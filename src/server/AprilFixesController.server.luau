--!strict
--[[
    AprilFixesController.server.luau
    Master controller for all April 29, 2025 fixes
    Handles initialization, dependency management, and diagnostics
    
    Created: April 29, 2025
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local DEBUG_MODE = RunService:IsStudio()
local CONFIG = {
    fixGroups = {
        {
            name = "CoreRegistry",
            priority = 1,
            scripts = {"CoreRegistryRestorer"},
            required = true
        },
        {
            name = "BuyTile", 
            priority = 2,
            scripts = {"BuyTilePositionFixer"},
            required = false
        },
        {
            name = "ClientFixes",
            priority = 3,
            scripts = {"ClientFixDistributor"}, -- UIAccessRestrictor changed to .lua extension
            required = true
        }
    },
    diagnosticsEnabled = true,
    diagnosticsInterval = 60, -- seconds
    maxRetries = 3
}

-- State management
local state = {
    initialized = false,
    fixStatus = {},
    diagnosticsActive = false,
    startTime = os.clock()
}

-- Logging with timestamp
local function log(message, level)
    local levelPrefix = ""
    if level == "warn" then levelPrefix = "⚠️ " 
    elseif level == "error" then levelPrefix = "❌ "
    elseif level == "success" then levelPrefix = "✅ " 
    elseif level == "info" then levelPrefix = "ℹ️ " end
    
    local timestamp = string.format("[%.2fs]", os.clock() - state.startTime)
    local prefix = "[AprilFixesController]" .. timestamp
    
    if level == "warn" then
        warn(prefix .. " " .. levelPrefix .. message)
    elseif level == "error" then
        error(prefix .. " " .. levelPrefix .. message)
    else
        print(prefix .. " " .. levelPrefix .. message)
    end
end

-- Find script by name in multiple locations
local function findScript(scriptName)
    -- Define common script paths to search
    local searchPaths = {
        ServerScriptService.Core,
        ServerScriptService.Systems,
        ServerScriptService.src,
        ServerScriptService.src and ServerScriptService.src.server,
        ServerScriptService.src and ServerScriptService.src.server and ServerScriptService.src.server.Core,
        ServerScriptService.src and ServerScriptService.src.client,
        ServerScriptService
    }
    
    -- Filter out nil paths
    local validPaths = {}
    for _, path in ipairs(searchPaths) do
        if path then
            table.insert(validPaths, path)
        end
    end
    
    -- Search for the script
    for _, path in ipairs(validPaths) do
        local script = path:FindFirstChild(scriptName)
        if script then
            return script
        end
    end
    
    return nil
end

-- Execute a fix script
local function executeFixScript(scriptName, retry)
    retry = retry or 0
    local script = findScript(scriptName)
    
    if not script then
        if retry < CONFIG.maxRetries then
            log("Script not found: " .. scriptName .. ", will retry (" .. (retry+1) .. "/" .. CONFIG.maxRetries .. ")", "warn")
            task.delay(1, function()
                executeFixScript(scriptName, retry + 1)
            end)
        else
            log("Failed to find script after " .. CONFIG.maxRetries .. " retries: " .. scriptName, "error")
            state.fixStatus[scriptName] = {
                success = false, 
                error = "Script not found"
            }
        end
        return false
    end
    
    -- Try to execute the script
    log("Executing fix script: " .. scriptName)
    
    local success, result = pcall(function()
        if script:IsA("ModuleScript") then
            return require(script)
        elseif script:IsA("Script") then
            -- If it's already running as a server script, assume it's working
            return true
        end
    end)
    
    if success then
        log("Successfully executed: " .. scriptName, "success")
        state.fixStatus[scriptName] = {
            success = true,
            result = result
        }
        return true
    else
        if retry < CONFIG.maxRetries then
            log("Failed to execute " .. scriptName .. " will retry (" .. (retry+1) .. "/" .. CONFIG.maxRetries .. "): " .. tostring(result), "warn")
            task.delay(1, function()
                executeFixScript(scriptName, retry + 1)
            end)
        else
            log("Failed to execute after " .. CONFIG.maxRetries .. " retries: " .. scriptName .. " - " .. tostring(result), "error")
            state.fixStatus[scriptName] = {
                success = false, 
                error = tostring(result)
            }
        end
        return false
    end
end

-- Initialize a fix group
local function initializeFixGroup(group)
    log("Initializing fix group: " .. group.name .. " (Priority: " .. group.priority .. ")")
    
    local allSucceeded = true
    for _, scriptName in ipairs(group.scripts) do
        local success = executeFixScript(scriptName)
        if not success and group.required then
            allSucceeded = false
        end
    end
    
    if allSucceeded then
        log("Fix group completed successfully: " .. group.name, "success")
    elseif group.required then
        log("Required fix group failed: " .. group.name, "error")
    else
        log("Non-required fix group completed with some issues: " .. group.name, "warn")
    end
    
    return allSucceeded
end

-- Run diagnostics to check the health of fixes
local function runDiagnostics()
    if not state.diagnosticsActive then
        state.diagnosticsActive = true
        
        log("Running diagnostics check...", "info")
        
        -- Check CoreRegistry functionality
        local CoreRegistry = nil
        local registryCheckPassed = pcall(function()
            -- Try different paths to find CoreRegistry
            local searchPaths = {
                ReplicatedStorage.shared,
                ReplicatedStorage.src and ReplicatedStorage.src.shared,
                ServerScriptService.Core,
                ServerScriptService.Systems
            }
            
            for _, path in ipairs(searchPaths) do
                if path and path:FindFirstChild("CoreRegistry") then
                    CoreRegistry = require(path.CoreRegistry)
                    if CoreRegistry and CoreRegistry.GetSystem then
                        break
                    end
                end
            end
            
            if not CoreRegistry or not CoreRegistry.GetSystem then
                error("CoreRegistry not found or invalid")
            end
            
            -- Check critical systems
            local criticalSystems = {"ModuleLoader", "DataManager", "UIComponents", "AssetValidator", "BuyTileSystem"}
            local missingCount = 0
            
            for _, systemName in ipairs(criticalSystems) do
                local system = CoreRegistry:GetSystem(systemName)
                if not system then
                    log("Critical system still missing: " .. systemName, "warn")
                    missingCount += 1
                end
            end
            
            if missingCount > 0 then
                error(missingCount .. " critical systems still missing")
            end
        end)
        
        -- Check BuyTileSystem fixes
        local buyTileCheckPassed = pcall(function()
            -- Check if the fix was applied
            if not _G.BuyTilePositionFixerInitialized then
                error("BuyTilePositionFixer not initialized")
            end
            
            -- Optional: Check for patched functions
            if CoreRegistry then
                local BuyTileSystem = CoreRegistry:GetSystem("BuyTileSystem")
                if BuyTileSystem and not BuyTileSystem._positionFixApplied then
                    error("BuyTileSystem not patched with position fix")
                end
            end
        end)
        
        -- Check client-side fixes distribution
        local clientFixesCheckPassed = pcall(function()
            -- Check if the flag is set in ReplicatedStorage
            local clientConfig = ReplicatedStorage:FindFirstChild("ClientConfig")
            if not clientConfig or not clientConfig:FindFirstChild("EnableUIAccessRestrictor") then
                error("Client fix configuration not set")
            end
        end)
        
        -- Log results
        log("Diagnostics results:", "info")
        log("  CoreRegistry fixes: " .. (registryCheckPassed and "✅" or "❌"), registryCheckPassed and "success" or "warn")
        log("  BuyTile fixes: " .. (buyTileCheckPassed and "✅" or "❌"), buyTileCheckPassed and "success" or "warn")
        log("  Client fixes: " .. (clientFixesCheckPassed and "✅" or "❌"), clientFixesCheckPassed and "success" or "warn")
        
        -- Schedule next run if enabled
        if CONFIG.diagnosticsEnabled then
            task.delay(CONFIG.diagnosticsInterval, function()
                state.diagnosticsActive = false
                runDiagnostics()
            end)
        else
            state.diagnosticsActive = false
        end
    end
end

-- Initialize all fixes in priority order
local function initialize()
    if state.initialized then
        return
    end
    
    log("Starting initialization of all April 29 fixes...")
    state.startTime = os.clock()
    
    -- Sort fix groups by priority
    table.sort(CONFIG.fixGroups, function(a, b)
        return a.priority < b.priority
    end)
    
    -- Initialize each group
    for _, group in ipairs(CONFIG.fixGroups) do
        initializeFixGroup(group)
    end
    
    -- Set global flag
    _G.AprilFixesController = {
        version = "1.0.0",
        initialized = true,
        getStatus = function()
            return state.fixStatus
        end
    }
    
    state.initialized = true
    log("All fixes initialized in " .. string.format("%.2f", os.clock() - state.startTime) .. " seconds", "success")
    
    -- Run initial diagnostics after a delay
    task.delay(5, function()
        runDiagnostics()
    end)
end

-- Autorun with safety check
task.spawn(function()
    -- Wait a moment for other scripts to initialize
    task.wait(1)
    initialize()
end)

return {
    initialize = initialize,
    runDiagnostics = runDiagnostics,
    getStatus = function() return state.fixStatus end,
    DEBUG_MODE = DEBUG_MODE
}
