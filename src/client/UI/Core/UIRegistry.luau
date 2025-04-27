--!strict
--[[
    UIRegistry.luau
    
    Central registry for UI components with versioning and dependency tracking.
    Provides a way to register, discover, and manage UI components throughout
    the application lifecycle.
    
    Features:
    - Component registration and retrieval
    - Version tracking and conflict detection
    - Dependency management
    - Automatic component discovery
    - Component initialization orchestration
    
    Author: Updated April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module and state variables
local UIRegistry = {}
local components = {}
local componentStates = {}
local componentVersions = {}
local dependencies = {}

-- Constants
local VERSION_PATTERN = "^(%d+)%.(%d+)%.(%d+)$" -- Semantic versioning pattern (e.g., "1.0.0")

--[[ Utility Functions ]]--

-- Parse a semantic version string into a table of numbers
local function parseVersion(versionStr)
    if not versionStr then return nil end
    
    local major, minor, patch = string.match(versionStr, VERSION_PATTERN)
    if not major then
        warn("Invalid version format: " .. tostring(versionStr) .. ". Expected format: x.y.z")
        return nil
    end
    
    return {
        major = tonumber(major),
        minor = tonumber(minor),
        patch = tonumber(patch)
    }
end

-- Compare two version tables
local function compareVersions(v1, v2)
    if not v1 or not v2 then return false end
    
    if v1.major > v2.major then
        return 1
    elseif v1.major < v2.major then
        return -1
    else
        if v1.minor > v2.minor then
            return 1
        elseif v1.minor < v2.minor then
            return -1
        else
            if v1.patch > v2.patch then
                return 1
            elseif v1.patch < v2.patch then
                return -1
            else
                return 0 -- Versions are equal
            end
        end
    end
end

-- Check if a component can be initialized based on its dependencies
local function canInitializeComponent(name)
    if not dependencies[name] then
        return true -- No dependencies
    end
    
    for depName, depVersion in pairs(dependencies[name]) do
        local depComponent = components[depName]
        
        -- Dependency doesn't exist
        if not depComponent then
            return false
        end
        
        -- Check if dependency is initialized
        if componentStates[depName] ~= "initialized" then
            return false
        end
        
        -- Check version compatibility
        local requiredVersion = parseVersion(depVersion)
        local actualVersion = parseVersion(componentVersions[depName])
        
        if not requiredVersion or not actualVersion then
            return false
        end
        
        -- Major version must match, minor and patch must be >= required
        if actualVersion.major ~= requiredVersion.major or
           compareVersions(actualVersion, requiredVersion) < 0 then
            return false
        end
    end
    
    return true
end

-- Safely initialize a component
local function safeInitialize(component)
    if not component or type(component) ~= "table" or not component.initialize then
        return false
    end
    
    local success, result = pcall(function()
        return component:initialize()
    end)
    
    return success and result
end

--[[ Public API Functions ]]--

-- Register a component
function UIRegistry:registerComponent(name, component, version)
    if not name or not component then
        warn("Cannot register component without name or implementation")
        return false
    end
    
    -- Check if component already exists with a different version
    if components[name] and componentVersions[name] and componentVersions[name] ~= version then
        warn("Component " .. name .. " already registered with version " .. componentVersions[name])
        return false
    end
    
    -- Register the component
    components[name] = component
    componentStates[name] = "registered"
    
    -- Set version if provided
    if version then
        -- Validate version format
        if not parseVersion(version) then
            warn("Invalid version format for component " .. name .. ": " .. tostring(version))
            return false
        end
        
        componentVersions[name] = version
    end
    
    return true
end

-- Get a component by name
function UIRegistry:getComponent(name)
    return components[name]
end

-- Get all registered component names
function UIRegistry:getAllComponentNames()
    local names = {}
    
    for name, _ in pairs(components) do
        table.insert(names, name)
    end
    
    return names
end

-- Get component state
function UIRegistry:getComponentState(name)
    return componentStates[name] or "unknown"
end

-- Get component version
function UIRegistry:getComponentVersion(name)
    return componentVersions[name]
end

-- Register dependency
function UIRegistry:registerDependency(componentName, dependencyName, minVersion)
    if not componentName or not dependencyName then
        warn("Cannot register dependency without component name or dependency name")
        return false
    end
    
    -- Ensure component is registered
    if not components[componentName] then
        warn("Cannot register dependency for unregistered component: " .. componentName)
        return false
    end
    
    -- Initialize dependencies table for this component if needed
    if not dependencies[componentName] then
        dependencies[componentName] = {}
    end
    
    -- Register the dependency with version if provided
    dependencies[componentName][dependencyName] = minVersion
    
    return true
end

-- Get dependencies for a component
function UIRegistry:getDependencies(componentName)
    return dependencies[componentName] or {}
end

-- Check if a component has a specific dependency
function UIRegistry:hasDependency(componentName, dependencyName)
    return dependencies[componentName] and dependencies[componentName][dependencyName] ~= nil
end

-- Initialize a component by name
function UIRegistry:initializeComponent(name)
    local component = components[name]
    
    if not component then
        warn("Cannot initialize unknown component: " .. name)
        return false
    end
    
    -- Check if already initialized
    if componentStates[name] == "initialized" then
        return true
    end
    
    -- Check if dependencies are satisfied
    if not canInitializeComponent(name) then
        warn("Cannot initialize component " .. name .. " due to unsatisfied dependencies")
        componentStates[name] = "dependency_failed"
        return false
    end
    
    -- Try to initialize the component
    componentStates[name] = "initializing"
    
    local success = safeInitialize(component)
    
    if success then
        componentStates[name] = "initialized"
    else
        componentStates[name] = "init_failed"
        warn("Failed to initialize component: " .. name)
    end
    
    return success
end

-- Initialize all components in dependency order
function UIRegistry:initializeAllComponents()
    local initialized = {}
    local failed = {}
    
    -- First pass: initialize components without dependencies
    for name, component in pairs(components) do
        if not dependencies[name] or next(dependencies[name]) == nil then
            if self:initializeComponent(name) then
                table.insert(initialized, name)
            else
                table.insert(failed, name)
            end
        end
    end
    
    -- Repeatedly try to initialize remaining components
    local progress = true
    local maxAttempts = 5
    local attempt = 0
    
    while progress and attempt < maxAttempts do
        progress = false
        attempt = attempt + 1
        
        for name, component in pairs(components) do
            if componentStates[name] ~= "initialized" and componentStates[name] ~= "init_failed" then
                if canInitializeComponent(name) then
                    if self:initializeComponent(name) then
                        table.insert(initialized, name)
                        progress = true
                    else
                        table.insert(failed, name)
                    end
                end
            end
        end
    end
    
    -- If there are still uninitialized components, mark them as failed
    for name, state in pairs(componentStates) do
        if state ~= "initialized" and state ~= "init_failed" and not table.find(failed, name) then
            table.insert(failed, name)
        end
    end
    
    return initialized, failed
end

-- Check for version conflicts
function UIRegistry:checkVersionConflicts()
    local conflicts = {}
    
    -- Check for direct version conflicts between components and their dependencies
    for componentName, componentDeps in pairs(dependencies) do
        for depName, requiredVersion in pairs(componentDeps) do
            local actualVersion = componentVersions[depName]
            
            if actualVersion then
                local reqVersion = parseVersion(requiredVersion)
                local actVersion = parseVersion(actualVersion)
                
                if reqVersion and actVersion then
                    -- Major version must match, minor and patch must be >= required
                    if actVersion.major ~= reqVersion.major or
                       compareVersions(actVersion, reqVersion) < 0 then
                        table.insert(conflicts, {
                            component = componentName,
                            dependency = depName,
                            required = requiredVersion,
                            actual = actualVersion
                        })
                    end
                end
            end
        end
    end
    
    return conflicts
end

-- Discover UI modules in the workspace
function UIRegistry:discoverUIModules()
    local discovered = {}
    local srcFolder = ReplicatedStorage:FindFirstChild("src")
    
    if not srcFolder then
        warn("Source folder not found for UI component discovery")
        return discovered
    end
    
    local clientFolder = srcFolder:FindFirstChild("client")
    if not clientFolder then
        warn("Client folder not found for UI component discovery")
        return discovered
    end
    
    local uiFolder = clientFolder:FindFirstChild("UI")
    if not uiFolder then
        warn("UI folder not found for component discovery")
        return discovered
    end
    
    -- Helper function to search for modules
    local function searchForModules(folder)
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("ModuleScript") then
                -- Attempt to require the module
                local success, result = pcall(function()
                    return require(child)
                end)
                
                if success and type(result) == "table" then
                    -- Check if it has the expected UI component interface
                    if result.initialize and (result.show or result.hide) then
                        local name = child.Name:gsub("%.luau$", ""):gsub("%.lua$", "")
                        
                        -- Register the component
                        if self:registerComponent(name, result) then
                            table.insert(discovered, name)
                        end
                    end
                end
            elseif child:IsA("Folder") then
                -- Recursively search subfolders
                searchForModules(child)
            end
        end
    end
    
    -- Start the search
    searchForModules(uiFolder)
    
    return discovered
end

-- Reset registry (mainly for testing)
function UIRegistry:reset()
    components = {}
    componentStates = {}
    componentVersions = {}
    dependencies = {}
    
    return true
end

-- Return the module
return UIRegistry
