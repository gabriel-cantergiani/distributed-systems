local socket = require("socket")

local luarpc = {}
local servants = {}


-- ######################## Local functions ######################
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
 

-- Parse an IDL string and create an IDL table
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


--######################## createServant #########################

function luarpc:createServant(object, idl_string)

    local idl = idl_parser(idl_string)
    
    -- Valida se objeto recebido é compatível com a interface ??? (- TODO)
    

    -- Define a higher port than the ones already being used
    local port = 8888
    if next(servants) ~= nil then
        for _,v in ipairs(servants) do
            if port <= v.port then
                port = v.port + 1
            end
        end
    end

    -- Create server
    local server = assert(socket.bind("*", port))
    local ip, _ = server:getsockname()
    
    -- Cria função para escutar requisição
    local start_server = function()
        
        -- Waits for client to connect
        server:settimeout(10)
        local client, timeout = server:accept()

        if client then
            print("Client connected to server on port " .. port)
            client:settimeout(10)
            client:setoption('tcp-nodelay', true)

            -- Receive message:
            local line, err = client:receive('*a')
            if line then
                print("Message received: ", line)
                -- TODO
                -- Converte usando protocolo determinado para obter nome do método e parametros
                -- Chama método do objeto
                -- Obtém resposta
                -- Converte novamente a resposta de acordo com protocolo determinado
            else
                print("Error receiving message from client: " .. err)
            end
        -- Gera mensagem de resposta e envia para o client
        -- Fecha conexao com client (primeira versao)
        else
            print("Server timeout...")
        end

    end

    -- Insert newly created server in servants list
    table.insert(servants, {ip = ip, port = port, start_server = start_server})


    -- Return Server's info (ip and port)
    return ip, port

end



--######################## createProxy #########################

function luarpc:createProxy(interface, ip, porta)

    -- Cria tabela de funções

    -- Parsear a interface para obter uma tabela com o nome e assinatura das funções

    -- Loop sobre a tabela:

        -- Insere na tabela de funções uma nova função que:
            -- Recebe parâmetros e valida se são compatíveis com os definidos na interface
            -- Completa parametros se necessário, ou gera resposta de erro caso necessário
            -- Converte parâmetros para mensagem de acordo com protocolo definido
            -- Cria objeto cliente tcp
            -- Conecta com IP e Porta do Servidor
            -- Envia mensagem
            -- Recebe resposta
            -- Converte resposta novamente de volta, de acordo com protocolo
            -- Envia resposta para quem chamou a função

    -- Retorna tabela de funções

end

--######################## waitIncoming #########################

function luarpc:waitIncoming()

    -- Obtem tabela global com os servants registrados

    while 1 do
        -- Loop sobre os servants:
        for _,v in ipairs(servants) do
            print("Starting server on port: " .. v.port)
            -- chama select para receber pedidos a cada servant
            v.start_server()
            print("Server stopped")
        end
        socket.sleep(5)
    end

end


return luarpc