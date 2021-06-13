local config = require("config")

local rumour = {}

function rumour.SetUp(node_id)

    -- Set Up logging
    rumour.filePath = config.fileOutputFolder .. "node" .. tostring(node_id) .. ".log"
    rumour.outputFile = io.open(rumour.filePath, "w")
    
    -- Get node position
    for _,node in ipairs(config.nodes) do
        if node.id == node_id then
            rumour.me = node
        end
    end
    
    rumour.log("initialized")
end

    -- 1-1 1-2 1-3 1-4
    -- 2-1 2-2 2-3 2-4
    -- 3-1 3-2 3-3 3-4
    -- 4-1 4-2 4-3 4-4

function rumour.triggerEvento1()
    rumour.log("Event1 triggered")
end

function rumour.triggerEvento2()
    rumour.log("Event2 triggered")
end

function rumour.Consulta()
    rumour.log("Consulta triggered")
end

function rumour.Estado()
    rumour.log("Estado triggered")
end


function rumour.log(message)
    msg = "[Node ".. tostring(rumour.me.id) .. "]" .. tostring(message)
    rumour.outputFile:write(msg .. "\n")
end

return rumour