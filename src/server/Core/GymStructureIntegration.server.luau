-- GymStructureIntegration.server.luau
-- Module for handling gym structure and area management
-- Place in ServerScriptService/Core

local ServerScriptService = game:GetService("ServerScriptService")

-- Get references to CoreRegistry
local CoreRegistry
if _G.CoreRegistry then
    CoreRegistry = _G.CoreRegistry
else
    local success, result = pcall(function()
        return require(script.Parent.CoreRegistry)
    end)
    
    if success then
        CoreRegistry = result
    else
        warn("[GymStructureIntegration] Failed to get CoreRegistry")
        return {}
    end
end

-- Create the GymStructureIntegration system
local GymStructureIntegration = {
    -- Cache for gym areas to avoid repeated lookups
    areaCache = {},
    initialized = false
}

-- Debug function
local function log(...)
    print("[GymStructureIntegration]", ...)
end

-- Initialize the system
function GymStructureIntegration:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing GymStructureIntegration...")
    
    -- Clear cache
    self.areaCache = {}
    
    -- Create standard area definitions
    self.standardAreas = {
        "Gym Floor",
        "Cardio Area",
        "Weights Area",
        "Reception",
        "Locker Room",
        "Sauna",
        "Pool",
        "Yoga Studio",
        "Staff Room"
    }
    
    self.initialized = true
    log("GymStructureIntegration initialized")
    return true
end

-- Get a specific area in a tycoon
function GymStructureIntegration:getArea(tycoon, areaName)
    if not tycoon or not areaName then
        return nil
    end
    
    -- Check cache first
    local cacheKey = tostring(tycoon:GetFullName()) .. "_" .. areaName
    if self.areaCache[cacheKey] then
        return self.areaCache[cacheKey]
    end
    
    -- Search for area by name
    local area = tycoon:FindFirstChild(areaName, true)
    
    -- Also try with spaces removed (for compatibility)
    if not area then
        local noSpaceName = areaName:gsub(" ", "")
        area = tycoon:FindFirstChild(noSpaceName, true)
    end
    
    -- Also try with underscore instead of spaces
    if not area then
        local underscoreName = areaName:gsub(" ", "_")
        area = tycoon:FindFirstChild(underscoreName, true)
    end
    
    -- Cache result (even if nil)
    self.areaCache[cacheKey] = area
    
    return area
end

-- Clear cache for a specific tycoon or all tycoons
function GymStructureIntegration:clearCache(tycoon)
    if tycoon then
        -- Clear cache for specific tycoon
        local prefix = tostring(tycoon:GetFullName())
        for key in pairs(self.areaCache) do
            if key:sub(1, #prefix) == prefix then
                self.areaCache[key] = nil
            end
        end
        log("Cleared cache for " .. tycoon:GetFullName())
    else
        -- Clear all cache
        self.areaCache = {}
        log("Cleared all area caches")
    end
end

-- Get all areas in a tycoon
function GymStructureIntegration:getAllAreas(tycoon)
    if not tycoon then
        return {}
    end
    
    local areas = {}
    
    -- Check for standard areas
    for _, areaName in ipairs(self.standardAreas) do
        local area = self:getArea(tycoon, areaName)
        if area then
            areas[areaName] = area
        end
    end
    
    -- Check for any folders that could be areas
    for _, child in ipairs(tycoon:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            -- Skip folders that are already identified as standard areas
            if not areas[child.Name] then
                areas[child.Name] = child
            end
        end
    end
    
    return areas
end

-- Set up equipment spots in an area
function GymStructureIntegration:setupEquipmentSpots(tycoon, areaName, count)
    local area = self:getArea(tycoon, areaName)
    if not area then
        log("Area not found: " .. areaName)
        return false
    end
    
    -- Check if equipment spots already exist
    local existingSpots = area:FindFirstChild("EquipmentSpots")
    if existingSpots then
        log("Equipment spots already exist in " .. areaName)
        return true
    end
    
    -- Create equipment spots folder
    local spotsFolder = Instance.new("Folder")
    spotsFolder.Name = "EquipmentSpots"
    spotsFolder.Parent = area
    
    -- Try to find floor in the area
    local floor
    for _, child in ipairs(area:GetDescendants()) do
        if child:IsA("BasePart") and 
           (child.Name:lower():find("floor") or 
            child.Name:lower():find("ground")) then
            floor = child
            break
        end
    end
    
    if not floor then
        log("No floor found in " .. areaName)
        return false
    end
    
    -- Create spots
    count = count or 5
    local size = floor.Size
    local centerPos = floor.Position
    
    for i = 1, count do
        local spot = Instance.new("Part")
        spot.Name = "EquipmentSpot" .. i
        spot.Anchored = true
        spot.CanCollide = false
        spot.Transparency = 1
        spot.Size = Vector3.new(1, 0.1, 1)
        
        -- Distribute spots on the floor
        local xOffset = (math.random() - 0.5) * (size.X * 0.8)
        local zOffset = (math.random() - 0.5) * (size.Z * 0.8)
        
        spot.Position = Vector3.new(
            centerPos.X + xOffset,
            floor.Position.Y + floor.Size.Y/2 + 0.1,
            centerPos.Z + zOffset
        )
        
        spot:SetAttribute("Occupied", false)
        spot.Parent = spotsFolder
    end
    
    log("Created " .. count .. " equipment spots in " .. areaName)
    return true
end

-- Public API
local PublicAPI = {
    initialize = function()
        return GymStructureIntegration:initialize()
    end,
    
    getArea = function(tycoon, areaName)
        return GymStructureIntegration:getArea(tycoon, areaName)
    end,
    
    getAllAreas = function(tycoon)
        return GymStructureIntegration:getAllAreas(tycoon)
    end,
    
    clearCache = function(tycoon)
        return GymStructureIntegration:clearCache(tycoon)
    end,
    
    setupEquipmentSpots = function(tycoon, areaName, count)
        return GymStructureIntegration:setupEquipmentSpots(tycoon, areaName, count)
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("GymStructureIntegration", PublicAPI, {"EventBridge"})
