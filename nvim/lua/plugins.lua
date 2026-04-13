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

-- nvim terminal
vim.pack.add({'https://github.com/s1n7ax/nvim-terminal'})

vim.o.hidden = true

require("nvim-terminal").setup({
    window = {
        position = 'botright', -- `:h :botright`
        split = 'sp', -- `:h split`
        width = 50,
        height = 15,
    },
    disable_default_keymaps = false,
    toggle_keymap = '<leader>;',
    window_height_change_amount = 2,
    window_width_change_amount = 2,
    increase_width_keymap = '<leader><leader>+',
    decrease_width_keymap = '<leader><leader>-',
    increase_height_keymap = '<leader>+',
    decrease_height_keymap = '<leader>-',
    terminals = {
        {keymap = '<leader>1'},
        {keymap = '<leader>2'},
        {keymap = '<leader>3'},
        {keymap = '<leader>4'},
        {keymap = '<leader>5'},
    },
})

-- nvim lsp config
vim.pack.add({'https://github.com/neovim/nvim-lspconfig'})

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


vim.pack.add({'https://github.com/dense-analysis/ale'})

-- code highlighting
-- vim.pack.add({'https://github.com/octol/vim-cpp-enhanced-highlight'})
vim.pack.add({'https://github.com/cdelledonne/vim-cmake'})

-- git plugin
vim.pack.add({'https://github.com/tpope/vim-fugitive'})

vim.pack.add({'https://github.com/dkarter/bullets.vim'})

vim.pack.add({'https://github.com/shime/vim-livedown'})

vim.pack.add({'https://github.com/szw/vim-maximizer'})

-- trailer trash
vim.pack.add({'https://github.com/csexton/trailertrash.vim'})


vim.pack.add({'https://github.com/puremourning/vimspector'})

-- gdb plugin
vim.pack.add({'https://github.com/sakhnik/nvim-gdb'})

-- code completion
-- vim.pack.add({'https://github.com/nvim-lua/completion-nvim'})

-- vim.pack.add({'https://github.com/Valloric/YouCompleteMe'})
-- vim.pack.add({'https://github.com/neoclide/coc.nvim'})
-- vim.pack.add({'https://github.com/SirVer/ultisnips'})
-- vim.pack.add({'https://github.com/honza/vim-snippets'})
-- vim.pack.add({'https://github.com/ms-jpq/coq_nvim'})

