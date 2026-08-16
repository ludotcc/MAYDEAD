local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local SurvivalConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("SurvivalConfig")
)
local FlaskConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("FlaskConfig"))
local drinkRequest = ReplicatedStorage:WaitForChild("DrinkRequest")
local drinkResult = ReplicatedStorage:WaitForChild("DrinkResult")
local survivalStateChanged = ReplicatedStorage:WaitForChild("SurvivalStateChanged")
local inventoryStateChanged = ReplicatedStorage:WaitForChild("InventoryStateChanged")
local flaskRequest = ReplicatedStorage:WaitForChild("FlaskRequest")
local flaskResult = ReplicatedStorage:WaitForChild("FlaskResult")

local ACTION_NAME = "MAYDEADDrink"
local CHECK_INTERVAL = 0.25

local DrinkController = {}
DrinkController.__index = DrinkController

function DrinkController.new()
	return setmetatable({
		Available = false,
		Thirst = 100,
		Underwater = false,
		Prompt = nil,
		Feedback = nil,
		ActionFeedback = nil,
		FlaskUseButton = nil,
		ActiveFlask = false,
		FlaskCharges = 0,
		FillAvailable = false,
		Running = false,
	}, DrinkController)
end

local function isNearTerrainWater(character)
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local distance = SurvivalConfig.DRINK_INTERACTION_DISTANCE
	local resolution = 4
	local region = Region3.new(
		rootPart.Position - Vector3.new(distance, distance, distance),
		rootPart.Position + Vector3.new(distance, distance, distance)
	):ExpandToGrid(resolution)
	local succeeded, materials, occupancy = pcall(function()
		return workspace.Terrain:ReadVoxels(region, resolution)
	end)
	if not succeeded then
		return false
	end

	local regionCorner = region.CFrame.Position - (region.Size / 2)
	for x = 1, #materials do
		for y = 1, #materials[x] do
			for z = 1, #materials[x][y] do
				if materials[x][y][z] == Enum.Material.Water and occupancy[x][y][z] > 0 then
					local cellCenter = regionCorner + Vector3.new(
						(x - 0.5) * resolution,
						(y - 0.5) * resolution,
						(z - 0.5) * resolution
					)
					if (cellCenter - rootPart.Position).Magnitude <= distance then
						return true
					end
				end
			end
		end
	end
	return false
end

function DrinkController:_buildPrompt()
	local existing = playerGui:FindFirstChild("MAYDEADDrinkPrompt")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MAYDEADDrinkPrompt"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 15
	screenGui.Parent = playerGui

	local prompt = Instance.new("TextButton")
	prompt.Name = "DrinkPrompt"
	prompt.Size = UDim2.fromOffset(112, 34)
	prompt.Position = UDim2.new(0.5, 0, 1, -92)
	prompt.AnchorPoint = Vector2.new(0.5, 1)
	prompt.BackgroundColor3 = Color3.fromRGB(11, 16, 23)
	prompt.BackgroundTransparency = 0.12
	prompt.BorderSizePixel = 0
	prompt.AutoButtonColor = false
	prompt.Text = UserInputService.TouchEnabled and "BOIRE" or "[F]  BOIRE"
	prompt.TextColor3 = Color3.fromRGB(220, 239, 248)
	prompt.Font = Enum.Font.GothamSemibold
	prompt.TextSize = 12
	prompt.Visible = false
	prompt.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = prompt

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(106, 178, 211)
	stroke.Transparency = 0.58
	stroke.Thickness = 1
	stroke.Parent = prompt

	local feedback = Instance.new("TextLabel")
	feedback.Size = UDim2.new(1, 0, 0, 18)
	feedback.Position = UDim2.new(0.5, 0, 0, -5)
	feedback.AnchorPoint = Vector2.new(0.5, 1)
	feedback.BackgroundTransparency = 1
	feedback.Text = ""
	feedback.TextColor3 = Color3.fromRGB(132, 211, 239)
	feedback.Font = Enum.Font.GothamSemibold
	feedback.TextSize = 11
	feedback.Parent = prompt

	prompt.Activated:Connect(function()
		if self.FillAvailable then
			flaskRequest:FireServer("Fill")
		elseif self.Available then
			drinkRequest:FireServer()
		end
	end)

	self.Prompt = prompt
	self.Feedback = feedback
	local actionFeedback = feedback:Clone()
	actionFeedback.Name = "FlaskFeedback"
	actionFeedback.Size = UDim2.fromOffset(240, 18)
	actionFeedback.Position = UDim2.new(0.5, 0, 1, -172)
	actionFeedback.AnchorPoint = Vector2.new(0.5, 1)
	actionFeedback.Parent = screenGui
	self.ActionFeedback = actionFeedback

	local flaskUseButton = prompt:Clone()
	flaskUseButton.Name = "FlaskUsePrompt"
	flaskUseButton.Position = UDim2.new(0.5, 0, 1, -134)
	flaskUseButton.Text = "BOIRE"
	flaskUseButton.Visible = false
	flaskUseButton.Parent = screenGui
	local clonedFeedback = flaskUseButton:FindFirstChildOfClass("TextLabel")
	if clonedFeedback then
		clonedFeedback:Destroy()
	end
	flaskUseButton.Activated:Connect(function()
		if self.ActiveFlask then
			flaskRequest:FireServer("Use")
		end
	end)
	self.FlaskUseButton = flaskUseButton
end

function DrinkController:_refreshAvailability()
	local nearUsableWater = not self.Underwater and isNearTerrainWater(player.Character)
	self.FillAvailable = self.ActiveFlask and self.FlaskCharges < FlaskConfig.MAX_WATER_CHARGES and nearUsableWater
	self.Available = not self.FillAvailable and self.Thirst < 100 and nearUsableWater
	if self.Prompt then
		self.Prompt.Visible = self.FillAvailable or self.Available
		self.Prompt.Text = self.FillAvailable
			and (UserInputService.TouchEnabled and "REMPLIR" or "[F]  REMPLIR")
			or (UserInputService.TouchEnabled and "BOIRE" or "[F]  BOIRE")
	end
	if self.FlaskUseButton then
		self.FlaskUseButton.Visible = UserInputService.TouchEnabled and self.ActiveFlask
	end
end

function DrinkController:_showFeedback(text)
	if not self.ActionFeedback then
		return
	end
	self.ActionFeedback.Text = text
	task.delay(0.8, function()
		if self.ActionFeedback and self.ActionFeedback.Text == text then
			self.ActionFeedback.Text = ""
		end
	end)
end

function DrinkController:Start()
	if self.Running then
		return
	end
	self.Running = true
	self:_buildPrompt()

	ContextActionService:BindActionAtPriority(
		ACTION_NAME,
		function(_, inputState)
			if inputState == Enum.UserInputState.Begin and self.FillAvailable then
				flaskRequest:FireServer("Fill")
				return Enum.ContextActionResult.Sink
			elseif inputState == Enum.UserInputState.Begin and self.Available then
				drinkRequest:FireServer()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.F
	)

	survivalStateChanged.OnClientEvent:Connect(function(state)
		self.Thirst = state.Thirst or self.Thirst
		self.Underwater = state.Underwater == true
	end)

	inventoryStateChanged.OnClientEvent:Connect(function(state)
		local activeQuickSlot = state.ActiveQuickSlot or 0
		local slot = activeQuickSlot > 0 and state.Slots and state.Slots[20 + activeQuickSlot]
		self.ActiveFlask = type(slot) == "table" and slot.ItemId == "Flask"
		self.FlaskCharges = self.ActiveFlask
			and math.clamp(
				math.floor(slot.WaterCharges or FlaskConfig.INITIAL_WATER_CHARGES),
				0,
				FlaskConfig.MAX_WATER_CHARGES
			)
			or FlaskConfig.INITIAL_WATER_CHARGES
		self:_refreshAvailability()
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if not gameProcessedEvent and input.UserInputType == Enum.UserInputType.MouseButton1 and self.ActiveFlask then
			flaskRequest:FireServer("Use")
		end
	end)

	drinkResult.OnClientEvent:Connect(function()
		if self.Feedback then
			self.Feedback.Text = "HYDRATÉ"
			task.delay(0.8, function()
				if self.Feedback then
					self.Feedback.Text = ""
				end
			end)
		end
	end)

	flaskResult.OnClientEvent:Connect(function(action, success, reason)
		if success then
			self:_showFeedback(action == "Fill" and "FLASK REMPLIE" or "HYDRATÉ")
		elseif reason == "Empty" then
			self:_showFeedback("FLASK VIDE")
		elseif reason == "ThirstFull" then
			self:_showFeedback("SOIF DÉJÀ PLEINE")
		elseif reason == "Full" then
			self:_showFeedback("FLASK PLEINE")
		end
	end)

	task.spawn(function()
		while self.Running do
			self:_refreshAvailability()
			task.wait(CHECK_INTERVAL)
		end
	end)
end

return DrinkController.new()
