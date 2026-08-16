local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config.CheetahConfig)
local CheetahAnimator = require(script.Parent:WaitForChild("CheetahAnimator"))
local WorldDropService = require(script.Parent:WaitForChild("WorldDropService"))

local CheetahAI = {}
CheetahAI.__index = CheetahAI

local function debugLog(message)
	if Config.DEBUG then print("[MAYDEAD][CHEETAH] " .. message) end
end

local function findRoot(model)
	local named = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
	if named and named:IsA("BasePart") then return named end
	if model.PrimaryPart then return model.PrimaryPart end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function groundAt(position, exclude)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {exclude}
	params.IgnoreWater = false
	local result = workspace:Raycast(position + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), params)
	if not result or result.Material == Enum.Material.Water then return nil end
	return result.Position
end

local function isInWater(root)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {root.Parent}
	params.IgnoreWater = false
	local result = workspace:Raycast(
		root.Position + Vector3.new(0, Config.WATER_RECOVERY_DEPTH, 0),
		Vector3.new(0, -(Config.WATER_RECOVERY_DEPTH * 2 + 1), 0),
		params
	)
	return result ~= nil and result.Material == Enum.Material.Water
end

function CheetahAI.new(model, homePosition)
	local self = setmetatable({}, CheetahAI)
	self.Model = model
	self.Humanoid = model:FindFirstChildOfClass("Humanoid")
	self.Root = findRoot(model)
	self.HomePosition = homePosition
	self.LastLandPosition = self.Root and self.Root.Position or homePosition
	self.State = "IDLE"
	self.StateUntil = os.clock() + math.random(2, 5)
	self.Target = nil
	self.Threat = {}
	self.LastAggression = 0
	self.LastAttack = 0
	self.LastPounce = 0
	self.LastBurst = 0
	self.LastPath = 0
	self.Waypoints = nil
	self.WaypointIndex = 1
	self.Tamed = false
	self.OwnerUserId = nil
	self.OriginalTamerUserId = nil
	self.Trust = 0
	self.TamingPlayerUserId = nil
	self.LastTrustGain = -math.huge
	self.HasReceivedTamingFeed = false
	self.TamingSessionActive = false
	self.LastSuccessfulTamingFeedTime = nil
	self.CompanionName = Config.COMPANION_DEFAULT_NAME
	self.CanCompleteTaming = nil
	self.CompletingTaming = false
	self.TamingRandom = Random.new()
	self.FoodTarget = nil
	self.LastFoodSearch = 0
	self.OnTamingChanged = nil
	self.Hunger = 100
	self.Inventory = table.create(Config.COMPANION_SLOT_COUNT)
	for index = 1, Config.COMPANION_SLOT_COUNT do self.Inventory[index] = {ItemId = nil, Quantity = 0} end
	self.Command = "Follow"
	self.FollowTargetUserId = nil
	self.StayPosition = homePosition
	self.MountStamina = 100
	self.MountedPlayer = nil
	self.MountInput = Vector3.zero
	self.MountSprint = false
	self.RiderLean = 0
	self.LastLocomotionDebug = 0
	self.LastMountJump = -math.huge
	self.LastHealth = self.Humanoid.Health
	self.OwnerInteractionHold = false
	self.LastFollowPosition = self.Root.Position
	self.LastFollowProgress = os.clock()
	self.Running = true
	self.Animator = CheetahAnimator.new(model, self.Humanoid, self.Root)
	return self
end

function CheetahAI:_setState(state, duration)
	if self.State ~= state then debugLog("State = " .. state) end
	self.State = state
	self.StateUntil = duration and (os.clock() + duration) or math.huge
end

function CheetahAI:_chooseTarget()
	local best, bestScore
	for player, threat in self.Threat do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then
			local distance = (root.Position - self.Root.Position).Magnitude
			local score = threat.Damage * 3 + math.max(0, 100 - distance) + math.max(0, 10 - (os.clock() - threat.LastHit))
			if not bestScore or score > bestScore then best, bestScore = player, score end
		end
	end
	if self.Target ~= best then debugLog("Target = " .. (best and best.Name or "none")) end
	self.Target = best
end

function CheetahAI:RegisterAggression(player, damage)
	self.Animator:PlayHit()
	if self.FoodTarget then WorldDropService:ReleaseFromCheetah(self.FoodTarget, self.Model); self.FoodTarget = nil end
	local threat = self.Threat[player] or {Damage = 0, LastHit = 0}
	threat.Damage += damage
	threat.LastHit = os.clock()
	self.Threat[player] = threat
	self.LastAggression = os.clock()
	if self.TamingPlayerUserId == player.UserId then
		self.Trust = math.max(0, self.Trust - Config.TAMING_AGGRESSION_PENALTY)
		if self.OnTamingChanged then self.OnTamingChanged(self) end
	end
	debugLog("Aggro = " .. player.Name)
	self:_chooseTarget()
	self:_setState("ALERT", 0.35)
end

function CheetahAI:SetTamingState(state)
	if typeof(state) ~= "table" then return end
	if state.Alive == false then return end
	self.Trust = math.clamp(tonumber(state.Trust) or 0, 0, 100)
	self.HasReceivedTamingFeed = state.HasReceivedTamingFeed == true or self.Trust > 0
	self.TamingPlayerUserId = typeof(state.TamingPlayerUserId) == "number" and state.TamingPlayerUserId or nil
	self.Tamed = state.Tamed == true and self.Trust >= 100
	self.OriginalTamerUserId = self.Tamed and (tonumber(state.OriginalTamerUserId)
		or tonumber(state.OwnerUserId) or self.TamingPlayerUserId) or nil
	self.OwnerUserId = self.OriginalTamerUserId
	local savedName = state.CompanionName
	local savedNameLength = typeof(savedName) == "string" and utf8.len(savedName) or nil
	self.CompanionName = savedNameLength and savedNameLength >= Config.COMPANION_NAME_MIN_LENGTH
		and savedNameLength <= Config.COMPANION_NAME_MAX_LENGTH and not savedName:find("%c")
		and savedName or Config.COMPANION_DEFAULT_NAME
	self.Hunger = math.clamp(tonumber(state.Hunger) or 100, 0, 100)
	self.Command = state.Command == "Stay" and "Stay" or "Follow"
	self.MountStamina = math.clamp(tonumber(state.MountStamina) or 100, 0, 100)
	if typeof(state.Inventory) == "table" then
		for index = 1, Config.COMPANION_SLOT_COUNT do
			local slot = state.Inventory[index]
			self.Inventory[index] = typeof(slot) == "table" and slot.ItemId == "RawMeat"
				and {ItemId = "RawMeat", Quantity = math.max(0, math.floor(tonumber(slot.Quantity) or 0))}
				or {ItemId = nil, Quantity = 0}
		end
	end
	if typeof(state.Health) == "number" then self.Humanoid.Health = math.clamp(state.Health, 1, self.Humanoid.MaxHealth) end
	if typeof(state.Position) == "table" and #state.Position == 12 and self.Tamed then
		local validPosition, restoredCFrame = pcall(function()
			return CFrame.new(table.unpack(state.Position))
		end)
		if validPosition then self.Model:PivotTo(restoredCFrame) end
	end
	if self.Command == "Stay" then self.StayPosition = self.Root.Position end
end

function CheetahAI:GetTamingState()
	local position = {self.Model:GetPivot():GetComponents()}
	local inventory = {}
	for index, slot in self.Inventory do inventory[index] = {ItemId = slot.ItemId, Quantity = slot.Quantity} end
	return {Version = 1, Exists = true, Alive = self.Humanoid.Health > 0, Trust = self.Trust,
		TamingPlayerUserId = self.TamingPlayerUserId, Tamed = self.Tamed, OwnerUserId = self.OwnerUserId,
		OriginalTamerUserId = self.OriginalTamerUserId,
		HasReceivedTamingFeed = self.HasReceivedTamingFeed,
		Health = self.Humanoid.Health, Hunger = self.Hunger, Command = self.Command, Inventory = inventory,
		MountStamina = self.MountStamina, Position = position, CompanionName = self.CompanionName}
end

function CheetahAI:GetPublicState()
	return {Tamed = self.Tamed, OwnerUserId = self.OwnerUserId, OriginalTamerUserId = self.OriginalTamerUserId,
		FollowTargetUserId = self.FollowTargetUserId, Trust = self.Trust, Health = self.Humanoid.Health,
		MaxHealth = self.Humanoid.MaxHealth, Hunger = self.Hunger, Command = self.Command,
		Inventory = self.Inventory, MountStamina = self.MountStamina, Mounted = self.MountedPlayer ~= nil,
		CompanionName = self.CompanionName}
end

function CheetahAI:SetCommand(command, player)
	if command ~= "Follow" and command ~= "Stay" then return false end
	self.Command = command
	if command == "Follow" then
		self.FollowTargetUserId = player and player.UserId or self.FollowTargetUserId
	else
		self.FollowTargetUserId = nil
		self.StayPosition = self.Root.Position
	end
	return true
end

function CheetahAI:CompleteTaming(originalTamerUserId)
	if self.Tamed or self.CompletingTaming then return false end
	self.CompletingTaming = true
	self.Trust = 100
	self.Tamed = true
	self.OriginalTamerUserId = originalTamerUserId
	self.OwnerUserId = originalTamerUserId -- Backward-compatible historical field.
	self.FollowTargetUserId = originalTamerUserId
	self.TamingSessionActive = false
	self.CompletingTaming = false
	return true
end

function CheetahAI:AddFood(quantity)
	local remaining = quantity
	for _, slot in self.Inventory do
		if slot.ItemId == "RawMeat" then local add = math.min(50 - slot.Quantity, remaining); slot.Quantity += add; remaining -= add end
	end
	for _, slot in self.Inventory do
		if remaining <= 0 then break end
		if not slot.ItemId then local add = math.min(50, remaining); slot.ItemId = "RawMeat"; slot.Quantity = add; remaining -= add end
	end
	return quantity - remaining
end

function CheetahAI:RemoveFood(quantity)
	local remaining = quantity
	for _, slot in self.Inventory do
		if slot.ItemId == "RawMeat" then
			local take = math.min(slot.Quantity, remaining); slot.Quantity -= take; remaining -= take
			if slot.Quantity <= 0 then slot.ItemId = nil; slot.Quantity = 0 end
			if remaining <= 0 then break end
		end
	end
	return quantity - remaining
end

function CheetahAI:SetMountInput(player, direction, sprint)
	if self.MountedPlayer ~= player or typeof(direction) ~= "Vector3" then return false end
	self.MountInput = Vector3.new(direction.X, 0, direction.Z)
	if self.MountInput.Magnitude > 1 then self.MountInput = self.MountInput.Unit end
	self.MountSprint = sprint == true
	return true
end

function CheetahAI:_companionThink(deltaTime)
	if not self.Tamed then return false end
	self.Hunger = math.max(0, self.Hunger - Config.HUNGER_DECAY_PER_SECOND * deltaTime)
	if self.Hunger <= Config.AUTO_FEED_THRESHOLD and self:RemoveFood(1) == 1 then self.Hunger = math.min(100, self.Hunger + Config.RAW_MEAT_HUNGER_RESTORE) end
	if not next(self.Threat) and self.Hunger > Config.HEALTH_REGEN_MIN_HUNGER then
		self.Humanoid.Health = math.min(self.Humanoid.MaxHealth, self.Humanoid.Health + Config.HEALTH_REGEN_PER_SECOND * deltaTime)
	end
	if self.MountedPlayer then
		local sprinting = self.MountSprint and self.MountStamina > 0
		if sprinting then self.MountStamina = math.max(0, self.MountStamina - Config.MOUNT_STAMINA_DRAIN_PER_SECOND * deltaTime)
		else self.MountStamina = math.min(100, self.MountStamina + Config.MOUNT_STAMINA_REGEN_PER_SECOND * deltaTime) end
		local speed = sprinting and Config.MOUNT_SPRINT_SPEED or (self.MountInput.Magnitude > 0.7 and Config.MOUNT_RUN_SPEED or Config.MOUNT_WALK_SPEED)
		if self.Hunger < Config.MOUNT_LOW_HUNGER_THRESHOLD and sprinting then speed *= Config.MOUNT_LOW_HUNGER_SPRINT_MULTIPLIER end
		self.Humanoid.WalkSpeed = speed
		self.Humanoid:Move(self.MountInput, false)
		local horizontalVelocity = Vector3.new(self.Root.AssemblyLinearVelocity.X, 0, self.Root.AssemblyLinearVelocity.Z).Magnitude
		local targetLean = math.rad(Config.MOUNT_RIDER_LEAN_MAX_DEGREES) * math.clamp(horizontalVelocity / Config.MOUNT_SPRINT_SPEED, 0, 1)
		self.RiderLean += (targetLean - self.RiderLean) * math.clamp(deltaTime * Config.MOUNT_RIDER_LEAN_RESPONSE, 0, 1)
		local seat = self.Model:FindFirstChild("CheetahMountSeat")
		local mountWeld = seat and seat:FindFirstChild("CheetahMountWeld")
		local baseC0 = seat and seat:GetAttribute("MountBaseC0")
		if mountWeld and mountWeld:IsA("Weld") and typeof(baseC0) == "CFrame" then mountWeld.C0 = baseC0 * CFrame.Angles(-self.RiderLean, 0, 0) end
		if Config.CHEETAH_LOCOMOTION_DEBUG and os.clock() - self.LastLocomotionDebug >= 1.5 then
			self.LastLocomotionDebug = os.clock()
			print(string.format("[MAYDEAD][CHEETAH][LOCOMOTION] State=%s Speed=%.2f RiderLean=%.2f", self.State, horizontalVelocity, math.deg(self.RiderLean)))
		end
		return true
	end
	self.RiderLean = 0
	self.MountStamina = math.min(100, self.MountStamina + Config.MOUNT_STAMINA_REGEN_PER_SECOND * deltaTime)
	local followTarget = self.FollowTargetUserId and Players:GetPlayerByUserId(self.FollowTargetUserId)
	local ownerRoot = followTarget and followTarget.Character and followTarget.Character:FindFirstChild("HumanoidRootPart")
	if self.Command == "Follow" then
		if not ownerRoot then
			self:_setState("FOLLOW_WAIT_TARGET")
			self.Humanoid:Move(Vector3.zero)
			self.Humanoid:MoveTo(self.Root.Position)
			return true
		end
		local distance = (ownerRoot.Position - self.Root.Position).Magnitude
		self.OwnerInteractionHold = distance <= Config.FOLLOW_DESIRED_DISTANCE
		if self.OwnerInteractionHold then
			self:_setState("FOLLOW_TARGET_INTERACTION")
			self.Humanoid:Move(Vector3.zero)
			self.Humanoid:MoveTo(self.Root.Position)
		elseif distance > Config.FOLLOW_DESIRED_DISTANCE then
			local now = os.clock()
			if (self.Root.Position - self.LastFollowPosition).Magnitude >= 1 then
				self.LastFollowPosition = self.Root.Position; self.LastFollowProgress = now
			elseif now - self.LastFollowProgress >= Config.FOLLOW_STUCK_TIMEOUT then
				self.LastPath = 0; self.Waypoints = nil; self.LastFollowProgress = now
			end
			if now - self.LastPath >= Config.FOLLOW_PATH_REFRESH_INTERVAL then self.LastPath = 0 end
			local catchingUp = distance >= Config.FOLLOW_CATCH_UP_DISTANCE
			self:_setState(catchingUp and "FOLLOW_CATCHUP" or "FOLLOW_TARGET")
			self:_moveTo(ownerRoot.Position, catchingUp and Config.FOLLOW_CATCH_UP_SPEED or Config.TROT_SPEED)
		end
		return true
	elseif self.Command == "Stay" then
		self.OwnerInteractionHold = false
		self:_setState("STAY")
		if (self.Root.Position - self.StayPosition).Magnitude > Config.STAY_RADIUS then
			self:_moveTo(self.StayPosition, Config.WALK_SPEED)
		else
			self.Humanoid:Move(Vector3.zero)
			self.Humanoid:MoveTo(self.Root.Position)
		end
		return true
	end
	return false
end

function CheetahAI:_safeHumanDistance()
	local index = self.Trust < 25 and 1 or self.Trust < 50 and 2 or self.Trust < 75 and 3 or 4
	return Config.TRUST_HUMAN_DISTANCES[index]
end

function CheetahAI:_foodThink()
	local now = os.clock()
	if self.State == "EAT_FOOD" and self.FoodTarget then
		self.Humanoid:Move(Vector3.zero)
		return true
	end
	if not self.FoodTarget then
		if now - self.LastFoodSearch < Config.FOOD_SEARCH_INTERVAL or now - self.LastTrustGain < Config.TAMING_TRUST_COOLDOWN then return false end
		self.LastFoodSearch = now
		self.FoodTarget = WorldDropService:GetAvailableRawMeat(self.Root.Position, Config.FOOD_DETECTION_RADIUS)
		if self.FoodTarget then self:_setState("INVESTIGATE_FOOD", Config.FOOD_INVESTIGATE_TIME) end
	end
	local food = self.FoodTarget
	if not WorldDropService:IsAvailable(food) then self.FoodTarget = nil; return false end
	local foodPosition = (food:IsA("Model") and food:GetPivot() or food.CFrame).Position
	local nearestHuman = math.huge
	for _, player in Players:GetPlayers() do
		local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if playerRoot then nearestHuman = math.min(nearestHuman, (playerRoot.Position - foodPosition).Magnitude) end
	end
	if nearestHuman < self:_safeHumanDistance() then
		self:_setState("INVESTIGATE_FOOD", 1)
		self.Humanoid:Move(Vector3.zero)
		return true
	end
	if self.State == "INVESTIGATE_FOOD" and now < self.StateUntil then self.Humanoid:Move(Vector3.zero); return true end
	local distance = (self.Root.Position - foodPosition).Magnitude
	if distance > Config.FOOD_APPROACH_DISTANCE then
		self:_setState("APPROACH_FOOD")
		self:_moveTo(foodPosition, distance > 14 and Config.TROT_SPEED or Config.WALK_SPEED)
		return true
	end
	if not WorldDropService:ReserveForCheetah(food, self.Model) then self.FoodTarget = nil; return false end
	self:_setState("EAT_FOOD", Config.FOOD_EAT_TIME)
	self.Humanoid:Move(Vector3.zero)
	task.delay(Config.FOOD_EAT_TIME, function()
		if not self.Running or self.FoodTarget ~= food or next(self.Threat) then
			WorldDropService:ReleaseFromCheetah(food, self.Model)
			if self.FoodTarget == food then self.FoodTarget = nil end
			return
		end
		local feederUserId = WorldDropService:ConsumeForCheetah(food, self.Model)
		self.FoodTarget = nil
		if not feederUserId then return end
		if self.CanCompleteTaming and not self.CanCompleteTaming(feederUserId) then
			if self.OnTamingChanged then self.OnTamingChanged(self, 0, true) end
			print(string.format("[MAYDEAD][CHEETAH][TAMING] Player=%s TrustBefore=%d Gain=0 TrustAfter=%d FoodId=%s CurrentFoodTarget=nil TamedBefore=false CompleteTamingCalled=false Blocked=WorldCompanionExists",
				tostring(feederUserId), self.Trust, self.Trust, food.Name))
			return
		end
		if not self.TamingPlayerUserId then self.TamingPlayerUserId = feederUserId end
		if os.clock() - self.LastTrustGain >= Config.TAMING_TRUST_COOLDOWN then
			local previousTrust = self.Trust
			local tamedBefore = self.Tamed
			local attemptedGain = not self.HasReceivedTamingFeed and Config.TAMING_FIRST_FEED_GAIN
				or self.TamingRandom:NextInteger(Config.TAMING_TRUST_MIN_GAIN, Config.TAMING_TRUST_MAX_GAIN)
			self.HasReceivedTamingFeed = true
			self.Trust = math.min(100, self.Trust + attemptedGain)
			self.LastTrustGain = os.clock()
			if self.Trust >= 100 then
				local canComplete = not self.CanCompleteTaming or self.CanCompleteTaming(self.TamingPlayerUserId)
				if canComplete then
					self:CompleteTaming(self.TamingPlayerUserId)
				else
					self.Trust = previousTrust
				end
			end
			local gain = self.Trust - previousTrust
			if gain > 0 and not self.Tamed then
				self.TamingSessionActive = true
				self.LastSuccessfulTamingFeedTime = self.LastTrustGain
			end
			local blockedByExistingCompanion = self.Trust == previousTrust
				and previousTrust + attemptedGain >= 100 and not self.Tamed
			if self.OnTamingChanged then self.OnTamingChanged(self, gain, blockedByExistingCompanion) end
			print(string.format("[MAYDEAD][CHEETAH][TAMING] Player=%s TrustBefore=%d Gain=%d TrustAfter=%d FoodId=%s CurrentFoodTarget=nil TamedBefore=%s CompleteTamingCalled=%s",
				tostring(self.TamingPlayerUserId), previousTrust, gain, self.Trust, food.Name,
				tostring(tamedBefore), tostring(not tamedBefore and self.Tamed)))
			if self.Tamed then
				print(string.format("[MAYDEAD][CHEETAH][TAMING] RESULT=SUCCESS Trust=100 WorldCompanion=true OriginalTamerUserId=%s",
					tostring(self.OriginalTamerUserId)))
			end
		end
	end)
	return true
end

function CheetahAI:_moveTo(destination, speed)
	local ground = groundAt(destination, self.Model)
	if not ground then debugLog("Water avoided"); return false end
	if (ground - self.HomePosition).Magnitude > Config.MAX_HOME_DISTANCE and self.State ~= "CHASE" then return false end
	self.Humanoid.WalkSpeed += math.clamp(speed - self.Humanoid.WalkSpeed, -Config.SPEED_ACCELERATION * Config.THINK_INTERVAL, Config.SPEED_ACCELERATION * Config.THINK_INTERVAL)
	if os.clock() - self.LastPath >= Config.PATH_RECALCULATE_INTERVAL then
		self.LastPath = os.clock()
		local path = PathfindingService:CreatePath({AgentCanJump = false, WaypointSpacing = 8})
		local ok = pcall(function() path:ComputeAsync(self.Root.Position, ground) end)
		if ok and path.Status == Enum.PathStatus.Success then self.Waypoints, self.WaypointIndex = path:GetWaypoints(), 2 else self.Waypoints = nil end
	end
	local waypoint = self.Waypoints and self.Waypoints[self.WaypointIndex]
	if waypoint and (self.Root.Position - waypoint.Position).Magnitude < 4 then
		self.WaypointIndex += 1
		waypoint = self.Waypoints[self.WaypointIndex]
	end
	self.Humanoid:MoveTo(waypoint and waypoint.Position or ground)
	return true
end

function CheetahAI:_passiveThink()
	local nearest, nearestDistance
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local distance = (root.Position - self.Root.Position).Magnitude
			if not nearestDistance or distance < nearestDistance then nearest, nearestDistance = player, distance end
		end
	end
	if nearestDistance and nearestDistance <= Config.FLEE_DISTANCE then
		local playerRoot = nearest.Character.HumanoidRootPart
		local away = (self.Root.Position - playerRoot.Position).Unit
		self:_setState("FLEE_REPOSITION", 2.5)
		self:_moveTo(self.Root.Position + away * 35, Config.TROT_SPEED)
	elseif nearestDistance and nearestDistance <= Config.OBSERVE_DISTANCE then
		self:_setState("OBSERVE", math.random(2, 4))
		self.Humanoid:Move(Vector3.zero)
	elseif os.clock() >= self.StateUntil then
		if math.random() < 0.45 then
			self:_setState("IDLE", math.random(2, 6))
			self.Humanoid:Move(Vector3.zero)
		else
			self:_setState("ROAM", math.random(4, 9))
			local angle = math.random() * math.pi * 2
			local radius = Config.ROAM_RADIUS_MIN + math.random() * (Config.ROAM_RADIUS_MAX - Config.ROAM_RADIUS_MIN)
			self.RoamDestination = self.HomePosition + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		end
	elseif self.State == "ROAM" and self.RoamDestination then
		self:_moveTo(self.RoamDestination, math.random() < 0.35 and Config.TROT_SPEED or Config.WALK_SPEED)
	elseif self.State == "FLEE_REPOSITION" then
		-- Existing MoveTo continues until the short reposition window ends.
	end
end

function CheetahAI:_combatThink()
	self:_chooseTarget()
	local player = self.Target
	local character = player and player.Character
	local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot then self.Target = nil; return end
	local now = os.clock()
	local distance = (targetRoot.Position - self.Root.Position).Magnitude
	if now - self.LastAggression > Config.AGGRO_MEMORY or distance > Config.MAX_HOME_DISTANCE * 1.5 then
		self.Threat = {}; self.Target = nil; self:_setState("RETURN_HOME"); return
	end
	if distance <= Config.ATTACK_RANGE and now - self.LastAttack >= Config.ATTACK_COOLDOWN then
		self.LastAttack = now
		self:_setState("ATTACK", 0.3)
		self.Animator:PlayAttack()
		local pounce = now - self.LastPounce >= Config.POUNCE_COOLDOWN and math.random() < 0.22
		if pounce then self.LastPounce = now end
		local damage = pounce and Config.POUNCE_DAMAGE or math.random(Config.ATTACK_DAMAGE_MIN, Config.ATTACK_DAMAGE_MAX)
		task.delay(Config.ATTACK_IMPACT_DELAY, function()
			if self.Running and targetHumanoid.Parent and targetHumanoid.Health > 0
				and (targetRoot.Position - self.Root.Position).Magnitude <= Config.ATTACK_RANGE + 1
			then
				targetHumanoid:TakeDamage(damage)
			end
		end)
	else
		self:_setState(distance < 12 and "DEFEND" or "CHASE")
		local burst = now - self.LastBurst >= Config.BURST_COOLDOWN
		if burst then self.LastBurst = now; self.BurstUntil = now + Config.BURST_DURATION end
		self:_moveTo(targetRoot.Position + targetRoot.AssemblyLinearVelocity * 0.2, now < (self.BurstUntil or 0) and Config.BURST_SPEED or Config.CHASE_SPEED)
	end
end

function CheetahAI:Start()
	self.Animator:Start()
	task.spawn(function()
		local lastTick = os.clock()
		while self.Running and self.Model.Parent and self.Humanoid.Health > 0 do
			local now = os.clock(); local deltaTime = math.min(1, now - lastTick); lastTick = now
			if isInWater(self.Root) then
				self.Model:PivotTo(CFrame.new(self.LastLandPosition) * self.Model:GetPivot().Rotation)
				self:_setState("RETURN_HOME")
			else
				local land = groundAt(self.Root.Position, self.Model)
				if land then self.LastLandPosition = self.Root.Position end
			end
			if self.Target or next(self.Threat) then self:_combatThink()
			elseif self:_companionThink(deltaTime) then
			elseif (self.Root.Position - self.HomePosition).Magnitude > Config.MAX_HOME_DISTANCE then self:_setState("RETURN_HOME"); self:_moveTo(self.HomePosition, Config.TROT_SPEED)
			elseif not self:_foodThink() then self:_passiveThink() end
			task.wait(Config.THINK_INTERVAL)
		end
		self.State = "DEAD"
		debugLog("Dead")
	end)
end

function CheetahAI:Stop()
	self.Running = false
	if self.FoodTarget then WorldDropService:ReleaseFromCheetah(self.FoodTarget, self.Model); self.FoodTarget = nil end
	self.Animator:PlayDeath()
end

return CheetahAI
