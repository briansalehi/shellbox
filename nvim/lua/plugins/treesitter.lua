-- tree sitter
require('nvim-treesitter').install({"c", "cpp", "lua", "cmake", "python", "rust"})

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'c', 'cpp', 'lua', 'cmake', 'python', 'rust' },
    callback = function()
        pcall(vim.treesitter.start)
    end,
})

-- nvim-treesitter-context - pin the enclosing scope to the top of the window
-- Standalone: it reads vim.treesitter directly and never requires a
-- nvim-treesitter module, so the master/main split does not affect it.
-- max_lines defaults to 0 (no limit), which eats the window in deeply nested
-- C++; 3 keeps the cost bounded. trim_scope 'outer' drops the class line first
-- and keeps the function and loop, which is the part you lose while scrolling.
require('treesitter-context').setup({
    max_lines = 3,
    min_window_height = 20,   -- no context in short splits
    trim_scope = 'outer',
    separator = '-',
})

-- [c jumps to the context line. Diff mode binds [c to the previous hunk, so
-- fall through to the builtin there rather than shadowing it for diffview.
vim.keymap.set('n', '[c', function()
    if vim.wo.diff then return '[c' end
    require('treesitter-context').go_to_context(vim.v.count1)
    return ''
end, { expr = true, silent = true, desc = 'Context: jump to enclosing scope' })
