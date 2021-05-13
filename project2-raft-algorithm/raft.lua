luarpc = require("luarpc")
interface = require("interface")
socket = require("socket")
math = require("math")
config = require("config")

-- Raft Implementation
local raft = {}

-- SetUp
function raft.SetUp(peers, me, verbose)

    -- Nodes information variables
    raft.remote_peers = peers
    raft.me = me
    if config.fileOutputEnabled then
        raft.outputFile = io.open(config.fileOutputPath, "a")
        io.output(raft.outputFile)
    end

    -- Basic State Variables
    raft.running = false
    raft.isPartitioned = false
    raft.currentState = "follower"
    raft.verbose = verbose

    -- Election State Variables
    raft.currentTerm = 0
    raft.requestVoteTerm = 0
    raft.receivedRequestVote = false
    raft.votingMajority = (#peers / 2) + 1
    raft.votes = 0
    raft.votedFor = nil
    raft.waitingForVotes = false
    raft.peersToRetryRequestVote = {}
    
    -- Timeout related variables
    raft.lastHeartbeatTimestamp = 0
    math.randomseed(me.port * os.time())
    raft.randomElectionTimeout = math.random(config.electionTimeoutMin, config.electionTimeoutMax)
    raft.heartbeatFrequency = config.heartbeatFrequency
    raft.electionStartTimestamp = nil
    raft.raftStartTimestamp = os.time()
    print("Heartbeat timeout: " .. tostring(raft.randomElectionTimeout))
end

-- RPC METHOD
function raft.InitializeNode()
    -- Inicializa e fica rodando..
    raft.printState("InitializingNode received")
    raft.lastHeartbeatTimestamp = os.time()
    raft.running = true
    while true do
        if raft.running then
            raft.printState("Node Running...")
            
            if raft.receivedRequestVote then
                raft.ProcessRequestVote()
            end
            
            -- Verifica estado atual.
            if raft.currentState == 'leader' then
            -- Se for leader
                raft.sendHeartbeats()
            elseif raft.currentState == 'candidate' then
            -- Se for candidate
                if raft.waitingForVotes then
                    raft.processReceivedVotes()
                else
                    raft.startElection()
                end
                -- Espera os votos chegarem
            elseif raft.currentState == 'follower' then
            -- Se for follower
                raft.printState("Waiting for heartbeat...")
                if raft.running then
                    -- Se recebeu um Heartbeat, ignora (lider esta vivo)
                    if (os.time() - raft.lastHeartbeatTimestamp) > raft.randomElectionTimeout then
                        raft.printState("No HeartBeat received within ElectionTimeout. Changing state do candidate")
                        raft.currentState = 'candidate'
                    end
                end
            end
        end
        luarpc.wait(raft.heartbeatFrequency, false)
    end
    raft.printState("Node Stopped")
end

-- RPC METHOD
function raft.PartitionNode()
    raft.printState("PartitionNode received")
    raft.isPartitioned = true
    raft.running = true
end

-- RPC METHOD
function raft.StopNode()
    raft.printState("StopNode received.")
    raft.heartbeatDue = os.time() - raft.lastHeartbeatTimestamp
    raft.isPartitioned = true
    raft.running = false
end

-- RPC METHOD
function raft.ResumeNode()
    raft.printState("ResumeNode received.")
    raft.lastHeartbeatTimestamp = os.time() - raft.heartbeatDue
    raft.isPartitioned = false
    raft.running = true
end


-- PRIVATE
function raft.startElection()
    raft.printState("Starting election")
    -- Incrementa o termo
    raft.currentTerm = raft.currentTerm + 1 
    -- Vota em si mesmo
    raft.votes = 1
    raft.votedFor = raft.me.id
    raft.peersToRetryRequestVote = {}
    -- Envia RequestVote para outros nós
    for _,peer in ipairs(raft.remote_peers) do
        if raft.isPartitioned then
            table.insert(raft.peersToRetryRequestVote, peer)
        else
            raft.printState("Sending RequestVote to Node " .. peer.id)
            result = peer.proxy.RequestVote(raft.me.id, raft.currentTerm)
            if result == "NOT ACK" then
                table.insert(raft.peersToRetryRequestVote, peer)
            end
        end
    end
    raft.waitingForVotes = true
    raft.electionTimeoutLimit = math.random(config.electionTimeLimitMin, config.electionTimeLimitMax)
    raft.electionStartTimestamp = os.time()
    raft.printState("RequestVotes Sent. Waiting for Replies... (ElectionTimeoutLimit = " .. raft.electionTimeoutLimit .. ")")
end

-- PRIVATE
function raft.processReceivedVotes()
    raft.printState("Processing Received Votes")
    -- Fica esperando um dos 3 casos:
    if raft.currentState ~= "candidate" then
        -- Recebeu heartbeat com termo maior ou igual de outro leader -> muda para follower
        raft.printState("State changed during election")
        raft.waitingForVotes = false
    elseif raft.votes >= raft.votingMajority then
        raft.printState("Election Won. Changing state to leader")
        -- Ganhou eleicao -> atualiza estado para leader
        raft.currentState = 'leader'
        raft.votes = 0
        raft.waitingForVotes = false
    elseif (os.time() - raft.electionStartTimestamp) > raft.electionTimeoutLimit then
        raft.printState("Election timed out")
        raft.votes = 0
        raft.waitingForVotes = false
    else
        -- Tenta novamente envio do RequestVote para nos que nao receberam
        for position,peer in ipairs(raft.peersToRetryRequestVote) do
            if not raft.isPartitioned then
                raft.printState("Retrying RequestVote to Node " .. peer.id)
                result = peer.proxy.RequestVote(raft.me.id, raft.currentTerm)
                if result == "ACK" then
                    raft.printState("RequestVote ACK received from Node " .. peer.id)
                    table.remove(raft.peersToRetryRequestVote, position)
                end
            end
        end 
    end
end

-- RPC METHOD
function raft.RequestVote(node_id, term)
    -- Nao faz nada se estiver "parado"
    if not raft.running or raft.isPartitioned then return "NOT ACK" end

    raft.printState("Received RequestVote")
    -- Responde o requestVote votando ou não no candidato...
    if not raft.receivedRequestVote then
        raft.requestVoteTerm = term
        raft.receivedRequestVote = true
        raft.requestVoteNodeID = node_id
    end
    return "ACK"
end

-- RPC METHOD
function raft.RequestVoteReply(vote)
    -- Nao faz nada se estiver "parado"
    if not raft.running or raft.isPartitioned then return end

    if raft.currentState == 'candidate' then
        if vote == "YES" then
            raft.printState("Received RequestVoteReply YES")
            raft.votes = raft.votes + 1
        else
            raft.printState("Received RequestVoteReply NO")
        end
    end
end

-- PRIVATE
function raft.ProcessRequestVote()
    raft.printState("Processing RequestVote")
    vote = "NO"
     -- Se o termo recebido for maior que o atual
    if (raft.requestVoteTerm > raft.currentTerm) or (raft.requestVoteTerm == raft.currentTermand and raft.votedFor == nil) then
            raft.printState("Received Higher Term from Node " .. raft.requestVoteNodeID ..  ". Changing to Follower")
            -- Muda para follower e responde OK
            raft.currentState = 'follower'
            raft.currentTerm = raft.requestVoteTerm
            raft.votedFor = raft.requestVoteNodeID
            raft.lastHeartbeatTimestamp = os.time()
            vote = "YES"
    end

    -- Envia Reply
    for _,node in ipairs(raft.remote_peers) do
        if node.id == raft.requestVoteNodeID and not raft.isPartitioned then
            node.proxy.RequestVoteReply(vote)
        end
    end

    raft.receivedRequestVote = false
    
end

-- PRIVATE
function raft.sendHeartbeats()
    raft.printState("Sending Heartbeats...")
    -- Se for o líder
    if raft.currentState == 'leader' and not raft.isPartitioned then
        -- Envia AppendEntries() para todos os peers
        for _,peer in ipairs(raft.remote_peers) do
            raft.printState("Sending AppendEntries to Node " .. peer.id)
            peer.proxy.AppendEntries(raft.currentTerm)
        end
    end
    raft.printState("All heartbeats sent")
end

-- RPC METHOD
function raft.AppendEntries(term)
    -- Nao faz nada se estiver "parado"
    if not raft.running or raft.isPartitioned then return end

    raft.printState("Received AppendEntries")
    -- Recebe heartbeat
    -- Se estiver no estado candidate (ou leader?):
    if raft.currentState == 'leader' or raft.currentState == 'candidate' then
        -- Se o termo do Heartbeat for maior ou igual que o termo atual, sai do estado candidate e vai pro follower.
        if (tonumber(term) > raft.currentTerm and raft.currentState == 'leader') or (tonumber(term) >= raft.currentTerm and raft.currentState == 'candidate') then
            raft.printState("AppendEntries with higher or equal term. Changing to follower")
            raft.currentState = 'follower'
            raft.currentTerm = tonumber(term)
            raft.waitingForVotes = false
            raft.votedFor = nil
            raft.lastHeartbeatTimestamp = os.time()
        end
        -- Se estiver no estado follower:
    elseif raft.currentState == 'follower' then
        -- valida se o termo recebido é igual ou maior que o seu termo atual
        if raft.currentTerm < tonumber(term) then
            -- Se for maior, atualiza o seu termo atual
            raft.currentTerm = term
            raft.votedFor = nil
        end
    end

    raft.lastHeartbeatTimestamp = os.time()

    return
end

-- PRIVATE
function raft.printState(message)
    log = "[" .. (os.time() - raft.raftStartTimestamp) .. "s][Node " .. raft.me.id .. "/" .. raft.currentState .. "/term " .. raft.currentTerm ..  "] " .. message
    if raft.verbose then
        print(log)
    end
    if config.fileOutputEnabled then
        io.write(log)
    end
end

-- PRIVATE
function raft.Healthcheck()
    return
end

return raft