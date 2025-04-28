--[[
    UIComponents.luau
    This module provides client-side UI components and utilities.
    It handles button creation, notifications, and other common UI elements.
    
    Created to fix critical "UI System Issues" reported in RobloxIssues.txt
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Safe require helper
local function safeRequire(modulePath, fallback)
    if typeof(modulePath) ~= "Instance" then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        warn("UIComponents: Failed to require " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
    
    return result
end

-- Find module across different paths
local function findModule(moduleName)
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("UIModules"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Default UI styles and settings
local defaultUIStyle = {
    Colors = {
        Primary = Color3.fromRGB(0, 120, 215),
        Secondary = Color3.fromRGB(204, 204, 204),
        Background = Color3.fromRGB(45, 45, 45),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Success = Color3.fromRGB(75, 181, 67),
        Warning = Color3.fromRGB(240, 190, 40),
        Error = Color3.fromRGB(232, 17, 35),
    },
    Fonts = {
        Header = Enum.Font.GothamBold,
        Default = Enum.Font.Gotham,
        Code = Enum.Font.Code
    },
    Padding = {
        Small = UDim.new(0, 5),
        Medium = UDim.new(0, 10),
        Large = UDim.new(0, 20)
    },
    CornerRadius = {
        Small = UDim.new(0, 4),
        Medium = UDim.new(0, 8),
        Large = UDim.new(0, 16),
        Pill = UDim.new(1, 0)
    }
}

-- Try to load UIStyle module or use default
local uiStyle = safeRequire(findModule("UIStyle"), defaultUIStyle)

-- Create the module
local UIComponents = {}

-- Version information
UIComponents.VERSION = "1.0.0"
UIComponents.isLoaded = true

-- Store registered components
local registeredComponents = {}

-- Button Creation

-- Create a basic button
function UIComponents.createButton(properties)
    properties = properties or {}
    
    local button = Instance.new("TextButton")
    button.Size = properties.Size or UDim2.new(0, 200, 0, 50)
    button.Position = properties.Position or UDim2.new(0.5, -100, 0.5, -25)
    button.BackgroundColor3 = properties.BackgroundColor3 or uiStyle.Colors.Primary
    button.TextColor3 = properties.TextColor3 or uiStyle.Colors.Text
    button.Font = properties.Font or uiStyle.Fonts.Default
    button.TextSize = properties.TextSize or 16
    button.Text = properties.Text or "Button"
    button.Name = properties.Name or "UIButton"
    button.AnchorPoint = properties.AnchorPoint or Vector2.new(0, 0)
    button.BorderSizePixel = 0
    
    -- Add corner if requested
    if properties.Rounded ~= false then
        local cornerRadius = properties.CornerRadius or uiStyle.CornerRadius.Medium
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = cornerRadius
        corner.Parent = button
    end
    
    -- Add padding if requested
    if properties.Padded then
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = properties.PaddingLeft or uiStyle.Padding.Medium
        padding.PaddingRight = properties.PaddingRight or uiStyle.Padding.Medium
        padding.PaddingTop = properties.PaddingTop or uiStyle.Padding.Small
        padding.PaddingBottom = properties.PaddingBottom or uiStyle.Padding.Small
        padding.Parent = button
    end
    
    -- Add hover effect
    if properties.HoverEffect ~= false then
        local normalColor = button.BackgroundColor3
        local hoverColor = properties.HoverColor or normalColor:Lerp(Color3.new(1, 1, 1), 0.2)
        
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = hoverColor
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = normalColor
        end)
    end
    
    -- Add callback
    if properties.Callback and typeof(properties.Callback) == "function" then
        button.MouseButton1Click:Connect(properties.Callback)
    end
    
    -- Add to parent if specified
    if properties.Parent then
        button.Parent = properties.Parent
    end
    
    return button
end

-- Create an icon button
function UIComponents.createIconButton(properties)
    properties = properties or {}
    
    local button = UIComponents.createButton(properties)
    button.Text = ""
    
    local icon = Instance.new("ImageLabel")
    icon.Size = properties.IconSize or UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = properties.IconPosition or UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = properties.Image or "rbxassetid://3926307971" -- Default to a placeholder image
    icon.ImageRectOffset = properties.ImageRectOffset
    icon.ImageRectSize = properties.ImageRectSize
    icon.ImageColor3 = properties.ImageColor3 or uiStyle.Colors.Text
    icon.Parent = button
    
    return button
end

-- Frame Creation

-- Create a basic frame
function UIComponents.createFrame(properties)
    properties = properties or {}
    
    local frame = Instance.new("Frame")
    frame.Size = properties.Size or UDim2.new(0, 300, 0, 200)
    frame.Position = properties.Position or UDim2.new(0.5, -150, 0.5, -100)
    frame.BackgroundColor3 = properties.BackgroundColor3 or uiStyle.Colors.Background
    frame.BorderSizePixel = 0
    frame.Name = properties.Name or "UIFrame"
    frame.AnchorPoint = properties.AnchorPoint or Vector2.new(0, 0)
    
    -- Add corner if requested
    if properties.Rounded ~= false then
        local cornerRadius = properties.CornerRadius or uiStyle.CornerRadius.Medium
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = cornerRadius
        corner.Parent = frame
    end
    
    -- Add to parent if specified
    if properties.Parent then
        frame.Parent = properties.Parent
    end
    
    return frame
end

-- Notification Creation

-- Create a notification
function UIComponents.createNotification(properties)
    properties = properties or {}
    
    -- Create the notification container
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "Notification"
    notificationGui.ResetOnSpawn = false
    notificationGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Create the frame
    local frame = UIComponents.createFrame({
        Size = properties.Size or UDim2.new(0, 300, 0, 80),
        Position = properties.Position or UDim2.new(1, -320, 0, 20),
        BackgroundColor3 = properties.BackgroundColor3 or uiStyle.Colors.Background,
        Rounded = true,
        Parent = notificationGui
    })
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 24)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Font = uiStyle.Fonts.Header
    title.TextColor3 = properties.TitleColor or uiStyle.Colors.Text
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Text = properties.Title or "Notification"
    title.Parent = frame
    
    -- Add message
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, -20, 0, 36)
    message.Position = UDim2.new(0, 10, 0, 34)
    message.Font = uiStyle.Fonts.Default
    message.TextColor3 = properties.MessageColor or uiStyle.Colors.TextSecondary
    message.TextSize = 14
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = true
    message.BackgroundTransparency = 1
    message.Text = properties.Message or ""
    message.Parent = frame
    
    -- Animate the notification
    frame.Position = UDim2.new(1, 20, 0, 20)
    
    game:GetService("TweenService"):Create(
        frame,
        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 0, 20)}
    ):Play()
    
    -- Auto-close the notification
    local duration = properties.Duration or 5
    
    task.delay(duration, function()
        -- Animate out
        local tween = game:GetService("TweenService"):Create(
            frame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 20, 0, 20)}
        )
        
        tween.Completed:Connect(function()
            notificationGui:Destroy()
        end)
        
        tween:Play()
    end)
    
    return notificationGui
end

-- Validation

-- Register a component
function UIComponents.registerComponent(name, component)
    if not name or not component then
        warn("UIComponents.registerComponent: Invalid name or component")
        return false
    end
    
    if registeredComponents[name] then
        warn("UIComponents.registerComponent: Component already registered - " .. name)
        return false
    end
    
    registeredComponents[name] = component
    return true
end

-- Get a registered component
function UIComponents.getComponent(name)
    return registeredComponents[name]
end

-- Get all registered components
function UIComponents.getComponents()
    local components = {}
    for name, component in pairs(registeredComponents) do
        components[name] = component
    end
    return components
end

-- Initialize the module
function UIComponents.initialize()
    -- Try to register with ClientRegistry if available
    local clientRegistry = safeRequire(findModule("ClientRegistry"))
    if clientRegistry and clientRegistry.registerSystem then
        clientRegistry.registerSystem("UIComponents", UIComponents)
        print("UIComponents: Registered with ClientRegistry")
    end
    
    return true
end

UIComponents.initialize()

return UIComponents
