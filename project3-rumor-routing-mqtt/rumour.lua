local config = require("config")
local mqtt = require("mqtt_library")

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

    -- Build neighbours
    rumour.neighbours = {}
    for i = (rumour.me.position_x - 1), (rumour.me.position_x + 1) do
        for j = (rumour.me.position_y - 1), (rumour.me.position_y + 1) do
            if i ~= rumour.me.position_x or j ~= rumour.me.position_y then
                if i >= 1 and i <= math.sqrt(config.nodes_num) and j >= 1 and j <= math.sqrt(config.nodes_num) then
                    table.insert(rumour.neighbours, "no-" .. i .. "-" .. j)
                end
            end
        end
    end
    
    -- MQTT set up
    rumour.me.topic = "no-" .. tostring(rumour.me.position_x) .. "-" .. tostring(rumour.me.position_y)
    mqtt_client = mqtt.client.create("localhost", 1883, mqttcb)
    mqtt_client:connect("Node " .. tostring(rumour.me.id))
    mqtt_client:subscribe({rumour.me.topic})
    
    rumour.log("Initialized")
end

function rumour.getNodePosition()
    return rumour.me.position_x, rumour.me.position_y
end


function rumour.HandleMqtt()
    mqtt_client:handler()
end

function mqttcb(topic, message)
    if topic == rumour.me.topic then
        rumour.log("Message received: " .. message)
    end
end

function rumour.triggerEvento1()
    rumour.log("Event1 triggered")
    rumour.sendMessageToNeighbours("event1")
end

function rumour.triggerEvento2()
    rumour.log("Event2 triggered")
    rumour.sendMessageToNeighbours("event2")
end

function rumour.triggerConsulta()
    rumour.log("Consulta triggered")
    rumour.sendMessageToNeighbours("consulta")
end

function rumour.Estado()
    rumour.log("Estado triggered")
end

function rumour.sendMessageToNeighbours(message)
    for _,neighbour in ipairs(rumour.neighbours) do
        mqtt_client:publish(neighbour, message)
        rumour.log("Sending " .. message .. " to node " .. neighbour)
    end
end


function rumour.log(message)
    msg = "[Node ".. tostring(rumour.me.id) .. "] " .. tostring(message)
    rumour.outputFile:write(msg .. "\n")
end

return rumour