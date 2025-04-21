--[[
    AutomationInitializer.server.luau - 
    
    Direct initializer for automation tools. This script avoids complex path resolution
    by defining all the automation functionality in one file.
    
    Just run the game in Studio and then use _G.AutomateGym() in the Command Bar.
    
    Created: April 20, 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Only run in Studio
if not RunService:IsStudio() then
    return
end

print("\n=== GYM TYCOON AUTOMATION INITIALIZER ===")
print("Initializing automation tools...")

--------------------------------
-- UTILITY FUNCTIONS
--------------------------------

-- Calculate bounds of a model (min/max in each dimension)
local function calculateModelBounds(model)
    local minBound = Vector3.new(math.huge, math.huge, math.huge)
    local maxBound = Vector3.new(-math.huge, -math.huge, -math.huge)
    local hasParts = false
    
    local function processPart(part)
        hasParts = true
        local size = part.Size
        local pos = part.Position
        
        minBound = Vector3.new(
            math.min(minBound.X, pos.X - size.X/2),
            math.min(minBound.Y, pos.Y - size.Y/2),
            math.min(minBound.Z, pos.Z - size.Z/2)
        )
        
        maxBound = Vector3.new(
            math.max(maxBound.X, pos.X + size.X/2),
            math.max(maxBound.Y, pos.Y + size.Y/2),
            math.max(maxBound.Z, pos.Z + size.Z/2)
        )
    end
    
    -- If it's a single part
    if model:IsA("BasePart") then
        processPart(model)
    else
        -- Process all descendant parts
        for _, part in pairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                processPart(part)
            end
        end
    end
    
    if not hasParts then
        return nil, nil
    end
    
    return minBound, maxBound
end

-- Create a hitbox for a model
local function createHitbox(model, tileType, showDebug)
    local transparency = showDebug and 0.8 or 1.0
    
    -- Check for existing hitbox
    local existingHitbox = model:FindFirstChild("Hitbox")
    if existingHitbox then
        existingHitbox:Destroy()
    end
    
    -- Create new hitbox
    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Transparency = transparency
    hitbox.CanCollide = true
    hitbox.Anchored = true
    hitbox.CastShadow = false
    hitbox.Material = Enum.Material.SmoothPlastic
    hitbox.Color = Color3.fromRGB(0, 162, 255)
    
    -- Size and position
    local minBound, maxBound = calculateModelBounds(model)
    if not minBound then
        warn("   ⚠️ No parts found in model: " .. model.Name)
        return nil
    end
    
    -- Calculate dimensions
    local size = maxBound - minBound
    local position = minBound + size/2
    
    -- Ensure minimum size
    local minSize = Vector3.new(4, 2, 4)
    size = Vector3.new(
        math.max(size.X, minSize.X),
        math.max(size.Y, minSize.Y),
        math.max(size.Z, minSize.Z)
    )
    
    -- Add margins
    local margin = Vector3.new(2, 1, 2)
    hitbox.Size = size + margin
    
    -- Position with slight offset
    local offset = Vector3.new(0, -0.5, 0)
    hitbox.CFrame = CFrame.new(position) + offset
    
    -- Set attributes
    hitbox:SetAttribute("TileType", tileType)
    hitbox:SetAttribute("HitboxGenerated", true)
    
    -- Create buy prompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "BuyPrompt"
    prompt.ActionText = "Buy"
    prompt.ObjectText = model:GetAttribute("Description") or model.Name
    prompt.MaxActivationDistance = 10
    prompt.Parent = hitbox
    
    -- Parent to model
    hitbox.Parent = model
    
    return hitbox
end

-- Detect which floor a model is on
local function detectFloor(model)
    local position
    if model:IsA("Model") and model.PrimaryPart then
        position = model.PrimaryPart.Position
    elseif model:IsA("BasePart") then
        position = model.Position
    else
        local minBound, maxBound = calculateModelBounds(model)
        if minBound then
            position = minBound + (maxBound - minBound)/2
        else
            return 1 -- Default to ground floor
        end
    end
    
    local FLOOR_HEIGHT = 20 -- Approximate height between floors
    local GROUND_LEVEL = 0  -- Approximate Y position of ground floor
    
    local relativeHeight = position.Y - GROUND_LEVEL
    local floorNumber = math.floor(relativeHeight / FLOOR_HEIGHT) + 1
    
    return math.clamp(floorNumber, 1, 6)
end

-- Detect category based on model name
local function detectCategory(model)
    local name = model.Name:lower()
    
    -- Category keywords
    local categories = {
        STRUCTURE = {"wall", "floor", "ceiling", "door", "window", "stairs"},
        CARDIO = {"treadmill", "bike", "bicycle", "elliptical", "rowing"},
        STRENGTH = {"bench", "press", "rack", "dumbbell", "barbell", "weight"},
        AMENITIES = {"water", "fountain", "locker", "towel", "shower"},
        SPECIALTY = {"sauna", "pool", "spa", "basketball", "court"},
        STAFF = {"desk", "reception", "office", "trainer", "staff"}
    }
    
    for category, keywords in pairs(categories) do
        for _, keyword in ipairs(keywords) do
            if string.find(name, keyword) then
                return category
            end
        end
    end
    
    return "STRUCTURE" -- Default
end

--------------------------------
-- AUTOMATION FUNCTIONS
--------------------------------

-- Create hitboxes for all models in a folder
local function generateHitboxes(folder, showDebug)
    print("\n== GENERATING HITBOXES ==")
    local stats = {created = 0, skipped = 0, errors = 0}
    
    -- Find models with TileType attribute
    for _, model in ipairs(folder:GetDescendants()) do
        if (model:IsA("Model") or model:IsA("BasePart")) then
            local tileType = model:GetAttribute("TileType")
            
            if tileType then
                local hitbox = createHitbox(model, tileType, showDebug)
                if hitbox then
                    print("   ✓ Created hitbox for: " .. model.Name)
                    stats.created += 1
                else
                    stats.errors += 1
                end
            end
        end
    end
    
    print("\n✓ Created " .. stats.created .. " hitboxes")
    if stats.errors > 0 then
        warn("⚠️ " .. stats.errors .. " errors occurred")
    end
    
    return stats
end

-- Setup attributes for models in a folder
local function setupAttributes(folder)
    print("\n== SETTING UP ATTRIBUTES ==")
    local stats = {updated = 0, skipped = 0}
    
    for _, model in ipairs(folder:GetDescendants()) do
        -- Skip non-models and items that already have TileType
        if not (model:IsA("Model") or model:IsA("BasePart")) or model:GetAttribute("TileType") then
            continue
        end
        
        -- Skip tiny objects or invisible objects
        local minBound, maxBound = calculateModelBounds(model)
        if not minBound then
            continue
        end
        
        -- Generate clean name for TileType
        local tileType = model.Name:gsub("%s+", ""):gsub("[^%w]", "")
        if tileType:match("^%d") then
            tileType = "Tile" .. tileType
        end
        
        -- Detect floor and category
        local floor = detectFloor(model)
        local category = detectCategory(model)
        
        -- Set attributes
        model:SetAttribute("TileType", tileType)
        model:SetAttribute("Floor", floor)
        model:SetAttribute("Category", category)
        model:SetAttribute("ModelName", model.Name)
        model:SetAttribute("Description", model.Name)
        model:SetAttribute("BuildOrder", 100 * floor)
        
        -- Economy values (simple estimates)
        local basePrice = 100 * floor
        local incomeBonus = math.floor(basePrice / 25)
        model:SetAttribute("Price", basePrice)
        model:SetAttribute("IncomeBonus", incomeBonus)
        
        print("   ✓ Set attributes for: " .. model.Name)
        stats.updated += 1
    end
    
    print("\n✓ Set up attributes for " .. stats.updated .. " models")
    return stats
end

-- Main automation function
local function automateGym(options)
    options = options or {}
    local showDebug = options.showDebug ~= false -- Default to true
    
    print("\n===== GYM TYCOON AUTOMATION =====")
    print("Starting automation process...")
    
    -- Find the main gym folder
    local gymFolder = nil
    local candidates = {"GymParts", "Gym", "Tycoon", "GymTycoon", "Template"}
    
    for _, name in ipairs(candidates) do
        local folder = workspace:FindFirstChild(name)
        if folder then
            gymFolder = folder
            print("✓ Found gym folder: " .. folder.Name)
            break
        end
    end
    
    if not gymFolder then
        warn("❌ Could not find gym folder in workspace!")
        warn("   Please rename your main gym folder to one of: ", table.concat(candidates, ", "))
        return nil
    end
    
    -- Run automation steps
    local stats = {
        attributes = 0,
        hitboxes = 0
    }
    
    -- Step 1: Setup attributes
    local attrStats = setupAttributes(gymFolder)
    stats.attributes = attrStats.updated
    
    -- Step 2: Generate hitboxes
    local hitboxStats = generateHitboxes(gymFolder, showDebug)
    stats.hitboxes = hitboxStats.created
    
    print("\n===== AUTOMATION COMPLETE =====")
    print("✓ Models with attributes: " .. stats.attributes)
    print("✓ Hitboxes created: " .. stats.hitboxes)
    print("\nYou can now buy tiles by walking up to them and pressing E.")
    
    return stats
end

-- Register global function
_G.AutomateGym = automateGym
_G.GenerateGymHitboxes = function() return generateHitboxes(workspace, true) end
_G.SetupGymAttributes = function() return setupAttributes(workspace) end

print("✓ Automation tools initialized!")
print("✓ Run _G.AutomateGym() in the Command Bar to start")
print("✓ Additional commands: _G.GenerateGymHitboxes(), _G.SetupGymAttributes()")

-- Return the module
return {
    AutomateGym = automateGym,
    GenerateHitboxes = generateHitboxes,
    SetupAttributes = setupAttributes
}