local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local controller = {}

local function corner(parent, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius)
	value.Parent = parent
end

function controller:Start()
	local player = Players.LocalPlayer
	local remote = ReplicatedStorage:WaitForChild("CheetahTamingFeedback")
	local gui = Instance.new("ScreenGui")
	gui.Name = "CheetahTamingFeedbackGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 11
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.Parent = player:WaitForChild("PlayerGui")

	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(280, 92)
	card.Position = UDim2.fromScale(0.5, 0.04)
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.BackgroundColor3 = Color3.fromRGB(8, 15, 20)
	card.BackgroundTransparency = 0.12
	card.BorderSizePixel = 0
	card.Visible = false
	card.Parent = gui
	corner(card, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(57, 143, 159)
	stroke.Transparency = 0.45
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 20)
	title.Position = UDim2.fromOffset(12, 10)
	title.BackgroundTransparency = 1
	title.Text = "GUÉPARD  •  CONFIANCE"
	title.TextColor3 = Color3.fromRGB(220, 232, 237)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local rail = Instance.new("Frame")
	rail.Size = UDim2.new(1, -24, 0, 9)
	rail.Position = UDim2.fromOffset(12, 39)
	rail.BackgroundColor3 = Color3.fromRGB(20, 31, 37)
	rail.BorderSizePixel = 0
	rail.Parent = card
	corner(rail, 5)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(66, 190, 211)
	fill.BorderSizePixel = 0
	fill.Parent = rail
	corner(fill, 5)

	local amount = Instance.new("TextLabel")
	amount.Size = UDim2.new(1, -24, 0, 22)
	amount.Position = UDim2.fromOffset(12, 57)
	amount.BackgroundTransparency = 1
	amount.Text = "0 / 100"
	amount.TextColor3 = Color3.fromRGB(238, 242, 245)
	amount.Font = Enum.Font.GothamBold
	amount.TextSize = 14
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.Parent = card
	local gainLabel = amount:Clone()
	gainLabel.Size = UDim2.fromOffset(80, 22)
	gainLabel.Position = UDim2.new(1, -92, 0, 57)
	gainLabel.Text = ""
	gainLabel.TextColor3 = Color3.fromRGB(236, 208, 119)
	gainLabel.TextXAlignment = Enum.TextXAlignment.Right
	gainLabel.Parent = card

	local revision = 0
	local function hide()
		revision += 1
		local hideRevision = revision
		local tween = TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 1})
		tween:Play()
		tween.Completed:Wait()
		if revision == hideRevision then
			card.Visible = false
			card.BackgroundTransparency = 0.12
		end
	end

	remote.OnClientEvent:Connect(function(action, payload)
		payload = typeof(payload) == "table" and payload or {}
		if action == "TimedOut" then hide(); return end
		if action == "Blocked" then
			revision += 1
			local blockedRevision = revision
			card.Visible = true
			title.Text = "COMPAGNON DÉJÀ APPRIVOISÉ"
			gainLabel.Text = ""
			task.delay(2.5, function()
				if revision == blockedRevision then
					hide()
					title.Text = "GUÉPARD  •  CONFIANCE"
				end
			end)
			return
		end
		if action ~= "Progress" and action ~= "Completed" then return end
		revision += 1
		local currentRevision = revision
		local trust = math.clamp(tonumber(payload.Trust) or 0, 0, 100)
		local gain = math.max(0, tonumber(payload.Gain) or 0)
		card.Visible = true
		card.BackgroundTransparency = 0.12
		amount.Text = string.format("%d / 100", trust)
		gainLabel.Text = gain > 0 and string.format("+%d", gain) or ""
		TweenService:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
			Size = UDim2.fromScale(trust / 100, 1),
		}):Play()
		task.delay(1.2, function()
			if revision == currentRevision then gainLabel.Text = "" end
		end)
		if action == "Completed" then
			title.Text = "GUÉPARD APPRIVOISÉ"
			task.delay(1.6, function()
				if revision == currentRevision then
					hide()
					title.Text = "GUÉPARD  •  CONFIANCE"
				end
			end)
		else
			title.Text = "GUÉPARD  •  CONFIANCE"
		end
	end)
	player:GetAttributeChangedSignal("SessionStarted"):Connect(function()
		if player:GetAttribute("SessionStarted") ~= true then task.spawn(hide) end
	end)
end

return controller
