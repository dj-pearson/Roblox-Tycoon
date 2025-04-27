--!strict
--[[
    RegistryBase.luau
    
    Base class for the registry system that provides common registry functionality
    including component registration, retrieval, version tracking, and dependency
    management. This serves as the foundation for specialized registry implementations.
    
    Features:
    - Component registration with versioning
    - Component retrieval with type checking
    - Dependency tracking and resolution
    - Component lifecycle management
    - Error handling and reporting
    
    Author: Created April 27, 2025
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

export type RegistryOptions = {
    name: string?,
    strict: boolean?,
    autoInit: boolean?,
    allowOverrides: boolean?,
    allowDynamicRegistration: boolean?,
    debugMode: boolean?,
    logLevel: number?
}

export type ComponentInfo = {
    id: string,
    module: any, -- The actual module
    version: string,
    dependencies: {[string]: string}?,
    state: "registered" | "initializing" | "ready" | "error",
    initialized: boolean,
    api: any?, -- Public API exposed by the component
    tags: {[string]: boolean}?,
    metadata: {[string]: any}?,
    registrationTime: number,
    errorInfo: {message: string, trace: string}?
}

export type Registry = {
    name: string,
    components: {[string]: ComponentInfo},
    options: RegistryOptions,
    
    -- Core methods
    register: (self: Registry, id: string, module: any, version: string?) -> boolean,
    registerWithDependencies: (self: Registry, id: string, module: any, version: string?, dependencies: {[string]: string}?) -> boolean,
    get: (self: Registry, id: string, minVersion: string?) -> any,
    getApi: (self: Registry, id: string, minVersion: string?) -> any,
    getInfo: (self: Registry, id: string) -> ComponentInfo?,
    has: (self: Registry, id: string, minVersion: string?) -> boolean,
    remove: (self: Registry, id: string) -> boolean,
    
    -- Lifecycle methods
    initialize: (self: Registry, componentId: string?) -> boolean,
    initializeAll: (self: Registry) -> {failures: {[string]: string}},
    shutdown: (self: Registry, componentId: string?) -> boolean,
    shutdownAll: (self: Registry) -> {failures: {[string]: string}},
    
    -- Registry management
    listComponents: (self: Registry, filter: {tags: {string}?, state: string?}?) -> {ComponentInfo},
    findComponentsByTag: (self: Registry, tag: string) -> {ComponentInfo},
    setTag: (self: Registry, componentId: string, tag: string, value: boolean) -> boolean,
    setMetadata: (self: Registry, componentId: string, key: string, value: any) -> boolean,
    
    -- Configuration and utilities
    setOptions: (self: Registry, options: RegistryOptions) -> nil,
    getOptions: (self: Registry) -> RegistryOptions,
    getDependents: (self: Registry, componentId: string) -> {string},
    getErrors: (self: Registry) -> {[string]: {message: string, trace: string}}
}

-- Module implementation
local RegistryBase = {}
RegistryBase.__index = RegistryBase

--[[ Private Utility Functions ]]--

-- Log messages based on log level
local function log(registry, level, message, ...)
    if registry.options.logLevel and registry.options.logLevel >= level then
        local prefix = "[Registry:" .. registry.name .. "]"
        
        if level == 1 then
            warn(prefix .. " ERROR: " .. message, ...)
        elseif level == 2 then
            warn(prefix .. " WARNING: " .. message, ...)
        elseif level == 3 then
            print(prefix .. " INFO: " .. message, ...)
        elseif level == 4 then
            print(prefix .. " DEBUG: " .. message, ...)
        end
    end
end

-- Compare versions
local function compareVersions(version1, version2)
    -- Parse versions into numeric components
    local function parseVersion(version)
        local major, minor, patch = string.match(version, "(%d+)%.(%d+)%.(%d+)")
        return major and {tonumber(major), tonumber(minor), tonumber(patch)} or {0, 0, 0}
    end

    local v1 = parseVersion(version1)
    local v2 = parseVersion(version2)
    
    -- Compare major version
    if v1[1] > v2[1] then
        return 1
    elseif v1[1] < v2[1] then
        return -1
    end
    
    -- Compare minor version
    if v1[2] > v2[2] then
        return 1
    elseif v1[2] < v2[2] then
        return -1
    end
    
    -- Compare patch version
    if v1[3] > v2[3] then
        return 1
    elseif v1[3] < v2[3] then
        return -1
    end
    
    -- Versions are equal
    return 0
end

-- Check if a version meets minimum version requirement
local function meetsVersionRequirement(version, minVersion)
    return compareVersions(version, minVersion) >= 0
end

-- Get module API safely
local function getModuleApi(componentInfo)
    if not componentInfo or not componentInfo.module then
        return nil
    end
    
    -- If component already has an API set, return it
    if componentInfo.api then
        return componentInfo.api
    end
    
    -- If module is a table with an API field, return that
    if type(componentInfo.module) == "table" and componentInfo.module.API then
        return componentInfo.module.API
    end
    
    -- If module is a table and doesn't have a __call metamethod, assume it's the API
    if type(componentInfo.module) == "table" and not getmetatable(componentInfo.module).__call then
        return componentInfo.module
    end
    
    -- Otherwise, return the module itself
    return componentInfo.module
end

-- Utility function to resolve dependencies
local function resolveDependencies(registry, componentId, visited)
    visited = visited or {}
    
    -- Check for circular dependencies
    if visited[componentId] then
        return false, "Circular dependency detected for: " .. componentId
    end
    
    -- Mark this component as visited
    visited[componentId] = true
    
    -- Get component info
    local componentInfo = registry.components[componentId]
    if not componentInfo then
        return false, "Component not found: " .. componentId
    end
    
    -- Check each dependency
    if componentInfo.dependencies then
        for depId, minVersion in pairs(componentInfo.dependencies) do
            -- Check if dependency exists
            if not registry.components[depId] then
                return false, "Missing dependency: " .. depId .. " for component: " .. componentId
            end
            
            -- Check if dependency version is sufficient
            local depInfo = registry.components[depId]
            if not meetsVersionRequirement(depInfo.version, minVersion) then
                return false, "Dependency version mismatch: " .. depId .. " requires " .. minVersion .. " but found " .. depInfo.version
            end
            
            -- Recursively resolve this dependency's dependencies
            local success, error = resolveDependencies(registry, depId, visited)
            if not success then
                return false, error
            end
            
            -- If dependency is not initialized but should be, try to initialize it
            if registry.options.autoInit and not depInfo.initialized and depInfo.state ~= "initializing" then
                local initSuccess = registry:initialize(depId)
                if not initSuccess then
                    return false, "Failed to initialize dependency: " .. depId
                end
            end
        end
    end
    
    -- All dependencies resolved
    return true, nil
end

-- Get all components that depend on a given component
local function findDependents(registry, componentId)
    local dependents = {}
    
    for id, info in pairs(registry.components) do
        if info.dependencies and info.dependencies[componentId] then
            table.insert(dependents, id)
        end
    end
    
    return dependents
end

-- Create a new registry instance
function RegistryBase.new(name, options)
    local self = setmetatable({}, RegistryBase)
    
    self.name = name or "Registry"
    self.components = {}
    self.options = {
        strict = true,             -- Strict mode enforces version requirements
        autoInit = true,           -- Auto-initialize dependencies
        allowOverrides = false,    -- Allow components to be overridden
        allowDynamicRegistration = true, -- Allow components to be registered at runtime
        debugMode = false,         -- Enable debug mode
        logLevel = 2,              -- 1=errors, 2=warnings, 3=info, 4=debug
    }
    
    -- Apply custom options if provided
    if options then
        for k, v in pairs(options) do
            self.options[k] = v
        end
    end
    
    log(self, 3, "Created new registry: " .. self.name)
    
    return self
end

--[[ Registry API Implementation ]]--

-- Register a new component
function RegistryBase:register(id, module, version)
    -- Parameter validation
    if not id or type(id) ~= "string" then
        log(self, 1, "Failed to register component: Invalid ID")
        return false
    end
    
    if not module then
        log(self, 1, "Failed to register component: Module is nil", id)
        return false
    end
    
    -- Check if component already exists
    if self.components[id] and not self.options.allowOverrides then
        log(self, 2, "Component already registered: " .. id)
        return false
    end
    
    -- Create component info
    local componentInfo = {
        id = id,
        module = module,
        version = version or "1.0.0",
        dependencies = {},
        state = "registered",
        initialized = false,
        tags = {},
        metadata = {},
        registrationTime = os.time()
    }
    
    -- Register the component
    self.components[id] = componentInfo
    log(self, 3, string.format("Registered component: %s (v%s)", id, componentInfo.version))
    
    -- Auto-initialize if enabled
    if self.options.autoInit and type(module) == "table" and type(module.initialize) == "function" then
        task.spawn(function()
            self:initialize(id)
        end)
    end
    
    return true
end

-- Register a component with dependencies
function RegistryBase:registerWithDependencies(id, module, version, dependencies)
    if not id or not module then
        log(self, 1, "Failed to register component with dependencies: Invalid parameters")
        return false
    end
    
    -- Register the base component first
    if not self:register(id, module, version) then
        return false
    end
    
    -- Add dependencies
    if dependencies then
        self.components[id].dependencies = dependencies
        
        -- Log dependencies
        if self.options.logLevel >= 3 then
            local depList = ""
            for depId, depVersion in pairs(dependencies) do
                depList = depList .. depId .. " (>=" .. depVersion .. ") "
            end
            log(self, 3, "Component " .. id .. " has dependencies: " .. depList)
        end
    end
    
    return true
end

-- Get a registered component
function RegistryBase:get(id, minVersion)
    if not id then
        log(self, 1, "Cannot get component: ID is nil")
        return nil
    end
    
    local componentInfo = self.components[id]
    
    -- Check if component exists
    if not componentInfo then
        log(self, 2, "Component not found: " .. id)
        return nil
    end
    
    -- Check version requirement if specified
    if minVersion and self.options.strict and not meetsVersionRequirement(componentInfo.version, minVersion) then
        log(self, 2, string.format(
            "Component version mismatch: %s requires v%s but found v%s", 
            id, minVersion, componentInfo.version
        ))
        return nil
    end
    
    -- Return the module
    return componentInfo.module
end

-- Get the public API of a component
function RegistryBase:getApi(id, minVersion)
    if not id then
        log(self, 1, "Cannot get component API: ID is nil")
        return nil
    end
    
    local componentInfo = self.components[id]
    
    -- Check if component exists
    if not componentInfo then
        log(self, 2, "Component not found: " .. id)
        return nil
    end
    
    -- Check version requirement if specified
    if minVersion and self.options.strict and not meetsVersionRequirement(componentInfo.version, minVersion) then
        log(self, 2, string.format(
            "Component version mismatch: %s requires v%s but found v%s", 
            id, minVersion, componentInfo.version
        ))
        return nil
    end
    
    -- Return the component's API
    return getModuleApi(componentInfo)
end

-- Get information about a registered component
function RegistryBase:getInfo(id)
    if not id or not self.components[id] then
        return nil
    end
    
    -- Return a copy to prevent direct modification
    local info = self.components[id]
    local infoCopy = table.clone(info)
    
    -- Remove module reference for safety
    infoCopy.module = nil
    
    return infoCopy
end

-- Check if a component is registered and meets version requirement
function RegistryBase:has(id, minVersion)
    if not id then
        return false
    end
    
    local componentInfo = self.components[id]
    
    if not componentInfo then
        return false
    end
    
    if not minVersion then
        return true
    end
    
    return meetsVersionRequirement(componentInfo.version, minVersion)
end

-- Remove a registered component
function RegistryBase:remove(id)
    if not id or not self.components[id] then
        return false
    end
    
    -- Check if other components depend on this one
    local dependents = findDependents(self, id)
    if #dependents > 0 and self.options.strict then
        log(self, 2, "Cannot remove component " .. id .. " because other components depend on it: " .. table.concat(dependents, ", "))
        return false
    end
    
    -- If it's initialized, try to shut it down first
    if self.components[id].initialized then
        self:shutdown(id)
    end
    
    -- Remove the component
    self.components[id] = nil
    log(self, 3, "Removed component: " .. id)
    
    return true
end

-- Initialize a specific component
function RegistryBase:initialize(componentId)
    -- Initialize all components if none specified
    if not componentId then
        return self:initializeAll().failures == 0
    end
    
    local componentInfo = self.components[componentId]
    
    -- Check if component exists
    if not componentInfo then
        log(self, 2, "Cannot initialize: Component not found: " .. componentId)
        return false
    end
    
    -- Check if already initialized
    if componentInfo.initialized then
        return true
    end
    
    -- Check if already initializing (prevent recursion)
    if componentInfo.state == "initializing" then
        log(self, 2, "Component is already being initialized: " .. componentId)
        return false
    end
    
    -- Mark as initializing
    componentInfo.state = "initializing"
    
    -- Resolve dependencies
    local depsResolved, depsError = resolveDependencies(self, componentId)
    if not depsResolved then
        componentInfo.state = "error"
        componentInfo.errorInfo = {
            message = "Dependency resolution failed: " .. depsError,
            trace = debug.traceback()
        }
        log(self, 1, "Failed to initialize component " .. componentId .. ": " .. depsError)
        return false
    end
    
    -- Check if module has initialize method
    if type(componentInfo.module) == "table" and type(componentInfo.module.initialize) == "function" then
        -- Call initialize method
        local success, result = pcall(function()
            return componentInfo.module:initialize()
        end)
        
        -- Handle initialization result
        if success then
            componentInfo.initialized = true
            componentInfo.state = "ready"
            
            -- If the initialize method returned an API, store it
            if result ~= nil and result ~= true then
                componentInfo.api = result
            end
            
            log(self, 3, "Initialized component: " .. componentId)
            return true
        else
            componentInfo.state = "error"
            componentInfo.errorInfo = {
                message = "Initialization error: " .. tostring(result),
                trace = debug.traceback()
            }
            log(self, 1, "Error initializing component " .. componentId .. ": " .. tostring(result))
            return false
        end
    else
        -- No initialize method, consider it initialized
        componentInfo.initialized = true
        componentInfo.state = "ready"
        return true
    end
end

-- Initialize all components
function RegistryBase:initializeAll()
    local results = {
        succeeded = {},
        failures = {}
    }
    
    -- First, build a dependency graph
    local dependencyGraph = {}
    for id, info in pairs(self.components) do
        dependencyGraph[id] = {
            dependencies = info.dependencies or {},
            initialized = false
        }
    end
    
    -- Helper function to initialize a component and its dependencies
    local function initializeWithDependencies(id)
        -- Skip already initialized components
        if dependencyGraph[id].initialized then
            return true
        end
        
        -- Mark as in progress to detect cycles
        dependencyGraph[id].initialized = "in_progress"
        
        -- Initialize dependencies first
        if dependencyGraph[id].dependencies then
            for depId, _ in pairs(dependencyGraph[id].dependencies) do
                if not dependencyGraph[depId] then
                    results.failures[id] = "Missing dependency: " .. depId
                    return false
                end
                
                if dependencyGraph[depId].initialized == "in_progress" then
                    results.failures[id] = "Circular dependency detected with: " .. depId
                    return false
                end
                
                if not dependencyGraph[depId].initialized then
                    if not initializeWithDependencies(depId) then
                        results.failures[id] = "Dependency initialization failed: " .. depId
                        return false
                    end
                end
            end
        end
        
        -- Initialize the component
        local success = self:initialize(id)
        if success then
            dependencyGraph[id].initialized = true
            table.insert(results.succeeded, id)
            return true
        else
            results.failures[id] = "Initialization failed"
            return false
        end
    end
    
    -- Initialize all components in dependency order
    for id, _ in pairs(self.components) do
        if not dependencyGraph[id].initialized then
            initializeWithDependencies(id)
        end
    end
    
    return results
end

-- Shut down a specific component
function RegistryBase:shutdown(componentId)
    -- Shutdown all components if none specified
    if not componentId then
        return self:shutdownAll().failures == 0
    end
    
    local componentInfo = self.components[componentId]
    
    -- Check if component exists
    if not componentInfo then
        log(self, 2, "Cannot shutdown: Component not found: " .. componentId)
        return false
    end
    
    -- Check if initialized
    if not componentInfo.initialized then
        return true
    end
    
    -- Check if other components depend on this one
    local dependents = findDependents(self, componentId)
    if #dependents > 0 then
        -- Shutdown dependent components first
        for _, depId in ipairs(dependents) do
            if self.components[depId].initialized then
                local success = self:shutdown(depId)
                if not success and self.options.strict then
                    log(self, 2, "Failed to shutdown dependent component: " .. depId)
                    return false
                end
            end
        end
    end
    
    -- Check if module has shutdown method
    if type(componentInfo.module) == "table" and type(componentInfo.module.shutdown) == "function" then
        -- Call shutdown method
        local success, result = pcall(function()
            return componentInfo.module:shutdown()
        end)
        
        -- Handle shutdown result
        if success then
            componentInfo.initialized = false
            componentInfo.state = "registered"
            log(self, 3, "Shut down component: " .. componentId)
            return true
        else
            componentInfo.errorInfo = {
                message = "Shutdown error: " .. tostring(result),
                trace = debug.traceback()
            }
            log(self, 1, "Error shutting down component " .. componentId .. ": " .. tostring(result))
            return false
        end
    else
        -- No shutdown method, consider it shut down
        componentInfo.initialized = false
        componentInfo.state = "registered"
        return true
    end
end

-- Shut down all components
function RegistryBase:shutdownAll()
    local results = {
        succeeded = {},
        failures = {}
    }
    
    -- Build a reverse dependency graph
    local reverseDepGraph = {}
    for id, info in pairs(self.components) do
        if not reverseDepGraph[id] then
            reverseDepGraph[id] = {}
        end
        
        if info.dependencies then
            for depId, _ in pairs(info.dependencies) do
                if not reverseDepGraph[depId] then
                    reverseDepGraph[depId] = {}
                end
                table.insert(reverseDepGraph[depId], id)
            end
        end
    end
    
    -- Shutdown components in reverse dependency order (leaves first)
    local visited = {}
    local function shutdownWithDependents(id)
        if visited[id] then
            return
        end
        visited[id] = true
        
        -- First shutdown components that depend on this one
        if reverseDepGraph[id] then
            for _, depId in ipairs(reverseDepGraph[id]) do
                shutdownWithDependents(depId)
            end
        end
        
        -- Then shutdown this component
        if self.components[id] and self.components[id].initialized then
            local success = self:shutdown(id)
            if success then
                table.insert(results.succeeded, id)
            else
                results.failures[id] = "Shutdown failed"
            end
        end
    end
    
    -- Start with components that have no dependents
    for id, _ in pairs(self.components) do
        if not reverseDepGraph[id] or #reverseDepGraph[id] == 0 then
            shutdownWithDependents(id)
        end
    end
    
    -- Handle any remaining components (in case of circular dependencies)
    for id, info in pairs(self.components) do
        if not visited[id] and info.initialized then
            local success = self:shutdown(id)
            if success then
                table.insert(results.succeeded, id)
            else
                results.failures[id] = "Shutdown failed"
            end
        end
    end
    
    return results
end

-- List components matching criteria
function RegistryBase:listComponents(filter)
    local result = {}
    
    for _, componentInfo in pairs(self.components) do
        local matches = true
        
        if filter then
            -- Filter by tags
            if filter.tags then
                for _, tag in ipairs(filter.tags) do
                    if not componentInfo.tags or not componentInfo.tags[tag] then
                        matches = false
                        break
                    end
                end
            end
            
            -- Filter by state
            if filter.state and componentInfo.state ~= filter.state then
                matches = false
            end
        end
        
        if matches then
            -- Include a copy of the info without the module reference
            local infoCopy = table.clone(componentInfo)
            infoCopy.module = nil
            table.insert(result, infoCopy)
        end
    end
    
    return result
end

-- Find components by tag
function RegistryBase:findComponentsByTag(tag)
    if not tag then
        return {}
    end
    
    return self:listComponents({ tags = {tag} })
end

-- Set or clear a tag on a component
function RegistryBase:setTag(componentId, tag, value)
    if not componentId or not tag or not self.components[componentId] then
        return false
    end
    
    -- Initialize tags table if needed
    if not self.components[componentId].tags then
        self.components[componentId].tags = {}
    end
    
    -- Set or clear the tag
    if value == nil or value == false then
        self.components[componentId].tags[tag] = nil
    else
        self.components[componentId].tags[tag] = true
    end
    
    return true
end

-- Set metadata on a component
function RegistryBase:setMetadata(componentId, key, value)
    if not componentId or not key or not self.components[componentId] then
        return false
    end
    
    -- Initialize metadata table if needed
    if not self.components[componentId].metadata then
        self.components[componentId].metadata = {}
    end
    
    -- Set the metadata
    self.components[componentId].metadata[key] = value
    return true
end

-- Get components that depend on a specified component
function RegistryBase:getDependents(componentId)
    if not componentId then
        return {}
    end
    
    return findDependents(self, componentId)
end

-- Get all registry errors
function RegistryBase:getErrors()
    local errors = {}
    
    for id, componentInfo in pairs(self.components) do
        if componentInfo.errorInfo then
            errors[id] = componentInfo.errorInfo
        end
    end
    
    return errors
end

-- Set registry options
function RegistryBase:setOptions(options)
    if not options or type(options) ~= "table" then
        return
    end
    
    for k, v in pairs(options) do
        self.options[k] = v
    end
end

-- Get registry options
function RegistryBase:getOptions()
    return table.clone(self.options)
end

return RegistryBase
