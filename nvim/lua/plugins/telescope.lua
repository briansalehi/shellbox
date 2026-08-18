-- telescope
require('telescope').setup({
  defaults = {
    file_ignore_patterns = { 'build/', '.git/', '.idea/' },
  },
  pickers = {
      find_files = {
          hidden = true,
      },
      buffers = {
          mappings = {
              n = { ['<C-d>'] = require('telescope.actions').delete_buffer },
              i = { ['<C-d>'] = require('telescope.actions').delete_buffer },
          },
      },
  },
  extensions = {
  }
})

local telescope_builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', telescope_builtin.find_files)
vim.keymap.set('n', '<leader>fg', telescope_builtin.live_grep)
vim.keymap.set('n', '<leader>fi', telescope_builtin.git_files)
vim.keymap.set('n', '<leader>fb', telescope_builtin.buffers)
vim.keymap.set('n', '<leader>fh', telescope_builtin.help_tags)
vim.keymap.set('n', '<leader>fk', telescope_builtin.keymaps,   { desc = 'Find keymaps' })
