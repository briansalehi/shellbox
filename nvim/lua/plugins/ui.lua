-- lualine
require('lualine').setup({
    options = {
        theme = 'auto',
        -- powerline separators, rounded to match the float and split borders.
        -- 'left'/'right' name the half of the statusline, not the direction the
        -- glyph points: sections on the left trail a right-bulging cap, ones on
        -- the right lead with a left-bulging one. Needs the nerd font that the
        -- diagnostic signs and devicons already rely on.
        component_separators = { left = '\u{e0b1}', right = '\u{e0b3}' },
        section_separators   = { left = '\u{e0b4}', right = '\u{e0b6}' },
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        -- the global statusline can only ever name the active window, so list
        -- every window in the tab instead of the current filename: which files
        -- are open and which one has focus, without spending a winbar line per
        -- window. floats and the quickfix are excluded by the component.
        lualine_c = { { 'windows', symbols = { alternate_file = '' } } },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
    },
})

-- which-key: group labels
local wk = require('which-key')
wk.setup({ delay = 1000 })
wk.add({
    { '<leader>f', group = 'find' },
    { '<leader>e', group = 'oil' },
    { '<leader>m', group = 'cmake' },
    { '<leader>mp', group = 'preset' },
    { '<leader>mt', group = 'ctest' },
    { '<leader>g', group = 'git' },
    { '<leader>h', group = 'harpoon' },
    { '<leader>d', group = 'debug' },
    { '<leader>l', group = 'lsp' },
    { '<leader>u', group = 'format' },
    { '<leader>c', group = 'agents' },
    { '<leader>r', group = 'refactor' },
    { '<leader>x', group = 'trouble' },
    { '<leader>q', group = 'quickfix' },
})
