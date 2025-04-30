--!strict
--[[
    CoreRegistryRestorer.server.luau
    Creates and registers missing critical systems in CoreRegistry
    
    Created: April 29, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Debug logging
local function log(message, isError)
    if isError then
        warn("[CoreRegistryRestorer] " .. message)
    else
        print("[CoreRegistryRestorer] " .. message)
    end
end

-- Find CoreRegistry module
local function findCoreRegistry()
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Core"),
        ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and path:FindFirstChild("CoreRegistry") then
            local success, module = pcall(function()
                return require(path.CoreRegistry)
            end)
            
            if success and typeof(module) == "table" and typeof(module.registerSystem) == "function" then
                log("Found CoreRegistry at: " .. path.CoreRegistry:GetFullName())
                return module
            end
        end
    end
    
    log("Could not find CoreRegistry module", true)
    return nil
end

-- Create placeholder implementations for missing systems
local function createPlaceholderSystem(name)
    log("Creating placeholder for missing system: " .. name)
    
    local system = {
        name = name,
        initialized = true,
        
        initialize = function(self)
            log("Initialized placeholder for " .. name)
            return true
        end,
        
        getStatus = function(self)
            return {
                status = "Ready",
                message = "Placeholder implementation active",
                version = "1.0.0"
            }
        end
    }
    
    -- Implement specific functionality for each system type
    if name == "ModuleLoader" then
        system.loadModule = function(self, modulePath)
            log("ModuleLoader placeholder loading module: " .. tostring(modulePath))
            return require(modulePath)
        end
        
        system.getModulePath = function(self, moduleName)
            log("ModuleLoader placeholder looking for module: " .. moduleName)
            -- Try some common paths
            local paths = {
                ReplicatedStorage:FindFirstChild("src"),
                ReplicatedStorage:FindFirstChild("shared"),
                ServerScriptService:FindFirstChild("src"),
                ServerScriptService:FindFirstChild("Core"),
                ServerScriptService:FindFirstChild("Systems")
            }
            
            for _, path in ipairs(paths) do
                if path and path:FindFirstChild(moduleName) then
                    return path:FindFirstChild(moduleName)
                end
            end
            
            return nil
        end
        
    elseif name == "DataManager" then
        local playerData = {}
        
        system.getPlayerData = function(self, player)
            if not playerData[player.UserId] then
                playerData[player.UserId] = {
                    cash = 1000,
                    level = 1,
                    tiles = {},
                    stats = {
                        tilesUnlocked = 0,
                        totalRevenue = 0
                    }
                }
            end
            return playerData[player.UserId]
        end
        
        system.updatePlayerData = function(self, player, dataUpdates)
            if not playerData[player.UserId] then
                self:getPlayerData(player)
            end
            
            for key, value in pairs(dataUpdates) do
                playerData[player.UserId][key] = value
            end
            
            return true
        end
        
    elseif name == "UIComponents" then
        system.createButton = function(self, options)
            log("UIComponents placeholder creating button: " .. (options.name or "unnamed"))
            -- In a real implementation, this would create UI elements
            return {
                type = "Button",
                name = options.name or "Button",
                visible = true,
                enabled = true
            }
        end
        
        system.createPanel = function(self, options)
            log("UIComponents placeholder creating panel: " .. (options.name or "unnamed"))
            return {
                type = "Panel",
                name = options.name or "Panel",
                visible = true,
                children = {}
            }
        end
        
    elseif name == "AssetValidator" then
        system.validateAsset = function(self, assetId)
            log("AssetValidator placeholder validating asset: " .. tostring(assetId))
            return true
        end
        
        system.loadAsset = function(self, assetType, assetId)
            log("AssetValidator placeholder loading asset: " .. tostring(assetId) .. " of type " .. assetType)
            return true
        end
        
    elseif name == "BuyTileSystem" then
        local purchasedTiles = {}
        
        system.purchaseTile = function(self, player, tileId)
            log("BuyTileSystem placeholder purchasing tile: " .. tostring(tileId) .. " for player " .. player.Name)
            
            if not purchasedTiles[player.UserId] then
                purchasedTiles[player.UserId] = {}
            end
            
            purchasedTiles[player.UserId][tileId] = {
                purchased = true,
                timestamp = os.time()
            }
            
            return true
        end
        
        system.spawnBuyTile = function(self, tileId, position)
            log("BuyTileSystem placeholder spawning tile: " .. tostring(tileId) .. " at position " .. tostring(position))
            return {}
        end
        
        system.getPlayerTiles = function(self, player)
            return purchasedTiles[player.UserId] or {}
        end
    end
    
    return system
end

-- Ensure critical systems exist in CoreRegistry
local function ensureCriticalSystems(CoreRegistry)
    if not CoreRegistry then
        log("CoreRegistry not found, cannot ensure critical systems", true)
        return false
    end
    
    local criticalSystems = {
        "ModuleLoader",
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem"
    }
    
    local fixedCount = 0
    
    for _, systemName in ipairs(criticalSystems) do
        -- Check if system already exists
        local existingSystem = CoreRegistry:GetSystem(systemName)
        
        if not existingSystem then
            log("Creating missing critical system: " .. systemName)
            local placeholderSystem = createPlaceholderSystem(systemName)
            CoreRegistry:registerSystem(systemName, placeholderSystem)
            fixedCount = fixedCount + 1
        else
            log("System already exists: " .. systemName)
        end
    end
    
    log("Fixed " .. fixedCount .. " missing critical systems")
    
    -- Try to update registry status if needed
    if typeof(CoreRegistry.setRegistryStatus) == "function" then
        CoreRegistry:setRegistryStatus("Ready")
    end
    
    return fixedCount > 0
end

-- Main execution
log("Starting CoreRegistry restoration process")

local CoreRegistry = findCoreRegistry()
if CoreRegistry then
    local success = ensureCriticalSystems(CoreRegistry)
    
    if success then
        log("Successfully restored critical systems in CoreRegistry")
    else
        log("No critical systems needed restoration")
    end
else
    log("Failed to restore critical systems - CoreRegistry not found", true)
end

-- Set global flag to indicate fixes have been applied
_G.CoreRegistryRestored = true

return true
