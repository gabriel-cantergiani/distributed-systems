
local config = {}

config.servers_num = 4
config.servers = {
    {host = "raft-server1", port = 8888, id = 1},
    {host = "raft-server2", port = 8889, id = 2},
    {host = "raft-server3", port = 9000, id = 3},
    {host = "raft-server4", port = 9001, id = 4},
}

config.interface_file = "./interface.lua"

config.verbose = true
config.rpc_verbose = false
config.heartbeatFrequency = 2
config.electionTimeoutMin = 20
config.electionTimeoutMax = 40
config.electionTimeLimitMin = 50
config.electionTimeLimitMax = 100

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