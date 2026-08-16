local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local StationConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("StationConfig"))
local MetallurgyConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("MetallurgyConfig"))
local ItemDefinitions = require(SharedFolder:WaitForChild("Definitions"):WaitForChild("ItemDefinitions"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local SmeltConfig = MetallurgyConfig.Smelt
local CAMPFIRE_STATE_VERSION = 2
local STATION_REQUEST_RATE_PER_SECOND = 20
local STATION_REQUEST_BURST_CAPACITY = 30
local STATION_REQUEST_ACTIONS = {
	TransferToStation = true,
	TransferToPlayer = true,
}

local StationService = {}
StationService.__index = StationService

local function createSlots(count)
	local slots = {}
	for index = 1, count do
		slots[index] = {ItemId = nil, Quantity = 0}
	end
	return slots
end

local function cloneSlots(slots)
	local clone = {}
	for index, slot in ipairs(slots) do
		clone[index] = {ItemId = slot.ItemId, Quantity = slot.Quantity}
	end
	return clone
end

local function isPositiveInteger(value)
	return typeof(value) == "number"
		and value > -math.huge and value < math.huge
		and value == math.floor(value) and value >= 1
end

local function isValidTransferRequest(action, request)
	if typeof(request) ~= "table"
		or typeof(request.Area) ~= "string"
		or (request.Mode ~= "SINGLE" and request.Mode ~= "FULL_STACK" and request.Mode ~= "HALF_STACK")
	then
		return false
	end
	if action == "TransferToStation" then
		return isPositiveInteger(request.PlayerSlotIndex)
			and (request.StationSlotIndex == nil or isPositiveInteger(request.StationSlotIndex))
	end
	return isPositiveInteger(request.StationSlotIndex)
		and (request.PlayerSlotIndex == nil or isPositiveInteger(request.PlayerSlotIndex))
end

local function validateSlots(savedSlots, expectedCount)
	if typeof(savedSlots) ~= "table" or #savedSlots ~= expectedCount then
		return nil
	end
	local validated = {}
	local keyCount = 0
	for key in savedSlots do
		if typeof(key) ~= "number" or key ~= math.floor(key) or key < 1 or key > expectedCount then
			return nil
		end
		keyCount = keyCount + 1
	end
	if keyCount ~= expectedCount then
		return nil
	end
	for index = 1, expectedCount do
		local slot = savedSlots[index]
		if typeof(slot) ~= "table" then
			return nil
		end
		local itemId = slot.ItemId
		local quantity = slot.Quantity
		if itemId == nil then
			if quantity ~= 0 then return nil end
			validated[index] = {ItemId = nil, Quantity = 0}
		else
			local definition = typeof(itemId) == "string" and ItemDefinitions[itemId] or nil
			if not definition or typeof(quantity) ~= "number" or quantity ~= math.floor(quantity)
				or quantity < 1 or quantity > definition.MaxStack
			then
				return nil
			end
			validated[index] = {ItemId = itemId, Quantity = quantity}
		end
	end
	return validated
end

local function validateFactorySlots(savedSlots)
	if typeof(savedSlots) ~= "table" then return nil end
	local slotCount = #savedSlots
	if slotCount ~= StationConfig.FINAL_FACTORY_SLOTS and slotCount ~= 70 then return nil end
	local validated = validateSlots(savedSlots, slotCount)
	if not validated then return nil end
	local totals = {MetalPanelStack = 0, PlasticPanelStack = 0}
	for _, slot in validated do
		if slot.ItemId ~= nil then
			if totals[slot.ItemId] == nil then return nil end
			totals[slot.ItemId] += slot.Quantity
		end
	end
	if totals.MetalPanelStack > ItemDefinitions.MetalPanelStack.MaxStack
		or totals.PlasticPanelStack > ItemDefinitions.PlasticPanelStack.MaxStack
	then return nil end
	return {
		{ItemId = totals.MetalPanelStack > 0 and "MetalPanelStack" or nil, Quantity = totals.MetalPanelStack},
		{ItemId = totals.PlasticPanelStack > 0 and "PlasticPanelStack" or nil, Quantity = totals.PlasticPanelStack},
	}
end

local function getStationSlotCount(stationType)
	if stationType == "Factory" then return StationConfig.FINAL_FACTORY_SLOTS end
	if stationType == "Chest" then return StationConfig.CHEST_SLOTS end
	if stationType == "AutomaticLoader" then return StationConfig.AUTOMATIC_LOADER_SLOTS end
	if stationType == "CraftingTable" then return StationConfig.CRAFTING_TABLE_SLOTS end
	return nil
end

local function getCampfireCookingItemKind(itemId)
	if StationConfig.CAMPFIRE_RECIPES[itemId] ~= nil then
		return "Input"
	end
	for _, outputItemId in StationConfig.CAMPFIRE_RECIPES do
		if outputItemId == itemId then
			return "Output"
		end
	end
	return nil
end

local function getItemQuantity(slots, itemId)
	local total = 0
	for _, slot in ipairs(slots) do
		if slot.ItemId == itemId then
			total = total + slot.Quantity
		end
	end
	return total
end

local function getAddCapacity(slots, itemId)
	local definition = ItemDefinitions[itemId]
	if not definition then
		return 0
	end
	local capacity = 0
	for _, slot in ipairs(slots) do
		if slot.ItemId == nil then
			capacity = capacity + definition.MaxStack
		elseif slot.ItemId == itemId then
			capacity = capacity + math.max(0, definition.MaxStack - slot.Quantity)
		end
	end
	return capacity
end

local function canAddToSlots(slots, itemId, quantity)
	return getAddCapacity(slots, itemId) >= quantity
end

local function isCompatibleTarget(slots, targetIndex, itemId)
	if targetIndex == nil then
		return true
	end
	if typeof(targetIndex) ~= "number" or targetIndex ~= math.floor(targetIndex) then
		return false
	end
	local target = slots[targetIndex]
	local definition = ItemDefinitions[itemId]
	return target ~= nil and definition ~= nil
		and (target.ItemId == nil or (target.ItemId == itemId and target.Quantity < definition.MaxStack))
end

local function addToSlots(slots, itemId, quantity)
	local definition = ItemDefinitions[itemId]
	local remaining = quantity
	for _, slot in ipairs(slots) do
		if slot.ItemId == itemId and slot.Quantity < definition.MaxStack then
			local added = math.min(remaining, definition.MaxStack - slot.Quantity)
			slot.Quantity = slot.Quantity + added
			remaining = remaining - added
			if remaining <= 0 then
				return true
			end
		end
	end
	for _, slot in ipairs(slots) do
		if slot.ItemId == nil then
			local added = math.min(remaining, definition.MaxStack)
			slot.ItemId = itemId
			slot.Quantity = added
			remaining = remaining - added
			if remaining <= 0 then
				return true
			end
		end
	end
	return false
end

local function removeFromSlots(slots, itemId, quantity)
	local remaining = quantity
	for _, slot in ipairs(slots) do
		if slot.ItemId == itemId then
			local removed = math.min(remaining, slot.Quantity)
			slot.Quantity = slot.Quantity - removed
			remaining = remaining - removed
			if slot.Quantity <= 0 then
				slot.ItemId = nil
				slot.Quantity = 0
			end
			if remaining <= 0 then
				return true
			end
		end
	end
	return false
end

function StationService.new()
	local self = setmetatable({}, StationService)
	self._stations = setmetatable({}, {__mode = "k"})
	self._viewers = setmetatable({}, {__mode = "k"})
	self._requestBudgets = {}
	self._open = Instance.new("RemoteEvent")
	self._open.Name = "StationOpened"
	self._open.Parent = ReplicatedStorage
	self._stateChanged = Instance.new("RemoteEvent")
	self._stateChanged.Name = "StationStateChanged"
	self._stateChanged.Parent = ReplicatedStorage
	self._request = Instance.new("RemoteEvent")
	self._request.Name = "StationRequest"
	self._request.Parent = ReplicatedStorage
	self.StorageChanged = Instance.new("BindableEvent")
	return self
end

function StationService:_consumeRequestBudget(player)
	local now = os.clock()
	local budget = self._requestBudgets[player]
	if not budget then
		budget = {Tokens = STATION_REQUEST_BURST_CAPACITY, UpdatedAt = now}
		self._requestBudgets[player] = budget
	else
		local elapsed = math.max(0, now - budget.UpdatedAt)
		budget.Tokens = math.min(
			STATION_REQUEST_BURST_CAPACITY,
			budget.Tokens + elapsed * STATION_REQUEST_RATE_PER_SECOND
		)
		budget.UpdatedAt = now
	end
	if budget.Tokens < 1 then return false end
	budget.Tokens -= 1
	return true
end

local function getStationInteractionPosition(station)
	local interactionPoint = station:FindFirstChild("InteractionPoint", true)
	if interactionPoint then
		if interactionPoint:IsA("Attachment") then return interactionPoint.WorldPosition end
		if interactionPoint:IsA("BasePart") then return interactionPoint.Position end
	end
	return station:GetPivot().Position
end

function StationService:_isPlayerNear(player, station)
	if typeof(station) ~= "Instance" or not station:IsDescendantOf(workspace) then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	return humanoid ~= nil
		and humanoid.Health > 0
		and rootPart ~= nil
		and (rootPart.Position - getStationInteractionPosition(station)).Magnitude <= StationConfig.INTERACTION_DISTANCE
end

function StationService:_buildClientState(data)
	local state = {
		StationId = data.Id,
		StructureId = data.Model and data.Model:GetAttribute("StructureId") or nil,
		StationType = data.Type,
		IsLit = data.IsLit == true,
		BurnRemaining = data.BurnRemaining or 0,
		CookProgress = data.CookProgress or 0,
		CookDuration = StationConfig.CAMPFIRE_COOK_TIME,
	}
	if data.Type == "Smelt" then
		local recipe = data.ActiveRecipe and SmeltConfig.Recipes[data.ActiveRecipe]
		state.InputSlots = cloneSlots(data.InputSlots)
		state.FuelSlots = cloneSlots(data.FuelSlots)
		state.OutputSlots = cloneSlots(data.OutputSlots)
		state.ActiveRecipe = data.ActiveRecipe
		state.ProgressElapsed = data.ProgressElapsed or 0
		state.ProgressDuration = recipe and recipe.Duration or 0
		state.Status = data.Status or "ÉTEINT"
		return state
	end
	if data.Type == "CraftingTable" or data.Type == "Chest" or data.Type == "AutomaticLoader" or data.Type == "Factory" then
		state.Slots = cloneSlots(data.Slots)
	else
		state.FuelSlots = cloneSlots(data.FuelSlots)
		state.CookingSlots = cloneSlots(data.CookingSlots)
	end
	return state
end

function StationService:_syncStation(station)
	local data = self._stations[station]
	local viewers = self._viewers[station]
	if not data or not viewers then
		return
	end
	local state = self:_buildClientState(data)
	for player in viewers do
		if player.Parent == Players and self:_isPlayerNear(player, station) then
			self._stateChanged:FireClient(player, station, state)
		else
			viewers[player] = nil
		end
	end
end

function StationService:_setEffects(station, enabled)
	for _, descendant in station:GetDescendants() do
		if descendant:IsA("Fire")
			or descendant:IsA("ParticleEmitter")
			or descendant:IsA("Smoke")
			or descendant:IsA("PointLight")
			or descendant:IsA("SpotLight")
			or descendant:IsA("SurfaceLight")
		then
			descendant.Enabled = enabled
		elseif descendant:IsA("Sound") then
			if enabled then
				if not descendant.Playing then
					descendant:Play()
				end
			else
				descendant:Stop()
			end
		end
	end
end

function StationService:RegisterStation(station, stationType)
	if self._stations[station] then
		return self._stations[station]
	end
	local data = {
		Id = HttpService:GenerateGUID(false),
		Model = station,
		Type = stationType,
		IsLit = false,
		BurnRemaining = 0,
		CookProgress = 0,
	}
	if stationType == "CraftingTable" or stationType == "Chest" or stationType == "AutomaticLoader" or stationType == "Factory" then
		local slotCount = stationType == "Chest" and StationConfig.CHEST_SLOTS
			or stationType == "AutomaticLoader" and StationConfig.AUTOMATIC_LOADER_SLOTS
			or stationType == "Factory" and StationConfig.FINAL_FACTORY_SLOTS
			or StationConfig.CRAFTING_TABLE_SLOTS
		data.Slots = createSlots(slotCount)
	elseif stationType == "Campfire" then
		data.FuelSlots = createSlots(StationConfig.CAMPFIRE_FUEL_SLOTS)
		data.CookingSlots = createSlots(StationConfig.CAMPFIRE_COOKING_SLOTS)
		self:_setEffects(station, false)
	elseif stationType == "Smelt" then
		data.InputSlots = createSlots(SmeltConfig.InputSlots)
		data.FuelSlots = createSlots(SmeltConfig.FuelSlots)
		data.OutputSlots = createSlots(SmeltConfig.OutputSlots)
		data.ActiveRecipe = nil
		data.ProgressElapsed = 0
		data.Status = "ÉTEINT"
		self:_setEffects(station, false)
	else
		return nil
	end
	station:SetAttribute("StationId", data.Id)
	station:SetAttribute("StationType", stationType)
	station:SetAttribute("IsLit", false)
	self._stations[station] = data
	self._viewers[station] = {}
	return data
end

function StationService:OpenStation(player, station)
	local data = self._stations[station]
	if not data or not self:_isPlayerNear(player, station) then
		return false
	end
	self._viewers[station][player] = true
	self._open:FireClient(player, station, self:_buildClientState(data))
	return true
end

function StationService:CanDismantle(station)
	local data = self._stations[station]
	if not data then
		return true
	end
	local function hasItems(slots)
		for _, slot in slots or {} do
			if slot.ItemId ~= nil and slot.Quantity > 0 then
				return true
			end
		end
		return false
	end
	if data.Type == "CraftingTable" or data.Type == "Chest" or data.Type == "AutomaticLoader" or data.Type == "Factory" then
		return not hasItems(data.Slots)
	end
	if data.Type == "Smelt" then
		return not hasItems(data.InputSlots) and not hasItems(data.FuelSlots) and not hasItems(data.OutputSlots)
			and data.IsLit ~= true and (data.BurnRemaining or 0) <= 0
	end
	return not hasItems(data.FuelSlots)
		and not hasItems(data.CookingSlots)
		and data.IsLit ~= true
		and (data.BurnRemaining or 0) <= 0
end

function StationService:UnregisterStation(station)
	if not self._stations[station] then
		return
	end
	self:_setEffects(station, false)
	self._stations[station] = nil
	self._viewers[station] = nil
end

function StationService:GetPersistentState(station)
	local data = self._stations[station]
	if not data then
		return nil, "StationNotRegistered"
	end
	if data.Type == "Chest" or data.Type == "CraftingTable" or data.Type == "AutomaticLoader" or data.Type == "Factory" then
		return {
			StateVersion = 1,
			StationType = data.Type,
			Inventory = {Slots = cloneSlots(data.Slots)},
		}
	elseif data.Type == "Campfire" then
		return {
			StateVersion = CAMPFIRE_STATE_VERSION,
			StationType = data.Type,
			FuelSlots = cloneSlots(data.FuelSlots),
			CookingSlots = cloneSlots(data.CookingSlots),
			IsLit = data.IsLit == true,
			BurnRemaining = math.max(0, data.BurnRemaining or 0),
			CookProgress = math.max(0, data.CookProgress or 0),
		}
	elseif data.Type == "Smelt" then
		return {
			StateVersion = 1, StationType = "Smelt",
			InputSlots = cloneSlots(data.InputSlots), FuelSlots = cloneSlots(data.FuelSlots), OutputSlots = cloneSlots(data.OutputSlots),
			ActiveRecipe = data.ActiveRecipe, ProgressElapsed = math.max(0, data.ProgressElapsed or 0), BurnRemaining = math.max(0, data.BurnRemaining or 0),
		}
	end
	return nil
end

function StationService:RestorePersistentState(station, state)
	local data = self._stations[station]
	if not data or typeof(state) ~= "table" or state.StationType ~= data.Type then
		return false, "InvalidStationState"
	end
	local stateVersion = state.StateVersion
	local supportedVersion = stateVersion == 1
		or (data.Type == "Campfire" and stateVersion == CAMPFIRE_STATE_VERSION)
	if not supportedVersion then return false, "InvalidStationState" end
	if data.Type == "Chest" or data.Type == "CraftingTable" or data.Type == "AutomaticLoader" or data.Type == "Factory" then
		local inventory = state.Inventory
		local slots = typeof(inventory) == "table" and (data.Type == "Factory"
			and validateFactorySlots(inventory.Slots)
			or validateSlots(inventory.Slots, getStationSlotCount(data.Type))) or nil
		if not slots then return false, "InvalidStationInventory" end
		if data.Type == "Factory" then
			if (slots[1].ItemId ~= nil and slots[1].ItemId ~= "MetalPanelStack")
				or (slots[2].ItemId ~= nil and slots[2].ItemId ~= "PlasticPanelStack")
			then return false, "IncompatibleStationItem" end
		end
		for _, slot in slots do
			if slot.ItemId and not self:_canDeposit(data, "Storage", slot.ItemId) then
				return false, "IncompatibleStationItem"
			end
		end
		data.Slots = slots
	elseif data.Type == "Campfire" then
		local fuelSlots = validateSlots(state.FuelSlots, StationConfig.CAMPFIRE_FUEL_SLOTS)
		local cookingSlots = validateSlots(state.CookingSlots, StationConfig.CAMPFIRE_COOKING_SLOTS)
		local burnRemaining = state.BurnRemaining
		local cookProgress = state.CookProgress
		if not fuelSlots or not cookingSlots then return false, "InvalidCampfireInventory" end
		local transientStateValid = typeof(state.IsLit) == "boolean"
			and typeof(burnRemaining) == "number" and burnRemaining == burnRemaining
			and burnRemaining >= 0 and burnRemaining <= StationConfig.CAMPFIRE_WOOD_BURN_TIME
			and typeof(cookProgress) == "number" and cookProgress == cookProgress
			and cookProgress >= 0 and cookProgress < StationConfig.CAMPFIRE_COOK_TIME
		for _, slot in fuelSlots do
			if slot.ItemId and not self:_canDeposit(data, "Fuel", slot.ItemId) then return false, "IncompatibleFuel" end
		end
		local hasConfiguredOutput = false
		local incompatibleItemIds = {}
		for _, slot in cookingSlots do
			if slot.ItemId then
				local itemKind = getCampfireCookingItemKind(slot.ItemId)
				if itemKind == "Output" then
					hasConfiguredOutput = true
				elseif itemKind == nil and not table.find(incompatibleItemIds, slot.ItemId) then
					table.insert(incompatibleItemIds, slot.ItemId)
				end
			end
		end
		data.FuelSlots = fuelSlots
		data.CookingSlots = cookingSlots
		local restoreInfo
		if #incompatibleItemIds > 0 or not transientStateValid then
			data.IsLit = false
			data.BurnRemaining = 0
			data.CookProgress = 0
			local recoveryReason = #incompatibleItemIds > 0 and "IncompatibleCooking" or "InvalidCookingTransient"
			local affectedFields = #incompatibleItemIds > 0
				and ("CookingSlots(" .. table.concat(incompatibleItemIds, ",") .. ")")
				or "IsLit/BurnRemaining/CookProgress"
			restoreInfo = {Recovered = true, Reason = recoveryReason, Action = "CookingStateReset"}
			warn(string.format(
				"[MAYDEAD][PERSISTENCE][RECOVERY] StructureId=%s Type=%s Reason=%s Fields=%s Action=CookingStateReset StructurePreserved=true InventoryPreserved=true",
				tostring(station:GetAttribute("StructureId")),
				data.Type,
				recoveryReason,
				affectedFields
			))
		else
			data.IsLit = state.IsLit and burnRemaining > 0
			data.BurnRemaining = data.IsLit and burnRemaining or 0
			data.CookProgress = cookProgress
			if stateVersion == 1 and hasConfiguredOutput then
				restoreInfo = {Migrated = true, Reason = "LegacyCookingOutput", Action = "CookingOutputAccepted"}
				print(string.format(
					"[MAYDEAD][PERSISTENCE][MIGRATION] StructureId=%s Type=%s LegacyCooking=true Action=CookingOutputAccepted StructurePreserved=true InventoryPreserved=true",
					tostring(station:GetAttribute("StructureId")),
					data.Type
				))
			end
		end
		station:SetAttribute("IsLit", data.IsLit)
		self:_setEffects(station, data.IsLit)
		self:_syncStation(station)
		return true, nil, restoreInfo
	elseif data.Type == "Smelt" then
		local inputSlots = validateSlots(state.InputSlots, SmeltConfig.InputSlots)
		local fuelSlots = validateSlots(state.FuelSlots, SmeltConfig.FuelSlots)
		local outputSlots = validateSlots(state.OutputSlots, SmeltConfig.OutputSlots)
		local recipe = state.ActiveRecipe == nil and nil or SmeltConfig.Recipes[state.ActiveRecipe]
		local progress = state.ProgressElapsed
		local burn = state.BurnRemaining
		if not inputSlots or not fuelSlots or not outputSlots or (state.ActiveRecipe ~= nil and not recipe)
			or typeof(progress) ~= "number" or progress ~= progress or progress < 0 or (recipe and progress >= recipe.Duration)
			or (state.ActiveRecipe == nil and progress ~= 0)
			or typeof(burn) ~= "number" or burn ~= burn or burn < 0 or burn > SmeltConfig.FuelDefinitions.Wood.BurnSeconds then return false, "InvalidSmeltState" end
		for _, slot in inputSlots do if slot.ItemId and not self:_canDeposit(data, "Input", slot.ItemId) then return false, "IncompatibleInput" end end
		for _, slot in fuelSlots do if slot.ItemId and not self:_canDeposit(data, "Fuel", slot.ItemId) then return false, "IncompatibleFuel" end end
		local validOutputs = {CopperIngot = true, MetalIngot = true, GoldIngot = true}
		for _, slot in outputSlots do if slot.ItemId and not validOutputs[slot.ItemId] then return false, "IncompatibleOutput" end end
		data.InputSlots, data.FuelSlots, data.OutputSlots = inputSlots, fuelSlots, outputSlots
		data.ActiveRecipe, data.ProgressElapsed, data.BurnRemaining = state.ActiveRecipe, progress, burn
		data.IsLit, data.Status = false, "ÉTEINT"
		station:SetAttribute("IsLit", false); self:_setEffects(station, false)
	end
	self:_syncStation(station)
	return true
end

function StationService:_getDestination(data, area)
	if (data.Type == "CraftingTable" or data.Type == "Chest" or data.Type == "AutomaticLoader" or data.Type == "Factory") and area == "Storage" then
		return data.Slots
	elseif data.Type == "Campfire" and area == "Fuel" then
		return data.FuelSlots
	elseif data.Type == "Campfire" and area == "Cooking" then
		return data.CookingSlots
	elseif data.Type == "Smelt" and area == "Input" then return data.InputSlots
	elseif data.Type == "Smelt" and area == "Fuel" then return data.FuelSlots
	elseif data.Type == "Smelt" and area == "Output" then return data.OutputSlots
	end
	return nil
end

function StationService:_canDeposit(data, area, itemId)
	if data.Type == "CraftingTable" then
		local definition = ItemDefinitions[itemId]
		return area == "Storage" and definition ~= nil and definition.Category == "Resource"
	elseif data.Type == "Chest" then
		return area == "Storage" and ItemDefinitions[itemId] ~= nil
	elseif data.Type == "AutomaticLoader" then
		return area == "Storage" and (itemId == "MetalWaste" or itemId == "PlasticWaste" or itemId == "WasteBag")
	elseif data.Type == "Factory" then
		return area == "Storage" and (itemId == "MetalPanelStack" or itemId == "PlasticPanelStack")
	end
	if data.Type == "Smelt" then
		if area == "Fuel" then return SmeltConfig.FuelDefinitions[itemId] ~= nil end
		if area == "Input" then
			for _, recipe in SmeltConfig.Recipes do if recipe.InputItem == itemId then return true end end
		end
		return false
	end
	return (area == "Fuel" and itemId == "Wood")
		or (area == "Cooking" and StationConfig.CAMPFIRE_RECIPES[itemId] ~= nil)
end

function StationService:GetStoredItemQuantity(station, itemId)
	local data = self._stations[station]
	return data and data.Slots and getItemQuantity(data.Slots, itemId) or 0
end

function StationService:ConsumeStoredItems(station, ingredients)
	local data = self._stations[station]
	if not data or data.Type ~= "Factory" then return false end
	local working = cloneSlots(data.Slots)
	for itemId, quantity in ingredients do
		if getItemQuantity(working, itemId) < quantity or not removeFromSlots(working, itemId, quantity) then return false end
	end
	data.Slots = working
	self:_syncStation(station)
	return true
end

function StationService:TakeAutomaticLoaderItem(station)
	local data = self._stations[station]
	if not data or data.Type ~= "AutomaticLoader" then return nil end
	for _, slot in ipairs(data.Slots) do
		if slot.ItemId and slot.Quantity > 0 then
			local itemId = slot.ItemId
			slot.Quantity = slot.Quantity - 1
			if slot.Quantity <= 0 then slot.ItemId, slot.Quantity = nil, 0 end
			self:_syncStation(station)
			return itemId
		end
	end
	return nil
end

function StationService:_transferToStation(player, station, data, request)
	local playerInventory = InventoryService:GetInventory(player)
	local slotIndex = request.PlayerSlotIndex
	local area = request.Area
	local mode = request.Mode
	if not playerInventory
		or typeof(slotIndex) ~= "number"
		or slotIndex ~= math.floor(slotIndex)
		or (mode ~= "SINGLE" and mode ~= "FULL_STACK" and mode ~= "HALF_STACK")
	then
		return
	end
	local slot = playerInventory.Slots[slotIndex]
	local destination = self:_getDestination(data, area)
	if not slot or not slot.ItemId or slot.Quantity <= 0 or not destination then
		return
	end
	if not self:_canDeposit(data, area, slot.ItemId) then
		return
	end
	local itemId = slot.ItemId
	if data.Type == "Factory" then
		local dedicatedSlot = itemId == "MetalPanelStack" and 1 or itemId == "PlasticPanelStack" and 2 or nil
		if not dedicatedSlot or (request.StationSlotIndex ~= nil and request.StationSlotIndex ~= dedicatedSlot) then return end
		request.StationSlotIndex = dedicatedSlot
	end
	if not isCompatibleTarget(destination, request.StationSlotIndex, itemId) then
		return
	end
	local requestedQuantity = mode == "FULL_STACK" and slot.Quantity
		or mode == "HALF_STACK" and math.floor(slot.Quantity / 2)
		or 1
	local destinationCapacity = getAddCapacity(destination, itemId)
	if data.Type == "Factory" then
		local target = destination[request.StationSlotIndex]
		destinationCapacity = ItemDefinitions[itemId].MaxStack - (target.ItemId == itemId and target.Quantity or 0)
	end
	local quantity = math.min(requestedQuantity, destinationCapacity)
	if quantity <= 0 then
		return
	end
	local structureId = station:GetAttribute("StructureId")
	if data.Type == "Factory" and RunService:IsStudio() then
		print(string.format(
			"[MAYDEAD][FINAL_FACTORY][TRANSFER] Action=Before Direction=PlayerToFactory StructureId=%s ItemId=%s Quantity=%d PlayerQty=%d FactoryMetal=%d FactoryPlastic=%d",
			tostring(structureId), itemId, quantity, slot.Quantity,
			getItemQuantity(destination, "MetalPanelStack"),
			getItemQuantity(destination, "PlasticPanelStack")
		))
	end
	local removedItemId, removedQuantity = InventoryService:TakeFromSlot(player, slotIndex, quantity)
	if removedItemId ~= itemId or removedQuantity ~= quantity then
		return
	end
	local addedToDestination
	if data.Type == "Factory" then
		local target = destination[request.StationSlotIndex]
		if target.ItemId == nil then target.ItemId, target.Quantity = itemId, 0 end
		target.Quantity += quantity
		addedToDestination = true
	else
		addedToDestination = addToSlots(destination, itemId, quantity)
	end
	if not addedToDestination then
		InventoryService:AddItem(player, itemId, quantity)
		return
	end
	if data.Type == "AutomaticLoader" then
		print("[MAYDEAD][FACTORY] AutomaticLoader accepted " .. itemId)
	end
	if data.Type == "Factory" and RunService:IsStudio() then
		local updatedInventory = InventoryService:GetInventory(player)
		local updatedSlot = updatedInventory and updatedInventory.Slots[slotIndex]
		local playerQuantity = updatedSlot and updatedSlot.ItemId == itemId and updatedSlot.Quantity or 0
		print(string.format(
			"[MAYDEAD][FINAL_FACTORY][TRANSFER] Action=After Direction=PlayerToFactory StructureId=%s ItemId=%s Quantity=%d PlayerQty=%d FactoryMetal=%d FactoryPlastic=%d",
			tostring(structureId), itemId, quantity, playerQuantity,
			getItemQuantity(destination, "MetalPanelStack"),
			getItemQuantity(destination, "PlasticPanelStack")
		))
	end
	self:_syncStation(station)
	self.StorageChanged:Fire(station, data.Type)
end

function StationService:_transferToPlayer(player, station, data, request)
	local source = self:_getDestination(data, request.Area)
	local slotIndex = request.StationSlotIndex
	local mode = request.Mode
	if not source
		or typeof(slotIndex) ~= "number"
		or slotIndex ~= math.floor(slotIndex)
		or (mode ~= "SINGLE" and mode ~= "FULL_STACK" and mode ~= "HALF_STACK")
	then
		return
	end
	local slot = source[slotIndex]
	if not slot or not slot.ItemId or slot.Quantity <= 0 then
		return
	end
	local itemId = slot.ItemId
	local playerInventory = InventoryService:GetInventory(player)
	if not playerInventory or not isCompatibleTarget(playerInventory.Slots, request.PlayerSlotIndex, itemId) then
		return
	end
	local requestedQuantity = mode == "FULL_STACK" and slot.Quantity
		or mode == "HALF_STACK" and math.floor(slot.Quantity / 2)
		or 1
	local quantity = math.min(requestedQuantity, InventoryService:GetAddCapacity(player, itemId))
	if quantity <= 0 then
		return
	end
	local added = InventoryService:AddItem(player, itemId, quantity)
	if added.Added <= 0 then
		return
	end
	slot.Quantity = slot.Quantity - added.Added
	if slot.Quantity <= 0 then
		slot.ItemId = nil
		slot.Quantity = 0
	end
	self:_syncStation(station)
	self.StorageChanged:Fire(station, data.Type)
end

function StationService:TryWorkbenchCraft(player, station, recipe)
	local data = self._stations[station]
	if not data or data.Type ~= "CraftingTable" or not self:_isPlayerNear(player, station) then
		return false, "WorkbenchRequired"
	end
	for itemId, quantity in recipe.Ingredients do
		if getItemQuantity(data.Slots, itemId) < quantity then
			return false, "MissingIngredients"
		end
	end
	if not InventoryService:CanAddItem(player, recipe.ResultItemId, recipe.ResultAmount) then
		return false, "InventoryFull"
	end

	local workingSlots = cloneSlots(data.Slots)
	for itemId, quantity in recipe.Ingredients do
		if not removeFromSlots(workingSlots, itemId, quantity) then
			return false, "MissingIngredients"
		end
	end
	local added = InventoryService:AddItem(player, recipe.ResultItemId, recipe.ResultAmount)
	if added.Remaining > 0 then
		return false, "InventoryFull"
	end
	data.Slots = workingSlots
	self:_syncStation(station)
	return true, "Ok"
end

function StationService:_processCampfire(station, data, deltaTime)
	local hasFuel = getItemQuantity(data.FuelSlots, "Wood") > 0
	if not hasFuel then
		if data.IsLit then
			data.IsLit = false
			data.BurnRemaining = 0
			station:SetAttribute("IsLit", false)
			self:_setEffects(station, false)
			self:_syncStation(station)
		end
		return
	end

	if not data.IsLit then
		data.IsLit = true
		data.BurnRemaining = StationConfig.CAMPFIRE_WOOD_BURN_TIME
		station:SetAttribute("IsLit", true)
		self:_setEffects(station, true)
	end
	data.BurnRemaining = data.BurnRemaining - deltaTime
	if data.BurnRemaining <= 0 then
		removeFromSlots(data.FuelSlots, "Wood", 1)
		if getItemQuantity(data.FuelSlots, "Wood") > 0 then
			data.BurnRemaining = data.BurnRemaining + StationConfig.CAMPFIRE_WOOD_BURN_TIME
		else
			data.BurnRemaining = 0
			data.IsLit = false
			station:SetAttribute("IsLit", false)
			self:_setEffects(station, false)
		end
	end

	local rawItemId
	local cookedItemId
	for candidateRaw, candidateCooked in StationConfig.CAMPFIRE_RECIPES do
		if getItemQuantity(data.CookingSlots, candidateRaw) > 0 then
			rawItemId = candidateRaw
			cookedItemId = candidateCooked
			break
		end
	end
	if data.IsLit and rawItemId and cookedItemId then
		local workingSlots = cloneSlots(data.CookingSlots)
		if removeFromSlots(workingSlots, rawItemId, 1) and canAddToSlots(workingSlots, cookedItemId, 1) then
			data.CookProgress = data.CookProgress + deltaTime
			if data.CookProgress >= StationConfig.CAMPFIRE_COOK_TIME then
				removeFromSlots(data.CookingSlots, rawItemId, 1)
				addToSlots(data.CookingSlots, cookedItemId, 1)
				data.CookProgress = data.CookProgress - StationConfig.CAMPFIRE_COOK_TIME
			end
		end
	elseif not rawItemId then
		data.CookProgress = 0
	end
	self:_syncStation(station)
end

function StationService:_processSmelt(station, data, deltaTime)
	local recipe = data.ActiveRecipe and SmeltConfig.Recipes[data.ActiveRecipe]
	if not recipe then
		data.ActiveRecipe, data.ProgressElapsed = nil, 0
		for _, recipeId in SmeltConfig.RecipeOrder do
			local candidate = SmeltConfig.Recipes[recipeId]
			if getItemQuantity(data.InputSlots, candidate.InputItem) >= candidate.InputAmount then data.ActiveRecipe, recipe = recipeId, candidate; break end
		end
	end
	local status = "PRÊT"
	local hasInput = recipe and getItemQuantity(data.InputSlots, recipe.InputItem) >= recipe.InputAmount
	local canOutput = recipe and canAddToSlots(data.OutputSlots, recipe.OutputItem, recipe.OutputAmount)
	if not recipe then status = "ÉTEINT"
	elseif not hasInput then status = "PRÊT"
	elseif not canOutput then status = "SORTIE PLEINE"
	elseif data.BurnRemaining <= 0 and getItemQuantity(data.FuelSlots, "Wood") <= 0 then status = "MANQUE DE COMBUSTIBLE" end
	local working = recipe and hasInput and canOutput and (data.BurnRemaining > 0 or getItemQuantity(data.FuelSlots, "Wood") > 0)
	if working and data.BurnRemaining <= 0 then removeFromSlots(data.FuelSlots, "Wood", 1); data.BurnRemaining = SmeltConfig.FuelDefinitions.Wood.BurnSeconds end
	if working then
		data.BurnRemaining = math.max(0, data.BurnRemaining - deltaTime); data.ProgressElapsed = data.ProgressElapsed + deltaTime; status = recipe.StatusText
		if data.ProgressElapsed >= recipe.Duration then
			if removeFromSlots(data.InputSlots, recipe.InputItem, recipe.InputAmount) and addToSlots(data.OutputSlots, recipe.OutputItem, recipe.OutputAmount) then data.ProgressElapsed, data.ActiveRecipe = 0, nil end
		end
	end
	if data.IsLit ~= working then data.IsLit = working; station:SetAttribute("IsLit", working); self:_setEffects(station, working) end
	data.Status = status
	self:_syncStation(station)
end

function StationService:Start(worldService)
	self._request.OnServerEvent:Connect(function(player, action, station, request)
		if player:GetAttribute("SessionStarted") ~= true
			or (worldService and not worldService:IsRuntimeMember(player))
		then return end
		if typeof(action) ~= "string" or not STATION_REQUEST_ACTIONS[action]
			or typeof(station) ~= "Instance" or not isValidTransferRequest(action, request)
			or not self:_consumeRequestBudget(player)
		then return end
		local data = self._stations[station]
		if not data or station:GetAttribute("StationId") ~= data.Id or not self:_isPlayerNear(player, station) then
			return
		end
		if data.Type == "Factory" and typeof(station:GetAttribute("StructureId")) ~= "string" then return end
		self._viewers[station][player] = true
		if action == "TransferToStation" then
			self:_transferToStation(player, station, data, request)
		elseif action == "TransferToPlayer" then
			self:_transferToPlayer(player, station, data, request)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._requestBudgets[player] = nil
		for _, viewers in self._viewers do
			viewers[player] = nil
		end
	end)

	task.spawn(function()
		local lastUpdate = os.clock()
		while true do
			task.wait(0.25)
			local now = os.clock()
			local deltaTime = math.min(now - lastUpdate, 1)
			lastUpdate = now
			for station, data in self._stations do
				if not station:IsDescendantOf(workspace) then
					self._stations[station] = nil
					self._viewers[station] = nil
				elseif data.Type == "Campfire" then
					self:_processCampfire(station, data, deltaTime)
				elseif data.Type == "Smelt" then
					self:_processSmelt(station, data, deltaTime)
				end
			end
		end
	end)
end

return StationService.new()
