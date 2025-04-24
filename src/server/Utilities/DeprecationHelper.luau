--!strict
--[[
    DeprecationHelper.luau
    
    Helper module for implementing deprecation notices and wrappers
    Part of Phase 5: Deprecate Old Scripts
    
    Created: April 23, 2025
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Configuration
local DEPRECATION_CONFIG = {
    DeprecationDate = "June 30, 2025", -- When the old scripts will be fully removed
    NewSystemDocumentation = "https://devforum.roblox.com/t/gym-automation-system-documentation", -- Replace with your actual documentation link
    LogDeprecatedCalls = true,
    ShowWarnings = true,
    DetailLevel = 2, -- 0: None, 1: Basic, 2: Detailed
    TelemetryEnabled = RunService:IsStudio() -- Only collect telemetry in Studio
}

-- The deprecation helper module
local DeprecationHelper = {}

-- Internal state
local _deprecationLogCount = {}
local _deprecationFirstCalled = {}

-- Data structure for collecting telemetry
local _telemetryData = {
    DeprecatedFunctionCalls = {},
    UsagePatterns = {},
    MigrationProgress = {}
}

-- Generate a unique identifier for a function call
local function GenerateCallId(moduleName, functionName, args)
    local uniqueId = moduleName .. "." .. functionName
    
    -- Add a hash of args if provided and HttpService is available
    if args and HttpService then
        local success, argsString = pcall(function()
            return HttpService:JSONEncode(args)
        end)
        
        if success then
            uniqueId = uniqueId .. "_" .. string.sub(argsString, 1, 20)
        end
    end
    
    return uniqueId
end

-- Log deprecation notice
function DeprecationHelper.LogDeprecation(moduleName, functionName, alternativeModule, alternativeFunction, additionalInfo)
    if not DEPRECATION_CONFIG.ShowWarnings then return end
    
    local callId = GenerateCallId(moduleName, functionName)
    
    -- Initialize count if first call
    if not _deprecationLogCount[callId] then
        _deprecationLogCount[callId] = 0
        _deprecationFirstCalled[callId] = os.time()
    end
    
    -- Only show detailed message on first call or every 10 calls
    _deprecationLogCount[callId] += 1
    
    if _deprecationLogCount[callId] == 1 or _deprecationLogCount[callId] % 10 == 0 then
        local message = string.format(
            "⚠️ DEPRECATED: %s.%s will be removed after %s. ", 
            moduleName, functionName, DEPRECATION_CONFIG.DeprecationDate
        )
        
        if alternativeModule and alternativeFunction then
            message = message .. string.format(
                "Use %s.%s instead.", 
                alternativeModule, alternativeFunction
            )
        end
        
        if additionalInfo and DEPRECATION_CONFIG.DetailLevel >= 2 then
            message = message .. "\n→ " .. additionalInfo
        end
        
        if DEPRECATION_CONFIG.DetailLevel >= 2 then
            message = message .. string.format(
                "\n→ Called %d times since script started.", 
                _deprecationLogCount[callId]
            )
        end
        
        message = message .. string.format(
            "\n→ See documentation: %s", 
            DEPRECATION_CONFIG.NewSystemDocumentation
        )
        
        warn(message)
    end
    
    -- Log call data for telemetry
    if DEPRECATION_CONFIG.TelemetryEnabled then
        -- Record usage in telemetry
        if not _telemetryData.DeprecatedFunctionCalls[moduleName] then
            _telemetryData.DeprecatedFunctionCalls[moduleName] = {}
        end
        
        if not _telemetryData.DeprecatedFunctionCalls[moduleName][functionName] then
            _telemetryData.DeprecatedFunctionCalls[moduleName][functionName] = 0
        end
        
        _telemetryData.DeprecatedFunctionCalls[moduleName][functionName] += 1
    end
end

-- Create a wrapper function that forwards to a new implementation but logs deprecation
function DeprecationHelper.WrapDeprecatedFunction(moduleName, functionName, newFunction, alternativeModule, alternativeFunction, additionalInfo)
    return function(...)
        DeprecationHelper.LogDeprecation(moduleName, functionName, alternativeModule, alternativeFunction, additionalInfo)
        return newFunction(...)
    end
end

-- Create a wrapper module that forwards all calls to a new module with deprecation notices
function DeprecationHelper.WrapDeprecatedModule(oldModuleName, newModule, functionMappings, additionalInfo)
    local wrappedModule = {}
    
    for oldFunctionName, mapping in pairs(functionMappings) do
        local newFunctionName = type(mapping) == "string" and mapping or oldFunctionName
        
        if type(newModule[newFunctionName]) == "function" then
            wrappedModule[oldFunctionName] = DeprecationHelper.WrapDeprecatedFunction(
                oldModuleName, 
                oldFunctionName, 
                function(...)
                    return newModule[newFunctionName](...)
                end,
                typeof(newModule) == "table" and newModule.Name or "NewConsolidatedModule", 
                newFunctionName,
                additionalInfo
            )
        end
    end
    
    return wrappedModule
end

-- Add deprecation notice to the top of a script
function DeprecationHelper.GenerateDeprecationHeader(oldScriptName, newModuleName, description)
    local header = [[
--[[
    ⚠️ DEPRECATED SCRIPT ⚠️
    
    This script is deprecated and will be removed after %s
    
    It has been replaced by the new consolidated module system:
    → %s
    
    %s
    
    For documentation and migration guides, see:
    %s
]]

]]
    return string.format(
        header, 
        DEPRECATION_CONFIG.DeprecationDate, 
        newModuleName, 
        description or "Please migrate your code to use the new system.", 
        DEPRECATION_CONFIG.NewSystemDocumentation
    )
end

-- Get telemetry data for monitoring migration progress
function DeprecationHelper.GetTelemetryData()
    if not DEPRECATION_CONFIG.TelemetryEnabled then
        return { TelemetryDisabled = true }
    end
    
    -- Update timestamps
    _telemetryData.LastUpdated = os.time()
    
    -- Calculate some statistics
    local totalCalls = 0
    local moduleStats = {}
    
    for moduleName, functions in pairs(_telemetryData.DeprecatedFunctionCalls) do
        moduleStats[moduleName] = 0
        
        for _, callCount in pairs(functions) do
            totalCalls += callCount
            moduleStats[moduleName] += callCount
        end
    end
    
    -- Add summary stats
    _telemetryData.Summary = {
        TotalDeprecatedCalls = totalCalls,
        ModuleUsageCount = moduleStats
    }
    
    return _telemetryData
end

-- Export configuration for modification
DeprecationHelper.Config = DEPRECATION_CONFIG

-- Register global functions for Studio use
if RunService:IsStudio() then
    -- Define global functions
    _G.GetDeprecationTelemetry = function()
        return DeprecationHelper.GetTelemetryData()
    end
    
    _G.ConfigureDeprecation = function(config)
        for key, value in pairs(config) do
            if DEPRECATION_CONFIG[key] ~= nil then
                DEPRECATION_CONFIG[key] = value
            end
        end
        return DEPRECATION_CONFIG
    end
    
    _G.GenerateDeprecationHeader = function(oldScriptName, newModuleName, description)
        return DeprecationHelper.GenerateDeprecationHeader(oldScriptName, newModuleName, description)
    end
    
    print("Deprecation helper functions registered for Studio use")
end

return DeprecationHelper
