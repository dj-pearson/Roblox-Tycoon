--!strict
--[[
    ClientEvents.luau
    
    Client-specific implementation of the Event System. Extends EventBase with
    functionality specific to the client context, including integration with UI
    events and input handling.
    
    Features:
    - UI event integration
    - Input event binding
    - Client-specific event categories
    - Performance optimizations for client context
    - Debug visualization for events
    
    Author: Created April 28, 2025
]]

-- Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Import dependencies
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local EventsModules = SharedModules:WaitForChild("Events")

local EventBase = require(EventsModules:WaitForChild("EventBase"))
local EventTypes = require(EventsModules:WaitForChild("EventTypes"))

-- Type imports
type Event = EventTypes.Event
type EventData = EventTypes.EventData
type EventHandler = EventTypes.EventHandler
type EventHandlerInfo = EventTypes.EventHandlerInfo
type EventPriority = EventTypes.EventPriority
type EventCategory = EventTypes.EventCategory
type EventFilter = EventTypes.EventFilter
type EventTransform = EventTypes.EventTransform
type EventResult = EventTypes.EventResult
type EventBusConfig = EventTypes.EventBusConfig
type EventSubscription = EventTypes.EventSubscription

-- Client-specific event categories
local ClientEventCategories = {
    INPUT = "input",           -- Input events (keyboard, mouse, touch)
    UI = "ui",                 -- UI events (buttons, sliders, etc.)
    ANIMATION = "animation",   -- Animation events
    CAMERA = "camera",         -- Camera events
    CHARACTER = "character",   -- Local character events
    AUDIO = "audio",           -- Audio events
    NOTIFICATION = "notification", -- Notification events
    EFFECT = "effect"          -- Visual effect events
}

-- Module implementation
local ClientEvents = setmetatable({}, {__index = EventBase})
ClientEvents.__index = ClientEvents

-- Constructor
function ClientEvents.new(config: EventBusConfig?)
    -- Prepare configuration with client defaults
    config = config or {}
    if not config.name then
        config.name = "ClientEvents"
    end
    
    -- Create new event bus with EventBase constructor
    local self = setmetatable(EventBase.new(config), ClientEvents)
    
    -- Add client-specific properties
    self.inputBindings = {}    -- Input key to event mapping
    self.uiBindings = {}       -- UI element to event mapping
    self.debugVisualization = config.debugVisualization == true
    self.localPlayer = Players.LocalPlayer
    
    -- Add client-specific filters
    table.insert(self.filters, function(event: Event)
        -- Example filter: ignore events from other players if marked as local-only
        if event.data.localOnly == true and event.data.player and event.data.player ~= self.localPlayer then
            return false
        end
        return true
    end)
    
    -- Set up input handling
    self:_setupInputHandling()
    
    return self
end

-- Get the singleton instance
local clientEventsInstance
function ClientEvents.get()
    if not clientEventsInstance then
        clientEventsInstance = ClientEvents.new()
    end
    return clientEventsInstance
end

--[[ Client-specific implementations ]]--

-- Set up input handling
function ClientEvents:_setupInputHandling()
    -- Handle input began events
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local inputType = input.UserInputType
        local keyCode = input.KeyCode
        
        -- Check for bound inputs
        if inputType == Enum.UserInputType.Keyboard then
            if self.inputBindings[keyCode] then
                for _, binding in ipairs(self.inputBindings[keyCode]) do
                    if binding.type == "began" or binding.type == "both" then
                        self:emit(binding.eventId, {
                            input = input,
                            keyCode = keyCode,
                            player = self.localPlayer
                        }, {
                            category = ClientEventCategories.INPUT,
                            source = "InputService"
                        })
                    end
                end
            end
        elseif inputType == Enum.UserInputType.MouseButton1 or 
               inputType == Enum.UserInputType.MouseButton2 or
               inputType == Enum.UserInputType.MouseButton3 then
            -- Handle mouse buttons
            if self.inputBindings[inputType] then
                for _, binding in ipairs(self.inputBindings[inputType]) do
                    if binding.type == "began" or binding.type == "both" then
                        self:emit(binding.eventId, {
                            input = input,
                            inputType = inputType,
                            mousePosition = input.Position,
                            player = self.localPlayer
                        }, {
                            category = ClientEventCategories.INPUT,
                            source = "InputService"
                        })
                    end
                end
            end
        elseif inputType == Enum.UserInputType.Touch then
            -- Handle touch inputs
            if self.inputBindings[inputType] then
                for _, binding in ipairs(self.inputBindings[inputType]) do
                    if binding.type == "began" or binding.type == "both" then
                        self:emit(binding.eventId, {
                            input = input,
                            inputType = inputType,
                            touchPosition = input.Position,
                            player = self.localPlayer
                        }, {
                            category = ClientEventCategories.INPUT,
                            source = "InputService"
                        })
                    end
                end
            end
        end
    end)
    
    -- Handle input ended events
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local inputType = input.UserInputType
        local keyCode = input.KeyCode
        
        -- Check for bound inputs
        if inputType == Enum.UserInputType.Keyboard then
            if self.inputBindings[keyCode] then
                for _, binding in ipairs(self.inputBindings[keyCode]) do
                    if binding.type == "ended" or binding.type == "both" then
                        self:emit(binding.eventId, {
                            input = input,
                            keyCode = keyCode,
                            player = self.localPlayer
                        }, {
                            category = ClientEventCategories.INPUT,
                            source = "InputService"
                        })
                    end
                end
            end
        elseif inputType == Enum.UserInputType.MouseButton1 or 
               inputType == Enum.UserInputType.MouseButton2 or
               inputType == Enum.UserInputType.MouseButton3 then
            -- Handle mouse buttons
            if self.inputBindings[inputType] then
                for _, binding in ipairs(self.inputBindings[inputType]) do
                    if binding.type == "ended" or binding.type == "both" then
                        self:emit(binding.eventId, {
                            input = input,
                            inputType = inputType,
                            mousePosition = input.Position,
                            player = self.localPlayer
                        }, {
                            category = ClientEventCategories.INPUT,
                            source = "InputService"
                        })
                    end
                end
            end
        elseif inputType == Enum.UserInputType.Touch then
            -- Handle touch inputs
            if self.inputBindings[inputType] then
                for _, binding in ipairs(self.inputBindings[inputType]) do
                    if binding.type == "ended" or binding.type == "both" then
                        self:emit(binding.eventId, {
                            input = input,
                            inputType = inputType,
                            touchPosition = input.Position,
                            player = self.localPlayer
                        }, {
                            category = ClientEventCategories.INPUT,
                            source = "InputService"
                        })
                    end
                end
            end
        end
    end)
    
    -- Handle input changed events (for mouse movement, etc.)
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            -- Fire mouse move event if we have subscribers
            if self.handlers["input.mouseMoved"] then
                self:emit("input.mouseMoved", {
                    input = input,
                    mousePosition = input.Position,
                    delta = input.Delta,
                    player = self.localPlayer
                }, {
                    category = ClientEventCategories.INPUT,
                    source = "InputService"
                })
            end
        elseif input.UserInputType == Enum.UserInputType.Touch and input.UserInputState == Enum.UserInputState.Change then
            -- Fire touch moved event if we have subscribers
            if self.handlers["input.touchMoved"] then
                self:emit("input.touchMoved", {
                    input = input,
                    touchPosition = input.Position,
                    delta = input.Delta,
                    player = self.localPlayer
                }, {
                    category = ClientEventCategories.INPUT,
                    source = "InputService"
                })
            end
        end
    end)
end

-- Bind an input to an event
function ClientEvents:bindInput(
    inputBinding: Enum.KeyCode | Enum.UserInputType,
    eventId: string,
    bindType: "began" | "ended" | "both"
): boolean
    -- Initialize the binding table if it doesn't exist
    if not self.inputBindings[inputBinding] then
        self.inputBindings[inputBinding] = {}
    end
    
    -- Add the binding
    table.insert(self.inputBindings[inputBinding], {
        eventId = eventId,
        type = bindType or "both"
    })
    
    return true
end

-- Unbind an input from an event
function ClientEvents:unbindInput(
    inputBinding: Enum.KeyCode | Enum.UserInputType,
    eventId: string
): boolean
    -- Check if the binding exists
    if not self.inputBindings[inputBinding] then
        return false
    end
    
    -- Find and remove the binding
    local bindings = self.inputBindings[inputBinding]
    for i = #bindings, 1, -1 do
        if bindings[i].eventId == eventId then
            table.remove(bindings, i)
            
            -- Clean up empty binding arrays
            if #bindings == 0 then
                self.inputBindings[inputBinding] = nil
            end
            
            return true
        end
    end
    
    return false
end

-- Bind a UI element to an event
function ClientEvents:bindUIElement(
    uiElement: GuiObject,
    eventName: string,
    eventId: string
): RBXScriptConnection
    -- Create a unique ID for the element if we don't have one
    local elementId = uiElement:GetAttribute("id") or tostring(uiElement)
    
    -- Initialize the binding table if it doesn't exist
    if not self.uiBindings[elementId] then
        self.uiBindings[elementId] = {}
    end
    
    -- Create the event connection
    local connection
    
    if eventName == "mouseEnter" then
        connection = uiElement.MouseEnter:Connect(function()
            self:emit(eventId, {
                element = uiElement,
                player = self.localPlayer
            }, {
                category = ClientEventCategories.UI,
                source = "UIBinding"
            })
        end)
    elseif eventName == "mouseLeave" then
        connection = uiElement.MouseLeave:Connect(function()
            self:emit(eventId, {
                element = uiElement,
                player = self.localPlayer
            }, {
                category = ClientEventCategories.UI,
                source = "UIBinding"
            })
        end)
    elseif eventName == "mouseButton1Click" then
        connection = uiElement.MouseButton1Click:Connect(function()
            self:emit(eventId, {
                element = uiElement,
                player = self.localPlayer
            }, {
                category = ClientEventCategories.UI,
                source = "UIBinding"
            })
        end)
    elseif eventName == "mouseButton1Down" then
        connection = uiElement.MouseButton1Down:Connect(function()
            self:emit(eventId, {
                element = uiElement,
                player = self.localPlayer
            }, {
                category = ClientEventCategories.UI,
                source = "UIBinding"
            })
        end)
    elseif eventName == "mouseButton1Up" then
        connection = uiElement.MouseButton1Up:Connect(function()
            self:emit(eventId, {
                element = uiElement,
                player = self.localPlayer
            }, {
                category = ClientEventCategories.UI,
                source = "UIBinding"
            })
        end)
    elseif eventName == "mouseButton2Click" then
        connection = uiElement.MouseButton2Click:Connect(function()
            self:emit(eventId, {
                element = uiElement,
                player = self.localPlayer
            }, {
                category = ClientEventCategories.UI,
                source = "UIBinding"
            })
        end)
    elseif eventName == "mouseButton2Down" then
        connection = uiElement.MouseButton2Down:Connect(function()
            self:emit(eventId, {
                element = uiElement,
                player = self.localPlayer
            }, {
                category = ClientEventCategories.UI,
                source = "UIBinding"
            })
        end)
    elseif eventName == "mouseButton2Up" then
        connection = uiElement.MouseButton2Up:Connect(function()
            self:emit(eventId, {
                element = uiElement,
                player = self.localPlayer
            }, {
                category = ClientEventCategories.UI,
                source = "UIBinding"
            })
        end)
    end
    
    -- Store the connection
    if connection then
        self.uiBindings[elementId][eventName] = connection
    end
    
    return connection
end

-- Unbind a UI element from an event
function ClientEvents:unbindUIElement(
    uiElement: GuiObject,
    eventName: string
): boolean
    -- Get the element ID
    local elementId = uiElement:GetAttribute("id") or tostring(uiElement)
    
    -- Check if the binding exists
    if not self.uiBindings[elementId] or not self.uiBindings[elementId][eventName] then
        return false
    end
    
    -- Disconnect the event
    self.uiBindings[elementId][eventName]:Disconnect()
    self.uiBindings[elementId][eventName] = nil
    
    -- Clean up empty binding tables
    if not next(self.uiBindings[elementId]) then
        self.uiBindings[elementId] = nil
    end
    
    return true
end

-- Clean up UI bindings for an element when it's removed
function ClientEvents:cleanupUIBindings(uiElement: GuiObject)
    local elementId = uiElement:GetAttribute("id") or tostring(uiElement)
    
    if self.uiBindings[elementId] then
        for _, connection in pairs(self.uiBindings[elementId]) do
            connection:Disconnect()
        end
        self.uiBindings[elementId] = nil
    end
end

-- Fire a UI event
function ClientEvents:fireUIEvent(
    eventId: string,
    uiElement: GuiObject,
    additionalData: EventData?
): EventResult
    local data = additionalData or {}
    data.element = uiElement
    data.player = self.localPlayer
    
    return self:emit(eventId, data, {
        category = ClientEventCategories.UI,
        source = "UIEvent"
    })
end

-- Fire a local player event
function ClientEvents:firePlayerEvent(
    eventId: string,
    data: EventData?
): EventResult
    local eventData = data or {}
    eventData.player = self.localPlayer
    
    return self:emit(eventId, eventData, {
        category = ClientEventCategories.PLAYER,
        source = "PlayerEvent"
    })
end

-- Fire an animation event
function ClientEvents:fireAnimationEvent(
    eventId: string,
    animationTrack: AnimationTrack,
    additionalData: EventData?
): EventResult
    local data = additionalData or {}
    data.track = animationTrack
    data.player = self.localPlayer
    
    return self:emit(eventId, data, {
        category = ClientEventCategories.ANIMATION,
        source = "AnimationEvent"
    })
end

-- Enable debug visualization for events
function ClientEvents:enableDebugVisualization(enabled: boolean?)
    self.debugVisualization = enabled ~= false
    
    if self.debugVisualization then
        -- Create a transform to show events visually
        table.insert(self.transforms, function(event: Event)
            -- Only visualize certain types of events
            if event.category == ClientEventCategories.UI or 
               event.category == ClientEventCategories.INPUT or
               event.category == ClientEventCategories.EFFECT then
                
                task.spawn(function()
                    local screenGui = Instance.new("ScreenGui")
                    screenGui.Name = "EventVisualizer"
                    screenGui.ResetOnSpawn = false
                    
                    local frame = Instance.new("Frame")
                    frame.Size = UDim2.new(0, 200, 0, 50)
                    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    frame.BackgroundTransparency = 0.7
                    frame.Position = UDim2.new(0.5, -100, 0.9, -25)
                    frame.Parent = screenGui
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                    label.Text = event.id .. "\n" .. event.category
                    label.Parent = frame
                    
                    screenGui.Parent = Players.LocalPlayer:FindFirstChild("PlayerGui")
                    
                    -- Animate and remove
                    local startTime = os.clock()
                    local connection
                    connection = RunService.RenderStepped:Connect(function()
                        local elapsed = os.clock() - startTime
                        if elapsed > 2 then
                            screenGui:Destroy()
                            connection:Disconnect()
                            return
                        end
                        
                        -- Fade out
                        local alpha = 1 - (elapsed / 2)
                        frame.BackgroundTransparency = 0.7 + (0.3 * (1 - alpha))
                        label.TextTransparency = 1 - alpha
                        
                        -- Move up
                        frame.Position = UDim2.new(0.5, -100, 0.9 - (0.1 * elapsed), -25)
                    end)
                end)
            end
            
            return event
        end)
    else
        -- Remove visualization transform
        for i = #self.transforms, 1, -1 do
            -- Look for the transform we added (imperfect but simple)
            local source = debug.info(self.transforms[i], "s")
            if source and source:find("enableDebugVisualization") then
                table.remove(self.transforms, i)
                break
            end
        end
    end
end

-- Return module (with get function for singleton access)
return ClientEvents
