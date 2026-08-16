local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config.CheetahConfig)
local ItemIconConfig = require(ReplicatedStorage.Shared.Config.ItemIconConfig)
local remote = ReplicatedStorage:WaitForChild("CheetahCompanionRemote")
local player = Players.LocalPlayer
local controller = {Mounted = false, TouchSprint = false, State = nil, Cheetah = nil}

local COLORS = {Health=Color3.fromRGB(219,72,78), Hunger=Color3.fromRGB(231,153,58), Stamina=Color3.fromRGB(66,190,211)}

local function corner(parent, radius) local value=Instance.new("UICorner"); value.CornerRadius=UDim.new(0,radius); value.Parent=parent end
local function label(parent,text,size,position,font,textSize,color)
	local value=Instance.new("TextLabel"); value.Size=size; value.Position=position; value.BackgroundTransparency=1; value.Text=text
	value.Font=font or Enum.Font.Gotham; value.TextSize=textSize or 12; value.TextColor3=color or Color3.fromRGB(225,232,239); value.TextXAlignment=Enum.TextXAlignment.Left; value.Parent=parent; return value
end
local function stat(parent,y,name,color)
	local title=label(parent,name,UDim2.new(.55,0,0,17),UDim2.fromOffset(20,y),Enum.Font.GothamSemibold,11,Color3.fromRGB(169,182,196))
	local amount=label(parent,"0 / 100",UDim2.new(.4,-20,0,17),UDim2.new(.6,0,0,y),Enum.Font.GothamBold,11,Color3.fromRGB(235,240,245)); amount.TextXAlignment=Enum.TextXAlignment.Right
	local rail=Instance.new("Frame"); rail.Size=UDim2.new(1,-40,0,6); rail.Position=UDim2.fromOffset(20,y+21); rail.BackgroundColor3=Color3.fromRGB(19,28,35); rail.BorderSizePixel=0; rail.Parent=parent; corner(rail,3)
	local fill=Instance.new("Frame"); fill.Size=UDim2.fromScale(1,1); fill.BackgroundColor3=color; fill.BorderSizePixel=0; fill.Parent=rail; corner(fill,3)
	return {Title=title,Amount=amount,Fill=fill}
end
local function makeButton(parent,text,size,position,callback)
	local value=Instance.new("TextButton"); value.Size=size; value.Position=position; value.Text=text; value.Font=Enum.Font.GothamBold; value.TextSize=11
	value.TextColor3=Color3.fromRGB(231,239,244); value.BackgroundColor3=Color3.fromRGB(19,38,46); value.AutoButtonColor=false; value.Parent=parent; corner(value,8)
	local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(52,94,106); stroke.Transparency=.35; stroke.Parent=value
	value.MouseEnter:Connect(function() TweenService:Create(value,TweenInfo.new(.08),{BackgroundColor3=Color3.fromRGB(26,55,65)}):Play() end)
	value.MouseLeave:Connect(function() TweenService:Create(value,TweenInfo.new(.08),{BackgroundColor3=Color3.fromRGB(19,38,46)}):Play() end)
	value.MouseButton1Down:Connect(function() value.Size=size-UDim2.fromOffset(2,2) end); value.MouseButton1Up:Connect(function() value.Size=size end)
	value.Activated:Connect(callback); return value
end

local function getCheetahInteractionPosition(cheetah)
	if not cheetah or not cheetah.Parent then return nil end
	local root = cheetah:FindFirstChild("HumanoidRootPart") or cheetah:FindFirstChild("Torso") or cheetah.PrimaryPart
	if root and root:IsA("BasePart") then return root.Position end
	local fallback = cheetah:FindFirstChildWhichIsA("BasePart", true)
	return fallback and fallback.Position or nil
end

function controller:Start()
	local gui=Instance.new("ScreenGui"); gui.Name="CheetahCompanionGui"; gui.ResetOnSpawn=false; gui.Enabled=true; gui.DisplayOrder=12; gui.Parent=player:WaitForChild("PlayerGui")
	print(string.format("[MAYDEAD][CHEETAH][UI][CLIENT] Controller started Remote=%s ScreenGui=%s", remote:GetFullName(), gui:GetFullName()))
	local frame=Instance.new("Frame"); frame.Size=UDim2.fromOffset(390,370); frame.Position=UDim2.new(.5,0,.62,0); frame.AnchorPoint=Vector2.new(.5,.5)
	frame.BackgroundColor3=Color3.fromRGB(7,12,17); frame.BackgroundTransparency=.06; frame.BorderSizePixel=0; frame.Visible=false; frame.Parent=gui; corner(frame,15)
	local panelScale=Instance.new("UIScale"); panelScale.Name="ResponsiveScale"; panelScale.Parent=frame
	local function updateScale()
		local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		panelScale.Scale=viewport and math.clamp(math.min((viewport.X-24)/390,(viewport.Y-24)/370),.6,1) or 1
	end
	updateScale(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end
	local gradient=Instance.new("UIGradient"); gradient.Color=ColorSequence.new(Color3.fromRGB(12,25,31),Color3.fromRGB(6,10,15)); gradient.Rotation=90; gradient.Parent=frame
	local border=Instance.new("UIStroke"); border.Color=Color3.fromRGB(49,111,126); border.Transparency=.35; border.Thickness=1; border.Parent=frame
	local nameTitle=label(frame,"GUÉPARD",UDim2.fromOffset(190,24),UDim2.fromOffset(20,16),Enum.Font.GothamBold,18,Color3.fromRGB(242,246,248))
	local badge=label(frame,"●  COMPAGNON",UDim2.fromOffset(150,20),UDim2.new(1,-170,0,19),Enum.Font.GothamBold,10,Color3.fromRGB(73,207,177)); badge.TextXAlignment=Enum.TextXAlignment.Right
	local openNaming
	local renameButton=makeButton(frame,"✎",UDim2.fromOffset(28,24),UDim2.fromOffset(174,16),function() if openNaming then openNaming() end end)
	renameButton.TextSize=16
	local health=stat(frame,55,"SANTÉ",COLORS.Health); local hunger=stat(frame,96,"FAIM",COLORS.Hunger); local stamina=stat(frame,137,"ENDURANCE",COLORS.Stamina)
	label(frame,"NOURRITURE",UDim2.fromOffset(120,16),UDim2.fromOffset(20,178),Enum.Font.GothamSemibold,10,Color3.fromRGB(169,182,196))
	local foodSlot=Instance.new("Frame"); foodSlot.Name="RawMeatSlot"; foodSlot.Size=UDim2.fromOffset(54,54); foodSlot.Position=UDim2.fromOffset(20,197); foodSlot.BackgroundColor3=Color3.fromRGB(13,17,25); foodSlot.BackgroundTransparency=.28; foodSlot.BorderSizePixel=0; foodSlot.Parent=frame; corner(foodSlot,11)
	local foodStroke=Instance.new("UIStroke"); foodStroke.Color=Color3.fromRGB(72,84,100); foodStroke.Transparency=.8; foodStroke.Thickness=1; foodStroke.Parent=foodSlot
	local foodIcon=Instance.new("ImageLabel"); foodIcon.Name="ItemIcon"; foodIcon.Size=UDim2.new(1,-10,1,-10); foodIcon.Position=UDim2.fromOffset(5,5); foodIcon.BackgroundTransparency=1; foodIcon.Image=ItemIconConfig.RawMeat; foodIcon.ScaleType=Enum.ScaleType.Fit; foodIcon.ZIndex=2; foodIcon.Parent=foodSlot
	local foodCount=label(foodSlot,"0",UDim2.new(1,-8,0,16),UDim2.new(0,4,1,-18),Enum.Font.GothamBold,11,Color3.fromRGB(230,235,242)); foodCount.Name="Count"; foodCount.TextXAlignment=Enum.TextXAlignment.Right; foodCount.TextStrokeColor3=Color3.fromRGB(4,7,10); foodCount.TextStrokeTransparency=.25; foodCount.ZIndex=3
	label(frame,"VIANDE CRUE",UDim2.fromOffset(150,20),UDim2.fromOffset(84,214),Enum.Font.GothamSemibold,11,Color3.fromRGB(225,232,239))
	local follow=makeButton(frame,"SUIVRE",UDim2.fromOffset(165,34),UDim2.fromOffset(20,260),function() remote:FireServer("Command","Follow") end)
	local stay=makeButton(frame,"RESTER",UDim2.fromOffset(165,34),UDim2.fromOffset(205,260),function() remote:FireServer("Command","Stay") end)
	local mount=makeButton(frame,"MONTER",UDim2.new(1,-40,0,38),UDim2.fromOffset(20,300),function() remote:FireServer("Mount") end); mount.BackgroundColor3=Color3.fromRGB(25,91,108)
	makeButton(frame,"+ VIANDE",UDim2.fromOffset(165,24),UDim2.fromOffset(20,342),function() remote:FireServer("DepositRawMeat") end)
	makeButton(frame,"- VIANDE",UDim2.fromOffset(165,24),UDim2.fromOffset(205,342),function() remote:FireServer("WithdrawRawMeat") end)

	local naming=Instance.new("Frame"); naming.Size=UDim2.fromOffset(330,190); naming.Position=UDim2.fromScale(.5,.5); naming.AnchorPoint=Vector2.new(.5,.5)
	naming.BackgroundColor3=Color3.fromRGB(7,14,19); naming.BorderSizePixel=0; naming.Visible=false; naming.ZIndex=20; naming.Parent=gui; corner(naming,14)
	local namingScale=Instance.new("UIScale"); namingScale.Parent=naming
	local function updateNamingScale()
		local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		namingScale.Scale=viewport and math.clamp(math.min((viewport.X-24)/330,(viewport.Y-24)/190),.65,1) or 1
	end
	updateNamingScale(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateNamingScale) end
	local namingStroke=Instance.new("UIStroke"); namingStroke.Color=Color3.fromRGB(58,151,169); namingStroke.Transparency=.25; namingStroke.Parent=naming
	local namingTitle=label(naming,"NOMMEZ VOTRE COMPAGNON",UDim2.new(1,-32,0,24),UDim2.fromOffset(16,18),Enum.Font.GothamBold,14,Color3.fromRGB(235,242,245)); namingTitle.ZIndex=21; namingTitle.TextXAlignment=Enum.TextXAlignment.Center
	local nameInput=Instance.new("TextBox"); nameInput.Size=UDim2.new(1,-40,0,42); nameInput.Position=UDim2.fromOffset(20,57); nameInput.BackgroundColor3=Color3.fromRGB(16,29,36); nameInput.BorderSizePixel=0
	nameInput.ClearTextOnFocus=false; nameInput.PlaceholderText="Guépard"; nameInput.Text=""; nameInput.TextColor3=Color3.fromRGB(239,244,247); nameInput.PlaceholderColor3=Color3.fromRGB(119,139,149); nameInput.Font=Enum.Font.GothamSemibold; nameInput.TextSize=15; nameInput.ZIndex=21; nameInput.Parent=naming; corner(nameInput,9)
	local namingFeedback=label(naming,"",UDim2.new(1,-40,0,18),UDim2.fromOffset(20,104),Enum.Font.GothamSemibold,10,Color3.fromRGB(229,105,105)); namingFeedback.ZIndex=21; namingFeedback.TextXAlignment=Enum.TextXAlignment.Center
	local validateName=makeButton(naming,"VALIDER",UDim2.fromOffset(180,34),UDim2.new(.5,-90,1,-58),function()
		namingFeedback.Text=""; remote:FireServer("SetName",nameInput.Text)
	end); validateName.ZIndex=21
	local later=makeButton(naming,"PLUS TARD",UDim2.fromOffset(100,24),UDim2.new(.5,-50,1,-24),function() naming.Visible=false end); later.ZIndex=21; later.BackgroundTransparency=1
	local touchDismount=makeButton(gui,"DESCENDRE",UDim2.fromOffset(156,56),UDim2.new(1,-24,.56,0),function() remote:FireServer("Dismount") end)
	touchDismount.Name="TouchDismountButton"; touchDismount.AnchorPoint=Vector2.new(1,.5); touchDismount.BackgroundColor3=Color3.fromRGB(25,91,108); touchDismount.TextSize=14; touchDismount.Visible=false; touchDismount.ZIndex=10
	local touchDismountStroke=touchDismount:FindFirstChildOfClass("UIStroke"); if touchDismountStroke then touchDismountStroke.Color=Color3.fromRGB(79,178,194); touchDismountStroke.Transparency=.15; touchDismountStroke.Thickness=1.5 end
	local touchSprint=makeButton(gui,"SPRINT",UDim2.fromOffset(156,56),UDim2.new(1,-24,.34,0),function() end)
	touchSprint.Name="TouchSprintButton"; touchSprint.AnchorPoint=Vector2.new(1,.5); touchSprint.BackgroundColor3=Color3.fromRGB(19,38,46); touchSprint.TextSize=14; touchSprint.Visible=false; touchSprint.ZIndex=10
	local touchSprintInput
	touchSprint.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch and touchSprint.Visible then controller.TouchSprint=true; touchSprintInput=input; touchSprint.BackgroundColor3=Color3.fromRGB(36,122,139) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input==touchSprintInput then controller.TouchSprint=false; touchSprintInput=nil; touchSprint.BackgroundColor3=Color3.fromRGB(19,38,46) end
	end)
	local function updateTouchDismountVisibility()
		touchDismount.Visible=UserInputService.TouchEnabled and controller.Mounted
		touchSprint.Visible=UserInputService.TouchEnabled and controller.Mounted
		if not touchSprint.Visible then controller.TouchSprint=false; touchSprintInput=nil end
	end
	openNaming=function()
		nameInput.Text=controller.State and controller.State.CompanionName or "Guépard"
		namingFeedback.Text=""; naming.Visible=true; nameInput:CaptureFocus()
	end
	local function close() frame.Visible=false; naming.Visible=false; controller.Cheetah=nil end
	local mountJumpConnection
	local mountJumpRequestConnection
	local function bindMountJump()
		if mountJumpConnection then mountJumpConnection:Disconnect() end
		if mountJumpRequestConnection then mountJumpRequestConnection:Disconnect() end
		mountJumpConnection=UserInputService.InputBegan:Connect(function(input,processed)
			if not processed and controller.Mounted and input.UserInputType==Enum.UserInputType.MouseButton1 then remote:FireServer("MountJump") end
		end)
		mountJumpRequestConnection=UserInputService.JumpRequest:Connect(function()
			if not controller.Mounted then return end
			local inputType=UserInputService:GetLastInputType()
			if inputType==Enum.UserInputType.Touch or string.find(inputType.Name,"Gamepad",1,true)==1 then
				local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then humanoid.Jump=false end
				remote:FireServer("MountJump")
			end
		end)
	end
	local function unbindMountJump()
		if mountJumpConnection then mountJumpConnection:Disconnect(); mountJumpConnection=nil end
		if mountJumpRequestConnection then mountJumpRequestConnection:Disconnect(); mountJumpRequestConnection=nil end
	end
	local function render(state)
		controller.State=state; local count=0; for _,slot in state.Inventory or {} do count+=slot.Quantity or 0 end
		nameTitle.Text=string.upper(state.CompanionName or "Guépard")
		health.Amount.Text=string.format("%d / %d",state.Health,state.MaxHealth); health.Fill.Size=UDim2.fromScale(math.clamp(state.Health/state.MaxHealth,0,1),1)
		hunger.Amount.Text=string.format("%d / 100",state.Hunger); hunger.Fill.Size=UDim2.fromScale(math.clamp(state.Hunger/100,0,1),1)
		stamina.Amount.Text=string.format("%d / 100",state.MountStamina); stamina.Fill.Size=UDim2.fromScale(math.clamp(state.MountStamina/100,0,1),1); foodCount.Text=tostring(count); foodIcon.ImageTransparency=count==0 and .45 or 0
		follow.BackgroundColor3=state.Command=="Follow" and Color3.fromRGB(27,103,115) or Color3.fromRGB(19,38,46); stay.BackgroundColor3=state.Command=="Stay" and Color3.fromRGB(27,103,115) or Color3.fromRGB(19,38,46)
	end
	remote.OnClientEvent:Connect(function(action,state,cheetah)
		if state and action~="NameResult" then render(state) end
		if action=="Open" then
			local count=0; for _,slot in state.Inventory or {} do count+=slot.Quantity or 0 end
			print(string.format("[MAYDEAD][CHEETAH][UI][CLIENT] Open event received Cheetah=%s OwnerUserId=%s Health=%s MaxHealth=%s Hunger=%s FoodCount=%d Stamina=%s Command=%s Mounted=%s",
				cheetah and cheetah:GetFullName() or "nil", tostring(state.OwnerUserId), tostring(state.Health), tostring(state.MaxHealth),
				tostring(state.Hunger), count, tostring(state.MountStamina), tostring(state.Command), tostring(state.Mounted)))
			controller.Cheetah=cheetah; gui.Enabled=true; frame.Visible=not frame.Visible
			print(string.format("[MAYDEAD][CHEETAH][UI][CLIENT] ScreenGui=true Enabled=%s Frame=true Visible=%s Parent=%s AbsoluteSize=%s AbsolutePosition=%s DisplayOrder=%d",
				tostring(gui.Enabled), tostring(frame.Visible), gui.Parent:GetFullName(), tostring(frame.AbsoluteSize), tostring(frame.AbsolutePosition), gui.DisplayOrder))
			if frame.Visible then print("[MAYDEAD][CHEETAH][UI][CLIENT] CompanionUI opened=true") end
		elseif action=="PromptName" then controller.Cheetah=cheetah; render(state); openNaming()
		elseif action=="NameResult" then
			if state and state.Ok then
				if controller.State then controller.State.CompanionName=state.CompanionName; render(controller.State) end
				naming.Visible=false
			else namingFeedback.Text="NOM INVALIDE" end
		elseif action=="Mounted" then controller.Mounted=true; close(); bindMountJump(); updateTouchDismountVisibility()
		elseif action=="Dismounted" then controller.Mounted=false; unbindMountJump(); updateTouchDismountVisibility()
		elseif action=="State" and frame.Visible then render(state) end
	end)
	UserInputService.InputBegan:Connect(function(input,processed) if not processed and controller.Mounted and input.KeyCode==Enum.KeyCode.E then remote:FireServer("Dismount") end end)
	local deathConnection
	local function cleanupMount()
		controller.Mounted=false; controller.TouchSprint=false; unbindMountJump(); close(); updateTouchDismountVisibility()
	end
	local function watchCharacter(character)
		if deathConnection then deathConnection:Disconnect(); deathConnection=nil end
		local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",5)
		if humanoid then deathConnection=humanoid.Died:Connect(cleanupMount) end
	end
	player.CharacterAdded:Connect(function(character) cleanupMount(); watchCharacter(character) end)
	if player.Character then watchCharacter(player.Character) end
	player:GetAttributeChangedSignal("SessionStarted"):Connect(function() if player:GetAttribute("SessionStarted")~=true then cleanupMount() end end)
	local lastInput,lastDistance=0,0
	RunService.RenderStepped:Connect(function()
		if frame.Visible and os.clock()-lastDistance>.2 then lastDistance=os.clock(); local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local cheetahPosition=getCheetahInteractionPosition(controller.Cheetah)
			if not root or not cheetahPosition then
				print("[MAYDEAD][CHEETAH][UI][CLIENT] AutoClose reason=InvalidCompanion")
				close()
			else
				local distance=(root.Position-cheetahPosition).Magnitude
				if distance>Config.COMPANION_UI_CLOSE_DISTANCE then
					print(string.format("[MAYDEAD][CHEETAH][UI][CLIENT] AutoClose reason=Distance distance=%.2f threshold=%.2f",distance,Config.COMPANION_UI_CLOSE_DISTANCE))
					close()
				end
			end
		end
		if not controller.Mounted or os.clock()-lastInput<.08 then return end; lastInput=os.clock(); local direction=Vector3.zero
		local inputBlocked = UserInputService:GetFocusedTextBox() ~= nil or GuiService.MenuIsOpen
		local forward = not inputBlocked and (UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up))
		local backward = not inputBlocked and (UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down))
		local left = not inputBlocked and (UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left))
		local right = not inputBlocked and (UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right))
		if forward then direction+=Vector3.new(0,0,-1) end; if backward then direction+=Vector3.new(0,0,1) end
		if left then direction+=Vector3.new(-1,0,0) end; if right then direction+=Vector3.new(1,0,0) end
		local camera=workspace.CurrentCamera; if camera and direction.Magnitude>0 then direction=camera.CFrame:VectorToWorldSpace(direction) end
		local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not inputBlocked and UserInputService.TouchEnabled and humanoid and humanoid.MoveDirection.Magnitude>0 then direction=humanoid.MoveDirection end
		if direction.Magnitude>1 then direction=direction.Unit end
		remote:FireServer("MountInput",{Direction=direction,Sprint=UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or controller.TouchSprint})
	end)
end

return controller
