--[[
    FixesManager.server.luau
    
    This script serves as the main entry point for accessing all the critical fixes 
    and provides a unified API for other scripts to interact with them. It also exposes
    diagnostic and repair capabilities.
    
    Created to coordinate fixes for issues identified in RobloxIssues.txt
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Configuration
local CONFIG = {
    debug = true,
    modules = {
        -- List of fix modules in loading order
        {name = "FolderSetup", required = true},
        {name = "SafeRequire", required = true},
        {name = "CoreRegistry", required = true},
        {name = "CoreRegistryMonitor", required = false},
        {name = "TycoonFolderFixer", required = true},
        {name = "DataPersistenceManager", required = true},
        {name = "BuyTileSystem", required = false},
        {name = "BuyTileFixer", required = false},
        {name = "DiagnosticsAndRepair", required = false}
    },
    locations = {
        ServerScriptService.Core,
        ServerScriptService,
        ServerScriptService.Server,
        ReplicatedStorage.shared
    },
    moduleTypes = {
        "", -- No suffix
        ".server",
        ".module",
        ".luau"
    }
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[FixesManager]", ...)
    end
end

-- Create a global reference to the manager
_G.FixesManager = {}

-- Required modules storage
local modules = {}

-- Find and require a module
local function findAndRequireModule(moduleName, isRequired)
    -- Try all possible locations and suffixes
    for _, location in ipairs(CONFIG.locations) do
        if not location then continue end
        
        for _, suffix in ipairs(CONFIG.moduleTypes) do
            local fullName = moduleName .. suffix
            local module = location:FindFirstChild(fullName)
            
            if module and module:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(module)
                end)
                
                if success and result then
                    log("Successfully loaded", moduleName, "from", module:GetFullName())
                    return result
                else
                    if isRequired then
                        warn("[FixesManager] Failed to load required module:", moduleName, "Error:", result)
                    end
                end
            end
        end
    end
    
    if isRequired then
        warn("[FixesManager] Could not find required module:", moduleName)
    else
        log("Could not find optional module:", moduleName)
    end
    
    return nil
end

-- Initialize all modules
local function initializeModules()
    log("Initializing fix modules")
    
    for _, moduleInfo in ipairs(CONFIG.modules) do
        log("Looking for", moduleInfo.name)
        local module = findAndRequireModule(moduleInfo.name, moduleInfo.required)
        
        if module then
            modules[moduleInfo.name] = module
        end
    end
end

-- Create shared API
local function createSharedAPI()
    log("Creating shared API")
    
    -- Create shared folder
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        shared = Instance.new("Folder")
        shared.Name = "shared"
        shared.Parent = ReplicatedStorage
    end
    
    -- Create FixesAPI module
    local fixesAPI = shared:FindFirstChild("FixesAPI")
    if fixesAPI then
        if not fixesAPI:IsA("ModuleScript") then
            fixesAPI:Destroy()
            fixesAPI = nil
        end
    end
    
    if not fixesAPI then
        fixesAPI = Instance.new("ModuleScript")
        fixesAPI.Name = "FixesAPI"
        
        -- Module code
        fixesAPI.Source = [[
-- FixesAPI Module
-- Provides access to critical fixes functionality

local API = {}

-- Cached system references
local systems = {}

-- Get a system by name
function API.getSystem(name)
    if systems[name] then
        return systems[name]
    end
    
    -- Try to get from FixesManager global
    if _G.FixesManager and _G.FixesManager.getModule then
        local system = _G.FixesManager.getModule(name)
        if system then
            systems[name] = system
            return system
        end
    end
    
    -- Try remotes if server reference not available
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("FixesRemotes")
    if remotes then
        local getRemote = remotes:FindFirstChild("GetSystem")
        if getRemote and getRemote:IsA("RemoteFunction") then
            local success, result = pcall(function()
                return getRemote:InvokeServer(name)
            end)
            
            if success then
                -- Can't return actual objects over remotes, but can return data
                return result
            end
        end
    end
    
    return nil
end

-- Check if system is available
function API.hasSystem(name)
    local system = API.getSystem(name)
    return system ~= nil
end

-- Fix Tycoon structure for a player
function API.fixTycoonStructure(player)
    -- On server, use direct call
    if game:GetService("RunService"):IsServer() then
        if _G.FixesManager and _G.FixesManager.fixTycoonStructure then
            return _G.FixesManager.fixTycoonStructure(player)
        end
    else
        -- On client, use remote
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("FixesRemotes")
        if remotes then
            local fixRemote = remotes:FindFirstChild("FixTycoon")
            if fixRemote and fixRemote:IsA("RemoteEvent") then
                fixRemote:FireServer()
                return true
            end
        end
    end
    
    return false
end

-- Run diagnostics
function API.runDiagnostics()
    -- On server, use direct call
    if game:GetService("RunService"):IsServer() then
        if _G.FixesManager and _G.FixesManager.runDiagnostics then
            return _G.FixesManager.runDiagnostics()
        end
    else
        -- On client, use remote
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("FixesRemotes")
        if remotes then
            local diagnosticsRemote = remotes:FindFirstChild("RunDiagnostics")
            if diagnosticsRemote and diagnosticsRemote:IsA("RemoteFunction") then
                return diagnosticsRemote:InvokeServer()
            end
        end
    end
    
    return nil
end

-- Return API
return API
]]
        
        fixesAPI.Parent = shared
        log("Created FixesAPI in shared folder")
    end
end

-- Create client-server remotes
local function createRemotes()
    log("Creating remotes")
    
    -- Create remotes folder
    local remotes = ReplicatedStorage:FindFirstChild("FixesRemotes")
    if not remotes then
        remotes = Instance.new("Folder")
        remotes.Name = "FixesRemotes"
        remotes.Parent = ReplicatedStorage
    end
    
    -- Create GetSystem remote
    local getSystem = remotes:FindFirstChild("GetSystem") or Instance.new("RemoteFunction")
    getSystem.Name = "GetSystem"
    getSystem.Parent = remotes
    
    -- Create RunDiagnostics remote
    local runDiagnostics = remotes:FindFirstChild("RunDiagnostics") or Instance.new("RemoteFunction")
    runDiagnostics.Name = "RunDiagnostics"
    runDiagnostics.Parent = remotes
    
    -- Create FixTycoon remote
    local fixTycoon = remotes:FindFirstChild("FixTycoon") or Instance.new("RemoteEvent")
    fixTycoon.Name = "FixTycoon"
    fixTycoon.Parent = remotes
    
    -- Connect remotes
    getSystem.OnServerInvoke = function(player, systemName)
        if modules[systemName] then
            -- Convert to serializable format if needed
            if systemName == "DiagnosticsAndRepair" then
                return {
                    hasSystem = true,
                    canRunDiagnostics = true
                }
            elseif systemName == "TycoonFolderFixer" then
                return {
                    hasSystem = true,
                    canFixTycoon = true
                }
            else
                -- Generic system indicator
                return {
                    hasSystem = true
                }
            end
        end
        return nil
    end
    
    runDiagnostics.OnServerInvoke = function(player)
        if modules.DiagnosticsAndRepair and modules.DiagnosticsAndRepair.runDiagnostics then
            return modules.DiagnosticsAndRepair.runDiagnostics()
        end
        return nil
    end
    
    fixTycoon.OnServerEvent:Connect(function(player)
        log("Received FixTycoon request from", player.Name)
        if modules.TycoonFolderFixer and modules.TycoonFolderFixer.fixPlayerTycoon then
            modules.TycoonFolderFixer.fixPlayerTycoon(player)
        end
    end)
end

-- Fix Tycoon structure for a player
local function fixTycoonStructure(player)
    if modules.TycoonFolderFixer and modules.TycoonFolderFixer.fixPlayerTycoon then
        return modules.TycoonFolderFixer.fixPlayerTycoon(player)
    elseif modules.TycoonFolderFixer and modules.TycoonFolderFixer.fixTycoon then
        return modules.TycoonFolderFixer.fixTycoon(player)
    else
        warn("[FixesManager] TycoonFolderFixer module not found or missing fixPlayerTycoon function")
        
        -- Basic Tycoon structure fix
        local tycoon = player:FindFirstChild("Tycoon")
        if not tycoon or not tycoon:IsA("ObjectValue") then
            if tycoon then tycoon:Destroy() end
            tycoon = Instance.new("ObjectValue")
            tycoon.Name = "Tycoon"
            tycoon.Parent = player
            
            -- Set basic attributes
            tycoon:SetAttribute("EquipmentCount", 0)
            tycoon:SetAttribute("GymTier", 1)
            tycoon:SetAttribute("MemberCount", 0)
            
            return true
        end
    end
    
    return false
end

-- Run diagnostics using the DiagnosticsAndRepair module
local function runDiagnostics()
    if modules.DiagnosticsAndRepair and modules.DiagnosticsAndRepair.runDiagnostics then
        return modules.DiagnosticsAndRepair.runDiagnostics()
    else
        warn("[FixesManager] DiagnosticsAndRepair module not found or missing runDiagnostics function")
    end
    
    return nil
end

-- Add player added handler
local function setupPlayerHandlers()
    Players.PlayerAdded:Connect(function(player)
        task.delay(1, function()
            fixTycoonStructure(player)
        end)
    end)
    
    -- Fix for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            fixTycoonStructure(player)
        end)
    end
end

-- Initialize and set up the manager
local function initialize()
    log("Initializing FixesManager")
    
    -- Initialize modules
    initializeModules()
    
    -- Create shared API
    createSharedAPI()
    
    -- Create remotes
    createRemotes()
    
    -- Set up player handlers
    setupPlayerHandlers()
    
    -- Create global API access
    _G.FixesManager = {
        -- Module access
        getModule = function(name)
            return modules[name]
        end,
        
        -- Actions
        fixTycoonStructure = fixTycoonStructure,
        runDiagnostics = runDiagnostics,
        
        -- Status
        getLoadedModules = function()
            local result = {}
            for name, _ in pairs(modules) do
                table.insert(result, name)
            end
            return result
        end
    }
    
    log("FixesManager initialization complete")
end

-- Run initialization
initialize()

-- Return the API
return _G.FixesManager
