local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "DamageFeedback"

local DamageFeedbackService = {}
DamageFeedbackService.__index = DamageFeedbackService

local function getTargetPosition(target)
	if typeof(target) ~= "Instance" then
		return nil
	end
	if target:IsA("Model") then
		return target:GetPivot().Position
	end
	if target:IsA("BasePart") then
		return target.Position
	end
	return nil
end

function DamageFeedbackService.new()
	local self = setmetatable({}, DamageFeedbackService)
	self._started = false
	self._characterConnections = {}
	self._healthConnections = {}
	self._remote = Instance.new("RemoteEvent")
	self._remote.Name = REMOTE_NAME
	self._remote.Parent = ReplicatedStorage
	return self
end

function DamageFeedbackService:_watchCharacter(player, character)
	if self._healthConnections[player] then
		self._healthConnections[player]:Disconnect()
		self._healthConnections[player] = nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	local previousHealth = humanoid.Health
	self._healthConnections[player] = humanoid.HealthChanged:Connect(function(health)
		local damage = previousHealth - health
		previousHealth = health
		if damage > 0 and player.Parent == Players then
			self._remote:FireClient(player, "Taken", damage)
		end
	end)
end

function DamageFeedbackService:_watchPlayer(player)
	if self._characterConnections[player] then
		return
	end
	self._characterConnections[player] = player.CharacterAdded:Connect(function(character)
		self:_watchCharacter(player, character)
	end)
	if player.Character then
		task.defer(function()
			if player.Parent == Players and player.Character then
				self:_watchCharacter(player, player.Character)
			end
		end)
	end
end

function DamageFeedbackService:NotifyDealt(player, amount, target)
	if player.Parent ~= Players or typeof(amount) ~= "number" or amount <= 0 then
		return
	end
	local position = getTargetPosition(target)
	self._remote:FireClient(player, "Dealt", amount, target, position)
end

function DamageFeedbackService:Start()
	if self._started then
		return
	end
	self._started = true
	Players.PlayerAdded:Connect(function(player)
		self:_watchPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		if self._characterConnections[player] then
			self._characterConnections[player]:Disconnect()
			self._characterConnections[player] = nil
		end
		if self._healthConnections[player] then
			self._healthConnections[player]:Disconnect()
			self._healthConnections[player] = nil
		end
	end)
	for _, player in Players:GetPlayers() do
		self:_watchPlayer(player)
	end
end

return DamageFeedbackService.new()
