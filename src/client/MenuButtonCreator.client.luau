-- MenuButtonCreator.client.luau
-- Script to create menu buttons with icons that provide access to various game systems
-- Created April 2025

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Log function
local function log(message)
    print("[MenuButtonCreator] " .. message)
end

-- Define icons for our menu system
local ICONS = {}

-- Hardcoded icon IDs from AdminControlsUI
local hardcodedIcons = {
    Close = "rbxassetid://6031094678",
    Settings = "rbxassetid://6031280882", 
    Player = "rbxassetid://6031302920",
    Warning = "rbxassetid://6031094670",
    Success = "rbxassetid://6031094661",
    Error = "rbxassetid://6031094667",
    Info = "rbxassetid://6026568247"
}

-- Get icons from AdminControlsUI or use hardcoded values
local function loadIconsFromAdminUI()
    -- First try to load them dynamically 
    local success, adminUI = pcall(function()
        -- Try to find AdminControlsUI in various locations
        local ui = script.Parent:FindFirstChild("UI")
        if ui and ui:FindFirstChild("AdminControlsUI") then
            log("Found AdminControlsUI in script.Parent.UI")
            return require(ui.AdminControlsUI)
        end
        
        local repStorage = game:GetService("ReplicatedStorage")
        if repStorage:FindFirstChild("UI") and
           repStorage.UI:FindFirstChild("AdminControlsUI") then
            log("Found AdminControlsUI in ReplicatedStorage.UI")
            return require(repStorage.UI.AdminControlsUI)
        end
        
        -- Check in workspace
        local workspace = game:GetService("Workspace")
        if workspace:FindFirstChild("UI") and
           workspace.UI:FindFirstChild("AdminControlsUI") then 
            log("Found AdminControlsUI in workspace.UI")
            return require(workspace.UI.AdminControlsUI)
        end
        
        return nil
    end)
      if success and adminUI then
        -- Try to get IconSet from the AdminControlsUI module
        if adminUI.tryRequireUIModule then
            local iconModule = adminUI.tryRequireUIModule("IconSet")
            if iconModule and iconModule.Icons then
                log("Successfully loaded icons from AdminControlsUI")
                -- Return our mapped icons using the found icons
                return {
                    Shop = iconModule.Icons.Settings or hardcodedIcons.Settings,
                    Stats = iconModule.Icons.Success or hardcodedIcons.Success,
                    Settings = iconModule.Icons.Player or hardcodedIcons.Player,
                    Leaderboard = iconModule.Icons.Info or hardcodedIcons.Info,
                    Gym = iconModule.Icons.Close or hardcodedIcons.Close,
                    Data = iconModule.Icons.Warning or hardcodedIcons.Warning,
                    Competition = iconModule.Icons.Settings or hardcodedIcons.Settings,
                    Social = iconModule.Icons.Player or hardcodedIcons.Player
                }
            end
        end
    end
    
    -- Use hardcoded icons as a fallback
    log("Using hardcoded icon assets")
    return {
        Shop = hardcodedIcons.Settings,      -- Shopping cart icon (using Settings icon)
        Stats = hardcodedIcons.Success,      -- Stats chart icon (using Success icon)
        Settings = hardcodedIcons.Player,    -- Gear icon (using Player icon) 
        Leaderboard = hardcodedIcons.Info,   -- Trophy icon (using Info icon)
        Gym = hardcodedIcons.Close,          -- Gym icon (using Close icon)
        Data = hardcodedIcons.Warning,       -- Data icon (using Warning icon)
        Competition = hardcodedIcons.Settings, -- Competition icon (using Settings icon)
        Social = hardcodedIcons.Player       -- Social icon (using Player icon)
    }
end

-- Load icons
ICONS = loadIconsFromAdminUI()

-- Safely require a module with fallback paths
local function safeRequire(moduleName)
    -- First try direct parent
    if script.Parent:FindFirstChild(moduleName) then
        local success, module = pcall(function()
            return require(script.Parent:FindFirstChild(moduleName))
        end)
        if success and module then
            return module
        end
    end
    
    -- Then try ReplicatedStorage path
    local repStorage = game:GetService("ReplicatedStorage")
    if repStorage:FindFirstChild(moduleName) then
        local success, module = pcall(function()
            return require(repStorage:FindFirstChild(moduleName))
        end)
        if success and module then
            return module
        end
    end
    
    -- Try src/client path
    if repStorage:FindFirstChild("src") and
       repStorage.src:FindFirstChild("client") and
       repStorage.src.client:FindFirstChild(moduleName) then
        local success, module = pcall(function()
            return require(repStorage.src.client:FindFirstChild(moduleName))
        end)
        if success and module then
            return module
        end
    end
    
    -- Last resort - search recursively for the module
    local function findModuleInChildren(parent, name)
        for _, child in pairs(parent:GetChildren()) do
            if child.Name == name and child:IsA("ModuleScript") then
                local success, module = pcall(function()
                    return require(child)
                end)
                if success and module then
                    return module
                end
            end
            
            if #child:GetChildren() > 0 then
                local foundModule = findModuleInChildren(child, name)
                if foundModule then
                    return foundModule
                end
            end
        end
        return nil
    end
    
    local gameModule = findModuleInChildren(game, moduleName)
    if gameModule then
        return gameModule
    end
    
    return nil
end

-- Menu button configurations
local MENU_BUTTONS = {
    {
        name = "Shop",
        icon = ICONS.Shop,
        position = UDim2.new(0, 10, 0, 10),
        color = Color3.fromRGB(76, 175, 80),
        callback = function()
            -- Handle shop button click
            log("Shop button clicked")
            local shopModule = safeRequire("ShopUI")
            if shopModule then
                if typeof(shopModule.ToggleVisibility) == "function" then
                    shopModule.ToggleVisibility()
                else
                    log("ShopUI found but ToggleVisibility function not available")
                end
            else
                -- Create placeholder UI
                log("ShopUI module not found - showing placeholder")
                local gui = Instance.new("ScreenGui")
                gui.Name = "ShopUIPlaceholder"
                gui.ResetOnSpawn = false
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 300, 0, 200)
                frame.Position = UDim2.new(0.5, -150, 0.5, -100)
                frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                frame.BorderSizePixel = 0
                frame.Parent = gui
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 30)
                title.Text = "Shop (Placeholder UI)"
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                title.BorderSizePixel = 0
                title.Parent = frame
                
                gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
                
                -- Auto-close after 2 seconds
                task.delay(2, function()
                    gui:Destroy()
                end)
            end
        end
    },    {
        name = "Gym",
        icon = ICONS.Gym,
        position = UDim2.new(0, 10, 0, 260),
        color = Color3.fromRGB(46, 125, 50),
        callback = function()
            -- Handle gym management button click
            log("Gym management button clicked")
              -- Direct loading approach for the gym module
            local success, result = pcall(function()
                -- Try to load directly from the script's parent
                if script.Parent:FindFirstChild("GymTycoonMenuUI") then
                    log("Found GymTycoonMenuUI directly in script.Parent")
                    local gymModuleFromParent = require(script.Parent.GymTycoonMenuUI)
                    
                    -- Check if it has the expected function
                    if typeof(gymModuleFromParent.ToggleManagementMenu) == "function" then
                        gymModuleFromParent:ToggleManagementMenu()
                        return true
                    else
                        log("GymTycoonMenuUI found but ToggleManagementMenu not available")
                    end
                end
                
                -- Try with safeRequire as backup
                local gymModuleFromSafe = safeRequire("GymTycoonMenuUI")
                if gymModuleFromSafe and typeof(gymModuleFromSafe.ToggleManagementMenu) == "function" then
                    log("Found GymTycoonMenuUI via safeRequire")
                    gymModuleFromSafe:ToggleManagementMenu()
                    return true
                end
                
                -- Try to initialize the module manually if it exists but wasn't initialized
                if script.Parent:FindFirstChild("GymTycoonMenuUI") then
                    log("Trying to initialize GymTycoonMenuUI manually")
                    local gymModuleInit = require(script.Parent.GymTycoonMenuUI)
                    if typeof(gymModuleInit.Initialize) == "function" then
                        gymModuleInit:Initialize()
                        if typeof(gymModuleInit.ToggleManagementMenu) == "function" then
                            gymModuleInit:ToggleManagementMenu()
                            return true
                        end
                    end
                end
                
                return false
            end)
            
            -- Show placeholder if all approaches failed
            if not success or not result then
                log("GymTycoonMenuUI could not be loaded or toggled - showing placeholder")
                -- Create a simplified version of the gym management UI directly
                local gui = Instance.new("ScreenGui")
                gui.Name = "GymManagementUI"
                gui.ResetOnSpawn = false
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 400, 0, 300)
                frame.Position = UDim2.new(0.5, -200, 0.5, -150)
                frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                frame.BorderSizePixel = 0
                frame.Parent = gui
                
                -- Add corner radius
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 10)
                corner.Parent = frame
                
                -- Title bar
                local titleBar = Instance.new("Frame")
                titleBar.Size = UDim2.new(1, 0, 0, 40)
                titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                titleBar.BorderSizePixel = 0
                titleBar.Parent = frame
                
                -- Title
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -50, 1, 0)
                title.Position = UDim2.new(0, 20, 0, 0)
                title.BackgroundTransparency = 1
                title.Text = "Gym Management"
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.TextSize = 18
                title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = titleBar
                
                -- Close button
                local closeButton = Instance.new("TextButton")
                closeButton.Size = UDim2.new(0, 30, 0, 30)
                closeButton.Position = UDim2.new(1, -35, 0, 5)
                closeButton.BackgroundTransparency = 1
                closeButton.Text = "✕"
                closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                closeButton.TextSize = 20
                closeButton.Parent = titleBar
                
                closeButton.MouseButton1Click:Connect(function()
                    gui:Destroy()
                end)
                
                -- Content
                local content = Instance.new("TextLabel")
                content.Size = UDim2.new(1, -40, 0, 30)
                content.Position = UDim2.new(0, 20, 0, 60)
                content.BackgroundTransparency = 1
                content.Text = "Gym Management module is being loaded..."
                content.TextColor3 = Color3.fromRGB(255, 255, 255)
                content.TextSize = 16
                content.TextXAlignment = Enum.TextXAlignment.Left
                content.Parent = frame
                
                gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
                
                -- Try to load the module again after a delay
                task.delay(3, function()
                    if gui and gui.Parent then
                        gui:Destroy()
                        
                        -- Try the callback again
                        pcall(function()
                            local gymModule = safeRequire("GymTycoonMenuUI")
                            if gymModule and typeof(gymModule.ToggleManagementMenu) == "function" then
                                gymModule:ToggleManagementMenu()
                            end
                        end)
                    end
                end)
            end
        end
    },{
        name = "Stats",
        icon = ICONS.Stats,
        position = UDim2.new(0, 10, 0, 60),
        color = Color3.fromRGB(33, 150, 243),
        callback = function()
            -- Handle stats button click
            log("Stats button clicked")
            local statsModule = safeRequire("StatsUI")
            if statsModule then
                if typeof(statsModule.ToggleVisibility) == "function" then
                    statsModule.ToggleVisibility()
                else
                    log("StatsUI found but ToggleVisibility function not available")
                end
            else
                log("StatsUI module not found - showing placeholder")
                -- Create placeholder notification
                local gui = Instance.new("ScreenGui")
                gui.Name = "StatsUIPlaceholder"
                gui.ResetOnSpawn = false
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 300, 0, 200)
                frame.Position = UDim2.new(0.5, -150, 0.5, -100)
                frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                frame.BorderSizePixel = 0
                frame.Parent = gui
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 30)
                title.Text = "Stats (Placeholder UI)"
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                title.BorderSizePixel = 0
                title.Parent = frame
                
                gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
                
                -- Auto-close after 2 seconds
                task.delay(2, function()
                    gui:Destroy()
                end)
            end
        end
    },
    {
        name = "Leaderboard",
        icon = ICONS.Leaderboard,
        position = UDim2.new(0, 10, 0, 110),
        color = Color3.fromRGB(255, 193, 7),
        callback = function()
            -- Handle leaderboard button click
            log("Leaderboard button clicked")
            local leaderboardModule = safeRequire("LeaderboardUI")
            if leaderboardModule then
                if typeof(leaderboardModule.ToggleVisibility) == "function" then
                    leaderboardModule.ToggleVisibility()
                else
                    log("LeaderboardUI found but ToggleVisibility function not available")
                end
            else
                log("LeaderboardUI module not found - showing placeholder")
                -- Create placeholder notification
                local gui = Instance.new("ScreenGui")
                gui.Name = "LeaderboardUIPlaceholder"
                gui.ResetOnSpawn = false
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 300, 0, 200)
                frame.Position = UDim2.new(0.5, -150, 0.5, -100)
                frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                frame.BorderSizePixel = 0
                frame.Parent = gui
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 30)
                title.Text = "Leaderboard (Placeholder UI)"
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                title.BorderSizePixel = 0
                title.Parent = frame
                
                gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
                
                -- Auto-close after 2 seconds
                task.delay(2, function()
                    gui:Destroy()
                end)
            end
        end
    },
    {
        name = "Competition",
        icon = ICONS.Competition,
        position = UDim2.new(0, 10, 0, 160),
        color = Color3.fromRGB(156, 39, 176),
        callback = function()
            -- Handle competition button click
            log("Competition button clicked")
            local competitionModule = safeRequire("CompetitionUI")
            if competitionModule then
                if typeof(competitionModule.ToggleVisibility) == "function" then
                    competitionModule.ToggleVisibility()
                else
                    log("CompetitionUI found but ToggleVisibility function not available")
                end
            else
                log("CompetitionUI module not found - showing placeholder")
                -- Create placeholder notification
                local gui = Instance.new("ScreenGui")
                gui.Name = "CompetitionUIPlaceholder"
                gui.ResetOnSpawn = false
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 300, 0, 200)
                frame.Position = UDim2.new(0.5, -150, 0.5, -100)
                frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                frame.BorderSizePixel = 0
                frame.Parent = gui
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 30)
                title.Text = "Competition (Placeholder UI)"
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                title.BorderSizePixel = 0
                title.Parent = frame
                
                gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
                
                -- Auto-close after 2 seconds
                task.delay(2, function()
                    gui:Destroy()
                end)
            end
        end
    },    {
        name = "Data",
        icon = ICONS.Data,
        position = UDim2.new(0, 10, 0, 210),
        color = Color3.fromRGB(63, 81, 181),
        callback = function()
            -- Handle data button click
            log("Data button clicked")
            
            -- The direct approach - we know DataManagementUI exists
            local success, result = pcall(function()
                -- Try to load directly from the current script's parent
                if script.Parent:FindFirstChild("DataManagementUI") then
                    local dataModule = require(script.Parent.DataManagementUI)
                    -- Check if it has the expected interface
                    if typeof(dataModule.ToggleVisibility) == "function" then
                        dataModule.ToggleVisibility()
                        return true
                    end
                end
                
                -- If that fails, try the fallback approach
                local dataModule = safeRequire("DataManagementUI")
                if dataModule and typeof(dataModule.ToggleVisibility) == "function" then
                    dataModule.ToggleVisibility()
                    return true
                end
                
                return false
            end)
            
            if not success or not result then
                log("DataManagementUI module not found or error occurred - showing placeholder")
                -- Create placeholder notification
                local gui = Instance.new("ScreenGui")
                gui.Name = "DataUIPlaceholder"
                gui.ResetOnSpawn = false
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 300, 0, 200)
                frame.Position = UDim2.new(0.5, -150, 0.5, -100)
                frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                frame.BorderSizePixel = 0
                frame.Parent = gui
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 30)
                title.Text = "Data Management (Placeholder UI)"
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                title.BorderSizePixel = 0
                title.Parent = frame
                
                gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
                
                -- Auto-close after 2 seconds
                task.delay(2, function()
                    gui:Destroy()
                end)
            end
        end
    }
}

-- Create a menu button
local function createMenuButton(config)
    -- Create button element
    local button = Instance.new("ImageButton")
    button.Name = config.name .. "Button"
    button.Size = UDim2.new(0, 40, 0, 40)
    button.Position = config.position or UDim2.new(0, 10, 0, 10)
    button.BackgroundColor3 = config.color or Color3.fromRGB(65, 105, 225)
    button.BorderSizePixel = 0
    button.ZIndex = 10
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    -- Add icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.7, 0, 0.7, 0)
    icon.Position = UDim2.new(0.15, 0, 0.15, 0)
    icon.BackgroundTransparency = 1
    icon.Image = config.icon or ""
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ZIndex = 11
    icon.Parent = button
    
    -- Add hover effect
    local hoverColor = Color3.new(
        math.min(config.color.R + 0.1, 1),
        math.min(config.color.G + 0.1, 1),
        math.min(config.color.B + 0.1, 1)
    )
    
    local originalColor = config.color
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = originalColor
    end)
    
    -- Add tooltip
    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 100, 0, 30)
    tooltip.Position = UDim2.new(1, 10, 0, 5)
    tooltip.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
    tooltip.Text = config.name
    tooltip.TextSize = 14
    tooltip.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    tooltip.BorderSizePixel = 0
    tooltip.TextWrapped = true
    tooltip.TextXAlignment = Enum.TextXAlignment.Center
    tooltip.ZIndex = 12
    tooltip.Visible = false
    
    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 6)
    tooltipCorner.Parent = tooltip
    
    tooltip.Parent = button
    
    -- Show/hide tooltip on hover
    button.MouseEnter:Connect(function()
        tooltip.Visible = true
    end)
    
    button.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
    
    -- Add click callback
    button.MouseButton1Click:Connect(function()
        if config.callback then
            config.callback()
        end
    end)
    
    return button
end

-- Initialize all menu buttons
local function initializeMenuButtons()
    -- Create a ScreenGui for menu buttons
    local menuGui = Instance.new("ScreenGui")
    menuGui.Name = "MenuButtonsGui"
    menuGui.ResetOnSpawn = false
    menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Check if PlayerGui exists
    if not LocalPlayer:FindFirstChild("PlayerGui") then
        log("PlayerGui not found, waiting...")
        LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Check if MenuButtonsGui already exists
    local existingGui = LocalPlayer.PlayerGui:FindFirstChild("MenuButtonsGui")
    if existingGui then
        existingGui:Destroy()
    end
    
    menuGui.Parent = LocalPlayer.PlayerGui
    
    -- Create all configured buttons
    for _, buttonConfig in ipairs(MENU_BUTTONS) do
        local button = createMenuButton(buttonConfig)
        button.Parent = menuGui
        log("Created button: " .. buttonConfig.name)
    end
    
    log("Menu buttons initialization complete")
end

-- Start menu creation when player is fully loaded
local function onPlayerLoaded()
    log("Player loaded, initializing menu buttons")
    
    -- Wait a short time to ensure the UI system is ready
    task.wait(1)
    initializeMenuButtons()
end

-- If the player is already loaded
if LocalPlayer:IsDescendantOf(game) then
    onPlayerLoaded()
else
    -- Otherwise wait for the player to load
    LocalPlayer.CharacterAdded:Connect(function()
        onPlayerLoaded()
    end)
end

-- ButtonCreator module
local MenuButtonCreator = {}

-- Create a custom button programmatically
function MenuButtonCreator.CreateButton(config)
    if not config or not config.name then
        log("Invalid button configuration")
        return nil
    end
    
    -- Find parent GUI
    local parent = LocalPlayer.PlayerGui:FindFirstChild("MenuButtonsGui")
    if not parent then
        log("MenuButtonsGui not found, creating one")
        parent = Instance.new("ScreenGui")
        parent.Name = "MenuButtonsGui"
        parent.ResetOnSpawn = false
        parent.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        parent.Parent = LocalPlayer.PlayerGui
    end
    
    -- Create the button
    local button = createMenuButton(config)
    button.Parent = parent
    
    log("Created custom button: " .. config.name)
    return button
end

return MenuButtonCreator
