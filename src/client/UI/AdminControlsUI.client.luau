--[[
    AdminControlsUI.client.luau
    UI module for admin controls
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- We don't need PlayersService since it's not used
local UIStyle = require(script.Parent:FindFirstChild("UIStyle") or ReplicatedStorage:FindFirstChild("UIStyle"))
local DialogFactory = require(script.Parent:FindFirstChild("DialogFactory") or ReplicatedStorage:FindFirstChild("DialogFactory"))

local AdminControlsUI = {}

-- UI state
local uiState = {
    adminPanelVisible = false,
    currentTab = "admin",
    menuElements = {},
    commandHistory = {},
    commandHistoryIndex = 0
}

-- Admin check - only allow authorized players to use admin commands
local function isAdmin(player)
    -- For security, we would normally check if the player is in an admin group
    -- or has a specific role on the server
    
    -- This is a simple check for demo purposes
    local adminList = {
        "BuilderPerson25",
        "GameAdmin123",
        "ModeratorElite"
    }
    
    for _, adminName in ipairs(adminList) do
        if player.Name == adminName then
            return true
        end
    end
    
    -- Fallback to return true in Studio for testing
    if game:GetService("RunService"):IsStudio() then
        return true
    end
      -- Check admin users list in ReplicatedStorage
    local success, result = pcall(function()
		local adminUsersModule = game.ReplicatedStorage:FindFirstChild("AdminUsers")
		if adminUsersModule and adminUsersModule:IsA("ModuleScript") then
			local admins = require(adminUsersModule)
			if typeof(admins) == "table" then
				for _, adminId in ipairs(admins) do
					if player.UserId == adminId then
						return true
					end
				end
			end
		end
		return false
	end)
    
    -- Return true if pcall succeeded and result is true
    if success and result == true then
        return true
    end
    
    -- Not an admin
    return false
end

-- Initialize the admin UI
function AdminControlsUI:Initialize(player)
    -- Only admins can initialize the admin UI
    if not isAdmin(player) then
        print("Player " .. player.Name .. " is not an admin, admin UI not initialized")
        return false
    end
    
    -- Create the main admin panel
    local adminPanel = Instance.new("Frame")
    adminPanel.Name = "AdminPanel"
    adminPanel.Size = UDim2.new(0.8, 0, 0.8, 0)
    adminPanel.Position = UDim2.new(0.1, 0, 0.1, 0)
    adminPanel.BackgroundColor3 = UIStyle.Colors.Background
    adminPanel.BackgroundTransparency = 0.1
    adminPanel.Visible = false
      -- Add corner radius
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = adminPanel
    
    -- Create the title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0.08, 0)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = UIStyle.Colors.Primary
    titleBar.Parent = adminPanel
    
    -- Add corner radius to title bar
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    -- Create title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(0.7, 0, 0.8, 0)
    titleText.Position = UDim2.new(0.02, 0, 0.1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Admin Controls"
    titleText.Font = UIStyle.Fonts.Title
    titleText.TextColor3 = UIStyle.Colors.Text
    titleText.TextSize = 24
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.08, 0, 0.8, 0)
    closeButton.Position = UDim2.new(0.91, 0, 0.1, 0)
    closeButton.BackgroundColor3 = UIStyle.Colors.Danger
    closeButton.Text = "X"
    closeButton.Font = UIStyle.Fonts.Bold
    closeButton.TextColor3 = UIStyle.Colors.Text
    closeButton.TextSize = 20
    closeButton.Parent = titleBar
    
    -- Add corner radius to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Create tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0.08, 0)
    tabBar.Position = UDim2.new(0, 0, 0.08, 0)
    tabBar.BackgroundColor3 = UIStyle.Colors.Secondary
    tabBar.BackgroundTransparency = 0.2
    tabBar.Parent = adminPanel
    
    -- Create content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, 0, 0.84, 0)
    contentArea.Position = UDim2.new(0, 0, 0.16, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = adminPanel
    
    -- Create tab buttons
    local tabButtons = {}
    local tabContents = {}
    
    -- Function to create a tab button
    local function createTabButton(name, text, index)
        local button = Instance.new("TextButton")
        button.Name = name .. "Tab"
        button.Size = UDim2.new(0.2, 0, 0.8, 0)
        button.Position = UDim2.new(0.02 + (index - 1) * 0.22, 0, 0.1, 0)
        button.BackgroundColor3 = UIStyle.Colors.Primary
        button.BackgroundTransparency = 0.4
        button.Text = text
        button.Font = UIStyle.Fonts.Bold
        button.TextColor3 = UIStyle.Colors.Text
        button.TextSize = 18
        button.Parent = tabBar
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        
        -- Add to tab buttons
        tabButtons[name] = button
        
        -- Create content panel for this tab
        local content = Instance.new("ScrollingFrame")
        content.Name = name .. "Content"
        content.Size = UDim2.new(0.98, 0, 0.98, 0)
        content.Position = UDim2.new(0.01, 0, 0.01, 0)
        content.BackgroundTransparency = 1
        content.Visible = false
        content.ScrollBarThickness = 6
        content.ScrollingDirection = Enum.ScrollingDirection.Y
        content.CanvasSize = UDim2.new(0, 0, 2, 0)
        content.Parent = contentArea
        
        -- Add basic padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.Parent = content
        
        -- Add to tab contents
        tabContents[name] = content
        
        -- Tab switching logic
        button.MouseButton1Click:Connect(function()
            -- Hide all content panels
            for _, panel in pairs(tabContents) do
                panel.Visible = false
            end
            
            -- Reset all button styling
            for _, btn in pairs(tabButtons) do
                btn.BackgroundTransparency = 0.4
            end
            
            -- Show this tab's content
            content.Visible = true
            button.BackgroundTransparency = 0
            
            -- Update current tab
            uiState.currentTab = name
        end)
        
        return button
    end
    
    -- Create common tabs
    createTabButton("admin", "Admin", 1)
    createTabButton("tools", "Tools", 2)
    createTabButton("reports", "Reports", 3)
    createTabButton("console", "Console", 4)
    
    -- Show admin tab by default
    tabContents.admin.Visible = true
    tabButtons.admin.BackgroundTransparency = 0
    
    -- Create admin console input and output in console tab
    local outputLog = Instance.new("ScrollingFrame")
    outputLog.Name = "OutputLog"
    outputLog.Size = UDim2.new(1, 0, 0.85, 0)
    outputLog.Position = UDim2.new(0, 0, 0, 0)
    outputLog.BackgroundColor3 = UIStyle.Colors.ConsoleBackground
    outputLog.BackgroundTransparency = 0.3
    outputLog.ScrollBarThickness = 6
    outputLog.ScrollingDirection = Enum.ScrollingDirection.Y
    outputLog.CanvasSize = UDim2.new(0, 0, 0, 0)
    outputLog.Parent = tabContents.console
    
    -- Add corner radius
    local outputCorner = Instance.new("UICorner")
    outputCorner.CornerRadius = UDim.new(0, 6)
    outputCorner.Parent = outputLog
    
    -- Create input field
    local inputContainer = Instance.new("Frame")
    inputContainer.Name = "InputContainer"
    inputContainer.Size = UDim2.new(1, 0, 0.1, 0)
    inputContainer.Position = UDim2.new(0, 0, 0.88, 0)
    inputContainer.BackgroundColor3 = UIStyle.Colors.ConsoleBackground
    inputContainer.BackgroundTransparency = 0.3
    inputContainer.Parent = tabContents.console
    
    -- Add corner radius
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputContainer
    
    -- Create input text box
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "InputBox"
    inputBox.Size = UDim2.new(0.9, 0, 0.8, 0)
    inputBox.Position = UDim2.new(0.05, 0, 0.1, 0)
    inputBox.BackgroundColor3 = UIStyle.Colors.InputBackground
    inputBox.BackgroundTransparency = 0.2
    inputBox.Text = ""
    inputBox.PlaceholderText = "Enter admin command..."
    inputBox.Font = UIStyle.Fonts.Code
    inputBox.TextColor3 = UIStyle.Colors.Text
    inputBox.TextSize = 18
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputContainer
    
    -- Add corner radius
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = inputBox
    
    -- Implement command history
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local command = inputBox.Text
            if command and command ~= "" then
                -- Add to command history
                table.insert(uiState.commandHistory, command)
                uiState.commandHistoryIndex = #uiState.commandHistory + 1
                
                -- Execute the command
                self:ExecuteCommand(command)
                
                -- Clear the input box
                inputBox.Text = ""
            end
        end
    end)
    
    -- Handle up/down arrow for command history
    inputBox:GetPropertyChangedSignal("Text"):Connect(function()
        local text = inputBox.Text
        if text == "\b" then -- Up arrow
            if uiState.commandHistoryIndex > 1 then
                uiState.commandHistoryIndex = uiState.commandHistoryIndex - 1
                inputBox.Text = uiState.commandHistory[uiState.commandHistoryIndex]
            end
        elseif text == "\n" then -- Down arrow
            if uiState.commandHistoryIndex < #uiState.commandHistory then
                uiState.commandHistoryIndex = uiState.commandHistoryIndex + 1
                inputBox.Text = uiState.commandHistory[uiState.commandHistoryIndex]
            else
                uiState.commandHistoryIndex = #uiState.commandHistory + 1
                inputBox.Text = ""
            end
        end
    end)
    
    -- Function to create the admin tools tab
    self:CreateAdminToolsTab(tabContents.tools) -- No need to store the return value
    
    -- Store UI elements in state
    uiState.menuElements = {
        adminPanel = adminPanel,
        tabButtons = tabButtons,
        tabContents = tabContents,
        outputLog = outputLog,
        inputBox = inputBox,
        closeButton = closeButton
    }
    
    -- Add to player's GUI
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        adminPanel.Parent = playerGui
    end
      -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        self:ToggleAdminPanel()
    end)
    
    -- Write initial message to console
    self:AddCommandOutput(outputLog, "System", "Admin console initialized. Type 'help' for commands.")
    
    -- Set up key binding for toggle (Ctrl+A)
    local userInputService = game:GetService("UserInputService")
    userInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.A and userInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            self:ToggleAdminPanel()
        end
    end)
    
    -- Create the admin button
    local adminButton = Instance.new("TextButton")
    adminButton.Name = "AdminButton"
    adminButton.Size = UDim2.new(0, 100, 0, 40)
    adminButton.Position = UDim2.new(0, 10, 0.95, -40)
    adminButton.BackgroundColor3 = UIStyle.Colors.Primary
    adminButton.Text = "Admin"
    adminButton.Font = UIStyle.Fonts.Bold
    adminButton.TextColor3 = UIStyle.Colors.Text
    adminButton.TextSize = 18
    adminButton.Visible = true
    adminButton.Parent = playerGui
    
    -- Add corner radius
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = adminButton
    
    -- Toggle admin panel when button is clicked
    adminButton.MouseButton1Click:Connect(function()
        self:ToggleAdminPanel()
    end)
    
    return true
end

-- Add output to the console log
function AdminControlsUI:AddCommandOutput(outputLog, category, message)
    -- Create text label for output
    local outputLine = Instance.new("TextLabel")
    outputLine.Name = "Output" .. os.time() .. math.random(1000, 9999)
    outputLine.Size = UDim2.new(1, -10, 0, 24)
    outputLine.Position = UDim2.new(0, 5, 0, 0) -- Will be positioned by UIListLayout
    outputLine.BackgroundTransparency = 1
    outputLine.TextXAlignment = Enum.TextXAlignment.Left
    outputLine.TextSize = 16
    outputLine.Font = UIStyle.Fonts.Code
    
    -- Format and color output based on category
    if category == "Error" then
        outputLine.Text = "[ERROR] " .. message
        outputLine.TextColor3 = UIStyle.Colors.Error
    elseif category == "Success" then
        outputLine.Text = "[SUCCESS] " .. message
        outputLine.TextColor3 = UIStyle.Colors.Success
    elseif category == "Command" then
        outputLine.Text = "> " .. message
        outputLine.TextColor3 = UIStyle.Colors.Command
    else
        outputLine.Text = "[" .. category .. "] " .. message
        outputLine.TextColor3 = UIStyle.Colors.Info
    end
    
    -- Add to output log
    outputLine.Parent = outputLog
    
    -- Add list layout if not present
    if not outputLog:FindFirstChild("UIListLayout") then
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 2)
        listLayout.SortOrder = Enum.SortOrder.Name
        listLayout.Parent = outputLog
    end
    
    -- Update canvas size
    local listLayout = outputLog:FindFirstChild("UIListLayout")
    if listLayout then
        outputLog.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end
    
    -- Scroll to bottom
    outputLog.CanvasPosition = Vector2.new(0, outputLog.CanvasSize.Y.Offset)
    
    return outputLine
end

-- Execute command
function AdminControlsUI:ExecuteCommand(commandText)
    if not commandText or commandText == "" then return end
    
    local outputLog = uiState.menuElements.outputLog
    if not outputLog then
        outputLog = Instance.new("ScrollingFrame")
        outputLog.Name = "OutputLog"
        uiState.menuElements.outputLog = outputLog
    end
    
    -- Add the command to the log
    self:AddCommandOutput(outputLog, "Command", commandText)
    
    -- Parse the command
    local args = string.split(commandText, " ")
    local command = string.lower(args[1])
    table.remove(args, 1)
    
    -- Process commands
    if command == "help" then
        self:AddCommandOutput(outputLog, "System", "Available commands:")
        self:AddCommandOutput(outputLog, "Info", "help - Display this help message")
        self:AddCommandOutput(outputLog, "Info", "kick [player] [reason] - Kick a player")
        self:AddCommandOutput(outputLog, "Info", "ban [player] [duration] [reason] - Ban a player")
        self:AddCommandOutput(outputLog, "Info", "unban [player] - Unban a player")
        self:AddCommandOutput(outputLog, "Info", "mute [player] [duration] - Mute a player")
        self:AddCommandOutput(outputLog, "Info", "unmute [player] - Unmute a player")
        self:AddCommandOutput(outputLog, "Info", "give [player] [item] [amount] - Give item to player")
        self:AddCommandOutput(outputLog, "Info", "teleport [player] [destination] - Teleport player")
        self:AddCommandOutput(outputLog, "Info", "shutdown - Shut down the server")
        self:AddCommandOutput(outputLog, "Info", "setupbuytiles - Set up buy tiles in the game")
        self:AddCommandOutput(outputLog, "Info", "heal [player] - Heal a player")
        self:AddCommandOutput(outputLog, "Info", "clear - Clear the console")
    elseif command == "kick" then
        if #args < 1 then
            self:AddCommandOutput(outputLog, "Error", "Usage: kick [player] [reason]")
        else
            local playerName = args[1]
            local reason = "No reason provided"
            if #args > 1 then
                reason = table.concat(args, " ", 2)
            end
            
            self:AddCommandOutput(outputLog, "System", "Kicking player: " .. playerName .. " for: " .. reason)
            -- In a real implementation, this would call server-side admin functions
        end
    elseif command == "ban" then
        if #args < 2 then
            self:AddCommandOutput(outputLog, "Error", "Usage: ban [player] [duration] [reason]")
        else
            local playerName = args[1]
            local duration = args[2]
            local reason = "No reason provided"
            if #args > 2 then
                reason = table.concat(args, " ", 3)
            end
            
            self:AddCommandOutput(outputLog, "System", "Banning player: " .. playerName .. " for " .. duration .. " - " .. reason)
            -- In a real implementation, this would call server-side admin functions
        end
    elseif command == "setupbuytiles" then
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
            self:AddCommandOutput(outputLog, "Success", "BuyTile System setup completed successfully!")
            DialogFactory.createNotification("BuyTile System setup completed successfully!", 3, "success")
        else
            self:AddCommandOutput(outputLog, "Error", "Failed to set up BuyTile System: " .. tostring(result))
            DialogFactory.createNotification("Failed to set up BuyTile System: " .. tostring(result), 3, "error")
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
    adminPanel.Visible = uiState.adminPanelVisible
end

-- Create the admin tools tab
function AdminControlsUI:CreateAdminToolsTab(parent)
    -- Create a scrolling container for all the tools
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ToolsContainer"
    scrollFrame.Size = UDim2.new(0.98, 0, 0.98, 0)
    scrollFrame.Position = UDim2.new(0.01, 0, 0.01, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
    scrollFrame.Parent = parent
    
    -- Add padding to the scrolling frame
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = scrollFrame
    
    -- Function to create a category with buttons
    local function createCategory(name, description, layoutOrder)
        local categoryFrame = Instance.new("Frame")
        categoryFrame.Name = name .. "Category"
        categoryFrame.Size = UDim2.new(1, 0, 0, 40)
        categoryFrame.BackgroundColor3 = UIStyle.Colors.BackgroundLight
        categoryFrame.BorderSizePixel = 0
        categoryFrame.LayoutOrder = layoutOrder
        
        -- Add corner radius
        local categoryCorner = Instance.new("UICorner")
        categoryCorner.CornerRadius = UDim.new(0, 8)
        categoryCorner.Parent = categoryFrame
        
        -- Add category name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -20, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.Font = UIStyle.Fonts.Bold
        nameLabel.TextColor3 = UIStyle.Colors.Text
        nameLabel.TextSize = 20
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = categoryFrame
        
        -- Add description as tooltip
        local descriptionLabel = Instance.new("TextLabel")
        descriptionLabel.Size = UDim2.new(1, -20, 0, 0) -- Adjusted to hidden by default
        descriptionLabel.Position = UDim2.new(0, 10, 0, 40)
        descriptionLabel.BackgroundTransparency = 1
        descriptionLabel.Text = description
        descriptionLabel.Font = UIStyle.Fonts.Regular
        descriptionLabel.TextColor3 = UIStyle.Colors.SubText
        descriptionLabel.TextSize = 16
        descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        descriptionLabel.Parent = categoryFrame
        
        -- Create container for buttons
        local buttonsContainer = Instance.new("Frame")
        buttonsContainer.Name = "ButtonsContainer"
        buttonsContainer.Size = UDim2.new(1, 0, 0, 0) -- Will be resized based on content
        buttonsContainer.Position = UDim2.new(0, 0, 0, 40)
        buttonsContainer.BackgroundTransparency = 1
        buttonsContainer.Parent = categoryFrame
        
        -- Add list layout for buttons
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 10)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = buttonsContainer
        
        -- Return both the category frame and the button container
        return categoryFrame, buttonsContainer
    end
    
    -- Function to create a command button
    local function createCommandButton(container, name, description, commandFunc, layoutOrder, buttonType)
        buttonType = buttonType or "default"
        
        -- Create a button
        local button = Instance.new("TextButton")
        button.Name = name:gsub(" ", "") .. "Button"
        button.Size = UDim2.new(1, 0, 0, 40)
        button.LayoutOrder = layoutOrder
        button.BackgroundColor3 = UIStyle.Colors.ButtonPrimary
        button.Font = UIStyle.Fonts.Bold
        button.Text = name
        button.TextSize = 18
        button.TextColor3 = UIStyle.Colors.Text
        button.Parent = container
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        
        -- Button click handler
        button.MouseButton1Click:Connect(
            function()
                -- Show confirmation dialog
                DialogFactory.createConfirmationDialog(
                    "Run Command: " .. name,
                    description .. "\n\nAre you sure you want to execute this command?",
                    function()                        -- Using the existing ReplicatedStorage reference
                        local remotes = ReplicatedStorage:FindFirstChild("AdminRemotes")
                        
                        if remotes then
                            local executeCommand = remotes:FindFirstChild("ExecuteAdminCommand")
                            if executeCommand then                                -- Log the command execution in the output
                                -- Get a reference to the output log from uiState
                                if uiState.menuElements.outputLog then
                                    self:AddCommandOutput(uiState.menuElements.outputLog, "System", "Running command: " .. name)
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
                                        if uiState.menuElements.outputLog then
                                            self:AddCommandOutput(uiState.menuElements.outputLog, "Success", "Command executed: " .. name .. "\n" .. (result.message or ""))
                                        end
                                    else
                                        DialogFactory.createNotification("Command failed: " .. (result.message or "Unknown error"), 3, "error")
                                          -- Add to output log
                                        if uiState.menuElements.outputLog then
                                            self:AddCommandOutput(uiState.menuElements.outputLog, "Error", "Command failed: " .. name .. "\n" .. (result.message or ""))
                                        end
                                    end
                                else
                                    DialogFactory.createNotification("Failed to execute command. Check server logs.", 3, "error")
                                      -- Add to output log
                                    if uiState.menuElements.outputLog then
                                        self:AddCommandOutput(uiState.menuElements.outputLog, "Error", "Failed to execute command: " .. name)
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

    -- Create categories and add buttons    -- Make sure we have a scroll frame reference
    if not uiState.menuElements.scrollFrame then
        uiState.menuElements.scrollFrame = Instance.new("ScrollingFrame")
        uiState.menuElements.scrollFrame.Name = "ScrollFrame"
    end
      -- Tycoon Information Category
    local infoCategory, infoButtons = createCategory("Tycoon Information", "View and analyze gym structure information", 100)
    infoCategory.Parent = uiState.menuElements.scrollFrame
    
    createCommandButton(infoButtons, "Show Tycoon Info", "Display detailed information about tycoon structure", "showTycoonInfo", 10)
    createCommandButton(infoButtons, "Analyze Gym Structure", "Analyze gym structure without making changes", "analyzeGymStructure", 20)
    createCommandButton(infoButtons, "Generate Model Report", "Create detailed validation report for models", "generateModelReport", 30)
    createCommandButton(infoButtons, "Show Hitboxes", "Make hitboxes visible in the workspace", "showHitboxes", 40, "warning")
    createCommandButton(infoButtons, "Hide Hitboxes", "Hide hitboxes in the workspace", "hideHitboxes", 50)
    
    -- Adjust the category size based on content
    infoCategory.Size = UDim2.new(1, 0, 0, infoButtons.Position.Y.Offset + infoButtons.AbsoluteSize.Y + 20)
      -- Tycoon Automation Category
    local autoCategory, autoButtons = createCategory("Tycoon Automation", "Automate tycoon setup and configuration", 200)
    autoCategory.Parent = uiState.menuElements.scrollFrame
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
    validationCategory.Parent = uiState.menuElements.scrollFrame
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
    
    -- Return the scroll frame itself since we don't have a parent reference
    return scrollFrame
end

return AdminControlsUI
