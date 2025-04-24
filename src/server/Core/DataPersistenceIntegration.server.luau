--[[
    DataPersistenceIntegration.server.luau
    
    A utility script that automatically integrates the new data persistence system with
    existing game systems. This script runs at startup and patches/hooks into other systems
    to ensure they use the standardized DataAccessLayer.
    
    Author: Created April 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Find CoreRegistry
local CoreRegistry
local function findCoreRegistry()
    -- Try to require from common locations
    local success, result
    local possiblePaths = {
        ServerScriptService:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("Systems") and ServerScriptService.Core.Systems:FindFirstChild("CoreRegistry"),
    }
    
    for _, path in ipairs(possiblePaths) do
        if path and path:IsA("ModuleScript") then
            success, result = pcall(function()
                return require(path)
            end)
            
            if success then
                return result
            end
        end
    end
    
    return nil
end

CoreRegistry = findCoreRegistry()

-- Get required systems
local DataAccessLayer
local VersionedDataStore 
local DataMigrationUtility

if CoreRegistry then
    DataAccessLayer = CoreRegistry:GetSystem("DataAccessLayer")
    VersionedDataStore = CoreRegistry:GetSystem("VersionedDataStore")
    DataMigrationUtility = CoreRegistry:GetSystem("DataMigrationUtility")
end

-- Try to load directly if not found in CoreRegistry
if not DataAccessLayer then
    pcall(function()
        local path = ServerScriptService:FindFirstChild("Core") and 
                    ServerScriptService.Core:FindFirstChild("DataAccessLayer")
        if path then
            DataAccessLayer = require(path)
        end
    end)
end

if not VersionedDataStore then
    pcall(function()
        local path = ServerScriptService:FindFirstChild("Core") and 
                    ServerScriptService.Core:FindFirstChild("VersionedDataStore")
        if path then
            VersionedDataStore = require(path)
        end
    end)
end

-- Configuration
local CONFIG = {
    debug = true,
    patchSystems = true,  -- Whether to patch existing systems
    logAllDataOperations = true -- Whether to log all data operations
}

-- Logger
local function log(message)
    if CONFIG.debug then
        print("[DataIntegration] " .. message)
    end
end

-- Find all systems in the game
local function findGameSystems()
    local systems = {}
    
    -- Systems in Core folder
    if ServerScriptService:FindFirstChild("Core") then
        for _, item in pairs(ServerScriptService.Core:GetChildren()) do
            if item:IsA("ModuleScript") and item.Name:match("System$") then
                table.insert(systems, item)
            end
        end
    end
    
    -- Systems in server folder
    for _, item in pairs(ServerScriptService:GetChildren()) do
        if item:IsA("ModuleScript") and item.Name:match("System$") then
            table.insert(systems, item)
        end
    end
    
    -- Check inside server folder
    if ServerScriptService:FindFirstChild("server") then
        for _, item in pairs(ServerScriptService.server:GetChildren()) do
            if item:IsA("ModuleScript") and item.Name:match("System$") then
                table.insert(systems, item)
            end
        end
    end
    
    log("Found " .. #systems .. " systems to integrate with")
    return systems
end

-- Get the original DataManager
local function findOriginalDataManagers()
    local managers = {}
    
    -- Try common paths
    local possiblePaths = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("DataManager"),
        ServerScriptService:FindFirstChild("GymTycoonDataManager"),
        ServerScriptService:FindFirstChild("Data") and ServerScriptService.Data:FindFirstChild("EnhancedDataStorageSystem"),
        ServerScriptService:FindFirstChild("EnhancedDataStorageSystem"),
    }
    
    for _, path in ipairs(possiblePaths) do
        if path and path:IsA("ModuleScript") then
            pcall(function()
                local module = require(path)
                if module then
                    table.insert(managers, module)
                    log("Found data manager: " .. path.Name)
                end
            end)
        end
    end
    
    return managers
end

-- Patch a system to use DataAccessLayer
local function patchSystem(system)
    -- Only proceed if we have DataAccessLayer
    if not DataAccessLayer then
        log("Cannot patch system " .. system.Name .. " - DataAccessLayer not found")
        return false
    end
    
    local success, moduleSystem = pcall(function()
        return require(system)
    end)
    
    if not success then
        log("Failed to load system " .. system.Name)
        return false
    end
    
    -- Check if the system has data-related methods
    local needsPatching = false
    for key, value in pairs(moduleSystem) do
        if typeof(value) == "function" and 
           (key:match("^[Ll]oad") or key:match("^[Ss]ave") or 
            key:match("^[Gg]et.*[Dd]ata") or key:match("^[Ss]et.*[Dd]ata")) then
            needsPatching = true
            break
        end
    end
    
    if not needsPatching then
        log("System " .. system.Name .. " does not need data patching")
        return false
    end
    
    -- Set DataAccessLayer reference on the system
    pcall(function()
        moduleSystem.DataAccessLayer = DataAccessLayer
    end)
    
    log("Patched system: " .. system.Name)
    return true
end

-- Monitor data operations
local function setupDataMonitoring()
    if not DataAccessLayer then return end
    
    -- Listen for data events through CoreRegistry
    if CoreRegistry then
        if typeof(CoreRegistry.OnEvent) == "function" then
            -- Use OnEvent if available
            CoreRegistry:OnEvent("PlayerDataSaved", function(player)
                if CONFIG.logAllDataOperations then
                    log("Player data saved for " .. player.Name)
                end
            end)
            
            CoreRegistry:OnEvent("PlayerDataLoaded", function(player)
                if CONFIG.logAllDataOperations then
                    log("Player data loaded for " .. player.Name)
                end
            end)
            
            CoreRegistry:OnEvent("PlayerDataUpdated", function(player, path)
                if CONFIG.logAllDataOperations then
                    log("Player data updated for " .. player.Name .. " at path " .. path)
                end
            end)
        elseif typeof(CoreRegistry.onEvent) == "function" then
            -- Use onEvent (lowercase) if available
            CoreRegistry.onEvent("PlayerDataSaved", function(player)
                if CONFIG.logAllDataOperations then
                    log("Player data saved for " .. player.Name)
                end
            end)
            
            CoreRegistry.onEvent("PlayerDataLoaded", function(player)
                if CONFIG.logAllDataOperations then
                    log("Player data loaded for " .. player.Name)
                end
            end)
            
            CoreRegistry.onEvent("PlayerDataUpdated", function(player, path)
                if CONFIG.logAllDataOperations then
                    log("Player data updated for " .. player.Name .. " at path " .. path)
                end
            end)
        end
    end
end

-- Check server status
local function checkServerStatus()
    local status = {
        players = #Players:GetPlayers(),
        uptime = workspace:GetAttribute("ServerUptime") or os.time() - workspace:GetAttribute("ServerStartTime") or 0,
        memory = stats().PhysicalMemory / 1024 / 1024, -- MB
    }
    
    log("Server status - Players: " .. status.players .. ", Uptime: " .. status.uptime .. "s, Memory: " .. math.floor(status.memory) .. "MB")
    
    -- Set attributes for monitoring
    workspace:SetAttribute("DataSystemsIntegrated", true)
    workspace:SetAttribute("DataLayerVersion", DataAccessLayer and DataAccessLayer.Version or "N/A")
    
    return status
end

-- Main integration function
local function runIntegration()
    log("Starting data persistence integration")
    
    -- Check if DataAccessLayer is available
    if not DataAccessLayer then
        warn("DataAccessLayer not found. Integration will be limited.")
    end
    
    -- Find existing data managers
    local dataManagers = findOriginalDataManagers()
    log("Found " .. #dataManagers .. " legacy data managers")
    
    -- Find and patch systems if enabled
    if CONFIG.patchSystems then
        local systems = findGameSystems()
        local patchedCount = 0
        
        for _, system in ipairs(systems) do
            if patchSystem(system) then
                patchedCount = patchedCount + 1
            end
        end
        
        log("Patched " .. patchedCount .. " systems to use DataAccessLayer")
    end
    
    -- Setup monitoring
    setupDataMonitoring()
    
    -- Check server status
    checkServerStatus()
    
    -- Register server shutdown handler
    game:BindToClose(function()
        if DataAccessLayer then
            log("Server shutting down - notifying DataAccessLayer")
            DataAccessLayer:HandleShutdown()
        end
    end)
    
    log("Data persistence integration completed")
end

-- Run the integration
runIntegration()

-- Return nothing as this is a script not a module
return nil
