-- SeasonalSystem.luau
-- Server-side implementation of seasonal events system
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import server-side systems
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")
local DataManager = CoreRegistry.getSystem("DataManager")
local SpecializationSystem = CoreRegistry.getSystem("SpecializationSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    checkInterval = 60, -- Check for expired events every minute
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[SeasonalSystem]", ...)
    end
end

-- The SeasonalSystem object
local SeasonalSystem = {
    -- Currently active global seasonal event
    currentSeason = nil,
    
    -- Players with active seasonal bonuses
    playerSeasonalBoosts = {},
    
    initialized = false,
    
    -- Definitions of seasonal events
    seasons = {
        summerBeachBody = {
            name = "Summer Beach Body Program",
            description = "Attract more members with summer-focused training programs",
            duration = 14, -- Days
            icon = "rbxassetid://12345678", -- Replace with actual ID
            benefits = {
                membership_boost = 1.4, -- 40% more members
                specific_equipment_boost = {"outdoor", "cardio"}, -- Boost for specific equipment
                member_satisfaction = 1.2
            },
            requirements = {
                gym_level = 2 -- Minimum gym level to participate
            }
        },

        newYearResolution = {
            name = "New Year's Resolution Program",
            description = "Capitalize on New Year's fitness resolutions with beginner-friendly programs",
            duration = 21,
            icon = "rbxassetid://12345679",
            benefits = {
                membership_boost = 1.5, -- 50% more members
                retention_penalty = 0.7, -- But members leave faster
                dues_boost = 1.2 -- 20% more membership fees
            },
            requirements = {
                gym_level = 3
            }
        },

        summerSlim = {
            name = "Summer Slim Down Challenge",
            description = "Help members get beach-ready with intensive cardio programs",
            duration = 14,
            icon = "rbxassetid://12345680",
            benefits = {
                cardio_equipment_boost = 1.5, -- Cardio equipment efficiency boost
                membership_boost = 1.3,
                vip_chance = 0.15
            },
            requirements = {
                gym_level = 2,
                min_cardio_equipment = 3 -- Requires at least 3 cardio machines
            }
        },

        fallFitness = {
            name = "Fall Fitness Challenge",
            description = "Keep members engaged with seasonal challenges",
            duration = 18,
            icon = "rbxassetid://12345681",
            benefits = {
                retention_boost = 1.3, -- Better retention
                dues_boost = 1.15,
                competition_boost = 1.2
            },
            requirements = {
                gym_level = 4
            }
        },

        winterBulk = {
            name = "Winter Bulk Program",
            description = "Focused strength training during winter months",
            duration = 28,
            icon = "rbxassetid://12345682",
            benefits = {
                membership_boost = 1.2,
                strength_equipment_boost = 1.4,
                vip_chance = 0.18
            },
            requirements = {
                gym_level = 3,
                min_strength_equipment = 4
            }
        }
    }
}

-- Count specific equipment types in a player's tycoon
function SeasonalSystem:countEquipmentType(player, equipmentType)
    if not player or not equipmentType then return 0 end
    
    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then return 0 end
    
    local count = 0
    
    -- Search for equipment based on type
    for _, obj in pairs(tycoon.Value:GetDescendants()) do
        if obj:GetAttribute("EquipmentType") == equipmentType or
           obj.Name:lower():find(equipmentType:lower()) then
            count = count + 1
        end
    end
    
    return count
end

-- Check if player meets requirements for a seasonal event
function SeasonalSystem:checkRequirements(player, seasonId)
    if not player or not seasonId then return false end

    local season = self.seasons[seasonId]
    if not season then return false end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then return false end

    -- Check gym level
    local gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or 1
    if gymLevel < season.requirements.gym_level then
        return false, "Your gym needs to be level " .. season.requirements.gym_level
    end

    -- Check equipment requirements if any
    if season.requirements.min_cardio_equipment then
        local cardioCount = self:countEquipmentType(player, "cardio")
        if cardioCount < season.requirements.min_cardio_equipment then
            return false, "You need at least " .. season.requirements.min_cardio_equipment .. " cardio machines"
        end
    end

    if season.requirements.min_strength_equipment then
        local strengthCount = self:countEquipmentType(player, "strength")
        if strengthCount < season.requirements.min_strength_equipment then
            return false, "You need at least " .. season.requirements.min_strength_equipment .. " strength equipment pieces"
        end
    end

    return true
end

-- Get available seasonal events for a player
function SeasonalSystem:getAvailableSeasons(player)
    if not player then return {} end

    local available = {}

    for id, season in pairs(self.seasons) do
        local meetsRequirements, reason = self:checkRequirements(player, id)

        table.insert(available, {
            id = id,
            name = season.name,
            description = season.description,
            duration = season.duration,
            icon = season.icon,
            available = meetsRequirements,
            reason = not meetsRequirements and reason or nil,
            active = self.playerSeasonalBoosts[player.UserId] and 
                     self.playerSeasonalBoosts[player.UserId].seasonId == id
        })
    end

    return available
end

-- Apply seasonal bonuses to a player
function SeasonalSystem:applySeasonalBonuses(player, seasonId)
    if not player or not seasonId then return false end

    local season = self.seasons[seasonId]
    if not season then return false, "Invalid seasonal event" end

    -- Check requirements
    local meetsRequirements, reason = self:checkRequirements(player, seasonId)
    if not meetsRequirements then
        return false, reason
    end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then return false, "Tycoon not found" end

    -- Apply bonuses
    if season.benefits.membership_boost then
        tycoon:SetAttribute("SeasonalMembershipBoost", season.benefits.membership_boost)
    end

    if season.benefits.dues_boost then
        tycoon:SetAttribute("SeasonalDuesBoost", season.benefits.dues_boost)
    end

    if season.benefits.vip_chance then
        tycoon:SetAttribute("SeasonalVIPChance", season.benefits.vip_chance)
    end

    if season.benefits.retention_boost then
        tycoon:SetAttribute("SeasonalRetentionBoost", season.benefits.retention_boost)
    end

    if season.benefits.retention_penalty then
        tycoon:SetAttribute("SeasonalRetentionPenalty", season.benefits.retention_penalty)
    end

    if season.benefits.competition_boost then
        tycoon:SetAttribute("SeasonalCompetitionBoost", season.benefits.competition_boost)
    end

    -- Calculate end time
    local durationInSeconds = season.duration * 24 * 60 * 60 -- Convert days to seconds
    local endTime = os.time() + durationInSeconds

    -- Store in player data
    tycoon:SetAttribute("ActiveSeason", seasonId)
    tycoon:SetAttribute("SeasonEndTime", endTime)

    -- Store in module data for tracking
    self.playerSeasonalBoosts[player.UserId] = {
        seasonId = seasonId,
        endTime = endTime
    }
    
    -- Save to player data if using DataManager
    if DataManager then
        DataManager.updateData(player, "activeSeason", {
            id = seasonId,
            endTime = endTime
        })
    end

    -- Update any relevant systems
    local GymRevenueSystem = CoreRegistry.getSystem("GymRevenueSystem")
    if GymRevenueSystem and GymRevenueSystem.updatePlayerConfig then
        GymRevenueSystem.updatePlayerConfig(player)
    end
    
    -- Send notification to client
    EventBridge.fireClientEvent("NotificationReceived", player, {
        title = "Seasonal Event Started",
        message = season.name .. "\nActive for " .. season.duration .. " days!",
        type = "success",
        duration = 5
    })
    
    -- Broadcast event
    EventBridge.fireEvent("PlayerJoinedSeason", player, seasonId)
    EventBridge.fireClientEvent("SeasonalStatusChanged", player, {
        active = true,
        seasonId = seasonId,
        name = season.name, 
        endTime = endTime
    })

    return true, "Seasonal event started successfully"
end

-- Remove seasonal bonuses from a player
function SeasonalSystem:removeSeasonalBonuses(player)
    if not player then return false end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then return false end
    
    -- Get the season info before removing it
    local activeSeasonId = tycoon:GetAttribute("ActiveSeason")
    local seasonInfo = activeSeasonId and self.seasons[activeSeasonId]

    -- Remove all seasonal attributes
    tycoon:SetAttribute("SeasonalMembershipBoost", nil)
    tycoon:SetAttribute("SeasonalDuesBoost", nil)
    tycoon:SetAttribute("SeasonalVIPChance", nil)
    tycoon:SetAttribute("SeasonalRetentionBoost", nil)
    tycoon:SetAttribute("SeasonalRetentionPenalty", nil)
    tycoon:SetAttribute("SeasonalCompetitionBoost", nil)
    tycoon:SetAttribute("ActiveSeason", nil)
    tycoon:SetAttribute("SeasonEndTime", nil)

    -- Remove from tracking
    self.playerSeasonalBoosts[player.UserId] = nil
    
    -- Update player data
    if DataManager then
        DataManager.updateData(player, "activeSeason", nil)
    end

    -- Update any relevant systems
    local GymRevenueSystem = CoreRegistry.getSystem("GymRevenueSystem")
    if GymRevenueSystem and GymRevenueSystem.updatePlayerConfig then
        GymRevenueSystem.updatePlayerConfig(player)
    end
    
    -- Send notification if there was an active season
    if seasonInfo then
        EventBridge.fireClientEvent("NotificationReceived", player, {
            title = "Seasonal Event Ended",
            message = seasonInfo.name .. " has ended!\nYour gym has returned to normal operations.",
            type = "info",
            duration = 5
        })
    end
    
    -- Broadcast event
    EventBridge.fireEvent("PlayerLeftSeason", player, activeSeasonId)
    EventBridge.fireClientEvent("SeasonalStatusChanged", player, {
        active = false
    })

    return true
end

-- Check for expired seasonal events
function SeasonalSystem:checkExpiredEvents()
    local currentTime = os.time()

    for userId, data in pairs(self.playerSeasonalBoosts) do
        if currentTime >= data.endTime then
            -- Find player
            local player = Players:GetPlayerByUserId(userId)
            if player then
                -- Remove bonuses
                self:removeSeasonalBonuses(player)
            else
                -- Player not found, just remove from tracking
                self.playerSeasonalBoosts[userId] = nil
            end
        end
    end
end

-- Start a global seasonal event
function SeasonalSystem:startGlobalSeason(seasonId)
    if not seasonId or not self.seasons[seasonId] then
        return false, "Invalid seasonal event"
    end

    -- Set current global season
    self.currentSeason = {
        id = seasonId,
        name = self.seasons[seasonId].name,
        startTime = os.time(),
        endTime = os.time() + (self.seasons[seasonId].duration * 24 * 60 * 60)
    }

    -- Notify all players
    for _, player in pairs(Players:GetPlayers()) do
        EventBridge.fireClientEvent("NotificationReceived", player, {
            title = "Seasonal Event Available",
            message = self.seasons[seasonId].name .. "\nCheck the Seasonal Events menu to participate!",
            type = "info",
            duration = 5
        })
    end

    -- Broadcast the event to all clients
    EventBridge.fireAllClientsEvent("GlobalSeasonStarted", {
        id = seasonId,
        name = self.seasons[seasonId].name,
        endTime = self.currentSeason.endTime
    })
    
    -- Broadcast server event
    EventBridge.fireEvent("GlobalSeasonStarted", seasonId)

    return true, "Global seasonal event started"
end

-- End global seasonal event
function SeasonalSystem:endGlobalSeason()
    if not self.currentSeason then
        return false, "No active seasonal event"
    end

    local oldSeason = self.currentSeason
    self.currentSeason = nil

    -- Notify all players
    for _, player in pairs(Players:GetPlayers()) do
        EventBridge.fireClientEvent("NotificationReceived", player, {
            title = "Seasonal Event Ended",
            message = oldSeason.name .. " has ended globally!",
            type = "info",
            duration = 5
        })
    end
    
    -- Broadcast the event to all clients
    EventBridge.fireAllClientsEvent("GlobalSeasonEnded", {
        id = oldSeason.id,
        name = oldSeason.name
    })
    
    -- Broadcast server event
    EventBridge.fireEvent("GlobalSeasonEnded", oldSeason.id)

    return true, "Global seasonal event ended"
end

-- Setup server events
function SeasonalSystem:setupServerEvents()
    -- Join seasonal event
    EventBridge.registerClientToServerEvent("JoinSeasonalEvent", function(player, seasonId)
        local success, message = self:applySeasonalBonuses(player, seasonId)
        
        -- Send response to client
        EventBridge.fireClientEvent("SeasonalEventResponse", player, {
            success = success,
            message = message
        })
        
        return success
    end)
    
    -- Leave seasonal event
    EventBridge.registerClientToServerEvent("LeaveSeasonalEvent", function(player)
        local success = self:removeSeasonalBonuses(player)
        
        -- Send response to client
        EventBridge.fireClientEvent("SeasonalEventResponse", player, {
            success = success,
            message = success and "Left seasonal event" or "Failed to leave seasonal event"
        })
        
        return success
    end)
    
    -- Get available seasons request
    EventBridge.registerClientToServerEvent("RequestAvailableSeasons", function(player)
        local availableSeasons = self:getAvailableSeasons(player)
        
        -- Send data to client
        EventBridge.fireClientEvent("AvailableSeasonsData", player, {
            seasons = availableSeasons,
            globalSeason = self.currentSeason
        })
        
        return true
    end)
    
    -- Admin commands for managing seasons (these would be secured in a real implementation)
    EventBridge.registerClientToServerEvent("AdminStartGlobalSeason", function(player, seasonId)
        -- Check if player is an admin
        if player:GetAttribute("IsAdmin") then
            local success, message = self:startGlobalSeason(seasonId)
            return success, message
        end
        return false, "Unauthorized"
    end)
    
    EventBridge.registerClientToServerEvent("AdminEndGlobalSeason", function(player)
        -- Check if player is an admin
        if player:GetAttribute("IsAdmin") then
            local success, message = self:endGlobalSeason()
            return success, message
        end
        return false, "Unauthorized"
    end)
end

-- Load player seasonal data
function SeasonalSystem:loadPlayerSeasonalData(player)
    if not player or not DataManager then return end
    
    -- Get active season from player data
    local data = DataManager.getPlayerData(player)
    if data and data.activeSeason then
        local activeSeason = data.activeSeason
        
        -- Check if the season is still valid
        if activeSeason.endTime > os.time() then
            -- Re-apply the seasonal bonuses
            self:applySeasonalBonuses(player, activeSeason.id)
        else
            -- Season has expired, clean up data
            DataManager.updateData(player, "activeSeason", nil)
        end
    end
end

-- Initialize the system
function SeasonalSystem:initialize()
    log("Initializing SeasonalSystem...")
    
    -- Set up server events
    self:setupServerEvents()
    
    -- Start expired events check loop
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            self:checkExpiredEvents()
        end
    end)
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:loadPlayerSeasonalData(player)
    end
    
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        -- Wait for character to load
        player.CharacterAdded:Wait()
        task.wait(3)
        
        -- Load seasonal data
        self:loadPlayerSeasonalData(player)
    end)
    
    -- Clean up when players leave
    Players.PlayerRemoving:Connect(function(player)
        -- Just remove from tracking - data is preserved in DataManager
        self.playerSeasonalBoosts[player.UserId] = nil
    end)
    
    self.initialized = true
    log("SeasonalSystem initialized")
    
    -- For testing purposes, start with a seasonal event
    -- Uncomment for testing
    -- self:startGlobalSeason("summerBeachBody")
    
    return true
end

-- Public API
local PublicAPI = {
    initialize = function()
        return SeasonalSystem:initialize()
    end,
    
    getSeasons = function()
        return SeasonalSystem.seasons
    end,
    
    getCurrentGlobalSeason = function()
        return SeasonalSystem.currentSeason
    end,
    
    getPlayerActiveSeason = function(player)
        if not player then return nil end
        
        local userId = player.UserId
        if SeasonalSystem.playerSeasonalBoosts[userId] then
            local seasonId = SeasonalSystem.playerSeasonalBoosts[userId].seasonId
            return {
                id = seasonId,
                name = SeasonalSystem.seasons[seasonId] and SeasonalSystem.seasons[seasonId].name,
                endTime = SeasonalSystem.playerSeasonalBoosts[userId].endTime
            }
        end
        return nil
    end,
    
    getAvailableSeasons = function(player)
        return SeasonalSystem:getAvailableSeasons(player)
    end,
    
    applySeasonalBonuses = function(player, seasonId)
        return SeasonalSystem:applySeasonalBonuses(player, seasonId)
    end,
    
    removeSeasonalBonuses = function(player)
        return SeasonalSystem:removeSeasonalBonuses(player)
    end,
    
    startGlobalSeason = function(seasonId)
        return SeasonalSystem:startGlobalSeason(seasonId)
    end,
    
    endGlobalSeason = function()
        return SeasonalSystem:endGlobalSeason()
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("SeasonalSystem", PublicAPI, {"EventBridge", "DataManager", "SpecializationSystem"})