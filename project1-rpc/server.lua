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
ip, port, err = luarpc:createServant(object1, idl_string)
if err then print(err) else print("Servant registered on IP=" .. ip .. " and PORT=" ..  port) end

ip, port, err = luarpc:createServant(object1, idl_string)
if err then print(err) else print("Servant registered on IP=" .. ip .. " and PORT=" ..  port) end

-- Calls waitIncoming
luarpc:waitIncoming()