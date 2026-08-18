-- Keymap helpers shared by the plugin modules.

local M = {}

-- normal-mode map to an ex command
function M.cmd_map(lhs, cmd, desc)
    vim.keymap.set('n', lhs, '<cmd>' .. cmd .. '<CR>', { desc = desc })
end

-- normal-mode map to a lua function
function M.fn_map(lhs, fn, desc)
    vim.keymap.set('n', lhs, fn, { desc = desc })
end

return M
