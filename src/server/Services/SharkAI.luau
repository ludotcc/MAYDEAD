local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharkConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("SharkConfig"))

local SharkAI = {}
SharkAI.__index = SharkAI

local function isAdmittedWorldPlayer(player)
	return player.Parent == Players and player:GetAttribute("SessionStarted") == true
		and player:GetAttribute("InMainMenu") ~= true and player:GetAttribute("ReturningToMenu") ~= true
end

local function orientedPivot(position, direction, fallback)
	if direction.Magnitude <= 0.001 then return CFrame.new(position) * fallback.Rotation end
	local forward = direction.Unit
	local zAxis = forward:Cross(Vector3.yAxis)
	if zAxis.Magnitude <= 0.001 then return CFrame.new(position) * fallback.Rotation end
	zAxis = zAxis.Unit
	local yAxis = zAxis:Cross(forward).Unit
	return CFrame.fromMatrix(position, forward, yAxis, zAxis)
end

function SharkAI.new(model, isPlayerAquatic, damagePlayer, isPointInWater)
	local root = model.PrimaryPart
	if not root or not root:IsA("BasePart") then return nil end

	local humanoid = model:FindFirstChildOfClass("Humanoid") or Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.MaxHealth = SharkConfig.MAX_HEALTH
	humanoid.Health = SharkConfig.MAX_HEALTH
	humanoid.Parent = model

	local self = setmetatable({}, SharkAI)
	self.Model = model
	self.Root = root
	self.Humanoid = humanoid
	self.HomePivot = model:GetPivot()
	self.HomePosition = self.HomePivot.Position
	self.Target = nil
	self.PatrolTarget = nil
	self.State = "Patrol"
	self.Active = true
	self.Alive = true
	self.TargetRefreshAccumulator = SharkConfig.TARGET_REFRESH_INTERVAL
	self.PatrolRetargetAccumulator = SharkConfig.PATROL_RETARGET_INTERVAL
	self.LastAttackByPlayer = setmetatable({}, {__mode = "k"})
	self.IsPlayerAquatic = isPlayerAquatic
	self.DamagePlayer = damagePlayer
	self.IsPointInWater = isPointInWater
	self.Random = Random.new()
	self.WaterCache = {}
	self.VisualState = {}
	self.BodyParts = {}

	model:SetAttribute("AnimalType", "Shark")
	model:SetAttribute("IsDead", false)
	model:SetAttribute("HomePosition", self.HomePosition)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			table.insert(self.VisualState, {Instance = descendant, Transparency = descendant.Transparency})
			table.insert(self.BodyParts, descendant)
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
			table.insert(self.VisualState, {Instance = descendant, Enabled = descendant.Enabled})
		end
	end
	local hitSurface = model:FindFirstChild("MainBody", true)
	if hitSurface and hitSurface:IsA("BasePart") then hitSurface.CanQuery = true end
	pcall(function() root:SetNetworkOwner(nil) end)
	return self
end

function SharkAI:_distanceToBody(position)
	local shortest = math.huge
	for _, part in self.BodyParts do
		if part.Parent then shortest = math.min(shortest, (part:GetClosestPointOnSurface(position) - position).Magnitude) end
	end
	return shortest
end

function SharkAI:_isPointInWater(position)
	local resolution = SharkConfig.WATER_VOXEL_RESOLUTION
	local key = string.format("%d:%d:%d", math.floor(position.X / resolution), math.floor(position.Y / resolution), math.floor(position.Z / resolution))
	if self.WaterCache[key] == nil then self.WaterCache[key] = self.IsPointInWater(position) end
	return self.WaterCache[key]
end

function SharkAI:_getTargetData(player)
	if not isAdmittedWorldPlayer(player) or not self.IsPlayerAquatic(player) then return nil end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
	if (root.Position - self.HomePosition).Magnitude > SharkConfig.LEASH_RADIUS then return nil end
	return root, (root.Position - self.Root.Position).Magnitude
end

function SharkAI:_refreshTarget()
	local currentDistance
	if self.Target then
		local _, distance = self:_getTargetData(self.Target)
		currentDistance = distance
	end
	local closest, closestDistance = nil, SharkConfig.DETECTION_RADIUS
	for _, player in Players:GetPlayers() do
		local _, distance = self:_getTargetData(player)
		if distance and distance <= closestDistance then closest, closestDistance = player, distance end
	end
	if self.Target and currentDistance and currentDistance <= SharkConfig.DETECTION_RADIUS
		and closest ~= self.Target and closestDistance + SharkConfig.TARGET_SWITCH_ADVANTAGE >= currentDistance
	then return end
	self.Target = closest
end

function SharkAI:_choosePatrolTarget()
	for _ = 1, SharkConfig.PATROL_POINT_ATTEMPTS do
		local angle = self.Random:NextNumber(0, math.pi * 2)
		local radius = math.sqrt(self.Random:NextNumber()) * SharkConfig.PATROL_RADIUS
		local candidate = self.HomePosition + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if self:_isPointInWater(candidate) then self.PatrolTarget = candidate; return end
	end
	self.PatrolTarget = self.HomePosition
end

function SharkAI:_moveToward(position, speed, deltaTime)
	local current = self.Model:GetPivot()
	local offset = position - current.Position
	if offset.Magnitude <= 0.05 then return true end
	local movement = offset.Unit * math.min(offset.Magnitude, speed * deltaTime)
	local nextPosition = current.Position + movement
	if not self:_isPointInWater(nextPosition) then return false end
	local desired = orientedPivot(nextPosition, offset, current)
	local alpha = 1 - math.exp(-SharkConfig.TURN_RESPONSIVENESS * deltaTime)
	local smoothed = current:Lerp(desired, alpha)
	self.Model:PivotTo(CFrame.new(nextPosition) * smoothed.Rotation)
	return true
end

function SharkAI:_tryAttack(player, distance)
	if distance > SharkConfig.ATTACK_RADIUS then return end
	local now = os.clock()
	if now - (self.LastAttackByPlayer[player] or -math.huge) < SharkConfig.DAMAGE_COOLDOWN then return end
	if self.DamagePlayer(player, SharkConfig.DAMAGE) then self.LastAttackByPlayer[player] = now end
end

function SharkAI:Step(deltaTime)
	if not self.Active or not self.Model.Parent or not self.Root.Parent then return false end
	if not self.Alive then return true end
	self.TargetRefreshAccumulator += deltaTime
	if self.TargetRefreshAccumulator >= SharkConfig.TARGET_REFRESH_INTERVAL then
		self.TargetRefreshAccumulator %= SharkConfig.TARGET_REFRESH_INTERVAL
		self:_refreshTarget()
	end
	if (self.Root.Position - self.HomePosition).Magnitude > SharkConfig.LEASH_RADIUS then self.Target = nil end
	if self.Target then
		local root, distance = self:_getTargetData(self.Target)
		if root and distance then
			self.State = "Chase"
			self:_tryAttack(self.Target, self:_distanceToBody(root.Position))
			if not self:_moveToward(root.Position, SharkConfig.CHASE_SPEED, deltaTime) then self.Target = nil end
			return true
		end
		self.Target = nil
	end
	local distanceHome = (self.Root.Position - self.HomePosition).Magnitude
	if distanceHome > SharkConfig.PATROL_RADIUS then
		self.State = "Return"
		self:_moveToward(self.HomePosition, SharkConfig.RETURN_SPEED, deltaTime)
		return true
	end
	self.State = "Patrol"
	self.PatrolRetargetAccumulator += deltaTime
	if not self.PatrolTarget or self.PatrolRetargetAccumulator >= SharkConfig.PATROL_RETARGET_INTERVAL then
		self.PatrolRetargetAccumulator = 0
		self:_choosePatrolTarget()
	end
	if self.PatrolTarget and not self:_moveToward(self.PatrolTarget, SharkConfig.PATROL_SPEED, deltaTime) then
		self.PatrolTarget = nil
	elseif self.PatrolTarget and (self.PatrolTarget - self.Root.Position).Magnitude <= 0.5 then
		self.PatrolTarget = nil
		self.PatrolRetargetAccumulator = SharkConfig.PATROL_RETARGET_INTERVAL
	end
	return true
end

function SharkAI:Kill()
	self.Alive = false
	self.Target = nil
	self.PatrolTarget = nil
	for _, state in self.VisualState do
		if state.Instance.Parent then
			if state.Transparency ~= nil then state.Instance.Transparency = 1; state.Instance.CanQuery = false
			else state.Instance.Enabled = false end
		end
	end
end

function SharkAI:Respawn()
	if not self.Active or not self.Model.Parent then return end
	self.Model:PivotTo(self.HomePivot)
	self.Humanoid.MaxHealth = SharkConfig.MAX_HEALTH
	self.Humanoid.Health = SharkConfig.MAX_HEALTH
	self.Model:SetAttribute("IsDead", false)
	for _, state in self.VisualState do
		if state.Instance.Parent then
			if state.Transparency ~= nil then state.Instance.Transparency = state.Transparency
			else state.Instance.Enabled = state.Enabled end
		end
	end
	local hitSurface = self.Model:FindFirstChild("MainBody", true)
	if hitSurface and hitSurface:IsA("BasePart") then hitSurface.CanQuery = true end
	table.clear(self.WaterCache)
	self.TargetRefreshAccumulator = SharkConfig.TARGET_REFRESH_INTERVAL
	self.PatrolRetargetAccumulator = SharkConfig.PATROL_RETARGET_INTERVAL
	self.Alive = true
	self.State = "Patrol"
end

function SharkAI:RemovePlayer(player)
	self.LastAttackByPlayer[player] = nil
	if self.Target == player then self.Target = nil end
end

function SharkAI:Stop()
	self.Active = false
	self.Target = nil
	table.clear(self.LastAttackByPlayer)
end

return SharkAI
