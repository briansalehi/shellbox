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

-- plugins.cmake must precede plugins.dap: the latter re-runs cmake-tools' register_dap_function() once nvim-dap exists.
require('plugins.colorscheme')
require('plugins.ui')
require('plugins.telescope')
require('plugins.treesitter')
require('plugins.completion')
require('plugins.git')
require('plugins.cmake')
require('plugins.esp-idf')
require('plugins.clangd')
require('plugins.dap')
require('plugins.format')
require('plugins.navigation')
require('plugins.diagnostics')
require('plugins.editor')
require('plugins.claude-code')
