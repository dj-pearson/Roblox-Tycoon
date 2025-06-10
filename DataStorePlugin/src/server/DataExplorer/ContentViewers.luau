--[[
    ContentViewers - DataExplorer Content Viewing Manager
    Handles different data viewing modes like JSON Editor, Tree View, etc.
]]

local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

-- Safe module resolver
local function safeRequire(moduleName)
    local success, result = pcall(function()
        return require(script.Parent.Parent:FindFirstChild(moduleName))
    end)
    return success and result or {}
end

-- Import dependencies
local SchemaManager = safeRequire("SchemaManager")
local SessionManager = safeRequire("SessionManager")
local PerformanceMonitor = safeRequire("PerformanceMonitor")
local CacheManager = safeRequire("CacheManager")
local SchemaValidator = safeRequire("SchemaValidator")
local SchemaEditor = safeRequire("SchemaEditor")
local generateSchemaFromData = safeRequire("generateSchemaFromData")

local ContentViewers = {}
local DataExplorer = nil

-- Initialize the module
function ContentViewers.initialize(dataExplorerRef)
    DataExplorer = dataExplorerRef
    print("ContentViewers: Initialized")
end

-- Display key content in the content pane
function ContentViewers.displayKeyContent(dataStoreName, keyName)
    local contentPane = DataExplorer.contentPane
    if not contentPane then return end
    
    -- Clear the content pane
    for _, child in ipairs(contentPane:GetChildren()) do
        child:Destroy()
    end
    
    -- Attempt to acquire a lock for reading/editing
    local lockAcquired = SessionManager.acquireLock and SessionManager.acquireLock(dataStoreName, keyName, DataExplorer.sessionId) or false
    
    -- Create lock notification if not acquired
    if not lockAcquired then
        ContentViewers.createLockNotification(contentPane, dataStoreName, keyName)
    end
    
    -- Create header
    local headerFrame = ContentViewers.createHeaderFrame(contentPane, dataStoreName, keyName, lockAcquired)
    
    -- Create validation message area
    local validationMessageFrame = ContentViewers.createValidationMessageFrame(contentPane, headerFrame)
    
    -- Create tab system
    local tabsFrame, contentArea = ContentViewers.createTabSystem(contentPane, headerFrame, validationMessageFrame)
    
    -- Fetch and display data
    ContentViewers.fetchAndDisplayData(dataStoreName, keyName, tabsFrame, contentArea, validationMessageFrame, lockAcquired)
end

-- Create lock notification
function ContentViewers.createLockNotification(parent, dataStoreName, keyName)
    local lockNotification = Instance.new("Frame")
    lockNotification.Size = UDim2.new(1, 0, 0, 40)
    lockNotification.Position = UDim2.new(0, 0, 0, 0)
    lockNotification.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    lockNotification.BackgroundTransparency = 0.2
    lockNotification.BorderSizePixel = 0
    lockNotification.Parent = parent
    
    local lockIcon = Instance.new("ImageLabel")
    lockIcon.Size = UDim2.new(0, 24, 0, 24)
    lockIcon.Position = UDim2.new(0, 10, 0.5, -12)
    lockIcon.BackgroundTransparency = 1
    lockIcon.Image = "rbxassetid://6031225819"
    lockIcon.Parent = lockNotification
    
    local lockText = Instance.new("TextLabel")
    lockText.Size = UDim2.new(1, -180, 1, 0)
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
    forceUnlockBtn.BorderSizePixel = 0
    forceUnlockBtn.Text = "Force Unlock"
    forceUnlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    forceUnlockBtn.Parent = lockNotification
    
    forceUnlockBtn.MouseButton1Click:Connect(function()
        if SessionManager.forceReleaseLock then
            SessionManager.forceReleaseLock(dataStoreName, keyName)
            ContentViewers.displayKeyContent(dataStoreName, keyName)
        end
    end)
    
    return lockNotification
end

-- Create header frame
function ContentViewers.createHeaderFrame(parent, dataStoreName, keyName, lockAcquired)
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 60)
    headerFrame.Position = UDim2.new(0, 0, 0, lockAcquired and 0 or 50)
    headerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = parent
    
    -- Key title
    local keyTitle = Instance.new("TextLabel")
    keyTitle.Size = UDim2.new(1, -320, 0, 24)
    keyTitle.Position = UDim2.new(0, 10, 0, 5)
    keyTitle.BackgroundTransparency = 1
    keyTitle.Text = keyName
    keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyTitle.TextXAlignment = Enum.TextXAlignment.Left
    keyTitle.Font = Enum.Font.SourceSansBold
    keyTitle.TextSize = 18
    keyTitle.Parent = headerFrame
    
    -- Datastore subtitle
    local datastoreSubtitle = Instance.new("TextLabel")
    datastoreSubtitle.Size = UDim2.new(1, -320, 0, 18)
    datastoreSubtitle.Position = UDim2.new(0, 10, 0, 30)
    datastoreSubtitle.BackgroundTransparency = 1
    datastoreSubtitle.Text = "DataStore: " .. dataStoreName
    datastoreSubtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
    datastoreSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    datastoreSubtitle.Font = Enum.Font.SourceSans
    datastoreSubtitle.TextSize = 14
    datastoreSubtitle.Parent = headerFrame
    
    -- Action panel
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
    
    return headerFrame
end

-- Create validation message frame
function ContentViewers.createValidationMessageFrame(parent, headerFrame)
    local validationMessageFrame = Instance.new("Frame")
    validationMessageFrame.Size = UDim2.new(1, 0, 0, 0)
    validationMessageFrame.Position = UDim2.new(0, 0, 0, headerFrame.Position.Y.Offset + headerFrame.Size.Y.Offset)
    validationMessageFrame.BackgroundTransparency = 1
    validationMessageFrame.Visible = false
    validationMessageFrame.Name = "ValidationMessageFrame"
    validationMessageFrame.Parent = parent
    
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
    
    return validationMessageFrame
end

-- Create tab system
function ContentViewers.createTabSystem(parent, headerFrame, validationMessageFrame)
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Size = UDim2.new(1, 0, 0, 30)
    tabsFrame.Position = UDim2.new(0, 0, 0, headerFrame.Position.Y.Offset + headerFrame.Size.Y.Offset)
    tabsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    tabsFrame.BorderSizePixel = 0
    tabsFrame.Parent = parent
    
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.Padding = UDim.new(0, 2)
    tabsLayout.Parent = tabsFrame
    
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, 0, 1, -(tabsFrame.Position.Y.Offset + tabsFrame.Size.Y.Offset + 10))
    contentArea.Position = UDim2.new(0, 0, 0, tabsFrame.Position.Y.Offset + tabsFrame.Size.Y.Offset + 5)
    contentArea.BackgroundTransparency = 1
    contentArea.Name = "ContentArea"
    contentArea.Parent = parent
    
    return tabsFrame, contentArea
end

-- Function to create a tab
function ContentViewers.createTab(name, selected, parent)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0, 100, 1, 0)
    tab.BackgroundColor3 = selected and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(40, 40, 50)
    tab.BorderSizePixel = 0
    tab.Text = name
    tab.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    tab.Font = Enum.Font.SourceSansSemibold
    tab.Name = "Tab_" .. name
    tab.Parent = parent
    
    return tab
end

-- Function to create a view container
function ContentViewers.createViewContainer(name, parent)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Visible = false
    container.Name = "View_" .. name
    container.Parent = parent
    
    return container
end

-- Function to switch tabs
function ContentViewers.switchTab(selectedTabName, tabsFrame, contentArea)
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

-- Fetch and display data
function ContentViewers.fetchAndDisplayData(dataStoreName, keyName, tabsFrame, contentArea, validationMessageFrame, lockAcquired)
    -- Create tabs and view containers
    local tabJsonEditor = ContentViewers.createTab("JSON Editor", true, tabsFrame)
    local tabTreeView = ContentViewers.createTab("Tree View", false, tabsFrame)
    local tabRawView = ContentViewers.createTab("Raw View", false, tabsFrame)
    local tabVisualizer = ContentViewers.createTab("Visualizer", false, tabsFrame)
    local tabSchema = ContentViewers.createTab("Schema", false, tabsFrame)
    
    local viewJsonEditor = ContentViewers.createViewContainer("JSON Editor", contentArea)
    local viewTreeView = ContentViewers.createViewContainer("Tree View", contentArea)
    local viewRawView = ContentViewers.createViewContainer("Raw View", contentArea)
    local viewVisualizer = ContentViewers.createViewContainer("Visualizer", contentArea)
    local viewSchema = ContentViewers.createViewContainer("Schema", contentArea)
    
    -- Make JSON Editor visible by default
    viewJsonEditor.Visible = true
    
    -- Connect tab click events
    tabJsonEditor.MouseButton1Click:Connect(function() ContentViewers.switchTab("JSON Editor", tabsFrame, contentArea) end)
    tabTreeView.MouseButton1Click:Connect(function() ContentViewers.switchTab("Tree View", tabsFrame, contentArea) end)
    tabRawView.MouseButton1Click:Connect(function() ContentViewers.switchTab("Raw View", tabsFrame, contentArea) end)
    tabVisualizer.MouseButton1Click:Connect(function() ContentViewers.switchTab("Visualizer", tabsFrame, contentArea) end)
    tabSchema.MouseButton1Click:Connect(function() ContentViewers.switchTab("Schema", tabsFrame, contentArea) end)
    
    -- Fetch the data from DataStore
    local dataStore = DataStoreService:GetDataStore(dataStoreName)
    
    -- Check cache first
    local cachedData = CacheManager.get and CacheManager.get(dataStoreName, keyName) or nil
    local success, data, operationDuration
    
    if cachedData then
        success, data = true, cachedData
        print("DataExplorer: Retrieved data from cache for", dataStoreName .. ":" .. keyName)
    else
        if PerformanceMonitor.timeOperation then
            success, data, operationDuration = PerformanceMonitor.timeOperation(
                "GetAsync",
                function() return pcall(dataStore.GetAsync, dataStore, keyName) end,
                dataStoreName,
                keyName
            )
        else
            success, data = pcall(dataStore.GetAsync, dataStore, keyName)
        end
        
        print("Operation: GetAsync, Duration:", operationDuration or "N/A")
        
        -- Cache the data if retrieved successfully
        if success and data and CacheManager.set then
            CacheManager.set(dataStoreName, keyName, data, 300)
        end
    end
    
    if not success or not data then
        ContentViewers.showError(validationMessageFrame, "Error fetching data: " .. (not success and tostring(data) or "No data found"))
        return
    end
    
    -- Convert data to JSON string
    local encodedData = HttpService:JSONEncode(data)
    
    -- Create views
    ContentViewers.createJsonEditorView(viewJsonEditor, encodedData, dataStoreName, keyName, validationMessageFrame, lockAcquired)
    ContentViewers.createTreeView(viewTreeView, data)
    ContentViewers.createRawView(viewRawView, encodedData)
    ContentViewers.createVisualizerView(viewVisualizer, data)
    ContentViewers.createSchemaView(viewSchema, dataStoreName, keyName, encodedData, validationMessageFrame)
end

-- Create JSON Editor view
function ContentViewers.createJsonEditorView(container, encodedData, dataStoreName, keyName, validationMessageFrame, lockAcquired)
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
    jsonEditor.Parent = container
    
    return jsonEditor
end

-- Create Tree View
function ContentViewers.createTreeView(container, data)
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
    
    -- Create tree nodes recursively
    ContentViewers.createTreeNodes(data, 0, treeRoot)
end

-- Create tree nodes recursively
function ContentViewers.createTreeNodes(data, depth, parent)
    if type(data) == "table" then
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
            ContentViewers.createTreeNode(k, data[k], depth, parent)
        end
    else
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, -10, 0, 24)
        valueLabel.Position = UDim2.new(0, 5, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.Text = tostring(data)
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.Font = Enum.Font.Code
        valueLabel.TextSize = 14
        valueLabel.Parent = parent
    end
end

-- Create individual tree node
function ContentViewers.createTreeNode(key, value, depth, parent)
    local nodeFrame = Instance.new("Frame")
    nodeFrame.Size = UDim2.new(1, 0, 0, 24)
    nodeFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    nodeFrame.BackgroundTransparency = 0.2
    nodeFrame.LayoutOrder = #parent:GetChildren()
    nodeFrame.Parent = parent

    local indent = depth * 20
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

        local contentFrame = Instance.new("Frame")
        contentFrame.Size = UDim2.new(1, 0, 0, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Visible = false
        contentFrame.Name = "Content_" .. tostring(key)
        contentFrame.LayoutOrder = nodeFrame.LayoutOrder + 1
        contentFrame.Parent = parent

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = contentFrame

        toggleBtn:SetAttribute("Expanded", false)

        toggleBtn.MouseButton1Click:Connect(function()
            local expanded = toggleBtn:GetAttribute("Expanded")
            expanded = not expanded
            toggleBtn:SetAttribute("Expanded", expanded)
            toggleBtn.Text = expanded and "-" or "+"
            contentFrame.Visible = expanded

            if expanded and not toggleBtn:GetAttribute("ChildrenCreated") then
                toggleBtn:SetAttribute("ChildrenCreated", true)
                ContentViewers.createTreeNodes(value, depth + 1, contentFrame)
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

    -- Value display
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

-- Create Raw View
function ContentViewers.createRawView(container, encodedData)
    local formattedView = Instance.new("ScrollingFrame")
    formattedView.Size = UDim2.new(1, -20, 1, -10)
    formattedView.Position = UDim2.new(0, 10, 0, 5)
    formattedView.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    formattedView.BorderColor3 = Color3.fromRGB(60, 60, 80)
    formattedView.CanvasSize = UDim2.new(0, 0, 0, 0)
    formattedView.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    formattedView.ScrollBarThickness = 6
    formattedView.ScrollingDirection = Enum.ScrollingDirection.Y
    formattedView.Parent = container
    
    local textLayout = Instance.new("UIListLayout")
    textLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textLayout.Parent = formattedView
    
    -- Simply display the JSON as text
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 0, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = encodedData
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.Font = Enum.Font.Code
    textLabel.TextSize = 14
    textLabel.TextWrapped = true
    textLabel.AutomaticSize = Enum.AutomaticSize.Y
    textLabel.Parent = formattedView
end

-- Create Visualizer View
function ContentViewers.createVisualizerView(container, data)
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
    
    -- Analyze data
    local dataSize = #HttpService:JSONEncode(data)
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
end

-- Create Schema View
function ContentViewers.createSchemaView(container, dataStoreName, keyName, encodedData, validationMessageFrame)
    local currentSchema = SchemaManager.loadSchema and SchemaManager.loadSchema(dataStoreName, keyName) or nil
    
    if currentSchema then
        -- Display existing schema
        local schemaInfoFrame = Instance.new("Frame")
        schemaInfoFrame.Size = UDim2.new(1, -20, 0, 40)
        schemaInfoFrame.Position = UDim2.new(0, 10, 0, 10)
        schemaInfoFrame.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
        schemaInfoFrame.BackgroundTransparency = 0.7
        schemaInfoFrame.BorderSizePixel = 0
        schemaInfoFrame.Parent = container
        
        local schemaInfoLabel = Instance.new("TextLabel")
        schemaInfoLabel.Size = UDim2.new(1, -20, 1, 0)
        schemaInfoLabel.Position = UDim2.new(0, 10, 0, 0)
        schemaInfoLabel.BackgroundTransparency = 1
        schemaInfoLabel.Text = "Schema exists for this key"
        schemaInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        schemaInfoLabel.Font = Enum.Font.SourceSansSemibold
        schemaInfoLabel.TextSize = 16
        schemaInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
        schemaInfoLabel.Parent = schemaInfoFrame
    else
        -- No schema - show creation options
        local noSchemaLabel = Instance.new("TextLabel")
        noSchemaLabel.Size = UDim2.new(1, -20, 0, 30)
        noSchemaLabel.Position = UDim2.new(0, 10, 0, 10)
        noSchemaLabel.BackgroundTransparency = 1
        noSchemaLabel.Text = "No schema exists for this key"
        noSchemaLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        noSchemaLabel.Font = Enum.Font.SourceSansSemibold
        noSchemaLabel.TextSize = 16
        noSchemaLabel.TextXAlignment = Enum.TextXAlignment.Left
        noSchemaLabel.Parent = container
        
        local createButton = Instance.new("TextButton")
        createButton.Size = UDim2.new(0, 150, 0, 36)
        createButton.Position = UDim2.new(0, 10, 0, 50)
        createButton.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
        createButton.BorderSizePixel = 0
        createButton.Text = "Create Schema"
        createButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        createButton.Font = Enum.Font.SourceSansSemibold
        createButton.TextSize = 16
        createButton.Parent = container
        
        local createButtonCorner = Instance.new("UICorner")
        createButtonCorner.CornerRadius = UDim.new(0, 4)
        createButtonCorner.Parent = createButton
        
        local generateButton = Instance.new("TextButton")
        generateButton.Size = UDim2.new(0, 200, 0, 36)
        generateButton.Position = UDim2.new(0, 170, 0, 50)
        generateButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        generateButton.BorderSizePixel = 0
        generateButton.Text = "Generate from Data"
        generateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        generateButton.Font = Enum.Font.SourceSansSemibold
        generateButton.TextSize = 16
        generateButton.Parent = container
        
        local generateButtonCorner = Instance.new("UICorner")
        generateButtonCorner.CornerRadius = UDim.new(0, 4)
        generateButtonCorner.Parent = generateButton
        
        generateButton.MouseButton1Click:Connect(function()
            local success, decodedData = pcall(HttpService.JSONDecode, HttpService, encodedData)
            
            if not success then
                ContentViewers.showError(validationMessageFrame, "Invalid JSON: Cannot generate schema")
                return
            end
            
            if generateSchemaFromData then
                local generatedSchema = generateSchemaFromData(decodedData)
                if SchemaManager.saveSchema then
                    SchemaManager.saveSchema(generatedSchema, dataStoreName, keyName)
                end
                ContentViewers.displayKeyContent(dataStoreName, keyName)
            end
        end)
    end
end

-- Show error message
function ContentViewers.showError(validationMessageFrame, message)
    validationMessageFrame.Size = UDim2.new(1, 0, 0, 40)
    validationMessageFrame.Visible = true
    validationMessageFrame.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    validationMessageFrame.BackgroundTransparency = 0.7
    
    local validationMessage = validationMessageFrame:FindFirstChild("ValidationMessage")
    if validationMessage then
        validationMessage.Text = message
        validationMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

return ContentViewers 