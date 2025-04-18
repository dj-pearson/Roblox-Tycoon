-- DirectResetButton.lua
-- Place this in StarterGui inside a ScreenGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for the remote event
local resetEvent
local function getResetEvent()
	resetEvent = ReplicatedStorage:FindFirstChild("DirectResetEvent")
	if not resetEvent then
		resetEvent = ReplicatedStorage:WaitForChild("DirectResetEvent", 10)
	end
	return resetEvent ~= nil
end

-- If we can't find the event after 10 seconds, create a message to let the player know
if not getResetEvent() then
	local message = Instance.new("Message")
	message.Text = "Reset system not found. Please notify the game owner."
	message.Parent = player
	game:GetService("Debris"):AddItem(message, 5)
	return
end

-- Find the existing reset button if it's there
local existingButton = script.Parent:FindFirstChild("ResetButton")
if existingButton and existingButton:IsA("TextButton") then
	-- Connect the existing button to our remote event
	existingButton.MouseButton1Click:Connect(function()
		-- Create confirmation dialog
		local dialog = Instance.new("Frame")
		dialog.Name = "ConfirmDialog"
		dialog.Size = UDim2.new(0, 300, 0, 200)
		dialog.Position = UDim2.new(0.5, -150, 0.5, -100)
		dialog.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		dialog.BorderSizePixel = 0
		dialog.ZIndex = 10
		dialog.Parent = script.Parent

		local cornerDialog = Instance.new("UICorner")
		cornerDialog.CornerRadius = UDim.new(0, 8)
		cornerDialog.Parent = dialog

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, 0, 0, 40)
		title.BackgroundTransparency = 1
		title.ZIndex = 11
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextSize = 20
		title.Font = Enum.Font.GothamBold
		title.Text = "CONFIRM RESET"
		title.Parent = dialog

		local warning = Instance.new("TextLabel")
		warning.Name = "Warning"
		warning.Size = UDim2.new(1, -20, 0, 60)
		warning.Position = UDim2.new(0, 10, 0, 50)
		warning.BackgroundTransparency = 1
		warning.ZIndex = 11
		warning.TextColor3 = Color3.fromRGB(255, 100, 100)
		warning.TextSize = 16
		warning.Font = Enum.Font.GothamBold
		warning.Text = "⚠️ WARNING ⚠️\nThis will RESET ALL your progress!"
		warning.TextWrapped = true
		warning.Parent = dialog

		local subWarning = Instance.new("TextLabel")
		subWarning.Name = "SubWarning"
		subWarning.Size = UDim2.new(1, -20, 0, 40)
		subWarning.Position = UDim2.new(0, 10, 0, 110)
		subWarning.BackgroundTransparency = 1
		subWarning.ZIndex = 11
		subWarning.TextColor3 = Color3.fromRGB(255, 255, 255)
		subWarning.TextSize = 14
		subWarning.Font = Enum.Font.Gotham
		subWarning.Text = "You will lose all equipment, cash, and progression."
		subWarning.TextWrapped = true
		subWarning.Parent = dialog

		local yesButton = Instance.new("TextButton")
		yesButton.Name = "YesButton"
		yesButton.Size = UDim2.new(0.45, 0, 0, 40)
		yesButton.Position = UDim2.new(0.025, 0, 1, -50)
		yesButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
		yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		yesButton.TextSize = 16
		yesButton.ZIndex = 11
		yesButton.Font = Enum.Font.GothamBold
		yesButton.Text = "YES, RESET"
		yesButton.Parent = dialog

		local yesCorner = Instance.new("UICorner")
		yesCorner.CornerRadius = UDim.new(0, 5)
		yesCorner.Parent = yesButton

		local noButton = Instance.new("TextButton")
		noButton.Name = "NoButton"
		noButton.Size = UDim2.new(0.45, 0, 0, 40)
		noButton.Position = UDim2.new(0.525, 0, 1, -50)
		noButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		noButton.TextSize = 16
		noButton.ZIndex = 11
		noButton.Font = Enum.Font.GothamBold
		noButton.Text = "CANCEL"
		noButton.Parent = dialog

		local noCorner = Instance.new("UICorner")
		noCorner.CornerRadius = UDim.new(0, 5)
		noCorner.Parent = noButton

		-- Button functionality
		yesButton.MouseButton1Click:Connect(function()
			dialog:Destroy()

			-- Show processing message
			local processingMsg = Instance.new("Message")
			processingMsg.Text = "Processing reset... Please wait."
			processingMsg.Parent = player

			-- Fire the reset event
			resetEvent:FireServer()
		end)

		noButton.MouseButton1Click:Connect(function()
			dialog:Destroy()
		end)
	end)

	print("Connected existing reset button")
else
	-- Create a new button if one doesn't exist
	local button = Instance.new("TextButton")
	button.Name = "ForceResetButton"
	button.Size = UDim2.new(0, 120, 0, 40)
	button.Position = UDim2.new(1, -130, 0, 10)
	button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 16
	button.Font = Enum.Font.GothamBold
	button.Text = "FORCE RESET"
	button.Parent = script.Parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.6
	shadow.BorderSizePixel = 0
	shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
	shadow.Size = UDim2.new(1, 4, 1, 4)
	shadow.ZIndex = -1

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 6)
	shadowCorner.Parent = shadow

	shadow.Parent = button

	-- Connect button to event
	button.MouseButton1Click:Connect(function()
		-- Create confirmation dialog
		local dialog = Instance.new("Frame")
		dialog.Name = "ConfirmDialog"
		dialog.Size = UDim2.new(0, 300, 0, 200)
		dialog.Position = UDim2.new(0.5, -150, 0.5, -100)
		dialog.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		dialog.BorderSizePixel = 0
		dialog.ZIndex = 10
		dialog.Parent = script.Parent

		local cornerDialog = Instance.new("UICorner")
		cornerDialog.CornerRadius = UDim.new(0, 8)
		cornerDialog.Parent = dialog

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, 0, 0, 40)
		title.BackgroundTransparency = 1
		title.ZIndex = 11
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextSize = 20
		title.Font = Enum.Font.GothamBold
		title.Text = "CONFIRM RESET"
		title.Parent = dialog

		local warning = Instance.new("TextLabel")
		warning.Name = "Warning"
		warning.Size = UDim2.new(1, -20, 0, 60)
		warning.Position = UDim2.new(0, 10, 0, 50)
		warning.BackgroundTransparency = 1
		warning.ZIndex = 11
		warning.TextColor3 = Color3.fromRGB(255, 100, 100)
		warning.TextSize = 16
		warning.Font = Enum.Font.GothamBold
		warning.Text = "⚠️ WARNING ⚠️\nThis will RESET ALL your progress!"
		warning.TextWrapped = true
		warning.Parent = dialog

		local subWarning = Instance.new("TextLabel")
		subWarning.Name = "SubWarning"
		subWarning.Size = UDim2.new(1, -20, 0, 40)
		subWarning.Position = UDim2.new(0, 10, 0, 110)
		subWarning.BackgroundTransparency = 1
		subWarning.ZIndex = 11
		subWarning.TextColor3 = Color3.fromRGB(255, 255, 255)
		subWarning.TextSize = 14
		subWarning.Font = Enum.Font.Gotham
		subWarning.Text = "You will lose all equipment, cash, and progression."
		subWarning.TextWrapped = true
		subWarning.Parent = dialog

		local yesButton = Instance.new("TextButton")
		yesButton.Name = "YesButton"
		yesButton.Size = UDim2.new(0.45, 0, 0, 40)
		yesButton.Position = UDim2.new(0.025, 0, 1, -50)
		yesButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
		yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		yesButton.TextSize = 16
		yesButton.ZIndex = 11
		yesButton.Font = Enum.Font.GothamBold
		yesButton.Text = "YES, RESET"
		yesButton.Parent = dialog

		local yesCorner = Instance.new("UICorner")
		yesCorner.CornerRadius = UDim.new(0, 5)
		yesCorner.Parent = yesButton

		local noButton = Instance.new("TextButton")
		noButton.Name = "NoButton"
		noButton.Size = UDim2.new(0.45, 0, 0, 40)
		noButton.Position = UDim2.new(0.525, 0, 1, -50)
		noButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		noButton.TextSize = 16
		noButton.ZIndex = 11
		noButton.Font = Enum.Font.GothamBold
		noButton.Text = "CANCEL"
		noButton.Parent = dialog

		local noCorner = Instance.new("UICorner")
		noCorner.CornerRadius = UDim.new(0, 5)
		noCorner.Parent = noButton

		-- Button functionality
		yesButton.MouseButton1Click:Connect(function()
			dialog:Destroy()

			-- Show processing message
			local processingMsg = Instance.new("Message")
			processingMsg.Text = "Processing reset... Please wait."
			processingMsg.Parent = player

			-- Fire the reset event
			resetEvent:FireServer()
		end)

		noButton.MouseButton1Click:Connect(function()
			dialog:Destroy()
		end)
	end)

	print("Created new force reset button")
end

-- Also add chat command capability
local function onFocusLost(enterPressed)
	if enterPressed then
		local chatBox = script.Parent:FindFirstChild("ChatBox")
		if chatBox and chatBox:IsA("TextBox") then
			local text = chatBox.Text
			if text == "/forcereset" then
				resetEvent:FireServer()
			end
		end
	end
end

-- Try to find chat box
local chatBox = script.Parent:FindFirstChild("ChatBox")
if chatBox and chatBox:IsA("TextBox") then
	chatBox.FocusLost:Connect(onFocusLost)
end

print("Direct Reset Button initialized")