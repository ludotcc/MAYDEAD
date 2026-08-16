local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local DEPENDENCY_TIMEOUT = 5
local DRAG_THRESHOLD_PIXELS = 6
local LONG_PRESS_DURATION = 0.45
local SLOT_COLUMNS = 5
local STATION_FRAME_SIZE = Vector2.new(920, 560)
local INVENTORY_FRAME_SIZE = Vector2.new(404, 498)

local function requireChild(parent, childName)
	local child = parent:WaitForChild(childName, DEPENDENCY_TIMEOUT)
	if not child then
		error("[MAYDEAD] StationController dependency timed out: " .. childName, 0)
	end
	return child
end

local SharedFolder = requireChild(ReplicatedStorage, "Shared")
local ItemDefinitions = require(requireChild(requireChild(SharedFolder, "Definitions"), "ItemDefinitions"))
local ItemIconConfig = require(requireChild(requireChild(SharedFolder, "Config"), "ItemIconConfig"))
local InventoryConfig = require(requireChild(requireChild(SharedFolder, "Config"), "InventoryConfig"))
local StationConfig = require(requireChild(requireChild(SharedFolder, "Config"), "StationConfig"))
local inventoryControllerModule = script.Parent:FindFirstChild("InventoryController")
	or script.Parent:FindFirstChild("InventoryController.module")
if not inventoryControllerModule or not inventoryControllerModule:IsA("ModuleScript") then
	error("[MAYDEAD] StationController dependency missing: InventoryController.module", 0)
end
local InventoryController = require(inventoryControllerModule)
local InventoryDragGhost = require(script.Parent:WaitForChild("InventoryDragGhost.module"))

local inventoryRemote = requireChild(ReplicatedStorage, "InventoryStateChanged")
local stationOpened = requireChild(ReplicatedStorage, "StationOpened")
local stationStateChanged = requireChild(ReplicatedStorage, "StationStateChanged")
local stationRequest = requireChild(ReplicatedStorage, "StationRequest")
local finalFactoryStateChanged = requireChild(ReplicatedStorage, "FinalFactoryStateChanged")
local finalFactoryRequest = requireChild(ReplicatedStorage, "FinalFactoryRequest")

local controller = {
	Started = false,
	Inventory = nil,
	Station = nil,
	State = nil,
	FinalFactoryState = nil,
	DragGhost = nil,
	DragState = nil,
	TouchHalfButton = nil,
	TouchHalfTransfer = nil,
	TouchHalfRevision = 0,
	SlotComponents = {},
	DropZones = {},
	FeedbackComponent = nil,
	CanAssemble = false,
	LastFactoryButtonDebugState = nil,
}

local function getStationInteractionPosition(station)
	local interactionPoint = station:FindFirstChild("InteractionPoint", true)
	if interactionPoint then
		if interactionPoint:IsA("Attachment") then return interactionPoint.WorldPosition end
		if interactionPoint:IsA("BasePart") then return interactionPoint.Position end
	end
	return station:GetPivot().Position
end

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function setBaseInventoryVisible(visible)
	local mainFrame = InventoryController.MainFrame
	for _, name in ipairs({"DayAgePanel", "InventoryFrame", "QuickAccessTitle", "QuickAccessHelp", "QuickAccessSlots"}) do
		local child = mainFrame and mainFrame:FindFirstChild(name)
		if child then
			child.Visible = visible
		end
	end
	local craftPanel = mainFrame and mainFrame:FindFirstChild("CraftPanel")
	if craftPanel and visible then
		craftPanel.Visible = false
	end
end

local function setMainFrameMode(stationMode)
	local mainFrame = InventoryController.MainFrame
	if not mainFrame then return end
	local size = stationMode and STATION_FRAME_SIZE or INVENTORY_FRAME_SIZE
	mainFrame.Size = UDim2.fromOffset(size.X, size.Y)
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local minimumScale = stationMode and 0.32 or 0.5
	local scale = math.clamp(math.min((viewport.X - 32) / size.X, (viewport.Y - 48) / size.Y), minimumScale, 1)
	if InventoryController.ScaleTween then InventoryController.ScaleTween:Cancel() end
	InventoryController.PanelTargetScale = scale
	local panelScale = mainFrame:FindFirstChild("PanelScale")
	if panelScale and panelScale:IsA("UIScale") then panelScale.Scale = scale end
end

local function clearContainer(container)
	for _, child in container:GetChildren() do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end
end

local function setFactoryControlsVisible(self, visible)
	-- These controls belong to the FinalFactory layout, not to ordinary stations.
	-- The nil checks keep an already-open legacy Studio UI safe during a Rojo hot reload.
	for _, controlName in ipairs({
		"FactoryAssembleButton",
		"FactoryPlaneImage",
		"FactoryProgressTitle",
		"FactoryProgressTrack",
	}) do
		local control = self[controlName]
		if control then
			control.Visible = visible
		end
	end
end

local function createGridLayout(parent, columns)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(60, 60)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.FillDirectionMaxCells = columns
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
end

local function isPointInside(gui, position)
	local origin, size = gui.AbsolutePosition, gui.AbsoluteSize
	return position.X >= origin.X and position.Y >= origin.Y
		and position.X <= origin.X + size.X and position.Y <= origin.Y + size.Y
end

local function getInputPosition(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	return UserInputService:GetMouseLocation()
end

local function addSlotVisual(button, slot)
	local itemId = slot and slot.ItemId
	local quantity = slot and slot.Quantity or 0
	local iconId = itemId and ItemIconConfig[itemId]
	if iconId then
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(1, -10, 1, -10)
		icon.Position = UDim2.fromOffset(5, 5)
		icon.BackgroundTransparency = 1
		icon.Image = iconId
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = button.ZIndex + 1
		icon.Parent = button
	elseif itemId then
		local fallback = Instance.new("TextLabel")
		fallback.Size = UDim2.fromScale(1, 1)
		fallback.BackgroundTransparency = 1
		fallback.Text = string.upper(string.sub((ItemDefinitions[itemId] and ItemDefinitions[itemId].DisplayName) or itemId, 1, 2))
		fallback.TextColor3 = Color3.fromRGB(194, 207, 223)
		fallback.Font = Enum.Font.GothamBold
		fallback.TextSize = 14
		fallback.ZIndex = button.ZIndex + 1
		fallback.Parent = button
	end
	local count = Instance.new("TextLabel")
	count.Name = "SlotQuantity"
	count.Size = UDim2.fromOffset(38, 16)
	count.Position = UDim2.new(1, -4, 1, -3)
	count.AnchorPoint = Vector2.new(1, 1)
	count.BackgroundTransparency = 1
	count.Text = quantity > 1 and ("x" .. quantity) or ""
	count.TextColor3 = Color3.fromRGB(245, 247, 250)
	count.TextStrokeTransparency = 0.35
	count.Font = Enum.Font.GothamBold
	count.TextSize = 10
	count.TextXAlignment = Enum.TextXAlignment.Right
	count.ZIndex = button.ZIndex + 2
	count.Parent = button
end

function controller:_decorateFactorySlot(button, slot, slotIndex)
	local expectedItemId = slotIndex == 1 and "MetalPanelStack" or "PlasticPanelStack"
	local finalState = self.FinalFactoryState
	local required = slotIndex == 1
		and (finalState and finalState.RequiredMetalPanelStack or 40)
		or (finalState and finalState.RequiredPlasticPanelStack or 30)
	local quantity = slot and slot.Quantity or 0
	if not slot or not slot.ItemId then
		local placeholder = Instance.new("ImageLabel")
		placeholder.Name = "ExpectedItemIcon"
		placeholder.Size = UDim2.new(1, -16, 1, -16)
		placeholder.Position = UDim2.fromOffset(8, 8)
		placeholder.BackgroundTransparency = 1
		placeholder.Image = ItemIconConfig[expectedItemId]
		placeholder.ImageTransparency = 0.42
		placeholder.ScaleType = Enum.ScaleType.Fit
		placeholder.ZIndex = button.ZIndex + 1
		placeholder.Parent = button
	end
	local itemLabel = Instance.new("TextLabel")
	itemLabel.Name = "ExpectedItemLabel"
	itemLabel.Size = UDim2.new(1, -8, 0, 14)
	itemLabel.Position = UDim2.fromOffset(4, 3)
	itemLabel.BackgroundTransparency = 1
	itemLabel.Text = slotIndex == 1 and "MÉTAL" or "PLASTIQUE"
	itemLabel.TextColor3 = Color3.fromRGB(205, 220, 232)
	itemLabel.TextStrokeTransparency = 0.35
	itemLabel.Font = Enum.Font.GothamBold
	itemLabel.TextSize = 8
	itemLabel.ZIndex = button.ZIndex + 3
	itemLabel.Parent = button
	local count = button:FindFirstChild("SlotQuantity")
	if count and count:IsA("TextLabel") then
		count.Size = UDim2.new(1, -8, 0, 18)
		count.Position = UDim2.new(1, -4, 1, -3)
		count.Text = string.format("%d / %d", quantity, required)
		count.TextColor3 = quantity >= required and Color3.fromRGB(74, 205, 180) or Color3.fromRGB(245, 247, 250)
		count.TextSize = 11
	end
end

function controller:_updateFactoryAssembleButton(finalState)
	local metal = finalState and finalState.MetalPanelStack or 0
	local plastic = finalState and finalState.PlasticPanelStack or 0
	local buildState = finalState and finalState.BuildState or "Unavailable"
	local completed = finalState and (finalState.Completed == true or buildState == "Completed") or false
	local requiredMetal = finalState and finalState.RequiredMetalPanelStack or 40
	local requiredPlastic = finalState and finalState.RequiredPlasticPanelStack or 30
	local canAssemble = finalState ~= nil
		and buildState == "Idle"
		and not completed
		and metal >= requiredMetal
		and plastic >= requiredPlastic

	self.CanAssemble = canAssemble
	local button = self.FactoryAssembleButton
	if not button then
		return
	end
	button.Active = canAssemble
	button.Interactable = canAssemble
	button.Selectable = canAssemble
	button.AutoButtonColor = canAssemble
	button.BackgroundColor3 = canAssemble and Color3.fromRGB(0, 174, 210) or Color3.fromRGB(54, 66, 78)
	button.Text = completed and "NAVAL SEAPLANE TERMINÉ"
		or buildState == "Building" and "ASSEMBLAGE EN COURS"
		or "ASSEMBLER"

	if RunService:IsStudio() then
		local debugState = string.format("%d|%d|%s|%s|%s", metal, plastic, buildState, tostring(completed), tostring(canAssemble))
		if debugState ~= self.LastFactoryButtonDebugState then
			self.LastFactoryButtonDebugState = debugState
			print(string.format(
				"[MAYDEAD][FINAL_FACTORY][BUTTON] Metal=%d Plastic=%d State=%s Completed=%s CanAssemble=%s",
				metal, plastic, buildState, tostring(completed), tostring(canAssemble)
			))
		end
	end
end

local function isShiftDown()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
end

local function slotAcceptsItem(slot, itemId)
	if not slot or not slot.ItemId then
		return true
	end
	local definition = ItemDefinitions[itemId]
	return definition ~= nil and slot.ItemId == itemId and slot.Quantity < definition.MaxStack
end

function controller:_setComponentFeedback(component, color)
	if self.FeedbackComponent and self.FeedbackComponent ~= component then
		self.FeedbackComponent.Stroke.Color = Color3.fromRGB(55, 68, 82)
		self.FeedbackComponent.Stroke.Thickness = 1
	end
	self.FeedbackComponent = component
	if component then
		component.Stroke.Color = color
		component.Stroke.Thickness = 2
	end
end

function controller:_cancelDrag()
	if self.DragState and self.DragState.ProgressTween then
		self.DragState.ProgressTween:Cancel()
	end
	if self.DragGhost then
		self.DragGhost:Destroy()
		self.DragGhost = nil
	end
	if self.DragState and self.DragState.Source then
		self.DragState.Source.Stroke.Color = Color3.fromRGB(55, 68, 82)
		self.DragState.Source.Stroke.Transparency = 0.2
		self.DragState.Source.Stroke.Thickness = 1
	end
	self:_setComponentFeedback(nil, Color3.new())
	self.DragState = nil
end

function controller:_hideTouchHalfAction()
	self.TouchHalfRevision += 1
	self.TouchHalfTransfer = nil
	if self.TouchHalfButton then self.TouchHalfButton.Visible = false end
end

function controller:_showTouchHalfAction(drag, position)
	if not UserInputService.TouchEnabled or not self.Panel.Visible then return end
	if not self.TouchHalfButton then
		local button = Instance.new("TextButton")
		button.Name = "TouchHalfStackButton"
		button.Size = UDim2.fromOffset(132, 44)
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.BackgroundColor3 = Color3.fromRGB(25, 91, 108)
		button.AutoButtonColor = true
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.Text = "½ PILE"
		button.TextColor3 = Color3.fromRGB(231, 239, 244)
		button.TextSize = 13
		button.Visible = false
		button.ZIndex = 40
		button.Parent = InventoryController.ScreenGui
		addCorner(button, 10)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(79, 178, 194)
		stroke.Transparency = 0.15
		stroke.Thickness = 1.5
		stroke.Parent = button
		button.Activated:Connect(function()
			local transfer = self.TouchHalfTransfer
			self:_hideTouchHalfAction()
			if transfer and self.Panel.Visible then transfer.Callback("HALF_STACK", nil, transfer.DestinationArea) end
		end)
		self.TouchHalfButton = button
	end
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	self.TouchHalfButton.Position = UDim2.fromOffset(
		math.clamp(position.X, 78, viewport.X - 78),
		math.clamp(position.Y + 54, 28, viewport.Y - 28)
	)
	self.TouchHalfTransfer = drag
	self.TouchHalfButton.Visible = true
	self.TouchHalfRevision += 1
	local revision = self.TouchHalfRevision
	task.delay(2.5, function()
		if self.TouchHalfRevision == revision then self:_hideTouchHalfAction() end
	end)
end

function controller:_createDragGhost(slot, position)
	local ghost = InventoryDragGhost.Create(InventoryController.ScreenGui, slot, addSlotVisual)
	ghost.Position = UDim2.fromOffset(position.X, position.Y)
	self.DragGhost = ghost
end

function controller:_resolveDrop(position)
	local drag = self.DragState
	if not drag then return nil, false end
	for _, component in self.SlotComponents do
		if component.InventoryId ~= drag.Source.InventoryId and isPointInside(component.Button, position) then
			local zoneAllowed = drag.Source.InventoryId == "Station" or component.Area == drag.DestinationArea
			return component, zoneAllowed and slotAcceptsItem(component.Slot, drag.ItemId)
		end
	end
	for _, zone in self.DropZones do
		if zone.InventoryId ~= drag.Source.InventoryId and isPointInside(zone.Container, position) then
			local allowed = drag.Source.InventoryId == "Station" or zone.Area == drag.DestinationArea
			return zone, allowed
		end
	end
	return nil, false
end

function controller:_updateDrag(position)
	local drag = self.DragState
	if not drag then return end
	local dragThreshold = drag.IsTouch and InventoryConfig.MOBILE_SLOT_MOVE_TOLERANCE or DRAG_THRESHOLD_PIXELS
	if not self.DragGhost and (position - drag.StartPosition).Magnitude >= dragThreshold then
		drag.LongPressCancelled = true
		self:_createDragGhost(drag.Slot, position)
		drag.Source.Stroke.Color = Color3.fromRGB(205, 174, 124)
		drag.Source.Stroke.Thickness = 2
	end
	if not self.DragGhost then return end
	self.DragGhost.Position = UDim2.fromOffset(position.X, position.Y)
	local target, valid = self:_resolveDrop(position)
	self:_setComponentFeedback(target and target.Stroke and target or nil, valid and Color3.fromRGB(83, 181, 126) or Color3.fromRGB(198, 79, 79))
	self.DragGhost.BackgroundColor3 = valid and Color3.fromRGB(39, 88, 65) or Color3.fromRGB(92, 42, 45)
end

function controller:_finishDrag(position)
	local drag = self.DragState
	if not drag then return end
	local target, valid = self:_resolveDrop(position)
	local showTouchHalfAction = drag.IsTouch and drag.DestinationArea ~= nil and drag.Slot.Quantity >= 2
		and not self.DragGhost and not drag.LongPressTriggered and not drag.LongPressCancelled
	if self.DragGhost and valid then
		drag.Callback("SINGLE", target.SlotIndex, target.Area)
	end
	self:_cancelDrag()
	if showTouchHalfAction then self:_showTouchHalfAction(drag, position) end
end

function controller:_createSlotCard(parent, slot, inventoryId, slotIndex, area, destinationArea, callback)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = slot and slot.ItemId and Color3.fromRGB(30, 42, 54) or Color3.fromRGB(22, 27, 34)
	button.BackgroundTransparency = 0.06
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = slot ~= nil and slot.ItemId ~= nil
	button.Active = true
	button.Parent = parent
	addCorner(button, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(55, 68, 82)
	stroke.Transparency = 0.2
	stroke.Thickness = 1
	stroke.Parent = button
	addSlotVisual(button, slot)
	local component = {Button = button, Stroke = stroke, Slot = slot, InventoryId = inventoryId, SlotIndex = slotIndex, Area = area}
	table.insert(self.SlotComponents, component)
	button.MouseEnter:Connect(function()
		component.Hovered = true
		if not self.DragState then
			stroke.Color = Color3.fromRGB(112, 135, 158)
		end
	end)
	button.MouseLeave:Connect(function()
		component.Hovered = false
		if self.DragState and self.DragState.Source == component then
			self.DragState.LongPressCancelled = true
		end
		if not self.DragState then
			stroke.Color = Color3.fromRGB(55, 68, 82)
		end
	end)
	if not slot or not slot.ItemId then return button end
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			if isShiftDown() then callback("HALF_STACK", nil, destinationArea) end
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isShiftDown() then
			callback("FULL_STACK", nil, destinationArea)
			return
		end
		self:_hideTouchHalfAction()
		self:_cancelDrag()
		local dragState = {
			Source = component,
			Slot = slot,
			ItemId = slot.ItemId,
			StartPosition = getInputPosition(input),
			Input = input,
			DestinationArea = destinationArea,
			Callback = callback,
			IsTouch = input.UserInputType == Enum.UserInputType.Touch,
			LongPressCancelled = false,
		}
		self.DragState = dragState
		local longPressDuration = dragState.IsTouch and InventoryConfig.MOBILE_SLOT_LONG_PRESS_TIME or LONG_PRESS_DURATION
		if dragState.IsTouch then
			dragState.ProgressTween = TweenService:Create(
				stroke,
				TweenInfo.new(longPressDuration, Enum.EasingStyle.Linear),
				{Color = Color3.fromRGB(74, 205, 226), Transparency = 0.02, Thickness = 3}
			)
			dragState.ProgressTween:Play()
		end
		task.delay(longPressDuration, function()
				if self.DragState ~= dragState or dragState.LongPressCancelled or self.DragGhost
					or not self.Panel.Visible or (not dragState.IsTouch and not component.Hovered)
				then
					return
				end
				local currentSlot = component.InventoryId == "Player"
					and self.Inventory and self.Inventory.Slots[component.SlotIndex]
					or component.Slot
				if not currentSlot or currentSlot.ItemId ~= dragState.ItemId or currentSlot.Quantity <= 0 then return end
				dragState.LongPressTriggered = true
				self:_cancelDrag()
				callback("FULL_STACK", nil, destinationArea)
			end)
		input:GetPropertyChangedSignal("UserInputState"):Connect(function()
			if self.DragState == dragState and input.UserInputState == Enum.UserInputState.Cancel then
				dragState.LongPressCancelled = true
				self:_cancelDrag()
			end
		end)
	end)
	return button
end

function controller:_canDeposit(itemId)
	if not self.State then
		return false, nil
	end
	if self.State.StationType == "CraftingTable" then
		local definition = ItemDefinitions[itemId]
		return definition ~= nil and definition.Category == "Resource", "Storage"
	elseif self.State.StationType == "Chest" then
		return ItemDefinitions[itemId] ~= nil, "Storage"
	elseif self.State.StationType == "AutomaticLoader" then
		return itemId == "MetalWaste" or itemId == "PlasticWaste" or itemId == "WasteBag", "Storage"
	elseif self.State.StationType == "Factory" then
		return itemId == "MetalPanelStack" or itemId == "PlasticPanelStack", "Storage"
	elseif self.State.StationType == "Smelt" then
		if itemId == "Wood" then return true, "Fuel" end
		if itemId == "CopperOre" or itemId == "RawMetal" or itemId == "GoldOre" then return true, "Input" end
		return false, nil
	elseif itemId == "Wood" then
		return true, "Fuel"
	elseif StationConfig.CAMPFIRE_RECIPES[itemId] ~= nil then
		return true, "Cooking"
	end
	return false, nil
end

function controller:_renderPlayerInventory()
	clearContainer(self.PlayerList)
	createGridLayout(self.PlayerList, SLOT_COLUMNS)
	for slotIndex = 1, InventoryConfig.MAIN_SLOT_COUNT + InventoryConfig.QUICK_SLOT_COUNT do
		local slot = self.Inventory and self.Inventory.Slots[slotIndex]
		local allowed, area = false, nil
		if slot and slot.ItemId then allowed, area = self:_canDeposit(slot.ItemId) end
		local card = self:_createSlotCard(self.PlayerList, slot, "Player", slotIndex, "Player", area, function(mode, targetSlotIndex, targetArea)
			if allowed then
				local stationSlotIndex = self.State and self.State.StationType == "Factory" and nil or targetSlotIndex
				if self.State and self.State.StationType == "Factory" and RunService:IsStudio() then
					local quantity = mode == "FULL_STACK" and slot.Quantity
						or mode == "HALF_STACK" and math.floor(slot.Quantity / 2)
						or 1
					print(string.format(
						"[MAYDEAD][FINAL_FACTORY][TRANSFER] Action=Request Direction=PlayerToFactory StructureId=%s ItemId=%s Quantity=%d",
						tostring(self.State.StructureId or self.Station:GetAttribute("StructureId")),
						tostring(slot.ItemId),
						quantity
					))
				end
					stationRequest:FireServer("TransferToStation", self.Station, {
						PlayerSlotIndex = slotIndex,
						StationSlotIndex = stationSlotIndex,
						Area = targetArea or area,
						Mode = mode,
					})
			end
		end)
		if slotIndex > InventoryConfig.MAIN_SLOT_COUNT then
			local stroke = card:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = Color3.fromRGB(132, 103, 62) end
		end
	end
end

function controller:_renderStationArea(container, title, area, slots)
	clearContainer(container)
	createGridLayout(container, SLOT_COLUMNS)
	local layout = container:FindFirstChildOfClass("UIGridLayout")
	if self.State and self.State.StationType == "Factory" and area == "Storage" and layout then
		layout.CellSize = UDim2.fromOffset(80, 80)
		layout.CellPadding = UDim2.fromOffset(14, 8)
		layout.FillDirectionMaxCells = 2
	end
	container:SetAttribute("AreaTitle", title)
	table.insert(self.DropZones, {
		Container = container,
		Stroke = container:FindFirstChildOfClass("UIStroke"),
		InventoryId = "Station",
		Area = area,
	})
	for index, slot in ipairs(slots or {}) do
		local card = self:_createSlotCard(container, slot, "Station", index, area, "Player", function(mode, targetSlotIndex)
			stationRequest:FireServer("TransferToPlayer", self.Station, {
				StationSlotIndex = index,
				PlayerSlotIndex = targetSlotIndex,
				Area = area,
				Mode = mode,
			})
		end)
		if self.State and self.State.StationType == "Factory" and area == "Storage" then
			self:_decorateFactorySlot(card, slot, index)
		end
	end
end

function controller:_render()
	if not self.State or not self.Panel.Visible then
		return
	end
	self:_hideTouchHalfAction()
	self:_cancelDrag()
	self.SlotComponents = {}
	self.DropZones = {{
		Container = self.PlayerList,
		Stroke = self.PlayerList:FindFirstChildOfClass("UIStroke"),
		InventoryId = "Player",
		Area = "Player",
	}}
	self:_renderPlayerInventory()
	if self.State.StationType == "CraftingTable" or self.State.StationType == "Chest" or self.State.StationType == "AutomaticLoader" or self.State.StationType == "Factory" then
		local isChest = self.State.StationType == "Chest"
		local isLoader = self.State.StationType == "AutomaticLoader"
		local isFactory = self.State.StationType == "Factory"
		self.StationTitle.Text = isFactory and "FACTORY" or (isLoader and "CHARGEUR AUTOMATIQUE" or (isChest and "COFFRE" or "TABLE DE CRAFT"))
		self.PrimaryTitle.Text = isFactory and "ASSEMBLAGE NAVAL SEAPLANE" or ((isChest or isLoader) and "STOCKAGE  •  30 SLOTS" or "RESSOURCES  •  12 SLOTS")
		local finalState = self.FinalFactoryState
		self.Status.Text = isFactory and string.format(
			"MÉTAL %d / 40  •  PLASTIQUE %d / 30  •  PROGRESSION %d%%",
			finalState and finalState.MetalPanelStack or 0,
			finalState and finalState.PlasticPanelStack or 0,
			math.floor(((finalState and finalState.Progress) or 0) * 100 + 0.5)
		) or (isLoader and "DÉCHETS UNIQUEMENT" or (isChest and "COFFRE  •  30 SLOTS" or "STOCK TABLE  •  12 SLOTS"))
		self.PrimaryArea.Size = isFactory and UDim2.new(0.48, 0, 0, 112) or UDim2.new(0.48, 0, 1, -90)
		self.PrimaryArea.Position = UDim2.new(0.52, 0, 0, isFactory and 170 or 70)
		self:_renderStationArea(self.PrimaryArea, isFactory and "INVENTAIRE FACTORY" or (isLoader and "ENTRÉE CHARGEUR" or (isChest and "COFFRE" or "INVENTAIRE TABLE")), "Storage", self.State.Slots)
		self.SecondaryArea.Visible = false
		self.SecondaryTitle.Visible = false
		self.TertiaryArea.Visible = false
		self.TertiaryTitle.Visible = false
		if isFactory then
			setFactoryControlsVisible(self, true)
			local progress = math.clamp((finalState and finalState.Progress) or 0, 0, 1)
			local progressPercent = math.floor(progress * 100 + 0.5)
			self.FactoryProgressFill.Size = UDim2.fromScale(progress, 1)
			self.FactoryProgressText.Text = string.format("%d %%", progressPercent)
			self.FactoryProgressTitle.Text = finalState and finalState.BuildState == "Completed" and "PROGRESSION  •  TERMINÉ"
				or finalState and finalState.BuildState == "Building" and string.format("PROGRESSION  •  %.0f s RESTANTES", finalState.Remaining or 0)
				or "PROGRESSION"
			self:_updateFactoryAssembleButton(finalState)
		else
			self.CanAssemble = false
			setFactoryControlsVisible(self, false)
		end
	elseif self.State.StationType == "Smelt" then
		setFactoryControlsVisible(self, false)
		self.StationTitle.Text = "FOUR DE FONTE"
		self.PrimaryTitle.Text = "MINERAI  •  4 SLOTS"
		self.SecondaryTitle.Text = "COMBUSTIBLE  •  BOIS"
		self.TertiaryTitle.Text = "SORTIE  •  4 SLOTS"
		local duration = self.State.ProgressDuration or 0
		local percent = duration > 0 and math.floor(math.clamp((self.State.ProgressElapsed or 0) / duration, 0, 1) * 100) or 0
		self.Status.Text = (self.State.Status or "ÉTEINT") .. "  •  FONTE " .. percent .. "%"
		self.PrimaryArea.Size = UDim2.new(0.48, 0, 0, 76)
		self.SecondaryArea.Position = UDim2.new(0.52, 0, 0, 190)
		self.SecondaryArea.Size = UDim2.new(0.48, 0, 0, 76)
		self.SecondaryTitle.Position = UDim2.new(0.52, 0, 0, 168)
		self.SecondaryArea.Visible = true; self.SecondaryTitle.Visible = true
		self.TertiaryArea.Visible = true; self.TertiaryTitle.Visible = true
		self:_renderStationArea(self.PrimaryArea, "MINERAI", "Input", self.State.InputSlots)
		self:_renderStationArea(self.SecondaryArea, "COMBUSTIBLE", "Fuel", self.State.FuelSlots)
		self:_renderStationArea(self.TertiaryArea, "SORTIE", "Output", self.State.OutputSlots)
	else
		setFactoryControlsVisible(self, false)
		self.StationTitle.Text = "CAMPFIRE"
		self.PrimaryTitle.Text = "COMBUSTIBLE  •  BOIS"
		self.SecondaryTitle.Text = "CUISSON / SORTIE  •  ALIMENTS"
		local percent = math.floor(math.clamp((self.State.CookProgress or 0) / self.State.CookDuration, 0, 1) * 100)
		self.Status.Text = (self.State.IsLit and "ACTIF" or "ÉTEINT") .. "  •  CUISSON " .. percent .. "%"
		self.PrimaryArea.Size = UDim2.new(0.48, 0, 0, 112)
		self.PrimaryArea.Position = UDim2.new(0.52, 0, 0, 70)
		self.SecondaryTitle.Position = UDim2.new(0.52, 0, 0, 216)
		self.SecondaryArea.Position = UDim2.new(0.52, 0, 0, 238)
		self.SecondaryArea.Size = UDim2.new(0.48, 0, 0, 112)
		self:_renderStationArea(self.PrimaryArea, "COMBUSTIBLE", "Fuel", self.State.FuelSlots)
		self.SecondaryArea.Visible = true
		self.SecondaryTitle.Visible = true
		self.TertiaryArea.Visible = false
		self.TertiaryTitle.Visible = false
		self:_renderStationArea(self.SecondaryArea, "CUISSON / SORTIE", "Cooking", self.State.CookingSlots)
	end
end

function controller:_showStation()
	if not self.Station or not self.State then
		return
	end
	setBaseInventoryVisible(false)
	setMainFrameMode(true)
	local craftPanel = InventoryController.MainFrame:FindFirstChild("CraftPanel")
	if craftPanel then
		craftPanel.Visible = false
	end
	local craftTabButton = InventoryController.MainFrame:FindFirstChild("CraftTabButton")
	if craftTabButton and craftTabButton:IsA("TextButton") then
		craftTabButton.Text = "FABRICATION"
	end
	self.Panel.Visible = true
	InventoryController.MainFrame.Title.Text = "INVENTAIRE"
	InventoryController.MainFrame.Subtitle.Visible = false
	self:_render()
end

function controller:_closeContext()
	self:_hideTouchHalfAction()
	self:_cancelDrag()
	if self.Station and self.State and self.State.StationType == "Factory" then finalFactoryRequest:FireServer("Close", self.Station) end
	self.Station = nil
	self.State = nil
	self.FinalFactoryState = nil
	self.Panel.Visible = false
	self.TabButton.Visible = false
	setMainFrameMode(false)
	setBaseInventoryVisible(true)
end

function controller:_build()
	local mainFrame = InventoryController.MainFrame
	local tabButton = Instance.new("TextButton")
	tabButton.Name = "StationTabButton"
	tabButton.Size = UDim2.fromOffset(92, 34)
	tabButton.Position = UDim2.new(1, -14, 0, 14)
	tabButton.AnchorPoint = Vector2.new(1, 0)
	tabButton.BackgroundColor3 = Color3.fromRGB(74, 56, 37)
	tabButton.BorderSizePixel = 0
	tabButton.Text = "STOCK"
	tabButton.TextColor3 = Color3.fromRGB(235, 221, 198)
	tabButton.Font = Enum.Font.GothamSemibold
	tabButton.TextSize = 10
	tabButton.Visible = false
	tabButton.ZIndex = 25
	tabButton.Parent = mainFrame
	addCorner(tabButton, 8)
	self.TabButton = tabButton

	local panel = Instance.new("Frame")
	panel.Name = "StationPanel"
	panel.Size = UDim2.new(1, -32, 1, -70)
	panel.Position = UDim2.fromOffset(16, 55)
	panel.BackgroundTransparency = 1
	panel.Visible = false
	panel.Parent = mainFrame
	self.Panel = panel

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, 0, 0, 22)
	status.BackgroundTransparency = 1
	status.TextColor3 = Color3.fromRGB(205, 174, 124)
	status.Font = Enum.Font.GothamBold
	status.TextSize = 11
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = panel
	self.Status = status

	local playerTitle = Instance.new("TextLabel")
	playerTitle.Size = UDim2.new(0.48, 0, 0, 20)
	playerTitle.Position = UDim2.fromOffset(0, 26)
	playerTitle.BackgroundTransparency = 1
	playerTitle.Text = "INVENTAIRE JOUEUR  •  20 + 8 SLOTS"
	playerTitle.TextColor3 = Color3.fromRGB(170, 184, 201)
	playerTitle.Font = Enum.Font.GothamBold
	playerTitle.TextSize = 10
	playerTitle.TextXAlignment = Enum.TextXAlignment.Left
	playerTitle.Parent = panel

	local stationTitle = playerTitle:Clone()
	stationTitle.Position = UDim2.new(0.52, 0, 0, 26)
	stationTitle.Text = "STOCK"
	stationTitle.Parent = panel
	self.StationTitle = stationTitle

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(0, 1, 1, -30)
	divider.Position = UDim2.new(0.5, 0, 0, 30)
	divider.BackgroundColor3 = Color3.fromRGB(55, 68, 82)
	divider.BackgroundTransparency = 0.35
	divider.BorderSizePixel = 0
	divider.Parent = panel

	local primaryTitle = stationTitle:Clone()
	primaryTitle.Position = UDim2.new(0.52, 0, 0, 48)
	primaryTitle.TextColor3 = Color3.fromRGB(205, 174, 124)
	primaryTitle.Parent = panel
	self.PrimaryTitle = primaryTitle

	local secondaryTitle = primaryTitle:Clone()
	secondaryTitle.Position = UDim2.new(0.52, 0, 0, 216)
	secondaryTitle.Parent = panel
	self.SecondaryTitle = secondaryTitle

	local playerList = Instance.new("ScrollingFrame")
	playerList.Size = UDim2.new(0.48, 0, 1, -72)
	playerList.Position = UDim2.fromOffset(0, 52)
	playerList.BackgroundColor3 = Color3.fromRGB(15, 19, 24)
	playerList.BackgroundTransparency = 0.25
	playerList.BorderSizePixel = 0
	playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playerList.CanvasSize = UDim2.new()
	playerList.ScrollBarThickness = 3
	playerList.Parent = panel
	addCorner(playerList, 8)
	local playerStroke = Instance.new("UIStroke")
	playerStroke.Color = Color3.fromRGB(55, 68, 82)
	playerStroke.Transparency = 0.35
	playerStroke.Parent = playerList
	self.PlayerList = playerList

	local primary = Instance.new("ScrollingFrame")
	primary.Size = UDim2.new(0.48, 0, 0, 112)
	primary.Position = UDim2.new(0.52, 0, 0, 70)
	primary.BackgroundColor3 = Color3.fromRGB(15, 19, 24)
	primary.BackgroundTransparency = 0.25
	primary.BorderSizePixel = 0
	primary.AutomaticCanvasSize = Enum.AutomaticSize.Y
	primary.CanvasSize = UDim2.new()
	primary.ScrollBarThickness = 3
	primary.Parent = panel
	addCorner(primary, 8)
	local primaryStroke = playerStroke:Clone()
	primaryStroke.Parent = primary
	self.PrimaryArea = primary

	local secondary = Instance.new("ScrollingFrame")
	secondary.Size = UDim2.new(0.48, 0, 0, 112)
	secondary.Position = UDim2.new(0.52, 0, 0, 238)
	secondary.BackgroundColor3 = Color3.fromRGB(15, 19, 24)
	secondary.BackgroundTransparency = 0.25
	secondary.BorderSizePixel = 0
	secondary.AutomaticCanvasSize = Enum.AutomaticSize.Y
	secondary.CanvasSize = UDim2.new()
	secondary.ScrollBarThickness = 3
	secondary.Parent = panel
	addCorner(secondary, 8)
	local secondaryStroke = playerStroke:Clone()
	secondaryStroke.Parent = secondary
	self.SecondaryArea = secondary

	local tertiaryTitle = primaryTitle:Clone()
	tertiaryTitle.Position = UDim2.new(0.52, 0, 0, 282)
	tertiaryTitle.Text = "SORTIE"
	tertiaryTitle.Visible = false
	tertiaryTitle.Parent = panel
	self.TertiaryTitle = tertiaryTitle

	local tertiary = secondary:Clone()
	tertiary.Position = UDim2.new(0.52, 0, 0, 304)
	tertiary.Size = UDim2.new(0.48, 0, 0, 76)
	tertiary.Visible = false
	tertiary.Parent = panel
	self.TertiaryArea = tertiary

	local planeImage = Instance.new("ImageLabel")
	planeImage.Name = "FactoryNavalSeaplanePreview"
	planeImage.Size = UDim2.new(0.48, 0, 0, 94)
	planeImage.Position = UDim2.new(0.52, 0, 0, 68)
	planeImage.BackgroundTransparency = 1
	planeImage.Image = "rbxassetid://109820418000805"
	planeImage.ImageTransparency = 0
	planeImage.ScaleType = Enum.ScaleType.Fit
	planeImage.Visible = false
	planeImage.Parent = panel
	self.FactoryPlaneImage = planeImage

	local progressTitle = primaryTitle:Clone()
	progressTitle.Name = "FactoryProgressTitle"
	progressTitle.Position = UDim2.new(0.52, 0, 0, 282)
	progressTitle.Text = "PROGRESSION"
	progressTitle.Visible = false
	progressTitle.Parent = panel
	self.FactoryProgressTitle = progressTitle

	local progressTrack = Instance.new("Frame")
	progressTrack.Name = "FactoryProgressTrack"
	progressTrack.Size = UDim2.new(0.48, 0, 0, 28)
	progressTrack.Position = UDim2.new(0.52, 0, 0, 306)
	progressTrack.BackgroundColor3 = Color3.fromRGB(21, 30, 40)
	progressTrack.BorderSizePixel = 0
	progressTrack.ClipsDescendants = true
	progressTrack.Visible = false
	progressTrack.Parent = panel
	addCorner(progressTrack, 8)
	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(0, 174, 210)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressTrack
	addCorner(progressFill, 8)
	self.FactoryProgressFill = progressFill
	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressText"
	progressText.Size = UDim2.fromScale(1, 1)
	progressText.BackgroundTransparency = 1
	progressText.Text = "0 %"
	progressText.TextColor3 = Color3.fromRGB(245, 247, 250)
	progressText.TextStrokeTransparency = 0.55
	progressText.Font = Enum.Font.GothamBold
	progressText.TextSize = 11
	progressText.ZIndex = progressFill.ZIndex + 1
	progressText.Parent = progressTrack
	self.FactoryProgressText = progressText

	local assembleButton = Instance.new("TextButton")
	assembleButton.Name = "FactoryAssembleButton"
	assembleButton.Size = UDim2.new(0.48, 0, 0, 42)
	assembleButton.Position = UDim2.new(0.52, 0, 1, -48)
	assembleButton.BackgroundColor3 = Color3.fromRGB(54, 66, 78)
	assembleButton.BorderSizePixel = 0
	assembleButton.Text = "ASSEMBLER"
	assembleButton.TextColor3 = Color3.fromRGB(235, 244, 250)
	assembleButton.Font = Enum.Font.GothamBold
	assembleButton.TextSize = 13
	assembleButton.Visible = false
	assembleButton.Active = false
	assembleButton.Interactable = false
	assembleButton.Selectable = false
	assembleButton.ZIndex = 2
	assembleButton.Parent = panel
	addCorner(assembleButton, 9)
	assembleButton.Activated:Connect(function()
		if self.CanAssemble and self.Station and self.State and self.State.StationType == "Factory" then
			if RunService:IsStudio() then
				print(string.format("[MAYDEAD][FINAL_FACTORY][ASSEMBLE] Action=Click StructureId=%s", tostring(self.State.StructureId or self.Station:GetAttribute("StructureId"))))
			end
			finalFactoryRequest:FireServer("Assemble", self.Station)
		end
	end)
	self.FactoryAssembleButton = assembleButton

	tabButton.Activated:Connect(function()
		self:_showStation()
	end)
end

function controller:Start()
	if self.Started then
		return
	end
	self.Started = true
	self:_build()
	self.Inventory = InventoryController.Inventory
	UserInputService.InputChanged:Connect(function(input)
		if self.DragState and (input.UserInputType == Enum.UserInputType.MouseMovement or input == self.DragState.Input) then
			self:_updateDrag(getInputPosition(input))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if self.DragState and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == self.DragState.Input) then
			self:_finishDrag(getInputPosition(input))
		end
	end)

	inventoryRemote.OnClientEvent:Connect(function(state)
		self:_cancelDrag()
		self.Inventory = state
		self:_render()
	end)
	stationOpened.OnClientEvent:Connect(function(station, state)
		if state.StationType == "Factory" and RunService:IsStudio() then
			print(string.format(
				"[MAYDEAD][FINAL_FACTORY][UI] OpenRemoteReceived StructureId=%s",
				tostring(state.StructureId or station:GetAttribute("StructureId"))
			))
		end
		self.Station = station
		self.State = state
		self.TabButton.Visible = true
		InventoryController:SetOpen(true)
		if state.StationType == "Campfire" or state.StationType == "Chest" or state.StationType == "Smelt" or state.StationType == "Factory" then
			self:_showStation()
		end
		if state.StationType == "Factory" and RunService:IsStudio() then
			local button = self.FactoryAssembleButton
			print(string.format(
				"[MAYDEAD][FINAL_FACTORY][UI] Visible ScreenGui=%s MainFrame=%s StationPanel=%s",
				tostring(InventoryController.ScreenGui.Enabled),
				tostring(InventoryController.MainFrame.Visible),
				tostring(self.Panel.Visible)
			))
			print(string.format(
				"[MAYDEAD][FINAL_FACTORY][BUTTON] Exists=%s Class=%s Active=%s Interactable=%s Visible=%s AbsoluteSize=%s ZIndex=%s Parent=%s Bound=true",
				tostring(button ~= nil),
				button and button.ClassName or "nil",
				button and tostring(button.Active) or "nil",
				button and tostring(button.Interactable) or "nil",
				button and tostring(button.Visible) or "nil",
				button and tostring(button.AbsoluteSize) or "nil",
				button and tostring(button.ZIndex) or "nil",
				button and button.Parent and button.Parent:GetFullName() or "nil"
			))
		end
	end)
	stationStateChanged.OnClientEvent:Connect(function(station, state)
		if station == self.Station then
			self.State = state
			if self.DragState then return end
			self:_cancelDrag()
			self:_render()
		end
	end)
	finalFactoryStateChanged.OnClientEvent:Connect(function(station, state)
		if station == self.Station and self.State and self.State.StationType == "Factory" then
			self.FinalFactoryState = state
			self:_render()
		end
	end)
	InventoryController.OpenChanged.Event:Connect(function(open)
		if not open then
			self:_closeContext()
		end
	end)

	local rangeTimer = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		rangeTimer = rangeTimer + deltaTime
		if rangeTimer < 0.25 or not self.Station then
			return
		end
		rangeTimer = 0
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if not rootPart
			or not self.Station:IsDescendantOf(workspace)
			or (rootPart.Position - getStationInteractionPosition(self.Station)).Magnitude > StationConfig.INTERACTION_DISTANCE
		then
			InventoryController:SetOpen(false)
		end
	end)
	print("[MAYDEAD] StationController started")
end

return controller
