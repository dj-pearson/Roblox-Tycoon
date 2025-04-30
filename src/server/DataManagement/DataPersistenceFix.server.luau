--!strict
-- DataPersistenceFix.server.luau
-- Enhances data persistence and recovery for player data
-- Created on April 29, 2025 to fix critical data persistence issues

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants
local SAVE_INTERVAL = 60 -- Save every 60 seconds
local BACKUP_SAVE_INTERVAL = 300 -- Backup save every 5 minutes
local MAX_RETRIES = 3 -- Maximum retry attempts for saving data
local RETRY_DELAY = 5 -- Seconds between retry attempts

-- Primary and backup datastores
local PlayerDataStore = DataStoreService:GetDataStore("PlayerTycoonData_v1")
local BackupDataStore = DataStoreService:GetDataStore("PlayerTycoonDataBackup_v1")

-- Track save operations for diagnostics
local saveOperationsStats = {
    totalSaves = 0,
    successfulSaves = 0,
    failedSaves = 0,
    lastSaveTime = 0,
    backupSaves = 0
}

-- Data validation and conversion helpers
local function safelySerializeValue(value, valueType)
    if valueType == "StringValue" then
        return tostring(value) or ""
    elseif valueType == "BoolValue" then
        return value == true
    elseif valueType == "IntValue" then
        return math.floor(tonumber(value) or 0)
    elseif valueType == "NumberValue" then
        return tonumber(value) or 0
    else
        return value
    end
end

-- Properly extract a value from an instance
local function getInstanceValue(instance)
    if not instance then return nil end
    if instance:IsA("StringValue") then
        return instance.Value
    elseif instance:IsA("BoolValue") then
        return instance.Value
    elseif instance:IsA("IntValue") or instance:IsA("NumberValue") then
        return instance.Value
    elseif instance:IsA("Folder") or instance:IsA("Model") then
        -- For collection instances, return a dictionary of child values
        local values = {}
        for _, child in pairs(instance:GetChildren()) do
            values[child.Name] = getInstanceValue(child)
        end
        return values
    end
    return nil
end

-- Get player data from Tycoon folder structure
local function extractPlayerData(player)
    local data = {
        lastUpdated = os.time(),
        playerName = player.Name,
        userId = player.UserId
    }
    
    -- Check if Tycoon folder exists
    local tycoonFolder = player:FindFirstChild("Tycoon")
    if not tycoonFolder then
        warn("[DataPersistenceFix] Tycoon folder missing for player: " .. player.Name)
        return nil
    end
    
    -- Extract data from each main folder
    for _, mainFolder in pairs(tycoonFolder:GetChildren()) do
        if mainFolder:IsA("Folder") then
            data[mainFolder.Name] = getInstanceValue(mainFolder)
        end
    end
    
    return data
end

-- Save player data with retry mechanism
local function savePlayerData(player, isBackup)
    local playerKey = "Player_" .. player.UserId
    
    -- Extract player data
    local playerData = extractPlayerData(player)
    if not playerData then
        warn("[DataPersistenceFix] Failed to extract data for player: " .. player.Name)
        saveOperationsStats.failedSaves += 1
        return false
    end
    
    -- Add metadata
    playerData.lastSaved = os.time()
    playerData.saveType = isBackup and "backup" or "regular"
    
    -- Try to save with retries
    local success = false
    local errorMessage = ""
    
    for attempt = 1, MAX_RETRIES do
        success, errorMessage = pcall(function()
            local dataStore = isBackup and BackupDataStore or PlayerDataStore
            dataStore:SetAsync(playerKey, playerData)
        end)
        
        if success then
            print(string.format("[DataPersistenceFix] %s save successful for: %s (Attempt %d)",
                isBackup and "Backup" or "Regular", player.Name, attempt))
            break
        else
            warn(string.format("[DataPersistenceFix] Save attempt %d failed for %s: %s", 
                attempt, player.Name, errorMessage))
            
            if attempt < MAX_RETRIES then
                task.wait(RETRY_DELAY)
            end
        end
    end
    
    -- Update stats
    saveOperationsStats.totalSaves += 1
    if success then
        saveOperationsStats.successfulSaves += 1
        if isBackup then
            saveOperationsStats.backupSaves += 1
        end
    else
        saveOperationsStats.failedSaves += 1
    end
    
    saveOperationsStats.lastSaveTime = os.time()
    return success
end

-- Save data for all players
local function saveAllPlayerData()
    print("[DataPersistenceFix] Saving data for all players...")
    local savedCount = 0
    local playerCount = #Players:GetPlayers()
    
    for _, player in ipairs(Players:GetPlayers()) do
        local success = savePlayerData(player, false) -- Regular save
        if success then
            savedCount += 1
        end
    end
    
    print(string.format("[DataPersistenceFix] Saved %d/%d player data records", savedCount, playerCount))
    return savedCount
end

-- Save backup data for all players
local function saveAllPlayerBackupData()
    print("[DataPersistenceFix] Creating backup save for all players...")
    local savedCount = 0
    local playerCount = #Players:GetPlayers()
    
    for _, player in ipairs(Players:GetPlayers()) do
        local success = savePlayerData(player, true) -- Backup save
        if success then
            savedCount += 1
        end
    end
    
    print(string.format("[DataPersistenceFix] Backed up %d/%d player data records", savedCount, playerCount))
    return savedCount
end

-- Load player data
local function loadPlayerData(player)
    local playerKey = "Player_" .. player.UserId
    local data = nil
    local isBackupUsed = false
    local success, result = pcall(function()
        return PlayerDataStore:GetAsync(playerKey)
    end)
    
    if success and result then
        data = result
    else
        warn(string.format("[DataPersistenceFix] Failed to load data for %s, trying backup: %s", 
            player.Name, tostring(result)))
        
        -- Try backup
        success, result = pcall(function()
            return BackupDataStore:GetAsync(playerKey)
        end)
        
        if success and result then
            data = result
            isBackupUsed = true
            warn(string.format("[DataPersistenceFix] Loaded backup data for %s (last saved: %s)", 
                player.Name, os.date("%Y-%m-%d %H:%M:%S", result.lastSaved or 0)))
        else
            warn(string.format("[DataPersistenceFix] Failed to load backup data for %s: %s", 
                player.Name, tostring(result)))
        end
    end
    
    return data, isBackupUsed
end

-- Event handlers
local function onPlayerAdded(player)
    print("[DataPersistenceFix] Player added: " .. player.Name)
    
    -- Load player data - delayed to ensure Tycoon folder is created first
    task.delay(2, function()
        local playerData, usedBackup = loadPlayerData(player)
        
        -- Check if we have data to restore
        if playerData then
            print(string.format("[DataPersistenceFix] Loaded %s data for: %s", 
                usedBackup and "backup" or "primary", player.Name))
            
            -- Check if the Tycoon folder exists (should be created by TycoonFolderInitializer)
            local tycoonFolder = player:FindFirstChild("Tycoon")
            if not tycoonFolder then
                warn("[DataPersistenceFix] Tycoon folder missing after initialization for: " .. player.Name)
                -- We'll rely on the TycoonFolderInitializer to create it
                return
            end
            
            -- Apply loaded data to each folder
            for folderName, folderData in pairs(playerData) do
                -- Skip metadata fields
                if folderName ~= "lastUpdated" and folderName ~= "playerName" and 
                   folderName ~= "userId" and folderName ~= "lastSaved" and folderName ~= "saveType" then
                    
                    local folder = tycoonFolder:FindFirstChild(folderName)
                    if folder and typeof(folderData) == "table" then
                        -- Apply values to this folder
                        for valueName, value in pairs(folderData) do
                            local valueInstance = folder:FindFirstChild(valueName)
                            if valueInstance then
                                if valueInstance:IsA("StringValue") then
                                    valueInstance.Value = tostring(value) or ""
                                elseif valueInstance:IsA("BoolValue") then
                                    valueInstance.Value = value == true
                                elseif valueInstance:IsA("IntValue") then
                                    valueInstance.Value = math.floor(tonumber(value) or 0)
                                elseif valueInstance:IsA("NumberValue") then
                                    valueInstance.Value = tonumber(value) or 0
                                end
                            end
                        end
                    end
                end
            end
            
            print("[DataPersistenceFix] Successfully restored data for: " .. player.Name)
        else
            print("[DataPersistenceFix] No saved data found for: " .. player.Name .. ", using defaults")
        end
    end)
end

local function onPlayerRemoving(player)
    print("[DataPersistenceFix] Player removing: " .. player.Name)
    
    -- Save player data when they leave
    local success = savePlayerData(player, false)
    if success then
        -- Also create a backup if successful
        savePlayerData(player, true)
    end
end

-- Set up periodic saving
task.spawn(function()
    while true do
        task.wait(SAVE_INTERVAL)
        saveAllPlayerData()
    end
end)

-- Set up periodic backup saving
task.spawn(function()
    while true do
        task.wait(BACKUP_SAVE_INTERVAL)
        saveAllPlayerBackupData()
    end
end)

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle server shutdown
game:BindToClose(function()
    print("[DataPersistenceFix] Server shutting down, saving all player data...")
    local savedCount = saveAllPlayerData()
    print(string.format("[DataPersistenceFix] Saved %d player data records during shutdown", savedCount))
end)

-- Save existing players' data on script start
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        onPlayerAdded(player)
    end)
end

-- Public API for other systems to interact with
local API = {}

-- Force an immediate save for a player
function API.forceSave(player)
    return savePlayerData(player, false)
end

-- Force an immediate backup save for a player
function API.forceBackupSave(player)
    return savePlayerData(player, true)
end

-- Get save operation stats
function API.getStats()
    return saveOperationsStats
end

print("[DataPersistenceFix] Initialized and active")
return API
