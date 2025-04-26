--!strict
--[[
    SystemDiagnostics.server.luau
    
    A diagnostic tool for checking system health and fixing common issues.
    Useful for troubleshooting CoreRegistry, ModuleLoader, and other critical systems.
    
    Created: April 26, 2025
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Debug settings
local DEBUG_ENABLED = true

-- Print debug messages
local function log(message)
    if DEBUG_ENABLED then
        print("[SystemDiagnostics] " .. message)
    end
end

-- Find a module script in common locations
local function findModuleInCommonLocations(moduleName)
    local commonLocations = {
        ServerScriptService:FindFirstChild("Core") and 
            ServerScriptService.Core:FindFirstChild(moduleName),
        
        ReplicatedStorage:FindFirstChild("shared") and 
            ReplicatedStorage.shared:FindFirstChild(moduleName),
        
        ServerScriptService:FindFirstChild("src") and 
            ServerScriptService.src:FindFirstChild("server") and 
            ServerScriptService.src.server:FindFirstChild("Core") and 
            ServerScriptService.src.server.Core:FindFirstChild(moduleName),
        
        ReplicatedStorage:FindFirstChild("src") and 
            ReplicatedStorage.src:FindFirstChild("shared") and 
            ReplicatedStorage.src.shared:FindFirstChild(moduleName)
    }
    
    for _, location in ipairs(commonLocations) do
        if location and location:IsA("ModuleScript") then
            return location
        end
    end
    
    return nil
end

-- Safely require a module
local function safeRequire(moduleScript)
    if not moduleScript then
        return nil, "Module is nil"
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        return nil, tostring(result)
    end
    
    return result, nil
end

-- Main diagnostics module
local SystemDiagnostics = {
    testResults = {},
    fixesApplied = {}
}

-- Run a single test
function SystemDiagnostics:RunTest(testName, testFunction)
    log("Running test: " .. testName)
    
    local startTime = os.clock()
    local success, result = pcall(testFunction)
    local endTime = os.clock()
    
    local testResult = {
        name = testName,
        success = success,
        result = result,
        error = not success and tostring(result) or nil,
        duration = endTime - startTime
    }
    
    self.testResults[testName] = testResult
    
    if success then
        log("✓ Test passed: " .. testName)
    else
        log("✗ Test failed: " .. testName .. " - " .. tostring(result))
    end
    
    return success, result
end

-- Test if CoreRegistry is available
function SystemDiagnostics:TestCoreRegistry()
    -- Try multiple methods to find CoreRegistry
    local methods = {
        function()
            if _G and _G.CoreRegistry then
                return _G.CoreRegistry
            end
            return nil, "Not found in _G"
        end,
        
        function()
            if shared and shared.CoreRegistry then
                return shared.CoreRegistry
            end
            return nil, "Not found in shared"
        end,
        
        function()
            local coreRegistryScript = findModuleInCommonLocations("CoreRegistry")
            if coreRegistryScript then
                return safeRequire(coreRegistryScript)
            end
            return nil, "Script not found in common locations"
        end,
        
        function()
            local CoreRegistryAccess = findModuleInCommonLocations("CoreRegistryAccess")
            if CoreRegistryAccess then
                local access, error = safeRequire(CoreRegistryAccess)
                if access and access.GetRegistry then
                    return access:GetRegistry()
                end
            end
            return nil, "Not found through CoreRegistryAccess"
        end
    }
    
    -- Try each method
    local registry = nil
    local errors = {}
    
    for i, method in ipairs(methods) do
        local success, result = pcall(function()
            return method()
        end)
        
        if success and result then
            registry = result
            break
        else
            table.insert(errors, "Method " .. i .. ": " .. tostring(result))
        end
    end
    
    if not registry then
        return false, "CoreRegistry not found using any method. Errors: " .. table.concat(errors, ", ")
    end
    
    -- Verify it's a proper CoreRegistry
    if not registry.registerSystem or not registry.getSystem then
        return false, "Found object is not a valid CoreRegistry (missing key methods)"
    end
    
    return true, registry
end

-- Test if ModuleLoader is available
function SystemDiagnostics:TestModuleLoader()
    local moduleLoaderScript = findModuleInCommonLocations("ModuleLoader")
    if not moduleLoaderScript then
        return false, "ModuleLoader script not found"
    end
    
    local moduleLoader, error = safeRequire(moduleLoaderScript)
    if not moduleLoader then
        return false, "Failed to require ModuleLoader: " .. error
    end
    
    if not moduleLoader.tryRequire and not moduleLoader.LoadServerModule then
        return false, "Invalid ModuleLoader (missing key methods)"
    end
    
    return true, moduleLoader
end

-- Test if EventBridge is available and working
function SystemDiagnostics:TestEventBridge()
    local success, registry = self:TestCoreRegistry()
    if not success then
        return false, "Cannot test EventBridge - CoreRegistry not available"
    end
    
    local eventBridge = registry.getSystem("EventBridge")
    if not eventBridge then
        return false, "EventBridge not found in CoreRegistry"
    end
    
    -- Test creating an event and firing it
    if not eventBridge.getOrCreateEvent or not eventBridge.fireEvent or not eventBridge.connectEvent then
        return false, "EventBridge is missing required methods"
    end
    
    -- Create a test event
    local eventFired = false
    eventBridge:connectEvent("DiagnosticTestEvent", function()
        eventFired = true
    end)
    
    eventBridge:fireEvent("DiagnosticTestEvent")
    
    -- Check if event was fired
    if not eventFired then
        return false, "EventBridge event system not working properly"
    end
    
    return true, eventBridge
end

-- Test if folder structure is correct
function SystemDiagnostics:TestFolderStructure()
    local requiredFolders = {
        ServerScriptService:FindFirstChild("Core"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("Events")
    }
    
    local missingFolders = {}
    
    for i, folder in ipairs(requiredFolders) do
        if not folder then
            table.insert(missingFolders, {"ServerScriptService.Core", "ReplicatedStorage.shared", "ReplicatedStorage.Events"}[i])
        end
    end
    
    if #missingFolders > 0 then
        return false, "Missing critical folders: " .. table.concat(missingFolders, ", ")
    end
    
    return true, "All critical folders exist"
end

-- Fix missing CoreRegistry
function SystemDiagnostics:FixCoreRegistry()
    log("Attempting to fix CoreRegistry...")
    
    -- Check if CoreRegistryInitializer exists and run it if it does
    local initializerScript = findModuleInCommonLocations("CoreRegistryInitializer")
    if initializerScript then
        log("Found CoreRegistryInitializer, attempting to run it")
        
        local initializer, error = safeRequire(initializerScript)
        if initializer then
            log("CoreRegistryInitializer loaded successfully")
            self.fixesApplied["CoreRegistry"] = "Used existing CoreRegistryInitializer"
            
            -- Test again
            local success, _ = self:TestCoreRegistry()
            return success, success and "CoreRegistry fixed successfully" or "CoreRegistry still not working properly"
        else
            log("Failed to load CoreRegistryInitializer: " .. error)
        end
    end
    
    -- Create a minimal CoreRegistry if needed
    log("Creating minimal CoreRegistry")
    
    -- Ensure Core folder exists
    local core = ServerScriptService:FindFirstChild("Core")
    if not core then
        core = Instance.new("Folder")
        core.Name = "Core"
        core.Parent = ServerScriptService
        log("Created missing Core folder")
    end
    
    -- Create minimal CoreRegistry
    local minimalRegistry = Instance.new("ModuleScript")
    minimalRegistry.Name = "CoreRegistry"
    minimalRegistry.Source = [[
-- Minimal CoreRegistry implementation
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the registry table
local CoreRegistry = {
    systems = {},     -- Systems that have been registered
    initialized = {}, -- Systems that have been initialized
    loading = {}      -- Systems currently being initialized (to detect circular dependencies)
}

-- Debug function
local function log(...)
    print("[CoreRegistry]", ...)
end

-- Register a system with the registry
function CoreRegistry.registerSystem(name, system, dependencies)
    if CoreRegistry.systems[name] then
        log("Warning: System '" .. name .. "' already registered, overwriting")
    end
    
    CoreRegistry.systems[name] = {
        module = system,
        dependencies = dependencies or {}
    }
    
    log("Registered system: " .. name)
    return system
end

-- Get a system and ensure it's initialized
function CoreRegistry.getSystem(name)
    -- Return already initialized system
    if CoreRegistry.initialized[name] then
        return CoreRegistry.initialized[name]
    end
    
    -- Check if system exists
    if not CoreRegistry.systems[name] then
        log("System not found: " .. name)
        return nil
    end
    
    -- Detect circular dependencies
    if CoreRegistry.loading[name] then
        log("Error: Circular dependency detected for system: " .. name)
        return nil
    end
    
    -- Mark as loading
    CoreRegistry.loading[name] = true
    
    -- Initialize the system
    local system = CoreRegistry.systems[name].module
    if type(system.initialize) == "function" then
        log("Initializing system: " .. name)
        local success, errorMsg = pcall(function()
            system:initialize()
        end)
        
        if not success then
            log("Error initializing system '" .. name .. "': " .. tostring(errorMsg))
        end
    end
    
    -- Mark as initialized and no longer loading
    CoreRegistry.initialized[name] = system
    CoreRegistry.loading[name] = nil
    
    return system
end

-- Create a basic EventBridge system
local EventBridge = {
    events = {},
    remoteEvents = {},
    
    initialize = function()
        log("EventBridge initialized")
        return true
    end,
    
    getOrCreateEvent = function(self, eventName)
        if not self.events[eventName] then
            self.events[eventName] = {
                callbacks = {}
            }
        end
        return self.events[eventName]
    end,
    
    fireEvent = function(self, eventName, ...)
        local event = self.events[eventName]
        if event then
            for _, callback in ipairs(event.callbacks) do
                task.spawn(function()
                    callback(...)
                end)
            end
        end
    end,
    
    connectEvent = function(self, eventName, callback)
        local event = self:getOrCreateEvent(eventName)
        table.insert(event.callbacks, callback)
    end
}

-- Register core EventBridge system
CoreRegistry.registerSystem("EventBridge", EventBridge, {})

-- Store in shared table for access from anywhere
if shared then
    shared.CoreRegistry = CoreRegistry
end

return CoreRegistry
]]
    minimalRegistry.Parent = core
    
    -- Try to require it
    local registry, error = safeRequire(minimalRegistry)
    if not registry then
        log("Failed to load minimal CoreRegistry: " .. error)
        return false, "Failed to create minimal CoreRegistry: " .. error
    end
    
    -- Store in global scope for emergency access
    shared.CoreRegistry = registry
    
    log("Created minimal CoreRegistry successfully")
    self.fixesApplied["CoreRegistry"] = "Created minimal CoreRegistry"
    
    -- Test again
    local success, _ = self:TestCoreRegistry()
    return success, success and "CoreRegistry fixed successfully" or "CoreRegistry still not working properly"
end

-- Run all diagnostic tests
function SystemDiagnostics:RunAllTests()
    log("Starting system diagnostics...")
    self.testResults = {}
    self.fixesApplied = {}
    
    self:RunTest("FolderStructure", function() return self:TestFolderStructure() end)
    self:RunTest("CoreRegistry", function() return self:TestCoreRegistry() end)
    self:RunTest("ModuleLoader", function() return self:TestModuleLoader() end)
    self:RunTest("EventBridge", function() return self:TestEventBridge() end)
    
    -- Generate report
    local report = {
        testsRun = 0,
        passed = 0,
        failed = 0,
        fixes = self.fixesApplied,
        details = {}
    }
    
    for name, result in pairs(self.testResults) do
        report.testsRun = report.testsRun + 1
        if result.success then
            report.passed = report.passed + 1
        else
            report.failed = report.failed + 1
        end
        
        report.details[name] = {
            success = result.success,
            error = result.error,
            duration = result.duration
        }
    end
    
    return report
end

-- Auto-fix issues
function SystemDiagnostics:AutoFixIssues()
    log("Auto-fixing system issues...")
    
    -- Run tests first
    self:RunAllTests()
    
    -- Fix issues based on test results
    if self.testResults.CoreRegistry and not self.testResults.CoreRegistry.success then
        self:FixCoreRegistry()
    end
    
    -- Run tests again after fixes
    return self:RunAllTests()
end

-- Run diagnostics once on module load
task.spawn(function()
    log("Running initial diagnostics...")
    wait(1) -- Allow some time for scripts to load
    
    local report = SystemDiagnostics:RunAllTests()
    log("Initial diagnostics complete. Passed: " .. report.passed .. "/" .. report.testsRun)
end)

return SystemDiagnostics
