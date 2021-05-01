
local config = {}

config.servers_num = 3
config.servers = {
    {host = "raft-server1", port = 8888},
    -- {host = "raft-server2", port = 8889},
    -- {host = "raft-server3", port = 9000},
}

config.interface_file = "./interface.lua"

config.verbose = true

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