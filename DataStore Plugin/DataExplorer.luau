--luau
-- DataStore Plugin/DataExplorer.luau

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local SchemaManager = require(script.Parent.SchemaManager)
local SessionManager = require(script.Parent.SessionManager)
local PerformanceMonitor = require(script.Parent.PerformanceMonitor)
local CacheManager = require(script.Parent.CacheManager)

local DataExplorer = {}
DataExplorer.performanceDataUI = {}
DataExplorer.sessionId = HttpService:GenerateGUID()

DataExplorer.lockStatusUI = {}

-- Local helper to avoid repetition
DataExplorer.cacheViewerPane = nil -- Add a variable to store the cache viewer panel

local function createLabel(text: string, parent: Instance): TextLabel
	local label = Instance.new("TextButton")
    label.BorderSizePixel = 0
	label.BackgroundTransparency = 1
    label.TextTransparency = 0
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Code
	label.TextXAlignment = Enum.TextXAlignment.Left
    label.AutoButtonColor = false
    label.Parent = parent

    
	label.Text = text
	label.Size = UDim2.new(1, 0, 0, 18)

    -- Create the main frame for the data explorer
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Name = "DataStoreExplorerFrame"
    DataExplorer.mainFrame = mainFrame
    

    -- Create a split-pane layout (Using ScrollingFrame for potential future scrolling)
    local splitPane = Instance.new("ScrollingFrame")
    splitPane.Size = UDim2.new(1, 0, 1, 0)
    splitPane.Name = "SplitPane"
    splitPane.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be adjusted later
    splitPane.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    splitPane.ScrollBarInset = Enum.ScrollBarInset.Always
    splitPane.ElasticBehavior = Enum.ElasticBehavior.Never
    splitPane.Parent = mainFrame
    DataExplorer.splitPane = splitPane

    -- Create a UIHorizontalListLayout for the panes within the ScrollingFrame
    local horizontalLayout = Instance.new("UIHorizontalListLayout")
    horizontalLayout.FillDirection = Enum.FillDirection.Horizontal
    horizontalLayout.SortOrder = Enum.SortOrder.LayoutOrder
    horizontalLayout.Parent = splitPane

    -- Create the navigation pane (tree view)
    local navigationPane = Instance.new("Frame")
    navigationPane.Size = UDim2.new(0.3, 0, 1, 0) -- 30% of the width
    navigationPane.Name = "NavigationPane"
    navigationPane.Parent = splitPane
    DataExplorer.navigationPane = navigationPane -- Save the navigation pane for later use

    -- Add a layout for potential items in the navigation pane
    local navigationLayout = Instance.new("UIListLayout")
    navigationLayout.FillDirection = Enum.FillDirection.Vertical
    navigationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navigationLayout.Parent = navigationPane
    
    -- Create a Pane to display performance data
    local performancePane = Instance.new("Frame")
    performancePane.Size = UDim2.new(1, 0, 0.2, 0)
    performancePane.Position = UDim2.new(0,0,0.6,0) -- under the treeview
    performancePane.Name = "PerformancePane"
    performancePane.Parent = navigationPane
    DataExplorer.performancePane = performancePane


        -- Create the cache viewer pane
    local cacheViewerPane = Instance.new("Frame")
    cacheViewerPane.Size = UDim2.new(1, 0, 0.4, 0) -- 40% of the height
    cacheViewerPane.Position = UDim2.new(0, 0, 1, 0) -- At the bottom of the Navigation Pane
    cacheViewerPane.Name = "CacheViewerPane"
    cacheViewerPane.Parent = navigationPane
    DataExplorer.cacheViewerPane = cacheViewerPane -- Store the reference to the cache viewer panel


    -- Create the lock Status pane
    local lockStatusPane = Instance.new("Frame")
    lockStatusPane.Size = UDim2.new(1, 0, 0.2, 0) -- 20% of the height
    lockStatusPane.Position = UDim2.new(0,0,0.8,0) -- at the bottom of the Navigation Pane
    lockStatusPane.Name = "LockStatusPane"
    lockStatusPane.Parent = navigationPane
    DataExplorer.lockStatusPane = lockStatusPane
    -- Add a layout for potential items in the navigation pane
    local lockStatusLayout = Instance.new("UIListLayout")
    lockStatusLayout.FillDirection = Enum.FillDirection.Vertical
    lockStatusLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lockStatusLayout.Padding = UDim.new(0, 2)
    navigationLayout.Parent = navigationPane

        -- Create the content pane (for displaying data)
    local contentPane = Instance.new("ScrollingFrame")
    contentPane.Size = UDim2.new(0.7, 0, 1, 0) -- 70% of the width
    contentPane.Name = "ContentPane"
    contentPane.Parent = splitPane
    DataExplorer.contentPane = contentPane

    -- Add a layout for potential items in the content pane
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentPane

    -- Add a splitter to resize the panes (This will require scripting later)
    -- Placed outside the horizontal layout to overlap
    local splitter = Instance.new("Frame")
    splitter.Size = UDim2.new(0, 5, 1, 0)    
    splitter.Position = UDim2.new(navigationPane.Size.X.Scale, navigationPane.Size.X.Offset - splitter.Size.X.Offset / 2, 0, 0)
    splitter.Name = "Splitter"
    splitter.Draggable = true
    splitter.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
    splitter.ZIndex = 2
    splitter.Parent = mainFrame

        --Add cache content display
    function DataExplorer.updateCacheViewerUI()
        local cacheViewerPane = DataExplorer.cacheViewerPane
        if not cacheViewerPane then return end

        -- Clear existing cache viewer UI
        for _, child in ipairs(cacheViewerPane:GetChildren()) do
            child:Destroy()
        end

        -- Get cache contents
        local cacheContents = CacheManager.getCacheContents()

        if #cacheContents > 0 then
            for _, cacheEntry in ipairs(cacheContents) do
                local entryFrame = Instance.new("Frame")
                entryFrame.Size = UDim2.new(1, 0, 0, 20) -- Fixed height for each entry
                entryFrame.BackgroundTransparency = 1
                entryFrame.Parent = cacheViewerPane

                local entryLayout = Instance.new("UIListLayout")
                entryLayout.FillDirection = Enum.FillDirection.Horizontal
                entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
                entryLayout.Parent = entryFrame
                
                local dataStoreLabel = createLabel(cacheEntry.dataStoreName, entryFrame)
                dataStoreLabel.Size = UDim2.new(0.2,0,1,0)
                local keyLabel = createLabel(cacheEntry.keyName, entryFrame)
                keyLabel.Size = UDim2.new(0.3,0,1,0)
                local sizeLabel = createLabel(string.format("%.2f KB", cacheEntry.estimatedSize / 1024), entryFrame)
                sizeLabel.Size = UDim2.new(0.15,0,1,0)
                local lastAccessedLabel = createLabel(os.date("%Y-%m-%d %H:%M:%S", cacheEntry.lastAccessed), entryFrame)
                lastAccessedLabel.Size = UDim2.new(0.25,0,1,0)
                local accessCountLabel = createLabel(tostring(cacheEntry.accessCount), entryFrame)
                accessCountLabel.Size = UDim2.new(0.1,0,1,0)


            end
        else
            local noDataLabel = createLabel("No data in cache", cacheViewerPane)
            noDataLabel.Parent = cacheViewerPane
        end
    end
    return mainFrame
end

function DataExplorer.updateLockStatusUI()
    local lockStatusPane = DataExplorer.lockStatusPane
    if not lockStatusPane then return end

    -- Clear existing lock status UI
    for _, child in ipairs(lockStatusPane:GetChildren()) do
        child:Destroy()
    end

    -- Get active locks
    local activeLocks = SessionManager.getActiveLocks()

    if #activeLocks > 0 then
        for _, lockInfo in ipairs(activeLocks) do
            local lockLabel = createLabel(lockInfo.dataStoreName .. ":" .. lockInfo.keyName, lockStatusPane)
            lockLabel.Parent = lockStatusPane
            
            local forceUnlockButton = Instance.new("TextButton")
            forceUnlockButton.Text = "Force Unlock"
            forceUnlockButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2) -- Red
            forceUnlockButton.Size = UDim2.new(0, 100, 0, 30)
            forceUnlockButton.Parent = lockLabel

            -- Force unlock function
            forceUnlockButton.MouseButton1Click:Connect(function()
                SessionManager.forceReleaseLock(lockInfo.dataStoreName, lockInfo.keyName)
                DataExplorer.updateLockStatusUI() -- Refresh the lock status UI
            end)
        end
    else
        local noLocksLabel = createLabel("No active locks", lockStatusPane)
        noLocksLabel.Parent = lockStatusPane
    end
end

function DataExplorer.updatePerformanceDataUI()
    local performancePane = DataExplorer.performancePane
    if not performancePane then return end

    -- Clear existing performance data UI
    for _, child in ipairs(performancePane:GetChildren()) do    
        child:Destroy()
    end

    -- Display cache analytics
    local cacheAnalytics = CacheManager.getCacheAnalytics()
    local cacheFrame = Instance.new("Frame")
    cacheFrame.Size = UDim2.new(1, 0, 0, 40)
    cacheFrame.BackgroundTransparency = 1
    cacheFrame.Parent = performancePane

    local cacheHitsLabel = createLabel("Cache Hits: " .. tostring(cacheAnalytics.hits), cacheFrame)
    local cacheMissesLabel = createLabel("Cache Misses: " .. tostring(cacheAnalytics.misses), cacheFrame)
    cacheMissesLabel.Position = UDim2.new(0, 0, 0, 20)

        -- Display cache hit rate percentage
    local hitRate = 0
    if cacheAnalytics.hits + cacheAnalytics.misses > 0 then
        hitRate = (cacheAnalytics.hits / (cacheAnalytics.hits + cacheAnalytics.misses)) * 100
    end
    local hitRateLabel = createLabel(string.format("Hit Rate: %.2f%%", hitRate), cacheFrame)
    hitRateLabel.Position = UDim2.new(0, 0, 0, 40) -- Position below misses



        -- Add cache memory usage display
        local memoryUsage = CacheManager.estimateMemoryUsage()
        local memoryUsageLabel = createLabel("Cache Memory: " .. string.format("%.2f", memoryUsage / 1024) .. " KB", cacheFrame) -- Display in KB
        memoryUsageLabel.Position = UDim2.new(0, 0, 0, 40) -- Position below misses
        memoryUsageLabel.Parent = cacheFrame


    -- Get performance data
    local operationSummary = PerformanceMonitor.getOperationSummary()

    if operationSummary then
        for operationName, summary in pairs(operationSummary) do

            local operationFrame = Instance.new("Frame")
            operationFrame.Size = UDim2.new(1, 0, 0, 40)
            operationFrame.Position = UDim2.new(0,0,0,cacheFrame.Size.Y.Offset)
            operationFrame.BackgroundTransparency = 1
            operationFrame.Parent = performancePane

            -- Create a frame for the table header
            local headerFrame = Instance.new("Frame")
            headerFrame.Size = UDim2.new(1, 0, 0, 20)
            headerFrame.BackgroundTransparency = 1
            headerFrame.Parent = operationFrame

            -- Create a frame for the table rows
            local rowFrame = Instance.new("Frame")
            rowFrame.Size = UDim2.new(1, 0, 0, 20)
            rowFrame.Position = UDim2.new(0,0,0,20)
            rowFrame.BackgroundTransparency = 1
            rowFrame.Parent = operationFrame


            -- Table header labels
            local headerLabels = {
                {name = "Operation", widthScale = 0.3},
                {name = "Count", widthScale = 0.2},
                {name = "Total Duration", widthScale = 0.25},
                {name = "Average Duration", widthScale = 0.25}
            }

            local headerOffset = 0
            for _, header in ipairs(headerLabels) do
                local headerLabel = createLabel(header.name, headerFrame)
                headerLabel.Size = UDim2.new(header.widthScale, 0, 1, 0)
                headerLabel.Position = UDim2.new(0, headerOffset, 0, 0)
                headerOffset += header.widthScale * 100
            end

            -- Row labels (data)
            local rowLabels = {
                {value = operationName, widthScale = 0.3, color = (summary.averageDuration > 0.5) and Color3.fromRGB(255, 100, 100) or nil},
                {value = tostring(summary.count), widthScale = 0.2},
                {value = string.format("%.2fms", summary.totalDuration * 1000), widthScale = 0.25},
                {value = string.format("%.2fms", summary.averageDuration * 1000), widthScale = 0.25}
            }

            local rowOffset = 0
            for _, row in ipairs(rowLabels) do
                local rowLabel = createLabel(row.value, rowFrame)
                rowLabel.Size = UDim2.new(row.widthScale, 0, 1, 0)
                rowLabel.Position = UDim2.new(0, rowOffset, 0, 0)
                rowLabel.TextColor3 = row.color or Color3.new(1,1,1)
                rowOffset += row.widthScale * 100
            end   
        end
    else
        local noDataLabel = createLabel("No performance data yet.", performancePane)
        noDataLabel.Parent = performancePane
    end
end

RunService.Heartbeat:Connect(DataExplorer.updatePerformanceDataUI)
RunService.Heartbeat:Connect(DataExplorer.updateCacheViewerUI)




function DataExplorer.displayKeyContent(dataStoreName: string, keyName: string)
    local contentPane = DataExplorer.contentPane
    if not contentPane then return end
    
    -- Clear the content pane
    for _, child in ipairs(contentPane:GetChildren()) do
        child:Destroy()
    end
    
    -- Attempt to acquire a lock for reading/editing
    local lockAcquired = SessionManager.acquireLock(dataStoreName, keyName, DataExplorer.sessionId)
    if not lockAcquired then
        -- Create a locked notification
        local lockNotification = Instance.new("Frame")
        lockNotification.Size = UDim2.new(1, 0, 0, 40)
        lockNotification.Position = UDim2.new(0, 0, 0, 0)
        lockNotification.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        lockNotification.BackgroundTransparency = 0.2
        lockNotification.BorderSizePixel = 0
        lockNotification.Parent = contentPane
        
        local lockIcon = Instance.new("ImageLabel")
        lockIcon.Size = UDim2.new(0, 24, 0, 24)
        lockIcon.Position = UDim2.new(0, 10, 0.5, -12)
        lockIcon.BackgroundTransparency = 1
        lockIcon.Image = "rbxassetid://6031225819" -- Lock icon
        lockIcon.Parent = lockNotification
        
        local lockText = Instance.new("TextLabel")
        lockText.Size = UDim2.new(1, -50, 1, 0)
        lockText.Position = UDim2.new(0, 40, 0, 0)
        lockText.BackgroundTransparency = 1
        lockText.Text = "This key is currently locked by another session. Read-only mode enabled."
        lockText.TextColor3 = Color3.fromRGB(255, 255, 255)
        lockText.TextXAlignment = Enum.TextXAlignment.Left
        lockText.Font = Enum.Font.SourceSansBold
        lockText.TextSize = 14
        lockText.Parent = lockNotification
        
        local forceUnlockBtn = Instance.new("TextButton")
        forceUnlockBtn.Size = UDim2.new(0, 120, 0, 28)
        forceUnlockBtn.Position = UDim2.new(1, -130, 0.5, -14)
        forceUnlockBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        forceUnlockBtn.Text = "Force Unlock"
        forceUnlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        forceUnlockBtn.Parent = lockNotification
        
        forceUnlockBtn.MouseButton1Click:Connect(function()
            SessionManager.forceReleaseLock(dataStoreName, keyName)
            DataExplorer.displayKeyContent(dataStoreName, keyName) -- Refresh
        end)
    end
    
    -- Retrieve schema if exists for current datastore/key
    local currentSchema = SchemaManager.loadSchema(dataStoreName, keyName)
    
    -- Create header
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 60)
    headerFrame.Position = UDim2.new(0, 0, 0, lockAcquired and 0 or 50)
    headerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = contentPane
    
    -- Display the key name and datastore
    local keyTitle = Instance.new("TextLabel")
    keyTitle.Size = UDim2.new(1, -20, 0, 24)
    keyTitle.Position = UDim2.new(0, 10, 0, 5)
    keyTitle.BackgroundTransparency = 1
    keyTitle.Text = keyName
    keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyTitle.TextXAlignment = Enum.TextXAlignment.Left
    keyTitle.Font = Enum.Font.SourceSansBold
    keyTitle.TextSize = 18
    keyTitle.Parent = headerFrame
    
    local datastoreSubtitle = Instance.new("TextLabel")
    datastoreSubtitle.Size = UDim2.new(1, -20, 0, 18)
    datastoreSubtitle.Position = UDim2.new(0, 10, 0, 30)
    datastoreSubtitle.BackgroundTransparency = 1
    datastoreSubtitle.Text = "DataStore: " .. dataStoreName
    datastoreSubtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
    datastoreSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    datastoreSubtitle.Font = Enum.Font.SourceSans
    datastoreSubtitle.TextSize = 14
    datastoreSubtitle.Parent = headerFrame
    
    -- Add button panel for actions
    local actionPanel = Instance.new("Frame")
    actionPanel.Size = UDim2.new(0, 300, 0, 50)
    actionPanel.Position = UDim2.new(1, -310, 0, 5)
    actionPanel.BackgroundTransparency = 1
    actionPanel.Parent = headerFrame
    
    local panelLayout = Instance.new("UIListLayout")
    panelLayout.FillDirection = Enum.FillDirection.Horizontal
    panelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    panelLayout.Padding = UDim.new(0, 10)
    panelLayout.Parent = actionPanel
    
    -- Create validation message area
    local validationMessageFrame = Instance.new("Frame")
    validationMessageFrame.Size = UDim2.new(1, 0, 0, 0) -- Will auto-expand if needed
    validationMessageFrame.Position = UDim2.new(0, 0, 0, headerFrame.Position.Y.Offset + headerFrame.Size.Y.Offset)
    validationMessageFrame.BackgroundTransparency = 1
    validationMessageFrame.Visible = false
    validationMessageFrame.Name = "ValidationMessageFrame"
    validationMessageFrame.Parent = contentPane
    
    local validationMessage = Instance.new("TextLabel")
    validationMessage.Size = UDim2.new(1, -20, 1, 0)
    validationMessage.Position = UDim2.new(0, 10, 0, 0)
    validationMessage.BackgroundTransparency = 1
    validationMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
    validationMessage.TextXAlignment = Enum.TextXAlignment.Left
    validationMessage.TextWrapped = true
    validationMessage.Font = Enum.Font.SourceSans
    validationMessage.TextSize = 14
    validationMessage.Name = "ValidationMessage"
    validationMessage.Parent = validationMessageFrame
    
    -- Add a tab system for different views
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Size = UDim2.new(1, 0, 0, 30)
    tabsFrame.Position = UDim2.new(0, 0, 0, headerFrame.Position.Y.Offset + headerFrame.Size.Y.Offset)
    tabsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    tabsFrame.BorderSizePixel = 0
    tabsFrame.Parent = contentPane
    
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.Padding = UDim.new(0, 2)
    tabsLayout.Parent = tabsFrame
    
    -- Create content area
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, 0, 1, -(tabsFrame.Position.Y.Offset + tabsFrame.Size.Y.Offset + 10))
    contentArea.Position = UDim2.new(0, 0, 0, tabsFrame.Position.Y.Offset + tabsFrame.Size.Y.Offset + 5)
    contentArea.BackgroundTransparency = 1
    contentArea.Name = "ContentArea"
    contentArea.Parent = contentPane
    
    -- Function to create a tab
    local function createTab(name, selected)
        local tab = Instance.new("TextButton")
        tab.Size = UDim2.new(0, 100, 1, 0)
        tab.BackgroundColor3 = selected and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(40, 40, 50)
        tab.BorderSizePixel = 0
        tab.Text = name
        tab.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        tab.Font = Enum.Font.SourceSansSemibold
        tab.Name = "Tab_" .. name
        tab.Parent = tabsFrame
        
        return tab
    end
    
    -- Function to create a view container
    local function createViewContainer(name)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Visible = false
        container.Name = "View_" .. name
        container.Parent = contentArea
        
        return container
    end
    
    -- Create tabs and view containers
    local tabJsonEditor = createTab("JSON Editor", true)
    local tabTreeView = createTab("Tree View", false)
    local tabRawView = createTab("Raw View", false)
    local tabVisualizer = createTab("Visualizer", false)
    
    local viewJsonEditor = createViewContainer("JSON Editor")
    local viewTreeView = createViewContainer("Tree View")
    local viewRawView = createViewContainer("Raw View")
    local viewVisualizer = createViewContainer("Visualizer")
    
    -- Make JSON Editor visible by default
    viewJsonEditor.Visible = true
    
    -- Function to switch tabs
    local function switchTab(selectedTabName)
        for _, tab in ipairs(tabsFrame:GetChildren()) do
            if tab:IsA("TextButton") and tab.Name:match("^Tab_") then
                local isSelected = tab.Name == "Tab_" .. selectedTabName
                tab.BackgroundColor3 = isSelected and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(40, 40, 50)
                tab.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
            end
        end
        
        for _, view in ipairs(contentArea:GetChildren()) do
            if view:IsA("Frame") and view.Name:match("^View_") then
                view.Visible = view.Name == "View_" .. selectedTabName
            end
        end
    end
    
    -- Connect tab click events
    tabJsonEditor.MouseButton1Click:Connect(function() switchTab("JSON Editor") end)
    tabTreeView.MouseButton1Click:Connect(function() switchTab("Tree View") end)
    tabRawView.MouseButton1Click:Connect(function() switchTab("Raw View") end)
    tabVisualizer.MouseButton1Click:Connect(function() switchTab("Visualizer") end)
    
    -- Fetch the data from DataStore
    local dataStore = DataStoreService:GetDataStore(dataStoreName)
    
    -- Check cache first before fetching from DataStore
    local cachedData = CacheManager.get(dataStoreName, keyName)
    local success, data, operationDuration
    
    if cachedData then
        success, data = true, cachedData
        print("DataExplorer: Retrieved data from cache for", dataStoreName .. ":" .. keyName)
    else
        success, data, operationDuration = PerformanceMonitor.timeOperation(
            "GetAsync",
            function() return pcall(dataStore.GetAsync, dataStore, keyName) end,
            dataStoreName,
            keyName
        )
        print("Operation: GetAsync, Duration:", operationDuration)
        
        -- Cache the data if retrieved successfully
        if success and data then
            CacheManager.set(dataStoreName, keyName, data, 300) -- Cache for 5 minutes
        end
    end
    
    if not success or not data then
        -- Show error
        validationMessageFrame.Size = UDim2.new(1, 0, 0, 40)
        validationMessageFrame.Visible = true
        validationMessageFrame.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        validationMessageFrame.BackgroundTransparency = 0.7
        validationMessage.Text = "Error fetching data: " .. (not success and tostring(data) or "No data found")
        return
    end
    
    -- Convert data to a JSON-encoded string for editing
    local encodedData = HttpService:JSONEncode(data)
    
    -- Save function
    local function saveData(dataToSave)
        if not lockAcquired then
            validationMessageFrame.Size = UDim2.new(1, 0, 0, 40)
            validationMessageFrame.Visible = true
            validationMessageFrame.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            validationMessageFrame.BackgroundTransparency = 0.7
            validationMessage.Text = "Cannot save: Key is locked by another session"
            return false
        end
        
        -- Validate data before saving
        if currentSchema then
            local isValid, validationResult = SchemaManager.validateData(dataToSave, currentSchema)
            if not isValid then
                validationMessageFrame.Size = UDim2.new(1, 0, 0, 40)
                validationMessageFrame.Visible = true
                validationMessageFrame.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
                validationMessageFrame.BackgroundTransparency = 0.7
                validationMessage.Text = "Data validation failed: " .. validationResult
                return false
            end
        end
        
        -- Save the data
        local success2, result, operationDuration2 = PerformanceMonitor.timeOperation(
            "SetAsync",
            function() return pcall(dataStore.SetAsync, dataStore, keyName, dataToSave) end,
            dataStoreName,
            keyName
        )
        print("Operation: SetAsync, Duration:", operationDuration2)
        
        if success2 then
            -- Update cache
            CacheManager.set(dataStoreName, keyName, dataToSave, 300)
            
            -- Show success message
            validationMessageFrame.Size = UDim2.new(1, 0, 0, 40)
            validationMessageFrame.Visible = true
            validationMessageFrame.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
            validationMessageFrame.BackgroundTransparency = 0.7
            validationMessage.Text = "Data saved successfully"
            validationMessage.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            -- Hide the message after 3 seconds
            task.delay(3, function()
                validationMessageFrame.Visible = false
            end)
            
            return true
        else
            -- Show error message
            validationMessageFrame.Size = UDim2.new(1, 0, 0, 40)
            validationMessageFrame.Visible = true
            validationMessageFrame.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            validationMessageFrame.BackgroundTransparency = 0.7
            validationMessage.Text = "Error saving data: " .. tostring(result)
            validationMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
            return false
        end
    end
    
    -- Create save button
    local saveButton = Instance.new("TextButton")
    saveButton.Size = UDim2.new(0, 100, 0, 36)
    saveButton.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
    saveButton.BorderSizePixel = 0
    saveButton.Text = "Save"
    saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveButton.Font = Enum.Font.SourceSansBold
    saveButton.TextSize = 16
    saveButton.AutoButtonColor = true
    saveButton.Parent = actionPanel
    
    -- Create other action buttons
    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0, 100, 0, 36)
    refreshButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
    refreshButton.BorderSizePixel = 0
    refreshButton.Text = "Refresh"
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.Font = Enum.Font.SourceSansBold
    refreshButton.TextSize = 16
    refreshButton.AutoButtonColor = true
    refreshButton.Parent = actionPanel
    
    refreshButton.MouseButton1Click:Connect(function()
        DataExplorer.displayKeyContent(dataStoreName, keyName)
    end)
    
    -- Implement the JSON Editor View
    local jsonEditor = Instance.new("TextBox")
    jsonEditor.Size = UDim2.new(1, -20, 1, -10)
    jsonEditor.Position = UDim2.new(0, 10, 0, 5)
    jsonEditor.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    jsonEditor.BorderColor3 = Color3.fromRGB(60, 60, 80)
    jsonEditor.ClearTextOnFocus = false
    jsonEditor.Font = Enum.Font.Code
    jsonEditor.TextColor3 = Color3.fromRGB(255, 255, 255)
    jsonEditor.TextSize = 14
    jsonEditor.TextXAlignment = Enum.TextXAlignment.Left
    jsonEditor.TextYAlignment = Enum.TextYAlignment.Top
    jsonEditor.Text = encodedData
    jsonEditor.MultiLine = true
    jsonEditor.TextWrapped = false
    jsonEditor.Name = "JSONEditor"
    jsonEditor.Parent = viewJsonEditor
    
    -- Implement Save functionality
    saveButton.MouseButton1Click:Connect(function()
        local success, decodedData = pcall(HttpService.JSONDecode, HttpService, jsonEditor.Text)
        if success then
            saveData(decodedData)
        else
            -- Show error message
            validationMessageFrame.Size = UDim2.new(1, 0, 0, 40)
            validationMessageFrame.Visible = true
            validationMessageFrame.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            validationMessageFrame.BackgroundTransparency = 0.7
            validationMessage.Text = "Invalid JSON: " .. decodedData
            validationMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
    
    -- Function to create a formatted JSON view with syntax highlighting
    local function createFormattedJsonView(container, jsonData)
        local formattedView = Instance.new("ScrollingFrame")
        formattedView.Size = UDim2.new(1, -20, 1, -10)
        formattedView.Position = UDim2.new(0, 10, 0, 5)
        formattedView.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        formattedView.BorderColor3 = Color3.fromRGB(60, 60, 80)
        formattedView.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set later
        formattedView.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        formattedView.ScrollBarThickness = 6
        formattedView.ScrollingDirection = Enum.ScrollingDirection.Y
        formattedView.Parent = container
        
        local textLayout = Instance.new("UIListLayout")
        textLayout.SortOrder = Enum.SortOrder.LayoutOrder
        textLayout.Parent = formattedView
        
        -- Helper function to create a text line
        local function createTextLine(text, color, indent)
            local line = Instance.new("TextLabel")
            line.Size = UDim2.new(1, -indent, 0, 18)
            line.Position = UDim2.new(0, indent, 0, 0)
            line.BackgroundTransparency = 1
            line.Text = text
            line.TextColor3 = color or Color3.fromRGB(255, 255, 255)
            line.TextXAlignment = Enum.TextXAlignment.Left
            line.Font = Enum.Font.Code
            line.TextSize = 14
            line.LayoutOrder = textLayout.AbsoluteContentSize.Y
            line.Parent = formattedView
            return line
        end
        
        -- Format the JSON nicely
        local formattingSuccess, formattedJson = pcall(function()
            local lines = {}
            local indentLevel = 0
            local inString = false
            local currentLine = ""
            
            local function addLine()
                if currentLine ~= "" then
                    table.insert(lines, {text = currentLine, indent = indentLevel * 20})
                    currentLine = ""
                end
            end
            
            -- Very basic JSON formatter (in practice, we'd use a proper parser)
            for i = 1, #jsonData do
                local char = string.sub(jsonData, i, i)
                
                if char == '"' and string.sub(jsonData, i-1, i-1) ~= "\\" then
                    inString = not inString
                end
                
                if not inString then
                    if char == "{" or char == "[" then
                        addLine()
                        table.insert(lines, {text = char, indent = indentLevel * 20})
                        indentLevel = indentLevel + 1
                        addLine()
                    elseif char == "}" or char == "]" then
                        addLine()
                        indentLevel = indentLevel - 1
                        table.insert(lines, {text = char, indent = indentLevel * 20})
                    elseif char == "," then
                        currentLine = currentLine .. char
                        addLine()
                    elseif char == ":" then
                        currentLine = currentLine .. char .. " "
                    elseif char ~= " " and char ~= "\t" and char ~= "\n" and char ~= "\r" then
                        currentLine = currentLine .. char
                    end
                else
                    currentLine = currentLine .. char
                end
            end
            
            addLine()
            return lines
        end)
        
        if formattingSuccess then
            for _, line in ipairs(formattedJson) do
                createTextLine(line.text, nil, line.indent)
            end
        else
            createTextLine("Error formatting JSON: " .. tostring(formattedJson), Color3.fromRGB(255, 100, 100), 0)
        end
    end
    
    -- Implement Raw View
    createFormattedJsonView(viewRawView, encodedData)
    
    -- Implement the Tree View (recursive table explorer)
    local function createTreeView(container, data)
        local treeRoot = Instance.new("ScrollingFrame")
        treeRoot.Size = UDim2.new(1, -20, 1, -10)
        treeRoot.Position = UDim2.new(0, 10, 0, 5)
        treeRoot.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        treeRoot.BorderColor3 = Color3.fromRGB(60, 60, 80)
        treeRoot.CanvasSize = UDim2.new(0, 0, 0, 0)
        treeRoot.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        treeRoot.ScrollBarThickness = 6
        treeRoot.Parent = container
        
        local treeLayout = Instance.new("UIListLayout")
        treeLayout.SortOrder = Enum.SortOrder.LayoutOrder
        treeLayout.Padding = UDim.new(0, 1)
        treeLayout.Parent = treeRoot
        
        -- Recursively create tree nodes
        local function createTreeNode(key, value, depth, parent)
            local nodeFrame = Instance.new("Frame")
            nodeFrame.Size = UDim2.new(1, 0, 0, 24)
            nodeFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            nodeFrame.BackgroundTransparency = 0.2
            nodeFrame.LayoutOrder = parent.AbsoluteSize.Y
            nodeFrame.Parent = parent
            
            local indent = depth * 20
            
            -- Toggle button for tables
            local isExpandable = type(value) == "table"
            if isExpandable then
                local toggleBtn = Instance.new("TextButton")
                toggleBtn.Size = UDim2.new(0, 16, 0, 16)
                toggleBtn.Position = UDim2.new(0, indent, 0.5, -8)
                toggleBtn.Text = "+"
                toggleBtn.BackgroundTransparency = 1
                toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                toggleBtn.Name = "ToggleBtn"
                toggleBtn.Parent = nodeFrame
                
                -- Content frame for children (initially hidden)
                local contentFrame = Instance.new("Frame")
                contentFrame.Size = UDim2.new(1, 0, 0, 0)
                contentFrame.BackgroundTransparency = 1
                contentFrame.Visible = false
                contentFrame.Name = "Content_" .. tostring(key)
                contentFrame.LayoutOrder = nodeFrame.LayoutOrder + 1
                contentFrame.Parent = parent
                
                -- Content layout
                local contentLayout = Instance.new("UIListLayout")
                contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
                contentLayout.Parent = contentFrame
                
                -- Store expanded state
                toggleBtn:SetAttribute("Expanded", false)
                toggleBtn:SetAttribute("ContentFrame", contentFrame.Name)
                
                -- Toggle content visibility
                toggleBtn.MouseButton1Click:Connect(function()
                    local expanded = toggleBtn:GetAttribute("Expanded")
                    expanded = not expanded
                    toggleBtn:SetAttribute("Expanded", expanded)
                    toggleBtn.Text = expanded and "-" or "+"
                    contentFrame.Visible = expanded
                    
                    -- Create children on first expansion
                    if expanded and not toggleBtn:GetAttribute("ChildrenCreated") then
                        toggleBtn:SetAttribute("ChildrenCreated", true)
                        
                        -- Add children
                        if type(value) == "table" then
                            -- Sort keys to ensure consistent display
                            local keys = {}
                            for k in pairs(value) do
                                table.insert(keys, k)
                            end
                            table.sort(keys, function(a, b)
                                if type(a) == type(b) then
                                    if type(a) == "number" then
                                        return a < b
                                    else
                                        return tostring(a) < tostring(b)
                                    end
                                else
                                    return type(a) == "number"
                                end
                            end)
                            
                            for _, k in ipairs(keys) do
                                createTreeNode(k, value[k], depth + 1, contentFrame)
                            end
                        end
                    end
                end)
            end
            
            -- Key label
            local keyLabel = Instance.new("TextLabel")
            keyLabel.Size = UDim2.new(0.5, -indent - (isExpandable and 20 or 0), 1, 0)
            keyLabel.Position = UDim2.new(0, indent + (isExpandable and 20 or 0), 0, 0)
            keyLabel.BackgroundTransparency = 1
            keyLabel.TextXAlignment = Enum.TextXAlignment.Left
            keyLabel.Text = tostring(key) .. ":"
            keyLabel.TextColor3 = Color3.fromRGB(80, 160, 255)
            keyLabel.Font = Enum.Font.Code
            keyLabel.TextSize = 14
            keyLabel.Parent = nodeFrame
            
            -- Value display - different formatting based on type
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0.5, 0, 1, 0)
            valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
            valueLabel.BackgroundTransparency = 1
            valueLabel.TextXAlignment = Enum.TextXAlignment.Left
            valueLabel.Parent = nodeFrame
            
            if type(value) == "string" then
                valueLabel.Text = '"' .. value .. '"'
                valueLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
            elseif type(value) == "number" then
                valueLabel.Text = tostring(value)
                valueLabel.TextColor3 = Color3.fromRGB(255, 200, 150)
            elseif type(value) == "boolean" then
                valueLabel.Text = tostring(value)
                valueLabel.TextColor3 = Color3.fromRGB(255, 160, 160)
            elseif type(value) == "table" then
                local count = 0
                for _ in pairs(value) do
                    count = count + 1
                end
                valueLabel.Text = "{...} (" .. count .. " items)"
                valueLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
            else
                valueLabel.Text = tostring(value)
                valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
            
            valueLabel.Font = Enum.Font.Code
            valueLabel.TextSize = 14
        end
        
        -- Start creating the tree with the root object
        if type(data) == "table" then
            -- Sort keys for consistent display
            local keys = {}
            for k in pairs(data) do
                table.insert(keys, k)
            end
            table.sort(keys, function(a, b)
                if type(a) == type(b) then
                    if type(a) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                else
                    return type(a) == "number"
                end
            end)
            
            for _, k in ipairs(keys) do
                createTreeNode(k, data[k], 0, treeRoot)
            end
        else
            -- If it's not a table, just display the value
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(1, -10, 0, 24)
            valueLabel.Position = UDim2.new(0, 5, 0, 0)
            valueLabel.BackgroundTransparency = 1
            valueLabel.TextXAlignment = Enum.TextXAlignment.Left
            valueLabel.Text = tostring(data)
            valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            valueLabel.Font = Enum.Font.Code
            valueLabel.TextSize = 14
            valueLabel.Parent = treeRoot
        end
    end
    
    -- Implement Tree View
    createTreeView(viewTreeView, data)
    
    -- Implement Visualizer based on data type
    local function createVisualizer(container, data)
        local function createBasicStatsView()
            local statsFrame = Instance.new("Frame")
            statsFrame.Size = UDim2.new(1, -20, 0, 200)
            statsFrame.Position = UDim2.new(0, 10, 0, 10)
            statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            statsFrame.BorderColor3 = Color3.fromRGB(60, 60, 80)
            statsFrame.Parent = container
            
            local statsLayout = Instance.new("UIListLayout")
            statsLayout.Padding = UDim.new(0, 5)
            statsLayout.Parent = statsFrame
            
            -- Helper to create stat rows
            local function addStat(name, value, color)
                local statRow = Instance.new("Frame")
                statRow.Size = UDim2.new(1, 0, 0, 24)
                statRow.BackgroundTransparency = 1
                statRow.Parent = statsFrame
                
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.3, 0, 1, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = name
                nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Font = Enum.Font.SourceSansSemibold
                nameLabel.TextSize = 14
                nameLabel.Parent = statRow
                
                local valueLabel = Instance.new("TextLabel")
                valueLabel.Size = UDim2.new(0.7, 0, 1, 0)
                valueLabel.Position = UDim2.new(0.3, 0, 0, 0)
                valueLabel.BackgroundTransparency = 1
                valueLabel.Text = tostring(value)
                valueLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
                valueLabel.TextXAlignment = Enum.TextXAlignment.Left
                valueLabel.Font = Enum.Font.SourceSans
                valueLabel.TextSize = 14
                valueLabel.Parent = statRow
            end
            
            -- Count total size
            local function countSize(obj)
                local jsonStr = HttpService:JSONEncode(obj)
                return #jsonStr
            end
            
            -- Analyze data structure
            local dataSize = countSize(data)
            local dataType = type(data)
            local itemCount = 0
            local nestedLevels = 0
            
            local function analyzeTable(tbl, level)
                nestedLevels = math.max(nestedLevels, level)
                for k, v in pairs(tbl) do
                    itemCount = itemCount + 1
                    if type(v) == "table" then
                        analyzeTable(v, level + 1)
                    end
                end
            end
            
            if dataType == "table" then
                analyzeTable(data, 1)
            end
            
            -- Add stats
            addStat("Data Type", dataType:upper(), Color3.fromRGB(100, 180, 255))
            addStat("Data Size", string.format("%.2f KB", dataSize / 1024), Color3.fromRGB(255, 200, 100))
            
            if dataType == "table" then
                addStat("Item Count", itemCount, Color3.fromRGB(180, 255, 120))
                addStat("Nested Levels", nestedLevels, Color3.fromRGB(255, 150, 150))
            end
            
            -- Return the stats frame for further customization
            return statsFrame
        end
        
        local statsView = createBasicStatsView()
        
        -- Create chart area (if data is suitable for visualization)
        if type(data) == "table" then
            local chartFrame = Instance.new("Frame")
            chartFrame.Size = UDim2.new(1, -20, 0, 300)
            chartFrame.Position = UDim2.new(0, 10, 0, statsView.Size.Y.Offset + 20)
            chartFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            chartFrame.BorderColor3 = Color3.fromRGB(60, 60, 80)
            chartFrame.Parent = container
            
            -- Try to detect if the data is suitable for charts
            local numericalData = {}
            local hasNumericalData = false
            
            -- Look for arrays of numbers or objects with numerical properties
            if type(data) == "table" then
                -- Check if it's an array of numbers
                local isArray = true
                local allNumbers = true
                local i = 1
                
                for k, v in pairs(data) do
                    if k ~= i then
                        isArray = false
                    end
                    if type(v) ~= "number" then
                        allNumbers = false
                    else
                        table.insert(numericalData, v)
                    end
                    i = i + 1
                end
                
                hasNumericalData = isArray and allNumbers and #numericalData > 0
                
                -- If not a simple array, look for objects with common numerical properties
                if not hasNumericalData then
                    local commonProps = {}
                    local firstItem = true
                    
                    for _, item in pairs(data) do
                        if type(item) == "table" then
                            if firstItem then
                                for prop, value in pairs(item) do
                                    if type(value) == "number" then
                                        commonProps[prop] = true
                                    end
                                end
                                firstItem = false
                            else
                                for prop in pairs(commonProps) do
                                    if type(item[prop]) ~= "number" then
                                        commonProps[prop] = nil
                                    end
                                end
                            end
                        end
                    end
                    
                    -- If we found common numerical properties, extract them
                    local propNames = {}
                    for prop in pairs(commonProps) do
                        table.insert(propNames, prop)
                    end
                    
                    if #propNames > 0 then
                        hasNumericalData = true
                        numericalData = {}
                        
                        -- Extract property values
                        for _, item in pairs(data) do
                            if type(item) == "table" then
                                local entry = {}
                                for _, prop in ipairs(propNames) do
                                    entry[prop] = item[prop]
                                end
                                table.insert(numericalData, entry)
                            end
                        end
                    end
                end
            end
            
            -- If we found numerical data, create a chart
            if hasNumericalData then
                local chartTitle = Instance.new("TextLabel")
                chartTitle.Size = UDim2.new(1, 0, 0, 30)
                chartTitle.BackgroundTransparency = 1
                chartTitle.Text = "Data Visualization"
                chartTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                chartTitle.Font = Enum.Font.SourceSansBold
                chartTitle.TextSize = 16
                chartTitle.Parent = chartFrame
                
                local chartArea = Instance.new("Frame")
                chartArea.Size = UDim2.new(1, -20, 1, -40)
                chartArea.Position = UDim2.new(0, 10, 0, 30)
                chartArea.BackgroundTransparency = 1
                chartArea.Parent = chartFrame
                
                -- Create a basic bar chart if simple array of numbers
                if type(numericalData[1]) == "number" then
                    local maxValue = 0
                    for _, value in ipairs(numericalData) do
                        maxValue = math.max(maxValue, value)
                    end
                    
                    local barWidth = chartArea.Size.X.Scale / #numericalData
                    local padding = 0.1 * barWidth
                    
                    for i, value in ipairs(numericalData) do
                        local barHeight = (value / maxValue) * chartArea.Size.Y.Scale
                        
                        local bar = Instance.new("Frame")
                        bar.Size = UDim2.new(barWidth - padding, 0, barHeight, 0)
                        bar.Position = UDim2.new((i-1) * barWidth + padding/2, 0, 1 - barHeight, 0)
                        bar.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
                        bar.BorderSizePixel = 0
                        bar.Parent = chartArea
                        
                        local valueLabel = Instance.new("TextLabel")
                        valueLabel.Size = UDim2.new(1, 0, 0, 20)
                        valueLabel.Position = UDim2.new(0, 0, -20/chartArea.Size.Y.Offset, 0)
                        valueLabel.BackgroundTransparency = 1
                        valueLabel.Text = tostring(value)
                        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        valueLabel.Font = Enum.Font.SourceSans
                        valueLabel.TextSize = 12
                        valueLabel.Parent = bar
                    end
                else
                    -- For more complex data, show a property selector
                    local propNames = {}
                    for prop in pairs(numericalData[1]) do
                        table.insert(propNames, prop)
                    end
                    
                    local selectorFrame = Instance.new("Frame")
                    selectorFrame.Size = UDim2.new(1, 0, 0, 30)
                    selectorFrame.BackgroundTransparency = 1
                    selectorFrame.Parent = chartArea
                    
                    local selectorLabel = Instance.new("TextLabel")
                    selectorLabel.Size = UDim2.new(0.3, 0, 1, 0)
                    selectorLabel.BackgroundTransparency = 1
                    selectorLabel.Text = "Select Property:"
                    selectorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                    selectorLabel.TextXAlignment = Enum.TextXAlignment.Left
                    selectorLabel.Font = Enum.Font.SourceSansSemibold
                    selectorLabel.TextSize = 14
                    selectorLabel.Parent = selectorFrame
                    
                    local propDropdown = Instance.new("TextButton")
                    propDropdown.Size = UDim2.new(0.5, 0, 1, 0)
                    propDropdown.Position = UDim2.new(0.3, 0, 0, 0)
                    propDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                    propDropdown.BorderColor3 = Color3.fromRGB(70, 70, 90)
                    propDropdown.Text = propNames[1]
                    propDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
                    propDropdown.Font = Enum.Font.SourceSans
                    propDropdown.TextSize = 14
                    propDropdown.Parent = selectorFrame
                    
                    -- For simplicity, we're just picking the first property without a dropdown implementation
                    -- In a real implementation, you'd create a proper dropdown menu
                    
                    -- Create a simple bar chart for the first property
                    local chartFrame = Instance.new("Frame")
                    chartFrame.Size = UDim2.new(1, 0, 1, -40)
                    chartFrame.Position = UDim2.new(0, 0, 0, 40)
                    chartFrame.BackgroundTransparency = 1
                    chartFrame.Parent = chartArea
                    
                    local selectedProp = propNames[1]
                    local maxValue = 0
                    for _, entry in ipairs(numericalData) do
                        maxValue = math.max(maxValue, entry[selectedProp] or 0)
                    end
                    
                    local barWidth = chartFrame.Size.X.Scale / #numericalData
                    local padding = 0.1 * barWidth
                    
                    for i, entry in ipairs(numericalData) do
                        local value = entry[selectedProp] or 0
                        local barHeight = (value / maxValue) * chartFrame.Size.Y.Scale
                        
                        local bar = Instance.new("Frame")
                        bar.Size = UDim2.new(barWidth - padding, 0, barHeight, 0)
                        bar.Position = UDim2.new((i-1) * barWidth + padding/2, 0, 1 - barHeight, 0)
                        bar.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
                        bar.BorderSizePixel = 0
                        bar.Parent = chartFrame
                        
                        local valueLabel = Instance.new("TextLabel")
                        valueLabel.Size = UDim2.new(1, 0, 0, 20)
                        valueLabel.Position = UDim2.new(0, 0, -20/chartFrame.Size.Y.Offset, 0)
                        valueLabel.BackgroundTransparency = 1
                        valueLabel.Text = tostring(value)
                        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        valueLabel.Font = Enum.Font.SourceSans
                        valueLabel.TextSize = 12
                        valueLabel.Parent = bar
                    end
                end
            else
                -- If no suitable data for visualization, show message
                local noChartMessage = Instance.new("TextLabel")
                noChartMessage.Size = UDim2.new(1, 0, 1, 0)
                noChartMessage.BackgroundTransparency = 1
                noChartMessage.Text = "No suitable numerical data found for visualization"
                noChartMessage.TextColor3 = Color3.fromRGB(200, 200, 200)
                noChartMessage.Font = Enum.Font.SourceSans
                noChartMessage.TextSize = 16
                noChartMessage.Parent = chartFrame
            end
        end
    end
    
    -- Implement Visualizer
    createVisualizer(viewVisualizer, data)
end

-- Create a styled tree node with expand/collapse functionality
local function createTreeNode(text, parent, level, isDataStore)
    local nodeContainer = Instance.new("Frame")
    nodeContainer.Size = UDim2.new(1, 0, 0, 24)
    nodeContainer.BackgroundColor3 = isDataStore and Color3.fromRGB(40, 40, 50) or Color3.fromRGB(30, 30, 40)
    nodeContainer.BackgroundTransparency = 0.2
    nodeContainer.BorderSizePixel = 0
    nodeContainer.Name = "TreeNode_" .. text
    nodeContainer.Parent = parent
    
    -- Indentation based on level
    local indentation = 16 * level
    
    -- Expand/collapse icon (for datastores only)
    if isDataStore then
        local expandIcon = Instance.new("TextButton")
        expandIcon.Size = UDim2.new(0, 16, 0, 16)
        expandIcon.Position = UDim2.new(0, indentation, 0.5, -8)
        expandIcon.BackgroundTransparency = 1
        expandIcon.Text = "+"
        expandIcon.TextSize = 16
        expandIcon.TextColor3 = Color3.fromRGB(200, 200, 200)
        expandIcon.Name = "ExpandIcon"
        expandIcon.Parent = nodeContainer
        
        -- Store expanded state
        nodeContainer:SetAttribute("Expanded", false)
    end
    
    -- Node label
    local nodeLabel = Instance.new("TextButton")
    nodeLabel.Size = UDim2.new(1, -indentation - 24, 1, 0)
    nodeLabel.Position = UDim2.new(0, indentation + (isDataStore and 20 or 0), 0, 0)
    nodeLabel.BackgroundTransparency = 1
    nodeLabel.TextXAlignment = Enum.TextXAlignment.Left
    nodeLabel.Text = text
    nodeLabel.TextSize = 14
    nodeLabel.Font = Enum.Font.Code
    nodeLabel.TextColor3 = isDataStore and Color3.fromRGB(120, 160, 255) or Color3.fromRGB(255, 255, 255)
    nodeLabel.Name = "NodeLabel"
    nodeLabel.Parent = nodeContainer
    
    -- Icon based on type
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 16, 0, 16)
    icon.Position = UDim2.new(0, indentation + (isDataStore ? 20 : 4), 0.5, -8)
    icon.BackgroundTransparency = 1
    icon.Image = isDataStore and "rbxassetid://6031090990" or "rbxassetid://6026568207" -- Database icon or Key icon
    icon.Parent = nodeContainer
    
    -- Hover effect
    nodeContainer.MouseEnter:Connect(function()
        nodeContainer.BackgroundColor3 = isDataStore and Color3.fromRGB(60, 60, 70) or Color3.fromRGB(50, 50, 60)
    end)
    
    nodeContainer.MouseLeave:Connect(function()
        nodeContainer.BackgroundColor3 = isDataStore and Color3.fromRGB(40, 40, 50) or Color3.fromRGB(30, 30, 40)
    end)
    
    return nodeContainer
end

function DataExplorer.populateDataStores()
    local navigationPane = DataExplorer.navigationPane
    if not navigationPane then return end
    
    -- Create search bar at the top
    local searchBar = Instance.new("Frame")
    searchBar.Size = UDim2.new(1, 0, 0, 30)
    searchBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    searchBar.BorderSizePixel = 0
    searchBar.Name = "SearchBar"
    searchBar.Parent = navigationPane
    
    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Size = UDim2.new(0, 16, 0, 16)
    searchIcon.Position = UDim2.new(0, 8, 0.5, -8)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = "rbxassetid://3605022185" -- Search icon
    searchIcon.Parent = searchBar
    
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -40, 1, -6)
    searchBox.Position = UDim2.new(0, 32, 0, 3)
    searchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    searchBox.BorderSizePixel = 0
    searchBox.PlaceholderText = "Search datastores and keys..."
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchBar
    
    -- Create a container for the tree view
    local treeContainer = Instance.new("ScrollingFrame")
    treeContainer.Size = UDim2.new(1, 0, 0.4, -30) -- Leave room for search bar
    treeContainer.Position = UDim2.new(0, 0, 0, 30)
    treeContainer.BackgroundTransparency = 0
    treeContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    treeContainer.BorderSizePixel = 0
    treeContainer.ScrollBarThickness = 6
    treeContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    treeContainer.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    treeContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    treeContainer.Name = "TreeContainer"
    treeContainer.Parent = navigationPane
    
    local treeLayout = Instance.new("UIListLayout")
    treeLayout.Padding = UDim.new(0, 1)
    treeLayout.SortOrder = Enum.SortOrder.Name
    treeLayout.Parent = treeContainer
    
    DataExplorer.updateLockStatusUI()
    local function releaseLock(dataStoreName: string, keyName: string)
        SessionManager.releaseLock(dataStoreName, keyName, DataExplorer.sessionId)
    end
    DataExplorer.updatePerformanceDataUI()
    DataExplorer.updateCacheViewerUI()

    game:BindToClose(function()
        for _, dataStoreInfo in DataStoreService:ListDataStoresAsync():GetCurrentPage() do
            for _, keyInfo in DataStoreService:GetDataStore(dataStoreInfo.Name):ListKeysAsync():GetCurrentPage() do
                releaseLock(dataStoreInfo.Name, keyInfo.KeyName)
            end
        end
    end)
    
    local dataStoreList = DataStoreService:ListDataStoresAsync()

    local success, errorMessage = pcall(function()
        while dataStoreList.IsFinished == false do
            for _, dataStoreInfo in dataStoreList:GetCurrentPage() do
                local dataStoreName = dataStoreInfo.Name
                
                -- Create datastore node
                local dataStoreNode = createTreeNode(dataStoreName, treeContainer, 0, true)
                
                -- Create a folder to put the data store keys
                local keysFolder = Instance.new("Frame")
                keysFolder.Name = "KeysFolder_" .. dataStoreName
                keysFolder.Size = UDim2.new(1, 0, 0, 0) -- Will be sized by the UIListLayout
                keysFolder.Visible = false
                keysFolder.BackgroundTransparency = 1
                keysFolder.Parent = treeContainer
                
                local keyLayout = Instance.new("UIListLayout")
                keyLayout.FillDirection = Enum.FillDirection.Vertical
                keyLayout.SortOrder = Enum.SortOrder.Name
                keyLayout.Parent = keysFolder
                
                -- Store reference to folder in node for expansion
                dataStoreNode:SetAttribute("FolderName", keysFolder.Name)
                
                -- Toggle expand/collapse on icon click
                local expandIcon = dataStoreNode:FindFirstChild("ExpandIcon")
                if expandIcon then
                    expandIcon.MouseButton1Click:Connect(function()
                        local expanded = dataStoreNode:GetAttribute("Expanded")
                        expanded = not expanded
                        dataStoreNode:SetAttribute("Expanded", expanded)
                        expandIcon.Text = expanded and "-" or "+"
                        keysFolder.Visible = expanded
                    end)
                end
                
                -- Also toggle when clicking on the node label
                dataStoreNode.NodeLabel.MouseButton1Click:Connect(function()
                    local expanded = dataStoreNode:GetAttribute("Expanded")
                    expanded = not expanded
                    dataStoreNode:SetAttribute("Expanded", expanded)
                    expandIcon.Text = expanded and "-" or "+"
                    keysFolder.Visible = expanded
                    
                    -- Load keys lazily when first expanded
                    if expanded and not dataStoreNode:GetAttribute("KeysLoaded") then
                        dataStoreNode:SetAttribute("KeysLoaded", true)
                        
                        -- Show loading indicator
                        local loadingNode = createTreeNode("Loading keys...", keysFolder, 1, false)
                        
                        -- Load keys in a separate thread
                        task.spawn(function()
                            local dataStore = DataStoreService:GetDataStore(dataStoreName)
                            local keyList = dataStore:ListKeysAsync()
                            
                            local keyNodes = {}
                            
                            while keyList.IsFinished == false do
                                for _, keyInfo in keyList:GetCurrentPage() do
                                    local keyNode = createTreeNode(keyInfo.KeyName, keysFolder, 1, false)
                                    table.insert(keyNodes, keyNode)
                                    
                                    keyNode.NodeLabel.MouseButton1Click:Connect(function()
                                        DataExplorer.displayKeyContent(dataStoreName, keyInfo.KeyName)
                                        
                                        -- Highlight the selected key
                                        for _, node in ipairs(keyNodes) do
                                            node.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                                        end
                                        keyNode.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
                                        
                                        if DataExplorer.currentKey then
                                            releaseLock(dataStoreName, DataExplorer.currentKey)
                                        end
                                        DataExplorer.currentKey = keyInfo.KeyName
                                        DataExplorer.updateLockStatusUI()
                                    end)
                                end
                                keyList:AdvanceToNextPageAsync()
                            end
                            
                            -- Remove loading indicator
                            if loadingNode and loadingNode.Parent then
                                loadingNode:Destroy()
                            end
                        end)
                    end
                end)
            end
            dataStoreList:AdvanceToNextPageAsync()
        end
    end)
    
    -- Implement search functionality
    searchBox.Changed:Connect(function(property)
        if property ~= "Text" then return end
        
        local searchText = searchBox.Text:lower()
        
        -- Show all nodes if search is empty
        if searchText == "" then
            for _, node in pairs(treeContainer:GetChildren()) do
                if node:IsA("Frame") and node.Name:match("^TreeNode_") then
                    node.Visible = true
                    
                    -- Hide all key folders by default
                    local folderName = node:GetAttribute("FolderName")
                    if folderName then
                        local folder = treeContainer:FindFirstChild(folderName)
                        if folder then
                            folder.Visible = node:GetAttribute("Expanded") or false
                        end
                    end
                end
            end
            return
        end
        
        -- Filter nodes based on search
        for _, node in pairs(treeContainer:GetChildren()) do
            if node:IsA("Frame") then
                if node.Name:match("^TreeNode_") then
                    -- This is a datastore node
                    local dataStoreName = node.NodeLabel.Text:lower()
                    local matches = dataStoreName:find(searchText, 1, true) ~= nil
                    node.Visible = matches
                    
                    -- Always expand datastore nodes during search
                    local folderName = node:GetAttribute("FolderName")
                    if folderName then
                        local folder = treeContainer:FindFirstChild(folderName)
                        if folder then
                            folder.Visible = matches
                            
                            -- For datastores that match, we'll further check their keys
                            if matches then
                                -- Load keys if not already loaded
                                if not node:GetAttribute("KeysLoaded") then
                                    node:SetAttribute("KeysLoaded", true)
                                    node:SetAttribute("Expanded", true)
                                    
                                    -- Trigger key loading
                                    node.NodeLabel.MouseButton1Click:Fire()
                                end
                            end
                        end
                    end
                elseif node.Name:match("^KeysFolder_") then
                    -- This is a key folder, show/hide individual keys
                    for _, keyNode in pairs(node:GetChildren()) do
                        if keyNode:IsA("Frame") and keyNode.Name:match("^TreeNode_") then
                            local keyName = keyNode.NodeLabel.Text:lower()
                            keyNode.Visible = keyName:find(searchText, 1, true) ~= nil
                        end
                    end
                end
            end
        end
    end)
    
    if not success then warn("Error populating data stores: ", errorMessage) end
end


return DataExplorer