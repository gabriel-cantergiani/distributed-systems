
echo "Starting Tests..."

# Initialize Node 1 
echo "Testing InitializeNode 1"
lua /root/test_client.lua raft-server1 8888 InitializeNode &
# Initialize Node 2
echo "Testing InitializeNode 2"
lua /root/test_client.lua raft-server2 8889 InitializeNode &
sleep 5

# # Stop Node 1 test
# echo "Testing StopNode 1"
# lua /root/test_client.lua raft-server1 8888 StopNode 15 &
# # Stop Node 2 test
# echo "Testing StopNode 2"
# lua /root/test_client.lua raft-server2 8889 StopNode 9 &


sleep 16
# Finished Testing
echo "Finished All Tests"