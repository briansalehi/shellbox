-- State reporter for the observer and the mentor: `nvim --clean -l agent-state.lua
-- <event>`, run by claude's hooks and by opencode's plugin (agent-state.ts).
--
-- Tells the nvim that owns the terminal ($NVIM) what the agent is doing, which is how
-- lua/agent-observer.lua knows when it is safe to type into it. Prints nothing and
-- always exits 0, so it can never influence a permission decision or block the agent.

local server, name, root = os.getenv('NVIM'), os.getenv('AGENT_NAME'), os.getenv('AGENT_ROOT')
if not (server and name and root) then os.exit(0) end

local ok, input = pcall(vim.json.decode, io.read('*a') or '', { luanil = { object = true } })
local message = ok and type(input) == 'table' and input.last_assistant_message or nil

pcall(function()
    local chan = vim.fn.sockconnect('pipe', server, { rpc = true })
    vim.rpcrequest(chan, 'nvim_exec_lua', 'require("agent-observer").on_state(...)',
        { name, root, _G.arg[1], message or vim.NIL })
end)
os.exit(0)
