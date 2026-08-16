local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local inventoryStateChanged = ReplicatedStorage:WaitForChild("InventoryStateChanged")
local worldDropRequest = ReplicatedStorage:WaitForChild("WorldDropRequest")
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

function controller:Start()
	inventoryStateChanged.OnClientEvent:Connect(function(state) self.Inventory = state end)
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
