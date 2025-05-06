--luau
-- DataStore Plugin/MultiServerCoordinationUI.luau

local DataStoreService = game:GetService("DataStoreService")

local MultiServerCoordination = require(script.Parent.MultiServerCoordination)
local DataVisualization = require(script.Parent.DataVisualization)
local StyleGuide = require(script.Parent.StyleGuide)

-- Module for the Multi-Server Coordination UI
local MultiServerCoordinationUI = {}

-- State for UI
local uiState = {
    isInitialized = false,
    refreshRate = 5, -- seconds
    activeTab = "Servers",
    parentFrame = nil,
    refreshConnection = nil
}

-- Create the main UI
function MultiServerCoordinationUI.createUI(parent)
    if uiState.isInitialized then return end
    
    uiState.parentFrame = parent
    
    -- Container frame
    local container = Instance.new("Frame")
    container.Name = "MultiServerCoordinationContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = StyleGuide.getColor("background")
    container.BorderSizePixel = 0
    container.Parent = parent
    
    -- Header with title
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = StyleGuide.getColor("header")
    header.BorderSizePixel = 0
    header.Parent = container
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Multi-Server Coordination"
    title.TextColor3 = StyleGuide.getColor("text")
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Refresh rate selector
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
    refreshRateLabel.Parent = header
    
    local refreshRateDropdown = Instance.new("TextButton")
    refreshRateDropdown.Name = "RefreshRateDropdown"
    refreshRateDropdown.Size = UDim2.new(0, 80, 0, 30)
    refreshRateDropdown.Position = UDim2.new(1, -110, 0, 10)
    refreshRateDropdown.BackgroundColor3 = StyleGuide.getColor("button")
    refreshRateDropdown.Text = uiState.refreshRate .. "s"
    refreshRateDropdown.TextColor3 = StyleGuide.getColor("buttonText")
    refreshRateDropdown.TextSize = 14
    refreshRateDropdown.Font = Enum.Font.SourceSans
    refreshRateDropdown.Parent = header
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = refreshRateDropdown
    
    -- Create the tab buttons container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.Size = UDim2.new(1, 0, 0, 40)
    tabsContainer.Position = UDim2.new(0, 0, 0, 50)
    tabsContainer.BackgroundColor3 = StyleGuide.getColor("tabBar")
    tabsContainer.BorderSizePixel = 0
    tabsContainer.Parent = container
    
    -- Set up tabs
    local tabs = {
        { name = "Servers", position = 0 },
        { name = "DataAccess", position = 100, display = "Data Access" },
        { name = "Conflicts", position = 200 },
        { name = "Locks", position = 300 },
    }
    
    local tabButtons = {}
    local tabContent = {}
    
    for _, tabInfo in ipairs(tabs) do
        -- Create the tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabInfo.name .. "Tab"
        tabButton.Size = UDim2.new(0, 100, 1, 0)
        tabButton.Position = UDim2.new(0, tabInfo.position, 0, 0)
        tabButton.BackgroundColor3 = uiState.activeTab == tabInfo.name and 
            StyleGuide.getColor("tabSelected") or StyleGuide.getColor("tab")
        tabButton.BorderSizePixel = 0
        tabButton.Text = tabInfo.display or tabInfo.name
        tabButton.TextColor3 = StyleGuide.getColor("tabText")
        tabButton.Font = Enum.Font.SourceSansSemibold
        tabButton.TextSize = 14
        tabButton.Parent = tabsContainer
        
        -- Create the content frame for this tab
        local contentFrame = Instance.new("ScrollingFrame")
        contentFrame.Name = tabInfo.name .. "Content"
        contentFrame.Size = UDim2.new(1, 0, 1, -90) -- Header + Tabs = 90
        contentFrame.Position = UDim2.new(0, 0, 0, 90)
        contentFrame.BackgroundTransparency = 1
        contentFrame.BorderSizePixel = 0
        contentFrame.ScrollBarThickness = 6
        contentFrame.Visible = uiState.activeTab == tabInfo.name
        contentFrame.Parent = container
        
        -- Add padding to the content
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.Parent = contentFrame
        
        -- Set up click handler for tab
        tabButton.MouseButton1Click:Connect(function()
            -- Deselect all tabs
            for _, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = StyleGuide.getColor("tab")
            end
            
            -- Hide all content frames
            for _, content in pairs(tabContent) do
                content.Visible = false
            end
            
            -- Select this tab
            tabButton.BackgroundColor3 = StyleGuide.getColor("tabSelected")
            contentFrame.Visible = true
            
            -- Update active tab
            uiState.activeTab = tabInfo.name
            
            -- Refresh content immediately
            MultiServerCoordinationUI.refreshContent()
        end)
        
        tabButtons[tabInfo.name] = tabButton
        tabContent[tabInfo.name] = contentFrame
    end
    
    -- Set up refresh rate dropdown
    local refreshOptions = {1, 5, 10, 30, 60}
    local dropdownOpen = false
    
    refreshRateDropdown.MouseButton1Click:Connect(function()
        if dropdownOpen then
            -- Close the dropdown
            for _, child in ipairs(refreshRateDropdown:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            dropdownOpen = false
        else
            -- Open the dropdown
            local optionsFrame = Instance.new("Frame")
            optionsFrame.Name = "OptionsFrame"
            optionsFrame.Size = UDim2.new(1, 0, 0, #refreshOptions * 30)
            optionsFrame.Position = UDim2.new(0, 0, 1, 5)
            optionsFrame.BackgroundColor3 = StyleGuide.getColor("dropdown")
            optionsFrame.BorderSizePixel = 0
            optionsFrame.ZIndex = 10
            optionsFrame.Parent = refreshRateDropdown
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = optionsFrame
            
            for i, rate in ipairs(refreshOptions) do
                local option = Instance.new("TextButton")
                option.Name = "Option" .. rate
                option.Size = UDim2.new(1, 0, 0, 30)
                option.Position = UDim2.new(0, 0, 0, (i-1) * 30)
                option.BackgroundTransparency = 1
                option.Text = rate .. "s"
                option.TextColor3 = StyleGuide.getColor("buttonText")
                option.TextSize = 14
                option.Font = Enum.Font.SourceSans
                option.ZIndex = 11
                option.Parent = optionsFrame
                
                option.MouseButton1Click:Connect(function()
                    uiState.refreshRate = rate
                    refreshRateDropdown.Text = rate .. "s"
                    
                    -- Close the dropdown
                    optionsFrame:Destroy()
                    dropdownOpen = false
                    
                    -- Reset the refresh timer
                    if uiState.refreshConnection then
                        uiState.refreshConnection:Disconnect()
                    end
                    
                    MultiServerCoordinationUI.startRefreshLoop()
                end)
            end
            
            dropdownOpen = true
        end
    end)
    
    -- Initialize content for the active tab
    MultiServerCoordinationUI.refreshContent()
    
    -- Start refresh loop
    MultiServerCoordinationUI.startRefreshLoop()
    
    uiState.isInitialized = true
    return container
end

-- Create server list UI
function MultiServerCoordinationUI.createServerListUI(parent)
    -- Clear existing content
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "UIPadding" then
            child:Destroy()
        end
    end
    
    -- Get active servers
    local servers = MultiServerCoordination.getActiveServers()
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = StyleGuide.getColor("subHeader")
    header.BorderSizePixel = 0
    header.Parent = parent
    
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Name = "Title"
    headerTitle.Size = UDim2.new(1, 0, 1, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Active Servers: " .. #servers
    headerTitle.TextColor3 = StyleGuide.getColor("headerText")
    headerTitle.Font = Enum.Font.SourceSansBold
    headerTitle.TextSize = 18
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Server list
    local listFrame = Instance.new("Frame")
    listFrame.Name = "ServerList"
    listFrame.Size = UDim2.new(1, 0, 1, -50)
    listFrame.Position = UDim2.new(0, 0, 0, 50)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = parent
    
    -- Create UI for each server
    for i, server in ipairs(servers) do
        local serverFrame = Instance.new("Frame")
        serverFrame.Name = "Server_" .. i
        serverFrame.Size = UDim2.new(1, 0, 0, 80)
        serverFrame.Position = UDim2.new(0, 0, 0, (i-1) * 90)
        serverFrame.BackgroundColor3 = StyleGuide.getColor("card")
        serverFrame.BorderSizePixel = 0
        serverFrame.Parent = listFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = serverFrame
        
        -- Server ID
        local idLabel = Instance.new("TextLabel")
        idLabel.Name = "ServerID"
        idLabel.Size = UDim2.new(1, -20, 0, 20)
        idLabel.Position = UDim2.new(0, 10, 0, 10)
        idLabel.BackgroundTransparency = 1
        idLabel.Text = "Server ID: " .. string.sub(server.serverId, 1, 8) .. "..."
        idLabel.TextColor3 = StyleGuide.getColor("text")
        idLabel.Font = Enum.Font.SourceSansSemibold
        idLabel.TextSize = 14
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.Parent = serverFrame
        
        -- Job ID
        local jobLabel = Instance.new("TextLabel")
        jobLabel.Name = "JobID"
        jobLabel.Size = UDim2.new(1, -20, 0, 20)
        jobLabel.Position = UDim2.new(0, 10, 0, 30)
        jobLabel.BackgroundTransparency = 1
        jobLabel.Text = "Job ID: " .. string.sub(server.jobId or "N/A", 1, 8) .. "..."
        jobLabel.TextColor3 = StyleGuide.getColor("text")
        jobLabel.Font = Enum.Font.SourceSans
        jobLabel.TextSize = 14
        jobLabel.TextXAlignment = Enum.TextXAlignment.Left
        jobLabel.Parent = serverFrame
        
        -- Player count
        local playersLabel = Instance.new("TextLabel")
        playersLabel.Name = "Players"
        playersLabel.Size = UDim2.new(0, 100, 0, 20)
        playersLabel.Position = UDim2.new(0, 10, 0, 50)
        playersLabel.BackgroundTransparency = 1
        playersLabel.Text = "Players: " .. (server.playerCount or 0)
        playersLabel.TextColor3 = StyleGuide.getColor("text")
        playersLabel.Font = Enum.Font.SourceSans
        playersLabel.TextSize = 14
        playersLabel.TextXAlignment = Enum.TextXAlignment.Left
        playersLabel.Parent = serverFrame
        
        -- Last active
        local timeAgo = os.time() - (server.lastActive or 0)
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Name = "LastActive"
        timeLabel.Size = UDim2.new(0, 150, 0, 20)
        timeLabel.Position = UDim2.new(0, 120, 0, 50)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = "Last active: " .. timeAgo .. " seconds ago"
        timeLabel.TextColor3 = StyleGuide.getColor("text")
        timeLabel.Font = Enum.Font.SourceSans
        timeLabel.TextSize = 14
        timeLabel.TextXAlignment = Enum.TextXAlignment.Left
        timeLabel.Parent = serverFrame
    end
    
    -- If no servers found
    if #servers == 0 then
        local noServersLabel = Instance.new("TextLabel")
        noServersLabel.Name = "NoServers"
        noServersLabel.Size = UDim2.new(1, 0, 0, 60)
        noServersLabel.Position = UDim2.new(0, 0, 0, 50)
        noServersLabel.BackgroundTransparency = 1
        noServersLabel.Text = "No other active servers found"
        noServersLabel.TextColor3 = StyleGuide.getColor("text")
        noServersLabel.Font = Enum.Font.SourceSansItalic
        noServersLabel.TextSize = 16
        noServersLabel.Parent = parent
    end
    
    -- Update scrolling frame canvas size
    parent.CanvasSize = UDim2.new(0, 0, 0, #servers * 90 + 60)
end

-- Create data access log UI
function MultiServerCoordinationUI.createDataAccessUI(parent)
    -- Clear existing content
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "UIPadding" then
            child:Destroy()
        end
    end
    
    -- Get data access log
    local accessLog = MultiServerCoordination.getDataAccessLog()
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = StyleGuide.getColor("subHeader")
    header.BorderSizePixel = 0
    header.Parent = parent
    
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Name = "Title"
    headerTitle.Size = UDim2.new(1, 0, 1, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Data Access Log: " .. #accessLog .. " entries"
    headerTitle.TextColor3 = StyleGuide.getColor("headerText")
    headerTitle.Font = Enum.Font.SourceSansBold
    headerTitle.TextSize = 18
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Column headers
    local columnFrame = Instance.new("Frame")
    columnFrame.Name = "ColumnHeaders"
    columnFrame.Size = UDim2.new(1, 0, 0, 30)
    columnFrame.Position = UDim2.new(0, 0, 0, 50)
    columnFrame.BackgroundColor3 = StyleGuide.getColor("listHeader")
    columnFrame.BorderSizePixel = 0
    columnFrame.Parent = parent
    
    local serverHeader = Instance.new("TextLabel")
    serverHeader.Name = "ServerHeader"
    serverHeader.Size = UDim2.new(0.2, 0, 1, 0)
    serverHeader.BackgroundTransparency = 1
    serverHeader.Text = "Server ID"
    serverHeader.TextColor3 = StyleGuide.getColor("headerText")
    serverHeader.Font = Enum.Font.SourceSansSemibold
    serverHeader.TextSize = 14
    serverHeader.TextXAlignment = Enum.TextXAlignment.Left
    serverHeader.Parent = columnFrame
    
    local storeHeader = Instance.new("TextLabel")
    storeHeader.Name = "StoreHeader"
    storeHeader.Size = UDim2.new(0.25, 0, 1, 0)
    storeHeader.Position = UDim2.new(0.2, 0, 0, 0)
    storeHeader.BackgroundTransparency = 1
    storeHeader.Text = "DataStore"
    storeHeader.TextColor3 = StyleGuide.getColor("headerText")
    storeHeader.Font = Enum.Font.SourceSansSemibold
    storeHeader.TextSize = 14
    storeHeader.TextXAlignment = Enum.TextXAlignment.Left
    storeHeader.Parent = columnFrame
    
    local keyHeader = Instance.new("TextLabel")
    keyHeader.Name = "KeyHeader"
    keyHeader.Size = UDim2.new(0.25, 0, 1, 0)
    keyHeader.Position = UDim2.new(0.45, 0, 0, 0)
    keyHeader.BackgroundTransparency = 1
    keyHeader.Text = "Key"
    keyHeader.TextColor3 = StyleGuide.getColor("headerText")
    keyHeader.Font = Enum.Font.SourceSansSemibold
    keyHeader.TextSize = 14
    keyHeader.TextXAlignment = Enum.TextXAlignment.Left
    keyHeader.Parent = columnFrame
    
    local operationHeader = Instance.new("TextLabel")
    operationHeader.Name = "OperationHeader"
    operationHeader.Size = UDim2.new(0.15, 0, 1, 0)
    operationHeader.Position = UDim2.new(0.7, 0, 0, 0)
    operationHeader.BackgroundTransparency = 1
    operationHeader.Text = "Operation"
    operationHeader.TextColor3 = StyleGuide.getColor("headerText")
    operationHeader.Font = Enum.Font.SourceSansSemibold
    operationHeader.TextSize = 14
    operationHeader.TextXAlignment = Enum.TextXAlignment.Left
    operationHeader.Parent = columnFrame
    
    local timeHeader = Instance.new("TextLabel")
    timeHeader.Name = "TimeHeader"
    timeHeader.Size = UDim2.new(0.15, 0, 1, 0)
    timeHeader.Position = UDim2.new(0.85, 0, 0, 0)
    timeHeader.BackgroundTransparency = 1
    timeHeader.Text = "Time"
    timeHeader.TextColor3 = StyleGuide.getColor("headerText")
    timeHeader.Font = Enum.Font.SourceSansSemibold
    timeHeader.TextSize = 14
    timeHeader.TextXAlignment = Enum.TextXAlignment.Left
    timeHeader.Parent = columnFrame
    
    -- Data rows
    local listFrame = Instance.new("Frame")
    listFrame.Name = "DataList"
    listFrame.Size = UDim2.new(1, 0, 1, -90)
    listFrame.Position = UDim2.new(0, 0, 0, 90)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = parent
    
    -- Create rows for recent entries (last 50 entries, showing most recent first)
    local startIdx = math.max(1, #accessLog - 50 + 1)
    local rowHeight = 30
    
    for i = 0, math.min(49, #accessLog - 1) do
        local idx = #accessLog - i
        local entry = accessLog[idx]
        
        local rowFrame = Instance.new("Frame")
        rowFrame.Name = "Row_" .. i
        rowFrame.Size = UDim2.new(1, 0, 0, rowHeight)
        rowFrame.Position = UDim2.new(0, 0, 0, i * rowHeight)
        rowFrame.BackgroundColor3 = i % 2 == 0 and StyleGuide.getColor("listRowAlt") or StyleGuide.getColor("listRow")
        rowFrame.BorderSizePixel = 0
        rowFrame.Parent = listFrame
        
        local serverCell = Instance.new("TextLabel")
        serverCell.Name = "ServerCell"
        serverCell.Size = UDim2.new(0.2, 0, 1, 0)
        serverCell.BackgroundTransparency = 1
        serverCell.Text = string.sub(entry.serverId or "N/A", 1, 8) .. "..."
        serverCell.TextColor3 = StyleGuide.getColor("text")
        serverCell.Font = Enum.Font.SourceSans
        serverCell.TextSize = 14
        serverCell.TextXAlignment = Enum.TextXAlignment.Left
        serverCell.Parent = rowFrame
        
        local storeCell = Instance.new("TextLabel")
        storeCell.Name = "StoreCell"
        storeCell.Size = UDim2.new(0.25, 0, 1, 0)
        storeCell.Position = UDim2.new(0.2, 0, 0, 0)
        storeCell.BackgroundTransparency = 1
        storeCell.Text = entry.dataStore or "N/A"
        storeCell.TextColor3 = StyleGuide.getColor("text")
        storeCell.Font = Enum.Font.SourceSans
        storeCell.TextSize = 14
        storeCell.TextXAlignment = Enum.TextXAlignment.Left
        storeCell.Parent = rowFrame
        
        local keyCell = Instance.new("TextLabel")
        keyCell.Name = "KeyCell"
        keyCell.Size = UDim2.new(0.25, 0, 1, 0)
        keyCell.Position = UDim2.new(0.45, 0, 0, 0)
        keyCell.BackgroundTransparency = 1
        keyCell.Text = entry.key or "N/A"
        keyCell.TextColor3 = StyleGuide.getColor("text")
        keyCell.Font = Enum.Font.SourceSans
        keyCell.TextSize = 14
        keyCell.TextXAlignment = Enum.TextXAlignment.Left
        keyCell.TextTruncate = Enum.TextTruncate.AtEnd
        keyCell.Parent = rowFrame
        
        local operationCell = Instance.new("TextLabel")
        operationCell.Name = "OperationCell"
        operationCell.Size = UDim2.new(0.15, 0, 1, 0)
        operationCell.Position = UDim2.new(0.7, 0, 0, 0)
        operationCell.BackgroundTransparency = 1
        operationCell.Text = entry.operation or "N/A"
        operationCell.TextColor3 = entry.operation == "write" and 
            Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 200, 255)
        operationCell.Font = Enum.Font.SourceSansSemibold
        operationCell.TextSize = 14
        operationCell.TextXAlignment = Enum.TextXAlignment.Left
        operationCell.Parent = rowFrame
        
        local timeAgo = os.time() - (entry.timestamp or 0)
        local timeCell = Instance.new("TextLabel")
        timeCell.Name = "TimeCell"
        timeCell.Size = UDim2.new(0.15, 0, 1, 0)
        timeCell.Position = UDim2.new(0.85, 0, 0, 0)
        timeCell.BackgroundTransparency = 1
        timeCell.Text = timeAgo .. "s ago"
        timeCell.TextColor3 = StyleGuide.getColor("text")
        timeCell.Font = Enum.Font.SourceSans
        timeCell.TextSize = 14
        timeCell.TextXAlignment = Enum.TextXAlignment.Left
        timeCell.Parent = rowFrame
    end
    
    -- If no data
    if #accessLog == 0 then
        local noDataLabel = Instance.new("TextLabel")
        noDataLabel.Name = "NoData"
        noDataLabel.Size = UDim2.new(1, 0, 0, 60)
        noDataLabel.Position = UDim2.new(0, 0, 0, 90)
        noDataLabel.BackgroundTransparency = 1
        noDataLabel.Text = "No data access logs available"
        noDataLabel.TextColor3 = StyleGuide.getColor("text")
        noDataLabel.Font = Enum.Font.SourceSansItalic
        noDataLabel.TextSize = 16
        noDataLabel.Parent = parent
    end
    
    -- Update scrolling frame canvas size
    parent.CanvasSize = UDim2.new(0, 0, 0, math.min(50, #accessLog) * rowHeight + 90)
end

-- Create conflicts UI
function MultiServerCoordinationUI.createConflictsUI(parent)
    -- Clear existing content
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "UIPadding" then
            child:Destroy()
        end
    end
    
    -- Get conflicts data
    local conflicts = MultiServerCoordination.getPendingConflicts()
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = StyleGuide.getColor("subHeader")
    header.BorderSizePixel = 0
    header.Parent = parent
    
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Name = "Title"
    headerTitle.Size = UDim2.new(1, 0, 1, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Pending Conflicts: " .. #conflicts
    headerTitle.TextColor3 = StyleGuide.getColor("headerText")
    headerTitle.Font = Enum.Font.SourceSansBold
    headerTitle.TextSize = 18
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Conflict list
    local listFrame = Instance.new("Frame")
    listFrame.Name = "ConflictList"
    listFrame.Size = UDim2.new(1, 0, 1, -50)
    listFrame.Position = UDim2.new(0, 0, 0, 50)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = parent
    
    -- Create UI for each conflict
    for i, conflict in ipairs(conflicts) do
        local conflictFrame = Instance.new("Frame")
        conflictFrame.Name = "Conflict_" .. i
        conflictFrame.Size = UDim2.new(1, 0, 0, 120)
        conflictFrame.Position = UDim2.new(0, 0, 0, (i-1) * 130)
        conflictFrame.BackgroundColor3 = StyleGuide.getColor("warning")
        conflictFrame.BorderSizePixel = 0
        conflictFrame.Parent = listFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = conflictFrame
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -20, 0, 30)
        title.Position = UDim2.new(0, 10, 0, 10)
        title.BackgroundTransparency = 1
        title.Text = "Conflict detected in DataStore: " .. conflict.dataStore
        title.TextColor3 = Color3.fromRGB(50, 50, 50)
        title.Font = Enum.Font.SourceSansBold
        title.TextSize = 16
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = conflictFrame
        
        -- Key
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Name = "Key"
        keyLabel.Size = UDim2.new(1, -20, 0, 20)
        keyLabel.Position = UDim2.new(0, 10, 0, 40)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = "Key: " .. conflict.key
        keyLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
        keyLabel.Font = Enum.Font.SourceSansSemibold
        keyLabel.TextSize = 14
        keyLabel.TextXAlignment = Enum.TextXAlignment.Left
        keyLabel.Parent = conflictFrame
        
        -- Servers involved
        local serversLabel = Instance.new("TextLabel")
        serversLabel.Name = "Servers"
        serversLabel.Size = UDim2.new(1, -20, 0, 20)
        serversLabel.Position = UDim2.new(0, 10, 0, 60)
        serversLabel.BackgroundTransparency = 1
        serversLabel.Text = "Servers involved: " .. string.sub(conflict.serverId1, 1, 8) .. "... and " .. string.sub(conflict.serverId2, 1, 8) .. "..."
        serversLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
        serversLabel.Font = Enum.Font.SourceSans
        serversLabel.TextSize = 14
        serversLabel.TextXAlignment = Enum.TextXAlignment.Left
        serversLabel.Parent = conflictFrame
        
        -- Time
        local timeAgo = os.time() - (conflict.timestamp or 0)
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Name = "Time"
        timeLabel.Size = UDim2.new(1, -20, 0, 20)
        timeLabel.Position = UDim2.new(0, 10, 0, 80)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = "Detected: " .. timeAgo .. " seconds ago"
        timeLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
        timeLabel.Font = Enum.Font.SourceSans
        timeLabel.TextSize = 14
        timeLabel.TextXAlignment = Enum.TextXAlignment.Left
        timeLabel.Parent = conflictFrame
    end
    
    -- If no conflicts found
    if #conflicts == 0 then
        local noConflictsLabel = Instance.new("TextLabel")
        noConflictsLabel.Name = "NoConflicts"
        noConflictsLabel.Size = UDim2.new(1, 0, 0, 60)
        noConflictsLabel.Position = UDim2.new(0, 0, 0, 50)
        noConflictsLabel.BackgroundTransparency = 1
        noConflictsLabel.Text = "No pending conflicts detected"
        noConflictsLabel.TextColor3 = StyleGuide.getColor("text")
        noConflictsLabel.Font = Enum.Font.SourceSansItalic
        noConflictsLabel.TextSize = 16
        noConflictsLabel.Parent = parent
    end
    
    -- Update scrolling frame canvas size
    parent.CanvasSize = UDim2.new(0, 0, 0, #conflicts * 130 + 60)
end

-- Create locks UI
function MultiServerCoordinationUI.createLocksUI(parent)
    -- Clear existing content
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "UIPadding" then
            child:Destroy()
        end
    end
    
    -- Get locks data
    local locks = MultiServerCoordination.getActiveLocks()
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = StyleGuide.getColor("subHeader")
    header.BorderSizePixel = 0
    header.Parent = parent
    
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Name = "Title"
    headerTitle.Size = UDim2.new(1, 0, 1, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Active Locks: " .. #locks
    headerTitle.TextColor3 = StyleGuide.getColor("headerText")
    headerTitle.Font = Enum.Font.SourceSansBold
    headerTitle.TextSize = 18
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header
    
    -- Column headers
    local columnFrame = Instance.new("Frame")
    columnFrame.Name = "ColumnHeaders"
    columnFrame.Size = UDim2.new(1, 0, 0, 30)
    columnFrame.Position = UDim2.new(0, 0, 0, 50)
    columnFrame.BackgroundColor3 = StyleGuide.getColor("listHeader")
    columnFrame.BorderSizePixel = 0
    columnFrame.Parent = parent
    
    local storeHeader = Instance.new("TextLabel")
    storeHeader.Name = "StoreHeader"
    storeHeader.Size = UDim2.new(0.35, 0, 1, 0)
    storeHeader.BackgroundTransparency = 1
    storeHeader.Text = "DataStore"
    storeHeader.TextColor3 = StyleGuide.getColor("headerText")
    storeHeader.Font = Enum.Font.SourceSansSemibold
    storeHeader.TextSize = 14
    storeHeader.TextXAlignment = Enum.TextXAlignment.Left
    storeHeader.Parent = columnFrame
    
    local keyHeader = Instance.new("TextLabel")
    keyHeader.Name = "KeyHeader"
    keyHeader.Size = UDim2.new(0.35, 0, 1, 0)
    keyHeader.Position = UDim2.new(0.35, 0, 0, 0)
    keyHeader.BackgroundTransparency = 1
    keyHeader.Text = "Key"
    keyHeader.TextColor3 = StyleGuide.getColor("headerText")
    keyHeader.Font = Enum.Font.SourceSansSemibold
    keyHeader.TextSize = 14
    keyHeader.TextXAlignment = Enum.TextXAlignment.Left
    keyHeader.Parent = columnFrame
    
    local timeHeader = Instance.new("TextLabel")
    timeHeader.Name = "TimeHeader"
    timeHeader.Size = UDim2.new(0.3, 0, 1, 0)
    timeHeader.Position = UDim2.new(0.7, 0, 0, 0)
    timeHeader.BackgroundTransparency = 1
    timeHeader.Text = "Locked Since"
    timeHeader.TextColor3 = StyleGuide.getColor("headerText")
    timeHeader.Font = Enum.Font.SourceSansSemibold
    timeHeader.TextSize = 14
    timeHeader.TextXAlignment = Enum.TextXAlignment.Left
    timeHeader.Parent = columnFrame
    
    -- Data rows
    local listFrame = Instance.new("Frame")
    listFrame.Name = "LocksList"
    listFrame.Size = UDim2.new(1, 0, 1, -90)
    listFrame.Position = UDim2.new(0, 0, 0, 90)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = parent
    
    local rowHeight = 30
    
    for i, lock in ipairs(locks) do
        local rowFrame = Instance.new("Frame")
        rowFrame.Name = "Row_" .. i
        rowFrame.Size = UDim2.new(1, 0, 0, rowHeight)
        rowFrame.Position = UDim2.new(0, 0, 0, (i-1) * rowHeight)
        rowFrame.BackgroundColor3 = i % 2 == 0 and StyleGuide.getColor("listRowAlt") or StyleGuide.getColor("listRow")
        rowFrame.BorderSizePixel = 0
        rowFrame.Parent = listFrame
        
        local storeCell = Instance.new("TextLabel")
        storeCell.Name = "StoreCell"
        storeCell.Size = UDim2.new(0.35, 0, 1, 0)
        storeCell.BackgroundTransparency = 1
        storeCell.Text = lock.dataStore or "N/A"
        storeCell.TextColor3 = StyleGuide.getColor("text")
        storeCell.Font = Enum.Font.SourceSans
        storeCell.TextSize = 14
        storeCell.TextXAlignment = Enum.TextXAlignment.Left
        storeCell.Parent = rowFrame
        
        local keyCell = Instance.new("TextLabel")
        keyCell.Name = "KeyCell"
        keyCell.Size = UDim2.new(0.35, 0, 1, 0)
        keyCell.Position = UDim2.new(0.35, 0, 0, 0)
        keyCell.BackgroundTransparency = 1
        keyCell.Text = lock.key or "N/A"
        keyCell.TextColor3 = StyleGuide.getColor("text")
        keyCell.Font = Enum.Font.SourceSans
        keyCell.TextSize = 14
        keyCell.TextXAlignment = Enum.TextXAlignment.Left
        keyCell.TextTruncate = Enum.TextTruncate.AtEnd
        keyCell.Parent = rowFrame
        
        local timeAgo = os.time() - (lock.timestamp or 0)
        local timeCell = Instance.new("TextLabel")
        timeCell.Name = "TimeCell"
        timeCell.Size = UDim2.new(0.3, 0, 1, 0)
        timeCell.Position = UDim2.new(0.7, 0, 0, 0)
        timeCell.BackgroundTransparency = 1
        timeCell.Text = timeAgo .. " seconds ago"
        timeCell.TextColor3 = StyleGuide.getColor("text")
        timeCell.Font = Enum.Font.SourceSans
        timeCell.TextSize = 14
        timeCell.TextXAlignment = Enum.TextXAlignment.Left
        timeCell.Parent = rowFrame
        
        -- Add release button
        local releaseButton = Instance.new("TextButton")
        releaseButton.Name = "ReleaseButton"
        releaseButton.Size = UDim2.new(0, 60, 0, 20)
        releaseButton.Position = UDim2.new(1, -70, 0, 5)
        releaseButton.BackgroundColor3 = StyleGuide.getColor("warning")
        releaseButton.Text = "Release"
        releaseButton.TextColor3 = Color3.fromRGB(50, 50, 50)
        releaseButton.Font = Enum.Font.SourceSansSemibold
        releaseButton.TextSize = 12
        releaseButton.Parent = rowFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = releaseButton
        
        -- Add release button functionality
        releaseButton.MouseButton1Click:Connect(function()
            MultiServerCoordination.releaseDistributedLock(lock.dataStore, lock.key)
            MultiServerCoordinationUI.refreshContent()
        end)
    end
    
    -- If no locks found
    if #locks == 0 then
        local noLocksLabel = Instance.new("TextLabel")
        noLocksLabel.Name = "NoLocks"
        noLocksLabel.Size = UDim2.new(1, 0, 0, 60)
        noLocksLabel.Position = UDim2.new(0, 0, 0, 90)
        noLocksLabel.BackgroundTransparency = 1
        noLocksLabel.Text = "No active locks found"
        noLocksLabel.TextColor3 = StyleGuide.getColor("text")
        noLocksLabel.Font = Enum.Font.SourceSansItalic
        noLocksLabel.TextSize = 16
        noLocksLabel.Parent = parent
    end
    
    -- Update scrolling frame canvas size
    parent.CanvasSize = UDim2.new(0, 0, 0, #locks * rowHeight + 90)
end

-- Refresh content based on active tab
function MultiServerCoordinationUI.refreshContent()
    if not uiState.isInitialized then return end
    
    local parent = uiState.parentFrame
    if not parent then return end
    
    local activeTabContent = parent:FindFirstChild(uiState.activeTab .. "Content")
    if not activeTabContent then return end
    
    if uiState.activeTab == "Servers" then
        MultiServerCoordinationUI.createServerListUI(activeTabContent)
    elseif uiState.activeTab == "DataAccess" then
        MultiServerCoordinationUI.createDataAccessUI(activeTabContent)
    elseif uiState.activeTab == "Conflicts" then
        MultiServerCoordinationUI.createConflictsUI(activeTabContent)
    elseif uiState.activeTab == "Locks" then
        MultiServerCoordinationUI.createLocksUI(activeTabContent)
    end
end

-- Start the refresh loop
function MultiServerCoordinationUI.startRefreshLoop()
    if uiState.refreshConnection then
        uiState.refreshConnection:Disconnect()
    end
    
    uiState.refreshConnection = task.spawn(function()
        while uiState.isInitialized do
            MultiServerCoordinationUI.refreshContent()
            task.wait(uiState.refreshRate)
        end
    end)
end

-- Initialize the UI system
function MultiServerCoordinationUI.initialize()
    -- Will be fully initialized when createUI is called
    return true
end

return MultiServerCoordinationUI
