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
vim.pack.add({
    'https://github.com/loctvl842/monokai-pro.nvim',
    'https://github.com/folke/tokyonight.nvim',
    'https://github.com/tiagovla/tokyodark.nvim',
    'https://github.com/ellisonleao/gruvbox.nvim',
    'https://github.com/scottmckendry/cyberdream.nvim',
    'https://github.com/Shatur/neovim-ayu',
    'https://github.com/rafi/awesome-vim-colorschemes',
    'https://github.com/joshdick/onedark.vim'
})

require("monokai-pro").setup({
  transparent_background = false,
  terminal_colors = true,
  devicons = true,
  styles = {
    comment = { italic = true },
    keyword = { italic = true },
    type = { italic = true },
    storageclass = { italic = true },
    structure = { italic = true },
    parameter = { italic = true },
    annotation = { italic = true },
    tag_attribute = { italic = true },
  },
  filter = "pro", -- classic | octagon | pro | machine | ristretto | spectrum
  day_night = {
    enable = false,
    day_filter = "pro",
    night_filter = "spectrum",
  },
  inc_search = "background", -- underline | background
  background_clear = {
    "toggleterm",
    "telescope",
    "renamer",
    "notify",
  },
  plugins = {
    bufferline = {
      underline_selected = false,
      underline_visible = false,
      underline_fill = false,
      bold = true,
    },
    indent_blankline = {
      context_highlight = "default", -- default | pro
      context_start_underline = false,
    },
  },
  override = function(scheme)
    return {}
  end,
  override_palette = function(filter)
    return {}
  end,
  override_scheme = function(scheme, palette, colors)
    return {}
  end,
})

require('ayu').setup({
    mirage = false, -- Set to `true` to use `mirage` variant instead of `dark` for dark background.
    terminal = true, -- Set to `false` to let terminal manage its own colors.
    overrides = {}, -- A dictionary of group names, each associated with a dictionary of parameters (`bg`, `fg`, `sp` and `style`) and colors in hex.
})

vim.cmd('colorscheme ayu')

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
          hidden = true,
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
require('nvim-treesitter').install({"c", "cpp", "lua", "cmake"})

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'c', 'cpp', 'lua', 'cmake' },
    callback = function()
        pcall(vim.treesitter.start)
    end,
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

-- gitsigns
vim.pack.add({'https://github.com/lewis6991/gitsigns.nvim'})
require('gitsigns').setup({
    signs = {
        add          = { text = '▎' },
        change       = { text = '▎' },
        delete       = { text = '▁' },
        topdelete    = { text = '▔' },
        changedelete = { text = '▎' },
        untracked    = { text = '▎' },
    },
    on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end
        map('n', ']h', gs.next_hunk,        'Next hunk')
        map('n', '[h', gs.prev_hunk,        'Prev hunk')
        map('n', '<leader>hs', gs.stage_hunk,   'Stage hunk')
        map('n', '<leader>hu', gs.undo_stage_hunk, 'Undo stage hunk')
        map('n', '<leader>hr', gs.reset_hunk,   'Reset hunk')
        map('n', '<leader>hp', gs.preview_hunk, 'Preview hunk')
        map('n', '<leader>hb', gs.blame_line,   'Blame line')
    end,
})

-- lualine
vim.pack.add({'https://github.com/nvim-lualine/lualine.nvim'})
require('lualine').setup({
    options = {
        theme = 'monokai-pro',
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

-- vim airline (replaced by lualine)
-- vim.pack.add({'https://github.com/vim-airline/vim-airline.git'})

-- nerd tree
vim.pack.add({'https://github.com/scrooloose/nerdtree'})
-- vim.pack.add({'https://github.com/preservim/nerdtree'})
vim.keymap.set('n', '<leader>e', ':NERDTreeToggle<CR>', { silent = true, desc = 'Toggle NERDTree' })
vim.keymap.set('n', '<leader>ef', ':NERDTreeFind<CR>',  { silent = true, desc = 'Reveal file in NERDTree' })

-- tag bar
vim.pack.add({'https://github.com/preservim/tagbar'})

-- dashboard
vim.pack.add({'https://github.com/glepnir/dashboard-nvim'})

-- cmake tools
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

do
    local map = function(lhs, cmd, desc)
        vim.keymap.set('n', lhs, '<cmd>' .. cmd .. '<CR>', { desc = desc })
    end
    map('<leader>mg', 'CMakeGenerate',           'CMake: configure')
    map('<leader>mb', 'CMakeBuild',              'CMake: build')
    map('<leader>mf', 'CMakeBuildCurrentFile',   'CMake: build')
    map('<leader>mr', 'CMakeRun',                'CMake: run')
    map('<leader>md', 'CMakeDebug',              'CMake: debug')
    map('<leader>mc', 'CMakeClean',              'CMake: clean')
    map('<leader>mC', 'CMakeSettings',           'CMake: clean')
    map('<leader>ms', 'CMakeStopRunner',         'CMake: stop')
    map('<leader>mS', 'CMakeStopExecutor',       'CMake: stop')
    map('<leader>mt', 'CMakeTest',               'CMake: test')
    map('<leader>mi', 'CMakeInstall',            'CMake: install')
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
vim.pack.add({'https://github.com/stevearc/conform.nvim'})
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
vim.pack.add({'https://github.com/stevearc/oil.nvim'})
require('oil').setup()
vim.keymap.set('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory in oil' })

-- git plugin
vim.pack.add({'https://github.com/tpope/vim-fugitive'})

vim.pack.add({'https://github.com/dkarter/bullets.vim'})

vim.pack.add({'https://github.com/shime/vim-livedown'})

vim.pack.add({'https://github.com/szw/vim-maximizer'})

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
vim.pack.add({'https://github.com/p00f/clangd_extensions.nvim'})
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
            map("n", "<leader>li", "<cmd>ClangdSymbolInfo<CR>",         { buffer = buf, desc = "Symbol info" })
        end
    end,
})

-- gdb plugin
vim.pack.add({'https://github.com/sakhnik/nvim-gdb'})

-- claude code
vim.pack.add({'https://github.com/greggh/claude-code.nvim'})
require("claude-code").setup({
  -- Terminal window settings
  window = {
    split_ratio = 0.3,      -- Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
    position = "botright",  -- Position of the window: "botright", "topleft", "vertical", "float", etc.
    enter_insert = true,    -- Whether to enter insert mode when opening Claude Code
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
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = "<leader>cc",       -- Normal mode keymap for toggling Claude Code, false to disable
      terminal = "<leader>cc",     -- Terminal mode keymap for toggling Claude Code, false to disable
      variants = {
        continue = "<leader>cC", -- Normal mode keymap for Claude Code with continue flag
        verbose = "<leader>cV",  -- Normal mode keymap for Claude Code with verbose flag
      },
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = false,         -- Enable scrolling keymaps (<C-f/b>) for page up/down
  }
})
vim.keymap.set('n', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code' })
