--[[
    AdminControlsUI.client.luau
    
    Administrator control panel UI implementation that leverages the UIUtils
    library for consistent UI patterns and proper close functionality.
    
    Author: Created April 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Load required modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared") or ReplicatedStorage:FindFirstChild("Shared")
local UIUtils, UIStyle

-- Safe require helper
local function requireSafely(moduleScript)
    if moduleScript and moduleScript:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            return result
        else
            warn("Failed to load module: " .. moduleScript.Name)
            return nil
        end
    end
    return nil
end

-- Try to load the modules
if sharedFolder then
    UIUtils = requireSafely(sharedFolder:FindFirstChild("UIUtils"))
    UIStyle = requireSafely(sharedFolder:FindFirstChild("UIStyle"))
end

-- Create fallbacks if modules not found
if not UIUtils then
    warn("UIUtils module not found, AdminControlsUI will have limited functionality")
    UIUtils = {}
end

if not UIStyle then
    warn("UIStyle module not found, using fallback styles")
    UIStyle = {
        colors = {
            primary = Color3.fromRGB(0, 132, 255),
            background = Color3.fromRGB(30, 30, 50),
            backgroundLight = Color3.fromRGB(40, 40, 70),
            textPrimary = Color3.fromRGB(255, 255, 255)
        }
    }
end

-- Admin Controls UI Module
local AdminControlsUI = {}
AdminControlsUI.__index = AdminControlsUI

-- State tracking
local uiState = {
    isInitialized = false,
    adminPanelVisible = false,
    menuElements = {},
    currentTab = "Players"
}

-- Initialize the admin UI
function AdminControlsUI:Initialize()
    if uiState.isInitialized then
        return self
    end
    
    -- Create toggle button
    self:CreateAdminToggleButton()
    
    -- Create the admin panel (initially hidden)
    self:CreateAdminPanel()
    
    uiState.isInitialized = true
    return self
end

-- Create the admin toggle button
function AdminControlsUI:CreateAdminToggleButton()
    -- Only create if UIUtils is available
    if not UIUtils.createToggleButton then return end
    
    -- Create toggle button for admin panel
    local adminToggle = UIUtils.createToggleButton("Admin", "settings", UDim2.new(1, -10, 0, 10), function()
        self:ToggleAdminPanel()
    end)
    
    uiState.menuElements.adminToggle = adminToggle
    return adminToggle
end

-- Create the admin panel
function AdminControlsUI:CreateAdminPanel()
    -- Only create if UIUtils is available
    if not UIUtils.createMenuContainer then return end
    
    -- Create the main container
    local adminContainer = UIUtils.createMenuContainer(
        "AdminControls", 
        "Admin Control Panel", 
        UDim2.new(0, 600, 0, 450),
        UDim2.new(0.5, -300, 0.5, -225)
    )
    
    -- Create tabs for different admin functions
    local tabs = {
        { name = "Players", label = "Players" },
        { name = "GameSettings", label = "Game Settings" },
        { name = "ServerStats", label = "Server Stats" },
        { name = "Commands", label = "Commands" }
    }
    
    local tabSystem = UIUtils.createTabSystem(adminContainer.mainFrame, tabs)
    
    -- Populate the Players tab
    self:CreatePlayersTab(tabSystem.tabContents.Players)
    
    -- Populate the Game Settings tab
    self:CreateGameSettingsTab(tabSystem.tabContents.GameSettings)
    
    -- Populate the Server Stats tab
    self:CreateServerStatsTab(tabSystem.tabContents.ServerStats)
    
    -- Populate the Commands tab
    self:CreateCommandsTab(tabSystem.tabContents.Commands)
    
    -- Store UI elements for later access
    uiState.menuElements.adminContainer = adminContainer
    uiState.menuElements.tabSystem = tabSystem
    
    -- Initially hide the panel
    adminContainer.mainFrame.Visible = false
    
    return adminContainer
end

-- Create the Players tab content
function AdminControlsUI:CreatePlayersTab(parent)
    -- Create search bar at the top
    local searchBar = Instance.new("TextBox")
    searchBar.Name = "SearchBar"
    searchBar.PlaceholderText = "Search players..."
    searchBar.Text = ""
    searchBar.Size = UDim2.new(1, -20, 0, 30)
    searchBar.Position = UDim2.new(0, 10, 0, 10)
    searchBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    searchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBar.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
    searchBar.Font = Enum.Font.Gotham
    searchBar.TextSize = 14
    searchBar.BorderSizePixel = 0
    searchBar.Parent = parent
    
    -- Add corner radius to search bar
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = searchBar
    
    -- Create players list
    local playersScrolling = UIUtils.createScrollingList(
        parent,
        UDim.new(0, 10),
        UDim2.new(1, -20, 1, -100),
        UDim2.new(0, 10, 0, 50)
    )
    
    -- Create action buttons at bottom
    local actionsContainer = Instance.new("Frame")
    actionsContainer.Name = "ActionsContainer"
    actionsContainer.Size = UDim2.new(1, -20, 0, 40)
    actionsContainer.Position = UDim2.new(0, 10, 1, -45)
    actionsContainer.BackgroundTransparency = 1
    actionsContainer.Parent = parent
    
    -- Add kick button
    local kickButton = Instance.new("TextButton")
    kickButton.Name = "KickButton"
    kickButton.Size = UDim2.new(0.3, -10, 1, 0)
    kickButton.Position = UDim2.new(0, 0, 0, 0)
    kickButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    kickButton.Font = Enum.Font.GothamBold
    kickButton.Text = "Kick Player"
    kickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    kickButton.TextSize = 16
    kickButton.Parent = actionsContainer
    
    local kickCorner = Instance.new("UICorner")
    kickCorner.CornerRadius = UDim.new(0, 6)
    kickCorner.Parent = kickButton
    
    -- Add ban button
    local banButton = Instance.new("TextButton")
    banButton.Name = "BanButton"
    banButton.Size = UDim2.new(0.3, -10, 1, 0)
    banButton.Position = UDim2.new(0.35, 0, 0, 0)
    banButton.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
    banButton.Font = Enum.Font.GothamBold
    banButton.Text = "Ban Player"
    banButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    banButton.TextSize = 16
    banButton.Parent = actionsContainer
    
    local banCorner = Instance.new("UICorner")
    banCorner.CornerRadius = UDim.new(0, 6)
    banCorner.Parent = banButton
    
    -- Add teleport button
    local teleportButton = Instance.new("TextButton")
    teleportButton.Name = "TeleportButton"
    teleportButton.Size = UDim2.new(0.3, -10, 1, 0)
    teleportButton.Position = UDim2.new(0.7, 0, 0, 0)
    teleportButton.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
    teleportButton.Font = Enum.Font.GothamBold
    teleportButton.Text = "Teleport"
    teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportButton.TextSize = 16
    teleportButton.Parent = actionsContainer
    
    local teleportCorner = Instance.new("UICorner")
    teleportCorner.CornerRadius = UDim.new(0, 6)
    teleportCorner.Parent = teleportButton
    
    -- Populate players list (example - would be populated dynamically)
    self:UpdatePlayersList(playersScrolling.scrollFrame)
    
    -- Store UI elements
    uiState.menuElements.playerSearch = searchBar
    uiState.menuElements.playersList = playersScrolling.scrollFrame
    
    return parent
end

-- Update the players list with current players
function AdminControlsUI:UpdatePlayersList(scrollFrame)
    -- Clear existing player entries
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^PlayerEntry_") then
            child:Destroy()
        end
    end
    
    -- Get all players
    local playersList = Players:GetPlayers()
    
    -- Create entry for each player
    for i, plr in ipairs(playersList) do
        local entry = UIUtils.createCard(scrollFrame, 60)
        entry.Name = "PlayerEntry_" .. plr.Name
        entry.LayoutOrder = i
        
        -- Add player name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "PlayerName"
        nameLabel.Size = UDim2.new(0.7, -10, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamSemibold
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = entry
        
        -- Add selection button
        local selectButton = Instance.new("TextButton")
        selectButton.Name = "SelectButton"
        selectButton.Size = UDim2.new(0.25, -20, 0, 30)
        selectButton.Position = UDim2.new(0.75, 10, 0.5, -15)
        selectButton.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
        selectButton.Font = Enum.Font.GothamMedium
        selectButton.Text = "Select"
        selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectButton.TextSize = 14
        selectButton.Parent = entry
        
        local selectCorner = Instance.new("UICorner")
        selectCorner.CornerRadius = UDim.new(0, 6)
        selectCorner.Parent = selectButton
        
        -- Add click handler for selection
        selectButton.MouseButton1Click:Connect(function()
            self:SelectPlayer(plr.Name)
        end)
    end
end

-- Create the Game Settings tab
function AdminControlsUI:CreateGameSettingsTab(parent)
    -- Create settings container
    local settingsContainer = Instance.new("ScrollingFrame")
    settingsContainer.Name = "SettingsContainer"
    settingsContainer.Size = UDim2.new(1, -20, 1, -20)
    settingsContainer.Position = UDim2.new(0, 10, 0, 10)
    settingsContainer.BackgroundTransparency = 1
    settingsContainer.ScrollBarThickness = 6
    settingsContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    settingsContainer.CanvasSize = UDim2.new(0, 0, 0, 400)
    settingsContainer.Parent = parent
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "SettingsTitle"
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "Game Settings"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = settingsContainer
    
    -- Sample settings (these would be dynamically populated and connected to real game settings)
    local settings = {
        { name = "Player Spawn Rate", type = "slider", min = 1, max = 60, default = 10 },
        { name = "Economy Multiplier", type = "slider", min = 0.1, max = 5, default = 1 },
        { name = "Enable PvP", type = "toggle", default = false },
        { name = "Max Players", type = "number", min = 1, max = 100, default = 50 },
        { name = "Game Difficulty", type = "dropdown", options = {"Easy", "Normal", "Hard"}, default = "Normal" }
    }
    
    -- Create UI for each setting
    local yOffset = 50
    for i, setting in ipairs(settings) do
        -- Setting label
        local label = Instance.new("TextLabel")
        label.Name = setting.name .. "Label"
        label.Size = UDim2.new(0.4, -10, 0, 30)
        label.Position = UDim2.new(0, 10, 0, yOffset)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.Text = setting.name .. ":"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = settingsContainer
        
        -- Create control based on setting type
        if setting.type == "slider" then
            -- Create a slider using our progress bar
            local slider = UIUtils.createProgressBar(
                settingsContainer,
                UDim2.new(0.5, -10, 0, 30),
                UDim2.new(0.45, 0, 0, yOffset)
            )
            slider.updateProgress(setting.default / setting.max)
        elseif setting.type == "toggle" then
            -- Create a toggle switch
            local toggleButton = Instance.new("TextButton")
            toggleButton.Name = setting.name .. "Toggle"
            toggleButton.Size = UDim2.new(0, 60, 0, 30)
            toggleButton.Position = UDim2.new(0.45, 0, 0, yOffset)
            toggleButton.BackgroundColor3 = setting.default and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 180, 180)
            toggleButton.Font = Enum.Font.GothamBold
            toggleButton.Text = setting.default and "ON" or "OFF"
            toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggleButton.TextSize = 14
            toggleButton.Parent = settingsContainer
            
            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 15)
            toggleCorner.Parent = toggleButton
            
            -- Add toggle functionality
            local isOn = setting.default
            toggleButton.MouseButton1Click:Connect(function()
                isOn = not isOn
                toggleButton.Text = isOn and "ON" or "OFF"
                toggleButton.BackgroundColor3 = isOn and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 180, 180)
            end)
        elseif setting.type == "number" then
            -- Create a number input
            local inputBox = Instance.new("TextBox")
            inputBox.Name = setting.name .. "Input"
            inputBox.Size = UDim2.new(0.2, -10, 0, 30)
            inputBox.Position = UDim2.new(0.45, 0, 0, yOffset)
            inputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            inputBox.Font = Enum.Font.Gotham
            inputBox.Text = tostring(setting.default)
            inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            inputBox.TextSize = 16
            inputBox.Parent = settingsContainer
            
            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 6)
            inputCorner.Parent = inputBox
        elseif setting.type == "dropdown" then
            -- Create dropdown
            local dropdown = Instance.new("TextButton")
            dropdown.Name = setting.name .. "Dropdown"
            dropdown.Size = UDim2.new(0.5, -10, 0, 30)
            dropdown.Position = UDim2.new(0.45, 0, 0, yOffset)
            dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            dropdown.Font = Enum.Font.Gotham
            dropdown.Text = setting.default
            dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
            dropdown.TextSize = 16
            dropdown.Parent = settingsContainer
            
            local dropdownCorner = Instance.new("UICorner")
            dropdownCorner.CornerRadius = UDim.new(0, 6)
            dropdownCorner.Parent = dropdown
        end
        
        yOffset = yOffset + 60
    end
    
    -- Add save button at the bottom
    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveSettingsButton"
    saveButton.Size = UDim2.new(0.3, 0, 0, 40)
    saveButton.Position = UDim2.new(0.5, -0.15 * parent.Size.X.Offset, 0, yOffset)
    saveButton.BackgroundColor3 = Color3.fromRGB(0, 120, 210)
    saveButton.Font = Enum.Font.GothamBold
    saveButton.Text = "Save Settings"
    saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveButton.TextSize = 16
    saveButton.Parent = settingsContainer
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 8)
    saveCorner.Parent = saveButton
    
    -- Update canvas size
    settingsContainer.CanvasSize = UDim2.new(0, 0, 0, yOffset + 60)
    
    return parent
end

-- Create the Server Stats tab
function AdminControlsUI:CreateServerStatsTab(parent)
    -- Add stats header
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Name = "StatsHeader"
    headerLabel.Size = UDim2.new(1, -20, 0, 30)
    headerLabel.Position = UDim2.new(0, 10, 0, 10)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.Text = "Server Statistics"
    headerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    headerLabel.TextSize = 18
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Parent = parent
    
    -- Create server stats cards
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(1, -20, 0, 300)
    statsContainer.Position = UDim2.new(0, 10, 0, 50)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = parent
    
    -- Add stats cards
    local stats = {
        { name = "Players", value = tostring(#Players:GetPlayers()) .. "/" .. Players.MaxPlayers, icon = "rbxassetid://7025806665" },
        { name = "Uptime", value = "2h 45m", icon = "rbxassetid://7025807372" },
        { name = "Memory", value = "428 MB", icon = "rbxassetid://7025809274" },
        { name = "CPU", value = "32%", icon = "rbxassetid://7025807166" }
    }
    
    -- Create grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.48, 0, 0, 120)
    gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = statsContainer
    
    -- Add stat cards
    for i, stat in ipairs(stats) do
        local card = Instance.new("Frame")
        card.Name = stat.name .. "Card"
        card.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        card.BorderSizePixel = 0
        card.LayoutOrder = i
        card.Parent = statsContainer
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card
        
        -- Add icon
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 20, 0, 20)
        icon.BackgroundTransparency = 1
        icon.Image = stat.icon
        icon.Parent = card
        
        -- Add stat name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "StatName"
        nameLabel.Size = UDim2.new(1, -100, 0, 30)
        nameLabel.Position = UDim2.new(0, 80, 0, 25)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.Text = stat.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 18
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = card
        
        -- Add value 
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "StatValue"
        valueLabel.Size = UDim2.new(0, 150, 0, 40)
        valueLabel.Position = UDim2.new(0, 20, 0, 70)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.Text = stat.value
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.TextSize = 24
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.Parent = card
    end
    
    -- Add refresh button
    local refreshButton = Instance.new("TextButton")
    refreshButton.Name = "RefreshButton"
    refreshButton.Size = UDim2.new(0, 120, 0, 40)
    refreshButton.Position = UDim2.new(0.5, -60, 0, 360)
    refreshButton.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
    refreshButton.Font = Enum.Font.GothamBold
    refreshButton.Text = "Refresh"
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.TextSize = 16
    refreshButton.Parent = parent
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 8)
    refreshCorner.Parent = refreshButton
    
    return parent
end

-- Create the Commands tab
function AdminControlsUI:CreateCommandsTab(parent)
    -- Create command input
    local commandBox = Instance.new("TextBox")
    commandBox.Name = "CommandInput"
    commandBox.PlaceholderText = "Type command here..."
    commandBox.Text = ""
    commandBox.Size = UDim2.new(1, -120, 0, 40)
    commandBox.Position = UDim2.new(0, 10, 0, 10)
    commandBox.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    commandBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    commandBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
    commandBox.Font = Enum.Font.Code
    commandBox.TextSize = 16
    commandBox.TextXAlignment = Enum.TextXAlignment.Left
    commandBox.Parent = parent
    
    local commandCorner = Instance.new("UICorner")
    commandCorner.CornerRadius = UDim.new(0, 6)
    commandCorner.Parent = commandBox
    
    -- Execute button
    local executeButton = Instance.new("TextButton")
    executeButton.Name = "ExecuteButton"
    executeButton.Size = UDim2.new(0, 90, 0, 40)
    executeButton.Position = UDim2.new(1, -100, 0, 10)
    executeButton.BackgroundColor3 = Color3.fromRGB(0, 120, 210)
    executeButton.Font = Enum.Font.GothamBold
    executeButton.Text = "Run"
    executeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    executeButton.TextSize = 16
    executeButton.Parent = parent
    
    local executeCorner = Instance.new("UICorner")
    executeCorner.CornerRadius = UDim.new(0, 6)
    executeCorner.Parent = executeButton
    
    -- Output log
    local outputLog = Instance.new("ScrollingFrame")
    outputLog.Name = "OutputLog"
    outputLog.Size = UDim2.new(1, -20, 0, 280)
    outputLog.Position = UDim2.new(0, 10, 0, 60)
    outputLog.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    outputLog.BorderSizePixel = 0
    outputLog.ScrollBarThickness = 6
    outputLog.ScrollingDirection = Enum.ScrollingDirection.Y
    outputLog.CanvasSize = UDim2.new(0, 0, 0, 0)
    outputLog.Parent = parent
    
    local outputCorner = Instance.new("UICorner")
    outputCorner.CornerRadius = UDim.new(0, 6)
    outputCorner.Parent = outputLog
    
    -- Add padding to the output log
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = outputLog
    
    -- Layout for log entries
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = outputLog
    
    -- Add some sample output
    self:AddCommandOutput(outputLog, "System", "Admin console initialized")
    self:AddCommandOutput(outputLog, "Help", "Type 'help' for a list of commands")
    
    -- Add common commands
    local commandsContainer = Instance.new("Frame")
    commandsContainer.Name = "CommandsContainer"
    commandsContainer.Size = UDim2.new(1, -20, 0, 40)
    commandsContainer.Position = UDim2.new(0, 10, 1, -50)
    commandsContainer.BackgroundTransparency = 1
    commandsContainer.Parent = parent
    
    -- Common command buttons
    local commands = {"help", "kick", "ban", "shutdown", "heal"}
    local buttonWidth = 1 / #commands
    
    for i, cmd in ipairs(commands) do
        local cmdButton = Instance.new("TextButton")
        cmdButton.Name = cmd .. "Button"
        cmdButton.Size = UDim2.new(buttonWidth, -10, 1, 0)
        cmdButton.Position = UDim2.new(buttonWidth * (i-1), 5, 0, 0)
        cmdButton.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        cmdButton.Font = Enum.Font.GothamMedium
        cmdButton.Text = cmd
        cmdButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        cmdButton.TextSize = 14
        cmdButton.Parent = commandsContainer
        
        local cmdCorner = Instance.new("UICorner")
        cmdCorner.CornerRadius = UDim.new(0, 6)
        cmdCorner.Parent = cmdButton
        
        -- Click handler to insert command
        cmdButton.MouseButton1Click:Connect(function()
            commandBox.Text = cmd .. " "
            commandBox:CaptureFocus()
        end)
    end
    
    -- Connect execute button
    executeButton.MouseButton1Click:Connect(function()
        self:ExecuteCommand(commandBox.Text, outputLog)
    end)
    
    -- Connect enter key to execute
    commandBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and commandBox.Text ~= "" then
            self:ExecuteCommand(commandBox.Text, outputLog)
        end
    end)
    
    -- Store UI elements
    uiState.menuElements.commandBox = commandBox
    uiState.menuElements.outputLog = outputLog
    
    return parent
end

-- Helper function to add output to the command log
function AdminControlsUI:AddCommandOutput(outputLog, prefix, message)
    -- Create a new log entry
    local logEntry = Instance.new("TextLabel")
    logEntry.Name = "LogEntry" .. #outputLog:GetChildren()
    logEntry.Size = UDim2.new(1, 0, 0, 20)
    logEntry.BackgroundTransparency = 1
    logEntry.Font = Enum.Font.Code
    logEntry.Text = "[" .. prefix .. "] " .. message
    logEntry.TextColor3 = prefix == "Error" and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 255, 255)
    logEntry.TextSize = 14
    logEntry.TextXAlignment = Enum.TextXAlignment.Left
    logEntry.TextWrapped = true
    logEntry.AutomaticSize = Enum.AutomaticSize.Y
    logEntry.Parent = outputLog
    
    -- Update canvas size
    local layout = outputLog:FindFirstChildOfClass("UIListLayout")
    if layout then
        outputLog.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        -- Scroll to bottom
        outputLog.CanvasPosition = Vector2.new(0, layout.AbsoluteContentSize.Y)
    end
    
    return logEntry
end

-- Execute a command
function AdminControlsUI:ExecuteCommand(commandText, outputLog)
    if not commandText or commandText == "" then return end
    
    -- Here you would connect to your actual admin command system
    -- This is just a sample implementation that shows output
    
    -- Add the command to the log
    self:AddCommandOutput(outputLog, "Command", commandText)
    
    -- Parse the command
    local args = commandText:split(" ")
    local command = args[1]:lower()
    table.remove(args, 1)
    
    -- Process commands
    if command == "help" then
        self:AddCommandOutput(outputLog, "Help", "Available commands: help, kick [player], ban [player], shutdown, heal [player], clear")
    elseif command == "kick" then
        if #args < 1 then
            self:AddCommandOutput(outputLog, "Error", "Usage: kick [player]")
        else
            self:AddCommandOutput(outputLog, "System", "Attempting to kick player: " .. args[1])
        end
    elseif command == "ban" then
        if #args < 1 then
            self:AddCommandOutput(outputLog, "Error", "Usage: ban [player]")
        else
            self:AddCommandOutput(outputLog, "System", "Attempting to ban player: " .. args[1])
        end
    elseif command == "shutdown" then
        self:AddCommandOutput(outputLog, "System", "Server shutdown initiated")
    elseif command == "heal" then
        if #args < 1 then
            self:AddCommandOutput(outputLog, "Error", "Usage: heal [player]")
        else
            self:AddCommandOutput(outputLog, "System", "Healing player: " .. args[1])
        end
    elseif command == "clear" then
        -- Clear the output log
        for _, child in ipairs(outputLog:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        outputLog.CanvasSize = UDim2.new(0, 0, 0, 0)
        self:AddCommandOutput(outputLog, "System", "Console cleared")
    else
        self:AddCommandOutput(outputLog, "Error", "Unknown command: " .. command)
    end
    
    -- Reset the command box
    if uiState.menuElements.commandBox then
        uiState.menuElements.commandBox.Text = ""
    end
end

-- Select a player in the player list
function AdminControlsUI:SelectPlayer(playerName)
    -- Here you would highlight the selected player and enable appropriate actions
    print("Selected player: " .. playerName)
    
    -- Sample implementation to show a notification
    local modalDialog = UIUtils.createModalDialog(
        "Player Selected",
        "Selected player: " .. playerName .. "\n\nWhat action would you like to take?",
        UDim2.new(0, 400, 0, 200)
    )
    
    -- Customize the dialog
    if modalDialog then
        -- Replace the default OK button with custom buttons
        if modalDialog.okButton then
            modalDialog.okButton:Destroy()
        end
        
        -- Add kick button
        local kickButton = Instance.new("TextButton")
        kickButton.Name = "KickButton"
        kickButton.Size = UDim2.new(0, 100, 0, 40)
        kickButton.Position = UDim2.new(0.3, -50, 0, 0)
        kickButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        kickButton.Font = Enum.Font.GothamBold
        kickButton.Text = "Kick"
        kickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        kickButton.TextSize = 16
        kickButton.Parent = modalDialog.buttonsContainer
        
        local kickCorner = Instance.new("UICorner")
        kickCorner.CornerRadius = UDim.new(0, 6)
        kickCorner.Parent = kickButton
        
        -- Add teleport button
        local teleportButton = Instance.new("TextButton")
        teleportButton.Name = "TeleportButton"
        teleportButton.Size = UDim2.new(0, 100, 0, 40)
        teleportButton.Position = UDim2.new(0.7, -50, 0, 0)
        teleportButton.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
        teleportButton.Font = Enum.Font.GothamBold
        teleportButton.Text = "Teleport"
        teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        teleportButton.TextSize = 16
        teleportButton.Parent = modalDialog.buttonsContainer
        
        local teleportCorner = Instance.new("UICorner")
        teleportCorner.CornerRadius = UDim.new(0, 6)
        teleportCorner.Parent = teleportButton
        
        -- Connect button events
        kickButton.MouseButton1Click:Connect(function()
            -- Simulate kick action
            if uiState.menuElements.outputLog then
                self:AddCommandOutput(uiState.menuElements.outputLog, "System", "Kicking player: " .. playerName)
            end
            modalDialog.destroy()
        end)
        
        teleportButton.MouseButton1Click:Connect(function()
            -- Simulate teleport action
            if uiState.menuElements.outputLog then
                self:AddCommandOutput(uiState.menuElements.outputLog, "System", "Teleporting to player: " .. playerName)
            end
            modalDialog.destroy()
        end)
    end
end

-- Toggle the admin panel visibility
function AdminControlsUI:ToggleAdminPanel()
    if not uiState.menuElements.adminContainer then
        warn("Admin panel not initialized")
        return
    end
    
    uiState.adminPanelVisible = not uiState.adminPanelVisible
    
    local mainFrame = uiState.menuElements.adminContainer.mainFrame
    
    if uiState.adminPanelVisible then
        -- Show the panel with animation
        mainFrame.Visible = true
        mainFrame.Position = UDim2.new(
            mainFrame.Position.X.Scale,
            mainFrame.Position.X.Offset,
            0.6, 0
        )
        mainFrame.BackgroundTransparency = 0.5
        
        -- Tween to final position
        TweenService:Create(
            mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {
                Position = UDim2.new(
                    mainFrame.Position.X.Scale,
                    mainFrame.Position.X.Offset,
                    0.5, 0
                ),
                BackgroundTransparency = 0.1
            }
        ):Play()
        
        -- Update players list
        self:UpdatePlayersList(uiState.menuElements.playersList)
    else
        -- Hide with animation
        TweenService:Create(
            mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = UDim2.new(
                    mainFrame.Position.X.Scale,
                    mainFrame.Position.X.Offset,
                    0.6, 0
                ),
                BackgroundTransparency = 1
            }
        ):Play()
        
        -- Hide after animation
        task.delay(0.3, function()
            mainFrame.Visible = false
        end)
    end
end

-- Initialize the module when required
return AdminControlsUI:Initialize()