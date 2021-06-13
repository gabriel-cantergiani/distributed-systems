
local config = {}

config.nodes_num = 1
config.nodes = {
    {host = "localhost", id = 1, position_x = 1, position_y = 1},
}

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