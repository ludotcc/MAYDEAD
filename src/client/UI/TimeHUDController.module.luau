local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TimeHUDController = {}

local function buildHUD()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local legacyHUD = playerGui:FindFirstChild("MaydeadTimeHUD")
	if legacyHUD then legacyHUD:Destroy() end
	local inventoryGui = playerGui:WaitForChild("MAYDEADInventoryUI")
	local mainFrame = inventoryGui:WaitForChild("MainFrame")
	local mount = mainFrame:WaitForChild("DayAgePanel")
	local existingContent = mount:FindFirstChild("TimeHUDContent")
	if existingContent then existingContent:Destroy() end

	local timeState = ReplicatedStorage:WaitForChild("TimeState")
	local yearsOnIslandValue = timeState:WaitForChild("YearsOnIsland")
	local cycleProgressValue = timeState:WaitForChild("CycleProgress")

	local root = Instance.new("Frame")
	root.Name = "TimeHUDContent"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(9, 12, 18)
	root.BackgroundTransparency = 0.08
	root.Parent = mount

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = root

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.9
	stroke.Thickness = 1
	stroke.Parent = root

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 29, 39)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 13, 20)),
	})
	gradient.Parent = root

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.Parent = root

	local topRow = Instance.new("Frame")
	topRow.Name = "TopRow"
	topRow.Size = UDim2.new(0, 88, 1, 0)
	topRow.Position = UDim2.new(1, -88, 0, 0)
	topRow.BackgroundTransparency = 1
	topRow.Parent = root

	local ageLabel = Instance.new("TextLabel")
	ageLabel.Name = "YearsOnIslandLabel"
	ageLabel.Size = UDim2.new(1, 0, 1, 0)
	ageLabel.BackgroundTransparency = 1
	ageLabel.Text = "ANNÉE " .. tostring(yearsOnIslandValue.Value)
	ageLabel.TextColor3 = Color3.fromRGB(245, 248, 252)
	ageLabel.TextXAlignment = Enum.TextXAlignment.Right
	ageLabel.TextYAlignment = Enum.TextYAlignment.Center
	ageLabel.Font = Enum.Font.GothamBold
	ageLabel.TextSize = 17
	ageLabel.Parent = topRow

	local ageScale = Instance.new("UIScale")
	ageScale.Scale = 1
	ageScale.Parent = ageLabel

	local cycleRow = Instance.new("Frame")
	cycleRow.Name = "CycleRow"
	cycleRow.Size = UDim2.new(0, 196, 1, 0)
	cycleRow.BackgroundTransparency = 1
	cycleRow.Parent = root

	local leftIcon = Instance.new("TextLabel")
	leftIcon.Name = "LeftIcon"
	leftIcon.Size = UDim2.new(0, 16, 0, 16)
	leftIcon.Position = UDim2.new(0, 0, 0.5, -8)
	leftIcon.BackgroundTransparency = 1
	leftIcon.Text = "☀"
	leftIcon.TextColor3 = Color3.fromRGB(255, 221, 153)
	leftIcon.Font = Enum.Font.GothamBold
	leftIcon.TextSize = 14
	leftIcon.Parent = cycleRow

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, -28, 0, 1)
	track.Position = UDim2.new(0, 12, 0.5, 0)
	track.BackgroundColor3 = Color3.fromRGB(82, 92, 108)
	track.BackgroundTransparency = 0.65
	track.Parent = cycleRow

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 999)
	trackCorner.Parent = track

	local trackStroke = Instance.new("UIStroke")
	trackStroke.Color = Color3.fromRGB(255, 255, 255)
	trackStroke.Transparency = 0.95
	trackStroke.Thickness = 1
	trackStroke.Parent = track

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 6, 0, 6)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = Color3.fromRGB(255, 235, 185)
	knob.Parent = track

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(0, 999)
	knobCorner.Parent = knob

	local rightIcon = Instance.new("TextLabel")
	rightIcon.Name = "RightIcon"
	rightIcon.Size = UDim2.new(0, 14, 0, 14)
	rightIcon.Position = UDim2.new(1, -14, 0.5, -7)
	rightIcon.AnchorPoint = Vector2.new(1, 0)
	rightIcon.BackgroundTransparency = 1
	rightIcon.Text = "☾"
	rightIcon.TextColor3 = Color3.fromRGB(162, 201, 255)
	rightIcon.Font = Enum.Font.GothamBold
	rightIcon.TextSize = 12
	rightIcon.Parent = cycleRow

	local lastYearsOnIsland = yearsOnIslandValue.Value

	local function updateAgeAppearance()
		ageLabel.Text = "ANNÉE " .. tostring(yearsOnIslandValue.Value)

		if yearsOnIslandValue.Value ~= lastYearsOnIsland then
			local tween = TweenService:Create(
				ageScale,
				TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Scale = 1.03,
				}
			)

			tween:Play()

			tween.Completed:Connect(function()
				TweenService:Create(
					ageScale,
					TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Scale = 1,
					}
				):Play()
			end)
		end

		lastYearsOnIsland = yearsOnIslandValue.Value
	end

	local function updateCycleIndicator()
		local progress = math.clamp(cycleProgressValue.Value, 0, 1)

		local targetPosition = UDim2.new(
			progress,
			0,
			0.5,
			0
		)

		local tween = TweenService:Create(
			knob,
			TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = targetPosition,
			}
		)

		tween:Play()
	end

	updateAgeAppearance()
	updateCycleIndicator()

	yearsOnIslandValue.Changed:Connect(updateAgeAppearance)
	cycleProgressValue.Changed:Connect(updateCycleIndicator)
end

function TimeHUDController:Start()
	task.spawn(buildHUD)
end

return TimeHUDController
