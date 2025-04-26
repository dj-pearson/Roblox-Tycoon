--!strict
--[[
    UIRegistry.luau
    
    Central registry for UI components with versioning, dependency tracking,
    and component discovery. Acts as the single source of truth for UI components.
    
    Features:
    - Component registration with versioning
    - Dependency management
    - Component lifecycle tracking
    - Component discovery
    - Error handling and logging
    
    Author: Updated April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module and state variables
local UIRegistry = {}
local components = {}
local dependencies = {}
local versions = {}
local componentStates = {}

-- State constants
local ComponentState = {
    REGISTERED = "registered",
    INITIALIZING = "initializing",
    INITIALIZED = "initialized",
    ERROR = "error"
}

-- Version parsing utility
local function parseVersion(versionString)
    if not versionString then
        return { major = 0, minor = 0, patch = 0 }
    end
    
    local major, minor, patch = string.match(versionString, "(%d+)%.(%d+)%.(%d+)")
    
    if not major then
        major, minor = string.match(versionString, "(%d+)%.(%d+)")
        patch = 0
    end
    
    if not major then
        major = string.match(versionString, "(%d+)")
        minor, patch = 0, 0
    end
    
    if not major then
        return { major = 0, minor = 0, patch = 0 }
    end
    
    return {
        major = tonumber(major) or 0,
        minor = tonumber(minor) or 0,
        patch = tonumber(patch) or 0
    }
end

-- Version comparison utility
local function isVersionSatisfied(available, required)
    local availableVersion = parseVersion(available)
    local requiredVersion = parseVersion(required)
    
    -- Check major version first (breaking changes)
    if availableVersion.major ~= requiredVersion.major then
        return availableVersion.major > requiredVersion.major
    end
    
    -- Same major version, check minor version (non-breaking additions)
    if availableVersion.minor ~= requiredVersion.minor then
        return availableVersion.minor > requiredVersion.minor
    end
    
    -- Same minor version, check patch version (bug fixes)
    return availableVersion.patch >= requiredVersion.patch
end

-- Debug logging utility
local function debugLog(message, level)
    level = level or "Info"
    local prefix = "[UIRegistry] "
    
    if level == "Info" then
        print(prefix .. message)
    elseif level == "Warning" then
        warn(prefix .. message)
    elseif level == "Error" then
        error(prefix .. message)
    end
end

--[[ Public API Functions ]]--

-- Register a component with optional version
function UIRegistry:registerComponent(name, component, version)
    if not name or type(name) ~= "string" then
        debugLog("Invalid component name", "Warning")
        return false
    end
    
    if not component then
        debugLog("Cannot register nil component: " .. name, "Warning")
        return false
    end
    
    -- Store the component
    components[name] = component
    componentStates[name] = ComponentState.REGISTERED
    
    -- Store version if provided
    if version then
        versions[name] = version
        debugLog("Registered component " .. name .. " v" .. version)
    else
        versions[name] = "1.0.0" -- Default version
        debugLog("Registered component " .. name .. " (unversioned)")
    end
    
    -- Check if any registered dependencies are satisfied by this component
    for dependentName, deps in pairs(dependencies) do
        for depName, requiredVersion in pairs(deps) do
            if depName == name then
                local available = versions[name]
                if isVersionSatisfied(available, requiredVersion) then
                    debugLog("Dependency satisfied: " .. dependentName .. " requires " .. name .. " v" .. requiredVersion .. ", got v" .. available)
                else
                    debugLog("Dependency version mismatch: " .. dependentName .. " requires " .. name .. " v" .. requiredVersion .. ", but got v" .. available, "Warning")
                end
            end
        end
    end
    
    return true
end

-- Register a dependency
function UIRegistry:registerDependency(componentName, dependencyName, requiredVersion)
    if not componentName or not dependencyName then
        debugLog("Invalid dependency registration parameters", "Warning")
        return false
    end
    
    -- Initialize dependency table if needed
    dependencies[componentName] = dependencies[componentName] or {}
    
    -- Store the dependency with version requirement
    dependencies[componentName][dependencyName] = requiredVersion or "1.0.0"
    
    -- Check if dependency is already registered
    if components[dependencyName] then
        local available = versions[dependencyName]
        local required = requiredVersion or "1.0.0"
        
        if isVersionSatisfied(available, required) then
            debugLog("Dependency already satisfied: " .. componentName .. " requires " .. dependencyName .. " v" .. required .. ", got v" .. available)
        else
            debugLog("Dependency version mismatch: " .. componentName .. " requires " .. dependencyName .. " v" .. required .. ", but got v" .. available, "Warning")
        end
    else
        debugLog("Dependency not yet registered: " .. componentName .. " requires " .. dependencyName)
    end
    
    return true
end

-- Get a component by name
function UIRegistry:getComponent(name)
    return components[name]
end

-- Check if a component is registered
function UIRegistry:hasComponent(name)
    return components[name] ~= nil
end

-- Get a component version
function UIRegistry:getComponentVersion(name)
    return versions[name]
end

-- Get all registered component names
function UIRegistry:getAllComponentNames()
    local names = {}
    for name in pairs(components) do
        table.insert(names, name)
    end
    return names
end

-- Get all component dependencies
function UIRegistry:getDependencies(componentName)
    return dependencies[componentName] or {}
end

-- Check if all dependencies are satisfied
function UIRegistry:areDependenciesSatisfied(componentName)
    local deps = dependencies[componentName]
    if not deps then
        return true  -- No dependencies
    end
    
    for depName, requiredVersion in pairs(deps) do
        local component = components[depName]
        if not component then
            return false  -- Dependency not registered
        end
        
        local availableVersion = versions[depName]
        if not isVersionSatisfied(availableVersion, requiredVersion) then
            return false  -- Version requirement not met
        end
    end
    
    return true
end

-- Update component state
function UIRegistry:updateComponentState(name, state)
    if not components[name] then
        debugLog("Cannot update state for non-existent component: " .. name, "Warning")
        return false
    end
    
    if not ComponentState[state] then
        debugLog("Invalid component state: " .. state, "Warning")
        return false
    end
    
    componentStates[name] = state
    return true
end

-- Get component state
function UIRegistry:getComponentState(name)
    return componentStates[name]
end

-- Mark component as initialized
function UIRegistry:setInitialized(name, success)
    if not components[name] then
        debugLog("Cannot mark non-existent component as initialized: " .. name, "Warning")
        return false
    end
    
    if success == false then
        componentStates[name] = ComponentState.ERROR
        debugLog("Component initialization failed: " .. name, "Warning")
    else
        componentStates[name] = ComponentState.INITIALIZED
        debugLog("Component initialized: " .. name)
    end
    
    return true
end

-- Unregister a component
function UIRegistry:unregisterComponent(name)
    if not components[name] then
        debugLog("Cannot unregister non-existent component: " .. name, "Warning")
        return false
    end
    
    -- Remove component
    components[name] = nil
    versions[name] = nil
    componentStates[name] = nil
    
    -- Check for any dependencies that will be broken
    for depName, deps in pairs(dependencies) do
        if deps[name] then
            debugLog("Breaking dependency: " .. depName .. " depends on " .. name, "Warning")
        end
    end
    
    -- Remove component's dependencies
    dependencies[name] = nil
    
    debugLog("Unregistered component: " .. name)
    return true
end

-- Find components by pattern matching
function UIRegistry:findComponents(pattern)
    local matches = {}
    for name, component in pairs(components) do
        if string.match(name, pattern) then
            matches[name] = component
        end
    end
    return matches
end

-- Check for version conflicts
function UIRegistry:checkVersionConflicts()
    local conflicts = {}
    
    for componentName, deps in pairs(dependencies) do
        for depName, requiredVersion in pairs(deps) do
            if components[depName] then
                local availableVersion = versions[depName]
                if not isVersionSatisfied(availableVersion, requiredVersion) then
                    conflicts[componentName] = conflicts[componentName] or {}
                    conflicts[componentName][depName] = {
                        required = requiredVersion,
                        available = availableVersion
                    }
                end
            else
                conflicts[componentName] = conflicts[componentName] or {}
                conflicts[componentName][depName] = {
                    required = requiredVersion,
                    available = nil
                }
            end
        end
    end
    
    return conflicts
end

-- Initialize all registered components
function UIRegistry:initializeAllComponents()
    local initialized = {}
    local failed = {}
    
    for name, component in pairs(components) do
        if componentStates[name] ~= ComponentState.INITIALIZED and type(component.initialize) == "function" then
            componentStates[name] = ComponentState.INITIALIZING
            
            -- Check dependencies
            if not self:areDependenciesSatisfied(name) then
                debugLog("Cannot initialize " .. name .. " due to unsatisfied dependencies", "Warning")
                componentStates[name] = ComponentState.ERROR
                table.insert(failed, name)
                continue
            end
            
            -- Try to initialize
            local success, result = pcall(function()
                return component:initialize()
            end)
            
            if success then
                componentStates[name] = ComponentState.INITIALIZED
                table.insert(initialized, name)
                debugLog("Successfully initialized: " .. name)
            else
                componentStates[name] = ComponentState.ERROR
                table.insert(failed, name)
                debugLog("Failed to initialize: " .. name .. " - " .. tostring(result), "Warning")
            end
        end
    end
    
    return initialized, failed
end

-- Find UI modules in the workspace
function UIRegistry:discoverUIModules()
    local discovered = {}
    
    -- Define paths to search
    local paths = {
        ReplicatedStorage:FindFirstChild("src"),
        game:GetService("StarterGui")
    }
    
    -- Helper function to search for UI modules
    local function searchForUIModules(parent, prefix)
        prefix = prefix or ""
        
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ModuleScript") and 
               (string.match(child.Name, "UI") or 
                string.match(child.Name, "Gui")) then
                
                local path = prefix .. child.Name
                table.insert(discovered, {
                    name = child.Name,
                    path = path,
                    module = child
                })
            elseif child:IsA("Folder") or child:IsA("Configuration") then
                searchForUIModules(child, prefix .. child.Name .. ".")
            end
        end
    end
    
    -- Search in all defined paths
    for _, path in ipairs(paths) do
        if path then
            searchForUIModules(path)
        end
    end
    
    return discovered
end

-- Auto-register discovered UI modules
function UIRegistry:autoRegisterUIModules()
    local discovered = self:discoverUIModules()
    local registered = {}
    
    for _, info in ipairs(discovered) do
        local module = requireSafely(info.module)
        if module then
            local success = self:registerComponent(info.name:gsub("%.client", ""), module)
            if success then
                table.insert(registered, info.name)
            end
        end
    end
    
    return registered
end

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        debugLog("Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result), "Warning")
        return nil
    end
    
    return result
end

-- Return the module
return UIRegistry
