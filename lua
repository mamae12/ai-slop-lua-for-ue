local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local systemEnabled = false
local intensity = 105.0
local minIntensity = 1
local maxIntensity = 260

local toggleKey = Enum.KeyCode.P
local changingKey = false

local lastMove = 0
local patternSeed = tick()
local voidCooldown = 0
local spikeCooldown = 0

local pos = Vector2.new(math.random(310, 490), math.random(150, 310))
local dragging = false
local sliderDragging = false
local dragStart = Vector2.zero
local startPos = Vector2.zero

-- UI Colors
local darkP = Color3.fromRGB(13, 4, 28)
local medP = Color3.fromRGB(36, 13, 58)
local lightP = Color3.fromRGB(88, 40, 155)
local accentP = Color3.fromRGB(135, 70, 210)
local glowP = Color3.fromRGB(175, 110, 240)

local function NewSquare(x, y, w, h, color, trans)
    local sq = Drawing.new("Square")
    sq.Position = Vector2.new(x, y)
    sq.Size = Vector2.new(w, h)
    sq.Color = color
    sq.Filled = true
    sq.Transparency = trans or 0.86
    sq.Visible = true
    return sq
end

local function NewText(text, size, x, y, color)
    local txt = Drawing.new("Text")
    txt.Text = text
    txt.Size = size
    txt.Position = Vector2.new(x, y)
    txt.Color = color
    txt.Outline = true
    txt.OutlineColor = Color3.new(0, 0, 0)
    txt.Font = 2
    txt.Visible = true
    return txt
end

local function InBox(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

-- Create UI
local bg1 = NewSquare(pos.X, pos.Y, 435, 325, darkP, 0.83)
local bg2 = NewSquare(pos.X + 8, pos.Y + 8, 419, 309, medP, 0.87)
local topBar = NewSquare(pos.X, pos.Y, 435, 74, accentP, 0.84)
local glowBar = NewSquare(pos.X, pos.Y, 435, 10, glowP, 0.55)

local titleText = NewText("LETHALWARE", 24, pos.X + 34, pos.Y + 18, glowP)
local versionText = NewText("HYPERSPIN v18 - 10X", 14, pos.X + 34, pos.Y + 50, lightP)

local toggleButton = NewSquare(pos.X + 30, pos.Y + 92, 375, 66, medP)
local toggleLabel = NewText("SYSTEM OFFLINE", 17, pos.X + 145, pos.Y + 110, Color3.new(1, 0.3, 0.3))

local keyButton = NewSquare(pos.X + 30, pos.Y + 170, 375, 50, darkP)
local keyLabel = NewText("Hotkey: P [Click to change]", 13, pos.X + 48, pos.Y + 183, accentP)

local intensityLabel = NewText("Intensity: " .. intensity, 15, pos.X + 36, pos.Y + 235, Color3.new(0.95, 0.88, 1))
local sliderTrack = NewSquare(pos.X + 30, pos.Y + 260, 375, 28, Color3.new(0.02, 0.005, 0.06))
local sliderFill = NewSquare(pos.X + 30, pos.Y + 260, 0, 28, lightP)
local sliderHandle = NewSquare(pos.X + 25, pos.Y + 255, 34, 38, Color3.new(1,1,1))

local statusLabel = NewText("LethalWare Voiding.", 13, pos.X + 38, pos.Y + 298, Color3.fromRGB(130, 255, 170))

local dots = 1
local function UpdateStatus()
    if not systemEnabled then
        statusLabel.Text = "Status: Standby"
        statusLabel.Color = Color3.fromRGB(160,160,160)
        return
    end
    dots = (dots % 3) + 1
    statusLabel.Text = "LethalWare Voiding" .. string.rep(".", dots)
    statusLabel.Color = Color3.fromRGB(110, 255, 150)
end

local function UpdateSlider()
    local percent = math.clamp((intensity - minIntensity) / (maxIntensity - minIntensity), 0, 1)
    local fillWidth = 375 * percent
    sliderFill.Size = Vector2.new(fillWidth, 28)
    sliderHandle.Position = Vector2.new(pos.X + 30 + fillWidth - 17, pos.Y + 255)
    intensityLabel.Text = "Intensity: " .. string.format("%.1f", intensity)
end

local function UpdateUI()
    if systemEnabled then
        toggleButton.Color = lightP
        toggleLabel.Text = "GOD MODE ACTIVE"
        toggleLabel.Color = Color3.fromRGB(120, 255, 190)
    else
        toggleButton.Color = medP
        toggleLabel.Text = "SYSTEM OFFLINE"
        toggleLabel.Color = Color3.fromRGB(255, 55, 55)
    end
end

local function UpdateKeyText()
    if changingKey then
        keyLabel.Text = ">>> PRESS ANY KEY <<<"
        keyLabel.Color = Color3.fromRGB(255, 220, 100)
    else
        local name = tostring(toggleKey):gsub("Enum.KeyCode.", "")
        keyLabel.Text = "Hotkey: " .. name .. " [Click to change]"
        keyLabel.Color = accentP
    end
end

-- ==================== MOVEMENT ====================
local function ExtremeMouseMove()
    local now = tick()
    if now - lastMove < (math.random(1,3)/2700) then return end
    lastMove = now

    local chaos = intensity * 0.48
    local dx = math.noise(tick()*48) * chaos + (math.random()-0.5)*intensity*1.3
    local dy = math.noise(tick()*55) * chaos + (math.random()-0.5)*intensity*1.25

    if mousemoverel then pcall(mousemoverel, dx, dy)
    elseif mouse1move then pcall(mouse1move, dx, dy) end
end

local function HyperVoid(root)
    if not root then return end
    if tick() - voidCooldown < 0.028 then return end
    voidCooldown = tick()
    root.CFrame = CFrame.new(
        root.Position.X + math.random(-58000,58000),
        5500 + math.random(-30000,39000),
        root.Position.Z + math.random(-58000,58000)
    )
end

local function FakeSpike(root)
    if not root then return end
    if tick() - spikeCooldown < 1.8 then return end
    if math.random() > 0.65 then return end
    spikeCooldown = tick()
    local orig = root.CFrame
    root.CFrame = CFrame.new(root.Position.X + math.random(-65000,65000), 4200 + math.random(-29000,37000), root.Position.Z + math.random(-65000,65000))
    task.delay(0.07, function() if root and orig then root.CFrame = orig end end)
end

local function GodDesync(root)
    if not root then return end
    root.CFrame = root.CFrame * CFrame.Angles(math.rad(math.random(-60,60)), math.rad(math.random(-95,95)), math.rad(math.random(-45,45)))
    root.CFrame += Vector3.new(math.random(-500,500)/90, math.random(-170,230)/90, math.random(-500,500)/90)
    root.AssemblyLinearVelocity = Vector3.new(math.random(-210,210), root.AssemblyLinearVelocity.Y + math.random(-70,100), math.random(-210,210))
end

-- ==================== INPUT ====================
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    local mousePos = UIS:GetMouseLocation()

    if changingKey then
        if input.KeyCode.Name ~= "Unknown" then
            toggleKey = input.KeyCode
            changingKey = false
            UpdateKeyText()
        end
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if InBox(mousePos.X, mousePos.Y, pos.X, pos.Y, 435, 74) then
            dragging = true
            dragStart = mousePos
            startPos = pos
        elseif InBox(mousePos.X, mousePos.Y, pos.X+30, pos.Y+92, 375, 66) then
            systemEnabled = not systemEnabled
        elseif InBox(mousePos.X, mousePos.Y, pos.X+30, pos.Y+170, 375, 50) then
            changingKey = true
            UpdateKeyText()
        elseif InBox(mousePos.X, mousePos.Y, pos.X+30, pos.Y+260, 375, 40) then
            sliderDragging = true
        end
    end

    if input.KeyCode == toggleKey then
        systemEnabled = not systemEnabled
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        sliderDragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    local mousePos = UIS:GetMouseLocation()
    if dragging then
        pos = startPos + (mousePos - dragStart)
    elseif sliderDragging then
        local relative = math.clamp((mousePos.X - (pos.X + 30)) / 375, 0, 1)
        intensity = minIntensity + (maxIntensity - minIntensity) * relative
    end
end)

-- ==================== MAIN LOOP ====================
local frame = 0

RunService.RenderStepped:Connect(function()
    -- UI Position Update
    bg1.Position = pos
    bg2.Position = pos + Vector2.new(8,8)
    topBar.Position = pos
    glowBar.Position = pos
    titleText.Position = pos + Vector2.new(34,18)
    versionText.Position = pos + Vector2.new(34,50)
    toggleButton.Position = pos + Vector2.new(30,92)
    toggleLabel.Position = pos + Vector2.new(145,110)
    keyButton.Position = pos + Vector2.new(30,170)
    keyLabel.Position = pos + Vector2.new(48,183)
    intensityLabel.Position = pos + Vector2.new(36,235)
    sliderTrack.Position = pos + Vector2.new(30,260)
    sliderFill.Position = pos + Vector2.new(30,260)
    statusLabel.Position = pos + Vector2.new(38,298)

    UpdateSlider()
    UpdateUI()
    UpdateKeyText()
    UpdateStatus()

    if not systemEnabled then return end

    frame += 1
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local nearby = 0 -- Simplified for stability
    local realIntensity = intensity + (nearby * 32)

    if frame % math.random(1,3) == 0 then HyperVoid(root) end
    if frame % 2 == 0 then GodDesync(root) end
    if frame % 3 == 0 then FakeSpike(root) end

    ExtremeMouseMove()
    if frame % 2 == 0 then ExtremeMouseMove() end

    if realIntensity > 150 and frame % 2 == 0 then
        for i = 1, 3 do ExtremeMouseMove() end
    end

    if frame % 220 == 0 then
        patternSeed = tick()
    end
end)

print("LethalWare HyperSpin v18 Loaded - Toggle should work now")
