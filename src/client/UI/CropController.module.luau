local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local controller = {Started = false}

function controller:Start()
	if self.Started then
		return
	end
	self.Started = true
	ReplicatedStorage:WaitForChild("CropFeedback").OnClientEvent:Connect(function(message)
		pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = "POTAGER",
				Text = tostring(message),
				Duration = 2,
			})
		end)
	end)
end

return controller
