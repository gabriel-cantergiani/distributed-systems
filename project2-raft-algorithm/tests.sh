
echo "Starting Tests..."

# Initialize Node 1 
echo "Testing InitializeNode 1"
lua /root/test_client.lua raft-server1 8888 InitializeNode &
sleep 5

# Stop Node 1 test
echo "Testing StopNode 1"
# lua /root/test_client.lua raft-server1 8888 StopNode
sleep 10

# Finished Testing
echo "Finished All Tests"