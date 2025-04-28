--[[
    Phase3ClientLoader.client.luau
    
    Client-side initialization for Phase 3 fixes addressing:
    1. Asset loading failures
    2. Sound playback issues
    
    This script ensures that client-side components of Phase 3 fixes are 
    properly loaded and initialized.
    
    Created: April 27, 2025
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    AUTO_INITIALIZE = true,
    INITIALIZATION_DELAY = 2, -- seconds to wait before initializing
    PRELOAD_SOUNDS = true,
    ASSET_DIAGNOSTICS = true, -- Enable asset loading diagnostics
    COLLECT_ASSET_STATS = true, -- Collect statistics about asset loading
    REPORT_ASSET_FAILURES = true, -- Report failed assets to the server
    ASSET_MONITORING_INTERVAL = 30, -- Check assets every 30 seconds
    MAX_TRACKED_FAILURES = 50 -- Maximum number of failed assets to track
}

-- Local player
local player = Players.LocalPlayer

-- Asset diagnostics data
local assetStats = {
    attemptedLoads = 0,
    successfulLoads = 0,
    failedLoads = 0,
    lastFailedAssets = {},
    startTime = os.clock()
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_MODE then
        print("[Phase3ClientLoader] " .. message)
    end
end

-- The Phase 3 client loader module
local Phase3ClientLoader = {}

-- Check if module exists without yielding
local function safeRequire(moduleParent, moduleName, timeout)
    timeout = timeout or 5 -- 5 seconds default timeout
    
    if not moduleParent then return nil end
    
    -- Check if module exists immediately
    if moduleParent:FindFirstChild(moduleName) then
        local success, result = pcall(function()
            return require(moduleParent[moduleName])
        end)
        
        if success then
            return result
        end
    end
    
    -- Wait with timeout
    local startTime = os.clock()
    local module
    
    while os.clock() - startTime < timeout do
        module = moduleParent:FindFirstChild(moduleName)
        if module then
            local success, result = pcall(function()
                return require(module)
            end)
            
            if success then
                return result
            end
            
            -- If require failed, no point waiting more
            return nil
        end
        
        task.wait(0.1)
    end
    
    return nil
end

-- Ensure we have shared folder
local function ensureSharedFolder()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        shared = Instance.new("Folder")
        shared.Name = "shared"
        shared.Parent = ReplicatedStorage
        log("Created missing shared folder")
    end
    
    return shared
end

-- Track asset loading success/failure
local function assetLoadingHandler(contentId, status)
    if not CONFIG.COLLECT_ASSET_STATS then return end
    
    assetStats.attemptedLoads = assetStats.attemptedLoads + 1
    
    if status == Enum.AssetFetchStatus.Success then
        assetStats.successfulLoads = assetStats.successfulLoads + 1
    else
        assetStats.failedLoads = assetStats.failedLoads + 1
        
        -- Record only asset ID
        local assetId = contentId:match("rbxassetid://(%d+)")
        if assetId then
            -- Keep the list at a reasonable size
            if #assetStats.lastFailedAssets >= CONFIG.MAX_TRACKED_FAILURES then
                table.remove(assetStats.lastFailedAssets, 1)
            end
            
            table.insert(assetStats.lastFailedAssets, {
                id = assetId,
                timestamp = os.time()
            })
            
            log("Failed to load asset ID: " .. assetId)
            
            -- Report to server if enabled
            if CONFIG.REPORT_ASSET_FAILURES then
                local assetReport = ReplicatedStorage:FindFirstChild("AssetLoadFailureReport")
                if assetReport and assetReport:IsA("RemoteEvent") then
                    assetReport:FireServer(assetId, status)
                end
            end
        end
    end
end

-- Create diagnostic tools
local function setupAssetDiagnostics()
    if not CONFIG.ASSET_DIAGNOSTICS then return end
    
    log("Setting up asset diagnostics tools")
    
    -- Set up ContentProvider asset load listener
    ContentProvider.AssetFetchFailed:Connect(function(contentId, status)
        assetLoadingHandler(contentId, status)
    end)
    
    -- Create reporting RemoteEvent if it doesn't exist
    if CONFIG.REPORT_ASSET_FAILURES then
        if not ReplicatedStorage:FindFirstChild("AssetLoadFailureReport") then
            local reportEvent = Instance.new("RemoteEvent")
            reportEvent.Name = "AssetLoadFailureReport"
            reportEvent.Parent = ReplicatedStorage
            log("Created AssetLoadFailureReport event")
        end
    end
    
    -- Create asset stats folder in PlayerGui
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local diagnosticsFolder = playerGui:FindFirstChild("AssetDiagnostics") 
        
        if not diagnosticsFolder then
            diagnosticsFolder = Instance.new("Folder")
            diagnosticsFolder.Name = "AssetDiagnostics"
            
            -- Create StringValue to store stats
            local statsValue = Instance.new("StringValue")
            statsValue.Name = "AssetStats"
            statsValue.Parent = diagnosticsFolder
            
            -- Create BindableFunction for querying stats
            local getStatsFunction = Instance.new("BindableFunction")
            getStatsFunction.Name = "GetAssetStats"
            getStatsFunction.OnInvoke = function()
                return assetStats
            end
            getStatsFunction.Parent = diagnosticsFolder
            
            diagnosticsFolder.Parent = playerGui
            log("Created asset diagnostics tools in PlayerGui")
        end
    end
    
    -- Periodically update stats
    task.spawn(function()
        while task.wait(CONFIG.ASSET_MONITORING_INTERVAL) do
            -- Calculate success rate
            local successRate = 0
            if assetStats.attemptedLoads > 0 then
                successRate = (assetStats.successfulLoads / assetStats.attemptedLoads) * 100
            end
            
            log(string.format("Asset Stats - Success: %.1f%%, Loaded: %d, Failed: %d", 
                successRate, assetStats.successfulLoads, assetStats.failedLoads))
            
            -- Update StringValue
            local playerGui = player:FindFirstChild("PlayerGui")
            if playerGui then
                local diagnosticsFolder = playerGui:FindFirstChild("AssetDiagnostics")
                if diagnosticsFolder then
                    local statsValue = diagnosticsFolder:FindFirstChild("AssetStats")
                    if statsValue and statsValue:IsA("StringValue") then
                        statsValue.Value = string.format([[
Success Rate: %.1f%%
Total Attempts: %d
Successful: %d
Failed: %d
Running for: %.0f seconds
                        ]], successRate, assetStats.attemptedLoads, 
                        assetStats.successfulLoads, assetStats.failedLoads,
                        os.clock() - assetStats.startTime)
                    end
                end
            end
        end
    end)
end

-- Try to find and fix common asset issues
local function scanForAssetIssues()
    log("Scanning for asset issues...")
    
    -- Try to load SoundAssetValidator
    local shared = ensureSharedFolder()
    local soundValidator = safeRequire(shared, "SoundAssetValidator")
    
    if soundValidator then
        task.spawn(function()
            log("Running sound asset scan")
            local fixCount = soundValidator.scanAndFixSoundAssets()
            log("Sound asset scan complete: Fixed " .. fixCount .. " assets")
        end)
    else
        log("SoundAssetValidator not found, skipping sound asset scan")
    end
    
    -- Look for missing UI assets
    task.spawn(function()
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            local issuesFound = 0
            
            -- Check for missing images in UI
            for _, instance in ipairs(playerGui:GetDescendants()) do
                if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
                    if instance.Image ~= "" and not instance.Image:match("^rbxasset") then
                        -- Try to preload it to check validity
                        ContentProvider:PreloadAsync({instance}, function(contentId, status)
                            if status ~= Enum.AssetFetchStatus.Success then
                                issuesFound = issuesFound + 1
                                log("Found problematic UI image: " .. contentId .. " in " .. instance:GetFullName())
                                
                                -- Try to replace with placeholder
                                instance.Image = "rbxassetid://9122021050" -- Generic UI placeholder
                            end
                        end)
                    end
                end
                
                -- Don't check too many items at once to prevent performance issues
                if issuesFound % 10 == 0 and issuesFound > 0 then
                    task.wait(0.1)
                end
            end
            
            log("UI asset scan complete: Found " .. issuesFound .. " issues")
        end
    end)
end

-- Initialize sound system fixes
function Phase3ClientLoader:InitializeSoundSystem()
    log("Initializing sound system fixes...")
    
    -- Ensure we have shared folder
    local shared = ensureSharedFolder()
    
    -- Try to load sound system modules
    local soundSystem = safeRequire(shared, "SoundSystemManager")
    local soundValidator = safeRequire(shared, "SoundAssetValidator")
    
    if not soundSystem then
        log("SoundSystemManager not found or failed to load")
    else
        log("SoundSystemManager loaded successfully")
    end
    
    if not soundValidator then
        log("SoundAssetValidator not found or failed to load")
    else
        log("SoundAssetValidator loaded successfully")
    end
    
    -- Ensure PlaySoundEvent exists
    local playSoundEvent = ReplicatedStorage:FindFirstChild("PlaySoundEvent")
    if not playSoundEvent then
        log("PlaySoundEvent missing! Creating a local fallback...")
        
        -- Create a local bindable instead
        local localEvent = Instance.new("BindableEvent")
        localEvent.Name = "LocalPlaySoundEvent"
        localEvent.Parent = player:FindFirstChild("PlayerGui") or player
        
        log("Created local sound event fallback")
    else
        log("PlaySoundEvent found")
    end
    
    -- Try to load the enhanced sound client
    local soundClient = safeRequire(player:FindFirstChild("PlayerScripts"), "SoundClient.client")
    
    if not soundClient then
        log("SoundClient.client not found or failed to load")
    else
        log("SoundClient.client loaded successfully")
    end
    
    -- Preload common sounds if sound validator is available
    if soundValidator and CONFIG.PRELOAD_SOUNDS then
        task.spawn(function()
            log("Preloading common sounds...")
            soundValidator.createSoundRegistry()
        end)
    end
    
    log("Sound system initialization complete")
    return soundSystem ~= nil or soundValidator ~= nil or soundClient ~= nil
end

-- Initialize diagnostics tools  
function Phase3ClientLoader:InitializeDiagnostics()
    log("Initializing asset diagnostics tools...")
    
    -- Set up asset diagnostics
    if CONFIG.ASSET_DIAGNOSTICS then
        setupAssetDiagnostics()
        
        -- Run an initial asset scan
        task.delay(5, function()  -- Delay to let other systems load first
            scanForAssetIssues()
        end)
    end
    
    return true
end

-- Initialize all client-side fixes
function Phase3ClientLoader:Initialize()
    -- Add a small delay to allow other systems to load first
    task.wait(CONFIG.INITIALIZATION_DELAY)
    
    log("Initializing Phase 3 client fixes...")
    
    local soundSystemResult = self:InitializeSoundSystem()
    local diagnosticsResult = self:InitializeDiagnostics()
    
    log("Phase 3 client initialization complete:")
    log("- Sound System: " .. (soundSystemResult and "SUCCESS" or "FAILED"))
    log("- Asset Diagnostics: " .. (diagnosticsResult and "SUCCESS" or "FAILED"))
    
    return soundSystemResult and diagnosticsResult
end

-- Create diagnostic commands for developers
local function setupDiagnosticCommands()
    -- Add to shared functions folder for access
    local sharedFunctions = ReplicatedStorage:FindFirstChild("SharedFunctions")
    if not sharedFunctions then
        sharedFunctions = Instance.new("Folder")
        sharedFunctions.Name = "SharedFunctions"
        sharedFunctions.Parent = ReplicatedStorage
    end
    
    -- Show asset stats
    local showAssetStats = Instance.new("BindableFunction")
    showAssetStats.Name = "ShowAssetStats"
    showAssetStats.OnInvoke = function()
        local successRate = 0
        if assetStats.attemptedLoads > 0 then
            successRate = (assetStats.successfulLoads / assetStats.attemptedLoads) * 100
        end
        
        return {
            successRate = successRate,
            attempted = assetStats.attemptedLoads,
            successful = assetStats.successfulLoads,
            failed = assetStats.failedLoads,
            runtime = os.clock() - assetStats.startTime,
            recentFailures = #assetStats.lastFailedAssets
        }
    end
    showAssetStats.Parent = sharedFunctions
    
    -- Scan for asset issues
    local scanAssets = Instance.new("BindableFunction")
    scanAssets.Name = "ScanForAssetIssues"
    scanAssets.OnInvoke = function()
        scanForAssetIssues()
        return "Asset scan initiated"
    end
    scanAssets.Parent = sharedFunctions
    
    log("Diagnostic commands set up")
end

-- Set up diagnostic commands
setupDiagnosticCommands()

-- Auto-initialize if enabled
if CONFIG.AUTO_INITIALIZE then
    task.spawn(function()
        Phase3ClientLoader:Initialize()
    end)
end

return Phase3ClientLoader
