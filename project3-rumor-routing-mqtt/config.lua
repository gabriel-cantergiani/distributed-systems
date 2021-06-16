
local config = {}

config.nodes_num = 16
config.nodes = {
    {id = 1, position_x = 1, position_y = 1},
    {id = 2, position_x = 1, position_y = 2},
    {id = 3, position_x = 1, position_y = 3},
    {id = 4, position_x = 1, position_y = 4},
    {id = 5, position_x = 2, position_y = 1},
    {id = 6, position_x = 2, position_y = 2},
    {id = 7, position_x = 2, position_y = 3},
    {id = 8, position_x = 2, position_y = 4},
    {id = 9, position_x = 3, position_y = 1},
    {id = 10, position_x = 3, position_y = 2},
    {id = 11, position_x = 3, position_y = 3},
    {id = 12, position_x = 3, position_y = 4},
    {id = 13, position_x = 4, position_y = 1},
    {id = 14, position_x = 4, position_y = 2},
    {id = 15, position_x = 4, position_y = 3},
    {id = 16, position_x = 4, position_y = 4},
}

config.query_max_hops = 5
config.agent_max_hops = 5
config.sleep_between_hops = 3

config.fileOutputEnabled = true
config.fileOutputFolder = "./logs/"

config.mqtt_server_address = "localhost"
config.mqtt_server_port = 1883

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