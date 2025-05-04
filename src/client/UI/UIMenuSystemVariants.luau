-- UIMenuSystemVariants.luau
-- Examples of different styling variants for the UIMenuSystem
-- Created: May 3, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Import the UIMenuSystem
local UIMenuSystem = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("UI"):WaitForChild("UIMenuSystem"))

-- Get UIStyle for reference
local UIStyle = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UIStyle"))

-- Collection of different style variants
local UIMenuVariants = {}

-- Circular buttons variant
UIMenuVariants.CircularStyle = function()
    -- Create a deep copy of the original CONFIG
    local config = table.clone(UIMenuSystem.CONFIG)
    
    -- Modify the configuration for circular buttons
    config.buttonSize = UDim2.new(0, 60, 0, 60)
    config.buttonCornerRadius = UDim.new(1, 0)  -- Makes it fully circular
    config.iconSize = UDim2.new(0.7, 0, 0.7, 0)
    config.defaultBackgroundColor = UIStyle.colors.background
    config.hoverBackgroundColor = UIStyle.colors.accent
    config.activeBackgroundColor = UIStyle.colors.accentLight
    
    -- Set the new configuration
    for key, value in pairs(config) do
        UIMenuSystem.CONFIG[key] = value
    end
    
    -- Return the create function for chaining
    return UIMenuSystem.CreateMenuUI
end

-- Horizontal bottom menu variant
UIMenuVariants.HorizontalBottomStyle = function()
    -- First modify the createMenuUI function to place at bottom
    local originalCreateMenuUI = UIMenuSystem.CreateMenuUI
    
    -- Override the create function
    UIMenuSystem.CreateMenuUI = function()
        -- Call the original to create the base UI
        local screenGui = originalCreateMenuUI()
        
        -- Find and modify the menu container
        local menuContainer = screenGui:FindFirstChild("MenuContainer")
        if menuContainer then
            -- Change orientation to horizontal
            menuContainer.Size = UDim2.new(1, 0, 0, 70)
            menuContainer.Position = UDim2.new(0, 0, 1, -70)
            
            -- Reposition all buttons
            local buttons = menuContainer:GetChildren()
            local spacing = 80  -- Horizontal spacing between buttons
            local startX = 20   -- Starting X position
            
            for i, button in ipairs(buttons) do
                if button:IsA("ImageButton") then
                    button.Position = UDim2.new(0, startX + (i-1) * spacing, 0, 10)
                end
            end
        end
        
        return screenGui
    end
    
    -- Return the modified create function
    return UIMenuSystem.CreateMenuUI
end

-- Minimal side menu variant (just icons, expanded tooltips)
UIMenuVariants.MinimalSideStyle = function()
    -- Create a deep copy of the original CONFIG
    local config = table.clone(UIMenuSystem.CONFIG)
    
    -- Modify the configuration for minimal buttons
    config.buttonSize = UDim2.new(0, 40, 0, 40)
    config.buttonCornerRadius = UDim.new(0, 4)
    config.iconSize = UDim2.new(0.8, 0, 0.8, 0)
    config.defaultBackgroundColor = Color3.fromRGB(30, 30, 40)
    config.tooltipBackgroundColor = UIStyle.colors.accent
    
    -- Set the new configuration
    for key, value in pairs(config) do
        UIMenuSystem.CONFIG[key] = value
    end
    
    -- Override the createMenuUI function
    local originalCreateMenuUI = UIMenuSystem.CreateMenuUI
    UIMenuSystem.CreateMenuUI = function()
        -- Call the original to create the base UI
        local screenGui = originalCreateMenuUI()
        
        -- Find and modify the menu container
        local menuContainer = screenGui:FindFirstChild("MenuContainer")
        if menuContainer then
            -- Make it smaller
            menuContainer.Size = UDim2.new(0, 50, 1, 0)
            
            -- Add a subtle gradient
            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 40)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
            })
            gradient.Rotation = 90
            gradient.Parent = menuContainer
        end
        
        return screenGui
    end
    
    -- Return the modified create function
    return UIMenuSystem.CreateMenuUI
end

-- Example to demonstrate how to use a variant:
-- UIMenuVariants.CircularStyle()()  -- Note the double parentheses: first to get the function, second to call it

return UIMenuVariants
