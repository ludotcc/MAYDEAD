local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FishingConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("FishingConfig"))
local ItemIconConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("ItemIconConfig"))
local fishingRequest = ReplicatedStorage:WaitForChild("FishingRequest")
local fishingState = ReplicatedStorage:WaitForChild("FishingState")

local controller = {
	Started = false,
	State = "Idle",
	SessionId = nil,
	CursorSpeed = 0,
	CursorPhase = 0,
	CastStartedAt = 0,
	DisplayedFishPosition = 0.5,
	DisplayedTargetPosition = 0.5,
	DisplayedCatchProgress = 0,
	DesiredFishPosition = 0.5,
	DesiredTargetPosition = 0.5,
	DesiredCatchProgress = 0,
	TouchInput = nil,
}

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function addStroke(instance, color, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency or 0
	stroke.Thickness = 1
	stroke.Parent = instance
end

local function createText(parent, text, size, position, font, textSize)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = font or Enum.Font.GothamSemibold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(232, 238, 244)
	label.TextSize = textSize or 13
	label.Parent = parent
	return label
end

local function cursorPosition(elapsed, speed, phase)
	return 0.5 + (0.5 * math.sin((elapsed * speed) + (0.28 * math.sin((elapsed * 1.7) + phase))))
end

function controller:_build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FishingUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 40
	gui.Parent = player:WaitForChild("PlayerGui")
	self.Gui = gui

	local feedback = createText(gui, "", UDim2.fromOffset(420, 42), UDim2.new(0.5, -210, 0.2, 0), Enum.Font.GothamBold, 18)
	feedback.BackgroundColor3 = Color3.fromRGB(10, 15, 22)
	feedback.BackgroundTransparency = 0.12
	feedback.Visible = false
	addCorner(feedback, 10)
	addStroke(feedback, Color3.fromRGB(73, 101, 122), 0.25)
	self.Feedback = feedback

	local castPanel = Instance.new("Frame")
	castPanel.Name = "CastPanel"
	castPanel.Size = UDim2.fromOffset(440, 112)
	castPanel.Position = UDim2.new(0.5, -220, 0.74, -56)
	castPanel.BackgroundColor3 = Color3.fromRGB(10, 15, 22)
	castPanel.BackgroundTransparency = 0.08
	castPanel.Visible = false
	castPanel.Parent = gui
	addCorner(castPanel, 12)
	addStroke(castPanel, Color3.fromRGB(73, 101, 122), 0.2)
	createText(castPanel, "LANCER", UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 8), Enum.Font.GothamBold, 15).TextXAlignment = Enum.TextXAlignment.Left

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -28, 0, 22)
	bar.Position = UDim2.fromOffset(14, 42)
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.ClipsDescendants = false
	bar.Parent = castPanel
	addCorner(bar, 6)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 39, 48)),
		ColorSequenceKeypoint.new(0.18, Color3.fromRGB(232, 105, 38)),
		ColorSequenceKeypoint.new(0.34, Color3.fromRGB(236, 197, 50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(47, 209, 114)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(236, 197, 50)),
		ColorSequenceKeypoint.new(0.82, Color3.fromRGB(232, 105, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 39, 48)),
	})
	gradient.Parent = bar
	local pointer = Instance.new("Frame")
	pointer.Size = UDim2.fromOffset(4, 34)
	pointer.AnchorPoint = Vector2.new(0.5, 0.5)
	pointer.Position = UDim2.fromScale(0.5, 0.5)
	pointer.BackgroundColor3 = Color3.fromRGB(245, 250, 255)
	pointer.Parent = bar
	addCorner(pointer, 2)
	addStroke(pointer, Color3.fromRGB(8, 12, 18), 0)
	self.CastPointer = pointer
	local castInstruction = UserInputService.TouchEnabled and "TOUCHER  —  LANCER" or "CLIC GAUCHE  —  LANCER"
	local instruction = createText(castPanel, castInstruction, UDim2.new(1, -28, 0, 22), UDim2.fromOffset(14, 76), Enum.Font.GothamMedium, 12)
	instruction.TextColor3 = Color3.fromRGB(154, 176, 193)
	self.CastPanel = castPanel

	local fightPanel = Instance.new("Frame")
	fightPanel.Name = "FightPanel"
	fightPanel.Size = UDim2.fromOffset(250, 430)
	fightPanel.Position = UDim2.new(1, -280, 0.5, -215)
	fightPanel.BackgroundColor3 = Color3.fromRGB(10, 15, 22)
	fightPanel.BackgroundTransparency = 0.06
	fightPanel.Visible = false
	fightPanel.Parent = gui
	addCorner(fightPanel, 14)
	addStroke(fightPanel, Color3.fromRGB(73, 101, 122), 0.2)
	createText(fightPanel, "RAMENEZ LE POISSON", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 10), Enum.Font.GothamBold, 14)

	local lane = Instance.new("Frame")
	lane.Size = UDim2.fromOffset(74, 300)
	lane.Position = UDim2.new(0.5, -37, 0, 54)
	lane.BackgroundColor3 = Color3.fromRGB(18, 29, 40)
	lane.ClipsDescendants = true
	lane.Parent = fightPanel
	addCorner(lane, 10)
	addStroke(lane, Color3.fromRGB(60, 83, 101), 0.2)
	local target = Instance.new("Frame")
	target.AnchorPoint = Vector2.new(0, 0.5)
	target.Size = UDim2.new(1, 0, FishingConfig.TargetZoneSize, 0)
	target.Position = UDim2.fromScale(0, 0.5)
	target.BackgroundColor3 = Color3.fromRGB(44, 190, 111)
	target.BackgroundTransparency = 0.6
	target.Parent = lane
	addStroke(target, Color3.fromRGB(69, 235, 143), 0.05)
	local fish = Instance.new("ImageLabel")
	fish.AnchorPoint = Vector2.new(0.5, 0.5)
	fish.Size = UDim2.fromOffset(42, 42)
	fish.Position = UDim2.fromScale(0.5, 0.5)
	fish.BackgroundTransparency = 1
	fish.Image = ItemIconConfig.Fish_Common
	fish.Parent = lane
	self.FightTarget = target
	self.FightFish = fish

	local progressBack = Instance.new("Frame")
	progressBack.Size = UDim2.fromOffset(178, 8)
	progressBack.Position = UDim2.new(0.5, -89, 1, -58)
	progressBack.BackgroundColor3 = Color3.fromRGB(30, 42, 53)
	progressBack.Parent = fightPanel
	addCorner(progressBack, 4)
	local progress = Instance.new("Frame")
	progress.Size = UDim2.fromScale(0, 1)
	progress.BackgroundColor3 = Color3.fromRGB(50, 202, 126)
	progress.Parent = progressBack
	addCorner(progress, 4)
	self.FightProgress = progress
	local fightInputText = UserInputService.TouchEnabled and "MAINTENIR LE DOIGT : MONTER" or "MAINTENIR CLIC GAUCHE : MONTER"
	local fightInstruction = createText(fightPanel, fightInputText, UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 1, -38), Enum.Font.GothamMedium, 10)
	fightInstruction.TextColor3 = Color3.fromRGB(154, 176, 193)
	self.FightPanel = fightPanel
end

function controller:_showFeedback(text, duration)
	self.Feedback.Text = text
	self.Feedback.Visible = true
	local expected = text
	task.delay(duration or 1.5, function()
		if self.Feedback.Text == expected then self.Feedback.Visible = false end
	end)
end

function controller:_getWaterTarget(screenPosition)
	local camera = workspace.CurrentCamera
	local character = player.Character
	if not camera or not character then return nil end
	local viewportPoint = screenPosition or (UserInputService:GetMouseLocation() - GuiService:GetGuiInset())
	local ray = camera:ViewportPointToRay(viewportPoint.X, viewportPoint.Y)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character}
	parameters.IgnoreWater = false
	local result = workspace:Raycast(ray.Origin, ray.Direction * FishingConfig.MaxCastDistance, parameters)
	return result and result.Material == Enum.Material.Water and result.Position or nil
end

function controller:_isMountedOnCheetah()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seatPart = humanoid and humanoid.SeatPart
	return seatPart ~= nil and seatPart.Name == "CheetahMountSeat"
end

function controller:_canUseTouchFishing()
	return UserInputService.TouchEnabled
		and player:GetAttribute("SessionStarted") == true
		and player:GetAttribute("ReturningToMenu") ~= true
		and self:_hasEquippedRod()
		and not self:_isMountedOnCheetah()
end

function controller:_hasEquippedRod()
	local character = player.Character
	local tool = character and character:FindFirstChild("Fishing_Rod")
	return tool ~= nil and tool:IsA("Tool")
end

function controller:_reset()
	self.TouchInput = nil
	if self.State == "Fight" and self.SessionId then
		fishingRequest:FireServer("FightInput", self.SessionId, false)
	end
	self.State = "Idle"
	self.SessionId = nil
	self.CastPanel.Visible = false
	self.FightPanel.Visible = false
end

function controller:_performPrimaryAction(holding, targetPosition)
	if self.State == "Idle" then
		if not self:_hasEquippedRod() then return end
		local target = targetPosition or self:_getWaterTarget()
		if target then
			fishingRequest:FireServer("StartCast", target)
		else
			self:_showFeedback("VISEZ L'EAU")
		end
	elseif self.State == "CastMinigame" and holding then
		fishingRequest:FireServer("StopCast", self.SessionId)
	elseif self.State == "Fight" then
		fishingRequest:FireServer("FightInput", self.SessionId, holding)
	end
end

function controller:_beginTouch(input, gameProcessed)
	if gameProcessed or self.TouchInput or not self:_canUseTouchFishing() then return end
	if self.State ~= "Idle" and self.State ~= "CastMinigame" and self.State ~= "Fight" then return end
	local position = Vector2.new(input.Position.X, input.Position.Y)
	self.TouchInput = {
		Input = input,
		State = self.State,
		StartPosition = position,
		LastPosition = position,
		StartedAt = os.clock(),
		Cancelled = false,
	}
	if self.State == "Fight" then self:_performPrimaryAction(true) end
end

function controller:_updateTouch(input)
	local touch = self.TouchInput
	if not touch or touch.Input ~= input then return end
	touch.LastPosition = Vector2.new(input.Position.X, input.Position.Y)
	if touch.State ~= "Fight"
		and (touch.LastPosition - touch.StartPosition).Magnitude > FishingConfig.TouchTapMoveTolerance
	then
		touch.Cancelled = true
	end
end

function controller:_finishTouch(input)
	local touch = self.TouchInput
	if not touch or touch.Input ~= input then return end
	self.TouchInput = nil
	if touch.State == "Fight" then
		self:_performPrimaryAction(false)
		return
	end
	if touch.Cancelled or self.State ~= touch.State
		or os.clock() - touch.StartedAt > FishingConfig.TouchTapMaxDuration
		or not self:_canUseTouchFishing()
	then
		return
	end
	if touch.State == "Idle" then
		local inset = GuiService:GetGuiInset()
		local target = self:_getWaterTarget(touch.LastPosition - inset)
		if target then self:_performPrimaryAction(true, target) end
	elseif touch.State == "CastMinigame" then
		self:_performPrimaryAction(true)
	end
end

function controller:_handleInput(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
		self:_performPrimaryAction(true)
	elseif input.UserInputType == Enum.UserInputType.Touch then
		self:_beginTouch(input, gameProcessed)
	end
end

function controller:Start()
	if self.Started then return end
	self.Started = true
	self:_build()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		self:_handleInput(input, gameProcessed)
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then self:_updateTouch(input) end
	end)
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and self.State == "Fight" then
			self:_performPrimaryAction(false)
		elseif input.UserInputType == Enum.UserInputType.Touch then
			self:_finishTouch(input)
		end
	end)
	local function watchCharacter(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and child.Name == "Fishing_Rod" then self.TouchInput = nil end
		end)
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child.Name == "Fishing_Rod" then
				self:_reset()
			end
		end)
		self.TouchInput = nil
	end
	if player.Character then watchCharacter(player.Character) end
	player.CharacterAdded:Connect(watchCharacter)
	player.CharacterRemoving:Connect(function()
		self:_reset()
	end)
	player:GetAttributeChangedSignal("SessionStarted"):Connect(function()
		if player:GetAttribute("SessionStarted") ~= true then self:_reset() end
	end)
	player:GetAttributeChangedSignal("ReturningToMenu"):Connect(function()
		if player:GetAttribute("ReturningToMenu") == true then self:_reset() end
	end)
	RunService.RenderStepped:Connect(function(deltaTime)
		if self.State == "CastMinigame" then
			local elapsed = workspace:GetServerTimeNow() - self.CastStartedAt
			self.CastPointer.Position = UDim2.fromScale(cursorPosition(elapsed, self.CursorSpeed, self.CursorPhase), 0.5)
		elseif self.State == "Fight" then
			local alpha = 1 - math.exp(-FishingConfig.FightVisualSmoothing * deltaTime)
			self.DisplayedFishPosition += (self.DesiredFishPosition - self.DisplayedFishPosition) * alpha
			self.DisplayedTargetPosition += (self.DesiredTargetPosition - self.DisplayedTargetPosition) * alpha
			self.DisplayedCatchProgress += (self.DesiredCatchProgress - self.DisplayedCatchProgress) * alpha
			self.FightFish.Position = UDim2.fromScale(0.5, 1 - self.DisplayedFishPosition)
			self.FightTarget.Position = UDim2.fromScale(0, 1 - self.DisplayedTargetPosition)
			self.FightProgress.Size = UDim2.fromScale(math.clamp(self.DisplayedCatchProgress / 100, 0, 1), 1)
		end
	end)
	fishingState.OnClientEvent:Connect(function(state, sessionId, a, b, c)
		if state == "CastMinigame" then
			self.State = state
			self.SessionId = sessionId
			self.CursorSpeed = a
			self.CursorPhase = b
			self.CastStartedAt = c
			self.CastPanel.Visible = true
			self.FightPanel.Visible = false
		elseif sessionId ~= self.SessionId then
			return
		elseif state == "Casting" then
			self.State = state
			self.CastPanel.Visible = false
			self:_showFeedback(string.upper(a or "LANCER"), 1)
		elseif state == "WaitingBite" then
			self.State = state
			self:_showFeedback("ATTENDEZ LA MORSURE", 1.25)
		elseif state == "Bite" then
			self.State = "Fight"
			self.DisplayedFishPosition = 0.5
			self.DisplayedTargetPosition = 0.5
			self.DisplayedCatchProgress = 0
			self.DesiredFishPosition = 0.5
			self.DesiredTargetPosition = 0.5
			self.DesiredCatchProgress = 0
			self.FightPanel.Visible = true
			self:_showFeedback("ÇA MORD !", 1)
		elseif state == "FightState" then
			self.State = "Fight"
			self.DesiredFishPosition = a
			self.DesiredTargetPosition = b
			self.DesiredCatchProgress = c
		elseif state == "Reeling" then
			self.State = state
			self.FightPanel.Visible = false
			self:_showFeedback("POISSON CAPTURÉ", 1.2)
		elseif state == "Finished" then
			self:_showFeedback(a or "PÊCHE TERMINÉE", 2)
			self:_reset()
		end
	end)
end

return controller
