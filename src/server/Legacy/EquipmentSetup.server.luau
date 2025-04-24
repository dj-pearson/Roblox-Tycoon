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
    
    warn("⚠️ Could not locate EquipmentManager module. Legacy equipment functionality will be limited.")
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

-- Create equipment setup module
local EquipmentSetup = {}

-- Get the actual implementation
local EquipmentManager = FindEquipmentManager()

-- Equipment setup functions that map to the new EquipmentManager
if EquipmentManager then
    -- Define function mappings from old API to new API
    local functionMappings = {
        SetupEquipment = "ProcessEquipment",
        ProcessGymEquipment = "ProcessAllEquipment",
        GetEquipmentCategory = "DetectEquipmentCategory",
        ApplyAttributes = "SetupEquipmentAttributes",
        InitializeEquipment = "ProcessEquipment",
        CalculatePrice = "CalculateEquipmentPrice",
        GetIncome = "CalculateEquipmentIncome"
    }
    
    -- Use the deprecation helper if available, or create simple wrappers
    if DeprecationHelper then
        EquipmentSetup = DeprecationHelper.WrapDeprecatedModule(
            "EquipmentSetup", 
            EquipmentManager, 
            functionMappings,
            "Equipment configuration has been consolidated into EquipmentManager"
        )
    else
        -- Manual implementation if helper not available
        for oldName, newName in pairs(functionMappings) do
            if type(EquipmentManager[newName]) == "function" then
                EquipmentSetup[oldName] = function(...)
                    warn("⚠️ DEPRECATED: EquipmentSetup." .. oldName .. " is deprecated. Use EquipmentManager." .. newName .. " instead.")
                    return EquipmentManager[newName](EquipmentManager, ...)
                end
            end
        end
    end
else
    -- Fallback implementation with warnings
    local function DeprecatedStub(name)
        return function()
            warn("⚠️ DEPRECATED and UNAVAILABLE: EquipmentSetup." .. name .. " is deprecated and EquipmentManager could not be found.")
            return nil
        end
    end
    
    EquipmentSetup.SetupEquipment = DeprecatedStub("SetupEquipment")
    EquipmentSetup.ProcessGymEquipment = DeprecatedStub("ProcessGymEquipment")
    EquipmentSetup.GetEquipmentCategory = DeprecatedStub("GetEquipmentCategory")
    EquipmentSetup.ApplyAttributes = DeprecatedStub("ApplyAttributes")
    EquipmentSetup.InitializeEquipment = DeprecatedStub("InitializeEquipment")
    EquipmentSetup.CalculatePrice = DeprecatedStub("CalculatePrice")
    EquipmentSetup.GetIncome = DeprecatedStub("GetIncome")
end

return EquipmentSetup
