--!strict
--[[
    DataMigrationUI.luau
    
    UI component for the DataMigrationTools module.
    Provides interface for managing data migrations between DataStores,
    viewing migration status, and handling backups.
    
    Author: GitHub Copilot
    Created: May 2023
]]

local HttpService = game:GetService("HttpService")

local DataMigrationTools = require(script.Parent.DataMigrationTools)
local DataStoreManager = require(script.Parent.DataStoreManager)
local DataVisualization = require(script.Parent.DataVisualization)

local DataMigrationUI = {}

-- Create the Data Migration UI tab
function DataMigrationUI.createTab(parent)
    -- Main container for the Data Migration UI
    local container = Instance.new("Frame")
    container.Name = "DataMigrationContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Visible = false
    container.Parent = parent
    
    -- Create header section
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "HeaderFrame"
    headerFrame.Size = UDim2.new(1, 0, 0, 42)
    headerFrame.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = container
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "Data Migration Tools"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = headerFrame
    
    -- Create content section
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -50)
    contentFrame.Position = UDim2.new(0, 0, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = container
    
    -- Create tabs for different sections
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(1, 0, 0, 26)
    tabsFrame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
    tabsFrame.BorderSizePixel = 0
    tabsFrame.Parent = contentFrame
    
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.Padding = UDim.new(0, 1)
    tabsLayout.Parent = tabsFrame
    
    -- Create tab content container
    local tabContentsFrame = Instance.new("Frame")
    tabContentsFrame.Name = "TabContentsFrame"
    tabContentsFrame.Size = UDim2.new(1, 0, 1, -30)
    tabContentsFrame.Position = UDim2.new(0, 0, 0, 30)
    tabContentsFrame.BackgroundTransparency = 1
    tabContentsFrame.Parent = contentFrame
    
    -- Helper function to create a tab button
    local function createTabButton(name, selected)
        local tab = Instance.new("TextButton")
        tab.Name = name .. "Tab"
        tab.Size = UDim2.new(0, 120, 1, 0)
        tab.BackgroundColor3 = selected and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(46, 46, 46)
        tab.BorderSizePixel = 0
        tab.Text = name
        tab.Font = Enum.Font.SourceSans
        tab.TextSize = 14
        tab.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        tab.Parent = tabsFrame
        return tab
    end
    
    -- Helper function to create a tab content container
    local function createTabContent(name)
        local content = Instance.new("ScrollingFrame")
        content.Name = name .. "Content"
        content.Size = UDim2.new(1, 0, 1, 0)
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.ScrollBarThickness = 6
        content.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.Visible = false
        content.Parent = tabContentsFrame
        return content
    end
    
    -- Create tabs and their content
    local migrateTab = createTabButton("Migrate", true)
    local statusTab = createTabButton("Status", false)
    local backupsTab = createTabButton("Backups", false)
    local settingsTab = createTabButton("Settings", false)
    
    local migrateContent = createTabContent("Migrate")
    local statusContent = createTabContent("Status")
    local backupsContent = createTabContent("Backups")
    local settingsContent = createTabContent("Settings")
    
    -- Make first tab visible
    migrateContent.Visible = true
    
    -- Set up tab switching
    local function switchTab(tabName)
        -- Update tab button appearance
        migrateTab.BackgroundColor3 = tabName == "Migrate" and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(46, 46, 46)
        migrateTab.TextColor3 = tabName == "Migrate" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        
        statusTab.BackgroundColor3 = tabName == "Status" and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(46, 46, 46)
        statusTab.TextColor3 = tabName == "Status" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        
        backupsTab.BackgroundColor3 = tabName == "Backups" and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(46, 46, 46)
        backupsTab.TextColor3 = tabName == "Backups" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        
        settingsTab.BackgroundColor3 = tabName == "Settings" and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(46, 46, 46)
        settingsTab.TextColor3 = tabName == "Settings" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        
        -- Show selected content
        migrateContent.Visible = tabName == "Migrate"
        statusContent.Visible = tabName == "Status"
        backupsContent.Visible = tabName == "Backups"
        settingsContent.Visible = tabName == "Settings"
        
        -- Refresh content if needed
        if tabName == "Status" then
            DataMigrationUI.refreshStatusTab(statusContent)
        elseif tabName == "Backups" then
            DataMigrationUI.refreshBackupsTab(backupsContent)
        end
    end
    
    -- Connect tab buttons
    migrateTab.MouseButton1Click:Connect(function() switchTab("Migrate") end)
    statusTab.MouseButton1Click:Connect(function() switchTab("Status") end)
    backupsTab.MouseButton1Click:Connect(function() switchTab("Backups") end)
    settingsTab.MouseButton1Click:Connect(function() switchTab("Settings") end)
    
    -- Populate the tabs with content
    DataMigrationUI.populateMigrateTab(migrateContent)
    DataMigrationUI.populateStatusTab(statusContent)
    DataMigrationUI.populateBackupsTab(backupsContent)
    DataMigrationUI.populateSettingsTab(settingsContent)
    
    -- Return the container
    return container
end

-- Helper function to create a section header
local function createSectionHeader(parent, text, positionY)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -20, 0, 24)
    header.Position = UDim2.new(0, 10, 0, positionY)
    header.BackgroundTransparency = 0.9
    header.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    header.BorderSizePixel = 0
    header.Text = text
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextSize = 14
    header.Font = Enum.Font.SourceSansBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = parent
    
    -- Add some padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 5)
    padding.Parent = header
    
    return header
end

-- Helper function to create a labeled input field
local function createLabeledInput(parent, labelText, positionY, defaultText)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 24)
    container.Position = UDim2.new(0, 10, 0, positionY)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.7, 0, 1, 0)
    input.Position = UDim2.new(0.3, 0, 0, 0)
    input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    input.BorderColor3 = Color3.fromRGB(60, 60, 60)
    input.Text = defaultText or ""
    input.PlaceholderText = "Enter " .. string.lower(labelText)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.TextSize = 14
    input.Font = Enum.Font.SourceSans
    input.ClearTextOnFocus = false
    input.Parent = container
    
    return container, input
end

-- Helper function to create a button
local function createButton(parent, text, positionY, positionX, width, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, width or 100, 0, 30)
    button.Position = UDim2.new(positionX or 0, 10, 0, positionY)
    button.BackgroundColor3 = color or Color3.fromRGB(60, 120, 200)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.SourceSansBold
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    return button
end

-- Helper function to create a status message
local function createStatusMessage(parent, message, color, positionY)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 30)
    statusLabel.Position = UDim2.new(0, 10, 0, positionY)
    statusLabel.BackgroundTransparency = 0.8
    statusLabel.BackgroundColor3 = color or Color3.fromRGB(60, 60, 60)
    statusLabel.BorderSizePixel = 0
    statusLabel.Text = message
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextWrapped = true
    statusLabel.Visible = false
    statusLabel.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = statusLabel
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = statusLabel
    
    return statusLabel
end

-- Populate the migrate tab with content
function DataMigrationUI.populateMigrateTab(parent)
    -- Create migrate single key section
    local singleKeyHeader = createSectionHeader(parent, "Migrate Single Key", 10)
    
    -- Create source DataStore input
    local sourceStoreContainer, sourceStoreInput = createLabeledInput(
        parent, "Source DataStore:", 44, ""
    )
    
    -- Create destination DataStore input
    local destStoreContainer, destStoreInput = createLabeledInput(
        parent, "Destination DataStore:", 78, ""
    )
    
    -- Create key name input
    local keyNameContainer, keyNameInput = createLabeledInput(
        parent, "Key Name:", 112, ""
    )
    
    -- Create migrate button
    local migrateButton = createButton(
        parent, "Migrate Key", 146, 0, 120, Color3.fromRGB(76, 175, 80)
    )
    
    -- Create status message
    local singleKeyStatus = createStatusMessage(
        parent, "Migration started!", Color3.fromRGB(76, 175, 80), 186
    )
    
    -- Create DataStore migration section
    local dataStoreMigrationHeader = createSectionHeader(parent, "Migrate Entire DataStore", 230)
    
    -- Create source DataStore input
    local batchSourceContainer, batchSourceInput = createLabeledInput(
        parent, "Source DataStore:", 264, ""
    )
    
    -- Create destination DataStore input
    local batchDestContainer, batchDestInput = createLabeledInput(
        parent, "Destination DataStore:", 298, ""
    )
    
    -- Create batch size input
    local batchSizeContainer, batchSizeInput = createLabeledInput(
        parent, "Batch Size:", 332, "10"
    )
    
    -- Create migrate button
    local migrateBatchButton = createButton(
        parent, "Migrate DataStore", 366, 0, 150, Color3.fromRGB(76, 175, 80)
    )
    
    -- Create status message
    local batchStatus = createStatusMessage(
        parent, "DataStore migration started!", Color3.fromRGB(76, 175, 80), 406
    )
    
    -- Handle migrate single key button click
    migrateButton.MouseButton1Click:Connect(function()
        local sourceStore = sourceStoreInput.Text
        local destStore = destStoreInput.Text
        local keyName = keyNameInput.Text
        
        if sourceStore == "" or destStore == "" or keyName == "" then
            singleKeyStatus.Text = "Please fill in all fields"
            singleKeyStatus.BackgroundColor3 = Color3.fromRGB(239, 83, 80)
            singleKeyStatus.Visible = true
            return
        end
        
        -- Start the migration
        local success, result, migrationId = DataMigrationTools:migrateKey(sourceStore, destStore, keyName)
        
        if success then
            singleKeyStatus.Text = "Migration started! ID: " .. migrationId
            singleKeyStatus.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        else
            singleKeyStatus.Text = "Migration failed: " .. tostring(result)
            singleKeyStatus.BackgroundColor3 = Color3.fromRGB(239, 83, 80)
        end
        
        singleKeyStatus.Visible = true
        
        -- Hide the status after 5 seconds
        task.delay(5, function()
            singleKeyStatus.Visible = false
        end)
    end)
    
    -- Handle migrate DataStore button click
    migrateBatchButton.MouseButton1Click:Connect(function()
        local sourceStore = batchSourceInput.Text
        local destStore = batchDestInput.Text
        local batchSize = tonumber(batchSizeInput.Text) or 10
        
        if sourceStore == "" or destStore == "" then
            batchStatus.Text = "Please fill in the DataStore fields"
            batchStatus.BackgroundColor3 = Color3.fromRGB(239, 83, 80)
            batchStatus.Visible = true
            return
        end
        
        -- Start the migration
        local success, result, migrationId = DataMigrationTools:migrateDataStore(sourceStore, destStore, {
            batchSize = batchSize
        })
        
        if success then
            batchStatus.Text = "DataStore migration started! ID: " .. migrationId
            batchStatus.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        else
            batchStatus.Text = "DataStore migration failed: " .. tostring(result)
            batchStatus.BackgroundColor3 = Color3.fromRGB(239, 83, 80)
        end
        
        batchStatus.Visible = true
        
        -- Hide the status after 5 seconds
        task.delay(5, function()
            batchStatus.Visible = false
        end)
    end)
end

-- Populate the status tab with content
function DataMigrationUI.populateStatusTab(parent)
    -- Create active migrations section
    local activeMigrationsHeader = createSectionHeader(parent, "Active Migrations", 10)
    
    -- Create container for active migrations
    local activeMigrationsContainer = Instance.new("Frame")
    activeMigrationsContainer.Name = "ActiveMigrationsContainer"
    activeMigrationsContainer.Size = UDim2.new(1, -20, 0, 150)
    activeMigrationsContainer.Position = UDim2.new(0, 10, 0, 44)
    activeMigrationsContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    activeMigrationsContainer.BorderSizePixel = 0
    activeMigrationsContainer.Parent = parent
    
    -- Create layout for active migrations
    local activeLayout = Instance.new("UIListLayout")
    activeLayout.Padding = UDim.new(0, 5)
    activeLayout.Parent = activeMigrationsContainer
    
    -- Create completed migrations section
    local completedMigrationsHeader = createSectionHeader(parent, "Completed Migrations", 204)
    
    -- Create container for completed migrations
    local completedMigrationsContainer = Instance.new("Frame")
    completedMigrationsContainer.Name = "CompletedMigrationsContainer"
    completedMigrationsContainer.Size = UDim2.new(1, -20, 0, 150)
    completedMigrationsContainer.Position = UDim2.new(0, 10, 0, 238)
    completedMigrationsContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    completedMigrationsContainer.BorderSizePixel = 0
    completedMigrationsContainer.Parent = parent
    
    -- Create layout for completed migrations
    local completedLayout = Instance.new("UIListLayout")
    completedLayout.Padding = UDim.new(0, 5)
    completedLayout.Parent = completedMigrationsContainer
    
    -- Create refresh button
    local refreshButton = createButton(
        parent, "Refresh", 400, 0, 120, Color3.fromRGB(66, 134, 244)
    )
    
    -- Handle refresh button click
    refreshButton.MouseButton1Click:Connect(function()
        DataMigrationUI.refreshStatusTab(parent)
    end)
    
    -- Initial refresh
    DataMigrationUI.refreshStatusTab(parent)
end

-- Refresh the status tab with current migration data
function DataMigrationUI.refreshStatusTab(parent)
    -- Get the containers
    local activeMigrationsContainer = parent:FindFirstChild("ActiveMigrationsContainer")
    local completedMigrationsContainer = parent:FindFirstChild("CompletedMigrationsContainer")
    
    if not activeMigrationsContainer or not completedMigrationsContainer then
        return
    end
    
    -- Clear existing items
    for _, child in ipairs(activeMigrationsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for _, child in ipairs(completedMigrationsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get all migrations
    local migrations = DataMigrationTools:getAllMigrations()
    
    -- Helper function to create a migration item
    local function createMigrationItem(migration, container)
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, 0, 0, 60)
        item.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        item.BorderSizePixel = 0
        item.Parent = container
        
        -- Add migration ID
        local idLabel = Instance.new("TextLabel")
        idLabel.Size = UDim2.new(1, -20, 0, 18)
        idLabel.Position = UDim2.new(0, 10, 0, 5)
        idLabel.BackgroundTransparency = 1
        idLabel.Text = "ID: " .. migration.migrationId
        idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        idLabel.TextSize = 12
        idLabel.Font = Enum.Font.SourceSans
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.TextTruncate = Enum.TextTruncate.AtEnd
        idLabel.Parent = item
        
        -- Add source and destination
        local sourceDestLabel = Instance.new("TextLabel")
        sourceDestLabel.Size = UDim2.new(1, -20, 0, 18)
        sourceDestLabel.Position = UDim2.new(0, 10, 0, 23)
        sourceDestLabel.BackgroundTransparency = 1
        sourceDestLabel.Text = migration.sourceStore .. " → " .. migration.destStore
        sourceDestLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        sourceDestLabel.TextSize = 14
        sourceDestLabel.Font = Enum.Font.SourceSansBold
        sourceDestLabel.TextXAlignment = Enum.TextXAlignment.Left
        sourceDestLabel.Parent = item
        
        -- Add status
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.new(0.7, -20, 0, 18)
        statusLabel.Position = UDim2.new(0, 10, 0, 41)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "Status: " .. migration.status
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusLabel.TextSize = 12
        statusLabel.Font = Enum.Font.SourceSans
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.Parent = item
        
        -- Add progress bar for active migrations
        if migration.inProgress then
            local progressBar = Instance.new("Frame")
            progressBar.Size = UDim2.new(0.3, -20, 0, 10)
            progressBar.Position = UDim2.new(0.7, 10, 0, 45)
            progressBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            progressBar.BorderSizePixel = 0
            progressBar.Parent = item
            
            local progressFill = Instance.new("Frame")
            progressFill.Size = UDim2.new(migration.progress / 100, 0, 1, 0)
            progressFill.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
            progressFill.BorderSizePixel = 0
            progressFill.Parent = progressBar
            
            -- Add percentage
            local percentLabel = Instance.new("TextLabel")
            percentLabel.Size = UDim2.new(0, 40, 0, 18)
            percentLabel.Position = UDim2.new(1, 5, 0, -4)
            percentLabel.BackgroundTransparency = 1
            percentLabel.Text = migration.progress .. "%"
            percentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            percentLabel.TextSize = 12
            percentLabel.Font = Enum.Font.SourceSans
            percentLabel.Parent = progressBar
        else
            -- Add completion time for completed migrations
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Size = UDim2.new(0.3, -10, 0, 18)
            timeLabel.Position = UDim2.new(0.7, 0, 0, 41)
            timeLabel.BackgroundTransparency = 1
            
            if migration.status == "completed" then
                timeLabel.Text = os.date("%H:%M:%S", migration.completionTime)
                timeLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
            elseif migration.status == "failed" then
                timeLabel.Text = "Failed"
                timeLabel.TextColor3 = Color3.fromRGB(239, 83, 80)
            else
                timeLabel.Text = os.date("%H:%M:%S", migration.completionTime)
                timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
            
            timeLabel.TextSize = 12
            timeLabel.Font = Enum.Font.SourceSans
            timeLabel.TextXAlignment = Enum.TextXAlignment.Right
            timeLabel.Parent = item
        end
        
        return item
    end
    
    -- Add active migrations
    local activeCount = 0
    for _, migration in pairs(migrations) do
        if migration.inProgress then
            createMigrationItem(migration, activeMigrationsContainer)
            activeCount = activeCount + 1
        end
    end
    
    -- Add "no active migrations" message if needed
    if activeCount == 0 then
        local noActiveLabel = Instance.new("TextLabel")
        noActiveLabel.Size = UDim2.new(1, 0, 0, 30)
        noActiveLabel.BackgroundTransparency = 1
        noActiveLabel.Text = "No active migrations"
        noActiveLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noActiveLabel.TextSize = 14
        noActiveLabel.Font = Enum.Font.SourceSans
        noActiveLabel.Parent = activeMigrationsContainer
    end
    
    -- Add completed migrations
    local completedCount = 0
    for _, migration in pairs(migrations) do
        if not migration.inProgress and (migration.status == "completed" or migration.status == "failed") then
            createMigrationItem(migration, completedMigrationsContainer)
            completedCount = completedCount + 1
            
            -- Limit to the last 5 completed migrations
            if completedCount >= 5 then break end
        end
    end
    
    -- Add "no completed migrations" message if needed
    if completedCount == 0 then
        local noCompletedLabel = Instance.new("TextLabel")
        noCompletedLabel.Size = UDim2.new(1, 0, 0, 30)
        noCompletedLabel.BackgroundTransparency = 1
        noCompletedLabel.Text = "No completed migrations"
        noCompletedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noCompletedLabel.TextSize = 14
        noCompletedLabel.Font = Enum.Font.SourceSans
        noCompletedLabel.Parent = completedMigrationsContainer
    end
end

-- Populate the backups tab with content
function DataMigrationUI.populateBackupsTab(parent)
    -- Create backups list section
    local backupsHeader = createSectionHeader(parent, "Data Backups", 10)
    
    -- Create container for backups
    local backupsContainer = Instance.new("Frame")
    backupsContainer.Name = "BackupsContainer"
    backupsContainer.Size = UDim2.new(1, -20, 0, 300)
    backupsContainer.Position = UDim2.new(0, 10, 0, 44)
    backupsContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    backupsContainer.BorderSizePixel = 0
    backupsContainer.Parent = parent
    
    -- Create layout for backups
    local backupsLayout = Instance.new("UIListLayout")
    backupsLayout.Padding = UDim.new(0, 5)
    backupsLayout.Parent = backupsContainer
    
    -- Create filter section
    local filterHeader = createSectionHeader(parent, "Filter Backups", 354)
    
    -- Create DataStore filter input
    local dataStoreFilterContainer, dataStoreFilterInput = createLabeledInput(
        parent, "DataStore:", 388, ""
    )
    
    -- Create key filter input
    local keyFilterContainer, keyFilterInput = createLabeledInput(
        parent, "Key Name:", 422, ""
    )
    
    -- Create filter button
    local filterButton = createButton(
        parent, "Apply Filter", 456, 0, 120, Color3.fromRGB(66, 134, 244)
    )
    
    -- Create refresh button
    local refreshButton = createButton(
        parent, "Refresh", 456, 0.3, 120, Color3.fromRGB(76, 175, 80)
    )
    
    -- Create clear all button
    local clearButton = createButton(
        parent, "Clear All", 456, 0.6, 120, Color3.fromRGB(239, 83, 80)
    )
    
    -- Handle filter button click
    filterButton.MouseButton1Click:Connect(function()
        DataMigrationUI.refreshBackupsTab(parent, dataStoreFilterInput.Text, keyFilterInput.Text)
    end)
    
    -- Handle refresh button click
    refreshButton.MouseButton1Click:Connect(function()
        DataMigrationUI.refreshBackupsTab(parent, dataStoreFilterInput.Text, keyFilterInput.Text)
    end)
    
    -- Handle clear all button click
    clearButton.MouseButton1Click:Connect(function()
        -- Show confirmation dialog
        local mainFrame = parent.Parent.Parent.Parent
        
        local confirmDialog = Instance.new("Frame")
        confirmDialog.Size = UDim2.new(0, 300, 0, 150)
        confirmDialog.Position = UDim2.new(0.5, -150, 0.5, -75)
        confirmDialog.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        confirmDialog.BorderSizePixel = 0
        confirmDialog.ZIndex = 10
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = confirmDialog
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundTransparency = 1
        title.Text = "Confirm Delete All Backups"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 16
        title.Font = Enum.Font.SourceSansBold
        title.ZIndex = 11
        title.Parent = confirmDialog
        
        local message = Instance.new("TextLabel")
        message.Size = UDim2.new(1, -40, 0, 40)
        message.Position = UDim2.new(0, 20, 0, 40)
        message.BackgroundTransparency = 1
        message.Text = "Are you sure you want to delete all backups? This action cannot be undone."
        message.TextColor3 = Color3.fromRGB(200, 200, 200)
        message.TextSize = 14
        message.Font = Enum.Font.SourceSans
        message.TextWrapped = true
        message.ZIndex = 11
        message.Parent = confirmDialog
        
        local cancelButton = Instance.new("TextButton")
        cancelButton.Size = UDim2.new(0, 120, 0, 30)
        cancelButton.Position = UDim2.new(0, 30, 1, -50)
        cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        cancelButton.Text = "Cancel"
        cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        cancelButton.TextSize = 14
        cancelButton.Font = Enum.Font.SourceSansBold
        cancelButton.ZIndex = 11
        cancelButton.Parent = confirmDialog
        
        local cancelCorner = Instance.new("UICorner")
        cancelCorner.CornerRadius = UDim.new(0, 4)
        cancelCorner.Parent = cancelButton
        
        local confirmDeleteButton = Instance.new("TextButton")
        confirmDeleteButton.Size = UDim2.new(0, 120, 0, 30)
        confirmDeleteButton.Position = UDim2.new(1, -150, 1, -50)
        confirmDeleteButton.BackgroundColor3 = Color3.fromRGB(239, 83, 80)
        confirmDeleteButton.Text = "Delete All"
        confirmDeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        confirmDeleteButton.TextSize = 14
        confirmDeleteButton.Font = Enum.Font.SourceSansBold
        confirmDeleteButton.ZIndex = 11
        confirmDeleteButton.Parent = confirmDialog
        
        local confirmCorner = Instance.new("UICorner")
        confirmCorner.CornerRadius = UDim.new(0, 4)
        confirmCorner.Parent = confirmDeleteButton
        
        -- Dim background
        local dimBackground = Instance.new("Frame")
        dimBackground.Size = UDim2.new(1, 0, 1, 0)
        dimBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        dimBackground.BackgroundTransparency = 0.7
        dimBackground.ZIndex = 9
        
        dimBackground.Parent = mainFrame
        confirmDialog.Parent = mainFrame
        
        -- Handle button clicks
        cancelButton.MouseButton1Click:Connect(function()
            dimBackground:Destroy()
            confirmDialog:Destroy()
        end)
        
        confirmDeleteButton.MouseButton1Click:Connect(function()
            -- Clear all backups
            DataMigrationTools:cleanupOldBackups(0)
            
            -- Refresh the backups tab
            DataMigrationUI.refreshBackupsTab(parent)
            
            -- Close the dialog
            dimBackground:Destroy()
            confirmDialog:Destroy()
        end)
    end)
    
    -- Initial refresh
    DataMigrationUI.refreshBackupsTab(parent)
end

-- Refresh the backups tab with current backup data
function DataMigrationUI.refreshBackupsTab(parent, dataStoreFilter, keyFilter)
    -- Get the container
    local backupsContainer = parent:FindFirstChild("BackupsContainer")
    
    if not backupsContainer then
        return
    end
    
    -- Clear existing items
    for _, child in ipairs(backupsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get all backups
    local backups = DataMigrationTools:getBackups(dataStoreFilter, keyFilter)
    
    -- Helper function to create a backup item
    local function createBackupItem(backup, container)
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, 0, 0, 80)
        item.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        item.BorderSizePixel = 0
        item.Parent = container
        
        -- Add backup ID
        local idLabel = Instance.new("TextLabel")
        idLabel.Size = UDim2.new(1, -20, 0, 18)
        idLabel.Position = UDim2.new(0, 10, 0, 5)
        idLabel.BackgroundTransparency = 1
        idLabel.Text = "ID: " .. backup.id
        idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        idLabel.TextSize = 12
        idLabel.Font = Enum.Font.SourceSans
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.TextTruncate = Enum.TextTruncate.AtEnd
        idLabel.Parent = item
        
        -- Add DataStore and key
        local dataStoreLabel = Instance.new("TextLabel")
        dataStoreLabel.Size = UDim2.new(1, -20, 0, 18)
        dataStoreLabel.Position = UDim2.new(0, 10, 0, 23)
        dataStoreLabel.BackgroundTransparency = 1
        dataStoreLabel.Text = "DataStore: " .. backup.dataStoreName
        dataStoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        dataStoreLabel.TextSize = 14
        dataStoreLabel.Font = Enum.Font.SourceSansBold
        dataStoreLabel.TextXAlignment = Enum.TextXAlignment.Left
        dataStoreLabel.Parent = item
        
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Size = UDim2.new(1, -20, 0, 18)
        keyLabel.Position = UDim2.new(0, 10, 0, 41)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = "Key: " .. backup.keyName
        keyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        keyLabel.TextSize = 12
        keyLabel.Font = Enum.Font.SourceSans
        keyLabel.TextXAlignment = Enum.TextXAlignment.Left
        keyLabel.Parent = item
        
        -- Add timestamp and size
        local timestampLabel = Instance.new("TextLabel")
        timestampLabel.Size = UDim2.new(0.5, -20, 0, 18)
        timestampLabel.Position = UDim2.new(0, 10, 0, 59)
        timestampLabel.BackgroundTransparency = 1
        timestampLabel.Text = "Created: " .. os.date("%Y-%m-%d %H:%M:%S", backup.timestamp)
        timestampLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        timestampLabel.TextSize = 12
        timestampLabel.Font = Enum.Font.SourceSans
        timestampLabel.TextXAlignment = Enum.TextXAlignment.Left
        timestampLabel.Parent = item
        
        local sizeLabel = Instance.new("TextLabel")
        sizeLabel.Size = UDim2.new(0.5, -20, 0, 18)
        sizeLabel.Position = UDim2.new(0.5, 10, 0, 59)
        sizeLabel.BackgroundTransparency = 1
        sizeLabel.Text = "Size: " .. string.format("%.2f KB", backup.size / 1024)
        sizeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        sizeLabel.TextSize = 12
        sizeLabel.Font = Enum.Font.SourceSans
        sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
        sizeLabel.Parent = item
        
        -- Add restore button
        local restoreButton = Instance.new("TextButton")
        restoreButton.Size = UDim2.new(0, 80, 0, 24)
        restoreButton.Position = UDim2.new(1, -90, 0, 5)
        restoreButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        restoreButton.Text = "Restore"
        restoreButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        restoreButton.TextSize = 12
        restoreButton.Font = Enum.Font.SourceSansBold
        restoreButton.Parent = item
        
        local restoreCorner = Instance.new("UICorner")
        restoreCorner.CornerRadius = UDim.new(0, 4)
        restoreCorner.Parent = restoreButton
        
        -- Add delete button
        local deleteButton = Instance.new("TextButton")
        deleteButton.Size = UDim2.new(0, 80, 0, 24)
        deleteButton.Position = UDim2.new(1, -90, 0, 34)
        deleteButton.BackgroundColor3 = Color3.fromRGB(239, 83, 80)
        deleteButton.Text = "Delete"
        deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteButton.TextSize = 12
        deleteButton.Font = Enum.Font.SourceSansBold
        deleteButton.Parent = item
        
        local deleteCorner = Instance.new("UICorner")
        deleteCorner.CornerRadius = UDim.new(0, 4)
        deleteCorner.Parent = deleteButton
        
        -- Handle restore button click
        restoreButton.MouseButton1Click:Connect(function()
            -- Show confirmation dialog
            local mainFrame = parent.Parent.Parent.Parent
            
            local confirmDialog = Instance.new("Frame")
            confirmDialog.Size = UDim2.new(0, 300, 0, 150)
            confirmDialog.Position = UDim2.new(0.5, -150, 0.5, -75)
            confirmDialog.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            confirmDialog.BorderSizePixel = 0
            confirmDialog.ZIndex = 10
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = confirmDialog
            
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 40)
            title.BackgroundTransparency = 1
            title.Text = "Confirm Restore"
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.TextSize = 16
            title.Font = Enum.Font.SourceSansBold
            title.ZIndex = 11
            title.Parent = confirmDialog
            
            local message = Instance.new("TextLabel")
            message.Size = UDim2.new(1, -40, 0, 40)
            message.Position = UDim2.new(0, 20, 0, 40)
            message.BackgroundTransparency = 1
            message.Text = "Are you sure you want to restore this backup? This will overwrite the current data for " .. backup.keyName .. " in " .. backup.dataStoreName .. "."
            message.TextColor3 = Color3.fromRGB(200, 200, 200)
            message.TextSize = 14
            message.Font = Enum.Font.SourceSans
            message.TextWrapped = true
            message.ZIndex = 11
            message.Parent = confirmDialog
            
            local cancelButton = Instance.new("TextButton")
            cancelButton.Size = UDim2.new(0, 120, 0, 30)
            cancelButton.Position = UDim2.new(0, 30, 1, -50)
            cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            cancelButton.Text = "Cancel"
            cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            cancelButton.TextSize = 14
            cancelButton.Font = Enum.Font.SourceSansBold
            cancelButton.ZIndex = 11
            cancelButton.Parent = confirmDialog
            
            local cancelCorner = Instance.new("UICorner")
            cancelCorner.CornerRadius = UDim.new(0, 4)
            cancelCorner.Parent = cancelButton
            
            local confirmRestoreButton = Instance.new("TextButton")
            confirmRestoreButton.Size = UDim2.new(0, 120, 0, 30)
            confirmRestoreButton.Position = UDim2.new(1, -150, 1, -50)
            confirmRestoreButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
            confirmRestoreButton.Text = "Restore"
            confirmRestoreButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            confirmRestoreButton.TextSize = 14
            confirmRestoreButton.Font = Enum.Font.SourceSansBold
            confirmRestoreButton.ZIndex = 11
            confirmRestoreButton.Parent = confirmDialog
            
            local confirmCorner = Instance.new("UICorner")
            confirmCorner.CornerRadius = UDim.new(0, 4)
            confirmCorner.Parent = confirmRestoreButton
            
            -- Dim background
            local dimBackground = Instance.new("Frame")
            dimBackground.Size = UDim2.new(1, 0, 1, 0)
            dimBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            dimBackground.BackgroundTransparency = 0.7
            dimBackground.ZIndex = 9
            
            dimBackground.Parent = mainFrame
            confirmDialog.Parent = mainFrame
            
            -- Handle button clicks
            cancelButton.MouseButton1Click:Connect(function()
                dimBackground:Destroy()
                confirmDialog:Destroy()
            end)
            
            confirmRestoreButton.MouseButton1Click:Connect(function()
                -- Restore from backup
                local success, result = DataMigrationTools:restoreFromBackup(backup.id)
                
                -- Create status message
                local statusLabel = Instance.new("TextLabel")
                statusLabel.Size = UDim2.new(1, -40, 0, 30)
                statusLabel.Position = UDim2.new(0, 20, 0, 80)
                statusLabel.BackgroundTransparency = 0.8
                statusLabel.BackgroundColor3 = success and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(239, 83, 80)
                statusLabel.Text = success and "Backup restored successfully" or ("Failed to restore backup: " .. tostring(result))
                statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                statusLabel.TextSize = 14
                statusLabel.Font = Enum.Font.SourceSans
                statusLabel.TextWrapped = true
                statusLabel.ZIndex = 11
                statusLabel.Parent = confirmDialog
                
                -- Make the confirm button say "Close"
                confirmRestoreButton.Text = "Close"
                cancelButton.Visible = false
                confirmRestoreButton.Position = UDim2.new(0.5, -60, 1, -50)
                
                -- Change the behavior of the confirm button
                confirmRestoreButton.MouseButton1Click:Connect(function()
                    dimBackground:Destroy()
                    confirmDialog:Destroy()
                end)
            end)
        end)
        
        -- Handle delete button click
        deleteButton.MouseButton1Click:Connect(function()
            -- Delete the backup
            local success = DataMigrationTools:deleteBackup(backup.id)
            
            if success then
                -- Remove the item from the container
                item:Destroy()
            end
        end)
        
        return item
    end
    
    -- Add backups
    local backupCount = 0
    for _, backup in ipairs(backups) do
        createBackupItem(backup, backupsContainer)
        backupCount = backupCount + 1
    end
    
    -- Add "no backups" message if needed
    if backupCount == 0 then
        local noBackupsLabel = Instance.new("TextLabel")
        noBackupsLabel.Size = UDim2.new(1, 0, 0, 30)
        noBackupsLabel.BackgroundTransparency = 1
        noBackupsLabel.Text = "No backups found"
        noBackupsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noBackupsLabel.TextSize = 14
        noBackupsLabel.Font = Enum.Font.SourceSans
        noBackupsLabel.Parent = backupsContainer
    end
end

-- Populate the settings tab with content
function DataMigrationUI.populateSettingsTab(parent)
    -- Create settings section
    local settingsHeader = createSectionHeader(parent, "Migration Settings", 10)
    
    -- Helper function to create a setting toggle
    local function createSettingToggle(name, description, defaultValue, positionY)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 0, 50)
        container.Position = UDim2.new(0, 10, 0, positionY)
        container.BackgroundTransparency = 1
        container.Parent = parent
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -60, 0, 20)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = container
        
        local descriptionLabel = Instance.new("TextLabel")
        descriptionLabel.Size = UDim2.new(1, -60, 0, 30)
        descriptionLabel.Position = UDim2.new(0, 0, 0, 20)
        descriptionLabel.BackgroundTransparency = 1
        descriptionLabel.Text = description
        descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        descriptionLabel.TextSize = 12
        descriptionLabel.Font = Enum.Font.SourceSans
        descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        descriptionLabel.TextWrapped = true
        descriptionLabel.Parent = container
        
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 40, 0, 24)
        toggle.Position = UDim2.new(1, -50, 0, 13)
        toggle.BackgroundColor3 = defaultValue and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(120, 120, 120)
        toggle.Text = defaultValue and "ON" or "OFF"
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.TextSize = 12
        toggle.Font = Enum.Font.SourceSansBold
        toggle.Parent = container
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 4)
        toggleCorner.Parent = toggle
        
        -- Handle toggle click
        toggle.MouseButton1Click:Connect(function()
            local isOn = toggle.Text == "ON"
            toggle.Text = isOn and "OFF" or "ON"
            toggle.BackgroundColor3 = isOn and Color3.fromRGB(120, 120, 120) or Color3.fromRGB(76, 175, 80)
            
            -- Update config
            DataMigrationTools.config[name:lower():gsub(" ", "")] = not isOn
        end)
        
        return container, toggle
    end
    
    -- Helper function to create a setting input
    local function createSettingInput(name, description, defaultValue, positionY)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 0, 50)
        container.Position = UDim2.new(0, 10, 0, positionY)
        container.BackgroundTransparency = 1
        container.Parent = parent
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -110, 0, 20)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = container
        
        local descriptionLabel = Instance.new("TextLabel")
        descriptionLabel.Size = UDim2.new(1, -110, 0, 30)
        descriptionLabel.Position = UDim2.new(0, 0, 0, 20)
        descriptionLabel.BackgroundTransparency = 1
        descriptionLabel.Text = description
        descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        descriptionLabel.TextSize = 12
        descriptionLabel.Font = Enum.Font.SourceSans
        descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        descriptionLabel.TextWrapped = true
        descriptionLabel.Parent = container
        
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0, 100, 0, 24)
        input.Position = UDim2.new(1, -100, 0, 13)
        input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        input.BorderColor3 = Color3.fromRGB(60, 60, 60)
        input.Text = tostring(defaultValue)
        input.TextColor3 = Color3.fromRGB(255, 255, 255)
        input.TextSize = 12
        input.Font = Enum.Font.SourceSans
        input.ClearTextOnFocus = false
        input.Parent = container
        
        -- Handle focus lost
        input.FocusLost:Connect(function()
            -- Update config
            local numValue = tonumber(input.Text)
            if numValue then
                DataMigrationTools.config[name:lower():gsub(" ", "")] = numValue
            end
        end)
        
        return container, input
    end
    
    -- Create settings
    createSettingToggle("Backup Before Migration", "Create a backup of data before migrating it", 
        DataMigrationTools.config.backupBeforeMigration, 44)
    
    createSettingToggle("Validate Before Migration", "Validate data against schema before migrating",
        DataMigrationTools.config.validateBeforeMigration, 104)
    
    createSettingToggle("Validate After Migration", "Validate data against schema after transforming for migration",
        DataMigrationTools.config.validateAfterMigration, 164)
    
    createSettingInput("Batch Size", "Number of keys to process in each batch during DataStore migration",
        DataMigrationTools.config.batchSize, 224)
    
    createSettingInput("Migration Cooldown", "Seconds to wait between migrations to avoid throttling",
        DataMigrationTools.config.migrationCooldown, 284)
    
    createSettingInput("Max Retries", "Maximum number of retries for failed migrations",
        DataMigrationTools.config.maxRetries, 344)
    
    createSettingInput("Retry Delay", "Seconds to wait before retrying a failed migration",
        DataMigrationTools.config.retryDelay, 404)
    
    -- Create save button
    local saveButton = createButton(
        parent, "Save Settings", 464, 0, 120, Color3.fromRGB(76, 175, 80)
    )
    
    -- Create reset button
    local resetButton = createButton(
        parent, "Reset to Defaults", 464, 0.3, 150, Color3.fromRGB(66, 134, 244)
    )
    
    -- Handle save button click
    saveButton.MouseButton1Click:Connect(function()
        -- Create status message
        local statusLabel = createStatusMessage(
            parent, "Settings saved successfully", Color3.fromRGB(76, 175, 80), 500
        )
        
        statusLabel.Visible = true
        
        -- Hide the status after 3 seconds
        task.delay(3, function()
            statusLabel.Visible = false
        end)
    end)
    
    -- Handle reset button click
    resetButton.MouseButton1Click:Connect(function()
        -- Reset config to defaults
        DataMigrationTools.config = {
            backupBeforeMigration = true,
            validateBeforeMigration = true,
            validateAfterMigration = true,
            batchSize = 10,
            migrationCooldown = 0.5,
            maxRetries = 3,
            retryDelay = 2,
            logLevel = 2,
        }
        
        -- Refresh the tab
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        DataMigrationUI.populateSettingsTab(parent)
        
        -- Create status message
        local statusLabel = createStatusMessage(
            parent, "Settings reset to defaults", Color3.fromRGB(66, 134, 244), 500
        )
        
        statusLabel.Visible = true
        
        -- Hide the status after 3 seconds
        task.delay(3, function()
            statusLabel.Visible = false
        end)
    end)
end

return DataMigrationUI
