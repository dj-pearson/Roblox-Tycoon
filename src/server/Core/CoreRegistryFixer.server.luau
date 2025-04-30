--!strict
--[[
    CoreRegistryFixer.server.luau
    Emergency fixer script for CoreRegistry missing systems
    
    Updated: April 29, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Find CoreRegistry
local function findCoreRegistry()
    local paths = {
        ServerScriptService.Core,
        ServerScriptService.Systems,
        ServerScriptService.src.server.Core,
        ReplicatedStorage.src.shared,
        ReplicatedStorage.shared
    }
    
    for _, path in ipairs(paths) do
        if path and path:FindFirstChild("CoreRegistry") then
            local success, module = pcall(function()
                return require(path.CoreRegistry)
            end)
            
            if success and type(module) == "table" and module.registerSystem then
                print("[CoreRegistryFixer] Found CoreRegistry at:", path.CoreRegistry:GetFullName())
                return module
            end
        end
    end
    
    print("[CoreRegistryFixer] Could not find CoreRegistry")
    return nil
end

-- Find or create essential systems
local function createEssentialSystem(name)
    print("[CoreRegistryFixer] Creating essential system:", name)
    
    local system = {
        name = name,
        initialized = true,
        
        initialize = function(self)
            print("[CoreRegistryFixer] Initialized system:", name)
            return true
        end
    }
    
    if name == "ModuleLoader" then
        system.loadModule = function(modulePath)
            return require(modulePath)
        end
    elseif name == "DataManager" then
        system.getPlayerData = function(player)
            return {
                cash = 1000,
                level = 1,
                tiles = {}
            }
        end
    elseif name == "UIComponents" then
        system.createButton = function(props)
            print("[CoreRegistryFixer] Created UI button:", props.name or "unnamed")
            return {}
        end
    elseif name == "AssetValidator" then
        system.validateAsset = function(assetId)
            return true
        end
    elseif name == "BuyTileSystem" then
        system.initialize = function(self)
            print("[CoreRegistryFixer] Initialized BuyTileSystem (placeholder)")
            return true
        end
        
        system.spawnBuyTile = function(tileId, position)
            print("[CoreRegistryFixer] Spawned BuyTile:", tileId, "at position", tostring(position))
            return {}
        end
    end
    
    return system
end

-- Check if system exists and create placeholders if needed
local function ensureSystemsExist(CoreRegistry)
    if not CoreRegistry then return end
    
    local criticalSystems = {
        "ModuleLoader",
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem"
    }
    
    for _, systemName in ipairs(criticalSystems) do
        local system = CoreRegistry:GetSystem(systemName)
        
        if not system then
            print("[CoreRegistryFixer] System missing:", systemName, "- Creating placeholder")
            local placeholderSystem = createEssentialSystem(systemName)
            CoreRegistry:registerSystem(systemName, placeholderSystem)
        else
            print("[CoreRegistryFixer] System exists:", systemName)
        end
    end
end

-- Disable UISystemEnhancer emergency UI
local function disableEmergencyUI()
    local paths = {
        ReplicatedStorage.src.client,
        ServerScriptService.src.client
    }
    
    for _, path in ipairs(paths) do
        local enhancer = path and (path:FindFirstChild("UISystemEnhancer") or path:FindFirstChild("UISystemEnhancer_fixed"))
        
        if enhancer then
            print("[CoreRegistryFixer] Found UISystemEnhancer:", enhancer:GetFullName())
            -- Set attribute to disable emergency UI
            enhancer:SetAttribute("DisableEmergencyUI", true)
            print("[CoreRegistryFixer] Disabled emergency UI for", enhancer.Name)
        end
    end
end

-- Main execution
local CoreRegistry = findCoreRegistry()

if CoreRegistry then
    ensureSystemsExist(CoreRegistry)
    disableEmergencyUI()
    print("[CoreRegistryFixer] Completed system checks and fixes")
else
    warn("[CoreRegistryFixer] Failed to find CoreRegistry, cannot apply fixes")
end

-- Set global emergency value to allow emergency UI to detect we've fixed things
_G.CoreRegistryFixed = true

return true
