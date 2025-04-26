--!strict
--[[
    ButtonFactory.luau
    
    A factory module for creating consistently styled buttons throughout the UI.
    Works with UIStyle to ensure a cohesive appearance.
    
    Created: April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Try to load UIStyle
local UIStyle
local success = pcall(function()
    UIStyle = require(ReplicatedStorage.shared.UIStyle)
end)

if not success or not UIStyle then
    -- Create a minimal UIStyle if not found
    UIStyle = {
        Colors = {
            Primary = Color3.fromRGB(0, 120, 215),
            Secondary = Color3.fromRGB(80, 150, 255),
            Accent = Color3.fromRGB(60, 120, 190),
            Background = Color3.fromRGB(40, 40, 60),
            BackgroundLight = Color3.fromRGB(60, 60, 80),
            BackgroundDark = Color3.fromRGB(30, 30, 45),
            Text = Color3.fromRGB(240, 240, 255),
            TextSecondary = Color3.fromRGB(180, 180, 200),
            ButtonDefault = Color3.fromRGB(60, 60, 80),
            ButtonHover = Color3.fromRGB(70, 70, 90),
            ButtonActive = Color3.fromRGB(50, 50, 70),
            Success = Color3.fromRGB(40, 180, 100),
            Warning = Color3.fromRGB(255, 190, 0),
            Danger = Color3.fromRGB(220, 50, 50)
        },
        Fonts = {
            Regular = Enum.Font.Gotham,
            Bold = Enum.Font.GothamBold,
            SemiBold = Enum.Font.GothamSemibold
        },
        TextSizes = {
            Small = 12,
            Medium = 16,
            Large = 20
        },
        Animations = {
            Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        }
    }
end

-- Try to load IconSet
local IconSet
success = pcall(function()
    IconSet = require(ReplicatedStorage.shared.IconSet)
end)

if not success or not IconSet then
    -- Create a minimal IconSet if not found
    IconSet = {
        Close = "rbxassetid://8093755787",
        Settings = "rbxassetid://8093754726",
        Info = "rbxassetid://8093754900",
        Warning = "rbxassetid://8093755364",
        Error = "rbxassetid://8093755611"
    }
end

local ButtonFactory = {}

-- Create a standard text button
function ButtonFactory:createTextButton(config)
    config = config or {}
    
    local button = Instance.new("TextButton")
    button.Name = config.name or "Button"
    button.Size = config.size or UDim2.new(0, 120, 0, 40)
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    button.BorderSizePixel = 0
    button.Text = config.text or "Button"
    button.Font = config.font or UIStyle.Fonts.Bold
    button.TextSize = config.textSize or UIStyle.TextSizes.Medium
    button.BackgroundColor3 = config.backgroundColor or UIStyle.Colors.ButtonDefault
    button.TextColor3 = config.textColor or UIStyle.Colors.Text
    button.AutoButtonColor = false
    button.ZIndex = config.zIndex or 10
    button.ClipsDescendants = true
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = config.cornerRadius or UDim.new(0, 8)
    corner.Parent = button
    
    -- Add text padding if needed
    if config.padding then
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, config.padding)
        padding.PaddingRight = UDim.new(0, config.padding)
        padding.PaddingTop = UDim.new(0, config.padding)
        padding.PaddingBottom = UDim.new(0, config.padding)
        padding.Parent = button
    end
    
    -- Apply style based on button type
    local baseColor = config.backgroundColor or UIStyle.Colors.ButtonDefault
    local hoverColor = config.hoverColor or baseColor:Lerp(Color3.new(1, 1, 1), 0.15)
    local pressColor = config.pressColor or baseColor:Lerp(Color3.new(0, 0, 0), 0.15)
    
    if config.style == "primary" then
        baseColor = config.backgroundColor or UIStyle.Colors.Primary
        hoverColor = config.hoverColor or baseColor:Lerp(Color3.new(1, 1, 1), 0.15)
        pressColor = config.pressColor or baseColor:Lerp(Color3.new(0, 0, 0), 0.15)
        button.BackgroundColor3 = baseColor
    elseif config.style == "danger" then
        baseColor = config.backgroundColor or UIStyle.Colors.Danger
        hoverColor = config.hoverColor or baseColor:Lerp(Color3.new(1, 1, 1), 0.15)
        pressColor = config.pressColor or baseColor:Lerp(Color3.new(0, 0, 0), 0.15)
        button.BackgroundColor3 = baseColor
    elseif config.style == "success" then
        baseColor = config.backgroundColor or UIStyle.Colors.Success
        hoverColor = config.hoverColor or baseColor:Lerp(Color3.new(1, 1, 1), 0.15)
        pressColor = config.pressColor or baseColor:Lerp(Color3.new(0, 0, 0), 0.15)
        button.BackgroundColor3 = baseColor
    end
    
    -- Add hover/press effects
    button.MouseEnter:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = hoverColor
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = baseColor
        }):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = pressColor
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = hoverColor
        }):Play()
    end)
    
    -- Add ripple effect
    if config.rippleEffect ~= false then
        button.MouseButton1Down:Connect(function(x, y)
            local ripple = Instance.new("Frame")
            ripple.Name = "Ripple"
            ripple.AnchorPoint = Vector2.new(0.5, 0.5)
            ripple.BackgroundColor3 = Color3.new(1, 1, 1)
            ripple.BackgroundTransparency = 0.7
            ripple.BorderSizePixel = 0
            ripple.Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y)
            ripple.Size = UDim2.new(0, 0, 0, 0)
            ripple.ZIndex = button.ZIndex + 1
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = ripple
            
            ripple.Parent = button
            
            local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
            
            TweenService:Create(ripple, TweenInfo.new(0.5), {
                Size = UDim2.new(0, maxSize, 0, maxSize),
                BackgroundTransparency = 1
            }):Play()
            
            game:GetService("Debris"):AddItem(ripple, 1)
        end)
    end
    
    -- Connect the callback if provided
    if config.callback and type(config.callback) == "function" then
        button.MouseButton1Click:Connect(config.callback)
    end
    
    -- Assign parent if provided
    if config.parent then
        button.Parent = config.parent
    end
    
    return button
end

-- Create an icon button
function ButtonFactory:createIconButton(config)
    config = config or {}
    
    local button = Instance.new("ImageButton")
    button.Name = config.name or "IconButton"
    button.Size = config.size or UDim2.new(0, 40, 0, 40)
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    button.BackgroundColor3 = config.backgroundColor or UIStyle.Colors.ButtonDefault
    button.BackgroundTransparency = config.backgroundTransparency or 0
    button.BorderSizePixel = 0
    button.Image = config.icon or IconSet.Settings
    button.ImageColor3 = config.iconColor or UIStyle.Colors.Text
    button.ImageTransparency = config.iconTransparency or 0
    button.ScaleType = Enum.ScaleType.Fit
    button.AutoButtonColor = false
    button.ZIndex = config.zIndex or 10
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = config.cornerRadius or UDim.new(0.5, 0)
    corner.Parent = button
    
    -- Apply style based on button type
    local baseColor = config.backgroundColor or UIStyle.Colors.ButtonDefault
    local hoverColor = config.hoverColor or baseColor:Lerp(Color3.new(1, 1, 1), 0.15)
    local pressColor = config.pressColor or baseColor:Lerp(Color3.new(0, 0, 0), 0.15)
    
    -- Add hover/press effects
    button.MouseEnter:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = hoverColor,
            ImageColor3 = config.iconHoverColor or button.ImageColor3
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = baseColor,
            ImageColor3 = config.iconColor or UIStyle.Colors.Text
        }):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = pressColor
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = hoverColor
        }):Play()
    end)
    
    -- Connect the callback if provided
    if config.callback and type(config.callback) == "function" then
        button.MouseButton1Click:Connect(config.callback)
    end
    
    -- Assign parent if provided
    if config.parent then
        button.Parent = config.parent
    end
    
    return button
end

-- Create a toggle button
function ButtonFactory:createToggleButton(config)
    config = config or {}
    
    local initialState = config.initialState or false
    
    local container = Instance.new("Frame")
    container.Name = config.name or "ToggleButton"
    container.Size = config.size or UDim2.new(0, 50, 0, 25)
    container.Position = config.position or UDim2.new(0, 0, 0, 0)
    container.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    container.BackgroundColor3 = initialState 
        and (config.activeColor or UIStyle.Colors.Success)
        or (config.inactiveColor or UIStyle.Colors.ButtonDefault)
    container.BorderSizePixel = 0
    container.ZIndex = config.zIndex or 10
    
    -- Add corner rounding for the container
    local cornerRadius = config.cornerRadius or UDim.new(1, 0)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = cornerRadius
    corner.Parent = container
    
    -- Create the toggle knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = initialState
        and UDim2.new(1, -22, 0.5, 0)
        or UDim2.new(0, 3, 0.5, 0)
    knob.Size = UDim2.new(0, 19, 0, 19)
    knob.BackgroundColor3 = config.knobColor or UIStyle.Colors.Text
    knob.BorderSizePixel = 0
    knob.ZIndex = container.ZIndex + 1
    knob.Parent = container
    
    -- Add corner rounding for the knob
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    -- Add a hitbox button for better interaction
    local hitbox = Instance.new("TextButton")
    hitbox.Name = "Hitbox"
    hitbox.Text = ""
    hitbox.BackgroundTransparency = 1
    hitbox.Size = UDim2.new(1, 0, 1, 0)
    hitbox.ZIndex = container.ZIndex + 2
    hitbox.Parent = container
    
    -- Keep track of the toggle state
    local isOn = initialState
    
    -- Handle toggle functionality
    local function updateVisuals()
        TweenService:Create(container, UIStyle.Animations.Fast, {
            BackgroundColor3 = isOn 
                and (config.activeColor or UIStyle.Colors.Success)
                or (config.inactiveColor or UIStyle.Colors.ButtonDefault)
        }):Play()
        
        TweenService:Create(knob, UIStyle.Animations.Fast, {
            Position = isOn
                and UDim2.new(1, -22, 0.5, 0)
                or UDim2.new(0, 3, 0.5, 0)
        }):Play()
    end
    
    hitbox.MouseButton1Click:Connect(function()
        isOn = not isOn
        updateVisuals()
        
        if config.callback and type(config.callback) == "function" then
            config.callback(isOn)
        end
    end)
    
    -- Add a function to set the state programmatically
    function container:setState(state)
        isOn = state
        updateVisuals()
    end
    
    function container:getState()
        return isOn
    end
    
    -- Add disable/enable functionality
    function container:setEnabled(enabled)
        hitbox.Active = enabled
        
        if enabled then
            container.BackgroundTransparency = 0
            knob.BackgroundTransparency = 0
        else
            container.BackgroundTransparency = 0.5
            knob.BackgroundTransparency = 0.5
        end
    end
    
    -- Assign parent if provided
    if config.parent then
        container.Parent = config.parent
    end
    
    return container
end

-- Create a close button
function ButtonFactory:createCloseButton(config)
    config = config or {}
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = config.name or "CloseButton"
    closeButton.Size = config.size or UDim2.new(0, 30, 0, 30)
    closeButton.Position = config.position or UDim2.new(1, -10, 0, 10)
    closeButton.AnchorPoint = config.anchorPoint or Vector2.new(1, 0)
    closeButton.BackgroundColor3 = config.backgroundColor or UIStyle.Colors.Danger
    closeButton.TextColor3 = config.textColor or UIStyle.Colors.Text
    closeButton.Font = config.font or UIStyle.Fonts.Bold
    closeButton.TextSize = config.textSize or 18
    closeButton.Text = config.text or "X"
    closeButton.BorderSizePixel = 0
    closeButton.ZIndex = config.zIndex or 100
    closeButton.AutoButtonColor = false
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = closeButton
    
    -- Add hover/press effects
    local baseColor = config.backgroundColor or UIStyle.Colors.Danger
    local hoverColor = config.hoverColor or baseColor:Lerp(Color3.new(1, 1, 1), 0.15)
    local pressColor = config.pressColor or baseColor:Lerp(Color3.new(0, 0, 0), 0.15)
    
    closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, UIStyle.Animations.Fast, {
            BackgroundColor3 = hoverColor
        }):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, UIStyle.Animations.Fast, {
            BackgroundColor3 = baseColor
        }):Play()
    end)
    
    closeButton.MouseButton1Down:Connect(function()
        TweenService:Create(closeButton, UIStyle.Animations.Fast, {
            BackgroundColor3 = pressColor
        }):Play()
    end)
    
    closeButton.MouseButton1Up:Connect(function()
        TweenService:Create(closeButton, UIStyle.Animations.Fast, {
            BackgroundColor3 = hoverColor
        }):Play()
    end)
    
    -- Connect the callback if provided
    if config.callback and type(config.callback) == "function" then
        closeButton.MouseButton1Click:Connect(config.callback)
    end
    
    -- Assign parent if provided
    if config.parent then
        closeButton.Parent = config.parent
    end
    
    return closeButton
end

return ButtonFactory
