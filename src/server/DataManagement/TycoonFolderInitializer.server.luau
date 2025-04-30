--!strict
-- TycoonFolderInitializer.server.luau
-- Handles proper initialization and validation of Tycoon folder structures
-- Created on April 29, 2025 to fix critical tycoon folder structure issues

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import SafeWaitForChild utility if available
local SafeWaitForChild = nil
local function importSafeUtilities()
    local success, result = pcall(function()
        local sharedFolder = ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared")
        if sharedFolder then
            return require(sharedFolder:FindFirstChild("SafeWaitForChild"))
        end
        return nil
    end)
    
    if success and result then
        return result
    else
        -- Fallback implementation if the utility cannot be loaded
        return function(parent, childName, timeout)
            timeout = timeout or 5
            local child = parent:FindFirstChild(childName)
            if child then return child end
            
            local startTime = os.clock()
            while os.clock() - startTime < timeout do
                child = parent:FindFirstChild(childName)
                if child then return child end
                task.wait(0.1)
            end
            
            warn(string.format("[TycoonFolderInitializer] Failed to find %s in %s within %d seconds", 
                childName, parent:GetFullName(), timeout))
            return nil
        end
    end
end

-- Get or create a child instance
local function getOrCreateInstance(parent, name, instanceType)
    local instance = parent:FindFirstChild(name)
    if instance then
        if instance.ClassName ~= instanceType then
            warn(string.format("[TycoonFolderInitializer] %s exists but is a %s, not a %s. Fixing...", 
                name, instance.ClassName, instanceType))
            instance:Destroy()
            instance = Instance.new(instanceType)
            instance.Name = name
            instance.Parent = parent
        end
    else
        instance = Instance.new(instanceType)
        instance.Name = name
        instance.Parent = parent
    end
    return instance
end

-- Required folder structure for tycoon data
local REQUIRED_FOLDERS = {
    {"TycoonData", "Folder"},
    {"Stats", "Folder"},
    {"Purchases", "Folder"},
    {"Equipment", "Folder"},
    {"FrontDesk", "Folder"},
    {"Progress", "Folder"},
    {"Settings", "Folder"},
}

-- Required values for newly initialized tycoon
local REQUIRED_VALUES = {
    {"TycoonData/Level", "IntValue", 1},
    {"TycoonData/Experience", "IntValue", 0},
    {"TycoonData/Money", "NumberValue", 100},
    {"TycoonData/GymName", "StringValue", "My Gym"},
    {"Stats/Reputation", "NumberValue", 50},
    {"Stats/Members", "IntValue", 0},
    {"Stats/Satisfaction", "NumberValue", 100},
    {"Equipment/EquipmentCount", "IntValue", 0},
    {"FrontDesk/HasStaff", "BoolValue", false},
    {"Progress/TilesUnlocked", "IntValue", 1},
    {"Progress/LastSaveTimestamp", "NumberValue", os.time()},
}

-- Initialize tycoon folder structure for a player
local function initializeTycoonStructure(player)
    print("[TycoonFolderInitializer] Initializing tycoon structure for: " .. player.Name)
    
    -- Create main Tycoon folder if it doesn't exist
    local tycoonFolder = getOrCreateInstance(player, "Tycoon", "Folder")
    
    -- Create required folders
    for _, folderInfo in ipairs(REQUIRED_FOLDERS) do
        local folderName, instanceType = folderInfo[1], folderInfo[2]
        getOrCreateInstance(tycoonFolder, folderName, instanceType)
    end
    
    -- Create required values
    for _, valueInfo in ipairs(REQUIRED_VALUES) do
        local path, instanceType, defaultValue = valueInfo[1], valueInfo[2], valueInfo[3]
        
        -- Parse path to get parent folder and instance name
        local pathParts = string.split(path, "/")
        local parentPath = pathParts[1]
        local instanceName = pathParts[2]
        
        -- Get parent folder
        local parentFolder = tycoonFolder:FindFirstChild(parentPath)
        if parentFolder then
            local instance = getOrCreateInstance(parentFolder, instanceName, instanceType)
            
            -- Set default value if instance is newly created
            if instanceType == "StringValue" then
                instance.Value = defaultValue
            elseif instanceType == "BoolValue" then
                instance.Value = defaultValue
            elseif instanceType == "IntValue" or instanceType == "NumberValue" then
                instance.Value = defaultValue
            end
        end
    end
    
    return tycoonFolder
end

-- Validate tycoon structure - returns true if structure is valid, false if corrections were made
local function validateTycoonStructure(player)
    print("[TycoonFolderInitializer] Validating tycoon structure for: " .. player.Name)
    
    local tycoonFolder = player:FindFirstChild("Tycoon")
    if not tycoonFolder then
        print("[TycoonFolderInitializer] Tycoon folder missing for " .. player.Name .. ", creating...")
        initializeTycoonStructure(player)
        return false
    end
    
    local madeChanges = false
    
    -- Validate required folders
    for _, folderInfo in ipairs(REQUIRED_FOLDERS) do
        local folderName, instanceType = folderInfo[1], folderInfo[2]
        local folder = tycoonFolder:FindFirstChild(folderName)
        
        if not folder then
            print("[TycoonFolderInitializer] Missing required folder: " .. folderName .. " for " .. player.Name)
            getOrCreateInstance(tycoonFolder, folderName, instanceType)
            madeChanges = true
        elseif folder.ClassName ~= instanceType then
            print("[TycoonFolderInitializer] Incorrect folder type: " .. folderName .. " for " .. player.Name)
            folder:Destroy()
            getOrCreateInstance(tycoonFolder, folderName, instanceType)
            madeChanges = true
        end
    end
    
    -- Validate required values
    for _, valueInfo in ipairs(REQUIRED_VALUES) do
        local path, instanceType, defaultValue = valueInfo[1], valueInfo[2], valueInfo[3]
        
        -- Parse path to get parent folder and instance name
        local pathParts = string.split(path, "/")
        local parentPath = pathParts[1]
        local instanceName = pathParts[2]
        
        -- Get parent folder
        local parentFolder = tycoonFolder:FindFirstChild(parentPath)
        if parentFolder then
            local instance = parentFolder:FindFirstChild(instanceName)
            
            if not instance then
                print("[TycoonFolderInitializer] Missing required value: " .. path .. " for " .. player.Name)
                instance = getOrCreateInstance(parentFolder, instanceName, instanceType)
                
                -- Set default value
                if instanceType == "StringValue" then
                    instance.Value = defaultValue
                elseif instanceType == "BoolValue" then
                    instance.Value = defaultValue
                elseif instanceType == "IntValue" or instanceType == "NumberValue" then
                    instance.Value = defaultValue
                end
                
                madeChanges = true
            elseif instance.ClassName ~= instanceType then
                print("[TycoonFolderInitializer] Incorrect value type: " .. path .. " for " .. player.Name)
                instance:Destroy()
                instance = getOrCreateInstance(parentFolder, instanceName, instanceType)
                
                -- Set default value
                if instanceType == "StringValue" then
                    instance.Value = defaultValue
                elseif instanceType == "BoolValue" then
                    instance.Value = defaultValue
                elseif instanceType == "IntValue" or instanceType == "NumberValue" then
                    instance.Value = defaultValue
                end
                
                madeChanges = true
            end
        else
            print("[TycoonFolderInitializer] Missing required parent folder: " .. parentPath .. " for " .. player.Name)
            parentFolder = getOrCreateInstance(tycoonFolder, parentPath, "Folder")
            local instance = getOrCreateInstance(parentFolder, instanceName, instanceType)
            
            -- Set default value
            if instanceType == "StringValue" then
                instance.Value = defaultValue
            elseif instanceType == "BoolValue" then
                instance.Value = defaultValue
            elseif instanceType == "IntValue" or instanceType == "NumberValue" then
                instance.Value = defaultValue
            end
            
            madeChanges = true
        end
    end
    
    return not madeChanges
end

-- Register event handlers
local function onPlayerAdded(player)
    print("[TycoonFolderInitializer] Player joined: " .. player.Name)
    
    -- Try to initialize structure
    local success, result = pcall(function()
        return initializeTycoonStructure(player)
    end)
    
    if not success then
        warn("[TycoonFolderInitializer] Failed to initialize tycoon structure for " .. player.Name .. ": " .. tostring(result))
        -- Retry once after a delay
        task.delay(2, function()
            pcall(function()
                return initializeTycoonStructure(player)
            end)
        end)
    end
end

-- Add validation check when character is loaded to catch any issues after initial setup
local function onCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        -- Validate after character loads, allowing time for other systems
        task.delay(1, function()
            local isValid = validateTycoonStructure(player)
            if not isValid then
                print("[TycoonFolderInitializer] Corrected tycoon structure for " .. player.Name)
            end
        end)
    end
end

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        onPlayerAdded(player)
    end)
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- Connect to player joining
Players.PlayerAdded:Connect(onPlayerAdded)

-- Periodic validation - check all players every 60 seconds
task.spawn(function()
    while true do
        task.wait(60)
        print("[TycoonFolderInitializer] Running periodic tycoon structure validation...")
        
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(function()
                local isValid = validateTycoonStructure(player)
                if not isValid then
                    print("[TycoonFolderInitializer] Corrected tycoon structure during periodic check for " .. player.Name)
                end
            end)
        end
    end
end)

print("[TycoonFolderInitializer] Initialized and active")
return true
