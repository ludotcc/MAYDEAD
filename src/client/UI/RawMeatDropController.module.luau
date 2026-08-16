local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local inventoryStateChanged = ReplicatedStorage:WaitForChild("InventoryStateChanged")
local worldDropRequest = ReplicatedStorage:WaitForChild("WorldDropRequest")
local CheetahConfig = require(ReplicatedStorage.Shared.Config.CheetahConfig)
local InventoryController = require(script.Parent:WaitForChild("InventoryController.module"))

local controller = {Inventory = nil}

local function activeItem(state)
	local quick = state and state.ActiveQuickSlot or 0
	local slot = quick > 0 and state.Slots and state.Slots[20 + quick]
	return slot and slot.ItemId or nil
end

local function pointerIsOverInteractiveGui()
	local position = UserInputService:GetMouseLocation()
	local ok, objects = pcall(function() return playerGui:GetGuiObjectsAtPosition(position.X, position.Y) end)
	if not ok then return true end
	for _, object in objects do
		if object.Visible and (object:IsA("GuiButton") or object.Active) then return true end
	end
	return false
end

local function isUsableWildCheetah(model)
	return model:IsA("Model") and model:GetAttribute("AnimalType") == "Cheetah"
		and model:GetAttribute("Tamed") ~= true and model:GetAttribute("IsDead") ~= true
end

local function cheetahPosition(model)
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	return root and root.Position or nil
end

function controller:Start()
	inventoryStateChanged.OnClientEvent:Connect(function(state) self.Inventory = state end)
	local gui = Instance.new("ScreenGui")
	gui.Name = "RawMeatTouchActionGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 12
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.Parent = playerGui
	local button = Instance.new("TextButton")
	button.Name = "TouchFeedCheetahButton"
	button.Size = UDim2.fromOffset(156, 56)
	button.Position = UDim2.new(1, -24, 0.56, 0)
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(25, 91, 108)
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = "NOURRIR"
	button.TextColor3 = Color3.fromRGB(231, 239, 244)
	button.TextSize = 14
	button.Visible = false
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(79, 178, 194)
	stroke.Transparency = 0.15
	stroke.Thickness = 1.5
	stroke.Parent = button
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(button, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(36, 122, 139)}):Play()
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(button, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(25, 91, 108)}):Play()
		end
	end)
	button.Activated:Connect(function()
		if button.Visible then worldDropRequest:FireServer("DropRawMeat") end
	end)
	local cheetahs = setmetatable({}, {__mode = "k"})
	for _, descendant in workspace:GetDescendants() do
		if isUsableWildCheetah(descendant) then cheetahs[descendant] = true end
	end
	workspace.DescendantAdded:Connect(function(descendant)
		if isUsableWildCheetah(descendant) then cheetahs[descendant] = true end
	end)
	workspace.DescendantRemoving:Connect(function(descendant) cheetahs[descendant] = nil end)
	local lastVisibilityUpdate = 0
	RunService.Heartbeat:Connect(function()
		if os.clock() - lastVisibilityUpdate < 0.15 then return end
		lastVisibilityUpdate = os.clock()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local available = UserInputService.TouchEnabled and activeItem(self.Inventory) == "RawMeat"
			and player:GetAttribute("SessionStarted") == true and player:GetAttribute("InMainMenu") ~= true
			and player:GetAttribute("ReturningToMenu") ~= true and not InventoryController.Open
			and not InventoryController.DragState and not InventoryController.DragGhost
			and humanoid and humanoid.Health > 0 and root and not character:FindFirstChildOfClass("Tool")
		if available then
			available = false
			for cheetah in cheetahs do
				local position = isUsableWildCheetah(cheetah) and cheetahPosition(cheetah)
				if position and (root.Position - position).Magnitude <= CheetahConfig.FOOD_DETECTION_RADIUS then
					available = true
					break
				end
			end
		end
		button.Visible = available == true
	end)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then return end
		if player:GetAttribute("SessionStarted") ~= true or player:GetAttribute("InMainMenu") == true
			or player:GetAttribute("ReturningToMenu") == true
		then return end
		if InventoryController.Open or InventoryController.DragState or InventoryController.DragGhost then return end
		if UserInputService:GetFocusedTextBox() or pointerIsOverInteractiveGui() then return end
		if activeItem(self.Inventory) ~= "RawMeat" then return end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 or character:FindFirstChildOfClass("Tool") then return end
		worldDropRequest:FireServer("DropRawMeat")
	end)
end

return controller
