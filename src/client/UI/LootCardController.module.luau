local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Shared")
local ItemDefinitions = require(shared:WaitForChild("Definitions"):WaitForChild("ItemDefinitions"))
local ItemIconConfig = require(shared:WaitForChild("Config"):WaitForChild("ItemIconConfig"))

local MAX_VISIBLE_CARDS = 3
local AGGREGATION_WINDOW = 1.25
local HOLD_DURATION = 2

local controller = {Started = false, Cards = {}, Revision = 0}

local function isValidAssetId(assetId)
	return typeof(assetId) == "string" and string.match(assetId, "^rbxassetid://%d+$") ~= nil
end

function controller:_removeCard(card)
	if card.Removing then return end
	card.Removing = true
	for index, candidate in ipairs(self.Cards) do
		if candidate == card then
			table.remove(self.Cards, index)
			break
		end
	end
	local tween = TweenService:Create(card.Frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.fromOffset(18, 0),
		BackgroundTransparency = 1,
	})
	tween:Play()
	tween.Completed:Once(function()
		if card.Frame.Parent then card.Frame:Destroy() end
	end)
end

function controller:_scheduleRemoval(card)
	card.Revision += 1
	local revision = card.Revision
	task.delay(HOLD_DURATION, function()
		if card.Revision == revision then self:_removeCard(card) end
	end)
end

function controller:_createCard(itemId, quantity)
	local definition = ItemDefinitions[itemId]
	if not definition then return end
	local frame = Instance.new("Frame")
	frame.Name = itemId .. "LootCard"
	frame.Size = UDim2.fromOffset(238, 72)
	frame.BackgroundColor3 = Color3.fromRGB(9, 14, 20)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromOffset(18, 0)
	frame.Parent = self.List
	local frameCorner = Instance.new("UICorner", frame)
	frameCorner.CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(67, 94, 105)
	stroke.Transparency = 0.35

	local accent = Instance.new("Frame", frame)
	accent.Size = UDim2.new(0, 3, 1, -18)
	accent.Position = UDim2.fromOffset(0, 9)
	accent.BackgroundColor3 = Color3.fromRGB(76, 157, 255)
	accent.BorderSizePixel = 0
	local accentCorner = Instance.new("UICorner", accent)
	accentCorner.CornerRadius = UDim.new(1, 0)

	local icon = Instance.new("ImageLabel", frame)
	icon.Size = UDim2.fromOffset(46, 46)
	icon.Position = UDim2.fromOffset(14, 13)
	icon.BackgroundColor3 = Color3.fromRGB(17, 24, 32)
	icon.BackgroundTransparency = 0.15
	icon.Image = isValidAssetId(ItemIconConfig[itemId]) and ItemIconConfig[itemId] or ""
	icon.ScaleType = Enum.ScaleType.Fit
	local iconCorner = Instance.new("UICorner", icon)
	iconCorner.CornerRadius = UDim.new(0, 9)

	local name = Instance.new("TextLabel", frame)
	name.Size = UDim2.new(1, -124, 0, 24)
	name.Position = UDim2.fromOffset(72, 12)
	name.BackgroundTransparency = 1
	name.Text = string.upper(definition.DisplayName or itemId)
	name.TextColor3 = Color3.fromRGB(229, 235, 239)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 13
	name.TextXAlignment = Enum.TextXAlignment.Left

	local subtitle = Instance.new("TextLabel", frame)
	subtitle.Size = UDim2.new(1, -124, 0, 18)
	subtitle.Position = UDim2.fromOffset(72, 38)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "AJOUTÉ À L'INVENTAIRE"
	subtitle.TextColor3 = Color3.fromRGB(124, 145, 157)
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextSize = 9
	subtitle.TextXAlignment = Enum.TextXAlignment.Left

	local amount = Instance.new("TextLabel", frame)
	amount.Size = UDim2.fromOffset(48, 32)
	amount.Position = UDim2.new(1, -58, 0.5, -16)
	amount.BackgroundTransparency = 1
	amount.Text = "+" .. tostring(quantity)
	amount.TextColor3 = Color3.fromRGB(107, 205, 146)
	amount.Font = Enum.Font.GothamBold
	amount.TextSize = 17
	amount.TextXAlignment = Enum.TextXAlignment.Right

	local scale = Instance.new("UIScale", frame)
	scale.Scale = 0.96
	local card = {Frame = frame, Amount = amount, ItemId = itemId, Quantity = quantity, LastUpdate = os.clock(), Revision = 0}
	table.insert(self.Cards, card)
	TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.08,
	}):Play()
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	self:_scheduleRemoval(card)
	while #self.Cards > MAX_VISIBLE_CARDS do self:_removeCard(self.Cards[1]) end
end

function controller:_showGrant(grant)
	if typeof(grant) ~= "table" or typeof(grant.ItemId) ~= "string" or typeof(grant.Quantity) ~= "number" or grant.Quantity <= 0 then return end
	local now = os.clock()
	for _, card in ipairs(self.Cards) do
		if not card.Removing and card.ItemId == grant.ItemId and now - card.LastUpdate <= AGGREGATION_WINDOW then
			card.Quantity += grant.Quantity
			card.LastUpdate = now
			card.Amount.Text = "+" .. tostring(card.Quantity)
			self:_scheduleRemoval(card)
			return
		end
	end
	self:_createCard(grant.ItemId, grant.Quantity)
end

function controller:Start()
	if self.Started then return end
	self.Started = true
	local gui = Instance.new("ScreenGui")
	gui.Name = "MAYDEADLootCards"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.DisplayOrder = 18
	gui.Parent = playerGui
	local list = Instance.new("Frame")
	list.Name = "LootCardStack"
	list.Size = UDim2.fromOffset(238, 236)
	list.Position = UDim2.new(1, -18, 0.32, 0)
	list.AnchorPoint = Vector2.new(1, 0)
	list.BackgroundTransparency = 1
	list.Parent = gui
	local layout = Instance.new("UIListLayout", list)
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	self.List = list
	ReplicatedStorage:WaitForChild("InventoryStateChanged").OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" then self:_showGrant(payload.GrantedItem) end
	end)
	local function updateVisibility()
		gui.Enabled = player:GetAttribute("SessionStarted") == true and player:GetAttribute("ReturningToMenu") ~= true
	end
	player:GetAttributeChangedSignal("SessionStarted"):Connect(updateVisibility)
	player:GetAttributeChangedSignal("ReturningToMenu"):Connect(updateVisibility)
	updateVisibility()
end

return controller
