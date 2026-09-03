-- mini.ai
require('mini.ai').setup()

-- auto-session
require('auto-session').setup({
    suppressed_dirs = { '~/', '/' },
})

-- undotree
vim.keymap.set('n', '<leader>U', '<cmd>UndotreeToggle<CR>', { desc = 'Undotree: toggle' })

-- vim-illuminate - highlight other occurrences of the symbol under the cursor
-- Providers are tried in order and the treesitter one is deliberately absent:
-- it needs `nvim-treesitter.locals`, which only exists on nvim-treesitter's
-- master branch, and this config runs the main-branch rewrite. It fails soft
-- (returns nil, falls through), so the omission only avoids a dead lookup.
-- clangd covers C/C++ via lsp; regex covers lua, cmake, python and rust.
-- Default keymaps <A-n> / <A-p> jump between occurrences, <A-i> selects one.
require('illuminate').configure({
    providers = { 'lsp', 'regex' },
    filetypes_denylist = {
        'oil', 'harpoon', 'trouble', 'undotree',
        'NeogitStatus', 'DiffviewFiles', 'toggleterm', 'dap-repl',
    },
})
