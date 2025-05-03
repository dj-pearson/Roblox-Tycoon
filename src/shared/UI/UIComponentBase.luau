--!strict
--[[
    UIComponentBase.luau
    
    Base class for all UI components in the enhanced UI system.
    Provides standardized lifecycle methods, property management, and event handling.
    
    Created: May 3, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Import ModuleLoaderHelper
local ModuleLoaderHelper = nil
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
    else
        warn("[UIComponentBase] Failed to load ModuleLoaderHelper, using direct requires")
    end
end

-- Load UIStyle
local UIStyle = nil
if ModuleLoaderHelper then
    UIStyle = ModuleLoaderHelper.loadModule("UIStyle")
else
    local uiStyleModule = ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("UIStyle")
    if uiStyleModule then
        UIStyle = require(uiStyleModule)
    end
end

if not UIStyle then
    warn("[UIComponentBase] Failed to load UIStyle module")
end

--[[ 
    UIComponentBase Class
    
    Base class for all UI components with standard lifecycle methods and property support.
]]
local UIComponentBase = {}
UIComponentBase.__index = UIComponentBase

-- Property change event handlers
local propertyChangedHandlers = {}

-- Component ID counter for unique identifiers
local componentIdCounter = 0

--[[
    Create a new UI component instance
    @param props - Table of initial properties for the component
    @return - New UIComponentBase instance
]]
function UIComponentBase.new(props)
    props = props or {}
    
    -- Generate a unique ID for this component
    componentIdCounter = componentIdCounter + 1
    
    local self = setmetatable({
        -- Core properties
        _id = componentIdCounter,
        _name = props.name or "UIComponent_" .. componentIdCounter,
        _type = "UIComponentBase",
        _initialized = false,
        _mounted = false,
        _visible = props.visible ~= false, -- Default to visible
        _enabled = props.enabled ~= false, -- Default to enabled
        
        -- Instance properties
        _instance = nil, -- The actual UI instance
        _parent = nil, -- Parent instance or component
        _children = {}, -- Child components
        
        -- Properties storage
        _props = props,
        _state = {},
        
        -- Events storage
        _events = {},
        _connections = {},
        
        -- Style information
        _style = props.style or {},
        
        -- Layout information
        _position = props.position,
        _size = props.size,
        _anchorPoint = props.anchorPoint,
        _layoutOrder = props.layoutOrder or 0,
        
        -- Debug flags
        _debugMode = props.debug or false
    }, UIComponentBase)
    
    -- Initialize event storage
    self._events.onPropertyChanged = {}
    self._events.onRender = {}
    self._events.onMount = {}
    self._events.onUnmount = {}
    self._events.onDestroy = {}
    
    return self
end

--[[
    Initialize the component - internal setup before rendering
    @return - Self for method chaining
]]
function UIComponentBase:init()
    if self._initialized then
        return self
    end
    
    -- Call internal initialization
    self:_init()
    
    -- Mark as initialized
    self._initialized = true
    
    return self
end

--[[
    Internal initialization - override in subclasses
]]
function UIComponentBase:_init()
    -- Default implementation does nothing
    -- Override in derived classes
end

--[[
    Render the component - create all UI instances
    @return - The rendered UI instance
]]
function UIComponentBase:render()
    if not self._initialized then
        self:init()
    end
    
    -- Allow subclasses to create their specific instance
    local instance = self:_render()
    self._instance = instance
    
    -- Apply common properties
    if instance then
        -- Apply basic properties
        if self._name then
            instance.Name = self._name
        end
        
        if self._position then
            instance.Position = self._position
        end
        
        if self._size then
            instance.Size = self._size
        end
        
        if self._anchorPoint and instance:IsA("GuiObject") then
            instance.AnchorPoint = self._anchorPoint
        end
        
        if self._layoutOrder and instance:IsA("GuiObject") then
            instance.LayoutOrder = self._layoutOrder
        end
        
        -- Set visibility
        if not self._visible and instance:IsA("GuiObject") then
            instance.Visible = false
        end
        
        -- Apply styles if UIStyle is available
        if UIStyle then
            self:applyStyle()
        end
    end
    
    -- Trigger render event
    self:triggerEvent("onRender")
    
    return instance
end

--[[
    Internal render method - override in subclasses
    @return - The created UI instance
]]
function UIComponentBase:_render()
    -- Default implementation creates a basic frame
    local frame = Instance.new("Frame")
    frame.Size = self._size or UDim2.new(0, 100, 0, 100)
    frame.BackgroundColor3 = (UIStyle and UIStyle.colors.background) or Color3.fromRGB(40, 40, 60)
    frame.BorderSizePixel = 0
    
    return frame
end

--[[
    Apply style to the component
    @param styleOverrides - Optional style overrides
    @return - Self for method chaining
]]
function UIComponentBase:applyStyle(styleOverrides)
    if not self._instance or not UIStyle then
        return self
    end
    
    local style = styleOverrides or self._style
    
    -- Allow subclasses to apply specific styling
    self:_applyStyle(style)
    
    return self
end

--[[
    Internal style application - override in subclasses
    @param style - Style properties to apply
]]
function UIComponentBase:_applyStyle(style)
    -- Default implementation applies background color if it's a GuiObject
    if self._instance:IsA("GuiObject") then
        self._instance.BackgroundColor3 = style.backgroundColor or UIStyle.colors.background
    end
end

--[[
    Mount the component to a parent
    @param parent - Parent instance or component
    @return - Self for method chaining
]]
function UIComponentBase:mount(parent)
    if not self._instance then
        self:render()
    end
    
    if not self._instance then
        warn("[UIComponentBase] Cannot mount component: no instance created")
        return self
    end
    
    local parentInstance = parent
    
    -- If parent is a component, get its instance
    if parent and typeof(parent) == "table" and parent._instance then
        parentInstance = parent._instance
        self._parent = parent
    else
        self._parent = parentInstance
    end
    
    -- Set the parent
    if parentInstance and self._instance then
        self._instance.Parent = parentInstance
        self._mounted = true
        
        -- Trigger mount event
        self:triggerEvent("onMount")
    end
    
    return self
end

--[[
    Unmount the component from its parent
    @return - Self for method chaining
]]
function UIComponentBase:unmount()
    if self._instance then
        self._instance.Parent = nil
        self._mounted = false
        
        -- Trigger unmount event
        self:triggerEvent("onUnmount")
    end
    
    return self
end

--[[
    Add a child component
    @param child - Child component to add
    @return - Self for method chaining
]]
function UIComponentBase:addChild(child)
    if not child then
        return self
    end
    
    -- Add to children collection
    table.insert(self._children, child)
    
    -- If we're already mounted, mount the child too
    if self._mounted and self._instance then
        child:mount(self._instance)
    end
    
    return self
end

--[[
    Remove a child component
    @param child - Child component to remove
    @return - Self for method chaining
]]
function UIComponentBase:removeChild(child)
    if not child then
        return self
    end
    
    -- Find and remove the child
    for i, c in ipairs(self._children) do
        if c == child then
            table.remove(self._children, i)
            child:unmount()
            break
        end
    end
    
    return self
end

--[[
    Set a property value
    @param name - Property name
    @param value - Property value
    @return - Self for method chaining
]]
function UIComponentBase:setProperty(name, value)
    local oldValue = self._props[name]
    self._props[name] = value
    
    -- Notify property change
    if oldValue ~= value then
        self:_handlePropertyChanged(name, value, oldValue)
    end
    
    return self
end

--[[
    Get a property value
    @param name - Property name
    @param defaultValue - Default value if property not found
    @return - Property value or defaultValue
]]
function UIComponentBase:getProperty(name, defaultValue)
    return self._props[name] or defaultValue
end

--[[
    Internal property change handler
    @param name - Property name
    @param newValue - New property value
    @param oldValue - Previous property value
]]
function UIComponentBase:_handlePropertyChanged(name, newValue, oldValue)
    -- Call specific handler if it exists
    local handler = propertyChangedHandlers[name]
    if handler then
        handler(self, newValue, oldValue)
    end
    
    -- Trigger property changed event
    self:triggerEvent("onPropertyChanged", name, newValue, oldValue)
    
    -- Handle special properties
    if name == "visible" then
        self:setVisible(newValue)
    elseif name == "enabled" then
        self:setEnabled(newValue)
    end
end

--[[
    Set component visibility
    @param visible - Visibility state
    @return - Self for method chaining
]]
function UIComponentBase:setVisible(visible)
    self._visible = visible
    
    if self._instance and self._instance:IsA("GuiObject") then
        self._instance.Visible = visible
    end
    
    return self
end

--[[
    Set component enabled state
    @param enabled - Enabled state
    @return - Self for method chaining
]]
function UIComponentBase:setEnabled(enabled)
    self._enabled = enabled
    
    -- Handle enabled state based on instance type
    if self._instance then
        if self._instance:IsA("TextButton") or self._instance:IsA("ImageButton") then
            self._instance.Active = enabled
            
            if enabled then
                self._instance.BackgroundTransparency = 0
                self._instance.TextTransparency = 0
            else
                self._instance.BackgroundTransparency = UIStyle and UIStyle.transparency.disabledElement or 0.4
                self._instance.TextTransparency = UIStyle and UIStyle.transparency.disabledElement or 0.4
            end
        end
    end
    
    return self
end

--[[
    Register an event handler
    @param eventName - Name of the event
    @param handler - Function to handle the event
    @return - Connection ID for unregistering
]]
function UIComponentBase:on(eventName, handler)
    if not self._events[eventName] then
        self._events[eventName] = {}
    end
    
    local id = #self._events[eventName] + 1
    self._events[eventName][id] = handler
    
    return id
end

--[[
    Unregister an event handler
    @param eventName - Name of the event
    @param id - Connection ID from on() method
    @return - Self for method chaining
]]
function UIComponentBase:off(eventName, id)
    if self._events[eventName] and self._events[eventName][id] then
        self._events[eventName][id] = nil
    end
    
    return self
end

--[[
    Trigger an event
    @param eventName - Name of the event
    @param ... - Additional arguments to pass to handlers
]]
function UIComponentBase:triggerEvent(eventName, ...)
    if not self._events[eventName] then
        return
    end
    
    for _, handler in pairs(self._events[eventName]) do
        task.spawn(function()
            handler(self, ...)
        end)
    end
end

--[[
    Connect to a Roblox event
    @param instance - Instance with the event
    @param eventName - Name of the event
    @param handler - Function to handle the event
    @return - Connection object
]]
function UIComponentBase:connect(instance, eventName, handler)
    if not instance then
        warn("[UIComponentBase] Cannot connect event: instance is nil")
        return nil
    end
    
    local event = instance[eventName]
    if not event or typeof(event) ~= "RBXScriptSignal" then
        warn("[UIComponentBase] Cannot connect event: " .. eventName .. " is not a valid event")
        return nil
    end
    
    local connection = event:Connect(function(...)
        handler(self, ...)
    end)
    
    -- Store the connection for cleanup
    table.insert(self._connections, connection)
    
    return connection
end

--[[
    Disconnect all connections
    @return - Self for method chaining
]]
function UIComponentBase:disconnectAll()
    for _, connection in ipairs(self._connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    
    self._connections = {}
    
    return self
end

--[[
    Destroy the component
    Cleans up all resources and removes the instance
]]
function UIComponentBase:destroy()
    -- Trigger destroy event
    self:triggerEvent("onDestroy")
    
    -- Disconnect all event connections
    self:disconnectAll()
    
    -- Destroy all children
    for _, child in ipairs(self._children) do
        child:destroy()
    end
    
    -- Clear children array
    self._children = {}
    
    -- Remove from parent
    self:unmount()
    
    -- Destroy the instance
    if self._instance then
        self._instance:Destroy()
        self._instance = nil
    end
    
    -- Clear event handlers
    self._events = {}
end

--[[
    Create a tween for the component instance
    @param properties - Properties to tween
    @param tweenInfo - TweenInfo object or nil for default
    @return - Tween object
]]
function UIComponentBase:tween(properties, tweenInfo)
    if not self._instance then
        warn("[UIComponentBase] Cannot tween: no instance")
        return nil
    end
    
    local info = tweenInfo or TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(self._instance, info, properties)
    
    return tween
end

-- Register property change handlers
propertyChangedHandlers["position"] = function(component, newValue)
    if component._instance then
        component._instance.Position = newValue
    end
end

propertyChangedHandlers["size"] = function(component, newValue)
    if component._instance then
        component._instance.Size = newValue
    end
end

propertyChangedHandlers["anchorPoint"] = function(component, newValue)
    if component._instance and component._instance:IsA("GuiObject") then
        component._instance.AnchorPoint = newValue
    end
end

propertyChangedHandlers["layoutOrder"] = function(component, newValue)
    if component._instance and component._instance:IsA("GuiObject") then
        component._instance.LayoutOrder = newValue
    end
end

return UIComponentBase
