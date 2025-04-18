-- RebirthClient.client.luau
-- Enhanced client-side controller for the rebirth system with unlockable content progression
-- Place in StarterPlayer/StarterPlayerScripts/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Import client-side systems
local ClientRegistry = require(script.Parent.ClientRegistry)
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
local UIManager = ClientRegistry.getSystem("UIManager")
local NotificationSystem = ClientRegistry.getSystem("NotificationSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    rebirthRemoteName = "RebirthRemote",
    
    -- Particle effects for feature unlocks
    unlockEffects = {
        duration = 2,
        color = Color3.fromRGB(255, 215, 0), -- Gold
        particleCount = 30,
        spreadRadius = 5,
        image = "rbxassetid://3084116722" -- Star particle
    },
    
    -- Sound effects
    sounds = {
        unlock = "rbxassetid://1753832226", -- Success sound
        rebirthComplete = "rbxassetid://5153734608", -- Achievement sound
        featureUnlocked = "rbxassetid://4612375802" -- Unlock sound
    }
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[RebirthClient]", ...)
    end
end

-- Main rebirth client system
local RebirthClient = {
    -- Internal state
    initialized = false,
    rebirthRemote = nil,
    rebirthInfoFunction = nil,
    
    -- Rebirth data
    rebirthCount = 0,
    rebirthCost = 100000,
    rebirthMultiplier = 0.1,
    unlockedFeatures = {},
    activePerks = {},
    achievements = {},
    nextFeature = nil,
    nextPerk = nil,
    progress = 0,
    
    -- Advanced stats
    totalRebirths = 0,
    fastestTime = 0,
    timeInCurrentRebirth = 0
}

-- Initialize the client
function RebirthClient:initialize()
    if self.initialized then return true end
    log("Initializing RebirthClient...")
    
    -- Get remote event
    self.rebirthRemote = ReplicatedStorage:WaitForChild(CONFIG.rebirthRemoteName, 10)
    if not self.rebirthRemote then
        warn("RebirthClient: Failed to find rebirth remote event")
        return false
    end
    
    -- Get remote function for direct data access
    self.rebirthInfoFunction = ReplicatedStorage:WaitForChild("GetRebirthInfoFunction", 10)
    
    -- Set up event handlers
    self:setupEventHandlers()
    
    -- Request initial rebirth information from the server
    task.spawn(function()
        task.wait(1) -- Wait a moment for connections to establish
        self:requestRebirthInfo()
    end)
    
    self.initialized = true
    log("RebirthClient initialized")
    return true
end

-- Set up event handlers
function RebirthClient:setupEventHandlers()
    -- Listen for server rebirth responses
    if not self.rebirthRemote then return end
    
    self.rebirthRemote.OnClientEvent:Connect(function(messageType, data)
        self:handleRebirthResponse(messageType, data)
    end)
    
    -- Listen for client event bridge events
    ClientEventBridge.connectEvent("TycoonDataUpdated", function(tycoonData)
        -- Update rebirth UI if tycoon data changes
        if (tycoonData and tycoonData.RebirthCount ~= nil) then
            self.rebirthCount = tycoonData.RebirthCount
            ClientEventBridge.fireEvent("RebirthDataUpdated", {
                count = self.rebirthCount,
                cost = self.rebirthCost,
                multiplier = self.rebirthMultiplier,
                unlockedFeatures = self.unlockedFeatures,
                activePerks = self.activePerks,
                achievements = self.achievements,
                nextFeature = self.nextFeature,
                nextPerk = self.nextPerk,
                progress = self.progress
            })
        end
    end)
    
    -- Listen for rebirth feature unlocks
    local rebirthFeatureEvent = ReplicatedStorage:WaitForChild("EventBridge"):WaitForChild("RebirthFeatureUnlocked", 10)
    if rebirthFeatureEvent then
        rebirthFeatureEvent.OnClientEvent:Connect(function(feature)
            self:handleFeatureUnlocked(feature)
        end)
    end
    
    -- Listen for rebirth perk unlocks
    local rebirthPerkEvent = ReplicatedStorage:WaitForChild("EventBridge"):WaitForChild("RebirthPerkUnlocked", 10)
    if rebirthPerkEvent then
        rebirthPerkEvent.OnClientEvent:Connect(function(perk)
            self:handlePerkUnlocked(perk)
        end)
    end
    
    -- Listen for rebirth achievements
    local rebirthAchievementEvent = ReplicatedStorage:WaitForChild("EventBridge"):WaitForChild("RebirthAchievementUnlocked", 10)
    if rebirthAchievementEvent then
        rebirthAchievementEvent.OnClientEvent:Connect(function(achievement)
            self:handleAchievementUnlocked(achievement)
        end)
    end
    
    -- Listen for rebirth effects
    local rebirthEffectsEvent = ReplicatedStorage:WaitForChild("EventBridge"):WaitForChild("RebirthEffects", 10)
    if rebirthEffectsEvent then
        rebirthEffectsEvent.OnClientEvent:Connect(function(effectsConfig)
            self:playRebirthEffects(effectsConfig)
        end)
    end
    
    log("Event handlers set up")
end

-- Handle responses from the server about rebirth
function RebirthClient:handleRebirthResponse(messageType, data)
    log("Received rebirth response:", messageType)
    
    if messageType == "RebirthSuccess" then
        -- Update local data
        if data and data.rebirthCount ~= nil then
            self.rebirthCount = data.rebirthCount
        end
        if data and data.newMultiplier ~= nil then
            self.rebirthMultiplier = data.newMultiplier
        end
        
        -- Request full info update after rebirth
        self:requestRebirthInfo()
        
        -- Show success notification
        if NotificationSystem then
            NotificationSystem.showNotification({
                title = "Rebirth Complete!",
                message = "You've successfully rebirthed! Your new rebirth level is " .. self.rebirthCount,
                duration = 5,
                type = "Success",
                icon = "rbxassetid://12696911020", -- Use Phoenix Rising achievement icon
                sound = CONFIG.sounds.rebirthComplete
            })
        end
        
        -- Fire event for any listening systems
        ClientEventBridge.fireEvent("RebirthCompleted", {
            count = self.rebirthCount,
            multiplier = self.rebirthMultiplier
        })
        
    elseif messageType == "NotEnoughCash" then
        -- Show error notification
        if NotificationSystem then
            NotificationSystem.showNotification({
                title = "Rebirth Failed",
                message = "You need $" .. data.required .. " to rebirth. You have $" .. data.current,
                duration = 3,
                type = "Error"
            })
        end
        
    elseif messageType == "RebirthFailed" then
        -- Show error notification
        if NotificationSystem then
            NotificationSystem.showNotification({
                title = "Rebirth Failed",
                message = data.reason or "Unknown error",
                duration = 3,
                type = "Error"
            })
        end
        
    elseif messageType == "RebirthInfo" then
        -- Update all local data with server values
        self:updateRebirthData(data)
    end
end

-- Update local rebirth data
function RebirthClient:updateRebirthData(data)
    if not data then return end
    
    -- Update basic stats
    if data.rebirthCount ~= nil then self.rebirthCount = data.rebirthCount end
    if data.cost ~= nil then self.rebirthCost = data.cost end
    if data.multiplier ~= nil then self.rebirthMultiplier = data.multiplier end
    if data.progress ~= nil then self.progress = data.progress end
    
    -- Update unlockable content
    if data.unlockedFeatures then self.unlockedFeatures = data.unlockedFeatures end
    if data.activePerks then self.activePerks = data.activePerks end
    if data.achievements then self.achievements = data.achievements end
    
    -- Update upcoming unlocks
    if data.nextFeature then self.nextFeature = data.nextFeature end
    if data.nextPerk then self.nextPerk = data.nextPerk end
    
    -- Update advanced stats
    if data.totalRebirths ~= nil then self.totalRebirths = data.totalRebirths end
    if data.fastestTime ~= nil then self.fastestTime = data.fastestTime end
    if data.timeInCurrentRebirth ~= nil then self.timeInCurrentRebirth = data.timeInCurrentRebirth end
    
    -- Fire update event
    ClientEventBridge.fireEvent("RebirthDataUpdated", {
        count = self.rebirthCount,
        cost = self.rebirthCost,
        multiplier = self.rebirthMultiplier,
        unlockedFeatures = self.unlockedFeatures,
        activePerks = self.activePerks,
        achievements = self.achievements,
        nextFeature = self.nextFeature,
        nextPerk = self.nextPerk,
        progress = self.progress,
        totalRebirths = self.totalRebirths,
        fastestTime = self.fastestTime,
        timeInCurrentRebirth = self.timeInCurrentRebirth
    })
    
    log("Rebirth data updated:", self.rebirthCount, "features:", #self.unlockedFeatures, "perks:", #self.activePerks)
end

-- Handle feature unlocked
function RebirthClient:handleFeatureUnlocked(feature)
    if not feature then return end
    
    log("Feature unlocked:", feature.name)
    
    -- Request updated info
    self:requestRebirthInfo()
    
    -- Show notification
    if NotificationSystem then
        NotificationSystem.showNotification({
            title = "Feature Unlocked!",
            message = feature.name .. " - " .. feature.description,
            duration = 8, -- Show longer for important unlocks
            type = "Achievement",
            icon = feature.icon or "rbxassetid://12696906515",
            sound = CONFIG.sounds.featureUnlocked
        })
    end
    
    -- Display visual effects
    self:playUnlockEffects(feature.name)
end

-- Handle perk unlocked
function RebirthClient:handlePerkUnlocked(perk)
    if not perk then return end
    
    log("Perk unlocked:", perk.name)
    
    -- Request updated info
    self:requestRebirthInfo()
    
    -- Show notification
    if NotificationSystem then
        NotificationSystem.showNotification({
            title = "Rebirth Perk Unlocked!",
            message = perk.name .. " - " .. perk.description,
            duration = 8, -- Show longer for important unlocks
            type = "Achievement", 
            icon = perk.icon or "rbxassetid://12696908920",
            sound = CONFIG.sounds.unlock
        })
    end
    
    -- Display visual effects
    self:playUnlockEffects(perk.name)
end

-- Handle achievement unlocked
function RebirthClient:handleAchievementUnlocked(achievement)
    if not achievement then return end
    
    log("Achievement unlocked:", achievement.name)
    
    -- Request updated info
    self:requestRebirthInfo()
    
    -- Show notification
    if NotificationSystem then
        NotificationSystem.showNotification({
            title = achievement.name,
            message = achievement.description .. (achievement.reward and ("\nReward: $" .. achievement.reward) or ""),
            duration = 8, -- Show longer for achievements
            type = "Achievement",
            icon = achievement.icon or "rbxassetid://12696911020",
            sound = CONFIG.sounds.unlock
        })
    end
end

-- Play rebirth visual effects
function RebirthClient:playRebirthEffects(effectsConfig)
    if not effectsConfig then return end
    
    -- Get config values or use defaults
    local duration = effectsConfig.transformDuration or 3
    local particleImage = effectsConfig.particleImage or "rbxassetid://3084116722"
    local particleColor = effectsConfig.particleColor or Color3.fromRGB(255, 215, 0)
    local soundId = effectsConfig.soundEffect or "rbxassetid://1753832226"
    
    log("Playing rebirth effects")
    
    -- Get player character
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Play sound effect
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 1
    sound.Parent = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    sound:Play()
    
    -- Create screen effects using UIManager if available
    if UIManager and typeof(UIManager.createScreenEffect) == "function" then
        UIManager.createScreenEffect({
            type = "flash",
            color = particleColor,
            duration = 0.5,
            fadeOut = 0.3
        })
        
        UIManager.createScreenEffect({
            type = "particles",
            image = particleImage,
            color = particleColor,
            quantity = 50,
            lifetime = duration,
            speed = {5, 10},
            size = {0.5, 1.5},
            spreadRadius = 1
        })
    else
        -- Fallback: Create screen GUI effect
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "RebirthEffect"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = LocalPlayer:FindFirstChild("PlayerGui")
        
        -- Create flash effect
        local flash = Instance.new("Frame")
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundColor3 = particleColor
        flash.BackgroundTransparency = 0.5
        flash.BorderSizePixel = 0
        flash.ZIndex = 10
        flash.Parent = screenGui
        
        -- Fade out the flash
        TweenService:Create(
            flash,
            TweenInfo.new(0.5),
            {BackgroundTransparency = 1}
        ):Play()
        
        -- Clean up
        task.delay(duration, function()
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
        end)
    end
    
    -- Clean up sound
    task.delay(duration + 2, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
end

-- Play unlock effects
function RebirthClient:playUnlockEffects(unlockName)
    -- Get configuration
    local duration = CONFIG.unlockEffects.duration
    local color = CONFIG.unlockEffects.color
    local image = CONFIG.unlockEffects.image
    local particleCount = CONFIG.unlockEffects.particleCount
    local spreadRadius = CONFIG.unlockEffects.spreadRadius
    
    log("Playing unlock effects for", unlockName)
    
    -- Create screen effects using UIManager if available
    if UIManager and typeof(UIManager.createScreenEffect) == "function" then
        UIManager.createScreenEffect({
            type = "particles",
            image = image,
            color = color,
            quantity = particleCount,
            lifetime = duration,
            speed = {2, 5},
            size = {0.2, 0.5},
            spreadRadius = spreadRadius
        })
    end
    
    -- Play unlock sound
    local sound = Instance.new("Sound")
    sound.SoundId = CONFIG.sounds.unlock
    sound.Volume = 0.8
    sound.Parent = LocalPlayer.PlayerGui
    sound:Play()
    
    -- Clean up sound
    task.delay(duration, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
end

-- Request rebirth info from server
function RebirthClient:requestRebirthInfo()
    if self.rebirthInfoFunction then
        -- Use the RemoteFunction for direct access if available
        local success, result = pcall(function()
            return self.rebirthInfoFunction:InvokeServer()
        end)
        
        if success and result then
            self:updateRebirthData(result)
            return
        end
    end
    
    -- Fall back to RemoteEvent if function fails
    if not self.rebirthRemote then return end
    
    log("Requesting rebirth information")
    self.rebirthRemote:FireServer("GetInfo")
end

-- Request rebirth from server
function RebirthClient:requestRebirth()
    if not self.rebirthRemote then return end
    
    log("Requesting rebirth")
    self.rebirthRemote:FireServer("Rebirth")
end

-- Format time as string (e.g. "2h 30m 15s")
function RebirthClient:formatTime(seconds)
    if seconds == math.huge then
        return "Never"
    end
    
    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = math.floor(seconds % 60)
    
    local result = ""
    if days > 0 then
        result = result .. days .. "d "
    end
    if hours > 0 or days > 0 then
        result = result .. hours .. "h "
    end
    if minutes > 0 or hours > 0 or days > 0 then
        result = result .. minutes .. "m "
    end
    result = result .. seconds .. "s"
    
    return result
end

-- Format cash amount
function RebirthClient:formatCash(amount)
    local formatted = tostring(math.floor(amount))
    local i = #formatted % 3
    if i == 0 then i = 3 end
    local result = formatted:sub(1, i)
    for j = i + 1, #formatted, 3 do
        result = result .. "," .. formatted:sub(j, j + 2)
    end
    return "$" .. result
end

-- Get formatted rebirth info for UI displays
function RebirthClient:getFormattedInfo()
    return {
        rebirthLevel = self.rebirthCount,
        formattedCost = self:formatCash(self.rebirthCost),
        multiplierText = string.format("%.1f", self.rebirthMultiplier * 100) .. "%",
        formattedProgress = string.format("%.1f", self.progress * 100) .. "%",
        unlockedFeatures = self.unlockedFeatures,
        activePerks = self.activePerks,
        achievements = self.achievements,
        nextFeatureText = self.nextFeature and (self.nextFeature.name .. " (Level " .. self.rebirthCount + 1 .. ")") or "None",
        nextPerkText = self.nextPerk and (self.nextPerk.name .. " (Level " .. self.rebirthCount + 1 .. ")") or "None",
        totalRebirths = self.totalRebirths,
        fastestTimeText = self:formatTime(self.fastestTime),
        currentRebirthTimeText = self:formatTime(self.timeInCurrentRebirth)
    }
end

-- Get current rebirth count
function RebirthClient:getRebirthCount()
    return self.rebirthCount
end

-- Get current rebirth cost
function RebirthClient:getRebirthCost()
    return self.rebirthCost
end

-- Get current rebirth multiplier
function RebirthClient:getRebirthMultiplier()
    return self.rebirthMultiplier
end

-- Get unlocked features
function RebirthClient:getUnlockedFeatures()
    return self.unlockedFeatures
end

-- Get active perks
function RebirthClient:getActivePerks()
    return self.activePerks
end

-- Get achievements
function RebirthClient:getAchievements()
    return self.achievements
end

-- Get current rebirth progress
function RebirthClient:getProgress()
    return self.progress
end

-- Create public API
local PublicAPI = {
    initialize = function()
        return RebirthClient:initialize()
    end,
    
    requestRebirth = function()
        return RebirthClient:requestRebirth()
    end,
    
    requestRebirthInfo = function()
        return RebirthClient:requestRebirthInfo()
    end,
    
    getRebirthCount = function()
        return RebirthClient:getRebirthCount()
    end,
    
    getRebirthCost = function()
        return RebirthClient:getRebirthCost()
    end,
    
    getRebirthMultiplier = function()
        return RebirthClient:getRebirthMultiplier()
    end,
    
    getUnlockedFeatures = function()
        return RebirthClient:getUnlockedFeatures()
    end,
    
    getActivePerks = function()
        return RebirthClient:getActivePerks()
    end,
    
    getAchievements = function()
        return RebirthClient:getAchievements()
    end,
    
    getProgress = function()
        return RebirthClient:getProgress()
    end,
    
    getFormattedInfo = function()
        return RebirthClient:getFormattedInfo()
    end
}

-- Register with ClientRegistry
return ClientRegistry.registerSystem("RebirthClient", PublicAPI, {"ClientEventBridge", "UIManager", "NotificationSystem"})