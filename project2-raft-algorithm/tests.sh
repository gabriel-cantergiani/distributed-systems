
echo "Starting Tests..."

echo "Testing InitializeNode 1"
lua /root/test_client.lua 1 InitializeNode &
echo "Testing InitializeNode 2"
lua /root/test_client.lua 2 InitializeNode &
echo "Testing InitializeNode 3"
lua /root/test_client.lua 3 InitializeNode &
echo "Testing InitializeNode 4"
lua /root/test_client.lua 4 InitializeNode &
echo "Testing InitializeNode 5"
lua /root/test_client.lua 5 InitializeNode &

echo "Waiting 42 seconds..."
sleep 42

echo "Testing StopNode 1"
lua /root/test_client.lua 1 StopNode &
echo "Waiting 35 seconds..."
sleep 35

echo "Testing ResumeNode 1"
lua /root/test_client.lua 1 ResumeNode &
echo "Waiting 35 seconds..."
sleep 35

echo "Testing PartitionNode 1"
lua /root/test_client.lua 1 PartitionNode &
echo "Waiting 35 seconds..."
sleep 35

echo "Testing ResumeNode 1"
lua /root/test_client.lua 1 ResumeNode &
echo "Waiting 15 seconds..."
sleep 15

echo "Testing StopNode 2"
lua /root/test_client.lua 2 StopNode &
echo "Waiting 35 seconds..."
sleep 35

echo "Testing ResumeNode 2"
lua /root/test_client.lua 2 ResumeNode &
echo "Waiting 15 seconds..."
sleep 15

echo "Testing StopNode 3"
lua /root/test_client.lua 3 StopNode &
echo "Waiting 42 seconds..."
sleep 42

echo "Testing ResumeNode 3"
lua /root/test_client.lua 3 ResumeNode &
echo "Waiting 15 seconds..."
sleep 15

echo "Testing StopNode 4"
lua /root/test_client.lua 4 StopNode &
echo "Waiting 42 seconds..."
sleep 42

echo "Testing ResumeNode 4"
lua /root/test_client.lua 4 ResumeNode &
echo "Waiting 15 seconds..."
sleep 15

echo "Testing StopNode 5"
lua /root/test_client.lua 5 StopNode &
echo "Waiting 42 seconds..."
sleep 42

echo "Testing ResumeNode 5"
lua /root/test_client.lua 5 ResumeNode &
echo "Waiting 15 seconds..."
sleep 15

echo "Testing Multiple StopNodes (1 and 2)"
lua /root/test_client.lua 1 StopNode &
lua /root/test_client.lua 2 StopNode &
echo "Waiting 42 seconds..."
sleep 42

echo "Testing Multiple ResumeNodes (1 and 2)"
lua /root/test_client.lua 1 ResumeNode &
lua /root/test_client.lua 2 ResumeNode &
echo "Waiting 15 seconds..."
sleep 15

echo "Testing Multiple StopNodes (2, 3 and 4)"
lua /root/test_client.lua 2 StopNode &
lua /root/test_client.lua 3 StopNode &
lua /root/test_client.lua 4 StopNode &
echo "Waiting 42 seconds..."
sleep 42

echo "Testing Multiple ResumeNodes (2, 3 and 4)"
lua /root/test_client.lua 2 ResumeNode &
lua /root/test_client.lua 3 ResumeNode &
lua /root/test_client.lua 4 ResumeNode &
echo "Waiting 15 seconds..."
sleep 15

# Finished Testing
echo "Finished All Tests"