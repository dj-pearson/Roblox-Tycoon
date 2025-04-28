--!strict
--[[
    UIComponents.luau
    
    A consolidated module that provides all UI-related components and utilities.
    This module serves as a facade for various UI modules and provides a unified
    interface for accessing UI functionality.
    
    Created: April 27, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to load dependencies
local UIStyle, IconSet, ButtonFactory, DialogFactory

local function loadDependencies()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then
        -- Try loading each dependency
        local success, result
        
        -- Load UIStyle
        success, result = pcall(function()
            local module = shared:FindFirstChild("UIStyle")
            return module and require(module)
        end)
        if success and result then
            UIStyle = result
        end
        
        -- Load IconSet
        success, result = pcall(function()
            local module = shared:FindFirstChild("IconSet")
            return module and require(module)
        end)
        if success and result then
            IconSet = result
        end
        
        -- Load ButtonFactory
        success, result = pcall(function()
            local module = shared:FindFirstChild("ButtonFactory")
            return module and require(module)
        end)
        if success and result then
            ButtonFactory = result
        end
        
        -- Load DialogFactory
        success, result = pcall(function()
            local module = shared:FindFirstChild("DialogFactory")
            return module and require(module)
        end)
        if success and result then
            DialogFactory = result
        end
    end
    
    -- Set default values for anything not loaded
    if not UIStyle then
        print("UIStyle not found, using default implementation")
        UIStyle = {
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
    end
    
    if not IconSet then
        print("IconSet not found, using default implementation")
        IconSet = {
            close = "rbxassetid://8093755787",
            info = "rbxassetid://8093754900",
            warning = "rbxassetid://8093755364",
            error = "rbxassetid://8093755611",
            success = "rbxassetid://8093755457"
        }
    end
end

-- Load dependencies on require
loadDependencies()

-- UIComponents module
local UIComponents = {
    UIStyle = UIStyle,
    IconSet = IconSet
}

-- Create a button
function UIComponents.createButton(options)
    -- If ButtonFactory exists, use it
    if ButtonFactory and typeof(ButtonFactory.createButton) == "function" then
        return ButtonFactory.createButton(options)
    end
    
    -- Otherwise, implement basic button creation
    options = options or {}
    
    local button = Instance.new("TextButton")
    button.Name = options.name or "Button"
    button.Size = options.size or UDim2.new(0, 200, 0, 40)
    button.Position = options.position or UDim2.new(0.5, -100, 0.5, -20)
    button.BackgroundColor3 = options.color or UIStyle.colors.accent
    button.TextColor3 = options.textColor or UIStyle.colors.text
    button.TextSize = options.textSize or UIStyle.fontSizes.button
    button.Font = options.font or UIStyle.fonts.button
    button.Text = options.text or "Button"
    button.BorderSizePixel = 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = options.cornerRadius or UDim.new(0, 8)
    corner.Parent = button
    
    -- Add shadow
    if options.showShadow ~= false then
        local shadow = Instance.new("Frame")
        shadow.Name = "Shadow"
        shadow.AnchorPoint = Vector2.new(0.5, 0.5)
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.6
        shadow.BorderSizePixel = 0
        shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
        shadow.Size = UDim2.new(1, 4, 1, 4)
        shadow.ZIndex = button.ZIndex - 1
        
        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = corner.CornerRadius
        shadowCorner.Parent = shadow
        
        shadow.Parent = button
    end
    
    -- Connect callback if provided
    if options.callback and typeof(options.callback) == "function" then
        button.MouseButton1Click:Connect(options.callback)
    end
    
    return button
end

-- Create a notification
function UIComponents.createNotification(options)
    -- If DialogFactory exists, use it
    if DialogFactory and typeof(DialogFactory.createNotification) == "function" then
        return DialogFactory:createNotification(options)
    end
    
    -- Otherwise, implement basic notification
    options = options or {}
    local player = options.player or game:GetService("Players").LocalPlayer
    
    if not player or not player:FindFirstChild("PlayerGui") then
        warn("UIComponents: Cannot create notification - player or PlayerGui not found")
        return nil
    end
    
    -- Create notification GUI if needed
    local notificationGui = player.PlayerGui:FindFirstChild("NotificationGui")
    if not notificationGui then
        notificationGui = Instance.new("ScreenGui")
        notificationGui.Name = "NotificationGui"
        notificationGui.ResetOnSpawn = false
        notificationGui.Parent = player.PlayerGui
    end
    
    -- Create notification frame
    local notif = Instance.new("Frame")
    notif.Name = "Notification_" .. os.time()
    notif.Size = UDim2.new(0, 300, 0, 80)
    notif.Position = UDim2.new(0.5, -150, 0, -100) -- Start offscreen
    notif.BackgroundColor3 = UIStyle.colors.background
    notif.BorderSizePixel = 0
    notif.Parent = notificationGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.TextColor3 = UIStyle.colors.text
    title.TextSize = UIStyle.fontSizes.header
    title.Font = UIStyle.fonts.header
    title.Text = options.title or "Notification"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notif
    
    -- Create message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -20, 0, 40)
    message.Position = UDim2.new(0, 10, 0, 35)
    message.BackgroundTransparency = 1
    message.TextColor3 = UIStyle.colors.text
    message.TextSize = UIStyle.fontSizes.body
    message.Font = UIStyle.fonts.body
    message.Text = options.message or ""
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = true
    message.Parent = notif
    
    -- Animate in
    notif:TweenPosition(
        UDim2.new(0.5, -150, 0, 20),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.5
    )
    
    -- Auto-remove after duration
    local duration = options.duration or 5 -- Default 5 seconds
    task.delay(duration, function()
        notif:TweenPosition(
            UDim2.new(0.5, -150, 0, -100),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Quad,
            0.5,
            true,
            function()
                notif:Destroy()
            end
        )
    end)
    
    return notif
end

-- Show a dialog
function UIComponents.createDialog(options)
    -- If DialogFactory exists, use it
    if DialogFactory then
        if options.confirmCallback then
            return DialogFactory:createConfirmDialog(
                options.title or "Confirm",
                options.message or "",
                options.confirmCallback,
                options.cancelCallback,
                options
            )
        else
            return DialogFactory:createMessageDialog(
                options.title or "Message",
                options.message or "",
                options.closeCallback,
                options
            )
        end
    end
    
    -- Otherwise, implement basic dialog
    options = options or {}
    local player = options.player or game:GetService("Players").LocalPlayer
    
    if not player or not player:FindFirstChild("PlayerGui") then
        warn("UIComponents: Cannot create dialog - player or PlayerGui not found")
        return nil
    end
    
    -- Create dialog GUI if needed
    local dialogGui = player.PlayerGui:FindFirstChild("DialogGui")
    if not dialogGui then
        dialogGui = Instance.new("ScreenGui")
        dialogGui.Name = "DialogGui"
        dialogGui.ResetOnSpawn = false
        dialogGui.Parent = player.PlayerGui
    end
    
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "DialogOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = dialogGui
    
    -- Create dialog frame
    local dialog = Instance.new("Frame")
    dialog.Name = "Dialog"
    dialog.Size = UDim2.new(0, 400, 0, 200)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
    dialog.BackgroundColor3 = UIStyle.colors.background
    dialog.BorderSizePixel = 0
    dialog.Parent = overlay
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = dialog
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.TextColor3 = UIStyle.colors.text
    title.TextSize = UIStyle.fontSizes.header
    title.Font = UIStyle.fonts.header
    title.Text = options.title or "Dialog"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = dialog
    
    -- Create message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -40, 0, 80)
    message.Position = UDim2.new(0, 20, 0, 50)
    message.BackgroundTransparency = 1
    message.TextColor3 = UIStyle.colors.text
    message.TextSize = UIStyle.fontSizes.body
    message.Font = UIStyle.fonts.body
    message.Text = options.message or ""
    message.TextWrapped = true
    message.Parent = dialog
    
    -- Function to close dialog
    local function closeDialog()
        overlay:Destroy()
    end
    
    -- Create buttons based on dialog type
    if options.confirmCallback then
        -- Confirm dialog with two buttons
        local confirmButton = UIComponents.createButton({
            name = "ConfirmButton",
            text = options.confirmText or "Confirm",
            size = UDim2.new(0.4, 0, 0, 40),
            position = UDim2.new(0.075, 0, 1, -60),
            color = UIStyle.colors.accent,
            callback = function()
                if options.confirmCallback then
                    options.confirmCallback()
                end
                closeDialog()
            end
        })
        confirmButton.Parent = dialog
        
        local cancelButton = UIComponents.createButton({
            name = "CancelButton",
            text = options.cancelText or "Cancel",
            size = UDim2.new(0.4, 0, 0, 40),
            position = UDim2.new(0.525, 0, 1, -60),
            color = UIStyle.colors.backgroundLight,
            callback = function()
                if options.cancelCallback then
                    options.cancelCallback()
                end
                closeDialog()
            end
        })
        cancelButton.Parent = dialog
    else
        -- Message dialog with one button
        local okButton = UIComponents.createButton({
            name = "OKButton",
            text = options.okText or "OK",
            size = UDim2.new(0.5, 0, 0, 40),
            position = UDim2.new(0.25, 0, 1, -60),
            color = UIStyle.colors.accent,
            callback = function()
                if options.closeCallback then
                    options.closeCallback()
                end
                closeDialog()
            end
        })
        okButton.Parent = dialog
    end
    
    return dialog
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
        clientRegistry:registerUIComponent("UIComponents", UIComponents)
        print("UIComponents registered with ClientRegistry")
    end
end

-- Try to register with ClientRegistry
task.spawn(registerWithClientRegistry)

return UIComponents
