--!strict
--[[
    DiagnosticsAndRepair.server.luau
    
    System for diagnosing and repairing issues with core systems.
    Includes checks for BuyTileSystem integration and health.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Updated for new BuyTileSystem integration
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Import dependencies
local CoreRegistry = require(ServerScriptService.Core.CoreRegistry)
local BuyTileSystem = require(ServerScriptService.Core.BuyTileSystem)
local DataAccessLayer = require(ServerScriptService.Core.DataAccessLayer)

-- Configuration
local CONFIG = {
    debug = true,
    maxRetries = 3,
    retryDelay = 1, -- seconds
    checkInterval = 60, -- seconds
    autoRepair = true
}

-- DiagnosticsAndRepair module
local DiagnosticsAndRepair = {
    Version = "2.0.0",
    initialized = false,
    stats = {
        checks = 0,
        errors = 0,
        repairs = 0
    }
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[DiagnosticsAndRepair]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Get a safe require function
local function getSafeRequire()
    return function(module)
        local success, result = pcall(function()
            return require(module)
        end)
        if success then
            return result
        end
        return nil
    end
end

-- Get a system from CoreRegistry
local function getSystem(systemName, safeRequire)
    -- Try CoreRegistry first
    if CoreRegistry then
        local system = CoreRegistry:getSystem(systemName)
        if system then
            return system
        end
    end
    
    -- Try direct require
    if safeRequire then
        local system = safeRequire(ServerScriptService.Core[systemName])
        if system then
            return system
        end
    end
    
    return nil
end

-- System diagnostics
local SystemDiagnostics = {
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
        
        -- Check if BuyTileSystem has required methods
        local requiredMethods = {
            "Initialize",
            "RegisterTile",
            "GetTile",
            "IsTileOwned",
            "GetOwnedTiles",
            "BuyTile",
            "GetAvailableTiles"
        }
        
        for _, method in ipairs(requiredMethods) do
            if typeof(BuyTileSystem[method]) ~= "function" then
                log("BuyTileSystem diagnostic result: ERROR (missing method: " .. method .. ")")
                return "ERROR"
            end
        end
        
        -- Check if BuyTileSystem is integrated with DataAccessLayer
        if not BuyTileSystem:IsHealthy() then
            log("BuyTileSystem diagnostic result: WARNING (system not healthy)")
            return "WARNING"
        end
        
        log("BuyTileSystem diagnostic result: OK")
        return "OK"
    end,
    
    -- Add more system diagnostics here
}

-- Initialize the system
function DiagnosticsAndRepair:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing DiagnosticsAndRepair v" .. self.Version)
    
    -- Register with CoreRegistry
    if CoreRegistry then
        CoreRegistry:registerSystem("DiagnosticsAndRepair", self)
        log("Registered with CoreRegistry")
    end
    
    -- Set up periodic checks
    task.spawn(function()
        while true do
            self:RunDiagnostics()
            task.wait(CONFIG.checkInterval)
        end
    end)
    
    self.initialized = true
    log("DiagnosticsAndRepair initialized successfully")
    return true
end

-- Run diagnostics
function DiagnosticsAndRepair:RunDiagnostics()
    log("Running system diagnostics")
    
    for systemName, diagnostic in pairs(SystemDiagnostics) do
        local result = diagnostic()
        
        if result == "ERROR" then
            self.stats.errors += 1
            if CONFIG.autoRepair then
                self:AttemptRepair(systemName)
            end
        elseif result == "WARNING" then
            log("Warning for " .. systemName, "warn")
        end
    end
    
    self.stats.checks += 1
end

-- Attempt to repair a system
function DiagnosticsAndRepair:AttemptRepair(systemName)
    log("Attempting to repair " .. systemName)
    
    local system = getSystem(systemName, getSafeRequire())
    if not system then
        log("Could not find system to repair: " .. systemName, "error")
        return false
    end
    
    -- Try to recover the system
    if typeof(system.Recover) == "function" then
        local success = system:Recover()
        if success then
            log("Successfully repaired " .. systemName)
            self.stats.repairs += 1
            return true
        end
    end
    
    -- Try to reinitialize the system
    if typeof(system.Initialize) == "function" then
        local success = system:Initialize()
        if success then
            log("Successfully reinitialized " .. systemName)
            self.stats.repairs += 1
            return true
        end
    end
    
    log("Failed to repair " .. systemName, "error")
    return false
end

-- Get system health
function DiagnosticsAndRepair:IsHealthy()
    return self.initialized
end

-- Recover from failure
function DiagnosticsAndRepair:Recover()
    if not self.initialized then
        return self:Initialize()
    end
    return true
end

-- Initialize the DiagnosticsAndRepair
DiagnosticsAndRepair:Initialize()

return DiagnosticsAndRepair
