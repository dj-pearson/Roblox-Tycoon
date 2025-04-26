--[[
    ClientBootstrap.client.luau
    
    Initializes the client environment and loads essential modules.
    
    Created: April 25, 2025
    Updated: April 25, 2025 - Enhanced with SafeWaitForChild and robust error handling
    
    This script:
    1. Loads early in the client lifecycle
    2. Initializes the ModuleLoader
    3. Ensures the ClientRegistry is loaded
    4. Loads and initializes core UI modules
    5. Handles error recovery for critical systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local LocalPlayer = Players.LocalPlayer
local DEBUG_ENABLED = true
local WAIT_TIMEOUT = 5  -- Seconds to wait for modules before timeout

-- Debug logging
local function log(message)
    if DEBUG_ENABLED then
        print("[ClientBootstrap] " .. message)
    end
end

local function warn_log(message)
    warn("[ClientBootstrap] " .. message)
end

-- First, get SafeWaitForChild to help prevent infinite yield errors
local SafeWaitForChild
do
    -- Try to find in shared folder
    local sharedFolderWait = ReplicatedStorage:FindFirstChild("shared")
    if not sharedFolderWait then
        sharedFolderWait = Instance.new("Folder")
        sharedFolderWait.Name = "shared"
        sharedFolderWait.Parent = ReplicatedStorage
        log("Created shared folder in ReplicatedStorage")
    end
    
    local safeWaitModule = sharedFolderWait:FindFirstChild("SafeWaitForChild")
    if safeWaitModule and safeWaitModule:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(safeWaitModule)
        end)
        
        if success then
            SafeWaitForChild = result
            log("Found and loaded SafeWaitForChild module")
        else
            warn_log("Error loading SafeWaitForChild: " .. tostring(result))
        end
    end
    
    -- If not found, create a minimal version
    if not SafeWaitForChild then
        log("SafeWaitForChild not found, creating minimal version")
        
        SafeWaitForChild = {
            waitForChild = function(parent, childName, timeout)
                timeout = timeout or WAIT_TIMEOUT
                
                -- Check if child already exists
                local child = parent:FindFirstChild(childName)
                if child then return child, false end
                
                -- Wait with timeout
                local startTime = os.clock()
                while os.clock() - startTime < timeout do
                    child = parent:FindFirstChild(childName)
                    if child then return child, false end
                    task.wait(0.1)
                end
                
                warn_log("Timed out waiting for " .. childName .. " in " .. parent:GetFullName())
                return nil, false
            end
        }
    end
end

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn_log("Failed to require module: " .. (typeof(module) == "Instance" and module:GetFullName() or tostring(module)))
        return nil
    end
    
    return result
end

-- Ensure a folder exists, creating it if needed
local function ensureFolderExists(parent, folderName)
    local folder = parent:FindFirstChild(folderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = parent
        log("Created folder: " .. folderName .. " in " .. parent:GetFullName())
    end
    return folder
end

-- Storage for module references
local modules = {}

-- Stage 1: Setup Essential Folders
local function setupFolders()
    log("Setting up essential folders")
    
    -- Ensure shared folder exists in ReplicatedStorage
    local sharedFolder = ensureFolderExists(ReplicatedStorage, "shared")
    
    -- Ensure client folder exists in PlayerScripts
    local clientFolder = ensureFolderExists(LocalPlayer.PlayerScripts, "Client")
    
    -- Ensure Core folder exists in client folder
    local coreFolder = ensureFolderExists(clientFolder, "Core")
    
    -- Ensure UI folder exists in client folder
    local uiFolder = ensureFolderExists(clientFolder, "UI")
    
    return true
end

-- Stage 2: Load ModuleLoader
local function loadModuleLoader()
    log("Loading ModuleLoader")
    
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if not sharedFolder then
        warn_log("Shared folder not found, cannot load ModuleLoader")
        return false
    end
    
    -- Try to find ModuleLoader in shared folder
    local moduleLoader = sharedFolder:FindFirstChild("ModuleLoader")
    if moduleLoader and moduleLoader:IsA("ModuleScript") then
        local loaderModule = requireSafely(moduleLoader)
        if loaderModule then
            -- Initialize ModuleLoader
            if typeof(loaderModule.initialize) == "function" then
                loaderModule.initialize()
            end
            
            modules.ModuleLoader = loaderModule
            log("ModuleLoader initialized")
            return true
        end
    end
    
    warn_log("ModuleLoader not found, some modules may fail to load")
    return false
end

-- Stage 3: Load ClientRegistry
local function loadClientRegistry()
    log("Loading ClientRegistry")
    
    local clientRegistry
    
    -- Try multiple ways to get ClientRegistry
    local attempts = {
        -- First try path in client folder
        function()
            local clientFolder = LocalPlayer.PlayerScripts:FindFirstChild("Client")
            if clientFolder and clientFolder:FindFirstChild("Core") then
                local registryModule = clientFolder.Core:FindFirstChild("ClientRegistry")
                if registryModule then
                    return requireSafely(registryModule)
                end
            end
            return nil
        end,
        
        -- Then try in shared folder
        function()
            local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
            if sharedFolder and sharedFolder:FindFirstChild("ClientRegistry") then
                return requireSafely(sharedFolder.ClientRegistry)
            end
            return nil
        end,
        
        -- Then try using ModuleLoader
        function()
            if modules.ModuleLoader and typeof(modules.ModuleLoader.tryRequire) == "function" then
                return modules.ModuleLoader.tryRequire("ClientRegistry")
            end
            return nil
        end
    }
    
    -- Try each method
    for i, attemptFunc in ipairs(attempts) do
        clientRegistry = attemptFunc()
        if clientRegistry then
            log("Found ClientRegistry using method #" .. i)
            break
        end
    end
    
    if not clientRegistry then
        warn_log("ClientRegistry not found, UI systems may not function correctly")
        return false
    end
    
    -- Initialize ClientRegistry
    if typeof(clientRegistry.initialize) == "function" and not clientRegistry.initialized then
        clientRegistry.initialize()
    end
    
    modules.ClientRegistry = clientRegistry
    log("ClientRegistry initialized")
    return true
end

-- Stage 4: Load UI Components
local function loadUIComponents()
    log("Loading UI Components")
    
    local uiComponents
    
    -- Try to find UIComponents in shared folder
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if sharedFolder and sharedFolder:FindFirstChild("UIComponents") then
        uiComponents = requireSafely(sharedFolder.UIComponents)
    end
    
    -- Try using ModuleLoader if available
    if not uiComponents and modules.ModuleLoader then
        uiComponents = modules.ModuleLoader.tryRequire("UIComponents")
    end
    
    if not uiComponents then
        warn_log("UIComponents not found, UI may not display correctly")
        return false
    end
    
    -- Register with ClientRegistry if available
    if modules.ClientRegistry and typeof(uiComponents.registerWithClientRegistry) == "function" then
        uiComponents.registerWithClientRegistry(modules.ClientRegistry)
    end
    
    modules.UIComponents = uiComponents
    log("UIComponents loaded")
    return true
end

-- Stage 5: Initialize Core Systems
local function initializeCoreSystems()
    log("Initializing Core Systems")
    
    if not modules.ClientRegistry then
        warn_log("ClientRegistry not available for system initialization")
        return false
    end
    
    -- Core systems to initialize in order
    local coreSystems = {
        "UIManager",
        "NotificationManager",
        "DataManager",
        "InputManager"
    }
    
    local initializedCount = 0
    for _, systemName in ipairs(coreSystems) do
        if modules.ClientRegistry.initializeSystem and 
           modules.ClientRegistry:initializeSystem(systemName) then
            initializedCount = initializedCount + 1
        end
    end
    
    log("Core systems initialized: " .. initializedCount .. "/" .. #coreSystems)
    return initializedCount > 0
end

-- Run bootstrap process
local function runBootstrap()
    log("Starting client bootstrap")
    
    local stages = {
        {name = "Setup Folders", func = setupFolders},
        {name = "Load ModuleLoader", func = loadModuleLoader},
        {name = "Load ClientRegistry", func = loadClientRegistry},
        {name = "Load UI Components", func = loadUIComponents},
        {name = "Initialize Core Systems", func = initializeCoreSystems}
    }
    
    local successfulStages = 0
    
    for i, stage in ipairs(stages) do
        log("Running bootstrap stage " .. i .. "/" .. #stages .. ": " .. stage.name)
        
        local success, result = pcall(function()
            return stage.func()
        end)
        
        if success and result then
            log("Stage " .. i .. " completed successfully")
            successfulStages = successfulStages + 1
        else
            warn_log("Stage " .. i .. " failed: " .. tostring(result))
            
            -- Critical early stages
            if i <= 2 then
                warn_log("Critical stage failed, bootstrap incomplete")
                break
            end
        end
    end
    
    log("Bootstrap complete: " .. successfulStages .. "/" .. #stages .. " stages successful")
    return successfulStages == #stages
end

-- Export any critical modules to the shared environment safely
local function exportModules()
    -- Create a safe reference accessor
    local ClientBootstrap = {
        getModuleLoader = function() return modules.ModuleLoader end,
        getClientRegistry = function() return modules.ClientRegistry end,
        getUIComponents = function() return modules.UIComponents end
    }
    
    return ClientBootstrap
end

-- Run the bootstrap process and return the interface
local success, result = pcall(runBootstrap)

if not success then
    warn_log("Critical error during bootstrap: " .. tostring(result))
    
    -- Attempt recovery
    pcall(function()
        log("Attempting recovery of critical systems")
        loadClientRegistry()
        loadUIComponents()
    end)
end

return exportModules()
