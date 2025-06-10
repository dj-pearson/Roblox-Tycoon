--[[
    UIComponents - DataExplorer UI Component Manager
    Handles creation and management of basic UI components
]]

local RunService = game:GetService("RunService")

-- Safe module resolver
local function safeRequire(moduleName)
    local success, result = pcall(function()
        return require(script.Parent.Parent:FindFirstChild(moduleName))
    end)
    return success and result or {}
end

-- Import dependencies
local SessionManager = safeRequire("SessionManager")
local CacheManager = safeRequire("CacheManager")
local PerformanceMonitor = safeRequire("PerformanceMonitor")
local SessionManagementUI = safeRequire("SessionManagementUI")

local UIComponents = {}
local DataExplorer = nil

-- Initialize the module
function UIComponents.initialize(dataExplorerRef)
    DataExplorer = dataExplorerRef
    print("UIComponents: Initialized")
end

-- Helper function to create text labels
local function createLabel(text, parent)
    local label = Instance.new("TextButton")
    label.BorderSizePixel = 0
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.AutoButtonColor = false
    label.Text = text
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Parent = parent
    return label
end

-- Create the main UI frame
function UIComponents.createMainUI()
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    mainFrame.BorderSizePixel = 0
    DataExplorer.mainFrame = mainFrame

    -- Create split-pane layout
    local splitPane = Instance.new("ScrollingFrame")
    splitPane.Size = UDim2.new(1, 0, 1, 0)
    splitPane.Name = "SplitPane"
    splitPane.CanvasSize = UDim2.new(0, 0, 0, 0)
    splitPane.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    splitPane.ScrollBarInset = Enum.ScrollBarInset.Always
    splitPane.ElasticBehavior = Enum.ElasticBehavior.Never
    splitPane.Parent = mainFrame
    DataExplorer.splitPane = splitPane

    -- Create horizontal layout
    local horizontalLayout = Instance.new("UIListLayout")
    horizontalLayout.FillDirection = Enum.FillDirection.Horizontal
    horizontalLayout.SortOrder = Enum.SortOrder.LayoutOrder
    horizontalLayout.Parent = splitPane

    -- Create navigation pane
    UIComponents.createNavigationPane(splitPane)
    
    -- Create content pane
    UIComponents.createContentPane(splitPane)
    
    -- Create splitter
    UIComponents.createSplitter(mainFrame)
    
    -- Start UI update loops
    UIComponents.startUpdateLoops()
    
    return mainFrame
end

-- Create the navigation pane (tree view)
function UIComponents.createNavigationPane(parent)
    local navigationPane = Instance.new("Frame")
    navigationPane.Size = UDim2.new(0.3, 0, 1, 0)
    navigationPane.Name = "NavigationPane"
    navigationPane.Parent = parent
    DataExplorer.navigationPane = navigationPane

    local navigationLayout = Instance.new("UIListLayout")
    navigationLayout.FillDirection = Enum.FillDirection.Vertical
    navigationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navigationLayout.Parent = navigationPane
    
    -- Create performance pane
    UIComponents.createPerformancePane(navigationPane)
    
    -- Create cache viewer pane
    UIComponents.createCacheViewerPane(navigationPane)
    
    -- Create lock status pane
    UIComponents.createLockStatusPane(navigationPane)
    
    return navigationPane
end

-- Create performance data pane
function UIComponents.createPerformancePane(parent)
    local performancePane = Instance.new("Frame")
    performancePane.Size = UDim2.new(1, 0, 0.2, 0)
    performancePane.Position = UDim2.new(0, 0, 0.6, 0)
    performancePane.Name = "PerformancePane"
    performancePane.Parent = parent
    DataExplorer.performancePane = performancePane
    
    return performancePane
end

-- Create cache viewer pane
function UIComponents.createCacheViewerPane(parent)
    local cacheViewerPane = Instance.new("Frame")
    cacheViewerPane.Size = UDim2.new(1, 0, 0.4, 0)
    cacheViewerPane.Position = UDim2.new(0, 0, 1, 0)
    cacheViewerPane.Name = "CacheViewerPane"
    cacheViewerPane.Parent = parent
    DataExplorer.cacheViewerPane = cacheViewerPane
    
    return cacheViewerPane
end

-- Create lock status pane
function UIComponents.createLockStatusPane(parent)
    local lockStatusPane = Instance.new("Frame")
    lockStatusPane.Size = UDim2.new(1, 0, 0.2, 0)
    lockStatusPane.Position = UDim2.new(0, 0, 0.8, 0)
    lockStatusPane.Name = "LockStatusPane"
    lockStatusPane.Parent = parent
    DataExplorer.lockStatusPane = lockStatusPane

    -- Create title
    local lockStatusTitle = Instance.new("TextLabel")
    lockStatusTitle.Size = UDim2.new(1, -80, 0, 24)
    lockStatusTitle.Position = UDim2.new(0, 5, 0, 0)
    lockStatusTitle.BackgroundTransparency = 1
    lockStatusTitle.Text = "Session Locks"
    lockStatusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    lockStatusTitle.Font = Enum.Font.SourceSansBold
    lockStatusTitle.TextSize = 14
    lockStatusTitle.TextXAlignment = Enum.TextXAlignment.Left
    lockStatusTitle.Parent = lockStatusPane
    
    -- Create session management button
    local sessionManagementButton = Instance.new("TextButton")
    sessionManagementButton.Size = UDim2.new(0, 70, 0, 24)
    sessionManagementButton.Position = UDim2.new(1, -75, 0, 0)
    sessionManagementButton.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
    sessionManagementButton.BorderSizePixel = 0
    sessionManagementButton.Text = "Manage"
    sessionManagementButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    sessionManagementButton.Font = Enum.Font.SourceSansSemibold
    sessionManagementButton.TextSize = 14
    sessionManagementButton.Name = "SessionManagementButton"
    sessionManagementButton.Parent = lockStatusPane
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = sessionManagementButton
    
    -- Create content container
    local lockStatusContent = Instance.new("Frame")
    lockStatusContent.Size = UDim2.new(1, 0, 1, -24)
    lockStatusContent.Position = UDim2.new(0, 0, 0, 24)
    lockStatusContent.BackgroundTransparency = 1
    lockStatusContent.Name = "LockStatusContent"
    lockStatusContent.Parent = lockStatusPane
    DataExplorer.lockStatusContent = lockStatusContent
    
    local lockStatusLayout = Instance.new("UIListLayout")
    lockStatusLayout.FillDirection = Enum.FillDirection.Vertical
    lockStatusLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lockStatusLayout.Padding = UDim.new(0, 2)
    lockStatusLayout.Parent = lockStatusContent
    
    -- Connect session management button
    sessionManagementButton.MouseButton1Click:Connect(function()
        UIComponents.showSessionManagementUI()
    end)
    
    return lockStatusPane
end

-- Create content pane
function UIComponents.createContentPane(parent)
    local contentPane = Instance.new("ScrollingFrame")
    contentPane.Size = UDim2.new(0.7, 0, 1, 0)
    contentPane.Name = "ContentPane"
    contentPane.Parent = parent
    DataExplorer.contentPane = contentPane

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentPane
    
    return contentPane
end

-- Create splitter for resizing panes
function UIComponents.createSplitter(parent)
    local splitter = Instance.new("Frame")
    splitter.Size = UDim2.new(0, 5, 1, 0)
    splitter.Position = UDim2.new(0.3, -2.5, 0, 0)
    splitter.Name = "Splitter"
    splitter.Draggable = true
    splitter.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
    splitter.ZIndex = 2
    splitter.Parent = parent
    
    return splitter
end

-- Update cache viewer UI
function UIComponents.updateCacheViewerUI()
    local cacheViewerPane = DataExplorer.cacheViewerPane
    if not cacheViewerPane then return end

    -- Clear existing UI
    for _, child in ipairs(cacheViewerPane:GetChildren()) do
        child:Destroy()
    end

    -- Get cache contents
    local cacheContents = CacheManager.getCacheContents and CacheManager.getCacheContents() or {}

    if #cacheContents > 0 then
        for _, cacheEntry in ipairs(cacheContents) do
            local entryFrame = Instance.new("Frame")
            entryFrame.Size = UDim2.new(1, 0, 0, 20)
            entryFrame.BackgroundTransparency = 1
            entryFrame.Parent = cacheViewerPane

            local entryLayout = Instance.new("UIListLayout")
            entryLayout.FillDirection = Enum.FillDirection.Horizontal
            entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
            entryLayout.Parent = entryFrame
            
            local dataStoreLabel = createLabel(cacheEntry.dataStoreName or "Unknown", entryFrame)
            dataStoreLabel.Size = UDim2.new(0.2, 0, 1, 0)
            
            local keyLabel = createLabel(cacheEntry.keyName or "Unknown", entryFrame)
            keyLabel.Size = UDim2.new(0.3, 0, 1, 0)
            
            local sizeLabel = createLabel(string.format("%.2f KB", (cacheEntry.estimatedSize or 0) / 1024), entryFrame)
            sizeLabel.Size = UDim2.new(0.15, 0, 1, 0)
            
            local lastAccessedLabel = createLabel(os.date("%Y-%m-%d %H:%M:%S", cacheEntry.lastAccessed or 0), entryFrame)
            lastAccessedLabel.Size = UDim2.new(0.25, 0, 1, 0)
            
            local accessCountLabel = createLabel(tostring(cacheEntry.accessCount or 0), entryFrame)
            accessCountLabel.Size = UDim2.new(0.1, 0, 1, 0)
        end
    else
        local noDataLabel = createLabel("No data in cache", cacheViewerPane)
        noDataLabel.Parent = cacheViewerPane
    end
end

-- Update lock status UI
function UIComponents.updateLockStatusUI()
    local lockStatusContent = DataExplorer.lockStatusContent
    if not lockStatusContent then return end

    -- Clear existing lock status UI
    for _, child in ipairs(lockStatusContent:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    -- Get active locks
    local activeLocks = SessionManager.getActiveLocks and SessionManager.getActiveLocks() or {}

    if #activeLocks > 0 then
        for i, lockInfo in ipairs(activeLocks) do
            local lockFrame = Instance.new("Frame")
            lockFrame.Size = UDim2.new(1, -10, 0, 24)
            lockFrame.Position = UDim2.new(0, 5, 0, 0)
            lockFrame.BackgroundColor3 = lockInfo.isExpired and Color3.fromRGB(70, 30, 30) or Color3.fromRGB(35, 35, 40)
            lockFrame.BorderSizePixel = 0
            lockFrame.Name = "LockFrame_" .. i
            lockFrame.LayoutOrder = i
            lockFrame.Parent = lockStatusContent
            
            local frameCorner = Instance.new("UICorner")
            frameCorner.CornerRadius = UDim.new(0, 4)
            frameCorner.Parent = lockFrame
            
            -- Status indicator
            local statusIndicator = Instance.new("Frame")
            statusIndicator.Size = UDim2.new(0, 4, 1, 0)
            statusIndicator.Position = UDim2.new(0, 0, 0, 0)
            statusIndicator.BackgroundColor3 = lockInfo.isExpired and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 180, 80)
            statusIndicator.BorderSizePixel = 0
            statusIndicator.Parent = lockFrame
            
            local indicatorCorner = Instance.new("UICorner")
            indicatorCorner.CornerRadius = UDim.new(0, 4)
            indicatorCorner.Parent = statusIndicator
            
            -- Lock label
            local lockLabel = Instance.new("TextLabel")
            lockLabel.Size = UDim2.new(1, -70, 1, 0)
            lockLabel.Position = UDim2.new(0, 10, 0, 0)
            lockLabel.BackgroundTransparency = 1
            lockLabel.Text = (lockInfo.dataStoreName or "Unknown") .. ":" .. (lockInfo.keyName or "Unknown")
            lockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            lockLabel.Font = Enum.Font.Code
            lockLabel.TextSize = 14
            lockLabel.TextXAlignment = Enum.TextXAlignment.Left
            lockLabel.TextTruncate = Enum.TextTruncate.AtEnd
            lockLabel.Parent = lockFrame
            
            -- Force unlock button
            local forceUnlockButton = Instance.new("TextButton")
            forceUnlockButton.Size = UDim2.new(0, 60, 0, 20)
            forceUnlockButton.Position = UDim2.new(1, -65, 0.5, -10)
            forceUnlockButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            forceUnlockButton.BorderSizePixel = 0
            forceUnlockButton.Text = "Unlock"
            forceUnlockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            forceUnlockButton.Font = Enum.Font.SourceSans
            forceUnlockButton.TextSize = 14
            forceUnlockButton.Parent = lockFrame
            
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 4)
            buttonCorner.Parent = forceUnlockButton

            -- Force unlock function
            forceUnlockButton.MouseButton1Click:Connect(function()
                if SessionManager.forceReleaseLock then
                    SessionManager.forceReleaseLock(lockInfo.dataStoreName, lockInfo.keyName)
                    UIComponents.updateLockStatusUI()
                end
            end)
        end
    else
        local noLocksLabel = Instance.new("TextLabel")
        noLocksLabel.Size = UDim2.new(1, -10, 0, 24)
        noLocksLabel.Position = UDim2.new(0, 5, 0, 0)
        noLocksLabel.BackgroundTransparency = 1
        noLocksLabel.Text = "No active locks"
        noLocksLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        noLocksLabel.Font = Enum.Font.SourceSans
        noLocksLabel.TextSize = 14
        noLocksLabel.TextXAlignment = Enum.TextXAlignment.Center
        noLocksLabel.Parent = lockStatusContent
    end
end

-- Update performance data UI
function UIComponents.updatePerformanceDataUI()
    local performancePane = DataExplorer.performancePane
    if not performancePane then return end

    -- Clear existing performance data UI
    for _, child in ipairs(performancePane:GetChildren()) do    
        child:Destroy()
    end

    -- Display cache analytics
    local cacheAnalytics = CacheManager.getCacheAnalytics and CacheManager.getCacheAnalytics() or {hits = 0, misses = 0}
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
    hitRateLabel.Position = UDim2.new(0, 0, 0, 40)

    -- Add cache memory usage display
    local memoryUsage = CacheManager.estimateMemoryUsage and CacheManager.estimateMemoryUsage() or 0
    local memoryUsageLabel = createLabel("Cache Memory: " .. string.format("%.2f", memoryUsage / 1024) .. " KB", cacheFrame)
    memoryUsageLabel.Position = UDim2.new(0, 0, 0, 60)
    memoryUsageLabel.Parent = cacheFrame

    -- Get performance data
    local operationSummary = PerformanceMonitor.getOperationSummary and PerformanceMonitor.getOperationSummary() or {}

    if operationSummary and next(operationSummary) then
        for operationName, summary in pairs(operationSummary) do
            local operationFrame = Instance.new("Frame")
            operationFrame.Size = UDim2.new(1, 0, 0, 40)
            operationFrame.Position = UDim2.new(0, 0, 0, cacheFrame.Size.Y.Offset)
            operationFrame.BackgroundTransparency = 1
            operationFrame.Parent = performancePane

            local headerFrame = Instance.new("Frame")
            headerFrame.Size = UDim2.new(1, 0, 0, 20)
            headerFrame.BackgroundTransparency = 1
            headerFrame.Parent = operationFrame

            local rowFrame = Instance.new("Frame")
            rowFrame.Size = UDim2.new(1, 0, 0, 20)
            rowFrame.Position = UDim2.new(0, 0, 0, 20)
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
                headerLabel.Position = UDim2.new(headerOffset, 0, 0, 0)
                headerOffset = headerOffset + header.widthScale
            end

            -- Row labels (data)
            local rowLabels = {
                {value = operationName, widthScale = 0.3, color = (summary.averageDuration and summary.averageDuration > 0.5) and Color3.fromRGB(255, 100, 100) or nil},
                {value = tostring(summary.count or 0), widthScale = 0.2},
                {value = string.format("%.2fms", (summary.totalDuration or 0) * 1000), widthScale = 0.25},
                {value = string.format("%.2fms", (summary.averageDuration or 0) * 1000), widthScale = 0.25}
            }

            local rowOffset = 0
            for _, row in ipairs(rowLabels) do
                local rowLabel = createLabel(row.value, rowFrame)
                rowLabel.Size = UDim2.new(row.widthScale, 0, 1, 0)
                rowLabel.Position = UDim2.new(rowOffset, 0, 0, 0)
                rowLabel.TextColor3 = row.color or Color3.new(1, 1, 1)
                rowOffset = rowOffset + row.widthScale
            end   
        end
    else
        local noDataLabel = createLabel("No performance data yet.", performancePane)
        noDataLabel.Parent = performancePane
    end
end

-- Show session management UI
function UIComponents.showSessionManagementUI()
    -- Check if the UI already exists
    if DataExplorer.sessionManagementUI then
        -- Toggle visibility
        DataExplorer.sessionManagementUI.Visible = not DataExplorer.sessionManagementUI.Visible
        return
    end
    
    -- Create the session management UI
    local uiContainer = Instance.new("Frame")
    uiContainer.Name = "SessionManagementContainer"
    uiContainer.Size = UDim2.new(0.7, 0, 0.8, 0)
    uiContainer.Position = UDim2.new(0.15, 0, 0.1, 0)
    uiContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    uiContainer.BorderSizePixel = 0
    uiContainer.ZIndex = 100
    uiContainer.Parent = DataExplorer.mainFrame
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = uiContainer
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -32, 0, 8)
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextSize = 16
    closeButton.ZIndex = 101
    closeButton.Parent = uiContainer
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        uiContainer.Visible = false
    end)
    
    -- Create the session management UI inside the container
    if SessionManagementUI.createUI then
        local sessionManagementUI = SessionManagementUI.createUI(uiContainer)
        sessionManagementUI.Visible = true
        sessionManagementUI.Position = UDim2.new(0, 0, 0, 0)
        sessionManagementUI.Size = UDim2.new(1, 0, 1, 0)
        sessionManagementUI.Parent = uiContainer
    end
    
    DataExplorer.sessionManagementUI = uiContainer
end

-- Start UI update loops
function UIComponents.startUpdateLoops()
    -- Connect update functions to RunService
    RunService.Heartbeat:Connect(UIComponents.updatePerformanceDataUI)
    RunService.Heartbeat:Connect(UIComponents.updateCacheViewerUI)
end

return UIComponents 