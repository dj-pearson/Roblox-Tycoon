--!strict
--[[
    UIRegistry.luau
    
    Handles registration and management of UI components.
    Provides a central registry for all UI-related modules.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the module loader
local ModuleLoader = require(script.Parent.ModuleLoader)

-- UIRegistry
local UIRegistry = {}
UIRegistry.__index = UIRegistry

-- Constructor
function UIRegistry.new()
    local self = setmetatable({}, UIRegistry)
    self.components = {}
    self.versions = {}
    self.dependencies = {}
    self.states = {}
    self.initialized = false
    return self
end

-- Initialize registry
function UIRegistry:initialize()
    if self.initialized then return end
    
    -- Load all available components
    self:discoverComponents()
    
    self.initialized = true
end

-- Discover components
function UIRegistry:discoverComponents()
    -- Discover core components
    local coreModules = ModuleLoader.getAvailableModules("CORE")
    for _, moduleName in ipairs(coreModules) do
        self:registerComponent(moduleName, "CORE")
    end
    
    -- Discover screen components
    local screenModules = ModuleLoader.getAvailableModules("SCREENS")
    for _, moduleName in ipairs(screenModules) do
        self:registerComponent(moduleName, "SCREENS")
    end
    
    -- Discover UI components
    local componentModules = ModuleLoader.getAvailableModules("COMPONENTS")
    for _, moduleName in ipairs(componentModules) do
        self:registerComponent(moduleName, "COMPONENTS")
    end
end

-- Register a component
function UIRegistry:registerComponent(componentName, componentType, version, dependencies)
    -- Load the component
    local component
    if componentType == "CORE" then
        component = ModuleLoader.loadCore(componentName)
    elseif componentType == "SCREENS" then
        component = ModuleLoader.loadScreen(componentName)
    elseif componentType == "COMPONENTS" then
        component = ModuleLoader.loadComponent(componentName)
    end
    
    if not component then
        warn("Failed to load component:", componentName)
        return false
    end
    
    -- Register the component
    self.components[componentName] = component
    self.versions[componentName] = version or "1.0.0"
    self.dependencies[componentName] = dependencies or {}
    self.states[componentName] = "registered"
    
    -- Register in module cache
    ModuleLoader.registerModule(componentName, componentType, component)
    
    return true
end

-- Get a component
function UIRegistry:getComponent(componentName)
    return self.components[componentName]
end

-- Get component version
function UIRegistry:getComponentVersion(componentName)
    return self.versions[componentName]
end

-- Get component dependencies
function UIRegistry:getComponentDependencies(componentName)
    return self.dependencies[componentName]
end

-- Check for version conflicts
function UIRegistry:checkVersionConflicts()
    local conflicts = {}
    
    for componentName, dependencies in pairs(self.dependencies) do
        for depName, requiredVersion in pairs(dependencies) do
            local actualVersion = self.versions[depName]
            if actualVersion and actualVersion ~= requiredVersion then
                table.insert(conflicts, {
                    component = componentName,
                    dependency = depName,
                    required = requiredVersion,
                    actual = actualVersion
                })
            end
        end
    end
    
    return conflicts
end

-- Set component state
function UIRegistry:setComponentState(componentName, state)
    self.states[componentName] = state
end

-- Get component state
function UIRegistry:getComponentState(componentName)
    return self.states[componentName]
end

-- Get all registered component names
function UIRegistry:getRegisteredComponents()
    local names = {}
    for name in pairs(self.components) do
        table.insert(names, name)
    end
    return names
end

-- Clean up
function UIRegistry:cleanup()
    -- Clear module cache
    ModuleLoader.clearCache()
    
    -- Reset registry
    self.components = {}
    self.versions = {}
    self.dependencies = {}
    self.states = {}
    self.initialized = false
end

return UIRegistry
