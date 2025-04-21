--[[
    UpgradePathDetector.server.luau
    
    Automatically detects and establishes upgrade paths between related equipment
    based on naming conventions and existing attributes.
    
    Features:
    - Detects upgrade paths using model naming patterns (e.g., Treadmill_1, Treadmill_2)
    - Identifies equipment variants and relationships
    - Automatically sets UpgradesTo/UpgradesFrom attributes
    - Creates a graph of upgrade relationships for visualization
    
    Part of the enhanced gym automation system.
    
    Author: Created April 21, 2025
]]

local CollectionService = game:GetService("CollectionService")

local UpgradePathDetector = {
    -- Constants for upgrade path detection
    NAMING_PATTERNS = {
        -- Pattern: BaseName_Number (e.g., "Treadmill_1")
        NUMBERED = "^(.+)_(%d+)$",
        
        -- Pattern: BaseName_Mk/MkNumber (e.g., "BenchPress_Mk2")
        MK_VARIANT = "^(.+)_[Mm][Kk](%d+)$",
        
        -- Pattern: BaseName_V/VNumber (e.g., "StairClimber_V2")
        V_VARIANT = "^(.+)_[Vv](%d+)$",
        
        -- Pattern: BaseName_Tier (e.g., "Weights_Basic", "Weights_Advanced", "Weights_Premium")
        TIER_VARIANT = "^(.+)_(%a+)$"
    },
    
    -- Ordering of text-based tiers (for TIER_VARIANT pattern)
    TIER_ORDER = {
        Basic = 1,
        Standard = 2,
        Advanced = 3,
        Premium = 4,
        Elite = 5,
        Professional = 6,
        Ultimate = 7
    }
}

-- Function to extract base name and tier from a model name
function UpgradePathDetector:ExtractBaseNameAndTier(modelName)
    -- Try each pattern to see if it matches
    
    -- Check for numbered pattern (e.g., "Treadmill_1")
    local baseName, numberStr = string.match(modelName, self.NAMING_PATTERNS.NUMBERED)
    if baseName and numberStr then
        return baseName, tonumber(numberStr), "number"
    end
    
    -- Check for Mk variant pattern (e.g., "BenchPress_Mk2")
    baseName, numberStr = string.match(modelName, self.NAMING_PATTERNS.MK_VARIANT)
    if baseName and numberStr then
        return baseName, tonumber(numberStr), "mk"
    end
    
    -- Check for V variant pattern (e.g., "StairClimber_V2")
    baseName, numberStr = string.match(modelName, self.NAMING_PATTERNS.V_VARIANT)
    if baseName and numberStr then
        return baseName, tonumber(numberStr), "v"
    end
    
    -- Check for tier variant pattern (e.g., "Weights_Basic")
    baseName, local tierName = string.match(modelName, self.NAMING_PATTERNS.TIER_VARIANT)
    if baseName and tierName and self.TIER_ORDER[tierName] then
        return baseName, self.TIER_ORDER[tierName], "tier", tierName
    end
    
    -- No recognized pattern
    return nil, nil, nil
end

-- Function to build upgrade path groups
function UpgradePathDetector:BuildUpgradeGroups(models)
    local upgradeGroups = {}
    
    -- First pass: group models by base name
    for _, model in ipairs(models) do
        if not model:IsA("Model") then
            continue
        end
        
        local modelName = model.Name
        local baseName, tier, tierType, originalTierName = self:ExtractBaseNameAndTier(modelName)
        
        -- If we could extract a pattern, add it to the appropriate group
        if baseName and tier then
            if not upgradeGroups[baseName] then
                upgradeGroups[baseName] = {
                    models = {},
                    tierType = tierType
                }
            end
            
            -- Store model along with its tier information
            table.insert(upgradeGroups[baseName].models, {
                model = model,
                name = modelName,
                tier = tier,
                originalTierName = originalTierName
            })
        end
    end
    
    -- Second pass: sort models within each group by tier
    for baseName, group in pairs(upgradeGroups) do
        table.sort(group.models, function(a, b)
            return a.tier < b.tier
        end)
    end
    
    return upgradeGroups
end

-- Function to establish upgrade relationships between models in groups
function UpgradePathDetector:EstablishUpgradeRelationships(upgradeGroups, options)
    options = options or {}
    local applyAttributes = options.applyAttributes or false
    
    local upgradePaths = {}
    local stats = {
        totalPaths = 0,
        groupsFound = 0,
        attributesApplied = 0
    }
    
    -- Process each upgrade group
    for baseName, group in pairs(upgradeGroups) do
        if #group.models > 1 then
            stats.groupsFound = stats.groupsFound + 1
            local models = group.models
            local upgradePath = {}
            
            -- Create the upgrade path relationships
            for i = 1, #models do
                local currentModel = models[i].model
                local currentModelName = models[i].name
                
                if i < #models then
                    local nextModel = models[i+1].model
                    local nextModelName = models[i+1].name
                    
                    -- Add to upgrade paths
                    upgradePaths[currentModelName] = {
                        next = nextModelName
                    }
                    
                    upgradePaths[nextModelName] = upgradePaths[nextModelName] or {}
                    upgradePaths[nextModelName].previous = currentModelName
                    
                    -- Apply attributes if requested
                    if applyAttributes then
                        if not currentModel:GetAttribute("UpgradesTo") then
                            currentModel:SetAttribute("UpgradesTo", nextModelName)
                            stats.attributesApplied = stats.attributesApplied + 1
                        end
                        
                        if not nextModel:GetAttribute("UpgradesFrom") then
                            nextModel:SetAttribute("UpgradesFrom", currentModelName)
                            stats.attributesApplied = stats.attributesApplied + 1
                        end
                    end
                    
                    stats.totalPaths = stats.totalPaths + 1
                    
                    -- Add to local upgrade path for this group
                    table.insert(upgradePath, {
                        from = currentModelName,
                        to = nextModelName
                    })
                end
            end
            
            -- Store the complete upgrade path for this group
            upgradeGroups[baseName].upgradePath = upgradePath
        end
    end
    
    return upgradePaths, stats
end

-- Function to tag models with upgrade-related tags
function UpgradePathDetector:ApplyUpgradeTags(upgradeGroups)
    local tagStats = {}
    
    for baseName, group in pairs(upgradeGroups) do
        local models = group.models
        
        -- Tag first model in series as base tier
        if #models > 0 then
            local baseModel = models[1].model
            local baseTag = "BaseTier"
            
            if not CollectionService:HasTag(baseModel, baseTag) then
                CollectionService:AddTag(baseModel, baseTag)
                tagStats[baseTag] = (tagStats[baseTag] or 0) + 1
            end
            
            -- Tag highest tier model as max tier
            local maxModel = models[#models].model
            local maxTag = "MaxTier"
            
            if not CollectionService:HasTag(maxModel, maxTag) then
                CollectionService:AddTag(maxModel, maxTag)
                tagStats[maxTag] = (tagStats[maxTag] or 0) + 1
            end
            
            -- Tag all models with their equipment family
            local familyTag = "Family_" .. baseName
            
            for _, modelInfo in ipairs(models) do
                if not CollectionService:HasTag(modelInfo.model, familyTag) then
                    CollectionService:AddTag(modelInfo.model, familyTag)
                    tagStats[familyTag] = (tagStats[familyTag] or 0) + 1
                end
                
                -- Tag with tier level
                local tierTag = "Tier_" .. modelInfo.tier
                if not CollectionService:HasTag(modelInfo.model, tierTag) then
                    CollectionService:AddTag(modelInfo.model, tierTag)
                    tagStats[tierTag] = (tagStats[tierTag] or 0) + 1
                end
            end
        end
    end
    
    return tagStats
end

-- Main function to detect upgrade paths in a container
function UpgradePathDetector:DetectUpgradePaths(container, options)
    options = options or {}
    
    -- Find all models in the container
    local models = {}
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("Model") then
            table.insert(models, child)
        end
    end
    
    -- Build upgrade groups
    local upgradeGroups = self:BuildUpgradeGroups(models)
    
    -- Establish upgrade relationships
    local upgradePaths, stats = self:EstablishUpgradeRelationships(upgradeGroups, options)
    
    -- Apply tags if requested
    local tagStats = {}
    if options.applyTags then
        tagStats = self:ApplyUpgradeTags(upgradeGroups)
    end
    
    -- Return the results
    return {
        upgradePaths = upgradePaths,
        upgradeGroups = upgradeGroups,
        stats = stats,
        tagStats = tagStats
    }
end

-- Function to generate a visual representation of the upgrade paths
function UpgradePathDetector:VisualizeUpgradePaths(container, options)
    options = options or {}
    
    -- First detect all upgrade paths
    local results = self:DetectUpgradePaths(container, {
        applyAttributes = options.applyAttributes or false,
        applyTags = options.applyTags or false
    })
    
    if options.debug then
        -- Print summary
        print("\n=== UPGRADE PATH DETECTION RESULTS ===")
        print("Groups found: " .. results.stats.groupsFound)
        print("Total upgrade paths: " .. results.stats.totalPaths)
        print("Attributes applied: " .. results.stats.attributesApplied)
        
        -- Print each group
        for baseName, group in pairs(results.upgradeGroups) do
            if #group.models > 0 then
                print("\nGroup: " .. baseName .. " (" .. group.tierType .. " variant)")
                
                local pathString = ""
                for i, modelInfo in ipairs(group.models) do
                    pathString = pathString .. modelInfo.name
                    if i < #group.models then
                        pathString = pathString .. " -> "
                    end
                end
                
                print(pathString)
            end
        end
    end
    
    return results
end

-- Function to generate ModuleScript with upgrade paths data
function UpgradePathDetector:GenerateUpgradePathsModule(container, options)
    options = options or {}
    
    -- Detect upgrade paths
    local results = self:DetectUpgradePaths(container, {
        applyAttributes = options.applyAttributes or false,
        applyTags = options.applyTags or false
    })
    
    -- Generate module code
    local moduleCode = "--[[\n"
    moduleCode = moduleCode .. "    UpgradePathsData.lua\n"
    moduleCode = moduleCode .. "    Auto-generated on " .. os.date() .. "\n"
    moduleCode = moduleCode .. "    Contains automatically detected upgrade paths for gym equipment\n"
    moduleCode = moduleCode .. "]]\n\n"
    
    moduleCode = moduleCode .. "return {\n"
    
    -- Add paths data
    for modelName, pathInfo in pairs(results.upgradePaths) do
        moduleCode = moduleCode .. "    [\"" .. modelName .. "\"] = {\n"
        
        if pathInfo.next then
            moduleCode = moduleCode .. "        next = \"" .. pathInfo.next .. "\",\n"
        end
        
        if pathInfo.previous then
            moduleCode = moduleCode .. "        previous = \"" .. pathInfo.previous .. "\",\n"
        end
        
        moduleCode = moduleCode .. "    },\n"
    end
    
    moduleCode = moduleCode .. "}"
    
    -- Create or update the module script
    local moduleScript = nil
    local moduleParent = game:GetService("ReplicatedStorage")
    local moduleName = options.moduleName or "UpgradePathsData"
    
    moduleScript = moduleParent:FindFirstChild(moduleName)
    
    if not moduleScript then
        moduleScript = Instance.new("ModuleScript")
        moduleScript.Name = moduleName
        moduleScript.Parent = moduleParent
    end
    
    moduleScript.Source = moduleCode
    
    return moduleScript
end

return UpgradePathDetector