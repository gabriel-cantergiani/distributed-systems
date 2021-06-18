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
        event1 = {event_direction=nil, event_distance=nil, query_direction=nil, query_distance=nil, is_observer = false},
        event2 = {event_direction=nil, event_distance=nil, query_direction=nil, query_distance=nil, is_observer = false}
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

    -- Check if event1 has expired
    if rumour.events.event1.event_observed_timestamp ~= nil and (os.time() - rumour.events.event1.event_observed_timestamp) > config.event_timeout then
        rumour.events.event1.event_observed_timestamp = nil
        rumour.events.event1.is_observer = false
    end

    -- Check if event2 has expired
    if rumour.events.event2.event_observed_timestamp ~= nil and (os.time() - rumour.events.event2.event_observed_timestamp) > config.event_timeout then
        rumour.events.event2.event_observed_timestamp = nil
        rumour.events.event2.is_observer = false
    end
end

function mqttcb(topic, message)
    if topic == rumour.me.topic then
        decoded_message = json.decode(message)
        if decoded_message.type == "agent" then
            rumour.agentReceived(decoded_message)
        else
            rumour.queryReceived(decoded_message)
        end

        -- for _,event in ipairs(decoded_message.events) do
        --     rumour.log("Sending " .. event.event .. "-" .. decoded_message.type .. " from node " .. event.sender)
        -- end
        -- rumour.processReceivedMessage(decoded_message)
    end
end

function rumour.agentReceived(agent)
    agent.hops = agent.hops + 1
    
    -- Update Node
    for event,_ in pairs(agent.events) do
        agent.events[event].distance = agent.events[event].distance + 1
        if (rumour.events[event].event_distance == nil) or (rumour.events[event].event_distance > agent.events[event].distance) then
            rumour.events[event].event_distance = agent.events[event].distance
            rumour.events[event].event_direction = agent.source_direction
        end
    end -- end for

    -- Update Agent
    for event,_ in pairs(rumour.events) do
        if rumour.events[event].event_distance ~= nil then
            if agent.events[event] == nil then agent.events[event] = {} end
            agent.events[event].distance = rumour.events[event].event_distance
            agent.events[event].source_direction = rumour.me.topic
        end
    end -- end for

    if agent.hops < config.agent_max_hops then
        rumour.log("Forwarding Agent")
        sleep(config.sleep_between_hops)
        rumour.sendMessageToRandomNeighbour(agent)
    else
        rumour.log("Agent reached hops limit")
    end

end

function rumour.queryReceived(query)
    query.hops = query.hops + 1

    if query.hops < config.query_max_hops then
        if rumour.events[query.event].event_distance == nil then
            rumour.log("Forwarding query to random direction")
            sleep(config.sleep_between_hops)
            rumour.sendMessageToRandomNeighbour(query)
        elseif rumour.events[query.event].event_distance == 0 then
            rumour.AnswerEventQuery()
        elseif rumour.events[query.event].event_distance > 0 then
            rumour.log("Forwarding query to event direction")
            sleep(config.sleep_between_hops)
            rumour.sendMessageToNeighbour(query, rumour.events[query.event].event_direction)
        end
    else
        rumour.log("Query reached max hops limit")
    end

end

function rumour.AnswerEventQuery()
    rumour.log("answering event query...") -- TODO
end

function rumour.triggerMessage(message_type, message_event)
    rumour.log(message_event .. " " .. message_type .. " triggered")

    if message_type == "query" then
        message = {
            type = "query",
            event = message_event,
            source_direction = rumour.me.topic,
            hops = 0
        }

        rumour.events[message_event].query_distance = 0
        rumour.events[message_event].query_direction = rumour.me.topic

        if  rumour.events[message_event].event_direction ~= nil then
            -- encaminha no path do evento
            rumour.sendMessageToNeighbour(message, rumour.events[message_event].event_direction)
        else
            -- encaminha para vizinho aleatorio
            rumour.sendMessageToRandomNeighbour(message)
        end

    elseif message_type == "agent" then

        message = {
            type = "agent",
            events = {},
            source_direction = rumour.me.topic,
            hops = 0
        }
        message.events[message_event] = {distance = 0}

        rumour.events[message_event].event_distance = 0
        rumour.events[message_event].event_direction = rumour.me.topic

        -- rumour.events[message_event].is_observer = true
        -- rumour.events[message_event].event_observed_timestamp = os.time()
        -- rumour.sendMessageToRandomNeighbour(message)
        -- encaminha para si mesmo
        rumour.sendMessageToNeighbour(message, rumour.me.topic)
    end

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
    rumour.log("Sending " .. message.type .. " to node " .. random_neighbour)
end

function rumour.sendMessageToNeighbour(message, neighbour)
    -- Decode message table into string and publish it to mqtt
    mqtt_client:publish(neighbour, json.encode(message))
    rumour.log("Sending " .. message.type .. " to node " .. neighbour)
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