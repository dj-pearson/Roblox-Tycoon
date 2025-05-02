--luau
--!strict
-- ShopMenuUI.client.luau
-- Script for the main Shop menu UI.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Placeholder for the main shop frame
local shopFrame = nil

-- Function to create the shop UI
local function createShopUI()
    if shopFrame then
        return shopFrame
    end

    shopFrame = Instance.new("Frame")
    shopFrame.Name = "ShopMenuFrame"
    shopFrame.Size = UDim2.new(0.6, 0, 0.8, 0) -- Example size: 60% of screen width, 80% of screen height
    shopFrame.Position = UDim2.new(0.5, -shopFrame.Size.X.Offset / 2, 0.5, -shopFrame.Size.Y.Offset / 2) -- Center the frame
    shopFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50) -- Dark background color
    shopFrame.BorderSizePixel = 0
    shopFrame.Active = true
    shopFrame.Draggable = true -- Make the frame draggable

    -- Add a UICorner for rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = shopFrame

    -- Add a title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = shopFrame

    -- Add the title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -50, 1, 0) -- Leave space for close button
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Shop"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 20
    titleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Add a close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 5) -- Position near the top right corner
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 20
    closeButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    closeButton.Parent = titleBar

    closeButton.MouseButton1Click:Connect(function()
        shopFrame.Visible = false
    end)

    -- Placeholder area for shop items
    local itemsContainer = Instance.new("Frame")
    itemsContainer.Name = "ItemsContainer"
    itemsContainer.Size = UDim2.new(1, 0, 1, -40) -- Below the title bar
    itemsContainer.Position = UDim2.new(0, 0, 0, 40)
    itemsContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 60) -- Slightly lighter background
    itemsContainer.BorderSizePixel = 0
    itemsContainer.Parent = shopFrame

    -- Add a UIListLayout to arrange items vertically (placeholder)
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Parent = itemsContainer

    -- Add a placeholder item for demonstration
    local placeholderItem = Instance.new("Frame")
    placeholderItem.Size = UDim2.new(0.9, 0, 0, 60)
    placeholderItem.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    placeholderItem.BorderSizePixel = 0
    placeholderItem.Parent = itemsContainer

    local placeholderLabel = Instance.new("TextLabel")
    placeholderLabel.Size = UDim2.new(1, 0, 1, 0)
    placeholderLabel.BackgroundTransparency = 1
    placeholderLabel.Text = "Shop Item Placeholder"
    placeholderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    placeholderLabel.TextSize = 16
    placeholderLabel.Parent = placeholderItem

    -- Initially hide the frame
    shopFrame.Visible = false

    return shopFrame
end

-- Function to toggle the visibility of the shop menu
local function ToggleVisibility()
    if not shopFrame then
        shopFrame = createShopUI()
        shopFrame.Parent = PlayerGui
    end
    shopFrame.Visible = not shopFrame.Visible
end

-- Return the public API
return {
    ToggleVisibility = ToggleVisibility,
}