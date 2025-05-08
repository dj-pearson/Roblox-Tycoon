--!strict
--[[
    TycoonFolderInitializer.server.luau
    
    Core system for initializing and maintaining tycoon folder structures.
    This is the single source of truth for tycoon folder structure initialization.
    
    Created: May 2, 2025
    Author: N-DPEARSON
    Version: 2.0.0
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
    debug = true, -- Enable debug logging
    retryCount = 3, -- Number of times to retry initialization
    retryDelay = 1, -- Delay between retries in seconds
    checkInterval = 60, -- How often to check for structure integrity (seconds)
    
    -- Required folder structure
    requiredFolders = {
        -- Main categories
        "TycoonData",
        "Stats",
        "Purchases",
        "Equipment",
        "Staff",
        "Customers",
        "Progress",
        "Settings",
        "GymStructure",
        
        -- Data subfolders
        {"TycoonData", "Purchases"},
        {"TycoonData", "Upgrades"},
        {"TycoonData", "Progress"},
        {"TycoonData", "Settings"},
        {"TycoonData", "BuyTiles"},
        
        -- Equipment subfolders
        {"Equipment", "Gym"},
        {"Equipment", "Office"},
        {"Equipment", "Entertainment"},
        {"Equipment", "Amenities"},
        
        -- Staff subfolders
        {"Staff", "Trainers"},
        {"Staff", "Cleaners"},
        {"Staff", "Receptionists"},
        {"Staff", "Management"},
        
        -- Customer subfolders
        {"Customers", "Active"},
        {"Customers", "Queued"},
        {"Customers", "History"},
        
        -- Stats subfolders
        {"Stats", "Daily"},
        {"Stats", "Weekly"},
        {"Stats", "Monthly"},
        
        -- GymStructure subfolders (for BuyTileSystem)
        {"GymStructure", "Models"},
        {"GymStructure", "Tiles"},
        {"GymStructure", "Layout"}
    },
    
    -- Required values and their defaults
    requiredValues = {
        -- TycoonData values
        {"TycoonData", "Level", "IntValue", 1},
        {"TycoonData", "Experience", "IntValue", 0},
        {"TycoonData", "Money", "NumberValue", 100},
        {"TycoonData", "GymName", "StringValue", "My Gym"},
        
        -- Stats values
        {"Stats", "MemberCount", "IntValue", 0},
        {"Stats", "EquipmentCount", "IntValue", 0},
        {"Stats", "DailyIncome", "NumberValue", 0},
        {"Stats", "WeeklyIncome", "NumberValue", 0},
        {"Stats", "MonthlyIncome", "NumberValue", 0},
        
        -- Progress values
        {"Progress", "GymTier", "IntValue", 1},
        {"Progress", "UnlockedEquipment", "StringValue", "{}"},
        {"Progress", "UnlockedStaff", "StringValue", "{}"},
        
        -- Settings values
        {"Settings", "AutoSave", "BoolValue", true},
        {"Settings", "Notifications", "BoolValue", true},
        {"Settings", "SoundEnabled", "BoolValue", true}
    }
}

-- Logger function
local function log(...)
    if CONFIG.debug then
        print("[TycoonFolderInitializer]", ...)
    end
end

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

-- Safely require a module
local function safeRequire(moduleInstance, fallback)
    if not moduleInstance then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if success then
        return result
    else
        warn("TycoonFolderInitializer: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Create or ensure a folder exists
local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    
    if folder and not folder:IsA("Folder") then
        log("Found", name, "that is not a Folder, removing it")
        folder:Destroy()
        folder = nil
    end
    
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        log("Created folder:", name)
    end
    
    return folder
end

-- Create or ensure a value exists
local function ensureValue(parent, name, valueType, defaultValue)
    local value = parent:FindFirstChild(name)
    
    if value and not value:IsA(valueType) then
        log("Found", name, "with wrong type, fixing it")
        value:Destroy()
        value = nil
    end
    
    if not value then
        value = Instance.new(valueType)
        value.Name = name
        value.Parent = parent
        
        -- Set default value
        if defaultValue ~= nil then
            value.Value = defaultValue
        end
        
        log("Created", valueType, name, "with default value", defaultValue)
    end
    
    return value
end

-- Initialize tycoon folder structure for a player
local function initializeTycoonFolder(player)
    if not player then return nil end
    
    log("Initializing tycoon folder structure for", player.Name)
    
    -- Create or get the Tycoon ObjectValue
    local tycoonValue = player:FindFirstChild("Tycoon")
    if tycoonValue and not tycoonValue:IsA("ObjectValue") then
        log("Found invalid Tycoon type for", player.Name, "- removing and recreating")
        tycoonValue:Destroy()
        tycoonValue = nil
    end
    
    if not tycoonValue then
        tycoonValue = Instance.new("ObjectValue")
        tycoonValue.Name = "Tycoon"
        tycoonValue.Parent = player
        log("Created Tycoon ObjectValue for", player.Name)
    end
    
    -- Create the tycoon model if it doesn't exist
    local tycoonModel = tycoonValue.Value
    if not tycoonModel then
        tycoonModel = Instance.new("Model")
        tycoonModel.Name = player.Name .. "_Tycoon"
        tycoonModel.Parent = workspace
        tycoonValue.Value = tycoonModel
        log("Created tycoon model for", player.Name)
    end
    
    -- Create all required folders
    for _, folderInfo in ipairs(CONFIG.requiredFolders) do
        local parent = tycoonModel
        local folderName = folderInfo
        
        -- Handle nested folders
        if type(folderInfo) == "table" then
            for i, part in ipairs(folderInfo) do
                if i < #folderInfo then
                    parent = ensureFolder(parent, part)
                else
                    folderName = part
                end
            end
        end
        
        ensureFolder(parent, folderName)
    end
    
    -- Create all required values
    for _, valueInfo in ipairs(CONFIG.requiredValues) do
        local parent = tycoonModel
        local parentPath = valueInfo[1]
        local valueName = valueInfo[2]
        local valueType = valueInfo[3]
        local defaultValue = valueInfo[4]
        
        -- Navigate to the parent folder
        for _, part in ipairs(string.split(parentPath, "/")) do
            parent = ensureFolder(parent, part)
        end
        
        ensureValue(parent, valueName, valueType, defaultValue)
    end
    
    -- Special handling for GymStructure folder
    local gymStructureFolder = tycoonModel:FindFirstChild("GymStructure")
    if gymStructureFolder then
        -- Set up tile positions attribute
        local modelsFolder = gymStructureFolder:FindFirstChild("Models")
        if modelsFolder then
            modelsFolder:SetAttribute("TilePositions", "{}")
        end
        
        -- Set up tile metadata attribute
        local tilesFolder = gymStructureFolder:FindFirstChild("Tiles")
        if tilesFolder then
            tilesFolder:SetAttribute("TileMetadata", "{}")
        end
    end
    
    log("Tycoon folder structure initialized for", player.Name)
    return tycoonModel
end

-- Validate and fix tycoon folder structure
local function validateTycoonStructure(player)
    if not player then return false end
    
    log("Validating tycoon structure for", player.Name)
    
    local tycoonValue = player:FindFirstChild("Tycoon")
    if not tycoonValue or not tycoonValue:IsA("ObjectValue") then
        log("Tycoon value missing or invalid for", player.Name)
        initializeTycoonFolder(player)
        return false
    end
    
    local tycoonModel = tycoonValue.Value
    if not tycoonModel then
        log("Tycoon model missing for", player.Name)
        initializeTycoonFolder(player)
        return false
    end
    
    local madeChanges = false
    
    -- Validate all required folders
    for _, folderInfo in ipairs(CONFIG.requiredFolders) do
        local parent = tycoonModel
        local folderName = folderInfo
        
        -- Handle nested folders
        if type(folderInfo) == "table" then
            for i, part in ipairs(folderInfo) do
                if i < #folderInfo then
                    local folder = parent:FindFirstChild(part)
                    if not folder or not folder:IsA("Folder") then
                        madeChanges = true
                        parent = ensureFolder(parent, part)
                    else
                        parent = folder
                    end
                else
                    folderName = part
                end
            end
        end
        
        local folder = parent:FindFirstChild(folderName)
        if not folder or not folder:IsA("Folder") then
            madeChanges = true
            ensureFolder(parent, folderName)
        end
    end
    
    -- Validate all required values
    for _, valueInfo in ipairs(CONFIG.requiredValues) do
        local parent = tycoonModel
        local parentPath = valueInfo[1]
        local valueName = valueInfo[2]
        local valueType = valueInfo[3]
        local defaultValue = valueInfo[4]
        
        -- Navigate to the parent folder
        for _, part in ipairs(string.split(parentPath, "/")) do
            local folder = parent:FindFirstChild(part)
            if not folder or not folder:IsA("Folder") then
                madeChanges = true
                parent = ensureFolder(parent, part)
            else
                parent = folder
            end
        end
        
        local value = parent:FindFirstChild(valueName)
        if not value or not value:IsA(valueType) then
            madeChanges = true
            ensureValue(parent, valueName, valueType, defaultValue)
        end
    end
    
    -- If changes were made, try to fix model positions
    if madeChanges then
        task.spawn(function()
            -- Find BuyTilePositionFixer
            local fixerModule = findModule("BuyTilePositionFixer")
            if fixerModule then
                local fixer = safeRequire(fixerModule)
                if fixer and fixer.fixModelsForPlayer then
                    local success, result = pcall(function()
                        return fixer.fixModelsForPlayer(player)
                    end)
                    
                    if success and result then
                        log("Successfully called BuyTilePositionFixer for", player.Name)
                    else
                        warn("Failed to call BuyTilePositionFixer for", player.Name, "-", tostring(result))
                    end
                end
            end
        end)
    end
    
    return not madeChanges
end

-- Initialize tycoon folders for all players
local function initializeAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            for i = 1, CONFIG.retryCount do
                if validateTycoonStructure(player) then
                    break
                end
                
                if i < CONFIG.retryCount then
                    task.wait(CONFIG.retryDelay)
                end
            end
        end)
    end
end

-- Set up for new players
Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        -- Wait a short period to ensure player is fully loaded
        task.wait(1)
        for i = 1, CONFIG.retryCount do
            if validateTycoonStructure(player) then
                break
            end
            
            if i < CONFIG.retryCount then
                task.wait(CONFIG.retryDelay)
            end
        end
    end)
end)

-- Start periodic structure validation
task.spawn(function()
    while true do
        task.wait(CONFIG.checkInterval)
        log("Running periodic structure validation")
        initializeAllPlayers()
    end
end)

-- Initialize existing players
initializeAllPlayers()

-- Export the module
return {
    initializeTycoonFolder = initializeTycoonFolder,
    validateTycoonStructure = validateTycoonStructure,
    initializeAllPlayers = initializeAllPlayers
}
