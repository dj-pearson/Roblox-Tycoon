--[[
    ModelScaleRenamer.lua
    
    This script runs in Roblox Studio to find all models in Workspace.GymParts
    with a scale less than 1, and adds "_Big" to their name.
    
    Instructions:
    1. Open your game in Roblox Studio
    2. Run this script in the Command Bar (View > Command Bar)
    3. The script will identify and rename models automatically
]]

-- Configuration
local DRY_RUN = false  -- Set to true to only print changes without renaming
local THRESHOLD = 1.0  -- Scale threshold for renaming (models below this value get renamed)
local TARGET_FOLDER = "GymParts"  -- Name of the folder containing models to check

-- Helper function to get model scale
local function getModelScale(model)
    -- Try to get primary part size
    if model.PrimaryPart then
        local size = model.PrimaryPart.Size
        return (size.X + size.Y + size.Z) / 3
    end
    
    -- If no primary part, check all parts
    local totalSize = Vector3.new(0, 0, 0)
    local partCount = 0
    
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            totalSize = totalSize + part.Size
            partCount = partCount + 1
        end
    end
    
    if partCount > 0 then
        return (totalSize.X + totalSize.Y + totalSize.Z) / (3 * partCount)
    end
    
    -- Default if we can't determine
    return 1.0
end

-- Find the GymParts folder
local gymParts = nil
if workspace:FindFirstChild(TARGET_FOLDER) then
    gymParts = workspace[TARGET_FOLDER]
else
    warn("Could not find GymParts folder in Workspace. Please make sure it exists.")
    return
end

-- Count variables
local totalChecked = 0
local totalRenamed = 0

-- Process all models in GymParts
local function processFolder(folder)
    for _, child in pairs(folder:GetChildren()) do
        if child:IsA("Model") then
            totalChecked = totalChecked + 1
            
            -- Get the scale
            local scale = getModelScale(child)
            
            -- Check if it needs renaming
            if scale < THRESHOLD and not string.match(child.Name, "_Big$") then
                local oldName = child.Name
                local newName = oldName .. "_Big"
                
                if DRY_RUN then
                    print(string.format("Would rename '%s' to '%s' (Scale: %.2f)", oldName, newName, scale))
                else
                    child.Name = newName
                    print(string.format("Renamed '%s' to '%s' (Scale: %.2f)", oldName, newName, scale))
                    totalRenamed = totalRenamed + 1
                end
            end
        elseif child:IsA("Folder") or child:IsA("Model") then
            -- Recursively check subfolders
            processFolder(child)
        end
    end
end

-- Start processing
print("Starting model scale check in " .. TARGET_FOLDER .. "...")
processFolder(gymParts)

-- Report summary
print("========== Summary ==========")
print("Total models checked: " .. totalChecked)
if DRY_RUN then
    print("Models that would be renamed: " .. totalRenamed)
    print("This was a dry run. No actual renaming was performed.")
else
    print("Models renamed: " .. totalRenamed)
    print("Renaming complete.")
end
print("============================")
