local socket = require("socket")
local json = require("json")

local luarpc = {}
local servants = {}


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

    -- Loads replaced string as a function and call it to receive the idl table as a return
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

    return idl
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

local function get_methods_from_idl(idl)

    names = {}
    signatures = {}

    return names, signatures
end

--[[#######################################################################

                    EXPORTED FUNCTIONS

############################################################################]]


-- Creates an RPC servant to serve a given object's methods
function luarpc:createServant(object, idl_string)

    local idl = idl_parser(idl_string)
    
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



local function validate_remote_call(params, signature)

    -- Check number of parameters
    sig_in_params = {}
    sig_out_params = {}
    for _,v in ipairs(signature.args) do
        if v.direction == 'in' then table.insert(sig_in_params, v) else table.insert(sig_out_params, v) end
    end

    if #params ~= #sig_in_params then
        return "Invalid number of arguments. Expected: " .. #params .. ". Received: " .. #sig_in_params
    end
    
    -- Check params types
    for i = 1, #params do
        if type(params[i]) == 'number' then
            if sig_in_params[i].type ~= 'int' and sig_in_params[i].type ~= 'double' then
                return "Invalid parameter type. Expected: number. Received: " .. type(params[i])
            end
        elseif type(params[i] == 'table') then
            -- TODO
            -- trata struct
        elseif type(params[i]) ~= sig_in_params[i].type then
            return "Invalid parameter type. Expected: " .. sig_in_params[i].type .. ". Received: " .. type(params[i])
        end
    end

    return nil
end

--######################## createProxy #########################

function luarpc:createProxy(idl_string, ip, port)

    local methods = {}

    -- Parse idl
    local idl = idl_parser(idl_string)

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

            local err = validate_remote_call(params, signature)
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
    return methods

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