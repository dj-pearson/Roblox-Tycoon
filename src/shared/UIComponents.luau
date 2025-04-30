-- UIComponents.luau
-- Consolidated UI component system that provides consistent styling and UI elements
-- Created: April 30, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Utilities
local function safeRequire(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        warn("[UIComponents] Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find a module by searching multiple paths
local function findModule(moduleName)
    -- Search paths
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and ReplicatedStorage.src.client:FindFirstChild("UI") and ReplicatedStorage.src.client.UI:FindFirstChild("Core"),
        ReplicatedStorage
    }
    
    -- Look in each path
    for _, path in ipairs(searchPaths) do
        if path then
            local moduleScript = path:FindFirstChild(moduleName)
            if moduleScript and moduleScript:IsA("ModuleScript") then
                return moduleScript
            end
        end
    end
    
    return nil
end

-- Default UI style configuration
local defaultUIStyle = {
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
        Default = Enum.Font.Gotham,
        Title = Enum.Font.GothamBold,
        Button = Enum.Font.GothamMedium,
        Body = Enum.Font.Gotham,
        Code = Enum.Font.Code
    },
    Padding = {
        Small = UDim.new(0, 5),
        Medium = UDim.new(0, 10),
        Large = UDim.new(0, 20)
    },
    CornerRadius = {
        Small = UDim.new(0, 4),
        Medium = UDim.new(0, 8),
        Large = UDim.new(0, 16),
        Pill = UDim.new(1, 0)
    }
}

-- Try to load UIStyle module or use default
local uiStyle = safeRequire(findModule("UIStyle")) or defaultUIStyle

-- Create the module
local UIComponents = {}

-- Version information
UIComponents.Version = "1.0.0"
UIComponents.IsLoaded = true
UIComponents.UIStyle = uiStyle

-- Store registered components
local registeredComponents = {}

-- Default icons
local defaultIcons = {
    Close = "rbxassetid://3926305904",
    Settings = "rbxassetid://3926307971",
    Info = "rbxassetid://3926305904",
    Warning = "rbxassetid://3926305904",
    Error = "rbxassetid://3926305904",
    Success = "rbxassetid://3926305904",
    User = "rbxassetid://3926307971"
}

-- Try to load IconSet or use defaults
local IconSet = safeRequire(findModule("IconSet")) or {
    getIcon = function(name)
        return defaultIcons[name] or defaultIcons.Info
    end
}

UIComponents.IconSet = IconSet

-- Button Creation
function UIComponents.CreateButton(properties)
    properties = properties or {}
    
    if type(properties) == "string" then
        properties = {text = properties}
    end
    
    local button = Instance.new("TextButton")
    button.Size = properties.size or UDim2.new(0, 200, 0, 50)
    button.Position = properties.position or UDim2.new(0.5, -100, 0.5, -25)
    button.BackgroundColor3 = properties.backgroundColor or uiStyle.Colors.Primary
    button.TextColor3 = properties.textColor or uiStyle.Colors.Text
    button.Font = properties.font or uiStyle.Fonts.Button
    button.TextSize = properties.textSize or 16
    button.Text = properties.text or "Button"
    button.Name = properties.name or "UIButton"
    button.AnchorPoint = properties.anchorPoint or Vector2.new(0, 0)
    button.BorderSizePixel = 0
    button.AutoButtonColor = properties.autoButtonColor ~= false -- default true
    
    -- Add corner if requested
    if properties.rounded ~= false then
        local cornerRadius = properties.cornerRadius or uiStyle.CornerRadius.Medium
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = cornerRadius
        corner.Parent = button
    end
    
    -- Add callback
    if properties.callback and type(properties.callback) == "function" then
        button.MouseButton1Click:Connect(properties.callback)
    end
    
    -- Add to parent if specified
    if properties.parent then
        button.Parent = properties.parent
    end
    
    return button
end

-- Create a button with an icon
function UIComponents.CreateIconButton(properties)
    properties = properties or {}
    
    local button = UIComponents.CreateButton(properties)
    
    -- Add the icon
    if properties.icon then
        local iconImage = Instance.new("ImageLabel")
        iconImage.Name = "Icon"
        iconImage.Size = properties.iconSize or UDim2.new(0.6, 0, 0.6, 0)
        iconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
        iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = properties.icon
        iconImage.Parent = button
    end
    
    return button
end

-- Create a frame with consistent styling
function UIComponents.CreateFrame(properties)
    properties = properties or {}
    
    local frame = Instance.new("Frame")
    frame.Name = properties.name or "UIFrame"
    frame.Size = properties.size or UDim2.new(0, 400, 0, 300)
    frame.Position = properties.position or UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundColor3 = properties.backgroundColor or uiStyle.Colors.Background
    frame.BorderSizePixel = 0
    
    -- Add corner if requested
    if properties.rounded ~= false then
        local cornerRadius = properties.cornerRadius or uiStyle.CornerRadius.Medium
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = cornerRadius
        corner.Parent = frame
    end
    
    -- Add children if specified
    if properties.children then
        for _, child in ipairs(properties.children) do
            child.Parent = frame
        end
    end
    
    -- Add to parent if specified
    if properties.parent then
        frame.Parent = properties.parent
    end
    
    return frame
end

-- Create a simple dialog
function UIComponents.CreateDialog(config)
    config = config or {}
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.name or "UIDialog"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Get parent
    local parent = config.parent
    if not parent and RunService:IsClient() then
        local player = Players.LocalPlayer
        if player then
            parent = player:FindFirstChild("PlayerGui")
        end
    end
    
    if parent then
        screenGui.Parent = parent
    end
    
    -- Create background overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui
    
    -- Create dialog frame
    local dialog = UIComponents.CreateFrame({
        name = "DialogFrame",
        size = config.size or UDim2.new(0, 400, 0, 250),
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchorPoint = Vector2.new(0.5, 0.5),
        parent = overlay
    })
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = uiStyle.Fonts.Title
    title.TextSize = 24
    title.TextColor3 = uiStyle.Colors.Text
    title.Text = config.title or "Dialog"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = dialog
    
    -- Create message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -20, 1, -110)
    message.Position = UDim2.new(0, 10, 0, 60)
    message.BackgroundTransparency = 1
    message.Font = uiStyle.Fonts.Body
    message.TextSize = 16
    message.TextColor3 = uiStyle.Colors.Text
    message.Text = config.message or ""
    message.TextWrapped = true
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextYAlignment = Enum.TextYAlignment.Top
    message.Parent = dialog
    
    -- Add button(s)
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, 40)
    buttonContainer.Position = UDim2.new(0, 0, 1, -50)
    buttonContainer.AnchorPoint = Vector2.new(0, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = dialog
    
    -- Add OK button by default
    local button = UIComponents.CreateButton({
        name = "OkButton",
        size = UDim2.new(0, 120, 0, 30),
        position = UDim2.new(0.5, 0, 0, 0),
        anchorPoint = Vector2.new(0.5, 0),
        text = config.buttonText or "OK",
        callback = function()
            screenGui:Destroy()
            if config.callback then
                config.callback()
            end
        end,
        parent = buttonContainer
    })
    
    -- Return the dialog and components
    return {
        dialog = dialog,
        title = title,
        message = message,
        button = button,
        screenGui = screenGui
    }
end

-- Create a confirmation dialog with yes/no buttons
function UIComponents.CreateConfirmDialog(config)
    config = config or {}
    
    local dialog = UIComponents.CreateDialog({
        title = config.title or "Confirm",
        message = config.message or "Are you sure?",
        size = config.size or UDim2.new(0, 400, 0, 250),
        parent = config.parent
    })
    
    -- Remove the default button
    dialog.button:Destroy()
    
    -- Create Yes button
    local yesButton = UIComponents.CreateButton({
        name = "YesButton",
        size = UDim2.new(0, 120, 0, 30),
        position = UDim2.new(0.3, 0, 0, 0),
        anchorPoint = Vector2.new(0.5, 0),
        text = config.confirmText or "Yes",
        backgroundColor = uiStyle.Colors.Success,
        callback = function()
            dialog.screenGui:Destroy()
            if config.onConfirm then
                config.onConfirm()
            end
        end,
        parent = dialog.dialog:FindFirstChild("ButtonContainer")
    })
    
    -- Create No button
    local noButton = UIComponents.CreateButton({
        name = "NoButton",
        size = UDim2.new(0, 120, 0, 30),
        position = UDim2.new(0.7, 0, 0, 0),
        anchorPoint = Vector2.new(0.5, 0),
        text = config.cancelText or "No",
        backgroundColor = uiStyle.Colors.Error,
        callback = function()
            dialog.screenGui:Destroy()
            if config.onCancel then
                config.onCancel()
            end
        end,
        parent = dialog.dialog:FindFirstChild("ButtonContainer")
    })
    
    -- Add to the dialog object
    dialog.yesButton = yesButton
    dialog.noButton = noButton
    
    return dialog
end

-- Create a notification
function UIComponents.CreateNotification(config)
    config = config or {}
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.name or "UINotification"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Get parent
    local parent = config.parent
    if not parent and RunService:IsClient() then
        local player = Players.LocalPlayer
        if player then
            parent = player:FindFirstChild("PlayerGui")
        end
    end
    
    if parent then
        screenGui.Parent = parent
    end
    
    -- Create notification frame
    local notif = UIComponents.CreateFrame({
        name = "NotificationFrame",
        size = config.size or UDim2.new(0, 300, 0, 80),
        position = config.position or UDim2.new(1, -20, 0, 20),
        anchorPoint = Vector2.new(1, 0),
        parent = screenGui
    })
    
    -- Default colors based on type
    local typeColors = {
        info = uiStyle.Colors.Primary,
        success = uiStyle.Colors.Success,
        warning = uiStyle.Colors.Warning,
        error = uiStyle.Colors.Error
    }
    
    -- Set background color based on type
    local notifType = config.type or "info"
    notif.BackgroundColor3 = config.backgroundColor or typeColors[notifType] or typeColors.info
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Font = uiStyle.Fonts.Title
    title.TextSize = 18
    title.TextColor3 = uiStyle.Colors.Text
    title.Text = config.title or "Notification"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notif
    
    -- Create message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -20, 1, -40)
    message.Position = UDim2.new(0, 10, 0, 35)
    message.BackgroundTransparency = 1
    message.Font = uiStyle.Fonts.Body
    message.TextSize = 14
    message.TextColor3 = uiStyle.Colors.Text
    message.Text = config.message or ""
    message.TextWrapped = true
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.Parent = notif
    
    -- Auto-remove after duration
    local duration = config.duration or 5 -- seconds
    if duration > 0 then
        task.spawn(function()
            task.wait(duration)
            screenGui:Destroy()
        end)
    end
    
    return {
        notification = notif,
        title = title,
        message = message,
        screenGui = screenGui
    }
end

-- For backwards compatibility with different casing conventions
UIComponents.ButtonFactory = {
    createButton = UIComponents.CreateButton,
    CreateButton = UIComponents.CreateButton,
    createIconButton = UIComponents.CreateIconButton,
    CreateIconButton = UIComponents.CreateIconButton
}

UIComponents.DialogFactory = {
    createDialog = UIComponents.CreateDialog,
    CreateDialog = UIComponents.CreateDialog,
    createConfirmDialog = UIComponents.CreateConfirmDialog,
    CreateConfirmDialog = UIComponents.CreateConfirmDialog,
    createNotification = UIComponents.CreateNotification,
    CreateNotification = UIComponents.CreateNotification
}

-- Add camelCase aliases for all Pascal case functions
UIComponents.createButton = UIComponents.CreateButton
UIComponents.createIconButton = UIComponents.CreateIconButton
UIComponents.createFrame = UIComponents.CreateFrame
UIComponents.createDialog = UIComponents.CreateDialog
UIComponents.createConfirmDialog = UIComponents.CreateConfirmDialog
UIComponents.createNotification = UIComponents.CreateNotification
UIComponents.registerComponent = UIComponents.RegisterComponent
UIComponents.getComponent = UIComponents.GetComponent
UIComponents.getComponents = UIComponents.GetComponents
UIComponents.initialize = UIComponents.Initialize

-- Register a component
function UIComponents.RegisterComponent(name, component)
    if not name or type(name) ~= "string" then
        warn("[UIComponents] Invalid component name")
        return false
    end
    
    if not component then
        warn("[UIComponents] Cannot register nil component: " .. name)
        return false
    end
    
    registeredComponents[name] = component
    print("[UIComponents] Registered component: " .. name)
    return true
end

-- Get a registered component
function UIComponents.GetComponent(name)
    return registeredComponents[name]
end

-- Get all registered components
function UIComponents.GetComponents()
    local components = {}
    for name, component in pairs(registeredComponents) do
        components[name] = component
    end
    return components
end

-- Initialize the module
function UIComponents.Initialize()
    print("[UIComponents] Initializing...")
    
    -- Try to register with ClientRegistry if available
    local clientRegistry = safeRequire(findModule("ClientRegistry"))
    if clientRegistry then
        if typeof(clientRegistry.registerSystem) == "function" then
            clientRegistry:registerSystem("UIComponents", UIComponents)
            print("[UIComponents] Registered with ClientRegistry using registerSystem")
        elseif typeof(clientRegistry.registerUIComponent) == "function" then
            clientRegistry:registerUIComponent("UIComponents", UIComponents)
            print("[UIComponents] Registered with ClientRegistry using registerUIComponent")
        else
            print("[UIComponents] ClientRegistry found but no registration method available")
        end
    else
        print("[UIComponents] ClientRegistry not found, but UIComponents will still function")
    end
    
    -- Register button and dialog factories
    UIComponents.RegisterComponent("ButtonFactory", UIComponents.ButtonFactory)
    UIComponents.RegisterComponent("DialogFactory", UIComponents.DialogFactory)
    UIComponents.RegisterComponent("UIStyle", uiStyle)
    UIComponents.RegisterComponent("IconSet", IconSet)
    
    print("[UIComponents] Initialization complete")
    return true
end

-- Auto-initialize on load
task.spawn(function()
    UIComponents.Initialize()
end)

return UIComponents
