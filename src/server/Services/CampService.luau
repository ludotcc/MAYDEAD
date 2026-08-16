local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local CampConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("CampConfig"))
local SurvivalService = require(script.Parent:WaitForChild("SurvivalService"))

local CampService = {}
CampService.__index = CampService

local function createPoint(parentPart, name, worldCFrame)
	local point = Instance.new("Attachment")
	point.Name = name
	point.CFrame = parentPart.CFrame:ToObjectSpace(worldCFrame)
	point.Parent = parentPart
	return point
end

function CampService.new()
	local self = setmetatable({}, CampService)
	self._camps = setmetatable({}, {__mode = "k"})
	self._playerRest = {}
	self._accumulator = 0
	self._running = false
	return self
end

function CampService:_resolvePoints(camp)
	local bed = camp:FindFirstChild("Bed", true)
	print("[MAYDEAD][CAMP] Bed found = " .. tostring(bed ~= nil))
	if bed then
		print("[MAYDEAD][CAMP] Bed full name = " .. bed:GetFullName())
		print("[MAYDEAD][CAMP] Bed class = " .. bed.ClassName)
	end
	if not bed or not bed:IsA("BasePart") then
		warn("[MAYDEAD][CAMP] WARNING: Bed part missing")
		return nil, nil
	end
	local interactionPoint = camp:FindFirstChild("InteractionPoint", true)
	if interactionPoint and not (interactionPoint:IsA("Attachment") or interactionPoint:IsA("BasePart")) then
		interactionPoint = nil
	end
	if not interactionPoint then
		interactionPoint = createPoint(bed, "InteractionPoint", bed.CFrame)
	end
	return bed, interactionPoint
end

function CampService:_getBedPose(bed)
	local surfaceCFrame = bed.CFrame * CFrame.new(0, (bed.Size.Y / 2) + CampConfig.CampBedVerticalOffset, 0)
	if bed.Size.Z > bed.Size.X then
		return surfaceCFrame * CFrame.Angles(math.rad(90), 0, 0), "Z"
	end
	return surfaceCFrame * CFrame.Angles(0, 0, math.rad(90)), "X"
end

function CampService:_getExitCFrame(bed, lengthAxis)
	local sideDistance
	local localOffset
	if lengthAxis == "Z" then
		sideDistance = (bed.Size.X / 2) + CampConfig.EXIT_SIDE_CLEARANCE
		localOffset = Vector3.new(sideDistance, CampConfig.EXIT_VERTICAL_OFFSET, 0)
	else
		sideDistance = (bed.Size.Z / 2) + CampConfig.EXIT_SIDE_CLEARANCE
		localOffset = Vector3.new(0, CampConfig.EXIT_VERTICAL_OFFSET, sideDistance)
	end
	local exitPosition = (bed.CFrame * CFrame.new(localOffset)).Position
	local forward = Vector3.new(bed.CFrame.LookVector.X, 0, bed.CFrame.LookVector.Z)
	if forward.Magnitude < 0.01 then
		forward = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(exitPosition, exitPosition + forward.Unit)
end

function CampService:_isNearCamp(player, camp)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local data = self._camps[camp]
	return rootPart ~= nil and data ~= nil
		and (rootPart.Position - data.Bed.Position).Magnitude <= CampConfig.MAX_INTERACTION_DISTANCE
end

function CampService:_leaveRest(player, reposition)
	local rest = self._playerRest[player]
	if not rest then
		return
	end
	self._playerRest[player] = nil
	local data = self._camps[rest.Camp]
	if data and data.Occupant == player then
		data.Occupant = nil
		data.Prompt.ActionText = "SE REPOSER"
		rest.Camp:SetAttribute("OccupiedUserId", nil)
	end
	if rest.DeathConnection then
		rest.DeathConnection:Disconnect()
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.Anchored = rest.WasAnchored
	end
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = rest.AutoRotate
		humanoid.WalkSpeed = rest.WalkSpeed
		humanoid.JumpPower = rest.JumpPower
		humanoid.JumpHeight = rest.JumpHeight
		if humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	if reposition and character and data then
		character:PivotTo(self:_getExitCFrame(data.Bed, data.LengthAxis))
	end
end

function CampService:_enterRest(player, camp)
	local data = self._camps[camp]
	if not data or data.Occupant or self._playerRest[player] or not self:_isNearCamp(player, camp) then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not rootPart then
		return
	end

	data.Occupant = player
	data.Prompt.ActionText = "SE LEVER"
	camp:SetAttribute("OccupiedUserId", player.UserId)
	local rest = {
		Camp = camp,
		WalkSpeed = humanoid.WalkSpeed,
		JumpPower = humanoid.JumpPower,
		JumpHeight = humanoid.JumpHeight,
		AutoRotate = humanoid.AutoRotate,
		WasAnchored = rootPart.Anchored,
	}
	self._playerRest[player] = rest
	rest.DeathConnection = humanoid.Died:Connect(function()
		self:_leaveRest(player, false)
	end)
	humanoid:UnequipTools()
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	rootPart.Anchored = true
	local bedPose, lengthAxis = self:_getBedPose(data.Bed)
	data.LengthAxis = lengthAxis
	character:PivotTo(bedPose)
end

function CampService:RegisterCamp(camp)
	if not camp:IsA("Model") or self._camps[camp] then
		return false
	end
	local bed, interactionPoint = self:_resolvePoints(camp)
	if not bed or not interactionPoint then
		warn("[MAYDEAD][CampService] Camp registration failed: required BasePart Bed unavailable")
		return false
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CampPrompt"
	prompt.ActionText = "SE REPOSER"
	prompt.ObjectText = "CAMP"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = CampConfig.MAX_INTERACTION_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = interactionPoint
	local _, lengthAxis = self:_getBedPose(bed)
	local data = {Bed = bed, LengthAxis = lengthAxis, Prompt = prompt, Occupant = nil, Connections = {}}
	self._camps[camp] = data
	table.insert(data.Connections, prompt.Triggered:Connect(function(player)
		if player:GetAttribute("SessionStarted") ~= true then return end
		if data.Occupant == player then
			self:_leaveRest(player, true)
		elseif not data.Occupant then
			self:_enterRest(player, camp)
		end
	end))
	table.insert(data.Connections, camp.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			if data.Occupant then
				self:_leaveRest(data.Occupant, true)
			end
			for _, connection in data.Connections do
				connection:Disconnect()
			end
			self._camps[camp] = nil
		end
	end))
	print("[MAYDEAD][CAMP] Bed principal axis = " .. lengthAxis)
	return true
end

function CampService:Start()
	if self._running then
		return
	end
	self._running = true
	Players.PlayerRemoving:Connect(function(player)
		self:_leaveRest(player, false)
	end)
	RunService.Heartbeat:Connect(function(deltaTime)
		self._accumulator = self._accumulator + deltaTime
		if self._accumulator < CampConfig.UPDATE_INTERVAL then
			return
		end
		local updateDelta = self._accumulator
		self._accumulator = 0
		for player, rest in self._playerRest do
			if not player.Parent or not rest.Camp.Parent then
				self:_leaveRest(player, false)
			else
				SurvivalService:RecoverFromCamp(player, updateDelta, CampConfig.CampFullRecoveryDuration)
			end
		end
	end)
end

return CampService.new()
