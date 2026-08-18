-- oil.nvim - filesystem manager
require('oil').setup({
    view_options = { show_hidden = true },
})
vim.keymap.set('n', '<leader>e', '<cmd>Oil<CR>', { desc = 'Explorer: open directory' })
vim.keymap.set('n', '-',         '<cmd>Oil<CR>', { desc = 'Explorer: open directory' })

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'oil',
    callback = function(args)
        vim.keymap.set('n', '<leader>ea', function() require('oil').save() end, { buffer = args.buf, desc = 'Explorer: apply changes' })
    end,
})

-- harpoon
local harpoon = require('harpoon')
harpoon:setup()

vim.keymap.set('n', '<leader>a',  function() harpoon:list():add() end,                         { desc = 'Harpoon: add file' })
vim.keymap.set('n', '<leader>h',  function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon: menu' })
vim.keymap.set('n', '<leader>1',  function() harpoon:list():select(1) end,                     { desc = 'Harpoon: file 1' })
vim.keymap.set('n', '<leader>2',  function() harpoon:list():select(2) end,                     { desc = 'Harpoon: file 2' })
vim.keymap.set('n', '<leader>3',  function() harpoon:list():select(3) end,                     { desc = 'Harpoon: file 3' })
vim.keymap.set('n', '<leader>4',  function() harpoon:list():select(4) end,                     { desc = 'Harpoon: file 4' })

-- flash.nvim
local flash = require('flash')
flash.setup({ modes = { char = { enabled = false } } })

vim.keymap.set({ 'n', 'x', 'o' }, '<leader>s', flash.jump,              { desc = 'Flash: jump' })
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>S', flash.treesitter,        { desc = 'Flash: treesitter' })
vim.keymap.set('o',               'r',         flash.remote,            { desc = 'Flash: remote' })
vim.keymap.set({ 'o', 'x' },      'R',         flash.treesitter_search, { desc = 'Flash: treesitter search' })
vim.keymap.set('c',               '<C-s>',     flash.toggle,            { desc = 'Flash: toggle in search' })
