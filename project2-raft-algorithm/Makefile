# RUN LOCAL
run-raft-server1:
	lua init_server.lua 1

run-raft-server2:
	lua init_server.lua 2

run-raft-server3:
	lua init_server.lua 3

run-raft-server4:
	lua init_server.lua 4

run-raft-server5:
	lua init_server.lua 5

run-raft-tests:
	./tests.sh

test-initialize-all-nodes:
	lua test_client.lua 1 InitializeNode & && \
	lua test_client.lua 2 InitializeNode & && \
	lua test_client.lua 3 InitializeNode & && \
	lua test_client.lua 4 InitializeNode & && \
	lua test_client.lua 5 InitializeNode &

test-stop-node-1:
	lua test_client.lua 1 StopNode

test-partition-node-1:
	lua test_client.lua 1 PartitionNode

test-resume-node-1:
	lua test_client.lua 1 ResumeNode

# RUN ON DOCKER CONTAINERS
run-raft-all-container:
	docker-compose up

run-raft-2-servers-container:
	docker-compose up raft-server1 raft-server2

run-raft-3-servers-container:
	docker-compose up raft-server1 raft-server2 raft-server3

run-raft-4-servers-container:
	docker-compose up raft-server1 raft-server2 raft-server3 raft-server4

run-raft-5-servers-container:
	docker-compose up raft-server1 raft-server2 raft-server3 raft-server4 raft-server5
	
run-tests-container:
	docker-compose up raft-tests
