-- claude code
require("claude-code").setup({
  -- Terminal window settings
  window = {
    split_ratio = 0.3,      -- Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
    position = "botright",  -- Position of the window: "botright", "topleft", "vertical", "float", etc.
    enter_insert = true,    -- Whether to enter insert mode when opening Claude Code
    start_in_normal_mode = true, -- Disable auto-startinsert on WinEnter so scrollback position survives window switches
    hide_numbers = true,    -- Hide line numbers in the terminal window
    hide_signcolumn = true, -- Hide the sign column in the terminal window

    -- Floating window configuration (only applies when position = "float")
    float = {
      width = "80%",        -- Width: number of columns or percentage string
      height = "80%",       -- Height: number of rows or percentage string
      row = "center",       -- Row position: number, "center", or percentage string
      col = "center",       -- Column position: number, "center", or percentage string
      relative = "editor",  -- Relative to: "editor" or "cursor"
      border = "rounded",   -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
    },
  },
  -- File refresh settings
  refresh = {
    enable = true,           -- Enable file change detection
    updatetime = 100,        -- updatetime when Claude Code is active (milliseconds)
    timer_interval = 1000,   -- How often to check for file changes (milliseconds)
    show_notifications = true, -- Show notification when files are reloaded
  },
  -- Git project settings
  git = {
    use_git_root = true,     -- Set CWD to git root when opening Claude Code (if in git project)
  },
  -- Shell-specific settings
  shell = {
    separator = '&&',        -- Command separator used in shell commands
    pushd_cmd = 'pushd',     -- Command to push directory onto stack (e.g., 'pushd' for bash/zsh, 'enter' for nushell)
    popd_cmd = 'popd',       -- Command to pop directory from stack (e.g., 'popd' for bash/zsh, 'exit' for nushell)
  },
  -- Command settings
  command = "claude", -- Command used to launch Claude Code
  -- Command variants
  command_variants = {
    -- Conversation management
    continue = "--continue", -- Resume the most recent conversation
    resume = "--resume",     -- Display an interactive conversation picker

    -- Output options
    verbose = "--verbose",   -- Enable verbose logging with full turn-by-turn output
    verboseContinue = "--verbose --continue", -- Resume last conversation with verbose logging

    -- Permissions
    yolo = "--dangerously-skip-permissions", -- Run every tool without confirmation
    yoloContinue = "--dangerously-skip-permissions --continue", -- Resume last conversation, skipping confirmation
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = "<leader>cc",       -- Normal mode keymap for toggling Claude Code, false to disable
      terminal = "<leader>cc",     -- Terminal mode keymap for toggling Claude Code, false to disable
      variants = {
        continue = "<leader>cC", -- Normal mode keymap for Claude Code with continue flag
        verbose = "<leader>cv",  -- Normal mode keymap for Claude Code with verbose flag
        verboseContinue = "<leader>cV", -- Normal mode keymap for Claude Code with verbose flag, continued
        yolo = "<leader>cy",     -- Normal mode keymap for Claude Code with skipped permissions
        yoloContinue = "<leader>cY", -- Normal mode keymap for Claude Code with skipped permissions, continued
      },
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = false,         -- Enable scrolling keymaps (<C-f/b>) for page up/down
  }
})
-- the plugin's start_in_normal_mode keeps scrollback on window switches, so the
-- toggle keymaps ask for insert mode themselves
local function enter_insert()
  vim.schedule(function()
    if vim.bo.buftype == 'terminal' then
      vim.cmd('startinsert')
    end
  end)
end

local function claude_toggle(cmd)
  return function()
    vim.cmd(cmd)
    enter_insert()
  end
end
vim.keymap.set('n', '<leader>cc', claude_toggle('ClaudeCode'),         { desc = 'Toggle Claude Code' })
vim.keymap.set('n', '<leader>cC', claude_toggle('ClaudeCodeContinue'), { desc = 'Toggle Claude Code (continue)' })
vim.keymap.set('n', '<leader>cv', claude_toggle('ClaudeCodeVerbose'),  { desc = 'Toggle Claude Code (verbose)' })
vim.keymap.set('n', '<leader>cV', claude_toggle('ClaudeCodeVerboseContinue'), { desc = 'Toggle Claude Code (verbose, continue)' })
vim.keymap.set('n', '<leader>cy', claude_toggle('ClaudeCodeYolo'),     { desc = 'Toggle Claude Code (skip permissions)' })
vim.keymap.set('n', '<leader>cY', claude_toggle('ClaudeCodeYoloContinue'), { desc = 'Toggle Claude Code (skip permissions, continue)' })

-- Per-model system prompts: each ~/.config/models/<model>.md holds the prompt to
-- append when running <model>, so <leader>cs picks one and launches
--   claude --model <model> --append-system-prompt-file <file>
-- The flag must be --append-system-prompt-file; --append-system-prompt takes the
-- prompt text itself, so handing it a path appends the path as a literal string.
local models_dir = vim.fn.expand('~/.config/models')

local function claude_with_model(extra_args)
  return function()
    local files = vim.fn.glob(models_dir .. '/*.md', true, true)
    if #files == 0 then
      vim.notify('Claude: no model prompts in ' .. models_dir, vim.log.levels.WARN)
      return
    end

    local models = vim.tbl_map(function(f) return vim.fn.fnamemodify(f, ':t:r') end, files)

    local function launch(model, file)
      local claude = require('claude-code')
      local base = claude.config.command

      -- config.command is only read when a new terminal is spawned, so swap it
      -- for the duration of the toggle the way command_variants does internally
      local argv = { base, '--model', model,
                     '--append-system-prompt-file', vim.fn.shellescape(file) }
      if extra_args then table.insert(argv, extra_args) end
      claude.config.command = table.concat(argv, ' ')

      local ok, err = pcall(claude.toggle)
      claude.config.command = base
      if not ok then
        vim.notify('Claude: ' .. tostring(err), vim.log.levels.ERROR)
        return
      end
      enter_insert()
    end

    -- a single prompt file leaves nothing to choose, so skip the picker
    if #models == 1 then
      launch(models[1], files[1])
      return
    end

    vim.ui.select(models, { prompt = 'Claude model:' }, function(model, index)
      if not model then return end
      launch(model, files[index])
    end)
  end
end

vim.keymap.set('n', '<leader>cs', claude_with_model(nil),         { desc = 'Toggle Claude Code (model system prompt)' })
vim.keymap.set('n', '<leader>cS', claude_with_model('--continue'), { desc = 'Toggle Claude Code (model system prompt, continue)' })
vim.keymap.set({ 'n', 't' }, '<M-r>', function()
  vim.cmd('mode')
end, { desc = 'Redraw terminal' })

-- send Ctrl-L (redraw) straight to the terminal process, staying in insert mode
vim.keymap.set('t', '<M-r>', function()
    vim.fn.chansend(vim.b.terminal_job_id, '\012')  -- \012 = ^L
end, { desc = 'Redraw terminal (send Ctrl-L)' })
