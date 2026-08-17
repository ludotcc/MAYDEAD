local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local WildlifeDefinitions = require(SharedFolder:WaitForChild("Definitions"):WaitForChild("WildlifeDefinitions"))
local CheetahConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("CheetahConfig"))
local JellyfishConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("JellyfishConfig"))
local SharkConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("SharkConfig"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local SurvivalService = require(script.Parent:WaitForChild("SurvivalService"))
local DamageFeedbackService = require(script.Parent:WaitForChild("DamageFeedbackService"))
local CheetahAI = require(script.Parent:WaitForChild("CheetahAI"))
local JellyfishAI = require(script.Parent:WaitForChild("JellyfishAI"))
local SharkAI = require(script.Parent:WaitForChild("SharkAI"))

local WildlifeService = {}
WildlifeService.__index = WildlifeService

local function trim(value)
	return value:match("^%s*(.-)%s*$")
end

local function isFiniteNumber(value)
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function isFiniteVector3(value)
	return typeof(value) == "Vector3"
		and isFiniteNumber(value.X)
		and isFiniteNumber(value.Y)
		and isFiniteNumber(value.Z)
end

local function closestDistance(rootPart, model)
	local shortest = math.huge
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			shortest = math.min(shortest, (descendant:GetClosestPointOnSurface(rootPart.Position) - rootPart.Position).Magnitude)
		end
	end
	return shortest
end

local function isValidSpawnPoint(instance)
	return instance:IsA("BasePart") or instance:IsA("Model")
end

local function isAdmittedWorldPlayer(player)
	return player.Parent == Players and player:GetAttribute("SessionStarted") == true
		and player:GetAttribute("InMainMenu") ~= true and player:GetAttribute("ReturningToMenu") ~= true
end

local function getSpawnPivot(spawnPoint, animal)
	local markerPivot
	local markerTopOffset = 0
	if spawnPoint:IsA("BasePart") then
		markerPivot = spawnPoint.CFrame
		markerTopOffset = spawnPoint.Size.Y * 0.5
	else
		markerPivot = spawnPoint:GetPivot()
	end
	local animalPivot = animal:GetPivot()
	local boundingCFrame, boundingSize = animal:GetBoundingBox()
	local pivotAboveBottom = math.max(0, animalPivot.Position.Y - (boundingCFrame.Position.Y - boundingSize.Y * 0.5))
	return markerPivot * CFrame.new(0, markerTopOffset + pivotAboveBottom, 0)
end

local function disableUnsupportedAnimationScripts(animal)
	local disabled = 0
	for _, descendant in animal:GetDescendants() do
		if descendant:IsA("BaseScript") and string.lower(descendant.Name) == "animate" then
			descendant.Disabled = true
			disabled = disabled + 1
		end
	end
	return disabled
end

local function findMountBody(model, root)
	for _, name in {"Body", "Torso", "UpperTorso"} do
		local candidate = model:FindFirstChild(name, true)
		if candidate and candidate:IsA("BasePart") then return candidate end
	end
	return root
end

local function getMountForward(model, mountBody)
	local head = model:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then
		local towardHead = Vector3.new(head.Position.X - mountBody.Position.X, 0, head.Position.Z - mountBody.Position.Z)
		if towardHead.Magnitude > 0.01 then return towardHead.Unit, "BodyToHead" end
	end
	local bodyForward = Vector3.new(mountBody.CFrame.LookVector.X, 0, mountBody.CFrame.LookVector.Z)
	if bodyForward.Magnitude > 0.01 then return bodyForward.Unit, "BodyLookVectorFallback" end
	return Vector3.new(0, 0, -1), "WorldNegativeZFallback"
end

function WildlifeService.new()
	local self = setmetatable({}, WildlifeService)
	self._activeBySpawn = setmetatable({}, {__mode = "k"})
	self._spawnByAnimal = setmetatable({}, {__mode = "k"})
	self._lastHits = {}
	self._lastNameRequests = {}
	self._lastMountInputs = {}
	self._cheetahAIs = setmetatable({}, {__mode = "k"})
	self._cheetahCount = 0
	self._wildCheetahCount = 0
	self._cheetahPersistentState = nil
	self._persistentCheetahAI = nil
	self._cheetahSpawnPoints = {}
	self._cheetahPopulationInitialized = false
	self._cheetahSessionGeneration = 0
	self._cheetahRespawnScheduled = false
	self._lastCheetahSpawnPoint = nil
	self._cheetahRandom = Random.new()
	self._jellyfishAIs = setmetatable({}, {__mode = "k"})
	self._sharkAIs = setmetatable({}, {__mode = "k"})
	self._tamingFeedback = Instance.new("RemoteEvent")
	self._tamingFeedback.Name = "CheetahTamingFeedback"
	self._tamingFeedback.Parent = ReplicatedStorage
	self._companionRemote = Instance.new("RemoteEvent")
	self._companionRemote.Name = "CheetahCompanionRemote"
	self._companionRemote.Parent = ReplicatedStorage
	self._request = Instance.new("RemoteEvent")
	self._request.Name = "WildlifeHitRequest"
	self._request.Parent = ReplicatedStorage
	self._result = Instance.new("RemoteEvent")
	self._result.Name = "WildlifeHitResult"
	self._result.Parent = ReplicatedStorage
	return self
end

function WildlifeService:_ensureCheetahInteraction(ai, reason)
	if not ai or not ai.Model.Parent or not ai.Root or not ai.Root.Parent then return nil end
	local prompt
	for _, descendant in ai.Model:GetDescendants() do
		if descendant:IsA("ProximityPrompt") and descendant.Name == "CheetahCompanionPrompt" then
			if not prompt then prompt = descendant else descendant:Destroy() end
		end
	end
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CheetahCompanionPrompt"
		prompt.Parent = ai.Root
		prompt.Triggered:Connect(function(player)
			local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local distance = playerRoot and (playerRoot.Position - ai.Root.Position).Magnitude or math.huge
			local canInteract = ai.Tamed and isAdmittedWorldPlayer(player) and ai.MountedPlayer == nil
			print(string.format("[MAYDEAD][CHEETAH][INTERACTION] Triggered by UserId=%d OwnerUserId=%s Distance=%.2f Mounted=%s PromptEnabled=%s CanInteract=%s",
				player.UserId, tostring(ai.OwnerUserId), distance, tostring(ai.MountedPlayer ~= nil), tostring(prompt.Enabled), tostring(canInteract)))
			if canInteract and distance <= CheetahConfig.MOUNT_INTERACTION_DISTANCE + 1 then
				print(string.format("[MAYDEAD][CHEETAH][UI][SERVER] FireClient UserId=%d Remote=%s Cheetah=%s",
					player.UserId, self._companionRemote:GetFullName(), ai.Model:GetFullName()))
				self._companionRemote:FireClient(player, "Open", ai:GetPublicState(), ai.Model)
				print("[MAYDEAD][CHEETAH][INTERACTION] CompanionUI open requested=true")
			end
		end)
	end
	prompt.Parent = ai.Root
	prompt.ActionText = "INTERAGIR"
	prompt.ObjectText = ai.Tamed and ai.CompanionName or CheetahConfig.COMPANION_DEFAULT_NAME
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = CheetahConfig.MOUNT_INTERACTION_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Enabled = ai.Tamed and ai.OwnerUserId ~= nil and ai.MountedPlayer == nil
	print(string.format("[MAYDEAD][CHEETAH][INTERACTION] reason=%s Tamed=%s OwnerUserId=%s PromptExists=true FullName=%s Parent=%s Enabled=%s Key=%s Distance=%.1f LOS=%s Hold=%.1f",
		reason, tostring(ai.Tamed), tostring(ai.OwnerUserId), prompt:GetFullName(), prompt.Parent:GetFullName(),
		tostring(prompt.Enabled), prompt.KeyboardKeyCode.Name, prompt.MaxActivationDistance,
		tostring(prompt.RequiresLineOfSight), prompt.HoldDuration))
	return prompt
end

function WildlifeService:_getAnimal(target)
	if typeof(target) ~= "Instance" then return nil, nil end
	local current = target
	while current and current ~= workspace do
		if current:IsA("Model") then
			if current:GetAttribute("Invulnerable") == true then return nil, nil end
			local animalType = current:GetAttribute("AnimalType")
			if WildlifeDefinitions[animalType] and current:FindFirstChildOfClass("Humanoid") then
				return current, animalType
			end
		end
		current = current.Parent
	end
	return nil, nil
end

function WildlifeService:_registerJellyfish(model)
	if not model:IsA("Model") or model.Name ~= JellyfishConfig.MODEL_NAME or self._jellyfishAIs[model] then
		return
	end
	local ai = JellyfishAI.new(
		model,
		function(player) return SurvivalService:IsPlayerAquatic(player) end,
		function(player, amount) return SurvivalService:DamagePlayer(player, amount) end,
		function(position) return SurvivalService:IsPointInTerrainWater(position) end
	)
	if not ai then
		warn("[MAYDEAD][JELLYFISH] Rejected model without a valid PrimaryPart: " .. model:GetFullName())
		return
	end
	self._jellyfishAIs[model] = ai
	print("[MAYDEAD][JELLYFISH] Registered aquatic hazard: " .. model:GetFullName())
end

function WildlifeService:_registerShark(model)
	if not model:IsA("Model") or model.Name ~= SharkConfig.MODEL_NAME or self._sharkAIs[model] then return end
	local ai = SharkAI.new(
		model,
		function(player) return SurvivalService:IsPlayerAquatic(player) end,
		function(player, amount) return SurvivalService:DamagePlayer(player, amount) end,
		function(position) return SurvivalService:IsPointInTerrainWater(position) end
	)
	if not ai then
		warn("[MAYDEAD][SHARK] Rejected model without a valid PrimaryPart: " .. model:GetFullName())
		return
	end
	self._sharkAIs[model] = ai
	print("[MAYDEAD][SHARK] Registered aquatic predator: " .. model:GetFullName())
end

function WildlifeService:_syncCheetahRuntimeAttributes(ai, spawnPoint)
	ai.Model:SetAttribute("Tamed", ai.Tamed == true)
	ai.Model:SetAttribute("OwnerUserId", ai.OwnerUserId)
	ai.Model:SetAttribute("OriginalTamerUserId", ai.OriginalTamerUserId)
	ai.Model:SetAttribute("WorldCompanion", ai.Tamed == true)
	ai.Model:SetAttribute("FollowTargetUserId", ai.FollowTargetUserId)
	ai.Model:SetAttribute("Trust", ai.Trust)
	ai.Model:SetAttribute("Command", ai.Tamed and ai.Command or "Wild")
	ai.Model:SetAttribute("Mounted", ai.MountedPlayer ~= nil)
	ai.Model:SetAttribute("CompanionName", ai.Tamed and ai.CompanionName or nil)
	ai.Model:SetAttribute("SpawnPointId", ai.Tamed and nil or (spawnPoint and spawnPoint.Name or nil))
end

function WildlifeService:_releaseWildSpawn(ai, reason)
	local animal = ai.Model
	local spawnPoint = self._spawnByAnimal[animal]
	if not spawnPoint then return nil end
	self._spawnByAnimal[animal] = nil
	if self._activeBySpawn[spawnPoint] == animal then self._activeBySpawn[spawnPoint] = nil end
	self._wildCheetahCount = math.max(0, self._wildCheetahCount - 1)
	self:_syncCheetahRuntimeAttributes(ai, nil)
	print(string.format("[MAYDEAD][CHEETAH][SPAWN] SpawnPoint=%s Action=ReleasedBy%s RespawnIn=%d",
		spawnPoint.Name, reason, CheetahConfig.WILD_RESPAWN_DELAY))
	return spawnPoint
end

function WildlifeService:_spawnAt(spawnPoint, animalType, persistentState)
	if self._activeBySpawn[spawnPoint] or not spawnPoint:IsDescendantOf(workspace) then return end
	if animalType == "Cheetah" and not persistentState and self._wildCheetahCount >= CheetahConfig.MAX_ACTIVE_WILD then return end
	local definition = WildlifeDefinitions[animalType]
	local assetImports = ServerStorage:FindFirstChild("AssetImports")
	local template = assetImports and assetImports:FindFirstChild(definition.TemplateName)
	print("[MAYDEAD] " .. animalType .. " template found = " .. tostring(template ~= nil and template:IsA("Model")))
	if not template or not template:IsA("Model") then
		warn("[MAYDEAD] Wildlife template missing: ServerStorage.AssetImports." .. definition.TemplateName)
		return
	end
	local wildlifeFolder = workspace:FindFirstChild("Wildlife") or Instance.new("Folder")
	wildlifeFolder.Name = "Wildlife"
	wildlifeFolder.Parent = workspace
	local animalFolderName = animalType .. "s"
	local animalFolder = wildlifeFolder:FindFirstChild(animalFolderName) or Instance.new("Folder")
	animalFolder.Name = animalFolderName
	animalFolder.Parent = wildlifeFolder
	local animal = template:Clone()
	animal.Name = animalType
	animal:SetAttribute("AnimalType", animalType)
	animal:SetAttribute("IsDead", false)
	animal:SetAttribute("SpawnPointName", spawnPoint.Name)
	local humanoid = animal:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		animal:Destroy()
		warn("[MAYDEAD] " .. animalType .. " template has no Humanoid")
		return
	end
	humanoid.MaxHealth = definition.MaxHealth
	humanoid.Health = definition.MaxHealth
	local disabledAnimationScripts = disableUnsupportedAnimationScripts(animal)
	if disabledAnimationScripts > 0 then
		print("[MAYDEAD] " .. animalType .. " incompatible Animate scripts disabled = " .. disabledAnimationScripts)
	end
	if animalType == "Cheetah" then
		if CheetahConfig.CHEETAH_SCALE ~= 1 then animal:ScaleTo(CheetahConfig.CHEETAH_SCALE) end
		local locomotionRoot = animal:FindFirstChild("HumanoidRootPart")
			or animal:FindFirstChild("Torso")
			or animal.PrimaryPart
			or animal:FindFirstChildWhichIsA("BasePart", true)
		if not locomotionRoot or not locomotionRoot:IsA("BasePart") then
			animal:Destroy()
			warn("[MAYDEAD][CHEETAH] Template has no locomotion root")
			return
		end
		local animator = humanoid:FindFirstChildOfClass("Animator")
		local animations = {}
		local joints = {}
		local animationControllers = {}
		for _, descendant in animal:GetDescendants() do
			if descendant:IsA("Animation") then table.insert(animations, descendant.Name .. "=" .. descendant.AnimationId) end
			if descendant:IsA("AnimationController") then table.insert(animationControllers, descendant:GetFullName()) end
			if descendant:IsA("Motor6D") or descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
				table.insert(joints, string.format("%s:%s(%s->%s)", descendant.ClassName, descendant.Name,
					descendant.Part0 and descendant.Part0.Name or "nil", descendant.Part1 and descendant.Part1.Name or "nil"))
			end
			if descendant:IsA("BasePart") then
				descendant.Anchored = false
				descendant.CanTouch = false
				if descendant.Name ~= "HumanoidRootPart" and descendant.Name ~= "Torso" then descendant.CanCollide = false end
			end
		end
		print(string.format("[MAYDEAD][CHEETAH] Hierarchy descendants=%d Root=%s Humanoid=true Animator=%s AnimationControllers=[%s] Animations=[%s] Joints=[%s]",
			#animal:GetDescendants(), locomotionRoot.Name, tostring(animator ~= nil), table.concat(animationControllers, ", "),
			table.concat(animations, ", "), table.concat(joints, ", ")))
	end
	animal:PivotTo(getSpawnPivot(spawnPoint, animal))
	animal.Parent = animalFolder
	self._activeBySpawn[spawnPoint] = animal
	self._spawnByAnimal[animal] = spawnPoint
	if animalType == "Cheetah" then
		self._cheetahCount += 1
		local root = animal:FindFirstChild("HumanoidRootPart") or animal:FindFirstChild("Torso") or animal.PrimaryPart
		if root and root:IsA("BasePart") then pcall(function() root:SetNetworkOwner(nil) end) end
		local ai = CheetahAI.new(animal, animal:GetPivot().Position)
		ai.CanCompleteTaming = function()
			for _, otherAI in self._cheetahAIs do
				if otherAI ~= ai and otherAI.Tamed then return false end
			end
			return true
		end
		if persistentState then
			ai:SetTamingState(persistentState)
			self._persistentCheetahAI = ai
		end
		local isWild = not ai.Tamed
		if isWild then
			self._wildCheetahCount += 1
			self._lastCheetahSpawnPoint = spawnPoint
		else
			self._activeBySpawn[spawnPoint] = nil
			self._spawnByAnimal[animal] = nil
		end
		self:_syncCheetahRuntimeAttributes(ai, isWild and spawnPoint or nil)
		ai.OnTamingChanged = function(changedAI, gain, blockedByExistingCompanion)
			local successfulFeed = typeof(gain) == "number" and gain > 0
			local trackedAI = self._persistentCheetahAI
			local canTrack = changedAI.Tamed or not trackedAI or not trackedAI.Model.Parent or not trackedAI.Tamed
			if canTrack then
				self._cheetahPersistentState = changedAI:GetTamingState()
				self._persistentCheetahAI = changedAI
			end
			local releasedSpawn
			if changedAI.Tamed then releasedSpawn = self:_releaseWildSpawn(changedAI, "Taming") end
			self:_syncCheetahRuntimeAttributes(changedAI, self._spawnByAnimal[changedAI.Model])
			self:_ensureCheetahInteraction(changedAI, "TamingChanged")
			local userId = changedAI.TamingPlayerUserId
			local player = userId and Players:GetPlayerByUserId(userId)
			if player and blockedByExistingCompanion then
				self._tamingFeedback:FireClient(player, "Blocked", {Trust = changedAI.Trust, Reason = "WorldCompanionExists"})
			end
			if player and successfulFeed then
				self._tamingFeedback:FireClient(player, changedAI.Tamed and "Completed" or "Progress", {
					Trust = changedAI.Trust,
					Gain = gain,
				})
				if changedAI.Tamed then
					task.delay(1.8, function()
						if changedAI.Model.Parent and changedAI.Tamed
							and changedAI.OwnerUserId == player.UserId and player.Parent
						then
							self._companionRemote:FireClient(player, "PromptName", changedAI:GetPublicState(), changedAI.Model)
						end
					end)
				end
			end
			if releasedSpawn then self:_scheduleCheetahRespawn("Tamed") end
		end
		self._cheetahAIs[animal] = ai
		self:_ensureCheetahInteraction(ai, "SpawnOrRestore")
		ai:Start()
	end
	print("[MAYDEAD] " .. animalType .. " spawned at " .. spawnPoint.Name)
	return animal
end

function WildlifeService:GetPersistentState()
	if self._persistentCheetahAI and self._persistentCheetahAI.Model.Parent then
		return self._persistentCheetahAI:GetTamingState()
	end
	return self._cheetahPersistentState
end

function WildlifeService:RestorePersistentState(state)
	if state == nil then self._cheetahPersistentState = nil; self._persistentCheetahAI = nil; return true end
	if typeof(state) ~= "table" or typeof(state.Trust) ~= "number" or state.Trust < 0 or state.Trust > 100 then return false end
	local ownerUserId = typeof(state.OwnerUserId) == "number" and state.OwnerUserId or nil
	local companionName = CheetahConfig.COMPANION_DEFAULT_NAME
	if state.Tamed == true and ownerUserId and state.CompanionName ~= nil then
		companionName = self:_filterCompanionNameForUserId(ownerUserId, state.CompanionName)
			or CheetahConfig.COMPANION_DEFAULT_NAME
	end
	self._cheetahPersistentState = {
		Version = state.Version,
		Exists = state.Exists,
		Alive = state.Alive,
		Trust = state.Trust,
		HasReceivedTamingFeed = state.HasReceivedTamingFeed == true or state.Trust > 0,
		TamingPlayerUserId = typeof(state.TamingPlayerUserId) == "number" and state.TamingPlayerUserId or nil,
		Tamed = state.Tamed == true,
		OwnerUserId = ownerUserId,
		OriginalTamerUserId = typeof(state.OriginalTamerUserId) == "number" and state.OriginalTamerUserId or ownerUserId,
		Health = state.Health,
		Hunger = state.Hunger,
		Command = state.Command,
		Inventory = state.Inventory,
		MountStamina = state.MountStamina,
		Position = state.Position,
		CompanionName = companionName,
	}
	return true
end

function WildlifeService:_filterCompanionNameForUserId(userId, requestedName)
	if typeof(requestedName) ~= "string" or requestedName:find("%c") then return nil end
	local cleaned = trim(requestedName):gsub("%s+", " ")
	local length = utf8.len(cleaned)
	if not length or length < CheetahConfig.COMPANION_NAME_MIN_LENGTH
		or length > CheetahConfig.COMPANION_NAME_MAX_LENGTH
	then
		return nil
	end
	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(cleaned, userId, Enum.TextFilterContext.PublicChat)
		return result:GetNonChatStringForBroadcastAsync()
	end)
	if not ok or typeof(filtered) ~= "string" then return nil end
	filtered = trim(filtered)
	local filteredLength = utf8.len(filtered)
	if not filteredLength or filteredLength < CheetahConfig.COMPANION_NAME_MIN_LENGTH
		or filteredLength > CheetahConfig.COMPANION_NAME_MAX_LENGTH
		or filtered:match("^#+$")
	then
		return nil
	end
	return filtered
end

function WildlifeService:_filterCompanionName(player, requestedName)
	return self:_filterCompanionNameForUserId(player.UserId, requestedName)
end

function WildlifeService:_getWorldCompanionAI(player)
	if not isAdmittedWorldPlayer(player) then return nil end
	for _, ai in self._cheetahAIs do if ai.Tamed then return ai end end
end

function WildlifeService:_mount(player, ai)
	if ai.MountedPlayer or ai.Hunger <= CheetahConfig.MOUNT_REFUSE_HUNGER_THRESHOLD then return end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or (root.Position - ai.Root.Position).Magnitude > CheetahConfig.MOUNT_INTERACTION_DISTANCE then return end
	local boxCFrame, boxSize = ai.Model:GetBoundingBox()
	local mountBody = findMountBody(ai.Model, ai.Root)
	local attachment = mountBody:FindFirstChild("CheetahMountAttachment")
	if attachment and not attachment:IsA("Attachment") then attachment:Destroy(); attachment = nil end
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "CheetahMountAttachment"
		attachment.Parent = mountBody
	end
	local localMountPosition = Vector3.new(0, mountBody.Size.Y * 0.5 + CheetahConfig.MOUNT_BACK_CLEARANCE, CheetahConfig.MOUNT_FORWARD_OFFSET)
	local mountWorldPosition = mountBody.CFrame:PointToWorldSpace(localMountPosition)
	local cheetahForward, forwardSource = getMountForward(ai.Model, mountBody)
	attachment.WorldCFrame = CFrame.lookAt(mountWorldPosition, mountWorldPosition + cheetahForward, Vector3.yAxis)
	local mountOffset = ai.Root.CFrame:ToObjectSpace(mountBody.CFrame * attachment.CFrame)
	local seat = Instance.new("Seat"); seat.Name = "CheetahMountSeat"; seat.Size = Vector3.new(2, 0.5, 2)
	seat.Transparency = 1; seat.CanCollide = false; seat.Massless = true; seat.CFrame = attachment.WorldCFrame; seat.Parent = ai.Model
	local weld = Instance.new("Weld"); weld.Name = "CheetahMountWeld"; weld.Part0 = ai.Root; weld.Part1 = seat
	weld.C0 = ai.Root.CFrame:ToObjectSpace(seat.CFrame); weld.C1 = CFrame.identity; weld.Parent = seat
	seat:SetAttribute("MountBaseC0", weld.C0)
	seat:Sit(humanoid); ai.MountedPlayer = player; ai.OwnerInteractionHold = true
	task.defer(function()
		if not seat.Parent then return end
		local riderRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		print(string.format("[MAYDEAD][CHEETAH][MOUNT_ORIENTATION] ForwardSource=%s BodyLook=%s CheetahForward=%s MountForward=%s RiderForward=%s MountUp=%s RiderUp=%s RotationOffset=%s",
			forwardSource, tostring(mountBody.CFrame.LookVector), tostring(cheetahForward), tostring(attachment.WorldCFrame.LookVector),
			tostring(riderRoot and riderRoot.CFrame.LookVector or Vector3.zero), tostring(attachment.WorldCFrame.UpVector),
			tostring(riderRoot and riderRoot.CFrame.UpVector or Vector3.zero), tostring(attachment.CFrame.Rotation)))
	end)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Parent and seat.Occupant == nil and ai.MountedPlayer == player and not ai.Dismounting then
			task.defer(function() if ai.MountedPlayer == player then self:_dismount(player, ai) end end)
		end
	end)
	self:_ensureCheetahInteraction(ai, "MountStarted")
	print(string.format("[MAYDEAD][CHEETAH][MOUNT] Mounted=true Owner=%d Body=%s BodySize=%s BoundingBox=%s Scale=%.2f Attachment=%s RiderOffset=%s HipHeight=%.2f MountSpeed=%d/%d/%d PromptEnabled=false",
		player.UserId, mountBody:GetFullName(), tostring(mountBody.Size), tostring(boxSize), ai.Model:GetScale(), attachment:GetFullName(),
		tostring(mountOffset), humanoid.HipHeight, CheetahConfig.MOUNT_WALK_SPEED, CheetahConfig.MOUNT_RUN_SPEED, CheetahConfig.MOUNT_SPRINT_SPEED))
	self._companionRemote:FireClient(player, "Mounted", ai:GetPublicState())
end

function WildlifeService:_dismount(player, ai)
	if ai.MountedPlayer ~= player or ai.Dismounting then return end
	ai.Dismounting = true
	local seat = ai.Model:FindFirstChild("CheetahMountSeat")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.Sit = false end
	if seat then seat:Destroy() end
	ai.MountedPlayer = nil; ai.MountInput = Vector3.zero; ai.MountSprint = false
	ai.OwnerInteractionHold = true
	if ai.Command == "Stay" then ai.StayPosition = ai.Root.Position end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local desired = (ai.Root.CFrame * CFrame.new(CheetahConfig.DISMOUNT_SIDE_OFFSET)).Position
		local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {ai.Model, player.Character}; params.IgnoreWater = false
		local ground = workspace:Raycast(desired + Vector3.new(0, CheetahConfig.DISMOUNT_RAY_HEIGHT, 0),
			Vector3.new(0, -CheetahConfig.DISMOUNT_RAY_DEPTH, 0), params)
		if ground and ground.Material ~= Enum.Material.Water then
			root.CFrame = CFrame.new(ground.Position + Vector3.new(0, 3, 0), ground.Position + Vector3.new(0, 3, 0) + ai.Root.CFrame.LookVector)
		end
	end
	self:_ensureCheetahInteraction(ai, "DismountComplete")
	task.defer(function() if ai.Model.Parent and not ai.MountedPlayer then self:_ensureCheetahInteraction(ai, "DismountSettled") end end)
	ai.Dismounting = false
	print("[MAYDEAD][CHEETAH][INTERACT] Dismount complete, prompt enabled=true")
	print(string.format("[MAYDEAD][CHEETAH][DISMOUNT] Mounted=false CurrentRider=nil InteractionLock=false PromptExists=true PromptEnabled=true DistanceOwner=%.2f",
		root and (root.Position - ai.Root.Position).Magnitude or -1))
	self._companionRemote:FireClient(player, "Dismounted", ai:GetPublicState())
end

function WildlifeService:_mountJump(player, ai)
	local now=os.clock(); local grounded=false; local material=nil
	if ai.MountedPlayer==player and ai.Humanoid.Health>0 and now-ai.LastMountJump>=CheetahConfig.MOUNT_JUMP_COOLDOWN and ai.MountStamina>=CheetahConfig.MOUNT_JUMP_STAMINA_COST then
		local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={ai.Model,player.Character}; params.IgnoreWater=false
		local result=workspace:Raycast(ai.Root.Position,Vector3.new(0,-CheetahConfig.MOUNT_JUMP_GROUND_CHECK_DISTANCE,0),params)
		grounded=result~=nil and result.Material~=Enum.Material.Water; material=result and result.Material or nil
		if grounded then
			local velocity=ai.Root.AssemblyLinearVelocity
			ai.Root.AssemblyLinearVelocity=Vector3.new(velocity.X,CheetahConfig.MOUNT_JUMP_VELOCITY,velocity.Z)
			ai.MountStamina=math.max(0,ai.MountStamina-CheetahConfig.MOUNT_JUMP_STAMINA_COST); ai.LastMountJump=now
		end
	end
	if CheetahConfig.CHEETAH_MOUNT_JUMP_DEBUG then
		print(string.format("[MAYDEAD][CHEETAH][JUMP] Requested=true ValidRider=%s Grounded=%s Material=%s Stamina=%.1f JumpVelocity=%.1f",
			tostring(ai.MountedPlayer==player),tostring(grounded),material and material.Name or "nil",ai.MountStamina,CheetahConfig.MOUNT_JUMP_VELOCITY))
	end
	return grounded
end

function WildlifeService:_chooseCheetahSpawnPoint()
	local validPoints = {}
	for _, spawnPoint in self._cheetahSpawnPoints do
		if isValidSpawnPoint(spawnPoint)
			and spawnPoint:IsDescendantOf(workspace)
			and not self._activeBySpawn[spawnPoint]
		then
			table.insert(validPoints, spawnPoint)
		end
	end
	if #validPoints == 0 then return nil end
	if #validPoints > 1 and self._lastCheetahSpawnPoint then
		local alternatives = {}
		for _, spawnPoint in validPoints do
			if spawnPoint ~= self._lastCheetahSpawnPoint then table.insert(alternatives, spawnPoint) end
		end
		if #alternatives > 0 then validPoints = alternatives end
	end
	return validPoints[self._cheetahRandom:NextInteger(1, #validPoints)]
end

function WildlifeService:_spawnSingleWildCheetah()
	if not self._cheetahPopulationInitialized
		or self._cheetahRespawnScheduled
		or self._wildCheetahCount >= CheetahConfig.MAX_ACTIVE_WILD
	then
		return false
	end
	local spawnPoint = self:_chooseCheetahSpawnPoint()
	if not spawnPoint then
		warn("[MAYDEAD][CHEETAH][POPULATION] No valid spawn point available")
		return false
	end
	self:_spawnAt(spawnPoint, "Cheetah")
	if self._activeBySpawn[spawnPoint] then
		print(string.format("[MAYDEAD][CHEETAH][POPULATION] SpawnPoint=%s WildCount=%d",
			spawnPoint.Name, self._wildCheetahCount))
		return true
	end
	return false
end

function WildlifeService:_scheduleCheetahRespawn(reason)
	if self._wildCheetahCount >= CheetahConfig.MAX_ACTIVE_WILD or self._cheetahRespawnScheduled then return end
	self._cheetahRespawnScheduled = true
	local generation = self._cheetahSessionGeneration
	print(string.format("[MAYDEAD][CHEETAH][POPULATION] Reason=%s WildCount=%d RespawnIn=%d",
		reason, self._wildCheetahCount, CheetahConfig.WILD_RESPAWN_DELAY))
	task.delay(CheetahConfig.WILD_RESPAWN_DELAY, function()
		if generation ~= self._cheetahSessionGeneration or not self._cheetahPopulationInitialized then return end
		self._cheetahRespawnScheduled = false
		self:_spawnSingleWildCheetah()
	end)
end

function WildlifeService:_scheduleRespawn(spawnPoint, animalType, definition)
	if animalType == "Cheetah" then
		self:_scheduleCheetahRespawn("Death")
		return
	end
	print("[MAYDEAD] " .. animalType .. " respawn scheduled = " .. definition.RespawnTime)
	task.delay(definition.RespawnTime, function()
		if not spawnPoint:IsDescendantOf(workspace) or self._activeBySpawn[spawnPoint] then return end
		self:_spawnAt(spawnPoint, animalType)
		if self._activeBySpawn[spawnPoint] then
			print("[MAYDEAD] " .. animalType .. " respawned = " .. spawnPoint.Name)
		end
	end)
end

function WildlifeService:_kill(player, animal, animalType, definition)
	if animal:GetAttribute("IsDead") then return end
	animal:SetAttribute("IsDead", true)
	local sharkAI = self._sharkAIs[animal]
	if sharkAI then
		sharkAI:Kill()
		print("[MAYDEAD] Shark killed by " .. player.Name .. " | loot = none")
		task.delay(definition.RespawnTime, function()
			if self._sharkAIs[animal] == sharkAI and animal.Parent then sharkAI:Respawn() end
		end)
		return
	end
	local spawnPoint = self._spawnByAnimal[animal]
	self._spawnByAnimal[animal] = nil
	if spawnPoint then self._activeBySpawn[spawnPoint] = nil end
	local ai = self._cheetahAIs[animal]
	local wasTamed = ai and ai.Tamed
	local dropAmount = wasTamed and 0 or (definition.Drop.Amount
		or math.random(definition.Drop.MinAmount, definition.Drop.MaxAmount))
	local result = dropAmount > 0 and InventoryService:AddItem(player, definition.Drop.ItemId, dropAmount)
		or {Added = 0, Remaining = 0}
	if result.Remaining > 0 then
		warn("[MAYDEAD] Wildlife reward invariant failed; " .. animalType .. " retained")
		animal:SetAttribute("IsDead", false)
		local humanoid = animal:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Health = 1 end
		if spawnPoint then
			self._activeBySpawn[spawnPoint] = animal
			self._spawnByAnimal[animal] = spawnPoint
		end
		return
	end
	if ai then
		if wasTamed then
			self._cheetahPersistentState = ai:GetTamingState()
			self._cheetahPersistentState.Alive = false
			self._cheetahPersistentState.Tamed = false
			self._cheetahPersistentState.OwnerUserId = nil
		end
		ai:Stop(); self._cheetahAIs[animal] = nil; self._cheetahCount = math.max(0, self._cheetahCount - 1)
		if not wasTamed then self._wildCheetahCount = math.max(0, self._wildCheetahCount - 1) end
		if self._persistentCheetahAI == ai then self._persistentCheetahAI = nil end
	end
	print("[MAYDEAD] " .. animalType .. " killed by " .. player.Name)
	print("[MAYDEAD] RawMeat awarded = " .. dropAmount)
	if spawnPoint then self:_scheduleRespawn(spawnPoint, animalType, definition) end
	task.delay(definition.CorpseLifetime, function()
		if animal.Parent then animal:Destroy() end
	end)
end

function WildlifeService:_handleHit(player, target)
	local animal, animalType = self:_getAnimal(target)
	local definition = animalType and WildlifeDefinitions[animalType]
	if not animal or not definition or animal:GetAttribute("IsDead") then return end
	local spawnPoint = self._spawnByAnimal[animal]
	local registeredCheetahAI = self._cheetahAIs[animal]
	local registeredSharkAI = self._sharkAIs[animal]
	if not registeredSharkAI and not (registeredCheetahAI and registeredCheetahAI.Tamed)
		and (not spawnPoint or self._activeBySpawn[spawnPoint] ~= animal)
	then
		return
	end
	local humanoid = animal:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local character = player.Character
	local playerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local tool = character and character:FindFirstChildOfClass("Tool")
	if not playerHumanoid or playerHumanoid.Health <= 0 or not rootPart or not tool then return end
	local toolDefinition = definition.AllowedTools[tool.Name]
	if not toolDefinition or InventoryService:GetActiveItem(player) ~= toolDefinition.ItemId then return end
	if closestDistance(rootPart, animal) > definition.AttackRange then return end
	local now = os.clock()
	if now - (self._lastHits[player] or 0) < definition.AttackCooldown then return end
	self._lastHits[player] = now
	local fatal = humanoid.Health - toolDefinition.Damage <= 0
	local maximumDrop = definition.Drop and (definition.Drop.Amount or definition.Drop.MaxAmount) or 0
	local cheetahAI = registeredCheetahAI
	if fatal and maximumDrop > 0 and not (cheetahAI and cheetahAI.Tamed)
		and not InventoryService:CanAddItem(player, definition.Drop.ItemId, maximumDrop)
	then
		print("[MAYDEAD] " .. animalType .. " kill rejected: inventory cannot secure RawMeat x" .. maximumDrop)
		return
	end
	local previousHealth = humanoid.Health
	humanoid:TakeDamage(toolDefinition.Damage)
	local ai = self._cheetahAIs[animal]
	if ai then ai:RegisterAggression(player, toolDefinition.Damage) end
	print("[MAYDEAD] " .. animalType .. " hit by " .. tool.Name .. ", Health = " .. math.floor(humanoid.Health))
	self._result:FireClient(player, toolDefinition.ImpactSoundName)
	if humanoid.Health <= 0 then self:_kill(player, animal, animalType, definition) end
	DamageFeedbackService:NotifyDealt(player, previousHealth - humanoid.Health, animal)
end

function WildlifeService:_logCheetahPopulation()
	local tamedCount = 0
	for _, ai in self._cheetahAIs do
		if ai.Tamed then tamedCount += 1 end
	end
	print(string.format("[MAYDEAD][CHEETAH][POPULATION] SpawnPoints=%d WildCount=%d CompanionCount=%d RespawnScheduled=%s",
		#self._cheetahSpawnPoints, self._wildCheetahCount, tamedCount, tostring(self._cheetahRespawnScheduled)))
end

function WildlifeService:_initializeCheetahPopulation()
	if self._cheetahPopulationInitialized then return end
	self._cheetahPopulationInitialized = true
	self._cheetahSessionGeneration += 1

	local persistentState = self._cheetahPersistentState
	if persistentState and persistentState.Alive ~= false and #self._cheetahSpawnPoints > 0 then
		self:_spawnAt(self._cheetahSpawnPoints[1], "Cheetah", persistentState)
	end
	self:_spawnSingleWildCheetah()
	self:_logCheetahPopulation()
end

function WildlifeService:_clearCheetahRuntime()
	if not self._cheetahPopulationInitialized then return end
	for animal, ai in self._cheetahAIs do
		if ai.Tamed then self._cheetahPersistentState = ai:GetTamingState() end
		local spawnPoint = self._spawnByAnimal[animal]
		if spawnPoint and self._activeBySpawn[spawnPoint] == animal then self._activeBySpawn[spawnPoint] = nil end
		self._spawnByAnimal[animal] = nil
		ai:Stop()
		if animal.Parent then animal:Destroy() end
	end
	self._cheetahAIs = setmetatable({}, {__mode = "k"})
	self._cheetahCount = 0
	self._wildCheetahCount = 0
	self._persistentCheetahAI = nil
	self._cheetahPopulationInitialized = false
	self._cheetahRespawnScheduled = false
	self._lastCheetahSpawnPoint = nil
	self._cheetahSessionGeneration += 1
	print("[MAYDEAD][CHEETAH][SPAWN] Action=RuntimeCleared")
end

function WildlifeService:_refreshCheetahSessionState()
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("SessionStarted") == true then
			self:_initializeCheetahPopulation()
			return
		end
	end
	self:_clearCheetahRuntime()
end

function WildlifeService:Start()
	local animalsFolder = workspace:FindFirstChild(JellyfishConfig.ANIMALS_FOLDER_NAME)
	if animalsFolder then
		for _, child in animalsFolder:GetChildren() do
			self:_registerJellyfish(child)
			self:_registerShark(child)
		end
		animalsFolder.ChildAdded:Connect(function(child)
			self:_registerJellyfish(child)
			self:_registerShark(child)
		end)
	else
		warn("[MAYDEAD][WILDLIFE] Workspace.Animals folder not found; JellyFish and Shark registration skipped")
	end
	RunService.Heartbeat:Connect(function(deltaTime)
		for model, ai in self._jellyfishAIs do
			if not ai:Step(deltaTime) then
				self._jellyfishAIs[model] = nil
			end
		end
		for model, ai in self._sharkAIs do
			if not ai:Step(deltaTime) then self._sharkAIs[model] = nil end
		end
	end)

	local bisonSpawns = workspace:FindFirstChild("BisonSpawns")
	if not bisonSpawns then
		bisonSpawns = Instance.new("Folder")
		bisonSpawns.Name = "BisonSpawns"
		bisonSpawns.Parent = workspace
	end
	print("[MAYDEAD] Bison spawn folder = " .. bisonSpawns:GetFullName() .. " | class = " .. bisonSpawns.ClassName)
	print("[MAYDEAD] Bison spawn children = " .. #bisonSpawns:GetChildren())
	local count = 0
	for _, spawnPoint in bisonSpawns:GetChildren() do
		print("[MAYDEAD] Bison spawn candidate = " .. spawnPoint.Name .. " | class = " .. spawnPoint.ClassName)
		if isValidSpawnPoint(spawnPoint) then
			count = count + 1
			self:_spawnAt(spawnPoint, "Bison")
		else
			warn("[MAYDEAD] Bison spawn rejected: " .. spawnPoint.Name
				.. " | class = " .. spawnPoint.ClassName
				.. " | reason = expected BasePart or Model")
		end
	end
	print("[MAYDEAD] Bison valid spawn points = " .. count)
	if count == 0 then warn("[MAYDEAD] No Bison spawn points found") end
	bisonSpawns.ChildAdded:Connect(function(child)
		print("[MAYDEAD] Bison spawn candidate = " .. child.Name .. " | class = " .. child.ClassName)
		if isValidSpawnPoint(child) then
			self:_spawnAt(child, "Bison")
		else
			warn("[MAYDEAD] Bison spawn rejected: " .. child.Name
				.. " | class = " .. child.ClassName
				.. " | reason = expected BasePart or Model")
		end
	end)
	local cheetahSpawns = workspace:FindFirstChild(CheetahConfig.WILD_SPAWN_FOLDER_NAME)
	if not cheetahSpawns then
		cheetahSpawns = Instance.new("Folder")
		cheetahSpawns.Name = CheetahConfig.WILD_SPAWN_FOLDER_NAME
		cheetahSpawns.Parent = workspace
	end
	for _, spawnPoint in cheetahSpawns:GetChildren() do
		if isValidSpawnPoint(spawnPoint) then table.insert(self._cheetahSpawnPoints, spawnPoint) end
	end
	table.sort(self._cheetahSpawnPoints, function(left, right) return left.Name < right.Name end)
	print("[MAYDEAD][CHEETAH] Valid spawn points = " .. #self._cheetahSpawnPoints)
	if #self._cheetahSpawnPoints == 0 then warn("[MAYDEAD][CHEETAH] No valid Workspace.CheetahSpawns children found") end
	cheetahSpawns.ChildAdded:Connect(function(child)
		if not isValidSpawnPoint(child) then return end
		table.insert(self._cheetahSpawnPoints, child)
		table.sort(self._cheetahSpawnPoints, function(left, right) return left.Name < right.Name end)
		if self._cheetahPopulationInitialized then self:_spawnSingleWildCheetah() end
	end)
	Players.PlayerRemoving:Connect(function(player)
		self._lastHits[player] = nil
		self._lastNameRequests[player] = nil
		self._lastMountInputs[player] = nil
		for _, ai in self._cheetahAIs do
			if ai.FollowTargetUserId == player.UserId then ai:SetCommand("Stay") end
		end
		for _, ai in self._jellyfishAIs do ai:RemovePlayer(player) end
		for _, ai in self._sharkAIs do ai:RemovePlayer(player) end
		task.defer(function() self:_refreshCheetahSessionState() end)
	end)
	Players.PlayerAdded:Connect(function(player)
		player:GetAttributeChangedSignal("SessionStarted"):Connect(function()
			task.defer(function() self:_refreshCheetahSessionState() end)
		end)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				local ai = self:_getWorldCompanionAI(player)
				if ai then self:_ensureCheetahInteraction(ai, "OwnerRespawn") end
			end)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player:GetAttributeChangedSignal("SessionStarted"):Connect(function()
			task.defer(function() self:_refreshCheetahSessionState() end)
		end)
	end
	self:_refreshCheetahSessionState()
	task.spawn(function()
		while true do
			task.wait(5)
			for _, ai in self._cheetahAIs do
				if ai.TamingSessionActive and ai.LastSuccessfulTamingFeedTime
					and os.clock() - ai.LastSuccessfulTamingFeedTime >= CheetahConfig.TAMING_SESSION_TIMEOUT
				then
					ai.TamingSessionActive = false
					local tamingPlayer = ai.TamingPlayerUserId and Players:GetPlayerByUserId(ai.TamingPlayerUserId)
					if tamingPlayer then self._tamingFeedback:FireClient(tamingPlayer, "TimedOut", {Trust = ai.Trust}) end
					ai.TamingPlayerUserId = nil
				end
				if ai.Tamed and not ai.MountedPlayer then
					local prompt = ai.Model:FindFirstChild("CheetahCompanionPrompt", true)
					if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then
						self:_ensureCheetahInteraction(ai, "LifecycleRepair")
					end
				end
			end
		end
	end)
	self._request.OnServerEvent:Connect(function(player, target)
		if player:GetAttribute("SessionStarted") ~= true then return end
		self:_handleHit(player, target)
	end)
	self._companionRemote.OnServerEvent:Connect(function(player, action, data)
		if player:GetAttribute("SessionStarted") ~= true then return end
		local ai = self:_getWorldCompanionAI(player); if not ai then return end
		if action == "Command" and (data == "Follow" or data == "Stay") then ai:SetCommand(data, player)
		elseif action == "DepositRawMeat" then
			if InventoryService:HasItem(player, "RawMeat", 1) and ai:AddFood(1) == 1 then
				local removed = InventoryService:RemoveItem(player, "RawMeat", 1); if removed.Removed ~= 1 then ai:RemoveFood(1) end
			end
		elseif action == "WithdrawRawMeat" then
			if InventoryService:CanAddItem(player, "RawMeat", 1) and ai:RemoveFood(1) == 1 then
				local added = InventoryService:AddItem(player, "RawMeat", 1); if added.Added ~= 1 then ai:AddFood(1) end
			end
		elseif action == "Mount" then self:_mount(player, ai)
		elseif action == "Dismount" then self:_dismount(player, ai)
		elseif action == "MountJump" then self:_mountJump(player, ai)
		elseif action == "MountInput" then
			if ai.MountedPlayer ~= player or typeof(data) ~= "table" or not isFiniteVector3(data.Direction) then return end
			local now = os.clock()
			if now - (self._lastMountInputs[player] or -math.huge) < CheetahConfig.MOUNT_INPUT_MIN_INTERVAL then return end
			self._lastMountInputs[player] = now
			ai:SetMountInput(player, data.Direction, data.Sprint)
			return
		elseif action == "SetName" then
			if player.UserId ~= ai.OriginalTamerUserId then return end
			local now = os.clock()
			if now - (self._lastNameRequests[player] or -math.huge) < CheetahConfig.COMPANION_RENAME_COOLDOWN then return end
			self._lastNameRequests[player] = now
			local filteredName = self:_filterCompanionName(player, data)
			if not filteredName then
				self._companionRemote:FireClient(player, "NameResult", {Ok = false, Error = "InvalidName"})
				return
			end
			ai.CompanionName = filteredName
			self:_syncCheetahRuntimeAttributes(ai, nil)
			self:_ensureCheetahInteraction(ai, "NameChanged")
			self._cheetahPersistentState = ai:GetTamingState()
			self._companionRemote:FireClient(player, "NameResult", {Ok = true, CompanionName = filteredName})
		end
		self._cheetahPersistentState = ai:GetTamingState(); self._companionRemote:FireClient(player, "State", ai:GetPublicState())
	end)
end

return WildlifeService.new()
