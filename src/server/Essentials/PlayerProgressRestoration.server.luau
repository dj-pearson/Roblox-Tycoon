--[[
    PlayerProgressRestoration.server.luau
    
    Handles recovery of player progress in case of data issues. Provides mechanisms
    to restore lost progress, fix corrupted saves, or compensate players for technical problems.
    This script serves as a safety net for data integrity issues.
    
    Created: April 27, 2025
]]

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    AUTO_RECOVERY_ENABLED = true,
    RETRY_EQUIPMENT_RESTORE = true,
    MAX_RESTORE_ATTEMPTS = 3,
    RESTORATION_DELAY = 10, -- seconds to wait after join before attempting restoration
    COMPENSATION_AMOUNTS = {
        MINOR_ISSUE = 1000, -- amount of in-game currency to give for minor issues
        MAJOR_ISSUE = 5000  -- amount for major issues
    }
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[ProgressRestoration] " .. message)
    end
end

-- Get CoreRegistry
local CoreRegistry
local success, result = pcall(function()
    local registryLocations = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and
            ServerScriptService.src.server:FindFirstChild("Core") and 
            ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Systems") and ServerScriptService.Systems:FindFirstChild("CoreRegistry")
    }
    
    for _, location in ipairs(registryLocations) do
        if location then
            return require(location)
        end
    end
    
    return nil
end)

if success and result then
    CoreRegistry = result
    log("CoreRegistry found")
else
    warn("[ProgressRestoration] Failed to find CoreRegistry: " .. tostring(result))
end

-- Get references to key systems
local function getSystems()
    if not CoreRegistry then
        return {}
    end
    
    -- Get systems from registry
    local systems = {
        DataManager = CoreRegistry:GetSystem("DataManager"),
        TycoonManager = CoreRegistry:GetSystem("TycoonManager"),
        BuyTileSystem = CoreRegistry:GetSystem("BuyTileSystem"),
        EquipmentManager = CoreRegistry:GetSystem("EquipmentManager")
    }
    
    -- Load DataManagerFix if available
    pcall(function()
        local fixLocations = {
            ServerScriptService.Core.DataManagerFix,
            ServerScriptService.src and ServerScriptService.src.server and 
                ServerScriptService.src.server.Core and ServerScriptService.src.server.Core.DataManagerFix
        }
        
        for _, location in ipairs(fixLocations) do
            if location then
                systems.DataManagerFix = require(location)
                log("Found DataManagerFix")
                break
            end
        end
    end)
    
    return systems
end

-- Track player data restoration status
local playerRestorationState = {}

-- Get player's tycoon
local function getPlayerTycoon(player)
    if not player then return nil end
    
    -- Check player has tycoon reference
    local tycoonRef = player:FindFirstChild("Tycoon")
    if tycoonRef and tycoonRef:IsA("ObjectValue") and tycoonRef.Value then
        return tycoonRef.Value
    end
    
    -- Try to find it by name in workspace
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and 
           (model.Name == player.Name .. "_Tycoon" or 
            model.Name == player.Name .. "Tycoon" or
            model:GetAttribute("Owner") == player.Name or
            model:GetAttribute("OwnerID") == player.UserId) then
            return model
        end
    end
    
    return nil
end

-- Get or create restoration state for a player
local function getRestorationState(player)
    if not playerRestorationState[player.UserId] then
        playerRestorationState[player.UserId] = {
            restorationAttempts = 0,
            compensationGiven = false,
            equipmentRestored = false,
            tilesRestored = 0,
            lastAttemptTime = 0
        }
    end
    
    return playerRestorationState[player.UserId]
end

-- Check if player data needs restoration
local function needsRestoration(player)
    local systems = getSystems()
    
    -- No data manager, can't check
    if not systems.DataManager then
        return false, "No DataManager available"
    end
    
    local data = systems.DataManager.loadedData and systems.DataManager.loadedData[player.UserId]
    if not data then
        return false, "No data loaded"
    end
    
    -- Check if player has equipment to restore
    if data.equipmentPurchased and next(data.equipmentPurchased) then
        -- Check if player has tycoon
        local tycoon = getPlayerTycoon(player)
        if not tycoon then
            log("No tycoon to restore equipment to for " .. player.Name)
            return false, "No tycoon available"
        end
        
        -- Count equipment in tycoon
        local equipmentInTycoon = 0
        for _, instance in ipairs(tycoon:GetDescendants()) do
            if instance:GetAttribute("IsEquipment") or instance:GetAttribute("IsBuyableTile") then
                equipmentInTycoon = equipmentInTycoon + 1
            end
        end
        
        -- Count equipment in data
        local equipmentInData = 0
        for _ in pairs(data.equipmentPurchased) do
            equipmentInData = equipmentInData + 1
        end
        
        -- If there's a large difference, restoration is needed
        if equipmentInTycoon < equipmentInData * 0.5 then
            return true, "Equipment mismatch: " .. equipmentInTycoon .. " in tycoon vs " .. equipmentInData .. " in data"
        end
    end
    
    return false, "No restoration needed"
end

-- Restore player equipment
local function restorePlayerEquipment(player)
    local systems = getSystems()
    local state = getRestorationState(player)
    
    -- Check if we should try to restore
    if state.equipmentRestored or state.restorationAttempts >= CONFIG.MAX_RESTORE_ATTEMPTS then
        return false, "Max attempts reached or already restored"
    end
    
    -- Increment attempt counter
    state.restorationAttempts = state.restorationAttempts + 1
    state.lastAttemptTime = os.time()
    
    log("Attempt #" .. state.restorationAttempts .. " to restore equipment for " .. player.Name)
    
    -- Try using DataManagerFix first if available
    if systems.DataManagerFix and systems.DataManagerFix.enhancedRestorePlayerEquipment then
        log("Using enhanced restore function for " .. player.Name)
        local success, result = pcall(function()
            return systems.DataManagerFix.enhancedRestorePlayerEquipment(player)
        end)
        
        if success and result then
            state.equipmentRestored = true
            log("Successfully restored equipment for " .. player.Name .. " using enhanced restore")
            return true, "Equipment restored successfully"
        end
    end
    
    -- Fall back to normal DataManager restore function
    if systems.DataManager and systems.DataManager.RestorePlayerEquipment then
        log("Using standard restore function for " .. player.Name)
        local success, result = pcall(function()
            return systems.DataManager:RestorePlayerEquipment(player)
        end)
        
        if success and result then
            state.equipmentRestored = true
            log("Successfully restored equipment for " .. player.Name .. " using standard restore")
            return true, "Equipment restored successfully"
        else
            log("Failed to restore equipment: " .. tostring(result))
        end
    end
    
    -- Last resort: Try BuyTileSystem directly
    if systems.BuyTileSystem then
        local buyTileSystem = systems.BuyTileSystem
        local dataManager = systems.DataManager
        
        if dataManager and dataManager.loadedData and dataManager.loadedData[player.UserId] and
           dataManager.loadedData[player.UserId].equipmentPurchased then
            
            local data = dataManager.loadedData[player.UserId]
            local restored = 0
            
            -- Try to restore each piece of equipment
            for tileId, _ in pairs(data.equipmentPurchased) do
                local numericId = tonumber(tileId) or tonumber(string.match(tileId or "", "%d+"))
                
                if numericId and buyTileSystem.spawnGymPart then
                    local success = pcall(function()
                        buyTileSystem.spawnGymPart(numericId)
                    end)
                    
                    if success then
                        restored = restored + 1
                    end
                    
                    task.wait(0.1) -- Small delay between spawns
                end
            end
            
            if restored > 0 then
                state.tilesRestored = restored
                log("Manually restored " .. restored .. " tiles for " .. player.Name)
                return true, "Manually restored " .. restored .. " pieces of equipment"
            end
        end
    end
    
    -- If we get here, all restoration attempts failed
    return false, "All restoration methods failed"
end

-- Provide compensation for failed restoration
local function provideCompensation(player, level)
    local systems = getSystems()
    local state = getRestorationState(player)
    
    -- Don't compensate twice
    if state.compensationGiven then
        return false, "Compensation already given"
    end
    
    -- Get amount based on level
    local amount = CONFIG.COMPENSATION_AMOUNTS[level] or CONFIG.COMPENSATION_AMOUNTS.MINOR_ISSUE
    
    -- Try to add cash through DataManager
    if systems.DataManager and systems.DataManager.loadedData and systems.DataManager.loadedData[player.UserId] then
        local data = systems.DataManager.loadedData[player.UserId]
        
        -- Add cash
        data.cash = (data.cash or 0) + amount
        
        -- Mark as given
        state.compensationGiven = true
        
        -- Notify player
        local message = "You've received " .. amount .. " cash as compensation for technical issues."
        
        -- Try to find notification system
        local NotificationSystem = CoreRegistry and CoreRegistry:GetSystem("NotificationSystem")
        if NotificationSystem then
            NotificationSystem:SendNotification(player, message)
        else
            -- Direct message
            ReplicatedStorage:FindFirstChild("NotificationEvent"):FireClient(player, message)
        end
        
        log("Provided " .. amount .. " compensation to " .. player.Name)
        return true, "Compensation provided: " .. amount
    end
    
    return false, "Failed to provide compensation"
end

-- Scheduled checks for player data integrity
local function scheduleIntegrityCheck(player)
    task.delay(CONFIG.RESTORATION_DELAY, function()
        if not player or not player:IsDescendantOf(Players) then
            return -- Player left
        end
        
        log("Running scheduled integrity check for " .. player.Name)
        
        local needsRestore, reason = needsRestoration(player)
        if needsRestore then
            log("Player " .. player.Name .. " needs restoration: " .. reason)
            
            local success, result = restorePlayerEquipment(player)
            if not success then
                log("Restoration failed: " .. result)
                
                -- Give compensation for failed restore
                provideCompensation(player, "MINOR_ISSUE")
            end
        else
            log("No restoration needed for " .. player.Name .. ": " .. reason)
        end
    end)
end

-- Handle player joining
local function onPlayerAdded(player)
    log("Player joined: " .. player.Name)
    
    -- Initialize restoration state
    getRestorationState(player)
    
    -- Schedule integrity check after delay
    if CONFIG.AUTO_RECOVERY_ENABLED then
        scheduleIntegrityCheck(player)
    end
end

-- Handle player leaving
local function onPlayerRemoving(player)
    -- Clean up restoration state
    playerRestorationState[player.UserId] = nil
    log("Cleaned up restoration state for " .. player.Name)
end

-- Connect player events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Process existing players
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        onPlayerAdded(player)
    end)
end

-- Create remote function for manual restoration requests
local RestoreProgressFunction = Instance.new("RemoteFunction")
RestoreProgressFunction.Name = "RestoreProgressFunction"
RestoreProgressFunction.Parent = ReplicatedStorage

-- Handle restoration requests
RestoreProgressFunction.OnServerInvoke = function(player)
    log("Manual restoration requested by " .. player.Name)
    
    local state = getRestorationState(player)
    
    -- Check if we've tried too many times recently
    if state.restorationAttempts >= CONFIG.MAX_RESTORE_ATTEMPTS and
       os.time() - state.lastAttemptTime < 600 then -- 10 minute cooldown
        return {
            success = false,
            message = "Too many restoration attempts. Please try again later.",
            cooldownRemaining = 600 - (os.time() - state.lastAttemptTime)
        }
    end
    
    -- Try restoration
    local success, result = restorePlayerEquipment(player)
    
    -- Try compensation if restoration failed
    if not success then
        local compensated, compResult = provideCompensation(player, "MINOR_ISSUE")
        
        if compensated then
            return {
                success = false,
                compensated = true,
                message = "Unable to restore your progress fully. You've been compensated with in-game currency.",
                compensationAmount = CONFIG.COMPENSATION_AMOUNTS.MINOR_ISSUE
            }
        else
            return {
                success = false,
                message = "Unable to restore your progress. Please contact support.",
                error = result
            }
        end
    end
    
    return {
        success = true,
        message = "Your progress has been restored!",
        result = result
    }
end

log("PlayerProgressRestoration initialized")

-- Export API
return {
    restorePlayerEquipment = restorePlayerEquipment,
    provideCompensation = provideCompensation,
    checkDataIntegrity = needsRestoration,
    getRestorationState = getRestorationState
}
