-- UIMenuSystem.client.luau
-- Implements a manual ScreenGui with ImageButtons for UI elements
-- Created: May 3, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Import UI style and utilities
local path = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local UIStyle = require(path:WaitForChild("UIStyle"))
local UIUtils = require(path:WaitForChild("UIUtils"))
local UIRegistry = require(path:WaitForChild("UIRegistry"))

-- Menu element asset IDs from UIElements.md
local MENU_ELEMENTS = {
    {
        assetId = "128203268160479",
        name = "Alliance",
        tooltip = "Manage your alliances with other players",
        position = UDim2.new(0, 20, 0, 20),
        callback = function() print("Alliance button clicked") end
    },
    {
        assetId = "97149848004338",
        name = "CommunityGoals",
        tooltip = "View and contribute to community goals",
        position = UDim2.new(0, 20, 0, 90),
        callback = function() print("Community Goals button clicked") end
    },
    {
        assetId = "120333480860384",
        name = "Challenges",
        tooltip = "Daily and weekly challenges",
        position = UDim2.new(0, 20, 0, 160),
        callback = function() print("Challenges button clicked") end
    },
    {
        assetId = "110319251186892",
        name = "GuestPass",
        tooltip = "Manage guest passes for your tycoon",
        position = UDim2.new(0, 20, 0, 230),
        callback = function() print("Guest Pass button clicked") end
    },
    {
        assetId = "98150393120956",
        name = "Tutorial",
        tooltip = "Open the tutorial guide",
        position = UDim2.new(0, 20, 0, 300),
        callback = function() print("Tutorial button clicked") end
    },
    {
        assetId = "72876573893033",
        name = "Settings",
        tooltip = "Adjust game settings",
        position = UDim2.new(0, 20, 0, 370),
        callback = function() print("Settings button clicked") end
    },
    {
        assetId = "129409029383961",
        name = "Rebirth",
        tooltip = "Reset progress for bonuses",
        position = UDim2.new(0, 20, 0, 440),
        callback = function() print("Rebirth button clicked") end
    },
    {
        assetId = "89834599810886",
        name = "StaffManagement",
        tooltip = "Manage your staff members",
        position = UDim2.new(0, 20, 0, 510),
        callback = function() print("Staff Management button clicked") end
    },
    {
        assetId = "132635366103906",
        name = "Upgrades",
        tooltip = "Purchase upgrades for your tycoon",
        position = UDim2.new(0, 20, 0, 580),
        callback = function() print("Upgrades button clicked") end
    },
    {
        assetId = "79337595530955",
        name = "Achievements",
        tooltip = "View your achievements and progress",
        position = UDim2.new(0, 20, 0, 650),
        callback = function() print("Achievements button clicked") end
    }
}

-- Configuration for the UI
local CONFIG = {
    buttonSize = UDim2.new(0, 50, 0, 50),
    iconSize = UDim2.new(0.8, 0, 0.8, 0),
    buttonCornerRadius = UDim.new(0, 8),
    tooltipBackgroundColor = UIStyle.colors.backgroundDark,
    tooltipTextColor = UIStyle.colors.text,
    tooltipFont = UIStyle.fontSize.medium,
    tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    defaultBackgroundColor = UIStyle.colors.backgroundLight,
    hoverBackgroundColor = UIStyle.colors.accentDark,
    activeBackgroundColor = UIStyle.colors.accent
}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Function to create the main menu UI
local function createMenuUI()
    -- Create the main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MenuSystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Register the ScreenGui in UIRegistry for global access
    if UIRegistry then
        UIRegistry.RegisterInstance("MenuSystemGui", screenGui)
    end
    
    -- Create a container for the menu buttons
    local menuContainer = Instance.new("Frame")
    menuContainer.Name = "MenuContainer"
    menuContainer.Size = UDim2.new(0, 70, 1, 0)
    menuContainer.Position = UDim2.new(0, 0, 0, 0)
    menuContainer.BackgroundColor3 = UIStyle.colors.backgroundDark
    menuContainer.BorderSizePixel = 0
    menuContainer.Parent = screenGui
    
    -- Add UI corner to the menu container
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 0)
    corner.Parent = menuContainer
    
    -- Create buttons for each menu element
    for _, elementInfo in ipairs(MENU_ELEMENTS) do
        createMenuButton(menuContainer, elementInfo)
    end
    
    return screenGui
end

-- Function to create individual menu buttons
local function createMenuButton(parent, elementInfo)
    -- Create button container
    local button = Instance.new("ImageButton")
    button.Name = elementInfo.name .. "Button"
    button.Size = CONFIG.buttonSize
    button.Position = elementInfo.position
    button.BackgroundColor3 = CONFIG.defaultBackgroundColor
    button.Image = ""  -- We'll use the background for styling and add the icon as a child
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = parent
    
    -- Add corner radius to button
    local corner = Instance.new("UICorner")
    corner.CornerRadius = CONFIG.buttonCornerRadius
    corner.Parent = button
    
    -- Add icon image
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = CONFIG.iconSize
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://" .. elementInfo.assetId
    icon.Parent = button
    
    -- Create tooltip (initially invisible)
    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 200, 0, 40)
    tooltip.Position = UDim2.new(1, 10, 0, 0)
    tooltip.BackgroundColor3 = CONFIG.tooltipBackgroundColor
    tooltip.BorderSizePixel = 0
    tooltip.Visible = false
    tooltip.ZIndex = 10
    tooltip.Parent = button
    
    -- Add corner to tooltip
    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = CONFIG.buttonCornerRadius
    tooltipCorner.Parent = tooltip
    
    -- Add tooltip text
    local tooltipText = Instance.new("TextLabel")
    tooltipText.Name = "TooltipText"
    tooltipText.Size = UDim2.new(1, -20, 1, 0)
    tooltipText.Position = UDim2.new(0, 10, 0, 0)
    tooltipText.BackgroundTransparency = 1
    tooltipText.Text = elementInfo.tooltip
    tooltipText.TextColor3 = CONFIG.tooltipTextColor
    tooltipText.TextSize = CONFIG.tooltipFont
    tooltipText.Font = Enum.Font.Gotham
    tooltipText.TextXAlignment = Enum.TextXAlignment.Left
    tooltipText.TextYAlignment = Enum.TextYAlignment.Center
    tooltipText.ZIndex = 11
    tooltipText.Parent = tooltip
    
    -- Button hover effect
    button.MouseEnter:Connect(function()
        -- Show tooltip
        tooltip.Visible = true
        
        -- Animate button background
        local tween = TweenService:Create(
            button,
            CONFIG.tweenInfo,
            {BackgroundColor3 = CONFIG.hoverBackgroundColor}
        )
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        -- Hide tooltip
        tooltip.Visible = false
        
        -- Animate button background back to default
        local tween = TweenService:Create(
            button,
            CONFIG.tweenInfo,
            {BackgroundColor3 = CONFIG.defaultBackgroundColor}
        )
        tween:Play()
    end)
    
    -- Button click effect
    button.MouseButton1Down:Connect(function()
        -- Animate button press
        local tween = TweenService:Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundColor3 = CONFIG.activeBackgroundColor}
        )
        tween:Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        -- Animate button release
        local tween = TweenService:Create(
            button,
            CONFIG.tweenInfo,
            {BackgroundColor3 = CONFIG.hoverBackgroundColor}
        )
        tween:Play()
        
        -- Execute button callback
        if typeof(elementInfo.callback) == "function" then
            elementInfo.callback()
        end
    end)
    
    return button
end

-- Initialize the menu system
local function init()
    local menuGui = createMenuUI()
    
    -- Clean up when player leaves
    Players.PlayerRemoving:Connect(function(player)
        if player == LocalPlayer and menuGui then
            menuGui:Destroy()
        end
    end)
end

-- Start the initialization
init()

return {
    CreateMenuUI = createMenuUI,
    CONFIG = CONFIG
}
