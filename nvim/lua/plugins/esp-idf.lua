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
