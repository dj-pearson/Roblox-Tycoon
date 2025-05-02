--luau
--!strict
-- StatsMenuUI.client.luau
-- Script to manage the main Player Stats menu UI.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIStyle = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UIStyle")) -- Assuming UIStyle is accessible here

local StatsMenuUI = {}

local menuFrame: Frame? = nil

-- Function to create the initial menu frame
local function createMenuFrame()
	local frame = UIStyle.createFrame({ -- Using UIStyle for consistency
		name = "StatsMenuFrame",
		size = UDim2.new(0.6, 0, 0.7, 0), -- Example size, adjust as needed
		position = UDim2.new(0.5, -UDim.new(0.6, 0).X.Scale * game.Workspace.CurrentCamera.ViewportSize.X / 2, 0.5, -UDim.new(0.7, 0).Y.Scale * game.Workspace.CurrentCamera.ViewportSize.Y / 2), -- Center the frame
		anchorPoint = Vector2.new(0.5, 0.5),
		backgroundColor = UIStyle.colors.background, -- Example background color
		cornerRadius = UIStyle.cornerRadius.medium, -- Example corner radius
		zIndex = UIStyle.ZIndex.Modal -- Example zIndex
	})

	-- Add a title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40) -- Example size
	titleBar.BackgroundColor3 = UIStyle.colors.accent -- Example accent color
	titleBar.BorderSizePixel = 0
	titleBar.Parent = frame

	-- Add title text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -80, 1, 0) -- Leave space for close button
	titleLabel.Position = UDim2.new(0, 40, 0, 0) -- Center text
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Player Stats"
	titleLabel.TextColor3 = UIStyle.colors.text -- Example text color
	titleLabel.TextSize = 20
	titleLabel.Font = UIStyle.fonts.header -- Example font
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Parent = titleBar

	-- Add a close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30) -- Example size
	closeButton.Position = UDim2.new(1, -35, 0.5, -15) -- Position in top right
	closeButton.AnchorPoint = Vector2.new(1, 0.5)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "X"
	closeButton.TextColor3 = UIStyle.colors.text -- Example text color
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.GothamBold -- Example font
	closeButton.Parent = titleBar

	-- Connect close button
	closeButton.MouseButton1Click:Connect(function()
		StatsMenuUI:ToggleVisibility(false)
	end)

	-- Add a scrolling frame for stats content
	local statsScrollingFrame = Instance.new("ScrollingFrame")
	statsScrollingFrame.Name = "StatsScrollingFrame"
	statsScrollingFrame.Size = UDim2.new(1, 0, 1, -40) -- Fill the frame below the title bar
	statsScrollingFrame.Position = UDim2.new(0, 0, 0, 40)
	statsScrollingFrame.CanvasSize = UDim2.new(0, 0, 2, 0) -- Example canvas size, adjust as needed
	statsScrollingFrame.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
	statsScrollingFrame.BackgroundTransparency = 1
	statsScrollingFrame.ScrollBarThickness = 6
	statsScrollingFrame.Parent = frame

	-- Add placeholder sections
	local currentY = 0
	local sectionHeight = 80 -- Example height per section

	local basicStatsSection = Instance.new("TextLabel")
	basicStatsSection.Name = "BasicStatsSection"
	basicStatsSection.Size = UDim2.new(1, 0, 0, sectionHeight)
	basicStatsSection.Position = UDim2.new(0, 0, 0, currentY)
	basicStatsSection.BackgroundTransparency = 1
	basicStatsSection.Text = "Basic Stats (Placeholder)"
	basicStatsSection.TextColor3 = UIStyle.colors.text
	basicStatsSection.TextSize = 18
	basicStatsSection.Font = UIStyle.fonts.body
	basicStatsSection.TextWrapped = true
	basicStatsSection.TextXAlignment = Enum.TextXAlignment.Left
	basicStatsSection.TextYAlignment = Enum.TextYAlignment.Top
	basicStatsSection.Parent = statsScrollingFrame
	currentY = currentY + sectionHeight

	local combatStatsSection = Instance.new("TextLabel")
	combatStatsSection.Name = "CombatStatsSection"
	combatStatsSection.Size = UDim2.new(1, 0, 0, sectionHeight)
	combatStatsSection.Position = UDim2.new(0, 0, 0, currentY)
	combatStatsSection.BackgroundTransparency = 1
	combatStatsSection.Text = "Combat Stats (Placeholder)"
	combatStatsSection.TextColor3 = UIStyle.colors.text
	combatStatsSection.TextSize = 18
	combatStatsSection.Font = UIStyle.fonts.body
	combatStatsSection.TextWrapped = true
	combatStatsSection.TextXAlignment = Enum.TextXAlignment.Left
	combatStatsSection.TextYAlignment = Enum.TextYAlignment.Top
	combatStatsSection.Parent = statsScrollingFrame
	currentY = currentY + sectionHeight

	local economicStatsSection = Instance.new("TextLabel")
	economicStatsSection.Name = "EconomicStatsSection"
	economicStatsSection.Size = UDim2.new(1, 0, 0, sectionHeight)
	economicStatsSection.Position = UDim2.new(0, 0, 0, currentY)
	economicStatsSection.BackgroundTransparency = 1
	economicStatsSection.Text = "Economic Stats (Placeholder)"
	economicStatsSection.TextColor3 = UIStyle.colors.text
	economicStatsSection.TextSize = 18
	economicStatsSection.Font = UIStyle.fonts.body
	economicStatsSection.TextWrapped = true
	economicStatsSection.TextXAlignment = Enum.TextXAlignment.Left
	economicStatsSection.TextYAlignment = Enum.TextYAlignment.Top
	economicStatsSection.Parent = statsScrollingFrame
	currentY = currentY + sectionHeight


	-- Update canvas size after adding elements
	statsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, currentY)


	return frame
end

-- Function to toggle the visibility of the stats menu
function StatsMenuUI:ToggleVisibility(visible: boolean?)
	if not menuFrame then
		menuFrame = createMenuFrame()
		menuFrame.Parent = PlayerGui -- Attach to PlayerGui
	end

	-- Toggle visibility if 'visible' argument is not provided
	local newVisibility = visible
	if newVisibility == nil then
		newVisibility = not menuFrame.Visible
	end

	menuFrame.Visible = newVisibility
end

return StatsMenuUI