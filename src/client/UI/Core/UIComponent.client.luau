--!strict
--[[
    UIComponent.client.luau
    
    Base class for all UI components.
    Provides common functionality and interface for UI components.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Types = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Types"))
local Constants = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Constants"))

type UIComponentProps = Types.UIComponentProps
type UIState = Types.UIState
type UIAnimation = Types.UIAnimation
type UIEvent = Types.UIEvent
type UIComponent = Types.UIComponent

local UIComponent = {}
UIComponent.__index = UIComponent

-- Constructor
function UIComponent.new(name: string, props: UIComponentProps): UIComponent
    local self = setmetatable({}, UIComponent)
    
    self.name = name
    self.props = props
    self.state = {
        visible = props.visible or false,
        enabled = props.enabled or true,
        focused = false,
        hovered = false,
        pressed = false,
        selected = false,
        loading = false,
        error = nil,
    }
    
    -- Create the base instance
    self.instance = self:createInstance()
    
    -- Apply initial props
    self:update(props)
    
    return self
end

-- Create the base instance
function UIComponent:createInstance(): Instance
    local frame = Instance.new("Frame")
    frame.Name = self.name
    
    -- Apply default styles
    frame.BackgroundColor3 = Constants.STYLES.BACKGROUND_COLOR
    frame.BorderSizePixel = Constants.STYLES.BORDER_SIZE
    frame.BorderColor3 = Constants.STYLES.ACCENT_COLOR
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Constants.STYLES.CORNER_RADIUS)
    corner.Parent = frame
    
    return frame
end

-- Show the component
function UIComponent:show(animation: UIAnimation?)
    if self.state.visible then return end
    
    if animation then
        self:animate(animation, true)
    else
        self.instance.Visible = true
        self.state.visible = true
    end
end

-- Hide the component
function UIComponent:hide(animation: UIAnimation?)
    if not self.state.visible then return end
    
    if animation then
        self:animate(animation, false)
    else
        self.instance.Visible = false
        self.state.visible = false
    end
end

-- Update component props
function UIComponent:update(props: UIComponentProps)
    self.props = props
    
    -- Update instance properties
    if props.position then
        self.instance.Position = props.position
    end
    
    if props.size then
        self.instance.Size = props.size
    end
    
    if props.anchorPoint then
        self.instance.AnchorPoint = props.anchorPoint
    end
    
    if props.backgroundColor3 then
        self.instance.BackgroundColor3 = props.backgroundColor3
    end
    
    if props.backgroundTransparency then
        self.instance.BackgroundTransparency = props.backgroundTransparency
    end
    
    if props.borderSizePixel then
        self.instance.BorderSizePixel = props.borderSizePixel
    end
    
    if props.borderColor3 then
        self.instance.BorderColor3 = props.borderColor3
    end
    
    if props.zIndex then
        self.instance.ZIndex = props.zIndex
    end
    
    if props.layoutOrder then
        self.instance.LayoutOrder = props.layoutOrder
    end
    
    if props.autoSize then
        self.instance.AutomaticSize = props.autoSize
    end
    
    -- Update parent if changed
    if props.parent and props.parent ~= self.instance.Parent then
        self.instance.Parent = props.parent
    end
end

-- Animate the component
function UIComponent:animate(animation: UIAnimation, show: boolean)
    local tweenInfo = TweenInfo.new(
        animation.duration,
        animation.easing,
        animation.direction
    )
    
    local properties = {}
    
    if animation.type == Constants.ANIMATIONS.FADE then
        properties.BackgroundTransparency = show and 0 or 1
    elseif animation.type == Constants.ANIMATIONS.SLIDE then
        -- Implement slide animation
    elseif animation.type == Constants.ANIMATIONS.SCALE then
        -- Implement scale animation
    elseif animation.type == Constants.ANIMATIONS.ROTATE then
        -- Implement rotate animation
    end
    
    local tween = TweenService:Create(self.instance, tweenInfo, properties)
    tween:Play()
    
    -- Update state after animation
    task.delay(animation.duration, function()
        self.state.visible = show
        self.instance.Visible = show
    end)
end

-- Handle events
function UIComponent:onEvent(event: UIEvent)
    -- Base implementation - override in child classes
end

-- Destroy the component
function UIComponent:destroy()
    if self.instance then
        self.instance:Destroy()
    end
end

return UIComponent 