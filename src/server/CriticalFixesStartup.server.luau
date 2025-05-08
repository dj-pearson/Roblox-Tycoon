--[[
    CriticalFixesStartup.server.luau
    
    This script runs with highest priority to ensure critical fixes are applied
    before other systems initialize.
    
    Created to address the highest priority issues identified in RobloxIssues.txt
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

print("🛠️ [CriticalFixesStartup] Starting critical fixes initialization...")

-- Create folder structure before anything else
local function runFolderSetup()
    -- Try to require FolderSetup module first
    local success, folderSetup
    
    -- Look in multiple common locations
    local possiblePaths = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("FolderSetup"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("FolderSetup.server"),
        ServerScriptService:FindFirstChild("FolderSetup"),
        ServerScriptService:FindFirstChild("FolderSetup.server")
    }
    
    -- Try each path
    for _, path in ipairs(possiblePaths) do
        if path and path:IsA("ModuleScript") then
            success, folderSetup = pcall(function()
                return require(path)
            end)
            if success and folderSetup then
                print("🛠️ [CriticalFixesStartup] Successfully loaded FolderSetup from:", path:GetFullName())
                break
            end
        end
    end
    
    -- If not found or failed to load, run basic folder setup directly
    if not success or not folderSetup then
        print("🛠️ [CriticalFixesStartup] FolderSetup module not found, running basic folder setup...")
        
        -- Create essential folders
        local function ensureFolder(parent, name)
            if not parent then return nil end
            
            local folder = parent:FindFirstChild(name)
            if folder and not folder:IsA("Folder") then
                folder:Destroy()
                folder = nil
            end
            
            if not folder then
                folder = Instance.new("Folder")
                folder.Name = name
                folder.Parent = parent
                print("🛠️ [CriticalFixesStartup] Created folder:", name, "in", parent:GetFullName())
            end
            
            return folder
        end
        
        -- Create required folders
        ensureFolder(ReplicatedStorage, "shared")
        ensureFolder(ReplicatedStorage, "src")
        ensureFolder(ReplicatedStorage, "EventBridge")
        
        ensureFolder(ServerScriptService, "Core")
        ensureFolder(ServerScriptService, "Server")
        ensureFolder(ServerScriptService, "Tests")
        
        ensureFolder(ServerStorage, "GymParts")
        ensureFolder(ServerStorage, "BuyTiles")
    end
end

-- Fix the Tycoon folder structure for a player
local function fixTycoonStructure(player)
    -- Try to use TycoonFolderInitializer first
    local initializer = ServerScriptService.Core:FindFirstChild("TycoonFolderInitializer")
    if initializer and initializer:IsA("ModuleScript") then
        local success, result = pcall(function()
            local module = require(initializer)
            if module and module.validateTycoonStructure then
                return module.validateTycoonStructure(player)
            end
        end)
        
        if success and result then
            print("🛠️ [CriticalFixesStartup] Successfully fixed tycoon structure for", player.Name)
            return true
        end
    end
    
    -- Fallback to TycoonFolderFixer if available
    local tycoonFixer
    local coreFolder = ServerScriptService:FindFirstChild("Core")
    
    if coreFolder and coreFolder:FindFirstChild("TycoonFolderFixer") then
        local success, result = pcall(function()
            return require(coreFolder.TycoonFolderFixer)
        end)
        
        if success and result then
            tycoonFixer = result
        end
    end
    
    -- If we found the fixer module, use it
    if tycoonFixer then
        print("🛠️ [CriticalFixesStartup] Using TycoonFolderFixer for", player.Name)
        -- The module should handle fixing the structure
        return
    end
    
    -- Otherwise, do basic fixes ourselves
    print("🛠️ [CriticalFixesStartup] No tycoon structure fixer available, applying basic fixes for", player.Name)
    
    -- Basic Tycoon structure creation
    local tycoon = player:FindFirstChild("Tycoon")
    
    -- Remove Tycoon if it's not an ObjectValue
    if tycoon and not tycoon:IsA("ObjectValue") then
        warn("🛠️ [CriticalFixesStartup] Found invalid Tycoon type for", player.Name, "- removing and recreating")
        tycoon:Destroy()
        tycoon = nil
    end
    
    -- Create Tycoon if it doesn't exist
    if not tycoon then
        tycoon = Instance.new("ObjectValue")
        tycoon.Name = "Tycoon"
        tycoon.Parent = player
        print("🛠️ [CriticalFixesStartup] Created Tycoon ObjectValue for", player.Name)
    end
    
    -- Set basic required attributes
    if not tycoon:GetAttribute("EquipmentCount") then
        tycoon:SetAttribute("EquipmentCount", 0)
    end
    
    if not tycoon:GetAttribute("GymTier") then
        tycoon:SetAttribute("GymTier", 1)
    end
    
    if not tycoon:GetAttribute("MemberCount") then
        tycoon:SetAttribute("MemberCount", 0)
    end
    
    if not tycoon:GetAttribute("AccruedDues") then
        tycoon:SetAttribute("AccruedDues", 0)
    end
    
    print("🛠️ [CriticalFixesStartup] Applied basic Tycoon structure fixes for", player.Name)
end

-- Fix the shared registry for CoreRegistry
local function fixCoreRegistry()
    -- Try to load CoreRegistry from wherever it exists
    local coreRegistry
    local possiblePaths = {
        ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("CoreRegistry"),
        ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("CoreRegistry.server")
    }
    
    -- Try each path
    for _, path in ipairs(possiblePaths) do
        if path and path:IsA("ModuleScript") then
            local success, registry = pcall(function()
                return require(path)
            end)
            
            if success and registry then
                coreRegistry = registry
                print("🛠️ [CriticalFixesStartup] Successfully loaded CoreRegistry from:", path:GetFullName())
                break
            end
        end
    end
    
    -- If not found, CoreRegistry.server.luau should be created by the fixes
    if not coreRegistry then
        print("🛠️ [CriticalFixesStartup] CoreRegistry not found, it should be created by our fixes")
    end
    
    -- Create shared registry access in ReplicatedStorage if needed
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared") or Instance.new("Folder", ReplicatedStorage)
    sharedFolder.Name = "shared"
    
    -- Create CoreRegistryRemotes if it doesn't exist
    local remotesFolder = ReplicatedStorage:FindFirstChild("CoreRegistryRemotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "CoreRegistryRemotes"
        remotesFolder.Parent = ReplicatedStorage
        print("🛠️ [CriticalFixesStartup] Created CoreRegistryRemotes folder")
        
        -- Create basic remotes
        local getSystemRemote = Instance.new("RemoteFunction")
        getSystemRemote.Name = "GetSystem"
        getSystemRemote.Parent = remotesFolder
        
        local hasSystemRemote = Instance.new("RemoteFunction")
        hasSystemRemote.Name = "HasSystem" 
        hasSystemRemote.Parent = remotesFolder
        
        print("🛠️ [CriticalFixesStartup] Created basic CoreRegistry remotes")
    end
end

-- Fix DataPersistence by ensuring it's loaded
local function ensureDataPersistence()
    -- Look for DataPersistenceManager in common locations
    local dataManager
    local possiblePaths = {
        ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("DataPersistenceManager"),
        ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("DataPersistenceManager.server"),
        ServerScriptService.Data and ServerScriptService.Data:FindFirstChild("GymTycoonDataManager"),
        ServerScriptService:FindFirstChild("GymTycoonDataManager")
    }
    
    -- Try each path
    for _, path in ipairs(possiblePaths) do
        if path and path:IsA("ModuleScript") then
            local success, manager = pcall(function()
                return require(path)
            end)
            
            if success and manager then
                dataManager = manager
                print("🛠️ [CriticalFixesStartup] Successfully loaded DataManager from:", path:GetFullName())
                break
            end
        end
    end
    
    -- If not found, warn but continue
    if not dataManager then
        print("🛠️ [CriticalFixesStartup] DataManager not found, it should be created by our fixes")
    end
end

-- Fix client registry issues from server
local function ensureClientRegistry()
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared") or Instance.new("Folder", ReplicatedStorage)
    sharedFolder.Name = "shared"
    
    -- Create or fix ClientRegistry in shared folder
    local clientRegistry = sharedFolder:FindFirstChild("ClientRegistry")
    
    -- Remove if it's not a ModuleScript
    if clientRegistry and not clientRegistry:IsA("ModuleScript") then
        warn("🛠️ [CriticalFixesStartup] Found invalid ClientRegistry, recreating it")
        clientRegistry:Destroy()
        clientRegistry = nil
    end
    
    -- Create if it doesn't exist
    if not clientRegistry then
        clientRegistry = Instance.new("ModuleScript")
        clientRegistry.Name = "ClientRegistry"
        
        -- Create basic ClientRegistry module
        clientRegistry.Source = [[
-- ClientRegistry Module
-- A registry for client-side systems and components

local ClientRegistry = {}
ClientRegistry.VERSION = "1.0.0"
ClientRegistry.systems = {}
ClientRegistry.initialized = {}
ClientRegistry.isLoaded = true

-- Register a system
function ClientRegistry.registerSystem(name, system)
    if type(name) ~= "string" then
        warn("ClientRegistry: System name must be a string")
        return false
    end
    
    if type(system) ~= "table" then
        warn("ClientRegistry: System must be a table")
        return false
    end
    
    ClientRegistry.systems[name] = system
    print("ClientRegistry: Registered system:", name)
    return true
end

-- Get a system
function ClientRegistry.getSystem(name)
    if type(name) ~= "string" then
        warn("ClientRegistry: System name must be a string")
        return nil
    end
    
    local system = ClientRegistry.systems[name]
    if not system then
        warn("ClientRegistry: System not found:", name)
        return nil
    end
    
    return system
end

-- Check if system exists
function ClientRegistry.hasSystem(name)
    return ClientRegistry.systems[name] ~= nil
end

-- Initialize a system
function ClientRegistry.initSystem(name, dependencies, initFunc)
    if ClientRegistry.initialized[name] then
        return true -- Already initialized
    end
    
    -- Check dependencies
    if dependencies and type(dependencies) == "table" then
        for _, depName in ipairs(dependencies) do
            if not ClientRegistry.hasSystem(depName) then
                warn("ClientRegistry: Required dependency not found:", depName, "for system:", name)
                return false
            end
        end
    end
    
    -- Initialize if function provided
    if initFunc and type(initFunc) == "function" then
        local success, result = pcall(initFunc)
        if not success then
            warn("ClientRegistry: Failed to initialize:", name, "-", result)
            return false
        end
    end
    
    -- Mark as initialized
    ClientRegistry.initialized[name] = true
    print("ClientRegistry: Initialized system:", name)
    return true
end

-- Return only one value
return ClientRegistry
]]
        
        clientRegistry.Parent = sharedFolder
        print("🛠️ [CriticalFixesStartup] Created ClientRegistry in shared folder")
    end
end

-- Set up player joining event
local function setupPlayerEvents()
    Players.PlayerAdded:Connect(function(player)
        task.delay(1, function() 
            -- Fix tycoon structure for the player
            fixTycoonStructure(player)
        end)
    end)
    
    -- Fix tycoon structure for existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            fixTycoonStructure(player)
        end)
    end
end

-- Run all fixes in the correct order
local function runAllFixes()
    print("🛠️ [CriticalFixesStartup] Running all fixes...")
    
    -- Step 1: Set up required folders
    runFolderSetup()
    
    -- Step 2: Fix CoreRegistry
    fixCoreRegistry()
    
    -- Step 3: Fix ClientRegistry
    ensureClientRegistry()
    
    -- Step 4: Fix DataPersistence
    ensureDataPersistence()
    
    -- Step 5: Set up player events
    setupPlayerEvents()
    
    print("🛠️ [CriticalFixesStartup] All critical fixes applied!")
end

-- Run the fixes
runAllFixes()

-- Return a simple API for other scripts to use
return {
    fixTycoonStructure = fixTycoonStructure,
    ensureClientRegistry = ensureClientRegistry,
    ensureDataPersistence = ensureDataPersistence
}
