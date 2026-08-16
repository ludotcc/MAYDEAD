local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.PersistenceConfig)
local DataService = require(script.Parent.DataService)

local SessionService = {_active = nil}

function SessionService:Acquire(worldId)
	if self._active then return false, "ServerAlreadyUsingWorld" end
	local token = HttpService:GenerateGUID(false)
	local acquired = DataService:AcquireLock(worldId, token)
	if not acquired then return false, "WorldAlreadyActive" end
	self._active = {WorldId = worldId, Token = token, Valid = true}
	task.spawn(function()
		while self._active and self._active.Token == token do
			task.wait(Config.LOCK_RENEW_INTERVAL)
			if not self._active or self._active.Token ~= token then break end
			if not DataService:RenewLock(worldId, token) then
				self._active.Valid = false
				warn("[SessionService] Lost world lease; future saves are fenced")
				break
			end
		end
	end)
	return true, token
end

function SessionService:GetActive() return self._active end
function SessionService:Clear(token)
	if self._active and self._active.Token == token then self._active = nil end
end

return SessionService
