--[[
    MigrationUtils.server.luau
    
    Migration utilities to help transition from old BuyTile implementation to 
    the new modular system (FloorAttributeSetup, BuyTileProgressionManager, TileDataGenerator).
    
    This script provides tools for:
    - Finding and identifying old BuyTile scripts
    - Converting existing data to work with the new modular system
    - Detecting and resolving conflicts between old and new implementations
    
    Created: April 21, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Find CoreRegistry
local CoreRegistry = nil
local systemFolder = ServerScriptService:FindFirstChild("Systems") or ServerScriptService

for _, folder in pairs(systemFolder:GetDescendants()) do
    if folder:IsA("ModuleScript") and folder.Name == "CoreRegistry" then
        CoreRegistry = require(folder)
        break
    end
end

-- Find or systems
local FloorAttributeSetup = CoreRegistry and CoreRegistry:GetSystem("FloorAttributeSetup")
local BuyTileProgressionManager = CoreRegistry and CoreRegistry:GetSystem("BuyTileProgressionManager")
local TileDataGenerator = CoreRegistry and CoreRegistry:GetSystem("TileDataGenerator")
local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")

-- Legacy system modules
local legacyModules = {}

-- MigrationUtils singleton
local MigrationUtils = {
    Debug = false,  -- Set to true for detailed logging
    LegacyModules = {}
}

-- Log messages if debug is enabled
function MigrationUtils:Log(message)
    if self.Debug then
        print("[MigrationUtils] " .. message)
    end
end

-- Legacy module finder
function MigrationUtils:FindLegacyBuyTileModules()
    local foundModules = {}
    local moduleNames = {
        "AutoBuyTileSetup", 
        "BuyTileConfigGenerator", 
        "BuyTileHitboxGenerator",
        "BuyTileManager"
    }
    
    -- Search common folders
    local searchFolders = {
        ServerScriptService,
        ServerScriptService:FindFirstChild("Connectors"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src"),
        ServerStorage
    }
    
    -- Add additional search paths
    if ServerScriptService:FindFirstChild("src") then
        local src = ServerScriptService:FindFirstChild("src")
        
        if src:FindFirstChild("server") then
            table.insert(searchFolders, src:FindFirstChild("server"))
            
            -- Check for Core and Connectors folders
            if src:FindFirstChild("server"):FindFirstChild("Core") then
                table.insert(searchFolders, src:FindFirstChild("server"):FindFirstChild("Core"))
            end
            
            if src:FindFirstChild("server"):FindFirstChild("Connectors") then
                table.insert(searchFolders, src:FindFirstChild("server"):FindFirstChild("Connectors"))
            end
        end
    end
    
    -- Function to check if module name matches any of the target names
    local function isTargetModule(name)
        for _, targetName in ipairs(moduleNames) do
            if name:find(targetName) then
                return true
            end
        end
        return name:lower():find("buytile") ~= nil
    end
    
    -- Search through all folders
    for _, folder in ipairs(searchFolders) do
        if not folder then continue end
        
        for _, child in ipairs(folder:GetDescendants()) do
            if (child:IsA("ModuleScript") or child:IsA("Script")) and isTargetModule(child.Name) then
                foundModules[child.Name] = {
                    instance = child,
                    path = child:GetFullName(),
                    type = child.ClassName
                }
                self:Log("Found legacy BuyTile module: " .. child.Name .. " at " .. child:GetFullName())
            end
        end
    end
    
    -- Store and return results
    self.LegacyModules = foundModules
    return foundModules
end

-- Check for legacy BuyTile data
function MigrationUtils:FindLegacyBuyTileData()
    local dataLocations = {}
    
    -- Check for BuyTile folders
    local buyTilesFolder = ServerStorage:FindFirstChild("BuyTiles")
    if buyTilesFolder then
        dataLocations.BuyTilesFolder = {
            path = buyTilesFolder:GetFullName(),
            instance = buyTilesFolder,
            itemCount = #buyTilesFolder:GetChildren()
        }
        self:Log("Found BuyTiles folder in ServerStorage with " .. #buyTilesFolder:GetChildren() .. " models")
    end
    
    -- Check for BuyTile data in workspace
    for _, tycoon in ipairs(workspace:GetChildren()) do
        if tycoon:IsA("Folder") or tycoon:IsA("Model") then
            local buyTilesFolder = tycoon:FindFirstChild("BuyTiles")
            
            if buyTilesFolder and #buyTilesFolder:GetChildren() > 0 then
                dataLocations["Workspace_" .. tycoon.Name] = {
                    path = buyTilesFolder:GetFullName(),
                    instance = buyTilesFolder,
                    itemCount = #buyTilesFolder:GetChildren()
                }
                self:Log("Found BuyTiles folder in " .. tycoon.Name .. " with " .. #buyTilesFolder:GetChildren() .. " tiles")
            end
        end
    end
    
    -- Check for tile data in module scripts
    for _, module in ipairs(ServerStorage:GetDescendants()) do
        if module:IsA("ModuleScript") and 
          (module.Name == "TileData" or module.Name == "BuyTileData" or module.Name:lower():find("buytile")) then
            dataLocations[module.Name] = {
                path = module:GetFullName(),
                instance = module,
                isScript = true
            }
            self:Log("Found potential BuyTile data module: " .. module:GetFullName())
        end
    end
    
    return dataLocations
end

-- Import data from legacy BuyTile systems into our new system
function MigrationUtils:ImportLegacyData()
    if not BuyTileSystem then
        warn("BuyTileSystem not found, cannot import legacy data")
        return false
    end
    
    -- Stats for reporting
    local stats = {
        tilesImported = 0,
        modelsProcessed = 0,
        errors = 0
    }
    
    -- First check if we can access any legacy modules
    local legacyModules = self:FindLegacyBuyTileModules()
    
    -- Try to extract tile data from legacy modules
    for name, info in pairs(legacyModules) do
        if info.type == "ModuleScript" then
            local success, result = pcall(function()
                return require(info.instance)
            end)
            
            if success and result then
                -- Check for tile data
                if type(result.tileData) == "table" or type(result.buyTileData) == "table" then
                    local tileData = result.tileData or result.buyTileData
                    
                    -- Import the tile data into our system
                    local importCount = self:ImportLegacyTileData(tileData)
                    stats.tilesImported += importCount
                    self:Log("Imported " .. importCount .. " tiles from " .. name)
                end
                
                -- Store loaded module for potential use
                legacyModules[name].module = result
            else
                self:Log("Could not load module " .. name .. ": " .. tostring(result))
                stats.errors += 1
            end
        end
    end
    
    -- Look for BuyTile models in ServerStorage
    local legacyData = self:FindLegacyBuyTileData()
    
    -- Import from BuyTiles folder
    if legacyData.BuyTilesFolder then
        local folder = legacyData.BuyTilesFolder.instance
        
        -- Process each model
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") then
                -- Extract attributes
                local attributes = {}
                for name, value in pairs(model:GetAttributes()) do
                    attributes[name] = value
                end
                
                -- Create tile data if needed
                if attributes.TileType then
                    local result = self:CreateTileDataFromAttributes(attributes, model)
                    if result then
                        stats.tilesImported += 1
                    end
                end
                
                stats.modelsProcessed += 1
            end
        end
    end
    
    -- If we have TileDataGenerator, use it to complete the process
    if TileDataGenerator then
        local genStats = TileDataGenerator:UpdateBuyTileSystem()
        stats.tilesImported = math.max(stats.tilesImported, genStats.total)
        self:Log("TileDataGenerator imported " .. genStats.total .. " tiles")
    end
    
    -- If we have the progression manager, generate build order
    if BuyTileProgressionManager then
        BuyTileProgressionManager:GenerateBuildOrder()
        BuyTileProgressionManager:SetupFloorPrerequisites()
        BuyTileProgressionManager:IdentifyRequiredTiles()
        self:Log("Generated progression data with BuyTileProgressionManager")
    end
    
    -- Return stats
    return stats
end

-- Import legacy tile data into the new system
function MigrationUtils:ImportLegacyTileData(tileData)
    if not BuyTileSystem or not tileData then return 0 end
    
    local importCount = 0
    
    -- Ensure tileData table exists on BuyTileSystem
    if not BuyTileSystem.tileData then
        BuyTileSystem.tileData = {}
    end
    
    -- Process each tile in the legacy data
    for tileType, data in pairs(tileData) do
        -- Only import if it doesn't exist already
        if not BuyTileSystem.tileData[tileType] then
            -- Create new entry
            BuyTileSystem.tileData[tileType] = {
                tileType = tileType,
                description = data.description or data.name or tileType,
                floor = data.floor or 1,
                price = data.price or 100,
                incomeBoost = data.incomeBoost or data.income or 5,
                modelName = data.modelName or data.model or tileType,
                buildOrder = data.buildOrder or data.order,
                prerequisites = data.prerequisites or data.requires or {},
                category = data.category,
                isRequired = data.isRequired or false
            }
            
            -- Legacy data might use other field names
            if not data.incomeBoost and data.incomeBonus then
                BuyTileSystem.tileData[tileType].incomeBoost = data.incomeBonus
            end
            
            importCount += 1
            self:Log("Imported " .. tileType)
        end
    end
    
    return importCount
end

-- Create tile data from model attributes
function MigrationUtils:CreateTileDataFromAttributes(attributes, model)
    if not BuyTileSystem or not attributes.TileType then return false end
    
    local tileType = attributes.TileType
    
    -- Skip if already exists
    if BuyTileSystem.tileData and BuyTileSystem.tileData[tileType] then
        return false
    end
    
    -- Create tile data from attributes
    if not BuyTileSystem.tileData then
        BuyTileSystem.tileData = {}
    end
    
    -- Create new entry
    BuyTileSystem.tileData[tileType] = {
        tileType = tileType,
        description = attributes.Description or model.Name,
        floor = attributes.Floor or 1,
        price = attributes.Price or 100,
        incomeBoost = attributes.IncomeBoost or attributes.IncomeBonus or 5,
        modelName = attributes.ModelName or model.Name,
        buildOrder = attributes.BuildOrder,
        prerequisites = attributes.Prerequisites or {},
        category = attributes.Category,
        structureType = attributes.StructureType,
        room = attributes.Room,
        isRequired = attributes.IsRequired or false
    }
    
    self:Log("Created tile data for " .. tileType .. " from attributes")
    return true
end

-- Check for potential conflicts between old and new systems
function MigrationUtils:CheckForConflicts()
    local conflicts = {
        moduleConflicts = {},
        dataConflicts = {}
    }
    
    -- Find legacy modules first
    local legacyModules = self:FindLegacyBuyTileModules()
    
    -- Check for specific module conflicts
    if legacyModules.AutoBuyTileSetup and FloorAttributeSetup then
        conflicts.moduleConflicts.FloorAttributeSetup = {
            legacyModule = legacyModules.AutoBuyTileSetup.path,
            newModule = "FloorAttributeSetup",
            severity = "High"
        }
    end
    
    if legacyModules.BuyTileConfigGenerator and TileDataGenerator then
        conflicts.moduleConflicts.TileDataGenerator = {
            legacyModule = legacyModules.BuyTileConfigGenerator.path,
            newModule = "TileDataGenerator",
            severity = "High"
        }
    end
    
    if legacyModules.BuyTileHitboxGenerator then
        conflicts.moduleConflicts.Hitboxes = {
            legacyModule = legacyModules.BuyTileHitboxGenerator.path,
            newModule = "GymAutomation (now uses modules)",
            severity = "Medium"
        }
    end
    
    
    -- Check for data conflicts
    local legacyData = self:FindLegacyBuyTileData()
    
    -- Check if we have both BuyTileSystem and legacy data
    if BuyTileSystem and BuyTileSystem.tileData and legacyData.BuyTilesFolder then
        -- Compare count
        local newCount = 0
        for _ in pairs(BuyTileSystem.tileData) do
            newCount += 1
        end
        
        local legacyCount = legacyData.BuyTilesFolder.itemCount
        
        if newCount > 0 and legacyCount > 0 and newCount ~= legacyCount then
            conflicts.dataConflicts.TileCount = {
                description = "Tile count mismatch - BuyTileSystem: " .. newCount .. ", Legacy: " .. legacyCount,
                severity = "Medium"
            }
        end
    end
    
    -- Return conflicts
    return conflicts
end

-- Generate suggestions for resolving conflicts
function MigrationUtils:GetMigrationSuggestions(conflicts)
    local suggestions = {}
    
    -- Module conflict suggestions
    for name, conflict in pairs(conflicts.moduleConflicts) do
        if name == "FloorAttributeSetup" then
            table.insert(suggestions, {
                issue = "Floor attribute handling conflict with " .. conflict.legacyModule,
                solution = "Consider disabling " .. conflict.legacyModule .. " by renaming it to add '.backup' or moving to Unused/ folder"
            })
        elseif name == "TileDataGenerator" then
            table.insert(suggestions, {
                issue = "BuyTile data generation conflict with " .. conflict.legacyModule,
                solution = "Consider disabling " .. conflict.legacyModule .. " by renaming it to add '.backup' or moving to Unused/ folder"
            })
        elseif name == "Hitboxes" then
            table.insert(suggestions, {
                issue = "Hitbox generation conflict with " .. conflict.legacyModule,
                solution = "The updated GymAutomation now handles hitbox generation correctly, consider disabling " .. conflict.legacyModule
            })
        end
    end
    
    -- Data conflict suggestions
    for name, conflict in pairs(conflicts.dataConflicts) do
        if name == "TileCount" then
            table.insert(suggestions, {
                issue = conflict.description,
                solution = "Run MigrationUtils:ImportLegacyData() to synchronize tile data between systems"
            })
        end
    end
    
    return suggestions
end

-- Create command for running the migration
function MigrationUtils:CreateCommand()
    local CommandService = CoreRegistry and CoreRegistry:GetSystem("CommandService")
    
    if not CommandService then
        self:Log("CommandService not found, commands won't be available")
        return false
    end
    
    -- Register migration command
    CommandService:RegisterCommand("migrateBuyTileSystem", {
        description = "Migrates legacy BuyTile data to the new modular system",
        parameters = {},
        handler = function(player)
            -- Check if player is authorized to run admin commands
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            -- Run migration
            local stats = self:ImportLegacyData()
            
            -- Check for conflicts
            local conflicts = self:CheckForConflicts()
            local hasConflicts = false
            
            for _, _ in pairs(conflicts.moduleConflicts) do
                hasConflicts = true
                break
            end
            
            if not hasConflicts then
                for _, _ in pairs(conflicts.dataConflicts) do
                    hasConflicts = true
                    break
                end
            end
            
            -- Generate response
            local response = "Migration complete:\n"
            response = response .. "- Tiles imported: " .. stats.tilesImported .. "\n"
            response = response .. "- Models processed: " .. stats.modelsProcessed .. "\n"
            
            if stats.errors > 0 then
                response = response .. "- Errors: " .. stats.errors .. "\n"
            end
            
            if hasConflicts then
                response = response .. "\nWarning: Conflicts detected between old and new systems.\n"
                response = response .. "Run '/migrationInfo' for details."
            end
            
            return response
        end
    })
    
    -- Register migration info command
    CommandService:RegisterCommand("migrationInfo", {
        description = "Shows information about BuyTile system migration",
        parameters = {},
        handler = function(player)
            -- Check if player is authorized to run admin commands
            local AdminService = CoreRegistry:GetSystem("AdminService")
            if AdminService and not AdminService:IsAdmin(player) then
                return "You don't have permission to use this command"
            end
            
            -- Find legacy modules
            local legacyModules = self:FindLegacyBuyTileModules()
            local legacyData = self:FindLegacyBuyTileData()
            local conflicts = self:CheckForConflicts()
            local suggestions = self:GetMigrationSuggestions(conflicts)
            
            -- Generate response
            local response = "=== MIGRATION INFO ===\n\n"
            
            -- Legacy modules
            response = response .. "Legacy modules found: " .. #legacyModules .. "\n"
            for name, info in pairs(legacyModules) do
                response = response .. "- " .. name .. " (" .. info.path .. ")\n"
            end
            
            -- Legacy data
            response = response .. "\nLegacy data found: " .. #legacyData .. "\n"
            for name, info in pairs(legacyData) do
                if info.itemCount then
                    response = response .. "- " .. name .. " (" .. info.itemCount .. " items)\n"
                else
                    response = response .. "- " .. name .. " (" .. info.path .. ")\n"
                end
            end
            
            -- Conflicts
            local hasConflicts = false
            for _, _ in pairs(conflicts.moduleConflicts) do
                hasConflicts = true
                break
            end
            
            if not hasConflicts then
                for _, _ in pairs(conflicts.dataConflicts) do
                    hasConflicts = true
                    break
                end
            end
            
            if hasConflicts then
                response = response .. "\n=== CONFLICTS DETECTED ===\n"
                
                for name, conflict in pairs(conflicts.moduleConflicts) do
                    response = response .. "- [" .. conflict.severity .. "] " .. name .. ": " .. 
                                          conflict.legacyModule .. " conflicts with " .. conflict.newModule .. "\n"
                end
                
                for name, conflict in pairs(conflicts.dataConflicts) do
                    response = response .. "- [" .. conflict.severity .. "] " .. name .. ": " .. 
                                          conflict.description .. "\n"
                end
                
                -- Suggestions
                if #suggestions > 0 then
                    response = response .. "\n=== SUGGESTIONS ===\n"
                    
                    for _, suggestion in ipairs(suggestions) do
                        response = response .. "- Issue: " .. suggestion.issue .. "\n"
                        response = response .. "  Solution: " .. suggestion.solution .. "\n"
                    end
                end
            else
                response = response .. "\nNo conflicts detected. Safe to migrate.\n"
            end
            
            return response
        end
    })
    
    return true
end

-- Help function for creating global migration functions
function MigrationUtils:CreateGlobalFunctions()
    if RunService:IsStudio() then
        _G.MigrateBuyTileSystem = function()
            print("Starting BuyTile system migration...")
            local stats = MigrationUtils:ImportLegacyData()
            print("Migration complete!")
            print("- Tiles imported: " .. stats.tilesImported)
            print("- Models processed: " .. stats.modelsProcessed)
            if stats.errors > 0 then
                warn("- Errors: " .. stats.errors)
            end
            
            -- Check for conflicts
            local conflicts = MigrationUtils:CheckForConflicts()
            local hasConflicts = false
            
            for _, _ in pairs(conflicts.moduleConflicts) do
                hasConflicts = true
                break
            end
            
            if not hasConflicts then
                for _, _ in pairs(conflicts.dataConflicts) do
                    hasConflicts = true
                    break
                end
            end
            
            if hasConflicts then
                warn("\nWarning: Conflicts detected between old and new systems.")
                print("Run _G.ShowMigrationInfo() for details.")
            end
            
            return stats
        end
        
        _G.ShowMigrationInfo = function()
            print("\n=== MIGRATION INFO ===")
            
            -- Find legacy modules
            local legacyModules = MigrationUtils:FindLegacyBuyTileModules()
            local legacyData = MigrationUtils:FindLegacyBuyTileData()
            local conflicts = MigrationUtils:CheckForConflicts()
            local suggestions = MigrationUtils:GetMigrationSuggestions(conflicts)
            
            -- Legacy modules
            print("\nLegacy modules found: " .. #legacyModules)
            for name, info in pairs(legacyModules) do
                print("- " .. name .. " (" .. info.path .. ")")
            end
            
            -- Legacy data
            print("\nLegacy data found: " .. #legacyData)
            for name, info in pairs(legacyData) do
                if info.itemCount then
                    print("- " .. name .. " (" .. info.itemCount .. " items)")
                else
                    print("- " .. name .. " (" .. info.path .. ")")
                end
            end
            
            -- Conflicts
            local hasConflicts = false
            for _, _ in pairs(conflicts.moduleConflicts) do
                hasConflicts = true
                break
            end
            
            if not hasConflicts then
                for _, _ in pairs(conflicts.dataConflicts) do
                    hasConflicts = true
                    break
                end
            end
            
            if hasConflicts then
                warn("\n=== CONFLICTS DETECTED ===")
                
                for name, conflict in pairs(conflicts.moduleConflicts) do
                    warn("- [" .. conflict.severity .. "] " .. name .. ": " .. 
                         conflict.legacyModule .. " conflicts with " .. conflict.newModule)
                end
                
                for name, conflict in pairs(conflicts.dataConflicts) do
                    warn("- [" .. conflict.severity .. "] " .. name .. ": " .. 
                         conflict.description)
                end
                
                -- Suggestions
                if #suggestions > 0 then
                    print("\n=== SUGGESTIONS ===")
                    
                    for _, suggestion in ipairs(suggestions) do
                        print("- Issue: " .. suggestion.issue)
                        print("  Solution: " .. suggestion.solution)
                    end
                end
            else
                print("\nNo conflicts detected. Safe to migrate.")
            end
            
            return conflicts
        end
        
        print("✓ Registered global function: _G.MigrateBuyTileSystem()")
        print("✓ Registered global function: _G.ShowMigrationInfo()")
    end
end

-- Initialize the migration utilities
function MigrationUtils:Initialize()
    self:Log("MigrationUtils initializing...")
    
    -- Create command
    self:CreateCommand()
    
    -- Create global functions for Studio
    self:CreateGlobalFunctions()
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("MigrationUtils", self)
        self:Log("Registered with CoreRegistry")
    end
    
    self:Log("MigrationUtils initialization complete")
    return self
end

return MigrationUtils:Initialize()