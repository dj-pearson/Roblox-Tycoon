--!strict
--[[
    ServerRegistry.luau
    
    Server-side registry implementation that extends RegistryBase with
    server-specific functionality for managing services, systems, and
    centralized server-side component registration.
    
    Features:
    - Service management and lifecycle control
    - System registration with environment context
    - Auto-discovery of server modules
    - Player-specific component tracking
    - Cross-service dependency management
    
    Author: Created April 27, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Import required modules
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryBase = require(SharedModules:WaitForChild("Registry"):WaitForChild("RegistryBase"))

-- Type definitions
type ServiceInfo = {
    id: string,
    serviceType: string,
    status: "stopped" | "starting" | "running" | "stopping" | "error",
    autostart: boolean,
    remoteObjects: {[string]: Instance},
    playerData: {[number]: any},
    startTime: number?,
    errorInfo: {message: string, trace: string}?
}

type SystemInfo = {
    id: string,
    systemType: string,
    environment: "server" | "client" | "shared",
    autorun: boolean,
    interval: number?,
    lastRunTime: number?,
    isRunning: boolean,
    runCount: number,
    status: "idle" | "running" | "paused" | "error"
}

-- Module Implementation
local ServerRegistry = {}
ServerRegistry.__index = ServerRegistry

-- Create a new server registry instance
function ServerRegistry.new(name)
    -- Create base registry
    local baseRegistry = RegistryBase.new(name or "ServerRegistry", {
        logLevel = 3,
        allowOverrides = false,
        autoInit = true
    })
    
    -- Create server registry as an extension of the base registry
    local self = setmetatable({
        -- Inherit all base registry properties
        name = baseRegistry.name,
        components = baseRegistry.components,
        options = baseRegistry.options,
        
        -- Server-specific properties
        services = {},
        systems = {},
        playerComponents = {},
        discoveredModules = {}
    }, ServerRegistry)
    
    -- Copy all methods from base registry
    for key, value in pairs(baseRegistry) do
        if type(value) == "function" and not self[key] then
            self[key] = value
        end
    end
    
    -- Initialize server registry
    self:initialize()
    
    print("[ServerRegistry] Created new registry:", name)
    
    return self
end

--[[ Private Utility Functions ]]--

-- Scan for modules in a container
local function scanForModules(container, path, results)
    results = results or {}
    path = path or container.Name
    
    -- Process each child
    for _, child in pairs(container:GetChildren()) do
        local childPath = path .. "/" .. child.Name
        
        -- If module script, add to results
        if child:IsA("ModuleScript") then
            table.insert(results, {
                instance = child,
                path = childPath
            })
        end
        
        -- If container, scan recursively
        if child:IsA("Folder") or child:IsA("Configuration") then
            scanForModules(child, childPath, results)
        end
    end
    
    return results
end

-- Auto-discover modules
local function discoverModules(self)
    local modules = {}
    
    -- Scan server scripts
    local serverScripts = game:GetService("ServerScriptService"):FindFirstChild("src")
    if serverScripts then
        local serverModules = scanForModules(serverScripts, "ServerScripts")
        for _, moduleInfo in ipairs(serverModules) do
            table.insert(modules, moduleInfo)
        end
    end
    
    -- Scan server storage
    local serverStorage = ServerStorage:FindFirstChild("src") 
    if serverStorage then
        local storageModules = scanForModules(serverStorage, "ServerStorage")
        for _, moduleInfo in ipairs(serverModules) do
            table.insert(modules, moduleInfo)
        end
    end
    
    -- Store discovered modules
    self.discoveredModules = modules
    
    return modules
end

-- Connect player events for tracking player-specific components
local function connectPlayerEvents(self)
    -- Track player joining
    Players.PlayerAdded:Connect(function(player)
        -- Create player component table if it doesn't exist
        if not self.playerComponents[player.UserId] then
            self.playerComponents[player.UserId] = {}
        end
        
        -- Notify services of player joining
        for serviceId, serviceInfo in pairs(self.services) do
            if serviceInfo.status == "running" then
                local service = self:get(serviceId)
                if service and type(service.onPlayerJoined) == "function" then
                    task.spawn(function()
                        pcall(function()
                            service:onPlayerJoined(player)
                        end)
                    end)
                end
            end
        end
    end)
    
    -- Clean up when player leaves
    Players.PlayerRemoving:Connect(function(player)
        -- Notify services of player leaving
        for serviceId, serviceInfo in pairs(self.services) do
            if serviceInfo.status == "running" then
                local service = self:get(serviceId)
                if service and type(service.onPlayerLeaving) == "function" then
                    task.spawn(function()
                        pcall(function()
                            service:onPlayerLeaving(player)
                        end)
                    end)
                end
            end
        end
        
        -- Clean up player components
        if self.playerComponents[player.UserId] then
            self.playerComponents[player.UserId] = nil
        end
    end)
end

-- Set up cleanup functions
local function setupCleanup(self)
    -- Clean up on game close
    game:BindToClose(function()
        self:cleanup()
    end)
end

--[[ Server Registry API Implementation ]]--

-- Initialize the server registry
function ServerRegistry:initialize()
    -- Only run on server
    if not RunService:IsServer() then
        warn("[ServerRegistry] Cannot initialize on client")
        return false
    end
    
    -- Connect player events
    connectPlayerEvents(self)
    
    -- Set up cleanup
    setupCleanup(self)
    
    return true
end

-- Register a service
function ServerRegistry:registerService(id, service, options)
    -- Validate parameters
    if not id or not service then
        warn("[ServerRegistry] Failed to register service: Invalid parameters")
        return false
    end
    
    options = options or {}
    
    -- First register as a normal component
    if not self:register(id, service, options.version) then
        return false
    end
    
    -- Create service info
    local serviceInfo = {
        id = id,
        serviceType = options.serviceType or "default",
        status = "stopped",
        autostart = options.autostart ~= false,
        remoteObjects = {},
        playerData = {}
    }
    
    -- Store service info
    self.services[id] = serviceInfo
    
    -- Set service tag
    self:setTag(id, "service", true)
    
    -- Register dependencies
    if options.dependencies then
        for depId, depVersion in pairs(options.dependencies) do
            -- Add to component dependencies
            if not self.components[id].dependencies then
                self.components[id].dependencies = {}
            end
            self.components[id].dependencies[depId] = depVersion
        end
    end
    
    -- Set up any remote objects
    if options.remoteObjects then
        -- Create remote folder in ReplicatedStorage
        local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotesFolder then
            remotesFolder = Instance.new("Folder")
            remotesFolder.Name = "Remotes"
            remotesFolder.Parent = ReplicatedStorage
        end
        
        -- Create service remotes folder
        local serviceFolder = remotesFolder:FindFirstChild(id)
        if not serviceFolder then
            serviceFolder = Instance.new("Folder")
            serviceFolder.Name = id
            serviceFolder.Parent = remotesFolder
        end
        
        -- Create remote objects
        for objName, objType in pairs(options.remoteObjects) do
            local objInstance = serviceFolder:FindFirstChild(objName)
            
            -- Create if it doesn't exist
            if not objInstance then
                if objType == "event" then
                    objInstance = Instance.new("RemoteEvent")
                    objInstance.Name = objName
                    objInstance.Parent = serviceFolder
                elseif objType == "function" then
                    objInstance = Instance.new("RemoteFunction")
                    objInstance.Name = objName
                    objInstance.Parent = serviceFolder
                end
            end
            
            -- Store in service info
            if objInstance then
                serviceInfo.remoteObjects[objName] = objInstance
            end
        end
    end
    
    -- Auto-start service if enabled
    if serviceInfo.autostart then
        task.spawn(function()
            self:startService(id)
        end)
    end
    
    return true
end

-- Register a system
function ServerRegistry:registerSystem(id, system, options)
    -- Validate parameters
    if not id or not system then
        warn("[ServerRegistry] Failed to register system: Invalid parameters")
        return false
    end
    
    options = options or {}
    
    -- First register as a normal component
    if not self:register(id, system, options.version) then
        return false
    end
    
    -- Create system info
    local systemInfo = {
        id = id,
        systemType = options.systemType or "default",
        environment = options.environment or "server",
        autorun = options.autorun ~= false,
        interval = options.interval,
        runCount = 0,
        isRunning = false,
        status = "idle"
    }
    
    -- Store system info
    self.systems[id] = systemInfo
    
    -- Set system tag
    self:setTag(id, "system", true)
    
    -- Set up system dependencies
    if options.dependencies then
        for depId, depVersion in pairs(options.dependencies) do
            -- Add to component dependencies
            if not self.components[id].dependencies then
                self.components[id].dependencies = {}
            end
            self.components[id].dependencies[depId] = depVersion
        end
    end
    
    -- Auto-run system if enabled
    if systemInfo.autorun then
        task.spawn(function()
            if systemInfo.interval then
                self:startSystemInterval(id)
            else
                self:runSystem(id)
            end
        end)
    end
    
    return true
end

-- Start a service
function ServerRegistry:startService(id)
    -- Validate service
    local serviceInfo = self.services[id]
    if not serviceInfo then
        warn("[ServerRegistry] Cannot start service: Not found:", id)
        return false
    end
    
    -- Check if service is already running
    if serviceInfo.status == "running" or serviceInfo.status == "starting" then
        return true
    end
    
    -- Update status
    serviceInfo.status = "starting"
    
    -- Get service
    local service = self:get(id)
    if not service then
        warn("[ServerRegistry] Cannot start service: Failed to get module:", id)
        serviceInfo.status = "error"
        serviceInfo.errorInfo = {
            message = "Failed to get service module",
            trace = debug.traceback()
        }
        return false
    end
    
    -- Initialize service
    local success = self:initialize(id)
    if not success then
        warn("[ServerRegistry] Failed to initialize service:", id)
        serviceInfo.status = "error"
        return false
    end
    
    -- Start service
    if type(service.start) == "function" then
        -- Call start method
        local startSuccess, result = pcall(function()
            return service:start()
        end)
        
        -- Handle start result
        if not startSuccess then
            warn("[ServerRegistry] Error starting service:", id, result)
            serviceInfo.status = "error"
            serviceInfo.errorInfo = {
                message = "Start error: " .. tostring(result),
                trace = debug.traceback()
            }
            return false
        end
    end
    
    -- Set up remote handlers
    if type(service.setupRemotes) == "function" then
        local setupSuccess, result = pcall(function()
            return service:setupRemotes(serviceInfo.remoteObjects)
        end)
        
        if not setupSuccess then
            warn("[ServerRegistry] Error setting up remotes for service:", id, result)
        end
    end
    
    -- Service started successfully
    serviceInfo.status = "running"
    serviceInfo.startTime = os.time()
    
    return true
end

-- Stop a service
function ServerRegistry:stopService(id)
    -- Validate service
    local serviceInfo = self.services[id]
    if not serviceInfo then
        warn("[ServerRegistry] Cannot stop service: Not found:", id)
        return false
    end
    
    -- Check if service is already stopped
    if serviceInfo.status == "stopped" or serviceInfo.status == "stopping" then
        return true
    end
    
    -- Update status
    serviceInfo.status = "stopping"
    
    -- Get service
    local service = self:get(id)
    if not service then
        serviceInfo.status = "stopped"
        return true
    end
    
    -- Stop service
    if type(service.stop) == "function" then
        -- Call stop method
        local success, result = pcall(function()
            return service:stop()
        end)
        
        -- Handle stop result
        if not success then
            warn("[ServerRegistry] Error stopping service:", id, result)
            serviceInfo.status = "error"
            serviceInfo.errorInfo = {
                message = "Stop error: " .. tostring(result),
                trace = debug.traceback()
            }
            return false
        end
    end
    
    -- Service stopped successfully
    serviceInfo.status = "stopped"
    serviceInfo.startTime = nil
    
    return true
end

-- Run a system once
function ServerRegistry:runSystem(id)
    -- Validate system
    local systemInfo = self.systems[id]
    if not systemInfo then
        warn("[ServerRegistry] Cannot run system: Not found:", id)
        return false
    end
    
    -- Check if system is already running
    if systemInfo.isRunning then
        return true
    end
    
    -- Get system
    local system = self:get(id)
    if not system then
        warn("[ServerRegistry] Cannot run system: Failed to get module:", id)
        systemInfo.status = "error"
        return false
    end
    
    -- Initialize system if needed
    if not self.components[id].initialized then
        local success = self:initialize(id)
        if not success then
            warn("[ServerRegistry] Failed to initialize system:", id)
            systemInfo.status = "error"
            return false
        end
    end
    
    -- Update status
    systemInfo.isRunning = true
    systemInfo.status = "running"
    
    -- Run system
    if type(system.run) == "function" then
        local success, result = pcall(function()
            return system:run()
        end)
        
        -- Handle run result
        if not success then
            warn("[ServerRegistry] Error running system:", id, result)
            systemInfo.status = "error"
            systemInfo.isRunning = false
            return false
        end
    end
    
    -- System ran successfully
    systemInfo.status = "idle"
    systemInfo.isRunning = false
    systemInfo.runCount += 1
    systemInfo.lastRunTime = os.time()
    
    return true
end

-- Start a system on an interval
function ServerRegistry:startSystemInterval(id)
    -- Validate system
    local systemInfo = self.systems[id]
    if not systemInfo then
        warn("[ServerRegistry] Cannot start system interval: Not found:", id)
        return false
    end
    
    -- Check if system has interval
    if not systemInfo.interval or systemInfo.interval <= 0 then
        warn("[ServerRegistry] System has no interval:", id)
        return false
    end
    
    -- Check if already running on interval
    if systemInfo.intervalConnection then
        return true
    end
    
    -- Create interval task
    task.spawn(function()
        while self.systems[id] and self.systems[id].interval do
            -- Run the system
            self:runSystem(id)
            
            -- Wait for interval
            task.wait(self.systems[id].interval)
        end
    end)
    
    return true
end

-- Stop a system interval
function ServerRegistry:stopSystemInterval(id)
    -- Validate system
    local systemInfo = self.systems[id]
    if not systemInfo then
        warn("[ServerRegistry] Cannot stop system interval: Not found:", id)
        return false
    end
    
    -- Check if running on interval
    if not systemInfo.intervalConnection then
        return true
    end
    
    -- Clear the interval
    systemInfo.interval = nil
    
    return true
end

-- Get remote objects for a service
function ServerRegistry:getServiceRemotes(serviceId)
    local serviceInfo = self.services[serviceId]
    if not serviceInfo then
        return nil
    end
    
    return serviceInfo.remoteObjects
end

-- Get player-specific component
function ServerRegistry:getPlayerComponent(userId, componentId)
    if not userId or not componentId then
        return nil
    end
    
    -- Check if player components exist
    if not self.playerComponents[userId] then
        return nil
    end
    
    -- Return the component
    return self.playerComponents[userId][componentId]
end

-- Set player-specific component
function ServerRegistry:setPlayerComponent(userId, componentId, component)
    if not userId or not componentId or not component then
        return false
    end
    
    -- Create player components table if it doesn't exist
    if not self.playerComponents[userId] then
        self.playerComponents[userId] = {}
    end
    
    -- Set the component
    self.playerComponents[userId][componentId] = component
    return true
end

-- Auto-discover and register modules
function ServerRegistry:discoverAndRegister(options)
    options = options or {}
    local moduleTypes = options.types or {"service", "system", "utility"}
    local autoStartServices = options.autoStartServices ~= false
    local autoRunSystems = options.autoRunSystems ~= false
    
    -- Discover modules
    local modules = discoverModules(self)
    local registeredCount = 0
    
    -- Try to load and register each module
    for _, moduleInfo in ipairs(modules) do
        local success, moduleInstance = pcall(function()
            return require(moduleInfo.instance)
        end)
        
        if not success then
            warn("[ServerRegistry] Failed to require module:", moduleInfo.path, moduleInstance)
            continue
        end
        
        -- Skip if module is not a table
        if type(moduleInstance) ~= "table" then
            continue
        end
        
        -- Try to determine module type
        local moduleType = nil
        
        -- Check for explicit module type
        if moduleInstance.MODULE_TYPE then
            moduleType = moduleInstance.MODULE_TYPE
        -- Check based on path or name
        elseif string.find(moduleInfo.path:lower(), "service") then
            moduleType = "service"
        elseif string.find(moduleInfo.path:lower(), "system") then
            moduleType = "system"
        elseif string.find(moduleInfo.path:lower(), "utility") or 
               string.find(moduleInfo.path:lower(), "util") then
            moduleType = "utility"
        end
        
        -- Skip modules types that don't match filter
        if moduleType and not table.find(moduleTypes, moduleType) then
            continue
        end
        
        -- Generate ID from path
        local id = moduleInfo.instance.Name
        if options.usePathAsId then
            id = moduleInfo.path:gsub("/", ".")
        end
        
        -- Register module based on its type
        if moduleType == "service" then
            self:registerService(id, moduleInstance, {
                autostart = autoStartServices,
                serviceType = moduleInstance.SERVICE_TYPE
            })
            registeredCount += 1
        elseif moduleType == "system" then
            self:registerSystem(id, moduleInstance, {
                autorun = autoRunSystems,
                interval = moduleInstance.INTERVAL,
                systemType = moduleInstance.SYSTEM_TYPE
            })
            registeredCount += 1
        else
            -- Register as a regular component
            self:register(id, moduleInstance, moduleInstance.VERSION)
            registeredCount += 1
        end
    end
    
    print("[ServerRegistry] Auto-discovered and registered", registeredCount, "modules")
    return registeredCount
end

-- Clean up all services and systems
function ServerRegistry:cleanup()
    -- Stop all services
    for serviceId, _ in pairs(self.services) do
        self:stopService(serviceId)
    end
    
    -- Stop all system intervals
    for systemId, _ in pairs(self.systems) do
        self:stopSystemInterval(systemId)
    end
    
    -- Shut down all components
    self:shutdownAll()
    
    return true
end

-- Build server registry singleton
local ServerRegistryInstance = nil

-- Create singleton instance
local function createSingleton()
    -- Only create on server
    if not RunService:IsServer() then
        return nil
    end
    
    -- Create instance if doesn't exist
    if not ServerRegistryInstance then
        ServerRegistryInstance = ServerRegistry.new("GlobalServerRegistry")
    end
    
    return ServerRegistryInstance
end

-- Get singleton instance
local function getInstance()
    return ServerRegistryInstance or createSingleton()
end

return {
    new = ServerRegistry.new,
    get = getInstance
}
