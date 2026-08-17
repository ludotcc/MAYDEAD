local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("BisonConfig"))

local BisonAI = {}
BisonAI.__index = BisonAI

local function makeRaycastParams(exclusions)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = typeof(exclusions) == "Instance" and {exclusions} or exclusions
	params.IgnoreWater = false
	return params
end

function BisonAI.IsDryTerrainAt(position, exclusions, isPointInWater)
	if isPointInWater(position) then return false, nil end
	local result = workspace:Raycast(
		position + Vector3.new(0, Config.GROUND_RAY_HEIGHT, 0),
		Vector3.new(0, -Config.GROUND_RAY_DEPTH, 0),
		makeRaycastParams(exclusions)
	)
	if not result or result.Instance ~= workspace.Terrain or result.Material == Enum.Material.Water then return false, nil end
	if math.abs(position.Y - result.Position.Y) > Config.MAX_GROUND_VERTICAL_DISTANCE then return false, nil end
	if isPointInWater(result.Position + Vector3.new(0, 2, 0)) then return false, nil end
	return true, result.Position
end

function BisonAI.new(model, isPointInWater)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("Torso")
	if not humanoid or not root or not root:IsA("BasePart") then return nil end

	local self = setmetatable({}, BisonAI)
	self.Model = model
	self.Humanoid = humanoid
	self.Root = root
	self.IsPointInWater = isPointInWater
	self.RaycastParams = makeRaycastParams(model)
	self.LastSafeGroundPosition = nil
	self.LastHealth = humanoid.Health
	self.Active = true
	self.Fleeing = false
	self.PathGeneration = 0
	self.PathActive = false
	self.NextWanderTime = os.clock()
	self.SafetyAccumulator = Config.SAFETY_CHECK_INTERVAL
	self.RecoveryStartedAt = nil
	self.LastRecoveryDistance = math.huge
	self.Random = Random.new()

	local dry = self:_getDryGround(root.Position)
	if dry then self.LastSafeGroundPosition = root.Position end
	self.HealthConnection = humanoid.HealthChanged:Connect(function(health)
		if self.Active and health > 0 and health < self.LastHealth then self:_flee() end
		self.LastHealth = health
	end)
	return self
end

function BisonAI:_getDryGround(position)
	if self.IsPointInWater(position) then return false, nil end
	local result = workspace:Raycast(
		position + Vector3.new(0, Config.GROUND_RAY_HEIGHT, 0),
		Vector3.new(0, -Config.GROUND_RAY_DEPTH, 0),
		self.RaycastParams
	)
	if not result or result.Instance ~= workspace.Terrain or result.Material == Enum.Material.Water then return false, nil end
	if math.abs(position.Y - result.Position.Y) > Config.MAX_GROUND_VERTICAL_DISTANCE then return false, nil end
	if self.IsPointInWater(result.Position + Vector3.new(0, 2, 0)) then return false, nil end
	return true, result.Position
end

function BisonAI:_isDrySegment(fromPosition, toPosition)
	local distance = (toPosition - fromPosition).Magnitude
	local samples = math.max(1, math.ceil(distance / Config.PATH_SAMPLE_SPACING))
	for index = 1, samples do
		local sample = fromPosition:Lerp(toPosition, index / samples)
		local dry = self:_getDryGround(sample)
		if not dry then return false end
	end
	return true
end

function BisonAI:_requestPath(destination)
	local destinationDry, dryDestination = self:_getDryGround(destination)
	if not destinationDry or not dryDestination or not self:_isDrySegment(self.Root.Position, dryDestination) then return false end
	self.PathGeneration += 1
	local generation = self.PathGeneration
	self.PathActive = true
	task.spawn(function()
		local path = PathfindingService:CreatePath({Costs = {Water = math.huge}})
		local computed = pcall(function() path:ComputeAsync(self.Root.Position, dryDestination) end)
		if not computed or path.Status ~= Enum.PathStatus.Success or generation ~= self.PathGeneration then
			if generation == self.PathGeneration then
				self.PathActive = false
				if not self.Fleeing then self.NextWanderTime = os.clock() + self.Random:NextNumber(Config.WANDER_DELAY_MIN, Config.WANDER_DELAY_MAX) end
			end
			return
		end
		local previousPosition = self.Root.Position
		for _, waypoint in path:GetWaypoints() do
			if not self.Active or generation ~= self.PathGeneration then return end
			local dry = self:_getDryGround(waypoint.Position)
			if not dry or not self:_isDrySegment(previousPosition, waypoint.Position) then break end
			if waypoint.Action == Enum.PathWaypointAction.Jump then self.Humanoid.Jump = true end
			self.Humanoid:MoveTo(waypoint.Position)
			local reached = self.Humanoid.MoveToFinished:Wait()
			if not reached or generation ~= self.PathGeneration then break end
			previousPosition = waypoint.Position
		end
		if generation == self.PathGeneration then
			self.PathActive = false
			if not self.Fleeing then self.NextWanderTime = os.clock() + self.Random:NextNumber(Config.WANDER_DELAY_MIN, Config.WANDER_DELAY_MAX) end
		end
	end)
	return true
end

function BisonAI:_findThreat()
	local closestRoot, closestDistance = nil, Config.THREAT_RADIUS
	for _, candidate in workspace:GetChildren() do
		local humanoid = candidate:FindFirstChildOfClass("Humanoid")
		local root = candidate:FindFirstChild("Torso") or candidate:FindFirstChild("HumanoidRootPart")
		if candidate ~= self.Model and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			local distance = (self.Root.Position - root.Position).Magnitude
			if distance < closestDistance then closestRoot, closestDistance = root, distance end
		end
	end
	return closestRoot
end

function BisonAI:_flee()
	if self.Fleeing then return end
	self.Fleeing = true
	self.Humanoid.WalkSpeed = Config.FLEE_SPEED
	local threat = self:_findThreat()
	if threat then
		local offset = threat.Position - self.Root.Position
		if offset.Magnitude > 0.01 then
			local legacyDestination = self.Root.CFrame * CFrame.new(offset.Unit * Config.FLEE_DISTANCE)
			self:_requestPath(legacyDestination.Position)
		end
	else
		self.NextWanderTime = os.clock()
	end
	task.delay(Config.FLEE_DURATION, function()
		if not self.Active or self.Humanoid.Health <= 0 then return end
		self.Fleeing = false
		self.Humanoid.WalkSpeed = Config.NORMAL_SPEED
		self.NextWanderTime = os.clock()
	end)
end

function BisonAI:_recoverFromWater()
	self.PathGeneration += 1
	self.PathActive = false
	if not self.LastSafeGroundPosition then
		self.Humanoid:MoveTo(self.Root.Position)
		return
	end
	local distance = (self.Root.Position - self.LastSafeGroundPosition).Magnitude
	if not self.RecoveryStartedAt then
		self.RecoveryStartedAt = os.clock()
		self.LastRecoveryDistance = distance
	elseif distance + 0.5 < self.LastRecoveryDistance then
		self.RecoveryStartedAt = os.clock()
		self.LastRecoveryDistance = distance
	elseif os.clock() - self.RecoveryStartedAt >= Config.RECOVERY_STUCK_SECONDS then
		self.Model:PivotTo(self.Model:GetPivot() + (self.LastSafeGroundPosition - self.Root.Position))
		self.RecoveryStartedAt = os.clock()
	end
	self.Humanoid:MoveTo(self.LastSafeGroundPosition)
end

function BisonAI:Step(deltaTime)
	if not self.Active or not self.Model.Parent or self.Humanoid.Health <= 0 then return false end
	self.SafetyAccumulator += deltaTime
	if self.SafetyAccumulator < Config.SAFETY_CHECK_INTERVAL then return true end
	self.SafetyAccumulator %= Config.SAFETY_CHECK_INTERVAL

	local dry = self:_getDryGround(self.Root.Position)
	if not dry then self:_recoverFromWater(); return true end
	if math.abs(self.Root.AssemblyLinearVelocity.Y) <= Config.SAFE_MAX_VERTICAL_SPEED then
		self.LastSafeGroundPosition = self.Root.Position
	end
	self.RecoveryStartedAt = nil
	if self.PathActive or self.Fleeing or os.clock() < self.NextWanderTime then return true end

	local offset = Vector3.new(self.Random:NextInteger(-Config.WANDER_RADIUS, Config.WANDER_RADIUS), 0,
		self.Random:NextInteger(-Config.WANDER_RADIUS, Config.WANDER_RADIUS))
	if not self:_requestPath(self.Root.Position + offset) then
		self.NextWanderTime = os.clock() + self.Random:NextNumber(Config.WANDER_DELAY_MIN, Config.WANDER_DELAY_MAX)
	end
	return true
end

function BisonAI:Stop()
	self.Active = false
	self.PathGeneration += 1
	if self.HealthConnection then self.HealthConnection:Disconnect(); self.HealthConnection = nil end
end

return BisonAI
