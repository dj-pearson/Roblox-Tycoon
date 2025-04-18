-- UIHub.client.luau
-- Centralized UI management system
-- Part of UI refinements initiative (April 2025)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Import required modules
local UIStyle = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("UIStyle"))

-- Private variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ClientRegistry
local UIManager

-- Module table
local UIHub = {}

-- Hub state
local hubState = {
    menuItems = {},
    categories = {
        management = { name = "Management", icon = UIStyle.icons.settings, priority = 10 },
        progress = { name = "Progress", icon = UIStyle.icons.success, priority = 20 },
        facility = { name = "Facility", icon = "rbxassetid://7059249296", priority = 30 }, -- Building icon
        settings = { name = "Settings", icon = UIStyle.icons.settings, priority = 40 }
    },
    activePanels = {},
    legacyButtons = {},
    initialized = false,
    mainGuiVisible = true,
    sidebarExpanded = true,
    debugMode = false
}

-- UI Elements
local uiElements = {
    mainGui = nil,
    sidebarContainer = nil,
    mainContainer = nil,
    categoryContainers = {},
    menuButtons = {}
}

-- Forward declarations for internal functions
local createMainGui, createSidebar, createMainContainer
local addMenuButton, handleMenuItemClick, toggleSidebar
local updateCategoryVisibility, logDebug

-- Initialize the UIHub system
function UIHub:initialize()
    if hubState.initialized then
        return true
    end
    
    -- Get dependencies
    ClientRegistry = require(script.Parent.Parent.Core.ClientRegistry)
    UIManager = ClientRegistry.getSystem("UIManager")
    
    if not UIManager then
        warn("[UIHub] UIManager dependency not found. Initialization failed.")
        return false
    end
    
    -- Setup UI
    createMainGui()
    createSidebar()
    createMainContainer()
    
    -- Register with UIManager for global access
    if UIManager.registerGlobalUI then
        UIManager.registerGlobalUI("UIHub", self)
    end
    
    -- Setup keyboard shortcut for hub toggle (Alt+H)
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.H and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
            self:toggleVisibility()
        end
    end)
    
    hubState.initialized = true
    logDebug("UIHub initialized successfully")
    return true
end

-- Register a menu item with the UIHub
function UIHub:registerMenuItem(menuItemConfig)
    if not menuItemConfig or not menuItemConfig.id then
        warn("[UIHub] Cannot register menu item without id")
        return false
    end
    
    -- Default values
    local menuItem = {
        id = menuItemConfig.id,
        name = menuItemConfig.name or "Menu Item",
        description = menuItemConfig.description or "",
        icon = menuItemConfig.icon or UIStyle.icons.info,
        category = menuItemConfig.category or "management",
        priority = menuItemConfig.priority or 50,
        disabled = menuItemConfig.disabled or false,
        callback = menuItemConfig.callback or function() end,
        closeOnClick = menuItemConfig.closeOnClick ~= nil and menuItemConfig.closeOnClick or true
    }
    
    -- Store the menu item
    hubState.menuItems[menuItem.id] = menuItem
    
    -- If UI is already initialized, add the button immediately
    if hubState.initialized and uiElements.mainGui then
        addMenuButton(menuItem)
    end
    
    logDebug("Registered menu item: " .. menuItem.id)
    return true
end

-- Unregister a menu item
function UIHub:unregisterMenuItem(itemId)
    if not itemId or not hubState.menuItems[itemId] then
        return false
    end
    
    -- Remove the button if it exists
    if uiElements.menuButtons[itemId] then
        uiElements.menuButtons[itemId]:Destroy()
        uiElements.menuButtons[itemId] = nil
    end
    
    -- Remove from state
    hubState.menuItems[itemId] = nil
    
    logDebug("Unregistered menu item: " .. itemId)
    return true
end

-- Show the UIHub
function UIHub:show()
    if not uiElements.mainGui then
        warn("[UIHub] Cannot show UIHub GUI - not initialized")
        return
    end
    
    uiElements.mainGui.Enabled = true
    hubState.mainGuiVisible = true
    
    -- Animate sidebar in
    if uiElements.sidebarContainer then
        uiElements.sidebarContainer:TweenPosition(
            UDim2.new(0, 0, 0, 0),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quint,
            0.5,
            true
        )
    end
    
    logDebug("UIHub shown")
end

-- Hide the UIHub
function UIHub:hide()
    if not uiElements.mainGui then
        return
    end
    
    -- Animate sidebar out
    if uiElements.sidebarContainer then
        uiElements.sidebarContainer:TweenPosition(
            UDim2.new(-0.3, 0, 0, 0),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quint,
            0.5,
            true,
            function()
                uiElements.mainGui.Enabled = false
                hubState.mainGuiVisible = false
            end
        )
    else
        uiElements.mainGui.Enabled = false
        hubState.mainGuiVisible = false
    end
    
    logDebug("UIHub hidden")
end

-- Toggle UIHub visibility
function UIHub:toggleVisibility()
    if hubState.mainGuiVisible then
        self:hide()
    else
        self:show()
    end
    
    return hubState.mainGuiVisible
end

-- Open a specific UI through UIHub
function UIHub:openUI(uiId)
    if not UIManager then
        warn("[UIHub] UIManager not found, cannot open UI")
        return false
    end
    
    -- Find the menu item
    local menuItem = hubState.menuItems[uiId]
    if menuItem and menuItem.callback then
        menuItem.callback()
        return true
    end
    
    -- If no direct menu item, try to open through UIManager
    if UIManager.openUI then
        return UIManager.openUI(uiId)
    end
    
    return false
end

-- Register a legacy button that will be hidden when UIHub is active
function UIHub:registerLegacyButton(buttonInstance)
    if not buttonInstance or typeof(buttonInstance) ~= "Instance" then
        return false
    end
    
    table.insert(hubState.legacyButtons, buttonInstance)
    return true
end

-- Hide all registered legacy buttons
function UIHub:hideLegacyButtons()
    for _, button in ipairs(hubState.legacyButtons) do
        if button:IsA("GuiObject") then
            -- Store original position for restore later if needed
            button:SetAttribute("OriginalPosition", button.Position)
            button.Visible = false
        end
    end
    
    logDebug("Hidden " .. #hubState.legacyButtons .. " legacy buttons")
    return true
end

-- Show all registered legacy buttons
function UIHub:showLegacyButtons()
    for _, button in ipairs(hubState.legacyButtons) do
        if button:IsA("GuiObject") then
            button.Visible = true
            
            -- Restore original position if saved
            local originalPos = button:GetAttribute("OriginalPosition")
            if originalPos then
                button.Position = originalPos
            end
        end
    end
    
    return true
end

-- Enable/disable debug mode
function UIHub:setDebug(enabled)
    hubState.debugMode = enabled
    return hubState.debugMode
end

-- Create the main GUI container
function createMainGui()
    -- Create ScreenGui
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "UIHub"
    mainGui.ResetOnSpawn = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainGui.IgnoreGuiInset = true
    mainGui.Enabled = false
    mainGui.Parent = playerGui
    
    -- Add blur effect
    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Name = "UIHubBlur"
    blurEffect.Size = 0
    blurEffect.Enabled = false
    blurEffect.Parent = game:GetService("Lighting")
    
    -- Connect blur animation
    mainGui:GetPropertyChangedSignal("Enabled"):Connect(function()
        if mainGui.Enabled then
            blurEffect.Enabled = true
            TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 10}):Play()
        else
            TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 0}):Play()
            task.delay(0.5, function()
                blurEffect.Enabled = false
            end)
        end
    end)
    
    -- Store in elements
    uiElements.mainGui = mainGui
    uiElements.blurEffect = blurEffect
    
    return mainGui
end

-- Create the sidebar for menu items
function createSidebar()
    local mainGui = uiElements.mainGui
    if not mainGui then return end
    
    -- Create sidebar container
    local sidebarContainer = Instance.new("Frame")
    sidebarContainer.Name = "SidebarContainer"
    sidebarContainer.Size = UIStyle.sizes.sidebar.expanded
    sidebarContainer.Position = UDim2.new(-0.3, 0, 0, 0)
    sidebarContainer.BackgroundColor3 = UIStyle.colors.background
    sidebarContainer.BorderSizePixel = 0
    sidebarContainer.ZIndex = UIStyle.zIndex.foreground
    sidebarContainer.Parent = mainGui
    
    -- Add shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(1, 0.5)
    shadow.Position = UDim2.new(1, 0, 0.5, 0)
    shadow.Size = UDim2.new(0, 20, 1, 40)
    shadow.BackgroundTransparency = 1
    shadow.Image = UIStyle.icons.shadow
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = UIStyle.shadow.sliceCenter
    shadow.ZIndex = UIStyle.zIndex.foreground - 1
    shadow.Parent = sidebarContainer
    
    -- Create header
    local header = UIStyle.createHeader({
        name = "Header",
        text = "UI Hub",
        size = UDim2.new(1, 0, 0, 50),
        position = UDim2.new(0, 0, 0, 0),
        color = UIStyle.colors.headerBackground,
        includeCloseButton = false
    })
    
    -- Add toggle button
    local toggleButton = UIStyle.createButton({
        name = "ToggleButton",
        size = UDim2.new(0, 35, 0, 35),
        position = UDim2.new(1, -45, 0, 8),
        text = "≡",
        color = UIStyle.colors.primary
    })
    
    toggleButton.MouseButton1Click:Connect(function()
        toggleSidebar()
    end)
    
    toggleButton.Parent = header
    header.Parent = sidebarContainer
    
    -- Create menu container
    local menuScrollingFrame = Instance.new("ScrollingFrame")
    menuScrollingFrame.Name = "MenuContainer"
    menuScrollingFrame.Size = UDim2.new(1, 0, 1, -60)
    menuScrollingFrame.Position = UDim2.new(0, 0, 0, 50)
    menuScrollingFrame.BackgroundTransparency = 1
    menuScrollingFrame.BorderSizePixel = 0
    menuScrollingFrame.ScrollBarThickness = 6
    menuScrollingFrame.ScrollBarImageColor3 = UIStyle.colors.textSecondary
    menuScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    menuScrollingFrame.ZIndex = UIStyle.zIndex.foreground
    menuScrollingFrame.Parent = sidebarContainer
    
    -- Add padding and layout
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = menuScrollingFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.Name
    layout.Parent = menuScrollingFrame
    
    -- Create category containers
    for categoryId, category in pairs(hubState.categories) do
        -- Category header
        local categoryHeader = Instance.new("TextLabel")
        categoryHeader.Name = string.format("%02d_%s_Header", category.priority, categoryId)
        categoryHeader.Size = UDim2.new(1, 0, 0, 30)
        categoryHeader.BackgroundTransparency = 1
        categoryHeader.Text = category.name
        categoryHeader.Font = UIStyle.fonts.subheader
        categoryHeader.TextSize = UIStyle.textSizes.subheader
        categoryHeader.TextColor3 = UIStyle.colors.textSecondary
        categoryHeader.TextXAlignment = Enum.TextXAlignment.Left
        categoryHeader.ZIndex = UIStyle.zIndex.foreground
        categoryHeader.Parent = menuScrollingFrame
        
        -- Category icon
        local categoryIcon = Instance.new("ImageLabel")
        categoryIcon.Name = "CategoryIcon"
        categoryIcon.Size = UDim2.new(0, 18, 0, 18)
        categoryIcon.Position = UDim2.new(0, 0, 0.5, 0)
        categoryIcon.AnchorPoint = Vector2.new(0, 0.5)
        categoryIcon.BackgroundTransparency = 1
        categoryIcon.Image = category.icon
        categoryIcon.ImageColor3 = UIStyle.colors[categoryId] or UIStyle.colors.textSecondary
        categoryIcon.ZIndex = UIStyle.zIndex.foreground
        categoryIcon.Parent = categoryHeader
        
        -- Adjust header text for icon
        categoryHeader.UIPadding = Instance.new("UIPadding")
        categoryHeader.UIPadding.PaddingLeft = UDim.new(0, 25)
        
        -- Category container
        local categoryContainer = Instance.new("Frame")
        categoryContainer.Name = string.format("%02d_%s_Container", category.priority, categoryId)
        categoryContainer.Size = UDim2.new(1, 0, 0, 0) -- Will be auto-sized based on contents
        categoryContainer.AutomaticSize = Enum.AutomaticSize.Y
        categoryContainer.BackgroundTransparency = 1
        categoryContainer.BorderSizePixel = 0
        categoryContainer.ZIndex = UIStyle.zIndex.foreground
        categoryContainer.Parent = menuScrollingFrame
        
        -- Add layout to category
        local categoryLayout = Instance.new("UIListLayout")
        categoryLayout.Padding = UDim.new(0, 2)
        categoryLayout.SortOrder = Enum.SortOrder.Name
        categoryLayout.Parent = categoryContainer
        
        -- Add to tracked elements
        uiElements.categoryContainers[categoryId] = categoryContainer
    end
    
    -- Auto-adjust scrolling frame canvas size
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        menuScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Add existing menu items
    for _, menuItem in pairs(hubState.menuItems) do
        addMenuButton(menuItem)
    end
    
    -- Store in elements
    uiElements.sidebarContainer = sidebarContainer
    uiElements.menuScrollingFrame = menuScrollingFrame
    
    return sidebarContainer
end

-- Create the main content container
function createMainContainer()
    local mainGui = uiElements.mainGui
    if not mainGui then return end
    
    -- Create main container
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, -250, 1, 0)
    mainContainer.Position = UDim2.new(0, 250, 0, 0)
    mainContainer.BackgroundTransparency = 1
    mainContainer.BorderSizePixel = 0
    mainContainer.ZIndex = UIStyle.zIndex.content
    mainContainer.Parent = mainGui
    
    -- Add close button for mobile/tablet
    local closeOverlayButton = UIStyle.createButton({
        name = "CloseOverlay",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -50, 0, 10),
        text = "X",
        color = UIStyle.colors.error,
        textColor = UIStyle.colors.textPrimary
    })
    
    closeOverlayButton.ZIndex = UIStyle.zIndex.topmost
    closeOverlayButton.MouseButton1Click:Connect(function()
        UIHub:hide()
    end)
    closeOverlayButton.Parent = mainContainer
    
    -- Store in elements
    uiElements.mainContainer = mainContainer
    
    return mainContainer
end

-- Add a menu button for an item
function addMenuButton(menuItem)
    if not uiElements.mainGui or not menuItem or not menuItem.id then return end
    
    -- Get the category container
    local categoryId = menuItem.category or "management"
    local categoryContainer = uiElements.categoryContainers[categoryId]
    if not categoryContainer then
        warn("[UIHub] Category not found: " .. categoryId)
        categoryContainer = uiElements.categoryContainers.management
    end
    
    -- Create the button
    local buttonName = string.format("%02d_%s", menuItem.priority or 50, menuItem.id)
    local button = UIStyle.createButton({
        name = buttonName,
        size = UDim2.new(1, 0, 0, 36),
        text = menuItem.name,
        color = menuItem.disabled and UIStyle.colors.buttonDisabled or UIStyle.colors.buttonDefault
    })
    
    -- Add icon if provided
    if menuItem.icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 18, 0, 18)
        icon.Position = UDim2.new(0, 8, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = menuItem.icon
        icon.ImageColor3 = menuItem.disabled and UIStyle.colors.textDisabled or UIStyle.colors.textPrimary
        icon.ZIndex = button.ZIndex + 1
        icon.Parent = button
        
        -- Add padding to text for icon
        button.TextXAlignment = Enum.TextXAlignment.Left
        local textPadding = Instance.new("UIPadding")
        textPadding.PaddingLeft = UDim.new(0, 35)
        textPadding.Parent = button
    end
    
    -- Disable button if needed
    if menuItem.disabled then
        button.Active = false
    else
        -- Add click handler
        button.MouseButton1Click:Connect(function()
            handleMenuItemClick(menuItem)
        end)
    end
    
    -- Store button reference and parent
    uiElements.menuButtons[menuItem.id] = button
    button.Parent = categoryContainer
    
    -- Update category visibility
    updateCategoryVisibility()
    
    return button
end

-- Handle menu item click
function handleMenuItemClick(menuItem)
    if not menuItem then return end
    
    -- Call the callback
    if menuItem.callback and typeof(menuItem.callback) == "function" then
        menuItem.callback()
    end
    
    -- Hide the hub if needed
    if menuItem.closeOnClick then
        UIHub:hide()
    end
end

-- Toggle sidebar expanded/collapsed state
function toggleSidebar()
    hubState.sidebarExpanded = not hubState.sidebarExpanded
    
    local targetSize = hubState.sidebarExpanded 
        and UIStyle.sizes.sidebar.expanded 
        or UIStyle.sizes.sidebar.collapsed
    
    local targetPosition = hubState.sidebarExpanded
        and UDim2.new(0, 250, 0, 0)
        or UDim2.new(0, 60, 0, 0)
    
    -- Tween sidebar
    TweenService:Create(
        uiElements.sidebarContainer,
        UIStyle.animations.standard,
        { Size = targetSize }
    ):Play()
    
    -- Tween main container
    TweenService:Create(
        uiElements.mainContainer,
        UIStyle.animations.standard,
        { Position = targetPosition, Size = UDim2.new(1, -targetPosition.X.Offset, 1, 0) }
    ):Play()
    
    -- Show/hide text in buttons
    for _, button in pairs(uiElements.menuButtons) do
        if button:FindFirstChild("UIPadding") then
            button.TextTransparency = hubState.sidebarExpanded and 0 or 1
        end
    end
    
    -- Show/hide category headers
    for _, container in pairs(uiElements.categoryContainers) do
        local header = container.Parent:FindFirstChild(container.Name:gsub("Container", "Header"))
        if header then
            header.TextTransparency = hubState.sidebarExpanded and 0 or 1
        end
    end
    
    logDebug("Sidebar toggled: " .. (hubState.sidebarExpanded and "Expanded" or "Collapsed"))
end

-- Update category visibility based on content
function updateCategoryVisibility()
    for categoryId, container in pairs(uiElements.categoryContainers) do
        -- Count visible children
        local visibleChildren = 0
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible then
                visibleChildren = visibleChildren + 1
            end
        end
        
        -- Get header
        local header = container.Parent:FindFirstChild(container.Name:gsub("Container", "Header"))
        
        -- Update visibility
        if header then
            local isVisible = visibleChildren > 0
            header.Visible = isVisible
            container.Visible = isVisible
        end
    end
end

-- Debug logging utility
function logDebug(message)
    if hubState.debugMode then
        print("[UIHub] " .. message)
    end
end

return UIHub