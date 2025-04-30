--[[
    ModuleScriptAccessor.luau
    
    Provides a centralized way to access critical modules and systems across the game.
    This helper module serves as a bridge between different systems and helps resolve dependencies.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local ModuleScriptAccessor = {}

-- Debug settings
ModuleScriptAccessor.DEBUG = true

-- Internal storage for CoreRegistry instance
local cachedCoreRegistry = nil

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[ModuleScriptAccessor] Failed to require module:", result)
        return nil
    end
end

-- Find a module in the workspace
function ModuleScriptAccessor.findModule(moduleName)
    -- Define potential locations based on whether we're on the server or client
    local searchPaths = {}
    
    if RunService:IsServer() then
        -- Server-side search paths
        searchPaths = {
            ServerScriptService:FindFirstChild("Core"),
            ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
            ServerScriptService:FindFirstChild("Systems"),
            ServerScriptService:FindFirstChild("GymAutomation"),
            ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("GymAutomation"),
            ServerScriptService
        }
    end
    
    -- Common search paths for both server and client
    table.insert(searchPaths, ReplicatedStorage:FindFirstChild("shared"))
    table.insert(searchPaths, ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"))
    
    -- Try to find the module
    for _, path in ipairs(searchPaths) do
        if path then
            -- Check for exact name
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Check with .luau extension
            module = path:FindFirstChild(moduleName .. ".luau")
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Check with server/client extension
            local side = RunService:IsServer() and "server" or "client"
            module = path:FindFirstChild(moduleName .. "." .. side .. ".luau")
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Get a system (attempts to use CoreRegistry if available)
function ModuleScriptAccessor.getSystem(systemName)
    -- First try via CoreRegistry
    local CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
    if CoreRegistry and typeof(CoreRegistry.getSystem) == "function" then
        local system = CoreRegistry.getSystem(systemName)
        if system then
            return system
        end
    end
    
    -- Fallback to direct require
    local module = ModuleScriptAccessor.findModule(systemName)
    if module then
        return safeRequire(module)
    end
    
    return nil
end

-- Get CoreRegistry 
function ModuleScriptAccessor.getCoreRegistry()
    -- Try cached registry first
    if cachedCoreRegistry then
        return cachedCoreRegistry
    end
    
    -- Try to find and require the module
    local coreRegistryModule = ModuleScriptAccessor.findModule("CoreRegistry")
    if coreRegistryModule then
        local CoreRegistry = safeRequire(coreRegistryModule)
        if CoreRegistry then
            -- Cache for future use
            cachedCoreRegistry = CoreRegistry
            return CoreRegistry
        end
    end
    
    return nil
end

return ModuleScriptAccessor
