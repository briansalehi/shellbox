-- Activate the ESP-IDF environment for this nvim session so cmake-tools'
-- cmake/ninja/clangd subprocesses find the toolchain + python venv.
--   :IdfActivate            -> source export.sh into vim.env
--   :IdfActivate esp32s3    -> same, and set IDF_TARGET (picked up by <leader>mg)
vim.api.nvim_create_user_command('IdfActivate', function(o)
  local idf = vim.env.IDF_PATH or (vim.env.HOME .. '/.local/src/esp-idf')
  -- text = false keeps stdout as raw bytes so env -0's NUL delimiters survive
  -- (vim.fn.system would translate NUL -> newline and collapse the parse).
  local res = vim.system({ 'bash', '-c',
    'source "' .. idf .. '/export.sh" >/dev/null 2>&1 && env -0' },
    { text = false }):wait()
  if res.code ~= 0 then
    vim.notify('IdfActivate: export.sh failed (IDF_PATH=' .. idf .. ')', vim.log.levels.ERROR)
    return
  end
  for _, line in ipairs(vim.split(res.stdout or '', '\0', { plain = true })) do
    local k, v = line:match('^([^=]+)=(.*)$')
    if k then vim.env[k] = v end
  end
  local target = o.fargs[1]
  if target then vim.env.IDF_TARGET = target end
  vim.notify('ESP-IDF activated' .. (target and (' (target=' .. target .. ')') or ''))
end, { nargs = '?', desc = 'Activate ESP-IDF environment (optional target arg)' })

-- Set the serial port for the flash target (esptool reads ESPPORT; = idf.py -p),
-- mirroring how :IdfActivate controls IDF_TARGET.
--   :IdfSetPort /dev/ttyUSB0   -> set ESPPORT
--   :IdfSetPort                -> show current ESPPORT
vim.api.nvim_create_user_command('IdfSetPort', function(o)
  if o.args == '' then
    vim.notify('ESPPORT = ' .. (vim.env.ESPPORT or '(unset)'))
    return
  end
  vim.env.ESPPORT = o.args
  vim.notify('ESPPORT = ' .. o.args)
end, {
  nargs = '?',
  complete = function(arglead)
    local ports = {}
    for _, pat in ipairs({ '/dev/ttyUSB*', '/dev/ttyACM*' }) do
      vim.list_extend(ports, vim.fn.glob(pat, true, true))
    end
    return vim.tbl_filter(function(p) return p:find(arglead, 1, true) == 1 end, ports)
  end,
  desc = 'Set ESP-IDF serial port (ESPPORT)',
})

-- idf_monitor needs a real TTY. As a cmake target it runs through the quickfix
-- executor, which has none, so it exits at once and the panel auto-closes.
-- This runs it in a terminal split from the project's top-level directory,
-- against cmake-tools' build dir. Ctrl-] quits the monitor, and so does
-- <leader>ms, which stops it before falling back to cmake-tools' runner.
local monitor_job, monitor_buf = nil, nil
local function stop_monitor()
  if monitor_job and vim.fn.jobwait({ monitor_job }, 0)[1] == -1 then
    vim.fn.jobstop(monitor_job)
    -- wiping the buffer closes its split too
    if vim.api.nvim_buf_is_valid(monitor_buf) then
      vim.api.nvim_buf_delete(monitor_buf, { force = true })
    end
    monitor_job, monitor_buf = nil, nil
    return true
  end
  return false
end
vim.keymap.set('n', '<leader>mM', function()
  if vim.fn.executable('idf.py') == 0 then
    vim.notify('idf.py not found, run :IdfActivate first', vim.log.levels.WARN)
    return
  end
  local cmake = require('cmake-tools')
  local root = tostring(cmake.get_config().cwd or '')
  if root == '' then root = vim.loop.cwd() end
  local argv = { 'idf.py', '-B', tostring(cmake.get_build_directory()) }
  if vim.env.ESPPORT then vim.list_extend(argv, { '-p', vim.env.ESPPORT }) end
  table.insert(argv, 'monitor')
  vim.cmd('botright new')
  monitor_job = vim.fn.jobstart(argv, { term = true, cwd = root })
  monitor_buf = vim.api.nvim_get_current_buf()
  -- the split opens in terminal mode, where keys go to the monitor
  vim.keymap.set('t', '<leader>ms', stop_monitor, { buffer = true, desc = 'ESP-IDF: stop monitor' })
  vim.cmd('startinsert')
end, { desc = 'ESP-IDF: serial monitor' })

return { stop_monitor = stop_monitor }
