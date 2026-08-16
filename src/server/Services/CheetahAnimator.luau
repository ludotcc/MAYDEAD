local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config.CheetahConfig)

local CheetahAnimator = {}
CheetahAnimator.__index = CheetahAnimator

local BLEND_RATE = 8
local PROBE_ANGLE = math.rad(20)
local PROBE_DURATION = 0.5

local function partName(part)
	return part and part:GetFullName() or "nil"
end

local function jointPart1(joint)
	if joint:IsA("Motor6D") or joint:IsA("Weld") or joint:IsA("WeldConstraint") then return joint.Part1 end
	return nil
end

local function logRig(model)
	if not RunService:IsStudio() or not (Config.CHEETAH_RIG_DEBUG or Config.CHEETAH_RIG_REBUILD_DEBUG) then return end
	print("[MAYDEAD][CHEETAH][RIG] BEGIN " .. model:GetFullName())
	for _, item in model:GetDescendants() do
		if item:IsA("Humanoid") or item:IsA("Animator") or item:IsA("AnimationController")
			or item:IsA("Motor6D") or item:IsA("Weld") or item:IsA("WeldConstraint") or item:IsA("Bone")
			or item:IsA("Attachment") or item:IsA("MeshPart") or item:IsA("Part") or item:IsA("UnionOperation")
		then
			print(string.format("[MAYDEAD][CHEETAH][RIG] FullName=%s Class=%s Name=%s Parent=%s",
				item:GetFullName(), item.ClassName, item.Name, item.Parent and item.Parent:GetFullName() or "nil"))
			if item:IsA("Motor6D") then
				print(string.format("[MAYDEAD][CHEETAH][RIG] Joint=%s Class=Motor6D Part0=%s Part1=%s C0=%s C1=%s Transform=%s",
					item.Name, partName(item.Part0), partName(item.Part1), tostring(item.C0), tostring(item.C1), tostring(item.Transform)))
			elseif item:IsA("Weld") then
				print(string.format("[MAYDEAD][CHEETAH][RIG] Joint=%s Class=Weld Part0=%s Part1=%s C0=%s C1=%s",
					item.Name, partName(item.Part0), partName(item.Part1), tostring(item.C0), tostring(item.C1)))
			elseif item:IsA("WeldConstraint") then
				print(string.format("[MAYDEAD][CHEETAH][RIG] Joint=%s Class=WeldConstraint Part0=%s Part1=%s",
					item.Name, partName(item.Part0), partName(item.Part1)))
			end
		end
	end
	print("[MAYDEAD][CHEETAH][RIG] END")
end

local function limbRole(root, joint)
	local limb = jointPart1(joint)
	if not limb or limb == root then return nil end
	local localPosition = root.CFrame:PointToObjectSpace(limb.Position)
	-- Roblox local -Z is forward and -X is left. Ignore parts too close to the body centre.
	if math.abs(localPosition.X) < 0.15 or math.abs(localPosition.Z) < 0.15 then return nil end
	local longitudinal = localPosition.Z < 0 and "Front" or "Rear"
	local lateral = localPosition.X < 0 and "Left" or "Right"
	return longitudinal .. lateral, localPosition
end

local function getTransform(joint)
	return joint:IsA("Motor6D") and joint.Transform or CFrame.identity
end

local function findVisualBodyJoint(model, root)
	for _, joint in model:GetDescendants() do
		if joint:IsA("Motor6D") or joint:IsA("Weld") then
			local part0, part1 = joint.Part0, joint.Part1
			local visual = part0 == root and part1 or part1 == root and part0 or nil
			if visual and (visual.Name == "Body" or visual.Name == "Torso" or visual.Name == "UpperTorso") then
				return {Joint=joint, Visual=visual, Reversed=part1==root, BaseTransform=getTransform(joint), BaseC0=joint:IsA("Weld") and joint.C0 or nil}
			end
		end
	end
	return nil
end

function CheetahAnimator.new(model, humanoid, root)
	local self = setmetatable({}, CheetahAnimator)
	self.Model, self.Humanoid, self.Root = model, humanoid, root
	self.Joints, self.ByRole, self.ConstraintCandidates = {}, {}, {}
	self.Time, self.LastPosition, self.MeasuredSpeed = 0, root.Position, 0
	self.AttackUntil, self.AttackDuration, self.HitUntil = 0, 0.34, 0
	self.Dead, self.Connection, self.DestroyingConnection, self.LastDebug = false, nil, nil, 0
	self.BodyEntry = findVisualBodyJoint(model, root)
	logRig(model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Motor6D") or descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
			local role, localPosition = limbRole(root, descendant)
			if role then
				if descendant:IsA("WeldConstraint") then
					table.insert(self.ConstraintCandidates, {Joint = descendant, Role = role, LocalPosition = localPosition})
				else
					local entry = {Joint = descendant, Role = role, LocalPosition = localPosition,
						BaseTransform = getTransform(descendant), BaseC0 = descendant:IsA("Weld") and descendant.C0 or nil}
					table.insert(self.Joints, entry)
					-- Prefer the proximal shoulder/hip joint, not a distal paw joint in the same quadrant.
					local current = self.ByRole[role]
					if not current or localPosition.Magnitude < current.LocalPosition.Magnitude then self.ByRole[role] = entry end
				end
			end
		end
	end
	for _, role in {"FrontLeft", "FrontRight", "RearLeft", "RearRight"} do
		local entry = self.ByRole[role]
		if Config.CHEETAH_RIG_DEBUG then
			print(string.format("[MAYDEAD][CHEETAH][RIG] Mapping %s=%s", role,
				entry and (entry.Joint.ClassName .. ":" .. entry.Joint:GetFullName() .. " Part1=" .. partName(jointPart1(entry.Joint))) or "UNRESOLVED"))
		end
	end
	for _, candidate in self.ConstraintCandidates do
		if Config.CHEETAH_RIG_DEBUG then
			print(string.format("[MAYDEAD][CHEETAH][RIG] Non-animatable candidate Role=%s Joint=%s Part1=%s",
				candidate.Role, candidate.Joint:GetFullName(), partName(candidate.Joint.Part1)))
		end
	end
	return self
end

function CheetahAnimator:PlayAttack() self.AttackUntil = os.clock() + self.AttackDuration end
function CheetahAnimator:PlayHit() self.HitUntil = os.clock() + 0.18 end
function CheetahAnimator:PlayDeath() self.Dead = true end

function CheetahAnimator:_apply(entry, target, blend)
	local joint = entry.Joint
	if joint:IsA("Motor6D") then joint.Transform = joint.Transform:Lerp(entry.BaseTransform * target, blend)
	elseif joint:IsA("Weld") then joint.C0 = joint.C0:Lerp(entry.BaseC0 * target, blend) end
end

function CheetahAnimator:_probeJoints()
	if not RunService:IsStudio() or not (Config.CHEETAH_LOCOMOTION_DEBUG or Config.CHEETAH_RIG_REBUILD_DEBUG) or not Config.ANIMATION_JOINT_PROBE then return end
	task.spawn(function()
		task.wait(1)
		for _, role in {"FrontLeft", "FrontRight", "RearLeft", "RearRight"} do
			local entry = self.ByRole[role]
			if entry and self.Model.Parent then
				print(string.format("[MAYDEAD][CHEETAH][RIG][PROBE] Role=%s Joint=%s Angle=20 Duration=0.5",
					role, entry.Joint:GetFullName()))
				self:_apply(entry, CFrame.Angles(PROBE_ANGLE, 0, 0), 1)
				task.wait(PROBE_DURATION)
				self:_apply(entry, CFrame.identity, 1)
				task.wait(0.2)
			end
		end
	end)
end

function CheetahAnimator:_step(deltaTime)
	self.Time += deltaTime
	local position = self.Root.Position
	local delta = position - self.LastPosition
	self.LastPosition = position
	local measured = Vector3.new(delta.X, 0, delta.Z).Magnitude / math.max(deltaTime, 1 / 240)
	self.MeasuredSpeed += (measured - self.MeasuredSpeed) * math.clamp(deltaTime * 8, 0, 1)
	local speed = self.MeasuredSpeed
	local moving = speed > 0.65
	local cadence, amplitude
	if speed < 12 then cadence, amplitude = 3.2 + speed * 0.28, math.rad(15 + speed * 0.55)
	elseif speed < 24 then cadence, amplitude = 6.5 + (speed - 12) * 0.2, math.rad(22 + (speed - 12) * 0.55)
	else cadence, amplitude = math.clamp(9 + (speed - 24) * 0.18, 9, 14), math.rad(math.clamp(32 + (speed - 24) * 0.45, 32, 45)) end
	if not moving then cadence, amplitude = 0, 0 end
	local phase = self.Time * cadence
	local blend = 1 - math.exp(-BLEND_RATE * deltaTime)
	if self.BodyEntry then
		local ratio=math.clamp(speed/Config.MOUNT_SPRINT_SPEED,0,1)
		local bob,pitch
		if not moving then bob,pitch=Config.BODY_IDLE_BOB,math.rad(1)
		elseif speed<30 then bob,pitch=Config.BODY_WALK_BOB,math.rad(Config.BODY_WALK_PITCH_DEGREES)
		elseif speed<40 then bob,pitch=Config.BODY_RUN_BOB,math.rad(Config.BODY_RUN_PITCH_DEGREES)
		else bob,pitch=Config.BODY_SPRINT_BOB,math.rad(Config.BODY_SPRINT_PITCH_DEGREES) end
		local stride=math.sin(phase); local impact=math.max(0,-stride)^2
		local bodyTarget=CFrame.new(0,stride*bob-impact*bob*.35,math.cos(phase)*bob*.18)
			*CFrame.Angles(stride*pitch,0,math.sin(phase*.5)*math.rad(Config.BODY_MAX_ROLL_DEGREES)*ratio)
		if self.BodyEntry.Reversed then bodyTarget=bodyTarget:Inverse() end
		self:_apply(self.BodyEntry,bodyTarget,blend)
		if Config.CHEETAH_BODY_LOCOMOTION_DEBUG and RunService:IsStudio() and os.clock()-self.LastDebug>=1.5 then
			print(string.format("[MAYDEAD][CHEETAH][BODY] State=%s Speed=%.1f Bob=%.3f Pitch=%.2f Roll=%.2f Visual=%s",
				moving and (speed<30 and "Walk" or speed<40 and "Run" or "Sprint") or "Idle",speed,stride*bob,math.deg(stride*pitch),math.deg(math.sin(phase*.5)*math.rad(Config.BODY_MAX_ROLL_DEGREES)*ratio),self.BodyEntry.Visual:GetFullName()))
		end
	end
	local angles = {FrontLeft = math.sin(phase) * amplitude, RearRight = math.sin(phase) * amplitude,
		FrontRight = -math.sin(phase) * amplitude, RearLeft = -math.sin(phase) * amplitude}
	for role, entry in self.ByRole do
		local angle = angles[role] or 0
		if self.Dead then angle = math.rad(18)
		elseif os.clock() < self.AttackUntil and (role == "FrontLeft" or role == "FrontRight") then angle = math.rad(-42) end
		self:_apply(entry, CFrame.Angles(angle, 0, 0), blend)
	end
	if (Config.CHEETAH_LOCOMOTION_DEBUG or Config.CHEETAH_RIG_REBUILD_DEBUG) and RunService:IsStudio() and os.clock() - self.LastDebug >= 1.5 then
		self.LastDebug = os.clock()
		local state = not moving and "Idle" or speed < 12 and "Walk" or speed < 24 and "Trot" or "Chase"
		print(string.format("[MAYDEAD][CHEETAH][ANIM] State=%s Speed=%.1f FL=%.1f FR=%.1f RL=%.1f RR=%.1f",
			state, speed, math.deg(angles.FrontLeft), math.deg(angles.FrontRight), math.deg(angles.RearLeft), math.deg(angles.RearRight)))
	end
end

function CheetahAnimator:Start()
	if self.Connection then return end
	self.Connection = RunService.Heartbeat:Connect(function(deltaTime) self:_step(deltaTime) end)
	self.DestroyingConnection = self.Model.Destroying:Connect(function() self:Stop() end)
	self:_probeJoints()
end

function CheetahAnimator:Stop()
	if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
	if self.DestroyingConnection then self.DestroyingConnection:Disconnect(); self.DestroyingConnection = nil end
	for _, entry in self.Joints do
		if entry.Joint.Parent then
			if entry.Joint:IsA("Motor6D") then entry.Joint.Transform = entry.BaseTransform
			else entry.Joint.C0 = entry.BaseC0 end
		end
	end
	if self.BodyEntry and self.BodyEntry.Joint.Parent then
		if self.BodyEntry.Joint:IsA("Motor6D") then self.BodyEntry.Joint.Transform=self.BodyEntry.BaseTransform else self.BodyEntry.Joint.C0=self.BodyEntry.BaseC0 end
	end
end

return CheetahAnimator
