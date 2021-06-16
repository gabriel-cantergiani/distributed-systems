local config = require("config")
local mqtt = require("mqtt_library")
local json = require("json")

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
        event1 = {agent_path=nil, agent_hops=0, query_path=nil, query_hops=0},
        event2 = {agent_path=nil, agent_hops=0, query_path=nil, query_hops=0}
    }
    
    -- MQTT set up
    rumour.me.topic = "no-" .. tostring(rumour.me.position_x) .. "-" .. tostring(rumour.me.position_y)
    mqtt_client = mqtt.client.create(config.mqtt_server_address, config.mqtt_server_port, mqttcb)
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
        decoded_message = json.decode(message)
        rumour.log("Received " .. decoded_message.event .. "-" .. decoded_message.type .. " from node " .. decoded_message.sender)
        rumour.processReceivedMessage(decoded_message)
    end
end

function rumour.processReceivedMessage(message)
    if message.type == "agent" then
        -- Update events table
        if rumour.events[message.event].agent_path == nil or rumour.events[message.event].agent_hops >= (message.hops + 1) then
                rumour.events[message.event].agent_path = message.sender
                rumour.events[message.event].agent_hops = message.hops + 1
        end

        -- Update message
        message.hops = rumour.events[message.event].agent_hops
        message.sender = rumour.me.topic
        
        -- Forward to neighbour if max_hops was not reached
        if message.hops < config.agent_max_hops then
            rumour.log("Fowarding event agent")
            sleep(config.sleep_between_hops)
            rumour.sendMessageToRandomNeighbour(message)
        else
            rumour.log("Event agent reached hops limit")
        end
    elseif message.type == "query" then
        -- Update message
        incoming_message_sender = message.sender
        message.sender = rumour.me.topic
        message.hops = message.hops + 1

        sleep(config.sleep_between_hops)
        -- Check events table
        if rumour.events[message.event].agent_path ~= nil then
            -- Forward query to node_path
            rumour.log("Forwarding event query")
            rumour.sendMessageToNeighbour(message, rumour.events[message.event].agent_path)
        elseif message.hops < config.query_max_hops then
            -- Forward query to random node
            rumour.log("Randomly Forwarding event query")
            rumour.sendMessageToRandomNeighbour(message)
        else
            rumour.log("Event query reached hops limit")
        end

        -- Update events table
        rumour.events[message.event].query_path = incoming_message_sender
        rumour.events[message.event].query_hops = message.hops

    end

end

function rumour.triggerEvento1()
    rumour.log("Event1 triggered")
    message = {
        type = "agent",
        event = "event1",
        sender = rumour.me.topic,
        hops = 0
    }
    rumour.sendMessageToRandomNeighbour(message)
end

function rumour.triggerEvento2()
    rumour.log("Event2 triggered")
    message = {
        type = "agent",
        event = "event2",
        sender = rumour.me.topic,
        hops = 0
    }
    rumour.sendMessageToRandomNeighbour(message)
end

function rumour.triggerConsulta1()
    rumour.log("Consulta1 triggered")
    message = {
        type = "query",
        event = "event1",
        sender = rumour.me.topic,
        hops = 0
    }
    rumour.sendMessageToRandomNeighbour(message)
end

function rumour.triggerConsulta2()
    rumour.log("Consulta2 triggered")
    message = {
        type = "query",
        event = "event2",
        sender = rumour.me.topic,
        hops = 0
    }
    rumour.sendMessageToRandomNeighbour(message)
end

function rumour.Estado()
    rumour.log("Estado triggered")
end

function rumour.sendMessageToRandomNeighbour(message)
    -- Get random neighbour
    random_index = math.random(1, #rumour.neighbours)
    random_neighbour = rumour.neighbours[random_index]

    -- Decode message table into string and publish it to mqtt
    mqtt_client:publish(random_neighbour, json.encode(message))
    rumour.log("Sending " .. message.event .. "-" .. message.type .. " to node " .. random_neighbour)
end

function rumour.sendMessageToNeighbour(message, neighbour)
    -- Decode message table into string and publish it to mqtt
    mqtt_client:publish(neighbour, json.encode(message))
    rumour.log("Sending " .. message.event .. "-" .. message.type .. " to node " .. neighbour)
end


function rumour.log(message)
    msg = "[" .. (os.time() - rumour.initial_timestamp) .. "s][Node ".. tostring(rumour.me.id) .. "] " .. tostring(message)
    rumour.outputFile:write(msg .. "\n")
    rumour.print(message)
end


function sleep(time)
    local duration = os.time() + time
    while os.time() < duration do end
end

return rumour