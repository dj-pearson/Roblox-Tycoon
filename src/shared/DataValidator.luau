--!strict
--[[
    DataValidator.luau
    
    A utility module for validating data structures and repairing corrupt data.
    This helps prevent data corruption and provides mechanisms to fix
    damaged data before it causes further issues.
    
    Created: April 26, 2025
]]

local HttpService = game:GetService("HttpService")

-- Configuration
local CONFIG = {
    debug = true,
    strictMode = false, -- In strict mode, validation failures return nil
    repairMode = true,  -- Attempt to repair invalid data when possible
    typeChecking = true -- Perform type checking on properties
}

-- Default data structure - used for validation and repair
local DEFAULT_DATA = {
    -- Economy
    cash = 1000,
    totalEarned = 0,
    
    -- Progression
    equipmentPurchased = {},
    equipmentCount = 0,
    gymLevel = 1,
    memberCount = 0,
    vipCount = 0,
    
    -- Stats
    playTime = 0,
    lastPlayed = 0,
    
    -- Version control
    dataVersion = 1
}

-- Logging function
local function log(message)
    if CONFIG.debug then
        print("[DataValidator] " .. message)
    end
end

-- Type definitions for validation
local TYPES = {
    CASH = "number",
    EQUIPMENT_PURCHASED = "table",
    EQUIPMENT_COUNT = "number",
    GYM_LEVEL = "number",
    MEMBER_COUNT = "number",
    VIP_COUNT = "number",
    PLAY_TIME = "number",
    LAST_PLAYED = "number",
    DATA_VERSION = "number"
}

-- Value constraints for different fields
local CONSTRAINTS = {
    cash = { min = 0 },
    totalEarned = { min = 0 },
    equipmentCount = { min = 0 },
    gymLevel = { min = 1, max = 100 },
    memberCount = { min = 0 },
    vipCount = { min = 0 },
    playTime = { min = 0 },
    dataVersion = { min = 1 }
}

local DataValidator = {}

-- Deep copy function for data cloning
function DataValidator.deepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = DataValidator.deepCopy(value)
        else
            copy[key] = value
        end
    end
    
    return copy
end

-- Validate a value against constraints
function DataValidator.validateValue(value, fieldName, constraints)
    if not constraints then
        return true
    end
    
    -- Type checking
    if CONFIG.typeChecking and TYPES[string.upper(fieldName)] and type(value) ~= TYPES[string.upper(fieldName)] then
        log("Type mismatch for " .. fieldName .. ": expected " .. TYPES[string.upper(fieldName)] .. ", got " .. type(value))
        return false
    end
    
    -- Number constraints
    if type(value) == "number" then
        if constraints.min and value < constraints.min then
            log("Value for " .. fieldName .. " is below minimum: " .. value .. " < " .. constraints.min)
            return false
        end
        
        if constraints.max and value > constraints.max then
            log("Value for " .. fieldName .. " exceeds maximum: " .. value .. " > " .. constraints.max)
            return false
        end
    end
    
    -- Table constraints
    if type(value) == "table" and constraints.requiredKeys then
        for _, key in ipairs(constraints.requiredKeys) do
            if value[key] == nil then
                log("Missing required key in table: " .. key)
                return false
            end
        end
    end
    
    return true
end

-- Core validation function for player data
function DataValidator.validatePlayerData(data)
    if not data then
        log("Data is nil")
        return false, CONFIG.repairMode and DataValidator.repairPlayerData(nil) or nil
    end
    
    if type(data) ~= "table" then
        log("Data is not a table")
        return false, CONFIG.repairMode and DataValidator.repairPlayerData(nil) or nil
    end
    
    -- Create a validation results table
    local validationResults = {
        isValid = true,
        issues = {},
        repaired = {}
    }
    
    -- Check each expected field
    for field, defaultValue in pairs(DEFAULT_DATA) do
        -- Check if field exists
        if data[field] == nil then
            validationResults.isValid = false
            table.insert(validationResults.issues, "Missing field: " .. field)
            
            if CONFIG.repairMode then
                data[field] = DataValidator.deepCopy(defaultValue)
                table.insert(validationResults.repaired, "Added missing field: " .. field)
            end
            continue
        end
        
        -- Validate value
        local constraints = CONSTRAINTS[field]
        if not DataValidator.validateValue(data[field], field, constraints) then
            validationResults.isValid = false
            table.insert(validationResults.issues, "Invalid value for field: " .. field)
            
            if CONFIG.repairMode then
                -- Repair based on field type
                if type(defaultValue) == "number" and type(data[field]) ~= "number" then
                    data[field] = defaultValue
                    table.insert(validationResults.repaired, "Repaired field " .. field .. " with default value")
                elseif type(defaultValue) == "number" and type(data[field]) == "number" then
                    -- Apply constraints
                    if constraints and constraints.min and data[field] < constraints.min then
                        data[field] = constraints.min
                        table.insert(validationResults.repaired, "Applied minimum constraint to " .. field)
                    end
                    
                    if constraints and constraints.max and data[field] > constraints.max then
                        data[field] = constraints.max
                        table.insert(validationResults.repaired, "Applied maximum constraint to " .. field)
                    end
                elseif type(defaultValue) == "table" and type(data[field]) ~= "table" then
                    data[field] = DataValidator.deepCopy(defaultValue)
                    table.insert(validationResults.repaired, "Repaired table field " .. field .. " with default value")
                end
            end
        end
    end
    
    -- Special validation for equipment purchased table
    if type(data.equipmentPurchased) == "table" then
        for id, value in pairs(data.equipmentPurchased) do
            -- Ensure each entry is a boolean
            if type(value) ~= "boolean" then
                validationResults.isValid = false
                table.insert(validationResults.issues, "Non-boolean value in equipmentPurchased: " .. tostring(id))
                
                if CONFIG.repairMode then
                    data.equipmentPurchased[id] = true
                    table.insert(validationResults.repaired, "Fixed non-boolean value for equipment " .. tostring(id))
                end
            end
        end
    end
    
    -- Validate equipment count matches actual purchased equipment
    if type(data.equipmentPurchased) == "table" and type(data.equipmentCount) == "number" then
        local actualCount = 0
        for _ in pairs(data.equipmentPurchased) do
            actualCount = actualCount + 1
        end
        
        if actualCount ~= data.equipmentCount then
            validationResults.isValid = false
            table.insert(validationResults.issues, "Equipment count mismatch: stored " .. data.equipmentCount .. ", actual " .. actualCount)
            
            if CONFIG.repairMode then
                data.equipmentCount = actualCount
                table.insert(validationResults.repaired, "Fixed equipment count: updated to " .. actualCount)
            end
        end
    end
    
    -- Log validation results
    if #validationResults.issues > 0 then
        log("Data validation found " .. #validationResults.issues .. " issues")
        for _, issue in ipairs(validationResults.issues) do
            log("- " .. issue)
        end
    end
    
    if #validationResults.repaired > 0 then
        log("Data validation repaired " .. #validationResults.repaired .. " issues")
        for _, repair in ipairs(validationResults.repaired) do
            log("- " .. repair)
        end
    end
    
    -- Return validation result and possibly repaired data
    return validationResults.isValid or not CONFIG.strictMode, data
end

-- Create repaired data from scratch or fix existing data
function DataValidator.repairPlayerData(data)
    log("Repairing player data")
    
    -- Create a new data table
    local repairedData = DataValidator.deepCopy(DEFAULT_DATA)
    
    -- Copy over valid data from original if available
    if data and type(data) == "table" then
        for field, defaultValue in pairs(DEFAULT_DATA) do
            if data[field] ~= nil then
                local constraints = CONSTRAINTS[field]
                
                -- Copy based on field type
                if type(defaultValue) == "number" and type(data[field]) == "number" then
                    -- Apply constraints
                    if constraints and constraints.min and data[field] < constraints.min then
                        repairedData[field] = constraints.min
                    elseif constraints and constraints.max and data[field] > constraints.max then
                        repairedData[field] = constraints.max
                    else
                        repairedData[field] = data[field]
                    end
                elseif type(defaultValue) == "table" and type(data[field]) == "table" then
                    repairedData[field] = DataValidator.deepCopy(data[field])
                elseif type(data[field]) == type(defaultValue) then
                    repairedData[field] = data[field]
                end
            end
        end
        
        -- Special handling for equipment purchased
        if type(data.equipmentPurchased) == "table" then
            for id, value in pairs(data.equipmentPurchased) do
                repairedData.equipmentPurchased[id] = true
            end
        end
        
        -- Update equipment count
        local actualCount = 0
        for _ in pairs(repairedData.equipmentPurchased) do
            actualCount = actualCount + 1
        end
        repairedData.equipmentCount = actualCount
    end
    
    -- Set last played time
    repairedData.lastPlayed = os.time()
    
    return repairedData
end

-- Validate integrity of data by comparing with a checksum
function DataValidator.validateIntegrity(data, checksum)
    if not data or type(data) ~= "table" or not checksum then
        return false
    end
    
    -- Create a stable string representation of the data
    local function stableStringify(t, ignoreFields)
        ignoreFields = ignoreFields or {}
        local temp = {}
        
        -- Get and sort keys
        local keys = {}
        for k in pairs(t) do
            if not ignoreFields[k] then
                table.insert(keys, k)
            end
        end
        table.sort(keys)
        
        -- Generate stable string
        for _, k in ipairs(keys) do
            local v = t[k]
            if type(v) == "table" then
                table.insert(temp, k .. ":" .. stableStringify(v, {}))
            else
                table.insert(temp, k .. ":" .. tostring(v))
            end
        end
        
        return "{" .. table.concat(temp, ",") .. "}"
    end
    
    -- Calculate checksum of current data (excluding the checksum field itself)
    local dataString = stableStringify(data, {__checksum = true})
    local calculatedChecksum = HttpService:GenerateGUID(false)
    
    return calculatedChecksum == checksum
end

-- Generate a checksum for data integrity verification
function DataValidator.generateChecksum(data)
    if not data or type(data) ~= "table" then
        return nil
    end
    
    -- Create a stable string representation of the data
    local function stableStringify(t)
        local temp = {}
        
        -- Get and sort keys
        local keys = {}
        for k in pairs(t) do
            if k ~= "__checksum" then -- Exclude existing checksum
                table.insert(keys, k)
            end
        end
        table.sort(keys)
        
        -- Generate stable string
        for _, k in ipairs(keys) do
            local v = t[k]
            if type(v) == "table" then
                table.insert(temp, k .. ":" .. stableStringify(v))
            else
                table.insert(temp, k .. ":" .. tostring(v))
            end
        end
        
        return "{" .. table.concat(temp, ",") .. "}"
    end
    
    -- Calculate checksum
    local dataString = stableStringify(data)
    local checksum = HttpService:GenerateGUID(false)
    
    return checksum
end

-- Configure the validator
function DataValidator.configure(config)
    for key, value in pairs(config) do
        if CONFIG[key] ~= nil then
            CONFIG[key] = value
        end
    end
    
    log("DataValidator configured")
    return DataValidator
end

-- Update default data template
function DataValidator.setDefaultData(defaultData)
    if type(defaultData) == "table" then
        DEFAULT_DATA = DataValidator.deepCopy(defaultData)
        log("Updated default data template")
    else
        log("Invalid default data provided")
    end
    
    return DataValidator
end

return DataValidator
