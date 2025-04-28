--[[
    TycoonFolderInitializer.server.luau
    
    Initializes the tycoon folder structure for players when they join.
    This prevents "Value is not a valid member of Folder" errors that were reported
    as highest priority in RobloxIssues.txt.
    
    Creates all required subfolders and validates existing structures.
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
    
    -- Data subfolders
    {"Data", "Purchases"},
    {"Data", "Upgrades"},
    {"Data", "Progress"},
    {"Data", "Settings"},
    
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
    {"Stats", "Monthly"}
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
    
    print("TycoonFolderInitializer: Validated and fixed tycoon folder structure for " .. player.Name)
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
