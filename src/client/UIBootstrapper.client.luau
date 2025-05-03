--[[
    UIBootstrapper.client.luau
    
    This script ensures all UI systems are properly loaded and initialized.
    It makes sure required client modules like UIRegistry and AssetValidator
    are available and registered with the CoreRegistry.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
if not player then
    warn("[UIBootstrapper] No LocalPlayer found, waiting...")
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

print("\n==== STARTING UI BOOTSTRAPPER ====")

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[UIBootstrapper] Failed to require module:", tostring(result))
        return nil
    end
end

-- Ensure shared folder exists
local shared = ReplicatedStorage:FindFirstChild("shared")
if not shared then
    shared = Instance.new("Folder")
    shared.Name = "shared"
    shared.Parent = ReplicatedStorage
    print("[UIBootstrapper] Created missing shared folder in ReplicatedStorage")
end

-- STEP 1: Make sure ModuleScriptAccessor is available
print("[UIBootstrapper] Step 1: Setting up ModuleScriptAccessor...")

-- Check if it's already in shared
local moduleAccessor = shared:FindFirstChild("ModuleScriptAccessor")
if not moduleAccessor then
    -- Try to find it in src/shared
    local srcShared = ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared")
    if srcShared and srcShared:FindFirstChild("ModuleScriptAccessor") then
        moduleAccessor = srcShared:FindFirstChild("ModuleScriptAccessor"):Clone()
        moduleAccessor.Parent = shared
        print("[UIBootstrapper] Copied ModuleScriptAccessor to shared folder")
    else
        warn("[UIBootstrapper] ModuleScriptAccessor not found!")
    end
end

-- Get ModuleScriptAccessor
local ModuleScriptAccessor = moduleAccessor and safeRequire(moduleAccessor)
if not ModuleScriptAccessor then
    warn("[UIBootstrapper] Failed to load ModuleScriptAccessor, UI systems may not function correctly")
end

-- STEP 2: Create or find the client/Core folder
print("[UIBootstrapper] Step 2: Setting up client folder structure...")

-- Create client core path if it doesn't exist
local clientCore = nil
local srcClient = nil

-- Try to find existing client/Core folder
srcClient = ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client")
if srcClient then
    clientCore = srcClient:FindFirstChild("Core")
    if not clientCore then
        clientCore = Instance.new("Folder")
        clientCore.Name = "Core"
        clientCore.Parent = srcClient
        print("[UIBootstrapper] Created missing Core folder in src/client")
    end
else
    -- Create the src/client path
    local src = ReplicatedStorage:FindFirstChild("src")
    if not src then
        src = Instance.new("Folder")
        src.Name = "src"
        src.Parent = ReplicatedStorage
        print("[UIBootstrapper] Created missing src folder in ReplicatedStorage")
    end
    
    srcClient = src:FindFirstChild("client")
    if not srcClient then
        srcClient = Instance.new("Folder")
        srcClient.Name = "client"
        srcClient.Parent = src
        print("[UIBootstrapper] Created missing client folder in src")
    end
    
    clientCore = srcClient:FindFirstChild("Core")
    if not clientCore then
        clientCore = Instance.new("Folder")
        clientCore.Name = "Core"
        clientCore.Parent = srcClient
        print("[UIBootstrapper] Created missing Core folder in src/client")
    end
end

-- STEP 3: Set up the ModuleLoader
print("[UIBootstrapper] Step 3: Setting up ModuleLoader...")

-- Check for ModuleLoader in shared folder
local moduleLoader = shared:FindFirstChild("ModuleLoader")
if not moduleLoader then
    -- Try to find it in src/shared
    local srcShared = ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared")
    if srcShared and srcShared:FindFirstChild("ModuleLoader") then
        moduleLoader = srcShared:FindFirstChild("ModuleLoader"):Clone()
        moduleLoader.Parent = shared
        print("[UIBootstrapper] Copied ModuleLoader to shared folder")
    else
        warn("[UIBootstrapper] ModuleLoader not found!")
    end
end

-- Load ModuleLoader
local ModuleLoader = moduleLoader and safeRequire(moduleLoader)
if not ModuleLoader then
    warn("[UIBootstrapper] Failed to load ModuleLoader, UI systems may not function correctly")
end

-- STEP 4: Set up AssetValidator
print("[UIBootstrapper] Step 4: Setting up AssetValidator...")

-- Check for AssetValidator in shared folder
local assetValidator = shared:FindFirstChild("AssetValidator")
if not assetValidator then
    -- Try to find it in src/shared
    local srcShared = ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared")
    if srcShared and srcShared:FindFirstChild("AssetValidator") then
        assetValidator = srcShared:FindFirstChild("AssetValidator"):Clone()
        assetValidator.Parent = shared
        print("[UIBootstrapper] Copied AssetValidator to shared folder")
    else
        warn("[UIBootstrapper] AssetValidator not found!")
    end
end

-- Load AssetValidator
local AssetValidator = assetValidator and safeRequire(assetValidator)
if not AssetValidator then
    warn("[UIBootstrapper] Failed to load AssetValidator, UI systems may not function correctly")
end

-- STEP 5: Make sure UIComponents is registered
print("[UIBootstrapper] Step 5: Setting up UIComponents...")

-- Try to find UIComponents in client/Core
local uiComponents = clientCore and clientCore:FindFirstChild("UIComponents")
if not uiComponents then
    -- Try to find it in ReplicatedStorage
    uiComponents = ReplicatedStorage:FindFirstChild("UIComponents")
    if uiComponents then
        local clone = uiComponents:Clone()
        clone.Parent = clientCore
        print("[UIBootstrapper] Copied UIComponents to client/Core folder")
    else
        warn("[UIBootstrapper] UIComponents not found!")
    end
end

-- Load UIComponents
local UIComponents = uiComponents and safeRequire(uiComponents)
if not UIComponents then
    warn("[UIBootstrapper] Failed to load UIComponents, UI systems may not function correctly")
end

-- STEP 6: Make sure UIRegistry is registered
print("[UIBootstrapper] Step 6: Setting up UIRegistry...")

-- Try to find UIRegistry in multiple locations with improved search logic
local uiRegistry = nil
local searchLocations = {
    -- Search in client/Core
    clientCore and clientCore:FindFirstChild("UIRegistry"),
    clientCore and clientCore:FindFirstChild("UIRegistry.client"),
    
    -- Search in client/UI
    srcClient and srcClient:FindFirstChild("UI") and srcClient:FindFirstChild("UI"):FindFirstChild("UIRegistry"),
    srcClient and srcClient:FindFirstChild("UI") and srcClient:FindFirstChild("UI"):FindFirstChild("UIRegistry.client"),
    
    -- Search in ReplicatedStorage
    ReplicatedStorage:FindFirstChild("UIRegistry"),
    
    -- Search in ReplicatedStorage/shared
    ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("UIRegistry")
}

-- Find the first valid UIRegistry module
for _, location in pairs(searchLocations) do
    if location and location:IsA("ModuleScript") then
        uiRegistry = location
        print("[UIBootstrapper] Found UIRegistry at: " .. uiRegistry:GetFullName())
        break
    end
end

-- If not found in any predefined location, try a more exhaustive search
if not uiRegistry then
    print("[UIBootstrapper] UIRegistry not found in expected locations, searching more thoroughly...")
    
    -- Look for it in client/UI folder
    local uiFolder = srcClient and srcClient:FindFirstChild("UI")
    if uiFolder then
        uiRegistry = uiFolder:FindFirstChild("UIRegistry") or uiFolder:FindFirstChild("UIRegistry.client")
        if uiRegistry then
            print("[UIBootstrapper] Found UIRegistry in client/UI folder")
        end
    end
end

-- Final fallback: if still not found, use the one in shared
if not uiRegistry and shared:FindFirstChild("UIRegistry") then
    uiRegistry = shared:FindFirstChild("UIRegistry")
    print("[UIBootstrapper] Using UIRegistry from shared folder")
end

-- If still not found but exists in client/UI, use that as a last resort
if not uiRegistry then
    local clientUIRegistry = srcClient and srcClient:FindFirstChild("UI") and 
                            srcClient:FindFirstChild("UI"):FindFirstChild("UIRegistry.client.luau")
    if clientUIRegistry then
        uiRegistry = clientUIRegistry
        print("[UIBootstrapper] Using UIRegistry.client.luau from client/UI folder")
    end
end

-- Copy to clientCore if found elsewhere
if uiRegistry and clientCore and not clientCore:FindFirstChild("UIRegistry") then
    local clone = uiRegistry:Clone()
    clone.Parent = clientCore
    print("[UIBootstrapper] Copied UIRegistry to client/Core folder")
    uiRegistry = clone -- Use the clone from now on
end

-- Load UIRegistry
local UIRegistry = uiRegistry and safeRequire(uiRegistry)
if not UIRegistry then
    -- If we can't load it, try to find it one last time in the client UI folder
    local clientUIRegistry = player.PlayerScripts:FindFirstChild("client") and 
                           player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and
                           player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild("UIRegistry.client")
    
    if clientUIRegistry then
        UIRegistry = safeRequire(clientUIRegistry)
        print("[UIBootstrapper] Loaded UIRegistry from PlayerScripts/client/UI")
    else
        warn("[UIBootstrapper] Failed to load UIRegistry, UI systems may not function correctly")
    end
end

-- STEP 7: Register systems with CoreRegistry if possible
print("[UIBootstrapper] Step 7: Registering systems with CoreRegistry...")

-- Try to get CoreRegistry
local CoreRegistry = nil
if ModuleScriptAccessor then
    CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
end

if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
    -- Register ModuleLoader if found
    if ModuleLoader and not CoreRegistry.hasSystem("ModuleLoader") then
        CoreRegistry.registerSystem("ModuleLoader", ModuleLoader)
        print("[UIBootstrapper] Registered ModuleLoader with CoreRegistry")
    end
    
    -- Register AssetValidator if found
    if AssetValidator and not CoreRegistry.hasSystem("AssetValidator") then
        CoreRegistry.registerSystem("AssetValidator", AssetValidator)
        print("[UIBootstrapper] Registered AssetValidator with CoreRegistry")
    end
    
    -- Register UIComponents if found
    if UIComponents and not CoreRegistry.hasSystem("UIComponents") then
        CoreRegistry.registerSystem("UIComponents", UIComponents)
        print("[UIBootstrapper] Registered UIComponents with CoreRegistry")
    end
    
    -- Register UIRegistry if found
    if UIRegistry and not CoreRegistry.hasSystem("UIRegistry") then
        CoreRegistry.registerSystem("UIRegistry", UIRegistry)
        print("[UIBootstrapper] Registered UIRegistry with CoreRegistry")
    end
else
    warn("[UIBootstrapper] CoreRegistry not found or missing registerSystem function")
end

-- STEP 8: Run UISystemTester to verify everything is working
print("[UIBootstrapper] Step 8: Running UI System Tests...")

-- Wait a moment for everything to initialize
task.wait(1)

-- Try to find UISystemTester
local uiSystemTester = nil
if srcClient then
    uiSystemTester = srcClient:FindFirstChild("UISystemTester") or srcClient:FindFirstChild("UISystemTester.client.luau")
end

-- Run the tester if found
if uiSystemTester then
    print("[UIBootstrapper] Running UISystemTester...")
    safeRequire(uiSystemTester)
else
    warn("[UIBootstrapper] UISystemTester not found!")
end

-- Show a notification if UIRegistry is available
if UIRegistry and UIRegistry.DialogFactory and UIRegistry.DialogFactory.showNotification then
    UIRegistry.DialogFactory.showNotification("UI System Bootstrap", "UI systems initialized successfully", "success", 5)
end

print("==== UI BOOTSTRAPPER COMPLETE ====\n")
