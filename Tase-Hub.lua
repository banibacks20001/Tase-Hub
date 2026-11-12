local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Tase Hub",
    LoadingTitle = "Tase Hub",
    LoadingSubtitle = "by banibacks",
    ConfigurationSaving = {Enabled = false}
})

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Aimbot = false
local AimFOV = 150
local ESP = false
local NameTags = false
local SpeedValue = 16
local InfJump = false
local TeamCheck = false
local RainbowFOV = false

local BulletSpeed = 2500
local Prediction = true

local activeTags = {}

local function GetTeamColor(player)
    if player.Team and player.Team.Name == "Police" then
        return Color3.fromRGB(0,120,255)
    elseif player.Team and player.Team.Name == "Prisoner" then
        return Color3.fromRGB(255,170,0)
    elseif player.Team and player.Team.Name == "Criminal" then
        return Color3.fromRGB(255,0,0)
    end
    return Color3.fromRGB(255,255,255)
end

local function CreateNameTag(player, character)
    local head = character:WaitForChild("Head", 10)
    local humanoid = character:WaitForChild("Humanoid", 10)

    if not head or not humanoid then return end

    local old = head:FindFirstChild("CustomNameTag")
    if old then old:Destroy() end

    local gui = Instance.new("BillboardGui")
    gui.Name = "CustomNameTag"
    gui.Adornee = head
    gui.Size = UDim2.fromOffset(112, 32)
    gui.StudsOffset = Vector3.new(0, 2.7, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 0
    gui.Parent = head

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1
    uiScale.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = GetTeamColor(player)
    stroke.Parent = frame

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.fromOffset(27, 27)
    avatar.Position = UDim2.fromOffset(3, 2)
    avatar.BackgroundTransparency = 1
    avatar.Parent = frame

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 5)
    avatarCorner.Parent = avatar

    task.spawn(function()
        local success, image = pcall(function()
            return Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)

        if success and avatar.Parent then
            avatar.Image = image
        end
    end)

    local name = Instance.new("TextLabel")
    name.Position = UDim2.fromOffset(35, 2)
    name.Size = UDim2.new(1, -40, 0, 15)
    name.BackgroundTransparency = 1
    name.Text = player.Name
    name.TextColor3 = Color3.new(1, 1, 1)
    name.TextSize = 10
    name.Font = Enum.Font.GothamBold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.Parent = frame

    local hpBackground = Instance.new("Frame")
    hpBackground.Position = UDim2.fromOffset(35, 21)
    hpBackground.Size = UDim2.new(1, -40, 0, 6)
    hpBackground.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    hpBackground.BorderSizePixel = 0
    hpBackground.ClipsDescendants = true
    hpBackground.Parent = frame

    local hpCorner = Instance.new("UICorner")
    hpCorner.CornerRadius = UDim.new(1, 0)
    hpCorner.Parent = hpBackground

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.fromScale(1, 1)
    hpFill.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBackground

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = hpFill

    local function Update()
        local percent = math.clamp(
            humanoid.Health / math.max(humanoid.MaxHealth, 1),
            0, 1
        )

        hpFill.Size = UDim2.fromScale(percent, 1)
        stroke.Color = GetTeamColor(player)

        if percent <= 0.25 then
            hpFill.BackgroundColor3 = Color3.fromRGB(240, 65, 65)
        elseif percent <= 0.5 then
            hpFill.BackgroundColor3 = Color3.fromRGB(240, 190, 60)
        else
            hpFill.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
        end
    end

    humanoid.HealthChanged:Connect(Update)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(Update)
    Update()

    activeTags[player] = {
        gui = gui,
        head = head,
        scale = uiScale
    }
end

local Circle = Drawing.new("Circle")
Circle.Visible = false
Circle.Thickness = 2
Circle.Radius = AimFOV
Circle.Color = Color3.fromRGB(255,255,255)
Circle.Filled = false

local CombatTab = Window:CreateTab("Combat")
local MoveTab = Window:CreateTab("Movement")
local VisualTab = Window:CreateTab("Visuals")

CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(v)
        Aimbot = v
        Circle.Visible = v
    end
})

CombatTab:CreateSlider({
    Name = "Aim FOV",
    Range = {50,500},
    Increment = 10,
    CurrentValue = 150,
    Callback = function(v)
        AimFOV = v
    end
})

CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(v)
        TeamCheck = v
    end
})

MoveTab:CreateSlider({
    Name = "SpeedHack",
    Range = {16,120},
    Increment = 2,
    CurrentValue = 16,
    Callback = function(v)
        SpeedValue = v
    end
})

MoveTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        InfJump = v
    end
})

VisualTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(v)
        ESP = v
    end
})

VisualTab:CreateToggle({
    Name = "Name Tags",
    CurrentValue = false,
    Callback = function(v)
        NameTags = v
    end
})

VisualTab:CreateToggle({
    Name = "Rainbow FOV",
    CurrentValue = false,
    Callback = function(v)
        RainbowFOV = v
    end
})

VisualTab:CreateButton({
    Name = "FPS Boost",
    Callback = function()
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            end
        end
    end
})

local function WallCheck(position, character)
    local origin = Camera.CFrame.Position
    local direction = position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local ray = workspace:Raycast(origin, direction, params)

    if ray then
        return ray.Instance:IsDescendantOf(character)
    end

    return true
end

RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.WalkSpeed = SpeedValue
    end
end)

UIS.JumpRequest:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if InfJump and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(
        Camera.ViewportSize.X/2,
        Camera.ViewportSize.Y/2
    )

    Circle.Position = screenCenter
    Circle.Radius = AimFOV

    if RainbowFOV then
        Circle.Color = Color3.fromHSV(tick()%5/5,1,1)
    end

    if not Aimbot then return end

    local closestPart = nil
    local shortestDistance = AimFOV

    for _,player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer
        and player.Character
        and player.Character:FindFirstChild("Head")
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0 then

            if TeamCheck and LocalPlayer.Team ~= nil
            and player.Team == LocalPlayer.Team then
                continue
            end

            local head = player.Character.Head
            local pos, visible = Camera:WorldToViewportPoint(head.Position)

            if visible and WallCheck(head.Position, player.Character) then
                local distance = (
                    Vector2.new(pos.X,pos.Y) - screenCenter
                ).Magnitude

                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPart = head
                end
            end
        end
    end

    if closestPart then
        local aimPosition = closestPart.Position

        if Prediction then
            local velocity = closestPart.AssemblyLinearVelocity
            local distance = (
                Camera.CFrame.Position - closestPart.Position
            ).Magnitude

            local time = distance / BulletSpeed
            aimPosition = closestPart.Position + (velocity * time)
        end

        Camera.CFrame = CFrame.new(
            Camera.CFrame.Position,
            aimPosition
        )
    end
end)

RunService.RenderStepped:Connect(function()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local color = GetTeamColor(p)
            local h = p.Character:FindFirstChild("ZenithESP")

            if ESP then
                if not h then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "ZenithESP"
                    highlight.FillColor = color
                    highlight.Parent = p.Character
                else
                    h.FillColor = color
                end
            elseif h then
                h:Destroy()
            end

            local tagData = activeTags[p]
            local head = p.Character:FindFirstChild("Head")

            if NameTags and head then
                if not tagData or not tagData.gui.Parent or tagData.head ~= head then
                    if tagData and tagData.gui then
                        tagData.gui:Destroy()
                    end

                    CreateNameTag(p, p.Character)
                end
            elseif tagData then
                if tagData.gui then
                    tagData.gui:Destroy()
                end
                activeTags[p] = nil
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if not camera then return end

    for player, data in pairs(activeTags) do
        if data.gui.Parent and data.head.Parent then
            local distance = (
                camera.CFrame.Position - data.head.Position
            ).Magnitude

            local alpha = math.clamp(
                (distance - 15) / 145,
                0, 1
            )

            data.scale.Scale = 0.85 + ((1 - alpha) * 0.3)
        else
            activeTags[player] = nil
        end
    end
end)
