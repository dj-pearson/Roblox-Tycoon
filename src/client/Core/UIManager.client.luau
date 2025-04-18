-- UIManager.luau
-- Centralized system for managing UI elements
-- Place in StarterPlayer/StarterPlayerScripts/Core

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Import the ClientRegistry
local ClientRegistry = require(script.Parent.ClientRegistry)
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
local UIHub -- Will be set after initialization

-- Configuration
local CONFIG = {
    debugEnabled = true,
    uiModulesFolder = "UIModules", -- Folder in ReplicatedStorage for UI templates
    zIndexLevels = {
        background = 1,
        main = 10,
        modal = 100,
        notification = 500,
        tooltip = 900,
        topmost = 1000
    },
    defaultTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    
    -- Control Panel Settings
    controlPanel = {
        defaultPosition = UDim2.new(1, -10, 0, 10), -- Top right
        defaultAnchorPoint = Vector2.new(1, 0),
        width = 200,
        minHeight = 300,
        maxHeight = 500,
    },
    
    -- UI Hub integration
    useUIHub = true, -- Enable/disable the UI Hub
    hideLegacyButtons = true, -- Hide legacy buttons when using UI Hub
}

-- Create the UIManager system
local UIManager = {
    -- Internal state
    activeUIs = {},
    uiHistory = {},
    uiCounter = 0,
    uiFolders = {},
    controlPanel = nil
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[UIManager]", ...)
    end
end

-- Initialize the UIManager
function UIManager:initialize()
    log("Initializing UIManager...")
    
    -- Create main UI folders
    self:createUIFolders()
    
    -- Set up event handlers
    self:setupEventHandlers()
    
    -- Create and set up control panel
    self:setupControlPanel()
    
    -- Initialize UI Hub if enabled
    if CONFIG.useUIHub then
        task.delay(1, function() -- Slight delay to ensure UIHub is registered
            UIHub = ClientRegistry.getSystem("UIHub")
            if UIHub then
                UIHub.initialize()
                
                -- Hide legacy buttons if configured
                if CONFIG.hideLegacyButtons then
                    UIHub.hideLegacyButtons()
                end
                
                log("UI Hub initialized")
            else
                log("UI Hub system not found")
            end
        end)
    end
    
    log("UIManager initialized")
    return true
end

-- Create the necessary UI folders in PlayerGui
function UIManager:createUIFolders()
    -- Create a folder for different UI categories
    local categories = {
        "Main",          -- Main UI elements
        "Overlays",      -- UI that overlays the main UI
        "Popups",        -- Modal popup dialogs
        "Notifications", -- Temporary notifications
        "HUD",           -- Heads-up display elements
        "Tooltips",      -- Tooltip elements
        "SaunaTemperatureUI",     -- Tooltip elements
    }
    
    for _, category in ipairs(categories) do
        local folder = PlayerGui:FindFirstChild(category)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = category
            folder.Parent = PlayerGui
        end
        
        -- Store reference
        self.uiFolders[category] = folder
    end
    
    log("Created UI folders")
end

-- Set up event handlers for UI-related events
function UIManager:setupEventHandlers()
    if not ClientEventBridge then
        log("ClientEventBridge not available, couldn't set up event handlers")
        return
    end
    
    -- Handle notification events
    ClientEventBridge.connectEvent("ShowNotification", function(data)
        self:showNotification(data)
    end)
    
    -- Handle UI open/close events
    ClientEventBridge.connectEvent("OpenUI", function(uiName, data)
        self:openUI(uiName, data)
    end)
    
    ClientEventBridge.connectEvent("CloseUI", function(uiName)
        self:closeUI(uiName)
    end)
    
    -- Handle specialization UI events
    ClientEventBridge.connectEvent("ShowSpecializationUI", function(data)
        self:openUI("SpecializationMenu", data)
    end)
    
    log("Set up event handlers")
end

-- Setup the control panel
function UIManager:setupControlPanel()
    -- Create the control panel if it doesn't exist
    if PlayerGui:FindFirstChild("ControlPanel") then
        self.controlPanel = PlayerGui.ControlPanel
    else
        local panel = Instance.new("ScreenGui")
        panel.Name = "ControlPanel"
        panel.ResetOnSpawn = false
        panel.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        panel.Parent = PlayerGui
        
        -- Main frame
        local frame = Instance.new("Frame")
        frame.Name = "MainFrame"
        frame.Size = UDim2.new(0, CONFIG.controlPanel.width, 0, CONFIG.controlPanel.minHeight)
        frame.Position = CONFIG.controlPanel.defaultPosition
        frame.AnchorPoint = CONFIG.controlPanel.defaultAnchorPoint
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = panel
        
        -- Make it rounded
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        -- Title bar
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 30)
        titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        titleBar.BackgroundTransparency = 0.1
        titleBar.BorderSizePixel = 0
        titleBar.Parent = frame
        
        -- Round title bar corners 
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 8)
        titleCorner.Parent = titleBar
        
        -- Fix bottom corners of title bar
        local bottomFix = Instance.new("Frame")
        bottomFix.Name = "BottomFix"
        bottomFix.Size = UDim2.new(1, 0, 0.5, 0)
        bottomFix.Position = UDim2.new(0, 0, 0.5, 0)
        bottomFix.BackgroundColor3 = titleBar.BackgroundColor3
        bottomFix.BackgroundTransparency = titleBar.BackgroundTransparency
        bottomFix.BorderSizePixel = 0
        bottomFix.ZIndex = titleBar.ZIndex - 1
        bottomFix.Parent = titleBar
        
        -- Title text
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -10, 1, 0)
        title.Position = UDim2.new(0, 10, 0, 0)
        title.BackgroundTransparency = 1
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "Gym Tycoon"
        title.Parent = titleBar
        
        -- Close button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Size = UDim2.new(0, 24, 0, 24)
        closeBtn.Position = UDim2.new(1, -5, 0.5, 0)
        closeBtn.AnchorPoint = Vector2.new(1, 0.5)
        closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        closeBtn.Text = "X"
        closeBtn.TextSize = 14
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = titleBar
        
        -- Make close button rounded
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0.5, 0)
        closeCorner.Parent = closeBtn
        
        -- Content frame for buttons
        local content = Instance.new("ScrollingFrame")
        content.Name = "Content"
        content.Size = UDim2.new(1, -16, 1, -40)  -- Padding for scrollbar and title bar
        content.Position = UDim2.new(0, 8, 0, 35)
        content.BackgroundTransparency = 1
        content.ScrollBarThickness = 4
        content.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200)
        content.CanvasSize = UDim2.new(0, 0, 0, 0)  -- Will be set dynamically
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        content.Parent = frame
        
        -- Layout for content
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 5)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = content
        
        -- Store reference to control panel
        self.controlPanel = panel
        
        -- Connect close button
        closeBtn.MouseButton1Click:Connect(function()
            self:toggleControlPanel()
        end)
        
        -- Make it draggable
        self:makeFrameDraggable(frame, titleBar)
        
        log("Created control panel")
    end
    
    -- Add buttons to the control panel
    self:addControlPanelButtons()
end

-- Add standard buttons to the control panel
function UIManager:addControlPanelButtons()
    if not self.controlPanel then return end
    
    local content = self.controlPanel.MainFrame.Content
    
    -- Clear existing buttons
    for _, child in pairs(content:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Standard buttons to add
    local buttons = {
        {
            name = "Specializations",
            text = "Specializations",
            callback = function()
                ClientEventBridge.fireServerEvent("GetAvailableSpecializations")
            end,
            color = Color3.fromRGB(0, 120, 215)
        },
        {
            name = "Milestones",
            text = "Milestones",
            callback = function()
                self:openUI("MilestonesMenu")
            end,
            color = Color3.fromRGB(0, 150, 80)
        },
        {
            name = "StaffManagement",
            text = "Staff Management",
            callback = function()
                self:openUI("StaffManagement")
            end,
            color = Color3.fromRGB(180, 80, 180)
        },
        {
            name = "Settings",
            text = "Settings",
            callback = function()
                self:openUI("SettingsMenu")
            end,
            color = Color3.fromRGB(100, 100, 100)
        }
    }
    
    -- Create the buttons
    for i, buttonInfo in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Name = buttonInfo.name
        button.Size = UDim2.new(1, 0, 0, 40)
        button.LayoutOrder = i
        button.BackgroundColor3 = buttonInfo.color
        button.BorderSizePixel = 0
        button.Text = buttonInfo.text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 16
        button.Font = Enum.Font.Gotham
        
        -- Add rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        
        -- Connect function
        button.MouseButton1Click:Connect(buttonInfo.callback)
        
        -- Add hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.new(
                buttonInfo.color.R * 1.1,
                buttonInfo.color.G * 1.1,
                buttonInfo.color.B * 1.1
            )
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = buttonInfo.color
        end)
        
        button.Parent = content
    end
    
    log("Added control panel buttons")
end

-- Make a frame draggable using a drag handle
function UIManager:makeFrameDraggable(frame, dragHandle)
    if not frame or not dragHandle then return end
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                updateInput(input)
            end
        end
    end)
end

-- Toggle the control panel visibility
function UIManager:toggleControlPanel()
    if not self.controlPanel then return end
    
    local frame = self.controlPanel.MainFrame
    local visible = frame.Visible
    
    if visible then
        -- Hide with animation
        local tween = TweenService:Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, frame.Position.Y.Scale, frame.Position.Y.Offset)}
        )
        
        tween:Play()
        tween.Completed:Connect(function()
            frame.Visible = false
        end)
    else
        -- Show with animation
        frame.Position = UDim2.new(1, 10, frame.Position.Y.Scale, frame.Position.Y.Offset)
        frame.Visible = true
        
        local tween = TweenService:Create(
            frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -10, frame.Position.Y.Scale, frame.Position.Y.Offset)}
        )
        
        tween:Play()
    end
end

-- Show a notification
function UIManager:showNotification(data)
    if not data then return end
    
    -- Default values
    local title = data.title or "Notification"
    local message = data.message or ""
    local duration = data.duration or 5
    local notificationType = data.type or "info"
    
    -- Get notifications folder
    local notificationsFolder = self.uiFolders.Notifications
    if not notificationsFolder then
        notificationsFolder = Instance.new("Folder")
        notificationsFolder.Name = "Notifications"
        notificationsFolder.Parent = PlayerGui
        self.uiFolders.Notifications = notificationsFolder
    end
    
    -- Create notification ID
    local notificationId = "notification_" .. self.uiCounter
    self.uiCounter = self.uiCounter + 1
    
    -- Create notification frame
    local notif = Instance.new("Frame")
    notif.Name = notificationId
    notif.Size = UDim2.new(0, 300, 0, 80)
    notif.Position = UDim2.new(1, 10, 0.8, 0)
    notif.AnchorPoint = Vector2.new(1, 1)
    notif.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notif.BackgroundTransparency = 0.1
    notif.BorderSizePixel = 0
    notif.Parent = notificationsFolder
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif
    
    -- Add color based on notification type
    local typeColor
    if notificationType == "success" then
        typeColor = Color3.fromRGB(0, 180, 0)
    elseif notificationType == "warning" then
        typeColor = Color3.fromRGB(255, 150, 0)
    elseif notificationType == "error" then
        typeColor = Color3.fromRGB(255, 50, 50)
    else
        typeColor = Color3.fromRGB(0, 120, 215) -- info
    end
    
    -- Add color bar
    local colorBar = Instance.new("Frame")
    colorBar.Name = "ColorBar"
    colorBar.Size = UDim2.new(0, 6, 1, 0)
    colorBar.BackgroundColor3 = typeColor
    colorBar.BorderSizePixel = 0
    colorBar.Parent = notif
    
    -- Left side corner radius
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 8)
    barCorner.Parent = colorBar
    
    -- Fix right corners
    local rightFix = Instance.new("Frame")
    rightFix.Name = "RightFix"
    rightFix.Size = UDim2.new(0.5, 0, 1, 0)
    rightFix.Position = UDim2.new(0.5, 0, 0, 0)
    rightFix.BackgroundColor3 = colorBar.BackgroundColor3
    rightFix.BorderSizePixel = 0
    rightFix.ZIndex = colorBar.ZIndex - 1
    rightFix.Parent = colorBar
    
    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.new(0, 15, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = title
    titleLabel.Parent = notif
    
    -- Message text
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -20, 1, -40)
    messageLabel.Position = UDim2.new(0, 15, 0, 32)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.Text = message
    messageLabel.TextWrapped = true
    messageLabel.Parent = notif
    
    -- Animate in
    notif.Position = UDim2.new(1, 10, 0.8, 0)
    
    -- Find existing notifications and shift them up
    local existingNotifications = {}
    for _, child in ipairs(notificationsFolder:GetChildren()) do
        if child:IsA("Frame") and child ~= notif then
            table.insert(existingNotifications, child)
        end
    end
    
    -- Sort by position (bottom to top)
    table.sort(existingNotifications, function(a, b)
        return a.Position.Y.Scale > b.Position.Y.Scale
    end)
    
    -- Shift existing notifications up
    for i, notification in ipairs(existingNotifications) do
        local tween = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -10, 0.8 - (i * 0.12), 0)}
        )
        tween:Play()
    end
    
    -- Animate in
    local tweenIn = TweenService:Create(
        notif,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -10, 0.8, 0)}
    )
    tweenIn:Play()
    
    -- Set up auto-dismiss
    task.delay(duration, function()
        -- Animate out
        local tweenOut = TweenService:Create(
            notif,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, 0.8, 0)}
        )
        tweenOut:Play()
        
        tweenOut.Completed:Connect(function()
            notif:Destroy()
        end)
    end)
    
    log("Showed notification: " .. title)
    return notificationId
end

-- Open a UI by name
function UIManager:openUI(uiName, data)
    if not uiName then return end
    
    -- Check if UI is already open
    if self.activeUIs[uiName] then
        log("UI already open: " .. uiName)
        return
    end
    
    -- Try to find UI module in ReplicatedStorage
    local uiModulesFolder = ReplicatedStorage:FindFirstChild(CONFIG.uiModulesFolder)
    if not uiModulesFolder then
        -- Check in shared folder
        uiModulesFolder = ReplicatedStorage:FindFirstChild("shared")
    end
    
    if not uiModulesFolder then
        log("UI modules folder not found")
        return
    end
    
    local uiModule = uiModulesFolder:FindFirstChild(uiName)
    if not uiModule then
        log("UI module not found: " .. uiName)
        return
    end
    
    -- Try to load the UI module
    local success, uiCreator = pcall(function()
        return require(uiModule)
    end)
    
    if not success or not uiCreator.create then
        log("Failed to load UI module: " .. uiName)
        return
    end
    
    -- Create the UI
    local ui = uiCreator.create(data)
    if not ui then
        log("Failed to create UI: " .. uiName)
        return
    end
    
    -- Store the UI
    self.activeUIs[uiName] = {
        ui = ui,
        module = uiCreator,
        data = data
    }
    
    -- Add to UI history
    table.insert(self.uiHistory, uiName)
    
    -- Call open function if it exists
    if uiCreator.open then
        uiCreator.open(ui, data)
    end
    
    log("Opened UI: " .. uiName)
    return ui
end

-- Close a UI by name
function UIManager:closeUI(uiName)
    if not uiName or not self.activeUIs[uiName] then return end
    
    local uiData = self.activeUIs[uiName]
    
    -- Call close function if it exists
    if uiData.module and uiData.module.close then
        uiData.module.close(uiData.ui)
    else
        -- Default destruction
        if typeof(uiData.ui) == "Instance" then
            uiData.ui:Destroy()
        end
    end
    
    -- Remove from active UIs
    self.activeUIs[uiName] = nil
    
    -- Remove from UI history
    for i, name in ipairs(self.uiHistory) do
        if name == uiName then
            table.remove(self.uiHistory, i)
            break
        end
    end
    
    log("Closed UI: " .. uiName)
    return true
end

-- Close all UIs
function UIManager:closeAllUIs()
    local uiNames = {}
    for name in pairs(self.activeUIs) do
        table.insert(uiNames, name)
    end
    
    for _, name in ipairs(uiNames) do
        self:closeUI(name)
    end
    
    self.uiHistory = {}
    log("Closed all UIs")
end

-- Get the UI folder for a category
function UIManager:getUIFolder(category)
    if not category then
        category = "Main"
    end
    
    return self.uiFolders[category] or self.uiFolders.Main
end

-- Public API
local PublicAPI = {
    initialize = function()
        return UIManager:initialize()
    end,
    
    showNotification = function(data)
        return UIManager:showNotification(data)
    end,
    
    openUI = function(uiName, data)
        return UIManager:openUI(uiName, data)
    end,
    
    closeUI = function(uiName)
        return UIManager:closeUI(uiName)
    end,
    
    closeAllUIs = function()
        return UIManager:closeAllUIs()
    end,
    
    toggleControlPanel = function()
        return UIManager:toggleControlPanel()
    end,
    
    getUIFolder = function(category)
        return UIManager:getUIFolder(category)
    end,
    
    makeFrameDraggable = function(frame, dragHandle)
        return UIManager:makeFrameDraggable(frame, dragHandle)
    end,
    
    getConfig = function()
        return CONFIG
    end,
    
    -- New methods for UI Hub integration
    toggleUIHub = function()
        if UIHub then
            return UIHub.toggle()
        end
        return false
    end
}

-- Register with ClientRegistry
return ClientRegistry.registerSystem("UIManager", PublicAPI, {"ClientEventBridge"})