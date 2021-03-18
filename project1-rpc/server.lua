luarpc = require("luarpc")

-- Cria objeto(s)
object1 = {}

-- Abre arquivo da interface
io.input("example1.idl")
local idl_string = io.read("*all")




-- Cria Servants
luarpc:createServant(object1, idl_string)

-- Chama waitIncoming