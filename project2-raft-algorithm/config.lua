
local config = {}

config.servers_num = 4
config.servers = {
    {host = "raft-server1", port = 8888, id = 1},
    {host = "raft-server2", port = 8889, id = 2},
    {host = "raft-server3", port = 9000, id = 3},
    {host = "raft-server4", port = 9001, id = 4},
    {host = "raft-server5", port = 9002, id = 5},
}

config.interface_file = "./interface.lua"

config.verbose = true
config.rpc_verbose = false
config.heartbeatFrequency = 2
config.electionTimeoutMin = 15
config.electionTimeoutMax = 30
config.electionTimeLimitMin = 50
config.electionTimeLimitMax = 100

config.fileOutputEnabled = false
config.fileOutputPath = "./logs/raft.log"

function config.dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. config.dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

return config