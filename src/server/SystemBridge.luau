--[[
    SystemBridge.luau
    
    Creates a bridge between various systems and ensures they're properly registered
    with the CoreRegistry. This is a helper module to fix issues with missing core systems.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SystemBridge = {}
SystemBridge.debug = true

-- Log function
local function log(message)
    if SystemBridge.debug then
        print("[SystemBridge] " .. message)
    end
end

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[SystemBridge] Failed to require module:", result)
        return nil
    end
end

-- Find module in various locations
local function findModule(moduleName)
    -- Define search paths
    local searchPaths = {
        -- Direct (main) paths first for faster access
        ServerScriptService,
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server"),
        -- Subfolders
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Systems"),
        -- Specialized folders        ServerScriptService:FindFirstChild("GymAutomation"),
        ServerScriptService:FindFirstChild("Data"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Data"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("GymAutomation")
    }
    
    -- Try each path
    for _, path in ipairs(searchPaths) do
        if path then
            -- Try exact name
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Try with .luau extension
            module = path:FindFirstChild(moduleName .. ".luau")
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Try with .server.luau extension
            module = path:FindFirstChild(moduleName .. ".server.luau")
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Get CoreRegistry
function SystemBridge.getCoreRegistry()
    -- Try through ModuleScriptAccessor first
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local ModuleScriptAccessor = safeRequire(shared.ModuleScriptAccessor)
        if ModuleScriptAccessor and typeof(ModuleScriptAccessor.getCoreRegistry) == "function" then
            local CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
            if CoreRegistry then
                return CoreRegistry
            end
        end
    end
    
    -- Direct approach if ModuleScriptAccessor not available
    local coreRegistryModule = findModule("CoreRegistry")
    if coreRegistryModule then
        return safeRequire(coreRegistryModule)
    end
    
    return nil
end

-- Register a system with CoreRegistry
function SystemBridge.registerSystem(systemName)
    local CoreRegistry = SystemBridge.getCoreRegistry()
    if not CoreRegistry then
        warn("[SystemBridge] CoreRegistry not found, cannot register " .. systemName)
        return false
    end
    
    -- Check if system is already registered
    if CoreRegistry.hasSystem and CoreRegistry:hasSystem(systemName) then
        log(systemName .. " is already registered with CoreRegistry")
        return true
    end
    
    -- Find the system module
    local systemModule = findModule(systemName)
    if not systemModule then
        warn("[SystemBridge] Could not find module: " .. systemName)
        return false
    end
    
    -- Require the module
    local system = safeRequire(systemModule)
    if not system then
        warn("[SystemBridge] Failed to require: " .. systemName)
        return false
    end
    
    -- Register the system
    if typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem(systemName, system)
        log("Registered " .. systemName .. " with CoreRegistry")
        return true
    else
        warn("[SystemBridge] CoreRegistry.registerSystem is not a function")
        return false
    end
end

-- Register all critical systems
function SystemBridge.registerCriticalSystems()
    -- Define list of critical systems
    local criticalSystems = {
        "ModuleLoader",
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem",
        "TycoonSystem",
        "EventBridge",
        "GymAutomation" 
    }
    
    -- Force create correct copies of systems if they're missing
    local function ensureSystemExists(systemName)
        -- Check if the system already exists
        local existing = findModule(systemName)
        if existing then
            log("System " .. systemName .. " found at " .. existing:GetFullName())
            return true
        end
        
        -- System is missing, check for copies in other locations
        local alternateLocations = {
            -- Standard paths with extensions
            {ServerScriptService, systemName .. ".luau"},
            {ServerScriptService, systemName .. ".server.luau"},
            {ServerScriptService:FindFirstChild("Core"), systemName .. ".luau"},
            {ServerScriptService:FindFirstChild("Core"), systemName .. ".server.luau"},
            -- Special folder paths
            {ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild(systemName), systemName .. ".luau"},
            {ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"), systemName .. ".luau"},
            {ServerScriptService:FindFirstChild("GymAutomation"), systemName .. ".luau"},
        }
        
        -- Try each alternate location
        for _, location in ipairs(alternateLocations) do
            local folder = location[1]
            local fileName = location[2]
            
            if folder and folder:FindFirstChild(fileName) then
                local module = folder:FindFirstChild(fileName)
                if module and module:IsA("ModuleScript") then
                    -- Found a copy, now create a direct version
                    local copy = module:Clone()
                    copy.Name = systemName
                    copy.Parent = ServerScriptService
                    log("Created copy of " .. systemName .. " in ServerScriptService")
                    return true
                end
            end
        end
        
        log("Could not find " .. systemName .. " in any location", "warn")
        return false
    end
    
    -- Ensure all systems exist
    for _, systemName in ipairs(criticalSystems) do
        ensureSystemExists(systemName)
    end
    
    -- Register systems with CoreRegistry
    local successCount = 0
    for _, systemName in ipairs(criticalSystems) do
        if SystemBridge.registerSystem(systemName) then
            successCount += 1
        end
    end
    
    log("Registered " .. successCount .. "/" .. #criticalSystems .. " critical systems")
    
    -- Running health check on CoreRegistry
    local CoreRegistry = SystemBridge.getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.runHealthCheck) == "function" then
        CoreRegistry.runHealthCheck()
    end
    
    return successCount == #criticalSystems
end

return SystemBridge
