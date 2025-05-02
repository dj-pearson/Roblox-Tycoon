--luau
--!strict
--[[
    GymMenuUI.client.luau

    Manages the UI for the main Gym Management menu.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local TweenService = game:GetService("TweenService")

-- UI Elements
local mainFrame: Frame?
local isVisible = false

-- Create the main UI frame
local function createMenuUI()
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "GymMenuFrame"
    mainFrame.Size = UDim2.new(0.6, 0, 0.7, 0) -- Adjust size as needed
    mainFrame.Position = UDim2.new(0.5, -mainFrame.Size.X.Offset / 2, 0.5, -mainFrame.Size.Y.Offset / 2)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50) -- Dark gray background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true

    -- Add UICorner for rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    -- Add a title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70) -- Slightly lighter gray
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    -- Add the title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -50, 1, 0) -- Leave space for close button
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Gym Management"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamBold -- Use a bold font from UIStyle if available
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Add a close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90) -- Darker button color
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar

    local closeButtonCorner = Instance.new("UICorner")
    closeButtonCorner.CornerRadius = UDim.new(0, 5)
    closeButtonCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        ToggleVisibility()
    end)

    -- Placeholder area for content
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -titleBar.Size.Y.Offset)
    contentFrame.Position = UDim2.new(0, 0, 0, titleBar.Size.Y.Offset)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    -- Add a placeholder label
    local placeholderLabel = Instance.new("TextLabel")
    placeholderLabel.Name = "PlaceholderLabel"
    placeholderLabel.Size = UDim2.new(1, -20, 0, 30)
    placeholderLabel.Position = UDim2.new(0, 10, 0, 10)
    placeholderLabel.BackgroundTransparency = 1
    placeholderLabel.Text = "Gym management options will go here..."
    placeholderLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Light gray text
    placeholderLabel.TextSize = 16
    placeholderLabel.Font = Enum.Font.Gotham -- Use a standard font
    placeholderLabel.TextWrapped = true
    placeholderLabel.TextXAlignment = Enum.TextXAlignment.Left
    placeholderLabel.Parent = contentFrame

    -- Initially hide the frame
    mainFrame.Visible = false
end

-- Toggle the visibility of the menu
local function ToggleVisibility()
    if not mainFrame then
        createMenuUI()
    end

    isVisible = not isVisible
    mainFrame.Visible = isVisible

    -- Optional: Add a tween animation for opening/closing
    local targetPosition = UDim2.new(0.5, -mainFrame.Size.X.Offset / 2, 0.5, -mainFrame.Size.Y.Offset / 2)
    local hiddenPosition = UDim2.new(0.5, -mainFrame.Size.X.Offset / 2, 1.1, 0) -- Off-screen below

    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local targetGoal = { Position = isVisible and targetPosition or hiddenPosition }
    local tween = TweenService:Create(mainFrame, tweenInfo, targetGoal)
    tween:Play()

    if isVisible then
        -- Parent to PlayerGui when visible
        mainFrame.Parent = PlayerGui
    else
        -- Optional: Parent back to nil or a storage service when hidden
        -- mainFrame.Parent = nil -- Or a dedicated storage folder
    end
end

-- Return the public API
local GymMenuUI = {}
GymMenuUI.ToggleVisibility = ToggleVisibility

return GymMenuUI