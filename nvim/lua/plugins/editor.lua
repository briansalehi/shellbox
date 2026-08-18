-- mini.ai
require('mini.ai').setup()

-- auto-session
require('auto-session').setup({
    suppressed_dirs = { '~/', '/' },
})

-- undotree
vim.keymap.set('n', '<leader>U', '<cmd>UndotreeToggle<CR>', { desc = 'Undotree: toggle' })
