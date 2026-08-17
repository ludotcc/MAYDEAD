local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local BoatConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("BoatConfig"))

local BoatService = {}

type SurfaceMode = "Water" | "NonWater"

local WATER_SAMPLE_THRESHOLD = 3
local SURFACE_SAMPLE_SCALE = 0.4

type BoatState = {
	Model: Model,
	Seat: VehicleSeat,
	Body: BasePart,
	BodyForce: BodyForce,
	AngularVelocity: AngularVelocity,
	Propulsion: LinearVelocity,
	Buoyancy: VectorForce,
	WaterlineOffset: number,
	DesiredSpeed: number,
	DebugAccumulator: number,
	StabilityLogAccumulator: number,
	AccelerationElapsed: number?,
	AccelerationLogAccumulator: number,
	SurfaceMode: SurfaceMode,
	PendingSurfaceMode: SurfaceMode?,
	PendingSurfaceElapsed: number,
	WaterSamples: number,
	PivotToBody: CFrame,
	OccupantConnection: RBXScriptConnection?,
}

local boatStates: {[Model]: BoatState} = setmetatable({}, {__mode = "k"})
local started = false

local function moveTowards(current: number, target: number, maximumDelta: number): number
	if current < target then
		return math.min(current + maximumDelta, target)
	end
	return math.max(current - maximumDelta, target)
end

local function getNetworkOwnerName(body: BasePart): string
	local networkOwner = "server"
	pcall(function()
		local owner = body:GetNetworkOwner()
		if owner then
			networkOwner = owner.Name
		end
	end)
	return networkOwner
end

local function findBoatComponents(model: Model): (VehicleSeat?, BasePart?, BodyForce?, AngularVelocity?)
	local seat = model:FindFirstChildWhichIsA("VehicleSeat", true)
	local body = model:FindFirstChild("Body")
	if not seat or not body or not body:IsA("BasePart") then
		return seat, nil, nil, nil
	end
	return seat, body, body:FindFirstChildWhichIsA("BodyForce"), body:FindFirstChildWhichIsA("AngularVelocity")
end

local function disableLegacyPropulsionScript(seat: VehicleSeat)
	local legacyScript = seat:FindFirstChild("Script")
	if legacyScript and legacyScript:IsA("Script") then
		legacyScript.Disabled = true
	end
end

local function getInstancePath(instance: Instance?): string
	return instance and instance:GetFullName() or "nil"
end

local function auditBoatRuntime(model: Model, seat: VehicleSeat, body: BasePart, bodyForce: BodyForce, angularVelocity: AngularVelocity, propulsion: LinearVelocity)
	local attachment = propulsion.Attachment0
	local bodyForward = Vector3.new(body.CFrame.LookVector.X, 0, body.CFrame.LookVector.Z)
	local seatForward = Vector3.new(seat.CFrame.LookVector.X, 0, seat.CFrame.LookVector.Z)
	local forwardDot = 0
	if bodyForward.Magnitude > 0 and seatForward.Magnitude > 0 then
		forwardDot = bodyForward.Unit:Dot(seatForward.Unit)
	end
	print(string.format(
		"[MAYDEAD][BOAT][AUDIT] Boat=%s Body=%s VehicleSeat=%s BodyRoot=%s SeatRoot=%s Attachment=%s AttachmentParent=%s LinearVelocityParent=%s ForwardDot=%.3f SeatMaxSpeed=%.1f SeatTorque=%.1f",
		model:GetFullName(),
		body:GetFullName(),
		seat:GetFullName(),
		getInstancePath(body.AssemblyRootPart),
		getInstancePath(seat.AssemblyRootPart),
		getInstancePath(attachment),
		getInstancePath(attachment and attachment.Parent),
		getInstancePath(propulsion.Parent),
		forwardDot,
		seat.MaxSpeed,
		seat.Torque
	))
	local anchoredParts = 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Anchored then anchoredParts += 1 end
	end
	print(string.format(
		"[MAYDEAD][BOAT][RUNTIME] Path=%s StructureId=%s Registered=true AssemblyRoot=%s AssemblyMass=%.3f AnchoredParts=%d Throttle=%.2f Steer=%.2f LinearVelocityExists=true AngularVelocityExists=%s BodyForceExists=%s BodyForce=%s NetworkOwner=%s",
		model:GetFullName(), tostring(model:GetAttribute("StructureId")), getInstancePath(body.AssemblyRootPart),
		body.AssemblyMass, anchoredParts, seat.ThrottleFloat, seat.SteerFloat,
		tostring(angularVelocity ~= nil), tostring(bodyForce ~= nil), tostring(bodyForce.Force), getNetworkOwnerName(body)
	))
	print(string.format(
		"[MAYDEAD][BOAT][AUDIT] LinearVelocity Enabled=%s RelativeTo=%s Mode=%s PlaneVelocity=%s VectorVelocity=%s PrimaryAxis=%s SecondaryAxis=%s MaxForce=%.1f ForceLimitsEnabled=%s Attachment0=%s",
		tostring(propulsion.Enabled),
		propulsion.RelativeTo.Name,
		propulsion.VelocityConstraintMode.Name,
		tostring(propulsion.PlaneVelocity),
		tostring(propulsion.VectorVelocity),
		tostring(propulsion.PrimaryTangentAxis),
		tostring(propulsion.SecondaryTangentAxis),
		propulsion.MaxForce,
		tostring(propulsion.ForceLimitsEnabled),
		getInstancePath(attachment)
	))

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BodyForce")
			or descendant:IsA("BodyVelocity")
			or descendant:IsA("LinearVelocity")
			or descendant:IsA("VectorForce")
			or descendant:IsA("AlignPosition")
			or descendant:IsA("AngularVelocity")
			or descendant:IsA("Constraint")
			or descendant:IsA("Script")
		then
			local state = descendant:IsA("Script") and (" Disabled=" .. tostring(descendant.Disabled)) or ""
			print(string.format(
				"[MAYDEAD][BOAT][AUDIT] Descendant Class=%s Path=%s%s",
				descendant.ClassName,
				descendant:GetFullName(),
				state
			))
		end
	end
end

local function createPropulsion(body: BasePart): LinearVelocity
	local attachment = body:FindFirstChild("BoatPropulsionAttachment")
	if not attachment or not attachment:IsA("Attachment") then
		attachment = Instance.new("Attachment")
		attachment.Name = "BoatPropulsionAttachment"
		attachment.Parent = body
	end

	local propulsion = body:FindFirstChild("BoatPropulsion")
	if not propulsion or not propulsion:IsA("LinearVelocity") then
		propulsion = Instance.new("LinearVelocity")
		propulsion.Name = "BoatPropulsion"
		propulsion.Parent = body
	end
	propulsion.Attachment0 = attachment
	propulsion.RelativeTo = Enum.ActuatorRelativeTo.World
	propulsion.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	propulsion.PrimaryTangentAxis = Vector3.xAxis
	propulsion.SecondaryTangentAxis = Vector3.zAxis
	propulsion.ForceLimitsEnabled = true
	propulsion.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	propulsion.MaxForce = body.AssemblyMass * BoatConfig.MAX_FORCE_PER_MASS
	propulsion.PlaneVelocity = Vector2.zero
	propulsion.Enabled = true
	return propulsion
end

local function sampleWaterSurface(model: Model): (number, number?)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	local filterDescendants: {Instance} = {model}
	for _, player in Players:GetPlayers() do
		if player.Character then table.insert(filterDescendants, player.Character) end
	end
	parameters.FilterDescendantsInstances = filterDescendants
	parameters.IgnoreWater = false
	local boxCFrame, boxSize = model:GetBoundingBox()
	local extentX = boxSize.X * SURFACE_SAMPLE_SCALE
	local extentZ = boxSize.Z * SURFACE_SAMPLE_SCALE
	local waterSamples = 0
	local waterHeightTotal = 0
	local centerWaterY: number? = nil
	for sampleIndex, offset in {
		Vector3.zero,
		Vector3.new(extentX, 0, 0),
		Vector3.new(-extentX, 0, 0),
		Vector3.new(0, 0, extentZ),
		Vector3.new(0, 0, -extentZ),
	} do
		local samplePosition = boxCFrame:PointToWorldSpace(offset)
		local result = Workspace:Raycast(
			samplePosition + Vector3.new(0, BoatConfig.BUOYANCY_RAY_HEIGHT, 0),
			Vector3.new(0, -BoatConfig.BUOYANCY_RAY_DEPTH, 0),
			parameters
		)
		if result and result.Instance == Workspace.Terrain and result.Material == Enum.Material.Water then
			waterSamples += 1
			waterHeightTotal += result.Position.Y
			if sampleIndex == 1 then centerWaterY = result.Position.Y end
		end
	end
	return waterSamples, centerWaterY or (waterSamples > 0 and waterHeightTotal / waterSamples or nil)
end

local function getVerticalHalfExtent(part: BasePart): number
	local halfSize = part.Size / 2
	return math.abs(part.CFrame.RightVector.Y) * halfSize.X
		+ math.abs(part.CFrame.UpVector.Y) * halfSize.Y
		+ math.abs(part.CFrame.LookVector.Y) * halfSize.Z
end

local function createBuoyancy(body: BasePart): VectorForce
	local attachment = body:FindFirstChild("BoatBuoyancyAttachment")
	if not attachment or not attachment:IsA("Attachment") then
		attachment = Instance.new("Attachment")
		attachment.Name = "BoatBuoyancyAttachment"
		attachment.Parent = body
	end
	local buoyancy = body:FindFirstChild("BoatBuoyancy")
	if not buoyancy or not buoyancy:IsA("VectorForce") then
		buoyancy = Instance.new("VectorForce")
		buoyancy.Name = "BoatBuoyancy"
		buoyancy.Parent = body
	end
	buoyancy.Attachment0 = attachment
	buoyancy.RelativeTo = Enum.ActuatorRelativeTo.World
	buoyancy.ApplyAtCenterOfMass = true
	buoyancy.Force = Vector3.zero
	buoyancy.Enabled = true
	return buoyancy
end

local function logBuoyancy(state: BoatState, reason: string)
	if not RunService:IsStudio() then return end
	local _, waterSurfaceY = sampleWaterSurface(state.Model)
	print(string.format(
		"[MAYDEAD][BOAT][BUOYANCY] Reason=%s StructureId=%s AssemblyMass=%.3f Gravity=%.3f Occupant=%s BodyY=%.3f WaterSurfaceY=%s VerticalVelocity=%.3f BuoyancyForce=%s System=VectorForce",
		reason, tostring(state.Model:GetAttribute("StructureId")), state.Body.AssemblyMass,
		Workspace.Gravity, tostring(state.Seat.Occupant ~= nil), state.Body.Position.Y,
		waterSurfaceY and string.format("%.3f", waterSurfaceY) or "nil",
		state.Body.AssemblyLinearVelocity.Y, tostring(state.Buoyancy.Force)
	))
end

local function logSurfaceMode(state: BoatState)
	if not RunService:IsStudio() then return end
	print(string.format(
		"[MAYDEAD][BOAT][SURFACE] Mode=%s WaterSamples=%d/5",
		state.SurfaceMode, state.WaterSamples
	))
end

local function registerBoat(model: Model): BoatState?
	local existing = boatStates[model]
	if existing then return existing end
	local seat, body, bodyForce, angularVelocity = findBoatComponents(model)
	if not seat or not body or not bodyForce or not angularVelocity then
		warn("[MAYDEAD][BOAT] Boat runtime missing VehicleSeat, Body, BodyForce or AngularVelocity: " .. model:GetFullName())
		return nil
	end

	disableLegacyPropulsionScript(seat)
	local pivotToBody = model:GetPivot():ToObjectSpace(body.CFrame)
	body.AssemblyLinearVelocity = Vector3.zero
	body.AssemblyAngularVelocity = Vector3.zero
	bodyForce.Force = Vector3.zero
	angularVelocity.AngularVelocity = Vector3.zero
	local templateTurnMaxTorque = angularVelocity.MaxTorque
	angularVelocity.MaxTorque = body.AssemblyMass * BoatConfig.TURN_MAX_TORQUE_PER_MASS
	seat.MaxSpeed = BoatConfig.FORWARD_MAX_SPEED
	local propulsion = createPropulsion(body)
	local buoyancy = createBuoyancy(body)
	local verticalHalfExtent = getVerticalHalfExtent(body)
	local waterlineOffset = verticalHalfExtent
		* (1 - 2 * BoatConfig.BUOYANCY_HULL_SUBMERGED_FRACTION)
	local initialWaterSamples, initialWaterSurfaceY = sampleWaterSurface(model)
	if initialWaterSurfaceY then
		local initialTargetBodyY = initialWaterSurfaceY + waterlineOffset
		model:PivotTo(model:GetPivot() + Vector3.new(0, initialTargetBodyY - body.Position.Y, 0))
	end

	local state = {
		Model = model,
		Seat = seat,
		Body = body,
		BodyForce = bodyForce,
		AngularVelocity = angularVelocity,
		Propulsion = propulsion,
		Buoyancy = buoyancy,
		WaterlineOffset = waterlineOffset,
		DesiredSpeed = 0,
		DebugAccumulator = 0,
		StabilityLogAccumulator = 0,
		AccelerationElapsed = nil,
		AccelerationLogAccumulator = 0,
		SurfaceMode = initialWaterSamples >= WATER_SAMPLE_THRESHOLD and "Water" or "NonWater",
		PendingSurfaceMode = nil,
		PendingSurfaceElapsed = 0,
		WaterSamples = initialWaterSamples,
		PivotToBody = pivotToBody,
		OccupantConnection = nil,
	}
	boatStates[model] = state

	print(string.format(
		"[MAYDEAD][BOAT] Registered %s | StructureId=%s | Mass=%.3f | MaxForce=%.1f | TurnMaxTorqueBefore=%.1f | TurnMaxTorqueAfter=%.1f | NetworkOwner=%s",
		model:GetFullName(), tostring(model:GetAttribute("StructureId")),
		body.AssemblyMass,
		propulsion.MaxForce,
		templateTurnMaxTorque,
		angularVelocity.MaxTorque,
		getNetworkOwnerName(body)
	))
	if RunService:IsStudio() then
		auditBoatRuntime(model, seat, body, bodyForce, angularVelocity, propulsion)
	end
	state.OccupantConnection = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		task.defer(function()
			print(string.format(
				"[MAYDEAD][BOAT] Occupant=%s | NetworkOwner=%s",
				tostring(seat.Occupant ~= nil),
				getNetworkOwnerName(body)
			))
			logBuoyancy(state, "OccupantChanged")
		end)
	end)
	logBuoyancy(state, "Init")
	logSurfaceMode(state)
	return state
end

function BoatService:RegisterBoat(model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then return false end
	return registerBoat(model) ~= nil
end

function BoatService:UnregisterBoat(model)
	local state = boatStates[model]
	if state and state.OccupantConnection then
		state.OccupantConnection:Disconnect()
	end
	boatStates[model] = nil
end

function BoatService:GetPersistentPivot(model)
	local state = boatStates[model]
	if not state or not state.Body.Parent then return nil end
	return state.Body.CFrame * state.PivotToBody:Inverse()
end

local function updateBoat(state: BoatState, deltaTime: number)
	local seat = state.Seat
	local body = state.Body
	local velocity = body.AssemblyLinearVelocity
	local waterSamples, sampledWaterSurfaceY = sampleWaterSurface(state.Model)
	state.WaterSamples = waterSamples
	local detectedSurfaceMode: SurfaceMode = waterSamples >= WATER_SAMPLE_THRESHOLD and "Water" or "NonWater"
	if detectedSurfaceMode == state.SurfaceMode then
		state.PendingSurfaceMode = nil
		state.PendingSurfaceElapsed = 0
	elseif detectedSurfaceMode == "Water" then
		state.SurfaceMode = "Water"
		state.PendingSurfaceMode = nil
		state.PendingSurfaceElapsed = 0
		logSurfaceMode(state)
	else
		if state.PendingSurfaceMode ~= detectedSurfaceMode then
			state.PendingSurfaceMode = detectedSurfaceMode
			state.PendingSurfaceElapsed = 0
		end
		state.PendingSurfaceElapsed += deltaTime
		if state.PendingSurfaceElapsed >= BoatConfig.NON_WATER_STATE_HYSTERESIS then
			state.SurfaceMode = detectedSurfaceMode
			state.PendingSurfaceMode = nil
			state.PendingSurfaceElapsed = 0
			logSurfaceMode(state)
		end
	end
	local waterSurfaceY = state.SurfaceMode == "Water" and sampledWaterSurfaceY or nil
	if waterSurfaceY then
		local mass = body.AssemblyMass
		local targetBodyY = waterSurfaceY + state.WaterlineOffset
		local rawErrorY = targetBodyY - body.Position.Y
		local errorMagnitude = math.max(0, math.abs(rawErrorY) - BoatConfig.BUOYANCY_WATERLINE_DEADBAND)
		local errorY = math.sign(rawErrorY) * errorMagnitude
		local damping = BoatConfig.BUOYANCY_DAMPING
		if math.abs(rawErrorY) < BoatConfig.BUOYANCY_NEAR_WATERLINE_RANGE then
			damping *= BoatConfig.BUOYANCY_NEAR_WATERLINE_DAMPING_MULTIPLIER
		end
		local unclampedCorrection = errorY * BoatConfig.BUOYANCY_STIFFNESS - velocity.Y * damping
		local correctionAcceleration = math.clamp(
			unclampedCorrection,
			-BoatConfig.BUOYANCY_MAX_CORRECTION,
			BoatConfig.BUOYANCY_MAX_CORRECTION
		)
		local baseForce = mass * Workspace.Gravity
		local buoyancyY = mass * (Workspace.Gravity + correctionAcceleration)
		local maximumBuoyancy = mass * Workspace.Gravity * BoatConfig.BUOYANCY_MAX_GRAVITY_MULTIPLIER
		local finalForceY = math.clamp(buoyancyY, 0, maximumBuoyancy)
		state.Buoyancy.Force = Vector3.new(0, finalForceY, 0)
		state.StabilityLogAccumulator += deltaTime
		if BoatConfig.DEBUG_LOGS
			and RunService:IsStudio()
			and state.StabilityLogAccumulator >= BoatConfig.DEBUG_INTERVAL
			and (state.Seat.Occupant ~= nil or math.abs(rawErrorY) > BoatConfig.BUOYANCY_WATERLINE_DEADBAND or math.abs(velocity.Y) > 0.05)
		then
			state.StabilityLogAccumulator = 0
			print(string.format(
				"[MAYDEAD][BOAT][BUOYANCY_STABILITY] ErrorY=%.3f VelocityY=%.3f BaseForce=%.3f Correction=%.3f FinalForceY=%.3f Occupant=%s",
				rawErrorY, velocity.Y, baseForce, correctionAcceleration * mass,
				finalForceY, tostring(state.Seat.Occupant ~= nil)
			))
		end
	else
		state.Buoyancy.Force = Vector3.zero
		state.StabilityLogAccumulator = 0
	end
	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	local horizontalForward = Vector3.new(seat.CFrame.LookVector.X, 0, seat.CFrame.LookVector.Z)
	if horizontalForward.Magnitude <= 0 then
		state.Propulsion.PlaneVelocity = Vector2.zero
		state.AngularVelocity.AngularVelocity = Vector3.zero
		return
	end
	horizontalForward = horizontalForward.Unit

	local hasDriver = seat.Occupant ~= nil
	local throttle = hasDriver and seat.ThrottleFloat or 0
	local targetSpeed = 0
	local speedChangeRate = BoatConfig.DECELERATION
	local forwardMaxSpeed = state.SurfaceMode == "Water" and BoatConfig.FORWARD_MAX_SPEED or BoatConfig.NON_WATER_MAX_SPEED
	local reverseMaxSpeed = state.SurfaceMode == "Water" and BoatConfig.REVERSE_MAX_SPEED or BoatConfig.NON_WATER_REVERSE_SPEED
	local forwardAcceleration = state.SurfaceMode == "Water" and BoatConfig.FORWARD_ACCELERATION or BoatConfig.NON_WATER_ACCELERATION
	local reverseAcceleration = state.SurfaceMode == "Water" and BoatConfig.REVERSE_ACCELERATION or BoatConfig.NON_WATER_ACCELERATION
	if throttle > 0 then
		targetSpeed = forwardMaxSpeed
		if state.DesiredSpeed < 0 then
			speedChangeRate = BoatConfig.BRAKE_DECELERATION
		elseif state.DesiredSpeed > forwardMaxSpeed then
			speedChangeRate = BoatConfig.DECELERATION
		else
			speedChangeRate = forwardAcceleration
		end
	elseif throttle < 0 then
		targetSpeed = -reverseMaxSpeed
		if state.DesiredSpeed > 0 then
			speedChangeRate = BoatConfig.BRAKE_DECELERATION
		elseif state.DesiredSpeed < -reverseMaxSpeed then
			speedChangeRate = BoatConfig.DECELERATION
		else
			speedChangeRate = reverseAcceleration
		end
	end
	state.DesiredSpeed = moveTowards(state.DesiredSpeed, targetSpeed, speedChangeRate * deltaTime)
	state.Propulsion.MaxForce = body.AssemblyMass * BoatConfig.MAX_FORCE_PER_MASS
	state.AngularVelocity.MaxTorque = body.AssemblyMass * BoatConfig.TURN_MAX_TORQUE_PER_MASS
	local desiredVelocity = horizontalForward * state.DesiredSpeed
	state.Propulsion.PlaneVelocity = Vector2.new(desiredVelocity.X, desiredVelocity.Z)

	local speedRatio = math.clamp(horizontalVelocity.Magnitude / BoatConfig.FORWARD_MAX_SPEED, 0, 1)
	local turnRate = BoatConfig.TURN_RATE_LOW
		+ (BoatConfig.TURN_RATE_HIGH - BoatConfig.TURN_RATE_LOW) * speedRatio
	local steer = hasDriver and seat.SteerFloat or 0
	state.AngularVelocity.AngularVelocity = Vector3.new(0, -steer * turnRate, 0)

	local forwardSpeed = horizontalVelocity:Dot(horizontalForward)
	if throttle > 0 and state.SurfaceMode == "Water" then
		if state.AccelerationElapsed == nil and forwardSpeed <= 1 then
			state.AccelerationElapsed = 0
			state.AccelerationLogAccumulator = 0
		end
		local accelerationElapsed = state.AccelerationElapsed
		if accelerationElapsed ~= nil then
			accelerationElapsed += deltaTime
			state.AccelerationElapsed = accelerationElapsed
			state.AccelerationLogAccumulator += deltaTime
			local reachedTarget = forwardSpeed >= BoatConfig.FORWARD_MAX_SPEED * 0.975
			if RunService:IsStudio()
				and BoatConfig.DEBUG_LOGS
				and (reachedTarget or state.AccelerationLogAccumulator >= BoatConfig.DEBUG_INTERVAL)
			then
				state.AccelerationLogAccumulator = 0
				print(string.format(
					"[MAYDEAD][BOAT][ACCEL] Speed=%.2f Target=%.2f Elapsed=%.2f Throttle=%.2f",
					forwardSpeed, BoatConfig.FORWARD_MAX_SPEED, accelerationElapsed, throttle
				))
			end
			if reachedTarget then state.AccelerationElapsed = nil end
		end
	else
		state.AccelerationElapsed = nil
		state.AccelerationLogAccumulator = 0
	end

	state.DebugAccumulator += deltaTime
	if BoatConfig.DEBUG_LOGS
		and RunService:IsStudio()
		and state.DebugAccumulator >= BoatConfig.DEBUG_INTERVAL
		and (hasDriver or horizontalVelocity.Magnitude > 0.5)
	then
		state.DebugAccumulator = 0
		print(string.format(
			"[MAYDEAD][BOAT] Throttle=%.2f CommandedSpeed=%.2f ForwardSpeed=%.2f HorizontalSpeed=%.2f Target=%.2f LinearVelocityMode=%s MaxForce=%.1f NetworkOwner=%s",
			throttle,
			state.DesiredSpeed,
			forwardSpeed,
			horizontalVelocity.Magnitude,
			targetSpeed,
			state.Propulsion.VelocityConstraintMode.Name,
			state.Propulsion.MaxForce,
			getNetworkOwnerName(body)
		))
	end
end

function BoatService:Start()
	if started then return end
	started = true
	local boat = Workspace:FindFirstChild("Boat")
	if boat and boat:IsA("Model") then
		registerBoat(boat)
	end
	local placedStructures = Workspace:FindFirstChild("PlacedStructures")
	if placedStructures then
		for _, candidate in placedStructures:GetDescendants() do
			if candidate:IsA("Model") and candidate:GetAttribute("StructureType") == "Boat" then registerBoat(candidate) end
		end
	end
	RunService.Heartbeat:Connect(function(deltaTime)
		for model, state in boatStates do
			if model:IsDescendantOf(Workspace) then
				updateBoat(state, deltaTime)
			else
				BoatService:UnregisterBoat(model)
			end
		end
	end)
	print("[MAYDEAD][BOAT] BoatService V4 started | Runtime structure registration enabled")
end

return BoatService
