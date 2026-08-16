local BuildingSnapGeometry = {}

function BuildingSnapGeometry.GetWallSnapCFrame(
	ceilingBox,
	ceilingSize,
	wallSize,
	edgeDirection,
	edgeYaw,
	wallThickness,
	snapOffset
)
	local inset = wallThickness / 2
	local offset = Vector3.new(
		edgeDirection.X * (ceilingSize.X / 2 - inset),
		ceilingSize.Y / 2 + wallSize.Y / 2,
		edgeDirection.Z * (ceilingSize.Z / 2 - inset)
	)

	return ceilingBox
		* CFrame.new(offset)
		* CFrame.Angles(0, edgeYaw, 0)
		* CFrame.new(snapOffset or Vector3.zero)
end

function BuildingSnapGeometry.GetStairsSnapCFrame(
	ceilingBox,
	ceilingSize,
	stairsSize,
	edgeYaw,
	snapOffset
)
	return ceilingBox
		* CFrame.new(0, ceilingSize.Y / 2 + stairsSize.Y / 2, 0)
		* CFrame.Angles(0, edgeYaw, 0)
		* CFrame.new(snapOffset or Vector3.zero)
end

function BuildingSnapGeometry.GetInsertSnapCFrame(supportBox, snapOffset)
	return supportBox * CFrame.new(snapOffset or Vector3.zero)
end

function BuildingSnapGeometry.GetDoorInsertSnapCFrame(
	supportBox,
	supportSize,
	doorSize,
	snapOffset
)
	local baseAlignmentOffset = -(supportSize.Y - doorSize.Y) / 2
	return supportBox
		* CFrame.new(0, baseAlignmentOffset, 0)
		* CFrame.new(snapOffset or Vector3.zero)
end

function BuildingSnapGeometry.GetFloorEdgeSnapCFrame(
	supportBox,
	supportSize,
	supportEdgeDirection,
	pieceSize,
	pieceEdgeDirection,
	snapOffset
)
	local rotationYaw = 0
	for quarterTurn = 0, 3 do
		local candidateYaw = quarterTurn * math.pi / 2
		local rotatedEdge = CFrame.Angles(0, candidateYaw, 0):VectorToWorldSpace(pieceEdgeDirection)
		if rotatedEdge:Dot(-supportEdgeDirection) > 0.999 then
			rotationYaw = candidateYaw
			break
		end
	end
	local supportExtent = math.abs(supportEdgeDirection.X) * supportSize.X / 2
		+ math.abs(supportEdgeDirection.Z) * supportSize.Z / 2
	local pieceExtent = math.abs(pieceEdgeDirection.X) * pieceSize.X / 2
		+ math.abs(pieceEdgeDirection.Z) * pieceSize.Z / 2
	local offset = supportEdgeDirection * (supportExtent + pieceExtent)
	return supportBox
		* CFrame.new(offset)
		* CFrame.Angles(0, rotationYaw, 0)
		* CFrame.new(snapOffset or Vector3.zero)
end

function BuildingSnapGeometry.GetCurvedWallSnapCFrame(
	supportBox,
	supportSize,
	wallSize,
	snapOffset,
	orientationOffset
)
	local function getArcChordFrame(size, y)
		local arcStart = Vector3.new(size.X / 2, y, -size.Z / 2)
		local arcEnd = Vector3.new(-size.X / 2, y, size.Z / 2)
		local chordDirection = (arcEnd - arcStart).Unit
		local up = Vector3.yAxis
		local back = chordDirection:Cross(up).Unit
		return CFrame.fromMatrix((arcStart + arcEnd) / 2, chordDirection, up, back)
	end

	local floorArcFrame = getArcChordFrame(supportSize, supportSize.Y / 2)
	local wallArcFrame = getArcChordFrame(wallSize, -wallSize.Y / 2)
	return supportBox
		* floorArcFrame
		* wallArcFrame:Inverse()
		* (orientationOffset or CFrame.identity)
		* CFrame.new(snapOffset or Vector3.zero)
end

return BuildingSnapGeometry
