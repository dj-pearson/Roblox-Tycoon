--[[
    UIComponents.luau
    
    Core system for UI components and factories.
    This module provides standardized UI components and styling.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UIComponents = {}
UIComponents.initialized = false

-- Configuration constants
local UI_CONFIG = {
    COLORS = {
        PRIMARY = Color3.fromRGB(50, 120, 220),
        SECONDARY = Color3.fromRGB(220, 70, 50),
        ACCENT = Color3.fromRGB(80, 200, 120),
        BACKGROUND = Color3.fromRGB(245, 245, 245),
        TEXT_DARK = Color3.fromRGB(40, 40, 40),
        TEXT_LIGHT = Color3.fromRGB(240, 240, 240)
    },
    FONTS = {
        HEADER = Enum.Font.GothamBold,
        BODY = Enum.Font.Gotham,
        BUTTON = Enum.Font.GothamSemibold,
        HIGHLIGHT = Enum.Font.GothamBlack
    },
    CORNER_RADIUS = {
        SMALL = UDim.new(0, 4),
        MEDIUM = UDim.new(0, 8),
        LARGE = UDim.new(0, 12)
    },
    PADDING = {
        SMALL = UDim.new(0, 4),
        MEDIUM = UDim.new(0, 8),
        LARGE = UDim.new(0, 16)
    },
    ANIMATION = {
        TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
    }
}

-- Debug settings
UIComponents.DEBUG = true

-- Log a message to the output
local function log(message)
    if UIComponents.DEBUG then
        print("[UIComponents] " .. message)
    end
end

-- Get the CoreRegistry if available
local function getCoreRegistry()
    if not RunService:IsClient() then
        return nil
    end
    
    -- Try in ReplicatedStorage
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("replicatedStorage") and shared.replicatedStorage:FindFirstChild("CoreRegistryShared") then
        local success, result = pcall(function()
            return require(shared.replicatedStorage.CoreRegistryShared)
        end)
        
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Initialize the UIComponents system
function UIComponents.initialize()
    if UIComponents.initialized then
        return true
    end
    
    log("Initializing UIComponents...")
    
    -- Create UI assets folder if it doesn't exist
    local uiAssets = ReplicatedStorage:FindFirstChild("UIAssets")
    if not uiAssets then
        uiAssets = Instance.new("Folder")
        uiAssets.Name = "UIAssets"
        uiAssets.Parent = ReplicatedStorage
        log("Created UIAssets folder in ReplicatedStorage")
    end
    
    -- Register with CoreRegistry if available
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("UIComponents", UIComponents)
        log("Registered with CoreRegistry")
    else
        log("CoreRegistryShared not found, but UIComponents will still function")
    end
    
    UIComponents.initialized = true
    log("UIComponents initialized")
    
    return true
end

-- Button Factory ----------------------------------------

-- Create a styled button
function UIComponents.createButton(options)
    options = options or {}
    
    -- Create the button instance
    local button = Instance.new("TextButton")
    button.AutoButtonColor = true
    button.BackgroundColor3 = options.backgroundColor or UI_CONFIG.COLORS.PRIMARY
    button.BorderSizePixel = 0
    button.Size = options.size or UDim2.new(0, 200, 0, 50)
    button.Font = options.font or UI_CONFIG.FONTS.BUTTON
    button.TextColor3 = options.textColor or UI_CONFIG.COLORS.TEXT_LIGHT
    button.TextSize = options.textSize or 18
    button.Text = options.text or "Button"
    button.Name = options.name or "StyledButton"
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = options.cornerRadius or UI_CONFIG.CORNER_RADIUS.MEDIUM
    corner.Parent = button
    
    -- Add hover effects if requested
    if options.useHoverEffect ~= false then
        -- Original properties to restore
        local originalBackgroundColor = button.BackgroundColor3
        local originalTextColor = button.TextColor3
        local originalSize = button.Size
        
        -- Mouse enter effect
        button.MouseEnter:Connect(function()
            -- Create hover effect with animation
            local hoverTween = game:GetService("TweenService"):Create(
                button,
                UI_CONFIG.ANIMATION.TWEEN_INFO,
                {
                    BackgroundColor3 = options.hoverBackgroundColor or originalBackgroundColor:Lerp(Color3.new(1, 1, 1), 0.2),
                    TextColor3 = options.hoverTextColor or originalTextColor,
                    Size = options.hoverSize or originalSize * UDim2.new(1.05, 0, 1.05, 0)
                }
            )
            hoverTween:Play()
        end)
        
        -- Mouse leave effect
        button.MouseLeave:Connect(function()
            -- Restore original appearance
            local restoreTween = game:GetService("TweenService"):Create(
                button,
                UI_CONFIG.ANIMATION.TWEEN_INFO,
                {
                    BackgroundColor3 = originalBackgroundColor,
                    TextColor3 = originalTextColor,
                    Size = originalSize
                }
            )
            restoreTween:Play()
        end)
    end
    
    -- Add click sound if requested
    if options.useClickSound ~= false then
        local sound = Instance.new("Sound")
        sound.SoundId = options.soundId or "rbxassetid://6895079853" -- Default click sound
        sound.Volume = options.soundVolume or 0.5
        sound.Parent = button
        
        button.MouseButton1Click:Connect(function()
            sound:Play()
        end)
    end
    
    -- Set parent if provided
    if options.parent then
        button.Parent = options.parent
    end
    
    return button
end

-- Label Factory ----------------------------------------

-- Create a styled label
function UIComponents.createLabel(options)
    options = options or {}
    
    -- Create the label instance
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = options.backgroundTransparency or 1
    label.Size = options.size or UDim2.new(0, 200, 0, 50)
    label.Font = options.font or UI_CONFIG.FONTS.BODY
    label.TextColor3 = options.textColor or UI_CONFIG.COLORS.TEXT_DARK
    label.TextSize = options.textSize or 16
    label.Text = options.text or "Label"
    label.TextWrapped = options.textWrapped or true
    label.Name = options.name or "StyledLabel"
    label.TextXAlignment = options.textXAlignment or Enum.TextXAlignment.Center
    label.TextYAlignment = options.textYAlignment or Enum.TextYAlignment.Center
    
    -- Set parent if provided
    if options.parent then
        label.Parent = options.parent
    end
    
    return label
end

-- Frame Factory ----------------------------------------

-- Create a styled frame
function UIComponents.createFrame(options)
    options = options or {}
    
    -- Create the frame instance
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = options.backgroundColor or UI_CONFIG.COLORS.BACKGROUND
    frame.BorderSizePixel = 0
    frame.Size = options.size or UDim2.new(0, 400, 0, 300)
    frame.Name = options.name or "StyledFrame"
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = options.cornerRadius or UI_CONFIG.CORNER_RADIUS.MEDIUM
    corner.Parent = frame
    
    -- Add padding if requested
    if options.padded ~= false then
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = options.paddingTop or UI_CONFIG.PADDING.MEDIUM
        padding.PaddingBottom = options.paddingBottom or UI_CONFIG.PADDING.MEDIUM
        padding.PaddingLeft = options.paddingLeft or UI_CONFIG.PADDING.MEDIUM
        padding.PaddingRight = options.paddingRight or UI_CONFIG.PADDING.MEDIUM
        padding.Parent = frame
    end
    
    -- Set parent if provided
    if options.parent then
        frame.Parent = options.parent
    end
    
    return frame
end

-- Dialog Factory ----------------------------------------

-- Create a dialog box
function UIComponents.createDialog(options)
    options = options or {}
    
    -- Create container for modal
    local dialogContainer = Instance.new("ScreenGui")
    dialogContainer.Name = options.name or "Dialog"
    dialogContainer.DisplayOrder = 100
    dialogContainer.IgnoreGuiInset = true
    dialogContainer.ResetOnSpawn = false
    dialogContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create darkened background
    local background = Instance.new("Frame")
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.BorderSizePixel = 0
    background.Size = UDim2.fromScale(1, 1)
    background.ZIndex = 10
    background.Parent = dialogContainer
    
    -- Create main dialog frame
    local dialog = UIComponents.createFrame({
        size = options.size or UDim2.fromOffset(400, 250),
        backgroundColor = options.backgroundColor or UI_CONFIG.COLORS.BACKGROUND,
        cornerRadius = options.cornerRadius or UI_CONFIG.CORNER_RADIUS.LARGE,
        parent = dialogContainer
    })
    dialog.ZIndex = 11
    dialog.Position = UDim2.fromScale(0.5, 0.5)
    dialog.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Create title
    local title = UIComponents.createLabel({
        text = options.title or "Dialog",
        font = UI_CONFIG.FONTS.HEADER,
        textSize = 22,
        textColor3 = UI_CONFIG.COLORS.TEXT_DARK,
        size = UDim2.new(1, -20, 0, 40),
        position = UDim2.new(0, 10, 0, 10),
        parent = dialog
    })
    title.ZIndex = 12
    
    -- Create content area
    local content = UIComponents.createLabel({
        text = options.message or "Dialog content goes here.",
        font = UI_CONFIG.FONTS.BODY,
        textSize = 16,
        textColor3 = UI_CONFIG.COLORS.TEXT_DARK,
        size = UDim2.new(1, -40, 1, -110),
        position = UDim2.new(0, 20, 0, 60),
        parent = dialog
    })
    content.TextWrapped = true
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.ZIndex = 12
    
    -- Create close button
    local closeButton = UIComponents.createButton({
        text = options.buttonText or "OK",
        size = UDim2.new(0, 120, 0, 40),
        parent = dialog
    })
    closeButton.Position = UDim2.new(0.5, 0, 1, -60)
    closeButton.AnchorPoint = Vector2.new(0.5, 0)
    closeButton.ZIndex = 12
    
    -- Close dialog when button is clicked
    closeButton.MouseButton1Click:Connect(function()
        dialogContainer:Destroy()
        
        if options.callback and typeof(options.callback) == "function" then
            options.callback()
        end
    end)
    
    -- Add dialog to player's GUI
    if RunService:IsClient() then
        dialogContainer.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    return dialogContainer
end

-- Notification Factory ----------------------------------------

-- Create a temporary notification
function UIComponents.createNotification(options)
    options = options or {}
    
    -- Create notification container if it doesn't exist yet
    local player = Players.LocalPlayer
    local playerGui = player:FindFirstChild("PlayerGui")
    
    if not playerGui then
        log("PlayerGui not found, notification cannot be created")
        return nil
    end
    
    local notificationContainer = playerGui:FindFirstChild("NotificationContainer")
    if not notificationContainer then
        notificationContainer = Instance.new("ScreenGui")
        notificationContainer.Name = "NotificationContainer"
        notificationContainer.ResetOnSpawn = false
        notificationContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        notificationContainer.Parent = playerGui
        
        -- Create a layout for stacking notifications
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = notificationContainer
        
        -- Add padding from screen edges
        local padding = Instance.new("UIPadding")
        padding.PaddingBottom = UDim.new(0, 20)
        padding.PaddingRight = UDim.new(0, 20)
        padding.Parent = notificationContainer
    end
    
    -- Create the notification frame
    local notification = UIComponents.createFrame({
        size = UDim2.new(0, options.width or 300, 0, options.height or 80),
        backgroundColor = options.backgroundColor or UI_CONFIG.COLORS.PRIMARY,
        cornerRadius = UI_CONFIG.CORNER_RADIUS.MEDIUM,
        parent = notificationContainer
    })
    notification.BackgroundTransparency = 0.1
    notification.LayoutOrder = options.priority or 1
    
    -- Add notification content
    local title
    if options.title then
        title = UIComponents.createLabel({
            text = options.title,
            font = UI_CONFIG.FONTS.HEADER,
            textSize = 18,
            textColor3 = UI_CONFIG.COLORS.TEXT_LIGHT,
            size = UDim2.new(1, -20, 0, 24),
            position = UDim2.new(0, 10, 0, 8),
            textXAlignment = Enum.TextXAlignment.Left,
            parent = notification
        })
    end
    
    local content = UIComponents.createLabel({
        text = options.message or "Notification",
        font = UI_CONFIG.FONTS.BODY,
        textSize = 16,
        textColor3 = UI_CONFIG.COLORS.TEXT_LIGHT,
        size = UDim2.new(1, -20, title and 0, 40 or 1, -16),
        position = UDim2.new(0, 10, title and 0, 32 or 0, 8),
        textXAlignment = Enum.TextXAlignment.Left,
        textYAlignment = Enum.TextYAlignment.Top,
        parent = notification
    })
    
    -- Animate notification entering
    notification.Position = UDim2.new(1, 50, 1, 0)
    local entryTween = game:GetService("TweenService"):Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
        { Position = UDim2.new(1, 0, 1, 0) }
    )
    entryTween:Play()
    
    -- Set up automatic dismissal
    local duration = options.duration or 5 -- seconds
    task.delay(duration - 0.5, function()
        -- Fade out notification
        local exitTween = game:GetService("TweenService"):Create(
            notification,
            TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
            { Position = UDim2.new(1, 50, 1, 0), BackgroundTransparency = 1 }
        )
        exitTween:Play()
        
        task.wait(0.5)
        notification:Destroy()
    end)
    
    return notification
end

-- Client interface that's safe to expose to clients
function UIComponents:getClientInterface()
    local clientInterface = {
        createButton = self.createButton,
        createLabel = self.createLabel,
        createFrame = self.createFrame,
        createDialog = self.createDialog,
        createNotification = self.createNotification,
        UI_CONFIG = UI_CONFIG
    }
    
    return clientInterface
end

-- Provide UI constants
UIComponents.UI_CONFIG = UI_CONFIG

-- Initialize UIComponents
UIComponents.initialize()

return UIComponents
