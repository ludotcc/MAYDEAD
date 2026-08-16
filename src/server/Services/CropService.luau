local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CropConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("CropConfig"))
local InventoryService = require(script.Parent:WaitForChild("InventoryService"))

local CROP_TYPE = "Tomato"
local TOMATO_CONFIG = CropConfig.Tomato
local SEED_ITEM_ID = TOMATO_CONFIG.SeedItemId
local HARVEST_ITEM_ID = TOMATO_CONFIG.HarvestItemId
local HARVEST_QUANTITY = TOMATO_CONFIG.HarvestQuantity
local STAGE_INTERVAL = TOMATO_CONFIG.StageInterval
local READY_TIME = TOMATO_CONFIG.ReadyTime

local CropService = {}
CropService.__index = CropService

local function findPlantPoint(plot)
	return plot:FindFirstChild("PlantPoint", true)
end

local function getPlantCFrame(plantPoint)
	if plantPoint:IsA("Attachment") then
		return plantPoint.WorldCFrame
	elseif plantPoint:IsA("BasePart") then
		return plantPoint.CFrame
	end
	return nil
end

local function prepareStage(instance)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
		elseif descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		end
	end
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.CanCollide = false
		instance.CanTouch = false
	end
end

local function clonePreservingArchivable(source)
	local changed = {}
	if not source.Archivable then
		table.insert(changed, source)
		source.Archivable = true
	end
	for _, descendant in source:GetDescendants() do
		if not descendant.Archivable then
			table.insert(changed, descendant)
			descendant.Archivable = true
		end
	end
	local succeeded, clone = pcall(function()
		return source:Clone()
	end)
	for _, instance in changed do
		instance.Archivable = false
	end
	return succeeded and clone or nil
end

function CropService.new()
	local self = setmetatable({}, CropService)
	self._plots = setmetatable({}, {__mode = "k"})
	self._feedback = Instance.new("RemoteEvent")
	self._feedback.Name = "CropFeedback"
	self._feedback.Parent = ReplicatedStorage
	return self
end

function CropService:_getStageSource(stage)
	local assetImports = ServerStorage:FindFirstChild("AssetImports")
	local crops = assetImports and assetImports:FindFirstChild("Crops")
	local tomato = crops and crops:FindFirstChild("Tomato")
	return tomato and tomato:FindFirstChild("Tomato_Stage" .. stage)
end

function CropService:_setVisual(plot, data, stage)
	if data.Visual then
		data.Visual:Destroy()
		data.Visual = nil
	end
	if stage <= 0 then
		return
	end
	local source = self:_getStageSource(stage)
	local plantCFrame = getPlantCFrame(data.PlantPoint)
	if not source or not plantCFrame then
		warn("[MAYDEAD] Tomato stage unavailable: " .. tostring(stage))
		return
	end
	local visual = clonePreservingArchivable(source)
	if not visual then
		warn("[MAYDEAD] Tomato stage clone failed: " .. tostring(stage))
		return
	end
	visual.Name = "ActiveTomatoCrop"
	prepareStage(visual)
	visual.Parent = plot
	if visual:IsA("Model") then
		visual:PivotTo(plantCFrame)
	elseif visual:IsA("BasePart") then
		visual.CFrame = plantCFrame
	else
		local model = Instance.new("Model")
		model.Name = visual.Name
		visual.Parent = model
		model.Parent = plot
		model:PivotTo(plantCFrame)
		visual = model
	end
	data.Visual = visual
end

function CropService:_updatePlot(plot, data, now)
	if not data.PlantedAt then
		return
	end
	local elapsed = now - data.PlantedAt
	local stage = math.clamp(math.floor(elapsed / STAGE_INTERVAL) + 1, 1, 4)
	local ready = elapsed >= READY_TIME
	if stage ~= data.Stage then
		data.Stage = stage
		plot:SetAttribute("GrowthStage", stage)
		self:_setVisual(plot, data, stage)
	end
	if ready ~= data.Ready then
		data.Ready = ready
		plot:SetAttribute("ReadyToHarvest", ready)
		data.Prompt.ActionText = ready and "RÉCOLTER" or "CROISSANCE"
		data.Prompt.Enabled = ready
	end
end

function CropService:_plant(player, plot, data)
	if data.PlantedAt then
		return
	end
	if not InventoryService:HasItem(player, SEED_ITEM_ID, 1) then
		self._feedback:FireClient(player, "GRAINE DE TOMATE REQUISE")
		return
	end
	local removed = InventoryService:RemoveItem(player, SEED_ITEM_ID, 1)
	if removed.Remaining > 0 then
		return
	end
	data.PlantedAt = workspace:GetServerTimeNow()
	data.Stage = 1
	data.Ready = false
	plot:SetAttribute("CropType", CROP_TYPE)
	plot:SetAttribute("GrowthStage", 1)
	plot:SetAttribute("PlantedAt", data.PlantedAt)
	plot:SetAttribute("ReadyToHarvest", false)
	data.Prompt.ActionText = "CROISSANCE"
	data.Prompt.Enabled = false
	self:_setVisual(plot, data, 1)
end

function CropService:_harvest(player, plot, data)
	if not data.Ready then
		return
	end
	if not InventoryService:CanAddItem(player, HARVEST_ITEM_ID, HARVEST_QUANTITY) then
		self._feedback:FireClient(player, "INVENTAIRE PLEIN")
		return
	end
	local result = InventoryService:AddItem(player, HARVEST_ITEM_ID, HARVEST_QUANTITY)
	if result.Remaining > 0 then
		return
	end
	data.PlantedAt = nil
	data.Stage = 0
	data.Ready = false
	plot:SetAttribute("CropType", nil)
	plot:SetAttribute("GrowthStage", 0)
	plot:SetAttribute("PlantedAt", nil)
	plot:SetAttribute("ReadyToHarvest", false)
	data.Prompt.ActionText = "PLANTER"
	data.Prompt.Enabled = true
	self:_setVisual(plot, data, 0)
end

function CropService:RegisterPlot(plot)
	if self._plots[plot] then
		return true
	end
	local plantPoint = findPlantPoint(plot)
	local plantCFrame = plantPoint and getPlantCFrame(plantPoint)
	if not plantCFrame then
		warn("[MAYDEAD] GardenPlot PlantPoint missing or invalid")
		return false
	end
	print("[MAYDEAD] GardenPlot PlantPoint = " .. plantPoint:GetFullName() .. " (" .. plantPoint.ClassName .. ")")
	local promptParent = plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart", true)
	if not promptParent then
		return false
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GardenPlotPrompt"
	prompt.ActionText = "PLANTER"
	prompt.ObjectText = "POTAGER"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptParent
	local data = {PlantPoint = plantPoint, Prompt = prompt, PlantedAt = nil, Stage = 0, Ready = false, Visual = nil}
	self._plots[plot] = data
	plot:SetAttribute("GrowthStage", 0)
	plot:SetAttribute("ReadyToHarvest", false)
	prompt.Triggered:Connect(function(player)
		if player:GetAttribute("SessionStarted") ~= true then return end
		if data.Ready then
			self:_harvest(player, plot, data)
		else
			self:_plant(player, plot, data)
		end
	end)
	return true
end

function CropService:GetPersistentState(plot)
	local data = self._plots[plot]
	if not data then
		return nil, "PlotNotRegistered"
	end
	if not data.PlantedAt then
		return {StateVersion = 1, CropType = nil, GrowthElapsed = 0}
	end
	return {
		StateVersion = 1,
		CropType = CROP_TYPE,
		GrowthElapsed = math.clamp(workspace:GetServerTimeNow() - data.PlantedAt, 0, READY_TIME),
	}
end

function CropService:RestorePersistentState(plot, state)
	local data = self._plots[plot]
	if not data or typeof(state) ~= "table" or state.StateVersion ~= 1 then
		return false, "InvalidCropState"
	end
	if state.CropType == nil then
		if state.GrowthElapsed ~= 0 then return false, "InvalidEmptyCropState" end
		data.PlantedAt = nil
		data.Stage = 0
		data.Ready = false
		plot:SetAttribute("CropType", nil)
		plot:SetAttribute("GrowthStage", 0)
		plot:SetAttribute("PlantedAt", nil)
		plot:SetAttribute("ReadyToHarvest", false)
		data.Prompt.ActionText = "PLANTER"
		data.Prompt.Enabled = true
		self:_setVisual(plot, data, 0)
		return true
	end
	local elapsed = state.GrowthElapsed
	if state.CropType ~= CROP_TYPE or typeof(elapsed) ~= "number" or elapsed ~= elapsed
		or elapsed < 0 or elapsed > READY_TIME
	then
		return false, "InvalidCropProgress"
	end
	local now = workspace:GetServerTimeNow()
	data.PlantedAt = now - elapsed
	data.Stage = math.clamp(math.floor(elapsed / STAGE_INTERVAL) + 1, 1, 4)
	data.Ready = elapsed >= READY_TIME
	plot:SetAttribute("CropType", CROP_TYPE)
	plot:SetAttribute("GrowthStage", data.Stage)
	plot:SetAttribute("PlantedAt", data.PlantedAt)
	plot:SetAttribute("ReadyToHarvest", data.Ready)
	data.Prompt.ActionText = data.Ready and "RÉCOLTER" or "CROISSANCE"
	data.Prompt.Enabled = data.Ready
	self:_setVisual(plot, data, data.Stage)
	return true
end

function CropService:Start()
	task.spawn(function()
		while true do
			task.wait(1)
			local now = workspace:GetServerTimeNow()
			for plot, data in self._plots do
				if plot:IsDescendantOf(workspace) then
					self:_updatePlot(plot, data, now)
				else
					self._plots[plot] = nil
				end
			end
		end
	end)
end

return CropService.new()
