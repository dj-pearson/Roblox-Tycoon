--!strict
--[[
    UIComponent.luau
    
    Base class for all UI components.
    Provides common functionality and lifecycle methods.
    
    Features:
    - Component lifecycle management
    - Event handling
    - State management
    - UI element creation
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    debugMode = true,
    defaultSize = UDim2.new(1, 0, 1, 0),
    defaultPosition = UDim2.new(0, 0, 0, 0),
    defaultBackgroundColor = Color3.fromRGB(40, 40, 45),
    defaultBackgroundTransparency = 0
}

-- Base UI Component class
local UIComponent = {}
UIComponent.__index = UIComponent

-- Constructor
function UIComponent.new(name)
    local self = setmetatable({}, UIComponent)
    
    self.name = name
    self.instance = nil
    self.events = {}
    self.state = {}
    self.initialized = false
    
    return self
end

-- Initialize the component
function UIComponent:initialize()
    if self.initialized then
        warn("[UIComponent] Component already initialized: " .. self.name)
        return false
    end
    
    -- Create base instance
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = self.name
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create main frame
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = CONFIG.defaultSize
    frame.Position = CONFIG.defaultPosition
    frame.BackgroundColor3 = CONFIG.defaultBackgroundColor
    frame.BackgroundTransparency = CONFIG.defaultBackgroundTransparency
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    -- Store instance
    self.instance = screenGui
    
    -- Mark as initialized
    self.initialized = true
    
    if CONFIG.debugMode then
        print("[UIComponent] Initialized: " .. self.name)
    end
    
    return true
end

-- Create the UI (to be implemented by subclasses)
function UIComponent:create()
    if not self.initialized then
        warn("[UIComponent] Component not initialized: " .. self.name)
        return nil
    end
    
    -- Add to PlayerGui
    self.instance.Parent = PlayerGui
    
    if CONFIG.debugMode then
        print("[UIComponent] Created: " .. self.name)
    end
    
    return self.instance
end

-- Show the UI
function UIComponent:show()
    if not self.instance then
        warn("[UIComponent] No instance to show: " .. self.name)
        return false
    end
    
    self.instance.Visible = true
    
    if CONFIG.debugMode then
        print("[UIComponent] Shown: " .. self.name)
    end
    
    return true
end

-- Hide the UI
function UIComponent:hide()
    if not self.instance then
        warn("[UIComponent] No instance to hide: " .. self.name)
        return false
    end
    
    self.instance.Visible = false
    
    if CONFIG.debugMode then
        print("[UIComponent] Hidden: " .. self.name)
    end
    
    return true
end

-- Destroy the UI
function UIComponent:destroy()
    if not self.instance then
        warn("[UIComponent] No instance to destroy: " .. self.name)
        return false
    end
    
    -- Clean up events
    for _, connection in pairs(self.events) do
        connection:Disconnect()
    end
    self.events = {}
    
    -- Destroy instance
    self.instance:Destroy()
    self.instance = nil
    self.initialized = false
    
    if CONFIG.debugMode then
        print("[UIComponent] Destroyed: " .. self.name)
    end
    
    return true
end

-- Set state and trigger update
function UIComponent:setState(newState)
    if not self.initialized then
        warn("[UIComponent] Component not initialized: " .. self.name)
        return false
    end
    
    -- Merge new state with existing state
    for key, value in pairs(newState) do
        self.state[key] = value
    end
    
    -- Trigger update
    self:update()
    
    return true
end

-- Update the UI (to be implemented by subclasses)
function UIComponent:update()
    if not self.initialized then
        warn("[UIComponent] Component not initialized: " .. self.name)
        return false
    end
    
    if CONFIG.debugMode then
        print("[UIComponent] Updated: " .. self.name)
    end
    
    return true
end

-- Add event listener
function UIComponent:on(eventName, callback)
    if not self.instance then
        warn("[UIComponent] No instance to add event to: " .. self.name)
        return false
    end
    
    local connection = self.instance[eventName]:Connect(callback)
    table.insert(self.events, connection)
    
    return true
end

-- Create a UI element with common properties
function UIComponent:createElement(elementType, properties)
    if not self.instance then
        warn("[UIComponent] No instance to create element in: " .. self.name)
        return nil
    end
    
    local element = Instance.new(elementType)
    
    -- Apply properties
    for property, value in pairs(properties) do
        element[property] = value
    end
    
    -- Add to main frame
    element.Parent = self.instance.MainFrame
    
    return element
end

-- Create a text label
function UIComponent:createLabel(properties)
    properties = properties or {}
    
    -- Set default properties
    properties.Name = properties.Name or "Label"
    properties.Size = properties.Size or UDim2.new(1, 0, 0, 20)
    properties.BackgroundTransparency = properties.BackgroundTransparency or 1
    properties.TextColor3 = properties.TextColor3 or Color3.fromRGB(255, 255, 255)
    properties.Font = properties.Font or Enum.Font.Gotham
    properties.TextSize = properties.TextSize or 14
    properties.TextWrapped = properties.TextWrapped or true
    
    return self:createElement("TextLabel", properties)
end

-- Create a button
function UIComponent:createButton(properties)
    properties = properties or {}
    
    -- Set default properties
    properties.Name = properties.Name or "Button"
    properties.Size = properties.Size or UDim2.new(0, 100, 0, 35)
    properties.BackgroundColor3 = properties.BackgroundColor3 or Color3.fromRGB(114, 137, 218)
    properties.BorderSizePixel = properties.BorderSizePixel or 0
    properties.TextColor3 = properties.TextColor3 or Color3.fromRGB(255, 255, 255)
    properties.Font = properties.Font or Enum.Font.GothamBold
    properties.TextSize = properties.TextSize or 14
    
    -- Add corner radius
    local button = self:createElement("TextButton", properties)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    return button
end

-- Create a frame
function UIComponent:createFrame(properties)
    properties = properties or {}
    
    -- Set default properties
    properties.Name = properties.Name or "Frame"
    properties.Size = properties.Size or UDim2.new(1, 0, 1, 0)
    properties.BackgroundColor3 = properties.BackgroundColor3 or Color3.fromRGB(40, 40, 45)
    properties.BorderSizePixel = properties.BorderSizePixel or 0
    
    return self:createElement("Frame", properties)
end

-- Create a scrolling frame
function UIComponent:createScrollingFrame(properties)
    properties = properties or {}
    
    -- Set default properties
    properties.Name = properties.Name or "ScrollingFrame"
    properties.Size = properties.Size or UDim2.new(1, 0, 1, 0)
    properties.BackgroundColor3 = properties.BackgroundColor3 or Color3.fromRGB(40, 40, 45)
    properties.BorderSizePixel = properties.BorderSizePixel or 0
    properties.ScrollBarThickness = properties.ScrollBarThickness or 6
    properties.ScrollingDirection = properties.ScrollingDirection or Enum.ScrollingDirection.Y
    properties.CanvasSize = properties.CanvasSize or UDim2.new(0, 0, 0, 0)
    
    return self:createElement("ScrollingFrame", properties)
end

-- Create an input field
function UIComponent:createInputField(properties)
    properties = properties or {}
    
    -- Set default properties
    properties.Name = properties.Name or "InputField"
    properties.Size = properties.Size or UDim2.new(1, 0, 0, 35)
    properties.BackgroundColor3 = properties.BackgroundColor3 or Color3.fromRGB(50, 50, 55)
    properties.BorderSizePixel = properties.BorderSizePixel or 0
    properties.TextColor3 = properties.TextColor3 or Color3.fromRGB(255, 255, 255)
    properties.Font = properties.Font or Enum.Font.Gotham
    properties.TextSize = properties.TextSize or 14
    properties.PlaceholderText = properties.PlaceholderText or ""
    properties.PlaceholderColor3 = properties.PlaceholderColor3 or Color3.fromRGB(150, 150, 150)
    
    -- Add corner radius
    local input = self:createElement("TextBox", properties)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = input
    
    return input
end

return UIComponent 