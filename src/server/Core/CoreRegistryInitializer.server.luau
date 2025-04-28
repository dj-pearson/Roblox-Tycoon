--[[
    CoreRegistryInitializer.server.luau
    
    A robust initializer for the CoreRegistry that ensures it's properly loaded
    early in the game lifecycle and handles dependency resolution.
    
    Updated: April 27, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    RETRY_COUNT = 3,
    RETRY_DELAY = 1,
    ENSURE_CRITICAL_SYSTEMS = true,
    HEALTH_CHECK_INTERVAL = 5
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[CoreRegistryInitializer] " .. message)
    end
end

local function warn_log(message)
    warn("[CoreRegistryInitializer] " .. message)
end

-- Find and require SafeWaitForChild and SafeRequire if they exist
local SafeWaitForChild
local SafeRequire

do
    -- Try to find SafeWaitForChild
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then
        local safeWaitForChildModule = shared:FindFirstChild("SafeWaitForChild")
        if safeWaitForChildModule and safeWaitForChildModule:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(safeWaitForChildModule)
            end)
            
            if success and result then
                SafeWaitForChild = result
                log("Loaded SafeWaitForChild from shared folder")
            end
        end
        
        local safeRequireModule = shared:FindFirstChild("SafeRequire")
        if safeRequireModule and safeRequireModule:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(safeRequireModule)
            end)
            
            if success and result then
                SafeRequire = result
                log("Loaded SafeRequire from shared folder")
            end
        end
    end
    
    -- Create minimal SafeWaitForChild if not found
    if not SafeWaitForChild then
        log("Creating minimal SafeWaitForChild")
        SafeWaitForChild = {
            waitForChild = function(parent, childName, timeout)
                if not parent then return nil end
                timeout = timeout or 5
                
                -- Check if child already exists
                local child = parent:FindFirstChild(childName)
                if child then return child end
                
                -- Try to wait for it
                local startTime = os.clock()
                
                while os.clock() - startTime < timeout do
                    child = parent:FindFirstChild(childName)
                    if child then return child end
                    task.wait(0.1)
                end
                
                warn("[SafeWaitForChild] Timed out waiting for " .. childName .. " in " .. parent:GetFullName())
                return nil
            end,
            
            waitForDescendant = function(parent, path, timeout)
                if not parent or not path then return nil end
                timeout = timeout or 5
                
                -- Split path
                local segments = string.split(path, ".")
                
                -- Navigate through path
                local current = parent
                for i, segment in ipairs(segments) do
                    current = SafeWaitForChild.waitForChild(current, segment, timeout/#segments)
                    if not current then
                        return nil
                    end
                end
                
                return current
            end,
            
            getOrCreateChild = function(parent, childName, className)
                if not parent then return nil end
                
                local child = parent:FindFirstChild(childName)
                if child then return child end
                
                -- Create new instance
                local newChild = Instance.new(className or "Folder")
                newChild.Name = childName
                newChild.Parent = parent
                return newChild
            end
        }
    end
    
    -- Create minimal SafeRequire if not found
    if not SafeRequire then
        log("Creating minimal SafeRequire")
        SafeRequire = {
            require = function(module, fallback)
                if not module then return fallback end
                
                local success, result = pcall(function()
                    return require(module)
                end)
                
                if success then
                    return result
                else
                    return fallback
                end
            end
        }
    end
end

-- Find folder with fallbacks
local function findFolder(parent, childName, createIfMissing)
    if not parent then
        warn_log("Parent is nil when finding folder: " .. childName)
        return nil
    end
    
    local child = parent:FindFirstChild(childName)
    if child and child:IsA("Folder") then
        return child
    end
    
    -- Try alternative casing
    if childName:lower() == "core" then
        child = parent:FindFirstChild("Core")
        if child and child:IsA("Folder") then
            return child
        end
    end
    
    -- Create if requested and not found
    if createIfMissing then
        log("Creating missing folder: " .. childName .. " in " .. parent:GetFullName())
        return SafeWaitForChild.getOrCreateChild(parent, childName, "Folder")
    end
    
    return nil
end

-- Ensure ModuleLoader is available
local function ensureModuleLoader()
    log("Ensuring ModuleLoader is available...")
    
    -- Find shared folder or create it
    local shared = findFolder(ReplicatedStorage, "shared", true)
    
    -- Check if our newly created ModuleLoader exists
    local moduleLoader = shared:FindFirstChild("ModuleLoader")
    if moduleLoader and moduleLoader:IsA("ModuleScript") then
        log("Found existing ModuleLoader")
        
        -- Initialize ModuleLoader
        local success, loader = pcall(function()
            local ml = require(moduleLoader)
            if typeof(ml.Initialize) == "function" then
                ml.Initialize()
            end
            return ml
        end)
        
        if success and loader then
            log("Successfully initialized ModuleLoader")
            return loader
        else
            warn_log("Failed to initialize existing ModuleLoader")
        end
    end
    
    -- Look for ModuleLoader in src/shared
    local srcShared = ReplicatedStorage:FindFirstChild("src") and 
                     ReplicatedStorage.src:FindFirstChild("shared")
    
    if srcShared and srcShared:FindFirstChild("ModuleLoader") then
        log("Found ModuleLoader in src/shared, copying to ReplicatedStorage.shared")
        local sourceMl = srcShared.ModuleLoader
        local copiedMl = sourceMl:Clone()
        copiedMl.Parent = shared
        
        -- Try to require it
        local loader = SafeRequire.require(copiedMl)
        if loader then
            if typeof(loader.Initialize) == "function" then
                loader.Initialize()
            end
            log("Successfully initialized ModuleLoader from src/shared")
            return loader
        end
    end
    
    -- Create minimal ModuleLoader if necessary
    warn_log("Could not find ModuleLoader, creating a minimal version")
    
    -- Get our previously created ModuleLoader
    local moduleLoaderPath = "c:\\Users\\pears\\OneDrive\\Documents\\RobloxProject\\src\\shared\\ModuleLoader.luau"
    local file = io.open(moduleLoaderPath, "r")
    local moduleLoaderSource = ""
    
    if file then
        moduleLoaderSource = file:read("*all")
        file:close()
    else
        moduleLoaderSource = [[
--!strict
-- Minimal ModuleLoader implementation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Default search paths
local searchPaths = {
    ["shared"] = ReplicatedStorage:FindFirstChild("shared"),
    ["ServerCore"] = ServerScriptService:FindFirstChild("Core"),
    ["ReplicatedStorage"] = ReplicatedStorage,
    ["ServerScriptService"] = ServerScriptService
}

-- Internal state
local moduleCache = {}
local initialized = false

-- Debug logging
local function log(message)
    print("[ModuleLoader] " .. message)
end

-- Find a module script in the registered paths
local function findModule(moduleName)
    if not moduleName then
        return nil
    end
    
    -- Check each registered path
    for pathName, path in pairs(searchPaths) do
        if path then
            local moduleScript = path:FindFirstChild(moduleName)
            if moduleScript and moduleScript:IsA("ModuleScript") then
                log("Found module " .. moduleName .. " in path: " .. pathName)
                return moduleScript
            end
        end
    end
    
    log("Module not found: " .. moduleName)
    return nil
end

-- Load a module by name
local function loadModule(moduleName, fallback)
    if not initialized then
        Initialize()
    end
    
    if not moduleName then
        warn("[ModuleLoader] moduleName is nil")
        return fallback
    end
    
    -- Check cache first
    if moduleCache[moduleName] then
        return moduleCache[moduleName]
    end
    
    -- Find the module
    local moduleScript = findModule(moduleName)
    if not moduleScript then
        warn("[ModuleLoader] Module not found: " .. moduleName)
        return fallback
    end
    
    -- Try to require the module
    local success, module = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        moduleCache[moduleName] = module
        return module
    else
        warn("[ModuleLoader] Failed to require " .. moduleName)
        return fallback
    end
end

-- Initialize the module loader
local function Initialize()
    if initialized then
        return
    end
    
    log("Initializing ModuleLoader")
    
    -- Create missing paths
    if not searchPaths["shared"] then
        local sharedFolder = Instance.new("Folder")
        sharedFolder.Name = "shared"
        sharedFolder.Parent = ReplicatedStorage
        searchPaths["shared"] = sharedFolder
    end
    
    if not searchPaths["ServerCore"] and game:GetService("RunService"):IsServer() then
        local coreFolder = Instance.new("Folder")
        coreFolder.Name = "Core"
        coreFolder.Parent = ServerScriptService
        searchPaths["ServerCore"] = coreFolder
    end
    
    initialized = true
end

-- Return the API
return {
    LoadModule = loadModule,
    FindModule = findModule,
    Initialize = Initialize,
    RegisterPath = function(name, path)
        searchPaths[name] = path
        return true
    end
}
]]
    end
    
    local minimalModuleLoader = Instance.new("ModuleScript")
    minimalModuleLoader.Name = "ModuleLoader"
    minimalModuleLoader.Source = moduleLoaderSource
    minimalModuleLoader.Parent = shared
    
    -- Initialize minimal ModuleLoader
    local loader = SafeRequire.require(minimalModuleLoader)
    if loader then
        if typeof(loader.Initialize) == "function" then
            loader.Initialize()
        end
        log("Created and initialized minimal ModuleLoader")
        return loader
    else
        warn_log("Failed to initialize minimal ModuleLoader")
        return nil
    end
end

-- Create or find the CoreRegistry
local function initializeCoreRegistry()
    log("Initializing CoreRegistry...")
    
    -- Ensure Core folder exists
    local core = findFolder(ServerScriptService, "Core", true)
    
    -- Try multiple paths to find CoreRegistry
    local registryPaths = {
        core and core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ReplicatedStorage:FindFirstChild("src") and 
            ReplicatedStorage.src:FindFirstChild("server") and 
            ReplicatedStorage.src.server:FindFirstChild("Core") and
            ReplicatedStorage.src.server.Core:FindFirstChild("CoreRegistry")
    }
    
    -- Try each path
    for _, registryPath in ipairs(registryPaths) do
        if registryPath and registryPath:IsA("ModuleScript") then
            log("Found CoreRegistry at: " .. registryPath:GetFullName())
            
            -- Try to require it
            local registry = SafeRequire.require(registryPath)
            if registry then
                log("Successfully loaded CoreRegistry")
                _G.CoreRegistry = registry
                return registry
            end
        end
    end
    
    -- Create a minimal CoreRegistry if necessary
    warn_log("Could not find CoreRegistry, creating a minimal version")
    
    local coreRegistrySource = [[
--!strict
-- CoreRegistry Module
-- Centralized system for managing game systems and their dependencies
-- Updated: April 27, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to use ModuleLoader if it exists
local ModuleLoader
local shared = ReplicatedStorage:FindFirstChild("shared")
if shared and shared:FindFirstChild("ModuleLoader") then
    local success, result = pcall(function()
        return require(shared.ModuleLoader)
    end)
    
    if success then
        ModuleLoader = result
        print("[CoreRegistry] Successfully loaded ModuleLoader")
    end
end

if not ModuleLoader then
    print("[CoreRegistry] ModuleLoader not found, using legacy loading")
end

-- Create the registry table
local CoreRegistry = {
    systems = {},     -- Systems that have been registered
    initialized = {}, -- Systems that have been initialized
    loading = {},     -- Systems currently being initialized (to detect circular dependencies)
    moduleLoader = ModuleLoader, -- Store ModuleLoader reference for other systems to use
    healthStatus = "OK"  -- Status for health checks
}

-- Debug function
local function log(...)
    print("[CoreRegistry]", ...)
end

-- Register a system with the registry
function CoreRegistry.registerSystem(name, system, dependencies)
    if type(name) ~= "string" or type(system) ~= "table" then
        log("Error registering system: Invalid parameters")
        return nil
    end
    
    if CoreRegistry.systems[name] then
        log("Warning: System '" .. name .. "' already registered, overwriting")
    end
    
    -- Normalize dependencies to array if nil
    if dependencies == nil then
        dependencies = {}
    end
    
    -- Store the system
    CoreRegistry.systems[name] = {
        module = system,
        dependencies = dependencies
    }
    
    log("Registered system: " .. name)
    return system
end

-- Check if a system exists in the registry
function CoreRegistry.hasSystem(name)
    return CoreRegistry.systems[name] ~= nil or CoreRegistry.initialized[name] ~= nil
end

-- Get a system and ensure it's initialized
function CoreRegistry.getSystem(name)
    -- Return already initialized system
    if CoreRegistry.initialized[name] then
        return CoreRegistry.initialized[name]
    end
    
    -- Check if system exists
    if not CoreRegistry.systems[name] then
        -- Try to load it directly using ModuleLoader if available
        if ModuleLoader and ModuleLoader.LoadModule then
            local module = ModuleLoader.LoadModule(name)
            if module then
                CoreRegistry.registerSystem(name, module, {})
                log("Auto-loaded system '" .. name .. "' using ModuleLoader")
            else
                -- Try direct requires as a last resort
                local success, result = pcall(function()
                    if ServerScriptService.Core and ServerScriptService.Core:FindFirstChild(name) then
                        return require(ServerScriptService.Core:FindFirstChild(name))
                    elseif ReplicatedStorage.shared and ReplicatedStorage.shared:FindFirstChild(name) then
                        return require(ReplicatedStorage.shared:FindFirstChild(name))
                    end
                    return nil
                end)
                
                if success and result then
                    CoreRegistry.registerSystem(name, result, {})
                    log("Auto-loaded system '" .. name .. "' using direct require")
                else
                    log("System not found: " .. name)
                    return nil
                end
            end
        else
            log("System not found and ModuleLoader not available: " .. name)
            return nil
        end
    end
    
    -- Detect circular dependencies
    if CoreRegistry.loading[name] then
        log("Error: Circular dependency detected for system: " .. name)
        return nil
    end
    
    -- Mark as loading
    CoreRegistry.loading[name] = true
    
    -- Load dependencies first
    local system = CoreRegistry.systems[name]
    if system and system.dependencies then
        for _, depName in ipairs(system.dependencies) do
            local depSystem = CoreRegistry.getSystem(depName)
            if not depSystem then
                log("Warning: Could not load dependency '" .. depName .. "' for system '" .. name .. "'")
            end
        end
    end
    
    -- Initialize the system
    system = CoreRegistry.systems[name].module
    if type(system.initialize) == "function" then
        log("Initializing system: " .. name)
        local success, errorMsg = pcall(function()
            system:initialize(CoreRegistry)
        end)
        
        if not success then
            log("Error initializing system '" .. name .. "': " .. tostring(errorMsg))
        end
    end
    
    -- Mark as initialized and no longer loading
    CoreRegistry.initialized[name] = system
    CoreRegistry.loading[name] = nil
    
    return system
end

-- Get all registered systems
function CoreRegistry.getAllSystems()
    local result = {}
    for name, _ in pairs(CoreRegistry.systems) do
        table.insert(result, name)
    end
    return result
end

-- Health check function
function CoreRegistry.healthCheck()
    -- Check critical systems
    local criticalSystems = {
        "EventBridge",
        "ModuleLoader"
    }
    
    for _, systemName in ipairs(criticalSystems) do
        if not CoreRegistry.hasSystem(systemName) then
            CoreRegistry.healthStatus = "WARNING: Missing " .. systemName
            return false
        end
    end
    
    CoreRegistry.healthStatus = "OK"
    return true
end

-- Create a basic EventBridge system if it doesn't exist yet
local EventBridge = {
    events = {},
    remoteEvents = {},
    
    initialize = function(self)
        log("EventBridge initialized")
        return true
    end,
    
    getOrCreateEvent = function(self, eventName)
        if not self.events[eventName] then
            self.events[eventName] = {
                callbacks = {}
            }
        end
        return self.events[eventName]
    end,
    
    fireEvent = function(self, eventName, ...)
        local event = self.events[eventName]
        if event then
            for _, callback in ipairs(event.callbacks) do
                task.spawn(function()
                    callback(...)
                end)
            end
        end
    end,
    
    connectEvent = function(self, eventName, callback)
        local event = self:getOrCreateEvent(eventName)
        table.insert(event.callbacks, callback)
        -- Return a "connection" object with a disconnect method
        return {
            disconnect = function()
                for i, cb in ipairs(event.callbacks) do
                    if cb == callback then
                        table.remove(event.callbacks, i)
                        break
                    end
                end
            end
        }
    end
}

-- Register core EventBridge system first
CoreRegistry.registerSystem("EventBridge", EventBridge, {})

-- Perform an initial health check
CoreRegistry.healthCheck()

return CoreRegistry
]]
    
    -- Create CoreRegistry module
    local minimalRegistry = Instance.new("ModuleScript")
    minimalRegistry.Name = "CoreRegistry"
    minimalRegistry.Source = coreRegistrySource
    minimalRegistry.Parent = core
    
    -- Try to require it
    local registry = SafeRequire.require(minimalRegistry)
    if registry then
        log("Created and initialized CoreRegistry")
        
        -- Store in global scope for emergency access
        _G.CoreRegistry = registry
        
        return registry
    else
        warn_log("Failed to initialize CoreRegistry")
        return nil
    end
end

-- Create CoreRegistryFeedback to monitor CoreRegistry health
local function createCoreRegistryFeedback()
    log("Setting up CoreRegistry health monitoring...")
    
    -- Create value for status monitoring
    local statusValue = Instance.new("StringValue")
    statusValue.Name = "CoreRegistryStatus"
    statusValue.Value = "Initializing..."
    statusValue.Parent = ServerScriptService
    
    -- Create the feedback script
    local feedbackScript = Instance.new("Script")
    feedbackScript.Name = "CoreRegistryFeedback"
    feedbackScript.Source = [[
-- CoreRegistryFeedback script
-- Monitors CoreRegistry health and provides status information
-- Created: April 27, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local statusValue = script.Parent:FindFirstChild("CoreRegistryStatus")

local CHECK_INTERVAL = 5 -- seconds
local MAX_RETRIES = 3

-- Helper function to check CoreRegistry
local function checkCoreRegistry()
    -- Check if CoreRegistry exists
    if not _G.CoreRegistry then
        return false, "CoreRegistry UNAVAILABLE"
    end
    
    -- Check health status
    if _G.CoreRegistry.healthStatus then
        return _G.CoreRegistry.healthStatus == "OK", _G.CoreRegistry.healthStatus
    end
    
    -- Run health check if available
    if typeof(_G.CoreRegistry.healthCheck) == "function" then
        local success = _G.CoreRegistry.healthCheck()
        return success, success and "OK" or "Health check failed"
    end
    
    return true, "Basic check OK"
end

-- Initialize feedback system
local function initialize()
    print("[CoreRegistryFeedback] Starting health monitoring...")
    
    -- Initial status
    local success, status = checkCoreRegistry()
    print("[CoreRegistryFeedback] Initial status: " .. status)
    
    if statusValue then
        statusValue.Value = status
    end
    
    -- If not available, try a few times
    if not success then
        for i = 1, MAX_RETRIES do
            wait(CHECK_INTERVAL)
            success, status = checkCoreRegistry()
            
            print("[CoreRegistryFeedback] CoreRegistry check " .. 
                  (success and "passed" or "failed") .. " (" .. i .. "/" .. MAX_RETRIES .. ")")
                  
            if statusValue then
                statusValue.Value = status
            end
            
            if success then
                break
            end
        end
    end
    
    -- Continuous monitoring
    while true do
        wait(CHECK_INTERVAL)
        local success, status = checkCoreRegistry()
        
        if statusValue then
            statusValue.Value = status
        end
        
        if not success then
            print("[CoreRegistryFeedback] CoreRegistry health check failed: " .. status)
        end
    end
end

-- Start the feedback system
initialize()
]]
    feedbackScript.Parent = ServerScriptService
    
    log("CoreRegistry health monitoring set up")
    return true
end

-- Ensure critical folders exist
local function ensureCriticalFolders()
    -- Create shared folder in ReplicatedStorage
    local shared = findFolder(ReplicatedStorage, "shared", true)
    
    -- Create Core folder in ServerScriptService
    local core = findFolder(ServerScriptService, "Core", true)
    
    -- Create other important folders
    findFolder(ReplicatedStorage, "Events", true)
    
    if shared and core then
        return true
    end
    
    return false
end

-- Create the TutorialManager module (one of the missing modules)
local function createTutorialManager()
    local core = findFolder(ServerScriptService, "Core", true)
    if not core then
        warn_log("Cannot create TutorialManager - Core folder not found")
        return false
    end
    
    -- Check if it already exists
    if core:FindFirstChild("TutorialManager") then
        return true
    end
    
    -- Create the module
    local tutorialManager = Instance.new("ModuleScript")
    tutorialManager.Name = "TutorialManager"
    tutorialManager.Source = [[
--!strict
-- TutorialManager Module
-- Manages player tutorials and guides
-- Created: April 27, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Try to get CoreRegistry
local CoreRegistry = _G.CoreRegistry

-- Default tutorial data
local defaultTutorials = {
    GymTutorial = {
        steps = {
            "Welcome to Gym Tycoon!",
            "Click on tiles to purchase gym equipment",
            "Upgrade equipment to earn more money",
            "Collect cash to expand your gym"
        },
        completed = false
    },
    RebirthTutorial = {
        steps = {
            "Ready to Rebirth?",
            "Rebirthing resets your progress but gives you bonuses",
            "Each rebirth makes you earn more money",
            "You keep your rebirth level and bonuses"
        },
        completed = false
    }
}

-- The Tutorial Manager
local TutorialManager = {
    playerTutorials = {}, -- Player tutorial state
    events = {}           -- Tutorial events
}

-- Initialize the system
function TutorialManager:initialize()
    print("[TutorialManager] Initializing...")
    
    -- Register events if CoreRegistry is available
    if CoreRegistry then
        local EventBridge = CoreRegistry.getSystem("EventBridge")
        if EventBridge then
            EventBridge:connectEvent("PlayerAdded", function(player)
                self:initializePlayerTutorials(player)
            end)
            
            print("[TutorialManager] Connected to EventBridge")
        else
            print("[TutorialManager] EventBridge not found, tutorials may not auto-start")
        end
    end
    
    -- Connect to PlayerAdded event directly as a fallback
    Players.PlayerAdded:Connect(function(player)
        self:initializePlayerTutorials(player)
    end)
    
    -- Initialize tutorials for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:initializePlayerTutorials(player)
    end
    
    print("[TutorialManager] Initialized successfully")
    return true
end

-- Initialize tutorials for a player
function TutorialManager:initializePlayerTutorials(player)
    if not player then return end
    
    -- Create tutorial state for player
    if not self.playerTutorials[player.UserId] then
        self.playerTutorials[player.UserId] = {}
        
        -- Copy default tutorials
        for tutorialName, tutorialData in pairs(defaultTutorials) do
            self.playerTutorials[player.UserId][tutorialName] = {
                steps = tutorialData.steps,
                currentStep = 1,
                completed = tutorialData.completed,
                started = false
            }
        end
        
        print("[TutorialManager] Initialized tutorials for " .. player.Name)
    end
    
    -- Fire event to notify client
    self:fireTutorialEvent("TutorialsInitialized", player)
end

-- Start a tutorial for a player
function TutorialManager:startTutorial(player, tutorialName)
    if not player or not tutorialName then return false end
    
    local playerData = self.playerTutorials[player.UserId]
    if not playerData then
        self:initializePlayerTutorials(player)
        playerData = self.playerTutorials[player.UserId]
    end
    
    local tutorial = playerData[tutorialName]
    if not tutorial then
        print("[TutorialManager] Tutorial not found: " .. tutorialName)
        return false
    end
    
    -- Skip if already completed
    if tutorial.completed then
        print("[TutorialManager] Tutorial already completed: " .. tutorialName)
        return false
    end
    
    -- Start or resume tutorial
    tutorial.started = true
    tutorial.currentStep = tutorial.currentStep or 1
    
    -- Fire event to notify client
    self:fireTutorialEvent("TutorialStarted", player, tutorialName, tutorial.currentStep)
    
    print("[TutorialManager] Started tutorial " .. tutorialName .. " for " .. player.Name)
    return true
end

-- Advance to the next step in a tutorial
function TutorialManager:advanceTutorial(player, tutorialName)
    if not player or not tutorialName then return false end
    
    local playerData = self.playerTutorials[player.UserId]
    if not playerData then return false end
    
    local tutorial = playerData[tutorialName]
    if not tutorial or not tutorial.started then return false end
    
    -- Advance to next step
    tutorial.currentStep = tutorial.currentStep + 1
    
    -- Check if completed
    if tutorial.currentStep > #tutorial.steps then
        tutorial.completed = true
        
        -- Fire completion event
        self:fireTutorialEvent("TutorialCompleted", player, tutorialName)
        
        print("[TutorialManager] Player " .. player.Name .. " completed tutorial: " .. tutorialName)
        return true
    end
    
    -- Fire step change event
    self:fireTutorialEvent("TutorialAdvanced", player, tutorialName, tutorial.currentStep)
    
    return true
end

-- Fire a tutorial event
function TutorialManager:fireTutorialEvent(eventName, player, ...)
    if CoreRegistry then
        local EventBridge = CoreRegistry.getSystem("EventBridge")
        if EventBridge then
            EventBridge:fireEvent(eventName, player, ...)
            return
        end
    end
    
    -- Fallback to direct event firing
    if self.events[eventName] then
        for _, callback in ipairs(self.events[eventName]) do
            task.spawn(function()
                callback(player, ...)
            end)
        end
    end
end

-- Connect to a tutorial event
function TutorialManager:connectTutorialEvent(eventName, callback)
    if CoreRegistry then
        local EventBridge = CoreRegistry.getSystem("EventBridge")
        if EventBridge then
            return EventBridge:connectEvent(eventName, callback)
        end
    end
    
    -- Fallback to direct event connection
    if not self.events[eventName] then
        self.events[eventName] = {}
    end
    
    table.insert(self.events[eventName], callback)
    
    return {
        disconnect = function()
            for i, cb in ipairs(self.events[eventName]) do
                if cb == callback then
                    table.remove(self.events[eventName], i)
                    break
                end
            end
        end
    }
end

-- Register with CoreRegistry if available
if CoreRegistry then
    CoreRegistry.registerSystem("TutorialManager", TutorialManager, {"EventBridge"})
end

return TutorialManager
]]
    tutorialManager.Parent = core
    
    log("Created TutorialManager module")
    return true
end

-- Create the MigrationUtils module (one of the missing modules)
local function createMigrationUtils()
    local core = findFolder(ServerScriptService, "Core", true)
    if not core then
        warn_log("Cannot create MigrationUtils - Core folder not found")
        return false
    end
    
    -- Check if it already exists
    if core:FindFirstChild("MigrationUtils") then
        return true
    end
    
    -- Create the module
    local migrationUtils = Instance.new("ModuleScript")
    migrationUtils.Name = "MigrationUtils"
    migrationUtils.Source = [[
--!strict
-- MigrationUtils Module
-- Utilities for data migration and format conversion
-- Created: April 27, 2025

local DataStoreService = game:GetService("DataStoreService")

-- Default configuration
local DEFAULT_CONFIG = {
    BACKUP_BEFORE_MIGRATION = true,
    MIGRATION_VERSION = 1,
    ENABLE_LOGGING = true
}

-- The MigrationUtils module
local MigrationUtils = {
    config = DEFAULT_CONFIG,
    migrations = {},
    migrationLog = {}
}

-- Initialize the system
function MigrationUtils:initialize()
    print("[MigrationUtils] Initializing...")
    
    -- Try to register with CoreRegistry
    local CoreRegistry = _G.CoreRegistry
    if CoreRegistry then
        CoreRegistry.registerSystem("MigrationUtils", self, {})
    end
    
    print("[MigrationUtils] Initialized")
    return true
end

-- Log migration events
function MigrationUtils:log(message)
    if self.config.ENABLE_LOGGING then
        print("[MigrationUtils] " .. message)
        table.insert(self.migrationLog, {
            timestamp = os.time(),
            message = message
        })
    end
end

-- Register a migration
function MigrationUtils:registerMigration(fromVersion, toVersion, migrationFunc)
    if not fromVersion or not toVersion or not migrationFunc then
        warn("[MigrationUtils] Invalid migration registration parameters")
        return false
    end
    
    local migrationKey = tostring(fromVersion) .. "->" .. tostring(toVersion)
    self.migrations[migrationKey] = migrationFunc
    
    self:log("Registered migration from v" .. fromVersion .. " to v" .. toVersion)
    return true
end

-- Check if a migration exists
function MigrationUtils:hasMigration(fromVersion, toVersion)
    local migrationKey = tostring(fromVersion) .. "->" .. tostring(toVersion)
    return self.migrations[migrationKey] ~= nil
end

-- Back up data before migration
function MigrationUtils:backupData(dataStore, key, data)
    if not self.config.BACKUP_BEFORE_MIGRATION then
        return true
    end
    
    local backupKey = key .. "_backup_v" .. tostring(data.version or 0) .. "_" .. os.time()
    
    local backupStore = DataStoreService:GetDataStore("Backup_" .. dataStore.Name)
    local success, errorMessage = pcall(function()
        backupStore:SetAsync(backupKey, data)
    end)
    
    if success then
        self:log("Created backup: " .. backupKey)
        return true
    else
        warn("[MigrationUtils] Failed to create backup: " .. tostring(errorMessage))
        return false
    end
end

-- Migrate data from one version to another
function MigrationUtils:migrateData(data, targetVersion)
    if not data then
        warn("[MigrationUtils] Cannot migrate nil data")
        return nil
    end
    
    -- Get current version
    local currentVersion = data.version or 0
    
    -- Already at target version
    if currentVersion == targetVersion then
        return data
    end
    
    -- Determine migration path
    if currentVersion > targetVersion then
        warn("[MigrationUtils] Cannot downgrade data from v" .. currentVersion .. " to v" .. targetVersion)
        return data
    end
    
    local migratedData = table.clone(data)
    
    -- Apply migrations in sequence
    for version = currentVersion, targetVersion - 1 do
        local nextVersion = version + 1
        local migrationKey = tostring(version) .. "->" .. tostring(nextVersion)
        
        local migrationFunc = self.migrations[migrationKey]
        if not migrationFunc then
            warn("[MigrationUtils] No migration path from v" .. version .. " to v" .. nextVersion)
            break
        end
        
        -- Apply migration
        self:log("Applying migration v" .. version .. " -> v" .. nextVersion)
        local success, result = pcall(function()
            return migrationFunc(migratedData)
        end)
        
        if success and result then
            migratedData = result
            migratedData.version = nextVersion
        else
            warn("[MigrationUtils] Migration failed: " .. tostring(result))
            break
        end
    end
    
    return migratedData
end

-- Migrate player data to the latest version
function MigrationUtils:migratePlayerData(player, data)
    if not player or not data then
        return data
    end
    
    -- Log migration attempt
    self:log("Attempting to migrate data for player: " .. player.Name)
    
    -- Perform migration
    local migratedData = self:migrateData(data, self.config.MIGRATION_VERSION)
    
    -- Log migration result
    if migratedData.version == self.config.MIGRATION_VERSION then
        self:log("Successfully migrated data for " .. player.Name .. " to v" .. migratedData.version)
    else
        self:log("Partial migration for " .. player.Name .. " to v" .. migratedData.version)
    end
    
    return migratedData
end

-- Configure the migration system
function MigrationUtils:configure(config)
    for key, value in pairs(config) do
        self.config[key] = value
    end
    
    return self
end

return MigrationUtils
]]
    migrationUtils.Parent = core
    
    log("Created MigrationUtils module")
    return true
end

-- Main initialization function
local function initialize()
    log("Starting Core Registry initialization...")
    
    -- Ensure critical folders exist
    local foldersCreated = ensureCriticalFolders()
    if not foldersCreated then
        warn_log("Failed to create critical folders!")
    end
    
    -- Ensure the ModuleLoader is available
    local moduleLoader = ensureModuleLoader()
    if not moduleLoader then
        warn_log("Failed to initialize ModuleLoader, continuing with limited functionality")
    end
    
    -- Initialize the CoreRegistry
    local registry = initializeCoreRegistry()
    if not registry then
        warn_log("Failed to initialize CoreRegistry! Game systems may not function correctly.")
        return false
    end
    
    -- Store in global scope for emergency access
    if _G then
        _G.CoreRegistry = registry
        log("CoreRegistry stored in _G for global access")
    end
    
    -- Create health check monitoring
    createCoreRegistryFeedback()
    
    -- Create missing critical modules
    createTutorialManager()
    createMigrationUtils()
    
    log("CoreRegistry initialization complete")
    return true
end

-- Run the initializer
local success, result = pcall(initialize)
if not success then
    warn_log("Error during initialization: " .. tostring(result))
end

-- Return module API
return {
    ensureModuleLoader = ensureModuleLoader,
    initializeCoreRegistry = initializeCoreRegistry
}
