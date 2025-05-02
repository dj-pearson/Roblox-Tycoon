--!strict
-- RebirthClient.client.luau
-- Client-side controller for the rebirth system
-- Created: May 2, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

-- Core imports
local ClientRegistry = require(script.Parent.Parent.Parent.client.Core.ClientRegistry)
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
local UIManager = ClientRegistry.getSystem("UIManager")
local NotificationSystem = ClientRegistry.getSystem("NotificationSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    
    -- Particle effects for feature unlocks
    unlockEffects = {
        duration = 2,
        color = Color3.fromRGB(255, 215, 0), -- Gold
        particleCount = 30,
        spreadRadius = 5,
        image = "rbxassetid://3084116722", -- Star particle
    },
    
    -- Sound effects
    sounds = {
        unlock = "rbxassetid://1753832226", -- Success sound
        rebirthComplete = "rbxassetid://5153734608", -- Achievement sound
        featureUnlocked = "rbxassetid://4612375802", -- Unlock sound
    },
}

-- Debug function
local function logDebug(...)
    if CONFIG.debugEnabled then
        print("[RebirthClient]", ...)
    end
end

-- Type definitions
type RebirthState = {
    level: number,
    multiplier: number,
    cost: number,
    canRebirth: boolean,
    progressInfo: {[string]: any}?,
    lastUpdate: number,
}

-- Main client controller
local RebirthClient = {
    -- Internal state
    _initialized = false,
    _state = {
        level = 0,
        multiplier = 1,
        cost = 0,
        canRebirth = false,
        progressInfo = nil,
        lastUpdate = 0,
    } :: RebirthState,
    
    -- UI references
    _uiComponents = {},
    _effectsContainer = nil,
}

-- Private methods

-- Handle rebirth completed event from server
function RebirthClient:_handleRebirthCompleted(data: {[string]: any})
    logDebug("Rebirth completed", data)
    
    -- Update internal state
    self._state.level = data.newLevel
    self._state.multiplier = data.newMultiplier
    self._state.lastUpdate = os.time()
    
    -- Request fresh data
    self:RequestRebirthInfo()
    
    -- Play effects
    self:_playRebirthEffects()
    
    -- Update UI
    self:_updateUI()
    
    -- Show notification
    if NotificationSystem then
        NotificationSystem:ShowNotification({
            title = "Rebirth Complete!",
            message = string.format("You are now Rebirth Level %d with a %.2fx multiplier!", data.newLevel, data.newMultiplier),
            duration = 5,
            type = "success",
        })
    end
end

-- Handle feature unlock event from server
function RebirthClient:_handleFeatureUnlocked(features: {any})
    logDebug("Features unlocked", features)
    
    -- Play unlock effects for each feature
    for _, feature in ipairs(features) do
        self:_playUnlockEffect(feature)
        
        -- Show notification
        if NotificationSystem then
            NotificationSystem:ShowNotification({
                title = "Feature Unlocked!",
                message = string.format("%s\n%s", feature.name, feature.description),
                duration = 5,
                icon = feature.icon,
                type = "unlock",
            })
        end
    end
    
    -- Update UI after unlocks
    self:_updateUI()
end

-- Handle rebirth info update from server
function RebirthClient:_handleRebirthInfo(data: {[string]: any})
    logDebug("Rebirth info updated", data)
    
    -- Update internal state
    self._state.level = data.level
    self._state.multiplier = data.multiplier
    self._state.cost = data.cost
    self._state.canRebirth = data.canRebirth
    self._state.progressInfo = data.progressInfo
    self._state.lastUpdate = os.time()
    
    -- Update UI
    self:_updateUI()
end

-- Handle rebirth rejected event from server
function RebirthClient:_handleRebirthRejected(data: {[string]: any})
    logDebug("Rebirth rejected", data)
    
    -- Show notification
    if NotificationSystem then
        NotificationSystem:ShowNotification({
            title = "Cannot Rebirth",
            message = data.reason or "You cannot rebirth at this time",
            duration = 3,
            type = "error",
        })
    end
end

-- Play visual and audio effects for rebirth
function RebirthClient:_playRebirthEffects()
    -- Play sound effect
    local sound = Instance.new("Sound")
    sound.SoundId = CONFIG.sounds.rebirthComplete
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    
    -- Create visual effect
    if self._effectsContainer then
        -- Create particles
        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxassetid://6607841813" -- Starburst
        emitter.LightEmission = 0.5
        emitter.LightInfluence = 0.2
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 2),
            NumberSequenceKeypoint.new(1, 0.5),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.8, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 140, 0))
        emitter.Acceleration = Vector3.new(0, 10, 0)
        emitter.Drag = 5
        emitter.LockedToPart = false
        emitter.Lifetime = NumberRange.new(1, 2)
        emitter.Rate = 0
        emitter.Speed = NumberRange.new(30, 50)
        emitter.SpreadAngle = Vector2.new(0, 180)
        emitter.Parent = self._effectsContainer
        
        -- Emit particles
        emitter:Emit(50)
        
        -- Clean up after effect
        task.delay(3, function()
            emitter:Destroy()
        end)
    end
end

-- Play visual and audio effects for feature unlock
function RebirthClient:_playUnlockEffect(feature: {[string]: any})
    -- Play sound effect
    local sound = Instance.new("Sound")
    sound.SoundId = CONFIG.sounds.featureUnlocked
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    
    -- Create visual effect if container exists
    if self._effectsContainer and feature.icon then
        -- Create a floating icon that rises up
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 64, 0, 64)
        icon.Position = UDim2.new(0.5, -32, 0.5, -32)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = feature.icon
        icon.ZIndex = 10
        icon.Parent = self._effectsContainer
        
        -- Add glow effect
        local glow = Instance.new("UIGradient")
        glow.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 200)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        })
        glow.Rotation = 0
        glow.Parent = icon
        
        -- Animate the glow
        local glowTween = TweenService:Create(glow, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
            Rotation = 360
        })
        glowTween:Play()
        
        -- Float the icon upward
        local floatTween = TweenService:Create(icon, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -32, 0.3, -32),
            Size = UDim2.new(0, 96, 0, 96),
            ImageTransparency = 1
        })
        floatTween:Play()
        
        -- Clean up after animation
        task.delay(2, function()
            icon:Destroy()
        end)
    end
end

-- Update UI components with current state
function RebirthClient:_updateUI()
    -- Update all registered UI components
    for _, component in pairs(self._uiComponents) do
        if typeof(component) == "table" and component.UpdateRebirthInfo then
            component:UpdateRebirthInfo(self._state)
        end
    end
    
    -- Fire event for any other listeners
    ClientEventBridge:FireEvent("RebirthStateUpdated", self._state)
end

-- Public methods

-- Initialize the controller
function RebirthClient:Initialize()
    if self._initialized then
        return
    end
    
    logDebug("Initializing...")
    
    -- Set up event handlers
    ClientEventBridge:SubscribeToEvent("RebirthCompleted", function(data)
        self:_handleRebirthCompleted(data)
    end)
    
    ClientEventBridge:SubscribeToEvent("RebirthUnlocksGranted", function(data)
        self:_handleFeatureUnlocked(data)
    end)
    
    ClientEventBridge:SubscribeToEvent("RebirthInfoResponse", function(data)
        self:_handleRebirthInfo(data)
    end)
    
    ClientEventBridge:SubscribeToEvent("RebirthRejected", function(data)
        self:_handleRebirthRejected(data)
    end)
    
    -- Create effects container
    self._effectsContainer = Instance.new("ScreenGui")
    self._effectsContainer.Name = "RebirthEffects"
    self._effectsContainer.ResetOnSpawn = false
    self._effectsContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._effectsContainer.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Request initial rebirth info
    task.delay(1, function()
        self:RequestRebirthInfo()
    end)
    
    self._initialized = true
    logDebug("Initialization complete")
end

-- Register a UI component to receive updates
function RebirthClient:RegisterUIComponent(name: string, component: any)
    if not name or not component then
        return
    end
    
    self._uiComponents[name] = component
    
    -- Send current state to the component right away
    if typeof(component) == "table" and component.UpdateRebirthInfo then
        component:UpdateRebirthInfo(self._state)
    end
end

-- Unregister a UI component
function RebirthClient:UnregisterUIComponent(name: string)
    if name and self._uiComponents[name] then
        self._uiComponents[name] = nil
    end
end

-- Request rebirth info from the server
function RebirthClient:RequestRebirthInfo()
    ClientEventBridge:FireEvent("RequestRebirthInfo")
end

-- Request a rebirth from the server
function RebirthClient:RequestRebirth()
    -- Don't spam requests
    if os.time() - self._state.lastUpdate < 1 then
        return
    end
    
    logDebug("Requesting rebirth")
    ClientEventBridge:FireEvent("RequestRebirth")
end

-- Open the rebirth UI
function RebirthClient:OpenRebirthUI()
    -- Use UIManager if available
    if UIManager then
        UIManager:OpenScreen("RebirthScreen")
    else
        -- Use the enhanced RebirthUI if available
        local success, result = pcall(function()
            return game:GetService("StarterGui"):FindFirstChild("RebirthUI_Enhanced")
        end)
        
        if success and result then
            local enhancedUI = require(result)
            if enhancedUI and enhancedUI.showRebirthUI then
                enhancedUI.showRebirthUI()
                return
            end
        end
        
        -- Legacy fallback
        local screenGui = LocalPlayer.PlayerGui:FindFirstChild("RebirthUI")
        if screenGui then
            screenGui.Enabled = true
        end
    end
end

-- Get the current rebirth state
function RebirthClient:GetState(): RebirthState
    return table.clone(self._state)
end

-- Create the public API
local PublicAPI = {
    Initialize = function()
        RebirthClient:Initialize()
    end,
    
    RegisterUIComponent = function(name: string, component: any)
        RebirthClient:RegisterUIComponent(name, component)
    end,
    
    UnregisterUIComponent = function(name: string)
        RebirthClient:UnregisterUIComponent(name)
    end,
    
    RequestRebirthInfo = function()
        RebirthClient:RequestRebirthInfo()
    end,
    
    RequestRebirth = function()
        RebirthClient:RequestRebirth()
    end,
    
    OpenRebirthUI = function()
        RebirthClient:OpenRebirthUI()
    end,
    
    GetState = function(): RebirthState
        return RebirthClient:GetState()
    end
}

-- Register with ClientRegistry and return
return ClientRegistry.registerSystem("RebirthClient", PublicAPI, {
    "ClientEventBridge"
})
