--[[
    CoreRegistryBridge.server.luau
    
    Helper module for connecting systems to CoreRegistry.
    Created May 1, 2025 to solve BuyTile system integration issues.
    
    This module helps systems like BuyTilePositionFixer find and register with
    CoreRegistry without circular dependencies.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CoreRegistryBridge = {}

-- Find CoreRegistry through multiple methods
function CoreRegistryBridge.getCoreRegistry()
    -- Try direct paths first
    local coreRegistryPaths = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("server") and ServerScriptService.server:FindFirstChild("Core") and ServerScriptService.server.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry"),
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("CoreRegistry"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild("CoreRegistry")
    }
    
    for _, path in ipairs(coreRegistryPaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                return result
            end
        end
    end
    
    -- Try SafeRequire if available
    local safeRequirePaths = {
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("SafeRequire"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild("SafeRequire")
    }
    
    for _, path in ipairs(safeRequirePaths) do
        if path then
            local success, safeRequire = pcall(function()
                return require(path)
            end)
            
            if success and safeRequire and typeof(safeRequire.requireFromPath) == "function" then
                local CoreRegistry = safeRequire.requireFromPath("CoreRegistry")
                if CoreRegistry then
                    return CoreRegistry
                end
            end
        end
    end
    
    -- Try ModuleLoader if available
    local moduleLoaderPaths = {
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoader"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild("ModuleLoader")
    }
    
    for _, path in ipairs(moduleLoaderPaths) do
        if path then
            local success, moduleLoader = pcall(function()
                return require(path)
            end)
            
            if success and moduleLoader and typeof(moduleLoader.require) == "function" then
                local CoreRegistry = moduleLoader.require("CoreRegistry")
                if CoreRegistry then
                    return CoreRegistry
                end
            end
        end
    end
    
    -- No CoreRegistry found
    return nil
end

-- Find a system in CoreRegistry
function CoreRegistryBridge.getSystem(systemName)
    local CoreRegistry = CoreRegistryBridge.getCoreRegistry()
    
    if CoreRegistry then
        -- Try common accessor function patterns
        if typeof(CoreRegistry.getSystem) == "function" then
            return CoreRegistry.getSystem(systemName)
        elseif typeof(CoreRegistry.GetSystem) == "function" then
            return CoreRegistry.GetSystem(systemName)
        elseif typeof(CoreRegistry.get) == "function" then
            return CoreRegistry.get(systemName)
        elseif typeof(CoreRegistry.Get) == "function" then
            return CoreRegistry.Get(systemName)
        elseif CoreRegistry[systemName] then
            return CoreRegistry[systemName]
        end
    end
    
    -- Fallback: direct lookup of module
    local systemPaths = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild(systemName),
        ServerScriptService:FindFirstChild("server") and ServerScriptService.server:FindFirstChild("Core") and ServerScriptService.server.Core:FindFirstChild(systemName),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild(systemName),
        ServerScriptService:FindFirstChild("Systems") and ServerScriptService.Systems:FindFirstChild(systemName)
    }
    
    for _, path in ipairs(systemPaths) do
        if path and path:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(path)
            end)
            
            if success and result then
                return result
            end
        end
    end
    
    return nil
end

-- Register a system with CoreRegistry
function CoreRegistryBridge.registerSystem(systemName, systemInstance)
    local CoreRegistry = CoreRegistryBridge.getCoreRegistry()
    
    if CoreRegistry then
        -- Try common registration function patterns
        if typeof(CoreRegistry.registerSystem) == "function" then
            return CoreRegistry.registerSystem(systemName, systemInstance)
        elseif typeof(CoreRegistry.RegisterSystem) == "function" then
            return CoreRegistry.RegisterSystem(systemName, systemInstance)
        elseif typeof(CoreRegistry.register) == "function" then
            return CoreRegistry.register(systemName, systemInstance)
        elseif typeof(CoreRegistry.Register) == "function" then
            return CoreRegistry:Register(systemName, systemInstance)
        elseif typeof(CoreRegistry.add) == "function" then
            return CoreRegistry.add(systemName, systemInstance)
        end
    end
    
    print("[CoreRegistryBridge] Could not register system " .. systemName .. " as CoreRegistry was not found")
    return false
end

-- Check CoreRegistry health and return its status
function CoreRegistryBridge.getRegistryStatus()
    local CoreRegistry = CoreRegistryBridge.getCoreRegistry()
    
    if not CoreRegistry then
        return "NotFound"
    end
    
    -- Try to access status property
    if CoreRegistry.status then
        return CoreRegistry.status
    elseif CoreRegistry.Status then
        return CoreRegistry.Status
    elseif typeof(CoreRegistry.getStatus) == "function" then
        return CoreRegistry.getStatus()
    elseif typeof(CoreRegistry.GetStatus) == "function" then
        return CoreRegistry.GetStatus()
    end
    
    -- Count registered systems as a health check
    local systemCount = 0
    
    if typeof(CoreRegistry.getSystems) == "function" then
        local systems = CoreRegistry.getSystems()
        systemCount = typeof(systems) == "table" and #systems or 0
    elseif typeof(CoreRegistry.systems) == "table" then
        systemCount = #CoreRegistry.systems
    elseif typeof(CoreRegistry.Systems) == "table" then
        systemCount = #CoreRegistry.Systems
    end
    
    if systemCount > 5 then
        return "Healthy"
    elseif systemCount > 0 then
        return "Degraded"
    else
        return "Error"
    end
end

print("✅ CoreRegistryBridge: Initialized and ready to help systems connect to CoreRegistry")

return CoreRegistryBridge
