
local config = {}

config.nodes_num = 16
config.nodes = {
    {host = "localhost", id = 1, position_x = 1, position_y = 1},
    {host = "localhost", id = 2, position_x = 1, position_y = 2},
    {host = "localhost", id = 3, position_x = 1, position_y = 3},
    {host = "localhost", id = 4, position_x = 1, position_y = 4},
    {host = "localhost", id = 5, position_x = 2, position_y = 1},
    {host = "localhost", id = 6, position_x = 2, position_y = 2},
    {host = "localhost", id = 7, position_x = 2, position_y = 3},
    {host = "localhost", id = 8, position_x = 2, position_y = 4},
    {host = "localhost", id = 9, position_x = 3, position_y = 1},
    {host = "localhost", id = 10, position_x = 3, position_y = 2},
    {host = "localhost", id = 11, position_x = 3, position_y = 3},
    {host = "localhost", id = 12, position_x = 3, position_y = 4},
    {host = "localhost", id = 13, position_x = 4, position_y = 1},
    {host = "localhost", id = 14, position_x = 4, position_y = 2},
    {host = "localhost", id = 15, position_x = 4, position_y = 3},
    {host = "localhost", id = 16, position_x = 4, position_y = 4},
}

config.max_hops = 10

config.fileOutputEnabled = true
config.fileOutputFolder = "./logs/"

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