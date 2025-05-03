--!strict
--[[
    ButtonComponent.luau
    
    A reusable button component for the enhanced UI system.
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Import ModuleLoaderHelper
local ModuleLoaderHelper = nil
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
    else
        warn("[ButtonComponent] Failed to load ModuleLoaderHelper, using direct requires")
    end
end

-- Load UIComponentBase
local UIComponentBase
if ModuleLoaderHelper then
    UIComponentBase = ModuleLoaderHelper.loadModule("UI/UIComponentBase")
else
    local componentBasePath = ReplicatedStorage:FindFirstChild("shared") and 
                             ReplicatedStorage.shared:FindFirstChild("UI") and 
                             ReplicatedStorage.shared.UI:FindFirstChild("UIComponentBase")
    
    if componentBasePath then
        UIComponentBase = require(componentBasePath)
    end
end

if not UIComponentBase then
    error("[ButtonComponent] Required dependency UIComponentBase not found")
end

-- Load UIStyleSystem
local UIStyleSystem
if ModuleLoaderHelper then
    UIStyleSystem = ModuleLoaderHelper.loadModule("UI/UIStyleSystem")
else
    local styleSystemPath = ReplicatedStorage:FindFirstChild("shared") and 
                           ReplicatedStorage.shared:FindFirstChild("UI") and 
                           ReplicatedStorage.shared.UI:FindFirstChild("UIStyleSystem")
    
    if styleSystemPath then
        UIStyleSystem = require(styleSystemPath)
    end
end

--[[
    ButtonComponent - A standard button component
]]
local ButtonComponent = setmetatable({}, UIComponentBase)
ButtonComponent.__index = ButtonComponent

--[[
    Create a new button component
    @param props - Button properties
    @return - New ButtonComponent instance
]]
function ButtonComponent.new(props)
    props = props or {}
    
    local self = UIComponentBase.new(props)
    setmetatable(self, ButtonComponent)
    
    -- Button-specific properties
    self._type = "ButtonComponent"
    self._text = props.text or "Button"
    self._icon = props.icon
    self._style = props.style or "default" -- default, primary, secondary, danger, success
    self._size = props.size or "medium" -- small, medium, large
    self._cornerRadius = props.cornerRadius
    self._hoverEffect = props.hoverEffect ~= false -- Enable by default
    self._pressEffect = props.pressEffect ~= false -- Enable by default
    self._tooltip = props.tooltip
    
    -- Button state
    self._isHovered = false
    self._isPressed = false
    
    -- Get style from UIStyleSystem if available
    if UIStyleSystem then
        self._buttonStyle = UIStyleSystem:createStyle("Button", props.themeOverrides)
    end
    
    return self
end

--[[
    Internal render method - creates the button instance
    @return - The created button instance
]]
function ButtonComponent:_render()
    local button = Instance.new("TextButton")
    button.Name = self._name
    button.Size = self._size or UDim2.new(0, 200, 0, 50)
    button.Position = self._position or UDim2.new(0.5, 0, 0.5, 0)
    button.AnchorPoint = self._anchorPoint or Vector2.new(0.5, 0.5)
    button.Text = self._text
    button.AutoButtonColor = false -- We'll handle hover/press effects manually
    button.ClipsDescendants = true -- For ripple effect
    
    -- Apply style
    self:_applyButtonStyle(button)
    
    -- Create icon if provided
    if self._icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.BackgroundTransparency = 1
        icon.Image = self._icon
        icon.Position = UDim2.new(0, 10, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Parent = button
        
        -- Adjust text position when there's an icon
        button.TextXAlignment = Enum.TextXAlignment.Center
        
        -- Store reference to the icon
        self._iconInstance = icon
    end
    
    -- Add corner radius
    if self._cornerRadius or (self._buttonStyle and self._buttonStyle:getCorner("medium")) then
        local radius = self._cornerRadius
        if not radius and self._buttonStyle then
            radius = self._buttonStyle:getCorner("medium")
        end
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 8)
        corner.Parent = button
    end
    
    -- Connect mouse events for hover and press effects
    if self._hoverEffect then
        button.MouseEnter:Connect(function()
            self:_onHoverStart()
        end)
        
        button.MouseLeave:Connect(function()
            self:_onHoverEnd()
        end)
    end
    
    if self._pressEffect then
        button.MouseButton1Down:Connect(function()
            self:_onPressStart()
        end)
        
        button.MouseButton1Up:Connect(function()
            self:_onPressEnd()
        end)
    end
    
    -- Connect click handler
    button.MouseButton1Click:Connect(function()
        self:_onClick()
    end)
    
    -- Add tooltip if provided
    if self._tooltip then
        -- Implementation depends on tooltip system
        -- This is a placeholder for future tooltip integration
    end
    
    return button
end

--[[
    Apply style to the button
    @param button - Button instance to style
]]
function ButtonComponent:_applyButtonStyle(button)
    if self._buttonStyle then
        -- Use UIStyleSystem styling
        local colors = {
            background = self._buttonStyle:getColor("background"),
            text = self._buttonStyle:getColor("text"),
            backgroundHover = self._buttonStyle:getColor("backgroundHover"),
            backgroundPressed = self._buttonStyle:getColor("backgroundPressed")
        }
        
        local typography = self._buttonStyle:getTypography("button") or {}
        
        button.BackgroundColor3 = colors.background or Color3.fromRGB(48, 48, 200)
        button.TextColor3 = colors.text or Color3.fromRGB(255, 255, 255)
        button.Font = typography.font or Enum.Font.GothamBold
        button.TextSize = typography.size or 16
        button.BorderSizePixel = 0
        
        -- Store the style colors for hover/press effects
        self._backgroundNormal = colors.background
        self._backgroundHover = colors.backgroundHover
        self._backgroundPressed = colors.backgroundPressed
        
        -- Apply padding if available
        local padding = self._buttonStyle:getValue("padding")
        if padding then
            local uiPadding = Instance.new("UIPadding")
            
            if typeof(padding) == "number" then
                uiPadding.PaddingLeft = UDim.new(0, padding)
                uiPadding.PaddingRight = UDim.new(0, padding)
                uiPadding.PaddingTop = UDim.new(0, padding)
                uiPadding.PaddingBottom = UDim.new(0, padding)
            else
                uiPadding.PaddingLeft = UDim.new(0, padding.left or 16)
                uiPadding.PaddingRight = UDim.new(0, padding.right or 16)
                uiPadding.PaddingTop = UDim.new(0, padding.top or 8)
                uiPadding.PaddingBottom = UDim.new(0, padding.bottom or 8)
            end
            
            uiPadding.Parent = button
        end
    else
        -- Fallback styling when UIStyleSystem is not available
        local styleColors = {
            default = {
                background = Color3.fromRGB(60, 60, 80),
                text = Color3.fromRGB(255, 255, 255),
                hover = Color3.fromRGB(70, 70, 90),
                pressed = Color3.fromRGB(50, 50, 70)
            },
            primary = {
                background = Color3.fromRGB(48, 48, 200),
                text = Color3.fromRGB(255, 255, 255),
                hover = Color3.fromRGB(58, 58, 210),
                pressed = Color3.fromRGB(38, 38, 190)
            },
            secondary = {
                background = Color3.fromRGB(80, 80, 100),
                text = Color3.fromRGB(255, 255, 255),
                hover = Color3.fromRGB(90, 90, 110),
                pressed = Color3.fromRGB(70, 70, 90)
            },
            danger = {
                background = Color3.fromRGB(200, 48, 48),
                text = Color3.fromRGB(255, 255, 255),
                hover = Color3.fromRGB(210, 58, 58),
                pressed = Color3.fromRGB(190, 38, 38)
            },
            success = {
                background = Color3.fromRGB(48, 180, 80),
                text = Color3.fromRGB(255, 255, 255),
                hover = Color3.fromRGB(58, 190, 90),
                pressed = Color3.fromRGB(38, 170, 70)
            }
        }
        
        local style = styleColors[self._style] or styleColors.default
        
        button.BackgroundColor3 = style.background
        button.TextColor3 = style.text
        button.Font = Enum.Font.GothamBold
        button.TextSize = 16
        button.BorderSizePixel = 0
        
        -- Store the style colors for hover/press effects
        self._backgroundNormal = style.background
        self._backgroundHover = style.hover
        self._backgroundPressed = style.pressed
        
        -- Apply size-based adjustments
        if self._size == "small" then
            button.TextSize = 14
            
            -- Add appropriate padding
            local uiPadding = Instance.new("UIPadding")
            uiPadding.PaddingLeft = UDim.new(0, 12)
            uiPadding.PaddingRight = UDim.new(0, 12)
            uiPadding.PaddingTop = UDim.new(0, 6)
            uiPadding.PaddingBottom = UDim.new(0, 6)
            uiPadding.Parent = button
        elseif self._size == "large" then
            button.TextSize = 18
            
            -- Add appropriate padding
            local uiPadding = Instance.new("UIPadding")
            uiPadding.PaddingLeft = UDim.new(0, 20)
            uiPadding.PaddingRight = UDim.new(0, 20)
            uiPadding.PaddingTop = UDim.new(0, 10)
            uiPadding.PaddingBottom = UDim.new(0, 10)
            uiPadding.Parent = button
        else
            -- Medium (default) size
            -- Add appropriate padding
            local uiPadding = Instance.new("UIPadding")
            uiPadding.PaddingLeft = UDim.new(0, 16)
            uiPadding.PaddingRight = UDim.new(0, 16)
            uiPadding.PaddingTop = UDim.new(0, 8)
            uiPadding.PaddingBottom = UDim.new(0, 8)
            uiPadding.Parent = button
        end
    end
end

--[[
    Set button text
    @param text - New button text
    @return - Self for method chaining
]]
function ButtonComponent:setText(text)
    self._text = text
    
    if self._instance then
        self._instance.Text = text
    end
    
    return self
end

--[[
    Set button icon
    @param icon - New button icon (asset ID)
    @return - Self for method chaining
]]
function ButtonComponent:setIcon(icon)
    self._icon = icon
    
    if self._instance and self._iconInstance then
        self._iconInstance.Image = icon
    elseif self._instance and icon then
        -- Create icon if it doesn't exist
        local iconInstance = Instance.new("ImageLabel")
        iconInstance.Name = "Icon"
        iconInstance.Size = UDim2.new(0, 20, 0, 20)
        iconInstance.BackgroundTransparency = 1
        iconInstance.Image = icon
        iconInstance.Position = UDim2.new(0, 10, 0.5, 0)
        iconInstance.AnchorPoint = Vector2.new(0, 0.5)
        iconInstance.Parent = self._instance
        
        -- Adjust text position
        self._instance.TextXAlignment = Enum.TextXAlignment.Center
        
        self._iconInstance = iconInstance
    elseif self._instance and self._iconInstance and not icon then
        -- Remove icon if nil is passed
        self._iconInstance:Destroy()
        self._iconInstance = nil
        
        -- Reset text alignment
        self._instance.TextXAlignment = Enum.TextXAlignment.Center
    end
    
    return self
end

--[[
    Set button style
    @param style - Button style (default, primary, secondary, danger, success)
    @return - Self for method chaining
]]
function ButtonComponent:setStyle(style)
    self._style = style
    
    if self._instance then
        self:_applyButtonStyle(self._instance)
    end
    
    return self
end

--[[
    Set button size
    @param size - Button size (small, medium, large)
    @return - Self for method chaining
]]
function ButtonComponent:setSize(size)
    self._size = size
    
    if self._instance then
        self:_applyButtonStyle(self._instance)
    end
    
    return self
end

--[[
    Internal handler for hover start
]]
function ButtonComponent:_onHoverStart()
    self._isHovered = true
    
    if self._instance and not self._isPressed and self._backgroundHover then
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(self._instance, tweenInfo, {
            BackgroundColor3 = self._backgroundHover
        })
        tween:Play()
    end
    
    -- Trigger hover event
    self:triggerEvent("onHover", true)
end

--[[
    Internal handler for hover end
]]
function ButtonComponent:_onHoverEnd()
    self._isHovered = false
    
    if self._instance and not self._isPressed and self._backgroundNormal then
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(self._instance, tweenInfo, {
            BackgroundColor3 = self._backgroundNormal
        })
        tween:Play()
    end
    
    -- Trigger hover event
    self:triggerEvent("onHover", false)
end

--[[
    Internal handler for press start
]]
function ButtonComponent:_onPressStart()
    self._isPressed = true
    
    if self._instance and self._backgroundPressed then
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(self._instance, tweenInfo, {
            BackgroundColor3 = self._backgroundPressed
        })
        tween:Play()
        
        -- Create ripple effect
        self:_createRippleEffect()
    end
    
    -- Trigger press event
    self:triggerEvent("onPress", true)
end

--[[
    Internal handler for press end
]]
function ButtonComponent:_onPressEnd()
    self._isPressed = false
    
    if self._instance then
        local targetColor = self._isHovered and self._backgroundHover or self._backgroundNormal
        
        if targetColor then
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(self._instance, tweenInfo, {
                BackgroundColor3 = targetColor
            })
            tween:Play()
        end
    end
    
    -- Trigger press event
    self:triggerEvent("onPress", false)
end

--[[
    Internal handler for click
]]
function ButtonComponent:_onClick()
    -- Trigger click event
    self:triggerEvent("onClick")
end

--[[
    Create a ripple effect on the button
]]
function ButtonComponent:_createRippleEffect()
    if not self._instance then
        return
    end
    
    -- Get input position (center of button if not available)
    local inputPosition = self._instance.AbsolutePosition + self._instance.AbsoluteSize / 2
    
    -- Create ripple circle
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.7
    ripple.BorderSizePixel = 0
    
    -- Calculate position based on input
    local relativePos = inputPosition - self._instance.AbsolutePosition
    
    -- Start at click position
    ripple.Position = UDim2.new(0, relativePos.X, 0, relativePos.Y)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Start small
    ripple.Size = UDim2.new(0, 0, 0, 0)
    
    -- Add corner to make it circular
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = ripple
    
    -- Add to button
    ripple.Parent = self._instance
    
    -- Animate growth
    local buttonSize = math.max(self._instance.AbsoluteSize.X, self._instance.AbsoluteSize.Y) * 1.5
    local targetSize = UDim2.new(0, buttonSize, 0, buttonSize)
    
    local growInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local growTween = TweenService:Create(ripple, growInfo, {
        Size = targetSize,
        BackgroundTransparency = 1
    })
    
    growTween:Play()
    
    -- Clean up when animation completes
    growTween.Completed:Connect(function()
        ripple:Destroy()
    end)
end

--[[
    Register an onClick handler
    @param handler - Function to call when button is clicked
    @return - Connection ID
]]
function ButtonComponent:onClick(handler)
    return self:on("onClick", handler)
end

--[[
    Register an onHover handler
    @param handler - Function to call when hover state changes
    @return - Connection ID
]]
function ButtonComponent:onHover(handler)
    return self:on("onHover", handler)
end

--[[
    Register an onPress handler
    @param handler - Function to call when press state changes
    @return - Connection ID
]]
function ButtonComponent:onPress(handler)
    return self:on("onPress", handler)
end

return ButtonComponent
