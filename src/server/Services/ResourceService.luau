local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local HarvestConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("HarvestConfig"))
local BalanceConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("BalanceConfig"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local SurvivalService = require(script.Parent:WaitForChild("SurvivalService"))

local ResourceService = {}
ResourceService.__index = ResourceService

local function getResourceDistance(rootPart, resource)
	if resource:IsA("BasePart") then
		return (resource:GetClosestPointOnSurface(rootPart.Position) - rootPart.Position).Magnitude
	end

	local shortestDistance = math.huge
	for _, descendant in resource:GetDescendants() do
		if descendant:IsA("BasePart") then
			local distance = (descendant:GetClosestPointOnSurface(rootPart.Position) - rootPart.Position).Magnitude
			shortestDistance = math.min(shortestDistance, distance)
		end
	end
	return shortestDistance
end

local function findHealthValue(resource)
	local health = resource:FindFirstChild("Health", true)
	if health and (health:IsA("NumberValue") or health:IsA("IntValue")) then
		return health
	end
	return nil
end

function ResourceService.new()
	local self = setmetatable({}, ResourceService)
	self._lastHits = {}
	self._maximumHealth = {}
	self._request = Instance.new("RemoteEvent")
	self._request.Name = "HarvestRequest"
	self._request.Parent = ReplicatedStorage
	self._result = Instance.new("RemoteEvent")
	self._result.Name = "HarvestResult"
	self._result.Parent = ReplicatedStorage
	return self
end

function ResourceService:_initializeResource(resource)
	local definition = HarvestConfig.Resources[resource.Name]
	if not definition then return end
	local healthValue = findHealthValue(resource)
	if not healthValue then
		healthValue = Instance.new("IntValue")
		healthValue.Name = "Health"
		healthValue.Parent = resource
	end
	healthValue.Value = definition.MaxHealth
	self._maximumHealth[resource] = definition.MaxHealth
end

function ResourceService:_getResource(target)
	local resourcesFolder = workspace:FindFirstChild("Resources")
	if not resourcesFolder or typeof(target) ~= "Instance" then
		return nil
	end

	local current = target
	while current and current.Parent ~= resourcesFolder do
		current = current.Parent
	end
	if current and current.Parent == resourcesFolder and HarvestConfig.Resources[current.Name] then
		return current
	end
	return nil
end

function ResourceService:_respawn(resource, healthValue, parent, definition)
	task.delay(definition.RespawnTime, function()
		if not resource or not parent or not parent.Parent then
			return
		end
		healthValue.Value = definition.MaxHealth
		resource.Parent = parent
	end)
end

function ResourceService:_handleHarvest(player, target)
	local resource = self:_getResource(target)
	if not resource then
		print("[MAYDEAD] Harvest rejected: invalid target")
		return
	end

	local definition = HarvestConfig.Resources[resource.Name]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not rootPart then
		return
	end

	local equippedTool = character:FindFirstChildOfClass("Tool")
	print("[MAYDEAD] Harvest request:")
	print("Player = " .. player.Name)
	print("Tool = " .. (equippedTool and equippedTool.Name or "NONE"))
	print("Resource = " .. resource.Name)
	local damage
	local rewardQuantity = definition.LootQuantity
	if definition.LootQuantityMin and definition.LootQuantityMax then
		rewardQuantity = math.random(definition.LootQuantityMin, definition.LootQuantityMax)
	end
	local isHandHarvest = false
	if equippedTool and equippedTool:IsA("Tool") then
		local toolDefinition = definition.Tools[equippedTool.Name]
		if not toolDefinition or InventoryService:GetActiveItem(player) ~= toolDefinition.ItemId then
			print("[MAYDEAD] Harvest rejected: wrong tool")
			return
		end
		damage = toolDefinition.Damage
	else
		if not definition.CanHarvestByHand then
			self._result:FireClient(player, "ToolRequired")
			return
		end
		isHandHarvest = true
		damage = definition.HandDamage
		rewardQuantity = definition.HandHarvestAmount
		if typeof(damage) ~= "number" or damage <= 0
			or typeof(rewardQuantity) ~= "number" or rewardQuantity <= 0
		then
			warn("[MAYDEAD] Invalid hand harvesting configuration for " .. resource.Name)
			return
		end
	end

	if getResourceDistance(rootPart, resource) > HarvestConfig.HARVEST_RANGE then
		print("[MAYDEAD] Harvest rejected: too far")
		return
	end

	local now = os.clock()
	local lastHit = self._lastHits[player] or 0
	if now - lastHit < HarvestConfig.HARVEST_COOLDOWN then
		print("[MAYDEAD] Harvest rejected: cooldown")
		return
	end
	self._lastHits[player] = now

	local healthValue = findHealthValue(resource)
	if not healthValue or healthValue.Value <= 0 then
		print("[MAYDEAD] Harvest rejected: resource dead")
		return
	end
	local maximumHealth = self._maximumHealth[resource] or healthValue.Value
	self._maximumHealth[resource] = maximumHealth

	local willDestroy = healthValue.Value - damage <= 0
	if willDestroy and not InventoryService:CanAddItem(player, definition.LootItemId, rewardQuantity) then
		print("[MAYDEAD] Harvest rejected: inventory full")
		self._result:FireClient(player, "InventoryFull")
		return
	end

	healthValue.Value = math.max(0, healthValue.Value - damage)
	print("[MAYDEAD] Harvest accepted")
	print("[MAYDEAD] " .. resource.Name .. " Health = " .. tostring(healthValue.Value))
	if isHandHarvest then
		SurvivalService:ConsumeEnergy(player, SurvivalService.HandHarvestEnergyCost)
	end
	self._result:FireClient(player, definition.ImpactSoundName, healthValue.Value, maximumHealth, isHandHarvest, resource)

	if healthValue.Value <= 0 then
		local result = InventoryService:AddItem(player, definition.LootItemId, rewardQuantity)
		if result.Remaining > 0 then
			healthValue.Value = math.max(1, maximumHealth)
			return
		end

		local parent = resource.Parent
		resource.Parent = nil
		if BalanceConfig.BALANCE_DEBUG then
			local harvestMode = isHandHarvest and "Hand" or "Tool"
			print("[MAYDEAD][BALANCE] " .. harvestMode .. " harvest " .. resource.Name .. " -> " .. definition.LootItemId .. " +" .. rewardQuantity)
		end
		self:_respawn(resource, healthValue, parent, definition)
	end
end

function ResourceService:Start()
	local resourcesFolder = workspace:FindFirstChild("Resources")
	if resourcesFolder then
		for _, resource in resourcesFolder:GetChildren() do
			self:_initializeResource(resource)
		end
		resourcesFolder.ChildAdded:Connect(function(resource) self:_initializeResource(resource) end)
	else
		warn("[MAYDEAD] Workspace.Resources not found; harvesting disabled")
	end

	Players.PlayerRemoving:Connect(function(player)
		self._lastHits[player] = nil
	end)

	self._request.OnServerEvent:Connect(function(player, target)
		if player:GetAttribute("SessionStarted") ~= true then return end
		self:_handleHarvest(player, target)
	end)
end

return ResourceService.new()
