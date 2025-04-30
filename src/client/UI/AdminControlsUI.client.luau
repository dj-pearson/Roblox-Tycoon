--[[
    AdminControlsUI.client.luau
]]

local GameSystem = require(game.ReplicatedStorage.GameSystem)

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Player references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Modules with safe requires and fallbacks
local function safeRequire(path, fallback)
    local success, result = pcall(function() 
        return require(path)
    end)
    
    if success then
        return result
    else
        warn("Failed to require " .. tostring(path) .. ": " .. tostring(result))
        return fallback
    end
end

-- Try to load UI modules from multiple possible locations
local function tryRequireUIModule(moduleName)
    -- Common locations to check for UI modules
    local possiblePaths = {
        game.ReplicatedStorage.shared.UI,
        game.ReplicatedStorage.src.shared.UI,
        game.ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("UI"),
        game.ReplicatedStorage.UI
    }
    
    for _, path in ipairs(possiblePaths) do
        if path and path:FindFirstChild(moduleName) then
            local module = safeRequire(path:FindFirstChild(moduleName))
            if module then
                return module
            end
        end
    end
    
    -- Return fallback if module not found
    warn(moduleName .. " module not found, using fallback")
    
    if moduleName == "UIStyle" then
        return {
            Colors = {
                Background = Color3.fromRGB(50, 50, 50),
                TabActive = Color3.fromRGB(100, 100, 255),
                TabInactive = Color3.fromRGB(70, 70, 70),
                ButtonPrimary = Color3.fromRGB(0, 120, 255),
                ButtonSecondary = Color3.fromRGB(100, 100, 100),
                ButtonWarning = Color3.fromRGB(255, 100, 0),
                ButtonDanger = Color3.fromRGB(255, 0, 0),
                TextPrimary = Color3.fromRGB(255, 255, 255),
                TextSecondary = Color3.fromRGB(200, 200, 200),
                Border = Color3.fromRGB(100, 100, 100)
            },
            Fonts = {
                Header = Enum.Font.GothamBold,
                Regular = Enum.Font.Gotham,
                Button = Enum.Font.GothamMedium
            },
            Animation = {
                Default = Enum.EasingStyle.Quad,
                DefaultTime = 0.3
            }
        }
    elseif moduleName == "ButtonFactory" then
        return {
            createButton = function(config)
                local button = Instance.new("TextButton")
                button.Size = config.size or UDim2.new(0.2, 0, 0.08, 0)
                button.Position = config.position or UDim2.new(0, 0, 0, 0)
                button.BackgroundColor3 = config.color or Color3.fromRGB(0, 120, 255)
                button.Text = config.text or "Button"
                button.Font = config.font or Enum.Font.GothamMedium
                button.TextSize = config.textSize or 16
                button.TextColor3 = config.textColor or Color3.fromRGB(255, 255, 255)
                button.Parent = config.parent
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = button
                
                if config.callback then
                    button.MouseButton1Click:Connect(config.callback)
                end
                
                return button
            end,
            createIconButton = function(config)
                local button = Instance.new("TextButton")
                button.Size = config.size or UDim2.new(0.1, 0, 0.1, 0)
                button.Position = config.position or UDim2.new(0, 0, 0, 0)
                button.BackgroundColor3 = config.color or Color3.fromRGB(0, 120, 255)
                button.Text = ""
                button.Parent = config.parent
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = button
                
                local icon = Instance.new("ImageLabel")
                icon.Size = UDim2.new(0.7, 0, 0.7, 0)
                icon.Position = UDim2.new(0.15, 0, 0.15, 0)
                icon.BackgroundTransparency = 1
                icon.Image = config.icon or ""
                icon.Parent = button
                
                if config.callback then
                    button.MouseButton1Click:Connect(config.callback)
                end
                
                return button
            end
        }
    elseif moduleName == "DialogFactory" then
        return {
            showConfirmDialog = function(config)
                local dialog = Instance.new("Frame")
                dialog.Size = UDim2.new(0.4, 0, 0.3, 0)
                dialog.Position = UDim2.new(0.3, 0, 0.35, 0)
                dialog.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                dialog.BorderSizePixel = 0
                dialog.ZIndex = 20
                dialog.Parent = player.PlayerGui
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = dialog
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0.2, 0)
                title.BackgroundTransparency = 1
                title.Text = config.title or "Confirm"
                title.Font = Enum.Font.GothamBold
                title.TextSize = 20
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.Parent = dialog
                
                local message = Instance.new("TextLabel")
                message.Size = UDim2.new(0.9, 0, 0.4, 0)
                message.Position = UDim2.new(0.05, 0, 0.25, 0)
                message.BackgroundTransparency = 1
                message.Text = config.message or "Are you sure?"
                message.Font = Enum.Font.Gotham
                message.TextSize = 16
                message.TextWrapped = true
                message.TextColor3 = Color3.fromRGB(230, 230, 230)
                message.Parent = dialog
                
                local confirmButton = Instance.new("TextButton")
                confirmButton.Size = UDim2.new(0.4, 0, 0.2, 0)
                confirmButton.Position = UDim2.new(0.1, 0, 0.7, 0)
                confirmButton.BackgroundColor3 = config.confirmColor or Color3.fromRGB(0, 180, 0)
                confirmButton.Text = config.confirmText or "Confirm"
                confirmButton.Font = Enum.Font.GothamMedium
                confirmButton.TextSize = 16
                confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                confirmButton.Parent = dialog
                
                local cancelButton = Instance.new("TextButton")
                cancelButton.Size = UDim2.new(0.4, 0, 0.2, 0)
                cancelButton.Position = UDim2.new(0.5, 0, 0.7, 0)
                cancelButton.BackgroundColor3 = config.cancelColor or Color3.fromRGB(180, 0, 0)
                cancelButton.Text = config.cancelText or "Cancel"
                cancelButton.Font = Enum.Font.GothamMedium
                cancelButton.TextSize = 16
                cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                cancelButton.Parent = dialog
                
                local cornerConfirm = Instance.new("UICorner")
                cornerConfirm.CornerRadius = UDim.new(0, 6)
                cornerConfirm.Parent = confirmButton
                
                local cornerCancel = Instance.new("UICorner")
                cornerCancel.CornerRadius = UDim.new(0, 6)
                cornerCancel.Parent = cancelButton
                
                confirmButton.MouseButton1Click:Connect(function()
                    dialog:Destroy()
                    if config.onConfirm then
                        config.onConfirm()
                    end
                end)
                
                cancelButton.MouseButton1Click:Connect(function()
                    dialog:Destroy()
                    if config.onCancel then
                        config.onCancel()
                    end
                end)
                
                return dialog
            end,
            showInfoDialog = function(config)
                local dialog = Instance.new("Frame")
                dialog.Size = UDim2.new(0.4, 0, 0.3, 0)
                dialog.Position = UDim2.new(0.3, 0, 0.35, 0)
                dialog.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                dialog.BorderSizePixel = 0
                dialog.ZIndex = 20
                dialog.Parent = player.PlayerGui
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = dialog
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0.2, 0)
                title.BackgroundTransparency = 1
                title.Text = config.title or "Information"
                title.Font = Enum.Font.GothamBold
                title.TextSize = 20
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.Parent = dialog
                
                local message = Instance.new("TextLabel")
                message.Size = UDim2.new(0.9, 0, 0.5, 0)
                message.Position = UDim2.new(0.05, 0, 0.25, 0)
                message.BackgroundTransparency = 1
                message.Text = config.message or ""
                message.Font = Enum.Font.Gotham
                message.TextSize = 16
                message.TextWrapped = true
                message.TextColor3 = Color3.fromRGB(230, 230, 230)
                message.Parent = dialog
                
                local okButton = Instance.new("TextButton")
                okButton.Size = UDim2.new(0.4, 0, 0.2, 0)
                okButton.Position = UDim2.new(0.3, 0, 0.75, 0)
                okButton.BackgroundColor3 = config.confirmColor or Color3.fromRGB(0, 120, 255)
                okButton.Text = config.okText or "OK"
                okButton.Font = Enum.Font.GothamMedium
                okButton.TextSize = 16
                okButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                okButton.Parent = dialog
                
                local cornerOk = Instance.new("UICorner")
                cornerOk.CornerRadius = UDim.new(0, 6)
                cornerOk.Parent = okButton
                
                okButton.MouseButton1Click:Connect(function()
                    dialog:Destroy()
                    if config.onOk then
                        config.onOk()
                    end
                end)
                
                return dialog
            end
        }
    elseif moduleName == "IconSet" then
        return {
            Icons = {
                Close = "rbxassetid://6031094678",
                Settings = "rbxassetid://6031280882",
                Player = "rbxassetid://6031302920",
                Warning = "rbxassetid://6031094670",
                Success = "rbxassetid://6031094661",
                Error = "rbxassetid://6031094667",
                Info = "rbxassetid://6026568247"
            }
        }
    end
    
    return {}
end

-- Load UI modules with fallbacks
local UIStyle = tryRequireUIModule("UIStyle")
local ButtonFactory = tryRequireUIModule("ButtonFactory")
local DialogFactory = tryRequireUIModule("DialogFactory")
local IconSet = tryRequireUIModule("IconSet")

-- UI State
local uiState = {
    isOpen = false,
    currentTab = "Players",
    selectedPlayer = nil,
    menuElements = {},
    playerListItems = {}
}

-- Admin Controls UI Module
local AdminControlsUI = {}

-- Check if the current player is an admin
local function isPlayerAdmin()
	-- Check player attributes (most reliable method)
	if player:GetAttribute("IsAdmin") or player:GetAttribute("Admin") or player:GetAttribute("IsDeveloper") then
		return true
	end
	
	-- Check if in Studio (for testing only)
	if game:GetService("RunService"):IsStudio() then
		return true
	end
	
	-- Check for admin in GameSystem
	local success, result = pcall(function()
		if GameSystem and typeof(GameSystem.isPlayerAdmin) == "function" then
			return GameSystem.isPlayerAdmin(player)
		end
		return false
	end)
	
	if success and result then
		return true
	end
	
	-- Check admin users list in ReplicatedStorage
	pcall(function() -- Use pcall directly without assigning to unused variable
		local adminList = game.ReplicatedStorage:FindFirstChild("AdminUsers")
		if adminList and adminList:IsA("ModuleScript") then
			local admins = require(adminList)
			if type(admins) == "table" then
				for _, id in pairs(admins) do
					if id == player.UserId then
						return true
					end
				end
			end
		end
		return false
	end)
	
	-- By default, not an admin
	return false
end

function AdminControlsUI.initialize()
	-- Check if player is an admin before creating UI
	if not isPlayerAdmin() then
		print("[AdminControlsUI] User is not an admin. Admin interface disabled.")
		return false
	end
	
	print("[AdminControlsUI] User is an admin. Initializing admin interface...")
	
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

function AdminControlsUI.SetupAdminDashboard()
    local adminDashboard = AdminControlsUI.AdminDashboard
    if not adminDashboard then
        warn("Admin dashboard not initialized")
        return
    end
    
    -- Create tabs container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.Size = UDim2.new(1, 0, 0.05, 0)
    tabsContainer.Position = UDim2.new(0, 0, 0.1, 0)
    tabsContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabsContainer.BorderSizePixel = 0
    tabsContainer.Parent = adminDashboard
    
    -- Create content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 0.85, 0)
    contentContainer.Position = UDim2.new(0, 0, 0.15, 0)
    contentContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = adminDashboard
    
    -- Create tab buttons and content frames
    local tabs = {"Players", "GameSettings", "ServerStats", "Commands", "AdminTools"}
    local tabWidth = 1 / #tabs
    
    for i, tabName in ipairs(tabs) do
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Text = tabName
        tabButton.Size = UDim2.new(tabWidth, 0, 1, 0)
        tabButton.Position = UDim2.new(tabWidth * (i-1), 0, 0, 0)
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.TextSize = 14
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.BackgroundColor3 = (i == 1) and UIStyle.Colors.TabActive or UIStyle.Colors.TabInactive
        tabButton.BorderSizePixel = 0
        tabButton.ZIndex = 16
        tabButton.Parent = tabsContainer
        
        -- Add corner radius
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = tabButton
        
        -- Create content frame
        local contentFrame = Instance.new("Frame")
        contentFrame.Name = tabName .. "Content"
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Visible = (i == 1) -- First tab visible by default
        contentFrame.Parent = contentContainer
        
        -- Store references
        uiState.menuElements[tabName .. "Tab"] = tabButton
        uiState.menuElements[tabName .. "Content"] = contentFrame
        
        -- Connect tab button
        tabButton.MouseButton1Click:Connect(function()
            AdminControlsUI:SwitchTab(tabName)
        end)
    end
    
    -- Create content for each tab
    AdminControlsUI:CreatePlayersTab(uiState.menuElements.PlayersContent)
    AdminControlsUI:CreateGameSettingsTab(uiState.menuElements.GameSettingsContent)
    AdminControlsUI:CreateServerStatsTab(uiState.menuElements.ServerStatsContent)
    AdminControlsUI:CreateCommandsTab(uiState.menuElements.CommandsContent)
    AdminControlsUI:CreateAdminToolsTab(uiState.menuElements.AdminToolsContent)
    
    -- Select the first tab by default
    AdminControlsUI:SwitchTab("Players")
    
    -- Store the main panels
    uiState.menuElements.adminPanel = adminDashboard
    uiState.menuElements.tabsContainer = tabsContainer
    uiState.menuElements.contentContainer = contentContainer
end

function AdminControlsUI.showAdminDashboard()
	AdminControlsUI.AdminDashboard.Visible = true
    
    -- Setup tab system if not already set up
    if not uiState.menuElements.adminPanel then
        AdminControlsUI.SetupAdminDashboard()
    end
end


-- Switch between tabs
function AdminControlsUI:SwitchTab(tabId)
    -- Update current tab
    uiState.currentTab = tabId
    
    -- Update tab button appearances
    local tabs = {"Players", "GameSettings", "ServerStats", "Commands", "AdminTools"}
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
    for _, plr in ipairs(playersList) do
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
    for _, setting in ipairs(settings) do
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
    
    -- Add BuyTile setup button below save button
    yOffset = yOffset + 60
    local setupBuyTileButton = ButtonFactory.createIconButton("Refresh", "Setup BuyTile System", UDim2.new(0.6, 0, 0, 40), UDim2.new(0.2, 0, 0, yOffset), function()
        -- Show confirmation before setting up BuyTile System
        DialogFactory.createConfirmationDialog(
            "Setup BuyTile System",
            "Are you sure you want to run the BuyTile System setup? This will scan the GymParts folder and regenerate all tile data.",
            function()
                -- Execute the SetupBuyTileSystem function - use proper module reference instead of _G
                local success, result = pcall(function()
                    -- Try to find the BuyTileSystemIntegration module
                    local CoreRegistry = game:GetService("ServerScriptService"):FindFirstChild("Core"):FindFirstChild("CoreRegistry")
                    local BuyTileSystemIntegration
                    
                    if CoreRegistry then
                        BuyTileSystemIntegration = require(CoreRegistry):GetSystem("BuyTileSystemIntegration")
                    end
                    
                    if BuyTileSystemIntegration and typeof(BuyTileSystemIntegration.generateTileData) == "function" then
                        return BuyTileSystemIntegration.generateTileData("auto")
                    elseif game:GetService("ServerScriptService"):FindFirstChild("Core"):FindFirstChild("TileDataInitializer") then
                        return require(game:GetService("ServerScriptService").Core.TileDataInitializer).initializeTileData()
                    else
                        error("SetupBuyTileSystem function not found")
                    end
                end)
                
                if success and result then
                    DialogFactory.createNotification("BuyTile System setup completed successfully!", 3, "success")
                else
                    DialogFactory.createNotification("BuyTile System setup failed: " .. tostring(result), 5, "error")
                end
            end,
            nil,
            { confirmText = "Setup" }
        )
    end, "primary")
    setupBuyTileButton.Parent = settingsContainer
    
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
    padding.PaddingRight = UDim2.new(0, 10)
    padding.PaddingTop = UDim2.new(0, 10)
    padding.PaddingBottom = UDim2.new(0, 10)
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
function AdminControlsUI:AddCommandOutput(outputLog, type, message)
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
    logEntry.Text = "[" .. type .. "] " .. message
    logEntry.TextColor3 = type == "Error" and UIStyle.Colors.Danger or UIStyle.Colors.Text
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

-- Execute command
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

-- Create the AdminTools tab with commonly used admin commands
function AdminControlsUI:CreateAdminToolsTab(parent)
    -- Create a scrolling container for all the tools
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "AdminToolsScrollFrame"
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 700) -- Will be adjusted based on content
    scrollFrame.Parent = parent

    -- Store the output log for commands to use
    local outputLog = uiState.menuElements.outputLog
    
    -- Add category title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = UIStyle.Fonts.Bold
    titleLabel.Text = "Admin Tools"
    titleLabel.TextColor3 = UIStyle.Colors.Text
    titleLabel.TextSize = UIStyle.TextSizes.Large
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = scrollFrame
    
    -- Create UI layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 15)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim2.new(0, 10)
    padding.PaddingTop = UDim2.new(0, 10)
    padding.PaddingBottom = UDim2.new(0, 10)
    padding.Parent = scrollFrame

    -- Function to create a command category
    local function createCategory(name, description, layoutOrder)
        local categoryFrame = Instance.new("Frame")
        categoryFrame.Name = name .. "Category"
        categoryFrame.Size = UDim2.new(1, 0, 0, 40)
        categoryFrame.BackgroundColor3 = UIStyle.Colors.BackgroundLight
        categoryFrame.BorderSizePixel = 0
        categoryFrame.LayoutOrder = layoutOrder
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = categoryFrame
        
        -- Add category name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -20, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = UIStyle.Fonts.Bold
        nameLabel.Text = name
        nameLabel.TextColor3 = UIStyle.Colors.Text
        nameLabel.TextSize = UIStyle.TextSizes.Medium
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = categoryFrame
        
        -- Add description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -20, 0, 30)
        descLabel.Position = UDim2.new(0, 10, 1, 5)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = UIStyle.Fonts.Italic
        descLabel.Text = description
        descLabel.TextColor3 = UIStyle.Colors.TextSecondary
        descLabel.TextSize = UIStyle.TextSizes.Small
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = categoryFrame
        
        -- Create container for buttons
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Name = "ButtonContainer"
        buttonContainer.Size = UDim2.new(1, 0, 0, 0) -- Height will be adjusted based on content
        buttonContainer.Position = UDim2.new(0, 0, 0, 80)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.AutomaticSize = Enum.AutomaticSize.Y
        buttonContainer.Parent = categoryFrame
        
        -- Create grid layout for buttons
        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.new(0.48, 0, 0, 45)
        gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = buttonContainer
        
        -- Adjust category frame size based on content
        categoryFrame.Size = UDim2.new(1, 0, 0, 85) -- Base size plus padding
        
        return categoryFrame, buttonContainer
    end

    -- Function to create a command button in a category
    local function createCommandButton(container, name, description, commandFunc, layoutOrder, buttonType)
        buttonType = buttonType or "primary"
        
        local button = ButtonFactory.createButton(
            name,
            UDim2.new(1, 0, 0, 45),
            UDim2.new(0, 0, 0, 0),
            function()
                -- Show confirmation dialog
                DialogFactory.createConfirmationDialog(
                    "Run Command: " .. name,
                    description .. "\n\nAre you sure you want to execute this command?",
                    function()
                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local remotes = ReplicatedStorage:FindFirstChild("AdminRemotes")
                        
                        if remotes then
                            local executeCommand = remotes:FindFirstChild("ExecuteAdminCommand")
                            if executeCommand then
                                -- Log the command execution in the output
                                if outputLog then
                                    self:AddCommandOutput(outputLog, "System", "Running command: " .. name)
                                end
                                
                                -- Show processing notification
                                DialogFactory.createNotification("Executing command: " .. name, 2, "info")
                                
                                -- Execute the command
                                local success, result = pcall(function()
                                    return executeCommand:InvokeServer({
                                        type = commandFunc,
                                        params = {}
                                    })
                                end)
                                
                                -- Handle response
                                if success and result then
                                    if result.success then
                                        DialogFactory.createNotification("Command executed successfully: " .. (result.message or ""), 3, "success")
                                        
                                        -- Add to output log
                                        if outputLog then
                                            self:AddCommandOutput(outputLog, "Success", "Command executed: " .. name .. "\n" .. (result.message or ""))
                                        end
                                    else
                                        DialogFactory.createNotification("Command failed: " .. (result.message or "Unknown error"), 3, "error")
                                        
                                        -- Add to output log
                                        if outputLog then
                                            self:AddCommandOutput(outputLog, "Error", "Command failed: " .. name .. "\n" .. (result.message or ""))
                                        end
                                    end
                                else
                                    DialogFactory.createNotification("Failed to execute command. Check server logs.", 3, "error")
                                    
                                    -- Add to output log
                                    if outputLog then
                                        self:AddCommandOutput(outputLog, "Error", "Failed to execute command: " .. name)
                                    end
                                end
                            end
                        end
                    end,
                    nil,
                    { confirmText = "Execute" }
                )
            end
        )
        button.LayoutOrder = layoutOrder
        button.Parent = container
        
        -- Apply style based on button type
        if buttonType == "danger" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonDanger
        elseif buttonType == "warning" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonWarning
        elseif buttonType == "success" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonSuccess
        else
            button.BackgroundColor3 = UIStyle.Colors.ButtonPrimary
        end
        
        return button
    end

    -- Create categories and add buttons
    
    -- Tycoon Information Category
    local infoCategory, infoButtons = createCategory("Tycoon Information", "View and analyze gym structure information", 100)
    infoCategory.Parent = scrollFrame
    
    createCommandButton(infoButtons, "Show Tycoon Info", "Display detailed information about tycoon structure", "showTycoonInfo", 10)
    createCommandButton(infoButtons, "Analyze Gym Structure", "Analyze gym structure without making changes", "analyzeGymStructure", 20)
    createCommandButton(infoButtons, "Generate Model Report", "Create detailed validation report for models", "generateModelReport", 30)
    createCommandButton(infoButtons, "Show Hitboxes", "Make hitboxes visible in the workspace", "showHitboxes", 40, "warning")
    createCommandButton(infoButtons, "Hide Hitboxes", "Hide hitboxes in the workspace", "hideHitboxes", 50)
    
    -- Adjust the category size based on content
    infoCategory.Size = UDim2.new(1, 0, 0, infoButtons.Position.Y.Offset + infoButtons.AbsoluteSize.Y + 20)
    
    -- Tycoon Automation Category
    local autoCategory, autoButtons = createCategory("Tycoon Automation", "Automate tycoon setup and configuration", 200)
    autoCategory.Parent = scrollFrame
    autoCategory.Position = UDim2.new(0, 0, 0, infoCategory.AbsoluteSize.Y + infoCategory.AbsolutePosition.Y + 20)
    
    createCommandButton(autoButtons, "Automate Gym", "Fully automate gym setup and configuration", "automateGym", 10, "success")
    createCommandButton(autoButtons, "Auto-Setup Buy Tiles", "Automatically set up all buy tiles", "autoSetupBuyTiles", 20, "success")
    createCommandButton(autoButtons, "Generate Build Order", "Create logical build order for tiles", "generateBuildOrder", 30)
    createCommandButton(autoButtons, "Process Equipment", "Process all equipment and set up attributes", "processEquipment", 40)
    createCommandButton(autoButtons, "Generate Hitboxes", "Create hitboxes for BuyTile interaction", "generateHitboxes", 50)
    
    -- Adjust the category size based on content
    autoCategory.Size = UDim2.new(1, 0, 0, autoButtons.Position.Y.Offset + autoButtons.AbsoluteSize.Y + 20)
    
    -- Model Validation Category
    local validationCategory, validationButtons = createCategory("Model Validation", "Validate and fix model issues", 300)
    validationCategory.Parent = scrollFrame
    validationCategory.Position = UDim2.new(0, 0, 0, autoCategory.AbsoluteSize.Y + autoCategory.AbsolutePosition.Y + 20)
    
    createCommandButton(validationButtons, "Validate Gym Models", "Check all models for common issues", "validateGymModels", 10)
    createCommandButton(validationButtons, "Fix Model Issues", "Attempt to fix common model issues", "fixModelIssues", 20, "warning")
    createCommandButton(validationButtons, "Apply Collection Tags", "Apply tags to models based on attributes", "applyCollectionTags", 30)
    createCommandButton(validationButtons, "Generate Equipment Config", "Create equipment configuration from models", "generateEquipmentConfig", 40)
    createCommandButton(validationButtons, "Generate UI Config", "Create UI configuration from UI elements", "generateUIConfig", 50)
    
    -- Adjust the category size based on content
    validationCategory.Size = UDim2.new(1, 0, 0, validationButtons.Position.Y.Offset + validationButtons.AbsoluteSize.Y + 20)
    
    -- Set final canvas size based on all content
    local totalHeight = validationCategory.AbsoluteSize.Y + validationCategory.AbsolutePosition.Y - scrollFrame.AbsolutePosition.Y + 30
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    return parent
end

-- Execute command
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

-- Create the AdminTools tab with commonly used admin commands
function AdminControlsUI:CreateAdminToolsTab(parent)
    -- Create a scrolling container for all the tools
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "AdminToolsScrollFrame"
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 700) -- Will be adjusted based on content
    scrollFrame.Parent = parent

    -- Store the output log for commands to use
    local outputLog = uiState.menuElements.outputLog
    
    -- Add category title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = UIStyle.Fonts.Bold
    titleLabel.Text = "Admin Tools"
    titleLabel.TextColor3 = UIStyle.Colors.Text
    titleLabel.TextSize = UIStyle.TextSizes.Large
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = scrollFrame
    
    -- Create UI layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 15)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim2.new(0, 10)
    padding.PaddingTop = UDim2.new(0, 10)
    padding.PaddingBottom = UDim2.new(0, 10)
    padding.Parent = scrollFrame

    -- Function to create a command category
    local function createCategory(name, description, layoutOrder)
        local categoryFrame = Instance.new("Frame")
        categoryFrame.Name = name .. "Category"
        categoryFrame.Size = UDim2.new(1, 0, 0, 40)
        categoryFrame.BackgroundColor3 = UIStyle.Colors.BackgroundLight
        categoryFrame.BorderSizePixel = 0
        categoryFrame.LayoutOrder = layoutOrder
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = categoryFrame
        
        -- Add category name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -20, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = UIStyle.Fonts.Bold
        nameLabel.Text = name
        nameLabel.TextColor3 = UIStyle.Colors.Text
        nameLabel.TextSize = UIStyle.TextSizes.Medium
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = categoryFrame
        
        -- Add description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -20, 0, 30)
        descLabel.Position = UDim2.new(0, 10, 1, 5)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = UIStyle.Fonts.Italic
        descLabel.Text = description
        descLabel.TextColor3 = UIStyle.Colors.TextSecondary
        descLabel.TextSize = UIStyle.TextSizes.Small
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = categoryFrame
        
        -- Create container for buttons
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Name = "ButtonContainer"
        buttonContainer.Size = UDim2.new(1, 0, 0, 0) -- Height will be adjusted based on content
        buttonContainer.Position = UDim2.new(0, 0, 0, 80)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.AutomaticSize = Enum.AutomaticSize.Y
        buttonContainer.Parent = categoryFrame
        
        -- Create grid layout for buttons
        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.new(0.48, 0, 0, 45)
        gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = buttonContainer
        
        -- Adjust category frame size based on content
        categoryFrame.Size = UDim2.new(1, 0, 0, 85) -- Base size plus padding
        
        return categoryFrame, buttonContainer
    end

    -- Function to create a command button in a category
    local function createCommandButton(container, name, description, commandFunc, layoutOrder, buttonType)
        buttonType = buttonType or "primary"
        
        local button = ButtonFactory.createButton(
            name,
            UDim2.new(1, 0, 0, 45),
            UDim2.new(0, 0, 0, 0),
            function()
                -- Show confirmation dialog
                DialogFactory.createConfirmationDialog(
                    "Run Command: " .. name,
                    description .. "\n\nAre you sure you want to execute this command?",
                    function()
                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local remotes = ReplicatedStorage:FindFirstChild("AdminRemotes")
                        
                        if remotes then
                            local executeCommand = remotes:FindFirstChild("ExecuteAdminCommand")
                            if executeCommand then
                                -- Log the command execution in the output
                                if outputLog then
                                    self:AddCommandOutput(outputLog, "System", "Running command: " .. name)
                                end
                                
                                -- Show processing notification
                                DialogFactory.createNotification("Executing command: " .. name, 2, "info")
                                
                                -- Execute the command
                                local success, result = pcall(function()
                                    return executeCommand:InvokeServer({
                                        type = commandFunc,
                                        params = {}
                                    })
                                end)
                                
                                -- Handle response
                                if success and result then
                                    if result.success then
                                        DialogFactory.createNotification("Command executed successfully: " .. (result.message or ""), 3, "success")
                                        
                                        -- Add to output log
                                        if outputLog then
                                            self:AddCommandOutput(outputLog, "Success", "Command executed: " .. name .. "\n" .. (result.message or ""))
                                        end
                                    else
                                        DialogFactory.createNotification("Command failed: " .. (result.message or "Unknown error"), 3, "error")
                                        
                                        -- Add to output log
                                        if outputLog then
                                            self:AddCommandOutput(outputLog, "Error", "Command failed: " .. name .. "\n" .. (result.message or ""))
                                        end
                                    end
                                else
                                    DialogFactory.createNotification("Failed to execute command. Check server logs.", 3, "error")
                                    
                                    -- Add to output log
                                    if outputLog then
                                        self:AddCommandOutput(outputLog, "Error", "Failed to execute command: " .. name)
                                    end
                                end
                            end
                        end
                    end,
                    nil,
                    { confirmText = "Execute" }
                )
            end
        )
        button.LayoutOrder = layoutOrder
        button.Parent = container
        
        -- Apply style based on button type
        if buttonType == "danger" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonDanger
        elseif buttonType == "warning" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonWarning
        elseif buttonType == "success" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonSuccess
        else
            button.BackgroundColor3 = UIStyle.Colors.ButtonPrimary
        end
        
        return button
    end

    -- Create categories and add buttons
    
    -- Tycoon Information Category
    local infoCategory, infoButtons = createCategory("Tycoon Information", "View and analyze gym structure information", 100)
    infoCategory.Parent = scrollFrame
    
    createCommandButton(infoButtons, "Show Tycoon Info", "Display detailed information about tycoon structure", "showTycoonInfo", 10)
    createCommandButton(infoButtons, "Analyze Gym Structure", "Analyze gym structure without making changes", "analyzeGymStructure", 20)
    createCommandButton(infoButtons, "Generate Model Report", "Create detailed validation report for models", "generateModelReport", 30)
    createCommandButton(infoButtons, "Show Hitboxes", "Make hitboxes visible in the workspace", "showHitboxes", 40, "warning")
    createCommandButton(infoButtons, "Hide Hitboxes", "Hide hitboxes in the workspace", "hideHitboxes", 50)
    
    -- Adjust the category size based on content
    infoCategory.Size = UDim2.new(1, 0, 0, infoButtons.Position.Y.Offset + infoButtons.AbsoluteSize.Y + 20)
    
    -- Tycoon Automation Category
    local autoCategory, autoButtons = createCategory("Tycoon Automation", "Automate tycoon setup and configuration", 200)
    autoCategory.Parent = scrollFrame
    autoCategory.Position = UDim2.new(0, 0, 0, infoCategory.AbsoluteSize.Y + infoCategory.AbsolutePosition.Y + 20)
    
    createCommandButton(autoButtons, "Automate Gym", "Fully automate gym setup and configuration", "automateGym", 10, "success")
    createCommandButton(autoButtons, "Auto-Setup Buy Tiles", "Automatically set up all buy tiles", "autoSetupBuyTiles", 20, "success")
    createCommandButton(autoButtons, "Generate Build Order", "Create logical build order for tiles", "generateBuildOrder", 30)
    createCommandButton(autoButtons, "Process Equipment", "Process all equipment and set up attributes", "processEquipment", 40)
    createCommandButton(autoButtons, "Generate Hitboxes", "Create hitboxes for BuyTile interaction", "generateHitboxes", 50)
    
    -- Adjust the category size based on content
    autoCategory.Size = UDim2.new(1, 0, 0, autoButtons.Position.Y.Offset + autoButtons.AbsoluteSize.Y + 20)
    
    -- Model Validation Category
    local validationCategory, validationButtons = createCategory("Model Validation", "Validate and fix model issues", 300)
    validationCategory.Parent = scrollFrame
    validationCategory.Position = UDim2.new(0, 0, 0, autoCategory.AbsoluteSize.Y + autoCategory.AbsolutePosition.Y + 20)
    
    createCommandButton(validationButtons, "Validate Gym Models", "Check all models for common issues", "validateGymModels", 10)
    createCommandButton(validationButtons, "Fix Model Issues", "Attempt to fix common model issues", "fixModelIssues", 20, "warning")
    createCommandButton(validationButtons, "Apply Collection Tags", "Apply tags to models based on attributes", "applyCollectionTags", 30)
    createCommandButton(validationButtons, "Generate Equipment Config", "Create equipment configuration from models", "generateEquipmentConfig", 40)
    createCommandButton(validationButtons, "Generate UI Config", "Create UI configuration from UI elements", "generateUIConfig", 50)
    
    -- Adjust the category size based on content
    validationCategory.Size = UDim2.new(1, 0, 0, validationButtons.Position.Y.Offset + validationButtons.AbsoluteSize.Y + 20)
    
    -- Set final canvas size based on all content
    local totalHeight = validationCategory.AbsoluteSize.Y + validationCategory.AbsolutePosition.Y - scrollFrame.AbsolutePosition.Y + 30
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    return parent
end

-- Execute command
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
-- Primary implementation of ToggleAdminPanel
-- Primary implementation of the ToggleAdminPanel function
function AdminControlsUI:ToggleAdminPanel()
    local adminPanel = uiState.menuElements.adminPanel
    if not adminPanel then
        warn("Admin panel not initialized")
        return
    end
    
    uiState.adminPanelVisible = not uiState.adminPanelVisible
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = scrollFrame

    -- Function to create a command category
    local function createCategory(name, description, layoutOrder)
        local categoryFrame = Instance.new("Frame")
        categoryFrame.Name = name .. "Category"
        categoryFrame.Size = UDim2.new(1, 0, 0, 40)
        categoryFrame.BackgroundColor3 = UIStyle.Colors.BackgroundLight
        categoryFrame.BorderSizePixel = 0
        categoryFrame.LayoutOrder = layoutOrder
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = categoryFrame
        
        -- Add category name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -20, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = UIStyle.Fonts.Bold
        nameLabel.Text = name
        nameLabel.TextColor3 = UIStyle.Colors.Text
        nameLabel.TextSize = UIStyle.TextSizes.Medium
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = categoryFrame
        
        -- Add description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -20, 0, 30)
        descLabel.Position = UDim2.new(0, 10, 1, 5)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = UIStyle.Fonts.Italic
        descLabel.Text = description
        descLabel.TextColor3 = UIStyle.Colors.TextSecondary
        descLabel.TextSize = UIStyle.TextSizes.Small
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = categoryFrame
        
        -- Create container for buttons
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Name = "ButtonContainer"
        buttonContainer.Size = UDim2.new(1, 0, 0, 0) -- Height will be adjusted based on content
        buttonContainer.Position = UDim2.new(0, 0, 0, 80)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.AutomaticSize = Enum.AutomaticSize.Y
        buttonContainer.Parent = categoryFrame
        
        -- Create grid layout for buttons
        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.new(0.48, 0, 0, 45)
        gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = buttonContainer
        
        -- Adjust category frame size based on content
        categoryFrame.Size = UDim2.new(1, 0, 0, 85) -- Base size plus padding
        
        return categoryFrame, buttonContainer
    end

    -- Function to create a command button in a category
    local function createCommandButton(container, name, description, commandFunc, layoutOrder, buttonType)
        buttonType = buttonType or "primary"
        
        local button = ButtonFactory.createButton(
            name,
            UDim2.new(1, 0, 0, 45),
            UDim2.new(0, 0, 0, 0),
            function()
                -- Show confirmation dialog
                DialogFactory.createConfirmationDialog(
                    "Run Command: " .. name,
                    description .. "\n\nAre you sure you want to execute this command?",
                    function()
                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local remotes = ReplicatedStorage:FindFirstChild("AdminRemotes")
                        
                        if remotes then
                            local executeCommand = remotes:FindFirstChild("ExecuteAdminCommand")
                            if executeCommand then
                                -- Log the command execution in the output
                                if outputLog then
                                    self:AddCommandOutput(outputLog, "System", "Running command: " .. name)
                                end
                                
                                -- Show processing notification
                                DialogFactory.createNotification("Executing command: " .. name, 2, "info")
                                
                                -- Execute the command
                                local success, result = pcall(function()
                                    return executeCommand:InvokeServer({
                                        type = commandFunc,
                                        params = {}
                                    })
                                end)
                                
                                -- Handle response
                                if success and result then
                                    if result.success then
                                        DialogFactory.createNotification("Command executed successfully: " .. (result.message or ""), 3, "success")
                                        
                                        -- Add to output log
                                        if outputLog then
                                            self:AddCommandOutput(outputLog, "Success", "Command executed: " .. name .. "\n" .. (result.message or ""))
                                        end
                                    else
                                        DialogFactory.createNotification("Command failed: " .. (result.message or "Unknown error"), 3, "error")
                                        
                                        -- Add to output log
                                        if outputLog then
                                            self:AddCommandOutput(outputLog, "Error", "Command failed: " .. name .. "\n" .. (result.message or ""))
                                        end
                                    end
                                else
                                    DialogFactory.createNotification("Failed to execute command. Check server logs.", 3, "error")
                                    
                                    -- Add to output log
                                    if outputLog then
                                        self:AddCommandOutput(outputLog, "Error", "Failed to execute command: " .. name)
                                    end
                                end
                            end
                        end
                    end,
                    nil,
                    { confirmText = "Execute" }
                )
            end
        )
        button.LayoutOrder = layoutOrder
        button.Parent = container
        
        -- Apply style based on button type
        if buttonType == "danger" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonDanger
        elseif buttonType == "warning" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonWarning
        elseif buttonType == "success" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonSuccess
        else
            button.BackgroundColor3 = UIStyle.Colors.ButtonPrimary
        end
        
        return button
    end

    -- Create categories and add buttons
    
    -- Tycoon Information Category
    local infoCategory, infoButtons = createCategory("Tycoon Information", "View and analyze gym structure information", 100)
    infoCategory.Parent = scrollFrame
    
    createCommandButton(infoButtons, "Show Tycoon Info", "Display detailed information about tycoon structure", "showTycoonInfo", 10)
    createCommandButton(infoButtons, "Analyze Gym Structure", "Analyze gym structure without making changes", "analyzeGymStructure", 20)
    createCommandButton(infoButtons, "Generate Model Report", "Create detailed validation report for models", "generateModelReport", 30)
    createCommandButton(infoButtons, "Show Hitboxes", "Make hitboxes visible in the workspace", "showHitboxes", 40, "warning")
    createCommandButton(infoButtons, "Hide Hitboxes", "Hide hitboxes in the workspace", "hideHitboxes", 50)
    
    -- Adjust the category size based on content
    infoCategory.Size = UDim2.new(1, 0, 0, infoButtons.Position.Y.Offset + infoButtons.AbsoluteSize.Y + 20)
    
    -- Tycoon Automation Category
    local autoCategory, autoButtons = createCategory("Tycoon Automation", "Automate tycoon setup and configuration", 200)
    autoCategory.Parent = scrollFrame
    autoCategory.Position = UDim2.new(0, 0, 0, infoCategory.AbsoluteSize.Y + infoCategory.AbsolutePosition.Y + 20)
    
    createCommandButton(autoButtons, "Automate Gym", "Fully automate gym setup and configuration", "automateGym", 10, "success")
    createCommandButton(autoButtons, "Auto-Setup Buy Tiles", "Automatically set up all buy tiles", "autoSetupBuyTiles", 20, "success")
    createCommandButton(autoButtons, "Generate Build Order", "Create logical build order for tiles", "generateBuildOrder", 30)
    createCommandButton(autoButtons, "Process Equipment", "Process all equipment and set up attributes", "processEquipment", 40)
    createCommandButton(autoButtons, "Generate Hitboxes", "Create hitboxes for BuyTile interaction", "generateHitboxes", 50)
    
    -- Adjust the category size based on content
    autoCategory.Size = UDim2.new(1, 0, 0, autoButtons.Position.Y.Offset + autoButtons.AbsoluteSize.Y + 20)
    
    -- Model Validation Category
    local validationCategory, validationButtons = createCategory("Model Validation", "Validate and fix model issues", 300)
    validationCategory.Parent = scrollFrame
    validationCategory.Position = UDim2.new(0, 0, 0, autoCategory.AbsoluteSize.Y + autoCategory.AbsolutePosition.Y + 20)
    
    createCommandButton(validationButtons, "Validate Gym Models", "Check all models for common issues", "validateGymModels", 10)
    createCommandButton(validationButtons, "Fix Model Issues", "Attempt to fix common model issues", "fixModelIssues", 20, "warning")
    createCommandButton(validationButtons, "Apply Collection Tags", "Apply tags to models based on attributes", "applyCollectionTags", 30)
    createCommandButton(validationButtons, "Generate Equipment Config", "Create equipment configuration from models", "generateEquipmentConfig", 40)
    createCommandButton(validationButtons, "Generate UI Config", "Create UI configuration from UI elements", "generateUIConfig", 50)
    
    -- Adjust the category size based on content
    validationCategory.Size = UDim2.new(1, 0, 0, validationButtons.Position.Y.Offset + validationButtons.AbsoluteSize.Y + 20)
    
    -- Set final canvas size based on all content
    local totalHeight = validationCategory.AbsoluteSize.Y + validationCategory.AbsolutePosition.Y - scrollFrame.AbsolutePosition.Y + 30
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    return parent
end

-- Execute command
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

-- Create the AdminTools tab with commonly used admin commands
function AdminControlsUI:CreateAdminToolsTab(parent)
    -- Create a scrolling container for all the tools
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "AdminToolsScrollFrame"
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 700) -- Will be adjusted based on content
    scrollFrame.Parent = parent

    -- Store the output log for commands to use
    local outputLog = uiState.menuElements.outputLog
    
    -- Add category title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = UIStyle.Fonts.Bold
    titleLabel.Text = "Admin Tools"
    titleLabel.TextColor3 = UIStyle.Colors.Text
    titleLabel.TextSize = UIStyle.TextSizes.Large
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = scrollFrame
    
    -- Create UI layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 15)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim2.new(0, 10)
    padding.PaddingTop = UDim2.new(0, 10)
    padding.PaddingBottom = UDim2.new(0, 10)
    padding.Parent = scrollFrame

    -- Function to create a command category
    local function createCategory(name, description, layoutOrder)
        local categoryFrame = Instance.new("Frame")
        categoryFrame.Name = name .. "Category"
        categoryFrame.Size = UDim2.new(1, 0, 0, 40)
        categoryFrame.BackgroundColor3 = UIStyle.Colors.BackgroundLight
        categoryFrame.BorderSizePixel = 0
        categoryFrame.LayoutOrder = layoutOrder
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = categoryFrame
        
        -- Add category name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -20, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = UIStyle.Fonts.Bold
        nameLabel.Text = name
        nameLabel.TextColor3 = UIStyle.Colors.Text
        nameLabel.TextSize = UIStyle.TextSizes.Medium
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = categoryFrame
        
        -- Add description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -20, 0, 30)
        descLabel.Position = UDim2.new(0, 10, 1, 5)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = UIStyle.Fonts.Italic
        descLabel.Text = description
        descLabel.TextColor3 = UIStyle.Colors.TextSecondary
        descLabel.TextSize = UIStyle.TextSizes.Small
        descLabel.TextWrapped = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = categoryFrame
        
        -- Create container for buttons
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Name = "ButtonContainer"
        buttonContainer.Size = UDim2.new(1, 0, 0, 0) -- Height will be adjusted based on content
        buttonContainer.Position = UDim2.new(0, 0, 0, 80)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.AutomaticSize = Enum.AutomaticSize.Y
        buttonContainer.Parent = categoryFrame
        
        -- Create grid layout for buttons
        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.new(0.48, 0, 0, 45)
        gridLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = buttonContainer
        
        -- Adjust category frame size based on content
        categoryFrame.Size = UDim2.new(1, 0, 0, 85) -- Base size plus padding
        
        return categoryFrame, buttonContainer
    end

    -- Function to create a command button in a category
    local function createCommandButton(container, name, description, commandFunc, layoutOrder, buttonType)
        buttonType = buttonType or "primary"
        
        local button = ButtonFactory.createButton(
            name,
            UDim2.new(1, 0, 0, 45),
            UDim2.new(0, 0, 0, 0),
            function()
                -- Show confirmation dialog
                DialogFactory.createConfirmationDialog(
                    "Run Command: " .. name,
                    description .. "\n\nAre you sure you want to execute this command?",
                    function()
                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local remotes = ReplicatedStorage:FindFirstChild("AdminRemotes")
                        
                        if remotes then
                            local executeCommand = remotes:FindFirstChild("ExecuteAdminCommand")
                            if executeCommand then
                                -- Log the command execution in the output
                                if outputLog then
                                    self:AddCommandOutput(outputLog, "System", "Running command: " .. name)
                                end
                                
                                -- Show processing notification
                                DialogFactory.createNotification("Executing command: " .. name, 2, "info")
                                
                                -- Execute the command
                                local success, result = pcall(function()
                                    return executeCommand:InvokeServer({
                                        type = commandFunc,
                                        params = {}
                                    })
                                end)
                                
                                -- Handle response
                                if success and result then
                                    if result.success then
                                        DialogFactory.createNotification("Command executed successfully: " .. (result.message or ""), 3, "success")
                                        
                                        -- Add to output log
                                        if outputLog then
                                            self:AddCommandOutput(outputLog, "Success", "Command executed: " .. name .. "\n" .. (result.message or ""))
                                        end
                                    else
                                        DialogFactory.createNotification("Command failed: " .. (result.message or "Unknown error"), 3, "error")
                                        
                                        -- Add to output log
                                        if outputLog then
                                            self:AddCommandOutput(outputLog, "Error", "Command failed: " .. name .. "\n" .. (result.message or ""))
                                        end
                                    end
                                else
                                    DialogFactory.createNotification("Failed to execute command. Check server logs.", 3, "error")
                                    
                                    -- Add to output log
                                    if outputLog then
                                        self:AddCommandOutput(outputLog, "Error", "Failed to execute command: " .. name)
                                    end
                                end
                            end
                        end
                    end,
                    nil,
                    { confirmText = "Execute" }
                )
            end
        )
        button.LayoutOrder = layoutOrder
        button.Parent = container
        
        -- Apply style based on button type
        if buttonType == "danger" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonDanger
        elseif buttonType == "warning" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonWarning
        elseif buttonType == "success" then
            button.BackgroundColor3 = UIStyle.Colors.ButtonSuccess
        else
            button.BackgroundColor3 = UIStyle.Colors.ButtonPrimary
        end
        
        return button
    end

    -- Create categories and add buttons
    
    -- Tycoon Information Category
    local infoCategory, infoButtons = createCategory("Tycoon Information", "View and analyze gym structure information", 100)
    infoCategory.Parent = scrollFrame
    
    createCommandButton(infoButtons, "Show Tycoon Info", "Display detailed information about tycoon structure", "showTycoonInfo", 10)
    createCommandButton(infoButtons, "Analyze Gym Structure", "Analyze gym structure without making changes", "analyzeGymStructure", 20)
    createCommandButton(infoButtons, "Generate Model Report", "Create detailed validation report for models", "generateModelReport", 30)
    createCommandButton(infoButtons, "Show Hitboxes", "Make hitboxes visible in the workspace", "showHitboxes", 40, "warning")
    createCommandButton(infoButtons, "Hide Hitboxes", "Hide hitboxes in the workspace", "hideHitboxes", 50)
    
    -- Adjust the category size based on content
    infoCategory.Size = UDim2.new(1, 0, 0, infoButtons.Position.Y.Offset + infoButtons.AbsoluteSize.Y + 20)
    
    -- Tycoon Automation Category
    local autoCategory, autoButtons = createCategory("Tycoon Automation", "Automate tycoon setup and configuration", 200)
    autoCategory.Parent = scrollFrame
    autoCategory.Position = UDim2.new(0, 0, 0, infoCategory.AbsoluteSize.Y + infoCategory.AbsolutePosition.Y + 20)
    
    createCommandButton(autoButtons, "Automate Gym", "Fully automate gym setup and configuration", "automateGym", 10, "success")
    createCommandButton(autoButtons, "Auto-Setup Buy Tiles", "Automatically set up all buy tiles", "autoSetupBuyTiles", 20, "success")
    createCommandButton(autoButtons, "Generate Build Order", "Create logical build order for tiles", "generateBuildOrder", 30)
    createCommandButton(autoButtons, "Process Equipment", "Process all equipment and set up attributes", "processEquipment", 40)
    createCommandButton(autoButtons, "Generate Hitboxes", "Create hitboxes for BuyTile interaction", "generateHitboxes", 50)
    
    -- Adjust the category size based on content
    autoCategory.Size = UDim2.new(1, 0, 0, autoButtons.Position.Y.Offset + autoButtons.AbsoluteSize.Y + 20)
    
    -- Model Validation Category
    local validationCategory, validationButtons = createCategory("Model Validation", "Validate and fix model issues", 300)
    validationCategory.Parent = scrollFrame
    validationCategory.Position = UDim2.new(0, 0, 0, autoCategory.AbsoluteSize.Y + autoCategory.AbsolutePosition.Y + 20)
    
    createCommandButton(validationButtons, "Validate Gym Models", "Check all models for common issues", "validateGymModels", 10)
    createCommandButton(validationButtons, "Fix Model Issues", "Attempt to fix common model issues", "fixModelIssues", 20, "warning")
    createCommandButton(validationButtons, "Apply Collection Tags", "Apply tags to models based on attributes", "applyCollectionTags", 30)
    createCommandButton(validationButtons, "Generate Equipment Config", "Create equipment configuration from models", "generateEquipmentConfig", 40)
    createCommandButton(validationButtons, "Generate UI Config", "Create UI configuration from UI elements", "generateUIConfig", 50)
    
    -- Adjust the category size based on content
    validationCategory.Size = UDim2.new(1, 0, 0, validationButtons.Position.Y.Offset + validationButtons.AbsoluteSize.Y + 20)
    
    -- Set final canvas size based on all content
    local totalHeight = validationCategory.AbsoluteSize.Y + validationCategory.AbsolutePosition.Y - scrollFrame.AbsolutePosition.Y + 30
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    return parent
end

-- Execute command
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