-- Valgrind runner.
--
-- Not a plugin: the whole feature is a run, a parse of the report and a
-- quickfix list. Valgrind's own text report is the single artifact -- it is
-- what \vr shows verbatim and what the quickfix is built from, so the thing
-- read and the thing parsed are the same bytes.
--
-- This is not vim's errorformat, which cannot do the job: it would put every
-- leak in vg_replace_malloc.c, because valgrind's malloc interposer is always
-- a leak's top frame and errorformat cannot walk down to the frame that is
-- actually yours. Parsing the report here can, and does. See parse() below for
-- the flags that make the text unambiguous.
--
-- lua/plugins/valgrind.lua holds the options and the keymaps.

local M = {}

M.opts = {
    num_callers = 50,               -- valgrind's own default of 12 truncates real stacks
    leak_kinds = 'definite,possible',
    track_origins = false,          -- halves memcheck's speed, so off until asked for
    suppressions_file = 'valgrind.supp',
    split_ratio = 0.33,             -- same share of the screen the agent terminals take
    extra_args = {},
}

function M.setup(opts)
    M.opts = vim.tbl_extend('force', M.opts, opts or {})
end

-- The program's output, streamed. vim.system only hands back stdout and stderr
-- when the process exits, which never happens for a server or any other target
-- that runs until it is stopped, so the chunks are collected as they arrive and
-- kept in a buffer \vp can open at any point, during the run or after it.
local out = { buf = nil, partial = '' }

local function split_height()
    return math.max(5, math.floor(vim.o.lines * M.opts.split_ratio))
end

local function output_buf()
    if out.buf and vim.api.nvim_buf_is_valid(out.buf) then return out.buf end
    out.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[out.buf].bufhidden = 'hide'
    vim.bo[out.buf].swapfile = false
    vim.api.nvim_buf_set_name(out.buf, 'valgrind://output')
    return out.buf
end

local function reset_output()
    local buf = output_buf()
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '' })
    vim.bo[buf].modifiable = false
    out.partial = ''
end

local function append_output(chunk)
    if chunk == nil or chunk == '' then return end
    local buf = output_buf()

    -- a chunk can split mid-line, so the tail is carried to the next one and
    -- the buffer's last line is rewritten rather than appended to
    local lines = vim.split(out.partial .. chunk, '\n', { plain = true })
    out.partial = table.remove(lines)
    lines[#lines + 1] = out.partial

    local windows = vim.fn.win_findbuf(buf)
    local at_end = {}
    for _, win in ipairs(windows) do
        at_end[win] = vim.api.nvim_win_get_cursor(win)[1] >= vim.api.nvim_buf_line_count(buf)
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, math.max(vim.api.nvim_buf_line_count(buf) - 1, 0), -1,
        false, lines)
    vim.bo[buf].modifiable = false

    -- follow the tail, unless the reader has scrolled back to look at something
    for _, win in ipairs(windows) do
        if at_end[win] then
            vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
        end
    end
end

-- Returns the window showing the output, opening one if it is not up yet, plus
-- the window that was current before. Reuses a visible one rather than stacking
-- a second copy of the same buffer.
local function open_output_win()
    local buf = output_buf()
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        return win, vim.api.nvim_get_current_win()
    end

    local prev = vim.api.nvim_get_current_win()
    vim.cmd('botright split')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_height(win, split_height())
    return win, prev
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
    log_file = nil,
    output = nil,
    root = nil,
}

-- parsing ---------------------------------------------------------------
-- Valgrind's own report is read rather than its XML. The two carry the same
-- information -- the text has a leak_summary, a heap_summary and per-frame
-- file and line just as the XML does -- but only one of them can be produced
-- per run: --xml=yes replaces the text output, it does not duplicate it, and a
-- --log-file given alongside it comes back empty. Reading the text means the
-- report shown by \vr is valgrind's own words, which is the format every
-- tutorial and CI log speaks, rather than something reconstructed from XML.
--
-- Three flags make it parseable without guesswork:
--   --error-markers  valgrind brackets each error itself, so block boundaries
--                    are not inferred from blank lines
--   --fullpath-after= absolute paths in frames, so the quickfix can navigate
--                    (this flag does nothing in XML mode; text is its purpose)
--   --log-file       keeps the report out of the program's own output
--
-- After the ==pid== marker is removed the indent carries the structure: four
-- spaces for a stack frame, two for a secondary description, one for the
-- error's own message.

-- Prose to error kind. memcheck prints the XML kind and this text from the same
-- switch in its mc_errors.c, so the pairs below are taken from there; the text
-- format is the only place the kind is not stated outright.
local kind_patterns = {
    { '^Invalid read of size',                          'InvalidRead' },
    { '^Invalid write of size',                         'InvalidWrite' },
    { '^Conditional jump or move depends',              'UninitCondition' },
    { '^Use of uninitialised value of size',            'UninitValue' },
    { '^Invalid free%(%)',                              'InvalidFree' },
    { '^Mismatched free%(%)',                           'MismatchedFree' },
    { '^Mismatched .* alignment alloc value',           'MismatchedAllocateDeallocateAlignment' },
    { '^Mismatched .* size value',                      'MismatchedAllocateDeallocateSize' },
    { '^Syscall param ',                                'SyscallParam' },
    { '^Source and destination overlap',                'Overlap' },
    { '^Jump to the invalid address',                   'InvalidJump' },
    { "^Argument '.*' of function .* has a fishy",      'FishyValue' },
    { '^Illegal memory pool address',                   'InvalidMemPool' },
    { '^Invalid alignment value',                       'InvalidAlignment' },
    { '^Invalid size value',                            'InvalidSizeAndAlignment' },
    { '^Unsafe allocation with size of zero',           'InvalidSize' },
    { '^%S+%(%) with size 0',                           'ReallocSizeZero' },
    { 'byte%(%)s? found during client check request',   'ClientCheck' },
    { 'contains unaddressable byte%(s%)',               'CoreMemError' },
}

local leak_kinds = {
    ['definitely lost'] = 'Leak_DefinitelyLost',
    ['indirectly lost'] = 'Leak_IndirectlyLost',
    ['possibly lost']   = 'Leak_PossiblyLost',
    ['still reachable'] = 'Leak_StillReachable',
}

local function classify(what)
    for lost, kind in pairs(leak_kinds) do
        if what:find(' are ' .. lost .. ' in ', 1, true) then return kind end
    end
    for _, rule in ipairs(kind_patterns) do
        if what:match(rule[1]) then return rule[2] end
    end
    -- an unmapped message still gets an entry, labelled with its opening words
    return what:match('^(%S+%s+%S+)') or 'Unknown'
end

local function parse_frame(line)
    --    at 0x4011A4: invalid_read (/path/main.c:15)
    --    by 0x4847772: malloc (in /usr/lib/foo.so)
    --    by 0x8048348: (within /path/a.out)
    local lead, ip, rest = line:match('^%s+(%a%a)%s+0x(%x+):%s*(.*)$')
    if ip == nil or (lead ~= 'at' and lead ~= 'by') then return nil end

    local frame = { ip = '0x' .. ip }
    local fn, where = rest:match('^(.-)%s*%(([^()]*)%)%s*$')
    if fn == nil then
        frame.fn = rest
        return frame
    end
    if fn ~= '' then frame.fn = fn end

    local obj = where:match('^in%s+(.*)$') or where:match('^within%s+(.*)$')
    if obj then
        frame.obj = obj
    else
        local file, lnum = where:match('^(.*):(%d+)$')
        if file then
            frame.file, frame.line = file, tonumber(lnum)
        else
            frame.obj = where
        end
    end
    return frame
end

local function parse(log)
    local errors = {}
    local current, supp = nil, nil

    for raw in (log .. '\n'):gmatch('(.-)\n') do
        -- the suppression for an error follows its VGEND, unprefixed
        if supp ~= nil then
            supp[#supp + 1] = raw
            if raw:match('^}') then
                local e = errors[#errors]
                if e then e.suppression = table.concat(supp, '\n') end
                supp = nil
            end
            goto continue
        end
        if raw:match('^{%s*$') and #errors > 0 and errors[#errors].suppression == nil then
            supp = { raw }
            goto continue
        end

        -- keep the indent: it is what separates a frame from a description
        local line = raw:match('^==%d+==(.*)$')
        if line == nil then goto continue end
        local marker = vim.trim(line)

        if marker == 'VGBEGIN' then
            current = { stacks = {}, auxwhat = {} }
        elseif marker == 'VGEND' then
            if current and current.what then errors[#errors + 1] = current end
            current = nil
        elseif current ~= nil then
            local frame = parse_frame(line)
            if frame then
                if #current.stacks == 0 then current.stacks[1] = {} end
                local stack = current.stacks[#current.stacks]
                stack[#stack + 1] = frame
            elseif line:match('^  %S') then
                -- a secondary description, and the stack after it describes
                -- that rather than the error: the allocation site, the origin
                -- of an uninitialised value, the thread holding a lock
                current.auxwhat[#current.auxwhat + 1] = marker
                current.stacks[#current.stacks + 1] = {}
            elseif marker ~= '' and current.what == nil then
                current.what = marker
                current.kind = classify(marker)
                -- "168 (24 direct, 144 indirect) bytes in 1 blocks are ..."
                -- states the total first, which is what the XML reported too
                current.leaked_bytes = marker:match('^([%d,]+) %([%d,]+ direct')
                    or marker:match('^([%d,]+) bytes in ')
                if current.leaked_bytes then
                    current.leaked_blocks = marker:match(' in ([%d,]+) blocks are ')
                end
            end
        end
        ::continue::
    end

    -- a description with no frames after it left an empty stack behind
    for _, e in ipairs(errors) do
        while #e.stacks > 0 and #e.stacks[#e.stacks] == 0 do
            table.remove(e.stacks)
        end
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

-- tool: memcheck today. helgrind and drd print the same report shape -- marked
-- errors, indented frames, indented descriptions -- so they can reuse
-- everything below by passing their own name and extra flags.
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

    local log_file = vim.fn.tempname() .. '.valgrind'
    local argv = {
        'valgrind',
        '--tool=' .. tool,
        -- the report goes to its own file, so the program's output stays clean
        '--log-file=' .. log_file,
        -- valgrind brackets each error itself rather than leaving it to be guessed
        '--error-markers=VGBEGIN,VGEND',
        -- frames name a basename by default, which the quickfix cannot open
        '--fullpath-after=',
        '--num-callers=' .. tostring(M.opts.num_callers),
        -- 'all' would stop and read a confirmation from stdin for every error
        '--gen-suppressions=all',
    }
    vim.list_extend(argv, extra or {})
    vim.list_extend(argv, M.opts.extra_args)
    argv[#argv + 1] = '--'
    argv[#argv + 1] = target.exe
    vim.list_extend(argv, target.args)

    -- a target that runs until it is stopped reports nothing until then, so say
    -- up front where its output is and how to end the run
    vim.notify(('Valgrind: %s on %s — \\vp for output, \\vs to stop')
        :format(tool, target.name))

    reset_output()

    -- up on every run: a target that runs until it is stopped has nothing else
    -- to show for itself. Focus stays where it was, so the run does not
    -- interrupt whatever is being edited.
    local _, prev = open_output_win()
    if vim.api.nvim_win_is_valid(prev) then vim.api.nvim_set_current_win(prev) end

    last.tool = tool
    last.target = target.name
    last.log_file = log_file
    last.root = project_root()
    last.output = ''
    last.errors, last.shown = {}, {}

    local function stream(_, chunk)
        if chunk == nil then return end
        last.output = last.output .. chunk
        vim.schedule(function() append_output(chunk) end)
    end

    local handle = vim.system(argv, {
        cwd = target.cwd,
        text = true,
        stdout = stream,
        stderr = stream,
    }, vim.schedule_wrap(function(res)
        local stopped = running ~= nil and running.stopped
        running = nil

        local log = ''
        if vim.fn.filereadable(log_file) == 1 then
            log = table.concat(vim.fn.readfile(log_file), '\n')
        end

        if log == '' then
            -- a run stopped before valgrind got as far as writing anything
            local msg = stopped and 'Valgrind: stopped, nothing reported yet'
                or ('Valgrind: wrote no report (exit ' .. tostring(res.code) ..
                    '), see \\vp for its output')
            vim.notify(msg, stopped and vim.log.levels.WARN or vim.log.levels.ERROR)
            last.errors, last.shown = {}, {}
            return
        end

        -- SIGTERM is a normal shutdown for valgrind: it still runs its exit
        -- path and writes the full report, so a stopped run keeps its findings
        last.errors = parse(log)
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
-- its exit path and writes the full report, so the errors it had already found
-- still reach the quickfix list.
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

-- One window per view, rewritten in place. Pressing \vmt on a second error
-- should replace the stack on screen, not put another pane below it.
local function scratch(name, lines)
    local buf = vim.fn.bufnr(name)
    if buf == -1 or not vim.api.nvim_buf_is_valid(buf) then
        buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].buftype = 'nofile'
        vim.bo[buf].bufhidden = 'hide'
        vim.bo[buf].swapfile = false
        vim.api.nvim_buf_set_name(buf, name)
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        vim.api.nvim_set_current_win(win)
        vim.api.nvim_win_set_cursor(win, { 1, 0 })
        return
    end

    vim.cmd('botright split')
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_height(0, split_height())
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

-- Opens the live buffer, so it works while the run is still going; a target
-- that never exits on its own is the normal case for this.
function M.show_output()
    if not has_run() then return end
    local win = open_output_win()
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(output_buf()), 0 })
end

-- Closes what this feature opened: the output, the stack view, the raw report
-- and the quickfix list if valgrind is what filled it. The output buffer itself
-- is kept, so \vp reopens the same scrollback rather than an empty pane.
function M.close()
    local closed = 0

    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            local name = vim.api.nvim_buf_get_name(buf)
            local ours = name:match('^valgrind://') ~= nil
                or (last.log_file ~= nil and name == last.log_file)
            -- never close the last window of a tab out from under the user
            local tab = vim.api.nvim_win_get_tabpage(win)
            if ours and #vim.api.nvim_tabpage_list_wins(tab) > 1 then
                vim.api.nvim_win_close(win, false)
                closed = closed + 1
            end
        end
    end

    if vim.fn.getqflist({ title = 0 }).title:match('^valgrind ') then
        for _, w in ipairs(vim.fn.getwininfo()) do
            if w.quickfix == 1 and w.loclist == 0 then
                vim.cmd('cclose')
                closed = closed + 1
                break
            end
        end
    end

    if closed == 0 then
        vim.notify('Valgrind: nothing open to close')
    end
end

-- Valgrind's own report, as it printed it. Re-read on every open, so during a
-- long run it shows what has accumulated rather than a stale copy.
function M.show_report()
    if not has_run() then return end
    if last.log_file == nil or vim.fn.filereadable(last.log_file) == 0 then
        vim.notify('Valgrind: no report written yet', vim.log.levels.WARN)
        return
    end
    -- reuse the window it is already in rather than stacking another copy
    local buf = vim.fn.bufnr(last.log_file)
    if buf ~= -1 then
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
            vim.api.nvim_set_current_win(win)
            vim.cmd('edit')     -- the run may have written more since
            return
        end
    end

    vim.cmd('botright split ' .. vim.fn.fnameescape(last.log_file))
    vim.api.nvim_win_set_height(0, split_height())
    vim.cmd('edit')
    vim.bo.filetype = 'valgrind'
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
