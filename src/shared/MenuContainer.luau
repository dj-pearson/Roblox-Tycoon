--[[
    MenuContainer.luau
    
    A module for creating consistent menu containers following the UI_Module_Design document.
    Provides standard containers, tabbed containers, scrolling containers, and more.
    
    Author: Updated April 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn("Failed to require module: ", module:GetFullName())
        return nil
    end
    
    return result
end

-- Find shared modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
local UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))
local ButtonFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("ButtonFactory"))

-- Create fallbacks if modules not found
if not UIStyle then
    warn("UIStyle module not found, using fallback styles")
    UIStyle = {
        Colors = {
            Background = Color3.fromRGB(40, 40, 60),
            BackgroundLight = Color3.fromRGB(60, 60, 80),
            BackgroundDark = Color3.fromRGB(30, 30, 45),
            HeaderBackground = Color3.fromRGB(35, 35, 55),
            ButtonDefault = Color3.fromRGB(60, 60, 80),
            ButtonHover = Color3.fromRGB(70, 70, 90),
            ButtonPressed = Color3.fromRGB(50, 50, 70),
            ButtonSelected = Color3.fromRGB(80, 100, 150),
            Text = Color3.fromRGB(240, 240, 255),
            TextSecondary = Color3.fromRGB(180, 180, 200),
            TextDisabled = Color3.fromRGB(120, 120, 140),
            Border = Color3.fromRGB(80, 80, 100),
            TableHeader = Color3.fromRGB(50, 50, 70),
            TableRowEven = Color3.fromRGB(45, 45, 65),
            TableRowOdd = Color3.fromRGB(40, 40, 60)
        },
        Fonts = {
            Bold = Enum.Font.GothamBold,
            Regular = Enum.Font.Gotham,
            SemiBold = Enum.Font.GothamSemibold
        },
        TextSizes = {
            Small = 14,
            Medium = 16,
            Large = 20,
            Title = 24
        },
        ZIndex = {
            Background = 1,
            Content = 2,
            Foreground = 3
        },
        Animations = {
            Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        }
    }
end

-- Container Factory Module
local MenuContainer = {}

--[[
    Create a standard container for general-purpose UI elements
    @param name: string - Name of the container
    @param size: UDim2 - Size of the container
    @param position: UDim2 - Position of the container
    @param parent: Instance - Parent Instance for the container
    @return: table - Container components
]]
function MenuContainer.createStandardContainer(name, size, position, parent)
    name = name or "StandardContainer"
    size = size or UDim2.new(0, 400, 0, 300)
    position = position or UDim2.new(0.5, 0, 0.5, 0)
    
    -- Create main frame
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = size
    container.Position = position
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundColor3 = UIStyle.Colors.Background
    container.BorderSizePixel = 0
    container.ZIndex = UIStyle.ZIndex.Background
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container
    
    -- Add stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = UIStyle.Colors.Border
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = container
    
    -- Create content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -20)
    contentArea.Position = UDim2.new(0, 10, 0, 10)
    contentArea.BackgroundTransparency = 1
    contentArea.ZIndex = UIStyle.ZIndex.Content
    contentArea.Parent = container
    
    if parent then
        container.Parent = parent
    end
    
    -- Return the container components
    return {
        container = container,
        contentArea = contentArea
    }
end

--[[
    Create a container with a header
    @param name: string - Name of the container
    @param title: string - Title text for the header
    @param size: UDim2 - Size of the container
    @param position: UDim2 - Position of the container
    @param parent: Instance - Parent Instance for the container
    @param showCloseButton: boolean - Whether to show a close button
    @param closeCallback: function - Callback when close button is clicked
    @return: table - Container components
]]
function MenuContainer.createHeaderContainer(name, title, size, position, parent, showCloseButton, closeCallback)
    name = name or "HeaderContainer"
    title = title or "Container"
    size = size or UDim2.new(0, 400, 0, 300)
    position = position or UDim2.new(0.5, 0, 0.5, 0)
    showCloseButton = (showCloseButton ~= nil) and showCloseButton or true
    
    -- Create main frame
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = size
    container.Position = position
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundColor3 = UIStyle.Colors.Background
    container.BorderSizePixel = 0
    container.ZIndex = UIStyle.ZIndex.Background
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container
    
    -- Add header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = UIStyle.Colors.HeaderBackground
    header.BorderSizePixel = 0
    header.ZIndex = UIStyle.ZIndex.Content
    header.Parent = container
    
    -- Add header corner rounding (top only)
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    -- Add bottom frame to make corners only at top
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Name = "BottomFrame"
    bottomFrame.Size = UDim2.new(1, 0, 0, 10)
    bottomFrame.Position = UDim2.new(0, 0, 1, -10)
    bottomFrame.BackgroundColor3 = UIStyle.Colors.HeaderBackground
    bottomFrame.BorderSizePixel = 0
    bottomFrame.ZIndex = UIStyle.ZIndex.Content
    bottomFrame.Parent = header
    
    -- Add title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, showCloseButton and -50 or -20, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = UIStyle.Fonts.Bold
    titleText.Text = title
    titleText.TextColor3 = UIStyle.Colors.Text
    titleText.TextSize = UIStyle.TextSizes.Large
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = UIStyle.ZIndex.Content
    titleText.Parent = header
    
    -- Create close button if needed
    local closeButton
    if showCloseButton then
        if ButtonFactory then
            closeButton = ButtonFactory.createCloseButton(header, UDim2.new(1, -10, 0.5, 0))
        else
            closeButton = Instance.new("TextButton")
            closeButton.Name = "CloseButton"
            closeButton.Size = UDim2.new(0, 30, 0, 30)
            closeButton.Position = UDim2.new(1, -10, 0.5, 0)
            closeButton.AnchorPoint = Vector2.new(1, 0.5)
            closeButton.Font = UIStyle.Fonts.Bold
            closeButton.Text = "✕"
            closeButton.TextColor3 = UIStyle.Colors.Text
            closeButton.TextSize = UIStyle.TextSizes.Medium
            closeButton.BackgroundColor3 = UIStyle.Colors.ButtonDefault
            closeButton.ZIndex = UIStyle.ZIndex.Content
            closeButton.Parent = header
            
            local closeCorner = Instance.new("UICorner")
            closeCorner.CornerRadius = UDim.new(0, 4)
            closeCorner.Parent = closeButton
            
            -- Add hover effect
            closeButton.MouseEnter:Connect(function()
                TweenService:Create(closeButton, UIStyle.Animations.Fast, {
                    BackgroundColor3 = UIStyle.Colors.ButtonHover
                }):Play()
            end)
            
            closeButton.MouseLeave:Connect(function()
                TweenService:Create(closeButton, UIStyle.Animations.Fast, {
                    BackgroundColor3 = UIStyle.Colors.ButtonDefault
                }):Play()
            end)
        end
        
        -- Connect close button to callback
        closeButton.MouseButton1Click:Connect(function()
            if closeCallback and typeof(closeCallback) == "function" then
                closeCallback()
            end
        end)
    end
    
    -- Create content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -60)
    contentArea.Position = UDim2.new(0, 10, 0, 50)
    contentArea.BackgroundTransparency = 1
    contentArea.ZIndex = UIStyle.ZIndex.Content
    contentArea.Parent = container
    
    -- Add stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = UIStyle.Colors.Border
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = container
    
    if parent then
        container.Parent = parent
    end
    
    -- Return the container components
    return {
        container = container,
        header = header,
        titleText = titleText,
        closeButton = closeButton,
        contentArea = contentArea
    }
end

--[[
    Create a tabbed container with multiple tabs
    @param name: string - Name of the container
    @param tabs: table - List of tab data {name = "Tab Name", content = function(frame) end}
    @param size: UDim2 - Size of the container
    @param position: UDim2 - Position of the container
    @param parent: Instance - Parent Instance for the container
    @return: table - Container components and functions to manage tabs
]]
function MenuContainer.createTabbedContainer(name, tabs, size, position, parent)
    name = name or "TabbedContainer"
    size = size or UDim2.new(0, 500, 0, 350)
    position = position or UDim2.new(0.5, 0, 0.5, 0)
    tabs = tabs or {}
    
    -- Create main container
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = size
    container.Position = position
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundColor3 = UIStyle.Colors.Background
    container.BorderSizePixel = 0
    container.ZIndex = UIStyle.ZIndex.Background
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container
    
    -- Add stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = UIStyle.Colors.Border
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = container
    
    -- Create tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, -20, 0, 40)
    tabBar.Position = UDim2.new(0, 10, 0, 10)
    tabBar.BackgroundColor3 = UIStyle.Colors.HeaderBackground
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex = UIStyle.ZIndex.Content
    tabBar.Parent = container
    
    -- Add tab bar corner rounding
    local tabBarCorner = Instance.new("UICorner")
    tabBarCorner.CornerRadius = UDim.new(0, 6)
    tabBarCorner.Parent = tabBar
    
    -- Create tab content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -60)
    contentArea.Position = UDim2.new(0, 10, 0, 60)
    contentArea.BackgroundTransparency = 1
    contentArea.ZIndex = UIStyle.ZIndex.Content
    contentArea.Parent = container
    
    -- Add tab buttons layout
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar
    
    -- Add padding to tab bar
    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingRight = UDim.new(0, 10)
    tabPadding.Parent = tabBar
    
    -- Table to store all tab buttons and content frames
    local tabButtons = {}
    local tabContents = {}
    local currentTab = nil
    
    -- Function to select a tab
    local function selectTab(tabName)
        for name, button in pairs(tabButtons) do
            if name == tabName then
                TweenService:Create(button, UIStyle.Animations.Fast, {
                    BackgroundColor3 = UIStyle.Colors.ButtonSelected,
                    BackgroundTransparency = 0
                }):Play()
            else
                TweenService:Create(button, UIStyle.Animations.Fast, {
                    BackgroundColor3 = UIStyle.Colors.ButtonDefault,
                    BackgroundTransparency = 0.5
                }):Play()
            end
        end
        
        for name, contentFrame in pairs(tabContents) do
            if name == tabName then
                contentFrame.Visible = true
            else
                contentFrame.Visible = false
            end
        end
        
        currentTab = tabName
    end
    
    -- Create tabs from configuration
    for i, tabInfo in ipairs(tabs) do
        local tabName = tabInfo.name or "Tab " .. i
        
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = "Tab_" .. tabName
        tabButton.Size = UDim2.new(0, 120, 0, 30)
        tabButton.BackgroundColor3 = UIStyle.Colors.ButtonDefault
        tabButton.BackgroundTransparency = 0.5
        tabButton.Font = UIStyle.Fonts.SemiBold
        tabButton.Text = tabName
        tabButton.TextColor3 = UIStyle.Colors.Text
        tabButton.TextSize = UIStyle.TextSizes.Medium
        tabButton.LayoutOrder = i
        tabButton.ZIndex = UIStyle.ZIndex.Content
        tabButton.Parent = tabBar
        
        -- Add corner rounding to button
        local tabButtonCorner = Instance.new("UICorner")
        tabButtonCorner.CornerRadius = UDim.new(0, 4)
        tabButtonCorner.Parent = tabButton
        
        -- Create content frame for this tab
        local tabContent = Instance.new("Frame")
        tabContent.Name = "Content_" .. tabName
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.ZIndex = UIStyle.ZIndex.Content
        tabContent.Parent = contentArea
        
        -- Add content if provided
        if tabInfo.content and typeof(tabInfo.content) == "function" then
            tabInfo.content(tabContent)
        end
        
        -- Store tab components
        tabButtons[tabName] = tabButton
        tabContents[tabName] = tabContent
        
        -- Connect tab button
        tabButton.MouseButton1Click:Connect(function()
            selectTab(tabName)
        end)
        
        -- Add hover effect
        tabButton.MouseEnter:Connect(function()
            if currentTab ~= tabName then
                TweenService:Create(tabButton, UIStyle.Animations.Fast, {
                    BackgroundTransparency = 0.3
                }):Play()
            end
        end)
        
        tabButton.MouseLeave:Connect(function()
            if currentTab ~= tabName then
                TweenService:Create(tabButton, UIStyle.Animations.Fast, {
                    BackgroundTransparency = 0.5
                }):Play()
            end
        end)
        
        -- If this is the first tab, select it
        if i == 1 then
            selectTab(tabName)
        end
    end
    
    if parent then
        container.Parent = parent
    end
    
    -- Return the container and tab management functions
    return {
        container = container,
        tabBar = tabBar,
        contentArea = contentArea,
        selectTab = selectTab,
        getCurrentTab = function() return currentTab end,
        getTabContent = function(tabName) return tabContents[tabName] end,
        getTabButton = function(tabName) return tabButtons[tabName] end,
        getTabs = function() return tabButtons end,
        
        -- Function to add a new tab
        addTab = function(tabName, contentCallback)
            if tabButtons[tabName] then
                warn("Tab " .. tabName .. " already exists")
                return nil
            end
            
            local tabIndex = #tabBar:GetChildren() - 2 -- Adjust for layout and padding
            
            -- Create tab button
            local tabButton = Instance.new("TextButton")
            tabButton.Name = "Tab_" .. tabName
            tabButton.Size = UDim2.new(0, 120, 0, 30)
            tabButton.BackgroundColor3 = UIStyle.Colors.ButtonDefault
            tabButton.BackgroundTransparency = 0.5
            tabButton.Font = UIStyle.Fonts.SemiBold
            tabButton.Text = tabName
            tabButton.TextColor3 = UIStyle.Colors.Text
            tabButton.TextSize = UIStyle.TextSizes.Medium
            tabButton.LayoutOrder = tabIndex
            tabButton.ZIndex = UIStyle.ZIndex.Content
            tabButton.Parent = tabBar
            
            -- Add corner rounding to button
            local tabButtonCorner = Instance.new("UICorner")
            tabButtonCorner.CornerRadius = UDim.new(0, 4)
            tabButtonCorner.Parent = tabButton
            
            -- Create content frame for this tab
            local tabContent = Instance.new("Frame")
            tabContent.Name = "Content_" .. tabName
            tabContent.Size = UDim2.new(1, 0, 1, 0)
            tabContent.BackgroundTransparency = 1
            tabContent.Visible = false
            tabContent.ZIndex = UIStyle.ZIndex.Content
            tabContent.Parent = contentArea
            
            -- Add content if provided
            if contentCallback and typeof(contentCallback) == "function" then
                contentCallback(tabContent)
            end
            
            -- Store tab components
            tabButtons[tabName] = tabButton
            tabContents[tabName] = tabContent
            
            -- Connect tab button
            tabButton.MouseButton1Click:Connect(function()
                selectTab(tabName)
            end)
            
            -- Add hover effect
            tabButton.MouseEnter:Connect(function()
                if currentTab ~= tabName then
                    TweenService:Create(tabButton, UIStyle.Animations.Fast, {
                        BackgroundTransparency = 0.3
                    }):Play()
                end
            end)
            
            tabButton.MouseLeave:Connect(function()
                if currentTab ~= tabName then
                    TweenService:Create(tabButton, UIStyle.Animations.Fast, {
                        BackgroundTransparency = 0.5
                    }):Play()
                end
            end)
            
            return tabContent
        end,
        
        -- Function to remove a tab
        removeTab = function(tabName)
            if not tabButtons[tabName] then
                warn("Tab " .. tabName .. " doesn't exist")
                return false
            end
            
            -- Remove UI elements
            tabButtons[tabName]:Destroy()
            tabContents[tabName]:Destroy()
            
            -- Clean up tables
            tabButtons[tabName] = nil
            tabContents[tabName] = nil
            
            -- If the removed tab was selected, select the first available tab
            if currentTab == tabName then
                currentTab = nil
                for nextTabName, _ in pairs(tabButtons) do
                    selectTab(nextTabName)
                    break
                end
            end
            
            return true
        end
    }
end

--[[
    Create a scrolling container
    @param name: string - Name of the container
    @param size: UDim2 - Size of the container
    @param position: UDim2 - Position of the container
    @param parent: Instance - Parent Instance for the container
    @param scrollDirection: Enum.ScrollingDirection - Direction of scrolling
    @return: table - Container components
]]
function MenuContainer.createScrollingContainer(name, size, position, parent, scrollDirection)
    name = name or "ScrollingContainer"
    size = size or UDim2.new(0, 400, 0, 300)
    position = position or UDim2.new(0.5, 0, 0.5, 0)
    scrollDirection = scrollDirection or Enum.ScrollingDirection.Y
    
    -- Create main frame
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = size
    container.Position = position
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundColor3 = UIStyle.Colors.Background
    container.BorderSizePixel = 0
    container.ZIndex = UIStyle.ZIndex.Background
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container
    
    -- Create scrolling frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, -10, 1, -10)
    scrollFrame.Position = UDim2.new(0, 5, 0, 5)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = UIStyle.Colors.ButtonDefault
    scrollFrame.ScrollingDirection = scrollDirection
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    -- Set canvas size based on scrolling direction
    if scrollDirection == Enum.ScrollingDirection.X then
        scrollFrame.CanvasSize = UDim2.new(2, 0, 0, 0)
    elseif scrollDirection == Enum.ScrollingDirection.Y then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
    else -- Both
        scrollFrame.CanvasSize = UDim2.new(2, 0, 2, 0)
    end
    
    scrollFrame.ZIndex = UIStyle.ZIndex.Content
    scrollFrame.Parent = container
    
    -- Add layout for content
    local contentLayout
    local contentPadding
    
    if scrollDirection == Enum.ScrollingDirection.X then
        contentLayout = Instance.new("UIListLayout")
        contentLayout.FillDirection = Enum.FillDirection.Horizontal
        contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        contentLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        contentLayout.Padding = UDim.new(0, 10)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = scrollFrame
    else -- Y or Both
        contentLayout = Instance.new("UIListLayout")
        contentLayout.FillDirection = Enum.FillDirection.Vertical
        contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        contentLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        contentLayout.Padding = UDim.new(0, 10)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = scrollFrame
    end
    
    contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 5)
    contentPadding.PaddingBottom = UDim.new(0, 5)
    contentPadding.PaddingLeft = UDim.new(0, 5)
    contentPadding.PaddingRight = UDim.new(0, 5)
    contentPadding.Parent = scrollFrame
    
    -- Add stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = UIStyle.Colors.Border
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = container
    
    if parent then
        container.Parent = parent
    end
    
    -- Return the container components
    return {
        container = container,
        scrollFrame = scrollFrame,
        contentLayout = contentLayout,
        
        -- Helper to add items to the scroll frame
        addItem = function(item)
            if item and item:IsA("Instance") then
                item.Parent = scrollFrame
            end
        end,
        
        -- Helper to clear items
        clearItems = function()
            for _, child in pairs(scrollFrame:GetChildren()) do
                if child:IsA("GuiObject") and child ~= contentLayout and child ~= contentPadding then
                    child:Destroy()
                end
            end
        end,
        
        -- Helper to scroll to top
        scrollToTop = function()
            scrollFrame.CanvasPosition = Vector2.new(0, 0)
        end,
        
        -- Helper to scroll to bottom
        scrollToBottom = function()
            if scrollDirection == Enum.ScrollingDirection.Y or scrollDirection == Enum.ScrollingDirection.XY then
                scrollFrame.CanvasPosition = Vector2.new(scrollFrame.CanvasPosition.X, scrollFrame.CanvasSize.Y.Offset)
            end
        end
    }
end

--[[
    Create a container for displaying card-style items
    @param name: string - Name of the container
    @param size: UDim2 - Size of the container
    @param position: UDim2 - Position of the container
    @param parent: Instance - Parent Instance for the container
    @param gridSize: Vector2 - Number of columns and rows
    @return: table - Container components
]]
function MenuContainer.createCardContainer(name, size, position, parent, gridSize)
    name = name or "CardContainer"
    size = size or UDim2.new(0, 600, 0, 400)
    position = position or UDim2.new(0.5, 0, 0.5, 0)
    gridSize = gridSize or Vector2.new(3, 0) -- 0 rows means automatic
    
    -- Create main container
    local scrollContainer = MenuContainer.createScrollingContainer(
        name,
        size,
        position,
        parent,
        Enum.ScrollingDirection.Y
    )
    
    -- Remove default list layout
    scrollContainer.scrollFrame.UIListLayout:Destroy()
    
    -- Add grid layout
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 180, 0, 180)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.FillDirectionMaxCells = gridSize.X
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollContainer.scrollFrame
    
    -- Helper function to create a card
    local function createCard(title, content, imageId, clickCallback)
        local card = Instance.new("Frame")
        card.Name = "Card_" .. title
        card.Size = UDim2.new(1, 0, 1, 0)
        card.BackgroundColor3 = UIStyle.Colors.BackgroundLight
        card.ZIndex = UIStyle.ZIndex.Content
        
        -- Add corner rounding
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 6)
        cardCorner.Parent = card
        
        -- Add stroke
        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = UIStyle.Colors.Border
        cardStroke.Thickness = 1
        cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        cardStroke.Parent = card
        
        -- Add image if provided
        if imageId then
            local image = Instance.new("ImageLabel")
            image.Name = "CardImage"
            image.Size = UDim2.new(1, -20, 0, 100)
            image.Position = UDim2.new(0, 10, 0, 10)
            image.BackgroundColor3 = UIStyle.Colors.BackgroundDark
            image.Image = imageId
            image.ScaleType = Enum.ScaleType.Crop
            image.ZIndex = UIStyle.ZIndex.Content
            image.Parent = card
            
            -- Add corner rounding to image
            local imageCorner = Instance.new("UICorner")
            imageCorner.CornerRadius = UDim.new(0, 4)
            imageCorner.Parent = image
        end
        
        -- Add title
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "CardTitle"
        titleLabel.Size = UDim2.new(1, -20, 0, 30)
        titleLabel.Position = UDim2.new(0, 10, 0, imageId and 120 or 10)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = UIStyle.Fonts.Bold
        titleLabel.Text = title
        titleLabel.TextColor3 = UIStyle.Colors.Text
        titleLabel.TextSize = UIStyle.TextSizes.Medium
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        titleLabel.ZIndex = UIStyle.ZIndex.Content
        titleLabel.Parent = card
        
        -- Add content text
        if content then
            local contentLabel = Instance.new("TextLabel")
            contentLabel.Name = "CardContent"
            contentLabel.Size = UDim2.new(1, -20, 0, 50)
            contentLabel.Position = UDim2.new(0, 10, 0, imageId and 150 or 40)
            contentLabel.BackgroundTransparency = 1
            contentLabel.Font = UIStyle.Fonts.Regular
            contentLabel.Text = content
            contentLabel.TextColor3 = UIStyle.Colors.TextSecondary
            contentLabel.TextSize = UIStyle.TextSizes.Small
            contentLabel.TextWrapped = true
            contentLabel.TextXAlignment = Enum.TextXAlignment.Left
            contentLabel.TextYAlignment = Enum.TextYAlignment.Top
            contentLabel.ZIndex = UIStyle.ZIndex.Content
            contentLabel.Parent = card
        end
        
        -- Make card clickable if callback provided
        if clickCallback and typeof(clickCallback) == "function" then
            local button = Instance.new("TextButton")
            button.Name = "CardButton"
            button.Size = UDim2.new(1, 0, 1, 0)
            button.BackgroundTransparency = 1
            button.Text = ""
            button.ZIndex = UIStyle.ZIndex.Foreground
            button.Parent = card
            
            -- Add hover effect
            button.MouseEnter:Connect(function()
                TweenService:Create(card, UIStyle.Animations.Fast, {
                    BackgroundColor3 = UIStyle.Colors.ButtonHover
                }):Play()
            end)
            
            button.MouseLeave:Connect(function()
                TweenService:Create(card, UIStyle.Animations.Fast, {
                    BackgroundColor3 = UIStyle.Colors.BackgroundLight
                }):Play()
            end)
            
            button.MouseButton1Click:Connect(clickCallback)
        end
        
        return card
    end
    
    -- Extended API for card container
    local cardAPI = {
        container = scrollContainer.container,
        scrollFrame = scrollContainer.scrollFrame,
        gridLayout = gridLayout,
        
        -- Function to create and add a card
        addCard = function(title, content, imageId, clickCallback)
            local card = createCard(title, content, imageId, clickCallback)
            card.Parent = scrollContainer.scrollFrame
            return card
        end,
        
        -- Function to clear all cards
        clearCards = function()
            for _, child in pairs(scrollContainer.scrollFrame:GetChildren()) do
                if child:IsA("Frame") and child.Name:match("^Card_") then
                    child:Destroy()
                end
            end
        end,
        
        -- Function to get all cards
        getCards = function()
            local cards = {}
            for _, child in pairs(scrollContainer.scrollFrame:GetChildren()) do
                if child:IsA("Frame") and child.Name:match("^Card_") then
                    table.insert(cards, child)
                end
            end
            return cards
        end,
        
        -- Change grid configuration
        setGridSize = function(columns, cellSize)
            gridLayout.FillDirectionMaxCells = columns or 3
            if cellSize then
                gridLayout.CellSize = cellSize
            end
        end,
        
        -- Scroll to top
        scrollToTop = scrollContainer.scrollToTop,
        
        -- Scroll to bottom
        scrollToBottom = scrollContainer.scrollToBottom
    }
    
    return cardAPI
end

--[[
    Create a split container with two resizable panels
    @param name: string - Name of the container
    @param size: UDim2 - Size of the container
    @param position: UDim2 - Position of the container
    @param parent: Instance - Parent Instance for the container
    @param splitDirection: string - "horizontal" or "vertical" split
    @param splitRatio: number - Initial split ratio (0-1)
    @return: table - Container components
]]
function MenuContainer.createSplitContainer(name, size, position, parent, splitDirection, splitRatio)
    name = name or "SplitContainer"
    size = size or UDim2.new(0, 600, 0, 400)
    position = position or UDim2.new(0.5, 0, 0.5, 0)
    splitDirection = splitDirection or "vertical" -- vertical means left/right split
    splitRatio = splitRatio or 0.5 -- Default to 50/50 split
    
    -- Create main frame
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = size
    container.Position = position
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundColor3 = UIStyle.Colors.Background
    container.BorderSizePixel = 0
    container.ZIndex = UIStyle.ZIndex.Background
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container
    
    -- Add stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = UIStyle.Colors.Border
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = container
    
    -- Create first panel
    local panel1 = Instance.new("Frame")
    panel1.Name = "Panel1"
    panel1.BackgroundColor3 = UIStyle.Colors.Background
    panel1.BorderSizePixel = 0
    panel1.ZIndex = UIStyle.ZIndex.Content
    panel1.Parent = container
    
    -- Create second panel
    local panel2 = Instance.new("Frame")
    panel2.Name = "Panel2"
    panel2.BackgroundColor3 = UIStyle.Colors.Background
    panel2.BorderSizePixel = 0
    panel2.ZIndex = UIStyle.ZIndex.Content
    panel2.Parent = container
    
    -- Create divider
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.BackgroundColor3 = UIStyle.Colors.Border
    divider.BorderSizePixel = 0
    divider.ZIndex = UIStyle.ZIndex.Foreground
    divider.Parent = container
    
    -- Create drag handle (invisible, wider for easier grabbing)
    local dragHandle = Instance.new("TextButton")
    dragHandle.Name = "DragHandle"
    dragHandle.Text = ""
    dragHandle.BackgroundTransparency = 1
    dragHandle.ZIndex = UIStyle.ZIndex.Foreground + 1
    dragHandle.Parent = container
    
    -- Set sizes and positions based on split direction
    if splitDirection == "horizontal" then -- top/bottom split
        panel1.Size = UDim2.new(1, -20, splitRatio, -5)
        panel1.Position = UDim2.new(0, 10, 0, 10)
        
        divider.Size = UDim2.new(1, -20, 0, 4)
        divider.Position = UDim2.new(0, 10, splitRatio, 0)
        
        dragHandle.Size = UDim2.new(1, -20, 0, 10)
        dragHandle.Position = UDim2.new(0, 10, splitRatio, -3)
        
        panel2.Size = UDim2.new(1, -20, 1 - splitRatio, -15)
        panel2.Position = UDim2.new(0, 10, splitRatio, 5)
        
        -- Set mouse cursor for horizontal divider
        dragHandle.MouseEnter:Connect(function()
            dragHandle.MouseIcon = "rbxassetid://5756380506" -- NS-resize cursor
        end)
    else -- vertical split (left/right)
        panel1.Size = UDim2.new(splitRatio, -5, 1, -20)
        panel1.Position = UDim2.new(0, 10, 0, 10)
        
        divider.Size = UDim2.new(0, 4, 1, -20)
        divider.Position = UDim2.new(splitRatio, 0, 0, 10)
        
        dragHandle.Size = UDim2.new(0, 10, 1, -20)
        dragHandle.Position = UDim2.new(splitRatio, -3, 0, 10)
        
        panel2.Size = UDim2.new(1 - splitRatio, -15, 1, -20)
        panel2.Position = UDim2.new(splitRatio, 5, 0, 10)
        
        -- Set mouse cursor for vertical divider
        dragHandle.MouseEnter:Connect(function()
            dragHandle.MouseIcon = "rbxassetid://5756381960" -- EW-resize cursor
        end)
    end
    
    -- Reset mouse cursor when leaving
    dragHandle.MouseLeave:Connect(function()
        dragHandle.MouseIcon = ""
    end)
    
    -- Make divider resizable
    local dragging = false
    local minSplitRatio = 0.1
    local maxSplitRatio = 0.9
    local startPos, startRatio
    
    dragHandle.MouseButton1Down:Connect(function()
        dragging = true
        startRatio = splitRatio
        if splitDirection == "horizontal" then
            startPos = game:GetService("UserInputService"):GetMouseLocation().Y
        else
            startPos = game:GetService("UserInputService"):GetMouseLocation().X
        end
    end)
    
    dragHandle.MouseButton1Up:Connect(function()
        dragging = false
    end)
    
    dragHandle.MouseMoved:Connect(function(x, y)
        if dragging then
            local newRatio = startRatio
            
            if splitDirection == "horizontal" then
                local mouseY = game:GetService("UserInputService"):GetMouseLocation().Y
                local deltaY = mouseY - startPos
                local containerHeight = container.AbsoluteSize.Y
                newRatio = startRatio + (deltaY / containerHeight)
            else
                local mouseX = game:GetService("UserInputService"):GetMouseLocation().X
                local deltaX = mouseX - startPos
                local containerWidth = container.AbsoluteSize.X
                newRatio = startRatio + (deltaX / containerWidth)
            end
            
            -- Clamp the ratio
            newRatio = math.clamp(newRatio, minSplitRatio, maxSplitRatio)
            
            -- Update the ratio and positions
            if splitDirection == "horizontal" then
                panel1.Size = UDim2.new(1, -20, newRatio, -5)
                divider.Position = UDim2.new(0, 10, newRatio, 0)
                dragHandle.Position = UDim2.new(0, 10, newRatio, -3)
                panel2.Size = UDim2.new(1, -20, 1 - newRatio, -15)
                panel2.Position = UDim2.new(0, 10, newRatio, 5)
            else
                panel1.Size = UDim2.new(newRatio, -5, 1, -20)
                divider.Position = UDim2.new(newRatio, 0, 0, 10)
                dragHandle.Position = UDim2.new(newRatio, -3, 0, 10)
                panel2.Size = UDim2.new(1 - newRatio, -15, 1, -20)
                panel2.Position = UDim2.new(newRatio, 5, 0, 10)
            end
            
            splitRatio = newRatio
        end
    end)
    
    if parent then
        container.Parent = parent
    end
    
    -- Return the container components
    return {
        container = container,
        panel1 = panel1,
        panel2 = panel2,
        divider = divider,
        splitRatio = splitRatio,
        splitDirection = splitDirection,
        
        -- Function to update split ratio
        setSplitRatio = function(ratio)
            ratio = math.clamp(ratio, minSplitRatio, maxSplitRatio)
            
            if splitDirection == "horizontal" then
                panel1.Size = UDim2.new(1, -20, ratio, -5)
                divider.Position = UDim2.new(0, 10, ratio, 0)
                dragHandle.Position = UDim2.new(0, 10, ratio, -3)
                panel2.Size = UDim2.new(1, -20, 1 - ratio, -15)
                panel2.Position = UDim2.new(0, 10, ratio, 5)
            else
                panel1.Size = UDim2.new(ratio, -5, 1, -20)
                divider.Position = UDim2.new(ratio, 0, 0, 10)
                dragHandle.Position = UDim2.new(ratio, -3, 0, 10)
                panel2.Size = UDim2.new(1 - ratio, -15, 1, -20)
                panel2.Position = UDim2.new(ratio, 5, 0, 10)
            end
            
            splitRatio = ratio
        end
    }
end

return MenuContainer