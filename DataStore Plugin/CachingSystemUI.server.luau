--[[
    CachingSystemUI.luau
    Part of DataStore Manager Pro
    
    This module provides the user interface for the Caching System feature,
    allowing developers to visualize and manage caching for DataStore operations.
]]

local StyleGuide = require(script.Parent.StyleGuide)
local DataVisualization = require(script.Parent.DataVisualization)
local CacheManager = require(script.Parent.CacheManager)

local CachingSystemUI = {}

-- Reference to UI components
CachingSystemUI.container = nil
CachingSystemUI.tabs = {}
CachingSystemUI.charts = {}

-- Initialize the Caching System UI
function CachingSystemUI.initialize()
    print("CachingSystemUI: Initializing UI components...")
    return true
end

-- Create the main Caching System UI
function CachingSystemUI.createUI(container)
    CachingSystemUI.container = container
    
    -- Create the main layout
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.Padding = UDim.new(0, 10)
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Parent = container
    
    -- Create tab buttons for different sections
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 0, 40)
    tabContainer.BackgroundTransparency = 1
    tabContainer.LayoutOrder = 1
    tabContainer.Name = "TabContainer"
    tabContainer.Parent = container
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabContainer
    
    -- Create content container for tab content
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, 0, 1, -50)
    contentContainer.Position = UDim2.new(0, 0, 0, 50)
    contentContainer.BackgroundTransparency = 1
    contentContainer.LayoutOrder = 2
    contentContainer.Name = "ContentContainer"
    contentContainer.Parent = container
    
    -- Create the tabs and their content
    CachingSystemUI.createDashboardTab(tabContainer, contentContainer)
    CachingSystemUI.createCacheManagerTab(tabContainer, contentContainer)
    CachingSystemUI.createSettingsTab(tabContainer, contentContainer)
    
    -- Select the first tab by default
    CachingSystemUI.selectTab("Dashboard")
    
    -- Set up periodic UI updates
    task.spawn(function()
        while true do
            CachingSystemUI.updateUI()
            task.wait(3) -- Update every 3 seconds
        end
    end)
end

-- Create the Dashboard tab
function CachingSystemUI.createDashboardTab(tabContainer, contentContainer)
    -- Create tab button
    local tabButton = StyleGuide.createTabButton("Dashboard", 1)
    tabButton.Parent = tabContainer
    
    -- Create tab content
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 6
    tabContent.Visible = false
    tabContent.Name = "DashboardTab"
    tabContent.Parent = contentContainer
    
    -- Create layout for tab content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tabContent
    
    -- Create cache statistics section
    local statsSection = StyleGuide.createSection("Cache Statistics", 1)
    statsSection.Size = UDim2.new(1, -20, 0, 150)
    statsSection.Parent = tabContent
    
    -- Create a dashboard style display of cache stats
    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(1, -20, 1, -40)
    statsContainer.Position = UDim2.new(0, 10, 0, 30)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Name = "StatsContainer"
    statsContainer.Parent = statsSection
    
    local statsLayout = Instance.new("UIGridLayout")
    statsLayout.CellSize = UDim2.new(0.25, -10, 1, 0)
    statsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    statsLayout.Parent = statsContainer
    
    -- Create stat boxes
    local hitRateBox = CachingSystemUI.createStatBox("Hit Rate", "0%", Color3.fromRGB(52, 152, 219), statsContainer)
    hitRateBox.LayoutOrder = 1
    hitRateBox.Name = "HitRateBox"
    
    local entriesBox = CachingSystemUI.createStatBox("Cache Entries", "0", Color3.fromRGB(46, 204, 113), statsContainer)
    entriesBox.LayoutOrder = 2
    entriesBox.Name = "EntriesBox"
    
    local memoryBox = CachingSystemUI.createStatBox("Memory Usage", "0 KB", Color3.fromRGB(155, 89, 182), statsContainer)
    memoryBox.LayoutOrder = 3
    memoryBox.Name = "MemoryBox"
    
    local efficiencyBox = CachingSystemUI.createStatBox("Efficiency", "0%", Color3.fromRGB(230, 126, 34), statsContainer)
    efficiencyBox.LayoutOrder = 4
    efficiencyBox.Name = "EfficiencyBox"
    
    -- Create cache performance trend chart
    local trendsChartContainer = StyleGuide.createSection("Cache Performance Trends", 2)
    trendsChartContainer.Size = UDim2.new(1, -20, 0, 250)
    trendsChartContainer.Parent = tabContent
    
    -- Create placeholder for chart (will be populated during updateUI)
    local trendsChartFrame = Instance.new("Frame")
    trendsChartFrame.Size = UDim2.new(1, -20, 1, -40)
    trendsChartFrame.Position = UDim2.new(0, 10, 0, 30)
    trendsChartFrame.BackgroundTransparency = 1
    trendsChartFrame.Name = "TrendsChartFrame"
    trendsChartFrame.Parent = trendsChartContainer
    
    -- Store reference to chart frame for later use
    CachingSystemUI.charts.trends = trendsChartFrame
    
    -- Create cache contents section
    local contentsSection = StyleGuide.createSection("Most Active Cache Entries", 3)
    contentsSection.Size = UDim2.new(1, -20, 0, 300)
    contentsSection.Parent = tabContent
    
    -- Create the entries table
    local entriesTableFrame = Instance.new("Frame")
    entriesTableFrame.Size = UDim2.new(1, -20, 1, -40)
    entriesTableFrame.Position = UDim2.new(0, 10, 0, 30)
    entriesTableFrame.BackgroundTransparency = 1
    entriesTableFrame.Name = "EntriesTableFrame"
    entriesTableFrame.Parent = contentsSection
    
    -- Store reference to table for later use
    CachingSystemUI.entriesTable = entriesTableFrame
    
    -- Store tab information
    CachingSystemUI.tabs.Dashboard = {
        button = tabButton,
        content = tabContent
    }
    
    -- Add button click handler
    tabButton.MouseButton1Click:Connect(function()
        CachingSystemUI.selectTab("Dashboard")
    end)
end

-- Create the Cache Manager tab
function CachingSystemUI.createCacheManagerTab(tabContainer, contentContainer)
    -- Create tab button
    local tabButton = StyleGuide.createTabButton("Cache Manager", 2)
    tabButton.Parent = tabContainer
    
    -- Create tab content
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 6
    tabContent.Visible = false
    tabContent.Name = "CacheManagerTab"
    tabContent.Parent = contentContainer
    
    -- Create layout for tab content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tabContent
    
    -- Create cache search and filter section
    local searchSection = StyleGuide.createSection("Search & Filter Cache Entries", 1)
    searchSection.Size = UDim2.new(1, -20, 0, 120)
    searchSection.Parent = tabContent
    
    -- Create search input
    local searchLabel = StyleGuide.createLabel("Search:", 1)
    searchLabel.Size = UDim2.new(0, 80, 0, 30)
    searchLabel.Position = UDim2.new(0, 10, 0, 40)
    searchLabel.Parent = searchSection
    
    local searchInput = StyleGuide.createTextInput("Enter DataStore or key name")
    searchInput.Size = UDim2.new(0.5, -100, 0, 30)
    searchInput.Position = UDim2.new(0, 90, 0, 40)
    searchInput.Name = "SearchInput"
    searchInput.Parent = searchSection
    
    -- Create filter options
    local filterLabel = StyleGuide.createLabel("Filter by:", 2)
    filterLabel.Size = UDim2.new(0, 80, 0, 30)
    filterLabel.Position = UDim2.new(0.5, 10, 0, 40)
    filterLabel.Parent = searchSection
    
    local filterDropdown = StyleGuide.createDropdown({"All Entries", "Most Accessed", "Least Accessed", "Newest", "Oldest"})
    filterDropdown.Size = UDim2.new(0.5, -100, 0, 30)
    filterDropdown.Position = UDim2.new(0.5, 90, 0, 40)
    filterDropdown.Name = "FilterDropdown"
    filterDropdown.Parent = searchSection
    
    local searchButton = StyleGuide.createButton("Search", true)
    searchButton.Size = UDim2.new(0, 100, 0, 30)
    searchButton.Position = UDim2.new(0.5, -50, 0, 80)
    searchButton.Name = "SearchButton"
    searchButton.Parent = searchSection
    
    -- Create cache entries section
    local entriesSection = StyleGuide.createSection("Cache Entries", 2)
    entriesSection.Size = UDim2.new(1, -20, 0, 500)
    entriesSection.Parent = tabContent
    
    -- Create entries list container
    local entriesListFrame = Instance.new("ScrollingFrame")
    entriesListFrame.Size = UDim2.new(1, -20, 1, -40)
    entriesListFrame.Position = UDim2.new(0, 10, 0, 30)
    entriesListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    entriesListFrame.BorderSizePixel = 0
    entriesListFrame.ScrollBarThickness = 6
    entriesListFrame.Name = "EntriesListFrame"
    entriesListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    entriesListFrame.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    entriesListFrame.Parent = entriesSection
    
    -- Create layout for entries list
    local entriesLayout = Instance.new("UIListLayout")
    entriesLayout.Padding = UDim.new(0, 2)
    entriesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    entriesLayout.Parent = entriesListFrame
    
    -- Create header for entries
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 30)
    headerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    headerFrame.LayoutOrder = 0
    headerFrame.Name = "HeaderFrame"
    headerFrame.Parent = entriesListFrame
    
    -- Create header columns
    local datastoreHeader = StyleGuide.createLabel("DataStore", 1)
    datastoreHeader.Size = UDim2.new(0.25, -5, 1, 0)
    datastoreHeader.Position = UDim2.new(0, 5, 0, 0)
    datastoreHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
    datastoreHeader.Font = Enum.Font.SourceSansBold
    datastoreHeader.Parent = headerFrame
    
    local keyHeader = StyleGuide.createLabel("Key", 2)
    keyHeader.Size = UDim2.new(0.25, -5, 1, 0)
    keyHeader.Position = UDim2.new(0.25, 5, 0, 0)
    keyHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
    keyHeader.Font = Enum.Font.SourceSansBold
    keyHeader.Parent = headerFrame
    
    local accessHeader = StyleGuide.createLabel("Access Count", 3)
    accessHeader.Size = UDim2.new(0.15, -5, 1, 0)
    accessHeader.Position = UDim2.new(0.5, 5, 0, 0)
    accessHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
    accessHeader.Font = Enum.Font.SourceSansBold
    accessHeader.Parent = headerFrame
    
    local sizeHeader = StyleGuide.createLabel("Size", 4)
    sizeHeader.Size = UDim2.new(0.15, -5, 1, 0)
    sizeHeader.Position = UDim2.new(0.65, 5, 0, 0)
    sizeHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
    sizeHeader.Font = Enum.Font.SourceSansBold
    sizeHeader.Parent = headerFrame
    
    local actionsHeader = StyleGuide.createLabel("Actions", 5)
    actionsHeader.Size = UDim2.new(0.2, -5, 1, 0)
    actionsHeader.Position = UDim2.new(0.8, 5, 0, 0)
    actionsHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
    actionsHeader.Font = Enum.Font.SourceSansBold
    actionsHeader.Parent = headerFrame
    
    -- Create action buttons section
    local actionsSection = StyleGuide.createSection("Cache Actions", 3)
    actionsSection.Size = UDim2.new(1, -20, 0, 100)
    actionsSection.Parent = tabContent
    
    -- Create action buttons
    local clearCacheButton = StyleGuide.createButton("Clear All Cache", false)
    clearCacheButton.Size = UDim2.new(0.3, -15, 0, 40)
    clearCacheButton.Position = UDim2.new(0, 10, 0, 40)
    clearCacheButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
    clearCacheButton.Name = "ClearCacheButton"
    clearCacheButton.Parent = actionsSection
    
    local optimizeCacheButton = StyleGuide.createButton("Optimize Cache", true)
    optimizeCacheButton.Size = UDim2.new(0.3, -15, 0, 40)
    optimizeCacheButton.Position = UDim2.new(0.35, 10, 0, 40)
    optimizeCacheButton.Name = "OptimizeCacheButton"
    optimizeCacheButton.Parent = actionsSection
    
    local preloadDataButton = StyleGuide.createButton("Preload Data", true)
    preloadDataButton.Size = UDim2.new(0.3, -15, 0, 40)
    preloadDataButton.Position = UDim2.new(0.7, 10, 0, 40)
    preloadDataButton.Name = "PreloadDataButton"
    preloadDataButton.Parent = actionsSection
    
    -- Store tab information
    CachingSystemUI.tabs.CacheManager = {
        button = tabButton,
        content = tabContent,
        entriesListFrame = entriesListFrame,
        searchInput = searchInput,
        filterDropdown = filterDropdown
    }
    
    -- Add button click handler
    tabButton.MouseButton1Click:Connect(function()
        CachingSystemUI.selectTab("CacheManager")
    end)
    
    -- Add search button handler
    searchButton.MouseButton1Click:Connect(function()
        CachingSystemUI.updateCacheEntries(searchInput.Text, filterDropdown.Selection)
    end)
    
    -- Add clear cache button handler
    clearCacheButton.MouseButton1Click:Connect(function()
        -- Create a confirmation dialog
        local confirmDialog = StyleGuide.createConfirmDialog(
            "Clear Cache",
            "Are you sure you want to clear all cache entries? This cannot be undone.",
            function()
                CacheManager.clearCache()
                CachingSystemUI.updateCacheEntries("", "All Entries")
                StyleGuide.showNotification("Cache has been cleared", "success")
            end
        )
        confirmDialog.Parent = CachingSystemUI.container
    end)
    
    -- Add optimize cache button handler
    optimizeCacheButton.MouseButton1Click:Connect(function()
        CacheManager.optimizeCache()
        CachingSystemUI.updateCacheEntries(searchInput.Text, filterDropdown.Selection)
        StyleGuide.showNotification("Cache has been optimized", "success")
    end)
    
    -- Add preload data button handler
    preloadDataButton.MouseButton1Click:Connect(function()
        -- Show preload dialog
        CachingSystemUI.showPreloadDialog()
    end)
end

-- Create the Settings tab
function CachingSystemUI.createSettingsTab(tabContainer, contentContainer)
    -- Create tab button
    local tabButton = StyleGuide.createTabButton("Settings", 3)
    tabButton.Parent = tabContainer
    
    -- Create tab content
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 6
    tabContent.Visible = false
    tabContent.Name = "SettingsTab"
    tabContent.Parent = contentContainer
    
    -- Create layout for tab content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tabContent
    
    -- Create cache settings section
    local settingsSection = StyleGuide.createSection("Cache Configuration", 1)
    settingsSection.Size = UDim2.new(1, -20, 0, 350)
    settingsSection.Parent = tabContent
    
    -- Create a layout for the settings section
    local settingsLayout = Instance.new("UIListLayout")
    settingsLayout.Padding = UDim.new(0, 20)
    settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    settingsLayout.Parent = settingsSection
    
    -- Create settings for max entries
    local maxEntriesLabel = StyleGuide.createLabel("Maximum Cache Entries", 1)
    maxEntriesLabel.Size = UDim2.new(1, -20, 0, 20)
    maxEntriesLabel.Position = UDim2.new(0, 10, 0, 30)
    maxEntriesLabel.Parent = settingsSection
    
    local maxEntriesInput = StyleGuide.createTextInput(tostring(CacheManager.config.maxEntries))
    maxEntriesInput.Size = UDim2.new(0.5, -20, 0, 30)
    maxEntriesInput.Position = UDim2.new(0, 10, 0, 55)
    maxEntriesInput.Name = "MaxEntriesInput"
    maxEntriesInput.Parent = settingsSection
    
    -- Create settings for default TTL
    local defaultTTLLabel = StyleGuide.createLabel("Default Time-to-Live (seconds)", 2)
    defaultTTLLabel.Size = UDim2.new(1, -20, 0, 20)
    defaultTTLLabel.Position = UDim2.new(0, 10, 0, 95)
    defaultTTLLabel.Parent = settingsSection
    
    local defaultTTLInput = StyleGuide.createTextInput(tostring(CacheManager.config.defaultTTL))
    defaultTTLInput.Size = UDim2.new(0.5, -20, 0, 30)
    defaultTTLInput.Position = UDim2.new(0, 10, 0, 120)
    defaultTTLInput.Name = "DefaultTTLInput"
    defaultTTLInput.Parent = settingsSection
    
    -- Create settings for eviction policy
    local evictionPolicyLabel = StyleGuide.createLabel("Cache Eviction Policy", 3)
    evictionPolicyLabel.Size = UDim2.new(1, -20, 0, 20)
    evictionPolicyLabel.Position = UDim2.new(0, 10, 0, 160)
    evictionPolicyLabel.Parent = settingsSection
    
    local evictionPolicyDropdown = StyleGuide.createDropdown({"LRU", "LFU", "FIFO"})
    evictionPolicyDropdown.Size = UDim2.new(0.5, -20, 0, 30)
    evictionPolicyDropdown.Position = UDim2.new(0, 10, 0, 185)
    evictionPolicyDropdown.Name = "EvictionPolicyDropdown"
    evictionPolicyDropdown.Parent = settingsSection
    
    -- Create settings for auto-preload
    local autoPreloadLabel = StyleGuide.createLabel("Auto-Preload Frequently Used Data", 4)
    autoPreloadLabel.Size = UDim2.new(1, -20, 0, 20)
    autoPreloadLabel.Position = UDim2.new(0, 10, 0, 225)
    autoPreloadLabel.Parent = settingsSection
    
    local autoPreloadToggle = StyleGuide.createToggle(CacheManager.config.autoPreload)
    autoPreloadToggle.Position = UDim2.new(0, 10, 0, 250)
    autoPreloadToggle.Name = "AutoPreloadToggle"
    autoPreloadToggle.Parent = settingsSection
    
    -- Create settings for memory limit
    local memoryLimitLabel = StyleGuide.createLabel("Memory Limit (KB)", 5)
    memoryLimitLabel.Size = UDim2.new(1, -20, 0, 20)
    memoryLimitLabel.Position = UDim2.new(0, 10, 0, 280)
    memoryLimitLabel.Parent = settingsSection
    
    local memoryLimitInput = StyleGuide.createTextInput(tostring(CacheManager.config.memoryLimit))
    memoryLimitInput.Size = UDim2.new(0.5, -20, 0, 30)
    memoryLimitInput.Position = UDim2.new(0, 10, 0, 305)
    memoryLimitInput.Name = "MemoryLimitInput"
    memoryLimitInput.Parent = settingsSection
    
    -- Create save settings button
    local saveButton = StyleGuide.createButton("Save Settings", true)
    saveButton.Size = UDim2.new(0.4, 0, 0, 40)
    saveButton.Position = UDim2.new(0.3, 0, 0, 350)
    saveButton.Name = "SaveSettingsButton"
    saveButton.Parent = settingsSection
    
    -- Create cache rules section
    local rulesSection = StyleGuide.createSection("Cache Rules", 2)
    rulesSection.Size = UDim2.new(1, -20, 0, 350)
    rulesSection.Parent = tabContent
    
    -- Create rules list
    local rulesListFrame = Instance.new("ScrollingFrame")
    rulesListFrame.Size = UDim2.new(1, -20, 0, 150)
    rulesListFrame.Position = UDim2.new(0, 10, 0, 40)
    rulesListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    rulesListFrame.BorderSizePixel = 0
    rulesListFrame.ScrollBarThickness = 6
    rulesListFrame.Name = "RulesListFrame"
    rulesListFrame.Parent = rulesSection
    
    -- Create layout for rules list
    local rulesLayout = Instance.new("UIListLayout")
    rulesLayout.Padding = UDim.new(0, 2)
    rulesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rulesLayout.Parent = rulesListFrame
    
    -- Create "Add Rule" button
    local addRuleButton = StyleGuide.createButton("Add Cache Rule", true)
    addRuleButton.Size = UDim2.new(0.4, 0, 0, 40)
    addRuleButton.Position = UDim2.new(0.3, 0, 0, 200)
    addRuleButton.Name = "AddRuleButton"
    addRuleButton.Parent = rulesSection
    
    -- Create rule editor (initially hidden)
    local ruleEditorFrame = Instance.new("Frame")
    ruleEditorFrame.Size = UDim2.new(1, -20, 0, 200)
    ruleEditorFrame.Position = UDim2.new(0, 10, 0, 250)
    ruleEditorFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    ruleEditorFrame.BorderSizePixel = 0
    ruleEditorFrame.Visible = false
    ruleEditorFrame.Name = "RuleEditorFrame"
    ruleEditorFrame.Parent = rulesSection
    
    -- Create rule editor content
    local ruleTypeLabel = StyleGuide.createLabel("Rule Type:", 1)
    ruleTypeLabel.Size = UDim2.new(0.3, 0, 0, 30)
    ruleTypeLabel.Position = UDim2.new(0, 10, 0, 10)
    ruleTypeLabel.Parent = ruleEditorFrame
    
    local ruleTypeDropdown = StyleGuide.createDropdown({"DataStore Pattern", "Key Pattern", "Exclude Pattern"})
    ruleTypeDropdown.Size = UDim2.new(0.65, -20, 0, 30)
    ruleTypeDropdown.Position = UDim2.new(0.3, 10, 0, 10)
    ruleTypeDropdown.Name = "RuleTypeDropdown"
    ruleTypeDropdown.Parent = ruleEditorFrame
    
    local patternLabel = StyleGuide.createLabel("Pattern:", 2)
    patternLabel.Size = UDim2.new(0.3, 0, 0, 30)
    patternLabel.Position = UDim2.new(0, 10, 0, 50)
    patternLabel.Parent = ruleEditorFrame
    
    local patternInput = StyleGuide.createTextInput("Enter pattern (e.g., PlayerData_*)")
    patternInput.Size = UDim2.new(0.65, -20, 0, 30)
    patternInput.Position = UDim2.new(0.3, 10, 0, 50)
    patternInput.Name = "PatternInput"
    patternInput.Parent = ruleEditorFrame
    
    local ttlLabel = StyleGuide.createLabel("TTL (seconds):", 3)
    ttlLabel.Size = UDim2.new(0.3, 0, 0, 30)
    ttlLabel.Position = UDim2.new(0, 10, 0, 90)
    ttlLabel.Parent = ruleEditorFrame
    
    local ttlInput = StyleGuide.createTextInput("300")
    ttlInput.Size = UDim2.new(0.65, -20, 0, 30)
    ttlInput.Position = UDim2.new(0.3, 10, 0, 90)
    ttlInput.Name = "TTLInput"
    ttlInput.Parent = ruleEditorFrame
    
    local priorityLabel = StyleGuide.createLabel("Priority:", 4)
    priorityLabel.Size = UDim2.new(0.3, 0, 0, 30)
    priorityLabel.Position = UDim2.new(0, 10, 0, 130)
    priorityLabel.Parent = ruleEditorFrame
    
    local prioritySlider = StyleGuide.createSlider(1, 10, 5)
    prioritySlider.Size = UDim2.new(0.65, -20, 0, 30)
    prioritySlider.Position = UDim2.new(0.3, 10, 0, 130)
    prioritySlider.Name = "PrioritySlider"
    prioritySlider.Parent = ruleEditorFrame
    
    local saveRuleButton = StyleGuide.createButton("Save Rule", true)
    saveRuleButton.Size = UDim2.new(0.3, 0, 0, 30)
    saveRuleButton.Position = UDim2.new(0.2, 0, 0, 170)
    saveRuleButton.Name = "SaveRuleButton"
    saveRuleButton.Parent = ruleEditorFrame
    
    local cancelRuleButton = StyleGuide.createButton("Cancel", false)
    cancelRuleButton.Size = UDim2.new(0.3, 0, 0, 30)
    cancelRuleButton.Position = UDim2.new(0.5, 10, 0, 170)
    cancelRuleButton.Name = "CancelRuleButton"
    cancelRuleButton.Parent = ruleEditorFrame
    
    -- Store tab information
    CachingSystemUI.tabs.Settings = {
        button = tabButton,
        content = tabContent,
        rulesListFrame = rulesListFrame,
        ruleEditorFrame = ruleEditorFrame,
        settingsInputs = {
            maxEntries = maxEntriesInput,
            defaultTTL = defaultTTLInput,
            evictionPolicy = evictionPolicyDropdown,
            autoPreload = autoPreloadToggle,
            memoryLimit = memoryLimitInput
        }
    }
    
    -- Add button click handler
    tabButton.MouseButton1Click:Connect(function()
        CachingSystemUI.selectTab("Settings")
    end)
    
    -- Add save settings button handler
    saveButton.MouseButton1Click:Connect(function()
        -- Get input values
        local maxEntries = tonumber(maxEntriesInput.Text) or CacheManager.config.maxEntries
        local defaultTTL = tonumber(defaultTTLInput.Text) or CacheManager.config.defaultTTL
        local evictionPolicy = evictionPolicyDropdown.Selection or CacheManager.config.evictionPolicy
        local autoPreload = autoPreloadToggle.Value
        local memoryLimit = tonumber(memoryLimitInput.Text) or CacheManager.config.memoryLimit
        
        -- Update cache configuration
        CacheManager.configure({
            maxEntries = maxEntries,
            defaultTTL = defaultTTL,
            evictionPolicy = evictionPolicy,
            autoPreload = autoPreload,
            memoryLimit = memoryLimit
        })
        
        StyleGuide.showNotification("Cache settings saved", "success")
    end)
    
    -- Add add rule button handler
    addRuleButton.MouseButton1Click:Connect(function()
        ruleEditorFrame.Visible = true
    end)
    
    -- Add cancel rule button handler
    cancelRuleButton.MouseButton1Click:Connect(function()
        ruleEditorFrame.Visible = false
    end)
    
    -- Add save rule button handler
    saveRuleButton.MouseButton1Click:Connect(function()
        -- Get input values
        local ruleType = ruleTypeDropdown.Selection
        local pattern = patternInput.Text
        local ttl = tonumber(ttlInput.Text) or 300
        local priority = prioritySlider.Value
        
        if pattern == "" then
            StyleGuide.showNotification("Please enter a pattern", "warning")
            return
        end
        
        -- Add rule to cache manager
        CacheManager.addCacheRule({
            type = ruleType,
            pattern = pattern,
            ttl = ttl,
            priority = priority
        })
        
        -- Hide rule editor and update rules list
        ruleEditorFrame.Visible = false
        CachingSystemUI.updateRulesList()
        
        StyleGuide.showNotification("Cache rule added", "success")
    end)
    
    -- Initialize rules list
    CachingSystemUI.updateRulesList()
end

-- Create a stat box for the dashboard
function CachingSystemUI.createStatBox(title, value, color, parent)
    local statBox = Instance.new("Frame")
    statBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    statBox.BorderSizePixel = 0
    statBox.Parent = parent
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = statBox
    
    -- Add color indicator
    local colorIndicator = Instance.new("Frame")
    colorIndicator.Size = UDim2.new(1, 0, 0, 4)
    colorIndicator.Position = UDim2.new(0, 0, 0, 0)
    colorIndicator.BackgroundColor3 = color
    colorIndicator.BorderSizePixel = 0
    colorIndicator.Name = "ColorIndicator"
    colorIndicator.Parent = statBox
    
    -- Add rounded corners to indicator
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 6)
    indicatorCorner.Parent = colorIndicator
    
    -- Add title
    local titleLabel = StyleGuide.createLabel(title, 1)
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.new(0, 10, 0, 15)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.Parent = statBox
    
    -- Add value
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, -20, 0, 40)
    valueLabel.Position = UDim2.new(0, 10, 0, 40)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = value
    valueLabel.TextColor3 = color
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Font = Enum.Font.SourceSansBold
    valueLabel.TextSize = 28
    valueLabel.Name = "ValueLabel"
    valueLabel.Parent = statBox
    
    return statBox
end

-- Select a tab to display
function CachingSystemUI.selectTab(tabName)
    for name, tab in pairs(CachingSystemUI.tabs) do
        if name == tabName then
            tab.button.BackgroundColor3 = StyleGuide.Colors.Primary
            tab.content.Visible = true
        else
            tab.button.BackgroundColor3 = StyleGuide.Colors.Button
            tab.content.Visible = false
        end
    end
    
    -- Refresh the UI for the selected tab
    CachingSystemUI.updateUI()
end

-- Update the UI with current cache data
function CachingSystemUI.updateUI()
    -- Skip if container is not visible
    if not CachingSystemUI.container or not CachingSystemUI.container.Visible then
        return
    end
    
    -- Update based on which tab is currently selected
    for name, tab in pairs(CachingSystemUI.tabs) do
        if tab.content.Visible then
            if name == "Dashboard" then
                CachingSystemUI.updateDashboardTab()
            elseif name == "CacheManager" then
                CachingSystemUI.updateCacheEntries()
            end
            break -- Only update the visible tab
        end
    end
end

-- Update the Dashboard tab
function CachingSystemUI.updateDashboardTab()
    -- Get cache analytics
    local cacheAnalytics = CacheManager.getCacheAnalytics()
    local cacheContents = CacheManager.getCacheContents()
    local memoryUsage = CacheManager.estimateMemoryUsage()
    
    -- Update stat boxes
    local hitRate = 0
    if (cacheAnalytics.hits + cacheAnalytics.misses) > 0 then
        hitRate = (cacheAnalytics.hits / (cacheAnalytics.hits + cacheAnalytics.misses)) * 100
    end
    
    local statBoxes = CachingSystemUI.tabs.Dashboard.content:FindFirstChild("StatsContainer")
    if statBoxes then
        local hitRateBox = statBoxes:FindFirstChild("HitRateBox")
        if hitRateBox then
            local valueLabel = hitRateBox:FindFirstChild("ValueLabel")
            if valueLabel then
                valueLabel.Text = string.format("%.1f%%", hitRate)
            end
        end
        
        local entriesBox = statBoxes:FindFirstChild("EntriesBox")
        if entriesBox then
            local valueLabel = entriesBox:FindFirstChild("ValueLabel")
            if valueLabel then
                valueLabel.Text = tostring(#cacheContents)
            end
        end
        
        local memoryBox = statBoxes:FindFirstChild("MemoryBox")
        if memoryBox then
            local valueLabel = memoryBox:FindFirstChild("ValueLabel")
            if valueLabel then
                valueLabel.Text = string.format("%.1f KB", memoryUsage / 1024)
            end
        end
        
        local efficiencyBox = statBoxes:FindFirstChild("EfficiencyBox")
        if efficiencyBox then
            local valueLabel = efficiencyBox:FindFirstChild("ValueLabel")
            if valueLabel then
                local efficiency = 0
                if cacheAnalytics.totalOperations > 0 then
                    efficiency = (cacheAnalytics.hits / cacheAnalytics.totalOperations) * 100
                end
                valueLabel.Text = string.format("%.1f%%", efficiency)
            end
        end
    end
    
    -- Update trends chart
    local trendsChart = CachingSystemUI.charts.trends
    if trendsChart then
        -- Clear existing chart
        trendsChart:ClearAllChildren()
        
        -- Get historical cache data
        local historicalData = CacheManager.getHistoricalCacheData()
        
        if #historicalData > 0 then
            -- Prepare data for line chart
            local timestamps = {}
            local hitRates = {}
            local entryCount = {}
            
            for i, period in ipairs(historicalData) do
                table.insert(timestamps, os.date("%H:%M", period.timestamp))
                
                local rate = 0
                if (period.hits + period.misses) > 0 then
                    rate = (period.hits / (period.hits + period.misses)) * 100
                end
                table.insert(hitRates, rate)
                
                table.insert(entryCount, period.entries)
            end
            
            -- Create the line chart
            DataVisualization.createLineChart(
                trendsChart,
                timestamps,
                {
                    {name = "Hit Rate (%)", values = hitRates, color = Color3.fromRGB(52, 152, 219)},
                    {name = "Entries", values = entryCount, color = Color3.fromRGB(46, 204, 113)}
                },
                "Cache Performance Trends"
            )
        else
            -- Show message if no data available
            local noDataLabel = StyleGuide.createLabel("No historical cache data available yet.", 1)
            noDataLabel.Size = UDim2.new(1, 0, 0, 30)
            noDataLabel.Position = UDim2.new(0, 0, 0.5, -15)
            noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
            noDataLabel.Parent = trendsChart
        end
    end
    
    -- Update entries table
    local entriesTable = CachingSystemUI.entriesTable
    if entriesTable then
        -- Clear existing table
        entriesTable:ClearAllChildren()
        
        -- Create table header
        local tableData = {
            headers = {"DataStore", "Key", "Access Count", "Size (KB)", "Last Access"},
            rows = {}
        }
        
        -- Sort cache entries by access count (descending)
        table.sort(cacheContents, function(a, b)
            return a.accessCount > b.accessCount
        end)
        
        -- Add up to 10 most accessed entries
        local count = 0
        for _, entry in ipairs(cacheContents) do
            if count >= 10 then break end
            
            table.insert(tableData.rows, {
                entry.dataStoreName,
                entry.keyName,
                tostring(entry.accessCount),
                string.format("%.2f", entry.estimatedSize / 1024),
                os.date("%Y-%m-%d %H:%M:%S", entry.lastAccessed)
            })
            
            count = count + 1
        end
        
        -- Create the table
        if #tableData.rows > 0 then
            DataVisualization.createTableView(entriesTable, tableData)
        else
            -- Show message if no data available
            local noDataLabel = StyleGuide.createLabel("No cache entries available.", 1)
            noDataLabel.Size = UDim2.new(1, 0, 0, 30)
            noDataLabel.Position = UDim2.new(0, 0, 0.5, -15)
            noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
            noDataLabel.Parent = entriesTable
        end
    end
end

-- Update cache entries list based on search/filter
function CachingSystemUI.updateCacheEntries(searchText, filterOption)
    local entriesListFrame = CachingSystemUI.tabs.CacheManager.entriesListFrame
    
    if not entriesListFrame then return end
    
    -- Save header before clearing
    local headerFrame = entriesListFrame:FindFirstChild("HeaderFrame")
    
    -- Clear existing entries
    for _, child in ipairs(entriesListFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "HeaderFrame" then
            child:Destroy()
        end
    end
    
    -- Get cache contents
    local cacheContents = CacheManager.getCacheContents()
    
    -- Apply search filter
    searchText = searchText or ""
    local filteredEntries = {}
    
    for _, entry in ipairs(cacheContents) do
        if string.find(entry.dataStoreName:lower(), searchText:lower()) or 
           string.find(entry.keyName:lower(), searchText:lower()) or
           searchText == "" then
            table.insert(filteredEntries, entry)
        end
    end
    
    -- Apply sorting filter
    filterOption = filterOption or "All Entries"
    
    if filterOption == "Most Accessed" then
        table.sort(filteredEntries, function(a, b)
            return a.accessCount > b.accessCount
        end)
    elseif filterOption == "Least Accessed" then
        table.sort(filteredEntries, function(a, b)
            return a.accessCount < b.accessCount
        end)
    elseif filterOption == "Newest" then
        table.sort(filteredEntries, function(a, b)
            return a.lastAccessed > b.lastAccessed
        end)
    elseif filterOption == "Oldest" then
        table.sort(filteredEntries, function(a, b)
            return a.lastAccessed < b.lastAccessed
        end)
    end
    
    -- Create entry items
    for i, entry in ipairs(filteredEntries) do
        local entryFrame = Instance.new("Frame")
        entryFrame.Size = UDim2.new(1, 0, 0, 40)
        entryFrame.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(30, 30, 40) or Color3.fromRGB(35, 35, 45)
        entryFrame.BorderSizePixel = 0
        entryFrame.LayoutOrder = i
        entryFrame.Name = "EntryFrame_" .. i
        entryFrame.Parent = entriesListFrame
        
        -- Create columns
        local datastoreLabel = StyleGuide.createLabel(entry.dataStoreName, 1)
        datastoreLabel.Size = UDim2.new(0.25, -5, 1, 0)
        datastoreLabel.Position = UDim2.new(0, 5, 0, 0)
        datastoreLabel.TextXAlignment = Enum.TextXAlignment.Left
        datastoreLabel.Parent = entryFrame
        
        local keyLabel = StyleGuide.createLabel(entry.keyName, 2)
        keyLabel.Size = UDim2.new(0.25, -5, 1, 0)
        keyLabel.Position = UDim2.new(0.25, 5, 0, 0)
        keyLabel.TextXAlignment = Enum.TextXAlignment.Left
        keyLabel.Parent = entryFrame
        
        local accessLabel = StyleGuide.createLabel(tostring(entry.accessCount), 3)
        accessLabel.Size = UDim2.new(0.15, -5, 1, 0)
        accessLabel.Position = UDim2.new(0.5, 5, 0, 0)
        accessLabel.TextXAlignment = Enum.TextXAlignment.Left
        accessLabel.Parent = entryFrame
        
        local sizeLabel = StyleGuide.createLabel(string.format("%.2f KB", entry.estimatedSize / 1024), 4)
        sizeLabel.Size = UDim2.new(0.15, -5, 1, 0)
        sizeLabel.Position = UDim2.new(0.65, 5, 0, 0)
        sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
        sizeLabel.Parent = entryFrame
        
        -- Create actions container
        local actionsContainer = Instance.new("Frame")
        actionsContainer.Size = UDim2.new(0.2, -5, 1, 0)
        actionsContainer.Position = UDim2.new(0.8, 5, 0, 0)
        actionsContainer.BackgroundTransparency = 1
        actionsContainer.Name = "ActionsContainer"
        actionsContainer.Parent = entryFrame
        
        -- Create remove button
        local removeButton = StyleGuide.createButton("Remove", false)
        removeButton.Size = UDim2.new(0.9, 0, 0, 24)
        removeButton.Position = UDim2.new(0.05, 0, 0.5, -12)
        removeButton.TextSize = 12
        removeButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
        removeButton.Name = "RemoveButton"
        removeButton.Parent = actionsContainer
        
        -- Add remove button handler
        removeButton.MouseButton1Click:Connect(function()
            CacheManager.removeFromCache(entry.dataStoreName, entry.keyName)
            CachingSystemUI.updateCacheEntries(searchText, filterOption)
            StyleGuide.showNotification("Cache entry removed", "success")
        end)
    end
    
    -- Add header back if it was removed
    if headerFrame and not entriesListFrame:FindFirstChild("HeaderFrame") then
        headerFrame.Parent = entriesListFrame
    end
    
    -- Show message if no entries found
    if #filteredEntries == 0 then
        local noEntriesLabel = StyleGuide.createLabel("No cache entries found.", 1)
        noEntriesLabel.Size = UDim2.new(1, 0, 0, 40)
        noEntriesLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        noEntriesLabel.TextXAlignment = Enum.TextXAlignment.Center
        noEntriesLabel.LayoutOrder = 1
        noEntriesLabel.Parent = entriesListFrame
    end
    
    -- Update canvas size
    entriesListFrame.CanvasSize = UDim2.new(0, 0, 0, (#filteredEntries + 1) * 40)
end

-- Update the list of cache rules
function CachingSystemUI.updateRulesList()
    local rulesListFrame = CachingSystemUI.tabs.Settings.rulesListFrame
    
    if not rulesListFrame then return end
    
    -- Clear existing rules
    for _, child in ipairs(rulesListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get cache rules
    local cacheRules = CacheManager.getCacheRules()
    
    -- Create rule items
    for i, rule in ipairs(cacheRules) do
        local ruleFrame = Instance.new("Frame")
        ruleFrame.Size = UDim2.new(1, 0, 0, 60)
        ruleFrame.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(30, 30, 40) or Color3.fromRGB(35, 35, 45)
        ruleFrame.BorderSizePixel = 0
        ruleFrame.LayoutOrder = i
        ruleFrame.Name = "RuleFrame_" .. i
        ruleFrame.Parent = rulesListFrame
        
        -- Create rule info
        local typeLabel = StyleGuide.createLabel("Type: " .. rule.type, 1)
        typeLabel.Size = UDim2.new(0.3, -10, 0, 20)
        typeLabel.Position = UDim2.new(0, 10, 0, 10)
        typeLabel.TextXAlignment = Enum.TextXAlignment.Left
        typeLabel.Parent = ruleFrame
        
        local patternLabel = StyleGuide.createLabel("Pattern: " .. rule.pattern, 2)
        patternLabel.Size = UDim2.new(0.5, -10, 0, 20)
        patternLabel.Position = UDim2.new(0.3, 0, 0, 10)
        patternLabel.TextXAlignment = Enum.TextXAlignment.Left
        patternLabel.Parent = ruleFrame
        
        local ttlLabel = StyleGuide.createLabel("TTL: " .. rule.ttl .. "s", 3)
        ttlLabel.Size = UDim2.new(0.2, -10, 0, 20)
        ttlLabel.Position = UDim2.new(0.8, 0, 0, 10)
        ttlLabel.TextXAlignment = Enum.TextXAlignment.Left
        ttlLabel.Parent = ruleFrame
        
        local priorityLabel = StyleGuide.createLabel("Priority: " .. rule.priority, 4)
        priorityLabel.Size = UDim2.new(0.3, -10, 0, 20)
        priorityLabel.Position = UDim2.new(0, 10, 0, 35)
        priorityLabel.TextXAlignment = Enum.TextXAlignment.Left
        priorityLabel.Parent = ruleFrame
        
        -- Create delete button
        local deleteButton = StyleGuide.createButton("Delete", false)
        deleteButton.Size = UDim2.new(0.15, 0, 0, 24)
        deleteButton.Position = UDim2.new(0.8, 10, 0.5, -12)
        deleteButton.TextSize = 12
        deleteButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
        deleteButton.Name = "DeleteButton"
        deleteButton.Parent = ruleFrame
        
        -- Add delete button handler
        deleteButton.MouseButton1Click:Connect(function()
            CacheManager.removeCacheRule(i)
            CachingSystemUI.updateRulesList()
            StyleGuide.showNotification("Cache rule deleted", "success")
        end)
    end
    
    -- Show message if no rules found
    if #cacheRules == 0 then
        local noRulesLabel = StyleGuide.createLabel("No cache rules defined.", 1)
        noRulesLabel.Size = UDim2.new(1, 0, 0, 40)
        noRulesLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        noRulesLabel.TextXAlignment = Enum.TextXAlignment.Center
        noRulesLabel.LayoutOrder = 1
        noRulesLabel.Parent = rulesListFrame
    end
    
    -- Update canvas size
    rulesListFrame.CanvasSize = UDim2.new(0, 0, 0, (#cacheRules == 0 and 40 or #cacheRules * 60))
end

-- Show the preload data dialog
function CachingSystemUI.showPreloadDialog()
    local dialogFrame = Instance.new("Frame")
    dialogFrame.Size = UDim2.new(0.6, 0, 0, 300)
    dialogFrame.Position = UDim2.new(0.2, 0, 0.5, -150)
    dialogFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    dialogFrame.BorderSizePixel = 0
    dialogFrame.Name = "PreloadDialog"
    dialogFrame.Parent = CachingSystemUI.container
    
    -- Add rounded corners
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 8)
    dialogCorner.Parent = dialogFrame
    
    -- Add title
    local titleLabel = StyleGuide.createLabel("Preload Data", 1)
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = dialogFrame
    
    -- Close button
    local closeButton = StyleGuide.createButton("X", false)
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
    closeButton.Name = "CloseButton"
    closeButton.Parent = dialogFrame
    
    -- Add content
    local datastoreLabel = StyleGuide.createLabel("DataStore Name:", 2)
    datastoreLabel.Size = UDim2.new(0.3, 0, 0, 30)
    datastoreLabel.Position = UDim2.new(0, 20, 0, 60)
    datastoreLabel.TextXAlignment = Enum.TextXAlignment.Left
    datastoreLabel.Parent = dialogFrame
    
    local datastoreInput = StyleGuide.createTextInput("Enter DataStore name")
    datastoreInput.Size = UDim2.new(0.65, -20, 0, 30)
    datastoreInput.Position = UDim2.new(0.3, 10, 0, 60)
    datastoreInput.Name = "DataStoreInput"
    datastoreInput.Parent = dialogFrame
    
    local keyPatternLabel = StyleGuide.createLabel("Key Pattern:", 3)
    keyPatternLabel.Size = UDim2.new(0.3, 0, 0, 30)
    keyPatternLabel.Position = UDim2.new(0, 20, 0, 100)
    keyPatternLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyPatternLabel.Parent = dialogFrame
    
    local keyPatternInput = StyleGuide.createTextInput("Enter key pattern (e.g., Player_*)")
    keyPatternInput.Size = UDim2.new(0.65, -20, 0, 30)
    keyPatternInput.Position = UDim2.new(0.3, 10, 0, 100)
    keyPatternInput.Name = "KeyPatternInput"
    keyPatternInput.Parent = dialogFrame
    
    local maxItemsLabel = StyleGuide.createLabel("Max Items:", 4)
    maxItemsLabel.Size = UDim2.new(0.3, 0, 0, 30)
    maxItemsLabel.Position = UDim2.new(0, 20, 0, 140)
    maxItemsLabel.TextXAlignment = Enum.TextXAlignment.Left
    maxItemsLabel.Parent = dialogFrame
    
    local maxItemsInput = StyleGuide.createTextInput("10")
    maxItemsInput.Size = UDim2.new(0.65, -20, 0, 30)
    maxItemsInput.Position = UDim2.new(0.3, 10, 0, 140)
    maxItemsInput.Name = "MaxItemsInput"
    maxItemsInput.Parent = dialogFrame
    
    local ttlLabel = StyleGuide.createLabel("Cache TTL (seconds):", 5)
    ttlLabel.Size = UDim2.new(0.3, 0, 0, 30)
    ttlLabel.Position = UDim2.new(0, 20, 0, 180)
    ttlLabel.TextXAlignment = Enum.TextXAlignment.Left
    ttlLabel.Parent = dialogFrame
    
    local ttlInput = StyleGuide.createTextInput("300")
    ttlInput.Size = UDim2.new(0.65, -20, 0, 30)
    ttlInput.Position = UDim2.new(0.3, 10, 0, 180)
    ttlInput.Name = "TTLInput"
    ttlInput.Parent = dialogFrame
    
    -- Create preload button
    local preloadButton = StyleGuide.createButton("Preload Data", true)
    preloadButton.Size = UDim2.new(0.4, 0, 0, 40)
    preloadButton.Position = UDim2.new(0.3, 0, 0, 230)
    preloadButton.Name = "PreloadButton"
    preloadButton.Parent = dialogFrame
    
    -- Add button handlers
    closeButton.MouseButton1Click:Connect(function()
        dialogFrame:Destroy()
    end)
    
    preloadButton.MouseButton1Click:Connect(function()
        -- Get input values
        local dataStoreName = datastoreInput.Text
        local keyPattern = keyPatternInput.Text
        local maxItems = tonumber(maxItemsInput.Text) or 10
        local ttl = tonumber(ttlInput.Text) or 300
        
        if dataStoreName == "" or keyPattern == "" then
            StyleGuide.showNotification("Please enter DataStore name and key pattern", "warning")
            return
        end
        
        -- Start preloading
        preloadButton.Text = "Preloading..."
        preloadButton.BackgroundColor3 = StyleGuide.Colors.Disabled
        
        task.spawn(function()
            local result = CacheManager.preloadData(dataStoreName, keyPattern, maxItems, ttl)
            
            -- Close dialog
            dialogFrame:Destroy()
            
            -- Show result notification
            if result.success then
                StyleGuide.showNotification(string.format("Preloaded %d items into cache", result.count), "success")
            else
                StyleGuide.showNotification("Error preloading data: " .. result.error, "error")
            end
        end)
    end)
end

return CachingSystemUI
