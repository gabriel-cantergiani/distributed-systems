luarpc = require("luarpc")

-- Creates server objects
object1 = { 
    foo =   
        function (a, s, st)
            return a*2, string.len(s) + st.idade
        end,
    boo = 
        function (n)
            return n, { nome = "Bia", idade = 30, peso = 61.0}
        end
}

-- Reads IDL file
io.input("example1.idl")
local idl_string = io.read("*all")


-- Creates servants
ip, port = luarpc:createServant(object1, idl_string)
print("Servant registered on IP=" .. ip .. " and PORT=" .. port)

ip, port = luarpc:createServant(object1, idl_string)
print("Servant registered on IP=" .. ip .. " and PORT=" .. port)

-- Calls waitIncoming
luarpc:waitIncoming()