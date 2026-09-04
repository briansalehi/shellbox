-- ayu
require('ayu').setup({
    mirage = false, -- Set to `true` to use `mirage` variant instead of `dark` for dark background.
    terminal = true, -- Set to `false` to let terminal manage its own colors.
    overrides = {
        LineNr = { fg = '#7A3030' },
        -- ayu draws split separators in black on a near-black background, so
        -- splits had no visible edge; match FloatBorder's grey instead
        WinSeparator = { fg = '#636A72' },
    }, -- A dictionary of group names, each associated with a dictionary of parameters (`bg`, `fg`, `sp` and `style`) and colors in hex.
})

vim.cmd('colorscheme ayu')
