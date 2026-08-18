local map = require('plugins.util').cmd_map

-- trouble.nvim
require('trouble').setup()

map('<leader>xx', 'Trouble diagnostics toggle',              'Trouble: all diagnostics')
map('<leader>xd', 'Trouble diagnostics toggle filter.buf=0', 'Trouble: buffer diagnostics')
map('<leader>xq', 'Trouble qflist toggle',                   'Trouble: quickfix')
map('<leader>xl', 'Trouble loclist toggle',                  'Trouble: location list')
map('<leader>xr', 'Trouble lsp_references toggle',           'Trouble: LSP references')
map('<leader>xs', 'Trouble lsp_document_symbols toggle',     'Trouble: document symbols')

-- quickfix
map('<leader>qo', 'copen',  'Quickfix: open')
map('<leader>qc', 'cclose', 'Quickfix: close')
map('<leader>qf', 'cfirst', 'Quickfix: first')
map('<leader>ql', 'clast',  'Quickfix: last')
map('<leader>qn', 'cnext',  'Quickfix: next')
map('<leader>qp', 'cprev',  'Quickfix: prev')
