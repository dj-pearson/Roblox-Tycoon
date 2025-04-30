--!strict
--[[
    ClientFixDistributor.server.luau
    Distributes client-side fix scripts to players when they join
    
    Created: April 29, 2025
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CLIENT_FIXES_FOLDER = "src/client"
local FIX_SCRIPTS = {
    "UIAccessRestrictor.client" -- Use the correct filename with extension
}

-- Utility functions
local function log(message)
    print("[ClientFixDistributor] " .. message)
end

-- Find script in various paths
local function findScript(scriptName)
    local paths = {
        ServerScriptService:FindFirstChild("src"):FindFirstChild("client"),
        ServerScriptService:FindFirstChild(CLIENT_FIXES_FOLDER),
        script.Parent:FindFirstChild(CLIENT_FIXES_FOLDER),
        script.Parent
    }
    
    for _, path in ipairs(paths) do
        if path then
            local script = path:FindFirstChild(scriptName)
            if script then
                return script
            end
        end
    end
    
    return nil
end

-- Distribute fix scripts to a player
local function distributeFixesToPlayer(player)
    log("Distributing client fixes to player: " .. player.Name)
    
    -- Create a folder for fixes in the player's PlayerScripts
    local playerScripts = player:WaitForChild("PlayerScripts")
    local fixesFolder = playerScripts:FindFirstChild("AprilFixes") or Instance.new("Folder")
    fixesFolder.Name = "AprilFixes"
    fixesFolder.Parent = playerScripts
    
    -- Distribute each fix script
    for _, scriptName in ipairs(FIX_SCRIPTS) do
        local sourceScript = findScript(scriptName)
        
        if sourceScript then
            log("Distributing fix script: " .. scriptName)
            
            -- Check if script already exists
            local existingScript = playerScripts:FindFirstChild(scriptName) or fixesFolder:FindFirstChild(scriptName)
            if existingScript then
                existingScript:Destroy()
            end
            
            -- Clone and distribute the script
            local scriptClone = sourceScript:Clone()
            scriptClone.Parent = playerScripts
        else
            warn("[ClientFixDistributor] Could not find source script: " .. scriptName)
        end
    end
    
    -- Send the startup script
    local startupScript = findScript("AprilFixesClientStartup")
    if startupScript then
        log("Distributing client startup script")
        
        -- Clone and distribute the startup script
        local clientStartupClone = startupScript:Clone()
        clientStartupClone.Parent = playerScripts
    else
        warn("[ClientFixDistributor] Could not find client startup script")
    end
    
    log("All client fixes distributed to player: " .. player.Name)
end

-- Connect to player joining event
Players.PlayerAdded:Connect(distributeFixesToPlayer)

-- Apply to existing players
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        distributeFixesToPlayer(player)
    end)
end

log("Client fix distributor initialized!")
return true
