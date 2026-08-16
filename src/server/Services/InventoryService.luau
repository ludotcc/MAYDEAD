local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local FlaskConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("FlaskConfig"))
local FishingConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("FishingConfig"))
local InventoryConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("InventoryConfig"))
local ItemDefinitions = require(SharedFolder:WaitForChild("Definitions"):WaitForChild("ItemDefinitions"))
local SurvivalService = require(script.Parent:WaitForChild("SurvivalService"))

local InventoryService = {}
InventoryService.__index = InventoryService

local INVENTORY_SIZE = InventoryConfig.MAIN_SLOT_COUNT
local QUICK_SLOT_COUNT = InventoryConfig.QUICK_SLOT_COUNT
-- Logical slots 1-20 are main inventory; 21-28 are real quick-access inventory slots.
local TOTAL_SLOT_COUNT = INVENTORY_SIZE + QUICK_SLOT_COUNT
local INVENTORY_SCHEMA_VERSION = 2
local REMOTE_NAME = "InventoryStateChanged"
local REQUEST_NAME = "InventoryRequest"
local FOOD_CONSUMED_NAME = "FoodConsumed"
local FLASK_REQUEST_NAME = "FlaskRequest"
local FLASK_RESULT_NAME = "FlaskResult"

local function makeFishingRodPartEquipSafe(part)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
end

local function logFishingRootVelocity(character, stage)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return end
	print(string.format(
		"[MAYDEAD][FISHING] %s root linear=%s angular=%s",
		stage,
		tostring(root.AssemblyLinearVelocity),
		tostring(root.AssemblyAngularVelocity)
	))
end

local function logFishingPart(part)
	print(string.format(
		"[MAYDEAD][FISHING] Part name=%s class=%s anchored=%s collide=%s massless=%s assemblyMass=%.4f",
		part.Name,
		part.ClassName,
		tostring(part.Anchored),
		tostring(part.CanCollide),
		tostring(part.Massless),
		part.AssemblyMass
	))
end

local function basisFromDirection(direction, upHint)
	local look = direction.Unit
	local projectedUp = upHint - look * upHint:Dot(look)
	if projectedUp.Magnitude < 0.001 then
		local alternateUp = Vector3.zAxis
		projectedUp = alternateUp - look * alternateUp:Dot(look)
	end
	local up = projectedUp.Unit
	local right = look:Cross(up).Unit
	return CFrame.fromMatrix(Vector3.zero, right, up, -look)
end

local function getFishingRodGrip(handle, visual)
	local lineStart = visual:FindFirstChild("LineStart", true)
	if not lineStart or not lineStart:IsA("Attachment") then
		warn("[MAYDEAD][FISHING] LineStart missing; unable to derive Fishing_Rod orientation")
		return CFrame.new(FishingConfig.FishingRodGrip.Position), CFrame.identity
	end
	local lineStartLocal = handle.CFrame:PointToObjectSpace(lineStart.WorldPosition)
	local forwardSign = lineStartLocal.X >= 0 and 1 or -1
	local rodDirection = Vector3.new(forwardSign, 0, 0)
	if rodDirection.Magnitude < 0.001 then
		warn("[MAYDEAD][FISHING] Handle to LineStart axis is degenerate")
		return CFrame.new(FishingConfig.FishingRodGrip.Position), CFrame.identity
	end
	local grip = FishingConfig.FishingRodGrip
	local yaw = math.rad(grip.ForwardYawDegrees)
	local elevation = math.rad(grip.ElevationDegrees)
	local targetDirection = Vector3.new(
		math.sin(yaw) * math.cos(elevation),
		math.sin(elevation),
		-math.cos(yaw) * math.cos(elevation)
	).Unit
	local localBasis = basisFromDirection(rodDirection, Vector3.yAxis)
	local targetBasis = basisFromDirection(targetDirection, Vector3.yAxis)
	local rotation = grip.Rotation
	local c0 = CFrame.new(grip.Position)
		* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		* targetBasis
		* localBasis:Inverse()
	local rearGripX = -forwardSign * math.max(0, (handle.Size.X * 0.5) - grip.RearGripInset)
	local c1 = CFrame.new(rearGripX, 0, 0)
	if RunService:IsStudio() then
		print(string.format(
			"[MAYDEAD][FISHING] Handle class=%s size=%s pivotOffset=%s Right=%s Up=%s Look=%s LineStartLocal=%s ROD_FORWARD_AXIS=%s C0=%s C1=%s",
			handle.ClassName,
			tostring(handle.Size),
			tostring(handle.PivotOffset),
			tostring(handle.CFrame.RightVector),
			tostring(handle.CFrame.UpVector),
			tostring(handle.CFrame.LookVector),
			tostring(lineStartLocal),
			forwardSign > 0 and "+X" or "-X",
			tostring(c0),
			tostring(c1)
		))
	end
	return c0, c1
end
local function clearSlot(slot)
	slot.ItemId = nil
	slot.Quantity = 0
	slot.WaterCharges = nil
end

local function findMainItemSlot(inventory, itemId)
	for index = 1, INVENTORY_SIZE do
		local slot = inventory.Slots[index]
		if slot and slot.ItemId == itemId and slot.Quantity > 0 then
			return slot, index
		end
	end
	return nil, nil
end

local function cloneSlot(slot)
	return {
		ItemId = slot.ItemId,
		Quantity = slot.Quantity,
		WaterCharges = slot.WaterCharges,
	}
end

local function normalizeToolName(name)
	return string.lower(string.match(name, "^%s*(.-)%s*$") or name)
end

local function findNormalizedTool(container, toolName)
	if not container then
		return nil
	end
	local normalizedExpectedName = normalizeToolName(toolName)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") and normalizeToolName(child.Name) == normalizedExpectedName then
			return child
		end
	end
	return nil
end

local function findAxeTemplate()
	for _, child in ipairs(StarterPack:GetChildren()) do
		local bytes = {}
		for index = 1, string.len(child.Name) do
			table.insert(bytes, tostring(string.byte(child.Name, index)))
		end
		print(
			"[MAYDEAD] StarterPack child name = "
				.. string.format("%q", child.Name)
				.. ", length = "
				.. tostring(string.len(child.Name))
				.. ", class = "
				.. child.ClassName
				.. ", bytes = "
				.. table.concat(bytes, ",")
		)
		if child:IsA("Tool") and normalizeToolName(child.Name) == "axe" then
			print("[MAYDEAD] Axe matched runtime name = " .. string.format("%q", child.Name))
			if child.Name ~= "Axe" then
				child.Name = "Axe"
			end
			return child
		end
	end
	return nil
end

local function removeFishingRodVisual(character)
	if not character then return end
	local visual = character:FindFirstChild("MAYDEADFishingRodVisual")
	if visual then visual:Destroy() end
	local motor = character:FindFirstChild("MAYDEADFishingRodVisualGrip", true)
	if motor then motor:Destroy() end
end

local function hideFishingRodToolVisual(tool)
	for _, descendant in tool:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			makeFishingRodPartEquipSafe(descendant)
		elseif descendant:IsA("RopeConstraint") then
			descendant.Visible = false
		end
	end
end

local function removeNativeFishingRodGrip(character, tool)
	local removed = false
	for _, descendant in character:GetDescendants() do
		if descendant.Name == "RightGrip" and descendant:IsA("JointInstance")
			and (descendant.Part1 == nil or descendant.Part1:IsDescendantOf(tool))
		then
			descendant:Destroy()
			removed = true
		end
	end
	return removed
end

local function createFishingRodVisual(character, tool)
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local assetImports = ServerStorage:FindFirstChild("AssetImports")
	local source = assetImports and assetImports:FindFirstChild("Fishing_Rod", true)
	if not hand or not hand:IsA("BasePart") or not source then
		warn("[MAYDEAD][FISHING] Visual unavailable: RightHand/Right Arm or source asset missing")
		return false
	end

	removeFishingRodVisual(character)
	hideFishingRodToolVisual(tool)
	local nativeGripRemoved = removeNativeFishingRodGrip(character, tool)

	local visual = Instance.new("Model")
	visual.Name = "MAYDEADFishingRodVisual"
	local sourceClone = source:Clone()
	if sourceClone:IsA("BasePart") then
		sourceClone.Parent = visual
	else
		for _, child in sourceClone:GetChildren() do
			child.Parent = visual
		end
		sourceClone:Destroy()
	end
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then descendant:Destroy() end
	end

	local handle = visual:FindFirstChild("Handle", true)
		or visual:FindFirstChild("Grip", true)
		or visual:FindFirstChild("HandGrip", true)
		or visual:FindFirstChildWhichIsA("BasePart", true)
	if not handle or not handle:IsA("BasePart") then
		visual:Destroy()
		warn("[MAYDEAD][FISHING] Visual unavailable: Handle missing from source asset")
		return false
	end
	handle.Name = "Handle"
	visual.PrimaryPart = handle
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("JointInstance") or descendant:IsA("WeldConstraint") then
			descendant:Destroy()
		elseif descendant:IsA("AlignPosition") or descendant:IsA("AlignOrientation")
			or descendant:IsA("LinearVelocity") or descendant:IsA("AngularVelocity")
			or descendant:IsA("VectorForce") or descendant:IsA("BodyMover")
		then
			descendant:Destroy()
		end
	end
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") then
			makeFishingRodPartEquipSafe(descendant)
			if descendant ~= handle then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "MAYDEADFishingRodVisualWeld"
				weld.Part0 = handle
				weld.Part1 = descendant
				weld.Parent = handle
			end
			logFishingPart(descendant)
		end
	end
	visual.Parent = character
	logFishingRootVelocity(character, "after visual parent")

	local motor = Instance.new("Motor6D")
	motor.Name = "MAYDEADFishingRodVisualGrip"
	motor.Part0 = hand
	motor.Part1 = handle
	local gripC0, gripC1 = getFishingRodGrip(handle, visual)
	motor.C0 = gripC0
	motor.C1 = gripC1
	motor.Parent = hand
	logFishingRootVelocity(character, "after visual Motor6D")

	task.defer(function()
		if character.Parent and tool.Parent == character then
			nativeGripRemoved = removeNativeFishingRodGrip(character, tool) or nativeGripRemoved
			local activeGripTransforms = 0
			for _, descendant in character:GetDescendants() do
				if descendant:IsA("JointInstance") and descendant.Part0 == hand and descendant.Part1
					and (descendant.Part1:IsDescendantOf(tool) or descendant.Part1:IsDescendantOf(visual))
				then
					activeGripTransforms += 1
				end
			end
			print("[MAYDEAD][FISHING] Native RightGrip removed = " .. tostring(nativeGripRemoved))
			print("[MAYDEAD][FISHING] Native Tool visual hidden = true")
			print("[MAYDEAD][FISHING] Visual clone created = " .. tostring(visual.Parent == character))
			print("[MAYDEAD][FISHING] Visual Motor6D created = " .. tostring(motor.Parent == hand))
			print("[MAYDEAD][FISHING] Active grip transforms = " .. tostring(activeGripTransforms))
		end
	end)
	return true
end

local function watchFishingRodUnequip(tool)
	tool.Unequipped:Connect(function()
		for _, player in Players:GetPlayers() do
			if tool:IsDescendantOf(player) then
				removeFishingRodVisual(player.Character)
				break
			end
		end
	end)
end

local function cloneImportedTool(toolName)
	if toolName == "Fishing_Rod" then
		local tool = Instance.new("Tool")
		tool.Name = toolName
		tool.CanBeDropped = false
		tool.RequiresHandle = false
		watchFishingRodUnequip(tool)
		return tool
	end
	local assetImports = ServerStorage:FindFirstChild("AssetImports")
	local source = assetImports and assetImports:FindFirstChild(toolName, true)
	if not source then
		return nil
	end
	local clone = source:Clone()
	if clone:IsA("Tool") then
		clone.Name = toolName
		clone.CanBeDropped = false
		for _, descendant in clone:GetDescendants() do
			if descendant:IsA("BasePart") then
				makeFishingRodPartEquipSafe(descendant)
			end
		end
		return clone
	end

	local tool = Instance.new("Tool")
	tool.Name = toolName
	tool.CanBeDropped = false
	tool.RequiresHandle = false
	clone.Parent = tool
	local handle = clone:IsA("BasePart") and clone
		or clone:FindFirstChild("Handle", true)
		or clone:FindFirstChild("Grip", true)
		or clone:FindFirstChild("HandGrip", true)
		or (clone:IsA("Model") and clone.PrimaryPart)
		or clone:FindFirstChildWhichIsA("BasePart", true)
	if handle and not handle:IsA("BasePart") then
		handle = clone:IsA("Model") and clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
	end
	if handle then
		handle.Parent = tool
		handle.Name = "Handle"
		tool.RequiresHandle = toolName ~= "Fishing_Rod"
		for _, descendant in tool:GetDescendants() do
			if descendant:IsA("BasePart") then
				makeFishingRodPartEquipSafe(descendant)
				if descendant ~= handle then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = handle
					weld.Part1 = descendant
					weld.Parent = handle
				end
			end
		end
	end
	return tool
end

function InventoryService.new()
	local self = setmetatable({}, InventoryService)
	self.PlayerInventories = {}
	self._replicate = Instance.new("RemoteEvent")
	self._replicate.Name = REMOTE_NAME
	self._replicate.Parent = ReplicatedStorage
	self._request = Instance.new("RemoteEvent")
	self._request.Name = REQUEST_NAME
	self._request.Parent = ReplicatedStorage
	self._foodConsumed = Instance.new("RemoteEvent")
	self._foodConsumed.Name = FOOD_CONSUMED_NAME
	self._foodConsumed.Parent = ReplicatedStorage
	self._flaskRequest = Instance.new("RemoteEvent")
	self._flaskRequest.Name = FLASK_REQUEST_NAME
	self._flaskRequest.Parent = ReplicatedStorage
	self._flaskResult = Instance.new("RemoteEvent")
	self._flaskResult.Name = FLASK_RESULT_NAME
	self._flaskResult.Parent = ReplicatedStorage
	self._lastFlaskAttempts = {}
	return self
end

function InventoryService:_removeUnownedStarterTools(player)
	local inventory = self.PlayerInventories[player]
	if not inventory then return end
	local owned = {Axe = self:HasItem(player, "StoneAxe", 1), Pickaxe = self:HasItem(player, "StonePickaxe", 1)}
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, container in {backpack, player.Character} do
		if container then
			for toolName, isOwned in owned do
				local tool = container:FindFirstChild(toolName)
				if tool and tool:IsA("Tool") and not isOwned then tool:Destroy() end
			end
		end
	end
end

function InventoryService:Start()
	Players.PlayerAdded:Connect(function(player)
		self.PlayerInventories[player] = self:_createEmptyInventory()
		self:_syncPlayer(player)
		player.CharacterAdded:Connect(function()
			task.delay(0.25, function() self:_removeUnownedStarterTools(player) end)
		end)
		task.spawn(function()
			local backpack = player:WaitForChild("Backpack")
			backpack.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and (child.Name == "Axe" or child.Name == "Pickaxe") then
					task.defer(function() self:_removeUnownedStarterTools(player) end)
				end
			end)
		end)
		task.delay(0.25, function() self:_removeUnownedStarterTools(player) end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.PlayerInventories[player] = nil
		self._lastFlaskAttempts[player] = nil
	end)

	self._request.OnServerEvent:Connect(function(player, action, data)
		if player:GetAttribute("SessionStarted") ~= true then return end
		if not self.PlayerInventories[player] then
			return
		end

		if action == "Move" then
			self:_handleMove(player, data)
		elseif action == "Use" then
			self:_handleUse(player, data)
		elseif action == "SelectQuickSlot" then
			self:_handleSelectQuickSlot(player, data)
		elseif action == "ClearSelectedItem" then
			self:ClearSelectedItem(player)
		elseif action == "RequestState" then
			self:_syncPlayer(player)
		end
	end)

	self._flaskRequest.OnServerEvent:Connect(function(player, action)
		if player:GetAttribute("SessionStarted") ~= true then return end
		self:_handleFlaskRequest(player, action)
	end)
end

function InventoryService:_createEmptyInventory()
	local slots = {}
	for _ = 1, TOTAL_SLOT_COUNT do
		table.insert(slots, {ItemId = nil, Quantity = 0, WaterCharges = nil})
	end
	return {
		Slots = slots,
		ActiveQuickSlot = 0,
		InventoryVersion = INVENTORY_SCHEMA_VERSION,
	}
end

function InventoryService:_migrateInventory(inventory)
	if inventory.InventoryVersion == INVENTORY_SCHEMA_VERSION then return end
	-- V1 quick slots were ItemId references. Move one matching real stack into each
	-- referenced slot and clear its former main slot so migration cannot duplicate.
	for quickIndex = 1, QUICK_SLOT_COUNT do
		local slotIndex = INVENTORY_SIZE + quickIndex
		local legacyReference = inventory.Slots[slotIndex]
		if not legacyReference then
			legacyReference = {ItemId = nil, Quantity = 0, WaterCharges = nil}
			inventory.Slots[slotIndex] = legacyReference
		elseif legacyReference.ItemId then
			local _, sourceIndex = findMainItemSlot(inventory, legacyReference.ItemId)
			if sourceIndex then
				inventory.Slots[slotIndex] = inventory.Slots[sourceIndex]
				inventory.Slots[sourceIndex] = {ItemId = nil, Quantity = 0, WaterCharges = nil}
			else
				clearSlot(legacyReference)
			end
		end
	end
	inventory.InventoryVersion = INVENTORY_SCHEMA_VERSION
end

function InventoryService:_syncPlayer(player, grantedItem)
	local inventory = self.PlayerInventories[player]
	if not inventory then
		return
	end
	self:_migrateInventory(inventory)

	self._replicate:FireClient(player, {
		Slots = inventory.Slots,
		ActiveQuickSlot = inventory.ActiveQuickSlot,
		InventoryVersion = inventory.InventoryVersion,
		GrantedItem = grantedItem,
	})
end

function InventoryService:AddItem(player, itemId, quantity)
	assert(typeof(player) == "Instance", "Player expected")
	assert(typeof(itemId) == "string", "ItemId must be a string")
	assert(typeof(quantity) == "number", "Quantity must be a number")

	local definition = ItemDefinitions[itemId]
	if not definition then
		return {Added = 0, Remaining = quantity, Reason = "InvalidItem"}
	end

	if quantity <= 0 then
		return {Added = 0, Remaining = 0, Reason = "InvalidQuantity"}
	end

	local inventory = self.PlayerInventories[player]
	if not inventory then
		return {Added = 0, Remaining = quantity, Reason = "MissingInventory"}
	end

	local remaining = quantity
	local added = 0

	for index = 1, TOTAL_SLOT_COUNT do
		local slot = inventory.Slots[index]
		if not slot then
			continue
		end

		if slot.ItemId == itemId and slot.Quantity < definition.MaxStack then
			local space = definition.MaxStack - slot.Quantity
			local toAdd = math.min(remaining, space)
			slot.Quantity = slot.Quantity + toAdd
			remaining = remaining - toAdd
			added = added + toAdd
			if remaining <= 0 then
				break
			end
		end
	end

	while remaining > 0 do
		local inserted = false
		for index = 1, TOTAL_SLOT_COUNT do
			local slot = inventory.Slots[index]
			if slot.ItemId == nil then
				slot.ItemId = itemId
				slot.Quantity = 0
				slot.WaterCharges = itemId == "Flask" and FlaskConfig.INITIAL_WATER_CHARGES or nil
			end

			if slot.ItemId == itemId and slot.Quantity < definition.MaxStack then
				local space = definition.MaxStack - slot.Quantity
				local toAdd = math.min(remaining, space)
				slot.Quantity = slot.Quantity + toAdd
				remaining = remaining - toAdd
				added = added + toAdd
				inserted = true
				if remaining <= 0 then
					break
				end
			end
		end

		if not inserted then
			break
		end
	end

	self:_syncPlayer(player, added > 0 and {
		ItemId = itemId,
		Quantity = added,
	} or nil)
	return {Added = added, Remaining = remaining, Reason = remaining > 0 and "InventoryFull" or "Ok"}
end

function InventoryService:RemoveItem(player, itemId, quantity)
	assert(typeof(player) == "Instance", "Player expected")
	assert(typeof(itemId) == "string", "ItemId must be a string")
	assert(typeof(quantity) == "number", "Quantity must be a number")

	if quantity <= 0 then
		return {Removed = 0, Remaining = 0, Reason = "InvalidQuantity"}
	end

	local inventory = self.PlayerInventories[player]
	if not inventory then
		return {Removed = 0, Remaining = quantity, Reason = "MissingInventory"}
	end

	local remaining = quantity
	local removed = 0

	for index = 1, TOTAL_SLOT_COUNT do
		local slot = inventory.Slots[index]
		if slot.ItemId == itemId then
			local take = math.min(slot.Quantity, remaining)
			slot.Quantity = slot.Quantity - take
			remaining = remaining - take
			removed = removed + take
			if slot.Quantity <= 0 then
				clearSlot(slot)
			end
			if remaining <= 0 then
				break
			end
		end
	end

	self:_syncPlayer(player)
	return {Removed = removed, Remaining = remaining, Reason = remaining > 0 and "MissingQuantity" or "Ok"}
end

function InventoryService:HasItem(player, itemId, quantity)
	local inventory = self.PlayerInventories[player]
	if not inventory then
		return false
	end

	local total = 0
	for index = 1, TOTAL_SLOT_COUNT do
		local slot = inventory.Slots[index]
		if slot.ItemId == itemId then total = total + slot.Quantity end
	end
	return total >= quantity
end

function InventoryService:GetInventory(player)
	return self.PlayerInventories[player]
end

function InventoryService:ExportInventory(player)
	local inventory = self.PlayerInventories[player]
	if not inventory then return nil end
	local slots = {}
	for index = 1, TOTAL_SLOT_COUNT do
		local slot = inventory.Slots[index]
		slots[index] = {ItemId = slot.ItemId, Quantity = slot.Quantity, WaterCharges = slot.WaterCharges}
	end
	return {Slots = slots, ActiveQuickSlot = inventory.ActiveQuickSlot, InventoryVersion = inventory.InventoryVersion}
end

function InventoryService:RestoreInventory(player, saved)
	if typeof(saved) ~= "table" or typeof(saved.Slots) ~= "table" then return false end
	local restored = self:_createEmptyInventory()
	for index = 1, TOTAL_SLOT_COUNT do
		local source = saved.Slots[index]
		if typeof(source) == "table" and source.ItemId ~= nil then
			local definition = ItemDefinitions[source.ItemId]
			if not definition or typeof(source.Quantity) ~= "number" or source.Quantity ~= math.floor(source.Quantity)
				or source.Quantity < 1 or source.Quantity > definition.MaxStack
			then
				return false
			end
			restored.Slots[index] = {ItemId = source.ItemId, Quantity = source.Quantity, WaterCharges = source.WaterCharges}
		end
	end
	restored.ActiveQuickSlot = 0
	self.PlayerInventories[player] = restored
	self:_syncPlayer(player)
	return true
end

function InventoryService:TakeFromSlot(player, slotIndex, quantity)
	local inventory = self.PlayerInventories[player]
	if not inventory
		or typeof(slotIndex) ~= "number"
		or slotIndex ~= math.floor(slotIndex)
		or slotIndex < 1
		or slotIndex > TOTAL_SLOT_COUNT
		or typeof(quantity) ~= "number"
		or quantity <= 0
	then
		return nil, 0
	end
	local slot = inventory.Slots[slotIndex]
	if not slot or not slot.ItemId or slot.Quantity < quantity then
		return nil, 0
	end
	local itemId = slot.ItemId
	slot.Quantity = slot.Quantity - quantity
	if slot.Quantity <= 0 then clearSlot(slot) end
	if inventory.ActiveQuickSlot > 0 and slotIndex == INVENTORY_SIZE + inventory.ActiveQuickSlot and not slot.ItemId then
		inventory.ActiveQuickSlot = 0
	end
	self:_applyActiveTool(player, inventory)
	self:_syncPlayer(player)
	return itemId, quantity
end

function InventoryService:GetItemQuantity(player, itemId)
	local inventory = self.PlayerInventories[player]
	if not inventory then
		return 0
	end

	local total = 0
	for index = 1, TOTAL_SLOT_COUNT do
		local slot = inventory.Slots[index]
		if slot.ItemId == itemId then total = total + slot.Quantity end
	end
	return total
end

function InventoryService:TryCraft(player, ingredients, resultItemId, resultAmount)
	local inventory = self.PlayerInventories[player]
	local resultDefinition = ItemDefinitions[resultItemId]
	if not inventory or typeof(ingredients) ~= "table" or not resultDefinition then
		return false, "InvalidCraft"
	end
	if typeof(resultAmount) ~= "number" or resultAmount <= 0 or resultAmount ~= math.floor(resultAmount) then
		return false, "InvalidResultAmount"
	end

	local workingSlots = {}
	for index, slot in ipairs(inventory.Slots) do
		workingSlots[index] = cloneSlot(slot)
	end

	for itemId, requiredAmount in ingredients do
		if not ItemDefinitions[itemId]
			or typeof(requiredAmount) ~= "number"
			or requiredAmount <= 0
			or requiredAmount ~= math.floor(requiredAmount)
		then
			return false, "InvalidIngredients"
		end

		local remaining = requiredAmount
		for index = 1, TOTAL_SLOT_COUNT do
			local slot = workingSlots[index]
			if slot.ItemId == itemId then
				local removed = math.min(slot.Quantity, remaining)
				slot.Quantity = slot.Quantity - removed
				remaining = remaining - removed
				if slot.Quantity <= 0 then
					clearSlot(slot)
				end
				if remaining <= 0 then
					break
				end
			end
		end
		if remaining > 0 then
			return false, "MissingIngredients"
		end
	end

	local remainingResult = resultAmount
	for index = 1, TOTAL_SLOT_COUNT do
		local slot = workingSlots[index]
		if slot.ItemId == resultItemId and slot.Quantity < resultDefinition.MaxStack then
			local added = math.min(resultDefinition.MaxStack - slot.Quantity, remainingResult)
			slot.Quantity = slot.Quantity + added
			remainingResult = remainingResult - added
			if remainingResult <= 0 then
				break
			end
		end
	end
	for index = 1, TOTAL_SLOT_COUNT do
		local slot = workingSlots[index]
		if remainingResult <= 0 then
			break
		end
		if slot.ItemId == nil then
			local added = math.min(resultDefinition.MaxStack, remainingResult)
			slot.ItemId = resultItemId
			slot.Quantity = added
			slot.WaterCharges = resultItemId == "Flask" and FlaskConfig.INITIAL_WATER_CHARGES or nil
			remainingResult = remainingResult - added
		end
	end
	if remainingResult > 0 then
		return false, "InventoryFull"
	end

	inventory.Slots = workingSlots
	if inventory.ActiveQuickSlot > 0 then
		local activeSlot = inventory.Slots[INVENTORY_SIZE + inventory.ActiveQuickSlot]
		if not activeSlot or not activeSlot.ItemId then
			inventory.ActiveQuickSlot = 0
		end
	end
	self:_applyActiveTool(player, inventory)
	self:_syncPlayer(player)
	return true, "Ok"
end

function InventoryService:ConsumeActivePlaceable(player, expectedItemId)
	local inventory = self.PlayerInventories[player]
	if not inventory or inventory.ActiveQuickSlot <= 0 then
		return false
	end

	local slot = inventory.Slots[INVENTORY_SIZE + inventory.ActiveQuickSlot]
	local definition = slot and slot.ItemId and ItemDefinitions[slot.ItemId]
	if not slot
		or slot.ItemId ~= expectedItemId
		or slot.Quantity <= 0
		or not definition
		or definition.Placeable ~= true
	then
		return false
	end

	slot.Quantity = slot.Quantity - 1
	if slot.Quantity <= 0 then
		clearSlot(slot)
		inventory.ActiveQuickSlot = 0
	end
	self:_applyActiveTool(player, inventory)
	self:_syncPlayer(player)
	return true
end

function InventoryService:ConsumePlaceableAnywhere(player, expectedItemId)
	local definition = ItemDefinitions[expectedItemId]
	local inventory = self.PlayerInventories[player]
	if not definition or definition.Placeable ~= true or not inventory then
		return false
	end
	local activeIndex = inventory.ActiveQuickSlot > 0 and INVENTORY_SIZE + inventory.ActiveQuickSlot or nil
	local selectedIndex
	if activeIndex then
		local activeSlot = inventory.Slots[activeIndex]
		if activeSlot and activeSlot.ItemId == expectedItemId and activeSlot.Quantity > 0 then selectedIndex = activeIndex end
	end
	if not selectedIndex then
		for index = 1, TOTAL_SLOT_COUNT do
			local slot = inventory.Slots[index]
			if slot.ItemId == expectedItemId and slot.Quantity > 0 then
				selectedIndex = index
				break
			end
		end
	end
	if not selectedIndex then
		return false
	end
	local slot = inventory.Slots[selectedIndex]
	slot.Quantity = slot.Quantity - 1
	if slot.Quantity <= 0 then
		clearSlot(slot)
		if selectedIndex == activeIndex then inventory.ActiveQuickSlot = 0 end
	end
	self:_applyActiveTool(player, inventory)
	self:_syncPlayer(player)
	return true
end

function InventoryService:CanAddItem(player, itemId, quantity)
	return self:GetAddCapacity(player, itemId) >= quantity
end

function InventoryService:GetAddCapacity(player, itemId)
	local definition = ItemDefinitions[itemId]
	if not definition then
		return 0
	end

	local inventory = self.PlayerInventories[player]
	if not inventory then
		return 0
	end

	local freeSlots = 0
	local totalCapacity = 0
	for index = 1, TOTAL_SLOT_COUNT do
		local slot = inventory.Slots[index]
		if slot.ItemId == nil then
			freeSlots = freeSlots + 1
		elseif slot.ItemId == itemId and slot.Quantity < definition.MaxStack then
			totalCapacity = totalCapacity + (definition.MaxStack - slot.Quantity)
		end
	end

	return totalCapacity + (freeSlots * definition.MaxStack)
end

function InventoryService:_handleMove(player, data)
	if typeof(data) ~= "table" then
		return
	end

	local fromIndex = data.fromIndex
	local toIndex = data.toIndex
	if typeof(fromIndex) ~= "number" or typeof(toIndex) ~= "number" then
		return
	end

	local inventory = self.PlayerInventories[player]
	if not inventory then
		return
	end

	if fromIndex ~= math.floor(fromIndex) or toIndex ~= math.floor(toIndex) then
		return
	end

	if fromIndex < 1 or fromIndex > TOTAL_SLOT_COUNT or toIndex < 1 or toIndex > TOTAL_SLOT_COUNT then
		return
	end
	if fromIndex == toIndex then return end

	local fromSlot = inventory.Slots[fromIndex]
	local toSlot = inventory.Slots[toIndex]
	if not fromSlot or not toSlot then
		return
	end
	if not fromSlot.ItemId or not ItemDefinitions[fromSlot.ItemId] or fromSlot.Quantity <= 0 then
		return
	end
	if toSlot.ItemId == fromSlot.ItemId then
		local definition = ItemDefinitions[fromSlot.ItemId]
		local moved = math.min(fromSlot.Quantity, definition.MaxStack - toSlot.Quantity)
		if moved <= 0 then return end
		toSlot.Quantity = toSlot.Quantity + moved
		fromSlot.Quantity = fromSlot.Quantity - moved
		if fromSlot.Quantity <= 0 then clearSlot(fromSlot) end
	else
		inventory.Slots[fromIndex], inventory.Slots[toIndex] = toSlot, fromSlot
	end
	if inventory.ActiveQuickSlot > 0 then
		local active = inventory.Slots[INVENTORY_SIZE + inventory.ActiveQuickSlot]
		if not active or not active.ItemId then inventory.ActiveQuickSlot = 0 end
	end
	self:_applyActiveTool(player, inventory)
	self:_syncPlayer(player)
end

function InventoryService:_applyActiveTool(player, inventory)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	removeFishingRodVisual(character)

	if inventory.ActiveQuickSlot <= 0 then
		humanoid:UnequipTools()
		return
	end

	local slot = inventory.Slots[INVENTORY_SIZE + inventory.ActiveQuickSlot]
	local definition = slot and slot.ItemId and ItemDefinitions[slot.ItemId]
	if slot and slot.ItemId then
		print("[MAYDEAD] Selected item = " .. slot.ItemId)
	end
	if not definition or definition.IsTool ~= true or typeof(definition.ToolName) ~= "string" then
		humanoid:UnequipTools()
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	print("[MAYDEAD] Looking for Tool = " .. definition.ToolName)
	local tool
	if definition.ToolName == "Axe" then
		tool = findNormalizedTool(character, "Axe") or findNormalizedTool(backpack, "Axe")
	else
		tool = character:FindFirstChild(definition.ToolName)
			or (backpack and backpack:FindFirstChild(definition.ToolName))
	end
	if tool and not tool:IsA("Tool") then
		tool = nil
	end
	if tool and definition.ToolName == "Fishing_Rod" and tool:FindFirstChildWhichIsA("BasePart", true) then
		tool:Destroy()
		tool = nil
	end
	if tool and definition.ToolName == "Axe" then
		print("[MAYDEAD] Axe matched runtime name = " .. string.format("%q", tool.Name))
		if tool.Name ~= "Axe" then
			tool.Name = "Axe"
		end
	end

	if tool and tool.Parent == character then
		print("[MAYDEAD] " .. definition.ToolName .. " found in Character")
	elseif tool and tool.Parent == backpack then
		print("[MAYDEAD] " .. definition.ToolName .. " found in Backpack")
	end

	if not tool then
		local template
		if definition.ToolName == "Axe" then
			template = findAxeTemplate()
		elseif definition.ToolName == "Pickaxe" then
			template = StarterPack:FindFirstChild("Pickaxe")
		elseif definition.ToolName == "Fishing_Rod" then
			template = cloneImportedTool("Fishing_Rod")
		end
		if template and template:IsA("Tool") and backpack then
			if definition.ToolName == "Axe" then
				print("[MAYDEAD] Axe template found")
			else
				print("[MAYDEAD] " .. definition.ToolName .. " template found in StarterPack")
			end
			tool = definition.ToolName == "Fishing_Rod" and template or template:Clone()
			if definition.ToolName == "Axe" then
				tool.Name = "Axe"
			end
			tool.Parent = backpack
			print("[MAYDEAD] " .. definition.ToolName .. " cloned to Backpack")
		elseif template then
			warn("[MAYDEAD] StarterPack." .. definition.ToolName .. " exists but class = " .. template.ClassName)
			return
		else
			warn("[MAYDEAD] Tool equip failed: " .. definition.ToolName .. " no official source found")
			return
		end
	end

	humanoid:UnequipTools()
	if tool.Parent == character then
		tool = backpack and backpack:FindFirstChild(definition.ToolName) or tool
	end
	print("[MAYDEAD] Equipping Tool = " .. definition.ToolName)
	if definition.ToolName == "Fishing_Rod" then
		logFishingRootVelocity(character, "before Humanoid:EquipTool")
	end
	humanoid:EquipTool(tool)
	if definition.ToolName == "Fishing_Rod" then
		logFishingRootVelocity(character, "after Humanoid:EquipTool")
	end
	if tool.Parent == character then
		print("[MAYDEAD] Tool equipped = " .. definition.ToolName)
		if definition.ToolName == "Fishing_Rod" then
			createFishingRodVisual(character, tool)
		end
	else
		warn("[MAYDEAD] Tool equip failed: " .. definition.ToolName .. " Humanoid:EquipTool did not parent it to Character")
	end
end

function InventoryService:GetActiveItem(player)
	local inventory = self.PlayerInventories[player]
	if not inventory or inventory.ActiveQuickSlot <= 0 then
		return nil
	end
	local slot = inventory.Slots[INVENTORY_SIZE + inventory.ActiveQuickSlot]
	return slot and slot.ItemId or nil
end

function InventoryService:DeselectActiveItem(player, expectedItemId)
	local inventory = self.PlayerInventories[player]
	if not inventory or inventory.ActiveQuickSlot <= 0 then
		return
	end
	local slot = inventory.Slots[INVENTORY_SIZE + inventory.ActiveQuickSlot]
	if slot and slot.ItemId == expectedItemId then
		inventory.ActiveQuickSlot = 0
		self:_applyActiveTool(player, inventory)
		self:_syncPlayer(player)
	end
end

function InventoryService:_getActiveFlaskSlot(player)
	local inventory = self.PlayerInventories[player]
	if not inventory or inventory.ActiveQuickSlot <= 0 then
		return nil
	end
	local slot = inventory.Slots[INVENTORY_SIZE + inventory.ActiveQuickSlot]
	if not slot or slot.ItemId ~= "Flask" or slot.Quantity ~= 1 then
		return nil
	end
	if typeof(slot.WaterCharges) ~= "number" then
		slot.WaterCharges = FlaskConfig.INITIAL_WATER_CHARGES
	end
	slot.WaterCharges = math.clamp(math.floor(slot.WaterCharges), 0, FlaskConfig.MAX_WATER_CHARGES)
	return slot
end

function InventoryService:_handleFlaskRequest(player, action)
	if action ~= "Fill" and action ~= "Use" then
		return
	end
	local now = os.clock()
	if now - (self._lastFlaskAttempts[player] or 0) < 0.2 then
		return
	end
	self._lastFlaskAttempts[player] = now

	local slot = self:_getActiveFlaskSlot(player)
	if not slot then
		return
	end
	if action == "Fill" then
		if slot.WaterCharges >= FlaskConfig.MAX_WATER_CHARGES then
			self._flaskResult:FireClient(player, "Fill", false, "Full")
			return
		end
		if not SurvivalService:CanInteractWithTerrainWater(player) then
			return
		end
		slot.WaterCharges = FlaskConfig.MAX_WATER_CHARGES
		self:_syncPlayer(player)
		self._flaskResult:FireClient(player, "Fill", true, "Filled")
		return
	end

	if slot.WaterCharges <= 0 then
		self._flaskResult:FireClient(player, "Use", false, "Empty")
		return
	end
	if not SurvivalService:HydrateFromFlask(player) then
		self._flaskResult:FireClient(player, "Use", false, "ThirstFull")
		return
	end
	slot.WaterCharges = slot.WaterCharges - 1
	self:_syncPlayer(player)
	self._flaskResult:FireClient(player, "Use", true, "Hydrated")
end

function InventoryService:_handleSelectQuickSlot(player, data)
	if typeof(data) ~= "table" then
		return
	end

	local quickSlotIndex = data.quickSlotIndex
	if typeof(quickSlotIndex) ~= "number" or quickSlotIndex ~= math.floor(quickSlotIndex) then
		return
	end
	if quickSlotIndex < 1 or quickSlotIndex > QUICK_SLOT_COUNT then
		return
	end

	local inventory = self.PlayerInventories[player]
	if not inventory then
		return
	end
	local slot = inventory.Slots[INVENTORY_SIZE + quickSlotIndex]
	if inventory.ActiveQuickSlot == quickSlotIndex or not slot or not slot.ItemId then
		self:ClearSelectedItem(player)
		return
	end
	inventory.ActiveQuickSlot = quickSlotIndex
	self:_applyActiveTool(player, inventory)
	self:_syncPlayer(player)
end

function InventoryService:ClearSelectedItem(player)
	local inventory = self.PlayerInventories[player]
	if not inventory then
		return
	end
	inventory.ActiveQuickSlot = 0
	self:_applyActiveTool(player, inventory)
	self:_syncPlayer(player)
end

function InventoryService:_handleUse(player, data)
	if typeof(data) ~= "table" then
		return
	end

	local slotIndex = data.slotIndex
	if typeof(slotIndex) ~= "number" or slotIndex ~= math.floor(slotIndex) then
		return
	end

	local inventory = self.PlayerInventories[player]
	if not inventory or slotIndex < 1 or slotIndex > TOTAL_SLOT_COUNT then
		return
	end

	local slot = inventory.Slots[slotIndex]
	if not slot or not slot.ItemId then
		return
	end
	local expectedSlotIndex = INVENTORY_SIZE + inventory.ActiveQuickSlot
	if inventory.ActiveQuickSlot <= 0 or slotIndex ~= expectedSlotIndex then
		return
	end

	local definition = ItemDefinitions[slot.ItemId]
	if not definition
		or definition.Category ~= "Food"
		or definition.Consumable ~= true
		or typeof(definition.HungerRestore) ~= "number"
		or definition.HungerRestore <= 0
		or slot.Quantity <= 0
	then
		return
	end

	local restored = SurvivalService:ConsumeFood(
		player,
		definition.HungerRestore,
		definition.EnergyRestore or 0,
		definition.HealthDelta or 0
	)
	if restored <= 0 then
		return
	end

	slot.Quantity = slot.Quantity - 1
	if slot.Quantity <= 0 then
		clearSlot(slot)
		inventory.ActiveQuickSlot = 0
	end
	self:_applyActiveTool(player, inventory)

	self:_syncPlayer(player)
	self._foodConsumed:FireClient(player, restored)
end

return InventoryService.new()
