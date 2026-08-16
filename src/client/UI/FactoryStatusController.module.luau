local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FactoryConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("FactoryConfig"))
local opened = ReplicatedStorage:WaitForChild("RecyclerStatusOpened")
local changed = ReplicatedStorage:WaitForChild("RecyclerStatusChanged")
local closed = ReplicatedStorage:WaitForChild("RecyclerStatusClosed")
local finalChanged = ReplicatedStorage:WaitForChild("FinalFactoryStateChanged")
local finalRequest = ReplicatedStorage:WaitForChild("FinalFactoryRequest")
local finalObjectiveCompleted = ReplicatedStorage:WaitForChild("FinalObjectiveCompleted")
local player = Players.LocalPlayer
local controller = {Started = false, Machine = nil}

local ITEM_NAMES = {
	MetalWaste = "DÉCHET MÉTAL", PlasticWaste = "DÉCHET PLASTIQUE", WasteBag = "SAC DE DÉCHETS",
	MetalBlock = "BLOC DE MÉTAL", PlasticBlock = "BLOC DE PLASTIQUE",
}

local function label(parent, position, size, text, textSize, color)
	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Position = position
	value.Size = size
	value.Text = text
	value.TextColor3 = color or Color3.fromRGB(220, 226, 234)
	value.Font = Enum.Font.GothamSemibold
	value.TextSize = textSize or 13
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Parent = parent
	return value
end

function controller:_build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RecyclerStatusGui"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(390, 300)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(16, 21, 29)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(68, 82, 99)
	stroke.Transparency = 0.25
	stroke.Parent = frame
	self.Title = label(frame, UDim2.fromOffset(20, 14), UDim2.fromOffset(300, 30), "RECYCLEUR", 20, Color3.fromRGB(205, 174, 124))
	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(34, 30)
	close.Position = UDim2.new(1, -48, 0, 12)
	close.Text = "×"
	close.TextSize = 22
	close.TextColor3 = Color3.fromRGB(220, 226, 234)
	close.BackgroundColor3 = Color3.fromRGB(34, 42, 54)
	close.Parent = frame
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
	self.State = label(frame, UDim2.fromOffset(20, 58), UDim2.fromOffset(350, 24), "ÉTAT : ARRÊTÉ", 14)
	self.Item = label(frame, UDim2.fromOffset(20, 88), UDim2.fromOffset(350, 24), "ÉLÉMENT : AUCUN", 13)
	self.Progress = label(frame, UDim2.fromOffset(20, 120), UDim2.fromOffset(350, 24), "PROGRESSION : 0 %", 13)
	self.Time = label(frame, UDim2.fromOffset(20, 148), UDim2.fromOffset(350, 24), "TEMPS RESTANT : 0.0 s", 13)
	self.Queue = label(frame, UDim2.fromOffset(20, 184), UDim2.fromOffset(350, 24), "FILE D'ATTENTE : 0", 13)
	self.Metal = label(frame, UDim2.fromOffset(20, 220), UDim2.fromOffset(350, 24), "MATIÈRE MÉTAL : 0 / 1", 13)
	self.Plastic = label(frame, UDim2.fromOffset(20, 248), UDim2.fromOffset(350, 24), "MATIÈRE PLASTIQUE : 0 / 1", 13)
	local planeIcon = Instance.new("ImageLabel")
	planeIcon.Size = UDim2.fromOffset(72, 72); planeIcon.Position = UDim2.fromOffset(286, 78)
	planeIcon.BackgroundTransparency = 1; planeIcon.Image = "rbxassetid://109820418000805"; planeIcon.ScaleType = Enum.ScaleType.Fit
	planeIcon.Visible = false; planeIcon.Parent = frame; self.PlaneIcon = planeIcon
	local assemble = Instance.new("TextButton")
	assemble.Size = UDim2.fromOffset(350, 38); assemble.Position = UDim2.fromOffset(20, 248)
	assemble.BackgroundColor3 = Color3.fromRGB(0, 154, 190); assemble.TextColor3 = Color3.new(1, 1, 1)
	assemble.Font = Enum.Font.GothamBold; assemble.TextSize = 14; assemble.Text = "ASSEMBLER"; assemble.Visible = false; assemble.Parent = frame
	Instance.new("UICorner", assemble).CornerRadius = UDim.new(0, 9); self.Assemble = assemble
	assemble.Activated:Connect(function()
		if self.Machine then finalRequest:FireServer("Assemble", self.Machine) else self.Gui.Enabled = false end
	end)
	self.Gui = gui
	close.Activated:Connect(function() self:Close() end)
end

function controller:Close()
	if self.Machine then closed:FireServer(self.Machine); finalRequest:FireServer("Close", self.Machine) end
	self.Machine = nil
	self.Gui.Enabled = false
end

function controller:_render(state)
	if state.BuildState then
		self.Title.Text = "FACTORY  •  ASSEMBLAGE NAVAL SEAPLANE"
		self.State.Text = "ÉTAT : " .. (state.BuildState == "Building" and "ASSEMBLAGE EN COURS" or (state.BuildState == "Completed" and "NAVAL SEAPLANE TERMINÉ" or "PRÊT"))
		self.Item.Text = string.format("PANNEAUX MÉTAL : %d / %d", state.MetalPanelStack or 0, state.RequiredMetalPanelStack or 40)
		self.Progress.Text = string.format("PANNEAUX PLASTIQUE : %d / %d", state.PlasticPanelStack or 0, state.RequiredPlasticPanelStack or 30)
		self.Time.Text = string.format("PROGRESSION : %d %%  •  %.1f s", math.floor((state.Progress or 0) * 100 + 0.5), state.Remaining or 0)
		self.Queue.Visible = false; self.Metal.Visible = false; self.Plastic.Visible = false; self.PlaneIcon.Visible = true; self.Assemble.Visible = true
		local ready = state.BuildState == "Idle" and (state.MetalPanelStack or 0) >= (state.RequiredMetalPanelStack or 40) and (state.PlasticPanelStack or 0) >= (state.RequiredPlasticPanelStack or 30)
		self.Assemble.Active = ready; self.Assemble.AutoButtonColor = ready; self.Assemble.BackgroundColor3 = ready and Color3.fromRGB(0, 174, 210) or Color3.fromRGB(54, 66, 78)
		self.Assemble.Text = state.BuildState == "Completed" and "NAVAL SEAPLANE TERMINÉ" or (state.BuildState == "Building" and "ASSEMBLAGE EN COURS" or "ASSEMBLER")
		return
	end
	self.Queue.Visible = true; self.Metal.Visible = true; self.Plastic.Visible = true; self.PlaneIcon.Visible = false; self.Assemble.Visible = false
	local isPress = state.MachineType == "IndustrialPress"
	self.Title.Text = isPress and "PRESSE INDUSTRIELLE" or "RECYCLEUR"
	self.State.Text = "ÉTAT : " .. (state.Processing and "EN COURS" or (isPress and "ARRÊTÉE" or "ARRÊTÉ"))
	self.Item.Text = "ÉLÉMENT : " .. (ITEM_NAMES[state.CurrentItemId] or "AUCUN")
	self.Progress.Text = "PROGRESSION : " .. tostring(math.floor((state.Progress or 0) * 100 + 0.5)) .. " %"
	self.Time.Text = string.format("TEMPS RESTANT : %.1f s", state.Remaining or 0)
	self.Queue.Text = "FILE D'ATTENTE : " .. tostring(state.QueueLength or 0)
	self.Metal.Text = string.format(isPress and "BLOCS MÉTAL : %d / %d" or "MATIÈRE MÉTAL : %d / %d", isPress and (state.MetalBlocksProcessed or 0) or (state.MetalMaterial or 0), state.MaterialRatio or 1)
	self.Plastic.Text = string.format(isPress and "BLOCS PLASTIQUE : %d / %d" or "MATIÈRE PLASTIQUE : %d / %d", isPress and (state.PlasticBlocksProcessed or 0) or (state.PlasticMaterial or 0), state.MaterialRatio or 1)
end

function controller:Start()
	if self.Started then return end
	self.Started = true
	self:_build()
	opened.OnClientEvent:Connect(function(machine, state)
		self.Machine = machine
		self.Gui.Enabled = true
		self:_render(state)
	end)
	changed.OnClientEvent:Connect(function(machine, state)
		if self.Gui.Enabled and machine == self.Machine then self:_render(state) end
	end)
	finalChanged.OnClientEvent:Connect(function(machine, state)
		-- FinalFactory uses the shared StationController inventory surface.
	end)
	finalObjectiveCompleted.OnClientEvent:Connect(function(state)
		self.Machine = nil; self.Gui.Enabled = true; self.PlaneIcon.Visible = true; self.Assemble.Visible = true
		self.Assemble.Active = true; self.Assemble.AutoButtonColor = true; self.Assemble.Text = "CONTINUER À JOUER"
		self.Title.Text = "OBJECTIF TERMINÉ"
		self.State.Text = "VOUS AVEZ CONSTRUIT LE NAVAL SEAPLANE"
		self.Item.Text = "ÉVASION RÉUSSIE  •  ÂGE " .. tostring(state.Age or "?")
		self.Progress.Text = "Vous pouvez continuer à vivre, construire et explorer ce monde."
		self.Time.Text = "RECORD DE LONGÉVITÉ  •  ÂGE " .. tostring(state.LongevityAge or state.Age or "?")
		self.Queue.Visible = false; self.Metal.Visible = false; self.Plastic.Visible = false
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and self.Gui.Enabled and (input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.Escape) then self:Close() end
	end)
	RunService.RenderStepped:Connect(function(deltaTime)
		local angle = math.rad(FactoryConfig.RECYCLER_GEAR_SPEED_DEGREES) * deltaTime
		for _, gear in CollectionService:GetTagged("FactoryRecyclerGear") do
			if gear:IsA("BasePart") and gear:IsDescendantOf(workspace) then
				local machine = gear:FindFirstAncestorWhichIsA("Model")
				while machine and machine:GetAttribute("ItemId") ~= "Recycler" do machine = machine:FindFirstAncestorWhichIsA("Model") end
				if machine and machine:GetAttribute("FactoryProcessing") == true then
					gear.CFrame = gear.CFrame * CFrame.Angles(angle * (gear:GetAttribute("RecyclerGearDirection") or 1), 0, 0)
				end
			end
		end
		local textureOffset = FactoryConfig.CONVEYOR_TEXTURE_SPEED * deltaTime
		for _, conveyor in CollectionService:GetTagged("FactoryConveyor") do
			if conveyor:IsA("BasePart") and conveyor:IsDescendantOf(workspace) then
				for _, visual in conveyor:GetDescendants() do
					if visual:IsA("Texture") then visual.OffsetStudsV = visual.OffsetStudsV + textureOffset end
				end
			end
		end
	end)
end

return controller
