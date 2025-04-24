--[[
    BoundingBoxManager.server.luau
    
    Consolidated module that handles all bounding box and hitbox functionality.
    This module combines functionality from:
    - BoundingBoxGenerator.server.luau
    - EquipmentBoundingBox.luau
    
    Author: Created April 2025
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Configuration constants
local HITBOX_CONFIG = {
    DEFAULT_COLOR = Color3.fromRGB(255, 80, 80),
    HIGHLIGHT_COLOR = Color3.fromRGB(80, 255, 80),
    DEFAULT_TRANSPARENCY = 0.8,
    PADDING = 0.2,
    DEFAULT_HITBOX_FOLDER = "BuyTileHitboxes",
}

-- The BoundingBoxManager module
local BoundingBoxManager = {}
BoundingBoxManager.__index = BoundingBoxManager

-- Internal state variables
local _hitboxesVisible = true
local _debugMode = RunService:IsStudio()
local _allHitboxes = {}

-- Return the appropriate system to get access to BuyTileSystem
local function GetBuyTileSystem()
    -- Check if we're inside a CoreRegistry environment
    if script.Parent and script.Parent.Parent then
        local CoreRegistry = script.Parent.Parent:FindFirstChild("CoreRegistry")
        if CoreRegistry and CoreRegistry:IsA("ModuleScript") then
            local Registry = require(CoreRegistry)
            if Registry and Registry.GetSystem then
                return Registry:GetSystem("BuyTileSystem")
            end
        end
    end

    -- Try to find it through ServerScriptService
    local ServerScriptService = game:GetService("ServerScriptService")
    local coreFolder = ServerScriptService:FindFirstChild("Core") or ServerScriptService:FindFirstChild("Systems")
    
    if coreFolder then
        for _, module in pairs(coreFolder:GetDescendants()) do
            if module:IsA("ModuleScript") and module.Name == "BuyTileSystem" then
                return require(module)
            end
        end
    end
    
    -- Last resort - try to find it globally
    if _G.BuyTileSystem then
        return _G.BuyTileSystem
    end
    
    return nil
end

-- Calculate a bounding box for a model or a collection of parts
function BoundingBoxManager:CalculateBoundingBox(instanceOrParts)
    local parts
    
    if typeof(instanceOrParts) == "table" then
        -- If we're given a table of parts
        parts = instanceOrParts
    else
        -- If we're given an instance
        parts = {}
        if instanceOrParts:IsA("BasePart") then
            table.insert(parts, instanceOrParts)
        else
            for _, descendant in pairs(instanceOrParts:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    table.insert(parts, descendant)
                end
            end
        end
    end
    
    -- If no parts were found, return a default bounding box
    if #parts == 0 then
        return {
            CFrame = CFrame.new(0, 0, 0),
            Size = Vector3.new(0, 0, 0)
        }
    end
    
    -- Initialize min and max with the first part
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    -- Find min and max bounds
    for _, part in ipairs(parts) do
        local cf = part.CFrame
        local size = part.Size
        
        -- Get corner positions
        for _, corner in pairs({
            cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
        }) do
            local pos = corner.Position
            minX, minY, minZ = math.min(minX, pos.X), math.min(minY, pos.Y), math.min(minZ, pos.Z)
            maxX, maxY, maxZ = math.max(maxX, pos.X), math.max(maxY, pos.Y), math.max(maxZ, pos.Z)
        end
    end
    
    -- Add padding
    minX = minX - HITBOX_CONFIG.PADDING
    minY = minY - HITBOX_CONFIG.PADDING
    minZ = minZ - HITBOX_CONFIG.PADDING
    maxX = maxX + HITBOX_CONFIG.PADDING
    maxY = maxY + HITBOX_CONFIG.PADDING
    maxZ = maxZ + HITBOX_CONFIG.PADDING
    
    -- Calculate center and size
    local center = Vector3.new((minX + maxX)/2, (minY + maxY)/2, (minZ + maxZ)/2)
    local size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
    
    return {
        CFrame = CFrame.new(center),
        Size = size
    }
end

-- Create a hitbox part with given properties
function BoundingBoxManager:CreateHitbox(name, cf, size, parent, attributes)
    local hitbox = Instance.new("Part")
    hitbox.Name = name or "Hitbox"
    hitbox.Anchored = true
    hitbox.CanCollide = false
    hitbox.CastShadow = false
    hitbox.CFrame = cf
    hitbox.Size = size
    hitbox.Transparency = HITBOX_CONFIG.DEFAULT_TRANSPARENCY
    hitbox.BrickColor = BrickColor.new(HITBOX_CONFIG.DEFAULT_COLOR)
    hitbox.Material = Enum.Material.SmoothPlastic
    
    -- Add this to our global hitbox tracking
    table.insert(_allHitboxes, hitbox)
    
    -- Apply any provided attributes
    if attributes then
        for name, value in pairs(attributes) do
            hitbox:SetAttribute(name, value)
        end
    end
    
    -- Set parent last to avoid spam in output
    hitbox.Parent = parent
    
    -- Apply visibility setting
    hitbox.Transparency = _hitboxesVisible and HITBOX_CONFIG.DEFAULT_TRANSPARENCY or 1
    
    -- Tag the hitbox for easier finding later
    if RunService:IsServer() then
        local CollectionService = game:GetService("CollectionService")
        CollectionService:AddTag(hitbox, "Hitbox")
    end
    
    return hitbox
end

-- Generate hitboxes for buyable tiles in a tycoon
function BoundingBoxManager:GenerateHitboxes(tycoon, options)
    options = options or {}
    
    -- Create options from defaults
    local showDebug = options.showDebug or _debugMode
    local autoSetAttributes = options.autoSetAttributes ~= false
    local hitboxFolder = options.hitboxFolder
    
    local BuyTileSystem = GetBuyTileSystem()
    local stats = {
        created = 0,
        errors = 0,
    }
    
    -- Find or create the hitbox folder
    if not hitboxFolder then
        hitboxFolder = tycoon:FindFirstChild(HITBOX_CONFIG.DEFAULT_HITBOX_FOLDER)
        if not hitboxFolder then
            hitboxFolder = Instance.new("Folder")
            hitboxFolder.Name = HITBOX_CONFIG.DEFAULT_HITBOX_FOLDER
            hitboxFolder.Parent = tycoon
        else
            -- Clear existing hitboxes
            hitboxFolder:ClearAllChildren()
        end
    end
    
    -- If BuyTileSystem isn't available, we can't create hitboxes
    if not BuyTileSystem or not BuyTileSystem.tileData then
        if showDebug then
            warn("BoundingBoxManager: Cannot generate hitboxes - BuyTileSystem not found or no tile data available")
        end
        stats.errors = stats.errors + 1
        return stats
    end
    
    -- Helper function to find a floor position in the tycoon
    local function FindSpotOnFloor(floorNum)
        local floorY = (floorNum - 1) * 10 + 2  -- Assuming 10 stud floor height
        local bestCandidate = nil
        local bestCandidateScore = -math.huge
        
        -- Search for parts that are on this floor
        for _, part in ipairs(tycoon:GetDescendants()) do
            if part:IsA("BasePart") and part:GetAttribute("Floor") == floorNum then
                -- Prefer parts that are floor parts and in central positions
                local isFloor = part:GetAttribute("IsFloor") == true or part.Name:match("Floor") ~= nil
                local centerDistance = (part.Position * Vector3.new(1, 0, 1)).Magnitude
                local score = (isFloor and 100 or 0) - centerDistance
                
                if score > bestCandidateScore then
                    bestCandidate = part
                    bestCandidateScore = score
                end
            end
        end
        
        -- Return position, defaulting to tycoon position if no parts found
        if bestCandidate then
            return Vector3.new(bestCandidate.Position.X, floorY, bestCandidate.Position.Z)
        else
            return Vector3.new(tycoon.PrimaryPart and tycoon.PrimaryPart.Position.X or 0, floorY, tycoon.PrimaryPart and tycoon.PrimaryPart.Position.Z or 0)
        end
    end
    
    -- Process each tile type in the BuyTileSystem
    for tileType, data in pairs(BuyTileSystem.tileData) do
        -- Skip tiles that already exist in the tycoon
        local exists = false
        for _, child in pairs(tycoon:GetDescendants()) do
            if child:IsA("Model") and child.Name == tileType then
                exists = true
                break
            end
        end
        
        if exists and not options.recreateAll then
            continue
        end

        -- Find where to place the hitbox
        local floor = data.floor or 1
        local position = FindSpotOnFloor(floor)
        
        -- Create attributes for the hitbox
        local attributes = {
            TileType = tileType,
            Price = data.price,
            IncomeBoost = data.incomeBoost or 0,
            Floor = floor,
            Category = data.category or "Misc",
            Description = data.description or tileType
        }
        
        -- If there's a buildOrder, add it
        if data.buildOrder then
            attributes.BuildOrder = data.buildOrder
        end
        
        -- If there are prerequisites, add them
        if data.prerequisites and #data.prerequisites > 0 then
            attributes.Prerequisites = table.concat(data.prerequisites, ",")
        end
        
        -- Create the hitbox
        local hitbox = self:CreateHitbox(
            "BuyTile_" .. tileType,
            CFrame.new(position),
            Vector3.new(4, 4, 4),
            hitboxFolder,
            attributes
        )

        stats.created = stats.created + 1
    end
    
    if showDebug then
        print("BoundingBoxManager: Generated " .. stats.created .. " hitboxes for " .. tycoon.Name)
    end
    
    return stats
end

-- Generate hitboxes for equipment models
function BoundingBoxManager:GenerateEquipmentHitboxes(equipment, options)
    options = options or {}
    
    local showDebug = options.showDebug or _debugMode
    local autoSetAttributes = options.autoSetAttributes ~= false
    local hitboxParent = options.hitboxParent or equipment
    
    -- Don't create hitboxes if the equipment already has them
    if equipment:FindFirstChild("Hitbox") and not options.recreate then
        return {
            created = 0,
            skipped = 1
        }
    end

    -- Calculate the bounding box for the equipment
    local bbox = self:CalculateBoundingBox(equipment)

    -- Create attributes from the equipment model
    local attributes = {}

    if autoSetAttributes then
        for name, value in pairs(equipment:GetAttributes()) do
            attributes[name] = value
        end

        -- Add the equipment name if not already set
        if not attributes.EquipmentName then
            attributes.EquipmentName = equipment.Name
        end
    end

    -- Create the hitbox
    local hitboxName = "Hitbox"
    -- Check if the equipment has a primary part with a specific name
    if equipment.PrimaryPart and equipment.PrimaryPart.Name == "ClickDetectorPart" then
        hitboxName = "InteractionHitbox" -- Different name for interaction
    end
    local hitbox = self:CreateHitbox(hitboxName, bbox.CFrame, bbox.Size, hitboxParent, attributes)

    if showDebug then
        print("BoundingBoxManager: Generated hitbox for equipment: " .. equipment:GetFullName() .. ", Type: " .. hitboxName)
    end

    return {
        created = 1,
        hitbox = hitbox
    }
end

-- Show all hitboxes
function BoundingBoxManager:ShowHitboxes()
    _hitboxesVisible = true
    
    for _, hitbox in pairs(_allHitboxes) do
        if hitbox and hitbox.Parent then
            hitbox.Transparency = HITBOX_CONFIG.DEFAULT_TRANSPARENCY
        end
    end
    
    -- Also check for any tagged hitboxes we might not be tracking directly
    if RunService:IsServer() then
        local CollectionService = game:GetService("CollectionService")
        for _, hitbox in pairs(CollectionService:GetTagged("Hitbox")) do
            if hitbox:IsA("BasePart") then
                hitbox.Transparency = HITBOX_CONFIG.DEFAULT_TRANSPARENCY
            end
        end
    end
    
    return { visible = true, count = #_allHitboxes }
end

-- Hide all hitboxes
function BoundingBoxManager:HideHitboxes()
    _hitboxesVisible = false
    
    for _, hitbox in pairs(_allHitboxes) do
        if hitbox and hitbox.Parent then
            hitbox.Transparency = 1
        end
    end
    
    -- Also check for any tagged hitboxes we might not be tracking directly
    if RunService:IsServer() then
        local CollectionService = game:GetService("CollectionService")
        for _, hitbox in pairs(CollectionService:GetTagged("Hitbox")) do
            if hitbox:IsA("BasePart") then
                hitbox.Transparency = 1
            end
        end
    end
    
    return { visible = false, count = #_allHitboxes }
end

-- Highlight a specific hitbox
function BoundingBoxManager:HighlightHitbox(hitbox)
    if hitbox and hitbox:IsA("BasePart") then
        -- Store original color
        local originalColor = hitbox.Color
        
        -- Highlight the hitbox
        hitbox.Color = HITBOX_CONFIG.HIGHLIGHT_COLOR
        hitbox.Transparency = 0.5
        
        -- Restore after a delay
        task.delay(2, function()
            if hitbox and hitbox.Parent then
                hitbox.Color = originalColor
                hitbox.Transparency = _hitboxesVisible and HITBOX_CONFIG.DEFAULT_TRANSPARENCY or 1
            end
        end)
        
        return true
    end
    
    return false
end

-- Clean up stray or orphaned hitboxes
function BoundingBoxManager:CleanupHitboxes()
    local removed = 0
    
    for i = #_allHitboxes, 1, -1 do
        local hitbox = _allHitboxes[i]
        if not hitbox or not hitbox.Parent then
            table.remove(_allHitboxes, i)
            removed = removed + 1
        end
    end
    
    return { removed = removed }
end

-- Toggle debug mode
function BoundingBoxManager:SetDebugMode(enabled)
    _debugMode = enabled == true
    return { debugMode = _debugMode }
end

-- Initialize legacy support for old BoundingBoxGenerator and EquipmentBoundingBox scripts
-- This enables backward compatibility with existing scripts that might still call the old functions
function BoundingBoxManager:LegacySupport()
    -- Get access to the shared environment without using _G directly
    local sharedEnv = _ENV
    
    -- Create a LegacyBoundingBoxGenerator API that forwards to our new methods
    local LegacyBoundingBoxGenerator = {
        CreateHitbox = function(instance, options)
            return BoundingBoxManager:CreateHitbox(instance, options)
        end,
        
        GenerateBoundingBox = function(instance, padding)
            local result = BoundingBoxManager:CalculateBoundingBox(instance)
            -- Apply padding if specified
            if padding and type(padding) == "number" then
                result.Size = result.Size + Vector3.new(padding * 2, padding * 2, padding * 2)
            end
            return result
        end,
        
        ShowHitboxes = function(visible)
            return BoundingBoxManager:SetHitboxVisibility(visible ~= false)
        end,
        
        HideHitboxes = function()
            return BoundingBoxManager:SetHitboxVisibility(false)
        end,
        
        CreateTileHitbox = function(tile, options)
            return BoundingBoxManager:CreateBuyTileHitbox(tile, options)
        end
    }
    
    -- Create a LegacyEquipmentBoundingBox API that forwards to our new methods
    local LegacyEquipmentBoundingBox = {
        CreateInteractionBox = function(equipment, options)
            return BoundingBoxManager:CreateEquipmentInteractionBox(equipment, options)
        end,
        
        GenerateEquipmentBounds = function(equipment, padding)
            local options = type(padding) == "number" and {padding = padding} or {}
            return BoundingBoxManager:CalculateBoundingBox(equipment, options)
        end
    }
    
    -- Set up an interface for legacy access through CoreRegistry
    if script.Parent and script.Parent.Parent then
        local CoreRegistry = script.Parent.Parent:FindFirstChild("CoreRegistry")
        if CoreRegistry and CoreRegistry:IsA("ModuleScript") then
            local Registry = require(CoreRegistry)
            if Registry and Registry.RegisterLegacySystem then
                Registry:RegisterLegacySystem("BoundingBoxGenerator", LegacyBoundingBoxGenerator)
                Registry:RegisterLegacySystem("EquipmentBoundingBox", LegacyEquipmentBoundingBox)
            end
        end
    end
    
    -- Set up Studio-only global functions for backward compatibility
    -- In strict mode, we should use RunService:IsStudio() check rather than direct _G assignment
    if RunService:IsStudio() then
        local success, errorMsg = pcall(function()
            -- Use rawset to avoid strict mode errors for global assignments
            rawset(sharedEnv, "ShowHitboxes", function()
                return BoundingBoxManager:SetHitboxVisibility(true)
            end)
            
            rawset(sharedEnv, "HideHitboxes", function()
                return BoundingBoxManager:SetHitboxVisibility(false)
            end)
        end)
        
        if not success then
            warn("BoundingBoxManager: Failed to set up legacy global functions: " .. errorMsg)
        end
    end
    
    return {
        BoundingBoxGenerator = LegacyBoundingBoxGenerator,
        EquipmentBoundingBox = LegacyEquipmentBoundingBox
    }
end

-- Initialize and return the module
local function Initialize()
    -- Set up legacy support
    BoundingBoxManager:LegacySupport()
    
    return BoundingBoxManager
end

-- Return the initialized BoundingBoxManager module
return Initialize()