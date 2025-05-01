--[[
    DiagnosticsAndRepair.server.luau
    
    System for diagnosing and repairing runtime issues in the game.
    This module runs diagnostics on critical systems and attempts to fix issues.
    
    Created: May 1, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Configuration
local Config = {
    AUTO_FIX = true,               -- Whether to automatically fix issues
    DIAGNOSTIC_INTERVAL = 180,     -- Run diagnostics every 3 minutes
    DEBUG_MODE = true,             -- Enable debug logging
    CRITICAL_SYSTEMS = {           -- Systems to check
        "CoreRegistry",
        "TycoonStructure",
        "DataPersistence",
        "BuyTileSystem",
        "UISystem"
    }
}

-- Track state
local State = {
    lastRunTime = 0,
    diagnosticResults = {},
    repairAttempts = {},
    repairHistory = {}
}

-- Debug logging
local function log(message)
    if Config.DEBUG_MODE then
        print("[DiagnosticsAndRepair] " .. message)
    end
end

-- Get SafeRequire module
local function getSafeRequire()
    local safeRequirePaths = {
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("SafeRequire"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild("SafeRequire"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("shared") and ServerScriptService.src.shared:FindFirstChild("SafeRequire")
    }
    
    for _, path in ipairs(safeRequirePaths) do
        if path then
            local success, safeRequire = pcall(function()
                return require(path)
            end)
            
            if success and safeRequire and typeof(safeRequire.requireFromPath) == "function" then
                return safeRequire
            end
        end
    end
    
    return nil
end

-- Get a system
local function getSystem(systemName, safeRequire)
    if safeRequire then
        local system = safeRequire.requireFromPath(systemName)
        if system then
            return system
        end
    end
    
    -- Try to get it from CoreRegistry
    local success, CoreRegistry = pcall(function()
        local safeRequire = getSafeRequire()
        if safeRequire then
            return safeRequire.requireFromPath("CoreRegistry")
        end
        return nil
    end)
    
    if success and CoreRegistry then
        local getSystemFn = CoreRegistry.getSystem or CoreRegistry.GetSystem
        if typeof(getSystemFn) == "function" then
            return getSystemFn(systemName)
        end
    end
    
    return nil
end

-- Diagnostics functions
local Diagnostics = {
    -- Check CoreRegistry
    CoreRegistry = function()
        log("Running CoreRegistry diagnostic")
        
        local safeRequire = getSafeRequire()
        if not safeRequire then
            log("CoreRegistry diagnostic result: ERROR (SafeRequire not found)")
            return "ERROR"
        end
        
        local CoreRegistry = safeRequire.requireFromPath("CoreRegistry")
        if not CoreRegistry then
            log("CoreRegistry diagnostic result: ERROR (CoreRegistry not found)")
            return "ERROR"
        end
        
        -- Check health via Registry's own methods
        if typeof(CoreRegistry.runHealthCheck) == "function" then
            local criticalCount, totalCritical = CoreRegistry.runHealthCheck()
            if criticalCount == 0 then
                log("CoreRegistry diagnostic result: ERROR (no critical systems)")
                return "ERROR"
            elseif criticalCount < totalCritical then
                log("CoreRegistry diagnostic result: WARNING (missing some critical systems)")
                return "WARNING" 
            else
                log("CoreRegistry diagnostic result: OK")
                return "OK"
            end
        end
        
        -- Fallback check
        if typeof(CoreRegistry.getStatus) == "function" then
            local status = CoreRegistry.getStatus()
            if status == "Error" then
                log("CoreRegistry diagnostic result: ERROR")
                return "ERROR"
            elseif status == "Degraded" then
                log("CoreRegistry diagnostic result: WARNING")
                return "WARNING"
            else
                log("CoreRegistry diagnostic result: OK")
                return "OK"
            end
        end
        
        log("CoreRegistry diagnostic result: WARNING (could not determine status)")
        return "WARNING"
    end,
    
    -- Check TycoonStructure
    TycoonStructure = function()
        log("Running TycoonStructure diagnostic")
        
        -- First check if required folders exist
        local workspace = game:GetService("Workspace")
        local tycoonFolder = workspace:FindFirstChild("Tycoons")
        
        if not tycoonFolder then
            log("TycoonStructure diagnostic result: ERROR (Tycoons folder missing)")
            return "ERROR"
        end
        
        -- Check if all player tycoons exist
        local missingTycoons = 0
        for _, player in pairs(game.Players:GetPlayers()) do
            local tycoon = player:FindFirstChild("Tycoon")
            if not tycoon or not tycoon.Value then
                missingTycoons = missingTycoons + 1
            end
        end
        
        if missingTycoons > 0 then
            log("TycoonStructure diagnostic result: WARNING (" .. missingTycoons .. " missing tycoons)")
            return "WARNING"
        end
        
        -- Check ServerStorage for templates
        local serverStorage = game:GetService("ServerStorage")
        local templatesFolder = serverStorage:FindFirstChild("TycoonTemplates")
        
        if not templatesFolder then
            log("TycoonStructure diagnostic result: WARNING (TycoonTemplates folder missing)")
            return "WARNING"
        end
        
        log("TycoonStructure diagnostic result: OK")
        return "OK"
    end,
      -- Check DataPersistence
    DataPersistence = function()
        log("Running DataPersistence diagnostic")
        
        -- Try to load DataManager first
        local safeRequire = getSafeRequire()
        local DataManager = getSystem("DataManager", safeRequire)
        
        -- If not found, try DataPersistenceManager
        if not DataManager then
            DataManager = getSystem("DataPersistenceManager", safeRequire)
        end
        
        if not DataManager then
            log("DataPersistence diagnostic result: ERROR (DataManager not found)")
            return "ERROR"
        end
        
        -- Check if DataManager is initialized
        if not DataManager.initialized then
            log("DataPersistence diagnostic result: ERROR (DataManager not initialized)")
            return "ERROR"
        end
        
        -- Check if DataManager has save functionality
        if typeof(DataManager.saveData) ~= "function" then
            log("DataPersistence diagnostic result: WARNING (saveData function missing)")
            return "WARNING"
        end
        
        -- Check if DataManager has load functionality
        if typeof(DataManager.loadData) ~= "function" then
            log("DataPersistence diagnostic result: WARNING (loadData function missing)")
            return "WARNING"
        end
        
        log("DataPersistence diagnostic result: OK")
        return "OK"
    end,
    
    -- Check BuyTileSystem
    BuyTileSystem = function()
        log("Running BuyTileSystem diagnostic")
        
        -- Try to load BuyTileSystem
        local safeRequire = getSafeRequire()
        local BuyTileSystem = getSystem("BuyTileSystem", safeRequire)
        
        if not BuyTileSystem then
            log("BuyTileSystem diagnostic result: ERROR (BuyTileSystem not found)")
            return "ERROR"
        end
        
        -- Check if BuyTileSystem is initialized
        if not BuyTileSystem.initialized then
            log("BuyTileSystem diagnostic result: WARNING (BuyTileSystem not initialized)")
            return "WARNING"
        end
        
        -- Check if BuyTileSystem has spawnGymPart functionality
        if typeof(BuyTileSystem.spawnGymPart) ~= "function" then
            log("BuyTileSystem diagnostic result: WARNING (spawnGymPart function missing)")
            return "WARNING"
        end
        
        -- Check if position fix is applied
        if not BuyTileSystem._positionFixApplied then
            log("BuyTileSystem diagnostic result: WARNING (position fix not applied)")
            return "WARNING"
        end
        
        log("BuyTileSystem diagnostic result: OK")
        return "OK"
    end,
    
    -- Check UISystem
    UISystem = function()
        log("Running UISystem diagnostic")
        
        -- Check for UIComponents in ReplicatedStorage
        local shared = ReplicatedStorage:FindFirstChild("shared")
        if not shared or not shared:FindFirstChild("UIComponents") then
            log("UISystem diagnostic result: ERROR (UIComponents module missing)")
            return "ERROR"
        end
        
        -- Check for UIRegistry
        if not shared:FindFirstChild("UIRegistry") then
            log("UISystem diagnostic result: WARNING (UIRegistry module missing)")
            return "WARNING"
        end
        
        -- Try to load UIComponents
        local safeRequire = getSafeRequire()
        local UIComponents = getSystem("UIComponents", safeRequire)
        
        if not UIComponents then
            log("UISystem diagnostic result: ERROR (UIComponents not loadable)")
            return "ERROR"
        end
        
        -- Check basic UI creation functions
        if typeof(UIComponents.CreateButton) ~= "function" then
            log("UISystem diagnostic result: WARNING (CreateButton function missing)")
            return "WARNING"
        end
        
        log("UISystem diagnostic result: OK")
        return "OK"
    end
}

-- Repair functions
local Repairs = {
    -- Fix CoreRegistry
    CoreRegistry = function()
        log("Attempting to repair CoreRegistry")
        
        -- Try to load CoreRegistryFeedback which has repair functionality
        local success = pcall(function()
            local script = ServerScriptService:FindFirstChild("Core"):FindFirstChild("CoreRegistryFeedback")
            if script then
                require(script)
                log("Triggered CoreRegistryFeedback repair mechanism")
                return true
            end
            return false
        end)
        
        if success then
            log("CoreRegistry repair initiated")
            return true
        end
        
        -- Fallback: try to manually register critical systems
        local safeRequire = getSafeRequire()
        if not safeRequire then
            log("Failed to repair CoreRegistry (SafeRequire not found)")
            return false
        end
        
        local CoreRegistry = safeRequire.requireFromPath("CoreRegistry")
        if not CoreRegistry then
            log("Failed to repair CoreRegistry (CoreRegistry not found)")
            return false
        end
        
        -- Try to register critical systems
        local criticalSystems = {
            "ModuleLoader",
            "DataManager",
            "UIComponents",
            "AssetValidator",
            "BuyTileSystem",
            "TycoonSystem",
            "EventBridge"
        }
        
        local registeredCount = 0
        for _, systemName in ipairs(criticalSystems) do
            local system = safeRequire.requireFromPath(systemName)
            if system then
                local registered = false
                
                if typeof(CoreRegistry.registerSystem) == "function" then
                    registered = CoreRegistry.registerSystem(systemName, system)
                elseif typeof(CoreRegistry.Register) == "function" then
                    registered = CoreRegistry:Register(systemName, system)
                end
                
                if registered then
                    registeredCount = registeredCount + 1
                    log("Registered " .. systemName .. " with CoreRegistry")
                end
            end
        end
        
        log("CoreRegistry repair completed, registered " .. registeredCount .. " systems")
        return registeredCount > 0
    end,
    
    -- Fix TycoonStructure
    TycoonStructure = function()
        log("Attempting to repair TycoonStructure")
        
        -- Create Tycoons folder if missing
        local workspace = game:GetService("Workspace")
        local tycoonFolder = workspace:FindFirstChild("Tycoons")
        
        if not tycoonFolder then
            tycoonFolder = Instance.new("Folder")
            tycoonFolder.Name = "Tycoons"
            tycoonFolder.Parent = workspace
            log("Created Tycoons folder")
        end
        
        -- Check ServerStorage for templates
        local serverStorage = game:GetService("ServerStorage")
        local templatesFolder = serverStorage:FindFirstChild("TycoonTemplates")
        
        if not templatesFolder then
            templatesFolder = Instance.new("Folder")
            templatesFolder.Name = "TycoonTemplates"
            templatesFolder.Parent = serverStorage
            log("Created TycoonTemplates folder")
            
            -- Add a basic empty template
            local basicTemplate = Instance.new("Model")
            basicTemplate.Name = "BasicTycoon"
            basicTemplate.Parent = templatesFolder
            
            -- Add base part
            local basePart = Instance.new("Part")
            basePart.Name = "Base"
            basePart.Size = Vector3.new(50, 1, 50)
            basePart.Anchored = true
            basePart.TopSurface = Enum.SurfaceType.Smooth
            basePart.BottomSurface = Enum.SurfaceType.Smooth
            basePart.Parent = basicTemplate
            
            log("Created basic tycoon template")
        end
        
        -- Try to fix missing player tycoons
        local TycoonSystem = getSystem("TycoonSystem", getSafeRequire())
        if TycoonSystem and typeof(TycoonSystem.setupPlayerTycoon) == "function" then
            for _, player in pairs(game.Players:GetPlayers()) do
                local tycoon = player:FindFirstChild("Tycoon")
                if not tycoon or not tycoon.Value then
                    task.spawn(function()
                        local success = pcall(function()
                            TycoonSystem:setupPlayerTycoon(player)
                        end)
                        
                        if success then
                            log("Fixed tycoon for player: " .. player.Name)
                        end
                    end)
                end
            end
            
            log("TycoonStructure repair: attempted to fix player tycoons")
            return true
        end
        
        log("TycoonStructure partial repair: created folders but couldn't fix player tycoons")
        return true
    end,
    
    -- Fix DataPersistence
    DataPersistence = function()
        log("Attempting to repair DataPersistence")
        
        -- Try to load DataManager
        local DataManager = getSystem("DataManager", getSafeRequire())
        
        -- If not found, try DataPersistenceManager
        if not DataManager then
            DataManager = getSystem("DataPersistenceManager", getSafeRequire())
        }
        
        if not DataManager then
            -- Try to find it directly and register with CoreRegistry
            local safeRequire = getSafeRequire()
            local success, module = pcall(function()
                return safeRequire(ServerScriptService.Core.DataPersistenceManager)
            end)
            
            if success and module then
                DataManager = module
                log("Found DataPersistenceManager module, registering with CoreRegistry")
                local CoreRegistry = getSystem("CoreRegistry")
                if CoreRegistry then
                    CoreRegistry:registerSystem("DataPersistenceManager", DataManager)
                    CoreRegistry:registerSystem("DataManager", DataManager) -- For backward compatibility
                    log("DataPersistence repair: registered DataManager with CoreRegistry")
                end
            else
                log("DataPersistence repair: DataManager not found, cannot repair")
                return false
            end
        end
        
        -- Attempt to reinitialize
        if typeof(DataManager.initialize) == "function" and not DataManager.initialized then
            local success = pcall(function()
                DataManager.initialize()
            end)
            
            if success then
                log("DataPersistence repair: reinitialized DataManager")
                return true
            end
        end
        
        -- Try to register with CoreRegistry
        local safeRequire = getSafeRequire()
        if safeRequire then
            local CoreRegistry = safeRequire.requireFromPath("CoreRegistry")
            if CoreRegistry then
                local registered = false
                
                if typeof(CoreRegistry.registerSystem) == "function" then
                    registered = CoreRegistry.registerSystem("DataManager", DataManager)
                elseif typeof(CoreRegistry.Register) == "function" then
                    registered = CoreRegistry:Register("DataManager", DataManager)
                end
                
                if registered then
                    log("DataPersistence repair: registered DataManager with CoreRegistry")
                    return true
                end
            end
        end
        
        log("DataPersistence repair: partial success")
        return true
    end,
    
    -- Fix BuyTileSystem
    BuyTileSystem = function()
        log("Attempting to repair BuyTileSystem")
        
        -- Try to load BuyTileSystem
        local BuyTileSystem = getSystem("BuyTileSystem", getSafeRequire())
        
        if not BuyTileSystem then
            log("BuyTileSystem repair: BuyTileSystem not found, cannot repair")
            return false
        end
        
        -- Apply position fix if not already applied
        if not BuyTileSystem._positionFixApplied then
            -- Try to load BuyTilePositionFixer
            local success = pcall(function()
                local script = ServerScriptService:FindFirstChild("BuyTilePositionFixer")
                if script then
                    require(script)
                    log("Triggered BuyTilePositionFixer")
                    BuyTileSystem._positionFixApplied = true
                    return true
                end
                return false
            end)
            
            if success then
                log("BuyTileSystem repair: applied position fix")
            end
        end
        
        -- Try to register with CoreRegistry
        local safeRequire = getSafeRequire()
        if safeRequire then
            local CoreRegistry = safeRequire.requireFromPath("CoreRegistry")
            if CoreRegistry then
                local registered = false
                
                if typeof(CoreRegistry.registerSystem) == "function" then
                    registered = CoreRegistry.registerSystem("BuyTileSystem", BuyTileSystem)
                elseif typeof(CoreRegistry.Register) == "function" then
                    registered = CoreRegistry:Register("BuyTileSystem", BuyTileSystem)
                end
                
                if registered then
                    log("BuyTileSystem repair: registered with CoreRegistry")
                    return true
                end
            end
        end
        
        log("BuyTileSystem repair: partial success")
        return true
    end,
    
    -- Fix UISystem
    UISystem = function()
        log("Attempting to repair UISystem")
        
        -- Check if UIComponents exists in shared
        local shared = ReplicatedStorage:FindFirstChild("shared")
        if not shared then
            shared = Instance.new("Folder")
            shared.Name = "shared"
            shared.Parent = ReplicatedStorage
            log("Created shared folder in ReplicatedStorage")
        end
        
        -- Check if UIComponents exists
        if not shared:FindFirstChild("UIComponents") then
            log("UISystem repair: UIComponents module not found, cannot repair")
            return false
        end
        
        -- Try to register with CoreRegistry
        local safeRequire = getSafeRequire()
        if safeRequire then
            local UIComponents = safeRequire.requireFromPath("UIComponents")
            if UIComponents then
                local CoreRegistry = safeRequire.requireFromPath("CoreRegistry")
                if CoreRegistry then
                    local registered = false
                    
                    if typeof(CoreRegistry.registerSystem) == "function" then
                        registered = CoreRegistry.registerSystem("UIComponents", UIComponents)
                    elseif typeof(CoreRegistry.Register) == "function" then
                        registered = CoreRegistry:Register("UIComponents", UIComponents)
                    end
                    
                    if registered then
                        log("UISystem repair: registered UIComponents with CoreRegistry")
                        return true
                    end
                end
            end
        end
        
        -- Trigger DarkOverlayFix if available
        pcall(function()
            for _, player in pairs(game.Players:GetPlayers()) do
                local playerScripts = player:FindFirstChild("PlayerScripts")
                if playerScripts then
                    local darkOverlayFix = playerScripts:FindFirstChild("DarkOverlayFix")
                    if darkOverlayFix then
                        -- The script should be running automatically, but we'll trigger it
                        log("UISystem repair: found DarkOverlayFix script, it should be running")
                    end
                end
            end
        end)
        
        log("UISystem repair: partial success")
        return true
    end
}

-- Run diagnostics on all systems
local function runDiagnostics()
    log("Running diagnostics on all systems")
    
    local results = {}
    local anyErrors = false
    local anyWarnings = false
    
    for _, systemName in ipairs(Config.CRITICAL_SYSTEMS) do
        local diagnosticFn = Diagnostics[systemName]
        if diagnosticFn then
            local result = diagnosticFn()
            results[systemName] = result
            
            if result == "ERROR" then
                anyErrors = true
            elseif result == "WARNING" then
                anyWarnings = true
            end
        else
            log("No diagnostic function for " .. systemName)
            results[systemName] = "UNKNOWN"
        end
    end
    
    -- Update state
    State.lastRunTime = os.time()
    State.diagnosticResults = results
    
    -- Return overall status
    if anyErrors then
        return "ERROR", results
    elseif anyWarnings then
        return "WARNING", results
    else
        return "OK", results
    end
end

-- Try to repair systems with issues
local function repairSystems(results)
    if not Config.AUTO_FIX then
        log("Auto-fix is disabled, not attempting repairs")
        return false
    end
    
    log("Auto-fix is enabled, attempting to repair issues")
    
    local repairsAttempted = {}
    local repairsSucceeded = {}
    
    for systemName, result in pairs(results) do
        if result == "ERROR" or result == "WARNING" then
            local repairFn = Repairs[systemName]
            if repairFn then
                log(systemName .. " diagnostic result: " .. result)
                repairsAttempted[systemName] = true
                
                local success = repairFn()
                repairsSucceeded[systemName] = success
                
                if success then
                    log("Successfully repaired " .. systemName)
                else
                    log("Failed to repair " .. systemName)
                end
            else
                log("No repair function for " .. systemName)
            end
        end
    end
    
    -- Update state
    State.repairAttempts = repairsAttempted
    
    -- Add to repair history
    table.insert(State.repairHistory, {
        timestamp = os.time(),
        attempted = repairsAttempted,
        succeeded = repairsSucceeded
    })
    
    return true
end

-- Run diagnostics again after repairs
local function rerunDiagnostics()
    log("Re-running diagnostics after repairs")
    local status, results = runDiagnostics()
    
    -- Log results
    for systemName, result in pairs(results) do
        log(systemName .. " diagnostic result after repair: " .. result)
    end
    
    return status, results
end

-- Main execution function
local function runDiagnosticsAndRepair()
    -- Run initial diagnostics
    local status, results = runDiagnostics()
    
    -- If there are issues, try to repair them
    if status ~= "OK" then
        local repairsApplied = repairSystems(results)
        
        if repairsApplied then
            -- Wait a moment for repairs to take effect
            task.wait(1)
            
            -- Run diagnostics again
            rerunDiagnostics()
        end
    else
        log("All systems OK, no repairs needed")
    end
end

-- Initialize the system
local function initialize()
    log("Initializing DiagnosticsAndRepair system...")
    
    -- Run diagnostics and repair once on startup
    task.delay(5, function()
        runDiagnosticsAndRepair()
    end)
    
    -- Set up periodic diagnostics
    task.spawn(function()
        while true do
            task.wait(Config.DIAGNOSTIC_INTERVAL)
            runDiagnosticsAndRepair()
        end
    end)
    
    log("DiagnosticsAndRepair system initialized")
    return true
end

-- Initialize the system
initialize()

-- Return the module
return {
    runDiagnostics = runDiagnostics,
    repairSystems = repairSystems,
    getState = function() return State end,
    getConfig = function() return Config end,
    setConfig = function(newConfig)
        for key, value in pairs(newConfig) do
            Config[key] = value
        end
    end
}
