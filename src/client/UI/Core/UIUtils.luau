--!strict
--[[
    UIUtils.luau
    
    Common UI utilities and helper functions.
    Centralizes shared UI functionality to reduce code duplication.
]]

local TweenService = game:GetService("TweenService")

-- UIUtils
local UIUtils = {}

-- Common colors
UIUtils.Colors = {
    Primary = Color3.fromRGB(114, 137, 218),
    Secondary = Color3.fromRGB(50, 53, 59),
    Background = Color3.fromRGB(40, 40, 45),
    BackgroundDark = Color3.fromRGB(30, 30, 35),
    Text = Color3.fromRGB(255, 255, 255),
    Error = Color3.fromRGB(231, 76, 60),
    Success = Color3.fromRGB(46, 204, 113),
    Warning = Color3.fromRGB(241, 196, 15),
    Disabled = Color3.fromRGB(128, 128, 128),
    Hover = Color3.fromRGB(255, 255, 255)
}

-- Common fonts
UIUtils.Fonts = {
    Title = Enum.Font.GothamBold,
    Subtitle = Enum.Font.GothamBold,
    Body = Enum.Font.Gotham,
    Button = Enum.Font.GothamBold,
    Code = Enum.Font.Code
}

-- Common text sizes
UIUtils.TextSizes = {
    Title = 36,
    Subtitle = 24,
    Body = 16,
    Small = 14,
    Button = 18
}

-- Common animations
UIUtils.Animations = {
    Default = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    Elastic = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
}

-- Common layouts
UIUtils.Layouts = {
    Vertical = {
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder
    },
    Horizontal = {
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder
    }
}

-- Create a frame with common properties
function UIUtils.createFrame(parent, properties)
    local frame = Instance.new("Frame")
    
    -- Set common properties
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    
    -- Apply custom properties
    for property, value in pairs(properties) do
        frame[property] = value
    end
    
    -- Add corner radius if specified
    if properties.CornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, properties.CornerRadius)
        corner.Parent = frame
    end
    
    -- Add layout if specified
    if properties.Layout then
        local layout = Instance.new("UIListLayout")
        for property, value in pairs(properties.Layout) do
            layout[property] = value
        end
        layout.Parent = frame
    end
    
    -- Parent the frame
    if parent then
        frame.Parent = parent
    end
    
    return frame
end

-- Create a label with common properties
function UIUtils.createLabel(parent, properties)
    local label = Instance.new("TextLabel")
    
    -- Set common properties
    label.BackgroundTransparency = 1
    label.TextColor3 = UIUtils.Colors.Text
    label.Font = UIUtils.Fonts.Body
    label.TextSize = UIUtils.TextSizes.Body
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    
    -- Apply custom properties
    for property, value in pairs(properties) do
        label[property] = value
    end
    
    -- Parent the label
    if parent then
        label.Parent = parent
    end
    
    return label
end

-- Create a button with common properties
function UIUtils.createButton(parent, properties)
    local button = Instance.new("TextButton")
    
    -- Set common properties
    button.BackgroundColor3 = UIUtils.Colors.Secondary
    button.TextColor3 = UIUtils.Colors.Text
    button.Font = UIUtils.Fonts.Button
    button.TextSize = UIUtils.TextSizes.Button
    button.AutoButtonColor = true
    button.TextTruncate = Enum.TextTruncate.AtEnd
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Apply custom properties
    for property, value in pairs(properties) do
        button[property] = value
    end
    
    -- Parent the button
    if parent then
        button.Parent = parent
    end
    
    return button
end

-- Create a gradient background
function UIUtils.createGradient(parent, properties)
    local frame = UIUtils.createFrame(parent, properties)
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, UIUtils.Colors.Background),
        ColorSequenceKeypoint.new(1, UIUtils.Colors.BackgroundDark)
    })
    gradient.Rotation = properties.Rotation or 45
    gradient.Parent = frame
    
    return frame, gradient
end

-- Setup button hover effects
function UIUtils.setupButtonHover(button, baseColor, hoverColor)
    baseColor = baseColor or button.BackgroundColor3
    hoverColor = hoverColor or baseColor:Lerp(UIUtils.Colors.Hover, 0.2)
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = baseColor
    end)
end

-- Create a separator line
function UIUtils.createSeparator(parent, properties)
    local separator = UIUtils.createFrame(parent, {
        Size = UDim2.new(0.8, 0, 0, 2),
        Position = UDim2.new(0.1, 0, 0, 0),
        BackgroundColor3 = UIUtils.Colors.Primary,
        BorderSizePixel = 0
    })
    
    -- Apply custom properties
    for property, value in pairs(properties) do
        separator[property] = value
    end
    
    return separator
end

-- Create a container for buttons
function UIUtils.createButtonContainer(parent, properties)
    local container = UIUtils.createFrame(parent, {
        Size = UDim2.new(0.8, 0, 0, 300),
        Position = UDim2.new(0.1, 0, 0, 0),
        BackgroundTransparency = 1,
        Layout = UIUtils.Layouts.Vertical
    })
    
    -- Apply custom properties
    for property, value in pairs(properties) do
        container[property] = value
    end
    
    return container
end

-- Create a scrollable frame
function UIUtils.createScrollFrame(parent, properties)
    local scrollFrame = Instance.new("ScrollingFrame")
    
    -- Set common properties
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    -- Add corner radius if specified
    if properties.CornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, properties.CornerRadius)
        corner.Parent = scrollFrame
    end
    
    -- Apply custom properties
    for property, value in pairs(properties) do
        scrollFrame[property] = value
    end
    
    -- Parent the scroll frame
    if parent then
        scrollFrame.Parent = parent
    end
    
    return scrollFrame
end

-- Create an input field
function UIUtils.createInputField(parent, properties)
    local container = UIUtils.createFrame(parent, {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = UIUtils.Colors.Background,
        CornerRadius = 8
    })
    
    local input = Instance.new("TextBox")
    input.BackgroundTransparency = 1
    input.TextColor3 = UIUtils.Colors.Text
    input.Font = UIUtils.Fonts.Body
    input.TextSize = UIUtils.TextSizes.Body
    input.PlaceholderColor3 = UIUtils.Colors.Disabled
    input.Size = UDim2.new(1, -20, 1, 0)
    input.Position = UDim2.new(0, 10, 0, 0)
    input.Parent = container
    
    -- Apply custom properties
    for property, value in pairs(properties) do
        if property ~= "PlaceholderText" then
            input[property] = value
        end
    end
    
    -- Set placeholder text if provided
    if properties.PlaceholderText then
        input.PlaceholderText = properties.PlaceholderText
    end
    
    return container, input
end

-- Create a toggle button
function UIUtils.createToggle(parent, properties)
    local container = UIUtils.createFrame(parent, {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1
    })
    
    local label = UIUtils.createLabel(container, {
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = properties.Text or "Toggle",
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local toggle = UIUtils.createFrame(container, {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = UIUtils.Colors.Secondary,
        CornerRadius = 10
    })
    
    local handle = UIUtils.createFrame(toggle, {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = UIUtils.Colors.Text,
        CornerRadius = 8
    })
    
    local isOn = false
    
    local function updateToggle()
        local targetPos = isOn and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local targetColor = isOn and UIUtils.Colors.Primary or UIUtils.Colors.Secondary
        
        local tween = TweenService:Create(handle, UIUtils.Animations.Default, {
            Position = targetPos
        })
        tween:Play()
        
        local colorTween = TweenService:Create(toggle, UIUtils.Animations.Default, {
            BackgroundColor3 = targetColor
        })
        colorTween:Play()
    end
    
    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isOn = not isOn
            updateToggle()
            if properties.OnToggle then
                properties.OnToggle(isOn)
            end
        end
    end)
    
    return container, toggle, function(value)
        isOn = value
        updateToggle()
    end
end

-- Create a slider
function UIUtils.createSlider(parent, properties)
    local container = UIUtils.createFrame(parent, {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1
    })
    
    local label = UIUtils.createLabel(container, {
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = properties.Text or "Slider",
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local track = UIUtils.createFrame(container, {
        Size = UDim2.new(0, 200, 0, 4),
        Position = UDim2.new(1, -210, 0.5, -2),
        BackgroundColor3 = UIUtils.Colors.Secondary,
        CornerRadius = 2
    })
    
    local fill = UIUtils.createFrame(track, {
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = UIUtils.Colors.Primary,
        CornerRadius = 2
    })
    
    local handle = UIUtils.createFrame(track, {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = UIUtils.Colors.Text,
        CornerRadius = 8
    })
    
    local value = properties.Value or 0
    local min = properties.Min or 0
    local max = properties.Max or 1
    
    local function updateSlider(newValue)
        value = math.clamp(newValue, min, max)
        local ratio = (value - min) / (max - min)
        
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        handle.Position = UDim2.new(ratio, -8, 0.5, -8)
        
        if properties.OnChange then
            properties.OnChange(value)
        end
    end
    
    local isDragging = false
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
        end
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position.X
            local trackPos = track.AbsolutePosition.X
            local trackSize = track.AbsoluteSize.X
            local ratio = (mousePos - trackPos) / trackSize
            updateSlider(min + ratio * (max - min))
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = input.Position.X
            local trackPos = track.AbsolutePosition.X
            local trackSize = track.AbsoluteSize.X
            local ratio = (mousePos - trackPos) / trackSize
            updateSlider(min + ratio * (max - min))
        end
    end)
    
    updateSlider(value)
    
    return container, function(newValue)
        updateSlider(newValue)
    end
end

return UIUtils 