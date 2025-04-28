--!strict
--[[
    DialogFactory.luau
    
    Factory for creating dialogs and notifications in a consistent style.
    This is part of the UI components system.
    
    Created: April 27, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to load UIStyle and other dependencies
local UIStyle, IconSet

local function loadDependencies()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then
        -- Try to load UIStyle
        local uiStyleModule = shared:FindFirstChild("UIStyle")
        if uiStyleModule then
            local success, result = pcall(function()
                return require(uiStyleModule)
            end)
            if success then
                UIStyle = result
            end
        end
        
        -- Try to load IconSet
        local iconSetModule = shared:FindFirstChild("IconSet")
        if iconSetModule then
            local success, result = pcall(function()
                return require(iconSetModule)
            end)
            if success then
                IconSet = result
            end
        end
    end
    
    -- Set defaults if not loaded
    UIStyle = UIStyle or {
        colors = {
            background = Color3.fromRGB(40, 40, 60),
            backgroundLight = Color3.fromRGB(60, 60, 80),
            backgroundDark = Color3.fromRGB(30, 30, 45),
            accent = Color3.fromRGB(80, 150, 255),
            accentLight = Color3.fromRGB(130, 180, 255),
            accentDark = Color3.fromRGB(60, 120, 200),
            text = Color3.fromRGB(240, 240, 255),
            success = Color3.fromRGB(80, 240, 120),
            warning = Color3.fromRGB(255, 200, 80),
            error = Color3.fromRGB(255, 80, 80)
        },
        fonts = {
            header = Enum.Font.GothamBold,
            body = Enum.Font.Gotham,
            button = Enum.Font.GothamMedium
        },
        fontSizes = {
            header = 20,
            body = 16,
            button = 16
        }
    }
    
    IconSet = IconSet or {
        close = "rbxassetid://8093755787",
        info = "rbxassetid://8093754900",
        warning = "rbxassetid://8093755364",
        error = "rbxassetid://8093755611",
        success = "rbxassetid://8093755457"
    }
end

-- Load dependencies when module is required
loadDependencies()

-- Utility functions
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or UDim.new(0, 8)
    corner.Parent = parent
    return corner
end

local function createShadow(parent)
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.6
    shadow.BorderSizePixel = 0
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.ZIndex = -1
    
    -- Add corner to shadow
    createCorner(shadow)
    shadow.Parent = parent
    
    return shadow
end

-- The DialogFactory module
local DialogFactory = {}

-- Create a notification popup
function DialogFactory:createNotification(options)
    options = options or {}
    
    -- Get player's GUI
    local player = options.player or Players.LocalPlayer
    if not player then
        warn("[DialogFactory] No player provided and LocalPlayer not available")
        return nil
    end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        warn("[DialogFactory] PlayerGui not found for", player.Name)
        return nil
    end
    
    -- Create notification GUI if needed
    local notificationGui = playerGui:FindFirstChild("NotificationGui")
    if not notificationGui then
        notificationGui = Instance.new("ScreenGui")
        notificationGui.Name = "NotificationGui"
        notificationGui.ResetOnSpawn = false
        notificationGui.Parent = playerGui
    end
    
    -- Determine notification type and color
    local notifType = options.type or "info"
    local bgColor
    if notifType == "success" then
        bgColor = UIStyle.colors.success
    elseif notifType == "error" then
        bgColor = UIStyle.colors.error
    elseif notifType == "warning" then
        bgColor = UIStyle.colors.warning
    else
        bgColor = UIStyle.colors.accent
    end
    
    -- Create the notification container
    local notification = Instance.new("Frame")
    notification.Name = "Notification_" .. os.time()
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(0.5, -150, 0, -100) -- Start above screen
    notification.BackgroundColor3 = bgColor
    notification.BorderSizePixel = 0
    notification.Parent = notificationGui
    
    -- Add corner radius
    createCorner(notification)
    
    -- Add shadow
    createShadow(notification)
    
    -- Create icon (if available)
    local icon
    if IconSet and IconSet[notifType] then
        icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 32, 0, 32)
        icon.Position = UDim2.new(0, 10, 0, 10)
        icon.Image = IconSet[notifType]
        icon.BackgroundTransparency = 1
        icon.Parent = notification
    end
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(icon and 0.9 or 1, icon and -50 or -20, 0, 24)
    title.Position = UDim2.new(icon and 0.1 or 0, icon and 0 or 10, 0, 10)
    title.TextColor3 = UIStyle.colors.text
    title.Font = UIStyle.fonts.header
    title.TextSize = UIStyle.fontSizes.header
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.Text = options.title or "Notification"
    title.Parent = notification
    
    -- Create message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -20, 0, 36)
    message.Position = UDim2.new(0, 10, 0, 40)
    message.TextColor3 = UIStyle.colors.text
    message.Font = UIStyle.fonts.body
    message.TextSize = UIStyle.fontSizes.body
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = true
    message.BackgroundTransparency = 1
    message.Text = options.message or ""
    message.Parent = notification
    
    -- Animate notification
    notification:TweenPosition(
        UDim2.new(0.5, -150, 0, 20),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.5,
        true
    )
    
    -- Auto-close after duration
    local duration = options.duration or 5 -- Default 5 seconds
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
    
    return notification
end

-- Show a notification (shorthand method)
function DialogFactory:showNotification(options)
    return self:createNotification(options)
end

-- Create a confirmation dialog with Yes/No buttons
function DialogFactory:createConfirmDialog(title, message, confirmCallback, cancelCallback, options)
    options = options or {}
    
    -- Get player's GUI
    local player = options.player or Players.LocalPlayer
    if not player then
        warn("[DialogFactory] No player provided and LocalPlayer not available")
        return nil
    end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        warn("[DialogFactory] PlayerGui not found for", player.Name)
        return nil
    end
    
    -- Create dialog GUI if needed
    local dialogGui = playerGui:FindFirstChild("DialogGui")
    if not dialogGui then
        dialogGui = Instance.new("ScreenGui")
        dialogGui.Name = "DialogGui"
        dialogGui.ResetOnSpawn = false
        dialogGui.Parent = playerGui
    end
    
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = dialogGui
    
    -- Create the dialog container
    local dialog = Instance.new("Frame")
    dialog.Name = "ConfirmDialog"
    dialog.Size = UDim2.new(0, 400, 0, 200)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
    dialog.BackgroundColor3 = UIStyle.colors.background
    dialog.BorderSizePixel = 0
    dialog.Parent = overlay
    
    -- Add corner radius
    createCorner(dialog)
    
    -- Add shadow
    createShadow(dialog)
    
    -- Create title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 36)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.TextColor3 = UIStyle.colors.text
    titleLabel.Font = UIStyle.fonts.header
    titleLabel.TextSize = UIStyle.fontSizes.header
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "Confirm"
    titleLabel.Parent = dialog
    
    -- Create close button
    local closeButton = Instance.new("ImageButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -34, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Image = IconSet.close
    closeButton.Parent = dialog
    
    -- Create message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -40, 0, 80)
    messageLabel.Position = UDim2.new(0, 20, 0, 50)
    messageLabel.TextColor3 = UIStyle.colors.text
    messageLabel.Font = UIStyle.fonts.body
    messageLabel.TextSize = UIStyle.fontSizes.body
    messageLabel.TextWrapped = true
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message or ""
    messageLabel.Parent = dialog
    
    -- Create confirm button
    local confirmButton = Instance.new("TextButton")
    confirmButton.Name = "ConfirmButton"
    confirmButton.Size = UDim2.new(0.4, 0, 0, 40)
    confirmButton.Position = UDim2.new(0.075, 0, 1, -60)
    confirmButton.BackgroundColor3 = UIStyle.colors.accent
    confirmButton.TextColor3 = UIStyle.colors.text
    confirmButton.Font = UIStyle.fonts.button
    confirmButton.TextSize = UIStyle.fontSizes.button
    confirmButton.BorderSizePixel = 0
    confirmButton.Text = options.confirmText or "Yes"
    confirmButton.Parent = dialog
    createCorner(confirmButton)
    
    -- Create cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(0.4, 0, 0, 40)
    cancelButton.Position = UDim2.new(0.525, 0, 1, -60)
    cancelButton.BackgroundColor3 = UIStyle.colors.backgroundLight
    cancelButton.TextColor3 = UIStyle.colors.text
    cancelButton.Font = UIStyle.fonts.button
    cancelButton.TextSize = UIStyle.fontSizes.button
    cancelButton.BorderSizePixel = 0
    cancelButton.Text = options.cancelText or "No"
    cancelButton.Parent = dialog
    createCorner(cancelButton)
    
    -- Function to close dialog
    local function closeDialog()
        overlay:Destroy()
    end
    
    -- Connect button events
    confirmButton.MouseButton1Click:Connect(function()
        if confirmCallback then
            confirmCallback()
        end
        closeDialog()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        if cancelCallback then
            cancelCallback()
        end
        closeDialog()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        if cancelCallback then
            cancelCallback()
        end
        closeDialog()
    end)
    
    return dialog
end

-- Create a simple message dialog with just an OK button
function DialogFactory:createMessageDialog(title, message, closeCallback, options)
    options = options or {}
    
    -- Get player's GUI
    local player = options.player or Players.LocalPlayer
    if not player then
        warn("[DialogFactory] No player provided and LocalPlayer not available")
        return nil
    end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        warn("[DialogFactory] PlayerGui not found for", player.Name)
        return nil
    end
    
    -- Create dialog GUI if needed
    local dialogGui = playerGui:FindFirstChild("DialogGui")
    if not dialogGui then
        dialogGui = Instance.new("ScreenGui")
        dialogGui.Name = "DialogGui"
        dialogGui.ResetOnSpawn = false
        dialogGui.Parent = playerGui
    end
    
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = dialogGui
    
    -- Create the dialog container
    local dialog = Instance.new("Frame")
    dialog.Name = "MessageDialog"
    dialog.Size = UDim2.new(0, 400, 0, 200)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
    dialog.BackgroundColor3 = UIStyle.colors.background
    dialog.BorderSizePixel = 0
    dialog.Parent = overlay
    
    -- Add corner radius
    createCorner(dialog)
    
    -- Add shadow
    createShadow(dialog)
    
    -- Create title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 36)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.TextColor3 = UIStyle.colors.text
    titleLabel.Font = UIStyle.fonts.header
    titleLabel.TextSize = UIStyle.fontSizes.header
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "Message"
    titleLabel.Parent = dialog
    
    -- Create message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -40, 0, 80)
    messageLabel.Position = UDim2.new(0, 20, 0, 50)
    messageLabel.TextColor3 = UIStyle.colors.text
    messageLabel.Font = UIStyle.fonts.body
    messageLabel.TextSize = UIStyle.fontSizes.body
    messageLabel.TextWrapped = true
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message or ""
    messageLabel.Parent = dialog
    
    -- Create OK button
    local okButton = Instance.new("TextButton")
    okButton.Name = "OKButton"
    okButton.Size = UDim2.new(0.5, 0, 0, 40)
    okButton.Position = UDim2.new(0.25, 0, 1, -60)
    okButton.BackgroundColor3 = UIStyle.colors.accent
    okButton.TextColor3 = UIStyle.colors.text
    okButton.Font = UIStyle.fonts.button
    okButton.TextSize = UIStyle.fontSizes.button
    okButton.BorderSizePixel = 0
    okButton.Text = options.okText or "OK"
    okButton.Parent = dialog
    createCorner(okButton)
    
    -- Function to close dialog
    local function closeDialog()
        overlay:Destroy()
    end
    
    -- Connect button events
    okButton.MouseButton1Click:Connect(function()
        if closeCallback then
            closeCallback()
        end
        closeDialog()
    end)
    
    return dialog
end

-- Shorthand to show a simple message
function DialogFactory:showMessage(options)
    return self:createMessageDialog(
        options.title or "Message",
        options.message or "",
        options.callback,
        options
    )
end

-- Register with ClientRegistry if available
local function registerWithClientRegistry()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then return end
    
    local clientRegistryModule = shared:FindFirstChild("ClientRegistry")
    if not clientRegistryModule then return end
    
    local success, clientRegistry = pcall(function()
        return require(clientRegistryModule)
    end)
    
    if success and clientRegistry and typeof(clientRegistry.registerUIComponent) == "function" then
        clientRegistry:registerUIComponent("DialogFactory", DialogFactory)
        print("[DialogFactory] Registered with ClientRegistry")
    end
end

-- Try to register with ClientRegistry
task.spawn(registerWithClientRegistry)

return DialogFactory
