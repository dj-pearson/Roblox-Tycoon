--!strict
--[[
    SafeWaitForChild.lua
    A utility module that provides safer ways to wait for children with timeouts and fallbacks.
    
    Author: Pearson
    Date: April 25, 2025
]]

local SafeWaitForChild = {}

-- Default timeout in seconds
SafeWaitForChild.DEFAULT_TIMEOUT = 10

-- Function to safely wait for a child with a timeout
function SafeWaitForChild.waitForChild(parent: Instance, childName: string, timeout: number?)
    timeout = timeout or SafeWaitForChild.DEFAULT_TIMEOUT
    
    -- Check if the child already exists
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Set up a timeout using a separate thread
    local timeoutReached = false
    local co = coroutine.running()
    
    local connection
    local timeoutThread = task.spawn(function()
        task.wait(timeout)
        timeoutReached = true
        if connection then
            connection:Disconnect()
        end
        task.spawn(co, nil) -- Resume with nil to indicate timeout
    end)
    
    -- Wait for the child to appear
    connection = parent.ChildAdded:Connect(function(child)
        if child.Name == childName and not timeoutReached then
            task.cancel(timeoutThread)
            connection:Disconnect()
            task.spawn(co, child) -- Resume with the child
        end
    end)
    
    -- Try one more time in case the child was added between our initial check and setting up the connection
    child = parent:FindFirstChild(childName)
    if child then
        task.cancel(timeoutThread)
        if connection then
            connection:Disconnect()
        end
        return child
    end
    
    -- Suspend this thread until either the child is found or timeout is reached
    local result = coroutine.yield()
    return result
end

-- Function to safely get a child or create a fallback
function SafeWaitForChild.getOrCreate(parent: Instance, childName: string, fallbackCreator: () -> Instance?, timeout: number?)
    local child = SafeWaitForChild.waitForChild(parent, childName, timeout)
    
    if child then
        return child, false -- Return the found child and false to indicate it wasn't created
    elseif fallbackCreator then
        warn(string.format("Failed to find child '%s' in '%s', creating fallback", childName, parent:GetFullName()))
        local fallback = fallbackCreator()
        if fallback then
            fallback.Name = childName
            fallback.Parent = parent
        end
        return fallback, true -- Return the created fallback and true to indicate it was created
    else
        warn(string.format("Failed to find child '%s' in '%s' and no fallback provided", childName, parent:GetFullName()))
        return nil, false
    end
end

-- Function to safely require a module with timeout and error handling
function SafeWaitForChild.safeRequire(parent: Instance, moduleName: string, timeout: number?)
    local success, result = pcall(function()
        local module = SafeWaitForChild.waitForChild(parent, moduleName, timeout)
        if module and module:IsA("ModuleScript") then
            return require(module)
        end
        warn(string.format("Found '%s' but it's not a ModuleScript", moduleName))
        return nil
    end)
    
    if success then
        return result
    else
        warn(string.format("Failed to require module '%s' from '%s': %s", moduleName, parent:GetFullName(), tostring(result)))
        return nil
    end
end

return SafeWaitForChild
