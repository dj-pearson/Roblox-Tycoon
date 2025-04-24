--[[
    DataSystemInitializer.server.luau
    
    Initializes all data persistence systems in the correct order.
    This ensures proper dependency management and prevents race conditions
    during startup.
    
    Author: Created April 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Only run on server
if not RunService:IsServer() then
    return
end

local function log(message)
    print("[DataInitializer] " .. message)
end

log("Starting data systems initialization...")

-- Set server start time for tracking
workspace:SetAttribute("ServerStartTime", os.time())

-- =========================================
-- Step 1: Initialize the CoreRegistry first
-- =========================================
local CoreRegistry
pcall(function()
    local registryModule = ServerScriptService:FindFirstChild("Core"):FindFirstChild("CoreRegistry")
    if registryModule then
        CoreRegistry = require(registryModule)
        log("CoreRegistry loaded")
    else
        log("CoreRegistry not found, will continue without it")
    end
end)

-- =======================================================
-- Step 2: Initialize the DataAccessLayer (our main system)
-- =======================================================
local DataAccessLayer
pcall(function()
    local dalPath = ServerScriptService:FindFirstChild("Core"):FindFirstChild("DataAccessLayer")
    if dalPath then
        DataAccessLayer = require(dalPath)
        log("DataAccessLayer initialized")
    else
        warn("DataAccessLayer not found, data persistence improvements will be limited")
    end
end)

-- =====================================================
-- Step 3: Initialize the VersionedDataStore (if present)
-- =====================================================
local VersionedDataStore
pcall(function()
    local vdsPath = ServerScriptService:FindFirstChild("Core"):FindFirstChild("VersionedDataStore")
    if vdsPath then
        VersionedDataStore = require(vdsPath)
        log("VersionedDataStore initialized")
    end
end)

-- ========================================================
-- Step 4: Initialize the DataMigrationUtility (if present)
-- ========================================================
local DataMigrationUtility
pcall(function()
    local dmuPath = ServerScriptService:FindFirstChild("Core"):FindFirstChild("DataMigrationUtility")
    if dmuPath then
        DataMigrationUtility = require(dmuPath)
        log("DataMigrationUtility initialized")
    end
end)

-- ==============================================
-- Step 5: Initialize the DataAdminSystem
-- ==============================================
local DataAdminSystem
pcall(function()
    local dasPath = ServerScriptService:FindFirstChild("Core"):FindFirstChild("DataAdminSystem")
    if dasPath then
        DataAdminSystem = require(dasPath)
        log("DataAdminSystem initialized")
    end
end)

-- ==========================================
-- Step 6: Run the integration script last
-- ==========================================
pcall(function()
    local integrationPath = ServerScriptService:FindFirstChild("Core"):FindFirstChild("DataPersistenceIntegration")
    if integrationPath and integrationPath:IsA("Script") then
        log("DataPersistenceIntegration will run automatically")
    else
        log("DataPersistenceIntegration script not found, running integration manually")
        local integrationModule = ServerScriptService:FindFirstChild("Core"):FindFirstChild("DataPersistenceIntegration")
        if integrationModule and integrationModule:IsA("ModuleScript") then
            require(integrationModule)
        end
    end
end)

log("All data systems initialized successfully!")

-- Register a periodic status check (every 5 minutes)
task.spawn(function()
    while task.wait(300) do -- 5 minutes
        local memoryUsage = math.floor(stats().PhysicalMemory / 1024 / 1024)
        log("Server running - Memory usage: " .. memoryUsage .. " MB")
    end
end)
