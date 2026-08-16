local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local WildCropConfig = require(ReplicatedStorage.Shared.Config.WildCropConfig)
local InventoryService = require(script.Parent.InventoryService)

local service = {_crops = setmetatable({}, {__mode = "k"}), _lastHits = {}}

local function getSpawnCFrame(spawnPoint)
	if spawnPoint:IsA("Attachment") then return spawnPoint.WorldCFrame end
	if spawnPoint:IsA("BasePart") then return spawnPoint.CFrame end
	if spawnPoint:IsA("Model") then return spawnPoint:GetPivot() end
	return nil
end

local function cloneTemplate(path)
	local current = ServerStorage:FindFirstChild("AssetImports")
	for _, name in path do current = current and current:FindFirstChild(name) end
	if not current then return nil end
	local wasArchivable = current.Archivable
	current.Archivable = true
	local succeeded, clone = pcall(function() return current:Clone() end)
	current.Archivable = wasArchivable
	if not succeeded or not clone then return nil end
	if clone:IsA("BasePart") then
		clone.Anchored = true
		clone.CanQuery = true
	end
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanQuery = true
		elseif descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		end
	end
	return clone
end

function service:_spawn(spawnPoint, definition)
	local cframe = getSpawnCFrame(spawnPoint)
	local visual = cframe and cloneTemplate(definition.TemplatePath)
	if not visual then
		warn("[MAYDEAD] WildTomato spawn/template invalid: " .. spawnPoint:GetFullName())
		return
	end
	if not visual:IsA("Model") then
		local wrapper = Instance.new("Model")
		visual.Parent = wrapper
		visual = wrapper
	end
	visual.Name = "WildTomatoPlant"
	local id = HttpService:GenerateGUID(false)
	visual:SetAttribute("WildCropId", id)
	visual:SetAttribute("WildCropType", "WildTomato")
	visual.Parent = workspace:FindFirstChild("ActiveWildCrops")
	visual:PivotTo(cframe)
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") then descendant:SetAttribute("WildCropId", id) end
	end
	local promptParent = visual.PrimaryPart or visual:FindFirstChildWhichIsA("BasePart", true)
	if not promptParent then visual:Destroy(); return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "RÉCOLTER TOMATES"
	prompt.ObjectText = "TOMATE SAUVAGE"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptParent
	local data = {Spawn = spawnPoint, Definition = definition, Available = true}
	self._crops[visual] = data
	prompt.Triggered:Connect(function(player)
		if player:GetAttribute("SessionStarted") ~= true then return end
		self:_claim(player, visual, "Harvest")
	end)
end

function service:_claim(player, crop, mode)
	local data = self._crops[crop]
	if not data or not data.Available or not crop:IsDescendantOf(workspace) then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or (root.Position - crop:GetPivot().Position).Magnitude > 10 then return end
	local reward = mode == "Harvest" and data.Definition.HarvestReward or data.Definition.DestroyReward
	if not InventoryService:CanAddItem(player, reward.ItemId, reward.Amount) then return end
	data.Available = false
	local result = InventoryService:AddItem(player, reward.ItemId, reward.Amount)
	if result.Remaining > 0 then data.Available = true; return end
	self._crops[crop] = nil
	crop:Destroy()
	task.delay(data.Definition.RespawnTime, function()
		if data.Spawn and data.Spawn:IsDescendantOf(workspace) then self:_spawn(data.Spawn, data.Definition) end
	end)
end

function service:_handleTool(player, crop)
	local data = self._crops[crop]
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if not data or not tool or not data.Definition.AllowedTools[tool.Name] then return end
	local expectedItem = tool.Name == "Axe" and "StoneAxe" or "StonePickaxe"
	if InventoryService:GetActiveItem(player) ~= expectedItem then return end
	local now = os.clock()
	if now - (self._lastHits[player] or 0) < 0.65 then return end
	self._lastHits[player] = now
	self:_claim(player, crop, "Destroy")
	if not self._crops[crop] then
		local harvestResult = ReplicatedStorage:FindFirstChild("HarvestResult")
		if harvestResult then harvestResult:FireClient(player, tool.Name == "Axe" and "Wood" or "Stone") end
		print("[MAYDEAD] +3 GRAINES DE TOMATE")
	end
end

function service:Start()
	local active = workspace:FindFirstChild("ActiveWildCrops") or Instance.new("Folder")
	active.Name = "ActiveWildCrops"
	active.Parent = workspace
	local request = Instance.new("RemoteEvent")
	request.Name = "WildCropHitRequest"
	request.Parent = ReplicatedStorage
	request.OnServerEvent:Connect(function(player, crop)
		if player:GetAttribute("SessionStarted") ~= true then return end
		self:_handleTool(player, crop)
	end)
	local spawns = workspace:FindFirstChild("WildCropSpawns") or Instance.new("Folder")
	spawns.Name = "WildCropSpawns"
	spawns.Parent = workspace
	for _, spawnPoint in spawns:GetChildren() do self:_spawn(spawnPoint, WildCropConfig.WildTomato) end
	spawns.ChildAdded:Connect(function(spawnPoint) self:_spawn(spawnPoint, WildCropConfig.WildTomato) end)
end

return service
