local map = require('plugins.util').cmd_map

-- diffview
require('diffview').setup()

map('<leader>gd', 'DiffviewOpen',          'Git: diff working tree')
map('<leader>gh', 'DiffviewFileHistory %', 'Git: file history')
map('<leader>gH', 'DiffviewFileHistory',   'Git: repo history')
map('<leader>gc', 'DiffviewClose',         'Git: close')

-- neogit
require('neogit').setup({
    integrations = { diffview = true, telescope = true },
})

map('<leader>gg', 'Neogit',        'Git: status (stage here)')
map('<leader>gC', 'Neogit commit', 'Git: commit')
map('<leader>gp', 'Neogit push',   'Git: push')
map('<leader>gP', 'Neogit pull',   'Git: pull')
