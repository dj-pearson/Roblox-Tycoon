--[[
    CoreRegistry_GymAutomation_FixTest.server.luau
    
    A test script to verify that CoreRegistry and GymAutomation fixes
    work correctly. Run this in Studio to see test results.
    
    Created: May 1, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Only run in Studio for safety
if not RunService:IsStudio() then
    return
end

print("\n===== STARTING COREREGISTRY & GYMAUTOMATION FIX TESTS =====")

-- Safe require function
local function safeRequire(module)
    if not module then 
        return nil 
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[FixTest] Failed to require module:", tostring(result))
        return nil
    end
end

-- Test results table
local testResults = {
    passed = 0,
    failed = 0,
    tests = {}
}

-- Add test result
local function addTestResult(testName, passed, details)
    table.insert(testResults.tests, {
        name = testName,
        passed = passed,
        details = details or ""
    })
    
    if passed then
        testResults.passed += 1
    else
        testResults.failed += 1
    end
end

-- Test 1: Check if shared folder exists
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
addTestResult("Shared Folder Exists", sharedFolder ~= nil, 
    sharedFolder and ("Found at " .. sharedFolder:GetFullName()) or "Not found in ReplicatedStorage")

-- Test 2: Check if CoreRegistryRef exists
local coreRegistryRef = sharedFolder and sharedFolder:FindFirstChild("CoreRegistryRef")
addTestResult("CoreRegistryRef Exists", coreRegistryRef ~= nil,
    coreRegistryRef and ("Found at " .. coreRegistryRef:GetFullName()) or "Not found in shared folder")

-- Test 3: Try to require CoreRegistry
local CoreRegistry
if coreRegistryRef then
    CoreRegistry = safeRequire(coreRegistryRef)
end
addTestResult("CoreRegistry Loads", CoreRegistry ~= nil,
    CoreRegistry and "Successfully loaded CoreRegistry" or "Failed to load CoreRegistry")

-- Test 4: Check CoreRegistry status
local registryStatus = CoreRegistry and CoreRegistry.getStatus and CoreRegistry.getStatus()
addTestResult("CoreRegistry Status", registryStatus == "Available",
    "Status: " .. (registryStatus or "Unknown"))

-- Test 5: Check if critical systems are registered
local criticalSystems = {
    "ModuleLoader",
    "DataManager",
    "UIComponents",
    "AssetValidator",
    "BuyTileSystem",
    "TycoonSystem",
    "EventBridge"
}

local registeredSystems = CoreRegistry and CoreRegistry.getRegisteredSystems and CoreRegistry.getRegisteredSystems() or {}
local missingCriticalSystems = {}

for _, system in ipairs(criticalSystems) do
    if not CoreRegistry or not CoreRegistry.hasSystem or not CoreRegistry.hasSystem(system) then
        table.insert(missingCriticalSystems, system)
    end
end

addTestResult("Critical Systems Registered", #missingCriticalSystems == 0,
    #missingCriticalSystems == 0 and "All critical systems registered" or 
    "Missing systems: " .. table.concat(missingCriticalSystems, ", "))

-- Test 6: Check if GymAutomationSharedRef exists
local gymAutomationRef = sharedFolder and sharedFolder:FindFirstChild("GymAutomationSharedRef")
addTestResult("GymAutomationRef Exists", gymAutomationRef ~= nil,
    gymAutomationRef and ("Found at " .. gymAutomationRef:GetFullName()) or "Not found in shared folder")

-- Test 7: Try to load GymAutomation
local GymAutomation
if gymAutomationRef then
    GymAutomation = safeRequire(gymAutomationRef)
end

-- If not found, try direct path
if not GymAutomation then
    local gymAutomationModule = ServerScriptService:FindFirstChild("GymAutomation")
    if gymAutomationModule and gymAutomationModule:IsA("ModuleScript") then
        GymAutomation = safeRequire(gymAutomationModule)
    else
        -- Try GymAutomation.luau or GymAutomation.server.luau
        gymAutomationModule = ServerScriptService:FindFirstChild("GymAutomation.luau") or 
                              ServerScriptService:FindFirstChild("GymAutomation.server.luau")
        if gymAutomationModule then
            GymAutomation = safeRequire(gymAutomationModule)
        end
    end
end

addTestResult("GymAutomation Loads", GymAutomation ~= nil,
    GymAutomation and "Successfully loaded GymAutomation" or "Failed to load GymAutomation")

-- Test 8: Check if GymAutomation is registered with CoreRegistry
local gymAutomationRegistered = CoreRegistry and CoreRegistry.hasSystem and CoreRegistry.hasSystem("GymAutomation")
addTestResult("GymAutomation Registered", gymAutomationRegistered,
    gymAutomationRegistered and "GymAutomation registered with CoreRegistry" or "GymAutomation not registered")

-- Test 9: Check if GymAutomation is initialized
local gymAutomationInitialized = GymAutomation and GymAutomation.initialized
addTestResult("GymAutomation Initialized", gymAutomationInitialized,
    gymAutomationInitialized and "GymAutomation is initialized" or "GymAutomation not initialized")

-- Test 10: Check if GymAutomation has required methods
local requiredMethods = {
    "AutomateGym",
    "AutomateAllGyms",
    "ProcessEquipment"
}

local missingMethods = {}
for _, methodName in ipairs(requiredMethods) do
    if not GymAutomation or type(GymAutomation[methodName]) ~= "function" then
        table.insert(missingMethods, methodName)
    end
end

addTestResult("GymAutomation Has Required Methods", #missingMethods == 0,
    #missingMethods == 0 and "All required methods available" or 
    "Missing methods: " .. table.concat(missingMethods, ", "))

-- Print test results
print("\n===== TEST RESULTS =====")
print("Passed: " .. testResults.passed .. " | Failed: " .. testResults.failed)
print("-------------------------")

for i, test in ipairs(testResults.tests) do
    local result = test.passed and "✅ PASS" or "❌ FAIL"
    print(i .. ". " .. result .. " - " .. test.name)
    if test.details and test.details ~= "" then
        print("   → " .. test.details)
    end
end

print("-------------------------")
print("Total tests: " .. (testResults.passed + testResults.failed))
if testResults.failed == 0 then
    print("✅ ALL TESTS PASSED! CoreRegistry and GymAutomation fixes are working correctly.")
else
    print("❌ " .. testResults.failed .. " TEST(S) FAILED. Some fixes may not be working correctly.")
end
print("=========================\n")
