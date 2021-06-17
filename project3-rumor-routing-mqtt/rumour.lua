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
        event1 = {agent_path=nil, agent_hops=0, query_path=nil, query_hops=0, is_observer = false},
        event2 = {agent_path=nil, agent_hops=0, query_path=nil, query_hops=0, is_observer = false}
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
        for _,event in ipairs(decoded_message.events) do
            rumour.log("Sending " .. event.event .. "-" .. decoded_message.type .. " from node " .. event.sender)
        end
        rumour.processReceivedMessage(decoded_message)
    end
end

function rumour.processReceivedMessage(message)
    if message.type == "agent" then
        for event,_ in ipairs(rumour.events) do

            if rumour.events[event].is_observer then
                rumour.log("Received agent with " .. event .. " that node has already observed")
            else
                -- Update events table
                if message.events[event] ~= nil then -- event exists on agent
                    if rumour.events[event].agent_path == nil or rumour.events[event].agent_hops >= (message.events[event].hops + 1) then
                        rumour.events[event].agent_path = message.events[event].sender
                        rumour.events[event].agent_hops = message.events[event].hops + 1
                    end
                elseif rumour.events[event].agent_path ~= nil then -- event exists on node
                
                    -- Update agent
                    message.events[event] = {
                        event_name = event,
                        sender = rumour.me.topic,
                        hops = rumour.events[event].agent_hops
                    }
                    
                    -- Remove event from agent if it has reached max hops limit
                    if message.events[event].hops >= config.agent_max_hops then
                        rumour.log(event .. " agent reached hops limit")
                        message.events[event] = nil
                    end
                end
            end

        end
        
        -- Forward agent to random neighbour if it stills has an event
        if #message.events > 0 then
            rumour.log("Fowarding agent")
            sleep(config.sleep_between_hops)
            rumour.sendMessageToRandomNeighbour(message)
        end

    elseif message.type == "query" then

        for event,_ in ipairs(message.events) do

            -- Check if this node has observed this event
            if rumour.events[event].is_observer then
                rumour.AnswerEventQuery()
                return
            else
                -- Update events table
                rumour.events[event].query_path = message.events[event].sender
                rumour.events[event].query_hops = message.events[event].hops
    
                -- Update message
                message.events[event].sender = rumour.me.topic
                message.events[event].hops = message.events[event].hops + 1
    
            end
        end -- end for

        sleep(config.sleep_between_hops)
        -- Check events table
        if rumour.events[event].agent_path ~= nil then
            -- Forward query to node_path
            rumour.log("Forwarding event query")
            rumour.sendMessageToNeighbour(message, rumour.events[event].agent_path)
        elseif message.hops < config.query_max_hops then
            -- Forward query to random node
            rumour.log("Randomly Forwarding event query")
            rumour.sendMessageToRandomNeighbour(message)
        else
            rumour.log("Event query reached hops limit")
        end

    end -- end if query

end

function rumour.AnswerEventQuery()
    rumour.log("answering event query...") -- TODO
end

function rumour.triggerMessage(message_type, message_event)
    rumour.log(message_event .. " " .. message_type .. " triggered")

    if message_type == "query" then
        message = {
            type = message_type,
            event = message_event,
            sender = rumour.me.topic,
            hops = 0
        }

        if  rumour.events[message_event].node_path ~= nil then
            -- encaminha no path do evento
            rumour.sendMessageToNeighbour(message, rumour.events[message_event].node_path)
        else
            -- encaminha para vizinho aleatorio
            rumour.sendMessageToRandomNeighbour(message)
        end

    elseif message_type == "event" then
        message = {
            type = message_type,
            events = {
                message_event = {
                    event_name = message_event,
                    sender = rumour.me.topic,
                    hops = 0
                }
            }
        }

        rumour.events[message_event].is_observer = true
        rumour.events[message_event].event_observed_timestamp = os.time()
        -- encaminha para vizinho aleatorio
        rumour.sendMessageToRandomNeighbour(message)
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
    for _,event in ipairs(message.events) do
        rumour.log("Sending " .. event.event .. "-" .. message.type .. " to node " .. random_neighbour)
    end
end

function rumour.sendMessageToNeighbour(message, neighbour)
    -- Decode message table into string and publish it to mqtt
    mqtt_client:publish(neighbour, json.encode(message))
    for _,event in ipairs(message.events) do
        rumour.log("Sending " .. event.event .. "-" .. message.type .. " to node " .. random_neighbour)
    end
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