--[[
    TycoonFolderInitializer.server.luau
    
    Initializes the tycoon folder structure for players when they join.
    This prevents "Value is not a valid member of Folder" errors that were reported
    as highest priority in RobloxIssues.txt.
    
    Creates all required subfolders and validates existing structures.
    
    UPDATED: May 1, 2025 - Enhanced to properly integrate with BuyTilePositionFixer
    and fix BuyTile System and Tycoon Structure Issues marked in RobloxIssues.txt.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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

-- Try to load the SafeWaitForChild module
local SafeWaitForChildModule = findModule("SafeWaitForChild")
local SafeWaitForChild = safeRequire(SafeWaitForChildModule)

-- Fallback implementation if SafeWaitForChild is not available
if not SafeWaitForChild then
    SafeWaitForChild = {
        wait = function(parent, childName, timeout, createIfMissing)
            timeout = timeout or 5
            
            local child = parent:FindFirstChild(childName)
            if child then return child end
            
            local startTime = os.clock()
            while not child and (os.clock() - startTime) < timeout do
                child = parent:FindFirstChild(childName)
                if child then break end
                task.wait(0.1)
            end
            
            if not child and createIfMissing then
                child = Instance.new("Folder")
                child.Name = childName
                child.Parent = parent
            end
            
            return child
        end
    }
end

-- Create or ensure a folder exists
local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    
    return folder
end

-- Required tycoon folder structure
local tycoonFolderStructure = {
    -- Main categories
    "Data",
    "Equipment",
    "Staff",
    "Customers",
    "Stats",
    "TycoonData", -- Added for compatibility with DataManagement TycoonFolderInitializer
    "Purchases",  -- Added for compatibility with DataManagement TycoonFolderInitializer
    "Progress",   -- Added for compatibility with DataManagement TycoonFolderInitializer
    "GymStructure", -- Added for compatibility with BuyTileSystem
    
    -- Data subfolders
    {"Data", "Purchases"},
    {"Data", "Upgrades"},
    {"Data", "Progress"},
    {"Data", "Settings"},
    {"Data", "BuyTiles"}, -- Added for BuyTileSystem integration
    
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
}

-- Initialize tycoon folder for a player
local function initializeTycoonFolder(player)
    -- Create main Tycoon folder
    local tycoonFolder = ensureFolder(player, "Tycoon")
    
    -- Create primary subfolders
    for _, entry in ipairs(tycoonFolderStructure) do
        if type(entry) == "string" then
            -- Top level folder
            ensureFolder(tycoonFolder, entry)
        else
            -- Nested folder
            local parent = SafeWaitForChild.wait(tycoonFolder, entry[1], 1, true)
            if parent then
                ensureFolder(parent, entry[2])
            end
        end
    end
    
    -- Create default value instances for critical systems
    
    -- FrontDesk display data
    local dataFolder = SafeWaitForChild.wait(tycoonFolder, "Data", 1, true)
    if dataFolder then
        local frontDeskData = dataFolder:FindFirstChild("FrontDeskDisplay")
        if not frontDeskData then
            frontDeskData = Instance.new("StringValue")
            frontDeskData.Name = "FrontDeskDisplay"
            frontDeskData.Value = "Welcome to your gym!"
            frontDeskData.Parent = dataFolder
        end
        
        -- BuyTile data store - needed for BuyTileSystem
        local buyTilesFolder = SafeWaitForChild.wait(dataFolder, "BuyTiles", 1, true)
        if buyTilesFolder then
            local buyTilesData = buyTilesFolder:FindFirstChild("OwnedTiles")
            if not buyTilesData then
                buyTilesData = Instance.new("StringValue")
                buyTilesData.Name = "OwnedTiles"
                buyTilesData.Value = "[]" -- Empty JSON array
                buyTilesData.Parent = buyTilesFolder
            end
        end
    end
    
    -- TycoonData folder needed by DataManagement TycoonFolderInitializer
    local tycoonDataFolder = SafeWaitForChild.wait(tycoonFolder, "TycoonData", 1, true)
    if tycoonDataFolder then
        -- Create required values if they don't exist
        local requiredValues = {
            {"Level", "IntValue", 1},
            {"Experience", "IntValue", 0},
            {"Money", "NumberValue", 100},
            {"GymName", "StringValue", "My Gym"}
        }
        
        for _, valueInfo in ipairs(requiredValues) do
            local name, valueType, defaultValue = valueInfo[1], valueInfo[2], valueInfo[3]
            local value = tycoonDataFolder:FindFirstChild(name)
            
            if not value then
                value = Instance.new(valueType)
                value.Name = name
                value.Value = defaultValue
                value.Parent = tycoonDataFolder
            end
        end
    end
    
    -- Equipment status values
    local equipmentFolder = SafeWaitForChild.wait(tycoonFolder, "Equipment", 1, true)
    if equipmentFolder then
        local statusValue = equipmentFolder:FindFirstChild("EquipmentStatus")
        if not statusValue then
            statusValue = Instance.new("StringValue")
            statusValue.Name = "EquipmentStatus"
            statusValue.Value = "functional"
            statusValue.Parent = equipmentFolder
        end
        
        -- Add equipment count for compatibility
        local equipmentCount = equipmentFolder:FindFirstChild("EquipmentCount") 
        if not equipmentCount then
            equipmentCount = Instance.new("IntValue")
            equipmentCount.Name = "EquipmentCount"
            equipmentCount.Value = 0
            equipmentCount.Parent = equipmentFolder
        end
    end
    
    -- GymStructure folder - needed by BuyTileSystem
    local gymStructureFolder = SafeWaitForChild.wait(tycoonFolder, "GymStructure", 1, true)
    if gymStructureFolder then
        -- Models folder for BuyTileSystem
        local modelsFolder = SafeWaitForChild.wait(gymStructureFolder, "Models", 1, true)
        if modelsFolder then
            -- Add a TilePositions attribute to hold model positions
            if not modelsFolder:GetAttribute("TilePositions") then
                modelsFolder:SetAttribute("TilePositions", "{}")
            end
        end
        
        -- Tiles folder for BuyTileSystem
        local tilesFolder = SafeWaitForChild.wait(gymStructureFolder, "Tiles", 1, true)
        if tilesFolder then
            -- Add a TileMetadata attribute
            if not tilesFolder:GetAttribute("TileMetadata") then
                tilesFolder:SetAttribute("TileMetadata", "{}")
            end
        end
    end
    
    -- Stats counters
    local statsFolder = SafeWaitForChild.wait(tycoonFolder, "Stats", 1, true)
    if statsFolder then
        local dailyStatsFolder = SafeWaitForChild.wait(statsFolder, "Daily", 1, true)
        if dailyStatsFolder then
            for _, statName in ipairs({"Visitors", "Income", "Expenses", "Profit"}) do
                local stat = dailyStatsFolder:FindFirstChild(statName)
                if not stat then
                    stat = Instance.new("NumberValue")
                    stat.Name = statName
                    stat.Value = 0
                    stat.Parent = dailyStatsFolder
                end
            end
        end
    end
    
    print("TycoonFolderInitializer: Successfully initialized tycoon folder structure for " .. player.Name)
    return tycoonFolder
end

-- Validate an existing tycoon folder
local function validateTycoonFolder(player)
    local tycoonFolder = player:FindFirstChild("Tycoon")
    
    -- If no tycoon folder, create it from scratch
    if not tycoonFolder then
        return initializeTycoonFolder(player)
    end
    
    -- Check primary subfolders and create if missing
    for _, entry in ipairs(tycoonFolderStructure) do
        if type(entry) == "string" then
            -- Top level folder
            ensureFolder(tycoonFolder, entry)
        else
            -- Nested folder
            local parent = SafeWaitForChild.wait(tycoonFolder, entry[1], 1, true)
            if parent then
                ensureFolder(parent, entry[2])
            end
        end
    end
    
    -- Create default value instances for critical systems that were causing errors
    local dataFolder = SafeWaitForChild.wait(tycoonFolder, "Data", 1, true)
    if dataFolder then
        -- FrontDeskDisplay - fix for "Value is not a valid member of Folder" error
        local frontDeskData = dataFolder:FindFirstChild("FrontDeskDisplay")
        if not frontDeskData then
            frontDeskData = Instance.new("StringValue")
            frontDeskData.Name = "FrontDeskDisplay"
            frontDeskData.Value = "Welcome to your gym!"
            frontDeskData.Parent = dataFolder
        end
        
        -- TycoonId - needed for validation checks
        local tycoonIdValue = dataFolder:FindFirstChild("TycoonId")
        if not tycoonIdValue then
            tycoonIdValue = Instance.new("StringValue")
            tycoonIdValue.Name = "TycoonId"
            tycoonIdValue.Value = player.Name
            tycoonIdValue.Parent = dataFolder
        end
        
        -- BuyTile data store - needed for BuyTileSystem
        local buyTilesFolder = dataFolder:FindFirstChild("BuyTiles")
        if not buyTilesFolder then
            buyTilesFolder = Instance.new("Folder")
            buyTilesFolder.Name = "BuyTiles"
            buyTilesFolder.Parent = dataFolder
            
            local buyTilesData = Instance.new("StringValue")
            buyTilesData.Name = "OwnedTiles"
            buyTilesData.Value = "[]" -- Empty JSON array
            buyTilesData.Parent = buyTilesFolder
        end
    end
    
    -- TycoonData folder needed by DataManagement TycoonFolderInitializer
    local tycoonDataFolder = tycoonFolder:FindFirstChild("TycoonData")
    if not tycoonDataFolder then
        tycoonDataFolder = Instance.new("Folder")
        tycoonDataFolder.Name = "TycoonData"
        tycoonDataFolder.Parent = tycoonFolder
        
        -- Create required values
        local requiredValues = {
            {"Level", "IntValue", 1},
            {"Experience", "IntValue", 0},
            {"Money", "NumberValue", 100},
            {"GymName", "StringValue", "My Gym"}
        }
        
        for _, valueInfo in ipairs(requiredValues) do
            local name, valueType, defaultValue = valueInfo[1], valueInfo[2], valueInfo[3]
            local value = Instance.new(valueType)
            value.Name = name
            value.Value = defaultValue
            value.Parent = tycoonDataFolder
        end
    end
    
    -- GymStructure folder - needed by BuyTileSystem and BuyTilePositionFixer
    local gymStructureFolder = tycoonFolder:FindFirstChild("GymStructure")
    if not gymStructureFolder then
        gymStructureFolder = Instance.new("Folder")
        gymStructureFolder.Name = "GymStructure"
        gymStructureFolder.Parent = tycoonFolder
        
        -- Create required subfolders
        local modelsFolder = Instance.new("Folder")
        modelsFolder.Name = "Models"
        modelsFolder.Parent = gymStructureFolder
        modelsFolder:SetAttribute("TilePositions", "{}")
        
        local tilesFolder = Instance.new("Folder")
        tilesFolder.Name = "Tiles"
        tilesFolder.Parent = gymStructureFolder
        tilesFolder:SetAttribute("TileMetadata", "{}")
        
        local layoutFolder = Instance.new("Folder")
        layoutFolder.Name = "Layout"
        layoutFolder.Parent = gymStructureFolder
    end
    
    print("TycoonFolderInitializer: Validated and fixed tycoon folder structure for " .. player.Name)
    
    -- Call BuyTilePositionFixer if available to ensure models are correctly positioned
    task.spawn(function()
        -- Find BuyTilePositionFixer in various possible locations
        local fixerPaths = {
            game:GetService("ServerScriptService"):FindFirstChild("BuyTilePositionFixer"),
            game:GetService("ServerScriptService"):FindFirstChild("server") and game:GetService("ServerScriptService").server:FindFirstChild("BuyTilePositionFixer"),
            game:GetService("ServerScriptService"):FindFirstChild("src") and game:GetService("ServerScriptService").src:FindFirstChild("server") and game:GetService("ServerScriptService").src.server:FindFirstChild("BuyTilePositionFixer")
        }
        
        for _, path in ipairs(fixerPaths) do
            if path and typeof(path) == "Instance" then
                -- Check if it has a fixModelsForPlayer function
                local success, result = pcall(function()
                    if typeof(path) == "Instance" and path:IsA("ModuleScript") then
                        local module = require(path)
                        if typeof(module) == "table" and typeof(module.fixModelsForPlayer) == "function" then
                            return module.fixModelsForPlayer(player)
                        end
                    end
                end)
                
                if success and result then
                    print("TycoonFolderInitializer: Successfully called BuyTilePositionFixer for " .. player.Name)
                    break
                end
            end
        end
    end)
    
    return tycoonFolder
end

-- Initialize tycoon folders for all players
local function initializeAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            validateTycoonFolder(player)
        end)
    end
end

-- Set up for new players
Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        -- Wait a short period to ensure player is fully loaded
        task.wait(1)
        initializeTycoonFolder(player)
    end)
end)

-- Fix for existing players when script runs
initializeAllPlayers()

print("✅ TycoonFolderInitializer: Running and monitoring player tycoon folder structures")
print("✅ [BuyTileSystem/TycoonFolderInitializer] Fixed and integrated with BuyTilePositionFixer - May 1, 2025")
