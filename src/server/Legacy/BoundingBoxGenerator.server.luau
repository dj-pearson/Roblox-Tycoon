--!strict
--[[
    ⚠️ DEPRECATED SCRIPT ⚠️
    
    This script is deprecated and will be removed after June 30, 2025
    
    It has been replaced by the new consolidated module system:
    → BoundingBoxManager.server.luau
    
    Please migrate your code to use the new system.
    
    For documentation and migration guides, see:
    https://devforum.roblox.com/t/gym-automation-system-documentation
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Find the new BoundingBoxManager module
local function FindBoundingBoxManager()
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
                    local boundingBoxManager = registry:GetSystem("BoundingBoxManager")
                    if boundingBoxManager then
                        return boundingBoxManager
                    end
                end
            end
        end
    end
    
    -- Direct search for BoundingBoxManager
    for _, service in ipairs({ServerScriptService, game:GetService("ReplicatedStorage")}) do
        for _, descendant in ipairs(service:GetDescendants()) do
            if descendant:IsA("ModuleScript") and descendant.Name == "BoundingBoxManager" then
                local success, module = pcall(function()
                    return require(descendant)
                end)
                
                if success and module then
                    return module
                end
            end
        end
    end
    
    warn("⚠️ Could not locate BoundingBoxManager module. Legacy hitbox functionality will be limited.")
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

-- Create bounding box generator module
local BoundingBoxGenerator = {}

-- Get the actual implementation
local BoundingBoxManager = FindBoundingBoxManager()

-- BoundingBoxGenerator functions that map to the new BoundingBoxManager
if BoundingBoxManager then
    -- Define function mappings from old API to new API
    local functionMappings = {
        CalculateBoundingBox = "CalculateBoundingBox",
        CreateBuyHitbox = "CreateHitbox",
        CreateTileHitbox = "CreateTileHitbox",
        CreateInteractionZone = "CreateInteractionBox",
        GetHitboxForTile = "GetHitboxForTile",
        ShowHitboxes = "SetHitboxesVisible",
        HideHitboxes = function()
            return BoundingBoxManager:SetHitboxesVisible(false)
        end,
        HighlightHitbox = "HighlightHitbox"
    }
    
    -- Use the deprecation helper if available, or create simple wrappers
    if DeprecationHelper then
        -- For simple mappings
        for oldName, newNameOrFunc in pairs(functionMappings) do
            if type(newNameOrFunc) == "string" and type(BoundingBoxManager[newNameOrFunc]) == "function" then
                BoundingBoxGenerator[oldName] = DeprecationHelper.WrapDeprecatedFunction(
                    "BoundingBoxGenerator", 
                    oldName,
                    function(...)
                        return BoundingBoxManager[newNameOrFunc](BoundingBoxManager, ...)
                    end,
                    "BoundingBoxManager",
                    newNameOrFunc,
                    "Hitbox functionality has been consolidated into BoundingBoxManager"
                )
            elseif type(newNameOrFunc) == "function" then
                -- For complex mappings
                BoundingBoxGenerator[oldName] = DeprecationHelper.WrapDeprecatedFunction(
                    "BoundingBoxGenerator", 
                    oldName,
                    function(...)
                        return newNameOrFunc(...)
                    end,
                    "BoundingBoxManager",
                    "BoundingBoxManager equivalent",
                    "Hitbox functionality has been consolidated into BoundingBoxManager"
                )
            end
        end
    else
        -- Manual implementation if helper not available
        for oldName, newNameOrFunc in pairs(functionMappings) do
            if type(newNameOrFunc) == "string" and type(BoundingBoxManager[newNameOrFunc]) == "function" then
                BoundingBoxGenerator[oldName] = function(...)
                    warn("⚠️ DEPRECATED: BoundingBoxGenerator." .. oldName .. " is deprecated. Use BoundingBoxManager." .. newNameOrFunc .. " instead.")
                    return BoundingBoxManager[newNameOrFunc](BoundingBoxManager, ...)
                end
            elseif type(newNameOrFunc) == "function" then
                BoundingBoxGenerator[oldName] = function(...)
                    warn("⚠️ DEPRECATED: BoundingBoxGenerator." .. oldName .. " is deprecated. Use BoundingBoxManager equivalent instead.")
                    return newNameOrFunc(...)
                end
            end
        end
    end
else
    -- Fallback implementation with warnings
    local function DeprecatedStub(name)
        return function()
            warn("⚠️ DEPRECATED and UNAVAILABLE: BoundingBoxGenerator." .. name .. " is deprecated and BoundingBoxManager could not be found.")
            return nil
        end
    end
    
    BoundingBoxGenerator.CalculateBoundingBox = DeprecatedStub("CalculateBoundingBox")
    BoundingBoxGenerator.CreateBuyHitbox = DeprecatedStub("CreateBuyHitbox")
    BoundingBoxGenerator.CreateTileHitbox = DeprecatedStub("CreateTileHitbox")
    BoundingBoxGenerator.CreateInteractionZone = DeprecatedStub("CreateInteractionZone")
    BoundingBoxGenerator.GetHitboxForTile = DeprecatedStub("GetHitboxForTile")
    BoundingBoxGenerator.ShowHitboxes = DeprecatedStub("ShowHitboxes")
    BoundingBoxGenerator.HideHitboxes = DeprecatedStub("HideHitboxes")
    BoundingBoxGenerator.HighlightHitbox = DeprecatedStub("HighlightHitbox")
end

return BoundingBoxGenerator
