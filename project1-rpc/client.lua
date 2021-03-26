luarpc = require("luarpc")

local server_ip = arg[1]
local server_port = arg[2]

if server_ip == nil or server_port == nil then
    print("Error: missing argument(s).\nUsage: lua client.lua <SERVER_IP> <SERVER_PORT>")
    os.exit()
end

-- Read IDL file
io.input("example1.idl")
local idl_string = io.read("*all")


-- Create proxy
proxy1 = luarpc:createProxy(idl_string, server_ip, server_port)
if proxy1 then
    -- Call method
    local result = proxy1:boo(5, {nome = "joao", peso = 170.5, idade = nil})
    print(result)
end

proxy2 = luarpc:createProxy(idl_string, server_ip, server_port+1)
if proxy2 then
    local result = proxy2:foo(3.0, "hello", {nome = "paula", peso = 65, idade = 33})
    print(result)
end