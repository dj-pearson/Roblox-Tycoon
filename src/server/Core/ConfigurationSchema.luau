--[[
	ConfigurationSchema.luau
	Defines schema and validation rules for tycoon configurations.
	Part of Phase 6: System Enhancement & Expansion
	
	This module:
	- Defines the expected structure of configuration files
	- Provides validation functions for each type of value
	- Applies default values when needed
	- Handles type conversions for special values
]]

local ConfigurationSchema = {}

-- Services
local HttpService = game:GetService("HttpService")

-- Constants
local DEFAULT_CONFIG = {
	tycoonType = "Gym",
	version = "1.0.0",
	settings = {
		economyMultiplier = 1.0,
		progressionSpeed = 1.0,
		maxFloors = 3,
		customizationEnabled = true,
		enabledFeatures = {
			staffHiring = true,
			equipmentUpgrades = true,
			membershipTiers = true,
			specialEvents = true,
		}
	},
	roomTypes = {
		{name = "Cardio", color = Color3.fromRGB(255, 200, 200)},
		{name = "Weights", color = Color3.fromRGB(200, 200, 255)},
		{name = "Specialized", color = Color3.fromRGB(200, 255, 200)}
	},
	equipmentCategories = {
		{name = "Cardio", upgradePathPrefix = "Cardio_"},
		{name = "Strength", upgradePathPrefix = "Strength_"},
		{name = "Functional", upgradePathPrefix = "Func_"}
	},
	prerequisites = {}
}

-- Schema definition
local SCHEMA = {
	tycoonType = {
		type = "string",
		required = true,
		enum = {"Gym", "Restaurant", "Retail", "Office", "Custom"},
		default = "Gym"
	},
	version = {
		type = "string",
		required = true,
		pattern = "^%d+%.%d+%.%d+$", -- Semantic versioning pattern
		default = "1.0.0"
	},
	settings = {
		type = "table",
		required = true,
		properties = {
			economyMultiplier = {
				type = "number",
				required = true,
				min = 0.1,
				max = 10.0,
				default = 1.0
			},
			progressionSpeed = {
				type = "number",
				required = true,
				min = 0.1,
				max = 10.0,
				default = 1.0
			},
			maxFloors = {
				type = "number",
				required = true,
				min = 1,
				max = 10,
				default = 3,
				integer = true
			},
			customizationEnabled = {
				type = "boolean",
				required = true,
				default = true
			},
			enabledFeatures = {
				type = "table",
				required = false,
				default = {
					staffHiring = true,
					equipmentUpgrades = true,
					membershipTiers = true,
					specialEvents = true,
				}
			}
		}
	},
	roomTypes = {
		type = "array",
		required = true,
		itemSchema = {
			type = "table",
			properties = {
				name = {
					type = "string",
					required = true
				},
				color = {
					type = "Color3",
					required = true
				}
			}
		},
		default = DEFAULT_CONFIG.roomTypes
	},
	equipmentCategories = {
		type = "array",
		required = true,
		itemSchema = {
			type = "table",
			properties = {
				name = {
					type = "string",
					required = true
				},
				upgradePathPrefix = {
					type = "string",
					required = true
				}
			}
		},
		default = DEFAULT_CONFIG.equipmentCategories
	},
	prerequisites = {
		type = "table",
		required = false,
		default = {}
	}
}

-- Validation utility functions
local function deepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	
	return copy
end

local function validateString(value, schema)
	if type(value) ~= "string" then
		if schema.default then
			return schema.default
		end
		return ""
	end
	
	if schema.enum then
		local valid = false
		for _, allowed in ipairs(schema.enum) do
			if value == allowed then
				valid = true
				break
			end
		end
		
		if not valid then
			return schema.default or schema.enum[1]
		end
	end
	
	if schema.pattern then
		if not string.match(value, schema.pattern) then
			return schema.default or ""
		end
	end
	
	return value
end

local function validateNumber(value, schema)
	if type(value) ~= "number" then
		if schema.default then
			return schema.default
		end
		return 0
	end
	
	if schema.min and value < schema.min then
		value = schema.min
	end
	
	if schema.max and value > schema.max then
		value = schema.max
	end
	
	if schema.integer and value ~= math.floor(value) then
		value = math.floor(value + 0.5)  -- Round to nearest integer
	end
	
	return value
end

local function validateBoolean(value, schema)
	if type(value) ~= "boolean" then
		if schema.default ~= nil then
			return schema.default
		end
		return false
	end
	
	return value
end

local function validateColor3(value, schema)
	if typeof(value) == "Color3" then
		return value
	end
	
	-- Handle table representation {r, g, b} or {r=r, g=g, b=b}
	if type(value) == "table" then
		if value.r and value.g and value.b then
			return Color3.new(value.r, value.g, value.b)
		elseif #value >= 3 and type(value[1]) == "number" then
			return Color3.new(value[1], value[2], value[3])
		end
	end
	
	if schema.default then
		return schema.default
	end
	
	return Color3.new(1, 1, 1)  -- White default
end

local function validateTable(value, schema)
	if type(value) ~= "table" then
		return deepCopy(schema.default or {})
	end
	
	if schema.properties then
		local result = {}
		
		-- Validate each property according to its schema
		for propName, propSchema in pairs(schema.properties) do
			local propValue = value[propName]
			
			if propValue ~= nil or propSchema.required then
				result[propName] = validateValue(propValue, propSchema)
			end
		end
		
		-- Add any additional properties not in the schema but in the value
		for key, val in pairs(value) do
			if not schema.properties[key] then
				result[key] = val
			end
		end
		
		return result
	end
	
	return value
end

local function validateArray(value, schema)
	if type(value) ~= "table" then
		return deepCopy(schema.default or {})
	end
	
	local result = {}
	
	if schema.itemSchema then
		for i, item in ipairs(value) do
			result[i] = validateValue(item, schema.itemSchema)
		end
	else
		-- If no item schema, copy as-is
		for i, item in ipairs(value) do
			result[i] = item
		end
	end
	
	return result
end

-- Main validation function
function validateValue(value, schema)
	if not schema then
		return value
	end
	
	if value == nil and schema.default ~= nil then
		return deepCopy(schema.default)
	end
	
	if schema.type == "string" then
		return validateString(value, schema)
	elseif schema.type == "number" then
		return validateNumber(value, schema)
	elseif schema.type == "boolean" then
		return validateBoolean(value, schema)
	elseif schema.type == "Color3" then
		return validateColor3(value, schema)
	elseif schema.type == "table" then
		return validateTable(value, schema)
	elseif schema.type == "array" then
		return validateArray(value, schema)
	end
	
	return value
end

-- Public API

--[[
	Validate a configuration against the schema
	@param config - The configuration to validate
	@return validated configuration with defaults applied where needed
]]
function ConfigurationSchema.validate(config)
	if not config then
		return deepCopy(DEFAULT_CONFIG)
	end
	
	return validateValue(config, {type = "table", properties = SCHEMA})
end

--[[
	Get the default configuration
	@return The default configuration
]]
function ConfigurationSchema.getDefault()
	return deepCopy(DEFAULT_CONFIG)
end

--[[
	Get the schema definition
	@return The schema definition
]]
function ConfigurationSchema.getSchema()
	return deepCopy(SCHEMA)
end

return ConfigurationSchema
