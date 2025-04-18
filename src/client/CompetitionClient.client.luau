-- CompetitionClient.client.luau
-- Client-side competition management
-- Updated as part of UI refinements initiative (April 2025)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get UI modules
local CompetitionUI = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("CompetitionUI"))

-- Private variables
local player = Players.LocalPlayer
local ClientRegistry
local ClientEventBridge
local UIManager
local UIHub
local updateInterval = 5 -- Update competition list every 5 seconds

-- Module table
local CompetitionClient = {}

-- Competition data cache
local cachedCompetitions = {}
local activeCompetitions = {}
local isInitialized = false
local isDebug = false

-- Utility function to log debug messages
local function log(message, isWarning)
    if isDebug then
        local prefix = "[CompetitionClient] "
        
        if isWarning then
            warn(prefix .. message)
        else
            print(prefix .. message)
        end
    end
end

-- Format time from seconds to MM:SS
local function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

-- Format duration from seconds to minutes
local function formatDuration(seconds)
    local minutes = math.floor(seconds / 60)
    if minutes == 1 then
        return "1 minute"
    else
        return minutes .. " minutes"
    end
end

-- Initialize the competition client module
function CompetitionClient:initialize()
    if isInitialized then 
        return true 
    end
    
    log("Initializing CompetitionClient...")
    
    -- Get dependencies from ClientRegistry
    ClientRegistry = require(script.Parent.Core.ClientRegistry)
    ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
    UIManager = ClientRegistry.getSystem("UIManager")
    
    if not ClientEventBridge or not UIManager then
        log("Missing dependencies, system may not function correctly", true)
        return false
    end
    
    -- Register UI module with UIManager
    UIManager.registerUIModule("CompetitionUI", CompetitionUI)
    
    -- Try to get UIHub (optional)
    UIHub = ClientRegistry.getSystem("UIHub")
    if UIHub then
        log("Registering with UIHub...")
        UIHub.registerMenuItem({
            id = "competitions",
            name = "Competitions",
            icon = "rbxassetid://7072706351", -- Trophy icon
            priority = 20,
            category = "progress",
            callback = function() 
                self:openCompetitionMenu() 
            end
        })
    end
    
    -- Subscribe to competition events
    ClientEventBridge.subscribe("CompetitionStarted", function(data)
        self:handleCompetitionStarted(data)
    end)
    
    ClientEventBridge.subscribe("CompetitionEnded", function(data)
        self:handleCompetitionEnded(data)
    end)
    
    -- Set callbacks for CompetitionUI
    CompetitionUI:SetCallbacks({
        onOpen = function()
            self:refreshCompetitionData()
        end,
        
        onStartCompetition = function(competitionId)
            return self:startCompetition(competitionId)
        end
    })
    
    -- Start periodic updates
    self:startPeriodicUpdates()
    
    isInitialized = true
    log("Initialized successfully")
    return true
end

-- Open competition menu
function CompetitionClient:openCompetitionMenu()
    UIManager.openUI("CompetitionUI", {})
    self:refreshCompetitionData()
end

-- Get competition data from server
function CompetitionClient:getCompetitions()
    local success, competitions = pcall(function()
        return ClientEventBridge.invokeServer("GetCompetitions")
    end)
    
    if success and competitions then
        cachedCompetitions = competitions
        return competitions
    else
        log("Failed to get competition data: " .. tostring(competitions), true)
        return cachedCompetitions -- Return last cached data on failure
    end
end

-- Refresh competition data and update UI
function CompetitionClient:refreshCompetitionData()
    local competitions = self:getCompetitions()
    
    -- Sort competitions: available first, then by cost
    table.sort(competitions, function(a, b)
        if a.available ~= b.available then
            return a.available
        end
        return a.cost < b.cost
    end)
    
    -- Update UI with competition data
    CompetitionUI:UpdateCompetitions(competitions)
end

-- Start a competition
function CompetitionClient:startCompetition(competitionId)
    local success, result = pcall(function()
        return ClientEventBridge.invokeServer("StartCompetition", competitionId)
    end)
    
    if success and result then
        -- Close the menu with delay
        task.delay(1.5, function()
            UIManager.closeUI("CompetitionUI")
        end)
        
        -- Show success notification
        UIManager.showNotification({
            title = "Competition Started",
            message = "Your competition has started successfully!",
            type = "success",
            duration = 5
        })
        
        return true, "Competition started successfully"
    else
        -- Show error notification
        UIManager.showNotification({
            title = "Error",
            message = tostring(result) or "Failed to start competition",
            type = "error",
            duration = 5
        })
        
        CompetitionUI:SetStatus("Failed: " .. tostring(result), UIStyle.colors.error)
        CompetitionUI:ResetStatus(3)
        
        return false, tostring(result) or "Failed to start competition"
    end
end

-- Handle competition started event
function CompetitionClient:handleCompetitionStarted(data)
    if data.playerName == player.Name then
        -- This is for the player who started it
        UIManager.showNotification({
            title = "Competition Started",
            message = "You've started a " .. data.competitionName .. "!",
            type = "success",
            duration = 5
        })
    else
        -- This is for other players
        UIManager.showNotification({
            title = "Competition Announcement",
            message = data.playerName .. " has started a " .. data.competitionName .. "!",
            type = "info",
            duration = 5
        })
    end
    
    -- Add to active competitions
    activeCompetitions[data.competitionId] = data
end

-- Handle competition ended event
function CompetitionClient:handleCompetitionEnded(data)
    if data.playerId == player.UserId then
        -- Only notify the player whose competition ended
        UIManager.showNotification({
            title = "Competition Ended",
            message = "Your " .. data.competitionName .. " has ended.",
            type = "info",
            duration = 5
        })
        
        -- Refresh competition data
        self:refreshCompetitionData()
    end
    
    -- Remove from active competitions
    activeCompetitions[data.competitionId] = nil
end

-- Start periodic updates for competition data
function CompetitionClient:startPeriodicUpdates()
    task.spawn(function()
        while true do
            task.wait(updateInterval)
            
            -- Only refresh if menu is open
            if UIManager and UIManager.isUIOpen and UIManager.isUIOpen("CompetitionUI") then
                self:refreshCompetitionData()
            end
        end
    end)
end

-- Set debug mode
function CompetitionClient:setDebug(enabled)
    isDebug = enabled
    return isDebug
end

-- Public API
return ClientRegistry.registerSystem("CompetitionClient", CompetitionClient, {"ClientEventBridge", "UIManager"})