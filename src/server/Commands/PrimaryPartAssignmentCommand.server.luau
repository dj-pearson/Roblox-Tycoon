--!strict
--[[
    PrimaryPartAssignmentCommand.server.luau
    Script to add invisible primary parts to models that don't have one
    
    Created: May 4, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Try to find utility modules
local SafeWaitForChild
local success, safeWaitResult = pcall(function()
    local moduleScript = ReplicatedStorage:FindFirstChild("src")
    if moduleScript then
        moduleScript = moduleScript:FindFirstChild("shared")
        if moduleScript then
            moduleScript = moduleScript:FindFirstChild("SafeWaitForChild")
            if moduleScript then
                return require(moduleScript)
            end
        end
    end
    return nil
end)

if success and safeWaitResult then
    SafeWaitForChild = safeWaitResult
else
    -- Simple fallback implementation
    SafeWaitForChild = {}
    function SafeWaitForChild.waitForChild(parent, childName, timeout)
        timeout = timeout or 10
        local startTime = os.clock()
        while os.clock() - startTime < timeout do
            local child = parent:FindFirstChild(childName)
            if child then return child end
            task.wait(0.1)
        end
        warn("Timeout waiting for " .. parent:GetFullName() .. ":" .. childName)
        return nil
    end
end

-- Check if player is authorized to run admin commands
local function isAuthorized(player)
    -- List of admin user IDs
    local ADMIN_IDS = {
        7768610061, -- Authorized admin
    }
    
    return table.find(ADMIN_IDS, player.UserId) ~= nil
end

-- Function to process a model that doesn't have a primary part
local function addPrimaryPart(model)
    -- Skip if already has primary part
    if model.PrimaryPart then 
        return false 
    end
    
    -- Get model bounds to find the center
    local modelCFrame, modelSize = model:GetBoundingBox()
    
    -- Create a new invisible reference part
    local refPart = Instance.new("Part")
    refPart.Name = "PrimaryReference"
    refPart.Size = Vector3.new(1, 1, 1)
    refPart.Transparency = 1
    refPart.CanCollide = false
    refPart.Anchored = true
    refPart.CFrame = modelCFrame
    refPart.Parent = model
    
    -- Set as primary part
    model.PrimaryPart = refPart
    
    print("[PrimaryPartAssignment] Added primary part to model: " .. model:GetFullName())
    
    return true
end

-- Function to recursively search through all models
local function processAllModels(parent, counter, debug)
    if not counter then
        counter = {count = 0, total = 0}
    end
    
    if debug then
        print("[PrimaryPartAssignment] Processing folder: " .. parent:GetFullName())
    end
    
    for _, child in pairs(parent:GetChildren()) do
        -- If it's a model, try to add primary part
        if child:IsA("Model") then
            counter.total += 1
            if addPrimaryPart(child) then
                counter.count += 1
                
                -- Print progress every 10 models
                if counter.count % 10 == 0 or debug then
                    print("[PrimaryPartAssignment] Progress: " .. counter.count .. " of " .. counter.total .. " models updated")
                end
            elseif debug then
                print("[PrimaryPartAssignment] Skipped model (already has primary part): " .. child:GetFullName())
            end
        end
        
        -- Process children regardless of type
        if #child:GetChildren() > 0 then
            processAllModels(child, counter)
        end
    end
    
    return counter.count
end

-- Create a function that will be accessible globally
local function assignPrimaryParts(targetFolderName)
    -- Default to GymParts if no folder name provided
    targetFolderName = targetFolderName or "GymParts"
    
    print("Looking for folder: " .. targetFolderName)
    
    -- Look for the folder in workspace first
    local targetFolder = workspace:FindFirstChild(targetFolderName)
    
    -- If not found in workspace, try ServerStorage
    if not targetFolder then
        local ServerStorage = game:GetService("ServerStorage")
        targetFolder = ServerStorage:FindFirstChild(targetFolderName)
    end
    
    -- If still not found, try other common locations
    if not targetFolder then
        -- Try ReplicatedStorage
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        targetFolder = ReplicatedStorage:FindFirstChild(targetFolderName)
        
        -- Try game.Workspace.Map if exists
        if not targetFolder and workspace:FindFirstChild("Map") then
            targetFolder = workspace.Map:FindFirstChild(targetFolderName)
        end
    end
    
    if not targetFolder then
        warn("Could not find folder: " .. targetFolderName)
        return "Error: Folder '" .. targetFolderName .. "' not found in workspace or storage"
    end
    
    print("Starting to process all models in " .. targetFolderName .. "...")
    local count = processAllModels(targetFolder)
    print("Completed! Added primary parts to " .. count .. " models")
    
    if count == 0 then
        return "No models needed primary parts in " .. targetFolderName
    else
        return "Added primary parts to " .. count .. " models in " .. targetFolderName
    end
end

-- Register the function globally for admin use
_G.AssignPrimaryParts = assignPrimaryParts

-- Create a RemoteFunction for client access
local assignPrimaryPartsRemote = Instance.new("RemoteFunction")
assignPrimaryPartsRemote.Name = "AssignPrimaryPartsRemote"
assignPrimaryPartsRemote.Parent = ReplicatedStorage

-- Handle remote function calls from clients
assignPrimaryPartsRemote.OnServerInvoke = function(player, targetFolderName)
    if not isAuthorized(player) then
        return "Error: Not authorized"
    end
    
    return assignPrimaryParts(targetFolderName)
end

print("Primary Part Assignment Command initialized")

return {
    AssignPrimaryParts = assignPrimaryParts
}
