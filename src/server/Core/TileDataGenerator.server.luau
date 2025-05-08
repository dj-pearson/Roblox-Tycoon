--!strict
--[[
    TileDataGenerator.server.luau
    
    Generates and updates tile data for the BuyTileSystem.
    Integrates with BuyTileSystem to ensure proper tile configuration.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Added enhanced model processing and data validation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Import dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)
local BuyTileSystem = require(script.Parent.BuyTileSystem)
local DataAccessLayer = require(script.Parent.DataAccessLayer)

-- Configuration
local CONFIG = {
    debug = true,
    maxRetries = 3,
    retryDelay = 1, -- seconds
    modelFolders = {
        "GymEquipment",
        "TileTemplates",
        "BuyTiles"
    },
    requiredAttributes = {
        "TileID",
        "TileType",
        "Cost",
        "Floor",
        "BuildOrder"
    },
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
    dataProcessing = {
        batchSize = 10,
        maxConcurrent = 5,
        timeout = 30 -- seconds
    }
}

-- TileDataGenerator module
local TileDataGenerator = {
    Version = "2.0.0",
    initialized = false,
    stats = {
        modelsProcessed = 0,
        errors = 0,
        warnings = 0
    }
}

-- Debug logging
local function log(message, level)
    if CONFIG.debug then
        local prefix = "[TileDataGenerator]"
        if level == "error" then
            warn(prefix .. " ERROR: " .. message)
        elseif level == "warn" then
            warn(prefix .. " WARNING: " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Find model folders
function TileDataGenerator:FindModelFolders()
    local folders = {}
    
    for _, folderName in ipairs(CONFIG.modelFolders) do
        local folder = ReplicatedStorage:FindFirstChild(folderName)
        if folder then
            table.insert(folders, {
                name = folderName,
                folder = folder
            })
        else
            log("Model folder not found: " .. folderName, "warn")
        end
    end
    
    return folders
end

-- Process models in a folder
function TileDataGenerator:ProcessModelsInFolder(folderInfo)
    if not folderInfo or not folderInfo.folder then
        return {}
    end
    
    local models = {}
    
    for _, model in ipairs(folderInfo.folder:GetChildren()) do
        if model:IsA("Model") then
            local modelInfo = self:ProcessModel(model)
            if modelInfo then
                models[modelInfo.type] = modelInfo
            end
        end
    end
    
    return models
end

-- Process a single model with enhanced validation
function TileDataGenerator:ProcessModel(model)
    if not model or not model:IsA("Model") then
        return nil
    end
    
    -- Get model attributes
    local tileId = model:GetAttribute("TileID")
    local tileType = model:GetAttribute("TileType")
    local cost = model:GetAttribute("Cost")
    local floor = model:GetAttribute("Floor")
    local buildOrder = model:GetAttribute("BuildOrder")
    
    -- Validate required attributes
    if not tileId or not tileType or not cost or not floor or not buildOrder then
        log("Model missing required attributes: " .. model.Name, "warn")
        self.stats.warnings += 1
        return nil
    end
    
    -- Validate attribute ranges
    if cost < CONFIG.validationRules.minCost or cost > CONFIG.validationRules.maxCost then
        log("Invalid cost for model " .. model.Name .. ": " .. cost, "warn")
        self.stats.warnings += 1
        return nil
    end
    
    if floor < CONFIG.validationRules.minFloor or floor > CONFIG.validationRules.maxFloor then
        log("Invalid floor for model " .. model.Name .. ": " .. floor, "warn")
        self.stats.warnings += 1
        return nil
    end
    
    if buildOrder < CONFIG.validationRules.minBuildOrder or buildOrder > CONFIG.validationRules.maxBuildOrder then
        log("Invalid build order for model " .. model.Name .. ": " .. buildOrder, "warn")
        self.stats.warnings += 1
        return nil
    end
    
    -- Validate required components
    for _, component in ipairs(CONFIG.validationRules.requiredComponents) do
        if not model:FindFirstChild(component) then
            log("Missing required component " .. component .. " in model " .. model.Name, "warn")
            self.stats.warnings += 1
            return nil
        end
    end
    
    -- Create model info with additional metadata
    local modelInfo = {
        id = tileId,
        type = tileType,
        cost = cost,
        floor = floor,
        buildOrder = buildOrder,
        model = model,
        metadata = {
            lastModified = model:GetAttribute("LastModified") or os.time(),
            version = model:GetAttribute("Version") or "1.0.0",
            tags = model:GetAttribute("Tags") or {},
            customData = {}
        }
    }
    
    -- Process custom attributes
    for _, attr in ipairs(model:GetAttributes()) do
        if string.match(attr, "^Custom_") then
            modelInfo.metadata.customData[attr] = model:GetAttribute(attr)
        end
    end
    
    self.stats.modelsProcessed += 1
    return modelInfo
end

-- Process models in batches
function TileDataGenerator:ProcessModelsInBatches(folderInfo)
    if not folderInfo or not folderInfo.folder then
        return {}
    end
    
    local models = {}
    local modelList = {}
    
    -- Collect all models
    for _, model in ipairs(folderInfo.folder:GetChildren()) do
        if model:IsA("Model") then
            table.insert(modelList, model)
        end
    end
    
    -- Process in batches
    for i = 1, #modelList, CONFIG.dataProcessing.batchSize do
        local batch = {}
        local batchEnd = math.min(i + CONFIG.dataProcessing.batchSize - 1, #modelList)
        
        -- Create batch
        for j = i, batchEnd do
            table.insert(batch, modelList[j])
        end
        
        -- Process batch concurrently
        local batchResults = {}
        local activeTasks = 0
        
        for _, model in ipairs(batch) do
            while activeTasks >= CONFIG.dataProcessing.maxConcurrent do
                task.wait()
            end
            
            activeTasks += 1
            task.spawn(function()
                local modelInfo = self:ProcessModel(model)
                if modelInfo then
                    table.insert(batchResults, modelInfo)
                end
                activeTasks -= 1
            end)
        end
        
        -- Wait for batch completion
        local startTime = os.time()
        while activeTasks > 0 do
            if os.time() - startTime > CONFIG.dataProcessing.timeout then
                log("Batch processing timeout", "error")
                break
            end
            task.wait()
        end
        
        -- Add batch results
        for _, modelInfo in ipairs(batchResults) do
            models[modelInfo.type] = modelInfo
        end
    end
    
    return models
end

-- Update BuyTileSystem with enhanced data processing
function TileDataGenerator:UpdateBuyTileSystem()
    if not BuyTileSystem then
        log("BuyTileSystem not found", "error")
        return false
    end
    
    -- Find model folders
    local folders = self:FindModelFolders()
    if #folders == 0 then
        log("No model folders found", "error")
        return false
    end
    
    -- Process models in all folders
    local allModels = {}
    local modelByTileType = {}
    local processingStats = {
        total = 0,
        successful = 0,
        failed = 0,
        skipped = 0
    }
    
    for _, folderInfo in ipairs(folders) do
        local models = self:ProcessModelsInBatches(folderInfo)
        for tileType, modelInfo in pairs(models) do
            modelByTileType[tileType] = modelInfo
            table.insert(allModels, modelInfo)
            processingStats.total += 1
        end
    end
    
    -- Process each model into tile data
    local updateCount = 0
    local addCount = 0
    
    for _, modelInfo in ipairs(allModels) do
        -- Create tile data
        local tileData = {
            id = modelInfo.id,
            type = modelInfo.type,
            cost = modelInfo.cost,
            floor = modelInfo.floor,
            buildOrder = modelInfo.buildOrder,
            model = modelInfo.model,
            metadata = modelInfo.metadata
        }
        
        -- Register with BuyTileSystem
        if BuyTileSystem:RegisterTile(tileData) then
            if BuyTileSystem:GetTile(modelInfo.id) then
                updateCount += 1
                processingStats.successful += 1
            else
                addCount += 1
                processingStats.successful += 1
            end
        else
            log("Failed to register tile: " .. modelInfo.type, "error")
            self.stats.errors += 1
            processingStats.failed += 1
        end
    end
    
    -- Log processing statistics
    log(string.format("Processing complete: %d total, %d successful, %d failed, %d skipped",
        processingStats.total,
        processingStats.successful,
        processingStats.failed,
        processingStats.skipped))
    
    log("Updated BuyTileSystem: " .. updateCount .. " updates, " .. addCount .. " additions")
    return true
end

-- Initialize the system
function TileDataGenerator:Initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing TileDataGenerator v" .. self.Version)
    
    -- Register with CoreRegistry
    if CoreRegistry then
        CoreRegistry:registerSystem("TileDataGenerator", self)
        log("Registered with CoreRegistry")
    end
    
    self.initialized = true
    log("TileDataGenerator initialized successfully")
    return true
end

-- Get system health
function TileDataGenerator:IsHealthy()
    return self.initialized
end

-- Recover from failure
function TileDataGenerator:Recover()
    if not self.initialized then
        return self:Initialize()
    end
    return true
end

-- Get processing statistics
function TileDataGenerator:GetStats()
    return {
        modelsProcessed = self.stats.modelsProcessed,
        errors = self.stats.errors,
        warnings = self.stats.warnings,
        successRate = self.stats.modelsProcessed > 0 and 
            (self.stats.modelsProcessed - self.stats.errors) / self.stats.modelsProcessed * 100 or 0
    }
end

-- Initialize the TileDataGenerator
TileDataGenerator:Initialize()

return TileDataGenerator