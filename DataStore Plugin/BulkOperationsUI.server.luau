--luau
-- DataStore Plugin/BulkOperationsUI.luau

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local BulkOperationsManager = require(script.Parent.BulkOperationsManager)

local BulkOperationsUI = {}

-- Create the bulk operations tab
function BulkOperationsUI.createTab(parent)
    -- Main container for the bulk operations UI
    local container = Instance.new("Frame")
    container.Name = "BulkOperationsContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Visible = false
    container.Parent = parent
      -- Header section
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
    title.Text = "Bulk Operations"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = headerFrame
    
    -- Content section
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -50)
    contentFrame.Position = UDim2.new(0, 0, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = container
      -- Create tabs for different bulk operation types
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
        tab.Size = UDim2.new(0, 100, 1, 0)
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
    local findTab = createTabButton("Find", true)
    local readTab = createTabButton("Read", false)
    local writeTab = createTabButton("Write", false)
    local updateTab = createTabButton("Update", false)
    local deleteTab = createTabButton("Delete", false)
    
    local findContent = createTabContent("Find")
    local readContent = createTabContent("Read")
    local writeContent = createTabContent("Write")
    local updateContent = createTabContent("Update")
    local deleteContent = createTabContent("Delete")
    
    -- Initially show the Find tab content
    findContent.Visible = true
      -- Function to switch between tabs
    local function switchTab(selectedTab)
        -- Update tab button appearance
        findTab.BackgroundColor3 = selectedTab == "Find" and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(46, 46, 46)
        readTab.BackgroundColor3 = selectedTab == "Read" and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(46, 46, 46)
        writeTab.BackgroundColor3 = selectedTab == "Write" and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(46, 46, 46)
        updateTab.BackgroundColor3 = selectedTab == "Update" and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(46, 46, 46)
        deleteTab.BackgroundColor3 = selectedTab == "Delete" and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(46, 46, 46)
        
        -- Update text color
        findTab.TextColor3 = selectedTab == "Find" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        readTab.TextColor3 = selectedTab == "Read" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        writeTab.TextColor3 = selectedTab == "Write" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        updateTab.TextColor3 = selectedTab == "Update" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        deleteTab.TextColor3 = selectedTab == "Delete" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        
        -- Show selected content, hide others
        findContent.Visible = selectedTab == "Find"
        readContent.Visible = selectedTab == "Read"
        writeContent.Visible = selectedTab == "Write"
        updateContent.Visible = selectedTab == "Update"
        deleteContent.Visible = selectedTab == "Delete"
    end
    
    -- Connect tab buttons to switch function
    findTab.MouseButton1Click:Connect(function() switchTab("Find") end)
    readTab.MouseButton1Click:Connect(function() switchTab("Read") end)
    writeTab.MouseButton1Click:Connect(function() switchTab("Write") end)
    updateTab.MouseButton1Click:Connect(function() switchTab("Update") end)
    deleteTab.MouseButton1Click:Connect(function() switchTab("Delete") end)
      -- Helper function to create a labeled input
    local function createLabeledInput(parent, labelText, inputType)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 0, 30)
        container.Position = UDim2.new(0, 10, 0, 0)
        container.BackgroundTransparency = 1
        container.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.3, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(240, 240, 240)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.SourceSans
        label.TextSize = 14
        label.Parent = container
        
        local input
        if inputType == "TextBox" then
            input = Instance.new("TextBox")
            input.Size = UDim2.new(0.7, 0, 1, 0)
            input.Position = UDim2.new(0.3, 0, 0, 0)
            input.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
            input.BorderColor3 = Color3.fromRGB(80, 80, 80)
            input.PlaceholderText = "Enter " .. labelText:lower() .. "..."
            input.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
            input.TextColor3 = Color3.fromRGB(255, 255, 255)
            input.Font = Enum.Font.SourceSans
            input.TextSize = 14
            input.ClearTextOnFocus = false
            input.TextXAlignment = Enum.TextXAlignment.Left        elseif inputType == "Dropdown" then
            input = Instance.new("TextButton")
            input.Size = UDim2.new(0.7, 0, 1, 0)
            input.Position = UDim2.new(0.3, 0, 0, 0)
            input.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
            input.BorderColor3 = Color3.fromRGB(80, 80, 80)
            input.TextColor3 = Color3.fromRGB(255, 255, 255)
            input.Font = Enum.Font.SourceSans
            input.TextSize = 14
            input.TextXAlignment = Enum.TextXAlignment.Left
            input.Text = "Select " .. labelText:lower() .. "..."
        end
        
        input.Parent = container
        return container, input
    end
      -- Helper function to create a button
    local function createButton(parent, text, position, color)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 100, 0, 28)
        button.Position = position or UDim2.new(0, 10, 0, 10)
        button.BackgroundColor3 = color or Color3.fromRGB(66, 133, 244)
        button.BorderSizePixel = 0
        button.Text = text
        button.Font = Enum.Font.SourceSansBold
        button.TextSize = 14
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        -- Add rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = button
        
        button.Parent = parent
        return button
    end
      -- Helper function to create a results display
    local function createResultsDisplay(parent, title)
        local resultsFrame = Instance.new("Frame")
        resultsFrame.Name = "ResultsFrame"
        resultsFrame.Size = UDim2.new(1, -20, 0, 200)
        resultsFrame.Position = UDim2.new(0, 10, 0, 0)
        resultsFrame.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
        resultsFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
        
        -- Add rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = resultsFrame
        
        resultsFrame.Parent = parent
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 26)
        titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        titleLabel.BorderSizePixel = 0
        titleLabel.Text = title or "Results"
        titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
        titleLabel.Font = Enum.Font.SourceSansBold
        titleLabel.TextSize = 14
        titleLabel.Parent = resultsFrame
        
        local resultsContent = Instance.new("ScrollingFrame")
        resultsContent.Name = "Content"
        resultsContent.Size = UDim2.new(1, 0, 1, -30)
        resultsContent.Position = UDim2.new(0, 0, 0, 30)
        resultsContent.BackgroundTransparency = 1
        resultsContent.BorderSizePixel = 0
        resultsContent.ScrollBarThickness = 6
        resultsContent.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        resultsContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        resultsContent.Parent = resultsFrame
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 1)
        layout.Parent = resultsContent
        
        return resultsFrame, resultsContent
    end
      -- Helper function to create a progress bar
    local function createProgressBar(parent)
        local barContainer = Instance.new("Frame")
        barContainer.Name = "ProgressBarContainer"
        barContainer.Size = UDim2.new(1, -20, 0, 40)
        barContainer.Position = UDim2.new(0, 10, 0, 0)
        barContainer.BackgroundTransparency = 1
        barContainer.Visible = false
        barContainer.Parent = parent
        
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.Size = UDim2.new(1, 0, 0, 20)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "Processing..."
        statusLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
        statusLabel.Font = Enum.Font.SourceSans
        statusLabel.TextSize = 14
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.Parent = barContainer
        
        local progressBg = Instance.new("Frame")
        progressBg.Name = "Background"
        progressBg.Size = UDim2.new(1, 0, 0, 16)
        progressBg.Position = UDim2.new(0, 0, 0, 20)
        progressBg.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
        progressBg.BorderColor3 = Color3.fromRGB(80, 80, 80)
        
        -- Add rounded corners for progress bar
        local cornerBg = Instance.new("UICorner")
        cornerBg.CornerRadius = UDim.new(0, 4)
        cornerBg.Parent = progressBg
        
        progressBg.Parent = barContainer
        
        local progressFill = Instance.new("Frame")
        progressFill.Name = "Fill"
        progressFill.Size = UDim2.new(0, 0, 1, 0)
        progressFill.BackgroundColor3 = Color3.fromRGB(66, 133, 244)
        progressFill.BorderSizePixel = 0
        
        -- Add rounded corners for fill
        local cornerFill = Instance.new("UICorner")
        cornerFill.CornerRadius = UDim.new(0, 4)
        cornerFill.Parent = progressFill
        
        progressFill.Parent = progressBg
          local percentLabel = Instance.new("TextLabel")
        percentLabel.Name = "PercentLabel"
        percentLabel.Size = UDim2.new(1, 0, 1, 0)
        percentLabel.BackgroundTransparency = 1
        percentLabel.Text = "0%"
        percentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        percentLabel.Font = Enum.Font.SourceSansSemibold
        percentLabel.TextSize = 13
        percentLabel.Parent = progressBg
        
        local function updateProgress(percent, status)
            progressFill:TweenSize(
                UDim2.new(percent / 100, 0, 1, 0),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.2,
                true
            )
            percentLabel.Text = tostring(math.floor(percent)) .. "%"
            
            if status then
                statusLabel.Text = status
            end
        end
        
        return barContainer, updateProgress
    end
    
    -- Build UI for each operation type
    
    -- Find Operation Tab Content
    local findSpace = 10
    local dataStoreContainer, dataStoreInput = createLabeledInput(findContent, "DataStore", "TextBox")
    dataStoreContainer.Position = UDim2.new(0, 10, 0, findSpace)
    findSpace += 40
    
    local patternContainer, patternInput = createLabeledInput(findContent, "Key Pattern", "TextBox")
    patternContainer.Position = UDim2.new(0, 10, 0, findSpace)
    patternInput.PlaceholderText = "Leave empty for all keys or enter a prefix"
    findSpace += 40
    
    local findButton = createButton(findContent, "Find Keys", UDim2.new(0, 10, 0, findSpace))
    findSpace += 40
    
    local findProgressBar, updateFindProgress = createProgressBar(findContent)
    findProgressBar.Position = UDim2.new(0, 10, 0, findSpace)
    findSpace += 50
    
    local findResults, findResultsContent = createResultsDisplay(findContent, "Found Keys")
    findResults.Position = UDim2.new(0, 10, 0, findSpace)
    
    -- Read Operation Tab Content
    local readSpace = 10
    local readDataStoreContainer, readDataStoreInput = createLabeledInput(readContent, "DataStore", "TextBox")
    readDataStoreContainer.Position = UDim2.new(0, 10, 0, readSpace)
    readSpace += 40
      local keysContainer = Instance.new("Frame")
    keysContainer.Size = UDim2.new(1, -20, 0, 200)
    keysContainer.Position = UDim2.new(0, 10, 0, readSpace)
    keysContainer.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
    keysContainer.BorderColor3 = Color3.fromRGB(80, 80, 80)
    
    -- Add rounded corners
    local keysCorner = Instance.new("UICorner")
    keysCorner.CornerRadius = UDim.new(0, 4)
    keysCorner.Parent = keysContainer
    
    keysContainer.Parent = readContent
    
    local keysLabel = Instance.new("TextLabel")
    keysLabel.Size = UDim2.new(1, 0, 0, 26)
    keysLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    keysLabel.BorderSizePixel = 0
    keysLabel.Text = "Keys to Read (one per line)"
    keysLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    keysLabel.Font = Enum.Font.SourceSansBold
    keysLabel.TextSize = 14
    keysLabel.Parent = keysContainer
      local keysInput = Instance.new("TextBox")
    keysInput.Size = UDim2.new(1, 0, 1, -26)
    keysInput.Position = UDim2.new(0, 0, 0, 26)
    keysInput.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
    keysInput.BorderSizePixel = 0
    keysInput.ClearTextOnFocus = false
    keysInput.PlaceholderText = "Enter one key per line..."
    keysInput.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
    keysInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keysInput.Font = Enum.Font.SourceSans
    keysInput.TextSize = 14
    keysInput.TextYAlignment = Enum.TextYAlignment.Top
    keysInput.TextXAlignment = Enum.TextXAlignment.Left
    keysInput.MultiLine = true
    keysInput.Parent = keysContainer
    
    readSpace += 210
    
    local readButton = createButton(readContent, "Read Keys", UDim2.new(0, 10, 0, readSpace))
    readSpace += 40
    
    local readProgressBar, updateReadProgress = createProgressBar(readContent)
    readProgressBar.Position = UDim2.new(0, 10, 0, readSpace)
    readSpace += 50
    
    local readResults, readResultsContent = createResultsDisplay(readContent, "Read Results")
    readResults.Position = UDim2.new(0, 10, 0, readSpace)
    
    -- Write Operation Tab Content
    local writeSpace = 10
    local writeDataStoreContainer, writeDataStoreInput = createLabeledInput(writeContent, "DataStore", "TextBox")
    writeDataStoreContainer.Position = UDim2.new(0, 10, 0, writeSpace)
    writeSpace += 40
      -- This would be expanded in a real implementation to include key-value pair inputs
    local writeDataContainer = Instance.new("Frame")
    writeDataContainer.Size = UDim2.new(1, -20, 0, 200)
    writeDataContainer.Position = UDim2.new(0, 10, 0, writeSpace)
    writeDataContainer.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
    writeDataContainer.BorderColor3 = Color3.fromRGB(80, 80, 80)
    
    -- Add rounded corners
    local writeDataCorner = Instance.new("UICorner")
    writeDataCorner.CornerRadius = UDim.new(0, 4)
    writeDataCorner.Parent = writeDataContainer
    
    writeDataContainer.Parent = writeContent
    
    local writeDataLabel = Instance.new("TextLabel")
    writeDataLabel.Size = UDim2.new(1, 0, 0, 26)
    writeDataLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    writeDataLabel.BorderSizePixel = 0
    writeDataLabel.Text = "JSON Data to Write (format: {\"key1\": value1, \"key2\": value2, ...})"
    writeDataLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    writeDataLabel.Font = Enum.Font.SourceSansBold
    writeDataLabel.TextSize = 14
    writeDataLabel.Parent = writeDataContainer
    
    local writeDataInput = Instance.new("TextBox")
    writeDataInput.Size = UDim2.new(1, 0, 1, -26)
    writeDataInput.Position = UDim2.new(0, 0, 0, 26)
    writeDataInput.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
    writeDataInput.BorderSizePixel = 0
    writeDataInput.ClearTextOnFocus = false
    writeDataInput.PlaceholderText = "Enter JSON data mapping keys to values..."
    writeDataInput.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
    writeDataInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    writeDataInput.Font = Enum.Font.Code
    writeDataInput.TextSize = 13
    writeDataInput.TextYAlignment = Enum.TextYAlignment.Top
    writeDataInput.TextXAlignment = Enum.TextXAlignment.Left
    writeDataInput.MultiLine = true
    writeDataInput.Parent = writeDataContainer
    
    writeSpace += 210
    
    local writeButton = createButton(writeContent, "Write Data", UDim2.new(0, 10, 0, writeSpace))
    writeSpace += 40
    
    local writeProgressBar, updateWriteProgress = createProgressBar(writeContent)
    writeProgressBar.Position = UDim2.new(0, 10, 0, writeSpace)
    writeSpace += 50
    
    local writeResults, writeResultsContent = createResultsDisplay(writeContent, "Write Results")
    writeResults.Position = UDim2.new(0, 10, 0, writeSpace)
    
    -- Update Operation Tab Content
    local updateSpace = 10
    local updateDataStoreContainer, updateDataStoreInput = createLabeledInput(updateContent, "DataStore", "TextBox")
    updateDataStoreContainer.Position = UDim2.new(0, 10, 0, updateSpace)
    updateSpace += 40
      local updateKeysContainer = Instance.new("Frame")
    updateKeysContainer.Size = UDim2.new(1, -20, 0, 100)
    updateKeysContainer.Position = UDim2.new(0, 10, 0, updateSpace)
    updateKeysContainer.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
    updateKeysContainer.BorderColor3 = Color3.fromRGB(80, 80, 80)
    
    -- Add rounded corners
    local updateKeysCorner = Instance.new("UICorner")
    updateKeysCorner.CornerRadius = UDim.new(0, 4)
    updateKeysCorner.Parent = updateKeysContainer
    
    updateKeysContainer.Parent = updateContent
    
    local updateKeysLabel = Instance.new("TextLabel")
    updateKeysLabel.Size = UDim2.new(1, 0, 0, 26)
    updateKeysLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    updateKeysLabel.BorderSizePixel = 0
    updateKeysLabel.Text = "Keys to Update (one per line)"
    updateKeysLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    updateKeysLabel.Font = Enum.Font.SourceSansBold
    updateKeysLabel.TextSize = 14
    updateKeysLabel.Parent = updateKeysContainer
    
    local updateKeysInput = Instance.new("TextBox")
    updateKeysInput.Size = UDim2.new(1, 0, 1, -26)
    updateKeysInput.Position = UDim2.new(0, 0, 0, 26)
    updateKeysInput.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
    updateKeysInput.BorderSizePixel = 0
    updateKeysInput.ClearTextOnFocus = false
    updateKeysInput.PlaceholderText = "Enter one key per line..."
    updateKeysInput.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
    updateKeysInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    updateKeysInput.Font = Enum.Font.SourceSans
    updateKeysInput.TextSize = 14
    updateKeysInput.TextYAlignment = Enum.TextYAlignment.Top
    updateKeysInput.TextXAlignment = Enum.TextXAlignment.Left
    updateKeysInput.MultiLine = true
    updateKeysInput.Parent = updateKeysContainer
    
    updateSpace += 110
      local transformContainer = Instance.new("Frame")
    transformContainer.Size = UDim2.new(1, -20, 0, 150)
    transformContainer.Position = UDim2.new(0, 10, 0, updateSpace)
    transformContainer.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
    transformContainer.BorderColor3 = Color3.fromRGB(80, 80, 80)
    
    -- Add rounded corners
    local transformCorner = Instance.new("UICorner")
    transformCorner.CornerRadius = UDim.new(0, 4)
    transformCorner.Parent = transformContainer
    
    transformContainer.Parent = updateContent
    
    local transformLabel = Instance.new("TextLabel")
    transformLabel.Size = UDim2.new(1, 0, 0, 26)
    transformLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    transformLabel.BorderSizePixel = 0
    transformLabel.Text = "Transform Function (Lua code that returns updated data)"
    transformLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    transformLabel.Font = Enum.Font.SourceSansBold
    transformLabel.TextSize = 14
    transformLabel.Parent = transformContainer
    
    local transformInput = Instance.new("TextBox")
    transformInput.Size = UDim2.new(1, 0, 1, -26)
    transformInput.Position = UDim2.new(0, 0, 0, 26)
    transformInput.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
    transformInput.BorderSizePixel = 0
    transformInput.ClearTextOnFocus = false
    transformInput.PlaceholderText = "function(data)\n  -- Modify data here\n  return data\nend"
    transformInput.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
    transformInput.Text = "function(data)\n  -- Modify data here\n  return data\nend"
    transformInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    transformInput.Font = Enum.Font.Code
    transformInput.TextSize = 13
    transformInput.TextYAlignment = Enum.TextYAlignment.Top
    transformInput.TextXAlignment = Enum.TextXAlignment.Left
    transformInput.MultiLine = true
    transformInput.Parent = transformContainer
    
    updateSpace += 160
    
    local updateButton = createButton(updateContent, "Update Keys", UDim2.new(0, 10, 0, updateSpace))
    updateSpace += 40
    
    local updateProgressBar, updateUpdateProgress = createProgressBar(updateContent)
    updateProgressBar.Position = UDim2.new(0, 10, 0, updateSpace)
    updateSpace += 50
    
    local updateResults, updateResultsContent = createResultsDisplay(updateContent, "Update Results")
    updateResults.Position = UDim2.new(0, 10, 0, updateSpace)
    
    -- Delete Operation Tab Content
    local deleteSpace = 10
    local deleteDataStoreContainer, deleteDataStoreInput = createLabeledInput(deleteContent, "DataStore", "TextBox")
    deleteDataStoreContainer.Position = UDim2.new(0, 10, 0, deleteSpace)
    deleteSpace += 40
      local deleteKeysContainer = Instance.new("Frame")
    deleteKeysContainer.Size = UDim2.new(1, -20, 0, 200)
    deleteKeysContainer.Position = UDim2.new(0, 10, 0, deleteSpace)
    deleteKeysContainer.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
    deleteKeysContainer.BorderColor3 = Color3.fromRGB(80, 80, 80)
    
    -- Add rounded corners
    local deleteKeysCorner = Instance.new("UICorner")
    deleteKeysCorner.CornerRadius = UDim.new(0, 4)
    deleteKeysCorner.Parent = deleteKeysContainer
    
    deleteKeysContainer.Parent = deleteContent
    
    local deleteKeysLabel = Instance.new("TextLabel")
    deleteKeysLabel.Size = UDim2.new(1, 0, 0, 26)
    deleteKeysLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    deleteKeysLabel.BorderSizePixel = 0
    deleteKeysLabel.Text = "Keys to Delete (one per line)"
    deleteKeysLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    deleteKeysLabel.Font = Enum.Font.SourceSansBold
    deleteKeysLabel.TextSize = 14
    deleteKeysLabel.Parent = deleteKeysContainer
    
    local deleteKeysInput = Instance.new("TextBox")
    deleteKeysInput.Size = UDim2.new(1, 0, 1, -26)
    deleteKeysInput.Position = UDim2.new(0, 0, 0, 26)
    deleteKeysInput.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
    deleteKeysInput.BorderSizePixel = 0
    deleteKeysInput.ClearTextOnFocus = false
    deleteKeysInput.PlaceholderText = "Enter one key per line..."
    deleteKeysInput.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
    deleteKeysInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    deleteKeysInput.Font = Enum.Font.SourceSans
    deleteKeysInput.TextSize = 14
    deleteKeysInput.TextYAlignment = Enum.TextYAlignment.Top
    deleteKeysInput.TextXAlignment = Enum.TextXAlignment.Left
    deleteKeysInput.MultiLine = true
    deleteKeysInput.Parent = deleteKeysContainer
    
    deleteSpace += 210
      local confirmContainer = Instance.new("Frame")
    confirmContainer.Size = UDim2.new(1, -20, 0, 30)
    confirmContainer.Position = UDim2.new(0, 10, 0, deleteSpace)
    confirmContainer.BackgroundTransparency = 1
    confirmContainer.Parent = deleteContent
    
    local confirmCheckbox = Instance.new("TextButton")
    confirmCheckbox.Size = UDim2.new(0, 20, 0, 20)
    confirmCheckbox.Position = UDim2.new(0, 0, 0, 5)
    confirmCheckbox.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
    confirmCheckbox.BorderColor3 = Color3.fromRGB(80, 80, 80)
    confirmCheckbox.Text = ""
    
    -- Add rounded corners
    local checkboxCorner = Instance.new("UICorner")
    checkboxCorner.CornerRadius = UDim.new(0, 3)
    checkboxCorner.Parent = confirmCheckbox
    
    confirmCheckbox.Parent = confirmContainer
    
    local confirmLabel = Instance.new("TextLabel")
    confirmLabel.Size = UDim2.new(1, -30, 1, 0)
    confirmLabel.Position = UDim2.new(0, 30, 0, 0)
    confirmLabel.BackgroundTransparency = 1
    confirmLabel.Text = "I understand that deleting keys is permanent and cannot be undone"
    confirmLabel.TextColor3 = Color3.fromRGB(255, 160, 160)
    confirmLabel.TextXAlignment = Enum.TextXAlignment.Left
    confirmLabel.Font = Enum.Font.SourceSans
    confirmLabel.TextSize = 14
    confirmLabel.Parent = confirmContainer
    
    local isConfirmed = false
    confirmCheckbox.MouseButton1Click:Connect(function()
        isConfirmed = not isConfirmed
        confirmCheckbox.BackgroundColor3 = isConfirmed and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(50, 50, 60)
        confirmCheckbox.Text = isConfirmed and "✓" or ""
    end)
    
    deleteSpace += 40
    
    local deleteButton = createButton(deleteContent, "Delete Keys", UDim2.new(0, 10, 0, deleteSpace), Color3.fromRGB(200, 60, 60))
    deleteSpace += 40
    
    local deleteProgressBar, updateDeleteProgress = createProgressBar(deleteContent)
    deleteProgressBar.Position = UDim2.new(0, 10, 0, deleteSpace)
    deleteSpace += 50
    
    local deleteResults, deleteResultsContent = createResultsDisplay(deleteContent, "Deletion Results")
    deleteResults.Position = UDim2.new(0, 10, 0, deleteSpace)
      -- Active Operations section
    local operationsContainer = Instance.new("Frame")
    operationsContainer.Name = "ActiveOperationsContainer"
    operationsContainer.Size = UDim2.new(1, -20, 0, 36)
    operationsContainer.Position = UDim2.new(0, 10, 1, -46)
    operationsContainer.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
    operationsContainer.BorderColor3 = Color3.fromRGB(80, 80, 80)
    
    -- Add rounded corners
    local operationsCorner = Instance.new("UICorner")
    operationsCorner.CornerRadius = UDim.new(0, 4)
    operationsCorner.Parent = operationsContainer
    
    operationsContainer.Parent = container
    
    local operationsLabel = Instance.new("TextLabel")
    operationsLabel.Size = UDim2.new(0.5, 0, 1, 0)
    operationsLabel.Position = UDim2.new(0, 10, 0, 0)
    operationsLabel.BackgroundTransparency = 1
    operationsLabel.Text = "Active Operations: 0"
    operationsLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    operationsLabel.Font = Enum.Font.SourceSansBold
    operationsLabel.TextSize = 14
    operationsLabel.TextXAlignment = Enum.TextXAlignment.Left
    operationsLabel.Parent = operationsContainer
    
    -- Add Click handling for all button operations
    -- Find button
    findButton.MouseButton1Click:Connect(function()
        -- Clear previous results
        for _, child in pairs(findResultsContent:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        local dataStoreName = dataStoreInput.Text
        local pattern = patternInput.Text
        
        if dataStoreName == "" then
            -- Show error
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "DataStore name is required"
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = findResultsContent
            return
        end
        
        -- Show progress bar
        findProgressBar.Visible = true
        updateFindProgress(0, "Fetching keys...")
        
        -- List keys from the DataStore
        local success, result = pcall(function()
            local dataStore = game:GetService("DataStoreService"):GetDataStore(dataStoreName)
            local keyList = dataStore:ListKeysAsync()
            local matchingKeys = {}
            
            while keyList.IsFinished == false do
                for _, keyInfo in pairs(keyList:GetCurrentPage()) do
                    if pattern == "" or string.find(keyInfo.KeyName, pattern) then
                        table.insert(matchingKeys, keyInfo.KeyName)
                    end
                end
                updateFindProgress(30, "Found " .. #matchingKeys .. " keys so far...")
                keyList:AdvanceToNextPageAsync()
            end
            
            updateFindProgress(100, "Found " .. #matchingKeys .. " keys")
            
            -- Display results
            if #matchingKeys == 0 then
                local noKeysLabel = Instance.new("TextLabel")
                noKeysLabel.Size = UDim2.new(1, -10, 0, 30)
                noKeysLabel.Position = UDim2.new(0, 5, 0, 5)
                noKeysLabel.BackgroundTransparency = 1
                noKeysLabel.Text = "No keys found matching the pattern"
                noKeysLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                noKeysLabel.Font = Enum.Font.SourceSans
                noKeysLabel.TextSize = 14
                noKeysLabel.Parent = findResultsContent
            else
                for i, key in ipairs(matchingKeys) do
                    local keyItem = Instance.new("TextLabel")
                    keyItem.Size = UDim2.new(1, -10, 0, 24)
                    keyItem.Position = UDim2.new(0, 5, 0, (i-1) * 24 + 5)
                    keyItem.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(35, 35, 45) or Color3.fromRGB(40, 40, 50)
                    keyItem.Text = key
                    keyItem.TextColor3 = Color3.fromRGB(220, 220, 220)
                    keyItem.TextXAlignment = Enum.TextXAlignment.Left
                    keyItem.Font = Enum.Font.SourceSans
                    keyItem.TextSize = 14
                    keyItem.Parent = findResultsContent
                end
            end
            
            return matchingKeys
        end)
        
        if not success then
            updateFindProgress(100, "Error: " .. tostring(result))
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "Error: " .. tostring(result)
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = findResultsContent
        end
    end)
      -- Read button
    readButton.MouseButton1Click:Connect(function()
        -- Implementation similar to find button, but using BulkOperationsManager.bulkRead
        local dataStoreName = readDataStoreInput.Text
        local keysText = keysInput.Text
        
        if dataStoreName == "" or keysText == "" then
            -- Show error
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "DataStore name and at least one key are required"
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = readResultsContent
            return
        end
        
        -- Parse keys from input
        local keys = {}
        for line in string.gmatch(keysText, "[^\r\n]+") do
            if line ~= "" then
                table.insert(keys, line)
            end
        end
        
        if #keys == 0 then
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "No valid keys entered"
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = readResultsContent
            return
        end
        
        -- Show progress bar
        readProgressBar.Visible = true
        updateReadProgress(0, "Starting bulk read operation...")
        
        -- Start the bulk read operation
        local operationId = BulkOperationsManager.bulkRead(dataStoreName, keys)
        
        -- Monitor the operation progress
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local status = BulkOperationsManager.getOperationStatus(operationId)
            if not status then
                connection:Disconnect()
                return
            end
            
            updateReadProgress(status.progress, string.format("Processing: %d/%d keys", status.processed, #status.keys))
            
            if not status.inProgress then
                connection:Disconnect()
                
                -- Clear previous results
                for _, child in pairs(readResultsContent:GetChildren()) do
                    if not child:IsA("UIListLayout") then
                        child:Destroy()
                    end
                end
                
                -- Display results
                local resultsHeader = Instance.new("TextLabel")
                resultsHeader.Size = UDim2.new(1, -10, 0, 30)
                resultsHeader.Position = UDim2.new(0, 5, 0, 5)
                resultsHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                resultsHeader.Text = string.format("Results: %d successful, %d failed", status.successful, status.failed)
                resultsHeader.TextColor3 = Color3.fromRGB(220, 220, 220)
                resultsHeader.Font = Enum.Font.SourceSansBold
                resultsHeader.TextSize = 14
                resultsHeader.Parent = readResultsContent
                
                local yOffset = 40
                
                for key, result in pairs(status.results) do
                    local keyLabel = Instance.new("TextLabel")
                    keyLabel.Size = UDim2.new(1, -10, 0, 24)
                    keyLabel.Position = UDim2.new(0, 5, 0, yOffset)
                    keyLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    keyLabel.Text = key
                    keyLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
                    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
                    keyLabel.Font = Enum.Font.SourceSansBold
                    keyLabel.TextSize = 14
                    keyLabel.Parent = readResultsContent
                    
                    yOffset += 24
                    
                    local valueJson = HttpService:JSONEncode(result)
                    local valueLabel = Instance.new("TextLabel")
                    valueLabel.Size = UDim2.new(1, -30, 0, 24)
                    valueLabel.Position = UDim2.new(0, 25, 0, yOffset)
                    valueLabel.BackgroundTransparency = 1
                    valueLabel.Text = string.sub(valueJson, 1, 100) .. (string.len(valueJson) > 100 and "..." or "")
                    valueLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
                    valueLabel.Font = Enum.Font.SourceSans
                    valueLabel.TextSize = 14
                    valueLabel.Parent = readResultsContent
                    
                    yOffset += 30
                end
                
                for key, error in pairs(status.errors) do
                    local errorLabel = Instance.new("TextLabel")
                    errorLabel.Size = UDim2.new(1, -10, 0, 24)
                    errorLabel.Position = UDim2.new(0, 5, 0, yOffset)
                    errorLabel.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
                    errorLabel.Text = key .. " - Error: " .. tostring(error)
                    errorLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
                    errorLabel.TextXAlignment = Enum.TextXAlignment.Left
                    errorLabel.Font = Enum.Font.SourceSans
                    errorLabel.TextSize = 14
                    errorLabel.Parent = readResultsContent
                    
                    yOffset += 30
                end
            end
        end)
    end)

    -- Write button
    writeButton.MouseButton1Click:Connect(function()
        -- Clear previous results
        for _, child in pairs(writeResultsContent:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        local dataStoreName = writeDataStoreInput.Text
        local jsonData = writeDataInput.Text
        
        if dataStoreName == "" or jsonData == "" then
            -- Show error
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "DataStore name and JSON data are required"
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = writeResultsContent
            return
        end
        
        -- Parse JSON data
        local success, keyValueMap = pcall(function()
            return HttpService:JSONDecode(jsonData)
        end)
        
        if not success or type(keyValueMap) ~= "table" then
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "Invalid JSON data: " .. (not success and keyValueMap or "Expected a table with key-value pairs")
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = writeResultsContent
            return
        end
        
        -- Count the number of keys
        local keyCount = 0
        for _ in pairs(keyValueMap) do
            keyCount += 1
        end
        
        if keyCount == 0 then
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "No key-value pairs found in the JSON data"
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = writeResultsContent
            return
        end
        
        -- Show progress bar
        writeProgressBar.Visible = true
        updateWriteProgress(0, "Starting bulk write operation...")
        
        -- Start the bulk write operation
        local operationId = BulkOperationsManager.bulkWrite(dataStoreName, keyValueMap)
        
        -- Monitor the operation progress
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local status = BulkOperationsManager.getOperationStatus(operationId)
            if not status then
                connection:Disconnect()
                return
            end
            
            updateWriteProgress(status.progress, string.format("Processing: %d/%d keys", status.processed, #status.keys))
            
            if not status.inProgress then
                connection:Disconnect()
                
                -- Display results
                local resultsHeader = Instance.new("TextLabel")
                resultsHeader.Size = UDim2.new(1, -10, 0, 30)
                resultsHeader.Position = UDim2.new(0, 5, 0, 5)
                resultsHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                resultsHeader.Text = string.format("Results: %d successful, %d failed", status.successful, status.failed)
                resultsHeader.TextColor3 = Color3.fromRGB(220, 220, 220)
                resultsHeader.Font = Enum.Font.SourceSansBold
                resultsHeader.TextSize = 14
                resultsHeader.Parent = writeResultsContent
                
                local yOffset = 40
                
                for key, _ in pairs(status.results) do
                    local keyLabel = Instance.new("TextLabel")
                    keyLabel.Size = UDim2.new(1, -10, 0, 24)
                    keyLabel.Position = UDim2.new(0, 5, 0, yOffset)
                    keyLabel.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
                    keyLabel.Text = key .. " - Successfully written"
                    keyLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
                    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
                    keyLabel.Font = Enum.Font.SourceSans
                    keyLabel.TextSize = 14
                    keyLabel.Parent = writeResultsContent
                    
                    yOffset += 30
                end
                
                for key, error in pairs(status.errors) do
                    local errorLabel = Instance.new("TextLabel")
                    errorLabel.Size = UDim2.new(1, -10, 0, 24)
                    errorLabel.Position = UDim2.new(0, 5, 0, yOffset)
                    errorLabel.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
                    errorLabel.Text = key .. " - Error: " .. tostring(error)
                    errorLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
                    errorLabel.TextXAlignment = Enum.TextXAlignment.Left
                    errorLabel.Font = Enum.Font.SourceSans
                    errorLabel.TextSize = 14
                    errorLabel.Parent = writeResultsContent
                    
                    yOffset += 30
                end
            end
        end)
    end)
    
    -- Update button
    updateButton.MouseButton1Click:Connect(function()
        -- Clear previous results
        for _, child in pairs(updateResultsContent:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        local dataStoreName = updateDataStoreInput.Text
        local keysText = updateKeysInput.Text
        local transformCode = transformInput.Text
        
        if dataStoreName == "" or keysText == "" or transformCode == "" then
            -- Show error
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "DataStore name, keys, and transform function are required"
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = updateResultsContent
            return
        end
        
        -- Parse keys from input
        local keys = {}
        for line in string.gmatch(keysText, "[^\r\n]+") do
            if line ~= "" then
                table.insert(keys, line)
            end
        end
        
        if #keys == 0 then
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "No valid keys entered"
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = updateResultsContent
            return
        end
        
        -- Try to compile the transform function
        local transformFunc, compileError = loadstring("return " .. transformCode)
        if not transformFunc then
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "Error in transform function: " .. tostring(compileError)
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = updateResultsContent
            return
        end
        
        -- Execute to get the actual function
        local success, result = pcall(transformFunc)
        if not success or type(result) ~= "function" then
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "Transform code must return a function: " .. tostring(result)
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = updateResultsContent
            return
        end
        
        -- Show progress bar
        updateProgressBar.Visible = true
        updateUpdateProgress(0, "Starting bulk update operation...")
        
        -- Start the bulk update operation
        local operationId = BulkOperationsManager.bulkTransform(dataStoreName, keys, result)
        
        -- Monitor the operation progress
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local status = BulkOperationsManager.getOperationStatus(operationId)
            if not status then
                connection:Disconnect()
                return
            end
            
            updateUpdateProgress(status.progress, string.format("Processing: %d/%d keys", status.processed, #status.keys))
            
            if not status.inProgress then
                connection:Disconnect()
                
                -- Display results
                local resultsHeader = Instance.new("TextLabel")
                resultsHeader.Size = UDim2.new(1, -10, 0, 30)
                resultsHeader.Position = UDim2.new(0, 5, 0, 5)
                resultsHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                resultsHeader.Text = string.format("Results: %d successful, %d failed", status.successful, status.failed)
                resultsHeader.TextColor3 = Color3.fromRGB(220, 220, 220)
                resultsHeader.Font = Enum.Font.SourceSansBold
                resultsHeader.TextSize = 14
                resultsHeader.Parent = updateResultsContent
                
                local yOffset = 40
                
                for key, _ in pairs(status.results) do
                    local keyLabel = Instance.new("TextLabel")
                    keyLabel.Size = UDim2.new(1, -10, 0, 24)
                    keyLabel.Position = UDim2.new(0, 5, 0, yOffset)
                    keyLabel.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
                    keyLabel.Text = key .. " - Successfully updated"
                    keyLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
                    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
                    keyLabel.Font = Enum.Font.SourceSans
                    keyLabel.TextSize = 14
                    keyLabel.Parent = updateResultsContent
                    
                    yOffset += 30
                end
                
                for key, error in pairs(status.errors) do
                    local errorLabel = Instance.new("TextLabel")
                    errorLabel.Size = UDim2.new(1, -10, 0, 24)
                    errorLabel.Position = UDim2.new(0, 5, 0, yOffset)
                    errorLabel.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
                    errorLabel.Text = key .. " - Error: " .. tostring(error)
                    errorLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
                    errorLabel.TextXAlignment = Enum.TextXAlignment.Left
                    errorLabel.Font = Enum.Font.SourceSans
                    errorLabel.TextSize = 14
                    errorLabel.Parent = updateResultsContent
                    
                    yOffset += 30
                end
            end
        end)
    end)
    
    -- Delete button
    deleteButton.MouseButton1Click:Connect(function()
        -- Clear previous results
        for _, child in pairs(deleteResultsContent:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        local dataStoreName = deleteDataStoreInput.Text
        local keysText = deleteKeysInput.Text
        
        if dataStoreName == "" or keysText == "" then
            -- Show error
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "DataStore name and keys are required"
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = deleteResultsContent
            return
        end
        
        if not isConfirmed then
            -- Show error
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "You must confirm deletion by checking the confirmation box"
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = deleteResultsContent
            return
        end
        
        -- Parse keys from input
        local keys = {}
        for line in string.gmatch(keysText, "[^\r\n]+") do
            if line ~= "" then
                table.insert(keys, line)
            end
        end
        
        if #keys == 0 then
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Size = UDim2.new(1, -10, 0, 30)
            errorLabel.Position = UDim2.new(0, 5, 0, 5)
            errorLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            errorLabel.BackgroundTransparency = 0.7
            errorLabel.Text = "No valid keys entered"
            errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorLabel.Font = Enum.Font.SourceSans
            errorLabel.TextSize = 14
            errorLabel.Parent = deleteResultsContent
            return
        end
        
        -- Show progress bar
        deleteProgressBar.Visible = true
        updateDeleteProgress(0, "Starting bulk delete operation...")
        
        -- Start the bulk delete operation
        local operationId = BulkOperationsManager.bulkDelete(dataStoreName, keys)
        
        -- Monitor the operation progress
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local status = BulkOperationsManager.getOperationStatus(operationId)
            if not status then
                connection:Disconnect()
                return
            end
            
            updateDeleteProgress(status.progress, string.format("Processing: %d/%d keys", status.processed, #status.keys))
            
            if not status.inProgress then
                connection:Disconnect()
                
                -- Display results
                local resultsHeader = Instance.new("TextLabel")
                resultsHeader.Size = UDim2.new(1, -10, 0, 30)
                resultsHeader.Position = UDim2.new(0, 5, 0, 5)
                resultsHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                resultsHeader.Text = string.format("Results: %d successful, %d failed", status.successful, status.failed)
                resultsHeader.TextColor3 = Color3.fromRGB(220, 220, 220)
                resultsHeader.Font = Enum.Font.SourceSansBold
                resultsHeader.TextSize = 14
                resultsHeader.Parent = deleteResultsContent
                
                local yOffset = 40
                
                for key, _ in pairs(status.results) do
                    local keyLabel = Instance.new("TextLabel")
                    keyLabel.Size = UDim2.new(1, -10, 0, 24)
                    keyLabel.Position = UDim2.new(0, 5, 0, yOffset)
                    keyLabel.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
                    keyLabel.Text = key .. " - Successfully deleted"
                    keyLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
                    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
                    keyLabel.Font = Enum.Font.SourceSans
                    keyLabel.TextSize = 14
                    keyLabel.Parent = deleteResultsContent
                    
                    yOffset += 30
                end
                
                for key, error in pairs(status.errors) do
                    local errorLabel = Instance.new("TextLabel")
                    errorLabel.Size = UDim2.new(1, -10, 0, 24)
                    errorLabel.Position = UDim2.new(0, 5, 0, yOffset)
                    errorLabel.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
                    errorLabel.Text = key .. " - Error: " .. tostring(error)
                    errorLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
                    errorLabel.TextXAlignment = Enum.TextXAlignment.Left
                    errorLabel.Font = Enum.Font.SourceSans
                    errorLabel.TextSize = 14
                    errorLabel.Parent = deleteResultsContent
                    
                    yOffset += 30
                end
                
                -- Reset confirmation after delete operation
                isConfirmed = false
                confirmCheckbox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                confirmCheckbox.Text = ""
            end
        end)
    end)
    
    -- Create the batch operations section in the write tab content
    local batchOperationsFrame = Instance.new("Frame")
    batchOperationsFrame.Name = "BatchOperationsFrame"
    batchOperationsFrame.Size = UDim2.new(1, -20, 0, 200)
    batchOperationsFrame.Position = UDim2.new(0, 10, 0, 360) -- Position below other write options
    batchOperationsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    batchOperationsFrame.Parent = writeContent
    
    local batchOpTitle = Instance.new("TextLabel")
    batchOpTitle.Name = "BatchOpTitle"
    batchOpTitle.Size = UDim2.new(1, -20, 0, 30)
    batchOpTitle.Position = UDim2.new(0, 10, 0, 5)
    batchOpTitle.BackgroundTransparency = 1
    batchOpTitle.Text = "Batch Operations"
    batchOpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    batchOpTitle.TextSize = 16
    batchOpTitle.Font = Enum.Font.SourceSansBold
    batchOpTitle.TextXAlignment = Enum.TextXAlignment.Left
    batchOpTitle.Parent = batchOperationsFrame
    
    -- Key Pattern Input for Batch Operations
    local keyPatternLabel = Instance.new("TextLabel")
    keyPatternLabel.Name = "KeyPatternLabel"
    keyPatternLabel.Size = UDim2.new(0.3, -20, 0, 30)
    keyPatternLabel.Position = UDim2.new(0, 10, 0, 40)
    keyPatternLabel.BackgroundTransparency = 1
    keyPatternLabel.Text = "Key Pattern:"
    keyPatternLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyPatternLabel.TextSize = 14
    keyPatternLabel.Font = Enum.Font.SourceSans
    keyPatternLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyPatternLabel.Parent = batchOperationsFrame
    
    local keyPatternInput = Instance.new("TextBox")
    keyPatternInput.Name = "KeyPatternInput"
    keyPatternInput.Size = UDim2.new(0.7, -20, 0, 30)
    keyPatternInput.Position = UDim2.new(0.3, 10, 0, 40)
    keyPatternInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    keyPatternInput.Text = ".*" -- Default to match all keys
    keyPatternInput.PlaceholderText = "Regular expression pattern (e.g. Player_.* or .*)"
    keyPatternInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyPatternInput.TextSize = 14
    keyPatternInput.Font = Enum.Font.SourceSans
    keyPatternInput.ClearTextOnFocus = false
    keyPatternInput.Parent = batchOperationsFrame
    
    -- Create buttons for different batch operations
    local batchEditButton = Instance.new("TextButton")
    batchEditButton.Name = "BatchEditButton"
    batchEditButton.Size = UDim2.new(0.3, -15, 0, 30)
    batchEditButton.Position = UDim2.new(0, 10, 0, 80)
    batchEditButton.BackgroundColor3 = Color3.fromRGB(66, 134, 244)
    batchEditButton.Text = "Batch Edit"
    batchEditButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    batchEditButton.TextSize = 14
    batchEditButton.Font = Enum.Font.SourceSansBold
    batchEditButton.Parent = batchOperationsFrame
    
    local batchExportButton = Instance.new("TextButton")
    batchExportButton.Name = "BatchExportButton"
    batchExportButton.Size = UDim2.new(0.3, -15, 0, 30)
    batchExportButton.Position = UDim2.new(0.35, 0, 0, 80)
    batchExportButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    batchExportButton.Text = "Batch Export"
    batchExportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    batchExportButton.TextSize = 14
    batchExportButton.Font = Enum.Font.SourceSansBold
    batchExportButton.Parent = batchOperationsFrame
    
    local batchImportButton = Instance.new("TextButton")
    batchImportButton.Name = "BatchImportButton"
    batchImportButton.Size = UDim2.new(0.3, -15, 0, 30)
    batchImportButton.Position = UDim2.new(0.7, 0, 0, 80)
    batchImportButton.BackgroundColor3 = Color3.fromRGB(240, 156, 0)
    batchImportButton.Text = "Batch Import"
    batchImportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    batchImportButton.TextSize = 14
    batchImportButton.Font = Enum.Font.SourceSansBold
    batchImportButton.Parent = batchOperationsFrame
    
    local batchDeleteButton = Instance.new("TextButton")
    batchDeleteButton.Name = "BatchDeleteButton"
    batchDeleteButton.Size = UDim2.new(0.3, -15, 0, 30)
    batchDeleteButton.Position = UDim2.new(0.35, 0, 0, 120)
    batchDeleteButton.BackgroundColor3 = Color3.fromRGB(239, 83, 80)
    batchDeleteButton.Text = "Batch Delete"
    batchDeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    batchDeleteButton.TextSize = 14
    batchDeleteButton.Font = Enum.Font.SourceSansBold
    batchDeleteButton.Parent = batchOperationsFrame
    
    local batchValidateButton = Instance.new("TextButton")
    batchValidateButton.Name = "BatchValidateButton"
    batchValidateButton.Size = UDim2.new(0.3, -15, 0, 30)
    batchValidateButton.Position = UDim2.new(0.7, 0, 0, 120)
    batchValidateButton.BackgroundColor3 = Color3.fromRGB(156, 39, 176)
    batchValidateButton.Text = "Batch Validate"
    batchValidateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    batchValidateButton.TextSize = 14
    batchValidateButton.Font = Enum.Font.SourceSansBold
    batchValidateButton.Parent = batchOperationsFrame
    
    -- Status and Limit section
    local limitLabel = Instance.new("TextLabel")
    limitLabel.Name = "LimitLabel"
    limitLabel.Size = UDim2.new(0.3, -20, 0, 30)
    limitLabel.Position = UDim2.new(0, 10, 0, 160)
    limitLabel.BackgroundTransparency = 1
    limitLabel.Text = "Key Limit:"
    limitLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    limitLabel.TextSize = 14
    limitLabel.Font = Enum.Font.SourceSans
    limitLabel.TextXAlignment = Enum.TextXAlignment.Left
    limitLabel.Parent = batchOperationsFrame
    
    local limitInput = Instance.new("TextBox")
    limitInput.Name = "LimitInput"
    limitInput.Size = UDim2.new(0.2, -10, 0, 30)
    limitInput.Position = UDim2.new(0.3, 10, 0, 160)
    limitInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    limitInput.Text = "100"
    limitInput.PlaceholderText = "Max keys"
    limitInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    limitInput.TextSize = 14
    limitInput.Font = Enum.Font.SourceSans
    limitInput.ClearTextOnFocus = false
    limitInput.Parent = batchOperationsFrame
    
    -- Add event handlers for batch operation buttons
    batchEditButton.MouseButton1Click:Connect(function()
        if selectedDataStore == "" then
            BulkOperationsUI.showMessage("Please select a DataStore first", Color3.fromRGB(255, 0, 0))
            return
        end
        
        -- Create a dialog to get the edit function
        BulkOperationsUI.showBatchEditDialog(selectedDataStore, keyPatternInput.Text, tonumber(limitInput.Text) or 100)
    end)
    
    batchExportButton.MouseButton1Click:Connect(function()
        if selectedDataStore == "" then
            BulkOperationsUI.showMessage("Please select a DataStore first", Color3.fromRGB(255, 0, 0))
            return
        end
        
        -- Start batch export operation
        local operationId = BulkOperationsManager.createOperation("BatchExport", {
            dataStoreName = selectedDataStore,
            keyPattern = keyPatternInput.Text,
            limit = tonumber(limitInput.Text) or 100
        })
        
        BulkOperationsManager.startOperation(operationId)
        BulkOperationsUI.showOperationProgress(operationId)
    end)
    
    batchImportButton.MouseButton1Click:Connect(function()
        if selectedDataStore == "" then
            BulkOperationsUI.showMessage("Please select a DataStore first", Color3.fromRGB(255, 0, 0))
            return
        end
        
        -- Create a dialog to get the import data
        BulkOperationsUI.showBatchImportDialog(selectedDataStore)
    end)
    
    batchDeleteButton.MouseButton1Click:Connect(function()
        if selectedDataStore == "" then
            BulkOperationsUI.showMessage("Please select a DataStore first", Color3.fromRGB(255, 0, 0))
            return
        end
        
        -- Confirm deletion
        BulkOperationsUI.showConfirmDialog(
            "Confirm Batch Delete",
            "Are you sure you want to delete all keys matching the pattern '" .. keyPatternInput.Text .. 
            "' in DataStore '" .. selectedDataStore .. "'? This action cannot be undone.",
            function()
                local operationId = BulkOperationsManager.createOperation("BatchDelete", {
                    dataStoreName = selectedDataStore,
                    keyPattern = keyPatternInput.Text,
                    limit = tonumber(limitInput.Text) or 100
                })
                
                BulkOperationsManager.startOperation(operationId)
                BulkOperationsUI.showOperationProgress(operationId)
            end
        )
    end)
    
    batchValidateButton.MouseButton1Click:Connect(function()
        if selectedDataStore == "" then
            BulkOperationsUI.showMessage("Please select a DataStore first", Color3.fromRGB(255, 0, 0))
            return
        end
        
        -- Start batch validation operation
        local operationId = BulkOperationsManager.createOperation("BatchValidate", {
            dataStoreName = selectedDataStore,
            keyPattern = keyPatternInput.Text,
            limit = tonumber(limitInput.Text) or 100
        })
        
        BulkOperationsManager.startOperation(operationId)
        BulkOperationsUI.showOperationProgress(operationId)
    end)
    
    -- Update active operations count periodically
    RunService.Heartbeat:Connect(function()
        local activeOps = BulkOperationsManager.getActiveOperations()
        operationsLabel.Text = "Active Operations: " .. #activeOps
    end)
    
    return container
end

-- Show an operation progress dialog
function BulkOperationsUI.showOperationProgress(operationId)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "ProgressDialog"
    mainFrame.Size = UDim2.new(0.8, 0, 0.7, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 10
    mainFrame.Parent = script.Parent.Parent
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = mainFrame
    
    -- Add a title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Operation Progress"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 11
    title.Parent = mainFrame
    
    -- Add a close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.ZIndex = 11
    closeButton.Parent = mainFrame
    
    -- Add rounded corners to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Add progress bar
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, -40, 0, 24)
    progressBar.Position = UDim2.new(0, 20, 0, 60)
    progressBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 11
    progressBar.Parent = mainFrame
    
    -- Add rounded corners to progress bar
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressBar
    
    -- Add progress fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(66, 134, 244)
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 11
    progressFill.Parent = progressBar
    
    -- Add rounded corners to progress fill
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = progressFill
    
    -- Add progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = "0%"
    progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressText.TextSize = 14
    progressText.Font = Enum.Font.SourceSansBold
    progressText.ZIndex = 12
    progressText.Parent = progressBar
    
    -- Add status text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -40, 0, 24)
    statusText.Position = UDim2.new(0, 20, 0, 90)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Starting operation..."
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.TextSize = 14
    statusText.Font = Enum.Font.SourceSans
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.ZIndex = 11
    statusText.Parent = mainFrame
    
    -- Add results container
    local resultsFrame = Instance.new("ScrollingFrame")
    resultsFrame.Name = "ResultsFrame"
    resultsFrame.Size = UDim2.new(1, -40, 1, -130)
    resultsFrame.Position = UDim2.new(0, 20, 0, 120)
    resultsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    resultsFrame.BorderSizePixel = 0
    resultsFrame.ScrollBarThickness = 6
    resultsFrame.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    resultsFrame.ZIndex = 11
    resultsFrame.Parent = mainFrame
    
    -- Add layout for results
    local resultsLayout = Instance.new("UIListLayout")
    resultsLayout.FillDirection = Enum.FillDirection.Vertical
    resultsLayout.Padding = UDim.new(0, 2)
    resultsLayout.Parent = resultsFrame
    
    -- Close button handler
    closeButton.MouseButton1Click:Connect(function()
        mainFrame:Destroy()
    end)
    
    -- Cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(0, 100, 0, 30)
    cancelButton.Position = UDim2.new(1, -120, 0, 60)
    cancelButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    cancelButton.Text = "Cancel"
    cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelButton.TextSize = 14
    cancelButton.Font = Enum.Font.SourceSansBold
    cancelButton.ZIndex = 11
    cancelButton.Parent = mainFrame
    
    -- Add rounded corners to cancel button
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 4)
    cancelCorner.Parent = cancelButton
    
    -- Cancel button handler
    cancelButton.MouseButton1Click:Connect(function()
        BulkOperationsManager.cancelOperation(operationId)
        statusText.Text = "Operation cancelled."
        statusText.TextColor3 = Color3.fromRGB(200, 60, 60)
        cancelButton.Visible = false
    end)
    
    -- Update progress at regular intervals
    local updateConnection
    updateConnection = RunService.Heartbeat:Connect(function()
        local status = BulkOperationsManager.getOperationStatus(operationId)
        
        if status then
            -- Update progress bar
            progressFill.Size = UDim2.new(status.progress.current / math.max(status.progress.total, 1), 0, 1, 0)
            progressText.Text = string.format("%.1f%%", (status.progress.current / math.max(status.progress.total, 1)) * 100)
            
            -- Update status text
            statusText.Text = string.format(
                "Status: %s | Processed: %d/%d | Successful: %d | Failed: %d",
                status.status,
                status.progress.current,
                status.progress.total,
                #status.progress.processedKeys - #status.progress.failedKeys,
                #status.progress.failedKeys
            )
            
            -- If operation is complete, show the results and disconnect the update
            if status.status == "Completed" or status.status == "Failed" or status.status == "Cancelled" then
                if status.status == "Completed" then
                    statusText.Text = "Operation completed successfully."
                    statusText.TextColor3 = Color3.fromRGB(76, 175, 80)
                elseif status.status == "Failed" then
                    statusText.Text = "Operation failed: " .. (status.errors.message or "Unknown error")
                    statusText.TextColor3 = Color3.fromRGB(200, 60, 60)
                end
                
                cancelButton.Visible = false
                
                -- Show operation results
                if status.status == "Completed" then
                    local results = BulkOperationsManager.getOperationResults(operationId)
                    
                    -- Create a title for results
                    local resultsTitle = Instance.new("TextLabel")
                    resultsTitle.Name = "ResultsTitle"
                    resultsTitle.Size = UDim2.new(1, -10, 0, 30)
                    resultsTitle.BackgroundTransparency = 1
                    resultsTitle.Text = "Operation Results:"
                    resultsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                    resultsTitle.TextSize = 16
                    resultsTitle.Font = Enum.Font.SourceSansBold
                    resultsTitle.TextXAlignment = Enum.TextXAlignment.Left
                    resultsTitle.Parent = resultsFrame
                    
                    -- Create a summary
                    local resultsSummary = Instance.new("TextLabel")
                    resultsSummary.Name = "ResultsSummary"
                    resultsSummary.Size = UDim2.new(1, -10, 0, 50)
                    resultsSummary.BackgroundTransparency = 1
                    resultsSummary.Text = string.format(
                        "Processed: %d keys\nSuccessful: %d keys\nFailed: %d keys\nDuration: %.1f seconds",
                        results.processed,
                        results.successful,
                        results.failed,
                        results.duration
                    )
                    resultsSummary.TextColor3 = Color3.fromRGB(200, 200, 200)
                    resultsSummary.TextSize = 14
                    resultsSummary.Font = Enum.Font.SourceSans
                    resultsSummary.TextXAlignment = Enum.TextXAlignment.Left
                    resultsSummary.TextYAlignment = Enum.TextYAlignment.Top
                    resultsSummary.Parent = resultsFrame
                    
                    -- For export operations, show a copy button
                    if status.type == "BatchExport" and results.exportedData then
                        local copyDataButton = Instance.new("TextButton")
                        copyDataButton.Name = "CopyDataButton"
                        copyDataButton.Size = UDim2.new(0, 200, 0, 30)
                        copyDataButton.Position = UDim2.new(0, 0, 0, 80)
                        copyDataButton.BackgroundColor3 = Color3.fromRGB(66, 134, 244)
                        copyDataButton.Text = "Copy Data to Clipboard"
                        copyDataButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                        copyDataButton.TextSize = 14
                        copyDataButton.Font = Enum.Font.SourceSansBold
                        copyDataButton.Parent = resultsFrame
                        
                        -- Add rounded corners
                        local copyCorner = Instance.new("UICorner")
                        copyCorner.CornerRadius = UDim.new(0, 4)
                        copyCorner.Parent = copyDataButton
                        
                        -- Click handler
                        copyDataButton.MouseButton1Click:Connect(function()
                            local json = HttpService:JSONEncode(results.exportedData)
                            setclipboard(json)
                            copyDataButton.Text = "Copied!"
                            task.wait(2)
                            copyDataButton.Text = "Copy Data to Clipboard"
                        end)
                    end
                end
                
                updateConnection:Disconnect()
            end
        else
            statusText.Text = "Error: Could not retrieve operation status"
            statusText.TextColor3 = Color3.fromRGB(200, 60, 60)
            updateConnection:Disconnect()
        end
    end)
end

-- Show a batch edit dialog
function BulkOperationsUI.showBatchEditDialog(dataStoreName, keyPattern, limit)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "BatchEditDialog"
    mainFrame.Size = UDim2.new(0.8, 0, 0.7, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 10
    mainFrame.Parent = script.Parent.Parent
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = mainFrame
    
    -- Add a title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Batch Edit - " .. dataStoreName
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 11
    title.Parent = mainFrame
    
    -- Add a close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.ZIndex = 11
    closeButton.Parent = mainFrame
    
    -- Add rounded corners to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Add description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -40, 0, 60)
    description.Position = UDim2.new(0, 20, 0, 50)
    description.BackgroundTransparency = 1
    description.Text = "Enter a Lua function that will be applied to each key. The function should take two parameters:\n1. data - The current data of the key\n2. keyName - The name of the key\nThe function should return the modified data."
    description.TextColor3 = Color3.fromRGB(200, 200, 200)
    description.TextSize = 14
    description.Font = Enum.Font.SourceSans
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextYAlignment = Enum.TextYAlignment.Top
    description.TextWrapped = true
    description.ZIndex = 11
    description.Parent = mainFrame
    
    -- Add function editor
    local functionEditor = Instance.new("TextBox")
    functionEditor.Name = "FunctionEditor"
    functionEditor.Size = UDim2.new(1, -40, 0, 200)
    functionEditor.Position = UDim2.new(0, 20, 0, 120)
    functionEditor.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    functionEditor.BorderSizePixel = 0
    functionEditor.Text = "function(data, keyName)\n    -- Modify data here\n    -- Example: data.value = data.value + 1\n    return data\nend"
    functionEditor.TextColor3 = Color3.fromRGB(255, 255, 255)
    functionEditor.TextSize = 14
    functionEditor.Font = Enum.Font.Code
    functionEditor.TextXAlignment = Enum.TextXAlignment.Left
    functionEditor.TextYAlignment = Enum.TextYAlignment.Top
    functionEditor.ClearTextOnFocus = false
    functionEditor.MultiLine = true
    functionEditor.ZIndex = 11
    functionEditor.Parent = mainFrame
    
    -- Add rounded corners to editor
    local editorCorner = Instance.new("UICorner")
    editorCorner.CornerRadius = UDim.new(0, 4)
    editorCorner.Parent = functionEditor
    
    -- Add start button
    local startButton = Instance.new("TextButton")
    startButton.Name = "StartButton"
    startButton.Size = UDim2.new(0, 150, 0, 40)
    startButton.Position = UDim2.new(0.5, -75, 0, 340)
    startButton.BackgroundColor3 = Color3.fromRGB(66, 134, 244)
    startButton.Text = "Start Batch Edit"
    startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    startButton.TextSize = 16
    startButton.Font = Enum.Font.SourceSansBold
    startButton.ZIndex = 11
    startButton.Parent = mainFrame
    
    -- Add rounded corners to start button
    local startCorner = Instance.new("UICorner")
    startCorner.CornerRadius = UDim.new(0, 4)
    startCorner.Parent = startButton
    
    -- Close button handler
    closeButton.MouseButton1Click:Connect(function()
        mainFrame:Destroy()
    end)
    
    -- Start button handler
    startButton.MouseButton1Click:Connect(function()
        -- Parse the function
        local editFunction, errorMessage = loadstring("return " .. functionEditor.Text)
        
        if not editFunction then
            BulkOperationsUI.showMessage("Error in function: " .. (errorMessage or "Unknown error"), Color3.fromRGB(255, 0, 0))
            return
        end
        
        local actualFunction = editFunction()
        if type(actualFunction) ~= "function" then
            BulkOperationsUI.showMessage("Error: Not a valid function", Color3.fromRGB(255, 0, 0))
            return
        end
        
        -- Create the batch edit operation
        local operationId = BulkOperationsManager.createOperation("BatchEdit", {
            dataStoreName = dataStoreName,
            keyPattern = keyPattern,
            editFunction = actualFunction,
            limit = limit
        })
        
        BulkOperationsManager.startOperation(operationId)
        mainFrame:Destroy()
        BulkOperationsUI.showOperationProgress(operationId)
    end)
end

-- Show a batch import dialog
function BulkOperationsUI.showBatchImportDialog(dataStoreName)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "BatchImportDialog"
    mainFrame.Size = UDim2.new(0.8, 0, 0.7, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 10
    mainFrame.Parent = script.Parent.Parent
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = mainFrame
    
    -- Add a title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Batch Import - " .. dataStoreName
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 11
    title.Parent = mainFrame
    
    -- Add a close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.ZIndex = 11
    closeButton.Parent = mainFrame
    
    -- Add rounded corners to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Add description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -40, 0, 60)
    description.Position = UDim2.new(0, 20, 0, 50)
    description.BackgroundTransparency = 1
    description.Text = "Paste JSON data to import. The JSON should be an object where keys are the DataStore keys and values are the data to import."
    description.TextColor3 = Color3.fromRGB(200, 200, 200)
    description.TextSize = 14
    description.Font = Enum.Font.SourceSans
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextYAlignment = Enum.TextYAlignment.Top
    description.TextWrapped = true
    description.ZIndex = 11
    description.Parent = mainFrame
    
    -- Add JSON editor
    local jsonEditor = Instance.new("TextBox")
    jsonEditor.Name = "JSONEditor"
    jsonEditor.Size = UDim2.new(1, -40, 0, 200)
    jsonEditor.Position = UDim2.new(0, 20, 0, 120)
    jsonEditor.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    jsonEditor.BorderSizePixel = 0
    jsonEditor.Text = '{\n    "key1": {"property1": "value1"},\n    "key2": {"property1": "value2"}\n}'
    jsonEditor.TextColor3 = Color3.fromRGB(255, 255, 255)
    jsonEditor.TextSize = 14
    jsonEditor.Font = Enum.Font.Code
    jsonEditor.TextXAlignment = Enum.TextXAlignment.Left
    jsonEditor.TextYAlignment = Enum.TextYAlignment.Top
    jsonEditor.ClearTextOnFocus = false
    jsonEditor.MultiLine = true
    jsonEditor.ZIndex = 11
    jsonEditor.Parent = mainFrame
    
    -- Add rounded corners to editor
    local editorCorner = Instance.new("UICorner")
    editorCorner.CornerRadius = UDim.new(0, 4)
    editorCorner.Parent = jsonEditor
    
    -- Add options
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name = "OptionsFrame"
    optionsFrame.Size = UDim2.new(1, -40, 0, 30)
    optionsFrame.Position = UDim2.new(0, 20, 0, 330)
    optionsFrame.BackgroundTransparency = 1
    optionsFrame.ZIndex = 11
    optionsFrame.Parent = mainFrame
    
    -- Add overwrite option
    local overwriteCheckbox = Instance.new("Frame")
    overwriteCheckbox.Name = "OverwriteCheckbox"
    overwriteCheckbox.Size = UDim2.new(0, 20, 0, 20)
    overwriteCheckbox.Position = UDim2.new(0, 0, 0, 5)
    overwriteCheckbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    overwriteCheckbox.BorderSizePixel = 0
    overwriteCheckbox.ZIndex = 12
    overwriteCheckbox.Parent = optionsFrame
    
    -- Add rounded corners to checkbox
    local checkboxCorner = Instance.new("UICorner")
    checkboxCorner.CornerRadius = UDim.new(0, 4)
    checkboxCorner.Parent = overwriteCheckbox
    
    -- Add checkmark
    local checkmark = Instance.new("TextLabel")
    checkmark.Name = "Checkmark"
    checkmark.Size = UDim2.new(1, 0, 1, 0)
    checkmark.BackgroundTransparency = 1
    checkmark.Text = "✓"
    checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
    checkmark.TextSize = 14
    checkmark.Font = Enum.Font.SourceSansBold
    checkmark.ZIndex = 13
    checkmark.Parent = overwriteCheckbox
    
    -- Add checkbox label
    local checkboxLabel = Instance.new("TextLabel")
    checkboxLabel.Name = "CheckboxLabel"
    checkboxLabel.Size = UDim2.new(0, 200, 0, 30)
    checkboxLabel.Position = UDim2.new(0, 30, 0, 0)
    checkboxLabel.BackgroundTransparency = 1
    checkboxLabel.Text = "Overwrite existing keys"
    checkboxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    checkboxLabel.TextSize = 14
    checkboxLabel.Font = Enum.Font.SourceSans
    checkboxLabel.TextXAlignment = Enum.TextXAlignment.Left
    checkboxLabel.ZIndex = 12
    checkboxLabel.Parent = optionsFrame
    
    -- Make the checkbox clickable
    local overwriteEnabled = true
    checkmark.Visible = overwriteEnabled
    
    local function toggleOverwrite()
        overwriteEnabled = not overwriteEnabled
        checkmark.Visible = overwriteEnabled
    end
    
    overwriteCheckbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleOverwrite()
        end
    end)
    
    checkboxLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleOverwrite()
        end
    end)
    
    -- Add start button
    local startButton = Instance.new("TextButton")
    startButton.Name = "StartButton"
    startButton.Size = UDim2.new(0, 150, 0, 40)
    startButton.Position = UDim2.new(0.5, -75, 0, 380)
    startButton.BackgroundColor3 = Color3.fromRGB(240, 156, 0)
    startButton.Text = "Start Import"
    startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    startButton.TextSize = 16
    startButton.Font = Enum.Font.SourceSansBold
    startButton.ZIndex = 11
    startButton.Parent = mainFrame
    
    -- Add rounded corners to start button
    local startCorner = Instance.new("UICorner")
    startCorner.CornerRadius = UDim.new(0, 4)
    startCorner.Parent = startButton
    
    -- Close button handler
    closeButton.MouseButton1Click:Connect(function()
        mainFrame:Destroy()
    end)
    
    -- Start button handler
    startButton.MouseButton1Click:Connect(function()
        -- Parse the JSON
        local success, importData = pcall(function()
            return HttpService:JSONDecode(jsonEditor.Text)
        end)
        
        if not success or type(importData) ~= "table" then
            BulkOperationsUI.showMessage("Error parsing JSON: " .. (importData or "Invalid format"), Color3.fromRGB(255, 0, 0))
            return
        end
        
        -- Create the batch import operation
        local operationId = BulkOperationsManager.createOperation("BatchImport", {
            dataStoreName = dataStoreName,
            importData = importData,
            overwriteExisting = overwriteEnabled
        })
        
        BulkOperationsManager.startOperation(operationId)
        mainFrame:Destroy()
        BulkOperationsUI.showOperationProgress(operationId)
    end)
end

-- Show a confirmation dialog
function BulkOperationsUI.showConfirmDialog(title, message, confirmCallback)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "ConfirmDialog"
    mainFrame.Size = UDim2.new(0.5, 0, 0.3, 0)
    mainFrame.Position = UDim2.new(0.25, 0, 0.35, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 20
    mainFrame.Parent = script.Parent.Parent
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = mainFrame
    
    -- Add a title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 21
    titleLabel.Parent = mainFrame
    
    -- Add message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -40, 0, 80)
    messageLabel.Position = UDim2.new(0, 20, 0, 50)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.ZIndex = 21
    messageLabel.Parent = mainFrame
    
    -- Add confirm button
    local confirmButton = Instance.new("TextButton")
    confirmButton.Name = "ConfirmButton"
    confirmButton.Size = UDim2.new(0, 120, 0, 40)
    confirmButton.Position = UDim2.new(0.3, -60, 0.8, -20)
    confirmButton.BackgroundColor3 = Color3.fromRGB(239, 83, 80)
    confirmButton.Text = "Confirm"
    confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmButton.TextSize = 16
    confirmButton.Font = Enum.Font.SourceSansBold
    confirmButton.ZIndex = 21
    confirmButton.Parent = mainFrame
    
    -- Add rounded corners to confirm button
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 4)
    confirmCorner.Parent = confirmButton
    
    -- Add cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(0, 120, 0, 40)
    cancelButton.Position = UDim2.new(0.7, -60, 0.8, -20)
    cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    cancelButton.Text = "Cancel"
    cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelButton.TextSize = 16
    cancelButton.Font = Enum.Font.SourceSansBold
    cancelButton.ZIndex = 21
    cancelButton.Parent = mainFrame
    
    -- Add rounded corners to cancel button
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 4)
    cancelCorner.Parent = cancelButton
    
    -- Button handlers
    confirmButton.MouseButton1Click:Connect(function()
        mainFrame:Destroy()
        confirmCallback()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        mainFrame:Destroy()
    end)
end
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.ZIndex = 21
    messageLabel.Parent = mainFrame
    
    -- Add confirm button
    local confirmButton = Instance.new("TextButton")
    confirmButton.Name = "ConfirmButton"
    confirmButton.Size = UDim2.new(0, 120, 0, 40)
    confirmButton.Position = UDim2.new(0.3, -60, 0.8, -20)
    confirmButton.BackgroundColor3 = Color3.fromRGB(239, 83, 80)
    confirmButton.Text = "Confirm"
    confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmButton.TextSize = 16
    confirmButton.Font = Enum.Font.SourceSansBold
    confirmButton.ZIndex = 21
    confirmButton.Parent = mainFrame
    
    -- Add rounded corners to confirm button
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 4)
    confirmCorner.Parent = confirmButton
    
    -- Add cancel button
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Size = UDim2.new(0, 120, 0, 40)
    cancelButton.Position = UDim2.new(0.7, -60, 0.8, -20)
    cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    cancelButton.Text = "Cancel"
    cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelButton.TextSize = 16
    cancelButton.Font = Enum.Font.SourceSansBold
    cancelButton.ZIndex = 21
    cancelButton.Parent = mainFrame
    
    -- Add rounded corners to cancel button
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 4)
    cancelCorner.Parent = cancelButton
    
    -- Button handlers
    confirmButton.MouseButton1Click:Connect(function()
        mainFrame:Destroy()
        confirmCallback()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        mainFrame:Destroy()
    end)

return BulkOperationsUI
