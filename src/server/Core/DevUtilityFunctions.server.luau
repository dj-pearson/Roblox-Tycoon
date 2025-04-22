--[[
    DevUtilityFunctions.server.luau
    
    Advanced developer utility functions for the Gym Tycoon project.
    These functions extend the core automation system with additional
    tools for specialized workflows and analysis.
    
    Author: Created April 21, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

-- Locate CoreRegistry to access our systems
local CoreRegistry = nil
local systemFolder = ServerScriptService:FindFirstChild("Systems") or ServerScriptService

for _, folder in pairs(systemFolder:GetDescendants()) do
    if folder:IsA("ModuleScript") and folder.Name == "CoreRegistry" then
        CoreRegistry = require(folder)
        break
    end
end

-- Get references to our modular systems from the registry
local ModelValidator = CoreRegistry and CoreRegistry:GetSystem("ModelValidator")
local TaggingSystem = CoreRegistry and CoreRegistry:GetSystem("TaggingSystem")
local UpgradePathDetector = CoreRegistry and CoreRegistry:GetSystem("UpgradePathDetector")
local BoundingBoxManager = CoreRegistry and CoreRegistry:GetSystem("BoundingBoxManager")
local EquipmentManager = CoreRegistry and CoreRegistry:GetSystem("EquipmentManager")
local FloorAttributeSetup = CoreRegistry and CoreRegistry:GetSystem("FloorAttributeSetup")

-- DevUtilityFunctions module
local DevUtilityFunctions = {}

-- Helper function to find tycoon from name or get default
function DevUtilityFunctions:FindTycoon(tycoonName)
    local tycoon
    
    if tycoonName then
        tycoon = Workspace:FindFirstChild(tycoonName)
        if not tycoon then
            warn("Tycoon not found: " .. tycoonName)
            return nil
        end
    else
        -- Find first gym tycoon
        local gymParts = {}
        for _, child in pairs(Workspace:GetChildren()) do
            if child.Name == "GymParts" or child.Name == "Tycoon" then
                table.insert(gymParts, child)
            end
        end
        
        if #gymParts > 0 then
            tycoon = gymParts[1]
        else
            warn("No gym tycoons found in workspace")
            return nil
        end
    end
    
    return tycoon
end

--[[
    BatchProcessModels

    Applies a custom processing function to all models in a tycoon.
    
    Parameters:
    - tycoonName (string, optional): Name of the tycoon to process
    - processingFunction (function): Function to apply to each model
      The function receives (model, options) as parameters and should return a result
    - options (table, optional): Options to pass to the processing function
    
    Returns: Table of results indexed by model name
]]
function DevUtilityFunctions:BatchProcessModels(tycoonName, processingFunction, options)
    if type(processingFunction) ~= "function" then
        warn("BatchProcessModels requires a processing function")
        return {}
    end
    
    local tycoon = self:FindTycoon(tycoonName)
    if not tycoon then return {} end
    
    options = options or {}
    local results = {}
    local count = 0
    
    -- Find all models in the tycoon
    for _, model in ipairs(tycoon:GetDescendants()) do
        if model:IsA("Model") then
            -- Apply the processing function and store result
            local result = processingFunction(model, options)
            results[model.Name] = result
            count = count + 1
        end
    end
    
    print("Processed " .. count .. " models in " .. tycoon.Name)
    return results
end

--[[
    GenerateModelStats

    Generates detailed statistics about models in a tycoon including
    part counts, memory usage, and other performance metrics.
    
    Parameters:
    - tycoonName (string, optional): Name of the tycoon to analyze
    - options (table, optional):
      - detailed (boolean): Whether to include detailed per-model stats
      - categoryBreakdown (boolean): Whether to break down stats by category
      - export (string): Export format - "print", "table", or "file"
    
    Returns: Table of statistics
]]
function DevUtilityFunctions:GenerateModelStats(tycoonName, options)
    local tycoon = self:FindTycoon(tycoonName)
    if not tycoon then return nil end
    
    options = options or {}
    options.detailed = options.detailed ~= false
    options.categoryBreakdown = options.categoryBreakdown ~= false
    options.export = options.export or "print"
    
    local stats = {
        totalModels = 0,
        totalParts = 0,
        totalTriangles = 0,
        estimatedMemory = 0,
        categories = {},
        modelDetails = {},
        averagePartsPerModel = 0,
        maxPartsInModel = 0,
        maxPartModel = "",
        scriptsCount = 0,
        uniqueTextureCount = 0,
        uniqueMaterialCount = 0
    }
    
    -- Material and texture tracking
    local uniqueMaterials = {}
    local uniqueTextures = {}
    
    -- Process each model
    for _, model in ipairs(tycoon:GetDescendants()) do
        if model:IsA("Model") then
            stats.totalModels = stats.totalModels + 1
            
            -- Get model category if available
            local category = model:GetAttribute("Category") or "Uncategorized"
            if not stats.categories[category] then
                stats.categories[category] = {
                    models = 0,
                    parts = 0,
                    triangles = 0,
                    estimatedMemory = 0
                }
            end
            stats.categories[category].models = stats.categories[category].models + 1
            
            -- Analyze parts in the model
            local modelStats = {
                name = model.Name,
                category = category,
                parts = 0,
                triangles = 0,
                estimatedMemory = 0,
                scripts = 0,
                serverScripts = 0,
                clientScripts = 0,
                unanchoredParts = 0,
                materialBreakdown = {}
            }
            
            for _, desc in ipairs(model:GetDescendants()) do
                -- Count scripts
                if desc:IsA("Script") or desc:IsA("ModuleScript") then
                    stats.scriptsCount = stats.scriptsCount + 1
                    modelStats.scripts = modelStats.scripts + 1
                    modelStats.serverScripts = modelStats.serverScripts + 1
                elseif desc:IsA("LocalScript") then
                    stats.scriptsCount = stats.scriptsCount + 1
                    modelStats.scripts = modelStats.scripts + 1
                    modelStats.clientScripts = modelStats.clientScripts + 1
                end
                
                -- Count and analyze parts
                if desc:IsA("BasePart") then
                    stats.totalParts = stats.totalParts + 1
                    modelStats.parts = modelStats.parts + 1
                    stats.categories[category].parts = stats.categories[category].parts + 1
                    
                    -- Count unanchored parts
                    if not desc.Anchored then
                        modelStats.unanchoredParts = modelStats.unanchoredParts + 1
                    end
                    
                    -- Track unique materials
                    if not uniqueMaterials[desc.Material.Name] then
                        uniqueMaterials[desc.Material.Name] = 0
                    end
                    uniqueMaterials[desc.Material.Name] = uniqueMaterials[desc.Material.Name] + 1
                    
                    -- Track material usage in model
                    if not modelStats.materialBreakdown[desc.Material.Name] then
                        modelStats.materialBreakdown[desc.Material.Name] = 0
                    end
                    modelStats.materialBreakdown[desc.Material.Name] = modelStats.materialBreakdown[desc.Material.Name] + 1
                    
                    -- Track textures if any
                    if desc:IsA("MeshPart") or desc:IsA("Part") then
                        if desc.TextureID and desc.TextureID ~= "" then
                            uniqueTextures[desc.TextureID] = true
                        end
                    end
                    
                    -- Estimate triangle count for mesh parts
                    if desc:IsA("MeshPart") then
                        local triangleCount = desc:GetAttribute("TriangleCount") or 500 -- rough estimate if not available
                        stats.totalTriangles = stats.totalTriangles + triangleCount
                        modelStats.triangles = modelStats.triangles + triangleCount
                        stats.categories[category].triangles = stats.categories[category].triangles + triangleCount
                    else
                        -- Regular parts are typically 12 triangles (2 per face)
                        stats.totalTriangles = stats.totalTriangles + 12
                        modelStats.triangles = modelStats.triangles + 12
                        stats.categories[category].triangles = stats.categories[category].triangles + 12
                    end
                    
                    -- Very rough memory estimation (just for comparison purposes)
                    local partMemory = 1000 -- base memory for a part
                    if desc:IsA("MeshPart") then
                        partMemory = partMemory + (desc:GetAttribute("TriangleCount") or 500) * 50 / 1000
                    end
                    stats.estimatedMemory = stats.estimatedMemory + partMemory
                    modelStats.estimatedMemory = modelStats.estimatedMemory + partMemory
                    stats.categories[category].estimatedMemory = stats.categories[category].estimatedMemory + partMemory
                end
            end
            
            -- Track highest part count
            if modelStats.parts > stats.maxPartsInModel then
                stats.maxPartsInModel = modelStats.parts
                stats.maxPartModel = model.Name
            end
            
            -- Store detailed model stats if requested
            if options.detailed then
                stats.modelDetails[model.Name] = modelStats
            end
        end
    end
    
    -- Calculate averages and counts
    stats.averagePartsPerModel = stats.totalModels > 0 and math.floor(stats.totalParts / stats.totalModels) or 0
    stats.uniqueMaterialCount = 0
    for _ in pairs(uniqueMaterials) do stats.uniqueMaterialCount = stats.uniqueMaterialCount + 1 end
    stats.uniqueTextureCount = 0
    for _ in pairs(uniqueTextures) do stats.uniqueTextureCount = stats.uniqueTextureCount + 1 end
    
    -- Format output
    if options.export == "print" then
        print("\n===== MODEL STATISTICS FOR " .. tycoon.Name .. " =====")
        print("Total models: " .. stats.totalModels)
        print("Total parts: " .. stats.totalParts)
        print("Average parts per model: " .. stats.averagePartsPerModel)
        print("Max parts in a model: " .. stats.maxPartsInModel .. " (" .. stats.maxPartModel .. ")")
        print("Total triangles: " .. stats.totalTriangles)
        print("Estimated memory usage: " .. math.floor(stats.estimatedMemory / 1024) .. " KB")
        print("Total scripts: " .. stats.scriptsCount)
        print("Unique materials: " .. stats.uniqueMaterialCount)
        print("Unique textures: " .. stats.uniqueTextureCount)
        
        if options.categoryBreakdown then
            print("\nCATEGORY BREAKDOWN:")
            for category, catStats in pairs(stats.categories) do
                print(category .. ":")
                print("  Models: " .. catStats.models)
                print("  Parts: " .. catStats.parts)
                print("  Triangles: " .. catStats.triangles)
                print("  Estimated memory: " .. math.floor(catStats.estimatedMemory / 1024) .. " KB")
            end
        end
        
        -- Print detailed model stats for models with a high part count
        if options.detailed then
            print("\nDETAILED STATS FOR LARGE MODELS:")
            for _, modelStats in pairs(stats.modelDetails) do
                if modelStats.parts > 50 then -- Only show larger models
                    print(modelStats.name .. " (" .. modelStats.category .. "):")
                    print("  Parts: " .. modelStats.parts)
                    print("  Triangles: " .. modelStats.triangles)
                    print("  Unanchored parts: " .. modelStats.unanchoredParts)
                    print("  Scripts: " .. modelStats.scripts .. " (" .. modelStats.serverScripts .. " server, " .. modelStats.clientScripts .. " client)")
                    print("  Estimated memory: " .. math.floor(modelStats.estimatedMemory / 1024) .. " KB")
                end
            end
        end
    elseif options.export == "file" then
        -- Create a text report
        local report = "MODEL STATISTICS FOR " .. tycoon.Name .. "\n"
        report = report .. "Generated: " .. os.date() .. "\n\n"
        report = report .. "Total models: " .. stats.totalModels .. "\n"
        report = report .. "Total parts: " .. stats.totalParts .. "\n"
        report = report .. "Average parts per model: " .. stats.averagePartsPerModel .. "\n"
        report = report .. "Total triangles: " .. stats.totalTriangles .. "\n"
        report = report .. "Estimated memory usage: " .. math.floor(stats.estimatedMemory / 1024) .. " KB\n"
        
        -- Create model stats StringValue in ReplicatedStorage
        local statsValue = Instance.new("StringValue")
        statsValue.Name = "ModelStatsReport_" .. os.date("%Y%m%d_%H%M%S")
        statsValue.Value = report
        statsValue.Parent = ReplicatedStorage
        
        print("Model stats report generated and saved to ReplicatedStorage." .. statsValue.Name)
    end
    
    return stats
end

--[[
    CompareConfigWithModels

    Compares an existing configuration module against the actual models,
    detecting inconsistencies between config and models.
    
    Parameters:
    - configModule (string or ModuleScript): Name of config module or the module itself
    - tycoonName (string, optional): Name of the tycoon to compare with
    - options (table, optional):
      - strict (boolean): Whether to enforce strict matching (default: false)
      - autoFix (boolean): Whether to automatically fix minor issues (default: false)
    
    Returns: Table of inconsistencies found
]]
function DevUtilityFunctions:CompareConfigWithModels(configModule, tycoonName, options)
    local tycoon = self:FindTycoon(tycoonName)
    if not tycoon then return nil end
    
    -- Load the config module
    local config
    if type(configModule) == "string" then
        local module = ReplicatedStorage:FindFirstChild(configModule) or ServerStorage:FindFirstChild(configModule)
        if not module then
            warn("Config module not found: " .. configModule)
            return nil
        end
        config = require(module)
    elseif typeof(configModule) == "Instance" and configModule:IsA("ModuleScript") then
        config = require(configModule)
    else
        config = configModule
    end
    
    if not config then
        warn("Invalid config module provided")
        return nil
    end
    
    -- Set default options
    options = options or {}
    options.strict = options.strict or false
    options.autoFix = options.autoFix or false
    
    local results = {
        missing = {}, -- Models in config but not in workspace
        extra = {}, -- Models in workspace but not in config
        attributeMismatches = {}, -- Models with differing attributes
        fixed = {}, -- Models with fixed issues
        analysisDate = os.date()
    }
    
    -- Build hash of models in workspace
    local modelsByName = {}
    for _, model in ipairs(tycoon:GetDescendants()) do
        if model:IsA("Model") then
            modelsByName[model.Name] = model
        end
    end
    
    -- Check for models in config but missing in workspace
    for name, configData in pairs(config) do
        if not modelsByName[name] then
            table.insert(results.missing, {
                name = name,
                configData = configData
            })
        else
            -- Check for attribute mismatches
            local model = modelsByName[name]
            local mismatches = {}
            
            for attr, value in pairs(configData) do
                if type(value) ~= "table" and type(value) ~= "function" then
                    local modelValue = model:GetAttribute(attr)
                    
                    if modelValue ~= value then
                        table.insert(mismatches, {
                            attribute = attr,
                            configValue = value,
                            modelValue = modelValue
                        })
                        
                        -- Auto-fix if requested
                        if options.autoFix then
                            model:SetAttribute(attr, value)
                            table.insert(results.fixed, {
                                model = name,
                                attribute = attr,
                                oldValue = modelValue,
                                newValue = value
                            })
                        end
                    end
                end
            end
            
            if #mismatches > 0 then
                results.attributeMismatches[name] = mismatches
            end
            
            -- Mark as processed
            modelsByName[name] = nil
        end
    end
    
    -- Remaining models in workspace but missing from config
    for name, model in pairs(modelsByName) do
        table.insert(results.extra, {
            name = name,
            model = model
        })
    end
    
    -- Generate summary
    local missingCount = #results.missing
    local extraCount = #results.extra
    local mismatchCount = 0
    for _ in pairs(results.attributeMismatches) do mismatchCount = mismatchCount + 1 end
    local fixedCount = #results.fixed
    
    print("\n===== CONFIG VS. MODELS COMPARISON =====")
    print("Missing models (in config but not in workspace): " .. missingCount)
    print("Extra models (in workspace but not in config): " .. extraCount)
    print("Models with attribute mismatches: " .. mismatchCount)
    
    if options.autoFix then
        print("Fixed issues: " .. fixedCount)
    end
    
    -- Display details if there are issues
    if missingCount > 0 then
        print("\nMISSING MODELS:")
        for _, item in ipairs(results.missing) do
            print("- " .. item.name)
        end
    end
    
    if extraCount > 0 then
        print("\nEXTRA MODELS:")
        for _, item in ipairs(results.extra) do
            print("- " .. item.name)
        end
    end
    
    if mismatchCount > 0 then
        print("\nATTRIBUTE MISMATCHES:")
        for name, mismatches in pairs(results.attributeMismatches) do
            print("- " .. name .. ":")
            for _, mismatch in ipairs(mismatches) do
                print("  " .. mismatch.attribute .. ": " .. tostring(mismatch.configValue) .. " (config) vs. " .. tostring(mismatch.modelValue) .. " (model)")
            end
        end
    end
    
    return results
end

--[[
    ExportCollectionServiceTags

    Exports a list of all CollectionService tags used in the game.
    
    Parameters:
    - outputFormat (string, optional): Format to output the tags
      "table" (default), "print", "module", "json"
    - containerName (string, optional): Name of container to export tags from
      If not provided, exports all tags in the workspace
    
    Returns: Table of tags or path to output file/module
]]
function DevUtilityFunctions:ExportCollectionServiceTags(outputFormat, containerName)
    outputFormat = outputFormat or "table"
    
    -- Determine the container to analyze
    local container
    if containerName then
        container = Workspace:FindFirstChild(containerName)
        if not container then
            warn("Container not found: " .. containerName)
            return nil
        end
    else
        container = Workspace
    end
    
    -- Collect all tags and their usage
    local tagUsage = {}
    local tagRegistry = {}
    
    -- First collect all known tags from the CollectionService
    local allRegisteredTags = CollectionService:GetAllTags()
    for _, tag in ipairs(allRegisteredTags) do
        tagRegistry[tag] = true
    end
    
    -- Scan all instances in the container to find tagged objects
    for _, instance in ipairs(container:GetDescendants()) do
        local tags = CollectionService:GetTags(instance)
        
        for _, tag in ipairs(tags) do
            tagRegistry[tag] = true
            
            if not tagUsage[tag] then
                tagUsage[tag] = {
                    count = 0,
                    instances = {},
                    categories = {}
                }
            end
            
            tagUsage[tag].count = tagUsage[tag].count + 1
            table.insert(tagUsage[tag].instances, instance:GetFullName())
            
            -- Track category usage
            local category = "Unknown"
            if instance:IsA("Model") then
                category = instance:GetAttribute("Category") or "Unknown"
            end
            
            if not tagUsage[tag].categories[category] then
                tagUsage[tag].categories[category] = 0
            end
            tagUsage[tag].categories[category] = tagUsage[tag].categories[category] + 1
        end
    end
    
    -- Build the result structure
    local tagsData = {
        tags = {},
        summary = {
            totalTags = 0,
            totalUsages = 0,
            mostUsedTag = "",
            mostUsedCount = 0
        }
    }
    
    -- Process all registered tags
    for tag, _ in pairs(tagRegistry) do
        local usageData = tagUsage[tag] or { count = 0, categories = {} }
        
        local tagData = {
            name = tag,
            count = usageData.count,
            categories = {}
        }
        
        -- Copy category usage data
        for category, count in pairs(usageData.categories) do
            tagData.categories[category] = count
        end
        
        -- Track most used tag
        if usageData.count > tagsData.summary.mostUsedCount then
            tagsData.summary.mostUsedTag = tag
            tagsData.summary.mostUsedCount = usageData.count
        end
        
        table.insert(tagsData.tags, tagData)
        
        -- Update summary
        tagsData.summary.totalTags = tagsData.summary.totalTags + 1
        tagsData.summary.totalUsages = tagsData.summary.totalUsages + usageData.count
    end
    
    -- Sort tags by usage count
    table.sort(tagsData.tags, function(a, b)
        return a.count > b.count
    end)
    
    -- Output based on format
    if outputFormat == "print" then
        print("\n===== COLLECTION SERVICE TAG USAGE =====")
        print("Total unique tags: " .. tagsData.summary.totalTags)
        print("Total tag usages: " .. tagsData.summary.totalUsages)
        
        if tagsData.summary.mostUsedTag ~= "" then
            print("Most used tag: " .. tagsData.summary.mostUsedTag .. " (" .. tagsData.summary.mostUsedCount .. " instances)")
        end
        
        print("\nTAG USAGE:")
        for _, tagData in ipairs(tagsData.tags) do
            print("- " .. tagData.name .. ": " .. tagData.count .. " instances")
            
            -- Show category breakdown for tags with significant usage
            if tagData.count >= 5 then
                for category, count in pairs(tagData.categories) do
                    if count > 0 then
                        print("  - " .. category .. ": " .. count)
                    end
                end
            end
        end
        
        return tagsData
    elseif outputFormat == "json" then
        local jsonData = HttpService:JSONEncode(tagsData)
        
        -- Create a StringValue in ReplicatedStorage with the JSON data
        local jsonValue = Instance.new("StringValue")
        jsonValue.Name = "CollectionServiceTags_" .. os.date("%Y%m%d_%H%M%S")
        jsonValue.Value = jsonData
        jsonValue.Parent = ReplicatedStorage
        
        print("Collection Service tags exported to JSON: ReplicatedStorage." .. jsonValue.Name)
        return jsonValue
    elseif outputFormat == "module" then
        -- Create a module script with the tag data
        local moduleCode = "--[[\n"
        moduleCode = moduleCode .. "    TagRegistry.lua\n"
        moduleCode = moduleCode .. "    Auto-generated on " .. os.date() .. "\n"
        moduleCode = moduleCode .. "    Contains CollectionService tag usage data\n"
        moduleCode = moduleCode .. "]]\n\n"
        
        moduleCode = moduleCode .. "return {\n"
        moduleCode = moduleCode .. "    summary = {\n"
        moduleCode = moduleCode .. "        totalTags = " .. tagsData.summary.totalTags .. ",\n"
        moduleCode = moduleCode .. "        totalUsages = " .. tagsData.summary.totalUsages .. ",\n"
        moduleCode = moduleCode .. "        mostUsedTag = \"" .. tagsData.summary.mostUsedTag .. "\",\n"
        moduleCode = moduleCode .. "        mostUsedCount = " .. tagsData.summary.mostUsedCount .. "\n"
        moduleCode = moduleCode .. "    },\n"
        moduleCode = moduleCode .. "    tags = {\n"
        
        for _, tagData in ipairs(tagsData.tags) do
            moduleCode = moduleCode .. "        [\"" .. tagData.name .. "\"] = {\n"
            moduleCode = moduleCode .. "            count = " .. tagData.count .. ",\n"
            moduleCode = moduleCode .. "            categories = {\n"
            
            for category, count in pairs(tagData.categories) do
                moduleCode = moduleCode .. "                [\"" .. category .. "\"] = " .. count .. ",\n"
            end
            
            moduleCode = moduleCode .. "            }\n"
            moduleCode = moduleCode .. "        },\n"
        end
        
        moduleCode = moduleCode .. "    }\n"
        moduleCode = moduleCode .. "}"
        
        -- Create a ModuleScript with the code
        local moduleScript = Instance.new("ModuleScript")
        moduleScript.Name = "TagRegistry"
        moduleScript.Source = moduleCode
        moduleScript.Parent = ReplicatedStorage
        
        print("Collection Service tags exported to module: ReplicatedStorage.TagRegistry")
        return moduleScript
    else
        -- Default to table output
        return tagsData
    end
end

--[[
    SetupTargetHardware

    Sets up performance test parameters based on target hardware profiles.
    
    Parameters:
    - profile (string): Target hardware profile
      "low", "medium", "high", or "custom"
    - customSettings (table, optional): Custom settings to apply
    
    Returns: Table of applied settings
]]
function DevUtilityFunctions:SetupTargetHardware(profile, customSettings)
    -- Define hardware profiles
    local profiles = {
        low = {
            maxParts = 2000,
            maxTriangles = 100000,
            maxTextureSize = 512,
            renderDistance = 500,
            maxLights = 4,
            shadowQuality = "Low",
            textureQuality = "Low",
            effectsQuality = "Low",
            maxParticlesPerEmitter = 50,
        },
        medium = {
            maxParts = 5000,
            maxTriangles = 250000,
            maxTextureSize = 1024,
            renderDistance = 1000,
            maxLights = 8,
            shadowQuality = "Medium",
            textureQuality = "Medium",
            effectsQuality = "Medium",
            maxParticlesPerEmitter = 150,
        },
        high = {
            maxParts = 15000,
            maxTriangles = 500000,
            maxTextureSize = 2048,
            renderDistance = 2000,
            maxLights = 16,
            shadowQuality = "High",
            textureQuality = "High",
            effectsQuality = "High",
            maxParticlesPerEmitter = 300,
        }
    }
    
    -- Get selected profile
    local settings
    if profile == "custom" and customSettings then
        settings = customSettings
    else
        settings = profiles[profile] or profiles.medium
    end
    
    -- Apply settings to test configuration
    local configValue = Instance.new("StringValue")
    configValue.Name = "TargetHardwareProfile"
    configValue.Value = HttpService:JSONEncode(settings)
    configValue.Parent = ReplicatedStorage
    
    -- Create visual indicator
    local indicator = Instance.new("ScreenGui")
    indicator.Name = "HardwareProfileIndicator"
    indicator.Parent = ReplicatedStorage
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 40)
    frame.Position = UDim2.new(1, -210, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.Parent = indicator
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, -10)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = "Target: " .. profile:upper() .. " hardware"
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    print("\n===== TARGET HARDWARE PROFILE: " .. profile:upper() .. " =====")
    print("Applied the following settings:")
    for setting, value in pairs(settings) do
        print("- " .. setting .. ": " .. tostring(value))
    end
    
    return settings
end

--[[
    GenerateUIConfig

    Extracts properties from UI elements to create a configuration
    module for runtime use.
    
    Parameters:
    - uiContainer (Instance): UI container to analyze
      If not provided, will look in StarterGui
    - options (table, optional):
      - output (string): Output format - "module" (default) or "table"
      - moduleName (string): Name for the generated module
      
    Returns: UI configuration data or module
]]
function DevUtilityFunctions:GenerateUIConfig(uiContainer, options)
    options = options or {}
    options.output = options.output or "module"
    options.moduleName = options.moduleName or "UIConfig"
    
    -- Find UI container if not provided
    if not uiContainer then
        uiContainer = game:GetService("StarterGui")
    elseif type(uiContainer) == "string" then
        uiContainer = game:GetService("StarterGui"):FindFirstChild(uiContainer)
        if not uiContainer then
            warn("UI container not found: " .. uiContainer)
            return nil
        end
    end
    
    -- Properties to extract for each UI type
    local propertyMap = {
        Frame = {"Size", "Position", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency", "BorderSizePixel", "ZIndex"},
        ImageLabel = {"Size", "Position", "AnchorPoint", "Image", "ImageColor3", "ImageTransparency", "ZIndex"},
        TextLabel = {"Size", "Position", "AnchorPoint", "Text", "TextColor3", "TextSize", "Font", "ZIndex"},
        TextButton = {"Size", "Position", "AnchorPoint", "Text", "TextColor3", "TextSize", "Font", "ZIndex"},
        ImageButton = {"Size", "Position", "AnchorPoint", "Image", "ImageColor3", "ImageTransparency", "ZIndex"},
        ScrollingFrame = {"Size", "Position", "AnchorPoint", "CanvasSize", "ScrollBarThickness", "ZIndex"},
        UIListLayout = {"Padding", "FillDirection", "HorizontalAlignment", "VerticalAlignment", "SortOrder"},
        UIGridLayout = {"CellSize", "CellPadding", "FillDirection", "StartCorner"},
        UIPadding = {"PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight"},
    }
    
    -- Recursively extract UI properties
    local function extractUIData(instance)
        if not instance:IsA("GuiObject") and not instance:IsA("UIComponent") then
            return nil
        end
        
        local data = {
            Name = instance.Name,
            ClassName = instance.ClassName,
            Properties = {},
            Children = {}
        }
        
        -- Extract properties for this UI element
        local properties = propertyMap[instance.ClassName] or {}
        for _, prop in ipairs(properties) do
            local success, value = pcall(function() return instance[prop] end)
            if success then
                -- Convert Color3 values to tables
                if typeof(value) == "Color3" then
                    data.Properties[prop] = {value.R, value.G, value.B}
                -- Convert UDim2 values to tables
                elseif typeof(value) == "UDim2" then
                    data.Properties[prop] = {
                        {value.X.Scale, value.X.Offset},
                        {value.Y.Scale, value.Y.Offset}
                    }
                -- Convert UDim values to tables
                elseif typeof(value) == "UDim" then
                    data.Properties[prop] = {value.Scale, value.Offset}
                -- Convert Enum values to strings
                elseif typeof(value) == "EnumItem" then
                    data.Properties[prop] = tostring(value)
                else
                    data.Properties[prop] = value
                end
            end
        end
        
        -- Extract all attributes
        for _, attrName in ipairs(instance:GetAttributeChangedSignal():GetAttributes()) do
            data.Properties["Attr_" .. attrName] = instance:GetAttribute(attrName)
        end
        
        -- Extract children
        for _, child in ipairs(instance:GetChildren()) do
            local childData = extractUIData(child)
            if childData then
                table.insert(data.Children, childData)
            end
        end
        
        return data
    end
    
    -- Start extraction from the container
    local uiConfig = {
        generated = os.date(),
        interfaces = {}
    }
    
    -- Process each direct child of the container (typically ScreenGuis)
    for _, child in ipairs(uiContainer:GetChildren()) do
        if child:IsA("ScreenGui") or child:IsA("GuiMain") then
            local interfaceData = {
                name = child.Name,
                enabled = child.Enabled,
                elements = {}
            }
            
            -- Extract data for each UI element
            for _, element in ipairs(child:GetChildren()) do
                local elementData = extractUIData(element)
                if elementData then
                    table.insert(interfaceData.elements, elementData)
                end
            end
            
            table.insert(uiConfig.interfaces, interfaceData)
        end
    end
    
    -- Output based on format
    if options.output == "module" then
        -- Generate module script
        local moduleCode = "--[[\n"
        moduleCode = moduleCode .. "    " .. options.moduleName .. ".lua\n"
        moduleCode = moduleCode .. "    Auto-generated on " .. os.date() .. "\n"
        moduleCode = moduleCode .. "    Contains UI configuration extracted from StarterGui\n"
        moduleCode = moduleCode .. "]]\n\n"
        
        moduleCode = moduleCode .. "return " .. DevUtilityFunctions:TableToLuaCode(uiConfig)
        
        -- Create a ModuleScript with the code
        local moduleScript = Instance.new("ModuleScript")
        moduleScript.Name = options.moduleName
        moduleScript.Source = moduleCode
        moduleScript.Parent = ReplicatedStorage
        
        print("UI configuration exported to module: ReplicatedStorage." .. options.moduleName)
        return moduleScript
    else
        -- Return the config table
        return uiConfig
    end
end

--[[
    InitializeDevelopmentEnvironment

    Sets up all required systems and tools for development.
    Particularly useful when onboarding new team members to the project.
    
    Parameters:
    - options (table, optional):
      - cleanStart (boolean): Whether to clean existing settings first
      - setupPlugins (boolean): Whether to install recommended plugins
      - loadTestData (boolean): Whether to load test data
      
    Returns: Status of initialization
]]
function DevUtilityFunctions:InitializeDevelopmentEnvironment(options)
    options = options or {}
    options.cleanStart = options.cleanStart or false
    options.setupPlugins = options.setupPlugins or true
    options.loadTestData = options.loadTestData or false
    
    print("\n===== INITIALIZING DEVELOPMENT ENVIRONMENT =====")
    
    -- Create a results table to track initialization
    local results = {
        success = true,
        initialized = {},
        errors = {},
        warnings = {}
    }
    
    -- Function to track initialization steps
    local function initStep(name, fn)
        print("Initializing " .. name .. "...")
        local success, result = pcall(fn)
        
        if success then
            table.insert(results.initialized, name)
            print("✓ " .. name .. " initialized")
            return result
        else
            results.success = false
            table.insert(results.errors, {step = name, error = result})
            warn("✗ Error initializing " .. name .. ": " .. tostring(result))
            return nil
        end
    end
    
    -- Clean start if requested
    if options.cleanStart then
        initStep("Clean Environment", function()
            -- Clear any existing settings from ReplicatedStorage
            for _, child in ipairs(ReplicatedStorage:GetChildren()) do
                if child.Name:match("^Dev") or child.Name:match("Config$") then
                    child:Destroy()
                end
            end
        end)
    end
    
    -- Set up core systems
    initStep("Core Systems", function()
        -- Create a folder for development settings
        local devSettings = Instance.new("Folder")
        devSettings.Name = "DevSettings"
        devSettings.Parent = ReplicatedStorage
        
        -- Create a development status flag
        local devMode = Instance.new("BoolValue")
        devMode.Name = "DevMode"
        devMode.Value = true
        devMode.Parent = devSettings
        
        -- Set project version
        local version = Instance.new("StringValue")
        version.Name = "Version"
        version.Value = "1.0.0-dev"
        version.Parent = devSettings
    end)
    
    -- Set up recommended plugin configuration
    if options.setupPlugins then
        initStep("Plugin Configuration", function()
            -- Create a list of recommended plugins
            local pluginsConfig = Instance.new("StringValue")
            pluginsConfig.Name = "RecommendedPlugins"
            pluginsConfig.Parent = ReplicatedStorage:FindFirstChild("DevSettings")
            
            -- List of recommended plugin IDs
            pluginsConfig.Value = table.concat({
                "4990825893", -- Roblox Studio Output Spy
                "6878133924", -- Module Viewer
                "6532322956", -- Grid Editor
                "1340872380", -- Attribute Editor
                "4048308140", -- Tag Editor
            }, ",")
            
            print("Recommended plugins configured. Please install them from the plugin manager.")
        end)
    end
    
    -- Load test data if requested
    if options.loadTestData then
        initStep("Test Data", function()
            -- Create a test data module
            local testData = Instance.new("ModuleScript")
            testData.Name = "TestData"
            testData.Parent = ReplicatedStorage
            
            -- Basic test data structure
            testData.Source = [[
                return {
                    testPlayers = {
                        {name = "TestPlayer1", cash = 5000, level = 5},
                        {name = "TestPlayer2", cash = 10000, level = 10},
                        {name = "TestPlayer3", cash = 20000, level = 15}
                    },
                    testEquipment = {
                        {name = "Treadmill_Basic", price = 500, incomeBoost = 10},
                        {name = "Treadmill_Premium", price = 1500, incomeBoost = 25},
                        {name = "BenchPress_Basic", price = 700, incomeBoost = 15}
                    }
                }
            ]]
        end)
    end
    
    -- Initialize all validation and automation systems
    initStep("Validation and Automation", function()
        -- Get all tycoons in the workspace
        local tycoons = {}
        for _, child in ipairs(Workspace:GetChildren()) do
            if child.Name == "GymParts" or child.Name == "Tycoon" then
                table.insert(tycoons, child)
            end
        end
        
        if #tycoons > 0 then
            -- Process the first tycoon
            local tycoon = tycoons[1]
            
            -- Apply floor attributes
            if FloorAttributeSetup then
                FloorAttributeSetup:ProcessTycoon(tycoon)
            end
            
            -- Validate models
            if ModelValidator then
                ModelValidator:ValidateAllModels(tycoon)
            end
            
            -- Apply collection tags
            if TaggingSystem then
                TaggingSystem:ApplyAllTags(tycoon, { debug = false })
            end
            
            print("Processed tycoon: " .. tycoon.Name)
        else
            table.insert(results.warnings, "No tycoons found in workspace")
        end
    end)
    
    -- Set up debugging tools
    initStep("Debug Tools", function()
        -- Create debug configuration
        local debugConfig = Instance.new("ModuleScript")
        debugConfig.Name = "DebugConfig"
        debugConfig.Parent = ReplicatedStorage
        
        debugConfig.Source = [[
            return {
                logLevel = "info", -- debug, info, warn, error
                showCollisionBoxes = false,
                showPathfinding = false,
                showPerformanceStats = true,
                breakpointsEnabled = true,
                mockPlayers = false
            }
        ]]
    end)
    
    -- Print summary
    print("\n===== DEVELOPMENT ENVIRONMENT INITIALIZATION COMPLETE =====")
    print("Successfully initialized: " .. #results.initialized .. " systems")
    
    if #results.warnings > 0 then
        print("\nWarnings (" .. #results.warnings .. "):")
        for _, warning in ipairs(results.warnings) do
            print("- " .. tostring(warning))
        end
    end
    
    if #results.errors > 0 then
        print("\nErrors (" .. #results.errors .. "):")
        for _, err in ipairs(results.errors) do
            print("- " .. err.step .. ": " .. tostring(err.error))
        end
    end
    
    -- Return status
    return results
end

-- Helper function to convert a table to Lua code string
function DevUtilityFunctions:TableToLuaCode(tbl, indent)
    indent = indent or 0
    
    if type(tbl) ~= "table" then
        if type(tbl) == "string" then
            return "\"" .. tbl:gsub("\"", "\\\"") .. "\""
        elseif type(tbl) == "boolean" or type(tbl) == "number" then
            return tostring(tbl)
        elseif tbl == nil then
            return "nil"
        else
            return "\"" .. tostring(tbl) .. "\""
        end
    end
    
    local indentStr = string.rep("    ", indent)
    local result = "{\n"
    
    -- First handle array part
    local arrayCount = 0
    for i, v in ipairs(tbl) do
        arrayCount = i
        result = result .. indentStr .. "    " .. self:TableToLuaCode(v, indent + 1) .. ",\n"
    end
    
    -- Then handle dictionary part
    for k, v in pairs(tbl) do
        if type(k) ~= "number" or k > arrayCount then
            local key = type(k) == "string" and "[\"" .. k .. "\"]" or "[" .. tostring(k) .. "]"
            result = result .. indentStr .. "    " .. key .. " = " .. self:TableToLuaCode(v, indent + 1) .. ",\n"
        end
    end
    
    result = result .. indentStr .. "}"
    return result
end

-- Register these utility functions globally for ease of use in Studio
function DevUtilityFunctions:RegisterGlobalFunctions()
    if not game:GetService("RunService"):IsStudio() then
        return
    end
    
    _G.BatchProcessModels = function(tycoonName, processingFunction, options)
        return DevUtilityFunctions:BatchProcessModels(tycoonName, processingFunction, options)
    end
    
    _G.GenerateModelStats = function(tycoonName, options)
        return DevUtilityFunctions:GenerateModelStats(tycoonName, options)
    end
    
    _G.CompareConfigWithModels = function(configModule, tycoonName, options)
        return DevUtilityFunctions:CompareConfigWithModels(configModule, tycoonName, options)
    end
    
    _G.ExportCollectionServiceTags = function(outputFormat, containerName)
        return DevUtilityFunctions:ExportCollectionServiceTags(outputFormat, containerName)
    end
    
    _G.SetupTargetHardware = function(profile, customSettings)
        return DevUtilityFunctions:SetupTargetHardware(profile, customSettings)
    end
    
    _G.GenerateUIConfig = function(uiContainer, options)
        return DevUtilityFunctions:GenerateUIConfig(uiContainer, options)
    end
    
    _G.InitializeDevelopmentEnvironment = function(options)
        return DevUtilityFunctions:InitializeDevelopmentEnvironment(options)
    end
    
    -- Register utility with registry if available
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("DevUtilityFunctions", DevUtilityFunctions)
    end
    
    print("✓ Registered global function: _G.BatchProcessModels(tycoonName, processingFunction, options)")
    print("✓ Registered global function: _G.GenerateModelStats(tycoonName, options)")
    print("✓ Registered global function: _G.CompareConfigWithModels(configModule, tycoonName, options)")
    print("✓ Registered global function: _G.ExportCollectionServiceTags(outputFormat, containerName)")
    print("✓ Registered global function: _G.SetupTargetHardware(profile, customSettings)")
    print("✓ Registered global function: _G.GenerateUIConfig(uiContainer, options)")
    print("✓ Registered global function: _G.InitializeDevelopmentEnvironment(options)")
end

-- Initialize and register the module
DevUtilityFunctions:RegisterGlobalFunctions()

return DevUtilityFunctions