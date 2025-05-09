--!strict
--[[
    UIUtils.luau
    
    Common UI utilities and helper functions.
    Provides reusable functionality for UI components.
]]

local TweenService = game:GetService("TweenService")

-- Constants
local DEFAULT_TWEEN_INFO = TweenInfo.new(
    0.3, -- Time
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)

-- Animation presets
local ANIMATIONS = {
    FADE_IN = {
        info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties = {BackgroundTransparency = 0}
    },
    FADE_OUT = {
        info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        properties = {BackgroundTransparency = 1}
    },
    SLIDE_IN_LEFT = {
        info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties = {Position = UDim2.new(0, 0, 0, 0)}
    },
    SLIDE_OUT_LEFT = {
        info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        properties = {Position = UDim2.new(-1, 0, 0, 0)}
    },
    SCALE_IN = {
        info = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        properties = {Scale = Vector3.new(1, 1, 1)}
    },
    SCALE_OUT = {
        info = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        properties = {Scale = Vector3.new(0, 0, 0)}
    }
}

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

-- Create a UI element with common properties
function UIUtils.createUIElement(className, properties)
    local element = Instance.new(className)
    
    -- Apply common properties
    if properties then
        for property, value in pairs(properties) do
            element[property] = value
        end
    end
    
    return element
end

-- Create a text label with common properties
function UIUtils.createTextLabel(properties)
    local label = UIUtils.createUIElement("TextLabel", {
        BackgroundTransparency = 1,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextWrapped = true
    })
    
    -- Apply custom properties
    if properties then
        for property, value in pairs(properties) do
            label[property] = value
        end
    end
    
    return label
end

-- Create a button with common properties
function UIUtils.createButton(properties)
    local button = UIUtils.createUIElement("TextButton", {
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 14,
        Font = Enum.Font.Gotham,
        AutoButtonColor = true
    })
    
    -- Apply custom properties
    if properties then
        for property, value in pairs(properties) do
            button[property] = value
        end
    end
    
    return button
end

-- Create a frame with common properties
function UIUtils.createFrame(properties)
    local frame = UIUtils.createUIElement("Frame", {
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0
    })
    
    -- Apply custom properties
    if properties then
        for property, value in pairs(properties) do
            frame[property] = value
        end
    end
    
    return frame
end

-- Apply an animation to a UI element
function UIUtils.animate(element, animationName, callback)
    local animation = ANIMATIONS[animationName]
    if not animation then
        warn("Animation not found:", animationName)
        return nil
    end
    
    local tween = TweenService:Create(element, animation.info, animation.properties)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

-- Create a custom tween
function UIUtils.createTween(element, properties, tweenInfo, callback)
    tweenInfo = tweenInfo or DEFAULT_TWEEN_INFO
    
    local tween = TweenService:Create(element, tweenInfo, properties)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

-- Create a hover effect for a button
function UIUtils.createHoverEffect(button)
    local originalColor = button.BackgroundColor3
    local hoverColor = Color3.fromRGB(
        math.min(originalColor.R * 255 + 20, 255),
        math.min(originalColor.G * 255 + 20, 255),
        math.min(originalColor.B * 255 + 20, 255)
    )
    
    button.MouseEnter:Connect(function()
        UIUtils.createTween(button, {BackgroundColor3 = hoverColor})
    end)
    
    button.MouseLeave:Connect(function()
        UIUtils.createTween(button, {BackgroundColor3 = originalColor})
    end)
end

-- Create a click effect for a button
function UIUtils.createClickEffect(button)
    local originalSize = button.Size
    local clickSize = UDim2.new(
        originalSize.X.Scale * 0.95,
        originalSize.X.Offset * 0.95,
        originalSize.Y.Scale * 0.95,
        originalSize.Y.Offset * 0.95
    )
    
    button.MouseButton1Down:Connect(function()
        UIUtils.createTween(button, {Size = clickSize})
    end)
    
    button.MouseButton1Up:Connect(function()
        UIUtils.createTween(button, {Size = originalSize})
    end)
end

-- Create a loading spinner
function UIUtils.createLoadingSpinner(parent, size)
    local spinner = UIUtils.createFrame({
        Name = "LoadingSpinner",
        Size = size or UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0.5, -20, 0.5, -20),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local circle = UIUtils.createUIElement("ImageLabel", {
        Name = "Circle",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://123456789", -- Replace with your spinner image
        Parent = spinner
    })
    
    -- Create rotation animation
    local rotation = 0
    game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
        rotation = (rotation + deltaTime * 360) % 360
        circle.Rotation = rotation
    end)
    
    return spinner
end

-- Create a tooltip
function UIUtils.createTooltip(parent, text)
    local tooltip = UIUtils.createFrame({
        Name = "Tooltip",
        Size = UDim2.new(0, 200, 0, 40),
        Position = UDim2.new(0, 0, 1, 5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Visible = false,
        Parent = parent
    })
    
    local label = UIUtils.createTextLabel({
        Name = "Text",
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        Text = text,
        Parent = tooltip
    })
    
    -- Show/hide on hover
    parent.MouseEnter:Connect(function()
        tooltip.Visible = true
        UIUtils.animate(tooltip, "FADE_IN")
    end)
    
    parent.MouseLeave:Connect(function()
        UIUtils.animate(tooltip, "FADE_OUT", function()
            tooltip.Visible = false
        end)
    end)
    
    return tooltip
end

-- Create a gradient background
function UIUtils.createGradient(parent, properties)
    local frame = UIUtils.createFrame(properties)
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, UIUtils.Colors.Background),
        ColorSequenceKeypoint.new(1, UIUtils.Colors.BackgroundDark)
    })
    gradient.Rotation = properties.Rotation or 45
    gradient.Parent = frame
    
    return frame, gradient
end

-- Create a separator line
function UIUtils.createSeparator(parent, properties)
    local separator = UIUtils.createFrame(properties)
    
    return separator
end

-- Create a container for buttons
function UIUtils.createButtonContainer(parent, properties)
    local container = UIUtils.createFrame(properties)
    
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
    local container = UIUtils.createFrame(properties)
    
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
    local container = UIUtils.createFrame(properties)
    
    local label = UIUtils.createTextLabel({
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = properties.Text or "Toggle",
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local toggle = UIUtils.createFrame({
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = UIUtils.Colors.Secondary,
        CornerRadius = 10
    })
    
    local handle = UIUtils.createFrame({
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
    local container = UIUtils.createFrame(properties)
    
    local label = UIUtils.createTextLabel({
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = properties.Text or "Slider",
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local track = UIUtils.createFrame({
        Size = UDim2.new(0, 200, 0, 4),
        Position = UDim2.new(1, -210, 0.5, -2),
        BackgroundColor3 = UIUtils.Colors.Secondary,
        CornerRadius = 2
    })
    
    local fill = UIUtils.createFrame({
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = UIUtils.Colors.Primary,
        CornerRadius = 2
    })
    
    local handle = UIUtils.createFrame({
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