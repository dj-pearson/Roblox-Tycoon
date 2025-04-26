--!strict
--[[
    UIRegistry.luau
    
    A client-side UI registry that manages UI state across the application.
    
    Created: April 25, 2025
    
    This module:
    1. Provides a global access point for UI components
    2. Manages UI state across the application
    3. Handles UI element creation with proper error handling
    4. Coordinates UI transitions and animations
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Constants
local LocalPlayer = Players.LocalPlayer
local IsStudio = RunService:IsStudio()
local DEBUG_LOGGING = true

-- Find shared folder
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn("[UIRegistry] Failed to require module: ", module:GetFullName())
        return nil
    end
    
    return result
end

-- Try to get ClientRegistry from _G or from module
local ClientRegistry = _G.ClientRegistry
if not ClientRegistry then
    local clientRegistryModule = nil
    
    -- Try to find in PlayerScripts
    if LocalPlayer and LocalPlayer.PlayerScripts then
        if LocalPlayer.PlayerScripts:FindFirstChild("Client") and 
           LocalPlayer.PlayerScripts.Client:FindFirstChild("Core") and
           LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistry") then
            clientRegistryModule = LocalPlayer.PlayerScripts.Client.Core.ClientRegistry
        end
    end
    
    -- Try to find in shared folder
    if not clientRegistryModule and sharedFolder and sharedFolder:FindFirstChild("ClientRegistry") then
        clientRegistryModule = sharedFolder.ClientRegistry
    end
    
    -- Try to require if found
    if clientRegistryModule then
        ClientRegistry = requireSafely(clientRegistryModule)
    end
end

-- Try to get UI components through ClientRegistry or direct requires
local UIStyle, IconSet, ButtonFactory, DialogFactory

-- First try through ClientRegistry
if ClientRegistry then
    UIStyle = ClientRegistry:getUIComponent("UIStyle")
    IconSet = ClientRegistry:getUIComponent("IconSet")
    ButtonFactory = ClientRegistry:getUIComponent("ButtonFactory")
    DialogFactory = ClientRegistry:getUIComponent("DialogFactory")
end

-- If any are missing, try to get consolidated UIComponents
if not (UIStyle and IconSet and ButtonFactory and DialogFactory) then
    local UIComponents = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIComponents"))
    
    if UIComponents then
        UIStyle = UIComponents.UIStyle or UIStyle
        IconSet = UIComponents.IconSet or IconSet
        ButtonFactory = UIComponents.ButtonFactory or ButtonFactory
        DialogFactory = UIComponents.DialogFactory or DialogFactory
    end
end

-- If still missing, try direct requires
if not UIStyle then
    UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))
end

if not IconSet then
    IconSet = requireSafely(sharedFolder and sharedFolder:FindFirstChild("IconSet"))
end

if not ButtonFactory then
    ButtonFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("ButtonFactory"))
end

if not DialogFactory then
    DialogFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("DialogFactory"))
end

-- Priority levels for UI elements
local priorityLevels = {
    Low = 100,
    Medium = 200,
    High = 300,
    Critical = 400
}

-- UI Registry Module
local UIRegistry = {
    -- Public constants
    priorityLevels = priorityLevels,
    
    -- State tracking
    activeUIs = {},
    registeredUIs = {},
    modalActive = false,
    currentToasts = {},
    
    -- Dependencies
    UIStyle = UIStyle,
    IconSet = IconSet,
    ButtonFactory = ButtonFactory,
    DialogFactory = DialogFactory,
    
    -- Initialization flag
    initialized = false
}

-- Debug logging
local function log(message)
    if DEBUG_LOGGING then
        print("[UIRegistry] " .. message)
    end
end

-- Register a UI element with the registry
function UIRegistry:registerUI(uiId, uiElement, options)
    if not uiId or not uiElement then
        warn("[UIRegistry] Cannot register UI without ID or element")
        return false
    end
    
    options = options or {}
    
    -- Set defaults
    options.priority = options.priority or priorityLevels.Medium
    options.isModal = options.isModal or false
    options.closeOnEscape = options.closeOnEscape ~= false -- default true
    options.animateIn = options.animateIn ~= false -- default true
    options.animateOut = options.animateOut ~= false -- default true
    
    -- Register the UI
    self.registeredUIs[uiId] = {
        element = uiElement,
        options = options,
        visible = false,
        showTimestamp = 0
    }
    
    -- Hide the UI initially
    if uiElement:IsA("GuiObject") then
        uiElement.Visible = false
    end
    
    log("Registered UI: " .. uiId)
    return true
end

-- Show a registered UI element
function UIRegistry:showUI(uiId, ...)
    if not uiId or not self.registeredUIs[uiId] then
        warn("[UIRegistry] Cannot show unregistered UI: " .. tostring(uiId))
        return false
    end
    
    local uiData = self.registeredUIs[uiId]
    local uiElement = uiData.element
    local options = uiData.options
    
    -- If it's modal and there's already a modal active, queue or skip
    if options.isModal and self.modalActive then
        if options.priority > self.activeModalPriority then
            -- Higher priority, hide current modal and show this one
            self:hideCurrentModal()
        else
            -- Lower priority, skip
            log("Skipped showing modal UI due to priority: " .. uiId)
            return false
        end
    end
    
    -- Mark as modal active if applicable
    if options.isModal then
        self.modalActive = true
        self.activeModalId = uiId
        self.activeModalPriority = options.priority
    end
    
    -- Show the UI element
    if uiElement:IsA("GuiObject") then
        -- Prepare for animation if needed
        if options.animateIn then
            -- Set initial state for animation
            if uiElement:IsA("Frame") or uiElement:IsA("ScrollingFrame") then
                uiElement.Position = UDim2.new(0.5, 0, 1.5, 0)
                uiElement.AnchorPoint = Vector2.new(0.5, 0.5)
            end
            uiElement.Visible = true
            
            -- Tween to final position
            local targetPosition = UDim2.new(0.5, 0, 0.5, 0)
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            
            TweenService:Create(uiElement, tweenInfo, {
                Position = targetPosition
            }):Play()
        else
            -- Just show it
            uiElement.Visible = true
        end
    elseif typeof(uiElement) == "table" and typeof(uiElement.show) == "function" then
        -- Call show method if it exists (for custom UIs)
        uiElement:show(...)
    end
    
    -- Track state
    uiData.visible = true
    uiData.showTimestamp = tick()
    self.activeUIs[uiId] = uiData
    
    log("Showed UI: " .. uiId)
    return true
end

-- Hide a registered UI element
function UIRegistry:hideUI(uiId)
    if not uiId or not self.registeredUIs[uiId] then
        warn("[UIRegistry] Cannot hide unregistered UI: " .. tostring(uiId))
        return false
    end
    
    local uiData = self.registeredUIs[uiId]
    local uiElement = uiData.element
    local options = uiData.options
    
    -- Check if this is the active modal
    if options.isModal and self.activeModalId == uiId then
        self.modalActive = false
        self.activeModalId = nil
        self.activeModalPriority = 0
    end
    
    -- Hide the UI element
    if uiElement:IsA("GuiObject") then
        if options.animateOut then
            -- Tween out
            local targetPosition = UDim2.new(0.5, 0, 1.5, 0)
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            
            local tween = TweenService:Create(uiElement, tweenInfo, {
                Position = targetPosition
            })
            
            tween:Play()
            
            -- Hide after tween
            tween.Completed:Connect(function()
                uiElement.Visible = false
            end)
        else
            -- Just hide it
            uiElement.Visible = false
        end
    elseif typeof(uiElement) == "table" and typeof(uiElement.hide) == "function" then
        -- Call hide method if it exists (for custom UIs)
        uiElement:hide()
    end
    
    -- Track state
    uiData.visible = false
    self.activeUIs[uiId] = nil
    
    log("Hid UI: " .. uiId)
    return true
end

-- Hide the current modal UI
function UIRegistry:hideCurrentModal()
    if not self.modalActive or not self.activeModalId then
        return false
    end
    
    return self:hideUI(self.activeModalId)
end

-- Toggle a UI element's visibility
function UIRegistry:toggleUI(uiId, ...)
    if not uiId or not self.registeredUIs[uiId] then
        warn("[UIRegistry] Cannot toggle unregistered UI: " .. tostring(uiId))
        return false
    end
    
    local uiData = self.registeredUIs[uiId]
    
    if uiData.visible then
        return self:hideUI(uiId)
    else
        return self:showUI(uiId, ...)
    end
end

-- Check if a UI is currently visible
function UIRegistry:isUIVisible(uiId)
    if not uiId or not self.registeredUIs[uiId] then
        return false
    end
    
    return self.registeredUIs[uiId].visible
end

-- Show a notification toast
function UIRegistry:showNotification(message, type, duration)
    -- Use DialogFactory if available
    if self.DialogFactory and typeof(self.DialogFactory.createNotification) == "function" then
        self.DialogFactory.createNotification(message, duration or 3, type or "info")
        return true
    end
    
    -- Fallback implementation
    local player = Players.LocalPlayer
    if not player then return false end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    -- Create notification container if needed
    local notificationGui = playerGui:FindFirstChild("NotificationGui")
    if not notificationGui then
        notificationGui = Instance.new("ScreenGui")
        notificationGui.Name = "NotificationGui"
        notificationGui.ResetOnSpawn = false
        notificationGui.Parent = playerGui
        
        -- Create container
        local container = Instance.new("Frame")
        container.Name = "NotificationContainer"
        container.Size = UDim2.new(0, 300, 1, -20)
        container.Position = UDim2.new(1, -320, 0, 10)
        container.BackgroundTransparency = 1
        container.Parent = notificationGui
        
        -- Add layout
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 10)
        layout.Parent = container
    end
    
    -- Colors based on type
    local colors = {
        info = Color3.fromRGB(80, 170, 240),
        success = Color3.fromRGB(40, 180, 100),
        warning = Color3.fromRGB(255, 190, 0),
        error = Color3.fromRGB(220, 50, 50)
    }
    
    local container = notificationGui.NotificationContainer
    
    -- Create notification
    local notification = Instance.new("Frame")
    notification.Name = "Notification_" .. os.time()
    notification.Size = UDim2.new(1, 0, 0, 50)
    notification.BackgroundColor3 = colors[type or "info"]
    notification.BackgroundTransparency = 0.2
    notification.LayoutOrder = #container:GetChildren() * -1
    notification.Parent = container
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    -- Message text
    local messageText = Instance.new("TextLabel")
    messageText.Name = "Message"
    messageText.Size = UDim2.new(1, -20, 1, 0)
    messageText.Position = UDim2.new(0, 10, 0, 0)
    messageText.BackgroundTransparency = 1
    messageText.Font = Enum.Font.Gotham
    messageText.TextSize = 16
    messageText.TextColor3 = Color3.new(1, 1, 1)
    messageText.TextWrapped = true
    messageText.Text = message
    messageText.TextXAlignment = Enum.TextXAlignment.Left
    messageText.TextYAlignment = Enum.TextYAlignment.Center
    messageText.Parent = notification
    
    -- Animate in
    notification.Position = UDim2.new(1, 0, 0, 0)
    TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    ):Play()
    
    -- Remove after duration
    task.delay(duration or 3, function()
        -- Animate out
        local animOut = TweenService:Create(
            notification,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 0, 0, 0)}
        )
        animOut:Play()
        
        -- Destroy after animation
        animOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
    
    return true
end

-- Show a confirmation dialog
function UIRegistry:showConfirmDialog(title, message, confirmCallback, cancelCallback)
    -- Use DialogFactory if available
    if self.DialogFactory and typeof(self.DialogFactory.createConfirmDialog) == "function" then
        return self.DialogFactory.createConfirmDialog(title, message, confirmCallback, cancelCallback)
    end
    
    -- Fallback implementation
    local player = Players.LocalPlayer
    if not player then return false end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    -- Create dialog GUI
    local dialogGui = Instance.new("ScreenGui")
    dialogGui.Name = "ConfirmDialog_" .. os.time()
    dialogGui.ResetOnSpawn = false
    dialogGui.Parent = playerGui
    
    -- Create modal background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.Parent = dialogGui
    
    -- Create dialog frame
    local dialogFrame = Instance.new("Frame")
    dialogFrame.Name = "DialogFrame"
    dialogFrame.Size = UDim2.new(0, 400, 0, 200)
    dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    dialogFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    dialogFrame.Parent = dialogGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = dialogFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    titleBar.Parent = dialogFrame
    
    -- Add corner to title bar
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -20, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.TextColor3 = Color3.new(1, 1, 1)
    titleText.Text = title
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Message text
    local messageText = Instance.new("TextLabel")
    messageText.Name = "Message"
    messageText.Size = UDim2.new(1, -40, 0, 80)
    messageText.Position = UDim2.new(0, 20, 0, 50)
    messageText.BackgroundTransparency = 1
    messageText.Font = Enum.Font.Gotham
    messageText.TextSize = 16
    messageText.TextColor3 = Color3.new(1, 1, 1)
    messageText.Text = message
    messageText.TextWrapped = true
    messageText.Parent = dialogFrame
    
    -- Confirm button
    local confirmButton = Instance.new("TextButton")
    confirmButton.Name = "ConfirmButton"
    confirmButton.Size = UDim2.new(0, 150, 0, 40)
    confirmButton.Position = UDim2.new(0, 20, 1, -50)
    confirmButton.BackgroundColor3 = Color3.fromRGB(40, 180, 100)
    confirmButton.Font = Enum.Font.GothamBold
    confirmButton.TextSize = 16
    confirmButton.TextColor3 = Color3.new(1, 1, 1)
    confirmButton.Text = "Confirm"
    confirmButton.Parent = dialogFrame
    
    -- Add corner to confirm button
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 8)
    confirmCorner.Parent = confirmButton
    
    -- Cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(0, 150, 0, 40)
    cancelButton.Position = UDim2.new(1, -170, 1, -50)
    cancelButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    cancelButton.Font = Enum.Font.GothamBold
    cancelButton.TextSize = 16
    cancelButton.TextColor3 = Color3.new(1, 1, 1)
    cancelButton.Text = "Cancel"
    cancelButton.Parent = dialogFrame
    
    -- Add corner to cancel button
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 8)
    cancelCorner.Parent = cancelButton
    
    -- Connect callbacks
    confirmButton.MouseButton1Click:Connect(function()
        if confirmCallback then confirmCallback() end
        dialogGui:Destroy()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        if cancelCallback then cancelCallback() end
        dialogGui:Destroy()
    end)
    
    -- Handle background click to cancel
    background.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if cancelCallback then cancelCallback() end
            dialogGui:Destroy()
        end
    end)
    
    -- Animate dialog appearing
    dialogFrame.Size = UDim2.new(0, 0, 0, 0)
    
    TweenService:Create(
        dialogFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 400, 0, 200)}
    ):Play()
    
    return dialogGui
end

-- Create a basic UI container
function UIRegistry:createUIContainer(name, size, position, parent)
    size = size or UDim2.new(0.8, 0, 0.8, 0)
    position = position or UDim2.new(0.5, 0, 0.5, 0)
    
    -- Create ScreenGui if no parent provided
    local screenGui
    if not parent then
        parent = Players.LocalPlayer:FindFirstChild("PlayerGui")
        
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = name .. "GUI"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = parent
        
        parent = screenGui
    end
    
    -- Create main frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Apply styling if UIStyle is available
    if self.UIStyle then
        frame.BackgroundColor3 = self.UIStyle.Colors.Background
    else
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    end
    
    frame.Parent = parent
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Return the container with the screenGui if we created one
    if screenGui then
        return frame, screenGui
    else
        return frame
    end
end

-- Handle keyboard input (Escape to close modal)
local function handleKeyboard(input)
    if input.KeyCode == Enum.KeyCode.Escape then
        -- Close modal UIs when Escape is pressed
        if UIRegistry.modalActive and UIRegistry.activeModalId then
            local uiData = UIRegistry.registeredUIs[UIRegistry.activeModalId]
            
            if uiData and uiData.options.closeOnEscape then
                UIRegistry:hideUI(UIRegistry.activeModalId)
            end
        end
    end
end

-- Initialize the registry
function UIRegistry:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing UIRegistry")
    
    -- Connect escape key for closing modal UIs
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
            handleKeyboard(input)
        end
    end)
    
    -- Register self with ClientRegistry if available
    if ClientRegistry and typeof(ClientRegistry.registerSystem) == "function" then
        ClientRegistry:registerSystem("UIRegistry", self)
    end
    
    -- Set initialized flag
    self.initialized = true
    log("UIRegistry initialized")
    
    -- Register with global context
    if _G and not _G.UIRegistry then
        _G.UIRegistry = self
    end
    
    return true
end

-- Auto-initialize
if LocalPlayer then
    UIRegistry:initialize()
end

return UIRegistry
