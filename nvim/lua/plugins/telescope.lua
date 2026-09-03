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
      -- routes every vim.ui.select through telescope, so the long lists win a
      -- fuzzy filter: the cursor and opencode model pickers, and cmake-tools'
      -- generator, kit and preset prompts
      ['ui-select'] = {
          require('telescope.themes').get_dropdown({}),
      },
  }
})

-- fzf-native is a C library and vim.pack has no build step, so the .so is built
-- here on install and after every update (:h vim.pack-events). Nothing rebuilds it
-- retroactively: a plugin installed before this hook existed needs one `make` in
-- its directory.
vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('TelescopeFzfBuild', { clear = true }),
    callback = function(ev)
        local d = ev.data
        if d.spec.name ~= 'telescope-fzf-native.nvim' then return end
        if d.kind ~= 'install' and d.kind ~= 'update' then return end
        vim.system({ 'make' }, { cwd = d.path }, function(res)
            vim.schedule(function()
                if res.code == 0 then
                    vim.notify('telescope: rebuilt the fzf sorter', vim.log.levels.INFO)
                else
                    vim.notify('telescope: fzf sorter failed to build\n' .. (res.stderr or ''),
                        vim.log.levels.ERROR)
                end
            end)
        end)
    end,
})

-- load_extension is what actually swaps in the native sorter; without this call the
-- plugin is installed and unused, and telescope quietly keeps its own sorter
local ok = pcall(require('telescope').load_extension, 'fzf')
if not ok then
    -- the PackChanged hook only fires on a future install or update, so a checkout
    -- that predates it needs one manual build; name the command rather than the fault
    local got = vim.pack.get({ 'telescope-fzf-native.nvim' })[1]
    vim.notify(('telescope: the fzf sorter is not built, run\n    make -C %s')
        :format(got and got.path or '<telescope-fzf-native.nvim>'), vim.log.levels.WARN)
end

require('telescope').load_extension('ui-select')

local telescope_builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', telescope_builtin.find_files)
vim.keymap.set('n', '<leader>fg', telescope_builtin.live_grep)
vim.keymap.set('n', '<leader>fi', telescope_builtin.git_files)
vim.keymap.set('n', '<leader>fb', telescope_builtin.buffers)
vim.keymap.set('n', '<leader>fh', telescope_builtin.help_tags)
vim.keymap.set('n', '<leader>fk', telescope_builtin.keymaps,   { desc = 'Find keymaps' })
