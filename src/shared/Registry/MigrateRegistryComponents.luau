--!strict
--[[
    MigrateRegistryComponents.luau
    
    A script that uses RegistryMigration to automatically migrate components
    from legacy registry systems to the new unified Registry System.
    
    This script should be run on both client and server to ensure all components
    are properly migrated.
    
    Author: Created April 28, 2025
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import required modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryModules = SharedModules:WaitForChild("Registry")

local RegistryMigration = require(RegistryModules:WaitForChild("RegistryMigration"))

-- Determine execution context
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

print("[RegistryMigration] Starting registry migration process...")

-- Define migration configurations for different legacy registries
local migrationConfigs = {}

-- Client Registry Migration Config
if isClient then
    local ClientRegistryModule
    
    -- Try to load the legacy ClientRegistry module
    local success, result = pcall(function()
        local CoreModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("Core")
        return require(CoreModules:WaitForChild("ClientRegistry.client"))
    end)
    
    if success then
        ClientRegistryModule = result
        print("[RegistryMigration] Found legacy ClientRegistry module")
        
        -- Create client migration config
        table.insert(migrationConfigs, {
            legacyModule = ClientRegistryModule,
            legacyNamespace = "ClientSystem",
            targetRegistry = "client",
            idTransformer = function(id)
                -- Custom ID transformation for client systems
                return "Client_" .. id:gsub("%.", "_")
            end,
            -- Version mappings for known components
            versionMap = {
                ["UISystem"] = "2.0.0",
                ["InputManager"] = "1.5.0",
                ["NotificationManager"] = "1.2.0",
                ["CharacterCustomization"] = "3.0.0",
                -- Add more as needed
            },
            -- Dependency mappings
            dependencyMap = {
                ["UISystem"] = {
                    ["Client_NotificationManager"] = "1.0.0",
                    ["Shared_UIStyle"] = "1.0.0"
                },
                -- Add more as needed
            }
        })
    else
        warn("[RegistryMigration] Failed to load legacy ClientRegistry:", result)
    end
end

-- Server Registry Migration Config
if isServer then
    local CoreRegistryModule
    
    -- Try to load the legacy CoreRegistry module
    local success, result = pcall(function()
        local ServerModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core")
        return require(ServerModules:WaitForChild("CoreRegistry.server"))
    end)
    
    if success then
        CoreRegistryModule = result
        print("[RegistryMigration] Found legacy CoreRegistry module")
        
        -- Create server migration config
        table.insert(migrationConfigs, {
            legacyModule = CoreRegistryModule,
            legacyNamespace = "ServerSystem",
            targetRegistry = "server",
            idTransformer = function(id)
                -- Custom ID transformation for server systems
                return "Server_" .. id:gsub("%.", "_")
            end,
            -- Version mappings for known components
            versionMap = {
                ["DataManager"] = "2.5.0",
                ["PlayerManager"] = "2.0.0",
                ["TycoonSystem"] = "1.8.0",
                ["NPCSystem"] = "2.2.0",
                -- Add more as needed
            },
            -- Dependency mappings 
            dependencyMap = {
                ["TycoonSystem"] = {
                    ["Server_DataManager"] = "2.0.0",
                    ["Server_PlayerManager"] = "1.5.0",
                    ["Shared_TycoonConstants"] = "1.0.0"
                },
                -- Add more as needed
            }
        })
    else
        warn("[RegistryMigration] Failed to load legacy CoreRegistry:", result)
    end
end

-- Shared Client Registry Migration Config
local SharedClientRegistryModule

-- Try to load the legacy shared ClientRegistry module
local success, result = pcall(function()
    return require(SharedModules:FindFirstChild("ClientRegistry"))
end)

if success then
    SharedClientRegistryModule = result
    print("[RegistryMigration] Found legacy shared ClientRegistry module")
    
    -- Create shared migration config
    table.insert(migrationConfigs, {
        legacyModule = SharedClientRegistryModule,
        legacyNamespace = "Shared",
        targetRegistry = "shared",
        -- Context mapping for shared components
        contextMap = {
            ["MathUtils"] = "both",
            ["Constants"] = "both",
            ["FormatUtils"] = "both",
            ["UIStyle"] = "client",
            ["ButtonFactory"] = "client",
            ["DataValidator"] = "both",
            -- Add more as needed
        }
    })
else
    warn("[RegistryMigration] Failed to load legacy shared ClientRegistry:", result)
end

-- Execute migration for each config
for _, config in ipairs(migrationConfigs) do
    print("[RegistryMigration] Starting migration for " .. config.legacyNamespace)
    
    -- Check if the legacy module has a systems table
    if config.legacyModule.systems then
        -- Extract components to migrate
        local componentsToMigrate = {}
        
        -- Process systems table based on format
        if config.legacyNamespace == "ServerSystem" then
            -- Server registry format with nested tables
            for id, info in pairs(config.legacyModule.systems) do
                componentsToMigrate[id] = info.module
            end
        else
            -- Client registry format with direct references
            for id, module in pairs(config.legacyModule.systems) do
                componentsToMigrate[id] = module
            end
        end
        
        -- Migrate the components
        local results = RegistryMigration.migrateComponents(componentsToMigrate, config)
        print("[RegistryMigration] " .. config.legacyNamespace .. " migration complete: " .. 
              results.success .. " succeeded, " .. results.failure .. " failed")
    else
        warn("[RegistryMigration] No systems table found in " .. config.legacyNamespace)
    end
    
    -- Create compatibility wrapper if needed
    if config.legacyNamespace == "ClientSystem" and isClient then
        print("[RegistryMigration] Creating ClientRegistry compatibility wrapper")
        _G.LegacyClientRegistry = RegistryMigration.createClientRegistryWrapper(config)
    elseif config.legacyNamespace == "ServerSystem" and isServer then
        print("[RegistryMigration] Creating ServerRegistry compatibility wrapper")
        _G.LegacyCoreRegistry = RegistryMigration.createServerRegistryWrapper(config)
    end
end

print("[RegistryMigration] Registry migration process complete")

-- Create global migration helper for manual migrations
_G.MigrateComponent = function(id, component, targetRegistry)
    local config = {
        legacyNamespace = string.sub(targetRegistry, 1, 1):upper() .. string.sub(targetRegistry, 2),
        targetRegistry = targetRegistry
    }
    return RegistryMigration.migrateComponent(id, component, config)
end

return true
