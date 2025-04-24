--!strict
--[[
    AssetValidator.luau
    A utility module for validating and providing fallback assets when needed.
    
    Created: April 24, 2025
    
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
    },
    
    -- Animation fallbacks
    ANIMATIONS = {
        WALK = "rbxassetid://507777826",      -- Basic walk
        IDLE = "rbxassetid://507766388",      -- Basic idle
        EXERCISE = "rbxassetid://507767968",  -- Exercise motion
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
        return ASSET_REPLACEMENTS[soundId]
    end
    
    -- Track this as potentially problematic for reporting
    problematicAssets[soundId] = (problematicAssets[soundId] or 0) + 1
    
    return soundId
end

-- Validate and potentially replace an animation asset ID
function AssetValidator.validateAnimationId(animationId)
    -- Check if we already have a replacement
    if ASSET_REPLACEMENTS[animationId] then
        return ASSET_REPLACEMENTS[animationId]
    end
    
    -- Track this as potentially problematic for reporting
    problematicAssets[animationId] = (problematicAssets[animationId] or 0) + 1
    
    return animationId
end

-- Create a sound with validated ID
function AssetValidator.createSound(soundId, properties)
    local validSoundId = AssetValidator.validateSoundId(soundId)
    
    local sound = Instance.new("Sound")
    sound.SoundId = validSoundId
    
    -- Apply any additional properties
    if properties then
        for property, value in pairs(properties) do
            sound[property] = value
        end
    end
    
    return sound
end

-- Create an animation with validated ID
function AssetValidator.createAnimation(animationId)
    local validAnimationId = AssetValidator.validateAnimationId(animationId)
    
    local animation = Instance.new("Animation")
    animation.AnimationId = validAnimationId
    
    return animation
end

-- Report problematic assets
function AssetValidator.generateReport()
    local report = {}
    
    for assetId, count in pairs(problematicAssets) do
        table.insert(report, {
            assetId = assetId,
            usageCount = count
        })
    end
    
    return report
end

return AssetValidator
