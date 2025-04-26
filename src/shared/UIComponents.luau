--!strict
--[[
    UIComponents.luau
    A consolidated module for UI components that bundles together UIStyle, IconSet, ButtonFactory, and DialogFactory
    
    Created: April 25, 2025
    
    This module helps resolve common UI loading issues by:
    1. Bundling all UI components together to ensure consistent loading
    2. Providing built-in fallbacks for each component
    3. Handling cross-dependencies between UI modules
    4. Using safe require patterns to avoid errors
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Create shared folder if it doesn't exist
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = ReplicatedStorage
    print("[UIComponents] Created shared folder in ReplicatedStorage")
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
        warn("[UIComponents] Failed to require module: ", module:GetFullName())
        return nil
    end
    
    return result
end

-- Try loading original modules
local originalUIStyle = requireSafely(sharedFolder:FindFirstChild("UIStyle"))
local originalIconSet = requireSafely(sharedFolder:FindFirstChild("IconSet"))
local originalButtonFactory = requireSafely(sharedFolder:FindFirstChild("ButtonFactory"))
local originalDialogFactory = requireSafely(sharedFolder:FindFirstChild("DialogFactory"))

-- Container for UI components
local UIComponents = {}

-- UIStyle Component
UIComponents.UIStyle = originalUIStyle or {}

-- Default colors
UIComponents.UIStyle.Colors = originalUIStyle and originalUIStyle.Colors or {
    -- Base colors
    Primary = Color3.fromRGB(0, 120, 215),       -- Primary brand color
    PrimaryHover = Color3.fromRGB(20, 140, 235), -- Primary hover state
    Secondary = Color3.fromRGB(80, 150, 255),    -- Secondary brand color
    SecondaryHover = Color3.fromRGB(100, 170, 255), -- Secondary hover state
    
    -- Background colors
    Background = Color3.fromRGB(40, 40, 60),        -- Main background
    BackgroundLight = Color3.fromRGB(60, 60, 80),   -- Lighter background
    BackgroundDark = Color3.fromRGB(30, 30, 45),    -- Darker background
    
    -- Text colors
    Text = Color3.fromRGB(240, 240, 255),       -- Primary text
    TextSecondary = Color3.fromRGB(180, 180, 200), -- Secondary text
    TextDisabled = Color3.fromRGB(120, 120, 140), -- Disabled text
    
    -- Button colors
    ButtonDefault = Color3.fromRGB(60, 60, 80),  -- Default button
    ButtonHover = Color3.fromRGB(70, 70, 90),    -- Button on hover
    ButtonActive = Color3.fromRGB(50, 50, 70),   -- Button when active/pressed
    ButtonDisabled = Color3.fromRGB(50, 50, 60), -- Disabled button
    
    -- Semantic colors
    Success = Color3.fromRGB(40, 180, 100),  -- Success/completion
    Warning = Color3.fromRGB(255, 190, 0),   -- Warning/caution
    Danger = Color3.fromRGB(220, 50, 50),    -- Error/danger
    Info = Color3.fromRGB(80, 170, 240),     -- Information
    
    -- Specialized UI colors
    HeaderBackground = Color3.fromRGB(35, 35, 55),
    CardBackground = Color3.fromRGB(50, 50, 70),
    TabActive = Color3.fromRGB(60, 100, 170),
    TabInactive = Color3.fromRGB(50, 50, 70)
}

-- Font styles (handling deprecated fonts)
UIComponents.UIStyle.Fonts = originalUIStyle and originalUIStyle.Fonts or {
    Regular = Enum.Font.Gotham,
    Bold = Enum.Font.GothamBold, 
    SemiBold = Enum.Font.GothamMedium, -- Changed from GothamSemibold which is deprecated
    Title = Enum.Font.GothamBlack,
    Subtitle = Enum.Font.GothamMedium,
    Mono = Enum.Font.RobotoMono
}

-- Text sizes
UIComponents.UIStyle.TextSizes = originalUIStyle and originalUIStyle.TextSizes or {
    Small = 12,
    Medium = 16,
    Large = 20,
    Title = 24,
    Header = 22,
    Subheader = 18
}

-- Animation settings
UIComponents.UIStyle.Animations = originalUIStyle and originalUIStyle.Animations or {
    Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    SpringIn = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    FadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
}

-- UI element sizes
UIComponents.UIStyle.Sizes = originalUIStyle and originalUIStyle.Sizes or {
    CornerRadius = UDim.new(0, 8),
    ButtonHeight = UDim2.new(0, 40),
    HeaderHeight = UDim2.new(0, 50),
    TabHeight = UDim2.new(0, 40),
    IconSize = UDim2.new(0, 24, 0, 24),
    Padding = {
        Small = 4,
        Medium = 8,
        Large = 16
    }
}

-- Z-index values
UIComponents.UIStyle.ZIndex = originalUIStyle and originalUIStyle.ZIndex or {
    Background = 1,
    Content = 10,
    Foreground = 50,
    Overlay = 100,
    Topmost = 200
}

-- IconSet Component
UIComponents.IconSet = originalIconSet or {}

-- Default asset IDs for common icons
UIComponents.IconSet.AssetIds = originalIconSet and originalIconSet.AssetIds or {
    -- Core icons - using reliable Roblox asset IDs
    Settings = "rbxassetid://3926307971",    -- Settings icon
    Close = "rbxassetid://3926307971",       -- X icon
    Menu = "rbxassetid://3926307971",        -- Menu icon
    Home = "rbxassetid://3926307971",        -- Home icon
    
    -- Feature icons - placeholder icons that always work
    Rebirth = "rbxassetid://6031090990",     -- Rebirth feature
    Alliance = "rbxassetid://6031090990",    -- Alliance feature
    StaffManagement = "rbxassetid://6031090990", -- Staff management
    Challenges = "rbxassetid://6031090990",  -- Challenges
    Tutorial = "rbxassetid://6031090990",    -- Tutorial
    GuestPass = "rbxassetid://6031090990",   -- Guest pass
    CommunityGoals = "rbxassetid://6031090990", -- Community goals
    Achievements = "rbxassetid://6031090990", -- Achievements
    
    -- Common UI icons
    Gear = "rbxassetid://3926307971",        -- Settings alternative
    Info = "rbxassetid://3926305904",        -- Information
    Warning = "rbxassetid://3926305904",     -- Warning icon
    Error = "rbxassetid://3926305904",       -- Error icon
    Check = "rbxassetid://3926305904",       -- Checkmark/success
    Play = "rbxassetid://3926307971",        -- Play button
    
    -- Additional common icons
    Coin = "rbxassetid://6026568247",        -- Money/currency icon
    Star = "rbxassetid://6031090990",        -- Star for ratings/achievements
    Trophy = "rbxassetid://6031090990",      -- Trophy for achievements
}

-- Create an icon with the specified name
function UIComponents.IconSet.createIcon(iconName, size, position)
    local iconAssetId = UIComponents.IconSet.AssetIds[iconName] or UIComponents.IconSet.AssetIds.Settings

    local icon = Instance.new("ImageLabel")
    icon.Name = iconName .. "Icon"
    icon.Size = size or UDim2.new(0, 24, 0, 24)
    icon.Position = position or UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Image = iconAssetId
    icon.ScaleType = Enum.ScaleType.Fit
    
    return icon
end

-- Add an icon to an existing button
function UIComponents.IconSet.addIconToButton(button, iconName)
    if not button then return button end
    
    local iconAssetId = UIComponents.IconSet.AssetIds[iconName] or UIComponents.IconSet.AssetIds.Settings
    
    -- Add padding to text for icon
    if button:IsA("TextButton") or button:IsA("TextLabel") then
        button.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Add padding if not already present
        if not button:FindFirstChild("UIPadding") then
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 35)
            padding.Parent = button
        end
        
        -- Create icon
        local icon = button:FindFirstChild("Icon") or Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0, 10, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = iconAssetId
        icon.Parent = button
    end
    
    return button
end

-- Check if the IconSet has a specific icon
function UIComponents.IconSet.hasIcon(iconName)
    return UIComponents.IconSet.AssetIds[iconName] ~= nil
end

-- Get the asset ID for a specific icon
function UIComponents.IconSet.getIconId(iconName)
    return UIComponents.IconSet.AssetIds[iconName] or UIComponents.IconSet.AssetIds.Settings
end

-- ButtonFactory Component
UIComponents.ButtonFactory = originalButtonFactory or {}

-- Create a standard button with hover effects
function UIComponents.ButtonFactory.createButton(text, size, position, callback, style)
    local button = Instance.new("TextButton")
    button.Name = (typeof(text) == "string" and text:gsub(" ", "") or "Button") .. "Button"
    button.Size = size or UDim2.new(0, 120, 0, 40)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BorderSizePixel = 0
    button.Text = text or "Button"
    button.Font = UIComponents.UIStyle.Fonts.Bold
    button.TextSize = UIComponents.UIStyle.TextSizes.Medium
    
    -- Set color based on style
    if style == "primary" then
        button.BackgroundColor3 = UIComponents.UIStyle.Colors.Primary
    elseif style == "danger" then
        button.BackgroundColor3 = UIComponents.UIStyle.Colors.Danger
    elseif style == "success" then
        button.BackgroundColor3 = UIComponents.UIStyle.Colors.Success
    else
        button.BackgroundColor3 = UIComponents.UIStyle.Colors.ButtonDefault
    end
    
    button.TextColor3 = Color3.new(1, 1, 1)
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add hover effects
    button.AutoButtonColor = false
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, UIComponents.UIStyle.Animations.Fast, {
            BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.15)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        local targetColor = style == "primary" and UIComponents.UIStyle.Colors.Primary 
            or style == "danger" and UIComponents.UIStyle.Colors.Danger
            or style == "success" and UIComponents.UIStyle.Colors.Success
            or UIComponents.UIStyle.Colors.ButtonDefault
            
        TweenService:Create(button, UIComponents.UIStyle.Animations.Fast, {
            BackgroundColor3 = targetColor
        }):Play()
    end)
    
    -- Connect callback
    if callback and typeof(callback) == "function" then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

-- Create a button with an icon
function UIComponents.ButtonFactory.createIconButton(iconName, text, size, position, callback, style)
    local button = UIComponents.ButtonFactory.createButton(text, size, position, callback, style)
    
    -- Add padding for icon
    button.TextXAlignment = Enum.TextXAlignment.Left
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 35)
    padding.Parent = button
    
    -- Add icon
    UIComponents.IconSet.addIconToButton(button, iconName)
    
    return button
end

-- Create a close button that follows the standard design
function UIComponents.ButtonFactory.createCloseButton(parent, position, callback)
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = position or UDim2.new(1, -10, 0, 10)
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.BackgroundColor3 = UIComponents.UIStyle.Colors.Danger
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Font = UIComponents.UIStyle.Fonts.Bold
    closeButton.TextSize = 18
    closeButton.Text = "X"
    closeButton.ZIndex = 12
    closeButton.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = closeButton

    -- Default close functionality
    local defaultCallback = function()
        if parent then
            parent.Visible = false
        end
    end
    
    -- Connect callback
    closeButton.MouseButton1Click:Connect(callback or defaultCallback)
    
    return closeButton
end

-- Create a confirm button for dialogs
function UIComponents.ButtonFactory.createConfirmButton(text, size, position, callback)
    return UIComponents.ButtonFactory.createIconButton("Check", text or "Confirm", size, position, callback, "success")
end

-- Create a cancel button for dialogs
function UIComponents.ButtonFactory.createCancelButton(text, size, position, callback)
    return UIComponents.ButtonFactory.createIconButton("Close", text or "Cancel", size, position, callback, "danger")
end

-- Create a toggle button (on/off state)
function UIComponents.ButtonFactory.createToggleButton(text, isOn, size, position, callback)
    local button = Instance.new("TextButton")
    button.Name = (typeof(text) == "string" and text:gsub(" ", "") or "Toggle") .. "ToggleButton"
    button.Size = size or UDim2.new(0, 60, 0, 30)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BorderSizePixel = 0
    button.Text = isOn and "ON" or "OFF"
    button.Font = UIComponents.UIStyle.Fonts.Bold
    button.TextSize = UIComponents.UIStyle.TextSizes.Medium
    button.TextColor3 = Color3.new(1, 1, 1)
    
    -- Set initial state
    button.BackgroundColor3 = isOn and UIComponents.UIStyle.Colors.Success or Color3.fromRGB(100, 100, 100)
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = button
    
    -- Track toggle state
    local toggleState = isOn
    
    -- Connect click handler
    button.MouseButton1Click:Connect(function()
        toggleState = not toggleState
        
        -- Update visual state
        button.Text = toggleState and "ON" or "OFF"
        button.BackgroundColor3 = toggleState and UIComponents.UIStyle.Colors.Success or Color3.fromRGB(100, 100, 100)
        
        -- Call callback with new state
        if callback then
            callback(toggleState)
        end
    end)
    
    -- Create API for the toggle button
    local api = {
        instance = button,
        getState = function()
            return toggleState
        end,
        setState = function(state)
            toggleState = state
            button.Text = toggleState and "ON" or "OFF"
            button.BackgroundColor3 = toggleState and UIComponents.UIStyle.Colors.Success or Color3.fromRGB(100, 100, 100)
        end
    }
    
    return api
end

-- DialogFactory Component
UIComponents.DialogFactory = originalDialogFactory or {}

-- Helper function to create corner rounding
local function addCorner(instance, cornerRadius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = cornerRadius or UDim.new(0, 8)
    corner.Parent = instance
    return corner
end

-- Helper function to create a modal background that closes dialog when clicking outside
local function createModalBackground(zIndex, clickCallback)
    local background = Instance.new("Frame")
    background.Name = "ModalBackground"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.BorderSizePixel = 0
    background.ZIndex = zIndex or UIComponents.UIStyle.ZIndex.Background
    
    -- Add click handler
    local button = Instance.new("TextButton")
    button.Name = "ClickHandler"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = background.ZIndex
    button.Parent = background
    
    if clickCallback then
        button.MouseButton1Click:Connect(clickCallback)
    end
    
    return background
end

-- Create a notification toast
function UIComponents.DialogFactory.createNotification(message, duration, type)
    type = type or "info"
    duration = duration or 3
    
    -- Get player GUI
    local player = Players.LocalPlayer
    if not player then return end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Determine notification color and icon based on type
    local colors = {
        info = UIComponents.UIStyle.Colors.Info,
        success = UIComponents.UIStyle.Colors.Success,
        warning = UIComponents.UIStyle.Colors.Warning,
        error = UIComponents.UIStyle.Colors.Danger
    }
    
    local iconNames = {
        info = "Info",
        success = "Check",
        warning = "Warning",
        error = "Error"
    }
    
    local backgroundColor = colors[type] or UIComponents.UIStyle.Colors.Info
    local iconName = iconNames[type] or "Info"
    
    -- Create notification container if it doesn't exist
    local notificationGui = playerGui:FindFirstChild("NotificationGui")
    if not notificationGui then
        notificationGui = Instance.new("ScreenGui")
        notificationGui.Name = "NotificationGui"
        notificationGui.ResetOnSpawn = false
        notificationGui.Parent = playerGui
        
        -- Create container to hold notifications
        local container = Instance.new("Frame")
        container.Name = "NotificationContainer"
        container.Size = UDim2.new(0, 300, 1, -20)
        container.Position = UDim2.new(1, -320, 0, 10)
        container.BackgroundTransparency = 1
        container.Parent = notificationGui
        
        -- Add layout for automatic positioning
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 10)
        layout.Parent = container
    end
    
    local container = notificationGui.NotificationContainer
    
    -- Create notification frame
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "Notification_" .. os.time()
    notificationFrame.Size = UDim2.new(1, 0, 0, 50)
    notificationFrame.BackgroundColor3 = backgroundColor
    notificationFrame.BackgroundTransparency = 0.2
    notificationFrame.LayoutOrder = #container:GetChildren() * -1  -- Newest at top
    notificationFrame.Parent = container
    
    -- Add rounded corners
    addCorner(notificationFrame, UDim.new(0, 8))
    
    -- Add icon
    local icon = UIComponents.IconSet.createIcon(iconName, UDim2.new(0, 24, 0, 24), UDim2.new(0, 12, 0.5, -12))
    icon.Parent = notificationFrame
    
    -- Message text
    local messageText = Instance.new("TextLabel")
    messageText.Name = "Message"
    messageText.Size = UDim2.new(1, -60, 1, 0)
    messageText.Position = UDim2.new(0, 48, 0, 0)
    messageText.BackgroundTransparency = 1
    messageText.Font = UIComponents.UIStyle.Fonts.Regular
    messageText.TextSize = UIComponents.UIStyle.TextSizes.Medium
    messageText.TextColor3 = Color3.new(1, 1, 1)
    messageText.TextWrapped = true
    messageText.Text = message
    messageText.TextXAlignment = Enum.TextXAlignment.Left
    messageText.TextYAlignment = Enum.TextYAlignment.Center
    messageText.Parent = notificationFrame
    
    -- Animate in
    notificationFrame.Position = UDim2.new(1, 0, 0, 0)
    TweenService:Create(
        notificationFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    ):Play()
    
    -- Destroy after duration
    task.delay(duration, function()
        -- Animate out
        local animOut = TweenService:Create(
            notificationFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 0, 0, 0)}
        )
        animOut:Play()
        
        -- Destroy after animation
        animOut.Completed:Connect(function()
            notificationFrame:Destroy()
        end)
    end)
    
    return notificationFrame
end

-- Create a message dialog
function UIComponents.DialogFactory.createMessageDialog(title, message, confirmCallback, options)
    options = options or {}
    
    -- Create ScreenGui
    local player = Players.LocalPlayer
    if not player then return end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Create the dialog UI
    local dialogGui = Instance.new("ScreenGui")
    dialogGui.Name = "MessageDialog_" .. os.time()
    dialogGui.ResetOnSpawn = false
    dialogGui.Parent = playerGui
    
    -- Create modal background if required
    if options.modal ~= false then
        local modalBackground = createModalBackground(UIComponents.UIStyle.ZIndex.Overlay, function()
            if options.closeOnOutsideClick ~= false then
                dialogGui:Destroy()
            end
        end)
        modalBackground.Parent = dialogGui
    end
    
    -- Create dialog frame
    local dialogFrame = Instance.new("Frame")
    dialogFrame.Name = "DialogFrame"
    dialogFrame.Size = UDim2.new(0, options.width or 400, 0, options.height or 250)
    dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    dialogFrame.BackgroundColor3 = UIComponents.UIStyle.Colors.Background
    dialogFrame.BorderSizePixel = 0
    dialogFrame.ZIndex = UIComponents.UIStyle.ZIndex.Foreground
    dialogFrame.Parent = dialogGui
    
    -- Add corner rounding
    addCorner(dialogFrame, UDim.new(0, 8))
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = UIComponents.UIStyle.Colors.HeaderBackground
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = UIComponents.UIStyle.ZIndex.Foreground
    titleBar.Parent = dialogFrame
    
    -- Add corner rounding to top of title bar
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = UIComponents.UIStyle.Fonts.Bold
    titleText.TextSize = UIComponents.UIStyle.TextSizes.Large
    titleText.TextColor3 = UIComponents.UIStyle.Colors.Text
    titleText.Text = title
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = UIComponents.UIStyle.ZIndex.Foreground
    titleText.Parent = titleBar
    
    -- Close button
    local closeBtn = UIComponents.ButtonFactory.createCloseButton(titleBar, UDim2.new(1, -10, 0.5, 0), function()
        dialogGui:Destroy()
    end)
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.ZIndex = UIComponents.UIStyle.ZIndex.Foreground + 1
    
    -- Message text
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -40, 0, 0)
    messageLabel.Position = UDim2.new(0, 20, 0, 60)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = UIComponents.UIStyle.Fonts.Regular
    messageLabel.TextSize = UIComponents.UIStyle.TextSizes.Medium
    messageLabel.TextColor3 = UIComponents.UIStyle.Colors.Text
    messageLabel.Text = message
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Center
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.ZIndex = UIComponents.UIStyle.ZIndex.Foreground
    messageLabel.Parent = dialogFrame
    
    -- Auto-adjust label height
    local textSize = game:GetService("TextService"):GetTextSize(
        message,
        UIComponents.UIStyle.TextSizes.Medium,
        UIComponents.UIStyle.Fonts.Regular,
        Vector2.new(messageLabel.AbsoluteSize.X, 10000)
    )
    messageLabel.Size = UDim2.new(1, -40, 0, textSize.Y)
    
    -- Confirm button
    local confirmText = options.confirmText or "OK"
    local confirmButton = UIComponents.ButtonFactory.createConfirmButton(confirmText, UDim2.new(0, 120, 0, 40), UDim2.new(0.5, -60, 1, -60), function()
        if confirmCallback then confirmCallback() end
        dialogGui:Destroy()
    end)
    confirmButton.Parent = dialogFrame
    confirmButton.ZIndex = UIComponents.UIStyle.ZIndex.Foreground
    
    -- Animate the dialog appearing
    dialogFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(
        dialogFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, options.width or 400, 0, options.height or 250)}
    ):Play()
    
    -- Helper to dispose dialog
    local dialog = {
        gui = dialogGui,
        destroy = function()
            dialogGui:Destroy()
        end
    }
    
    return dialog
end

-- Setup functions to register UI components in ClientRegistry
function UIComponents.registerWithClientRegistry(clientRegistry)
    if not clientRegistry then
        warn("[UIComponents] No ClientRegistry provided for registration")
        return false
    end
    
    -- Register style module
    clientRegistry:registerUIComponent("UIStyle", UIComponents.UIStyle)
    
    -- Register icons module
    clientRegistry:registerUIComponent("IconSet", UIComponents.IconSet)
    
    -- Register button factory
    clientRegistry:registerUIComponent("ButtonFactory", UIComponents.ButtonFactory)
    
    -- Register dialog factory
    clientRegistry:registerUIComponent("DialogFactory", UIComponents.DialogFactory)
    
    return true
end

-- Auto-add components to shared folder for easier access
local function createSharedReference(name, component)
    -- Check if it already exists
    if sharedFolder:FindFirstChild(name) then
        -- Don't replace if it's already there
        return
    end
    
    -- Create a ModuleScript
    local moduleScript = Instance.new("ModuleScript")
    moduleScript.Name = name
    moduleScript.Source = "return require(script.Parent.UIComponents)." .. name
    moduleScript.Parent = sharedFolder
    
    print("[UIComponents] Created shared reference for " .. name)
end

-- Create references for each component
createSharedReference("UIStyle", UIComponents.UIStyle)
createSharedReference("IconSet", UIComponents.IconSet)
createSharedReference("ButtonFactory", UIComponents.ButtonFactory)
createSharedReference("DialogFactory", UIComponents.DialogFactory)

-- If the original components exist, make sure they use our implementations
if sharedFolder:FindFirstChild("UIStyle") and sharedFolder.UIStyle ~= UIComponents.UIStyle then
    print("[UIComponents] Ensuring UIStyle module uses consolidated components")
    UIComponents.UIStyle = originalUIStyle or UIComponents.UIStyle
end

if sharedFolder:FindFirstChild("IconSet") and sharedFolder.IconSet ~= UIComponents.IconSet then
    print("[UIComponents] Ensuring IconSet module uses consolidated components")
    UIComponents.IconSet = originalIconSet or UIComponents.IconSet
end

if sharedFolder:FindFirstChild("ButtonFactory") and sharedFolder.ButtonFactory ~= UIComponents.ButtonFactory then
    print("[UIComponents] Ensuring ButtonFactory module uses consolidated components")
    UIComponents.ButtonFactory = originalButtonFactory or UIComponents.ButtonFactory
end

if sharedFolder:FindFirstChild("DialogFactory") and sharedFolder.DialogFactory ~= UIComponents.DialogFactory then
    print("[UIComponents] Ensuring DialogFactory module uses consolidated components")
    UIComponents.DialogFactory = originalDialogFactory or UIComponents.DialogFactory
end

print("[UIComponents] Module loaded successfully")
return UIComponents
