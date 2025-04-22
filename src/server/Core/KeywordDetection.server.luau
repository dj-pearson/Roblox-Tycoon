--lua
--[[
    KeywordDetection.server.luau

    Module script for detecting categories based on keywords.

    Created: May 2024
]]

local KeywordDetection = {}

-- Category keywords
local CATEGORY_KEYWORDS = {
    STRUCTURE = {"wall", "floor", "ceiling", "door", "window", "stairs", "foundation", "pillar", "beam", "support", "column"},
    CARDIO = {"treadmill", "bike", "bicycle", "elliptical", "rowing", "cardio", "run", "jog", "aerobic"},
    STRENGTH = {"bench", "press", "rack", "dumbbell", "barbell", "weight", "strength", "power", "lift"},
    AMENITIES = {"water", "fountain", "locker", "towel", "shower", "amenity", "vending", "counter", "desk"},
    SPECIALTY = {"sauna", "pool", "spa", "basketball", "court", "specialty", "yoga", "pilates", "stretch"},
    STAFF = {"desk", "reception", "office", "trainer", "staff", "employee", "manager", "admin"}
}

-- Detect category based on model name and other attributes
function KeywordDetection.DetectCategory(model)
    if not model then return "STRUCTURE" end
    
    -- Check if model already has a Category attribute
    local existingCategory = model:GetAttribute("Category")
    if existingCategory then
        return existingCategory
    end
    
    local modelName = model.Name:lower()
    
    -- Check for matches in category keywords
    for category, keywords in pairs(CATEGORY_KEYWORDS) do
        for _, keyword in ipairs(keywords) do
            if modelName:find(keyword) then
                return category
            end
        end
    end
    
    -- Check parent folder for context
    local parent = model.Parent
    if parent then
        local parentName = parent.Name:lower()
        for category, keywords in pairs(CATEGORY_KEYWORDS) do
            for _, keyword in ipairs(keywords) do
                if parentName:find(keyword) then
                    return category
                end
            end
        end
    end
    
    -- Default to STRUCTURE for unclassified models
    return "STRUCTURE"
end

return KeywordDetection