-- Valgrind runner.
--
-- Not a plugin: the whole feature is a run, an XML parse and a quickfix list.
-- The plain-text output is not parsed on purpose. A leak's top frame is always
-- valgrind's own malloc interposer, so a text errorformat puts every leak in
-- vg_replace_malloc.c; one logical error also spreads over several lines with
-- nothing tying them together, and the error kind and leaked byte counts have
-- no textual form at all. --xml=yes carries all three.
--
-- lua/plugins/valgrind.lua holds the options and the keymaps.

local M = {}

M.opts = {
    num_callers = 50,               -- valgrind's own default of 12 truncates real stacks
    leak_kinds = 'definite,possible',
    track_origins = false,          -- halves memcheck's speed, so off until asked for
    suppressions_file = 'valgrind.supp',
    extra_args = {},
}

function M.setup(opts)
    M.opts = vim.tbl_extend('force', M.opts, opts or {})
end

-- the run in flight, if any. Valgrind is 20-50x slower than native, so a run on
-- a real program lasts long enough to need calling off.
local running = nil

-- state of the last run, shared by every viewer keymap
local last = {
    tool = nil,
    target = nil,
    errors = {},        -- every error of the run
    shown = {},         -- the errors currently in the quickfix list, in its order
    xml_file = nil,
    output = nil,
    root = nil,
}

-- XML --------------------------------------------------------------------
-- Valgrind's XML is written by its own printer and is uniformly shaped, so a
-- tag scanner is enough; nvim has no XML parser and the treesitter parser list
-- here is c/cpp/lua/cmake/python/rust.

local entities = { amp = '&', lt = '<', gt = '>', quot = '"', apos = "'" }

local function unescape(s)
    if s == nil then return nil end
    s = s:gsub('&#(%d+);', function(n) return vim.fn.nr2char(tonumber(n)) end)
    return (s:gsub('&(%a+);', function(e) return entities[e] or ('&' .. e .. ';') end))
end

local function tag(block, name)
    return unescape(block:match('<' .. name .. '>(.-)</' .. name .. '>'))
end

local function parse_frame(block)
    local dir, file = tag(block, 'dir'), tag(block, 'file')
    local path
    -- <file> is the basename and <dir> the absolute directory, even under
    -- --fullpath-after=, which only changes the plain-text output.
    if file then
        path = (dir and dir ~= '') and (dir .. '/' .. file) or file
    end
    return {
        ip = tag(block, 'ip'),
        fn = tag(block, 'fn'),
        obj = tag(block, 'obj'),
        file = path,
        line = tonumber(tag(block, 'line')),
    }
end

local function parse_error(block)
    local e = {}
    e.kind = tag(block, 'kind')

    -- leaks describe themselves in <xwhat>, everything else in <what>
    local xwhat = block:match('<xwhat>(.-)</xwhat>')
    e.what = xwhat and tag(xwhat, 'text') or tag(block, 'what')
    if xwhat then
        e.leaked_bytes = tag(xwhat, 'leakedbytes')
        e.leaked_blocks = tag(xwhat, 'leakedblocks')
    end

    e.stacks = {}
    for stack in block:gmatch('<stack>(.-)</stack>') do
        local frames = {}
        for frame in stack:gmatch('<frame>(.-)</frame>') do
            frames[#frames + 1] = parse_frame(frame)
        end
        e.stacks[#e.stacks + 1] = frames
    end

    e.auxwhat = {}
    for aux in block:gmatch('<auxwhat>(.-)</auxwhat>') do
        e.auxwhat[#e.auxwhat + 1] = unescape(aux)
    end

    -- 3.27.1 repeats each suppression as a stray sibling after </error>;
    -- scanning per error block takes the one inside and ignores the copy.
    local supp = block:match('<suppression>(.-)</suppression>')
    if supp then
        local raw = supp:match('<rawtext>%s*<!%[CDATA%[(.-)%]%]>')
        if raw then e.suppression = vim.trim(raw) end
    end

    return e
end

local function parse(xml)
    local errors = {}
    -- leak records are emitted after <status><state>FINISHED</state></status>,
    -- so the whole document is scanned, not just the part before it
    for block in xml:gmatch('<error>(.-)</error>') do
        errors[#errors + 1] = parse_error(block)
    end
    return errors
end

-- quickfix ---------------------------------------------------------------

local function project_root()
    local ok, cmake = pcall(require, 'cmake-tools')
    if ok then
        local cwd = cmake.get_config().cwd
        if cwd and tostring(cwd) ~= '' then return tostring(cwd) end
    end
    return vim.loop.cwd()
end

-- The frame the error should point at. Valgrind reports its own interposers
-- first, so the top frame of every leak is vg_replace_malloc.c; walking down to
-- the first frame in the project is what makes the list navigable.
local function pick_frame(frames, root)
    if root then
        for _, f in ipairs(frames) do
            if f.file and vim.startswith(f.file, root) then return f end
        end
    end
    for _, f in ipairs(frames) do
        if f.file and not (f.obj or ''):match('vgpreload') then return f end
    end
    for _, f in ipairs(frames) do
        if f.file then return f end
    end
    return nil
end

-- still-reachable memory is reported for information, not as a defect
local warn_kinds = { Leak_StillReachable = true }

local function to_items(errors, root)
    local items = {}
    for _, e in ipairs(errors) do
        local item = {
            text = ('[%s] %s'):format(e.kind or 'Unknown', e.what or ''),
            type = warn_kinds[e.kind] and 'W' or 'E',
        }
        local frame = pick_frame(e.stacks[1] or {}, root)
        if frame then
            item.filename = frame.file
            item.lnum = frame.line or 1
            item.col = 1
        end
        items[#items + 1] = item
    end
    return items
end

-- The displayed list is remembered alongside the quickfix, because \vmf can
-- filter it: the keymaps that act on "the error under the cursor" have to index
-- what is on screen, not every error of the run.
local function set_qflist(errors, title, root)
    last.shown = errors
    vim.fn.setqflist({}, ' ', { title = title, items = to_items(errors, root) })
end

-- running ----------------------------------------------------------------

local function launch_target()
    local ok, cmake = pcall(require, 'cmake-tools')
    if not ok then
        vim.notify('Valgrind: cmake-tools is not available', vim.log.levels.ERROR)
        return nil
    end
    -- get_launch_target_path() does not check its own Result, so it returns nil
    -- rather than reporting why; treat nil as "nothing selected yet"
    local got, exe = pcall(cmake.get_launch_target_path)
    if not got or exe == nil or exe == '' then
        vim.notify('Valgrind: no launch target built; pick one with \\mL', vim.log.levels.WARN)
        return nil
    end
    local name = cmake.get_launch_target()
    local cwd = select(2, pcall(cmake.get_launch_path, name))
    local args = select(2, pcall(cmake.get_launch_args)) or {}
    return {
        exe = tostring(exe),
        name = tostring(name or vim.fs.basename(tostring(exe))),
        cwd = (cwd and tostring(cwd) ~= '') and tostring(cwd) or nil,
        args = args,
    }
end

-- tool: memcheck today; helgrind and drd emit the same XML protocol and can
-- reuse everything below by passing their own name and extra flags.
function M.run(tool, extra, opts)
    opts = opts or {}
    if vim.fn.executable('valgrind') == 0 then
        vim.notify('Valgrind: valgrind is not on PATH', vim.log.levels.ERROR)
        return
    end

    if running then
        vim.notify(('Valgrind: %s is still running on %s; stop it with \\vs')
            :format(running.tool, running.target), vim.log.levels.WARN)
        return
    end

    local target = launch_target()
    if target == nil then return end

    local xml_file = vim.fn.tempname() .. '.xml'
    local argv = {
        'valgrind',
        '--tool=' .. tool,
        '--xml=yes',
        '--xml-file=' .. xml_file,
        '--num-callers=' .. tostring(M.opts.num_callers),
        -- 'all' would stop and read a confirmation from stdin for every error
        '--gen-suppressions=all',
    }
    vim.list_extend(argv, extra or {})
    vim.list_extend(argv, M.opts.extra_args)
    argv[#argv + 1] = '--'
    argv[#argv + 1] = target.exe
    vim.list_extend(argv, target.args)

    vim.notify(('Valgrind: %s on %s'):format(tool, target.name))

    local handle = vim.system(argv, { cwd = target.cwd, text = true }, vim.schedule_wrap(function(res)
        local stopped = running ~= nil and running.stopped
        running = nil

        local xml = ''
        if vim.fn.filereadable(xml_file) == 1 then
            xml = table.concat(vim.fn.readfile(xml_file), '\n')
        end

        last.tool = tool
        last.target = target.name
        last.xml_file = xml_file
        last.root = project_root()
        last.output = (res.stdout or '') .. (res.stderr or '')

        if xml == '' then
            -- a run stopped before valgrind got as far as writing anything
            local msg = stopped and 'Valgrind: stopped, nothing reported yet'
                or ('Valgrind: produced no XML (exit ' .. tostring(res.code) ..
                    '), see \\vp for its output')
            vim.notify(msg, stopped and vim.log.levels.WARN or vim.log.levels.ERROR)
            last.errors, last.shown = {}, {}
            return
        end

        -- SIGTERM still leaves a complete document behind, so a stopped run
        -- keeps whatever valgrind had found by then
        last.errors = parse(xml)
        last.shown = last.errors
        local how = stopped and ' (stopped)' or ''
        if #last.errors == 0 then
            vim.notify(('Valgrind: %s found no errors in %s%s')
                :format(tool, target.name, how))
            return
        end

        set_qflist(last.errors,
            ('valgrind %s: %s%s'):format(tool, target.name, how), last.root)
        vim.cmd('copen')
        vim.notify(('Valgrind: %d error%s in %s%s')
            :format(#last.errors, #last.errors == 1 and '' or 's', target.name, how),
            vim.log.levels.WARN)
    end))

    running = { handle = handle, tool = tool, target = target.name, stopped = false }
end

-- Stop the run in flight. Valgrind treats SIGTERM as a normal shutdown: it runs
-- its exit path and writes a complete XML document, so the errors it had already
-- found still reach the quickfix list.
function M.stop()
    if running == nil then
        vim.notify('Valgrind: nothing is running', vim.log.levels.WARN)
        return
    end
    running.stopped = true
    vim.notify(('Valgrind: stopping %s on %s'):format(running.tool, running.target))
    running.handle:kill('sigterm')
end

function M.is_running()
    return running ~= nil
end

function M.build_and_run(tool, extra, opts)
    local ok, cmake = pcall(require, 'cmake-tools')
    if not ok then
        vim.notify('Valgrind: cmake-tools is not available', vim.log.levels.ERROR)
        return
    end
    -- valgrind never builds, so on its own it happily measures a stale binary
    cmake.build({ fargs = {} }, function(result)
        if not result:is_ok() then return end
        vim.schedule(function() M.run(tool, extra, opts) end)
    end)
end

-- viewers ----------------------------------------------------------------

local function scratch(name, lines, filetype)
    vim.cmd('botright new')
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = false
    if filetype then vim.bo[buf].filetype = filetype end
    vim.api.nvim_buf_set_name(buf, name)
end

local function has_run()
    if last.tool == nil then
        vim.notify('Valgrind: nothing has been run yet', vim.log.levels.WARN)
        return false
    end
    return true
end

-- the error behind the quickfix line under the cursor
local function current_error()
    if #last.shown == 0 then
        vim.notify('Valgrind: no errors from the last run', vim.log.levels.WARN)
        return nil
    end
    local qf = vim.fn.getqflist({ idx = 0 })
    local e = last.shown[qf.idx]
    if e == nil then
        vim.notify('Valgrind: no error under the cursor', vim.log.levels.WARN)
        return nil
    end
    return e
end

function M.show_output()
    if not has_run() then return end
    local out = last.output or ''
    if vim.trim(out) == '' then
        vim.notify('Valgrind: the program produced no output')
        return
    end
    scratch('valgrind://output', vim.split(out, '\n', { plain = true }))
end

function M.show_xml()
    if not has_run() then return end
    if last.xml_file == nil or vim.fn.filereadable(last.xml_file) == 0 then
        vim.notify('Valgrind: the raw output file is gone', vim.log.levels.WARN)
        return
    end
    vim.cmd('botright split ' .. vim.fn.fnameescape(last.xml_file))
    vim.bo.filetype = 'xml'
end

-- The full error: every stack, with the auxwhat lines that separate them. This
-- is where a --track-origins run shows where the uninitialised value came from.
function M.show_stack()
    local e = current_error()
    if e == nil then return end

    local lines = { ('[%s] %s'):format(e.kind or 'Unknown', e.what or '') }
    if e.leaked_bytes then
        lines[#lines + 1] = ('leaked %s bytes in %s blocks')
            :format(e.leaked_bytes, e.leaked_blocks or '?')
    end

    for i, frames in ipairs(e.stacks) do
        lines[#lines + 1] = ''
        -- stack 1 is the error itself; each later stack belongs to the auxwhat
        -- printed before it (the allocation site, the origin, the other thread)
        lines[#lines + 1] = (i == 1) and 'stack:' or ((e.auxwhat[i - 1] or 'stack') .. ':')
        for _, f in ipairs(frames) do
            local where = f.file and ('%s:%d'):format(f.file, f.line or 0) or (f.obj or '?')
            lines[#lines + 1] = ('  %s (%s)'):format(f.fn or '?', where)
        end
    end

    -- auxwhat lines with no stack of their own still carry the description
    for i = #e.stacks, #e.auxwhat do
        if e.auxwhat[i] then
            lines[#lines + 1] = ''
            lines[#lines + 1] = e.auxwhat[i]
        end
    end

    scratch('valgrind://stack', lines)
end

function M.filter()
    if #last.errors == 0 then
        vim.notify('Valgrind: no errors from the last run', vim.log.levels.WARN)
        return
    end
    local seen, kinds = {}, { 'all' }
    for _, e in ipairs(last.errors) do
        local kind = e.kind or 'Unknown'
        if not seen[kind] then
            seen[kind] = true
            kinds[#kinds + 1] = kind
        end
    end
    vim.ui.select(kinds, { prompt = 'Valgrind kind: ' }, function(choice)
        if choice == nil then return end
        local title = ('valgrind %s: %s'):format(last.tool, last.target)
        if choice == 'all' then
            set_qflist(last.errors, title, last.root)
        else
            local kept = vim.tbl_filter(function(e) return (e.kind or 'Unknown') == choice end,
                last.errors)
            set_qflist(kept, title .. ' [' .. choice .. ']', last.root)
        end
        vim.cmd('copen')
    end)
end

-- suppressions -----------------------------------------------------------

local function suppressions_path()
    local file = M.opts.suppressions_file
    if vim.fn.fnamemodify(file, ':p') == file then return file end
    return (last.root or project_root()) .. '/' .. file
end

local function append_suppressions(blocks)
    if #blocks == 0 then
        vim.notify('Valgrind: no suppression available', vim.log.levels.WARN)
        return
    end
    local path = suppressions_path()
    local lines = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}
    for _, block in ipairs(blocks) do
        vim.list_extend(lines, vim.split(block, '\n', { plain = true }))
    end
    vim.fn.writefile(lines, path)
    vim.notify(('Valgrind: %d suppression%s appended to %s')
        :format(#blocks, #blocks == 1 and '' or 's', path))
end

function M.suppress_current()
    local e = current_error()
    if e == nil then return end
    append_suppressions(e.suppression and { e.suppression } or {})
end

function M.suppress_all()
    local blocks = {}
    for _, e in ipairs(last.shown) do
        if e.suppression then blocks[#blocks + 1] = e.suppression end
    end
    append_suppressions(blocks)
end

return M
