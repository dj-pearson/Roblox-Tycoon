--[[
    CompetitionClient.luau
    Client-side controller for the competition system
    Handles communication between server CompetitionSystem and the UI module
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Client references
local Player = Players.LocalPlayer

-- Module dependencies
local ClientRegistry
local ClientEventBridge
local UIManager
local CompetitionUI

-- Module table
local CompetitionClient = {
    _name = "CompetitionClient",
    _version = "1.0.0",
    _dependencies = {"ClientRegistry", "ClientEventBridge", "UIManager"},
    
    -- Cache for competitions data
    _competitions = {},
    
    -- Update interval
    _updateInterval = 5, -- Update competition list every 5 seconds
    _updateLoop = nil
}

-- Debug function
local function debugPrint(...)
    print("[Competition Client]", ...)
end

--[[ Event Handlers ]]--

-- Handle competitions data update from server
function CompetitionClient:handleCompetitionsUpdate(competitions)
    -- Store competitions data
    self._competitions = competitions or {}
    
    -- Update UI if visible
    if CompetitionUI and CompetitionUI:IsVisible() then
        CompetitionUI:UpdateCompetitions(self._competitions)
    end
end


-- Handle competition start success
function CompetitionClient:handleCompetitionStarted(data)
    if not CompetitionUI then return end
    
    -- Update the status to show success
    CompetitionUI:SetStatus("Competition started successfully!", Color3.fromRGB(100, 255, 100))
    
    -- Play success sound
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://6042583773" -- Success sound
    sound.Volume = 0.5
    sound.Parent = Player.PlayerGui
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
    
    -- Close the menu after a delay
    task.delay(1.5, function()
        CompetitionUI:Toggle(false)
        
        -- Reset status text after closing
        task.delay(0.5, function()
            CompetitionUI:SetStatus("Your competition is now attracting new members!")
        end)
    end)
    
    -- Show notification
    if UIManager then
        UIManager:showNotification({
            title = "Competition Started",
            message = data.name .. " is now running for " .. data.duration .. " minutes!",
            icon = "rbxassetid://6031280882", -- Clock icon
            duration = 5
        })
    end
end

-- Handle competition start failure
function CompetitionClient:handleCompetitionFailed(reason)
    if not CompetitionUI then return end
    
    CompetitionUI:SetStatus("Error: " .. reason, Color3.fromRGB(255, 100, 100))
    
    -- Reset status after a delay
    task.delay(3, function()
        CompetitionUI:SetStatus()
    end)
end


-- Handle competition ending
function CompetitionClient:handleCompetitionEnded(data)
    -- Update competitions list
    self:requestCompetitions()
    
    -- Show notification
    if UIManager then
        UIManager:showNotification({
            title = "Competition Ended",
            message = "Your " .. data.name .. " competition has ended.",
            duration = 4
        })
    end
end 


--[[ Server Communication ]]--

-- Request competitions list from server
function CompetitionClient:requestCompetitions()
    if ClientEventBridge then
        ClientEventBridge:fireServer("RequestCompetitions")
    end
end

-- Request to start a competition
function CompetitionClient:requestStartCompetition(competitionId)
    if not competitionId then return false end
    
    -- Check if player has enough cash first
    local leaderstats = Player:FindFirstChild("leaderstats")
    if not leaderstats or not leaderstats:FindFirstChild("Cash") then
        if CompetitionUI then
            CompetitionUI:SetStatus("Error accessing player data!", Color3.fromRGB(255, 100, 100))
        end
        return false
    end
    
    -- Find competition info
    local competition
    for _, comp in ipairs(self._competitions) do
        if comp.id == competitionId then
            competition = comp
            break
        end
    end
    
    if not competition then
        if CompetitionUI then
            CompetitionUI:SetStatus("Competition not found!", Color3.fromRGB(255, 100, 100))
        end
        return false
    end
    
    -- Check if player has enough money
    if leaderstats.Cash.Value < competition.cost then
        if CompetitionUI then
            CompetitionUI:SetStatus("Not enough money to start this competition!", Color3.fromRGB(255, 100, 100))
            
            -- Reset after delay
            task.delay(3, function()
                CompetitionUI:SetStatus()
            end)
        end
        return false
    end
    
    -- Show pending status
    if CompetitionUI then
        CompetitionUI:SetStatus("Starting competition...", Color3.fromRGB(255, 255, 0))
    end
    
    -- Send request to server
    if ClientEventBridge then
        ClientEventBridge:fireServer("StartCompetition", competitionId)
    end
    
    return true
end


--[[ Client UI Management ]]--

-- Initialize the UI
function CompetitionClient:initializeUI()
    -- Try to get the UI module from ReplicatedStorage
    local uiModules = ReplicatedStorage:FindFirstChild("UIModules")
    if uiModules then
        local competitionUIModule = uiModules:FindFirstChild("CompetitionUI")
        if competitionUIModule then
            CompetitionUI = require(competitionUIModule)
            
            -- Initialize the UI module
            if CompetitionUI then
                -- Set up competition UI with UIManager
                CompetitionUI:Initialize(UIManager)
                
                -- Configure UI callbacks
                CompetitionUI:SetCallbacks({
                    onOpen = function()
                        -- Request fresh data when opened
                        self:requestCompetitions()
                    end,
                    onStartCompetition = function(competitionId)
                        -- Request to start a competition
                        self:requestStartCompetition(competitionId)
                    end
                })
                
                debugPrint("CompetitionUI module initialized")
            end
        else
            warn("CompetitionUI module not found")
        end
    end
end


-- Start update loop for competitions data
function CompetitionClient:startUpdateLoop()
    if self._updateLoop then
        task.cancel(self._updateLoop)
    end
    
    self._updateLoop = task.spawn(function()
        while true do
            task.wait(self._updateInterval)
            
            if CompetitionUI and CompetitionUI:IsVisible() then
                self:requestCompetitions()
            end
        end
    end)
end


--[[ Initialization ]]--

function CompetitionClient:init()
    debugPrint("Initializing CompetitionClient v" .. self._version)
    
    -- Get dependencies
    ClientRegistry = self.ClientRegistry
    ClientEventBridge = ClientRegistry:getSystem("ClientEventBridge")
    UIManager = ClientRegistry:getSystem("UIManager")
    
    -- Initialize UI
    self:initializeUI()
    
    return true
end


function CompetitionClient:start()
    debugPrint("Starting CompetitionClient")
    
    -- Register event handlers
    if ClientEventBridge then
        -- Register for server events
        ClientEventBridge:registerServerEvent("CompetitionsUpdate", function(competitions)
            self:handleCompetitionsUpdate(competitions)
        end)
        
        ClientEventBridge:registerServerEvent("CompetitionStarted", function(data)
            self:handleCompetitionStarted(data)
        end)
        
        ClientEventBridge:registerServerEvent("CompetitionFailed", function(reason)
            self:handleCompetitionFailed(reason)
        end)
        
        ClientEventBridge:registerServerEvent("CompetitionEnded", function(data)
            self:handleCompetitionEnded(data)
        end)
    end
    
    -- Start update loop
    self:startUpdateLoop()
    
    -- Initial data request
    task.delay(2, function()
        self:requestCompetitions()
    end)
    
    return true
end

function CompetitionClient:stop()
    debugPrint("Stopping CompetitionClient")
    
    -- Stop update loop
    if self._updateLoop then
        task.cancel(self._updateLoop)
        self._updateLoop = nil
    end
    
    return true
end

return CompetitionClient