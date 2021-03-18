local socket = require("socket")

local client = assert(socket.tcp())

client:connect("lua-server", 8888)

print("Connected!")

socket.sleep(2)

print("Sending hello message...")
client:settimeout(10)

local result, err = client:send("Hello from client\n")

if err then
    print(err)
end

print(result .. "bytes sent")

client:close()