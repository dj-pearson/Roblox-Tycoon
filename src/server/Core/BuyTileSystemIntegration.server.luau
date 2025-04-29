--[[
    BuyTileSystemIntegration.server.luau
    
    This script integrates the GymPartsScanner with the BuyTileSystem and ensures proper
    initialization sequence and event handling. It also provides commands and methods
    to manage the integration between these systems.
    
    Created April 28, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Find a module
local function findModule(moduleName)
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
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
        warn("BuyTileSystemIntegration: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Find CoreRegistry and key systems
local CoreRegistry = safeRequire(findModule("CoreRegistry"))
local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")
local TileDataInitializer = CoreRegistry and CoreRegistry:GetSystem("TileDataInitializer")
local EventBridge = CoreRegistry and CoreRegistry:GetSystem("EventBridge") or { 
    fireEvent = function() end,
    registerEvent = function() end,
    listenForEvent = function() end
}

-- Find scanner module
local GymPartsScanner = safeRequire(findModule("GymPartsScanner.server"))

-- Integration module
local BuyTileSystemIntegration = {
    initialized = false,
    automatedSetupComplete = false,
    Debug = false
}

-- Log with timestamp
local function log(message, level)
    if not BuyTileSystemIntegration.Debug and level == "DEBUG" then
        return
    end
    
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    print("[BuyTileIntegration " .. timestamp .. " " .. level .. "] " .. message)
end

-- Run full system initialization
function BuyTileSystemIntegration.initialize()
    if BuyTileSystemIntegration.initialized then
        log("Already initialized", "WARN")
        return true
    end
    
    log("Starting BuyTileSystem integration", "INFO")
    
    -- Check for prerequisites
    if not CoreRegistry then
        log("CoreRegistry not found, initialization failed", "ERROR")
        return false
    end
    
    if not BuyTileSystem then
        log("BuyTileSystem not found, initialization failed", "ERROR")
        return false
    end
    
    -- Register events
    if EventBridge.registerEvent then
        EventBridge.registerEvent("BuyTileSystem_Integrated")
        EventBridge.registerEvent("BuyTileSystem_SetupFromGymParts")
    end
    
    -- Listen for relevant events
    if EventBridge.listenForEvent then
        EventBridge.listenForEvent("GymPartsScanner_SetupComplete", function(data)
            log("GymPartsScanner setup completed with result: " .. tostring(data.success), "INFO")
            
            if data.success then
                BuyTileSystemIntegration.automatedSetupComplete = true
                
                if EventBridge.fireEvent then
                    EventBridge.fireEvent("BuyTileSystem_SetupFromGymParts", {
                        success = true,
                        timestamp = os.time()
                    })
                end
            end
        end)
    end
    
    BuyTileSystemIntegration.initialized = true
    log("Integration initialized successfully", "INFO")
    
    -- Run automated setup if scanner is available
    if GymPartsScanner and GymPartsScanner.setupBuyTileSystem then
        log("Running automated setup using GymPartsScanner", "INFO")
        task.spawn(function()
            local success = GymPartsScanner.setupBuyTileSystem()
            log("Automated setup result: " .. tostring(success), "INFO")
        end)
    else
        log("GymPartsScanner not available, skipping automated setup", "WARN")
    end
    
    -- Notify that integration is complete
    if EventBridge.fireEvent then
        EventBridge.fireEvent("BuyTileSystem_Integrated", {
            timestamp = os.time()
        })
    end
    
    return true
end

-- Generate tile data from different sources
function BuyTileSystemIntegration.generateTileData(source)
    source = source or "auto"
    log("Generating tile data from source: " .. source, "INFO")
    
    local success = false
    
    if source == "gymparts" or source == "scanner" then
        -- Use GymPartsScanner
        if GymPartsScanner and GymPartsScanner.setupBuyTileSystem then
            success = GymPartsScanner.setupBuyTileSystem()
        else
            log("GymPartsScanner not available", "ERROR")
            success = false
        end
    elseif source == "initializer" or source == "structure" then
        -- Use TileDataInitializer
        if TileDataInitializer and TileDataInitializer.initializeTileData then
            success = TileDataInitializer.initializeTileData()
        else
            log("TileDataInitializer not available", "ERROR")
            success = false
        end
    elseif source == "auto" then
        -- Try GymPartsScanner first, fall back to TileDataInitializer
        if GymPartsScanner and GymPartsScanner.setupBuyTileSystem then
            success = GymPartsScanner.setupBuyTileSystem()
        end
        
        if not success and TileDataInitializer and TileDataInitializer.initializeTileData then
            success = TileDataInitializer.initializeTileData()
        end
    else
        log("Unknown source: " .. source, "ERROR")
        success = false
    end
    
    log("Tile data generation result: " .. tostring(success), "INFO")
    return success
end

-- Check folder structures and automate setup if missing
function BuyTileSystemIntegration.validateAndRepair()
    log("Validating BuyTile system structures", "INFO")
    
    -- Check if BuyTileSystem has tile data
    local hasTileData = false
    
    if BuyTileSystem and BuyTileSystem.getAllTileData then
        local tileData = BuyTileSystem.getAllTileData()
        if type(tileData) == "table" then
            local count = 0
            for _ in pairs(tileData) do
                count = count + 1
            end
            hasTileData = count > 0
            log("Found " .. count .. " tile data entries", "INFO")
        end
    end
    
    -- If no tile data, attempt auto setup
    if not hasTileData then
        log("No tile data found, attempting auto setup", "WARN")
        return BuyTileSystemIntegration.generateTileData("auto")
    end
    
    return true
end

-- Register commands
if CoreRegistry then
    local CommandService = CoreRegistry:GetSystem("CommandService")
    if CommandService then
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
end

-- Initialize when the module is loaded
task.spawn(function()
    task.wait(2) -- Wait for other systems to initialize
    BuyTileSystemIntegration.initialize()
    
    -- Run validation after a delay
    task.wait(5)
    BuyTileSystemIntegration.validateAndRepair()
end)

-- Create global function for command bar
_G.IntegrateBuyTileSystem = function()
    return BuyTileSystemIntegration.initialize()
end

_G.GenerateBuyTileDataFrom = function(source)
    return BuyTileSystemIntegration.generateTileData(source)
end

-- Register with CoreRegistry
if CoreRegistry and CoreRegistry.registerSystem then
    CoreRegistry.registerSystem("BuyTileSystemIntegration", BuyTileSystemIntegration)
    log("Registered with CoreRegistry", "INFO")
end

return BuyTileSystemIntegration
