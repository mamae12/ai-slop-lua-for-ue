local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- SETTINGS
local systemEnabled = false  -- Single toggle for both spin and void
local intensity = 250.0
local minIntensity = 1.0
local maxIntensity = 500.0
local toggleKey = Enum.KeyCode.P
local changingKey = false

-- UI STATE
local pos = Vector2.new(300,200)
local dragging = false
local sliderDragging = false
local dragStart = Vector2.zero
local startPos = Vector2.zero
local frameW, frameH = 350, 220

-- PURPLE GRADIENT COLORS
local darkPurple = Color3.fromRGB(45, 25, 65)
local medPurple = Color3.fromRGB(80, 50, 120)
local lightPurple = Color3.fromRGB(120, 80, 180)
local accentPurple = Color3.fromRGB(160, 120, 220)

-- DRAWING WITH GRADIENTS
local function GradientBox(x,y,w,h,c1,c2)
	local d = Drawing.new("Square")
	d.Position = Vector2.new(x,y)
	d.Size = Vector2.new(w,h)
	d.Color = c1
	d.Filled = true
	d.Thickness = 0
	d.Visible = true
	d.Transparency = 0.1
	return d
end

local function SmoothText(t,s,x,y,c)
	local d = Drawing.new("Text")
	d.Text = t
	d.Size = s
	d.Position = Vector2.new(x,y)
	d.Color = c
	d.Outline = true
	d.OutlineColor = Color3.fromRGB(20,10,30)
	d.Font = 3
	d.Visible = true
	return d
end

local function InBox(x,y,w,h,p)
	return p.X>=x and p.X<=x+w and p.Y>=y and p.Y<=y+h
end

local function GetPos(i)
	if i.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(i.Position.X,i.Position.Y)
	end
	return UIS:GetMouseLocation()
end

-- MOUSE SIMULATION
local function SafeMouseMove(x, y)
    if mousemoverel then
        pcall(mousemoverel, x, y)
    elseif rawget(getfenv(0), "mousemoverel") then
        pcall(rawget(getfenv(0), "mousemoverel"), x, y)
    end
end

-- CONTINUOUS VOID
local function ContinuousVoid()
    if not systemEnabled then return end
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local randomX = math.random(-10000, 10000)
    local randomZ = math.random(-10000, 10000)
    root.CFrame = CFrame.new(randomX, math.huge, randomZ)
end

-- SMOOTH PURPLE GRADIENT UI
local bg = GradientBox(pos.X,pos.Y,frameW,frameH,darkPurple,medPurple)
local topBar = GradientBox(pos.X,pos.Y,frameW,40,medPurple,lightPurple)
local title = SmoothText("lethalWare UE Lua",18,pos.X+20,pos.Y+12,accentPurple)

-- SINGLE TOGGLE BUTTON (for both spin and void)
local toggleBtn = GradientBox(pos.X+20,pos.Y+60,310,40,medPurple,lightPurple)
local toggleText = SmoothText("SYSTEM OFF",18,pos.X+140,pos.Y+74,Color3.fromRGB(255,255,255))

-- KEYBIND CHANGER
local keyBtn = GradientBox(pos.X+20,pos.Y+120,310,30,darkPurple,medPurple)
local keyText = SmoothText("Toggle Key: P [CLICK TO CHANGE]",12,pos.X+30,pos.Y+130,accentPurple)

-- INTENSITY SLIDER
local intensityLabel = SmoothText("Intensity: "..string.format("%.1f", intensity),14,pos.X+20,pos.Y+160,Color3.fromRGB(220,200,255))
local sliderTrack = GradientBox(pos.X+20,pos.Y+180,310,12,darkPurple,medPurple)
local sliderFill = GradientBox(pos.X+20,pos.Y+180,0,12,lightPurple,accentPurple)
local sliderHandle = GradientBox(pos.X+20,pos.Y+178,16,16,Color3.fromRGB(255,255,255),accentPurple)

-- UPDATE FUNCTIONS
local function UpdateSlider()
	local percent = (intensity - minIntensity) / (maxIntensity - minIntensity)
	local fillWidth = 310 * percent
	local handlePos = 310 * percent
	
	sliderFill.Size = Vector2.new(fillWidth, 12)
	sliderHandle.Position = Vector2.new(pos.X + 20 + handlePos - 8, pos.Y + 178)
	intensityLabel.Text = "Intensity: "..string.format("%.1f", intensity).." / "..maxIntensity
end

local function UpdateKeyText()
	local keyName = string.gsub(tostring(toggleKey), "Enum.KeyCode.", "")
	keyText.Text = changingKey and "Press any key..." or ("Toggle Key: "..keyName.." [CLICK TO CHANGE]")
	keyText.Color = changingKey and Color3.fromRGB(255,200,100) or accentPurple
end

-- INPUT HANDLING
UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	local p = GetPos(input)
	
	if changingKey then
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			toggleKey = input.KeyCode
			changingKey = false
			UpdateKeyText()
		end
		return
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Title bar drag
		if InBox(pos.X,pos.Y,frameW,40,p) then
			dragging = true
			dragStart = p
			startPos = pos
		-- Single toggle button (controls both spin and void)
		elseif InBox(pos.X+20,pos.Y+60,310,40,p) then
			systemEnabled = not systemEnabled
		-- Key changer
		elseif InBox(pos.X+20,pos.Y+120,310,30,p) then
			changingKey = true
			UpdateKeyText()
		-- Slider
		elseif InBox(pos.X+20,pos.Y+178,310,16,p) then
			sliderDragging = true
		end
	end
	
	-- Toggle hotkey
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
	local p = GetPos(input)
	
	if dragging then
		pos = startPos + (p - dragStart)
	elseif sliderDragging then
		local sliderX = p.X - (pos.X + 20)
		local percent = math.clamp(sliderX / 310, 0, 1)
		intensity = minIntensity + (maxIntensity - minIntensity) * percent
	end
end)

-- MAIN LOOP
local voidTimer = 0

RunService.RenderStepped:Connect(function()
	-- Update all UI positions
	bg.Position = pos
	topBar.Position = pos
	title.Position = pos + Vector2.new(20,12)
	
	toggleBtn.Position = pos + Vector2.new(20,60)
	toggleText.Position = pos + Vector2.new(140,74)
	
	keyBtn.Position = pos + Vector2.new(20,120)
	keyText.Position = pos + Vector2.new(30,130)
	
	intensityLabel.Position = pos + Vector2.new(20,160)
	sliderTrack.Position = pos + Vector2.new(20,180)
	sliderFill.Position = pos + Vector2.new(20,180)
	
	-- Update single toggle button state
	if systemEnabled then
		toggleBtn.Color = lightPurple
		toggleText.Text = "SYSTEM ON - SPINNING + VOID"
		toggleText.Color = Color3.fromRGB(100,255,100)
	else
		toggleBtn.Color = medPurple
		toggleText.Text = "SYSTEM OFF"
		toggleText.Color = Color3.fromRGB(255,100,100)
	end
	
	UpdateSlider()
	UpdateKeyText()
	
	-- CONTINUOUS VOID (when system enabled)
	if systemEnabled then
		voidTimer = voidTimer + 1
		if voidTimer >= 3 then -- Every 3 frames
			ContinuousVoid()
			voidTimer = 0
		end
	end
	
	-- HYPER SPIN (when system enabled)
	if systemEnabled then
		local currentTime = tick()
		
		-- INSANE SPEED MULTIPLIERS
		local baseSpeed = intensity * 1000 -- Maximum chaos
		
		-- Multi-directional chaos spinning
		local horizontalSpeed = baseSpeed * (1 + math.sin(currentTime * 20))
		local verticalSpeed = math.sin(currentTime * intensity * 15) * intensity * 400
		local diagonalSpeed = math.cos(currentTime * intensity * 12) * intensity * 300
		
		-- Apply all movements simultaneously
		SafeMouseMove(horizontalSpeed * 0.016, 0) -- Horizontal
		SafeMouseMove(0, verticalSpeed * 0.016) -- Vertical
		SafeMouseMove(diagonalSpeed * 0.016, diagonalSpeed * 0.016) -- Diagonal
		
		-- EXTREME CHAOS at high intensity
		if intensity > 50 then
			local chaosX = (math.random() - 0.5) * intensity * 100
			local chaosY = (math.random() - 0.5) * intensity * 100
			SafeMouseMove(chaosX * 0.016, chaosY * 0.016)
		end
	end
end)

print("🌪️ HYPER SPIN + VOID SYSTEM LOADED 🌪️")
print("🎮 Single Toggle: P (click to change)")
print("💜 One Button Controls Both Spin + Void!")
print("⚡ Max Speed: ABSOLUTELY INSANE!")
