-- Variável de controle no começo
local jogadorMorto = false

-- Função para matar o jogador uma vez
function matarJogador(jogador)
    if not jogadorMorto then
        -- Mata o jogador
        jogador:TakeDamage(jogador.Health)  -- Diminui a saúde do jogador até 0
        jogadorMorto = true  -- Marca que o jogador foi morto
        print(jogador.Name .. " foi morto!")
    else
        print("inicialização de farm iniciada v2")
    end
end

-- Conectando o evento quando um jogador entra no jogo
game.Players.PlayerAdded:Connect(function(player)
    -- Matar o jogador quando ele entrar no jogo
    matarJogador(player)
end)

-- O resto do seu código vai aqui, abaixo

-- Variáveis iniciais
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local backpack = player.Backpack
local afkPosition = Vector3.new(6, -20, -4)

-- Função para desativar colisões e aplicar invisibilidade
local function disableCollisionsAndMakeInvisible(char)
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Transparency = 1
        end
    end
end

-- Função para restaurar colisões e visibilidade
local function enableCollisionsAndRestoreVisual(char)
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
            part.Transparency = 0
        end
    end
end

-- Função para desativar colisões globalmente
local function disableAllCollisionsInGame()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = false
        end
    end
end

-- Função para pegar a parte inferior do modelo
local function getModelBottom(model)
    local minPos = Vector3.new(math.huge, math.huge, math.huge)
    for _, part in pairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            minPos = Vector3.new(math.min(minPos.X, part.Position.X), math.min(minPos.Y, part.Position.Y), math.min(minPos.Z, part.Position.Z))
        end
    end
    return minPos
end

-- Função para encontrar a terra mais próxima
local function findClosestLand()
    local closestLand = nil
    local minDistance = math.huge
    local rootPosition = character:WaitForChild("HumanoidRootPart").Position -- Garantir que o HumanoidRootPart exista

    -- Cache de Workspace.Dirts
    local dirtParts = Workspace.Dirts:GetChildren()
    
    for _, item in ipairs(dirtParts) do
        if item:IsA("BasePart") or item:IsA("Model") then
            local landBottom = item:IsA("Model") and getModelBottom(item) or item.Position
            local distance = (rootPosition - landBottom).Magnitude

            if distance < minDistance then
                closestLand = item
                minDistance = distance
            end
        end
    end
    return closestLand
end

-- Função para encontrar a terra mais próxima, evitando inimigos
local function findClosestLandAvoidingEnemies()
    local closestLand = nil
    local minDistance = math.huge
    local rootPosition = character:WaitForChild("HumanoidRootPart").Position -- Garantir que o HumanoidRootPart exista

    -- Cache de Workspace.Dirts
    local dirtParts = Workspace.Dirts:GetChildren()

    -- Filtragem de inimigos
    local enemies = {}
    for _, enemy in ipairs(Players:GetPlayers()) do
        if enemy.Team ~= player.Team and enemy.Character then
            table.insert(enemies, enemy)
        end
    end

    for _, item in ipairs(dirtParts) do
        if item:IsA("BasePart") or item:IsA("Model") then
            local landBottom = item:IsA("Model") and getModelBottom(item) or item.Position
            local distance = (rootPosition - landBottom).Magnitude
            local closestEnemyDistance = math.huge

            -- Verificar a distância do inimigo mais próximo
            for _, enemy in ipairs(enemies) do
                local enemyCharacter = enemy.Character
                if enemyCharacter and enemyCharacter:FindFirstChild("HumanoidRootPart") then
                    local enemyDistance = (enemyCharacter.HumanoidRootPart.Position - landBottom).Magnitude
                    closestEnemyDistance = math.min(closestEnemyDistance, enemyDistance)
                end
            end

            -- Só escolher a terra se não houver inimigos próximos
            if closestEnemyDistance > 1 and distance < minDistance then
                closestLand = item
                minDistance = distance
            end
        end
    end
    return closestLand
end

-- Função para teletransportar o personagem
local function teleportTo(position)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CanCollide = false
    humanoidRootPart.CFrame = CFrame.new(position)
end

-- Função para manter a posição do personagem
local function maintainPosition(position)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local bodyVelocity = humanoidRootPart:FindFirstChildOfClass("BodyVelocity") or Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = humanoidRootPart
    humanoidRootPart.CFrame = CFrame.new(position)
end

-- Função para equipar item do slot específico
local function equipItemFromSlot(slot)
    local player = game.Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    local function equipItem()
        local character = player.Character or player.CharacterAdded:Wait()
        local item = backpack:GetChildren()[slot]
        if item and item:IsA("Tool") and item.Parent ~= character then
            item.Parent = character
        end
    end
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("HumanoidRootPart")
        equipItem()
    end)
    equipItem()
end

-- Função principal para executar a escavação
local function performDiggingProcedure()
    disableCollisionsAndMakeInvisible(character)
    disableAllCollisionsInGame()
    local land = findClosestLandAvoidingEnemies()
    if land then
        local landBottom = land:IsA("Model") and getModelBottom(land) or land.Position
        teleportTo(landBottom)
        equipItemFromSlot(3)
        while land.Parent do
            maintainPosition(landBottom)
            wait(0.1)  -- Ajustado o intervalo de espera para reduzir a carga
        end
        performDiggingProcedure()
    else
        -- Quando não encontrar terra, teletransportar para a posição AFK e manter fixa
        teleportTo(afkPosition)
        maintainPosition(afkPosition)
        while not findClosestLandAvoidingEnemies() do
            wait(0.5)  -- Intervalo mais longo para não sobrecarregar o sistema
        end
        performDiggingProcedure()
    end
end

-- Função para reiniciar o processo após a morte do personagem
local function onCharacterDied()
    enableCollisionsAndRestoreVisual(character)
    wait(1)
    equipItemFromSlot(3)
    performDiggingProcedure()
    -- Retornar à posição fixa após a morte
    teleportTo(afkPosition)
    maintainPosition(afkPosition)
end

-- Conectar eventos e iniciar o processo
local function restartProcess()
    player.CharacterAdded:Connect(function(char)
        character = char
        humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(onCharacterDied)
        equipItemFromSlot(3)
        performDiggingProcedure()
    end)
end

-- Iniciar escavação
restartProcess()

-- Resetar configurações anteriores, se existirem
local connections = getgenv().configs and getgenv().configs.connection
if connections then
    local Disable = configs.Disable
    for _, v in pairs(connections) do
        if v and typeof(v) == "RBXScriptConnection" then
            v:Disconnect()
        end
    end
    if Disable then
        Disable:Fire()
        Disable:Destroy()
    end
    table.clear(getgenv().configs)
end

-- Nova configuração
local Disable = Instance.new("BindableEvent")
getgenv().configs = {
    connections = {},
    Disable = Disable,
    Size = Vector3.new(50, 50, 50),  -- Aumentar o raio de detecção
    DeathCheck = true,
    Targeting = "Distance",  -- Priorizar pela distância
    IgnoreAllies = true,     -- Ignorar aliados ou mesma equipe
    AggressiveAttack = true  -- Agressividade no ataque
}

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local lp = Players.LocalPlayer
local Run = true
local Ignorelist = OverlapParams.new()
Ignorelist.FilterType = Enum.RaycastFilterType.Include

-- Funções auxiliares
local function getchar(plr)
    local plr = plr or lp
    return plr and plr.Character
end

local function gethumanoid(plr)
    local char = plr:IsA("Model") and plr or getchar(plr)
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function IsAlive(Humanoid)
    return Humanoid and Humanoid.Health > 0
end

local function GetTouchInterest(Tool)
    return Tool and Tool:FindFirstChildWhichIsA("TouchTransmitter", true)
end

local function GetCharacters(LocalPlayerChar)
    local Characters = {}
    for _, v in pairs(Players:GetPlayers()) do
        if v.Character and v.Character ~= LocalPlayerChar then
            -- Ignorar aliados ou mesma equipe, se configurado
            if not getgenv().configs.IgnoreAllies or v.Team ~= lp.Team then
                table.insert(Characters, v.Character)
            end
        end
    end
    return Characters
end

local function Attack(Tool, TouchPart, ToTouch)
    if Tool and Tool:IsDescendantOf(workspace) then
        Tool:Activate()
        firetouchinterest(TouchPart, ToTouch, 1)
        firetouchinterest(TouchPart, ToTouch, 0)
    end
end

local function GetPriorityTarget(characters, LocalPlayerChar)
    local target = nil
    local minValue = math.huge

    for _, enemy in ipairs(characters) do
        if enemy:FindFirstChild("HumanoidRootPart") then
            local humanoid = gethumanoid(enemy)
            if IsAlive(humanoid) then
                local distancia = (LocalPlayerChar.HumanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
                local value = getgenv().configs.Targeting == "Distance" and distancia or humanoid.Health

                if value < minValue then
                    minValue = value
                    target = enemy
                end
            end
        end
    end

    return target
end

-- Conexão para desativar Kill Aura
table.insert(getgenv().configs.connections, Disable.Event:Connect(function()
    Run = false
end))

-- Configurações principais
local raioDeDeteccao = 60  -- Aumentar o raio de detecção
local killAuraTempo = 0.02  -- Reduzir o tempo entre ataques

-- Função para resetar variáveis e estados do script
local function ResetScript()
    -- Resetando a variável Run para true
    Run = true
    
    -- Resetando as configurações novamente
    getgenv().configs = {
        connections = {},
        Disable = Disable,
        Size = Vector3.new(50, 50, 50),  -- Aumentar o raio de detecção
        DeathCheck = true,
        Targeting = "Distance",  -- Priorizar pela distância
        IgnoreAllies = true,     -- Ignorar aliados ou mesma equipe
        AggressiveAttack = true  -- Agressividade no ataque
    }

    -- Reconfigura a parte de desativação
    local Disable = Instance.new("BindableEvent")
    table.insert(getgenv().configs.connections, Disable.Event:Connect(function()
        Run = false
    end))

    -- Continuar com o loop principal após reiniciar
    spawn(ResetScript)  -- Reinicia o script em 5 minutos (ou o intervalo desejado)
end

-- Iniciar o reset automático
spawn(ResetScript)

-- Loop principal
while Run do
    local char = getchar()
    if char and IsAlive(gethumanoid(char)) then
        local Characters = GetCharacters(char)
        local targets = {}

        -- Identificar todos os inimigos dentro do raio de detecção
        for _, enemy in ipairs(Characters) do
            if enemy and enemy:FindFirstChild("HumanoidRootPart") then
                local distancia = (char.HumanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude

                if distancia <= raioDeDeteccao then
                    table.insert(targets, enemy)
                end
            end
        end

        -- Equipando o segundo ou terceiro Tool, se disponível
        local inventory = lp.Backpack:GetChildren()
        local itemEquipped = inventory[2] or inventory[3]  -- Equipar o 2º ou 3º item
        if itemEquipped and itemEquipped:IsA("Tool") then
            itemEquipped.Parent = char
        end

        -- Ataque a todos os inimigos dentro do raio de detecção
        for _, target in ipairs(targets) do
            local Tool = char:FindFirstChildWhichIsA("Tool")
            if Tool then
                local TouchInterest = GetTouchInterest(Tool)
                if TouchInterest then
                    local TouchPart = TouchInterest.Parent
                    Ignorelist.FilterDescendantsInstances = targets

                    -- Realizar o ataque a todos os inimigos
                    local InstancesInBox = workspace:GetPartBoundsInBox(TouchPart.CFrame, TouchPart.Size + getgenv().configs.Size, Ignorelist)
                    for _, v in ipairs(InstancesInBox) do
                        local Character = v:FindFirstAncestorWhichIsA("Model")
                        if Character and table.find(targets, Character) then
                            Attack(Tool, TouchPart, v)
                        end
                    end
                end
            end
        end
    end
    RunService.Heartbeat:Wait(killAuraTempo)
end
