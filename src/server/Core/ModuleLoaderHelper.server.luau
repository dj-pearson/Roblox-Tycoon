--!strict
--[[
    ModuleLoaderHelper.server.luau
    Helper script to fix module loading errors across the codebase
    
    This should be called from other modules near the top of their files:
    
    local ModuleLoaderHelper = require(script.Parent.ModuleLoaderHelper)
    local CoreRegistry = ModuleLoaderHelper:GetCoreRegistry()
    local EventBridge = ModuleLoaderHelper:GetModule("EventBridge")
    local DataManager = ModuleLoaderHelper:GetModule("DataManager")
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Cache for loaded modules
local moduleCache = {}

local ModuleLoaderHelper = {}

-- Try to get ModuleLoader instance, with caching
function ModuleLoaderHelper:GetModuleLoader()
    if moduleCache.ModuleLoader then
        return moduleCache.ModuleLoader
    end
    
    local success, result = pcall(function()
        return require(ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("ModuleLoader"))
    end)
    
    if success and result then
        moduleCache.ModuleLoader = result
        print("[ModuleLoaderHelper] Successfully loaded ModuleLoader")
        return result
    end
    
    print("[ModuleLoaderHelper] ModuleLoader not found, using fallback methods")
    return nil
end

-- Get the CoreRegistry module using various methods
function ModuleLoaderHelper:GetCoreRegistry()
    if moduleCache.CoreRegistry then
        return moduleCache.CoreRegistry
    end
    
    -- First try ModuleLoader
    local moduleLoader = self:GetModuleLoader()
    if moduleLoader then
        local coreRegistry = moduleLoader:LoadServerModule("Core", "CoreRegistry")
        if coreRegistry then
            moduleCache.CoreRegistry = coreRegistry
            print("[ModuleLoaderHelper] Loaded CoreRegistry using ModuleLoader")
            return coreRegistry
        end
    end
    
    -- Try direct require from different paths
    local paths = {
        function() return require(ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Core"):FindFirstChild("CoreRegistry")) end,
        function() return require(ServerScriptService:FindFirstChild("Core"):FindFirstChild("CoreRegistry")) end,
        function() return require(ServerScriptService:FindFirstChild("Server"):FindFirstChild("Core"):FindFirstChild("CoreRegistry")) end
    }
    
    for i, pathFunc in ipairs(paths) do
        local success, result = pcall(pathFunc)
        if success and result then
            moduleCache.CoreRegistry = result
            print("[ModuleLoaderHelper] Loaded CoreRegistry using path method #" .. i)
            return result
        end
    end
    
    warn("[ModuleLoaderHelper] Failed to load CoreRegistry!")
    return nil
end

-- Get any module using various methods
function ModuleLoaderHelper:GetModule(moduleName, category)
    category = category or "Core"
    
    if moduleCache[moduleName] then
        return moduleCache[moduleName]
    end
    
    -- First try CoreRegistry (most reliable once it's loaded)
    local coreRegistry = self:GetCoreRegistry()
    if coreRegistry and coreRegistry.getSystem then
        local module = coreRegistry.getSystem(moduleName)
        if module then
            moduleCache[moduleName] = module
            return module
        end
    end
    
    -- Next try ModuleLoader
    local moduleLoader = self:GetModuleLoader()
    if moduleLoader then
        local module = moduleLoader:LoadServerModule(category, moduleName)
        if module then
            moduleCache[moduleName] = module
            print("[ModuleLoaderHelper] Loaded " .. moduleName .. " using ModuleLoader")
            return module
        end
    end
    
    -- Try direct require from script.Parent
    if script and script.Parent then
        local success, result = pcall(function()
            return require(script.Parent:FindFirstChild(moduleName))
        end)
        
        if success and result then
            moduleCache[moduleName] = result
            print("[ModuleLoaderHelper] Loaded " .. moduleName .. " from script.Parent")
            return result
        end
    end
    
    -- Try direct require from different paths
    local serverCore = ServerScriptService:FindFirstChild("src") and 
                       ServerScriptService.src:FindFirstChild("server") and 
                       ServerScriptService.src.server:FindFirstChild("Core")
                       
    if serverCore and serverCore:FindFirstChild(moduleName) then
        local success, result = pcall(function()
            return require(serverCore:FindFirstChild(moduleName))
        end)
        
        if success and result then
            moduleCache[moduleName] = result
            print("[ModuleLoaderHelper] Loaded " .. moduleName .. " from server/Core")
            return result
        end
    end
    
    warn("[ModuleLoaderHelper] Failed to load module: " .. moduleName)
    return nil
end

-- Get the event bridge module (commonly needed)
function ModuleLoaderHelper:GetEventBridge()
    return self:GetModule("EventBridge")
end

-- Get the data manager module (commonly needed)
function ModuleLoaderHelper:GetDataManager()
    return self:GetModule("DataManager")
end

-- Get any DataStore through the DataManager
function ModuleLoaderHelper:GetDataStore(storeName)
    local dataManager = self:GetDataManager()
    if not dataManager or not dataManager.getDataStore then
        warn("[ModuleLoaderHelper] DataManager not available for getting DataStore: " .. storeName)
        return nil
    end
    
    return dataManager.getDataStore(storeName)
end

-- Register a module with CoreRegistry
function ModuleLoaderHelper:RegisterModule(name, module, dependencies)
    dependencies = dependencies or {}
    
    local coreRegistry = self:GetCoreRegistry()
    if not coreRegistry or not coreRegistry.registerSystem then
        warn("[ModuleLoaderHelper] CoreRegistry not available for registering " .. name)
        return module
    end
    
    return coreRegistry.registerSystem(name, module, dependencies)
end

-- Helper to create basic event connection when EventBridge isn't available
function ModuleLoaderHelper:SafeConnect(eventName, callback)
    local eventBridge = self:GetEventBridge()
    if eventBridge and eventBridge.connectEvent then
        eventBridge:connectEvent(eventName, callback)
        print("[ModuleLoaderHelper] Connected to event: " .. eventName .. " using EventBridge")
        return true
    else
        warn("[ModuleLoaderHelper] EventBridge not available for connecting to: " .. eventName)
        return false
    end
end

return ModuleLoaderHelper
