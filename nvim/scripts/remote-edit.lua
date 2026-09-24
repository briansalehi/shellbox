-- $VISUAL for agent terminals: `nvim --clean -l remote-edit.lua <file>`.
--
-- Opens <file> in the nvim that owns the terminal ($NVIM) and blocks until its
-- buffer is gone, because the agent reads the file back, then deletes it, as soon
-- as the editor exits. nvim has no --remote-wait, hence the poll.

local file = vim.fn.fnamemodify(_G.arg[1], ':p')
local chan = vim.fn.sockconnect('pipe', assert(os.getenv('NVIM'), '$NVIM is not set'),
    { rpc = true })

vim.rpcrequest(chan, 'nvim_exec_lua', 'require("agents").edit(...)', { file })
while vim.rpcrequest(chan, 'nvim_call_function', 'bufexists', { file }) == 1 do
    vim.uv.sleep(200)
end
