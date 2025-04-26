--!strict
--[[
    SafeRequire.luau
    
    A utility module for safely requiring other modules without crashing.
    
    Created: April 26, 2025
]]

-- Safely require a module, handling errors and returning nil if the module isn't found
local function SafeRequire(moduleInstance)
    if not moduleInstance then
        return nil
    end
    
    -- Check if it's a valid ModuleScript
    if not moduleInstance:IsA("ModuleScript") then
        warn("[SafeRequire] Instance is not a ModuleScript: " .. moduleInstance:GetFullName())
        return nil
    end
    
    -- Try to require the module
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if not success then
        warn("[SafeRequire] Error requiring module " .. moduleInstance:GetFullName() .. ": " .. tostring(result))
        return nil
    end
    
    return result
end

return SafeRequire
