local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local controller = {Started = false}

local function rectanglesOverlap(first, second, paddingAmount)
	local paddingValue = paddingAmount or 0
	local firstPosition, firstSize = first.AbsolutePosition, first.AbsoluteSize
	local secondPosition, secondSize = second.AbsolutePosition, second.AbsoluteSize
	return firstPosition.X < secondPosition.X + secondSize.X + paddingValue
		and firstPosition.X + firstSize.X + paddingValue > secondPosition.X
		and firstPosition.Y < secondPosition.Y + secondSize.Y + paddingValue
		and firstPosition.Y + firstSize.Y + paddingValue > secondPosition.Y
end

local function touchIsPreferred()
	local preferred = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	pcall(function()
		preferred = UserInputService.PreferredInput == Enum.PreferredInput.Touch
	end)
	return preferred
end

function controller:_findNativeJumpButton()
	local touchGui = playerGui:FindFirstChild("TouchGui")
	local touchControlFrame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jumpButton = touchControlFrame and touchControlFrame:FindFirstChild("JumpButton")
	return jumpButton and jumpButton:IsA("GuiButton") and jumpButton or nil
end

function controller:_layoutNativeButton(jumpButton)
	local revision = (self.LayoutRevision or 0) + 1
	self.LayoutRevision = revision
	task.defer(function()
		if self.LayoutRevision ~= revision or not jumpButton.Visible then return end
		local hotbar = playerGui:FindFirstChild("MAYDEADHotbar", true)
		if hotbar and hotbar:IsA("GuiObject") and hotbar.Visible and rectanglesOverlap(jumpButton, hotbar, 10) then
			local targetBottom = hotbar.AbsolutePosition.Y - 10
			local currentBottom = jumpButton.AbsolutePosition.Y + jumpButton.AbsoluteSize.Y
			jumpButton.Position = jumpButton.Position + UDim2.fromOffset(0, targetBottom - currentBottom)
		end
		jumpButton:SetAttribute(
			"MAYDEADHotbarCollisionFree",
			not (hotbar and hotbar:IsA("GuiObject") and rectanglesOverlap(jumpButton, hotbar, 0))
		)
	end)
end

function controller:_bindNativeButton(jumpButton)
	if self.BoundJumpButton == jumpButton then return end
	self.BoundJumpButton = jumpButton
	jumpButton:GetPropertyChangedSignal("Visible"):Connect(function()
		local shouldBeVisible = player:GetAttribute("SessionStarted") == true
			and player:GetAttribute("ReturningToMenu") ~= true
			and touchIsPreferred()
		if jumpButton.Visible ~= shouldBeVisible then self:_refresh() end
	end)
end

function controller:_refresh()
	local jumpButton = self:_findNativeJumpButton()
	if not jumpButton then return end
	self:_bindNativeButton(jumpButton)
	local gameplayActive = player:GetAttribute("SessionStarted") == true
		and player:GetAttribute("ReturningToMenu") ~= true
	jumpButton.Visible = gameplayActive and touchIsPreferred()
	jumpButton:SetAttribute("MAYDEADNativeJump", true)
	if jumpButton.Visible then self:_layoutNativeButton(jumpButton) end
end

function controller:Start()
	if self.Started then return end
	self.Started = true
	player:GetAttributeChangedSignal("SessionStarted"):Connect(function() self:_refresh() end)
	player:GetAttributeChangedSignal("ReturningToMenu"):Connect(function() self:_refresh() end)
	playerGui.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "JumpButton" then task.defer(function() self:_refresh() end) end
	end)
	pcall(function()
		UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function() self:_refresh() end)
	end)
	local function bindCamera(camera)
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() self:_refresh() end)
		end
	end
	bindCamera(workspace.CurrentCamera)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		bindCamera(workspace.CurrentCamera)
		self:_refresh()
	end)
	task.defer(function() self:_refresh() end)
end

return controller
