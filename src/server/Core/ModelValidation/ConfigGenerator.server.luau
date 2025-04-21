--[[
    ConfigGenerator.server.luau
    
    Automatically generates configuration tables from placed models in the gym tycoon.
    This eliminates the need for manual data entry and reduces the chance of errors.
    
    Features:
    - Extract equipment attributes from placed models
    - Generate consistent configuration tables for runtime systems
    - Support for multiple output formats (Lua tables, ModuleScript, JSON)
    - Validate data consistency across related models
    
    Part of the automated model validation & configuration system.
    
    Author: Created April 21, 2025
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

-- Configuration constants
local ConfigGenerator = {
    -- Types of configurations that can be generated
    CONFIG_TYPES = {
        EQUIPMENT = "equipment",
        SPECIALIZATIONS = "specializations",
        UPGRADES = "upgrades",
        NPC_TYPES = "npc_types"
    },
    
    -- Required attributes for different entity types
    REQUIRED_ATTRIBUTES = {
        EQUIPMENT = {"Category", "Price", "IncomeBoost"},
        SPECIALIZATIONS = {"Category", "Bonus"},
        UPGRADES = {"UpgradesFrom", "Price", "IncomeBoost"},
        NPC = {"Speed", "Income", "Satisfaction"}
    },
    
    -- Optional attributes to include if found
    OPTIONAL_ATTRIBUTES = {
        EQUIPMENT = {"Description", "Floor", "BuildOrder", "UpgradesTo", "UpgradesFrom", "UnlockRequirement", "SatisfactionImpact"},
        SPECIALIZATIONS = {"UnlockRequirement", "MaxLevel", "BoostType"},
        UPGRADES = {"Description", "UpgradeTier", "UnlockRequirement"},
        NPC = {"SpawnRate", "StayDuration", "InteractionTypes"}
    }
}

-- Private helper functions
local function serializeTable(tbl, indent, processed)
    processed = processed or {}
    indent = indent or 0
    
    if processed[tbl] then
        return "{ /* CIRCULAR REFERENCE */ }"
    end
    
    processed[tbl] = true
    
    local result = "{\n"
    local indentStr = string.rep("\t", indent + 1)
    
    for k, v in pairs(tbl) do
        local keyStr
        
        if type(k) == "string" then
            keyStr = string.format("%q", k)
        else
            keyStr = tostring(k)
        end
        
        local valueStr
        
        if type(v) == "table" then
            valueStr = serializeTable(v, indent + 1, processed)
        elseif type(v) == "string" then
            valueStr = string.format("%q", v)
        else
            valueStr = tostring(v)
        end
        
        result = result .. indentStr .. "[" .. keyStr .. "] = " .. valueStr .. ",\n"
    end
    
    result = result .. string.rep("\t", indent) .. "}"
    return result
end

-- Generate a configuration table for equipment
function ConfigGenerator:GenerateEquipmentConfig(container, options)
    options = options or {}
    local config = {}
    
    -- Process each model in the container
    for _, model in ipairs(container:GetDescendants()) do
        if model:IsA("Model") then
            local category = model:GetAttribute("Category")
            
            -- Skip models without the equipment category
            if not category or (options.categoryFilter and category ~= options.categoryFilter) then
                continue
            end
            
            local modelConfig = {}
            local modelName = model.Name
            
            -- Extract required attributes
            local allFound = true
            for _, attr in ipairs(self.REQUIRED_ATTRIBUTES.EQUIPMENT) do
                local value = model:GetAttribute(attr)
                if value == nil then
                    if options.strict then
                        print("Warning: Model '" .. modelName .. "' missing required attribute '" .. attr .. "'")
                        allFound = false
                        break
                    end
                else
                    modelConfig[attr] = value
                end
            end
            
            if not allFound and options.strict then
                continue
            end
            
            -- Extract optional attributes
            for _, attr in ipairs(self.OPTIONAL_ATTRIBUTES.EQUIPMENT) do
                local value = model:GetAttribute(attr)
                if value ~= nil then
                    modelConfig[attr] = value
                end
            end
            
            -- Add model configuration to the main config
            config[modelName] = modelConfig
        end
    end
    
    return config
end

-- Generate a configuration table for upgrade paths
function ConfigGenerator:GenerateUpgradesConfig(container, options)
    options = options or {}
    local config = {}
    local models = {}
    
    -- First pass: collect all models
    for _, model in ipairs(container:GetDescendants()) do
        if model:IsA("Model") then
            models[model.Name] = model
        end
    end
    
    -- Second pass: identify upgrade paths
    for modelName, model in pairs(models) do
        local upgradesToAttr = model:GetAttribute("UpgradesTo")
        local upgradesFromAttr = model:GetAttribute("UpgradesFrom")
        
        if upgradesToAttr then
            -- Add upgrade connection
            if not config[modelName] then
                config[modelName] = {}
            end
            
            config[modelName].next = upgradesToAttr
            
            -- Add reverse connection
            if not config[upgradesToAttr] then
                config[upgradesToAttr] = {}
            end
            
            config[upgradesToAttr].previous = modelName
        elseif upgradesFromAttr then
            -- Add upgrade connection
            if not config[modelName] then
                config[modelName] = {}
            end
            
            config[modelName].previous = upgradesFromAttr
            
            -- Add reverse connection
            if not config[upgradesFromAttr] then
                config[upgradesFromAttr] = {}
            end
            
            config[upgradesFromAttr].next = modelName
        end
        
        -- Detect upgrade paths from naming convention (optional)
        if options.detectFromNames and not upgradesToAttr and not upgradesFromAttr then
            -- Extract base name and tier from name pattern (e.g., "Treadmill_1" -> "Treadmill", 1)
            local baseName, tier = string.match(modelName, "(.-)_(%d+)$")
            
            if baseName and tier then
                tier = tonumber(tier)
                
                -- Look for previous tier
                local prevTier = tier - 1
                local prevName = baseName .. "_" .. prevTier
                
                if models[prevName] then
                    if not config[modelName] then
                        config[modelName] = {}
                    end
                    
                    config[modelName].previous = prevName
                    
                    if not config[prevName] then
                        config[prevName] = {}
                    end
                    
                    config[prevName].next = modelName
                end
                
                -- Look for next tier
                local nextTier = tier + 1
                local nextName = baseName .. "_" .. nextTier
                
                if models[nextName] then
                    if not config[modelName] then
                        config[modelName] = {}
                    end
                    
                    config[modelName].next = nextName
                    
                    if not config[nextName] then
                        config[nextName] = {}
                    end
                    
                    config[nextName].previous = modelName
                end
            end
        end
    end
    
    return config
end

-- Generate a complete configuration including all types
function ConfigGenerator:GenerateFullConfig(container, options)
    options = options or {}
    
    local fullConfig = {
        equipment = self:GenerateEquipmentConfig(container, options),
        upgrades = self:GenerateUpgradesConfig(container, { detectFromNames = true })
    }
    
    return fullConfig
end

-- Create a ModuleScript with the configuration
function ConfigGenerator:CreateConfigModule(configTable, moduleName, parent)
    parent = parent or ReplicatedStorage
    
    -- Create or find a ModuleScript with the given name
    local moduleScript = parent:FindFirstChild(moduleName)
    
    if not moduleScript then
        moduleScript = Instance.new("ModuleScript")
        moduleScript.Name = moduleName
        moduleScript.Parent = parent
    end
    
    -- Generate the script contents
    local serialized = serializeTable(configTable)
    local scriptContents = "-- Auto-generated configuration by ConfigGenerator\n"
    scriptContents = scriptContents .. "-- Generated on " .. os.date() .. "\n\n"
    scriptContents = scriptContents .. "return " .. serialized
    
    -- Set the script source
    moduleScript.Source = scriptContents
    
    return moduleScript
end

-- Export configuration as JSON string
function ConfigGenerator:ExportAsJson(configTable)
    return HttpService:JSONEncode(configTable)
end

-- Load the generated configuration into a system
function ConfigGenerator:ApplyConfigToSystem(system, configTable, configType)
    if not system then
        warn("Cannot apply config: system is nil")
        return false
    end
    
    if configType == self.CONFIG_TYPES.EQUIPMENT then
        -- Update equipment configuration
        if system.SetEquipmentData and type(system.SetEquipmentData) == "function" then
            system:SetEquipmentData(configTable)
            return true
        end
    elseif configType == self.CONFIG_TYPES.UPGRADES then
        -- Update upgrade paths
        if system.SetUpgradePaths and type(system.SetUpgradePaths) == "function" then
            system:SetUpgradePaths(configTable)
            return true
        end
    end
    
    return false
end

-- Function to validate generated configuration data
function ConfigGenerator:ValidateConfig(configTable, configType)
    local issues = {}
    
    if configType == self.CONFIG_TYPES.EQUIPMENT then
        for itemName, itemData in pairs(configTable) do
            -- Check for required fields
            for _, field in ipairs({"Category", "Price"}) do
                if itemData[field] == nil then
                    table.insert(issues, {
                        itemName = itemName,
                        field = field,
                        issue = "Missing required field"
                    })
                end
            end
            
            -- Check for valid price (must be positive)
            if itemData.Price and (type(itemData.Price) ~= "number" or itemData.Price <= 0) then
                table.insert(issues, {
                    itemName = itemName,
                    field = "Price",
                    issue = "Price must be a positive number, got " .. tostring(itemData.Price)
                })
            end
            
            -- Check for valid income boost
            if itemData.IncomeBoost and (type(itemData.IncomeBoost) ~= "number") then
                table.insert(issues, {
                    itemName = itemName,
                    field = "IncomeBoost",
                    issue = "IncomeBoost must be a number, got " .. tostring(itemData.IncomeBoost)
                })
            end
        end
    elseif configType == self.CONFIG_TYPES.UPGRADES then
        -- Check for circular upgrade paths
        for itemName, itemData in pairs(configTable) do
            if itemData.next then
                local visited = {[itemName] = true}
                local current = itemData.next
                
                while configTable[current] do
                    if visited[current] then
                        table.insert(issues, {
                            itemName = itemName,
                            field = "upgrade_path",
                            issue = "Circular upgrade path detected starting from " .. itemName
                        })
                        break
                    end
                    
                    visited[current] = true
                    current = configTable[current].next
                    
                    if not current then
                        break
                    end
                end
            end
        end
    end
    
    return issues
end

return ConfigGenerator