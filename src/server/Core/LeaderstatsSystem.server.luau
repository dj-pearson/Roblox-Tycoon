luau
-- LeaderstatsSystem.server.luau
-- Manages the leaderstats for players

local ServerScriptService = game:GetService("ServerScriptService")
local CoreFolder = ServerScriptService:WaitForChild("Core")
local CoreRegistry = require(CoreFolder:WaitForChild("CoreRegistry"))

local LeaderstatsSystem = {}
LeaderstatsSystem.Name = "LeaderstatsSystem"
LeaderstatsSystem.Dependencies = {"CoreRegistry"}

local CONFIG = {
    startingCash = 500, -- Starting cash for new players
    debug = true
}

local function debugPrint(...)
    if CONFIG.debug then
        print("[LeaderstatsSystem]", ...)
    end
end

local function setupLeaderstats(player)
    if not player or player:FindFirstChild("leaderstats") then
        return
    end

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local cash = Instance.new("IntValue")
    cash.Name = "Cash"
    cash.Value = CONFIG.startingCash
    cash.Parent = leaderstats
    
    debugPrint("Created leaderstats for " .. player.Name)
end

function LeaderstatsSystem:initialize()
    debugPrint("Initializing LeaderstatsSystem...")
    
    -- Handle existing players
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        setupLeaderstats(player)
    end
    
    -- Handle player joins
    game:GetService("Players").PlayerAdded:Connect(function(player)
        setupLeaderstats(player)
    end)
    
    debugPrint("LeaderstatsSystem initialized.")
end

function LeaderstatsSystem:shutdown()
    debugPrint("Shutting down LeaderstatsSystem...")
end

return CoreRegistry.registerSystem("LeaderstatsSystem", LeaderstatsSystem, {"CoreRegistry"})