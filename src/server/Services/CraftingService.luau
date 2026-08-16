local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local RecipeDefinitions = require(SharedFolder:WaitForChild("Definitions"):WaitForChild("RecipeDefinitions"))
local BalanceConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("BalanceConfig"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local StationService = require(script.Parent:WaitForChild("StationService"))

local CraftingService = {}
CraftingService.__index = CraftingService

local WORKBENCH_TAG = "MAYDEAD_CraftingTable"
local WORKBENCH_RANGE = 10

local function isNearWorkbench(player, station)
	if typeof(station) ~= "Instance"
		or not station:IsDescendantOf(workspace)
		or not CollectionService:HasTag(station, WORKBENCH_TAG)
	then
		return false
	end
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	return rootPart ~= nil and (rootPart.Position - station:GetPivot().Position).Magnitude <= WORKBENCH_RANGE
end

function CraftingService.new()
	local self = setmetatable({}, CraftingService)
	self._busyPlayers = {}
	self._request = Instance.new("RemoteEvent")
	self._request.Name = "CraftRequest"
	self._request.Parent = ReplicatedStorage
	self._result = Instance.new("RemoteEvent")
	self._result.Name = "CraftResult"
	self._result.Parent = ReplicatedStorage
	self._openWorkbench = Instance.new("RemoteEvent")
	self._openWorkbench.Name = "OpenWorkbench"
	self._openWorkbench.Parent = ReplicatedStorage
	return self
end

function CraftingService:_handleRequest(player, recipeId, station)
	if typeof(recipeId) ~= "string" or self._busyPlayers[player] then
		return
	end

	local recipe = RecipeDefinitions[recipeId]
	if not recipe then
		self._result:FireClient(player, false, recipeId, "InvalidRecipe")
		return
	end
	if recipe.CraftType == "Workbench" then
		if not isNearWorkbench(player, station) then
			self._result:FireClient(player, false, recipeId, "WorkbenchRequired")
			return
		end
	elseif recipe.CraftType ~= "Basic" then
		self._result:FireClient(player, false, recipeId, "InvalidCraftType")
		return
	end

	self._busyPlayers[player] = true
	task.wait(recipe.CraftTime or 0)
	local completed, crafted, reason = pcall(function()
		if recipe.CraftType == "Workbench" then
			return StationService:TryWorkbenchCraft(player, station, recipe)
		end
		return InventoryService:TryCraft(player, recipe.Ingredients, recipe.ResultItemId, recipe.ResultAmount)
	end)
	self._busyPlayers[player] = nil
	if not completed then
		warn("[MAYDEAD] Craft transaction failed: " .. tostring(crafted))
		self._result:FireClient(player, false, recipeId, "ServerError")
		return
	end
	if crafted and BalanceConfig.BALANCE_DEBUG then
		print("[MAYDEAD][BALANCE] Craft " .. recipeId)
	end
	self._result:FireClient(player, crafted, recipeId, reason)
end

function CraftingService:Start()
	Players.PlayerRemoving:Connect(function(player)
		self._busyPlayers[player] = nil
	end)
	self._request.OnServerEvent:Connect(function(player, recipeId, station)
		if player:GetAttribute("SessionStarted") ~= true then return end
		self:_handleRequest(player, recipeId, station)
	end)
end

function CraftingService:GetOpenWorkbenchRemote()
	return self._openWorkbench
end

return CraftingService.new()
