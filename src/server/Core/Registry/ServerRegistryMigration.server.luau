--!strict
--[[
    ServerRegistryMigration.server.luau
    
    Server-side script that launches the registry migration process
    on the server. This script runs at game start to automatically
    migrate legacy registry components to the new system.
    
    Created: May 2, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Import registry modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryModules = SharedModules:WaitForChild("Registry")

local AutoMigrator = require(RegistryModules:WaitForChild("AutoMigrator"))
local RegistryBridge = require(RegistryModules:WaitForChild("RegistryBridge"))
local ServerRegistry = require(ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("Registry"):WaitForChild("ServerRegistry"))

-- Registry validation function
local function validateRegistryHealth()
    -- Validate basic registry functions
    assert(typeof(ServerRegistry.RegisterComponent) == "function", "ServerRegistry missing RegisterComponent method")
    assert(typeof(ServerRegistry.GetComponent) == "function", "ServerRegistry missing GetComponent method")
    
    -- Test basic functionality
    local testId = "TestComponent_" .. os.time()
    local testComponent = { name = testId }
    
    local success = ServerRegistry:RegisterComponent(testId, testComponent)
    assert(success, "Failed to register test component")
    
    local retrieved = ServerRegistry:GetComponent(testId)
    assert(retrieved ~= nil, "Failed to retrieve test component")
    assert(retrieved.name == testId, "Retrieved component data mismatch")
    
    print("[ServerRegistryMigration] Registry health validation passed")
    return true
end

-- Run the migration
local function runMigration()
    print("[ServerRegistryMigration] Starting server registry migration")
    
    -- First validate registry health
    if not validateRegistryHealth() then
        error("[ServerRegistryMigration] Registry health validation failed, aborting migration")
        return
    end
    
    -- Run the automigrator
    local migrationResults = AutoMigrator:Run()
    
    -- Register the migration results in ServerRegistry for reporting
    ServerRegistry:RegisterComponent("RegistryMigrationResults", migrationResults, {
        system = "registry",
        category = "migration",
        timestamp = os.time()
    })
    
    print("[ServerRegistryMigration] Server registry migration completed")
    
    -- Now that the migration is complete, update the registry status
    local migratedMessage = "[ServerRegistryMigration] Migration complete: " .. 
                            migrationResults.migratedSystems .. "/" .. 
                            migrationResults.totalSystems .. " systems migrated"
    
    print(migratedMessage)
    return migrationResults
end

-- Call the migration function with error handling
local success, results = pcall(runMigration)

if not success then
    warn("[ServerRegistryMigration] Migration failed: " .. tostring(results))
    
    -- Register the failure in ServerRegistry for reporting
    ServerRegistry:RegisterComponent("RegistryMigrationFailure", {
        error = tostring(results),
        timestamp = os.time()
    }, {
        system = "registry",
        category = "migration_error",
        critical = true
    })
end

return { 
    success = success,
    results = results
}
