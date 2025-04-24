--[[
    UIStyle.luau
    
    A centralized module for UI styling constants and helper functions.
    This ensures consistent appearance across all UI elements in the game.
    
    Author: Updated April 2025
]]

local TweenService = game:GetService("TweenService")

local UIStyle = {}

-- Color palette
UIStyle.Colors = {
    -- Primary branding colors
    Primary = Color3.fromRGB(0, 120, 215),  -- Main brand color
    Secondary = Color3.fromRGB(80, 150, 255), -- Secondary brand color
    Accent = Color3.fromRGB(60, 120, 190),   -- Accent color for highlights
    
    -- Background colors
    Background = Color3.fromRGB(40, 40, 60),      -- Main background
    BackgroundLight = Color3.fromRGB(60, 60, 80), -- Lighter background for contrast
    BackgroundDark = Color3.fromRGB(30, 30, 45),  -- Darker background for contrast
    
    -- Text colors
    Text = Color3.fromRGB(240, 240, 255),       -- Primary text
    TextSecondary = Color3.fromRGB(180, 180, 200), -- Secondary text
    TextDisabled = Color3.fromRGB(120, 120, 140), -- Disabled text
    
    -- Button colors
    ButtonDefault = Color3.fromRGB(60, 60, 80),  -- Default button
    ButtonHover = Color3.fromRGB(70, 70, 90),    -- Button on hover
    ButtonActive = Color3.fromRGB(50, 50, 70),   -- Button when active/pressed
    ButtonDisabled = Color3.fromRGB(50, 50, 60), -- Disabled button
    
    -- Semantic colors
    Success = Color3.fromRGB(40, 180, 100),  -- Success/completion
    Warning = Color3.fromRGB(255, 190, 0),   -- Warning/caution
    Danger = Color3.fromRGB(220, 50, 50),    -- Error/danger
    Info = Color3.fromRGB(80, 170, 240),     -- Information
    
    -- Specialized UI colors
    HeaderBackground = Color3.fromRGB(35, 35, 55),
    CardBackground = Color3.fromRGB(50, 50, 70),
    TabActive = Color3.fromRGB(60, 100, 170),
    TabInactive = Color3.fromRGB(50, 50, 70)
}

-- Font styles
UIStyle.Fonts = {
    Regular = Enum.Font.Gotham,
    Bold = Enum.Font.GothamBold,
    SemiBold = Enum.Font.GothamSemibold,
    Title = Enum.Font.GothamBlack,
    Subtitle = Enum.Font.GothamMedium,
    Mono = Enum.Font.RobotoMono
}

-- Text sizes
UIStyle.TextSizes = {
    Small = 12,
    Medium = 16,
    Large = 20,
    Title = 24,
    Header = 22,
    Subheader = 18
}

-- Animation settings
UIStyle.Animations = {
    Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    SpringIn = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    FadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
}

-- UI element sizes
UIStyle.Sizes = {
    CornerRadius = UDim.new(0, 8),
    ButtonHeight = UDim2.new(0, 40),
    HeaderHeight = UDim2.new(0, 50),
    TabHeight = UDim2.new(0, 40),
    IconSize = UDim2.new(0, 24, 0, 24),
    Padding = {
        Small = 4,
        Medium = 8,
        Large = 16
    },
    Sidebar = {
        Expanded = UDim2.new(0, 250, 1, 0),
        Collapsed = UDim2.new(0, 60, 1, 0)
    }
}

-- Z-index values
UIStyle.ZIndex = {
    Background = 1,
    Content = 10,
    Foreground = 50,
    Overlay = 100,
    Topmost = 200
}

-- Shadow properties
UIStyle.Shadow = {
    SliceCenter = Rect.new(10, 10, 10, 10)
}

-- Standardized styling function for UI elements
function UIStyle.applyStyle(element, styleType)
    if not element then return end
    
    styleType = styleType or "default"
    
    if styleType == "button" then
        element.BackgroundColor3 = UIStyle.Colors.ButtonDefault
        element.BorderSizePixel = 0
        
        -- Add corner rounding
        local corner = element:FindFirstChild("UICorner") or Instance.new("UICorner")
        corner.CornerRadius = UIStyle.Sizes.CornerRadius
        corner.Parent = element
        
        -- Add hover/press effects if applicable
        if element:IsA("GuiButton") then
            element.AutoButtonColor = false
            
            element.MouseEnter:Connect(function()
                TweenService:Create(element, UIStyle.Animations.Fast, {
                    BackgroundColor3 = UIStyle.Colors.ButtonHover
                }):Play()
            end)
            
            element.MouseLeave:Connect(function()
                TweenService:Create(element, UIStyle.Animations.Fast, {
                    BackgroundColor3 = UIStyle.Colors.ButtonDefault
                }):Play()
            end)
            
            element.MouseButton1Down:Connect(function()
                TweenService:Create(element, UIStyle.Animations.Fast, {
                    BackgroundColor3 = UIStyle.Colors.ButtonActive
                }):Play()
            end)
            
            element.MouseButton1Up:Connect(function()
                TweenService:Create(element, UIStyle.Animations.Fast, {
                    BackgroundColor3 = UIStyle.Colors.ButtonHover
                }):Play()
            end)
        end
    elseif styleType == "frame" then
        element.BackgroundColor3 = UIStyle.Colors.Background
        element.BorderSizePixel = 0
        
        -- Add corner rounding
        local corner = element:FindFirstChild("UICorner") or Instance.new("UICorner")
        corner.CornerRadius = UIStyle.Sizes.CornerRadius
        corner.Parent = element
    elseif styleType == "header" then
        element.BackgroundColor3 = UIStyle.Colors.HeaderBackground
        element.BorderSizePixel = 0
        
        if element:IsA("TextLabel") or element:IsA("TextButton") then
            element.Font = UIStyle.Fonts.Bold
            element.TextColor3 = UIStyle.Colors.Text
            element.TextSize = UIStyle.TextSizes.Header
        end
    elseif styleType == "input" then
        element.BackgroundColor3 = UIStyle.Colors.BackgroundDark
        element.BorderSizePixel = 0
        
        if element:IsA("TextBox") then
            element.Font = UIStyle.Fonts.Regular
            element.TextColor3 = UIStyle.Colors.Text
            element.PlaceholderColor3 = UIStyle.Colors.TextSecondary
            element.TextSize = UIStyle.TextSizes.Medium
            element.ClearTextOnFocus = false
            
            -- Add corner rounding
            local corner = element:FindFirstChild("UICorner") or Instance.new("UICorner")
            corner.CornerRadius = UIStyle.Sizes.CornerRadius
            corner.Parent = element
        end
    end
end

-- Create a styled button with consistent appearance
function UIStyle.createStyledButton(text, size, position, callback, style)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.new(0, 120, 0, 40)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BorderSizePixel = 0
    button.Text = text or "Button"
    button.Font = UIStyle.Fonts.Bold
    button.TextSize = UIStyle.TextSizes.Medium
    
    -- Apply style
    if style == "primary" then
        button.BackgroundColor3 = UIStyle.Colors.Primary
        button.TextColor3 = UIStyle.Colors.Text
    elseif style == "danger" then
        button.BackgroundColor3 = UIStyle.Colors.Danger
        button.TextColor3 = UIStyle.Colors.Text
    elseif style == "success" then
        button.BackgroundColor3 = UIStyle.Colors.Success
        button.TextColor3 = UIStyle.Colors.Text
    else -- Default/secondary
        button.BackgroundColor3 = UIStyle.Colors.ButtonDefault
        button.TextColor3 = UIStyle.Colors.Text
    end
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIStyle.Sizes.CornerRadius
    corner.Parent = button
    
    -- Add hover/press effects
    button.AutoButtonColor = false
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.15)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = style == "primary" and UIStyle.Colors.Primary 
                or style == "danger" and UIStyle.Colors.Danger
                or style == "success" and UIStyle.Colors.Success
                or UIStyle.Colors.ButtonDefault
        }):Play()
    end)
    
    -- Connect callback if provided
    if callback and typeof(callback) == "function" then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

-- Create a standard close button following the design standard
function UIStyle.createCloseButton(size, position)
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = size or UDim2.new(0, 30, 0, 30)
    closeButton.Position = position or UDim2.new(1, -10, 0, 10)
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.BackgroundColor3 = UIStyle.Colors.Danger
    closeButton.TextColor3 = UIStyle.Colors.Text
    closeButton.Font = UIStyle.Fonts.Bold
    closeButton.TextSize = 18
    closeButton.Text = "X"
    closeButton.ZIndex = UIStyle.ZIndex.Foreground
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = closeButton
    
    -- Add hover effect
    closeButton.AutoButtonColor = false
    
    closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, UIStyle.Animations.Fast, {
            BackgroundColor3 = UIStyle.Colors.Danger:Lerp(Color3.new(1, 1, 1), 0.15)
        }):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, UIStyle.Animations.Fast, {
            BackgroundColor3 = UIStyle.Colors.Danger
        }):Play()
    end)
    
    return closeButton
end

return UIStyle