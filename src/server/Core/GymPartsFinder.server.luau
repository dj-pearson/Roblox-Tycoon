-- lua
--[[
    GymPartsFinder.server.luau

    Module script to find the GymParts folder in the workspace.

    Created: May 2025
]]--

local GymPartsFinder = {}

-- Find all parts in the game and return them in a table indexed by name
function GymPartsFinder:GetParts()
    local parts = {}
    local world = game:GetService("Workspace").World
    if not world then
        warn("World not found in Workspace")
        return parts -- Return empty table if World is not found
    end

    local gymPartsFolder = world:FindFirstChild("GymParts")
    if not gymPartsFolder then
        gymPartsFolder = Instance.new("Folder")
        gymPartsFolder.Name = "GymParts"
        gymPartsFolder.Parent = world
        warn("GymParts folder not found, created a new one in World.")
    end

    for _, descendant in pairs(gymPartsFolder:GetDescendants()) do
        if descendant:IsA("BasePart") then
            parts[descendant.Name] = descendant
        end
    end
    return parts
end

function GymPartsFinder:Initialize()
    local _ = self:GetParts() -- Ensure GymParts folder exists
end
return GymPartsFinder
