-- MenuButtonCreator.client.luau
-- Script to create menu buttons with icons that provide access to various game systems
-- Created April 2025
-- Updated May 3, 2025 to use ModuleLoader

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Log function
local function log(message: string)
    print("[MenuButtonCreator] " .. message)
end

-- Load ModuleLoaderHelper
local ModuleLoaderHelper = nil
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")

if sharedFolder and sharedFolder:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(sharedFolder.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
        log("ModuleLoaderHelper loaded successfully")
    else
        warn("[MenuButtonCreator] Failed to load ModuleLoaderHelper, falling back to legacy loading")
    end
end

-- Load UIElementsData using ModuleLoaderHelper if available
local UIElementsData = nil
if ModuleLoaderHelper then
    UIElementsData = ModuleLoaderHelper.loadModule("UI/UIElementsData")
    if not UIElementsData then
        log("Trying alternate paths for UIElementsData")
        UIElementsData = ModuleLoaderHelper.loadModule("UIElementsData")
    end
end

-- Fallback loading if ModuleLoaderHelper is not available or loading failed
if not UIElementsData then
    log("Using fallback loading for UIElementsData")
    if script.Parent:FindFirstChild("UI") and script.Parent.UI:FindFirstChild("UIElementsData") then
        local success, result = pcall(function()
            return require(script.Parent.UI.UIElementsData)
        end)
        if success then
            UIElementsData = result
            log("UIElementsData loaded from script.Parent.UI")
        end
    end
end

if not UIElementsData then
    error("[MenuButtonCreator] Could not load UIElementsData module")
end

local ICONS = UIElementsData.Icons
  -- More robust module loading function using ModuleLoaderHelper
local function loadUIModule(moduleName)
    if ModuleLoaderHelper then
        -- Try different path formats
        local possiblePaths = {
            moduleName,
            "UI/" .. moduleName,
            "client/UI/" .. moduleName,
            "UI/Menu/" .. moduleName
        }
        
        for _, path in ipairs(possiblePaths) do
            local module = ModuleLoaderHelper.loadModule(path)
            if module then
                log("Loaded module " .. moduleName .. " via ModuleLoaderHelper from path: " .. path)
                return module
            end
        end
    end
    
    -- Fallback to direct lookup in common locations
    log("Falling back to direct lookup for module: " .. moduleName)
    
    -- First try direct parent
    if script.Parent:FindFirstChild(moduleName) then
        local success, module = pcall(function()
            return require(script.Parent:FindFirstChild(moduleName))
        end)
        if success and module then
            return module
        end
    end
    
    -- Then try UI folder
    if script.Parent:FindFirstChild("UI") and script.Parent.UI:FindFirstChild(moduleName) then
        local success, module = pcall(function()
            return require(script.Parent.UI:FindFirstChild(moduleName))
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
    
    -- Last resort - recursive search
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

local MENU_BUTTONS = {    {
        name = "Shop",
        icon = ICONS.Shop,
        position = UDim2.new(0, 10, 0, 10),
        color = Color3.fromRGB(76, 175, 80),
        callback = function()
            -- Handle shop button click
            log("Shop button clicked")
            local shopModule = loadUIModule("ShopMenuUI")
            if shopModule then
                if typeof(shopModule.ToggleVisibility) == "function" then
                    shopModule.ToggleVisibility()
                else
                    log("ShopMenuUI found but ToggleVisibility function not available")
                end
            end
        end
    },{
        name = "Alliance",
        icon = ICONS.Alliance,
        position = UDim2.new(0, 10, 0, 310), -- Position it after Data
        color = Color3.fromRGB(121, 85, 72),
        callback = function()
            -- Handle alliance button click
            log("Alliance button clicked")
            
            -- Correctly require the AllianceUI module
            local AllianceUI = require(script.Parent.Parent.UI.AllianceUI)
            
            if AllianceUI and typeof(AllianceUI.toggleMenu) == "function" then
                AllianceUI.toggleMenu()
            else
                log("AllianceUI found but toggleMenu function not available or module not found")
            end
        end
    },
    
    {
        name = "Gym",
        icon = ICONS.Settings,
        position = UDim2.new(0, 10, 0, 260),
        color = Color3.fromRGB(46, 125, 50),
        callback = function()
            -- Handle settings button click
            log("Settings button clicked")
            local settingsModule = require(script.Parent.Parent.UI.SettingsMenuUI)
            if settingsModule and typeof(settingsModule.ToggleSettingsMenu) == "function" then
                settingsModule.ToggleSettingsMenu()
            end
        end
    },
    {
        name = "Gymm",
        icon = ICONS.Gym,
        position = UDim2.new(0, 10, 0, 260),
        color = Color3.fromRGB(46, 125, 50),        callback = function()
            -- Handle gym management button click
            log("Gym management button clicked")
            local gymModule = loadUIModule("GymMenuUI")
            if gymModule then
                if typeof(gymModule.ToggleVisibility) == "function" then 
                    gymModule.ToggleVisibility()
                else
                    log("GymMenuUI found but ToggleVisibility function not available")
                end
            end
        end
    },{
        name = "Stats",
        icon = ICONS.Stats,
        position = UDim2.new(0, 10, 0, 60),
        color = Color3.fromRGB(33, 150, 243),        callback = function()
            -- Handle stats button click
            log("Stats button clicked")
            local statsModule = loadUIModule("StatsMenuUI")
            if statsModule then
                if typeof(statsModule.ToggleVisibility) == "function" then
                    statsModule.ToggleVisibility()
                else
                    log("StatsMenuUI found but ToggleVisibility function not available")
                end
            end
        end
    },
    {
        name = "Leaderboard",
        icon = ICONS.Leaderboard,
        position = UDim2.new(0, 10, 0, 110),
        color = Color3.fromRGB(255, 193, 7),        callback = function()
            -- Handle leaderboard button click
            log("Leaderboard button clicked")
            local leaderboardModule = loadUIModule("LeaderboardMenuUI")
            if leaderboardModule then
                if typeof(leaderboardModule.ToggleVisibility) == "function" then
                    leaderboardModule.ToggleVisibility()
                else
                    log("LeaderboardMenuUI found but ToggleVisibility function not available")
                end
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
            local competitionModule = loadUIModule("CompetitionMenuUI")
            if competitionModule then
                if typeof(competitionModule.ToggleVisibility) == "function" then
                    competitionModule.ToggleVisibility()
                else
                    log("CompetitionMenuUI found but ToggleVisibility function not available")
                end
            end
        end
    },    {
        name = "Data",
        icon = ICONS.Data,
        position = UDim2.new(0, 10, 0, 210),
        color = Color3.fromRGB(63, 81, 181),        callback = function()
            -- Handle data button click
            log("Data button clicked")
            local dataModule = loadUIModule("DataMenuUI")
            if dataModule then
                if typeof(dataModule.ToggleVisibility) == "function" then
                    dataModule.ToggleVisibility()
                else
                    log("DataMenuUI found but ToggleVisibility function not available")
                end
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
