local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")


local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HarvestConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("HarvestConfig")
)
local ItemDefinitions = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("ItemDefinitions")
)
local harvestRequest = ReplicatedStorage:WaitForChild("HarvestRequest")
local harvestResult = ReplicatedStorage:WaitForChild("HarvestResult")
local dismantleRequest = ReplicatedStorage:WaitForChild("DismantleRequest")
local dismantleResult = ReplicatedStorage:WaitForChild("DismantleResult")
local wildCropHitRequest = ReplicatedStorage:WaitForChild("WildCropHitRequest")
local wildlifeHitRequest = ReplicatedStorage:WaitForChild("WildlifeHitRequest")
local wildlifeHitResult = ReplicatedStorage:WaitForChild("WildlifeHitResult")
local PICKAXE_IMPACT_SOUND_ID = "rbxassetid://2304904662"

local HarvestController = {}
HarvestController.__index = HarvestController

local function findResource(target)
	local resourcesFolder = workspace:FindFirstChild("Resources")
	local resource = target
	while resource and resource.Parent ~= resourcesFolder do
		resource = resource.Parent
	end
	if resource and HarvestConfig.Resources[resource.Name] then
		return resource
	end
	return nil
end

local function findPlacedStructure(target)
	local placedStructures = workspace:FindFirstChild("PlacedStructures")
	local current = target
	while current and current ~= placedStructures do
		if current:IsA("Model")
			and current:GetAttribute("StructureId")
			and current:GetAttribute("ItemId")
		then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function findWildCrop(target)
	local current = target
	while current and current ~= workspace do
		if current:IsA("Model") and current:GetAttribute("WildCropId") then return current end
		current = current.Parent
	end
	return nil
end

local function findWildlife(target)
	local current = target
	while current and current ~= workspace do
		if current:IsA("Model")
			and current:GetAttribute("AnimalType")
			and current:FindFirstChildOfClass("Humanoid")
		then
			return current
		end
		current = current.Parent
	end
	return nil
end

function HarvestController.new()
	return setmetatable({
		ConnectedTools = setmetatable({}, {__mode = "k"}),
		Tracks = setmetatable({}, {__mode = "k"}),
		RestGrips = setmetatable({}, {__mode = "k"}),
		SwingTweens = setmetatable({}, {__mode = "k"}),
		SwingIds = setmetatable({}, {__mode = "k"}),
		LastTouchPosition = nil,
		LastTouchTime = 0,
		LastHandAnimationAt = 0,
		HandAnimationTrack = nil,
	}, HarvestController)
end

function HarvestController:_raycastTarget()
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	local screenPosition = UserInputService:GetMouseLocation()
	if self.LastTouchPosition and os.clock() - self.LastTouchTime <= 1 then
		screenPosition = self.LastTouchPosition
	end
	local topLeftInset = GuiService:GetGuiInset()
	local viewportPosition = screenPosition - topLeftInset
	local ray = camera:ViewportPointToRay(viewportPosition.X, viewportPosition.Y)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = player.Character and {player.Character} or {}
	local result = workspace:Raycast(ray.Origin, ray.Direction * 32, parameters)
	return result and result.Instance or nil
end

function HarvestController:_getFeedbackGui()
	local screenGui = playerGui:FindFirstChild("MAYDEADHarvestFeedback")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "MAYDEADHarvestFeedback"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui
	end
	local existingMessage = screenGui:FindFirstChild("Message")
	if existingMessage and existingMessage:IsA("TextLabel") and existingMessage.Text == "" then
		existingMessage.Visible = false
	end
	return screenGui
end

function HarvestController:_showFeedback(text)
	local screenGui = self:_getFeedbackGui()
	local label = screenGui:FindFirstChild("Message") or Instance.new("TextLabel")
	label.Name = "Message"
	label.Size = UDim2.fromOffset(180, 30)
	label.Position = UDim2.new(0.5, 0, 0.68, 0)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	label.BackgroundTransparency = 0.2
	label.BorderSizePixel = 0
	label.Text = text
	label.Visible = text ~= ""
	label.TextColor3 = Color3.fromRGB(225, 205, 168)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.Parent = screenGui
	local corner = label:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	local messageId = os.clock()
	label:SetAttribute("MessageId", messageId)
	task.delay(0.8, function()
		if label.Parent and label:GetAttribute("MessageId") == messageId then
			label.Text = ""
			label.Visible = false
		end
	end)
end

function HarvestController:_showHarvestImpact(resource, currentHealth, maximumHealth)
	local screenGui = self:_getFeedbackGui()
	local panel = screenGui:FindFirstChild("Progress") or Instance.new("Frame")
	panel.Name = "Progress"
	panel.Size = UDim2.fromOffset(216, 52)
	panel.Position = UDim2.new(0.5, 0, 0.7, 0)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(9, 14, 20)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Parent = screenGui
	local corner = panel:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", panel)
	corner.CornerRadius = UDim.new(0, 10)
	local title = panel:FindFirstChild("Title") or Instance.new("TextLabel", panel)
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 24)
	title.Position = UDim2.fromOffset(10, 4)
	title.BackgroundTransparency = 1
	local resourceDefinition = resource and HarvestConfig.Resources[resource.Name]
	local itemDefinition = resourceDefinition and ItemDefinitions[resourceDefinition.LootItemId]
	title.Text = "RÉCOLTE  •  " .. string.upper(itemDefinition and itemDefinition.DisplayName or "RESSOURCE")
	title.TextColor3 = Color3.fromRGB(224, 232, 238)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 11
	title.TextXAlignment = Enum.TextXAlignment.Left
	local track = panel:FindFirstChild("Track") or Instance.new("Frame", panel)
	track.Name = "Track"
	track.Size = UDim2.new(1, -20, 0, 7)
	track.Position = UDim2.fromOffset(10, 34)
	track.BackgroundColor3 = Color3.fromRGB(35, 44, 52)
	track.BorderSizePixel = 0
	local trackCorner = track:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", track)
	trackCorner.CornerRadius = UDim.new(1, 0)
	local fill = track:FindFirstChild("Fill") or Instance.new("Frame", track)
	fill.Name = "Fill"
	fill.Size = fill.Size.X.Scale == 0 and UDim2.fromScale(1, 1) or fill.Size
	fill.BackgroundColor3 = Color3.fromRGB(88, 180, 129)
	fill.BorderSizePixel = 0
	local fillCorner = fill:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", fill)
	fillCorner.CornerRadius = UDim.new(1, 0)
	local ratio = math.clamp((tonumber(currentHealth) or 0) / math.max(tonumber(maximumHealth) or 1, 1), 0, 1)
	TweenService:Create(fill, TweenInfo.new(HarvestConfig.FEEDBACK_TWEEN_DURATION), {Size = UDim2.fromScale(ratio, 1)}):Play()
	panel.Visible = true
	local revision = os.clock()
	panel:SetAttribute("Revision", revision)
	task.delay(0.75, function()
		if panel.Parent and panel:GetAttribute("Revision") == revision then panel.Visible = false end
	end)
	if resource and resource:IsDescendantOf(workspace) then
		local highlight = Instance.new("Highlight")
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillColor = Color3.fromRGB(181, 208, 173)
		highlight.FillTransparency = 0.78
		highlight.OutlineColor = Color3.fromRGB(224, 235, 211)
		highlight.OutlineTransparency = 0.35
		highlight.Adornee = resource
		highlight.Parent = resource
		task.delay(0.14, function() if highlight.Parent then highlight:Destroy() end end)
	end
end

function HarvestController:_playHandHarvestAnimation()
	if os.clock() - self.LastHandAnimationAt < HarvestConfig.HARVEST_COOLDOWN * 0.8 then return end
	self.LastHandAnimationAt = os.clock()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if HarvestConfig.HAND_ANIMATION_ID ~= "" then
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
		local animation = Instance.new("Animation")
		animation.AnimationId = HarvestConfig.HAND_ANIMATION_ID
		local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
		animation:Destroy()
		if ok then track:Play(0.05, 1, 1.1); self.HandAnimationTrack = track; return end
	end
	local shoulder = character:FindFirstChild("RightShoulder", true) or character:FindFirstChild("Right Shoulder", true)
	if shoulder and shoulder:IsA("Motor6D") then
		local original = shoulder.Transform
		local reach = TweenService:Create(shoulder, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transform = original * CFrame.Angles(math.rad(-32), 0, math.rad(10)),
		})
		reach:Play()
		reach.Completed:Once(function()
			TweenService:Create(shoulder, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transform = original}):Play()
		end)
	end
end

function HarvestController:_playConfirmedSound(tool, impactName, resource)
	local sound = tool and self:_findImpactSound(tool, impactName) or nil
	if not sound and resource then
		for _, descendant in resource:GetDescendants() do
			if descendant:IsA("Sound") then sound = descendant:Clone(); sound.Parent = SoundService; break end
		end
	end
	if not sound then
		local soundId = HarvestConfig.ImpactSoundIds[impactName]
		if typeof(soundId) == "string" and string.match(soundId, "^rbxassetid://%d+$") then
			sound = Instance.new("Sound", SoundService)
			sound.SoundId = soundId
		end
	end
	if sound then
		sound.Volume = math.min(sound.Volume, HarvestConfig.IMPACT_SOUND_VOLUME)
		sound:Play()
		if sound.Parent == SoundService then sound.Ended:Once(function() sound:Destroy() end) end
	end
end

function HarvestController:_playPickaxeSwing(tool)
	local restGrip = self.RestGrips[tool] or tool.Grip
	self.RestGrips[tool] = restGrip

	local previousTween = self.SwingTweens[tool]
	if previousTween then
		previousTween:Cancel()
	end

	local swingId = (self.SwingIds[tool] or 0) + 1
	self.SwingIds[tool] = swingId
	tool.Grip = restGrip

	local function isCurrentSwing()
		return tool.Parent ~= nil and self.SwingIds[tool] == swingId
	end

	local raiseTween = TweenService:Create(
		tool,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Grip = restGrip * CFrame.Angles(math.rad(24), 0, math.rad(-4))}
	)
	self.SwingTweens[tool] = raiseTween
	raiseTween:Play()
	raiseTween.Completed:Connect(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed or not isCurrentSwing() then
			return
		end

		local strikeTween = TweenService:Create(
			tool,
			TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Grip = restGrip * CFrame.Angles(math.rad(-34), 0, math.rad(4))}
		)
		self.SwingTweens[tool] = strikeTween
		strikeTween:Play()
		strikeTween.Completed:Connect(function(strikeState)
			if strikeState ~= Enum.PlaybackState.Completed or not isCurrentSwing() then
				return
			end

			local returnTween = TweenService:Create(
				tool,
				TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Grip = restGrip}
			)
			self.SwingTweens[tool] = returnTween
			returnTween:Play()
			returnTween.Completed:Connect(function()
				if isCurrentSwing() then
					tool.Grip = restGrip
					self.SwingTweens[tool] = nil
				end
			end)
		end)
	end)
end

function HarvestController:_playFallback(tool)
	local originalGrip = tool.Grip
	local swing = TweenService:Create(
		tool,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Grip = originalGrip * CFrame.Angles(math.rad(-28), 0, 0)}
	)
	swing:Play()
	swing.Completed:Connect(function()
		TweenService:Create(
			tool,
			TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Grip = originalGrip}
		):Play()
	end)
end

function HarvestController:_playAnimation(tool)
	if tool.Name == "Pickaxe" then
		self:_playPickaxeSwing(tool)
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local animation = tool:FindFirstChildWhichIsA("Animation", true)
	if not animation or animation.AnimationId == "" then
		self:_playFallback(tool)
		return
	end

	local track = self.Tracks[tool]
	if not track then
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
		local loaded, loadedTrack = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if not loaded then
			self:_playFallback(tool)
			return
		end
		track = loadedTrack
		self.Tracks[tool] = track
	end

	track:Play(0.05, 1, 1.15)
end

function HarvestController:_findImpactSound(tool, impactName)
	if tool.Name == "Pickaxe" then
		local pickaxeImpact = tool:FindFirstChild("Equip", true)
		if pickaxeImpact and pickaxeImpact:IsA("Sound") then
			pickaxeImpact.SoundId = PICKAXE_IMPACT_SOUND_ID
			return pickaxeImpact
		end
		return nil
	end

	for _, descendant in tool:GetDescendants() do
		if descendant:IsA("Sound") then
			local loweredName = string.lower(descendant.Name)
			if string.find(loweredName, string.lower(impactName), 1, true)
				or string.find(loweredName, "impact", 1, true)
				or string.find(loweredName, "hit", 1, true)
			then
				return descendant
			end
		end
	end

	local soundId = HarvestConfig.ImpactSoundIds[impactName]
	if typeof(soundId) == "string" and string.match(soundId, "^rbxassetid://%d+$") then
		local handle = tool:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			local sound = Instance.new("Sound")
			sound.Name = impactName .. "Impact"
			sound.SoundId = soundId
			sound.Volume = 0.55
			sound.Parent = handle
			return sound
		end
	end
	return nil
end

function HarvestController:_connectTool(tool)
	if not tool:IsA("Tool") or self.ConnectedTools[tool] then
		return
	end
	if tool.Name ~= "Axe" and tool.Name ~= "Pickaxe" then
		return
	end

	self.ConnectedTools[tool] = true
	self.RestGrips[tool] = tool.Grip
	tool.Activated:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local hitPart = self:_raycastTarget()

		local resource = findResource(hitPart)
		if not resource then
			local animal = findWildlife(hitPart)
			if animal then
				wildlifeHitRequest:FireServer(animal)
				return
			end
			local wildCrop = findWildCrop(hitPart)
			if wildCrop then
				wildCropHitRequest:FireServer(wildCrop)
				return
			end
			local structure = findPlacedStructure(hitPart)
			if tool.Name == "Axe" and structure then
				dismantleRequest:FireServer(structure)
			end
			return
		end
		harvestRequest:FireServer(resource)
	end)
end

function HarvestController:_watchContainer(container)
	for _, child in container:GetChildren() do
		self:_connectTool(child)
	end
	container.ChildAdded:Connect(function(child)
		self:_connectTool(child)
	end)
end

function HarvestController:Start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.Touch then
			self.LastTouchPosition = Vector2.new(input.Position.X, input.Position.Y)
			self.LastTouchTime = os.clock()
		end
		if gameProcessed or (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) then
			return
		end
		local character = player.Character
		if character and character:FindFirstChildOfClass("Tool") then return end
		local resource = findResource(self:_raycastTarget())
		if resource then harvestRequest:FireServer(resource) end
	end)
	self:_watchContainer(player:WaitForChild("Backpack"))
	if player.Character then
		self:_watchContainer(player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		self:_watchContainer(character)
	end)

	harvestResult.OnClientEvent:Connect(function(impactName, currentHealth, maximumHealth, isHandHarvest, resource)
		if impactName == "ToolRequired" then
			self:_showFeedback("OUTIL REQUIS")
			return
		end
		if impactName == "InventoryFull" then
			self:_showFeedback("INVENTAIRE PLEIN")
			return
		end
		local character = player.Character
		local tool = character and character:FindFirstChildOfClass("Tool")
		if isHandHarvest then self:_playHandHarvestAnimation() elseif tool then self:_playAnimation(tool) end
		self:_playConfirmedSound(tool, impactName, resource)
		if typeof(currentHealth) == "number" and typeof(maximumHealth) == "number" then
			self:_showHarvestImpact(resource, currentHealth, maximumHealth)
		end
	end)

	wildlifeHitResult.OnClientEvent:Connect(function(impactName)
		local character = player.Character
		local tool = character and character:FindFirstChildOfClass("Tool")
		if tool then
			self:_playAnimation(tool)
			local sound = self:_findImpactSound(tool, impactName)
			if sound then sound:Play() end
		end
	end)

	dismantleResult.OnClientEvent:Connect(function(structure, accepted)
		if not accepted or typeof(structure) ~= "Instance" or not structure:IsDescendantOf(workspace) then
			return
		end
		local highlight = Instance.new("Highlight")
		highlight.Name = "DismantleImpact"
		highlight.Adornee = structure
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = Color3.fromRGB(238, 176, 74)
		highlight.FillTransparency = 0.55
		highlight.OutlineColor = Color3.fromRGB(255, 224, 157)
		highlight.OutlineTransparency = 0.15
		highlight.Parent = structure
		task.delay(0.12, function()
			if highlight.Parent then
				highlight:Destroy()
			end
		end)
	end)
end

return HarvestController.new()
