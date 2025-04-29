--!strict
--[[
    DataTypes.luau
    
    Standardized data type definitions and validation for the game's data system.
    Provides a structured way to define, validate, and manage data schemas.
    
    Features:
    - Type definitions for all game data
    - Schema validation
    - Default value generation
    - Type conversion utilities
    - Migration helpers
    
    Author: Updated April 27, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataTypes = {}

-- Type validators
local TypeValidators = {
    ["string"] = function(value)
        return typeof(value) == "string", "Expected string, got " .. typeof(value)
    end,
    
    ["number"] = function(value)
        return typeof(value) == "number", "Expected number, got " .. typeof(value)
    end,
    
    ["integer"] = function(value)
        return typeof(value) == "number" and math.floor(value) == value, 
               "Expected integer, got " .. typeof(value)
    end,
    
    ["boolean"] = function(value)
        return typeof(value) == "boolean", "Expected boolean, got " .. typeof(value)
    end,
    
    ["table"] = function(value)
        return typeof(value) == "table", "Expected table, got " .. typeof(value)
    end,
    
    ["array"] = function(value)
        if typeof(value) ~= "table" then
            return false, "Expected array (table), got " .. typeof(value)
        end
        
        -- Check if it's an array (consecutive integer keys starting from 1)
        local count = 0
        for _ in pairs(value) do
            count += 1
        end
        
        for i = 1, count do
            if value[i] == nil then
                return false, "Expected array but found non-consecutive keys"
            end
        end
        
        return true, ""
    end,
    
    ["Instance"] = function(value)
        return typeof(value) == "Instance", "Expected Instance, got " .. typeof(value)
    end,
    
    ["Vector3"] = function(value)
        return typeof(value) == "Vector3", "Expected Vector3, got " .. typeof(value)
    end,
    
    ["Color3"] = function(value)
        return typeof(value) == "Color3", "Expected Color3, got " .. typeof(value)
    end,
    
    ["EnumItem"] = function(value)
        return typeof(value) == "EnumItem", "Expected EnumItem, got " .. typeof(value)
    end,
    
    ["function"] = function(value)
        return typeof(value) == "function", "Expected function, got " .. typeof(value)
    end,
    
    ["userdata"] = function(value)
        return typeof(value) == "userdata", "Expected userdata, got " .. typeof(value)
    end,
    
    ["any"] = function(_)
        return true, ""
    end,
    
    ["nil"] = function(value)
        return value == nil, "Expected nil, got " .. typeof(value)
    end
}

-- Complex type validators

-- Validate a value against a specific enum type
local function validateEnum(value, enumType)
    if typeof(value) ~= "EnumItem" then
        return false, "Expected EnumItem, got " .. typeof(value)
    end
    
    if not value:IsA(enumType) then
        return false, "Expected Enum." .. enumType .. ", got " .. tostring(value)
    end
    
    return true, ""
end

-- Validate a value against a specific class type
local function validateClass(value, className)
    if typeof(value) ~= "Instance" then
        return false, "Expected Instance, got " .. typeof(value)
    end
    
    if not value:IsA(className) then
        return false, "Expected " .. className .. ", got " .. value.ClassName
    end
    
    return true, ""
end

-- Validate that a value is one of several allowed values
local function validateOneOf(value, allowedValues)
    for _, allowedValue in ipairs(allowedValues) do
        if value == allowedValue then
            return true, ""
        end
    end
    
    return false, "Value not in allowed set"
end

-- Validate that a table has a specific structure (keys and value types)
local function validateStructure(value, schema)
    if typeof(value) ~= "table" then
        return false, "Expected table, got " .. typeof(value)
    end
    
    for key, expectedType in pairs(schema) do
        local success, errorMsg
        
        -- Handle nil values based on whether they're required
        if value[key] == nil then
            if string.sub(expectedType, -1) == "?" then
                -- Optional field, nil is acceptable
                success = true
            else
                -- Required field
                return false, "Missing required key: " .. key
            end
        else
            -- Field exists, validate its type
            local cleanType = string.gsub(expectedType, "?$", "")
            
            -- Handle special complex types
            if string.sub(cleanType, 1, 5) == "Enum." then
                -- Enum type validation
                local enumType = string.sub(cleanType, 6)
                success, errorMsg = validateEnum(value[key], enumType)
            elseif string.sub(cleanType, 1, 7) == "Class." then
                -- Class type validation
                local className = string.sub(cleanType, 8)
                success, errorMsg = validateClass(value[key], className)
            elseif string.sub(cleanType, 1, 7) == "OneOf." then
                -- OneOf validation (value must be one of a set)
                -- Format: OneOf.{value1,value2,value3}
                local valuesStr = string.sub(cleanType, 8, -2)  -- Remove OneOf. and {}
                local values = {}
                
                -- Parse the values
                for valueStr in string.gmatch(valuesStr, "[^,]+") do
                    table.insert(values, valueStr)
                end
                
                success, errorMsg = validateOneOf(value[key], values)
            elseif string.sub(cleanType, 1, 6) == "Array." then
                -- Array of specific type validation
                -- First check if it's an array
                success, errorMsg = TypeValidators["array"](value[key])
                
                if success then
                    -- Then check each element
                    local elementType = string.sub(cleanType, 7)
                    local elementValidator = TypeValidators[elementType]
                    
                    if elementValidator then
                        for i, element in ipairs(value[key]) do
                            success, errorMsg = elementValidator(element)
                            
                            if not success then
                                errorMsg = "Array element " .. i .. ": " .. errorMsg
                                break
                            end
                        end
                    else
                        success = false
                        errorMsg = "Unknown array element type: " .. elementType
                    end
                end
            elseif string.sub(cleanType, 1, 7) == "Struct." then
                -- Nested structure validation
                -- The format should be Struct.NestedSchemaName
                local structName = string.sub(cleanType, 8)
                local nestedSchema = DataTypes.Schemas[structName]
                
                if nestedSchema then
                    success, errorMsg = validateStructure(value[key], nestedSchema)
                else
                    success = false
                    errorMsg = "Unknown structure schema: " .. structName
                end
            else
                -- Simple type validation
                local validator = TypeValidators[cleanType]
                
                if validator then
                    success, errorMsg = validator(value[key])
                else
                    success = false
                    errorMsg = "Unknown type: " .. cleanType
                end
            end
        end
        
        if not success then
            return false, "Field '" .. key .. "': " .. errorMsg
        end
    end
    
    return true, ""
end

--[[ Data Schema Definitions ]]--

-- Store all schemas here for easy reference
DataTypes.Schemas = {}

-- Basic player data schema
DataTypes.Schemas.PlayerData = {
    cash = "number",
    gymLevel = "integer",
    rebirthLevel = "integer",
    experience = "number",
    inventory = "table",
    lastSeen = "number",
    loginStreak = "integer",
    username = "string",
    displayName = "string",
    userId = "integer",
    settings = "table",
    tutorial = "table"
}

-- Equipment data schema
DataTypes.Schemas.Equipment = {
    id = "string",
    name = "string",
    type = "string",
    level = "integer",
    condition = "number",
    durability = "number",
    efficiency = "number",
    popularity = "number",
    purchaseTime = "number",
    lastMaintenance = "number",
    position = "Vector3",
    rotation = "Vector3",
    isLocked = "boolean",
    customizations = "table",
    usageStats = "table"
}

-- Gym member data schema
DataTypes.Schemas.GymMember = {
    id = "string",
    name = "string",
    level = "integer",
    satisfaction = "number",
    loyalty = "number",
    joinTime = "number",
    lastVisit = "number",
    visitCount = "integer",
    favoriteEquipment = "string?", -- Optional
    traits = "Array.string",
    preferences = "table",
    spending = "number",
    appearance = "table"
}

-- Gym data schema
DataTypes.Schemas.GymData = {
    name = "string",
    level = "integer",
    reputation = "number",
    revenue = "number",
    totalEarnings = "number",
    specialization = "string?", -- Optional
    foundedTime = "number",
    lastUpdate = "number",
    cleanliness = "number",
    equipment = "Array.string", -- Array of equipment IDs
    members = "Array.string", -- Array of member IDs
    staff = "Array.string", -- Array of staff IDs
    upgrades = "table",
    statistics = "table",
    layout = "table"
}

-- Staff member data schema
DataTypes.Schemas.StaffMember = {
    id = "string",
    name = "string",
    role = "string",
    level = "integer",
    skill = "number",
    efficiency = "number",
    salary = "number",
    hireTime = "number",
    lastBonus = "number?", -- Optional
    specialties = "Array.string",
    shifts = "table",
    performance = "table"
}

-- Achievement data schema
DataTypes.Schemas.Achievement = {
    id = "string",
    name = "string",
    description = "string",
    category = "string",
    progress = "number",
    completed = "boolean",
    completionTime = "number?", -- Optional
    rewards = "table",
    isHidden = "boolean"
}

-- Quest data schema
DataTypes.Schemas.Quest = {
    id = "string",
    title = "string",
    description = "string",
    type = "string",
    progress = "number",
    goal = "number",
    completed = "boolean",
    startTime = "number",
    endTime = "number?", -- Optional
    rewards = "table",
    prerequisites = "Array.string"
}

-- Transaction data schema
DataTypes.Schemas.Transaction = {
    id = "string",
    type = "string",
    amount = "number",
    timestamp = "number",
    description = "string",
    category = "string",
    relatedItemId = "string?", -- Optional
    metadata = "table"
}

--[[ Default Value Generators ]]--

DataTypes.Defaults = {}

-- Generate default player data
DataTypes.Defaults.PlayerData = function(userId, username, displayName)
    return {
        cash = 1000,
        gymLevel = 1,
        rebirthLevel = 0,
        experience = 0,
        inventory = {},
        lastSeen = os.time(),
        loginStreak = 1,
        username = username or "",
        displayName = displayName or "",
        userId = userId or 0,
        settings = {
            sound = 0.5,
            music = 0.5,
            notifications = true,
            tutorialEnabled = true,
            quality = "medium"
        },
        tutorial = {
            completed = false,
            currentStep = 1,
            seenTips = {}
        }
    }
end

-- Generate default equipment data
DataTypes.Defaults.Equipment = function(id, name, equipType)
    return {
        id = id or "equip_" .. os.time() .. "_" .. math.random(1000, 9999),
        name = name or "Basic Equipment",
        type = equipType or "basic",
        level = 1,
        condition = 100,
        durability = 100,
        efficiency = 1.0,
        popularity = 1.0,
        purchaseTime = os.time(),
        lastMaintenance = os.time(),
        position = Vector3.new(0, 0, 0),
        rotation = Vector3.new(0, 0, 0),
        isLocked = false,
        customizations = {},
        usageStats = {
            totalUses = 0,
            lastUsed = 0,
            revenue = 0,
            popularityHistory = {}
        }
    }
end

-- Generate default gym member data
DataTypes.Defaults.GymMember = function(id, name)
    return {
        id = id or "member_" .. os.time() .. "_" .. math.random(1000, 9999),
        name = name or "Gym Member",
        level = 1,
        satisfaction = 0.75,
        loyalty = 0.5,
        joinTime = os.time(),
        lastVisit = os.time(),
        visitCount = 1,
        favoriteEquipment = nil,
        traits = {},
        preferences = {
            equipmentTypes = {},
            visitTimes = {},
            workoutIntensity = "medium"
        },
        spending = 0,
        appearance = {
            bodyType = "average",
            hairStyle = 1,
            hairColor = Color3.fromRGB(50, 50, 50),
            skinTone = Color3.fromRGB(255, 220, 177)
        }
    }
end

-- Generate default gym data
DataTypes.Defaults.GymData = function(name)
    return {
        name = name or "My Gym",
        level = 1,
        reputation = 1.0,
        revenue = 0,
        totalEarnings = 0,
        specialization = nil,
        foundedTime = os.time(),
        lastUpdate = os.time(),
        cleanliness = 100,
        equipment = {},
        members = {},
        staff = {},
        upgrades = {},
        statistics = {
            dailyRevenue = {},
            memberCount = {},
            satisfaction = {},
            equipmentUsage = {}
        },
        layout = {
            tiles = {},
            walls = {},
            decorations = {}
        }
    }
end

-- Generate default staff member data
DataTypes.Defaults.StaffMember = function(id, name, role)
    return {
        id = id or "staff_" .. os.time() .. "_" .. math.random(1000, 9999),
        name = name or "Staff Member",
        role = role or "trainer",
        level = 1,
        skill = 1.0,
        efficiency = 1.0,
        salary = 250,
        hireTime = os.time(),
        lastBonus = nil,
        specialties = {},
        shifts = {
            monday = { start = 9, duration = 8 },
            tuesday = { start = 9, duration = 8 },
            wednesday = { start = 9, duration = 8 },
            thursday = { start = 9, duration = 8 },
            friday = { start = 9, duration = 8 }
        },
        performance = {
            membersSatisfied = 0,
            equipmentMaintained = 0,
            shiftsCompleted = 0
        }
    }
end

-- Generate default achievement data
DataTypes.Defaults.Achievement = function(id, name, description)
    return {
        id = id or "achievement_default",
        name = name or "Default Achievement",
        description = description or "Default achievement description",
        category = "general",
        progress = 0,
        completed = false,
        completionTime = nil,
        rewards = {
            cash = 0,
            experience = 0,
            items = {}
        },
        isHidden = false
    }
end

-- Generate default quest data
DataTypes.Defaults.Quest = function(id, title, description)
    return {
        id = id or "quest_default",
        title = title or "Default Quest",
        description = description or "Default quest description",
        type = "standard",
        progress = 0,
        goal = 100,
        completed = false,
        startTime = os.time(),
        endTime = nil,
        rewards = {
            cash = 100,
            experience = 50,
            items = {}
        },
        prerequisites = {}
    }
end

-- Generate default transaction data
DataTypes.Defaults.Transaction = function(type, amount, description)
    return {
        id = "txn_" .. os.time() .. "_" .. math.random(1000, 9999),
        type = type or "unknown",
        amount = amount or 0,
        timestamp = os.time(),
        description = description or "Transaction",
        category = "miscellaneous",
        relatedItemId = nil,
        metadata = {}
    }
end

--[[ Public API Functions ]]--

-- Validate data against a schema
function DataTypes.validate(data, schemaName)
    local schema = DataTypes.Schemas[schemaName]
    
    if not schema then
        return false, "Unknown schema: " .. tostring(schemaName)
    end
    
    return validateStructure(data, schema)
end

-- Create data with default values
function DataTypes.create(schemaName, ...)
    local defaultGenerator = DataTypes.Defaults[schemaName]
    
    if not defaultGenerator then
        return nil, "No default generator for schema: " .. tostring(schemaName)
    end
    
    return defaultGenerator(...)
end

-- Sanitize data by cleaning invalid fields and ensuring required fields exist
function DataTypes.sanitize(data, schemaName)
    local schema = DataTypes.Schemas[schemaName]
    
    if not schema then
        return nil, "Unknown schema: " .. tostring(schemaName)
    end
    
    -- Start with default data to ensure all required fields
    local defaultData = DataTypes.create(schemaName)
    
    if not defaultData then
        return nil, "Failed to create default data for schema: " .. tostring(schemaName)
    end
    
    -- Merge input data with defaults
    local sanitized = table.clone(defaultData)
    
    if typeof(data) == "table" then
        -- Only copy keys that exist in the schema
        for key, value in pairs(data) do
            if schema[key] then
                sanitized[key] = value
            end
        end
    end
    
    return sanitized
end

-- Check if a value matches a specific type
function DataTypes.is(value, typeName)
    local validator = TypeValidators[typeName]
    
    if validator then
        local success, _ = validator(value)
        return success
    end
    
    return false
end

-- Convert data to a serializable format (useful for DataStores)
function DataTypes.serialize(data)
    if typeof(data) == "table" then
        local result = {}
        
        for k, v in pairs(data) do
            if typeof(v) == "table" then
                result[k] = DataTypes.serialize(v)
            elseif typeof(v) == "Vector3" then
                result[k] = {
                    __type = "Vector3",
                    x = v.X,
                    y = v.Y,
                    z = v.Z
                }
            elseif typeof(v) == "Color3" then
                result[k] = {
                    __type = "Color3",
                    r = v.R,
                    g = v.G,
                    b = v.B
                }
            elseif typeof(v) == "EnumItem" then
                result[k] = {
                    __type = "EnumItem",
                    enum = tostring(v.EnumType),
                    value = v.Name
                }
            elseif typeof(v) == "Instance" then
                -- Store reference as string path if possible
                result[k] = {
                    __type = "Instance",
                    className = v.ClassName,
                    name = v.Name
                }
            elseif typeof(v) == "function" or typeof(v) == "userdata" then
                -- Skip functions and userdata
                result[k] = nil
            else
                -- Primitive types can be stored directly
                result[k] = v
            end
        end
        
        return result
    elseif typeof(data) == "Vector3" then
        return {
            __type = "Vector3",
            x = data.X,
            y = data.Y,
            z = data.Z
        }
    elseif typeof(data) == "Color3" then
        return {
            __type = "Color3",
            r = data.R,
            g = data.G,
            b = data.B
        }
    elseif typeof(data) == "EnumItem" then
        return {
            __type = "EnumItem",
            enum = tostring(data.EnumType),
            value = data.Name
        }
    elseif typeof(data) == "Instance" then
        return {
            __type = "Instance",
            className = data.ClassName,
            name = data.Name
        }
    elseif typeof(data) == "function" or typeof(data) == "userdata" then
        -- Return nil for non-serializable types
        return nil
    else
        -- Return primitives as is
        return data
    end
end

-- Convert serialized data back to its original form
function DataTypes.deserialize(data)
    if typeof(data) == "table" then
        -- Check if this is a special serialized type
        if data.__type then
            if data.__type == "Vector3" then
                return Vector3.new(data.x, data.y, data.z)
            elseif data.__type == "Color3" then
                return Color3.new(data.r, data.g, data.b)
            elseif data.__type == "EnumItem" then
                -- Try to resolve enum
                local success, enumType = pcall(function()
                    -- Extract enum type name from string like "Enum.Material"
                    local enumTypeName = string.match(data.enum, "Enum%.(.+)")
                    return Enum[enumTypeName]
                end)
                
                if success and enumType then
                    return enumType[data.value]
                else
                    warn("Failed to deserialize EnumItem:", data.enum, data.value)
                    return nil
                end
            elseif data.__type == "Instance" then
                -- We don't attempt to resolve instances during deserialization
                -- as it could be unsafe or unreliable
                warn("Instance reference deserialized but not resolved:", data.className, data.name)
                return nil
            end
        end
        
        -- Regular table, process recursively
        local result = {}
        
        for k, v in pairs(data) do
            result[k] = DataTypes.deserialize(v)
        end
        
        return result
    else
        -- Return primitives as is
        return data
    end
end

-- Deep copy a table
function DataTypes.deepCopy(original)
    local copy
    
    if typeof(original) == "table" then
        copy = {}
        for key, value in pairs(original) do
            copy[key] = DataTypes.deepCopy(value)
        end
    else
        copy = original
    end
    
    return copy
end

-- Merge two tables, with values from second table taking precedence
function DataTypes.merge(target, source)
    if typeof(target) ~= "table" or typeof(source) ~= "table" then
        if typeof(source) == "table" then
            return DataTypes.deepCopy(source)
        else
            return source
        end
    end
    
    local result = DataTypes.deepCopy(target)
    
    for key, value in pairs(source) do
        if typeof(value) == "table" and typeof(result[key]) == "table" then
            -- Recursively merge nested tables
            result[key] = DataTypes.merge(result[key], value)
        else
            -- Override or add value
            result[key] = DataTypes.deepCopy(value)
        end
    end
    
    return result
end

return DataTypes
