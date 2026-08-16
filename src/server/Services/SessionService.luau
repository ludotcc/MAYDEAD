local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.PersistenceConfig)
local DataService = require(script.Parent.DataService)

local SessionService = {_active = nil}

local function setState(active, state)
	active.State = state
	active.Valid = state == "Confirmed"
end

function SessionService:Acquire(worldId)
	if self._active then return false, "ServerAlreadyUsingWorld" end
	local token = HttpService:GenerateGUID(false)
	local acquired = DataService:AcquireLock(worldId, token)
	if not acquired then return false, "WorldAlreadyActive" end
	self._active = {WorldId = worldId, Token = token, State = "Confirmed", Valid = true}
	task.spawn(function()
		while self._active and self._active.Token == token do
			task.wait(Config.LOCK_RENEW_INTERVAL)
			if not self._active or self._active.Token ~= token then break end
			local renewed, renewError = DataService:RenewLock(worldId, token)
			local active = self._active
			if not active or active.Token ~= token then break end
			if renewed then
				if active.State == "Uncertain" then
					print("[SessionService] World lease confirmed again; saves are enabled")
				end
				setState(active, "Confirmed")
			elseif renewError == "Unavailable" then
				if active.State ~= "Uncertain" then
					warn("[SessionService] World lease confirmation unavailable; saves are fenced while renewal continues")
				end
				setState(active, "Uncertain")
			else
				setState(active, "Lost")
				warn("[SessionService] World lease ownership was lost; future saves are fenced")
				break
			end
		end
	end)
	return true, token
end

function SessionService:GetActive() return self._active end
function SessionService:Clear(token)
	if self._active and self._active.Token == token then
		setState(self._active, "Stopped")
		self._active = nil
	end
end

return SessionService
