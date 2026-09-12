local stl_escape = require('lualine.utils.utils').stl_escape

-- cwd-relative path of an ordinary file buffer; nil for terminals, quickfix,
-- help and unnamed buffers, which the windows component names itself.
local function window_path(bufnr)
    if vim.bo[bufnr].buftype ~= '' then
        return nil
    end
    local file = vim.api.nvim_buf_get_name(bufnr)
    if file == '' then
        return nil
    end
    return vim.fn.fnamemodify(file, ':.')
end

-- do the full paths of every window in the tab still fit? Budgeted against the
-- same two thirds of the screen the component keeps for itself before it starts
-- dropping windows, plus the icon, padding and separator each one costs.
local function window_paths_fit()
    local width = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local path = window_path(vim.api.nvim_win_get_buf(win))
        if path then
            width = width + vim.fn.strchars(path) + 5
        end
    end
    return width <= math.floor(2 * vim.o.columns / 3)
end

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
        -- name each window by its path relative to the cwd, so two files with
        -- the same basename stay apart. Full paths while they fit; past that
        -- every window falls back to the component's own shortened form
        -- (lua/plugins/ui.lua -> l/p/ui.lua), which is what
        -- show_filename_only = false renders.
        lualine_c = {
            {
                'windows',
                show_filename_only = false,
                symbols = { alternate_file = '' },
                fmt = function(name, window)
                    if not window_paths_fit() then
                        return name
                    end
                    local path = window_path(window.bufnr)
                    return path and stl_escape(path) or name
                end,
            },
        },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
    },
    -- take over the tabline (showtabline = 2 keeps it drawn) from nvim's
    -- default, which always abbreviates directories (l/p/ui.lua) and turns
    -- agent://claude/shellbox into a//c/shellbox. Name each tab by its current
    -- buffer's full cwd-relative path; tab_max_length = 0 disables lualine's
    -- own abbreviation. lualine names every terminal after $SHELL, so agent
    -- terminals fall back to their agent:// buffer name instead.
    tabline = {
        lualine_a = {
            {
                'tabs',
                mode = 1,
                path = 1,
                tab_max_length = 0,
                fmt = function(name, tab)
                    if tab.buftype == 'terminal' and not vim.startswith(tab.file, 'term://') then
                        return tab.file
                    end
                    return name
                end,
            },
        },
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
    { '<leader>v', group = 'valgrind' },
    { '<leader>vm', group = 'memcheck' },
})
