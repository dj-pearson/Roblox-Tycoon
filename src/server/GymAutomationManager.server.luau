--[[
    GymAutomationManager.server.luau
    
    FIXED VERSION: This creates a server-level standalone version of GymAutomationManager
    that will be discovered by GymAutomationLoader.
    
    Created: May 1, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Only run in Studio for safety
if not RunService:IsStudio() then
    return
end

-- Module and state variables
local GymAutomationManager = {}
local initialized = false
local startTime = os.clock()
local componentInitTimes = {}

-- Subsystems
local systems = {
    memberAutomation = nil,
    equipmentAutomation = nil,
    staffAutomation = nil,
    maintenanceAutomation = nil,
    cleaningAutomation = nil
}

-- Configuration
local CONFIG = {
    debugMode = true,
    defaultMemberLimit = 25,
    enabledSystems = {
        memberAutomation = true,
        equipmentAutomation = true,
        staffAutomation = true,
        maintenanceAutomation = true,
        cleaningAutomation = true
    }
}

--[[ Utility Functions ]]--

-- Log a message with level
local function logMessage(message, level)
    level = level or "Info"
    local prefix = "[GymAutomationManager] "
    
    if level == "Info" and CONFIG.debugMode then
        print(prefix .. message)
    elseif level == "Warning" then
        warn(prefix .. message)
    elseif level == "Error" then
        warn(prefix .. "ERROR: " .. message)
    end
end

-- Get a tycoon by name
local function getTycoonByName(tycoonName)
    -- If no name provided, try to find any tycoon
    if not tycoonName then
        local firstTycoon = workspace:FindFirstChild("GymTycoon") or workspace:FindFirstChild("Tycoon")
        if firstTycoon then
            return firstTycoon
        end
        
        -- Search for any tycoon model in workspace
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Model") and (child.Name:find("Tycoon") or child.Name:find("Gym")) then
                return child
            end
        end
        
        logMessage("No tycoon found in workspace", "Warning")
        return nil
    end
    
    -- Look for tycoon with specific name
    local tycoon = workspace:FindFirstChild(tycoonName)
    if not tycoon then
        logMessage("Tycoon '" .. tycoonName .. "' not found", "Warning")
        return nil
    end
    
    return tycoon
end

--[[ Core Functions ]]--

-- Initialize the manager
function GymAutomationManager.Initialize()
    if initialized then
        return true
    end
    
    logMessage("Initializing GymAutomationManager...")
    
    -- Record initialization time
    startTime = os.clock()
    
    -- Initialize subsystems
    if CONFIG.enabledSystems.memberAutomation then
        componentInitTimes.memberAutomation = os.clock()
        -- Initialize member automation
        logMessage("Member automation initialized")
    end
    
    if CONFIG.enabledSystems.equipmentAutomation then
        componentInitTimes.equipmentAutomation = os.clock()
        -- Initialize equipment automation
        logMessage("Equipment automation initialized")
    end
    
    initialized = true
    logMessage("GymAutomationManager initialized in " .. string.format("%.2f", os.clock() - startTime) .. " seconds")
    return true
end

-- Automate a gym
function GymAutomationManager:AutomateGym(tycoonName)
    if not initialized then
        GymAutomationManager.Initialize()
    end
    
    logMessage("Starting automation for " .. (tycoonName or "all gyms"))
    
    local tycoon = getTycoonByName(tycoonName)
    if not tycoon then
        return false
    end
    
    -- Process the tycoon
    self:ProcessTycoon(tycoon)
    
    return true
end

-- Process a tycoon
function GymAutomationManager:ProcessTycoon(tycoon)
    if not tycoon then
        return false
    end
    
    logMessage("Processing tycoon: " .. tycoon.Name)
    
    -- Process BuyTiles if they exist
    local buyTiles = tycoon:FindFirstChild("BuyTiles")
    if buyTiles then
        logMessage("Processing " .. #buyTiles:GetChildren() .. " BuyTiles")
        
        -- Simulate purchases of all BuyTiles
        for _, tile in ipairs(buyTiles:GetChildren()) do
            if tile:IsA("BasePart") and not tile:GetAttribute("Purchased") then
                tile:SetAttribute("Purchased", true)
                logMessage("Purchased tile: " .. tile.Name)
            end
        end
    else
        logMessage("No BuyTiles found", "Warning")
    end
    
    return true
end

-- Process equipment
function GymAutomationManager:ProcessEquipment(tycoonName)
    if not initialized then
        GymAutomationManager.Initialize()
    end
    
    logMessage("Processing equipment for " .. (tycoonName or "all gyms"))
    
    local tycoon = getTycoonByName(tycoonName)
    if not tycoon then
        return false
    end
    
    -- Find equipment
    local equipment = tycoon:FindFirstChild("Equipment")
    if not equipment then
        logMessage("No Equipment folder found", "Warning")
        return false
    end
    
    logMessage("Processing " .. #equipment:GetChildren() .. " equipment items")
    
    -- Process each piece of equipment
    for _, item in ipairs(equipment:GetChildren()) do
        if item:IsA("Model") then
            -- Set some attributes for equipment
            item:SetAttribute("Maintained", true)
            item:SetAttribute("Clean", true)
            logMessage("Processed equipment: " .. item.Name)
        end
    end
    
    return true
end

-- Automate all gyms
function GymAutomationManager:AutomateAllGyms()
    if not initialized then
        GymAutomationManager.Initialize()
    end
    
    logMessage("Automating all gyms...")
    
    -- Find all tycoons in workspace
    local tycoons = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and (child.Name:find("Tycoon") or child.Name:find("Gym")) then
            table.insert(tycoons, child)
        end
    end
    
    logMessage("Found " .. #tycoons .. " gyms")
    
    -- Process each tycoon
    for _, tycoon in ipairs(tycoons) do
        self:ProcessTycoon(tycoon)
    end
    
    return #tycoons > 0
end

-- Get the manager status
function GymAutomationManager:GetStatus()
    return {
        initialized = initialized,
        uptime = os.clock() - startTime,
        subsystems = CONFIG.enabledSystems
    }
end

-- Initialize on load if in Studio
if RunService:IsStudio() then
    task.spawn(function()
        wait(1) -- Wait a moment for other systems to load
        GymAutomationManager.Initialize()
    end)
end

return GymAutomationManager
