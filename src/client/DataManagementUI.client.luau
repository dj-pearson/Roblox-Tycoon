--!strict
--[[
    DataManagementUI.client.luau
    
    DEPRECATED: This UI is being replaced by components in the new UI system.
    This version now uses ClientDataBridge to connect with the new data system.
    
    For new development, please use the components in src/client/UI/Components/DataManagement/
    
    Last Updated: May 2, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Load the bridge to the new system
local ClientDataBridge = require(script.Parent:WaitForChild("ClientDataBridge"))

-- UI Components
local UIComponents = {}

-- UI references (will be populated when UI is created)
local screenGui
local mainFrame
local gymCommandsTab
local buyTilesTab
local visualizationTab
local validationTab

-- Additional tabs that will be implemented in the future
-- Stored as part of UIComponents to avoid unused variable warnings
UIComponents.playerDataTab = nil
UIComponents.versionHistoryTab = nil  
UIComponents.migrationTab = nil
UIComponents.analyticsTab = nil
UIComponents.settingsTab = nil

-- Find and initialize CoreRegistry
local coreRegistry

local function findClientRegistry()
    -- Try common paths
    local possiblePaths = {
        ReplicatedStorage:FindFirstChild("CoreRegistry"),
        ReplicatedStorage:FindFirstChild("Core") and ReplicatedStorage.Core:FindFirstChild("CoreRegistry"),
        ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("CoreRegistry"),
    }
    
    for _, path in ipairs(possiblePaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                return result
            end
        end
    end
    
    return nil
end

-- Initialize the CoreRegistry
coreRegistry = findClientRegistry()

-- Use CoreRegistry for module references
if not coreRegistry then
    print("[DataManagementUI] CoreRegistry not found - some functionality will be limited")
end

-- Remote events for communicating with server
local AdminRemoteEvent
local AdminRemoteFunction

-- Log function - keep at module level for use throughout the module
local function log(message)
    print("[DataManagementUI] " .. message)
end

-- Check if player is an admin (only user ID 7768610061 is authorized)
local function isAdmin()
    -- Check if player's ID is the authorized admin ID
    if LocalPlayer.UserId == 7768610061 then
        return true
    end
    
    -- For compatibility, still check server but only if ID check fails
    -- Ask server (only once)
    if not AdminRemoteFunction then
        return false
    end
    
    local success, result = pcall(function()
        return AdminRemoteFunction:InvokeServer("isAdmin")
    end)
    
    return success and result == true
end

-- Make isAdmin accessible from UIComponents table
UIComponents.isAdmin = isAdmin

-- Create a stylized label
local function createStyledLabel(parent, text, position, size, textColor)
    local label = Instance.new("TextLabel")
    label.Name = text .. "Label"
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    
    return label
end

-- Create a stylized button
local function createStyledButton(parent, text, position, size, callback)
    -- Create the button
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    button.TextSize = 14
    button.BorderSizePixel = 0
    button.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Create hover effects
    local originalColor = button.BackgroundColor3
    local hoverColor = Color3.fromRGB(85, 125, 245)
    local clickColor = Color3.fromRGB(45, 85, 205)
    
    -- Connect events
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = clickColor}):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = hoverColor}):Play()
    end)
    
    -- Connect callback
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

-- Create a stylized text box
local function createStyledTextBox(parent, placeholder, position, size)
    local textBox = Instance.new("TextBox")
    textBox.Size = size
    textBox.Position = position
    textBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    textBox.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    textBox.TextSize = 14
    textBox.Parent = parent
    textBox.BorderSizePixel = 0
    textBox.ClearTextOnFocus = false
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = textBox
    
    return textBox
end

-- Send command to server
local function sendCommand(command, ...)
    if not AdminRemoteEvent then
        log("AdminRemoteEvent not found")
        return
    end
    
    AdminRemoteEvent:FireServer(command, ...)
end

-- Add to UIComponents to avoid unused warning
UIComponents.sendCommand = sendCommand
UIComponents.createStyledTextBox = createStyledTextBox

-- Create the main UI container
local function createMainUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DataManagementUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer.PlayerGui
    
    -- Create main frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Add corner radius for title bar (top corners only)
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Data Management"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    closeButton.TextSize = 20
    closeButton.Parent = titleBar
    
    -- Add corner radius for close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = closeButton
    
    -- Create main content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -60)
    contentArea.Position = UDim2.new(0, 10, 0, 50)
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.Parent = mainFrame
    
    -- Create tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 40)
    tabBar.Position = UDim2.new(0, 0, 0, 0)
    tabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = contentArea
    
    -- Create tab content area
    local tabContentArea = Instance.new("Frame")
    tabContentArea.Name = "TabContentArea"
    tabContentArea.Size = UDim2.new(1, 0, 1, -50)
    tabContentArea.Position = UDim2.new(0, 0, 0, 50)
    tabContentArea.BackgroundTransparency = 1
    tabContentArea.BorderSizePixel = 0
    tabContentArea.Parent = contentArea
    
    -- Tab management
    local tabButtons = {}
    local tabContents = {}
    local activateTab = function(name)
        -- Update button visuals
        for _, button in ipairs(tabButtons) do
            if button.Name == name .. "Tab" then
                button.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
            else
                button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            end
        end
        
        -- Show/hide tab content
        for tabName, content in pairs(tabContents) do
            content.Visible = (tabName == name)
        end
    end
    
    -- Create tab function
    local function createTab(name)
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = name .. "Tab"
        tabButton.Size = UDim2.new(0, 100, 1, 0)
        tabButton.Position = UDim2.new(0, #tabButtons * 100, 0, 0)
        tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        tabButton.BorderSizePixel = 0
        tabButton.Text = name
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        tabButton.TextSize = 14
        tabButton.Parent = tabBar
        
        -- Create tab content
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = name .. "Content"
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 6
        tabContent.ScrollingDirection = Enum.ScrollingDirection.Y
        tabContent.CanvasSize = UDim2.new(0, 0, 2, 0)  -- Default to 2x vertical space, will adjust as needed
        tabContent.Parent = tabContentArea
        tabContent.Visible = false
        
        -- Connect tab button
        tabButton.MouseButton1Click:Connect(function()
            activateTab(name)
        end)
        
        -- Set initial colors
        if #tabButtons == 0 then
            tabButton.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
        else
            tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        end
          table.insert(tabButtons, tabButton)
        tabContents[name] = tabContent
        return tabContent
    end
    
    -- Create tabs
    local playerDataTabLocal = createTab("Player Data")
    local versionHistoryTabLocal = createTab("Version History")
    local migrationTabLocal = createTab("Data Migration")
    local analyticsTabLocal = createTab("Analytics")
    local settingsTabLocal = createTab("Settings")    -- Admin functionality is now provided by AdminButtonCreator.client.luau
    gymCommandsTab = createTab("Gym Commands")
    buyTilesTab = createTab("Buy Tiles")
    visualizationTab = createTab("Visualization")
    validationTab = createTab("Validation")
    
    -- Store tabs in UIComponents to avoid unused variable warnings
    UIComponents.playerDataTab = playerDataTabLocal
    UIComponents.versionHistoryTab = versionHistoryTabLocal
    UIComponents.migrationTab = migrationTabLocal
    UIComponents.analyticsTab = analyticsTabLocal
    UIComponents.settingsTab = settingsTabLocal
        
        -- Set up Gym Commands tab
        do
            -- Title
            createStyledLabel(gymCommandsTab, "Gym Tycoon Commands", UDim2.new(0, 20, 0, 20), UDim2.new(0, 300, 0, 30))
            
            -- Create command buttons
            local yPos = 70
            local spacing = 50            
            -- Process Tycoon
            createStyledButton(gymCommandsTab, "Process Tycoon", UDim2.new(0, 20, 0, yPos), UDim2.new(0, 160, 0, 35), function()
                -- Try to find the function in the expected modules
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.GymTycoon and 
                   typeof(coreRegistry.Modules.GymTycoon.ProcessTycoon) == "function" then
                    coreRegistry.Modules.GymTycoon.ProcessTycoon()
                else
                    print("[DataManagementUI] ProcessTycoon function not found")
                end
            end)
            
            -- Automate Gym
            createStyledButton(gymCommandsTab, "Automate Gym", UDim2.new(0, 20, 0, yPos + spacing), UDim2.new(0, 160, 0, 35), function()
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.GymTycoon and 
                   typeof(coreRegistry.Modules.GymTycoon.AutomateGym) == "function" then
                    coreRegistry.Modules.GymTycoon.AutomateGym()
                else
                    print("[DataManagementUI] AutomateGym function not found")
                end
            end)
            
              -- Show Tycoon Info
            createStyledButton(gymCommandsTab, "Show Tycoon Info", UDim2.new(0, 20, 0, yPos + spacing * 2), UDim2.new(0, 160, 0, 35), function()
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.GymTycoon and 
                   typeof(coreRegistry.Modules.GymTycoon.ShowTycoonInfo) == "function" then
                    coreRegistry.Modules.GymTycoon.ShowTycoonInfo()
                else
                    print("[DataManagementUI] ShowTycoonInfo function not found")
                end
            end)
        end
        
        -- Set up Buy Tiles tab
        do
            -- Title
            createStyledLabel(buyTilesTab, "Buy Tiles System Commands", UDim2.new(0, 20, 0, 20), UDim2.new(0, 300, 0, 30))
            
            -- Create command buttons
            local yPos = 70
            local spacing = 50            -- Setup BuyTile System
            createStyledButton(buyTilesTab, "Setup BuyTile System", UDim2.new(0, 20, 0, yPos), UDim2.new(0, 180, 0, 35), function()
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.BuyTileSystem and 
                   typeof(coreRegistry.Modules.BuyTileSystem.SetupBuyTileSystem) == "function" then
                    coreRegistry.Modules.BuyTileSystem.SetupBuyTileSystem()
                else
                    print("[DataManagementUI] SetupBuyTileSystem function not found")
                end
            end)
            
              -- Auto-Setup Buy Tiles
            createStyledButton(buyTilesTab, "Auto-Setup Buy Tiles", UDim2.new(0, 20, 0, yPos + spacing), UDim2.new(0, 180, 0, 35), function()
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.BuyTileSystem and 
                   typeof(coreRegistry.Modules.BuyTileSystem.AutoSetupBuyTiles) == "function" then
                    coreRegistry.Modules.BuyTileSystem.AutoSetupBuyTiles()
                else
                    print("[DataManagementUI] AutoSetupBuyTiles function not found")
                end
            end)
            
              -- Generate Build Order
            createStyledButton(buyTilesTab, "Generate Build Order", UDim2.new(0, 20, 0, yPos + spacing * 2), UDim2.new(0, 180, 0, 35), function()
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.BuyTileSystem and 
                   typeof(coreRegistry.Modules.BuyTileSystem.GenerateBuildOrder) == "function" then
                    coreRegistry.Modules.BuyTileSystem.GenerateBuildOrder()
                else
                    print("[DataManagementUI] GenerateBuildOrder function not found")
                end
            end)
            
              -- Generate BuyTile Config
            createStyledButton(buyTilesTab, "Generate BuyTile Config", UDim2.new(0, 20, 0, yPos + spacing * 3), UDim2.new(0, 180, 0, 35), function()
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.BuyTileSystem and 
                   typeof(coreRegistry.Modules.BuyTileSystem.GenerateBuyTileConfig) == "function" then
                    coreRegistry.Modules.BuyTileSystem.GenerateBuyTileConfig()
                else
                    print("[DataManagementUI] GenerateBuyTileConfig function not found")
                end
            end)
        end
        
        -- Set up Visualization tab
        do
            -- Title
            createStyledLabel(visualizationTab, "Visualization Tools", UDim2.new(0, 20, 0, 20), UDim2.new(0, 300, 0, 30))
            
            -- Create command buttons
            local yPos = 70
            local spacing = 50
              -- Show Hitboxes
            createStyledButton(visualizationTab, "Show Hitboxes", UDim2.new(0, 20, 0, yPos), UDim2.new(0, 160, 0, 35), function()
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.Visualization and 
                   typeof(coreRegistry.Modules.Visualization.ShowHitboxes) == "function" then
                    coreRegistry.Modules.Visualization.ShowHitboxes()
                else
                    print("[DataManagementUI] ShowHitboxes function not found")
                end
            end)
            
              -- Hide Hitboxes
            createStyledButton(visualizationTab, "Hide Hitboxes", UDim2.new(0, 20, 0, yPos + spacing), UDim2.new(0, 160, 0, 35), function()
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.Visualization and 
                   typeof(coreRegistry.Modules.Visualization.HideHitboxes) == "function" then
                    coreRegistry.Modules.Visualization.HideHitboxes()
                else
                    print("[DataManagementUI] HideHitboxes function not found")
                end
            end)
        end
        
        -- Set up Validation tab
        do
            -- Title
            createStyledLabel(validationTab, "Model Validation Tools", UDim2.new(0, 20, 0, 20), UDim2.new(0, 300, 0, 30))
            
            -- Create command buttons
            local yPos = 70
            local spacing = 50
              -- Validate Gym Models
            createStyledButton(validationTab, "Validate Gym Models", UDim2.new(0, 20, 0, yPos), UDim2.new(0, 180, 0, 35), function()
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.Validation and 
                   typeof(coreRegistry.Modules.Validation.ValidateGymModels) == "function" then
                    coreRegistry.Modules.Validation.ValidateGymModels()
                else
                    print("[DataManagementUI] ValidateGymModels function not found")
                end
            end)
            
            -- Verify Structure
            createStyledButton(validationTab, "Verify Structure", UDim2.new(0, 20, 0, yPos + spacing), UDim2.new(0, 180, 0, 35), function()
                if coreRegistry and coreRegistry.Modules and 
                   coreRegistry.Modules.Validation and 
                   typeof(coreRegistry.Modules.Validation.VerifyStructure) == "function" then
                    coreRegistry.Modules.Validation.VerifyStructure()
                else
                    print("[DataManagementUI] VerifyStructure function not found")
                end
            end)
        end
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)
    
    -- Show first tab by default
    activateTab("Player Data")
    
    -- Return the main components
    return {
        screenGui = screenGui,
        mainFrame = mainFrame,
        tabContentArea = tabContentArea
    }
end

-- Connect to remote events
local function connectToRemotes()
    -- Try to find the expected remote events
    AdminRemoteEvent = ReplicatedStorage:FindFirstChild("AdminRemoteEvent")
    AdminRemoteFunction = ReplicatedStorage:FindFirstChild("AdminRemoteFunction")
    
    if not AdminRemoteEvent or not AdminRemoteFunction then
        -- Try in other common locations
        local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if Remotes then
            AdminRemoteEvent = AdminRemoteEvent or Remotes:FindFirstChild("AdminRemoteEvent")
            AdminRemoteFunction = AdminRemoteFunction or Remotes:FindFirstChild("AdminRemoteFunction")
        end
    end
    
    if not AdminRemoteEvent then
        log("AdminRemoteEvent not found - some functionality will be limited")
    end
    
    if not AdminRemoteFunction then
        log("AdminRemoteFunction not found - some functionality will be limited")
    end
end

-- Initialize the UI and connections
local function initialize()
        -- Create the main UI components
        createMainUI()
        
        -- Check if player is admin when toggling UI visibility
        local function toggleVisibility()
            -- Everyone can see the data management UI
            mainFrame.Visible = not mainFrame.Visible
        end
        
        -- Create toggle button
        local toggleButton = Instance.new("TextButton")
        toggleButton.Name = "DataManagerToggle"
        toggleButton.Size = UDim2.new(0, 40, 0, 40)
        toggleButton.Position = UDim2.new(0, 10, 0, 10)
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 80, 190)
        toggleButton.Text = "📊"
        toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        toggleButton.TextSize = 20
        toggleButton.BorderSizePixel = 0
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = toggleButton
        
        -- Add to PlayerGui
        toggleButton.Parent = LocalPlayer.PlayerGui:WaitForChild("CoreGui", 5) or screenGui
        
        -- Connect toggle button
        toggleButton.MouseButton1Click:Connect(toggleVisibility)
        
        -- Hide initially
        mainFrame.Visible = false
end

-- Run initialization
-- Connect to remote events
connectToRemotes()

-- Initialize UI
initialize()

-- Return the module
return UIComponents
