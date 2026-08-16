local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("WorldSessionConfig"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local WorldService = require(script.Parent:WaitForChild("WorldService"))

local WorldSessionService = {}
WorldSessionService.__index = WorldSessionService

function WorldSessionService.new()
	local self = setmetatable({}, WorldSessionService)
	self._session = nil
	self._lastRequests = {}
	self._getStateCache = {}
	self._getStateInFlight = {}
	self._getStateVersions = {}
	self._lastRenames = {}
	self._returning = {}
	self._deleting = {}
	self._lastDeletes = {}
	self._request = Instance.new("RemoteFunction")
	self._request.Name = "WorldSessionRequest"
	self._request.Parent = ReplicatedStorage
	return self
end

function WorldSessionService:_publicState()
	local session = self._session
	return {
		Active = session ~= nil,
		WorldSlot = session and session.WorldSlot or nil,
		MaxPlayers = session and session.MaxPlayers or nil,
		PlayerCount = session and session.PlayerCount or 0,
		Persistent = session ~= nil,
		WorldId = session and session.WorldId or nil,
		DisplayName = session and session.DisplayName or nil,
	}
end

function WorldSessionService:_publicStateFor(player)
	local session = self._session
	if not session or not session.Members[player] then
		return {Active = false, PlayerCount = 0, Persistent = false}
	end
	return self:_publicState()
end

local function trim(value)
	return value:match("^%s*(.-)%s*$")
end

function WorldSessionService:_filterWorldName(player, value)
	if typeof(value) ~= "string" then return nil, "InvalidWorldName" end
	local cleaned = trim(value)
	local length = utf8.len(cleaned)
	if not length or length < Config.WORLD_NAME_MIN_LENGTH or length > Config.WORLD_NAME_MAX_LENGTH then
		return nil, "InvalidWorldName"
	end
	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(cleaned, player.UserId, Enum.TextFilterContext.PublicChat)
		return result:GetNonChatStringForBroadcastAsync()
	end)
	if not ok or typeof(filtered) ~= "string" or trim(filtered) == "" then return nil, "FilterFailed" end
	return filtered
end

function WorldSessionService:_setMenuState(player, inMenu)
	player:SetAttribute("InMainMenu", inMenu)
	player:SetAttribute("SessionStarted", not inMenu)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = inMenu
	elseif character then
		task.spawn(function()
			local delayedRoot = character:WaitForChild("HumanoidRootPart", 5)
			if delayedRoot and player.Character == character then
				delayedRoot.Anchored = player:GetAttribute("SessionStarted") ~= true
			end
		end)
	end
end

function WorldSessionService:_admit(player)
	local session = self._session
	if not session or session.Members[player] then return end
	if not WorldService:RestorePlayer(player) then return false end
	session.Members[player] = true
	session.PlayerCount += 1
	WorldService:SetMembers(session.Members)
	self:_setMenuState(player, false)
	return true
end

function WorldSessionService:_revokeRuntimeMember(player, reason)
	local session = self._session
	if not session or not session.Members[player] then return true end
	player:SetAttribute("ReturningToMenu", true); player:SetAttribute("SessionStarted", false)
	WorldService:CapturePlayer(player)
	local isLastPlayer = session.PlayerCount == 1
	local saved = WorldService:Save(isLastPlayer, reason or "MembershipRevoked")
	if not saved then
		player:SetAttribute("ReturningToMenu", false); player:SetAttribute("SessionStarted", true)
		return false
	end
	session.Members[player] = nil; session.PlayerCount = math.max(0, session.PlayerCount - 1)
	WorldService:SetMembers(session.Members); self:_setMenuState(player, true)
	player:SetAttribute("ReturningToMenu", false)
	if isLastPlayer then WorldService:DiscardClosedWorld(); self._session = nil end
	return true
end

function WorldSessionService:_newRuntimeSession(data)
	return {WorldId = data.WorldId, OwnerUserId = data.OwnerUserId, WorldSlot = data.OwnerSlot,
		MaxPlayers = data.MaxPlayers, DisplayName = data.DisplayName, PlayerCount = 0, Members = {}}
end

function WorldSessionService:_routePlayer(player, worldId, data)
	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions:SetTeleportData({WorldId = worldId, MembershipRoute = true})
	local lock = data.SessionLock
	if lock and (lock.ExpiresAt or 0) > os.time() then
		local accessCode = data.Routing and data.Routing.ReservedServerAccessCode
		if typeof(accessCode) == "string" and accessCode ~= "" then
			teleportOptions.ReservedServerAccessCode = accessCode
		elseif typeof(lock.JobId) == "string" and lock.JobId ~= "" and lock.JobId ~= game.JobId then
			teleportOptions.ServerInstanceId = lock.JobId
		else
			return false
		end
	else
		local reserved, proposedCode = pcall(TeleportService.ReserveServerAsync, TeleportService, game.PlaceId)
		if not reserved or typeof(proposedCode) ~= "string" then return false end
		local prepared, selectedCode = WorldService:PrepareReservedRoute(worldId, proposedCode)
		if not prepared then return false end
		teleportOptions.ReservedServerAccessCode = selectedCode
	end
	local ok, teleportError = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, {player}, teleportOptions)
	if not ok then warn("[WorldSession] Membership routing failed: " .. tostring(teleportError)); return false end
	return true
end

function WorldSessionService:_joinWorldById(player, worldId)
	local authorized, dataOrError = WorldService:GetWorldAccessInfo(player.UserId, worldId)
	if not authorized then return {Ok = false, Error = dataOrError, State = self:_publicStateFor(player)} end
	local data = dataOrError
	if self._session then
		if self._session.WorldId ~= worldId then
			return self:_routePlayer(player, worldId, data)
				and {Ok = true, Routing = true, State = self:_publicStateFor(player)}
				or {Ok = false, Error = "TeleportFailed", State = self:_publicStateFor(player)}
		end
		if self._session.Members[player] then return {Ok = true, Started = true, State = self:_publicState()} end
		if self._session.PlayerCount >= self._session.MaxPlayers then
			return {Ok = false, Error = "SessionFull", State = self:_publicState()}
		end
		if not self:_admit(player) then return {Ok = false, Error = "RestoreFailed", State = self:_publicState()} end
		return {Ok = true, Started = true, State = self:_publicState()}
	end
	local lock = data.SessionLock
	if lock and (lock.ExpiresAt or 0) > os.time() and lock.JobId ~= game.JobId then
		return self:_routePlayer(player, worldId, data)
			and {Ok = true, Routing = true, State = self:_publicStateFor(player)}
			or {Ok = false, Error = "TeleportFailed", State = self:_publicStateFor(player)}
	end
	local loaded, loadedData = WorldService:Load(player, worldId)
	if not loaded then return {Ok = false, Error = loadedData, State = self:_publicState()} end
	self._session = self:_newRuntimeSession(loadedData)
	if not self:_admit(player) then
		WorldService:Close("MembershipLoadRollback"); self._session = nil
		return {Ok = false, Error = "RestoreFailed", State = self:_publicState()}
	end
	return {Ok = true, Started = true, State = self:_publicState()}
end

local function resolveNames(records)
	for _, record in records do
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, record.UserId or record.OwnerUserId)
		record.Name = ok and name or ("JOUEUR " .. tostring(record.UserId or record.OwnerUserId))
	end
end

function WorldSessionService:_getState(player)
	local cached = self._getStateCache[player]
	local version = self._getStateVersions[player] or 0
	if cached and cached.Version == version and os.clock() - cached.Timestamp < Config.GET_STATE_CACHE_SECONDS then
		return cached.Response
	end
	if self._getStateInFlight[player] then
		return {Ok = false, Error = "RequestInProgress", State = self:_publicStateFor(player)}
	end
	self._getStateInFlight[player] = true
	local callOk, response = pcall(function()
		local ok, slotsOrError = WorldService:GetOwnerSlots(player.UserId)
		if not ok then return {Ok = false, Error = slotsOrError, State = self:_publicStateFor(player)} end
		local joinedOk, joinedOrError = WorldService:GetJoinedWorlds(player.UserId)
		if not joinedOk then return {Ok = false, Error = joinedOrError, State = self:_publicStateFor(player)} end
		local state = self:_publicStateFor(player)
		state.Slots = slotsOrError
		resolveNames(joinedOrError.JoinedWorlds)
		resolveNames(joinedOrError.PendingInvites)
		state.JoinedWorlds = joinedOrError.JoinedWorlds
		state.PendingInvites = joinedOrError.PendingInvites
		return {Ok = true, State = state}
	end)
	self._getStateInFlight[player] = nil
	if not callOk then error(response) end
	if response.Ok and player.Parent == Players and (self._getStateVersions[player] or 0) == version then
		self._getStateCache[player] = {Timestamp = os.clock(), Version = version, Response = response}
	end
	return response
end

function WorldSessionService:_invalidateGetState(player)
	self._getStateCache[player] = nil
	self._getStateVersions[player] = (self._getStateVersions[player] or 0) + 1
end

function WorldSessionService:_handle(player, action, payload)
	if action == "GetState" then
		return self:_getState(player)
	end
	local now = os.clock()
	if now - (self._lastRequests[player] or -math.huge) < Config.REQUEST_COOLDOWN then
		return {Ok = false, Error = "RequestInProgress", State = self:_publicState()}
	end
	self._lastRequests[player] = now

	if action == "ListFriends" then
		local friends = {}
		local ok, pages = pcall(Players.GetFriendsAsync, Players, player.UserId)
		if not ok then return {Ok = false, Error = "FriendListUnavailable", State = self:_publicState()} end
		repeat
			for _, friend in pages:GetCurrentPage() do
				table.insert(friends, {UserId = friend.Id, Name = friend.Username, DisplayName = friend.DisplayName})
			end
			if pages.IsFinished or #friends >= 200 then break end
			local advanced = pcall(function() pages:AdvanceToNextPageAsync() end)
			if not advanced then break end
		until false
		return {Ok = true, Friends = friends, State = self:_publicState()}
	elseif action == "InviteMember" then
		if typeof(payload) ~= "table" or typeof(payload.WorldId) ~= "string" or typeof(payload.TargetUserId) ~= "number"
			or payload.TargetUserId ~= math.floor(payload.TargetUserId)
		then return {Ok = false, Error = "InvalidRequest", State = self:_publicState()} end
		local friendOk, isFriend = pcall(function() return player:IsFriendsWithAsync(payload.TargetUserId) end)
		if not friendOk or not isFriend then return {Ok = false, Error = "NotFriend", State = self:_publicState()} end
		local invited, inviteError = WorldService:InviteMember(player.UserId, payload.WorldId, payload.TargetUserId,
			Config.MAX_OFFICIAL_MEMBERS, Config.MAX_PENDING_INVITES)
		return {Ok = invited, Error = invited and nil or inviteError, State = self:_publicState()}
	elseif action == "AcceptInvite" then
		if typeof(payload) ~= "table" or typeof(payload.WorldId) ~= "string" then
			return {Ok = false, Error = "InvalidRequest", State = self:_publicState()}
		end
		local accepted, acceptError = WorldService:AcceptInvite(player.UserId, payload.WorldId,
			Config.JOINED_WORLD_SLOT_COUNT, Config.MAX_OFFICIAL_MEMBERS)
		return {Ok = accepted, Error = accepted and nil or acceptError, State = self:_publicState()}
	elseif action == "DeclineInvite" then
		if typeof(payload) ~= "table" or typeof(payload.WorldId) ~= "string" then
			return {Ok = false, Error = "InvalidRequest", State = self:_publicState()}
		end
		local declined = WorldService:DeclineInvite(player.UserId, payload.WorldId)
		return {Ok = declined, Error = declined and nil or "InviteNotFound", State = self:_publicState()}
	elseif action == "GetMembers" then
		if typeof(payload) ~= "table" or typeof(payload.WorldId) ~= "string" then
			return {Ok = false, Error = "InvalidRequest", State = self:_publicState()}
		end
		local gotMembers, membersOrError = WorldService:GetMembers(player.UserId, payload.WorldId)
		if not gotMembers then return {Ok = false, Error = membersOrError, State = self:_publicState()} end
		resolveNames(membersOrError.Members)
		return {Ok = true, Membership = membersOrError, State = self:_publicState()}
	elseif action == "RemoveMember" or action == "LeaveWorld" then
		if typeof(payload) ~= "table" or typeof(payload.WorldId) ~= "string" then
			return {Ok = false, Error = "InvalidRequest", State = self:_publicState()}
		end
		local memberUserId = action == "LeaveWorld" and player.UserId or payload.MemberUserId
		if typeof(memberUserId) ~= "number" then return {Ok = false, Error = "InvalidRequest", State = self:_publicState()} end
		local removed, removeError = WorldService:RemoveMember(player.UserId, payload.WorldId, memberUserId,
			action == "LeaveWorld")
		if removed and self._session and self._session.WorldId == payload.WorldId then
			for runtimePlayer in self._session.Members do
				if runtimePlayer.UserId == memberUserId then self:_revokeRuntimeMember(runtimePlayer, "MembershipRemoved"); break end
			end
		end
		return {Ok = removed, Error = removed and nil or removeError, State = self:_publicState()}
	elseif action == "JoinJoinedWorld" then
		if typeof(payload) ~= "table" or typeof(payload.WorldId) ~= "string" then
			return {Ok = false, Error = "InvalidRequest", State = self:_publicState()}
		end
		return self:_joinWorldById(player, payload.WorldId)
	elseif action == "Create" then
		if typeof(payload) ~= "table" then return {Ok = false, Error = "InvalidRequest", State = self:_publicState()} end
		local maxPlayers = payload.MaxPlayers
		local worldSlot = payload.WorldSlot
		if typeof(maxPlayers) ~= "number" or maxPlayers ~= math.floor(maxPlayers)
			or maxPlayers < Config.MIN_PLAYERS or maxPlayers > Config.MAX_PLAYERS
			or typeof(worldSlot) ~= "number" or worldSlot ~= math.floor(worldSlot)
			or worldSlot < 1 or worldSlot > Config.WORLD_SLOT_COUNT
		then
			return {Ok = false, Error = "InvalidRequest", State = self:_publicState()}
		end
		if self._session then
			if self._session.Members[player] then return {Ok = false, Error = "SessionAlreadyActive", State = self:_publicState()} end
			local createdRecord, recordOrError = WorldService:CreateRecord(player, worldSlot, maxPlayers)
			if not createdRecord then return {Ok = false, Error = recordOrError, State = self:_publicStateFor(player)} end
			return self:_routePlayer(player, recordOrError.WorldId, recordOrError)
				and {Ok = true, Routing = true, State = self:_publicStateFor(player)}
				or {Ok = false, Error = "TeleportFailed", State = self:_publicStateFor(player)}
		end
		local created, dataOrError = WorldService:Create(player, worldSlot, maxPlayers)
		if not created then return {Ok = false, Error = dataOrError, State = self:_publicState()} end
		self._session = {
			WorldId = dataOrError.WorldId, OwnerUserId = dataOrError.OwnerUserId,
			WorldSlot = dataOrError.OwnerSlot, MaxPlayers = dataOrError.MaxPlayers,
			DisplayName = dataOrError.DisplayName,
			PlayerCount = 0,
			Members = {},
		}
		if not self:_admit(player) then
			WorldService:Close("CreateRollback")
			self._session = nil
			return {Ok = false, Error = "RestoreFailed", State = self:_publicState()}
		end
		print(string.format("[WorldSession] Ephemeral session created by %d, slot=%d, max=%d", player.UserId, worldSlot, maxPlayers))
		return {Ok = true, Started = true, State = self:_publicState()}
	elseif action == "Continue" then
		if typeof(payload) ~= "table" then return {Ok = false, Error = "InvalidRequest", State = self:_publicState()} end
		local slot = payload.WorldSlot
		if typeof(slot) ~= "number" or slot ~= math.floor(slot) or slot < 1 or slot > Config.WORLD_SLOT_COUNT then
			return {Ok = false, Error = "InvalidRequest", State = self:_publicState()}
		end
		local listed, slotsOrError = WorldService:GetOwnerSlots(player.UserId)
		local slotData = listed and slotsOrError[slot]
		if not slotData then return {Ok = false, Error = listed and "SlotUnavailable" or slotsOrError, State = self:_publicState()} end
		return self:_joinWorldById(player, slotData.WorldId)
	elseif action == "Join" then
		local session = self._session
		if not session then return {Ok = false, Error = "SessionUnavailable", State = self:_publicState()} end
		local authorized, accessData = WorldService:GetWorldAccessInfo(player.UserId, session.WorldId)
		if not authorized then return {Ok = false, Error = accessData, State = self:_publicState()} end
		if session.Members[player] then return {Ok = true, Started = true, State = self:_publicState()} end
		if session.PlayerCount >= session.MaxPlayers then
			return {Ok = false, Error = "SessionFull", State = self:_publicState()}
		end
		if not self:_admit(player) then return {Ok = false, Error = "RestoreFailed", State = self:_publicState()} end
		print(string.format("[WorldSession] Player %d joined ephemeral session", player.UserId))
		return {Ok = true, Started = true, State = self:_publicState()}
	elseif action == "RenameWorld" then
		if self._session then return {Ok = false, Error = "SessionAlreadyActive", State = self:_publicState()} end
		if typeof(payload) ~= "table" or typeof(payload.WorldSlot) ~= "number"
			or payload.WorldSlot ~= math.floor(payload.WorldSlot)
			or payload.WorldSlot < 1 or payload.WorldSlot > Config.WORLD_SLOT_COUNT
			or typeof(payload.WorldId) ~= "string"
		then
			return {Ok = false, Error = "InvalidRequest", State = self:_publicState()}
		end
		if now - (self._lastRenames[player] or -math.huge) < Config.RENAME_COOLDOWN then
			return {Ok = false, Error = "RequestInProgress", State = self:_publicState()}
		end
		self._lastRenames[player] = now
		local filteredName, filterError = self:_filterWorldName(player, payload.DisplayName)
		if not filteredName then return {Ok = false, Error = filterError, State = self:_publicState()} end
		local renamed, renameError = WorldService:RenameOwnerWorld(
			player.UserId, payload.WorldSlot, payload.WorldId, filteredName
		)
		if not renamed then return {Ok = false, Error = renameError, State = self:_publicState()} end
		local listed, slots = WorldService:GetOwnerSlots(player.UserId)
		local state = self:_publicState()
		if listed then state.Slots = slots end
		return {Ok = true, DisplayName = filteredName, State = state}
	elseif action == "ReturnToMenu" then
		local session = self._session
		if not session or not session.Members[player] then
			return {Ok = false, Error = "SessionUnavailable", State = self:_publicState()}
		end
		if self._returning[player] then
			return {Ok = false, Error = "RequestInProgress", State = self:_publicState()}
		end
		self._returning[player] = true
		player:SetAttribute("ReturningToMenu", true)
		player:SetAttribute("SessionStarted", false)
		WorldService:CapturePlayer(player)
		local isLastPlayer = session.PlayerCount == 1
		local saved = WorldService:Save(isLastPlayer, "ReturnToMenu")
		if not saved then
			player:SetAttribute("ReturningToMenu", false)
			player:SetAttribute("SessionStarted", true)
			self._returning[player] = nil
			return {Ok = false, Error = "SaveFailed", State = self:_publicState()}
		end
		session.Members[player] = nil
		session.PlayerCount = math.max(0, session.PlayerCount - 1)
		WorldService:SetMembers(session.Members)
		self:_setMenuState(player, true)
		player:SetAttribute("ReturningToMenu", false)
		self._returning[player] = nil
		if isLastPlayer then
			WorldService:DiscardClosedWorld()
			self._session = nil
		end
		local state = self:_publicState()
		local listed, slots = WorldService:GetOwnerSlots(player.UserId)
		if listed then state.Slots = slots end
		return {Ok = true, ReturnedToMenu = true, State = state}
	elseif action == "DeleteWorld" then
		if self._session then return {Ok = false, Error = "WorldInUse", State = self:_publicState()} end
		if self._deleting[player] then return {Ok = false, Error = "DeleteInProgress", State = self:_publicState()} end
		if typeof(payload) ~= "table" or typeof(payload.WorldSlot) ~= "number"
			or payload.WorldSlot ~= math.floor(payload.WorldSlot)
			or payload.WorldSlot < 1 or payload.WorldSlot > Config.WORLD_SLOT_COUNT
			or typeof(payload.WorldId) ~= "string" or #payload.WorldId < 8 or #payload.WorldId > 64
			or payload.Confirmation ~= "DELETE"
		then
			return {Ok = false, Error = "InvalidRequest", State = self:_publicState()}
		end
		if now - (self._lastDeletes[player] or -math.huge) < Config.DELETE_COOLDOWN then
			return {Ok = false, Error = "RequestInProgress", State = self:_publicState()}
		end
		self._lastDeletes[player] = now
		self._deleting[player] = true
		local deleted, deleteError = WorldService:DeleteOwnerWorld(player.UserId, payload.WorldSlot, payload.WorldId)
		self._deleting[player] = nil
		if not deleted then return {Ok = false, Error = deleteError, State = self:_publicState()} end
		local listed, slots = WorldService:GetOwnerSlots(player.UserId)
		local state = self:_publicState()
		if listed then state.Slots = slots end
		return {Ok = true, Deleted = true, State = state}
	end
	return {Ok = false, Error = "InvalidAction", State = self:_publicState()}
end

function WorldSessionService:Start()
	local function setupPlayer(player)
		self:_setMenuState(player, true)
		task.defer(function()
			local joinData = player:GetJoinData()
			local teleportData = joinData and joinData.TeleportData
			if typeof(teleportData) == "table" and teleportData.MembershipRoute == true
				and typeof(teleportData.WorldId) == "string"
			then
				local response = self:_joinWorldById(player, teleportData.WorldId)
				if not response.Ok then warn("[WorldSession] Routed membership join rejected: " .. tostring(response.Error)) end
			end
		end)
		player.CharacterAdded:Connect(function()
			task.defer(function() self:_setMenuState(player, player:GetAttribute("SessionStarted") ~= true) end)
		end)
	end
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do setupPlayer(player) end
	task.spawn(function()
		while true do
			task.wait(15)
			local session = self._session
			if session then
				local loaded, world = WorldService:GetWorldAccessInfo(session.OwnerUserId, session.WorldId)
				if loaded then
					local revoked = {}
					for member in session.Members do
						if member.UserId ~= world.OwnerUserId
							and not (world.AuthorizedMembers or {})[tostring(member.UserId)]
						then table.insert(revoked, member) end
					end
					for _, member in revoked do self:_revokeRuntimeMember(member, "MembershipReconciled") end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		self._lastRequests[player] = nil
		self._getStateCache[player] = nil
		self._getStateInFlight[player] = nil
		self._getStateVersions[player] = nil
		self._lastRenames[player] = nil
		self._returning[player] = nil
		self._deleting[player] = nil
		self._lastDeletes[player] = nil
		local session = self._session
		if session and session.Members[player] then
			WorldService:CapturePlayer(player)
			session.Members[player] = nil
			session.PlayerCount = math.max(0, session.PlayerCount - 1)
			if session.PlayerCount == 0 then
				if WorldService:Close("PlayerRemoving") then
					self._session = nil
					print("[WorldSession] Persistent session saved and closed")
				else
					warn("[WorldSession] Final save failed; lock retained until lease expiry")
				end
			elseif not WorldService:Save(false, "PlayerRemoving") then
				warn("[WorldSession] Departing player snapshot save failed; world remains active")
			end
		end
	end)
	self._request.OnServerInvoke = function(player, action, payload)
		local ok, result = pcall(function() return self:_handle(player, action, payload) end)
		if not ok then
			warn("[WorldSession] Request failed: " .. tostring(result))
			return {Ok = false, Error = "ServerError", State = self:_publicStateFor(player)}
		end
		if action ~= "GetState" and result and result.Ok then
			self:_invalidateGetState(player)
			local affectedUserId
			if action == "InviteMember" then
				affectedUserId = typeof(payload) == "table" and payload.TargetUserId or nil
			elseif action == "RemoveMember" then
				affectedUserId = typeof(payload) == "table" and payload.MemberUserId or nil
			end
			if typeof(affectedUserId) == "number" then
				local affectedPlayer = Players:GetPlayerByUserId(affectedUserId)
				if affectedPlayer and affectedPlayer ~= player then self:_invalidateGetState(affectedPlayer) end
			end
		end
		if action ~= "GetState" and result then result.State = self:_publicStateFor(player) end
		return result
	end
end

return WorldSessionService.new()
