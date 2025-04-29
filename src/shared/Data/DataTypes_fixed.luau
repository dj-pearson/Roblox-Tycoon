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
    
    ["boolean"] = function(value)
        return typeof(value) == "boolean", "Expected boolean, got " .. typeof(value)
    end,
    
    ["table"] = function(value)
        return typeof(value) == "table", "Expected table, got " .. typeof(value)
    end,
    
    ["function"] = function(value)
        return typeof(value) == "function", "Expected function, got " .. typeof(value)
    end,
    
    -- Renamed to avoid issues with Luau type checking
    ["userdataObj"] = function(value)
        return typeof(value) == "userdata", "Expected userdata object, got " .. typeof(value)
    end,
    
    ["any"] = function(_)
        return true, ""
    end,
    
    ["nil"] = function(value)
        return value == nil, "Expected nil, got " .. typeof(value)
    end
}

-- Rest of your file content

-- Applying your fixes to the serialize function
function DataTypes.serialize(data)
    if typeof(data) == "table" then
        local result = {}
        
        for k, v in pairs(data) do
            if typeof(v) == "table" then
                result[k] = DataTypes.serialize(v)
            elseif typeof(v) == "Vector3" then
                -- Your Vector3 handling logic
                -- ...
            elseif typeof(v) == "function" or typeof(v) == "userdata" then
                -- Skip functions and userdata objects
                result[k] = nil
            else
                -- Handle primitive types
                result[k] = v
            end
        end
        
        return result
    elseif typeof(data) == "Vector3" then
        -- Your Vector3 handling
        return {
            __type = "Vector3",
            x = data.X,
            y = data.Y,
            z = data.Z
        }
    elseif typeof(data) == "Color3" then
        -- Your Color3 handling
        return {
            __type = "Color3",
            r = data.R,
            g = data.G,
            b = data.B
        }
    elseif typeof(data) == "CFrame" then
        -- Your CFrame handling
        local pos = data.Position
        return {
            __type = "CFrame",
            x = pos.X,
            y = pos.Y,
            z = pos.Z,
            components = {data:GetComponents()}
        }
    elseif typeof(data) == "Enum" then
        -- Your Enum handling
        return {
            __type = "Enum",
            enum = tostring(data),
            value = data.Value
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

-- Return the module
return DataTypes
