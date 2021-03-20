local socket = require("socket")

local server_ip = arg[1]
local server_port = arg[2]

local client = assert(socket.tcp())

local _, err = client:connect(server_ip, server_port)

if err then
    print("Error connecting to server: " .. err)
    os.exit()
end

print("Connected!")

socket.sleep(2)

print("Sending hello message...")
client:settimeout(10)

local result, err = client:send("Hello from client\n")

if err then
    print(err)
    client:close()
    os.exit()
end

print(result .. "bytes sent")

print("Waiting for response...")
local response, err = client:receive('*l')
if not err then
    print("Response received: " .. response)
else
    print("Error: " .. err)
end

client:close()