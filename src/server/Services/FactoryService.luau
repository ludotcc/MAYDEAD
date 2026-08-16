local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local FactoryConfig = require(Shared:WaitForChild("Config"):WaitForChild("FactoryConfig"))
local ItemDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("ItemDefinitions"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local StationService = require(script.Parent:WaitForChild("StationService"))

local FactoryService = {}
FactoryService.__index = FactoryService

local FACTORY_ITEM_TAG = "FactoryItem"
local FACTORY_MACHINE_TAG = "FactoryMachine"
local CONVEYOR_TAG = "FactoryConveyor"
local RECYCLER_GEAR_TAG = "FactoryRecyclerGear"
local WASTE_TYPES = {MetalWaste = true, PlasticWaste = true, WasteBag = true}
local BLOCK_TYPES = {MetalBlock = true, PlasticBlock = true}
local PICKUP_TYPES = {
	MetalWaste = true, PlasticWaste = true, WasteBag = true,
	MetalPanelStack = true, PlasticPanelStack = true,
}
local PHYSICAL_ITEM_TYPES = {
	MetalWaste = true, PlasticWaste = true, WasteBag = true,
	MetalBlock = true, PlasticBlock = true,
	MetalPanelStack = true, PlasticPanelStack = true,
}

local function cloneArray(source)
	local result = {}
	for index, value in source do result[index] = value end
	return result
end

local function validateItemArray(value, allowedItems, maximumLength)
	if typeof(value) ~= "table" or #value > maximumLength then return nil end
	local result = {}
	for index, itemId in ipairs(value) do
		if typeof(itemId) ~= "string" or not allowedItems[itemId] then return nil end
		result[index] = itemId
	end
	local keyCount = 0
	for key in value do
		if typeof(key) ~= "number" or key ~= math.floor(key) or key < 1 or key > #value then return nil end
		keyCount += 1
	end
	if keyCount ~= #value then return nil end
	return result
end

local function validateCounter(value, maximumExclusive)
	return typeof(value) == "number" and value == math.floor(value) and value >= 0 and value < maximumExclusive
		and value or nil
end

local function log(message)
	print("[MAYDEAD][FACTORY] " .. message)
end

local function nameIdentifiesConveyor(name)
	local lowerName = string.lower(name)
	return string.find(lowerName, "conveyor", 1, true) ~= nil
		or string.find(lowerName, "conveyer", 1, true) ~= nil
end

local function getInheritedAttribute(instance, attributeName)
	local current = instance
	while current and current ~= workspace do
		local value = current:GetAttribute(attributeName)
		if value ~= nil then return value end
		current = current.Parent
	end
	return nil
end

local function findNamedDescendant(root, name)
	local direct = root:FindFirstChild(name, true)
	if direct then return direct end
	local expected = string.lower(name)
	for _, descendant in root:GetDescendants() do
		if string.lower(descendant.Name) == expected then return descendant end
	end
	return nil
end

local function getWorldCFrame(instance)
	if instance:IsA("Attachment") then return instance.WorldCFrame end
	if instance:IsA("BasePart") then return instance.CFrame end
	return nil
end

local function isFactoryConveyorPart(instance, factory)
	if not instance:IsA("BasePart") then return false end
	if CollectionService:HasTag(instance, CONVEYOR_TAG) then return true end
	local current = instance
	while current and current ~= factory do
		if nameIdentifiesConveyor(current.Name) then return true end
		current = current.Parent
	end
	return false
end

local function findFactorySurfaceBelow(factory, output, outputCFrame)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = {factory}
	parameters.IgnoreWater = true
	local origin = outputCFrame.Position + Vector3.new(0, 20, 0)
	local remainingDistance = 120
	for _ = 1, 16 do
		local result = workspace:Raycast(origin, Vector3.new(0, -remainingDistance, 0), parameters)
		if not result then return nil end
		if result.Instance ~= output
			and not result.Instance:IsDescendantOf(output)
			and isFactoryConveyorPart(result.Instance, factory)
		then
			return result
		end
		local travelled = origin.Y - result.Position.Y
		remainingDistance -= travelled + 0.05
		if remainingDistance <= 0 then return nil end
		origin = result.Position - Vector3.new(0, 0.05, 0)
	end
	return nil
end

local function getPartBottomY(part)
	local halfSize = part.Size * 0.5
	local projectedHalfHeight = math.abs(part.CFrame.RightVector.Y) * halfSize.X
		+ math.abs(part.CFrame.UpVector.Y) * halfSize.Y
		+ math.abs(part.CFrame.LookVector.Y) * halfSize.Z
	return part.Position.Y - projectedHalfHeight
end

local function getLowestContactY(model)
	local lowestCollidableY = math.huge
	local lowestVisibleY = math.huge
	local collidableParts = 0
	local visibleParts = 0
	local unanchoredCollidableParts = 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local bottomY = getPartBottomY(descendant)
			if descendant.CanCollide then
				lowestCollidableY = math.min(lowestCollidableY, bottomY)
				collidableParts += 1
				if not descendant.Anchored then unanchoredCollidableParts += 1 end
			end
			if descendant.Transparency < 1 then
				lowestVisibleY = math.min(lowestVisibleY, bottomY)
				visibleParts += 1
			end
		end
	end
	if collidableParts > 0 then
		return lowestCollidableY, "Collidable", collidableParts, visibleParts, unanchoredCollidableParts, lowestVisibleY
	end
	if visibleParts > 0 then
		return lowestVisibleY, "VisibleFallback", 0, visibleParts, 0, lowestVisibleY
	end
	return nil
end

local function resolveZonePart(instance)
	if not instance then return nil end
	if instance:IsA("BasePart") then return instance end
	if instance:IsA("Attachment") and instance.Parent and instance.Parent:IsA("BasePart") then return instance.Parent end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function getRootPart(instance)
	if instance:IsA("BasePart") then return instance end
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function findFactoryItemRoot(part)
	local current = part
	while current and current ~= workspace do
		if current:IsA("Model") or current:IsA("BasePart") then
			local itemId = current:GetAttribute("ItemId") or current:GetAttribute("FactoryItemId")
			local explicitlyFactory = current:GetAttribute("FactoryItem") == true
				or CollectionService:HasTag(current, FACTORY_ITEM_TAG)
			if explicitlyFactory and PHYSICAL_ITEM_TYPES[itemId] then
				return current, itemId
			end
		end
		current = current.Parent
	end
	return nil, nil
end

function FactoryService.new()
	local self = setmetatable({}, FactoryService)
	self._machines = setmetatable({}, {__mode = "k"})
	self._conveyors = setmetatable({}, {__mode = "k"})
	self.ActiveFactoryItems = {}
	self.ActiveRecyclers = setmetatable({}, {__mode = "k"})
	self.ActiveIndustrialPresses = setmetatable({}, {__mode = "k"})
	self._debugIntakeItem = nil
	self._recyclerViewers = setmetatable({}, {__mode = "k"})
	self._finalViewers = setmetatable({}, {__mode = "k"})
	self._statusAccumulator = 0
	self._statusOpened = Instance.new("RemoteEvent")
	self._statusOpened.Name = "RecyclerStatusOpened"
	self._statusOpened.Parent = game:GetService("ReplicatedStorage")
	self._statusChanged = Instance.new("RemoteEvent")
	self._statusChanged.Name = "RecyclerStatusChanged"
	self._statusChanged.Parent = game:GetService("ReplicatedStorage")
	self._statusClosed = Instance.new("RemoteEvent")
	self._statusClosed.Name = "RecyclerStatusClosed"
	self._statusClosed.Parent = game:GetService("ReplicatedStorage")
	self._finalRequest = Instance.new("RemoteEvent")
	self._finalRequest.Name = "FinalFactoryRequest"
	self._finalRequest.Parent = game:GetService("ReplicatedStorage")
	self._finalState = Instance.new("RemoteEvent")
	self._finalState.Name = "FinalFactoryStateChanged"
	self._finalState.Parent = game:GetService("ReplicatedStorage")
	self._statusClosed.OnServerEvent:Connect(function(player, machine)
		local viewers = self._recyclerViewers[machine]
		if viewers then viewers[player] = nil end
	end)
	self._spawnBusy = setmetatable({}, {__mode = "k"})
	self._accumulator = 0
	return self
end

local function isUnderConveyor(instance, machine)
	local current = instance.Parent
	while current and current ~= machine do
		if nameIdentifiesConveyor(current.Name) then return true end
		current = current.Parent
	end
	return false
end

local function setWorkEffects(machine, enabled)
	for _, descendant in machine:GetDescendants() do
		if isUnderConveyor(descendant, machine) then continue end
		if descendant:IsA("Light") or descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Trail") then
			descendant.Enabled = enabled
		elseif descendant:IsA("Sound") then
			if enabled and not descendant.Playing then descendant:Play() elseif not enabled then descendant:Stop() end
		end
	end
end

local function isRecyclerGear(part, shredder)
	if part:GetAttribute("RecyclerGear") == true then return true end
	if not shredder or not part:IsDescendantOf(shredder) then return false end
	local name = string.lower(part.Name)
	if string.find(name, "gear", 1, true) or string.find(name, "roller", 1, true)
		or string.find(name, "rouleau", 1, true) or string.find(name, "cylinder", 1, true)
		or string.find(name, "cylindre", 1, true)
	then return true end
	return part:IsA("Part") and part.Shape == Enum.PartType.Cylinder
end

function FactoryService:_prepareMachineVisuals(machine, data)
	if data.Type ~= "Recycler" and data.Type ~= "IndustrialPress" then return end
	machine:SetAttribute("FactoryProcessing", false)
	setWorkEffects(machine, false)
	if data.Type == "Recycler" then
		local shredder = findNamedDescendant(machine, "Shredder")
		local gearIndex = 0
		for _, descendant in machine:GetDescendants() do
			if descendant:IsA("BasePart") and isRecyclerGear(descendant, shredder) then
				gearIndex = gearIndex + 1
				descendant:SetAttribute("RecyclerGearDirection", gearIndex % 2 == 0 and -1 or 1)
				CollectionService:AddTag(descendant, RECYCLER_GEAR_TAG)
				log("Recycler gear registered = " .. descendant:GetFullName())
			end
		end
	end
end

function FactoryService:_setProcessing(data, processing)
	if data.Processing == processing then return end
	data.Processing = processing
	data.Model:SetAttribute("FactoryProcessing", processing)
	data.Model:SetAttribute("FactoryCurrentItemId", processing and data.CurrentItem or nil)
	setWorkEffects(data.Model, processing)
end

function FactoryService:_buildMachineState(data, now)
	local processing = data.CurrentItem ~= nil
	local elapsed = processing and math.max(0, now - (data.ProcessStartedAt or now)) or 0
	local duration = data.Type == "Recycler" and FactoryConfig.RECYCLER_PROCESS_TIME or FactoryConfig.PRESS_PROCESS_TIME
	return {
		MachineType = data.Type,
		Processing = processing, CurrentItemId = data.CurrentItem,
		Progress = processing and math.clamp(elapsed / duration, 0, 1) or 0,
		Remaining = processing and math.max(0, duration - elapsed) or 0,
		QueueLength = #data.Queue, MetalMaterial = data.MetalMaterial, PlasticMaterial = data.PlasticMaterial,
		MetalBlocksProcessed = data.MetalBlocksProcessed, PlasticBlocksProcessed = data.PlasticBlocksProcessed,
		MaterialRatio = data.Type == "Recycler" and FactoryConfig.RECYCLER_MATERIAL_RATIO or FactoryConfig.PRESS_BLOCK_RATIO,
	}
end

function FactoryService:_openMachineStatus(player, machine, data)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - machine:GetPivot().Position).Magnitude > 12 then return end
	self._recyclerViewers[machine][player] = true
	self._statusOpened:FireClient(player, machine, self:_buildMachineState(data, os.clock()))
end

function FactoryService:_registerFactoryItem(instance, itemId)
	self.ActiveFactoryItems[instance] = {
		Instance = instance,
		ItemId = itemId,
		Processing = false,
		LastIntakeDebug = 0,
	}
	if not self._debugIntakeItem and itemId == "MetalWaste" then self._debugIntakeItem = instance end
	log("FactoryItem registered = " .. itemId)
	instance.AncestryChanged:Connect(function()
		if not instance:IsDescendantOf(workspace) then
			self.ActiveFactoryItems[instance] = nil
		end
	end)
end

function FactoryService:_unregisterFactoryItem(instance)
	self.ActiveFactoryItems[instance] = nil
	if self._debugIntakeItem == instance then self._debugIntakeItem = nil end
end

function FactoryService:_asset(itemId)
	local imports = ServerStorage:FindFirstChild("AssetImports")
	local items = imports and imports:FindFirstChild("FactoryItems")
	return items and items:FindFirstChild(itemId) or nil
end

function FactoryService:_preparePhysicalItem(instance, itemId, pickupEnabled)
	instance.Name = itemId
	instance:SetAttribute("FactoryItem", true)
	instance:SetAttribute("ItemId", itemId)
	instance:SetAttribute("FactoryItemId", itemId)
	instance:SetAttribute("FactoryClaimed", false)
	instance:SetAttribute("Quantity", 1)
	instance:SetAttribute("Pickupable", pickupEnabled == true)
	CollectionService:AddTag(instance, FACTORY_ITEM_TAG)
	if instance:IsA("BasePart") then
		instance.Anchored = false
		instance.CanTouch = true
		instance.CanQuery = true
	end
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanTouch = true
			descendant.CanQuery = true
		end
	end
	local root = getRootPart(instance)
	if instance:IsA("Model") and root and not instance.PrimaryPart then instance.PrimaryPart = root end
	if pickupEnabled and root then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "FactoryPickupPrompt"
		prompt.ActionText = "RAMASSER"
		local definition = ItemDefinitions[itemId]
		prompt.ObjectText = definition and definition.DisplayName or itemId
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = FactoryConfig.PICKUP_DISTANCE
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
		prompt.Triggered:Connect(function(player)
			if player:GetAttribute("SessionStarted") ~= true then return end
			self:_pickup(player, instance)
		end)
	end
	return root
end

function FactoryService:_spawnItem(itemId, output, pickupEnabled)
	local template = self:_asset(itemId)
	local outputCFrame = output and getWorldCFrame(output)
	if not template or not outputCFrame then
		warn("[MAYDEAD][FACTORY] Missing asset or output for " .. itemId)
		return nil
	end
	local clone = template:Clone()
	local root = self:_preparePhysicalItem(clone, itemId, pickupEnabled == true)
	if not root then clone:Destroy(); return nil end
	clone.Parent = workspace
	if clone:IsA("Model") then clone:PivotTo(outputCFrame) else clone.CFrame = outputCFrame end
	pcall(function() root:SetNetworkOwner(nil) end)
	self:_registerFactoryItem(clone, itemId)
	log("Spawned " .. itemId .. " at ItemOutput")
	return clone
end

function FactoryService:_pickup(player, item)
	if not item:IsDescendantOf(workspace) or item:GetAttribute("FactoryClaimed") == true then return end
	if item:GetAttribute("Pickupable") ~= true then return end
	local itemId = item:GetAttribute("ItemId") or item:GetAttribute("FactoryItemId")
	if not PICKUP_TYPES[itemId] then return end
	local quantity = item:GetAttribute("Quantity")
	if quantity ~= 1 then return end
	local root = getRootPart(item)
	local characterRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not characterRoot or (root.Position - characterRoot.Position).Magnitude > FactoryConfig.PICKUP_DISTANCE + 2 then return end
	item:SetAttribute("FactoryClaimed", true)
	local result = InventoryService:AddItem(player, itemId, quantity)
	if result.Added == quantity then
		self:_unregisterFactoryItem(item)
		item:Destroy()
		log(player.Name .. " picked up " .. itemId)
	else
		item:SetAttribute("FactoryClaimed", false)
	end
end

function FactoryService:_outputClear(machine, output)
	local outputCFrame = output and getWorldCFrame(output)
	if not outputCFrame then return false end
	local parameters = OverlapParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {machine}
	for _, part in workspace:GetPartBoundsInBox(outputCFrame, FactoryConfig.OUTPUT_CLEARANCE_SIZE, parameters) do
		if findFactoryItemRoot(part) then return false end
	end
	return true
end

local function getItemWorldPosition(instance)
	if instance:IsA("Model") then return instance:GetPivot().Position end
	if instance:IsA("BasePart") then return instance.Position end
	return nil
end

function FactoryService:_registerMachine(machine)
	if self._machines[machine] then return end
	local machineType = machine:GetAttribute("ItemId") or machine.Name
	if machineType ~= "AutomaticLoader" and machineType ~= "Recycler" and machineType ~= "IndustrialPress" and machineType ~= "Factory" then return end
	local inputInstance = machineType ~= "AutomaticLoader" and findNamedDescendant(machine, "ItemInput") or nil
	local input = machineType ~= "AutomaticLoader" and resolveZonePart(inputInstance) or true
	local outputInstance = findNamedDescendant(machine, "ItemOutput")
	local output = outputInstance and (getWorldCFrame(outputInstance) and outputInstance or resolveZonePart(outputInstance)) or nil
	local interaction = machineType == "AutomaticLoader" and findNamedDescendant(machine, "InteractionPoint") or true
	if not input or not output or not interaction then
		warn("[MAYDEAD][FACTORY] " .. machineType .. " missing required ItemInput, ItemOutput or InteractionPoint")
		return
	end
	if machineType == "Recycler" or machineType == "IndustrialPress" then
		log(machineType .. " ItemInput found = " .. tostring(input ~= nil))
		if input then
			log(machineType .. " ItemInput class = " .. input.ClassName)
			log(machineType .. " ItemInput full name = " .. input:GetFullName())
			log(machineType .. " ItemInput size = " .. tostring(input.Size))
			log(machineType .. " ItemInput position = " .. tostring(input.Position))
			log(machineType .. " ItemInput CanTouch = " .. tostring(input.CanTouch))
			log(machineType .. " ItemInput CanQuery = " .. tostring(input.CanQuery))
			log(machineType .. " ItemInput CanCollide = " .. tostring(input.CanCollide))
		end
		log(machineType .. " ItemOutput found = " .. tostring(output ~= nil))
		if output then log(machineType .. " ItemOutput full name = " .. output:GetFullName()) end
	end
	CollectionService:AddTag(machine, FACTORY_MACHINE_TAG)
	if machineType == "AutomaticLoader" or machineType == "Factory" then StationService:RegisterStation(machine, machineType) end
	local data = {
		Model = machine,
		Type = machineType, Queue = {}, PendingOutputs = {}, EmittedOutputs = {}, BusyUntil = 0, CurrentItem = nil,
		Input = input ~= true and input or nil, Output = output,
		MetalMaterial = 0, PlasticMaterial = 0, MetalBlocksProcessed = 0, PlasticBlocksProcessed = 0,
		NextLoaderOutput = 0,
		BuildState = "Idle", BuildStartedAt = nil, BuildElapsed = 0, PlaneSpawned = false,
		NextPlaneSpawnAttempt = 0,
	}
	self._machines[machine] = data
	if machineType == "Recycler" then
		self.ActiveRecyclers[machine] = data
		self._recyclerViewers[machine] = setmetatable({}, {__mode = "k"})
	elseif machineType == "IndustrialPress" then
		self.ActiveIndustrialPresses[machine] = data
		self._recyclerViewers[machine] = setmetatable({}, {__mode = "k"})
	elseif machineType == "Factory" then
		self._finalViewers[machine] = setmetatable({}, {__mode = "k"})
		local inputs = {}
		for _, descendant in machine:GetDescendants() do
			if descendant.Name == "ItemInput" then table.insert(inputs, descendant) end
		end
		local interactionPoint = findNamedDescendant(machine, "InteractionPoint")
		local promptParent = interactionPoint and (interactionPoint:IsA("Attachment") or interactionPoint:IsA("BasePart")) and interactionPoint or getRootPart(machine)
		if #inputs ~= 2 or not output or not interactionPoint or not promptParent then
			warn("[MAYDEAD][FINAL FACTORY] Expected 2 ItemInput, 1 ItemOutput and InteractionPoint")
			self._machines[machine] = nil
			StationService:UnregisterStation(machine)
			return
		end
		data.InteractionPoint = interactionPoint
		local prompt = promptParent:FindFirstChild("FinalFactoryPrompt") or Instance.new("ProximityPrompt")
		prompt.Name = "FinalFactoryPrompt"; prompt.ActionText = "OUVRIR"; prompt.ObjectText = "FACTORY"
		prompt.KeyboardKeyCode = Enum.KeyCode.E; prompt.MaxActivationDistance = 10; prompt.RequiresLineOfSight = false; prompt.Parent = promptParent
		prompt.Triggered:Connect(function(player)
			if player:GetAttribute("SessionStarted") ~= true then return end
			if RunService:IsStudio() then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local interactionPosition = interactionPoint:IsA("Attachment") and interactionPoint.WorldPosition
					or interactionPoint:IsA("BasePart") and interactionPoint.Position
					or machine:GetPivot().Position
				local distance = root and (root.Position - interactionPosition).Magnitude or -1
				print(string.format(
					"[MAYDEAD][FINAL_FACTORY][INTERACTION] Triggered Player=%s StructureId=%s Distance=%.2f PromptEnabled=%s",
					player.Name,
					tostring(machine:GetAttribute("StructureId")),
					distance,
					tostring(prompt.Enabled)
				))
			end
			local openRemoteFired = StationService:OpenStation(player, machine)
			if RunService:IsStudio() then print("[MAYDEAD][FINAL_FACTORY][INTERACTION] OpenRemoteFired=" .. tostring(openRemoteFired)) end
			if not openRemoteFired then return end
			self._finalViewers[machine][player] = true
			self:_sendFinalState(player, machine, data)
		end)
		log("Factory audit ItemInput=2 ItemOutput=true InteractionPoint=true")
	end
	self:_prepareMachineVisuals(machine, data)
	if machineType == "Recycler" or machineType == "IndustrialPress" then
		local interaction = findNamedDescendant(machine, "InteractionPoint")
		local promptParent = interaction and (interaction:IsA("Attachment") or interaction:IsA("BasePart")) and interaction or getRootPart(machine)
		if promptParent and not promptParent:FindFirstChild("FactoryStatusPrompt") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "FactoryStatusPrompt"
			prompt.ActionText = "ÉTAT"
			prompt.ObjectText = machineType == "Recycler" and "RECYCLEUR" or "PRESSE INDUSTRIELLE"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = promptParent
			prompt.Triggered:Connect(function(player)
				if player:GetAttribute("SessionStarted") ~= true then return end
				self:_openMachineStatus(player, machine, data)
			end)
		end
	end
	log("Registered " .. machineType)
end

function FactoryService:GetPersistentState(machine)
	self:_registerMachine(machine)
	local data = self._machines[machine]
	if data and data.Type == "Factory" then
		local stationState, stationError = StationService:GetPersistentState(machine)
		if not stationState then return nil, stationError end
		local elapsed = data.BuildState == "Building" and math.clamp(data.BuildElapsed + (os.clock() - (data.BuildStartedAt or os.clock())), 0, FactoryConfig.NAVAL_SEAPLANE_BUILD_TIME) or data.BuildElapsed
		return {StateVersion = 1, MachineType = "Factory", StationState = stationState, BuildState = data.BuildState, BuildElapsed = elapsed, PlaneSpawned = data.PlaneSpawned == true}
	end
	if not data or (data.Type ~= "Recycler" and data.Type ~= "IndustrialPress") then
		return nil, "FactoryMachineNotRegistered"
	end
	local emittedOutputs = {}
	for instance, itemId in data.EmittedOutputs do
		if instance:IsDescendantOf(workspace) then table.insert(emittedOutputs, itemId) end
	end
	if #data.Queue > FactoryConfig.PERSISTENT_QUEUE_LIMIT
		or #data.PendingOutputs + #emittedOutputs > FactoryConfig.PERSISTENT_OUTPUT_LIMIT
	then
		return nil, "FactoryStateLimitExceeded"
	end
	local duration = data.Type == "Recycler" and FactoryConfig.RECYCLER_PROCESS_TIME or FactoryConfig.PRESS_PROCESS_TIME
	local remaining = data.CurrentItem and math.clamp(data.BusyUntil - os.clock(), 0, duration) or 0
	local state = {
		StateVersion = 1,
		MachineType = data.Type,
		Queue = cloneArray(data.Queue),
		PendingOutputs = cloneArray(data.PendingOutputs),
		EmittedOutputs = emittedOutputs,
		CurrentItemId = data.CurrentItem,
		RemainingProcessing = remaining,
	}
	if data.Type == "Recycler" then
		state.MetalMaterial = data.MetalMaterial
		state.PlasticMaterial = data.PlasticMaterial
	else
		state.MetalBlocksProcessed = data.MetalBlocksProcessed
		state.PlasticBlocksProcessed = data.PlasticBlocksProcessed
	end
	return state
end

function FactoryService:RestorePersistentState(machine, state)
	self:_registerMachine(machine)
	local data = self._machines[machine]
	if data and data.Type == "Factory" then
		if typeof(state) ~= "table" or state.StateVersion ~= 1 or state.MachineType ~= "Factory" then return false, "InvalidFinalFactoryState" end
		if state.StationState ~= nil then
			local restored, stationError = StationService:RestorePersistentState(machine, state.StationState)
			if not restored then return false, stationError end
		end
		if state.BuildState ~= "Idle" and state.BuildState ~= "Building" and state.BuildState ~= "Completed" then return false, "InvalidFinalFactoryState" end
		if typeof(state.BuildElapsed) ~= "number" or state.BuildElapsed < 0 or state.BuildElapsed > FactoryConfig.NAVAL_SEAPLANE_BUILD_TIME then return false, "InvalidFinalFactoryState" end
		data.BuildState, data.BuildElapsed, data.PlaneSpawned = state.BuildState, state.BuildElapsed, state.PlaneSpawned == true
		data.BuildStartedAt = data.BuildState == "Building" and os.clock() or nil
		if data.BuildState == "Completed" then self:_ensureFinalPlane(data) end
		return true
	end
	if not data or (data.Type ~= "Recycler" and data.Type ~= "IndustrialPress") then
		return false, "FactoryMachineNotRegistered"
	end
	data.Queue = {}
	data.PendingOutputs = {}
	data.EmittedOutputs = {}
	data.CurrentItem = nil
	data.ProcessStartedAt = nil
	data.BusyUntil = 0
	data.MetalMaterial = 0
	data.PlasticMaterial = 0
	data.MetalBlocksProcessed = 0
	data.PlasticBlocksProcessed = 0

	if typeof(state) ~= "table" or state.StateVersion ~= 1 or state.MachineType ~= data.Type then
		self:_setProcessing(data, false)
		warn(string.format(
			"[MAYDEAD][PERSISTENCE][RECOVERY] StructureId=%s Type=%s Action=FactoryRuntimeReset StructurePreserved=true",
			tostring(machine:GetAttribute("StructureId")), data.Type
		))
		return true, nil, {Recovered = true, Reason = "InvalidFactoryState", Action = "FactoryRuntimeReset"}
	end
	local queueItems = data.Type == "Recycler" and WASTE_TYPES or BLOCK_TYPES
	local outputItems = data.Type == "Recycler"
		and {MetalBlock = true, PlasticBlock = true}
		or {MetalPanelStack = true, PlasticPanelStack = true}
	local queue = validateItemArray(state.Queue, queueItems, FactoryConfig.PERSISTENT_QUEUE_LIMIT)
	local pendingOutputs = validateItemArray(state.PendingOutputs, outputItems, FactoryConfig.PERSISTENT_OUTPUT_LIMIT)
	local emittedOutputs = state.EmittedOutputs == nil and {}
		or validateItemArray(state.EmittedOutputs, outputItems, FactoryConfig.PERSISTENT_OUTPUT_LIMIT)
	local currentItem = state.CurrentItemId
	local recovered = queue == nil or pendingOutputs == nil or emittedOutputs == nil
	if pendingOutputs and emittedOutputs
		and #pendingOutputs + #emittedOutputs > FactoryConfig.PERSISTENT_OUTPUT_LIMIT
	then
		pendingOutputs = nil
		emittedOutputs = nil
		recovered = true
	end
	if currentItem ~= nil and (typeof(currentItem) ~= "string" or not queueItems[currentItem]) then
		currentItem = nil
		recovered = true
	end
	local duration = data.Type == "Recycler" and FactoryConfig.RECYCLER_PROCESS_TIME or FactoryConfig.PRESS_PROCESS_TIME
	local remaining = state.RemainingProcessing
	if typeof(remaining) ~= "number" or remaining ~= remaining or remaining < 0 or remaining > duration then
		remaining = currentItem and duration or 0
		recovered = true
	end
	if not currentItem then remaining = 0 end

	data.Queue = queue or {}
	data.PendingOutputs = pendingOutputs or {}
	for _, itemId in emittedOutputs or {} do table.insert(data.PendingOutputs, itemId) end
	data.CurrentItem = currentItem
	if currentItem then
		data.BusyUntil = os.clock() + remaining
		data.ProcessStartedAt = os.clock() - (duration - remaining)
	end
	if data.Type == "Recycler" then
		local metal = validateCounter(state.MetalMaterial, FactoryConfig.RECYCLER_MATERIAL_RATIO)
		local plastic = validateCounter(state.PlasticMaterial, FactoryConfig.RECYCLER_MATERIAL_RATIO)
		if metal == nil or plastic == nil then recovered = true end
		data.MetalMaterial = metal or 0
		data.PlasticMaterial = plastic or 0
	else
		local metal = validateCounter(state.MetalBlocksProcessed, FactoryConfig.PRESS_BLOCK_RATIO)
		local plastic = validateCounter(state.PlasticBlocksProcessed, FactoryConfig.PRESS_BLOCK_RATIO)
		if metal == nil or plastic == nil then recovered = true end
		data.MetalBlocksProcessed = metal or 0
		data.PlasticBlocksProcessed = plastic or 0
	end
	self:_setProcessing(data, currentItem ~= nil)
	if recovered then
		warn(string.format(
			"[MAYDEAD][PERSISTENCE][RECOVERY] StructureId=%s Type=%s Action=InvalidFactoryFieldsReset StructurePreserved=true",
			tostring(machine:GetAttribute("StructureId")), data.Type
		))
	end
	return true, nil, recovered and {Recovered = true, Reason = "PartialFactoryState", Action = "InvalidFieldsReset"} or nil
end

function FactoryService:CanDismantle(machine)
	local data = self._machines[machine]
	if not data then return true end
	if data.Type == "Factory" then return data.BuildState == "Idle" and StationService:CanDismantle(machine) end
	return #data.Queue == 0 and #data.PendingOutputs == 0 and not next(data.EmittedOutputs) and data.CurrentItem == nil
		and data.MetalMaterial == 0 and data.PlasticMaterial == 0
		and data.MetalBlocksProcessed == 0 and data.PlasticBlocksProcessed == 0
end

function FactoryService:ClearWorldMachineRuntime()
	for machine, data in self._machines do
		if typeof(machine:GetAttribute("StructureId")) ~= "string" then continue end
		for instance in data.EmittedOutputs do
			self:_unregisterFactoryItem(instance)
			if instance.Parent then instance:Destroy() end
		end
		self._machines[machine] = nil
		self.ActiveRecyclers[machine] = nil
		self.ActiveIndustrialPresses[machine] = nil
		self._recyclerViewers[machine] = nil
	end
end

function FactoryService:_trackMachineOutput(data, instance, itemId)
	data.EmittedOutputs[instance] = itemId
	instance.AncestryChanged:Connect(function()
		if not instance:IsDescendantOf(workspace) then data.EmittedOutputs[instance] = nil end
	end)
end

function FactoryService:_queueOutput(data, itemId)
	table.insert(data.PendingOutputs, itemId)
end

function FactoryService:_finishRecycler(data, itemId)
	local material = itemId == "WasteBag" and (math.random() < 0.5 and "Metal" or "Plastic")
		or (itemId == "MetalWaste" and "Metal" or "Plastic")
	local key = material .. "Material"
	data[key] = data[key] + 1
	log("Recycler " .. key .. " = " .. data[key] .. "/" .. FactoryConfig.RECYCLER_MATERIAL_RATIO)
	if data[key] >= FactoryConfig.RECYCLER_MATERIAL_RATIO then
		data[key] = data[key] - FactoryConfig.RECYCLER_MATERIAL_RATIO
		self:_queueOutput(data, material .. "Block")
	end
end

function FactoryService:_finishPress(data, itemId)
	local material = itemId == "MetalBlock" and "Metal" or "Plastic"
	local key = material .. "BlocksProcessed"
	data[key] = data[key] + 1
	if data[key] >= FactoryConfig.PRESS_BLOCK_RATIO then
		data[key] = data[key] - FactoryConfig.PRESS_BLOCK_RATIO
		self:_queueOutput(data, material .. "PanelStack")
	end
end

function FactoryService:_captureIntoMachine(instance, itemData, machineData)
	if not instance:IsDescendantOf(workspace) or itemData.Processing then return false end
	itemData.Processing = true
	instance:SetAttribute("FactoryProcessing", true)
	instance:SetAttribute("FactoryClaimed", true)
	local itemId = itemData.ItemId
	self:_unregisterFactoryItem(instance)
	CollectionService:RemoveTag(instance, FACTORY_ITEM_TAG)
	log(machineData.Type .. " captured " .. itemId)
	instance:Destroy()
	table.insert(machineData.Queue, itemId)
	log(machineData.Type .. " received " .. itemId)
	return true
end

function FactoryService:_tryCaptureFactoryItem(instance, itemData, now)
	local registry
	local captureRadius
	if WASTE_TYPES[itemData.ItemId] then
		registry = self.ActiveRecyclers
		captureRadius = FactoryConfig.RECYCLER_CAPTURE_RADIUS
	elseif BLOCK_TYPES[itemData.ItemId] then
		registry = self.ActiveIndustrialPresses
		captureRadius = FactoryConfig.INDUSTRIAL_PRESS_CAPTURE_RADIUS
	else
		return false
	end
	local itemPosition = getItemWorldPosition(instance)
	if not itemPosition then return false end
	local closestData, closestDistance
	for machine, machineData in registry do
		local input = machineData.Input
		if machine:IsDescendantOf(workspace) and input and input:IsDescendantOf(workspace) then
			local distance = (itemPosition - input.Position).Magnitude
			if not closestDistance or distance < closestDistance then
				closestData, closestDistance = machineData, distance
			end
		end
	end
	if not closestData then return false end
	if instance == self._debugIntakeItem
		and closestDistance <= captureRadius * 2
		and now - itemData.LastIntakeDebug >= FactoryConfig.INTAKE_DEBUG_INTERVAL
	then
		itemData.LastIntakeDebug = now
		log(itemData.ItemId .. " -> " .. closestData.Type .. " distance = " .. string.format("%.2f", closestDistance))
		log("calling intake check = " .. itemData.ItemId)
	end
	if closestDistance <= captureRadius then
		return self:_captureIntoMachine(instance, itemData, closestData)
	end
	return false
end

function FactoryService:_buildFinalState(data)
	local elapsed = data.BuildState == "Building"
		and math.clamp(data.BuildElapsed + (os.clock() - (data.BuildStartedAt or os.clock())), 0, FactoryConfig.NAVAL_SEAPLANE_BUILD_TIME)
		or data.BuildElapsed
	return {
		StructureId = data.Model:GetAttribute("StructureId"),
		BuildState = data.BuildState,
		Progress = data.BuildState == "Completed" and 1 or elapsed / FactoryConfig.NAVAL_SEAPLANE_BUILD_TIME,
		Remaining = math.max(0, FactoryConfig.NAVAL_SEAPLANE_BUILD_TIME - elapsed),
		MetalPanelStack = StationService:GetStoredItemQuantity(data.Model, "MetalPanelStack"),
		PlasticPanelStack = StationService:GetStoredItemQuantity(data.Model, "PlasticPanelStack"),
		RequiredMetalPanelStack = FactoryConfig.NAVAL_SEAPLANE_RECIPE.MetalPanelStack,
		RequiredPlasticPanelStack = FactoryConfig.NAVAL_SEAPLANE_RECIPE.PlasticPanelStack,
		Completed = data.BuildState == "Completed",
	}
end

function FactoryService:_sendFinalState(player, machine, data)
	self._finalState:FireClient(player, machine, self:_buildFinalState(data))
end

function FactoryService:_ensureFinalPlane(data)
	if self._worldService and self._worldService:IsFinalPlaneSpawned() then data.PlaneSpawned = true; return true end
	local imports = ServerStorage:FindFirstChild("AssetImports")
	local template = imports and imports:FindFirstChild("Naval Seaplane")
	if not template or not template:IsA("Model") then warn("[MAYDEAD][FINAL FACTORY] Naval Seaplane template missing"); return false end
	local existing = workspace:FindFirstChild("FinalNavalSeaplane")
	if existing then data.PlaneSpawned = true; return true end
	local clone = template:Clone()
	clone.Name = "FinalNavalSeaplane"
	clone:SetAttribute("FinalWorldVehicle", true)
	local outputCFrame = getWorldCFrame(data.Output)
	if not outputCFrame then clone:Destroy(); return false end
	local positionOffset = FactoryConfig.NAVAL_OUTPUT_POSITION_OFFSET
	local rotationDegrees = FactoryConfig.NAVAL_OUTPUT_ROTATION_OFFSET_DEGREES
	local rotationOffset = CFrame.Angles(
		math.rad(rotationDegrees.X),
		math.rad(rotationDegrees.Y),
		math.rad(rotationDegrees.Z)
	)
	local desiredCenter = (outputCFrame * CFrame.new(positionOffset)).Position
	local orientedPivot = CFrame.new(desiredCenter) * outputCFrame.Rotation * rotationOffset
	clone:PivotTo(orientedPivot)

	-- Measure only after applying the final local orientation. The bounding box is used
	-- for horizontal centering; collidable BasePart extents determine physical grounding.
	local boundingBoxCFrame, size = clone:GetBoundingBox()
	local bottomYBefore, contactMode, collidableParts, visibleParts, unanchoredCollidableParts, visibleBottomYBefore = getLowestContactY(clone)
	local surfaceResult = findFactorySurfaceBelow(data.Model, data.Output, outputCFrame)
	if not bottomYBefore or not surfaceResult or not surfaceResult.Instance:IsDescendantOf(data.Model) then
		warn("[MAYDEAD][FINAL FACTORY] Unable to resolve Naval physical bottom or Factory conveyor surface")
		clone:Destroy()
		return false
	end
	local targetSurfaceY = surfaceResult.Position.Y
	local verticalDelta = targetSurfaceY - bottomYBefore + FactoryConfig.NAVAL_OUTPUT_CLEARANCE
	local horizontalDelta = Vector3.new(
		desiredCenter.X - boundingBoxCFrame.Position.X,
		0,
		desiredCenter.Z - boundingBoxCFrame.Position.Z
	)
	local targetPivot = orientedPivot + horizontalDelta + Vector3.new(0, verticalDelta, 0)
	clone:PivotTo(targetPivot)
	local finalBottomY, finalContactMode, _, _, _, finalVisibleBottomY = getLowestContactY(clone)
	if not finalBottomY then clone:Destroy(); return false end
	if RunService:IsStudio() then
		print(string.format(
			"[MAYDEAD][FINAL_FACTORY][NAVAL_GROUND] ItemOutput=%s HitPart=%s HitPosition=%s SurfaceY=%.4f HitCanCollide=%s HitConveyor=true",
			data.Output:GetFullName(), surfaceResult.Instance:GetFullName(), tostring(surfaceResult.Position), targetSurfaceY,
			tostring(surfaceResult.Instance.CanCollide)
		))
		print(string.format(
			"[MAYDEAD][FINAL_FACTORY][NAVAL_OUTPUT] StructureId=%s ItemOutput=%s RotationOffsetY=%.2f BoundingSize=%s ContactMode=%s CollidableParts=%d UnanchoredCollidableParts=%d VisibleParts=%d LowestContactYBefore=%.4f VisibleBottomYBefore=%.4f SurfaceY=%.4f VerticalDelta=%.4f LocalOffset=%s FinalContactMode=%s FinalBottomY=%.4f FinalVisibleBottomY=%.4f Difference=%.4f FinalPivot=%s",
			tostring(data.Model:GetAttribute("StructureId")), data.Output:GetFullName(), rotationDegrees.Y,
			tostring(size), contactMode, collidableParts, unanchoredCollidableParts, visibleParts,
			bottomYBefore, visibleBottomYBefore, targetSurfaceY, verticalDelta, tostring(positionOffset), finalContactMode,
			finalBottomY, finalVisibleBottomY, finalBottomY - targetSurfaceY, tostring(targetPivot)
		))
	end
	local anchoredStates = {}
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			anchoredStates[descendant] = descendant.Anchored
			descendant.Anchored = true
		end
	end
	clone.Parent = workspace
	if RunService:IsStudio() then
		task.delay(1, function()
			if clone:IsDescendantOf(workspace) then
				local currentBottomY, currentContactMode = getLowestContactY(clone)
				print(string.format(
					"[MAYDEAD][FINAL_FACTORY][NAVAL_OUTPUT] Action=PostPhysicsCheck FinalPivot=%s CurrentPivot=%s SurfaceY=%.4f ContactMode=%s CurrentBottomY=%s Difference=%s",
					tostring(targetPivot), tostring(clone:GetPivot()), targetSurfaceY,
					tostring(currentContactMode), currentBottomY and string.format("%.4f", currentBottomY) or "nil",
					currentBottomY and string.format("%.4f", currentBottomY - targetSurfaceY) or "nil"
				))
			end
		end)
	end
	task.delay(0.25, function()
		for part, wasAnchored in anchoredStates do
			if part:IsDescendantOf(clone) then part.Anchored = wasAnchored end
		end
	end)
	data.PlaneSpawned = true
	if self._worldService then self._worldService:MarkFinalPlaneSpawned(clone:GetPivot()) end
	return true
end

function FactoryService:RestoreFinalWorldState(worldState)
	if typeof(worldState) ~= "table" or worldState.FinalPlaneSpawned ~= true or workspace:FindFirstChild("FinalNavalSeaplane") then return end
	local components = worldState.FinalPlanePivot
	if typeof(components) ~= "table" or #components ~= 12 then return end
	for _, value in components do if typeof(value) ~= "number" or value ~= value then return end end
	local imports = ServerStorage:FindFirstChild("AssetImports")
	local template = imports and imports:FindFirstChild("Naval Seaplane")
	if not template or not template:IsA("Model") then return end
	local clone = template:Clone()
	clone.Name = "FinalNavalSeaplane"; clone:SetAttribute("FinalWorldVehicle", true)
	clone:PivotTo(CFrame.new(table.unpack(components)))
	clone.Parent = workspace
end

function FactoryService:_startFinalBuild(player, machine, data)
	local structureId = machine:GetAttribute("StructureId")
	local metal = StationService:GetStoredItemQuantity(machine, "MetalPanelStack")
	local plastic = StationService:GetStoredItemQuantity(machine, "PlasticPanelStack")
	if RunService:IsStudio() then
		print(string.format(
			"[MAYDEAD][FINAL_FACTORY][ASSEMBLE] Action=RequestReceived Player=%s StructureId=%s Metal=%d Plastic=%d State=%s",
			player.Name, tostring(structureId), metal, plastic, tostring(data.BuildState)
		))
	end
	local function reject(reason)
		if RunService:IsStudio() then
			print(string.format("[MAYDEAD][FINAL_FACTORY][ASSEMBLE] Action=Rejected Reason=%s StructureId=%s", reason, tostring(structureId)))
		end
		return false, reason
	end
	if self._worldService and not self._worldService:IsRuntimeMember(player) then return reject("NotWorldMember") end
	if data.BuildState ~= "Idle" then return reject("ProductionNotIdle") end
	if self._worldService and self._worldService:IsNavalSeaplaneCompleted() then return reject("AlreadyCompleted") end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local interactionCFrame = data.InteractionPoint and getWorldCFrame(data.InteractionPoint)
	local interactionPosition = interactionCFrame and interactionCFrame.Position or machine:GetPivot().Position
	if not root or (root.Position - interactionPosition).Magnitude > 12 then return reject("TooFar") end
	if metal < FactoryConfig.NAVAL_SEAPLANE_RECIPE.MetalPanelStack
		or plastic < FactoryConfig.NAVAL_SEAPLANE_RECIPE.PlasticPanelStack
	then return reject("MissingResources") end
	-- Roblox event handlers do not interleave before a yield, but this explicit transient
	-- state also makes the single-winner rule clear if this function later gains one.
	data.BuildState = "Starting"
	if not StationService:ConsumeStoredItems(machine, FactoryConfig.NAVAL_SEAPLANE_RECIPE) then
		data.BuildState = "Idle"
		return reject("ConsumptionFailed")
	end
	data.BuildState, data.BuildElapsed, data.BuildStartedAt = "Building", 0, os.clock()
	if RunService:IsStudio() then
		print(string.format("[MAYDEAD][FINAL_FACTORY][ASSEMBLE] Action=ProductionStarted StructureId=%s", tostring(structureId)))
	end
	for candidate in self._finalViewers[machine] or {} do self:_sendFinalState(candidate, machine, data) end
	return true
end

function FactoryService:_updateFactoryItems(now)
	for instance, itemData in self.ActiveFactoryItems do
		if not instance:IsDescendantOf(workspace) then
			self:_unregisterFactoryItem(instance)
		elseif not itemData.Processing then
			self:_tryCaptureFactoryItem(instance, itemData, now)
		end
	end
end

function FactoryService:_updateMachine(machine, data, now)
	if data.Type == "Factory" then
		if data.BuildState == "Building" then
			local elapsed = data.BuildElapsed + (now - (data.BuildStartedAt or now))
			if elapsed >= FactoryConfig.NAVAL_SEAPLANE_BUILD_TIME then
				data.BuildElapsed, data.BuildStartedAt, data.BuildState = FactoryConfig.NAVAL_SEAPLANE_BUILD_TIME, nil, "Completed"
				if self:_ensureFinalPlane(data) then
					if self._worldService then self._worldService:CompleteNavalSeaplane() end
				else
					data.NextPlaneSpawnAttempt = now + 30
				end
			end
		elseif data.BuildState == "Completed" and not data.PlaneSpawned and now >= (data.NextPlaneSpawnAttempt or 0) then
			-- Completion is persistent. Retry a failed materialization without consuming again.
			data.NextPlaneSpawnAttempt = now + 30
			if self:_ensureFinalPlane(data) and self._worldService then self._worldService:CompleteNavalSeaplane() end
		end
		return
	end
	if not machine:IsDescendantOf(workspace) then
		self._machines[machine] = nil
		self.ActiveRecyclers[machine] = nil
		self.ActiveIndustrialPresses[machine] = nil
		return
	end
	local output = data.Output
	if #data.PendingOutputs > 0 and self:_outputClear(machine, output) then
		local itemId = table.remove(data.PendingOutputs, 1)
		local spawned = self:_spawnItem(itemId, output, PICKUP_TYPES[itemId])
		if spawned then
			self:_trackMachineOutput(data, spawned, itemId)
			log(data.Type .. " produced " .. itemId)
		end
	end
	if data.Type == "AutomaticLoader" then
		if now >= data.NextLoaderOutput and self:_outputClear(machine, output) then
			local itemId = StationService:TakeAutomaticLoaderItem(machine)
			if itemId then
				self:_spawnItem(itemId, output, PICKUP_TYPES[itemId] == true)
				data.NextLoaderOutput = now + FactoryConfig.LOADER_OUTPUT_INTERVAL
			end
		end
		return
	end
	if data.CurrentItem and now >= data.BusyUntil then
		if data.Type == "Recycler" then self:_finishRecycler(data, data.CurrentItem) else self:_finishPress(data, data.CurrentItem) end
		data.CurrentItem = nil
	end
	if not data.CurrentItem and #data.Queue > 0 then
		data.CurrentItem = table.remove(data.Queue, 1)
		data.ProcessStartedAt = now
		data.BusyUntil = now + (data.Type == "Recycler" and FactoryConfig.RECYCLER_PROCESS_TIME or FactoryConfig.PRESS_PROCESS_TIME)
		log(data.Type .. " processing " .. data.CurrentItem)
	end
	self:_setProcessing(data, data.CurrentItem ~= nil)
end

function FactoryService:_syncRecyclerStatuses(now)
	for machine, viewers in self._recyclerViewers do
		local data = self._machines[machine]
		if not data or not machine:IsDescendantOf(workspace) then
			self._recyclerViewers[machine] = nil
		else
			local state = self:_buildMachineState(data, now)
			for player in viewers do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if player.Parent == Players and root and (root.Position - machine:GetPivot().Position).Magnitude <= 14 then
					self._statusChanged:FireClient(player, machine, state)
				else
					viewers[player] = nil
				end
			end
		end
	end
end

function FactoryService:_registerConveyorPart(part)
	if not part:IsA("BasePart") or self._conveyors[part] then return end
	self._conveyors[part] = true
	CollectionService:AddTag(part, CONVEYOR_TAG)
	local direction = self:_getConveyorDirection(part)
	part.AssemblyLinearVelocity = direction * FactoryConfig.CONVEYOR_SPEED
	log("Conveyor registered = " .. part:GetFullName())
	log("Conveyor direction = " .. tostring(direction))
end

function FactoryService:_registerConveyorCandidate(instance)
	if CollectionService:HasTag(instance, CONVEYOR_TAG) and instance:IsA("BasePart") then
		self:_registerConveyorPart(instance)
		return
	end
	local namedRoot = instance
	while namedRoot and namedRoot ~= workspace and not nameIdentifiesConveyor(namedRoot.Name) do
		namedRoot = namedRoot.Parent
	end
	if namedRoot == workspace or not namedRoot then return end
	if instance:IsA("BasePart") then
		self:_registerConveyorPart(instance)
		return
	end
	if namedRoot:IsA("BasePart") then self:_registerConveyorPart(namedRoot) end
	for _, descendant in namedRoot:GetDescendants() do
		if descendant:IsA("BasePart") then self:_registerConveyorPart(descendant) end
	end
end

function FactoryService:_getConveyorDirection(part)
	local axis = getInheritedAttribute(part, "FactoryDirectionAxis")
	local direction
	if axis == "X" then
		direction = part.CFrame.RightVector
	elseif axis == "-X" then
		direction = -part.CFrame.RightVector
	elseif axis == "Z" then
		direction = -part.CFrame.LookVector
	elseif axis == "-Z" then
		direction = part.CFrame.LookVector
	elseif part.Size.X > part.Size.Z then
		direction = part.CFrame.RightVector
	else
		direction = part.CFrame.LookVector
	end
	if getInheritedAttribute(part, "FactoryDirectionSign") == -1 then direction = -direction end
	local horizontal = Vector3.new(direction.X, 0, direction.Z)
	return horizontal.Magnitude > 0.001 and horizontal.Unit or Vector3.new(0, 0, -1)
end

function FactoryService:_updateConveyorSurfaces()
	for conveyor in self._conveyors do
		if conveyor:IsDescendantOf(workspace) then
			conveyor.AssemblyLinearVelocity = self:_getConveyorDirection(conveyor) * FactoryConfig.CONVEYOR_SPEED
		else
			self._conveyors[conveyor] = nil
		end
	end
end

function FactoryService:_spawnAtPoint(spawnPoint, itemId)
	if self._spawnBusy[spawnPoint] or not spawnPoint:IsA("BasePart") then return end
	self._spawnBusy[spawnPoint] = true
	local item = self:_spawnItem(itemId, spawnPoint, true)
	if not item then self._spawnBusy[spawnPoint] = nil; return end
	task.spawn(function()
		item.AncestryChanged:Wait()
		while item.Parent do item.AncestryChanged:Wait() end
		task.wait(FactoryConfig.SPAWN_RESPAWN_TIME)
		self._spawnBusy[spawnPoint] = nil
		if spawnPoint:IsDescendantOf(workspace) then self:_spawnAtPoint(spawnPoint, itemId) end
	end)
end

function FactoryService:_startResourceSpawns()
	local folder = workspace:FindFirstChild("FactoryResourceSpawns")
	if not folder then warn("[MAYDEAD][FACTORY] Workspace.FactoryResourceSpawns missing"); return end
	local function register(instance)
		if not instance:IsA("BasePart") then return end
		local typeFolder = instance.Parent
		if typeFolder and WASTE_TYPES[typeFolder.Name] then self:_spawnAtPoint(instance, typeFolder.Name) end
	end
	for _, descendant in folder:GetDescendants() do register(descendant) end
	folder.DescendantAdded:Connect(register)
end

function FactoryService:Start(worldService)
	self._worldService = worldService
	StationService.StorageChanged.Event:Connect(function(machine, stationType)
		if stationType ~= "Factory" then return end
		local data = self._machines[machine]
		if not data or data.Type ~= "Factory" then return end
		for player in self._finalViewers[machine] or {} do self:_sendFinalState(player, machine, data) end
	end)
	self._finalRequest.OnServerEvent:Connect(function(player, action, machine)
		if player:GetAttribute("SessionStarted") ~= true or (worldService and not worldService:IsRuntimeMember(player)) then return end
		local data = self._machines[machine]
		if not data or data.Type ~= "Factory" or not machine:IsDescendantOf(workspace)
			or typeof(machine:GetAttribute("StructureId")) ~= "string"
		then return end
		if action == "Assemble" then self:_startFinalBuild(player, machine, data)
		elseif action == "Close" and self._finalViewers[machine] then self._finalViewers[machine][player] = nil end
	end)
	self:_startResourceSpawns()
	for _, child in workspace:GetDescendants() do
		if child:IsA("Model") then self:_registerMachine(child) end
		self:_registerConveyorCandidate(child)
	end
	workspace.DescendantAdded:Connect(function(child)
		if child:IsA("Model") then task.defer(function() self:_registerMachine(child) end) end
		task.defer(function() self:_registerConveyorCandidate(child) end)
	end)
	RunService.Heartbeat:Connect(function(deltaTime)
		self._accumulator = self._accumulator + deltaTime
		if self._accumulator < FactoryConfig.CONVEYOR_SCAN_INTERVAL then return end
		self._accumulator = 0
		local now = os.clock()
		for machine, data in self._machines do self:_updateMachine(machine, data, now) end
		self:_updateConveyorSurfaces()
		self:_updateFactoryItems(now)
		self._statusAccumulator = self._statusAccumulator + FactoryConfig.CONVEYOR_SCAN_INTERVAL
		if self._statusAccumulator >= FactoryConfig.STATUS_UPDATE_INTERVAL then
			self._statusAccumulator = 0
			self:_syncRecyclerStatuses(now)
			for machine, data in self._machines do
				if data.Type == "Factory" then
					for player in self._finalViewers[machine] or {} do
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						local interactionCFrame = data.InteractionPoint and getWorldCFrame(data.InteractionPoint)
						local interactionPosition = interactionCFrame and interactionCFrame.Position or machine:GetPivot().Position
						if root and (root.Position - interactionPosition).Magnitude <= 14 then self:_sendFinalState(player, machine, data) else self._finalViewers[machine][player] = nil end
					end
				end
			end
		end
	end)
	log("Factory V1 started")
end

return FactoryService.new()
