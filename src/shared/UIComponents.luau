--[[
    UIComponents.luau
    
    A collection of common UI components and utilities for use across the game.
    This module provides access to UI styles, icons, and component factories.
    
    Created: April 25, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Constants
local DEBUG_ENABLED = true

-- Debug logging
local function log(message)
    if DEBUG_ENABLED then
        print("[UIComponents] " .. message)
    end
end

local function warn_log(message)
    warn("[UIComponents] " .. message)
end

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn_log("Failed to require " .. tostring(module:GetFullName()) .. ": " .. tostring(result))
        return nil
    end
    
    return result
end

-- Default UI style
local defaultUIStyle = {
    colors = {
        background = Color3.fromRGB(40, 40, 60),
        backgroundLight = Color3.fromRGB(60, 60, 80),
        backgroundDark = Color3.fromRGB(30, 30, 45),
        accent = Color3.fromRGB(80, 150, 255),
        accentLight = Color3.fromRGB(130, 180, 255),
        accentDark = Color3.fromRGB(60, 120, 200),
        text = Color3.fromRGB(240, 240, 255),
        textDimmed = Color3.fromRGB(180, 180, 200),
        textDisabled = Color3.fromRGB(120, 120, 140),
        success = Color3.fromRGB(80, 240, 120),
        warning = Color3.fromRGB(255, 200, 80),
        error = Color3.fromRGB(255, 80, 80)
    },
    
    transparency = {
        standard = 0,
        semitransparent = 0.3,
        transparent = 0.7,
        hover = 0.1
    },
    
    fonts = {
        header = Enum.Font.GothamBold,
        subheader = Enum.Font.GothamMedium,
        body = Enum.Font.Gotham,
        button = Enum.Font.GothamMedium,
        numeric = Enum.Font.Gotham
    },
    
    fontSizes = {
        title = 24,
        header = 20,
        subheader = 18,
        body = 16,
        small = 14,
        tiny = 12
    },
    
    padding = {
        small = UDim.new(0, 4),
        medium = UDim.new(0, 8),
        large = UDim.new(0, 12),
        xlarge = UDim.new(0, 16)
    },
    
    cornerRadius = {
        none = UDim.new(0, 0),
        small = UDim.new(0, 4),
        medium = UDim.new(0, 8),
        large = UDim.new(0, 12),
        circle = UDim.new(1, 0)
    },
    
    shadows = {
        none = 0,
        small = 2,
        medium = 4,
        large = 8
    },
    
    animations = {
        fast = 0.15,
        medium = 0.3,
        slow = 0.5
    },
    
    spacing = {
        xsmall = 2,
        small = 4,
        medium = 8,
        large = 12,
        xlarge = 16,
        xxlarge = 24
    }
}

-- Default icon set (using placeholder IDs - update with actual asset IDs)
local defaultIconSet = {
    close = "rbxassetid://8093755787",
    settings = "rbxassetid://8093754726",
    info = "rbxassetid://8093754900",
    warning = "rbxassetid://8093755364",
    error = "rbxassetid://8093755611",
    success = "rbxassetid://8093755457",
    play = "rbxassetid://6026663699",
    pause = "rbxassetid://6026663719",
    shop = "rbxassetid://6031265976",
    coins = "rbxassetid://6031225816",
    gems = "rbxassetid://6031164899",
    star = "rbxassetid://6031068429",
    heart = "rbxassetid://6026568215",
    person = "rbxassetid://6031302932",
    search = "rbxassetid://6031154899",
    plus = "rbxassetid://6035067836",
    minus = "rbxassetid://6035067857",
    home = "rbxassetid://6026568255",
    chat = "rbxassetid://6031302921",
    menu = "rbxassetid://6031091000",
    achievements = "rbxassetid://6031254678",
    leaderboard = "rbxassetid://6031302920",
    gear = "rbxassetid://6031280345",
    lock = "rbxassetid://6031302925",
    unlock = "rbxassetid://6031302926",
    refresh = "rbxassetid://6026663697",
    notification = "rbxassetid://6026663699",
    share = "rbxassetid://6026663704",
    download = "rbxassetid://6026663694",
    upload = "rbxassetid://6026663705",
    check = "rbxassetid://6031094667",
    cross = "rbxassetid://6031094670"
}

-- UI Components module
local UIComponents = {
    UIStyle = defaultUIStyle,
    IconSet = defaultIconSet,
    initialized = false,
    components = {}
}

-- Create a basic button
function UIComponents:createButton(properties)
    properties = properties or {}
    
    local style = self.UIStyle
    
    local button = Instance.new("TextButton")
    button.Name = properties.name or "Button"
    button.Size = properties.size or UDim2.new(0, 200, 0, 40)
    button.BackgroundColor3 = properties.backgroundColor or style.colors.accent
    button.TextColor3 = properties.textColor or style.colors.text
    button.Text = properties.text or "Button"
    button.Font = properties.font or style.fonts.button
    button.TextSize = properties.textSize or style.fontSizes.body
    button.BorderSizePixel = 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = properties.cornerRadius or style.cornerRadius.medium
    corner.Parent = button
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = style.padding.medium
    padding.PaddingRight = style.padding.medium
    padding.Parent = button
    
    -- Add hover/press effects
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = properties.hoverColor or style.colors.accentLight
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = properties.backgroundColor or style.colors.accent
    end)
    
    button.MouseButton1Down:Connect(function()
        button.BackgroundColor3 = properties.pressColor or style.colors.accentDark
    end)
    
    button.MouseButton1Up:Connect(function()
        button.BackgroundColor3 = properties.hoverColor or style.colors.accentLight
    end)
    
    -- Assign parent if provided
    if properties.parent then
        button.Parent = properties.parent
    end
    
    return button
end

-- Create an icon button
function UIComponents:createIconButton(properties)
    properties = properties or {}
    
    local style = self.UIStyle
    
    local button = Instance.new("ImageButton")
    button.Name = properties.name or "IconButton"
    button.Size = properties.size or UDim2.new(0, 40, 0, 40)
    button.BackgroundColor3 = properties.backgroundColor or style.colors.background
    button.BackgroundTransparency = properties.backgroundTransparency or 1
    button.Image = properties.icon or self.IconSet.close
    button.ImageColor3 = properties.iconColor or style.colors.text
    button.BorderSizePixel = 0
    
    -- Add corner radius
    if properties.cornerRadius ~= nil then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = properties.cornerRadius or style.cornerRadius.circle
        corner.Parent = button
    end
    
    -- Add hover/press effects
    button.MouseEnter:Connect(function()
        button.ImageColor3 = properties.hoverColor or style.colors.accentLight
    end)
    
    button.MouseLeave:Connect(function()
        button.ImageColor3 = properties.iconColor or style.colors.text
    end)
    
    button.MouseButton1Down:Connect(function()
        button.ImageColor3 = properties.pressColor or style.colors.accentDark
    end)
    
    button.MouseButton1Up:Connect(function()
        button.ImageColor3 = properties.hoverColor or style.colors.accentLight
    end)
    
    -- Assign parent if provided
    if properties.parent then
        button.Parent = properties.parent
    end
    
    return button
end

-- Create a text label with proper styling
function UIComponents:createLabel(properties)
    properties = properties or {}
    
    local style = self.UIStyle
    
    local label = Instance.new("TextLabel")
    label.Name = properties.name or "Label"
    label.Size = properties.size or UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = properties.backgroundTransparency or 1
    label.TextColor3 = properties.textColor or style.colors.text
    label.Text = properties.text or ""
    label.Font = properties.font or style.fonts.body
    label.TextSize = properties.textSize or style.fontSizes.body
    label.TextXAlignment = properties.textXAlignment or Enum.TextXAlignment.Left
    label.TextYAlignment = properties.textYAlignment or Enum.TextYAlignment.Center
    label.TextWrapped = properties.textWrapped or false
    label.RichText = properties.richText or true
    label.AutomaticSize = properties.automaticSize or Enum.AutomaticSize.None
    
    -- Assign parent if provided
    if properties.parent then
        label.Parent = properties.parent
    end
    
    return label
end

-- Create a frame with proper styling
function UIComponents:createFrame(properties)
    properties = properties or {}
    
    local style = self.UIStyle
    
    local frame = Instance.new("Frame")
    frame.Name = properties.name or "Frame"
    frame.Size = properties.size or UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = properties.backgroundColor or style.colors.background
    frame.BackgroundTransparency = properties.backgroundTransparency or 0
    frame.BorderSizePixel = 0
    
    -- Add corner radius if specified
    if properties.cornerRadius ~= nil then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = properties.cornerRadius or style.cornerRadius.medium
        corner.Parent = frame
    end
    
    -- Add padding if specified
    if properties.padding ~= nil then
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = properties.padding.top or style.padding.medium
        padding.PaddingBottom = properties.padding.bottom or style.padding.medium
        padding.PaddingLeft = properties.padding.left or style.padding.medium
        padding.PaddingRight = properties.padding.right or style.padding.medium
        padding.Parent = frame
    end
    
    -- Assign parent if provided
    if properties.parent then
        frame.Parent = properties.parent
    end
    
    return frame
end

-- Create an input field
function UIComponents:createInputField(properties)
    properties = properties or {}
    
    local style = self.UIStyle
    
    local container = self:createFrame({
        name = properties.name or "InputContainer",
        size = properties.size or UDim2.new(0, 200, 0, 40),
        backgroundColor = properties.backgroundColor or style.colors.backgroundLight,
        cornerRadius = properties.cornerRadius or style.cornerRadius.medium
    })
    
    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.Size = UDim2.new(1, 0, 1, 0)
    textBox.BackgroundTransparency = 1
    textBox.TextColor3 = properties.textColor or style.colors.text
    textBox.PlaceholderText = properties.placeholderText or "Enter text..."
    textBox.PlaceholderColor3 = properties.placeholderColor or style.colors.textDimmed
    textBox.Text = properties.text or ""
    textBox.Font = properties.font or style.fonts.body
    textBox.TextSize = properties.textSize or style.fontSizes.body
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = properties.clearTextOnFocus or false
    textBox.Parent = container
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = style.padding.medium
    padding.PaddingRight = style.padding.medium
    padding.Parent = textBox
    
    -- Add focus/unfocus effects
    textBox.Focused:Connect(function()
        container.BackgroundColor3 = properties.focusColor or style.colors.accent
    end)
    
    textBox.FocusLost:Connect(function()
        container.BackgroundColor3 = properties.backgroundColor or style.colors.backgroundLight
    end)
    
    -- Assign parent if provided
    if properties.parent then
        container.Parent = properties.parent
    end
    
    return container, textBox
end

-- Create a notification dialog
function UIComponents:createNotification(properties)
    properties = properties or {}
    
    local style = self.UIStyle
    
    -- Create notification container
    local notification = self:createFrame({
        name = "Notification",
        size = UDim2.new(0, 300, 0, 80),
        backgroundColor = properties.type == "error" and style.colors.error
                        or properties.type == "warning" and style.colors.warning
                        or properties.type == "success" and style.colors.success
                        or properties.backgroundColor or style.colors.accent,
        cornerRadius = style.cornerRadius.medium
    })
    notification.Position = properties.position or UDim2.new(0.5, -150, 0, -100)
    
    -- Create layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, style.spacing.medium)
    layout.Parent = notification
    
    -- Create title
    local title = self:createLabel({
        name = "Title",
        text = properties.title or "Notification",
        textColor = properties.titleColor or style.colors.text,
        font = style.fonts.header,
        textSize = style.fontSizes.header,
        textXAlignment = Enum.TextXAlignment.Center,
        parent = notification
    })
    
    -- Create message
    local message = self:createLabel({
        name = "Message",
        text = properties.message or "",
        textColor = properties.messageColor or style.colors.text,
        font = style.fonts.body,
        textSize = style.fontSizes.body,
        textXAlignment = Enum.TextXAlignment.Center,
        textWrapped = true,
        parent = notification
    })
    
    -- Create ok button
    local buttonContainer = self:createFrame({
        name = "ButtonContainer",
        size = UDim2.new(1, 0, 0, 40),
        backgroundTransparency = 1,
        parent = notification
    })
    
    local okButton = self:createButton({
        name = "OkButton",
        text = properties.buttonText or "OK",
        size = UDim2.new(0.6, 0, 0, 35),
        parent = buttonContainer
    })
    okButton.Position = UDim2.new(0.5, -okButton.Size.X.Offset/2, 0, 0)
    
    -- Add notification to parent
    if properties.parent then
        notification.Parent = properties.parent
    else
        -- If no parent specified, add to PlayerGui
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local notificationGui = playerGui:FindFirstChild("NotificationGui")
            if not notificationGui then
                notificationGui = Instance.new("ScreenGui")
                notificationGui.Name = "NotificationGui"
                notificationGui.ResetOnSpawn = false
                notificationGui.Parent = playerGui
            end
            notification.Parent = notificationGui
        else
            warn_log("PlayerGui not found, cannot show notification")
            return notification
        end
    end
    
    -- Animate in
    notification:TweenPosition(
        UDim2.new(0.5, -150, 0, 100),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.5,
        true
    )
    
    -- Set up auto-close
    local duration = properties.duration or 5
    if duration > 0 then
        task.delay(duration, function()
            -- Animate out
            notification:TweenPosition(
                UDim2.new(0.5, -150, 0, -100),
                Enum.EasingDirection.In,
                Enum.EasingStyle.Quad,
                0.5,
                true,
                function()
                    notification:Destroy()
                end
            )
        end)
    end
    
    -- Set up button to close
    okButton.MouseButton1Click:Connect(function()
        -- Animate out
        notification:TweenPosition(
            UDim2.new(0.5, -150, 0, -100),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Quad,
            0.5,
            true,
            function()
                notification:Destroy()
            end
        )
    end)
    
    return notification
end

-- Register with ClientRegistry
function UIComponents:registerWithClientRegistry(clientRegistry)
    if not clientRegistry then
        warn_log("Cannot register with nil ClientRegistry")
        return false
    end
    
    log("Registering with ClientRegistry")
    
    -- Check if registerUIComponent is available
    if typeof(clientRegistry.registerUIComponent) == "function" then
        clientRegistry:registerUIComponent("UIStyle", self.UIStyle)
        clientRegistry:registerUIComponent("IconSet", self.IconSet)
        
        -- Register component factories
        clientRegistry:registerUIComponent("ButtonFactory", {
            createButton = function(...) 
                return self:createButton(...) 
            end,
            createIconButton = function(...) 
                return self:createIconButton(...) 
            end
        })
        
        clientRegistry:registerUIComponent("DialogFactory", {
            createNotification = function(...)
                return self:createNotification(...)
            end
        })
        
        -- Register self
        clientRegistry:registerUIComponent("UIComponents", self)
        
        log("Successfully registered with ClientRegistry")
        return true
    else
        warn_log("ClientRegistry does not have registerUIComponent method")
        return false
    end
end

-- Initialize the module
function UIComponents:initialize()
    if self.initialized then
        return
    end
    
    log("Initializing UIComponents...")
    
    -- Try to load UIStyle if it exists
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if sharedFolder then
        local uiStyleModule = sharedFolder:FindFirstChild("UIStyle")
        if uiStyleModule then
            local uiStyle = requireSafely(uiStyleModule)
            if uiStyle then
                self.UIStyle = uiStyle
                log("Loaded UIStyle module")
            end
        end
        
        -- Try to load IconSet if it exists
        local iconSetModule = sharedFolder:FindFirstChild("IconSet")
        if iconSetModule then
            local iconSet = requireSafely(iconSetModule)
            if iconSet then
                self.IconSet = iconSet
                log("Loaded IconSet module")
            end
        end
    end
    
    -- Register components for internal reference
    self.components = {
        UIStyle = self.UIStyle,
        IconSet = self.IconSet,
        ButtonFactory = {
            createButton = function(...) 
                return self:createButton(...) 
            end,
            createIconButton = function(...) 
                return self:createIconButton(...) 
            end
        },
        DialogFactory = {
            createNotification = function(...)
                return self:createNotification(...)
            end
        }
    }
    
    -- Try to find ClientRegistry to register with
    local clientRegistryFound = false
    
    -- Try to find ClientRegistry in ReplicatedStorage.shared
    if sharedFolder and sharedFolder:FindFirstChild("ClientRegistry") then
        local clientRegistry = requireSafely(sharedFolder.ClientRegistry)
        if clientRegistry then
            clientRegistryFound = self:registerWithClientRegistry(clientRegistry)
        end
    end
    
    -- If not found in shared, try PlayerScripts
    if not clientRegistryFound and LocalPlayer then
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if playerScripts and 
           playerScripts:FindFirstChild("Client") and
           playerScripts.Client:FindFirstChild("Core") and
           playerScripts.Client.Core:FindFirstChild("ClientRegistry") then
            
            local clientRegistry = requireSafely(playerScripts.Client.Core.ClientRegistry)
            if clientRegistry then
                clientRegistryFound = self:registerWithClientRegistry(clientRegistry)
            end
        end
    end
    
    if not clientRegistryFound then
        warn_log("Could not find ClientRegistry to register with")
    end
    
    self.initialized = true
    log("UIComponents initialized")
end

-- Initialize the module
UIComponents:initialize()

return UIComponents
