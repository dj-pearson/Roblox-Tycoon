--[[
    CoreRegistryInitializer.server.luau
    
    This script initializes the CoreRegistry system early in the game lifecycle 
    to ensure proper availability for other systems. It handles errors gracefully
    and provides fallback mechanisms when core components are missing.
    
    Created as part of the CoreRegistry fix documented in CoreRegistry_Fix_Solution.md
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize once flag
local initialized = false
local initializationAttempts = 0
local MAX_ATTEMPTS = 3

-- Safe require function with timeout
local function safeRequire(module, fallback)
    if not module then
        return fallback
    end
    
    if not module:IsA("ModuleScript") then
        warn("CoreRegistryInitializer: Expected ModuleScript but got " .. module.ClassName .. " for " .. module:GetFullName())
        return fallback
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("CoreRegistryInitializer: Failed to require " .. module:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Find module helper
local function findModule(moduleName)
    -- Search paths in priority order
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
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

-- Ensure a path exists
local function ensurePath(parent, pathArray)
    local current = parent
    for _, name in ipairs(pathArray) do
        local child = current:FindFirstChild(name)
        if not child then
            child = Instance.new("Folder")
            child.Name = name
            child.Parent = current
        end
        current = child
    end
    return current
end

-- Initialize the CoreRegistry
local function initializeCoreRegistry()
    if initialized then
        return true
    end
    
    initializationAttempts += 1
    
    -- Create necessary folders
    ensurePath(ServerScriptService, {"Core"})
    ensurePath(ReplicatedStorage, {"shared"})
    
    print("CoreRegistryInitializer: Initializing CoreRegistry (attempt " .. initializationAttempts .. "/" .. MAX_ATTEMPTS .. ")")
    
    -- Try to get CoreRegistry module
    local coreRegistryModule = findModule("CoreRegistry")
    if not coreRegistryModule then
        warn("CoreRegistryInitializer: Could not find CoreRegistry module")
        
        if initializationAttempts < MAX_ATTEMPTS then
            -- Schedule retry
            task.delay(1, initializeCoreRegistry)
            return false
        else
            warn("CoreRegistryInitializer: Failed to initialize CoreRegistry after " .. MAX_ATTEMPTS .. " attempts")
            return false
        end
    end
    
    -- Load CoreRegistry
    local CoreRegistry = safeRequire(coreRegistryModule)
    if not CoreRegistry then
        warn("CoreRegistryInitializer: CoreRegistry module found but failed to require")
        
        if initializationAttempts < MAX_ATTEMPTS then
            -- Schedule retry
            task.delay(1, initializeCoreRegistry)
            return false
        else
            warn("CoreRegistryInitializer: Failed to initialize CoreRegistry after " .. MAX_ATTEMPTS .. " attempts")
            return false
        end
    end
    
    -- Initialize CoreRegistry
    if CoreRegistry.initialize then
        local success = CoreRegistry.initialize()
        if not success then
            warn("CoreRegistryInitializer: CoreRegistry.initialize() returned false")
            
            if initializationAttempts < MAX_ATTEMPTS then
                -- Schedule retry
                task.delay(1, initializeCoreRegistry)
                return false
            else
                warn("CoreRegistryInitializer: Failed to initialize CoreRegistry after " .. MAX_ATTEMPTS .. " attempts")
                return false
            end
        end
    end
      -- Make sure ModuleLoader is available
    local moduleLoaderModule = findModule("ModuleLoader")
    local ModuleLoader = nil
    
    if moduleLoaderModule then
        ModuleLoader = safeRequire(moduleLoaderModule)
    end
    
    if ModuleLoader then
        print("CoreRegistryInitializer: Registered ModuleLoader with CoreRegistry")
        CoreRegistry.registerSystem("ModuleLoader", ModuleLoader)
    else
        warn("CoreRegistryInitializer: ModuleLoader not found, some dependencies may fail to load")
    end
    
    -- Create a shared reference to CoreRegistry
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if not sharedFolder then
        sharedFolder = Instance.new("Folder")
        sharedFolder.Name = "shared"
        sharedFolder.Parent = ReplicatedStorage
    end
    
    -- Create a ModuleScript that returns CoreRegistry
    local coreRegistryRef = sharedFolder:FindFirstChild("CoreRegistryRef")
    if not coreRegistryRef then
        coreRegistryRef = Instance.new("ModuleScript")
        coreRegistryRef.Name = "CoreRegistryRef"
        coreRegistryRef.Source = "return require(game:GetService('ServerScriptService').Core.CoreRegistry)"
        coreRegistryRef.Parent = sharedFolder
    end
    
    print("✅ CoreRegistryInitializer: CoreRegistry successfully initialized!")
    initialized = true
    return true
end

-- Initialize CoreRegistry when script runs
initializeCoreRegistry()
