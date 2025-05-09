--!strict
--[[
    ButtonFactory.luau
    
    Factory for creating buttons with consistent styling.
    This is part of the UI components system.
    
    Created: April 27, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to load UIStyle and IconSet
local UIStyle, IconSet

local function loadDependencies()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then
        -- Load UIStyle
        local uiStyleModule = shared:FindFirstChild("UIStyle")
        if uiStyleModule then
            local success, result = pcall(function()
                return require(uiStyleModule)
            end)
            if success then
                UIStyle = result
            end
        end
        
        -- Load IconSet
        local iconSetModule = shared:FindFirstChild("IconSet")
        if iconSetModule then
            local success, result = pcall(function()
                return require(iconSetModule)
            end)
            if success then
                IconSet = result
            end
        end
    end
    
    -- Set defaults if not loaded
    if not UIStyle then
        print("UIStyle module not found, using defaults")
        UIStyle = {
            colors = {
                accent = Color3.fromRGB(80, 150, 255),
                accentLight = Color3.fromRGB(130, 180, 255),
                accentDark = Color3.fromRGB(60, 120, 200),
                text = Color3.fromRGB(240, 240, 255),
                backgroundLight = Color3.fromRGB(60, 60, 80),
                success = Color3.fromRGB(80, 240, 120),
                warning = Color3.fromRGB(255, 200, 80),
                error = Color3.fromRGB(255, 80, 80)
            },
            fonts = {
                button = Enum.Font.GothamMedium
            },
            fontSizes = {
                button = 16
            },
            borderRadius = {
                medium = UDim.new(0, 8)
            },
            animation = {
                durationShort = 0.2,
                easeOut = Enum.EasingStyle.Quad,
                dirOut = Enum.EasingDirection.Out
            }
        }
    end
end

-- Load dependencies on require
loadDependencies()

-- The ButtonFactory module
local ButtonFactory = {}

-- Utility function to create UI corner
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or (UIStyle.borderRadius and UIStyle.borderRadius.medium) or UDim.new(0, 8)
    corner.Parent = parent
    return corner
end

-- Default hover effect for buttons
local function applyHoverEffect(button, options)
    options = options or {}
    
    if not button then return end
    
    local defaultColor = button.BackgroundColor3
    local hoverColor
    
    if options.hoverColor then
        hoverColor = options.hoverColor
    else
        -- Make hover color slightly lighter
        hoverColor = Color3.new(
            math.min(defaultColor.R + 0.1, 1),
            math.min(defaultColor.G + 0.1, 1),
            math.min(defaultColor.B + 0.1, 1)
        )
    end
    
    local function onHover()
        -- Animate to hover color
        button:TweenBackgroundColor3(
            hoverColor,
            UIStyle.animation and UIStyle.animation.dirOut or Enum.EasingDirection.Out,
            UIStyle.animation and UIStyle.animation.easeOut or Enum.EasingStyle.Quad,
            UIStyle.animation and UIStyle.animation.durationShort or 0.2
        )
    end
    
    local function onHoverEnd()
        -- Animate back to default color
        button:TweenBackgroundColor3(
            defaultColor,
            UIStyle.animation and UIStyle.animation.dirOut or Enum.EasingDirection.Out,
            UIStyle.animation and UIStyle.animation.easeOut or Enum.EasingStyle.Quad,
            UIStyle.animation and UIStyle.animation.durationShort or 0.2
        )
    end
    
    button.MouseEnter:Connect(onHover)
    button.MouseLeave:Connect(onHoverEnd)
end

-- Create a simple button
function ButtonFactory:createButton(options)
    options = options or {}
    
    -- Create the button
    local button = Instance.new("TextButton")
    button.Name = options.name or "Button"
    button.Size = options.size or UDim2.new(0, 200, 0, 40)
    button.Position = options.position or UDim2.new(0.5, -100, 0.5, -20)
    button.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    button.BackgroundColor3 = options.color or (UIStyle.colors and UIStyle.colors.accent) or Color3.fromRGB(80, 150, 255)
    button.TextColor3 = options.textColor or (UIStyle.colors and UIStyle.colors.text) or Color3.fromRGB(240, 240, 255)
    button.Font = options.font or (UIStyle.fonts and UIStyle.fonts.button) or Enum.Font.GothamMedium
    button.TextSize = options.textSize or (UIStyle.fontSizes and UIStyle.fontSizes.button) or 16
    button.Text = options.text or "Button"
    button.BorderSizePixel = 0
    button.AutoButtonColor = false -- We'll handle hover effects ourselves
    
    -- Add corner radius
    createCorner(button, options.cornerRadius)
    
    -- Add hover effect
    applyHoverEffect(button, {
        hoverColor = options.hoverColor
    })
    
    -- Add shadow if not disabled
    if options.shadow ~= false then
        local shadow = Instance.new("Frame")
        shadow.Name = "Shadow"
        shadow.AnchorPoint = Vector2.new(0.5, 0.5)
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.6
        shadow.BorderSizePixel = 0
        shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
        shadow.Size = UDim2.new(1, 4, 1, 4)
        shadow.ZIndex = button.ZIndex - 1
        
        createCorner(shadow, options.cornerRadius)
        shadow.Parent = button
    end
    
    -- Add icon if specified
    if options.icon and IconSet then
        local iconPosition = options.iconPosition or "left"
        local padding = options.iconPadding or 5
        
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = options.iconSize or UDim2.new(0, 20, 0, 20)
        icon.BackgroundTransparency = 1
        icon.Image = IconSet[options.icon] or options.icon
        icon.ImageColor3 = options.iconColor or button.TextColor3
        
        -- Position based on iconPosition
        if iconPosition == "left" then
            icon.Position = UDim2.new(0, padding, 0.5, -10)
            button.TextXAlignment = Enum.TextXAlignment.Center
        elseif iconPosition == "right" then
            icon.Position = UDim2.new(1, -(20 + padding), 0.5, -10)
            button.TextXAlignment = Enum.TextXAlignment.Center
        elseif iconPosition == "top" then
            icon.Position = UDim2.new(0.5, -10, 0, padding)
            button.TextXAlignment = Enum.TextXAlignment.Center
            button.TextYAlignment = Enum.TextYAlignment.Bottom
        elseif iconPosition == "bottom" then
            icon.Position = UDim2.new(0.5, -10, 1, -(20 + padding))
            button.TextXAlignment = Enum.TextXAlignment.Center
            button.TextYAlignment = Enum.TextYAlignment.Top
        end
        
        icon.Parent = button
    end
    
    -- Connect callback if provided
    if options.callback and typeof(options.callback) == "function" then
        button.MouseButton1Click:Connect(options.callback)
    end
    
    -- Add button to parent if specified
    if options.parent then
        button.Parent = options.parent
    end
    
    return button
end

-- Create an icon button (just icon, no text)
function ButtonFactory:createIconButton(options)
    options = options or {}
    local size = options.size or 40
    
    local newOptions = {
        name = options.name or "IconButton",
        size = UDim2.new(0, size, 0, size),
        position = options.position,
        anchorPoint = options.anchorPoint,
        color = options.color or (UIStyle.colors and UIStyle.colors.backgroundLight) or Color3.fromRGB(60, 60, 80),
        icon = options.icon or "fallback",
        iconSize = UDim2.new(0, size * 0.6, 0, size * 0.6),
        iconPosition = "center", -- Custom position handled below
        iconColor = options.iconColor or (UIStyle.colors and UIStyle.colors.text) or Color3.fromRGB(240, 240, 255),
        text = "",
        callback = options.callback,
        parent = options.parent,
        cornerRadius = options.cornerRadius or UDim.new(0, size / 4),
        shadow = options.shadow
    }
    
    local button = self:createButton(newOptions)
    
    -- Adjust the icon position to be centered
    local icon = button:FindFirstChild("Icon")
    if icon then
        icon.Position = UDim2.new(0.5, -icon.Size.X.Offset / 2, 0.5, -icon.Size.Y.Offset / 2)
    end
    
    return button
end

-- Create a primary action button
function ButtonFactory:createPrimaryButton(options)
    options = options or {}
    options.color = options.color or (UIStyle.colors and UIStyle.colors.accent) or Color3.fromRGB(80, 150, 255)
    options.textColor = options.textColor or (UIStyle.colors and UIStyle.colors.text) or Color3.fromRGB(240, 240, 255)
    options.name = options.name or "PrimaryButton"
    
    return self:createButton(options)
end

-- Create a secondary action button
function ButtonFactory:createSecondaryButton(options)
    options = options or {}
    options.color = options.color or (UIStyle.colors and UIStyle.colors.backgroundLight) or Color3.fromRGB(60, 60, 80)
    options.textColor = options.textColor or (UIStyle.colors and UIStyle.colors.text) or Color3.fromRGB(240, 240, 255)
    options.name = options.name or "SecondaryButton"
    
    return self:createButton(options)
end

-- Create a danger/destructive action button
function ButtonFactory:createDangerButton(options)
    options = options or {}
    options.color = options.color or (UIStyle.colors and UIStyle.colors.error) or Color3.fromRGB(255, 80, 80)
    options.textColor = options.textColor or (UIStyle.colors and UIStyle.colors.text) or Color3.fromRGB(240, 240, 255)
    options.name = options.name or "DangerButton"
    
    return self:createButton(options)
end

-- Create a success action button
function ButtonFactory:createSuccessButton(options)
    options = options or {}
    options.color = options.color or (UIStyle.colors and UIStyle.colors.success) or Color3.fromRGB(80, 240, 120)
    options.textColor = options.textColor or (UIStyle.colors and UIStyle.colors.text) or Color3.fromRGB(240, 240, 255)
    options.name = options.name or "SuccessButton"
    
    return self:createButton(options)
end

-- Create a warning action button
function ButtonFactory:createWarningButton(options)
    options = options or {}
    options.color = options.color or (UIStyle.colors and UIStyle.colors.warning) or Color3.fromRGB(255, 200, 80)
    options.textColor = options.textColor or (UIStyle.colors and UIStyle.colors.text) or Color3.fromRGB(240, 240, 255)
    options.name = options.name or "WarningButton"
    
    return self:createButton(options)
end

-- Register with ClientRegistry if available
local function registerWithClientRegistry()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then return end
    
    local clientRegistryModule = shared:FindFirstChild("ClientRegistry")
    if not clientRegistryModule then return end
    
    local success, clientRegistry = pcall(function()
        return require(clientRegistryModule)
    end)
    
    if success and clientRegistry and typeof(clientRegistry.registerUIComponent) == "function" then
        clientRegistry:registerUIComponent("ButtonFactory", ButtonFactory)
        print("ButtonFactory registered with ClientRegistry")
    end
end

-- Try to register with ClientRegistry
task.spawn(registerWithClientRegistry)

return ButtonFactory
