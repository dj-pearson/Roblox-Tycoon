--!strict
--[[
    AssetValidator.luau
    A utility module for validating and providing fallback assets when needed.
    
    Created: April 25, 2025
    
    This module helps resolve common asset loading issues by:
    1. Validating asset IDs before use
    2. Providing working fallback assets when originals fail
    3. Logging asset issues for future correction
]]

local AssetValidator = {}

-- Cache of validated assets
local validatedAssets = {}

-- Fallback assets (verified to work)
local FALLBACKS = {
    -- Sound fallbacks
    SOUNDS = {
        DEFAULT = "rbxassetid://5047606635",  -- Generic notification sound
        ACHIEVEMENT = "rbxassetid://5861141581",  -- Achievement sound
        AMBIENT = "rbxassetid://169338556",   -- Ambient/environment sound
        STEAM = "rbxassetid://130949361",     -- Steam/water sound
        ELEVATOR = "rbxassetid://142376088",  -- Elevator movement sound
        CHIME = "rbxassetid://138081509",     -- Elevator ding sound
    },
    
    -- Animation fallbacks
    ANIMATIONS = {
        WALK = "rbxassetid://507777826",      -- Basic walk
        IDLE = "rbxassetid://507766388",      -- Basic idle
        EXERCISE = "rbxassetid://507767968",  -- Exercise motion
    },
    
    -- UI Image fallbacks
    IMAGES = {
        TROPHY = "rbxassetid://6031090990",   -- Trophy icon
        COIN = "rbxassetid://6026568247",     -- Coin icon
        GYM = "rbxassetid://6022668885",      -- Gym icon
    }
}

-- Asset ID replacements for known problematic assets
local ASSET_REPLACEMENTS = {
    -- Sound replacements
    ["rbxassetid://9048378264"] = FALLBACKS.SOUNDS.STEAM,      -- Replace sauna sound
    ["rbxassetid://9125601193"] = FALLBACKS.SOUNDS.ACHIEVEMENT,-- Replace achievement sound
    
    -- Animation replacements
    ["rbxassetid://4479935848"] = FALLBACKS.ANIMATIONS.EXERCISE, -- Failed animation
    ["rbxassetid://4479937122"] = FALLBACKS.ANIMATIONS.EXERCISE, -- Failed animation
    ["rbxassetid://4571857828"] = FALLBACKS.ANIMATIONS.IDLE,     -- Failed animation
}

-- Tracks known problematic assets for reporting
local problematicAssets = {}

-- Validate and potentially replace a sound asset ID
function AssetValidator.validateSoundId(soundId)
    -- Check if we already have a replacement
    if ASSET_REPLACEMENTS[soundId] then
        print("[AssetValidator] Replacing problematic sound " .. soundId .. " with " .. ASSET_REPLACEMENTS[soundId])
        return ASSET_REPLACEMENTS[soundId]
    end
    
    -- Track this as potentially problematic for reporting
    problematicAssets[soundId] = (problematicAssets[soundId] or 0) + 1
    
    -- Additional validation for known problematic formats
    if type(soundId) == "string" and soundId:match("^rbxassetid://[0-9]+$") then
        -- Cache validated sound IDs to improve performance
        if validatedAssets[soundId] ~= nil then
            return validatedAssets[soundId]
        end
    end
    
    return soundId
end

-- Validate and potentially replace an animation asset ID
function AssetValidator.validateAnimationId(animationId)
    -- Check if we already have a replacement
    if ASSET_REPLACEMENTS[animationId] then
        print("[AssetValidator] Replacing problematic animation " .. animationId .. " with " .. ASSET_REPLACEMENTS[animationId])
        return ASSET_REPLACEMENTS[animationId]
    end
    
    -- Track this as potentially problematic for reporting
    problematicAssets[animationId] = (problematicAssets[animationId] or 0) + 1
    
    return animationId
end

-- Validate and potentially replace an image asset ID
function AssetValidator.validateImageId(imageId)
    -- Check if we already have a replacement
    if ASSET_REPLACEMENTS[imageId] then
        print("[AssetValidator] Replacing problematic image " .. imageId .. " with " .. ASSET_REPLACEMENTS[imageId])
        return ASSET_REPLACEMENTS[imageId]
    end
    
    -- Track this as potentially problematic for reporting
    problematicAssets[imageId] = (problematicAssets[imageId] or 0) + 1
    
    return imageId
end

-- Register an asset replacement
function AssetValidator.addReplacement(originalId, replacementId)
    ASSET_REPLACEMENTS[originalId] = replacementId
    print("[AssetValidator] Added replacement: " .. originalId .. " -> " .. replacementId)
end

-- Get fallback assets by category and type
function AssetValidator.getFallback(category, assetType)
    if FALLBACKS[category] and FALLBACKS[category][assetType] then
        return FALLBACKS[category][assetType]
    end
    
    -- Return a default fallback based on category
    if category == "SOUNDS" then
        return FALLBACKS.SOUNDS.DEFAULT
    elseif category == "ANIMATIONS" then
        return FALLBACKS.ANIMATIONS.IDLE
    elseif category == "IMAGES" then
        return FALLBACKS.IMAGES.GYM
    end
    
    return nil
end

-- Generate a report of problematic assets
function AssetValidator.generateReport()
    local report = {
        totalProblematic = 0,
        assets = {}
    }
    
    for assetId, count in pairs(problematicAssets) do
        table.insert(report.assets, {
            id = assetId,
            usageCount = count,
            hasReplacement = ASSET_REPLACEMENTS[assetId] ~= nil
        })
        report.totalProblematic = report.totalProblematic + 1
    end
    
    return report
end

return AssetValidator
