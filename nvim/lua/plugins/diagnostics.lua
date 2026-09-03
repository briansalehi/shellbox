local map = require('plugins.util').cmd_map

-- trouble.nvim
require('trouble').setup()

-- nvim-bqf - preview pane in the native quickfix window
-- cmake_executor is the quickfix executor, so \mb drops build errors straight
-- into this window; bqf previews each entry in place while moving through them.
-- The `zf` fzf filter is left at its default but needs the fzf binary, which is
-- not installed here.
require('bqf').setup({
    preview = { winblend = 0 },
})

map('<leader>xx', 'Trouble diagnostics toggle',              'Trouble: all diagnostics')
map('<leader>xd', 'Trouble diagnostics toggle filter.buf=0', 'Trouble: buffer diagnostics')
map('<leader>xq', 'Trouble qflist toggle',                   'Trouble: quickfix')
map('<leader>xl', 'Trouble loclist toggle',                  'Trouble: location list')
map('<leader>xr', 'Trouble lsp_references toggle',           'Trouble: LSP references')
map('<leader>xs', 'Trouble lsp_document_symbols toggle',     'Trouble: document symbols')

-- todo-comments - highlight TODO/FIXME/HACK and list them through trouble
require('todo-comments').setup()

map('<leader>xt', 'Trouble todo toggle', 'Trouble: todo comments')
vim.keymap.set('n', ']t', function() require('todo-comments').jump_next() end, { desc = 'Todo: next comment' })
vim.keymap.set('n', '[t', function() require('todo-comments').jump_prev() end, { desc = 'Todo: prev comment' })

-- quickfix
map('<leader>qo', 'copen',  'Quickfix: open')
map('<leader>qc', 'cclose', 'Quickfix: close')
map('<leader>qf', 'cfirst', 'Quickfix: first')
map('<leader>ql', 'clast',  'Quickfix: last')
map('<leader>qn', 'cnext',  'Quickfix: next')
map('<leader>qp', 'cprev',  'Quickfix: prev')
