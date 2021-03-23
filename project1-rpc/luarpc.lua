local socket = require("socket")
local json = require("json")

local luarpc = {}
local servants = {}

-- Variables
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

    -- Substitutes first struct to return an array of tables
    s1, num_structs = string.gsub(idl_string, "struct", "return", 1)

    -- If there was no struct in the file, returns only the interface
    if num_structs ~= 1 then
        s1, num_structs = string.gsub(idl_string, "interface", "return", 1)
    else
        -- Replaces other structs/interfaces with tables, separated by commas
        s1, num_structs = string.gsub(s1, "struct", ",")
        s1 = string.gsub(s1, "interface", ",")
    end

    -- Loads replaced string as a function and calls it to receive the idl tables as a return
    local f, err = load(s1)
    local r = {f()}

    -- Builds idl final table
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

-- Process remote call request
local function process_request(line, idl)

    -- Decodes message
    local message = json.decode(line)
    print("Message received: " .. dump(message))

    response = {}

    -- Checks message type
    if message.type ~= 'REQUEST' then
        return nil, "Wrong message type. Expecting: REQUEST. Received: " .. message.type
    end

    -- Checks if method is in IDL
    if idl.interface.methods[message.method] == nil then
        return nil, "Invalid request. Requested method does not exist in interface"
    end

    -- Checks parameters
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
            return nil, "Invalid numbers of parameters. Expecting: " .. expected_num_params .. ". Received: " .. received_num_params
        end
    end

    return message, nil
    
end

-- Validates an object implementation with an IDL
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

            -- Checks if expected type was not struct
            for _,v in ipairs(standard_types) do
                if type_name == v then 
                    return "Invalid parameter type. Expected: " .. type_name .. ". Received: table"
                end
            end

            -- Checks struct's fields
            for _, struct_field in ipairs(idl.structs[type_name].fields) do
                if params[i][struct_field.name] == nil then
                    return "Invalid struct parameter. Missing field: " .. struct_field.name
                end

                if type(params[i][struct_field.name]) ~= struct_field.type then
                    return "Invalid struct parameter. Expected type for field " .. struct_field.name .. ": " .. struct_field.type .. ". Received: " .. type(params[i][struct_field.name])
                end
            end

        elseif type(params[i]) ~= sig_in_params[i].type then
            return "Invalid parameter type. Expected: " .. sig_in_params[i].type .. ". Received: " .. type(params[i])
        end
    end

    return nil
end

--[[#######################################################################

                    EXPORTED FUNCTIONS

############################################################################]]


-- Creates an RPC servant to serve a given object's methods
function luarpc:createServant(object, idl_string)

    local idl, err = idl_parser(idl_string)
    if err then return nil, nil, "Error parsing IDL: " .. err end

    -- Validates received object with IDL
    local err = validate_object(object, idl) 
    if err then
        return nil, nil, "Invalid object received while creating servant: " .. err
    end

    -- Defines a higher port than the ones already being used
    local port = 8888
    if next(servants) ~= nil then
        for k,v in pairs(servants) do
            if port <= v.port then
                port = v.port + 1
            end
        end
    end

    -- Creates server
    local server = assert(socket.bind("*", port))
    local ip, _ = server:getsockname()
    
    -- Defines function to receive and respond client messages
    local receive_message = function()
        
        -- Waits for client to connect
        server:settimeout(10)
        local client, timeout = server:accept()

        if client then
            print("Client connected to server on port " .. port)
            client:settimeout(10)
            client:setoption('tcp-nodelay', true)

            -- Receives message:
            local line, err = client:receive('*l')
            if line then

                -- Process request by converting to table and checking if it is valid
                request, err = process_request(line, idl)
                response = {}
                if err then
                    response['type'] = 'ERROR'
                    if request then response['method'] = request.method end
                    response['error'] = err
                else
                    response['type'] = 'RESPONSE'
                    response['method'] = request.method

                    -- Calls object method and store response
                    local result = table.pack(object[request.method](table.unpack(request.params)))
                    result["n"] = nil
                    response['result'] = result

                end

                -- Encodes response message
                local encoded_response = json.encode(response)

                -- Sends response back to client
                client:send(encoded_response .. "\n")
            else
                print("Error receiving message from client: " .. err)
            end
            -- Closes connection with client
            client:close()
        else
            print("Server timed out while accepting client connection.")
        end

    end

    -- Inserts newly created server in servants list
    servants[server] = {ip = ip, port = port, receive_message = receive_message}

    -- Returns Server's info (ip and port)
    return ip, port, nil

end


--######################## createProxy #########################

function luarpc:createProxy(idl_string, ip, port)

    local methods = {}

    -- Parse idl
    local idl, err = idl_parser(idl_string)
    if err then return nil, "Error parsing IDL: " .. err end

    -- Parsear a interface para obter uma tabela com o nome e assinatura das funções
    -- local names, signatures = get_methods_from_idl(idl)

    -- Loop sobre a tabela:
    for name, signature in pairs(idl.interface.methods) do

        -- Insere na tabela de funções uma nova função que:
        methods[name] = function(...)
        
            local params = {...}

            -- Check if method was called with 'table:function' syntax
            if params[1] == methods then
                -- Remove table self-reference from params
                table.remove(params, 1)
            end

            local err = validate_remote_call(params, idl, name)
            if err then
                print("Error: " .. err)
            end

        end
            -- Recebe parâmetros e valida se são compatíveis com os definidos na interface
            -- Completa parametros se necessário, ou gera resposta de erro caso necessário
            -- Converte parâmetros para mensagem de acordo com protocolo definido
            -- Cria objeto cliente tcp
            -- Conecta com IP e Porta do Servidor
            -- Envia mensagem
            -- Recebe resposta
            -- Converte resposta novamente de volta, de acordo com protocolo
            -- Envia resposta para quem chamou a função

    end
    -- Retorna tabela de funções
    return methods, nil

end

--######################## waitIncoming #########################

function luarpc:waitIncoming()

    -- Inserts server sockets in table
    local obs = {}
    for k,_ in pairs(servants) do
        table.insert(obs, k)
    end

    while 1 do
        -- Waiting for a server to connect
        local ready_to_read, _, err = socket.select(obs, {}, 5)

        for _,server in ipairs(ready_to_read) do
            servants[server].receive_message()
        end

    end

end

return luarpc