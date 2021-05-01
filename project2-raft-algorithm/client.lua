luarpc = require("luarpc")
config = require("config")
socket = require("socket")

print("Initializing Raft Client...")

print("Connecting and initializing Raft Nodes...")
raft_nodes = {}

for _, server in ipairs(config.servers) do
    raft_node = luarpc.createProxy(server.host, server.port, config.interface_file, config.verbose)
    table.insert(raft_nodes, raft_node)
    -- socket.sleep(10)
    -- raft_node.StopNode()
end


