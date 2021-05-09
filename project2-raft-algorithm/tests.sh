
echo "Starting Tests..."

echo "Testing InitializeNode 1"
lua /root/test_client.lua raft-server1 8888 InitializeNode &
echo "Testing InitializeNode 2"
lua /root/test_client.lua raft-server2 8889 InitializeNode &
echo "Testing InitializeNode 3"
lua /root/test_client.lua raft-server3 9000 InitializeNode &
sleep 25

# echo "Testing StopNode 1"
# lua /root/test_client.lua raft-server1 8888 StopNode &
# sleep 25

# echo "Testing ResumeNode 1"
# lua /root/test_client.lua raft-server1 8888 ResumeNode &
# sleep 25

# echo "Testing StopNode 2"
# lua /root/test_client.lua raft-server2 8889 StopNode &
# sleep 25

# echo "Testing ResumeNode 2"
# lua /root/test_client.lua raft-server2 8889 ResumeNode &
# sleep 25

# echo "Testing StopNode 3"
# lua /root/test_client.lua raft-server3 9000 StopNode &
# sleep 25

# echo "Testing ResumeNode 3"
# lua /root/test_client.lua raft-server3 9000 ResumeNode &
# sleep 25

echo "Testing Multiple StopNodes (1 and 2)"
lua /root/test_client.lua raft-server1 8888 StopNode &
lua /root/test_client.lua raft-server2 8889 StopNode &
sleep 25

echo "Testing Multiple ResumeNodes (1 and 2)"
lua /root/test_client.lua raft-server1 8888 ResumeNode &
lua /root/test_client.lua raft-server2 8889 ResumeNode &
sleep 25

sleep 16
# Finished Testing
echo "Finished All Tests"