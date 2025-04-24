--!strict
--[[
    TycoonValidationTool.server.luau
    Tool for comprehensive validation of gym tycoon functionality
    Part of Phase 4: Testing & Validation
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Only run in Studio
if not RunService:IsStudio() then
    warn("TycoonValidationTool is designed to run only in Studio mode")
    return
end

-- Try to find modules
local function TryRequire(path)
    local success, result = pcall(function()
        return require(path)
    end)
    return success and result or nil
end

-- Find CoreRegistry to access all systems
local CoreRegistry
local coreFolder = ServerScriptService:FindFirstChild("Core") 
    or ServerScriptService:FindFirstChild("Systems")
    or ServerScriptService:FindFirstChild("server")
    
if coreFolder then
    for _, module in ipairs(coreFolder:GetDescendants()) do
        if module:IsA("ModuleScript") and module.Name == "CoreRegistry" then
            CoreRegistry = TryRequire(module)
            break
        end
    end
end

-- Tool configuration
local Config = {
    LogLevel = 2,     -- 0: Errors only, 1: Important info, 2: All info
    SimulatePurchases = true,
    ValidateEquipment = true,
    ValidateProgression = true,
    VerifyUpgradePaths = true
}

-- Main validation tool
local TycoonValidationTool = {
    Status = {
        TilesValidated = 0,
        EquipmentValidated = 0,
        PurchasesTested = 0,
        UpgradesTested = 0,
        ProgressionValidated = 0,
        IssuesFound = 0
    },
    Results = {}
}

-- Get modules from CoreRegistry
local Modules = {
    BoundingBoxManager = CoreRegistry and CoreRegistry:GetSystem("BoundingBoxManager"),
    EquipmentManager = CoreRegistry and CoreRegistry:GetSystem("EquipmentManager"),
    BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem"),
    TileDataGenerator = CoreRegistry and CoreRegistry:GetSystem("TileDataGenerator"),
    BuyTileProgressionManager = CoreRegistry and CoreRegistry:GetSystem("BuyTileProgressionManager")
}

-- Logging
function TycoonValidationTool:Log(message, level)
    level = level or 2
    if level <= Config.LogLevel then
        if level == 0 then
            warn("[TycoonValidation] " .. message)
        else
            print("[TycoonValidation] " .. message)
        end
    end
end

-- Record an issue
function TycoonValidationTool:RecordIssue(category, message, object)
    local issue = {
        Category = category,
        Message = message,
        Object = object and object:GetFullName() or "N/A"
    }
    
    table.insert(self.Results, issue)
    self.Status.IssuesFound += 1
    self:Log("❌ Issue found - " .. message, 0)
    
    return issue
end

-- Record success
function TycoonValidationTool:RecordSuccess(category, message, object)
    local success = {
        Category = category,
        Message = message,
        Object = object and object:GetFullName() or "N/A",
        Success = true
    }
    
    table.insert(self.Results, success)
    self:Log("✅ " .. message, 2)
    
    return success
end

-- Detect all tycoon instances in the workspace
function TycoonValidationTool:DetectTycoons()
    local tycoons = {}
    
    -- Look for tycoons in workspace
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and 
           (child.Name:match("Tycoon") or child.Name:match("Gym")) and
           child:FindFirstChild("Owner") then
            table.insert(tycoons, child)
        end
    end
    
    if #tycoons == 0 then
        self:Log("No tycoons detected in workspace. Looking for any suitable models...", 1)
        
        -- Fallback: look for models with floor submodels
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") then
                local hasFloors = false
                for _, subChild in ipairs(child:GetChildren()) do
                    if subChild:IsA("Model") and subChild.Name:match("Floor") then
                        hasFloors = true
                        break
                    end
                end
                
                if hasFloors then
                    table.insert(tycoons, child)
                end
            end
        end
    end
    
    return tycoons
end

-- Check if a tile is purchasable
function TycoonValidationTool:ValidateTile(tile, tycoon)
    self.Status.TilesValidated += 1
    
    -- Basic validation
    if not tile:IsA("BasePart") and not tile:IsA("Model") then
        return self:RecordIssue("TileValidation", "Tile is not a BasePart or Model", tile)
    end
    
    -- Check for essential attributes
    local requiredAttrs = {"Price", "TileType"}
    local missingAttrs = {}
    
    for _, attr in ipairs(requiredAttrs) do
        if tile:GetAttribute(attr) == nil then
            table.insert(missingAttrs, attr)
        end
    end
    
    if #missingAttrs > 0 then
        return self:RecordIssue("TileValidation", 
            "Tile missing attributes: " .. table.concat(missingAttrs, ", "), 
            tile)
    end
    
    -- Check for hitbox if BoundingBoxManager exists
    if Modules.BoundingBoxManager then
        local hitboxFound = false
        
        -- Look for hitbox folders
        local hitboxFolder = Workspace:FindFirstChild("BuyTileHitboxes") or
                            tycoon:FindFirstChild("Hitboxes") or
                            tycoon:FindFirstChild("BuyTileHitboxes")
        
        if hitboxFolder then
            for _, hitbox in ipairs(hitboxFolder:GetDescendants()) do
                if hitbox:IsA("BasePart") and hitbox:GetAttribute("TileId") == tile:GetAttribute("TileId") then
                    hitboxFound = true
                    break
                end
            end
        end
        
        if not hitboxFound then
            return self:RecordIssue("TileValidation", "Tile has no associated hitbox", tile)
        end
    end
    
    return self:RecordSuccess("TileValidation", "Tile validated successfully", tile)
end

-- Validate equipment setup
function TycoonValidationTool:ValidateEquipment(equipment)
    if not Config.ValidateEquipment then return end
    self.Status.EquipmentValidated += 1
    
    -- Basic validation
    if not equipment:IsA("Model") then
        return self:RecordIssue("EquipmentValidation", "Equipment is not a Model", equipment)
    end
    
    -- Check for essential attributes
    local requiredAttrs = {"Category", "UpgradeLevel"}
    local optionalValueAttrs = {
        {"Price", function(v) return type(v) == "number" and v > 0 end},
        {"IncomeBoost", function(v) return type(v) == "number" and v >= 0 end, "IncomeBonus"}
    }
    
    local missingAttrs = {}
    for _, attr in ipairs(requiredAttrs) do
        if equipment:GetAttribute(attr) == nil then
            table.insert(missingAttrs, attr)
        end
    end
    
    if #missingAttrs > 0 then
        return self:RecordIssue("EquipmentValidation", 
            "Equipment missing attributes: " .. table.concat(missingAttrs, ", "), 
            equipment)
    end
    
    -- Check attribute values
    for _, attrCheck in ipairs(optionalValueAttrs) do
        local attrName = attrCheck[1]
        local validator = attrCheck[2]
        local altName = attrCheck[3]
        
        local value = equipment:GetAttribute(attrName)
        
        -- Try alternative attribute name if provided
        if value == nil and altName then
            value = equipment:GetAttribute(altName)
        end
        
        if value ~= nil and not validator(value) then
            return self:RecordIssue("EquipmentValidation", 
                "Equipment has invalid " .. attrName .. " value: " .. tostring(value), 
                equipment)
        end
    end
    
    -- Check for upgrade paths if EquipmentManager exists
    if Config.VerifyUpgradePaths and Modules.EquipmentManager then
        local currentLevel = equipment:GetAttribute("UpgradeLevel") or 1
        local maxLevel = equipment:GetAttribute("MaxUpgradeLevel") or 5
        
        if currentLevel < maxLevel then
            local upgradeInfo = Modules.EquipmentManager:GetNextUpgradeInfo(equipment)
            
            if not upgradeInfo then
                return self:RecordIssue("EquipmentValidation", 
                    "Equipment has no valid upgrade path despite being below max level", 
                    equipment)
            end
            
            -- Validate upgrade path
            if upgradeInfo.level ~= currentLevel + 1 then
                return self:RecordIssue("EquipmentValidation", 
                    "Equipment upgrade level inconsistency", 
                    equipment)
            end
        end
    end
    
    return self:RecordSuccess("EquipmentValidation", "Equipment validated successfully", equipment)
end

-- Test progression logic
function TycoonValidationTool:ValidateProgression(tycoon)
    if not Config.ValidateProgression or not Modules.BuyTileProgressionManager then return end
    self.Status.ProgressionValidated += 1
    
    -- Check if we can get build order
    local buildOrder = Modules.BuyTileProgressionManager:GetBuildOrder(tycoon)
    
    if not buildOrder or type(buildOrder) ~= "table" or #buildOrder == 0 then
        return self:RecordIssue("ProgressionValidation", 
            "Failed to get valid build order for tycoon", 
            tycoon)
    end
    
    -- Check floor unlocking conditions
    local floors = {}
    for _, child in ipairs(tycoon:GetChildren()) do
        if child:IsA("Model") and child.Name:match("Floor") then
            table.insert(floors, child)
        end
    end
    
    table.sort(floors, function(a, b)
        local aNum = tonumber(a.Name:match("%d+")) or 0
        local bNum = tonumber(b.Name:match("%d+")) or 0
        return aNum < bNum
    end)
    
    -- Check if floor 2+ has prerequisites
    for i = 2, #floors do
        local floor = floors[i]
        local prerequisites = Modules.BuyTileProgressionManager:GetFloorPrerequisites(floor)
        
        if not prerequisites or #prerequisites == 0 then
            self:RecordIssue("ProgressionValidation", 
                "Floor " .. floor.Name .. " has no unlock prerequisites", 
                floor)
        end
    end
    
    return self:RecordSuccess("ProgressionValidation", "Progression system validated", tycoon)
end

-- Simulate purchase of a tile
function TycoonValidationTool:SimulatePurchase(tycoon, tile)
    if not Config.SimulatePurchases or not Modules.BuyTileSystem then return end
    self.Status.PurchasesTested += 1
    
    -- Check if tile is already purchased
    if tile:GetAttribute("Purchased") then
        self:Log("Tile already purchased, skipping purchase simulation", 2)
        return true
    end
    
    -- Create temporary player for purchase simulation
    local fakePlr = {
        Name = "TestPlayer",
        UserId = 0,
        GetAttribute = function() return 99999999 end,
        SetAttribute = function() return true end
    }
    
    -- Simulate purchase
    local success = Modules.BuyTileSystem:PurchaseTile(fakePlr, tile)
    
    if not success then
        return self:RecordIssue("PurchaseSimulation", 
            "Failed to simulate purchase for tile", 
            tile)
    end
    
    return self:RecordSuccess("PurchaseSimulation", "Purchase simulation successful", tile)
end

-- Simulate equipment upgrade
function TycoonValidationTool:SimulateEquipmentUpgrade(equipment)
    if not Config.VerifyUpgradePaths or not Modules.EquipmentManager then return end
    self.Status.UpgradesTested += 1
    
    local currentLevel = equipment:GetAttribute("UpgradeLevel") or 1
    local maxLevel = equipment:GetAttribute("MaxUpgradeLevel") or 5
    
    if currentLevel >= maxLevel then
        self:Log("Equipment already at max level, skipping upgrade simulation", 2)
        return true
    end
    
    -- Store original level for restoration
    local originalLevel = currentLevel
    
    -- Try to upgrade
    local success = Modules.EquipmentManager:UpgradeEquipment(equipment)
    
    if not success then
        return self:RecordIssue("UpgradeSimulation", 
            "Failed to simulate upgrade for equipment", 
            equipment)
    end
    
    -- Verify upgrade happened
    if equipment:GetAttribute("UpgradeLevel") <= currentLevel then
        return self:RecordIssue("UpgradeSimulation", 
            "Equipment upgrade did not increase level", 
            equipment)
    end
    
    -- Restore original level
    equipment:SetAttribute("UpgradeLevel", originalLevel)
    
    return self:RecordSuccess("UpgradeSimulation", "Upgrade simulation successful", equipment)
end

-- Validate full tycoon
function TycoonValidationTool:ValidateTycoon(tycoon)
    self:Log("\n===========================", 1)
    self:Log("Validating tycoon: " .. tycoon.Name, 1)
    self:Log("===========================", 1)
    
    -- First validate progression system
    self:ValidateProgression(tycoon)
    
    -- Track items we've validated
    local tilesValidated = 0
    local equipmentValidated = 0
    
    -- Process each floor
    for _, floor in ipairs(tycoon:GetChildren()) do
        if floor:IsA("Model") and floor.Name:match("Floor") then
            self:Log("Checking floor: " .. floor.Name, 1)
            
            -- Check tiles in the floor
            for _, child in ipairs(floor:GetDescendants()) do
                if child:GetAttribute("TileType") then
                    self:ValidateTile(child, tycoon)
                    tilesValidated += 1
                    
                    -- Simulate purchase if configured
                    if Config.SimulatePurchases then
                        self:SimulatePurchase(tycoon, child)
                    end
                end
                
                -- Check equipment
                local category = child:GetAttribute("Category")
                if category and (category == "CARDIO" or category == "STRENGTH" or 
                                category == "SPECIALTY" or category == "AMENITIES") then
                    self:ValidateEquipment(child)
                    equipmentValidated += 1
                    
                    -- Simulate upgrade if configured
                    if Config.VerifyUpgradePaths then
                        self:SimulateEquipmentUpgrade(child)
                    end
                end
            end
        end
    end
    
    self:Log(string.format("Tycoon validation complete: %d tiles, %d equipment items", 
                          tilesValidated, equipmentValidated), 1)
    
    return tilesValidated > 0 or equipmentValidated > 0
end

-- Run validation on all tycoons
function TycoonValidationTool:ValidateAllTycoons()
    self:Log("\n========================================", 1)
    self:Log("TYCOON VALIDATION STARTING", 1)
    self:Log("========================================\n", 1)
    
    -- Reset status
    self.Status = {
        TilesValidated = 0,
        EquipmentValidated = 0,
        PurchasesTested = 0,
        UpgradesTested = 0,
        ProgressionValidated = 0,
        IssuesFound = 0
    }
    self.Results = {}
    
    -- Find tycoons
    local tycoons = self:DetectTycoons()
    
    if #tycoons == 0 then
        self:Log("No tycoons found in the workspace", 0)
        return false
    end
    
    self:Log("Found " .. #tycoons .. " tycoon(s) to validate", 1)
    
    -- Validate each tycoon
    for _, tycoon in ipairs(tycoons) do
        self:ValidateTycoon(tycoon)
    end
    
    -- Report results
    self:Log("\n========================================", 1)
    self:Log("VALIDATION COMPLETE", 1)
    self:Log("========================================", 1)
    
    self:Log(string.format("Tiles validated: %d", self.Status.TilesValidated), 1)
    self:Log(string.format("Equipment validated: %d", self.Status.EquipmentValidated), 1)
    self:Log(string.format("Purchases tested: %d", self.Status.PurchasesTested), 1)
    self:Log(string.format("Upgrades tested: %d", self.Status.UpgradesTested), 1)
    self:Log(string.format("Issues found: %d", self.Status.IssuesFound), self.Status.IssuesFound > 0 and 0 or 1)
    self:Log("========================================\n", 1)
    
    -- If issues were found, show summary
    if self.Status.IssuesFound > 0 then
        self:Log("Issue Summary:", 0)
        for i, issue in ipairs(self.Results) do
            if not issue.Success then
                self:Log(string.format("%d. [%s] %s (%s)", 
                                     i, issue.Category, issue.Message, issue.Object), 0)
            end
        end
    end
    
    return {
        Status = self.Status,
        Results = self.Results
    }
end

-- Register global function for running validation
if RunService:IsStudio() then
    _G.ValidateTycoons = function(config)
        -- Apply any config overrides
        if config then
            for key, value in pairs(config) do
                Config[key] = value
            end
        end
        
        return TycoonValidationTool:ValidateAllTycoons()
    end
    
    print("Tycoon validation tool initialized. Run _G.ValidateTycoons() to validate all tycoons.")
    print("Optional config: _G.ValidateTycoons({LogLevel = 2, SimulatePurchases = true})")
end

return TycoonValidationTool
