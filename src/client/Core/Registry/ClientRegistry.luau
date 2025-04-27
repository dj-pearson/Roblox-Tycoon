--!strict
--[[
    ClientRegistry.luau
    
    Client-side registry implementation that extends the RegistryBase with
    client-specific functionality for UI components, client services, and
    input handling. This registry operates only on the client side.
    
    Features:
    - UI component registration and lifecycle management
    - Input handler registration and priority management
    - Client-side service discovery and initialization
    - Automatic component cleanup on game end
    
    Author: Created April 27, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Import required modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryBase = require(SharedModules:WaitForChild("Registry"):WaitForChild("RegistryBase"))

-- Type definitions
type UIComponentInfo = {
    id: string,
    parent: Instance?,
    instances: {[string]: Instance},
    visible: boolean,
    zIndex: number,
    screenGui: ScreenGui?,
    events: {[string]: RBXScriptConnection},
    data: {[string]: any}
}

type InputHandler = {
    id: string,
    priority: number,
    callback: (InputObject, ProcessedState) -> boolean,
    inputTypes: {[Enum.UserInputType]: boolean}?,
    keyboardKeys: {[Enum.KeyCode]: boolean}?,
    gamepadButtons: {[Enum.KeyCode]: boolean}?,
    active: boolean
}

-- Module implementation
local ClientRegistry = {}
ClientRegistry.__index = ClientRegistry

-- Create a new client registry instance
function ClientRegistry.new(name)
    -- Create a base registry
    local baseRegistry = RegistryBase.new(name or "ClientRegistry", {
        logLevel = 3,
        allowOverrides = true,
        autoInit = true
    })
    
    -- Create client registry as an extension of the base registry
    local self = setmetatable({
        -- Inherit all base registry properties
        name = baseRegistry.name,
        components = baseRegistry.components,
        options = baseRegistry.options,
        
        -- Client-specific properties
        uiComponents = {},
        inputHandlers = {
            keyboard = {},
            gamepad = {},
            touch = {},
            mouse = {},
            other = {}
        },
        inputHandlersByPriority = {}
    }, ClientRegistry)
    
    -- Copy all methods from base registry
    for key, value in pairs(baseRegistry) do
        if type(value) == "function" and not self[key] then
            self[key] = value
        end
    end
    
    -- Initialize client registry
    self:initialize()
    
    print("[ClientRegistry] Created new registry:", name)
    
    return self
end

--[[ Private Utility Functions ]]--

-- Handle input processing
local function processInputHandlers(self, inputObject, gameProcessed)
    -- Skip if already game processed
    if gameProcessed then
        return
    end
    
    -- Determine input category
    local category = "other"
    if inputObject.UserInputType == Enum.UserInputType.Keyboard then
        category = "keyboard"
    elseif inputObject.UserInputType == Enum.UserInputType.Gamepad1 then
        category = "gamepad"
    elseif inputObject.UserInputType == Enum.UserInputType.Touch then
        category = "touch"
    elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 or
           inputObject.UserInputType == Enum.UserInputType.MouseButton2 or
           inputObject.UserInputType == Enum.UserInputType.MouseButton3 then
        category = "mouse"
    end
    
    -- Process handlers in priority order
    for _, handler in ipairs(self.inputHandlersByPriority) do
        -- Skip inactive handlers
        if not handler.active then
            continue
        end
        
        -- Check input type filtering
        if handler.inputTypes and not handler.inputTypes[inputObject.UserInputType] then
            continue
        end
        
        -- Check key filtering for keyboard
        if category == "keyboard" and handler.keyboardKeys and 
           not handler.keyboardKeys[inputObject.KeyCode] then
            continue
        end
        
        -- Check button filtering for gamepad
        if category == "gamepad" and handler.gamepadButtons and
           not handler.gamepadButtons[inputObject.KeyCode] then
            continue
        end
        
        -- Call handler
        local handled = handler.callback(inputObject, gameProcessed)
        
        -- If handled, stop processing
        if handled then
            break
        end
    end
end

-- Connect input events
local function connectInputEvents(self)
    -- Handle input began
    UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
        processInputHandlers(self, inputObject, gameProcessed)
    end)
    
    -- Handle input ended
    UserInputService.InputEnded:Connect(function(inputObject, gameProcessed)
        processInputHandlers(self, inputObject, gameProcessed)
    end)
    
    -- Handle input changed
    UserInputService.InputChanged:Connect(function(inputObject, gameProcessed)
        processInputHandlers(self, inputObject, gameProcessed)
    end)
end

-- Sort input handlers by priority
local function sortInputHandlers(self)
    -- Clear current sorted list
    table.clear(self.inputHandlersByPriority)
    
    -- Collect all handlers
    local allHandlers = {}
    
    for _, categoryHandlers in pairs(self.inputHandlers) do
        for _, handler in pairs(categoryHandlers) do
            table.insert(allHandlers, handler)
        end
    end
    
    -- Sort by priority (higher priority comes first)
    table.sort(allHandlers, function(a, b)
        return a.priority > b.priority
    end)
    
    -- Store sorted handlers
    self.inputHandlersByPriority = allHandlers
end

-- Set up cleanup on game exit
local function setupCleanup(self)
    -- Clean up on game exit
    game:BindToClose(function()
        self:cleanup()
    end)
end

--[[ Client Registry API Implementation ]]--

-- Initialize the client registry
function ClientRegistry:initialize()
    -- Only run on client
    if not RunService:IsClient() then
        warn("[ClientRegistry] Cannot initialize on server")
        return false
    end
    
    -- Connect input events
    connectInputEvents(self)
    
    -- Set up cleanup
    setupCleanup(self)
    
    return true
end

-- Register a UI component
function ClientRegistry:registerUIComponent(id, component, parent)
    -- Validate parameters
    if not id or not component then
        warn("[ClientRegistry] Failed to register UI component: Invalid parameters")
        return false
    end
    
    -- First register as a normal component
    if not self:register(id, component) then
        return false
    end
    
    -- Create UI component info
    local componentInfo = {
        id = id,
        parent = parent,
        instances = {},
        visible = false,
        zIndex = 0,
        events = {},
        data = {}
    }
    
    -- Store UI component info
    self.uiComponents[id] = componentInfo
    
    -- If component has a mount method, call it
    if type(component.mount) == "function" then
        local success, result = pcall(function()
            return component:mount(parent)
        end)
        
        if success then
            -- If mount returned instances, store them
            if type(result) == "table" then
                componentInfo.instances = result
            end
            
            -- If mount created a ScreenGui, store it
            for _, instance in pairs(componentInfo.instances) do
                if instance:IsA("ScreenGui") then
                    componentInfo.screenGui = instance
                    break
                end
            end
        else
            warn("[ClientRegistry] Failed to mount UI component:", id, result)
        end
    end
    
    return true
end

-- Register an input handler
function ClientRegistry:registerInputHandler(id, callback, options)
    -- Validate parameters
    if not id or not callback or type(callback) ~= "function" then
        warn("[ClientRegistry] Failed to register input handler: Invalid parameters")
        return false
    end
    
    options = options or {}
    
    -- Create handler info
    local handlerInfo = {
        id = id,
        callback = callback,
        priority = options.priority or 0,
        active = options.active ~= false,
        inputTypes = options.inputTypes,
        keyboardKeys = options.keyboardKeys,
        gamepadButtons = options.gamepadButtons
    }
    
    -- Convert arrays to lookup tables for faster checking
    local function arrayToLookup(array)
        if array and type(array) == "table" then
            local lookup = {}
            for _, item in ipairs(array) do
                lookup[item] = true
            end
            return lookup
        end
        return nil
    end
    
    handlerInfo.inputTypes = arrayToLookup(handlerInfo.inputTypes)
    handlerInfo.keyboardKeys = arrayToLookup(handlerInfo.keyboardKeys)
    handlerInfo.gamepadButtons = arrayToLookup(handlerInfo.gamepadButtons)
    
    -- Determine main category for faster lookup
    local category = "other"
    if options.category then
        category = options.category
    elseif handlerInfo.keyboardKeys then
        category = "keyboard"
    elseif handlerInfo.gamepadButtons then
        category = "gamepad"
    elseif handlerInfo.inputTypes then
        -- Check for touch or mouse specific handlers
        for inputType, _ in pairs(handlerInfo.inputTypes) do
            if inputType == Enum.UserInputType.Touch then
                category = "touch"
                break
            elseif inputType == Enum.UserInputType.MouseButton1 or
                   inputType == Enum.UserInputType.MouseButton2 or
                   inputType == Enum.UserInputType.MouseButton3 then
                category = "mouse"
                break
            end
        end
    end
    
    -- Store handler in category
    self.inputHandlers[category][id] = handlerInfo
    
    -- Re-sort handlers by priority
    sortInputHandlers(self)
    
    return true
end

-- Show a UI component
function ClientRegistry:showUIComponent(id, zIndex)
    local componentInfo = self.uiComponents[id]
    if not componentInfo then
        warn("[ClientRegistry] Cannot show UI component: Not found:", id)
        return false
    end
    
    -- Update zIndex if specified
    if zIndex then
        componentInfo.zIndex = zIndex
    end
    
    -- If component has a show method, call it
    local component = self:get(id)
    if component and type(component.show) == "function" then
        local success, result = pcall(function()
            return component:show(componentInfo.zIndex)
        end)
        
        if not success then
            warn("[ClientRegistry] Failed to show UI component:", id, result)
            return false
        end
    end
    
    -- If component has a ScreenGui, show it
    if componentInfo.screenGui then
        componentInfo.screenGui.Enabled = true
        componentInfo.screenGui.DisplayOrder = componentInfo.zIndex
    end
    
    -- Update visibility state
    componentInfo.visible = true
    
    return true
end

-- Hide a UI component
function ClientRegistry:hideUIComponent(id)
    local componentInfo = self.uiComponents[id]
    if not componentInfo then
        warn("[ClientRegistry] Cannot hide UI component: Not found:", id)
        return false
    end
    
    -- If component has a hide method, call it
    local component = self:get(id)
    if component and type(component.hide) == "function" then
        local success, result = pcall(function()
            return component:hide()
        end)
        
        if not success then
            warn("[ClientRegistry] Failed to hide UI component:", id, result)
            return false
        end
    end
    
    -- If component has a ScreenGui, hide it
    if componentInfo.screenGui then
        componentInfo.screenGui.Enabled = false
    end
    
    -- Update visibility state
    componentInfo.visible = false
    
    return true
end

-- Update a UI component
function ClientRegistry:updateUIComponent(id, data)
    local componentInfo = self.uiComponents[id]
    if not componentInfo then
        warn("[ClientRegistry] Cannot update UI component: Not found:", id)
        return false
    end
    
    -- If component has an update method, call it
    local component = self:get(id)
    if component and type(component.update) == "function" then
        local success, result = pcall(function()
            return component:update(data)
        end)
        
        if not success then
            warn("[ClientRegistry] Failed to update UI component:", id, result)
            return false
        end
    end
    
    -- Store data in component info
    if data then
        for key, value in pairs(data) do
            componentInfo.data[key] = value
        end
    end
    
    return true
end

-- Get UI component instance(s)
function ClientRegistry:getUIInstance(id, instanceName)
    local componentInfo = self.uiComponents[id]
    if not componentInfo then
        return nil
    end
    
    if instanceName then
        return componentInfo.instances[instanceName]
    else
        return componentInfo.instances
    end
end

-- Set input handler active state
function ClientRegistry:setInputHandlerActive(id, active)
    -- Find handler in all categories
    for category, handlers in pairs(self.inputHandlers) do
        if handlers[id] then
            handlers[id].active = active ~= false
            return true
        end
    end
    
    return false
end

-- Connect a UI event
function ClientRegistry:connectUIEvent(componentId, eventName, callback)
    local componentInfo = self.uiComponents[componentId]
    if not componentInfo then
        warn("[ClientRegistry] Cannot connect UI event: Component not found:", componentId)
        return false
    end
    
    -- If event connection already exists, disconnect it
    if componentInfo.events[eventName] then
        componentInfo.events[eventName]:Disconnect()
        componentInfo.events[eventName] = nil
    end
    
    -- If callback is nil, just disconnect
    if not callback then
        return true
    end
    
    -- Find event in component instances
    local eventInstance = nil
    
    -- Check if there's a direct instance with this name
    if componentInfo.instances[eventName] then
        local instance = componentInfo.instances[eventName]
        if typeof(instance) == "RBXScriptSignal" then
            eventInstance = instance
        end
    end
    
    -- If not found, look for instance with this event
    if not eventInstance then
        for name, instance in pairs(componentInfo.instances) do
            if typeof(instance) == "Instance" and instance:IsA("GuiObject") then
                if eventName == "Click" or eventName == "MouseButton1Click" then
                    eventInstance = instance.MouseButton1Click
                    break
                elseif eventName == "MouseEnter" then
                    eventInstance = instance.MouseEnter
                    break
                elseif eventName == "MouseLeave" then
                    eventInstance = instance.MouseLeave
                    break
                elseif eventName == "TextChanged" and instance:IsA("TextBox") then
                    eventInstance = instance:GetPropertyChangedSignal("Text")
                    break
                end
            end
        end
    end
    
    -- If event instance found, connect it
    if eventInstance then
        componentInfo.events[eventName] = eventInstance:Connect(callback)
        return true
    end
    
    -- If component has a connectEvent method, use it
    local component = self:get(componentId)
    if component and type(component.connectEvent) == "function" then
        local success, connection = pcall(function()
            return component:connectEvent(eventName, callback)
        end)
        
        if success and typeof(connection) == "RBXScriptConnection" then
            componentInfo.events[eventName] = connection
            return true
        end
    end
    
    warn("[ClientRegistry] Failed to connect UI event:", componentId, eventName)
    return false
end

-- Unregister a UI component
function ClientRegistry:unregisterUIComponent(id)
    local componentInfo = self.uiComponents[id]
    if not componentInfo then
        return false
    end
    
    -- If component has an unmount method, call it
    local component = self:get(id)
    if component and type(component.unmount) == "function" then
        pcall(function()
            component:unmount()
        end)
    end
    
    -- Disconnect all events
    for eventName, connection in pairs(componentInfo.events) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    
    -- Remove all instances
    for name, instance in pairs(componentInfo.instances) do
        if typeof(instance) == "Instance" then
            pcall(function()
                instance:Destroy()
            end)
        end
    end
    
    -- Remove component info
    self.uiComponents[id] = nil
    
    -- Remove from base registry
    self:remove(id)
    
    return true
end

-- Clean up all UI components and input handlers
function ClientRegistry:cleanup()
    -- Clean up UI components
    for id, _ in pairs(self.uiComponents) do
        self:unregisterUIComponent(id)
    end
    
    -- Clear input handlers
    self.inputHandlers = {
        keyboard = {},
        gamepad = {},
        touch = {},
        mouse = {},
        other = {}
    }
    table.clear(self.inputHandlersByPriority)
    
    -- Shut down all components
    self:shutdownAll()
    
    return true
end

-- Build client registry singleton and wait for local player
local ClientRegistryInstance = nil

-- Create singleton instance
local function createSingleton()
    -- Only create on client
    if not RunService:IsClient() then
        return nil
    end
    
    -- Wait for local player
    local localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    
    -- Create instance if doesn't exist
    if not ClientRegistryInstance then
        ClientRegistryInstance = ClientRegistry.new("GlobalClientRegistry")
    end
    
    return ClientRegistryInstance
end

-- Get singleton instance
local function getInstance()
    return ClientRegistryInstance or createSingleton()
end

return {
    new = ClientRegistry.new,
    get = getInstance
}
