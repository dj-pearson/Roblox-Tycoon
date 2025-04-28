--[[
    AssetFailureLogger.server.luau
    
    Server-side component for handling asset loading failures reported by clients.
    This script collects, aggregates, and logs information about assets that fail to load.
    
    Created: April 28, 2025
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    STORE_FAILURE_DATA = true,
    MAX_FAILURES_PER_ASSET = 100, -- Cap reports per asset ID
    FAILURE_DATA_STORE_NAME = "AssetFailureReports",
    REPORT_INTERVAL = 600, -- 10 minutes
    SORT_BY_FREQUENCY = true,
    UPLOAD_TO_SERVER = false, -- If you have an external server for collecting data
    SERVER_ENDPOINT = "https://your-api.example.com/asset-reports" -- Change if used
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_MODE then
        print("[AssetFailureLogger] " .. message)
    end
end

-- Failure tracking
local failureReports = {
    byAsset = {}, -- Indexed by asset ID
    byPlayer = {}, -- Indexed by player ID
    totalReports = 0,
    sessionStart = os.time()
}

-- Initialize data storage if enabled
local failureDataStore
if CONFIG.STORE_FAILURE_DATA then
    local success, result = pcall(function()
        return DataStoreService:GetDataStore(CONFIG.FAILURE_DATA_STORE_NAME)
    end)
    
    if success then
        failureDataStore = result
        log("Data store initialized for asset failure reports")
    else
        warn("[AssetFailureLogger] Failed to get data store: " .. tostring(result))
    end
end

-- Process an asset failure report from a client
local function processFailureReport(player, assetId, status)
    if not player or not assetId then return end
    
    -- Convert to string if needed
    assetId = tostring(assetId)
    
    -- Initialize asset entry if new
    if not failureReports.byAsset[assetId] then
        failureReports.byAsset[assetId] = {
            count = 0,
            players = {},
            firstReported = os.time(),
            lastReported = os.time()
        }
    end
    
    -- Initialize player entry if new
    local userId = tostring(player.UserId)
    if not failureReports.byPlayer[userId] then
        failureReports.byPlayer[userId] = {
            count = 0,
            assets = {},
            playerName = player.Name
        }
    end
    
    -- Update asset entry
    local assetEntry = failureReports.byAsset[assetId]
    assetEntry.count = assetEntry.count + 1
    assetEntry.lastReported = os.time()
    assetEntry.players[userId] = true
    
    -- Update player entry
    local playerEntry = failureReports.byPlayer[userId]
    playerEntry.count = playerEntry.count + 1
    if not playerEntry.assets[assetId] then
        playerEntry.assets[assetId] = 0
    end
    playerEntry.assets[assetId] = playerEntry.assets[assetId] + 1
    
    -- Update totals
    failureReports.totalReports = failureReports.totalReports + 1
    
    -- Log if this is a frequently failing asset
    if assetEntry.count % 10 == 0 then
        log("Asset ID " .. assetId .. " has failed " .. assetEntry.count .. " times this session")
    end
    
    -- Cap reports per asset to prevent memory issues
    if assetEntry.count >= CONFIG.MAX_FAILURES_PER_ASSET then
        log("Asset ID " .. assetId .. " has reached the reporting cap")
    end
end

-- Generate a summary report of asset failures
local function generateSummaryReport()
    local sortedAssets = {}
    
    -- Convert to array for sorting
    for assetId, data in pairs(failureReports.byAsset) do
        table.insert(sortedAssets, {
            id = assetId,
            count = data.count,
            playerCount = 0,
            firstReported = data.firstReported,
            lastReported = data.lastReported
        })
        
        -- Count unique players affected
        for _ in pairs(data.players) do
            sortedAssets[#sortedAssets].playerCount = sortedAssets[#sortedAssets].playerCount + 1
        end
    end
    
    -- Sort by failure count if enabled
    if CONFIG.SORT_BY_FREQUENCY then
        table.sort(sortedAssets, function(a, b)
            return a.count > b.count
        end)
    end
    
    -- Format the report
    local report = {
        timestamp = os.time(),
        sessionDuration = os.time() - failureReports.sessionStart,
        totalReports = failureReports.totalReports,
        uniqueAssets = #sortedAssets,
        uniquePlayers = 0,
        top10Assets = {},
        playerCount = #Players:GetPlayers()
    }
    
    -- Count unique players
    for _ in pairs(failureReports.byPlayer) do
        report.uniquePlayers = report.uniquePlayers + 1
    end
    
    -- Add top 10 most frequently failing assets
    for i = 1, math.min(10, #sortedAssets) do
        table.insert(report.top10Assets, {
            assetId = sortedAssets[i].id,
            count = sortedAssets[i].count,
            playerCount = sortedAssets[i].playerCount
        })
    end
    
    return report
end

-- Save failure data to DataStore
local function saveFailureData()
    if not failureDataStore then return false end
    
    -- Generate a report
    local report = generateSummaryReport()
    local reportKey = "Report_" .. os.time()
    
    -- Add details for top failing assets
    local detailedReport = {}
    for assetId, data in pairs(failureReports.byAsset) do
        -- Only store details for assets that failed 5+ times
        if data.count >= 5 then
            detailedReport[assetId] = {
                count = data.count,
                firstReported = data.firstReported,
                lastReported = data.lastReported,
                playerCount = 0
            }
            
            -- Count unique players
            for _ in pairs(data.players) do
                detailedReport[assetId].playerCount = detailedReport[assetId].playerCount + 1
            end
        end
    end
    
    -- Attempt to save the report
    local success, result = pcall(function()
        return failureDataStore:SetAsync(reportKey, {
            summary = report,
            details = detailedReport
        })
    end)
    
    if success then
        log("Saved failure report: " .. reportKey)
        return true
    else
        warn("[AssetFailureLogger] Failed to save report: " .. tostring(result))
        return false
    end
end

-- Upload report to external server if configured
local function uploadReportToServer()
    if not CONFIG.UPLOAD_TO_SERVER then return false end
    
    local report = generateSummaryReport()
    local HttpService = game:GetService("HttpService")
    
    local success, result = pcall(function()
        return HttpService:PostAsync(
            CONFIG.SERVER_ENDPOINT,
            HttpService:JSONEncode(report),
            Enum.HttpContentType.ApplicationJson
        )
    end)
    
    if success then
        log("Uploaded report to external server")
        return true
    else
        warn("[AssetFailureLogger] Failed to upload report: " .. tostring(result))
        return false
    end
end

-- Print a summary to the output
local function printSummaryReport()
    local report = generateSummaryReport()
    
    log("===== ASSET FAILURE SUMMARY =====")
    log(string.format("Session Time: %.1f hours", report.sessionDuration / 3600))
    log(string.format("Total Reports: %d from %d players", report.totalReports, report.uniquePlayers))
    log(string.format("Unique Failing Assets: %d", report.uniqueAssets))
    log("Top Failing Assets:")
    
    for i, asset in ipairs(report.top10Assets) do
        log(string.format("%d. Asset ID %s - %d failures across %d players", 
            i, asset.assetId, asset.count, asset.playerCount))
    end
    
    log("================================")
end

-- Set up event handler for client reports
local function setupEventHandler()
    local reportEvent = ReplicatedStorage:FindFirstChild("AssetLoadFailureReport")
    
    if not reportEvent then
        reportEvent = Instance.new("RemoteEvent")
        reportEvent.Name = "AssetLoadFailureReport"
        reportEvent.Parent = ReplicatedStorage
        log("Created AssetLoadFailureReport event")
    end
    
    -- Connect handler
    reportEvent.OnServerEvent:Connect(function(player, assetId, status)
        processFailureReport(player, assetId, status)
    end)
    
    log("Asset failure report handler connected")
end

-- Schedule periodic reporting
local function scheduleReporting()
    task.spawn(function()
        while task.wait(CONFIG.REPORT_INTERVAL) do
            -- Only generate reports if we have data
            if failureReports.totalReports > 0 then
                printSummaryReport()
                
                if CONFIG.STORE_FAILURE_DATA then
                    saveFailureData()
                end
                
                if CONFIG.UPLOAD_TO_SERVER then
                    uploadReportToServer()
                end
            end
        end
    end)
    
    log("Scheduled periodic reporting every " .. CONFIG.REPORT_INTERVAL .. " seconds")
end

-- Initialize the system
local function initialize()
    log("Initializing Asset Failure Logger")
    
    setupEventHandler()
    scheduleReporting()
    
    log("Asset Failure Logger initialized successfully")
end

-- Initialize automatically
initialize()

return {
    generateSummaryReport = generateSummaryReport,
    printSummaryReport = printSummaryReport,
    saveFailureData = saveFailureData
}
