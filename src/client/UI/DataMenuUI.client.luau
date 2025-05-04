--luau
--!strict
--[[
    DataMenuUI.client.luau

    A client-side script for the main Data Management menu.
    This script handles the creation and visibility toggling of the UI.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DataMenuUI = {}

local menuFrame: Frame? = nil
local isVisible = false

-- Creates the main data menu UI frame
local function createMenu()
    if menuFrame then
        return
    end

    menuFrame = Instance.new("Frame")
    menuFrame.Name = "DataManagementMenuFrame"
    menuFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
    menuFrame.Position = UDim2.new(0.5, -menuFrame.Size.X.Offset / 2, 0.5, -menuFrame.Size.Y.Offset / 2)
    menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    menuFrame.BorderSizePixel = 0

    -- Add a UICorner for rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = menuFrame

    -- Add a title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = menuFrame

    -- Add the title text label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -50, 1, 0) -- Make space for close button
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Data Management"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 20
    titleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Add a close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeButton.TextSize = 20
    closeButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    closeButton.Parent = titleBar

    -- Connect the close button
    closeButton.MouseButton1Click:Connect(function()
        DataMenuUI.ToggleVisibility()
    end)

    -- Add a placeholder for data content
    local dataContentFrame = Instance.new("Frame")
    dataContentFrame.Name = "DataContentFrame"
    dataContentFrame.Size = UDim2.new(1, -40, 1, -50) -- Allow padding and space for title bar
    dataContentFrame.Position = UDim2.new(0, 20, 0, 45) -- Position below title bar
    dataContentFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60) -- Slightly different background
    dataContentFrame.BorderSizePixel = 0
    dataContentFrame.Parent = menuFrame

    -- Add a placeholder text label inside the content frame
    local placeholderLabel = Instance.new("TextLabel")
    placeholderLabel.Name = "PlaceholderLabel"
    placeholderLabel.Size = UDim2.new(1, 0, 1, 0)
    placeholderLabel.BackgroundTransparency = 1
    placeholderLabel.Text = "Data management options and display will go here."
    placeholderLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    placeholderLabel.TextSize = 16
    placeholderLabel.TextWrapped = true
    placeholderLabel.TextXAlignment = Enum.TextXAlignment.Center
    placeholderLabel.TextYAlignment = Enum.TextYAlignment.Center
    placeholderLabel.Parent = dataContentFrame
end

-- Toggles the visibility of the data menu
function DataMenuUI.ToggleVisibility()
    if not menuFrame then
        createMenu()
    end

    if menuFrame then
        isVisible = not isVisible
        menuFrame.Visible = isVisible

        -- Parent the frame to PlayerGui when visible
        if isVisible and menuFrame.Parent ~= PlayerGui then
            menuFrame.Parent = PlayerGui
        elseif not isVisible and menuFrame.Parent == PlayerGui then
            -- Optionally parent to nil or another container when hidden
            -- For simplicity, we'll just hide it here.
        end
    end
end

-- Ensure the menu is initially hidden
if menuFrame then
    menuFrame.Visible = false
end

return DataMenuUI