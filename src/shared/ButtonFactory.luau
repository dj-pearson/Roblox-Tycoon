--!strict
--[[
    ButtonFactory.luau
    
    Factory module for creating consistent buttons throughout the UI system.
    Provides utility functions for common button types with standard styling and behaviors.
    
    Features:
    - Consistent styling for all buttons
    - Built-in hover and press effects
    - Presets for common button types
    - Customizable appearance and behavior
    - Accessibility features
    
    Author: Updated April 26, 2025
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        warn("Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find paths to important folders
local srcFolder = ReplicatedStorage:FindFirstChild("src") 
if not srcFolder then
    warn("Source folder not found")
end

local sharedFolder = srcFolder and srcFolder:FindFirstChild("shared")
if not sharedFolder then
    warn("Shared folder not found")
end

-- Try to require UIStyle
local UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))

-- Fallback styles if UIStyle module not found
if not UIStyle then
    warn("UIStyle module not found, using fallback styles")
    UIStyle = {
        Colors = {
            Primary = Color3.fromRGB(0, 120, 215),
            Secondary = Color3.fromRGB(45, 45, 45),
            Background = Color3.fromRGB(30, 30, 30),
            Text = Color3.fromRGB(255, 255, 255),
            TextDisabled = Color3.fromRGB(150, 150, 150),
            Success = Color3.fromRGB(46, 204, 113),
            Warning = Color3.fromRGB(230, 126, 34),
            Error = Color3.fromRGB(231, 76, 60)
        },
        Fonts = {
            Regular = Enum.Font.Gotham,
            Bold = Enum.Font.GothamBold,
            Light = Enum.Font.GothamMedium
        },
        Animations = {
            Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        }
    }
end

-- Module table
local ButtonFactory = {}

-- Button configuration defaults
local DEFAULT_CONFIG = {
    buttonHeight = 40,
    cornerRadius = 8,
    primaryColor = UIStyle.Colors.Primary,
    secondaryColor = UIStyle.Colors.Secondary,
    textColor = UIStyle.Colors.Text,
    disabledColor = Color3.fromRGB(100, 100, 100),
    disabledTextColor = UIStyle.Colors.TextDisabled,
    font = UIStyle.Fonts.Regular,
    fontSize = 16,
    padding = 10,
    hoverBrightnessChange = 0.1,
    pressBrightnessChange = 0.2,
    animationInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
}

-- Helper function to adjust color brightness
local function adjustBrightness(color, amount)
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + amount, 0, 1))
end

-- Add hover and press effects to a button
local function addButtonEffects(button, properties, isDisabled)
    if isDisabled then
        return
    end
    
    local normalColor = button.BackgroundColor3
    local hoverColor = adjustBrightness(normalColor, DEFAULT_CONFIG.hoverBrightnessChange)
    local pressColor = adjustBrightness(normalColor, -DEFAULT_CONFIG.pressBrightnessChange)
    
    -- Create tweens for state changes
    local hoverTween = TweenService:Create(
        button, 
        DEFAULT_CONFIG.animationInfo, 
        {BackgroundColor3 = hoverColor}
    )
    
    local normalTween = TweenService:Create(
        button, 
        DEFAULT_CONFIG.animationInfo, 
        {BackgroundColor3 = normalColor}
    )
    
    local pressTween = TweenService:Create(
        button, 
        DEFAULT_CONFIG.animationInfo, 
        {BackgroundColor3 = pressColor}
    )
    
    -- Connect events
    button.MouseEnter:Connect(function()
        if button.Selectable then
            hoverTween:Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        if button.Selectable then
            normalTween:Play()
        end
    end)
    
    button.MouseButton1Down:Connect(function()
        if button.Selectable then
            pressTween:Play()
        end
    end)
    
    button.MouseButton1Up:Connect(function()
        if button.Selectable then
            if button.IsHovered and button:IsA("GuiObject") then
                hoverTween:Play()
            else
                normalTween:Play()
            end
        end
    end)
    
    -- Connect callback if provided
    if properties.callback then
        button.Activated:Connect(properties.callback)
    end
end

-- Create a basic button
function ButtonFactory:createButton(properties)
    properties = properties or {}
    
    local button = Instance.new("TextButton")
    button.Size = properties.size or UDim2.new(0, 200, 0, DEFAULT_CONFIG.buttonHeight)
    button.Position = properties.position or UDim2.new(0, 0, 0, 0)
    button.AnchorPoint = properties.anchorPoint or Vector2.new(0, 0)
    button.BackgroundColor3 = properties.backgroundColor or DEFAULT_CONFIG.primaryColor
    button.BorderSizePixel = 0
    button.TextColor3 = properties.textColor or DEFAULT_CONFIG.textColor
    button.Font = properties.font or DEFAULT_CONFIG.font
    button.TextSize = properties.textSize or DEFAULT_CONFIG.fontSize
    button.AutoButtonColor = false
    button.Text = properties.text or "Button"
    button.Name = properties.name or "Button"
    button.ZIndex = properties.zIndex or 1
    button.Selectable = not properties.disabled
    
    -- Apply disabled appearance if needed
    if properties.disabled then
        button.BackgroundColor3 = DEFAULT_CONFIG.disabledColor
        button.TextColor3 = DEFAULT_CONFIG.disabledTextColor
    end
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, properties.cornerRadius or DEFAULT_CONFIG.cornerRadius)
    corner.Parent = button
    
    -- Add padding if needed
    if properties.padding then
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, properties.padding)
        padding.PaddingRight = UDim.new(0, properties.padding)
        padding.Parent = button
    end
    
    -- Add button effects (hover, press)
    addButtonEffects(button, properties, properties.disabled)
    
    -- Set parent
    if properties.parent then
        button.Parent = properties.parent
    end
    
    return button
end

-- Create a primary action button (highlighted, important actions)
function ButtonFactory:createPrimaryButton(properties)
    properties = properties or {}
    properties.backgroundColor = properties.backgroundColor or DEFAULT_CONFIG.primaryColor
    properties.font = properties.font or UIStyle.Fonts.Bold
    
    return self:createButton(properties)
end

-- Create a secondary action button (less important actions)
function ButtonFactory:createSecondaryButton(properties)
    properties = properties or {}
    properties.backgroundColor = properties.backgroundColor or DEFAULT_CONFIG.secondaryColor
    
    return self:createButton(properties)
end

-- Create a danger button (destructive actions)
function ButtonFactory:createDangerButton(properties)
    properties = properties or {}
    properties.backgroundColor = properties.backgroundColor or UIStyle.Colors.Error
    
    return self:createButton(properties)
end

-- Create a success button (confirmations, completions)
function ButtonFactory:createSuccessButton(properties)
    properties = properties or {}
    properties.backgroundColor = properties.backgroundColor or UIStyle.Colors.Success
    
    return self:createButton(properties)
end

-- Create an icon button (square button with an icon)
function ButtonFactory:createIconButton(properties)
    properties = properties or {}
    local size = properties.size or UDim2.new(0, DEFAULT_CONFIG.buttonHeight, 0, DEFAULT_CONFIG.buttonHeight)
    properties.size = size
    
    local button = self:createButton(properties)
    button.Text = ""
    
    -- Create icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = properties.icon or "🔍"
    icon.TextColor3 = properties.textColor or DEFAULT_CONFIG.textColor
    icon.Font = properties.iconFont or UIStyle.Fonts.Regular
    icon.TextSize = properties.iconSize or (size.Y.Offset * 0.6)
    icon.Parent = button
    
    -- Apply disabled appearance if needed
    if properties.disabled then
        icon.TextColor3 = DEFAULT_CONFIG.disabledTextColor
    end
    
    return button
end

-- Create a toggle button (on/off state)
function ButtonFactory:createToggleButton(properties)
    properties = properties or {}
    
    -- Create container frame
    local container = Instance.new("Frame")
    container.Size = properties.size or UDim2.new(0, 200, 0, DEFAULT_CONFIG.buttonHeight)
    container.Position = properties.position or UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.Name = properties.name or "ToggleButton"
    
    -- Initial state
    local isOn = properties.initialState or false
    
    -- Create toggle background
    local toggleBg = Instance.new("Frame")
    toggleBg.Name = "ToggleBackground"
    toggleBg.Size = UDim2.new(0, 50, 0, 26)
    toggleBg.Position = UDim2.new(0, 0, 0.5, -13)
    toggleBg.BackgroundColor3 = isOn and DEFAULT_CONFIG.primaryColor or DEFAULT_CONFIG.secondaryColor
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = container
    
    -- Add corner radius to toggle background
    local cornerBg = Instance.new("UICorner")
    cornerBg.CornerRadius = UDim.new(0, 13)
    cornerBg.Parent = toggleBg
    
    -- Create toggle indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 20, 0, 20)
    indicator.Position = UDim2.new(isOn and 1 or 0, isOn and -23 or 3, 0.5, -10)
    indicator.BackgroundColor3 = DEFAULT_CONFIG.textColor
    indicator.BorderSizePixel = 0
    indicator.Parent = toggleBg
    
    -- Add corner radius to indicator
    local cornerIndicator = Instance.new("UICorner")
    cornerIndicator.CornerRadius = UDim.new(0, 10)
    cornerIndicator.Parent = indicator
    
    -- Add label if provided
    if properties.text then
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 60, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = properties.text
        label.TextColor3 = properties.textColor or DEFAULT_CONFIG.textColor
        label.Font = properties.font or DEFAULT_CONFIG.font
        label.TextSize = properties.textSize or DEFAULT_CONFIG.fontSize
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = container
    end
    
    -- Create click detector
    local button = Instance.new("TextButton")
    button.Name = "ToggleButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = container
    
    -- Toggle functionality
    button.Activated:Connect(function()
        if properties.disabled then
            return
        end
        
        isOn = not isOn
        
        -- Animate state change
        TweenService:Create(
            toggleBg, 
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = isOn and DEFAULT_CONFIG.primaryColor or DEFAULT_CONFIG.secondaryColor }
        ):Play()
        
        TweenService:Create(
            indicator,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = UDim2.new(isOn and 1 or 0, isOn and -23 or 3, 0.5, -10) }
        ):Play()
        
        -- Call callback if provided
        if properties.callback then
            properties.callback(isOn)
        end
    end)
    
    -- Apply disabled appearance if needed
    if properties.disabled then
        toggleBg.BackgroundColor3 = DEFAULT_CONFIG.disabledColor
        indicator.BackgroundColor3 = DEFAULT_CONFIG.disabledTextColor
        if container:FindFirstChild("Label") then
            container.Label.TextColor3 = DEFAULT_CONFIG.disabledTextColor
        end
    end
    
    -- Set parent
    if properties.parent then
        container.Parent = properties.parent
    end
    
    -- Add functions to control the toggle
    container.setOn = function(on)
        if isOn ~= on then
            button.Activated:Fire() -- Trigger the toggle
        end
    end
    
    container.isOn = function()
        return isOn
    end
    
    return container
end

-- Create a pill-shaped button
function ButtonFactory:createPillButton(properties)
    properties = properties or {}
    properties.cornerRadius = math.huge -- Effectively makes it pill-shaped
    
    return self:createButton(properties)
end

-- Create a text-only button (no background)
function ButtonFactory:createTextButton(properties)
    properties = properties or {}
    
    local button = self:createButton(properties)
    button.BackgroundTransparency = 1
    
    return button
end

-- Create a dropdown menu button
function ButtonFactory:createDropdownButton(properties)
    properties = properties or {}
    
    local container = Instance.new("Frame")
    container.Size = properties.size or UDim2.new(0, 200, 0, DEFAULT_CONFIG.buttonHeight)
    container.Position = properties.position or UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.Name = properties.name or "DropdownButton"
    
    -- Create the main button
    local mainButton = self:createButton({
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = properties.backgroundColor or DEFAULT_CONFIG.primaryColor,
        text = properties.text or "Dropdown",
        font = properties.font or DEFAULT_CONFIG.font,
        textSize = properties.textSize or DEFAULT_CONFIG.fontSize,
        disabled = properties.disabled,
        parent = container
    })
    
    -- Add dropdown arrow
    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -25, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = DEFAULT_CONFIG.textColor
    arrow.Font = DEFAULT_CONFIG.font
    arrow.TextSize = DEFAULT_CONFIG.fontSize
    arrow.Parent = mainButton
    
    -- Create dropdown container
    local dropdownContainer = Instance.new("Frame")
    dropdownContainer.Name = "DropdownContainer"
    dropdownContainer.Size = UDim2.new(1, 0, 0, 0)
    dropdownContainer.Position = UDim2.new(0, 0, 1, 0)
    dropdownContainer.BackgroundColor3 = DEFAULT_CONFIG.secondaryColor
    dropdownContainer.BorderSizePixel = 0
    dropdownContainer.Visible = false
    dropdownContainer.ZIndex = 10
    dropdownContainer.Parent = container
    
    -- Add corner radius to dropdown container
    local cornerDD = Instance.new("UICorner")
    cornerDD.CornerRadius = UDim.new(0, DEFAULT_CONFIG.cornerRadius)
    cornerDD.Parent = dropdownContainer
    
    -- Add list layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = dropdownContainer
    
    -- Dropdown state
    local isOpen = false
    local options = properties.options or {}
    local selectedOption = properties.defaultOption or options[1] or ""
    
    -- Update button text
    mainButton.Text = selectedOption
    
    -- Add options to dropdown
    for i, option in ipairs(options) do
        local optionButton = self:createButton({
            size = UDim2.new(1, 0, 0, DEFAULT_CONFIG.buttonHeight - 4),
            backgroundColor = DEFAULT_CONFIG.secondaryColor,
            text = option,
            font = properties.font or DEFAULT_CONFIG.font,
            textSize = (properties.textSize or DEFAULT_CONFIG.fontSize) - 2,
            cornerRadius = DEFAULT_CONFIG.cornerRadius - 2,
            parent = dropdownContainer,
            zIndex = 11
        })
        
        optionButton.LayoutOrder = i
        
        -- Option click behavior
        optionButton.Activated:Connect(function()
            selectedOption = option
            mainButton.Text = option
            
            -- Close dropdown
            isOpen = false
            dropdownContainer.Visible = false
            
            -- Rotate arrow back
            TweenService:Create(
                arrow,
                DEFAULT_CONFIG.animationInfo,
                { Rotation = 0 }
            ):Play()
            
            -- Call callback if provided
            if properties.callback then
                properties.callback(option)
            end
        end)
    end
    
    -- Toggle dropdown visibility
    mainButton.Activated:Connect(function()
        if properties.disabled then
            return
        end
        
        isOpen = not isOpen
        
        -- Animation for arrow rotation
        TweenService:Create(
            arrow,
            DEFAULT_CONFIG.animationInfo,
            { Rotation = isOpen and 180 or 0 }
        ):Play()
        
        -- Set dropdown container size and visibility
        if isOpen then
            dropdownContainer.Visible = true
            dropdownContainer.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
        else
            dropdownContainer.Visible = false
        end
    end)
    
    -- Click outside to close dropdown
    local closingConnection
    local function setupCloseCheck()
        if isOpen and not closingConnection then
            closingConnection = game:GetService("UserInputService").InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local dropdownAbsPos = dropdownContainer.AbsolutePosition
                    local dropdownAbsSize = dropdownContainer.AbsoluteSize
                    local buttonAbsPos = mainButton.AbsolutePosition
                    local buttonAbsSize = mainButton.AbsoluteSize
                    
                    local mousePos = input.Position
                    local mouseX, mouseY = mousePos.X, mousePos.Y
                    
                    -- Check if click is outside dropdown and button
                    local inDropdown = 
                        mouseX >= dropdownAbsPos.X and 
                        mouseX <= dropdownAbsPos.X + dropdownAbsSize.X and 
                        mouseY >= dropdownAbsPos.Y and 
                        mouseY <= dropdownAbsPos.Y + dropdownAbsSize.Y
                    
                    local inButton = 
                        mouseX >= buttonAbsPos.X and 
                        mouseX <= buttonAbsPos.X + buttonAbsSize.X and 
                        mouseY >= buttonAbsPos.Y and 
                        mouseY <= buttonAbsPos.Y + buttonAbsSize.Y
                    
                    if not inDropdown and not inButton then
                        isOpen = false
                        dropdownContainer.Visible = false
                        
                        -- Rotate arrow back
                        TweenService:Create(
                            arrow,
                            DEFAULT_CONFIG.animationInfo,
                            { Rotation = 0 }
                        ):Play()
                        
                        -- Disconnect the connection
                        if closingConnection then
                            closingConnection:Disconnect()
                            closingConnection = nil
                        end
                    end
                end
            end)
        end
    end
    
    -- Monitor dropdown open state
    container:GetPropertyChangedSignal("Parent"):Connect(function()
        if container.Parent and isOpen then
            setupCloseCheck()
        end
    end)
    
    dropdownContainer:GetPropertyChangedSignal("Visible"):Connect(function()
        if dropdownContainer.Visible then
            setupCloseCheck()
        elseif closingConnection then
            closingConnection:Disconnect()
            closingConnection = nil
        end
    end)
    
    -- Apply disabled appearance if needed
    if properties.disabled then
        arrow.TextColor3 = DEFAULT_CONFIG.disabledTextColor
    end
    
    -- Set parent
    if properties.parent then
        container.Parent = properties.parent
    end
    
    -- Add methods to control the dropdown
    container.select = function(option)
        for _, optionButton in ipairs(dropdownContainer:GetChildren()) do
            if optionButton:IsA("TextButton") and optionButton.Text == option then
                optionButton.Activated:Fire()
                return true
            end
        end
        return false
    end
    
    container.getSelected = function()
        return selectedOption
    end
    
    container.setOptions = function(newOptions)
        -- Clear existing options
        for _, child in ipairs(dropdownContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Add new options
        options = newOptions
        for i, option in ipairs(options) do
            local optionButton = ButtonFactory:createButton({
                size = UDim2.new(1, 0, 0, DEFAULT_CONFIG.buttonHeight - 4),
                backgroundColor = DEFAULT_CONFIG.secondaryColor,
                text = option,
                font = properties.font or DEFAULT_CONFIG.font,
                textSize = (properties.textSize or DEFAULT_CONFIG.fontSize) - 2,
                cornerRadius = DEFAULT_CONFIG.cornerRadius - 2,
                parent = dropdownContainer,
                zIndex = 11
            })
            
            optionButton.LayoutOrder = i
            
            -- Option click behavior
            optionButton.Activated:Connect(function()
                selectedOption = option
                mainButton.Text = option
                
                -- Close dropdown
                isOpen = false
                dropdownContainer.Visible = false
                
                -- Rotate arrow back
                TweenService:Create(
                    arrow,
                    DEFAULT_CONFIG.animationInfo,
                    { Rotation = 0 }
                ):Play()
                
                -- Call callback if provided
                if properties.callback then
                    properties.callback(option)
                end
            end)
        end
        
        -- Set selected option
        if #options > 0 then
            selectedOption = options[1]
            mainButton.Text = selectedOption
        else
            selectedOption = ""
            mainButton.Text = properties.text or "Dropdown"
        end
    end
    
    return container
end

-- Return the module
return ButtonFactory
