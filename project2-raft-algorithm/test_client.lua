luarpc = require("luarpc")
config = require("config")
socket = require("socket")

if #arg < 3 then
    print("Error: missing argument(s).\nUsage: lua test_client.lua <SERVER_HOSTNAME> <SERVER_PORT> <RPC_METHOD>")
    os.exit()
end

hostname = arg[1]
port = tonumber(arg[2])
rpc_method = arg[3]

found_host = false
for _, server in ipairs(config.servers) do
    if server.host == hostname and tonumber(server.port) == port then
        found_host = true
        break
    end
end

if not found_host then
    print("Server Hostname or Port not found in Config File.")
    os.exit()
end

raft_node = luarpc.createProxy(hostname, port, config.interface_file, config.verbose)

if rpc_method == "InitializeNode" then
    raft_node.InitializeNode()
elseif rpc_method == "StopNode" then
    seconds = tonumber(arg[4])
    raft_node.StopNode(seconds)
end


