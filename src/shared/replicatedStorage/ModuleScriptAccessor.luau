--[[
    ModuleScriptAccessor.luau
    
    A utility module for managing script access across the game.
    This provides a centralized way to access modules from different parts of the game.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local ModuleScriptAccessor = {}

-- Debug settings
ModuleScriptAccessor.DEBUG = true

-- Log a message to the output
local function log(message)
    if ModuleScriptAccessor.DEBUG then
        print("[ModuleScriptAccessor] " .. message)
    end
end

-- Get all standard search paths for a module
function ModuleScriptAccessor.getSearchPaths()
    local paths = {
        -- ReplicatedStorage paths (accessible from both client and server)
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("ClientModules"),
    }
    
    -- Add server-only paths if we're on the server
    if RunService:IsServer() then
        table.insert(paths, ServerScriptService:FindFirstChild("src"))
        table.insert(paths, ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server"))
        table.insert(paths, ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"))
        table.insert(paths, ServerScriptService:FindFirstChild("Core"))
        table.insert(paths, ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("Core"))
        table.insert(paths, ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("Systems"))
        table.insert(paths, ServerScriptService:FindFirstChild("Systems"))
        table.insert(paths, ServerScriptService:FindFirstChild("GymAutomation"))
        
        table.insert(paths, ServerStorage:FindFirstChild("src"))
        table.insert(paths, ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server"))
        table.insert(paths, ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server") and ServerStorage.src.server:FindFirstChild("Core"))
        table.insert(paths, ServerStorage:FindFirstChild("Core"))
        table.insert(paths, ServerStorage:FindFirstChild("Systems"))
        table.insert(paths, ServerStorage:FindFirstChild("GymAutomation"))
    end
    
    return paths
end

-- Try to find a module in all search paths
function ModuleScriptAccessor.findModule(moduleName)
    local searchPaths = ModuleScriptAccessor.getSearchPaths()
    
    for _, path in ipairs(searchPaths) do
        if path then
            -- Direct match
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                log("Found module " .. moduleName .. " at: " .. module:GetFullName())
                return module
            end
            
            -- With .luau extension
            module = path:FindFirstChild(moduleName .. ".luau")
            if module and module:IsA("ModuleScript") then
                log("Found module " .. moduleName .. ".luau at: " .. module:GetFullName())
                return module
            end
            
            -- With .server.luau extension
            if RunService:IsServer() then
                module = path:FindFirstChild(moduleName .. ".server.luau")
                if module and module:IsA("ModuleScript") then
                    log("Found module " .. moduleName .. ".server.luau at: " .. module:GetFullName())
                    return module
                end
            end
            
            -- With .client.luau extension
            module = path:FindFirstChild(moduleName .. ".client.luau")
            if module and module:IsA("ModuleScript") then
                log("Found module " .. moduleName .. ".client.luau at: " .. module:GetFullName())
                return module
            end
        end
    end
    
    log("Could not find module: " .. moduleName)
    return nil
end

-- Require a module by name, searching in standard locations
function ModuleScriptAccessor.requireModule(moduleName)
    local moduleScript = ModuleScriptAccessor.findModule(moduleName)
    
    if moduleScript then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            return result
        else
            warn("[ModuleScriptAccessor] Failed to require " .. moduleName .. ": " .. tostring(result))
        end
    end
    
    return nil
end

-- Get the CoreRegistry if available
function ModuleScriptAccessor.getCoreRegistry()
    -- Check if we're on the server
    if RunService:IsServer() then
        -- Try direct require
        local coreRegistry = ModuleScriptAccessor.requireModule("CoreRegistry")
        if coreRegistry then
            return coreRegistry
        end
    else
        -- On the client, use CoreRegistryShared
        local coreRegistryShared = ModuleScriptAccessor.requireModule("CoreRegistryShared")
        if coreRegistryShared then
            return coreRegistryShared
        end
    end
    
    -- Try to find in shared folder
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("CoreRegistry") then
        local success, result = pcall(function()
            return require(shared.CoreRegistry)
        end)
        
        if success then
            return result
        end
    end
    
    log("CoreRegistry not found")
    return nil
end

-- Get a reference to a system through CoreRegistry
function ModuleScriptAccessor.getSystem(systemName)
    local coreRegistry = ModuleScriptAccessor.getCoreRegistry()
    
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        return coreRegistry.getSystem(systemName)
    end
    
    -- Fallback: try to find it directly
    return ModuleScriptAccessor.requireModule(systemName)
end

-- Register a system with CoreRegistry
function ModuleScriptAccessor.registerSystem(systemName, systemModule)
    local coreRegistry = ModuleScriptAccessor.getCoreRegistry()
    
    if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
        local success, result = pcall(function()
            return coreRegistry.registerSystem(systemName, systemModule)
        end)
        
        if success then
            log("Successfully registered system: " .. systemName)
            return true
        else
            warn("[ModuleScriptAccessor] Failed to register system " .. systemName .. ": " .. tostring(result))
        end
    else
        warn("[ModuleScriptAccessor] CoreRegistry not found or missing registerSystem method")
    end
    
    return false
end

return ModuleScriptAccessor
