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

-- Generate a module for DataStore operations
function CodeGenerator.generateModuleCode(schema, template, options)
    local templateCode = CodeGenerator.templates.module[template] or CodeGenerator.templates.module.default
    
    if not templateCode then
        return nil, "Template not found: " .. template
    end
    
    -- Replace template variables with schema-specific code
    local code = templateCode
    code = code:gsub("{{SCHEMA_NAME}}", schema.name)
    code = code:gsub("{{DATA_STORE_NAME}}", options.dataStoreName or schema.name .. "Store")
    
    -- Generate field accessors
    local accessors = CodeGenerator.generateAccessorCode(schema)
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

-- Generate API documentation
function CodeGenerator.generateDocumentation(schema, template, options)
    local templateCode = CodeGenerator.templates.docs[template] or CodeGenerator.templates.docs.default
    
    if not templateCode then
        return nil, "Template not found: " .. template
    end
    
    -- Replace template variables with schema-specific documentation
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

-- Generate default data initialization code
function CodeGenerator.generateDefaultDataCode(schema)
    local lines = {}
    
    table.insert(lines, "-- Create default data based on schema")
    table.insert(lines, "local function createDefaultData()")
    table.insert(lines, "    return {")
    
    -- Add default values for each field
    for fieldName, fieldInfo in pairs(schema.fields or {}) do
        local defaultValue = fieldInfo.default
        
        if defaultValue == nil then
            -- Generate a sensible default based on type
            if fieldInfo.type == "string" then
                defaultValue = "\"\""
            elseif fieldInfo.type == "number" then
                defaultValue = "0"
            elseif fieldInfo.type == "boolean" then
                defaultValue = "false"
            elseif fieldInfo.type == "table" then
                if fieldInfo.isArray then
                    defaultValue = "{}"
                else
                    defaultValue = "{}"
                end
            else
                defaultValue = "nil"
            end
        elseif fieldInfo.type == "string" then
            defaultValue = "\"" .. defaultValue .. "\""
        elseif type(defaultValue) == "table" then
            -- Serialize table default value
            local tableStr = "{"
            for k, v in pairs(defaultValue) do
                if type(k) == "string" then
                    tableStr = tableStr .. "[\"" .. k .. "\"] = "
                else
                    tableStr = tableStr .. "[" .. k .. "] = "
                end
                
                if type(v) == "string" then
                    tableStr = tableStr .. "\"" .. v .. "\", "
                else
                    tableStr = tableStr .. tostring(v) .. ", "
                end
            end
            tableStr = tableStr .. "}"
            defaultValue = tableStr
        end
        
        table.insert(lines, "        " .. fieldName .. " = " .. defaultValue .. ",")
    end
    
    table.insert(lines, "    }")
    table.insert(lines, "end")
    
    return table.concat(lines, "\n")
end

-- Generate accessor code for each field
function CodeGenerator.generateAccessorCode(schema)
    local lines = {}
    
    table.insert(lines, "-- Field accessor methods")
    
    -- Generate getter and setter methods for each field
    for fieldName, fieldInfo in pairs(schema.fields or {}) do
        local capFieldName = fieldName:sub(1,1):upper() .. fieldName:sub(2)
        
        -- Generate getter
        table.insert(lines, "")
        table.insert(lines, "-- Get " .. fieldName)
        table.insert(lines, "function DataModule:get" .. capFieldName .. "()")
        table.insert(lines, "    return self.data." .. fieldName)
        table.insert(lines, "end")
        
        -- Generate setter
        table.insert(lines, "")
        table.insert(lines, "-- Set " .. fieldName)
        table.insert(lines, "function DataModule:set" .. capFieldName .. "(value)")
        
        -- Add type validation
        if fieldInfo.type then
            table.insert(lines, "    if type(value) ~= \"" .. fieldInfo.type .. "\" then")
            table.insert(lines, "        warn(\"Invalid type for '" .. fieldName .. "'. Expected '" .. fieldInfo.type .. "', got '\" .. type(value) .. \"'\")")
            table.insert(lines, "        return false")
            table.insert(lines, "    end")
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

-- Generate field documentation
function CodeGenerator.generateFieldDocumentation(schema)
    local lines = {}
    
    table.insert(lines, "## Fields")
    table.insert(lines, "")
    
    -- Generate documentation for each field
    for fieldName, fieldInfo in pairs(schema.fields or {}) do
        table.insert(lines, "### " .. fieldName)
        table.insert(lines, "")
        table.insert(lines, "- **Type**: " .. (fieldInfo.type or "any"))
        table.insert(lines, "- **Required**: " .. (fieldInfo.required and "Yes" or "No"))
        
        if fieldInfo.description then
            table.insert(lines, "- **Description**: " .. fieldInfo.description)
        end
        
        if fieldInfo.default ~= nil then
            local defaultStr = tostring(fieldInfo.default)
            if type(fieldInfo.default) == "table" then
                defaultStr = "{...}"  -- Simplified for tables
            end
            table.insert(lines, "- **Default**: " .. defaultStr)
        end
        
        table.insert(lines, "")
    end
    
    return table.concat(lines, "\n")
end

-- Generate method documentation
function CodeGenerator.generateMethodDocumentation(schema)
    local lines = {}
    
    table.insert(lines, "## Methods")
    table.insert(lines, "")
    
    -- Document standard methods
    table.insert(lines, "### load(playerId: string): boolean")
    table.insert(lines, "")
    table.insert(lines, "Loads the player's data from the DataStore. Returns true if successful, false otherwise.")
    table.insert(lines, "")
    
    table.insert(lines, "### save(): boolean")
    table.insert(lines, "")
    table.insert(lines, "Saves the player's data to the DataStore. Returns true if successful, false otherwise.")
    table.insert(lines, "")
    
    -- Document accessors for each field
    for fieldName, fieldInfo in pairs(schema.fields or {}) do
        local capFieldName = fieldName:sub(1,1):upper() .. fieldName:sub(2)
        
        -- Getter
        table.insert(lines, "### get" .. capFieldName .. "(): " .. (fieldInfo.type or "any"))
        table.insert(lines, "")
        table.insert(lines, "Returns the value of `" .. fieldName .. "`.")
        table.insert(lines, "")
        
        -- Setter
        table.insert(lines, "### set" .. capFieldName .. "(value: " .. (fieldInfo.type or "any") .. "): boolean")
        table.insert(lines, "")
        table.insert(lines, "Sets the value of `" .. fieldName .. "`. Returns true if successful, false otherwise.")
        table.insert(lines, "")
    end
    
    return table.concat(lines, "\n")
end

-- Define default templates
-- Server-side code template
CodeGenerator.templates.server.default = [[
--[[
    {{SCHEMA_NAME}} Server DataStore Module
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
    
    return true
end

-- Save player data when they leave
function ServerModule.playerRemoving(player)
    local userId = tostring(player.UserId)
    local data = playerData[userId]
    
    if not data then
        return false
    end
    
    -- Save data to DataStore
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

-- Event handlers
ClientModule.events = {}
ClientModule.callbacks = {}
ClientModule.data = nil

-- Initialize client module
function ClientModule.initialize()
    -- Connect to server events
    local remoteEvents = ReplicatedStorage:WaitForChild("DataEvents")
    local dataUpdated = remoteEvents:WaitForChild("DataUpdated")
    
    dataUpdated.OnClientEvent:Connect(function(data)
        ClientModule.data = data
        -- Call registered callbacks
        for _, callback in ipairs(ClientModule.callbacks) do
            callback(data)
        end
    end)
    
    return true
end

-- Register a callback for data updates
function ClientModule.onDataUpdated(callback)
    table.insert(ClientModule.callbacks, callback)
    
    -- Call immediately if data is already loaded
    if ClientModule.data then
        callback(ClientModule.data)
    end
    
    return true
end

-- Request specific data update from server
function ClientModule.requestUpdate(field)
    local remoteEvents = ReplicatedStorage:WaitForChild("DataEvents")
    local requestUpdate = remoteEvents:WaitForChild("RequestUpdate")
    
    requestUpdate:FireServer(field)
    
    return true
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

-- Create module
local DataModule = {
    dataStoreName = "{{DATA_STORE_NAME}}",
    loaded = false,
    dirty = false,
    data = {},
    backupData = nil,
    autoSaveInterval = 120, -- 2 minutes
    autoSaveActive = false
}
DataModule.__index = DataModule

-- Create a new instance of the data module
function DataModule.new(key)
    local self = setmetatable({}, DataModule)
    self.key = key
    self.dataStore = DataStoreService:GetDataStore(self.dataStoreName)
    self.data = {}
    return self
end

-- Load data from DataStore
function DataModule:load()
    if self.loaded then
        return true
    end
    
    local success, result = pcall(function()
        return self.dataStore:GetAsync(self.key)
    end)
    
    if not success then
        warn("Failed to load data for key " .. self.key .. ": " .. tostring(result))
        return false
    end
    
    -- Initialize with default or loaded data
    if result == nil then
        self:initializeDefaultData()
    else
        self.data = result
        -- Create a backup of initial data
        self.backupData = table.clone(result)
    end
    
    self.loaded = true
    self.dirty = false
    
    -- Start auto-save if enabled
    if self.autoSaveActive then
        self:startAutoSave()
    end
    
    return true
end

-- Save data to DataStore
function DataModule:save()
    if not self.loaded or not self.dirty then
        return true
    end
    
    local success, result = pcall(function()
        self.dataStore:SetAsync(self.key, self.data)
    end)
    
    if not success then
        warn("Failed to save data for key " .. self.key .. ": " .. tostring(result))
        return false
    end
    
    self.dirty = false
    -- Update backup
    self.backupData = table.clone(self.data)
    
    return true
end

-- Initialize default data
function DataModule:initializeDefaultData()
    self.data = {
        -- Default values will be inserted here based on schema
    }
    self.backupData = table.clone(self.data)
end

-- Mark data as dirty (needs saving)
function DataModule:markDirty()
    self.dirty = true
end

-- Start auto-save interval
function DataModule:startAutoSave()
    if self.autoSaveActive then
        return
    end
    
    self.autoSaveActive = true
    
    -- Use task.spawn for auto-save loop
    task.spawn(function()
        while self.autoSaveActive do
            task.wait(self.autoSaveInterval)
            
            if self.dirty then
                self:save()
            end
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

This document describes the usage and API for the {{SCHEMA_NAME}} data module.

## Overview

The {{SCHEMA_NAME}} module provides a structured interface for storing and retrieving 
data from Roblox DataStores. It enforces a schema to ensure data integrity and provides
helper methods for data operations.

{{FIELD_DOCUMENTATION}}

{{METHOD_DOCUMENTATION}}

## Example Usage

```lua
-- Create a new data module for a player
local playerData = DataModule.new("Player_" .. player.UserId)

-- Load data from DataStore
local success = playerData:load()
if not success then
    warn("Failed to load player data")
    return
end

-- Use accessor methods
local coins = playerData:getCoins()
playerData:setCoins(coins + 100)

-- Save data
playerData:save()
```
]]

return CodeGenerator
