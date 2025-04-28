--!strict
--[[
    SafeWaitForChild.luau
    
    A utility module that provides safe methods for waiting for child instances
    with timeout handling to prevent infinite yield errors.
    
    This module is a critical part of the infrastructure fixes and should be
    placed in ReplicatedStorage.shared for access from both server and client scripts.
    
    Updated: April 27, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local DEBUG_MODE = false
local DEFAULT_TIMEOUT = 5 -- seconds

local function log(message)
    if DEBUG_MODE then
        print("[SafeWaitForChild] " .. message)
    end
end

-- Main function to safely wait for a child with timeout
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
    
    -- Set up connection to detect when child is added
    local childAddedSignal
    local foundChild = nil
    
    local startTime = os.clock()
    
    -- Use ChildAdded event for detection
    childAddedSignal = parent.ChildAdded:Connect(function(addedChild)
        if addedChild.Name == childName then
            foundChild = addedChild
        end
    end)
    
    -- Try using WaitForChild with timeout
    local success, result = pcall(function()
        local co = coroutine.create(function()
            return parent:WaitForChild(childName, timeout)
        end)
        
        local status, child = coroutine.resume(co)
        
        if coroutine.status(co) == "dead" then
            return child
        else
            -- Yield until timeout or child is found
            local timeElapsed = 0
            while timeElapsed < timeout and not foundChild do
                task.wait(0.1)
                timeElapsed = os.clock() - startTime
            end
            
            return foundChild
        end
    end)
    
    -- Clean up connection
    if childAddedSignal then
        childAddedSignal:Disconnect()
    end
    
    -- Return child if found
    if success and result then
        return result
    end
    
    -- Log timeout
    warn("[SafeWaitForChild] Timed out waiting for " .. childName .. " in " .. parent:GetFullName())
    return nil
end

-- Get or create a child with the specified class (useful for ensuring folders exist)
local function getOrCreateChild(parent, childName, className)
    if not parent then
        warn("[SafeWaitForChild] Cannot create child, parent is nil")
        return nil
    end
    
    -- Look for existing child
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Create new instance
    log("Creating " .. className .. " '" .. childName .. "' in " .. parent:GetFullName())
    local newChild = Instance.new(className)
    newChild.Name = childName
    newChild.Parent = parent
    return newChild
end

-- Wait for a child at a specific path within a parent (e.g. "Folder1.Folder2.Target")
local function waitForDescendant(parent, path, timeout)
    if not parent or not path then
        warn("[SafeWaitForChild] Invalid arguments to waitForDescendant")
        return nil
    end
    
    timeout = timeout or DEFAULT_TIMEOUT
    local startTime = os.clock()
    
    -- Split path into segments
    local segments = string.split(path, ".")
    if #segments == 0 then
        return nil
    end
    
    -- Navigate through path segments
    local current = parent
    for i, segment in ipairs(segments) do
        local remainingTime = timeout - (os.clock() - startTime)
        if remainingTime <= 0 then
            warn("[SafeWaitForChild] Timed out waiting for path: " .. path)
            return nil
        end
        
        current = SafeWaitForChild(current, segment, remainingTime / (#segments - i + 1))
        if not current then
            warn("[SafeWaitForChild] Failed to find segment '" .. segment .. "' in path: " .. path)
            return nil
        end
    end
    
    return current
end

-- Create all folders in a path (e.g. "Folder1.Folder2.Folder3")
local function createPath(parent, path)
    if not parent or not path then
        warn("[SafeWaitForChild] Invalid arguments to createPath")
        return nil
    end
    
    -- Split path into segments
    local segments = string.split(path, ".")
    if #segments == 0 then
        return parent
    end
    
    -- Create each folder in the path
    local current = parent
    for _, segment in ipairs(segments) do
        current = getOrCreateChild(current, segment, "Folder")
        if not current then
            warn("[SafeWaitForChild] Failed to create path segment: " .. segment)
            return nil
        end
    end
    
    return current
end

-- Get statistics about WaitForChild calls (for diagnostics)
local yieldStats = {
    totalCalls = 0,
    successfulCalls = 0,
    timeoutCalls = 0,
    averageWaitTime = 0,
    totalWaitTime = 0
}

local function getYieldStats()
    return table.clone(yieldStats)
end

-- Ensure critical paths exist when module is loaded
local function ensureCriticalPaths()
    -- Create shared folder in ReplicatedStorage if it doesn't exist
    getOrCreateChild(ReplicatedStorage, "shared", "Folder")
    
    -- Create Core folder in ServerScriptService if it doesn't exist
    if game:GetService("RunService"):IsServer() then
        getOrCreateChild(ServerScriptService, "Core", "Folder")
    end
end

-- Run initialization
ensureCriticalPaths()

-- Return the module API
return {
    waitForChild = SafeWaitForChild,
    waitForDescendant = waitForDescendant,
    getOrCreateChild = getOrCreateChild,
    createPath = createPath,
    getYieldStats = getYieldStats,
    DEBUG_MODE = DEBUG_MODE,
    DEFAULT_TIMEOUT = DEFAULT_TIMEOUT
}
