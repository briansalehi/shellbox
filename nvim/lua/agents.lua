-- Coding agents as plain terminal jobs.
--
-- One live terminal per (agent, project root) pair, so several agents can run side
-- by side in the same repository. Deliberately not a plugin wrapper: the whole
-- feature is a registry, a split and jobstart().

local M = {}

M.config = {}
M.agents = {}   -- name -> agent
M.order  = {}   -- declaration order, used by the pickers

local defaults = {
    agents   = {},
    window   = { position = 'botright', split_ratio = 0.3 },
    refresh  = { enable = true, interval = 1000, updatetime = 100, notify = true },
    git_root = true,
}

local sessions = {}   -- key -> { agent, root, buf, job, argv }
local by_job   = {}   -- job id -> session; on_exit only receives the id

local function key_of(name, root)
    return name .. '@' .. root
end

local function alive(s)
    return s ~= nil
        and vim.api.nvim_buf_is_valid(s.buf)
        and vim.fn.jobwait({ s.job }, 0)[1] == -1   -- -1 = still running
end

-- Reviewer mode. --disallowedTools removes Edit and NotebookEdit, but Bash and
-- Write can still put bytes on disk, so the prohibition is spelled out in the
-- prompt, together with the three places a write is still wanted.
local review_prompt = table.concat({
    'You are a peer reviewer, not a writer.',
    'Never modify a file in the repository or in my configuration:',
    'not via Edit/Write, not via Bash',
    '(no sed -i, no tee, no heredoc redirect, no patch, no git apply,',
    'no git checkout/restore),',
    'and never by delegating the edit to a subagent.',
    'Propose code as fenced blocks in your reply and let me apply it.',
    'Three writes are allowed:',
    'your own memory files under ~/.claude/projects/*/memory/,',
    'the scratch file behind an Artifact you publish,',
    'and whatever a build or an installer you run writes to its own output paths.',
    'Build, test, install, and run any command freely.',
}, ' ')

-- Inside an agent terminal the git root of the buffer is meaningless, so keep the
-- root the session was started with.
local function project_root()
    local cur = vim.api.nvim_get_current_buf()
    for _, s in pairs(sessions) do
        if s.buf == cur then return s.root end
    end
    if not M.config.git_root then return vim.fn.getcwd() end
    return vim.fs.root(0, '.git') or vim.fn.getcwd()
end

--- window -------------------------------------------------------------------

local function apply_window_options(win)
    -- nvim's default TermOpen handler sets most of these, but a fresh split inherits
    -- the options of the window it was split from, so re-apply on every show
    -- no winfixheight here: it would make <C-w>= skip this window (:h winfixheight)
    local opts = { number = false, relativenumber = false, signcolumn = 'no' }
    for name, value in pairs(opts) do
        pcall(vim.api.nvim_set_option_value, name, value, { scope = 'local', win = win })
    end
end

local function open_split(buf)
    vim.cmd(M.config.window.position .. ' split')
    local win = vim.api.nvim_get_current_win()
    if buf then vim.api.nvim_win_set_buf(win, buf) end
    vim.api.nvim_win_set_height(win,
        math.max(5, math.floor(vim.o.lines * M.config.window.split_ratio)))
    apply_window_options(win)
    return win
end

local function visible_win(s)
    local tab = vim.api.nvim_get_current_tabpage()
    for _, w in ipairs(vim.fn.win_findbuf(s.buf)) do
        if vim.api.nvim_win_get_tabpage(w) == tab then return w end
    end
    return nil
end

local function is_last_window(win)
    return #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win)) <= 1
end

-- Deliberately not an autocmd. Nothing in this module runs startinsert on WinEnter
-- or BufEnter: leaving the terminal with <C-\><C-n>, scrolling back and switching
-- windows must not snap the view to the bottom on return.
local function enter_insert(win)
    vim.schedule(function()
        if vim.api.nvim_win_is_valid(win)
            and vim.api.nvim_get_current_win() == win
            and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == 'terminal' then
            vim.cmd('startinsert')
        end
    end)
end

--- file refresh -------------------------------------------------------------

local refresh = { timer = nil, saved_updatetime = nil }

local function any_visible()
    for _, s in pairs(sessions) do
        if alive(s) and #vim.fn.win_findbuf(s.buf) > 0 then return true end
    end
    return false
end

-- The timer only runs while an agent window is on screen, so a hidden agent costs
-- nothing and updatetime goes back to whatever options.lua set.
function refresh.update()
    if not M.config.refresh.enable then return end
    local want = any_visible()
    if want and not refresh.timer then
        refresh.saved_updatetime = vim.o.updatetime
        vim.o.updatetime = M.config.refresh.updatetime
        refresh.timer = vim.uv.new_timer()
        refresh.timer:start(M.config.refresh.interval, M.config.refresh.interval,
            vim.schedule_wrap(function() vim.cmd('silent! checktime') end))
    elseif not want and refresh.timer then
        refresh.timer:stop()
        refresh.timer:close()
        refresh.timer = nil
        vim.o.updatetime = refresh.saved_updatetime or 250
        refresh.saved_updatetime = nil
    end
end

--- sessions -----------------------------------------------------------------

local function bufnr_named(name)
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_get_name(b) == name then
            return b
        end
    end
    return nil
end

-- The agent:// scheme keeps nvim from prefixing the cwd, and is not term://, which
-- mksession restores by re-running the command.
local function buffer_name(agent, root)
    local base = ('agent://%s/%s'):format(agent.name, vim.fn.fnamemodify(root, ':t'))
    local name, n = base, 1
    while true do
        local existing = bufnr_named(name)
        if not existing then return name end
        local owned = false
        for _, s in pairs(sessions) do
            if s.buf == existing then owned = true end
        end
        if not owned then
            -- stale buffer from an earlier exit: take the name back
            pcall(vim.api.nvim_buf_delete, existing, { force = true })
            return name
        end
        n = n + 1
        name = base .. '#' .. n
    end
end

local function setup_buffer_keymaps(s)
    for _, d in ipairs({ 'h', 'j', 'k', 'l' }) do
        vim.keymap.set('t', '<C-' .. d .. '>', [[<C-\><C-n><C-w>]] .. d,
            { buffer = s.buf, desc = 'Window: move ' .. d })
    end
    vim.keymap.set('t', '<leader>cc', function() M.hide(s.agent.name) end,
        { buffer = s.buf, desc = 'Agent: hide' })
end

local function build_argv(agent, extra)
    local argv = { agent.cmd }
    vim.list_extend(argv, agent.args or {})
    vim.list_extend(argv, extra or {})
    return argv
end

local function spawn(agent, root, extra)
    if vim.fn.executable(agent.cmd) ~= 1 then
        vim.notify(("agents: '%s' is not in PATH"):format(agent.cmd), vim.log.levels.ERROR)
        return nil
    end

    local argv = build_argv(agent, extra)
    local name = buffer_name(agent, root)
    local buf  = vim.api.nvim_create_buf(false, false)
    local win  = open_split(buf)   -- must be current: term attaches to the current buffer

    -- an argv list bypasses 'shell' entirely, so there is no quoting and no
    -- pushd/&&/popd wrapper: cwd does the work
    local job = vim.fn.jobstart(argv, {
        term    = true,
        cwd     = vim.fn.isdirectory(root) == 1 and root or nil,
        env     = agent.env,
        on_exit = function(id, code) M._on_exit(id, code) end,
    })

    if job <= 0 then
        pcall(vim.api.nvim_win_close, win, true)
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
        vim.notify(("agents: failed to start '%s'"):format(agent.cmd), vim.log.levels.ERROR)
        return nil
    end

    vim.bo[buf].bufhidden = 'hide'    -- survives window close, so it can be re-shown
    vim.bo[buf].buflisted = false     -- keeps it out of :ls and out of auto-session
    pcall(vim.api.nvim_buf_set_name, buf, name)

    local s = { agent = agent, root = root, buf = buf, job = job, argv = argv }
    sessions[key_of(agent.name, root)] = s
    by_job[job] = s

    setup_buffer_keymaps(s)
    apply_window_options(win)
    refresh.update()
    enter_insert(win)
    return s
end

local function reveal(s)
    local win = visible_win(s)
    if not win then
        -- a window in another tabpage: going there switches tabs, which is right
        win = vim.fn.win_findbuf(s.buf)[1]
    end
    if win then
        vim.api.nvim_set_current_win(win)
        apply_window_options(win)
    else
        win = open_split(s.buf)
    end
    refresh.update()
    enter_insert(win)
    return win
end

local function hide_session(s)
    for _, w in ipairs(vim.fn.win_findbuf(s.buf)) do
        if is_last_window(w) then
            vim.notify('agents: refusing to close the last window', vim.log.levels.WARN)
        else
            pcall(vim.api.nvim_win_close, w, false)
        end
    end
    vim.schedule(refresh.update)
end

local function resolve_args(agent, opts)
    local args = {}
    if opts.variant then
        local v = (agent.variants or {})[opts.variant]
        if v then
            vim.list_extend(args, v)
        else
            vim.notify(("agents: %s has no '%s' variant"):format(agent.name, opts.variant),
                vim.log.levels.WARN)
        end
    end
    vim.list_extend(args, opts.args or {})
    return args
end

-- Flags only apply at spawn. Saying so beats silently ignoring them.
local function launch(agent, opts)
    opts = opts or {}
    local root = project_root()
    local key  = key_of(agent.name, root)
    local s    = sessions[key]

    if alive(s) then
        local want = build_argv(agent, resolve_args(agent, opts))
        if not vim.deep_equal(want, s.argv) then
            vim.notify(('agents: %s already running in %s (flags ignored)')
                :format(agent.name, vim.fn.fnamemodify(root, ':t')), vim.log.levels.INFO)
        end
        return reveal(s)
    end

    sessions[key] = nil
    return spawn(agent, root, resolve_args(agent, opts))
end

local function agent_or_warn(name)
    local agent = M.agents[name]
    if not agent then
        vim.notify(("agents: no agent named '%s'"):format(tostring(name)), vim.log.levels.ERROR)
    end
    return agent
end

--- public api ---------------------------------------------------------------

function M.list()
    local out = {}
    for _, name in ipairs(M.order) do
        for _, s in pairs(sessions) do
            if s.agent.name == name and alive(s) then table.insert(out, s) end
        end
    end
    return out
end

function M.hide(name)
    local s = sessions[key_of(name, project_root())]
    if alive(s) then hide_session(s) end
end

-- toggle closes when visible; focus never does, so the picker cannot close what
-- was just picked
function M.toggle(name, opts)
    local agent = agent_or_warn(name)
    if not agent then return end
    local s = sessions[key_of(agent.name, project_root())]
    if alive(s) and visible_win(s) then
        return hide_session(s)
    end
    return launch(agent, opts)
end

function M.focus(name, opts)
    local agent = agent_or_warn(name)
    if not agent then return end
    return launch(agent, opts)
end

function M.stop(name)
    local s = sessions[key_of(name, project_root())]
    if not alive(s) then
        vim.notify(('agents: %s is not running here'):format(name), vim.log.levels.WARN)
        return
    end
    pcall(vim.fn.jobstop, s.job)
end

function M.pick()
    local root = project_root()
    local here, elsewhere, launchable = {}, {}, {}

    local function label(name, r, state)
        return ('%-10s %-18s %s'):format(name, vim.fn.fnamemodify(r, ':t'), state)
    end

    for _, s in ipairs(M.list()) do
        local item = {
            label = label(s.agent.name, s.root, visible_win(s) and '[visible]' or '[hidden]'),
            run   = function() reveal(s) end,
        }
        table.insert(s.root == root and here or elsewhere, item)
    end

    for _, name in ipairs(M.order) do
        if not alive(sessions[key_of(name, root)]) then
            table.insert(launchable, {
                label = label(name, root, '[launch]'),
                run   = function() M.focus(name) end,
            })
        end
    end

    local items = {}
    vim.list_extend(items, here)
    vim.list_extend(items, elsewhere)
    vim.list_extend(items, launchable)

    if #items == 0 then
        vim.notify('agents: no agents configured', vim.log.levels.WARN)
        return
    end
    if #items == 1 then return items[1].run() end

    vim.ui.select(items, {
        prompt = 'Agent:',
        format_item = function(i) return i.label end,
    }, function(choice) if choice then choice.run() end end)
end

-- Model pickers are per-agent: claude's --model/--append-system-prompt-file pair
-- and opencode's --model/--agent pair are not interchangeable, so each agent
-- carries its own model list and builds its own flags.
function M.pick_model(name, opts)
    opts = opts or {}
    local agent = agent_or_warn(name)
    if not agent then return end
    if not agent.models then
        vim.notify(('agents: %s has no model list configured'):format(agent.name),
            vim.log.levels.WARN)
        return
    end

    local items = agent.models()
    if #items == 0 then
        vim.notify(('agents: no models found for %s'):format(agent.name), vim.log.levels.WARN)
        return
    end

    -- argv list: paths and provider/model strings go through verbatim, escaping
    -- them would pass literal quotes to the agent
    local function go(item)
        M.focus(agent.name, { variant = opts.variant, args = item.args })
    end

    if #items == 1 then return go(items[1]) end
    vim.ui.select(items, {
        prompt = agent.name .. ' model:',
        format_item = function(i) return i.label end,
    }, function(choice) if choice then go(choice) end end)
end

-- A clean exit takes the window and buffer with it; a crash keeps the buffer so the
-- error stays readable, with nvim's own "[Process exited N]" at the bottom.
function M._on_exit(job, code)
    local s = by_job[job]
    if not s then return end
    by_job[job] = nil
    sessions[key_of(s.agent.name, s.root)] = nil

    vim.schedule(function()
        if code == 0 then
            for _, w in ipairs(vim.fn.win_findbuf(s.buf)) do
                if not is_last_window(w) then pcall(vim.api.nvim_win_close, w, true) end
            end
            pcall(vim.api.nvim_buf_delete, s.buf, { force = true })
        else
            vim.notify(('agents: %s exited with %d'):format(s.agent.name, code),
                vim.log.levels.WARN)
        end
        refresh.update()
    end)
end

--- setup --------------------------------------------------------------------

local function setup_autocmds()
    local group = vim.api.nvim_create_augroup('Agents', { clear = true })

    if M.config.refresh.enable then
        vim.api.nvim_create_autocmd(
            { 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI', 'TermLeave' }, {
            group = group,
            callback = function(args)
                if vim.bo[args.buf].buftype == ''
                    and vim.fn.filereadable(vim.api.nvim_buf_get_name(args.buf)) == 1 then
                    vim.cmd('silent! checktime ' .. args.buf)
                end
            end,
        })
        if M.config.refresh.notify then
            vim.api.nvim_create_autocmd('FileChangedShellPost', {
                group = group,
                callback = function(args)
                    vim.notify(('agents: reloaded %s')
                        :format(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ':t')),
                        vim.log.levels.INFO)
                end,
            })
        end
    end

    -- catches the agent window being closed with :q behind the module's back
    vim.api.nvim_create_autocmd({ 'WinClosed', 'WinEnter' }, {
        group = group,
        callback = vim.schedule_wrap(function() refresh.update() end),
    })

    -- SIGTERM first, so an agent can persist its session and --continue still works
    vim.api.nvim_create_autocmd('VimLeavePre', {
        group = group,
        callback = function()
            for _, s in pairs(sessions) do pcall(vim.fn.jobstop, s.job) end
        end,
    })
end

-- Idempotent over the registry: re-sourcing this module keeps live sessions and
-- only resets the timer and the autocmds.
function M.setup(cfg)
    M.config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), cfg or {})

    M.agents, M.order = {}, {}
    for _, a in ipairs(M.config.agents or {}) do
        if not a.name or not a.cmd then
            vim.notify('agents: every agent needs a name and a cmd', vim.log.levels.ERROR)
        else
            M.agents[a.name] = a
            table.insert(M.order, a.name)
        end
    end

    if refresh.timer then
        refresh.timer:stop()
        refresh.timer:close()
        refresh.timer = nil
        if refresh.saved_updatetime then
            vim.o.updatetime = refresh.saved_updatetime
            refresh.saved_updatetime = nil
        end
    end

    setup_autocmds()
    refresh.update()
    return M
end

return M
