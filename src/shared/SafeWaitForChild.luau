-- SafeWaitForChild.luau
-- Utility module to prevent infinite yield errors when waiting for objects
-- Created: April 28, 2025

local DEFAULT_TIMEOUT = 5 -- seconds
local MAX_ATTEMPTS = 3
local RETRY_DELAY = 0.5 -- seconds
local DEBUG = true

local SafeWaitForChild = {}

-- Helper function for logging
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[SafeWaitForChild][%s] %s", level, message))
end

-- Wait for a child with timeout to prevent infinite yield
function SafeWaitForChild.Wait(parent, childName, timeout)
	if not parent then
		log("Parent is nil", "Error")
		return nil
	end
	
	if not childName then
		log("ChildName is nil", "Error")
		return nil
	end
	
	timeout = timeout or DEFAULT_TIMEOUT
	local startTime = os.clock()
	
	-- First check if the child already exists
	local child = parent:FindFirstChild(childName)
	if child then
		return child
	end
	
	-- Wait for the child with a timeout
	while os.clock() - startTime < timeout do
		child = parent:FindFirstChild(childName)
		if child then
			return child
		end
		wait(0.1)
	end
	
	log("Timed out waiting for " .. childName .. " in " .. parent:GetFullName(), "Warning")
	return nil
end

-- Wait for a child with multiple retry attempts
function SafeWaitForChild.WaitWithRetry(parent, childName, timeout, attempts)
	if not parent then
		log("Parent is nil", "Error")
		return nil
	end
	
	if not childName then
		log("ChildName is nil", "Error")
		return nil
	end
	
	timeout = timeout or DEFAULT_TIMEOUT
	attempts = attempts or MAX_ATTEMPTS
	
	for attempt = 1, attempts do
		local child = SafeWaitForChild.Wait(parent, childName, timeout)
		if child then
			return child
		end
		
		if attempt < attempts then
			log("Attempt " .. attempt .. "/" .. attempts .. " failed, retrying in " .. RETRY_DELAY .. " seconds...", "Warning")
			wait(RETRY_DELAY)
		else
			log("All " .. attempts .. " attempts failed to find " .. childName .. " in " .. parent:GetFullName(), "Error")
		end
	end
	
	return nil
end

-- Create a child if it doesn't exist (with specified instance type)
function SafeWaitForChild.EnsureChild(parent, childName, instanceType, timeout)
	if not parent then
		log("Parent is nil", "Error")
		return nil
	end
	
	if not childName then
		log("ChildName is nil", "Error")
		return nil
	end
	
	local child = SafeWaitForChild.Wait(parent, childName, timeout)
	
	if not child then
		-- Child not found, create it
		child = Instance.new(instanceType or "Folder")
		child.Name = childName
		child.Parent = parent
		log("Created " .. instanceType .. " '" .. childName .. "' in " .. parent:GetFullName(), "Warning")
	end
	
	return child
end

-- Wait for a child in a path (e.g., "ReplicatedStorage.shared.ClientRegistry")
function SafeWaitForChild.WaitForPath(pathString, timeout)
	if not pathString then
		log("Path string is nil", "Error")
		return nil
	end
	
	local pathParts = string.split(pathString, ".")
	local current = game
	
	for i, part in ipairs(pathParts) do
		current = SafeWaitForChild.Wait(current, part, timeout)
		
		if not current then
			log("Failed to find path at part " .. i .. ": " .. part, "Error")
			return nil
		end
	end
	
	return current
end

-- Create a path of folders (e.g., "ReplicatedStorage.shared.UI.Components")
function SafeWaitForChild.EnsurePath(pathString)
	if not pathString then
		log("Path string is nil", "Error")
		return nil
	end
	
	local pathParts = string.split(pathString, ".")
	local current = game
	
	for i, part in ipairs(pathParts) do
		if i == 1 then
			-- First part should be a service
			current = game:GetService(part)
			if not current then
				log("Invalid service name: " .. part, "Error")
				return nil
			end
		else
			-- Subsequent parts are folders to create
			current = SafeWaitForChild.EnsureChild(current, part, "Folder")
			
			if not current then
				log("Failed to ensure path at part " .. i .. ": " .. part, "Error")
				return nil
			end
		end
	end
	
	return current
end

return SafeWaitForChild
