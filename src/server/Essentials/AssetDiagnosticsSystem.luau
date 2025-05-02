--[[
    AssetDiagnosticsSystem.luau
    
    This module provides diagnostics for asset loading issues, helping identify and
    fix common problems with game assets.
    
    Created as part of Phase 3 fixes: May 2, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    MAX_TRACKED_ASSETS = 100,
    PERIODIC_SCAN_INTERVAL = 300, -- 5 minutes
    REPORT_THRESHOLD = 3, -- Report assets that fail this many times
    SCAN_ON_STARTUP = true
}

-- Debug logging
local function log(message, messageType)
    if CONFIG.DEBUG_MODE or messageType == "error" or messageType == "warn" then
        local prefix = "[AssetDiagnosticsSystem] "
        if messageType == "error" then
            warn(prefix .. "ERROR: " .. message)
        elseif messageType == "warn" then
            warn(prefix .. "WARNING: " .. message)
        else
            print(prefix .. message)
        end
    end
end

-- Try to require CoreRegistry
local CoreRegistry
pcall(function()
    local coreRegistryModule = ServerScriptService:FindFirstChild("Core") and 
                              ServerScriptService.Core:FindFirstChild("CoreRegistry") or
                              (ReplicatedStorage:FindFirstChild("shared") and 
                               ReplicatedStorage.shared:FindFirstChild("CoreRegistryRef"))
    
    if coreRegistryModule then
        CoreRegistry = require(coreRegistryModule)
    end
end)

-- The AssetDiagnosticsSystem module
local AssetDiagnosticsSystem = {
    initialized = false,
    assetStats = {
        failedAssets = {}, -- Maps asset ID to failure count
        totalFailures = 0,
        byAssetType = {
            image = 0,
            sound = 0,
            mesh = 0,
            animation = 0,
            other = 0
        },
        byErrorType = {},
        recentIssues = {} -- List of recent issues for easy access
    },
    remoteEvent = nil -- RemoteEvent for client reporting
}

-- Initialize the module
function AssetDiagnosticsSystem:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing AssetDiagnosticsSystem...")
    
    -- Set up remote event for client reporting
    self:setupRemoteEvent()
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("AssetDiagnosticsSystem", self)
        log("Registered with CoreRegistry")
    end
    
    -- Run initial asset scan if enabled
    if CONFIG.SCAN_ON_STARTUP then
        task.delay(5, function() -- Delay to allow game to load
            self:scanWorkspace()
        end)
    end
    
    -- Set up periodic scanning
    if CONFIG.PERIODIC_SCAN_INTERVAL > 0 then
        task.spawn(function()
            while true do
                task.wait(CONFIG.PERIODIC_SCAN_INTERVAL)
                self:scanWorkspace()
            end
        end)
    end
    
    self.initialized = true
    log("AssetDiagnosticsSystem initialized successfully")
    return true
end

-- Set up remote event for client reporting
function AssetDiagnosticsSystem:setupRemoteEvent()
    -- Check if event already exists
    self.remoteEvent = ReplicatedStorage:FindFirstChild("AssetLoadFailureReport")
    
    if not self.remoteEvent then
        -- Create new event
        self.remoteEvent = Instance.new("RemoteEvent")
        self.remoteEvent.Name = "AssetLoadFailureReport"
        self.remoteEvent.Parent = ReplicatedStorage
        log("Created AssetLoadFailureReport RemoteEvent")
    end
    
    -- Connect to event
    self.remoteEvent.OnServerEvent:Connect(function(player, assetId, status)
        self:recordAssetFailure(assetId, status, player)
    end)
    
    log("Set up remote event for client reporting")
end

-- Record an asset failure
function AssetDiagnosticsSystem:recordAssetFailure(assetId, errorStatus, player)
    if not assetId then return end
    
    -- Update stats
    self.assetStats.totalFailures += 1
    
    -- Add to failed assets or increment count
    self.assetStats.failedAssets[assetId] = (self.assetStats.failedAssets[assetId] or 0) + 1
    
    -- Categorize by asset type
    local assetType = self:getAssetType(assetId)
    self.assetStats.byAssetType[assetType] = (self.assetStats.byAssetType[assetType] or 0) + 1
    
    -- Categorize by error type
    local errorType = typeof(errorStatus) == "string" and errorStatus or "unknown"
    self.assetStats.byErrorType[errorType] = (self.assetStats.byErrorType[errorType] or 0) + 1
    
    -- Add to recent issues
    table.insert(self.assetStats.recentIssues, 1, {
        assetId = assetId,
        errorStatus = errorStatus,
        timestamp = os.time(),
        player = player and player.Name or "Server",
        assetType = assetType
    })
    
    -- Trim recent issues
    while #self.assetStats.recentIssues > CONFIG.MAX_TRACKED_ASSETS do
        table.remove(self.assetStats.recentIssues)
    end
    
    -- Log if this asset has failed multiple times
    if self.assetStats.failedAssets[assetId] >= CONFIG.REPORT_THRESHOLD then
        log("Asset " .. assetId .. " has failed " .. self.assetStats.failedAssets[assetId] .. " times", "warn")
    end
end

-- Get asset type from asset ID
function AssetDiagnosticsSystem:getAssetType(assetId)
    -- Extract the number portion of the asset ID
    local idNum = assetId:match("(%d+)")
    if not idNum then return "other" end
    
    -- Check for common asset types based on usage in the ID
    if assetId:match("rbxassetid://") then
        -- Could be any type, try to determine from context
        if assetId:match("Image=") or assetId:match("Texture=") then
            return "image"
        elseif assetId:match("SoundId=") then
            return "sound"
        elseif assetId:match("MeshId=") then
            return "mesh"
        elseif assetId:match("AnimationId=") then
            return "animation"
        end
    end
    
    -- Default to "other"
    return "other"
end

-- Scan workspace for asset references
function AssetDiagnosticsSystem:scanWorkspace()
    log("Starting workspace asset scan...")
    
    local startTime = os.clock()
    local scannedCount = 0
    local issuesFound = 0
    
    -- Helper function to scan an instance and its descendants
    local function scanInstance(instance)
        scannedCount += 1
        
        -- Check for common asset properties
        if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
            if instance.Image ~= "" and not instance.Image:match("^rbxasset") then
                -- Check the image
                task.spawn(function()
                    local success = self:validateAsset(instance.Image)
                    if not success then
                        issuesFound += 1
                        log("Found problematic image: " .. instance.Image .. " in " .. instance:GetFullName(), "warn")
                    end
                end)
            end
        elseif instance:IsA("Sound") then
            if instance.SoundId ~= "" and not instance.SoundId:match("^rbxasset") then
                -- Check the sound
                task.spawn(function()
                    local success = self:validateAsset(instance.SoundId)
                    if not success then
                        issuesFound += 1
                        log("Found problematic sound: " .. instance.SoundId .. " in " .. instance:GetFullName(), "warn")
                    end
                end)
            end
        elseif instance:IsA("SpecialMesh") or instance:IsA("FileMesh") then
            if instance.MeshId ~= "" and not instance.MeshId:match("^rbxasset") then
                -- Check the mesh
                task.spawn(function()
                    local success = self:validateAsset(instance.MeshId)
                    if not success then
                        issuesFound += 1
                        log("Found problematic mesh: " .. instance.MeshId .. " in " .. instance:GetFullName(), "warn")
                    end
                end)
            end
        elseif instance:IsA("Animation") then
            if instance.AnimationId ~= "" and not instance.AnimationId:match("^rbxasset") then
                -- Check the animation
                task.spawn(function()
                    local success = self:validateAsset(instance.AnimationId)
                    if not success then
                        issuesFound += 1
                        log("Found problematic animation: " .. instance.AnimationId .. " in " .. instance:GetFullName(), "warn")
                    end
                end)
            end
        end
        
        -- Scan children
        for _, child in ipairs(instance:GetChildren()) do
            scanInstance(child)
        end
    end
    
    -- Start scan at workspace level
    task.spawn(function()
        pcall(function()
            scanInstance(game.Workspace)
            scanInstance(game.ReplicatedStorage)
            scanInstance(game.ServerStorage)
            scanInstance(game.StarterGui)
            scanInstance(game.StarterPack)
        end)
        
        log("Workspace scan complete in " .. string.format("%.2f", os.clock() - startTime) .. " seconds")
        log("Scanned " .. scannedCount .. " instances, found " .. issuesFound .. " issues")
    end)
end

-- Validate a single asset
function AssetDiagnosticsSystem:validateAsset(assetId)
    if not assetId or assetId == "" then return true end
    
    -- Check if already known to be problematic
    if self.assetStats.failedAssets[assetId] and self.assetStats.failedAssets[assetId] >= CONFIG.REPORT_THRESHOLD then
        return false
    end
    
    -- Try to preload the asset
    local success = true
    
    -- For basic validation, we'll use a pcall without actually loading
    -- Real validation would use ContentProvider.PreloadAsync
    pcall(function()
        -- This is just a placeholder as actual preloading can be resource-intensive
        if assetId:match("00000") then -- Example of an invalid ID pattern
            success = false
        end
    end)
    
    return success
end

-- Get diagnostic report
function AssetDiagnosticsSystem:getDiagnosticReport()
    -- Count total failed assets
    local totalFailedAssets = 0
    for _ in pairs(self.assetStats.failedAssets) do
        totalFailedAssets += 1
    end
    
    -- Build report
    return {
        totalFailures = self.assetStats.totalFailures,
        uniqueFailedAssets = totalFailedAssets,
        byAssetType = self.assetStats.byAssetType,
        byErrorType = self.assetStats.byErrorType,
        recentIssues = self.assetStats.recentIssues,
        reportTime = os.time()
    }
end

-- Create diagnostic command for developers
function AssetDiagnosticsSystem:createDiagnosticCommand()
    -- Create a BindableFunction in ReplicatedStorage
    local diagnosticFunction = Instance.new("BindableFunction")
    diagnosticFunction.Name = "GetAssetDiagnostics"
    
    -- Set the OnInvoke function
    diagnosticFunction.OnInvoke = function()
        return self:getDiagnosticReport()
    end
    
    -- Add to SharedFunctions folder or create if it doesn't exist
    local sharedFunctions = ReplicatedStorage:FindFirstChild("SharedFunctions")
    if not sharedFunctions then
        sharedFunctions = Instance.new("Folder")
        sharedFunctions.Name = "SharedFunctions"
        sharedFunctions.Parent = ReplicatedStorage
    end
    
    diagnosticFunction.Parent = sharedFunctions
    log("Created diagnostic command in SharedFunctions")
end

-- Automatically initialize
task.spawn(function()
    AssetDiagnosticsSystem:initialize()
    AssetDiagnosticsSystem:createDiagnosticCommand()
end)

return AssetDiagnosticsSystem
