-- AdminCommandImplementations.lua
-- Central repository of admin command implementations
-- Created: May 4, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminCommands = {}

-- Logging function
local function log(message)
    local timestamp = os.date("%H:%M:%S")
    print("[AdminCommands " .. timestamp .. "] " .. message)
end

-- Show hitboxes implementation
function AdminCommands.showHitboxes()
    log("Executing ShowHitboxes")
    local hitboxesShown = 0
    
    -- Find parts that might be hitboxes
    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant:IsA("BasePart") and 
           (string.find(descendant.Name, "Hitbox") or string.find(descendant.Name, "Collision")) and
           descendant.Transparency > 0.9 then
            
            -- Store original transparency
            if not descendant:FindFirstChild("OriginalTransparency") then
                local originalValue = Instance.new("NumberValue")
                originalValue.Name = "OriginalTransparency"
                originalValue.Value = descendant.Transparency
                originalValue.Parent = descendant
            end
            
            -- Make hitbox visible
            descendant.Transparency = 0.5
            descendant.Color = Color3.fromRGB(255, 0, 0) -- Red for visualization
            hitboxesShown = hitboxesShown + 1
        end
    end
    
    log("Showed " .. hitboxesShown .. " hitboxes")
    return "Showed " .. hitboxesShown .. " hitboxes"
end

-- Hide hitboxes implementation
function AdminCommands.hideHitboxes()
    log("Executing HideHitboxes")
    local hitboxesHidden = 0
    
    -- Find parts that might be hitboxes
    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant:IsA("BasePart") and 
           descendant:FindFirstChild("OriginalTransparency") and
           (string.find(descendant.Name, "Hitbox") or string.find(descendant.Name, "Collision")) then
            
            -- Restore original transparency
            local originalValue = descendant:FindFirstChild("OriginalTransparency")
            if originalValue and originalValue:IsA("NumberValue") then
                descendant.Transparency = originalValue.Value
                hitboxesHidden = hitboxesHidden + 1
            end
        end
    end
    
    log("Hidden " .. hitboxesHidden .. " hitboxes")
    return "Hidden " .. hitboxesHidden .. " hitboxes"
end

-- Assign primary parts implementation via remote
function AdminCommands.assignPrimaryParts(targetFolderName)
    log("Executing AssignPrimaryParts")
    targetFolderName = targetFolderName or "GymParts"
    
    -- Try to use remote function
    local assignPrimaryPartsRemote = ReplicatedStorage:FindFirstChild("AssignPrimaryPartsRemote")
    if assignPrimaryPartsRemote and assignPrimaryPartsRemote:IsA("RemoteFunction") then
        local success, result = pcall(function()
            return assignPrimaryPartsRemote:InvokeServer(targetFolderName)
        end)
        
        if success then
            log("AssignPrimaryParts remote call successful: " .. tostring(result))
            return result
        else
            log("AssignPrimaryParts remote call failed: " .. tostring(result))
            return "Error executing AssignPrimaryParts: " .. tostring(result)
        end
    else
        log("AssignPrimaryPartsRemote not found, using direct implementation")
        
        -- Direct implementation when remote isn't available
        local targetFolder = workspace:FindFirstChild(targetFolderName)
        if not targetFolder then
            log("Target folder '" .. targetFolderName .. "' not found")
            return "Error: Target folder '" .. targetFolderName .. "' not found"
        end
        
        local modelsProcessed = 0
        local modelsUpdated = 0
        
        -- Function to add a primary part to a model
        local function addPrimaryPart(model)
            if not model:IsA("Model") then return false end
            modelsProcessed = modelsProcessed + 1
            
            if model.PrimaryPart then return false end
            
            local modelCFrame, modelSize = model:GetBoundingBox()
            local refPart = Instance.new("Part")
            refPart.Name = "PrimaryReference"
            refPart.Size = Vector3.new(1, 1, 1)
            refPart.Transparency = 1
            refPart.CanCollide = false
            refPart.Anchored = true
            refPart.CFrame = modelCFrame
            refPart.Parent = model
            model.PrimaryPart = refPart
            
            modelsUpdated = modelsUpdated + 1
            return true
        end
        
        -- Process all models in the target folder
        for _, child in pairs(targetFolder:GetChildren()) do
            if child:IsA("Model") then
                addPrimaryPart(child)
            end
        end
        
        log("Direct implementation - processed " .. modelsProcessed .. " models, updated " .. modelsUpdated)
        return "Processed " .. modelsProcessed .. " models, added primary parts to " .. modelsUpdated
    end
end

-- Process tycoon structure stub
function AdminCommands.processTycoon()
    log("Executing ProcessTycoon (stub)")
    return "ProcessTycoon command executed"
end

-- Automate gym stub
function AdminCommands.automateGym()
    log("Executing AutomateGym (stub)")
    return "AutomateGym command executed"
end

-- Show tycoon info stub
function AdminCommands.showTycoonInfo()
    log("Executing ShowTycoonInfo (stub)")
    return "ShowTycoonInfo command executed"
end

-- Setup buy tile system stub
function AdminCommands.setupBuyTileSystem()
    log("Executing SetupBuyTileSystem (stub)")
    return "SetupBuyTileSystem command executed"
end

-- Initialize global functions for all admin interfaces
function AdminCommands.initializeGlobals()
    log("Initializing global admin commands")
    
    -- Register commands in global namespace
    _G.ShowHitboxes = AdminCommands.showHitboxes
    _G.HideHitboxes = AdminCommands.hideHitboxes
    _G.AssignPrimaryParts = AdminCommands.assignPrimaryParts
    
    -- Set up stubs for other functions if they don't exist yet
    if not _G.ProcessTycoon then _G.ProcessTycoon = AdminCommands.processTycoon end
    if not _G.AutomateGym then _G.AutomateGym = AdminCommands.automateGym end
    if not _G.ShowTycoonInfo then _G.ShowTycoonInfo = AdminCommands.showTycoonInfo end
    if not _G.SetupBuyTileSystem then _G.SetupBuyTileSystem = AdminCommands.setupBuyTileSystem end
    
    log("Global admin commands registered")
    return true
end

-- Initialize global commands immediately
AdminCommands.initializeGlobals()

return AdminCommands
