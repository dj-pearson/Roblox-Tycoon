--[[
    SystemBootstrap.server.luau
    
    Initializes all core systems in the correct order to ensure proper dependencies.
    Sets up the server environment with proper dependencies and error handling.
    
    Created as part of the CoreRegistry fix documented in CoreRegistry_Fix_Solution.md
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Look for a module
local function findModule(moduleName)
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Server"),
        ServerScriptService,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Safely require a module
local function safeRequire(moduleInstance, fallback)
    if not moduleInstance then
        return fallback
    end
    
    if not moduleInstance:IsA("ModuleScript") then
        warn("SystemBootstrap: Expected ModuleScript but got " .. moduleInstance.ClassName .. " for " .. moduleInstance:GetFullName())
        return fallback
    end
    
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if success then
        return result
    else
        warn("SystemBootstrap: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

print("SystemBootstrap: Starting server systems initialization")

-- Stage 1: Core Registry and Module Loading
local CoreRegistry, ModuleLoader

-- Load CoreRegistry first (most critical dependency)
local coreRegistryModule = findModule("CoreRegistry")
if coreRegistryModule then
    CoreRegistry = safeRequire(coreRegistryModule)
    
    if CoreRegistry then
        print("SystemBootstrap: CoreRegistry loaded successfully")
        
        -- Initialize if needed
        if typeof(CoreRegistry.initialize) == "function" and not CoreRegistry.isInitialized then
            CoreRegistry.initialize()
        end
    else
        warn("SystemBootstrap[Error] CRITICAL: Required system failed: CoreRegistry")
    end
else
    warn("SystemBootstrap[Error] CRITICAL: CoreRegistry module not found")
end

-- Load ModuleLoader next
local moduleLoaderModule = findModule("ModuleLoader")
if moduleLoaderModule then
    ModuleLoader = safeRequire(moduleLoaderModule)
    
    if ModuleLoader then
        print("SystemBootstrap: ModuleLoader loaded successfully")
        
        -- Register with CoreRegistry
        if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
            CoreRegistry.registerSystem("ModuleLoader", ModuleLoader)
        end
    else
        warn("SystemBootstrap[Error] CRITICAL: Required system failed: ModuleLoader")
    end
else
    warn("SystemBootstrap[Error] CRITICAL: ModuleLoader module not found")
end

-- Stage 2: Data and Path Management
local systems = {
    -- Core infrastructure (highest priority)
    {name = "DataManager", required = true, dependencies = {"CoreRegistry"}},
    {name = "PathRegistration", required = true, dependencies = {"CoreRegistry"}},
    {name = "EventBridge", required = true, dependencies = {"CoreRegistry"}},
    
    -- Game systems (high priority)
    {name = "TycoonManager", required = true, dependencies = {"DataManager"}},
    {name = "EconomySystem", required = true, dependencies = {"DataManager"}},
    {name = "PlayerProgressionSystem", required = true, dependencies = {"DataManager", "TycoonManager"}},
    
    -- Feature systems (medium priority)
    {name = "GymAutomationManager", required = false, dependencies = {"TycoonManager"}},
    {name = "MemberSatisfactionSystem", required = false, dependencies = {"TycoonManager"}},
    {name = "StaffManagementSystem", required = false, dependencies = {"TycoonManager", "EconomySystem"}},
    
    -- Support systems (lowest priority)
    {name = "TutorialManager", required = false, dependencies = {}},
    {name = "AnalyticsManager", required = false, dependencies = {}},
    {name = "LocalizationManager", required = false, dependencies = {}}
}

-- Initialize systems in order
local initializedSystems = {}

for _, systemInfo in ipairs(systems) do
    print("SystemBootstrap: Initializing " .. systemInfo.name)
    
    -- Check dependencies
    local dependenciesMet = true
    for _, dependencyName in ipairs(systemInfo.dependencies) do
        if not initializedSystems[dependencyName] then
            warn("SystemBootstrap[Error] Required dependency failed: " .. dependencyName .. " for system: " .. systemInfo.name)
            dependenciesMet = false
            break
        end
    end
    
    if not dependenciesMet then
        if systemInfo.required then
            warn("SystemBootstrap[Error] Cannot initialize required system: " .. systemInfo.name)
        else
            print("SystemBootstrap: Skipping non-critical system due to missing dependencies: " .. systemInfo.name)
        end
        continue
    end
    
    -- Try to initialize the system
    local systemModule = findModule(systemInfo.name)
    if systemModule then
        local system = safeRequire(systemModule)
        
        if system then
            -- Register with CoreRegistry
            if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
                CoreRegistry.registerSystem(systemInfo.name, system)
            end
            
            -- Call initialize if it exists
            if typeof(system.initialize) == "function" then
                local success, result = pcall(function()
                    return system.initialize()
                end)
                
                if success and result ~= false then
                    print("SystemBootstrap: Successfully initialized " .. systemInfo.name)
                    initializedSystems[systemInfo.name] = system
                    
                    -- Mark as initialized in CoreRegistry
                    if CoreRegistry and typeof(CoreRegistry.markInitialized) == "function" then
                        CoreRegistry.markInitialized(systemInfo.name)
                    end
                else
                    warn("SystemBootstrap[Error] Failed to initialize " .. systemInfo.name .. ": " .. tostring(result))
                    if systemInfo.required then
                        warn("SystemBootstrap[Error] This is a required system and may impact game functionality")
                    end
                end
            else
                -- If no initialize method, consider it initialized
                print("SystemBootstrap: Registered " .. systemInfo.name .. " (no initialization method)")
                initializedSystems[systemInfo.name] = system
                
                -- Mark as initialized in CoreRegistry
                if CoreRegistry and typeof(CoreRegistry.markInitialized) == "function" then
                    CoreRegistry.markInitialized(systemInfo.name)
                end
            end
        else
            warn("SystemBootstrap[Error] Failed to require " .. systemInfo.name)
            if systemInfo.required then
                warn("SystemBootstrap[Error] This is a required system and may impact game functionality")
            end
        end
    else
        warn("SystemBootstrap[Error] Could not find module: " .. systemInfo.name)
        if systemInfo.required then
            warn("SystemBootstrap[Error] This is a required system and may impact game functionality")
        end
    end
end

-- Count successful initializations
local successCount = 0
local requiredSuccessCount = 0
local requiredTotal = 0

for _, systemInfo in ipairs(systems) do
    if initializedSystems[systemInfo.name] then
        successCount += 1
        if systemInfo.required then
            requiredSuccessCount += 1
        end
    end
    
    if systemInfo.required then
        requiredTotal += 1
    end
end

-- Report results
local successRate = math.floor((successCount / #systems) * 100)
local requiredSuccessRate = requiredTotal > 0 and math.floor((requiredSuccessCount / requiredTotal) * 100) or 0

print("SystemBootstrap: Initialization complete")
print("SystemBootstrap: Total systems initialized: " .. successCount .. "/" .. #systems .. " (" .. successRate .. "%)")
print("SystemBootstrap: Required systems initialized: " .. requiredSuccessCount .. "/" .. requiredTotal .. " (" .. requiredSuccessRate .. "%)")

if requiredSuccessRate < 100 then
    warn("SystemBootstrap[Warning] Not all required systems were initialized. Game functionality may be limited.")
else
    print("✅ SystemBootstrap: All required systems initialized successfully")
end
