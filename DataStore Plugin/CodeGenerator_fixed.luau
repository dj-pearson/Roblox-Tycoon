--[[
    CodeGenerator.luau
    Part of DataStore Manager Pro
    
    This module provides functionality for generating code templates based on schemas,
    helping developers quickly implement DataStore access patterns.
]]

local SchemaManager = require(script.Parent.SchemaManager)

local CodeGenerator = {}

-- Templates for different code types
CodeGenerator.templates = {
    server = {},
    client = {},
    module = {},
    docs = {}
}

-- Define global variables used in templates
local TYPE_DEFINITIONS = ""
local VALIDATION_CODE = ""
local DEFAULT_DATA = ""
local ACCESSOR_CODE = ""

-- Initialize the code generator
function CodeGenerator.initialize()
    print("CodeGenerator: Initializing module...")
    return true
end

-- Generate a module based on a schema
function CodeGenerator.generateModuleFromSchema(schemaName, options)
    local schema = SchemaManager.getSchema(schemaName)
    if not schema then
        return nil, "Schema not found: " .. schemaName
    end
    
    options = options or {}
    local template = options.template or "default"
    local moduleType = options.moduleType or "module"
    
    -- Generate code based on template and module type
    if moduleType == "server" then
        return CodeGenerator.generateServerCode(schema, template, options)
    elseif moduleType == "client" then
        return CodeGenerator.generateClientCode(schema, template, options)
    elseif moduleType == "module" then
        return CodeGenerator.generateModuleCode(schema, template, options)
    elseif moduleType == "docs" then
        return CodeGenerator.generateDocumentation(schema, template, options)
    else
        return nil, "Invalid module type: " .. moduleType
    end
end

-- Generate server-side DataStore code
function CodeGenerator.generateServerCode(schema, template, options)
    local templateCode = CodeGenerator.templates.server[template] or CodeGenerator.templates.server.default
    
    if not templateCode then
        return nil, "Template not found: " .. template
    end
    
    -- Replace template variables with schema-specific code
    local code = templateCode
    code = code:gsub("{{SCHEMA_NAME}}", schema.name)
    code = code:gsub("{{DATA_STORE_NAME}}", options.dataStoreName or schema.name .. "Store")
    
    -- Generate validation code
    local validationCode = CodeGenerator.generateValidationCode(schema)
    code = code:gsub("{{VALIDATION_CODE}}", validationCode)
    
    -- Generate default data
    local defaultDataCode = CodeGenerator.generateDefaultDataCode(schema)
    code = code:gsub("{{DEFAULT_DATA}}", defaultDataCode)
    
    -- Add metadata
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    code = code:gsub("{{GENERATED_TIMESTAMP}}", timestamp)
    code = code:gsub("{{SCHEMA_VERSION}}", schema.version or "1.0")
    
    return code
end

-- Generate client-side code for interacting with DataStore
function CodeGenerator.generateClientCode(schema, template, options)
    local templateCode = CodeGenerator.templates.client[template] or CodeGenerator.templates.client.default
    
    if not templateCode then
        return nil, "Template not found: " .. template
    end
    
    -- Replace template variables with schema-specific code
    local code = templateCode
    code = code:gsub("{{SCHEMA_NAME}}", schema.name)
    
    -- Generate type definitions for client
    local typeDefinitions = CodeGenerator.generateTypeDefinitions(schema)
    code = code:gsub("{{TYPE_DEFINITIONS}}", typeDefinitions)
    
    -- Add metadata
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    code = code:gsub("{{GENERATED_TIMESTAMP}}", timestamp)
    code = code:gsub("{{SCHEMA_VERSION}}", schema.version or "1.0")
    
    return code
end

-- Generate module code for handling data
function CodeGenerator.generateModuleCode(schema, template, options)
    local templateCode = CodeGenerator.templates.module[template] or CodeGenerator.templates.module.default
    
    if not templateCode then
        return nil, "Template not found: " .. template
    end
    
    -- Replace template variables with schema-specific code
    local code = templateCode
    code = code:gsub("{{SCHEMA_NAME}}", schema.name)
    
    -- Generate field accessors
    local accessors = CodeGenerator.generateFieldAccessors(schema)
    code = code:gsub("{{ACCESSOR_CODE}}", accessors)
    
    -- Generate type definitions
    local typeDefinitions = CodeGenerator.generateTypeDefinitions(schema)
    code = code:gsub("{{TYPE_DEFINITIONS}}", typeDefinitions)
    
    -- Add metadata
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    code = code:gsub("{{GENERATED_TIMESTAMP}}", timestamp)
    code = code:gsub("{{SCHEMA_VERSION}}", schema.version or "1.0")
    
    return code
end

-- Generate documentation
function CodeGenerator.generateDocumentation(schema, template, options)
    local templateCode = CodeGenerator.templates.docs[template] or CodeGenerator.templates.docs.default
    
    if not templateCode then
        return nil, "Template not found: " .. template
    end
    
    -- Replace template variables with schema-specific code
    local code = templateCode
    code = code:gsub("{{SCHEMA_NAME}}", schema.name)
    
    -- Generate field documentation
    local fieldDocs = CodeGenerator.generateFieldDocumentation(schema)
    code = code:gsub("{{FIELD_DOCUMENTATION}}", fieldDocs)
    
    -- Generate method documentation
    local methodDocs = CodeGenerator.generateMethodDocumentation(schema)
    code = code:gsub("{{METHOD_DOCUMENTATION}}", methodDocs)
    
    -- Add metadata
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    code = code:gsub("{{GENERATED_TIMESTAMP}}", timestamp)
    code = code:gsub("{{SCHEMA_VERSION}}", schema.version or "1.0")
    
    return code
end

-- Generate validation code for schema
function CodeGenerator.generateValidationCode(schema)
    local lines = {}
    
    table.insert(lines, "-- Validate data against schema")
    table.insert(lines, "local function validateData(data)")
    table.insert(lines, "    if type(data) ~= \"table\" then")
    table.insert(lines, "        return false, \"Data must be a table\"")
    table.insert(lines, "    end")
    
    -- Generate validation for each field
    for fieldName, fieldInfo in pairs(schema.fields or {}) do
        if fieldInfo.required then
            table.insert(lines, "    ")
            table.insert(lines, "    -- Validate " .. fieldName)
            table.insert(lines, "    if data." .. fieldName .. " == nil then")
            table.insert(lines, "        return false, \"Required field '" .. fieldName .. "' is missing\"")
            table.insert(lines, "    end")
            
            -- Add type validation
            if fieldInfo.type then
                table.insert(lines, "    if data." .. fieldName .. " ~= nil and type(data." .. fieldName .. ") ~= \"" .. fieldInfo.type .. "\" then")
                table.insert(lines, "        return false, \"Field '" .. fieldName .. "' must be of type '" .. fieldInfo.type .. "'\"")
                table.insert(lines, "    end")
            end
            
            -- Add validation for arrays
            if fieldInfo.isArray then
                table.insert(lines, "    if data." .. fieldName .. " ~= nil and type(data." .. fieldName .. ") == \"table\" then")
                table.insert(lines, "        for i, value in ipairs(data." .. fieldName .. ") do")
                table.insert(lines, "            if type(value) ~= \"" .. (fieldInfo.arrayType or "any") .. "\" then")
                table.insert(lines, "                return false, \"Array '" .. fieldName .. "' must contain items of type '" .. (fieldInfo.arrayType or "any") .. "'\"")
                table.insert(lines, "            end")
                table.insert(lines, "        end")
                table.insert(lines, "    end")
            end
            
            -- Add custom validation if provided
            if fieldInfo.validation then
                table.insert(lines, "    -- Custom validation for " .. fieldName)
                table.insert(lines, "    " .. fieldInfo.validation)
            end
        end
    end
    
    table.insert(lines, "    ")
    table.insert(lines, "    return true")
    table.insert(lines, "end")
    
    return table.concat(lines, "\n")
end

-- Generate default data creation code for schema
function CodeGenerator.generateDefaultDataCode(schema)
    local lines = {}
    
    table.insert(lines, "-- Create default data structure")
    table.insert(lines, "local function createDefaultData()")
    table.insert(lines, "    return {")
    
    -- Generate default value for each field
    for fieldName, fieldInfo in pairs(schema.fields or {}) do
        local defaultValue = "nil"
        
        if fieldInfo.default ~= nil then
            if fieldInfo.type == "string" then
                defaultValue = "\"" .. tostring(fieldInfo.default) .. "\""
            elseif fieldInfo.type == "number" or fieldInfo.type == "boolean" then
                defaultValue = tostring(fieldInfo.default)
            elseif fieldInfo.type == "table" and fieldInfo.isArray then
                defaultValue = "{}"
            elseif fieldInfo.type == "table" then
                defaultValue = "{}"
            end
        else
            -- No explicit default, use type-appropriate empty value
            if fieldInfo.type == "string" then
                defaultValue = "\"\""
            elseif fieldInfo.type == "number" then
                defaultValue = "0"
            elseif fieldInfo.type == "boolean" then
                defaultValue = "false"
            elseif fieldInfo.type == "table" then
                defaultValue = "{}"
            end
        end
        
        table.insert(lines, "        " .. fieldName .. " = " .. defaultValue .. ",")
    end
    
    table.insert(lines, "    }")
    table.insert(lines, "end")
    
    return table.concat(lines, "\n")
end

-- Generate field accessor methods
function CodeGenerator.generateFieldAccessors(schema)
    local lines = {}
    
    -- Generate accessor methods for each field
    for fieldName, fieldInfo in pairs(schema.fields or {}) do
        local capitalized = fieldName:sub(1, 1):upper() .. fieldName:sub(2)
        
        -- Getter method
        table.insert(lines, "-- Get " .. fieldName)
        table.insert(lines, "function DataModule:get" .. capitalized .. "()")
        table.insert(lines, "    return self.data." .. fieldName)
        table.insert(lines, "end")
        table.insert(lines, "")
        
        -- Setter method
        table.insert(lines, "-- Set " .. fieldName)
        table.insert(lines, "function DataModule:set" .. capitalized .. "(value)")
        
        -- Add type validation
        if fieldInfo.type then
            table.insert(lines, "    if value ~= nil and type(value) ~= \"" .. fieldInfo.type .. "\" then")
            table.insert(lines, "        warn(\"Type mismatch: " .. fieldName .. " must be " .. fieldInfo.type .. "\", type(value))")
            table.insert(lines, "        return false")
            table.insert(lines, "    end")
        end
        
        -- Add range validation for numbers
        if fieldInfo.type == "number" and (fieldInfo.min ~= nil or fieldInfo.max ~= nil) then
            if fieldInfo.min ~= nil then
                table.insert(lines, "    if value ~= nil and value < " .. fieldInfo.min .. " then")
                table.insert(lines, "        warn(\"Value out of range: " .. fieldName .. " must be at least " .. fieldInfo.min .. "\")")
                table.insert(lines, "        return false")
                table.insert(lines, "    end")
            end
            
            if fieldInfo.max ~= nil then
                table.insert(lines, "    if value ~= nil and value > " .. fieldInfo.max .. " then")
                table.insert(lines, "        warn(\"Value out of range: " .. fieldName .. " must be at most " .. fieldInfo.max .. "\")")
                table.insert(lines, "        return false")
                table.insert(lines, "    end")
            end
        end
        
        -- Add custom validation if provided
        if fieldInfo.validation then
            table.insert(lines, "    -- Custom validation")
            table.insert(lines, "    " .. fieldInfo.validation:gsub("data%.", ""))
        end
        
        table.insert(lines, "    self.data." .. fieldName .. " = value")
        table.insert(lines, "    self:markDirty()")
        table.insert(lines, "    return true")
        table.insert(lines, "end")
    end
    
    return table.concat(lines, "\n")
end

-- Generate Luau type definitions
function CodeGenerator.generateTypeDefinitions(schema)
    local lines = {}
    
    table.insert(lines, "-- Type definitions")
    table.insert(lines, "type " .. schema.name .. "Data = {")
    
    -- Generate type definition for each field
    for fieldName, fieldInfo in pairs(schema.fields or {}) do
        local typeStr = ""
        
        if fieldInfo.type == "string" then
            typeStr = "string"
        elseif fieldInfo.type == "number" then
            typeStr = "number"
        elseif fieldInfo.type == "boolean" then
            typeStr = "boolean"
        elseif fieldInfo.type == "table" then
            if fieldInfo.isArray then
                typeStr = "{ " .. (fieldInfo.arrayType or "any") .. " }"
            else
                typeStr = "{ [string]: any }"
            end
        else
            typeStr = "any"
        end
        
        if not fieldInfo.required then
            typeStr = typeStr .. "?"
        end
        
        table.insert(lines, "    " .. fieldName .. ": " .. typeStr .. ",")
    end
    
    table.insert(lines, "}")
    
    return table.concat(lines, "\n")
end

-- Generate field documentation for schema
function CodeGenerator.generateFieldDocumentation(schema)
    local lines = {}
    
    table.insert(lines, "## Fields\n")
    
    -- Document each field
    for fieldName, fieldInfo in pairs(schema.fields or {}) do
        table.insert(lines, "### " .. fieldName)
        
        -- Add field type
        local typeInfo = fieldInfo.type or "any"
        if fieldInfo.isArray then
            typeInfo = "array of " .. (fieldInfo.arrayType or "any")
        end
        table.insert(lines, "- **Type**: " .. typeInfo)
        
        -- Add required status
        table.insert(lines, "- **Required**: " .. (fieldInfo.required and "Yes" or "No"))
        
        -- Add default value if provided
        if fieldInfo.default ~= nil then
            local defaultStr
            if fieldInfo.type == "string" then
                defaultStr = "\"" .. tostring(fieldInfo.default) .. "\""
            else
                defaultStr = tostring(fieldInfo.default)
            end
            table.insert(lines, "- **Default**: " .. defaultStr)
        end
        
        -- Add description if provided
        if fieldInfo.description then
            table.insert(lines, "\n" .. fieldInfo.description)
        end
        
        table.insert(lines, "")
    end
    
    return table.concat(lines, "\n")
end

-- Generate method documentation for schema
function CodeGenerator.generateMethodDocumentation(schema)
    local lines = {}
    
    table.insert(lines, "## Methods\n")
    
    -- Document accessor methods for each field
    for fieldName, fieldInfo in pairs(schema.fields or {}) do
        local capitalized = fieldName:sub(1, 1):upper() .. fieldName:sub(2)
        
        -- Getter method
        table.insert(lines, "### get" .. capitalized .. "()")
        table.insert(lines, "Gets the value of " .. fieldName .. ".\n")
        table.insert(lines, "```lua")
        table.insert(lines, "local value = dataModule:get" .. capitalized .. "()")
        table.insert(lines, "```\n")
        
        -- Setter method
        table.insert(lines, "### set" .. capitalized .. "(value)")
        table.insert(lines, "Sets the value of " .. fieldName .. ".\n")
        
        -- Document parameters
        local typeInfo = fieldInfo.type or "any"
        if fieldInfo.isArray then
            typeInfo = "array of " .. (fieldInfo.arrayType or "any")
        end
        table.insert(lines, "- **value** (" .. typeInfo .. "): The new value to set")
        
        if fieldInfo.type == "number" and (fieldInfo.min ~= nil or fieldInfo.max ~= nil) then
            local rangeText = "Must be "
            if fieldInfo.min ~= nil then
                rangeText = rangeText .. "at least " .. fieldInfo.min
            end
            if fieldInfo.min ~= nil and fieldInfo.max ~= nil then
                rangeText = rangeText .. " and "
            end
            if fieldInfo.max ~= nil then
                rangeText = rangeText .. "at most " .. fieldInfo.max
            end
            table.insert(lines, "  - " .. rangeText)
        end
        
        table.insert(lines, "\n```lua")
        table.insert(lines, "local success = dataModule:set" .. capitalized .. "(newValue)")
        table.insert(lines, "```\n")
    end
    
    -- Document utility methods
    table.insert(lines, "### save()")
    table.insert(lines, "Saves the data to the DataStore.\n")
    table.insert(lines, "```lua")
    table.insert(lines, "local success, errorMessage = dataModule:save()")
    table.insert(lines, "```\n")
    
    table.insert(lines, "### startAutoSave(interval)")
    table.insert(lines, "Starts auto-saving data at the specified interval.\n")
    table.insert(lines, "- **interval** (number): Time between saves, in seconds\n")
    table.insert(lines, "```lua")
    table.insert(lines, "dataModule:startAutoSave(30) -- Save every 30 seconds")
    table.insert(lines, "```\n")
    
    table.insert(lines, "### stopAutoSave()")
    table.insert(lines, "Stops auto-saving data.\n")
    table.insert(lines, "```lua")
    table.insert(lines, "dataModule:stopAutoSave()")
    table.insert(lines, "```\n")
    
    return table.concat(lines, "\n")
end

-- Server-side code template
CodeGenerator.templates.server.default = [[
--[[
    {{SCHEMA_NAME}} Server Module
    Generated by DataStore Manager Pro
    Schema Version: {{SCHEMA_VERSION}}
    Generated on: {{GENERATED_TIMESTAMP}}
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Initialize DataStore
local dataStore = DataStoreService:GetDataStore("{{DATA_STORE_NAME}}")
local playerData = {}

-- Validation functions
{{VALIDATION_CODE}}

-- Default data generation
{{DEFAULT_DATA}}

-- Server module
local ServerModule = {}

-- Load player data when they join
function ServerModule.playerAdded(player)
    local userId = tostring(player.UserId)
    
    -- Attempt to load data from DataStore
    local success, result = pcall(function()
        return dataStore:GetAsync(userId)
    end)
    
    if not success then
        warn("Failed to load data for player " .. player.Name .. ": " .. tostring(result))
        result = createDefaultData()
    elseif result == nil then
        -- No existing data, use default
        result = createDefaultData()
    end
    
    -- Validate data structure
    local isValid, errorMsg = validateData(result)
    if not isValid then
        warn("Data validation failed for player " .. player.Name .. ": " .. errorMsg)
        -- Repair or reset data if needed
        result = createDefaultData()
    end
    
    -- Store player data
    playerData[userId] = result
    
    return result
end

-- Save player data when they leave
function ServerModule.playerRemoving(player)
    local userId = tostring(player.UserId)
    local data = playerData[userId]
    
    if not data then
        return false
    end
    
    -- Attempt to save data to DataStore
    local success, result = pcall(function()
        dataStore:SetAsync(userId, data)
    end)
    
    if not success then
        warn("Failed to save data for player " .. player.Name .. ": " .. tostring(result))
        return false
    end
    
    -- Clear from memory
    playerData[userId] = nil
    
    return true
end

-- Get a player's data
function ServerModule.getPlayerData(player)
    local userId = tostring(player.UserId)
    return playerData[userId]
end

-- Update a player's data
function ServerModule.updatePlayerData(player, updateFunc)
    local userId = tostring(player.UserId)
    local data = playerData[userId]
    
    if not data then
        return false
    end
    
    -- Call update function to modify data
    local success, result = pcall(updateFunc, data)
    
    if not success then
        warn("Failed to update data for player " .. player.Name .. ": " .. tostring(result))
        return false
    end
    
    -- Validate updated data
    local isValid, errorMsg = validateData(data)
    if not isValid then
        warn("Updated data validation failed for player " .. player.Name .. ": " .. errorMsg)
        return false
    end
    
    return true
end

-- Force save all player data
function ServerModule.saveAllData()
    for userId, data in pairs(playerData) do
        local success, result = pcall(function()
            dataStore:SetAsync(userId, data)
        end)
        
        if not success then
            warn("Failed to save data for user " .. userId .. ": " .. tostring(result))
        end
    end
end

-- Set up player events
Players.PlayerAdded:Connect(ServerModule.playerAdded)
Players.PlayerRemoving:Connect(ServerModule.playerRemoving)

-- Save all data when server is shutting down
game:BindToClose(function()
    ServerModule.saveAllData()
end)

return ServerModule
]]

-- Client-side code template
CodeGenerator.templates.client.default = [[
--[[
    {{SCHEMA_NAME}} Client Module
    Generated by DataStore Manager Pro
    Schema Version: {{SCHEMA_VERSION}}
    Generated on: {{GENERATED_TIMESTAMP}}
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- Type definitions
{{TYPE_DEFINITIONS}}

-- Client module
local ClientModule = {}

-- Remote events for data synchronization
local remotes = ReplicatedStorage:WaitForChild("DataRemotes")
local requestData = remotes:WaitForChild("RequestData")
local receiveData = remotes:WaitForChild("ReceiveData")
local requestUpdate = remotes:WaitForChild("RequestUpdate")
local dataChanged = remotes:WaitForChild("DataChanged")

-- Store the current data
ClientModule.data = nil

-- Initialize client data
function ClientModule.initialize()
    -- Request initial data from server
    requestData:FireServer()
    
    -- Set up data event handlers
    receiveData.OnClientEvent:Connect(function(data)
        ClientModule.data = data
        ClientModule.onDataLoaded:Fire(data)
    end)
    
    dataChanged.OnClientEvent:Connect(function(field, value)
        if not ClientModule.data then return end
        ClientModule.data[field] = value
        ClientModule.onDataChanged:Fire(field, value)
    end)
    
    -- Create custom events
    ClientModule.onDataLoaded = Instance.new("BindableEvent")
    ClientModule.onDataChanged = Instance.new("BindableEvent")
    
    return true
end

-- Get a value from the data
function ClientModule.getValue(field)
    if not ClientModule.data then
        warn("Data not loaded yet")
        return nil
    end
    
    return ClientModule.data[field]
end

-- Request a data update
function ClientModule.updateValue(field, value)
    if not ClientModule.data then
        warn("Data not loaded yet")
        return false
    end
    
    -- Update local cache immediately (optimistic)
    ClientModule.data[field] = value
    
    -- Send update to server
    requestUpdate:FireServer(field, value)
    
    return true
end

-- Check if data is loaded
function ClientModule.isLoaded()
    return ClientModule.data ~= nil
end

-- Wait for data to be loaded
function ClientModule.waitForData()
    if ClientModule.data then
        return ClientModule.data
    end
    
    -- Wait for data to be loaded
    local connection
    local result = nil
    
    connection = ClientModule.onDataLoaded.Event:Connect(function(data)
        result = data
        connection:Disconnect()
    end)
    
    -- Yield until data is loaded
    while not result do
        task.wait(0.1)
    end
    
    return result
end

-- Clean up resources when no longer needed
function ClientModule.destroy()
    if ClientModule.onDataLoaded then
        ClientModule.onDataLoaded:Destroy()
    end
    
    if ClientModule.onDataChanged then
        ClientModule.onDataChanged:Destroy()
    end
end

return ClientModule
]]

-- Module code template
CodeGenerator.templates.module.default = [[
--[[
    {{SCHEMA_NAME}} Data Module
    Generated by DataStore Manager Pro
    Schema Version: {{SCHEMA_VERSION}}
    Generated on: {{GENERATED_TIMESTAMP}}
]]

local DataStoreService = game:GetService("DataStoreService")

-- Type definitions
{{TYPE_DEFINITIONS}}

-- Data module
local DataModule = {}
DataModule.__index = DataModule

-- Create a new data module instance
function DataModule.new(userId, dataStore)
    local self = setmetatable({}, DataModule)
    
    self.userId = userId
    self.dataStore = dataStore or DataStoreService:GetDataStore("{{SCHEMA_NAME}}Store")
    self.data = {}
    self.dirty = false
    self.autoSaveActive = false
    self.autoSaveInterval = 60 -- Default: 60 seconds
    
    return self
end

-- Load data from DataStore
function DataModule:load()
    -- Attempt to load data from DataStore
    local success, result = pcall(function()
        return self.dataStore:GetAsync(self.userId)
    end)
    
    if not success then
        warn("Failed to load data for user " .. self.userId .. ": " .. tostring(result))
        return false, "Failed to load data: " .. tostring(result)
    end
    
    if result then
        self.data = result
    else
        -- No existing data, use default
        self:resetToDefault()
    end
    
    return true
end

-- Save data to DataStore
function DataModule:save()
    if not self.dirty then
        return true, "No changes to save"
    end
    
    -- Attempt to save data to DataStore
    local success, result = pcall(function()
        self.dataStore:SetAsync(self.userId, self.data)
    end)
    
    if not success then
        warn("Failed to save data for user " .. self.userId .. ": " .. tostring(result))
        return false, "Failed to save data: " .. tostring(result)
    end
    
    self.dirty = false
    return true
end

-- Mark data as changed
function DataModule:markDirty()
    self.dirty = true
end

-- Reset to default values
function DataModule:resetToDefault()
    self.data = {
        -- Default values will be defined here
    }
    self:markDirty()
end

-- Start auto-save process
function DataModule:startAutoSave(interval)
    if self.autoSaveActive then
        self:stopAutoSave()
    end
    
    self.autoSaveInterval = interval or self.autoSaveInterval
    self.autoSaveActive = true
    
    task.spawn(function()
        while self.autoSaveActive do
            if self.dirty then
                self:save()
            end
            task.wait(self.autoSaveInterval)
        end
    end)
end

-- Stop auto-save
function DataModule:stopAutoSave()
    self.autoSaveActive = false
end

-- Field accessor methods
{{ACCESSOR_CODE}}

return DataModule
]]

-- Documentation template
CodeGenerator.templates.docs.default = [[
# {{SCHEMA_NAME}} Data Module Documentation
Generated by DataStore Manager Pro
Schema Version: {{SCHEMA_VERSION}}
Generated on: {{GENERATED_TIMESTAMP}}

## Overview
This documentation describes the {{SCHEMA_NAME}} data module, which manages data storage and retrieval.

{{FIELD_DOCUMENTATION}}

{{METHOD_DOCUMENTATION}}

## Usage Examples

### Server-side Example
```lua
local dataModule = require(ServerStorage.Modules.{{SCHEMA_NAME}}Module)

-- When a player joins
local function playerAdded(player)
    local playerData = dataModule.new(player.UserId)
    playerData:load()
    playerData:startAutoSave(30) -- Auto-save every 30 seconds
    
    -- Use the data
    local coins = playerData:getCoins()
    playerData:setCoins(coins + 100)
end
```

### Client-side Example
```lua
local dataClient = require(ReplicatedStorage.Modules.{{SCHEMA_NAME}}Client)

-- Initialize the client
dataClient.initialize()

-- Wait for data to load
local data = dataClient.waitForData()

-- Listen for changes
dataClient.onDataChanged.Event:Connect(function(field, value)
    print(field, "changed to", value)
end)

-- Request an update
dataClient.updateValue("coins", 500)
```
]]

return CodeGenerator
