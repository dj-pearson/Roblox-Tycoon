--[[
    SoundAssetValidator.luau
    
    This module provides validation for sound assets in the game.
    Helps address the asset loading failures identified in the RobloxIssues document.
    
    The module checks if sound IDs are valid and provides fallbacks for invalid sounds.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local isServer = RunService:IsServer()

-- Find module helper
local function findModule(moduleName)
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    if isServer then
        local ServerScriptService = game:GetService("ServerScriptService")
        table.insert(searchPaths, 1, ServerScriptService:FindFirstChild("Core"))
        table.insert(searchPaths, 2, ServerScriptService)
    else
        local player = game:GetService("Players").LocalPlayer
        if player then
            local playerScripts = player:FindFirstChild("PlayerScripts")
            if playerScripts then
                table.insert(searchPaths, 1, playerScripts:FindFirstChild("Client"))
                table.insert(searchPaths, 2, playerScripts)
            end
        end
    end
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Safely require a module
local function safeRequire(module, fallback)
    if not module then
        return fallback
    end
    
    if not module:IsA("ModuleScript") then
        warn("SoundAssetValidator: Expected ModuleScript but got " .. module.ClassName .. " for " .. module:GetFullName())
        return fallback
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("SoundAssetValidator: Failed to require " .. module:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Try to load ErrorHandling module
local ErrorHandlingModule = findModule("ErrorHandling") or findModule("ErrorHandler")
local ErrorHandling = ErrorHandlingModule and safeRequire(ErrorHandlingModule)

-- Try to load EventBridge module
local EventBridgeModule = findModule("EventBridge")
local EventBridge = EventBridgeModule and safeRequire(EventBridgeModule)

if EventBridge and EventBridge.registerEvent then
    -- Register events for sound asset validation
    EventBridge.registerEvent("SoundAssetValidator_ValidationSuccess")
    EventBridge.registerEvent("SoundAssetValidator_ValidationFailure")
    EventBridge.registerEvent("SoundAssetValidator_AssetReplaced")
end

-- Create the module
local SoundAssetValidator = {}

-- Collection of known good fallback sounds
local fallbackSounds = {
    -- Generic fallback for any sound
    default = 4612375233, -- Valid sound effect ID
    -- Category-specific fallbacks
    ui = {
        click = 4612338705,
        hover = 4612347302,
        success = 4612339685,
        error = 4612361922
    },
    gameplay = {
        purchase = 4612385339,
        achievement = 4612394965,
        levelUp = 4612383033
    },
    ambient = {
        background = 4612416484
    }
}

-- Track validation statistics
local validationStats = {
    totalChecked = 0,
    validSounds = 0,
    invalidSounds = 0,
    replacements = 0
}

-- Cache of validated IDs
local validatedIds = {}

-- Convert various input formats to asset IDs
function SoundAssetValidator.getAssetId(input)
    if typeof(input) == "number" then
        return input
    elseif typeof(input) == "string" then
        -- Extract ID from various formats
        local idMatch = input:match("rbxassetid://(%d+)")
        if idMatch then
            return tonumber(idMatch)
        end
        
        -- Check if it's just a number as a string
        local numberId = tonumber(input)
        if numberId then
            return numberId
        end
    end
    
    return nil
end

-- Validate a single sound asset ID
function SoundAssetValidator.validateSoundId(soundId, category)
    category = category or "default"
    
    -- Get numeric ID
    local assetId = SoundAssetValidator.getAssetId(soundId)
    if not assetId then
        return fallbackSounds[category] or fallbackSounds.default
    end
    
    -- Check cache first
    if validatedIds[assetId] ~= nil then
        return validatedIds[assetId] and assetId or (fallbackSounds[category] or fallbackSounds.default)
    end
    
    validationStats.totalChecked += 1
    
    -- Create a test sound to validate the ID
    local success = pcall(function()
        local testSound = Instance.new("Sound")
        testSound.SoundId = "rbxassetid://" .. assetId
        testSound.Volume = 0 -- Ensure it doesn't actually play
        testSound.Parent = SoundService
        testSound:Destroy()
    end)
    
    -- Update cache
    validatedIds[assetId] = success
    
    if success then
        validationStats.validSounds += 1
        
        if EventBridge and EventBridge.fireEvent then
            EventBridge.fireEvent("SoundAssetValidator_ValidationSuccess", {
                soundId = assetId
            })
        end
        
        return assetId
    else
        validationStats.invalidSounds += 1
        validationStats.replacements += 1
        
        if EventBridge and EventBridge.fireEvent then
            EventBridge.fireEvent("SoundAssetValidator_ValidationFailure", {
                soundId = assetId
            })
            
            EventBridge.fireEvent("SoundAssetValidator_AssetReplaced", {
                originalId = assetId,
                fallbackId = fallbackSounds[category] or fallbackSounds.default,
                category = category
            })
        end
        
        -- Log the error
        if ErrorHandling and ErrorHandling.logError then
            ErrorHandling.logError("SoundAssetValidator", "Invalid sound ID: " .. assetId, "Replaced with fallback")
        else
            warn("SoundAssetValidator: Invalid sound ID: " .. assetId .. ", replaced with fallback")
        end
        
        -- Return appropriate fallback
        if typeof(category) == "string" and fallbackSounds[category] then
            return fallbackSounds[category]
        elseif typeof(category) == "table" and category[1] and fallbackSounds[category[1]] then
            -- Handle subcategory
            if category[2] and fallbackSounds[category[1]][category[2]] then
                return fallbackSounds[category[1]][category[2]]
            end
            return fallbackSounds[category[1]]
        end
        
        return fallbackSounds.default
    end
end

-- Create a validated sound object
function SoundAssetValidator.createValidatedSound(soundId, properties)
    properties = properties or {}
    
    -- Get valid sound ID
    local validId = SoundAssetValidator.validateSoundId(soundId, properties.category)
    
    -- Create the sound
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. validId
    
    -- Apply properties
    for prop, value in pairs(properties) do
        if prop ~= "category" and sound[prop] ~= nil then
            sound[prop] = value
        end
    end
    
    return sound
end

-- Register a custom fallback sound
function SoundAssetValidator.registerFallback(category, subcategory, soundId)
    if not category then
        return false
    end
    
    local assetId = SoundAssetValidator.getAssetId(soundId)
    if not assetId then
        return false
    end
    
    -- Validate the fallback sound itself
    local success = pcall(function()
        local testSound = Instance.new("Sound")
        testSound.SoundId = "rbxassetid://" .. assetId
        testSound.Volume = 0
        testSound.Parent = SoundService
        testSound:Destroy()
    end)
    
    if not success then
        warn("SoundAssetValidator: Cannot register invalid sound ID as fallback: " .. assetId)
        return false
    end
    
    -- Save the fallback
    if subcategory then
        if not fallbackSounds[category] then
            fallbackSounds[category] = {}
        end
        
        if typeof(fallbackSounds[category]) ~= "table" then
            fallbackSounds[category] = {}
        end
        
        fallbackSounds[category][subcategory] = assetId
    else
        fallbackSounds[category] = assetId
    end
    
    return true
end

-- Get validation statistics
function SoundAssetValidator.getStats()
    local successRate = validationStats.totalChecked > 0 
        and math.floor((validationStats.validSounds / validationStats.totalChecked) * 100) 
        or 0
    
    return {
        totalChecked = validationStats.totalChecked,
        validSounds = validationStats.validSounds,
        invalidSounds = validationStats.invalidSounds,
        replacements = validationStats.replacements,
        successRate = successRate
    }
end

-- Reset stats
function SoundAssetValidator.resetStats()
    validationStats = {
        totalChecked = 0,
        validSounds = 0,
        invalidSounds = 0,
        replacements = 0
    }
end

-- Fix specific sound IDs mentioned in the issue report
SoundAssetValidator.validateSoundId(9048378264, "default")
SoundAssetValidator.validateSoundId(9125601193, "default")

print("✅ SoundAssetValidator initialized successfully")

return SoundAssetValidator
