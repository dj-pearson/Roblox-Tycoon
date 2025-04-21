--[[
    GymAutomation.server.luau
    
    IMPORTANT: Put this script directly in ServerScriptService (not in any subfolder)
    
    Simple standalone automation script for Gym Tycoon.
    This script will automatically run when placed in ServerScriptService and will register
    global functions that can be called from the Command Bar.
    
    Created: April 20, 2025
]]

-- Services
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local workspace = game:GetService("Workspace")

-- Only run in Studio
if not RunService:IsStudio() then
    return
end

print("\n✅ GYM TYCOON AUTOMATION LOADED")
print("Run _G.AutomateGym() in the Command Bar")

--------------------------------
-- UTILITY FUNCTIONS
--------------------------------

-- Calculate bounds of a model (min/max in each dimension)
local function calculateModelBounds(model)
    local minBound = Vector3.new(math.huge, math.huge, math.huge)
    local maxBound = Vector3.new(-math.huge, -math.huge, -math.huge)
    local hasParts = false
    
    -- For single parts
    if model:IsA("BasePart") then
        local size = model.Size
        local pos = model.Position
        
        minBound = Vector3.new(
            pos.X - size.X/2,
            pos.Y - size.Y/2,
            pos.Z - size.Z/2
        )
        
        maxBound = Vector3.new(
            pos.X + size.X/2,
            pos.Y + size.Y/2,
            pos.Z + size.Z/2
        )
        
        hasParts = true
    else
        -- Process all descendant parts
        for _, part in pairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
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
    -- Try to get from existing attribute
    if model:GetAttribute("Floor") then
        return model:GetAttribute("Floor")
    end
    
    -- Determine position
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
    -- Try to get from existing attribute
    if model:GetAttribute("Category") then
        return model:GetAttribute("Category")
    end
    
    local name = model.Name:lower()
    
    -- Category keywords
    local categories = {
        STRUCTURE = {"wall", "floor", "ceiling", "door", "window", "stairs", "foundation"},
        CARDIO = {"treadmill", "bike", "bicycle", "elliptical", "rowing", "cardio"},
        STRENGTH = {"bench", "press", "rack", "dumbbell", "barbell", "weight", "strength"},
        AMENITIES = {"water", "fountain", "locker", "towel", "shower", "amenity"},
        SPECIALTY = {"sauna", "pool", "spa", "basketball", "court", "specialty"},
        STAFF = {"desk", "reception", "office", "trainer", "staff"}
    }
    
    for category, keywords in pairs(categories) do
        for _, keyword in ipairs(keywords) do
            if string.find(name, keyword) then
                return category
            end
        end
    end
    
    -- Check folder name for context
    local parent = model.Parent
    if parent then
        local parentName = parent.Name:lower()
        for category, keywords in pairs(categories) do
            for _, keyword in ipairs(keywords) do
                if string.find(parentName, keyword) then
                    return category
                end
            end
        end
    end
    
    return "STRUCTURE" -- Default
end

--------------------------------
-- AUTOMATION FUNCTIONS
--------------------------------

-- Create hitboxes for all models in a folder
local function generateHitboxes(folder, options)
    options = options or {}
    local showDebug = options.showDebug ~= false -- Default to true
    
    print("\n== GENERATING HITBOXES ==")
    local stats = {created = 0, skipped = 0, errors = 0}
    
    -- Process models
    local function processModel(model)
        if not (model:IsA("Model") or model:IsA("BasePart")) then
            return
        end
        
        -- Get or create TileType
        local tileType = model:GetAttribute("TileType")
        if not tileType and options.autoSetAttributes then
            -- Generate clean name for TileType
            tileType = model.Name:gsub("%s+", ""):gsub("[^%w]", "")
            if tileType:match("^%d") then
                tileType = "Tile" .. tileType
            end
            model:SetAttribute("TileType", tileType)
        end
        
        if tileType then
            local hitbox = createHitbox(model, tileType, showDebug)
            if hitbox then
                print("   ✓ Created hitbox for: " .. model.Name)
                stats.created += 1
            else
                stats.errors += 1
            end
        else
            stats.skipped += 1
        end
    end
    
    -- Process through the folder
    for _, child in ipairs(folder:GetDescendants()) do
        processModel(child)
    end
    
    print("\n✓ Created " .. stats.created .. " hitboxes")
    print("  Skipped " .. stats.skipped .. " models (no TileType)")
    if stats.errors > 0 then
        warn("⚠️ " .. stats.errors .. " errors occurred")
    end
    
    return stats
end

-- Setup attributes for models in a folder
local function setupAttributes(folder, options)
    options = options or {}
    
    print("\n== SETTING UP ATTRIBUTES ==")
    local stats = {updated = 0, skipped = 0}
    
    -- Process models in order of floor
    local floorModels = {}
    
    for _, model in ipairs(folder:GetDescendants()) do
        -- Skip non-models
        if not (model:IsA("Model") or model:IsA("BasePart")) then
            continue
        end
        
        -- Skip items that already have TileType unless overriding
        if model:GetAttribute("TileType") and not options.override then
            stats.skipped += 1
            continue
        end
        
        -- Skip tiny objects or invisible objects
        local minBound, maxBound = calculateModelBounds(model)
        if not minBound then
            continue
        end
        
        -- Detect floor
        local floor = detectFloor(model)
        
        -- Add to sorted list
        if not floorModels[floor] then
            floorModels[floor] = {}
        end
        
        table.insert(floorModels[floor], model)
    end
    
    -- Process each floor in order
    local nextBuildOrder = 1
    for floor = 1, 6 do
        if floorModels[floor] then
            print("  Processing Floor " .. floor .. ":")
            
            for i, model in ipairs(floorModels[floor]) do
                -- Generate clean name for TileType
                local tileType = model.Name:gsub("%s+", ""):gsub("[^%w]", "")
                if tileType:match("^%d") then
                    tileType = "Tile" .. tileType
                end
                
                -- Ensure uniqueness
                local count = 1
                local baseTileType = tileType
                while true do
                    local exists = false
                    for checkFloor = 1, floor do
                        if floorModels[checkFloor] then
                            for _, checkModel in ipairs(floorModels[checkFloor]) do
                                if checkModel ~= model and checkModel:GetAttribute("TileType") == tileType then
                                    exists = true
                                    break
                                end
                            end
                        end
                        if exists then break end
                    end
                    
                    if not exists then
                        break
                    end
                    
                    count += 1
                    tileType = baseTileType .. tostring(count)
                end
                
                -- Detect category
                local category = detectCategory(model)
                
                -- Set attributes
                model:SetAttribute("TileType", tileType)
                model:SetAttribute("Floor", floor)
                model:SetAttribute("Category", category)
                model:SetAttribute("ModelName", model.Name)
                model:SetAttribute("Description", model.Name)
                model:SetAttribute("BuildOrder", nextBuildOrder)
                
                -- Economy values (based on floor and category)
                local basePrice = 100 * floor
                if category == "CARDIO" then basePrice *= 1.25 end
                if category == "STRENGTH" then basePrice *= 1.5 end
                if category == "SPECIALTY" then basePrice *= 2.0 end
                
                local incomeBonus = math.floor(basePrice / 25)
                model:SetAttribute("Price", basePrice)
                model:SetAttribute("IncomeBonus", incomeBonus)
                
                print("   ✓ Set attributes for: " .. model.Name)
                stats.updated += 1
                
                nextBuildOrder += 5
            end
        end
    end
    
    print("\n✓ Set up attributes for " .. stats.updated .. " models")
    print("  Skipped " .. stats.skipped .. " models (already had attributes)")
    return stats
end

-- Main automation function
local function automateGym(options)
    options = options or {}
    local showDebug = options.showDebug ~= false -- Default to true
    local override = options.override == true -- Default to false
    
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
    local attrStats = setupAttributes(gymFolder, {override = override})
    stats.attributes = attrStats.updated
    
    -- Step 2: Generate hitboxes
    local hitboxStats = generateHitboxes(gymFolder, {showDebug = showDebug})
    stats.hitboxes = hitboxStats.created
    
    print("\n===== AUTOMATION COMPLETE =====")
    print("✓ Models with attributes: " .. stats.attributes)
    print("✓ Hitboxes created: " .. stats.hitboxes)
    print("\nYou can now buy tiles by walking up to them and pressing E.")
    
    return stats
end

-- Register global functions
_G.AutomateGym = automateGym
_G.GenerateHitboxes = function(options) return generateHitboxes(workspace, options) end
_G.SetupAttributes = function(options) return setupAttributes(workspace, options) end

-- Additional convenience functions
_G.ShowHitboxes = function()
    for _, hitbox in ipairs(workspace:GetDescendants()) do
        if hitbox.Name == "Hitbox" and hitbox:IsA("BasePart") then
            hitbox.Transparency = 0.8
        end
    end
    print("✓ Hitboxes are now visible")
    return true
end

_G.HideHitboxes = function()
    for _, hitbox in ipairs(workspace:GetDescendants()) do
        if hitbox.Name == "Hitbox" and hitbox:IsA("BasePart") then
            hitbox.Transparency = 1.0
        end
    end
    print("✓ Hitboxes are now invisible")
    return true
end

print("You can use these commands:")
print("- _G.AutomateGym() - Do everything")
print("- _G.GenerateHitboxes() - Just create hitboxes")
print("- _G.SetupAttributes() - Just set up attributes")
print("- _G.ShowHitboxes() - Make hitboxes visible")
print("- _G.HideHitboxes() - Make hitboxes invisible")