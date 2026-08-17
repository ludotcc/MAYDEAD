local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedConfig = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local SurvivalIconConfig = require(sharedConfig:WaitForChild("SurvivalIconConfig"))
local AlertConfig = require(sharedConfig:WaitForChild("SurvivalAlertConfig"))

local CAPSULE_WIDTH = 92
local CAPSULE_HEIGHT = 52
local CAPSULE_SPACING = 8
local ICON_SIZE = 48
local NORMAL_TEXT = Color3.fromRGB(185, 195, 205)
local HUD_TOP_OFFSET = 78
local CRITICAL_HEALTH_RATIO = 0.2

local STAT_COLORS = {
	Health = Color3.fromRGB(245, 65, 75),
	Hunger = Color3.fromRGB(245, 120, 30),
	Thirst = Color3.fromRGB(20, 155, 240),
	Energy = Color3.fromRGB(255, 190, 30),
	Breath = Color3.fromRGB(20, 205, 225),
}

local controller = {Started = false}

local function isValidAssetId(assetId)
	return typeof(assetId) == "string" and string.match(assetId, "^rbxassetid://%d+$") ~= nil
end

local function calculateHudScale()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	if viewport.X <= 600 then return 0.88 end
	if viewport.X <= 900 then return 0.94 end
	return 1
end

local function createShape(parent, size, position, color, radius, rotation)
	local shape = Instance.new("Frame")
	shape.Size = size
	shape.Position = position
	shape.BackgroundColor3 = color
	shape.BorderSizePixel = 0
	shape.Rotation = rotation or 0
	shape.ZIndex = 11
	shape.Parent = parent
	local shapeCorner = Instance.new("UICorner")
	shapeCorner.CornerRadius = UDim.new(0, radius)
	shapeCorner.Parent = shape
	return shape
end

local function buildHealthIcon(parent, color)
	createShape(parent, UDim2.fromOffset(9, 9), UDim2.fromOffset(3, 10), color, 9)
	createShape(parent, UDim2.fromOffset(9, 9), UDim2.fromOffset(11, 10), color, 9)
	createShape(parent, UDim2.fromOffset(14, 14), UDim2.fromOffset(5, 12), color, 3, 45)
end

local function buildEnergyIcon(parent, color)
	local bolt = createShape(parent, UDim2.fromOffset(8, 20), UDim2.fromOffset(8, 7), color, 1, 18)
	local cut = createShape(bolt, UDim2.fromOffset(7, 7), UDim2.fromOffset(-3, 8), Color3.fromRGB(10, 13, 20), 1, 0)
	cut.ZIndex = 12
end

local function buildFoodIcon(parent, color)
	createShape(parent, UDim2.fromOffset(11, 8), UDim2.fromOffset(6, 11), color, 5, -22)
	createShape(parent, UDim2.fromOffset(8, 3), UDim2.fromOffset(1, 19), Color3.fromRGB(225, 203, 164), 2, -22)
end

local function buildWaterIcon(parent, color)
	createShape(parent, UDim2.fromOffset(8, 8), UDim2.fromOffset(6, 14), color, 5)
	createShape(parent, UDim2.fromOffset(6, 6), UDim2.fromOffset(7, 10), color, 1, 45)
end

local function buildBreathIcon(parent, color)
	createShape(parent, UDim2.fromOffset(9, 9), UDim2.fromOffset(4, 17), color, 6)
	createShape(parent, UDim2.fromOffset(7, 7), UDim2.fromOffset(13, 10), color, 5)
	createShape(parent, UDim2.fromOffset(4, 4), UDim2.fromOffset(8, 5), color, 4)
end

local function createVignette(parent)
	local root = Instance.new("Frame")
	root.Name = "CriticalVignette"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.ZIndex = 2
	root.Parent = parent

	local edges = {}
	for _, definition in ipairs({
		{"Top", UDim2.new(1, 0, 0, 90), UDim2.fromScale(0, 0), 90},
		{"Bottom", UDim2.new(1, 0, 0, 90), UDim2.new(0, 0, 1, -90), -90},
		{"Left", UDim2.new(0, 90, 1, 0), UDim2.fromScale(0, 0), 0},
		{"Right", UDim2.new(0, 90, 1, 0), UDim2.new(1, -90, 0, 0), 180},
	}) do
		local edge = Instance.new("Frame")
		edge.Name = definition[1]
		edge.Size = definition[2]
		edge.Position = definition[3]
		edge.BackgroundColor3 = Color3.new(1, 1, 1)
		edge.BackgroundTransparency = 1
		edge.BorderSizePixel = 0
		edge.ZIndex = 2
		edge.Parent = root
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = definition[4]
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Parent = edge
		table.insert(edges, edge)
	end
	return root, edges
end

function controller:_setGameplayVisible()
	if not self.ScreenGui then return end
	local active = player:GetAttribute("SessionStarted") == true
		and player:GetAttribute("ReturningToMenu") ~= true
	self.ScreenGui.Enabled = active
	if not active then self:_resetAlerts() end
end

function controller:_resetAlerts()
	if self.ToastRevision then self.ToastRevision += 1 end
	if self.Toast then self.Toast.Visible = false end
	if self.Vignette then
		self.VignetteRevision = (self.VignetteRevision or 0) + 1
		self.VignetteActive = false
		for _, tween in ipairs(self.VignetteTweens or {}) do tween:Cancel() end
		table.clear(self.VignetteTweens or {})
		for _, edge in ipairs(self.VignetteEdges or {}) do edge.BackgroundTransparency = 1 end
		self.Vignette.Visible = false
	end
	for _, capsule in pairs(self.Capsules or {}) do
		if capsule.PulseTween then capsule.PulseTween:Cancel(); capsule.PulseTween = nil end
		capsule.IconScale.Scale = 1
		capsule.State = "Normal"
		capsule.Value.TextColor3 = NORMAL_TEXT
	end
end

function controller:_showToast(id, stateName)
	local now = os.clock()
	if now - (self.LastToastAt[id] or -math.huge) < AlertConfig.TOAST_COOLDOWN then return end
	self.LastToastAt[id] = now
	self.ToastRevision += 1
	local revision = self.ToastRevision
	local labelText = AlertConfig.LABELS[id] or (id == "Breath" and "OXYGÈNE") or id
	self.Toast.Text = id == "Energy" and stateName == "Critical"
		and "ÉNERGIE FAIBLE  •  VOUS RALENTISSEZ"
		or labelText .. (stateName == "Critical" and " CRITIQUE" or " FAIBLE")
	self.Toast.TextColor3 = AlertConfig.COLORS[id] or STAT_COLORS[id]
	self.Toast.TextTransparency = 1
	self.Toast.BackgroundTransparency = 1
	self.Toast.Visible = true
	TweenService:Create(self.Toast, TweenInfo.new(AlertConfig.TOAST_FADE_DURATION), {
		TextTransparency = 0,
		BackgroundTransparency = 0.14,
	}):Play()
	task.delay(AlertConfig.TOAST_HOLD_DURATION, function()
		if self.ToastRevision ~= revision then return end
		local fade = TweenService:Create(self.Toast, TweenInfo.new(AlertConfig.TOAST_FADE_DURATION), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		})
		fade:Play()
		fade.Completed:Once(function()
			if self.ToastRevision == revision then self.Toast.Visible = false end
		end)
	end)
end

function controller:_setCapsuleState(id, value)
	local capsule = self.Capsules[id]
	local newState = value <= AlertConfig.CRITICAL_THRESHOLD and "Critical"
		or value <= AlertConfig.WARNING_THRESHOLD and "Warning"
		or "Normal"
	if capsule.State == newState then return end
	local previousState = capsule.State
	local color = AlertConfig.COLORS[id] or capsule.AccentColor
	if capsule.PulseTween then capsule.PulseTween:Cancel(); capsule.PulseTween = nil end
	capsule.IconScale.Scale = 1
	capsule.State = newState
	TweenService:Create(capsule.Value, TweenInfo.new(AlertConfig.WARNING_TRANSITION), {
		TextColor3 = newState == "Normal" and NORMAL_TEXT or color,
	}):Play()
	if newState == "Critical" then
		capsule.PulseTween = TweenService:Create(capsule.IconScale, TweenInfo.new(
			id == "Health" and 0.8 or AlertConfig.CRITICAL_PULSE_DURATION,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true
		), {Scale = id == "Health" and 1.12 or 1.09})
		capsule.PulseTween:Play()
	end
	local worsened = newState == "Critical" or (newState == "Warning" and previousState == "Normal")
	if worsened and previousState ~= nil then self:_showToast(id, newState) end
end

function controller:_updateVignette(state)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local maxHealth = humanoid and humanoid.MaxHealth or 0
	local health = humanoid and math.min(state.Health or humanoid.Health, humanoid.Health) or 0
	local healthPercent = maxHealth > 0 and math.clamp(health / maxHealth, 0, 1) or 1
	local active = self.ScreenGui.Enabled and healthPercent <= CRITICAL_HEALTH_RATIO
	if self.VignetteActive == active then return end

	self.VignetteActive = active
	self.VignetteRevision += 1
	local revision = self.VignetteRevision
	for _, tween in ipairs(self.VignetteTweens) do tween:Cancel() end
	table.clear(self.VignetteTweens)
	self.Vignette:SetAttribute("ActiveAlert", active and "Health" or "None")
	if active then self.Vignette.Visible = true end
	for _, edge in ipairs(self.VignetteEdges) do
		edge.BackgroundColor3 = AlertConfig.COLORS.Health
		local tween = TweenService:Create(
			edge,
			TweenInfo.new(active and 0.22 or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = active and 0.84 or 1}
		)
		table.insert(self.VignetteTweens, tween)
		tween:Play()
	end
	if not active then
		local finalTween = self.VignetteTweens[1]
		finalTween.Completed:Once(function()
			if self.VignetteRevision == revision and not self.VignetteActive then
				self.Vignette.Visible = false
			end
		end)
	end
end

function controller:_updateHud(state)
	for _, id in ipairs({"Energy", "Health", "Hunger", "Thirst"}) do
		local value = state[id] or 0
		local capsule = self.Capsules[id]
		local ratio = math.clamp(value / 100, 0, 1)
		capsule.Value.Text = tostring(math.floor(ratio * 100 + 0.5)) .. "%"
		TweenService:Create(capsule.FillClip, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(1, ratio),
		}):Play()
		self:_setCapsuleState(id, value)
	end
	local breath = state.Breath or 100
	local breathCapsule = self.Capsules.Breath
	local breathRatio = math.clamp(breath / 100, 0, 1)
	breathCapsule.Value.Text = tostring(math.floor(breathRatio * 100 + 0.5)) .. "%"
	TweenService:Create(breathCapsule.FillClip, TweenInfo.new(0.18), {Size = UDim2.fromScale(1, breathRatio)}):Play()
	if state.Underwater == true then
		self.BreathRevision += 1
		breathCapsule.Frame.Visible = true
	else
		self.BreathRevision += 1
		local revision = self.BreathRevision
		task.delay(1, function()
			if self.BreathRevision == revision then breathCapsule.Frame.Visible = false end
		end)
	end
	self:_setCapsuleState("Breath", breath)
	self:_updateVignette(state)
end

function controller:_createCapsule(root, id, iconBuilder)
	local accentColor = STAT_COLORS[id]
	local capsule = Instance.new("Frame")
	capsule.Name = id .. "Capsule"
	capsule.Size = UDim2.fromOffset(CAPSULE_WIDTH, CAPSULE_HEIGHT)
	capsule.BackgroundTransparency = 1
	capsule.BorderSizePixel = 0
	capsule.ZIndex = 10
	capsule.Parent = root

	local iconRoot = Instance.new("Frame")
	iconRoot.Name = id .. "Icon"
	iconRoot.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
	iconRoot.Position = UDim2.fromOffset(0, 2)
	iconRoot.BackgroundTransparency = 1
	iconRoot.Parent = capsule
	local iconScale = Instance.new("UIScale")
	iconScale.Parent = iconRoot
	local imageAssetId = SurvivalIconConfig[id]
	local function createIconLayer(parent, color, name)
		local layer = Instance.new("Frame")
		layer.Name = name
		layer.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
		layer.BackgroundTransparency = 1
		layer.Parent = parent
		if isValidAssetId(imageAssetId) then
			local image = Instance.new("ImageLabel")
			image.Size = UDim2.fromScale(1, 1)
			image.BackgroundTransparency = 1
			image.Image = imageAssetId
			image.ImageColor3 = color
			image.ScaleType = Enum.ScaleType.Fit
			image.ZIndex = 11
			image.Parent = layer
		else
			local visual = Instance.new("Frame")
			visual.Size = UDim2.fromOffset(27, 27)
			visual.Position = UDim2.fromScale(0.5, 0.5)
			visual.AnchorPoint = Vector2.new(0.5, 0.5)
			visual.BackgroundTransparency = 1
			visual.Parent = layer
			iconBuilder(visual, color)
		end
		return layer
	end

	createIconLayer(iconRoot, accentColor:Lerp(Color3.fromRGB(70, 76, 84), 0.72), "IconBase")
	local fillClip = Instance.new("Frame")
	fillClip.Name = "FillClip"
	fillClip.Size = UDim2.fromScale(1, 1)
	fillClip.Position = UDim2.fromScale(0, 1)
	fillClip.AnchorPoint = Vector2.new(0, 1)
	fillClip.BackgroundTransparency = 1
	fillClip.ClipsDescendants = true
	fillClip.Parent = iconRoot
	local brightLayer = createIconLayer(fillClip, accentColor, "IconBright")
	brightLayer.Position = UDim2.new(0, 0, 1, -ICON_SIZE)

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.fromOffset(40, 24)
	valueLabel.Position = UDim2.new(1, -40, 0.5, -12)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "0%"
	valueLabel.TextColor3 = Color3.fromRGB(205, 215, 225)
	valueLabel.TextTransparency = 0.08
	valueLabel.Font = Enum.Font.GothamMedium
	valueLabel.TextSize = 12
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.ZIndex = 12
	valueLabel.Parent = capsule
	self.Capsules[id] = {
		Frame = capsule,
		Value = valueLabel,
		FillClip = fillClip,
		IconScale = iconScale,
		AccentColor = accentColor,
	}
end

function controller:_build()
	local existing = playerGui:FindFirstChild("MAYDEADSurvivalHUD")
	if existing then existing:Destroy() end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MAYDEADSurvivalHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	screenGui.DisplayOrder = 10
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.Parent = playerGui
	self.ScreenGui = screenGui
	self.Capsules = {}
	self.LastToastAt = {}
	self.ToastRevision = 0
	self.BreathRevision = 0
	self.Vignette, self.VignetteEdges = createVignette(screenGui)
	self.VignetteTweens = {}
	self.VignetteRevision = 0
	self.VignetteActive = false

	local toast = Instance.new("TextLabel")
	toast.Name = "SurvivalAlertToast"
	toast.Size = UDim2.fromOffset(280, 34)
	toast.Position = UDim2.new(0.5, 0, 0, 62)
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.BackgroundColor3 = Color3.fromRGB(10, 14, 21)
	toast.BackgroundTransparency = 1
	toast.TextTransparency = 1
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 12
	toast.Visible = false
	toast.ZIndex = 30
	toast.Parent = screenGui
	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 11)
	toastCorner.Parent = toast
	self.Toast = toast

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromOffset(CAPSULE_WIDTH, (CAPSULE_HEIGHT * 5) + (CAPSULE_SPACING * 4))
	root.Position = UDim2.new(0, 16, 0, HUD_TOP_OFFSET)
	root.BackgroundTransparency = 1
	root.ZIndex = 10
	root.Parent = screenGui
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = calculateHudScale()
	uiScale.Parent = root
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, CAPSULE_SPACING)
	layout.Parent = root

	self:_createCapsule(root, "Energy", buildEnergyIcon)
	self:_createCapsule(root, "Health", buildHealthIcon)
	self:_createCapsule(root, "Hunger", buildFoodIcon)
	self:_createCapsule(root, "Thirst", buildWaterIcon)
	self:_createCapsule(root, "Breath", buildBreathIcon)
	self.Capsules.Breath.Frame.Visible = false

	local camera = workspace.CurrentCamera
	if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() uiScale.Scale = calculateHudScale() end) end
	ReplicatedStorage:WaitForChild("SurvivalStateChanged").OnClientEvent:Connect(function(state)
		if typeof(state) == "table" then self:_updateHud(state) end
	end)
	player:GetAttributeChangedSignal("SessionStarted"):Connect(function() self:_setGameplayVisible() end)
	player:GetAttributeChangedSignal("ReturningToMenu"):Connect(function() self:_setGameplayVisible() end)
	player.CharacterAdded:Connect(function() self:_resetAlerts() end)
	self:_setGameplayVisible()
end

function controller:Start()
	if self.Started then return end
	self.Started = true
	local ok, buildError = xpcall(function() self:_build() end, debug.traceback)
	if not ok then error("[MAYDEAD] Survival HUD ERROR: " .. tostring(buildError), 0) end
end

return controller
