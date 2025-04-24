--[[
    CentralMenuUI.client.luau
    
    Centralized menu system that demonstrates usage of UIUtils for consistent
    menu patterns and proper close functionality.
    
    Author: Created April 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Find necessary modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared") or ReplicatedStorage:FindFirstChild("Shared")
local UIUtils, UIStyle

if sharedFolder then
    -- Safe require to prevent crashes
    local function requireSafely(moduleScript)
        if moduleScript then
            local success, result = pcall(function()
                return require(moduleScript)
            end)
            
            if success then
                return result
            else
                warn("Failed to load module: " .. moduleScript.Name .. " - " .. result)
                return nil
            end
        end
        return nil
    end
    
    UIUtils = requireSafely(sharedFolder:FindFirstChild("UIUtils"))
    UIStyle = requireSafely(sharedFolder:FindFirstChild("UIStyle"))
end

-- Create fallbacks if modules not found
if not UIUtils then
    warn("UIUtils module not found, CentralMenuUI will have limited functionality")
    UIUtils = {}
end

if not UIStyle then
    warn("UIStyle module not found, using fallback styles")
    UIStyle = {
        colors = {
            background = Color3.fromRGB(30, 30, 50),
            backgroundLight = Color3.fromRGB(40, 40, 70),
            textPrimary = Color3.fromRGB(255, 255, 255)
        }
    }
end

-- Central Menu UI Module
local CentralMenuUI = {}
CentralMenuUI.__index = CentralMenuUI

-- UI State
local UIState = {
    isInitialized = false,
    activeMenu = nil,
    menuElements = {},
    toggleButtons = {}
}

-- Initialize the module
function CentralMenuUI:Initialize()
    if UIState.isInitialized then
        return self
    end
    
    -- Create toggle button in corner for main menu
    local mainMenuToggle = UIUtils.createToggleButton("Main Menu", "settings", UDim2.new(1, -10, 0, 10), function()
        self:ToggleMenu("MainMenu")
    end)
    
    UIState.toggleButtons.MainMenu = mainMenuToggle
    UIState.isInitialized = true
    
    return self
end

-- Create a menu with tabs
function CentralMenuUI:CreateTabMenu(menuName, title, tabs, size, position)
    -- Clean up existing menu if it exists
    if UIState.menuElements[menuName] then
        self:DestroyMenu(menuName)
    end
    
    -- Create menu container
    local menuContainer = UIUtils.createMenuContainer(menuName, title, size, position)
    
    -- Format tab data for the tab system
    local tabInfo = {}
    for i, tab in ipairs(tabs) do
        table.insert(tabInfo, {
            name = tab.name,
            label = tab.label or tab.name
        })
    end
    
    -- Create tab system
    local tabSystem = UIUtils.createTabSystem(menuContainer.mainFrame, tabInfo, UDim2.new(0, 10, 0, 100))
    
    -- Create content for each tab
    for i, tab in ipairs(tabs) do
        if tab.createContent and typeof(tab.createContent) == "function" then
            -- Let the tab populate its own content
            tab.createContent(tabSystem.tabContents[tab.name])
        end
    end
    
    -- Store elements
    UIState.menuElements[menuName] = {
        container = menuContainer,
        tabSystem = tabSystem,
        tabs = tabs
    }
    
    -- Initially hide the menu
    menuContainer.mainFrame.Visible = false
    
    return UIState.menuElements[menuName]
end

-- Create a simple menu without tabs
function CentralMenuUI:CreateSimpleMenu(menuName, title, createContentFunc, size, position)
    -- Clean up existing menu if it exists
    if UIState.menuElements[menuName] then
        self:DestroyMenu(menuName)
    end
    
    -- Create menu container
    local menuContainer = UIUtils.createMenuContainer(menuName, title, size, position)
    
    -- Create content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -60)
    contentArea.Position = UDim2.new(0, 10, 0, 50)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = menuContainer.mainFrame
    
    -- Let the provided function populate the content
    if createContentFunc and typeof(createContentFunc) == "function" then
        createContentFunc(contentArea)
    end
    
    -- Store elements
    UIState.menuElements[menuName] = {
        container = menuContainer,
        contentArea = contentArea
    }
    
    -- Initially hide the menu
    menuContainer.mainFrame.Visible = false
    
    return UIState.menuElements[menuName]
end

-- Show a specific menu
function CentralMenuUI:ShowMenu(menuName)
    local menuElements = UIState.menuElements[menuName]
    if not menuElements then
        warn("Menu not found: " .. menuName)
        return false
    end
    
    -- Hide any active menu
    if UIState.activeMenu and UIState.activeMenu ~= menuName then
        self:HideMenu(UIState.activeMenu)
    end
    
    -- Show the requested menu
    menuElements.container.screenGui.Enabled = true
    menuElements.container.mainFrame.Visible = true
    
    -- Animate opening
    menuElements.container.mainFrame.Position = UDim2.new(
        menuElements.container.mainFrame.Position.X.Scale,
        menuElements.container.mainFrame.Position.X.Offset,
        0.6, 0
    )
    menuElements.container.mainFrame.BackgroundTransparency = 0.5
    
    -- Tween to final position
    local TweenService = game:GetService("TweenService")
    TweenService:Create(
        menuElements.container.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(
                menuElements.container.mainFrame.Position.X.Scale,
                menuElements.container.mainFrame.Position.X.Offset,
                0.5, 0
            ),
            BackgroundTransparency = 0.1
        }
    ):Play()
    
    -- Update active menu
    UIState.activeMenu = menuName
    
    return true
end

-- Hide a specific menu
function CentralMenuUI:HideMenu(menuName)
    local menuElements = UIState.menuElements[menuName]
    if not menuElements then
        warn("Menu not found: " .. menuName)
        return false
    end
    
    -- Hide the menu
    menuElements.container.mainFrame.Visible = false
    
    -- Update active menu
    if UIState.activeMenu == menuName then
        UIState.activeMenu = nil
    end
    
    return true
end

-- Toggle menu visibility
function CentralMenuUI:ToggleMenu(menuName)
    local menuElements = UIState.menuElements[menuName]
    if not menuElements then
        warn("Menu not found: " .. menuName)
        return false
    end
    
    if menuElements.container.mainFrame.Visible then
        return self:HideMenu(menuName)
    else
        return self:ShowMenu(menuName)
    end
end

-- Destroy a menu
function CentralMenuUI:DestroyMenu(menuName)
    local menuElements = UIState.menuElements[menuName]
    if not menuElements then
        return false
    end
    
    -- Remove from active menu if it is active
    if UIState.activeMenu == menuName then
        UIState.activeMenu = nil
    end
    
    -- Destroy container
    if menuElements.container and menuElements.container.screenGui then
        menuElements.container.screenGui:Destroy()
    end
    
    -- Remove from state
    UIState.menuElements[menuName] = nil
    
    return true
end

-- Create a toggle button for a menu
function CentralMenuUI:CreateMenuToggle(menuName, buttonText, icon, position)
    -- Create toggle button
    local toggleButton = UIUtils.createToggleButton(buttonText, icon, position, function()
        self:ToggleMenu(menuName)
    end)
    
    -- Store for cleanup
    UIState.toggleButtons[menuName] = toggleButton
    
    return toggleButton
end

-- Create a modal popup
function CentralMenuUI:CreateModalPopup(title, content, callback)
    local modalDialog = UIUtils.createModalDialog(title, content)
    
    if callback and typeof(callback) == "function" then
        modalDialog.okButton.MouseButton1Click:Connect(function()
            callback()
        end)
    end
    
    return modalDialog
end

-- Show a simple notification
function CentralMenuUI:ShowNotification(message, duration)
    duration = duration or 3
    
    -- Create notification UI
    local notificationUI = UIUtils.createModalDialog("Notification", message, UDim2.new(0, 300, 0, 150))
    
    -- Auto-hide after duration
    task.delay(duration, function()
        if notificationUI and notificationUI.destroy then
            notificationUI.destroy()
        end
    end)
    
    return notificationUI
end

-- Example: Create a main menu with demo tabs
function CentralMenuUI:CreateMainMenu()
    -- Define tab structure
    local tabs = {
        {
            name = "Game",
            label = "Game",
            createContent = function(parent)
                -- Create a scrolling list in the Game tab
                local scrollList = UIUtils.createScrollingList(parent)
                
                -- Add example buttons
                local playButton = Instance.new("TextButton")
                playButton.Name = "PlayButton"
                playButton.Size = UDim2.new(0.8, 0, 0, 50)
                playButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                playButton.Font = Enum.Font.GothamBold
                playButton.Text = "Play Game"
                playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                playButton.TextSize = 18
                playButton.Parent = scrollList.scrollFrame
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = playButton
                
                -- Add more buttons as needed
            end
        },
        {
            name = "Settings",
            label = "Settings",
            createContent = function(parent)
                -- Add settings controls here
                local title = Instance.new("TextLabel")
                title.Name = "SettingsTitle"
                title.Size = UDim2.new(1, -20, 0, 30)
                title.Position = UDim2.new(0, 10, 0, 10)
                title.BackgroundTransparency = 1
                title.Font = Enum.Font.GothamSemibold
                title.Text = "Game Settings"
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.TextSize = 18
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = parent
                
                -- Create example settings
                local musicVolumeLabel = Instance.new("TextLabel")
                musicVolumeLabel.Name = "MusicVolumeLabel"
                musicVolumeLabel.Size = UDim2.new(0.3, 0, 0, 30)
                musicVolumeLabel.Position = UDim2.new(0, 10, 0, 50)
                musicVolumeLabel.BackgroundTransparency = 1
                musicVolumeLabel.Font = Enum.Font.Gotham
                musicVolumeLabel.Text = "Music Volume:"
                musicVolumeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                musicVolumeLabel.TextSize = 16
                musicVolumeLabel.TextXAlignment = Enum.TextXAlignment.Left
                musicVolumeLabel.Parent = parent
                
                -- Add slider for music volume
                local musicVolumeSlider = UIUtils.createProgressBar(parent, UDim2.new(0.6, 0, 0, 30), UDim2.new(0.35, 0, 0, 50))
                musicVolumeSlider.updateProgress(0.7) -- Example initial value
            end
        },
        {
            name = "Stats",
            label = "Stats",
            createContent = function(parent)
                -- Add stats content
                local statsLabel = Instance.new("TextLabel")
                statsLabel.Name = "StatsLabel"
                statsLabel.Size = UDim2.new(1, -20, 0, 30)
                statsLabel.Position = UDim2.new(0, 10, 0, 10)
                statsLabel.BackgroundTransparency = 1
                statsLabel.Font = Enum.Font.GothamBold
                statsLabel.Text = "Player Statistics"
                statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                statsLabel.TextSize = 18
                statsLabel.TextXAlignment = Enum.TextXAlignment.Left
                statsLabel.Parent = parent
                
                -- Create example stats display
                local statsContainer = Instance.new("Frame")
                statsContainer.Name = "StatsContainer"
                statsContainer.Size = UDim2.new(1, -20, 0, 200)
                statsContainer.Position = UDim2.new(0, 10, 0, 50)
                statsContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
                statsContainer.BackgroundTransparency = 0.5
                statsContainer.BorderSizePixel = 0
                statsContainer.Parent = parent
                
                local statsCorner = Instance.new("UICorner")
                statsCorner.CornerRadius = UDim.new(0, 8)
                statsCorner.Parent = statsContainer
                
                -- Example stats
                local statsList = {"Level: 10", "XP: 3,450 / 5,000", "Cash: $25,750", "Playtime: 8h 23m"}
                
                for i, statText in ipairs(statsList) do
                    local statLabel = Instance.new("TextLabel")
                    statLabel.Name = "Stat" .. i
                    statLabel.Size = UDim2.new(1, -40, 0, 30)
                    statLabel.Position = UDim2.new(0, 20, 0, (i-1) * 40 + 20)
                    statLabel.BackgroundTransparency = 1
                    statLabel.Font = Enum.Font.GothamSemibold
                    statLabel.Text = statText
                    statLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    statLabel.TextSize = 16
                    statLabel.TextXAlignment = Enum.TextXAlignment.Left
                    statLabel.Parent = statsContainer
                end
            end
        }
    }
    
    -- Create the menu with tabs
    return self:CreateTabMenu(
        "MainMenu",
        "Game Menu",
        tabs,
        UDim2.new(0, 500, 0, 400),
        UDim2.new(0.5, -250, 0.5, -200)
    )
end

-- Initialize the module when required
return CentralMenuUI:Initialize()