luarpc = require("luarpc")
interface = require("interface")
socket = require("socket")

-- Raft Implementation
local raft = {}

-- definir struct de cada mensagem RPC recebida e enviada

-- Definir struct para guardar estado do nó, incluindo todas as variáveis necessárias
-- Cria Objeto Raft Server
local raftNode = {}

-- Implementar a recepção da chamada RequestVote

-- Implementar a recepção da chamada AppendEntries

-- PARA PENSAR -> como vai ser o estado inicial quando o algoritmo começar a execução.
    -- Implementar método InitializeNode da interface. Neste método, começa todo o algoritmo...
        -- Se estiver no estado Follower, fica sempre esperando o heartbeat. Dispara uma corotina paralela para contar o tempo até o timeout (randomico). Se houver um timeout antes de receber o heartbeat, muda de estado para Candidato e inicia a eleição enviando um RequestVote para outros nós.
        -- Se estiver no estado Líder, fica enviando ApplyEntries() vazios para os outros nós periódicamente como forma de heartbeat.
    -- Implementar método StopNode da interface. Neste método, algum estado interno deve ser alterado, a fim de parar a execução iniciada no metodo acima.

function raft.SetUp(peers, me)

    -- Insert RPC connection to all peers in remote_peers table
    raftNode.remote_peers = peers
    raftNode.me = me

    -- Initialize state values
    raftNode.currentTerm = 0
    raftNode.votedFor = -1
    raftNode.currentState = "follower"
    raftNode.running = false
end

function raft.InitializeNode()
    -- Inicializa e fica rodando..
    print("[" .. raftNode.me.host .. "/" .. raftNode.currentState .. "] InitializingNode received")
    raftNode.running = true
    while raftNode.running do
        print("[" .. raftNode.me.host .. "/" .. raftNode.currentState .. "] Node Running...")
        -- Verifica estado atual. 
        -- Se for leader
            -- fica mandando heartbeats / sendHeartbeats()
        -- Se for follower
            -- Chama corotina para esperar por timeout aleatório
            -- Se recebeu um Heartbeat, ignora (lider esta vivo)
            -- Se recebeu um RequestVote reply...???
        -- Se for candidate
            -- startElection()
        socket.sleep(5)
    end
    print("[" .. raftNode.me.host .. "/" .. raftNode.currentState .. "] Node Stopped")
end


function raft.StopNode()
    print("[" .. raftNode.me.host .. "/" .. raftNode.currentState .. "] StopNode received")
    raftNode.running = false
    -- Continua com os mesmos estados
    -- Só para de receber os Heartbeats
end

-- EM COROTINA
function checkHeartbeatTimeout()
    -- Espera o tempo do timeout
    -- Se timeout estourar, e não tiver recebido heartbeat -> muda para candidadate
end

-- EM ESTADO FOLLOWER OU CANDIDATE
function startElection()
    -- Muda de estado para candidato
    -- Incrementa o termo
    -- Vota em si mesmo
    -- Envia RequestVote para outros nós em paralelo (corotinas) - sendRequestVote()
    -- Fica esperando um dos 3 casos:
        -- Ganhou eleicao (variavel de estado) -> atualiza estado para leader
        -- Recebeu heartbeat com termo maior ou igual de outro leader -> muda para follower
        -- Estorou timeout de eleição -> mantem estado de candidate (nova eleicao sera iniciada)
    -- quando bater em um dos 3 casos, retorna para loop
end

-- EM ESTADO CANDIDATE / EM COROTINA
function sendRequestVote()
    -- envia as chamadas RPC RequestVote()
    -- enquanto a eleição ainda estiver em andamento:
        -- Vai colhendo os resultados. 
        -- Se o estado atual tiver mudado para follower (por conta de heartbeat recebido)
            -- retorna para loop
        -- Se o termo recebido for maior que o seu atual
            -- Volta estado para follower e retorna para loop
        -- Se for do mesmo termo, incrementa o numero de votos e continua esperando mais votos..
        -- Se o numero de votos chegar na maioria:
            -- Ganhou eleicao -> muda variavel de estado de winner
            -- retorna
end

function RequestVote()
    -- Responde o requestVote votando ou não no candidato...
    -- Se já votou em um candidato para aquele mesmo termo, responde Nao
    -- Se ainda não votou em candidato para aquele termo, responde Sim
end

-- EM ESTADO LEADER
function sendHeartbeats()
    -- Se for o líder
        -- Envia AppendEntries() para todos os peers
        -- Espera as respostas. Se todas as respostas forem sucesso, continua
end


function AppendEntries()
    -- Recebe heartbeat
    -- Se estiver no estado candidate (ou leader?):
        -- Se o termo do Heartbeat for maior ou igual que o termo atual, sai do estado candidate e vai pro follower. (sinaliza em alguma variavel?)
        -- Senao, rejeita o heartbeat e continua como candidate.
    -- Se estiver no estado follower:
        -- valida se o termo recebido é igual ou maior que o seu termo atual
        -- Se for maior, atualiza o seu termo atual
        -- Responde OK
end

return raft