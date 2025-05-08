--!strict
--[[
    BuyTileSystemIntegration.server.luau
    
    This script integrates the GymPartsScanner with the BuyTileSystem and ensures proper
    initialization sequence and event handling. It also provides commands and methods
    to manage the integration between these systems.
    
    Created April 28, 2025
    Updated May 2025 - Simplified integration with CoreRegistry
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Direct imports from Core
local CoreRegistry = require(script.Parent.CoreRegistry)
local BuyTileSystem = require(script.Parent.BuyTileSystem)
local GymPartsScanner = require(script.Parent.GymPartsScanner)
local TileDataInitializer = require(script.Parent.TileDataInitializer)
local EventBridge = require(script.Parent.EventBridge)

-- Integration module
local BuyTileSystemIntegration = {
    initialized = false,
    automatedSetupComplete = false,
    Debug = false,
    Version = "2.0.0"
}

-- Log with timestamp
local function log(message, level)
    if not BuyTileSystemIntegration.Debug and level == "DEBUG" then
        return
    end
    
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    print(string.format("[BuyTileIntegration %s %s] %s", timestamp, level, message))
end

-- Run full system initialization
function BuyTileSystemIntegration.initialize()
    if BuyTileSystemIntegration.initialized then
        log("Already initialized", "WARN")
        return true
    end
    
    log("Starting BuyTileSystem integration v" .. BuyTileSystemIntegration.Version, "INFO")
    
    -- Initialize BuyTileSystem first
    if not BuyTileSystem:Initialize() then
        log("BuyTileSystem initialization failed", "ERROR")
        return false
    end
    
    -- Register events
    EventBridge:RegisterEvent("BuyTileSystem_Integrated")
    EventBridge:RegisterEvent("BuyTileSystem_SetupFromGymParts")
    
    -- Listen for GymPartsScanner setup completion
    EventBridge:ListenForEvent("GymPartsScanner_SetupComplete", function(data)
        log("GymPartsScanner setup completed with result: " .. tostring(data.success), "INFO")
        
        if data.success then
            BuyTileSystemIntegration.automatedSetupComplete = true
            EventBridge:FireEvent("BuyTileSystem_SetupFromGymParts", {
                success = true,
                timestamp = os.time()
            })
        end
    end)
    
    BuyTileSystemIntegration.initialized = true
    log("Integration initialized successfully", "INFO")
    
    -- Run automated setup
    task.spawn(function()
        local success = GymPartsScanner:SetupBuyTileSystem()
        log("Automated setup result: " .. tostring(success), "INFO")
        
        if success then
            EventBridge:FireEvent("BuyTileSystem_Integrated", {
                timestamp = os.time(),
                version = BuyTileSystemIntegration.Version
            })
        end
    end)
    
    return true
end

-- Generate tile data from different sources
function BuyTileSystemIntegration.generateTileData(source)
    source = source or "auto"
    log("Generating tile data from source: " .. source, "INFO")
    
    local success = false
    
    if source == "gymparts" or source == "scanner" then
        success = GymPartsScanner:SetupBuyTileSystem()
    elseif source == "initializer" or source == "structure" then
        success = TileDataInitializer:InitializeTileData()
    elseif source == "auto" then
        -- Try GymPartsScanner first, fall back to TileDataInitializer
        success = GymPartsScanner:SetupBuyTileSystem()
        
        if not success then
            success = TileDataInitializer:InitializeTileData()
        end
    else
        log("Unknown source: " .. source, "ERROR")
        return false
    end
    
    log("Tile data generation result: " .. tostring(success), "INFO")
    return success
end

-- Check and repair tile data
function BuyTileSystemIntegration.validateAndRepair()
    log("Validating BuyTile system structures", "INFO")
    
    -- Check if BuyTileSystem has tile data
    local tileData = BuyTileSystem:GetAllTileData()
    local hasTileData = type(tileData) == "table" and next(tileData) ~= nil
    
    if hasTileData then
        local count = 0
        for _ in pairs(tileData) do
            count = count + 1
        end
        log("Found " .. count .. " tile data entries", "INFO")
        return true
    end
    
    -- If no tile data, attempt auto setup
    log("No tile data found, attempting auto setup", "WARN")
    return BuyTileSystemIntegration.generateTileData("auto")
end

-- Register commands
local function registerCommands()
    local CommandService = CoreRegistry:GetSystem("CommandService")
    if not CommandService then return end
    
    CommandService:RegisterCommand("integrateBuyTile", {
        description = "Integrates the BuyTile system with GymPartsScanner",
        handler = function(player)
            -- Check if player is admin
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            local success = BuyTileSystemIntegration.initialize()
            return success 
                and "Successfully integrated BuyTile system" 
                or "Failed to integrate BuyTile system"
        end
    })
    
    CommandService:RegisterCommand("generateTileData", {
        description = "Generates tile data from specified source (gymparts, initializer, auto)",
        handler = function(player, args)
            -- Check if player is admin
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            local source = args and args[1] or "auto"
            local success = BuyTileSystemIntegration.generateTileData(source)
            return success 
                and "Successfully generated tile data from " .. source 
                or "Failed to generate tile data from " .. source
        end
    })
end

-- Register with CoreRegistry
if CoreRegistry then
    CoreRegistry:RegisterSystem("BuyTileSystemIntegration", BuyTileSystemIntegration)
    registerCommands()
end

return BuyTileSystemIntegration
