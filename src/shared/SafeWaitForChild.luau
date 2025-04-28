--[[
    SafeWaitForChild.luau
    A utility module for safely waiting for child instances with timeout handling.
    This prevents "Infinite yield possible on WaitForChild" errors by using timeouts.
    
    Created to fix critical "Module Loading and WaitForChild Errors" reported in RobloxIssues.txt
]]

local SafeWaitForChild = {}

-- Wait for a child with a timeout to prevent infinite yield
function SafeWaitForChild.waitForChild(parent, childName, timeout, warningEnabled)
    timeout = timeout or 5
    warningEnabled = warningEnabled ~= false  -- Default to true if not specified
    
    -- Quick check first (most efficient)
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    -- Use timeout to prevent infinite yield
    local startTime = os.clock()
    
    -- Try to use WaitForChild with timeout
    local success, result = pcall(function()
        return parent:WaitForChild(childName, timeout)
    end)
    
    -- If successful, return the result
    if success and result then
        return result
    end
    
    -- Manual polling as fallback
    child = parent:FindFirstChild(childName)
    while not child and (os.clock() - startTime) < timeout do
        task.wait(0.1)
        child = parent:FindFirstChild(childName)
    end
    
    -- Warning if enabled and child not found
    if not child and warningEnabled then
        warn("SafeWaitForChild: Timeout waiting for " .. childName .. " in " .. parent:GetFullName())
    end
    
    return child
end

-- Wait for a list of children with timeouts
function SafeWaitForChild.waitForChildren(parent, childNames, timeout, warningEnabled)
    timeout = timeout or 5
    warningEnabled = warningEnabled ~= false
    
    local results = {}
    local startTime = os.clock()
    local remainingTime = timeout
    
    for _, childName in ipairs(childNames) do
        -- Calculate remaining time for this child
        remainingTime = math.max(0.1, timeout - (os.clock() - startTime))
        
        -- Wait for this child with the remaining time
        results[childName] = SafeWaitForChild.waitForChild(
            parent, 
            childName, 
            remainingTime, 
            warningEnabled
        )
    end
    
    return results
end

-- Try to create a child if it doesn't exist and we have permission
function SafeWaitForChild.waitOrCreate(parent, childName, instanceType, timeout)
    timeout = timeout or 5
    
    -- Try to wait for the child first
    local child = SafeWaitForChild.waitForChild(parent, childName, timeout, false)
    
    -- If child doesn't exist, try to create it
    if not child then
        local success, result = pcall(function()
            child = Instance.new(instanceType)
            child.Name = childName
            child.Parent = parent
            return child
        end)
        
        if success then
            child = result
        else
            warn("SafeWaitForChild: Failed to create " .. childName .. " in " .. parent:GetFullName() .. ": " .. tostring(result))
        end
    end
    
    return child
end

-- Check if we can access a child at a nested path
function SafeWaitForChild.resolvePath(rootInstance, path, timeout, createMissing)
    timeout = timeout or 5
    createMissing = createMissing or false
    
    if typeof(rootInstance) ~= "Instance" then
        warn("SafeWaitForChild.resolvePath: Invalid root instance")
        return nil
    end
    
    if type(path) == "string" then
        path = string.split(path, ".")
    end
    
    if type(path) ~= "table" or #path == 0 then
        return rootInstance
    end
    
    local current = rootInstance
    local startTime = os.clock()
    local remainingTime = timeout
    
    for i, segment in ipairs(path) do
        -- Calculate remaining time for this segment
        remainingTime = math.max(0.1, timeout - (os.clock() - startTime))
        
        if createMissing then
            current = SafeWaitForChild.waitOrCreate(current, segment, "Folder", remainingTime)
        else
            current = SafeWaitForChild.waitForChild(current, segment, remainingTime)
        end
        
        if not current then
            warn("SafeWaitForChild.resolvePath: Failed to resolve path at segment " .. i .. ": " .. segment)
            return nil
        end
    end
    
    return current
end

return SafeWaitForChild
