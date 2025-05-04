-- GlobalAdminCommandInitializer.server.luau
-- Initializes global admin commands to ensure they're accessible
-- Created: May 4, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to find the Commands folder in the ServerScriptService
local function findCommandsFolder()
    -- Try direct path
    if ServerScriptService:FindFirstChild("Commands") then
        return ServerScriptService:FindFirstChild("Commands")
    end
    
    -- Try src/server/Commands path
    if ServerScriptService:FindFirstChild("src") then
        local serverFolder = ServerScriptService.src:FindFirstChild("server")
        if serverFolder and serverFolder:FindFirstChild("Commands") then
            return serverFolder:FindFirstChild("Commands")
        end
    end
    
    -- Not found
    return nil
end

-- Setup global function stubs if they don't exist
local function setupGlobalCommands()
    local commandFunctions = {
        -- Tycoon Structure commands
        "ProcessTycoon",
        "AutomateGym",
        "ShowTycoonInfo",
        
        -- Buy Tile System commands
        "SetupBuyTileSystem",
        "AutoSetupBuyTiles",
        "GenerateBuildOrder",
        "GenerateBuyTileConfig",
        
        -- Visualization commands
        "ShowHitboxes",
        "HideHitboxes",
        
        -- Validation commands
        "ValidateGymModels",
        "AssignPrimaryParts"
    }
    
    -- Create placeholder functions for commands that don't exist
    for _, funcName in ipairs(commandFunctions) do
        if not _G[funcName] then
            _G[funcName] = function(...)
                print("Global command stub for " .. funcName .. " called")
                
                -- Create a shared result value
                local resultValue = Instance.new("StringValue")
                resultValue.Name = "AdminCommandResult_" .. funcName
                resultValue.Value = "Command not fully implemented: " .. funcName
                resultValue.Parent = ReplicatedStorage
                
                -- Auto-remove after 10 seconds
                task.delay(10, function()
                    if resultValue and resultValue.Parent then
                        resultValue:Destroy()
                    end
                end)
                
                return "Command not fully implemented: " .. funcName
            end
            
            print("Created stub for global command: " .. funcName)
        else
            print("Global command already exists: " .. funcName)
        end
    end
end

-- Try to load the primary part assignment command
local function loadPrimaryPartCommand()
    local commandsFolder = findCommandsFolder()
    if not commandsFolder then
        warn("Commands folder not found, cannot load PrimaryPartAssignmentCommand")
        return false
    end
    
    -- Look for the command module
    local primaryPartModule = commandsFolder:FindFirstChild("PrimaryPartAssignmentCommand")
    if primaryPartModule and primaryPartModule:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(primaryPartModule)
        end)
        
        if success then
            print("Successfully loaded PrimaryPartAssignmentCommand")
            return true
        else
            warn("Failed to load PrimaryPartAssignmentCommand: " .. tostring(result))
            return false
        end
    else
        warn("PrimaryPartAssignmentCommand not found in Commands folder")
        return false
    end
end

-- Initialize the commands
setupGlobalCommands()
loadPrimaryPartCommand()

print("Global admin commands initialized")

-- Create a specific test command for showing hitboxes
if not _G.ShowHitboxes then
    _G.ShowHitboxes = function()
        -- Example implementation to show hitboxes
        local hitboxesShown = 0
        
        -- Find parts that might be hitboxes
        for _, descendant in pairs(workspace:GetDescendants()) do
            if descendant:IsA("BasePart") and 
               (descendant.Name:find("Hitbox") or descendant.Name:find("Collision")) and
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
        
        return "Showed " .. hitboxesShown .. " hitboxes"
    end
    
    print("Created implementation for ShowHitboxes command")
end

if not _G.HideHitboxes then
    _G.HideHitboxes = function()
        -- Example implementation to hide hitboxes
        local hitboxesHidden = 0
        
        -- Find parts that might be hitboxes
        for _, descendant in pairs(workspace:GetDescendants()) do
            if descendant:IsA("BasePart") and 
               descendant:FindFirstChild("OriginalTransparency") and
               (descendant.Name:find("Hitbox") or descendant.Name:find("Collision")) then
                
                -- Restore original transparency
                local originalValue = descendant:FindFirstChild("OriginalTransparency")
                if originalValue and originalValue:IsA("NumberValue") then
                    descendant.Transparency = originalValue.Value
                    hitboxesHidden = hitboxesHidden + 1
                end
            end
        end
        
        return "Hidden " .. hitboxesHidden .. " hitboxes"
    end
    
    print("Created implementation for HideHitboxes command")
end
