local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

local systemEnabled = false
local intensity = 320
local minIntensity = 1
local maxIntensity = 320

local toggleKey = Enum.KeyCode.P
local changingKey = false

local lastMove = 0
local patternSeed = tick()
local voidCooldown = 0
local spikeCooldown = 0

local pos = Vector2.new(math.random(310, 490), math.random(140, 300))
local dragging = false
local sliderDragging = false
local dragStart = Vector2.zero
local startPos = Vector2.zero

-- UI
local darkP = Color3.fromRGB(10, 2, 22)
local medP = Color3.fromRGB(30, 9, 50)
local lightP = Color3.fromRGB(95, 45, 170)
local accentP = Color3.fromRGB(145, 75, 235)
local glowP = Color3.fromRGB(190, 125, 255)

local function NewSquare(x,y,w,h,c,t) local s = Drawing.new("Square") s.Position = Vector2.new(x,y) s.Size = Vector2.new(w,h) s.Color = c s.Filled = true s.Transparency = t or 0.84 s.Visible = true return s end
local function NewText(txt, size, x, y, c) local t = Drawing.new("Text") t.Text = txt t.Size = size t.Position = Vector2.new(x,y) t.Color = c t.Outline = true t.OutlineColor = Color3.new(0,0,0) t.Font = 2 t.Visible = true return t end
local function InBox(px,py,x,y,w,h) return px>=x and px<=x+w and py>=y and py<=y+h end

local bg1 = NewSquare(pos.X, pos.Y, 445, 335, darkP, 0.81)
local bg2 = NewSquare(pos.X+9, pos.Y+9, 427, 317, medP, 0.86)
local top = NewSquare(pos.X, pos.Y, 445, 78, accentP, 0.83)
local glow = NewSquare(pos.X, pos.Y, 445, 12, glowP, 0.5)

local title = NewText("LETHALWARE", 26, pos.X+36, pos.Y+19, glowP)
local sub = NewText("V3", 16.5, pos.X+36, pos.Y+53, lightP)

local toggleBg = NewSquare(pos.X+32, pos.Y+95, 382, 70, medP)
local toggleTxt = NewText("SYSTEM OFFLINE", 18, pos.X+152, pos.Y+113, Color3.new(1,0.3,0.3))

local keyBg = NewSquare(pos.X+32, pos.Y+180, 382, 54, darkP)
local keyTxt = NewText("Hotkey: P [Click to change]", 13, pos.X+50, pos.Y+194, accentP)

local intLabel = NewText("Intensity: "..intensity, 15, pos.X+38, pos.Y+245, Color3.new(0.96,0.9,1))
local sliderBg = NewSquare(pos.X+32, pos.Y+270, 382, 30, Color3.new(0.015,0.003,0.05))
local sliderFill = NewSquare(pos.X+32, pos.Y+270, 0, 30, lightP)
local sliderKnob = NewSquare(pos.X+27, pos.Y+265, 38, 42, Color3.new(1,1,1))

local status = NewText("LethalWare Voiding.", 13.5, pos.X+42, pos.Y+310, Color3.fromRGB(130,255,170))

local dots = 1
local function UpdateStatus()
    if not systemEnabled then
        status.Text = "Status: Standby"
        status.Color = Color3.fromRGB(160,160,160)
        return
    end
    dots = (dots % 3) + 1
    status.Text = "LethalWare Voiding" .. string.rep(".", dots)
    status.Color = Color3.fromRGB(110,255,150)
end

local function UpdateSlider()
    local p = math.clamp((intensity - minIntensity) / (maxIntensity - minIntensity), 0, 1)
    local w = 382 * p
    sliderFill.Size = Vector2.new(w, 30)
    sliderKnob.Position = Vector2.new(pos.X + 32 + w - 19, pos.Y + 265)
    intLabel.Text = "Intensity: " .. string.format("%.1f", intensity)
end

local function UpdateUI()
    if systemEnabled then
        toggleBg.Color = lightP
        toggleTxt.Text = "ORBIT GOD MODE"
        toggleTxt.Color = Color3.fromRGB(120,255,190)
    else
        toggleBg.Color = medP
        toggleTxt.Text = "SYSTEM OFFLINE"
        toggleTxt.Color = Color3.fromRGB(255,55,55)
    end
end

local function UpdateKeyText()
    if changingKey then
        keyTxt.Text = ">>> PRESS ANY KEY <<<"
        keyTxt.Color = Color3.fromRGB(255,220,100)
    else
        local name = tostring(toggleKey):gsub("Enum.KeyCode.", "")
        keyTxt.Text = "Hotkey: " .. name .. " [Click to change]"
        keyTxt.Color = accentP
    end
end

-- ==================== ORBIT + SPACE SPAM + 10X CHAOS ====================
local function GetNearbyThreats()
    local count = 0
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return 0 end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r and (r.Position - myRoot.Position).Magnitude < 95 then count += 1 end
        end
    end
    return count
end

local function HyperVoid(root)
    if tick() - voidCooldown < 0.016 then return end
    voidCooldown = tick()
    root.CFrame = CFrame.new(
        root.Position.X + math.random(-70000,70000),
        4200 + math.random(-35000,42000),
        root.Position.Z + math.random(-70000,70000)
    )
end

local function FakeSpike(root)
    if tick() - spikeCooldown < 1.3 then return end
    if math.random() > 0.72 then return end
    spikeCooldown = tick()
    local orig = root.CFrame
    root.CFrame = CFrame.new(root.Position.X + math.random(-75000,75000), 3200 + math.random(-33000,40000), root.Position.Z + math.random(-75000,75000))
    task.delay(0.055, function() if root and orig then root.CFrame = orig end end)
end

local function GodDesync(root)
    if not root then return end
    root.CFrame = root.CFrame * CFrame.Angles(math.rad(math.random(-65,65)), math.rad(math.random(-105,105)), 0)
    root.CFrame += Vector3.new(math.random(-550,550)/85, math.random(-180,240)/85, math.random(-550,550)/85)
    root.AssemblyLinearVelocity = Vector3.new(math.random(-235,235), root.AssemblyLinearVelocity.Y + math.random(-80,110), math.random(-235,235))
end

local function ExtremeMouseMove()
    local now = tick()
    if now - lastMove < (math.random(1,3)/2900) then return end
    lastMove = now

    local chaos = intensity * 0.58
    local dx = math.noise(tick()*52) * chaos + (math.random()-0.5)*intensity*1.7
    local dy = math.noise(tick()*59) * chaos + (math.random()-0.5)*intensity*1.65

    if mousemoverel then pcall(mousemoverel, dx, dy)
    elseif mouse1move then pcall(mouse1move, dx, dy) end
end

local function OrbitSpin(realIntensity)
    local t = tick() * 7.2
    local base = realIntensity * 34

    local orbitX = math.cos(t * 19) * base * 1.1
    local orbitY = math.sin(t * 24) * base * 1.05
    local chaosX = math.noise(t*48) * realIntensity * 1.8
    local chaosY = math.noise(t*55) * realIntensity * 1.7

    ExtremeMouseMove = function()
        local now = tick()
        if now - lastMove < (math.random(1,3)/2900) then return end
        lastMove = now
        if mousemoverel then
            pcall(mousemoverel, orbitX + chaosX, orbitY + chaosY)
        elseif mouse1move then
            pcall(mouse1move, orbitX + chaosX, orbitY + chaosY)
        end
    end
    ExtremeMouseMove()
end

-- SPACE BAR SPAM
local spaceSpamConnection
local function StartSpaceSpam()
    if spaceSpamConnection then return end
    spaceSpamConnection = RunService.RenderStepped:Connect(function()
        if not systemEnabled then return end
        if math.random() < 0.65 then
            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.03)
            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end)
end

local function StopSpaceSpam()
    if spaceSpamConnection then
        spaceSpamConnection:Disconnect()
        spaceSpamConnection = nil
    end
end

-- ==================== INPUT ====================
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    local m = UIS:GetMouseLocation()

    if changingKey then
        if i.KeyCode.Name ~= "Unknown" then
            toggleKey = i.KeyCode
            changingKey = false
            UpdateKeyText()
        end
        return
    end

    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        if InBox(m.X, m.Y, pos.X, pos.Y, 445, 78) then
            dragging = true
            dragStart = m
            startPos = pos
        elseif InBox(m.X, m.Y, pos.X+32, pos.Y+95, 382, 70) then
            systemEnabled = not systemEnabled
        elseif InBox(m.X, m.Y, pos.X+32, pos.Y+180, 382, 54) then
            changingKey = true
            UpdateKeyText()
        elseif InBox(m.X, m.Y, pos.X+32, pos.Y+265, 382, 48) then
            sliderDragging = true
        end
    end

    if i.KeyCode == toggleKey then
        systemEnabled = not systemEnabled
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        sliderDragging = false
    end
end)

UIS.InputChanged:Connect(function(i)
    local m = UIS:GetMouseLocation()
    if dragging then
        pos = startPos + (m - dragStart)
    elseif sliderDragging then
        local rel = math.clamp((m.X - (pos.X + 32)) / 382, 0, 1)
        intensity = minIntensity + (maxIntensity - minIntensity) * rel
    end
end)

-- ==================== MAIN LOOP ====================
local frame = 0

RunService.RenderStepped:Connect(function()
    bg1.Position = pos
    bg2.Position = pos + Vector2.new(9,9)
    top.Position = pos
    glow.Position = pos
    title.Position = pos + Vector2.new(36,19)
    sub.Position = pos + Vector2.new(36,53)
    toggleBg.Position = pos + Vector2.new(32,95)
    toggleTxt.Position = pos + Vector2.new(152,113)
    keyBg.Position = pos + Vector2.new(32,180)
    keyTxt.Position = pos + Vector2.new(50,194)
    intLabel.Position = pos + Vector2.new(38,245)
    sliderBg.Position = pos + Vector2.new(32,270)
    sliderFill.Position = pos + Vector2.new(32,270)
    status.Position = pos + Vector2.new(42,310)

    UpdateSlider()
    UpdateUI()
    UpdateKeyText()
    UpdateStatus()

    if systemEnabled then
        StartSpaceSpam()
    else
        StopSpaceSpam()
    end

    if not systemEnabled then return end

    frame += 1
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local nearby = GetNearbyThreats()
    local realIntensity = intensity + (nearby * 48)

    if frame % math.random(1,2) == 0 then HyperVoid(root) end
    if frame % 2 == 0 then GodDesync(root) end
    if frame % 3 == 0 then FakeSpike(root) end

    OrbitSpin(realIntensity)

    if realIntensity > 200 and frame % 2 == 0 then
        for _ = 1, 5 do OrbitSpin(realIntensity) end
    end

    if frame % 160 == 0 then
        patternSeed = tick()
    end
end)
