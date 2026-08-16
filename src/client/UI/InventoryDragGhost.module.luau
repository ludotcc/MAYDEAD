local InventoryDragGhost = {}

function InventoryDragGhost.Create(screenGui, slotData, renderSlot)
	local ghost = Instance.new("Frame")
	ghost.Name = "InventoryDragGhost"
	ghost.Size = UDim2.fromOffset(50, 50)
	ghost.AnchorPoint = Vector2.new(0.5, 0.5)
	ghost.BackgroundColor3 = Color3.fromRGB(38, 53, 68)
	ghost.BackgroundTransparency = 0.08
	ghost.BorderSizePixel = 0
	ghost.ZIndex = 100
	ghost.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = ghost
	renderSlot(ghost, slotData)
	return ghost
end

return InventoryDragGhost
