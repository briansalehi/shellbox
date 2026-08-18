-- tree sitter
require('nvim-treesitter').install({"c", "cpp", "lua", "cmake", "python", "rust"})

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'c', 'cpp', 'lua', 'cmake', 'python', 'rust' },
    callback = function()
        pcall(vim.treesitter.start)
    end,
})
