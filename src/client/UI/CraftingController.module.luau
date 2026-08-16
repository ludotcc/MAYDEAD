local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local DEPENDENCY_TIMEOUT = 5

local function requireChild(parent, childName)
	local child = parent:WaitForChild(childName, DEPENDENCY_TIMEOUT)
	if not child then
		error("[MAYDEAD] CraftingController dependency timed out: " .. childName, 0)
	end
	return child
end

local SharedFolder = requireChild(ReplicatedStorage, "Shared")
local DefinitionsFolder = requireChild(SharedFolder, "Definitions")
local ConfigFolder = requireChild(SharedFolder, "Config")
local ItemDefinitions = require(requireChild(DefinitionsFolder, "ItemDefinitions"))
local ItemIconConfig = require(requireChild(ConfigFolder, "ItemIconConfig"))
local RecipeDefinitions = require(requireChild(DefinitionsFolder, "RecipeDefinitions"))


local inventoryControllerModule = script.Parent:FindFirstChild("InventoryController")
	or script.Parent:FindFirstChild("InventoryController.module")
if not inventoryControllerModule or not inventoryControllerModule:IsA("ModuleScript") then
	error("[MAYDEAD] CraftingController dependency missing: InventoryController.module", 0)
end
local InventoryController = require(inventoryControllerModule)

local inventoryRemote = requireChild(ReplicatedStorage, "InventoryStateChanged")
local craftRequest = requireChild(ReplicatedStorage, "CraftRequest")
local craftResult = requireChild(ReplicatedStorage, "CraftResult")
local openWorkbench = requireChild(ReplicatedStorage, "OpenWorkbench")
local stationOpened = requireChild(ReplicatedStorage, "StationOpened")
local stationStateChanged = requireChild(ReplicatedStorage, "StationStateChanged")

local controller = {
	Started = false,
	Inventory = nil,
	CraftType = "Basic",
	Station = nil,
	StationState = nil,
	Cards = {},
	SectionHeaders = {},
}

local CATEGORY_ORDER = {Construction = 1, Factory = 2, Misc = 3}
local CATEGORY_LABELS = {Construction = "CONSTRUCTION", Factory = "FACTORY", Misc = "DIVERS"}

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function addStroke(instance, color, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = 1
	stroke.Parent = instance
end

local function getItemCount(inventory, itemId)
	local total = 0
	for _, slot in ipairs(inventory and inventory.Slots or {}) do
		if slot.ItemId == itemId then
			total = total + slot.Quantity
		end
	end
	return total
end

local function isStationInRange(station)
	if typeof(station) ~= "Instance" or not station:IsDescendantOf(workspace) then
		return false
	end
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	return rootPart ~= nil and (rootPart.Position - station:GetPivot().Position).Magnitude <= 10
end

local function getRecipesForType(craftType)
	local recipeIds = {}
	for recipeId, recipe in RecipeDefinitions do
		if recipe.CraftType == craftType then
			table.insert(recipeIds, recipeId)
		end
	end
	table.sort(recipeIds, function(leftId, rightId)
		local left = RecipeDefinitions[leftId]
		local right = RecipeDefinitions[rightId]
		if craftType == "Workbench" then
			local leftCategory = CATEGORY_ORDER[left.UiCategory or "Misc"] or CATEGORY_ORDER.Misc
			local rightCategory = CATEGORY_ORDER[right.UiCategory or "Misc"] or CATEGORY_ORDER.Misc
			if leftCategory ~= rightCategory then return leftCategory < rightCategory end
		end
		if left.SortOrder == right.SortOrder then
			return left.Id < right.Id
		end
		return left.SortOrder < right.SortOrder
	end)
	return recipeIds
end

local function setInventoryContentVisible(visible)
	local mainFrame = InventoryController.MainFrame
	if not mainFrame then
		return
	end
	for _, name in ipairs({"DayAgePanel", "InventoryFrame", "QuickAccessTitle", "QuickAccessHelp", "QuickAccessSlots"}) do
		local child = mainFrame:FindFirstChild(name)
		if child then
			child.Visible = visible
		end
	end
end

function controller:_renderAvailability()
	local workbenchAvailable = self.CraftType ~= "Workbench" or isStationInRange(self.Station)
	if self.Panel and self.Panel.Visible and self.CraftType == "Workbench" then
		self.Header.Text = workbenchAvailable and "CRAFT AVANCÉ  •  TABLE DE CRAFT" or "CRAFT AVANCÉ  •  HORS PORTÉE"
	end
	for recipeId, card in self.Cards do
		local recipe = RecipeDefinitions[recipeId]
		local sourceInventory = self.CraftType == "Workbench" and self.StationState or self.Inventory
		local canCraft = self.Inventory ~= nil and workbenchAvailable
		local ingredientLines = {}
		for itemId, required in recipe.Ingredients do
			local current = getItemCount(sourceInventory, itemId)
			canCraft = canCraft and current >= required
			local definition = ItemDefinitions[itemId]
			table.insert(
				ingredientLines,
				string.format("%s  %d / %d", definition and definition.DisplayName or itemId, current, required)
			)
		end
		table.sort(ingredientLines)
		card.Ingredients.Text = table.concat(ingredientLines, "    ")
		card.Button.Active = canCraft
		card.Button.AutoButtonColor = canCraft
		card.Button.BackgroundColor3 = canCraft and Color3.fromRGB(57, 119, 91) or Color3.fromRGB(49, 54, 62)
		card.Button.TextColor3 = canCraft and Color3.fromRGB(239, 251, 246) or Color3.fromRGB(130, 138, 149)
	end
end

function controller:_buildCard(recipeId, layoutOrder)
	local recipe = RecipeDefinitions[recipeId]
	local card = Instance.new("Frame")
	card.Name = recipeId
	card.Size = UDim2.new(1, -8, 0, 78)
	card.BackgroundColor3 = Color3.fromRGB(16, 21, 30)
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder or 0
	card.Parent = self.List
	addCorner(card, 11)
	addStroke(card, Color3.fromRGB(75, 88, 105), 0.72)

	local iconRoot = Instance.new("Frame")
	iconRoot.Size = UDim2.fromOffset(52, 52)
	iconRoot.Position = UDim2.fromOffset(12, 13)
	iconRoot.BackgroundColor3 = Color3.fromRGB(25, 31, 42)
	iconRoot.BorderSizePixel = 0
	iconRoot.Parent = card
	addCorner(iconRoot, 9)

	local assetId = ItemIconConfig[recipe.ResultItemId]
	if assetId and assetId ~= "" then
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(1, -8, 1, -8)
		icon.Position = UDim2.fromOffset(4, 4)
		icon.BackgroundTransparency = 1
		icon.Image = assetId
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Parent = iconRoot
	else
		local fallback = Instance.new("TextLabel")
		fallback.Size = UDim2.fromScale(1, 1)
		fallback.BackgroundTransparency = 1
		fallback.Text = string.upper(string.sub(recipe.DisplayName, 1, 2))
		fallback.TextColor3 = Color3.fromRGB(203, 214, 228)
		fallback.Font = Enum.Font.GothamBold
		fallback.TextSize = 15
		fallback.Parent = iconRoot
	end

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -190, 0, 22)
	nameLabel.Position = UDim2.fromOffset(76, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = string.upper(recipe.DisplayName)
	nameLabel.TextColor3 = Color3.fromRGB(235, 240, 247)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local ingredients = Instance.new("TextLabel")
	ingredients.Size = UDim2.new(1, -190, 0, 30)
	ingredients.Position = UDim2.fromOffset(76, 36)
	ingredients.BackgroundTransparency = 1
	ingredients.TextColor3 = Color3.fromRGB(162, 174, 190)
	ingredients.Font = Enum.Font.Gotham
	ingredients.TextSize = 10
	ingredients.TextWrapped = true
	ingredients.TextXAlignment = Enum.TextXAlignment.Left
	ingredients.TextYAlignment = Enum.TextYAlignment.Top
	ingredients.Parent = card

	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(104, 40)
	button.Position = UDim2.new(1, -12, 0.5, 0)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(57, 119, 91)
	button.BorderSizePixel = 0
	button.Text = "FABRIQUER"
	button.TextColor3 = Color3.fromRGB(239, 251, 246)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 10
	button.Parent = card
	addCorner(button, 9)
	button.Activated:Connect(function()
		if button.Active then
			craftRequest:FireServer(recipeId, self.CraftType == "Workbench" and self.Station or nil)
		end
	end)

	self.Cards[recipeId] = {Frame = card, Ingredients = ingredients, Button = button}
end

function controller:_buildSectionHeader(category, layoutOrder)
	local header = Instance.new("Frame")
	header.Name = "Category_" .. category
	header.Size = UDim2.new(1, -8, 0, 30)
	header.BackgroundTransparency = 1
	header.LayoutOrder = layoutOrder
	header.Parent = self.List

	local accent = Instance.new("Frame")
	accent.Size = UDim2.fromOffset(3, 16)
	accent.Position = UDim2.fromOffset(2, 7)
	accent.BackgroundColor3 = category == "Factory" and Color3.fromRGB(204, 149, 67)
		or category == "Construction" and Color3.fromRGB(91, 167, 130)
		or Color3.fromRGB(105, 126, 157)
	accent.BorderSizePixel = 0
	accent.Parent = header
	addCorner(accent, 2)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -18, 1, 0)
	label.Position = UDim2.fromOffset(14, 0)
	label.BackgroundTransparency = 1
	label.Text = CATEGORY_LABELS[category] or "DIVERS"
	label.TextColor3 = Color3.fromRGB(177, 189, 205)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = header
	table.insert(self.SectionHeaders, header)
end

function controller:_showCraft(craftType, station)
	self.CraftType = craftType
	self.Station = station
	local stationPanel = InventoryController.MainFrame:FindFirstChild("StationPanel")
	if stationPanel then
		stationPanel.Visible = false
	end
	self.Panel.Visible = true
	setInventoryContentVisible(false)
	InventoryController.MainFrame.Title.Text = "INVENTAIRE"
	InventoryController.MainFrame.Subtitle.Visible = false
	self.TabButton.Text = "INVENTAIRE"
	self.Header.Text = craftType == "Workbench" and "CRAFT AVANCÉ  •  TABLE DE CRAFT" or "CRAFT DE BASE"

	for _, card in self.Cards do
		card.Frame:Destroy()
	end
	for _, sectionHeader in self.SectionHeaders do sectionHeader:Destroy() end
	self.Cards = {}
	self.SectionHeaders = {}
	local currentCategory
	local layoutOrder = 0
	for _, recipeId in ipairs(getRecipesForType(craftType)) do
		local recipe = RecipeDefinitions[recipeId]
		local category = recipe.UiCategory or "Misc"
		if craftType == "Workbench" and category ~= currentCategory then
			currentCategory = category
			layoutOrder += 1
			self:_buildSectionHeader(category, layoutOrder)
		end
		layoutOrder += 1
		self:_buildCard(recipeId, layoutOrder)
	end
	self:_renderAvailability()
end

function controller:_showInventory(resetCraftContext)
	self.Panel.Visible = false
	local stationPanel = InventoryController.MainFrame:FindFirstChild("StationPanel")
	if stationPanel then
		stationPanel.Visible = false
	end
	if resetCraftContext then
		self.CraftType = "Basic"
		self.Station = nil
		self.StationState = nil
	end
	setInventoryContentVisible(true)
	InventoryController.MainFrame.Title.Text = "INVENTAIRE"
	InventoryController.MainFrame.Subtitle.Visible = true
	self.TabButton.Text = "FABRICATION"
end

function controller:_build()
	local mainFrame = InventoryController.MainFrame
	local tabButton = Instance.new("TextButton")
	tabButton.Name = "CraftTabButton"
	tabButton.Size = UDim2.fromOffset(104, 34)
	tabButton.Position = UDim2.new(0.5, 0, 0, 14)
	tabButton.AnchorPoint = Vector2.new(0.5, 0)
	tabButton.BackgroundColor3 = Color3.fromRGB(32, 40, 53)
	tabButton.BorderSizePixel = 0
	tabButton.Text = "FABRICATION"
	tabButton.TextColor3 = Color3.fromRGB(213, 222, 234)
	tabButton.Font = Enum.Font.GothamSemibold
	tabButton.TextSize = 10
	tabButton.ZIndex = 20
	tabButton.Parent = mainFrame
	addCorner(tabButton, 8)
	self.TabButton = tabButton

	local panel = Instance.new("Frame")
	panel.Name = "CraftPanel"
	panel.Size = UDim2.new(1, -32, 1, -70)
	panel.Position = UDim2.fromOffset(16, 55)
	panel.BackgroundTransparency = 1
	panel.Visible = false
	panel.Parent = mainFrame
	self.Panel = panel

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 22)
	header.BackgroundTransparency = 1
	header.Text = "CRAFT DE BASE"
	header.TextColor3 = Color3.fromRGB(170, 184, 201)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 11
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = panel
	self.Header = header

	local feedback = Instance.new("TextLabel")
	feedback.Size = UDim2.new(0.55, 0, 0, 22)
	feedback.Position = UDim2.new(1, 0, 0, 0)
	feedback.AnchorPoint = Vector2.new(1, 0)
	feedback.BackgroundTransparency = 1
	feedback.Text = ""
	feedback.TextColor3 = Color3.fromRGB(132, 206, 164)
	feedback.Font = Enum.Font.GothamSemibold
	feedback.TextSize = 10
	feedback.TextXAlignment = Enum.TextXAlignment.Right
	feedback.Parent = panel
	self.Feedback = feedback

	local list = Instance.new("ScrollingFrame")
	list.Name = "RecipeList"
	list.Size = UDim2.new(1, 0, 1, -28)
	list.Position = UDim2.fromOffset(0, 28)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = Color3.fromRGB(96, 111, 130)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = list
	self.List = list

	tabButton.Activated:Connect(function()
		if panel.Visible then
			self:_showInventory(false)
		else
			self:_showCraft(self.Station and "Workbench" or "Basic", self.Station)
		end
	end)
end

function controller:Start()
	if self.Started then
		return
	end
	self.Started = true
	self:_build()
	self.Inventory = InventoryController.Inventory

	inventoryRemote.OnClientEvent:Connect(function(state)
		self.Inventory = state
		self:_renderAvailability()
	end)
	craftResult.OnClientEvent:Connect(function(success, recipeId, reason)
		if success then
			self.Feedback.TextColor3 = Color3.fromRGB(132, 206, 164)
			self.Feedback.Text = "FABRICATION RÉUSSIE"
		else
			self.Feedback.TextColor3 = Color3.fromRGB(224, 132, 132)
			self.Feedback.Text = reason == "InventoryFull" and "INVENTAIRE PLEIN" or "FABRICATION IMPOSSIBLE"
		end
		local feedbackText = self.Feedback.Text
		task.delay(1.5, function()
			if self.Feedback.Text == feedbackText then
				self.Feedback.Text = ""
			end
		end)
	end)
	openWorkbench.OnClientEvent:Connect(function(station)
		InventoryController:SetOpen(true)
		self:_showCraft("Workbench", station)
	end)
	stationOpened.OnClientEvent:Connect(function(station, state)
		if state.StationType == "CraftingTable" then
			self.Station = station
			self.StationState = state
			self:_renderAvailability()
		end
	end)
	stationStateChanged.OnClientEvent:Connect(function(station, state)
		if station == self.Station and state.StationType == "CraftingTable" then
			self.StationState = state
			self:_renderAvailability()
		end
	end)
	InventoryController.OpenChanged.Event:Connect(function(open)
		if not open then
			self:_showInventory(true)
		end
	end)
	local rangeRefresh = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		rangeRefresh = rangeRefresh + deltaTime
		if rangeRefresh >= 0.25 then
			rangeRefresh = 0
			if self.Panel.Visible and self.CraftType == "Workbench" then
				self:_renderAvailability()
			end
		end
	end)

end

return controller
