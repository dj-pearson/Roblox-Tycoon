--!strict
--[[
    RegistryMigration.luau
    
    A utility module to assist in migrating components from the legacy registry systems
    to the new unified Registry System. This module provides tools for:
    
    1. Mapping old registry components to the new system
    2. Converting legacy dependencies to the new format
    3. Automating the registration process with appropriate context
    4. Providing compatibility wrappers for systems still using the old APIs
    
    Author: Created April 28, 2025
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import required modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryModules = SharedModules:WaitForChild("Registry")

local RegistryBase = require(RegistryModules:WaitForChild("RegistryBase"))

local ClientRegistry
local ServerRegistry
local SharedRegistry

-- Determine execution context and load appropriate registries
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

if isClient then
    local ClientModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("Core"):WaitForChild("Registry")
    ClientRegistry = require(ClientModules:WaitForChild("ClientRegistry")).get()
end

if isServer then
    local ServerModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("server"):WaitForChild("Core"):WaitForChild("Registry")
    ServerRegistry = require(ServerModules:WaitForChild("ServerRegistry")).get()
end

SharedRegistry = require(RegistryModules:WaitForChild("SharedRegistry")).get()

-- Type definitions
export type MigrationConfig = {
    legacyNamespace: string,  -- The old namespace or module name
    targetRegistry: string,   -- Which registry to use: "client", "server", "shared"
    componentType: string?,   -- Optional component type identifier
    versionMap: {[string]: string}?, -- Version mapping for components
    dependencyMap: {[string]: {[string]: string}}?, -- Dependency mapping
    contextMap: {[string]: "client" | "server" | "both"}?, -- Context mapping
    idTransformer: ((string) -> string)? -- Function to transform IDs
}

export type LegacyComponent = {
    [string]: any
}

-- Module Implementation
local RegistryMigration = {}

-- Map old module names to new registry IDs
function RegistryMigration.transformId(id: string, config: MigrationConfig): string
    if config.idTransformer then
        return config.idTransformer(id)
    end
    
    -- Default transformation: replace dots with underscores, convert to PascalCase
    local newId = id:gsub("%.", "_")
    
    -- Add namespace prefix if not already present
    if not newId:find(config.legacyNamespace) then
        newId = config.legacyNamespace .. "_" .. newId
    end
    
    return newId
end

-- Get the appropriate registry based on configuration
function RegistryMigration.getTargetRegistry(config: MigrationConfig)
    if config.targetRegistry == "client" then
        return ClientRegistry
    elseif config.targetRegistry == "server" then
        return ServerRegistry
    else
        return SharedRegistry
    end
end

-- Determine the version for a component based on config or defaults
function RegistryMigration.determineVersion(id: string, component: LegacyComponent, config: MigrationConfig): string
    -- Check if the component has an explicit version property
    if component.VERSION then
        return component.VERSION
    end
    
    -- Check version map in config
    if config.versionMap and config.versionMap[id] then
        return config.versionMap[id]
    end
    
    -- Default to 1.0.0
    return "1.0.0"
end

-- Map legacy dependencies to new dependency format
function RegistryMigration.mapDependencies(id: string, component: LegacyComponent, config: MigrationConfig): {[string]: string}?
    local dependencies = {}
    
    -- Check if component has a DEPENDENCIES table
    if type(component.DEPENDENCIES) == "table" then
        for depId, depVersion in pairs(component.DEPENDENCIES) do
            local newDepId = RegistryMigration.transformId(depId, config)
            dependencies[newDepId] = depVersion
        end
        return dependencies
    end
    
    -- Check dependency map in config
    if config.dependencyMap and config.dependencyMap[id] then
        return config.dependencyMap[id]
    end
    
    -- If no dependencies found
    return nil
end

-- Determine the context for a component
function RegistryMigration.determineContext(id: string, component: LegacyComponent, config: MigrationConfig): "client" | "server" | "both"
    -- Check if component has an explicit context
    if component.CONTEXT then
        return component.CONTEXT
    end
    
    -- Check context map in config
    if config.contextMap and config.contextMap[id] then
        return config.contextMap[id]
    end
    
    -- Default based on target registry
    if config.targetRegistry == "client" then
        return "client"
    elseif config.targetRegistry == "server" then
        return "server"
    else
        return "both"
    end
end

-- Migrate a single component to the new registry system
function RegistryMigration.migrateComponent(
    id: string, 
    component: LegacyComponent, 
    config: MigrationConfig
): boolean
    -- Transform ID according to config
    local newId = RegistryMigration.transformId(id, config)
    
    -- Get the target registry
    local registry = RegistryMigration.getTargetRegistry(config)
    if not registry then
        warn("[RegistryMigration] Target registry not available:", config.targetRegistry)
        return false
    end
    
    -- Determine component version
    local version = RegistryMigration.determineVersion(id, component, config)
    
    -- Map dependencies
    local dependencies = RegistryMigration.mapDependencies(id, component, config)
    
    -- Determine context for shared registry
    local context
    if config.targetRegistry == "shared" then
        context = RegistryMigration.determineContext(id, component, config)
    end
    
    -- Register with the appropriate registry
    local success = false
    
    if config.targetRegistry == "client" then
        if typeof(component) == "table" and component.mount and component.unmount then
            -- Looks like a UI component
            success = registry:registerUIComponent(newId, component)
        else
            -- Regular component
            if dependencies then
                success = registry:registerWithDependencies(newId, component, version, dependencies)
            else
                success = registry:register(newId, component, version)
            end
        end
    elseif config.targetRegistry == "server" then
        if typeof(component) == "table" and (component.start and component.stop) then
            -- Looks like a service
            success = registry:registerService(newId, component, {
                autostart = component.AUTOSTART ~= false,
                version = version,
                dependencies = dependencies
            })
        elseif typeof(component) == "table" and component.run then
            -- Looks like a system
            success = registry:registerSystem(newId, component, {
                autorun = component.AUTORUN ~= false,
                interval = component.INTERVAL,
                version = version,
                dependencies = dependencies
            })
        else
            -- Regular component
            if dependencies then
                success = registry:registerWithDependencies(newId, component, version, dependencies)
            else
                success = registry:register(newId, component, version)
            end
        end
    else
        -- Shared registry
        local options = {
            version = version,
            context = context,
            isUtility = component.IS_UTILITY == true
        }
        
        success = registry:registerShared(newId, component, options)
    end
    
    if success then
        print("[RegistryMigration] Successfully migrated:", id, "->", newId)
    else
        warn("[RegistryMigration] Failed to migrate:", id)
    end
    
    return success
end

-- Migrate multiple components from a table
function RegistryMigration.migrateComponents(
    components: {[string]: LegacyComponent}, 
    config: MigrationConfig
): {success: number, failure: number}
    local results = {
        success = 0,
        failure = 0
    }
    
    for id, component in pairs(components) do
        local success = RegistryMigration.migrateComponent(id, component, config)
        if success then
            results.success += 1
        else
            results.failure += 1
        end
    end
    
    print("[RegistryMigration] Migration complete. Success:", results.success, "Failure:", results.failure)
    return results
end

-- Create a compatibility wrapper for old client registry
function RegistryMigration.createClientRegistryWrapper(config: MigrationConfig)
    local legacyRegistry = {
        systems = {},
        initialized = {},
        dependencies = {}
    }
    
    -- Map to our new ClientRegistry
    function legacyRegistry.registerSystem(systemName, systemModule)
        -- Transform ID for new registry
        local newId = RegistryMigration.transformId(systemName, config)
        
        -- Register with new system
        ClientRegistry:register(newId, systemModule)
        
        -- Store in legacy systems table
        legacyRegistry.systems[systemName] = systemModule
        
        return systemModule
    end
    
    function legacyRegistry.getSystem(systemName)
        -- First check legacy systems table
        if legacyRegistry.systems[systemName] then
            return legacyRegistry.systems[systemName]
        end
        
        -- Try to get from new registry with transformed ID
        local newId = RegistryMigration.transformId(systemName, config)
        local system = ClientRegistry:get(newId)
        
        -- If found, also store in legacy table
        if system then
            legacyRegistry.systems[systemName] = system
        end
        
        return system
    end
    
    function legacyRegistry.defineDependencies(systemName, dependencyList)
        -- Store in legacy dependencies table
        legacyRegistry.dependencies[systemName] = dependencyList
        
        -- Also try to update in new registry
        local newId = RegistryMigration.transformId(systemName, config)
        local system = ClientRegistry:get(newId)
        
        if system then
            local dependencies = {}
            for _, depName in ipairs(dependencyList) do
                local depId = RegistryMigration.transformId(depName, config)
                dependencies[depId] = "1.0.0" -- Default version
            end
            
            -- Update component info in registry
            if not ClientRegistry.components[newId].dependencies then
                ClientRegistry.components[newId].dependencies = {}
            end
            
            for depId, depVersion in pairs(dependencies) do
                ClientRegistry.components[newId].dependencies[depId] = depVersion
            end
        end
    end
    
    function legacyRegistry.initializeSystem(systemName)
        -- Mark as initialized in legacy table
        legacyRegistry.initialized[systemName] = true
        
        -- Initialize in new registry
        local newId = RegistryMigration.transformId(systemName, config)
        return ClientRegistry:initialize(newId)
    end
    
    function legacyRegistry.getInitializedSystem(systemName)
        -- First check if already initialized in legacy table
        if not legacyRegistry.initialized[systemName] then
            legacyRegistry.initializeSystem(systemName)
        end
        
        return legacyRegistry.getSystem(systemName)
    end
    
    return legacyRegistry
end

-- Create a compatibility wrapper for old server registry
function RegistryMigration.createServerRegistryWrapper(config: MigrationConfig)
    local legacyRegistry = {
        systems = {},
        initialized = {},
        loading = {}
    }
    
    -- Map to our new ServerRegistry
    function legacyRegistry.registerSystem(name, system, dependencies)
        -- Register with new registry
        local newId = RegistryMigration.transformId(name, config)
        
        local newDeps = {}
        if dependencies then
            for depName, depRequirement in pairs(dependencies) do
                local depId = RegistryMigration.transformId(depName, config)
                -- Convert boolean requirements to version strings
                if type(depRequirement) == "boolean" then
                    if depRequirement then
                        newDeps[depId] = "1.0.0" -- Required
                    end
                else
                    newDeps[depId] = depRequirement -- Version string
                end
            end
        end
        
        local isService = typeof(system) == "table" and (system.start and system.stop)
        local isSystem = typeof(system) == "table" and system.run
        
        if isService then
            ServerRegistry:registerService(newId, system, {
                version = "1.0.0",
                dependencies = newDeps
            })
        elseif isSystem then
            ServerRegistry:registerSystem(newId, system, {
                version = "1.0.0",
                dependencies = newDeps
            })
        else
            if next(newDeps) then
                ServerRegistry:registerWithDependencies(newId, system, "1.0.0", newDeps)
            else
                ServerRegistry:register(newId, system, "1.0.0")
            end
        end
        
        -- Store in legacy systems table
        legacyRegistry.systems[name] = {
            module = system,
            dependencies = dependencies or {}
        }
        
        return system
    end
    
    function legacyRegistry.getSystem(name)
        -- First check legacy systems table
        if legacyRegistry.systems[name] then
            return legacyRegistry.systems[name].module
        end
        
        -- Try to get from new registry with transformed ID
        local newId = RegistryMigration.transformId(name, config)
        local system = ServerRegistry:get(newId)
        
        -- If found, also store in legacy table
        if system then
            legacyRegistry.systems[name] = {
                module = system,
                dependencies = {}
            }
        end
        
        return system
    end
    
    function legacyRegistry.initializeSystem(name)
        -- Mark as loading in legacy table
        legacyRegistry.loading[name] = true
        
        -- Initialize dependencies first
        local system = legacyRegistry.systems[name]
        if system and system.dependencies then
            for depName, _ in pairs(system.dependencies) do
                if not legacyRegistry.initialized[depName] then
                    if legacyRegistry.loading[depName] then
                        warn("[ServerRegistry] Circular dependency detected: " .. name .. " <-> " .. depName)
                    else
                        legacyRegistry.initializeSystem(depName)
                    end
                end
            end
        end
        
        -- Initialize in new registry
        local newId = RegistryMigration.transformId(name, config)
        local success = ServerRegistry:initialize(newId)
        
        -- Update legacy state
        legacyRegistry.loading[name] = nil
        legacyRegistry.initialized[name] = true
        
        return success
    end
    
    function legacyRegistry.getInitializedSystem(name)
        if not legacyRegistry.initialized[name] then
            legacyRegistry.initializeSystem(name)
        end
        
        return legacyRegistry.getSystem(name)
    end
    
    return legacyRegistry
end

-- Return the module
return RegistryMigration
