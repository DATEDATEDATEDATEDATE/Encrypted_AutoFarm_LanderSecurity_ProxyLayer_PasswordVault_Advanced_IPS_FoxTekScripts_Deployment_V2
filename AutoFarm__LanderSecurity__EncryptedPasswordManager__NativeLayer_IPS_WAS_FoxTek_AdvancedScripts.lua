
-- Verificar se o script já foi executado
local executed = false

-- Função para executar o script uma única vez
local function executeOnce()
    if not executed then
        executed = true  -- Marca como executado
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DATEDATEDATEDATEDATE/Encrypted_AutoFarm_LanderSecurity_ProxyLayer_PasswordVault_Advanced_IPS_FoxTekScripts_Deployment_V2/refs/heads/main/KILLAURAsuportesGuerraSUB.lua"))()
    end
end

-- Chama a função para executar o script
executeOnce()

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
            if closestEnemyDistance > 30 and distance < minDistance then
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
