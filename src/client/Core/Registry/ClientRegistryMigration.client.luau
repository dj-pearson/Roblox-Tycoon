--!strict
--[[
    ClientRegistryMigration.client.luau
    
    Client-side script that launches the registry migration process
    on the client. This script runs when the client loads to automatically
    migrate legacy registry components to the new system.
    
    Created: May 2, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import registry modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryModules = SharedModules:WaitForChild("Registry")

local AutoMigrator = require(RegistryModules:WaitForChild("AutoMigrator"))
local RegistryBridge = require(RegistryModules:WaitForChild("RegistryBridge"))
local ClientRegistryModules = script.Parent:WaitForChild("Registry")
local ClientRegistry = require(ClientRegistryModules:WaitForChild("ClientRegistry"))

-- Wait for the player to fully load
local player = Players.LocalPlayer
player.CharacterAdded:Wait()

-- Registry validation function
local function validateRegistryHealth()
    -- Validate basic registry functions
    assert(typeof(ClientRegistry.RegisterComponent) == "function", "ClientRegistry missing RegisterComponent method")
    assert(typeof(ClientRegistry.GetComponent) == "function", "ClientRegistry missing GetComponent method")
    
    -- Test basic functionality
    local testId = "TestComponent_" .. os.time()
    local testComponent = { name = testId }
    
    local success = ClientRegistry:RegisterComponent(testId, testComponent)
    assert(success, "Failed to register test component")
    
    local retrieved = ClientRegistry:GetComponent(testId)
    assert(retrieved ~= nil, "Failed to retrieve test component")
    assert(retrieved.name == testId, "Retrieved component data mismatch")
    
    print("[ClientRegistryMigration] Registry health validation passed")
    return true
end

-- Run the migration
local function runMigration()
    print("[ClientRegistryMigration] Starting client registry migration")
    
    -- First validate registry health
    if not validateRegistryHealth() then
        error("[ClientRegistryMigration] Registry health validation failed, aborting migration")
        return
    end
    
    -- Run the automigrator
    local migrationResults = AutoMigrator:Run()
    
    -- Register the migration results in ClientRegistry for reporting
    ClientRegistry:RegisterComponent("RegistryMigrationResults", migrationResults, {
        system = "registry",
        category = "migration",
        timestamp = os.time()
    })
    
    print("[ClientRegistryMigration] Client registry migration completed")
    
    -- Now that the migration is complete, update the registry status
    local migratedMessage = "[ClientRegistryMigration] Migration complete: " .. 
                            migrationResults.migratedSystems .. "/" .. 
                            migrationResults.totalSystems .. " systems migrated"
    
    print(migratedMessage)
    return migrationResults
end

-- Call the migration function with error handling
local success, results = pcall(runMigration)

if not success then
    warn("[ClientRegistryMigration] Migration failed: " .. tostring(results))
    
    -- Register the failure in ClientRegistry for reporting
    ClientRegistry:RegisterComponent("RegistryMigrationFailure", {
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
