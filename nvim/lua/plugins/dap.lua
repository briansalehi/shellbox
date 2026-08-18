local map = require('plugins.util').fn_map

-- nvim-dap + codelldb

local dap = require('dap')
local dapui = require('dapui')

dap.adapters.codelldb = {
    type = 'server',
    port = '${port}',
    executable = {
        command = vim.fn.expand('~/.local/share/nvim/codelldb/extension/adapter/codelldb'),
        args = { '--port', '${port}' },
    },
}

dapui.setup()

vim.fn.sign_define('DapBreakpoint',         { text = "\u{F111}", texthl = 'DapBreakpoint',         linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointCondition',{ text = "\u{F444}", texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
vim.fn.sign_define('DapLogPoint',           { text = "\u{F27A}", texthl = 'DapLogPoint',            linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped',            { text = "\u{F04B}", texthl = 'DapStopped',             linehl = 'DapStoppedLine', numhl = '' })
vim.fn.sign_define('DapBreakpointRejected', { text = "\u{F05E}", texthl = 'DapBreakpointRejected',  linehl = '', numhl = '' })

vim.api.nvim_set_hl(0, 'DapBreakpoint',         { fg = '#e06c75' })
vim.api.nvim_set_hl(0, 'DapBreakpointCondition',{ fg = '#e5c07b' })
vim.api.nvim_set_hl(0, 'DapLogPoint',           { fg = '#61afef' })
vim.api.nvim_set_hl(0, 'DapStopped',            { fg = '#98c379' })
vim.api.nvim_set_hl(0, 'DapBreakpointRejected', { fg = '#888888' })
vim.api.nvim_set_hl(0, 'DapStoppedLine',        { bg = '#2a3b2a' })

dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
dap.listeners.before.event_exited['dapui_config']     = function() dapui.close() end

-- cmake-tools ran register_dap_function() before nvim-dap was loaded; re-run it now
require('cmake-tools').register_dap_function()

map('<leader>dc',   dap.continue,          'DAP: continue')
map('<leader>dn',   dap.step_over,         'DAP: step over')
map('<leader>di',   dap.step_into,         'DAP: step into')
map('<leader>do',   dap.step_out,          'DAP: step out')
map('<leader>db',   dap.toggle_breakpoint,  'DAP: toggle breakpoint')
map('<leader>dB',   function()
    dap.set_breakpoint(vim.fn.input('Condition: '))
end, 'DAP: conditional breakpoint')
map('<leader>dl',   function()
    dap.set_breakpoint(nil, nil, vim.fn.input('Log message: '))
end, 'DAP: log point')
map('<leader>dC',   dap.clear_breakpoints,  'DAP: clear all breakpoints')
map('<leader>dR',   dap.run_to_cursor,      'DAP: run to cursor')
map('<leader>dh',   require('dap.ui.widgets').hover, 'DAP: hover variable')
map('<leader>dx',   dap.terminate,          'DAP: terminate session')
map('<leader>dr',   dap.repl.open,          'DAP: open REPL')
map('<leader>du',   dapui.toggle,           'DAP: toggle UI')
