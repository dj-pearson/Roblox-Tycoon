--[[
    SafeRequire.luau
    A utility module for safely requiring other modules with error handling and caching.
]]

local SafeRequire = {}

-- Cache for already required modules
local requiredModules = {}

-- Function to safely require a module
function SafeRequire.require(moduleScript)
    if typeof(moduleScript) ~= "Instance" then
        warn("[SafeRequire] Invalid argument: Expected moduleScript to be an Instance")
        return nil
    end

    -- Return cached module if already required
    if requiredModules[moduleScript] then
        return requiredModules[moduleScript]
    end

    -- Attempt to require the module with pcall to catch errors
    local success, result = pcall(function()
        return require(moduleScript)
    end)

    if success then
        requiredModules[moduleScript] = result
        return result
    else
        warn("[SafeRequire] Failed to require module:", moduleScript:GetFullName())
        warn("[SafeRequire] Error:", result)
        return nil
    end
end

-- Function to require a module from a path string
function SafeRequire.requireFromPath(path)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerStorage = game:GetService("ServerStorage")
    local ServerScriptService = game:GetService("ServerScriptService")
    
    -- List of locations to search
    local searchLocations = {
        ReplicatedStorage,
        ServerStorage,
        ServerScriptService,
        ReplicatedStorage:FindFirstChild("shared"),
        ServerScriptService:FindFirstChild("Server"),
        ServerScriptService:FindFirstChild("Server"):FindFirstChild("Core"),
    }
    
    -- Try to find the module in each location
    for _, location in ipairs(searchLocations) do
        if location then
            local moduleScript = location:FindFirstChild(path)
            if moduleScript and moduleScript:IsA("ModuleScript") then
                return SafeRequire.require(moduleScript)
            end
        end
    end
    
    warn("[SafeRequire] Could not find module:", path)
    return nil
end

return SafeRequire
