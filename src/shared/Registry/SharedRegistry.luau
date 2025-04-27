--!strict
--[[
    SharedRegistry.luau
    
    Shared registry implementation for registering components that need to be
    accessible from both client and server contexts. This registry provides a
    consistent API and component access pattern across both environments.
    
    Features:
    - Unified registry for cross-context components
    - Automatic context detection
    - Type safety with strong typing
    - Global modules and utilities registration
    - Common toolkits and utility collections
    
    Author: Created April 27, 2025
]]

local RunService = game:GetService("RunService")

-- Import required modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryBase = require(SharedModules:WaitForChild("Registry"):WaitForChild("RegistryBase"))

-- Determine current execution context
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

-- Type definitions
export type SharedContext = "server" | "client" | "both" | "unknown"

export type SharedModuleInfo = {
    id: string,
    context: SharedContext,
    tags: {string},
    isUtility: boolean,
    category: string?,
    usageCount: number
}

-- Module implementation
local SharedRegistry = {}
SharedRegistry.__index = SharedRegistry

-- Create a new shared registry instance
function SharedRegistry.new(name)
    -- Create base registry
    local baseRegistry = RegistryBase.new(name or "SharedRegistry", {
        logLevel = 2,
        allowOverrides = true,
        autoInit = true,
        strict = false -- Less strict to allow cross-context usage
    })
    
    -- Create shared registry as an extension of the base registry
    local self = setmetatable({
        -- Inherit all base registry properties
        name = baseRegistry.name,
        components = baseRegistry.components,
        options = baseRegistry.options,
        
        -- Shared-specific properties
        currentContext = isServer and "server" or (isClient and "client" or "unknown"),
        utilities = {},
        categories = {},
        contextModules = {
            server = {},
            client = {},
            both = {}
        }
    }, SharedRegistry)
    
    -- Copy all methods from base registry
    for key, value in pairs(baseRegistry) do
        if type(value) == "function" and not self[key] then
            self[key] = value
        end
    end
    
    -- Initialize shared registry
    self:initialize()
    
    print("[SharedRegistry] Created new registry:", name, "in context:", self.currentContext)
    
    return self
end

--[[ Private Utility Functions ]]--

-- Detect component context compatibility
local function detectContext(component)
    -- Check explicit context property
    if type(component) == "table" and component.CONTEXT then
        if component.CONTEXT == "server" or 
           component.CONTEXT == "client" or 
           component.CONTEXT == "both" then
            return component.CONTEXT
        end
    end
    
    -- Check for client/server specific methods
    if type(component) == "table" then
        -- Likely client-specific if has UI methods
        if component.render or component.mount or component.createUI then
            return "client"
        end
        
        -- Likely server-specific if has these methods
        if component.onServerEvent or component.processServerRequest then
            return "server"
        end
        
        -- Check for context-specific properties
        if component.clientOnly then
            return "client"
        elseif component.serverOnly then
            return "server"
        end
    end
    
    -- Default to both contexts
    return "both"
end

-- Detect if component is a utility module
local function isUtilityModule(component)
    -- Check explicit flag
    if type(component) == "table" and component.IS_UTILITY ~= nil then
        return component.IS_UTILITY
    end
    
    -- Check for function-heavy modules
    if type(component) == "table" then
        local functionCount = 0
        local totalCount = 0
        
        for k, v in pairs(component) do
            if type(k) == "string" and k:sub(1, 1) ~= "_" then
                totalCount += 1
                if type(v) == "function" then
                    functionCount += 1
                end
            end
        end
        
        -- If most exports are functions, likely a utility
        if totalCount > 0 and functionCount / totalCount > 0.7 then
            return true
        end
    end
    
    return false
end

-- Detect component category
local function detectCategory(component, id)
    -- Check explicit category
    if type(component) == "table" and component.CATEGORY then
        return component.CATEGORY
    end
    
    -- Try to detect from id
    if id then
        local lowerName = string.lower(id)
        
        -- Common categories
        if string.find(lowerName, "util") then
            return "utility"
        elseif string.find(lowerName, "type") then
            return "types"
        elseif string.find(lowerName, "const") then
            return "constants"
        elseif string.find(lowerName, "config") then
            return "configuration"
        elseif string.find(lowerName, "helper") then
            return "helpers"
        elseif string.find(lowerName, "math") then
            return "math"
        elseif string.find(lowerName, "format") or string.find(lowerName, "string") then
            return "formatting"
        elseif string.find(lowerName, "validator") or string.find(lowerName, "validate") then
            return "validation"
        end
    end
    
    return "general"
end

-- Set up component tracking
local function setupTracking(self)
    -- Track component usage to help detect unused modules
    local originalGet = self.get
    self.get = function(registry, id, minVersion)
        local component = originalGet(registry, id, minVersion)
        
        -- Track usage if component found
        if component and self.components[id] then
            -- Increment usage count in shared module info
            local contextTable = self.currentContext == "server" and "server" or "client"
            if self.contextModules[contextTable][id] then
                self.contextModules[contextTable][id].usageCount += 1
            end
        end
        
        return component
    end
end

--[[ Shared Registry API Implementation ]]--

-- Initialize the shared registry
function SharedRegistry:initialize()
    -- Set up component usage tracking
    setupTracking(self)
    
    return true
end

-- Register a shared component with context information
function SharedRegistry:registerShared(id, component, options)
    -- Validate parameters
    if not id or not component then
        warn("[SharedRegistry] Failed to register shared component: Invalid parameters")
        return false
    end
    
    options = options or {}
    
    -- First register as a normal component
    if not self:register(id, component, options.version) then
        return false
    end
    
    -- Detect context if not provided
    local context = options.context or detectContext(component)
    
    -- Set context tag
    self:setTag(id, "context:" .. context, true)
    
    -- Check if this is a utility module
    local isUtility = options.isUtility
    if isUtility == nil then
        isUtility = isUtilityModule(component)
    end
    
    if isUtility then
        self:setTag(id, "utility", true)
    end
    
    -- Detect category if not provided
    local category = options.category or detectCategory(component, id)
    if category then
        self:setTag(id, "category:" .. category, true)
        
        -- Track category
        if not self.categories[category] then
            self.categories[category] = {}
        end
        table.insert(self.categories[category], id)
    end
    
    -- Create shared module info
    local moduleInfo = {
        id = id,
        context = context,
        tags = options.tags or {},
        isUtility = isUtility,
        category = category,
        usageCount = 0
    }
    
    -- Store in context mapping
    if context == "both" then
        self.contextModules.both[id] = moduleInfo
    elseif context == "server" then
        self.contextModules.server[id] = moduleInfo
    elseif context == "client" then
        self.contextModules.client[id] = moduleInfo
    end
    
    -- Add to utilities if applicable
    if isUtility then
        self.utilities[id] = component
    end
    
    return true
end

-- Check if a component is compatible with current context
function SharedRegistry:isContextCompatible(id)
    if not id or not self.components[id] then
        return false
    end
    
    -- Check tags for context
    local serverCompatible = self.components[id].tags and 
                             (self.components[id].tags["context:server"] or 
                              self.components[id].tags["context:both"])
                              
    local clientCompatible = self.components[id].tags and 
                             (self.components[id].tags["context:client"] or 
                              self.components[id].tags["context:both"])
    
    if self.currentContext == "server" then
        return serverCompatible
    elseif self.currentContext == "client" then
        return clientCompatible
    end
    
    -- Unknown context
    return false
end

-- Get a component with context check
function SharedRegistry:getContextSafe(id, minVersion)
    if not id then
        return nil
    end
    
    -- Check context compatibility
    if not self:isContextCompatible(id) then
        warn("[SharedRegistry] Component", id, "is not compatible with current context:", self.currentContext)
        return nil
    end
    
    -- Get component normally
    return self:get(id, minVersion)
end

-- Get a utility function directly
function SharedRegistry:getUtility(id, functionName)
    -- Get utility module
    local utilModule = self:get(id)
    if not utilModule then
        return nil
    end
    
    -- If no function name, return the whole module
    if not functionName then
        return utilModule
    end
    
    -- Return specific function
    if type(utilModule) == "table" and type(utilModule[functionName]) == "function" then
        return utilModule[functionName]
    end
    
    return nil
end

-- Get components by category
function SharedRegistry:getByCategory(category)
    if not category or not self.categories[category] then
        return {}
    end
    
    local result = {}
    
    for _, id in ipairs(self.categories[category]) do
        -- Only include context-compatible components
        if self:isContextCompatible(id) then
            table.insert(result, {
                id = id,
                component = self:get(id)
            })
        end
    end
    
    return result
end

-- Register multiple components from a table
function SharedRegistry:registerMany(components)
    if not components or type(components) ~= "table" then
        return false
    end
    
    local count = 0
    
    for id, component in pairs(components) do
        if self:registerShared(id, component) then
            count += 1
        end
    end
    
    return count
end

-- Get usage statistics
function SharedRegistry:getUsageStats()
    local stats = {
        components = {
            total = 0,
            byContext = {
                server = 0,
                client = 0,
                both = 0
            },
            byCategory = {}
        },
        usage = {
            used = 0,
            unused = 0,
            byContext = {
                server = { used = 0, unused = 0 },
                client = { used = 0, unused = 0 },
                both = { used = 0, unused = 0 }
            }
        }
    }
    
    -- Count by context and category
    for id, info in pairs(self.components) do
        stats.components.total += 1
        
        -- Count by context
        for contextTag, _ in pairs(info.tags or {}) do
            if contextTag == "context:server" then
                stats.components.byContext.server += 1
            elseif contextTag == "context:client" then
                stats.components.byContext.client += 1
            elseif contextTag == "context:both" then
                stats.components.byContext.both += 1
            end
        end
        
        -- Count by category
        for tag, _ in pairs(info.tags or {}) do
            if string.find(tag, "category:") then
                local category = string.sub(tag, 10)
                if not stats.components.byCategory[category] then
                    stats.components.byCategory[category] = 0
                end
                stats.components.byCategory[category] += 1
            end
        end
    end
    
    -- Count usage
    local function countContextUsage(contextMap)
        local used, unused = 0, 0
        for _, info in pairs(contextMap) do
            if info.usageCount > 0 then
                used += 1
            else
                unused += 1
            end
        end
        return used, unused
    end
    
    local serverUsed, serverUnused = countContextUsage(self.contextModules.server)
    local clientUsed, clientUnused = countContextUsage(self.contextModules.client)
    local bothUsed, bothUnused = countContextUsage(self.contextModules.both)
    
    stats.usage.byContext.server.used = serverUsed
    stats.usage.byContext.server.unused = serverUnused
    stats.usage.byContext.client.used = clientUsed
    stats.usage.byContext.client.unused = clientUnused
    stats.usage.byContext.both.used = bothUsed
    stats.usage.byContext.both.unused = bothUnused
    
    stats.usage.used = serverUsed + clientUsed + bothUsed
    stats.usage.unused = serverUnused + clientUnused + bothUnused
    
    return stats
end

-- Build shared registry singleton
local SharedRegistryInstance = nil

-- Create singleton instance
local function createSingleton()
    -- Create instance if doesn't exist
    if not SharedRegistryInstance then
        SharedRegistryInstance = SharedRegistry.new("GlobalSharedRegistry")
    end
    
    return SharedRegistryInstance
end

-- Get singleton instance
local function getInstance()
    return SharedRegistryInstance or createSingleton()
end

return {
    new = SharedRegistry.new,
    get = getInstance
}
