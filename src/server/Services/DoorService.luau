local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local DoorService = {}
DoorService.__index = DoorService

local OPEN_ANGLE_MAGNITUDE = math.rad(90)
local ANIMATION_DURATION = 0.45
local INTERACTION_DISTANCE = 8
local BLADE_NAMES = {"door", "porte", "battant", "panel"}
local STRONG_BLADE_NAMES = {"battant", "panel", "leaf", "slab"}
local FRAME_NAMES = {"frame", "cadre", "jamb", "trim"}
local HINGE_NAMES = {"hinge", "charniere", "charnière"}
local HANDLE_NAMES = {"handle", "knob", "poignee", "poignée"}
local NON_PHYSICAL_NAMES = {
	"hingeroot",
	"hinge_root",
	"pivot",
	"root",
	"helper",
	"animationroot",
	"animation_root",
	"collisionroot",
	"collision_root",
}

local function containsName(name, fragments)
	local lowerName = string.lower(name)
	for _, fragment in fragments do
		if string.find(lowerName, fragment, 1, true) then
			return true
		end
	end
	return false
end

local function getBaseParts(root)
	local parts = {}
	if root:IsA("BasePart") then
		table.insert(parts, root)
	end
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function getPlacementBox(model)
	local size = model:GetAttribute("PlacementBoxSize")
	local boxToPivot = model:GetAttribute("PlacementBoxToPivot")
	if typeof(size) == "Vector3" and typeof(boxToPivot) == "CFrame" then
		return model:GetPivot() * boxToPivot:Inverse(), size
	end
	return model:GetBoundingBox()
end

local function selectMovingParts(door)
	local allParts = getBaseParts(door)
	if #allParts == 1 then
		print("[MAYDEAD] Door interactive audit: single-piece Door model")
		return allParts, "single BasePart"
	end

	for _, descendant in door:GetDescendants() do
		if descendant:IsA("Model")
			and containsName(descendant.Name, STRONG_BLADE_NAMES)
			and not containsName(descendant.Name, FRAME_NAMES)
		then
			local parts = getBaseParts(descendant)
			if #parts > 0 then
				return parts, "Model " .. descendant:GetFullName()
			end
		end
	end

	local namedParts = {}
	for _, part in allParts do
		if containsName(part.Name, STRONG_BLADE_NAMES) and not containsName(part.Name, FRAME_NAMES) then
			table.insert(namedParts, part)
		end
	end
	if #namedParts > 0 then
		return namedParts, #namedParts == 1 and ("BasePart " .. namedParts[1]:GetFullName()) or "named blade BaseParts"
	end

	for _, part in allParts do
		if containsName(part.Name, BLADE_NAMES) and not containsName(part.Name, FRAME_NAMES) then
			table.insert(namedParts, part)
		end
	end
	if #namedParts > 0 then
		return namedParts, #namedParts == 1 and ("BasePart " .. namedParts[1]:GetFullName()) or "named door BaseParts"
	end

	for _, descendant in door:GetDescendants() do
		if descendant:IsA("Model")
			and containsName(descendant.Name, BLADE_NAMES)
			and not containsName(descendant.Name, FRAME_NAMES)
		then
			local parts = getBaseParts(descendant)
			if #parts > 0 and #parts < #allParts then
				return parts, "Model " .. descendant:GetFullName()
			end
		end
	end

	local largestPanel
	local largestScore = -math.huge
	for _, part in allParts do
		local score = part.Size.Y * math.max(part.Size.X, part.Size.Z)
		if score > largestScore then
			largestScore = score
			largestPanel = part
		end
	end
	if largestPanel then
		return {largestPanel}, "largest vertical panel " .. largestPanel:GetFullName()
	end
	return {}, "no BasePart"
end

local function getLocalBounds(parts, referenceCFrame)
	local minimum = Vector3.new(math.huge, math.huge, math.huge)
	local maximum = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in parts do
		local halfSize = part.Size / 2
		for _, x in {-1, 1} do
			for _, y in {-1, 1} do
				for _, z in {-1, 1} do
					local worldCorner = part.CFrame:PointToWorldSpace(Vector3.new(
						halfSize.X * x,
						halfSize.Y * y,
						halfSize.Z * z
					))
					local corner = referenceCFrame:PointToObjectSpace(worldCorner)
					minimum = Vector3.new(
						math.min(minimum.X, corner.X),
						math.min(minimum.Y, corner.Y),
						math.min(minimum.Z, corner.Z)
					)
					maximum = Vector3.new(
						math.max(maximum.X, corner.X),
						math.max(maximum.Y, corner.Y),
						math.max(maximum.Z, corner.Z)
					)
				end
			end
		end
	end
	return minimum, maximum
end

local function findHingeAttachment(parts)
	for _, part in parts do
		for _, descendant in part:GetDescendants() do
			if descendant:IsA("Attachment") and containsName(descendant.Name, HINGE_NAMES) then
				return descendant
			end
		end
	end
	return nil
end

local function findHandlePosition(door)
	for _, descendant in door:GetDescendants() do
		if containsName(descendant.Name, HANDLE_NAMES) then
			if descendant:IsA("Attachment") then
				return descendant.WorldPosition, descendant:GetFullName()
			elseif descendant:IsA("BasePart") then
				return descendant.Position, descendant:GetFullName()
			end
		end
	end
	return nil, nil
end

local function containsPart(parts, expectedPart)
	for _, part in parts do
		if part == expectedPart then
			return true
		end
	end
	return false
end

local function addHandleParts(door, movingParts)
	for _, descendant in door:GetDescendants() do
		if descendant:IsA("BasePart")
			and containsName(descendant.Name, HANDLE_NAMES)
		then
			if descendant.CanCollide or descendant.CanTouch then
				print("[MAYDEAD] Door blocking part = " .. descendant:GetFullName())
			end
			descendant.CanCollide = false
			descendant.CanTouch = false
			if not containsPart(movingParts, descendant) then
				table.insert(movingParts, descendant)
			end
		end
	end
end

local function sanitizeNonPhysicalParts(door, movingParts)
	local _, doorSize = getPlacementBox(door)
	for _, part in getBaseParts(door) do
		local isRuntimeReference = containsName(part.Name, NON_PHYSICAL_NAMES)
		local isLargeTransparentVeil = part.Transparency > 0
			and part.Size.Y >= doorSize.Y * 0.6
			and math.max(part.Size.X, part.Size.Z) >= math.max(doorSize.X, doorSize.Z) * 0.6
		if not containsPart(movingParts, part) then
			if part.CanCollide or part.CanTouch then
				print("[MAYDEAD] Door blocking part = " .. part:GetFullName())
			end
			part.CanCollide = false
			part.CanTouch = false
			if isRuntimeReference or isLargeTransparentVeil then
				print(string.format(
					"[MAYDEAD] Door helper part = %s Transparency = %.3f CanCollide = %s CanQuery = %s",
					part:GetFullName(),
					part.Transparency,
					tostring(part.CanCollide),
					tostring(part.CanQuery)
				))
				part.Transparency = 1
				part.CanQuery = false
				part.CastShadow = false
			end
		end
	end
end

local function sanitizeDoorWallHelpers(doorWall)
	if not doorWall then
		return
	end
	local _, wallSize = getPlacementBox(doorWall)
	for _, part in getBaseParts(doorWall) do
		local isRuntimeReference = containsName(part.Name, NON_PHYSICAL_NAMES)
		local isLargeTransparentVeil = part.Transparency > 0
			and part.Size.Y >= wallSize.Y * 0.6
			and math.max(part.Size.X, part.Size.Z) >= math.max(wallSize.X, wallSize.Z) * 0.6
		if isRuntimeReference or isLargeTransparentVeil then
			print(string.format(
				"[MAYDEAD] Door helper part = %s Transparency = %.3f CanCollide = %s CanQuery = %s",
				part:GetFullName(),
				part.Transparency,
				tostring(part.CanCollide),
				tostring(part.CanQuery)
			))
			part.Transparency = 1
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.CastShadow = false
		end
	end
end

local function isOnMinimumSide(position, widthUsesX, centerOnWidthAxis)
	if widthUsesX then
		return position.X < centerOnWidthAxis
	end
	return position.Z < centerOnWidthAxis
end

function DoorService.new()
	local self = setmetatable({}, DoorService)
	self._states = setmetatable({}, {__mode = "k"})
	return self
end

function DoorService:_applyAngle(state, angle)
	local rotation = CFrame.Angles(0, angle, 0)
	for _, partState in state.PartStates do
		if partState.Part.Parent then
			partState.Part.CFrame = state.HingeCFrame * rotation * partState.ClosedRelativeCFrame
		end
	end
end

function DoorService:_setPromptState(state, isOpen)
	if state.Prompt then
		state.Prompt.ActionText = isOpen and "FERMER" or "OUVRIR"
	end
end

function DoorService:_toggle(player, door)
	local state = self._states[door]
	if not state or state.IsAnimating or not door:IsDescendantOf(workspace) then
		return
	end
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart or (rootPart.Position - state.PromptParent.Position).Magnitude > INTERACTION_DISTANCE + 2 then
		return
	end

	state.IsAnimating = true
	door:SetAttribute("IsAnimating", true)
	local targetIsOpen = not door:GetAttribute("IsOpen")
	local targetAngle = targetIsOpen and state.OpenAngle or 0
	local angleValue = Instance.new("NumberValue")
	angleValue.Value = state.CurrentAngle
	state.AngleValue = angleValue
	state.ValueConnection = angleValue.Changed:Connect(function(angle)
		state.CurrentAngle = angle
		self:_applyAngle(state, angle)
	end)
	local tween = TweenService:Create(
		angleValue,
		TweenInfo.new(ANIMATION_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{Value = targetAngle}
	)
	state.Tween = tween
	tween.Completed:Connect(function(playbackState)
		if self._states[door] ~= state then
			return
		end
		if state.ValueConnection then
			state.ValueConnection:Disconnect()
			state.ValueConnection = nil
		end
		angleValue:Destroy()
		state.AngleValue = nil
		state.Tween = nil
		if playbackState == Enum.PlaybackState.Completed then
			state.CurrentAngle = targetAngle
			self:_applyAngle(state, targetAngle)
			door:SetAttribute("IsOpen", targetIsOpen)
			self:_setPromptState(state, targetIsOpen)
		end
		state.IsAnimating = false
		door:SetAttribute("IsAnimating", false)
	end)
	tween:Play()
end

function DoorService:RegisterDoor(door, doorWall)
	if self._states[door] then
		return
	end
	local movingParts, auditDescription = selectMovingParts(door)
	if #movingParts == 0 then
		warn("[MAYDEAD] Door interactive audit failed: no movable BasePart")
		return
	end
	addHandleParts(door, movingParts)
	sanitizeNonPhysicalParts(door, movingParts)
	sanitizeDoorWallHelpers(doorWall)
	local referenceBox = getPlacementBox(door)
	local minimum, maximum = getLocalBounds(movingParts, referenceBox)
	local widthUsesX = (maximum.X - minimum.X) >= (maximum.Z - minimum.Z)
	local hingeAttachment = findHingeAttachment(movingParts)
	local handleWorldPosition, handleDescription = findHandlePosition(door)
	local handlePosition = handleWorldPosition and referenceBox:PointToObjectSpace(handleWorldPosition) or nil
	local centerOnWidthAxis = widthUsesX and (minimum.X + maximum.X) / 2 or (minimum.Z + maximum.Z) / 2
	local handleIsLeft = handlePosition and isOnMinimumSide(handlePosition, widthUsesX, centerOnWidthAxis) or false
	local handleSide = handlePosition and (handleIsLeft and "LEFT" or "RIGHT") or "RIGHT (inferred)"
	local hingeSide = handleIsLeft and "RIGHT" or "LEFT"
	local hingePosition
	if hingeAttachment then
		local attachmentPosition = referenceBox:PointToObjectSpace(hingeAttachment.WorldPosition)
		local attachmentIsLeft = isOnMinimumSide(attachmentPosition, widthUsesX, centerOnWidthAxis)
		if attachmentIsLeft == (hingeSide == "LEFT") then
			hingePosition = attachmentPosition
		end
	end
	if not hingePosition then
		local hingeOnMinimumSide = hingeSide == "LEFT"
		hingePosition = widthUsesX
			and Vector3.new(
				hingeOnMinimumSide and minimum.X or maximum.X,
				(minimum.Y + maximum.Y) / 2,
				(minimum.Z + maximum.Z) / 2
			)
			or Vector3.new(
				(minimum.X + maximum.X) / 2,
				(minimum.Y + maximum.Y) / 2,
				hingeOnMinimumSide and minimum.Z or maximum.Z
			)
	end
	local openAngle = hingeSide == "LEFT" and OPEN_ANGLE_MAGNITUDE or -OPEN_ANGLE_MAGNITUDE
	local hingeCFrame = referenceBox * CFrame.new(hingePosition)
	local partStates = {}
	for _, part in movingParts do
		table.insert(partStates, {
			Part = part,
			ClosedRelativeCFrame = hingeCFrame:ToObjectSpace(part.CFrame),
		})
	end

	local promptParent = door.PrimaryPart or movingParts[1] or door:FindFirstChildWhichIsA("BasePart", true)
	local existingPrompt = door:FindFirstChild("DoorPrompt", true)
	if existingPrompt then
		existingPrompt:Destroy()
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DoorPrompt"
	prompt.ActionText = "OUVRIR"
	prompt.ObjectText = "PORTE"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = INTERACTION_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptParent

	local state = {
		PartStates = partStates,
		HingeCFrame = hingeCFrame,
		Prompt = prompt,
		PromptParent = promptParent,
		CurrentAngle = 0,
		OpenAngle = openAngle,
		IsAnimating = false,
	}
	self._states[door] = state
	door:SetAttribute("IsOpen", false)
	door:SetAttribute("IsAnimating", false)
	print("[MAYDEAD] Door interactive audit: " .. auditDescription)
	print("[MAYDEAD] Door handle source: " .. (handleDescription or "not found; opposite side inferred"))
	print("[MAYDEAD] Door handle side detected = " .. handleSide)
	print("[MAYDEAD] Door hinge side detected = " .. hingeSide)
	print("[MAYDEAD] Door opening angle = " .. tostring(math.deg(openAngle)))
	prompt.Triggered:Connect(function(player)
		if player:GetAttribute("SessionStarted") ~= true then return end
		if Players:GetPlayerByUserId(player.UserId) == player then
			self:_toggle(player, door)
		end
	end)
end

function DoorService:PrepareDismantle(door)
	local state = self._states[door]
	if not state then
		return
	end
	if state.Tween then
		state.Tween:Cancel()
	end
	if state.ValueConnection then
		state.ValueConnection:Disconnect()
		state.ValueConnection = nil
	end
	if state.AngleValue then
		state.AngleValue:Destroy()
		state.AngleValue = nil
	end
	state.CurrentAngle = 0
	state.IsAnimating = false
	self:_applyAngle(state, 0)
	door:SetAttribute("IsOpen", false)
	door:SetAttribute("IsAnimating", false)
	if state.Prompt then
		state.Prompt.Enabled = false
	end
end

function DoorService:UnregisterDoor(door)
	self:PrepareDismantle(door)
	self._states[door] = nil
end

return DoorService.new()
