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
    
    if success and clientRegistry then
        -- Try both registration methods to ensure compatibility
        if typeof(clientRegistry.registerUIComponent) == "function" then
            clientRegistry:registerUIComponent("DialogFactory", DialogFactory)
            print("[DialogFactory] Registered with ClientRegistry using registerUIComponent")
        elseif typeof(clientRegistry.registerComponent) == "function" then
            clientRegistry.registerComponent("DialogFactory", DialogFactory)
            print("[DialogFactory] Registered with ClientRegistry using registerComponent")
        elseif typeof(clientRegistry.RegisterComponent) == "function" then
            clientRegistry.RegisterComponent("DialogFactory", DialogFactory)
            print("[DialogFactory] Registered with ClientRegistry using RegisterComponent")
        end
    end
end

-- Create a progress dialog showing a progress bar
function DialogFactory:createProgressDialog(options)
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
    dialog.Name = "ProgressDialog"
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
    titleLabel.Text = options.title or "Progress"
    titleLabel.Parent = dialog
    
    -- Create message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -40, 0, 40)
    messageLabel.Position = UDim2.new(0, 20, 0, 50)
    messageLabel.TextColor3 = UIStyle.colors.text
    messageLabel.Font = UIStyle.fonts.body
    messageLabel.TextSize = UIStyle.fontSizes.body
    messageLabel.TextWrapped = true
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = options.message or "Loading..."
    messageLabel.Parent = dialog
    
    -- Create progress bar background
    local progressBarBg = Instance.new("Frame")
    progressBarBg.Name = "ProgressBarBackground"
    progressBarBg.Size = UDim2.new(1, -40, 0, 20)
    progressBarBg.Position = UDim2.new(0, 20, 0, 100)
    progressBarBg.BackgroundColor3 = UIStyle.colors.backgroundDark
    progressBarBg.BorderSizePixel = 0
    progressBarBg.Parent = dialog
    createCorner(progressBarBg, UDim.new(0, 4))
    
    -- Create progress bar fill
    local progressBarFill = Instance.new("Frame")
    progressBarFill.Name = "ProgressBarFill"
    progressBarFill.Size = UDim2.new(0, 0, 1, 0)
    progressBarFill.BackgroundColor3 = UIStyle.colors.accent
    progressBarFill.BorderSizePixel = 0
    progressBarFill.Parent = progressBarBg
    createCorner(progressBarFill, UDim.new(0, 4))
    
    -- Create progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.Position = UDim2.new(0, 0, 0, 0)
    progressText.TextColor3 = UIStyle.colors.text
    progressText.Font = UIStyle.fonts.body
    progressText.TextSize = UIStyle.fontSizes.body
    progressText.BackgroundTransparency = 1
    progressText.Text = "0%"
    progressText.Parent = progressBarBg
    
    -- Create cancel button if needed
    local cancelButton
    if options.cancellable then
        cancelButton = Instance.new("TextButton")
        cancelButton.Name = "CancelButton"
        cancelButton.Size = UDim2.new(0.5, 0, 0, 40)
        cancelButton.Position = UDim2.new(0.25, 0, 1, -60)
        cancelButton.BackgroundColor3 = UIStyle.colors.backgroundLight
        cancelButton.TextColor3 = UIStyle.colors.text
        cancelButton.Font = UIStyle.fonts.button
        cancelButton.TextSize = UIStyle.fontSizes.button
        cancelButton.BorderSizePixel = 0
        cancelButton.Text = options.cancelText or "Cancel"
        cancelButton.Parent = dialog
        createCorner(cancelButton)
        
        if options.onCancel then
            cancelButton.MouseButton1Click:Connect(function()
                options.onCancel()
                overlay:Destroy()
            end)
        else
            cancelButton.MouseButton1Click:Connect(function()
                overlay:Destroy()
            end)
        end
    end
    
    -- Return an interface to update the progress dialog
    return {
        updateProgress = function(progress)
            progress = math.clamp(progress, 0, 1)
            progressBarFill:TweenSize(
                UDim2.new(progress, 0, 1, 0),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.2,
                true
            )
            progressText.Text = math.floor(progress * 100) .. "%"
        end,
        
        updateMessage = function(message)
            messageLabel.Text = message or ""
        end,
        
        complete = function()
            progressBarFill:TweenSize(
                UDim2.new(1, 0, 1, 0),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.2,
                true
            )
            progressText.Text = "100%"
            
            -- Change color to success
            progressBarFill.BackgroundColor3 = UIStyle.colors.success
            
            -- Auto-close after a delay
            if not options.persistent then
                task.delay(options.completeDelay or 1.5, function()
                    overlay:Destroy()
                end)
            end
        end,
        
        close = function()
            overlay:Destroy()
        end
    }
end

-- Create a tooltip that appears near an element
function DialogFactory:createTooltip(options)
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
    
    -- Create tooltip GUI if needed
    local tooltipGui = playerGui:FindFirstChild("TooltipGui")
    if not tooltipGui then
        tooltipGui = Instance.new("ScreenGui")
        tooltipGui.Name = "TooltipGui"
        tooltipGui.ResetOnSpawn = false
        tooltipGui.Parent = playerGui
    end
    
    -- Create tooltip container
    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 0, 0, 0) -- Start with zero size
    tooltip.AutomaticSize = Enum.AutomaticSize.XY
    tooltip.BackgroundColor3 = UIStyle.colors.backgroundDark
    tooltip.BorderSizePixel = 0
    tooltip.Position = UDim2.new(0, options.x or 0, 0, options.y or 0)
    tooltip.Parent = tooltipGui
    
    -- Add corner radius
    createCorner(tooltip)
    
    -- Add shadow
    createShadow(tooltip)
    
    -- Create content
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = tooltip
    
    local tooltipText = Instance.new("TextLabel")
    tooltipText.Name = "TooltipText"
    tooltipText.BackgroundTransparency = 1
    tooltipText.TextColor3 = UIStyle.colors.text
    tooltipText.Font = UIStyle.fonts.body
    tooltipText.TextSize = UIStyle.fontSizes.body
    tooltipText.TextWrapped = true
    tooltipText.Size = UDim2.new(1, 0, 0, 0)
    tooltipText.AutomaticSize = Enum.AutomaticSize.Y
    tooltipText.Text = options.text or ""
    tooltipText.Parent = tooltip
    
    -- Make the tooltip initially transparent
    tooltip.BackgroundTransparency = 1
    tooltipText.TextTransparency = 1
    
    -- Fade in the tooltip
    tooltip:TweenBackgroundTransparency(0.1, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    tooltipText:TweenProperty("TextTransparency", 0, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    
    -- Auto-close after duration
    local duration = options.duration or 3 -- Default 3 seconds
    task.delay(duration, function()
        -- Fade out
        tooltip:TweenBackgroundTransparency(1, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        tooltipText:TweenProperty("TextTransparency", 1, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        
        -- Destroy after fade out
        task.delay(0.2, function()
            tooltip:Destroy()
        end)
    end)
    
    -- Return interface
    return {
        updateText = function(text)
            tooltipText.Text = text or ""
        end,
        
        updatePosition = function(x, y)
            tooltip.Position = UDim2.new(0, x or tooltip.Position.X.Offset, 0, y or tooltip.Position.Y.Offset)
        end,
        
        close = function()
            -- Fade out
            tooltip:TweenBackgroundTransparency(1, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            tooltipText:TweenProperty("TextTransparency", 1, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            
            -- Destroy after fade out
            task.delay(0.2, function()
                tooltip:Destroy()
            end)
        end
    }
end

-- Create a context menu
function DialogFactory:createContextMenu(options)
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
    
    -- Create menu GUI if needed
    local menuGui = playerGui:FindFirstChild("ContextMenuGui")
    if not menuGui then
        menuGui = Instance.new("ScreenGui")
        menuGui.Name = "ContextMenuGui"
        menuGui.ResetOnSpawn = false
        menuGui.Parent = playerGui
    end
    
    -- Create menu container
    local menu = Instance.new("Frame")
    menu.Name = "ContextMenu"
    menu.Size = UDim2.new(0, 180, 0, 0) -- Height will be determined by content
    menu.AutomaticSize = Enum.AutomaticSize.Y
    menu.BackgroundColor3 = UIStyle.colors.background
    menu.BorderSizePixel = 0
    menu.Position = UDim2.new(0, options.x or 0, 0, options.y or 0)
    menu.Parent = menuGui
    
    -- Add corner radius
    createCorner(menu)
    
    -- Add shadow
    createShadow(menu)
    
    -- Menu items layout
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = menu
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 0)
    padding.PaddingRight = UDim.new(0, 0)
    padding.Parent = menu
    
    -- Function to create menu items
    local function createMenuItem(itemOptions)
        local item = Instance.new("TextButton")
        item.Name = "MenuItem"
        item.Size = UDim2.new(1, 0, 0, 32)
        item.BackgroundColor3 = UIStyle.colors.background
        item.BackgroundTransparency = 1
        item.TextColor3 = UIStyle.colors.text
        item.Font = UIStyle.fonts.body
        item.TextSize = UIStyle.fontSizes.body
        item.Text = itemOptions.text or ""
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.AutoButtonColor = false
        item.Parent = menu
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.Parent = item
        
        -- Icon if provided
        if itemOptions.icon then
            local icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.Size = UDim2.new(0, 16, 0, 16)
            icon.Position = UDim2.new(0, 8, 0.5, -8)
            icon.BackgroundTransparency = 1
            icon.Image = itemOptions.icon
            icon.Parent = item
            
            padding.PaddingLeft = UDim.new(0, 30)
        end
        
        -- Click event
        if itemOptions.onClick then
            item.MouseButton1Click:Connect(function()
                itemOptions.onClick()
                menu:Destroy()
            end)
        end
        
        -- Hover effect
        item.MouseEnter:Connect(function()
            item.BackgroundTransparency = 0.8
        end)
        
        item.MouseLeave:Connect(function()
            item.BackgroundTransparency = 1
        end)
        
        return item
    end
    
    -- Create menu items
    local menuItems = options.items or {}
    for i, itemOptions in ipairs(menuItems) do
        createMenuItem(itemOptions)
    end
    
    -- Close when clicking elsewhere
    local closeConnection
    closeConnection = game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            menu:Destroy()
            if closeConnection then
                closeConnection:Disconnect()
            end
        end
    end)
    
    -- Return interface
    return {
        addItem = function(itemOptions)
            createMenuItem(itemOptions)
        end,
        
        close = function()
            menu:Destroy()
            if closeConnection then
                closeConnection:Disconnect()
            end
        end
    }
end

-- Try to register with ClientRegistry
task.spawn(registerWithClientRegistry)

-- Mark as loaded for diagnostics
DialogFactory.isLoaded = true
DialogFactory.version = "1.1.0" -- Updated version with advanced features

return DialogFactory
