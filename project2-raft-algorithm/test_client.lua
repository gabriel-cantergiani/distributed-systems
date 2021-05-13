luarpc = require("luarpc")
config = require("config")
socket = require("socket")

if #arg < 2 then
    print("Error: missing argument(s).\nUsage: lua test_client.lua <NODE_ID> <RPC_METHOD>")
    os.exit()
end

-- hostname = arg[1]
-- port = tonumber(arg[2])
node_id = arg[1]
rpc_method = arg[2]

node = {}
for _, server in ipairs(config.servers) do
    if server.id == tonumber(node_id) then
        node = server
        break
    end
end

if not node then
    print("Node ID not found in Config File.")
    os.exit()
end

raft_node = luarpc.createProxy(node.host, node.port, config.interface_file, config.verbose)

if rpc_method == "InitializeNode" then
    raft_node.InitializeNode()
elseif rpc_method == "StopNode" then
    raft_node.StopNode()
elseif rpc_method == "ResumeNode" then
    raft_node.ResumeNode()
elseif rpc_method == "PartitionNode" then
    raft_node.PartitionNode()
end


