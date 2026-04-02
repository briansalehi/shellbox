-- color scheme
vim.pack.add({"https://github.com/folke/tokyonight.nvim"})

vim.cmd("colorscheme tokyonight")

-- telescope
vim.pack.add({
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/BurntSushi/ripgrep",
    "https://github.com/sharkdp/fd",
    "https://github.com/nvim-tree/nvim-web-devicons",
    "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
    "https://github.com/nvim-telescope/telescope.nvim"
})

local setup = require("telescope").setup({
  defaults = {
    file_ignore_patterns = { "build/", ".git/", ".idea/" },
  },
})

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

-- tree sitter
vim.pack.add({"https://github.com/nvim-treesitter/nvim-treesitter"})
