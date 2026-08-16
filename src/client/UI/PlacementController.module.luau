local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local DEPENDENCY_TIMEOUT = 5

local function requireChild(parent, childName)
	local child = parent:WaitForChild(childName, DEPENDENCY_TIMEOUT)
	if not child then
		error("[MAYDEAD] PlacementController dependency timed out: " .. childName, 0)
	end
	return child
end

local SharedFolder = requireChild(ReplicatedStorage, "Shared")
local DefinitionsFolder = requireChild(SharedFolder, "Definitions")
local BuildingSnapGeometry = require(requireChild(SharedFolder, "BuildingSnapGeometry"))
local BuildingConfig = require(requireChild(requireChild(SharedFolder, "Config"), "BuildingConfig"))
local InventoryConfig = require(requireChild(requireChild(SharedFolder, "Config"), "InventoryConfig"))
local ItemDefinitions = require(requireChild(DefinitionsFolder, "ItemDefinitions"))
local PlaceableDefinitions = require(requireChild(DefinitionsFolder, "PlaceableDefinitions"))
local previewTemplates = requireChild(ReplicatedStorage, "PlacementPreviews")
local inventoryControllerModule = script.Parent:FindFirstChild("InventoryController")
	or script.Parent:FindFirstChild("InventoryController.module")
if not inventoryControllerModule or not inventoryControllerModule:IsA("ModuleScript") then
	error("[MAYDEAD] PlacementController dependency missing: InventoryController.module", 0)
end
local InventoryController = require(inventoryControllerModule)
local inventoryRemote = requireChild(ReplicatedStorage, "InventoryStateChanged")
local placementRequest = requireChild(ReplicatedStorage, "PlacementRequest")
local placementResult = requireChild(ReplicatedStorage, "PlacementResult")

local CONFIRM_ACTION = "MAYDEAD_ConfirmPlacement"
local CANCEL_ACTION = "MAYDEAD_CancelPlacement"
local ROTATE_ACTION = "MAYDEAD_RotatePlacement"
local PLACEMENT_PRIORITY = Enum.ContextActionPriority.High.Value + 25
local FLOOR_SIDES = {
	{Name = "North", Opposite = "South", Direction = Vector3.new(0, 0, -1), Yaw = 0},
	{Name = "South", Opposite = "North", Direction = Vector3.new(0, 0, 1), Yaw = math.pi},
	{Name = "East", Opposite = "West", Direction = Vector3.new(1, 0, 0), Yaw = -math.pi / 2},
	{Name = "West", Opposite = "East", Direction = Vector3.new(-1, 0, 0), Yaw = math.pi / 2},
}
local CURVED_FLOOR_EDGES = {
	{Name = "StraightEdgeA", Direction = PlaceableDefinitions.QuarterCircleCeiling.StraightEdgeA},
	{Name = "StraightEdgeB", Direction = PlaceableDefinitions.QuarterCircleCeiling.StraightEdgeB},
}

local function isFloorPlacementType(placementType)
	return placementType == "Floor" or placementType == "CurvedFloor"
end

local function isFloorStructureType(structureType)
	return structureType == "Ceiling" or structureType == "QuarterCircleCeiling"
end

local controller = {
	Started = false,
	ActiveItemId = nil,
	ActivePlacementItemId = nil,
	PlacementPending = false,
	PlacementCancelled = false,
	LastInventoryState = nil,
	Preview = nil,
	PreviewHighlight = nil,
	PlacementFeedback = nil,
	PreviewCFrame = nil,
	PreviewValid = false,
	PreviewSize = nil,
	PreviewBoxToPivot = nil,
	ActiveSnap = nil,
	LastLoggedSnapKey = nil,
	RotationYaw = 0,
	RotationIndex = 0,
	RenderConnection = nil,
	WallThickness = nil,
}

local function getActiveItem(state)
	local activeQuickSlot = state and state.ActiveQuickSlot or 0
	if activeQuickSlot < 1 or activeQuickSlot > InventoryConfig.QUICK_SLOT_COUNT then
		return nil
	end
	local slot = state.Slots and state.Slots[InventoryConfig.MAIN_SLOT_COUNT + activeQuickSlot]
	return slot and slot.ItemId or nil
end

local function getPlacementBox(model)
	local size = model:GetAttribute("PlacementBoxSize")
	local boxToPivot = model:GetAttribute("PlacementBoxToPivot")
	if typeof(size) == "Vector3" and typeof(boxToPivot) == "CFrame" then
		return model:GetPivot() * boxToPivot:Inverse(), size
	end
	return model:GetBoundingBox()
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

function controller:_setPreviewState(valid, invalidReason)
	self.PreviewValid = valid
	if self.PreviewHighlight then
		local color = valid and Color3.fromRGB(74, 194, 124) or Color3.fromRGB(224, 77, 77)
		self.PreviewHighlight.FillColor = color
		self.PreviewHighlight.OutlineColor = color
	end
	if self.PlacementFeedback then
		self.PlacementFeedback.Enabled = valid or invalidReason == "InsufficientSupport"
		local label = self.PlacementFeedback:FindFirstChild("Instruction", true)
		local stroke = self.PlacementFeedback:FindFirstChildWhichIsA("UIStroke", true)
		if label then
			label.Text = valid
				and '<font color="#4AC27C">✓  PLACER</font>\n<font size="11" color="#D7E2DD">CLIC GAUCHE</font>'
				or '<font color="#E04D4D">SUPPORT INSUFFISANT</font>'
		end
		if stroke then
			stroke.Color = valid and Color3.fromRGB(74, 194, 124) or Color3.fromRGB(224, 77, 77)
		end
	end
	local confirmButton = ContextActionService:GetButton(CONFIRM_ACTION)
	if confirmButton then
		confirmButton.Active = valid
		confirmButton.AutoButtonColor = valid
		confirmButton.ImageTransparency = valid and 0 or 0.45
	end
end

local function createPlacementFeedback(preview, previewBoxCFrame, previewSize)
	local adornee = preview:FindFirstChildWhichIsA("BasePart", true)
	if not adornee then
		return nil
	end
	local anchor = Instance.new("Attachment")
	anchor.Name = "PlacementFeedbackAnchor"
	anchor.Position = adornee.CFrame:PointToObjectSpace(previewBoxCFrame.Position)
	anchor.Parent = adornee

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlacementFeedback"
	billboard.Adornee = anchor
	billboard.AlwaysOnTop = true
	billboard.Enabled = false
	billboard.LightInfluence = 0
	billboard.MaxDistance = 45
	billboard.Size = UDim2.fromOffset(154, 48)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, previewSize.Y / 2 + 1.25, 0)
	billboard.Parent = preview

	local capsule = Instance.new("Frame")
	capsule.Name = "Capsule"
	capsule.BackgroundColor3 = Color3.fromRGB(18, 24, 22)
	capsule.BackgroundTransparency = 0.18
	capsule.BorderSizePixel = 0
	capsule.Size = UDim2.fromScale(1, 1)
	capsule.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = capsule

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(74, 194, 124)
	stroke.Transparency = 0.28
	stroke.Thickness = 1
	stroke.Parent = capsule

	local label = Instance.new("TextLabel")
	label.Name = "Instruction"
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.RichText = true
	label.Size = UDim2.fromScale(1, 1)
	label.Text = '<font color="#4AC27C">✓  PLACER</font>\n<font size="11" color="#D7E2DD">CLIC GAUCHE</font>'
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 15
	label.TextWrapped = true
	label.Parent = capsule

	return billboard
end

function controller:_pivotPreview(groundCFrame)
	local targetBoxCFrame = groundCFrame * CFrame.new(0, self.PreviewSize.Y / 2, 0)
	self.Preview:PivotTo(targetBoxCFrame * self.PreviewBoxToPivot)
	return targetBoxCFrame
end

function controller:_pivotPreviewBox(targetBoxCFrame)
	self.Preview:PivotTo(targetBoxCFrame * self.PreviewBoxToPivot)
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

local function findStructureById(structureId)
	local placedFolder = workspace:FindFirstChild("PlacedStructures")
	if not placedFolder or typeof(structureId) ~= "string" then
		return nil
	end
	for _, candidate in placedFolder:GetDescendants() do
		if candidate:IsA("Model") and candidate:GetAttribute("StructureId") == structureId then
			return candidate
		end
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

function controller:_findSnapCandidate(position, definition, rayOrigin, rayDirection)
	local placedFolder = workspace:FindFirstChild("PlacedStructures")
	if not placedFolder then
		return nil
	end
	local best
	local sticky
	local snapOffset = definition.SnapOffset or Vector3.zero
	local function getSearchDistance(candidate)
		local capturePosition = candidate.CapturePosition or candidate.TargetBox.Position
		if position then
			return (capturePosition - position).Magnitude
		end
		local alongRay = math.clamp(
			(capturePosition - rayOrigin):Dot(rayDirection),
			0,
			BuildingConfig.PLACEMENT_RAY_LENGTH
		)
		return (capturePosition - (rayOrigin + rayDirection * alongRay)).Magnitude
	end
	local function getHorizontalSupportDistance(support, side)
		local direction
		if typeof(side) == "Vector3" then
			direction = side
		elseif typeof(side) == "CFrame" then
			direction = side.LookVector
		elseif type(side) == "table" and typeof(side.Direction) == "Vector3" then
			direction = side.Direction
		else
			warn("[MAYDEAD] Invalid horizontal support direction type: " .. typeof(side))
			return 2
		end
		local level = support:GetAttribute("StructureLevel") or 0
		if level <= 0 then
			return 0
		end
		local rootId = support:GetAttribute("StructureRootId")
		local gridX = (support:GetAttribute("GridX") or 0) + direction.X
		local gridZ = (support:GetAttribute("GridZ") or 0) + direction.Z
		for _, ceiling in placedFolder:GetDescendants() do
			if ceiling:IsA("Model") and isFloorStructureType(ceiling:GetAttribute("StructureType")) then
				if ceiling:GetAttribute("StructureRootId") == rootId
					and ceiling:GetAttribute("StructureLevel") == level - 1
					and ceiling:GetAttribute("GridX") == gridX
					and ceiling:GetAttribute("GridZ") == gridZ
					and hasAttachedWall(placedFolder, ceiling)
				then
					return 0
				end
				if ceiling:GetAttribute("SupportDirect")
					and ceiling:GetAttribute("StructureRootId") == rootId
					and ceiling:GetAttribute("StructureLevel") == level
				then
					local distance = math.abs((ceiling:GetAttribute("GridX") or 0) - gridX)
						+ math.abs((ceiling:GetAttribute("GridZ") or 0) - gridZ)
					if distance == 1 then
						return 1
					end
				end
			end
		end
		return 2
	end
	local function consider(candidate)
		candidate.Distance = getSearchDistance(candidate)
		local sameAsActive = self.ActiveSnap
			and self.ActiveSnap.TargetStructureId == candidate.TargetStructureId
			and self.ActiveSnap.SnapId == candidate.SnapId
		if sameAsActive
			and candidate.Distance <= math.max(definition.SnapReleaseDistance, BuildingConfig.SNAP_SEARCH_RADIUS)
		then
			sticky = candidate
		elseif candidate.Distance <= BuildingConfig.SNAP_SEARCH_RADIUS
			and (not best or candidate.Distance < best.Distance)
		then
			best = candidate
		end
	end
	for _, support in placedFolder:GetDescendants() do
		if not support:IsA("Model") then
			continue
		end
		local supportType = support:GetAttribute("StructureType")
		local supportDefinition = PlaceableDefinitions[supportType]
		local insertSupportMatches = (definition.PlacementType == "WindowInsert" and supportType == "WindowWall")
			or (definition.PlacementType == "DoorInsert" and supportType == "DoorWall")
		if insertSupportMatches then
			local structureId = support:GetAttribute("StructureId")
			if typeof(structureId) == "string" then
				local supportBox, supportSize = getPlacementBox(support)
				local targetBox = self.ActiveItemId == "Door"
					and BuildingSnapGeometry.GetDoorInsertSnapCFrame(
						supportBox,
						supportSize,
						self.PreviewSize,
						snapOffset
					)
					or BuildingSnapGeometry.GetInsertSnapCFrame(supportBox, snapOffset)
				consider({
					Support = support,
					TargetStructureId = structureId,
					SnapId = "Insert",
					Mode = "Insert",
					Side = "Insert",
					TargetBox = targetBox,
					OccupancyAttribute = self.ActiveItemId .. "Occupied",
				})
			end
		end
		if isFloorPlacementType(definition.PlacementType)
			and supportDefinition
			and supportDefinition.SupportsCeilingTop == true
		then
			local wallStructureId = support:GetAttribute("StructureId")
			local parentCeiling = findStructureById(support:GetAttribute("ParentStructureId"))
			if typeof(wallStructureId) == "string" and parentCeiling then
				local wallBox, wallSize = getPlacementBox(support)
				local parentBox = getPlacementBox(parentCeiling)
				local wallTopPosition = wallBox.Position + Vector3.new(0, wallSize.Y / 2, 0)
				local targetPosition = Vector3.new(
					parentBox.Position.X,
					wallBox.Position.Y + wallSize.Y / 2 + self.PreviewSize.Y / 2,
					parentBox.Position.Z
				)
				local target = parentBox + (targetPosition - parentBox.Position)
				consider({
					Support = parentCeiling,
					TargetWall = support,
					TargetStructureId = wallStructureId,
					SnapId = "WallTop",
					Mode = "Upper",
					SourceMode = "WallTop",
					Side = "Upper",
					TargetBox = target,
					CapturePosition = wallTopPosition,
					Distance = 0,
					HasStructuralSupport = true,
					SupportDistance = 0,
				})
			end
		end
		if supportType == "QuarterCircleCeiling" then
			local supportBox, supportSize = getPlacementBox(support)
			local structureId = support:GetAttribute("StructureId")
			if typeof(structureId) ~= "string" then
				continue
			end
			if isFloorPlacementType(definition.PlacementType) then
				for _, edge in CURVED_FLOOR_EDGES do
					local worldDirection = supportBox:VectorToWorldSpace(edge.Direction)
					local gridDirection = Vector3.new(
						math.round(worldDirection.X),
						0,
						math.round(worldDirection.Z)
					)
					local target = BuildingSnapGeometry.GetFloorEdgeSnapCFrame(
						supportBox,
						supportSize,
						edge.Direction,
						self.PreviewSize,
						Vector3.new(0, 0, -1),
						snapOffset
					)
					consider({
						Support = support,
						TargetStructureId = structureId,
						SnapId = edge.Name,
						Mode = "Horizontal",
						Side = edge.Name,
						TargetBox = target,
						OccupancyAttribute = edge.Name .. "Occupied",
						SupportDistance = getHorizontalSupportDistance(support, gridDirection),
					})
				end
			elseif definition.PlacementType == "CurvedWall" then
				consider({
					Support = support,
					TargetStructureId = structureId,
					SnapId = "CurvedEdge",
					Mode = "CurvedWall",
					Side = "CurvedEdge",
					TargetBox = BuildingSnapGeometry.GetCurvedWallSnapCFrame(
						supportBox,
						supportSize,
						self.PreviewSize,
						snapOffset,
						definition.OrientationOffset
					),
					OccupancyAttribute = "CurvedEdgeOccupied",
				})
			end
			continue
		end
		if supportType ~= "Ceiling" then
			continue
		end
		local supportBox, supportSize = getPlacementBox(support)
		local structureId = support:GetAttribute("StructureId")
		if typeof(structureId) ~= "string" then
			continue
		end
		if isFloorPlacementType(definition.PlacementType) then
			local wallTemplate = previewTemplates:FindFirstChild("Wall")
			if not wallTemplate or not wallTemplate:IsA("Model") then
				return nil
			end
			local _, wallSize = getPlacementBox(wallTemplate)
			for _, side in FLOOR_SIDES do
				local supportGridDirection = side
				if definition.PlacementType == "CurvedFloor" then
					local worldDirection = supportBox:VectorToWorldSpace(side.Direction)
					supportGridDirection = Vector3.new(
						math.round(worldDirection.X),
						0,
						math.round(worldDirection.Z)
					)
				end
				local target = definition.PlacementType == "CurvedFloor"
					and BuildingSnapGeometry.GetFloorEdgeSnapCFrame(
						supportBox,
						supportSize,
						side.Direction,
						self.PreviewSize,
						Vector3.new(0, 0, -1),
						snapOffset
					)
					or (supportBox * CFrame.new(Vector3.new(
						side.Direction.X * (supportSize.X / 2 + self.PreviewSize.X / 2),
						0,
						side.Direction.Z * (supportSize.Z / 2 + self.PreviewSize.Z / 2)
					)) * CFrame.new(snapOffset))
				consider({
						Support = support,
						TargetStructureId = structureId,
						SnapId = definition.PlacementType == "CurvedFloor" and ("QuarterFloor" .. side.Name)
							or ("Floor" .. side.Name),
						Mode = "Horizontal",
						Side = side.Name,
						Opposite = side.Opposite,
						TargetBox = target,
						Distance = 0,
						SupportDistance = getHorizontalSupportDistance(support, supportGridDirection),
					})
			end
			local upperTarget = supportBox * CFrame.new(
				0,
				supportSize.Y / 2 + wallSize.Y + self.PreviewSize.Y / 2,
				0
			) * CFrame.new(snapOffset)
			consider({
					Support = support,
					TargetStructureId = structureId,
					SnapId = "Upper",
					Mode = "Upper",
					Side = "Upper",
					TargetBox = upperTarget,
					Distance = 0,
					HasStructuralSupport = hasAttachedWall(placedFolder, support),
					SupportDistance = hasAttachedWall(placedFolder, support) and 0 or 2,
				})
		elseif definition.PlacementType == "Stairs" then
			for _, side in FLOOR_SIDES do
				local target = BuildingSnapGeometry.GetStairsSnapCFrame(
					supportBox,
					supportSize,
					self.PreviewSize,
					side.Yaw,
					snapOffset
				)
				consider({
					Support = support,
					TargetStructureId = structureId,
					SnapId = "Stairs" .. side.Name,
					Mode = "Stairs",
					Side = side.Name,
					TargetBox = target,
					CapturePosition = supportBox:PointToWorldSpace(Vector3.new(
						side.Direction.X * supportSize.X / 2,
						supportSize.Y / 2,
						side.Direction.Z * supportSize.Z / 2
					)),
				})
			end
		elseif definition.PlacementType == "Wall" then
			if not self.WallThickness then
				local wallThickness = previewTemplates:GetAttribute("WallThickness")
				if typeof(wallThickness) ~= "number" then
					local wallTemplate = previewTemplates:FindFirstChild("Wall")
					if not wallTemplate or not wallTemplate:IsA("Model") then
						return nil
					end
					local _, wallSize = getPlacementBox(wallTemplate)
					wallThickness = math.min(wallSize.X, wallSize.Z)
				end
				self.WallThickness = wallThickness
			end
			for _, side in FLOOR_SIDES do
				local target = BuildingSnapGeometry.GetWallSnapCFrame(
					supportBox,
					supportSize,
					self.PreviewSize,
					side.Direction,
					side.Yaw,
					self.WallThickness,
					snapOffset
				)
				consider({
					Support = support,
					TargetStructureId = structureId,
					SnapId = "Wall" .. side.Name,
					Mode = "Wall",
					Side = side.Name,
					TargetBox = target,
					Distance = 0,
				})
			end
		end
	end
	return sticky or best
end

function controller:_isSnapBoxClear(character, snap)
	local parameters = OverlapParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character, self.Preview}
	local epsilon = BuildingConfig.STRUCTURE_COLLISION_EPSILON
	for _, part in workspace:GetPartBoundsInBox(snap.TargetBox, Vector3.new(
		math.max(0.2, self.PreviewSize.X - epsilon * 2),
		math.max(0.2, self.PreviewSize.Y - epsilon * 2),
		math.max(0.2, self.PreviewSize.Z - epsilon * 2)
	), parameters) do
		if part.CanCollide or isPlayerCharacterPart(part) then
			local structure = getStructureModel(part)
			local isCompatibleCornerWall = snap.Mode == "Wall"
				and structure
				and isWallStructureType(structure:GetAttribute("StructureType"))
				and structure:GetAttribute("ParentStructureId") == snap.Support:GetAttribute("StructureId")
			local sameSupport = structure == snap.Support
				or (snap.Mode == "Upper"
					and structure
					and structure:GetAttribute("ParentStructureId") == snap.Support:GetAttribute("StructureId"))
				or isCompatibleCornerWall
			if not sameSupport then
				return false
			end
		end
	end
	return true
end

function controller:_hasFullSupport(character, groundCFrame, definition)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character, self.Preview}
	parameters.IgnoreWater = false
	local extentX = self.PreviewSize.X * 0.38
	local extentZ = self.PreviewSize.Z * 0.38
	for _, offset in ipairs({
		Vector3.zero,
		Vector3.new(extentX, 0, extentZ),
		Vector3.new(extentX, 0, -extentZ),
		Vector3.new(-extentX, 0, extentZ),
		Vector3.new(-extentX, 0, -extentZ),
	}) do
		local origin = groundCFrame:PointToWorldSpace(offset) + Vector3.new(0, 2, 0)
		local support = workspace:Raycast(origin, Vector3.new(0, -4, 0), parameters)
		if not isSolidGround(support)
			or isHarvestResource(support.Instance)
			or support.Normal.Y < math.cos(math.rad(definition.MaxSlopeDegrees))
			or math.abs(support.Position.Y - groundCFrame.Position.Y) > definition.MaxSupportGap
		then
			return false
		end
	end
	return true
end

function controller:_hasWaterSupport(character, groundCFrame)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character, self.Preview}
	parameters.IgnoreWater = false
	local extentX = self.PreviewSize.X * 0.38
	local extentZ = self.PreviewSize.Z * 0.38
	for _, offset in ipairs({
		Vector3.zero,
		Vector3.new(extentX, 0, extentZ),
		Vector3.new(extentX, 0, -extentZ),
		Vector3.new(-extentX, 0, extentZ),
		Vector3.new(-extentX, 0, -extentZ),
	}) do
		local origin = groundCFrame:PointToWorldSpace(offset) + Vector3.new(0, 2, 0)
		local support = workspace:Raycast(origin, Vector3.new(0, -4, 0), parameters)
		if not isWaterSurface(support) then
			return false
		end
	end
	return true
end

function controller:_applySnapPreview(snap, definition, rootPart, character)
	local targetBox = snap.TargetBox
	if self.ActiveItemId == "QuarterCircleCeiling" then
		targetBox = targetBox * CFrame.Angles(0, self.RotationIndex * math.pi / 2, 0)
	end
	self:_pivotPreviewBox(targetBox)
	self.PreviewCFrame = targetBox
	local occupied = (snap.Mode == "Upper" and snap.Support:GetAttribute("UpperFloorOccupied"))
		or (snap.Mode == "Horizontal" and snap.Support:GetAttribute(snap.Side .. "FloorOccupied"))
		or (snap.Mode == "Wall" and snap.Support:GetAttribute(snap.Side .. "WallOccupied"))
		or (snap.Mode == "Stairs" and snap.Support:GetAttribute(snap.Side .. "StairsOccupied"))
		or (snap.Mode == "Insert" and snap.Support:GetAttribute(snap.OccupancyAttribute))
		or (snap.Mode == "CurvedWall" and snap.Support:GetAttribute("CurvedEdgeOccupied"))
	if snap.OccupancyAttribute then
		occupied = snap.Support:GetAttribute(snap.OccupancyAttribute)
	end
	local activeDefinition = self.ActiveItemId and PlaceableDefinitions[self.ActiveItemId]
	local supported = not (activeDefinition and isFloorPlacementType(activeDefinition.PlacementType))
		or (snap.SupportDistance or 0) <= 1
	local valid = not occupied
		and supported
		and (rootPart.Position - targetBox.Position).Magnitude <= BuildingConfig.MAX_PLACEMENT_DISTANCE
		and self:_isSnapBoxClear(character, {
			TargetBox = targetBox,
			Support = snap.Support,
			Mode = snap.Mode,
		})
	self.ActiveSnap = valid and snap or nil
	if valid and self.ActiveItemId == "Ceiling" then
		local snapKey = snap.TargetStructureId .. ":" .. snap.SnapId
		if self.LastLoggedSnapKey ~= snapKey then
			print("[MAYDEAD] Ceiling snap candidate = " .. snapKey)
			if snap.SourceMode == "WallTop" then
				print("[MAYDEAD] Ceiling snapped to wall = " .. snap.TargetStructureId)
			elseif snap.Mode == "Horizontal" then
				print("[MAYDEAD] Ceiling snapped to ceiling edge = " .. snap.SnapId)
			end
			print("[MAYDEAD] Snap position = " .. tostring(snap.TargetBox.Position))
			self.LastLoggedSnapKey = snapKey
		end
	elseif not valid then
		self.LastLoggedSnapKey = nil
	end
	self:_setPreviewState(valid, not supported and "InsufficientSupport" or nil)
end

function controller:_updatePreview()
	local camera = workspace.CurrentCamera
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local definition = self.ActiveItemId and PlaceableDefinitions[self.ActiveItemId]
	if not camera or not rootPart or not self.Preview or not definition then
		self:_setPreviewState(false)
		return
	end

	local screenPosition
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		screenPosition = camera.ViewportSize / 2
	else
		screenPosition = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
	end
	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {character, self.Preview}
	parameters.IgnoreWater = false
	local result = workspace:Raycast(
		ray.Origin,
		ray.Direction * BuildingConfig.PLACEMENT_RAY_LENGTH,
		parameters
	)
	local snap = definition.PlacementType
		and self:_findSnapCandidate(result and result.Position or nil, definition, ray.Origin, ray.Direction)
		or nil
	if snap then
		self:_applySnapPreview(snap, definition, rootPart, character)
		return
	end
	if not result then
		self.PreviewCFrame = nil
		self:_setPreviewState(false)
		return
	end

	if definition.PlacementType then
		if not isFloorPlacementType(definition.PlacementType) then
			self.ActiveSnap = nil
			local targetBox = self:_pivotPreview(CFrame.new(result.Position) * CFrame.Angles(0, self.RotationYaw, 0))
			self.PreviewCFrame = targetBox
			self:_setPreviewState(false)
			return
		end
	end
	self.ActiveSnap = nil
	self.LastLoggedSnapKey = nil

	local groundCFrame = CFrame.new(result.Position) * CFrame.Angles(0, self.RotationYaw, 0)
	local targetBoxCFrame = self:_pivotPreview(groundCFrame)
	self.PreviewCFrame = groundCFrame
	local waterOnly = definition.PlacementSurface == "Water"
	local valid = (waterOnly and isWaterSurface(result) or (not waterOnly and isSolidGround(result)))
		and not isHarvestResource(result.Instance)
		and (waterOnly or result.Normal.Y >= math.cos(math.rad(definition.MaxSlopeDegrees)))
		and (rootPart.Position - targetBoxCFrame.Position).Magnitude <= BuildingConfig.MAX_PLACEMENT_DISTANCE
		and (waterOnly and self:_hasWaterSupport(character, groundCFrame)
			or not waterOnly and self:_hasFullSupport(character, groundCFrame, definition))

	if valid then
		local groundStructure = getStructureModel(result.Instance)
		local overlapParameters = OverlapParams.new()
		overlapParameters.FilterType = Enum.RaycastFilterType.Exclude
		overlapParameters.FilterDescendantsInstances = {character, self.Preview}
		local overlapSize = Vector3.new(
			math.max(0.2, self.PreviewSize.X * 0.9),
			math.max(0.2, self.PreviewSize.Y - 0.15),
			math.max(0.2, self.PreviewSize.Z * 0.9)
		)
		for _, part in workspace:GetPartBoundsInBox(targetBoxCFrame * CFrame.new(0, 0.1, 0), overlapSize, overlapParameters) do
			local overlappingStructure = getStructureModel(part)
			if (part.CanCollide or isPlayerCharacterPart(part))
				and part ~= result.Instance
				and (not groundStructure or overlappingStructure ~= groundStructure)
			then
				valid = false
				break
			end
		end
	end
	self:_setPreviewState(valid)
end

function controller:_stopPlacement(clearActivePlacement)
	if clearActivePlacement == nil then
		clearActivePlacement = true
	end
	ContextActionService:UnbindAction(CONFIRM_ACTION)
	ContextActionService:UnbindAction(CANCEL_ACTION)
	ContextActionService:UnbindAction(ROTATE_ACTION)
	if self.RenderConnection then
		self.RenderConnection:Disconnect()
		self.RenderConnection = nil
	end
	if self.Preview then
		self.Preview:Destroy()
	end
	self.ActiveItemId = nil
	if clearActivePlacement then
		self.ActivePlacementItemId = nil
	end
	self.Preview = nil
	self.PreviewHighlight = nil
	self.PlacementFeedback = nil
	self.PreviewCFrame = nil
	self.PreviewValid = false
	self.PreviewSize = nil
	self.PreviewBoxToPivot = nil
	self.ActiveSnap = nil
	self.LastLoggedSnapKey = nil
end

function controller:_startPlacement(itemId)
	if self.ActiveItemId == itemId and self.Preview then
		return
	end
	self:_stopPlacement(false)
	local definition = PlaceableDefinitions[itemId]
	if not definition then
		warn("[MAYDEAD] " .. tostring(itemId) .. " preview unavailable: PlaceableDefinitions entry missing")
		return
	end
	local template = previewTemplates:FindFirstChild(itemId) or previewTemplates:WaitForChild(itemId, 5)
	if not template then
		warn("[MAYDEAD] " .. itemId .. " preview unavailable in ReplicatedStorage.PlacementPreviews")
		for _, child in previewTemplates:GetChildren() do
			warn("[MAYDEAD] PlacementPreviews child = " .. child.Name .. " (" .. child.ClassName .. ")")
		end
		return
	end
	if not template:IsA("Model") then
		warn("[MAYDEAD] " .. itemId .. " preview has invalid runtime class: " .. template.ClassName)
		return
	end
	if not template:FindFirstChildWhichIsA("BasePart", true) then
		warn("[MAYDEAD] " .. itemId .. " preview Model contains no BasePart")
		return
	end
	print("[MAYDEAD] Placement template = " .. template.Name)

	local preview = template:Clone()
	preview.Name = "MAYDEADPlacementPreview"
	for _, descendant in preview:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Transparency = 1 - ((1 - descendant.Transparency) * 0.48)
		end
	end
	preview.Parent = workspace
	local pivot = preview:GetPivot()
	local boxCFrame, boxSize = getPlacementBox(preview)
	if itemId == "Ceiling" then
		local horizontal = boxSize.Y <= boxSize.X and boxSize.Y <= boxSize.Z
		print("[MAYDEAD] Ceiling preview horizontal = " .. tostring(horizontal))
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "PlacementValidity"
	highlight.Adornee = preview
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 0.68
	highlight.OutlineTransparency = 0.12
	highlight.Parent = preview

	local camera = workspace.CurrentCamera
	local lookVector = camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1)
	local cameraYaw = math.atan2(-lookVector.X, -lookVector.Z)
	local step = math.rad(definition.RotationStepDegrees)
	self.RotationYaw = math.floor(cameraYaw / step + 0.5) * step
	local rotationCount = math.round(360 / definition.RotationStepDegrees)
	self.RotationIndex = math.round(self.RotationYaw / step) % rotationCount
	self.RotationYaw = self.RotationIndex * step
	self.ActiveItemId = itemId
	self.ActivePlacementItemId = itemId
	self.PlacementPending = false
	self.PlacementCancelled = false
	self.Preview = preview
	self.PreviewHighlight = highlight
	self.PlacementFeedback = createPlacementFeedback(preview, boxCFrame, boxSize)
	self.PreviewSize = boxSize
	self.PreviewBoxToPivot = boxCFrame:ToObjectSpace(pivot)

	ContextActionService:BindActionAtPriority(
		CONFIRM_ACTION,
		function(_, inputState)
			if InventoryController.Open then
				return Enum.ContextActionResult.Pass
			end
			if inputState == Enum.UserInputState.Begin and self.PreviewValid and self.PreviewCFrame then
				if self.PlacementPending then
					return Enum.ContextActionResult.Sink
				end
				self.PlacementPending = true
				placementRequest:FireServer(self.ActiveItemId, {
					CFrame = self.PreviewCFrame,
					RotationIndex = self.RotationIndex,
					TargetStructureId = self.ActiveSnap and self.ActiveSnap.TargetStructureId or nil,
					SnapId = self.ActiveSnap and self.ActiveSnap.SnapId or nil,
				})
			end
			return Enum.ContextActionResult.Sink
		end,
		true,
		PLACEMENT_PRIORITY,
		Enum.UserInputType.MouseButton1
	)
	ContextActionService:SetTitle(CONFIRM_ACTION, "PLACER")
	ContextActionService:SetPosition(CONFIRM_ACTION, UDim2.new(1, -190, 1, -160))

	ContextActionService:BindActionAtPriority(
		ROTATE_ACTION,
		function(_, inputState)
			if InventoryController.Open then
				return Enum.ContextActionResult.Pass
			end
			if inputState == Enum.UserInputState.Begin then
				self.RotationIndex = (self.RotationIndex + 1) % rotationCount
				self.RotationYaw = self.RotationIndex * step
			end
			return Enum.ContextActionResult.Sink
		end,
		true,
		PLACEMENT_PRIORITY,
		Enum.KeyCode.R
	)
	ContextActionService:SetTitle(ROTATE_ACTION, "TOURNER")
	ContextActionService:SetPosition(ROTATE_ACTION, UDim2.new(1, -115, 1, -160))

	ContextActionService:BindActionAtPriority(
		CANCEL_ACTION,
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				self:_cancelPlacement()
			end
			return Enum.ContextActionResult.Sink
		end,
		true,
		PLACEMENT_PRIORITY,
		Enum.KeyCode.Escape
	)
	ContextActionService:SetTitle(CANCEL_ACTION, "ANNULER")
	ContextActionService:SetPosition(CANCEL_ACTION, UDim2.new(1, -40, 1, -160))

	self.RenderConnection = RunService.RenderStepped:Connect(function()
		self:_updatePreview()
	end)
	print("[MAYDEAD] Placement preview started = " .. itemId)
end

function controller:_cancelPlacement()
	local activePlacementItemId = self.ActivePlacementItemId
	self.PlacementCancelled = true
	self.PlacementPending = false
	if activePlacementItemId then
		placementRequest:FireServer(activePlacementItemId, {Cancel = true})
	end
	self:_stopPlacement(true)
end

function controller:_handleInventory(state)
	self.LastInventoryState = state
	local itemId = getActiveItem(state)
	local definition = itemId and ItemDefinitions[itemId]
	if definition and definition.Placeable == true then
		if self.ActivePlacementItemId and self.ActivePlacementItemId ~= itemId then
			placementRequest:FireServer(self.ActivePlacementItemId, {Cancel = true})
		end
		if self.ActiveItemId ~= itemId then
			print("[MAYDEAD] Selected placeable = " .. itemId)
		end
		self:_startPlacement(itemId)
	elseif self.ActivePlacementItemId then
		placementRequest:FireServer(self.ActivePlacementItemId, {Cancel = true})
		self.PlacementCancelled = true
		self:_stopPlacement(true)
	end
end

local function getTotalItemQuantity(state, itemId)
	local total = 0
	for _, slot in (state and state.Slots or {}) do
		if slot.ItemId == itemId then
			total = total + (slot.Quantity or 0)
		end
	end
	return total
end

function controller:Start()
	if self.Started then
		return
	end
	self.Started = true
	inventoryRemote.OnClientEvent:Connect(function(state)
		self:_handleInventory(state)
	end)
	placementResult.OnClientEvent:Connect(function(success, itemId, reason, remainingQuantity)
		self.PlacementPending = false
		if self.PlacementCancelled or itemId ~= self.ActivePlacementItemId then
			return
		end
		if success then
			print("[MAYDEAD] Placement completed")
			local remaining = typeof(remainingQuantity) == "number"
				and remainingQuantity
				or getTotalItemQuantity(self.LastInventoryState, itemId)
			if remaining > 0 and self.ActivePlacementItemId == itemId then
				self:_stopPlacement(false)
				self:_startPlacement(itemId)
			else
				self:_stopPlacement(true)
			end
		else
			warn("[MAYDEAD] Placement rejected: " .. tostring(reason))
			if reason == "InsufficientSupport" then
				self.ActiveSnap = nil
				self:_setPreviewState(false, "InsufficientSupport")
			end
		end
	end)
	local function bindCharacter(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Died:Connect(function()
				self:_cancelPlacement()
			end)
		end
	end
	if player.Character then
		bindCharacter(player.Character)
	end
	player.CharacterAdded:Connect(bindCharacter)
	if InventoryController.Inventory then
		self:_handleInventory(InventoryController.Inventory)
	end
	print("[MAYDEAD] PlacementController started")
end

return controller
