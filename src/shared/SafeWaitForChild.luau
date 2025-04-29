--[[
    SafeWaitForChild.luau
    
    Provides a safe alternative to WaitForChild with timeout functionality
    to prevent infinite yield errors.
    
    Created as part of critical fixes on April 28, 2025.
]]

local DEFAULT_TIMEOUT = 5

-- Wait for a child with a timeout
local function SafeWaitForChild(parent, childName, timeout)
    timeout = timeout or DEFAULT_TIMEOUT
    
    -- Quick check first
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Use timeout to prevent infinite yield
    local startTimeValue = os.clock()
    local endTime = startTimeValue + timeout
    
    while os.clock() < endTime do
        child = parent:FindFirstChild(childName)
        if child then
            return child
        end
        task.wait(0.1)
    end
    
    warn("SafeWaitForChild: Timed out waiting for " .. childName .. " in " .. parent:GetFullName())
    return nil
end

-- Wait for a child of a specific class with a timeout
local function SafeWaitForChildOfClass(parent, childName, className, timeout)
    timeout = timeout or DEFAULT_TIMEOUT
    
    -- Quick check first
    local child = parent:FindFirstChild(childName)
    if child and child:IsA(className) then
        return child
    end
    
    -- Use timeout to prevent infinite yield
    local startTimeValue = os.clock()
    local endTime = startTimeValue + timeout
    
    while os.clock() < endTime do
        child = parent:FindFirstChild(childName)
        if child and child:IsA(className) then
            return child
        end
        task.wait(0.1)
    end
    
    warn("SafeWaitForChildOfClass: Timed out waiting for " .. childName .. " of class " .. className .. " in " .. parent:GetFullName())
    return nil
end

-- Wait for one of multiple children with a timeout
-- Returns the child that was found first, or nil if timeout
local function SafeWaitForAnyChild(parent, childNames, timeout)
    timeout = timeout or DEFAULT_TIMEOUT
    
    -- Quick check first
    for _, childName in ipairs(childNames) do
        local child = parent:FindFirstChild(childName)
        if child then
            return child
        end
    end
    
    -- Use timeout to prevent infinite yield
    local startTimeValue = os.clock()
    local endTime = startTimeValue + timeout
    
    while os.clock() < endTime do
        for _, childName in ipairs(childNames) do
            local child = parent:FindFirstChild(childName)
            if child then
                return child
            end
        end
        task.wait(0.1)
    end
    
    warn("SafeWaitForAnyChild: Timed out waiting for any of " .. table.concat(childNames, ", ") .. " in " .. parent:GetFullName())
    return nil
end

-- Wait for all children in a list with a timeout
-- Returns a table of found children, may be incomplete if timeout occurs
local function SafeWaitForAllChildren(parent, childNames, timeout)
    timeout = timeout or DEFAULT_TIMEOUT
    
    local result = {}
    local missing = {}
    
    -- Quick check first
    for _, childName in ipairs(childNames) do
        local child = parent:FindFirstChild(childName)
        if child then
            result[childName] = child
        else
            table.insert(missing, childName)
        end
    end
    
    if #missing == 0 then
        return result
    end
    
    -- Use timeout to prevent infinite yield
    local startTimeValue = os.clock()
    local endTime = startTimeValue + timeout
    
    while #missing > 0 and os.clock() < endTime do
        for i = #missing, 1, -1 do
            local childName = missing[i]
            local child = parent:FindFirstChild(childName)
            if child then
                result[childName] = child
                table.remove(missing, i)
            end
        end
        
        if #missing == 0 then
            break
        end
        
        task.wait(0.1)
    end
    
    if #missing > 0 then
        warn("SafeWaitForAllChildren: Timed out waiting for " .. table.concat(missing, ", ") .. " in " .. parent:GetFullName())
    end
    
    return result
end

-- Wait for a path of children with a timeout
-- Example: SafeWaitForPath(game, {"Workspace", "Baseplate", "Attachment"})
local function SafeWaitForPath(startParent, path, timeout)
    timeout = timeout or DEFAULT_TIMEOUT
    local totalStartTime = os.clock()
    local remainingTimeout = timeout
    
    local current = startParent
    for i, childName in ipairs(path) do
        -- Get current child in path
        local child = SafeWaitForChild(current, childName, remainingTimeout)
        
        if not child then
            warn("SafeWaitForPath: Failed at path part " .. i .. " (" .. childName .. ") of " .. #path)
            return nil
        end
        
        current = child
        
        -- Update remaining timeout
        remainingTimeout = math.max(0.1, timeout - (os.clock() - totalStartTime))
    end
    
    return current
end

-- Return the module functions
return {
    WaitForChild = SafeWaitForChild,
    WaitForChildOfClass = SafeWaitForChildOfClass,
    WaitForAnyChild = SafeWaitForAnyChild,
    WaitForAllChildren = SafeWaitForAllChildren,
    WaitForPath = SafeWaitForPath,
    
    -- Set the default timeout
    SetDefaultTimeout = function(timeout)
        if typeof(timeout) == "number" and timeout > 0 then
            DEFAULT_TIMEOUT = timeout
            return true
        end
        return false
    end,
    
    -- Get the current default timeout
    GetDefaultTimeout = function()
        return DEFAULT_TIMEOUT
    end
}
