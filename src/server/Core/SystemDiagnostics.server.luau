--[[
    SystemDiagnostics.server.luau
    
    This script performs diagnostics on critical game systems to identify and report issues.
    It helps verify that fixes are working correctly and provides immediate feedback on
    the status of core systems like CoreRegistry, BuyTileSystem, DataManager, and others.
    
    Created April 28, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Find a module safely
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

-- Safe require function
local function safeRequire(moduleInstance)
    if not moduleInstance then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if success then
        return result
    else
        warn("SystemDiagnostics: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return nil
    end
end

-- Try to get CoreRegistry
local CoreRegistry
local coreRegistryModule = findModule("CoreRegistry")
if coreRegistryModule then
    CoreRegistry = safeRequire(coreRegistryModule)
    print("SystemDiagnostics: Found CoreRegistry module")
else
    warn("SystemDiagnostics: CoreRegistry module not found")
end

-- Log with timestamp
local function log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    print("[SystemDiagnostics " .. timestamp .. " " .. level .. "] " .. message)
end

-- Check system status
local function checkSystem(systemName)
    log("Checking " .. systemName .. "...", "INFO")
    
    if not CoreRegistry then
        log("Cannot check " .. systemName .. " - CoreRegistry not available", "ERROR")
        return false, "CoreRegistry not available"
    end
    
    local system = CoreRegistry:GetSystem(systemName)
    if not system then
        log(systemName .. " not found in CoreRegistry", "ERROR")
        return false, "Not found"
    end
    
    -- Check if the system has a status or isLoaded property
    if system.status then
        log(systemName .. " status: " .. tostring(system.status), "INFO")
        return true, system.status
    elseif system.isLoaded ~= nil then
        log(systemName .. " isLoaded: " .. tostring(system.isLoaded), "INFO")
        return system.isLoaded, system.isLoaded and "Loaded" or "Not loaded"
    else
        log(systemName .. " found but no status information available", "WARNING")
        return true, "Unknown"
    end
end

-- Run diagnostics on a single critical system with detailed checks
local function diagnoseCriticalSystem(systemName)
    log("Running detailed diagnostics on " .. systemName, "INFO")
    
    if not CoreRegistry then
        log("Cannot diagnose " .. systemName .. " - CoreRegistry not available", "ERROR")
        return {
            name = systemName,
            status = "ERROR",
            message = "CoreRegistry not available",
            details = {},
            success = false
        }
    end
    
    local system = CoreRegistry:GetSystem(systemName)
    if not system then
        log(systemName .. " not found in CoreRegistry", "ERROR")
        return {
            name = systemName,
            status = "ERROR", 
            message = "System not found in CoreRegistry",
            details = {},
            success = false
        }
    end
    
    -- System-specific checks
    local diagnosticResult = {
        name = systemName,
        status = "OK",
        message = "System is operational",
        details = {},
        success = true
    }
    
    -- Check BuyTileSystem
    if systemName == "BuyTileSystem" then
        -- Check for tile data
        if not system.getAllTileData or not system.getTileData then
            diagnosticResult.status = "ERROR"
            diagnosticResult.message = "Missing core methods"
            diagnosticResult.success = false
        else
            local allTileData = system.getAllTileData()
            local tileCount = 0
            
            if type(allTileData) == "table" then
                for _ in pairs(allTileData) do
                    tileCount = tileCount + 1
                end
                
                diagnosticResult.details.tileCount = tileCount
                
                if tileCount == 0 then
                    diagnosticResult.status = "WARNING"
                    diagnosticResult.message = "No tile data found"
                else
                    diagnosticResult.details.tileDataPresent = true
                end
            else
                diagnosticResult.status = "ERROR"
                diagnosticResult.message = "Invalid tile data format"
                diagnosticResult.success = false
            end
        end
        
        -- Check for ordered tiles
        if not system.orderedTiles then
            diagnosticResult.details.orderedTiles = false
            
            if diagnosticResult.status == "OK" then
                diagnosticResult.status = "WARNING"
                diagnosticResult.message = "Missing ordered tiles"
            end
        else
            diagnosticResult.details.orderedTiles = true
            diagnosticResult.details.orderedTilesCount = #system.orderedTiles
        end
        
        -- Check gym part spawning
        if not system.spawnGymPart then
            diagnosticResult.details.spawnGymPart = false
            
            if diagnosticResult.status == "OK" then
                diagnosticResult.status = "WARNING"
                diagnosticResult.message = "Missing spawnGymPart method"
            end
        else
            diagnosticResult.details.spawnGymPart = true
        end
    end
    
    -- Check DataManager
    if systemName == "DataManager" then
        -- Check for core data methods
        if not system.loadPlayerData or not system.savePlayerData then
            diagnosticResult.status = "ERROR"
            diagnosticResult.message = "Missing core data methods"
            diagnosticResult.success = false
        end
        
        -- Check for player data handling
        if system.getPlayerData then
            diagnosticResult.details.getPlayerData = true
            
            -- Check for any player data
            local anyPlayer = Players:GetPlayers()[1]
            if anyPlayer and system.getPlayerData(anyPlayer) then
                diagnosticResult.details.playerDataAvailable = true
            else
                diagnosticResult.details.playerDataAvailable = false
                
                if diagnosticResult.status == "OK" then
                    diagnosticResult.status = "WARNING"
                    diagnosticResult.message = "No player data available"
                end
            end
        else
            diagnosticResult.details.getPlayerData = false
            
            if diagnosticResult.status == "OK" then
                diagnosticResult.status = "WARNING"
                diagnosticResult.message = "Missing getPlayerData method"
            end
        end
    end
    
    -- Check for TileDataInitializer integration
    if systemName == "TileDataInitializer" and system then
        if not system.initializeTileData then
            diagnosticResult.details.initializeTileData = false
            
            if diagnosticResult.status == "OK" then
                diagnosticResult.status = "WARNING"
                diagnosticResult.message = "Missing initializeTileData method"
            end
        else
            diagnosticResult.details.initializeTileData = true
        end
    end
    
    return diagnosticResult
end

-- Run full diagnostics on all critical systems
local function runDiagnostics()
    log("Starting system diagnostics...", "INFO")
    
    local criticalSystems = {
        "CoreRegistry",
        "BuyTileSystem",
        "TileDataInitializer",
        "BuyTileProgressionManager",
        "DataManager",
        "EventBridge",
        "ModuleLoader"
    }
    
    local results = {}
    local statusSummary = {
        OK = 0,
        WARNING = 0,
        ERROR = 0,
        MISSING = 0
    }
    
    for _, systemName in ipairs(criticalSystems) do
        local isAvailable, status = checkSystem(systemName)
        
        if not isAvailable and not CoreRegistry then
            results[systemName] = {
                status = "MISSING",
                message = "CoreRegistry not available"
            }
            statusSummary.MISSING = statusSummary.MISSING + 1
        else
            local result = diagnoseCriticalSystem(systemName)
            results[systemName] = result
            
            if result.status == "ERROR" then
                statusSummary.ERROR = statusSummary.ERROR + 1
            elseif result.status == "WARNING" then
                statusSummary.WARNING = statusSummary.WARNING + 1
            elseif result.status == "OK" then
                statusSummary.OK = statusSummary.OK + 1
            else
                statusSummary.MISSING = statusSummary.MISSING + 1
            end
        end
    end
    
    -- Print summary
    log("Diagnostics complete!", "INFO")
    log("Results: OK: " .. statusSummary.OK .. "  WARNING: " .. statusSummary.WARNING .. 
        "  ERROR: " .. statusSummary.ERROR .. "  MISSING: " .. statusSummary.MISSING, "INFO")
    
    return results, statusSummary
end

-- Check BuyTile system folder structure
local function checkTileFolderStructure()
    log("Checking tile folder structure...", "INFO")
    
    local ServerStorage = game:GetService("ServerStorage")
    local structureFolder = ServerStorage:FindFirstChild("GymStructure")
    
    if not structureFolder then
        log("GymStructure folder not found in ServerStorage", "ERROR")
        return false
    end
    
    -- Check floors
    local floorFolders = 0
    for _, child in ipairs(structureFolder:GetChildren()) do
        if child:IsA("Folder") and child.Name:match("_Floor") then
            floorFolders = floorFolders + 1
            
            -- Check for required subfolders
            local hasWalls = child:FindFirstChild("Walls") ~= nil
            local hasRooms = child:FindFirstChild("Rooms") ~= nil
            local hasCeiling = child:FindFirstChild("Ceiling") ~= nil
            local hasStairs = child:FindFirstChild("Stairs") ~= nil
            
            log("Floor " .. child.Name .. ": Walls=" .. (hasWalls and "Yes" or "No") .. 
                " Rooms=" .. (hasRooms and "Yes" or "No") .. 
                " Ceiling=" .. (hasCeiling and "Yes" or "No") .. 
                " Stairs=" .. (hasStairs and "Yes" or "No"), "INFO")
            
            -- Check room structure if rooms folder exists
            if hasRooms then
                local roomsFolder = child:FindFirstChild("Rooms")
                local roomTypes = {}
                
                for _, room in ipairs(roomsFolder:GetChildren()) do
                    if room:IsA("Folder") then
                        table.insert(roomTypes, room.Name)
                        
                        -- Check for equipment in each room
                        local equipmentCount = #room:GetChildren()
                        log("Room " .. room.Name .. " has " .. equipmentCount .. " equipment items", "INFO")
                    end
                end
                
                log("Found room types: " .. table.concat(roomTypes, ", "), "INFO")
            end
        end
    end
    
    log("Found " .. floorFolders .. " floor folders in GymStructure", "INFO")
    
    return floorFolders > 0
end

-- Fix common issues automatically
local function attemptAutoRepair()
    log("Attempting to repair identified issues...", "INFO")
    
    -- Check if BuyTileSystem exists but has no tile data
    local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")
    if BuyTileSystem then
        local tileData = BuyTileSystem.getAllTileData and BuyTileSystem.getAllTileData()
        local tileCount = 0
        
        if type(tileData) == "table" then
            for _ in pairs(tileData) do
                tileCount = tileCount + 1
            end
        end
        
        if tileCount == 0 then
            log("BuyTileSystem has no tile data, attempting to initialize via TileDataInitializer", "WARNING")
            
            -- Try to find and use TileDataInitializer
            local TileDataInitializer = CoreRegistry:GetSystem("TileDataInitializer")
            if TileDataInitializer and TileDataInitializer.initializeTileData then
                local success = TileDataInitializer.initializeTileData()
                log("TileDataInitializer.initializeTileData() result: " .. tostring(success), "INFO")
                return success
            else
                -- Try to find the script directly
                local initializerScript = findModule("TileDataInitializer")
                if initializerScript then
                    log("Attempting to run TileDataInitializer script", "WARNING")
                    safeRequire(initializerScript)
                    return true
                else
                    log("TileDataInitializer not found, cannot auto-repair tile data", "ERROR")
                    return false
                end
            end
        end
    end
    
    return false
end

-- Run diagnostics when the server starts
log("System Diagnostics module initialized", "INFO")
task.wait(5) -- Wait for other systems to initialize

-- Run initial diagnostics
local results, summary = runDiagnostics()

-- Check folder structure
checkTileFolderStructure()

-- Attempt auto-repair if serious issues found
if summary.ERROR > 0 or summary.MISSING > 0 then
    log("Serious issues detected, attempting auto-repair", "WARNING")
    attemptAutoRepair()
    
    -- Run diagnostics again after repair
    log("Running diagnostics again after repair attempt", "INFO")
    results, summary = runDiagnostics()
end

-- Create a global diagnostic function
_G.RunSystemDiagnostics = function()
    return runDiagnostics()
end

-- Register command if CommandService is available
local CommandService = CoreRegistry and CoreRegistry:GetSystem("CommandService")
if CommandService then
    CommandService:RegisterCommand("diagnostics", {
        description = "Runs system diagnostics to check for issues",
        handler = function(player)
            -- Check if player is admin
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            local results, summary = runDiagnostics()
            
            return "Diagnostics complete! OK: " .. summary.OK .. " WARNING: " .. 
                   summary.WARNING .. " ERROR: " .. summary.ERROR .. 
                   " MISSING: " .. summary.MISSING
        end
    })
end

return {
    runDiagnostics = runDiagnostics,
    checkTileFolderStructure = checkTileFolderStructure,
    attemptAutoRepair = attemptAutoRepair
}
