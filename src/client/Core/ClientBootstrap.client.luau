--[[
    ClientBootstrap.client.luau
    This script initializes the client-side systems in the proper order.
    It handles client-side UI systems, component registration, and error recovery.
    
    Created to fix critical "ClientBootstrap Initialization Failures" reported in RobloxIssues.txt
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

print("ClientBootstrap: Starting initialization...")

-- First, ensure required paths exist
local function ensurePath(parent, pathArray)
    local current = parent
    for _, name in ipairs(pathArray) do
        local child = current:FindFirstChild(name)
        if not child then
            child = Instance.new("Folder")
            child.Name = name
            child.Parent = current
            print("ClientBootstrap: Created folder " .. name .. " in " .. current:GetFullName())
        end
        current = child
    end
    return current
end

-- Create required folders
local sharedFolder = ensurePath(ReplicatedStorage, {"shared"})

-- Helper function for safely requiring modules
local function safeRequire(modulePath, fallback)
    -- Check if module exists
    if typeof(modulePath) ~= "Instance" then
        return fallback
    end
    
    -- Try to require the module
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        warn("ClientBootstrap: Failed to require module: " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
    
    return result
end

-- Find module across different paths
local function findModule(moduleName)
    local searchPaths = {
        player:WaitForChild("PlayerScripts", 5):FindFirstChild("Core"),
        player:WaitForChild("PlayerScripts", 5),
        sharedFolder,
        ReplicatedStorage
    }
    
    for i, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Safe wait for child with timeout
local function safeWaitForChild(parent, childName, timeout)
    timeout = timeout or 5
    
    -- Quick check first
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    -- Use timeout to prevent infinite yield
    local startTime = os.clock()
    local success, result = pcall(function()
        return parent:WaitForChild(childName, timeout)
    end)
    
    if success and result then
        return result
    end
    
    -- Manual polling as fallback
    while not child and (os.clock() - startTime) < timeout do
        task.wait(0.1)
        child = parent:FindFirstChild(childName)
    end
    
    if not child then
        warn("ClientBootstrap: Timeout waiting for " .. childName .. " in " .. parent:GetFullName())
    end
    
    return child
end

-- Initialize ClientRegistry
local function initializeClientRegistry()
    print("ClientBootstrap: Initializing ClientRegistry...")
    
    local clientRegistryModule = findModule("ClientRegistry")
    if not clientRegistryModule then
        warn("ClientBootstrap: Could not find ClientRegistry module")
        
        -- Check if it exists but is not a ModuleScript
        local badModule = sharedFolder:FindFirstChild("ClientRegistry")
        if badModule and not badModule:IsA("ModuleScript") then
            warn("ClientBootstrap: Found ClientRegistry but it's not a ModuleScript, it's a " .. badModule.ClassName)
        end
        
        return nil
    end
    
    local clientRegistry = safeRequire(clientRegistryModule)
    if not clientRegistry then
        warn("[ClientBootstrap] Failed to require module: " .. clientRegistryModule:GetFullName())
        
        -- Try to determine the specific error
        local success, errorMessage = pcall(function()
            return require(clientRegistryModule)
        end)
        
        if not success then
            warn("[ClientBootstrap] Failed to require module: " .. clientRegistryModule:GetFullName() .. " - " .. tostring(errorMessage))
        end
        
        return nil
    end
    
    if type(clientRegistry) ~= "table" or not clientRegistry.registerComponent then
        warn("[ClientBootstrap] Failed to require module: " .. clientRegistryModule:GetFullName() .. " - Module code did not return exactly one value")
        return nil
    end
    
    if clientRegistry.initialize then
        local success = clientRegistry.initialize()
        if not success then
            warn("ClientBootstrap: ClientRegistry initialization failed")
            return nil
        end
    end
    
    print("ClientBootstrap: ClientRegistry initialized successfully")
    return clientRegistry
end

-- Initialize ModuleLoader
local function initializeModuleLoader()
    print("ClientBootstrap: Initializing ModuleLoader...")
    
    local moduleLoaderModule = findModule("ModuleLoader")
    if not moduleLoaderModule then
        warn("ClientBootstrap: Could not find ModuleLoader module")
        return nil
    end
    
    local moduleLoader = safeRequire(moduleLoaderModule)
    if not moduleLoader then
        warn("[ClientBootstrap] Failed to require ModuleLoader module")
        return nil
    end
    
    -- Add standard search paths
    if moduleLoader.addSearchPath then
        moduleLoader.addSearchPath(player:WaitForChild("PlayerScripts", 5))
        moduleLoader.addSearchPath(sharedFolder)
    end
    
    print("ClientBootstrap: ModuleLoader initialized successfully")
    return moduleLoader
end

-- Initialize UIComponents
local function initializeUIComponents(clientRegistry, moduleLoader)
    print("ClientBootstrap: Initializing UIComponents...")
    
    local uiComponentsModule = findModule("UIComponents")
    if not uiComponentsModule then
        warn("[ClientBootstrap] ModuleLoader not found, some system initialization may fail")
        return nil
    end
    
    local uiComponents = safeRequire(uiComponentsModule)
    if not uiComponents then
        warn("[ClientBootstrap] Failed to require UIComponents module")
        return nil
    end
    
    if clientRegistry and uiComponents and clientRegistry.registerSystem then
        clientRegistry.registerSystem("UIComponents", uiComponents)
        print("ClientBootstrap: UIComponents registered with ClientRegistry")
    end
    
    print("ClientBootstrap: UIComponents initialized successfully")
    return uiComponents
end

-- Main initialization sequence
local clientRegistry = initializeClientRegistry()
if not clientRegistry then
    warn("[ClientBootstrap] Failed to get ClientRegistry, cannot proceed with initialization")
else
    _G.ClientRegistry = clientRegistry
end

local moduleLoader = initializeModuleLoader()
if not moduleLoader then
    warn("[ClientBootstrap] ModuleLoader not found, some system initialization may fail")
else
    _G.ModuleLoader = moduleLoader
end

local uiComponents = initializeUIComponents(clientRegistry, moduleLoader)
if not uiComponents then
    warn("[ClientBootstrap] UIComponents not found, UI will not function properly")
else
    _G.UIComponents = uiComponents
end

-- Register completion so other scripts can check if bootstrapping is complete
_G.ClientBootstrapComplete = true
_G.ClientBootstrapFailed = not (clientRegistry and moduleLoader)

print("ClientBootstrap: Initialization complete!")
if _G.ClientBootstrapFailed then
    warn("ClientBootstrap: Some critical systems failed to initialize. UI may not function correctly.")
else
    print("✅ ClientBootstrap: All systems initialized successfully!")
end
