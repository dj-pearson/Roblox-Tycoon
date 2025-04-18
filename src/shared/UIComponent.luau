-- UIComponent.luau
-- Base class for all UI components
-- Part of UI refinements initiative (April 2025)

local TweenService = game:GetService("TweenService")
local UIStyle = require(script.Parent.UIStyle)

local UIComponent = {}
UIComponent.__index = UIComponent

-- Create a new UI component instance
function UIComponent.new(props)
    local self = setmetatable({}, UIComponent)
    
    -- Default properties
    self.props = props or {}
    self.name = self.props.name or "UIComponent"
    self.visible = self.props.visible ~= nil and self.props.visible or false
    self.parent = self.props.parent
    self.children = {}
    self.events = {}
    self.tweens = {}
    self.destroyed = false
    self.initialized = false
    
    -- Create the root container for this component
    self.container = Instance.new("Frame")
    self.container.Name = self.name
    self.container.Size = self.props.size or UDim2.new(1, 0, 1, 0)
    self.container.Position = self.props.position or UDim2.new(0, 0, 0, 0)
    self.container.AnchorPoint = self.props.anchorPoint or Vector2.new(0, 0)
    self.container.BackgroundTransparency = 1
    self.container.BorderSizePixel = 0
    self.container.Visible = self.visible
    self.container.ZIndex = self.props.zIndex or 1
    
    -- Set the parent if provided
    if self.parent then
        self.container.Parent = self.parent
    end
    
    return self
end

-- Initialize the component
function UIComponent:init()
    if self.initialized then
        return self
    end
    
    -- Call the build method which will be implemented by subclasses
    self:build()
    
    -- Call lifecycle hook
    if self.onInit then
        self:onInit()
    end
    
    self.initialized = true
    return self
end

-- Abstract method to be overridden by subclasses
function UIComponent:build()
    -- This should be implemented by subclasses to create their UI structure
    warn("UIComponent:build() method not implemented for " .. self.name)
end

-- Set the component's visibility
function UIComponent:setVisible(visible, animate)
    if self.visible == visible then
        return self
    end
    
    self.visible = visible
    
    if animate then
        -- Cancel any existing visibility tween
        if self.tweens.visibility then
            self.tweens.visibility:Cancel()
        end
        
        -- Create and store new tween
        self.container.Visible = true
        self.tweens.visibility = TweenService:Create(
            self.container,
            UIStyle.animations.normal,
            {BackgroundTransparency = visible and 0 or 1}
        )
        
        -- Connect completion callback
        self.tweens.visibility.Completed:Connect(function()
            if not visible then
                self.container.Visible = false
            end
        end)
        
        self.tweens.visibility:Play()
    else
        self.container.Visible = visible
    end
    
    -- Call lifecycle hook
    if visible and self.onShow then
        self:onShow()
    elseif not visible and self.onHide then
        self:onHide()
    end
    
    return self
end

-- Show the component
function UIComponent:show(animate)
    return self:setVisible(true, animate)
end

-- Hide the component
function UIComponent:hide(animate)
    return self:setVisible(false, animate)
end

-- Add a child component
function UIComponent:addChild(child, containerName)
    if not child then
        warn("Attempted to add nil child to " .. self.name)
        return self
    end
    
    -- Store the child reference
    table.insert(self.children, child)
    
    -- Set the parent container
    local parentContainer = self.container
    if containerName and parentContainer:FindFirstChild(containerName) then
        parentContainer = parentContainer[containerName]
    end
    
    child.container.Parent = parentContainer
    
    return self
end

-- Remove a child component
function UIComponent:removeChild(child)
    if not child then
        return self
    end
    
    -- Find and remove the child reference
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            break
        end
    end
    
    -- Remove from the hierarchy
    if child.container and child.container.Parent then
        child.container.Parent = nil
    end
    
    return self
end

-- Connect a function to an event
function UIComponent:connect(event, callback)
    if not self.events[event] then
        self.events[event] = {}
    end
    
    table.insert(self.events[event], callback)
    return self
end

-- Trigger an event
function UIComponent:trigger(event, ...)
    if not self.events[event] then
        return self
    end
    
    for _, callback in ipairs(self.events[event]) do
        callback(...)
    end
    
    return self
end

-- Set the component's position
function UIComponent:setPosition(position, animate)
    if animate then
        -- Cancel any existing position tween
        if self.tweens.position then
            self.tweens.position:Cancel()
        end
        
        -- Create and store new tween
        self.tweens.position = TweenService:Create(
            self.container,
            UIStyle.animations.normal,
            {Position = position}
        )
        
        self.tweens.position:Play()
    else
        self.container.Position = position
    end
    
    return self
end

-- Set the component's size
function UIComponent:setSize(size, animate)
    if animate then
        -- Cancel any existing size tween
        if self.tweens.size then
            self.tweens.size:Cancel()
        end
        
        -- Create and store new tween
        self.tweens.size = TweenService:Create(
            self.container,
            UIStyle.animations.normal,
            {Size = size}
        )
        
        self.tweens.size:Play()
    else
        self.container.Size = size
    end
    
    return self
end

-- Update component properties
function UIComponent:updateProps(newProps)
    if not newProps then
        return self
    end
    
    -- Merge the new props into the existing props
    for key, value in pairs(newProps) do
        self.props[key] = value
    end
    
    -- Call lifecycle hook
    if self.onPropsUpdate then
        self:onPropsUpdate(newProps)
    end
    
    return self
end

-- Find a child instance by name
function UIComponent:findChild(name)
    return self.container:FindFirstChild(name, true)
end

-- Clean up resources before destruction
function UIComponent:cleanup()
    -- Cancel all active tweens
    for _, tween in pairs(self.tweens) do
        if tween.PlaybackState ~= Enum.PlaybackState.Completed then
            tween:Cancel()
        end
    end
    
    -- Clear event connections
    self.events = {}
    
    -- Cleanup all children
    for _, child in ipairs(self.children) do
        if typeof(child) == "table" and child.destroy then
            child:destroy()
        end
    end
    
    self.children = {}
    
    -- Call lifecycle hook
    if self.onCleanup then
        self:onCleanup()
    end
    
    return self
end

-- Destroy the component and release resources
function UIComponent:destroy()
    if self.destroyed then
        return
    end
    
    -- Call cleanup to handle resources
    self:cleanup()
    
    -- Call lifecycle hook
    if self.onDestroy then
        self:onDestroy()
    end
    
    -- Remove the container
    if self.container then
        self.container:Destroy()
        self.container = nil
    end
    
    self.destroyed = true
end

-- Lifecycle methods that can be overridden by subclasses
function UIComponent:onInit() end
function UIComponent:onShow() end
function UIComponent:onHide() end
function UIComponent:onPropsUpdate(newProps) end
function UIComponent:onCleanup() end
function UIComponent:onDestroy() end

return UIComponent