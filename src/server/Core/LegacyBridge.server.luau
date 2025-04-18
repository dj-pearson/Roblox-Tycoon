-- LegacyBridge.luau
-- Helper script to bridge between old scripts and the new core system
-- Place in ServerScriptService/Core

-- Get core systems
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")
local DataManager = CoreRegistry.getSystem("DataManager")
local NPCSystem = CoreRegistry.getSystem("NPCSystem")
local GymTycoonConnector = CoreRegistry.getSystem("GymTycoonConnector")

print("=== Legacy Bridge ===")
print("Creating compatibility bridges for legacy scripts...")

-- Create global references for backward compatibility
_G.LegacyBridge = {
    version = "1.0",
    active = true
}

-- Create backward compatibility for DataStorageSystem
if not _G.DataStorageSystem and DataManager then
    _G.DataStorageSystem = {
        loadData = function(player)
            print("[LegacyBridge] Redirecting DataStorageSystem.loadData to DataManager")
            return DataManager.loadData(player)
        end,
        
        saveData = function(player, immediate)
            print("[LegacyBridge] Redirecting DataStorageSystem.saveData to DataManager")
            return DataManager.saveData(player, immediate)
        end,
        
        getDefaultData = function()
            print("[LegacyBridge] Redirecting DataStorageSystem.getDefaultData to DataManager")
            return DataManager.getDefaultData()
        end
    }
    
    print("Created legacy bridge for DataStorageSystem")
end

-- Create backward compatibility for UnifiedNPCSystem
if not _G.UnifiedNPCSystem and NPCSystem then
    _G.UnifiedNPCSystem = {
        initialize = function()
            print("[LegacyBridge] Redirecting UnifiedNPCSystem.initialize to NPCSystem")
            return true -- Already initialized
        end,
        
        trySpawnNPC = function(player)
            print("[LegacyBridge] Redirecting UnifiedNPCSystem.trySpawnNPC to NPCSystem")
            return NPCSystem.trySpawnNPC(player)
        end,
        
        initializePlayerNPCs = function(player)
            print("[LegacyBridge] Redirecting UnifiedNPCSystem.initializePlayerNPCs to NPCSystem")
            return NPCSystem.initializePlayerNPCs(player)
        end,
        
        fixNPCCollisions = function()
            print("[LegacyBridge] Redirecting UnifiedNPCSystem.fixNPCCollisions to NPCSystem")
            return NPCSystem.fixNPCCollisions()
        end,
        
        CONFIG = NPCSystem.getConfig()
    }
    
    print("Created legacy bridge for UnifiedNPCSystem")
end

-- Create backward compatibility for GymTycoonConnector
if not _G.GymTycoonConnector_Legacy and GymTycoonConnector then
    _G.GymTycoonConnector_Legacy = {
        onTilePurchased = function(player, tileId)
            print("[LegacyBridge] Redirecting GymTycoonConnector.onTilePurchased")
            return GymTycoonConnector:onTilePurchased(player, tileId)
        end,
        
        onDuesCollected = function(player, amount)
            print("[LegacyBridge] Redirecting GymTycoonConnector.onDuesCollected")
            return GymTycoonConnector:onDuesCollected(player, amount)
        end,
        
        fixTycoonReference = function(player)
            print("[LegacyBridge] Redirecting GymTycoonConnector.fixTycoonReference")
            return GymTycoonConnector:fixTycoonReference(player)
        end,
        
        setupPlayer = function(player)
            print("[LegacyBridge] Redirecting GymTycoonConnector.setupPlayer")
            return GymTycoonConnector:setupPlayer(player)
        end
    }
    
    print("Created legacy bridge for GymTycoonConnector")
end

-- Create event connection compatibilities
if EventBridge then
    -- Connect legacy event names if needed
    local legacyEvents = {
        ["onTilePurchased"] = "TilePurchased",
        ["onDuesCollected"] = "DuesCollected",
        ["onNPCSpawned"] = "NPCSpawned",
        ["onGymLevelUp"] = "GymLevelUp"
    }
    
    for legacyName, newName in pairs(legacyEvents) do
        EventBridge:connectEvent(newName, function(...)
            -- If there's a legacy event handler, call it
            if _G[legacyName] and type(_G[legacyName]) == "function" then
                print("[LegacyBridge] Forwarding " .. newName .. " event to legacy handler " .. legacyName)
                _G[legacyName](...)
            end
        end)
    end
    
    print("Created legacy event bridges")
end

-- Detect references to old systems and print migration warnings
local function checkOldSystemReferences()
    local oldSystems = {
        "NPCSystemIntegration",
        "NPCSpawner",
        "GymTycoonManager",
        "PlayerDataManager",
        "SystemManager"
    }
    
    task.spawn(function()
        task.wait(10) -- Wait for all scripts to load
        
        for _, systemName in ipairs(oldSystems) do
            if _G[systemName] then
                warn("[LegacyBridge] Detected reference to old system: " .. systemName .. ". Consider migrating to the new core systems.")
            end
        end
    end)
end

checkOldSystemReferences()

print("Legacy Bridge initialized successfully")
print("=======================")

-- Return the bridge module
return _G.LegacyBridge