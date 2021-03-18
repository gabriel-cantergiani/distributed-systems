
local luarpc = {}


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

    -- Parsear a interface
    local idl = idl_parser(idl_string)
    -- print(idl)
    

    -- Valida se objeto recebido é compatível com a interface
    
    -- Cria objeto server

    -- Cria função para escutar requisição

        -- Usa objeto server para esperar mensagem
        -- Quando receber mensagem, trata mensagem:
            -- Converte usando protocolo determinado para obter nome do método e parametros
            -- Chama método do objeto
            -- Obtém resposta
            -- Converte novamente a resposta de acordo com protocolo determinado
        -- Gera mensagem de resposta e envia para o client
        -- Fecha conexao com client (primeira versao)

    -- Insere esta instância de Servant(ip, porta e função de escuta) em uma lista Global de Servants

    -- Retorna dados desse servant (ip e porta)

end



--######################## createProxy #########################

function createProxy(interface, ip, porta)

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

function waitIncoming()

    -- Obtem tabela global com os servants registrados

    -- Loop sobre os servants:

        -- chama select para receber pedidos a cada servant

end


return luarpc