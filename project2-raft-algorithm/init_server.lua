raft = require("raft")
luarpc = require("luarpc")
config = require("config")

NODE_ID = arg[1]
if NODE_ID == nil then
    print("Error: missing node id argument.\nUsage: lua init_server.lua <NODE_ID>")
    os.exit()
end

-- Cria proxies com outros servidores
print("Creating proxies with other nodes...")
me = {}
peers = {}
for _, server in ipairs(config.servers) do
    if server.id == tonumber(NODE_ID) then
        me = server
    else
        raft_node = {}
        raft_node.host = server.host
        raft_node.port = server.port
        raft_node.id = server.id
        raft_node.proxy = luarpc.createProxy(server.host, server.port, config.interface_file, config.verbose)
        table.insert(peers, raft_node)
    end
end

print("Setting Up Raft Node...")
raft.SetUp(peers, me, config.verbose)

luarpc.createServant(raft, config.interface_file, me.port)
luarpc.waitIncoming(config.rpc_verbose)