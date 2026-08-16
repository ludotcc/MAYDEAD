local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.PersistenceConfig)
local DataService = require(script.Parent.DataService)
local SessionService = require(script.Parent.SessionService)
local InventoryService = require(script.Parent.InventoryService)
local TimeService = require(script.Parent.TimeService)
local BuildingService = require(script.Parent.BuildingService)
local WildlifeService = require(script.Parent.WildlifeService)
local finalObjectiveCompleted = ReplicatedStorage:FindFirstChild("FinalObjectiveCompleted") or Instance.new("RemoteEvent")
finalObjectiveCompleted.Name = "FinalObjectiveCompleted"
finalObjectiveCompleted.Parent = ReplicatedStorage

local WorldService = {
	_world = nil,
	_saving = false,
	_closing = false,
	_lockReleased = false,
	_restoreCompleted = false,
	_saveCompleted = Instance.new("BindableEvent"),
}

local CRASH_MODEL_NAME = "Crash_Avion"

local function applyCrashIntroEffects(introCompleted)
	local crashModel = workspace:FindFirstChild(CRASH_MODEL_NAME)
	if not crashModel then
		warn("[WorldService] Workspace.Crash_Avion not found; crash effects were not changed")
		return
	end
	local enabled = not introCompleted
	local fireCount, smokeCount, particleEmitterCount = 0, 0, 0
	for _, descendant in crashModel:GetDescendants() do
		if descendant:IsA("Fire") then
			fireCount += 1
			descendant.Enabled = enabled
		elseif descendant:IsA("Smoke") then
			smokeCount += 1
			descendant.Enabled = enabled
		elseif descendant:IsA("ParticleEmitter") then
			particleEmitterCount += 1
			descendant.Enabled = enabled
		end
	end
	print(string.format(
		"[WorldService] Crash_Avion effects enabled=%s Fire=%d Smoke=%d ParticleEmitter=%d",
		tostring(enabled), fireCount, smokeCount, particleEmitterCount
	))
end

local function clonePersistentValue(value, seen)
	local valueType = typeof(value)
	if valueType == "nil" or valueType == "string" or valueType == "boolean" then
		return value
	elseif valueType == "number" then
		if value ~= value or value <= -math.huge or value >= math.huge then error("NonFiniteNumber") end
		return value
	elseif valueType ~= "table" then
		error("UnsupportedPersistentType:" .. valueType)
	end
	if seen[value] then error("CyclicPersistentTable") end
	seen[value] = true
	local clone = {}
	for key, child in value do
		local keyType = typeof(key)
		if keyType ~= "string" and keyType ~= "number" then error("UnsupportedPersistentKey") end
		clone[key] = clonePersistentValue(child, seen)
	end
	seen[value] = nil
	return clone
end

local function newWorld(worldId, ownerUserId, ownerSlot, maxPlayers)
	local now = os.time()
	return {
		SchemaVersion = Config.SCHEMA_VERSION, WorldId = worldId, OwnerUserId = ownerUserId,
		OwnerSlot = ownerSlot, DisplayName = "MONDE " .. tostring(ownerSlot), MaxPlayers = maxPlayers,
		AuthorizedMembers = {}, CreatedAt = now, UpdatedAt = now,
		Time = {Age = 10, CycleProgress = 0}, PlayerStates = {},
		WorldState = {CrashIntroCompleted = false, NavalSeaplaneCompleted = false, FinalPlaneSpawned = false, EscapeAge = nil, LongevityAge = 10}, SessionLock = nil,
	}
end

local function memberCount(data)
	local count = 1
	for userId, authorized in data.AuthorizedMembers or {} do
		if authorized == true and tostring(data.OwnerUserId) ~= tostring(userId) then count += 1 end
	end
	return count
end

function WorldService:_migrate(data)
	if typeof(data) ~= "table" or typeof(data.SchemaVersion) ~= "number"
		or data.SchemaVersion > Config.SCHEMA_VERSION or data.SchemaVersion < 1
	then return nil, "UnsupportedSchema" end
	-- SchemaVersion 1 is the first persisted schema. Future migrations are applied
	-- sequentially here before increasing SCHEMA_VERSION; no fictitious migration exists yet.
	if data.SchemaVersion ~= Config.SCHEMA_VERSION then return nil, "UnsupportedSchema" end
	if typeof(data.WorldId) ~= "string" or typeof(data.OwnerUserId) ~= "number"
		or typeof(data.OwnerSlot) ~= "number" or data.OwnerSlot ~= math.floor(data.OwnerSlot)
		or data.OwnerSlot < 1 or data.OwnerSlot > 3
		or typeof(data.MaxPlayers) ~= "number" or data.MaxPlayers ~= math.floor(data.MaxPlayers)
		or data.MaxPlayers < 1 or data.MaxPlayers > 6
	then return nil, "InvalidWorldData" end
	if typeof(data.AuthorizedMembers) ~= "table" or typeof(data.PlayerStates) ~= "table"
		or typeof(data.WorldState) ~= "table" or typeof(data.Time) ~= "table"
	then return nil, "InvalidWorldData" end
	data.AuthorizedMembers = data.AuthorizedMembers or {}
	data.PlayerStates = data.PlayerStates or {}
	data.WorldState = data.WorldState or {}
	-- Saves created before the crash-intro flag represent worlds whose first
	-- session has already happened; do not reignite their permanent wreck.
	if data.WorldState.CrashIntroCompleted == nil then
		data.WorldState.CrashIntroCompleted = true
	elseif typeof(data.WorldState.CrashIntroCompleted) ~= "boolean" then
		return nil, "InvalidWorldData"
	end
	if data.WorldState.NavalSeaplaneCompleted == nil then data.WorldState.NavalSeaplaneCompleted = false end
	if data.WorldState.FinalPlaneSpawned == nil then data.WorldState.FinalPlaneSpawned = false end
	if data.WorldState.LongevityAge == nil then data.WorldState.LongevityAge = data.Time.Age or 10 end
	if typeof(data.WorldState.NavalSeaplaneCompleted) ~= "boolean" or typeof(data.WorldState.FinalPlaneSpawned) ~= "boolean"
		or typeof(data.WorldState.LongevityAge) ~= "number" then return nil, "InvalidWorldData" end
	if typeof(data.DisplayName) ~= "string" or data.DisplayName == "" then
		data.DisplayName = "MONDE " .. tostring(data.OwnerSlot)
	end
	return data
end

function WorldService:GetOwnerSlots(userId)
	local ok, index = DataService:ListOwnerSlots(userId)
	if not ok then return false, "LoadFailed" end
	local slots = {}
	for slot = 1, 3 do
		local entry = index.Slots and index.Slots[tostring(slot)]
		if entry and entry.Status == "Creating" then
			local loaded, pendingWorld = DataService:LoadWorld(entry.WorldId)
			if not loaded then return false, "LoadFailed" end
			if pendingWorld then
				if not DataService:FinalizeOwnerSlot(userId, slot, entry.WorldId) then return false, "LoadFailed" end
				entry.Status = "Ready"
			elseif typeof(entry.ReservedAt) == "number"
				and os.time() - entry.ReservedAt >= Config.CREATE_RESERVATION_TIMEOUT
			then
				DataService:RollbackOwnerSlot(userId, slot, entry.WorldId)
				entry = nil
			else
				return false, "WorldCreationInProgress"
			end
		end
		if entry and entry.Status == "Ready" then
			local loaded, data = DataService:LoadWorld(entry.WorldId)
			if not loaded or not data then return false, "LoadFailed" end
			if data.Deleted == true then
				DataService:RemoveOwnerSlotForDeletion(userId, slot, entry.WorldId)
				continue
			end
				slots[slot] = {
				WorldId = data.WorldId,
				DisplayName = typeof(data.DisplayName) == "string" and data.DisplayName or ("MONDE " .. tostring(slot)),
				Age = data.Time and data.Time.Age or 10,
					MaxPlayers = data.MaxPlayers,
					MemberCount = memberCount(data),
			}
		end
	end
	return true, slots
end

function WorldService:GetJoinedWorlds(userId)
	local indexed, memberIndex = DataService:ListMemberIndex(userId)
	if not indexed then return false, "LoadFailed" end
	local joined, invites, joinedById = {}, {}, {}
	for worldId, entry in memberIndex.JoinedWorlds do
		local loaded, data = DataService:LoadWorld(worldId)
		if loaded and data and data.Deleted ~= true
			and data.OwnerUserId ~= userId and (data.AuthorizedMembers or {})[tostring(userId)] == true
		then
			table.insert(joined, {WorldId = worldId, DisplayName = data.DisplayName, OwnerUserId = data.OwnerUserId,
				MaxPlayers = data.MaxPlayers, MemberCount = memberCount(data), Age = data.Time and data.Time.Age or 10,
				JoinedAt = entry.JoinedAt or entry.ReservedAt or 0,
				Active = data.SessionLock ~= nil and (data.SessionLock.ExpiresAt or 0) > os.time()})
			joinedById[worldId] = true
			if entry.Status ~= "Ready" then DataService:RepairMemberIndexWorld(userId, worldId, data) end
		elseif loaded then
			DataService:RepairMemberIndexWorld(userId, worldId, nil)
		end
	end
	for worldId, invite in memberIndex.PendingInvites do
		local loaded, data = DataService:LoadWorld(worldId)
		if loaded and data and data.Deleted ~= true and data.OwnerUserId ~= userId
			and (data.AuthorizedMembers or {})[tostring(userId)] == true
		then
			DataService:RepairMemberIndexWorld(userId, worldId, data)
			if not joinedById[worldId] then
				table.insert(joined, {WorldId = worldId, DisplayName = data.DisplayName, OwnerUserId = data.OwnerUserId,
					MaxPlayers = data.MaxPlayers, MemberCount = memberCount(data), Age = data.Time and data.Time.Age or 10,
					JoinedAt = invite.CreatedAt or 0,
					Active = data.SessionLock ~= nil and (data.SessionLock.ExpiresAt or 0) > os.time()})
				joinedById[worldId] = true
			end
		elseif loaded and data and data.Deleted ~= true and data.OwnerUserId ~= userId then
			table.insert(invites, {WorldId = worldId, DisplayName = data.DisplayName, OwnerUserId = data.OwnerUserId,
				MemberCount = memberCount(data), MaxPlayers = data.MaxPlayers, CreatedAt = invite.CreatedAt or 0})
		end
	end
	table.sort(joined, function(a, b) return a.JoinedAt < b.JoinedAt end)
	table.sort(invites, function(a, b) return a.CreatedAt < b.CreatedAt end)
	return true, {JoinedWorlds = joined, PendingInvites = invites}
end

function WorldService:GetWorldAccessInfo(userId, worldId)
	local loaded, data = DataService:LoadWorld(worldId)
	if not loaded or not data or data.Deleted == true then return false, "WorldNotFound" end
	if userId ~= data.OwnerUserId and not (data.AuthorizedMembers or {})[tostring(userId)] then
		return false, "NotAuthorized"
	end
	return true, data
end

function WorldService:PrepareReservedRoute(worldId, proposedAccessCode)
	return DataService:PrepareReservedWorldRoute(worldId, proposedAccessCode)
end

function WorldService:InviteMember(ownerUserId, worldId, targetUserId, maxMembers, maxPending)
	return DataService:CreateWorldInvite(worldId, ownerUserId, targetUserId, maxMembers, maxPending)
end

function WorldService:AcceptInvite(userId, worldId, maxJoined, maxMembers)
	return DataService:AcceptWorldInvite(userId, worldId, maxJoined, maxMembers)
end

function WorldService:DeclineInvite(userId, worldId)
	return DataService:DeclineWorldInvite(userId, worldId)
end

function WorldService:RemoveMember(actorUserId, worldId, memberUserId, memberLeaving)
	return DataService:RemoveAuthorizedMember(worldId, actorUserId, memberUserId, memberLeaving)
end

function WorldService:GetMembers(requesterUserId, worldId)
	local authorized, dataOrError = self:GetWorldAccessInfo(requesterUserId, worldId)
	if not authorized then return false, dataOrError end
	local data = dataOrError
	local members = {{UserId = data.OwnerUserId, Role = "Owner"}}
	for userId, isMember in data.AuthorizedMembers do
		local numericUserId = tonumber(userId)
		if isMember == true and numericUserId and numericUserId ~= data.OwnerUserId then
			table.insert(members, {UserId = numericUserId, Role = "Member"})
		end
	end
	table.sort(members, function(a, b)
		if a.Role ~= b.Role then return a.Role == "Owner" end
		return a.UserId < b.UserId
	end)
	return true, {WorldId = worldId, OwnerUserId = data.OwnerUserId, MemberCount = #members,
		MaxMembers = 6, Members = members}
end

function WorldService:DeleteOwnerWorld(ownerUserId, slot, worldId)
	if self._world or self._saving or self._closing or SessionService:GetActive() then return false, "WorldInUse" end
	local listed, slotsOrError = self:GetOwnerSlots(ownerUserId)
	if not listed then return false, slotsOrError end
	local entry = slotsOrError[slot]
	if not entry or entry.WorldId ~= worldId then return false, "NotAuthorized" end

	local deletionToken = HttpService:GenerateGUID(false)
	local reserved, reserveError = DataService:ReserveWorldDeletion(worldId, ownerUserId, deletionToken)
	if not reserved then return false, reserveError end
	if not DataService:RemoveOwnerSlotForDeletion(ownerUserId, slot, worldId) then
		DataService:CancelWorldDeletion(worldId, deletionToken)
		return false, "DeleteFailed"
	end
	if not DataService:CommitWorldDeletion(worldId, ownerUserId, slot, deletionToken) then
		local restored = DataService:RestoreOwnerSlotAfterDeleteFailure(ownerUserId, slot, worldId)
		local cancelled = DataService:CancelWorldDeletion(worldId, deletionToken)
		if not restored or not cancelled then
			warn("[WorldService] Delete rollback incomplete for world " .. worldId)
			return false, "DeleteRecoveryRequired"
		end
		return false, "DeleteFailed"
	end
	return true
end

function WorldService:RenameOwnerWorld(ownerUserId, slot, worldId, displayName)
	if self._world then return false, "SessionAlreadyActive" end
	local listed, slotsOrError = self:GetOwnerSlots(ownerUserId)
	if not listed then return false, slotsOrError end
	local entry = slotsOrError[slot]
	if not entry or entry.WorldId ~= worldId then return false, "NotAuthorized" end
	local renamed, renameError = DataService:RenameWorld(worldId, ownerUserId, displayName)
	return renamed, renameError
end

function WorldService:CreateRecord(owner, slot, maxPlayers)
	if self._closing then return false, "SessionAlreadyActive" end
	local ownedBefore = 0
	local beforeListed, beforeIndex = DataService:ListOwnerSlots(owner.UserId)
	if beforeListed then for _, entry in beforeIndex.Slots or {} do if entry then ownedBefore += 1 end end end
	local reserved, worldId = DataService:ReserveOwnerSlot(owner.UserId, slot)
	if not reserved then return false, "SlotUnavailable" end
	local data = newWorld(worldId, owner.UserId, slot, maxPlayers)
	if not DataService:CreateWorld(data) then
		DataService:RollbackOwnerSlot(owner.UserId, slot, worldId)
		return false, "SaveFailed"
	end
	if not DataService:FinalizeOwnerSlot(owner.UserId, slot, worldId) then return false, "IndexFinalizeFailed" end
	local ownedAfter = 0
	local listed, ownerIndex = DataService:ListOwnerSlots(owner.UserId)
	if listed then for _, entry in ownerIndex.Slots or {} do if entry then ownedAfter += 1 end end end
	local memberListed, memberIndex = DataService:ListMemberIndex(owner.UserId)
	local joinedCount, pendingCount = 0, 0
	if memberListed then
		for _ in memberIndex.JoinedWorlds do joinedCount += 1 end
		for _ in memberIndex.PendingInvites do pendingCount += 1 end
	end
	print(string.format("[MAYDEAD][WORLD_INDEX] Action=CREATE_WORLD UserId=%d OwnedBefore=%d OwnedAfter=%d Joined=%d PendingInvites=%d", owner.UserId, ownedBefore, ownedAfter, joinedCount, pendingCount))
	return true, data
end

function WorldService:Create(owner, slot, maxPlayers)
	if self._world then return false, "SessionAlreadyActive" end
	local created, dataOrError = self:CreateRecord(owner, slot, maxPlayers)
	if not created then return false, dataOrError end
	return self:Load(owner, dataOrError.WorldId)
end

function WorldService:Load(player, worldId)
	if self._world or self._closing then return false, "SessionAlreadyActive" end
	self._restoreCompleted = false
	local loaded, raw = DataService:LoadWorld(worldId)
	if not loaded or not raw then return false, "LoadFailed" end
	local data, validationError = self:_migrate(raw)
	if not data then return false, validationError end
	if player.UserId ~= data.OwnerUserId and not data.AuthorizedMembers[tostring(player.UserId)] then return false, "NotAuthorized" end
	local acquired, tokenOrError = SessionService:Acquire(worldId)
	if not acquired then return false, tokenOrError end
	self._world = data
	self._lockReleased = false
	self._world.SessionLock = nil
	local worldState = data.WorldState
	local restoreCallSucceeded, structuresRestored, structuresError = pcall(function()
		return BuildingService:RestorePersistentSnapshot(worldState.Structures, worldState.StructuresVersion)
	end)
	if not restoreCallSucceeded or not structuresRestored then
		local failureReason = restoreCallSucceeded and structuresError or structuresRestored
		BuildingService:ClearWorldStructures()
		SessionService:Clear(tokenOrError)
		self._world = nil
		warn("[WorldService] Structure restoration failed: " .. tostring(failureReason))
		return false, "InvalidWorldStructures"
	end
	if not TimeService:RestorePersistentState(data.Time) then
		BuildingService:ClearWorldStructures()
		SessionService:Clear(tokenOrError)
		self._world = nil
		return false, "InvalidWorldData"
	end
	BuildingService:RestoreFinalWorldState(worldState)
	if not WildlifeService:RestorePersistentState(worldState.CheetahTaming) then
		BuildingService:ClearWorldStructures()
		SessionService:Clear(tokenOrError)
		self._world = nil
		return false, "InvalidCheetahTamingState"
	end
	applyCrashIntroEffects(worldState.CrashIntroCompleted)
	self._restoreCompleted = true
	return true, data
end

function WorldService:RestorePlayer(player)
	if not self._world then return false end
	local state = self._world.PlayerStates[tostring(player.UserId)]
	if state and state.Inventory and not InventoryService:RestoreInventory(player, state.Inventory) then return false end
	return true
end

function WorldService:CapturePlayer(player)
	if not self._world then return end
	local inventory = InventoryService:ExportInventory(player)
	if inventory then self._world.PlayerStates[tostring(player.UserId)] = {Inventory = inventory} end
end

function WorldService:Save(releaseLock, reason)
	while self._saving do
		self._saveCompleted.Event:Wait()
	end
	if not self._world then return false, "NoWorld" end
	if not self._restoreCompleted then
		warn("[MAYDEAD][WORLD_SAVE_GUARD] Skipped Reason=RestoreNotCompleted")
		return false, "RestoreNotCompleted"
	end
	local active = SessionService:GetActive()
	if not active or not active.Valid then
		if releaseLock and self._lockReleased then return true, nil end
		return false, "LockLost"
	end
	self._saving = true
	local saveReason = reason or "Unspecified"
	print("[WorldPersistence] save reason = " .. saveReason)
	local callSucceeded, saved, saveError = pcall(function()
		for player in pairs(self._world._Members or {}) do self:CapturePlayer(player) end
		self._world.Time = TimeService:GetPersistentState()
		self._world.WorldState.LongevityAge = math.max(self._world.WorldState.LongevityAge or 10, self._world.Time.Age)
		local structures, structuresError = BuildingService:GetPersistentSnapshot()
		if not structures then
			return false, "StructureSnapshotFailed:" .. tostring(structuresError)
		end
		self._world.WorldState.StructuresVersion = 2
		self._world.WorldState.Structures = structures
		self._world.WorldState.CheetahTaming = WildlifeService:GetPersistentState()
		local completeCrashIntroOnSuccess = self._world.WorldState.CrashIntroCompleted == false
		local snapshot = {}
		local seen = {[self._world] = true}
		for key, value in self._world do
			if key ~= "_Members" then
				snapshot[key] = clonePersistentValue(value, seen)
			end
		end
		if completeCrashIntroOnSuccess then
			snapshot.WorldState.CrashIntroCompleted = true
		end
		local dataSaved = DataService:SaveWorld(self._world.WorldId, active.Token, snapshot, releaseLock)
		return dataSaved, dataSaved and nil or "SaveFailed"
	end)
	self._saving = false
	self._saveCompleted:Fire()
	if not callSucceeded then
		warn("[WorldService] World save crashed; previous DataStore snapshot retained: " .. tostring(saved))
		return false, "SaveFailed"
	end
	if saved and saveError == nil and self._world.WorldState.CrashIntroCompleted == false then
		self._world.WorldState.CrashIntroCompleted = true
	end
	if saved and releaseLock then
		self._lockReleased = true
		SessionService:Clear(active.Token)
	end
	if not saved then warn("[WorldService] World save failed or fenced: " .. tostring(saveError)) end
	if saved then return true, nil end
	return false, saveError or "SaveFailed"
end

function WorldService:SetMembers(members) if self._world then self._world._Members = members end end
function WorldService:GetActiveWorld() return self._world end
function WorldService:IsRuntimeMember(player)
	return self._world ~= nil and self._world._Members ~= nil and self._world._Members[player] == true
end

function WorldService:IsNavalSeaplaneCompleted()
	return self._world ~= nil and self._world.WorldState.NavalSeaplaneCompleted == true
end

function WorldService:IsFinalPlaneSpawned()
	return self._world ~= nil and self._world.WorldState.FinalPlaneSpawned == true and workspace:FindFirstChild("FinalNavalSeaplane") ~= nil
end

function WorldService:MarkFinalPlaneSpawned(pivot)
	if self._world then
		self._world.WorldState.FinalPlaneSpawned = true
		if typeof(pivot) == "CFrame" then self._world.WorldState.FinalPlanePivot = {pivot:GetComponents()} end
	end
end

function WorldService:CompleteNavalSeaplane()
	if not self._world or self._world.WorldState.NavalSeaplaneCompleted == true then return false end
	local age = TimeService:GetAge()
	self._world.WorldState.NavalSeaplaneCompleted = true
	self._world.WorldState.FinalPlaneSpawned = true
	self._world.WorldState.EscapeAge = self._world.WorldState.EscapeAge and math.min(self._world.WorldState.EscapeAge, age) or age
	self._world.WorldState.LongevityAge = math.max(self._world.WorldState.LongevityAge or age, age)
	finalObjectiveCompleted:FireAllClients({Age = age, EscapeAge = self._world.WorldState.EscapeAge, LongevityAge = self._world.WorldState.LongevityAge})
	return true
end
function WorldService:Close(reason)
	if not self._world then return true end
	local saved = self:Save(true, reason or "Close")
	if saved then
		self._world = nil
		self._restoreCompleted = false
		self._lockReleased = false
		BuildingService:ClearWorldStructures()
	end
	return saved
end

function WorldService:DiscardClosedWorld()
	if SessionService:GetActive() then return false end
	self._world = nil
	self._restoreCompleted = false
	self._lockReleased = false
	BuildingService:ClearWorldStructures()
	return true
end

function WorldService:Start()
	Players.PlayerRemoving:Connect(function(player) self:CapturePlayer(player) end)
	task.spawn(function()
		while not self._closing do
			task.wait(Config.AUTOSAVE_INTERVAL)
			if self._world then self:Save(false, "Autosave") end
		end
	end)
	game:BindToClose(function()
		self._closing = true
		if self._world then self:Save(true, "BindToClose") end
	end)
end

return WorldService
