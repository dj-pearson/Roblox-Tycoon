--[[
    SafeWaitForChild.luau
    A utility module for safely waiting for children with timeout and error handling.
]]

local SafeWaitForChild = {}

-- Default timeout in seconds
local DEFAULT_TIMEOUT = 5

-- Function to safely wait for a child with timeout
function SafeWaitForChild.waitForChild(parent, childName, timeout)
    if typeof(parent) ~= "Instance" then
        warn("[SafeWaitForChild] Invalid parent: Expected an Instance")
        return nil
    end
    
    if type(childName) ~= "string" then
        warn("[SafeWaitForChild] Invalid childName: Expected a string")
        return nil
    end
    
    timeout = timeout or DEFAULT_TIMEOUT
    
    -- Check if the child already exists
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Set up a timeout using a coroutine
    local timeoutThread = coroutine.create(function()
        wait(timeout)
        return false
    end)
    
    -- Wait for the child
    local waitThread = coroutine.create(function()
        local result = parent:WaitForChild(childName)
        return result
    end)
    
    -- Start both threads
    coroutine.resume(timeoutThread)
    coroutine.resume(waitThread)
    
    -- Check which one finishes first
    while true do
        local timeoutStatus = coroutine.status(timeoutThread)
        local waitStatus = coroutine.status(waitThread)
        
        if waitStatus == "dead" then
            -- The child was found
            local _, child = coroutine.resume(waitThread)
            return child
        end
        
        if timeoutStatus == "dead" then
            -- Timeout occurred
            warn("[SafeWaitForChild] Timeout waiting for", childName, "in", parent:GetFullName())
            return nil
        end
        
        wait()
    end
end

-- Function to safely wait for multiple children with timeout
function SafeWaitForChild.waitForChildren(parent, childrenNames, timeout)
    if typeof(parent) ~= "Instance" then
        warn("[SafeWaitForChild] Invalid parent: Expected an Instance")
        return {}
    end
    
    if type(childrenNames) ~= "table" then
        warn("[SafeWaitForChild] Invalid childrenNames: Expected a table")
        return {}
    end
    
    local children = {}
    
    for _, name in ipairs(childrenNames) do
        children[name] = SafeWaitForChild.waitForChild(parent, name, timeout)
    end
    
    return children
end

return SafeWaitForChild
