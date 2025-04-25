--[[
    AdminControlsUI.client.luau
]]

local GameSystem = require(game.ReplicatedStorage.GameSystem)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Admin Controls UI Module
local AdminControlsUI = {} 

function AdminControlsUI.initialize()
	-- Create the main panel frame
	local AdminDashboard = Instance.new("Frame")
	AdminDashboard.Name = "AdminDashboard"
	AdminDashboard.Size = UDim2.fromScale(0.8, 0.8)
	AdminDashboard.Position = UDim2.fromScale(0.1, 0.1)
	AdminDashboard.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	AdminDashboard.BorderSizePixel = 0
	AdminDashboard.ZIndex = 15
	AdminDashboard.Visible = false
	AdminDashboard.Parent = playerGui

	-- Apply corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = AdminDashboard
	
	-- Add title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 30
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = "Admin Dashboard"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.Parent = AdminDashboard

	-- Add close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Text = "Close"
	closeButton.Size = UDim2.fromScale(0.1, 0.1)
	closeButton.Position = UDim2.fromScale(0.85, 0.05)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Parent = AdminDashboard
	closeButton.MouseButton1Click:Connect(function()
		AdminControlsUI.hideAdminDashboard()	
	end)

	-- Create Confirmation Box
	local confirmationBox = Instance.new("Frame")
	confirmationBox.Name = "ConfirmationBox"
	confirmationBox.Size = UDim2.fromScale(0.4, 0.3)
	confirmationBox.Position = UDim2.fromScale(0.3, 0.35)
	confirmationBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	confirmationBox.BorderSizePixel = 0
	confirmationBox.ZIndex = 20
	confirmationBox.Visible = false
	confirmationBox.Parent = AdminDashboard

	-- Apply corner rounding
	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 10)
	corner2.Parent = confirmationBox

	--Confirmation Message
	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Size = UDim2.new(1, 0, 0.5, 0)
	message.Position = UDim2.new(0, 0, 0.1, 0)
	message.BackgroundTransparency = 1
	message.Font = Enum.Font.Gotham
	message.TextSize = 20
	message.TextColor3 = Color3.fromRGB(255, 255, 255)
	message.Text = "Are you sure you want to reset the game?"
	message.TextWrapped = true
	message.TextXAlignment = Enum.TextXAlignment.Center
	message.TextYAlignment = Enum.TextYAlignment.Center
	message.Parent = confirmationBox
	

	local function hideConfirmationBox()
		confirmationBox.Visible = false
	end

	local function resetAction()
		confirmationBox.Visible = true
	end
	

	-- Add reset button
	local resetButton = Instance.new("TextButton")
	resetButton.Name = "ResetButton"
	resetButton.Text = "Reset"
	resetButton.Size = UDim2.fromScale(0.2, 0.1)
	resetButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	resetButton.Parent = AdminDashboard
	resetButton.MouseButton1Click:Connect(function()
		resetAction()	
	end)

	-- Confirmation Title
	local confirmationTitle = Instance.new("TextLabel")
	confirmationTitle.Name = "ConfirmationTitle"
	confirmationTitle.Size = UDim2.new(1, 0, 0.2, 0)
	confirmationTitle.BackgroundTransparency = 1
	confirmationTitle.Font = Enum.Font.GothamBold
	confirmationTitle.TextSize = 24
	confirmationTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmationTitle.Text = "Confirm Reset"
	confirmationTitle.TextXAlignment = Enum.TextXAlignment.Center
	confirmationTitle.TextYAlignment = Enum.TextYAlignment.Center
	confirmationTitle.Parent = confirmationBox

	-- Confirmation Button
	local confirmButton = Instance.new("TextButton")
	confirmButton.Name = "Confirm"
	confirmButton.Text = "Confirm"
	confirmButton.Size = UDim2.fromScale(0.4, 0.2)
	confirmButton.Position = UDim2.fromScale(0.1, 0.7)
	confirmButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	confirmButton.Parent = confirmationBox
	confirmButton.MouseButton1Click:Connect(GameSystem.reset)

	local cancelButton = confirmButton:Clone()
	cancelButton.Text = "Cancel"
	cancelButton.Position = UDim2.fromScale(0.55, 0.7)
	cancelButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	cancelButton.MouseButton1Click:Connect(hideConfirmationBox)
	cancelButton.Parent = confirmationBox

	AdminControlsUI.AdminDashboard = AdminDashboard
end
function AdminControlsUI.showAdminDashboard()
	AdminControlsUI.AdminDashboard.Visible = true
end

function AdminControlsUI.hideAdminDashboard()
	AdminControlsUI.AdminDashboard.Visible = false
end


-- Switch between tabs
function AdminControlsUI:SwitchTab(tabId)
    -- Update current tab
    uiState.currentTab = tabId
    
    -- Update tab button appearances
    local tabs = {"Players", "GameSettings", "ServerStats", "Commands"}
    for _, tab in ipairs(tabs) do
        local tabButton = uiState.menuElements[tab .. "Tab"]
        local contentFrame = uiState.menuElements[tab .. "Content"]
        
        if tabButton and contentFrame then
            tabButton.BackgroundColor3 = tab == tabId and UIStyle.Colors.TabActive or UIStyle.Colors.TabInactive
            contentFrame.Visible = (tab == tabId)
        end
    end
    
    -- Refresh content if needed
    if tabId == "Players" then
        self:UpdatePlayersList()
    elseif tabId == "ServerStats" then
        self:UpdateServerStats()
    end
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
    
    -- Apply style
    UIStyle.applyStyle(searchBar, "input")
    searchBar.Parent = parent
    
    -- Create players list container
    local playersContainer = Instance.new("Frame")
    playersContainer.Name = "PlayersContainer"
    playersContainer.Size = UDim2.new(1, -20, 1, -100)
    playersContainer.Position = UDim2.new(0, 10, 0, 50)
    playersContainer.BackgroundTransparency = 1
    playersContainer.Parent = parent
    
    -- Create scrolling frame for players
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "PlayersList"
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.Parent = playersContainer
    
    -- Add layout for player entries
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Parent = scrollFrame
    
    -- Create action buttons at bottom
    local actionsContainer = Instance.new("Frame")
    actionsContainer.Name = "ActionsContainer"
    actionsContainer.Size = UDim2.new(1, -20, 0, 40)
    actionsContainer.Position = UDim2.new(0, 10, 1, -45)
    actionsContainer.BackgroundTransparency = 1
    actionsContainer.Parent = parent
    
    -- Add kick button
    local kickButton = ButtonFactory.createIconButton("Close", "Kick Player", UDim2.new(0.3, -10, 1, 0), UDim2.new(0, 0, 0, 0), function()
        if uiState.selectedPlayer then
            -- Show confirmation dialog
            self:ShowKickConfirmation(uiState.selectedPlayer)
        else
            DialogFactory.createNotification("No player selected", 3, "warning")
        end
    end, "danger")
    kickButton.Parent = actionsContainer
    
    -- Add ban button
    local banButton = ButtonFactory.createIconButton("Lock", "Ban Player", UDim2.new(0.3, -10, 1, 0), UDim2.new(0.35, 0, 0, 0), function()
        if uiState.selectedPlayer then
            -- Show confirmation dialog
            self:ShowBanConfirmation(uiState.selectedPlayer)
        else
            DialogFactory.createNotification("No player selected", 3, "warning")
        end
    end, "danger")
    banButton.Parent = actionsContainer
    
    -- Add teleport button
    local teleportButton = ButtonFactory.createIconButton("ArrowUp", "Teleport", UDim2.new(0.3, -10, 1, 0), UDim2.new(0.7, 0, 0, 0), function()
        if uiState.selectedPlayer then
            local targetPlayer = Players:FindFirstChild(uiState.selectedPlayer)
            if targetPlayer and targetPlayer.Character then
                player.Character:SetPrimaryPartCFrame(targetPlayer.Character:GetPrimaryPartCFrame())
                DialogFactory.createNotification("Teleported to " .. uiState.selectedPlayer, 3, "info")
            else
                DialogFactory.createNotification("Could not teleport to " .. uiState.selectedPlayer, 3, "error")
            end
        else
            DialogFactory.createNotification("No player selected", 3, "warning")
        end
    end)
    teleportButton.Parent = actionsContainer
    
    -- Store UI elements for later access
    uiState.menuElements.playerSearch = searchBar
    uiState.menuElements.playersList = scrollFrame
    uiState.menuElements.kickButton = kickButton
    uiState.menuElements.banButton = banButton
    uiState.menuElements.teleportButton = teleportButton
    
    -- Connect search functionality
    searchBar.Changed:Connect(function(prop)
        if prop == "Text" then
            self:FilterPlayersList(searchBar.Text)
        end
    end)
    
    -- Update the player list
    self:UpdatePlayersList()
    
    return parent
end

-- Update players list
function AdminControlsUI:UpdatePlayersList()
    local scrollFrame = uiState.menuElements.playersList
    if not scrollFrame then return end
    
    -- Clear existing entries
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get all players
    local playersList = Players:GetPlayers()
    
    -- Add entries for each player
    for i, plr in ipairs(playersList) do
        -- Create player entry card
        local entryFrame = Instance.new("Frame")
        entryFrame.Name = "PlayerEntry_" .. plr.Name
        entryFrame.Size = UDim2.new(1, -10, 0, 60)
        entryFrame.BackgroundColor3 = UIStyle.Colors.CardBackground
        entryFrame.BorderSizePixel = 0
        
        -- Add corner rounding
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = entryFrame
        
        -- Add player name label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "PlayerName"
        nameLabel.Size = UDim2.new(0.7, -10, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = UIStyle.Fonts.Bold
        nameLabel.TextSize = UIStyle.TextSizes.Medium
        nameLabel.TextColor3 = UIStyle.Colors.Text
        nameLabel.Text = plr.Name
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.Parent = entryFrame
        
        -- Add select button
        local selectButton = ButtonFactory.createButton("Select", UDim2.new(0.3, -10, 0, 30), UDim2.new(0.7, 5, 0.5, -15), function()
            self:SelectPlayer(plr.Name)
        end)
        selectButton.Parent = entryFrame
        
        -- Set initial selection state
        if uiState.selectedPlayer == plr.Name then
            entryFrame.BackgroundColor3 = UIStyle.Colors.Primary
            nameLabel.Font = UIStyle.Fonts.Title
        end
        
        entryFrame.Parent = scrollFrame
    end
    
    -- Update canvas size
    local listLayout = scrollFrame:FindFirstChildOfClass("UIListLayout")
    if listLayout then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 5)
    end
end

-- Filter players list by search term
function AdminControlsUI:FilterPlayersList(searchTerm)
    local scrollFrame = uiState.menuElements.playersList
    if not scrollFrame then return end
    
    searchTerm = searchTerm:lower()
    
    -- Show/hide entries based on search
    for _, entry in ipairs(scrollFrame:GetChildren()) do
        if entry:IsA("Frame") and entry.Name:sub(1, 13) == "PlayerEntry_" then
            local playerName = entry.Name:sub(14)
            entry.Visible = searchTerm == "" or playerName:lower():find(searchTerm, 1, true)
        end
    end
end

-- Select a player from the list
function AdminControlsUI:SelectPlayer(playerName)
    -- Update selected player
    uiState.selectedPlayer = playerName
    
    -- Update UI to show selected player
    self:UpdatePlayersList()
    
    -- Show notification
    DialogFactory.createNotification("Selected player: " .. playerName, 2, "info")
end

-- Show kick confirmation dialog
function AdminControlsUI:ShowKickConfirmation(playerName)
    DialogFactory.createConfirmationDialog(
        "Confirm Kick",
        "Are you sure you want to kick " .. playerName .. " from the game?",
        function()
            -- Execute kick command
            self:ExecuteCommand("kick " .. playerName)
            DialogFactory.createNotification("Player " .. playerName .. " has been kicked", 3, "success")
        end,
        function()
            -- Cancelled
            DialogFactory.createNotification("Kick operation cancelled", 2, "info")
        end,
        {
            confirmText = "Kick Player", 
            cancelText = "Cancel"
        }
    )
end

-- Show ban confirmation dialog
function AdminControlsUI:ShowBanConfirmation(playerName)
    DialogFactory.createConfirmationDialog(
        "Confirm Ban",
        "Are you sure you want to ban " .. playerName .. " from the game? This is a critical action that should be used carefully.",
        function()
            -- Execute ban command
            self:ExecuteCommand("ban " .. playerName)
            DialogFactory.createNotification("Player " .. playerName .. " has been banned", 3, "success")
        end,
        function()
            -- Cancelled
            DialogFactory.createNotification("Ban operation cancelled", 2, "info")
        end,
        {
            confirmText = "Ban Player", 
            cancelText = "Cancel"
        }
    )
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
    titleLabel.Font = UIStyle.Fonts.Bold
    titleLabel.Text = "Game Settings"
    titleLabel.TextColor3 = UIStyle.Colors.Text
    titleLabel.TextSize = UIStyle.TextSizes.Subheader
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = settingsContainer
    
    -- Sample settings (these would be dynamically populated and connected to real game settings)
    local settings = {
        { name = "Player Spawn Rate", type = "slider", min = 1, max = 60, default = 10, icon = "Clock" },
        { name = "Economy Multiplier", type = "slider", min = 0.1, max = 5, default = 1, step = 0.1, icon = "Coin" },
        { name = "Enable PvP", type = "toggle", default = false, icon = "Warning" },
        { name = "Max Players", type = "number", min = 1, max = 100, default = 50, icon = "User" },
        { name = "Game Difficulty", type = "dropdown", options = {"Easy", "Normal", "Hard"}, default = "Normal", icon = "Settings" }
    }
    
    -- Create UI for each setting
    local yOffset = 50
    for i, setting in ipairs(settings) do
        -- Create setting card
        local settingCard = Instance.new("Frame")
        settingCard.Name = setting.name .. "Setting"
        settingCard.Size = UDim2.new(1, -20, 0, 50)
        settingCard.Position = UDim2.new(0, 10, 0, yOffset)
        settingCard.BackgroundColor3 = UIStyle.Colors.CardBackground
        settingCard.BorderSizePixel = 0
        settingCard.Parent = settingsContainer
        
        -- Add corner rounding
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = settingCard
        
        -- Add icon
        local icon = IconSet.createIcon(setting.icon, UDim2.new(0, 30, 0, 30), UDim2.new(0, 10, 0.5, -15))
        icon.Parent = settingCard
        
        -- Setting label
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0.4, -50, 1, 0)
        label.Position = UDim2.new(0, 50, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = UIStyle.Fonts.SemiBold
        label.Text = setting.name
        label.TextColor3 = UIStyle.Colors.Text
        label.TextSize = UIStyle.TextSizes.Medium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = settingCard
        
        -- Create control based on setting type
        if setting.type == "slider" then
            -- For brevity, just using a TextButton as a placeholder for the slider control
            local sliderValue = Instance.new("TextLabel")
            sliderValue.Name = "Value"
            sliderValue.Size = UDim2.new(0.2, 0, 0, 30)
            sliderValue.Position = UDim2.new(0.8, -10, 0.5, -15)
            sliderValue.BackgroundColor3 = UIStyle.Colors.BackgroundDark
            sliderValue.TextColor3 = UIStyle.Colors.Text
            sliderValue.Font = UIStyle.Fonts.Bold
            sliderValue.TextSize = UIStyle.TextSizes.Medium
            sliderValue.Text = tostring(setting.default)
            sliderValue.TextXAlignment = Enum.TextXAlignment.Center
            
            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, 6)
            sliderCorner.Parent = sliderValue
            
            sliderValue.Parent = settingCard
        elseif setting.type == "toggle" then
            -- Create a toggle switch
            local toggleButton = ButtonFactory.createToggleButton(
                "", 
                setting.default, 
                UDim2.new(0, 60, 0, 30),
                UDim2.new(0.8, -30, 0.5, -15),
                function(isOn)
                    -- This would connect to backend systems to update the setting
                    DialogFactory.createNotification(setting.name .. " set to " .. (isOn and "ON" or "OFF"), 2, "info")
                end
            )
            toggleButton.Parent = settingCard
        elseif setting.type == "number" then
            -- Create a number input
            local inputBox = Instance.new("TextBox")
            inputBox.Name = "Input"
            inputBox.Size = UDim2.new(0.2, 0, 0, 30)
            inputBox.Position = UDim2.new(0.8, -10, 0.5, -15)
            inputBox.BackgroundColor3 = UIStyle.Colors.BackgroundDark
            inputBox.TextColor3 = UIStyle.Colors.Text
            inputBox.Font = UIStyle.Fonts.Regular
            inputBox.TextSize = UIStyle.TextSizes.Medium
            inputBox.Text = tostring(setting.default)
            inputBox.TextXAlignment = Enum.TextXAlignment.Center
            
            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 6)
            inputCorner.Parent = inputBox
            
            inputBox.Parent = settingCard
        elseif setting.type == "dropdown" then
            -- Create a dropdown button (simplified)
            local dropdown = ButtonFactory.createButton(
                setting.default,
                UDim2.new(0.4, 0, 0, 30),
                UDim2.new(0.6, -10, 0.5, -15),
                function()
                    -- This would open a dropdown menu with options
                    DialogFactory.createNotification("Dropdown functionality would be implemented here", 2, "info")
                end
            )
            dropdown.Parent = settingCard
        end
        
        yOffset = yOffset + 60
    end
    
    -- Add save button at the bottom
    local saveButton = ButtonFactory.createIconButton("Check", "Save Settings", UDim2.new(0.3, 0, 0, 40), UDim2.new(0.5, -0.15 * parent.Size.X.Offset, 0, yOffset), function()
        -- Show confirmation before saving
        DialogFactory.createConfirmationDialog(
            "Save Settings",
            "Are you sure you want to save these settings? This might affect all players in the game.",
            function()
                DialogFactory.createNotification("Settings saved successfully", 3, "success")
            end,
            nil,
            { confirmText = "Save" }
        )
    end, "success")
    saveButton.Parent = settingsContainer
    
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
    headerLabel.Font = UIStyle.Fonts.Bold
    headerLabel.Text = "Server Statistics"
    headerLabel.TextColor3 = UIStyle.Colors.Text
    headerLabel.TextSize = UIStyle.TextSizes.Subheader
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Parent = parent
    
    -- Create server stats cards
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(1, -20, 0, 300)
    statsContainer.Position = UDim2.new(0, 10, 0, 50)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = parent
    
    -- Create grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.48, 0, 0, 120)
    gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = statsContainer
    
    -- Store UI elements for later update
    uiState.menuElements.statsContainer = statsContainer
    
    -- Initialize stats data
    self:UpdateServerStats()
    
    -- Add refresh button
    local refreshButton = ButtonFactory.createIconButton("ArrowUp", "Refresh", UDim2.new(0, 120, 0, 40), UDim2.new(0.5, -60, 0, 360), function()
        self:UpdateServerStats()
        DialogFactory.createNotification("Server statistics refreshed", 2, "info")
    end)
    refreshButton.Parent = parent
    
    return parent
end

-- Update server stats
function AdminControlsUI:UpdateServerStats()
    local statsContainer = uiState.menuElements.statsContainer
    if not statsContainer then return end
    
    -- Clear existing stat cards
    for _, child in ipairs(statsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get current stats
    -- In a real implementation, these would be retrieved from backend systems
    local stats = {
        { name = "Players", value = tostring(#Players:GetPlayers()) .. "/" .. Players.MaxPlayers, icon = "User" },
        { name = "Uptime", value = "2h 45m", icon = "Clock" },
        { name = "Memory", value = "428 MB", icon = "Warning" },
        { name = "CPU", value = "32%", icon = "Gear" }
    }
    
    -- Create stat cards
    for i, stat in ipairs(stats) do
        -- Create card frame
        local card = Instance.new("Frame")
        card.Name = stat.name .. "Card"
        card.BackgroundColor3 = UIStyle.Colors.CardBackground
        card.LayoutOrder = i
        card.Parent = statsContainer
        
        -- Add corner radius
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card
        
        -- Create icon
        local icon = IconSet.createIcon(stat.icon, UDim2.new(0, 40, 0, 40), UDim2.new(0, 20, 0, 20))
        icon.Parent = card
        
        -- Add stat name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -100, 0, 30)
        nameLabel.Position = UDim2.new(0, 80, 0, 25)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = UIStyle.Fonts.SemiBold
        nameLabel.Text = stat.name
        nameLabel.TextColor3 = UIStyle.Colors.Text
        nameLabel.TextSize = UIStyle.TextSizes.Medium
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = card
        
        -- Add value
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 150, 0, 40)
        valueLabel.Position = UDim2.new(0, 20, 0, 70)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Font = UIStyle.Fonts.Bold
        valueLabel.Text = stat.value
        valueLabel.TextColor3 = UIStyle.Colors.Text
        valueLabel.TextSize = UIStyle.TextSizes.Large
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.Parent = card
    end
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
    
    -- Apply style
    UIStyle.applyStyle(commandBox, "input")
    commandBox.Parent = parent
    
    -- Execute button
    local executeButton = ButtonFactory.createIconButton("Play", "Run", UDim2.new(0, 100, 0, 40), UDim2.new(1, -110, 0, 10), function()
        if commandBox.Text ~= "" then
            self:ExecuteCommand(commandBox.Text)
            commandBox.Text = "" -- Clear after execution
        end
    end)
    executeButton.Parent = parent
    
    -- Output log
    local outputLog = Instance.new("ScrollingFrame")
    outputLog.Name = "OutputLog"
    outputLog.Size = UDim2.new(1, -20, 0, 280)
    outputLog.Position = UDim2.new(0, 10, 0, 60)
    outputLog.BackgroundColor3 = UIStyle.Colors.BackgroundDark
    outputLog.BorderSizePixel = 0
    outputLog.ScrollBarThickness = 6
    outputLog.ScrollingDirection = Enum.ScrollingDirection.Y
    outputLog.CanvasSize = UDim2.new(0, 0, 0, 0)
    outputLog.Parent = parent
    
    -- Add corner radius
    local outputCorner = Instance.new("UICorner")
    outputCorner.CornerRadius = UDim.new(0, 8)
    outputCorner.Parent = outputLog
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = outputLog
    
    -- Add list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = outputLog
    
    -- Add initial output
    self:AddCommandOutput(outputLog, "System", "Admin console initialized")
    self:AddCommandOutput(outputLog, "Help", "Type 'help' for a list of commands")
    
    -- Add command shortcuts
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
        local cmdButton = ButtonFactory.createButton(
            cmd,
            UDim2.new(buttonWidth, -10, 1, 0),
            UDim2.new(buttonWidth * (i-1), 5, 0, 0),
            function()
                commandBox.Text = cmd .. " "
                commandBox:CaptureFocus()
            end
        )
        cmdButton.Parent = commandsContainer
    end
    
    -- Connect enter key to execute command
    commandBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and commandBox.Text ~= "" then
            self:ExecuteCommand(commandBox.Text)
            commandBox.Text = "" -- Clear after execution
        end
    end)
    
    -- Store UI elements
    uiState.menuElements.commandBox = commandBox
    uiState.menuElements.outputLog = outputLog
    
    return parent
end

-- Add output to the command log
function AdminControlsUI:AddCommandOutput(outputLog, prefix, message)
    if not outputLog then
        outputLog = uiState.menuElements.outputLog
        if not outputLog then return end
    end
    
    -- Create a new log entry
    local logEntry = Instance.new("TextLabel")
    logEntry.Name = "LogEntry" .. #outputLog:GetChildren()
    logEntry.Size = UDim2.new(1, 0, 0, 20)
    logEntry.BackgroundTransparency = 1
    logEntry.Font = UIStyle.Fonts.Mono
    logEntry.Text = "[" .. prefix .. "] " .. message
    logEntry.TextColor3 = prefix == "Error" and UIStyle.Colors.Danger or UIStyle.Colors.Text
    logEntry.TextSize = UIStyle.TextSizes.Medium
    logEntry.TextXAlignment = Enum.TextXAlignment.Left
    logEntry.TextWrapped = true
    logEntry.AutomaticSize = Enum.AutomaticSize.Y
    logEntry.LayoutOrder = #outputLog:GetChildren() -- Order by creation order
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
function AdminControlsUI:ExecuteCommand(commandText)
    if not commandText or commandText == "" then return end
    
    local outputLog = uiState.menuElements.outputLog
    if not outputLog then return end
    
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
            self:AddCommandOutput(outputLog, "System", "Player " .. args[1] .. " has been kicked")
            -- In a real implementation, this would call server-side admin functions
        end
    elseif command == "ban" then
        if #args < 1 then
            self:AddCommandOutput(outputLog, "Error", "Usage: ban [player]")
        else
            self:AddCommandOutput(outputLog, "System", "Player " .. args[1] .. " has been banned")
            -- In a real implementation, this would call server-side admin functions
        end
    elseif command == "shutdown" then
        -- Add confirmation dialog for shutdown
        DialogFactory.createConfirmationDialog(
            "Confirm Shutdown",
            "Are you sure you want to shut down the server? All players will be disconnected.",
            function()
                self:AddCommandOutput(outputLog, "System", "Server shutdown initiated")
                -- In a real implementation, this would call server-side admin functions
            end,
            function()
                self:AddCommandOutput(outputLog, "System", "Server shutdown cancelled")
            end,
            {
                confirmText = "Shut Down",
                cancelText = "Cancel"
            }
        )
    elseif command == "heal" then
        if #args < 1 then
            self:AddCommandOutput(outputLog, "Error", "Usage: heal [player]")
        else
            self:AddCommandOutput(outputLog, "System", "Healing player: " .. args[1])
            -- In a real implementation, this would call server-side admin functions
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
end

-- Toggle the admin panel visibility
function AdminControlsUI:ToggleAdminPanel()
    local adminPanel = uiState.menuElements.adminPanel
    if not adminPanel then
        warn("Admin panel not initialized")
        return
    end
    
    uiState.adminPanelVisible = not uiState.adminPanelVisible
    
    if uiState.adminPanelVisible then
        -- Show the panel with animation
        adminPanel.Visible = true
        adminPanel.BackgroundTransparency = 1
        adminPanel.Position = UDim2.new(0.5, -300, 0.6, -225)
        
        -- Animate in
        TweenService:Create(
            adminPanel,
            UIStyle.Animations.Standard,
            {
                Position = UDim2.new(0.5, -300, 0.5, -225),
                BackgroundTransparency = 0
            }
        ):Play()
        
        -- Update players list if on players tab
        if uiState.currentTab == "Players" then
            self:UpdatePlayersList()
        elseif uiState.currentTab == "ServerStats" then
            self:UpdateServerStats()
        end
    else
        -- Hide with animation
        TweenService:Create(
            adminPanel,
            UIStyle.Animations.Standard,
            {
                Position = UDim2.new(0.5, -300, 0.6, -225),
                BackgroundTransparency = 1
            }
        ):Play()
        
        -- Hide after animation
        task.delay(UIStyle.Animations.Standard.Time, function()
            adminPanel.Visible = false
        end)
    end
end


return AdminControlsUI