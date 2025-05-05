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
    local lockAcquired = SessionManager.acquireLock(dataStoreName, keyName, DataExplorer.sessionId)



    if not contentPane then return end    

    -- Retrieve schema if exists for current datastore/key
    local currentSchema = SchemaManager.loadSchema(dataStoreName, keyName)


    if currentSchema then
        -- Create a validation message label
        local validationMessageLabel = Instance.new("TextLabel")
        validationMessageLabel.Name = "ValidationMessage"
        validationMessageLabel.Size = UDim2.new(1, 0, 0, 30)
        validationMessageLabel.Position = UDim2.new(0, 10, 0, 0)
        validationMessageLabel.BackgroundColor3 = Color3.new(1, 1, 1)
        validationMessageLabel.TextColor3 = Color3.new(1, 0, 0)
        validationMessageLabel.Visible = false
        validationMessageLabel.Parent = contentPane
    end

    local saveButton = Instance.new("TextButton")
    saveButton.Size = UDim2.new(0, 100, 0, 30)
    saveButton.Position = UDim2.new(1, -100, 0, 0)
    saveButton.Text = "Save"   
    saveButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
    saveButton.TextColor3 = Color3.new(1, 1, 1)
    saveButton.Parent = contentPane

    -- Clear the content pane
    for _, child in ipairs(contentPane:GetChildren()) do
        child:Destroy()
    end
    if not lockAcquired then
        local lockedLabel = createLabel("Locked by another user", contentPane)        
        lockedLabel.Parent = contentPane
    end
    local dataStore = DataStoreService:GetDataStore(dataStoreName)

    local success, data, operationDuration = PerformanceMonitor.timeOperation("GetAsync", function() return pcall(dataStore.GetAsync, dataStore, keyName) end)
    -- Check cache before fetching from DataStore
    data = CacheManager.get(dataStoreName, keyName) or data
    if success and data then
        -- Convert data to a JSON-encoded string for editing
        local encodedData = HttpService:JSONEncode(data)

        -- Create a TextBoxes for editing the data
        
        -- Add save Button
        local function saveData()
            local dataTextBox = contentPane:FindFirstChild("DataTextBox")   
            if not dataTextBox then return end

            local validationMessageLabel = contentPane:FindFirstChild("ValidationMessage")
            local success, decodedData = pcall(HttpService.JSONDecode, HttpService, dataTextBox.Text)
            
            -- Validate data before saving            
            if currentSchema then
                local validationError = SchemaManager.validateData(decodedData, currentSchema)
                if validationError then
                    if validationMessageLabel then
                        validationMessageLabel.Visible = true
                        validationMessageLabel.Text = "Data validation failed: " .. validationError
                    end
                    return 
                end
            end
            if success then
                local success2, _, operationDuration2 = PerformanceMonitor.timeOperation("SetAsync", function() return pcall(dataStore.SetAsync, dataStore, keyName, decodedData) end)
                print("Operation: SetAsync, Duration:", operationDuration2)
                CacheManager.invalidate(dataStoreName, keyName)




            else
                warn("Invalid JSON: ", decodedData)
                if validationMessageLabel then
                    validationMessageLabel.Visible = true
                    validationMessageLabel.Text = "Invalid JSON: " .. tostring(decodedData)
                end
            end
        end
        print("Operation: GetAsync, Duration:", operationDuration)

        saveButton.MouseButton1Click:Connect(saveData)        

        local dataTextBox = Instance.new("TextBox")
        dataTextBox.Size = UDim2.new(1, 0, 1, 0)
        dataTextBox.Text = encodedData -- Use the JSON-encoded string
        dataTextBox.Font = Enum.Font.Code
        dataTextBox.TextSize = 14
        dataTextBox.TextWrapped = true
        dataTextBox.MultiLine = true
        dataTextBox.Name = "DataTextBox"
        dataTextBox.Parent = contentPane
        dataTextBox.Size = UDim2.new(1, -10, 1, 0)
        dataTextBox.Position = UDim2.new(0, 10, 0, 30)
    else
        warn("Error fetching data for key: ", keyName)
    end
    if success then
    end
    

end

function DataExplorer.populateDataStores()
	local navigationPane = DataExplorer.navigationPane
	if not navigationPane then return end
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
                local dataStoreLabel = createLabel(dataStoreName, navigationPane)
                dataStoreLabel.Parent = navigationPane

                -- Create a folder to put the data store keys
                local keysFolder = Instance.new("Frame")
                keysFolder.Name = "KeysFolder"
                keysFolder.Size = UDim2.new(1, 0, 0, 0)

                keysFolder.Visible = false
                keysFolder.BackgroundTransparency = 1
                keysFolder.Parent = navigationPane
                local keyLayout = Instance.new("UIListLayout")
                keyLayout.FillDirection = Enum.FillDirection.Vertical
                keyLayout.SortOrder = Enum.SortOrder.LayoutOrder
                keyLayout.Parent = keysFolder

                dataStoreLabel.MouseButton1Click:Connect(function()
                    keysFolder.Visible = not keysFolder.Visible
                end)

                local dataStore = DataStoreService:GetDataStore(dataStoreName)
                local keyList = dataStore:ListKeysAsync()
                while keyList.IsFinished == false do
                    for _, keyInfo in keyList:GetCurrentPage() do
                        local keyLabel = createLabel("    " .. keyInfo.KeyName, keysFolder)
                        keyLabel.Parent = keysFolder
                        keyLabel.MouseButton1Click:Connect(function()
                            DataExplorer.displayKeyContent(dataStoreName, keyInfo.KeyName)

							if DataExplorer.currentKey then
								releaseLock(dataStoreName,DataExplorer.currentKey)
							end
                            DataExplorer.updateLockStatusUI()
                        end)
                    end
                    keyList:AdvanceToNextPageAsync()
                end
			end
			dataStoreList:AdvanceToNextPageAsync()
		end

	end)
	if not success then warn("Error populating data stores: ", errorMessage) end
end


return DataExplorer