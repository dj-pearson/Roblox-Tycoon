--[[
    UIComponents.luau
    
    Central module for UI components and factories.
    Provides standardized UI elements and styling for the entire game.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UIComponents = {}
UIComponents.initialized = false

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
    }
}

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[UIComponents] Failed to require module:", result)
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

-- Button Factory
UIComponents.ButtonFactory = {}

function UIComponents.ButtonFactory.createBasicButton(properties)
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
    
    -- Add click effect
    if properties.ClickEffect ~= false then
        button.MouseButton1Down:Connect(function()
            button:TweenSize(
                button.Size - UDim2.new(0, 4, 0, 4),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.1,
                true
            )
        end)
        
        button.MouseButton1Up:Connect(function()
            button:TweenSize(
                properties.Size or UDim2.new(0, 200, 0, UIConfig.SIZES.BUTTON_HEIGHT),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.1,
                true
            )
        end)
    end
    
    -- Custom callback
    if properties.Callback and type(properties.Callback) == "function" then
        button.MouseButton1Click:Connect(properties.Callback)
    end
    
    return button
end

function UIComponents.ButtonFactory.createStyledButton(style, properties)
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
    elseif style == "info" then
        properties.BackgroundColor3 = properties.BackgroundColor3 or UIConfig.COLORS.INFO
    end
    
    return UIComponents.ButtonFactory.createBasicButton(properties)
end

-- Dialog Factory
UIComponents.DialogFactory = {}

function UIComponents.DialogFactory.createNotification(properties)
    properties = properties or {}
    
    -- Create the main frame
    local notification = Instance.new("Frame")
    notification.Size = properties.Size or UDim2.new(0, 300, 0, 80)
    notification.Position = properties.Position or UDim2.new(1, -320, 0, 20)
    notification.BackgroundColor3 = properties.BackgroundColor3 or UIConfig.COLORS.BACKGROUND
    notification.BorderSizePixel = 0
    notification.Name = properties.Name or "Notification"
    
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
    message.Parent = notification
    
    -- Status bar (colored accent on the left side)
    local status = Instance.new("Frame")
    status.Size = UDim2.new(0, 4, 1, 0)
    status.Position = UDim2.new(0, 0, 0, 0)
    status.BackgroundColor3 = properties.StatusColor or UIConfig.COLORS.INFO
    status.BorderSizePixel = 0
    status.Name = "StatusBar"
    status.Parent = notification
    
    -- Add corner radius to left side of status bar
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, properties.CornerRadius or UIConfig.SIZES.CORNER_RADIUS)
    statusCorner.Parent = status
    
    -- Close button
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 20, 0, 20)
    close.Position = UDim2.new(1, -25, 0, 10)
    close.BackgroundTransparency = 1
    close.Font = UIConfig.FONTS.BODY
    close.TextColor3 = UIConfig.COLORS.TEXT_SECONDARY
    close.TextSize = 16
    close.Text = "✕"
    close.Name = "CloseButton"
    close.Parent = notification
    
    -- Auto-destroy after duration
    if properties.Duration then
        task.delay(properties.Duration, function()
            if notification and notification.Parent then
                notification:Destroy()
            end
        end)
    end
    
    -- Close button functionality
    close.MouseButton1Click:Connect(function()
        notification:Destroy()
    end)
    
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
                warn("[UIComponents] Could not find PlayerGui to parent notification")
            end
        else
            warn("[UIComponents] Notifications can only be shown to clients")
        end
    end
    
    return notification
end

function UIComponents.DialogFactory.createModal(properties)
    properties = properties or {}
    
    -- Create background overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Name = properties.Name or "ModalOverlay"
    
    -- Create the main modal frame
    local modal = Instance.new("Frame")
    modal.Size = properties.Size or UDim2.new(0, 400, 0, 300)
    modal.Position = properties.Position or UDim2.new(0.5, -200, 0.5, -150)
    modal.BackgroundColor3 = properties.BackgroundColor3 or UIConfig.COLORS.BACKGROUND
    modal.BorderSizePixel = 0
    modal.Name = "ModalFrame"
    modal.Parent = overlay
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, properties.CornerRadius or UIConfig.SIZES.CORNER_RADIUS)
    corner.Parent = modal
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = UIConfig.FONTS.HEADER
    title.TextColor3 = UIConfig.COLORS.TEXT_PRIMARY
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = properties.Title or "Modal Dialog"
    title.Name = "Title"
    title.Parent = modal
    
    -- Content frame
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -110)
    content.Position = UDim2.new(0, 10, 0, 60)
    content.BackgroundTransparency = 1
    content.Name = "ContentFrame"
    content.Parent = modal
    
    -- Message
    if properties.Message then
        local message = Instance.new("TextLabel")
        message.Size = UDim2.new(1, 0, 1, 0)
        message.BackgroundTransparency = 1
        message.Font = UIConfig.FONTS.BODY
        message.TextColor3 = UIConfig.COLORS.TEXT_SECONDARY
        message.TextSize = 16
        message.TextWrapped = true
        message.Text = properties.Message
        message.Name = "Message"
        message.Parent = content
    end
    
    -- Button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -20, 0, 40)
    buttonContainer.Position = UDim2.new(0, 10, 1, -50)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Parent = modal
    
    -- Close button
    local closeButton = UIComponents.ButtonFactory.createBasicButton({
        Size = UDim2.new(0, 100, 0, 40),
        Position = properties.ActionButton and UDim2.new(1, -220, 0, 0) or UDim2.new(1, -110, 0, 0),
        Text = properties.CloseText or "Close",
        BackgroundColor3 = UIConfig.COLORS.SECONDARY
    })
    closeButton.Name = "CloseButton"
    closeButton.Parent = buttonContainer
    
    closeButton.MouseButton1Click:Connect(function()
        overlay:Destroy()
        if properties.OnClose and type(properties.OnClose) == "function" then
            properties.OnClose()
        end
    end)
    
    -- Action button (optional)
    if properties.ActionButton then
        local actionButton = UIComponents.ButtonFactory.createBasicButton({
            Size = UDim2.new(0, 100, 0, 40),
            Position = UDim2.new(1, -110, 0, 0),
            Text = properties.ActionText or "Confirm",
            BackgroundColor3 = UIConfig.COLORS.PRIMARY
        })
        actionButton.Name = "ActionButton"
        actionButton.Parent = buttonContainer
        
        actionButton.MouseButton1Click:Connect(function()
            if properties.OnAction and type(properties.OnAction) == "function" then
                properties.OnAction()
            end
            overlay:Destroy()
        end)
    end
    
    -- Add modal to the PlayerGui
    if properties.Parent then
        overlay.Parent = properties.Parent
    else
        -- Try to find an appropriate parent
        if RunService:IsClient() then
            local player = Players.LocalPlayer
            if player and player:FindFirstChild("PlayerGui") then
                -- Create modal container if it doesn't exist
                local modalContainer = player.PlayerGui:FindFirstChild("ModalContainer")
                if not modalContainer then
                    modalContainer = Instance.new("ScreenGui")
                    modalContainer.Name = "ModalContainer"
                    modalContainer.ResetOnSpawn = false
                    modalContainer.Parent = player.PlayerGui
                end
                overlay.Parent = modalContainer
            else
                warn("[UIComponents] Could not find PlayerGui to parent modal")
            end
        else
            warn("[UIComponents] Modals can only be shown to clients")
        end
    end
    
    return overlay
end

-- UI Style utilities
UIComponents.UIStyle = {
    COLORS = UIConfig.COLORS,
    FONTS = UIConfig.FONTS,
    SIZES = UIConfig.SIZES,
    ANIMATION = UIConfig.ANIMATION,
    
    applyStyle = function(instance, style)
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
            
            -- Size and position
            if style.Size then
                instance.Size = style.Size
            end
            
            if style.Position then
                instance.Position = style.Position
            end
        end
    end
}

-- Icon set
UIComponents.IconSet = {
    SUCCESS = "rbxassetid://9801447135",  -- Green checkmark
    ERROR = "rbxassetid://9801447023",    -- Red X
    WARNING = "rbxassetid://9801447287",  -- Warning triangle
    INFO = "rbxassetid://9801446906",     -- Information icon
    
    getIcon = function(iconType)
        return UIComponents.IconSet[string.upper(iconType)] or UIComponents.IconSet.INFO
    end
}

-- Initialize the UIComponents module
function UIComponents.initialize()
    if UIComponents.initialized then
        return true
    end
    
    -- Register with CoreRegistry if available
    local ModuleScriptAccessor = getModuleScriptAccessor()
    if ModuleScriptAccessor then
        local CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
        if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
            CoreRegistry.registerSystem("UIComponents", UIComponents)
            print("[UIComponents] Registered with CoreRegistry")
        end
    end
    
    UIComponents.initialized = true
    print("[UIComponents] Successfully initialized")
    return true
end

-- Initialize on load
UIComponents.initialize()

return UIComponents
