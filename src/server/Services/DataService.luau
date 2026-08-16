local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config.PersistenceConfig)
local DataService = {}

local indexStore = DataStoreService:GetDataStore("MAYDEAD_WorldIndex_" .. Config.DATASTORE_NAMESPACE)
local worldStore = DataStoreService:GetDataStore("MAYDEAD_WorldData_" .. Config.DATASTORE_NAMESPACE)

local function retry(operation)
	local lastError
	for attempt = 1, Config.MAX_RETRIES do
		local ok, result = pcall(operation)
		if ok then return true, result end
		lastError = result
		if attempt < Config.MAX_RETRIES then task.wait(Config.RETRY_DELAY * attempt) end
	end
	return false, lastError
end

local function indexKey(userId) return "owner:" .. tostring(userId) end
local function memberIndexKey(userId) return "member:" .. tostring(userId) end
local function worldKey(worldId) return "world:" .. worldId end

local function normalizeMemberIndex(current)
	current = current or {SchemaVersion = 1}
	current.SchemaVersion = 1
	current.JoinedWorlds = typeof(current.JoinedWorlds) == "table" and current.JoinedWorlds or {}
	current.PendingInvites = typeof(current.PendingInvites) == "table" and current.PendingInvites or {}
	return current
end

local function countAuthorizedMembers(world)
	local count = 1
	for userId, authorized in world.AuthorizedMembers or {} do
		if authorized == true and tostring(world.OwnerUserId) ~= tostring(userId) then count += 1 end
	end
	return count
end

function DataService:ListOwnerSlots(userId)
	return retry(function() return indexStore:GetAsync(indexKey(userId)) or {SchemaVersion = 1, Slots = {}} end)
end

function DataService:ReserveOwnerSlot(userId, slot)
	local worldId = HttpService:GenerateGUID(false)
	local reserved = false
	local ok, result = retry(function()
		return indexStore:UpdateAsync(indexKey(userId), function(current)
			reserved = false
			current = current or {SchemaVersion = 1, Slots = {}}
			current.Slots = current.Slots or {}
			if current.Slots[tostring(slot)] ~= nil then return nil end
			current.Slots[tostring(slot)] = {WorldId = worldId, Status = "Creating", ReservedAt = os.time()}
			reserved = true
			return current
		end)
	end)
	return ok and reserved, worldId, ok and result or nil
end

function DataService:FinalizeOwnerSlot(userId, slot, worldId)
	local finalized = false
	local ok, result = retry(function()
		return indexStore:UpdateAsync(indexKey(userId), function(current)
			finalized = false
			local entry = current and current.Slots and current.Slots[tostring(slot)]
			if not entry or entry.WorldId ~= worldId then return nil end
			entry.Status = "Ready"
			finalized = true
			return current
		end)
	end)
	return ok and finalized, result
end

function DataService:RollbackOwnerSlot(userId, slot, worldId)
	return retry(function()
		return indexStore:UpdateAsync(indexKey(userId), function(current)
			local entry = current and current.Slots and current.Slots[tostring(slot)]
			if entry and entry.WorldId == worldId and entry.Status == "Creating" then
				current.Slots[tostring(slot)] = nil
			end
			return current
		end)
	end)
end

function DataService:CreateWorld(data)
	local created = false
	local ok, result = retry(function()
		return worldStore:UpdateAsync(worldKey(data.WorldId), function(current)
			created = false
			if current ~= nil then return nil end
			created = true
			return data
		end)
	end)
	return ok and created, result
end

function DataService:LoadWorld(worldId)
	return retry(function() return worldStore:GetAsync(worldKey(worldId)) end)
end

function DataService:PrepareReservedWorldRoute(worldId, proposedAccessCode)
	local selectedCode
	local ok = retry(function()
		return worldStore:UpdateAsync(worldKey(worldId), function(world)
			if not world or world.Deleted == true then return nil end
			local now = os.time()
			local lock = world.SessionLock
			if lock and (lock.ExpiresAt or 0) > now then
				selectedCode = world.Routing and world.Routing.ReservedServerAccessCode or nil
				return nil
			end
			local routing = world.Routing
			if routing and typeof(routing.ReservedServerAccessCode) == "string"
				and (routing.ExpiresAt or 0) > now
			then
				selectedCode = routing.ReservedServerAccessCode
				return world
			end
			selectedCode = proposedAccessCode
			world.Routing = {ReservedServerAccessCode = proposedAccessCode, ExpiresAt = now + 300}
			return world
		end)
	end)
	return ok and typeof(selectedCode) == "string", selectedCode
end

function DataService:ListMemberIndex(userId)
	return retry(function() return normalizeMemberIndex(indexStore:GetAsync(memberIndexKey(userId))) end)
end

function DataService:RepairMemberIndexWorld(userId, worldId, worldData)
	return retry(function()
		return indexStore:UpdateAsync(memberIndexKey(userId), function(current)
			current = normalizeMemberIndex(current)
			if worldData then
				local existing = current.JoinedWorlds[worldId] or {}
				existing.WorldId = worldId; existing.Status = "Ready"
				existing.OwnerUserId = worldData.OwnerUserId; existing.DisplayName = worldData.DisplayName
				existing.JoinedAt = existing.JoinedAt or existing.ReservedAt or os.time()
				current.JoinedWorlds[worldId] = existing
				current.PendingInvites[worldId] = nil
			else
				current.JoinedWorlds[worldId] = nil
			end
			return current
		end)
	end)
end

function DataService:CreateWorldInvite(worldId, ownerUserId, targetUserId, maxMembers, maxPending)
	local validWorld, inviteData
	local loaded, world = self:LoadWorld(worldId)
	if not loaded or not world then return false, "WorldNotFound" end
	if world.Deleted == true or world.OwnerUserId ~= ownerUserId then return false, "NotOwner" end
	if targetUserId == ownerUserId then return false, "AlreadyMember" end
	if (world.AuthorizedMembers or {})[tostring(targetUserId)] == true then
		local repaired = self:RepairMemberIndexWorld(targetUserId, worldId, world)
		return repaired, repaired and "Repaired" or "IndexRepairRequired"
	end
	if countAuthorizedMembers(world) >= maxMembers then return false, "MemberLimitReached" end
	inviteData = {WorldId = worldId, OwnerUserId = ownerUserId, DisplayName = world.DisplayName,
		CreatedAt = os.time(), Status = "Pending"}
	local resultCode = "SaveFailed"
	local ok = retry(function()
		return indexStore:UpdateAsync(memberIndexKey(targetUserId), function(current)
			current = normalizeMemberIndex(current)
			if current.JoinedWorlds[worldId] then resultCode = "AlreadyMember"; return nil end
			local pendingCount = 0
			for _ in current.PendingInvites do pendingCount += 1 end
			if not current.PendingInvites[worldId] and pendingCount >= maxPending then
				resultCode = "InviteLimitReached"; return nil
			end
			current.PendingInvites[worldId] = inviteData
			resultCode = "Invited"
			return current
		end)
	end)
	validWorld = ok and resultCode == "Invited"
	if validWorld then
		print(string.format("[MAYDEAD][WORLD_INVITE] Action=CREATE From=%d To=%d WorldId=%s PendingOnly=true", ownerUserId, targetUserId, worldId))
	end
	return validWorld, resultCode
end

function DataService:DeclineWorldInvite(userId, worldId)
	local declined = false
	local ok = retry(function()
		return indexStore:UpdateAsync(memberIndexKey(userId), function(current)
			current = normalizeMemberIndex(current)
			if not current.PendingInvites[worldId] then return nil end
			current.PendingInvites[worldId] = nil
			declined = true
			return current
		end)
	end)
	if ok and declined then print(string.format("[MAYDEAD][WORLD_INVITE] Action=DECLINE UserId=%d WorldId=%s", userId, worldId)) end
	return ok and declined
end

function DataService:AcceptWorldInvite(userId, worldId, maxJoined, maxMembers)
	local indexed, memberIndex = self:ListMemberIndex(userId)
	if not indexed then return false, "SaveFailed" end
	local invite = memberIndex.PendingInvites[worldId]
	if not invite then return false, "InviteNotFound" end
	local joinedBefore = 0
	for _ in memberIndex.JoinedWorlds do joinedBefore += 1 end
	if memberIndex.JoinedWorlds[worldId] == nil and joinedBefore >= maxJoined then return false, "JoinedWorldLimitReached" end

	local membershipAdded, membershipCode = false, "SaveFailed"
	local worldUpdated = retry(function()
		return worldStore:UpdateAsync(worldKey(worldId), function(world)
			membershipAdded = false
			if not world or world.Deleted == true then membershipCode = "WorldNotFound"; return nil end
			world.AuthorizedMembers = typeof(world.AuthorizedMembers) == "table" and world.AuthorizedMembers or {}
			if world.OwnerUserId == userId or world.AuthorizedMembers[tostring(userId)] == true then
				membershipAdded = true; membershipCode = "AlreadyMember"; return world
			end
			if countAuthorizedMembers(world) >= maxMembers then membershipCode = "MemberLimitReached"; return nil end
			world.AuthorizedMembers[tostring(userId)] = true
			world.UpdatedAt = os.time()
			membershipAdded = true; membershipCode = "Accepted"
			return world
		end)
	end)
	if not worldUpdated or not membershipAdded then return false, membershipCode end

	local finalized, joinedAfter = false, joinedBefore
	local indexUpdated = retry(function()
		return indexStore:UpdateAsync(memberIndexKey(userId), function(current)
			current = normalizeMemberIndex(current)
			if not current.PendingInvites[worldId] and not current.JoinedWorlds[worldId] then return nil end
			local count = 0
			for _ in current.JoinedWorlds do count += 1 end
			local alreadyIndexed = current.JoinedWorlds[worldId] ~= nil
			if not alreadyIndexed and count >= maxJoined then return nil end
			local entry = current.JoinedWorlds[worldId] or {WorldId = worldId}
			entry.Status = "Ready"; entry.JoinedAt = entry.JoinedAt or os.time()
			entry.OwnerUserId = invite.OwnerUserId; entry.DisplayName = invite.DisplayName
			current.JoinedWorlds[worldId] = entry
			current.PendingInvites[worldId] = nil
			joinedAfter = count + (alreadyIndexed and 0 or 1)
			finalized = true
			return current
		end)
	end)
	if not indexUpdated or not finalized then warn("[Membership] World accepted; member index will be repaired lazily for " .. tostring(userId)) end
	print(string.format("[MAYDEAD][WORLD_INVITE] Action=ACCEPT UserId=%d WorldId=%s JoinedBefore=%d JoinedAfter=%d AuthorizedMemberAdded=true", userId, worldId, joinedBefore, finalized and joinedAfter or joinedBefore))
	return true, finalized and nil or "IndexRepairRequired"
end

function DataService:RemoveAuthorizedMember(worldId, actorUserId, memberUserId, memberLeaving)
	local removed, resultCode = false, "SaveFailed"
	local ok = retry(function()
		return worldStore:UpdateAsync(worldKey(worldId), function(world)
			removed = false
			if not world or world.Deleted == true then resultCode = "WorldNotFound"; return nil end
			if memberUserId == world.OwnerUserId then resultCode = "CannotRemoveOwner"; return nil end
			if memberLeaving then
				if actorUserId ~= memberUserId then resultCode = "NotAuthorized"; return nil end
			elseif actorUserId ~= world.OwnerUserId then resultCode = "NotOwner"; return nil end
			if not (world.AuthorizedMembers or {})[tostring(memberUserId)] then resultCode = "NotMember"; return nil end
			world.AuthorizedMembers[tostring(memberUserId)] = nil
			world.UpdatedAt = os.time(); removed = true; resultCode = "Removed"
			return world
		end)
	end)
	if not ok or not removed then return false, resultCode end
	local indexUpdated = retry(function()
		return indexStore:UpdateAsync(memberIndexKey(memberUserId), function(current)
			current = normalizeMemberIndex(current)
			current.JoinedWorlds[worldId] = nil; current.PendingInvites[worldId] = nil
			return current
		end)
	end)
	return true, indexUpdated and nil or "IndexRepairRequired"
end

function DataService:ReserveWorldDeletion(worldId, ownerUserId, deletionToken)
	local resultCode = "DeleteFailed"
	local ok = retry(function()
		return worldStore:UpdateAsync(worldKey(worldId), function(current)
			resultCode = "DeleteFailed"
			if not current then resultCode = "WorldNotFound"; return nil end
			if current.OwnerUserId ~= ownerUserId then resultCode = "NotAuthorized"; return nil end
			if current.Deleted == true then resultCode = "AlreadyDeleted"; return nil end
			local lock = current.SessionLock
			if lock and (lock.ExpiresAt or 0) > os.time() then resultCode = "WorldInUse"; return nil end
			if current.Deletion and current.Deletion.Token ~= deletionToken
				and (current.Deletion.ExpiresAt or 0) > os.time()
			then resultCode = "DeleteInProgress"; return nil end
			current.Deletion = {Token = deletionToken, RequestedAt = os.time(), ExpiresAt = os.time() + 120}
			resultCode = "Reserved"
			return current
		end)
	end)
	return ok and resultCode == "Reserved", resultCode
end

function DataService:RemoveOwnerSlotForDeletion(userId, slot, worldId)
	local removed = false
	local ok = retry(function()
		return indexStore:UpdateAsync(indexKey(userId), function(current)
			removed = false
			local entry = current and current.Slots and current.Slots[tostring(slot)]
			if not entry or entry.WorldId ~= worldId then return nil end
			current.Slots[tostring(slot)] = nil
			removed = true
			return current
		end)
	end)
	return ok and removed
end

function DataService:RestoreOwnerSlotAfterDeleteFailure(userId, slot, worldId)
	local restored = false
	local ok = retry(function()
		return indexStore:UpdateAsync(indexKey(userId), function(current)
			current = current or {SchemaVersion = 1, Slots = {}}
			current.Slots = current.Slots or {}
			local entry = current.Slots[tostring(slot)]
			if entry and entry.WorldId ~= worldId then return nil end
			current.Slots[tostring(slot)] = {WorldId = worldId, Status = "Ready"}
			restored = true
			return current
		end)
	end)
	return ok and restored
end

function DataService:CancelWorldDeletion(worldId, deletionToken)
	local cancelled = false
	local ok = retry(function()
		return worldStore:UpdateAsync(worldKey(worldId), function(current)
			cancelled = false
			if not current or not current.Deletion or current.Deletion.Token ~= deletionToken then return nil end
			current.Deletion = nil
			cancelled = true
			return current
		end)
	end)
	return ok and cancelled
end

function DataService:CommitWorldDeletion(worldId, ownerUserId, ownerSlot, deletionToken)
	local committed = false
	local ok = retry(function()
		return worldStore:UpdateAsync(worldKey(worldId), function(current)
			committed = false
			if not current or current.OwnerUserId ~= ownerUserId
				or not current.Deletion or current.Deletion.Token ~= deletionToken
			then return nil end
			committed = true
			return {
				SchemaVersion = current.SchemaVersion,
				WorldId = worldId,
				OwnerUserId = ownerUserId,
				OwnerSlot = ownerSlot,
				Deleted = true,
				DeletedAt = os.time(),
				DeletionToken = deletionToken,
			}
		end)
	end)
	return ok and committed
end

function DataService:RenameWorld(worldId, ownerUserId, displayName)
	local renamed = false
	local resultCode = "SaveFailed"
	local ok, result = retry(function()
		return worldStore:UpdateAsync(worldKey(worldId), function(current)
			renamed = false
			resultCode = "SaveFailed"
			if not current then resultCode = "WorldNotFound"; return nil end
			if current.OwnerUserId ~= ownerUserId then resultCode = "NotOwner"; return nil end
			if current.Deleted == true then resultCode = "WorldDeleted"; return nil end
			if current.Deletion ~= nil then resultCode = "WorldBusy"; return nil end
			local lock = current.SessionLock
			if lock and (lock.ExpiresAt or 0) > os.time() then resultCode = "WorldBusy"; return nil end
			current.DisplayName = displayName
			current.UpdatedAt = os.time()
			renamed = true
			resultCode = "Renamed"
			return current
		end)
	end)
	if not ok then
		warn("[RenameWorld] DataStore UpdateAsync failed: " .. tostring(result))
		return false, "SaveFailed"
	end
	if renamed then return true, nil end
	return false, resultCode
end

function DataService:AcquireLock(worldId, token)
	local acquired = false
	local now = os.time()
	local ok, result = retry(function()
		return worldStore:UpdateAsync(worldKey(worldId), function(current)
			acquired = false
			if not current then return nil end
			if current.Deleted == true then return nil end
			if current.Deletion and (current.Deletion.ExpiresAt or 0) > now then return nil end
			if current.Deletion then current.Deletion = nil end
			local lock = current.SessionLock
			if lock and lock.Token ~= token and (lock.ExpiresAt or 0) > now then return nil end
			current.SessionLock = {Token = token, PlaceId = game.PlaceId, JobId = game.JobId, ExpiresAt = now + Config.LOCK_LEASE_SECONDS}
			acquired = true
			return current
		end)
	end)
	return ok and acquired, result
end

function DataService:RenewLock(worldId, token)
	local renewed = false
	local ok = retry(function()
		return worldStore:UpdateAsync(worldKey(worldId), function(current)
			renewed = false
			if not current or not current.SessionLock or current.SessionLock.Token ~= token then return nil end
			current.SessionLock.ExpiresAt = os.time() + Config.LOCK_LEASE_SECONDS
			renewed = true
			return current
		end)
	end)
	if not ok then return false, "Unavailable" end
	if not renewed then return false, "LockLost" end
	return true, nil
end

function DataService:SaveWorld(worldId, token, snapshot, releaseLock)
	local saved = false
	local ok, result = retry(function()
		return worldStore:UpdateAsync(worldKey(worldId), function(current)
			saved = false
			if not current or not current.SessionLock or current.SessionLock.Token ~= token then return nil end
			if releaseLock then
				snapshot.SessionLock = nil
			else
				snapshot.SessionLock = current.SessionLock
			end
			-- Membership may change through a different server while this world is active.
			-- The DataStore world record remains authoritative and must not be overwritten
			-- by the active server's older in-memory snapshot.
			snapshot.AuthorizedMembers = current.AuthorizedMembers or {}
			snapshot.UpdatedAt = os.time()
			saved = true
			return snapshot
		end)
	end)
	return ok and saved, result
end

return DataService
