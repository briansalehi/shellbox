-- lualine
require('lualine').setup({
    options = {
        theme = 'auto',
        component_separators = { left = '|', right = '|' },
        section_separators   = { left = '', right = '' },
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
    },
})

-- dashboard
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'dashboard',
    callback = function()
        vim.api.nvim_create_autocmd('BufLeave', {
            buffer = 0,
            once = true,
            callback = function() vim.opt.signcolumn = 'yes' end,
        })
    end,
})

-- which-key: group labels
local wk = require('which-key')
wk.setup({ delay = 1000 })
wk.add({
    { '<leader>f', group = 'find' },
    { '<leader>e', group = 'oil' },
    { '<leader>m', group = 'cmake' },
    { '<leader>mp', group = 'preset' },
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
