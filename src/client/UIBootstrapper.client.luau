--[[
    UIBootstrapper.client.luau
    
    Main entry point for initializing all UI systems on the client.
    This script runs at client startup and ensures all UI components are available.
    
    Created: April 30, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Only run in client
if not RunService:IsClient() then
    return
end

print("\n==== STARTING UI BOOTSTRAPPER ====")

-- Load in order: 
-- 1. Make sure shared folder exists
-- 2. Check ModuleScriptAccessor is available
-- 3. Run ClientRegistryFixer
-- 4. Run UISystemTester

-- Helper functions
local function findScriptInFolder(scriptName, folder)
    if not folder then return nil end
    
    -- Look for exact name
    local script = folder:FindFirstChild(scriptName)
    if script and script:IsA("ModuleScript") or script:IsA("Script") or script:IsA("LocalScript") then
        return script
    end
    
    -- Try with extensions
    local extensions = {".luau", ".client.luau", ".lua"}
    for _, ext in ipairs(extensions) do
        script = folder:FindFirstChild(scriptName .. ext)
        if script and (script:IsA("ModuleScript") or script:IsA("Script") or script:IsA("LocalScript")) then
            return script
        end
    end
    
    return nil
end

local function runScript(scriptName, folder)
    local scriptInstance = findScriptInFolder(scriptName, folder)
    if not scriptInstance then
        warn("[UIBootstrapper] Could not find " .. scriptName)
        return false
    end
    
    -- Handle based on script type
    if scriptInstance:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(scriptInstance)
        end)
        
        if success then
            print("[UIBootstrapper] Successfully required " .. scriptName)
            return result
        else
            warn("[UIBootstrapper] Failed to require " .. scriptName .. ": " .. tostring(result))
            return false
        end
    elseif scriptInstance:IsA("LocalScript") or scriptInstance:IsA("Script") then
        -- Clone and execute
        local clone = scriptInstance:Clone()
        clone.Disabled = false
        clone.Parent = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerScripts")
        
        print("[UIBootstrapper] Executed " .. scriptName)
        return true
    end
    
    return false
end

-- STEP 1: Ensure shared folder exists
local shared = ReplicatedStorage:FindFirstChild("shared")
if not shared then
    shared = Instance.new("Folder")
    shared.Name = "shared"
    shared.Parent = ReplicatedStorage
    print("[UIBootstrapper] Created shared folder in ReplicatedStorage")
else
    print("[UIBootstrapper] Shared folder already exists")
end

-- STEP 2: Check ModuleScriptAccessor
local moduleScriptAccessor = shared:FindFirstChild("ModuleScriptAccessor")
if not moduleScriptAccessor then
    -- Try to find it elsewhere
    local srcShared = ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared")
    if srcShared then
        moduleScriptAccessor = srcShared:FindFirstChild("ModuleScriptAccessor")
        if moduleScriptAccessor then
            local clone = moduleScriptAccessor:Clone()
            clone.Parent = shared
            print("[UIBootstrapper] Copied ModuleScriptAccessor from src/shared to shared folder")
            moduleScriptAccessor = clone
        end
    end
end

if moduleScriptAccessor then
    print("[UIBootstrapper] ModuleScriptAccessor available at: " .. moduleScriptAccessor:GetFullName())
    
    -- Require it to ensure it's loaded
    local success, result = pcall(function()
        return require(moduleScriptAccessor)
    end)
    
    if success then
        print("[UIBootstrapper] Successfully required ModuleScriptAccessor")
    else
        warn("[UIBootstrapper] Error requiring ModuleScriptAccessor: " .. tostring(result))
    end
else
    warn("[UIBootstrapper] ModuleScriptAccessor not found!")
end

-- Wait for the player and character to be ready
local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

if not player.Character then
    player.CharacterAdded:Wait()
end

print("[UIBootstrapper] Player and character ready")

-- Find client folder
local clientFolder = player:FindFirstChild("PlayerScripts")
if clientFolder then
    clientFolder = clientFolder:FindFirstChild("src") and clientFolder.src:FindFirstChild("client")
end

if not clientFolder then
    clientFolder = player.PlayerScripts
end

-- STEP 3: Run ClientRegistryFixer
print("[UIBootstrapper] Running ClientRegistryFixer...")
task.delay(1, function()
    runScript("ClientRegistryFixer", clientFolder)
    
    -- STEP 4: Run UISystemTester
    task.delay(2, function()
        print("[UIBootstrapper] Running UISystemTester...")
        runScript("UISystemTester", clientFolder)
        
        print("[UIBootstrapper] UI Bootstrap process complete\n")
    end)
end)

print("[UIBootstrapper] UI Bootstrap process started")
