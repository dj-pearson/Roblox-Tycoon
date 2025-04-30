--[[
    UIRegistry.luau
    
    Central registry for UI components and services.
    Provides UI factory methods and styling for consistent UI across the game.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UIRegistry = {}
UIRegistry.initialized = false

-- Configuration
local UIConfig = {
    COLORS = {
        PRIMARY = Color3.fromRGB(0, 120, 215),     -- Blue
        SECONDARY = Color3.fromRGB(50, 50, 50),    -- Dark Gray
        ACCENT = Color3.fromRGB(255, 185, 0),      -- Gold
        SUCCESS = Color3.fromRGB(16, 124, 16),     -- Green
        ERROR = Color3.fromRGB(232, 17, 35),       -- Red
        WARNING = Color3.fromRGB(255, 140, 0),     -- Orange
        INFO = Color3.fromRGB(0, 120, 215),        -- Blue
        BACKGROUND = Color3.fromRGB(32, 32, 32),   -- Dark Gray
        TEXT_PRIMARY = Color3.fromRGB(255, 255, 255), -- White
        TEXT_SECONDARY = Color3.fromRGB(200, 200, 200) -- Light Gray
    },
    FONTS = {
        HEADER = Enum.Font.SourceSansBold,
        BODY = Enum.Font.SourceSans,
        BUTTON = Enum.Font.SourceSansSemibold
    },
    SIZES = {
        BUTTON_HEIGHT = 40,
        PADDING = 10,
        CORNER_RADIUS = 8,
        BORDER = 2
    },
    ANIMATION = {
        TWEEN_TIME = 0.2,
        FADE_TIME = 0.3
    },
    Z_INDEX = {
        BACKGROUND = 1,
        CONTENT = 2,
        OVERLAY = 3,
        MODAL = 4,
        TOOLTIP = 5,
        NOTIFICATION = 6
    }
}

-- Registered UI components
local registeredComponents = {}

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[UIRegistry] Failed to require module:", result)
        return nil
    end
end

-- Get ModuleScriptAccessor if available
local function getModuleScriptAccessor()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        return safeRequire(shared.ModuleScriptAccessor)
    end
    return nil
end

-- Try to get UIComponents
local function getUIComponents()
    -- Try through ModuleScriptAccessor first
    local ModuleScriptAccessor = getModuleScriptAccessor()
    if ModuleScriptAccessor then
        local uiComponents = ModuleScriptAccessor.getSystem("UIComponents")
        if uiComponents then
            return uiComponents
        end
    end
    
    -- Try direct paths
    local paths = {
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("UIComponents"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild("UIComponents"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and ReplicatedStorage.src.client:FindFirstChild("Core") and ReplicatedStorage.src.client.Core:FindFirstChild("UIComponents")
    }
    
    for _, path in ipairs(paths) do
        if path then
            local result = safeRequire(path)
            if result then
                return result
            end
        end
    end
    
    return nil
end

-- Button Factory
UIRegistry.ButtonFactory = {}

function UIRegistry.ButtonFactory.createBasicButton(properties)
    -- Try to use UIComponents first
    local UIComponents = getUIComponents()
    if UIComponents and UIComponents.ButtonFactory and UIComponents.ButtonFactory.createBasicButton then
        return UIComponents.ButtonFactory.createBasicButton(properties)
    end
    
    -- Fallback implementation if UIComponents not found
    properties = properties or {}
    
    local button = Instance.new("TextButton")
    button.Size = properties.Size or UDim2.new(0, 200, 0, UIConfig.SIZES.BUTTON_HEIGHT)
    button.Position = properties.Position or UDim2.new(0.5, -100, 0.5, 0)
    button.BackgroundColor3 = properties.BackgroundColor3 or UIConfig.COLORS.PRIMARY
    button.Font = properties.Font or UIConfig.FONTS.BUTTON
    button.TextColor3 = properties.TextColor3 or UIConfig.COLORS.TEXT_PRIMARY
    button.TextSize = properties.TextSize or 16
    button.Text = properties.Text or "Button"
    button.AutoButtonColor = properties.AutoButtonColor ~= nil and properties.AutoButtonColor or true
    button.Name = properties.Name or "Button"
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, properties.CornerRadius or UIConfig.SIZES.CORNER_RADIUS)
    corner.Parent = button
    
    -- Add hover effect
    if properties.HoverEffect ~= false then
        local originalColor = button.BackgroundColor3
        local hoverColor = Color3.new(
            math.min(originalColor.R * 1.1, 1),
            math.min(originalColor.G * 1.1, 1),
            math.min(originalColor.B * 1.1, 1)
        )
        
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = hoverColor
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = originalColor
        end)
    end
    
    -- Custom callback
    if properties.Callback and type(properties.Callback) == "function" then
        button.MouseButton1Click:Connect(properties.Callback)
    end
    
    return button
end

function UIRegistry.ButtonFactory.createStyledButton(style, properties)
    -- Try to use UIComponents first
    local UIComponents = getUIComponents()
    if UIComponents and UIComponents.ButtonFactory and UIComponents.ButtonFactory.createStyledButton then
        return UIComponents.ButtonFactory.createStyledButton(style, properties)
    end
    
    -- Fallback implementation if UIComponents not found
    properties = properties or {}
    
    -- Apply predefined styles
    if style == "primary" then
        properties.BackgroundColor3 = properties.BackgroundColor3 or UIConfig.COLORS.PRIMARY
    elseif style == "secondary" then
        properties.BackgroundColor3 = properties.BackgroundColor3 or UIConfig.COLORS.SECONDARY
    elseif style == "success" then
        properties.BackgroundColor3 = properties.BackgroundColor3 or UIConfig.COLORS.SUCCESS
    elseif style == "warning" then
        properties.BackgroundColor3 = properties.BackgroundColor3 or UIConfig.COLORS.WARNING
    elseif style == "error" then
        properties.BackgroundColor3 = properties.BackgroundColor3 or UIConfig.COLORS.ERROR
    end
    
    return UIRegistry.ButtonFactory.createBasicButton(properties)
end

-- Dialog Factory
UIRegistry.DialogFactory = {}

function UIRegistry.DialogFactory.createNotification(properties)
    -- Try to use UIComponents first
    local UIComponents = getUIComponents()
    if UIComponents and UIComponents.DialogFactory and UIComponents.DialogFactory.createNotification then
        return UIComponents.DialogFactory.createNotification(properties)
    end
    
    -- Fallback implementation if UIComponents not found
    properties = properties or {}
    
    -- Create the main frame
    local notification = Instance.new("Frame")
    notification.Size = properties.Size or UDim2.new(0, 300, 0, 80)
    notification.Position = properties.Position or UDim2.new(1, -320, 0, 20)
    notification.BackgroundColor3 = properties.BackgroundColor3 or UIConfig.COLORS.BACKGROUND
    notification.BorderSizePixel = 0
    notification.Name = properties.Name or "Notification"
    notification.ZIndex = UIConfig.Z_INDEX.NOTIFICATION
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, properties.CornerRadius or UIConfig.SIZES.CORNER_RADIUS)
    corner.Parent = notification
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 25)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = UIConfig.FONTS.HEADER
    title.TextColor3 = UIConfig.COLORS.TEXT_PRIMARY
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = properties.Title or "Notification"
    title.Name = "Title"
    title.ZIndex = UIConfig.Z_INDEX.NOTIFICATION
    title.Parent = notification
    
    -- Message
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, -20, 1, -45)
    message.Position = UDim2.new(0, 10, 0, 35)
    message.BackgroundTransparency = 1
    message.Font = UIConfig.FONTS.BODY
    message.TextColor3 = UIConfig.COLORS.TEXT_SECONDARY
    message.TextSize = 16
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextYAlignment = Enum.TextYAlignment.Top
    message.TextWrapped = true
    message.Text = properties.Message or "This is a notification message."
    message.Name = "Message"
    message.ZIndex = UIConfig.Z_INDEX.NOTIFICATION
    message.Parent = notification
    
    -- Add notification to the PlayerGui
    if properties.Parent then
        notification.Parent = properties.Parent
    else
        -- Try to find an appropriate parent
        if RunService:IsClient() then
            local player = Players.LocalPlayer
            if player and player:FindFirstChild("PlayerGui") then
                -- Create notification container if it doesn't exist
                local notificationsContainer = player.PlayerGui:FindFirstChild("NotificationsContainer")
                if not notificationsContainer then
                    notificationsContainer = Instance.new("ScreenGui")
                    notificationsContainer.Name = "NotificationsContainer"
                    notificationsContainer.ResetOnSpawn = false
                    notificationsContainer.Parent = player.PlayerGui
                end
                notification.Parent = notificationsContainer
            else
                warn("[UIRegistry] Could not find PlayerGui to parent notification")
            end
        else
            warn("[UIRegistry] Notifications can only be shown to clients")
        end
    end
    
    -- Auto-destroy after duration
    if properties.Duration then
        task.delay(properties.Duration, function()
            if notification and notification.Parent then
                notification:Destroy()
            end
        end)
    end
    
    return notification
end

function UIRegistry.DialogFactory.showNotification(title, message, notificationType, duration)
    local properties = {
        Title = title,
        Message = message,
        Duration = duration or 5
    }
    
    -- Set color based on notification type
    if notificationType == "success" then
        properties.BackgroundColor3 = UIConfig.COLORS.SUCCESS
    elseif notificationType == "error" then
        properties.BackgroundColor3 = UIConfig.COLORS.ERROR
    elseif notificationType == "warning" then
        properties.BackgroundColor3 = UIConfig.COLORS.WARNING
    elseif notificationType == "info" then
        properties.BackgroundColor3 = UIConfig.COLORS.INFO
    end
    
    return UIRegistry.DialogFactory.createNotification(properties)
end

-- UI Style utilities
UIRegistry.UIStyle = {
    COLORS = UIConfig.COLORS,
    FONTS = UIConfig.FONTS,
    SIZES = UIConfig.SIZES,
    ANIMATION = UIConfig.ANIMATION,
    
    applyStyle = function(instance, style)
        -- Try to use UIComponents first
        local UIComponents = getUIComponents()
        if UIComponents and UIComponents.UIStyle and UIComponents.UIStyle.applyStyle then
            return UIComponents.UIStyle.applyStyle(instance, style)
        end
        
        -- Fallback implementation if UIComponents not found
        style = style or {}
        
        if not instance then return end
        
        -- Apply relevant properties based on instance type
        if instance:IsA("GuiObject") then
            -- Background color
            if style.BackgroundColor3 then
                instance.BackgroundColor3 = style.BackgroundColor3
            end
            
            -- Text color
            if instance:IsA("TextButton") or instance:IsA("TextLabel") or instance:IsA("TextBox") then
                if style.TextColor3 then
                    instance.TextColor3 = style.TextColor3
                end
                
                if style.Font then
                    instance.Font = style.Font
                end
                
                if style.TextSize then
                    instance.TextSize = style.TextSize
                end
            end
            
            -- Border
            if style.BorderColor3 then
                instance.BorderColor3 = style.BorderColor3
            end
            
            if style.BorderSizePixel ~= nil then
                instance.BorderSizePixel = style.BorderSizePixel
            end
        end
    end
}

-- Icon set
UIRegistry.IconSet = {
    SUCCESS = "rbxassetid://9801447135",  -- Green checkmark
    ERROR = "rbxassetid://9801447023",    -- Red X
    WARNING = "rbxassetid://9801447287",  -- Warning triangle
    INFO = "rbxassetid://9801446906",     -- Information icon
    
    getIcon = function(iconType)
        -- Try to use UIComponents first
        local UIComponents = getUIComponents()
        if UIComponents and UIComponents.IconSet and UIComponents.IconSet.getIcon then
            return UIComponents.IconSet.getIcon(iconType)
        end
        
        -- Fallback implementation if UIComponents not found
        return UIRegistry.IconSet[string.upper(iconType)] or UIRegistry.IconSet.INFO
    end
}

-- Register a UI component
function UIRegistry.registerComponent(name, component)
    if not name or type(name) ~= "string" then
        warn("[UIRegistry] Invalid component name")
        return false
    end
    
    if not component then
        warn("[UIRegistry] Invalid component object for " .. name)
        return false
    end
    
    registeredComponents[name] = component
    return true
end

-- Get a registered UI component
function UIRegistry.getComponent(name)
    return registeredComponents[name]
end

-- Initialize the module
function UIRegistry.initialize()
    if UIRegistry.initialized then
        return true
    end
    
    -- Try to find ModuleScriptAccessor
    local ModuleScriptAccessor = getModuleScriptAccessor()
    if ModuleScriptAccessor then
        -- Try to register with CoreRegistry
        local CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
        if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
            CoreRegistry.registerSystem("UIRegistry", UIRegistry)
            print("[UIRegistry] Registered with CoreRegistry")
        end
    end
    
    UIRegistry.initialized = true
    print("[UIRegistry] UIRegistry initialized")
    return true
end

-- Initialize on load
UIRegistry.initialize()

return UIRegistry
