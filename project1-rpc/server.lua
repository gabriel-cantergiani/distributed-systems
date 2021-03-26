luarpc = require("luarpc")

-- Creates server objects
object1 = { 
    foo =   
        function (a, s, st)
            return a*2, string.len(s) + st.idade
        end,
    boo = 
        function (n)
            return n*2, { nome = "Bia", idade = n*30, peso = n*61.0}
        end
}

-- Reads IDL file
io.input("example1.idl")
local idl_string = io.read("*all")


-- Creates servants
server_info = luarpc:createServant(object1, idl_string)
if server_info then print("Servant registered on IP=" .. server_info.ip .. " and PORT=" ..  server_info.port) end

server_info2 = luarpc:createServant(object1, idl_string)
if server_info2 then print("Servant registered on IP=" .. server_info2.ip .. " and PORT=" ..  server_info2.port) end

-- Calls waitIncoming
luarpc:waitIncoming()