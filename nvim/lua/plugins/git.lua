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

-- gitsigns - live per-line change markers in the signcolumn
-- Complements diffview rather than duplicating it: diffview is a window you
-- open, gitsigns marks what you changed since HEAD while you type.
require('gitsigns').setup({
    on_attach = function(buf)
        local gs = require('gitsigns')
        local function m(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { buffer = buf, desc = desc })
        end

        -- ]h / [h walk your own uncommitted hunks
        m(']h', function() gs.nav_hunk('next') end, 'Git: next hunk')
        m('[h', function() gs.nav_hunk('prev') end, 'Git: prev hunk')

        m('<leader>gs', gs.stage_hunk,      'Git: stage hunk')
        m('<leader>gr', gs.reset_hunk,      'Git: reset hunk')
        m('<leader>gS', gs.stage_buffer,    'Git: stage buffer')
        m('<leader>gR', gs.reset_buffer,    'Git: reset buffer')
        m('<leader>gv', gs.preview_hunk,    'Git: preview hunk')
        m('<leader>gb', function() gs.blame_line({ full = true }) end, 'Git: blame line')
        m('<leader>gB', gs.toggle_current_line_blame, 'Git: blame virtual text toggle')
    end,
})
