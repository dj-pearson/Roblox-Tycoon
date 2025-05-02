--[[
    ModuleLoader.luau
    A utility module for loading and managing module dependencies with advanced features.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ModuleLoader = {}

-- Cache for loaded modules
local loadedModules = {}

-- Track module dependencies to detect circular references
local loadingStack = {}

-- Standard search paths for modules
local standardPaths = {
    ReplicatedStorage,
    ReplicatedStorage:FindFirstChild("shared"),
    ServerScriptService,
    ServerScriptService:FindFirstChild("Server"),
    ServerScriptService:FindFirstChild("Server") and ServerScriptService:FindFirstChild("Server"):FindFirstChild("Core"),
    ServerStorage,
    game:GetService("Players"),
}

-- Function to detect circular dependencies
local function checkCircularDependency(moduleName)
    for _, name in ipairs(loadingStack) do
        if name == moduleName then
            local dependencyChain = table.concat(loadingStack, " -> ") .. " -> " .. moduleName
            warn("[ModuleLoader] Circular dependency detected: " .. dependencyChain)
            return true
        end
    end
    return false
end

-- Function to find a module in standard paths
function ModuleLoader.findModule(moduleName)
    -- Check if we're looking for a path (contains slash or dot)
    if string.find(moduleName, "[/.]") then
        -- Split the path
        local parts = {}
        for part in string.gmatch(moduleName, "[^/.]+") do
            table.insert(parts, part)
        end
        
        -- Navigate through the path
        for _, root in ipairs(standardPaths) do
            if root then
                local current = root
                local found = true
                
                for i = 1, #parts - 1 do
                    current = current:FindFirstChild(parts[i])
                    if not current then
                        found = false
                        break
                    end
                end
                
                if found and current:FindFirstChild(parts[#parts]) and current:FindFirstChild(parts[#parts]):IsA("ModuleScript") then
                    return current:FindFirstChild(parts[#parts])
                end
            end
        end
    else
        -- Direct lookup in standard paths
        for _, path in ipairs(standardPaths) do
            if path then
                local module = path:FindFirstChild(moduleName)
                if module and module:IsA("ModuleScript") then
                    return module
                end
            end
        end
    end
    
    return nil
end

-- Load a module with dependency tracking
function ModuleLoader.loadModule(moduleName, ignoreCache)
    -- Return cached module if available and cache isn't ignored
    if loadedModules[moduleName] and not ignoreCache then
        return loadedModules[moduleName]
    end
    
    -- Check for circular dependencies
    if checkCircularDependency(moduleName) then
        return nil
    end
    
    -- Add to loading stack to track dependencies
    table.insert(loadingStack, moduleName)
    
    -- Find the module
    local moduleScript = ModuleLoader.findModule(moduleName)
    if not moduleScript then
        table.remove(loadingStack)
        warn("[ModuleLoader] Could not find module: " .. moduleName)
        return nil
    end
    
    -- Load the module
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    -- Remove from loading stack
    table.remove(loadingStack)
    
    if success then
        loadedModules[moduleName] = result
        return result
    else
        warn("[ModuleLoader] Error loading module " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

-- Register additional search paths
function ModuleLoader.registerPath(path)
    if typeof(path) == "Instance" then
        table.insert(standardPaths, path)
        return true
    else
        warn("[ModuleLoader] Invalid path registration: Expected Instance, got " .. typeof(path))
        return false
    end
end

-- Clear the module cache
function ModuleLoader.clearCache()
    loadedModules = {}
end

-- Get a table of all cached modules
function ModuleLoader.getCachedModules()
    local result = {}
    for name, _ in pairs(loadedModules) do
        table.insert(result, name)
    end
    return result
end

return ModuleLoader
