--[[
    SafeRequireShim.luau
    
    A compatibility shim that ensures SafeRequire can be accessed properly
    during the migration from ReplicatedStorage\shared to src\shared.
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to load SafeRequire from src\shared
local SafeRequire = nil
local success, result = pcall(function()
    return require(ReplicatedStorage.Shared:FindFirstChild("SafeRequire"))
end)

if success then
    SafeRequire = result
else
    -- If that fails, try to load from the old location
    success, result = pcall(function()
        local module = ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("SafeRequire.luau")
        if module then
            return require(module)
        end
        return nil
    end)
    
    if success then
        SafeRequire = result
    else
        -- Create a minimal implementation if all else fails
        SafeRequire = {
            require = function(moduleScript)
                if typeof(moduleScript) ~= "Instance" then
                    warn("[SafeRequire] Invalid argument: Expected moduleScript to be an Instance")
                    return nil
                end
                
                local success, result = pcall(function()
                    return require(moduleScript)
                end)
                
                if success then
                    return result
                else
                    warn("[SafeRequire] Failed to require module: " .. tostring(result))
                    return nil
                end
            end,
            
            requireFromPath = function(parent, path)
                if not parent or typeof(parent) ~= "Instance" then
                    warn("[SafeRequire] Invalid parent: Expected an Instance")
                    return nil
                end
                
                if not path or type(path) ~= "string" then
                    warn("[SafeRequire] Invalid path: Expected a string")
                    return nil
                end
                
                local parts = string.split(path, ".")
                local current = parent
                
                for _, part in ipairs(parts) do
                    current = current:FindFirstChild(part)
                    if not current then
                        warn("[SafeRequire] Could not find " .. part .. " in path: " .. path)
                        return nil
                    end
                end
                
                if not current:IsA("ModuleScript") then
                    warn("[SafeRequire] Found object is not a ModuleScript: " .. path)
                    return nil
                end
                
                return SafeRequire.require(current)
            end
        }
        
        warn("[SafeRequireShim] Created minimal SafeRequire implementation due to loading failures")
    end
end

-- Add a message to indicate the shim is being used
if SafeRequire then
    local originalRequire = SafeRequire.require
    SafeRequire.require = function(...)
        print("[SafeRequireShim] Using compatible SafeRequire")
        return originalRequire(...)
    end
end

return SafeRequire
