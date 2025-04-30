--[[
    UISystemTester.server.luau
    
    Tests the functionality of UI Systems and verifies the CoreRegistry is properly set up.
    This script validates that all critical systems are available and functioning.
    
    Created: April 30, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("\n==== RUNNING UI SYSTEM TESTER ====")
print("Testing critical systems...")

-- Helper functions
local function findModule(name, paths)
    for _, path in ipairs(paths) do
        if path then
            local module = path:FindFirstChild(name)
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Try with extensions
            local extensions = {".luau", ".server.luau", ".lua"}
            for _, ext in ipairs(extensions) do
                module = path:FindFirstChild(name .. ext)
                if module and module:IsA("ModuleScript") then
                    return module
                end
            end
        end
    end
    
    return nil
end

local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[UISystemTester] Failed to require: " .. tostring(module:GetFullName()) .. " - " .. tostring(result))
        return nil
    end
end

-- Ensure shared folder exists
local shared = ReplicatedStorage:FindFirstChild("shared")
if not shared then
    shared = Instance.new("Folder")
    shared.Name = "shared"
    shared.Parent = ReplicatedStorage
    print("[UISystemTester] Created missing shared folder in ReplicatedStorage")
end

-- First check if CoreRegistry is available
local coreRegistryPaths = {
    ServerScriptService:FindFirstChild("Core"),
    ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core")
}

local coreRegistryModule = findModule("CoreRegistry", coreRegistryPaths)
local CoreRegistry = safeRequire(coreRegistryModule)

if not CoreRegistry then
    warn("[UISystemTester] CoreRegistry not found or failed to load!")
else
    print("[UISystemTester] CoreRegistry found at: " .. coreRegistryModule:GetFullName())
    
    -- Initialize if needed
    if typeof(CoreRegistry.initialize) == "function" and not CoreRegistry.initialized then
        CoreRegistry.initialize()
    end
    
    -- Verify if critical systems are registered
    local criticalSystems = {
        "ModuleLoader",
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem",
        "TycoonSystem",
        "EventBridge",
        "GymAutomation"
    }
    
    local missingCount = 0
    for _, systemName in ipairs(criticalSystems) do
        if CoreRegistry.hasSystem and CoreRegistry:hasSystem(systemName) then
            print("[UISystemTester] ✅ System found: " .. systemName)
        else
            warn("[UISystemTester] ❌ System missing: " .. systemName)
            missingCount = missingCount + 1
        end
    end
    
    print("[UISystemTester] CoreRegistry has " .. (8 - missingCount) .. "/8 critical systems")
end

-- Test if ModuleScriptAccessor is available
local moduleScriptAccessorPath = ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleScriptAccessor")
if not moduleScriptAccessorPath then
    warn("[UISystemTester] ModuleScriptAccessor not found in ReplicatedStorage/shared")
    
    -- Try to find it in src/shared and copy it if found
    local srcSharedPath = ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("shared")
    local srcModuleScriptAccessor = srcSharedPath and srcSharedPath:FindFirstChild("ModuleScriptAccessor")
    
    if srcModuleScriptAccessor then
        local clone = srcModuleScriptAccessor:Clone()
        clone.Parent = shared
        print("[UISystemTester] Copied ModuleScriptAccessor to ReplicatedStorage/shared")
    else
        warn("[UISystemTester] ModuleScriptAccessor not found anywhere!")
    end
else
    print("[UISystemTester] ModuleScriptAccessor found at: " .. moduleScriptAccessorPath:GetFullName())
end

-- Test GymAutomation
local gymAutomationPaths = {
    ServerScriptService:FindFirstChild("GymAutomation"),
    ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("GymAutomation"),
    ServerScriptService:FindFirstChild("Core"),
    ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
}

local gymAutomationModule = findModule("GymAutomationManager", gymAutomationPaths)
if not gymAutomationModule then
    warn("[UISystemTester] GymAutomationManager not found!")
else
    print("[UISystemTester] GymAutomationManager found at: " .. gymAutomationModule:GetFullName())
    
    -- Copy to other locations if not found
    local srcServerCore = ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core")
    local srcServerGymAuto = ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("GymAutomation")
    
    if srcServerCore and not srcServerCore:FindFirstChild("GymAutomationManager") and not srcServerCore:FindFirstChild("GymAutomationManager.luau") then
        local clone = gymAutomationModule:Clone()
        clone.Parent = srcServerCore
        print("[UISystemTester] Copied GymAutomationManager to src/server/Core")
    end
    
    if srcServerGymAuto and not srcServerGymAuto:FindFirstChild("GymAutomationManager") and not srcServerGymAuto:FindFirstChild("GymAutomationManager.luau") then
        local clone = gymAutomationModule:Clone()
        clone.Parent = srcServerGymAuto
        print("[UISystemTester] Copied GymAutomationManager to src/server/GymAutomation")
    end
end

-- Test GymAutomation wrapper
local gymAutomationWrapperModule = findModule("GymAutomation", {ServerScriptService})
if not gymAutomationWrapperModule then
    warn("[UISystemTester] GymAutomation wrapper not found!")
else
    print("[UISystemTester] GymAutomation wrapper found at: " .. gymAutomationWrapperModule:GetFullName())
    
    -- Test the wrapper
    local GymAutomation = safeRequire(gymAutomationWrapperModule)
    if GymAutomation then
        print("[UISystemTester] Successfully required GymAutomation wrapper")
    else
        warn("[UISystemTester] Failed to require GymAutomation wrapper")
    end
end

print("[UISystemTester] UI System test completed\n")
