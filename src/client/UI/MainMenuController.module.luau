local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local request = ReplicatedStorage:WaitForChild("WorldSessionRequest")
local Config = require(ReplicatedStorage.Shared.Config.WorldSessionConfig)
local VisualConfig = require(ReplicatedStorage.Shared.Config.MainMenuVisualConfig)

local controller = {
	Started = false,
	Loading = false,
	SelectedSlot = 1,
	MaxPlayers = Config.DEFAULT_MAX_PLAYERS,
	OwnedWorldRefreshGeneration = 0,
}
local BLOCK_ACTION = "MAYDEAD_MAIN_MENU_BLOCK"
local FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PANEL_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local COLORS = {
	Background = Color3.fromRGB(5, 8, 13),
	Panel = Color3.fromRGB(14, 21, 29),
	PanelHover = Color3.fromRGB(23, 36, 51),
	PanelSoft = Color3.fromRGB(18, 28, 39),
	Text = Color3.fromRGB(244, 246, 248),
	Muted = Color3.fromRGB(156, 169, 182),
	Stroke = Color3.fromRGB(42, 58, 73),
	Accent = Color3.fromRGB(76, 157, 255),
	AccentHover = Color3.fromRGB(105, 175, 255),
	Steel = Color3.fromRGB(98, 196, 214),
	Success = Color3.fromRGB(107, 175, 138),
	Danger = Color3.fromRGB(182, 74, 74),
	DangerHover = Color3.fromRGB(205, 86, 82),
}

local function rectPosition(rect)
	return UDim2.fromScale(rect.Position.X, rect.Position.Y)
end

local function rectSize(rect)
	return UDim2.fromScale(rect.Size.X, rect.Size.Y)
end

local function corner(parent, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius)
	value.Parent = parent
	return value
end

local function stroke(parent, color, transparency, thickness)
	local value = Instance.new("UIStroke")
	value.Color = color
	value.Transparency = transparency or 0
	value.Thickness = thickness or 1
	value.Parent = parent
	return value
end

local function padding(parent, horizontal, vertical)
	local value = Instance.new("UIPadding")
	value.PaddingLeft = UDim.new(0, horizontal)
	value.PaddingRight = UDim.new(0, horizontal)
	value.PaddingTop = UDim.new(0, vertical)
	value.PaddingBottom = UDim.new(0, vertical)
	value.Parent = parent
end

local function label(parent, text, size, textSize, font)
	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Size = size
	value.Text = text
	value.TextColor3 = COLORS.Text
	value.TextSize = textSize
	value.Font = font or Enum.Font.GothamMedium
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Parent = parent
	return value
end

local function addButtonMotion(value, primary, danger)
	local scale = Instance.new("UIScale")
	scale.Parent = value
	local border = value:FindFirstChildOfClass("UIStroke")
	value.MouseEnter:Connect(function()
		local hoverColor = value:GetAttribute("HoverColor")
		TweenService:Create(value, FAST, {BackgroundColor3 = hoverColor or (danger and COLORS.DangerHover or (primary and COLORS.AccentHover or COLORS.PanelHover))}):Play()
		TweenService:Create(scale, FAST, {Scale = value:GetAttribute("HoverScale") or 1.025}):Play()
		if border then TweenService:Create(border, FAST, {Transparency = 0.12}):Play() end
	end)
	value.MouseLeave:Connect(function()
		local selected = value:GetAttribute("Selected") == true
		local baseColor = value:GetAttribute("BaseColor")
		TweenService:Create(value, FAST, {BackgroundColor3 = baseColor or (danger and COLORS.Danger or ((primary or selected) and COLORS.Accent or COLORS.PanelSoft))}):Play()
		TweenService:Create(scale, FAST, {Scale = 1}):Play()
		if border then TweenService:Create(border, FAST, {Transparency = primary and 0.2 or 0.55}):Play() end
	end)
	value.MouseButton1Down:Connect(function() TweenService:Create(scale, TweenInfo.new(0.07), {Scale = value:GetAttribute("PressedScale") or 0.965}):Play() end)
	value.MouseButton1Up:Connect(function() TweenService:Create(scale, TweenInfo.new(0.09), {Scale = 1}):Play() end)
end

local function button(parent, text, size, primary, danger)
	local value = Instance.new("TextButton")
	value.Size = size
	value.BackgroundColor3 = danger and COLORS.Danger or (primary and COLORS.Accent or COLORS.PanelSoft)
	value.BackgroundTransparency = primary and 0.02 or 0.08
	value.AutoButtonColor = false
	value.Text = text
	value.TextColor3 = COLORS.Text
	value.TextSize = 13
	value.Font = Enum.Font.GothamBold
	value.Parent = parent
	value:SetAttribute("Selected", false)
	corner(value, 10)
	stroke(value, danger and COLORS.DangerHover or (primary and COLORS.AccentHover or COLORS.Stroke), primary and 0.2 or 0.55)
	addButtonMotion(value, primary, danger)
	return value
end

local function addIcon(parent, iconName, size, color)
	local image = Instance.new("ImageLabel")
	image.Name = iconName .. "Icon"
	image.Size = size
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.BackgroundTransparency = 1
	image.Image = VisualConfig.ICONS[iconName] or ""
	image.ImageColor3 = color or COLORS.Text
	image.ScaleType = Enum.ScaleType.Fit
	image.ZIndex = parent.ZIndex + 1
	image.Parent = parent
	return image
end

local function iconButton(parent, iconName, fallbackText, danger)
	local value = button(parent, "", UDim2.fromOffset(46, 46), false, false)
	local icon = addIcon(value, iconName, UDim2.fromOffset(20, 20), danger and COLORS.Danger or COLORS.Muted)
	if icon.Image == "" then value.Text = fallbackText; value.TextSize = 9 end
	value.MouseEnter:Connect(function() icon.ImageColor3 = danger and COLORS.DangerHover or COLORS.Accent end)
	value.MouseLeave:Connect(function() icon.ImageColor3 = danger and COLORS.Danger or COLORS.Muted end)
	return value
end

local function modal(parent, name, size)
	local shadow = Instance.new("Frame")
	shadow.Name = name .. "Shadow"
	shadow.Size = size + UDim2.fromOffset(12, 12)
	shadow.Position = UDim2.new(0.5, 6, 0.5, 8)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundColor3 = Color3.new(0, 0, 0)
	shadow.BackgroundTransparency = 0.35
	shadow.Visible = false
	shadow.ZIndex = 39
	shadow.Parent = parent
	corner(shadow, 18)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = COLORS.Panel
	frame.BackgroundTransparency = 0.04
	frame.Visible = false
	frame.ZIndex = 40
	frame.Parent = parent
	corner(frame, 16)
	stroke(frame, COLORS.Accent, 0.42)
	return frame, shadow
end

function controller:_setModalVisible(frame, shadowFrame, visible)
	if visible then
		shadowFrame.Visible = true
		frame.Visible = true
		frame.Position = UDim2.new(0.5, 0, 0.5, 10)
		local scale = frame:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		local targetScale = frame:GetAttribute("ResponsiveScaleTarget") or 1
		scale.Scale = targetScale * 0.96
		scale.Parent = frame
		TweenService:Create(frame, PANEL_TWEEN, {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		TweenService:Create(scale, PANEL_TWEEN, {Scale = targetScale}):Play()
	else
		frame.Visible = false
		shadowFrame.Visible = false
	end
end

function controller:_show(panel)
	for _, candidate in {self.Home, self.Worlds, self.JoinedWorlds, self.Create} do
		candidate.Visible = candidate == panel
	end
	panel.Position = UDim2.new(0.5, 0, 0.5, 18)
	local scale = panel:FindFirstChild("ResponsiveScale")
	local targetScale = panel == self.Worlds and (self.WorldsTargetScale or self.ResponsiveScale) or self.ResponsiveScale
	if scale then scale.Scale = targetScale * 0.97 end
	TweenService:Create(panel, PANEL_TWEEN, {Position = UDim2.fromScale(0.5, 0.5)}):Play()
	if scale then TweenService:Create(scale, PANEL_TWEEN, {Scale = targetScale}):Play() end
	if panel == self.Home then self:_animateHomeNarrative() end
	if self.HomeBackground and self.WorldsBackground then
		self.HomeBackground.Visible = panel ~= self.Worlds and panel ~= self.JoinedWorlds
		self.WorldsBackground.Visible = panel == self.Worlds
		if self.JoinedWorldsBackground then self.JoinedWorldsBackground.Visible = panel == self.JoinedWorlds end
	end
	self:_updateResponsive()
end

function controller:_animateHomeNarrative()
	self.HomeNarrativeRevision = (self.HomeNarrativeRevision or 0) + 1
	local revision = self.HomeNarrativeRevision
	for index, narrativeLabel in ipairs(self.HomeNarrativeLines or {}) do
		narrativeLabel.Position = UDim2.fromOffset(0, 6)
		narrativeLabel.TextTransparency = 1
		task.delay((index - 1) * 0.07, function()
			if self.HomeNarrativeRevision ~= revision or not self.Home.Visible then return end
			TweenService:Create(narrativeLabel, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(0, 0),
				TextTransparency = 0,
			}):Play()
		end)
	end
end

function controller:_feedback(text, isError)
	self.Feedback.Text = text
	self.Feedback.TextColor3 = isError and COLORS.Danger or COLORS.Muted
end

function controller:_setLoading(loading)
	self.Loading = loading
	self.CreateButton.Active = not loading
	self.CreateButton.Text = loading and "CRÉATION…" or "CRÉER LE MONDE"
	if self.ReturnConfirmButton then self.ReturnConfirmButton.Active = not loading end
	if self.DeleteConfirmButton then
		self.DeleteConfirmButton.Active = not loading
		self.DeleteConfirmButton.Text = loading and "SUPPRESSION…" or "SUPPRIMER DÉFINITIVEMENT"
	end
end

function controller:_invoke(action, payload)
	if self.Loading then return nil end
	self:_setLoading(true)
	local ok, response = pcall(function() return request:InvokeServer(action, payload) end)
	self:_setLoading(false)
	if not ok or typeof(response) ~= "table" then self:_feedback("LE SERVEUR NE RÉPOND PAS", true); return nil end
	return response
end

function controller:_errorMessage(code)
	return ({RequestInProgress = "REQUÊTE DÉJÀ EN COURS", SessionAlreadyActive = "UNE SESSION EXISTE DÉJÀ",
		SessionUnavailable = "SESSION INDISPONIBLE", SessionFull = "SESSION COMPLÈTE",
		InvalidRequest = "PARAMÈTRES INVALIDES", ServerError = "ERREUR SERVEUR",
		LoadFailed = "IMPOSSIBLE DE CHARGER CE MONDE — RÉESSAYEZ PLUS TARD",
		SaveFailed = "IMPOSSIBLE DE SAUVEGARDER POUR LE MOMENT", WorldAlreadyActive = "CE MONDE EST DÉJÀ ACTIF",
		SlotUnavailable = "EMPLACEMENT INDISPONIBLE", NotAuthorized = "ACCÈS REFUSÉ",
		RestoreFailed = "DONNÉES JOUEUR INVALIDES", InvalidWorldName = "LE NOM DOIT CONTENIR ENTRE 1 ET 28 CARACTÈRES",
		FilterFailed = "IMPOSSIBLE DE FILTRER CE NOM POUR LE MOMENT",
		NotOwner = "VOUS N'ÊTES PAS PROPRIÉTAIRE DE CE MONDE",
		WorldDeleted = "CE MONDE A ÉTÉ SUPPRIMÉ",
		WorldBusy = "CE MONDE EST ACTUELLEMENT UTILISÉ",
		WorldInUse = "CE MONDE EST ACTUELLEMENT UTILISÉ",
		DeleteInProgress = "SUPPRESSION DÉJÀ EN COURS",
		DeleteFailed = "SUPPRESSION IMPOSSIBLE — RÉESSAYEZ",
		DeleteRecoveryRequired = "SUPPRESSION INTERROMPUE — ACTUALISEZ LES MONDES",
		JoinedWorldLimitReached = "LIMITE DE MONDES REJOINTS ATTEINTE — 3 / 3",
		MemberLimitReached = "CE MONDE POSSÈDE DÉJÀ 6 / 6 MEMBRES",
		InviteNotFound = "INVITATION INTROUVABLE", AlreadyMember = "JOUEUR DÉJÀ MEMBRE",
		NotFriend = "CE JOUEUR N'EST PAS DANS VOS AMIS", FriendListUnavailable = "LISTE D'AMIS INDISPONIBLE",
		CannotRemoveOwner = "LE PROPRIÉTAIRE NE PEUT PAS ÊTRE RETIRÉ", NotMember = "JOUEUR NON MEMBRE",
		TeleportFailed = "ROUTAGE VERS LE MONDE IMPOSSIBLE",
		WorldNotFound = "CE MONDE N'EXISTE PLUS",
		AlreadyDeleted = "CE MONDE EST DÉJÀ SUPPRIMÉ",
		WorldCreationInProgress = "CRÉATION DU MONDE EN COURS — RÉESSAYEZ"})[code] or "ACTION IMPOSSIBLE"
end

function controller:_bindMenuInput()
	ContextActionService:BindActionAtPriority(BLOCK_ACTION, function() return Enum.ContextActionResult.Sink end, false, 3000,
		Enum.UserInputType.MouseButton2, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
		Enum.KeyCode.Space, Enum.KeyCode.E, Enum.KeyCode.F, Enum.KeyCode.R, Enum.KeyCode.B,
		Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,
		Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight)
end

function controller:_restoreGameplay()
	ContextActionService:UnbindAction(BLOCK_ACTION)
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		local character = player.Character
		local humanoid = character and (character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5))
		if humanoid then camera.CameraSubject = humanoid end
	end
	UserInputService.MouseIconEnabled = true
	self.Gui.Enabled = false
	self:_setMenuMusic(false)
end

function controller:_setMenuMusic(enabled)
	local music = SoundService:FindFirstChild("Drums Of Might")
	if not music or not music:IsA("Sound") then
		if enabled and not self.MenuMusicMissingWarned then
			self.MenuMusicMissingWarned = true
			warn("[MAYDEAD] Menu music missing: SoundService.Drums Of Might")
		end
		return
	end
	music.Looped = true
	if enabled then
		if not music.Playing then music:Play() end
	elseif music.Playing then
		music:Stop()
	end
end

function controller:_applyMenuCamera()
	if not self.Gui or not self.Gui.Enabled then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	camera.CameraType = Enum.CameraType.Scriptable
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	camera.CFrame = root and (root.CFrame * CFrame.new(0, 7, 16) * CFrame.Angles(math.rad(-12), math.rad(180), 0))
		or CFrame.new(0, 12, 24) * CFrame.Angles(math.rad(-12), math.rad(180), 0)
end

function controller:_startFromResponse(response)
	if response and response.Ok and response.Routing then
		self:_feedback("CONNEXION AU MONDE…", false)
		return true
	end
	if response and response.Ok and response.Started then
		self:_feedback("SESSION PRÊTE", false)
		TweenService:Create(self.Fade, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
		task.delay(0.28, function() self:_restoreGameplay() end)
		return true
	end
	if response and response.State and response.State.Active then
		self:_renderWorldState(response.State)
		self:_show(self.Worlds)
		self.WorldFeedback.Text = self:_errorMessage(response.Error) .. " — VOUS POUVEZ LA REJOINDRE"
	end
	self:_feedback(self:_errorMessage(response and response.Error), true)
	return false
end

function controller:_renderWorldState(state)
	for index, card in ipairs(self.WorldCards) do
		card.Frame.BackgroundTransparency = 1
		local saved = state.Slots and state.Slots[index]
		local active = state.Active and index == state.WorldSlot
		card.SlotLabel.Text = "MONDE " .. tostring(index)
		card.Rename.Visible = saved ~= nil
		card.Delete.Visible = saved ~= nil
		if card.Members then card.Members.Visible = saved ~= nil end
		card.AgeIcon.Visible = active or saved ~= nil
		card.PlayersIcon.Visible = active or saved ~= nil
		if active then
			card.Name.Text = state.DisplayName or ("MONDE " .. tostring(index))
			card.Meta.Text = string.format("SESSION EN COURS   •   %d/%d JOUEURS", state.PlayerCount or 0, state.MaxPlayers or 0)
			card.Action.Text = "REJOINDRE"
			card.Action.Visible = true
			card.Empty.Visible = false
		elseif saved and not state.Active then
			card.Name.Text = saved.DisplayName or ("MONDE " .. tostring(index))
			card.Meta.Text = string.format("ANNÉE %d   •   1–%d JOUEURS", saved.YearsOnIsland or 0, saved.MaxPlayers or 1)
			card.Action.Text = "CONTINUER"
			card.Action.Visible = true
			card.Empty.Visible = false
		else
			card.Name.Text = ""
			card.Meta.Text = ""
			card.Action.Text = "+  CRÉER UNE PARTIE"
			card.Action.Visible = not state.Active
			card.Empty.Visible = true
		end
		card.Action.Active = not state.Active or active
	end
	self.SessionState = state
	self:_renderHomeInvites(state)
end

local function ownedWorldCount(state)
	local count = 0
	for index = 1, Config.WORLD_SLOT_COUNT do
		if state and state.Slots and state.Slots[index] then count += 1 end
	end
	return count
end

local function slotWorldId(state, index)
	local slot = state and state.Slots and state.Slots[index]
	return slot and slot.WorldId or "empty"
end

local function snapshotWithoutDeletedWorld(state, deletedSlot, deletedWorldId)
	if typeof(state) ~= "table" or typeof(state.Slots) ~= "table" then return nil end
	local existing = state.Slots[deletedSlot]
	if not existing or existing.WorldId ~= deletedWorldId then return nil end
	local snapshot = table.clone(state)
	snapshot.Slots = table.clone(state.Slots)
	snapshot.Slots[deletedSlot] = nil
	return snapshot
end

function controller:_renderHomeInvites(state)
	if not self.HomeInviteCard then return end
	local invites = state.PendingInvites or {}
	local invite = invites[1]
	self.HomeInviteCard.Visible = invite ~= nil
	self.HomeInviteWorldId = invite and invite.WorldId or nil
	if not invite then return end
	self.HomeInviteTitle.Text = #invites > 1 and ("INVITATIONS DE MONDE (" .. tostring(#invites) .. ")") or "INVITATION DE MONDE"
	self.HomeInviteText.Text = string.format("%s  •  Invité par %s  •  %d / 6 membres",
		invite.DisplayName or "MONDE PRIVÉ", invite.Name or tostring(invite.OwnerUserId), invite.MemberCount or 1)
end

function controller:_openDelete(index)
	local saved = self.SessionState and self.SessionState.Slots and self.SessionState.Slots[index]
	if not saved or self.SessionState.Active then return end
	self.DeleteSlot, self.DeleteWorldId = index, saved.WorldId
	self.DeleteWorldName = saved.DisplayName or ("MONDE " .. tostring(index))
	self.DeleteWorldLabel.Text = self.DeleteWorldName
	self.DeleteFeedback.Text = ""
	self.DeleteConfirmInput.Text = ""
	self:_setModalVisible(self.DeleteModal, self.DeleteShadow, true)
end

function controller:_refreshWorlds()
	self.OwnedWorldRefreshGeneration += 1
	local generation = self.OwnedWorldRefreshGeneration
	local response = self:_invoke("GetState")
	if generation ~= self.OwnedWorldRefreshGeneration then return false end
	if response and response.Ok == true and typeof(response.State) == "table" and typeof(response.State.Slots) == "table" then
		self.WorldFeedback.Text = ""
		self.WorldFeedback.TextColor3 = COLORS.Danger
		self:_renderWorldState(response.State)
		if RunService:IsStudio() then
			print(string.format(
				"[MAYDEAD][WORLD_UI][REFRESH] Status=Success Slot1=%s Slot2=%s Slot3=%s",
				slotWorldId(response.State, 1), slotWorldId(response.State, 2), slotWorldId(response.State, 3)
			))
		end
		return true
	end
	self.WorldFeedback.Text = self:_errorMessage(response and response.Error)
	self.WorldFeedback.TextColor3 = COLORS.Danger
	if RunService:IsStudio() then
		warn(string.format(
			"[MAYDEAD][WORLD_UI][REFRESH] Status=Failure PreservingLastValidSnapshot=true Error=%s",
			tostring(response and response.Error or "NoResponse")
		))
	end
	return false
end

function controller:_openRename(index)
	local saved = self.SessionState and self.SessionState.Slots and self.SessionState.Slots[index]
	if not saved or self.SessionState.Active then return end
	self.RenameSlot, self.RenameWorldId = index, saved.WorldId
	self.RenameInput.Text = saved.DisplayName or ("MONDE " .. tostring(index))
	self.RenameFeedback.Text = ""
	self.RenameCounter.Text = tostring(utf8.len(self.RenameInput.Text) or 0) .. " / 28"
	self:_setModalVisible(self.RenameModal, self.RenameShadow, true)
	self.RenameInput:CaptureFocus()
end

function controller:_buildBackground(gui)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "FullScreenBackdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Position = UDim2.fromScale(0, 0)
	backdrop.BackgroundColor3 = VisualConfig.LETTERBOX_COLOR
	backdrop.BackgroundTransparency = 0
	backdrop.BorderSizePixel = 0
	backdrop.Parent = gui
	self.FullScreenBackdrop = backdrop

	local viewport = Instance.new("Frame")
	viewport.Name = "MenuViewport"
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.Position = UDim2.fromScale(0.5, 0.5)
	viewport.BackgroundColor3 = Color3.new(0, 0, 0)
	viewport.BorderSizePixel = 0
	viewport.ClipsDescendants = true
	viewport.Parent = gui
	self.MenuViewport = viewport

	local background = Instance.new("ImageLabel")
	background.Name = "HomeBackground"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(10, 24, 31)
	background.BorderSizePixel = 0
	background.Image = VisualConfig.BACKGROUND_IMAGE_ID
	background.ImageTransparency = VisualConfig.BACKGROUND_IMAGE_TRANSPARENCY
	background.ScaleType = Enum.ScaleType.Fit
	background.Parent = viewport
	self.HomeBackground = background
	local worldsBackground = background:Clone()
	worldsBackground.Name = "WorldsBackground"
	worldsBackground.Image = VisualConfig.WORLDS_BACKGROUND_IMAGE_ID
	worldsBackground.BackgroundColor3 = VisualConfig.LETTERBOX_COLOR
	worldsBackground.Visible = false
	worldsBackground.Parent = viewport
	self.WorldsBackground = worldsBackground
	local joinedWorldsBackground = background:Clone()
	joinedWorldsBackground.Name = "JoinedWorldsBackground"
	joinedWorldsBackground.Image = VisualConfig.JOINED_WORLDS_BACKGROUND_IMAGE_ID
	joinedWorldsBackground.BackgroundColor3 = VisualConfig.LETTERBOX_COLOR
	joinedWorldsBackground.Visible = false
	joinedWorldsBackground.Parent = viewport
	self.JoinedWorldsBackground = joinedWorldsBackground
	local fallbackGradient = Instance.new("UIGradient")
	fallbackGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 10, 16)),
		ColorSequenceKeypoint.new(0.48, Color3.fromRGB(18, 42, 48)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 14, 19)),
	})
	fallbackGradient.Rotation = 125
	fallbackGradient.Enabled = background.Image == ""
	fallbackGradient.Parent = background
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.36
	overlay.BorderSizePixel = 0
	overlay.Parent = gui
	overlay.Visible = false
	local shade = Instance.new("UIGradient")
	shade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.52, 0.42), NumberSequenceKeypoint.new(1, 0.08),
	})
	shade.Rotation = 90
	shade.Parent = overlay
	local redGlow = Instance.new("Frame")
	redGlow.Size = UDim2.new(0.7, 0, 0.55, 0)
	redGlow.Position = UDim2.new(-0.3, 0, 0.65, 0)
	redGlow.BackgroundColor3 = COLORS.Accent
	redGlow.BackgroundTransparency = 0.88
	redGlow.BorderSizePixel = 0
	redGlow.Rotation = -8
	redGlow.Parent = gui
	redGlow.Visible = false
	corner(redGlow, 999)
end

function controller:_buildHome(gui)
	local home = Instance.new("Frame")
	home.Name = "Home"
	home.Size = UDim2.fromOffset(760, 500)
	home.Position = UDim2.fromScale(0.5, 0.5)
	home.AnchorPoint = Vector2.new(0.5, 0.5)
	home.BackgroundTransparency = 1
	home.Parent = self.MenuViewport
	self.Home = home
	local content = Instance.new("Frame")
	content.Size = UDim2.fromScale(1, 1)
	content.BackgroundTransparency = 1
	content.Parent = home
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = content
	local eyebrow = label(content, VisualConfig.HOME_TEXT.Eyebrow, UDim2.new(1, 0, 0, 24), 12, Enum.Font.GothamBold)
	eyebrow.LayoutOrder = 1
	eyebrow.TextColor3 = COLORS.Steel
	eyebrow.TextXAlignment = Enum.TextXAlignment.Center
	local logoHolder = Instance.new("Frame")
	logoHolder.Name = "Logo"
	logoHolder.Size = UDim2.new(1, 0, 0, 120)
	logoHolder.BackgroundTransparency = 1
	logoHolder.LayoutOrder = 2
	logoHolder.Parent = content
	if typeof(VisualConfig.LOGO_IMAGE_ID) == "string" and VisualConfig.LOGO_IMAGE_ID ~= "" then
		local logoImage = Instance.new("ImageLabel")
		logoImage.Name = "OfficialLogo"
		logoImage.Size = UDim2.fromScale(1, 1)
		logoImage.BackgroundTransparency = 1
		logoImage.Image = VisualConfig.LOGO_IMAGE_ID
		logoImage.ScaleType = Enum.ScaleType.Fit
		logoImage.Parent = logoHolder
	else
		local logoShadow = label(logoHolder, VisualConfig.LOGO_TEXT, UDim2.fromScale(1, 1), 94, Enum.Font.Oswald)
		logoShadow.Name = "LogoShadow"
		logoShadow.Position = UDim2.fromOffset(0, 7)
		logoShadow.TextColor3 = VisualConfig.LOGO_SHADOW_COLOR
		logoShadow.TextTransparency = 0.22
		logoShadow.TextStrokeColor3 = Color3.new(0, 0, 0)
		logoShadow.TextStrokeTransparency = 0.34
		logoShadow.TextXAlignment = Enum.TextXAlignment.Center
		local logo = label(
			logoHolder,
			VisualConfig.LOGO_TEXT:sub(1, 5)
				.. '<font color="' .. VisualConfig.LOGO_BLOOD_RED_HEX .. '">'
				.. VisualConfig.LOGO_TEXT:sub(6, 6)
				.. "</font>"
				.. VisualConfig.LOGO_TEXT:sub(7),
			UDim2.fromScale(1, 1),
			94,
			Enum.Font.Oswald
		)
		logo.Name = "LogoText"
		logo.RichText = true
		logo.TextColor3 = VisualConfig.LOGO_TEXT_COLOR
		logo.TextXAlignment = Enum.TextXAlignment.Center
		logo.TextStrokeColor3 = VisualConfig.LOGO_STROKE_COLOR
		logo.TextStrokeTransparency = 0.48
		self.HomeLogo = logoHolder
	end
	local accent = Instance.new("Frame")
	accent.Size = UDim2.fromOffset(92, 4)
	accent.BackgroundColor3 = COLORS.Accent
	accent.BorderSizePixel = 0
	accent.LayoutOrder = 3
	accent.Parent = content
	corner(accent, 2)
	self.HomeNarrativeLines = {}
	local function narrativeLine(text, height, textSize, font, color, layoutOrder)
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 0, 0, height)
		holder.BackgroundTransparency = 1
		holder.LayoutOrder = layoutOrder
		holder.Parent = content
		local narrativeLabel = label(holder, text, UDim2.fromScale(1, 1), textSize, font)
		narrativeLabel.TextColor3 = color
		narrativeLabel.TextXAlignment = Enum.TextXAlignment.Center
		narrativeLabel.TextYAlignment = Enum.TextYAlignment.Center
		narrativeLabel.TextWrapped = true
		narrativeLabel.TextTransparency = 1
		narrativeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		narrativeLabel.TextStrokeTransparency = layoutOrder == 4 and 0.72 or 0.86
		table.insert(self.HomeNarrativeLines, narrativeLabel)
		return holder, narrativeLabel
	end
	self.NarrativeLeadHolder, self.NarrativeLead = narrativeLine(
		VisualConfig.HOME_TEXT.NarrativeLead,
		42,
		22,
		Enum.Font.GothamSemibold,
		Color3.fromRGB(241, 245, 249),
		4
	)
	self.NarrativeSupportHolder, self.NarrativeSupport = narrativeLine(
		VisualConfig.HOME_TEXT.NarrativeSupport,
		38,
		15,
		Enum.Font.GothamMedium,
		Color3.fromRGB(164, 179, 194),
		5
	)
	local inviteCard = Instance.new("Frame")
	inviteCard.Name = "PendingWorldInviteCard"; inviteCard.Size = UDim2.new(0.78, 0, 0, 72)
	inviteCard.Position = UDim2.fromScale(0.5, 0.78); inviteCard.AnchorPoint = Vector2.new(0.5, 0.5)
	inviteCard.BackgroundColor3 = Color3.fromRGB(7, 24, 36); inviteCard.BackgroundTransparency = 0.04
	inviteCard.BorderSizePixel = 0; inviteCard.Visible = false; inviteCard.ZIndex = 25; inviteCard.Parent = home
	corner(inviteCard, 12); stroke(inviteCard, COLORS.Accent, 0.32); self.HomeInviteCard = inviteCard
	local inviteTitle = label(inviteCard, "INVITATION DE MONDE", UDim2.new(0.58, 0, 0, 24), 11, Enum.Font.GothamBold)
	inviteTitle.Position = UDim2.fromOffset(16, 8); inviteTitle.TextColor3 = COLORS.Accent; inviteTitle.ZIndex = 26; self.HomeInviteTitle = inviteTitle
	local inviteText = label(inviteCard, "", UDim2.new(0.62, -16, 0, 28), 10, Enum.Font.GothamSemibold)
	inviteText.Position = UDim2.fromOffset(16, 34); inviteText.TextColor3 = COLORS.Text; inviteText.TextTruncate = Enum.TextTruncate.AtEnd; inviteText.ZIndex = 26; self.HomeInviteText = inviteText
	local acceptInvite = button(inviteCard, "ACCEPTER", UDim2.fromOffset(104, 38), true)
	acceptInvite.Position = UDim2.new(1, -220, 0.5, -19); acceptInvite.ZIndex = 26; self.HomeInviteAccept = acceptInvite
	local declineInvite = button(inviteCard, "REFUSER", UDim2.fromOffset(96, 38), false, true)
	declineInvite.Position = UDim2.new(1, -106, 0.5, -19); declineInvite.ZIndex = 26; self.HomeInviteDecline = declineInvite
	acceptInvite.Activated:Connect(function()
		if not self.HomeInviteWorldId then return end
		local response = self:_invoke("AcceptInvite", {WorldId = self.HomeInviteWorldId})
		if response and response.Ok then self:_refreshWorlds() else self:_feedback(self:_errorMessage(response and response.Error), true); self:_refreshWorlds() end
	end)
	declineInvite.Activated:Connect(function()
		if not self.HomeInviteWorldId then return end
		local response = self:_invoke("DeclineInvite", {WorldId = self.HomeInviteWorldId})
		if response and response.Ok then self:_refreshWorlds() else self:_feedback(self:_errorMessage(response and response.Error), true) end
	end)
	local play = button(content, "JOUER", UDim2.fromOffset(254, 54), true)
	play.TextSize = 16
	play.LayoutOrder = 7
	local playIcon = addIcon(play, "Play", UDim2.fromOffset(20, 20), COLORS.Text)
	playIcon.Position = UDim2.new(0, 38, 0.5, 0)
	play.Activated:Connect(function() self:_show(self.Worlds); self:_refreshWorlds() end)
	local foot = label(content, VisualConfig.HOME_TEXT.Footer, UDim2.new(1, 0, 0, 24), 10)
	foot.TextColor3 = Color3.fromRGB(120, 133, 146)
	foot.TextXAlignment = Enum.TextXAlignment.Center
	foot.LayoutOrder = 8
	content.Visible = false
	home.Size = UDim2.fromScale(1, 1)
	home.Position = UDim2.fromScale(0.5, 0.5)
	local function homeHitbox(name, position, size)
		local hitbox = Instance.new("TextButton")
		hitbox.Name = name
		hitbox.Position = position
		hitbox.Size = size
		hitbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hitbox.BackgroundTransparency = 1
		hitbox.Text = ""
		hitbox.AutoButtonColor = false
		hitbox.Parent = home
		return hitbox
	end
	local playHitbox = homeHitbox("PlayHitbox", rectPosition(VisualConfig.PLAY_BUTTON_RECT), rectSize(VisualConfig.PLAY_BUTTON_RECT))
	playHitbox.Activated:Connect(function() self:_show(self.Worlds); self:_refreshWorlds() end)
	homeHitbox("LeaderboardHitbox", rectPosition(VisualConfig.LEADERBOARD_BUTTON_RECT), rectSize(VisualConfig.LEADERBOARD_BUTTON_RECT))
	homeHitbox("QuitHitbox", rectPosition(VisualConfig.QUIT_BUTTON_RECT), rectSize(VisualConfig.QUIT_BUTTON_RECT))
end

function controller:_buildWorlds(gui)
	local panel = Instance.new("Frame")
	panel.Name = "Worlds"
	panel.Size = UDim2.fromScale(1, 1)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundTransparency = 1
	panel.Visible = false
	panel.Parent = self.MenuViewport
	self.Worlds = panel
	local title = label(panel, "VOS MONDES", UDim2.new(1, 0, 0, 40), 28, Enum.Font.GothamBlack)
	title.Position = UDim2.fromOffset(0, 0)
	title.Visible = false
	local subtitle = label(panel, "CHOISISSEZ UNE SAUVEGARDE POUR CONTINUER L'AVENTURE", UDim2.new(1, 0, 0, 22), 10, Enum.Font.GothamBold)
	subtitle.Position = UDim2.fromOffset(2, 42); subtitle.TextColor3 = COLORS.Muted
	subtitle.Visible = false
	local cards = Instance.new("ScrollingFrame")
	cards.Size = UDim2.fromScale(1, 1)
	cards.Position = UDim2.fromScale(0, 0)
	cards.BackgroundTransparency = 1
	cards.BorderSizePixel = 0
	cards.CanvasSize = UDim2.new()
	cards.AutomaticCanvasSize = Enum.AutomaticSize.None
	cards.ScrollBarThickness = 4
	cards.ScrollBarImageColor3 = COLORS.Steel
	cards.Parent = panel
	self.WorldCardsContainer = cards
	self.WorldCards = {}
	for index = 1, Config.WORLD_SLOT_COUNT do
		local card = Instance.new("Frame")
		card.Name = "WorldCard" .. index
		card.BackgroundTransparency = 1
		card.BorderSizePixel = 0
		card.Position = rectPosition(VisualConfig.WORLD_SLOT_RECTS[index])
		card.Size = rectSize(VisualConfig.WORLD_SLOT_RECTS[index])
		card.Parent = cards
		local contentOffsetX = index == 1 and 10 or 0
		local slotLabel = label(card, "MONDE " .. index, UDim2.fromScale(0.62, 0.055), 10, Enum.Font.GothamBold)
		slotLabel.Position = UDim2.new(0.06, contentOffsetX, 0.055, 0)
		slotLabel.TextColor3 = COLORS.Steel

		local actions = Instance.new("Frame")
		actions.Name = "ActionsFrame"
		actions.Size = UDim2.fromScale(0.32, 0.075)
		actions.Position = UDim2.fromScale(0.94, 0.05)
		actions.AnchorPoint = Vector2.new(1, 0)
		actions.BackgroundTransparency = 1
		actions.Parent = card
		local actionsLayout = Instance.new("UIListLayout")
		actionsLayout.FillDirection = Enum.FillDirection.Horizontal
		actionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		actionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		actionsLayout.Padding = UDim.new(0, 6)
		actionsLayout.Parent = actions
		local rename = iconButton(actions, "Rename", "EDIT", false)
		rename.Size = UDim2.fromOffset(38, 38)
		rename.LayoutOrder = 1
		rename.BackgroundColor3 = Color3.fromRGB(22, 38, 52)
		rename.BackgroundTransparency = 0.3
		rename.Visible = false
		rename:SetAttribute("Tooltip", "RENOMMER")
		rename.Activated:Connect(function() self:_openRename(index) end)
		local deleteButton = iconButton(actions, "Delete", "DEL", true)
		deleteButton.Size = UDim2.fromOffset(38, 38)
		deleteButton.LayoutOrder = 3
		deleteButton.BackgroundColor3 = Color3.fromRGB(48, 25, 29)
		deleteButton.BackgroundTransparency = 0.34
		deleteButton.Visible = false
		deleteButton:SetAttribute("Tooltip", "SUPPRIMER")
		deleteButton.Activated:Connect(function() self:_openDelete(index) end)
		local membersButton = iconButton(actions, "Members", "MEM", false)
		membersButton.Size = UDim2.fromOffset(38, 38)
		membersButton.LayoutOrder = 2
		membersButton.BackgroundColor3 = Color3.fromRGB(22, 38, 52)
		membersButton.BackgroundTransparency = 0.3
		membersButton.Visible = false
		membersButton:SetAttribute("Tooltip", "GÉRER LES MEMBRES")
		membersButton.Activated:Connect(function()
			local saved = self.SessionState and self.SessionState.Slots and self.SessionState.Slots[index]
			if saved then self:_openMembers(saved.WorldId, true) end
		end)

		local worldName = label(card, "", UDim2.fromScale(0.88, 0.12), 22, Enum.Font.GothamBlack)
		worldName.Position = UDim2.new(0.06, contentOffsetX, 0.17, 0)
		worldName.TextTruncate = Enum.TextTruncate.AtEnd
		worldName.TextWrapped = false
		local meta = label(card, "", UDim2.fromScale(0.82, 0.055), 10, Enum.Font.GothamMedium)
		meta.Position = UDim2.new(0.12, contentOffsetX, 0.305, 0)
		meta.TextColor3 = COLORS.Muted
		local ageIcon = addIcon(card, "Age", UDim2.fromOffset(15, 15), COLORS.Steel)
		ageIcon.Position = UDim2.new(0.065, contentOffsetX, 0.332, 0)
		local playersIcon = addIcon(card, "Players", UDim2.fromOffset(15, 15), COLORS.Steel)
		playersIcon.Position = UDim2.new(0.095, contentOffsetX, 0.332, 0)

		local empty = label(card, "AUCUN MONDE\nCommencez une nouvelle aventure.", UDim2.fromScale(0.82, 0.16), 14, Enum.Font.GothamBold)
		empty.Position = UDim2.fromScale(0.5, 0.52)
		empty.AnchorPoint = Vector2.new(0.5, 0.5)
		empty.TextXAlignment = Enum.TextXAlignment.Center
		empty.TextYAlignment = Enum.TextYAlignment.Center
		empty.TextColor3 = COLORS.Muted
		empty.TextWrapped = true

		local action = button(card, "", UDim2.fromScale(0.6, 0.09), true)
		action.Position = UDim2.fromScale(0.5, 0.94)
		action.AnchorPoint = Vector2.new(0.5, 1)
		action.BackgroundColor3 = Color3.fromRGB(16, 71, 116)
		action:SetAttribute("BaseColor", Color3.fromRGB(16, 71, 116))
		action:SetAttribute("HoverColor", Color3.fromRGB(22, 91, 145))
		action:SetAttribute("HoverScale", 1.015)
		action:SetAttribute("PressedScale", 0.97)
		local actionGradient = Instance.new("UIGradient")
		actionGradient.Color = ColorSequence.new(Color3.fromRGB(25, 103, 164), Color3.fromRGB(12, 53, 91))
		actionGradient.Rotation = 90
		actionGradient.Parent = action
		local actionStroke = action:FindFirstChildOfClass("UIStroke")
		if actionStroke then actionStroke.Color = Color3.fromRGB(79, 180, 230); actionStroke.Transparency = 0.38 end
		local actionIcon = addIcon(action, "Continue", UDim2.fromOffset(17, 17), COLORS.Text)
		actionIcon.Position = UDim2.new(0, 22, 0.5, 0)
		action.Activated:Connect(function()
			if self.SessionState and self.SessionState.Active then
				if index == self.SessionState.WorldSlot then self:_startFromResponse(self:_invoke("Join")) end
			elseif self.SessionState and self.SessionState.Slots and self.SessionState.Slots[index] then
				self:_startFromResponse(self:_invoke("Continue", {WorldSlot = index}))
			else
				self.SelectedSlot = index; self:_show(self.Create)
			end
		end)
		self.WorldCards[index] = {Frame = card, SlotLabel = slotLabel, Rename = rename, Delete = deleteButton,
			Members = membersButton, Name = worldName, Meta = meta, Empty = empty, Action = action,
			AgeIcon = ageIcon, PlayersIcon = playersIcon}
	end
	local back = Instance.new("TextButton")
	back.Name = "ReturnHitbox"
	back.Size = rectSize(VisualConfig.RETURN_BUTTON_RECT)
	back.Position = rectPosition(VisualConfig.RETURN_BUTTON_RECT)
	back.BackgroundTransparency = 1
	back.Text = ""
	back.AutoButtonColor = false
	back.Parent = panel
	back.Activated:Connect(function() self:_show(self.Home) end)
	self.WorldFeedback = label(panel, "", UDim2.fromScale(0.6, 0.04), 10, Enum.Font.GothamBold)
	self.WorldFeedback.Position = UDim2.fromScale(0.2, 0.91); self.WorldFeedback.TextColor3 = COLORS.Danger
	self.WorldFeedback.TextXAlignment = Enum.TextXAlignment.Right
	local joinedWorldsHitbox = Instance.new("TextButton")
	joinedWorldsHitbox.Name = "JoinedWorldsHitbox"
	joinedWorldsHitbox.Position = rectPosition(VisualConfig.JOINED_WORLDS_BUTTON_RECT)
	joinedWorldsHitbox.Size = rectSize(VisualConfig.JOINED_WORLDS_BUTTON_RECT)
	joinedWorldsHitbox.BackgroundTransparency = 1
	joinedWorldsHitbox.Text = ""
	joinedWorldsHitbox.TextTransparency = 1
	joinedWorldsHitbox.AutoButtonColor = false
	joinedWorldsHitbox.BorderSizePixel = 0
	joinedWorldsHitbox.ZIndex = 20
	joinedWorldsHitbox.Parent = panel
	joinedWorldsHitbox.Activated:Connect(function()
		self:_renderJoinedWorlds(self.SessionState or {})
		self:_show(self.JoinedWorlds)
	end)
end

function controller:_renderJoinedWorlds(state)
	self.SessionState = state
	local joined = state.JoinedWorlds or {}
	for index, card in ipairs(self.JoinedWorldCards or {}) do
		local saved = joined[index]
		card.Name.Text = saved and (saved.DisplayName or "MONDE REJOINT") or ""
		card.Meta.Text = saved and string.format("PROPRIÉTAIRE : %s\n%d / 6 MEMBRES\n%s",
			string.upper(saved.Name or tostring(saved.OwnerUserId)), saved.MemberCount or 1,
			saved.Active and "SESSION EN COURS" or "HORS LIGNE") or ""
		card.Empty.Visible = saved == nil
		card.Join.Visible = saved ~= nil
		card.Members.Visible = saved ~= nil
		card.Leave.Visible = saved ~= nil
		card.WorldId = saved and saved.WorldId or nil
	end
	local invite = state.PendingInvites and state.PendingInvites[1]
	self.InviteBanner.Visible = invite ~= nil
	if invite then
		self.InviteText.Text = string.format("INVITATION — %s — %s", invite.DisplayName or "MONDE PRIVÉ",
			invite.Name or tostring(invite.OwnerUserId))
		self.InviteWorldId = invite.WorldId
	end
end

function controller:_buildJoinedWorlds()
	local panel = Instance.new("Frame")
	panel.Name = "JoinedWorlds"; panel.Size = UDim2.fromScale(1, 1); panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.BackgroundTransparency = 1; panel.Visible = false
	panel.Parent = self.MenuViewport; self.JoinedWorlds = panel; self.JoinedWorldCards = {}
	for index = 1, Config.JOINED_WORLD_SLOT_COUNT do
		local card = Instance.new("Frame")
		card.Name = "JoinedWorldCard" .. index; card.BackgroundTransparency = 1
		card.Position = rectPosition(VisualConfig.WORLD_SLOT_RECTS[index]); card.Size = rectSize(VisualConfig.WORLD_SLOT_RECTS[index]); card.Parent = panel
		local name = label(card, "", UDim2.fromScale(0.88, 0.12), 22, Enum.Font.GothamBlack)
		name.Position = UDim2.fromScale(0.06, 0.17); name.TextTruncate = Enum.TextTruncate.AtEnd
		local meta = label(card, "", UDim2.fromScale(0.88, 0.24), 11, Enum.Font.GothamBold)
		meta.Position = UDim2.fromScale(0.06, 0.32); meta.TextWrapped = true; meta.TextColor3 = COLORS.Muted
		local empty = label(card, "AUCUN MONDE REJOINT\n\nAcceptez une invitation\npour rejoindre un monde privé.",
			UDim2.fromScale(0.84, 0.3), 13, Enum.Font.GothamBold)
		empty.Position = UDim2.fromScale(0.5, 0.53); empty.AnchorPoint = Vector2.new(0.5, 0.5)
		empty.TextWrapped = true; empty.TextXAlignment = Enum.TextXAlignment.Center; empty.TextColor3 = COLORS.Muted
		local join = button(card, "REJOINDRE", UDim2.fromScale(0.58, 0.09), true)
		join.Position = UDim2.fromScale(0.5, 0.94); join.AnchorPoint = Vector2.new(0.5, 1)
		local members = button(card, "MEMBRES", UDim2.fromScale(0.38, 0.07), false)
		members.Position = UDim2.fromScale(0.06, 0.78)
		local leave = button(card, "QUITTER", UDim2.fromScale(0.38, 0.07), false, true)
		leave.Position = UDim2.fromScale(0.56, 0.78)
		local record = {Frame = card, Name = name, Meta = meta, Empty = empty, Join = join, Members = members, Leave = leave}
		join.Activated:Connect(function()
			if record.WorldId then self:_startFromResponse(self:_invoke("JoinJoinedWorld", {WorldId = record.WorldId})) end
		end)
		members.Activated:Connect(function() if record.WorldId then self:_openMembers(record.WorldId, false) end end)
		leave.Activated:Connect(function()
			if not record.WorldId then return end
			local response = self:_invoke("LeaveWorld", {WorldId = record.WorldId})
			if response and response.Ok then self:_refreshWorlds(); self:_renderJoinedWorlds(self.SessionState or {})
			else self.JoinedFeedback.Text = self:_errorMessage(response and response.Error) end
		end)
		self.JoinedWorldCards[index] = record
	end
	local back = Instance.new("TextButton")
	back.Name = "OwnedWorldsHitbox"; back.Size = UDim2.fromScale(0.2, 0.125); back.Position = UDim2.fromScale(0.025, 0.85)
	back.BackgroundTransparency = 1; back.Text = ""; back.Parent = panel
	back.Activated:Connect(function() self:_show(self.Worlds) end)
	self.JoinedFeedback = label(panel, "", UDim2.fromScale(0.55, 0.04), 10, Enum.Font.GothamBold)
	self.JoinedFeedback.Position = UDim2.fromScale(0.225, 0.92); self.JoinedFeedback.TextColor3 = COLORS.Danger
	local banner = Instance.new("Frame")
	banner.Size = UDim2.fromScale(0.62, 0.07); banner.Position = UDim2.fromScale(0.19, 0.16)
	banner.BackgroundColor3 = Color3.fromRGB(8, 24, 36); banner.BackgroundTransparency = 0.08; banner.Visible = false; banner.Parent = panel
	corner(banner, 8); stroke(banner, COLORS.Accent, 0.35); self.InviteBanner = banner
	self.InviteText = label(banner, "", UDim2.fromScale(0.65, 1), 11, Enum.Font.GothamBold)
	local accept = button(banner, "ACCEPTER", UDim2.fromScale(0.16, 0.72), true); accept.Position = UDim2.fromScale(0.66, 0.14)
	local decline = button(banner, "REFUSER", UDim2.fromScale(0.16, 0.72), false, true); decline.Position = UDim2.fromScale(0.83, 0.14)
	accept.Activated:Connect(function()
		if not self.InviteWorldId then return end
		local response = self:_invoke("AcceptInvite", {WorldId = self.InviteWorldId})
		if response and response.Ok then self:_refreshWorlds(); self:_renderJoinedWorlds(self.SessionState or {})
		else self.JoinedFeedback.Text = self:_errorMessage(response and response.Error) end
	end)
	decline.Activated:Connect(function()
		if not self.InviteWorldId then return end
		local response = self:_invoke("DeclineInvite", {WorldId = self.InviteWorldId})
		if response and response.Ok then self:_refreshWorlds(); self:_renderJoinedWorlds(self.SessionState or {}) end
	end)
end

function controller:_openMembers(worldId, ownerView)
	local response = self:_invoke("GetMembers", {WorldId = worldId})
	if not response or not response.Ok then return end
	self.MembershipWorldId = worldId; self.MembershipOwnerView = ownerView
	for _, child in self.MembershipList:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
	for _, member in response.Membership.Members do
		local row = Instance.new("Frame"); row.Size = UDim2.new(1, -10, 0, 46); row.BackgroundColor3 = Color3.fromRGB(13, 31, 43); row.BackgroundTransparency = 0.08; row.BorderSizePixel = 0; row.ZIndex = 42; row.Parent = self.MembershipList
		corner(row, 8); stroke(row, Color3.fromRGB(55, 111, 132), 0.55)
		local textValue = label(row, string.format("%s   %s", member.Name, member.Role == "Owner" and "PROPRIÉTAIRE" or "MEMBRE"), UDim2.new(0.72, 0, 1, 0), 11, Enum.Font.GothamBold)
		textValue.Position = UDim2.fromOffset(14, 0); textValue.TextColor3 = member.Role == "Owner" and Color3.fromRGB(104, 220, 238) or Color3.fromRGB(235, 242, 247); textValue.ZIndex = 43
		if ownerView and member.Role ~= "Owner" then
			local remove = button(row, "RETIRER", UDim2.new(0.25, 0, 0, 32), false, true); remove.Position = UDim2.new(0.75, 0, 0, 5)
			remove.ZIndex = 43
			remove.Activated:Connect(function()
				local removed = self:_invoke("RemoveMember", {WorldId = worldId, MemberUserId = member.UserId})
				if removed and removed.Ok then self:_openMembers(worldId, true) end
			end)
		end
	end
	self.InviteFriendButton.Visible = ownerView
	self:_setModalVisible(self.MembershipModal, self.MembershipShadow, true)
end

function controller:_buildMembership(gui)
	self.MembershipModal, self.MembershipShadow = modal(gui, "MembershipModal", UDim2.fromOffset(600, 540))
	self.MembershipModal.BackgroundColor3 = Color3.fromRGB(8, 17, 26); self.MembershipModal.BackgroundTransparency = 0.02
	padding(self.MembershipModal, 28, 24)
	local title = label(self.MembershipModal, "MEMBRES DU MONDE", UDim2.new(1, 0, 0, 34), 21, Enum.Font.GothamBlack); title.TextColor3 = Color3.fromRGB(241, 247, 250); title.ZIndex = 42
	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, 0, 1, -120); list.Position = UDim2.fromOffset(0, 50); list.BackgroundColor3 = Color3.fromRGB(6, 14, 22); list.BackgroundTransparency = 0.18
	list.BorderSizePixel = 0; list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.CanvasSize = UDim2.new(); list.ScrollBarThickness = 6; list.ScrollBarImageColor3 = Color3.fromRGB(72, 166, 190); list.ClipsDescendants = true
	list.ZIndex = 41; list.Parent = self.MembershipModal; self.MembershipList = list
	corner(list, 9); local listPadding = Instance.new("UIPadding"); listPadding.PaddingTop = UDim.new(0, 8); listPadding.PaddingBottom = UDim.new(0, 8); listPadding.PaddingLeft = UDim.new(0, 8); listPadding.PaddingRight = UDim.new(0, 8); listPadding.Parent = list
	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 7); layout.Parent = list
	local close = button(self.MembershipModal, "FERMER", UDim2.fromOffset(130, 44), false)
	close.Position = UDim2.new(0, 0, 1, 0); close.AnchorPoint = Vector2.new(0, 1); close.ZIndex = 41
	close.Activated:Connect(function() self:_setModalVisible(self.MembershipModal, self.MembershipShadow, false) end)
	local invite = button(self.MembershipModal, "INVITER UN AMI", UDim2.fromOffset(190, 44), true)
	invite.Position = UDim2.new(1, 0, 1, 0); invite.AnchorPoint = Vector2.new(1, 1); invite.ZIndex = 41
	self.InviteFriendButton = invite
	invite.Activated:Connect(function()
		local response = self:_invoke("ListFriends")
		if not response or not response.Ok then return end
		for _, child in list:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
		local friends = response.Friends or {}
		if #friends == 0 then
			local empty = label(list, "AUCUN AMI ROBLOX DISPONIBLE À INVITER", UDim2.new(1, -10, 0, 58), 12, Enum.Font.GothamBold)
			empty.TextColor3 = Color3.fromRGB(166, 188, 201); empty.TextXAlignment = Enum.TextXAlignment.Center; empty.ZIndex = 42
		end
		for _, friend in friends do
			local row = Instance.new("Frame"); row.Size = UDim2.new(1, -10, 0, 46); row.BackgroundColor3 = Color3.fromRGB(13, 31, 43); row.BackgroundTransparency = 0.08; row.BorderSizePixel = 0; row.ZIndex = 42; row.Parent = list
			corner(row, 8); stroke(row, Color3.fromRGB(55, 111, 132), 0.55)
			local friendName = label(row, friend.DisplayName or friend.Name, UDim2.new(0.64, -14, 1, 0), 11, Enum.Font.GothamBold)
			friendName.Position = UDim2.fromOffset(14, 0); friendName.TextColor3 = Color3.fromRGB(235, 242, 247); friendName.ZIndex = 43
			local send = button(row, "INVITER", UDim2.new(0.3, 0, 0, 32), true); send.Position = UDim2.new(0.68, 0, 0, 5)
			send.ZIndex = 43
			send.Activated:Connect(function()
				local invited = self:_invoke("InviteMember", {WorldId = self.MembershipWorldId, TargetUserId = friend.UserId})
				send.Text = invited and invited.Ok and "ENVOYÉE" or self:_errorMessage(invited and invited.Error)
			end)
		end
	end)
end

function controller:_buildCreate(gui)
	local panel, shadowFrame = modal(gui, "Create", UDim2.fromOffset(620, 400))
	panel.Visible = false; shadowFrame.Visible = false; panel.ZIndex = 10; shadowFrame.ZIndex = 9
	self.Create, self.CreateShadow = panel, shadowFrame
	padding(panel, 34, 30)
	local title = label(panel, "NOUVELLE PARTIE", UDim2.new(1, 0, 0, 36), 24, Enum.Font.GothamBlack); title.ZIndex = 11
	local subtitle = label(panel, "CONFIGUREZ VOTRE MONDE PERSISTANT", UDim2.new(1, 0, 0, 22), 10, Enum.Font.GothamBold)
	subtitle.Position = UDim2.fromOffset(0, 42); subtitle.TextColor3 = COLORS.Muted; subtitle.ZIndex = 11
	local maxLabel = label(panel, "JOUEURS MAXIMUM", UDim2.new(1, 0, 0, 24), 11, Enum.Font.GothamBold)
	maxLabel.Position = UDim2.fromOffset(0, 92); maxLabel.TextColor3 = COLORS.Steel; maxLabel.ZIndex = 11
	local choices = Instance.new("Frame")
	choices.Size = UDim2.new(1, 0, 0, 54); choices.Position = UDim2.fromOffset(0, 126); choices.BackgroundTransparency = 1; choices.ZIndex = 11; choices.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal; layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.Padding = UDim.new(0, 10); layout.Parent = choices
	self.PlayerChoices = {}
	for count = Config.MIN_PLAYERS, Config.MAX_PLAYERS do
		local choice = button(choices, tostring(count), UDim2.fromOffset(72, 52), false); choice.ZIndex = 12
		choice.Activated:Connect(function()
			self.MaxPlayers = count
			for value, other in self.PlayerChoices do
				local selected = value == count; other:SetAttribute("Selected", selected)
				other.BackgroundColor3 = selected and COLORS.Accent or COLORS.PanelSoft
			end
		end)
		self.PlayerChoices[count] = choice
	end
	self.PlayerChoices[self.MaxPlayers]:SetAttribute("Selected", true); self.PlayerChoices[self.MaxPlayers].BackgroundColor3 = COLORS.Accent
	self.Feedback = label(panel, "SAUVEGARDE SÉCURISÉE  •  MONDE PARTAGÉ", UDim2.new(1, 0, 0, 28), 10)
	self.Feedback.Position = UDim2.fromOffset(0, 210); self.Feedback.TextColor3 = COLORS.Muted; self.Feedback.ZIndex = 11
	local cancel = button(panel, "ANNULER", UDim2.fromOffset(145, 50), false)
	cancel.Position = UDim2.new(0, 0, 1, 0); cancel.AnchorPoint = Vector2.new(0, 1); cancel.ZIndex = 11
	cancel.Activated:Connect(function() if not self.Loading then self:_show(self.Worlds); self:_refreshWorlds() end end)
	self.CreateButton = button(panel, "CRÉER LE MONDE", UDim2.fromOffset(210, 50), true)
	self.CreateButton.Position = UDim2.new(1, 0, 1, 0); self.CreateButton.AnchorPoint = Vector2.new(1, 1); self.CreateButton.ZIndex = 11
	self.CreateButton.Activated:Connect(function()
		self:_startFromResponse(self:_invoke("Create", {WorldSlot = self.SelectedSlot, MaxPlayers = self.MaxPlayers}))
	end)
end

function controller:_buildRename(gui)
	self.RenameModal, self.RenameShadow = modal(gui, "RenameModal", UDim2.fromOffset(500, 310))
	padding(self.RenameModal, 32, 28)
	local title = label(self.RenameModal, "RENOMMER LE MONDE", UDim2.new(1, 0, 0, 34), 21, Enum.Font.GothamBlack); title.ZIndex = 41
	local fieldLabel = label(self.RenameModal, "NOM DU MONDE", UDim2.new(1, 0, 0, 20), 10, Enum.Font.GothamBold)
	fieldLabel.Position = UDim2.fromOffset(0, 60); fieldLabel.TextColor3 = COLORS.Steel; fieldLabel.ZIndex = 41
	self.RenameInput = Instance.new("TextBox")
	self.RenameInput.Size = UDim2.new(1, 0, 0, 54); self.RenameInput.Position = UDim2.fromOffset(0, 88)
	self.RenameInput.BackgroundColor3 = COLORS.Background; self.RenameInput.TextColor3 = COLORS.Text
	self.RenameInput.PlaceholderText = "NOM DU MONDE"; self.RenameInput.ClearTextOnFocus = false
	self.RenameInput.TextSize = 15; self.RenameInput.Font = Enum.Font.GothamMedium; self.RenameInput.TextXAlignment = Enum.TextXAlignment.Left
	self.RenameInput.ZIndex = 41; self.RenameInput.Parent = self.RenameModal; corner(self.RenameInput, 9); padding(self.RenameInput, 16, 0)
	local inputStroke = stroke(self.RenameInput, COLORS.Stroke, 0.4)
	self.RenameInput.Focused:Connect(function() TweenService:Create(inputStroke, FAST, {Color = COLORS.Accent, Transparency = 0.05}):Play() end)
	self.RenameInput.FocusLost:Connect(function() TweenService:Create(inputStroke, FAST, {Color = COLORS.Stroke, Transparency = 0.4}):Play() end)
	self.RenameCounter = label(self.RenameModal, "0 / 28", UDim2.new(1, 0, 0, 18), 9)
	self.RenameCounter.Position = UDim2.fromOffset(0, 148); self.RenameCounter.TextXAlignment = Enum.TextXAlignment.Right; self.RenameCounter.TextColor3 = COLORS.Muted; self.RenameCounter.ZIndex = 41
	self.RenameInput:GetPropertyChangedSignal("Text"):Connect(function() self.RenameCounter.Text = tostring(utf8.len(self.RenameInput.Text) or 0) .. " / 28" end)
	self.RenameFeedback = label(self.RenameModal, "", UDim2.new(1, 0, 0, 28), 10, Enum.Font.GothamBold)
	self.RenameFeedback.Position = UDim2.fromOffset(0, 172); self.RenameFeedback.TextColor3 = COLORS.Danger; self.RenameFeedback.ZIndex = 41
	local cancel = button(self.RenameModal, "ANNULER", UDim2.fromOffset(140, 48), false)
	cancel.Position = UDim2.new(0, 0, 1, 0); cancel.AnchorPoint = Vector2.new(0, 1); cancel.ZIndex = 41
	cancel.Activated:Connect(function() if not self.Loading then self:_setModalVisible(self.RenameModal, self.RenameShadow, false) end end)
	local save = button(self.RenameModal, "ENREGISTRER", UDim2.fromOffset(180, 48), true)
	save.Position = UDim2.new(1, 0, 1, 0); save.AnchorPoint = Vector2.new(1, 1); save.ZIndex = 41
	save.Activated:Connect(function()
		local response = self:_invoke("RenameWorld", {WorldSlot = self.RenameSlot, WorldId = self.RenameWorldId, DisplayName = self.RenameInput.Text})
		if response and response.Ok then self:_setModalVisible(self.RenameModal, self.RenameShadow, false); self:_renderWorldState(response.State or {})
		else self.RenameFeedback.Text = self:_errorMessage(response and response.Error) end
	end)
end

function controller:_buildDelete(gui)
	self.DeleteModal, self.DeleteShadow = modal(gui, "DeleteModal", UDim2.fromOffset(520, 330))
	padding(self.DeleteModal, 32, 28)
	local warningIcon = addIcon(self.DeleteModal, "Warning", UDim2.fromOffset(30, 30), COLORS.Danger)
	warningIcon.Position = UDim2.fromOffset(15, 17)
	local title = label(self.DeleteModal, "SUPPRIMER CE MONDE ?", UDim2.new(1, -50, 0, 34), 21, Enum.Font.GothamBlack)
	title.Position = UDim2.fromOffset(50, 0); title.ZIndex = 41
	self.DeleteWorldLabel = label(self.DeleteModal, "", UDim2.new(1, 0, 0, 34), 17, Enum.Font.GothamBold)
	self.DeleteWorldLabel.Position = UDim2.fromOffset(0, 62); self.DeleteWorldLabel.TextColor3 = COLORS.Text; self.DeleteWorldLabel.ZIndex = 41
	local warning = label(self.DeleteModal, "Cette action supprimera définitivement la sauvegarde de ce monde.", UDim2.new(1, 0, 0, 58), 11)
	warning.Position = UDim2.fromOffset(0, 108); warning.TextWrapped = true; warning.TextColor3 = COLORS.Muted; warning.ZIndex = 41
	local cancel = button(self.DeleteModal, "ANNULER", UDim2.fromOffset(140, 48), false)
	cancel.Position = UDim2.new(0, 0, 1, 0); cancel.AnchorPoint = Vector2.new(0, 1); cancel.ZIndex = 41
	cancel.Activated:Connect(function() if not self.Loading then self:_setModalVisible(self.DeleteModal, self.DeleteShadow, false) end end)
	local proceed = button(self.DeleteModal, "SUPPRIMER", UDim2.fromOffset(165, 48), false, true)
	proceed.Position = UDim2.new(1, 0, 1, 0); proceed.AnchorPoint = Vector2.new(1, 1); proceed.ZIndex = 41
	proceed.Activated:Connect(function()
		self:_setModalVisible(self.DeleteModal, self.DeleteShadow, false)
		self.DeleteConfirmInput.Text = ""
		self.DeleteFeedback.Text = ""
		self:_setModalVisible(self.DeleteConfirmModal, self.DeleteConfirmShadow, true)
		self.DeleteConfirmInput:CaptureFocus()
	end)

	self.DeleteConfirmModal, self.DeleteConfirmShadow = modal(gui, "DeleteConfirmModal", UDim2.fromOffset(540, 380))
	padding(self.DeleteConfirmModal, 32, 28)
	local confirmTitle = label(self.DeleteConfirmModal, "CONFIRMER LA SUPPRESSION", UDim2.new(1, 0, 0, 34), 20, Enum.Font.GothamBlack)
	confirmTitle.ZIndex = 41
	local instruction = label(self.DeleteConfirmModal, "Tapez SUPPRIMER pour continuer.", UDim2.new(1, 0, 0, 26), 11)
	instruction.Position = UDim2.fromOffset(0, 58); instruction.TextColor3 = COLORS.Muted; instruction.ZIndex = 41
	self.DeleteConfirmInput = Instance.new("TextBox")
	self.DeleteConfirmInput.Size = UDim2.new(1, 0, 0, 54); self.DeleteConfirmInput.Position = UDim2.fromOffset(0, 96)
	self.DeleteConfirmInput.BackgroundColor3 = COLORS.Background; self.DeleteConfirmInput.TextColor3 = COLORS.Text
	self.DeleteConfirmInput.PlaceholderText = "SUPPRIMER"; self.DeleteConfirmInput.ClearTextOnFocus = false
	self.DeleteConfirmInput.TextSize = 14; self.DeleteConfirmInput.Font = Enum.Font.GothamBold; self.DeleteConfirmInput.ZIndex = 41
	self.DeleteConfirmInput.Parent = self.DeleteConfirmModal; corner(self.DeleteConfirmInput, 9); stroke(self.DeleteConfirmInput, COLORS.Danger, 0.48); padding(self.DeleteConfirmInput, 16, 0)
	self.DeleteFeedback = label(self.DeleteConfirmModal, "", UDim2.new(1, 0, 0, 40), 10, Enum.Font.GothamBold)
	self.DeleteFeedback.Position = UDim2.fromOffset(0, 166); self.DeleteFeedback.TextColor3 = COLORS.Danger; self.DeleteFeedback.ZIndex = 41
	local confirmCancel = button(self.DeleteConfirmModal, "ANNULER", UDim2.fromOffset(140, 48), false)
	confirmCancel.Position = UDim2.new(0, 0, 1, 0); confirmCancel.AnchorPoint = Vector2.new(0, 1); confirmCancel.ZIndex = 41
	confirmCancel.Activated:Connect(function() if not self.Loading then self:_setModalVisible(self.DeleteConfirmModal, self.DeleteConfirmShadow, false) end end)
	self.DeleteConfirmButton = button(self.DeleteConfirmModal, "SUPPRIMER DÉFINITIVEMENT", UDim2.fromOffset(245, 48), false, true)
	self.DeleteConfirmButton.Position = UDim2.new(1, 0, 1, 0); self.DeleteConfirmButton.AnchorPoint = Vector2.new(1, 1); self.DeleteConfirmButton.ZIndex = 41
	self.DeleteConfirmButton.Activated:Connect(function()
		if string.upper(self.DeleteConfirmInput.Text:match("^%s*(.-)%s*$")) ~= "SUPPRIMER" then
			self.DeleteFeedback.Text = "SAISISSEZ EXACTEMENT SUPPRIMER"
			return
		end
		local deleteSlot = self.DeleteSlot
		local deleteWorldId = self.DeleteWorldId
		if RunService:IsStudio() then
			print(string.format(
				"[MAYDEAD][WORLD_UI][DELETE] Action=Request WorldId=%s Slot=%s OwnedCountBefore=%d",
				tostring(deleteWorldId), tostring(deleteSlot), ownedWorldCount(self.SessionState)
			))
		end
		local response = self:_invoke("DeleteWorld", {
			WorldSlot = deleteSlot,
			WorldId = deleteWorldId,
			Confirmation = "DELETE",
		})
		if response and response.Ok and response.Deleted then
			self:_setModalVisible(self.DeleteConfirmModal, self.DeleteConfirmShadow, false)
			local optimisticSnapshot = snapshotWithoutDeletedWorld(self.SessionState, deleteSlot, deleteWorldId)
			if optimisticSnapshot then self:_renderWorldState(optimisticSnapshot) end
			self.WorldFeedback.Text = "MONDE SUPPRIMÉ"
			self.WorldFeedback.TextColor3 = COLORS.Success
			if RunService:IsStudio() then
				print(string.format(
					"[MAYDEAD][WORLD_UI][DELETE] Action=Success WorldId=%s Slot=%s RefreshingOwnedWorlds=true",
					tostring(deleteWorldId), tostring(deleteSlot)
				))
			end
			self:_refreshWorlds()
		else
			self.DeleteFeedback.Text = self:_errorMessage(response and response.Error)
		end
	end)
end

function controller:_returnToMenuFromResponse(response)
	if not response or not response.Ok or not response.ReturnedToMenu then
		self.ReturnFeedback.Text = self:_errorMessage(response and response.Error); self.ReturnFeedback.Visible = true; return
	end
	self:_setModalVisible(self.ReturnModal, self.ReturnShadow, false)
	self.SessionControls.Enabled = false; self.Gui.Enabled = true; self.Fade.BackgroundTransparency = 1
	self:_bindMenuInput(); self:_show(self.Home); self:_applyMenuCamera(); self:_renderWorldState(response.State or {})
	self:_setMenuMusic(true)
end

local function rectanglesOverlap(first, second, paddingAmount)
	local paddingValue = paddingAmount or 0
	local firstPosition = first.AbsolutePosition
	local firstSize = first.AbsoluteSize
	local secondPosition = second.AbsolutePosition
	local secondSize = second.AbsoluteSize
	return firstPosition.X < secondPosition.X + secondSize.X + paddingValue
		and firstPosition.X + firstSize.X + paddingValue > secondPosition.X
		and firstPosition.Y < secondPosition.Y + secondSize.Y + paddingValue
		and firstPosition.Y + firstSize.Y + paddingValue > secondPosition.Y
end

function controller:_usesTouchLayout()
	local touchPreferred = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	pcall(function()
		touchPreferred = UserInputService.PreferredInput == Enum.PreferredInput.Touch
	end)
	return touchPreferred
end

function controller:_setSessionMenuPosition(rightMargin, topOffset)
	if not self.SessionMenuButton then return end
	self.SessionMenuButton.Position = UDim2.new(1, -rightMargin, 0, topOffset)
end

function controller:_updateSessionControlsLayout()
	if not self.SessionMenuButton or not self.SessionControls then return end
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local compact = viewport.X < 600 or viewport.Y < 450
	local touchLayout = self:_usesTouchLayout()
	local topLeftInset = GuiService:GetGuiInset()
	local edgeMargin = compact and 12 or 18
	local topOffset = math.max(compact and 12 or 18, math.floor(topLeftInset.Y * 0.25))

	self.SessionMenuButton.Size = compact and UDim2.fromOffset(92, 38) or UDim2.fromOffset(104, 42)
	self:_setSessionMenuPosition(edgeMargin, topOffset)
	self.SessionControls:SetAttribute("LayoutMode", touchLayout and (compact and "Phone" or "Tablet") or "Desktop")

	local layoutRevision = (self.SessionMenuLayoutRevision or 0) + 1
	self.SessionMenuLayoutRevision = layoutRevision
	if not touchLayout then
		self.SessionControls:SetAttribute("InventoryCollisionFree", true)
	end
	task.defer(function()
		if self.SessionMenuLayoutRevision ~= layoutRevision or not touchLayout then return end
		local inventoryButton = player.PlayerGui:FindFirstChild("MobileInventoryButton", true)
		if not inventoryButton or not inventoryButton:IsA("GuiObject") or not inventoryButton.Visible then
			self.SessionControls:SetAttribute("InventoryCollisionFree", true)
			return
		end

		local separation = compact and 10 or 14
		if rectanglesOverlap(self.SessionMenuButton, inventoryButton, separation) then
			local targetAbsoluteTop = inventoryButton.AbsolutePosition.Y + inventoryButton.AbsoluteSize.Y + separation
			local correctedTop = self.SessionMenuButton.Position.Y.Offset
				+ targetAbsoluteTop - self.SessionMenuButton.AbsolutePosition.Y
			self:_setSessionMenuPosition(edgeMargin, correctedTop)
		end

		task.defer(function()
			if self.SessionMenuLayoutRevision ~= layoutRevision then return end
			self.SessionControls:SetAttribute(
				"InventoryCollisionFree",
				not rectanglesOverlap(self.SessionMenuButton, inventoryButton, 0)
			)
		end)
	end)
end

function controller:_buildSessionControls()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MAYDEADSessionControls"; gui.IgnoreGuiInset = false; gui.ResetOnSpawn = false; gui.DisplayOrder = 900
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.Enabled = player:GetAttribute("SessionStarted") == true; gui.Parent = player.PlayerGui; self.SessionControls = gui
	local returnButton = Instance.new("ImageButton")
	returnButton.Name = "SessionMenuButton"
	returnButton.Size = UDim2.fromOffset(104, 42)
	returnButton.Position = UDim2.new(1, -18, 0, 18); returnButton.AnchorPoint = Vector2.new(1, 0)
	returnButton.BackgroundTransparency = 1
	returnButton.AutoButtonColor = false
	returnButton.Image = "rbxassetid://131150526179359"
	returnButton.ScaleType = Enum.ScaleType.Fit
	returnButton.Parent = gui
	local menuScale = Instance.new("UIScale")
	menuScale.Parent = returnButton
	returnButton.MouseEnter:Connect(function() TweenService:Create(menuScale, FAST, {Scale = 1.02}):Play() end)
	returnButton.MouseLeave:Connect(function() TweenService:Create(menuScale, FAST, {Scale = 1}):Play() end)
	returnButton.MouseButton1Down:Connect(function() TweenService:Create(menuScale, TweenInfo.new(0.07), {Scale = 0.97}):Play() end)
	returnButton.MouseButton1Up:Connect(function() TweenService:Create(menuScale, TweenInfo.new(0.09), {Scale = 1}):Play() end)
	self.SessionMenuButton = returnButton; self.SessionMenuShadow = nil
	returnButton.Activated:Connect(function() self.ReturnFeedback.Visible = false; self:_setModalVisible(self.ReturnModal, self.ReturnShadow, true) end)
	self.ReturnModal, self.ReturnShadow = modal(gui, "ReturnModal", UDim2.fromOffset(500, 310)); padding(self.ReturnModal, 32, 28)
	local title = label(self.ReturnModal, "RETOUR AU MENU ?", UDim2.new(1, 0, 0, 36), 22, Enum.Font.GothamBlack); title.ZIndex = 41
	local warning = label(self.ReturnModal, "Votre progression sera sauvegardée avant de quitter la partie.", UDim2.new(1, 0, 0, 64), 12)
	warning.Position = UDim2.fromOffset(0, 62); warning.TextWrapped = true; warning.TextColor3 = COLORS.Muted; warning.ZIndex = 41
	self.ReturnFeedback = label(self.ReturnModal, "", UDim2.new(1, 0, 0, 42), 10, Enum.Font.GothamBold)
	self.ReturnFeedback.Position = UDim2.fromOffset(0, 142); self.ReturnFeedback.TextColor3 = COLORS.Danger; self.ReturnFeedback.Visible = false; self.ReturnFeedback.ZIndex = 41
	local cancel = button(self.ReturnModal, "ANNULER", UDim2.fromOffset(140, 48), false)
	cancel.Position = UDim2.new(0, 0, 1, 0); cancel.AnchorPoint = Vector2.new(0, 1); cancel.ZIndex = 41
	cancel.Activated:Connect(function() if not self.Loading then self:_setModalVisible(self.ReturnModal, self.ReturnShadow, false) end end)
	self.ReturnConfirmButton = button(self.ReturnModal, "RETOUR AU MENU", UDim2.fromOffset(190, 48), true)
	self.ReturnConfirmButton.Position = UDim2.new(1, 0, 1, 0); self.ReturnConfirmButton.AnchorPoint = Vector2.new(1, 1); self.ReturnConfirmButton.ZIndex = 41
	self.ReturnConfirmButton.Activated:Connect(function()
		self.ReturnFeedback.Visible = false; self:_returnToMenuFromResponse(self:_invoke("ReturnToMenu"))
	end)
	player:GetAttributeChangedSignal("SessionStarted"):Connect(function()
		gui.Enabled = player:GetAttribute("SessionStarted") == true
		if gui.Enabled then self:_updateSessionControlsLayout() end
	end)
	player.PlayerGui.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "MobileInventoryButton" then
			if descendant:IsA("GuiObject") then
				descendant:GetPropertyChangedSignal("Visible"):Connect(function()
					self:_updateSessionControlsLayout()
				end)
			end
			task.defer(function() self:_updateSessionControlsLayout() end)
		end
	end)
	pcall(function()
		UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
			self:_updateSessionControlsLayout()
		end)
	end)
end

function controller:_updateResponsive()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local nativeSize = self.JoinedWorlds and self.JoinedWorlds.Visible
		and VisualConfig.JOINED_WORLDS_BACKGROUND_NATIVE_SIZE
		or (self.Worlds and self.Worlds.Visible and VisualConfig.WORLDS_BACKGROUND_NATIVE_SIZE
			or VisualConfig.BACKGROUND_NATIVE_SIZE)
	local referenceRatio = nativeSize.X / nativeSize.Y
	local availableRatio = viewport.X / math.max(viewport.Y, 1)
	if availableRatio > referenceRatio then
		self.MenuViewport.Size = UDim2.fromOffset(math.floor(viewport.Y * referenceRatio), viewport.Y)
	else
		self.MenuViewport.Size = UDim2.fromOffset(viewport.X, math.floor(viewport.X / referenceRatio))
	end
	local narrow = viewport.X < 600
	local tablet = viewport.X >= 600 and viewport.X < 980
	local compactHome = narrow or viewport.Y < 500
	self:_updateSessionControlsLayout()
	self.Home.Size = UDim2.fromScale(1, 1)
	self.NarrativeLeadHolder.Size = UDim2.new(1, 0, 0, compactHome and 54 or 42)
	self.NarrativeSupportHolder.Size = UDim2.new(1, 0, 0, compactHome and 52 or 38)
	self.NarrativeLead.TextSize = compactHome and 25 or 22
	self.NarrativeSupport.TextSize = compactHome and 17 or 15
	if self.HomeInviteCard then
		self.HomeInviteCard.Size = narrow and UDim2.new(0.94, 0, 0, 112) or UDim2.new(0.78, 0, 0, 72)
		self.HomeInviteCard.Position = UDim2.fromScale(0.5, narrow and 0.76 or 0.78)
		self.HomeInviteText.Size = narrow and UDim2.new(1, -32, 0, 28) or UDim2.new(0.62, -16, 0, 28)
		self.HomeInviteAccept.Position = narrow and UDim2.new(0.5, -108, 1, -46) or UDim2.new(1, -220, 0.5, -19)
		self.HomeInviteDecline.Position = narrow and UDim2.new(0.5, 8, 1, -46) or UDim2.new(1, -106, 0.5, -19)
	end
	self.ResponsiveScale = math.clamp(math.min(viewport.X / 1180, viewport.Y / 760), narrow and 0.68 or 0.72, 1.18)
	for _, panel in {self.Create} do
		local scale = panel and (panel:FindFirstChild("ResponsiveScale") or Instance.new("UIScale"))
		if scale then scale.Name = "ResponsiveScale"; scale.Scale = self.ResponsiveScale; scale.Parent = panel end
	end
	local homeScale = self.Home:FindFirstChild("ResponsiveScale")
	if homeScale then homeScale.Scale = 1 end
	local worldScale = self.Worlds:FindFirstChild("ResponsiveScale") or Instance.new("UIScale")
	worldScale.Name = "ResponsiveScale"
	self.Worlds.Size = UDim2.fromScale(1, 1)
	worldScale.Scale = 1
	self.WorldsTargetScale = 1
	worldScale.Parent = self.Worlds
	local joinedScale = self.JoinedWorlds:FindFirstChild("ResponsiveScale") or Instance.new("UIScale")
	joinedScale.Name = "ResponsiveScale"; joinedScale.Scale = 1; joinedScale.Parent = self.JoinedWorlds
	for _, modalFrame in {self.RenameModal, self.DeleteModal, self.DeleteConfirmModal, self.MembershipModal} do
		local scale = modalFrame:FindFirstChild("ResponsiveScale") or Instance.new("UIScale")
		scale.Name = "ResponsiveScale"
		scale.Scale = math.clamp(math.min(viewport.X / 590, viewport.Y / 460), 0.66, 1)
		scale.Parent = modalFrame
		modalFrame:SetAttribute("ResponsiveScaleTarget", scale.Scale)
	end
end

function controller:_build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MAYDEADMainMenu"; gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false; gui.DisplayOrder = 1000
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets; gui.Parent = player:WaitForChild("PlayerGui"); self.Gui = gui
	self:_buildBackground(gui); self:_buildHome(gui); self:_buildWorlds(gui); self:_buildJoinedWorlds(); self:_buildCreate(gui)
	self:_buildRename(gui); self:_buildDelete(gui); self:_buildMembership(gui); self:_buildSessionControls()
	self.Fade = Instance.new("Frame")
	self.Fade.Size = UDim2.fromScale(1, 1); self.Fade.BackgroundColor3 = Color3.new(0, 0, 0); self.Fade.BackgroundTransparency = 1
	self.Fade.ZIndex = 100; self.Fade.Parent = gui
	self:_updateResponsive()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() self:_updateResponsive(); self:_applyMenuCamera() end)
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() self:_updateResponsive() end) end
end

function controller:Start()
	if self.Started then return end
	self.Started = true; self.ResponsiveScale = 1; self:_build(); self:_bindMenuInput(); self:_applyMenuCamera(); self:_animateHomeNarrative(); self:_setMenuMusic(true)
	task.defer(function() self:_refreshWorlds() end)
	player.CharacterAdded:Connect(function() task.defer(function() self:_applyMenuCamera() end) end)
end

return controller
