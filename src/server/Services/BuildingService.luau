local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local BuildingSnapGeometry = require(SharedFolder:WaitForChild("BuildingSnapGeometry"))
local BuildingConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("BuildingConfig"))
local ItemDefinitions = require(SharedFolder:WaitForChild("Definitions"):WaitForChild("ItemDefinitions"))
local PlaceableDefinitions = require(SharedFolder:WaitForChild("Definitions"):WaitForChild("PlaceableDefinitions"))
local DoorService = require(script.Parent:WaitForChild("DoorService"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local StationService = require(script.Parent:WaitForChild("StationService"))
local CropService = require(script.Parent:WaitForChild("CropService"))
local CampService = require(script.Parent:WaitForChild("CampService"))
local FactoryService = require(script.Parent:WaitForChild("FactoryService"))
local BoatService = require(script.Parent:WaitForChild("BoatService"))
local PersistenceConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("PersistenceConfig"))

local BuildingService = {}
BuildingService.__index = BuildingService

local WORKBENCH_TAG = "MAYDEAD_CraftingTable"
local GROUND_SEARCH_HEIGHT = 6
local SUPPORT_RAY_HEIGHT = 2
local SUPPORT_RAY_DEPTH = 4
local CONSTRUCTION_ITEMS = {
	Wall = true,
	WindowWall = true,
	DoorWall = true,
	HalfWall = true,
	Ceiling = true,
	Stairs = true,
	Fireplace = true,
	Window = true,
	Door = true,
	QuarterCircleCeiling = true,
	QuarterCircleWall = true,
}
local FLOOR_SIDES = {
	{Name = "North", Opposite = "South", Direction = Vector3.new(0, 0, -1), Yaw = 0},
	{Name = "South", Opposite = "North", Direction = Vector3.new(0, 0, 1), Yaw = math.pi},
	{Name = "East", Opposite = "West", Direction = Vector3.new(1, 0, 0), Yaw = -math.pi / 2},
	{Name = "West", Opposite = "East", Direction = Vector3.new(-1, 0, 0), Yaw = math.pi / 2},
}
local FLOOR_SIDE_BY_NAME = {}
for _, side in FLOOR_SIDES do
	FLOOR_SIDE_BY_NAME[side.Name] = side
end
local CURVED_FLOOR_EDGE_BY_NAME = {
	StraightEdgeA = PlaceableDefinitions.QuarterCircleCeiling.StraightEdgeA,
	StraightEdgeB = PlaceableDefinitions.QuarterCircleCeiling.StraightEdgeB,
}
local STRUCTURES_VERSION = 2
local MAX_PIVOT_COMPONENT_ABS = 10000000
local MAX_ROTATION_COMPONENT_ABS = 2
local PERSISTED_ATTRIBUTES = {
	"ParentStructureId",
	"SnapSide",
	"ParentOccupancyAttribute",
	"StructureLevel",
	"StructureRootId",
	"GridX",
	"GridZ",
	"SupportDirect",
	"SupportDistance",
	"NorthWallOccupied",
	"SouthWallOccupied",
	"EastWallOccupied",
	"WestWallOccupied",
	"NorthFloorOccupied",
	"SouthFloorOccupied",
	"EastFloorOccupied",
	"WestFloorOccupied",
	"NorthStairsOccupied",
	"SouthStairsOccupied",
	"EastStairsOccupied",
	"WestStairsOccupied",
	"UpperFloorOccupied",
	"StraightEdgeAOccupied",
	"StraightEdgeBOccupied",
	"CurvedEdgeOccupied",
}

local function isFloorItemId(itemId)
	return itemId == "Ceiling" or itemId == "QuarterCircleCeiling"
end

local function isFloorStructureType(structureType)
	return structureType == "Ceiling" or structureType == "QuarterCircleCeiling"
end

local function getModelDistance(rootPart, model)
	local shortestDistance = math.huge
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			shortestDistance = math.min(
				shortestDistance,
				(descendant:GetClosestPointOnSurface(rootPart.Position) - rootPart.Position).Magnitude
			)
		end
	end
	return shortestDistance
end

local function isFiniteNumber(value)
	return value == value and value > -math.huge and value < math.huge
end

local function isDenseArray(value, expectedLength)
	if typeof(value) ~= "table" or #value ~= expectedLength then
		return false
	end
	local count = 0
	for key in value do
		if typeof(key) ~= "number" or key ~= math.floor(key) or key < 1 or key > expectedLength then
			return false
		end
		count = count + 1
	end
	return count == expectedLength
end

local function serializeCFrame(value)
	if typeof(value) ~= "CFrame" then
		return nil
	end
	local components = {value:GetComponents()}
	for index, component in ipairs(components) do
		local limit = index <= 3 and MAX_PIVOT_COMPONENT_ABS or MAX_ROTATION_COMPONENT_ABS
		if not isFiniteNumber(component) or math.abs(component) > limit then
			return nil
		end
	end
	return components
end

local function deserializeCFrame(value)
	if not isDenseArray(value, 12) then
		return nil
	end
	for index = 1, 12 do
		local component = value[index]
		local limit = index <= 3 and MAX_PIVOT_COMPONENT_ABS or MAX_ROTATION_COMPONENT_ABS
		if typeof(component) ~= "number" or not isFiniteNumber(component) or math.abs(component) > limit then
			return nil
		end
	end
	return CFrame.new(table.unpack(value, 1, 12))
end

local function isValidStructureId(value)
	return typeof(value) == "string" and #value >= 8 and #value <= 128
end

local function isPersistableAttribute(value)
	local valueType = typeof(value)
	return valueType == "string" or valueType == "number" or valueType == "boolean"
end

local function isFiniteCFrame(value)
	if typeof(value) ~= "CFrame" then
		return false
	end
	local position = value.Position
	return isFiniteNumber(position.X) and isFiniteNumber(position.Y) and isFiniteNumber(position.Z)
end

local function isSolidGround(result)
	if not result or result.Material == Enum.Material.Water then
		return false
	end
	return result.Instance == workspace.Terrain
		or (result.Instance:IsA("BasePart") and result.Instance.CanCollide)
end

local function isWaterSurface(result)
	return result ~= nil and result.Instance == workspace.Terrain and result.Material == Enum.Material.Water
end

local function isHarvestResource(instance)
	local resources = workspace:FindFirstChild("Resources")
	return resources ~= nil and instance:IsDescendantOf(resources)
end

local function getYaw(cframe)
	local look = cframe.LookVector
	return math.atan2(-look.X, -look.Z)
end

local function computeAxisAlignedBox(model)
	local minPoint = Vector3.new(math.huge, math.huge, math.huge)
	local maxPoint = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local half = descendant.Size / 2
			for _, corner in {
				Vector3.new(-half.X, -half.Y, -half.Z),
				Vector3.new(-half.X, -half.Y, half.Z),
				Vector3.new(-half.X, half.Y, -half.Z),
				Vector3.new(-half.X, half.Y, half.Z),
				Vector3.new(half.X, -half.Y, -half.Z),
				Vector3.new(half.X, -half.Y, half.Z),
				Vector3.new(half.X, half.Y, -half.Z),
				Vector3.new(half.X, half.Y, half.Z),
			} do
				local point = descendant.CFrame:PointToWorldSpace(corner)
				minPoint = Vector3.new(math.min(minPoint.X, point.X), math.min(minPoint.Y, point.Y), math.min(minPoint.Z, point.Z))
				maxPoint = Vector3.new(math.max(maxPoint.X, point.X), math.max(maxPoint.Y, point.Y), math.max(maxPoint.Z, point.Z))
			end
		end
	end
	local size = maxPoint - minPoint
	return CFrame.new((minPoint + maxPoint) / 2), size
end

local function getPlacementBox(model)
	local size = model:GetAttribute("PlacementBoxSize")
	local boxToPivot = model:GetAttribute("PlacementBoxToPivot")
	if typeof(size) == "Vector3" and typeof(boxToPivot) == "CFrame" then
		return model:GetPivot() * boxToPivot:Inverse(), size
	end
	return model:GetBoundingBox()
end

local function getPlacementGeometry(model, groundCFrame)
	local pivot = model:GetPivot()
	local boxCFrame, boxSize = getPlacementBox(model)
	local boxToPivot = boxCFrame:ToObjectSpace(pivot)
	local targetBoxCFrame = groundCFrame * CFrame.new(0, boxSize.Y / 2, 0)
	return targetBoxCFrame * boxToPivot, targetBoxCFrame, boxSize
end

local function getPivotForBox(model, targetBoxCFrame)
	local pivot = model:GetPivot()
	local boxCFrame = getPlacementBox(model)
	return targetBoxCFrame * boxCFrame:ToObjectSpace(pivot)
end

local function orientHorizontalSurface(model)
	local _, beforeSize = computeAxisAlignedBox(model)
	local originalPivot = model:GetPivot()
	local candidates = {
		{Axis = "Y", Degrees = 0, Offset = CFrame.identity},
		{Axis = "X", Degrees = -90, Offset = CFrame.Angles(math.rad(-90), 0, 0)},
		{Axis = "X", Degrees = 90, Offset = CFrame.Angles(math.rad(90), 0, 0)},
		{Axis = "Z", Degrees = 90, Offset = CFrame.Angles(0, 0, math.rad(90))},
		{Axis = "Z", Degrees = -90, Offset = CFrame.Angles(0, 0, math.rad(-90))},
	}
	local selected = candidates[1]
	local selectedSize = beforeSize
	for _, candidate in candidates do
		model:PivotTo(originalPivot * candidate.Offset)
		local _, candidateSize = computeAxisAlignedBox(model)
		if candidateSize.Y < selectedSize.Y - 0.001 then
			selected = candidate
			selectedSize = candidateSize
		end
	end
	local offset = selected.Offset
	local axis = selected.Axis
	local angleDegrees = selected.Degrees
	model:PivotTo(originalPivot * offset)
	local afterBox, afterSize = computeAxisAlignedBox(model)
	local boxToPivot = afterBox:ToObjectSpace(model:GetPivot())
	model:SetAttribute("OrientationOffset", offset)
	model:SetAttribute("OrientationOffsetAxis", axis)
	model:SetAttribute("OrientationOffsetDegrees", angleDegrees)
	model:SetAttribute("PlacementBoxSize", afterSize)
	model:SetAttribute("PlacementBoxToPivot", boxToPivot)
	return offset, axis, angleDegrees, beforeSize, afterSize
end

local function orientVerticalStructure(model)
	local function getTopMarkerHeight()
		local markerHeight = -math.huge
		for _, descendant in model:GetDescendants() do
			local loweredName = string.lower(descendant.Name)
			if string.find(loweredName, "smoke", 1, true) or string.find(loweredName, "chimney", 1, true) then
				local marker = descendant:IsA("Attachment") and descendant
					or descendant:IsA("BasePart") and descendant
					or descendant.Parent
				local position = marker and marker:IsA("Attachment") and marker.WorldPosition
					or marker and marker:IsA("BasePart") and marker.Position
				if position then markerHeight = math.max(markerHeight, position.Y) end
			end
		end
		return markerHeight
	end
	local _, beforeSize = computeAxisAlignedBox(model)
	local originalPivot = model:GetPivot()
	local candidates = {
		{Axis = "Y", Degrees = 0, Offset = CFrame.identity},
		{Axis = "X", Degrees = -90, Offset = CFrame.Angles(math.rad(-90), 0, 0)},
		{Axis = "X", Degrees = 90, Offset = CFrame.Angles(math.rad(90), 0, 0)},
		{Axis = "Z", Degrees = 90, Offset = CFrame.Angles(0, 0, math.rad(90))},
		{Axis = "Z", Degrees = -90, Offset = CFrame.Angles(0, 0, math.rad(-90))},
	}
	local selected = candidates[1]
	local selectedSize = beforeSize
	local selectedMarkerHeight = getTopMarkerHeight()
	for _, candidate in candidates do
		model:PivotTo(originalPivot * candidate.Offset)
		local _, candidateSize = computeAxisAlignedBox(model)
		local markerHeight = getTopMarkerHeight()
		if candidateSize.Y > selectedSize.Y + 0.001
			or (math.abs(candidateSize.Y - selectedSize.Y) <= 0.001 and markerHeight > selectedMarkerHeight + 0.001)
		then
			selected = candidate
			selectedSize = candidateSize
			selectedMarkerHeight = markerHeight
		end
	end
	model:PivotTo(originalPivot * selected.Offset)
	local afterBox, afterSize = computeAxisAlignedBox(model)
	model:SetAttribute("OrientationOffset", selected.Offset)
	model:SetAttribute("OrientationOffsetAxis", selected.Axis)
	model:SetAttribute("OrientationOffsetDegrees", selected.Degrees)
	model:SetAttribute("PlacementBoxSize", afterSize)
	model:SetAttribute("PlacementBoxToPivot", afterBox:ToObjectSpace(model:GetPivot()))
	return selected.Offset, selected.Axis, selected.Degrees, beforeSize, afterSize
end

local function getStructureModel(instance)
	local current = instance
	while current and current ~= workspace do
		if current:IsA("Model") and current:GetAttribute("StructureType") then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function isPlayerCharacterPart(instance)
	local model = instance:FindFirstAncestorOfClass("Model")
	return model ~= nil and Players:GetPlayerFromCharacter(model) ~= nil
end

local function isWallStructureType(structureType)
	return structureType == "Wall"
		or structureType == "DoorWall"
		or structureType == "WindowWall"
		or structureType == "HalfWall"
end

local function getSnapDistance(targetPosition, requestedPosition, placementType)
	if placementType == "Wall" or placementType == "Floor" then
		local delta = targetPosition - requestedPosition
		return Vector2.new(delta.X, delta.Z).Magnitude
	end
	return (targetPosition - requestedPosition).Magnitude
end

local function hasAttachedWall(placedFolder, support)
	local structureId = support:GetAttribute("StructureId")
	if not structureId then
		return false
	end
	for _, candidate in placedFolder:GetDescendants() do
		if candidate:IsA("Model")
			and candidate:GetAttribute("ParentStructureId") == structureId
			and (candidate:GetAttribute("StructureType") == "Wall"
				or candidate:GetAttribute("StructureType") == "WindowWall"
				or candidate:GetAttribute("StructureType") == "DoorWall"
				or candidate:GetAttribute("StructureType") == "QuarterCircleWall")
		then
			return true
		end
	end
	return false
end

local function hasAttachedStructureType(placedFolder, support, structureType)
	local structureId = support:GetAttribute("StructureId")
	if typeof(structureId) ~= "string" then
		return false
	end
	for _, candidate in placedFolder:GetDescendants() do
		if candidate:IsA("Model")
			and candidate:GetAttribute("ParentStructureId") == structureId
			and candidate:GetAttribute("StructureType") == structureType
		then
			return true
		end
	end
	return false
end

function BuildingService:_getCeilings()
	local ceilings = {}
	local placedFolder = workspace:FindFirstChild("PlacedStructures")
	if not placedFolder then
		return ceilings
	end
	for _, candidate in placedFolder:GetDescendants() do
		if candidate:IsA("Model") and isFloorStructureType(candidate:GetAttribute("StructureType")) then
			table.insert(ceilings, candidate)
		end
	end
	return ceilings
end

function BuildingService:_hasDirectStructuralSupport(ceiling, ceilings)
	local level = ceiling:GetAttribute("StructureLevel") or 0
	if level <= 0 then
		return true
	end
	local rootId = ceiling:GetAttribute("StructureRootId")
	local gridX = ceiling:GetAttribute("GridX")
	local gridZ = ceiling:GetAttribute("GridZ")
	for _, lower in ceilings do
		if lower:GetAttribute("StructureRootId") == rootId
			and lower:GetAttribute("StructureLevel") == level - 1
			and lower:GetAttribute("GridX") == gridX
			and lower:GetAttribute("GridZ") == gridZ
			and hasAttachedWall(workspace.PlacedStructures, lower)
		then
			return true
		end
	end
	return false
end

function BuildingService:_refreshCeilingSupportMetadata()
	local ceilings = self:_getCeilings()
	for _, ceiling in ceilings do
		ceiling:SetAttribute("SupportDirect", self:_hasDirectStructuralSupport(ceiling, ceilings))
	end
	for _, ceiling in ceilings do
		if ceiling:GetAttribute("SupportDirect") then
			ceiling:SetAttribute("SupportDistance", 0)
			continue
		end
		local distance = BuildingConfig.MAX_CANTILEVER_MODULES + 1
		for _, neighbor in ceilings do
			if neighbor:GetAttribute("SupportDirect")
				and neighbor:GetAttribute("StructureRootId") == ceiling:GetAttribute("StructureRootId")
				and neighbor:GetAttribute("StructureLevel") == ceiling:GetAttribute("StructureLevel")
			then
				local gridDistance = math.abs((neighbor:GetAttribute("GridX") or 0) - (ceiling:GetAttribute("GridX") or 0))
					+ math.abs((neighbor:GetAttribute("GridZ") or 0) - (ceiling:GetAttribute("GridZ") or 0))
				if gridDistance == 1 then
					distance = 1
					break
				end
			end
		end
		ceiling:SetAttribute("SupportDistance", distance)
	end
end

function BuildingService:_getCandidateSupport(snap)
	if snap.Mode == "Ground" or snap.SourceMode == "WallTop" then
		return true, 0
	end
	if snap.Mode == "Upper" then
		return snap.HasStructuralSupport == true, snap.HasStructuralSupport and 0 or 2
	end
	if snap.Mode ~= "Horizontal" then
		return true, 0
	end
	local support = snap.Support
	local side = FLOOR_SIDE_BY_NAME[snap.Side]
	local gridDirection = snap.GridDirection or (side and side.Direction)
	if not gridDirection then
		return false, BuildingConfig.MAX_CANTILEVER_MODULES + 1
	end
	local rootId = support:GetAttribute("StructureRootId")
	local level = support:GetAttribute("StructureLevel") or 0
	local gridX = (support:GetAttribute("GridX") or 0) + gridDirection.X
	local gridZ = (support:GetAttribute("GridZ") or 0) + gridDirection.Z
	if level <= 0 then
		return true, 0
	end
	local ceilings = self:_getCeilings()
	for _, lower in ceilings do
		if lower:GetAttribute("StructureRootId") == rootId
			and lower:GetAttribute("StructureLevel") == level - 1
			and lower:GetAttribute("GridX") == gridX
			and lower:GetAttribute("GridZ") == gridZ
			and hasAttachedWall(workspace.PlacedStructures, lower)
		then
			return true, 0
		end
	end
	for _, ceiling in ceilings do
		if ceiling:GetAttribute("SupportDirect")
			and ceiling:GetAttribute("StructureRootId") == rootId
			and ceiling:GetAttribute("StructureLevel") == level
		then
			local distance = math.abs((ceiling:GetAttribute("GridX") or 0) - gridX)
				+ math.abs((ceiling:GetAttribute("GridZ") or 0) - gridZ)
			if distance == 1 then
				return false, 1
			end
		end
	end
	return false, BuildingConfig.MAX_CANTILEVER_MODULES + 1
end

local function preparePlacedModel(model, preserveVehicle)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			if not preserveVehicle then descendant:Destroy() end
		elseif descendant:IsA("BasePart") then
			if not preserveVehicle then descendant.Anchored = true end
		end
	end
end

local function preparePreviewTemplate(model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		elseif descendant:IsA("ParticleEmitter")
			or descendant:IsA("Fire")
			or descendant:IsA("Smoke")
			or descendant:IsA("PointLight")
			or descendant:IsA("SpotLight")
			or descendant:IsA("SurfaceLight")
			or descendant:IsA("Sound")
		then
			if descendant:IsA("Sound") then
				descendant.Playing = false
			else
				descendant.Enabled = false
			end
		end
	end
end

function BuildingService.new()
	local self = setmetatable({}, BuildingService)
	self._lastRequests = {}
	self._templates = {}
	self._moduleDimensions = nil
	self._dismantleHits = setmetatable({}, {__mode = "k"})
	self._lastDismantleRequests = {}
	self._activePlacementItems = {}
	self._request = Instance.new("RemoteEvent")
	self._request.Name = "PlacementRequest"
	self._request.Parent = ReplicatedStorage
	self._result = Instance.new("RemoteEvent")
	self._result.Name = "PlacementResult"
	self._result.Parent = ReplicatedStorage
	self._dismantleRequest = Instance.new("RemoteEvent")
	self._dismantleRequest.Name = "DismantleRequest"
	self._dismantleRequest.Parent = ReplicatedStorage
	self._dismantleResult = Instance.new("RemoteEvent")
	self._dismantleResult.Name = "DismantleResult"
	self._dismantleResult.Parent = ReplicatedStorage
	self._openWorkbench = nil
	return self
end

local function logQuarterCircleCeilingSource(template)
	print("[MAYDEAD] QuarterCircleCeiling ItemId = QuarterCircleCeiling")
	print("[MAYDEAD] QuarterCircleCeiling TemplateName = Quarter Circle Ceiling 2")
	print("[MAYDEAD] QuarterCircleCeiling source exists = " .. tostring(template ~= nil))
	print("[MAYDEAD] QuarterCircleCeiling source name = " .. (template and template.Name or "NONE"))
	print("[MAYDEAD] QuarterCircleCeiling source class = " .. (template and template.ClassName or "NONE"))
	print("[MAYDEAD] QuarterCircleCeiling source full name = " .. (template and template:GetFullName() or "NONE"))
	if not template then
		return
	end

	local counts = {BasePart = 0, MeshPart = 0, UnionOperation = 0, Model = 0}
	local function count(instance)
		if instance:IsA("BasePart") then
			counts.BasePart = counts.BasePart + 1
		end
		if counts[instance.ClassName] ~= nil then
			counts[instance.ClassName] = counts[instance.ClassName] + 1
		end
	end
	count(template)
	print("[MAYDEAD] QuarterCircleCeiling source Archivable = " .. tostring(template.Archivable))
	for _, child in template:GetChildren() do
		print("[MAYDEAD] QuarterCircleCeiling child = " .. child.Name .. " (" .. child.ClassName .. ")")
	end
	for _, descendant in template:GetDescendants() do
		count(descendant)
		print("[MAYDEAD] QuarterCircleCeiling descendant = " .. descendant.Name .. " (" .. descendant.ClassName .. ")")
	end
	print("[MAYDEAD] QuarterCircleCeiling BaseParts = " .. counts.BasePart)
	print("[MAYDEAD] QuarterCircleCeiling MeshParts = " .. counts.MeshPart)
	print("[MAYDEAD] QuarterCircleCeiling UnionOperations = " .. counts.UnionOperation)
	print("[MAYDEAD] QuarterCircleCeiling Models = " .. counts.Model)
	print("[MAYDEAD] QuarterCircleCeiling PrimaryPart = "
		.. (template:IsA("Model") and (template.PrimaryPart and template.PrimaryPart.Name or "NONE") or "N/A"))
	if template:IsA("Model") then
		local pivotSucceeded, pivot = pcall(function()
			return template:GetPivot()
		end)
		local boxSucceeded, boxCFrame, boxSize = pcall(function()
			return template:GetBoundingBox()
		end)
		print("[MAYDEAD] QuarterCircleCeiling pivot = " .. (pivotSucceeded and tostring(pivot) or "UNREADABLE"))
		print("[MAYDEAD] QuarterCircleCeiling BoundingBox = "
			.. (boxSucceeded and (tostring(boxCFrame) .. " size=" .. tostring(boxSize)) or "UNREADABLE"))
	elseif template:IsA("BasePart") then
		print("[MAYDEAD] QuarterCircleCeiling pivot = " .. tostring(template.CFrame))
		print("[MAYDEAD] QuarterCircleCeiling BoundingBox = " .. tostring(template.CFrame) .. " size=" .. tostring(template.Size))
	end
end

function BuildingService:_resolvePlaceableTemplate(assetImports, itemId)
	local definition = PlaceableDefinitions[itemId]
	local templateContainer = definition and definition.TemplateFolder and assetImports:FindFirstChild(definition.TemplateFolder) or assetImports
	local template = definition and templateContainer and templateContainer:FindFirstChild(definition.TemplateName) or nil
	if not template and definition and not definition.TemplateFolder then
		template = assetImports:FindFirstChild(definition.TemplateName, true)
	end
	if template and definition.ExpectedTemplateClass and template.ClassName ~= definition.ExpectedTemplateClass then
		warn(string.format(
			"[MAYDEAD][BUILDING] Invalid template for %s: expected %s, got %s",
			itemId,
			definition.ExpectedTemplateClass,
			template.ClassName
		))
		return nil
	end
	if itemId == "Factory" and RunService:IsStudio() and template then
		print("[MAYDEAD][FACTORY] Template resolved = " .. template:GetFullName())
	end
	if itemId == "ConveyorStraight" then
		print("[MAYDEAD][FACTORY] ConveyorStraight template found = " .. tostring(template ~= nil))
		print("[MAYDEAD][FACTORY] ConveyorStraight template path = " .. (template and template:GetFullName() or "NONE"))
		print("[MAYDEAD][FACTORY] ConveyorStraight template class = " .. (template and template.ClassName or "NONE"))
	end
	if itemId == "QuarterCircleCeiling" then
		logQuarterCircleCeilingSource(template)
		if template then
			print("[MAYDEAD] QuarterCircleCeiling source found = " .. template.Name)
		end
	end
	if itemId == "Wall" then
		print("[MAYDEAD] " .. itemId .. " source exists = " .. tostring(template ~= nil))
		print("[MAYDEAD] " .. itemId .. " source class = " .. (template and template.ClassName or "NONE"))
		print("[MAYDEAD] " .. itemId .. " source full name = " .. (template and template:GetFullName() or "NONE"))
	end
	if CONSTRUCTION_ITEMS[itemId] then
		print("[MAYDEAD] " .. itemId .. " template found = " .. tostring(template ~= nil))
		print("[MAYDEAD] " .. itemId .. " template class = " .. (template and template.ClassName or "NONE"))
		print("[MAYDEAD] " .. itemId .. " template full name = " .. (template and template:GetFullName() or "NONE"))
		if template then
			for _, child in template:GetChildren() do
				print("[MAYDEAD] " .. itemId .. " child = " .. child.Name .. " (" .. child.ClassName .. ")")
			end
		end
	end
	if itemId == "Wall" and template then
		local basePartCount = 0
		local modelCount = template:IsA("Model") and 1 or 0
		local unionCount = template:IsA("UnionOperation") and 1 or 0
		print("[MAYDEAD] " .. itemId .. " source Archivable = " .. tostring(template.Archivable))
		for _, descendant in template:GetDescendants() do
			basePartCount = basePartCount + (descendant:IsA("BasePart") and 1 or 0)
			modelCount = modelCount + (descendant:IsA("Model") and 1 or 0)
			unionCount = unionCount + (descendant:IsA("UnionOperation") and 1 or 0)
			print(
				"[MAYDEAD] "
					.. itemId
					.. " descendant = "
					.. descendant.Name
					.. " ("
					.. descendant.ClassName
					.. ") Archivable="
					.. tostring(descendant.Archivable)
			)
		end
		print(string.format(
			"[MAYDEAD] %s structure summary: BaseParts=%d Models=%d UnionOperations=%d PrimaryPart=%s",
			itemId,
			basePartCount + (template:IsA("BasePart") and 1 or 0),
			modelCount,
			unionCount,
			template:IsA("Model") and (template.PrimaryPart and template.PrimaryPart.Name or "NONE") or "N/A"
		))
		if template:IsA("Model") then
			local pivotSucceeded, pivot = pcall(function()
				return template:GetPivot()
			end)
			print("[MAYDEAD] " .. itemId .. " pivot readable = " .. tostring(pivotSucceeded) .. (pivotSucceeded and (" " .. tostring(pivot)) or ""))
		end
	end
	if itemId == "Campfire" then
		print("[MAYDEAD] Campfire template found = " .. tostring(template ~= nil))
		print("[MAYDEAD] Campfire template class = " .. (template and template.ClassName or "NONE"))
		if template then
			for _, child in template:GetChildren() do
				print("[MAYDEAD] CampFire child = " .. child.Name .. " (" .. child.ClassName .. ")")
			end
		end
	end
	return template
end

function BuildingService:_normalizePlaceableTemplate(template, itemId)
	if typeof(template) ~= "Instance" then
		return nil, "source template is not an Instance"
	end

	local runtimeModel = Instance.new("Model")
	runtimeModel.Name = itemId
	local cloneErrors = {}
	local function clonePreservingArchivable(source)
		local changed = {}
		if not source.Archivable then
			table.insert(changed, source)
			source.Archivable = true
		end
		for _, descendant in source:GetDescendants() do
			if not descendant.Archivable then
				table.insert(changed, descendant)
				descendant.Archivable = true
			end
		end
		local succeeded, clone = pcall(function()
			return source:Clone()
		end)
		for _, instance in changed do
			instance.Archivable = false
		end
		return succeeded, clone
	end
	local function cloneIntoRuntime(source)
		local succeeded, clone = clonePreservingArchivable(source)
		if succeeded and clone then
			clone.Parent = runtimeModel
			return true
		end
		table.insert(cloneErrors, source:GetFullName() .. " (" .. source.ClassName .. ")")
		return false
	end

	if template:IsA("Model") then
		local succeeded, clone = clonePreservingArchivable(template)
		if succeeded and clone and clone:IsA("Model") then
			runtimeModel:Destroy()
			runtimeModel = clone
			runtimeModel.Name = itemId
		else
			for _, child in template:GetChildren() do
				cloneIntoRuntime(child)
			end
		end
	elseif template:IsA("BasePart") then
		cloneIntoRuntime(template)
	else
		for _, child in template:GetChildren() do
			cloneIntoRuntime(child)
		end
	end

	local basePartCount = 0
	for _, descendant in runtimeModel:GetDescendants() do
		if descendant:IsA("BasePart") then
			basePartCount = basePartCount + 1
		end
	end
	if basePartCount <= 0 then
		for _, descendant in template:GetDescendants() do
			if descendant:IsA("BasePart") and cloneIntoRuntime(descendant) then
				basePartCount = basePartCount + 1
			end
		end
	end
	if basePartCount <= 0 then
		runtimeModel:Destroy()
		local suffix = #cloneErrors > 0 and ("; clone failures: " .. table.concat(cloneErrors, ", ")) or ""
		return nil, "no BasePart found after normalization" .. suffix
	end
	return runtimeModel, nil, basePartCount
end

function BuildingService:_loadTemplates()
	local assetImports = ServerStorage:FindFirstChild("AssetImports")
	if not assetImports then
		warn("[MAYDEAD] Building assets unavailable: ServerStorage.AssetImports missing")
		return
	end

	local previewFolder = ReplicatedStorage:FindFirstChild("PlacementPreviews")
	if not previewFolder then
		previewFolder = Instance.new("Folder")
		previewFolder.Name = "PlacementPreviews"
		previewFolder.Parent = ReplicatedStorage
	end

	for itemId, definition in PlaceableDefinitions do
		local sourceTemplate = self:_resolvePlaceableTemplate(assetImports, itemId)
		if not sourceTemplate then
			warn("[MAYDEAD] Placement template FAILED: " .. itemId .. " - source missing: " .. definition.TemplateName)
			if itemId == "QuarterCircleCeiling" then
				warn("[MAYDEAD] QuarterCircleCeiling publication FAILED: source missing: " .. definition.TemplateName)
			end
			continue
		end
		local template, normalizeReason, normalizedBasePartCount = self:_normalizePlaceableTemplate(sourceTemplate, itemId)
		if not template then
			warn("[MAYDEAD] Placement template FAILED: " .. itemId .. " - " .. normalizeReason)
			if itemId == "QuarterCircleCeiling" then
				warn("[MAYDEAD] QuarterCircleCeiling publication FAILED: " .. normalizeReason)
			end
			continue
		end
		if definition.OrientationMode == "AutoHorizontal" then
			local offset, axis, angleDegrees, beforeSize, afterSize = orientHorizontalSurface(template)
			print("[MAYDEAD] " .. itemId .. " orientation offset = " .. tostring(offset))
			print("[MAYDEAD] " .. itemId .. " orientation axis/angle = " .. axis .. " " .. tostring(angleDegrees))
			print("[MAYDEAD] " .. itemId .. " normalized size before offset = " .. tostring(beforeSize))
			print("[MAYDEAD] " .. itemId .. " normalized size after offset = " .. tostring(afterSize))
		elseif definition.OrientationMode == "AutoVertical" then
			local offset, axis, angleDegrees, beforeSize, afterSize = orientVerticalStructure(template)
			print("[MAYDEAD] " .. itemId .. " vertical orientation offset = " .. tostring(offset))
			print("[MAYDEAD] " .. itemId .. " vertical orientation axis/angle = " .. axis .. " " .. tostring(angleDegrees))
			print("[MAYDEAD] " .. itemId .. " normalized size before offset = " .. tostring(beforeSize))
			print("[MAYDEAD] " .. itemId .. " normalized size after offset = " .. tostring(afterSize))
		end
		local partCount = 0
		local anchoredCount = 0
		local collidableCount = 0
		for _, descendant in template:GetDescendants() do
			if descendant:IsA("BasePart") then
				partCount = partCount + 1
				anchoredCount = anchoredCount + (descendant.Anchored and 1 or 0)
				collidableCount = collidableCount + (descendant.CanCollide and 1 or 0)
			end
		end

		self._templates[itemId] = template
		local previousPreview = previewFolder:FindFirstChild(itemId)
		if previousPreview then
			previousPreview:Destroy()
		end
		local cloned, previewTemplate = pcall(function()
			return template:Clone()
		end)
		if not cloned or not previewTemplate then
			local fallbackReason
			previewTemplate, fallbackReason = self:_normalizePlaceableTemplate(template, itemId)
			if not previewTemplate then
				self._templates[itemId] = nil
				warn("[MAYDEAD] Placement template FAILED: " .. itemId .. " - preview clone failed: " .. fallbackReason)
				if itemId == "QuarterCircleCeiling" then
					warn("[MAYDEAD] QuarterCircleCeiling publication FAILED: preview clone failed: " .. fallbackReason)
				end
				continue
			end
		end
		previewTemplate.Name = itemId
		preparePreviewTemplate(previewTemplate)
		previewTemplate.Parent = previewFolder
		if itemId == "ConveyorStraight" then
			print("[MAYDEAD] Placement preview published: ConveyorStraight")
		end
		if itemId == "QuarterCircleCeiling" then
			if previewFolder:FindFirstChild(itemId) == previewTemplate then
				print("[MAYDEAD] Placement preview published: QuarterCircleCeiling")
			else
				warn("[MAYDEAD] QuarterCircleCeiling publication FAILED: runtime preview not found after parenting")
			end
		end
		print(string.format(
			"[MAYDEAD] Placement template ready: %s -> %s | normalizedBaseParts=%d parts=%d anchored=%d collidable=%d primary=%s",
			itemId,
			definition.TemplateName,
			normalizedBasePartCount,
			partCount,
			anchoredCount,
			collidableCount,
			template.PrimaryPart and template.PrimaryPart.Name or "NONE"
		))
	end

	local ceilingTemplate = self._templates.Ceiling
	local wallTemplate = self._templates.Wall
	if ceilingTemplate and wallTemplate then
		local _, ceilingSize = getPlacementBox(ceilingTemplate)
		local _, wallSize = getPlacementBox(wallTemplate)
		self._moduleDimensions = {
			CeilingWidth = ceilingSize.X,
			CeilingDepth = ceilingSize.Z,
			CeilingThickness = ceilingSize.Y,
			WallHeight = wallSize.Y,
			WallThickness = math.min(wallSize.X, wallSize.Z),
		}
		previewFolder:SetAttribute("WallThickness", self._moduleDimensions.WallThickness)
		print(string.format(
			"[MAYDEAD] Building modules: Ceiling %.3fx%.3fx%.3f | Wall height %.3f thickness %.3f",
			ceilingSize.X,
			ceilingSize.Z,
			ceilingSize.Y,
			wallSize.Y,
			math.min(wallSize.X, wallSize.Z)
		))
	end

	local quarterFloorTemplate = self._templates.QuarterCircleCeiling
	local quarterWallTemplate = self._templates.QuarterCircleWall
	if quarterFloorTemplate and quarterWallTemplate then
		local floorBox, floorSize = getPlacementBox(quarterFloorTemplate)
		local wallBox, wallSize = getPlacementBox(quarterWallTemplate)
		local floorChord = math.sqrt(floorSize.X * floorSize.X + floorSize.Z * floorSize.Z)
		local wallChord = math.sqrt(wallSize.X * wallSize.X + wallSize.Z * wallSize.Z)
		print("[MAYDEAD] Quarter floor pivot = " .. tostring(quarterFloorTemplate:GetPivot()))
		print("[MAYDEAD] Quarter wall pivot = " .. tostring(quarterWallTemplate:GetPivot()))
		print("[MAYDEAD] Quarter floor placement box = " .. tostring(floorBox) .. " size=" .. tostring(floorSize))
		print("[MAYDEAD] Quarter wall placement box = " .. tostring(wallBox) .. " size=" .. tostring(wallSize))
		print("[MAYDEAD] Quarter floor radius estimate = " .. tostring(math.max(floorSize.X, floorSize.Z)))
		print("[MAYDEAD] Quarter wall radius estimate = " .. tostring(math.max(wallSize.X, wallSize.Z)))
		print("[MAYDEAD] Quarter floor expected arc angle = 90")
		print("[MAYDEAD] Quarter wall expected arc angle = 90")
		print("[MAYDEAD] Quarter arc chord delta = " .. tostring(math.abs(floorChord - wallChord)))
	end
end

function BuildingService:_findStructureById(structureId)
	if typeof(structureId) ~= "string" then
		return nil
	end
	local placedFolder = workspace:FindFirstChild("PlacedStructures")
	if not placedFolder then
		return nil
	end
	for _, candidate in placedFolder:GetDescendants() do
		if candidate:IsA("Model") and candidate:GetAttribute("StructureId") == structureId then
			return candidate
		end
	end
	return nil
end

function BuildingService:_buildSnapCandidate(itemId, support, snapId)
	local definition = PlaceableDefinitions[itemId]
	local template = self._templates[itemId]
	if not definition
		or not template
		or not support
		or typeof(snapId) ~= "string"
	then
		return nil
	end

	local supportType = support:GetAttribute("StructureType")
	local supportDefinition = PlaceableDefinitions[supportType]
	if itemId == "Window" or itemId == "Door" then
		local expectedSupportType = itemId == "Window" and "WindowWall" or "DoorWall"
		if supportType ~= expectedSupportType or snapId ~= "Insert" then
			return nil
		end
		local supportBox, supportSize = getPlacementBox(support)
		local _, pieceSize = getPlacementBox(template)
		local targetBox = itemId == "Door"
			and BuildingSnapGeometry.GetDoorInsertSnapCFrame(
				supportBox,
				supportSize,
				pieceSize,
				definition.SnapOffset
			)
			or BuildingSnapGeometry.GetInsertSnapCFrame(supportBox, definition.SnapOffset)
		return {
			Support = support,
			Mode = "Insert",
			Side = "Insert",
			TargetBox = targetBox,
			OccupancyAttribute = itemId .. "Occupied",
		}
	end
	if isFloorItemId(itemId)
		and snapId == "WallTop"
		and supportDefinition
		and supportDefinition.SupportsCeilingTop == true
	then
		local parentCeiling = self:_findStructureById(support:GetAttribute("ParentStructureId"))
		if not parentCeiling or not isFloorStructureType(parentCeiling:GetAttribute("StructureType")) then
			return nil
		end
		local wallBox, wallSize = getPlacementBox(support)
		local parentBox = getPlacementBox(parentCeiling)
		local _, pieceSize = getPlacementBox(template)
		local targetPosition = Vector3.new(
			parentBox.Position.X,
			wallBox.Position.Y + wallSize.Y / 2 + pieceSize.Y / 2,
			parentBox.Position.Z
		)
		return {
			Support = parentCeiling,
			TargetWall = support,
			Mode = "Upper",
			SourceMode = "WallTop",
			Side = "Upper",
			TargetBox = parentBox + (targetPosition - parentBox.Position),
			HasStructuralSupport = true,
		}
	end
	if supportType == "QuarterCircleCeiling" then
		local supportBox, supportSize = getPlacementBox(support)
		local _, pieceSize = getPlacementBox(template)
		local snapOffset = definition.SnapOffset or Vector3.zero
		if definition.PlacementType == "CurvedWall" and snapId == "CurvedEdge" then
			return {
				Support = support,
				Mode = "CurvedWall",
				Side = "CurvedEdge",
				TargetBox = BuildingSnapGeometry.GetCurvedWallSnapCFrame(
					supportBox,
					supportSize,
					pieceSize,
					snapOffset,
					definition.OrientationOffset
				),
				OccupancyAttribute = "CurvedEdgeOccupied",
			}
		end
		local edgeDirection = CURVED_FLOOR_EDGE_BY_NAME[snapId]
		if isFloorItemId(itemId) and edgeDirection then
			local worldDirection = supportBox:VectorToWorldSpace(edgeDirection)
			local newOccupancyAttribute = itemId == "QuarterCircleCeiling"
				and "StraightEdgeAOccupied"
				or "NorthFloorOccupied"
			return {
				Support = support,
				Mode = "Horizontal",
				Side = snapId,
				TargetBox = BuildingSnapGeometry.GetFloorEdgeSnapCFrame(
					supportBox,
					supportSize,
					edgeDirection,
					pieceSize,
					Vector3.new(0, 0, -1),
					snapOffset
				),
				OccupancyAttribute = snapId .. "Occupied",
				NewOccupancyAttribute = newOccupancyAttribute,
				GridDirection = Vector3.new(math.round(worldDirection.X), 0, math.round(worldDirection.Z)),
			}
		end
		return nil
	end
	if supportType ~= "Ceiling" then
		return nil
	end

	local supportBox, supportSize = getPlacementBox(support)
	local _, pieceSize = getPlacementBox(template)
	local snapOffset = definition.SnapOffset or Vector3.zero
	if snapId == "Upper" and isFloorItemId(itemId) and self._moduleDimensions then
		local target = supportBox * CFrame.new(
			0,
			supportSize.Y / 2 + self._moduleDimensions.WallHeight + pieceSize.Y / 2,
			0
		) * CFrame.new(snapOffset)
		return {
			Support = support,
			Mode = "Upper",
			Side = "Upper",
			TargetBox = target,
			HasStructuralSupport = hasAttachedWall(workspace.PlacedStructures, support),
		}
	end
	if itemId == "QuarterCircleCeiling" and string.sub(snapId, 1, 12) == "QuarterFloor" then
		local side = FLOOR_SIDE_BY_NAME[string.sub(snapId, 13)]
		if not side then
			return nil
		end
		local worldDirection = supportBox:VectorToWorldSpace(side.Direction)
		return {
			Support = support,
			Mode = "Horizontal",
			Side = side.Name,
			TargetBox = BuildingSnapGeometry.GetFloorEdgeSnapCFrame(
				supportBox,
				supportSize,
				side.Direction,
				pieceSize,
				Vector3.new(0, 0, -1),
				snapOffset
			),
			OccupancyAttribute = side.Name .. "FloorOccupied",
			NewOccupancyAttribute = "StraightEdgeAOccupied",
			GridDirection = Vector3.new(math.round(worldDirection.X), 0, math.round(worldDirection.Z)),
		}
	end

	local prefix = itemId == "Ceiling" and "Floor" or (itemId == "Stairs" and "Stairs" or "Wall")
	if string.sub(snapId, 1, #prefix) ~= prefix then
		return nil
	end
	local side = FLOOR_SIDE_BY_NAME[string.sub(snapId, #prefix + 1)]
	if not side then
		return nil
	end

	if isFloorItemId(itemId) then
		local target = supportBox * CFrame.new(
			side.Direction.X * (supportSize.X / 2 + pieceSize.X / 2),
			0,
			side.Direction.Z * (supportSize.Z / 2 + pieceSize.Z / 2)
		) * CFrame.new(snapOffset)
		return {
			Support = support,
			Mode = "Horizontal",
			Side = side.Name,
			Opposite = side.Opposite,
			TargetBox = target,
		}
	end

	if itemId == "Wall" or itemId == "DoorWall" or itemId == "WindowWall" then
		if not self._moduleDimensions then
			return nil
		end
		local target = BuildingSnapGeometry.GetWallSnapCFrame(
			supportBox,
			supportSize,
			pieceSize,
			side.Direction,
			side.Yaw,
			self._moduleDimensions.WallThickness,
			snapOffset
		)
		return {
			Support = support,
			Mode = "Wall",
			Side = side.Name,
			TargetBox = target,
		}
	end
	if itemId == "HalfWall" then
		if not self._moduleDimensions then
			return nil
		end
		local target = BuildingSnapGeometry.GetWallSnapCFrame(
			supportBox,
			supportSize,
			pieceSize,
			side.Direction,
			side.Yaw,
			self._moduleDimensions.WallThickness,
			snapOffset
		)
		return {
			Support = support,
			Mode = "Wall",
			Side = side.Name,
			TargetBox = target,
		}
	end
	if itemId == "Stairs" and string.sub(snapId, 1, 6) == "Stairs" then
		local target = BuildingSnapGeometry.GetStairsSnapCFrame(
			supportBox,
			supportSize,
			pieceSize,
			side.Yaw,
			snapOffset
		)
		return {
			Support = support,
			Mode = "Stairs",
			Side = side.Name,
			TargetBox = target,
		}
	end
	return nil
end

function BuildingService:_getGroundResult(character, position)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character}
	parameters.IgnoreWater = false
	return workspace:Raycast(
		position + Vector3.new(0, GROUND_SEARCH_HEIGHT, 0),
		Vector3.new(0, -(GROUND_SEARCH_HEIGHT * 2), 0),
		parameters
	)
end

function BuildingService:_hasFullSupport(character, groundCFrame, boxSize, definition)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character}
	parameters.IgnoreWater = false
	local extentX = boxSize.X * 0.38
	local extentZ = boxSize.Z * 0.38
	for _, offset in ipairs({
		Vector3.zero,
		Vector3.new(extentX, 0, extentZ),
		Vector3.new(extentX, 0, -extentZ),
		Vector3.new(-extentX, 0, extentZ),
		Vector3.new(-extentX, 0, -extentZ),
	}) do
		local origin = groundCFrame:PointToWorldSpace(offset) + Vector3.new(0, SUPPORT_RAY_HEIGHT, 0)
		local result = workspace:Raycast(origin, Vector3.new(0, -SUPPORT_RAY_DEPTH, 0), parameters)
		if not isSolidGround(result)
			or result.Normal.Y < math.cos(math.rad(definition.MaxSlopeDegrees))
			or math.abs(result.Position.Y - groundCFrame.Position.Y) > definition.MaxSupportGap
		then
			return false
		end
	end
	return true
end

function BuildingService:_hasWaterSupport(character, groundCFrame, boxSize)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character}
	parameters.IgnoreWater = false
	local extentX = boxSize.X * 0.38
	local extentZ = boxSize.Z * 0.38
	for _, offset in ipairs({
		Vector3.zero,
		Vector3.new(extentX, 0, extentZ),
		Vector3.new(extentX, 0, -extentZ),
		Vector3.new(-extentX, 0, extentZ),
		Vector3.new(-extentX, 0, -extentZ),
	}) do
		local origin = groundCFrame:PointToWorldSpace(offset) + Vector3.new(0, SUPPORT_RAY_HEIGHT, 0)
		local result = workspace:Raycast(origin, Vector3.new(0, -SUPPORT_RAY_DEPTH, 0), parameters)
		if not isWaterSurface(result) then
			return false
		end
	end
	return true
end

function BuildingService:_findSnapCandidate(itemId, requestedPosition)
	local definition = PlaceableDefinitions[itemId]
	local template = self._templates[itemId]
	local placedFolder = workspace:FindFirstChild("PlacedStructures")
	if not definition or not template or not placedFolder then
		return nil
	end
	local _, pieceSize = getPlacementBox(template)
	local best
	for _, support in placedFolder:GetDescendants() do
		if not support:IsA("Model") or support:GetAttribute("StructureType") ~= "Ceiling" then
			continue
		end
		local supportBox, supportSize = getPlacementBox(support)
		if definition.PlacementType == "Floor" then
			local wallTemplate = self._templates.Wall
			if not wallTemplate then
				return nil
			end
			local _, wallSize = getPlacementBox(wallTemplate)
			for _, side in FLOOR_SIDES do
				local offset = Vector3.new(
					side.Direction.X * (supportSize.X / 2 + pieceSize.X / 2),
					0,
					side.Direction.Z * (supportSize.Z / 2 + pieceSize.Z / 2)
				)
				local target = supportBox * CFrame.new(offset)
				local distance = getSnapDistance(target.Position, requestedPosition, definition.PlacementType)
				if distance <= definition.SnapDistance and (not best or distance < best.Distance) then
					best = {
						Support = support,
						Mode = "Horizontal",
						Side = side.Name,
						Opposite = side.Opposite,
						TargetBox = target,
						Distance = distance,
					}
				end
			end
			local upperTarget = supportBox * CFrame.new(0, supportSize.Y / 2 + wallSize.Y + pieceSize.Y / 2, 0)
			local upperDistance = getSnapDistance(upperTarget.Position, requestedPosition, definition.PlacementType)
			if upperDistance <= definition.SnapDistance and (not best or upperDistance < best.Distance) then
				best = {
					Support = support,
					Mode = "Upper",
					Side = "Upper",
					TargetBox = upperTarget,
					Distance = upperDistance,
					HasStructuralSupport = hasAttachedWall(placedFolder, support),
				}
			end
		elseif definition.PlacementType == "Stairs" then
			for _, side in FLOOR_SIDES do
				local target = BuildingSnapGeometry.GetStairsSnapCFrame(
					supportBox,
					supportSize,
					pieceSize,
					side.Yaw,
					definition.SnapOffset
				)
				local capturePosition = supportBox:PointToWorldSpace(Vector3.new(
					side.Direction.X * supportSize.X / 2,
					supportSize.Y / 2,
					side.Direction.Z * supportSize.Z / 2
				))
				local distance = getSnapDistance(capturePosition, requestedPosition, definition.PlacementType)
				if distance <= definition.SnapDistance and (not best or distance < best.Distance) then
					best = {Support = support, Mode = "Stairs", Side = side.Name, TargetBox = target, Distance = distance}
				end
			end
		elseif definition.PlacementType == "Wall" then
			if not self._moduleDimensions then
				return nil
			end
			for _, side in FLOOR_SIDES do
				local target = BuildingSnapGeometry.GetWallSnapCFrame(
					supportBox,
					supportSize,
					pieceSize,
					side.Direction,
					side.Yaw,
					self._moduleDimensions.WallThickness,
					definition.SnapOffset
				)
				local distance = getSnapDistance(target.Position, requestedPosition, definition.PlacementType)
				if distance <= definition.SnapDistance and (not best or distance < best.Distance) then
					best = {Support = support, Mode = "Wall", Side = side.Name, TargetBox = target, Distance = distance}
				end
			end
		end
	end
	return best
end

function BuildingService:_isSnapBoxClear(character, targetBox, boxSize, support, snapMode)
	local parameters = OverlapParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character}
	local epsilon = BuildingConfig.STRUCTURE_COLLISION_EPSILON
	for _, part in workspace:GetPartBoundsInBox(targetBox, Vector3.new(
		math.max(0.2, boxSize.X - epsilon * 2),
		math.max(0.2, boxSize.Y - epsilon * 2),
		math.max(0.2, boxSize.Z - epsilon * 2)
	), parameters) do
		if part.CanCollide or isPlayerCharacterPart(part) then
			local structure = getStructureModel(part)
			local isCompatibleCornerWall = snapMode == "Wall"
				and structure
				and isWallStructureType(structure:GetAttribute("StructureType"))
				and structure:GetAttribute("ParentStructureId") == support:GetAttribute("StructureId")
			local sameSupport = structure == support
				or (snapMode == "Upper"
					and structure
					and structure:GetAttribute("ParentStructureId") == support:GetAttribute("StructureId"))
				or isCompatibleCornerWall
			if not sameSupport then
				return false
			end
		end
	end
	return true
end

function BuildingService:_validateSnapPlacement(player, itemId, requestData, definition, template, character, rootPart)
	local support = self:_findStructureById(requestData.TargetStructureId)
	if not support then
		return nil, "InvalidSnapTarget"
	end
	local snap = self:_buildSnapCandidate(itemId, support, requestData.SnapId)
	if not snap then
		return nil, "InvalidSnap"
	end
	if itemId == "QuarterCircleCeiling" then
		local rotationIndex = requestData.RotationIndex
		if typeof(rotationIndex) ~= "number" or rotationIndex % 1 ~= 0 or rotationIndex < 0 or rotationIndex > 3 then
			return nil, "InvalidRotation"
		end
		snap.TargetBox = snap.TargetBox * CFrame.Angles(0, rotationIndex * math.pi / 2, 0)
		snap.RotationIndex = rotationIndex
	end
	if isFloorItemId(itemId) then
		print("[MAYDEAD] Ceiling snap candidate = " .. requestData.TargetStructureId .. ":" .. requestData.SnapId)
		if snap.SourceMode == "WallTop" then
			print("[MAYDEAD] Ceiling snapped to wall = " .. requestData.TargetStructureId)
		elseif snap.Mode == "Horizontal" then
			print("[MAYDEAD] Ceiling snapped to ceiling edge = " .. requestData.SnapId)
		end
		print("[MAYDEAD] Snap position = " .. tostring(snap.TargetBox.Position))
		local supportDirect, supportDistance = self:_getCandidateSupport(snap)
		snap.SupportDirect = supportDirect
		snap.SupportDistance = supportDistance
		if supportDistance > BuildingConfig.MAX_CANTILEVER_MODULES then
			return nil, "InsufficientSupport"
		end
	end
	if snap.Mode == "Upper" then
		if not snap.HasStructuralSupport then
			return nil, "Unsupported"
		end
		if snap.Support:GetAttribute("UpperFloorOccupied") then
			return nil, "SnapOccupied"
		end
	elseif snap.Mode == "Horizontal"
		and snap.Support:GetAttribute(snap.OccupancyAttribute or (snap.Side .. "FloorOccupied"))
	then
		return nil, "SnapOccupied"
	elseif snap.Mode == "Wall" and snap.Support:GetAttribute(snap.Side .. "WallOccupied") then
		return nil, "SnapOccupied"
	elseif snap.Mode == "Stairs" and snap.Support:GetAttribute(snap.Side .. "StairsOccupied") then
		return nil, "SnapOccupied"
	elseif snap.Mode == "Insert" and snap.Support:GetAttribute(snap.OccupancyAttribute) then
		return nil, "SnapOccupied"
	elseif snap.Mode == "CurvedWall" and snap.Support:GetAttribute("CurvedEdgeOccupied") then
		return nil, "SnapOccupied"
	end
	if (rootPart.Position - snap.TargetBox.Position).Magnitude > BuildingConfig.MAX_PLACEMENT_DISTANCE then
		return nil, "TooFar"
	end
	local _, boxSize = getPlacementBox(template)
	if not self:_isSnapBoxClear(character, snap.TargetBox, boxSize, snap.Support, snap.Mode) then
		return nil, "Blocked"
	end
	return getPivotForBox(template, snap.TargetBox), nil, snap
end

function BuildingService:_validatePlacement(player, itemId, requestData)
	if typeof(requestData) ~= "table" then
		return nil, "InvalidRequest"
	end
	local requestedCFrame = requestData.CFrame
	local itemDefinition = ItemDefinitions[itemId]
	local placementDefinition = PlaceableDefinitions[itemId]
	local template = self._templates[itemId]
	if not itemDefinition
		or itemDefinition.Placeable ~= true
		or not placementDefinition
		or not template
		or not isFiniteCFrame(requestedCFrame)
	then
		return nil, "InvalidItem"
	end
	local inventoryActiveItem = InventoryService:GetActiveItem(player)
	if inventoryActiveItem == itemId then
		self._activePlacementItems[player] = itemId
	elseif self._activePlacementItems[player] ~= itemId then
		return nil, "ItemNotSelected"
	end
	if not InventoryService:HasItem(player, itemId, 1) then
		return nil, "ItemNotSelected"
	end
	local rotationIndex = requestData.RotationIndex
	local rotationStepDegrees = placementDefinition.RotationStepDegrees
	local rotationCount = rotationStepDegrees and math.round(360 / rotationStepDegrees) or 0
	if placementDefinition.FreeRotation == true
		and (typeof(rotationIndex) ~= "number"
			or rotationIndex % 1 ~= 0
			or rotationIndex < 0
			or rotationIndex >= rotationCount)
	then
		return nil, "InvalidRotation"
	end
	if itemId == "QuarterCircleCeiling"
		and (typeof(rotationIndex) ~= "number" or rotationIndex % 1 ~= 0 or rotationIndex < 0 or rotationIndex > 3)
	then
		return nil, "InvalidRotation"
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not rootPart then
		return nil, "InvalidPlayer"
	end
	local hasSnapRequest = requestData.TargetStructureId ~= nil or requestData.SnapId ~= nil
	if placementDefinition.PlacementType then
		if hasSnapRequest then
			if typeof(requestData.TargetStructureId) ~= "string" or typeof(requestData.SnapId) ~= "string" then
				return nil, "InvalidSnap"
			end
			local snapPivot, snapReason, snapData = self:_validateSnapPlacement(
				player,
				itemId,
				requestData,
				placementDefinition,
				template,
				character,
				rootPart
			)
			if snapPivot then
				return snapPivot, nil, snapData
			end
			return nil, snapReason
		elseif placementDefinition.PlacementType ~= "Floor"
			and placementDefinition.PlacementType ~= "CurvedFloor"
		then
			return nil, "SnapRequired"
		end
	end

	local groundResult = self:_getGroundResult(character, requestedCFrame.Position)
	local waterOnly = placementDefinition.PlacementSurface == "Water"
	if waterOnly and not isWaterSurface(groundResult) then
		return nil, "WaterRequired"
	elseif not waterOnly and not isSolidGround(groundResult) then
		if groundResult and groundResult.Material == Enum.Material.Water then
			return nil, "WaterForbidden"
		end
		return nil, "InvalidGround"
	end
	if isHarvestResource(groundResult.Instance) then
		return nil, "InvalidGround"
	end
	if not waterOnly and groundResult.Normal.Y < math.cos(math.rad(placementDefinition.MaxSlopeDegrees)) then
		return nil, "SlopeTooSteep"
	end

	local yaw = getYaw(requestedCFrame)
	if placementDefinition.FreeRotation == true then
		yaw = rotationIndex * math.rad(rotationStepDegrees)
	end
	if itemId == "QuarterCircleCeiling" then
		yaw = rotationIndex * math.pi / 2
	end
	if placementDefinition.PlacementType == "Floor" or placementDefinition.PlacementType == "CurvedFloor" then
		local step = math.rad(placementDefinition.RotationStepDegrees)
		yaw = math.floor(yaw / step + 0.5) * step
	end
	local groundCFrame = CFrame.new(groundResult.Position) * CFrame.Angles(0, yaw, 0)
	local finalPivot, targetBoxCFrame, boxSize = getPlacementGeometry(template, groundCFrame)
	if (rootPart.Position - targetBoxCFrame.Position).Magnitude > BuildingConfig.MAX_PLACEMENT_DISTANCE then
		return nil, "TooFar"
	end
	if waterOnly and not self:_hasWaterSupport(character, groundCFrame, boxSize) then
		return nil, "WaterRequired"
	elseif not waterOnly and not self:_hasFullSupport(character, groundCFrame, boxSize, placementDefinition) then
		return nil, "Unsupported"
	end

	local overlapParameters = OverlapParams.new()
	overlapParameters.FilterType = Enum.RaycastFilterType.Exclude
	overlapParameters.FilterDescendantsInstances = {character}
	local overlapSize = Vector3.new(
		math.max(0.2, boxSize.X * 0.9),
		math.max(0.2, boxSize.Y - 0.15),
		math.max(0.2, boxSize.Z * 0.9)
	)
	local groundStructure = getStructureModel(groundResult.Instance)
	for _, part in workspace:GetPartBoundsInBox(targetBoxCFrame * CFrame.new(0, 0.1, 0), overlapSize, overlapParameters) do
		local overlappingStructure = getStructureModel(part)
		if (part.CanCollide or isPlayerCharacterPart(part))
			and part ~= groundResult.Instance
			and (not groundStructure or overlappingStructure ~= groundStructure)
		then
			return nil, "Blocked"
		end
	end

	return finalPivot, nil, (placementDefinition.PlacementType == "Floor"
		or placementDefinition.PlacementType == "CurvedFloor") and {Mode = "Ground", Side = "Free"} or nil
end

function BuildingService:_createStructure(itemId, pivot)
	local template = self._templates[itemId]
	if not template then
		return nil
	end
	local model = template:Clone()
	preparePlacedModel(model, PlaceableDefinitions[itemId].Vehicle == true)
	model:PivotTo(pivot)
	return model
end

function BuildingService:_registerRuntimeStructure(model, itemId)
	if itemId == "Boat" then
		BoatService:RegisterBoat(model)
	end
	if itemId == "Door" then
		local doorWall = self:_findStructureById(model:GetAttribute("ParentStructureId"))
		DoorService:RegisterDoor(model, doorWall)
	end
	if itemId == "GardenPlot" then
		CropService:RegisterPlot(model)
	end
	if itemId == "Camp" then
		CampService:RegisterCamp(model)
	end
	if itemId == "CraftingTable" or itemId == "Campfire" or itemId == "Chest" or itemId == "AutomaticLoader" or itemId == "Smelt" then
		StationService:RegisterStation(model, itemId)
		if itemId == "CraftingTable" then
			CollectionService:AddTag(model, WORKBENCH_TAG)
		end
		local interactionPoint = model:FindFirstChild("InteractionPoint", true)
		local promptParent = (interactionPoint and (interactionPoint:IsA("Attachment") and interactionPoint or interactionPoint:IsA("BasePart") and interactionPoint))
			or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		local promptName = itemId .. "Prompt"
		local functionalPrompt
		local promptCountBefore = 0
		local duplicateRemoved = 0
		if itemId == "Chest" then
			for _, descendant in model:GetDescendants() do
				if descendant:IsA("ProximityPrompt") then
					promptCountBefore += 1
					if descendant.Name == promptName
						and descendant:GetAttribute("MAYDEADStationInteraction") == true
						and not functionalPrompt
					then
						functionalPrompt = descendant
					else
						descendant:Destroy()
						duplicateRemoved += 1
					end
				end
			end
		elseif promptParent then
			functionalPrompt = promptParent:FindFirstChild(promptName)
		end
		if promptParent and not functionalPrompt then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = promptName
			prompt:SetAttribute("MAYDEADStationInteraction", true)
			prompt.ActionText = itemId == "CraftingTable" and "CRAFTER" or (itemId == "AutomaticLoader" and "OUVRIR" or (itemId == "Chest" and "OUVRIR" or "UTILISER"))
			prompt.ObjectText = itemId == "CraftingTable" and "TABLE DE CRAFTING" or (itemId == "AutomaticLoader" and "CHARGEUR AUTOMATIQUE" or (itemId == "Chest" and "COFFRE" or (itemId == "Smelt" and "FOUR DE FONTE" or "FEU DE CAMP")))
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = promptParent
			prompt.Triggered:Connect(function(triggeringPlayer)
				if triggeringPlayer:GetAttribute("SessionStarted") ~= true then return end
				StationService:OpenStation(triggeringPlayer, model)
				if itemId == "CraftingTable" then
					self._openWorkbench:FireClient(triggeringPlayer, model)
				end
			end)
			functionalPrompt = prompt
		end
		if itemId == "Chest" and RunService:IsStudio() then
			local promptCountAfter = 0
			for _, descendant in model:GetDescendants() do
				if descendant:IsA("ProximityPrompt") then promptCountAfter += 1 end
			end
			print(string.format(
				"[MAYDEAD][CHEST][INTERACTION] StructureId=%s PromptCountBefore=%d PromptCountAfter=%d FunctionalPrompt=%s DuplicateRemoved=%d",
				tostring(model:GetAttribute("StructureId")),
				promptCountBefore,
				promptCountAfter,
				functionalPrompt and functionalPrompt:GetFullName() or "nil",
				duplicateRemoved
			))
		end
	end
	if itemId == "Factory" then FactoryService:_registerMachine(model) end
end

function BuildingService:_finalizeStructure(player, itemId, model, snapData)
	local placedFolder = workspace:FindFirstChild("PlacedStructures")
	if not placedFolder then
		error("PlacedStructures folder is missing")
	end
	model.Name = itemId
	model:SetAttribute("ItemId", itemId)
	local structureId = HttpService:GenerateGUID(false)
	model:SetAttribute("StructureId", structureId)
	model:SetAttribute("StructureType", itemId)
	model:SetAttribute("SnapType", PlaceableDefinitions[itemId].PlacementType)
	model:SetAttribute("OwnerUserId", player.UserId)
	if itemId == "Chest" then
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CanQuery = true
				descendant:SetAttribute("StructureId", structureId)
				descendant:SetAttribute("StructureType", "Chest")
			end
		end
	end
	local buildingsFolder = placedFolder:FindFirstChild("Buildings")
	if PlaceableDefinitions[itemId].PlacementType and not buildingsFolder then
		buildingsFolder = Instance.new("Folder")
		buildingsFolder.Name = "Buildings"
		buildingsFolder.Parent = placedFolder
	end
	model.Parent = PlaceableDefinitions[itemId].PlacementType and buildingsFolder or placedFolder

	if isFloorItemId(itemId) then
		if itemId == "Ceiling" then
			for _, side in FLOOR_SIDES do
				model:SetAttribute(side.Name .. "WallOccupied", false)
				model:SetAttribute(side.Name .. "FloorOccupied", false)
			end
		else
			model:SetAttribute("StraightEdgeAOccupied", false)
			model:SetAttribute("StraightEdgeBOccupied", false)
			model:SetAttribute("CurvedEdgeOccupied", false)
		end
		model:SetAttribute("UpperFloorOccupied", false)
		model:SetAttribute("StructureLevel", 0)
		model:SetAttribute("StructureRootId", structureId)
		model:SetAttribute("GridX", 0)
		model:SetAttribute("GridZ", 0)
		model:SetAttribute("SupportDirect", true)
		model:SetAttribute("SupportDistance", 0)
		for _, side in FLOOR_SIDES do
			model:SetAttribute(side.Name .. "StairsOccupied", false)
		end
		if snapData and snapData.Mode == "Horizontal" then
			local supportOccupancyAttribute = snapData.OccupancyAttribute or (snapData.Side .. "FloorOccupied")
			local newOccupancyAttribute = snapData.NewOccupancyAttribute or (snapData.Opposite .. "FloorOccupied")
			snapData.Support:SetAttribute(supportOccupancyAttribute, true)
			model:SetAttribute(newOccupancyAttribute, true)
			model:SetAttribute("ParentStructureId", snapData.Support:GetAttribute("StructureId"))
			model:SetAttribute("SnapSide", snapData.Side)
			model:SetAttribute("ParentOccupancyAttribute", supportOccupancyAttribute)
			model:SetAttribute("StructureLevel", snapData.Support:GetAttribute("StructureLevel") or 0)
			model:SetAttribute("StructureRootId", snapData.Support:GetAttribute("StructureRootId") or structureId)
			local side = FLOOR_SIDE_BY_NAME[snapData.Side]
			local gridDirection = snapData.GridDirection or (side and side.Direction) or Vector3.zero
			model:SetAttribute("GridX", (snapData.Support:GetAttribute("GridX") or 0) + gridDirection.X)
			model:SetAttribute("GridZ", (snapData.Support:GetAttribute("GridZ") or 0) + gridDirection.Z)
			model:SetAttribute("SupportDirect", snapData.SupportDirect == true)
			model:SetAttribute("SupportDistance", snapData.SupportDistance or 0)
		elseif snapData and snapData.Mode == "Upper" then
			snapData.Support:SetAttribute("UpperFloorOccupied", true)
			model:SetAttribute("ParentStructureId", snapData.Support:GetAttribute("StructureId"))
			model:SetAttribute("SnapSide", "Upper")
			model:SetAttribute("StructureLevel", (snapData.Support:GetAttribute("StructureLevel") or 0) + 1)
			model:SetAttribute("StructureRootId", snapData.Support:GetAttribute("StructureRootId") or structureId)
			model:SetAttribute("GridX", snapData.Support:GetAttribute("GridX") or 0)
			model:SetAttribute("GridZ", snapData.Support:GetAttribute("GridZ") or 0)
			model:SetAttribute("SupportDirect", snapData.SupportDirect == true)
			model:SetAttribute("SupportDistance", snapData.SupportDistance or 0)
		end
	elseif snapData and snapData.Support then
		model:SetAttribute("ParentStructureId", snapData.Support:GetAttribute("StructureId"))
		model:SetAttribute("SnapSide", snapData.Side)
		model:SetAttribute("StructureLevel", snapData.Support:GetAttribute("StructureLevel") or 0)
		model:SetAttribute("StructureRootId", snapData.Support:GetAttribute("StructureRootId"))
		if snapData.Mode == "Wall" then
			snapData.Support:SetAttribute(snapData.Side .. "WallOccupied", true)
		elseif snapData.Mode == "Stairs" then
			snapData.Support:SetAttribute(snapData.Side .. "StairsOccupied", true)
		elseif snapData.Mode == "Insert" then
			snapData.Support:SetAttribute(snapData.OccupancyAttribute, true)
		elseif snapData.Mode == "CurvedWall" then
			snapData.Support:SetAttribute("CurvedEdgeOccupied", true)
		end
	end
	self:_refreshCeilingSupportMetadata()
	self:_registerRuntimeStructure(model, itemId)
	model:SetAttribute("PersistentReady", true)
end

function BuildingService:_handleRequest(player, itemId, requestData)
	if typeof(itemId) ~= "string" then
		return
	end
	if typeof(requestData) == "table" and requestData.Cancel == true then
		self._activePlacementItems[player] = nil
		InventoryService:DeselectActiveItem(player, itemId)
		return
	end
	local now = os.clock()
	if now - (self._lastRequests[player] or 0) < 0.2 then
		return
	end
	self._lastRequests[player] = now

	local finalPivot, reason, snapData = self:_validatePlacement(player, itemId, requestData)
	if not finalPivot then
		self._result:FireClient(player, false, itemId, reason)
		return
	end

	local built, model = pcall(function()
		return self:_createStructure(itemId, finalPivot)
	end)
	if not built or not model then
		self._result:FireClient(player, false, itemId, "CreationFailed")
		return
	end
	if not InventoryService:ConsumePlaceableAnywhere(player, itemId) then
		model:Destroy()
		self._result:FireClient(player, false, itemId, "ItemUnavailable")
		return
	end
	if not InventoryService:HasItem(player, itemId, 1) then
		self._activePlacementItems[player] = nil
	end

	local finalized = pcall(function()
		self:_finalizeStructure(player, itemId, model, snapData)
	end)
	if not finalized then
		model:Destroy()
		InventoryService:AddItem(player, itemId, 1)
		self._activePlacementItems[player] = itemId
		self._result:FireClient(player, false, itemId, "CreationFailed")
		return
	end
	self._result:FireClient(player, true, itemId, "Ok", InventoryService:GetItemQuantity(player, itemId))
end

function BuildingService:_getPlacedStructure(target)
	if typeof(target) ~= "Instance" then
		return nil
	end
	local placedFolder = workspace:FindFirstChild("PlacedStructures")
	local current = target
	while current and current ~= placedFolder do
		if current:IsA("Model")
			and current:GetAttribute("StructureId")
			and PlaceableDefinitions[current:GetAttribute("ItemId")]
		then
			return current
		end
		current = current.Parent
	end
	return nil
end

function BuildingService:_releaseStructureOccupancy(structure)
	local parentStructureId = structure:GetAttribute("ParentStructureId")
	local snapSide = structure:GetAttribute("SnapSide")
	if typeof(parentStructureId) ~= "string" or typeof(snapSide) ~= "string" then
		return
	end
	local parentStructure = self:_findStructureById(parentStructureId)
	if not parentStructure then
		return
	end
	local itemId = structure:GetAttribute("ItemId")
	if isFloorItemId(itemId) then
		if snapSide == "Upper" then
			parentStructure:SetAttribute("UpperFloorOccupied", false)
		else
			local occupancyAttribute = structure:GetAttribute("ParentOccupancyAttribute")
				or (snapSide .. "FloorOccupied")
			parentStructure:SetAttribute(occupancyAttribute, false)
		end
	elseif itemId == "Wall" or itemId == "DoorWall" or itemId == "WindowWall" or itemId == "HalfWall" then
		parentStructure:SetAttribute(snapSide .. "WallOccupied", false)
	elseif itemId == "Stairs" then
		parentStructure:SetAttribute(snapSide .. "StairsOccupied", false)
	elseif itemId == "Window" then
		parentStructure:SetAttribute("WindowOccupied", false)
	elseif itemId == "Door" then
		parentStructure:SetAttribute("DoorOccupied", false)
	elseif itemId == "QuarterCircleWall" then
		parentStructure:SetAttribute("CurvedEdgeOccupied", false)
	end
end

function BuildingService:_rejectDismantle(player, structure, reason, logMessage)
	print("[MAYDEAD] Dismantle rejected: " .. logMessage)
	self._dismantleResult:FireClient(player, structure, false, reason)
end

function BuildingService:_handleDismantleRequest(player, target)
	local structure = self:_getPlacedStructure(target)
	if not structure then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local equippedTool = character and character:FindFirstChildOfClass("Tool")
	if not humanoid or humanoid.Health <= 0 or not rootPart then
		return
	end
	local structureItemId = structure:GetAttribute("ItemId")
	local activeItemId = InventoryService:GetActiveItem(player)
	local isAxe = equippedTool and equippedTool.Name == "Axe" and activeItemId == "StoneAxe"
	local isFurnacePickaxe = structureItemId == "Smelt"
		and equippedTool and equippedTool.Name == "Pickaxe" and activeItemId == "StonePickaxe"
	if not isAxe and not isFurnacePickaxe then
		return
	end
	-- OwnerUserId remains persisted for audit, but every player admitted to the
	-- active private world has the same dismantle permission.
	if getModelDistance(rootPart, structure) > BuildingConfig.DISMANTLE_RANGE then
		self:_rejectDismantle(player, structure, "TooFar", "too far")
		return
	end

	local now = os.clock()
	if now - (self._lastDismantleRequests[player] or 0) < BuildingConfig.DISMANTLE_COOLDOWN then
		return
	end
	self._lastDismantleRequests[player] = now
	print("[MAYDEAD] Structure hit by " .. equippedTool.Name .. " = " .. structureItemId)
	local placedFolder = workspace:FindFirstChild("PlacedStructures")
	if structureItemId == "DoorWall"
		and placedFolder
		and hasAttachedStructureType(placedFolder, structure, "Door")
	then
		self:_rejectDismantle(player, structure, "AttachedDoorPresent", "attached Door present")
		return
	end
	if structureItemId == "WindowWall"
		and placedFolder
		and hasAttachedStructureType(placedFolder, structure, "Window")
	then
		self:_rejectDismantle(player, structure, "AttachedWindowPresent", "attached Window present")
		return
	end
	if structureItemId == "QuarterCircleCeiling"
		and placedFolder
		and hasAttachedStructureType(placedFolder, structure, "QuarterCircleWall")
	then
		self:_rejectDismantle(player, structure, "AttachedStructurePresent", "attached structure present")
		return
	end

	local damage = structureItemId == "Smelt"
		and (isFurnacePickaxe and BuildingConfig.FURNACE_PICKAXE_DAMAGE or BuildingConfig.FURNACE_AXE_DAMAGE)
		or 1
	local maxHealth = structureItemId == "Smelt" and BuildingConfig.FURNACE_MAX_HEALTH
		or BuildingConfig.DISMANTLE_HITS_REQUIRED
	local remaining = math.max(0, (self._dismantleHits[structure] or maxHealth) - damage)
	if remaining > 0 then
		self._dismantleHits[structure] = remaining
		print("[MAYDEAD] Structure dismantle health = " .. remaining .. "/" .. maxHealth)
		self._dismantleResult:FireClient(player, structure, true, "Hit", remaining)
		return
	end

	local itemId = structure:GetAttribute("ItemId")
	if (itemId == "CraftingTable" or itemId == "Campfire" or itemId == "Chest" or itemId == "AutomaticLoader" or itemId == "Smelt")
		and not StationService:CanDismantle(structure)
	then
		self._dismantleHits[structure] = damage
		self:_rejectDismantle(player, structure, "StationNotEmpty", itemId == "Chest" and "Chest not empty" or "station not empty")
		return
	end
	local factoryRefund
	if itemId == "Recycler" or itemId == "IndustrialPress" then
		factoryRefund = FactoryService:GetDismantleRefund(structure)
		if not factoryRefund then
			self._dismantleHits[structure] = damage
			self:_rejectDismantle(player, structure, "InvalidFactoryState", "factory machine state is not refundable")
			return
		end
	end
	if itemId == "Factory" and not FactoryService:CanDismantle(structure) then
		self._dismantleHits[structure] = damage
		self:_rejectDismantle(player, structure, "InvalidFactoryState", "factory machine state is not refundable")
		return
	end
	local inventorySimulation
	if factoryRefund then
		factoryRefund.Items[itemId] = (factoryRefund.Items[itemId] or 0) + 1
		inventorySimulation = InventoryService:SimulateAddItems(player, factoryRefund.Items)
	end
	if (factoryRefund and not inventorySimulation)
		or (not factoryRefund and not InventoryService:CanAddItem(player, itemId, 1))
	then
		self._dismantleHits[structure] = damage
		self:_rejectDismantle(player, structure, "InventoryFull", "inventory full")
		return
	end

	local previousParent = structure.Parent
	structure.Parent = nil
	local inventoryCommitted
	if factoryRefund then
		inventoryCommitted = InventoryService:CommitSimulatedItems(player, inventorySimulation)
	else
		local returned = InventoryService:AddItem(player, itemId, 1)
		inventoryCommitted = returned.Remaining == 0
	end
	if not inventoryCommitted then
		structure.Parent = previousParent
		self._dismantleHits[structure] = damage
		self:_rejectDismantle(player, structure, "InventoryFull", "inventory full")
		return
	end
	if factoryRefund then FactoryService:CommitDismantle(structure, factoryRefund) end

	self:_releaseStructureOccupancy(structure)
	self:_refreshCeilingSupportMetadata()
	if itemId == "Door" then
		DoorService:UnregisterDoor(structure)
	end
	if itemId == "Boat" then
		BoatService:UnregisterBoat(structure)
	end
	StationService:UnregisterStation(structure)
	self._dismantleHits[structure] = nil
	print("[MAYDEAD] Structure dismantled = " .. itemId)
	print("[MAYDEAD] Structure returned to inventory = " .. itemId)
	self._dismantleResult:FireClient(player, nil, true, "Dismantled", 0)
	structure:Destroy()
end

function BuildingService:GetPersistentSnapshot()
	local placedFolder = workspace:FindFirstChild("PlacedStructures")
	if not placedFolder then
		return nil, "PlacedStructuresMissing"
	end
	local snapshot = {}
	local seenIds = {}
	local statefulCount = 0
	for _, candidate in placedFolder:GetDescendants() do
		if not candidate:IsA("Model") or candidate:GetAttribute("PersistentReady") ~= true then
			continue
		end
		local structureId = candidate:GetAttribute("StructureId")
		local itemId = candidate:GetAttribute("ItemId")
		local ownerUserId = candidate:GetAttribute("OwnerUserId")
		local pivot = serializeCFrame(candidate:GetPivot())
		if not isValidStructureId(structureId)
			or seenIds[structureId]
			or typeof(itemId) ~= "string"
			or not PlaceableDefinitions[itemId]
			or not self._templates[itemId]
			or typeof(ownerUserId) ~= "number"
			or not isFiniteNumber(ownerUserId)
			or ownerUserId ~= math.floor(ownerUserId)
			or not pivot
		then
			warn("[BuildingPersistence] Snapshot rejected invalid structure " .. candidate:GetFullName())
			return nil, "InvalidRuntimeStructure"
		end
		seenIds[structureId] = true
		local attributes = {}
		for _, attributeName in PERSISTED_ATTRIBUTES do
			local value = candidate:GetAttribute(attributeName)
			if value ~= nil then
				if not isPersistableAttribute(value) or (typeof(value) == "number" and not isFiniteNumber(value)) then
					warn("[BuildingPersistence] Snapshot rejected attribute " .. attributeName .. " on " .. structureId)
					return nil, "InvalidRuntimeAttribute"
				end
				attributes[attributeName] = value
			end
		end
		local state
		if itemId == "Chest" or itemId == "CraftingTable" or itemId == "AutomaticLoader" or itemId == "Campfire" or itemId == "Smelt" then
			local stateError
			state, stateError = StationService:GetPersistentState(candidate)
			if not state then
				warn("[StatePersistence] Station capture failed for " .. structureId .. ": " .. tostring(stateError))
				return nil, "StateSnapshotFailed"
			end
			statefulCount = statefulCount + 1
		elseif itemId == "GardenPlot" then
			local stateError
			state, stateError = CropService:GetPersistentState(candidate)
			if not state then
				warn("[StatePersistence] Crop capture failed for " .. structureId .. ": " .. tostring(stateError))
				return nil, "StateSnapshotFailed"
			end
			statefulCount = statefulCount + 1
		elseif itemId == "Recycler" or itemId == "IndustrialPress" or itemId == "Factory" then
			local stateError
			state, stateError = FactoryService:GetPersistentState(candidate)
			if not state then
				warn("[StatePersistence] Factory capture failed for " .. structureId .. ": " .. tostring(stateError))
				return nil, "StateSnapshotFailed"
			end
			statefulCount = statefulCount + 1
		end
		local record = {
			StructureId = structureId,
			ItemId = itemId,
			StructureType = itemId,
			OwnerUserId = ownerUserId,
			Pivot = pivot,
			Attributes = attributes,
		}
		if state then record.State = state end
		table.insert(snapshot, record)
		if #snapshot > PersistenceConfig.MAX_PERSISTENT_STRUCTURES then
			warn("[BuildingPersistence] Snapshot exceeds technical structure limit")
			return nil, "StructureLimitExceeded"
		end
	end
	if #snapshot >= PersistenceConfig.STRUCTURE_COUNT_WARNING then
		warn(string.format("[BuildingPersistence] Structure count approaching technical limit: %d/%d", #snapshot, PersistenceConfig.MAX_PERSISTENT_STRUCTURES))
	end
	local encoded, json = pcall(function()
		return HttpService:JSONEncode(snapshot)
	end)
	if not encoded or #json > PersistenceConfig.MAX_STRUCTURE_SNAPSHOT_BYTES then
		warn("[BuildingPersistence] Snapshot encoding failed or exceeds technical byte limit")
		return nil, "StructureSnapshotTooLarge"
	end
	if #json >= PersistenceConfig.STRUCTURE_SNAPSHOT_BYTES_WARNING then
		warn(string.format("[BuildingPersistence] Snapshot size approaching technical limit: %d/%d bytes", #json, PersistenceConfig.MAX_STRUCTURE_SNAPSHOT_BYTES))
	end
	print(string.format("[BuildingPersistence] structures serialized = %d, approximate bytes = %d", #snapshot, #json))
	print("[StatePersistence] structure states captured = " .. tostring(statefulCount))
	return snapshot
end

function BuildingService:ClearWorldStructures()
	FactoryService:ClearWorldMachineRuntime()
	local placedFolder = workspace:FindFirstChild("PlacedStructures")
	if not placedFolder then
		return
	end
	local structures = {}
	for _, candidate in placedFolder:GetDescendants() do
		if candidate:IsA("Model") and candidate:GetAttribute("StructureId") then
			table.insert(structures, candidate)
		end
	end
	for _, structure in structures do
		if structure.Parent then
			local itemId = structure:GetAttribute("ItemId")
			if itemId == "Door" then
				DoorService:UnregisterDoor(structure)
			end
			if itemId == "Boat" then
				BoatService:UnregisterBoat(structure)
			end
			StationService:UnregisterStation(structure)
			structure:Destroy()
		end
	end
	self._dismantleHits = setmetatable({}, {__mode = "k"})
	local buildingsFolder = placedFolder:FindFirstChild("Buildings") or Instance.new("Folder")
	buildingsFolder.Name = "Buildings"
	buildingsFolder.Parent = placedFolder
	print("[BuildingPersistence] runtime structures cleared = " .. tostring(#structures))
end

function BuildingService:RestoreFinalWorldState(worldState)
	FactoryService:RestoreFinalWorldState(worldState)
end

function BuildingService:RestorePersistentSnapshot(snapshot, structuresVersion)
	if structuresVersion ~= nil and structuresVersion ~= 1 and structuresVersion ~= STRUCTURES_VERSION then
		return false, "UnsupportedStructuresVersion"
	end
	if snapshot == nil then
		snapshot = {}
	end
	if typeof(snapshot) ~= "table" or #snapshot > PersistenceConfig.MAX_PERSISTENT_STRUCTURES
		or not isDenseArray(snapshot, #snapshot)
	then
		return false, "InvalidStructuresSnapshot"
	end

	self:ClearWorldStructures()
	local records = {}
	local knownIds = {}
	for index, saved in ipairs(snapshot) do
		local structureId = typeof(saved) == "table" and saved.StructureId or nil
		local itemId = typeof(saved) == "table" and saved.ItemId or nil
		local ownerUserId = typeof(saved) == "table" and saved.OwnerUserId or nil
		local pivot = typeof(saved) == "table" and deserializeCFrame(saved.Pivot) or nil
		local attributes = typeof(saved) == "table" and saved.Attributes or nil
		if not isValidStructureId(structureId)
			or knownIds[structureId]
			or typeof(itemId) ~= "string"
			or saved.StructureType ~= itemId
			or not PlaceableDefinitions[itemId]
			or not self._templates[itemId]
			or typeof(ownerUserId) ~= "number"
			or not isFiniteNumber(ownerUserId)
			or ownerUserId ~= math.floor(ownerUserId)
			or not pivot
			or typeof(attributes) ~= "table"
		then
			warn("[BuildingPersistence] skipped invalid structure at index " .. tostring(index))
			continue
		end
		local validAttributes = true
		for attributeName, value in attributes do
			if not table.find(PERSISTED_ATTRIBUTES, attributeName)
				or not isPersistableAttribute(value)
				or (typeof(value) == "number" and not isFiniteNumber(value))
			then
				validAttributes = false
				break
			end
		end
		if not validAttributes then
			warn("[BuildingPersistence] skipped structure with invalid attributes: " .. structureId)
			continue
		end
		local created, model = pcall(function()
			return self:_createStructure(itemId, pivot)
		end)
		if not created or not model then
			warn("[BuildingPersistence] template clone failed for " .. itemId)
			continue
		end
		knownIds[structureId] = true
		model.Name = itemId
		model:SetAttribute("ItemId", itemId)
		model:SetAttribute("StructureId", structureId)
		model:SetAttribute("StructureType", itemId)
		model:SetAttribute("SnapType", PlaceableDefinitions[itemId].PlacementType)
		model:SetAttribute("OwnerUserId", ownerUserId)
		if itemId == "Chest" then
			for _, descendant in model:GetDescendants() do
				if descendant:IsA("BasePart") then
					descendant.CanQuery = true
					descendant:SetAttribute("StructureId", structureId)
					descendant:SetAttribute("StructureType", "Chest")
				end
			end
		end
		local placedFolder = workspace.PlacedStructures
		model.Parent = PlaceableDefinitions[itemId].PlacementType and placedFolder.Buildings or placedFolder
		table.insert(records, {Model = model, ItemId = itemId, Attributes = attributes, State = saved.State})
	end

	if #snapshot > 0 and #records == 0 then
		self:ClearWorldStructures()
		return false, "NoStructuresRestored"
	end

	for _, record in records do
		for attributeName, value in record.Attributes do
			if (attributeName == "ParentStructureId" or attributeName == "StructureRootId")
				and typeof(value) == "string" and not knownIds[value]
			then
				warn("[BuildingPersistence] ignored missing relation " .. attributeName .. " = " .. value)
			else
				record.Model:SetAttribute(attributeName, value)
			end
		end
	end

	for _, record in records do
		local registered, registerError = pcall(function()
			self:_registerRuntimeStructure(record.Model, record.ItemId)
		end)
		if not registered then
			warn("[BuildingPersistence] runtime registration failed for " .. record.Model:GetAttribute("StructureId") .. ": " .. tostring(registerError))
		end
		record.Model:SetAttribute("PersistentReady", true)
	end
	local statesRestored = 0
	local structuresRecovered = 0
	local structuresFailed = 0
	for _, record in records do
		local state = record.State
		local requiresState = structuresVersion == STRUCTURES_VERSION
			and (record.ItemId == "Chest" or record.ItemId == "CraftingTable" or record.ItemId == "AutomaticLoader"
				or record.ItemId == "Campfire" or record.ItemId == "Smelt" or record.ItemId == "GardenPlot")
		if state == nil then
			if requiresState then
				self:ClearWorldStructures()
				return false, "MissingStructureState"
			end
			continue
		end
		local restored, stateError, restoreInfo
		if record.ItemId == "Chest" or record.ItemId == "CraftingTable" or record.ItemId == "AutomaticLoader" or record.ItemId == "Campfire" or record.ItemId == "Smelt" then
			restored, stateError, restoreInfo = StationService:RestorePersistentState(record.Model, state)
		elseif record.ItemId == "GardenPlot" then
			restored, stateError = CropService:RestorePersistentState(record.Model, state)
		elseif record.ItemId == "Recycler" or record.ItemId == "IndustrialPress" or record.ItemId == "Factory" then
			restored, stateError, restoreInfo = FactoryService:RestorePersistentState(record.Model, state)
		else
			self:ClearWorldStructures()
			return false, "UnexpectedStructureState"
		end
		if not restored then
			structuresFailed = structuresFailed + 1
			warn("[StatePersistence] Restore failed for " .. record.Model:GetAttribute("StructureId") .. ": " .. tostring(stateError))
			print(string.format(
				"[MAYDEAD][PERSISTENCE] World restoration failed StructuresLoaded=%d StructuresRecovered=%d StructuresFailed=%d",
				#records,
				structuresRecovered,
				structuresFailed
			))
			self:ClearWorldStructures()
			return false, "InvalidStructureState"
		end
		if restoreInfo and (restoreInfo.Recovered or restoreInfo.Migrated) then
			structuresRecovered = structuresRecovered + 1
		end
		statesRestored = statesRestored + 1
	end
	self:_refreshCeilingSupportMetadata()
	print(string.format("[BuildingPersistence] structures loaded = %d, spawned = %d", #snapshot, #records))
	print("[StatePersistence] structure states restored = " .. tostring(statesRestored))
	print(string.format(
		"[MAYDEAD][PERSISTENCE] World restoration completed StructuresLoaded=%d StructuresRecovered=%d StructuresFailed=%d",
		#records,
		structuresRecovered,
		structuresFailed
	))
	return true, #records
end

function BuildingService:Start(openWorkbench)
	if typeof(openWorkbench) ~= "Instance"
		or not openWorkbench:IsA("RemoteEvent")
		or openWorkbench.Name ~= "OpenWorkbench"
		or openWorkbench.Parent ~= ReplicatedStorage
	then
		error("BuildingService requires the published OpenWorkbench RemoteEvent")
	end
	self._openWorkbench = openWorkbench
	local placedFolder = workspace:FindFirstChild("PlacedStructures") or Instance.new("Folder")
	placedFolder.Name = "PlacedStructures"
	placedFolder.Parent = workspace
	local buildingsFolder = placedFolder:FindFirstChild("Buildings") or Instance.new("Folder")
	buildingsFolder.Name = "Buildings"
	buildingsFolder.Parent = placedFolder
	self:_loadTemplates()

	Players.PlayerRemoving:Connect(function(player)
		self._lastRequests[player] = nil
		self._lastDismantleRequests[player] = nil
		self._activePlacementItems[player] = nil
	end)
	self._request.OnServerEvent:Connect(function(player, itemId, requestData)
		if player:GetAttribute("SessionStarted") ~= true then return end
		self:_handleRequest(player, itemId, requestData)
	end)
	self._dismantleRequest.OnServerEvent:Connect(function(player, target)
		if player:GetAttribute("SessionStarted") ~= true then return end
		self:_handleDismantleRequest(player, target)
	end)
end

return BuildingService.new()
