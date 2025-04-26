--!strict
--[[
    PathRegistration.server.luau
    Registers all critical module paths for the ModuleLoader utility.
    This script should run early in the game's lifecycle.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Setup shared folder if it doesn't exist
local shared = ReplicatedStorage:FindFirstChild("shared")
if not shared then
    shared = Instance.new("Folder")
    shared.Name = "shared"
    shared.Parent = ReplicatedStorage
    print("[PathRegistration] Created shared folder in ReplicatedStorage")
end

-- Wait for ModuleLoader to be available
local function waitForModuleLoader()
    local ModuleLoader = shared:FindFirstChild("ModuleLoader")
    
    if not ModuleLoader then
        print("[PathRegistration] ModuleLoader not found, waiting...")
          -- Wait briefly for it to be created
        local attempts = 0
        while attempts < 10 do
            ModuleLoader = shared:FindFirstChild("ModuleLoader")
            if ModuleLoader then
                print("[PathRegistration] ModuleLoader found")
                break
            end
            attempts += 1
            task.wait(0.5)
        end
        
        -- If still not found, check if we need to create it
        if not ModuleLoader then
            -- Look in src/shared
            local srcShared = ServerScriptService:FindFirstChild("src") and
                             ServerScriptService.src:FindFirstChild("shared")
                             
            if srcShared and srcShared:FindFirstChild("ModuleLoader") then
                -- Copy to shared folder
                ModuleLoader = srcShared.ModuleLoader:Clone()
                ModuleLoader.Parent = shared
                print("[PathRegistration] Copied ModuleLoader from src/shared")
            else
                -- Create a minimal ModuleLoader
                ModuleLoader = Instance.new("ModuleScript")
                ModuleLoader.Name = "ModuleLoader"
                ModuleLoader.Source = [[
--!strict
-- Minimal ModuleLoader implementation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local searchPaths = {}
local loadedModules = {}

local ModuleLoader = {
    searchPaths = searchPaths,
    loadedModules = loadedModules
}

function ModuleLoader.addSearchPath(path)
    if typeof(path) == "Instance" then
        table.insert(searchPaths, 1, path)
        return true
    end
    return false
end

function ModuleLoader.RegisterPath(category, group, path)
    if typeof(path) == "Instance" then
        table.insert(searchPaths, 1, path)
        return true
    end
    return false
end

function ModuleLoader.findModule(moduleName)
    for _, path in ipairs(searchPaths) do
        local module = path:FindFirstChild(moduleName)
        if module and module:IsA("ModuleScript") then
            return module
        end
    end
    return nil
end

function ModuleLoader.tryRequire(moduleName)
    if loadedModules[moduleName] then
        return loadedModules[moduleName]
    end
    
    local moduleScript = ModuleLoader.findModule(moduleName)
    if not moduleScript then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        loadedModules[moduleName] = result
        return result
    end
    
    return nil
end

function ModuleLoader.initialize()
    -- Add core paths
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then ModuleLoader.addSearchPath(shared) end
    
    return ModuleLoader
end

ModuleLoader.require = ModuleLoader.tryRequire
ModuleLoader.LoadServerModule = function(_, _, name)
    return ModuleLoader.tryRequire(name)
end

return ModuleLoader
]]
                ModuleLoader.Parent = shared
                print("[PathRegistration] Created minimal ModuleLoader in shared folder")
            end
        end
    end
    
    -- Require the ModuleLoader
    local success, result = pcall(function()
        return require(ModuleLoader)
    end)
    
    if success then
        if typeof(result.initialize) == "function" then
            result.initialize()
        end
        return result
    else
        warn("[PathRegistration] Error loading ModuleLoader: " .. tostring(result))
        return nil
    end
end

-- Get ModuleLoader
local ModuleLoader = waitForModuleLoader()
if not ModuleLoader then
    error("[PathRegistration] Failed to get ModuleLoader after multiple attempts")
    return
end

-- Print function to show registration progress
local function logRegistration(category, group, path)
    print(string.format("[PathRegistration] Registered %s.%s at %s", category, group, path:GetFullName()))
end

-- Function to safely find a path with fallbacks
local function safeFindPath(parent, childName)
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Try different folder structures
    if childName == "server" and not child then
        child = parent:FindFirstChild("Server")
    end
    
    if childName == "client" and not child then
        child = parent:FindFirstChild("Client")
    end
    
    if childName == "shared" and not child then
        child = parent:FindFirstChild("Shared")
    end
    
    return child
end

-- Register Server paths
local function registerServerPaths()
    local src = safeFindPath(ServerScriptService, "src") 
    if not src then
        src = safeFindPath(ServerScriptService, "source")
    end
    
    local server = safeFindPath(src, "server")
    
    -- Core path registrations
    local core = safeFindPath(server, "Core")
    ModuleLoader:RegisterPath("Server", "Core", core)
    logRegistration("Server", "Core", core)
    
    -- Systems path registrations
    local systems = safeFindPath(core, "Systems") or safeFindPath(server, "Systems") or safeFindPath(ServerScriptService, "Systems")
    if systems then
        ModuleLoader:RegisterPath("Server", "Systems", systems)
        logRegistration("Server", "Systems", systems)
    end
    
    -- Data path registrations
    local data = safeFindPath(server, "Data") or safeFindPath(ServerScriptService, "Data")
    if data then
        ModuleLoader:RegisterPath("Server", "Data", data)
        logRegistration("Server", "Data", data)
    end
    
    -- Connectors path registrations
    local connectors = safeFindPath(server, "Connectors") or safeFindPath(ServerScriptService, "Connectors")
    ModuleLoader:RegisterPath("Server", "Connectors", connectors)
    logRegistration("Server", "Connectors", connectors)
    
    -- Model functions
    local modelFunctions = safeFindPath(server, "Model Function")
    if not modelFunctions then
        modelFunctions = safeFindPath(server, "ModelFunction")
    end
    ModuleLoader:RegisterPath("Server", "Model", modelFunctions)
    logRegistration("Server", "Model", modelFunctions)
    
    -- Tests
    local tests = safeFindPath(core, "Tests") 
    ModuleLoader:RegisterPath("Server", "Tests", tests)
    logRegistration("Server", "Tests", tests)
    
    -- Utilities
    local utilities = safeFindPath(server, "Utilities")
    ModuleLoader:RegisterPath("Server", "Utilities", utilities)
    logRegistration("Server", "Utilities", utilities)
    
    -- TutorialSteps
    local tutorialSteps = safeFindPath(server, "TutorialSteps")
    ModuleLoader:RegisterPath("Server", "TutorialSteps", tutorialSteps)
    logRegistration("Server", "TutorialSteps", tutorialSteps)
    
    -- Legacy paths for backward compatibility
    ModuleLoader:RegisterPath("Server", "LegacyServerScriptService", ServerScriptService)
    logRegistration("Server", "LegacyServerScriptService", ServerScriptService)
    
    -- Register direct server folder for compatibility 
    ModuleLoader:RegisterPath("Server", "server", server)
    logRegistration("Server", "server", server)
end

-- Register Client paths
local function registerClientPaths()
    local src = safeFindPath(ReplicatedStorage, "src") 
    if not src then
        src = safeFindPath(ReplicatedStorage, "shared")
    end
    
    local client = safeFindPath(src, "client")
    
    -- UI paths
    local ui = safeFindPath(client, "UI")
    ModuleLoader:RegisterPath("Client", "UI", ui)
    logRegistration("Client", "UI", ui)
    
    -- Client Core
    local clientCore = safeFindPath(client, "Core")
    ModuleLoader:RegisterPath("Client", "Core", clientCore)
    logRegistration("Client", "Core", clientCore)
    
    -- Client Utilities
    local clientUtilities = safeFindPath(client, "Utilities")
    ModuleLoader:RegisterPath("Client", "Utilities", clientUtilities)
    logRegistration("Client", "Utilities", clientUtilities)
    
    -- Register direct client folder for compatibility
    ModuleLoader:RegisterPath("Client", "client", client)
    logRegistration("Client", "client", client)
end

-- Register Shared paths
local function registerSharedPaths()
    local sharedFolder = safeFindPath(ReplicatedStorage, "shared")
    ModuleLoader:RegisterPath("Shared", "Shared", sharedFolder)
    logRegistration("Shared", "Shared", sharedFolder)
    
    -- Constants
    local constants = safeFindPath(sharedFolder, "Constants") 
    if constants then
        ModuleLoader:RegisterPath("Shared", "Constants", constants)
        logRegistration("Shared", "Constants", constants)
    end
    
    -- Utils
    local utils = safeFindPath(sharedFolder, "Utils")
    if utils then
        ModuleLoader:RegisterPath("Shared", "Utils", utils)
        logRegistration("Shared", "Utils", utils)
    end
    
    -- Register ReplicatedStorage for compatibility
    ModuleLoader:RegisterPath("Shared", "ReplicatedStorage", ReplicatedStorage)
    logRegistration("Shared", "ReplicatedStorage", ReplicatedStorage)
end

-- Register special paths for specific systems
local function registerSpecialPaths()
    -- Try to find legacy Core folder directly in ServerScriptService
    local legacyCore = safeFindPath(ServerScriptService, "Core")
    if legacyCore then
        ModuleLoader:RegisterPath("Server", "LegacyCore", legacyCore)
        logRegistration("Server", "LegacyCore", legacyCore)
    end
    
    -- Try to find legacy Server folder
    local legacyServer = safeFindPath(ServerScriptService, "Server")
    if legacyServer then
        local legacyServerCore = safeFindPath(legacyServer, "Core")
        if legacyServerCore then
            ModuleLoader:RegisterPath("Server", "LegacyServerCore", legacyServerCore)
            logRegistration("Server", "LegacyServerCore", legacyServerCore)
        end
    end
      -- Try to find on-device CoreRegistry for BuyTile compatibility
    local ServerStorage = game:GetService("ServerStorage")
    local serverStorageSystems = safeFindPath(ServerStorage, "Systems")
    if serverStorageSystems then
        ModuleLoader:RegisterPath("Server", "ServerStorageSystems", serverStorageSystems)
        logRegistration("Server", "ServerStorageSystems", serverStorageSystems)
    end
end

-- Run all registrations
local function init()
    print("[PathRegistration] Starting path registration...")
    
    registerServerPaths()
    registerClientPaths()
    registerSharedPaths()
    registerSpecialPaths()
    
    print("[PathRegistration] Path registration complete.")
end

-- Run the module
init()

return {
    reload = init  -- Allow manual reloading if needed
}
