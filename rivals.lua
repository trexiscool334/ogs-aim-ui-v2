-- OGS ESP & Aimbot GUI Script
-- Focused exclusively on Visuals/ESP and Combat/Aimbot

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings
local Settings = {
    -- ESP
    ESP = true,
    ESPBoxes = true,
    ESPNames = true,
    ESPDistance = true,
    ESPHealth = true,
    Chams = true,
    ChamsAlpha = 0.4,
    ChamsVisibleColor = Color3.fromRGB(150, 200, 60),
    ChamsOccludedColor = Color3.fromRGB(200, 50, 50),
    -- Aimbot
    Aimbot = true,
    Smoothness = 0.5,
    FOV = 150,
    AimbotKey = Enum.UserInputType.MouseButton2
}

local ACCENT = Color3.fromRGB(150, 200, 60)

-- Utility
local function isAlive(player)
    return player.Character
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
end

local function worldToViewport(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function isOccluded(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end
    local origin = Camera.CFrame.Position
    local dir = (hrp.Position - origin)
    local ray = Ray.new(origin, dir)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {character, LocalPlayer.Character})
    return hit ~= nil
end

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Color = ACCENT
fovCircle.Transparency = 0.6
fovCircle.NumSides = 64

-- Aimbot Target Finder
local function getAimbotTarget()
    local mouse = UserInputService:GetMouseLocation()
    local best, bestDist = nil, Settings.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local part = player.Character:FindFirstChild("HeadHB")
                      or player.Character:FindFirstChild("Head")
                      or player.Character:FindFirstChild("UpperTorso")
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best = part
                    end
                end
            end
        end
    end
    return best
end

-- Core Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OGSGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local DrawingFolder = Instance.new("Folder")
DrawingFolder.Name = "Drawings"
DrawingFolder.Parent = ScreenGui

-- ESP Storage
local espObjects = {}

local function removeESP(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            obj:Destroy()
        end
        espObjects[player] = nil
    end
end

local function createESP(player)
    if player == LocalPlayer then return end
    removeESP(player)

    local container = Instance.new("Folder", DrawingFolder)
    espObjects[player] = {}

    -- Box
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 2
    box.BorderColor3 = ACCENT
    box.Size = UDim2.new(0, 0, 0, 0)
    box.Parent = container
    espObjects[player].box = box

    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1,1,1)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = player.Name
    nameLabel.Size = UDim2.new(0, 100, 0, 16)
    nameLabel.Parent = container
    espObjects[player].nameLabel = nameLabel

    -- Distance label
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(200,200,200)
    distLabel.TextStrokeTransparency = 0.5
    distLabel.TextSize = 11
    distLabel.Font = Enum.Font.Gotham
    distLabel.Size = UDim2.new(0, 100, 0, 14)
    distLabel.Parent = container
    espObjects[player].distLabel = distLabel

    -- Health bar background
    local healthBG = Instance.new("Frame")
    healthBG.Name = "HealthBG"
    healthBG.BackgroundColor3 = Color3.fromRGB(30,30,30)
    healthBG.BorderSizePixel = 0
    healthBG.Parent = container
    espObjects[player].healthBG = healthBG

    -- Health bar fill
    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.BackgroundColor3 = Color3.fromRGB(100, 220, 60)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBG
    espObjects[player].healthFill = healthFill

    -- Chams
    local chams = Instance.new("SelectionBox")
    chams.Name = "Chams"
    chams.LineThickness = 0.05
    chams.SurfaceTransparency = 1 - Settings.ChamsAlpha
    chams.Color3 = Settings.ChamsVisibleColor
    chams.SurfaceColor3 = Settings.ChamsVisibleColor
    chams.Parent = container
    espObjects[player].chams = chams
end

local function updateESP(player)
    local objs = espObjects[player]
    if not objs then return end

    local char = player.Character
    if not char or not isAlive(player) then
        for _, obj in pairs(objs) do obj.Visible = false end
        if objs.chams then objs.chams.Adornee = nil end
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local humanoid = char:FindFirstChild("Humanoid")
    if not hrp or not head then return end

    local topPos, topOnScreen = worldToViewport(head.Position + Vector3.new(0, 0.7, 0))
    local botPos, botOnScreen, depth = worldToViewport(hrp.Position - Vector3.new(0, 3, 0))

    local visible = topOnScreen or botOnScreen
    local occluded = isOccluded(char)

    -- Box
    if objs.box then
        objs.box.Visible = Settings.ESP and Settings.ESPBoxes and visible
        if visible then
            local h = math.abs(botPos.Y - topPos.Y)
            local w = h * 0.6
            local cx = (topPos.X + botPos.X) / 2
            objs.box.Position = UDim2.new(0, cx - w/2, 0, topPos.Y)
            objs.box.Size = UDim2.new(0, w, 0, h)
            objs.box.BorderColor3 = occluded and Color3.fromRGB(200,50,50) or ACCENT
        end
    end

    -- Name
    if objs.nameLabel then
        objs.nameLabel.Visible = Settings.ESP and Settings.ESPNames and visible
        if visible then
            objs.nameLabel.Position = UDim2.new(0, topPos.X - 50, 0, topPos.Y - 18)
        end
    end

    -- Distance
    if objs.distLabel then
        local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
        objs.distLabel.Visible = Settings.ESP and Settings.ESPDistance and visible
        if visible then
            objs.distLabel.Text = dist .. "m"
            objs.distLabel.Position = UDim2.new(0, botPos.X - 50, 0, botPos.Y + 2)
        end
    end

    -- Health
    if objs.healthBG and humanoid then
        local h = math.abs(botPos.Y - topPos.Y)
        local w = h * 0.6
        local cx = (topPos.X + botPos.X) / 2
        objs.healthBG.Visible = Settings.ESP and Settings.ESPHealth and visible
        objs.healthBG.Position = UDim2.new(0, cx - w/2 - 6, 0, topPos.Y)
        objs.healthBG.Size = UDim2.new(0, 4, 0, h)
        local pct = humanoid.Health / humanoid.MaxHealth
        objs.healthFill.Size = UDim2.new(1, 0, pct, 0)
        objs.healthFill.Position = UDim2.new(0, 0, 1 - pct, 0)
        objs.healthFill.BackgroundColor3 = Color3.fromRGB(
            math.floor(255 * (1 - pct)),
            math.floor(255 * pct),
            0
        )
    end

    -- Chams
    if objs.chams then
        objs.chams.Visible = Settings.Chams
        if Settings.Chams then
            objs.chams.Adornee = hrp
            local col = occluded and Settings.ChamsOccludedColor or Settings.ChamsVisibleColor
            objs.chams.Color3 = col
            objs.chams.SurfaceColor3 = col
            objs.chams.SurfaceTransparency = occluded and (1 - Settings.ChamsAlpha * 0.5) or (1 - Settings.ChamsAlpha)
        else
            objs.chams.Adornee = nil
        end
    end
end

-- GUI Setup
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 450)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = ScreenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local border = Instance.new("UIStroke", mainFrame)
border.Color = ACCENT
border.Thickness = 1.5
border.Transparency = 0.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(12,12,12)
title.BorderSizePixel = 0
title.Text = "OGS GUI"
title.TextColor3 = ACCENT
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local container = Instance.new("ScrollingFrame")
container.Size = UDim2.new(1, -20, 1, -60)
container.Position = UDim2.new(0, 10, 0, 50)
container.BackgroundTransparency = 1
container.BorderSizePixel = 0
container.ScrollBarThickness = 3
container.ScrollBarImageColor3 = ACCENT
container.Parent = mainFrame
local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 10)

local function makeSection(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = ACCENT
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
end

local function makeToggle(labelText, setting)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent = container

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0, 50, 0, 24)
    btn.Position = UDim2.new(1, -50, 0.5, -12)
    btn.BorderSizePixel = 0
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local function refresh()
        local on = Settings[setting]
        btn.BackgroundColor3 = on and ACCENT or Color3.fromRGB(50,50,50)
        btn.TextColor3 = on and Color3.fromRGB(20,20,20) or Color3.fromRGB(150,150,150)
        btn.Text = on and "ON" or "OFF"
    end
    refresh()
    btn.MouseButton1Click:Connect(function()
        Settings[setting] = not Settings[setting]
        refresh()
    end)
end

local function makeSlider(labelText, setting, min, max)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.Parent = container

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText .. ": " .. tostring(math.floor(Settings[setting] * 10) / 10)
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1, 0, 0, 8)
    track.Position = UDim2.new(0, 0, 0, 24)
    track.BackgroundColor3 = Color3.fromRGB(40,40,40)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local function setVal(v)
        v = math.clamp(v, min, max)
        Settings[setting] = v
        lbl.Text = labelText .. ": " .. tostring(math.floor(v * 10) / 10)
        fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
    end
    setVal(Settings[setting])

    local dragging = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local abs = track.AbsolutePosition
            local w = track.AbsoluteSize.X
            local pct = math.clamp((i.Position.X - abs.X) / w, 0, 1)
            setVal(min + (max - min) * pct)
        end
    end)
end

-- Build UI
makeSection("COMBAT")
makeToggle("Aimbot", "Aimbot")
makeSlider("Smoothness", "Smoothness", 0.1, 1.0)
makeSlider("FOV Radius", "FOV", 10, 600)

makeSection("VISUALS")
makeToggle("Master ESP", "ESP")
makeToggle("Boxes", "ESPBoxes")
makeToggle("Names", "ESPNames")
makeToggle("Distance", "ESPDistance")
makeToggle("Health", "ESPHealth")
makeToggle("Chams", "Chams")

-- Toggle GUI with INSERT
UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.Insert then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- Player Management
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        createESP(player)
    end)
    if player.Character then
        task.wait(1)
        createESP(player)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then onPlayerAdded(player) end
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(removeESP)

-- Global Loop
RunService.RenderStepped:Connect(function()
    -- ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateESP(player)
        end
    end

    -- FOV Circle
    fovCircle.Visible = Settings.Aimbot
    fovCircle.Radius = Settings.FOV
    fovCircle.Position = UserInputService:GetMouseLocation()

    -- Aimbot
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Settings.AimbotKey) then
        local target = getAimbotTarget()
        if target then
            local pos, _ = Camera:WorldToViewportPoint(target.Position)
            local mouse = UserInputService:GetMouseLocation()
            local x = (pos.X - mouse.X) * Settings.Smoothness
            local y = (pos.Y - mouse.Y) * Settings.Smoothness
            if mousemoverel then
                mousemoverel(x, y)
            end
        end
    end
end)
