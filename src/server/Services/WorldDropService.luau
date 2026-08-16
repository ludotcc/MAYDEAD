local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Config = require(SharedFolder:WaitForChild("Config"):WaitForChild("WorldDropConfig"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local WorldDropService = {}
WorldDropService.__index = WorldDropService

local ITEM_ID = "RawMeat"
local TEMPLATE_NAME = "RawMeatWorldModel"

local function getTemplate()
	local imports = ServerStorage:FindFirstChild("AssetImports")
	return imports and imports:FindFirstChild(TEMPLATE_NAME)
end

local function auditTemplate(template)
	print(string.format("[MAYDEAD][WORLD_DROP] Template=%s Class=%s Pivot=%s",
		template:GetFullName(), template.ClassName,
		tostring(template:IsA("Model") and template:GetPivot() or template.CFrame)))
	for _, item in {template, table.unpack(template:GetDescendants())} do
		if item:IsA("BasePart") then
			print(string.format("[MAYDEAD][WORLD_DROP] Part=%s Class=%s Size=%s Anchored=%s Collide=%s Touch=%s Query=%s",
				item:GetFullName(), item.ClassName, tostring(item.Size), tostring(item.Anchored),
				tostring(item.CanCollide), tostring(item.CanTouch), tostring(item.CanQuery)))
		end
	end
end

local function prepareClone(template)
	local clone = template:Clone()
	clone.Name = "RawMeatWorldDrop"
	clone:SetAttribute("ItemId", ITEM_ID)
	clone:SetAttribute("WorldDrop", true)
	local parts = {clone}
	for _, descendant in clone:GetDescendants() do table.insert(parts, descendant) end
	local hasPart = false
	for _, item in parts do
		if item:IsA("BasePart") then
			hasPart = true
			item.Anchored = true
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = true
		end
	end
	if not hasPart then clone:Destroy(); return nil end
	local originalSize = clone:IsA("Model") and clone:GetExtentsSize() or clone.Size
	local longest = math.max(originalSize.X, originalSize.Y, originalSize.Z)
	if longest <= 0 then clone:Destroy(); return nil end
	local scale = (Config.RAW_MEAT_TARGET_LENGTH * Config.RAW_MEAT_WORLD_DROP_SCALE) / longest
	if clone:IsA("Model") then clone:ScaleTo(clone:GetScale() * scale) else clone.Size *= scale end
	local finalSize = clone:IsA("Model") and clone:GetExtentsSize() or clone.Size
	clone:SetAttribute("OriginalDimensions", tostring(originalSize))
	clone:SetAttribute("RuntimeScale", scale)
	clone:SetAttribute("WorldDropScaleMultiplier", Config.RAW_MEAT_WORLD_DROP_SCALE)
	print(string.format("[MAYDEAD][WORLD_DROP] RawMeat scale=%.5f original=%s final=%s", scale, tostring(originalSize), tostring(finalSize)))
	return clone
end

local function getBottomOffset(instance)
	if instance:IsA("Model") then
		local pivot = instance:GetPivot()
		local boxCFrame, boxSize = instance:GetBoundingBox()
		return math.max(0, pivot.Position.Y - (boxCFrame.Position.Y - boxSize.Y * 0.5))
	end
	return instance.Size.Y * 0.5
end

local function pivotTo(instance, cframe)
	if instance:IsA("Model") then instance:PivotTo(cframe) else instance.CFrame = cframe end
end

function WorldDropService.new()
	local self = setmetatable({}, WorldDropService)
	self._lastDrop = {}
	self._request = Instance.new("RemoteEvent")
	self._request.Name = "WorldDropRequest"
	self._request.Parent = ReplicatedStorage
	self._drops = setmetatable({}, {__mode = "k"})
	self._reservedBy = setmetatable({}, {__mode = "k"})
	return self
end

function WorldDropService:GetAvailableRawMeat(position, radius)
	local best, bestDistance
	for drop, state in self._drops do
		if drop.Parent and state == "AVAILABLE" and drop:GetAttribute("ItemId") == ITEM_ID then
			local pivot = drop:IsA("Model") and drop:GetPivot() or drop.CFrame
			local distance = (pivot.Position - position).Magnitude
			if distance <= radius and (not bestDistance or distance < bestDistance) then best, bestDistance = drop, distance end
		end
	end
	return best, bestDistance
end

function WorldDropService:IsAvailable(drop)
	return drop and drop.Parent ~= nil and self._drops[drop] == "AVAILABLE"
end

function WorldDropService:ReserveForCheetah(drop, cheetah)
	if not self:IsAvailable(drop) or typeof(cheetah) ~= "Instance" then return false end
	self._drops[drop] = "RESERVED_BY_CHEETAH"
	self._reservedBy[drop] = cheetah
	drop:SetAttribute("DropState", "RESERVED_BY_CHEETAH")
	local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then prompt.Enabled = false end
	return true
end

function WorldDropService:ReleaseFromCheetah(drop, cheetah)
	if not drop or self._drops[drop] ~= "RESERVED_BY_CHEETAH" or self._reservedBy[drop] ~= cheetah or not drop.Parent then return false end
	self._drops[drop] = "AVAILABLE"
	self._reservedBy[drop] = nil
	drop:SetAttribute("DropState", "AVAILABLE")
	local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then prompt.Enabled = true end
	return true
end

function WorldDropService:ConsumeForCheetah(drop, cheetah)
	if not drop or self._drops[drop] ~= "RESERVED_BY_CHEETAH" or self._reservedBy[drop] ~= cheetah or not drop.Parent then return nil end
	self._drops[drop] = "CONSUMED"
	self._reservedBy[drop] = nil
	drop:SetAttribute("DropState", "CONSUMED")
	local userId = drop:GetAttribute("DroppedByUserId")
	drop:Destroy()
	return typeof(userId) == "number" and userId or nil
end

function WorldDropService:_expire(drop)
	local reservationDeadline = os.clock() + Config.RAW_MEAT_RESERVED_EXPIRY_GRACE
	while drop.Parent and self._drops[drop] == "RESERVED_BY_CHEETAH" and os.clock() < reservationDeadline do task.wait(1) end
	if drop.Parent and self._drops[drop] == "AVAILABLE" then
		self._drops[drop] = "EXPIRED"
		drop:SetAttribute("DropState", "EXPIRED")
		drop:Destroy()
	elseif drop.Parent and self._drops[drop] == "RESERVED_BY_CHEETAH" then
		self._drops[drop] = "EXPIRED"
		drop:SetAttribute("DropState", "EXPIRED")
		drop:Destroy()
	end
end

function WorldDropService:ClearWorldDrops()
	if not self._folder then return end
	for _, drop in self._folder:GetChildren() do
		self._drops[drop] = "WORLD_CLEANUP"
		drop:Destroy()
	end
end

function WorldDropService:_pickup(player, drop)
	if not self:IsAvailable(drop) or player:GetAttribute("SessionStarted") ~= true then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end
	local pivot = drop:IsA("Model") and drop:GetPivot() or drop.CFrame
	if (root.Position - pivot.Position).Magnitude > Config.PICKUP_DISTANCE then return end
	if not InventoryService:CanAddItem(player, ITEM_ID, 1) then return end
	self._drops[drop] = "RESERVED_BY_PLAYER"
	drop:SetAttribute("DropState", "RESERVED_BY_PLAYER")
	local added = InventoryService:AddItem(player, ITEM_ID, 1)
	if added.Added == 1 then self._drops[drop] = "CONSUMED"; drop:Destroy()
	else self._drops[drop] = "AVAILABLE"; drop:SetAttribute("DropState", "AVAILABLE") end
end

function WorldDropService:_dropRawMeat(player)
	if player:GetAttribute("SessionStarted") ~= true or player:GetAttribute("InMainMenu") == true
		or player:GetAttribute("ReturningToMenu") == true
	then return end
	local now = os.clock()
	if now - (self._lastDrop[player] or 0) < Config.RAW_MEAT_DROP_COOLDOWN then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return end
	if InventoryService:GetActiveItem(player) ~= ITEM_ID or not InventoryService:HasItem(player, ITEM_ID, 1) then return end
	local template = getTemplate()
	if not template or (not template:IsA("Model") and not template:IsA("BasePart")) then
		warn("[MAYDEAD][WORLD_DROP] Missing or invalid ServerStorage.AssetImports.RawMeatWorldModel")
		return
	end
	local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if forward.Magnitude < 0.01 then return end
	forward = forward.Unit
	local candidate = root.Position + forward * Config.RAW_MEAT_DROP_DISTANCE
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.IgnoreWater = false
	local obstruction = workspace:Raycast(root.Position, forward * Config.RAW_MEAT_DROP_DISTANCE, params)
	if obstruction and (obstruction.Position - root.Position).Magnitude < Config.RAW_MEAT_DROP_DISTANCE - 0.25 then return end
	local ground = workspace:Raycast(candidate + Vector3.new(0, Config.GROUND_RAY_HEIGHT, 0),
		Vector3.new(0, -Config.GROUND_RAY_DEPTH, 0), params)
	if not ground or ground.Material == Enum.Material.Water then return end
	if (ground.Position - root.Position).Magnitude > Config.MAX_ROOT_TO_DROP_DISTANCE then return end
	local clone = prepareClone(template)
	if not clone then return end
	local target = CFrame.new(ground.Position + Vector3.new(0, getBottomOffset(clone) + 0.02, 0))
		* CFrame.Angles(0, math.atan2(-forward.X, -forward.Z), 0)
	pivotTo(clone, target)
	clone:SetAttribute("DroppedByUserId", player.UserId)
	clone:SetAttribute("DropState", "AVAILABLE")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "RAMASSER"
	prompt.ObjectText = "VIANDE CRUE"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = Config.PICKUP_DISTANCE
	prompt.RequiresLineOfSight = true
	prompt.Parent = clone:IsA("BasePart") and clone or clone:FindFirstChildWhichIsA("BasePart", true)
	local removed = InventoryService:RemoveItem(player, ITEM_ID, 1)
	if removed.Removed ~= 1 then clone:Destroy(); return end
	local ok = pcall(function()
		clone.Parent = self._folder
	end)
	if not ok or not clone.Parent then
		clone:Destroy()
		local restored = InventoryService:AddItem(player, ITEM_ID, 1)
		if restored.Added ~= 1 then warn("[MAYDEAD][WORLD_DROP] CRITICAL: RawMeat rollback failed for " .. player.Name) end
		return
	end
	self._lastDrop[player] = now
	self._drops[clone] = "AVAILABLE"
	prompt.Triggered:Connect(function(triggeringPlayer) self:_pickup(triggeringPlayer, clone) end)
	task.delay(Config.RAW_MEAT_DROP_LIFETIME, function() self:_expire(clone) end)
end

function WorldDropService:Start()
	self._folder = workspace:FindFirstChild("WorldDrops") or Instance.new("Folder")
	self._folder.Name = "WorldDrops"
	self._folder.Parent = workspace
	local template = getTemplate()
	if template and (template:IsA("Model") or template:IsA("BasePart")) then auditTemplate(template) end
	local players=game:GetService("Players")
	local function cleanupIfNoActiveWorldPlayers()
		for _,player in players:GetPlayers() do if player:GetAttribute("SessionStarted")==true then return end end
		self:ClearWorldDrops()
	end
	players.PlayerAdded:Connect(function(player) player:GetAttributeChangedSignal("SessionStarted"):Connect(function() task.defer(cleanupIfNoActiveWorldPlayers) end) end)
	players.PlayerRemoving:Connect(function(player) self._lastDrop[player] = nil; task.defer(cleanupIfNoActiveWorldPlayers) end)
	self._request.OnServerEvent:Connect(function(player, action)
		if action == "DropRawMeat" then self:_dropRawMeat(player) end
	end)
end

return WorldDropService.new()
