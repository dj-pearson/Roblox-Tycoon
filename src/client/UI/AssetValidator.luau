-- AssetValidator.luau
-- A simple module for validating assets
-- Created: April 30, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local AssetValidator = {
    initialized = false,
    DEBUG = true,
    cache = {}
}

-- Simple logging function
local function log(message, level)
    if not AssetValidator.DEBUG and level ~= "Error" then return end
    
    local prefix = "[AssetValidator]"
    if level == "Error" then
        warn(prefix .. " " .. message)
    elseif level == "Success" then
        print(prefix .. " ✓ " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Validate an asset by ID
function AssetValidator:ValidateAsset(assetId)
    if not assetId or typeof(assetId) ~= "string" then
        log("Invalid assetId provided", "Error")
        return false
    end
    
    -- Check cache first
    if self.cache[assetId] ~= nil then
        return self.cache[assetId]
    end
    
    -- Basic validation check for rbxassetid format
    if not assetId:match("^rbxassetid://[0-9]+$") and not assetId:match("^http") then
        log("Asset ID format invalid: " .. assetId, "Error")
        self.cache[assetId] = false
        return false
    end
    
    -- Attempt to preload the asset to verify it exists
    local success = pcall(function()
        ContentProvider:PreloadAsync({assetId})
    end)
    
    -- Cache the result
    self.cache[assetId] = success
    
    if not success then
        log("Failed to validate asset: " .. assetId, "Error")
    else
        log("Successfully validated asset: " .. assetId, "Success")
    end
    
    return success
end

-- Initialize module
function AssetValidator:initialize()
    if self.initialized then
        return
    end
    
    log("Initializing AssetValidator")
    
    -- Register with ClientRegistry if available
    local ClientRegistry = nil
    
    -- First try direct requiring
    local success, result = pcall(function()
        return require(script.Parent.Parent:FindFirstChild("ClientRegistry"))
    end)
    
    if success and result then
        ClientRegistry = result
    else
        -- Try to find in player scripts
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local PlayerScripts = player and player:FindFirstChild("PlayerScripts")
        
        if PlayerScripts and PlayerScripts:FindFirstChild("ClientRegistry") then
            ClientRegistry = require(PlayerScripts.ClientRegistry)
        elseif ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ClientRegistry") then
            ClientRegistry = require(ReplicatedStorage.shared.ClientRegistry)
        end
    end
    
    if ClientRegistry and typeof(ClientRegistry.Register) == "function" then
        ClientRegistry:Register("AssetValidator", self)
        log("Registered with ClientRegistry", "Success")
    else
        log("ClientRegistry not found, could not register", "Error")
    end
    
    self.initialized = true
    log("AssetValidator initialized", "Success")
    return true
end

-- Get a specific interface for the client
function AssetValidator:getClientInterface()
    return self
end

-- Initialize on require
task.spawn(function()
    AssetValidator:initialize()
end)

return AssetValidator
