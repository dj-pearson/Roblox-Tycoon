-- DataManager.luau
-- Unified system for player data storage with redundancy and automatic retries
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- Get the CoreRegistry and EventBridge
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")

-- Configuration
local CONFIG = {
    dataStoreEnabled = true,      -- Set to false for testing to avoid API limits
    autoSaveInterval = 120,       -- How often to auto-save player data (seconds)
    backupInterval = 600,         -- How often to save backup data (seconds)
    maxRetries = 5,               -- Max retries for data operations
    retryDelay = 5,               -- Seconds between retries
    sessionLockTime = 600,        -- Time in seconds for session locks
    maxDataStoreVersions = 3,     -- How many versions of player data to store
    
    -- Keys
    mainDataKey = "GymTycoonData",
    backupDataKey = "GymTycoonBackupData",
    keyVersionKey = "GymTycoonVersionKeys",
    equipmentKey = "GymEquipment",
    milestonesKey = "GymMilestones",
    specialtyKey = "GymSpecialty",
    membershipKey = "GymMemberships",
    vipKey = "GymVIPs",
    revenueKey = "GymRevenue",
    staffKey = "GymStaff",
    achievementsKey = "GymAchievements",
    seasonalKey = "GymSeasonal",
    
    -- Data structure version - increment this when you make breaking changes
    dataVersion = 2
}

-- Create the DataManager
local DataManager = {
    playerData = {},
    dataCache = {},
    saveQueue = {},
    saveLocks = {},
    sessionLocks = {},
    dataStores = {},
    orderedStores = {}
}

-- Debug function
local function log(...)
    print("[DataManager]", ...)
end

-- Check if a value should be considered corrupted data
local function isCorruptedData(value)
    -- Check if it's a typical error code from data store corruption
    if type(value) == "string" then
        if string.match(value, "501") or string.match(value, "504") then
            return true
        end
    end
    
    -- We expect a table for player data
    if type(value) ~= "table" then
        return true
    end
    
    return false
end

-- Initialize data stores
function DataManager:initDataStores()
    if CONFIG.dataStoreEnabled then
        local success, result = pcall(function()
            self.dataStores = {
                main = DataStoreService:GetDataStore(CONFIG.mainDataKey),
                backup = DataStoreService:GetDataStore(CONFIG.backupDataKey),
                equipment = DataStoreService:GetDataStore(CONFIG.equipmentKey),
                milestones = DataStoreService:GetDataStore(CONFIG.milestonesKey),
                specialty = DataStoreService:GetDataStore(CONFIG.specialtyKey),
                memberships = DataStoreService:GetDataStore(CONFIG.membershipKey),
                vips = DataStoreService:GetDataStore(CONFIG.vipKey),
                revenue = DataStoreService:GetDataStore(CONFIG.revenueKey),
                staff = DataStoreService:GetDataStore(CONFIG.staffKey),
                achievements = DataStoreService:GetDataStore(CONFIG.achievementsKey),
                seasonal = DataStoreService:GetDataStore(CONFIG.seasonalKey)
            }
            
            -- Initialize ordered data stores for versioning (Berezaa's method)
            self.orderedStores = {
                versionKeys = DataStoreService:GetOrderedDataStore(CONFIG.keyVersionKey)
            }
        end)
        
        if not success then
            log("Failed to initialize DataStores: " .. tostring(result))
            self.dataStores = {}
            self.orderedStores = {}
            return false
        end
        
        log("DataStores initialized successfully")
        return true
    else
        log("DataStore disabled in configuration")
        return true
    end
end

-- Initialize the module
function DataManager:initialize()
    log("Initializing DataManager...")
    
    -- Initialize data stores
    local storesReady = self:initDataStores()
    if not storesReady then
        log("Warning: DataStores not ready")
    end
    
    -- Set up auto-save interval
    task.spawn(function()
        while task.wait(CONFIG.autoSaveInterval) do
            self:saveAllPlayerData(false) -- Not immediate
        end
    end)
    
    -- Set up backup interval
    task.spawn(function()
        while task.wait(CONFIG.backupInterval) do
            self:backupAllPlayerData()
        end
    end)
    
    -- Set up player join/leave handling
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerJoin(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerLeave(player)
    end)
    
    -- Handle server shutdown
    game:BindToClose(function()
        self:onServerShutdown()
    end)
    
    log("DataManager initialized")
    return true
end

-- Get default data structure for a new player
function DataManager:getDefaultData()
    return {
        cash = 1000,
        lastJoin = os.time(),
        gymTier = 1,
        equipmentCount = 0,
        milestones = {},
        specialization = "none",
        equipment = {},
        achievements = {},
        
        -- New fields for improved data storage
        members = {
            regular = 0,
            vip = 0,
            premium = 0,
            total = 0
        },
        
        revenue = {
            daily = 0,
            weekly = 0,
            total = 0,
            history = {}
        },
        
        staff = {
            trainers = {},
            cleaners = {},
            receptionists = {}
        },
        
        gym = {
            satisfaction = 100,
            cleanliness = 100,
            reputation = 0
        },
        
        competitions = {
            participated = 0,
            won = 0,
            lastParticipation = 0
        },
        
        rebirth = {
            level = 0,
            points = 0
        },
        
        seasonal = {
            eventParticipation = {},
            rewards = {}
        },
        
        settings = {
            musicVolume = 0.5,
            sfxVolume = 0.5,
            notifications = true
        },
        
        -- Important metadata
        sessionLock = nil,
        lastSave = os.time(),
        dataVersion = CONFIG.dataVersion
    }
end

-- Check and handle session lock
function DataManager:checkSessionLock(player, data)
    if not player or not data then return true end
    
    -- If no session lock exists, we're good to go
    if not data.sessionLock then
        return true
    end
    
    -- If session lock exists but is very old (over 30 minutes), we can override it
    local currentTime = os.time()
    local lockTime = data.sessionLock
    
    if type(lockTime) == "number" and (currentTime - lockTime) > 1800 then -- 30 minutes
        log("Session lock for " .. player.Name .. " is stale (over 30 minutes old), overriding it")
        return true
    end
    
    -- Active session lock exists, retry until it's gone
    log("Session lock detected for " .. player.Name .. ", waiting for it to clear...")
    
    -- Return false to indicate the session is locked
    return false
end

-- Get the latest version key for a player
function DataManager:getLatestVersionKey(userId)
    if not self.orderedStores.versionKeys or not CONFIG.dataStoreEnabled then
        return tostring(userId)
    end
    
    local key = tostring(userId)
    local success, result = pcall(function()
        -- Get the latest version number
        return self.orderedStores.versionKeys:GetAsync(key) or 1
    end)
    
    if success then
        return key .. "_v" .. tostring(result)
    else
        log("Failed to get version key for " .. key .. ": " .. tostring(result))
        return key
    end
end

-- Increment and get a new version key for a player
function DataManager:getNewVersionKey(userId)
    if not self.orderedStores.versionKeys or not CONFIG.dataStoreEnabled then
        return tostring(userId)
    end
    
    local key = tostring(userId)
    local success, result = pcall(function()
        -- Get and increment the version number
        local currentVersion = self.orderedStores.versionKeys:GetAsync(key) or 1
        local newVersion = currentVersion + 1
        
        -- Limit to max versions by cycling back to 1 if needed
        if newVersion > CONFIG.maxDataStoreVersions then
            newVersion = 1
        end
        
        -- Update the version number
        self.orderedStores.versionKeys:SetAsync(key, newVersion)
        
        return key .. "_v" .. tostring(newVersion)
    end)
    
    if success then
        return result
    else
        log("Failed to create new version key for " .. key .. ": " .. tostring(result))
        return key
    end
end

-- Try to load data from multiple versions
function DataManager:loadVersionedData(userId)
    if not CONFIG.dataStoreEnabled or not self.dataStores.main then
        return nil
    end
    
    local key = tostring(userId)
    local baseKey = key
    
    -- Try the latest version first
    local latestKey = self:getLatestVersionKey(userId)
    local success, data = pcall(function()
        return self.dataStores.main:GetAsync(latestKey)
    end)
    
    -- If successful and not corrupted, return this data
    if success and data and not isCorruptedData(data) then
        log("Successfully loaded latest version data with key: " .. latestKey)
        return data
    end
    
    log("Latest version failed or corrupted, trying older versions...")
    
    -- Try older versions
    for i = 1, CONFIG.maxDataStoreVersions do
        local versionKey = key .. "_v" .. tostring(i)
        
        success, data = pcall(function()
            return self.dataStores.main:GetAsync(versionKey)
        end)
        
        if success and data and not isCorruptedData(data) then
            log("Successfully loaded from older version: " .. versionKey)
            return data
        end
    end
    
    -- Try the base key without version as a last resort
    success, data = pcall(function()
        return self.dataStores.main:GetAsync(baseKey)
    end)
    
    if success and data and not isCorruptedData(data) then
        log("Successfully loaded from base key without version")
        return data
    end
    
    log("All versioned loads failed")
    return nil
end

-- Load player data with retries
function DataManager:loadData(player)
    if not player then return nil end
    
    local userId = player.UserId
    local key = tostring(userId)
    
    -- Check if data already loaded in memory
    if self.playerData[userId] then
        return self.playerData[userId]
    end
    
    -- Default data
    local data = self:getDefaultData()
    
    -- Load from DataStore if enabled
    if CONFIG.dataStoreEnabled and self.dataStores.main then
        local attempts = 0
        local sessionLocked = true
        
        -- Keep trying until we can unlock the session or hit max retries
        while sessionLocked and attempts < CONFIG.maxRetries do
            attempts = attempts + 1
            
            -- Try to load versioned data
            local versionedData = self:loadVersionedData(userId)
            
            -- If we got data, check session lock
            if versionedData then
                sessionLocked = not self:checkSessionLock(player, versionedData)
                
                if not sessionLocked then
                    -- We have unlocked data, use it
                    data = versionedData
                    log("Successfully loaded unlocked data for " .. player.Name)
                    break
                end
            else
                -- No data found, not locked
                sessionLocked = false
                log("No existing data found for " .. player.Name)
                break
            end
            
            -- If still locked, wait before retry
            if sessionLocked then
                log("Session still locked for " .. player.Name .. ", retry in " .. CONFIG.retryDelay .. "s")
                task.wait(CONFIG.retryDelay)
            end
        end
        
        -- If all attempts failed due to session lock
        if sessionLocked then
            log("Failed to unlock session for " .. player.Name .. " after " .. attempts .. " attempts")
            -- Here we could kick the player with a message
            player:Kick("Your data is being used in another server. Please try again in a few minutes.")
            return nil
        end
        
        -- Migrate data structure if needed
        data = self:migrateDataIfNeeded(data)
        
        -- Set session lock
        data.sessionLock = os.time()
        
        -- Try to load additional data stores
        self:loadAdditionalData(player, data)
    else
        log("Using default data for " .. player.Name)
    end
    
    -- Store in memory
    self.playerData[userId] = data
    
    -- Apply to player
    self:applyDataToPlayer(player, data)
    
    log("Loaded data for " .. player.Name)
    return data
end

-- Update data structure if version changes
function DataManager:migrateDataIfNeeded(data)
    if not data then return self:getDefaultData() end
    
    -- Check if migration is needed
    if not data.dataVersion or data.dataVersion < CONFIG.dataVersion then
        log("Migrating data from version " .. (data.dataVersion or "unknown") .. " to " .. CONFIG.dataVersion)
        
        local newData = self:getDefaultData()
        
        -- Copy all existing fields that match
        for key, value in pairs(data) do
            if newData[key] ~= nil then
                -- Copy existing data for fields that already exist
                newData[key] = value
            end
        end
        
        -- Manual migrations for changed structures
        if data.dataVersion == 1 then
            -- Example of migrating from v1 to v2
            -- Convert old members count to new structure if it exists
            if data.memberCount then
                newData.members.regular = data.memberCount
                newData.members.total = data.memberCount
            end
            
            -- Convert old revenue to new structure if it exists
            if data.totalRevenue then
                newData.revenue.total = data.totalRevenue
            end
        end
        
        -- Set the new version
        newData.dataVersion = CONFIG.dataVersion
        
        return newData
    end
    
    return data
end

-- Load additional data from secondary data stores
function DataManager:loadAdditionalData(player, data)
    if not player or not data then return end
    
    local userId = player.UserId
    local key = tostring(userId)
    
    -- Load equipment data
    if self.dataStores.equipment then
        pcall(function()
            local equipmentData = self.dataStores.equipment:GetAsync(key)
            if equipmentData then
                data.equipment = equipmentData
                log("Loaded equipment data for " .. player.Name)
            end
        end)
    end
    
    -- Load milestone data
    if self.dataStores.milestones then
        pcall(function()
            local milestoneData = self.dataStores.milestones:GetAsync(key)
            if milestoneData then
                data.milestones = milestoneData
                log("Loaded milestone data for " .. player.Name)
            end
        end)
    end
    
    -- Load specialization data
    if self.dataStores.specialty then
        pcall(function()
            local specialtyData = self.dataStores.specialty:GetAsync(key)
            if specialtyData then
                data.specialization = specialtyData
                log("Loaded specialization data for " .. player.Name)
            end
        end)
    end
    
    -- Load membership data
    if self.dataStores.memberships then
        pcall(function()
            local membershipData = self.dataStores.memberships:GetAsync(key)
            if membershipData then
                data.members = membershipData
                log("Loaded membership data for " .. player.Name)
            end
        end)
    end
    
    -- Load VIP data
    if self.dataStores.vips then
        pcall(function()
            local vipData = self.dataStores.vips:GetAsync(key)
            if vipData and vipData.vips then
                data.members.vip = vipData.vips
                data.members.premium = vipData.premium or 0
                log("Loaded VIP data for " .. player.Name)
            end
        end)
    end
    
    -- Load revenue data
    if self.dataStores.revenue then
        pcall(function()
            local revenueData = self.dataStores.revenue:GetAsync(key)
            if revenueData then
                data.revenue = revenueData
                log("Loaded revenue data for " .. player.Name)
            end
        end)
    end
    
    -- Load staff data
    if self.dataStores.staff then
        pcall(function()
            local staffData = self.dataStores.staff:GetAsync(key)
            if staffData then
                data.staff = staffData
                log("Loaded staff data for " .. player.Name)
            end
        end)
    end
    
    -- Load achievements data
    if self.dataStores.achievements then
        pcall(function()
            local achievementsData = self.dataStores.achievements:GetAsync(key)
            if achievementsData then
                data.achievements = achievementsData
                log("Loaded achievements data for " .. player.Name)
            end
        end)
    end
    
    -- Load seasonal data
    if self.dataStores.seasonal then
        pcall(function()
            local seasonalData = self.dataStores.seasonal:GetAsync(key)
            if seasonalData then
                data.seasonal = seasonalData
                log("Loaded seasonal data for " .. player.Name)
            end
        end)
    end
end

-- Save player data with retries
function DataManager:saveData(player, immediate)
    if not player then return false end
    
    local userId = player.UserId
    local key = tostring(userId)
    
    -- If already saving, add to queue instead
    if self.saveLocks[userId] then
        self.saveQueue[userId] = true
        return false
    end
    
    -- Get data
    local data = self.playerData[userId]
    if not data then
        log("No data to save for " .. player.Name)
        return false
    end
    
    -- Update timestamp
    data.lastSave = os.time()
    
    -- Create save lock
    self.saveLocks[userId] = true
    
    -- If not immediate, defer save to prevent API throttling
    if not immediate then
        task.delay(math.random(1, 10), function()
            self:processSave(player, key, data)
        end)
        return true
    end
    
    -- Process save immediately
    return self:processSave(player, key, data)
end

-- Process the actual save operation with retries
function DataManager:processSave(player, key, data)
    if not player or not CONFIG.dataStoreEnabled then 
        self.saveLocks[player.UserId] = nil
        return false
    end
    
    local userId = player.UserId
    local success, result
    local attempts = 0
    
    -- Get a new version key for saving
    local versionKey = self:getNewVersionKey(userId)
    
    -- Try to save with retries
    while attempts < CONFIG.maxRetries do
        attempts = attempts + 1
        
        -- Try main save using UpdateAsync to prevent data overwrites
        if self.dataStores.main then
            success, result = pcall(function()
                return self.dataStores.main:UpdateAsync(versionKey, function(oldData)
                    -- Keep session lock if this is not a final save
                    if self.sessionLocks[userId] then
                        data.sessionLock = os.time()
                    else
                        data.sessionLock = nil
                    end
                    
                    return data
                end)
            end)
            
            if success then
                log("Successfully saved data for " .. player.Name .. " to key " .. versionKey)
                break
            else
                log("Failed to save data for " .. player.Name .. " (Attempt " .. attempts .. "): " .. tostring(result))
            end
        end
        
        -- Wait before retry
        if attempts < CONFIG.maxRetries then
            task.wait(CONFIG.retryDelay)
        end
    end
    
    -- Save additional data
    self:saveAdditionalData(player, data)
    
    -- Release lock
    self.saveLocks[player.UserId] = nil
    
    -- Check if queued for another save
    if self.saveQueue[player.UserId] then
        self.saveQueue[player.UserId] = nil
        self:saveData(player, false) -- Not immediate
    end
    
    return success
end

-- Save additional data to secondary DataStores
function DataManager:saveAdditionalData(player, data)
    if not player or not data or not CONFIG.dataStoreEnabled then return end
    
    local userId = player.UserId
    local key = tostring(userId)
    
    -- Save equipment data
    if self.dataStores.equipment and data.equipment then
        pcall(function()
            self.dataStores.equipment:UpdateAsync(key, function()
                return data.equipment
            end)
        end)
    end
    
    -- Save milestone data
    if self.dataStores.milestones and data.milestones then
        pcall(function()
            self.dataStores.milestones:UpdateAsync(key, function()
                return data.milestones
            end)
        end)
    end
    
    -- Save specialization data
    if self.dataStores.specialty and data.specialization then
        pcall(function()
            self.dataStores.specialty:UpdateAsync(key, function()
                return data.specialization
            end)
        end)
    end
    
    -- Save membership data
    if self.dataStores.memberships and data.members then
        pcall(function()
            self.dataStores.memberships:UpdateAsync(key, function()
                return data.members
            end)
        end)
    end
    
    -- Save VIP data
    if self.dataStores.vips and data.members then
        pcall(function()
            self.dataStores.vips:UpdateAsync(key, function()
                return {
                    vips = data.members.vip or 0,
                    premium = data.members.premium or 0
                }
            end)
        end)
    end
    
    -- Save revenue data
    if self.dataStores.revenue and data.revenue then
        pcall(function()
            self.dataStores.revenue:UpdateAsync(key, function()
                return data.revenue
            end)
        end)
    end
    
    -- Save staff data
    if self.dataStores.staff and data.staff then
        pcall(function()
            self.dataStores.staff:UpdateAsync(key, function()
                return data.staff
            end)
        end)
    end
    
    -- Save achievements data
    if self.dataStores.achievements and data.achievements then
        pcall(function()
            self.dataStores.achievements:UpdateAsync(key, function()
                return data.achievements
            end)
        end)
    end
    
    -- Save seasonal data
    if self.dataStores.seasonal and data.seasonal then
        pcall(function()
            self.dataStores.seasonal:UpdateAsync(key, function()
                return data.seasonal
            end)
        end)
    end
end

-- Create a backup of player data
function DataManager:backupPlayerData(player)
    if not player or not CONFIG.dataStoreEnabled then return false end
    
    local userId = player.UserId
    local key = tostring(userId)
    
    -- Get data
    local data = self.playerData[userId]
    if not data then
        return false
    end
    
    -- Save to backup DataStore
    if self.dataStores.backup then
        local success, result = pcall(function()
            self.dataStores.backup:UpdateAsync(key, function()
                return data
            end)
        end)
        
        if success then
            log("Created backup for " .. player.Name)
            return true
        else
            log("Failed to create backup for " .. player.Name .. ": " .. tostring(result))
            return false
        end
    end
    
    return false
end

-- Save all player data
function DataManager:saveAllPlayerData(immediate)
    log("Saving all player data...")
    
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            self:saveData(player, immediate)
        end)
    end
end

-- Backup all player data
function DataManager:backupAllPlayerData()
    log("Creating backups for all players...")
    
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            self:backupPlayerData(player)
        end)
    end
end

-- Handle player joining
function DataManager:onPlayerJoin(player)
    if not player then return end
    
    -- Set session lock
    self.sessionLocks[player.UserId] = true
    
    -- Load player data
    task.spawn(function()
        self:setupPlayer(player)
    end)
end

-- Handle player leaving
function DataManager:onPlayerLeave(player)
    if not player then return end
    
    local userId = player.UserId
    
    -- Save data immediately
    self:saveData(player, true)
    
    -- Clear session lock upon successful save
    self.sessionLocks[userId] = false
    
    -- Clean up memory
    task.delay(30, function()
        self.playerData[userId] = nil
        self.saveLocks[userId] = nil
        self.saveQueue[userId] = nil
        self.sessionLocks[userId] = nil
    end)
end

-- Handle server shutdown
function DataManager:onServerShutdown()
    log("Server shutting down, saving all data...")
    
    -- Save all player data immediately
    local allPlayers = Players:GetPlayers()
    local savedCount = 0
    local totalPlayers = #allPlayers
    
    -- Create a BindableEvent to wait for all saves to complete
    local saveCompleted = Instance.new("BindableEvent")
    
    for _, player in ipairs(allPlayers) do
        task.spawn(function()
            self:saveData(player, true)
            
            -- Track saves completed
            savedCount = savedCount + 1
            
            -- If all saved, fire completed event
            if savedCount >= totalPlayers then
                saveCompleted:Fire()
            end
        end)
    end
    
    -- If in Studio, wait a short time
    if RunService:IsStudio() then
        task.wait(2)
    else
        -- In production, wait for all saves or timeout after 25 seconds
        -- Roblox gives 30 seconds for BindToClose, so we need to finish before that
        local saveSuccess = false
        
        task.spawn(function()
            saveCompleted.Event:Wait()
            saveSuccess = true
        end)
        
        -- Wait up to 25 seconds
        local startTime = os.clock()
        while not saveSuccess and (os.clock() - startTime) < 25 do
            task.wait(0.1)
        end
        
        log("Shutdown save completed for " .. savedCount .. " out of " .. totalPlayers .. " players")
    end
    
    -- Clear session locks for all players
    for userId, _ in pairs(self.sessionLocks) do
        local key = tostring(userId)
        pcall(function()
            self.dataStores.main:UpdateAsync(key, function(oldData)
                if oldData and type(oldData) == "table" then
                    oldData.sessionLock = nil
                    return oldData
                end
                return nil
            end)
        end)
    end
end

-- Apply data values to player
function DataManager:applyDataToPlayer(player, data)
    if not player or not data then return false end
    
    -- Update leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    -- Set cash
    local cashValue = leaderstats:FindFirstChild("Cash")
    if not cashValue then
        cashValue = Instance.new("IntValue")
        cashValue.Name = "Cash"
        cashValue.Parent = leaderstats
    end
    cashValue.Value = data.cash or 1000
    
    -- Set gym tier
    local tierValue = leaderstats:FindFirstChild("GymTier")
    if not tierValue then
        tierValue = Instance.new("IntValue")
        tierValue.Name = "GymTier"
        tierValue.Parent = leaderstats
    end
    tierValue.Value = data.gymTier or 1
    
    -- Set members count
    local membersValue = leaderstats:FindFirstChild("Members")
    if not membersValue then
        membersValue = Instance.new("IntValue")
        membersValue.Name = "Members"
        membersValue.Parent = leaderstats
    end
    membersValue.Value = (data.members and data.members.total) or 0
    
    -- Set tycoon attributes
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon then
        tycoon:SetAttribute("GymTier", data.gymTier or 1)
        tycoon:SetAttribute("EquipmentCount", data.equipmentCount or 0)
        tycoon:SetAttribute("Specialization", data.specialization or "none")
        tycoon:SetAttribute("MemberCount", (data.members and data.members.total) or 0)
        tycoon:SetAttribute("VIPCount", (data.members and data.members.vip) or 0)
        tycoon:SetAttribute("PremiumCount", (data.members and data.members.premium) or 0)
        tycoon:SetAttribute("Satisfaction", (data.gym and data.gym.satisfaction) or 100)
        tycoon:SetAttribute("TotalRevenue", (data.revenue and data.revenue.total) or 0)
    end
    
    log("Applied data to " .. player.Name)
    return true
end

-- Restore purchased equipment
function DataManager:restorePurchasedEquipment(player)
    if not player then return false end
    
    local userId = player.UserId
    local data = self.playerData[userId]
    
    -- Check if we have equipment data
    if not data or not data.equipment or #data.equipment == 0 then
        log("No equipment to restore for " .. player.Name)
        return false
    end
    
    log("Restoring " .. #data.equipment .. " pieces of equipment for " .. player.Name)
    
    -- Get BuyTileSystem
    local BuyTileSystem = CoreRegistry.getSystem("BuyTileSystem")
    if BuyTileSystem and BuyTileSystem.restoreEquipment then
        return BuyTileSystem.restoreEquipment(player, data.equipment)
    end
    
    -- Manual restore if BuyTileSystem not available
    local GymTycoonConnector = CoreRegistry.getSystem("GymTycoonConnector")
    if GymTycoonConnector then
        for _, tileId in ipairs(data.equipment) do
            GymTycoonConnector:onTilePurchased(player, tileId)
        end
        return true
    end
    
    return false
end

-- Record equipment purchase
function DataManager:recordEquipmentPurchase(player, tileId, tileInfo)
    if not player or not tileId then return false end
    
    local userId = player.UserId
    local data = self.playerData[userId]
    
    -- Check if we have the data
    if not data then
        log("No data found for " .. player.Name)
        return false
    end
    
    -- Initialize equipment array if needed
    if not data.equipment then
        data.equipment = {}
    end
    
    -- Add equipment
    table.insert(data.equipment, tileId)
    
    -- Update equipment count
    data.equipmentCount = (data.equipmentCount or 0) + 1
    
    -- Update gym tier
    data.gymTier = math.floor(data.equipmentCount / 5) + 1
    
    -- If tile info provided, store extra details
    if tileInfo then
        -- Store additional equipment details if needed
        if not data.equipmentDetails then
            data.equipmentDetails = {}
        end
        
        data.equipmentDetails[tileId] = {
            name = tileInfo.name,
            type = tileInfo.type,
            cost = tileInfo.cost,
            purchasedAt = os.time()
        }
    end
    
    -- Apply to player
    self:applyDataToPlayer(player, data)
    
    -- Save data later
    task.delay(5, function()
        self:saveData(player, false) -- Not immediate
    end)
    
    return true
end

-- Update player cash
function DataManager:updateCash(player, amount)
    if not player then return false end
    
    local userId = player.UserId
    local data = self.playerData[userId]
    
    -- Check if we have the data
    if not data then
        log("No data found for " .. player.Name)
        return false
    end
    
    -- Update cash
    data.cash = data.cash + amount
    
    -- Ensure cash doesn't go below 0
    if data.cash < 0 then
        data.cash = 0
    end
    
    -- Apply to player
    self:applyDataToPlayer(player, data)
    
    -- Only save immediately for large amounts
    if math.abs(amount) > 1000 then
        self:saveData(player, false) -- Not immediate but soon
    end
    
    return true
end

-- Update member counts
function DataManager:updateMembers(player, regularDelta, vipDelta, premiumDelta)
    if not player then return false end
    
    local userId = player.UserId
    local data = self.playerData[userId]
    
    -- Check if we have the data
    if not data then
        log("No data found for " .. player.Name)
        return false
    end
    
    -- Ensure members table exists
    if not data.members then
        data.members = {
            regular = 0,
            vip = 0,
            premium = 0,
            total = 0
        }
    end
    
    -- Update counts
    data.members.regular = (data.members.regular or 0) + (regularDelta or 0)
    data.members.vip = (data.members.vip or 0) + (vipDelta or 0)
    data.members.premium = (data.members.premium or 0) + (premiumDelta or 0)
    
    -- Calculate total
    data.members.total = data.members.regular + data.members.vip + data.members.premium
    
    -- Apply to player
    self:applyDataToPlayer(player, data)
    
    -- Schedule save
    self:saveData(player, false) -- Not immediate
    
    return true
end

-- Update revenue statistics
function DataManager:updateRevenue(player, amount)
    if not player then return false end
    
    local userId = player.UserId
    local data = self.playerData[userId]
    
    -- Check if we have the data
    if not data then
        log("No data found for " .. player.Name)
        return false
    end
    
    -- Ensure revenue table exists
    if not data.revenue then
        data.revenue = {
            daily = 0,
            weekly = 0,
            total = 0,
            history = {}
        }
    end
    
    -- Update revenue
    data.revenue.daily = (data.revenue.daily or 0) + amount
    data.revenue.weekly = (data.revenue.weekly or 0) + amount
    data.revenue.total = (data.revenue.total or 0) + amount
    
    -- Keep track of revenue history
    local today = os.date("%Y-%m-%d")
    if not data.revenue.history[today] then
        data.revenue.history[today] = amount
    else
        data.revenue.history[today] = data.revenue.history[today] + amount
    end
    
    -- Trim history to keep only last 30 days
    local days = {}
    for day, _ in pairs(data.revenue.history) do
        table.insert(days, day)
    end
    
    table.sort(days)
    if #days > 30 then
        for i = 1, #days - 30 do
            data.revenue.history[days[i]] = nil
        end
    end
    
    -- Apply to player
    self:applyDataToPlayer(player, data)
    
    return true
end

-- Update specialization
function DataManager:updateSpecialization(player, specialization)
    if not player then return false end
    
    local userId = player.UserId
    local data = self.playerData[userId]
    
    -- Check if we have the data
    if not data then
        log("No data found for " .. player.Name)
        return false
    end
    
    -- Update specialization
    data.specialization = specialization
    
    -- Apply to player
    self:applyDataToPlayer(player, data)
    
    -- Save data
    self:saveData(player, false) -- Not immediate
    
    return true
end

-- Set up a player's initial data
function DataManager:setupPlayer(player)
    if not player then return false end
    
    task.spawn(function()
        -- Load data
        local data = self:loadData(player)
        
        -- If we have equipment, restore it
        if data and data.equipment and #data.equipment > 0 then
            task.wait(3) -- Wait for tycoon to be fully set up
            self:restorePurchasedEquipment(player)
        end
        
        -- Notify systems that player data is ready
        EventBridge:fireServer("PlayerDataReady", player)
    end)
    
    return true
end

-- Check if player has started their tycoon
function DataManager:hasPlayerStartedTycoon(player)
    if not player then return false end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then return false end
    
    return tycoon:GetAttribute("TycoonStarted") == true
end

-- Get player data for external systems
function DataManager:getPlayerData(player)
    if not player then return nil end
    
    local userId = player.UserId
    return self.playerData[userId]
end

-- Public API
local PublicAPI = {
    initialize = function()
        return DataManager:initialize()
    end,
    
    loadData = function(player)
        return DataManager:loadData(player)
    end,
    
    saveData = function(player, immediate)
        return DataManager:saveData(player, immediate)
    end,
    
    applyDataToPlayer = function(player, data)
        return DataManager:applyDataToPlayer(player, data or DataManager.playerData[player.UserId])
    end,
    
    restorePurchasedEquipment = function(player)
        return DataManager:restorePurchasedEquipment(player)
    end,
    
    recordEquipmentPurchase = function(player, tileId, tileInfo)
        return DataManager:recordEquipmentPurchase(player, tileId, tileInfo)
    end,
    
    updateCash = function(player, amount)
        return DataManager:updateCash(player, amount)
    end,
    
    updateMembers = function(player, regularDelta, vipDelta, premiumDelta)
        return DataManager:updateMembers(player, regularDelta, vipDelta, premiumDelta)
    end,
    
    updateRevenue = function(player, amount)
        return DataManager:updateRevenue(player, amount)
    end,
    
    updateSpecialization = function(player, specialization)
        return DataManager:updateSpecialization(player, specialization)
    end,
    
    setupPlayer = function(player)
        return DataManager:setupPlayer(player)
    end,
    
    hasPlayerStartedTycoon = function(player)
        return DataManager:hasPlayerStartedTycoon(player)
    end,
    
    getPlayerData = function(player)
        return DataManager:getPlayerData(player)
    end,
    
    getDefaultData = function()
        return DataManager:getDefaultData()
    end,
    
    backupPlayerData = function(player)
        return DataManager:backupPlayerData(player)
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("DataManager", PublicAPI, {"EventBridge"})