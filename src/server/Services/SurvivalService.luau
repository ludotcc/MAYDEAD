local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local SurvivalConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("SurvivalConfig"))

local SurvivalService = {}
SurvivalService.__index = SurvivalService

local REMOTE_NAME = "SurvivalStateChanged"
local DRINK_REQUEST_NAME = "DrinkRequest"
local DRINK_RESULT_NAME = "DrinkResult"

local function createInitialState()
	return {
		Health = 100,
		Hunger = 100,
		Thirst = 100,
		Energy = 100,
		Breath = 100,
		Underwater = false,
		IsAlive = true,
	}
end

local function clamp(value, minValue, maxValue)
	return math.max(minValue, math.min(maxValue, value))
end

local function getTerrainWaterSurface(position)
	local resolution = 4
	local voxelCorner = Vector3.new(
		math.floor(position.X / resolution) * resolution,
		math.floor(position.Y / resolution) * resolution,
		math.floor(position.Z / resolution) * resolution
	)
	local region = Region3.new(voxelCorner, voxelCorner + Vector3.new(resolution, resolution, resolution))
	local waterOccupancy = 0
	local channelReadSucceeded, channels = pcall(function()
		return workspace.Terrain:ReadVoxelChannels(region, resolution, {"LiquidOccupancy"})
	end)

	if channelReadSucceeded and channels and channels.LiquidOccupancy then
		waterOccupancy = channels.LiquidOccupancy[1][1][1]
	else
		local materials, occupancy = workspace.Terrain:ReadVoxels(region, resolution)
		if materials[1][1][1] == Enum.Material.Water then
			waterOccupancy = occupancy[1][1][1]
		end
	end

	if waterOccupancy <= 0 then
		return nil
	end
	return voxelCorner.Y + (waterOccupancy * resolution)
end

function SurvivalService.new()
	local self = setmetatable({}, SurvivalService)
	self.PlayerStates = {}
	self._connections = {}
	self._lastUnderwaterStates = {}
	self._lastDrinkAttempts = {}
	self._baseWalkSpeeds = {}
	self.HandHarvestEnergyCost = SurvivalConfig.HAND_HARVEST_ENERGY_COST
	self._running = false
	self._updateAccumulator = 0
	self._remote = Instance.new("RemoteEvent")
	self._remote.Name = REMOTE_NAME
	self._remote.Parent = ReplicatedStorage
	self._drinkRequest = Instance.new("RemoteEvent")
	self._drinkRequest.Name = DRINK_REQUEST_NAME
	self._drinkRequest.Parent = ReplicatedStorage
	self._drinkResult = Instance.new("RemoteEvent")
	self._drinkResult.Name = DRINK_RESULT_NAME
	self._drinkResult.Parent = ReplicatedStorage
	return self
end

function SurvivalService:Start()
	if self._running then
		return
	end

	self._running = true

	Players.PlayerAdded:Connect(function(player)
		self.PlayerStates[player] = createInitialState()
		self:_syncPlayer(player)

		self._connections[player] = player.CharacterAdded:Connect(function(character)
			self:_onCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.PlayerStates[player] = nil
		self._lastUnderwaterStates[player] = nil
		self._lastDrinkAttempts[player] = nil
		self._baseWalkSpeeds[player] = nil
		if self._connections[player] then
			self._connections[player]:Disconnect()
			self._connections[player] = nil
		end
	end)

	self._drinkRequest.OnServerEvent:Connect(function(player)
		if player:GetAttribute("SessionStarted") ~= true then return end
		self:_handleDrinkRequest(player)
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		self._updateAccumulator = self._updateAccumulator + deltaTime
		if self._updateAccumulator < SurvivalConfig.UPDATE_INTERVAL then
			return
		end

		local updateDelta = self._updateAccumulator
		self._updateAccumulator = 0

		for player, state in pairs(self.PlayerStates) do
			if not player or not player.Parent then
				continue
			end

			if not state.IsAlive then
				continue
			end
			if player:GetAttribute("SessionStarted") ~= true then
				continue
			end

			state.Hunger = state.Hunger - (SurvivalConfig.HUNGER_DRAIN_PER_SECOND * updateDelta)
			state.Thirst = state.Thirst - (SurvivalConfig.THIRST_DRAIN_PER_SECOND * updateDelta)
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			local isMoving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.05
			local energyDrain = isMoving
				and SurvivalConfig.ENERGY_MOVEMENT_DRAIN_PER_SECOND
				or SurvivalConfig.ENERGY_IDLE_DRAIN_PER_SECOND
			state.Energy = state.Energy - (energyDrain * updateDelta)

			state.Hunger = clamp(state.Hunger, 0, 100)
			state.Thirst = clamp(state.Thirst, 0, 100)
			state.Energy = clamp(state.Energy, 0, 100)

			state.Underwater = self:_isHeadUnderwater(player.Character)
			if self._lastUnderwaterStates[player] ~= state.Underwater then
				self._lastUnderwaterStates[player] = state.Underwater
				print("[MAYDEAD] Underwater = " .. tostring(state.Underwater))
			end
			if state.Underwater then
				state.Breath = state.Breath - ((100 / SurvivalConfig.BREATH_DURATION) * updateDelta)
			else
				state.Breath = state.Breath + ((100 / SurvivalConfig.BREATH_RECOVERY_DURATION) * updateDelta)
			end
			state.Breath = clamp(state.Breath, 0, 100)

			local damagePerSecond = 0
			if state.Hunger <= 0 then
				damagePerSecond = damagePerSecond + SurvivalConfig.STARVATION_DAMAGE_PER_SECOND
			end
			if state.Thirst <= 0 then
				damagePerSecond = damagePerSecond + SurvivalConfig.DEHYDRATION_DAMAGE_PER_SECOND
			end
			if state.Breath <= 0 and state.Underwater then
				damagePerSecond = damagePerSecond + SurvivalConfig.DROWNING_DAMAGE_PER_SECOND
			end

			local maxHealth = humanoid and humanoid.MaxHealth or 100
			if humanoid then
				state.Health = math.min(state.Health, humanoid.Health)
			end
			if damagePerSecond > 0 then
				state.Health = state.Health - (damagePerSecond * updateDelta)
			end
			if state.Hunger > SurvivalConfig.HEALTH_REGEN_MIN_HUNGER
				and state.Thirst > SurvivalConfig.HEALTH_REGEN_MIN_THIRST
				and state.Health > 0
				and state.Health < maxHealth
			then
				state.Health = state.Health + (SurvivalConfig.HEALTH_REGEN_PER_SECOND * updateDelta)
			end

			state.Health = clamp(state.Health, 0, maxHealth)
			if humanoid and humanoid.Health ~= state.Health then
				humanoid.Health = state.Health
			end
			if humanoid then
				self:_applyFatigueSpeed(player, humanoid, state.Energy)
			end

			if state.Health <= 0 then
				state.IsAlive = false
				self:_applyDeath(player)
			end

			self:_syncPlayer(player)
		end
	end)
end

function SurvivalService:_getFatigueMultiplier(energy)
	if energy >= SurvivalConfig.FATIGUE_START_PERCENT then
		return 1
	end
	if energy >= SurvivalConfig.FATIGUE_FULL_PERCENT then
		local alpha = (SurvivalConfig.FATIGUE_START_PERCENT - energy)
			/ (SurvivalConfig.FATIGUE_START_PERCENT - SurvivalConfig.FATIGUE_FULL_PERCENT)
		return 1 + ((SurvivalConfig.FATIGUE_START_MULTIPLIER - 1) * alpha)
	end
	local alpha = (SurvivalConfig.FATIGUE_FULL_PERCENT - math.max(energy, 0))
		/ SurvivalConfig.FATIGUE_FULL_PERCENT
	return SurvivalConfig.FATIGUE_START_MULTIPLIER
		+ ((SurvivalConfig.FATIGUE_ZERO_MULTIPLIER - SurvivalConfig.FATIGUE_START_MULTIPLIER) * alpha)
end

function SurvivalService:_applyFatigueSpeed(player, humanoid, energy)
	local rootPart = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
	if humanoid.PlatformStand or (rootPart and rootPart.Anchored) then return end
	local baseSpeed = self._baseWalkSpeeds[player] or humanoid.WalkSpeed
	self._baseWalkSpeeds[player] = baseSpeed
	local targetSpeed = baseSpeed * self:_getFatigueMultiplier(energy)
	if math.abs(humanoid.WalkSpeed - targetSpeed) > 0.01 then
		humanoid.WalkSpeed = targetSpeed
	end
end

function SurvivalService:ConsumeEnergy(player, amount)
	if typeof(amount) ~= "number" or amount <= 0 then return 0 end
	local state = self.PlayerStates[player]
	if not state or not state.IsAlive then return 0 end
	local previousEnergy = state.Energy
	state.Energy = clamp(state.Energy - amount, 0, 100)
	self:_syncPlayer(player)
	return previousEnergy - state.Energy
end

function SurvivalService:_isHeadUnderwater(character)
	if not character then
		return false
	end

	local head = character:FindFirstChild("Head")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not head or not humanoid or humanoid.Health <= 0 then
		return false
	end

	local position = head.Position
	local waterSurfaceY = getTerrainWaterSurface(position)
	return waterSurfaceY ~= nil and position.Y < waterSurfaceY
end

function SurvivalService:IsPointInTerrainWater(position)
	return typeof(position) == "Vector3" and getTerrainWaterSurface(position) ~= nil
end

function SurvivalService:IsPlayerAquatic(player)
	local state = self.PlayerStates[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return state ~= nil
		and state.IsAlive
		and humanoid ~= nil
		and humanoid.Health > 0
		and root ~= nil
		and root:IsA("BasePart")
		and humanoid:GetState() == Enum.HumanoidStateType.Swimming
		and getTerrainWaterSurface(root.Position) ~= nil
end

function SurvivalService:DamagePlayer(player, amount)
	if typeof(amount) ~= "number" or amount <= 0 then
		return false
	end
	local state = self.PlayerStates[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not state or not state.IsAlive or not humanoid or humanoid.Health <= 0 then
		return false
	end
	state.Health = clamp(math.min(state.Health, humanoid.Health) - amount, 0, humanoid.MaxHealth)
	humanoid.Health = state.Health
	if state.Health <= 0 then
		state.IsAlive = false
		self:_applyDeath(player)
	end
	self:_syncPlayer(player)
	return true
end

function SurvivalService:SetThirst(player, value)
	if typeof(value) ~= "number" then
		return false
	end

	local state = self.PlayerStates[player]
	if not state or not state.IsAlive then
		return false
	end

	local targetThirst = clamp(value, 0, 100)
	if state.Thirst ~= targetThirst then
		state.Thirst = targetThirst
		self:_syncPlayer(player)
		return true
	end
	return false
end

function SurvivalService:AddHunger(player, amount)
	if typeof(amount) ~= "number" or amount <= 0 then
		return 0
	end

	local state = self.PlayerStates[player]
	if not state or not state.IsAlive or state.Hunger >= 100 then
		return 0
	end

	local previousHunger = state.Hunger
	state.Hunger = clamp(state.Hunger + amount, 0, 100)
	local restored = state.Hunger - previousHunger
	self:_syncPlayer(player)
	return restored
end

function SurvivalService:AddEnergy(player, amount)
	if typeof(amount) ~= "number" or amount <= 0 then
		return 0
	end

	local state = self.PlayerStates[player]
	if not state or not state.IsAlive then
		return 0
	end

	local previousEnergy = state.Energy
	state.Energy = clamp(state.Energy + amount, 0, 100)
	return state.Energy - previousEnergy
end

function SurvivalService:RecoverFromCamp(player, deltaTime, fullRecoveryDuration)
	if typeof(deltaTime) ~= "number" or deltaTime <= 0
		or typeof(fullRecoveryDuration) ~= "number" or fullRecoveryDuration <= 0
	then
		return false
	end
	local state = self.PlayerStates[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not state or not state.IsAlive or not humanoid or humanoid.Health <= 0 then
		return false
	end

	local maxHealth = humanoid.MaxHealth
	local healthRate = maxHealth / fullRecoveryDuration
	local energyRate = 100 / fullRecoveryDuration
	-- Respect damage applied directly to the Humanoid before adding this tick's recovery.
	state.Health = clamp(math.min(state.Health, humanoid.Health) + (healthRate * deltaTime), 0, maxHealth)
	state.Energy = clamp(state.Energy + (energyRate * deltaTime), 0, 100)
	humanoid.Health = state.Health
	self:_syncPlayer(player)
	return state.Health >= maxHealth and state.Energy >= 100
end

function SurvivalService:CanInteractWithTerrainWater(player)
	local state = self.PlayerStates[player]
	local character = player.Character
	return state ~= nil
		and state.IsAlive
		and character ~= nil
		and not self:_isHeadUnderwater(character)
		and self:_isNearTerrainWater(character)
end

function SurvivalService:HydrateFromFlask(player)
	local state = self.PlayerStates[player]
	if not state or not state.IsAlive or state.Thirst >= 100 then
		return false
	end
	state.Thirst = 100
	state.Energy = clamp(state.Energy + SurvivalConfig.DRINK_ENERGY_BONUS, 0, 100)
	self:_syncPlayer(player)
	return true
end

function SurvivalService:ConsumeFood(player, hungerRestore, energyRestore, healthDelta)
	local state = self.PlayerStates[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not state or not state.IsAlive or not humanoid or humanoid.Health <= 0 or state.Hunger >= 100 then
		return 0
	end
	if typeof(hungerRestore) ~= "number" or hungerRestore <= 0 then
		return 0
	end
	if typeof(energyRestore) ~= "number" or typeof(healthDelta) ~= "number" then
		return 0
	end

	local previousHunger = state.Hunger
	state.Hunger = clamp(state.Hunger + hungerRestore, 0, 100)
	local restored = state.Hunger - previousHunger
	if restored > 0 then
		if energyRestore > 0 then
			self:AddEnergy(player, energyRestore)
		end
		if healthDelta < 0 then
			humanoid:TakeDamage(-healthDelta)
		end
		self:_syncPlayer(player)
	end
	return restored
end

function SurvivalService:_isNearTerrainWater(character)
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local distance = SurvivalConfig.DRINK_INTERACTION_DISTANCE
	local resolution = 4
	local region = Region3.new(
		rootPart.Position - Vector3.new(distance, distance, distance),
		rootPart.Position + Vector3.new(distance, distance, distance)
	):ExpandToGrid(resolution)
	local materials, occupancy = workspace.Terrain:ReadVoxels(region, resolution)
	local regionCorner = region.CFrame.Position - (region.Size / 2)

	for x = 1, #materials do
		for y = 1, #materials[x] do
			for z = 1, #materials[x][y] do
				if materials[x][y][z] == Enum.Material.Water and occupancy[x][y][z] > 0 then
					local cellCenter = regionCorner + Vector3.new(
						(x - 0.5) * resolution,
						(y - 0.5) * resolution,
						(z - 0.5) * resolution
					)
					if (cellCenter - rootPart.Position).Magnitude <= distance then
						return true
					end
				end
			end
		end
	end

	return false
end

function SurvivalService:_handleDrinkRequest(player)
	local state = self.PlayerStates[player]
	if not state or not state.IsAlive or state.Thirst >= 100 then
		return
	end

	local now = os.clock()
	local lastAttempt = self._lastDrinkAttempts[player] or 0
	if now - lastAttempt < SurvivalConfig.DRINK_COOLDOWN then
		return
	end
	self._lastDrinkAttempts[player] = now

	local character = player.Character
	if not character or self:_isHeadUnderwater(character) or not self:_isNearTerrainWater(character) then
		return
	end

	if self:SetThirst(player, 100) then
		self:AddEnergy(player, SurvivalConfig.DRINK_ENERGY_BONUS)
		self:_syncPlayer(player)
		self._drinkResult:FireClient(player)
	end
end

function SurvivalService:_onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	self._baseWalkSpeeds[player] = humanoid.WalkSpeed
	local state = self.PlayerStates[player]
	if state then
		state.Health = humanoid.Health
		state.Breath = 100
		state.Underwater = false
		state.IsAlive = true
		self._lastUnderwaterStates[player] = nil
		self:_syncPlayer(player)
	end
	humanoid.Died:Connect(function()
		local state = self.PlayerStates[player]
		if state then
			state.IsAlive = false
			self:_syncPlayer(player)
		end
	end)
end

function SurvivalService:_applyDeath(player)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
end

function SurvivalService:_syncPlayer(player)
	local state = self.PlayerStates[player]
	if not state then
		return
	end

	self._remote:FireClient(player, state)
end

return SurvivalService.new()
