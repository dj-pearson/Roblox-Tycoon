--!strict
--[[
    CoreRegistryBridge.server.luau
    
    Bridge module for ensuring backward compatibility with existing systems
    while providing access to enhanced CoreRegistry features.
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Bridge module
local CoreRegistryBridge = {}

-- Private state
local bridgeInitialized = false
local enhancedRegistry = nil

-- Debug logging
local function log(message, level)
    local prefix = "[CoreRegistryBridge]"
    if level == "error" then
        warn(prefix .. " ERROR: " .. message)
    elseif level == "warn" then
        warn(prefix .. " WARNING: " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Initialize the bridge
function CoreRegistryBridge.initialize()
    if bridgeInitialized then
        return true
    end
    
    log("Initializing CoreRegistryBridge...")
    
    -- Try to load enhanced registry
    local success, result = pcall(function()
        return require(script.Parent.CoreRegistry_enhanced)
    end)
    
    if not success then
        log("Failed to load enhanced CoreRegistry: " .. tostring(result), "error")
        return false
    end
    
    enhancedRegistry = result
    
    -- Initialize enhanced registry
    success, result = pcall(function()
        return enhancedRegistry:initialize()
    end)
    
    if not success then
        log("Failed to initialize enhanced CoreRegistry: " .. tostring(result), "error")
        return false
    end
    
    bridgeInitialized = true
    log("CoreRegistryBridge initialized")
    return true
end

-- Forward method calls to enhanced registry
setmetatable(CoreRegistryBridge, {
    __index = function(_, key)
        if not bridgeInitialized then
            CoreRegistryBridge.initialize()
        end
        
        if enhancedRegistry and typeof(enhancedRegistry[key]) == "function" then
            return function(_, ...)
                return enhancedRegistry[key](enhancedRegistry, ...)
            end
        end
        
        return nil
    end
})

-- Initialize bridge
CoreRegistryBridge.initialize()

return CoreRegistryBridge 