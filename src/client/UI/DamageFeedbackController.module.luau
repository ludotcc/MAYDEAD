local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local REMOTE_NAME = "DamageFeedback"
local MAX_FLOATING_NUMBERS = 12

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)

local DamageFeedbackController = {
	_started = false,
	_edges = {},
	_edgeTweens = {},
	_floating = {},
	_shakeTweens = {},
	_takenGeneration = 0,
}

local function addEdgeGradient(frame, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = frame
end

function DamageFeedbackController:_createGui()
	local existing = playerGui:FindFirstChild("MAYDEADDamageFeedback")
	if existing then
		existing:Destroy()
	end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MAYDEADDamageFeedback"
	screenGui.DisplayOrder = 90
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local impactLayer = Instance.new("Frame")
	impactLayer.Name = "TakenImpactLayer"
	impactLayer.Size = UDim2.fromScale(1, 1)
	impactLayer.BackgroundTransparency = 1
	impactLayer.BorderSizePixel = 0
	impactLayer.Parent = screenGui

	local flash = Instance.new("Frame")
	flash.Name = "ImpactFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(205, 54, 58)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 1
	flash.Parent = impactLayer

	local definitions = {
		{Name = "Top", Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.fromScale(0, 0), Rotation = 90},
		{Name = "Bottom", Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.fromScale(0, 0.88), Rotation = 270},
		{Name = "Left", Size = UDim2.new(0.1, 0, 1, 0), Position = UDim2.fromScale(0, 0), Rotation = 0},
		{Name = "Right", Size = UDim2.new(0.1, 0, 1, 0), Position = UDim2.fromScale(0.9, 0), Rotation = 180},
	}
	for _, definition in definitions do
		local edge = Instance.new("Frame")
		edge.Name = definition.Name
		edge.Size = definition.Size
		edge.Position = definition.Position
		edge.BackgroundColor3 = Color3.fromRGB(170, 22, 28)
		edge.BackgroundTransparency = 1
		edge.BorderSizePixel = 0
		edge.ZIndex = 2
		edge.Parent = impactLayer
		addEdgeGradient(edge, definition.Rotation)
		table.insert(self._edges, edge)
	end
	self._screenGui = screenGui
	self._impactLayer = impactLayer
	self._flash = flash
end

function DamageFeedbackController:_showTaken(amount)
	local strength = math.clamp(amount / 25, 0.25, 1)
	local visibleTransparency = 0.55 - (strength * 0.25)
	self._takenGeneration += 1
	local generation = self._takenGeneration

	if self._flashTween then
		self._flashTween:Cancel()
	end
	self._flash.BackgroundTransparency = 0.9 - (strength * 0.08)
	self._flashTween = TweenService:Create(
		self._flash,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1}
	)
	self._flashTween:Play()

	for index, edge in self._edges do
		local previousTween = self._edgeTweens[index]
		if previousTween then
			previousTween:Cancel()
		end
		edge.BackgroundTransparency = visibleTransparency
		local tween = TweenService:Create(
			edge,
			TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)
		self._edgeTweens[index] = tween
		tween:Play()
	end

	for _, tween in self._shakeTweens do
		tween:Cancel()
	end
	table.clear(self._shakeTweens)
	local amplitude = math.round(1 + strength * 3)
	self._impactLayer.Position = UDim2.fromOffset(-amplitude, amplitude)
	local impulseTween = TweenService:Create(
		self._impactLayer,
		TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.fromOffset(amplitude, -amplitude)}
	)
	table.insert(self._shakeTweens, impulseTween)
	impulseTween.Completed:Once(function()
		if generation ~= self._takenGeneration then
			return
		end
		local returnTween = TweenService:Create(
			self._impactLayer,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Position = UDim2.fromOffset(0, 0)}
		)
		table.insert(self._shakeTweens, returnTween)
		returnTween.Completed:Once(function()
			if generation == self._takenGeneration then
				table.clear(self._shakeTweens)
			end
		end)
		returnTween:Play()
	end)
	impulseTween:Play()
end

function DamageFeedbackController:_resolveAdornee(target)
	if typeof(target) ~= "Instance" or not target:IsDescendantOf(workspace) then
		return nil
	end
	if target:IsA("BasePart") then
		return target
	end
	if target:IsA("Model") then
		return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

function DamageFeedbackController:_trimFloating()
	while #self._floating >= MAX_FLOATING_NUMBERS do
		local oldest = table.remove(self._floating, 1)
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end
end

function DamageFeedbackController:_showDealt(amount, target, position)
	self:_trimFloating()
	local adornee = self:_resolveAdornee(target)
	local anchor
	if not adornee and typeof(position) == "Vector3" then
		anchor = Instance.new("Part")
		anchor.Name = "DamageFeedbackAnchor"
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.CFrame = CFrame.new(position)
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanTouch = false
		anchor.CanQuery = false
		anchor.Transparency = 1
		anchor.Parent = workspace
		adornee = anchor
	end
	if not adornee then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageNumber"
	billboard.Adornee = adornee
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 120
	billboard.Size = UDim2.fromOffset(92, 38)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
	billboard.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = "-" .. tostring(math.max(1, math.round(amount)))
	label.TextColor3 = Color3.fromRGB(255, 112, 72)
	label.TextSize = 22
	label.TextStrokeColor3 = Color3.fromRGB(40, 8, 5)
	label.TextStrokeTransparency = 0.35
	label.Parent = billboard

	table.insert(self._floating, billboard)
	TweenService:Create(
		billboard,
		TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{StudsOffsetWorldSpace = Vector3.new(0, 3.7, 0)}
	):Play()
	TweenService:Create(
		label,
		TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1, TextStrokeTransparency = 1}
	):Play()
	task.delay(0.7, function()
		local index = table.find(self._floating, billboard)
		if index then
			table.remove(self._floating, index)
		end
		if billboard.Parent then
			billboard:Destroy()
		end
	end)
	if anchor then
		Debris:AddItem(anchor, 0.75)
	end
end

function DamageFeedbackController:Start()
	if self._started then
		return
	end
	self._started = true
	self:_createGui()
	remote.OnClientEvent:Connect(function(feedbackType, amount, target, position)
		if typeof(amount) ~= "number" or amount <= 0 then
			return
		end
		if feedbackType == "Taken" then
			self:_showTaken(amount)
		elseif feedbackType == "Dealt" then
			self:_showDealt(amount, target, position)
		end
	end)
end

return DamageFeedbackController
