--!strict
--[[
    UIManager.luau
    
    Handles UI operations like showing/hiding, animations, and notifications.
    Provides a set of utility functions for manipulating UI elements and
    creating consistent user experiences.
    
    Features:
    - UI visibility management
    - Animation utilities (fade, slide, scale)
    - Notification system
    - Modal dialog system
    - UI state tracking
    
    Author: Updated April 26, 2025
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        warn("Invalid module script provided to requireSafely")
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
local UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))

-- Module and state variables
local UIManager = {}
local visibleUIs = {}
local activeModals = {}
local activeNotifications = {}
local notificationQueue = {}
local notificationContainers = {}
local idCounter = 0

-- Default configuration
local CONFIG = {
    modalZIndex = 10,
    notificationZIndex = 100,
    notificationDuration = 5, -- seconds
    maxNotifications = 5,
    animationDurations = {
        fast = 0.15,
        normal = 0.3,
        slow = 0.5
    }
}

--[[ Animation Functions ]]--

-- Fade in animation
function UIManager:fadeIn(instance, duration, callback)
    if not instance then return end
    
    -- Store original transparency and ZIndex values
    local originalTransparency = {}
    local originalZIndex = {}
    
    -- Apply to instance and all descendants
    local function applyFade(obj)
        if obj:IsA("GuiObject") then
            originalTransparency[obj] = obj.BackgroundTransparency
            originalZIndex[obj] = obj.ZIndex
            
            obj.BackgroundTransparency = 1
            obj.ZIndex = obj.ZIndex + 1 -- Ensure it appears above other elements
            
            -- Handle special cases
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                obj.TextTransparency = 1
            end
            
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                obj.ImageTransparency = 1
            end
        end
        
        -- Apply to children
        for _, child in ipairs(obj:GetChildren()) do
            applyFade(child)
        end
    end
    
    -- Apply initial transparent state
    applyFade(instance)
    
    -- Make the instance visible
    instance.Visible = true
    
    -- Create tweens for all affected objects
    local tweens = {}
    
    local function createTweens(obj)
        if obj:IsA("GuiObject") then
            -- Determine original transparency
            local origTransparency = originalTransparency[obj] or 0
            
            -- Create background tween
            local tweenInfo = TweenInfo.new(duration or CONFIG.animationDurations.normal, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            local backgroundTween = TweenService:Create(obj, tweenInfo, {
                BackgroundTransparency = origTransparency
            })
            
            table.insert(tweens, backgroundTween)
            
            -- Handle special cases
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                local textTween = TweenService:Create(obj, tweenInfo, {
                    TextTransparency = 0
                })
                table.insert(tweens, textTween)
            end
            
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                local imageTween = TweenService:Create(obj, tweenInfo, {
                    ImageTransparency = 0
                })
                table.insert(tweens, imageTween)
            end
        end
        
        -- Create tweens for children
        for _, child in ipairs(obj:GetChildren()) do
            createTweens(child)
        end
    end
    
    -- Create all the tweens
    createTweens(instance)
    
    -- Play all tweens
    for _, tween in ipairs(tweens) do
        tween:Play()
    end
    
    -- Wait for tweens to complete
    if #tweens > 0 then
        tweens[1].Completed:Connect(function()
            -- Restore original ZIndex values
            for obj, zindex in pairs(originalZIndex) do
                if obj and obj:IsA("GuiObject") then
                    obj.ZIndex = zindex
                end
            end
            
            -- Call the callback if provided
            if callback then
                callback()
            end
        end)
    else
        -- No tweens were created, call callback immediately
        if callback then
            callback()
        end
    end
end

-- Fade out animation
function UIManager:fadeOut(instance, duration, callback)
    if not instance then return end
    
    -- Create tweens for all affected objects
    local tweens = {}
    
    local function createTweens(obj)
        if obj:IsA("GuiObject") then
            -- Create background tween
            local tweenInfo = TweenInfo.new(duration or CONFIG.animationDurations.normal, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            local backgroundTween = TweenService:Create(obj, tweenInfo, {
                BackgroundTransparency = 1
            })
            
            table.insert(tweens, backgroundTween)
            
            -- Handle special cases
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                local textTween = TweenService:Create(obj, tweenInfo, {
                    TextTransparency = 1
                })
                table.insert(tweens, textTween)
            end
            
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                local imageTween = TweenService:Create(obj, tweenInfo, {
                    ImageTransparency = 1
                })
                table.insert(tweens, imageTween)
            end
        end
        
        -- Create tweens for children
        for _, child in ipairs(obj:GetChildren()) do
            createTweens(child)
        end
    end
    
    -- Create all the tweens
    createTweens(instance)
    
    -- Play all tweens
    for _, tween in ipairs(tweens) do
        tween:Play()
    end
    
    -- Wait for tweens to complete
    if #tweens > 0 then
        tweens[1].Completed:Connect(function()
            -- Hide the instance
            instance.Visible = false
            
            -- Call the callback if provided
            if callback then
                callback()
            end
        end)
    else
        -- No tweens were created, hide immediately and call callback
        instance.Visible = false
        
        if callback then
            callback()
        end
    end
end

-- Slide in animation
function UIManager:slideIn(instance, direction, duration, callback)
    if not instance then return end
    
    direction = direction or "right"
    duration = duration or CONFIG.animationDurations.normal
    
    -- Store original position
    local originalPosition = instance.Position
    
    -- Determine start position based on direction
    local startPosition
    if direction == "right" then
        startPosition = UDim2.new(1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
    elseif direction == "left" then
        startPosition = UDim2.new(-1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
    elseif direction == "top" then
        startPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, -1, 0)
    elseif direction == "bottom" then
        startPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, 0)
    else
        warn("Invalid slide direction: " .. direction)
        startPosition = originalPosition
    end
    
    -- Set initial position
    instance.Position = startPosition
    
    -- Make instance visible
    instance.Visible = true
    
    -- Create and play tween
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, {
        Position = originalPosition
    })
    
    tween:Play()
    
    -- Wait for tween to complete
    tween.Completed:Connect(function()
        -- Call the callback if provided
        if callback then
            callback()
        end
    end)
end

-- Slide out animation
function UIManager:slideOut(instance, direction, duration, callback)
    if not instance then return end
    
    direction = direction or "right"
    duration = duration or CONFIG.animationDurations.normal
    
    -- Store original position
    local originalPosition = instance.Position
    
    -- Determine end position based on direction
    local endPosition
    if direction == "right" then
        endPosition = UDim2.new(1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
    elseif direction == "left" then
        endPosition = UDim2.new(-1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
    elseif direction == "top" then
        endPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, -1, 0)
    elseif direction == "bottom" then
        endPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, 0)
    else
        warn("Invalid slide direction: " .. direction)
        endPosition = originalPosition
    end
    
    -- Create and play tween
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    local tween = TweenService:Create(instance, tweenInfo, {
        Position = endPosition
    })
    
    tween:Play()
    
    -- Wait for tween to complete
    tween.Completed:Connect(function()
        -- Hide the instance
        instance.Visible = false
        
        -- Reset position to original
        instance.Position = originalPosition
        
        -- Call the callback if provided
        if callback then
            callback()
        end
    end)
end

-- Scale in animation
function UIManager:scaleIn(instance, duration, callback)
    if not instance then return end
    
    duration = duration or CONFIG.animationDurations.normal
    
    -- Store original size and position
    local originalSize = instance.Size
    local originalPosition = instance.Position
    
    -- Set initial state
    instance.Size = UDim2.new(0, 0, 0, 0)
    instance.Position = UDim2.new(0.5, 0, 0.5, 0)
    instance.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Make instance visible
    instance.Visible = true
    
    -- Create and play tween
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, {
        Size = originalSize,
        Position = originalPosition
    })
    
    tween:Play()
    
    -- Wait for tween to complete
    tween.Completed:Connect(function()
        -- Call the callback if provided
        if callback then
            callback()
        end
    end)
end

-- Scale out animation
function UIManager:scaleOut(instance, duration, callback)
    if not instance then return end
    
    duration = duration or CONFIG.animationDurations.normal
    
    -- Store original size and position for restoration later
    local originalSize = instance.Size
    local originalPosition = instance.Position
    local originalAnchorPoint = instance.AnchorPoint
    
    -- Set anchor point to center for scaling animation
    instance.AnchorPoint = Vector2.new(0.5, 0.5)
    local centerPosition = UDim2.new(0.5, 0, 0.5, 0)
    
    -- Create and play tween
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    local tween = TweenService:Create(instance, tweenInfo, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = centerPosition
    })
    
    tween:Play()
    
    -- Wait for tween to complete
    tween.Completed:Connect(function()
        -- Hide the instance
        instance.Visible = false
        
        -- Reset to original properties
        instance.Size = originalSize
        instance.Position = originalPosition
        instance.AnchorPoint = originalAnchorPoint
        
        -- Call the callback if provided
        if callback then
            callback()
        end
    end)
end

--[[ UI Management Functions ]]--

-- Show a UI with animation
function UIManager:showUI(name, component, animationType, duration, ...)
    if not component then
        warn("Cannot show UI without component")
        return false
    end
    
    -- Check if component has a show method
    if not component.show then
        warn("Component does not have a show method")
        return false
    end
    
    -- Call the component's show method
    local result = component:show(...)
    
    -- If the component returned an instance, animate it
    if result and typeof(result) == "Instance" then
        -- Apply animation based on type
        if animationType == "fade" then
            self:fadeIn(result, duration)
        elseif animationType == "slide" then
            self:slideIn(result, "right", duration)
        elseif animationType == "scale" then
            self:scaleIn(result, duration)
        end
        
        -- Store the instance for later reference
        component.instance = result
    elseif component.instance then
        -- Component already has an instance, make it visible with animation
        if animationType == "fade" then
            self:fadeIn(component.instance, duration)
        elseif animationType == "slide" then
            self:slideIn(component.instance, "right", duration)
        elseif animationType == "scale" then
            self:scaleIn(component.instance, duration)
        else
            component.instance.Visible = true
        end
    end
    
    -- Mark UI as visible
    visibleUIs[name] = component
    
    return true
end

-- Hide a UI with animation
function UIManager:hideUI(name, animationType, duration, callback)
    local component = visibleUIs[name]
      if not component then
        if callback then 
            callback() 
        end
        return false
    end
    
    -- Check if component has an instance or hide method
    if component.instance then
        -- Apply animation based on type
        if animationType == "fade" then
            self:fadeOut(component.instance, duration, function()
                -- Call the component's hide method
                if component.hide then
                    component:hide()
                end
                
                -- Call the callback if provided
                if callback then
                    callback()
                end
            end)
        elseif animationType == "slide" then
            self:slideOut(component.instance, "right", duration, function()
                -- Call the component's hide method
                if component.hide then
                    component:hide()
                end
                
                -- Call the callback if provided
                if callback then
                    callback()
                end
            end)
        elseif animationType == "scale" then
            self:scaleOut(component.instance, duration, function()
                -- Call the component's hide method
                if component.hide then
                    component:hide()
                end
                
                -- Call the callback if provided
                if callback then
                    callback()
                end
            end)
        else
            -- No animation, just hide
            component.instance.Visible = false
            
            -- Call the component's hide method
            if component.hide then
                component:hide()
            end
            
            -- Call the callback if provided
            if callback then
                callback()
            end
        end
    elseif component.hide then
        -- No instance but has hide method
        component:hide()
        
        -- Call the callback if provided
        if callback then
            callback()
        end    else
        -- No instance or hide method
        if callback then 
            callback() 
        end
        return false
    end
    
    -- Mark UI as hidden
    visibleUIs[name] = nil
    
    return true
end

-- Check if a UI is visible
function UIManager:isUIVisible(name)
    return visibleUIs[name] ~= nil
end

-- Hide all UIs
function UIManager:hideAllUIs(animationType, duration)
    local hiddenCount = 0
    
    for name, _ in pairs(visibleUIs) do
        if self:hideUI(name, animationType, duration) then
            hiddenCount = hiddenCount + 1
        end
    end
    
    return hiddenCount
end

--[[ Notification Functions ]]--

-- Get or create notification container
local function getNotificationContainer()
    -- Check if container already exists
    for _, container in pairs(notificationContainers) do
        if container.Parent then
            return container
        end
    end
    
    -- Create new container
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationContainer"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Name = "NotificationsFrame"
    frame.Size = UDim2.new(0, 300, 1, -20)
    frame.Position = UDim2.new(1, -320, 0, 10)
    frame.BackgroundTransparency = 1
    frame.Parent = screenGui
    
    -- Create layout for notifications
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = frame
    
    -- Store the container
    table.insert(notificationContainers, frame)
    
    return frame
end

-- Create a notification
function UIManager:createNotification(options)
    -- Generate unique ID
    idCounter = idCounter + 1
    local id = "notification_" .. idCounter
    
    -- Default options
    options = options or {}
    options.title = options.title or "Notification"
    options.message = options.message or ""
    options.type = options.type or "info"  -- info, success, warning, error
    options.duration = options.duration or CONFIG.notificationDuration
    options.closable = options.closable ~= false  -- true by default
    
    -- Create notification instance
    local notification = {}
    notification.id = id
    notification.options = options
    
    -- Add to queue if too many active notifications
    if #activeNotifications >= CONFIG.maxNotifications then
        table.insert(notificationQueue, notification)
        return notification
    end
    
    -- Create UI elements
    local container = getNotificationContainer()
    
    local frame = Instance.new("Frame")
    frame.Name = id
    frame.Size = UDim2.new(1, -20, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.LayoutOrder = idCounter
    frame.Parent = container
    
    -- Get theme-appropriate color
    local themeColor
    if UIStyle then
        if options.type == "success" then
            themeColor = UIStyle:getColor("Success")
        elseif options.type == "warning" then
            themeColor = UIStyle:getColor("Warning")
        elseif options.type == "error" then
            themeColor = UIStyle:getColor("Error")
        else -- info
            themeColor = UIStyle:getColor("Primary")
        end
    else
        -- Fallback colors
        if options.type == "success" then
            themeColor = Color3.fromRGB(46, 204, 113)
        elseif options.type == "warning" then
            themeColor = Color3.fromRGB(230, 126, 34)
        elseif options.type == "error" then
            themeColor = Color3.fromRGB(231, 76, 60)
        else -- info
            themeColor = Color3.fromRGB(52, 152, 219)
        end
    end
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Add accent border on left
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BackgroundColor3 = themeColor
    accent.BorderSizePixel = 0
    accent.Parent = frame
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -50, 0, 24)
    title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = options.title
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    -- Add message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -28, 1, -40)
    message.Position = UDim2.new(0, 14, 0, 32)
    message.BackgroundTransparency = 1
    message.Text = options.message
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.Font = Enum.Font.Gotham
    message.TextSize = 14
    message.TextWrapped = true
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextYAlignment = Enum.TextYAlignment.Top
    message.Parent = frame
    
    -- Add close button if closable
    if options.closable then
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Size = UDim2.new(0, 24, 0, 24)
        closeButton.Position = UDim2.new(1, -28, 0, 8)
        closeButton.BackgroundTransparency = 1
        closeButton.Text = "✕"
        closeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        closeButton.Font = Enum.Font.GothamBold
        closeButton.TextSize = 16
        closeButton.Parent = frame
        
        -- Close button hover effect
        closeButton.MouseEnter:Connect(function()
            closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        
        closeButton.MouseLeave:Connect(function()
            closeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        end)
        
        -- Close button click handler
        closeButton.MouseButton1Click:Connect(function()
            self:closeNotification(id)
        end)
    end
    
    -- Store notification in active list
    table.insert(activeNotifications, {
        id = id,
        instance = frame,
        options = options,
        timeCreated = os.time()
    })
    
    -- Show with animation
    frame.Position = UDim2.new(1, 0, 0, 0)
    frame.Visible = true
    
    -- Create and play animation
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(frame, tweenInfo, {
        Position = UDim2.new(0, 0, 0, 0)
    })
    
    tween:Play()
    
    -- Auto-close after duration if specified
    if options.duration > 0 then
        task.delay(options.duration, function()
            self:closeNotification(id)
        end)
    end
    
    return notification
end

-- Close a notification
function UIManager:closeNotification(id)
    -- Find the notification in active list
    local index = nil
    local notification = nil
    
    for i, notif in ipairs(activeNotifications) do
        if notif.id == id then
            index = i
            notification = notif
            break
        end
    end
    
    if not notification then
        return false
    end
    
    -- Animate close
    local frame = notification.instance
    
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    local tween = TweenService:Create(frame, tweenInfo, {
        Position = UDim2.new(1, 0, 0, 0)
    })
    
    tween:Play()
    
    -- Remove from active list after animation
    tween.Completed:Connect(function()
        -- Remove from active notifications
        if index then
            table.remove(activeNotifications, index)
        end
        
        -- Destroy instance
        frame:Destroy()
        
        -- Show next notification from queue if any
        if #notificationQueue > 0 then
            local nextNotification = table.remove(notificationQueue, 1)
            self:createNotification(nextNotification.options)
        end
    end)
    
    return true
end

-- Close all notifications
function UIManager:closeAllNotifications()
    local closedCount = 0
    
    for _, notification in ipairs(activeNotifications) do
        if self:closeNotification(notification.id) then
            closedCount = closedCount + 1
        end
    end
    
    -- Clear the queue
    notificationQueue = {}
    
    return closedCount
end

--[[ Modal Dialog Functions ]]--

-- Create a modal dialog
function UIManager:createModal(options)
    -- Generate unique ID
    idCounter = idCounter + 1
    local id = "modal_" .. idCounter
    
    -- Default options
    options = options or {}
    options.title = options.title or "Dialog"
    options.content = options.content or ""
    options.buttons = options.buttons or {
        {
            text = "OK",
            style = "primary",
            callback = function() end
        }
    }
    options.closable = options.closable ~= false  -- true by default
    options.width = options.width or 400
    options.height = options.height or 300
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = id
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Create background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.ZIndex = CONFIG.modalZIndex
    overlay.Parent = screenGui
    
    -- Create modal frame
    local modalFrame = Instance.new("Frame")
    modalFrame.Name = "ModalFrame"
    modalFrame.Size = UDim2.new(0, options.width, 0, options.height)
    modalFrame.Position = UDim2.new(0.5, -options.width/2, 0.5, -options.height/2)
    modalFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    modalFrame.BorderSizePixel = 0
    modalFrame.ZIndex = CONFIG.modalZIndex + 1
    modalFrame.Parent = screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = modalFrame
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = CONFIG.modalZIndex + 2
    titleBar.Parent = modalFrame
    
    -- Add corner radius to title bar
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    -- Add title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = options.title
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = CONFIG.modalZIndex + 3
    titleText.Parent = titleBar
    
    -- Add close button if closable
    if options.closable then
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Size = UDim2.new(0, 30, 0, 30)
        closeButton.Position = UDim2.new(1, -35, 0, 5)
        closeButton.BackgroundTransparency = 1
        closeButton.Text = "✕"
        closeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        closeButton.Font = Enum.Font.GothamBold
        closeButton.TextSize = 18
        closeButton.ZIndex = CONFIG.modalZIndex + 3
        closeButton.Parent = titleBar
        
        -- Close button hover effect
        closeButton.MouseEnter:Connect(function()
            closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        
        closeButton.MouseLeave:Connect(function()
            closeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        end)
        
        -- Close button click handler
        closeButton.MouseButton1Click:Connect(function()
            self:closeModal(id)
        end)
    end
    
    -- Create content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -30, 1, -110)
    contentArea.Position = UDim2.new(0, 15, 0, 50)
    contentArea.BackgroundTransparency = 1
    contentArea.ZIndex = CONFIG.modalZIndex + 2
    contentArea.Parent = modalFrame
    
    -- Add content (handle different content types)
    if typeof(options.content) == "string" then
        -- Text content
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = options.content
        textLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextSize = 16
        textLabel.TextWrapped = true
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextYAlignment = Enum.TextYAlignment.Top
        textLabel.ZIndex = CONFIG.modalZIndex + 3
        textLabel.Parent = contentArea
    elseif typeof(options.content) == "Instance" then
        -- Instance content
        options.content.Parent = contentArea
    elseif typeof(options.content) == "function" then
        -- Function that returns content
        local success, result = pcall(options.content, contentArea)
        
        if not success then
            warn("Error creating modal content: " .. tostring(result))
        end
    end
    
    -- Create button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -30, 0, 40)
    buttonContainer.Position = UDim2.new(0, 15, 1, -50)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.ZIndex = CONFIG.modalZIndex + 2
    buttonContainer.Parent = modalFrame
    
    -- Add buttons
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonContainer
    
    -- Create buttons
    for i, buttonInfo in ipairs(options.buttons) do
        local button = Instance.new("TextButton")
        button.Name = buttonInfo.text
        button.Size = UDim2.new(0, 100, 0, 35)
        button.BackgroundColor3 = self:getButtonColor(buttonInfo.style)
        button.BorderSizePixel = 0
        button.Text = buttonInfo.text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 14
        button.ZIndex = CONFIG.modalZIndex + 3
        button.LayoutOrder = i
        button.Parent = buttonContainer
        
        -- Add corner radius to button
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- Button hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = self:getButtonColor(buttonInfo.style, 0.8)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = self:getButtonColor(buttonInfo.style)
        end)
        
        -- Button click handler
        button.MouseButton1Click:Connect(function()
            -- Close modal first
            self:closeModal(id)
            
            -- Call button callback
            if buttonInfo.callback then
                buttonInfo.callback()
            end
        end)
    end
    
    -- Store modal in active list
    local modal = {
        id = id,
        instance = screenGui,
        options = options
    }
    
    table.insert(activeModals, modal)
    
    -- Animate appearance
    modalFrame.Size = UDim2.new(0, options.width * 0.8, 0, options.height * 0.8)
    modalFrame.Position = UDim2.new(0.5, -options.width * 0.4, 0.5, -options.height * 0.4)
    overlay.BackgroundTransparency = 1
    
    -- Create and play animations
    local frameTween = TweenService:Create(
        modalFrame, 
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {
            Size = UDim2.new(0, options.width, 0, options.height),
            Position = UDim2.new(0.5, -options.width/2, 0.5, -options.height/2)
        }
    )
    
    local overlayTween = TweenService:Create(
        overlay,
        TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {
            BackgroundTransparency = 0.5
        }
    )
    
    frameTween:Play()
    overlayTween:Play()
    
    return modal
end

-- Close a modal dialog
function UIManager:closeModal(id)
    -- Find the modal in active list
    local index = nil
    local modal = nil
    
    for i, m in ipairs(activeModals) do
        if m.id == id then
            index = i
            modal = m
            break
        end
    end
    
    if not modal then
        return false
    end
    
    -- Get references to components
    local screenGui = modal.instance
    local modalFrame = screenGui.ModalFrame
    local overlay = screenGui.Overlay
    local options = modal.options
    
    -- Create and play animations
    local frameTween = TweenService:Create(
        modalFrame, 
        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
        {
            Size = UDim2.new(0, options.width * 0.8, 0, options.height * 0.8),
            Position = UDim2.new(0.5, -options.width * 0.4, 0.5, -options.height * 0.4)
        }
    )
    
    local overlayTween = TweenService:Create(
        overlay,
        TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
        {
            BackgroundTransparency = 1
        }
    )
    
    frameTween:Play()
    overlayTween:Play()
    
    -- Remove from active list after animation
    overlayTween.Completed:Connect(function()
        -- Remove from active modals
        if index then
            table.remove(activeModals, index)
        end
        
        -- Destroy instance
        screenGui:Destroy()
    end)
    
    return true
end

-- Close all modals
function UIManager:closeAllModals()
    local closedCount = 0
    
    for _, modal in ipairs(activeModals) do
        if self:closeModal(modal.id) then
            closedCount = closedCount + 1
        end
    end
    
    return closedCount
end

-- Get button color based on style
function UIManager:getButtonColor(style, multiplier)
    multiplier = multiplier or 1
    
    if UIStyle then
        local baseColor
          local colorMap = {
            primary = "Primary",
            secondary = "Secondary",
            danger = "Error",
            success = "Success",
            warning = "Warning"
        }
        
        -- Get the appropriate color or default to Primary
        local colorName = colorMap[style] or "Primary"
        baseColor = UIStyle:getColor(colorName)
        
        if multiplier ~= 1 then
            return baseColor:Lerp(Color3.new(1, 1, 1), 1 - multiplier)
        else
            return baseColor
        end
    else
        -- Fallback colors
        if style == "primary" then
            return Color3.fromRGB(114, 137, 218):Lerp(Color3.new(1, 1, 1), 1 - multiplier)
        elseif style == "secondary" then
            return Color3.fromRGB(50, 53, 59):Lerp(Color3.new(1, 1, 1), 1 - multiplier)
        elseif style == "danger" then
            return Color3.fromRGB(231, 76, 60):Lerp(Color3.new(1, 1, 1), 1 - multiplier)
        elseif style == "success" then
            return Color3.fromRGB(46, 204, 113):Lerp(Color3.new(1, 1, 1), 1 - multiplier)
        elseif style == "warning" then
            return Color3.fromRGB(230, 126, 34):Lerp(Color3.new(1, 1, 1), 1 - multiplier)
        else
            return Color3.fromRGB(114, 137, 218):Lerp(Color3.new(1, 1, 1), 1 - multiplier)
        end
    end
end

--[[ Initialization Function ]]--

function UIManager:initialize()
    -- Set up notification cleanup timer
    task.spawn(function()
        while true do
            task.wait(1)
              -- Check for expired notifications
            local now = os.time()
            for _, notification in ipairs(activeNotifications) do
                local elapsed = now - notification.timeCreated
                
                -- Check if notification has expired
                if notification.options.duration > 0 and elapsed >= notification.options.duration then
                    self:closeNotification(notification.id)
                end
            end
        end
    end)
    
    return true
end

-- Return the module
return UIManager
