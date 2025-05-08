--!strict
--[[
    DataManagerBridge.server.luau
    
    Bridge module to handle the transition to the enhanced DataManager.
    This module ensures backward compatibility while providing access to
    the enhanced features of the new DataManager.
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import the enhanced DataManager
local EnhancedDataManager = require(script.Parent:WaitForChild("DataManager_enhanced"))

-- Create the bridge module
local DataManagerBridge = {
    initialized = false,
    version = "1.0.0"
}

-- Debug logging
local function log(message, level)
    level = level or "Info"
    print(string.format("[DataManagerBridge][%s] %s", level, message))
end

-- Initialize the bridge
function DataManagerBridge:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DataManagerBridge v" .. self.version)
    
    -- Initialize the enhanced DataManager
    local success = EnhancedDataManager:initialize()
    if not success then
        log("Failed to initialize enhanced DataManager", "Error")
        return false
    end
    
    -- Register with CoreRegistry if available
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("DataManager", self)
        log("Registered with CoreRegistry")
    end
    
    self.initialized = true
    log("DataManagerBridge initialized successfully")
    return true
end

-- Forward all method calls to the enhanced DataManager
setmetatable(DataManagerBridge, {
    __index = function(_, key)
        if typeof(EnhancedDataManager[key]) == "function" then
            return function(self, ...)
                return EnhancedDataManager[key](EnhancedDataManager, ...)
            end
        end
        return EnhancedDataManager[key]
    end
})

-- Initialize the bridge
DataManagerBridge:initialize()

return DataManagerBridge 