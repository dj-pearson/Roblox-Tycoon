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
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Systems"),
        ServerScriptService
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
    
    local successCount = 0
    for _, systemName in ipairs(criticalSystems) do
        if SystemBridge.registerSystem(systemName) then
            successCount += 1
        end
    end
    
    log("Registered " .. successCount .. "/" .. #criticalSystems .. " critical systems")
    return successCount == #criticalSystems
end

return SystemBridge
