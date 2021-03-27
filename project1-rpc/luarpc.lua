local socket = require("socket")
local json = require("json")

-- Variables
local luarpc = {}
local servants = {}
local standard_types = {'int', 'double', 'string', 'nil', 'boolean', 'number', 'userdata', 'function', 'thread', 'table'}


--[[#######################################################################

                    LOCAL FUNCTIONS

############################################################################]]

local function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end
 

-- Parses an IDL string and create an IDL table
local function idl_parser(idl_string)

    -- Substitute first struct to return an array of tables
    s1, num_structs = string.gsub(idl_string, "struct", "return", 1)

    -- If there was no struct in the file, return only the interface
    if num_structs ~= 1 then
        s1, num_structs = string.gsub(idl_string, "interface", "return", 1)
    else
        -- Replace other structs/interfaces with tables, separated by commas
        s1, num_structs = string.gsub(s1, "struct", ",")
        s1 = string.gsub(s1, "interface", ",")
    end

    -- Load replaced string as a function and calls it to receive the idl tables as a return
    local f, err = load(s1)
    local r = {f()}

    -- Build idl final table
    idl = {interface = {}, structs = {}}
    for k,v in pairs(r) do
        if v['fields'] ~= nil then
            idl["structs"][v["name"]] = v
        else
            idl["interface"] = v
        end
    end

    -- Check if structs are defined and also change int and double types for number
    for method, _ in pairs(idl.interface.methods) do
        for _, arg in ipairs(idl.interface.methods[method].args) do
            standard_types = {'int', 'double', 'string', 'nil', 'boolean', 'number', 'userdata', 'function', 'thread', 'table'}
            found = 0
            for _,v in ipairs(standard_types) do
                if arg.type == v then found = 1 end
            end
            
            if found == 0 and idl.structs[arg.type] == nil then
                return nil, "Struct " .. arg.type .. " not found"
            end

            if arg.type == "int" or arg.type == "double" then
                arg.type = 'number'
            end
        end
    end

    -- Change int and double types to number on struct fields
    for _, struct in pairs(idl.structs) do
        for _, field in ipairs(struct.fields) do
            if field.type == "int" or field.type == "double" then
                field.type = "number"
            end
        end
    end

    return idl, nil
end

-- Try to convert received parameters to the type defined in IDL
local function convert_value(received_param, idl_param)
    if type(received_param) == 'string' then
        -- Convert string to number
        if idl_param.type == 'number' then
            converted_number = tonumber(received_param)
            if converted_number then 
                received_param = converted_number
                return nil
            else
                return "Error converting parameter type. Expected: " .. idl_param.type .. ". Received: " .. received_param .. " (" .. type(received_param) .. ")"
            end
        -- Convert string to boolean
        elseif idl_param.type == 'boolean' then
            if received_param == 'false' or received_param == 'False' or received_param == '0' then
                received_param = false
            else
                received_param = true
            end
            return nil
        end
    -- Convert number to boolean
    elseif type(received_param) == 'number' and idl_param.type == 'boolean' then
        if received_param == 0 then
            received_param = false
        else
            received_param = true
        end
        return nil
    end

    return "Invalid parameter type. Expected: " .. idl_param.type .. ". Received: " .. type(received_param)
end

-- Process remote call request
local function process_request(line, idl)

    -- Decode message
    local message = json.decode(line)

    response = {}

    -- Check message type
    if message.type ~= 'REQUEST' then
        return nil, "Wrong message type. Expecting: REQUEST. Received: " .. message.type
    end

    -- Check if method is in IDL
    if idl.interface.methods[message.method] == nil then
        return nil, "Invalid request. Requested method does not exist in interface"
    end

    -- Check parameters
    if idl.interface.methods[message.method].args then
        if message.params == nil then
            return nil, "Missing method parameters"
        end

        expected_num_params = 0
        for _,v in ipairs(idl.interface.methods[message.method].args) do
            if v.direction == "in" then expected_num_params = expected_num_params + 1 end
        end
        received_num_params = #message.params

        if expected_num_params ~= received_num_params then
            return nil, "Invalid number of parameters. Expecting: " .. expected_num_params .. ". Received: " .. received_num_params
        end
    end

    return message, nil
    
end

-- Validate an object implementation with an IDL
local function validate_object(object, idl)

    for k,v in pairs(idl.interface.methods) do
        if object[k] == nil then 
            return "Method '" .. k .. "' not found" 
        end
    end

    return nil
end

-- Validate parameters of a remote method call
local function validate_remote_call(params, idl, method_name)

    -- Check number of parameters
    sig_in_params = {}
    sig_out_params = {}
    for _,v in ipairs(idl.interface.methods[method_name].args) do
        if v.direction == 'in' then table.insert(sig_in_params, v) else table.insert(sig_out_params, v) end
    end

    if #params ~= #sig_in_params then
        return "Invalid number of arguments. Expected: " .. #sig_in_params .. ". Received: " .. #params
    end
    
    -- Check params types
    for i = 1, #params do

        -- Checking struct types
        if type(params[i]) == 'table' then
            type_name = sig_in_params[i].type

            -- Check if expected type was not struct
            for _,v in ipairs(standard_types) do
                if type_name == v then 
                    return "Invalid parameter type. Expected: " .. type_name .. ". Received: table"
                end
            end

            -- Check struct's fields
            for _, struct_field in ipairs(idl.structs[type_name].fields) do
                if params[i][struct_field.name] ~= nil and type(params[i][struct_field.name]) ~= struct_field.type then
                    err = convert_value(params[i][struct_field.name], struct_field)
                    if err then return "Invalid struct: " .. err end
                end
            end

        elseif type(params[i]) ~= sig_in_params[i].type then
            err = convert_value(params[i], sig_in_params[i])
            if err then return err end
        end
    end

    return nil
end

--[[#######################################################################

                    EXPORTED FUNCTIONS

############################################################################]]


-- Creates an RPC servant to serve a given object's methods
function luarpc:createServant(object, idl_string)

    local ok, return_value, err = pcall(idl_parser, idl_string)
    if not ok or err ~= nil then
        local msg = err or return_value
        print("Error parsing IDL: " .. msg) 
        return nil
    end
    local idl = return_value

    -- Validate received object with IDL
    local ok, err = pcall(validate_object, object, idl) 
    if not ok or err then
        msg = err or ""
        print("Invalid object received while creating servant: " .. err)
        return nil
    end

    -- Define a higher port than the ones already being used
    local port = 8888
    if next(servants) ~= nil then
        for k,v in pairs(servants) do
            if port <= v.port then
                port = v.port + 1
            end
        end
    end

    -- Create server
    local server = assert(socket.bind("*", port))
    local ip, _ = server:getsockname()
    
    -- Define function to receive and respond client messages
    local receive_message = function()
        
        -- Wait for client to connect
        server:settimeout(10)
        local client, timeout = server:accept()

        if client then
            print("Client connected to server on port " .. port)
            client:settimeout(10)
            client:setoption('tcp-nodelay', true)

            -- Receive message:
            local line, err = client:receive('*l')
            if line then

                -- Process request by converting to table and checking if it is valid
                ok, return_value, err = pcall(process_request, line, idl)
                response = {}
                if not ok or err then
                    response['type'] = 'ERROR'
                    if request then response['method'] = request.method end
                    msg = err or return_value
                    response['error'] = msg
                else
                    local request = return_value
                    response['type'] = 'RESPONSE'
                    response['method'] = request.method

                    -- Call object method and store response
                    local result = table.pack(object[request.method](table.unpack(request.params)))
                    result["n"] = nil
                    response['result'] = result

                end

                -- Encode response message
                local encoded_response = json.encode(response)

                -- Send response back to client
                client:send(encoded_response .. "\n")
            else
                print("Error receiving message from client: " .. err)
                return nil
            end
            -- Close connection with client
            client:close()
        else
            print("Server timed out while accepting client connection")
            return nil
        end

    end

    -- Insert newly created server in servants list
    servants[server] = {ip = ip, port = port, receive_message = receive_message}

    -- Return Server's info (ip and port)
    return {ip=ip, port=port}

end


--######################## createProxy #########################

function luarpc:createProxy(idl_string, ip, port)

    local methods = {}

    -- Parse idl
    local ok, return_value, err = pcall(idl_parser, idl_string)
    if not ok or err then
        local msg = err or return_value
        print ("Error parsing IDL: " .. msg)
        return nil 
    end
    local idl = return_value

    for name, signature in pairs(idl.interface.methods) do

        -- Creating stub's methods
        methods[name] = function(...)
        
            local params = {...}

            -- Check if method was called with 'table:function' syntax
            if params[1] == methods then
                -- Remove table self-reference from params
                table.remove(params, 1)
            end

            -- Validate received parameters
            local ok, err = pcall(validate_remote_call, params, idl, name)
            if not ok or err then
                local msg = err or ""
                print("Error validating parameters: " .. msg)
                return nil
            end
    
            -- Convert and encode request to protocol
            request = {
                type = "REQUEST", 
                method = name,
                params = params
            }
            local encoded_request = json.encode(request)

            -- Create client socket and connect to server
            local client = assert(socket.tcp())
            local _, err = client:connect(ip, port)
            if err then
                print("Error connecting to remote server: " .. err)
                return nil
            end
            
            client:settimeout(5)

            -- Send remote procedure call
            local _, err = client:send(encoded_request .. "\n")
            if err then
                print("Error sending request to remote server: " .. err)
                return nil
            end

            local encoded_response, err = client:receive('*l')
            if err then
                print("Error receiving response from remote server: " .. err)
                return nil
            end

            -- Process response
            local response = json.decode(encoded_response)
                
            if response.type == "ERROR" then
                print("Error response from server: " .. response.error)
                return nil
            elseif response.type ~= "RESPONSE" then
                print("Invalid response type from server: " .. response.type)
                return nil
            end

            client:close()

            -- Return RPC response
            return response.result

        end

    end

    -- Return stub
    return methods, nil

end

--######################## waitIncoming #########################

function luarpc:waitIncoming()

    -- Insert server sockets in table
    local obs = {}
    for k,_ in pairs(servants) do
        table.insert(obs, k)
    end

    while 1 do
        -- Waiting for a server to connect
        local ready_to_read, _, err = socket.select(obs, {}, 5)

        for _,socket_ready in ipairs(ready_to_read) do
            servants[socket_ready].receive_message()
            -- TODO
            -- Preciso inserir o socket client na lista de observáveis logo após o accept do servidor!
        end

    end

end

return luarpc