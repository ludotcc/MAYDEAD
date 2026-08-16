local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ItemDefinitions = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("ItemDefinitions"))
local ItemIconConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("ItemIconConfig"))
local FlaskConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("FlaskConfig"))
local InventoryConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("InventoryConfig"))
local inventoryRemote = ReplicatedStorage:WaitForChild("InventoryStateChanged")
local inventoryRequest = ReplicatedStorage:WaitForChild("InventoryRequest")
local survivalRemote = ReplicatedStorage:WaitForChild("SurvivalStateChanged")
local foodConsumed = ReplicatedStorage:WaitForChild("FoodConsumed")
local InventoryDragGhost = require(script.Parent:WaitForChild("InventoryDragGhost.module"))

local INVENTORY_INPUT_PRIORITY = Enum.ContextActionPriority.High.Value + 100
local INVENTORY_ACTION_NAME = "MAYDEAD_ToggleInventory"
local QUICK_SLOT_INPUT_PRIORITY = Enum.ContextActionPriority.High.Value + 50
local DRAG_THRESHOLD_PIXELS = 6
local QUICK_SLOT_COUNT = InventoryConfig.QUICK_SLOT_COUNT
local MAIN_SLOT_COUNT = InventoryConfig.MAIN_SLOT_COUNT
local QUICK_SLOT_KEYS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
}
local QUICK_SLOT_KEY_INDEX = {}
for slotIndex, keyCode in QUICK_SLOT_KEYS do
	QUICK_SLOT_KEY_INDEX[keyCode] = slotIndex
end

local controller = {}
controller.__index = controller

function controller.new()
	local self = setmetatable({}, controller)
	self.ScreenGui = nil
	self.Open = false
	self.Inventory = nil
	self.HotbarSlots = {}
	self.HotbarScale = nil
	self.InventoryQuickSlots = {}
	self.InventorySlots = {}
	self.SelectedInventoryIndex = nil
	self.DragState = nil
	self.DragGhost = nil
	self.DragFeedback = nil
	self.Hunger = 100
	self.ConsumePrompt = nil
	self.ConsumeFeedback = nil
	self.HoverTooltip = nil
	self.MainFrame = nil
	self.IsTouchDevice = false
	self.PanelTargetScale = 1
	self.BackgroundTween = nil
	self.ScaleTween = nil
	self.VisualTransitionId = 0
	self.LastToggleTime = 0
	self.InventoryInputBound = false
	self.PriorityPrompts = {}
	self.MobileButton = nil
	self.OpenChanged = Instance.new("BindableEvent")
	return self
end

function controller:SetHoverTooltip(slotData, quickIndex)
	if not self.HoverTooltip then return end
	local definition = slotData and slotData.ItemId and ItemDefinitions[slotData.ItemId]
	if not definition then self.HoverTooltip.Text = ""; return end
	local suffix = quickIndex and ("  •  ACCÈS RAPIDE " .. quickIndex) or ("  •  x" .. tostring(slotData.Quantity))
	self.HoverTooltip.Text = string.upper(definition.DisplayName or slotData.ItemId) .. suffix
end

local function inputPosition(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	return UserInputService:GetMouseLocation()
end

local function pointInside(gui, position)
	local origin, size = gui.AbsolutePosition, gui.AbsoluteSize
	return position.X >= origin.X and position.Y >= origin.Y
		and position.X <= origin.X + size.X and position.Y <= origin.Y + size.Y
end

local function getDropPositions(position)
	local topLeftInset, bottomRightInset = GuiService:GetGuiInset()
	return {
		position,
		position - topLeftInset,
		position + topLeftInset,
		position - bottomRightInset,
	}
end

local function guiBelongsTo(gui, ancestor)
	return gui == ancestor or gui:IsDescendantOf(ancestor)
end

local function isTouchDevice()
	if not UserInputService.TouchEnabled then return false end
	local ok, preferredInput = pcall(function() return UserInputService.PreferredInput end)
	return not ok or preferredInput == Enum.PreferredInput.Touch or not UserInputService.KeyboardEnabled
end

local function calculatePanelScale()
	local camera = workspace.CurrentCamera
	local viewportSize = camera and camera.ViewportSize
	if not viewportSize or viewportSize.X <= 32 or viewportSize.Y <= 48 then
		return 1
	end

	return math.clamp(math.min((viewportSize.X - 32) / 404, (viewportSize.Y - 48) / 498), 0.5, 1)
end

local function buildItemIcon(parent, imageAssetId)
	local icon = Instance.new("ImageLabel")
	icon.Name = "ItemIcon"
	icon.Size = UDim2.new(0.9, 0, 0.9, 0)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = imageAssetId
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 4
	icon.Parent = parent

	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = 1
	aspectRatio.DominantAxis = Enum.DominantAxis.Height
	aspectRatio.Parent = icon
end

local function buildItemFallback(parent, itemId)
	local definition = ItemDefinitions[itemId]
	local fallbackText = string.upper(string.sub(definition and definition.DisplayName or itemId, 1, 2))
	local label = Instance.new("TextLabel")
	label.Name = "ItemFallback"
	label.Size = UDim2.new(1, -4, 1, -4)
	label.Position = UDim2.fromOffset(2, 2)
	label.BackgroundTransparency = 1
	label.Text = fallbackText
	label.TextColor3 = Color3.fromRGB(194, 207, 223)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.ZIndex = 4
	label.Parent = parent
end

local function buildWaterChargeBadge(parent, slotData)
	if not slotData or slotData.ItemId ~= "Flask" then
		return
	end
	local charges = math.clamp(
		math.floor(slotData.WaterCharges or FlaskConfig.INITIAL_WATER_CHARGES),
		0,
		FlaskConfig.MAX_WATER_CHARGES
	)
	local badge = Instance.new("TextLabel")
	badge.Name = "WaterCharges"
	badge.Size = UDim2.fromOffset(25, 15)
	badge.Position = UDim2.new(1, -2, 1, -2)
	badge.AnchorPoint = Vector2.new(1, 1)
	badge.BackgroundColor3 = Color3.fromRGB(7, 13, 20)
	badge.BackgroundTransparency = 0.2
	badge.BorderSizePixel = 0
	badge.Text = tostring(charges) .. "/" .. tostring(FlaskConfig.MAX_WATER_CHARGES)
	badge.TextColor3 = Color3.fromRGB(220, 242, 250)
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 9
	badge.ZIndex = 8
	badge.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = badge
end

local function createQuickSlot(parent, slotIndex, size)
	local slot = Instance.new("TextButton")
	slot.Name = "QuickSlot" .. slotIndex
	slot.Size = UDim2.fromOffset(size, size)
	slot.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
	slot.BackgroundTransparency = 0.2
	slot.BorderSizePixel = 0
	slot.AutoButtonColor = false
	slot.Text = ""
	slot.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = slot

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(75, 87, 104)
	stroke.Transparency = 0.72
	stroke.Thickness = 1
	stroke.Parent = slot

	local scale = Instance.new("UIScale")
	scale.Name = "SelectionScale"
	scale.Scale = 1
	scale.Parent = slot

	local numberLabel = Instance.new("TextLabel")
	numberLabel.Name = "Number"
	numberLabel.Size = UDim2.fromOffset(16, 14)
	numberLabel.Position = UDim2.fromOffset(5, 3)
	numberLabel.BackgroundTransparency = 1
	numberLabel.Text = tostring(slotIndex)
	numberLabel.TextColor3 = Color3.fromRGB(142, 154, 170)
	numberLabel.Font = Enum.Font.GothamSemibold
	numberLabel.TextSize = 10
	numberLabel.TextXAlignment = Enum.TextXAlignment.Left
	numberLabel.ZIndex = 7
	numberLabel.Parent = slot

	local iconContainer = Instance.new("Frame")
	iconContainer.Name = "IconContainer"
	iconContainer.Size = UDim2.new(1, -10, 1, -10)
	iconContainer.Position = UDim2.fromOffset(5, 5)
	iconContainer.BackgroundTransparency = 1
	iconContainer.Parent = slot

	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.Size = UDim2.new(1, -10, 0, 14)
	countLabel.Position = UDim2.new(0, 5, 1, -4)
	countLabel.AnchorPoint = Vector2.new(0, 1)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = ""
	countLabel.TextColor3 = Color3.fromRGB(210, 218, 229)
	countLabel.Font = Enum.Font.GothamSemibold
	countLabel.TextSize = 10
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.ZIndex = 7
	countLabel.Parent = slot

	return {
		Frame = slot,
		Border = stroke,
		IconContainer = iconContainer,
		Count = countLabel,
		Number = numberLabel,
		Scale = scale,
	}
end

function controller:CancelInventoryDrag()
	if self.DragGhost then self.DragGhost:Destroy() end
	self.DragGhost = nil
	if self.DragFeedback then
		self.DragFeedback.Color = Color3.fromRGB(75, 87, 104)
		self.DragFeedback.Transparency = 0.72
	end
	self.DragFeedback = nil
	self.DragState = nil
end

function controller:BeginInventoryDrag(kind, index, slotData, input)
	if not slotData or not slotData.ItemId or slotData.Quantity <= 0 then return end
	self:CancelInventoryDrag()
	self.DragState = {
		Kind = kind,
		Index = index,
		SlotData = slotData,
		Input = input,
		StartPosition = inputPosition(input),
	}
end

function controller:GetInventoryDrop(position)
	local success, guiObjects = pcall(function()
		return playerGui:GetGuiObjectsAtPosition(position.X, position.Y)
	end)
	if success then
		for quickIndex, slotUi in self.InventoryQuickSlots do
			for _, guiObject in guiObjects do
				if guiBelongsTo(guiObject, slotUi.Frame) then
					return "Quick", quickIndex, slotUi.Border
				end
			end
		end
		for inventoryIndex, slotUi in self.InventorySlots do
			for _, guiObject in guiObjects do
				if guiBelongsTo(guiObject, slotUi.Frame) then
					return "Inventory", inventoryIndex, slotUi.Border
				end
			end
		end
	end

	local positions = getDropPositions(position)
	for quickIndex, slotUi in self.InventoryQuickSlots do
		for _, candidate in positions do
			if pointInside(slotUi.Frame, candidate) then
				return "Quick", quickIndex, slotUi.Border
			end
		end
	end
	for inventoryIndex, slotUi in self.InventorySlots do
		for _, candidate in positions do
			if pointInside(slotUi.Frame, candidate) then
				return "Inventory", inventoryIndex, slotUi.Border
			end
		end
	end
	local inventoryFrame = self.MainFrame and self.MainFrame:FindFirstChild("InventoryFrame")
	if inventoryFrame then
		for _, candidate in positions do
			if pointInside(inventoryFrame, candidate) then
				for index = 1, MAIN_SLOT_COUNT do
					local slot = self.Inventory and self.Inventory.Slots[index]
					if not slot or not slot.ItemId then return "Inventory", index, nil end
				end
			end
		end
	end
	return nil, nil, nil
end

function controller:UpdateInventoryDrag(position)
	local drag = self.DragState
	if not drag then return end
	local dragThreshold = drag.Input.UserInputType == Enum.UserInputType.Touch
		and InventoryConfig.MOBILE_SLOT_MOVE_TOLERANCE or DRAG_THRESHOLD_PIXELS
	if not self.DragGhost and (position - drag.StartPosition).Magnitude >= dragThreshold then
		local ghost = InventoryDragGhost.Create(self.ScreenGui, drag.SlotData, function(parent, slotData)
			local iconId = ItemIconConfig[slotData.ItemId]
			if iconId and iconId ~= "" then buildItemIcon(parent, iconId) else buildItemFallback(parent, slotData.ItemId) end
			local count = Instance.new("TextLabel")
			count.Size = UDim2.new(1, -8, 0, 14)
			count.Position = UDim2.new(0, 4, 1, -3)
			count.AnchorPoint = Vector2.new(0, 1)
			count.BackgroundTransparency = 1
			count.Text = slotData.Quantity > 1 and tostring(slotData.Quantity) or ""
			count.TextColor3 = Color3.fromRGB(245, 247, 250)
			count.Font = Enum.Font.GothamBold
			count.TextSize = 10
			count.TextXAlignment = Enum.TextXAlignment.Right
			count.ZIndex = 102
			count.Parent = parent
		end)
		self.DragGhost = ghost
	end
	if not self.DragGhost then return end
	self.DragGhost.Position = UDim2.fromOffset(position.X, position.Y)
	local targetKind, _, border = self:GetInventoryDrop(position)
	local valid = (drag.Kind == "Inventory" and (targetKind == "Quick" or targetKind == "Inventory"))
		or (drag.Kind == "Quick" and (targetKind == "Quick" or targetKind == "Inventory"))
	if self.DragFeedback and self.DragFeedback ~= border then
		self.DragFeedback.Color = Color3.fromRGB(75, 87, 104)
		self.DragFeedback.Transparency = 0.72
	end
	self.DragFeedback = border
	if border then
		border.Color = valid and Color3.fromRGB(83, 181, 126) or Color3.fromRGB(198, 79, 79)
		border.Transparency = 0.12
	end
	self.DragGhost.BackgroundColor3 = valid and Color3.fromRGB(39, 88, 65) or Color3.fromRGB(92, 42, 45)
end

function controller:FinishInventoryDrag(position)
	local drag = self.DragState
	if not drag then return end
	local targetKind, targetIndex = self:GetInventoryDrop(position)
	if self.DragGhost then
		if drag.Kind == "Inventory" and targetKind == "Quick" then
			inventoryRequest:FireServer("Move", {fromIndex = drag.Index, toIndex = MAIN_SLOT_COUNT + targetIndex})
		elseif drag.Kind == "Inventory" and targetKind == "Inventory" and drag.Index ~= targetIndex then
			inventoryRequest:FireServer("Move", {fromIndex = drag.Index, toIndex = targetIndex})
		elseif drag.Kind == "Quick" and targetKind == "Quick" then
			inventoryRequest:FireServer("Move", {fromIndex = MAIN_SLOT_COUNT + drag.Index, toIndex = MAIN_SLOT_COUNT + targetIndex})
		elseif drag.Kind == "Quick" and targetKind == "Inventory" then
			inventoryRequest:FireServer("Move", {fromIndex = MAIN_SLOT_COUNT + drag.Index, toIndex = targetIndex})
		end
	elseif drag.Kind == "Quick" then
		inventoryRequest:FireServer("SelectQuickSlot", {quickSlotIndex = drag.Index})
	end
	self:CancelInventoryDrag()
end

function controller:CanToggleFromInput()
	if player:GetAttribute("SessionStarted") ~= true
		or player:GetAttribute("InMainMenu") == true
		or player:GetAttribute("ReturningToMenu") == true
	then
		return false
	end
	local focusedTextBox = UserInputService:GetFocusedTextBox()
	if focusedTextBox then
		return false
	end

	return true
end

function controller:ToggleInventory()
	local now = os.clock()
	if now - self.LastToggleTime < 0.08 then
		return
	end
	self.LastToggleTime = now
	self:SetOpen(not self.Open)
end

function controller:HasPriorityInteraction()
	for prompt in self.PriorityPrompts do
		if prompt.Parent and prompt.Enabled and prompt.KeyboardKeyCode == Enum.KeyCode.E then return true end
		self.PriorityPrompts[prompt] = nil
	end
	return false
end

function controller:BindInput()
	if self.InventoryInputBound then
		return
	end

	ContextActionService:BindActionAtPriority(
		INVENTORY_ACTION_NAME,
		function(_, inputState, inputObject)
			if not inputObject or inputObject.KeyCode ~= Enum.KeyCode.E then
				return Enum.ContextActionResult.Pass
			end

			if not self:CanToggleFromInput() then
				return Enum.ContextActionResult.Pass
			end
			if self:HasPriorityInteraction() then return Enum.ContextActionResult.Pass end

			if inputState == Enum.UserInputState.Begin then
				self:ToggleInventory()
			end

			return Enum.ContextActionResult.Sink
		end,
		false,
		INVENTORY_INPUT_PRIORITY,
		Enum.KeyCode.E
	)
	self.InventoryInputBound = true
end

function controller:BuildMobileButton()
	local inventoryButton = Instance.new("ImageButton")
	inventoryButton.Name = "MobileInventoryButton"
	inventoryButton.Size = UDim2.fromOffset(64, 64)
	inventoryButton.Position = UDim2.new(1, -20, 0, 76)
	inventoryButton.AnchorPoint = Vector2.new(1, 0)
	inventoryButton.BackgroundTransparency = 1
	inventoryButton.Image = "rbxassetid://80162683254318"
	inventoryButton.ScaleType = Enum.ScaleType.Fit
	inventoryButton.AutoButtonColor = false
	inventoryButton.Visible = false
	inventoryButton.ZIndex = 20
	inventoryButton.Parent = self.ScreenGui
	local buttonScale = Instance.new("UIScale")
	buttonScale.Parent = inventoryButton
	inventoryButton.MouseButton1Down:Connect(function()
		TweenService:Create(buttonScale, TweenInfo.new(0.07), {Scale = 0.96}):Play()
	end)
	inventoryButton.MouseButton1Up:Connect(function()
		TweenService:Create(buttonScale, TweenInfo.new(0.09), {Scale = 1}):Play()
	end)
	inventoryButton.Activated:Connect(function()
		if self:CanToggleFromInput() then self:ToggleInventory() end
	end)
	self.MobileButton = inventoryButton
	self:RefreshMobileButton()
end

function controller:RefreshMobileButton()
	self.IsTouchDevice = isTouchDevice()
	if self.MobileButton then
		self.MobileButton.Visible = self.IsTouchDevice and player:GetAttribute("SessionStarted") == true
	end
end

function controller:BindQuickSlotInput()
	ContextActionService:UnbindAction("SelectQuickSlot")
	ContextActionService:BindActionAtPriority(
		"SelectQuickSlot",
		function(_, inputState, inputObject)
			if not inputObject then
				return Enum.ContextActionResult.Pass
			end

			local slotIndex = QUICK_SLOT_KEY_INDEX[inputObject.KeyCode]
			if not slotIndex then
				return Enum.ContextActionResult.Pass
			end

			if not self:CanToggleFromInput() then
				return Enum.ContextActionResult.Pass
			end

			if inputState == Enum.UserInputState.Begin and not self.Open then
				inventoryRequest:FireServer("SelectQuickSlot", {quickSlotIndex = slotIndex})
			end

			return Enum.ContextActionResult.Sink
		end,
		false,
		QUICK_SLOT_INPUT_PRIORITY,
		table.unpack(QUICK_SLOT_KEYS)
	)
end

function controller:GetActiveFoodSlotIndex()
	local activeQuickSlot = self.Inventory and self.Inventory.ActiveQuickSlot or 0
	if activeQuickSlot < 1 or activeQuickSlot > QUICK_SLOT_COUNT then
		return nil
	end

	local slotIndex = MAIN_SLOT_COUNT + activeQuickSlot
	local slot = self.Inventory.Slots[slotIndex]
	local definition = slot and slot.ItemId and ItemDefinitions[slot.ItemId]
	if definition and definition.Category == "Food" and definition.Consumable == true and slot.Quantity > 0 then
		return slotIndex
	end
	return nil
end

function controller:RefreshConsumePrompt()
	if self.ConsumePrompt then
		self.ConsumePrompt.Visible = not self.Open and self.Hunger < 100 and self:GetActiveFoodSlotIndex() ~= nil
	end
end

function controller:RequestConsumeActiveFood()
	local slotIndex = self:GetActiveFoodSlotIndex()
	if slotIndex and self.Hunger < 100 and not self.Open then
		inventoryRequest:FireServer("Use", {slotIndex = slotIndex})
	end
end

function controller:BindConsumeInput()
	ContextActionService:UnbindAction("ConsumeActiveFood")
	ContextActionService:BindActionAtPriority(
		"ConsumeActiveFood",
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin and self:GetActiveFoodSlotIndex() then
				self:RequestConsumeActiveFood()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		QUICK_SLOT_INPUT_PRIORITY,
		Enum.KeyCode.F
	)
end

function controller:BuildConsumePrompt()
	local prompt = Instance.new("TextButton")
	prompt.Name = "ConsumeFoodPrompt"
	prompt.Size = UDim2.fromOffset(122, 34)
	prompt.Position = UDim2.new(0.5, 0, 1, -134)
	prompt.AnchorPoint = Vector2.new(0.5, 1)
	prompt.BackgroundColor3 = Color3.fromRGB(18, 14, 11)
	prompt.BackgroundTransparency = 0.12
	prompt.BorderSizePixel = 0
	prompt.AutoButtonColor = false
	prompt.Text = self.IsTouchDevice and "MANGER" or "[F]  MANGER"
	prompt.TextColor3 = Color3.fromRGB(244, 220, 181)
	prompt.Font = Enum.Font.GothamSemibold
	prompt.TextSize = 12
	prompt.Visible = false
	prompt.Parent = self.ScreenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = prompt

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(190, 137, 79)
	stroke.Transparency = 0.58
	stroke.Thickness = 1
	stroke.Parent = prompt

	local feedback = Instance.new("TextLabel")
	feedback.Size = UDim2.new(1, 0, 0, 18)
	feedback.Position = UDim2.new(0.5, 0, 0, -5)
	feedback.AnchorPoint = Vector2.new(0.5, 1)
	feedback.BackgroundTransparency = 1
	feedback.Text = ""
	feedback.TextColor3 = Color3.fromRGB(242, 174, 91)
	feedback.Font = Enum.Font.GothamSemibold
	feedback.TextSize = 11
	feedback.Parent = prompt

	prompt.Activated:Connect(function()
		self:RequestConsumeActiveFood()
	end)

	self.ConsumePrompt = prompt
	self.ConsumeFeedback = feedback
end

function controller:BuildHotbar()
	local hotbar = Instance.new("Frame")
	hotbar.Name = "MAYDEADHotbar"
	hotbar.Size = UDim2.fromOffset(426, 54)
	hotbar.Position = UDim2.new(0.5, 0, 1, -14)
	hotbar.AnchorPoint = Vector2.new(0.5, 1)
	hotbar.BackgroundTransparency = 1
	hotbar.Parent = self.ScreenGui

	local hotbarScale = Instance.new("UIScale")
	local camera = workspace.CurrentCamera
	local viewportWidth = camera and camera.ViewportSize.X or 1920
	hotbarScale.Scale = math.clamp((viewportWidth - 24) / 426, 0.62, 1)
	hotbarScale.Parent = hotbar
	self.HotbarScale = hotbarScale
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			hotbarScale.Scale = math.clamp((camera.ViewportSize.X - 24) / 426, 0.62, 1)
		end)
	end

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.Parent = hotbar

	for slotIndex = 1, QUICK_SLOT_COUNT do
		local slotUi = createQuickSlot(hotbar, slotIndex, 48)
		self.HotbarSlots[slotIndex] = slotUi

		slotUi.Frame.MouseButton1Click:Connect(function()
			inventoryRequest:FireServer("SelectQuickSlot", {quickSlotIndex = slotIndex})
		end)
	end
end

function controller:Build()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end

	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "MAYDEADInventoryUI"
	self.ScreenGui.ResetOnSpawn = false
	self.ScreenGui.IgnoreGuiInset = true
	self.ScreenGui.DisplayOrder = 20
	self.ScreenGui.Parent = playerGui

	self.IsTouchDevice = isTouchDevice()
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt.KeyboardKeyCode == Enum.KeyCode.E then self.PriorityPrompts[prompt] = true end
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt) self.PriorityPrompts[prompt] = nil end)
	self:BindInput()
	self:BindQuickSlotInput()
	self:BindConsumeInput()
	self:BuildHotbar()
	self:BuildConsumePrompt()
	self:BuildMobileButton()
	local function refreshSessionState()
		local inSession = player:GetAttribute("SessionStarted") == true
		if not inSession and self.Open then self:SetOpen(false) end
		if self.ScreenGui then self.ScreenGui.Enabled = inSession end
		self:RefreshMobileButton()
	end
	player:GetAttributeChangedSignal("SessionStarted"):Connect(refreshSessionState)
	player:GetAttributeChangedSignal("ReturningToMenu"):Connect(refreshSessionState)
	pcall(function()
		UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function() self:RefreshMobileButton() end)
	end)
	refreshSessionState()
	UserInputService.InputChanged:Connect(function(input)
		if self.DragState and (input.UserInputType == Enum.UserInputType.MouseMovement or input == self.DragState.Input) then
			self:UpdateInventoryDrag(inputPosition(input))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if self.DragState and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == self.DragState.Input) then
			self:FinishInventoryDrag(inputPosition(input))
		end
	end)

	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "MainFrame"
	self.MainFrame.Size = UDim2.new(0, 404, 0, 498)
	self.MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.MainFrame.BackgroundColor3 = Color3.fromRGB(8, 11, 17)
	self.MainFrame.BackgroundTransparency = 1
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.Visible = false
	self.MainFrame.Parent = self.ScreenGui

	local panelScale = Instance.new("UIScale")
	panelScale.Name = "PanelScale"
	self.PanelTargetScale = calculatePanelScale()
	panelScale.Scale = self.PanelTargetScale * 0.96
	panelScale.Parent = self.MainFrame

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(960, 600)
	sizeConstraint.MinSize = Vector2.new(320, 350)
	sizeConstraint.Parent = self.MainFrame

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 25, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 13, 20)),
	})
	gradient.Parent = self.MainFrame

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = self.MainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(98, 112, 128)
	mainStroke.Transparency = 0.8
	mainStroke.Thickness = 1
	mainStroke.Parent = self.MainFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0, 160, 0, 24)
	title.Position = UDim2.new(0, 20, 0, 17)
	title.BackgroundTransparency = 1
	title.Text = "INVENTAIRE"
	title.TextColor3 = Color3.fromRGB(245, 248, 252)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = self.MainFrame

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(0, 140, 0, 18)
	subtitle.Position = UDim2.new(1, -20, 0, 20)
	subtitle.AnchorPoint = Vector2.new(1, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "0 / 28 slots"
	subtitle.TextColor3 = Color3.fromRGB(142, 156, 172)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 11
	subtitle.TextXAlignment = Enum.TextXAlignment.Right
	subtitle.Parent = self.MainFrame

	local dayAgePanel = Instance.new("Frame")
	dayAgePanel.Name = "DayAgePanel"
	dayAgePanel.Size = UDim2.new(1, -32, 0, 36)
	dayAgePanel.Position = UDim2.fromOffset(16, 52)
	dayAgePanel.BackgroundTransparency = 1
	dayAgePanel.ClipsDescendants = true
	dayAgePanel.Parent = self.MainFrame

	local controlHint = Instance.new("TextLabel")
	controlHint.Name = "ControlHint"
	controlHint.Size = UDim2.new(1, -40, 0, 14)
	controlHint.Position = UDim2.new(0.5, 0, 1, -7)
	controlHint.AnchorPoint = Vector2.new(0.5, 1)
	controlHint.BackgroundTransparency = 1
	controlHint.Text = "E  Fermer"
	controlHint.TextColor3 = Color3.fromRGB(125, 137, 153)
	controlHint.Font = Enum.Font.Gotham
	controlHint.TextSize = 10
	controlHint.TextXAlignment = Enum.TextXAlignment.Center
	controlHint.Visible = not self.IsTouchDevice
	controlHint.Parent = self.MainFrame

	local hoverTooltip = Instance.new("TextLabel")
	hoverTooltip.Name = "HoverTooltip"
	hoverTooltip.Size = UDim2.new(1, -160, 0, 16)
	hoverTooltip.Position = UDim2.new(0.5, 0, 1, -22)
	hoverTooltip.AnchorPoint = Vector2.new(0.5, 1)
	hoverTooltip.BackgroundTransparency = 1
	hoverTooltip.Text = ""
	hoverTooltip.TextColor3 = Color3.fromRGB(170, 184, 201)
	hoverTooltip.Font = Enum.Font.GothamSemibold
	hoverTooltip.TextSize = 9
	hoverTooltip.Parent = self.MainFrame
	self.HoverTooltip = hoverTooltip

	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(1, -32, 0, 264)
	inventoryFrame.Position = UDim2.new(0, 16, 0, 99)
	inventoryFrame.BackgroundTransparency = 1
	inventoryFrame.Parent = self.MainFrame

	local invLayout = Instance.new("UIGridLayout")
	invLayout.CellPadding = UDim2.new(0, 10, 0, 8)
	invLayout.CellSize = UDim2.new(0, 60, 0, 60)
	invLayout.StartCorner = Enum.StartCorner.TopLeft
	invLayout.FillDirection = Enum.FillDirection.Horizontal
	invLayout.FillDirectionMaxCells = 5
	invLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	invLayout.Parent = inventoryFrame

	for index = 1, 20 do
		local slot = Instance.new("Frame")
		slot.Name = "InventorySlot" .. index
		slot.BackgroundColor3 = Color3.fromRGB(13, 17, 25)
		slot.BackgroundTransparency = 0.28
		slot.BorderSizePixel = 0
		slot.Parent = inventoryFrame

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 11)
		slotCorner.Parent = slot

		local slotStroke = Instance.new("UIStroke")
		slotStroke.Color = Color3.fromRGB(72, 84, 100)
		slotStroke.Transparency = 0.8
		slotStroke.Thickness = 1
		slotStroke.Parent = slot

		local iconContainer = Instance.new("Frame")
		iconContainer.Size = UDim2.new(1, -10, 1, -10)
		iconContainer.Position = UDim2.new(0, 5, 0, 5)
		iconContainer.BackgroundTransparency = 1
		iconContainer.Parent = slot

		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, -10, 0, 14)
		countLabel.Position = UDim2.new(0, 5, 1, -5)
		countLabel.AnchorPoint = Vector2.new(0, 1)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = ""
		countLabel.TextColor3 = Color3.fromRGB(210, 218, 229)
		countLabel.Font = Enum.Font.GothamSemibold
		countLabel.TextSize = 11
		countLabel.TextXAlignment = Enum.TextXAlignment.Right
		countLabel.Parent = slot

		self.InventorySlots[index] = {Frame = slot, IconContainer = iconContainer, Count = countLabel, Border = slotStroke}
		slot.Active = true

		slot.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local slotData = self.Inventory and self.Inventory.Slots[index]
				self:BeginInventoryDrag("Inventory", index, slotData, input)
			end
		end)

		slot.MouseEnter:Connect(function()
			self:HighlightSlot(index, true)
			self:SetHoverTooltip(self.Inventory and self.Inventory.Slots[index], nil)
		end)

		slot.MouseLeave:Connect(function()
			self:HighlightSlot(index, false)
			self:SetHoverTooltip(nil, nil)
		end)
	end

	local quickTitle = Instance.new("TextLabel")
	quickTitle.Name = "QuickAccessTitle"
	quickTitle.Size = UDim2.new(0, 150, 0, 16)
	quickTitle.Position = UDim2.fromOffset(20, 378)
	quickTitle.BackgroundTransparency = 1
	quickTitle.Text = "ACCÈS RAPIDE"
	quickTitle.TextColor3 = Color3.fromRGB(218, 225, 235)
	quickTitle.Font = Enum.Font.GothamBold
	quickTitle.TextSize = 11
	quickTitle.TextXAlignment = Enum.TextXAlignment.Left
	quickTitle.Parent = self.MainFrame

	local quickHelp = Instance.new("TextLabel")
	quickHelp.Name = "QuickAccessHelp"
	quickHelp.Size = UDim2.new(1, -40, 0, 14)
	quickHelp.Position = UDim2.fromOffset(20, 395)
	quickHelp.BackgroundTransparency = 1
	quickHelp.Text = "Glisse un stack ici pour le placer dans l'accès rapide."
	quickHelp.TextColor3 = Color3.fromRGB(122, 135, 151)
	quickHelp.Font = Enum.Font.Gotham
	quickHelp.TextSize = 9
	quickHelp.TextXAlignment = Enum.TextXAlignment.Left
	quickHelp.Parent = self.MainFrame

	local inventoryQuickFrame = Instance.new("Frame")
	inventoryQuickFrame.Name = "QuickAccessSlots"
	inventoryQuickFrame.Size = UDim2.new(1, -32, 0, 50)
	inventoryQuickFrame.Position = UDim2.fromOffset(16, 414)
	inventoryQuickFrame.BackgroundTransparency = 1
	inventoryQuickFrame.Parent = self.MainFrame

	local quickLayout = Instance.new("UIListLayout")
	quickLayout.FillDirection = Enum.FillDirection.Horizontal
	quickLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	quickLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	quickLayout.Padding = UDim.new(0, 6)
	quickLayout.Parent = inventoryQuickFrame

	for slotIndex = 1, QUICK_SLOT_COUNT do
		local slotUi = createQuickSlot(inventoryQuickFrame, slotIndex, 40)
		self.InventoryQuickSlots[slotIndex] = slotUi

		local removeButton = Instance.new("TextButton")
		removeButton.Name = "Remove"
		removeButton.Size = UDim2.fromOffset(16, 16)
		removeButton.Position = UDim2.new(1, -2, 0, 2)
		removeButton.AnchorPoint = Vector2.new(1, 0)
		removeButton.BackgroundColor3 = Color3.fromRGB(34, 39, 49)
		removeButton.BackgroundTransparency = 0.12
		removeButton.BorderSizePixel = 0
		removeButton.Text = "×"
		removeButton.TextColor3 = Color3.fromRGB(190, 199, 211)
		removeButton.Font = Enum.Font.GothamBold
		removeButton.TextSize = 11
		removeButton.Visible = false
		removeButton.ZIndex = 9
		removeButton.Parent = slotUi.Frame

		local removeCorner = Instance.new("UICorner")
		removeCorner.CornerRadius = UDim.new(0, 999)
		removeCorner.Parent = removeButton

		slotUi.Remove = removeButton
		slotUi.Frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local slotData = self.Inventory and self.Inventory.Slots[MAIN_SLOT_COUNT + slotIndex]
				if slotData and slotData.ItemId then
					self:BeginInventoryDrag("Quick", slotIndex, slotData, input)
				else
					inventoryRequest:FireServer("SelectQuickSlot", {quickSlotIndex = slotIndex})
				end
			end
		end)
		slotUi.Frame.MouseEnter:Connect(function()
			self:SetHoverTooltip(self.Inventory and self.Inventory.Slots[MAIN_SLOT_COUNT + slotIndex], slotIndex)
		end)
		slotUi.Frame.MouseLeave:Connect(function() self:SetHoverTooltip(nil, nil) end)
		removeButton.Visible = false
	end

	inventoryRemote.OnClientEvent:Connect(function(state)
		self.Inventory = state
		self:Render()
		self:RefreshConsumePrompt()
	end)
	survivalRemote.OnClientEvent:Connect(function(state)
		self.Hunger = state.Hunger or self.Hunger
		self:RefreshConsumePrompt()
	end)
	foodConsumed.OnClientEvent:Connect(function()
		if self.ConsumeFeedback then
			self.ConsumeFeedback.Text = "NOURRI"
			task.delay(0.8, function()
				if self.ConsumeFeedback then
					self.ConsumeFeedback.Text = ""
				end
			end)
		end
	end)
	inventoryRequest:FireServer("RequestState")
end

function controller:HandleSlotClick(index)
	local slotData = self.Inventory and self.Inventory.Slots[index]
	local itemId = slotData and slotData.ItemId
	if self.SelectedInventoryIndex and self.SelectedInventoryIndex ~= index then
		inventoryRequest:FireServer("Move", {
			fromIndex = self.SelectedInventoryIndex,
			toIndex = index,
		})
		self.SelectedInventoryIndex = nil
	elseif itemId and ItemDefinitions[itemId] then
		self.SelectedInventoryIndex = index
	else
		self.SelectedInventoryIndex = nil
	end

	self:RenderInventorySelection()
	self:RenderQuickSlots(false)
end

function controller:RenderInventorySelection()
	for index, slotUi in self.InventorySlots do
		if index == self.SelectedInventoryIndex then
			slotUi.Border.Color = Color3.fromRGB(154, 181, 214)
			slotUi.Border.Transparency = 0.22
			slotUi.Frame.BackgroundColor3 = Color3.fromRGB(24, 31, 43)
			slotUi.Frame.BackgroundTransparency = 0.04
		else
			local slotData = self.Inventory and self.Inventory.Slots[index]
			local occupied = slotData and slotData.ItemId and ItemDefinitions[slotData.ItemId]
			slotUi.Border.Color = Color3.fromRGB(72, 84, 100)
			slotUi.Border.Transparency = occupied and 0.64 or 0.82
			slotUi.Frame.BackgroundColor3 = occupied and Color3.fromRGB(18, 23, 32) or Color3.fromRGB(13, 17, 25)
			slotUi.Frame.BackgroundTransparency = occupied and 0.12 or 0.28
		end
	end
end

function controller:RenderQuickSlots(animateActive)
	local activeSlot = self.Inventory and self.Inventory.ActiveQuickSlot or 0

	local function renderSet(slotSet, assignmentTargets)
		for slotIndex = 1, QUICK_SLOT_COUNT do
			local slotUi = slotSet[slotIndex]
			if slotUi then
				local slotData = self.Inventory and self.Inventory.Slots[MAIN_SLOT_COUNT + slotIndex]
				local itemId = slotData and slotData.ItemId
				local quantity = slotData and slotData.Quantity or 0
				local imageAssetId = itemId and ItemIconConfig[itemId]

				slotUi.IconContainer:ClearAllChildren()
				slotUi.Count.Text = quantity > 1 and tostring(quantity) or ""
				if imageAssetId and imageAssetId ~= "" and quantity > 0 then
					buildItemIcon(slotUi.IconContainer, imageAssetId)
				elseif itemId and quantity > 0 then
					buildItemFallback(slotUi.IconContainer, itemId)
				end
				buildWaterChargeBadge(slotUi.IconContainer, slotData)

				local isActive = activeSlot == slotIndex and itemId ~= nil and quantity > 0
				local isSelected = self.SelectedInventoryIndex == MAIN_SLOT_COUNT + slotIndex
				slotUi.Frame.BackgroundColor3 = isActive and Color3.fromRGB(27, 35, 48) or Color3.fromRGB(14, 18, 26)
				slotUi.Frame.BackgroundTransparency = isActive and 0.04 or 0.2
				slotUi.Border.Color = (isActive or isSelected) and Color3.fromRGB(170, 197, 226) or Color3.fromRGB(75, 87, 104)
				local selectedForMove = assignmentTargets and self.SelectedInventoryIndex ~= nil
				slotUi.Border.Transparency = (isActive or isSelected) and 0.12 or (selectedForMove and 0.42 or 0.72)
				slotUi.Number.TextColor3 = isActive and Color3.fromRGB(235, 241, 248) or Color3.fromRGB(142, 154, 170)

				if slotUi.Remove then
					slotUi.Remove.Visible = false
				end

				if animateActive and isActive then
					slotUi.Scale.Scale = 0.94
					TweenService:Create(slotUi.Scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Scale = 1,
					}):Play()
				else
					slotUi.Scale.Scale = 1
				end
			end
		end
	end

	renderSet(self.HotbarSlots, false)
	renderSet(self.InventoryQuickSlots, true)
end

function controller:HighlightSlot(index, hovered)
	local slotUi = self.InventorySlots[index]
	if not slotUi then
		return
	end

	if index == self.SelectedInventoryIndex then
		slotUi.Frame.BackgroundTransparency = 0.04
		slotUi.Frame.BackgroundColor3 = Color3.fromRGB(24, 31, 43)
		slotUi.Border.Color = Color3.fromRGB(154, 181, 214)
		slotUi.Border.Transparency = 0.22
	elseif hovered then
		slotUi.Frame.BackgroundTransparency = 0.08
		slotUi.Frame.BackgroundColor3 = Color3.fromRGB(19, 24, 33)
		slotUi.Border.Transparency = 0.6
	else
		local slotData = self.Inventory and self.Inventory.Slots[index]
		local itemId = slotData and slotData.ItemId
		if itemId and ItemDefinitions[itemId] then
			slotUi.Border.Color = Color3.fromRGB(72, 84, 100)
			slotUi.Frame.BackgroundTransparency = 0.12
			slotUi.Frame.BackgroundColor3 = Color3.fromRGB(18, 23, 32)
			slotUi.Border.Transparency = 0.64
		else
			slotUi.Border.Color = Color3.fromRGB(72, 84, 100)
			slotUi.Frame.BackgroundTransparency = 0.28
			slotUi.Frame.BackgroundColor3 = Color3.fromRGB(13, 17, 25)
			slotUi.Border.Transparency = 0.82
		end
	end
end

function controller:Render()
	if not self.Inventory then
		return
	end

	local occupied = 0
	for index, slotData in ipairs(self.Inventory.Slots) do
		local itemId = slotData and slotData.ItemId
		if itemId and ItemDefinitions[itemId] then occupied = occupied + 1 end
		local slotUi = self.InventorySlots[index]
		if slotUi then
			local quantity = slotData and slotData.Quantity or 0
			local imageAssetId = itemId and ItemIconConfig[itemId]
			slotUi.IconContainer:ClearAllChildren()
			slotUi.Count.Text = ""
			if itemId and ItemDefinitions[itemId] then
				if imageAssetId and imageAssetId ~= "" then
					slotUi.IconContainer.Visible = true
					buildItemIcon(slotUi.IconContainer, imageAssetId)
				else
					slotUi.IconContainer.Visible = true
					buildItemFallback(slotUi.IconContainer, itemId)
				end
				slotUi.Count.Text = quantity > 1 and tostring(quantity) or ""
				slotUi.Frame.BackgroundTransparency = 0.12
				slotUi.Frame.BackgroundColor3 = Color3.fromRGB(18, 23, 32)
				slotUi.Border.Transparency = 0.64
			else
				slotUi.IconContainer.Visible = false
				slotUi.Frame.BackgroundTransparency = 0.28
				slotUi.Frame.BackgroundColor3 = Color3.fromRGB(13, 17, 25)
				slotUi.Border.Transparency = 0.82
			end
			buildWaterChargeBadge(slotUi.IconContainer, slotData)
		end
	end

	if self.SelectedInventoryIndex then
		local selectedSlot = self.Inventory.Slots[self.SelectedInventoryIndex]
		if not selectedSlot or not selectedSlot.ItemId then
			self.SelectedInventoryIndex = nil
		end
	end
	self:RenderInventorySelection()
	self:RenderQuickSlots(false)

	if self.MainFrame and self.MainFrame:FindFirstChild("Subtitle") then
		self.MainFrame.Subtitle.Text = tostring(occupied) .. " / 28 slots"
	end

end

function controller:SetOpen(open)
	if open and not self:CanToggleFromInput() then return end
	self.Open = open
	self.OpenChanged:Fire(open)
	self:RefreshConsumePrompt()
	self.VisualTransitionId = self.VisualTransitionId + 1
	local transitionId = self.VisualTransitionId

	if not self.MainFrame then
		return
	end

	if self.BackgroundTween then
		self.BackgroundTween:Cancel()
	end
	if self.ScaleTween then
		self.ScaleTween:Cancel()
	end

	local panelScale = self.MainFrame:FindFirstChild("PanelScale")
	self.PanelTargetScale = calculatePanelScale()
	self.ScreenGui.Enabled = true

	if open then
		self.MainFrame.Visible = true
		self.MainFrame.BackgroundTransparency = 1
		if panelScale then
			panelScale.Scale = self.PanelTargetScale * 0.96
		end
		self.BackgroundTween = TweenService:Create(self.MainFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.08,
		})
		self.BackgroundTween:Play()
		if panelScale then
			self.ScaleTween = TweenService:Create(panelScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = self.PanelTargetScale,
			})
			self.ScaleTween:Play()
		end
	else
		self.BackgroundTween = TweenService:Create(self.MainFrame, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})
		self.BackgroundTween:Play()
		if panelScale then
			self.ScaleTween = TweenService:Create(panelScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = self.PanelTargetScale * 0.96,
			})
			self.ScaleTween:Play()
		end
		task.delay(0.14, function()
			if self.Open or self.VisualTransitionId ~= transitionId then
				return
			end
			self.MainFrame.Visible = false
		end)
	end

end

function controller:Start()
	self:Build()
end

return controller.new()
