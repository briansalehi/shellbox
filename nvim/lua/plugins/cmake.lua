local map = require('plugins.util').cmd_map

-- cmake tools
local osys = require("cmake-tools.osys")
require("cmake-tools").setup {
  cmake_command = "cmake", -- this is used to specify cmake command path
  ctest_command = "ctest", -- this is used to specify ctest command path
  ctest_show_labels = true, -- also show labels in the test picker
  cmake_use_preset = true,
  cmake_regenerate_on_save = true, -- auto generate when save CMakeLists.txt
  cmake_generate_options = { }, -- this will be passed when invoke `CMakeGenerate`
  cmake_build_options = { }, -- this will be passed when invoke `CMakeBuild`
  -- support macro expansion:
  --       ${kit}
  --       ${kitGenerator}
  --       ${variant:xx}
  cmake_build_directory = function()
    if osys.iswin32 then
      return "build"
    end
    return "build"
  end, -- this is used to specify generate directory for cmake, allows macro expansion, can be a string or a function returning the string, relative to cwd.
  cmake_compile_commands_options = {
    action = "soft_link", -- available options: soft_link, copy, lsp, none
    target = vim.loop.cwd, -- path or function returning path to directory, this is used only if action == "soft_link" or action == "copy"
  },
  cmake_kits_path = nil, -- this is used to specify global cmake kits path, see CMakeKits for detailed usage
  cmake_variants_message = {
    short = { show = true }, -- whether to show short message
    long = { show = true, max_length = 40 }, -- whether to show long message
  },
  cmake_dap_configuration = { -- debug settings for cmake
    name = "cpp",
    type = "codelldb",
    request = "launch",
    stopOnEntry = false,
    runInTerminal = true,
    console = "integratedTerminal",
  },
  cmake_executor = { -- executor to use
    name = "quickfix", -- name of the executor
    opts = {}, -- the options the executor will get, possible values depend on the executor type. See `default_opts` for possible values.
    default_opts = { -- a list of default and possible values for executors
      quickfix = {
        show = "always", -- "always", "only_on_error"
        position = "belowright", -- "vertical", "horizontal", "leftabove", "aboveleft", "rightbelow", "belowright", "topleft", "botright", use `:h vertical` for example to see help on them
        size = 8,
        encoding = "utf-8", -- if encoding is not "utf-8", it will be converted to "utf-8" using `vim.fn.iconv`
        auto_close_when_success = true, -- typically, you can use it with the "always" option; it will auto-close the quickfix buffer if the execution is successful.
      },
      toggleterm = {
        direction = "float", -- 'vertical' | 'horizontal' | 'tab' | 'float'
        close_on_exit = true, -- whether close the terminal when exit
        auto_scroll = true, -- whether auto scroll to the bottom
        singleton = true, -- single instance, autocloses the opened one, if present
      },
      overseer = {
        new_task_opts = {
            strategy = {
                "toggleterm",
                direction = "horizontal",
                auto_scroll = true,
                quit_on_exit = "success"
            }
        }, -- options to pass into the `overseer.new_task` command
        on_new_task = function(task)
            require("overseer").open(
                { enter = false, direction = "right" }
            )
        end,   -- a function that gets overseer.Task when it is created, before calling `task:start`
      },
      terminal = {
        name = "Main Terminal",
        prefix_name = "[CMakeTools]: ", -- This must be included and must be unique, otherwise the terminals will not work. Do not use a simple spacebar " ", or any generic name
        split_direction = "horizontal", -- "horizontal", "vertical"
        split_size = 8,

        -- Window handling
        single_terminal_per_instance = true, -- Single viewport, multiple windows
        single_terminal_per_tab = true, -- Single viewport per tab
        keep_terminal_static_location = true, -- Static location of the viewport if avialable
        auto_resize = true, -- Resize the terminal if it already exists

        -- Running Tasks
        start_insert = false, -- If you want to enter terminal with :startinsert upon using :CMakeRun
        focus = false, -- Focus on terminal when cmake task is launched.
        do_not_add_newline = false, -- Do not hit enter on the command inserted when using :CMakeRun, allowing a chance to review or modify the command before hitting enter.
      }, -- terminal executor uses the values in cmake_terminal
    },
  },
  cmake_runner = { -- runner to use
    name = "terminal", -- name of the runner
    opts = {}, -- the options the runner will get, possible values depend on the runner type. See `default_opts` for possible values.
    default_opts = { -- a list of default and possible values for runners
      quickfix = {
        show = "always", -- "always", "only_on_error"
        position = "belowright", -- "bottom", "top"
        size = 8,
        encoding = "utf-8",
        auto_close_when_success = true, -- typically, you can use it with the "always" option; it will auto-close the quickfix buffer if the execution is successful.
      },
      toggleterm = {
        direction = "float", -- 'vertical' | 'horizontal' | 'tab' | 'float'
        close_on_exit = true, -- whether close the terminal when exit
        auto_scroll = true, -- whether auto scroll to the bottom
        singleton = true, -- single instance, autocloses the opened one, if present
      },
      overseer = {
        new_task_opts = {
            strategy = {
                "toggleterm",
                direction = "horizontal",
                autos_croll = true,
                quit_on_exit = "success"
            }
        }, -- options to pass into the `overseer.new_task` command
        on_new_task = function(task)
        end,   -- a function that gets overseer.Task when it is created, before calling `task:start`
      },
      terminal = {
        name = "Main Terminal",
        prefix_name = "[CMakeTools]: ", -- This must be included and must be unique, otherwise the terminals will not work. Do not use a simple spacebar " ", or any generic name
        split_direction = "horizontal", -- "horizontal", "vertical"
        split_size = 11,

        -- Window handling
        single_terminal_per_instance = true, -- Single viewport, multiple windows
        single_terminal_per_tab = true, -- Single viewport per tab
        keep_terminal_static_location = true, -- Static location of the viewport if avialable
        auto_resize = true, -- Resize the terminal if it already exists

        -- Running Tasks
        start_insert = false, -- If you want to enter terminal with :startinsert upon using :CMakeRun
        focus = false, -- Focus on terminal when cmake task is launched.
        do_not_add_newline = false, -- Do not hit enter on the command inserted when using :CMakeRun, allowing a chance to review or modify the command before hitting enter.
        use_shell_alias = false, -- Hide the verbose command wrapper by using a shell alias, showing only the program's output (currently not supported on Windows)
      },
    },
  },
  cmake_notifications = {
    runner = { enabled = true },
    executor = { enabled = true },
    spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }, -- icons used for progress display
    refresh_rate_ms = 100, -- how often to iterate icons
  },
  cmake_virtual_text_support = true, -- Show the target related to current file using virtual text (at right corner)
  cmake_use_scratch_buffer = false, -- A buffer that shows what cmake-tools has done
}

-- Most cmake-tools entry points report missing state politely, but a few
-- index the codemodel unguarded and raise a raw lua error instead. These
-- helpers produce the same kind of message the rest of the group gives.
local function project_root()
    local cwd = require('cmake-tools').get_config().cwd
    if cwd == nil or cwd == '' then cwd = vim.loop.cwd() end
    return tostring(cwd)
end
local function has_project()
    local root = project_root()
    if vim.fn.filereadable(root .. '/CMakeLists.txt') == 0 then
        vim.notify('CMake: no CMakeLists.txt in ' .. root, vim.log.levels.WARN)
        return false
    end
    return true
end
local function is_configured()
    if not has_project() then return false end
    local dir = tostring(require('cmake-tools').get_build_directory())
    if dir == '' or vim.fn.filereadable(dir .. '/CMakeCache.txt') == 0 then
        vim.notify('CMake: not configured yet, run <leader>mg first', vim.log.levels.WARN)
        return false
    end
    return true
end

map('<leader>mg', 'CMakeGenerate',           'CMake: configure')
map('<leader>mb', 'CMakeBuild',              'CMake: build target')
vim.keymap.set('n', '<leader>mf', function()
    -- build_current_file indexes the codemodel, which only exists post-configure
    if not is_configured() then return end
    require('cmake-tools').build_current_file({ fargs = {} })
end, { desc = 'CMake: build targets using this file' })
map('<leader>mr', 'CMakeRun',                'CMake: run')
vim.keymap.set('n', '<leader>mR', function()
    vim.ui.input({ prompt = 'Launch args args: ' }, function(args)
        if args then vim.cmd('CMakeLaunchArgs ' .. args) end
    end)
end, { desc = 'CMake: set launch args' })
vim.keymap.set('n', '<leader>md', function()
    local cmake = require('cmake-tools')
    if not is_configured() then return end
    -- on a non-debuggable build type cmake-tools reprompts for one and calls
    -- itself again regardless of the answer, so cancelling loops forever
    if not cmake.get_config():validate_for_debugging():is_ok() then
        vim.notify('CMake: build type ' .. tostring(cmake.get_build_type()) ..
            ' has no debug info, pick one with <leader>mT', vim.log.levels.WARN)
        return
    end
    cmake.debug({})
end, { desc = 'CMake: debug' })
map('<leader>mC', 'CMakeClean',              'CMake: clean')
vim.keymap.set('n', '<leader>mw', function()
    local dir = tostring(require('cmake-tools').get_build_directory())
    if dir == nil or dir == '' then
        vim.notify('CMake: no build directory configured', vim.log.levels.WARN)
        return
    end
    if vim.fn.isdirectory(dir) == 0 then
        vim.notify('CMake: build directory does not exist: ' .. dir, vim.log.levels.INFO)
        return
    end
    if vim.fn.confirm('Remove build directory?\n' .. dir, '&Yes\n&No', 2) == 1 then
        vim.fn.delete(dir, 'rf')
        vim.notify('CMake: removed ' .. dir)
    end
end, { desc = 'CMake: remove build dir' })
vim.keymap.set('n', '<leader>mF', function()
    require('cmake-tools').quick_build({ fargs = { 'flash' } })
end, { desc = 'CMake: flash (idf flash target)' })
vim.keymap.set('n', '<leader>mG', function()
    local cmake = require('cmake-tools')
    vim.ui.select({ 'Ninja', 'Unix Makefiles', 'Ninja Multi-Config' },
        { prompt = 'CMake generator:' }, function(gen)
            if not gen then return end
            -- ask for the build type too, so configuring doesn't run with
            -- an unintended default and have to be redone
            vim.schedule(function()
                cmake.select_build_type(function(result)
                    if not result:is_ok() then return end
                    -- generator can't change on an existing build dir; wipe it first
                    local dir = tostring(cmake.get_build_directory())
                    if vim.fn.isdirectory(dir) == 1 then vim.fn.delete(dir, 'rf') end
                    cmake.generate({ fargs = { '-G', gen } }, nil)
                end)
            end)
        end)
end, { desc = 'CMake: select generator + build type + configure' })
map('<leader>mc', 'CMakeSettings',           'CMake: settings')

-- CMakeSettings above edits cmake-tools' own settings; the project's cache is a
-- separate thing and nothing in the plugin lists it. `cmake -LH` is that listing,
-- -N keeps it from reconfiguring behind your back, and the help text for each
-- entry arrives as the `//` lines above it.
local function cache_entries(advanced)
    local dir = tostring(require('cmake-tools').get_build_directory())
    local lines = vim.fn.systemlist({ 'cmake', advanced and '-LAH' or '-LH', '-N', '-B', dir })
    if vim.v.shell_error ~= 0 then
        vim.notify('CMake: ' .. table.concat(lines, '\n'), vim.log.levels.ERROR)
        return {}
    end
    local out, help = {}, {}
    for _, line in ipairs(lines) do
        local comment = line:match('^//(.*)$')
        if comment then
            table.insert(help, vim.trim(comment))
        else
            local name, kind, value = line:match('^([^:]+):(%u+)=(.*)$')
            if name then
                table.insert(out, { name = name, kind = kind, value = value,
                    help = table.concat(help, ' ') })
            end
            help = {}
        end
    end
    return out
end

-- cmake's own truthiness: false is only these constants and a *-NOTFOUND
local function cmake_true(value)
    local v = value:upper()
    return not (v == '' or v == '0' or v == 'OFF' or v == 'NO' or v == 'FALSE'
        or v == 'N' or v == 'IGNORE' or v == 'NOTFOUND' or v:match('%-NOTFOUND$'))
end

local function ellipsis(text, width)
    if #text <= width then return text end
    return text:sub(1, width - 1) .. '\u{2026}'
end

-- A pick edits a pending set instead of reconfiguring, so flipping four options
-- costs one configure run rather than four; closing the picker applies them.
local function browse_cache(advanced)
    if not is_configured() then return end
    local entries = cache_entries(advanced)
    if #entries == 0 then
        vim.notify('CMake: no cache entries in ' ..
            tostring(require('cmake-tools').get_build_directory()), vim.log.levels.WARN)
        return
    end

    local pending = {}
    local function value_of(e) return pending[e.name] or e.value end

    local function apply()
        local args, changed = {}, {}
        for _, e in ipairs(entries) do
            if pending[e.name] then
                table.insert(args, ('-D%s:%s=%s'):format(e.name, e.kind, pending[e.name]))
                table.insert(changed, ('  %s = %s'):format(e.name, pending[e.name]))
            end
        end
        if #args == 0 then return end
        if vim.fn.confirm('Reconfigure with:\n' .. table.concat(changed, '\n'),
            '&Yes\n&No', 1) == 1 then
            require('cmake-tools').generate({ fargs = args }, nil)
        end
    end

    local function pick()
        vim.ui.select(entries, {
            prompt = advanced and 'CMake cache (advanced):' or 'CMake cache:',
            format_item = function(e)
                local value = value_of(e)
                return ('%s %-38s %-9s %-22s %s'):format(
                    pending[e.name] and '*' or ' ',
                    ellipsis(e.name, 38), e.kind:lower(),
                    ellipsis(value ~= '' and value or '<empty>', 22),
                    ellipsis(e.help, 60))
            end,
        }, function(e)
            -- cancelling is the way out, so that is where the changes are applied
            if not e then return vim.schedule(apply) end
            if e.kind == 'BOOL' then
                pending[e.name] = cmake_true(value_of(e)) and 'OFF' or 'ON'
                return vim.schedule(pick)
            end
            vim.ui.input({
                prompt = e.name .. ' (' .. e.kind:lower() .. '): ',
                default = value_of(e),
                completion = (e.kind == 'PATH' or e.kind == 'FILEPATH') and 'file' or nil,
            }, function(input)
                if input then pending[e.name] = input end
                vim.schedule(pick)
            end)
        end)
    end

    pick()
end

vim.keymap.set('n', '<leader>mv', function() browse_cache(false) end,
    { desc = 'CMake: cache options' })
vim.keymap.set('n', '<leader>mV', function() browse_cache(true) end,
    { desc = 'CMake: cache options, including advanced' })
map('<leader>ms', 'CMakeStopRunner',         'CMake: stop')
map('<leader>mS', 'CMakeStopExecutor',       'CMake: stop')
-- ctest lives under <leader>mt. cmake-tools' run_test drives a picker and
-- forwards only a single extra argument, so the direct runs below go through
-- utils.run themselves.
local function ctest_build_dir()
    local dir = tostring(require('cmake-tools').get_build_directory())
    if dir == '' or vim.fn.isdirectory(dir) == 0 then
        vim.notify('CTest: no build directory', vim.log.levels.WARN)
        return nil
    end
    return dir
end
local function ctest_run(dir, args)
    local cmake = require('cmake-tools')
    local cfg = cmake.get_config()
    -- a test preset picked with <leader>mpt names its own test dir
    local preset = cmake.get_test_preset()
    local argv = preset and { '--preset', preset } or { '--test-dir', dir }
    require('cmake-tools.utils').run(
        'ctest', cfg.env_script,
        require('cmake-tools.environment').get_build_environment(cfg),
        vim.list_extend(argv, args),
        cfg.cwd, cfg.runner, nil)
end

vim.keymap.set('n', '<leader>mta', function()
    local dir = ctest_build_dir()
    if dir == nil then return end
    -- plain ctest says only "N tests failed"; show what actually broke
    ctest_run(dir, { '--output-on-failure' })
end, { desc = 'CTest: run all tests' })
vim.keymap.set('n', '<leader>mtb', function()
    -- ctest never builds, so on its own it happily tests a stale binary after
    -- a source edit; the build directory check waits until after the build,
    -- which creates and configures that directory when it is missing
    require('cmake-tools').build({ fargs = {} }, function(result)
        if not result:is_ok() then return end
        vim.schedule(function()
            local dir = ctest_build_dir()
            if dir == nil then return end
            ctest_run(dir, { '--output-on-failure' })
        end)
    end)
end, { desc = 'CTest: build then run all tests' })
vim.keymap.set('n', '<leader>mts', function()
    require('cmake-tools').run_test({ fargs = {}, args = '--output-on-failure' })
end, { desc = 'CTest: pick test or label to run' })
vim.keymap.set('n', '<leader>mtr', function()
    local dir = ctest_build_dir()
    if dir == nil then return end
    vim.ui.input({ prompt = 'CTest name regex: ' }, function(pattern)
        if not pattern or pattern == '' then return end
        ctest_run(dir, { '-R', pattern, '--output-on-failure' })
    end)
end, { desc = 'CTest: run tests matching regex' })
vim.keymap.set('n', '<leader>mtu', function()
    local dir = ctest_build_dir()
    if dir == nil then return end
    -- flaky hunts target one test, so reuse whatever <leader>mts picked last;
    -- that field also holds the picker's "all" and "[label] ..." rows, which
    -- are not test names and cannot be passed to -R
    local target = require('cmake-tools').get_config().selected_test
    if target == 'all' or (target and target:match('^%[label%]')) then
        target = nil
    end
    vim.ui.input(
        { prompt = 'Repeat ' .. (target or 'all tests') .. ' until fail, runs: ', default = '10' },
        function(count)
            if not count or not count:match('^%d+$') then return end
            local args = { '--repeat', 'until-fail:' .. count, '--output-on-failure' }
            if target then vim.list_extend(args, { '-R', target }) end
            ctest_run(dir, args)
        end)
end, { desc = 'CTest: repeat until fail' })
vim.keymap.set('n', '<leader>mtf', function()
    local dir = ctest_build_dir()
    if dir == nil then return end
    -- --rerun-failed reads LastTestsFailed.log, written by the previous run
    if vim.fn.filereadable(dir .. '/Testing/Temporary/LastTestsFailed.log') == 0 then
        vim.notify('CTest: no failed tests recorded yet', vim.log.levels.INFO)
        return
    end
    ctest_run(dir, { '--rerun-failed', '--output-on-failure' })
end, { desc = 'CTest: rerun failed tests' })
vim.keymap.set('n', '<leader>mtl', function()
    local dir = ctest_build_dir()
    if dir == nil then return end
    -- ctest overwrites this on every run, so it is the last run's full output
    local log = dir .. '/Testing/Temporary/LastTest.log'
    if vim.fn.filereadable(log) == 0 then
        vim.notify('CTest: no test log at ' .. log, vim.log.levels.INFO)
        return
    end
    vim.cmd('edit ' .. vim.fn.fnameescape(log))
end, { desc = 'CTest: open last test log' })
vim.keymap.set('n', '<leader>mi', function()
    if not is_configured() then return end
    require('cmake-tools').install({ fargs = {} }, nil)
end, { desc = 'CMake: install' })
local install_prefix = nil
vim.keymap.set('n', '<leader>mI', function()
    if not is_configured() then return end
    vim.ui.input(
        { prompt = 'Install prefix: ', default = install_prefix or vim.fn.expand('~/.local'), completion = 'dir' },
        function(prefix)
            if not prefix or prefix == '' then return end
            install_prefix = prefix
            require('cmake-tools').install({ fargs = { '--prefix', vim.fn.expand(prefix) } }, nil)
        end)
end, { desc = 'CMake: install to prefix' })
map('<leader>mpc', 'CMakeSelectConfigurePreset', 'CMake: select configure preset')
map('<leader>mpb', 'CMakeSelectBuildPreset',     'CMake: select build preset')
map('<leader>mpt', 'CMakeSelectTestPreset',      'CMake: select test preset')
map('<leader>mT', 'CMakeSelectBuildType',    'CMake: select build type')
map('<leader>mB', 'CMakeSelectBuildTarget',  'CMake: select build target')
map('<leader>mL', 'CMakeSelectLaunchTarget', 'CMake: select launch target')
map('<leader>mK', 'CMakeSelectKit',          'CMake: select kit')
map('<leader>mo', 'CMakeOpenRunner',         'CMake: open panel')
map('<leader>mO', 'CMakeOpenExecutor',       'CMake: open panel')
map('<leader>mx', 'CMakeCloseRunner',        'CMake: close panel')
map('<leader>mX', 'CMakeCloseExecutor',      'CMake: close panel')
