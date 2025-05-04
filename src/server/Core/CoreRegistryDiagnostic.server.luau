--[[
    CoreRegistryDiagnostic.server.luau
    
    Diagnostic script to check the status of CoreRegistry and verify that all required systems
    are properly registered and functioning. This script reports detailed status information
    and can be used to verify that fixes have been successfully applied.
    
    Created: May 4, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    criticalSystems = {
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem",
        "TycoonSystem",
        "EventBridge"
    },
    debug = true
}

-- Debug logging
local function log(...)
    if CONFIG.debug then
        print("[CoreRegistryDiagnostic]", ...)
    end
end

-- Find CoreRegistry
local function findCoreRegistry()
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService:FindFirstChild("src"):FindFirstChild("server") and ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Core"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and path:FindFirstChild("CoreRegistry") then
            local success, module = pcall(function()
                return require(path.CoreRegistry)
            end)
            
            if success and type(module) == "table" and module.registerSystem then
                log("Found CoreRegistry at:", path.CoreRegistry:GetFullName())
                return module
            end
        end
    end
    
    log("Could not find CoreRegistry")
    return nil
end

-- Check registry status
local function checkRegistryStatus()
    log("Starting CoreRegistry diagnostic check...")
    
    local results = {
        coreRegistryFound = false,
        registryStatus = "Unknown",
        missingSystems = {},
        placeholderSystems = {},
        systemsFound = {},
        allCriticalSystemsPresent = false
    }
    
    -- Find the CoreRegistry
    local CoreRegistry = findCoreRegistry()
    if not CoreRegistry then
        log("ERROR: CoreRegistry not found")
        results.coreRegistryFound = false
        return results
    end
    
    results.coreRegistryFound = true
    
    -- Check registry status
    if CoreRegistry.getRegistryStatus then
        results.registryStatus = CoreRegistry:getRegistryStatus()
        log("CoreRegistry status:", results.registryStatus)
    end
    
    -- Check for critical systems
    local allSystemsPresent = true
    
    for _, systemName in ipairs(CONFIG.criticalSystems) do
        local system = CoreRegistry.getSystem and CoreRegistry:getSystem(systemName)
        
        if system then
            log("✓ Found system:", systemName)
            
            -- Check if it's a placeholder
            if system._isPlaceholder then
                log("  ⚠️ Note: This is a placeholder implementation")
                table.insert(results.placeholderSystems, systemName)
            else
                table.insert(results.systemsFound, systemName)
            end
        else
            log("✗ Missing system:", systemName)
            table.insert(results.missingSystems, systemName)
            allSystemsPresent = false
        end
    end
    
    results.allCriticalSystemsPresent = allSystemsPresent
    
    -- Report final status
    if allSystemsPresent then
        log("✓ All critical systems present")
        
        if #results.placeholderSystems > 0 then
            log("⚠️ However, some systems are placeholders")
        end
    else
        log("✗ Some critical systems are missing")
    end
    
    return results
end

-- Run the diagnostic
local diagnosticResults = checkRegistryStatus()

-- Return the results
return diagnosticResults
