--[[
    SystemBootstrap.server.luau
    This script is responsible for initializing all core systems in the correct order.
    It ensures that dependencies are properly resolved and handles initialization failures.
    
    Created to fix critical "SystemBootstrap Critical Failures" reported in RobloxIssues.txt
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- First, ensure required paths exist
local function ensurePath(parent, pathArray)
    local current = parent
    for _, name in ipairs(pathArray) do
        local child = current:FindFirstChild(name)
        if not child then
            child = Instance.new("Folder")
            child.Name = name
            child.Parent = current
            print("SystemBootstrap: Created folder " .. name .. " in " .. current:GetFullName())
        end
        current = child
    end
    return current
end

-- Create required folders
local coreFolder = ensurePath(ServerScriptService, {"Core"})
local sharedFolder = ensurePath(ReplicatedStorage, {"shared"})

-- Helper function for safely requiring modules
local function safeRequire(modulePath, timeout)
    local startTime = os.clock()
    timeout = timeout or 5
    
    -- Quick check if module exists
    if typeof(modulePath) ~= "Instance" then
        return nil
    end
    
    -- Try to require the module
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        warn("SystemBootstrap: Failed to require module: " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find module across different paths
local function findModule(moduleName)
    local searchPaths = {
        coreFolder,
        ServerScriptService,
        sharedFolder,
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        local module = path:FindFirstChild(moduleName)
        if module and module:IsA("ModuleScript") then
            return module
        end
    end
    
    return nil
end

print("SystemBootstrap: Starting system initialization...")

-- Define systems to initialize in order
local systems = {
    {
        name = "FolderSetup",
        required = true,
        dependencies = {},
        initFunction = function()
            local setupModule = findModule("FolderSetup")
            if setupModule then
                -- It's a script, not a module, so it should run automatically
                return true
            end
            return false
        end
    },
    {
        name = "CoreRegistry",
        required = true,
        dependencies = {},
        initFunction = function()
            local coreRegistry = safeRequire(findModule("CoreRegistry"))
            if coreRegistry and coreRegistry.initialize then
                local success = coreRegistry.initialize()
                if success then
                    print("SystemBootstrap: CoreRegistry initialized successfully")
                    return true
                end
            end
            return false
        end
    },
    {
        name = "ModuleLoader",
        required = true,
        dependencies = {},
        initFunction = function()
            local moduleLoader = safeRequire(findModule("ModuleLoader"))
            if moduleLoader and moduleLoader.addSearchPath then
                -- Add standard search paths
                moduleLoader.addSearchPath(coreFolder)
                moduleLoader.addSearchPath(sharedFolder)
                
                print("SystemBootstrap: ModuleLoader initialized successfully")
                return true
            end
            return false
        end
    },
    {
        name = "SafeRequireModule",
        required = true,
        dependencies = {"ModuleLoader"},
        initFunction = function()
            local safeRequireModule = safeRequire(findModule("SafeRequire"))
            if safeRequireModule and type(safeRequireModule) == "function" then
                print("SystemBootstrap: SafeRequireModule initialized successfully")
                _G.SafeRequire = safeRequireModule
                return true
            end
            return false
        end
    },
    {
        name = "DataManager",
        required = true,
        dependencies = {"CoreRegistry"},
        initFunction = function()
            local coreRegistry = safeRequire(findModule("CoreRegistry"))
            if not coreRegistry then
                return false
            end
            
            local dataManager = safeRequire(findModule("DataManager"))
            if dataManager and coreRegistry.registerSystem then
                coreRegistry.registerSystem("DataManager", dataManager)
                
                if dataManager.initialize then
                    local success = dataManager.initialize()
                    if success then
                        print("SystemBootstrap: DataManager initialized successfully")
                        return true
                    end
                    return false
                end
                return true
            end
            return false
        end
    },
    {
        name = "EventBridge",
        required = false,
        dependencies = {"CoreRegistry"},
        initFunction = function()
            local coreRegistry = safeRequire(findModule("CoreRegistry"))
            if not coreRegistry then
                return false
            end
            
            local eventBridge = safeRequire(findModule("EventBridge"))
            if eventBridge and coreRegistry.registerSystem then
                coreRegistry.registerSystem("EventBridge", eventBridge)
                
                if eventBridge.initialize then
                    local success = eventBridge.initialize()
                    if success then
                        print("SystemBootstrap: EventBridge initialized successfully")
                        return true
                    end
                    return false
                end
                return true
            end
            return false
        end
    },
    {
        name = "GymAutomation",
        required = false,
        dependencies = {"CoreRegistry", "ModuleLoader"},
        initFunction = function()
            -- Rely on the GymAutomationLoader script to handle this
            -- Just check if the module exists and can be accessed
            local moduleLoader = safeRequire(findModule("ModuleLoader"))
            if moduleLoader then
                local gymAutomation = moduleLoader.loadModule("GymAutomation")
                if gymAutomation then
                    print("SystemBootstrap: GymAutomation found")
                    return true
                end
            end
            
            print("SystemBootstrap: GymAutomation not found, will be loaded separately")
            return true -- Not required, so return true anyway
        end
    }
}

-- Track initialization status
local systemStatus = {}
local allRequiredSucceeded = true

-- Helper function to initialize a system
local function initializeSystem(system)
    if systemStatus[system.name] ~= nil then
        return systemStatus[system.name]
    end
    
    -- Check dependencies first
    for _, dependency in ipairs(system.dependencies) do
        local dependencySucceeded = false
        
        -- Find the dependency in our systems list
        for _, depSystem in ipairs(systems) do
            if depSystem.name == dependency then
                dependencySucceeded = initializeSystem(depSystem)
                break
            end
        end
        
        if not dependencySucceeded then
            warn("[SystemBootstrap][Error] Required dependency failed: " .. dependency .. " for system: " .. system.name)
            systemStatus[system.name] = false
            return false
        end
    end
    
    -- Initialize the system
    local success = system.initFunction()
    systemStatus[system.name] = success
    
    if not success then
        warn("[SystemBootstrap][Error] Failed to initialize " .. (system.required and "required " or "") .. "system: " .. system.name)
        if system.required then
            warn("[SystemBootstrap][Error] CRITICAL: Required system failed: " .. system.name)
            allRequiredSucceeded = false
        end
    end
    
    return success
end

-- Initialize all systems
for _, system in ipairs(systems) do
    initializeSystem(system)
end

-- Check if all required systems initialized successfully
if allRequiredSucceeded then
    print("✅ SystemBootstrap: All required systems initialized successfully!")
else
    warn("[SystemBootstrap][Error] CRITICAL: Some required systems failed to initialize. Game may not function correctly.")
end
