local config = require("config")
local mqtt = require("mqtt_library")

local rumour = {}

function rumour.SetUp(node_id, printLog)

    -- Set Up logging
    rumour.filePath = config.fileOutputFolder .. "node" .. tostring(node_id) .. ".log"
    rumour.outputFile = io.open(rumour.filePath, "w")
    rumour.print = printLog
    
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

    -- Events
    math.randomseed(node_id * os.time())
    rumour.events = {
        -- event1 = {node_id(path)=x, hops=y}
        -- event2 = {node_id(path)=x, hops=y}
    }
    
    -- MQTT set up
    rumour.me.topic = "no-" .. tostring(rumour.me.position_x) .. "-" .. tostring(rumour.me.position_y)
    mqtt_client = mqtt.client.create("localhost", 1883, mqttcb)
    mqtt_client:connect("Node " .. tostring(rumour.me.id))
    mqtt_client:subscribe({rumour.me.topic})
    
    rumour.initial_timestamp = os.time()
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
    rumour.sendMessageToNeighbour("event1 from Node " .. rumour.me.topic)
end

function rumour.triggerEvento2()
    rumour.log("Event2 triggered")
    rumour.sendMessageToNeighbour("event2 from Node " .. rumour.me.topic)
end

function rumour.triggerConsulta1()
    rumour.log("Consulta1 triggered")
    rumour.sendMessageToNeighbour("consulta1 from Node " .. rumour.me.topic)
end

function rumour.triggerConsulta2()
    rumour.log("Consulta2 triggered")
    rumour.sendMessageToNeighbour("consulta2 from Node " .. rumour.me.topic)
end

function rumour.Estado()
    rumour.log("Estado triggered")
end

function rumour.sendMessageToNeighbour(message)
    random_index = math.random(1, #rumour.neighbours)
    random_neighbour = rumour.neighbours[random_index]
    mqtt_client:publish(random_neighbour, message)
    rumour.log("Sending " .. message .. " to node " .. random_neighbour)
end


function rumour.log(message)
    msg = "[" .. (os.time() - rumour.initial_timestamp) .. "s][Node ".. tostring(rumour.me.id) .. "] " .. tostring(message)
    rumour.outputFile:write(msg .. "\n")
    rumour.print(message)
end

return rumour