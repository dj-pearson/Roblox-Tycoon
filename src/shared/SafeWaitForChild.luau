--!strict
--[[
    SafeWaitForChild.luau
    
    A utility module for safely waiting for children with timeout handling.
    This prevents the "Infinite yield possible on WaitForChild" errors mentioned
    in the issues list.
    
    Created: April 26, 2025
]]

-- Configuration
local DEFAULT_TIMEOUT = 5 -- Default timeout in seconds
local DEBUG_LOGGING = true
local TRACK_YIELDS = true

-- Tracking for long yields
local yieldStats = {
    totalYields = 0,
    timeoutYields = 0,
    longestYield = 0,
    longestYieldPath = "",
    problematicPaths = {}
}

-- SafeWaitForChild utility
local SafeWaitForChild = {}

-- Internal logging function
local function log(message)
    if DEBUG_LOGGING then
        print("[SafeWaitForChild] " .. message)
    end
end

-- Record a problematic path
local function recordProblematicPath(parent, childName, elapsed)
    if not TRACK_YIELDS then return end
    
    local path = parent:GetFullName() .. "." .. childName
    
    -- Update tracking stats
    yieldStats.totalYields = yieldStats.totalYields + 1
    
    -- Record longest yield
    if elapsed > yieldStats.longestYield then
        yieldStats.longestYield = elapsed
        yieldStats.longestYieldPath = path
    end
    
    -- Track path frequency
    yieldStats.problematicPaths[path] = (yieldStats.problematicPaths[path] or 0) + 1
end

-- Safely wait for a child with timeout
function SafeWaitForChild.waitForChild(parent, childName, timeoutSeconds)
    timeoutSeconds = timeoutSeconds or DEFAULT_TIMEOUT
    
    if not parent then
        warn("[SafeWaitForChild] Parent is nil while waiting for: " .. childName)
        return nil
    end
    
    local startTime = os.clock()
    local child = parent:FindFirstChild(childName)
    
    -- If child already exists, return it immediately
    if child then
        return child
    end
    
    -- Set up a flag to track if we've found the child
    local found = false
    local connection
    
    -- Create function to handle when a child is added
    connection = parent.ChildAdded:Connect(function(newChild)
        if newChild.Name == childName then
            found = true
            child = newChild
        end
    end)
    
    -- Wait until we find the child or timeout
    while not found and (os.clock() - startTime) < timeoutSeconds do
        task.wait(0.1)
        
        -- Double-check if child exists directly (might have been added just before connection)
        if not child then
            child = parent:FindFirstChild(childName)
            if child then
                found = true
                break
            end
        end
    end
    
    -- Clean up the connection
    connection:Disconnect()
    
    -- Record statistics
    local elapsed = os.clock() - startTime
    if elapsed > 0.5 then -- Only record yields longer than 0.5 seconds
        recordProblematicPath(parent, childName, elapsed)
    end
    
    -- Handle timeout
    if not found then
        yieldStats.timeoutYields = yieldStats.timeoutYields + 1
        warn("[SafeWaitForChild] Timed out waiting for child: " .. childName .. 
             " in parent: " .. parent:GetFullName() .. 
             " (timeout: " .. timeoutSeconds .. "s)")
        return nil
    end
    
    return child
end

-- Wait for a descendant (may be multiple levels deep)
function SafeWaitForChild.waitForDescendant(parent, descendantPath, timeoutSeconds)
    timeoutSeconds = timeoutSeconds or DEFAULT_TIMEOUT
    local startTime = os.clock()
    local timeRemaining = timeoutSeconds
    
    -- Split the path into parts
    local pathParts = string.split(descendantPath, ".")
    local current = parent
    
    -- Navigate through each part of the path
    for _, part in ipairs(pathParts) do
        if not current then return nil end
        
        -- Calculate remaining time for this part
        timeRemaining = timeoutSeconds - (os.clock() - startTime)
        if timeRemaining <= 0 then
            warn("[SafeWaitForChild] Timed out waiting for descendant part: " .. part .. 
                 " in path: " .. descendantPath)
            return nil
        end
        
        -- Wait for this part
        current = SafeWaitForChild.waitForChild(current, part, timeRemaining)
    end
    
    return current
end

-- Create a child if it doesn't exist and return it
function SafeWaitForChild.getOrCreateChild(parent, childName, instanceType, properties)
    local child = parent:FindFirstChild(childName)
    
    if not child then
        child = Instance.new(instanceType)
        child.Name = childName
        
        -- Apply properties if provided
        if properties then
            for key, value in pairs(properties) do
                child[key] = value
            end
        end
        
        child.Parent = parent
        log("Created " .. instanceType .. " '" .. childName .. "' in " .. parent:GetFullName())
    end
    
    return child
end

-- Create a folder hierarchy from a path string
function SafeWaitForChild.createPath(parent, path)
    local pathParts = string.split(path, ".")
    local current = parent
    
    for _, part in ipairs(pathParts) do
        current = SafeWaitForChild.getOrCreateChild(current, part, "Folder")
    end
    
    return current
end

-- Get statistics on problematic WaitForChild calls
function SafeWaitForChild.getYieldStats()
    return {
        totalYields = yieldStats.totalYields,
        timeoutYields = yieldStats.timeoutYields,
        timeoutRate = yieldStats.totalYields > 0 
                     and (yieldStats.timeoutYields / yieldStats.totalYields) 
                     or 0,
        longestYield = yieldStats.longestYield,
        longestYieldPath = yieldStats.longestYieldPath,
        problematicPaths = table.clone(yieldStats.problematicPaths)
    }
end

-- Reset statistics
function SafeWaitForChild.resetStats()
    yieldStats = {
        totalYields = 0,
        timeoutYields = 0,
        longestYield = 0,
        longestYieldPath = "",
        problematicPaths = {}
    }
end

-- Get the most problematic paths
function SafeWaitForChild.getMostProblematicPaths(limit)
    limit = limit or 10
    
    local paths = {}
    for path, count in pairs(yieldStats.problematicPaths) do
        table.insert(paths, {
            path = path,
            count = count
        })
    end
    
    -- Sort by frequency
    table.sort(paths, function(a, b)
        return a.count > b.count
    end)
    
    -- Limit results
    local result = {}
    for i = 1, math.min(limit, #paths) do
        table.insert(result, paths[i])
    end
    
    return result
end

-- Set default timeout
function SafeWaitForChild.setDefaultTimeout(seconds)
    DEFAULT_TIMEOUT = seconds
    log("Default timeout set to " .. seconds .. " seconds")
end

-- Configure the module
function SafeWaitForChild.configure(config)
    if config.defaultTimeout then
        DEFAULT_TIMEOUT = config.defaultTimeout
    end
    
    if config.debugLogging ~= nil then
        DEBUG_LOGGING = config.debugLogging
    end
    
    if config.trackYields ~= nil then
        TRACK_YIELDS = config.trackYields
    end
    
    log("SafeWaitForChild configured")
end

return SafeWaitForChild
