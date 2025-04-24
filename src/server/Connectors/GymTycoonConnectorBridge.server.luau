-- GymTycoonConnectorBridge.luau
-- Bridging module between the two GymTycoonConnector implementations
-- Place in ServerScriptService/Connectors

local ServerScriptService = game:GetService("ServerScriptService")

-- Get references to the CoreRegistry
local CoreRegistry
if _G.CoreRegistry then
    CoreRegistry = _G.CoreRegistry
else
    local success, result = pcall(function()
        return require(ServerScriptService.Core.CoreRegistry)
    end)
    
    if success then
        CoreRegistry = result
    else
        warn("[GymTycoonConnectorBridge] Failed to get CoreRegistry")
        return {}
    end
end

local Bridge = {}

-- Private debug function
local function log(...)
    print("[GymTycoonConnectorBridge]", ...)
end

-- Initialize the bridge
function Bridge:initialize()
    log("Initializing bridge between GymTycoonConnector implementations")
    
    -- Get core connector from Core folder
    self.coreConnector = CoreRegistry.getSystem("GymTycoonConnector")
    
    -- Get bridge connector from Connectors folder
    local success, connectorBridge = pcall(function() 
        return require(ServerScriptService.Connectors.GymTycoonConnector)
    end)
    
    if success and connectorBridge then
        self.connectorBridge = connectorBridge
        
        -- Initialize bridge connector if needed and it has an initialize function
        if typeof(self.connectorBridge.initialize) == "function" then
            self.connectorBridge:initialize()
        end
        
        log("Successfully connected both GymTycoonConnector implementations")
    else
        log("Warning: Could not find both GymTycoonConnector implementations")
    end
    
    -- Make bridge publicly accessible for debugging
    _G.GymTycoonConnectorBridge = self
    
    return true
end

-- Forward method calls between connector implementations
function Bridge:forwardMethod(methodName, ...)
    local result = nil
    
    -- Try core connector first
    if self.coreConnector and typeof(self.coreConnector[methodName]) == "function" then
        result = self.coreConnector[methodName](self.coreConnector, ...)
    end
    
    -- Try bridge connector
    if self.connectorBridge and typeof(self.connectorBridge[methodName]) == "function" then
        local bridgeResult = self.connectorBridge[methodName](...)
        
        -- If core connector didn't return a value, use bridge result
        if result == nil then
            result = bridgeResult
        end
    end
    
    return result
end

-- Legacy API compatibility layer
local BridgedAPI = {
    initialize = function()
        return Bridge:initialize()
    end,
    
    -- Methods from core connector
    onTilePurchased = function(player, tileId)
        return Bridge:forwardMethod("onTilePurchased", player, tileId)
    end,
    
    onDuesCollected = function(player, amount)
        return Bridge:forwardMethod("onDuesCollected", player, amount)
    end,
    
    fixTycoonReference = function(player)
        return Bridge:forwardMethod("fixTycoonReference", player)
    end,
    
    setupPlayer = function(player)
        return Bridge:forwardMethod("setupPlayer", player)
    end,
    
    -- Methods from bridge connector
    updateFrontDesk = function(player)
        return Bridge:forwardMethod("updateFrontDesk", player)
    end,
    
    getFrontDesk = function(player)
        return Bridge:forwardMethod("getFrontDesk", player)
    end,
    
    getAllPlayersFrontDesks = function()
        return Bridge:forwardMethod("getAllPlayersFrontDesks")
    end,
    
    getLegacySystems = function()
        return Bridge:forwardMethod("getLegacySystems")
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("GymTycoonConnectorBridge", BridgedAPI, {"GymTycoonConnector", "EventBridge"})