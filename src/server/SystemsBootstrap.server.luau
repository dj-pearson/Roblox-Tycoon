--[[
    SystemsBootstrap.server.luau
    
    Entry point for initializing all critical systems and fixing module loading issues.
    This script runs at server start and ensures all systems are properly registered and available.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Only run in Studio mode for safety
if not RunService:IsStudio() then
    warn("[SystemsBootstrap] Only runs in Studio mode for safety")
    return
end

print("\n==== STARTING SYSTEMS BOOTSTRAP PROCESS ====")

-- Create helpers
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[SystemsBootstrap] Failed to require module:", result)
        return nil
    end
end

-- Create or find shared folder
local shared = ReplicatedStorage:FindFirstChild("shared")
if not shared then
    shared = Instance.new("Folder")
    shared.Name = "shared"
    shared.Parent = ReplicatedStorage
    print("[SystemsBootstrap] Created shared folder in ReplicatedStorage")
end

-- STEP 1: Initialize ModuleScriptAccessor
print("[SystemsBootstrap] Step 1: Setting up ModuleScriptAccessor...")

-- Check if it's already in shared
local moduleAccessor = shared:FindFirstChild("ModuleScriptAccessor")
if not moduleAccessor then
    -- Look for it in src/shared
    local srcShared = ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("shared")
    if srcShared then
        moduleAccessor = srcShared:FindFirstChild("ModuleScriptAccessor")
        if moduleAccessor then
            local clone = moduleAccessor:Clone()
            clone.Parent = shared
            print("[SystemsBootstrap] Copied ModuleScriptAccessor to shared folder")
        end
    end
    
    -- If still not found, run SharedFolderSetup script
    if not shared:FindFirstChild("ModuleScriptAccessor") then
        local setupScript = ServerScriptService:FindFirstChild("SharedFolderSetup") or 
                           (ServerScriptService:FindFirstChild("src") and 
                            ServerScriptService.src:FindFirstChild("server") and 
                            ServerScriptService.src.server:FindFirstChild("SharedFolderSetup"))
        
        if setupScript then
            print("[SystemsBootstrap] Running SharedFolderSetup script...")
            require(setupScript)
        else
            warn("[SystemsBootstrap] SharedFolderSetup script not found!")
        end
    end
end

-- STEP 2: Initialize CoreRegistry
print("[SystemsBootstrap] Step 2: Initializing CoreRegistry...")

-- Look for CoreRegistryInitializer
local initializerScript = ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistryInitializer") or
                         (ServerScriptService:FindFirstChild("src") and 
                          ServerScriptService.src:FindFirstChild("server") and 
                          ServerScriptService.src.server:FindFirstChild("Core") and 
                          ServerScriptService.src.server.Core:FindFirstChild("CoreRegistryInitializer"))

if initializerScript then
    print("[SystemsBootstrap] Running CoreRegistryInitializer...")
    require(initializerScript)
else
    warn("[SystemsBootstrap] CoreRegistryInitializer not found!")
end

-- STEP 3: Register systems using SystemBridge
print("[SystemsBootstrap] Step 3: Registering critical systems...")

local systemBridgePath = ServerScriptService:FindFirstChild("SystemBridge") or
                        (ServerScriptService:FindFirstChild("src") and 
                         ServerScriptService.src:FindFirstChild("server") and 
                         ServerScriptService.src.server:FindFirstChild("SystemBridge"))

if systemBridgePath then
    local SystemBridge = safeRequire(systemBridgePath)
    if SystemBridge then
        SystemBridge.registerCriticalSystems()
    else
        warn("[SystemsBootstrap] Failed to require SystemBridge!")
    end
else
    warn("[SystemsBootstrap] SystemBridge not found!")
end

-- STEP 4: Initialize GymAutomation
print("[SystemsBootstrap] Step 4: Initializing GymAutomation...")

local gymAutomationLoaderPath = ServerScriptService:FindFirstChild("GymAutomationLoader") or
                               (ServerScriptService:FindFirstChild("src") and 
                                ServerScriptService.src:FindFirstChild("server") and 
                                ServerScriptService.src.server:FindFirstChild("GymAutomationLoader"))

if gymAutomationLoaderPath then
    print("[SystemsBootstrap] Running GymAutomationLoader...")
    require(gymAutomationLoaderPath)
else
    warn("[SystemsBootstrap] GymAutomationLoader not found!")
end

-- STEP 5: Run UI System tests to verify everything is working
print("[SystemsBootstrap] Step 5: Testing systems...")

-- Wait a moment for everything to initialize
task.wait(1)

-- Run UISystemTester
local uiSystemTester = ServerScriptService:FindFirstChild("UISystemTester") or
                      (ServerScriptService:FindFirstChild("src") and 
                       ServerScriptService.src:FindFirstChild("server") and 
                       ServerScriptService.src.server:FindFirstChild("UISystemTester"))

if uiSystemTester then
    print("[SystemsBootstrap] Running UISystemTester...")
    require(uiSystemTester)
else
    warn("[SystemsBootstrap] UISystemTester not found!")
end

print("==== SYSTEMS BOOTSTRAP COMPLETE ====\n")
