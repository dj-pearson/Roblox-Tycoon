--[[
    UIUtils.luau
    
    A collection of reusable UI components and utility functions for creating
    consistent user interfaces across the game.
    
    Author: Updated April 2025
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Load required modules if available
local sharedFolder = script.Parent
local UIStyleModule = sharedFolder and sharedFolder:FindFirstChild("UIStyle")
local UIStyle = UIStyleModule and require(UIStyleModule) or {
    -- Default styling if UIStyle module is not available
    colors = {
        background = Color3.fromRGB(40, 40, 60),
        backgroundLight = Color3.fromRGB(60, 60, 80),
        backgroundDark = Color3.fromRGB(30, 30, 45),
        accent = Color3.fromRGB(80, 150, 255),
        text = Color3.fromRGB(240, 240, 255),
        textDimmed = Color3.fromRGB(180, 180, 200)
    },
    cornerRadius = UDim.new(0, 8),
    defaultFont = Enum.Font.Gotham,
    fontSize = {
        small = 12,
        medium = 16, 
        large = 20,
        title = 24
    },
    padding = {
        small = 4,
        medium = 8,
        large = 16
    },
    animation = {
        openTime = 0.3,
        closeTime = 0.2
    }
}

-- Create the UIUtils module
local UIUtils = {}

-- Helper function to create a default corner
local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or UIStyle.cornerRadius
    corner.Parent = instance
    return corner
end

--[[
    Creates a standardized menu container with title and close button
    
    @param name (string): The name of the menu
    @param title (string): The text to display in the title bar
    @param size (UDim2): The size of the menu container
    @param position (UDim2): The position of the menu container
    @return (table): Container objects
]]
function UIUtils.createMenuContainer(name, title, size, position)
    -- Create ScreenGui container
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = name .. "Container"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "mainFrame"
    mainFrame.Size = size or UDim2.new(0, 500, 0, 400)
    mainFrame.Position = position or UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = UIStyle.colors.background
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false -- Hidden by default
    mainFrame.Parent = screenGui
    
    -- Add corner rounding to main frame
    addCorner(mainFrame)
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = UIStyle.colors.accent
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Add corner rounding to title bar
    local titleCorner = addCorner(titleBar)
    titleCorner.CornerRadius = UDim.new(0, 8)
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = UIStyle.defaultFont
    titleText.Text = title or name
    titleText.TextColor3 = UIStyle.colors.text
    titleText.TextSize = UIStyle.fontSize.title
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.BackgroundTransparency = 0.5
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Parent = titleBar
    
    -- Add corner rounding to close button
    addCorner(closeButton, UDim.new(0, 15))
    
    -- Create content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -50)
    contentFrame.Position = UDim2.new(0, 10, 0, 45)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Add to PlayerGui
    local localPlayer = Players.LocalPlayer
    if localPlayer then
        local playerGui = localPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            screenGui.Parent = playerGui
        else
            localPlayer.ChildAdded:Connect(function(child)
                if child.Name == "PlayerGui" then
                    screenGui.Parent = child
                end
            end)
        end
    end
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)
    
    -- Set up dragging behavior for the menu
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function updateDrag(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateDrag(input)
        end
    end)
    
    -- Return container objects
    return {
        screenGui = screenGui,
        mainFrame = mainFrame,
        titleBar = titleBar,
        titleText = titleText,
        contentFrame = contentFrame,
        closeButton = closeButton
    }
end

--[[
    Creates a standardized tab system within a container
    
    @param parent (Instance): The parent frame to contain the tab system
    @param tabs (table): Array of tab definitions, e.g. {{name = "Tab1", label = "Tab 1"}}
    @return (table): Tab system objects
]]
function UIUtils.createTabSystem(parent, tabs)
    if not parent or not tabs or #tabs == 0 then
        warn("Cannot create tab system: missing parent or tabs")
        return nil
    end
    
    -- Create tabs container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.Size = UDim2.new(1, 0, 0, 35)
    tabsContainer.BackgroundColor3 = UIStyle.colors.backgroundLight
    tabsContainer.BorderSizePixel = 0
    tabsContainer.Parent = parent
    
    addCorner(tabsContainer, UDim.new(0, 6))
    
    -- Create tab list layout
    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.FillDirection = Enum.FillDirection.Horizontal
    tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 5)
    tabListLayout.Parent = tabsContainer
    
    -- Add padding to the beginning
    local paddingLeft = Instance.new("UIPadding")
    paddingLeft.PaddingLeft = UDim.new(0, 10)
    paddingLeft.Parent = tabsContainer
    
    -- Create tab content container
    local tabContents = Instance.new("Frame")
    tabContents.Name = "TabContents"
    tabContents.Size = UDim2.new(1, 0, 1, -45)
    tabContents.Position = UDim2.new(0, 0, 0, 40)
    tabContents.BackgroundTransparency = 1
    tabContents.Parent = parent
    
    -- Tab buttons and content frames
    local tabButtons = {}
    local tabFrames = {}
    local activeTab = nil
    
    -- Function to switch tabs
    local function switchTab(tabName)
        -- Hide all tab contents
        for name, frame in pairs(tabFrames) do
            frame.Visible = (name == tabName)
        end
        
        -- Update tab button styling
        for name, button in pairs(tabButtons) do
            local isActive = (name == tabName)
            button.BackgroundColor3 = isActive and UIStyle.colors.accent or UIStyle.colors.backgroundLight
            button.BackgroundTransparency = isActive and 0 or 0.5
            button.TextColor3 = isActive and UIStyle.colors.text or UIStyle.colors.textDimmed
        end
        
        activeTab = tabName
    end
    
    -- Create tabs
    for i, tabInfo in ipairs(tabs) do
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabInfo.name .. "Button"
        tabButton.Size = UDim2.new(0, 100, 0, 25)
        tabButton.BackgroundColor3 = UIStyle.colors.backgroundLight
        tabButton.BackgroundTransparency = 0.5
        tabButton.Font = UIStyle.defaultFont
        tabButton.Text = tabInfo.label or tabInfo.name
        tabButton.TextColor3 = UIStyle.colors.textDimmed
        tabButton.TextSize = UIStyle.fontSize.medium
        tabButton.LayoutOrder = i
        tabButton.Parent = tabsContainer
        
        addCorner(tabButton, UDim.new(0, 4))
        
        -- Create tab content frame
        local contentFrame = Instance.new("Frame")
        contentFrame.Name = tabInfo.name
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Visible = false
        contentFrame.Parent = tabContents
        
        -- Store references
        tabButtons[tabInfo.name] = tabButton
        tabFrames[tabInfo.name] = contentFrame
        
        -- Connect button click
        tabButton.MouseButton1Click:Connect(function()
            switchTab(tabInfo.name)
        end)
    end
    
    -- Switch to the first tab initially
    if #tabs > 0 then
        switchTab(tabs[1].name)
    end
    
    -- Return tab system objects
    return {
        container = tabsContainer,
        buttons = tabButtons,
        tabContents = tabFrames,
        switchTab = switchTab,
        activeTab = function() return activeTab end
    }
end

--[[
    Creates a card within a container for displaying information
    
    @param parent (Instance): The parent frame to contain the card
    @param height (number): The height of the card
    @param backgroundColor (Color3): The background color of the card
    @return (Frame): The card frame
]]
function UIUtils.createCard(parent, height, backgroundColor)
    if not parent then 
        warn("Cannot create card: missing parent")
        return nil
    end
    
    -- Create card frame
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -20, 0, height or 100)
    card.BackgroundColor3 = backgroundColor or UIStyle.colors.backgroundLight
    card.BorderSizePixel = 0
    card.Parent = parent
    
    -- Add corner rounding
    addCorner(card, UDim.new(0, 8))
    
    return card
end

--[[
    Creates a notification that appears and fades out
    
    @param parent (Instance): The parent for the notification
    @param message (string): The text to display
    @param duration (number): How long to show the notification (in seconds)
    @return (Frame): The notification frame
]]
function UIUtils.createNotification(parent, message, duration)
    if not parent then
        warn("Cannot create notification: missing parent")
        return nil
    end
    
    -- Create notification frame
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "Notification"
    notificationFrame.Size = UDim2.new(1, -20, 0, 60)
    notificationFrame.BackgroundColor3 = UIStyle.colors.backgroundDark
    notificationFrame.BackgroundTransparency = 0.2
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = parent
    
    -- Add corner rounding
    addCorner(notificationFrame, UDim.new(0, 8))
    
    -- Create message text
    local messageText = Instance.new("TextLabel")
    messageText.Size = UDim2.new(1, -20, 1, -10)
    messageText.Position = UDim2.new(0, 10, 0, 5)
    messageText.BackgroundTransparency = 1
    messageText.Font = UIStyle.defaultFont
    messageText.Text = message
    messageText.TextColor3 = UIStyle.colors.text
    messageText.TextSize = UIStyle.fontSize.medium
    messageText.TextWrapped = true
    messageText.TextXAlignment = Enum.TextXAlignment.Center
    messageText.TextYAlignment = Enum.TextYAlignment.Center
    messageText.Parent = notificationFrame
    
    -- Fade in
    notificationFrame.BackgroundTransparency = 1
    messageText.TextTransparency = 1
    
    -- Animation
    TweenService:Create(
        notificationFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.2 }
    ):Play()
    
    TweenService:Create(
        messageText,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { TextTransparency = 0 }
    ):Play()
    
    -- Remove after duration
    task.delay(duration or 3, function()
        -- Fade out animation
        TweenService:Create(
            notificationFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }
        ):Play()
        
        TweenService:Create(
            messageText,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { TextTransparency = 1 }
        ):Play()
        
        -- Destroy after animation completes
        task.delay(0.6, function()
            notificationFrame:Destroy()
        end)
    end)
    
    return notificationFrame
end

--[[
    Creates a scrolling frame for a list of items
    
    @param parent (Instance): The parent frame to contain the scrolling list
    @return (table): Scrolling list objects
]]
function UIUtils.createScrollingList(parent)
    if not parent then
        warn("Cannot create scrolling list: missing parent")
        return nil
    end
    
    -- Create scrolling frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = UIStyle.colors.accent
    scrollFrame.Parent = parent
    
    -- Create list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    -- Create padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.Parent = scrollFrame
    
    -- Auto-update canvas size
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    return {
        scrollFrame = scrollFrame,
        listLayout = listLayout,
        padding = padding
    }
end

--[[
    Creates a toggle button with an icon
    
    @param text (string): Text to display on the button
    @param iconName (string): Name of the icon to use (from ReplicatedStorage.Icons) 
    @param position (UDim2): Position of the button
    @param callback (function): Function to call when the button is clicked
    @return (table): Button objects
]]
function UIUtils.createToggleButton(text, iconName, position, callback)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    
    if not LocalPlayer then
        warn("Cannot create toggle button: LocalPlayer not found")
        return nil
    end
    
    -- Create ScreenGui if PlayerGui exists
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = text .. "Toggle"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create button
    local button = Instance.new("TextButton")
    button.Name = "ToggleButton"
    button.Size = UDim2.new(0, 120, 0, 40)
    button.Position = position or UDim2.new(1, -130, 0, 10)
    button.AnchorPoint = Vector2.new(1, 0)
    button.BackgroundColor3 = UIStyle.colors.accent
    button.Font = UIStyle.defaultFont
    button.Text = "    " .. text -- Space for icon
    button.TextColor3 = UIStyle.colors.text
    button.TextSize = UIStyle.fontSize.medium
    button.Parent = screenGui
    
    -- Add corner rounding
    addCorner(button, UDim.new(0, 8))
    
    -- Try to add icon if it exists in ReplicatedStorage
    local icons = ReplicatedStorage:FindFirstChild("Icons")
    if icons and iconName and icons:FindFirstChild(iconName) then
        local icon = icons:FindFirstChild(iconName):Clone()
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0, 10, 0.5, -10)
        icon.Parent = button
    end
    
    -- Connect callback
    if callback and type(callback) == "function" then
        button.MouseButton1Click:Connect(function()
            callback(button)
        end)
    end
    
    -- Add hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.2),
            { BackgroundColor3 = UIStyle.colors.accent:Lerp(Color3.new(1, 1, 1), 0.2) }
        ):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.2),
            { BackgroundColor3 = UIStyle.colors.accent }
        ):Play()
    end)
    
    -- Parent to PlayerGui
    if LocalPlayer:FindFirstChild("PlayerGui") then
        screenGui.Parent = LocalPlayer.PlayerGui
    else
        LocalPlayer.ChildAdded:Connect(function(child)
            if child.Name == "PlayerGui" then
                screenGui.Parent = child
            end
        end)
    end
    
    return {
        screenGui = screenGui,
        button = button,        setText = function(newText)
            button.Text = "    " .. newText
        end,
        setPosition = function(newPosition)
            button.Position = newPosition
        end
    }
end

--[[
    Creates a progress bar
    
    @param parent (Instance): The parent frame to contain the progress bar
    @param size (UDim2): Size of the progress bar
    @param position (UDim2): Position of the progress bar
    @param fillColor (Color3): Color of the progress fill
    @return (table): Progress bar objects and functions
]]
function UIUtils.createProgressBar(parent, size, position, fillColor)
    if not parent then
        warn("Cannot create progress bar: missing parent")
        return nil
    end
    
    -- Create container for progress bar
    local container = Instance.new("Frame")
    container.Name = "ProgressBarContainer"
    container.Size = size or UDim2.new(1, -20, 0, 20)
    container.Position = position or UDim2.new(0, 10, 0, 10)
    container.BackgroundColor3 = UIStyle.colors.backgroundDark
    container.BorderSizePixel = 0
    container.Parent = parent
    
    -- Add corner rounding to container
    addCorner(container, UDim.new(0, 4))
    
    -- Create fill for progress bar
    local fill = Instance.new("Frame")
    fill.Name = "ProgressFill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = fillColor or UIStyle.colors.accent
    fill.BorderSizePixel = 0
    fill.Parent = container
    
    -- Add corner rounding to fill
    addCorner(fill, UDim.new(0, 4))
    
    -- Function to update progress (0-1)
    local function updateProgress(progress)
        progress = math.clamp(progress, 0, 1)
        
        -- Tween the fill
        TweenService:Create(
            fill,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(progress, 0, 1, 0) }
        ):Play()
        
        return progress
    end
    
    return {
        container = container,
        fill = fill,
        updateProgress = updateProgress
    }
end

--[[
    Creates a standardized input field with label
    
    @param parent (Instance): The parent frame to contain the input
    @param labelText (string): The label text for the input
    @param defaultValue (string): Default value for the input
    @param inputType (string): Type of input: "text", "number", "password"
    @param position (UDim2): Position of the input field
    @param callback (function): Function to call when input changes
    @return (table): Input field objects and functions
]]
function UIUtils.createInputField(parent, labelText, defaultValue, inputType, position, callback)
    if not parent then
        warn("Cannot create input field: missing parent")
        return nil
    end
    
    -- Create the input container
    local container = Instance.new("Frame")
    container.Name = "InputContainer"
    container.Size = UDim2.new(1, -20, 0, 60)
    container.Position = position or UDim2.new(0, 10, 0, 10)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Create label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.Font = UIStyle.defaultFont
    label.Text = labelText or "Input:"
    label.TextColor3 = UIStyle.colors.text
    label.TextSize = UIStyle.fontSize.medium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Create input background
    local inputBackground = Instance.new("Frame")
    inputBackground.Name = "InputBackground"
    inputBackground.Size = UDim2.new(1, 0, 0, 30)
    inputBackground.Position = UDim2.new(0, 0, 0, 30)
    inputBackground.BackgroundColor3 = UIStyle.colors.background
    inputBackground.BorderSizePixel = 0
    inputBackground.Parent = container
    
    -- Add corner rounding to input background
    addCorner(inputBackground, UDim.new(0, 6))
    
    -- Create text input
    local input
    if inputType == "multi" then
        -- Create multi-line text box
        input = Instance.new("TextBox")
        input.Size = UDim2.new(1, -10, 1, -10)
        input.Position = UDim2.new(0, 5, 0, 5)
        input.BackgroundTransparency = 1
        input.Font = UIStyle.defaultFont
        input.PlaceholderText = "Enter text here..."
        input.PlaceholderColor3 = UIStyle.colors.textDimmed
        input.Text = defaultValue or ""
        input.TextColor3 = UIStyle.colors.text
        input.TextSize = UIStyle.fontSize.medium
        input.TextXAlignment = Enum.TextXAlignment.Left
        input.TextYAlignment = Enum.TextYAlignment.Top
        input.ClearTextOnFocus = false
        input.MultiLine = true
        input.TextWrapped = true
        input.Parent = inputBackground
    else
        -- Create single line input
        input = Instance.new("TextBox")
        input.Size = UDim2.new(1, -10, 1, 0)
        input.Position = UDim2.new(0, 5, 0, 0)
        input.BackgroundTransparency = 1
        input.Font = UIStyle.defaultFont
        input.PlaceholderText = "Enter text here..."
        input.PlaceholderColor3 = UIStyle.colors.textDimmed
        input.Text = defaultValue or ""
        input.TextColor3 = UIStyle.colors.text
        input.TextSize = UIStyle.fontSize.medium
        input.TextXAlignment = Enum.TextXAlignment.Left
        input.ClearTextOnFocus = false
        input.Parent = inputBackground
    end
    
    -- Set input type specific properties
    if inputType == "number" then
        input.PlaceholderText = "Enter number..."
    elseif inputType == "password" then
        input.PlaceholderText = "Enter password..."
        input.TextScaled = false
        input.TextSize = UIStyle.fontSize.medium
    end
    
    -- Connect callback
    if callback and type(callback) == "function" then
        input.FocusLost:Connect(function(enterPressed)
            callback(input.Text, enterPressed)
        end)
    end
    
    return {
        container = container,
        label = label,
        input = input,        getValue = function()
            return input.Text
        end,
        setValue = function(newValue)
            input.Text = newValue or ""
        end
    }
end

--[[
    Creates a button with configurable style
    
    @param parent (Instance): The parent frame to contain the button
    @param text (string): Text to display on the button
    @param size (UDim2): Size of the button
    @param position (UDim2): Position of the button
    @param callback (function): Function to call when the button is clicked
    @param style (string): Optional style: "primary", "secondary", "danger"
    @return (TextButton): The button instance
]]
function UIUtils.createButton(parent, text, size, position, callback, style)
    if not parent then
        warn("Cannot create button: missing parent")
        return nil
    end
      -- Determine button color based on style
    local buttonColor = UIStyle.colors.accent -- Default color (for primary or unspecified style)
    if style == "secondary" then
        buttonColor = UIStyle.colors.backgroundLight
    elseif style == "danger" then
        buttonColor = Color3.fromRGB(200, 50, 50)
    end
    
    -- Create the button
    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Size = size or UDim2.new(0, 120, 0, 40)
    button.Position = position or UDim2.new(0.5, -60, 0, 10)
    button.BackgroundColor3 = buttonColor
    button.Font = UIStyle.defaultFont
    button.Text = text or "Button"
    button.TextColor3 = UIStyle.colors.text
    button.TextSize = UIStyle.fontSize.medium
    button.Parent = parent
    
    -- Add corner rounding
    addCorner(button, UDim.new(0, 6))
    
    -- Connect callback
    if callback and type(callback) == "function" then
        button.MouseButton1Click:Connect(callback)
    end
    
    -- Add hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.2),
            { BackgroundColor3 = buttonColor:Lerp(Color3.new(1, 1, 1), 0.2) }
        ):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(0.2),
            { BackgroundColor3 = buttonColor }
        ):Play()
    end)
    
    return button
end

--[[
    Creates a dropdown menu
    
    @param parent (Instance): The parent frame to contain the dropdown
    @param labelText (string): Label text for the dropdown
    @param options (table): Array of options to display
    @param defaultOption (string/number): Default selected option
    @param position (UDim2): Position of the dropdown
    @param callback (function): Function called when selection changes
    @return (table): Dropdown objects and functions
]]
function UIUtils.createDropdown(parent, labelText, options, defaultOption, position, callback)
    if not parent or not options or #options == 0 then
        warn("Cannot create dropdown: missing parent or options")
        return nil
    end
    
    -- Create dropdown container
    local container = Instance.new("Frame")
    container.Name = "DropdownContainer"
    container.Size = UDim2.new(1, -20, 0, 65)
    container.Position = position or UDim2.new(0, 10, 0, 10)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Create label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.Font = UIStyle.defaultFont
    label.Text = labelText or "Select option:"
    label.TextColor3 = UIStyle.colors.text
    label.TextSize = UIStyle.fontSize.medium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Create selected option button
    local selectedButton = Instance.new("TextButton")
    selectedButton.Name = "SelectedButton"
    selectedButton.Size = UDim2.new(1, 0, 0, 35)
    selectedButton.Position = UDim2.new(0, 0, 0, 30)
    selectedButton.BackgroundColor3 = UIStyle.colors.background
    selectedButton.Font = UIStyle.defaultFont
    selectedButton.TextColor3 = UIStyle.colors.text
    selectedButton.TextSize = UIStyle.fontSize.medium
    selectedButton.TextXAlignment = Enum.TextXAlignment.Left
    selectedButton.Text = "   " .. (type(defaultOption) == "number" and options[defaultOption] or defaultOption or options[1] or "Select...")
    selectedButton.Parent = container
    
    -- Add corner rounding to button
    addCorner(selectedButton, UDim.new(0, 6))
    
    -- Create dropdown arrow indicator
    local arrowLabel = Instance.new("TextLabel")
    arrowLabel.Name = "ArrowLabel"
    arrowLabel.Size = UDim2.new(0, 20, 0, 20)
    arrowLabel.Position = UDim2.new(1, -30, 0.5, -10)
    arrowLabel.BackgroundTransparency = 1
    arrowLabel.Font = Enum.Font.SourceSansBold
    arrowLabel.Text = "▼"
    arrowLabel.TextColor3 = UIStyle.colors.text
    arrowLabel.TextSize = UIStyle.fontSize.medium
    arrowLabel.Parent = selectedButton
    
    -- Create options list frame
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name = "OptionsFrame"
    optionsFrame.Size = UDim2.new(1, 0, 0, math.min(#options * 30, 150))
    optionsFrame.Position = UDim2.new(0, 0, 1, 5)
    optionsFrame.BackgroundColor3 = UIStyle.colors.background
    optionsFrame.BorderSizePixel = 0
    optionsFrame.Visible = false
    optionsFrame.ZIndex = 10
    optionsFrame.Parent = selectedButton
    
    -- Add corner rounding to options frame
    addCorner(optionsFrame, UDim.new(0, 6))
    
    -- Create scrolling frame for options
    local optionsScroll = Instance.new("ScrollingFrame")
    optionsScroll.Size = UDim2.new(1, -10, 1, -10)
    optionsScroll.Position = UDim2.new(0, 5, 0, 5)
    optionsScroll.BackgroundTransparency = 1
    optionsScroll.BorderSizePixel = 0
    optionsScroll.ScrollBarThickness = 4
    optionsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    optionsScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
    optionsScroll.ZIndex = 10
    optionsScroll.Parent = optionsFrame
    
    -- Create list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = optionsScroll
    
    -- Current selected value
    local selectedValue = type(defaultOption) == "number" and options[defaultOption] or defaultOption or options[1]
    local selectedIndex = 1
    
    -- Find initial selected index
    for i, option in ipairs(options) do
        if option == selectedValue then
            selectedIndex = i
            break
        end
    end
    
    -- Create option buttons
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option_" .. i
        optionButton.Size = UDim2.new(1, 0, 0, 28)
        optionButton.BackgroundColor3 = i == selectedIndex and UIStyle.colors.accent or UIStyle.colors.background
        optionButton.BackgroundTransparency = 0.2
        optionButton.Font = UIStyle.defaultFont
        optionButton.Text = "   " .. option
        optionButton.TextColor3 = UIStyle.colors.text
        optionButton.TextSize = UIStyle.fontSize.medium
        optionButton.TextXAlignment = Enum.TextXAlignment.Left
        optionButton.ZIndex = 10
        optionButton.Parent = optionsScroll
        
        -- Add corner rounding
        addCorner(optionButton, UDim.new(0, 4))
        
        -- Option button hover effect
        optionButton.MouseEnter:Connect(function()
            if option ~= selectedValue then
                TweenService:Create(
                    optionButton,
                    TweenInfo.new(0.1),
                    { BackgroundColor3 = UIStyle.colors.backgroundLight }
                ):Play()
            end
        end)
        
        optionButton.MouseLeave:Connect(function()
            if option ~= selectedValue then
                TweenService:Create(
                    optionButton,
                    TweenInfo.new(0.1),
                    { BackgroundColor3 = UIStyle.colors.background }
                ):Play()
            end
        end)
        
        -- Select option
        optionButton.MouseButton1Click:Connect(function()
            selectedValue = option
            selectedIndex = i
            selectedButton.Text = "   " .. option
            optionsFrame.Visible = false
            arrowLabel.Text = "▼"
            
            -- Update option button colors
            for _, child in ipairs(optionsScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = child == optionButton and UIStyle.colors.accent or UIStyle.colors.background
                end
            end
            
            -- Call callback
            if callback then
                callback(option, i)
            end
        end)
    end
    
    -- Toggle dropdown visibility
    local dropdownOpen = false
    selectedButton.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        optionsFrame.Visible = dropdownOpen
        arrowLabel.Text = dropdownOpen and "▲" or "▼"
    end)
    
    -- Close dropdown when clicking elsewhere
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = game:GetService("UserInputService"):GetMouseLocation()
            
            -- Check if click is outside the dropdown area
            if dropdownOpen then
                local inDropdown = false
                local framePos = optionsFrame.AbsolutePosition
                local frameSize = optionsFrame.AbsoluteSize
                
                if mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and 
                   mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y then
                    inDropdown = true
                end
                
                local buttonPos = selectedButton.AbsolutePosition
                local buttonSize = selectedButton.AbsoluteSize
                
                if mousePos.X >= buttonPos.X and mousePos.X <= buttonPos.X + buttonSize.X and 
                   mousePos.Y >= buttonPos.Y and mousePos.Y <= buttonPos.Y + buttonSize.Y then
                    inDropdown = true
                end
                
                if not inDropdown then
                    dropdownOpen = false
                    optionsFrame.Visible = false
                    arrowLabel.Text = "▼"
                end
            end
        end
    end)
    
    -- Return dropdown object with methods
    return {
        container = container,
        selectedButton = selectedButton,
        optionsFrame = optionsFrame,
        getValue = function() return selectedValue end,
        getIndex = function() return selectedIndex end,
        setValue = function(value)
            for i, option in ipairs(options) do
                if option == value then
                    selectedValue = option
                    selectedIndex = i
                    selectedButton.Text = "   " .. option
                    
                    -- Update option button colors
                    for _, child in ipairs(optionsScroll:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.BackgroundColor3 = i == selectedIndex and UIStyle.colors.accent or UIStyle.colors.background
                        end
                    end
                    
                    -- Call callback
                    if callback then
                        callback(option, i)
                    end
                    
                    return true
                end
            end
            return false -- Value not found
        end
    }
end

-- Return the module
return UIUtils