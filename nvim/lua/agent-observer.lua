-- Pair programming on save: while observing is on for a repository, each :w sends
-- the diff of that save to the claude reviewer running there.
--
-- Nothing polls. A save starts a short timer so a burst of saves becomes one
-- message, and no save means no message and no tokens.
--
-- The message is typed into the reviewer's terminal, so it must not arrive while
-- claude is working: an Enter landing on a permission prompt could answer it.
-- Claude's hooks report its state through scripts/agent-state.lua, and anything
-- saved in the meantime is held and sent together once claude is idle.

local agents = require('agents')

local M = {}

local AGENT          = 'review'
local DEBOUNCE_MS    = 2000
local PASTE_ENTER_MS = 150
local MAX_FILE_BYTES = 1024 * 1024
local MAX_DIFF_LINES = 500

local INSTRUCTIONS = table.concat({
    'You are pair programming with me and I just saved the change above.',
    'Judge this change only, using what you already know from earlier saves, and do not repeat earlier comments.',
    'If there is nothing worth raising, reply with exactly: looks good.',
    'Otherwise comment briefly and propose edits as diff hunks.',
    'Only run a tool if the change cannot be judged without it.',
}, ' ')

local enabled  = {}   -- root -> true
local pending  = {}   -- root -> path -> { old, new }
local states   = {}   -- root -> { value = 'idle' | 'busy', job }
local awaiting = {}   -- root -> a reply to the observer is due
local timers   = {}   -- root -> generation of the latest debounce timer

local function read_file(path)
    local f = io.open(path, 'rb')
    if not f then return nil end
    local data = f:read('*a')
    f:close()
    return data
end

-- Saved text must not be able to end the bracketed paste or drive the terminal.
local function sanitize(text)
    return (text:gsub('[%z\1-\8\11-\31\127]', ''))
end

local function build_message(root)
    local parts, total = {}, 0
    local paths = vim.tbl_keys(pending[root] or {})
    table.sort(paths)
    for _, path in ipairs(paths) do
        local entry = pending[root][path]
        local diff = entry.new and vim.text.diff(entry.old, entry.new, { ctxlen = 3 }) or ''
        if diff ~= '' and total < MAX_DIFF_LINES then
            local lines = vim.split(sanitize(diff), '\n', { plain = true })
            local room = MAX_DIFF_LINES - total
            if #lines > room then
                lines = vim.list_slice(lines, 1, room)
                table.insert(lines, '... diff truncated, read the file if you need the rest')
            end
            total = total + #lines
            local rel = path:sub(#root + 2)
            table.insert(parts, ('````diff\n--- a/%s\n+++ b/%s\n%s\n````')
                :format(rel, rel, table.concat(lines, '\n')))
        end
    end
    if #parts == 0 then return nil end
    return 'Saved:\n' .. table.concat(parts, '\n') .. '\n' .. INSTRUCTIONS
end

local function flush(root)
    if not enabled[root] then return end
    local s = agents.session(AGENT, root)
    local state = states[root]
    if not s or not state or state.job ~= s.job or state.value ~= 'idle' then return end
    -- you are typing in the reviewer: TermLeave tries again
    if vim.api.nvim_get_current_buf() == s.buf and vim.fn.mode():sub(1, 1) == 't' then return end

    local message = build_message(root)
    pending[root] = nil
    if not message then return end

    state.value = 'busy'   -- until the hooks say otherwise, so nothing sends twice
    awaiting[root] = true
    vim.fn.chansend(s.job, '\27[200~' .. message .. '\27[201~')
    -- the TUI drops an Enter that arrives in the same read as the paste
    vim.defer_fn(function()
        if agents.session(AGENT, root) == s then vim.fn.chansend(s.job, '\r') end
    end, PASTE_ENTER_MS)
end

local function report(root, message)
    awaiting[root] = nil
    local words = vim.trim(message:lower():gsub('[%p%s]+', ' '))
    if words == 'looks good' then return end
    local s = agents.session(AGENT, root)
    if not s or #vim.fn.win_findbuf(s.buf) > 0 then return end
    vim.notify(('observer: %s (\\ap to read it)'):format(vim.split(message, '\n')[1]),
        vim.log.levels.WARN)
end

-- Called over RPC by scripts/agent-state.lua. event is 'idle', 'busy' or 'stop';
-- only 'stop' ends a turn and carries the reply.
function M.on_state(name, root, event, message)
    if name ~= AGENT then return end
    local s = agents.session(AGENT, root)
    states[root] = { value = event == 'busy' and 'busy' or 'idle', job = s and s.job }
    if event == 'busy' then return end
    if event == 'stop' and awaiting[root] and type(message) == 'string' then
        report(root, message)
    end
    flush(root)
end

-- Reads vim.fn.stdpath('config'), so it is resolved when the agent table is built.
function M.hook_settings()
    local script = vim.fn.stdpath('config') .. '/scripts/agent-state.lua'
    local function hook(event, matcher)
        return { {
            matcher = matcher,
            hooks = { {
                type = 'command',
                command = ("nvim --clean -l '%s' %s"):format(script, event),
                timeout = 5,
            } },
        } }
    end
    return vim.json.encode({ hooks = {
        -- not 'compact': that one fires in the middle of a turn
        SessionStart     = hook('idle', 'startup|resume|clear'),
        UserPromptSubmit = hook('busy'),
        PreToolUse       = hook('busy'),
        Stop             = hook('stop'),
        -- a turn you interrupt ends without Stop; this is what recovers from it
        Notification     = hook('idle', 'idle_prompt'),
    } })
end

local function watched(buf)
    if vim.bo[buf].buftype ~= '' or vim.bo[buf].binary then return nil end
    local path = vim.api.nvim_buf_get_name(buf)
    if path == '' then return nil end
    local root = vim.fs.root(buf, '.git') or vim.fn.getcwd()
    if not enabled[root] or not vim.startswith(path, root .. '/') then return nil end
    if not agents.session(AGENT, root) then return nil end
    return root, path
end

local function before_write(args)
    local root, path = watched(args.buf)
    if not root then return end
    pending[root] = pending[root] or {}
    -- the first save of a batch sets the baseline, so several saves read as one diff
    if pending[root][path] then return end
    if vim.fn.getfsize(path) > MAX_FILE_BYTES then return end
    local old = read_file(path) or ''
    if old:find('%z') then return end
    pending[root][path] = { old = old }
end

local function after_write(args)
    local root, path = watched(args.buf)
    if not root or not (pending[root] and pending[root][path]) then return end
    -- taken now, so a later edit by another agent is not presented as yours
    pending[root][path].new = read_file(path)
    local generation = (timers[root] or 0) + 1
    timers[root] = generation
    vim.defer_fn(function()
        if timers[root] == generation then flush(root) end
    end, DEBOUNCE_MS)
end

-- start() launches the reviewer when it is not running here.
function M.toggle(start)
    local root = agents.project_root()
    if enabled[root] and agents.session(AGENT, root) then
        enabled[root], pending[root], awaiting[root] = nil, nil, nil
        vim.notify('agents: observe off', vim.log.levels.INFO)
        return
    end
    enabled[root] = true
    vim.notify('agents: observe on', vim.log.levels.INFO)
    if not agents.session(AGENT, root) then start() end
end

local group = vim.api.nvim_create_augroup('AgentObserver', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre',  { group = group, callback = before_write })
vim.api.nvim_create_autocmd('BufWritePost', { group = group, callback = after_write })
vim.api.nvim_create_autocmd('TermLeave', {
    group = group,
    callback = vim.schedule_wrap(function()
        for root in pairs(enabled) do flush(root) end
    end),
})

return M
