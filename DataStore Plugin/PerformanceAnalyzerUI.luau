--[[
    PerformanceAnalyzerUI.luau
    Part of DataStore Manager Pro
    
    This module provides the user interface for the Performance Analyzer,
    allowing developers to visualize performance data, bottlenecks, and
    optimization suggestions.
]]

local HttpService = game:GetService("HttpService")

local StyleGuide = require(script.Parent.StyleGuide)
local DataVisualization = require(script.Parent.DataVisualization)
local PerformanceAnalyzer = require(script.Parent.PerformanceAnalyzer)

local PerformanceAnalyzerUI = {}

-- Reference to UI components
PerformanceAnalyzerUI.container = nil
PerformanceAnalyzerUI.tabs = {}
PerformanceAnalyzerUI.charts = {}
PerformanceAnalyzerUI.dataViews = {}

-- Initialize the Performance Analyzer UI
function PerformanceAnalyzerUI.initialize()
    print("PerformanceAnalyzerUI: Initializing UI components...")
    return true
end

-- Create the main Performance Analyzer UI
function PerformanceAnalyzerUI.createUI(container)
    PerformanceAnalyzerUI.container = container
    
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
    PerformanceAnalyzerUI.createOverviewTab(tabContainer, contentContainer)
    PerformanceAnalyzerUI.createBottlenecksTab(tabContainer, contentContainer)
    PerformanceAnalyzerUI.createSuggestionsTab(tabContainer, contentContainer)
    PerformanceAnalyzerUI.createBenchmarkTab(tabContainer, contentContainer)
    PerformanceAnalyzerUI.createSettingsTab(tabContainer, contentContainer)
    
    -- Select the first tab by default
    PerformanceAnalyzerUI.selectTab("Overview")
    
    -- Set up periodic UI updates
    task.spawn(function()
        while true do
            PerformanceAnalyzerUI.updateUI()
            task.wait(5) -- Update every 5 seconds
        end
    end)
end

-- Create the Overview tab
function PerformanceAnalyzerUI.createOverviewTab(tabContainer, contentContainer)
    -- Create tab button
    local tabButton = StyleGuide.createTabButton("Overview", 1)
    tabButton.Parent = tabContainer
    
    -- Create tab content
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 6
    tabContent.Visible = false
    tabContent.Name = "OverviewTab"
    tabContent.Parent = contentContainer
    
    -- Create layout for tab content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tabContent
    
    -- Create summary section
    local summarySection = StyleGuide.createSection("Performance Summary", 1)
    summarySection.Size = UDim2.new(1, -20, 0, 150)
    summarySection.Parent = tabContent
    
    -- Create operation trends chart
    local trendsChartContainer = StyleGuide.createSection("Operation Trends", 2)
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
    PerformanceAnalyzerUI.charts.trends = trendsChartFrame
    
    -- Create DataStore performance section
    local dataStoreSection = StyleGuide.createSection("DataStore Performance", 3)
    dataStoreSection.Size = UDim2.new(1, -20, 0, 300)
    dataStoreSection.Parent = tabContent
    
    -- Create table frame for DataStore performance data
    local dataStoreTable = Instance.new("Frame")
    dataStoreTable.Size = UDim2.new(1, -20, 1, -40)
    dataStoreTable.Position = UDim2.new(0, 10, 0, 30)
    dataStoreTable.BackgroundTransparency = 1
    dataStoreTable.Name = "DataStoreTable"
    dataStoreTable.Parent = dataStoreSection
    
    -- Store reference to table for later use
    PerformanceAnalyzerUI.dataViews.dataStorePerformance = dataStoreTable
    
    -- Create server load section
    local serverLoadSection = StyleGuide.createSection("Server Load", 4)
    serverLoadSection.Size = UDim2.new(1, -20, 0, 250)
    serverLoadSection.Parent = tabContent
    
    -- Create placeholder for server load chart
    local serverLoadChartFrame = Instance.new("Frame")
    serverLoadChartFrame.Size = UDim2.new(1, -20, 1, -40)
    serverLoadChartFrame.Position = UDim2.new(0, 10, 0, 30)
    serverLoadChartFrame.BackgroundTransparency = 1
    serverLoadChartFrame.Name = "ServerLoadChartFrame"
    serverLoadChartFrame.Parent = serverLoadSection
    
    -- Store reference to chart frame for later use
    PerformanceAnalyzerUI.charts.serverLoad = serverLoadChartFrame
    
    -- Store tab information
    PerformanceAnalyzerUI.tabs.Overview = {
        button = tabButton,
        content = tabContent
    }
    
    -- Add button click handler
    tabButton.MouseButton1Click:Connect(function()
        PerformanceAnalyzerUI.selectTab("Overview")
    end)
end

-- Create the Bottlenecks tab
function PerformanceAnalyzerUI.createBottlenecksTab(tabContainer, contentContainer)
    -- Create tab button
    local tabButton = StyleGuide.createTabButton("Bottlenecks", 2)
    tabButton.Parent = tabContainer
    
    -- Create tab content
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 6
    tabContent.Visible = false
    tabContent.Name = "BottlenecksTab"
    tabContent.Parent = contentContainer
    
    -- Create layout for tab content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tabContent
    
    -- Create bottlenecks list section
    local bottlenecksSection = StyleGuide.createSection("Identified Bottlenecks", 1)
    bottlenecksSection.Size = UDim2.new(1, -20, 0, 400)
    bottlenecksSection.Parent = tabContent
    
    -- Create the bottlenecks list container
    local bottlenecksList = Instance.new("ScrollingFrame")
    bottlenecksList.Size = UDim2.new(1, -20, 1, -40)
    bottlenecksList.Position = UDim2.new(0, 10, 0, 30)
    bottlenecksList.BackgroundTransparency = 1
    bottlenecksList.BorderSizePixel = 0
    bottlenecksList.ScrollBarThickness = 6
    bottlenecksList.Name = "BottlenecksList"
    bottlenecksList.Parent = bottlenecksSection
    
    -- Create layout for bottlenecks list
    local bottlenecksLayout = Instance.new("UIListLayout")
    bottlenecksLayout.Padding = UDim.new(0, 10)
    bottlenecksLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bottlenecksLayout.Parent = bottlenecksList
    
    -- Store reference to bottlenecks list for later use
    PerformanceAnalyzerUI.dataViews.bottlenecks = bottlenecksList
    
    -- Create key performance section
    local keyPerformanceSection = StyleGuide.createSection("Key Performance", 2)
    keyPerformanceSection.Size = UDim2.new(1, -20, 0, 300)
    keyPerformanceSection.Parent = tabContent
    
    -- Create table frame for key performance data
    local keyPerformanceTable = Instance.new("Frame")
    keyPerformanceTable.Size = UDim2.new(1, -20, 1, -40)
    keyPerformanceTable.Position = UDim2.new(0, 10, 0, 30)
    keyPerformanceTable.BackgroundTransparency = 1
    keyPerformanceTable.Name = "KeyPerformanceTable"
    keyPerformanceTable.Parent = keyPerformanceSection
    
    -- Store reference to table for later use
    PerformanceAnalyzerUI.dataViews.keyPerformance = keyPerformanceTable
    
    -- Store tab information
    PerformanceAnalyzerUI.tabs.Bottlenecks = {
        button = tabButton,
        content = tabContent
    }
    
    -- Add button click handler
    tabButton.MouseButton1Click:Connect(function()
        PerformanceAnalyzerUI.selectTab("Bottlenecks")
    end)
end

-- Create the Suggestions tab
function PerformanceAnalyzerUI.createSuggestionsTab(tabContainer, contentContainer)
    -- Create tab button
    local tabButton = StyleGuide.createTabButton("Suggestions", 3)
    tabButton.Parent = tabContainer
    
    -- Create tab content
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 6
    tabContent.Visible = false
    tabContent.Name = "SuggestionsTab"
    tabContent.Parent = contentContainer
    
    -- Create layout for tab content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tabContent
    
    -- Create optimization suggestions section
    local suggestionsSection = StyleGuide.createSection("Optimization Suggestions", 1)
    suggestionsSection.Size = UDim2.new(1, -20, 0, 500)
    suggestionsSection.Parent = tabContent
    
    -- Create the suggestions list container
    local suggestionsList = Instance.new("ScrollingFrame")
    suggestionsList.Size = UDim2.new(1, -20, 1, -40)
    suggestionsList.Position = UDim2.new(0, 10, 0, 30)
    suggestionsList.BackgroundTransparency = 1
    suggestionsList.BorderSizePixel = 0
    suggestionsList.ScrollBarThickness = 6
    suggestionsList.Name = "SuggestionsList"
    suggestionsList.Parent = suggestionsSection
    
    -- Create layout for suggestions list
    local suggestionsLayout = Instance.new("UIListLayout")
    suggestionsLayout.Padding = UDim.new(0, 15)
    suggestionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    suggestionsLayout.Parent = suggestionsList
    
    -- Store reference to suggestions list for later use
    PerformanceAnalyzerUI.dataViews.suggestions = suggestionsList
    
    -- Store tab information
    PerformanceAnalyzerUI.tabs.Suggestions = {
        button = tabButton,
        content = tabContent
    }
    
    -- Add button click handler
    tabButton.MouseButton1Click:Connect(function()
        PerformanceAnalyzerUI.selectTab("Suggestions")
    end)
end

-- Create the Benchmark tab
function PerformanceAnalyzerUI.createBenchmarkTab(tabContainer, contentContainer)
    -- Create tab button
    local tabButton = StyleGuide.createTabButton("Benchmark", 4)
    tabButton.Parent = tabContainer
    
    -- Create tab content
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 6
    tabContent.Visible = false
    tabContent.Name = "BenchmarkTab"
    tabContent.Parent = contentContainer
    
    -- Create layout for tab content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tabContent
    
    -- Create benchmark configuration section
    local configSection = StyleGuide.createSection("Benchmark Configuration", 1)
    configSection.Size = UDim2.new(1, -20, 0, 200)
    configSection.Parent = tabContent
    
    -- Create a layout for the config section
    local configLayout = Instance.new("UIListLayout")
    configLayout.Padding = UDim.new(0, 10)
    configLayout.SortOrder = Enum.SortOrder.LayoutOrder
    configLayout.Parent = configSection
    
    -- Create DataStore name input
    local dsLabel = StyleGuide.createLabel("DataStore Name", 1)
    dsLabel.Size = UDim2.new(1, -20, 0, 20)
    dsLabel.Position = UDim2.new(0, 10, 0, 30)
    dsLabel.Parent = configSection
    
    local dsInput = StyleGuide.createTextInput("PlayerData")
    dsInput.Size = UDim2.new(1, -20, 0, 30)
    dsInput.Position = UDim2.new(0, 10, 0, 55)
    dsInput.Name = "DataStoreInput"
    dsInput.Parent = configSection
    
    -- Create Key name input
    local keyLabel = StyleGuide.createLabel("Key Name", 2)
    keyLabel.Size = UDim2.new(1, -20, 0, 20)
    keyLabel.Position = UDim2.new(0, 10, 0, 95)
    keyLabel.Parent = configSection
    
    local keyInput = StyleGuide.createTextInput("Player_12345")
    keyInput.Size = UDim2.new(1, -20, 0, 30)
    keyInput.Position = UDim2.new(0, 10, 0, 120)
    keyInput.Name = "KeyInput"
    keyInput.Parent = configSection
    
    -- Create operation type selection
    local opLabel = StyleGuide.createLabel("Operation Type", 3)
    opLabel.Size = UDim2.new(1, -20, 0, 20)
    opLabel.Position = UDim2.new(0, 10, 0, 160)
    opLabel.Parent = configSection
    
    local opTypeFrame = Instance.new("Frame")
    opTypeFrame.Size = UDim2.new(1, -20, 0, 30)
    opTypeFrame.Position = UDim2.new(0, 10, 0, 185)
    opTypeFrame.BackgroundTransparency = 1
    opTypeFrame.LayoutOrder = 4
    opTypeFrame.Name = "OperationTypeFrame"
    opTypeFrame.Parent = configSection
    
    local getButton = StyleGuide.createButton("GetAsync", true)
    getButton.Size = UDim2.new(0.48, 0, 1, 0)
    getButton.Position = UDim2.new(0, 0, 0, 0)
    getButton.Name = "GetButton"
    getButton.Parent = opTypeFrame
    
    local setButton = StyleGuide.createButton("SetAsync", false)
    setButton.Size = UDim2.new(0.48, 0, 1, 0)
    setButton.Position = UDim2.new(0.52, 0, 0, 0)
    setButton.Name = "SetButton"
    setButton.Parent = opTypeFrame
    
    -- Create iterations input
    local iterLabel = StyleGuide.createLabel("Iterations", 5)
    iterLabel.Size = UDim2.new(1, -20, 0, 20)
    iterLabel.Position = UDim2.new(0, 10, 0, 225)
    iterLabel.Parent = configSection
    
    local iterInput = StyleGuide.createTextInput("10")
    iterInput.Size = UDim2.new(1, -20, 0, 30)
    iterInput.Position = UDim2.new(0, 10, 0, 250)
    iterInput.Name = "IterationsInput"
    iterInput.Parent = configSection
    
    -- Create benchmark button
    local benchmarkButton = StyleGuide.createButton("Run Benchmark", true)
    benchmarkButton.Size = UDim2.new(1, -20, 0, 40)
    benchmarkButton.Position = UDim2.new(0, 10, 0, 290)
    benchmarkButton.Name = "BenchmarkButton"
    benchmarkButton.Parent = configSection
    
    -- Create benchmark results section
    local resultsSection = StyleGuide.createSection("Benchmark Results", 2)
    resultsSection.Size = UDim2.new(1, -20, 0, 350)
    resultsSection.Parent = tabContent
    
    -- Create results container
    local resultsContainer = Instance.new("Frame")
    resultsContainer.Size = UDim2.new(1, -20, 0, 300)
    resultsContainer.Position = UDim2.new(0, 10, 0, 40)
    resultsContainer.BackgroundTransparency = 1
    resultsContainer.Name = "ResultsContainer"
    resultsContainer.Visible = false
    resultsContainer.Parent = resultsSection
    
    -- Create benchmark summary
    local summaryFrame = Instance.new("Frame")
    summaryFrame.Size = UDim2.new(1, 0, 0, 100)
    summaryFrame.BackgroundColor3 = StyleGuide.Colors.Background2
    summaryFrame.BorderSizePixel = 0
    summaryFrame.Name = "SummaryFrame"
    summaryFrame.Parent = resultsContainer
    
    local summaryLayout = Instance.new("UIListLayout")
    summaryLayout.Padding = UDim.new(0, 10)
    summaryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    summaryLayout.Parent = summaryFrame
    
    -- Create chart for benchmark results
    local resultsChartFrame = Instance.new("Frame")
    resultsChartFrame.Size = UDim2.new(1, 0, 0, 180)
    resultsChartFrame.Position = UDim2.new(0, 0, 0, 110)
    resultsChartFrame.BackgroundTransparency = 1
    resultsChartFrame.Name = "ResultsChartFrame"
    resultsChartFrame.Parent = resultsContainer
    
    -- Store reference to benchmark results for later use
    PerformanceAnalyzerUI.dataViews.benchmarkResults = {
        container = resultsContainer,
        summary = summaryFrame,
        chart = resultsChartFrame
    }
    
    -- Select GetAsync by default
    local selectedOperation = "GetAsync"
    
    -- Add button handlers for operation type selection
    getButton.MouseButton1Click:Connect(function()
        getButton.BackgroundColor3 = StyleGuide.Colors.Primary
        setButton.BackgroundColor3 = StyleGuide.Colors.Button
        selectedOperation = "GetAsync"
    end)
    
    setButton.MouseButton1Click:Connect(function()
        setButton.BackgroundColor3 = StyleGuide.Colors.Primary
        getButton.BackgroundColor3 = StyleGuide.Colors.Button
        selectedOperation = "SetAsync"
    end)
    
    -- Add benchmark button handler
    benchmarkButton.MouseButton1Click:Connect(function()
        -- Get input values
        local dataStoreName = dsInput.Text
        local keyName = keyInput.Text
        local iterations = tonumber(iterInput.Text) or 10
        
        -- Validate inputs
        if dataStoreName == "" or keyName == "" then
            StyleGuide.showNotification("Please enter a DataStore name and key name", "warning")
            return
        end
        
        -- Limit iterations for safety
        iterations = math.min(iterations, 50)
        
        -- Update UI to indicate benchmark is running
        benchmarkButton.Text = "Running..."
        benchmarkButton.BackgroundColor3 = StyleGuide.Colors.Disabled
        
        -- Run the benchmark
        task.spawn(function()
            local results = PerformanceAnalyzer.runBenchmark(dataStoreName, keyName, selectedOperation, iterations)
            
            -- Update the results display
            PerformanceAnalyzerUI.displayBenchmarkResults(results)
            
            -- Reset the button
            benchmarkButton.Text = "Run Benchmark"
            benchmarkButton.BackgroundColor3 = StyleGuide.Colors.Primary
        end)
    end)
    
    -- Store tab information
    PerformanceAnalyzerUI.tabs.Benchmark = {
        button = tabButton,
        content = tabContent
    }
    
    -- Add button click handler
    tabButton.MouseButton1Click:Connect(function()
        PerformanceAnalyzerUI.selectTab("Benchmark")
    end)
end

-- Create the Settings tab
function PerformanceAnalyzerUI.createSettingsTab(tabContainer, contentContainer)
    -- Create tab button
    local tabButton = StyleGuide.createTabButton("Settings", 5)
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
    
    -- Create performance settings section
    local settingsSection = StyleGuide.createSection("Performance Analyzer Settings", 1)
    settingsSection.Size = UDim2.new(1, -20, 0, 350)
    settingsSection.Parent = tabContent
    
    -- Create a layout for the settings section
    local settingsLayout = Instance.new("UIListLayout")
    settingsLayout.Padding = UDim.new(0, 20)
    settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    settingsLayout.Parent = settingsSection
    
    -- Create settings for slow operation threshold
    local slowOpLabel = StyleGuide.createLabel("Slow Operation Threshold (seconds)", 1)
    slowOpLabel.Size = UDim2.new(1, -20, 0, 20)
    slowOpLabel.Position = UDim2.new(0, 10, 0, 30)
    slowOpLabel.Parent = settingsSection
    
    local slowOpInput = StyleGuide.createTextInput(tostring(PerformanceAnalyzer.config.slowOperationThreshold))
    slowOpInput.Size = UDim2.new(0.5, -20, 0, 30)
    slowOpInput.Position = UDim2.new(0, 10, 0, 55)
    slowOpInput.Name = "SlowOperationThresholdInput"
    slowOpInput.Parent = settingsSection
    
    -- Create settings for warning threshold
    local warningLabel = StyleGuide.createLabel("Warning Threshold (seconds)", 2)
    warningLabel.Size = UDim2.new(1, -20, 0, 20)
    warningLabel.Position = UDim2.new(0, 10, 0, 95)
    warningLabel.Parent = settingsSection
    
    local warningInput = StyleGuide.createTextInput(tostring(PerformanceAnalyzer.config.alertThresholds.warning))
    warningInput.Size = UDim2.new(0.5, -20, 0, 30)
    warningInput.Position = UDim2.new(0, 10, 0, 120)
    warningInput.Name = "WarningThresholdInput"
    warningInput.Parent = settingsSection
    
    -- Create settings for critical threshold
    local criticalLabel = StyleGuide.createLabel("Critical Threshold (seconds)", 3)
    criticalLabel.Size = UDim2.new(1, -20, 0, 20)
    criticalLabel.Position = UDim2.new(0, 10, 0, 160)
    criticalLabel.Parent = settingsSection
    
    local criticalInput = StyleGuide.createTextInput(tostring(PerformanceAnalyzer.config.alertThresholds.critical))
    criticalInput.Size = UDim2.new(0.5, -20, 0, 30)
    criticalInput.Position = UDim2.new(0, 10, 0, 185)
    criticalInput.Name = "CriticalThresholdInput"
    criticalInput.Parent = settingsSection
    
    -- Create settings for sampling interval
    local samplingLabel = StyleGuide.createLabel("Sampling Interval (seconds)", 4)
    samplingLabel.Size = UDim2.new(1, -20, 0, 20)
    samplingLabel.Position = UDim2.new(0, 10, 0, 225)
    samplingLabel.Parent = settingsSection
    
    local samplingInput = StyleGuide.createTextInput(tostring(PerformanceAnalyzer.config.samplingInterval))
    samplingInput.Size = UDim2.new(0.5, -20, 0, 30)
    samplingInput.Position = UDim2.new(0, 10, 0, 250)
    samplingInput.Name = "SamplingIntervalInput"
    samplingInput.Parent = settingsSection
    
    -- Create detailed logging toggle
    local loggingLabel = StyleGuide.createLabel("Detailed Logging", 5)
    loggingLabel.Size = UDim2.new(1, -20, 0, 20)
    loggingLabel.Position = UDim2.new(0, 10, 0, 290)
    loggingLabel.Parent = settingsSection
    
    local loggingToggle = StyleGuide.createToggle(PerformanceAnalyzer.config.detailedLogging)
    loggingToggle.Position = UDim2.new(0, 10, 0, 315)
    loggingToggle.Name = "DetailedLoggingToggle"
    loggingToggle.Parent = settingsSection
    
    -- Create save settings button
    local saveButton = StyleGuide.createButton("Save Settings", true)
    saveButton.Size = UDim2.new(1, -20, 0, 40)
    saveButton.Position = UDim2.new(0, 10, 0, 350)
    saveButton.Name = "SaveSettingsButton"
    saveButton.Parent = settingsSection
    
    -- Create reset button
    local resetButton = StyleGuide.createButton("Reset Data", false)
    resetButton.Size = UDim2.new(1, -20, 0, 40)
    resetButton.Position = UDim2.new(0, 10, 0, 400)
    resetButton.Name = "ResetDataButton"
    resetButton.BackgroundColor3 = StyleGuide.Colors.Danger
    resetButton.Parent = settingsSection
    
    -- Add save button handler
    saveButton.MouseButton1Click:Connect(function()
        -- Get input values
        local slowOpThreshold = tonumber(slowOpInput.Text) or PerformanceAnalyzer.config.slowOperationThreshold
        local warningThreshold = tonumber(warningInput.Text) or PerformanceAnalyzer.config.alertThresholds.warning
        local criticalThreshold = tonumber(criticalInput.Text) or PerformanceAnalyzer.config.alertThresholds.critical
        local samplingInterval = tonumber(samplingInput.Text) or PerformanceAnalyzer.config.samplingInterval
        local detailedLogging = loggingToggle.Value
        
        -- Update configuration
        local newConfig = {
            slowOperationThreshold = slowOpThreshold,
            samplingInterval = samplingInterval,
            detailedLogging = detailedLogging,
            alertThresholds = {
                warning = warningThreshold,
                critical = criticalThreshold,
            }
        }
        
        PerformanceAnalyzer.configure(newConfig)
        
        -- Show confirmation
        StyleGuide.showNotification("Settings saved successfully", "success")
    end)
    
    -- Add reset button handler
    resetButton.MouseButton1Click:Connect(function()
        -- Show confirmation dialog
        local confirmDialog = StyleGuide.createConfirmDialog(
            "Reset Performance Data", 
            "Are you sure you want to reset all collected performance data? This cannot be undone.",
            function()
                PerformanceAnalyzer.clearData()
                StyleGuide.showNotification("Performance data has been reset", "success")
            end
        )
        confirmDialog.Parent = PerformanceAnalyzerUI.container
    end)
    
    -- Store tab information
    PerformanceAnalyzerUI.tabs.Settings = {
        button = tabButton,
        content = tabContent
    }
    
    -- Add button click handler
    tabButton.MouseButton1Click:Connect(function()
        PerformanceAnalyzerUI.selectTab("Settings")
    end)
end

-- Select a tab to display
function PerformanceAnalyzerUI.selectTab(tabName)
    for name, tab in pairs(PerformanceAnalyzerUI.tabs) do
        if name == tabName then
            tab.button.BackgroundColor3 = StyleGuide.Colors.Primary
            tab.content.Visible = true
        else
            tab.button.BackgroundColor3 = StyleGuide.Colors.Button
            tab.content.Visible = false
        end
    end
    
    -- Refresh the UI for the selected tab
    PerformanceAnalyzerUI.updateUI()
end

-- Update the UI with current performance data
function PerformanceAnalyzerUI.updateUI()
    -- Skip if container is not visible
    if not PerformanceAnalyzerUI.container or not PerformanceAnalyzerUI.container.Visible then
        return
    end
    
    -- Update based on which tab is currently selected
    for name, tab in pairs(PerformanceAnalyzerUI.tabs) do
        if tab.content.Visible then
            if name == "Overview" then
                PerformanceAnalyzerUI.updateOverviewTab()
            elseif name == "Bottlenecks" then
                PerformanceAnalyzerUI.updateBottlenecksTab()
            elseif name == "Suggestions" then
                PerformanceAnalyzerUI.updateSuggestionsTab()
            end
            break -- Only update the visible tab
        end
    end
end

-- Update the Overview tab
function PerformanceAnalyzerUI.updateOverviewTab()
    -- Update the trends chart
    local trendsChart = PerformanceAnalyzerUI.charts.trends
    if trendsChart then
        -- Clear existing chart
        trendsChart:ClearAllChildren()
        
        -- Get historical trends data
        local trendsData = PerformanceAnalyzer.getHistoricalTrends()
        
        if #trendsData > 0 then
            -- Prepare data for line chart
            local timestamps = {}
            local averageDurations = {}
            local failureRates = {}
            local slowOpRates = {}
            
            for _, period in ipairs(trendsData) do
                table.insert(timestamps, os.date("%H:%M", period.timestamp))
                table.insert(averageDurations, period.averageDuration)
                table.insert(failureRates, period.failureRate * 100) -- Convert to percentage
                table.insert(slowOpRates, period.slowOperationRate * 100) -- Convert to percentage
            end
            
            -- Create the line chart
            DataVisualization.createLineChart(
                trendsChart,
                timestamps,
                {
                    {name = "Avg Duration (s)", values = averageDurations, color = Color3.fromRGB(52, 152, 219)},
                    {name = "Failure Rate (%)", values = failureRates, color = Color3.fromRGB(231, 76, 60)},
                    {name = "Slow Op Rate (%)", values = slowOpRates, color = Color3.fromRGB(230, 126, 34)}
                },
                "Operation Performance Trends"
            )
        else
            -- Show message if no data available
            local noDataLabel = StyleGuide.createLabel("No performance data available yet.", 1)
            noDataLabel.Size = UDim2.new(1, 0, 0, 30)
            noDataLabel.Position = UDim2.new(0, 0, 0.5, -15)
            noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
            noDataLabel.Parent = trendsChart
        end
    end
    
    -- Update the DataStore performance table
    local dataStoreTable = PerformanceAnalyzerUI.dataViews.dataStorePerformance
    if dataStoreTable then
        -- Clear existing table
        dataStoreTable:ClearAllChildren()
        
        -- Get DataStore performance data
        local dataStorePerformance = PerformanceAnalyzer.getDataStorePerformance()
        
        -- Convert to table format
        local tableData = {
            headers = {"DataStore", "Operations", "Avg Duration (s)", "Slow Ops", "Failed Ops"},
            rows = {}
        }
        
        for dataStore, metrics in pairs(dataStorePerformance) do
            table.insert(tableData.rows, {
                dataStore,
                tostring(metrics.operations),
                string.format("%.3f", metrics.averageDuration),
                tostring(metrics.slowOperations),
                tostring(metrics.failedOperations)
            })
        end
        
        -- Create the table view
        if #tableData.rows > 0 then
            DataVisualization.createTableView(dataStoreTable, tableData)
        else
            -- Show message if no data available
            local noDataLabel = StyleGuide.createLabel("No DataStore performance data available yet.", 1)
            noDataLabel.Size = UDim2.new(1, 0, 0, 30)
            noDataLabel.Position = UDim2.new(0, 0, 0.5, -15)
            noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
            noDataLabel.Parent = dataStoreTable
        end
    end
    
    -- Update the server load chart
    local serverLoadChart = PerformanceAnalyzerUI.charts.serverLoad
    if serverLoadChart then
        -- Clear existing chart
        serverLoadChart:ClearAllChildren()
        
        -- Get server load data
        local serverLoad = PerformanceAnalyzer.getServerLoad()
        
        if #serverLoad > 0 then
            -- Prepare data for line chart
            local timestamps = {}
            local memoryUsage = {}
            local heartbeatTimes = {}
            
            for _, stats in ipairs(serverLoad) do
                table.insert(timestamps, os.date("%H:%M:%S", stats.timestamp))
                table.insert(memoryUsage, stats.memoryUsageMB)
                table.insert(heartbeatTimes, stats.heartbeatTime * 1000) -- Convert to milliseconds
            end
            
            -- Create the line chart
            DataVisualization.createLineChart(
                serverLoadChart,
                timestamps,
                {
                    {name = "Memory (MB)", values = memoryUsage, color = Color3.fromRGB(52, 152, 219)},
                    {name = "Heartbeat (ms)", values = heartbeatTimes, color = Color3.fromRGB(46, 204, 113)}
                },
                "Server Load"
            )
        else
            -- Show message if no data available
            local noDataLabel = StyleGuide.createLabel("No server load data available yet.", 1)
            noDataLabel.Size = UDim2.new(1, 0, 0, 30)
            noDataLabel.Position = UDim2.new(0, 0, 0.5, -15)
            noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
            noDataLabel.Parent = serverLoadChart
        end
    end
end

-- Update the Bottlenecks tab
function PerformanceAnalyzerUI.updateBottlenecksTab()
    -- Update the bottlenecks list
    local bottlenecksList = PerformanceAnalyzerUI.dataViews.bottlenecks
    if bottlenecksList then
        -- Clear existing list
        bottlenecksList:ClearAllChildren()
        
        -- Restore layout
        local bottlenecksLayout = Instance.new("UIListLayout")
        bottlenecksLayout.Padding = UDim.new(0, 10)
        bottlenecksLayout.SortOrder = Enum.SortOrder.LayoutOrder
        bottlenecksLayout.Parent = bottlenecksList
        
        -- Get bottlenecks data
        local bottlenecks = PerformanceAnalyzer.getBottlenecks()
        
        if #bottlenecks > 0 then
            -- Create bottleneck items
            for i, bottleneck in ipairs(bottlenecks) do
                -- Create bottleneck item container
                local itemFrame = Instance.new("Frame")
                itemFrame.Size = UDim2.new(1, 0, 0, 100)
                itemFrame.BackgroundColor3 = bottleneck.severity == "critical" and 
                    StyleGuide.Colors.DangerBackground or StyleGuide.Colors.WarningBackground
                itemFrame.BorderSizePixel = 0
                itemFrame.LayoutOrder = i
                itemFrame.Name = "BottleneckItem_" .. i
                itemFrame.Parent = bottlenecksList
                
                -- Add corner radius
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 4)
                corner.Parent = itemFrame
                
                -- Create layout for the item
                local itemLayout = Instance.new("UIListLayout")
                itemLayout.Padding = UDim.new(0, 5)
                itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
                itemLayout.Parent = itemFrame
                
                -- Create severity indicator
                local severityLabel = StyleGuide.createLabel(
                    bottleneck.severity == "critical" and "CRITICAL" or "WARNING",
                    1
                )
                severityLabel.Size = UDim2.new(1, -20, 0, 20)
                severityLabel.Position = UDim2.new(0, 10, 0, 10)
                severityLabel.TextColor3 = bottleneck.severity == "critical" and 
                    StyleGuide.Colors.Danger or StyleGuide.Colors.Warning
                severityLabel.Font = Enum.Font.SourceSansBold
                severityLabel.Parent = itemFrame
                
                -- Create message label
                local messageLabel = StyleGuide.createLabel(bottleneck.message, 2)
                messageLabel.Size = UDim2.new(1, -20, 0, 40)
                messageLabel.Position = UDim2.new(0, 10, 0, 35)
                messageLabel.TextWrapped = true
                messageLabel.TextYAlignment = Enum.TextYAlignment.Top
                messageLabel.Parent = itemFrame
                
                -- Create timestamp label
                local timestampLabel = StyleGuide.createLabel(
                    "Detected: " .. os.date("%Y-%m-%d %H:%M:%S", bottleneck.timestamp),
                    3
                )
                timestampLabel.Size = UDim2.new(1, -20, 0, 20)
                timestampLabel.Position = UDim2.new(0, 10, 0, 80)
                timestampLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                timestampLabel.TextXAlignment = Enum.TextXAlignment.Right
                timestampLabel.Parent = itemFrame
            end
        else
            -- Show message if no bottlenecks found
            local noDataLabel = StyleGuide.createLabel("No performance bottlenecks detected yet.", 1)
            noDataLabel.Size = UDim2.new(1, 0, 0, 30)
            noDataLabel.Position = UDim2.new(0, 0, 0.5, -15)
            noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
            noDataLabel.Parent = bottlenecksList
        end
    end
    
    -- Update the key performance table
    local keyPerformanceTable = PerformanceAnalyzerUI.dataViews.keyPerformance
    if keyPerformanceTable then
        -- Clear existing table
        keyPerformanceTable:ClearAllChildren()
        
        -- Get key performance data
        local keyPerformance = PerformanceAnalyzer.getKeyPerformance()
        
        -- Convert to table format
        local tableData = {
            headers = {"DataStore:Key", "Operations", "Avg Duration (s)", "Slow Ops", "Failed Ops"},
            rows = {}
        }
        
        for keyId, metrics in pairs(keyPerformance) do
            table.insert(tableData.rows, {
                keyId,
                tostring(metrics.operations),
                string.format("%.3f", metrics.averageDuration),
                tostring(metrics.slowOperations),
                tostring(metrics.failedOperations)
            })
        end
        
        -- Sort by average duration (descending)
        table.sort(tableData.rows, function(a, b)
            return tonumber(a[3]) > tonumber(b[3])
        end)
        
        -- Limit to top 15 slowest keys
        if #tableData.rows > 15 then
            local newRows = {}
            for i = 1, 15 do
                table.insert(newRows, tableData.rows[i])
            end
            tableData.rows = newRows
        end
        
        -- Create the table view
        if #tableData.rows > 0 then
            DataVisualization.createTableView(keyPerformanceTable, tableData)
        else
            -- Show message if no data available
            local noDataLabel = StyleGuide.createLabel("No key performance data available yet.", 1)
            noDataLabel.Size = UDim2.new(1, 0, 0, 30)
            noDataLabel.Position = UDim2.new(0, 0, 0.5, -15)
            noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
            noDataLabel.Parent = keyPerformanceTable
        end
    end
end

-- Update the Suggestions tab
function PerformanceAnalyzerUI.updateSuggestionsTab()
    -- Update the suggestions list
    local suggestionsList = PerformanceAnalyzerUI.dataViews.suggestions
    if suggestionsList then
        -- Clear existing list
        suggestionsList:ClearAllChildren()
        
        -- Restore layout
        local suggestionsLayout = Instance.new("UIListLayout")
        suggestionsLayout.Padding = UDim.new(0, 15)
        suggestionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        suggestionsLayout.Parent = suggestionsList
        
        -- Get suggestions data
        local suggestions = PerformanceAnalyzer.getOptimizationSuggestions()
        
        if #suggestions > 0 then
            -- Create suggestion items
            for i, suggestion in ipairs(suggestions) do
                -- Skip rejected suggestions
                if suggestion.appliedStatus == "rejected" then
                    continue
                end
                
                -- Create suggestion item container
                local itemFrame = Instance.new("Frame")
                itemFrame.Size = UDim2.new(1, 0, 0, 180)
                itemFrame.BackgroundColor3 = StyleGuide.Colors.Background2
                itemFrame.BorderSizePixel = 0
                itemFrame.LayoutOrder = i
                itemFrame.Name = "SuggestionItem_" .. i
                itemFrame.Parent = suggestionsList
                
                -- Add corner radius
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 4)
                corner.Parent = itemFrame
                
                -- Create layout for the item
                local itemLayout = Instance.new("UIListLayout")
                itemLayout.Padding = UDim.new(0, 5)
                itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
                itemLayout.Parent = itemFrame
                
                -- Create header
                local headerLabel = StyleGuide.createLabel("Optimization Suggestion", 1)
                headerLabel.Size = UDim2.new(1, -20, 0, 20)
                headerLabel.Position = UDim2.new(0, 10, 0, 10)
                headerLabel.Font = Enum.Font.SourceSansBold
                headerLabel.TextColor3 = StyleGuide.Colors.Primary
                headerLabel.Parent = itemFrame
                
                -- Create status indicator
                local statusBadge = Instance.new("Frame")
                statusBadge.Size = UDim2.new(0, 80, 0, 20)
                statusBadge.Position = UDim2.new(1, -90, 0, 10)
                statusBadge.BackgroundColor3 = suggestion.appliedStatus == "applied" and 
                    StyleGuide.Colors.Success or StyleGuide.Colors.Warning
                statusBadge.BorderSizePixel = 0
                statusBadge.Name = "StatusBadge"
                statusBadge.Parent = itemFrame
                
                local statusCorner = Instance.new("UICorner")
                statusCorner.CornerRadius = UDim.new(0, 10)
                statusCorner.Parent = statusBadge
                
                local statusLabel = StyleGuide.createLabel(
                    suggestion.appliedStatus == "applied" and "Applied" or "Pending",
                    1
                )
                statusLabel.Size = UDim2.new(1, 0, 1, 0)
                statusLabel.BackgroundTransparency = 1
                statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                statusLabel.TextXAlignment = Enum.TextXAlignment.Center
                statusLabel.Font = Enum.Font.SourceSansBold
                statusLabel.Parent = statusBadge
                
                -- Create message label
                local messageLabel = StyleGuide.createLabel(suggestion.message, 2)
                messageLabel.Size = UDim2.new(1, -20, 0, 40)
                messageLabel.Position = UDim2.new(0, 10, 0, 35)
                messageLabel.TextWrapped = true
                messageLabel.TextYAlignment = Enum.TextYAlignment.Top
                messageLabel.Parent = itemFrame
                
                -- Create implementation code label if available
                if suggestion.implementation then
                    local codeLabel = StyleGuide.createLabel("Suggested Implementation:", 3)
                    codeLabel.Size = UDim2.new(1, -20, 0, 20)
                    codeLabel.Position = UDim2.new(0, 10, 0, 80)
                    codeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                    codeLabel.Parent = itemFrame
                    
                    local codeFrame = Instance.new("Frame")
                    codeFrame.Size = UDim2.new(1, -20, 0, 60)
                    codeFrame.Position = UDim2.new(0, 10, 0, 105)
                    codeFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    codeFrame.BorderSizePixel = 0
                    codeFrame.LayoutOrder = 4
                    codeFrame.Name = "CodeFrame"
                    codeFrame.Parent = itemFrame
                    
                    local codeCorner = Instance.new("UICorner")
                    codeCorner.CornerRadius = UDim.new(0, 4)
                    codeCorner.Parent = codeFrame
                    
                    local codeText = Instance.new("TextLabel")
                    codeText.Size = UDim2.new(1, -20, 1, -10)
                    codeText.Position = UDim2.new(0, 10, 0, 5)
                    codeText.BackgroundTransparency = 1
                    codeText.TextColor3 = Color3.fromRGB(200, 200, 200)
                    codeText.TextXAlignment = Enum.TextXAlignment.Left
                    codeText.TextYAlignment = Enum.TextYAlignment.Top
                    codeText.TextSize = 14
                    codeText.Font = Enum.Font.Code
                    codeText.Text = suggestion.implementation
                    codeText.TextWrapped = true
                    codeText.Parent = codeFrame
                end
                
                -- Create action buttons
                local actionsFrame = Instance.new("Frame")
                actionsFrame.Size = UDim2.new(1, -20, 0, 30)
                actionsFrame.Position = UDim2.new(0, 10, 1, -40)
                actionsFrame.BackgroundTransparency = 1
                actionsFrame.LayoutOrder = 5
                actionsFrame.Name = "ActionsFrame"
                actionsFrame.Parent = itemFrame
                
                -- Only show buttons if not already applied
                if suggestion.appliedStatus == "pending" then
                    local applyButton = StyleGuide.createButton("Apply", true)
                    applyButton.Size = UDim2.new(0.48, 0, 1, 0)
                    applyButton.Position = UDim2.new(0, 0, 0, 0)
                    applyButton.Name = "ApplyButton"
                    applyButton.Parent = actionsFrame
                    
                    local rejectButton = StyleGuide.createButton("Dismiss", false)
                    rejectButton.Size = UDim2.new(0.48, 0, 1, 0)
                    rejectButton.Position = UDim2.new(0.52, 0, 0, 0)
                    rejectButton.Name = "RejectButton"
                    rejectButton.Parent = actionsFrame
                    
                    -- Add button handlers
                    applyButton.MouseButton1Click:Connect(function()
                        PerformanceAnalyzer.applySuggestion(i)
                        PerformanceAnalyzerUI.updateSuggestionsTab()
                    end)
                    
                    rejectButton.MouseButton1Click:Connect(function()
                        PerformanceAnalyzer.rejectSuggestion(i)
                        PerformanceAnalyzerUI.updateSuggestionsTab()
                    end)
                else
                    -- Show applied timestamp if available
                    if suggestion.appliedTimestamp then
                        local appliedLabel = StyleGuide.createLabel(
                            "Applied: " .. os.date("%Y-%m-%d %H:%M:%S", suggestion.appliedTimestamp),
                            1
                        )
                        appliedLabel.Size = UDim2.new(1, 0, 1, 0)
                        appliedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                        appliedLabel.TextXAlignment = Enum.TextXAlignment.Right
                        appliedLabel.Parent = actionsFrame
                    end
                end
            end
            
            -- Update content size to fit all items
            suggestionsList.CanvasSize = UDim2.new(0, 0, 0, suggestionsLayout.AbsoluteContentSize.Y + 20)
        else
            -- Show message if no suggestions available
            local noDataLabel = StyleGuide.createLabel("No optimization suggestions available yet.", 1)
            noDataLabel.Size = UDim2.new(1, 0, 0, 30)
            noDataLabel.Position = UDim2.new(0, 0, 0.5, -15)
            noDataLabel.TextXAlignment = Enum.TextXAlignment.Center
            noDataLabel.Parent = suggestionsList
        end
    end
end

-- Display benchmark results
function PerformanceAnalyzerUI.displayBenchmarkResults(results)
    local resultsContainer = PerformanceAnalyzerUI.dataViews.benchmarkResults.container
    local summaryFrame = PerformanceAnalyzerUI.dataViews.benchmarkResults.summary
    local chartFrame = PerformanceAnalyzerUI.dataViews.benchmarkResults.chart
    
    -- Show the results container
    resultsContainer.Visible = true
    
    -- Clear existing content
    summaryFrame:ClearAllChildren()
    chartFrame:ClearAllChildren()
    
    -- Restore layout
    local summaryLayout = Instance.new("UIListLayout")
    summaryLayout.Padding = UDim.new(0, 10)
    summaryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    summaryLayout.Parent = summaryFrame
    
    -- Create summary labels
    local titleLabel = StyleGuide.createLabel(
        string.format("Benchmark Results: %s on %s:%s", 
            results.operationType, results.dataStore, results.key),
        1
    )
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = summaryFrame
    
    local statsLabel = StyleGuide.createLabel(
        string.format("Avg: %.3fs | Min: %.3fs | Max: %.3fs | Success Rate: %.1f%%",
            results.averageDuration, results.minDuration, results.maxDuration, results.successRate * 100),
        2
    )
    statsLabel.Size = UDim2.new(1, -20, 0, 20)
    statsLabel.Position = UDim2.new(0, 10, 0, 35)
    statsLabel.Parent = summaryFrame
    
    local timeLabel = StyleGuide.createLabel(
        "Run at: " .. os.date("%Y-%m-%d %H:%M:%S", results.timestamp),
        3
    )
    timeLabel.Size = UDim2.new(1, -20, 0, 20)
    timeLabel.Position = UDim2.new(0, 10, 0, 60)
    timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    timeLabel.Parent = summaryFrame
    
    -- Create bar chart for durations
    local iterationLabels = {}
    for i = 1, #results.durations do
        table.insert(iterationLabels, tostring(i))
    end
    
    DataVisualization.createBarChart(
        chartFrame,
        iterationLabels,
        results.durations,
        "Operation Duration by Iteration (seconds)"
    )
end

return PerformanceAnalyzerUI
