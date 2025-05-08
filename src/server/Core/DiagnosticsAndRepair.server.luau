--[[
    DiagnosticsAndRepair.server.luau
    
    This script provides diagnostic capabilities and repair functions for remaining issues
    after primary fixes have been applied. It's useful for monitoring and resolving any
    lingering problems with the core systems.
    
    Created to follow up on fixes for issues identified in RobloxIssues.txt
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Module cache reference
local packageCache = _G.packageCache or {}
if not _G.packageCache then
    _G.packageCache = packageCache
end

-- Configuration
local CONFIG = {
    debug = true,
    diagnosticInterval = 60,  -- Run diagnostics every 60 seconds
    diagnosticCategories = {
        "TycoonStructure",
        "CoreRegistry",
        "DataPersistence",
        "BuyTileSystem",
        "FolderStructure"
    },
    autofixEnabled = true     -- Automatically attempt to fix issues
}

-- Results storage
local diagResults = {}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[DiagnosticsAndRepair]", ...)
    end
end

-- Diagnostic functions for each category
local diagnostics = {
    TycoonStructure = function()
        local results = {
            status = "OK",
            issues = {},
            playerResults = {}
        }
        
        -- Check each player's Tycoon structure
        for _, player in ipairs(Players:GetPlayers()) do
            local playerResult = {
                name = player.Name,
                issues = {}
            }
            
            -- Check if Tycoon exists
            local tycoon = player:FindFirstChild("Tycoon")
            if not tycoon then
                table.insert(playerResult.issues, "Missing Tycoon value")
                results.status = "ERROR"
            elseif not tycoon:IsA("ObjectValue") then
                table.insert(playerResult.issues, "Tycoon is " .. tycoon.ClassName .. " instead of ObjectValue")
                results.status = "ERROR"
            elseif not tycoon.Value then
                table.insert(playerResult.issues, "Tycoon ObjectValue has nil value")
                results.status = "WARNING"
            end
            
            -- Check required attributes
            local requiredAttributes = {"EquipmentCount", "GymTier", "MemberCount"}
            for _, attr in ipairs(requiredAttributes) do
                if tycoon and tycoon:GetAttribute(attr) == nil then
                    table.insert(playerResult.issues, "Missing attribute: " .. attr)
                    results.status = "WARNING"
                end
            end
            
            if #playerResult.issues > 0 then
                table.insert(results.playerResults, playerResult)
            end
        end
        
        return results
    end,
    
    CoreRegistry = function()
        local results = {
            status = "OK",
            issues = {}
        }
        
        -- Check CoreRegistry availability
        local coreRegistry
        local registrySearchPaths = {
            ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
            ServerScriptService:FindFirstChild("CoreRegistry")
        }
        
        for _, path in ipairs(registrySearchPaths) do
            if path and path:IsA("ModuleScript") then
                local success, registry = pcall(function()
                    return require(path)
                end)
                
                if success and registry then
                    coreRegistry = registry
                    break
                end
            end
        end
        
        if not coreRegistry then
            table.insert(results.issues, "CoreRegistry module not found or failed to load")
            results.status = "ERROR"
            return results
        end
        
        -- Check required functions
        local requiredFunctions = {"registerSystem", "getSystem", "hasSystem"}
        for _, funcName in ipairs(requiredFunctions) do
            if type(coreRegistry[funcName]) ~= "function" then
                table.insert(results.issues, "CoreRegistry missing " .. funcName .. " function")
                results.status = "ERROR"
            end
        end
        
        -- Check registry status if available
        if type(coreRegistry.getStatus) == "function" then
            local status = coreRegistry.getStatus()
            if status ~= "OK" and status ~= "READY" then
                table.insert(results.issues, "CoreRegistry status is " .. tostring(status))
                results.status = "WARNING"
            end
        end
        
        -- Check critical systems
        local criticalSystems = {"DataManager", "TycoonSystem", "UIManager"}
        for _, system in ipairs(criticalSystems) do
            if coreRegistry.hasSystem and not coreRegistry.hasSystem(system) then
                table.insert(results.issues, "CoreRegistry missing critical system: " .. system)
                results.status = "WARNING"
            end
        end
        
        return results
    end,
      DataPersistence = function()
        local results = {
            status = "OK",
            issues = {}
        }
        
        -- Try to find DataSystemIntegration first (preferred)
        local dataSystemIntegration
        pcall(function()
            dataSystemIntegration = require(ServerScriptService.Data.DataSystemIntegration)
        end)
        
        if dataSystemIntegration then
            -- Run diagnostics if available
            if dataSystemIntegration.runDiagnostics then
                local diagnostics = dataSystemIntegration.runDiagnostics()
                
                -- Check if critical components are missing
                if not diagnostics.dataPersistenceManager and not diagnostics.dataManager then
                    table.insert(results.issues, "Both DataPersistenceManager and DataManager are missing")
                    results.status = "ERROR"
                elseif not diagnostics.dataPersistenceManager then
                    table.insert(results.issues, "DataPersistenceManager is missing")
                    results.status = "WARNING"
                end
                
                -- Check CoreRegistry registration
                if not diagnostics.coreRegistryAvailable then
                    table.insert(results.issues, "CoreRegistry not available for DataSystem")
                    results.status = "WARNING"
                end
                
                -- If any backup systems are missing
                if not diagnostics.dataBackup or not diagnostics.versionedDataStore then
                    table.insert(results.issues, "Data backup systems incomplete")
                    results.status = results.status == "ERROR" and "ERROR" or "WARNING"
                end
                
                log("DataSystemIntegration diagnostics completed with status: " .. results.status)
                return results
            end
        end
        
        -- If DataSystemIntegration not found or diagnostics unavailable, fall back to manual checks
        
        -- Look for data manager modules
        local dataManager
        local dataPersistenceManager
        local dataManagerSearchPaths = {
            ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("DataPersistenceManager"),
            ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("DataManager"),
            ServerScriptService:FindFirstChild("DataPersistenceManager"),
            ServerScriptService:FindFirstChild("DataManager"),
            ServerScriptService:FindFirstChild("GymTycoonDataManager")
        }
        
        -- Try to find DataPersistenceManager first
        for _, path in ipairs(dataManagerSearchPaths) do
            if path and path:IsA("ModuleScript") then
                local success, manager = pcall(function()
                    return require(path)
                end)
                
                if success and manager then
                    if path.Name == "DataPersistenceManager" then
                        dataPersistenceManager = manager
                    else
                        dataManager = manager
                    end
                end
            end
        end
        
        -- Prioritize DataPersistenceManager if found
        local activeManager = dataPersistenceManager or dataManager
        
        if not activeManager then
            table.insert(results.issues, "No data manager module found or failed to load")
            results.status = "ERROR"
            return results
        end
        
        -- Check if registered with CoreRegistry
        local coreRegistry
        pcall(function()
            coreRegistry = require(ServerScriptService.Core.CoreRegistry)
        end)
        
        if coreRegistry then
            local managerRegistered = false
            local persistenceManagerRegistered = false
            
            if coreRegistry.hasSystem then
                managerRegistered = coreRegistry:hasSystem("DataManager")
                persistenceManagerRegistered = coreRegistry:hasSystem("DataPersistenceManager")
            elseif coreRegistry.systems then
                managerRegistered = coreRegistry.systems["DataManager"] ~= nil
                persistenceManagerRegistered = coreRegistry.systems["DataPersistenceManager"] ~= nil
            end
            
            if not managerRegistered and not persistenceManagerRegistered then
                table.insert(results.issues, "Data managers not registered with CoreRegistry")
                results.status = "WARNING"
            end
        end
        
        -- Check required functions
        local requiredFunctions = {"saveData", "loadData", "getDefaultData"}
        for _, funcName in ipairs(requiredFunctions) do
            if type(activeManager[funcName]) ~= "function" then
                table.insert(results.issues, "Data manager missing " .. funcName .. " function")
                results.status = "ERROR"
            end
        end
        
        -- Check for backup functionality
        local hasBackup = type(activeManager.backup) == "function" or type(activeManager.createBackup) == "function"
        if not hasBackup then
            table.insert(results.issues, "Data manager missing backup functionality")
            results.status = results.status == "ERROR" and "ERROR" or "WARNING"
        end
          -- Check save stats if available
        if activeManager.getStats and type(activeManager.getStats) == "function" then
            local stats = activeManager.getStats()
            if stats then
                if stats.failedSaves and stats.failedSaves > 0 then
                    table.insert(results.issues, "Data manager has " .. stats.failedSaves .. " failed saves")
                    results.status = results.status == "ERROR" and "ERROR" or "WARNING"
                end
                
                if stats.failedLoads and stats.failedLoads > 0 then
                    table.insert(results.issues, "Data manager has " .. stats.failedLoads .. " failed loads")
                    results.status = results.status == "ERROR" and "ERROR" or "WARNING"
                end
            end
        end
          return results
    end,
      BuyTileSystem = function()
        local results = {
            status = "OK",
            issues = {}
        }
        
        -- Check GymParts folder
        local gymPartsFolder = ServerStorage:FindFirstChild("GymParts")
        if not gymPartsFolder then
            table.insert(results.issues, "GymParts folder not found in ServerStorage")
            results.status = "ERROR"
            return results
        end
        
        -- Check if it has any items
        if #gymPartsFolder:GetChildren() == 0 then
            table.insert(results.issues, "GymParts folder is empty")
            results.status = "ERROR"
        end
        
        -- Look for BuyTile system
        local buyTileSystem
        local buyTileSearchPaths = {
            ServerScriptService:FindFirstChild("BuyTileSystem"),
            ServerScriptService:FindFirstChild("BuyTileFixer"),
            ServerScriptService.Server and ServerScriptService.Server:FindFirstChild("BuyTileSystem")
        }
        
        for _, path in ipairs(buyTileSearchPaths) do
            if path and (path:IsA("ModuleScript") or path:IsA("Script")) then
                if path:IsA("ModuleScript") then
                    local success, system = pcall(function()
                        return require(path)
                    end)
                    
                    if success and system then
                        buyTileSystem = system
                        break
                    end
                end
            end
        end
        
        if not buyTileSystem then
            table.insert(results.issues, "BuyTile system module not found or failed to load")
            results.status = "WARNING"
        else
            -- Check required functions
            local requiredFunctions = {"spawnGymPart", "findGymPartById"}
            for _, funcName in ipairs(requiredFunctions) do
                if type(buyTileSystem[funcName]) ~= "function" then
                    table.insert(results.issues, "BuyTile system missing " .. funcName .. " function")
                    results.status = "WARNING"
                end
            end
        end
        
        return results
    end,
      FolderStructure = function()
        local results = {
            status = "OK",
            issues = {}
        }
        
        -- Check required folders
        local requiredFolders = {
            {parent = ReplicatedStorage, name = "shared"},
            {parent = ReplicatedStorage, name = "EventBridge"},
            {parent = ServerScriptService, name = "Core"},
            {parent = ServerScriptService, name = "Server"},
            {parent = ServerStorage, name = "GymParts"}
        }
        
        for _, folderInfo in ipairs(requiredFolders) do
            local folder = folderInfo.parent:FindFirstChild(folderInfo.name)
            if not folder then
                table.insert(results.issues, folderInfo.name .. " folder not found in " .. folderInfo.parent:GetFullName())
                results.status = "WARNING"
            elseif not folder:IsA("Folder") then
                table.insert(results.issues, folderInfo.name .. " in " .. folderInfo.parent:GetFullName() .. " is not a Folder")
                results.status = "ERROR"
            end
        end
        
        return results
    end
}

-- Repair functions for each category
local repairs = {
    TycoonStructure = function(results)
        log("Attempting to fix Tycoon structure issues")
        
        -- Try to use TycoonFolderInitializer first
        local initializer = ServerScriptService.Core:FindFirstChild("TycoonFolderInitializer")
        if initializer and initializer:IsA("ModuleScript") then
            local success, module = pcall(function()
                return require(initializer)
            end)
            
            if success and module and module.validateTycoonStructure then
                -- For each player with issues
                for _, playerResult in ipairs(results.playerResults) do
                    local player = Players:FindFirstChild(playerResult.name)
                    if player then
                        log("Fixing Tycoon structure for", player.Name)
                        local success, result = pcall(function()
                            return module.validateTycoonStructure(player)
                        end)
                        
                        if success and result then
                            log("Successfully fixed Tycoon structure for", player.Name)
                        else
                            warn("Failed to fix Tycoon structure for", player.Name, "-", tostring(result))
                        end
                    end
                end
                return
            end
        end
        
        -- Fallback to TycoonFolderFixer if available
        local tycoonFixer
        local fixerPath = ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("TycoonFolderFixer")
        
        if fixerPath and fixerPath:IsA("ModuleScript") then
            local success, fixer = pcall(function()
                return require(fixerPath)
            end)
            
            if success and fixer then
                tycoonFixer = fixer
            end
        end
        
        -- For each player with issues
        for _, playerResult in ipairs(results.playerResults) do
            local player = Players:FindFirstChild(playerResult.name)
            if player then
                log("Fixing Tycoon structure for", player.Name)
                
                -- Use TycoonFolderFixer if available
                if tycoonFixer and tycoonFixer.fixPlayerTycoon then
                    tycoonFixer.fixPlayerTycoon(player)
                else
                    -- Basic fix
                    local tycoon = player:FindFirstChild("Tycoon")
                    
                    -- Remove if not ObjectValue
                    if tycoon and not tycoon:IsA("ObjectValue") then
                        tycoon:Destroy()
                        tycoon = nil
                    end
                    
                    -- Create if needed
                    if not tycoon then
                        tycoon = Instance.new("ObjectValue")
                        tycoon.Name = "Tycoon"
                        tycoon.Parent = player
                    end
                    
                    -- Set required attributes
                    tycoon:SetAttribute("EquipmentCount", tycoon:GetAttribute("EquipmentCount") or 0)
                    tycoon:SetAttribute("GymTier", tycoon:GetAttribute("GymTier") or 1)
                    tycoon:SetAttribute("MemberCount", tycoon:GetAttribute("MemberCount") or 0)
                end
            end
        end
    end,
    
    CoreRegistry = function(results)
        log("Attempting to fix CoreRegistry issues")
        
        -- Check if CoreRegistry exists
        local coreRegistryPath = ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("CoreRegistry")
          -- If CoreRegistry exists but has issues, try to reload it
        if coreRegistryPath and coreRegistryPath:IsA("ModuleScript") then
            log("Reloading CoreRegistry module")            
            -- Clear from cache to force reload            
            local reloadSuccess = pcall(function()
                -- Using _G as a cache instead of package.loaded
                _G.moduleCache = _G.moduleCache or {}
                _G.moduleCache[coreRegistryPath:GetFullName()] = nil
            end)
            
            if reloadSuccess then
                log("Successfully cleared CoreRegistry from module cache")
            end
        end
        
        -- Check if CoreRegistryMonitor exists and use it
        local monitorPath = ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("CoreRegistryMonitor")
          if monitorPath and monitorPath:IsA("ModuleScript") then
            local requireSuccess, monitor = pcall(function()
                return require(monitorPath)
            end)
            
            if requireSuccess and monitor and monitor.checkNow then
                log("Using CoreRegistryMonitor to check registry")
                local status = monitor.checkNow()
                log("CoreRegistry status:", status)            end
        end
    end,
    
    DataPersistence = function(results)
        log("Attempting to fix DataPersistence issues")
        
        -- First try to use DataSystemIntegration if available
        local dataSystemIntegration
        local success = pcall(function()
            dataSystemIntegration = require(ServerScriptService.Data.DataSystemIntegration)
        end)
        
        if success and dataSystemIntegration then
            log("Using DataSystemIntegration to repair data systems")
            
            -- If it's already initialized, reinitialize it
            if dataSystemIntegration.initialized then
                log("Reinitializing DataSystemIntegration")
                      -- Force reload the module
                pcall(function()
                    _G.moduleCache = _G.moduleCache or {}
                    _G.moduleCache[ServerScriptService.Data.DataSystemIntegration:GetFullName()] = nil
                    dataSystemIntegration = require(ServerScriptService.Data.DataSystemIntegration)
                    dataSystemIntegration:init()
                end)
            end
            
            -- Let's see if DataSystemIntegration fixed the issues
            if dataSystemIntegration.runDiagnostics then
                local diagnostics = dataSystemIntegration.runDiagnostics()
                if (diagnostics.dataPersistenceManager or diagnostics.dataManager) and diagnostics.initialized then
                    log("DataSystemIntegration successfully repaired the data system")
                    return
                end
            end
        end
        
        -- If DataSystemIntegration isn't available or couldn't fix it, 
        -- try to fix DataPersistenceManager and DataManager directly
        
        -- Find and reload DataPersistenceManager
        local dataManagerPath
        local searchPaths = {
            ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("DataPersistenceManager"),
            ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("DataManager"),
            ServerScriptService:FindFirstChild("DataPersistenceManager"),
            ServerScriptService:FindFirstChild("DataManager")
        }
        
        for _, path in ipairs(searchPaths) do
            if path and path:IsA("ModuleScript") then
                dataManagerPath = path
                log("Found data manager at " .. path:GetFullName())
                break
            end
        end
        
        if dataManagerPath then
            log("Reloading Data Manager module: " .. dataManagerPath.Name)
              -- Clear from cache to force reload
            local reloadSuccess = pcall(function()
                _G.moduleCache = _G.moduleCache or {}
                _G.moduleCache[dataManagerPath:GetFullName()] = nil
            end)
            
            if reloadSuccess then
                -- Try to require it
                local requireSuccess, dataManager = pcall(function()
                    return require(dataManagerPath)
                end)
                
                if requireSuccess and dataManager then
                    log("Successfully reloaded Data Manager module")
                    
                    -- Register with CoreRegistry if possible
                    local coreRegistry
                    pcall(function()
                        coreRegistry = require(ServerScriptService.Core.CoreRegistry)
                    end)
                    
                    if coreRegistry and coreRegistry.registerSystem then
                        if dataManagerPath.Name == "DataPersistenceManager" then
                            log("Registering DataPersistenceManager with CoreRegistry")
                            coreRegistry:registerSystem("DataPersistenceManager", dataManager)
                            
                            -- Also register as DataManager for compatibility
                            coreRegistry:registerSystem("DataManager", dataManager)
                        else
                            log("Registering DataManager with CoreRegistry")
                            coreRegistry:registerSystem("DataManager", dataManager)
                        end
                    end
                    
                    -- Initialize if needed
                    if dataManager.init and not dataManager.initialized then
                        log("Initializing Data Manager")
                        pcall(function()
                            dataManager:init()
                        end)
                    end
                else
                    log("Failed to reload Data Manager module")
                end
            end
        else
            log("No data manager module found to repair")        end
    end,
    
    BuyTileSystem = function(results)
        log("Attempting to fix BuyTile system issues")
        
        -- Ensure GymParts folder exists
        local gymPartsFolder = ServerStorage:FindFirstChild("GymParts")
        
        if not gymPartsFolder then
            log("Creating GymParts folder")
            gymPartsFolder = Instance.new("Folder")
            gymPartsFolder.Name = "GymParts"
            gymPartsFolder.Parent = ServerStorage
        end
        
        -- If folder is empty, create some default parts
        if #gymPartsFolder:GetChildren() == 0 then
            log("GymParts folder is empty, creating default parts")
            
            -- Look for BuyTileFixer or BuyTileSystem to help create parts
            local partCreator
            local searchPaths = {
                ServerScriptService:FindFirstChild("BuyTileFixer"),
                ServerScriptService:FindFirstChild("BuyTileSystem")
            }
            
            for _, path in ipairs(searchPaths) do
                if path and path:IsA("ModuleScript") then
                    local success, module = pcall(function()
                        return require(path)
                    end)
                    
                    if success and module and (module.createDefaultGymPart or module.createGymPart) then
                        partCreator = module
                        break
                    end
                end
            end
            
            -- Create default parts
            if partCreator then
                for id = 1, 3 do
                    log("Creating default gym part for ID:", id)
                    
                    if partCreator.createDefaultGymPart then
                        partCreator.createDefaultGymPart(id)
                    elseif partCreator.createGymPart then
                        partCreator.createGymPart(id)
                    end
                end
            else
                -- Basic part creation if no helper module found
                for id = 1, 3 do
                    log("Creating basic gym part for ID:", id)
                    
                    local model = Instance.new("Model")
                    model.Name = "GymPart_" .. id
                    
                    -- Create main part
                    local part = Instance.new("Part")
                    part.Anchored = true
                    part.Size = Vector3.new(5, 1, 5)
                    part.Color = Color3.fromRGB(0, 170, 255)
                    part.Parent = model
                    
                    model.PrimaryPart = part
                    model:SetAttribute("ID", id)
                    model.Parent = gymPartsFolder
                end
            end        end
    end,
    
    FolderStructure = function(results)
        log("Attempting to fix folder structure issues")
        
        -- Create missing folders
        local requiredFolders = {
            {parent = ReplicatedStorage, name = "shared"},
            {parent = ReplicatedStorage, name = "EventBridge"},
            {parent = ReplicatedStorage, name = "CoreRegistryRemotes"},
            {parent = ServerScriptService, name = "Core"},
            {parent = ServerScriptService, name = "Server"},
            {parent = ServerScriptService, name = "Tests"},
            {parent = ServerStorage, name = "GymParts"},
            {parent = ServerStorage, name = "BuyTiles"}
        }
        
        for _, folderInfo in ipairs(requiredFolders) do
            local folder = folderInfo.parent:FindFirstChild(folderInfo.name)
            
            -- Remove if not a folder
            if folder and not folder:IsA("Folder") then
                log("Removing non-Folder", folderInfo.name, "from", folderInfo.parent:GetFullName())
                folder:Destroy()
                folder = nil
            end
            
            -- Create if missing
            if not folder then
                log("Creating", folderInfo.name, "folder in", folderInfo.parent:GetFullName())
                folder = Instance.new("Folder")
                folder.Name = folderInfo.name
                folder.Parent = folderInfo.parent
            end
        end
    end
}

-- Run all diagnostics
local function runDiagnostics()
    log("Running diagnostics")
    local startTime = os.clock()
    local results = {}
    
    -- Run each diagnostic
    for _, category in ipairs(CONFIG.diagnosticCategories) do
        if diagnostics[category] then
            results[category] = diagnostics[category]()
            log(category, "diagnostic result:", results[category].status)
        end
    end
    
    -- Store results
    diagResults = results
    
    -- Create status summary
    local summary = {
        timestamp = os.time(),
        duration = os.clock() - startTime,
        ok = 0,
        warning = 0,
        error = 0
    }
    
    for _, result in pairs(results) do
        if result.status == "OK" then
            summary.ok = summary.ok + 1
        elseif result.status == "WARNING" then
            summary.warning = summary.warning + 1
        elseif result.status == "ERROR" then
            summary.error = summary.error + 1
        end
    end
    
    log("Diagnostics complete. OK:", summary.ok, " WARNING:", summary.warning, " ERROR:", summary.error)
    
    -- Attempt to fix issues if auto-fix is enabled
    if CONFIG.autofixEnabled and (summary.warning > 0 or summary.error > 0) then
        log("Auto-fix is enabled, attempting to repair issues")
        
        for category, result in pairs(results) do
            if result.status ~= "OK" and repairs[category] then
                log("Repairing", category)
                repairs[category](result)
            end
        end
        
        -- Run diagnostics again to check if issues were fixed
        task.delay(3, function()
            log("Re-running diagnostics after repairs")
            local newResults = {}
            
            for _, category in ipairs(CONFIG.diagnosticCategories) do
                if diagnostics[category] then
                    newResults[category] = diagnostics[category]()
                    log(category, "diagnostic result after repair:", newResults[category].status)
                end
            end
            
            -- Update stored results
            diagResults = newResults
        end)
    end
    
    return results
end

-- Create status objects in ReplicatedStorage
local function createStatusObjects()
    -- Create diagnostics folder
    local diagnosticsFolder = ReplicatedStorage:FindFirstChild("DiagnosticsStatus")
    
    if not diagnosticsFolder then
        diagnosticsFolder = Instance.new("Folder")
        diagnosticsFolder.Name = "DiagnosticsStatus"
        diagnosticsFolder.Parent = ReplicatedStorage
    end
    
    -- Create status value
    local statusValue = diagnosticsFolder:FindFirstChild("Status") or Instance.new("StringValue")
    statusValue.Name = "Status"
    statusValue.Value = "Initializing"
    statusValue.Parent = diagnosticsFolder
    
    -- Create timestamp value
    local timestampValue = diagnosticsFolder:FindFirstChild("LastRun") or Instance.new("NumberValue")
    timestampValue.Name = "LastRun"
    timestampValue.Value = os.time()
    timestampValue.Parent = diagnosticsFolder
    
    -- Create check function
    local checkFunction = diagnosticsFolder:FindFirstChild("RunDiagnostics") or Instance.new("BindableFunction")
    checkFunction.Name = "RunDiagnostics"
    checkFunction.Parent = diagnosticsFolder
    
    -- Set function
    checkFunction.OnInvoke = function()
        local results = runDiagnostics()
        return results
    end
    
    return {
        folder = diagnosticsFolder,
        status = statusValue,
        timestamp = timestampValue,
        runFunction = checkFunction
    }
end

-- Setup periodic diagnostics
local function setupPeriodicDiagnostics()
    local statusObjects = createStatusObjects()
    
    -- Run initial diagnostics
    task.delay(5, function()
        log("Running initial diagnostics")
        local results = runDiagnostics()
        
        -- Update status
        local status = "OK"
        for _, result in pairs(results) do
            if result.status == "ERROR" then
                status = "ERROR"
                break
            elseif result.status == "WARNING" and status ~= "ERROR" then
                status = "WARNING"
            end
        end
        
        statusObjects.status.Value = status
        statusObjects.timestamp.Value = os.time()
    end)
    
    -- Setup periodic diagnostics
    task.spawn(function()
        while true do
            task.wait(CONFIG.diagnosticInterval)
            
            log("Running periodic diagnostics")
            local results = runDiagnostics()
            
            -- Update status
            local status = "OK"
            for _, result in pairs(results) do
                if result.status == "ERROR" then
                    status = "ERROR"
                    break
                elseif result.status == "WARNING" and status ~= "ERROR" then
                    status = "WARNING"
                end
            end
            
            statusObjects.status.Value = status
            statusObjects.timestamp.Value = os.time()
        end
    end)
end

-- Run setup
setupPeriodicDiagnostics()

-- Return public API
return {
    runDiagnostics = runDiagnostics,
    repairIssue = function(category)
        if repairs[category] and diagResults[category] then
            repairs[category](diagResults[category])
            return true
        end
        return false
    end,
    getResults = function()
        return diagResults
    end,
    setAutofixEnabled = function(enabled)
        CONFIG.autofixEnabled = enabled
        return CONFIG.autofixEnabled
    end
}
