--[[
    CoreRegistryMonitor.server.luau
    
    A monitoring system for CoreRegistry that provides real-time feedback
    about the health and status of the registry and its components.
    
    Created to address CoreRegistry System Failure identified in RobloxIssues.txt
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true,                -- Enable debug prints
    checkInterval = 10,          -- How often to check registry health
    maxAttempts = 3,             -- Maximum attempts to check registry
    initialDelay = 2,            -- Initial delay before first check
    checkDelay = 5,              -- Delay between checks
    criticalSystems = {          -- Systems considered critical
        "CoreRegistry",
        "DataManager",
        "TycoonSystem"
    }
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[CoreRegistryMonitor]", ...)
    end
end

-- Attempt to get CoreRegistry
local function getCoreRegistry()
    -- Try direct access first
    if _G.CoreRegistry then
        return _G.CoreRegistry
    end
    
    -- Try to require CoreRegistry
    local coreRegistryModule
    
    -- Search in multiple locations
    local searchPaths = {
        ServerScriptService.Core,
        ServerScriptService,
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild("CoreRegistry")
            if module and module:IsA("ModuleScript") then
                coreRegistryModule = module
                break
            end
        end
    end
    
    if coreRegistryModule then
        local success, registry = pcall(function()
            return require(coreRegistryModule)
        end)
        
        if success and registry then
            return registry
        end
    end
    
    -- Try SharedRegistry if available
    local sharedRegistry = ReplicatedStorage:FindFirstChild("SharedRegistry")
    if sharedRegistry and sharedRegistry:FindFirstChild("GetSystem") then
        local success, registry = pcall(function()
            return sharedRegistry.GetSystem:Invoke("CoreRegistry")
        end)
        
        if success and registry then
            return registry
        end
    end
    
    return nil
end

-- Check registry health
local function checkRegistryHealth()
    local registry = getCoreRegistry()
    if not registry then
        log("CoreRegistry UNAVAILABLE")
        return "UNAVAILABLE"
    end
    
    -- Check if registry functions are available
    if type(registry.getStatus) ~= "function" then
        log("CoreRegistry missing getStatus function")
        return "DEGRADED"
    end
    
    -- Get registry status
    local status = registry.getStatus()
    
    -- Check critical systems
    local missingCritical = false
    for _, system in ipairs(CONFIG.criticalSystems) do
        if not registry.hasSystem or not registry.hasSystem(system) then
            missingCritical = true
            log("Critical system missing:", system)
        end
    end
    
    if missingCritical then
        return "DEGRADED"
    end
    
    return status or "UNKNOWN"
end

-- Create status folder
local statusFolder = Instance.new("Folder")
statusFolder.Name = "CoreRegistryStatus"
statusFolder.Parent = ReplicatedStorage

-- Create status value object
local statusValue = Instance.new("StringValue")
statusValue.Name = "Status"
statusValue.Value = "Initializing"
statusValue.Parent = statusFolder

-- Create timestamp
local timestampValue = Instance.new("NumberValue")
timestampValue.Name = "LastChecked"
timestampValue.Value = os.time()
timestampValue.Parent = statusFolder

-- Update status with timestamp
local function updateStatus(status)
    statusValue.Value = status
    timestampValue.Value = os.time()
end

-- Run initial checks
task.delay(CONFIG.initialDelay, function()
    log("Starting CoreRegistry monitoring")
    
    -- Initial status check
    local status = checkRegistryHealth()
    log("Initial status:", status)
    updateStatus(status)
    
    -- Check multiple times if needed
    if status == "UNAVAILABLE" or status == "DEGRADED" then
        for attempt = 1, CONFIG.maxAttempts do
            log("CoreRegistry check failed (" .. attempt .. "/" .. CONFIG.maxAttempts .. ")")
            task.wait(CONFIG.checkDelay)
            
            status = checkRegistryHealth()
            updateStatus(status)
            
            if status ~= "UNAVAILABLE" and status ~= "DEGRADED" then
                log("CoreRegistry now available:", status)
                break
            end
            
            if attempt == CONFIG.maxAttempts then
                warn("CoreRegistry unavailable after " .. CONFIG.maxAttempts .. " attempts")
                
                -- Attempt to create a fallback registry
                task.spawn(function()
                    log("Attempting to create fallback registry")
                    
                    -- Try to fix CoreRegistry
                    local CoreRegistryPath = ServerScriptService:FindFirstChild("Core")
                    if CoreRegistryPath then
                        local existingModule = CoreRegistryPath:FindFirstChild("CoreRegistry")
                        
                        -- Check if it's a ModuleScript
                        if existingModule and not existingModule:IsA("ModuleScript") then
                            log("Removing non-ModuleScript CoreRegistry")
                            existingModule:Destroy()
                            existingModule = nil
                        end
                        
                        if not existingModule then
                            -- Create a new CoreRegistry module
                            local newRegistry = Instance.new("ModuleScript")
                            newRegistry.Name = "CoreRegistry"
                            newRegistry.Source = [[
                                local CoreRegistry = {}
                                CoreRegistry.VERSION = "1.0.0"
                                CoreRegistry.isLoaded = true
                                
                                -- Registry storage
                                local registry = {
                                    systems = {},
                                    status = "Fallback"
                                }
                                
                                -- Register a system
                                function CoreRegistry.registerSystem(name, system)
                                    registry.systems[name] = system
                                    return true
                                end
                                
                                -- Get a system
                                function CoreRegistry.getSystem(name)
                                    return registry.systems[name]
                                end
                                
                                -- Check if a system exists
                                function CoreRegistry.hasSystem(name)
                                    return registry.systems[name] ~= nil
                                end
                                
                                -- Get registry status
                                function CoreRegistry.getStatus()
                                    return registry.status
                                end
                                
                                return CoreRegistry
                            ]]
                            newRegistry.Parent = CoreRegistryPath
                            log("Created fallback CoreRegistry module")
                            
                            -- Check again after creating fallback
                            task.wait(1)
                            status = checkRegistryHealth()
                            updateStatus(status)
                        end
                    end
                end)
            end
        end
    end
    
    -- Start continuous monitoring
    while true do
        task.wait(CONFIG.checkInterval)
        
        status = checkRegistryHealth()
        updateStatus(status)
    end
end)

-- Expose monitoring controls
local monitorControls = {
    checkNow = function()
        local status = checkRegistryHealth()
        updateStatus(status)
        return status
    end,
    
    getStatus = function()
        return statusValue.Value
    end,
    
    getLastChecked = function()
        return timestampValue.Value
    end
}

-- Create a BindableFunction for manual checks
local checkFunction = Instance.new("BindableFunction")
checkFunction.Name = "CheckRegistryHealth"
checkFunction.Parent = statusFolder

-- Connect the function
checkFunction.OnInvoke = monitorControls.checkNow

return monitorControls
