
-- FeatureManager.server.luau
-- Module to manage game features and their unlocking

local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")

local FeatureManager = {}

-- Debug function
local function log(...)
    print("[FeatureManager]", ...)
end

-- Configuration for all features
local CONFIG = {
    features = {
        ["firstFeature"] = {
            name = "First Feature",
            description = "The first feature in the game.",
            unlocked = false,
            unlockRequirement = function(playerData)
                -- Example requirement: player must have at least 1000 cash
                return playerData.cash >= 1000
            end,
        },
        ["secondFeature"] = {
            name = "Second Feature",
            description = "The second feature in the game.",
            unlocked = false,
            unlockRequirement = function(playerData)
                -- Example requirement: player must have at least 5 equipment
                return playerData.equipmentCount >= 5
            end,
        },
        ["thirdFeature"] = {
            name = "Third Feature",
            description = "The third feature in the game.",
            unlocked = false,
            unlockRequirement = function(playerData)
                -- Example requirement: player must have at least 10 members
                return playerData.members.total >= 10
            end,
        },
        -- Add more features here
    }
}

-- Initialize the module
function FeatureManager:initialize()
    log("Initializing...")

    -- Add event listeners here if needed

    log("Initialized")
end

-- Function to check if a feature is unlocked
function FeatureManager:isFeatureUnlocked(featureName, playerData)
    local feature = CONFIG.features[featureName]
    if not feature then
        log("Error: Feature not found: " .. featureName)
        return false
    end
    
    -- Check if it is already unlocked
    if feature.unlocked then
        return true
    end

    -- Check unlock requirement
    if feature.unlockRequirement and type(feature.unlockRequirement) == "function" then
        feature.unlocked = feature.unlockRequirement(playerData)
    end
    return feature.unlocked
end

-- Function to get all features data
function FeatureManager:getAllFeatures()
    return CONFIG.features
end

-- Public API
local PublicAPI = {
    initialize = function()
        FeatureManager:initialize()
    end,
    isFeatureUnlocked = function(featureName, playerData)
        return FeatureManager:isFeatureUnlocked(featureName, playerData)
    end,
    getAllFeatures = function()
        return FeatureManager:getAllFeatures()
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("FeatureManager", PublicAPI)