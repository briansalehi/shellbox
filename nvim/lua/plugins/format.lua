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
