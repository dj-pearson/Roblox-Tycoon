--!strict
--[[
    UISystem.client.luau
    
    Main UI system controller.
    Manages all UI components and their interactions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Types"))
local Constants = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Constants"))

type UIComponent = Types.UIComponent
type UIAnimation = Types.UIAnimation
type UIEvent = Types.UIEvent
type UISystem = Types.UISystem

local UISystem = {}
UISystem.__index = UISystem

-- Singleton instance
local instance: UISystem? = nil

-- Constructor
function UISystem.new(): UISystem
    if instance then
        return instance
    end
    
    local self = setmetatable({}, UISystem)
    
    self.components = {}
    self.activeComponent = nil
    self.eventHandlers = {}
    
    -- Create UI container
    self.container = Instance.new("ScreenGui")
    self.container.Name = "UISystem"
    self.container.ResetOnSpawn = false
    self.container.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    instance = self
    return self
end

-- Get singleton instance
function UISystem.getInstance(): UISystem
    return UISystem.new()
end

-- Register a component
function UISystem:register(component: UIComponent)
    if self.components[component.name] then
        warn("Component already registered: " .. component.name)
        return
    end
    
    self.components[component.name] = component
    component.instance.Parent = self.container
end

-- Unregister a component
function UISystem:unregister(name: string)
    local component = self.components[name]
    if not component then
        warn("Component not found: " .. name)
        return
    end
    
    component:destroy()
    self.components[name] = nil
    
    if self.activeComponent == component then
        self.activeComponent = nil
    end
end

-- Show a component
function UISystem:show(name: string, animation: UIAnimation?)
    local component = self.components[name]
    if not component then
        warn("Component not found: " .. name)
        return
    end
    
    -- Hide active component if different
    if self.activeComponent and self.activeComponent ~= component then
        self.activeComponent:hide(animation)
    end
    
    -- Show new component
    component:show(animation)
    self.activeComponent = component
end

-- Hide a component
function UISystem:hide(name: string, animation: UIAnimation?)
    local component = self.components[name]
    if not component then
        warn("Component not found: " .. name)
        return
    end
    
    component:hide(animation)
    
    if self.activeComponent == component then
        self.activeComponent = nil
    end
end

-- Get a component
function UISystem:get(name: string): UIComponent?
    return self.components[name]
end

-- Register event handler
function UISystem:on(eventType: string, handler: (event: UIEvent) -> ())
    if not self.eventHandlers[eventType] then
        self.eventHandlers[eventType] = {}
    end
    
    table.insert(self.eventHandlers[eventType], handler)
end

-- Dispatch event
function UISystem:dispatch(event: UIEvent)
    local handlers = self.eventHandlers[event.type]
    if not handlers then return end
    
    for _, handler in handlers do
        handler(event)
    end
end

-- Initialize the UI system
function UISystem:initialize()
    -- Set up global error handling
    self:setupErrorHandling()
    
    -- Set up input handling
    self:setupInputHandling()
    
    -- Set up cleanup
    self:setupCleanup()
end

-- Set up error handling
function UISystem:setupErrorHandling()
    -- Handle UI errors
    self:on("error", function(event)
        warn("UI Error:", event.data.message)
        
        -- Show error popup
        local errorComponent = self:get(Constants.COMPONENTS.ERROR_POPUP)
        if errorComponent then
            errorComponent:update({
                message = event.data.message
            })
            errorComponent:show()
        end
    end)
end

-- Set up input handling
function UISystem:setupInputHandling()
    -- Handle input events
    RunService:BindToRenderStep("UISystemInput", Enum.RenderPriority.Camera.Value + 1, function()
        -- Implement input handling
    end)
end

-- Set up cleanup
function UISystem:setupCleanup()
    -- Clean up on player leaving
    Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:cleanup()
        end
    end)
end

-- Clean up the UI system
function UISystem:cleanup()
    -- Destroy all components
    for name, _ in self.components do
        self:unregister(name)
    end
    
    -- Destroy container
    if self.container then
        self.container:Destroy()
    end
    
    -- Clear instance
    instance = nil
end

return UISystem 