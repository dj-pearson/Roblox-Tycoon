--[[
    SafeWaitForChild.luau
    
    Utility module to safely wait for child instances with timeout protection.
    Prevents infinite yield errors by providing fallback mechanisms when children
    don't appear within the specified timeout period.
    
    Created as part of the CoreRegistry fix documented in CoreRegistry_Fix_Solution.md
]]

local SafeWaitForChild = {}

-- Default timeout in seconds
SafeWaitForChild.DEFAULT_TIMEOUT = 5

-- SafeWaitForChild with timeout and optional creation
function SafeWaitForChild.wait(parent, childName, timeout, createIfMissing, instanceType)
    if not parent then
        warn("SafeWaitForChild: Parent is nil")
        return nil
    end
    
    if typeof(parent) ~= "Instance" then
        warn("SafeWaitForChild: Parent is not an Instance")
        return nil
    end
    
    timeout = timeout or SafeWaitForChild.DEFAULT_TIMEOUT
    
    -- Quick check first
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Wait with timeout
    local startTime = os.clock()
    while not child and (os.clock() - startTime) < timeout do
        child = parent:FindFirstChild(childName)
        if child then
            break
        end
        task.wait(0.1)
    end
    
    -- Create if requested and still missing
    if not child and createIfMissing then
        local success, result = pcall(function()
            local newChild
            
            if instanceType then
                newChild = Instance.new(instanceType)
            else
                newChild = Instance.new("Folder")
            end
            
            newChild.Name = childName
            newChild.Parent = parent
            return newChild
        end)
        
        if success then
            child = result
            print("SafeWaitForChild: Created " .. childName .. " in " .. parent:GetFullName())
        else
            warn("SafeWaitForChild: Failed to create " .. childName .. " in " .. parent:GetFullName() .. ": " .. tostring(result))
        end
    end
    
    -- Log warning if still not found
    if not child then
        warn("SafeWaitForChild: Timed out waiting for " .. childName .. " in " .. parent:GetFullName() .. " after " .. timeout .. " seconds")
    end
    
    return child
end

-- Safely wait and require a ModuleScript
function SafeWaitForChild.waitAndRequire(parent, childName, timeout, fallback)
    local module = SafeWaitForChild.wait(parent, childName, timeout)
    
    if not module then
        return fallback
    end
    
    if not module:IsA("ModuleScript") then
        warn("SafeWaitForChild.waitAndRequire: Found " .. childName .. " but it's not a ModuleScript")
        return fallback
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("SafeWaitForChild.waitAndRequire: Failed to require " .. childName .. ": " .. tostring(result))
        return fallback
    end
end

-- Safely navigate a path with individual timeouts
function SafeWaitForChild.navigatePath(startParent, pathArray, timeout, createMissing)
    if not startParent or typeof(startParent) ~= "Instance" then
        warn("SafeWaitForChild.navigatePath: Invalid start parent")
        return nil
    end
    
    local current = startParent
    timeout = timeout or SafeWaitForChild.DEFAULT_TIMEOUT
    local perElementTimeout = timeout / #pathArray
    
    for _, name in ipairs(pathArray) do
        current = SafeWaitForChild.wait(current, name, perElementTimeout, createMissing)
        if not current then
            return nil
        end
    end
    
    return current
end

return SafeWaitForChild
