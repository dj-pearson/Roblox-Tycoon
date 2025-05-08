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
    Warning = Color3.fromRGB(241, 196, 15)
}

-- Common fonts
UIUtils.Fonts = {
    Title = Enum.Font.GothamBold,
    Body = Enum.Font.Gotham,
    Button = Enum.Font.GothamBold
}

-- Common text sizes
UIUtils.TextSizes = {
    Title = 36,
    Subtitle = 24,
    Body = 16,
    Small = 14
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
    button.TextSize = UIUtils.TextSizes.Subtitle
    button.AutoButtonColor = true
    
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
function UIUtils.setupButtonHover(button, baseColor)
    baseColor = baseColor or button.BackgroundColor3
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = baseColor:Lerp(Color3.new(1, 1, 1), 0.2)
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
        BackgroundTransparency = 1
    })
    
    -- Apply custom properties
    for property, value in pairs(properties) do
        container[property] = value
    end
    
    return container
end

return UIUtils 