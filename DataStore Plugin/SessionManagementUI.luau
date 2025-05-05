--luau
-- DataStore Plugin/SessionManagementUI.luau

local SessionManager = require(script.Parent.SessionManager)

local SessionManagementUI = {}

function SessionManagementUI.createUI(parent)
    -- Create the main container
    local container = Instance.new("Frame")
    container.Name = "SessionManagementContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    container.BorderSizePixel = 0
    container.Visible = false
    container.Parent = parent
    
    -- Add rounded corners
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 8)
    cornerRadius.Parent = container
    
    -- Create header
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "HeaderFrame"
    headerFrame.Size = UDim2.new(1, 0, 0, 40)
    headerFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = container
    
    -- Add rounded corners to header
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = headerFrame
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Session Management"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = headerFrame
    
    -- Create main content layout
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -50)
    contentFrame.Position = UDim2.new(0, 10, 0, 45)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = container
    
    -- Create a tab bar for different views
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 35)
    tabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = contentFrame
    
    -- Add rounded corners to tab bar
    local tabBarCorner = Instance.new("UICorner")
    tabBarCorner.CornerRadius = UDim.new(0, 4)
    tabBarCorner.Parent = tabBar
    
    -- Create tab buttons
    local function createTabButton(name, selected)
        local button = Instance.new("TextButton")
        button.Name = name .. "Button"
        button.Size = UDim2.new(0, 120, 1, -6)
        button.Position = UDim2.new(0, 0, 0, 3)
        button.BackgroundColor3 = selected and Color3.fromRGB(60, 120, 180) or Color3.fromRGB(45, 45, 50)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.SourceSansSemibold
        button.TextSize = 14
        button.Text = name
        button.BorderSizePixel = 0
        button.Parent = tabBar
        
        -- Add rounded corners to button
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        return button
    end
    
    -- Create tab content containers
    local function createTabContent(name)
        local content = Instance.new("Frame")
        content.Name = name .. "Content"
        content.Size = UDim2.new(1, 0, 1, -40)
        content.Position = UDim2.new(0, 0, 0, 40)
        content.BackgroundTransparency = 1
        content.Visible = false
        content.Parent = contentFrame
        
        return content
    end
    
    -- Create tabs
    local activeSessionsButton = createTabButton("Active Sessions", true)
    local configurationButton = createTabButton("Configuration", false)
    local statisticsButton = createTabButton("Statistics", false)
    
    -- Position the buttons
    activeSessionsButton.Position = UDim2.new(0, 5, 0, 3)
    configurationButton.Position = UDim2.new(0, 130, 0, 3)
    statisticsButton.Position = UDim2.new(0, 255, 0, 3)
    
    -- Create content containers
    local activeSessionsContent = createTabContent("ActiveSessions")
    local configurationContent = createTabContent("Configuration")
    local statisticsContent = createTabContent("Statistics")
    
    -- Make the active sessions content visible by default
    activeSessionsContent.Visible = true
    
    -- Tab switching function
    local function switchTab(tabButton, tabContent)
        -- Reset all tabs
        activeSessionsButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        configurationButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        statisticsButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        
        activeSessionsContent.Visible = false
        configurationContent.Visible = false
        statisticsContent.Visible = false
        
        -- Activate selected tab
        tabButton.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
        tabContent.Visible = true
    end
    
    -- Connect tab buttons
    activeSessionsButton.MouseButton1Click:Connect(function()
        switchTab(activeSessionsButton, activeSessionsContent)
    end)
    
    configurationButton.MouseButton1Click:Connect(function()
        switchTab(configurationButton, configurationContent)
    end)
    
    statisticsButton.MouseButton1Click:Connect(function()
        switchTab(statisticsButton, statisticsContent)
    end)
    
    -- Create UI for Active Sessions tab
    local function createActiveSessionsUI()
        -- Create a refresh button
        local refreshButton = Instance.new("TextButton")
        refreshButton.Name = "RefreshButton"
        refreshButton.Size = UDim2.new(0, 100, 0, 30)
        refreshButton.Position = UDim2.new(1, -105, 0, 5)
        refreshButton.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
        refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        refreshButton.Font = Enum.Font.SourceSansSemibold
        refreshButton.TextSize = 14
        refreshButton.Text = "Refresh"
        refreshButton.BorderSizePixel = 0
        refreshButton.Parent = activeSessionsContent
        
        -- Add rounded corners to button
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = refreshButton
        
        -- Create a scrolling frame for the sessions list
        local sessionsListFrame = Instance.new("ScrollingFrame")
        sessionsListFrame.Name = "SessionsListFrame"
        sessionsListFrame.Size = UDim2.new(1, 0, 1, -45)
        sessionsListFrame.Position = UDim2.new(0, 0, 0, 40)
        sessionsListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        sessionsListFrame.BorderSizePixel = 0
        sessionsListFrame.ScrollBarThickness = 6
        sessionsListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        sessionsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        sessionsListFrame.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        sessionsListFrame.Parent = activeSessionsContent
        
        -- Add layout to the sessions list
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 5)
        listLayout.SortOrder = Enum.SortOrder.Name
        listLayout.Parent = sessionsListFrame
        
        -- Function to update the sessions list
        local function updateSessionsList()
            -- Clear existing entries
            for _, child in ipairs(sessionsListFrame:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            -- Get active locks
            local activeLocks = SessionManager.getActiveLocks()
            
            if #activeLocks == 0 then
                -- Create empty state message
                local emptyMessage = Instance.new("TextLabel")
                emptyMessage.Size = UDim2.new(1, -20, 0, 40)
                emptyMessage.Position = UDim2.new(0, 10, 0, 10)
                emptyMessage.BackgroundTransparency = 1
                emptyMessage.Text = "No active sessions"
                emptyMessage.TextColor3 = Color3.fromRGB(180, 180, 180)
                emptyMessage.Font = Enum.Font.SourceSans
                emptyMessage.TextSize = 16
                emptyMessage.TextXAlignment = Enum.TextXAlignment.Center
                emptyMessage.Parent = sessionsListFrame
                return
            end
            
            -- Add entries for each active lock
            for i, lockInfo in ipairs(activeLocks) do
                -- Create a frame for this lock
                local lockFrame = Instance.new("Frame")
                lockFrame.Name = "Lock_" .. i
                lockFrame.Size = UDim2.new(1, -10, 0, 80)
                lockFrame.BackgroundColor3 = lockInfo.isExpired and Color3.fromRGB(80, 40, 40) or Color3.fromRGB(40, 40, 45)
                lockFrame.BorderSizePixel = 0
                lockFrame.LayoutOrder = i
                lockFrame.Parent = sessionsListFrame
                
                -- Add rounded corners
                local frameCorner = Instance.new("UICorner")
                frameCorner.CornerRadius = UDim.new(0, 4)
                frameCorner.Parent = lockFrame
                
                -- DataStore and key name
                local dsLabel = Instance.new("TextLabel")
                dsLabel.Size = UDim2.new(1, -20, 0, 20)
                dsLabel.Position = UDim2.new(0, 10, 0, 5)
                dsLabel.BackgroundTransparency = 1
                dsLabel.Text = "DataStore: " .. lockInfo.dataStoreName
                dsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                dsLabel.Font = Enum.Font.SourceSansSemibold
                dsLabel.TextSize = 14
                dsLabel.TextXAlignment = Enum.TextXAlignment.Left
                dsLabel.Parent = lockFrame
                
                local keyLabel = Instance.new("TextLabel")
                keyLabel.Size = UDim2.new(1, -20, 0, 20)
                keyLabel.Position = UDim2.new(0, 10, 0, 25)
                keyLabel.BackgroundTransparency = 1
                keyLabel.Text = "Key: " .. lockInfo.keyName
                keyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                keyLabel.Font = Enum.Font.SourceSans
                keyLabel.TextSize = 14
                keyLabel.TextXAlignment = Enum.TextXAlignment.Left
                keyLabel.Parent = lockFrame
                
                -- Session ID and duration
                local sessionLabel = Instance.new("TextLabel")
                sessionLabel.Size = UDim2.new(1, -160, 0, 20)
                sessionLabel.Position = UDim2.new(0, 10, 0, 45)
                sessionLabel.BackgroundTransparency = 1
                sessionLabel.Text = "Session: " .. string.sub(lockInfo.sessionId, 1, 8) .. "..."
                sessionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                sessionLabel.Font = Enum.Font.SourceSans
                sessionLabel.TextSize = 14
                sessionLabel.TextXAlignment = Enum.TextXAlignment.Left
                sessionLabel.Parent = lockFrame
                
                local durationStr = "Unknown"
                if lockInfo.lockDuration then
                    if lockInfo.lockDuration < 60 then
                        durationStr = lockInfo.lockDuration .. " sec"
                    elseif lockInfo.lockDuration < 3600 then
                        durationStr = math.floor(lockInfo.lockDuration / 60) .. " min"
                    else
                        durationStr = math.floor(lockInfo.lockDuration / 3600) .. " hr " .. 
                                      math.floor((lockInfo.lockDuration % 3600) / 60) .. " min"
                    end
                end
                
                local durationLabel = Instance.new("TextLabel")
                durationLabel.Size = UDim2.new(0, 120, 0, 20)
                durationLabel.Position = UDim2.new(0.5, 0, 0, 45)
                durationLabel.BackgroundTransparency = 1
                durationLabel.Text = "Duration: " .. durationStr
                durationLabel.TextColor3 = lockInfo.isExpired and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(180, 180, 180)
                durationLabel.Font = Enum.Font.SourceSans
                durationLabel.TextSize = 14
                durationLabel.TextXAlignment = Enum.TextXAlignment.Left
                durationLabel.Parent = lockFrame
                
                -- Force release button
                local releaseButton = Instance.new("TextButton")
                releaseButton.Size = UDim2.new(0, 100, 0, 26)
                releaseButton.Position = UDim2.new(1, -110, 0, 10)
                releaseButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
                releaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                releaseButton.Font = Enum.Font.SourceSansSemibold
                releaseButton.TextSize = 14
                releaseButton.Text = "Release Lock"
                releaseButton.BorderSizePixel = 0
                releaseButton.Parent = lockFrame
                
                -- Add rounded corners to button
                local releaseButtonCorner = Instance.new("UICorner")
                releaseButtonCorner.CornerRadius = UDim.new(0, 4)
                releaseButtonCorner.Parent = releaseButton
                
                -- Connect force release button
                releaseButton.MouseButton1Click:Connect(function()
                    SessionManager.forceReleaseLock(lockInfo.dataStoreName, lockInfo.keyName)
                    task.wait(0.5) -- Brief delay to allow operation to complete
                    updateSessionsList() -- Refresh the list
                end)
                
                -- Status indicator
                local statusFrame = Instance.new("Frame")
                statusFrame.Size = UDim2.new(0, 8, 0, 80)
                statusFrame.Position = UDim2.new(0, 0, 0, 0)
                statusFrame.BackgroundColor3 = lockInfo.isExpired and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 180, 80)
                statusFrame.BorderSizePixel = 0
                statusFrame.Parent = lockFrame
                
                -- Add rounded corners to status bar
                local statusCorner = Instance.new("UICorner")
                statusCorner.CornerRadius = UDim.new(0, 4)
                statusCorner.Parent = statusFrame
            end
        end
        
        -- Connect refresh button
        refreshButton.MouseButton1Click:Connect(updateSessionsList)
        
        -- Initial update
        updateSessionsList()
        
        -- Auto refresh
        local function autoRefresh()
            while activeSessionsContent.Parent do
                if activeSessionsContent.Visible then
                    updateSessionsList()
                end
                task.wait(5) -- Refresh every 5 seconds when the tab is visible
            end
        end
        
        coroutine.wrap(autoRefresh)()
    end
    
    -- Create UI for Configuration tab
    local function createConfigurationUI()
        -- Create a scrolling frame for the configuration options
        local configScrollFrame = Instance.new("ScrollingFrame")
        configScrollFrame.Name = "ConfigScrollFrame"
        configScrollFrame.Size = UDim2.new(1, 0, 1, 0)
        configScrollFrame.BackgroundTransparency = 1
        configScrollFrame.ScrollBarThickness = 6
        configScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        configScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        configScrollFrame.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        configScrollFrame.Parent = configurationContent
        
        -- Add layout
        local configLayout = Instance.new("UIListLayout")
        configLayout.Padding = UDim.new(0, 15)
        configLayout.SortOrder = Enum.SortOrder.LayoutOrder
        configLayout.Parent = configScrollFrame
        
        -- Helper function to create a setting row
        local function createSettingRow(name, description, inputType, defaultValue, configKey, order)
            local row = Instance.new("Frame")
            row.Name = name .. "Setting"
            row.Size = UDim2.new(1, -20, 0, 80)
            row.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.Parent = configScrollFrame
            
            -- Add rounded corners
            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 4)
            rowCorner.Parent = row
            
            -- Setting title
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -20, 0, 24)
            titleLabel.Position = UDim2.new(0, 10, 0, 5)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = name
            titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            titleLabel.Font = Enum.Font.SourceSansBold
            titleLabel.TextSize = 16
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = row
            
            -- Description
            local descLabel = Instance.new("TextLabel")
            descLabel.Size = UDim2.new(1, -20, 0, 20)
            descLabel.Position = UDim2.new(0, 10, 0, 30)
            descLabel.BackgroundTransparency = 1
            descLabel.Text = description
            descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            descLabel.Font = Enum.Font.SourceSans
            descLabel.TextSize = 14
            descLabel.TextWrapped = true
            descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.Parent = row
            
            -- Input
            local input
            if inputType == "number" then
                input = Instance.new("TextBox")
                input.Size = UDim2.new(0, 100, 0, 30)
                input.Position = UDim2.new(1, -110, 0, 25)
                input.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                input.BorderColor3 = Color3.fromRGB(60, 60, 65)
                input.BorderSizePixel = 1
                input.TextColor3 = Color3.fromRGB(255, 255, 255)
                input.Font = Enum.Font.SourceSans
                input.TextSize = 14
                input.Text = tostring(SessionManager.config[configKey] or defaultValue)
                input.ClearTextOnFocus = false
                input.Parent = row
                
                -- Add validation for numbers only
                input.FocusLost:Connect(function(enterPressed)
                    local num = tonumber(input.Text)
                    if num then
                        local config = {}
                        config[configKey] = num
                        SessionManager.updateConfig(config)
                    else
                        input.Text = tostring(SessionManager.config[configKey])
                    end
                end)
            elseif inputType == "toggle" then
                input = Instance.new("Frame")
                input.Name = "ToggleFrame"
                input.Size = UDim2.new(0, 50, 0, 26)
                input.Position = UDim2.new(1, -60, 0, 27)
                input.BackgroundColor3 = (SessionManager.config[configKey] or defaultValue) and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(100, 100, 110)
                input.BorderSizePixel = 0
                input.Parent = row
                
                -- Add rounded corners to toggle
                local toggleCorner = Instance.new("UICorner")
                toggleCorner.CornerRadius = UDim.new(1, 0)
                toggleCorner.Parent = input
                
                -- Add toggle handle
                local handle = Instance.new("Frame")
                handle.Name = "Handle"
                handle.Size = UDim2.new(0, 20, 0, 20)
                handle.Position = UDim2.new((SessionManager.config[configKey] or defaultValue) and 0.6 or 0, 0, 0.5, -10)
                handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                handle.BorderSizePixel = 0
                handle.Parent = input
                
                -- Add rounded corners to handle
                local handleCorner = Instance.new("UICorner")
                handleCorner.CornerRadius = UDim.new(1, 0)
                handleCorner.Parent = handle
                
                -- Make the toggle clickable
                input.InputBegan:Connect(function(inputObj)
                    if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
                        local newValue = not (SessionManager.config[configKey] or defaultValue)
                        local config = {}
                        config[configKey] = newValue
                        SessionManager.updateConfig(config)
                        
                        -- Update the toggle appearance
                        input.BackgroundColor3 = newValue and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(100, 100, 110)
                        handle.Position = UDim2.new(newValue and 0.6 or 0, 0, 0.5, -10)
                    end
                end)
            end
            
            return row
        end
        
        -- Create settings
        createSettingRow("Lock Timeout", "Time in seconds before a lock expires (default: 600)", "number", 600, "lockTimeout", 1)
        createSettingRow("Monitor Interval", "How often to check for expired locks (seconds)", "number", 60, "monitorInterval", 2)
        createSettingRow("Auto-retry on Failure", "Automatically retry lock operations on failure", "toggle", true, "autoRetryOnFailure", 3)
        createSettingRow("Max Retry Attempts", "Maximum number of retry attempts for operations", "number", 3, "maxRetryAttempts", 4)
        createSettingRow("Retry Delay", "Delay in seconds between retry attempts", "number", 1, "retryDelaySeconds", 5)
        createSettingRow("Expired Lock Notifications", "Show notifications when locks expire", "toggle", true, "notifyOnExpiredLocks", 6)
        
        -- Save button
        local saveButton = Instance.new("TextButton")
        saveButton.Name = "SaveButton"
        saveButton.Size = UDim2.new(0, 120, 0, 40)
        saveButton.Position = UDim2.new(0.5, -60, 1, -50)
        saveButton.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
        saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        saveButton.Font = Enum.Font.SourceSansBold
        saveButton.TextSize = 16
        saveButton.Text = "Save Settings"
        saveButton.BorderSizePixel = 0
        saveButton.Parent = configurationContent
        
        -- Add rounded corners to button
        local saveButtonCorner = Instance.new("UICorner")
        saveButtonCorner.CornerRadius = UDim.new(0, 4)
        saveButtonCorner.Parent = saveButton
    end
    
    -- Create UI for Statistics tab
    local function createStatisticsUI()
        -- Create a scrolling frame for the stats
        local statsScrollFrame = Instance.new("ScrollingFrame")
        statsScrollFrame.Name = "StatsScrollFrame"
        statsScrollFrame.Size = UDim2.new(1, 0, 1, 0)
        statsScrollFrame.BackgroundTransparency = 1
        statsScrollFrame.ScrollBarThickness = 6
        statsScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        statsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        statsScrollFrame.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        statsScrollFrame.Parent = statisticsContent
        
        -- Add layout
        local statsLayout = Instance.new("UIListLayout")
        statsLayout.Padding = UDim.new(0, 10)
        statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        statsLayout.Parent = statsScrollFrame
        
        -- Helper function to create a stat card
        local function createStatCard(title, value, icon, color, order)
            local card = Instance.new("Frame")
            card.Name = title .. "Card"
            card.Size = UDim2.new(0.48, -10, 0, 100)
            card.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            card.BorderSizePixel = 0
            card.LayoutOrder = order
            card.Parent = statsScrollFrame
            
            -- Add rounded corners
            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 6)
            cardCorner.Parent = card
            
            -- Add title
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -20, 0, 30)
            titleLabel.Position = UDim2.new(0, 10, 0, 10)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = title
            titleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            titleLabel.Font = Enum.Font.SourceSans
            titleLabel.TextSize = 14
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = card
            
            -- Add value
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Name = "ValueLabel"
            valueLabel.Size = UDim2.new(1, -20, 0, 40)
            valueLabel.Position = UDim2.new(0, 10, 0, 40)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(value)
            valueLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
            valueLabel.Font = Enum.Font.SourceSansBold
            valueLabel.TextSize = 24
            valueLabel.TextXAlignment = Enum.TextXAlignment.Left
            valueLabel.Parent = card
            
            return card
        end
        
        -- Create stats row container
        local statsRow1 = Instance.new("Frame")
        statsRow1.Name = "StatsRow1"
        statsRow1.Size = UDim2.new(1, -20, 0, 100)
        statsRow1.BackgroundTransparency = 1
        statsRow1.LayoutOrder = 1
        statsRow1.Parent = statsScrollFrame
        
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.FillDirection = Enum.FillDirection.Horizontal
        rowLayout.Padding = UDim.new(0, 10)
        rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout.Parent = statsRow1
        
        -- Create stats row container 2
        local statsRow2 = Instance.new("Frame")
        statsRow2.Name = "StatsRow2"
        statsRow2.Size = UDim2.new(1, -20, 0, 100)
        statsRow2.BackgroundTransparency = 1
        statsRow2.LayoutOrder = 2
        statsRow2.Parent = statsScrollFrame
        
        local rowLayout2 = Instance.new("UIListLayout")
        rowLayout2.FillDirection = Enum.FillDirection.Horizontal
        rowLayout2.Padding = UDim.new(0, 10)
        rowLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rowLayout2.VerticalAlignment = Enum.VerticalAlignment.Center
        rowLayout2.Parent = statsRow2
        
        -- Create the stat cards
        local stats = SessionManager.getStats()
        
        local locksAcquiredCard = createStatCard("Locks Acquired", stats.totalLocksAcquired, nil, Color3.fromRGB(80, 200, 120))
        locksAcquiredCard.Parent = statsRow1
        
        local locksReleasedCard = createStatCard("Locks Released", stats.totalLocksReleased, nil, Color3.fromRGB(80, 160, 240))
        locksReleasedCard.Parent = statsRow1
        
        local locksFailedCard = createStatCard("Failed Lock Attempts", stats.totalLocksFailed, nil, Color3.fromRGB(240, 100, 100))
        locksFailedCard.Parent = statsRow2
        
        local forceReleasesCard = createStatCard("Force Releases", stats.totalForceReleases, nil, Color3.fromRGB(240, 160, 80))
        forceReleasesCard.Parent = statsRow2
        
        -- Add a section for active locks
        local activeLockSection = Instance.new("Frame")
        activeLockSection.Name = "ActiveLockSection"
        activeLockSection.Size = UDim2.new(1, -20, 0, 180)
        activeLockSection.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        activeLockSection.BorderSizePixel = 0
        activeLockSection.LayoutOrder = 3
        activeLockSection.Parent = statsScrollFrame
        
        -- Add rounded corners
        local sectionCorner = Instance.new("UICorner")
        sectionCorner.CornerRadius = UDim.new(0, 6)
        sectionCorner.Parent = activeLockSection
        
        -- Add title
        local sectionTitle = Instance.new("TextLabel")
        sectionTitle.Size = UDim2.new(1, -20, 0, 30)
        sectionTitle.Position = UDim2.new(0, 10, 0, 10)
        sectionTitle.BackgroundTransparency = 1
        sectionTitle.Text = "Active Locks Summary"
        sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        sectionTitle.Font = Enum.Font.SourceSansBold
        sectionTitle.TextSize = 18
        sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        sectionTitle.Parent = activeLockSection
        
        -- Add content
        local activeLocks = SessionManager.getActiveLocks()
        local totalLocks = #activeLocks
        local expiredLocks = 0
        
        for _, lock in ipairs(activeLocks) do
            if lock.isExpired then
                expiredLocks += 1
            end
        end
        
        local locksLabel = Instance.new("TextLabel")
        locksLabel.Size = UDim2.new(1, -20, 0, 24)
        locksLabel.Position = UDim2.new(0, 10, 0, 50)
        locksLabel.BackgroundTransparency = 1
        locksLabel.Text = "Total Active Locks: " .. totalLocks
        locksLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        locksLabel.Font = Enum.Font.SourceSans
        locksLabel.TextSize = 16
        locksLabel.TextXAlignment = Enum.TextXAlignment.Left
        locksLabel.Parent = activeLockSection
        
        local expiredLocksLabel = Instance.new("TextLabel")
        expiredLocksLabel.Size = UDim2.new(1, -20, 0, 24)
        expiredLocksLabel.Position = UDim2.new(0, 10, 0, 80)
        expiredLocksLabel.BackgroundTransparency = 1
        expiredLocksLabel.Text = "Expired Locks: " .. expiredLocks
        expiredLocksLabel.TextColor3 = expiredLocks > 0 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(220, 220, 220)
        expiredLocksLabel.Font = Enum.Font.SourceSans
        expiredLocksLabel.TextSize = 16
        expiredLocksLabel.TextXAlignment = Enum.TextXAlignment.Left
        expiredLocksLabel.Parent = activeLockSection
        
        -- Add average lock duration
        local avgDuration = "N/A"
        if stats.averageLockDuration then
            if stats.averageLockDuration < 60 then
                avgDuration = math.floor(stats.averageLockDuration) .. " seconds"
            elseif stats.averageLockDuration < 3600 then
                avgDuration = math.floor(stats.averageLockDuration / 60) .. " minutes"
            else
                avgDuration = math.floor(stats.averageLockDuration / 3600) .. " hours"
            end
        end
        
        local avgDurationLabel = Instance.new("TextLabel")
        avgDurationLabel.Size = UDim2.new(1, -20, 0, 24)
        avgDurationLabel.Position = UDim2.new(0, 10, 0, 110)
        avgDurationLabel.BackgroundTransparency = 1
        avgDurationLabel.Text = "Average Lock Duration: " .. avgDuration
        avgDurationLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        avgDurationLabel.Font = Enum.Font.SourceSans
        avgDurationLabel.TextSize = 16
        avgDurationLabel.TextXAlignment = Enum.TextXAlignment.Left
        avgDurationLabel.Parent = activeLockSection
        
        -- Add reset stats button
        local resetButton = Instance.new("TextButton")
        resetButton.Name = "ResetButton"
        resetButton.Size = UDim2.new(0, 120, 0, 36)
        resetButton.Position = UDim2.new(0.5, -60, 0, 140)
        resetButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        resetButton.Font = Enum.Font.SourceSansSemibold
        resetButton.TextSize = 16
        resetButton.Text = "Reset Stats"
        resetButton.BorderSizePixel = 0
        resetButton.Parent = activeLockSection
        
        -- Add rounded corners to button
        local resetButtonCorner = Instance.new("UICorner")
        resetButtonCorner.CornerRadius = UDim.new(0, 4)
        resetButtonCorner.Parent = resetButton
        
        -- Connect reset button
        resetButton.MouseButton1Click:Connect(function()
            SessionManager.resetStats()
            -- Update the stats display
            locksAcquiredCard.ValueLabel.Text = "0"
            locksReleasedCard.ValueLabel.Text = "0"
            locksFailedCard.ValueLabel.Text = "0"
            forceReleasesCard.ValueLabel.Text = "0"
            avgDurationLabel.Text = "Average Lock Duration: N/A"
        end)
        
        -- Create a refresh button
        local refreshButton = Instance.new("TextButton")
        refreshButton.Name = "RefreshButton"
        refreshButton.Size = UDim2.new(0, 100, 0, 30)
        refreshButton.Position = UDim2.new(1, -110, 0, 10)
        refreshButton.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
        refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        refreshButton.Font = Enum.Font.SourceSansSemibold
        refreshButton.TextSize = 14
        refreshButton.Text = "Refresh"
        refreshButton.BorderSizePixel = 0
        refreshButton.Parent = statisticsContent
        
        -- Add rounded corners to button
        local refreshButtonCorner = Instance.new("UICorner")
        refreshButtonCorner.CornerRadius = UDim.new(0, 4)
        refreshButtonCorner.Parent = refreshButton
        
        -- Function to update the statistics display
        local function updateStats()
            local stats = SessionManager.getStats()
            locksAcquiredCard.ValueLabel.Text = tostring(stats.totalLocksAcquired)
            locksReleasedCard.ValueLabel.Text = tostring(stats.totalLocksReleased)
            locksFailedCard.ValueLabel.Text = tostring(stats.totalLocksFailed)
            forceReleasesCard.ValueLabel.Text = tostring(stats.totalForceReleases)
            
            local activeLocks = SessionManager.getActiveLocks()
            local totalLocks = #activeLocks
            local expiredLocks = 0
            
            for _, lock in ipairs(activeLocks) do
                if lock.isExpired then
                    expiredLocks += 1
                end
            end
            
            locksLabel.Text = "Total Active Locks: " .. totalLocks
            expiredLocksLabel.Text = "Expired Locks: " .. expiredLocks
            expiredLocksLabel.TextColor3 = expiredLocks > 0 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(220, 220, 220)
            
            -- Update average lock duration
            local avgDuration = "N/A"
            if stats.averageLockDuration then
                if stats.averageLockDuration < 60 then
                    avgDuration = math.floor(stats.averageLockDuration) .. " seconds"
                elseif stats.averageLockDuration < 3600 then
                    avgDuration = math.floor(stats.averageLockDuration / 60) .. " minutes"
                else
                    avgDuration = math.floor(stats.averageLockDuration / 3600) .. " hours"
                end
            end
            
            avgDurationLabel.Text = "Average Lock Duration: " .. avgDuration
        end
        
        -- Connect refresh button
        refreshButton.MouseButton1Click:Connect(updateStats)
        
        -- Set up auto-refresh for statistics
        local function autoRefresh()
            while statisticsContent.Parent do
                if statisticsContent.Visible then
                    updateStats()
                end
                task.wait(5) -- Refresh every 5 seconds when the tab is visible
            end
        end
        
        coroutine.wrap(autoRefresh)()
    end
    
    -- Initialize the tab UIs
    createActiveSessionsUI()
    createConfigurationUI()
    createStatisticsUI()
    
    return container
end

return SessionManagementUI
