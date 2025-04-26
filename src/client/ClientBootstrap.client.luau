--!strict
--[[
    ClientBootstrap.client.luau
    
    Initializes the client environment and loads essential modules.
    
    Created: April 25, 2025
    
    This script:
    1. Loads early in the client lifecycle
    2. Initializes the ModuleLoader
    3. Ensures the ClientRegistry is loaded
    4. Loads and initializes core UI modules
    5. Handles error recovery for critical systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local LocalPlayer = Players.LocalPlayer
local DEBUG_ENABLED = true

-- Debug logging
local function log(message)
    if DEBUG_ENABLED then
        print("[ClientBootstrap] " .. message)
    end
end

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn("[ClientBootstrap] Failed to require module: ", module:GetFullName(), " Error: ", result)
        return nil
    end
    
    return result
end

-- Ensure a folder exists, creating it if needed
local function ensureFolderExists(parent, folderName)
    local folder = parent:FindFirstChild(folderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = parent
        log("Created folder: " .. folderName .. " in " .. parent:GetFullName())
    end
    return folder
end

-- Bootstrap stages for step-by-step initialization
local bootstrapStages = {
    -- Stage 1: Setup Essential Folders
    function()
        log("Stage 1: Setting up essential folders")
        
        -- Ensure shared folder exists
        local sharedFolder = ensureFolderExists(ReplicatedStorage, "shared")
        
        -- Ensure client folder exists in PlayerScripts
        local clientFolder = ensureFolderExists(LocalPlayer.PlayerScripts, "Client")
        
        -- Ensure Core folder exists in client folder
        local coreFolder = ensureFolderExists(clientFolder, "Core")
        
        -- Ensure UI folder exists in client folder
        local uiFolder = ensureFolderExists(clientFolder, "UI")
        
        return true
    end,
    
    -- Stage 2: Load ModuleLoader
    function()
        log("Stage 2: Loading ModuleLoader")
        
        local sharedFolder = ReplicatedStorage.shared
        local ModuleLoader = requireSafely(sharedFolder:FindFirstChild("ModuleLoader"))
        
        if not ModuleLoader then
            warn("[ClientBootstrap] ModuleLoader not found, some modules may fail to load")
            return false
        end
        
        -- Initialize ModuleLoader
        ModuleLoader.initialize()
        log("ModuleLoader initialized")
        
        -- Add to global context for easier access
        if _G then
            _G.ModuleLoader = ModuleLoader
        end
        
        return true
    end,
    
    -- Stage 3: Load ClientRegistry
    function()
        log("Stage 3: Loading ClientRegistry")
        
        local clientFolder = LocalPlayer.PlayerScripts.Client
        local coreFolder = clientFolder.Core
        
        -- Try to load ClientRegistry
        local ClientRegistry
        
        -- First try direct require
        ClientRegistry = requireSafely(coreFolder:FindFirstChild("ClientRegistry"))
        
        -- If that failed, try to load from shared folder
        if not ClientRegistry then
            ClientRegistry = requireSafely(ReplicatedStorage.shared:FindFirstChild("ClientRegistry"))
        end
        
        -- If still not found, try to use ModuleLoader
        if not ClientRegistry and _G.ModuleLoader then
            ClientRegistry = _G.ModuleLoader.tryRequire("ClientRegistry")
        end
        
        if not ClientRegistry then
            warn("[ClientBootstrap] ClientRegistry not found, UI systems may not function correctly")
            return false
        end
        
        -- Initialize ClientRegistry
        if typeof(ClientRegistry.initialize) == "function" and not ClientRegistry.initialized then
            ClientRegistry.initialize()
            log("ClientRegistry initialized")
        end
        
        -- Add to global context for easier access
        if _G then
            _G.ClientRegistry = ClientRegistry
        end
        
        return true
    end,
    
    -- Stage 4: Load UI Components
    function()
        log("Stage 4: Loading UI Components")
        
        local UIComponents = requireSafely(ReplicatedStorage.shared:FindFirstChild("UIComponents"))
        
        if not UIComponents then
            warn("[ClientBootstrap] UIComponents not found, UI may not display correctly")
            return false
        end
        
        -- Try to register with ClientRegistry
        if _G.ClientRegistry and typeof(UIComponents.registerWithClientRegistry) == "function" then
            UIComponents.registerWithClientRegistry(_G.ClientRegistry)
            log("UIComponents registered with ClientRegistry")
        end
        
        return true
    end,
    
    -- Stage 5: Initialize Core Systems
    function()
        log("Stage 5: Initializing Core Systems")
        
        if not _G.ClientRegistry then
            warn("[ClientBootstrap] ClientRegistry not available for system initialization")
            return false
        end
        
        -- Initialize core systems with proper dependency order
        local coreSystems = {
            "UIManager",
            "NotificationManager",
            "DataManager",
            "InputManager"
        }
        
        local initializedCount = 0
        for _, systemName in ipairs(coreSystems) do
            if _G.ClientRegistry:initializeSystem(systemName) then
                initializedCount += 1
            end
        end
        
        log("Core systems initialized: " .. initializedCount .. "/" .. #coreSystems)
        
        return initializedCount > 0
    end
}

-- Run bootstrap stages
local function runBootstrap()
    log("Starting client bootstrap")
    
    local stages = #bootstrapStages
    local successfulStages = 0
    
    for i, stageFunc in ipairs(bootstrapStages) do
        log("Running bootstrap stage " .. i .. "/" .. stages)
        
        local success, result = pcall(stageFunc)
        
        if success and result then
            log("Stage " .. i .. " completed successfully")
            successfulStages += 1
        else
            warn("[ClientBootstrap] Stage " .. i .. " failed: " .. tostring(result))
            
            -- Try to continue despite failure
            if i < 3 then
                -- If critical early stages fail, break
                warn("[ClientBootstrap] Critical stage failed, bootstrap incomplete")
                break
            end
        end
    end
    
    log("Bootstrap complete: " .. successfulStages .. "/" .. stages .. " stages successful")
    
    -- Signal that bootstrap is complete
    if _G then
        _G.ClientBootstrapComplete = true
    end
    
    return successfulStages == stages
end

-- Run the bootstrap process in a protected call
local success, result = pcall(runBootstrap)

if not success then
    warn("[ClientBootstrap] Critical error during bootstrap: " .. tostring(result))
    
    -- Attempt recovery of critical systems
    pcall(function()
        log("Attempting recovery of critical systems")
        
        -- Try to ensure ClientRegistry exists in some form
        if not _G.ClientRegistry then
            local ClientRegistry = requireSafely(LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistry"))
            if ClientRegistry then
                ClientRegistry.initialize()
                _G.ClientRegistry = ClientRegistry
                log("Recovered ClientRegistry")
            end
        end
        
        -- Try to ensure UIComponents are loaded
        if _G.ClientRegistry then
            local UIComponents = requireSafely(ReplicatedStorage.shared:FindFirstChild("UIComponents"))
            if UIComponents and typeof(UIComponents.registerWithClientRegistry) == "function" then
                UIComponents.registerWithClientRegistry(_G.ClientRegistry)
                log("Recovered UIComponents")
            end
        end
    end)
end
