local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FishingConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("FishingConfig"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local FishingService = {}
FishingService.__index = FishingService

local REQUEST_NAME = "FishingRequest"
local STATE_NAME = "FishingState"

local function findNamed(instance, name, className)
	local found = instance and instance:FindFirstChild(name, true)
	return found and found:IsA(className) and found or nil
end

local function isBobberAttachment(attachment)
	local current = attachment
	while current do
		local name = string.lower(current.Name)
		if string.find(name, "bobber", 1, true) or string.find(name, "float", 1, true) or string.find(name, "flotteur", 1, true) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function duplicateAttachment(source, name)
	if not source or not source.Parent then
		return nil
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.CFrame = source.CFrame
	attachment.Parent = source.Parent
	return attachment
end

local function cursorPosition(elapsed, speed, phase)
	return 0.5 + (0.5 * math.sin((elapsed * speed) + (0.28 * math.sin((elapsed * 1.7) + phase))))
end

local function getQuality(position)
	local distance = math.abs(position - 0.5)
	if distance <= 0.06 then return "Excellent", FishingConfig.ExcellentBiteChance end
	if distance <= 0.16 then return "Good", FishingConfig.GoodBiteChance end
	if distance <= 0.28 then return "Medium", FishingConfig.MediumBiteChance end
	if distance <= 0.40 then return "Low", FishingConfig.LowBiteChance end
	return "Bad", FishingConfig.BadBiteChance
end

local function isFiniteVector3(value)
	return typeof(value) == "Vector3"
		and value.X == value.X and value.Y == value.Y and value.Z == value.Z
		and math.abs(value.X) < math.huge and math.abs(value.Y) < math.huge and math.abs(value.Z) < math.huge
end

local function logRootVelocity(player, stage)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return end
	print(string.format(
		"[MAYDEAD][FISHING] %s root linear=%s angular=%s",
		stage,
		tostring(root.AssemblyLinearVelocity),
		tostring(root.AssemblyAngularVelocity)
	))
end

function FishingService.new()
	local self = setmetatable({}, FishingService)
	self._sessions = {}
	self._request = Instance.new("RemoteEvent")
	self._request.Name = REQUEST_NAME
	self._request.Parent = ReplicatedStorage
	self._state = Instance.new("RemoteEvent")
	self._state.Name = STATE_NAME
	self._state.Parent = ReplicatedStorage
	self._fishTemplate = nil
	self._accumulator = 0
	return self
end

function FishingService:_prepareAssets()
	local imports = ServerStorage:FindFirstChild("AssetImports")
	local rod = imports and imports:FindFirstChild("Fishing_Rod", true)
	print("[MAYDEAD][FISHING] Fishing_Rod found = " .. tostring(rod ~= nil))
	if rod then
		local mainPart = rod:IsA("Tool") and rod:FindFirstChild("Handle")
			or (rod:IsA("Model") and rod.PrimaryPart)
			or rod:FindFirstChildWhichIsA("BasePart", true)
		print("[MAYDEAD][FISHING] Fishing_Rod full name = " .. rod:GetFullName())
		print("[MAYDEAD][FISHING] Main part = " .. (mainPart and mainPart:GetFullName() or "NONE"))
	end
	local rope = rod and rod:FindFirstChildWhichIsA("RopeConstraint", true)
	print("[MAYDEAD][FISHING] RopeConstraint found = " .. tostring(rope ~= nil))
	if rope then
		print("[MAYDEAD][FISHING] RopeConstraint full name = " .. rope:GetFullName())
	end
	if rod and rope then
		local lineStart = findNamed(rod, "LineStart", "Attachment")
		local bobberPoint = findNamed(rod, "BobberPoint", "Attachment")
		local first = rope.Attachment0
		local second = rope.Attachment1
		local sourceBobber = (first and isBobberAttachment(first) and first)
			or (second and isBobberAttachment(second) and second)
			or second
		local sourceLine = sourceBobber == first and second or first
		lineStart = lineStart or duplicateAttachment(sourceLine, "LineStart")
		bobberPoint = bobberPoint or duplicateAttachment(sourceBobber, "BobberPoint")
		if lineStart and bobberPoint then
			rope.Attachment0 = lineStart
			rope.Attachment1 = bobberPoint
		end
		print("[MAYDEAD][FISHING] LineStart ready = " .. tostring(lineStart ~= nil))
		print("[MAYDEAD][FISHING] BobberPoint ready = " .. tostring(bobberPoint ~= nil))
		if lineStart then print("[MAYDEAD][FISHING] LineStart parent = " .. lineStart.Parent:GetFullName()) end
		if bobberPoint then print("[MAYDEAD][FISHING] BobberPoint parent = " .. bobberPoint.Parent:GetFullName()) end
	else
		print("[MAYDEAD][FISHING] LineStart ready = false")
		print("[MAYDEAD][FISHING] BobberPoint ready = false")
	end
	self._fishTemplate = imports and imports:FindFirstChild("Fish_Common", true)
	print("[MAYDEAD][FISHING] Fish_Common found = " .. tostring(self._fishTemplate ~= nil))
	if self._fishTemplate then
		print("[MAYDEAD][FISHING] Fish_Common full name = " .. self._fishTemplate:GetFullName())
	end
end

function FishingService:_getEquippedRod(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rod = character and character:FindFirstChild("Fishing_Rod")
	if not humanoid or humanoid.Health <= 0 or not rod or not rod:IsA("Tool") then
		return nil
	end
	return rod
end

function FishingService:_isMountedOnCheetah(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seatPart = humanoid and humanoid.SeatPart
	return seatPart ~= nil and seatPart.Name == "CheetahMountSeat"
end

function FishingService:_getRodVisual(player)
	local character = player.Character
	local visual = character and character:FindFirstChild("MAYDEADFishingRodVisual")
	return visual and visual:IsA("Model") and visual or nil
end

function FishingService:_isWaterTarget(player, targetPosition)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not isFiniteVector3(targetPosition)
		or (root.Position - targetPosition).Magnitude > FishingConfig.MaxCastDistance
	then
		return false
	end
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character}
	parameters.IgnoreWater = false
	local result = workspace:Raycast(targetPosition + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), parameters)
	if not result or result.Material ~= Enum.Material.Water then return false end
	local head = character:FindFirstChild("Head")
	local origin = head and head:IsA("BasePart") and head.Position or root.Position
	local direction = targetPosition - origin
	if direction.Magnitude <= 0 then return false end
	local lineOfSight = workspace:Raycast(origin, direction.Unit * (direction.Magnitude + 1), parameters)
	return lineOfSight ~= nil and lineOfSight.Material == Enum.Material.Water
end

function FishingService:_restoreRodVisual(session)
	if session.Rope and session.Rope.Parent then
		session.Rope.Attachment0 = session.OriginalRopeAttachment0
		session.Rope.Attachment1 = session.OriginalRopeAttachment1
		session.Rope.Length = session.OriginalRopeLength
		session.Rope.Enabled = session.OriginalRopeEnabled
		session.Rope.Visible = session.OriginalRopeVisible
	end
	if session.LineBeam then session.LineBeam:Destroy() end
	session.LineBeam = nil
	if session.OriginalBobberPart and session.OriginalBobberPart.Parent then
		session.OriginalBobberPart.Transparency = session.OriginalBobberTransparency
	end
	if session.BobberVisual then
		session.BobberVisual:Destroy()
	end
	session.BobberVisual = nil
end

function FishingService:_finish(player, message)
	local session = self._sessions[player]
	if not session then return end
	self._sessions[player] = nil
	self:_restoreRodVisual(session)
	self._state:FireClient(player, "Finished", session.Id, message)
end

function FishingService:_createBobberVisual(player, session)
	local rodVisual = self:_getRodVisual(player)
	local lineStart = findNamed(rodVisual, "LineStart", "Attachment")
	local bobberPoint = findNamed(rodVisual, "BobberPoint", "Attachment")
	local rope = rodVisual and rodVisual:FindFirstChildWhichIsA("RopeConstraint", true)
	local bobberPart = bobberPoint and bobberPoint.Parent
	if not lineStart or not bobberPoint or not rope or not bobberPart or not bobberPart:IsA("BasePart") then
		return nil
	end
	local visual = bobberPart:Clone()
	visual.Name = "FishingBobber"
	visual.Anchored = true
	visual.CanCollide = false
	visual.CanTouch = false
	visual.CanQuery = false
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("Constraint") or descendant:IsA("JointInstance") then descendant:Destroy() end
	end
	local visualPoint = findNamed(visual, "BobberPoint", "Attachment")
	if not visualPoint then
		visualPoint = Instance.new("Attachment")
		visualPoint.Name = "BobberPoint"
		visualPoint.Parent = visual
	end
	visual.CFrame = bobberPart.CFrame
	visual.Parent = workspace
	session.OriginalBobberPart = bobberPart
	session.OriginalBobberTransparency = bobberPart.Transparency
	bobberPart.Transparency = 1
	session.BobberVisual = visual
	session.Rope = rope
	session.OriginalRopeAttachment0 = rope.Attachment0
	session.OriginalRopeAttachment1 = rope.Attachment1
	session.OriginalRopeLength = rope.Length
	session.OriginalRopeEnabled = rope.Enabled
	session.OriginalRopeVisible = rope.Visible
	rope.Enabled = false
	rope.Visible = false
	local lineBeam = Instance.new("Beam")
	lineBeam.Name = "MAYDEADFishingLine"
	lineBeam.Attachment0 = lineStart
	lineBeam.Attachment1 = visualPoint
	lineBeam.FaceCamera = true
	lineBeam.Width0 = FishingConfig.FishingLineWidth
	lineBeam.Width1 = FishingConfig.FishingLineWidth
	lineBeam.Color = ColorSequence.new(rope.Color.Color)
	lineBeam.Transparency = NumberSequence.new(0)
	lineBeam.Parent = lineStart.Parent
	session.LineBeam = lineBeam
	return visual
end

function FishingService:_beginWaiting(player, session, quality, biteChance)
	local visual = self:_createBobberVisual(player, session)
	if not visual then
		self:_finish(player, "MATÉRIEL DE PÊCHE INCOMPLET")
		return
	end
	session.State = "Casting"
	logRootVelocity(player, "before cast")
	self._state:FireClient(player, "Casting", session.Id, quality)
	local targetCFrame = CFrame.new(session.TargetPosition + Vector3.new(0, 0.15, 0)) * visual.CFrame.Rotation
	TweenService:Create(visual, TweenInfo.new(FishingConfig.VisualCastDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = targetCFrame,
	}):Play()
	task.delay(FishingConfig.VisualCastDuration, function()
		if self._sessions[player] ~= session then return end
		logRootVelocity(player, "after cast")
		session.State = "WaitingBite"
		self._state:FireClient(player, "WaitingBite", session.Id, quality)
		local delaySeconds = math.random() * (FishingConfig.BiteDelayMax - FishingConfig.BiteDelayMin) + FishingConfig.BiteDelayMin
		task.delay(delaySeconds, function()
			if self._sessions[player] ~= session or session.State ~= "WaitingBite" then return end
			logRootVelocity(player, "before bite")
			if math.random() > biteChance then
				self:_finish(player, "RIEN N'A MORDU")
				return
			end
			if not InventoryService:CanAddItem(player, "Fish_Common", 1) then
				self:_finish(player, "INVENTAIRE PLEIN")
				return
			end
			session.State = "Fight"
			session.FightStartedAt = os.clock()
			session.TargetPositionNormalized = 0.5
			session.TargetDestination = 0.5
			session.FishPosition = math.clamp(
				session.TargetPositionNormalized + ((math.random() * 2 - 1) * FishingConfig.FightInitialFishOffset),
				0,
				1
			)
			session.FishVelocity = 0
			session.FishImpulse = 0
			session.FishImpulseTarget = 0
			session.CatchProgress = 0
			session.Holding = false
			session.NextImpulseAt = os.clock() + FishingConfig.FightStartGracePeriod
			session.NextTargetChangeAt = os.clock() + FishingConfig.FightStartGracePeriod
			logRootVelocity(player, "at bite")
			self._state:FireClient(player, "Bite", session.Id)
			task.defer(function()
				if self._sessions[player] == session then logRootVelocity(player, "after bite") end
			end)
		end)
	end)
end

function FishingService:_startCast(player, targetPosition)
	if self._sessions[player] or self:_isMountedOnCheetah(player)
		or not self:_getEquippedRod(player) or not self:_getRodVisual(player)
		or not self:_isWaterTarget(player, targetPosition)
	then
		return
	end
	local session = {
		Id = HttpService:GenerateGUID(false),
		State = "CastMinigame",
		TargetPosition = targetPosition,
		CastStartedAt = workspace:GetServerTimeNow(),
		CursorSpeed = FishingConfig.CastCursorMinSpeed
			+ (math.random() * (FishingConfig.CastCursorMaxSpeed - FishingConfig.CastCursorMinSpeed)),
		CursorPhase = math.random() * math.pi * 2,
	}
	self._sessions[player] = session
	self._state:FireClient(player, "CastMinigame", session.Id, session.CursorSpeed, session.CursorPhase, session.CastStartedAt)
end

function FishingService:_stopCast(player, sessionId)
	local session = self._sessions[player]
	if not session or session.Id ~= sessionId or session.State ~= "CastMinigame" or not self:_getEquippedRod(player) then
		return
	end
	local position = cursorPosition(workspace:GetServerTimeNow() - session.CastStartedAt, session.CursorSpeed, session.CursorPhase)
	local quality, biteChance = getQuality(position)
	self:_beginWaiting(player, session, quality, biteChance)
end

function FishingService:_setFightInput(player, sessionId, holding)
	local session = self._sessions[player]
	if session and session.Id == sessionId and session.State == "Fight" and typeof(holding) == "boolean" then
		session.Holding = holding
	end
end

function FishingService:_animateFishReward(player, session)
	if self._sessions[player] ~= session or not InventoryService:CanAddItem(player, "Fish_Common", 1) then
		self:_finish(player, "INVENTAIRE PLEIN")
		return
	end
	session.State = "Reeling"
	logRootVelocity(player, "reel start")
	self._state:FireClient(player, "Reeling", session.Id)
	local template = self._fishTemplate
	local visual = template and template:Clone()
	if visual then
		visual.Name = "CaughtFish_Common"
		for _, descendant in visual:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end
		if visual:IsA("BasePart") then visual.Anchored, visual.CanCollide = true, false end
		visual.Parent = workspace
		local startCFrame = session.BobberVisual and session.BobberVisual.CFrame or CFrame.new(session.TargetPosition)
		if visual:IsA("Model") then visual:PivotTo(startCFrame) elseif visual:IsA("BasePart") then visual.CFrame = startCFrame end
		session.FishVisual = visual
	end
	task.spawn(function()
		local started = os.clock()
		while self._sessions[player] == session and os.clock() - started < FishingConfig.VisualReelDuration do
			local alpha = math.clamp((os.clock() - started) / FishingConfig.VisualReelDuration, 0, 1)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if visual and root then
				local startPosition = session.TargetPosition
				local endPosition = root.Position + Vector3.new(0, 2, 0)
				local position = startPosition:Lerp(endPosition, alpha) + Vector3.new(0, math.sin(alpha * math.pi) * 5, 0)
				local pose = CFrame.new(position)
				if visual:IsA("Model") then visual:PivotTo(pose) elseif visual:IsA("BasePart") then visual.CFrame = pose end
			end
			RunService.Heartbeat:Wait()
		end
		if visual then visual:Destroy() end
		logRootVelocity(player, "reel end")
		if self._sessions[player] ~= session then return end
		local result = InventoryService:AddItem(player, "Fish_Common", 1)
		if result.Added == 1 then
			print("[MAYDEAD][FISHING] Fish_Common added to inventory")
			self:_finish(player, "POISSON CAPTURÉ")
		else
			self:_finish(player, "INVENTAIRE PLEIN")
		end
	end)
end

function FishingService:_updateFight(player, session, deltaTime)
	local elapsed = os.clock() - session.FightStartedAt
	if elapsed >= FishingConfig.FightMaxDuration then
		self:_finish(player, "LE POISSON S'EST ÉCHAPPÉ")
		return
	end
	local acceleration = session.Holding and FishingConfig.FishRiseAcceleration or -FishingConfig.FishFallAcceleration
	local now = os.clock()
	if now >= session.NextImpulseAt then
		session.FishImpulseTarget = (math.random() * 2 - 1) * FishingConfig.FishRandomImpulse
		session.NextImpulseAt = now + FishingConfig.FishImpulseIntervalMin
			+ (math.random() * (FishingConfig.FishImpulseIntervalMax - FishingConfig.FishImpulseIntervalMin))
	end
	local impulseAlpha = 1 - math.exp(-FishingConfig.FishImpulseSmoothing * deltaTime)
	session.FishImpulse = session.FishImpulse + ((session.FishImpulseTarget - session.FishImpulse) * impulseAlpha)
	session.FishVelocity = session.FishVelocity + ((acceleration + session.FishImpulse) * deltaTime)
	session.FishVelocity = math.clamp(
		session.FishVelocity * math.pow(0.9, deltaTime * 10),
		-FishingConfig.FishMaxVerticalSpeed,
		FishingConfig.FishMaxVerticalSpeed
	)
	session.FishPosition = math.clamp(session.FishPosition + (session.FishVelocity * deltaTime), 0, 1)
	if elapsed >= FishingConfig.FightStartGracePeriod and now >= session.NextTargetChangeAt then
		session.TargetDestination = FishingConfig.TargetTravelMin
			+ (math.random() * (FishingConfig.TargetTravelMax - FishingConfig.TargetTravelMin))
		session.NextTargetChangeAt = now + FishingConfig.TargetChangeIntervalMin
			+ (math.random() * (FishingConfig.TargetChangeIntervalMax - FishingConfig.TargetChangeIntervalMin))
	end
	local targetAlpha = 1 - math.exp(-FishingConfig.TargetMoveSpeed * deltaTime)
	session.TargetPositionNormalized = session.TargetPositionNormalized
		+ ((session.TargetDestination - session.TargetPositionNormalized) * targetAlpha)
	local targetPosition = session.TargetPositionNormalized
	local inside = math.abs(session.FishPosition - targetPosition) <= FishingConfig.TargetZoneSize / 2
	local rate = inside and FishingConfig.CatchGainRate or -FishingConfig.CatchLossRate
	session.CatchProgress = math.clamp(session.CatchProgress + (rate * deltaTime), 0, 100)
	if session.CatchProgress >= 100 then
		self:_animateFishReward(player, session)
		return
	end
	self._state:FireClient(player, "FightState", session.Id, session.FishPosition, targetPosition, session.CatchProgress, elapsed)
end

function FishingService:Start()
	self:_prepareAssets()
	self._request.OnServerEvent:Connect(function(player, action, ...)
		if player:GetAttribute("SessionStarted") ~= true then return end
		if action == "StartCast" then
			self:_startCast(player, ...)
		elseif action == "StopCast" then
			self:_stopCast(player, ...)
		elseif action == "FightInput" then
			self:_setFightInput(player, ...)
		elseif action == "Cancel" then
			self:_finish(player, "ANNULÉ")
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local session = self._sessions[player]
		if session then self:_restoreRodVisual(session) end
		self._sessions[player] = nil
	end)
	RunService.Heartbeat:Connect(function(deltaTime)
		self._accumulator = self._accumulator + deltaTime
		if self._accumulator < FishingConfig.StateReplicationInterval then return end
		local updateDelta = self._accumulator
		self._accumulator = 0
		for player, session in self._sessions do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not self:_getEquippedRod(player) or not root
				or (root.Position - session.TargetPosition).Magnitude > FishingConfig.MaxCastDistance + 10
			then
				self:_finish(player, "ANNULÉ")
			elseif session.State == "Fight" then
				self:_updateFight(player, session, updateDelta)
			end
		end
	end)
end

return FishingService.new()
