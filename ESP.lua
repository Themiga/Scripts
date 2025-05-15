-- Carrega Rayfield dinamicamente via loadstring
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Configurações iniciais
local ESPEnabled = false
local ShowName = true
local ShowDistance = true
local ShowChams = false
local UseTeamColor = false

local NameColor = Color3.fromRGB(255, 255, 255)
local DistanceColor = Color3.fromRGB(200, 255, 200)
local ChamsColor = Color3.fromRGB(0, 255, 255)

local ESPObjects = {}

local function getPlayerColor(player)
    if UseTeamColor and player.TeamColor then
        -- Garante que player.TeamColor.Color existe (Color3)
        return player.TeamColor.Color
    end
    return nil
end

-- Função para criar o Billboard acima da cabeça
local function CreateBillboard(player)
    if player == Players.LocalPlayer then return end
    if ESPObjects[player] then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end

    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "ESP_Billboard"
    Billboard.Adornee = player.Character.Head
    Billboard.Size = UDim2.new(0, 120, 0, 36)
    Billboard.StudsOffset = Vector3.new(0, 1.8, 0)
    Billboard.AlwaysOnTop = true

    local Stack = Instance.new("Frame")
    Stack.Name = "Stack"
    Stack.Parent = Billboard
    Stack.BackgroundTransparency = 1
    Stack.Size = UDim2.new(1, 0, 1, 0)

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "NameLabel"
    NameLabel.Parent = Stack
    NameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    NameLabel.Position = UDim2.new(0, 0, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = player.Name
    NameLabel.TextColor3 = NameColor
    NameLabel.TextStrokeTransparency = 0.5
    NameLabel.Font = Enum.Font.SourceSansBold
    NameLabel.TextScaled = true

    local DistanceLabel = Instance.new("TextLabel")
    DistanceLabel.Name = "DistanceLabel"
    DistanceLabel.Parent = Stack
    DistanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    DistanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    DistanceLabel.BackgroundTransparency = 1
    DistanceLabel.Text = ""
    DistanceLabel.TextColor3 = DistanceColor
    DistanceLabel.TextStrokeTransparency = 0.5
    DistanceLabel.Font = Enum.Font.SourceSans
    DistanceLabel.TextScaled = true

    Billboard.Parent = player.Character.Head
    ESPObjects[player] = Billboard
end

local function RemoveBillboard(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

-- Chams (Highlight) - Criação/Atualização
local function SetChams(player)
    if player == Players.LocalPlayer then return end
    if not player.Character then return end

    local highlight = player.Character:FindFirstChild("ESPChams")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ESPChams"
        highlight.Adornee = player.Character
        highlight.Parent = player.Character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end

    local useTeam = getPlayerColor(player)
    highlight.FillColor = useTeam or ChamsColor
    highlight.OutlineColor = useTeam or ChamsColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
end

local function RemoveChams(player)
    if player.Character and player.Character:FindFirstChild("ESPChams") then
        player.Character.ESPChams:Destroy()
    end
end

-- Atualização por tick
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            if ESPEnabled then
                -- Billboard
                if ShowName or ShowDistance then
                    CreateBillboard(player)
                    local bill = ESPObjects[player]
                    if bill then
                        local stack = bill:FindFirstChild("Stack")
                        if stack then
                            -- Nome
                            local nameLabel = stack:FindFirstChild("NameLabel")
                            if nameLabel then
                                nameLabel.Visible = ShowName
                                local useTeam = getPlayerColor(player)
                                nameLabel.TextColor3 = useTeam or NameColor
                                nameLabel.Text = player.Name
                            end
                            -- Distância
                            local distLabel = stack:FindFirstChild("DistanceLabel")
                            if distLabel then
                                distLabel.Visible = ShowDistance
                                if ShowDistance and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    local dist = math.floor((Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude)
                                    distLabel.Text = dist .. "m"
                                else
                                    distLabel.Text = ""
                                end
                                local useTeam = getPlayerColor(player)
                                distLabel.TextColor3 = useTeam or DistanceColor
                            end
                        end
                    end
                else
                    RemoveBillboard(player)
                end

                -- Chams (sempre atualiza cor se ativo)
                if ShowChams then
                    SetChams(player)
                else
                    RemoveChams(player)
                end
            else
                RemoveBillboard(player)
                RemoveChams(player)
            end
        end
    end
end

-- Eventos de players
local function onCharacterAdded(player, character)
    -- Aguarda partes essenciais
    local function tryInit()
        if character and character:FindFirstChild("Head") then
            if ESPEnabled and (ShowName or ShowDistance) then
                CreateBillboard(player)
            end
            if ESPEnabled and ShowChams then
                SetChams(player)
            end
            return true
        end
        return false
    end

    -- Tenta várias vezes até conseguir
    local tries = 0
    while tries < 15 and not tryInit() do
        tries = tries + 1
        task.wait(0.15)
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
end)
Players.PlayerRemoving:Connect(function(player)
    RemoveBillboard(player)
    RemoveChams(player)
end)

-- Atualização contínua
RunService.RenderStepped:Connect(UpdateESP)

-- Atualiza todos ao trocar cores/opções
local function UpdateAllChamsAndBillboards()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            if ESPEnabled then
                if ShowChams then
                    SetChams(player)
                end
                if ShowName or ShowDistance then
                    local bill = ESPObjects[player]
                    if bill then
                        local stack = bill:FindFirstChild("Stack")
                        if stack then
                            local nameLabel = stack:FindFirstChild("NameLabel")
                            if nameLabel then
                                nameLabel.TextColor3 = getPlayerColor(player) or NameColor
                            end
                            local distLabel = stack:FindFirstChild("DistanceLabel")
                            if distLabel then
                                distLabel.TextColor3 = getPlayerColor(player) or DistanceColor
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Menu Rayfield
local Window = Rayfield:CreateWindow({
    Name = "ESP Desenvolvido por Themiga",
    LoadingTitle = "Rayfield ESP",
    LoadingSubtitle = "by Themiga",
    ConfigurationSaving = {
       Enabled = false,
    }
})

local mainTab = Window:CreateTab("ESP", 4483362458)
mainTab:CreateSection("Opções do ESP")

mainTab:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = ESPEnabled,
    Callback = function(val)
        ESPEnabled = val
    end,
})

mainTab:CreateToggle({
    Name = "Mostrar nome",
    CurrentValue = ShowName,
    Callback = function(val)
        ShowName = val
    end,
})

mainTab:CreateToggle({
    Name = "Mostrar distância",
    CurrentValue = ShowDistance,
    Callback = function(val)
        ShowDistance = val
    end,
})

mainTab:CreateToggle({
    Name = "Glow/Chams",
    CurrentValue = ShowChams,
    Callback = function(val)
        ShowChams = val
    end,
})

mainTab:CreateSection("Personalização de Cores")

mainTab:CreateToggle({
    Name = "Team Color",
    CurrentValue = UseTeamColor,
    Callback = function(val)
        UseTeamColor = val
        UpdateAllChamsAndBillboards()
    end,
})

mainTab:CreateColorPicker({
    Name = "Cor do Nome",
    Color = NameColor,
    Callback = function(color)
        NameColor = color
        if not UseTeamColor then UpdateAllChamsAndBillboards() end
    end,
})

mainTab:CreateColorPicker({
    Name = "Cor da Distância",
    Color = DistanceColor,
    Callback = function(color)
        DistanceColor = color
        if not UseTeamColor then UpdateAllChamsAndBillboards() end
    end,
})

mainTab:CreateColorPicker({
    Name = "Cor do Glow/Chams",
    Color = ChamsColor,
    Callback = function(color)
        ChamsColor = color
        if not UseTeamColor then UpdateAllChamsAndBillboards() end
    end,
})

-- FIM DO SCRIPT
