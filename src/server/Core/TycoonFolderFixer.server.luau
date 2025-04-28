--[[
    TycoonFolderFixer.server.luau
    
    Critical fix for Tycoon folder structure issues.
    This script ensures that proper Tycoon folder structures exist and addresses
    the "Value is not a valid member of Folder" errors.
    
    Created to fix the highest priority issues identified in RobloxIssues.txt
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true, -- Enable debug logging
    fixOnStart = true, -- Fix existing players on startup
    retryCount = 3, -- Number of times to retry creating structures
    retryDelay = 1, -- Delay between retries in seconds
    checkInterval = 60, -- How often to check for structure integrity (seconds)
    requiredFolders = { -- Folders that must exist in the Tycoon
        "TycoonData",
        "Stats",
        "Purchases",
        "Equipment"
    },
    requiredValues = { -- Values that must exist in the Tycoon
        { name = "GymLevel", type = "IntValue", default = 1 },
        { name = "EquipmentCount", type = "IntValue", default = 0 },
        { name = "MemberCount", type = "IntValue", default = 0 },
        { name = "AccruedDues", type = "NumberValue", default = 0 }
    }
}

-- Logger function
local function log(...)
    if CONFIG.debug then
        print("[TycoonFolderFixer]", ...)
    end
end

-- Find a module in multiple potential locations
local function findModule(name)
    local searchPaths = {
        ServerScriptService.Core,
        ServerScriptService,
        ReplicatedStorage.shared,
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(name)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Try to safely require a module
local function safeRequire(modulePath)
    if not modulePath then return nil end
    
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if success then
        return result
    else
        log("Failed to require module:", modulePath:GetFullName(), "-", result)
        return nil
    end
end

-- Try to find data manager
local dataManagerModule = findModule("DataManager") or findModule("GymTycoonDataManager")
local DataManager = dataManagerModule and safeRequire(dataManagerModule)

-- Checks if a Tycoon value exists and is properly set up
local function validateTycoonValue(player)
    if not player then return false end
    
    local tycoonValue = player:FindFirstChild("Tycoon")
    
    if not tycoonValue then
        log("Tycoon value missing for", player.Name)
        return false
    end
    
    -- Check if it's an ObjectValue
    if not tycoonValue:IsA("ObjectValue") then
        log("Tycoon is not an ObjectValue for", player.Name, "- it's a", tycoonValue.ClassName)
        return false
    end
    
    -- Check if it has a valid target
    if not tycoonValue.Value then
        log("Tycoon value exists for", player.Name, "but points to nil")
        return false
    end
    
    -- Make sure it's not pointing to the player's character
    if tycoonValue.Value == player.Character then
        log("Tycoon incorrectly pointing to character for", player.Name)
        return false
    end
    
    return true
end

-- Create a new Tycoon ObjectValue for a player
local function createTycoonValue(player)
    -- Remove existing if it's the wrong type
    local existing = player:FindFirstChild("Tycoon")
    if existing and not existing:IsA("ObjectValue") then
        log("Removing incorrectly typed Tycoon for", player.Name)
        existing:Destroy()
    end
    
    -- Create a new ObjectValue
    local tycoonValue = player:FindFirstChild("Tycoon") or Instance.new("ObjectValue")
    tycoonValue.Name = "Tycoon"
    tycoonValue.Parent = player
    
    log("Created Tycoon ObjectValue for", player.Name)
    return tycoonValue
end

-- Create a folder with the given name if it doesn't exist
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

-- Create a value with the given name and type if it doesn't exist
local function ensureValue(parent, name, valueType, defaultValue)
    local value = parent:FindFirstChild(name)
    
    -- Fix mismatched value type
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

-- Fix Tycoon folder structure for a player
local function fixTycoonStructure(player)
    if not player then return false end
    
    log("Fixing Tycoon structure for", player.Name)
    
    -- Use existing Tycoon value or create a new one
    local tycoonValue = player:FindFirstChild("Tycoon")
    local needsNewValue = false
    
    -- Fix incorrect Tycoon value type
    if tycoonValue and not tycoonValue:IsA("ObjectValue") then
        log("Tycoon is not an ObjectValue, recreating it")
        tycoonValue:Destroy()
        needsNewValue = true
    end
    
    -- Create a new value if needed
    if not tycoonValue or needsNewValue then
        tycoonValue = createTycoonValue(player)
    end
    
    -- Create/ensure all required folders under the player
    for _, folderName in ipairs(CONFIG.requiredFolders) do
        ensureFolder(player, folderName)
    end
    
    -- Create/ensure all required values
    for _, valueInfo in ipairs(CONFIG.requiredValues) do
        local attribute = tycoonValue:GetAttribute(valueInfo.name)
        
        -- If we have the attribute but no value, create it
        if attribute ~= nil then
            ensureValue(tycoonValue, valueInfo.name, valueInfo.type, attribute)
            
            -- Once we've created the value, we can remove the attribute
            tycoonValue:SetAttribute(valueInfo.name, nil)
        else
            -- Create with the default value
            ensureValue(tycoonValue, valueInfo.name, valueInfo.type, valueInfo.default)
        end
    end
    
    -- If we have DataManager, use it to refresh player data
    if DataManager and DataManager.applyDataToPlayer then
        pcall(function()
            DataManager.applyDataToPlayer(player)
        end)
    end
    
    log("Tycoon structure fixed for", player.Name)
    return true
end

-- Fix all players
local function fixAllPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            fixTycoonStructure(player)
        end)
    end
end

-- Register event to fix new players when they join
Players.PlayerAdded:Connect(function(player)
    -- Wait a bit for the player to fully load
    task.delay(1, function()
        for i = 1, CONFIG.retryCount do
            if fixTycoonStructure(player) then
                break
            end
            
            -- Wait before trying again
            task.wait(CONFIG.retryDelay)
        end
    end)
end)

-- Fix existing players on startup if configured
if CONFIG.fixOnStart then
    fixAllPlayers()
end

-- Start periodic check for structure integrity
task.spawn(function()
    while true do
        task.wait(CONFIG.checkInterval)
        
        log("Running periodic structure integrity check")
        fixAllPlayers()
    end
end)

-- Set up an event for manual fixes
local fixEvent = Instance.new("BindableEvent")
fixEvent.Name = "FixTycoonStructure"
fixEvent.Parent = script

-- Connect the event
fixEvent.Event:Connect(function(player)
    if player and player:IsA("Player") then
        fixTycoonStructure(player)
    else
        fixAllPlayers()
    end
end)

log("TycoonFolderFixer initialized, fixing critical folder structure issues")
