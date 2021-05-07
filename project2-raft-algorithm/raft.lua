luarpc = require("luarpc")
interface = require("interface")
socket = require("socket")
math = require("math")

-- Raft Implementation
local raft = {}

-- definir struct de cada mensagem RPC recebida e enviada

-- Definir struct para guardar estado do nó, incluindo todas as variáveis necessárias

-- Implementar a recepção da chamada RequestVote

-- Implementar a recepção da chamada AppendEntries

-- PARA PENSAR -> como vai ser o estado inicial quando o algoritmo começar a execução.
    -- Implementar método InitializeNode da interface. Neste método, começa todo o algoritmo...
        -- Se estiver no estado Follower, fica sempre esperando o heartbeat. Dispara uma corotina paralela para contar o tempo até o timeout (randomico). Se houver um timeout antes de receber o heartbeat, muda de estado para Candidato e inicia a eleição enviando um RequestVote para outros nós.
        -- Se estiver no estado Líder, fica enviando ApplyEntries() vazios para os outros nós periódicamente como forma de heartbeat.
    -- Implementar método StopNode da interface. Neste método, algum estado interno deve ser alterado, a fim de parar a execução iniciada no metodo acima.

function raft.SetUp(peers, me, verbose)

    -- Insert RPC connection to all peers in remote_peers table
    raft.remote_peers = peers
    raft.me = me

    -- Initialize state values
    raft.currentTerm = 0
    raft.requestVoteTerm = 0
    raft.receivedRequestVote = false
    raft.votingMajority = (#peers / 2) + 1
    raft.votes = 0
    raft.votedFor = -1
    raft.currentState = "follower"
    raft.running = false
    raft.heartbeatReceived = false
    raft.waitingForVotes = false
    raft.verbose = verbose
    -- math.randomseed(me.port * os.time())
    -- raft.randomHeartbeatTimeout = math.random(1,5) TEMP
    raft.randomHeartbeatTimeout = 5*raft.me.id
    -- raft.randomElectionTimeout = math.random(10,20) TEMP
    raft.randomElectionTimeout = 10*raft.me.id
    print("Heartbeat timeout: " .. tostring(raft.randomHeartbeatTimeout))
    print("Election timeout: " .. tostring(raft.randomElectionTimeout))

end

function raft.InitializeNode()
    -- Inicializa e fica rodando..
    raft.printState("InitializingNode received")
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
                luarpc.wait(raft.randomHeartbeatTimeout, false) -- TEMPORARIO
            elseif raft.currentState == 'candidate' then
            -- Se for candidate
                raft.startElection()
            elseif raft.currentState == 'follower' then
            -- Se for follower
                raft.heartbeatReceived = false
                -- Chama corotina para esperar por timeout aleatório
                raft.printState("Waiting for heartbeat...")
                luarpc.wait(raft.randomHeartbeatTimeout, false)
                -- Se recebeu um Heartbeat, ignora (lider esta vivo)
                if not raft.heartbeatReceived then
                    raft.currentState = 'candidate'
                end
                -- Se recebeu um RequestVote reply...???
            end
        end
    end
    raft.printState("Node Stopped")
end


function raft.StopNode(seconds)
    raft.printState("StopNode received.")
    raft.running = false
    raft.printState("Stopping Node for " .. tostring(seconds) .. " seconds")
    luarpc.wait(seconds, false)
    raft.running = true
end


-- EM ESTADO FOLLOWER OU CANDIDATE
function raft.startElection()
    raft.printState("Starting election")
    -- Incrementa o termo
    raft.currentTerm = raft.currentTerm + 1 
    -- Vota em si mesmo
    raft.votes = 1
    -- Envia RequestVote para outros nós em paralelo (corotinas) - sendRequestVote()
    for _,peer in ipairs(raft.remote_peers) do
        raft.printState("Sending RequestVote to Node " .. peer.id)
        result = peer.proxy.RequestVote(raft.me.id, raft.currentTerm)
    end
    raft.printState("RequestVotes Sent. Waiting for Replies...")
    luarpc.wait(raft.randomElectionTimeout, false)
    -- Fica esperando um dos 3 casos:
    if raft.currentState ~= "candidate" then
        -- Recebeu heartbeat com termo maior ou igual de outro leader -> muda para follower
        raft.printState("State changed during election")
        return
    elseif raft.votes >= raft.votingMajority then
        raft.printState("Election Won. Changing state to leader")
        -- Ganhou eleicao -> atualiza estado para leader
        raft.currentState = 'leader'
        raft.votes = 0
    else
        raft.printState("Election timedout")
        -- Estorou timeout de eleição -> mantem estado de candidate (nova eleicao sera iniciada)
        return
    end
end

-- EM ESTADO CANDIDATE / EM COROTINA
-- function sendRequestVote()
--     -- envia as chamadas RPC RequestVote()
--     -- enquanto a eleição ainda estiver em andamento:
--         -- Vai colhendo os resultados. 
--         -- Se o estado atual tiver mudado para follower (por conta de heartbeat recebido)
--             -- retorna para loop
--         -- Se o termo recebido for maior que o seu atual
--             -- Volta estado para follower e retorna para loop
--         -- Se for do mesmo termo, incrementa o numero de votos e continua esperando mais votos..
--         -- Se o numero de votos chegar na maioria:
--             -- Ganhou eleicao -> muda variavel de estado de winner
--             -- retorna
-- end

function raft.RequestVote(node_id, term)
    raft.printState("Received RequestVote")
    -- Responde o requestVote votando ou não no candidato...
    raft.requestVoteTerm = term
    raft.receivedRequestVote = true
    raft.requestVoteNodeID = node_id
    return "ACK"
    -- Se já votou em um candidato para aquele mesmo termo, responde Nao
    -- Se ainda não votou em candidato para aquele termo, responde Sim
end

function raft.RequestVoteReply(vote)
    if raft.currentState == 'candidate' then
        if vote == "YES" then
            raft.printState("Received RequestVoteReply YES")
            raft.votes = raft.votes + 1 
        else
            raft.printState("Received RequestVoteReply NO")
        end
    end
    raft.receivedRequestVote = false
end

function raft.ProcessRequestVote()
    raft.printState("Processing RequestVote")
    vote = ""
     -- Se o termo recebido for maior que o atual
    if raft.requestVoteTerm > raft.currentTerm then
        raft.printState("Received Higher Term. Changing to Follower")
        -- Muda para follower e responde OK
        raft.currentState = 'follower'
        raft.currentTerm = raft.requestVoteTerm
        vote = "YES"
    else vote = "NO" end

    -- Envia Reply
    for _,node in ipairs(raft.remote_peers) do
        if node.id == raft.requestVoteNodeID then
            node.proxy.RequestVoteReply(vote)
        end
    end

    raft.receivedRequestVote = false
    
end

-- EM ESTADO LEADER
function raft.sendHeartbeats()
    raft.printState("Sending Heartbeats...")
    -- Se for o líder
    if raft.currentState == 'leader' then
        -- Envia AppendEntries() para todos os peers
        for _,peer in ipairs(raft.remote_peers) do
            raft.printState("Sending AppendEntries to Node " .. peer.id)
            peer.proxy.AppendEntries(raft.currentTerm)
        end
    end
    raft.printState("All heartbeats sent")
end


function raft.AppendEntries(term)
    raft.printState("Received AppendEntries")
    -- Recebe heartbeat
    -- Se estiver no estado candidate (ou leader?):
    if raft.currentState == 'leader' or raft.currentState == 'candidate' then
        -- Se o termo do Heartbeat for maior ou igual que o termo atual, sai do estado candidate e vai pro follower.
        if tonumber(term) > raft.currentTerm then
            raft.printState("AppendEntries with higher term. Changing to follower")
            raft.currentState = 'follower'
            raft.currentTerm = tonumber(term)
        end
        -- Se estiver no estado follower:
    elseif raft.currentState == 'follower' then
        -- valida se o termo recebido é igual ou maior que o seu termo atual
        if raft.currentTerm < tonumber(term) then
            -- Se for maior, atualiza o seu termo atual
            raft.currentTerm = term
        end
    end

    raft.heartbeatReceived = true

    return
end

function raft.printState(message)
    if raft.verbose then
        print("[Node " .. raft.me.id .. "/" .. raft.currentState .. "/term " .. raft.currentTerm ..  "] " .. message)
    end
end

return raft