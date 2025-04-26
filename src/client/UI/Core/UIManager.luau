--!strict
--[[
    UIManager.luau
    
    Central manager for UI operations including showing/hiding elements,
    animations, notifications, and modal dialogs.
    
    Features:
    - Unified show/hide functionality
    - Consistent animation system
    - Notification system
    - Modal dialog management
    - UI state tracking
    
    Author: Updated April 26, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        warn("Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find paths to important folders
local srcFolder = ReplicatedStorage:FindFirstChild("src") 
if not srcFolder then
    error("Source folder not found")
    return
end

local sharedFolder = srcFolder:FindFirstChild("shared")
if not sharedFolder then
    error("Shared folder not found")
    return
end

local clientFolder = srcFolder:FindFirstChild("client")
local clientUIFolder = clientFolder and clientFolder:FindFirstChild("UI")
local uiCoreFolder = clientUIFolder and clientUIFolder:FindFirstChild("Core")

-- Required modules
local UIRegistry = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIRegistry"))

-- Create fallbacks for critical dependencies
if not UIRegistry then
    warn("UIRegistry module not found, using fallback implementation")
    UIRegistry = {
        getComponent = function(_, name)
            return nil
        end,
        registerComponent = function(_, name, component)
            return true
        end
    }
end

-- Module and state variables
local UIManager = {}
local activeUIs = {}
local notifications = {}
local activeModals = {}
local animationQueue = {}
local isProcessingAnimation = false

-- UI Style fallback (normally would be loaded from a shared module)
local UIStyle = {
    Colors = {
        Primary = Color3.fromRGB(0, 120, 215),
        Secondary = Color3.fromRGB(45, 45, 45),
        Background = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(255, 255, 255),
        TextDisabled = Color3.fromRGB(150, 150, 150),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(230, 126, 34),
        Error = Color3.fromRGB(231, 76, 60)
    },
    Fonts = {
        Regular = Enum.Font.Gotham,
        Bold = Enum.Font.GothamBold,
        Light = Enum.Font.GothamMedium
    },
    Animations = {
        Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    }
}

-- Configuration
local CONFIG = {
    notificationDuration = 3, -- Default notification duration in seconds
    maxNotifications = 5, -- Maximum number of notifications shown simultaneously
    notificationOffset = 10, -- Spacing between notifications
    notificationWidth = 300, -- Width of notification
    notificationHeight = 80, -- Height of notification
    modalBackgroundTransparency = 0.5 -- Transparency of modal background overlay
}

--[[ Animation Functions ]]--

-- Process animation queue (one at a time to avoid conflicts)
local function processAnimationQueue()
    if isProcessingAnimation or #animationQueue == 0 then
        return
    end
    
    isProcessingAnimation = true
    
    local item = table.remove(animationQueue, 1)
    local func = item.func
    
    -- Call animation function
    local result = func()
    
    -- If it's a promise or yields, handle it
    if typeof(result) == "function" then
        -- It returned a callback function to run when done
        result(function()
            isProcessingAnimation = false
            processAnimationQueue()
        end)
    else
        -- It completed synchronously
        task.delay(item.duration or 0.3, function()
            isProcessingAnimation = false
            processAnimationQueue()
        end)
    end
end

-- Queue an animation
local function queueAnimation(func, duration)
    table.insert(animationQueue, {
        func = func,
        duration = duration
    })
    
    if not isProcessingAnimation then
        processAnimationQueue()
    end
end

-- Fade in animation
function UIManager:fadeIn(instance, duration, callback)
    if not instance then
        if callback then callback() end
        return
    end
    
    duration = duration or 0.3
    
    queueAnimation(function()
        instance.Visible = true
        instance.BackgroundTransparency = 1
        
        -- Find all text labels and set them transparent
        local textLabels = {}
        local function findTextObjects(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    table.insert(textLabels, child)
                    child.TextTransparency = 1
                elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                    table.insert(textLabels, child)
                    child.ImageTransparency = 1
                end
                
                findTextObjects(child)
            end
        end
        
        findTextObjects(instance)
        
        -- Create tweens
        local backgroundTween = TweenService:Create(
            instance,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 0 }
        )
        
        local textTweens = {}
        for _, textObject in ipairs(textLabels) do
            if textObject:IsA("TextLabel") or textObject:IsA("TextButton") or textObject:IsA("TextBox") then
                table.insert(textTweens, TweenService:Create(
                    textObject,
                    TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { TextTransparency = 0 }
                ))
            elseif textObject:IsA("ImageLabel") or textObject:IsA("ImageButton") then
                table.insert(textTweens, TweenService:Create(
                    textObject,
                    TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { ImageTransparency = 0 }
                ))
            end
        end
        
        -- Play tweens
        backgroundTween:Play()
        for _, tween in ipairs(textTweens) do
            tween:Play()
        end
        
        -- Return completion callback
        return function(done)
            backgroundTween.Completed:Connect(function()
                if callback then callback() end
                if done then done() end
            end)
        end
    end, duration)
end

-- Fade out animation
function UIManager:fadeOut(instance, duration, callback)
    if not instance then
        if callback then callback() end
        return
    end
    
    duration = duration or 0.3
    
    queueAnimation(function()
        if not instance.Visible then
            if callback then callback() end
            return
        end
        
        -- Find all text labels
        local textLabels = {}
        local function findTextObjects(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    table.insert(textLabels, child)
                elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                    table.insert(textLabels, child)
                end
                
                findTextObjects(child)
            end
        end
        
        findTextObjects(instance)
        
        -- Create tweens
        local backgroundTween = TweenService:Create(
            instance,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 }
        )
        
        local textTweens = {}
        for _, textObject in ipairs(textLabels) do
            if textObject:IsA("TextLabel") or textObject:IsA("TextButton") or textObject:IsA("TextBox") then
                table.insert(textTweens, TweenService:Create(
                    textObject,
                    TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { TextTransparency = 1 }
                ))
            elseif textObject:IsA("ImageLabel") or textObject:IsA("ImageButton") then
                table.insert(textTweens, TweenService:Create(
                    textObject,
                    TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { ImageTransparency = 1 }
                ))
            end
        end
        
        -- Play tweens
        backgroundTween:Play()
        for _, tween in ipairs(textTweens) do
            tween:Play()
        end
        
        -- Return completion callback
        return function(done)
            backgroundTween.Completed:Connect(function()
                instance.Visible = false
                if callback then callback() end
                if done then done() end
            end)
        end
    end, duration)
end

-- Scale in animation
function UIManager:scaleIn(instance, duration, callback)
    if not instance then
        if callback then callback() end
        return
    end
    
    duration = duration or 0.3
    
    queueAnimation(function()
        instance.Visible = true
        instance.Size = UDim2.new(
            instance.Size.X.Scale, 0,
            instance.Size.Y.Scale, 0
        )
        
        -- Create tween
        local sizeTween = TweenService:Create(
            instance,
            TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = UDim2.new(
                instance.Size.X.Scale, instance.Size.X.Offset,
                instance.Size.Y.Scale, instance.Size.Y.Offset
            )}
        )
        
        -- Play tween
        sizeTween:Play()
        
        -- Return completion callback
        return function(done)
            sizeTween.Completed:Connect(function()
                if callback then callback() end
                if done then done() end
            end)
        end
    end, duration)
end

-- Scale out animation
function UIManager:scaleOut(instance, duration, callback)
    if not instance then
        if callback then callback() end
        return
    end
    
    duration = duration or 0.3
    
    queueAnimation(function()
        -- Store original size
        local originalSize = instance.Size
        
        -- Create tween
        local sizeTween = TweenService:Create(
            instance,
            TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            { Size = UDim2.new(
                originalSize.X.Scale, 0,
                originalSize.Y.Scale, 0
            )}
        )
        
        -- Play tween
        sizeTween:Play()
        
        -- Return completion callback
        return function(done)
            sizeTween.Completed:Connect(function()
                instance.Visible = false
                -- Restore original size
                instance.Size = originalSize
                if callback then callback() end
                if done then done() end
            end)
        end
    end, duration)
end

-- Slide in animation
function UIManager:slideIn(instance, direction, duration, callback)
    if not instance then
        if callback then callback() end
        return
    end
    
    duration = duration or 0.3
    direction = direction or "right" -- "right", "left", "top", "bottom"
    
    queueAnimation(function()
        instance.Visible = true
        
        -- Store original position
        local originalPosition = instance.Position
        
        -- Set starting position based on direction
        if direction == "right" then
            instance.Position = UDim2.new(1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
        elseif direction == "left" then
            instance.Position = UDim2.new(-1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
        elseif direction == "bottom" then
            instance.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, 0)
        else -- top
            instance.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, -1, 0)
        end
        
        -- Create tween
        local positionTween = TweenService:Create(
            instance,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = originalPosition }
        )
        
        -- Play tween
        positionTween:Play()
        
        -- Return completion callback
        return function(done)
            positionTween.Completed:Connect(function()
                if callback then callback() end
                if done then done() end
            end)
        end
    end, duration)
end

-- Slide out animation
function UIManager:slideOut(instance, direction, duration, callback)
    if not instance then
        if callback then callback() end
        return
    end
    
    duration = duration or 0.3
    direction = direction or "right" -- "right", "left", "top", "bottom"
    
    queueAnimation(function()
        -- Store original position
        local originalPosition = instance.Position
        
        -- Determine target position based on direction
        local targetPosition
        if direction == "right" then
            targetPosition = UDim2.new(1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
        elseif direction == "left" then
            targetPosition = UDim2.new(-1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
        elseif direction == "bottom" then
            targetPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, 0)
        else -- top
            targetPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, -1, 0)
        end
        
        -- Create tween
        local positionTween = TweenService:Create(
            instance,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = targetPosition }
        )
        
        -- Play tween
        positionTween:Play()
        
        -- Return completion callback
        return function(done)
            positionTween.Completed:Connect(function()
                instance.Visible = false
                -- Restore original position
                instance.Position = originalPosition
                if callback then callback() end
                if done then done() end
            end)
        end
    end, duration)
end

--[[ Notification Functions ]]--

-- Create notification container
local function createNotificationContainer()
    -- Check if container already exists
    local container = PlayerGui:FindFirstChild("UINotifications")
    if container then
        return container
    end
    
    -- Create new container
    container = Instance.new("ScreenGui")
    container.Name = "UINotifications"
    container.ResetOnSpawn = false
    container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    container.Parent = PlayerGui
    
    -- Create frame for notifications
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(0, CONFIG.notificationWidth, 1, 0)
    frame.Position = UDim2.new(1, -CONFIG.notificationWidth - 20, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = container
    
    -- Add layout for notifications
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, CONFIG.notificationOffset)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.Name
    layout.Parent = frame
    
    return container
end

-- Create a notification
function UIManager:createNotification(options)
    if not options or not options.message then
        warn("Cannot create notification without a message")
        return nil
    end
    
    local notificationType = options.type or "info" -- "info", "success", "warning", "error"
    local duration = options.duration or CONFIG.notificationDuration
    local title = options.title
    
    -- Get container
    local container = createNotificationContainer()
    local frame = container:FindFirstChild("NotificationFrame")
    if not frame then
        return nil
    end
    
    -- Limit number of notifications
    if #notifications >= CONFIG.maxNotifications then
        -- Remove the oldest notification
        local oldest = notifications[1]
        if oldest and oldest.instance then
            self:fadeOut(oldest.instance, 0.2, function()
                oldest.instance:Destroy()
            end)
            table.remove(notifications, 1)
        end
    end
    
    -- Create notification instance
    local notification = Instance.new("Frame")
    notification.Name = "Notification_" .. tostring(#notifications + 1)
    notification.Size = UDim2.new(1, -20, 0, CONFIG.notificationHeight)
    notification.BackgroundColor3 = getNotificationColor(notificationType)
    notification.BorderSizePixel = 0
    notification.BackgroundTransparency = 1
    notification.Visible = false
    notification.Parent = frame
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    -- Add shadow
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, -3, 0, -3)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = notification.ZIndex - 1
    shadow.Parent = notification
    
    -- Add corner radius to shadow
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 10)
    shadowCorner.Parent = shadow
    
    -- Add icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.TextColor3 = Color3.new(1, 1, 1)
    icon.Font = UIStyle.Fonts.Bold
    icon.TextSize = 24
    icon.Text = getNotificationIcon(notificationType)
    icon.TextTransparency = 1
    icon.Parent = notification
    
    -- Add title if provided
    if title then
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, -70, 0, 24)
        titleLabel.Position = UDim2.new(0, 60, 0, 10)
        titleLabel.BackgroundTransparency = 1
        titleLabel.TextColor3 = Color3.new(1, 1, 1)
        titleLabel.Font = UIStyle.Fonts.Bold
        titleLabel.TextSize = 18
        titleLabel.Text = title
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTransparency = 1
        titleLabel.Parent = notification
        
        -- Add message
        local message = Instance.new("TextLabel")
        message.Name = "Message"
        message.Size = UDim2.new(1, -70, 0, 24)
        message.Position = UDim2.new(0, 60, 0, 34)
        message.BackgroundTransparency = 1
        message.TextColor3 = Color3.new(1, 1, 1)
        message.Font = UIStyle.Fonts.Regular
        message.TextSize = 16
        message.Text = options.message
        message.TextXAlignment = Enum.TextXAlignment.Left
        message.TextTransparency = 1
        message.Parent = notification
    else
        -- Add message (centered if no title)
        local message = Instance.new("TextLabel")
        message.Name = "Message"
        message.Size = UDim2.new(1, -70, 0, 40)
        message.Position = UDim2.new(0, 60, 0.5, -20)
        message.BackgroundTransparency = 1
        message.TextColor3 = Color3.new(1, 1, 1)
        message.Font = UIStyle.Fonts.Regular
        message.TextSize = 16
        message.Text = options.message
        message.TextXAlignment = Enum.TextXAlignment.Left
        message.TextYAlignment = Enum.TextYAlignment.Center
        message.TextWrapped = true
        message.TextTransparency = 1
        message.Parent = notification
    end
    
    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -30, 0, 6)
    closeButton.BackgroundTransparency = 1
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Font = UIStyle.Fonts.Bold
    closeButton.TextSize = 18
    closeButton.Text = "×"
    closeButton.TextTransparency = 1
    closeButton.Parent = notification
    
    -- Add notification to list
    local notificationData = {
        instance = notification,
        type = notificationType,
        createdAt = os.time()
    }
    table.insert(notifications, notificationData)
    
    -- Show notification with animation
    self:fadeIn(notification, 0.25)
    
    -- Set up auto-dismiss
    task.delay(duration, function()
        -- Check if notification still exists
        if notification and notification.Parent then
            self:fadeOut(notification, 0.25, function()
                -- Remove from list
                for i, data in ipairs(notifications) do
                    if data.instance == notification then
                        table.remove(notifications, i)
                        break
                    end
                end
                
                -- Destroy instance
                notification:Destroy()
            end)
        end
    end)
    
    -- Set up close button
    closeButton.Activated:Connect(function()
        -- Check if notification still exists
        if notification and notification.Parent then
            self:fadeOut(notification, 0.25, function()
                -- Remove from list
                for i, data in ipairs(notifications) do
                    if data.instance == notification then
                        table.remove(notifications, i)
                        break
                    end
                end
                
                -- Destroy instance
                notification:Destroy()
            end)
        end
    end)
    
    return notificationData
end

-- Get notification color based on type
local function getNotificationColor(notificationType)
    if notificationType == "success" then
        return UIStyle.Colors.Success
    elseif notificationType == "warning" then
        return UIStyle.Colors.Warning
    elseif notificationType == "error" then
        return UIStyle.Colors.Error
    else -- info
        return UIStyle.Colors.Primary
    end
end

-- Get notification icon based on type
local function getNotificationIcon(notificationType)
    if notificationType == "success" then
        return "✓"
    elseif notificationType == "warning" then
        return "⚠"
    elseif notificationType == "error" then
        return "✕"
    else -- info
        return "ℹ"
    end
end

--[[ Modal Dialog Functions ]]--

-- Create a modal dialog
function UIManager:createModal(options)
    if not options then
        warn("Cannot create modal without options")
        return nil
    end
    
    -- Get container
    local container = PlayerGui:FindFirstChild("UIModals")
    if not container then
        container = Instance.new("ScreenGui")
        container.Name = "UIModals"
        container.ResetOnSpawn = false
        container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        container.Parent = PlayerGui
    end
    
    -- Create background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "ModalOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1 -- Start transparent, will fade in
    overlay.Parent = container
    
    -- Create modal frame
    local modal = Instance.new("Frame")
    modal.Name = "ModalFrame"
    modal.Size = UDim2.new(0, 400, 0, 200)
    modal.Position = UDim2.new(0.5, -200, 0.5, -100)
    modal.BackgroundColor3 = UIStyle.Colors.Background
    modal.BorderSizePixel = 0
    modal.BackgroundTransparency = 1 -- Start transparent
    modal.Parent = overlay
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = modal
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.TextColor3 = UIStyle.Colors.Text
    title.Font = UIStyle.Fonts.Bold
    title.TextSize = 24
    title.Text = options.title or "Modal Dialog"
    title.TextTransparency = 1
    title.Parent = modal
    
    -- Add message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -40, 0, 80)
    message.Position = UDim2.new(0, 20, 0, 60)
    message.BackgroundTransparency = 1
    message.TextColor3 = UIStyle.Colors.Text
    message.Font = UIStyle.Fonts.Regular
    message.TextSize = 18
    message.Text = options.message or ""
    message.TextWrapped = true
    message.TextTransparency = 1
    message.Parent = modal
    
    -- Add buttons container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -40, 0, 40)
    buttonContainer.Position = UDim2.new(0, 20, 1, -50)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = modal
    
    -- Process buttons
    local buttons = options.buttons or {
        {
            text = "OK",
            color = UIStyle.Colors.Primary
        }
    }
    
    local buttonCount = #buttons
    local buttonWidth = (buttonContainer.Size.X.Offset - ((buttonCount - 1) * 10)) / buttonCount
    
    for i, buttonInfo in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Name = "Button" .. i
        button.Size = UDim2.new(0, buttonWidth, 1, 0)
        button.Position = UDim2.new(0, (i - 1) * (buttonWidth + 10), 0, 0)
        button.BackgroundColor3 = buttonInfo.color or UIStyle.Colors.Primary
        button.BorderSizePixel = 0
        button.TextColor3 = UIStyle.Colors.Text
        button.Font = UIStyle.Fonts.Bold
        button.TextSize = 18
        button.Text = buttonInfo.text
        button.TextTransparency = 1
        button.BackgroundTransparency = 1
        button.Parent = buttonContainer
        
        -- Add corner radius to button
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- Connect callback
        button.Activated:Connect(function()
            -- Fade out modal
            self:fadeOut(overlay, 0.25, function()
                overlay:Destroy()
                
                -- Remove from active modals
                for i, activeModal in ipairs(activeModals) do
                    if activeModal == overlay then
                        table.remove(activeModals, i)
                        break
                    end
                end
                
                -- Call callback if provided
                if buttonInfo.callback then
                    buttonInfo.callback()
                end
            end)
        end)
    end
    
    -- Add modal to active list
    table.insert(activeModals, overlay)
    
    -- Show modal with animation
    self:fadeIn(overlay, 0.25, function()
        -- Set overlay to semi-transparent
        overlay.BackgroundTransparency = CONFIG.modalBackgroundTransparency
    end)
    
    return overlay
end

-- Close all modals
function UIManager:closeAllModals()
    for _, modal in ipairs(activeModals) do
        self:fadeOut(modal, 0.25, function()
            modal:Destroy()
        end)
    end
    
    activeModals = {}
end

-- Close top modal
function UIManager:closeTopModal()
    if #activeModals > 0 then
        local modal = activeModals[#activeModals]
        
        self:fadeOut(modal, 0.25, function()
            modal:Destroy()
            table.remove(activeModals)
        end)
        
        return true
    end
    
    return false
end

--[[ UI Management Functions ]]--

-- Register a UI component with the manager
function UIManager:registerUI(name, component)
    if not name or not component then
        warn("Cannot register UI without name or component")
        return false
    end
    
    -- Register with UIRegistry if available
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent(name, component)
    end
    
    return true
end

-- Show a UI by name
function UIManager:showUI(name, ...)
    local component = UIRegistry and UIRegistry.getComponent and UIRegistry:getComponent(name)
    if not component then
        warn("UI component not found: " .. name)
        return false
    end
    
    if typeof(component.show) ~= "function" then
        warn("UI component does not have a show function: " .. name)
        return false
    end
    
    -- Call show function and pass any additional arguments
    local success = component:show(...)
    
    -- Track active UI if successful
    if success then
        activeUIs[name] = true
    end
    
    return success
end

-- Hide a UI by name
function UIManager:hideUI(name)
    local component = UIRegistry and UIRegistry.getComponent and UIRegistry:getComponent(name)
    if not component then
        warn("UI component not found: " .. name)
        return false
    end
    
    if typeof(component.hide) ~= "function" then
        warn("UI component does not have a hide function: " .. name)
        return false
    end
    
    -- Call hide function
    local success = component:hide()
    
    -- Remove from active UIs if successful
    if success then
        activeUIs[name] = nil
    end
    
    return success
end

-- Toggle a UI by name
function UIManager:toggleUI(name, ...)
    if activeUIs[name] then
        return self:hideUI(name)
    else
        return self:showUI(name, ...)
    end
end

-- Check if a UI is active
function UIManager:isUIActive(name)
    return activeUIs[name] == true
end

-- Hide all active UIs
function UIManager:hideAllUIs()
    for name in pairs(activeUIs) do
        self:hideUI(name)
    end
end

-- Initialize the manager
function UIManager:initialize()
    -- Register with UIRegistry if available
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent("UIManager", self)
    end
    
    -- Set up notification container
    createNotificationContainer()
    
    return self
end

-- Initialize on module load
UIManager:initialize()

-- Return the module
return UIManager
