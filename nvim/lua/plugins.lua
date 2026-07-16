-- abandoned
-- 'vimspector' -- duplicates nvim-gdb
-- 'ale' -- conflicts with already using vim.lsp
-- 'nvim-lspconfig' -- conflicts with already using vim.lsp
-- 'YouCompleteMe' -- conflicts with already using vim.lsp and nvim-cmp
-- 'coc.nvim' -- conflicts with already using vim.lsp
-- 'coq_nvim' -- conflicts with already using vim.lsp
-- 'nvim-terminal' -- conflicts with toggleterm required by cmake-tools
-- 'completion-nvim' -- outdated and unmaintained
-- 'ultisnips' -- conflicts with luasnip
-- 'vim-snippets' -- useless, required by ultisnips
-- 'vim-cmake' -- conflicts with cmake-tools
-- 'vim-cpp-enhanced-highlight' -- conflicts with treesitter
-- 'gitsign', 'gitdiff' -- replaced by diffview
-- 'vim-airline' -- replaced by lualine

vim.pack.add({
    'https://github.com/folke/which-key.nvim',
    'https://github.com/Shatur/neovim-ayu',
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/nvim-tree/nvim-web-devicons',
    'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
    'https://github.com/nvim-telescope/telescope.nvim',
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/farmergreg/vim-lastplace',
    'https://github.com/kylechui/nvim-surround',
    'https://github.com/tpope/vim-commentary',
    'https://github.com/hrsh7th/nvim-cmp',
    'https://github.com/hrsh7th/cmp-nvim-lsp',
    'https://github.com/hrsh7th/cmp-buffer',
    'https://github.com/L3MON4D3/LuaSnip',
    'https://github.com/saadparwaiz1/cmp_luasnip',
    'https://github.com/rafamadriz/friendly-snippets',
    'https://github.com/sindrets/diffview.nvim',
    'https://github.com/NeogitOrg/neogit',
    'https://github.com/nvim-lualine/lualine.nvim',
    'https://github.com/preservim/tagbar',
    'https://github.com/glepnir/dashboard-nvim',
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/stevearc/overseer.nvim',
    'https://github.com/akinsho/toggleterm.nvim',
    'https://github.com/Civitasv/cmake-tools.nvim',
    'https://github.com/stevearc/conform.nvim',
    'https://github.com/stevearc/oil.nvim',
    'https://github.com/dkarter/bullets.vim',
    'https://github.com/shime/vim-livedown',
    'https://github.com/szw/vim-maximizer',
    'https://github.com/p00f/clangd_extensions.nvim',
    'https://github.com/mfussenegger/nvim-dap',
    'https://github.com/rcarriga/nvim-dap-ui',
    'https://github.com/nvim-neotest/nvim-nio',
    'https://github.com/greggh/claude-code.nvim',
    'https://github.com/folke/flash.nvim',
    'https://github.com/folke/trouble.nvim',
    'https://github.com/nvim-mini/mini.ai',
    'https://github.com/rmagatti/auto-session',
    'https://github.com/mbbill/undotree',
    { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' }
})

-- ayu
require('ayu').setup({
    mirage = false, -- Set to `true` to use `mirage` variant instead of `dark` for dark background.
    terminal = true, -- Set to `false` to let terminal manage its own colors.
    overrides = {
        LineNr = { fg = '#7A3030' },
    }, -- A dictionary of group names, each associated with a dictionary of parameters (`bg`, `fg`, `sp` and `style`) and colors in hex.
})

vim.cmd('colorscheme ayu')

-- telescope
require('telescope').setup({
  defaults = {
    file_ignore_patterns = { 'build/', '.git/', '.idea/' },
  },
  pickers = {
      find_files = {
          hidden = true,
      },
      buffers = {
          mappings = {
              n = { ['<C-d>'] = require('telescope.actions').delete_buffer },
              i = { ['<C-d>'] = require('telescope.actions').delete_buffer },
          },
      },
  },
  extensions = {
  }
})

local telescope_builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', telescope_builtin.find_files)
vim.keymap.set('n', '<leader>fg', telescope_builtin.live_grep)
vim.keymap.set('n', '<leader>fi', telescope_builtin.git_files)
vim.keymap.set('n', '<leader>fb', telescope_builtin.buffers)
vim.keymap.set('n', '<leader>fh', telescope_builtin.help_tags)
vim.keymap.set('n', '<leader>fk', telescope_builtin.keymaps,   { desc = 'Find keymaps' })

-- tree sitter
require('nvim-treesitter').install({"c", "cpp", "lua", "cmake", "python", "rust"})

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'c', 'cpp', 'lua', 'cmake', 'python', 'rust' },
    callback = function()
        pcall(vim.treesitter.start)
    end,
})

-- completion
local cmp = require('cmp')

-- luasnip
local luasnip = require('luasnip')
require('luasnip.loaders.from_vscode').lazy_load()

cmp.setup({
    completion = { autocomplete = false },
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>']     = cmp.mapping.abort(),
        ['<CR>']      = cmp.mapping.confirm({ select = false }),
        ['<Tab>']     = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
        end, { 'i', 's' }),
        ['<S-Tab>']   = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
        end, { 'i', 's' }),
        ['<C-k>']     = cmp.mapping.scroll_docs(-4),
        ['<C-j>']     = cmp.mapping.scroll_docs(4),
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
    }, {
        { name = 'buffer' },
    }),
})

-- diffview
require('diffview').setup()
do
    local map = function(lhs, cmd, desc)
        vim.keymap.set('n', lhs, '<cmd>' .. cmd .. '<CR>', { desc = desc })
    end
    map('<leader>gd', 'DiffviewOpen',                    'Git: diff working tree')
    map('<leader>gh', 'DiffviewFileHistory %',           'Git: file history')
    map('<leader>gH', 'DiffviewFileHistory',             'Git: repo history')
    map('<leader>gc', 'DiffviewClose',                   'Git: close')
end

-- neogit
require('neogit').setup({
    integrations = { diffview = true, telescope = true },
})
do
    local map = function(lhs, cmd, desc)
        vim.keymap.set('n', lhs, '<cmd>' .. cmd .. '<CR>', { desc = desc })
    end
    map('<leader>gg', 'Neogit',        'Git: status (stage here)')
    map('<leader>gC', 'Neogit commit', 'Git: commit')
    map('<leader>gp', 'Neogit push',   'Git: push')
    map('<leader>gP', 'Neogit pull',   'Git: pull')
end

-- lualine
require('lualine').setup({
    options = {
        theme = 'auto',
        component_separators = { left = '|', right = '|' },
        section_separators   = { left = '', right = '' },
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
    },
})

-- dashboard
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'dashboard',
    callback = function()
        vim.api.nvim_create_autocmd('BufLeave', {
            buffer = 0,
            once = true,
            callback = function() vim.opt.signcolumn = 'yes' end,
        })
    end,
})

-- cmake tools
local osys = require("cmake-tools.osys")
require("cmake-tools").setup {
  cmake_command = "cmake", -- this is used to specify cmake command path
  ctest_command = "ctest", -- this is used to specify ctest command path
  ctest_show_labels = false, -- also show labels in the test picker
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

-- Activate the ESP-IDF environment for this nvim session so cmake-tools'
-- cmake/ninja/clangd subprocesses find the toolchain + python venv.
--   :IdfActivate            -> source export.sh into vim.env
--   :IdfActivate esp32s3    -> same, and set IDF_TARGET (picked up by <leader>mg)
vim.api.nvim_create_user_command('IdfActivate', function(o)
  local idf = vim.env.IDF_PATH or (vim.env.HOME .. '/.local/src/esp-idf')
  -- text = false keeps stdout as raw bytes so env -0's NUL delimiters survive
  -- (vim.fn.system would translate NUL -> newline and collapse the parse).
  local res = vim.system({ 'bash', '-c',
    'source "' .. idf .. '/export.sh" >/dev/null 2>&1 && env -0' },
    { text = false }):wait()
  if res.code ~= 0 then
    vim.notify('IdfActivate: export.sh failed (IDF_PATH=' .. idf .. ')', vim.log.levels.ERROR)
    return
  end
  for _, line in ipairs(vim.split(res.stdout or '', '\0', { plain = true })) do
    local k, v = line:match('^([^=]+)=(.*)$')
    if k then vim.env[k] = v end
  end
  local target = o.fargs[1]
  if target then vim.env.IDF_TARGET = target end
  vim.notify('ESP-IDF activated' .. (target and (' (target=' .. target .. ')') or ''))
end, { nargs = '?', desc = 'Activate ESP-IDF environment (optional target arg)' })

-- Set the serial port for the flash target (esptool reads ESPPORT; = idf.py -p),
-- mirroring how :IdfActivate controls IDF_TARGET.
--   :IdfSetPort /dev/ttyUSB0   -> set ESPPORT
--   :IdfSetPort                -> show current ESPPORT
vim.api.nvim_create_user_command('IdfSetPort', function(o)
  if o.args == '' then
    vim.notify('ESPPORT = ' .. (vim.env.ESPPORT or '(unset)'))
    return
  end
  vim.env.ESPPORT = o.args
  vim.notify('ESPPORT = ' .. o.args)
end, {
  nargs = '?',
  complete = function(arglead)
    local ports = {}
    for _, pat in ipairs({ '/dev/ttyUSB*', '/dev/ttyACM*' }) do
      vim.list_extend(ports, vim.fn.glob(pat, true, true))
    end
    return vim.tbl_filter(function(p) return p:find(arglead, 1, true) == 1 end, ports)
  end,
  desc = 'Set ESP-IDF serial port (ESPPORT)',
})

do
    local map = function(lhs, cmd, desc)
        vim.keymap.set('n', lhs, '<cmd>' .. cmd .. '<CR>', { desc = desc })
    end
    map('<leader>mg', 'CMakeGenerate',           'CMake: configure')
    map('<leader>mb', 'CMakeBuild',              'CMake: build target')
    map('<leader>mf', 'CMakeBuildCurrentFile',   'CMake: build targets using this file')
    map('<leader>mr', 'CMakeRun',                'CMake: run')
    vim.keymap.set('n', '<leader>mR', function()
        vim.ui.input({ prompt = 'Launch args args: ' }, function(args)
            if args then vim.cmd('CMakeLaunchArgs ' .. args) end
        end)
    end, { desc = 'CMake: set launch args' })
    vim.keymap.set('n', '<leader>md', function() require('cmake-tools').debug({}) end, { desc = 'CMake: debug' })
    map('<leader>mc', 'CMakeClean',              'CMake: clean')
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
        vim.ui.select({ 'Ninja', 'Unix Makefiles', 'Ninja Multi-Config' },
            { prompt = 'CMake generator:' }, function(gen)
                if not gen then return end
                -- generator can't change on an existing build dir; wipe it first
                local dir = tostring(require('cmake-tools').get_build_directory())
                if vim.fn.isdirectory(dir) == 1 then vim.fn.delete(dir, 'rf') end
                require('cmake-tools').generate({ fargs = { '-G', gen } }, nil)
            end)
    end, { desc = 'CMake: select generator + configure' })
    map('<leader>mC', 'CMakeSettings',           'CMake: settings')
    map('<leader>ms', 'CMakeStopRunner',         'CMake: stop')
    map('<leader>mS', 'CMakeStopExecutor',       'CMake: stop')
    map('<leader>mt', 'CMakeRunTest',             'CMake: test')
    map('<leader>mi', 'CMakeInstall',            'CMake: install')
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
end

-- conform.nvim - uncrustify formatter
require('conform').setup({
    formatters_by_ft = {
        c   = { 'uncrustify' },
        cpp = { 'uncrustify' },
    },
    formatters = {
        uncrustify = {
            prepend_args = { '-c', '.uncrustify.cfg' },
        },
    },
})
vim.keymap.set('n', '<leader>uf', function() require('conform').format({ async = true }) end, { desc = 'Uncrustify format buffer' })
vim.keymap.set('v', '<leader>uf', function() require('conform').format({ async = true }) end, { desc = 'Uncrustify format selection' })

-- oil.nvim - filesystem manager
require('oil').setup({
    view_options = { show_hidden = true },
})
vim.keymap.set('n', '<leader>e', '<cmd>Oil<CR>', { desc = 'Explorer: open directory' })
vim.keymap.set('n', '-',         '<cmd>Oil<CR>', { desc = 'Explorer: open directory' })

-- trailing whitespace: highlight and trim on save
vim.api.nvim_set_hl(0, 'TrailingWhitespace', { bg = '#ff0000' })
vim.fn.matchadd('TrailingWhitespace', [[\s\+$]])
vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*',
    callback = function()
        local pos = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[%s/\s\+$//e]])
        vim.api.nvim_win_set_cursor(0, pos)
    end,
})

-- clangd extensions
require("clangd_extensions").setup({
    inlay_hints = {
        inline = true,
        only_current_line = false,
        only_current_line_autocmd = { "CursorHold" },
        show_parameter_hints = true,
        parameter_hints_prefix = "<- ",
        other_hints_prefix = "=> ",
    },
    ast = {
        role_icons = {
            type = "",
            declaration = "",
            expression = "",
            specifier = "",
            statement = "",
            ["template argument"] = "",
        },
        kind_icons = {
            Compound = "",
            Recovery = "",
            TranslationUnit = "",
            PackExpansion = "",
            TemplateTypeParm = "",
            TemplateTemplateParm = "",
            TemplateParamObject = "",
        },
    },
    memory_usage = { border = "rounded" },
    symbol_info  = { border = "rounded" },
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "clangd" then
            local buf = args.buf
            local map = vim.keymap.set
            map("n", "<leader>lh", "<cmd>ClangdToggleInlayHints<CR>",   { buffer = buf, desc = "Toggle inlay hints" })
            map("n", "<leader>ls", "<cmd>ClangdSwitchSourceHeader<CR>", { buffer = buf, desc = "Switch source/header" })
            map("n", "<leader>la", "<cmd>ClangdAST<CR>",                { buffer = buf, desc = "Show AST" })
            map("n", "<leader>lm", "<cmd>ClangdMemoryUsage<CR>",        { buffer = buf, desc = "Memory usage" })
            map("n", "<leader>lt", "<cmd>ClangdTypeHierarchy<CR>",      { buffer = buf, desc = "Type hierarchy" })
            map("n", "<leader>lS", "<cmd>ClangdSymbolInfo<CR>",         { buffer = buf, desc = "Symbol info" })
            map("n", "<leader>li", function()
                vim.lsp.buf.code_action({
                    apply = true,
                    filter = function(action)
                        return action.title and action.title:match("Define in source file")
                    end,
                })
            end, { buffer = buf, desc = "Implement function in source file" })
            map("n", "<leader>lI", function()
                vim.lsp.buf.code_action({
                    apply = true,
                    filter = function(action)
                        return action.title and action.title:match("Move function body to declaration")
                    end,
                })
            end, { buffer = buf, desc = "Implement function inline at declaration" })
        end
    end,
})

-- nvim-dap + codelldb

local dap = require('dap')
local dapui = require('dapui')

dap.adapters.codelldb = {
    type = 'server',
    port = '${port}',
    executable = {
        command = vim.fn.expand('~/.local/share/nvim/codelldb/extension/adapter/codelldb'),
        args = { '--port', '${port}' },
    },
}

dapui.setup()

vim.fn.sign_define('DapBreakpoint',         { text = "\u{F111}", texthl = 'DapBreakpoint',         linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointCondition',{ text = "\u{F444}", texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
vim.fn.sign_define('DapLogPoint',           { text = "\u{F27A}", texthl = 'DapLogPoint',            linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped',            { text = "\u{F04B}", texthl = 'DapStopped',             linehl = 'DapStoppedLine', numhl = '' })
vim.fn.sign_define('DapBreakpointRejected', { text = "\u{F05E}", texthl = 'DapBreakpointRejected',  linehl = '', numhl = '' })

vim.api.nvim_set_hl(0, 'DapBreakpoint',         { fg = '#e06c75' })
vim.api.nvim_set_hl(0, 'DapBreakpointCondition',{ fg = '#e5c07b' })
vim.api.nvim_set_hl(0, 'DapLogPoint',           { fg = '#61afef' })
vim.api.nvim_set_hl(0, 'DapStopped',            { fg = '#98c379' })
vim.api.nvim_set_hl(0, 'DapBreakpointRejected', { fg = '#888888' })
vim.api.nvim_set_hl(0, 'DapStoppedLine',        { bg = '#2a3b2a' })

dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
dap.listeners.before.event_exited['dapui_config']     = function() dapui.close() end

-- cmake-tools ran register_dap_function() before nvim-dap was loaded; re-run it now
require('cmake-tools').register_dap_function()

do
    local map = function(lhs, fn, desc)
        vim.keymap.set('n', lhs, fn, { desc = desc })
    end
    map('<leader>dc',   dap.continue,          'DAP: continue')
    map('<leader>dn',   dap.step_over,         'DAP: step over')
    map('<leader>di',   dap.step_into,         'DAP: step into')
    map('<leader>do',   dap.step_out,          'DAP: step out')
    map('<leader>db',   dap.toggle_breakpoint,  'DAP: toggle breakpoint')
    map('<leader>dB',   function()
        dap.set_breakpoint(vim.fn.input('Condition: '))
    end, 'DAP: conditional breakpoint')
    map('<leader>dl',   function()
        dap.set_breakpoint(nil, nil, vim.fn.input('Log message: '))
    end, 'DAP: log point')
    map('<leader>dC',   dap.clear_breakpoints,  'DAP: clear all breakpoints')
    map('<leader>dR',   dap.run_to_cursor,      'DAP: run to cursor')
    map('<leader>dh',   require('dap.ui.widgets').hover, 'DAP: hover variable')
    map('<leader>dx',   dap.terminate,          'DAP: terminate session')
    map('<leader>dr',   dap.repl.open,          'DAP: open REPL')
    map('<leader>du',   dapui.toggle,           'DAP: toggle UI')
end

-- claude code
require("claude-code").setup({
  -- Terminal window settings
  window = {
    split_ratio = 0.3,      -- Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
    position = "botright",  -- Position of the window: "botright", "topleft", "vertical", "float", etc.
    enter_insert = true,    -- Whether to enter insert mode when opening Claude Code
    start_in_normal_mode = true, -- Disable auto-startinsert on WinEnter so scrollback position survives window switches
    hide_numbers = true,    -- Hide line numbers in the terminal window
    hide_signcolumn = true, -- Hide the sign column in the terminal window

    -- Floating window configuration (only applies when position = "float")
    float = {
      width = "80%",        -- Width: number of columns or percentage string
      height = "80%",       -- Height: number of rows or percentage string
      row = "center",       -- Row position: number, "center", or percentage string
      col = "center",       -- Column position: number, "center", or percentage string
      relative = "editor",  -- Relative to: "editor" or "cursor"
      border = "rounded",   -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
    },
  },
  -- File refresh settings
  refresh = {
    enable = true,           -- Enable file change detection
    updatetime = 100,        -- updatetime when Claude Code is active (milliseconds)
    timer_interval = 1000,   -- How often to check for file changes (milliseconds)
    show_notifications = true, -- Show notification when files are reloaded
  },
  -- Git project settings
  git = {
    use_git_root = true,     -- Set CWD to git root when opening Claude Code (if in git project)
  },
  -- Shell-specific settings
  shell = {
    separator = '&&',        -- Command separator used in shell commands
    pushd_cmd = 'pushd',     -- Command to push directory onto stack (e.g., 'pushd' for bash/zsh, 'enter' for nushell)
    popd_cmd = 'popd',       -- Command to pop directory from stack (e.g., 'popd' for bash/zsh, 'exit' for nushell)
  },
  -- Command settings
  command = "claude", -- Command used to launch Claude Code
  -- Command variants
  command_variants = {
    -- Conversation management
    continue = "--continue", -- Resume the most recent conversation
    resume = "--resume",     -- Display an interactive conversation picker

    -- Output options
    verbose = "--verbose",   -- Enable verbose logging with full turn-by-turn output
    verboseContinue = "--verbose --continue", -- Resume last conversation with verbose logging

    -- Permissions
    yolo = "--dangerously-skip-permissions", -- Run every tool without confirmation
    yoloContinue = "--dangerously-skip-permissions --continue", -- Resume last conversation, skipping confirmation
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = "<leader>cc",       -- Normal mode keymap for toggling Claude Code, false to disable
      terminal = "<leader>cc",     -- Terminal mode keymap for toggling Claude Code, false to disable
      variants = {
        continue = "<leader>cC", -- Normal mode keymap for Claude Code with continue flag
        verbose = "<leader>cv",  -- Normal mode keymap for Claude Code with verbose flag
        verboseContinue = "<leader>cV", -- Normal mode keymap for Claude Code with verbose flag, continued
        yolo = "<leader>cy",     -- Normal mode keymap for Claude Code with skipped permissions
        yoloContinue = "<leader>cY", -- Normal mode keymap for Claude Code with skipped permissions, continued
      },
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = false,         -- Enable scrolling keymaps (<C-f/b>) for page up/down
  }
})
local function claude_toggle(cmd)
  return function()
    vim.cmd(cmd)
    vim.schedule(function()
      if vim.bo.buftype == 'terminal' then
        vim.cmd('startinsert')
      end
    end)
  end
end
vim.keymap.set('n', '<leader>cc', claude_toggle('ClaudeCode'),         { desc = 'Toggle Claude Code' })
vim.keymap.set('n', '<leader>cC', claude_toggle('ClaudeCodeContinue'), { desc = 'Toggle Claude Code (continue)' })
vim.keymap.set('n', '<leader>cv', claude_toggle('ClaudeCodeVerbose'),  { desc = 'Toggle Claude Code (verbose)' })
vim.keymap.set('n', '<leader>cV', claude_toggle('ClaudeCodeVerboseContinue'), { desc = 'Toggle Claude Code (verbose, continue)' })
vim.keymap.set('n', '<leader>cy', claude_toggle('ClaudeCodeYolo'),     { desc = 'Toggle Claude Code (skip permissions)' })
vim.keymap.set('n', '<leader>cY', claude_toggle('ClaudeCodeYoloContinue'), { desc = 'Toggle Claude Code (skip permissions, continue)' })
vim.keymap.set({ 'n', 't' }, '<M-r>', function()
  vim.cmd('mode')
end, { desc = 'Redraw terminal' })

-- send Ctrl-L (redraw) straight to the terminal process, staying in insert mode
vim.keymap.set('t', '<M-r>', function()
    vim.fn.chansend(vim.b.terminal_job_id, '\012')  -- \012 = ^L
end, { desc = 'Redraw terminal (send Ctrl-L)' })

-- harpoon
do
    local harpoon = require('harpoon')
    harpoon:setup()

    vim.keymap.set('n', '<leader>a',  function() harpoon:list():add() end,                        { desc = 'Harpoon: add file' })
    vim.keymap.set('n', '<leader>h',  function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon: menu' })
    vim.keymap.set('n', '<leader>1',  function() harpoon:list():select(1) end,                    { desc = 'Harpoon: file 1' })
    vim.keymap.set('n', '<leader>2',  function() harpoon:list():select(2) end,                    { desc = 'Harpoon: file 2' })
    vim.keymap.set('n', '<leader>3',  function() harpoon:list():select(3) end,                    { desc = 'Harpoon: file 3' })
    vim.keymap.set('n', '<leader>4',  function() harpoon:list():select(4) end,                    { desc = 'Harpoon: file 4' })
end

-- flash.nvim
do
    local flash = require('flash')
    flash.setup({ modes = { char = { enabled = false } } })
    vim.keymap.set({ 'n', 'x', 'o' }, '<leader>s', flash.jump,             { desc = 'Flash: jump' })
    vim.keymap.set({ 'n', 'x', 'o' }, '<leader>S', flash.treesitter,       { desc = 'Flash: treesitter' })
    vim.keymap.set('o',               'r',         flash.remote,           { desc = 'Flash: remote' })
    vim.keymap.set({ 'o', 'x' },      'R',         flash.treesitter_search,{ desc = 'Flash: treesitter search' })
    vim.keymap.set('c',               '<C-s>',     flash.toggle,           { desc = 'Flash: toggle in search' })
end

-- trouble.nvim
require('trouble').setup()
do
    local map = function(lhs, cmd, desc)
        vim.keymap.set('n', lhs, '<cmd>Trouble ' .. cmd .. '<cr>', { desc = desc })
    end
    map('<leader>xx', 'diagnostics toggle',                  'Trouble: all diagnostics')
    map('<leader>xd', 'diagnostics toggle filter.buf=0',     'Trouble: buffer diagnostics')
    map('<leader>xq', 'qflist toggle',                       'Trouble: quickfix')
    map('<leader>xl', 'loclist toggle',                      'Trouble: location list')
    map('<leader>xr', 'lsp_references toggle',               'Trouble: LSP references')
    map('<leader>xs', 'lsp_document_symbols toggle',         'Trouble: document symbols')
end

-- mini.ai
require('mini.ai').setup()

-- auto-session
require('auto-session').setup({
    suppressed_dirs = { '~/', '/' },
})

-- undotree
vim.keymap.set('n', '<leader>U', '<cmd>UndotreeToggle<CR>', { desc = 'Undotree: toggle' })

-- quickfix
do
    local map = function(lhs, cmd, desc)
        vim.keymap.set('n', lhs, '<cmd>' .. cmd .. '<CR>', { desc = desc })
    end
    map('<leader>qo', 'copen',  'Quickfix: open')
    map('<leader>qc', 'cclose', 'Quickfix: close')
    map('<leader>qf', 'cfirst', 'Quickfix: first')
    map('<leader>ql', 'clast', 'Quickfix: last')
    map('<leader>qn', 'cnext', 'Quickfix: next')
    map('<leader>qp', 'cprev', 'Quickfix: prev')
end

-- which-key: group labels
local wk = require('which-key')
wk.setup({ delay = 1000 })
wk.add({
    { '<leader>f', group = 'find' },
    { '<leader>e', group = 'oil' },
    { '<leader>m', group = 'cmake' },
    { '<leader>mp', group = 'preset' },
    { '<leader>g', group = 'git' },
    { '<leader>h', group = 'harpoon' },
    { '<leader>d', group = 'debug' },
    { '<leader>l', group = 'lsp' },
    { '<leader>u', group = 'format' },
    { '<leader>c', group = 'claude' },
    { '<leader>r', group = 'refactor' },
    { '<leader>x', group = 'trouble' },
    { '<leader>q', group = 'quickfix' },
})
