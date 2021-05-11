
echo "Starting Tests..."

echo "Testing InitializeNode 1"
lua /root/test_client.lua raft-server1 8888 InitializeNode &
echo "Testing InitializeNode 2"
lua /root/test_client.lua raft-server2 8889 InitializeNode &
echo "Testing InitializeNode 3"
lua /root/test_client.lua raft-server3 9000 InitializeNode &
echo "Testing InitializeNode 4"
lua /root/test_client.lua raft-server4 9001 InitializeNode &
sleep 42

echo "Testing StopNode 1"
lua /root/test_client.lua raft-server1 8888 StopNode &
sleep 42

echo "Testing ResumeNode 1"
lua /root/test_client.lua raft-server1 8888 ResumeNode &
sleep 15

echo "Testing StopNode 2"
lua /root/test_client.lua raft-server2 8889 StopNode &
sleep 42

echo "Testing ResumeNode 2"
lua /root/test_client.lua raft-server2 8889 ResumeNode &
sleep 15

echo "Testing StopNode 3"
lua /root/test_client.lua raft-server3 9000 StopNode &
sleep 42

echo "Testing ResumeNode 3"
lua /root/test_client.lua raft-server3 9000 ResumeNode &
sleep 15

echo "Testing StopNode 4"
lua /root/test_client.lua raft-server4 9001 StopNode &
sleep 42

echo "Testing ResumeNode 4"
lua /root/test_client.lua raft-server4 9001 ResumeNode &
sleep 15

echo "Testing Multiple StopNodes (1 and 2)"
lua /root/test_client.lua raft-server1 8888 StopNode &
lua /root/test_client.lua raft-server2 8889 StopNode &
sleep 42

echo "Testing Multiple ResumeNodes (1 and 2)"
lua /root/test_client.lua raft-server1 8888 ResumeNode &
lua /root/test_client.lua raft-server2 8889 ResumeNode &
sleep 15

echo "Testing Multiple StopNodes (2, 3 and 4)"
lua /root/test_client.lua raft-server2 8889 StopNode &
lua /root/test_client.lua raft-server3 9000 StopNode &
lua /root/test_client.lua raft-server4 9001 StopNode &
sleep 42

echo "Testing Multiple ResumeNodes (2, 3 and 4)"
lua /root/test_client.lua raft-server2 8889 ResumeNode &
lua /root/test_client.lua raft-server3 9000 ResumeNode &
lua /root/test_client.lua raft-server4 9001 ResumeNode &
sleep 15

# Finished Testing
echo "Finished All Tests"