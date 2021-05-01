raft = require("raft")
luarpc = require("luarpc")
config = require("config")

PORT = arg[1]
if PORT == nil then
    print("Error: missing argument(s).\nUsage: lua init_server.lua <SERVER_PORT>")
    os.exit()
end

-- Cria proxies com outros servidores
print("Creating proxies with other nodes...")
me = {}
peers = {}
for _, server in ipairs(config.servers) do
    if server.port == tonumber(PORT) then
        me = server
    else
        raft_node = luarpc.createProxy(server.host, server.port, config.interface_file, config.verbose)
        table.insert(peers, raft_node)
    end
end

print("Setting Up Raft Node...")
raft.SetUp(peers, me)


luarpc.createServant(raft, config.interface_file, PORT)
luarpc.waitIncoming(true)
