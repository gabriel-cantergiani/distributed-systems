
## About
The main goal of this project is to implement a basic RPC library in Lua. This library is implemented in the ```luarpc.lua``` file. It exports 3 functions:

- **createServant**: receives an IDL file and an object implementing the IDL methods. It then creates an RPC server for this object, returning a table with the server IP and PORT.

- **createProxy**: receives an IDL file, the RPC server IP and the RPC server PORT. It creates and returns a stub/proxy responsible for calling the remote methods defined in the IDL.

- **waitIncoming**: Starts to monitor multiple servers (created in the same luarpc object), listening for connections from clients to any of the observed servers

## Running the client-server examples

To run the server:
```bash
lua server.lua
```
or
```bash
make run-server
```

To run the client (assuming the server is on localhost):
```bash
lua client.lua localhost 8888
```
or
```bash
make run-client
```

It is possible to change the initial port by setting the environment variable ```PORT```. All subsequent servers are going to listen on ports higher than the initial one (PORT+1, PORT+2,...).

## Running client-server on Docker Containers

To run on containers, Docker and Docker-Compose are required to be installed and running

To run the server:
```bash
make run-server-container
```

To run the client:
```bash
make run-client-container
```

## Using the rpclua library

To use ```rpclua``` as a **client**:
```lua
luarpc = require("luarpc")
-- 
...
-- Creating Proxy
proxy = luarpc:createProxy(IDL, server_ip, server_port)

-- Calling remote method
result = proxy:boo(param1, param2)
```

To use ```rpclua``` as a **server**:
```lua
luarpc = require("luarpc")
...
-- Creating a server
server = luarpc:createServant(object, IDL)

-- Starting to monitor servers
luarpc:waitIncoming()
```

Where ```IDL``` is a string containing the interface definition, ```object``` is an object that implements this interface, and ```boo``` is a method from this object.

An example of an accepted is interface is defined below:
```idl
struct { 
    name = "minhaStruct",
    fields = {
        {name = "nome",type = "string"},
        {name = "peso",type = "double"},
        {name = "idade",type = "int"}
    }
}

interface { 
    name = "minhaInt",
    methods = {
        foo = {
            resulttype = "double",
            args = {
                {direction = "in",type = "double"},
                {direction = "in",type = "string"},
                {direction = "in",type = "minhaStruct"},
                {direction = "out",type = "int"}
            }
        },
        boo = {
            resulttype = "int",
            args = {
                {direction = "in",type = "int"},
                {direction = "in",type = "minhaStruct"},
                {direction = "out",type = "minhaStruct"}
            }
        }
    }
}
```

A more detailed example of usage is implemented on ```client.lua``` and ```server.lua``` files.