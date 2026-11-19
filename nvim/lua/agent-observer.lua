-- Save forwarding: each :w sends the diff of that save to a read-only agent
-- session running in the same repository. Agents take one of two roles:
--
--   observer  you know what you are doing and it watches for mistakes. Forwarding
--             is toggled per repository, and its instructions travel with the
--             diffs, because the same agent can also run without observing.
--   mentor    you do not know how yet and want to write it yourself. Forwarding is
--             on for as long as the session lives, and its role is in its system
--             prompt, because you state your goal before the first save.
--
-- Nothing polls. A save is sent at once and opens a short window; saves inside
-- the window go together when it closes, so a burst of saves costs at most one
-- message per window, and no save means no message and no tokens.
--
-- The message is typed into the agent's terminal, so it must not arrive while
-- the agent is working: an Enter landing on a permission prompt could answer it.
-- Claude's hooks and opencode's plugin (scripts/agent-state.ts) report its state
-- through scripts/agent-state.lua, and anything saved in the meantime is held and
-- sent together once the agent is idle.
--
-- The observer's instructions go with the first diff a session gets, and again
-- after /clear, a resume or a compaction, which may have lost them.

local agents = require('agents')

local M = {}

local WINDOW_MS      = 2000
local PASTE_ENTER_MS = 150
local MAX_FILE_BYTES = 1024 * 1024
local MAX_DIFF_LINES = 500

local roles = {
    observer = {
        instructions = table.concat({
            'You are pair programming with me. Each message that starts with "Saved:" is the diff of a change I just saved.',
            'Judge each change only, using what you already know from earlier saves, and do not repeat earlier comments.',
            'If there is nothing worth raising, reply with exactly: looks good.',
            'Otherwise comment briefly and propose edits as diff hunks.',
            'Only run a tool if the change cannot be judged without it.',
        }, ' '),
        quiet = 'looks good',
    },
    -- the mentor ends a reply with its verdict, so it decides only after checking
    mentor = { always = true, verdict = 'last' },
}

local function mode(role)
    return vim.tbl_extend('error', roles[role], {
        label    = role,
        enabled  = {},   -- root -> true
        pending  = {},   -- root -> path -> { old, new }
        states   = {},   -- root -> { value = 'idle' | 'busy', job }
        awaiting = {},   -- root -> a reply to a save is due
        window   = {},   -- root -> 'open' | 'again' while saves are being batched
        briefed  = {},   -- root -> job of the session that has the instructions
    })
end

-- agent name -> its role and per-root state
local modes = {
    review       = mode('observer'),
    mentor       = mode('mentor'),
    ['oc-review'] = mode('observer'),
    ['oc-mentor'] = mode('mentor'),
}

local function active(m, root)
    return m.always or m.enabled[root]
end

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

local function build_message(m, root, brief)
    local parts, total = {}, 0
    local paths = vim.tbl_keys(m.pending[root] or {})
    table.sort(paths)
    for _, path in ipairs(paths) do
        local entry = m.pending[root][path]
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
    local message = 'Saved:\n' .. table.concat(parts, '\n')
    return brief and message .. '\n' .. m.instructions or message
end

local function flush(name, root)
    local m = modes[name]
    if not active(m, root) then return end
    local s = agents.session(name, root)
    local state = m.states[root]
    if not s or not state or state.job ~= s.job or state.value ~= 'idle' then return end
    -- you are typing in the agent: TermLeave tries again
    if vim.api.nvim_get_current_buf() == s.buf and vim.fn.mode():sub(1, 1) == 't' then return end

    local brief = m.instructions ~= nil and m.briefed[root] ~= s.job
    local message = build_message(m, root, brief)
    m.pending[root] = nil
    if not message then return end
    m.briefed[root] = s.job

    state.value = 'busy'   -- until the hooks say otherwise, so nothing sends twice
    m.awaiting[root] = true
    vim.fn.chansend(s.job, '\27[200~' .. message .. '\27[201~')
    -- the TUI drops an Enter that arrives in the same read as the paste
    vim.defer_fn(function()
        if agents.session(name, root) == s then vim.fn.chansend(s.job, '\r') end
    end, PASTE_ENTER_MS)
end

local function report(name, root, message)
    local m = modes[name]
    m.awaiting[root] = nil
    local words = vim.trim(message:lower():gsub('[%p%s]+', ' '))
    if m.quiet and words == m.quiet then return end
    local s = agents.session(name, root)
    if not s or #vim.fn.win_findbuf(s.buf) > 0 then return end
    local lines = vim.tbl_filter(function(l) return vim.trim(l) ~= '' end,
        vim.split(message, '\n'))
    local line = m.verdict == 'last' and lines[#lines] or lines[1] or ''
    vim.notify(('%s: %s (\\ap to read it)'):format(m.label, vim.trim(line)),
        vim.log.levels.WARN)
end

-- Called over RPC by scripts/agent-state.lua. event is 'start', 'idle', 'busy',
-- 'stop' or 'compact'; only 'stop' ends a turn and carries the reply.
function M.on_state(name, root, event, message)
    local m = modes[name]
    if not m then return end
    if event == 'start' or event == 'compact' then m.briefed[root] = nil end
    -- a compaction can happen in the middle of a turn, so it says nothing about state
    if event == 'compact' then return end
    local s = agents.session(name, root)
    m.states[root] = { value = event == 'busy' and 'busy' or 'idle', job = s and s.job }
    if event == 'busy' then return end
    if event == 'stop' and m.awaiting[root] and type(message) == 'string' then
        report(name, root, message)
    end
    flush(name, root)
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
        SessionStart     = {
            hook('start', 'startup|resume|clear')[1],
            hook('compact', 'compact')[1],
        },
        UserPromptSubmit = hook('busy'),
        PreToolUse       = hook('busy'),
        Stop             = hook('stop'),
        -- a turn you interrupt ends without Stop; this is what recovers from it
        Notification     = hook('idle', 'idle_prompt'),
    } })
end

-- every agent that takes this buffer's saves, as name -> root
local function watchers(buf)
    local out = {}
    if vim.bo[buf].buftype ~= '' or vim.bo[buf].binary then return out end
    local path = vim.api.nvim_buf_get_name(buf)
    if path == '' then return out end
    local root = vim.fs.root(buf, '.git') or vim.fn.getcwd()
    if not vim.startswith(path, root .. '/') then return out end
    for name, m in pairs(modes) do
        if active(m, root) and agents.session(name, root) then out[name] = root end
    end
    return out, path
end

local function before_write(args)
    local found, path = watchers(args.buf)
    if not next(found) then return end
    if vim.fn.getfsize(path) > MAX_FILE_BYTES then return end
    local old
    for name, root in pairs(found) do
        local pending = modes[name].pending
        pending[root] = pending[root] or {}
        -- the first save of a batch sets the baseline, so several saves read as one diff
        if not pending[root][path] then
            old = old or read_file(path) or ''
            if old:find('%z') then return end
            pending[root][path] = { old = old }
        end
    end
end

-- The first save goes on the next tick rather than at once, so the other buffers
-- of a :wa, written in the same command, join it.
local function throttle(name, root)
    local m = modes[name]
    if m.window[root] then
        m.window[root] = 'again'
        return
    end
    m.window[root] = 'open'
    vim.schedule(function() flush(name, root) end)
    vim.defer_fn(function()
        local again = m.window[root] == 'again'
        m.window[root] = nil
        if again then throttle(name, root) end
    end, WINDOW_MS)
end

local function after_write(args)
    local found, path = watchers(args.buf)
    local new
    for name, root in pairs(found) do
        local m = modes[name]
        if m.pending[root] and m.pending[root][path] then
            -- taken now, so a later edit by another agent is not presented as yours
            new = new or read_file(path)
            m.pending[root][path].new = new
            throttle(name, root)
        end
    end
end

-- Toggles an observer agent for this repository. start() launches it when it is
-- not running here.
function M.toggle(name, start)
    local m, root = modes[name], agents.project_root()
    if m.enabled[root] and agents.session(name, root) then
        m.enabled[root], m.pending[root], m.awaiting[root] = nil, nil, nil
        vim.notify(('agents: %s observe off'):format(name), vim.log.levels.INFO)
        return
    end
    m.enabled[root] = true
    vim.notify(('agents: %s observe on'):format(name), vim.log.levels.INFO)
    if not agents.session(name, root) then start() end
end

local group = vim.api.nvim_create_augroup('AgentObserver', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre',  { group = group, callback = before_write })
vim.api.nvim_create_autocmd('BufWritePost', { group = group, callback = after_write })
vim.api.nvim_create_autocmd('TermLeave', {
    group = group,
    callback = vim.schedule_wrap(function()
        for name, m in pairs(modes) do
            for root in pairs(m.pending) do flush(name, root) end
        end
    end),
})

return M
