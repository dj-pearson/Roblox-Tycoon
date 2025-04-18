-- ResetButton.lua
-- Place in StarterGui inside a ScreenGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Create the GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ResetDataGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- Create the button
local button = Instance.new("TextButton")
button.Name = "ResetButton"
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(1, -220, 0, 20) -- Top right corner
button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.Text = "RESET DATA"
button.Parent = screenGui

-- Add rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

-- Look for existing event or create it
local resetEvent = ReplicatedStorage:FindFirstChild("SimpleResetEvent")
if not resetEvent then
	-- Only try to create if it doesn't exist
	-- This avoids the error but the event might need to be created on the server
	print("SimpleResetEvent not found - server script should create this")
end

-- Connect button to event
button.MouseButton1Click:Connect(function()
	-- Create confirmation dialog
	local dialog = Instance.new("Frame")
	dialog.Name = "ConfirmDialog"
	dialog.Size = UDim2.new(0, 300, 0, 150)
	dialog.Position = UDim2.new(0.5, -150, 0.5, -75)
	dialog.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	dialog.BorderSizePixel = 0
	dialog.Parent = screenGui

	local cornerDialog = Instance.new("UICorner")
	cornerDialog.CornerRadius = UDim.new(0, 8)
	cornerDialog.Parent = dialog

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Text = "CONFIRM DATA RESET"
	title.Parent = dialog

	local warning = Instance.new("TextLabel")
	warning.Name = "Warning"
	warning.Size = UDim2.new(1, -20, 0, 40)
	warning.Position = UDim2.new(0, 10, 0, 40)
	warning.BackgroundTransparency = 1
	warning.TextColor3 = Color3.fromRGB(255, 100, 100)
	warning.TextSize = 14
	warning.Font = Enum.Font.Gotham
	warning.Text = "This will reset ALL your progress! This cannot be undone!"
	warning.TextWrapped = true
	warning.Parent = dialog

	local yesButton = Instance.new("TextButton")
	yesButton.Name = "YesButton"
	yesButton.Size = UDim2.new(0.45, 0, 0, 40)
	yesButton.Position = UDim2.new(0.025, 0, 1, -50)
	yesButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
	yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	yesButton.TextSize = 16
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
	noButton.Font = Enum.Font.GothamBold
	noButton.Text = "CANCEL"
	noButton.Parent = dialog

	local noCorner = Instance.new("UICorner")
	noCorner.CornerRadius = UDim.new(0, 5)
	noCorner.Parent = noButton

	-- Button functionality
	yesButton.MouseButton1Click:Connect(function()
		dialog:Destroy()
		if resetEvent then
			resetEvent:FireServer()
		else
			print("SimpleResetEvent not found!")
		end
	end)

	noButton.MouseButton1Click:Connect(function()
		dialog:Destroy()
	end)
end)