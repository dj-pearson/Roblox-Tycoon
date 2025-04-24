--!strict
--[[
    ⚠️ DEPRECATED SCRIPT ⚠️
    
    This script is deprecated and will be removed after June 30, 2025
    
    It has been replaced by the new consolidated module system:
    → EquipmentManager.server.luau
    
    Please migrate your code to use the new system.
    
    For documentation and migration guides, see:
    https://devforum.roblox.com/t/gym-automation-system-documentation
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Find the new EquipmentManager module
local function FindEquipmentManager()
    -- Try to find CoreRegistry first
    local coreFolder = ServerScriptService:FindFirstChild("Core") 
        or ServerScriptService:FindFirstChild("Systems")
        or ServerScriptService:FindFirstChild("server")
        
    if coreFolder then
        for _, module in ipairs(coreFolder:GetDescendants()) do
            if module:IsA("ModuleScript") and module.Name == "CoreRegistry" then
                local success, registry = pcall(function()
                    return require(module)
                end)
                
                if success and registry and registry.GetSystem then
                    local equipmentManager = registry:GetSystem("EquipmentManager")
                    if equipmentManager then
                        return equipmentManager
                    end
                end
            end
        end
    end
    
    -- Direct search for EquipmentManager
    for _, service in ipairs({ServerScriptService, game:GetService("ReplicatedStorage")}) do
        for _, descendant in ipairs(service:GetDescendants()) do
            if descendant:IsA("ModuleScript") and descendant.Name == "EquipmentManager" then
                local success, module = pcall(function()
                    return require(descendant)
                end)
                
                if success and module then
                    return module
                end
            end
        end
    end
    
    warn("⚠️ Could not locate EquipmentManager module. Legacy equipment upgrade functionality will be limited.")
    return nil
end

-- Get deprecation helper
local DeprecationHelper
local success, result = pcall(function()
    return require(ServerScriptService.server.Utilities.DeprecationHelper)
end)

if success then
    DeprecationHelper = result
end

-- Create equipment upgrade system module
local EquipmentUpgradeSystem = {}

-- Get the actual implementation
local EquipmentManager = FindEquipmentManager()

-- Equipment upgrade functions that map to the new EquipmentManager
if EquipmentManager then
    -- Define function mappings from old API to new API
    local functionMappings = {
        UpgradeEquipment = "UpgradeEquipment",
        GetUpgradeInfo = "GetNextUpgradeInfo",
        GetNextLevel = function(...)
            local info = EquipmentManager:GetNextUpgradeInfo(...)
            return info and info.level or nil
        end,
        GetUpgradePrice = function(...)
            local info = EquipmentManager:GetNextUpgradeInfo(...)
            return info and info.price or 0
        end,
        IsMaxLevel = function(model)
            local currentLevel = model:GetAttribute("UpgradeLevel") or 1
            local maxLevel = model:GetAttribute("MaxUpgradeLevel") or 5
            return currentLevel >= maxLevel
        end,
        GetUpgradeName = function(...)
            local info = EquipmentManager:GetNextUpgradeInfo(...)
            return info and info.name or nil
        end
    }
    
    -- Use the deprecation helper if available, or create simple wrappers
    if DeprecationHelper then
        -- For simple mappings
        for oldName, newNameOrFunc in pairs(functionMappings) do
            if type(newNameOrFunc) == "string" and type(EquipmentManager[newNameOrFunc]) == "function" then
                EquipmentUpgradeSystem[oldName] = DeprecationHelper.WrapDeprecatedFunction(
                    "EquipmentUpgradeSystem", 
                    oldName,
                    function(...)
                        return EquipmentManager[newNameOrFunc](EquipmentManager, ...)
                    end,
                    "EquipmentManager",
                    newNameOrFunc,
                    "Equipment upgrades have been consolidated into EquipmentManager"
                )
            elseif type(newNameOrFunc) == "function" then
                -- For complex mappings
                EquipmentUpgradeSystem[oldName] = DeprecationHelper.WrapDeprecatedFunction(
                    "EquipmentUpgradeSystem", 
                    oldName,
                    function(...)
                        return newNameOrFunc(...)
                    end,
                    "EquipmentManager",
                    "EquipmentManager equivalent",
                    "Equipment upgrades have been consolidated into EquipmentManager"
                )
            end
        end
    else
        -- Manual implementation if helper not available
        for oldName, newNameOrFunc in pairs(functionMappings) do
            if type(newNameOrFunc) == "string" and type(EquipmentManager[newNameOrFunc]) == "function" then
                EquipmentUpgradeSystem[oldName] = function(...)
                    warn("⚠️ DEPRECATED: EquipmentUpgradeSystem." .. oldName .. " is deprecated. Use EquipmentManager." .. newNameOrFunc .. " instead.")
                    return EquipmentManager[newNameOrFunc](EquipmentManager, ...)
                end
            elseif type(newNameOrFunc) == "function" then
                EquipmentUpgradeSystem[oldName] = function(...)
                    warn("⚠️ DEPRECATED: EquipmentUpgradeSystem." .. oldName .. " is deprecated. Use EquipmentManager equivalent instead.")
                    return newNameOrFunc(...)
                end
            end
        end
    end
else
    -- Fallback implementation with warnings
    local function DeprecatedStub(name)
        return function()
            warn("⚠️ DEPRECATED and UNAVAILABLE: EquipmentUpgradeSystem." .. name .. " is deprecated and EquipmentManager could not be found.")
            return nil
        end
    end
    
    EquipmentUpgradeSystem.UpgradeEquipment = DeprecatedStub("UpgradeEquipment")
    EquipmentUpgradeSystem.GetUpgradeInfo = DeprecatedStub("GetUpgradeInfo")
    EquipmentUpgradeSystem.GetNextLevel = DeprecatedStub("GetNextLevel")
    EquipmentUpgradeSystem.GetUpgradePrice = DeprecatedStub("GetUpgradePrice")
    EquipmentUpgradeSystem.IsMaxLevel = DeprecatedStub("IsMaxLevel")
    EquipmentUpgradeSystem.GetUpgradeName = DeprecatedStub("GetUpgradeName")
end

return EquipmentUpgradeSystem
