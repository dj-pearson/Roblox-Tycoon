--[[
    SystemBootstrap.server.luau
    
    Bootstrap script that initializes all core systems in the correct order.
    This script runs at server start and sets up the environment.
    
    Created: April 25, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    BOOTSTRAP_TIMEOUT = 10,
    ENSURE_FOLDERS = true,
    CREATE_EVENTS = true
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[SystemBootstrap] " .. message)
    end
end

local function warnLog(message)
    warn("[SystemBootstrap] " .. message)
end

local CoreFolder = ServerScriptService:FindFirstChild("Core")
local SharedFolder = ReplicatedStorage:FindFirstChild("shared")
local ConnectorsFolder = ServerScriptService:FindFirstChild("Connectors")

-- First try to initialize ModuleLoader and PathRegistration
local function initializeModuleLoader()
    log("Initializing ModuleLoader and registering paths...")
    
    -- Create shared folder if it doesn't exist
    if not ReplicatedStorage:FindFirstChild("shared") then
        local sharedFolder = Instance.new("Folder")
        sharedFolder.Name = "shared"
        sharedFolder.Parent = ReplicatedStorage
        log("Created shared folder in ReplicatedStorage")
    end
    
    -- Check for ModuleLoader, and copy it to shared folder if missing
    if not ReplicatedStorage.shared:FindFirstChild("ModuleLoader") then
        -- Try to find it in the src/shared folder
        local srcShared = ServerScriptService:FindFirstChild("src") and 
                          ServerScriptService.src:FindFirstChild("shared")
        if srcShared and srcShared:FindFirstChild("ModuleLoader") then
            local moduleLoader = srcShared.ModuleLoader:Clone()
            moduleLoader.Parent = ReplicatedStorage.shared
            log("Copied ModuleLoader to ReplicatedStorage.shared")
        else
            warnLog("ModuleLoader not found in src/shared, module loading might not work correctly")
        end
    end
    
    -- Run PathRegistration early (if not already run)
    local success, result = pcall(function()
        return require(script.Parent:FindFirstChild("PathRegistration"))
    end)
    
    if not success then
        warnLog("Failed to run PathRegistration: " .. tostring(result))
    else
        log("PathRegistration completed successfully")
    end
end

log("Starting system initialization...")

-- Initialize ModuleLoader first to ensure module loading works correctly
initializeModuleLoader()

-- Run folder setup first to ensure all required folders exist
local folderSetupPath = script.Parent:FindFirstChild("FolderSetup")
if folderSetupPath then
    log("Running FolderSetup...")
    require(folderSetupPath)
else
    log("Warning: FolderSetup not found, some scripts might yield indefinitely")
    
    -- Create essential folders if FolderSetup is missing
    if CONFIG.ENSURE_FOLDERS then
        log("Creating essential folders manually...")
        
        -- Function to ensure a folder exists
        local function ensureFolder(parent, name)
            local folder = parent:FindFirstChild(name)
            if not folder then
                folder = Instance.new("Folder")
                folder.Name = name
                folder.Parent = parent
                log("Created " .. name .. " folder in " .. parent.Name)
            end
            return folder
        end
        
        -- Create essential folders
        ensureFolder(ReplicatedStorage, "shared")
        ensureFolder(ReplicatedStorage, "Events")
        ensureFolder(ServerScriptService, "Core")
        ensureFolder(ServerScriptService, "Systems")
        ensureFolder(ServerScriptService, "Data")
    end
end

-- Ensure CoreRegistryInitializer runs to set up CoreRegistry
local coreRegistryInitializerPath = script.Parent:FindFirstChild("CoreRegistryInitializer")
if coreRegistryInitializerPath then
    log("Running CoreRegistryInitializer...")
    require(coreRegistryInitializerPath)
else
    warnLog("CoreRegistryInitializer not found! CoreRegistry may not function properly.")
end

-- Create all common remote events to prevent infinite yield errors
if CONFIG.CREATE_EVENTS then
    log("Creating common remote events...")
    
    local eventCreatorPath = script.Parent:FindFirstChild("EventCreator")
    if eventCreatorPath then
        require(eventCreatorPath)
        log("Common events created successfully")
    else
        warnLog("EventCreator not found, common events may not be created!")
    end
    
    -- Set up alliance events specifically
    local allianceEventSetupPath = script.Parent:FindFirstChild("AllianceEventSetup")
    if allianceEventSetupPath then
        require(allianceEventSetupPath)
        log("Alliance events created successfully")
    else
        warnLog("AllianceEventSetup not found, alliance events may not be created!")
    end
end

-- Try to get CoreRegistry to initialize systems
local CoreRegistry
local success, result = pcall(function()
    return require(script.Parent:FindFirstChild("CoreRegistry"))
end)

if success and result then
    CoreRegistry = result
    log("Found CoreRegistry, initializing systems...")
    
    -- Define the core systems that need to be initialized in order
    local coreSystems = {
        "EventBridge",
        "DataThrottler",
        "DataManager",
        "TutorialManager",
        "MigrationUtils",
    }
    
    -- Initialize systems one by one
    local initializedCount = 0
    for _, systemName in ipairs(coreSystems) do
        log("Initializing system: " .. systemName)
        
        local system = CoreRegistry:getSystem(systemName)
        if system then
            initializedCount = initializedCount + 1
            log("System loaded: " .. systemName)
        else
            warnLog("System not found: " .. systemName)
        end
    end
    
    log("Core systems initialized: " .. initializedCount .. "/" .. #coreSystems)
else
    warnLog("Failed to get CoreRegistry: " .. tostring(result))
    warnLog("System initialization may be incomplete!")
end

log("System bootstrap complete")

return {
    initialize = function()
        log("Systems already initialized")
        return true
    end
}
