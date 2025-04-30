--!strict
-- April29FixesInstaller.server.lua
-- Automatically installs all critical fixes for April 29, 2025
-- Run this script to set up the fixed modules in your Roblox project

-- Services
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("===================================================")
print("CRITICAL FIXES INSTALLER - April 29, 2025")
print("===================================================")

-- Helper functions
local function ensureFolderExists(parent, folderName)
    local folder = parent:FindFirstChild(folderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = parent
        print("Created folder: " .. parent.Name .. "/" .. folderName)
    end
    return folder
end

local function copyModule(sourceModule, targetParent, newName)
    newName = newName or sourceModule.Name
    
    -- Check if module already exists
    local existingModule = targetParent:FindFirstChild(newName)
    if existingModule then
        print("Module already exists: " .. targetParent:GetFullName() .. "/" .. newName .. " - Updating...")
        existingModule:Destroy()
    end
    
    -- Clone the module
    local clonedModule = sourceModule:Clone()
    clonedModule.Name = newName
    clonedModule.Parent = targetParent
    print("Installed module: " .. targetParent:GetFullName() .. "/" .. newName)
    
    return clonedModule
end

-- Set up folder structure
print("\nSetting up folder structure...")
local srcFolder = ensureFolderExists(ReplicatedStorage, "src")
local sharedFolder = ensureFolderExists(srcFolder, "shared")
local serverFolder = ensureFolderExists(srcFolder, "server")
local dataManagementFolder = ensureFolderExists(serverFolder, "DataManagement")
local systemsFolder = ensureFolderExists(serverFolder, "Systems")

-- Install the modules
print("\nInstalling fixed modules...")

-- 1. Install TycoonFolderInitializer
local tycoonFolderInitializer = script.Parent:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("DataManagement"):FindFirstChild("TycoonFolderInitializer.server.luau")
if tycoonFolderInitializer then
    copyModule(tycoonFolderInitializer, dataManagementFolder)
    print("✓ Installed TycoonFolderInitializer.server.luau")
else
    warn("✗ Could not find TycoonFolderInitializer.server.luau")
end

-- 2. Install DataPersistenceFix
local dataPersistenceFix = script.Parent:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("DataManagement"):FindFirstChild("DataPersistenceFix.server.luau")
if dataPersistenceFix then
    copyModule(dataPersistenceFix, dataManagementFolder)
    print("✓ Installed DataPersistenceFix.server.luau")
else
    warn("✗ Could not find DataPersistenceFix.server.luau")
end

-- 3. Install BuyTileSystemFix
local buyTileSystemFix = script.Parent:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Systems"):FindFirstChild("BuyTileSystemFix.server.luau")
if buyTileSystemFix then
    copyModule(buyTileSystemFix, systemsFolder)
    print("✓ Installed BuyTileSystemFix.server.luau")
else
    warn("✗ Could not find BuyTileSystemFix.server.luau")
end

-- 4. Install AssetValidator
local assetValidator = script.Parent:FindFirstChild("src"):FindFirstChild("shared"):FindFirstChild("AssetValidator.luau")
if assetValidator then
    copyModule(assetValidator, sharedFolder)
    print("✓ Installed AssetValidator.luau")
else
    warn("✗ Could not find AssetValidator.luau")
end

-- 5. Install UIRegistry
local uiRegistry = script.Parent:FindFirstChild("src"):FindFirstChild("shared"):FindFirstChild("UIRegistry.luau")
if uiRegistry then
    copyModule(uiRegistry, sharedFolder)
    print("✓ Installed UIRegistry.luau")
else
    warn("✗ Could not find UIRegistry.luau")
end

-- 6. Install SoundAssetValidator
local soundAssetValidator = script.Parent:FindFirstChild("src"):FindFirstChild("shared"):FindFirstChild("SoundAssetValidator.luau")
if soundAssetValidator then
    copyModule(soundAssetValidator, sharedFolder)
    print("✓ Installed SoundAssetValidator.luau")
else
    warn("✗ Could not find SoundAssetValidator.luau")
end

-- 7. Install SoundSystemManager
local soundSystemManager = script.Parent:FindFirstChild("src"):FindFirstChild("shared"):FindFirstChild("SoundSystemManager.luau")
if soundSystemManager then
    copyModule(soundSystemManager, sharedFolder)
    print("✓ Installed SoundSystemManager.luau")
else
    warn("✗ Could not find SoundSystemManager.luau")
end

-- 8. Install SoundSystemFix
local clientFolder = ensureFolderExists(srcFolder, "client")
local soundSystemFix = script.Parent:FindFirstChild("src"):FindFirstChild("client"):FindFirstChild("SoundSystemFix.client.luau")
if soundSystemFix then
    copyModule(soundSystemFix, clientFolder)
    print("✓ Installed SoundSystemFix.client.luau")
else
    warn("✗ Could not find SoundSystemFix.client.luau")
end

-- Create GymParts folder in ServerStorage if it doesn't exist
local gymPartsFolder = ensureFolderExists(ServerStorage, "GymParts")
print("✓ Ensured GymParts folder exists in ServerStorage")

-- Create a test default gym part
local defaultGymPart = gymPartsFolder:FindFirstChild("DefaultGymEquipment")
if not defaultGymPart then
    local newDefaultPart = Instance.new("Model")
    newDefaultPart.Name = "DefaultGymEquipment"
    
    -- Add a basic part to the model
    local part = Instance.new("Part")
    part.Anchored = true
    part.Size = Vector3.new(4, 1, 4)
    part.BrickColor = BrickColor.new("Bright blue")
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = newDefaultPart
    newDefaultPart.PrimaryPart = part
    
    -- Add ID value
    local idValue = Instance.new("StringValue")
    idValue.Name = "ID"
    idValue.Value = "DefaultGymEquipment"
    idValue.Parent = newDefaultPart
    
    newDefaultPart.Parent = gymPartsFolder
    print("✓ Created default gym part")
end

-- Create first few gym parts with IDs
for i = 1, 5 do
    local gymPartName = tostring(i)
    if not gymPartsFolder:FindFirstChild(gymPartName) then
        local newPart = Instance.new("Model")
        newPart.Name = gymPartName
        
        -- Add a basic part to the model
        local part = Instance.new("Part")
        part.Anchored = true
        part.Size = Vector3.new(4, 2, 4)
        part.BrickColor = BrickColor.new("Bright green")
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Parent = newPart
        newPart.PrimaryPart = part
        
        -- Add ID value
        local idValue = Instance.new("StringValue")
        idValue.Name = "ID"
        idValue.Value = gymPartName
        idValue.Parent = newPart
        
        newPart.Parent = gymPartsFolder
        print("✓ Created gym part with ID: " .. gymPartName)
    end
end

print("\nRunning initialization...")

-- Initialize the TycoonFolderInitializer for existing players
for _, player in ipairs(Players:GetPlayers()) do
    print("Initializing Tycoon folder for: " .. player.Name)
    
    local tycoonFolder = player:FindFirstChild("Tycoon")
    if not tycoonFolder then
        tycoonFolder = Instance.new("Folder")
        tycoonFolder.Name = "Tycoon"
        tycoonFolder.Parent = player
        print("Created Tycoon folder for: " .. player.Name)
    end
    
    -- Create basic required folders
    local requiredFolders = {"TycoonData", "Stats", "Purchases", "Equipment", "FrontDesk", "Progress", "Settings"}
    for _, folderName in ipairs(requiredFolders) do
        if not tycoonFolder:FindFirstChild(folderName) then
            local newFolder = Instance.new("Folder")
            newFolder.Name = folderName
            newFolder.Parent = tycoonFolder
        end
    end
    
    print("Basic Tycoon structure initialized for: " .. player.Name)
end

print("\n===================================================")
print("INSTALLATION COMPLETE!")
print("\nAll critical fixes for April 29, 2025 have been installed.")
print("Review the fixes in RobloxIssues_Updated_April29_FIXED.txt")
print("===================================================")

-- Cleanup
script.Disabled = true
