--!strict
--[[
    SafeWait.luau
    A utility module to safely wait for objects with timeout protection to prevent infinite yields
]]

local SafeWait = {}

-- Safely waits for a child with a timeout
-- @param parent - The parent instance to search in
-- @param childName - Name of the child to wait for
-- @param timeoutSeconds - Maximum time to wait (defaults to 5 seconds)
-- @return The found instance or nil if timed out
function SafeWait.waitForChild(parent: Instance, childName: string, timeoutSeconds: number?)
    timeoutSeconds = timeoutSeconds or 5 -- Default timeout of 5 seconds
    
    -- First check if child already exists
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Set up timeout using a separate thread
    local found = false
    local resultInstance = nil
    
    -- Thread to wait for the child
    task.spawn(function()
        resultInstance = parent:WaitForChild(childName)
        found = true
    end)
    
    -- Thread to handle timeout
    local startTime = os.clock()
    repeat
        task.wait(0.1)
    until found or (os.clock() - startTime) > timeoutSeconds
    
    if not found then
        warn(string.format("SafeWait: Timed out waiting for %s in %s after %d seconds", 
            childName, parent:GetFullName(), timeoutSeconds))
    end
    
    return resultInstance
end

-- Safely wait for multiple children in sequence
-- @param parent - Initial parent instance
-- @param childNames - Array of child names to traverse
-- @param timeoutSeconds - Timeout for each individual wait (defaults to 5 seconds)
-- @return The final found instance or nil if any step timed out
function SafeWait.waitForPath(parent: Instance, childNames: {string}, timeoutSeconds: number?)
    local current = parent
    
    for _, childName in ipairs(childNames) do
        local next = SafeWait.waitForChild(current, childName, timeoutSeconds)
        if not next then
            return nil
        end
        current = next
    end
    
    return current
end

return SafeWait
