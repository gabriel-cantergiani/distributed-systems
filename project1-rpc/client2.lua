luarpc = require("luarpc")

local server_ip = arg[1]
local server_port = arg[2]

if server_ip == nil or server_port == nil then
    print("Error: missing argument(s).\nUsage: lua client.lua <SERVER_IP> <SERVER_PORT>")
    os.exit()
end

-- Reads IDL file
io.input("example1.idl")
local idl_string = io.read("*all")


-- Create proxy
proxy1, err = luarpc:createProxy(idl_string, server_ip, server_port)
if err then
    print(err)
else
    -- Call method
    local result = proxy1:boo(5, {nome = "joao", peso = 170.5, idade = 25})
    print(result)
end