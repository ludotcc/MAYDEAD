local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JellyfishConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("JellyfishConfig")
)

local JellyfishAI = {}
JellyfishAI.__index = JellyfishAI

local function isAdmittedWorldPlayer(player)
	return player.Parent == Players
		and player:GetAttribute("SessionStarted") == true
		and player:GetAttribute("InMainMenu") ~= true
		and player:GetAttribute("ReturningToMenu") ~= true
end

function JellyfishAI.new(model, isPlayerAquatic, damagePlayer, isPointInWater)
	local root = model.PrimaryPart
	if not root or not root:IsA("BasePart") then
		return nil
	end

	local self = setmetatable({}, JellyfishAI)
	self.Model = model
	self.Root = root
	self.HomePivot = model:GetPivot()
	self.HomePosition = self.HomePivot.Position
	self.Target = nil
	self.LastAttackByPlayer = setmetatable({}, {__mode = "k"})
	self.TargetRefreshAccumulator = JellyfishConfig.TARGET_REFRESH_INTERVAL
	self.IsPlayerAquatic = isPlayerAquatic
	self.DamagePlayer = damagePlayer
	self.IsPointInWater = isPointInWater
	self.LastWaterCellKey = nil
	self.LastWaterCellResult = false
	self.Active = true

	model:SetAttribute("JellyfishHazard", true)
	model:SetAttribute("Invulnerable", true)
	model:SetAttribute("IsDead", false)
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.BreakJointsOnDeath = false
		humanoid.RequiresNeck = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		local protectedHealth = humanoid.MaxHealth
		humanoid.Health = protectedHealth
		humanoid.HealthChanged:Connect(function(health)
			if self.Active and health < protectedHealth then
				humanoid.Health = protectedHealth
			end
		end)
	end

	return self
end

function JellyfishAI:_isPointInWaterCached(position)
	local resolution = JellyfishConfig.WATER_VOXEL_RESOLUTION
	local cellKey = string.format(
		"%d:%d:%d",
		math.floor(position.X / resolution),
		math.floor(position.Y / resolution),
		math.floor(position.Z / resolution)
	)
	if cellKey ~= self.LastWaterCellKey then
		self.LastWaterCellKey = cellKey
		self.LastWaterCellResult = self.IsPointInWater(position)
	end
	return self.LastWaterCellResult
end

function JellyfishAI:_getValidTargetData(player)
	if not isAdmittedWorldPlayer(player) or not self.IsPlayerAquatic(player) then
		return nil
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil
	end
	if (root.Position - self.HomePosition).Magnitude > JellyfishConfig.LEASH_RADIUS then
		return nil
	end
	return root, (root.Position - self.Root.Position).Magnitude
end

function JellyfishAI:_refreshTarget()
	local closestPlayer = nil
	local closestDistance = JellyfishConfig.DETECTION_RADIUS
	for _, player in Players:GetPlayers() do
		local _, distance = self:_getValidTargetData(player)
		if distance and distance <= closestDistance then
			closestPlayer = player
			closestDistance = distance
		end
	end
	self.Target = closestPlayer
end

function JellyfishAI:_moveToward(position, speed, deltaTime)
	local currentPivot = self.Model:GetPivot()
	local offset = position - currentPivot.Position
	local distance = offset.Magnitude
	if distance <= 0.01 then
		return
	end
	local movement = offset.Unit * math.min(distance, speed * deltaTime)
	local nextPosition = currentPivot.Position + movement
	if self:_isPointInWaterCached(nextPosition) then
		self.Model:PivotTo(currentPivot + movement)
	elseif self.Target then
		self.Target = nil
	end
end

function JellyfishAI:_tryAttack(player, distance)
	if distance > JellyfishConfig.ATTACK_RADIUS then
		return
	end
	local now = os.clock()
	if now - (self.LastAttackByPlayer[player] or -math.huge) < JellyfishConfig.DAMAGE_COOLDOWN then
		return
	end
	if self.DamagePlayer(player, JellyfishConfig.DAMAGE) then
		self.LastAttackByPlayer[player] = now
	end
end

function JellyfishAI:Step(deltaTime)
	if not self.Active or not self.Model.Parent or not self.Root.Parent then
		self.Active = false
		return false
	end

	self.TargetRefreshAccumulator += deltaTime
	if self.TargetRefreshAccumulator >= JellyfishConfig.TARGET_REFRESH_INTERVAL then
		self.TargetRefreshAccumulator %= JellyfishConfig.TARGET_REFRESH_INTERVAL
		self:_refreshTarget()
	end

	if (self.Root.Position - self.HomePosition).Magnitude > JellyfishConfig.LEASH_RADIUS then
		self.Target = nil
	end

	if self.Target then
		local targetRoot, distance = self:_getValidTargetData(self.Target)
		if targetRoot and distance then
			self:_tryAttack(self.Target, distance)
			self:_moveToward(targetRoot.Position, JellyfishConfig.MOVE_SPEED, deltaTime)
			return true
		end
		self.Target = nil
	end

	self:_moveToward(self.HomePosition, JellyfishConfig.RETURN_SPEED, deltaTime)
	return true
end

function JellyfishAI:RemovePlayer(player)
	self.LastAttackByPlayer[player] = nil
	if self.Target == player then
		self.Target = nil
	end
end

function JellyfishAI:Stop()
	self.Active = false
	self.Target = nil
	table.clear(self.LastAttackByPlayer)
end

return JellyfishAI
