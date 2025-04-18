-- UIStyle.luau
-- Defines standardized UI styles for all components
-- Part of UI refinements initiative (April 2025)

local TweenService = game:GetService("TweenService")

local UIStyle = {}

-- Color palette
UIStyle.colors = {
    -- Primary colors
    primary = Color3.fromRGB(0, 132, 255),       -- Main brand color
    primaryLight = Color3.fromRGB(77, 169, 255), -- Lighter variant
    primaryDark = Color3.fromRGB(0, 95, 184),    -- Darker variant
    
    -- Secondary colors
    secondary = Color3.fromRGB(255, 184, 0),       -- Secondary brand color
    secondaryLight = Color3.fromRGB(255, 207, 77),  -- Lighter variant
    secondaryDark = Color3.fromRGB(204, 147, 0),    -- Darker variant
    
    -- Accent colors for various UI states
    success = Color3.fromRGB(46, 204, 113),
    warning = Color3.fromRGB(255, 184, 0),
    error = Color3.fromRGB(231, 76, 60),
    info = Color3.fromRGB(52, 152, 219),
    
    -- Background colors
    background = Color3.fromRGB(27, 27, 27),      -- Main background
    backgroundLight = Color3.fromRGB(45, 45, 45), -- Lighter background for cards/containers
    backgroundDark = Color3.fromRGB(18, 18, 18),  -- Darker background for contrast
    
    -- Text colors
    textPrimary = Color3.fromRGB(255, 255, 255),    -- Main text color
    textSecondary = Color3.fromRGB(180, 180, 180),  -- Secondary text color
    textDisabled = Color3.fromRGB(122, 122, 122),   -- Disabled text
    
    -- UI element colors
    border = Color3.fromRGB(58, 58, 58),
    divider = Color3.fromRGB(58, 58, 58),
    overlay = Color3.fromRGB(0, 0, 0),
    
    -- Button states
    buttonDefault = Color3.fromRGB(45, 45, 45),
    buttonHover = Color3.fromRGB(65, 65, 65),
    buttonPressed = Color3.fromRGB(35, 35, 35),
    buttonDisabled = Color3.fromRGB(40, 40, 40),
}

-- Font styles
UIStyle.fonts = {
    -- Title fonts
    titleLarge = {
        Font = Enum.Font.GothamBold,
        Size = 32,
    },
    titleMedium = {
        Font = Enum.Font.GothamBold,
        Size = 24,
    },
    titleSmall = {
        Font = Enum.Font.GothamBold,
        Size = 20,
    },
    
    -- Body text fonts
    bodyLarge = {
        Font = Enum.Font.Gotham,
        Size = 18,
    },
    bodyMedium = {
        Font = Enum.Font.Gotham,
        Size = 16,
    },
    bodySmall = {
        Font = Enum.Font.Gotham,
        Size = 14,
    },
    
    -- Label fonts
    label = {
        Font = Enum.Font.GothamMedium,
        Size = 14,
    },
    caption = {
        Font = Enum.Font.Gotham,
        Size = 12,
    },
    
    -- Button fonts
    button = {
        Font = Enum.Font.GothamBold,
        Size = 16,
    },
    
    -- Special text treatments
    numeric = {
        Font = Enum.Font.GothamSemibold,
        Size = 18,
    },
}

-- Animations and easing
UIStyle.animations = {
    -- Standard durations
    veryFast = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    fast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    normal = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    
    -- Specialized animations
    popup = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    popdown = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
    bounce = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    elastic = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    
    -- Spring animations
    spring = TweenInfo.new(0.7, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0),
    
    -- Repeating animations
    pulse = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
}

-- Common layout metrics
UIStyle.layout = {
    -- Padding and margins
    paddingTiny = UDim.new(0, 4),
    paddingSmall = UDim.new(0, 8),
    paddingMedium = UDim.new(0, 16),
    paddingLarge = UDim.new(0, 24),
    paddingExtraLarge = UDim.new(0, 36),
    
    -- Border sizes
    borderThin = 1,
    borderMedium = 2,
    borderThick = 3,
    
    -- Corner rounding
    cornerRadiusSmall = UDim.new(0, 4),
    cornerRadiusMedium = UDim.new(0, 8),
    cornerRadiusLarge = UDim.new(0, 12),
    
    -- Container sizes
    containerSmall = UDim2.new(0, 240, 0, 0),
    containerMedium = UDim2.new(0, 400, 0, 0),
    containerLarge = UDim2.new(0, 600, 0, 0),
    
    -- Button sizes
    buttonHeight = UDim.new(0, 40),
    buttonSmallHeight = UDim.new(0, 32),
    
    -- Icon sizes
    iconSmall = 16,
    iconMedium = 24,
    iconLarge = 32,
    
    -- Standard spacing between elements
    spacingTiny = UDim.new(0, 2),
    spacingSmall = UDim.new(0, 4),
    spacingMedium = UDim.new(0, 8),
    spacingLarge = UDim.new(0, 16),
    
    -- Status bar heights
    statusBarHeight = UDim.new(0, 32),
    
    -- Z-index layers
    zIndex = {
        background = 1,
        default = 10,
        overlay = 100,
        modal = 200,
        notification = 300,
        tooltip = 400,
    }
}

-- Helper function to apply standard styling to buttons
function UIStyle.applyButtonStyle(button, style)
    style = style or "default"
    
    -- Set default properties
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.BackgroundColor3 = UIStyle.colors.buttonDefault
    button.Size = UDim2.new(0, 200, UIStyle.layout.buttonHeight.Scale, UIStyle.layout.buttonHeight.Offset)
    
    -- Create corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    corner.Parent = button
    
    -- Create text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ButtonText"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = UIStyle.fonts.button.Font
    textLabel.TextSize = UIStyle.fonts.button.Size
    textLabel.TextColor3 = UIStyle.colors.textPrimary
    textLabel.Text = button.Name
    textLabel.Parent = button
    
    -- Apply specific styling based on button type
    if style == "primary" then
        button.BackgroundColor3 = UIStyle.colors.primary
    elseif style == "secondary" then
        button.BackgroundColor3 = UIStyle.colors.secondary
    elseif style == "success" then
        button.BackgroundColor3 = UIStyle.colors.success
    elseif style == "warning" then
        button.BackgroundColor3 = UIStyle.colors.warning
    elseif style == "danger" then
        button.BackgroundColor3 = UIStyle.colors.error
    elseif style == "outline" then
        button.BackgroundTransparency = 1
        button.BorderSizePixel = UIStyle.layout.borderMedium
        button.BorderColor3 = UIStyle.colors.primary
        textLabel.TextColor3 = UIStyle.colors.primary
    elseif style == "text" then
        button.BackgroundTransparency = 1
        textLabel.TextColor3 = UIStyle.colors.primary
    end
    
    -- Add hover and click effects
    local originalColor = button.BackgroundColor3
    local hoverColor = style == "default" and UIStyle.colors.buttonHover or 
                      originalColor:Lerp(Color3.new(1, 1, 1), 0.2)
    local pressedColor = style == "default" and UIStyle.colors.buttonPressed or 
                        originalColor:Lerp(Color3.new(0, 0, 0), 0.1)
    
    -- Setup hover and click animations
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, UIStyle.animations.fast, {BackgroundColor3 = hoverColor})
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, UIStyle.animations.fast, {BackgroundColor3 = originalColor})
        tween:Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        local tween = TweenService:Create(button, UIStyle.animations.veryFast, {BackgroundColor3 = pressedColor})
        tween:Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        local tween = TweenService:Create(button, UIStyle.animations.fast, {BackgroundColor3 = hoverColor})
        tween:Play()
    end)
    
    return button
end

-- Helper function to create a standard container
function UIStyle.createContainer(name, size, parent)
    local container = Instance.new("Frame")
    container.Name = name or "Container"
    container.Size = size or UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = UIStyle.colors.backgroundLight
    container.BorderSizePixel = 0
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    corner.Parent = container
    
    if parent then
        container.Parent = parent
    end
    
    return container
end

-- Helper function to create a standardized text label
function UIStyle.createText(props)
    local text = Instance.new("TextLabel")
    text.Name = props.name or "Text"
    text.Size = props.size or UDim2.new(1, 0, 0, 20)
    text.Position = props.position or UDim2.new(0, 0, 0, 0)
    text.BackgroundTransparency = 1
    
    -- Get font style based on text type
    local fontStyle = props.style and UIStyle.fonts[props.style] or UIStyle.fonts.bodyMedium
    text.Font = fontStyle.Font
    text.TextSize = fontStyle.Size
    
    -- Set text properties
    text.Text = props.text or ""
    text.TextColor3 = props.color or UIStyle.colors.textPrimary
    text.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
    text.TextYAlignment = props.yAlign or Enum.TextYAlignment.Center
    text.TextWrapped = props.wrapped ~= nil and props.wrapped or true
    text.RichText = props.rich ~= nil and props.rich or false
    
    if props.parent then
        text.Parent = props.parent
    end
    
    return text
end

return UIStyle