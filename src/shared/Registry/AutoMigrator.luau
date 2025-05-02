--!strict
--[[
    AutoMigrator.luau
    
    A utility script that automatically migrates system components 
    from the legacy registry to the new unified Registry System.
    
    This script:
    1. Scans for components registered with legacy registry systems
    2. Migrates them to appropriate new registry implementations
    3. Verifies successful migration and provides reporting
    
    Created: May 2, 2025
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

-- Determine execution context
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

-- Import registry modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryModules = SharedModules:WaitForChild("Registry")

local RegistryBridge = require(RegistryModules:WaitForChild("RegistryBridge"))
local SharedRegistry = require(RegistryModules:WaitForChild("SharedRegistry"))
local RegistryMigration = require(RegistryModules:WaitForChild("RegistryMigration"))

-- Context-specific registries
local TargetRegistry
if isServer then
    local ServerModules = ServerScriptService:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("Registry")
    TargetRegistry = require(ServerModules:WaitForChild("ServerRegistry"))
elseif isClient then
    local ClientModules = script.Parent:FindFirstChild("Registry")
    
    if ClientModules then
        TargetRegistry = require(ClientModules:WaitForChild("ClientRegistry"))
    else
        -- Try alternative paths
        local alternativePath = ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("Core"):WaitForChild("Registry")
        TargetRegistry = require(alternativePath:WaitForChild("ClientRegistry"))
    end
end

-- Legacy registry references
local LegacyRegistries = {}

-- Try to get CoreRegistry
local success, legacyServerRegistry = pcall(function()
    return require(ServerScriptService:WaitForChild("Core"):WaitForChild("CoreRegistry"))
end)

if success and legacyServerRegistry then
    table.insert(LegacyRegistries, {
        name = "CoreRegistry",
        instance = legacyServerRegistry,
        context = "server"
    })
end

-- Try to get client registry
if isClient then
    local clientSuccess, legacyClientRegistry = pcall(function()
        return require(script.Parent.Parent:WaitForChild("ClientRegistry"))
    end)
    
    if clientSuccess and legacyClientRegistry then
        table.insert(LegacyRegistries, {
            name = "ClientRegistry",
            instance = legacyClientRegistry,
            context = "client"
        })
    end
end

-- Find shared registry
local sharedSuccess, legacySharedRegistry = pcall(function()
    return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ClientRegistry"))
end)

if sharedSuccess and legacySharedRegistry then
    table.insert(LegacyRegistries, {
        name = "SharedRegistry",
        instance = legacySharedRegistry,
        context = "shared"
    })
end

-- Main migrator
local AutoMigrator = {}

-- Migration stats
AutoMigrator.Stats = {
    totalSystems = 0,
    migratedSystems = 0,
    failedSystems = {},
    startTime = 0,
    endTime = 0,
    elapsedTime = 0
}

-- Helper functions
function AutoMigrator:GetSystemsFromLegacyRegistry(registry)
    local systems = {}
    
    -- Handle different registry API patterns
    if typeof(registry.systems) == "table" then
        -- Direct table access pattern
        for name, system in pairs(registry.systems) do
            table.insert(systems, {
                name = name,
                instance = system
            })
        end
    elseif typeof(registry.GetAllSystems) == "function" then
        -- Method-based access pattern
        local success, allSystems = pcall(function()
            return registry:GetAllSystems()
        end)
        
        if success and allSystems then
            for name, system in pairs(allSystems) do
                table.insert(systems, {
                    name = name,
                    instance = system
                })
            end
        end
    end
    
    return systems
end

function AutoMigrator:ClassifySystem(systemName, systemInstance)
    -- Try to determine the appropriate registry for this system
    local systemType = "unknown"
    
    -- Look for context clues in the name
    if string.find(string.lower(systemName), "client") or 
       string.find(string.lower(systemName), "ui") or
       string.find(string.lower(systemName), "gui") then
        systemType = "client"
    elseif string.find(string.lower(systemName), "server") or
           string.find(string.lower(systemName), "data") or
           string.find(string.lower(systemName), "system") then
        systemType = "server"
    end
    
    -- Check if it's a table with typical methods
    if typeof(systemInstance) == "table" then
        -- Client-side hints
        if systemInstance.Render or systemInstance.Draw or systemInstance.UpdateUI then
            systemType = "client"
        end
        
        -- Server-side hints
        if systemInstance.ProcessServerEvent or systemInstance.SaveData or systemInstance.HandleRequest then
            systemType = "server"
        end
        
        -- Shared hints
        if systemInstance.ConvertData or systemInstance.ValidateInput or systemInstance.FormatMessage then
            systemType = "shared"
        end
    end
    
    return systemType
end

function AutoMigrator:MigrateSystem(systemName, systemInstance, systemType)
    local targetRegistry
    
    -- Choose the appropriate registry based on system type
    if systemType == "client" and isClient then
        targetRegistry = TargetRegistry
    elseif systemType == "server" and isServer then
        targetRegistry = TargetRegistry
    else
        targetRegistry = SharedRegistry
    end
    
    -- Skip if no appropriate registry is available
    if not targetRegistry then
        return false, "No appropriate registry available for " .. systemType .. " context"
    end
    
    -- Generate metadata for the migration
    local metadata = {
        migrated = true,
        originalName = systemName,
        migratedAt = os.time(),
        systemType = systemType,
        migratedBy = "AutoMigrator",
        migrationId = HttpService:GenerateGUID(false)
    }
    
    -- Attempt registration with new system
    local success, result = pcall(function()
        return targetRegistry:RegisterComponent(systemName, systemInstance, metadata)
    end)
    
    return success, success and "Success" or result
end

-- Main migration function
function AutoMigrator:Run()
    print("[AutoMigrator] Starting automatic registry migration")
    self.Stats.startTime = os.time()
    self.Stats.totalSystems = 0
    self.Stats.migratedSystems = 0
    self.Stats.failedSystems = {}
    
    -- Process each legacy registry
    for _, legacyRegistry in ipairs(LegacyRegistries) do
        print("[AutoMigrator] Processing legacy registry: " .. legacyRegistry.name)
        
        -- Get all systems from this registry
        local systems = self:GetSystemsFromLegacyRegistry(legacyRegistry.instance)
        
        for _, system in ipairs(systems) do
            self.Stats.totalSystems += 1
            
            -- Classify the system
            local systemType = self:ClassifySystem(system.name, system.instance)
            
            -- Try to migrate it
            local success, message = self:MigrateSystem(system.name, system.instance, systemType)
            
            if success then
                print("[AutoMigrator] Successfully migrated system: " .. system.name)
                self.Stats.migratedSystems += 1
            else
                warn("[AutoMigrator] Failed to migrate system: " .. system.name .. " - " .. message)
                table.insert(self.Stats.failedSystems, {
                    name = system.name,
                    reason = message
                })
            end
        end
    end
    
    -- Complete the migration
    self.Stats.endTime = os.time()
    self.Stats.elapsedTime = self.Stats.endTime - self.Stats.startTime
    
    -- Print summary
    print("=============================================")
    print("[AutoMigrator] Migration Summary:")
    print("Total systems processed: " .. self.Stats.totalSystems)
    print("Successfully migrated: " .. self.Stats.migratedSystems)
    print("Failed migrations: " .. #self.Stats.failedSystems)
    print("Elapsed time: " .. self.Stats.elapsedTime .. " seconds")
    print("=============================================")
    
    if #self.Stats.failedSystems > 0 then
        print("[AutoMigrator] Failed systems:")
        for _, failure in ipairs(self.Stats.failedSystems) do
            print("- " .. failure.name .. ": " .. failure.reason)
        end
    end
    
    return self.Stats
end

-- Run the migration automatically if this module is executed directly
if script.Name == "AutoMigrator" then
    AutoMigrator:Run()
end

return AutoMigrator
