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
local Tracers = false
local NameTags = false
local SpeedValue = 16
local InfJump = false
local TeamCheck = false

local BulletSpeed = 2500
local Prediction = true

local activeTags = {}
local ESPObjects = {}

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

-- NAME TAGS

local function RemoveNameTag(player)
    local data = activeTags[player]

    if data then
        if data.gui then
            data.gui:Destroy()
        end

        if data.humanoid and data.humanoid.Parent then
            data.humanoid.DisplayDistanceType =
                data.originalDisplayDistanceType
        end

        activeTags[player] = nil
    end
end

local function CreateNameTag(player, character)
    RemoveNameTag(player)

    local head = character:WaitForChild("Head",10)
    local humanoid = character:WaitForChild("Humanoid",10)

    if not head or not humanoid then return end

    local originalDisplayDistanceType =
        humanoid.DisplayDistanceType

    humanoid.DisplayDistanceType =
        Enum.HumanoidDisplayDistanceType.None

    local gui = Instance.new("BillboardGui")
    gui.Name = "CustomNameTag"
    gui.Adornee = head
    gui.Size = UDim2.fromOffset(110,29)
    gui.StudsOffset = Vector3.new(0,2.6,0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 0
    gui.Parent = head

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(1,1)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1,-8,0,17)
    name.Position = UDim2.fromOffset(4,1)
    name.BackgroundTransparency = 1
    name.Text = player.Name
    name.TextColor3 = GetTeamColor(player)
    name.TextSize = 12
    name.Font = Enum.Font.GothamBold
    name.TextXAlignment = Enum.TextXAlignment.Center
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.TextStrokeTransparency = 0.65
    name.Parent = frame

    local hpBackground = Instance.new("Frame")
    hpBackground.Position = UDim2.fromOffset(4,21)
    hpBackground.Size = UDim2.new(1,-8,0,4)
    hpBackground.BackgroundColor3 = Color3.fromRGB(55,55,55)
    hpBackground.BorderSizePixel = 0
    hpBackground.ClipsDescendants = true
    hpBackground.Parent = frame

    local hpCorner = Instance.new("UICorner")
    hpCorner.CornerRadius = UDim.new(1,0)
    hpCorner.Parent = hpBackground

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.fromScale(1,1)
    hpFill.BackgroundColor3 = Color3.fromRGB(50,220,100)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBackground

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1,0)
    fillCorner.Parent = hpFill

    local function Update()
        if not humanoid.Parent then return end

        local percent = math.clamp(
            humanoid.Health / math.max(humanoid.MaxHealth,1),
            0,1
        )

        name.TextColor3 = GetTeamColor(player)
        hpFill.Size = UDim2.fromScale(percent,1)

        if percent <= 0.25 then
            hpFill.BackgroundColor3 = Color3.fromRGB(240,65,65)
        elseif percent <= 0.5 then
            hpFill.BackgroundColor3 = Color3.fromRGB(240,190,60)
        else
            hpFill.BackgroundColor3 = Color3.fromRGB(50,220,100)
        end
    end

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = frame

    activeTags[player] = {
        gui = gui,
        head = head,
        scale = scale,
        humanoid = humanoid,
        originalDisplayDistanceType = originalDisplayDistanceType,
        update = Update
    }

    Update()
end

-- ESP DRAWINGS

local function CreateESPObjects(player)
    if ESPObjects[player] then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255,255,255)
    box.Thickness = 1.5
    box.Filled = false

    local hpBackground = Drawing.new("Square")
    hpBackground.Visible = false
    hpBackground.Color = Color3.fromRGB(35,35,35)
    hpBackground.Filled = true
    hpBackground.Thickness = 0

    local hpFill = Drawing.new("Square")
    hpFill.Visible = false
    hpFill.Color = Color3.fromRGB(50,220,100)
    hpFill.Filled = true
    hpFill.Thickness = 0

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(255,255,255)
    tracer.Thickness = 1

    ESPObjects[player] = {
        box = box,
        hpBackground = hpBackground,
        hpFill = hpFill,
        tracer = tracer
    }
end

local function HideESP(player)
    local data = ESPObjects[player]
    if not data then return end

    data.box.Visible = false
    data.hpBackground.Visible = false
    data.hpFill.Visible = false
    data.tracer.Visible = false
end

local function RemoveESP(player)
    local data = ESPObjects[player]
    if not data then return end

    for _,drawing in pairs(data) do
        drawing:Remove()
    end

    ESPObjects[player] = nil
end

-- ESP BOX POSITION

local function GetScreenBounds(character)
    local success,cf,size = pcall(function()
        return character:GetBoundingBox()
    end)

    if not success then return nil end

    local minX = math.huge
    local minY = math.huge
    local maxX = -math.huge
    local maxY = -math.huge
    local visibleCorners = 0

    for x = -1,1,2 do
        for y = -1,1,2 do
            for z = -1,1,2 do
                local offset = Vector3.new(
                    size.X*x/2,
                    size.Y*y/2,
                    size.Z*z/2
                )

                local worldPosition = cf:PointToWorldSpace(offset)
                local screenPosition =
                    Camera:WorldToViewportPoint(worldPosition)

                if screenPosition.Z > 0 then
                    visibleCorners += 1

                    minX = math.min(minX,screenPosition.X)
                    minY = math.min(minY,screenPosition.Y)
                    maxX = math.max(maxX,screenPosition.X)
                    maxY = math.max(maxY,screenPosition.Y)
                end
            end
        end
    end

    if visibleCorners == 0 then return nil end

    local width = maxX-minX
    local height = maxY-minY

    if width < 2 or height < 2 then return nil end

    local viewport = Camera.ViewportSize

    if maxX < 0 or minX > viewport.X
    or maxY < 0 or minY > viewport.Y then
        return nil
    end

    return minX,minY,width,height
end

-- TRACER POSITION

local function GetTracerPoint(position)
    local viewport = Camera.ViewportSize
    local center = Vector2.new(
        viewport.X/2,
        viewport.Y/2
    )

    local projected = Camera:WorldToViewportPoint(position)

    local point = Vector2.new(
        projected.X,
        projected.Y
    )

    if projected.Z <= 0 then
        point = center-(point-center)
    end

    if projected.Z > 0
    and point.X >= 0 and point.X <= viewport.X
    and point.Y >= 0 and point.Y <= viewport.Y then
        return point
    end

    local direction = point-center

    if direction.Magnitude < 0.001 then
        direction = Vector2.new(0,1)
    end

    local margin = 8
    local scaleX = math.huge
    local scaleY = math.huge

    if direction.X > 0 then
        scaleX = (viewport.X-margin-center.X)/direction.X
    elseif direction.X < 0 then
        scaleX = (margin-center.X)/direction.X
    end

    if direction.Y > 0 then
        scaleY = (viewport.Y-margin-center.Y)/direction.Y
    elseif direction.Y < 0 then
        scaleY = (margin-center.Y)/direction.Y
    end

    local scale = math.min(scaleX,scaleY)

    return center+direction*scale
end

-- UPDATE ESP

local function UpdateESP(player)
    if player == LocalPlayer then return end

    CreateESPObjects(player)

    local data = ESPObjects[player]
    local character = player.Character

    local humanoid = character and
        character:FindFirstChildOfClass("Humanoid")

    if not character or not humanoid or humanoid.Health <= 0 then
        HideESP(player)
        return
    end

    -- TRACERS

    local target = character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Head")

    if Tracers and target then
        local point = GetTracerPoint(target.Position)

        data.tracer.Visible = true

        data.tracer.From = Vector2.new(
            Camera.ViewportSize.X/2,
            Camera.ViewportSize.Y
        )

        data.tracer.To = point
    else
        data.tracer.Visible = false
    end

    -- ESP BOX

    if not ESP then
        data.box.Visible = false
        data.hpBackground.Visible = false
        data.hpFill.Visible = false
        return
    end

    local x,y,width,height = GetScreenBounds(character)

    if not x then
        data.box.Visible = false
        data.hpBackground.Visible = false
        data.hpFill.Visible = false
        return
    end

    local percent = math.clamp(
        humanoid.Health/math.max(humanoid.MaxHealth,1),
        0,1
    )

    data.box.Visible = true
    data.box.Position = Vector2.new(x,y)
    data.box.Size = Vector2.new(width,height)

    -- HP LEFT

    data.hpBackground.Visible = true
    data.hpBackground.Position = Vector2.new(x-6,y)
    data.hpBackground.Size = Vector2.new(3,height)

    data.hpFill.Visible = true
    data.hpFill.Position = Vector2.new(
        x-6,
        y+height*(1-percent)
    )

    data.hpFill.Size = Vector2.new(
        3,
        height*percent
    )

    if percent <= 0.25 then
        data.hpFill.Color = Color3.fromRGB(240,65,65)
    elseif percent <= 0.5 then
        data.hpFill.Color = Color3.fromRGB(240,190,60)
    else
        data.hpFill.Color = Color3.fromRGB(50,220,100)
    end
end

-- FOV

local Circle = Drawing.new("Circle")
Circle.Visible = false
Circle.Thickness = 2
Circle.Radius = AimFOV
Circle.Color = Color3.fromRGB(255,255,255)
Circle.Filled = false

-- TABS

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
    Name = "Tracers",
    CurrentValue = false,
    Callback = function(v)
        Tracers = v
    end
})

VisualTab:CreateToggle({
    Name = "Name Tags",
    CurrentValue = false,
    Callback = function(v)
        NameTags = v

        if not v then
            for player in pairs(activeTags) do
                RemoveNameTag(player)
            end
        end
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

-- WALL CHECK

local function WallCheck(position,character)
    local origin = Camera.CFrame.Position
    local direction = position-origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local ray = workspace:Raycast(origin,direction,params)

    if ray then
        return ray.Instance:IsDescendantOf(character)
    end

    return true
end

-- SPEED

RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and
        character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.WalkSpeed = SpeedValue
    end
end)

-- INFINITE JUMP

UIS.JumpRequest:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and
        character:FindFirstChildOfClass("Humanoid")

    if InfJump and humanoid then
        humanoid:ChangeState(
            Enum.HumanoidStateType.Jumping
        )
    end
end)

-- AIMBOT AND FOV

RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera
    if not Camera then return end

    local screenCenter = Vector2.new(
        Camera.ViewportSize.X/2,
        Camera.ViewportSize.Y/2
    )

    Circle.Position = screenCenter
    Circle.Radius = AimFOV
    Circle.Color = Color3.fromRGB(255,255,255)

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

            local pos,visible =
                Camera:WorldToViewportPoint(head.Position)

            if visible and WallCheck(head.Position,player.Character) then
                local distance = (
                    Vector2.new(pos.X,pos.Y)-screenCenter
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
                Camera.CFrame.Position-closestPart.Position
            ).Magnitude

            local time = distance/BulletSpeed
            aimPosition = closestPart.Position+(velocity*time)
        end

        Camera.CFrame = CFrame.new(
            Camera.CFrame.Position,
            aimPosition
        )
    end
end)

-- VISUALS UPDATE

RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera
    if not Camera then return end

    for _,player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then

            -- ESP AND TRACERS

            if ESP or Tracers then
                UpdateESP(player)
            elseif ESPObjects[player] then
                HideESP(player)
            end

            -- NAME TAGS

            local character = player.Character
            local head = character and
                character:FindFirstChild("Head")

            local tagData = activeTags[player]

            if NameTags and head then
                if not tagData
                or not tagData.gui.Parent
                or tagData.head ~= head then

                    CreateNameTag(player,character)
                end

            elseif tagData then
                RemoveNameTag(player)
            end
        end
    end
end)

-- NAME TAG SCALE AND HP

RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera
    if not Camera then return end

    for player,data in pairs(activeTags) do
        if data.gui.Parent and data.head.Parent then

            data.update()

            local distance = (
                Camera.CFrame.Position-data.head.Position
            ).Magnitude

            local alpha = math.clamp(
                (distance-15)/145,
                0,1
            )

            data.scale.Scale =
                0.85+((1-alpha)*0.3)
        else
            RemoveNameTag(player)
        end
    end
end)

-- CLEANUP

Players.PlayerRemoving:Connect(function(player)
    RemoveNameTag(player)
    RemoveESP(player)
end)
