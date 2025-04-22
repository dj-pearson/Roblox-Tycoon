--[[
    TaggingSystem.server.luau
    
    Advanced CollectionService tagging system for gym equipment and structures.
    This system automatically applies tags based on object attributes and characteristics,
    enabling more efficient queries during gameplay.
    
    Features:
    - Tag models by category (CardioEquipment, StrengthEquipment, etc.)
    - Tag models by floor location
    - Tag interactive elements
    - Support for custom tag mappings
    - Query optimization for efficient object finding
    
    Part of the enhanced gym automation system.
    
    Author: Created April 21, 2025
]]

local CollectionService = game:GetService("CollectionService")

local TaggingSystem = {
    -- Default tag mappings based on model attributes
    TAG_MAPPINGS = {
        -- Category-based tags
        CATEGORY = {
            CARDIO = "CardioEquipment",
            STRENGTH = "StrengthEquipment",
            AMENITIES = "AmenityEquipment",
            SPECIALTY = "SpecialtyEquipment",
            STRUCTURE = "StructureElement",
            DECOR = "DecorElement"
        },
        
        -- Interaction type tags
        INTERACTION = {
            USABLE = "InteractiveEquipment",
            UPGRADABLE = "UpgradableEquipment",
            MAINTENANCE = "RequiresMaintenance"
        },
        
        -- Special property tags
        PROPERTIES = {
            REVENUE = "GeneratesRevenue",
            SATISFACTION = "AffectsSatisfaction",
            CLEANLINESS = "AffectsCleanliness"
        }
    },
    
    -- Default tag prefixes
    TAG_PREFIXES = {
        FLOOR = "Floor_",
        ROOM = "Room_",
        FAMILY = "Family_",
        TIER = "Tier_"
    }
}

-- Function to tag models by category attribute
function TaggingSystem:TagModelsByCategory(container, options)
    options = options or {}
    local stats = { applied = 0, models = 0 }
    local tagMapping = options.categoryMapping or self.TAG_MAPPINGS.CATEGORY
    
    for _, model in ipairs(container:GetDescendants()) do
        if model:IsA("Model") then
            stats.models = stats.models + 1
            local category = model:GetAttribute("Category")
            
            if category then
                local tag = tagMapping[category]
                
                -- If we have a mapping for this category, apply the tag
                if tag then
                    if not CollectionService:HasTag(model, tag) then
                        CollectionService:AddTag(model, tag)
                        stats.applied = stats.applied + 1
                    end
                end
                
                -- Also apply the raw category as a tag if requested
                if options.rawCategoryAsTags and not CollectionService:HasTag(model, category) then
                    CollectionService:AddTag(model, category)
                    stats.applied = stats.applied + 1
                end
            end
        end
    end
    
    return stats
end

-- Function to tag models by floor attribute
function TaggingSystem:TagModelsByFloor(container, options)
    options = options or {}
    local stats = { applied = 0, models = 0 }
    local floorPrefix = options.floorPrefix or self.TAG_PREFIXES.FLOOR
    
    for _, model in ipairs(container:GetDescendants()) do
        if model:IsA("Model") or model:IsA("BasePart") then
            stats.models = stats.models + 1
            local floor = model:GetAttribute("Floor")
            
            if floor then
                local tag = floorPrefix .. floor
                
                if not CollectionService:HasTag(model, tag) then
                    CollectionService:AddTag(model, tag)
                    stats.applied = stats.applied + 1
                end
            end
        end
    end
    
    return stats
end

-- Function to tag models by room attribute
function TaggingSystem:TagModelsByRoom(container, options)
    options = options or {}
    local stats = { applied = 0, models = 0 }
    local roomPrefix = options.roomPrefix or self.TAG_PREFIXES.ROOM
    
    for _, model in ipairs(container:GetDescendants()) do
        if model:IsA("Model") or model:IsA("BasePart") then
            stats.models = stats.models + 1
            local room = model:GetAttribute("Room")
            
            if room then
                local tag = roomPrefix .. room
                
                if not CollectionService:HasTag(model, tag) then
                    CollectionService:AddTag(model, tag)
                    stats.applied = stats.applied + 1
                end
            end
        end
    end
    
    return stats
end

-- Function to tag models with special property tags
function TaggingSystem:TagModelsByProperties(container, options)
    options = options or {}
    local stats = { applied = 0, models = 0 }
    local propertyMapping = options.propertyMapping or self.TAG_MAPPINGS.PROPERTIES
    
    for _, model in ipairs(container:GetDescendants()) do
        if model:IsA("Model") then
            stats.models = stats.models + 1
            
            -- Check for revenue generation
            if model:GetAttribute("IncomeBoost") and model:GetAttribute("IncomeBoost") > 0 then
                local revenueTag = propertyMapping.REVENUE
                
                if revenueTag and not CollectionService:HasTag(model, revenueTag) then
                    CollectionService:AddTag(model, revenueTag)
                    stats.applied = stats.applied + 1
                end
            end
            
            -- Check for satisfaction impact
            if model:GetAttribute("SatisfactionImpact") and model:GetAttribute("SatisfactionImpact") ~= 0 then
                local satisfactionTag = propertyMapping.SATISFACTION
                
                if satisfactionTag and not CollectionService:HasTag(model, satisfactionTag) then
                    CollectionService:AddTag(model, satisfactionTag)
                    stats.applied = stats.applied + 1
                end
            end
            
            -- Check for cleanliness impact
            if model:GetAttribute("CleanlinessImpact") and model:GetAttribute("CleanlinessImpact") ~= 0 then
                local cleanlinessTag = propertyMapping.CLEANLINESS
                
                if cleanlinessTag and not CollectionService:HasTag(model, cleanlinessTag) then
                    CollectionService:AddTag(model, cleanlinessTag)
                    stats.applied = stats.applied + 1
                end
            end
        end
    end
    
    return stats
end

-- Function to tag interactive models
function TaggingSystem:TagInteractiveModels(container, options)
    options = options or {}
    local stats = { applied = 0, models = 0 }
    local interactionMapping = options.interactionMapping or self.TAG_MAPPINGS.INTERACTION
    
    for _, model in ipairs(container:GetDescendants()) do
        if model:IsA("Model") then
            stats.models = stats.models + 1
            
            -- Check if model is usable (has a UsableBy attribute)
            if model:GetAttribute("UsableBy") then
                local usableTag = interactionMapping.USABLE
                
                if usableTag and not CollectionService:HasTag(model, usableTag) then
                    CollectionService:AddTag(model, usableTag)
                    stats.applied = stats.applied + 1
                end
            end
            
            -- Check if model is upgradable (has UpgradesTo attribute)
            if model:GetAttribute("UpgradesTo") then
                local upgradeTag = interactionMapping.UPGRADABLE
                
                if upgradeTag and not CollectionService:HasTag(model, upgradeTag) then
                    CollectionService:AddTag(model, upgradeTag)
                    stats.applied = stats.applied + 1
                end
            end
            
            -- Check if model requires maintenance
            if model:GetAttribute("MaintenanceInterval") then
                local maintenanceTag = interactionMapping.MAINTENANCE
                
                if maintenanceTag and not CollectionService:HasTag(model, maintenanceTag) then
                    CollectionService:AddTag(model, maintenanceTag)
                    stats.applied = stats.applied + 1
                end
            end
        end
    end
    
    return stats
end

-- Function to tag models with custom tags based on attribute conditions
function TaggingSystem:ApplyCustomTags(container, customRules)
    if not customRules or type(customRules) ~= "table" then
        return { applied = 0, models = 0 }
    end
    
    local stats = { applied = 0, models = 0 }
    
    for _, model in ipairs(container:GetDescendants()) do
        if model:IsA("Model") or model:IsA("BasePart") then
            stats.models = stats.models + 1
            
            -- Check each custom rule
            for _, rule in ipairs(customRules) do
                local attributeName = rule.attribute
                local attributeValue = rule.value
                local tagToApply = rule.tag
                local compareFunc = rule.compare or function(a, b) return a == b end
                
                -- Get the attribute value
                local modelValue = model:GetAttribute(attributeName)
                
                -- Apply tag if the rule matches
                if modelValue ~= nil and compareFunc(modelValue, attributeValue) then
                    if not CollectionService:HasTag(model, tagToApply) then
                        CollectionService:AddTag(model, tagToApply)
                        stats.applied = stats.applied + 1
                    end
                end
            end
        end
    end
    
    return stats
end

-- Function to tag all hitboxes and interactive elements
function TaggingSystem:TagFunctionalElements(container)
    local stats = { applied = 0, models = 0 }
    
    -- Tag all hitboxes
    for _, part in ipairs(container:GetDescendants()) do
        if part:IsA("BasePart") and string.match(part.Name, "Hitbox") then
            stats.models = stats.models + 1
            
            if not CollectionService:HasTag(part, "BuyHitbox") then
                CollectionService:AddTag(part, "BuyHitbox")
                stats.applied = stats.applied + 1
            end
            
            -- Get tile type and tag with it
            local tileType = part:GetAttribute("TileType")
            if tileType and not CollectionService:HasTag(part, "Tile_" .. tileType) then
                CollectionService:AddTag(part, "Tile_" .. tileType)
                stats.applied = stats.applied + 1
            end
        end
    end
    
    -- Tag interactive parts
    for _, part in ipairs(container:GetDescendants()) do
        if (part:IsA("BasePart") or part:IsA("Model")) and part:GetAttribute("Interactive") then
            stats.models = stats.models + 1
            
            local interactionType = part:GetAttribute("InteractionType") or "Generic"
            local tag = "Interactive_" .. interactionType
            
            if not CollectionService:HasTag(part, tag) then
                CollectionService:AddTag(part, tag)
                stats.applied = stats.applied + 1
            end
        end
    end
    
    return stats
end

-- Main function to apply all relevant tags
function TaggingSystem:ApplyAllTags(container, options)
    options = options or {}
    
    local totalStats = {
        applied = 0,
        models = 0,
        byCategory = {},
        byFloor = {},
        byProperties = {},
        byInteraction = {},
        byCustom = {},
        byFunctional = {}
    }
    
    -- Apply category tags if not disabled
    if options.tagCategories ~= false then
        totalStats.byCategory = self:TagModelsByCategory(container, options)
        totalStats.applied = totalStats.applied + totalStats.byCategory.applied
    end
    
    -- Apply floor tags if not disabled
    if options.tagFloors ~= false then
        totalStats.byFloor = self:TagModelsByFloor(container, options)
        totalStats.applied = totalStats.applied + totalStats.byFloor.applied
    end
    
    -- Apply room tags if enabled
    if options.tagRooms then
        totalStats.byRoom = self:TagModelsByRoom(container, options)
        totalStats.applied = totalStats.applied + totalStats.byRoom.applied
    end
    
    -- Apply property tags if not disabled
    if options.tagProperties ~= false then
        totalStats.byProperties = self:TagModelsByProperties(container, options)
        totalStats.applied = totalStats.applied + totalStats.byProperties.applied
    end
    
    -- Apply interaction tags if not disabled
    if options.tagInteractions ~= false then
        totalStats.byInteraction = self:TagInteractiveModels(container, options)
        totalStats.applied = totalStats.applied + totalStats.byInteraction.applied
    end
    
    -- Apply custom tags if provided
    if options.customTags then
        totalStats.byCustom = self:ApplyCustomTags(container, options.customTags)
        totalStats.applied = totalStats.applied + totalStats.byCustom.applied
    end
    
    -- Apply functional element tags if not disabled
    if options.tagFunctional ~= false then
        totalStats.byFunctional = self:TagFunctionalElements(container)
        totalStats.applied = totalStats.applied + totalStats.byFunctional.applied
    end
    
    return totalStats
end

-- Function to print a summary of applied tags
function TaggingSystem:PrintTagSummary(container)
    print("\n=== COLLECTION SERVICE TAG SUMMARY ===")
    
    -- Get all unique tags in use
    local tagCounts = {}
    for _, instance in ipairs(container:GetDescendants()) do
        for _, tag in ipairs(CollectionService:GetTags(instance)) do
            tagCounts[tag] = (tagCounts[tag] or 0) + 1
        end
    end
    
    -- Group tags by prefix
    local tagsByPrefix = {}
    for tag, count in pairs(tagCounts) do
        local prefix = string.match(tag, "^([^_]+)_") or "Other"
        
        if not tagsByPrefix[prefix] then
            tagsByPrefix[prefix] = {}
        end
        
        tagsByPrefix[prefix][tag] = count
    end
    
    -- Print by category
    local totalTags = 0
    local totalTaggedInstances = 0
    
    for prefix, tags in pairs(tagsByPrefix) do
        print("\nCategory: " .. prefix)
        local categoryTotal = 0
        
        for tag, count in pairs(tags) do
            print("  " .. tag .. ": " .. count .. " instances")
            categoryTotal = categoryTotal + count
            totalTaggedInstances = totalTaggedInstances + count
        end
        
        print("  Total " .. prefix .. " tags: " .. categoryTotal)
        totalTags = totalTags + #tags
    end
    
    print("\nTotal unique tags: " .. totalTags)
    print("Total tag applications: " .. totalTaggedInstances)
end

-- Function to remove all tags from a container
function TaggingSystem:ClearAllTags(container)
    local count = 0
    
    for _, instance in ipairs(container:GetDescendants()) do
        local tags = CollectionService:GetTags(instance)
        
        for _, tag in ipairs(tags) do
            CollectionService:RemoveTag(instance, tag)
            count = count + 1
        end
    end
    
    return count
end

-- Function to find instances by tag combination
function TaggingSystem:FindByTags(container, tags, matchAll)
    matchAll = matchAll ~= false  -- Default to true
    local results = {}
    
    if type(tags) == "string" then
        tags = {tags}  -- Convert single tag to array
    end
    
    -- First get all instances with the first tag to narrow down search
    if #tags > 0 then
        local firstTagInstances = CollectionService:GetTagged(tags[1])
        
        for _, instance in ipairs(firstTagInstances) do
            -- Check if instance is in container
            local isInContainer = instance:IsDescendantOf(container)
            if not isInContainer then
                continue
            end
            
            -- For a single tag, we're done
            if #tags == 1 then
                table.insert(results, instance)
                continue
            end
            
            -- For multiple tags, check if all required tags are present
            local hasAllTags = true
            
            for i = 2, #tags do
                if not CollectionService:HasTag(instance, tags[i]) then
                    hasAllTags = false
                    break
                end
            end
            
            if hasAllTags == matchAll then
                table.insert(results, instance)
            end
        end
    end
    
    return results
end

return TaggingSystem