--!strict
--[[
    ModuleLoader.luau
    
    Standardizes module loading across the UI system.
    Handles different loading methods, paths, and extensions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module paths
local MODULE_PATHS = {
    CORE = "src/client/UI/Core",
    SCREENS = "src/client/UI/Screens",
    COMPONENTS = "src/client/UI/Components"
}

-- Module extensions
local MODULE_EXTENSIONS = {
    ".luau",
    ".client.luau"
}

-- Module cache
local moduleCache = {}

-- ModuleLoader
local ModuleLoader = {}

-- Get module path
function ModuleLoader.getModulePath(moduleName, moduleType)
    local basePath = MODULE_PATHS[moduleType] or MODULE_PATHS.CORE
    return basePath .. "/" .. moduleName
end

-- Try to require a module with different extensions
function ModuleLoader.tryRequireModule(modulePath)
    -- Check cache first
    if moduleCache[modulePath] then
        return moduleCache[modulePath]
    end
    
    -- Try each extension
    for _, extension in ipairs(MODULE_EXTENSIONS) do
        local fullPath = modulePath .. extension
        local success, module = pcall(function()
            return require(script.Parent.Parent.Parent.Parent:FindFirstChild(fullPath, true))
        end)
        
        if success and module then
            moduleCache[modulePath] = module
            return module
        end
    end
    
    return nil
end

-- Load a core module
function ModuleLoader.loadCore(moduleName)
    local modulePath = ModuleLoader.getModulePath(moduleName, "CORE")
    return ModuleLoader.tryRequireModule(modulePath)
end

-- Load a screen module
function ModuleLoader.loadScreen(moduleName)
    local modulePath = ModuleLoader.getModulePath(moduleName, "SCREENS")
    return ModuleLoader.tryRequireModule(modulePath)
end

-- Load a component module
function ModuleLoader.loadComponent(moduleName)
    local modulePath = ModuleLoader.getModulePath(moduleName, "COMPONENTS")
    return ModuleLoader.tryRequireModule(modulePath)
end

-- Load a module with fallback
function ModuleLoader.loadWithFallback(moduleName, moduleType, fallbackModule)
    local module = ModuleLoader.tryRequireModule(ModuleLoader.getModulePath(moduleName, moduleType))
    return module or fallbackModule
end

-- Clear module cache
function ModuleLoader.clearCache()
    moduleCache = {}
end

-- Get all available modules of a type
function ModuleLoader.getAvailableModules(moduleType)
    local modules = {}
    local basePath = MODULE_PATHS[moduleType]
    
    if not basePath then
        return modules
    end
    
    -- Search through the directory
    local directory = script.Parent.Parent.Parent.Parent:FindFirstChild(basePath, true)
    if directory then
        for _, child in ipairs(directory:GetChildren()) do
            if child:IsA("ModuleScript") then
                local moduleName = child.Name:gsub("%.luau$", ""):gsub("%.client%.luau$", "")
                table.insert(modules, moduleName)
            end
        end
    end
    
    return modules
end

-- Register a module in the cache
function ModuleLoader.registerModule(moduleName, moduleType, module)
    local modulePath = ModuleLoader.getModulePath(moduleName, moduleType)
    moduleCache[modulePath] = module
end

return ModuleLoader 