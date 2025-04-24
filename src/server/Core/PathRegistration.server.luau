--!strict
--[[
    PathRegistration.server.luau
    Registers all critical module paths for the ModuleLoader utility.
    This script should run early in the game's lifecycle.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for the shared folder to be available
local shared = ReplicatedStorage:WaitForChild("shared")
local ModuleLoader = require(shared:WaitForChild("ModuleLoader"))

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
    
    if childName == "Core" and not child then
        child = parent:FindFirstChild("core")
    end
    
    -- Try creating the path if it doesn't exist
    if not child then
        print(string.format("[PathRegistration] WARNING: Path %s not found in %s. Creating it.", childName, parent:GetFullName()))
        child = Instance.new("Folder")
        child.Name = childName
        child.Parent = parent
    end
    
    return child
end

-- Register Server paths
local function registerServerPaths()
    local src = safeFindPath(ServerScriptService, "src")
    local server = safeFindPath(src, "server")
    
    -- Core paths
    local core = safeFindPath(server, "Core")
    ModuleLoader:RegisterPath("Server", "Core", core)
    logRegistration("Server", "Core", core)
    
    -- Connectors
    local connectors = safeFindPath(server, "Connectors")
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
    
    -- Register direct client folder for compatibility
    ModuleLoader:RegisterPath("Client", "client", client)
    logRegistration("Client", "client", client)
end

-- Register Shared paths
local function registerSharedPaths()
    local shared = safeFindPath(ReplicatedStorage, "shared")
    ModuleLoader:RegisterPath("Shared", "Shared", shared)
    logRegistration("Shared", "Shared", shared)
    
    -- Constants
    local constants = safeFindPath(shared, "Constants") 
    if constants then
        ModuleLoader:RegisterPath("Shared", "Constants", constants)
        logRegistration("Shared", "Constants", constants)
    end
    
    -- Utils
    local utils = safeFindPath(shared, "Utils")
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

-- Execute the initialization
init()
