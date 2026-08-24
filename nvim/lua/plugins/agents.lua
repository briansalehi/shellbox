-- Coding agents in a 33% bottom split. The engine is lua/agents.lua; this file is
-- the agent table and the keymaps.

local agents = require('agents')
local map = require('plugins.util').fn_map

agents.setup({
    window = { split_ratio = 0.33 },
    agents = {
        {
            name = 'claude',
            cmd = 'claude',
            variants = {
                continue        = { '--continue' },
                resume          = { '--resume' },
                verbose         = { '--verbose' },
                verboseContinue = { '--verbose', '--continue' },
                yolo            = { '--dangerously-skip-permissions' },
                yoloContinue    = { '--dangerously-skip-permissions', '--continue' },
            },
            -- Each ~/.config/models/<model>.md holds the prompt to append when running
            -- <model>. The flag must be --append-system-prompt-file: --append-system-prompt
            -- takes the prompt text itself, so handing it a path appends the path as a
            -- literal string. No shellescape: jobstart gets an argv list, not a shell.
            prompts = {
                dir = '~/.config/models',
                args = function(model, file)
                    return { '--model', model, '--append-system-prompt-file', file }
                end,
            },
        },
        {
            name = 'opencode',
            cmd = 'opencode',
            variants = {
                continue = { '--continue' },
                fork     = { '--continue', '--fork' },
            },
            -- no prompts block: opencode takes system prompts through AGENTS.md and
            -- agent definitions, not a flag, so \cs says so rather than passing
            -- claude's --append-system-prompt-file
        },
    },
})

local function toggle(name, variant)
    return function() agents.toggle(name, { variant = variant }) end
end

map('<leader>cc', toggle('claude'),                    'Agent: claude')
map('<leader>cC', toggle('claude', 'continue'),        'Agent: claude (continue)')
map('<leader>cv', toggle('claude', 'verbose'),         'Agent: claude (verbose)')
map('<leader>cV', toggle('claude', 'verboseContinue'), 'Agent: claude (verbose, continue)')
map('<leader>cy', toggle('claude', 'yolo'),            'Agent: claude (skip permissions)')
map('<leader>cY', toggle('claude', 'yoloContinue'),    'Agent: claude (skip permissions, continue)')
map('<leader>co', toggle('opencode'),                  'Agent: opencode')
map('<leader>cO', toggle('opencode', 'continue'),      'Agent: opencode (continue)')
map('<leader>ca', agents.pick,                         'Agent: pick or focus')
map('<leader>cs', function() agents.pick_prompt({}) end,
    'Agent: system prompt')
map('<leader>cS', function() agents.pick_prompt({ variant = 'continue' }) end,
    'Agent: system prompt (continue)')

-- <C-l> is not free: <C-h/j/k/l> leave the terminal window, so redraw lives on <M-r>
vim.keymap.set({ 'n', 't' }, '<M-r>', function()
    vim.cmd('mode')
end, { desc = 'Redraw terminal' })

-- send Ctrl-L (redraw) straight to the terminal process, staying in insert mode
vim.keymap.set('t', '<M-r>', function()
    vim.fn.chansend(vim.b.terminal_job_id, '\012')  -- \012 = ^L
end, { desc = 'Redraw terminal (send Ctrl-L)' })
