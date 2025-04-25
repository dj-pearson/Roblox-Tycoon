--[[
    RebirthMenuUI.client.luau
    Handles the creation and functionality of the Rebirth Menu UI.

    Updated: Today
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local GameSystem = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("GameSystem"))
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CloseButtonFactory = require(script.Parent:WaitForChild("CloseButtonFactory"))

-- Import modern UI framework components
local UIStyle = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UIStyle"))
local ButtonFactory = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("ButtonFactory"))
local TooltipFactory = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("TooltipFactory"))
local RebirthSystem = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("RebirthSystem"))

local function updateRebirthButtonState(rebirthButton)
	local rebirthCost = 1000
	local playerCash = GameSystem.getPlayerCash(LocalPlayer)
	local tooltip = rebirthButton:FindFirstChildOfClass("Tooltip")
	
	if playerCash < rebirthCost then
		rebirthButton.Disabled = true
		if not tooltip then
			local tooltipData = {
				text = "Not enough cash to rebirth!",
				target = rebirthButton,
			}
			TooltipFactory.createTooltip(tooltipData)
		end
	else
		rebirthButton.Disabled = false
		if tooltip then
			tooltip:Destroy()
		end
	end
end
local function createRebirthMenuUI()
	local function rebirth()
		RebirthSystem.performRebirth()
	end
	-- Create the main container for the rebirth menu
	local rebirthFrame = UIStyle.createFrame({
		name = "RebirthFrame",
		size = UDim2.new(0, 300, 0, 200),
		position = UDim2.new(0.5, -150, 0.5, -100),
		zIndex = UIStyle.ZIndex.Standard,
	})

	--Create the rebirth cost label
	local rebirthCostLabel = Instance.new("TextLabel")
	rebirthCostLabel.Name = "RebirthCostLabel"
	rebirthCostLabel.Text = "Rebirth Cost: 1000"
	rebirthCostLabel.Size = UDim2.new(1, -20, 0, 30)
	rebirthCostLabel.Position = UDim2.new(0, 10, 0, 20)
	rebirthCostLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthCostLabel.TextSize = 18
	rebirthCostLabel.Font = Enum.Font.GothamBold
	rebirthCostLabel.BackgroundTransparency = 1
	rebirthCostLabel.Parent = rebirthFrame

	--Create the rebirth button
	local rebirthButton = ButtonFactory.createButton({		name = "RebirthButton",
		text = "Rebirth",
		size = UDim2.new(1, -20, 0, 50),
		position = UDim2.new(0, 10, 0, 100),
	})
	rebirthButton.Parent = rebirthFrame
	rebirthButton.MouseButton1Click:Connect(rebirth)
	
	updateRebirthButtonState(rebirthButton)
	
	return rebirthFrame
end

local function loadUI()
	-- Create the RebirthUI ScreenGui if it doesn't exist
	local screenGui = PlayerGui:FindFirstChild("RebirthUI")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "RebirthUI"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui
	end

	-- Create the RebirthFrame container
	local rebirthFrame = createRebirthMenuUI()
	rebirthFrame.Parent = screenGui

	--Create the close button
	CloseButtonFactory({
		size = UDim2.new(0, 30, 0, 30),
		position = UDim2.new(1, -40, 0, 10),
		target = rebirthFrame,
	})
		--Update the UI on cash change
	local player = Players.LocalPlayer
	local cash = player:WaitForChild("Cash")
	cash.Changed:Connect(function()
		updateRebirthButtonState(rebirthFrame:WaitForChild("RebirthButton"))
	end)
end

return {
	loadUI = loadUI,
}