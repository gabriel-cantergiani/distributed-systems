
## About
The main goal of this project is to implement the Leader Election of the [Raft Consensus Algorithm](https://raft.github.io/) in Lua. It uses a RPC library (```luarpc.lua```) to exchange RPC messages between nodes, and it simulates an asynchronous communication using Lua`s coroutines. It also includes a test scripts to simulate partition and timeout behaviours between nodes.

For more information about how Raft Algorithm works, see [Raft`s official page](https://raft.github.io/)

There are two ways to run this implementation:
- Run directly on a terminal using lua, which requires lua and lua-socket to be installed
- Run on docker containers, which requires Docker and Docker Compose to be installed

## Running directly with lua and lua-socket

All settings are in ```config.lua``` file. You should use the ```config.servers``` table to change how many nodes do you want to run, in which addresses and ports. The IDs in this table is used to referred to each node in the commands below.

Before starting the algorithm, run the following commands to start the RPC servers (**Each command must be ran in separate terminals/processes**).
```bash
$ lua init_server.lua 1
or
$ make run-raft-server1
...
$ lua init_server.lua 2
or
$ make run-raft-server2
...
$ lua init_server.lua 3
or
$ make run-raft-server3
...
```

Run the command above for each server configured in ```config.lua``` file. The last argument of these commands is the same ID configured in the file.

To initialize the algorithm and start testing:
```bash
$ lua test_client.lua 1 InitializeNode &
$ lua test_client.lua 2 InitializeNode &
$ lua test_client.lua 3 InitializeNode &
...
or
$ make test-initialize-all-nodes
```

To simulate a partition and exclude a node from the network (using node 1 as example):
```bash
$ lua test_client.lua 1 PartitionNode
ou
$ make test-partition-node-1
```

To simulate a node stopping (the node also stop executing the algorithm):
```bash
$ lua test_client.lua 1 StopNode
ou
$ make test-stop-node-1
```

To simulate the resuming of a node (it comes back from partition and also from a stop):
```bash
$ lua test_client.lua 1 Resume
ou
$ make test-resume-node-1
```

To do the same tests with other nodes, run the same commands passing other IDs as arguments.

Or, to run automated tests in sequence:
```bash
$ ./tests.sh
ou
$ make run-raft-tests
```

These tests doesnt validate results, they just call all commands in sequence, with a sleep within each command. To validate if the algorithm is working as expected, you should monitor the logs and outputs of each node.

## Running on Docker Containers

To start 5 Nodes (ids 1 to 5), on in each containers:
```bash
make run-raft-5-servers-container
```

To start the algorithm and run tests:
```bash
make run-tests-container
```
