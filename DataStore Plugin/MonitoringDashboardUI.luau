--luau
-- DataStore Plugin/MonitoringDashboardUI.luau

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local PerformanceMonitor = require(script.Parent.PerformanceMonitor)
local DataStoreManager = require(script.Parent.DataStoreManager)
local DataVisualization = require(script.Parent.DataVisualization)
local StyleGuide = require(script.Parent.StyleGuide)

-- Module for the Monitoring Dashboard UI
local MonitoringDashboardUI = {}

-- Initialize empty state
local dashboardState = {
    activeTab = "Overview",
    refreshRate = 5, -- seconds
    usageData = {},
    quotaData = {},
    requestData = {},
    errorLogs = {},
    isInitialized = false
}

-- Create the main monitoring dashboard UI
function MonitoringDashboardUI.createDashboardUI(parent)
    -- Main container for the monitoring dashboard
    local container = Instance.new("Frame")
    container.Name = "MonitoringDashboardContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Visible = true
    container.Parent = parent
    
    -- Create the header with title
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "HeaderFrame"
    headerFrame.Size = UDim2.new(1, 0, 0, 50)
    headerFrame.BackgroundColor3 = StyleGuide.getColor("header")
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = container
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Monitoring Dashboard"
    title.TextColor3 = StyleGuide.getColor("text")
    title.TextSize = 24
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = headerFrame
    
    -- Add refresh rate selector
    local refreshRateLabel = Instance.new("TextLabel")
    refreshRateLabel.Name = "RefreshRateLabel"
    refreshRateLabel.Size = UDim2.new(0, 100, 0, 30)
    refreshRateLabel.Position = UDim2.new(1, -220, 0, 10)
    refreshRateLabel.BackgroundTransparency = 1
    refreshRateLabel.Text = "Refresh Rate:"
    refreshRateLabel.TextColor3 = StyleGuide.getColor("text")
    refreshRateLabel.TextSize = 14
    refreshRateLabel.Font = Enum.Font.SourceSans
    refreshRateLabel.TextXAlignment = Enum.TextXAlignment.Right
    refreshRateLabel.Parent = headerFrame
    
    local refreshRateDropdown = Instance.new("TextButton")
    refreshRateDropdown.Name = "RefreshRateDropdown"
    refreshRateDropdown.Size = UDim2.new(0, 80, 0, 30)
    refreshRateDropdown.Position = UDim2.new(1, -110, 0, 10)
    refreshRateDropdown.BackgroundColor3 = StyleGuide.getColor("button")
    refreshRateDropdown.Text = dashboardState.refreshRate .. "s"
    refreshRateDropdown.TextColor3 = StyleGuide.getColor("buttonText")
    refreshRateDropdown.TextSize = 14
    refreshRateDropdown.Font = Enum.Font.SourceSans
    refreshRateDropdown.Parent = headerFrame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 4)
    dropdownCorner.Parent = refreshRateDropdown
    
    -- Create tabs container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.Size = UDim2.new(1, 0, 0, 40)
    tabsContainer.Position = UDim2.new(0, 0, 0, 50)
    tabsContainer.BackgroundColor3 = StyleGuide.getColor("tabBar")
    tabsContainer.BorderSizePixel = 0
    tabsContainer.Parent = container
    
    -- Create the tab buttons
    local function createTab(name, position, selected)
        local tab = Instance.new("TextButton")
        tab.Name = name .. "Tab"
        tab.Size = UDim2.new(0, 100, 1, 0)
        tab.Position = UDim2.new(0, position, 0, 0)
        tab.BackgroundColor3 = selected and StyleGuide.getColor("tabSelected") or StyleGuide.getColor("tab")
        tab.BorderSizePixel = 0
        tab.Text = name
        tab.TextColor3 = selected and StyleGuide.getColor("textSelected") or StyleGuide.getColor("text")
        tab.TextSize = 16
        tab.Font = Enum.Font.SourceSansSemibold
        tab.Parent = tabsContainer
        
        return tab
    end
    
    -- Create content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, -90)
    contentContainer.Position = UDim2.new(0, 0, 0, 90)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = container
    
    -- Create tabs and content areas
    local overviewTab = createTab("Overview", 0, true)
    local usageTab = createTab("Usage", 100, false)
    local quotaTab = createTab("Quota", 200, false)
    local errorTab = createTab("Errors", 300, false)
    
    -- Create content frames for each tab
    local function createContentFrame(name)
        local frame = Instance.new("ScrollingFrame")
        frame.Name = name .. "Content"
        frame.Size = UDim2.new(1, -20, 1, -20)
        frame.Position = UDim2.new(0, 10, 0, 10)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ScrollBarThickness = 6
        frame.ScrollingDirection = Enum.ScrollingDirection.Y
        frame.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.Visible = (name == "Overview")
        frame.Parent = contentContainer
        
        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.Parent = frame
        
        -- Add layout
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 15)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame
        
        return frame
    end
    
    local overviewContent = createContentFrame("Overview")
    local usageContent = createContentFrame("Usage")
    local quotaContent = createContentFrame("Quota")
    local errorContent = createContentFrame("Errors")
    
    -- Tab click handlers
    local function switchToTab(tabName)
        -- Update active tab in state
        dashboardState.activeTab = tabName
        
        -- Update tab visuals
        overviewTab.BackgroundColor3 = (tabName == "Overview") and StyleGuide.getColor("tabSelected") or StyleGuide.getColor("tab")
        usageTab.BackgroundColor3 = (tabName == "Usage") and StyleGuide.getColor("tabSelected") or StyleGuide.getColor("tab")
        quotaTab.BackgroundColor3 = (tabName == "Quota") and StyleGuide.getColor("tabSelected") or StyleGuide.getColor("tab")
        errorTab.BackgroundColor3 = (tabName == "Errors") and StyleGuide.getColor("tabSelected") or StyleGuide.getColor("tab")
        
        overviewTab.TextColor3 = (tabName == "Overview") and StyleGuide.getColor("textSelected") or StyleGuide.getColor("text")
        usageTab.TextColor3 = (tabName == "Usage") and StyleGuide.getColor("textSelected") or StyleGuide.getColor("text")
        quotaTab.TextColor3 = (tabName == "Quota") and StyleGuide.getColor("textSelected") or StyleGuide.getColor("text")
        errorTab.TextColor3 = (tabName == "Errors") and StyleGuide.getColor("textSelected") or StyleGuide.getColor("text")
        
        -- Update content visibility
        overviewContent.Visible = (tabName == "Overview")
        usageContent.Visible = (tabName == "Usage")
        quotaContent.Visible = (tabName == "Quota")
        errorContent.Visible = (tabName == "Errors")
        
        -- Update content for the selected tab
        MonitoringDashboardUI.refreshTabContent(tabName)
    end
    
    overviewTab.MouseButton1Click:Connect(function() switchToTab("Overview") end)
    usageTab.MouseButton1Click:Connect(function() switchToTab("Usage") end)
    quotaTab.MouseButton1Click:Connect(function() switchToTab("Quota") end)
    errorTab.MouseButton1Click:Connect(function() switchToTab("Errors") end)
    
    -- Refresh rate dropdown handler
    local refreshRateMenu = nil
    
    refreshRateDropdown.MouseButton1Click:Connect(function()
        if refreshRateMenu then
            refreshRateMenu:Destroy()
            refreshRateMenu = nil
            return
        end
        
        refreshRateMenu = Instance.new("Frame")
        refreshRateMenu.Name = "RefreshRateMenu"
        refreshRateMenu.Size = UDim2.new(0, 80, 0, 120)
        refreshRateMenu.Position = UDim2.new(1, -110, 0, 40)
        refreshRateMenu.BackgroundColor3 = StyleGuide.getColor("dropdown")
        refreshRateMenu.BorderSizePixel = 0
        refreshRateMenu.ZIndex = 10
        refreshRateMenu.Parent = headerFrame
        
        local menuCorner = Instance.new("UICorner")
        menuCorner.CornerRadius = UDim.new(0, 4)
        menuCorner.Parent = refreshRateMenu
        
        local menuLayout = Instance.new("UIListLayout")
        menuLayout.Padding = UDim.new(0, 0)
        menuLayout.FillDirection = Enum.FillDirection.Vertical
        menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
        menuLayout.Parent = refreshRateMenu
        
        local rates = {1, 5, 10, 30, 60}
        
        for i, rate in ipairs(rates) do
            local option = Instance.new("TextButton")
            option.Name = "Option" .. rate
            option.Size = UDim2.new(1, 0, 0, 24)
            option.BackgroundTransparency = 0.9
            option.BackgroundColor3 = StyleGuide.getColor("button")
            option.Text = rate .. "s"
            option.TextColor3 = StyleGuide.getColor("text")
            option.TextSize = 14
            option.Font = Enum.Font.SourceSans
            option.ZIndex = 11
            option.LayoutOrder = i
            option.Parent = refreshRateMenu
            
            option.MouseButton1Click:Connect(function()
                dashboardState.refreshRate = rate
                refreshRateDropdown.Text = rate .. "s"
                refreshRateMenu:Destroy()
                refreshRateMenu = nil
            end)
        end
    end)
    
    -- Store references to the content frames
    MonitoringDashboardUI.overviewContent = overviewContent
    MonitoringDashboardUI.usageContent = usageContent
    MonitoringDashboardUI.quotaContent = quotaContent
    MonitoringDashboardUI.errorContent = errorContent
    
    -- Initialize content
    MonitoringDashboardUI.refreshTabContent("Overview")
    
    -- Set initialized flag
    dashboardState.isInitialized = true
    
    return container
end

-- Function to create a section header
function MonitoringDashboardUI.createSectionHeader(title, parent)
    local header = Instance.new("Frame")
    header.Name = title:gsub("%s+", "") .. "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundTransparency = 1
    header.LayoutOrder = #parent:GetChildren()
    header.Parent = parent
    
    local headerText = Instance.new("TextLabel")
    headerText.Name = "HeaderText"
    headerText.Size = UDim2.new(1, 0, 1, 0)
    headerText.BackgroundTransparency = 1
    headerText.Text = title
    headerText.TextColor3 = StyleGuide.getColor("sectionHeader")
    headerText.TextSize = 18
    headerText.Font = Enum.Font.SourceSansBold
    headerText.TextXAlignment = Enum.TextXAlignment.Left
    headerText.Parent = header
    
    local underline = Instance.new("Frame")
    underline.Name = "Underline"
    underline.Size = UDim2.new(1, 0, 0, 2)
    underline.Position = UDim2.new(0, 0, 1, -2)
    underline.BackgroundColor3 = StyleGuide.getColor("accent")
    underline.BorderSizePixel = 0
    underline.Parent = header
    
    return header
end

-- Function to create a metric display
function MonitoringDashboardUI.createMetricDisplay(title, value, parent, color)
    local metricFrame = Instance.new("Frame")
    metricFrame.Name = title:gsub("%s+", "") .. "Metric"
    metricFrame.Size = UDim2.new(0, 200, 0, 100)
    metricFrame.BackgroundColor3 = StyleGuide.getColor("card")
    metricFrame.BorderSizePixel = 0
    metricFrame.LayoutOrder = #parent:GetChildren()
    metricFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = metricFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 0, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = StyleGuide.getColor("text")
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansSemibold
    titleLabel.Parent = metricFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(1, 0, 0, 40)
    valueLabel.Position = UDim2.new(0, 0, 0, 35)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = value
    valueLabel.TextColor3 = color or StyleGuide.getColor("accent")
    valueLabel.TextSize = 28
    valueLabel.Font = Enum.Font.SourceSansBold
    valueLabel.Parent = metricFrame
    
    return metricFrame, valueLabel
end

-- Function to create a graph display
function MonitoringDashboardUI.createGraphDisplay(title, data, parent, options)
    options = options or {}
    
    local graphFrame = Instance.new("Frame")
    graphFrame.Name = title:gsub("%s+", "") .. "Graph"
    graphFrame.Size = UDim2.new(1, 0, 0, 250)
    graphFrame.BackgroundColor3 = StyleGuide.getColor("card")
    graphFrame.BorderSizePixel = 0
    graphFrame.LayoutOrder = #parent:GetChildren()
    graphFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = graphFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = StyleGuide.getColor("text")
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = graphFrame
    
    local graphContainer = Instance.new("Frame")
    graphContainer.Name = "GraphContainer"
    graphContainer.Size = UDim2.new(1, -20, 1, -40)
    graphContainer.Position = UDim2.new(0, 10, 0, 35)
    graphContainer.BackgroundTransparency = 1
    graphContainer.BorderSizePixel = 0
    graphContainer.Parent = graphFrame
    
    -- Create the graph based on the type
    local graphType = options.type or "line"
    local graph
    
    if graphType == "line" then
        graph = DataVisualization.createLineChart(data, {
            parent = graphContainer,
            title = "",
            xAxisLabel = options.xAxisLabel or "Time",
            yAxisLabel = options.yAxisLabel or "Value",
            colors = options.colors
        })
    elseif graphType == "bar" then
        graph = DataVisualization.createBarChart(data, {
            parent = graphContainer,
            title = "",
            xAxisLabel = options.xAxisLabel or "Category",
            yAxisLabel = options.yAxisLabel or "Value",
            colors = options.colors
        })
    elseif graphType == "pie" then
        graph = DataVisualization.createPieChart(data, {
            parent = graphContainer,
            title = "",
            colors = options.colors
        })
    end
    
    return graphFrame, graph
end

-- Function to refresh the content of the active tab
function MonitoringDashboardUI.refreshTabContent(tabName)
    if not dashboardState.isInitialized then return end
    
    -- Refresh based on tab
    if tabName == "Overview" then
        MonitoringDashboardUI.refreshOverviewTab()
    elseif tabName == "Usage" then
        MonitoringDashboardUI.refreshUsageTab()
    elseif tabName == "Quota" then
        MonitoringDashboardUI.refreshQuotaTab()
    elseif tabName == "Errors" then
        MonitoringDashboardUI.refreshErrorsTab()
    end
end

-- Function to refresh the Overview tab
function MonitoringDashboardUI.refreshOverviewTab()
    local content = MonitoringDashboardUI.overviewContent
    if not content then return end
    
    -- Clear existing content (except layout)
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    
    -- Get the performance data
    local performanceData = PerformanceMonitor.getPerformanceData()
    local operationSummary = PerformanceMonitor.getOperationSummary()
    
    -- Summary section
    MonitoringDashboardUI.createSectionHeader("Summary", content)
    
    -- Create metric row
    local metricRow = Instance.new("Frame")
    metricRow.Name = "MetricRow"
    metricRow.Size = UDim2.new(1, 0, 0, 100)
    metricRow.BackgroundTransparency = 1
    metricRow.LayoutOrder = #content:GetChildren()
    metricRow.Parent = content
    
    local metricLayout = Instance.new("UIGridLayout")
    metricLayout.CellSize = UDim2.new(0, 200, 0, 100)
    metricLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    metricLayout.FillDirectionMaxCells = 3
    metricLayout.FillDirection = Enum.FillDirection.Horizontal
    metricLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    metricLayout.Parent = metricRow
    
    -- Create metrics
    MonitoringDashboardUI.createMetricDisplay("Total Operations", tostring(operationSummary.totalOperations or 0), metricRow)
    
    local readColor = StyleGuide.getColor("success")
    local writeColor = StyleGuide.getColor("warning")
    local errorColor = StyleGuide.getColor("error")
    
    MonitoringDashboardUI.createMetricDisplay("Read Operations", tostring(operationSummary.reads or 0), metricRow, readColor)
    MonitoringDashboardUI.createMetricDisplay("Write Operations", tostring(operationSummary.writes or 0), metricRow, writeColor)
    
    local successRate = operationSummary.totalOperations > 0 
        and math.floor((operationSummary.totalOperations - (operationSummary.errors or 0)) / operationSummary.totalOperations * 100) 
        or 100
    
    MonitoringDashboardUI.createMetricDisplay("Success Rate", successRate .. "%", metricRow, 
        successRate > 95 and StyleGuide.getColor("success") or 
        successRate > 80 and StyleGuide.getColor("warning") or 
        StyleGuide.getColor("error"))
    
    MonitoringDashboardUI.createMetricDisplay("Avg Response Time", string.format("%.2fms", operationSummary.avgResponseTime or 0), metricRow)
    MonitoringDashboardUI.createMetricDisplay("Error Count", tostring(operationSummary.errors or 0), metricRow, errorColor)
    
    -- Recent activity section
    MonitoringDashboardUI.createSectionHeader("Recent Activity", content)
    
    -- Create recent operations graph
    local timePoints = {}
    local readValues = {}
    local writeValues = {}
    local errorValues = {}
    
    for i = 10, 1, -1 do
        table.insert(timePoints, os.date("%H:%M", os.time() - (i * 60)))
        
        local readCount = math.random(0, 50) -- Replace with actual data
        local writeCount = math.random(0, 30) -- Replace with actual data
        local errorCount = math.random(0, 5) -- Replace with actual data
        
        table.insert(readValues, readCount)
        table.insert(writeValues, writeCount)
        table.insert(errorValues, errorCount)
    end
    
    local recentActivityData = {
        labels = timePoints,
        datasets = {
            {
                label = "Reads",
                data = readValues,
                color = readColor
            },
            {
                label = "Writes",
                data = writeValues,
                color = writeColor
            },
            {
                label = "Errors",
                data = errorValues,
                color = errorColor
            }
        }
    }
    
    MonitoringDashboardUI.createGraphDisplay("Operations (Last 10 Minutes)", recentActivityData, content, {
        type = "line",
        xAxisLabel = "Time",
        yAxisLabel = "Operations"
    })
    
    -- Quota status section
    MonitoringDashboardUI.createSectionHeader("Quota Status", content)
    
    -- Create quota usage graph
    local quotaLabels = {"Reads", "Writes", "GetSortedAsync", "Memory"}
    local quotaValues = {
        math.random(5, 70), -- Replace with actual data
        math.random(5, 50), -- Replace with actual data
        math.random(0, 20), -- Replace with actual data
        math.random(10, 90) -- Replace with actual data
    }
    
    local quotaData = {
        labels = quotaLabels,
        values = quotaValues
    }
    
    local quotaColors = {
        StyleGuide.getColor("reads"),
        StyleGuide.getColor("writes"),
        StyleGuide.getColor("sorted"),
        StyleGuide.getColor("memory")
    }
    
    MonitoringDashboardUI.createGraphDisplay("Current Quota Usage (%)", quotaData, content, {
        type = "bar",
        xAxisLabel = "Quota Type",
        yAxisLabel = "Usage Percentage",
        colors = quotaColors
    })
end

-- Function to refresh the Usage tab
function MonitoringDashboardUI.refreshUsageTab()
    local content = MonitoringDashboardUI.usageContent
    if not content then return end
    
    -- Clear existing content (except layout)
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    
    -- Detail usage statistics
    MonitoringDashboardUI.createSectionHeader("Operation Statistics", content)
    
    -- Create hourly breakdown graph
    local hourlyLabels = {}
    local hourlyReadValues = {}
    local hourlyWriteValues = {}
    
    for i = 0, 23 do
        table.insert(hourlyLabels, string.format("%02d:00", i))
        table.insert(hourlyReadValues, math.random(0, 200)) -- Replace with actual data
        table.insert(hourlyWriteValues, math.random(0, 100)) -- Replace with actual data
    end
    
    local hourlyData = {
        labels = hourlyLabels,
        datasets = {
            {
                label = "Reads",
                data = hourlyReadValues,
                color = StyleGuide.getColor("reads")
            },
            {
                label = "Writes",
                data = hourlyWriteValues,
                color = StyleGuide.getColor("writes")
            }
        }
    }
    
    MonitoringDashboardUI.createGraphDisplay("Hourly Operation Breakdown", hourlyData, content, {
        type = "line",
        xAxisLabel = "Hour",
        yAxisLabel = "Operation Count"
    })
    
    -- Create data store usage section
    MonitoringDashboardUI.createSectionHeader("DataStore Usage", content)
    
    -- Create data store metrics
    -- Get all data stores (sample data)
    local dataStores = {"PlayerData", "GameProgress", "Economy", "Inventory", "Settings"}
    local storeOperations = {}
    local storeMemory = {}
    
    for _, store in ipairs(dataStores) do
        table.insert(storeOperations, math.random(50, 500)) -- Replace with actual data
        table.insert(storeMemory, math.random(100, 1000)) -- Replace with actual data in KB
    end
    
    local operationsData = {
        labels = dataStores,
        values = storeOperations
    }
    
    local memoryData = {
        labels = dataStores,
        values = storeMemory
    }
    
    MonitoringDashboardUI.createGraphDisplay("Operations by DataStore", operationsData, content, {
        type = "bar",
        xAxisLabel = "DataStore",
        yAxisLabel = "Operation Count"
    })
    
    MonitoringDashboardUI.createGraphDisplay("Memory Usage by DataStore (KB)", memoryData, content, {
        type = "bar",
        xAxisLabel = "DataStore",
        yAxisLabel = "Memory (KB)"
    })
    
    -- Response time section
    MonitoringDashboardUI.createSectionHeader("Response Time Analysis", content)
    
    -- Create response time graph
    local timeLabels = {}
    local responseTimeValues = {}
    
    for i = 1, 20 do
        table.insert(timeLabels, "Sample " .. i)
        table.insert(responseTimeValues, math.random(20, 200)) -- Replace with actual data in ms
    end
    
    local responseTimeData = {
        labels = timeLabels,
        datasets = {
            {
                label = "Response Time",
                data = responseTimeValues,
                color = StyleGuide.getColor("accent")
            }
        }
    }
    
    MonitoringDashboardUI.createGraphDisplay("Recent Operation Response Times (ms)", responseTimeData, content, {
        type = "line",
        xAxisLabel = "Operation",
        yAxisLabel = "Response Time (ms)"
    })
end

-- Function to refresh the Quota tab
function MonitoringDashboardUI.refreshQuotaTab()
    local content = MonitoringDashboardUI.quotaContent
    if not content then return end
    
    -- Clear existing content (except layout)
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    
    -- Current quota status
    MonitoringDashboardUI.createSectionHeader("Current Quota Status", content)
    
    -- Create quota metrics row
    local metricRow = Instance.new("Frame")
    metricRow.Name = "QuotaMetricRow"
    metricRow.Size = UDim2.new(1, 0, 0, 100)
    metricRow.BackgroundTransparency = 1
    metricRow.LayoutOrder = #content:GetChildren()
    metricRow.Parent = content
    
    local metricLayout = Instance.new("UIGridLayout")
    metricLayout.CellSize = UDim2.new(0, 200, 0, 100)
    metricLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    metricLayout.FillDirectionMaxCells = 3
    metricLayout.FillDirection = Enum.FillDirection.Horizontal
    metricLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    metricLayout.Parent = metricRow
    
    -- Random quota values (replace with actual)
    local readQuota = math.random(60, 90)
    local writeQuota = math.random(40, 80)
    local sortedQuota = math.random(10, 50)
    local memoryQuota = math.random(50, 95)
    
    local getQuotaColor = function(percentage)
        if percentage < 70 then
            return StyleGuide.getColor("success")
        elseif percentage < 90 then
            return StyleGuide.getColor("warning")
        else
            return StyleGuide.getColor("error")
        end
    end
    
    MonitoringDashboardUI.createMetricDisplay("Read Quota", readQuota .. "%", metricRow, getQuotaColor(readQuota))
    MonitoringDashboardUI.createMetricDisplay("Write Quota", writeQuota .. "%", metricRow, getQuotaColor(writeQuota))
    MonitoringDashboardUI.createMetricDisplay("GetSortedAsync Quota", sortedQuota .. "%", metricRow, getQuotaColor(sortedQuota))
    MonitoringDashboardUI.createMetricDisplay("Memory Quota", memoryQuota .. "%", metricRow, getQuotaColor(memoryQuota))
    MonitoringDashboardUI.createMetricDisplay("Resets In", "56 minutes", metricRow)
    MonitoringDashboardUI.createMetricDisplay("Budget Usage", "$0.23", metricRow)
    
    -- Add detailed quota breakdown
    MonitoringDashboardUI.createSectionHeader("Quota Trends (Last 24 Hours)", content)
    
    -- Create quota trend graph
    local timeLabels = {}
    local readTrend = {}
    local writeTrend = {}
    local sortedTrend = {}
    local memoryTrend = {}
    
    for i = 24, 1, -1 do
        table.insert(timeLabels, string.format("%d hrs ago", i))
        table.insert(readTrend, math.random(30, 95))
        table.insert(writeTrend, math.random(20, 85))
        table.insert(sortedTrend, math.random(5, 60))
        table.insert(memoryTrend, math.random(40, 90))
    end
    
    local trendData = {
        labels = timeLabels,
        datasets = {
            {
                label = "Read Quota",
                data = readTrend,
                color = StyleGuide.getColor("reads")
            },
            {
                label = "Write Quota",
                data = writeTrend,
                color = StyleGuide.getColor("writes")
            },
            {
                label = "GetSortedAsync Quota",
                data = sortedTrend,
                color = StyleGuide.getColor("sorted")
            },
            {
                label = "Memory Quota",
                data = memoryTrend,
                color = StyleGuide.getColor("memory")
            }
        }
    }
    
    MonitoringDashboardUI.createGraphDisplay("Quota Usage Trends", trendData, content, {
        type = "line",
        xAxisLabel = "Time",
        yAxisLabel = "Usage Percentage"
    })
    
    -- Add quota alert settings
    MonitoringDashboardUI.createSectionHeader("Quota Alert Settings", content)
    
    -- Create alert settings container
    local alertsContainer = Instance.new("Frame")
    alertsContainer.Name = "AlertsContainer"
    alertsContainer.Size = UDim2.new(1, 0, 0, 200)
    alertsContainer.BackgroundColor3 = StyleGuide.getColor("card")
    alertsContainer.BorderSizePixel = 0
    alertsContainer.LayoutOrder = #content:GetChildren()
    alertsContainer.Parent = content
    
    local alertsCorner = Instance.new("UICorner")
    alertsCorner.CornerRadius = UDim.new(0, 8)
    alertsCorner.Parent = alertsContainer
    
    local alertsTitle = Instance.new("TextLabel")
    alertsTitle.Name = "Title"
    alertsTitle.Size = UDim2.new(1, -20, 0, 30)
    alertsTitle.Position = UDim2.new(0, 10, 0, 10)
    alertsTitle.BackgroundTransparency = 1
    alertsTitle.Text = "Configure Quota Alert Thresholds"
    alertsTitle.TextColor3 = StyleGuide.getColor("text")
    alertsTitle.TextSize = 16
    alertsTitle.Font = Enum.Font.SourceSansBold
    alertsTitle.TextXAlignment = Enum.TextXAlignment.Left
    alertsTitle.Parent = alertsContainer
    
    -- Create alert threshold sliders (would be functional in a complete implementation)
    local function createAlertSlider(name, value, yPos)
        local sliderContainer = Instance.new("Frame")
        sliderContainer.Name = name .. "SliderContainer"
        sliderContainer.Size = UDim2.new(1, -40, 0, 30)
        sliderContainer.Position = UDim2.new(0, 20, 0, yPos)
        sliderContainer.BackgroundTransparency = 1
        sliderContainer.Parent = alertsContainer
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(0.3, -10, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = name .. " Alert:"
        label.TextColor3 = StyleGuide.getColor("text")
        label.TextSize = 14
        label.Font = Enum.Font.SourceSans
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = sliderContainer
        
        local slider = Instance.new("Frame")
        slider.Name = "Slider"
        slider.Size = UDim2.new(0.5, 0, 0, 10)
        slider.Position = UDim2.new(0.3, 0, 0.5, -5)
        slider.BackgroundColor3 = StyleGuide.getColor("background")
        slider.BorderSizePixel = 0
        slider.Parent = sliderContainer
        
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 5)
        sliderCorner.Parent = slider
        
        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.new(value / 100, 0, 1, 0)
        fill.BackgroundColor3 = StyleGuide.getColor("accent")
        fill.BorderSizePixel = 0
        fill.Parent = slider
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 5)
        fillCorner.Parent = fill
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "Value"
        valueLabel.Size = UDim2.new(0.2, -10, 1, 0)
        valueLabel.Position = UDim2.new(0.8, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = value .. "%"
        valueLabel.TextColor3 = StyleGuide.getColor("text")
        valueLabel.TextSize = 14
        valueLabel.Font = Enum.Font.SourceSansBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = sliderContainer
        
        return sliderContainer
    end
    
    createAlertSlider("Read Quota", 80, 50)
    createAlertSlider("Write Quota", 75, 90)
    createAlertSlider("GetSortedAsync Quota", 70, 130)
    createAlertSlider("Memory Quota", 85, 170)
    
    -- Create a save button
    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveButton"
    saveButton.Size = UDim2.new(0, 100, 0, 30)
    saveButton.Position = UDim2.new(1, -120, 1, -40)
    saveButton.BackgroundColor3 = StyleGuide.getColor("accent")
    saveButton.BorderSizePixel = 0
    saveButton.Text = "Save Settings"
    saveButton.TextColor3 = StyleGuide.getColor("buttonText")
    saveButton.TextSize = 14
    saveButton.Font = Enum.Font.SourceSansBold
    saveButton.Parent = alertsContainer
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 4)
    saveCorner.Parent = saveButton
end

-- Function to refresh the Errors tab
function MonitoringDashboardUI.refreshErrorsTab()
    local content = MonitoringDashboardUI.errorContent
    if not content then return end
    
    -- Clear existing content (except layout)
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    
    -- Error summary section
    MonitoringDashboardUI.createSectionHeader("Error Summary", content)
    
    -- Create error metrics row
    local metricRow = Instance.new("Frame")
    metricRow.Name = "ErrorMetricRow"
    metricRow.Size = UDim2.new(1, 0, 0, 100)
    metricRow.BackgroundTransparency = 1
    metricRow.LayoutOrder = #content:GetChildren()
    metricRow.Parent = content
    
    local metricLayout = Instance.new("UIGridLayout")
    metricLayout.CellSize = UDim2.new(0, 200, 0, 100)
    metricLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    metricLayout.FillDirectionMaxCells = 3
    metricLayout.FillDirection = Enum.FillDirection.Horizontal
    metricLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    metricLayout.Parent = metricRow
    
    -- Sample error metrics
    MonitoringDashboardUI.createMetricDisplay("Total Errors", "27", metricRow, StyleGuide.getColor("error"))
    MonitoringDashboardUI.createMetricDisplay("Quota Errors", "8", metricRow, StyleGuide.getColor("error"))
    MonitoringDashboardUI.createMetricDisplay("Network Errors", "12", metricRow, StyleGuide.getColor("error"))
    MonitoringDashboardUI.createMetricDisplay("Data Corruption", "3", metricRow, StyleGuide.getColor("error"))
    MonitoringDashboardUI.createMetricDisplay("Other Errors", "4", metricRow, StyleGuide.getColor("error"))
    MonitoringDashboardUI.createMetricDisplay("Error Rate", "2.1%", metricRow, StyleGuide.getColor("warning"))
    
    -- Error trend section
    MonitoringDashboardUI.createSectionHeader("Error Trends", content)
    
    -- Create error trend graph
    local timeLabels = {}
    local errorCounts = {}
    
    for i = 24, 1, -1 do
        table.insert(timeLabels, string.format("%d hrs ago", i))
        table.insert(errorCounts, math.random(0, 8))
    end
    
    local errorTrendData = {
        labels = timeLabels,
        datasets = {
            {
                label = "Errors",
                data = errorCounts,
                color = StyleGuide.getColor("error")
            }
        }
    }
    
    MonitoringDashboardUI.createGraphDisplay("Error Frequency (Last 24 Hours)", errorTrendData, content, {
        type = "line",
        xAxisLabel = "Time",
        yAxisLabel = "Error Count"
    })
    
    -- Error breakdown section
    MonitoringDashboardUI.createSectionHeader("Error Type Breakdown", content)
    
    -- Create error type breakdown
    local errorTypes = {"Quota Exceeded", "Network Timeout", "Data Corruption", "Key Not Found", "Other"}
    local errorTypeCounts = {8, 12, 3, 2, 2}
    
    local errorTypeData = {
        labels = errorTypes,
        values = errorTypeCounts
    }
    
    MonitoringDashboardUI.createGraphDisplay("Error Types", errorTypeData, content, {
        type = "pie"
    })
    
    -- Recent errors section
    MonitoringDashboardUI.createSectionHeader("Recent Errors", content)
    
    -- Create recent errors list
    local errorsListFrame = Instance.new("Frame")
    errorsListFrame.Name = "ErrorsListFrame"
    errorsListFrame.Size = UDim2.new(1, 0, 0, 300)
    errorsListFrame.BackgroundColor3 = StyleGuide.getColor("card")
    errorsListFrame.BorderSizePixel = 0
    errorsListFrame.LayoutOrder = #content:GetChildren()
    errorsListFrame.Parent = content
    
    local errorsCorner = Instance.new("UICorner")
    errorsCorner.CornerRadius = UDim.new(0, 8)
    errorsCorner.Parent = errorsListFrame
    
    local errorsList = Instance.new("ScrollingFrame")
    errorsList.Name = "ErrorsList"
    errorsList.Size = UDim2.new(1, -20, 1, -20)
    errorsList.Position = UDim2.new(0, 10, 0, 10)
    errorsList.BackgroundTransparency = 1
    errorsList.BorderSizePixel = 0
    errorsList.ScrollBarThickness = 6
    errorsList.ScrollingDirection = Enum.ScrollingDirection.Y
    errorsList.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    errorsList.CanvasSize = UDim2.new(0, 0, 0, 0)
    errorsList.Parent = errorsListFrame
    
    local errorsLayout = Instance.new("UIListLayout")
    errorsLayout.Padding = UDim.new(0, 5)
    errorsLayout.FillDirection = Enum.FillDirection.Vertical
    errorsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    errorsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    errorsLayout.Parent = errorsList
    
    -- Sample error entries
    local errorMessages = {
        {type = "Quota Exceeded", message = "Read quota exceeded for DataStore 'PlayerData'", time = "2 hours ago"},
        {type = "Network Timeout", message = "Network timeout while writing to DataStore 'GameProgress'", time = "4 hours ago"},
        {type = "Data Corruption", message = "Corrupt data detected in key 'Player_12345'", time = "6 hours ago"},
        {type = "Quota Exceeded", message = "GetSortedAsync quota exceeded", time = "8 hours ago"},
        {type = "Network Timeout", message = "Network timeout while reading from DataStore 'Economy'", time = "9 hours ago"}
    }
    
    for i, error in ipairs(errorMessages) do
        local errorEntry = Instance.new("Frame")
        errorEntry.Name = "ErrorEntry" .. i
        errorEntry.Size = UDim2.new(1, 0, 0, 50)
        errorEntry.BackgroundColor3 = StyleGuide.getColor("errorCard")
        errorEntry.BackgroundTransparency = 0.7
        errorEntry.BorderSizePixel = 0
        errorEntry.LayoutOrder = i
        errorEntry.Parent = errorsList
        
        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0, 4)
        entryCorner.Parent = errorEntry
        
        local errorType = Instance.new("TextLabel")
        errorType.Name = "ErrorType"
        errorType.Size = UDim2.new(0, 120, 0, 20)
        errorType.Position = UDim2.new(0, 10, 0, 5)
        errorType.BackgroundColor3 = StyleGuide.getColor("error")
        errorType.BackgroundTransparency = 0.7
        errorType.Text = error.type
        errorType.TextColor3 = StyleGuide.getColor("text")
        errorType.TextSize = 12
        errorType.Font = Enum.Font.SourceSansBold
        errorType.Parent = errorEntry
        
        local typeCorner = Instance.new("UICorner")
        typeCorner.CornerRadius = UDim.new(0, 4)
        typeCorner.Parent = errorType
        
        local errorMessage = Instance.new("TextLabel")
        errorMessage.Name = "ErrorMessage"
        errorMessage.Size = UDim2.new(1, -140, 0, 20)
        errorMessage.Position = UDim2.new(0, 140, 0, 5)
        errorMessage.BackgroundTransparency = 1
        errorMessage.Text = error.message
        errorMessage.TextColor3 = StyleGuide.getColor("text")
        errorMessage.TextSize = 14
        errorMessage.Font = Enum.Font.SourceSans
        errorMessage.TextXAlignment = Enum.TextXAlignment.Left
        errorMessage.Parent = errorEntry
        
        local errorTime = Instance.new("TextLabel")
        errorTime.Name = "ErrorTime"
        errorTime.Size = UDim2.new(0, 100, 0, 20)
        errorTime.Position = UDim2.new(1, -110, 0, 25)
        errorTime.BackgroundTransparency = 1
        errorTime.Text = error.time
        errorTime.TextColor3 = StyleGuide.getColor("textDimmed")
        errorTime.TextSize = 12
        errorTime.Font = Enum.Font.SourceSans
        errorTime.TextXAlignment = Enum.TextXAlignment.Right
        errorTime.Parent = errorEntry
    end
end

-- Function to start the monitoring refresh loop
function MonitoringDashboardUI.startRefreshLoop()
    task.spawn(function()
        while dashboardState.isInitialized do
            MonitoringDashboardUI.refreshTabContent(dashboardState.activeTab)
            task.wait(dashboardState.refreshRate)
        end
    end)
end

return MonitoringDashboardUI
