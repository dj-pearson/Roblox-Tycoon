--!strict
--[[
    ImprovedBackupUIScripts.server.luau
    
    An improved script for backing up UI scripts in the game.
    This version uses a more robust approach to finding scripts.
]]

local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the backup folder
local backupFolder = Instance.new("Folder")
backupFolder.Name = "Legacy_UI_Backup_" .. os.date("%Y%m%d_%H%M%S")
backupFolder.Parent = ServerStorage

print("Creating UI script backups with improved script...")

-- Create category folders
local starterGuiFolder = Instance.new("Folder")
starterGuiFolder.Name = "StarterGui"
starterGuiFolder.Parent = backupFolder

local starterPlayerScriptsFolder = Instance.new("Folder")
starterPlayerScriptsFolder.Name = "StarterPlayerScripts"
starterPlayerScriptsFolder.Parent = backupFolder

local otherScriptsFolder = Instance.new("Folder")
otherScriptsFolder.Name = "OtherUIScripts"
otherScriptsFolder.Parent = backupFolder

-- Automatically find scripts in StarterGui
local function scanAndBackupScripts()
    local backupCount = 0
    
    -- Recursive function to search for UI-related scripts
    local function findAndBackupUIScripts(parent, destinationFolder, currentPath)
        for _, child in ipairs(parent:GetChildren()) do
            -- Check if it's a script
            if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
                -- Check if it's UI-related based on name
                if child.Name:find("UI") or child.Name:find("Gui") or child.Name:match("Menu") then
                    -- Create a folder structure that matches the actual location
                    local currentFolder = destinationFolder
                    
                    -- Build path parts
                    local pathParts = {}
                    local current = child.Parent
                    while current and current ~= parent.Parent do
                        table.insert(pathParts, 1, current.Name)
                        current = current.Parent
                    end
                    
                    -- Create folders for the path
                    for _, folderName in ipairs(pathParts) do
                        local folder = currentFolder:FindFirstChild(folderName)
                        if not folder then
                            folder = Instance.new("Folder")
                            folder.Name = folderName
                            folder.Parent = currentFolder
                        end
                        currentFolder = folder
                    end
                    
                    -- Clone the script to the backup
                    local clone = child:Clone()
                    clone.Parent = currentFolder
                    backupCount = backupCount + 1
                    
                    print("Backed up: " .. currentPath .. "/" .. child.Name)
                end
            end
            
            -- Recursively search in children
            if #child:GetChildren() > 0 then
                findAndBackupUIScripts(child, destinationFolder, currentPath .. "/" .. child.Name)
            end
        end
    end
    
    -- Search in StartGui
    print("Searching in StarterGui...")
    findAndBackupUIScripts(StarterGui, starterGuiFolder, "StarterGui")
    
    -- Search in StarterPlayerScripts
    print("Searching in StarterPlayerScripts...")
    findAndBackupUIScripts(StarterPlayer.StarterPlayerScripts, starterPlayerScriptsFolder, "StarterPlayerScripts")
    
    -- Search in ReplicatedStorage for client UI scripts
    print("Searching in ReplicatedStorage for UI scripts...")
    if ReplicatedStorage:FindFirstChild("src") then
        if ReplicatedStorage.src:FindFirstChild("client") then
            if ReplicatedStorage.src.client:FindFirstChild("UI") then
                findAndBackupUIScripts(ReplicatedStorage.src.client.UI, otherScriptsFolder, "client/UI")
            end
        end
    end
    
    -- Additional direct search for specific UI files from our redundant files list
    print("Searching for specific UI scripts by name...")
    local function tryBackupByName(scriptName, destination)
        local script = game:FindFirstChild(scriptName, true)
        if script and (script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript")) then
            local clone = script:Clone()
            clone.Parent = destination
            backupCount = backupCount + 1
            print("Backed up by name search: " .. scriptName)
            return true
        end
        return false
    end
    
    -- Try to find specific UI scripts by name from our redundant files list
    local specificScripts = {
        "MainMenuUI", "SettingsUI", "StatsGui", "RebirthUI", "RebirthMenuUI",
        "PlayerStatsDisplay", "GymMenuUI", "ProgressBar", "AchievementsUI",
        "GuestPassUI", "TemperatureDisplay", "SideMenu", "Tutorial"
    }
    
    for _, scriptName in ipairs(specificScripts) do
        tryBackupByName(scriptName, otherScriptsFolder)
    end
    
    return backupCount
end

-- Execute the backup
local backupCount = scanAndBackupScripts()

print("=== UI Script Backup Summary ===")
print("Total scripts backed up: " .. backupCount)
print("Backup location: ServerStorage/" .. backupFolder.Name)
print("================================")

-- Return values for debugging
return {
    backupFolder = backupFolder,
    backupCount = backupCount
}
