--[[
    DataManagementUI.client.luau
    
    A graphical interface for data management operations.
    This UI allows admins to perform data operations through
    a visual interface rather than chat commands.
    
    Author: Created April 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- UI Components
local UIComponents = {}

-- Find CoreRegistry on the client
local CoreRegistry
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
CoreRegistry = findClientRegistry()

-- Remote events for communicating with server
local AdminRemoteEvent
local AdminRemoteFunction

-- Log function
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
        return AdminRemoteFunction:InvokeServer("checkAdmin")
    end)
    
    return success and result
end

-- Create a stylized button
local function createStyledButton(parent, text, position, size, callback)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Text = text
    button.Position = position
    button.Size = size
    button.Parent = parent
    button.BackgroundColor3 = Color3.fromRGB(65, 105, 225) -- Royal blue
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    button.TextSize = 14
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add hover effects
    local hoverColor = Color3.fromRGB(100, 140, 250)
    local defaultColor = button.BackgroundColor3
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = defaultColor}):Play()
    end)
    
    -- Add click callback
    button.MouseButton1Click:Connect(function()
        callback(button)
    end)
    
    return button
end

-- Create a label with consistent styling
local function createStyledLabel(parent, text, position, size)
    local label = Instance.new("TextLabel")
    label.Name = text .. "Label"
    label.Text = text
    label.Position = position
    label.Size = size
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(240, 240, 240)
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

-- Create a input box with consistent styling
local function createStyledTextBox(parent, placeholder, position, size)
    local textBox = Instance.new("TextBox")
    textBox.Name = placeholder .. "TextBox"
    textBox.PlaceholderText = placeholder
    textBox.Text = ""
    textBox.Position = position
    textBox.Size = size
    textBox.Parent = parent
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    textBox.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    textBox.TextSize = 14
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

-- Create the main UI container
local function createMainUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DataManagementUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer.PlayerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- Add corner radius to main frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Add title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(50, 80, 190)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Add corner radius to title bar (top corners only)
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Fix title bar bottom corners (make them straight)
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Name = "BottomFrame"
    bottomFrame.Size = UDim2.new(1, 0, 0, 10)
    bottomFrame.Position = UDim2.new(0, 0, 1, -10)
    bottomFrame.BackgroundColor3 = Color3.fromRGB(50, 80, 190)
    bottomFrame.BorderSizePixel = 0
    bottomFrame.ZIndex = titleBar.ZIndex
    bottomFrame.Parent = titleBar
    
    -- Add title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 50, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Data Management"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 5)
    closeButton.Text = "✕"
    closeButton.TextSize = 18
    closeButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundTransparency = 0.5
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    -- Add corner radius to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton
    
    -- Add tab buttons container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 150, 1, -40)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    
    -- Add scrolling frame for content
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -150, 1, -40)
    contentFrame.Position = UDim2.new(0, 150, 0, 40)
    contentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 6
    contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
    contentFrame.Parent = mainFrame
    
    -- Make UI draggable
    local isDragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService = game:GetService("UserInputService")
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and isDragging then
            update(input)
        end
    end)
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)
    
    -- Setup tab buttons
    local tabButtons = {}
    local tabContents = {}
    
    local function createTab(name)
        local yPos = #tabButtons * 40
        
        -- Create tab button
        local tabButton = createStyledButton(tabContainer, name, UDim2.new(0, 5, 0, yPos + 5), UDim2.new(1, -10, 0, 35), function()
            -- Show this tab, hide others
            for tabName, content in pairs(tabContents) do
                content.Visible = (tabName == name)
            end
            
            -- Update button styles
            for _, button in ipairs(tabButtons) do
                if button.Text == name then
                    button.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
                else
                    button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                end
            end
        end)
        
        -- Create content container for this tab
        local tabContent = Instance.new("Frame")
        tabContent.Name = name .. "Content"
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = #tabButtons == 0 -- First tab is visible by default
        tabContent.Parent = contentFrame
        
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
    local playerDataTab = createTab("Player Data")
    local versionHistoryTab = createTab("Version History")
    local migrationTab = createTab("Data Migration")
    local analyticsTab = createTab("Analytics")
    local settingsTab = createTab("Settings")
    
    -- Set up player data tab
    do
        -- Player selection
        createStyledLabel(playerDataTab, "Select Player:", UDim2.new(0, 20, 0, 20), UDim2.new(0, 100, 0, 30))
        local playerDropdown = Instance.new("TextBox")
        playerDropdown.Name = "PlayerDropdown"
        playerDropdown.PlaceholderText = "Enter player name"
        playerDropdown.Text = ""
        playerDropdown.Position = UDim2.new(0, 130, 0, 20)
        playerDropdown.Size = UDim2.new(0, 200, 0, 30)
        playerDropdown.Parent = playerDataTab
        playerDropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        playerDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
        playerDropdown.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        playerDropdown.TextSize = 14
        playerDropdown.BorderSizePixel = 0
        
        local playerCorner = Instance.new("UICorner")
        playerCorner.CornerRadius = UDim.new(0, 8)
        playerCorner.Parent = playerDropdown
        
        -- Data path
        createStyledLabel(playerDataTab, "Data Path:", UDim2.new(0, 20, 0, 70), UDim2.new(0, 100, 0, 30))
        local dataPathInput = createStyledTextBox(playerDataTab, "e.g. cash, equipment.1, etc.", UDim2.new(0, 130, 0, 70), UDim2.new(0, 200, 0, 30))
        
        -- Data value display
        createStyledLabel(playerDataTab, "Data Value:", UDim2.new(0, 20, 0, 120), UDim2.new(0, 100, 0, 30))
        local dataValueBox = Instance.new("TextBox")
        dataValueBox.Name = "DataValueBox"
        dataValueBox.MultiLine = true
        dataValueBox.ClearTextOnFocus = false
        dataValueBox.Position = UDim2.new(0, 20, 0, 160)
        dataValueBox.Size = UDim2.new(1, -40, 0, 200)
        dataValueBox.Parent = playerDataTab
        dataValueBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        dataValueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        dataValueBox.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
        dataValueBox.TextSize = 14
        dataValueBox.TextXAlignment = Enum.TextXAlignment.Left
        dataValueBox.TextYAlignment = Enum.TextYAlignment.Top
        dataValueBox.TextEditable = true
        dataValueBox.BorderSizePixel = 0
        
        local valueCorner = Instance.new("UICorner")
        valueCorner.CornerRadius = UDim.new(0, 8)
        valueCorner.Parent = dataValueBox
        
        -- Action buttons
        local viewButton = createStyledButton(playerDataTab, "View Data", UDim2.new(0, 20, 0, 380), UDim2.new(0, 120, 0, 35), function()
            local playerName = playerDropdown.Text
            local path = dataPathInput.Text
            
            -- Send command to server
            if AdminRemoteFunction then
                local success, result = pcall(function()
                    return AdminRemoteFunction:InvokeServer("viewData", playerName, path)
                end)
                
                if success and result then
                    -- Format the result nicely
                    if type(result) == "table" then
                        -- Pretty print tables
                        local formattedResult = "{\n"
                        for k, v in pairs(result) do
                            formattedResult = formattedResult .. "   " .. tostring(k) .. " = " .. tostring(v) .. ",\n"
                        end
                        formattedResult = formattedResult .. "}"
                        dataValueBox.Text = formattedResult
                    else
                        dataValueBox.Text = tostring(result)
                    end
                else
                    dataValueBox.Text = "Error: " .. tostring(result)
                end
            end
        end)
        
        local saveButton = createStyledButton(playerDataTab, "Save Changes", UDim2.new(0, 150, 0, 380), UDim2.new(0, 120, 0, 35), function()
            local playerName = playerDropdown.Text
            local path = dataPathInput.Text
            local value = dataValueBox.Text
            
            -- Try to parse value as JSON
            local parsedValue
            local success = pcall(function()
                parsedValue = game:GetService("HttpService"):JSONDecode(value)
            end)
            
            if not success then
                -- Try to convert to number or boolean
                if value == "true" then
                    parsedValue = true
                elseif value == "false" then
                    parsedValue = false
                elseif tonumber(value) then
                    parsedValue = tonumber(value)
                else
                    parsedValue = value -- Keep as string
                end
            end
            
            -- Send command to server
            if AdminRemoteEvent then
                AdminRemoteEvent:FireServer("updateData", playerName, path, parsedValue)
            end
        end)
        
        local backupButton = createStyledButton(playerDataTab, "Create Backup", UDim2.new(0, 280, 0, 380), UDim2.new(0, 120, 0, 35), function()
            local playerName = playerDropdown.Text
            
            -- Send command to server
            if AdminRemoteEvent then
                AdminRemoteEvent:FireServer("createBackup", playerName)
            end
        end)
    end
    
    -- Set up version history tab
    do
        -- Player selection
        createStyledLabel(versionHistoryTab, "Select Player:", UDim2.new(0, 20, 0, 20), UDim2.new(0, 100, 0, 30))
        local playerInput = createStyledTextBox(versionHistoryTab, "Enter player name", UDim2.new(0, 130, 0, 20), UDim2.new(0, 200, 0, 30))
        
        -- Version list container
        local versionListContainer = Instance.new("ScrollingFrame")
        versionListContainer.Name = "VersionListContainer"
        versionListContainer.Position = UDim2.new(0, 20, 0, 70)
        versionListContainer.Size = UDim2.new(1, -40, 0, 300)
        versionListContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        versionListContainer.BorderSizePixel = 0
        versionListContainer.ScrollBarThickness = 6
        versionListContainer.Parent = versionHistoryTab
        
        local versionListCorner = Instance.new("UICorner")
        versionListCorner.CornerRadius = UDim.new(0, 8)
        versionListCorner.Parent = versionListContainer
        
        -- List layout for versions
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 5)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = versionListContainer
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.Parent = versionListContainer
        
        -- Action buttons
        local refreshButton = createStyledButton(versionHistoryTab, "Refresh Versions", UDim2.new(0, 20, 0, 390), UDim2.new(0, 140, 0, 35), function()
            local playerName = playerInput.Text
            
            -- Send command to server
            if AdminRemoteFunction then
                local success, versions = pcall(function()
                    return AdminRemoteFunction:InvokeServer("getVersions", playerName)
                end)
                
                if success and versions then
                    -- Clear existing items
                    for _, child in pairs(versionListContainer:GetChildren()) do
                        if child:IsA("Frame") then
                            child:Destroy()
                        end
                    end
                    
                    -- Add version items
                    for i, version in ipairs(versions) do
                        local versionItem = Instance.new("Frame")
                        versionItem.Name = "Version_" .. i
                        versionItem.Size = UDim2.new(1, 0, 0, 40)
                        versionItem.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                        versionItem.BorderSizePixel = 0
                        versionItem.LayoutOrder = i
                        versionItem.Parent = versionListContainer
                        
                        local versionCorner = Instance.new("UICorner")
                        versionCorner.CornerRadius = UDim.new(0, 6)
                        versionCorner.Parent = versionItem
                        
                        -- Version key and time
                        local versionLabel = Instance.new("TextLabel")
                        versionLabel.Name = "VersionLabel"
                        versionLabel.Size = UDim2.new(0.7, 0, 1, 0)
                        versionLabel.Position = UDim2.new(0, 10, 0, 0)
                        versionLabel.BackgroundTransparency = 1
                        versionLabel.Text = string.format("Version %d: %s", i, os.date("%Y-%m-%d %H:%M:%S", version.timestamp))
                        versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        versionLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
                        versionLabel.TextSize = 14
                        versionLabel.TextXAlignment = Enum.TextXAlignment.Left
                        versionLabel.Parent = versionItem
                        
                        -- Rollback button
                        local rollbackButton = createStyledButton(versionItem, "Rollback", UDim2.new(1, -110, 0.5, -15), UDim2.new(0, 100, 0, 30), function()
                            -- Send rollback command
                            if AdminRemoteEvent then
                                AdminRemoteEvent:FireServer("rollback", playerName, version.key)
                            end
                        end)
                    end
                    
                    -- Update canvas size
                    versionListContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
                end
            end
        end)
    end
    
    -- Set up migration tab
    do
        -- Migration form
        createStyledLabel(migrationTab, "Source System:", UDim2.new(0, 20, 0, 20), UDim2.new(0, 120, 0, 30))
        local sourceDropdown = Instance.new("TextBox")
        sourceDropdown.Name = "SourceDropdown"
        sourceDropdown.PlaceholderText = "Enter source (enhanced, datamanager, etc.)"
        sourceDropdown.Text = ""
        sourceDropdown.Position = UDim2.new(0, 150, 0, 20)
        sourceDropdown.Size = UDim2.new(0, 250, 0, 30)
        sourceDropdown.Parent = migrationTab
        sourceDropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        sourceDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
        sourceDropdown.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        sourceDropdown.TextSize = 14
        sourceDropdown.BorderSizePixel = 0
        
        local sourceCorner = Instance.new("UICorner")
        sourceCorner.CornerRadius = UDim.new(0, 8)
        sourceCorner.Parent = sourceDropdown
        
        createStyledLabel(migrationTab, "Destination System:", UDim2.new(0, 20, 0, 70), UDim2.new(0, 120, 0, 30))
        local destDropdown = Instance.new("TextBox")
        destDropdown.Name = "DestDropdown"
        destDropdown.PlaceholderText = "Enter destination (datamanager, versioned, etc.)"
        destDropdown.Text = ""
        destDropdown.Position = UDim2.new(0, 150, 0, 70)
        destDropdown.Size = UDim2.new(0, 250, 0, 30)
        destDropdown.Parent = migrationTab
        destDropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        destDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
        destDropdown.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        destDropdown.TextSize = 14
        destDropdown.BorderSizePixel = 0
        
        local destCorner = Instance.new("UICorner")
        destCorner.CornerRadius = UDim.new(0, 8)
        destCorner.Parent = destDropdown
        
        createStyledLabel(migrationTab, "Player(s):", UDim2.new(0, 20, 0, 120), UDim2.new(0, 120, 0, 30))
        local playerInput = createStyledTextBox(migrationTab, "Enter player name or 'all'", UDim2.new(0, 150, 0, 120), UDim2.new(0, 250, 0, 30))
        
        -- Status display
        createStyledLabel(migrationTab, "Migration Status:", UDim2.new(0, 20, 0, 170), UDim2.new(0, 150, 0, 30))
        local statusFrame = Instance.new("Frame")
        statusFrame.Name = "StatusFrame"
        statusFrame.Position = UDim2.new(0, 20, 0, 210)
        statusFrame.Size = UDim2.new(1, -40, 0, 150)
        statusFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        statusFrame.BorderSizePixel = 0
        statusFrame.Parent = migrationTab
        
        local statusCorner = Instance.new("UICorner")
        statusCorner.CornerRadius = UDim.new(0, 8)
        statusCorner.Parent = statusFrame
        
        local statusText = Instance.new("TextLabel")
        statusText.Name = "StatusText"
        statusText.Size = UDim2.new(1, -20, 1, -20)
        statusText.Position = UDim2.new(0, 10, 0, 10)
        statusText.BackgroundTransparency = 1
        statusText.Text = "No migration in progress"
        statusText.TextColor3 = Color3.fromRGB(220, 220, 220)
        statusText.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
        statusText.TextSize = 14
        statusText.TextXAlignment = Enum.TextXAlignment.Left
        statusText.TextYAlignment = Enum.TextYAlignment.Top
        statusText.Parent = statusFrame
        
        -- Action buttons
        local startButton = createStyledButton(migrationTab, "Start Migration", UDim2.new(0, 20, 0, 380), UDim2.new(0, 140, 0, 35), function()
            local source = sourceDropdown.Text
            local destination = destDropdown.Text
            local player = playerInput.Text
            
            -- Send command to server
            if AdminRemoteEvent then
                AdminRemoteEvent:FireServer("migrate", player, source, destination)
                statusText.Text = "Migration started for " .. player .. " from " .. source .. " to " .. destination
            end
        end)
        
        local checkButton = createStyledButton(migrationTab, "Check Status", UDim2.new(0, 180, 0, 380), UDim2.new(0, 140, 0, 35), function()
            local player = playerInput.Text
            
            -- Send command to server
            if AdminRemoteFunction then
                local success, result = pcall(function()
                    return AdminRemoteFunction:InvokeServer("migrationStatus", player)
                end)
                
                if success and result then
                    local status = "Migration Status for " .. player .. ":\n\n"
                    status = status .. "Source: " .. tostring(result.source or "N/A") .. "\n"
                    status = status .. "Destination: " .. tostring(result.destination or "N/A") .. "\n"
                    status = status .. "Status: " .. tostring(result.status or "N/A") .. "\n"
                    status = status .. "In Progress: " .. tostring(result.inProgress or false) .. "\n"
                    
                    if result.startTime then
                        status = status .. "Started: " .. os.date("%Y-%m-%d %H:%M:%S", result.startTime) .. "\n"
                    end
                    
                    if result.completeTime then
                        status = status .. "Completed: " .. os.date("%Y-%m-%d %H:%M:%S", result.completeTime) .. "\n"
                        local duration = result.completeTime - result.startTime
                        status = status .. "Duration: " .. duration .. " seconds"
                    end
                    
                    statusText.Text = status
                else
                    statusText.Text = "Error checking migration status: " .. tostring(result)
                end
            end
        end)
    end
    
    -- Set up analytics tab
    do
        -- Analytics dashboard will be set up elsewhere
        createStyledLabel(analyticsTab, "Data Analytics Dashboard", UDim2.new(0, 20, 0, 20), UDim2.new(0, 300, 0, 30))
        
        -- Message about analytics collection
        local messageText = Instance.new("TextLabel")
        messageText.Name = "MessageText"
        messageText.Size = UDim2.new(1, -40, 0, 60)
        messageText.Position = UDim2.new(0, 20, 0, 60)
        messageText.BackgroundTransparency = 1
        messageText.Text = "Analytics collection is active. Data is being gathered about player behavior, economy trends, and equipment preferences."
        messageText.TextColor3 = Color3.fromRGB(220, 220, 220)
        messageText.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        messageText.TextSize = 14
        messageText.TextWrapped = true
        messageText.TextXAlignment = Enum.TextXAlignment.Left
        messageText.Parent = analyticsTab
        
        -- Create metrics section
        createStyledLabel(analyticsTab, "Key Metrics:", UDim2.new(0, 20, 0, 130), UDim2.new(0, 100, 0, 30))
        
        local metricCards = {}
        local metrics = {
            {name = "Active Players", value = "0", color = Color3.fromRGB(65, 105, 225)},
            {name = "Total Revenue", value = "$0", color = Color3.fromRGB(60, 179, 113)},
            {name = "Avg. Session", value = "0 min", color = Color3.fromRGB(205, 92, 92)},
            {name = "Popular Equipment", value = "None", color = Color3.fromRGB(147, 112, 219)}
        }
        
        for i, metric in ipairs(metrics) do
            local xOffset = (i-1) % 2 * 215
            local yOffset = math.floor((i-1) / 2) * 110
            
            local metricCard = Instance.new("Frame")
            metricCard.Name = metric.name .. "Card"
            metricCard.Size = UDim2.new(0, 200, 0, 100)
            metricCard.Position = UDim2.new(0, 20 + xOffset, 0, 170 + yOffset)
            metricCard.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            metricCard.BorderSizePixel = 0
            metricCard.Parent = analyticsTab
            
            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 8)
            cardCorner.Parent = metricCard
            
            local metricName = Instance.new("TextLabel")
            metricName.Name = "MetricName"
            metricName.Size = UDim2.new(1, 0, 0, 30)
            metricName.Position = UDim2.new(0, 0, 0, 0)
            metricName.BackgroundTransparency = 1
            metricName.Text = metric.name
            metricName.TextColor3 = Color3.fromRGB(255, 255, 255)
            metricName.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
            metricName.TextSize = 14
            metricName.Parent = metricCard
            
            local metricValue = Instance.new("TextLabel")
            metricValue.Name = "MetricValue"
            metricValue.Size = UDim2.new(1, 0, 0, 50)
            metricValue.Position = UDim2.new(0, 0, 0, 40)
            metricValue.BackgroundTransparency = 1
            metricValue.Text = metric.value
            metricValue.TextColor3 = metric.color
            metricValue.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
            metricValue.TextSize = 24
            metricValue.Parent = metricCard
            
            metricCards[metric.name] = metricValue
        end
        
        -- Refresh button
        local refreshButton = createStyledButton(analyticsTab, "Refresh Analytics", UDim2.new(0, 20, 0, 400), UDim2.new(0, 140, 0, 35), function()
            -- Send command to server
            if AdminRemoteFunction then
                local success, result = pcall(function()
                    return AdminRemoteFunction:InvokeServer("getAnalytics")
                end)
                
                if success and result then
                    -- Update metric cards
                    metricCards["Active Players"].Text = tostring(result.activePlayers or 0)
                    metricCards["Total Revenue"].Text = "$" .. tostring(result.totalRevenue or 0)
                    metricCards["Avg. Session"].Text = tostring(result.averageSession or 0) .. " min"
                    metricCards["Popular Equipment"].Text = tostring(result.popularEquipment or "None")
                end
            end
        end)
    end
    
    -- Set up settings tab
    do
        createStyledLabel(settingsTab, "Data System Settings", UDim2.new(0, 20, 0, 20), UDim2.new(0, 200, 0, 30))
        
        local settings = {
            {name = "Auto-Save Interval", value = "120", unit = "seconds"},
            {name = "Backup Interval", value = "600", unit = "seconds"},
            {name = "Versions to Keep", value = "10", unit = "versions"},
            {name = "Debug Mode", value = "true", unit = "boolean"},
        }
        
        for i, setting in ipairs(settings) do
            local yPos = 60 + (i-1) * 60
            
            createStyledLabel(settingsTab, setting.name .. ":", UDim2.new(0, 20, 0, yPos), UDim2.new(0, 160, 0, 30))
            
            local settingInput = createStyledTextBox(settingsTab, "Enter value", UDim2.new(0, 190, 0, yPos), UDim2.new(0, 100, 0, 30))
            settingInput.Text = setting.value
            
            local unitLabel = Instance.new("TextLabel")
            unitLabel.Name = setting.name .. "UnitLabel"
            unitLabel.Size = UDim2.new(0, 100, 0, 30)
            unitLabel.Position = UDim2.new(0, 300, 0, yPos)
            unitLabel.BackgroundTransparency = 1
            unitLabel.Text = "(" .. setting.unit .. ")"
            unitLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            unitLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
            unitLabel.TextSize = 14
            unitLabel.TextXAlignment = Enum.TextXAlignment.Left
            unitLabel.Parent = settingsTab
        end
        
        -- Save settings button
        local saveButton = createStyledButton(settingsTab, "Save Settings", UDim2.new(0, 20, 0, 380), UDim2.new(0, 140, 0, 35), function()
            -- Collect all settings
            local newSettings = {}
            
            for _, setting in ipairs(settings) do
                local input = settingsTab:FindFirstChild(setting.name .. "TextBox")
                if input then
                    -- Convert to appropriate type
                    local value = input.Text
                    if setting.unit == "boolean" then
                        value = (value:lower() == "true")
                    elseif setting.unit == "seconds" or setting.unit == "versions" then
                        value = tonumber(value) or 0
                    end
                    
                    newSettings[setting.name:gsub(" ", "")] = value
                end
            end
            
            -- Send command to server
            if AdminRemoteEvent then
                AdminRemoteEvent:FireServer("updateSettings", newSettings)
            end
        end)
    end
    
    -- Initialize UI
    local function initialize()
        -- Check if player is admin when toggling UI visibility
        local function toggleVisibility()
            if isAdmin() then
                mainFrame.Visible = not mainFrame.Visible
            else
                log("Access denied - admin permissions required")
            end
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
        toggleButton.Parent = screenGui
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 10)
        toggleCorner.Parent = toggleButton
        
        toggleButton.MouseButton1Click:Connect(toggleVisibility)
        
        -- Set up the remote events/functions
        local success = pcall(function()
            AdminRemoteEvent = ReplicatedStorage:WaitForChild("DataAdmin"):WaitForChild("AdminEvent")
            AdminRemoteFunction = ReplicatedStorage:WaitForChild("DataAdmin"):WaitForChild("AdminFunction")
        end)
        
        if not success then
            log("Remote events not found - creating temporary ones")
            
            -- Create temporary remote objects
            local dataAdminFolder = ReplicatedStorage:FindFirstChild("DataAdmin") or Instance.new("Folder")
            dataAdminFolder.Name = "DataAdmin"
            dataAdminFolder.Parent = ReplicatedStorage
            
            AdminRemoteEvent = dataAdminFolder:FindFirstChild("AdminEvent") or Instance.new("RemoteEvent")
            AdminRemoteEvent.Name = "AdminEvent"
            AdminRemoteEvent.Parent = dataAdminFolder
            
            AdminRemoteFunction = dataAdminFolder:FindFirstChild("AdminFunction") or Instance.new("RemoteFunction")
            AdminRemoteFunction.Name = "AdminFunction" 
            AdminRemoteFunction.Parent = dataAdminFolder
        end
    end
    
    initialize()
    
    return {
        MainFrame = mainFrame,
        ToggleVisibility = function()
            mainFrame.Visible = not mainFrame.Visible
        end
    }
end

-- Initialize the module
UIComponents.MainUI = createMainUI()

-- Return the module
return UIComponents
