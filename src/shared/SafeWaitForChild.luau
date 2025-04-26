--[[
    SafeWaitForChild.luau
    
    A utility module for safely waiting for child objects with a timeout and fallbacks.
    Designed to prevent "Infinite yield possible on WaitForChild" errors.
    
    Created: April 25, 2025
]]

local SafeWaitForChild = {}

-- Default timeout in seconds
local DEFAULT_TIMEOUT = 5

-- Safe wait for child with timeout and optional fallback creation
function SafeWaitForChild.waitForChild(parent, childName, timeout, fallbackCreator)
    -- Check if parent is valid
    if not parent or typeof(parent) ~= "Instance" then
        warn(string.format("SafeWaitForChild: Invalid parent when waiting for '%s'", childName))
        return nil, false
    end
    
    -- Set default timeout if not provided
    timeout = timeout or DEFAULT_TIMEOUT
    
    -- First check if the child already exists
    local child = parent:FindFirstChild(childName)
    if child then
        return child, false -- Return the found child and false to indicate it wasn't created
    end
    
    -- Start timing for timeout
    local startTime = os.clock()
    
    -- Wait until child appears or timeout
    while os.clock() - startTime < timeout do
        child = parent:FindFirstChild(childName)
        if child then
            return child, false -- Return the found child and false to indicate it wasn't created
        end
        task.wait(0.1)
    end
    
    -- If not found after timeout, try fallback creation
    if not child then
        if fallbackCreator then
            warn(string.format("SafeWaitForChild: Failed to find child '%s' in '%s', creating fallback", childName, parent:GetFullName()))
            local fallback = fallbackCreator()
            if fallback then
                fallback.Name = childName
                fallback.Parent = parent
            end
            return fallback, true -- Return the created fallback and true to indicate it was created
        else
            warn(string.format("SafeWaitForChild: Failed to find child '%s' in '%s' and no fallback provided", childName, parent:GetFullName()))
            return nil, false
        end
    end
end

-- Safely wait for a descendant with timeout
function SafeWaitForChild.waitForDescendant(parent, path, timeout, fallbackCreator)
    -- Check if parent is valid
    if not parent or typeof(parent) ~= "Instance" then
        warn(string.format("SafeWaitForChild: Invalid parent when waiting for path '%s'", path))
        return nil
    end
    
    -- Set default timeout if not provided
    timeout = timeout or DEFAULT_TIMEOUT
    
    -- Split the path
    local pathParts = string.split(path, ".")
    local currentParent = parent
    local created = false
    
    -- Process each part of the path
    for i, part in ipairs(pathParts) do
        local isLast = i == #pathParts
        
        -- For the last part, we can use the fallback creator
        local fallback = isLast and fallbackCreator or nil
        
        -- Wait for this part
        local child, wasCreated = SafeWaitForChild.waitForChild(currentParent, part, timeout / #pathParts, fallback)
        
        if child then
            currentParent = child
            created = created or wasCreated
        else
            warn(string.format("SafeWaitForChild: Failed to find part '%s' in path '%s'", part, path))
            return nil
        end
    end
    
    return currentParent, created
end

-- Function to safely require a module with timeout and error handling
function SafeWaitForChild.safeRequire(parent, moduleName, timeout)
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

-- Create a folder if it doesn't exist
function SafeWaitForChild.ensureFolder(parent, folderName)
    local folder = parent:FindFirstChild(folderName)
    if folder and folder:IsA("Folder") then
        return folder, false
    end
    
    folder = Instance.new("Folder")
    folder.Name = folderName
    folder.Parent = parent
    
    return folder, true
end

-- Create necessary service paths
function SafeWaitForChild.establishServicePath(service, path, timeout)
    local parts = string.split(path, ".")
    local current = service
    local created = false
    
    for _, part in ipairs(parts) do
        local next, wasCreated = SafeWaitForChild.waitForChild(current, part, timeout, function()
            return Instance.new("Folder")
        end)
        
        current = next
        created = created or wasCreated
        
        if not current then
            warn(string.format("Failed to establish path '%s' in service '%s'", path, service.Name))
            return nil
        end
    end
    
    return current, created
end

return SafeWaitForChild
