--[[
    UIFixesCoordinator.server.luau
    
    Coordinates client and server UI fixes and ensures proper synchronization.
    This script loads both server and client-side fixes for the UI systems.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

print("\n===== STARTING UI FIXES COORDINATOR =====")

-- Configuration
local CONFIG = {
    SERVER_FIXES_FIRST = true, -- Run server fixes before sending client fixes
    LOAD_CLIENT_SCRIPTS = true, -- Whether to load client scripts
    DEBUG_LOGGING = true
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[UIFixesCoordinator] " .. message)
    end
end

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[UIFixesCoordinator] Failed to require module:", tostring(result))
        return nil
    end
end

-- Find a script in the specified paths
local function findScript(scriptName, paths)
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

-- STEP 1: Run server-side fixes first
if CONFIG.SERVER_FIXES_FIRST then
    log("Running server-side fixes...")
    
    -- Find and run SystemsBootstrap
    local serverPaths = {
        ServerScriptService,
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server")
    }
    
    local systemsBootstrap = findScript("SystemsBootstrap", serverPaths) or 
                            findScript("SystemsBootstrap.server.luau", serverPaths)
                            
    if systemsBootstrap then
        log("Running SystemsBootstrap...")
        safeRequire(systemsBootstrap)
    else
        warn("[UIFixesCoordinator] SystemsBootstrap not found!")
    end
end

-- STEP 2: Set up client-side fix distribution
if CONFIG.LOAD_CLIENT_SCRIPTS then
    log("Setting up client-side UI fixes...")
    
    -- Create "ClientUIFixes" folder in ReplicatedStorage to hold client scripts
    local clientUIFixes = ReplicatedStorage:FindFirstChild("ClientUIFixes")
    if not clientUIFixes then
        clientUIFixes = Instance.new("Folder")
        clientUIFixes.Name = "ClientUIFixes"
        clientUIFixes.Parent = ReplicatedStorage
        log("Created ClientUIFixes folder in ReplicatedStorage")
    end
    
    -- Find client scripts to distribute
    local srcClient = ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client")
    if srcClient then
        -- Copy UIBootstrapper to ClientUIFixes
        local uiBootstrapper = srcClient:FindFirstChild("UIBootstrapper.client.luau") or 
                              srcClient:FindFirstChild("UIBootstrapper")
                              
        if uiBootstrapper then
            -- If it already exists in ClientUIFixes, remove it first
            if clientUIFixes:FindFirstChild("UIBootstrapper.client") then
                clientUIFixes:FindFirstChild("UIBootstrapper.client"):Destroy()
            end
            
            local clone = uiBootstrapper:Clone()
            clone.Name = "UIBootstrapper.client"
            clone.Parent = clientUIFixes
            log("Copied UIBootstrapper to ClientUIFixes")
        else
            warn("[UIFixesCoordinator] UIBootstrapper not found!")
        end
        
        -- Copy UISystemTester to ClientUIFixes
        local uiSystemTester = srcClient:FindFirstChild("UISystemTester.client.luau") or 
                             srcClient:FindFirstChild("UISystemTester")
                             
        if uiSystemTester then
            -- If it already exists in ClientUIFixes, remove it first
            if clientUIFixes:FindFirstChild("UISystemTester.client") then
                clientUIFixes:FindFirstChild("UISystemTester.client"):Destroy()
            end
            
            local clone = uiSystemTester:Clone()
            clone.Name = "UISystemTester.client"
            clone.Parent = clientUIFixes
            log("Copied UISystemTester to ClientUIFixes")
        else
            warn("[UIFixesCoordinator] UISystemTester not found!")
        end
    else
        warn("[UIFixesCoordinator] src/client folder not found!")
    end
    
    -- Create the client loader script
    local clientLoaderScript = clientUIFixes:FindFirstChild("ClientUILoader")
    if clientLoaderScript then
        clientLoaderScript:Destroy()
    end
    
    clientLoaderScript = Instance.new("LocalScript")
    clientLoaderScript.Name = "ClientUILoader"
    
    -- Write the loader script to run UIBootstrapper and UISystemTester
    clientLoaderScript.Source = [[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
if not player then
    warn("[ClientUILoader] No LocalPlayer found, waiting...")
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

print("\n==== STARTING CLIENT UI LOADER ====")

-- Load UIBootstrapper first
local uiBootstrapper = script.Parent:FindFirstChild("UIBootstrapper.client")
if uiBootstrapper then
    print("[ClientUILoader] Running UIBootstrapper...")
    require(uiBootstrapper)
else
    warn("[ClientUILoader] UIBootstrapper not found!")
end

-- Wait a moment before running tests
task.wait(2)

-- Load UISystemTester
local uiSystemTester = script.Parent:FindFirstChild("UISystemTester.client")
if uiSystemTester then
    print("[ClientUILoader] Running UISystemTester...")
    require(uiSystemTester)
else
    warn("[ClientUILoader] UISystemTester not found!")
end

print("==== CLIENT UI LOADER COMPLETE ====\n")
]]
    
    clientLoaderScript.Parent = clientUIFixes
    log("Created ClientUILoader script")
end

-- Create UI Fix event to notify when fixes are complete
local uiFixEvent = ReplicatedStorage:FindFirstChild("UIFixesComplete")
if not uiFixEvent then
    uiFixEvent = Instance.new("BindableEvent")
    uiFixEvent.Name = "UIFixesComplete"
    uiFixEvent.Parent = ReplicatedStorage
    log("Created UIFixesComplete event")
end

-- STEP 3: Register player join handler to notify about fixes
log("Setting up player join handler...")

Players.PlayerAdded:Connect(function(player)
    log("Player joined: " .. player.Name .. " - Applying UI fixes")
    
    -- Fire event to notify that fixes are complete
    if uiFixEvent then
        uiFixEvent:Fire(player)
    end
end)

-- Fire event for existing players
for _, player in ipairs(Players:GetPlayers()) do
    log("Applying UI fixes to existing player: " .. player.Name)
    
    -- Fire event to notify that fixes are complete
    if uiFixEvent then
        uiFixEvent:Fire(player)
    end
end

print("===== UI FIXES COORDINATOR COMPLETE =====\n")
