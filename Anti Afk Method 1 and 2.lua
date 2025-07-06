local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera


local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoMoveMenu"
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 130)
frame.Position = UDim2.new(0, 30, 0, 30)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.AnchorPoint = Vector2.new(0, 0)
frame.Parent = screenGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.Position = UDim2.new(0, 0, 0, 0)
bg.BackgroundTransparency = 0
bg.BackgroundColor3 = Color3.new(1, 0, 0)
bg.BorderSizePixel = 0
bg.Parent = frame

local uiGradient = Instance.new("UIGradient")
uiGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(230,40,60)),   -- Красный
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40,80,220))    -- Синий
}
uiGradient.Rotation = 45
uiGradient.Parent = bg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = bg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 38)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "Anti-AFK"
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = frame
title.ZIndex = 2

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.7, 0, 0, 46)
toggleButton.Position = UDim2.new(0.15, 0, 0, 48)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 215, 80)
toggleButton.Text = "Включить"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.TextColor3 = Color3.fromRGB(10,10,10)
toggleButton.Parent = frame
toggleButton.AutoButtonColor = true
toggleButton.BorderSizePixel = 0
toggleButton.ZIndex = 2

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = toggleButton

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 22)
info.Position = UDim2.new(0, 0, 1, -26)
info.BackgroundTransparency = 1
info.Font = Enum.Font.Gotham
info.Text = "Made by @ksenorebat"
info.TextSize = 13
info.TextColor3 = Color3.fromRGB(230,230,255)
info.Parent = frame
info.ZIndex = 2


local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(
        0, math.clamp(startPos.X.Offset + delta.X, 0, workspace.CurrentCamera.ViewportSize.X - frame.AbsoluteSize.X),
        0, math.clamp(startPos.Y.Offset + delta.Y, 0, workspace.CurrentCamera.ViewportSize.Y - frame.AbsoluteSize.Y)
    )
end
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
userInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)


local running = false
local directionIndex = 1
local directions = {
    Vector3.new(0, 0, -1), -- вперед
    Vector3.new(0, 0, 1),  -- назад
    Vector3.new(1, 0, 0),  -- вправо
    Vector3.new(-1, 0, 0)  -- влево
}
local DIRECTION_INTERVAL = 2
local JUMP_INTERVAL = 2.5

local moveConnection = nil
local jumpThread = nil
local directionThread = nil
local cameraThread = nil


local function getCharacterAndHumanoid()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = character:WaitForChild("Humanoid")
    end
    return character, humanoid
end


local function rebindCharacterEvents()
    if running then
        -- если скрипт был активен, заново запустить все рутинные задачи
        stopAutoMove()
        startAutoMove()
    end
end
player.CharacterAdded:Connect(function()
    wait(0.2)
    rebindCharacterEvents()
end)

local function randomCameraTurn()
    local char = player.Character or player.CharacterAdded:Wait()
    local HRP = char:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    -- Выбираем случайно: влево или вправо, угол 25-55 градусов, время поворота ~0.6-1.5 сек (медленнее в 3 раза)
    local yaw = math.rad((math.random(0,1)==0 and 1 or -1) * math.random(25,55))
    local steps = math.random(30,60) -- в 3 раза больше шагов
    local stepAngle = yaw / steps
    local waitStep = math.random(45,105) / 100 -- 0.45..1.05 сек на весь поворот (медленнее! плавнее!)
    for i = 1, steps do
        if not running then break end
        -- Вращаем камеру вокруг персонажа
        local camCF = camera.CFrame
        local look = (HRP.Position - camCF.Position).Unit
        local up = Vector3.new(0,1,0)
        -- Вращаем не сам вектор взгляда, а камеру вокруг оси Y относительно HRP
        local dist = (camCF.Position - HRP.Position).Magnitude
        local newCF = CFrame.new(HRP.Position)
            * CFrame.Angles(0, stepAngle*i, 0)
            * CFrame.new(0, 0, dist)
        camera.CFrame = CFrame.new(newCF.Position, HRP.Position)
        wait(waitStep/steps)
    end
end

local function startCameraRoutine()
    cameraThread = coroutine.create(function()
        while running do
            local waitTime = math.random(3,7) -- от 3 до 7 секунд между поворотами
            wait(waitTime)
            if running then
                pcall(randomCameraTurn)
            end
        end
    end)
    coroutine.resume(cameraThread)
end

function startAutoMove()
    if running then return end
    running = true
    toggleButton.Text = "Выключить"
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
    local character, humanoid = getCharacterAndHumanoid()
    directionThread = coroutine.create(function()
        while running do
            wait(DIRECTION_INTERVAL)
            directionIndex = directionIndex + 1
            if directionIndex > #directions then
                directionIndex = 1
            end
        end
    end)
    coroutine.resume(directionThread)
    moveConnection = runService.RenderStepped:Connect(function()
        local _, humanoidNow = getCharacterAndHumanoid()
        if humanoidNow and humanoidNow.Health > 0 then
            humanoidNow:Move(directions[directionIndex], false)
        end
    end)
    jumpThread = coroutine.create(function()
        while running do
            local _, humanoidNow = getCharacterAndHumanoid()
            wait(JUMP_INTERVAL)
            if humanoidNow and humanoidNow.Health > 0 then
                humanoidNow.Jump = true
            end
        end
    end)
    coroutine.resume(jumpThread)
    startCameraRoutine()
end

function stopAutoMove()
    running = false
    toggleButton.Text = "Включить"
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 215, 80)
    if moveConnection then moveConnection:Disconnect() end
    moveConnection = nil
    directionThread = nil
    jumpThread = nil
    cameraThread = nil
end

toggleButton.MouseButton1Click:Connect(function()
    if running then
        stopAutoMove()
    else
        startAutoMove()
    end
end)
userInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.L then
        toggleButton:Activate()
    end
end)

local function safeHumanoidDied()
    stopAutoMove()
end
local function bindHumanoidDied()
    local _, humanoid = getCharacterAndHumanoid()
    if humanoid then
        humanoid.Died:Connect(safeHumanoidDied)
    end
end
bindHumanoidDied()
player.CharacterAdded:Connect(function()
    wait(0.1)
    bindHumanoidDied()
end)

local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(function()
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)