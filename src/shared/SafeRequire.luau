--!strict
--[[
    SafeRequire.luau
    
    A utility module for safely requiring other modules with error handling
    and fallback mechanisms. This helps prevent script failures when modules
    can't be loaded.
    
    Created: April 27, 2025
]]

-- Configuration
local DEBUG_MODE = false

local function log(message)
    if DEBUG_MODE then
        print("[SafeRequire] " .. message)
    end
end

-- Main function to safely require modules
local function SafeRequire(moduleScript, fallback)
    -- Check if module exists
    if not moduleScript then
        if fallback ~= nil then
            log("Module not found, using fallback")
            return fallback
        else
            warn("[SafeRequire] Module is nil and no fallback provided")
            return nil
        end
    end
    
    -- Make sure it's a ModuleScript
    if not moduleScript:IsA("ModuleScript") then
        if fallback ~= nil then
            warn("[SafeRequire] Instance is not a ModuleScript, using fallback")
            return fallback
        else
            warn("[SafeRequire] Instance is not a ModuleScript: " .. moduleScript:GetFullName())
            return nil
        end
    end
    
    -- Try to require the module
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        return result
    else
        -- Log the error
        warn("[SafeRequire] Failed to require " .. moduleScript:GetFullName() .. ": " .. tostring(result))
        
        -- Return fallback if provided
        if fallback ~= nil then
            log("Using fallback after require failed")
            return fallback
        end
        
        return nil
    end
end

-- Try to find and require a module through multiple paths
local function SafeRequireFromPaths(moduleNames, paths, fallback)
    if type(moduleNames) == "string" then
        moduleNames = {moduleNames}
    end
    
    -- Try each module name in each path
    for _, path in ipairs(paths) do
        for _, moduleName in ipairs(moduleNames) do
            if path then
                local moduleScript = path:FindFirstChild(moduleName)
                if moduleScript and moduleScript:IsA("ModuleScript") then
                    local result = SafeRequire(moduleScript)
                    if result then
                        return result
                    end
                end
            end
        end
    end
    
    -- If we get here, we couldn't find the module
    if fallback ~= nil then
        log("Module not found in any path, using fallback")
        return fallback
    else
        warn("[SafeRequire] Module not found in any path: " .. table.concat(moduleNames, ", "))
        return nil
    end
end

-- Require a module from a path specified as a string (e.g., "ReplicatedStorage.shared.Utility")
local function SafeRequireFromString(pathString, fallback)
    -- Check if path is valid
    if type(pathString) ~= "string" then
        if fallback ~= nil then
            return fallback
        else
            warn("[SafeRequire] Path string is not a string")
            return nil
        end
    end
    
    -- Split path into segments
    local segments = string.split(pathString, ".")
    if #segments == 0 then
        warn("[SafeRequire] Empty path string")
        return fallback
    end
    
    -- Start with the service or global object
    local current
    local firstSegment = segments[1]
    
    -- Handle common services and special cases
    if firstSegment == "game" then
        current = game
    elseif firstSegment == "workspace" then
        current = workspace
    else
        -- Try to get service
        local success, service = pcall(function()
            return game:GetService(firstSegment)
        end)
        
        if success and service then
            current = service
        else
            -- Try as a global variable
            current = _G[firstSegment]
            
            if not current then
                warn("[SafeRequire] Invalid first segment in path: " .. firstSegment)
                return fallback
            end
        end
    end
    
    -- Navigate through path
    for i = 2, #segments - 1 do
        if not current then
            break
        end
        
        current = current:FindFirstChild(segments[i])
    end
    
    -- Check if we reached a valid parent
    if current then
        -- Try to find the actual module
        local moduleScript = current:FindFirstChild(segments[#segments])
        return SafeRequire(moduleScript, fallback)
    else
        -- Path navigation failed
        if fallback ~= nil then
            return fallback
        else
            warn("[SafeRequire] Failed to navigate path: " .. pathString)
            return nil
        end
    end
end

-- Return API
return {
    require = SafeRequire,
    requireFromPaths = SafeRequireFromPaths,
    requireFromString = SafeRequireFromString,
    setDebugMode = function(enabled)
        DEBUG_MODE = enabled
    end
}
