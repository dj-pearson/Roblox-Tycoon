--[[
    ClientBootstrap.client.luau
    
    Client-side initialization system that loads ModuleLoader, ClientRegistry, and UIComponents.
    Handles errors gracefully and creates fallbacks for critical components.
    
    Created as part of the ClientBootstrap fix documented in ClientBootstrap_Fix_Documentation.md
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")

-- Initialization states
local initialized = false
local initializationAttempts = 0
local MAX_ATTEMPTS = 3

-- Critical component statuses
local componentStatus = {
    ModuleLoader = false,
    ClientRegistry = false,
    UIComponents = false
}

-- Safe require helper
local function safeRequire(moduleInstance, fallback)
    if not moduleInstance then
        return fallback
    end
    
    if not moduleInstance:IsA("ModuleScript") then
        warn("ClientBootstrap: Expected ModuleScript but got " .. moduleInstance.ClassName .. " for " .. moduleInstance:GetFullName())
        return fallback
    end
    
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if success then
        return result
    else
        warn("ClientBootstrap: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Safe wait for child with timeout
local function safeWaitForChild(parent, childName, timeout)
    timeout = timeout or 5 -- Default timeout of 5 seconds
    
    -- Quick check
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    -- Use timeout to prevent infinite yield
    local startTime = os.clock()
    while not child and (os.clock() - startTime) < timeout do
        child = parent:FindFirstChild(childName)
        if child then break end
        task.wait(0.1)
    end
    
    return child
end

-- Find module across search paths
local function findModule(moduleName)
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage,
        playerScripts:FindFirstChild("shared"),
        playerScripts:FindFirstChild("Client"),
        playerScripts:FindFirstChild("Client", "Core"),
        playerScripts
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Ensure path exists
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

-- Initialize the client systems
local function initializeClientSystems()
    if initialized then
        return true
    end
    
    initializationAttempts += 1
    print("ClientBootstrap: Initializing client systems (attempt " .. initializationAttempts .. "/" .. MAX_ATTEMPTS .. ")")
    
    -- Create necessary folders
    ensurePath(playerScripts, {"Client", "Core"})
    ensurePath(playerScripts, {"Client", "UI"})
    ensurePath(playerScripts, {"shared"})
    
    -- 1. Try to get ModuleLoader
    local ModuleLoader
    local moduleLoaderInstance = findModule("ModuleLoader")
    
    if moduleLoaderInstance then
        ModuleLoader = safeRequire(moduleLoaderInstance)
        if ModuleLoader then
            componentStatus.ModuleLoader = true
            print("ClientBootstrap: ModuleLoader loaded successfully")
            
            -- Make it available globally for other scripts
            _G.ModuleLoader = ModuleLoader
        end
    end
    
    if not ModuleLoader then
        warn("ClientBootstrap: ModuleLoader not found, some system initialization may fail")
    end
    
    -- 2. Try to get ClientRegistry
    local ClientRegistry
    local clientRegistryInstance = findModule("ClientRegistry")
    
    if clientRegistryInstance then
        ClientRegistry = safeRequire(clientRegistryInstance)
        if ClientRegistry then
            componentStatus.ClientRegistry = true
            print("ClientBootstrap: ClientRegistry loaded successfully")
            
            -- Make it available globally for other scripts
            _G.ClientRegistry = ClientRegistry
            
            -- Initialize ClientRegistry if needed
            if typeof(ClientRegistry.initialize) == "function" and not ClientRegistry.isInitialized then
                ClientRegistry.initialize()
            end
            
            -- Register ModuleLoader with ClientRegistry if both are available
            if ModuleLoader and typeof(ClientRegistry.registerSystem) == "function" then
                ClientRegistry.registerSystem("ModuleLoader", ModuleLoader)
            end
        end
    end
    
    if not ClientRegistry then
        warn("ClientBootstrap: Failed to get ClientRegistry, cannot proceed with initialization")
        
        if initializationAttempts < MAX_ATTEMPTS then
            -- Schedule retry
            task.delay(1, initializeClientSystems)
            return false
        end
    end
    
    -- 3. Try to get UIComponents
    local UIComponents
    local uiComponentsInstance = findModule("UIComponents")
    
    if uiComponentsInstance then
        UIComponents = safeRequire(uiComponentsInstance)
        if UIComponents then
            componentStatus.UIComponents = true
            print("ClientBootstrap: UIComponents loaded successfully")
            
            -- Make it available globally for other scripts
            _G.UIComponents = UIComponents
            
            -- Register UIComponents with ClientRegistry if both are available
            if ClientRegistry and typeof(ClientRegistry.registerSystem) == "function" then
                ClientRegistry.registerSystem("UIComponents", UIComponents)
            end
        end
    end
    
    if not UIComponents then
        warn("ClientBootstrap: Could not find module for system: UIComponents")
    end
    
    -- Report initialization status
    local successCount = 0
    for component, status in pairs(componentStatus) do
        if status then
            successCount += 1
        end
    end
    
    local successRate = math.floor((successCount / 3) * 100)
    print("ClientBootstrap: Initialization completed with " .. successRate .. "% success rate")
    
    -- Consider initialization successful if at least ClientRegistry is available
    if componentStatus.ClientRegistry then
        print("✅ ClientBootstrap: Client system initialization complete")
        initialized = true
        return true
    else
        warn("❌ ClientBootstrap: Critical component ClientRegistry failed to initialize")
        
        if initializationAttempts < MAX_ATTEMPTS then
            -- Schedule retry
            task.delay(1, initializeClientSystems)
            return false
        else
            warn("ClientBootstrap: Failed to initialize client systems after " .. MAX_ATTEMPTS .. " attempts")
            return false
        end
    end
end

-- Start initialization
initializeClientSystems()
