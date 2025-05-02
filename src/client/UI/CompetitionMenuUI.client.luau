luau
--!strict
--[[
    CompetitionMenuUI.client.luau

    Client-side script for the main Competition menu UI.
    Provides a basic structure and a function to toggle its visibility.

    Created: May 27, 2024
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CompetitionMenuUI = {}

local menuFrame = nil
local isVisible = false

-- Create the basic UI frame
local function createMenuUI()
    menuFrame = Instance.new("Frame")
    menuFrame.Name = "CompetitionMenuFrame"
    menuFrame.Size = UDim2.new(0.5, 0, 0.7, 0) -- Centered size
    menuFrame.Position = UDim2.new(0.5, -menuFrame.Size.X.Offset / 2, 0.5, -menuFrame.Size.Y.Offset / 2)
    menuFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- Center anchor
    menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    menuFrame.BorderSizePixel = 0
    menuFrame.Active = true -- Allow dragging if needed
    menuFrame.Draggable = true -- Make it draggable
    menuFrame.Visible = false -- Start hidden

    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = menuFrame

    -- Add title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = menuFrame

    -- Add title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -50, 1, 0) -- Make space for close button
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Competitions"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    titleLabel.Parent = titleBar

    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 5)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕" -- X character
    closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeButton.TextSize = 20
    closeButton.Parent = titleBar

    -- Close button click connection
    closeButton.MouseButton1Click:Connect(function()
        CompetitionMenuUI:ToggleVisibility()
    end)

    -- Add a placeholder for competition details
    local detailsLabel = Instance.new("TextLabel")
    detailsLabel.Name = "CompetitionDetailsPlaceholder"
    detailsLabel.Size = UDim2.new(1, -20, 1, -50) -- Takes up most of the frame below title bar
    detailsLabel.Position = UDim2.new(0, 10, 0, 45)
    detailsLabel.BackgroundTransparency = 1
    detailsLabel.Text = "Competition details will be displayed here."
    detailsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    detailsLabel.TextSize = 16
    detailsLabel.TextWrapped = true
    detailsLabel.TextXAlignment = Enum.TextXAlignment.Center
    detailsLabel.TextYAlignment = Enum.TextYAlignment.Top
    detailsLabel.Parent = menuFrame

    menuFrame.Parent = PlayerGui
end

-- Function to toggle the visibility of the menu
function CompetitionMenuUI:ToggleVisibility()
    if not menuFrame then
        createMenuUI()
    end

    isVisible = not isVisible
    menuFrame.Visible = isVisible
end

-- Ensure UI is created when the script starts if not already present
if not PlayerGui:FindFirstChild("CompetitionMenuFrame") then
    createMenuUI()
end


return CompetitionMenuUI