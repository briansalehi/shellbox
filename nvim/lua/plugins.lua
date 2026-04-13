-- abandoned
-- vim.pack.add({'https://github.com/puremourning/vimspector'}) -- duplicates nvim-gdb
-- vim.pack.add({'https://github.com/dense-analysis/ale'}) -- conflicts with already using vim.lsp
-- vim.pack.add({'https://github.com/neovim/nvim-lspconfig'}) -- conflicts with already using vim.lsp
-- vim.pack.add({'https://github.com/Valloric/YouCompleteMe'}) -- conflicts with already using vim.lsp and nvim-cmp
-- vim.pack.add({'https://github.com/neoclide/coc.nvim'}) -- conflicts with already using vim.lsp
-- vim.pack.add({'https://github.com/ms-jpq/coq_nvim'}) -- conflicts with already using vim.lsp
-- vim.pack.add({'https://github.com/s1n7ax/nvim-terminal'}) -- conflicts with toggleterm required by cmake-tools
-- vim.pack.add({'https://github.com/nvim-lua/completion-nvim'}) -- outdated and unmaintained
-- vim.pack.add({'https://github.com/SirVer/ultisnips'}) -- conflicts with LuaSnip
-- vim.pack.add({'https://github.com/honza/vim-snippets'}) -- useless, required by ultisnips
-- vim.pack.add({'https://github.com/cdelledonne/vim-cmake'}) -- conflicts with cmake-tools
-- vim.pack.add({'https://github.com/octol/vim-cpp-enhanced-highlight'}) -- conflicts with treesitter

-- color scheme
vim.pack.add({'https://github.com/folke/tokyonight.nvim'})
-- vim.pack.add({'https://github.com/rafi/awesome-vim-colorschemes'})
-- vim.pack.add({'https://github.com/joshdick/onedark.vim'})

vim.cmd('colorscheme tokyonight')

-- telescope
vim.pack.add({
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/nvim-tree/nvim-web-devicons',
    'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
    'https://github.com/nvim-telescope/telescope.nvim'
})

require('telescope').setup({
  defaults = {
    file_ignore_patterns = { 'build/', '.git/', '.idea/' },
  },
  pickers = {
      find_files = {
      }
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

-- tree sitter
vim.pack.add({'https://github.com/nvim-treesitter/nvim-treesitter'})
require('nvim-treesitter').setup({
    ensure_installed = {'cpp', 'lua', 'cmake'},
    highlight = { enable = true }
})

-- vim last place
vim.pack.add({'https://github.com/farmergreg/vim-lastplace'})

-- nvim surround
vim.pack.add({'https://github.com/kylechui/nvim-surround'})

-- vim commentary
vim.pack.add({'https://github.com/tpope/vim-commentary'})

-- completion
vim.pack.add({
    'https://github.com/hrsh7th/nvim-cmp',
    'https://github.com/hrsh7th/cmp-nvim-lsp',
    'https://github.com/hrsh7th/cmp-buffer',
    'https://github.com/L3MON4D3/LuaSnip',
    'https://github.com/saadparwaiz1/cmp_luasnip',
})

local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
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
        { name = 'luasnip' },
    }, {
        { name = 'buffer' },
    }),
})

-- git blame
vim.pack.add({'https://github.com/zivyangll/git-blame.vim'})

-- vim airline
-- vim.pack.add({'https://github.com/vim-airline/vim-airline.git'})

-- nerd tree
vim.pack.add({'https://github.com/scrooloose/nerdtree'})
-- vim.pack.add({'https://github.com/preservim/nerdtree'})

-- tag bar
vim.pack.add({'https://github.com/preservim/tagbar'})

-- dashboard
vim.pack.add({'https://github.com/glepnir/dashboard-nvim'})

-- code highlighting
vim.pack.add({
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/stevearc/overseer.nvim',
    'https://github.com/akinsho/toggleterm.nvim',
    'https://github.com/Civitasv/cmake-tools.nvim'
})

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
      return "build-${variant:buildType}"
    end
    return "build-${variant:buildType}"
  end, -- this is used to specify generate directory for cmake, allows macro expansion, can be a string or a function returning the string, relative to cwd.
  cmake_compile_commands_options = {
    action = "none", -- available options: soft_link, copy, lsp, none
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

-- git plugin
vim.pack.add({'https://github.com/tpope/vim-fugitive'})

vim.pack.add({'https://github.com/dkarter/bullets.vim'})

vim.pack.add({'https://github.com/shime/vim-livedown'})

vim.pack.add({'https://github.com/szw/vim-maximizer'})

-- trailer trash
vim.pack.add({'https://github.com/csexton/trailertrash.vim'})

-- gdb plugin
vim.pack.add({'https://github.com/sakhnik/nvim-gdb'})
