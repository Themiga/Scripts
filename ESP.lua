local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESPEnabled = false
local ShowName = true
local ShowDistance = true
local ShowChams = false
local UseTeamColor = false

local NameColor = Color3.fromRGB(255, 255, 255)
local DistanceColor = Color3.fromRGB(200, 255, 200)
local ChamsColor = Color3.fromRGB(0, 255, 255)

local ESPObjects = {} -- [player] = {billboard = BillboardGui, highlight = Highlight}

----------------------------------------------------------------------
-- FUNÇÕES AUXILIARES
----------------------------------------------------------------------

local function getTeamColor(player)
    if UseTeamColor and player.TeamColor then
        return player.TeamColor.Color
    end
    return nil
end

local function getDistance(player)
    local myChar = LocalPlayer.Character
    if myChar and myChar:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return math.floor((myChar.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude)
    end
    return ""
end

local function removeESP(player)
    local data = ESPObjects[player]
    if data then
        if data.billboard and data.billboard.Parent then
            data.billboard:Destroy()
        end
        if data.highlight and data.highlight.Parent then
            data.highlight:Destroy()
        end
        ESPObjects[player] = nil
    end
end

local function updateBillboard(player)
    if not ShowName and not ShowDistance then
        if ESPObjects[player] and ESPObjects[player].billboard then
            ESPObjects[player].billboard.Enabled = false
        end
        return
    end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end

    -- Billboard só é criado se não existir
    local data = ESPObjects[player] or {}
    local bill = data.billboard
    if not bill or not bill.Parent then
        bill = Instance.new("BillboardGui")
        bill.Name = "ESP_Billboard"
        bill.Adornee = player.Character.Head
        bill.Size = UDim2.new(0, 120, 0, 36)
        bill.StudsOffset = Vector3.new(0, 1.8, 0)
        bill.AlwaysOnTop = true

        local Stack = Instance.new("Frame")
        Stack.Name = "Stack"
        Stack.Parent = bill
        Stack.BackgroundTransparency = 1
        Stack.Size = UDim2.new(1, 0, 1, 0)

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Name = "NameLabel"
        NameLabel.Parent = Stack
        NameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        NameLabel.Position = UDim2.new(0, 0, 0, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.TextStrokeTransparency = 0.5
        NameLabel.Font = Enum.Font.SourceSansBold
        NameLabel.TextScaled = true

        local DistanceLabel = Instance.new("TextLabel")
        DistanceLabel.Name = "DistanceLabel"
        DistanceLabel.Parent = Stack
        DistanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
        DistanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
        DistanceLabel.BackgroundTransparency = 1
        DistanceLabel.TextStrokeTransparency = 0.5
        DistanceLabel.Font = Enum.Font.SourceSans
        DistanceLabel.TextScaled = true

        bill.Parent = player.Character.Head
        data.billboard = bill
        ESPObjects[player] = data
    end

    bill.Enabled = ESPEnabled and (ShowName or ShowDistance)

    -- Atualiza textos e cores
    local stack = bill:FindFirstChild("Stack")
    if stack then
        local nameLabel = stack:FindFirstChild("NameLabel")
        local distLabel = stack:FindFirstChild("DistanceLabel")
        local teamColor = getTeamColor(player)
        if nameLabel then
            nameLabel.Visible = ShowName
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = teamColor or NameColor
        end
        if distLabel then
            distLabel.Visible = ShowDistance
            distLabel.TextColor3 = teamColor or DistanceColor
            if ShowDistance then
                distLabel.Text = getDistance(player) ~= "" and (getDistance(player) .. "m") or ""
            else
                distLabel.Text = ""
            end
        end
    end
end

local function updateHighlight(player)
    if not ShowChams or not ESPEnabled then
        if ESPObjects[player] and ESPObjects[player].highlight then
            ESPObjects[player].highlight.Enabled = false
        end
        return
    end
    if not player.Character then return end

    -- Highlight só é criado se não existir
    local data = ESPObjects[player] or {}
    local high = data.highlight
    if not high or not high.Parent then
        -- Remove outros Highlights para garantir só 1
        for _, v in ipairs(player.Character:GetChildren()) do
            if v:IsA("Highlight") and v.Name == "ESPChams" then
                v:Destroy()
            end
        end
        high = Instance.new("Highlight")
        high.Name = "ESPChams"
        high.Adornee = player.Character
        high.Parent = player.Character
        high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        data.highlight = high
        ESPObjects[player] = data
    end

    high.Enabled = ESPEnabled and ShowChams
    local teamColor = getTeamColor(player)
    high.FillColor = teamColor or ChamsColor
    high.OutlineColor = teamColor or ChamsColor
    high.FillTransparency = 0.5
    high.OutlineTransparency = 0
end

local function updatePlayerESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    if not ESPEnabled then
        removeESP(player)
        return
    end
    updateBillboard(player)
    updateHighlight(player)
end

local function onCharacterAdded(player, character)
    -- Aguarda partes essenciais
    local function tryInit()
        if character and character:FindFirstChild("Head") then
            updatePlayerESP(player)
            return true
        end
        return false
    end
    local tries = 0
    while tries < 15 and not tryInit() do
        tries = tries + 1
        task.wait(0.15)
    end
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
    -- Se o character já existir
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end

local function onPlayerRemoving(player)
    removeESP(player)
end

-- Atualização contínua para garantir atualização de cor/time
RunService.RenderStepped:Connect(function()
    if not ESPEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then removeESP(player) end
        end
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updatePlayerESP(player)
        end
    end
end)

-- Liga eventos para todos jogadores atuais e futuros!
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

----------------------------------------------------------------------
-- INTERFACE RAYFIELD
----------------------------------------------------------------------

local Window = Rayfield:CreateWindow({
    Name = "ESP desenvolvido por Themiga",
    LoadingTitle = "Rayfield ESP",
    LoadingSubtitle = "by Themiga",
    ConfigurationSaving = {Enabled = false,},
})

local mainTab = Window:CreateTab("ESP", 4483362458)
mainTab:CreateSection("Opções do ESP")

mainTab:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = ESPEnabled,
    Callback = function(val) ESPEnabled = val end,
})

mainTab:CreateToggle({
    Name = "Mostrar nome",
    CurrentValue = ShowName,
    Callback = function(val) ShowName = val end,
})

mainTab:CreateToggle({
    Name = "Mostrar distância",
    CurrentValue = ShowDistance,
    Callback = function(val) ShowDistance = val end,
})

mainTab:CreateToggle({
    Name = "Chams/Glow",
    CurrentValue = ShowChams,
    Callback = function(val) ShowChams = val end,
})

mainTab:CreateSection("Personalização de Cores")

mainTab:CreateToggle({
    Name = "Team color",
    CurrentValue = UseTeamColor,
    Callback = function(val) UseTeamColor = val end,
})

mainTab:CreateColorPicker({
    Name = "Cor do Nome",
    Color = NameColor,
    Callback = function(color) NameColor = color end,
})

mainTab:CreateColorPicker({
    Name = "Cor da Distância",
    Color = DistanceColor,
    Callback = function(color) DistanceColor = color end,
})

mainTab:CreateColorPicker({
    Name = "Cor do Chams/Glow",
    Color = ChamsColor,
    Callback = function(color) ChamsColor = color end,
})

-- FIM DO SCRIPT
