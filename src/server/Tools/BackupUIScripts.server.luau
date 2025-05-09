--!strict
--[[
    BackupUIScripts.server.luau
    
    This script creates backups of all UI scripts that are scheduled for elimination.
    Run this script once before starting the elimination process.
    
    Updated version - Improved script location logic
]]

local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the backup folder
local backupFolder = Instance.new("Folder")
backupFolder.Name = "Legacy_UI_Backup_" .. os.date("%Y%m%d")
backupFolder.Parent = ServerStorage

print("Creating UI script backups...")

-- Helper function to find a script in the Roblox instance hierarchy
local function findScriptInGame(scriptPath)
    local parts = string.split(scriptPath, "/")
    local scriptName = parts[#parts]
    
    -- Start with different root locations based on path prefix
    local currentLocation
    
    if scriptPath:find("^StarterGui/") then
        currentLocation = StarterGui
        -- Skip the first part (StarterGui)
        table.remove(parts, 1)
    elseif scriptPath:find("^StarterPlayerScripts/") then
        currentLocation = StarterPlayer.StarterPlayerScripts
        -- Skip the first part (StarterPlayerScripts)
        table.remove(parts, 1)
    elseif scriptPath:find("^client/UI/") then
        -- Try different possible paths for client UI in your project structure
        if ReplicatedStorage:FindFirstChild("src") and 
           ReplicatedStorage.src:FindFirstChild("client") and
           ReplicatedStorage.src.client:FindFirstChild("UI") then
            currentLocation = ReplicatedStorage.src.client.UI
            -- Skip the first two parts (client/UI)
            table.remove(parts, 1)
            table.remove(parts, 1)
        else
            -- Alternative paths that might exist in your project
            local paths = {
                game.ReplicatedStorage:FindFirstChild("client", true),
                game:FindFirstChild("client", true),
                ReplicatedStorage:FindFirstChild("UI", true)
            }
            
            for _, path in ipairs(paths) do
                if path then
                    currentLocation = path
                    break
                end
            end
            
            if not currentLocation then
                return nil
            end
        end
    else
        -- Generic search for scripts by name as fallback
        return game:FindFirstChild(scriptName, true)
    end
    
    -- Navigate through the path
    for i = 1, #parts - 1 do
        if currentLocation:FindFirstChild(parts[i]) then
            currentLocation = currentLocation:FindFirstChild(parts[i])
        else
            -- Try a wildcard search one level down
            local found = false
            for _, child in ipairs(currentLocation:GetChildren()) do
                if child:FindFirstChild(parts[i]) then
                    currentLocation = child:FindFirstChild(parts[i])
                    found = true
                    break
                end
            end
            
            if not found then return nil end
        end
    end
    
    -- Find the actual script
    return currentLocation:FindFirstChild(scriptName)
end

-- Helper function to backup a script
local function backupScript(scriptPath, destinationFolder)
    local parts = string.split(scriptPath, "/")
    local scriptName = parts[#parts]
    
    -- Find the script using our improved search function
    local script = findScriptInGame(scriptPath)
    
    -- Fallback: Try direct search by name as a last resort
    if not script then
        -- Remove file extensions for more flexible searching
        local cleanName = scriptName:gsub("%.client%.luau$", ""):gsub("%.luau$", ""):gsub("%.lua$", "")
        
        -- Try various name patterns
        for _, pattern in ipairs({scriptName, cleanName, cleanName.."UI", cleanName.."Client"}) do
            script = game:FindFirstChild(pattern, true)
            if script and (script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript")) then
                break
            end
        end
    end
    
    -- If script is found, clone it to the backup folder
    if script then
        -- Create parent folder structure in backup
        local currentFolder = destinationFolder
        for i = 1, #parts - 1 do
            local folderName = parts[i]
            local folder = currentFolder:FindFirstChild(folderName)
            if not folder then
                folder = Instance.new("Folder")
                folder.Name = folderName
                folder.Parent = currentFolder
            end
            currentFolder = folder
        end
        
        -- Clone the script
        local clone = script:Clone()
        clone.Parent = currentFolder
        return true
    end
    
    return false
end

-- Backup StarterGui scripts
local starterGuiFolder = Instance.new("Folder")
starterGuiFolder.Name = "StarterGui"
starterGuiFolder.Parent = backupFolder

local starterGuiScripts = {
    "StarterGui/MainMenuUI.client.luau",
    "StarterGui/SettingsUI.client.luau",
    "StarterGui/StatsGui.client.luau",
    "StarterGui/RebirthUI.client.luau",
    "StarterGui/RebirthUI_Enhanced.client.luau",
    "StarterGui/RebirthMenuUI.client.luau",
    "StarterGui/RebirthUIFixes.luau",
    "StarterGui/TemperatureDisplay.client.luau",
    "StarterGui/DoubleMemberPurchaseGui.client.luau",
    "StarterGui/BuilderBoostPurchaseGui.client.luau",
    "StarterGui/CloseButtonFactory.lua"
}

-- Backup StarterPlayerScripts scripts
local starterPlayerScriptsFolder = Instance.new("Folder")
starterPlayerScriptsFolder.Name = "StarterPlayerScripts"
starterPlayerScriptsFolder.Parent = backupFolder

local starterPlayerScripts = {
    "StarterPlayerScripts/UIComponentDemo.client.luau",
    "StarterPlayerScripts/UIComponentDemo.client-PearsonASUS.luau"
}

-- Backup other UI scripts
local otherScriptsFolder = Instance.new("Folder")
otherScriptsFolder.Name = "OtherUIScripts"
otherScriptsFolder.Parent = backupFolder

local otherScripts = {
    "client/UI/MainMenuUI.client.luau",
    "client/UI/MainMenuUILoader.client.luau",
    "client/UI/AchievementsUI.client.luau",
    "client/UI/RebirthUI.client.luau",
    "client/UI/GuestPassUI.client.luau",
    "client/UI/GymMenuUI.client.luau",
    "client/UI/PlayerStatsDisplay.client.luau",
    "client/UI/ProgressBar.client.luau"
}

-- Backup all scripts
local backupCount = 0
for _, scriptPath in ipairs(starterGuiScripts) do
    if backupScript(scriptPath, starterGuiFolder) then
        backupCount = backupCount + 1
        print("Backed up: " .. scriptPath)
    end
end

for _, scriptPath in ipairs(starterPlayerScripts) do
    if backupScript(scriptPath, starterPlayerScriptsFolder) then
        backupCount = backupCount + 1
        print("Backed up: " .. scriptPath)
    end
end

for _, scriptPath in ipairs(otherScripts) do
    if backupScript(scriptPath, otherScriptsFolder) then
        backupCount = backupCount + 1
        print("Backed up: " .. scriptPath)
    end
end

print("UI script backup complete! " .. backupCount .. " scripts backed up in ServerStorage." .. backupFolder.Name)
