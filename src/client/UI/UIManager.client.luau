--[[
    UIManager.client.luau
    
    Central UI management module for controlling all UI screens and elements.
    Provides a standardized way to register, access, and toggle UI components.
    
    Author: Updated April 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Get required modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared") or ReplicatedStorage:FindFirstChild("Shared")
local clientFolder = script.Parent.Parent

-- Safely require a module
local function requireSafely(moduleScript)
    if moduleScript and moduleScript:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            return result
        else
            warn("Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
            return nil
        end
    end
    return nil
end

-- Required modules
local UIUtils = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIUtils"))
local UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))
local Signal = requireSafely(sharedFolder and sharedFolder:FindFirstChild("Signal"))

-- Create manager
local UIManager = {
    _initialized = false,
    _menus = {}, -- Stores all menu references
    _activeMenus = {}, -- Tracks currently visible menus
    _menuInstances = {},
    _buttons = {}, -- Toggle buttons
    _notificationQueue = {},
    _processingNotifications = false,
    _notificationDisplayTime = 3,
    
    -- Signals
    MenuOpened = Signal and Signal.new() or { Connect = function() end },
    MenuClosed = Signal and Signal.new() or { Connect = function() end },
    NotificationShown = Signal and Signal.new() or { Connect = function() end },
}

-- Track if the PlayerGui has loaded
local playerGuiReady = false
local onPlayerGuiReadyCallbacks = {}

-- Configuration
local config = {
    notificationDisplayTime = 3,
    maxActiveMenus = 3,
    menuTransitionTime = 0.3,
    menuFadeType = "spring", -- "linear" or "spring"
    compatibilityMode = false,
    logging = false,
}

-- Debug log function
local function log(...)
    if config.logging then
        print("[UIManager]", ...)
    end
end

-- Wait for PlayerGui
local function onPlayerGuiReady(callback)
    if playerGuiReady then
        callback(LocalPlayer:FindFirstChild("PlayerGui"))
    else
        table.insert(onPlayerGuiReadyCallbacks, callback)
    end
end

-- Initialize the UI Manager
function UIManager:Initialize()
    if self._initialized then
        return self
    end
    
    log("Initializing UIManager...")
    
    -- Wait for player GUI
    if LocalPlayer:FindFirstChild("PlayerGui") then
        playerGuiReady = true
        -- Process any pending callbacks
        for _, callback in ipairs(onPlayerGuiReadyCallbacks) do
            callback(LocalPlayer.PlayerGui)
        end
        onPlayerGuiReadyCallbacks = {}
    else
        LocalPlayer.ChildAdded:Connect(function(child)
            if child.Name == "PlayerGui" then
                playerGuiReady = true
                -- Process any pending callbacks
                for _, callback in ipairs(onPlayerGuiReadyCallbacks) do
                    callback(child)
                end
                onPlayerGuiReadyCallbacks = {}
            end
        end)
    end
    
    -- Create the notification system
    self:InitializeNotifications()
    
    -- Create a global screen for elements that need to persist
    onPlayerGuiReady(function(playerGui)
        -- Create global UI container if it doesn't exist
        if not playerGui:FindFirstChild("UIManagerGlobal") then
            local globalContainer = Instance.new("ScreenGui")
            globalContainer.Name = "UIManagerGlobal"
            globalContainer.ResetOnSpawn = false
            globalContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            globalContainer.Parent = playerGui
        end
    end)
    
    self._initialized = true
    return self
end

-- Register a menu with the UI manager
function UIManager:RegisterMenu(menuName, menuInstance, toggleButton, config)
    if not menuName or not menuInstance then
        warn("Failed to register menu: Missing menuName or menuInstance")
        return
    end
    
    log("Registering menu:", menuName)
    
    -- Store menu data
    self._menus[menuName] = {
        instance = menuInstance,
        toggleButton = toggleButton,
        config = config or {},
        visible = false,
    }
    
    -- Set up close handlers
    self:SetupCloseHandler(menuName, menuInstance)
    
    -- Connect toggle button if provided
    if toggleButton and toggleButton.MouseButton1Click then
        toggleButton.MouseButton1Click:Connect(function()
            self:ToggleMenu(menuName)
        end)
    end
    
    return self._menus[menuName]
end

-- Setup close handler for a menu
function UIManager:SetupCloseHandler(menuName, menuInstance)
    -- Find close button in the menu instance
    local mainFrame = menuInstance
    if menuInstance.MainFrame then
        mainFrame = menuInstance.MainFrame
    elseif menuInstance.mainFrame then
        mainFrame = menuInstance.mainFrame
    end
    
    local closeButton = mainFrame:FindFirstChild("CloseButton")
    if not closeButton then
        -- Look deeper
        for _, child in ipairs(mainFrame:GetChildren()) do
            if child.Name == "CloseButton" or child.Name:match("^.*CloseButton$") then
                closeButton = child
                break
            end
        end
    end
    
    if closeButton and closeButton:IsA("GuiButton") then
        closeButton.MouseButton1Click:Connect(function()
            self:CloseMenu(menuName)
        end)
        log("Close handler set up for menu:", menuName)
    else
        log("No close button found for menu:", menuName)
    end
end

-- Toggle a menu's visibility
function UIManager:ToggleMenu(menuName)
    if not self._menus[menuName] then
        warn("Menu not registered:", menuName)
        return
    end
    
    local menu = self._menus[menuName]
    
    if menu.visible then
        self:CloseMenu(menuName)
    else
        self:OpenMenu(menuName)
    end
end

-- Open a menu
function UIManager:OpenMenu(menuName, forceOpen)
    if not self._menus[menuName] then
        warn("Menu not registered:", menuName)
        return
    end
    
    local menu = self._menus[menuName]
    
    -- If already visible, do nothing
    if menu.visible and not forceOpen then
        return
    end
    
    log("Opening menu:", menuName)
    
    -- Check if we need to close other menus first
    local exclusiveGroup = menu.config.exclusiveGroup
    if exclusiveGroup then
        for name, otherMenu in pairs(self._menus) do
            if name ~= menuName and otherMenu.config.exclusiveGroup == exclusiveGroup and otherMenu.visible then
                self:CloseMenu(name)
            end
        end
    end
    
    -- Show the menu
    local mainFrame = menu.instance
    if menu.instance.MainFrame then
        mainFrame = menu.instance.MainFrame
    elseif menu.instance.mainFrame then
        mainFrame = menu.instance.mainFrame
    end
    
    mainFrame.Visible = true
    menu.visible = true
    self._activeMenus[menuName] = true
    
    -- Trigger the MenuOpened signal
    self.MenuOpened:Fire(menuName, menu)
    
    return menu
end

-- Close a menu
function UIManager:CloseMenu(menuName)
    if not self._menus[menuName] then
        warn("Menu not registered:", menuName)
        return
    end
    
    local menu = self._menus[menuName]
    
    -- If not visible, do nothing
    if not menu.visible then
        return
    end
    
    log("Closing menu:", menuName)
    
    -- Hide the menu
    local mainFrame = menu.instance
    if menu.instance.MainFrame then
        mainFrame = menu.instance.MainFrame
    elseif menu.instance.mainFrame then
        mainFrame = menu.instance.mainFrame
    end
    
    mainFrame.Visible = false
    menu.visible = false
    self._activeMenus[menuName] = nil
    
    -- Trigger the MenuClosed signal
    self.MenuClosed:Fire(menuName, menu)
end

-- Close all active menus
function UIManager:CloseAllMenus(exceptMenuName)
    for menuName, _ in pairs(self._activeMenus) do
        if menuName ~= exceptMenuName then
            self:CloseMenu(menuName)
        end
    end
end

-- Initialize the notification system
function UIManager:InitializeNotifications()
    onPlayerGuiReady(function(playerGui)
        -- Create notification container if it doesn't exist
        if not playerGui:FindFirstChild("UIManagerNotifications") then
            local notificationGui = Instance.new("ScreenGui")
            notificationGui.Name = "UIManagerNotifications"
            notificationGui.ResetOnSpawn = false
            notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            notificationGui.Parent = playerGui
            
            -- Add container for notifications
            local container = Instance.new("Frame")
            container.Name = "NotificationContainer"
            container.Size = UDim2.new(0, 300, 0.5, 0)
            container.Position = UDim2.new(0.5, -150, 0.25, 0)
            container.BackgroundTransparency = 1
            container.Parent = notificationGui
            
            -- Add list layout for notifications
            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 10)
            listLayout.FillDirection = Enum.FillDirection.Vertical
            listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = container
            
            self._notificationContainer = container
        else
            self._notificationContainer = playerGui.UIManagerNotifications.NotificationContainer
        end
    end)
end

-- Create a tabbed menu
function UIManager:CreateTabbedMenu(menuName, title, tabs, size, position)
    if not UIUtils then
        warn("UIUtils module is required to create tabbed menus")
        return nil
    end
    
    log("Creating tabbed menu:", menuName)
    
    -- Create the menu container
    local container = UIUtils.createMenuContainer(menuName, title, size, position)
    
    -- Create tab system
    local tabSystem = UIUtils.createTabSystem(container.mainFrame, tabs)
    
    -- Register the menu
    self:RegisterMenu(menuName, container)
    
    -- Store the menu instance
    self._menuInstances[menuName] = {
        container = container,
        tabSystem = tabSystem,
        tabs = tabs
    }
    
    return {
        container = container,
        tabSystem = tabSystem,
        tabs = tabs
    }
end

-- Show a notification
function UIManager:ShowNotification(message, duration, priority)
    if not self._notificationContainer then
        -- Queue the notification for when the container is ready
        table.insert(self._notificationQueue, {
            message = message,
            duration = duration,
            priority = priority
        })
        return
    end
    
    -- Create notification UI
    duration = duration or self._notificationDisplayTime
    priority = priority or 0
    
    log("Showing notification:", message)
    
    -- Create using UIUtils if available
    if UIUtils and UIUtils.createNotification then
        local notification = UIUtils.createNotification(
            self._notificationContainer,
            message,
            duration
        )
        self.NotificationShown:Fire(message)
        return notification
    end
    
    -- Fallback to manual creation
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "Notification" .. tostring(#self._notificationContainer:GetChildren())
    notificationFrame.Size = UDim2.new(1, -20, 0, 60)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    notificationFrame.BackgroundTransparency = 0.1
    notificationFrame.BorderSizePixel = 0
    notificationFrame.LayoutOrder = -priority -- Higher priority appears on top
    notificationFrame.Parent = self._notificationContainer
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    -- Add message label
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 1, -10)
    messageLabel.Position = UDim2.new(0, 10, 0, 5)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.TextSize = 14
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Center
    messageLabel.TextYAlignment = Enum.TextYAlignment.Center
    messageLabel.Parent = notificationFrame
    
    -- Set initial properties for animation
    notificationFrame.Position = UDim2.new(0, 0, 0, 0)
    notificationFrame.BackgroundTransparency = 1
    messageLabel.TextTransparency = 1
    
    -- Fade in animation
    game:GetService("TweenService"):Create(
        notificationFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.1 }
    ):Play()
    
    game:GetService("TweenService"):Create(
        messageLabel,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { TextTransparency = 0 }
    ):Play()
    
    -- Remove after duration
    task.delay(duration, function()
        -- Fade out animation
        game:GetService("TweenService"):Create(
            notificationFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }
        ):Play()
        
        game:GetService("TweenService"):Create(
            messageLabel,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { TextTransparency = 1 }
        ):Play()
        
        -- Destroy after animation completes
        task.delay(0.6, function()
            notificationFrame:Destroy()
        end)
    end)
    
    self.NotificationShown:Fire(message)
    return notificationFrame
end

-- Process the notification queue
function UIManager:ProcessNotificationQueue()
    if self._processingNotifications or #self._notificationQueue == 0 or not self._notificationContainer then
        return
    end
    
    self._processingNotifications = true
    
    -- Process all queued notifications
    while #self._notificationQueue > 0 do
        local notification = table.remove(self._notificationQueue, 1)
        self:ShowNotification(notification.message, notification.duration, notification.priority)
        task.wait(0.2) -- Small delay between notifications
    end
    
    self._processingNotifications = false
end

-- Create a toggle button
function UIManager:CreateToggleButton(text, iconName, position, callback)
    if not UIUtils or not UIUtils.createToggleButton then
        warn("UIUtils module is required to create toggle buttons")
        return nil
    end
    
    local button = UIUtils.createToggleButton(text, iconName, position, callback)
    
    if button then
        self._buttons[text] = button
    end
    
    return button
end

-- Configure the manager
function UIManager:Configure(newConfig)
    if not newConfig then return end
    
    for key, value in pairs(newConfig) do
        config[key] = value
    end
    
    -- Apply configuration changes
    self._notificationDisplayTime = config.notificationDisplayTime or 3
    
    return self
end

-- Expose public API for other scripts
return UIManager:Initialize()