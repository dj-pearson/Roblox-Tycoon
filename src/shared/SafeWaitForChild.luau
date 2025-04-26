--!strict
--[[
    SafeWaitForChild.luau
    
    A utility module that provides safe replacements for WaitForChild to avoid
    issues with timing and missing instances.
    
    Created: April 26, 2025
]]

-- Configuration
local DEFAULT_TIMEOUT = 5 -- Default timeout in seconds
local DEBUG_MODE = false   -- Enable debug logging

-- Debug logging
local function log(message)
    if DEBUG_MODE then
        print("[SafeWaitForChild] " .. message)
    end
end

-- Safely wait for a child with timeout
local function SafeWaitForChild(parent, childName, timeout)
    if not parent then
        warn("[SafeWaitForChild] Parent is nil")
        return nil
    end
    
    if not childName then
        warn("[SafeWaitForChild] Child name is nil")
        return nil
    end
    
    timeout = timeout or DEFAULT_TIMEOUT
    
    -- Check if child already exists
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Wait with timeout
    local startTime = os.clock()
    local connection
    local result = nil
    
    -- Create a promise-like mechanism
    local complete = false
    
    connection = parent.ChildAdded:Connect(function(newChild)
        if newChild.Name == childName then
            result = newChild
            complete = true
            connection:Disconnect()
        end
    end)
    
    -- Check again after connection (race condition prevention)
    if not complete then
        child = parent:FindFirstChild(childName)
        if child then
            complete = true
            result = child
            connection:Disconnect()
        end
    end
    
    -- Wait until complete or timeout
    while not complete and (os.clock() - startTime) < timeout do
        task.wait(0.1)
    end
    
    -- Clean up if timed out
    if not complete and connection then
        connection:Disconnect()
        warn("[SafeWaitForChild] Timed out waiting for " .. childName .. " in " .. parent:GetFullName())
    end
    
    return result
end

-- Safely wait for a descendant with timeout
local function SafeWaitForDescendant(parent, descendantPath, timeout)
    if not parent or not descendantPath then
        return nil
    end
    
    timeout = timeout or DEFAULT_TIMEOUT
    local startTime = os.clock()
    local remainingTime = timeout
    local currentParent = parent
    
    -- Split the path
    local pathParts = string.split(descendantPath, ".")
    
    -- Navigate through each part of the path
    for i, childName in ipairs(pathParts) do
        -- Calculate remaining timeout
        remainingTime = timeout - (os.clock() - startTime)
        if remainingTime <= 0 then
            warn("[SafeWaitForDescendant] Timed out waiting for " .. descendantPath .. " at part " .. childName)
            return nil
        end
        
        -- Wait for this child
        local child = SafeWaitForChild(currentParent, childName, remainingTime)
        if not child then
            return nil
        end
        
        currentParent = child
    end
    
    return currentParent
end

-- Create a multi-path finder that tries several paths
local function SafeFindFirstInstance(paths, timeout)
    if not paths or #paths == 0 then
        return nil
    end
    
    timeout = timeout or DEFAULT_TIMEOUT
    local startTime = os.clock()
    
    for _, path in ipairs(paths) do
        -- Skip empty paths
        if not path or path == "" then
            continue
        end
        
        -- Calculate remaining timeout
        local remainingTime = timeout - (os.clock() - startTime)
        if remainingTime <= 0 then
            warn("[SafeFindFirstInstance] Timed out searching for instance")
            return nil
        end
        
        -- Parse path - either a direct instance or a path string
        if typeof(path) == "Instance" then
            return path
        elseif typeof(path) == "string" then
            -- Split into segments
            local segments = string.split(path, ".")
            local current = game
            local found = true
            
            -- Navigate through segments
            for i, segment in ipairs(segments) do
                current = SafeWaitForChild(current, segment, remainingTime / #segments)
                
                if not current then
                    found = false
                    break
                end
            end
            
            if found then
                return current
            end
        end
    end
    
    return nil
end

-- Return all functions
return {
    WaitForChild = SafeWaitForChild,
    WaitForDescendant = SafeWaitForDescendant,
    FindFirstInstance = SafeFindFirstInstance,
    SetDebug = function(enabled) DEBUG_MODE = enabled end,
    SetDefaultTimeout = function(timeout) DEFAULT_TIMEOUT = timeout end
}
