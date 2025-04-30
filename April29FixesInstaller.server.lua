--[[
    April29FixesInstaller.server.lua
    Master installer for all April 29, 2025 fixes
    
    Created: April 29, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local INSTALLER_VERSION = "1.0.0"
local INSTALLATION_PATH = ServerScriptService

-- All required fix files
local fixFiles = {
    -- Server-side fixes (core fixes)
    {
        name = "CoreRegistryRestorer.server.luau",
        path = "src/server/Core"
    },
    {
        name = "BuyTilePositionFixer.server.luau",
        path = "src/server"
    },
    {
        name = "ClientFixDistributor.server.luau", 
        path = "src/server"
    },
    
    -- Client-side fixes
    {
        name = "UIAccessRestrictor.client.lua",
        path = "src/client"
    },
    
    -- Startup scripts
    {
        name = "AprilFixesStartup.server.luau",
        path = "src/server"
    },
    
    -- Test scripts
    {
        name = "AprilFixesTestSuite.server.luau",
        path = "src/server"
    }
}

-- Helper functions
local function createNestedPath(parent, path)
    local folders = string.split(path, "/")
    local currentParent = parent
    
    for _, folderName in ipairs(folders) do
        local folder = currentParent:FindFirstChild(folderName)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = currentParent
            print("[Installer] Created folder:", folderName)
        end
        currentParent = folder
    end
    
    return currentParent
end

-- Install the fixes
local function installFixes()
    print("=== April 29 Fixes Installer v" .. INSTALLER_VERSION .. " ===")
    print("Installing fixes to:", INSTALLATION_PATH:GetFullName())
    
    -- Verify all files exist
    local missingFiles = {}
    
    -- Check each fix file
    for _, fileInfo in ipairs(fixFiles) do
        local success = false
        
        -- Try to find the file in multiple locations
        local sourcePaths = {
            "src/" .. fileInfo.path .. "/" .. fileInfo.name,
            fileInfo.path .. "/" .. fileInfo.name,
            fileInfo.name
        }
        
        for _, path in ipairs(sourcePaths) do
            local sourceFile = script:FindFirstChild(path)
            if sourceFile then
                success = true
                break
            end
        end
        
        if not success then
            table.insert(missingFiles, fileInfo.name)
        end
    end
    
    -- Check if any files are missing
    if #missingFiles > 0 then
        warn("The following files are missing:")
        for _, fileName in ipairs(missingFiles) do
            warn("- " .. fileName)
        end
        warn("Please ensure all fix files are included as children of this installer script.")
        warn("Installation aborted.")
        return false
    end
    
    -- Install each fix file
    for _, fileInfo in ipairs(fixFiles) do
        -- Create the destination path
        local destFolder = createNestedPath(INSTALLATION_PATH, fileInfo.path)
        
        -- Find the source file (try multiple paths)
        local sourceFile = nil
        local sourcePaths = {
            "src/" .. fileInfo.path .. "/" .. fileInfo.name,
            fileInfo.path .. "/" .. fileInfo.name,
            fileInfo.name
        }
        
        for _, path in ipairs(sourcePaths) do
            sourceFile = script:FindFirstChild(path)
            if sourceFile then break end
        end
        
        -- Clone and install the file
        if sourceFile then
            -- Check if file already exists
            local existingFile = destFolder:FindFirstChild(fileInfo.name)
            if existingFile then
                existingFile:Destroy()
                print("[Installer] Replaced existing file:", fileInfo.name)
            end
            
            -- Clone and parent the file
            local fileClone = sourceFile:Clone()
            fileClone.Parent = destFolder
            print("[Installer] Installed:", fileInfo.name)
        end
    end
    
    -- Create ClientConfig folder in ReplicatedStorage if it doesn't exist
    local clientConfig = ReplicatedStorage:FindFirstChild("ClientConfig") or Instance.new("Folder")
    clientConfig.Name = "ClientConfig"
    clientConfig.Parent = ReplicatedStorage
    
    -- Set UI access restriction flag
    local uiAccessFlag = clientConfig:FindFirstChild("EnableUIAccessRestrictor") or Instance.new("BoolValue")
    uiAccessFlag.Name = "EnableUIAccessRestrictor"
    uiAccessFlag.Value = true
    uiAccessFlag.Parent = clientConfig
    print("[Installer] Set ClientConfig flag: EnableUIAccessRestrictor")
    
    print("Installation complete! All April 29 fixes have been installed.")
    print("Please run the game to activate the fixes.")
    return true
end

-- Run the installer
installFixes()
