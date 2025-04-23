-- SystemBootstrap.server.luau
-- Script responsible for initializing the core systems in the correct order
-- Place in ServerScriptService/Core

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Debug function
local function log(...)
    print("[SystemBootstrap]", ...)
end

log("Starting system initialization...")

-- Ensure folders exist
local function ensureFolderExists(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

-- Create necessary folders in ReplicatedStorage
local eventsFolder = ensureFolderExists(ReplicatedStorage, "Events")
local sharedFolder = ensureFolderExists(ReplicatedStorage, "shared")

-- First load CoreRegistry which manages all other systems
local coreRegistryPath = script.Parent:FindFirstChild("CoreRegistry")
if not coreRegistryPath then
    log("ERROR: Could not find CoreRegistry. System initialization cannot continue.")
    return
end

-- Load CoreRegistry
local success, CoreRegistry = pcall(function()
    return require(coreRegistryPath)
end)

if not success or not CoreRegistry then
    log("ERROR: Failed to load CoreRegistry:", CoreRegistry)
    return
end

log("CoreRegistry loaded successfully")

-- Define initialization order for critical systems
local initializationOrder = {
    -- Core infrastructure first
    "EventBridge",
    "GymTycoonConnector",
    
    -- Data systems next
    "DataManager",
    
    -- Base gameplay systems
    "TycoonSystem",
    "BuyTileSystem",
    "GymStructureIntegration",
    
    -- Feature systems
    "NPCSystem",
    "RevenueSystem",
    "MemberSatisfactionSystem",
    "FrontDeskSystem",
    "SaunaSystem",
    
    -- Integration systems
    "GymTycoonConnectorBridge"
}

-- Initialize systems in specified order
for _, systemName in ipairs(initializationOrder) do
    log("Initializing " .. systemName .. "...")
    local system = CoreRegistry.getSystem(systemName)
    
    if system then
        log(systemName .. " initialized successfully")
    else
        log("Warning: " .. systemName .. " failed to initialize or was not found")
    end
end

-- Check for any remaining systems that weren't explicitly initialized
local allSystems = CoreRegistry.getSystemNames()
log("All registered systems: " .. table.concat(allSystems, ", "))

-- Initialize remaining systems
CoreRegistry.initializeAll()

log("System initialization complete!")

-- Create global access point for debugging
_G.SystemBootstrap = {
    CoreRegistry = CoreRegistry,
    reinitialize = function()
        log("Attempting to reinitialize all systems...")
        CoreRegistry.initializeAll()
        log("Reinitialization complete")
    end,
    getSystem = function(name)
        return CoreRegistry.getSystem(name)
    end
}

-- Signal to any waiting scripts that initialization is complete
local initComplete = Instance.new("BoolValue")
initComplete.Name = "SystemInitializationComplete"
initComplete.Value = true
initComplete.Parent = script
