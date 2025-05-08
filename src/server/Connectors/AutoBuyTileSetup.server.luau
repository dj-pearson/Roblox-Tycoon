--!strict
--[[
    AutoBuyTileSetup.server.luau
    
    Automatically sets up and validates buyable tiles in the tycoon.
    Integrates with BuyTileSystem to ensure proper tile configuration.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Updated for new BuyTileSystem integration
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Import dependencies
local CoreRegistry = require(ServerScriptService.Core.CoreRegistry)
local BuyTileSystem = require(ServerScriptService.Core.BuyTileSystem)
local DataAccessLayer = require(ServerScriptService.Core.DataAccessLayer)

-- Configuration
local CONFIG = {
    debug = true,
    maxRetries = 3,
    retryDelay = 1, -- seconds
    validationTimeout = 5, -- seconds
    maxTilesPerTycoon = 100,
    tileFolder = "BuyTiles",
    templateFolder = "TileTemplates",
    validationRules = {
        minCost = 100,
        maxCost = 1000000,
        minFloor = 1,
        maxFloor = 5,
        minBuildOrder = 1,
        maxBuildOrder = 1000,
        requiredComponents = {
            "ClickDetector",
            "TileConfig",
            "TileModel"
        }
    },
    errorRecovery = {
        maxAttempts = 3,
        retryDelay = 2, -- seconds
        autoFix = true
    }
}

-- AutoBuyTileSetup module
local AutoBuyTileSetup = {
    Version = "2.0.0",
    initialized = false,
    stats = {
        tilesProcessed = 0,
        validationErrors = 0,
        prerequisiteErrors = 0,
        setupErrors = 0
    }
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[AutoBuyTileSetup]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Validate prerequisites for a tile
local function ValidatePrerequisites(tileType, tileData)
    if not tileData.prerequisites or #tileData.prerequisites == 0 then
        return true
    end
    
    for _, prereqType in ipairs(tileData.prerequisites) do
        -- Make sure prerequisite exists
        if not BuyTileSystem:GetTile(prereqType) then
            log("Tile " .. tileType .. " has non-existent prerequisite: " .. prereqType, "error")
            AutoBuyTileSetup.stats.prerequisiteErrors += 1
            return false
        end
        
        -- Check that prerequisite is on same or lower floor
        local prereqData = BuyTileSystem:GetTile(prereqType)
        if prereqData.floor > tileData.floor then
            log("Tile " .. tileType .. " has prerequisite " .. prereqType .. " on a higher floor (" .. prereqData.floor .. " > " .. tileData.floor .. ")", "error")
            AutoBuyTileSetup.stats.prerequisiteErrors += 1
            return false
        end
        
        -- Check that buildOrder makes sense
        if prereqData.buildOrder >= tileData.buildOrder then
            log("Tile " .. tileType .. " (buildOrder " .. tileData.buildOrder .. ") has prerequisite " .. prereqType .. " with higher or equal buildOrder (" .. prereqData.buildOrder .. ")", "error")
            AutoBuyTileSetup.stats.prerequisiteErrors += 1
            return false
        end
    end
    
    return true
end

-- Update a model with BuyTile data
local function UpdateModelWithBuyTileData(model, tileData)
    if not model or not tileData then
        return false
    end
    
    -- Set attributes
    model:SetAttribute("TileID", tileData.id)
    model:SetAttribute("TileType", tileData.type)
    model:SetAttribute("Cost", tileData.cost)
    model:SetAttribute("Floor", tileData.floor)
    model:SetAttribute("BuildOrder", tileData.buildOrder)
    
    -- Set name
    model.Name = "BuyTile_" .. tileData.id
    
    -- Add required components
    if not model:FindFirstChild("TileConfig") then
        local config = Instance.new("Configuration")
        config.Name = "TileConfig"
        config.Parent = model
    end
    
    -- Add click detector if needed
    if not model:FindFirstChild("ClickDetector") then
        local clickDetector = Instance.new("ClickDetector")
        clickDetector.Name = "ClickDetector"
        clickDetector.Parent = model
    end
    
    return true
end

-- Enhanced validation for a tile's configuration
local function ValidateTileConfig(tileData)
    if not tileData then
        return false, "No tile data provided"
    end
    
    -- Required fields
    local requiredFields = {
        "id", "type", "cost", "floor", "buildOrder"
    }
    
    for _, field in ipairs(requiredFields) do
        if not tileData[field] then
            return false, "Missing required field: " .. field
        end
    end
    
    -- Validate cost range
    if tileData.cost < CONFIG.validationRules.minCost or tileData.cost > CONFIG.validationRules.maxCost then
        return false, string.format("Cost out of range: %d (must be between %d and %d)",
            tileData.cost, CONFIG.validationRules.minCost, CONFIG.validationRules.maxCost)
    end
    
    -- Validate floor range
    if tileData.floor < CONFIG.validationRules.minFloor or tileData.floor > CONFIG.validationRules.maxFloor then
        return false, string.format("Floor out of range: %d (must be between %d and %d)",
            tileData.floor, CONFIG.validationRules.minFloor, CONFIG.validationRules.maxFloor)
    end
    
    -- Validate build order range
    if tileData.buildOrder < CONFIG.validationRules.minBuildOrder or tileData.buildOrder > CONFIG.validationRules.maxBuildOrder then
        return false, string.format("Build order out of range: %d (must be between %d and %d)",
            tileData.buildOrder, CONFIG.validationRules.minBuildOrder, CONFIG.validationRules.maxBuildOrder)
    end
    
    -- Validate prerequisites
    if not ValidatePrerequisites(tileData.type, tileData) then
        return false, "Invalid prerequisites"
    end
    
    -- Validate model components
    local template = ReplicatedStorage:FindFirstChild(CONFIG.templateFolder):FindFirstChild(tileData.type)
    if template then
        for _, component in ipairs(CONFIG.validationRules.requiredComponents) do
            if not template:FindFirstChild(component) then
                return false, "Missing required component: " .. component
            end
        end
    end
    
    return true
end

-- Attempt to fix tile configuration
local function AttemptTileFix(tileData, errorMessage)
    if not CONFIG.errorRecovery.autoFix then
        return false, errorMessage
    end
    
    log("Attempting to fix tile: " .. tileData.id)
    
    -- Fix cost if out of range
    if tileData.cost < CONFIG.validationRules.minCost then
        tileData.cost = CONFIG.validationRules.minCost
    elseif tileData.cost > CONFIG.validationRules.maxCost then
        tileData.cost = CONFIG.validationRules.maxCost
    end
    
    -- Fix floor if out of range
    if tileData.floor < CONFIG.validationRules.minFloor then
        tileData.floor = CONFIG.validationRules.minFloor
    elseif tileData.floor > CONFIG.validationRules.maxFloor then
        tileData.floor = CONFIG.validationRules.maxFloor
    end
    
    -- Fix build order if out of range
    if tileData.buildOrder < CONFIG.validationRules.minBuildOrder then
        tileData.buildOrder = CONFIG.validationRules.minBuildOrder
    elseif tileData.buildOrder > CONFIG.validationRules.maxBuildOrder then
        tileData.buildOrder = CONFIG.validationRules.maxBuildOrder
    end
    
    -- Add missing components
    local template = ReplicatedStorage:FindFirstChild(CONFIG.templateFolder):FindFirstChild(tileData.type)
    if template then
        for _, component in ipairs(CONFIG.validationRules.requiredComponents) do
            if not template:FindFirstChild(component) then
                if component == "ClickDetector" then
                    local clickDetector = Instance.new("ClickDetector")
                    clickDetector.Name = "ClickDetector"
                    clickDetector.Parent = template
                elseif component == "TileConfig" then
                    local config = Instance.new("Configuration")
                    config.Name = "TileConfig"
                    config.Parent = template
                end
            end
        end
    end
    
    -- Validate again after fixes
    local isValid, newError = ValidateTileConfig(tileData)
    if isValid then
        log("Successfully fixed tile: " .. tileData.id)
        return true
    else
        log("Failed to fix tile: " .. tileData.id .. " - " .. newError, "error")
        return false, newError
    end
end

-- Set up a tile in the workspace with retry logic
local function SetupTile(tileData)
    if not tileData then
        return false, "No tile data provided"
    end
    
    -- Validate configuration
    local isValid, errorMessage = ValidateTileConfig(tileData)
    if not isValid then
        -- Attempt to fix the tile
        local fixed, fixError = AttemptTileFix(tileData, errorMessage)
        if not fixed then
            log("Invalid tile config: " .. fixError, "error")
            AutoBuyTileSetup.stats.validationErrors += 1
            return false, fixError
        end
    end
    
    -- Find template
    local templateFolder = ReplicatedStorage:FindFirstChild(CONFIG.templateFolder)
    if not templateFolder then
        return false, "Template folder not found"
    end
    
    local template = templateFolder:FindFirstChild(tileData.type)
    if not template then
        return false, "Template not found: " .. tileData.type
    end
    
    -- Clone template with retry logic
    local attempts = 0
    local tile = nil
    
    while attempts < CONFIG.errorRecovery.maxAttempts do
        local success, result = pcall(function()
            tile = template:Clone()
            return tile
        end)
        
        if success and tile then
            break
        end
        
        attempts += 1
        if attempts < CONFIG.errorRecovery.maxAttempts then
            task.wait(CONFIG.errorRecovery.retryDelay)
        end
    end
    
    if not tile then
        return false, "Failed to clone template after " .. CONFIG.errorRecovery.maxAttempts .. " attempts"
    end
    
    -- Update with tile data
    if not UpdateModelWithBuyTileData(tile, tileData) then
        return false, "Failed to update model with tile data"
    end
    
    -- Register with BuyTileSystem
    if not BuyTileSystem:RegisterTile(tileData) then
        return false, "Failed to register tile with BuyTileSystem"
    end
    
    AutoBuyTileSetup.stats.tilesProcessed += 1
    return true
end

-- Initialize the system
function AutoBuyTileSetup:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing AutoBuyTileSetup v" .. self.Version)
    
    -- Register with CoreRegistry
    if CoreRegistry then
        CoreRegistry:registerSystem("AutoBuyTileSetup", self)
        log("Registered with CoreRegistry")
    end
    
    -- Set up tile folder
    local tileFolder = Workspace:FindFirstChild(CONFIG.tileFolder)
    if not tileFolder then
        tileFolder = Instance.new("Folder")
        tileFolder.Name = CONFIG.tileFolder
        tileFolder.Parent = Workspace
    end
    
    self.initialized = true
    log("AutoBuyTileSetup initialized successfully")
    return true
end

-- Set up all tiles
function AutoBuyTileSetup:SetupAllTiles()
    if not self.initialized then
        self:Initialize()
    end
    
    log("Setting up all tiles")
    
    -- Get tile folder
    local tileFolder = Workspace:FindFirstChild(CONFIG.tileFolder)
    if not tileFolder then
        log("Tile folder not found", "error")
        return false
    end
    
    -- Process each tile
    for _, tile in ipairs(tileFolder:GetChildren()) do
        if tile:IsA("Model") then
            local tileData = {
                id = tile:GetAttribute("TileID"),
                type = tile:GetAttribute("TileType"),
                cost = tile:GetAttribute("Cost"),
                floor = tile:GetAttribute("Floor"),
                buildOrder = tile:GetAttribute("BuildOrder")
            }
            
            local success, errorMessage = SetupTile(tileData)
            if not success then
                log("Failed to set up tile " .. tile.Name .. ": " .. errorMessage, "error")
                self.stats.setupErrors += 1
            end
        end
    end
    
    log("Set up " .. self.stats.tilesProcessed .. " tiles")
    return true
end

-- Get system health
function AutoBuyTileSetup:IsHealthy()
    return self.initialized
end

-- Recover from failure
function AutoBuyTileSetup:Recover()
    if not self.initialized then
        return self:Initialize()
    end
    return true
end

-- Get tile setup statistics
function AutoBuyTileSetup:GetStats()
    return {
        tilesProcessed = self.stats.tilesProcessed,
        validationErrors = self.stats.validationErrors,
        prerequisiteErrors = self.stats.prerequisiteErrors,
        setupErrors = self.stats.setupErrors,
        successRate = self.stats.tilesProcessed > 0 and 
            (self.stats.tilesProcessed - self.stats.validationErrors - self.stats.prerequisiteErrors - self.stats.setupErrors) / self.stats.tilesProcessed * 100 or 0
    }
end

-- Initialize the AutoBuyTileSetup
AutoBuyTileSetup:Initialize()

return AutoBuyTileSetup