local socket = require("socket")
local json = require("json")

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

local message = {type = 'REQUEST', method = "boo", params = {5}}
local encoded_message = json.encode(message)
local result, err = client:send(encoded_message .. "\n")

if err then
    print(err)
    client:close()
    os.exit()
end

print(result .. "bytes sent")

print("Waiting for response...")
local response, err = client:receive('*l')
local decoded_response = json.decode(response)
if not err then
    print("Response received: " .. dump(decoded_response))
else
    print("Error: " .. err)
end

client:close()