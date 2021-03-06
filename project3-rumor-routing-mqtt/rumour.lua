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
        event1 = {event_direction=nil, event_distance=nil, query_direction=nil, query_distance=nil, is_observer = false, is_query_source = false},
        event2 = {event_direction=nil, event_distance=nil, query_direction=nil, query_distance=nil, is_observer = false, is_query_source = false}
    }

    rumour.initial_timestamp = os.time()
    
    -- MQTT set up
    rumour.me.topic = "no-" .. tostring(rumour.me.position_x) .. "-" .. tostring(rumour.me.position_y)
    mqtt_client = mqtt.client.create(config.mqtt_server_address, config.mqtt_server_port, mqttcb)
    error = mqtt_client:connect("Node " .. tostring(rumour.me.id))
    if error ~= nil then
        rumour.log(tostring(error), true)
        rumour.mqtt_error = tostring(error)
        return tostring(error)
    end
    mqtt_client:subscribe({rumour.me.topic})
    rumour.log("Connection to mqtt server successful", true)
    rumour.log("Waiting for messages...", true)
    
    return nil
end

function rumour.getNodePosition()
    return rumour.me.position_x, rumour.me.position_y
end

function rumour.HandleMqtt()

    if rumour.mqtt_error ~= nil then return end

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
        elseif decoded_message.type == "query" then
            rumour.queryReceived(decoded_message)
        else
            rumour.queryResponseReceived(decoded_message)
        end
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
        end
    end -- end for
    
    agent.source_direction = rumour.me.topic

    if agent.hops < config.agent_max_hops then
        rumour.log("Forwarding Agent", true)
        sleep(config.sleep_between_hops)
        rumour.sendMessageToRandomNeighbour(agent)
    else
        rumour.log("Agent reached hops limit", true)
    end

end

function rumour.queryReceived(query)

    -- Update Node
    rumour.events[query.event].query_direction = query.source_direction
    rumour.events[query.event].distance = query.hops

    -- Update query
    query.hops = query.hops + 1
    
    if rumour.events[query.event].event_distance == nil then
        query.source_direction = rumour.me.topic
        if query.hops < config.query_max_hops then
            rumour.log("Forwarding query to random direction", true)
            sleep(config.sleep_between_hops)
            rumour.sendMessageToRandomNeighbour(query)
        else
            rumour.log("Query for " .. query.event .. " reached max hops limit", true)
        end
    elseif rumour.events[query.event].event_distance == 0 then
        rumour.AnswerEventQuery(query)
    elseif rumour.events[query.event].event_distance >= 1 then
        query.source_direction = rumour.me.topic
        rumour.log("Forwarding query to event direction", true)
        sleep(config.sleep_between_hops)
        rumour.sendMessageToNeighbour(query, rumour.events[query.event].event_direction)
    end

end

function rumour.queryResponseReceived(queryResponse)

    if rumour.events[queryResponse.event].is_query_source then
        rumour.log("Received Event Information: " .. tostring(queryResponse.event_information), true)
    elseif rumour.events[queryResponse.event].query_direction == nil then
        rumour.log("Received query response but there is no path to query", true)
    else
        rumour.log("Forwarding query response to query direction", true)
        sleep(config.sleep_between_hops)
        rumour.sendMessageToNeighbour(queryResponse, rumour.events[queryResponse.event].query_direction)
    end
end

function rumour.AnswerEventQuery(query)
    rumour.log("Answering event query...", true) -- TODO

    message = {
        type = "query-response",
        event = query.event,
        event_information = "foo" -- Aqui entraria o dado relativo ao evento
    }

    -- Send response back to query source direction
    sleep(config.sleep_between_hops)
    rumour.sendMessageToNeighbour(message, query.source_direction)

end

function rumour.triggerMessage(message_type, message_event)
    rumour.log(message_event .. " " .. message_type .. " triggered", true)

    if message_type == "query" then
        message = {
            type = "query",
            event = message_event,
            source_direction = rumour.me.topic,
            hops = 0,
            visited_nodes = {}
        }

        table.insert(message.visited_nodes, rumour.me.topic)

        rumour.events[message_event].query_distance = 0
        rumour.events[message_event].query_direction = rumour.me.topic
        rumour.events[message_event].is_query_source = true

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
            hops = 0,
            visited_nodes = {}
        }
        message.events[message_event] = {distance = 0}

        rumour.events[message_event].event_distance = 0
        rumour.events[message_event].event_direction = rumour.me.topic

        -- Forward message to itself
        rumour.sendMessageToNeighbour(message, rumour.me.topic)
    end

end

function rumour.Estado()
    rumour.log("Node state:", true)
    if rumour.events.event1.event_direction ~= nil then
        rumour.log("Event 1: direction=" .. rumour.events.event1.event_direction .. ", distance=" .. rumour.events.event1.event_distance, true)
    end
    if rumour.events.event2.event_direction ~= nil then
        rumour.log("Event 2: direction=" .. rumour.events.event2.event_direction .. ", distance=" .. rumour.events.event2.event_distance, true)
    end
end

function rumour.sendMessageToRandomNeighbour(message)

    table.insert(message.visited_nodes, rumour.me.topic)

    found, random_neighbour = rumour.getUnvisitedRandomNeighbour(message.visited_nodes)

    if not found then
        rumour.log("All neighbours were already visited by " .. message.type, true)
        return
    end

    -- Decode message table into string and publish it to mqtt
    mqtt_client:publish(random_neighbour, json.encode(message))
    rumour.log("Sending " .. message.type .. " to node " .. random_neighbour, true)
end

function rumour.sendMessageToNeighbour(message, neighbour)
    -- Decode message table into string and publish it to mqtt
    mqtt_client:publish(neighbour, json.encode(message))
    rumour.log("Sending " .. message.type .. " to node " .. neighbour, true)
end

function rumour.getUnvisitedRandomNeighbour(visited_nodes)
    
    -- Shuffle neighbours list
    local shuffled_neighbours = {}
    for i, v in ipairs(rumour.neighbours) do
        local pos = math.random(1, #shuffled_neighbours+1)
        table.insert(shuffled_neighbours, pos, v)
    end

    
    local neighbour_visited_by_agent = false
    
    -- Get neighbour one by one, checking if it was already visited
    for _,random_neighbour in ipairs(shuffled_neighbours) do
        for _,node in ipairs(visited_nodes) do
            if node == random_neighbour then 
                neighbour_visited_by_agent = true
                break
            end
        end
        if not neighbour_visited_by_agent then
            return true, random_neighbour
        end
        neighbour_visited_by_agent = false
    end

    return false, nil

end


function rumour.log(message, print)
    msg = "[" .. (os.time() - rumour.initial_timestamp) .. "s][Node ".. tostring(rumour.me.id) .. "] " .. tostring(message)
    rumour.outputFile:write(msg .. "\n")
    if print then rumour.print(message) end
end


function sleep(time)
    local duration = os.time() + time
    while os.time() < duration do end
end

return rumour