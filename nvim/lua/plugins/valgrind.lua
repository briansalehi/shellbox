local map = require('plugins.util').fn_map
local valgrind = require('valgrind')

valgrind.setup({
    num_callers = 50,
    leak_kinds = 'definite,possible',
    track_origins = false,
    suppressions_file = 'valgrind.supp',
    split_ratio = 0.33,
})

-- \v is a namespace per valgrind tool, so the tools that are not wired up yet
-- have a home to go to: \vm memcheck, \vh helgrind, \vd drd, \vc callgrind,
-- \vg cachegrind, \va massif, \vt dhat. Only memcheck exists today. \vs stops
-- whichever tool is running, \vp / \vr read whichever one ran last and \vx closes
-- what they opened, so those four stay at the top level.

local function memcheck_args(leak_kinds)
    local args = {
        '--leak-check=full',
        '--show-leak-kinds=' .. (leak_kinds or valgrind.opts.leak_kinds),
    }
    if valgrind.opts.track_origins then
        args[#args + 1] = '--track-origins=yes'
    end
    return args
end

map('<leader>vmm', function()
    valgrind.run('memcheck', memcheck_args())
end, 'Memcheck: run launch target')

map('<leader>vmb', function()
    valgrind.build_and_run('memcheck', memcheck_args())
end, 'Memcheck: build then run')

map('<leader>vml', function()
    -- reachable and indirect blocks as well, for the full picture of a heap
    valgrind.run('memcheck', memcheck_args('all'))
end, 'Memcheck: run with all leak kinds')

map('<leader>vmo', function()
    -- --track-origins roughly halves memcheck's speed and adds at least 100MB,
    -- so it is a deliberate toggle rather than a default
    valgrind.opts.track_origins = not valgrind.opts.track_origins
    vim.notify('Memcheck: track-origins ' .. (valgrind.opts.track_origins and 'on' or 'off'))
end, 'Memcheck: toggle track-origins')

map('<leader>vmf', valgrind.filter,           'Memcheck: filter quickfix by kind')
map('<leader>vmt', valgrind.show_stack,       'Memcheck: full stack of this error')
map('<leader>vms', valgrind.suppress_current, 'Memcheck: suppress this error')
map('<leader>vmS', valgrind.suppress_all,     'Memcheck: suppress every error')

map('<leader>vs', valgrind.stop,        'Valgrind: stop the running tool')
map('<leader>vp', valgrind.show_output, 'Valgrind: program output of last run')
map('<leader>vr', valgrind.show_report, 'Valgrind: raw report of last run')
map('<leader>vx', valgrind.close,       'Valgrind: close its windows')

-- a run outliving nvim would keep the target process alive with it
vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
        if valgrind.is_running() then valgrind.stop() end
    end,
})

-- nvim ships syntax/valgrind.vim but no ftdetect for it, so a saved log opens
-- unhighlighted; these are the names such logs usually get.
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
    pattern = { '*.valgrind', 'valgrind*.log' },
    callback = function() vim.bo.filetype = 'valgrind' end,
})
