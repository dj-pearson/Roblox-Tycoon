--[[
    UISystemTester.client.luau
    
    Tests the functionality of the UI system components.
    This script verifies that all UI modules are properly loaded and functioning.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
if not player then
    warn("[UISystemTester] No LocalPlayer found, exiting test")
    return
end

print("\n==== RUNNING UI SYSTEM TESTS ====")

-- Test results tracking
local testResults = {
    total = 0,
    passed = 0,
    failed = 0
}

-- Run a test
local function runTest(testName, testFunc)
    testResults.total = testResults.total + 1
    
    local success, result = pcall(testFunc)
    
    if success and result then
        testResults.passed = testResults.passed + 1
        print("✓ " .. testName)
        return true
    else
        testResults.failed = testResults.failed + 1
        local errorMsg = (type(result) == "string" and result ~= "") and (": " .. result) or ""
        warn("✗ " .. testName .. errorMsg)
        return false
    end
end

-- Get ModuleScriptAccessor
local function getModuleScriptAccessor()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local success, result = pcall(function()
            return require(shared.ModuleScriptAccessor)
        end)
        
        if success and result then
            return result
        end
    end
    return nil
end

-- Find a module using various methods
local function findModule(moduleName)
    -- Try through ModuleScriptAccessor first
    local moduleAccessor = getModuleScriptAccessor()
    if moduleAccessor then
        local module = moduleAccessor.getSystem(moduleName)
        if module then
            return module
        end
    end
    
    -- Try direct paths
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and ReplicatedStorage.src.client:FindFirstChild("Core")
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module then
                local success, result = pcall(function()
                    return require(module)
                end)
                
                if success and result then
                    return result
                end
            end
        end
    end
    
    return nil
end

-- Test 1: Check if ModuleScriptAccessor exists
runTest("ModuleScriptAccessor Exists", function()
    local moduleAccessor = getModuleScriptAccessor()
    if not moduleAccessor then
        return false, "ModuleScriptAccessor not found"
    end
    return true
end)

-- Test 2: Check if ModuleLoader exists
runTest("ModuleLoader Exists", function()
    local moduleLoader = findModule("ModuleLoader")
    if not moduleLoader then
        return false, "ModuleLoader module not found"
    end
    return true
end)

-- Test 3: Check if AssetValidator exists
runTest("AssetValidator Exists", function()
    local assetValidator = findModule("AssetValidator")
    if not assetValidator then
        return false, "AssetValidator not found through any method"
    end
    return true
end)

-- Test 4: Check if UIComponents exists
runTest("UIComponents Exists", function()
    local uiComponents = findModule("UIComponents")
    if not uiComponents then
        return false, "UIComponents not found through any method"
    end
    return true
end)

-- Test 5: Check if UIRegistry exists
runTest("UIRegistry Exists", function()
    local uiRegistry = findModule("UIRegistry")
    if not uiRegistry then
        return false, "UIRegistry not found"
    end
    return true
end)

-- Test 6: Check UIRegistry.ButtonFactory
runTest("UIRegistry.ButtonFactory", function()
    local uiRegistry = findModule("UIRegistry")
    if not uiRegistry or not uiRegistry.ButtonFactory or not uiRegistry.ButtonFactory.createBasicButton then
        return false, "ButtonFactory not available or missing createBasicButton function"
    end
    return true
end)

-- Test 7: Check UIRegistry.DialogFactory
runTest("UIRegistry.DialogFactory", function()
    local uiRegistry = findModule("UIRegistry")
    if not uiRegistry or not uiRegistry.DialogFactory or not uiRegistry.DialogFactory.createNotification then
        return false, "DialogFactory not available or missing createNotification function"
    end
    return true
end)

-- Test 8: Check UIRegistry.IconSet
runTest("UIRegistry.IconSet", function()
    local uiRegistry = findModule("UIRegistry")
    if not uiRegistry or not uiRegistry.IconSet or not uiRegistry.IconSet.getIcon then
        return false, "IconSet not available or missing getIcon function"
    end
    return true
end)

-- Test 9: Check UIRegistry.UIStyle
runTest("UIRegistry.UIStyle", function()
    local uiRegistry = findModule("UIRegistry")
    if not uiRegistry or not uiRegistry.UIStyle or not uiRegistry.UIStyle.applyStyle then
        return false, "UIStyle not available or missing applyStyle function"
    end
    return true
end)

-- Test 10: Check if UIRegistry can show notifications
runTest("UIRegistry Can Show Notifications", function()
    local uiRegistry = findModule("UIRegistry")
    if not uiRegistry or not uiRegistry.DialogFactory or not uiRegistry.DialogFactory.showNotification then
        return false, "DialogFactory not available or missing showNotification function"
    end
    
    local notification = uiRegistry.DialogFactory.showNotification("Test", "This is a test notification", "info", 3)
    if not notification then
        return false, "Failed to create notification"
    end
    
    return true
end)

-- Test 11: Check CoreRegistry integration
runTest("CoreRegistry Integration", function()
    local moduleAccessor = getModuleScriptAccessor()
    if not moduleAccessor then
        return false, "ModuleScriptAccessor not found"
    end
    
    local coreRegistry = moduleAccessor.getCoreRegistry()
    if not coreRegistry then
        return false, "CoreRegistry not found"
    end
    
    if not coreRegistry.getSystem or not coreRegistry.hasSystem then
        return false, "CoreRegistry missing required functions"
    end
    
    return true
end)

-- Test 12: Check if required UI systems are registered with CoreRegistry
runTest("Required UI Systems Registration", function()
    local moduleAccessor = getModuleScriptAccessor()
    if not moduleAccessor then
        return false, "ModuleScriptAccessor not found"
    end
    
    local coreRegistry = moduleAccessor.getCoreRegistry()
    if not coreRegistry or not coreRegistry.hasSystem then
        return false, "CoreRegistry not found or missing hasSystem function"
    end
    
    local requiredSystems = {
        "UIComponents",
        "UIRegistry",
        "AssetValidator",
        "ModuleLoader"
    }
    
    local missingCount = 0
    local missingSystems = {}
    
    for _, systemName in ipairs(requiredSystems) do
        if not coreRegistry.hasSystem(systemName) then
            missingCount = missingCount + 1
            table.insert(missingSystems, systemName)
        end
    end
    
    if missingCount > 0 then
        return false, missingCount .. " systems not registered: " .. table.concat(missingSystems, ", ")
    end
    
    return true
end)

-- Print test summary
local passRate = math.floor((testResults.passed / testResults.total) * 100)
print("\n[UISystemTester] Tests Run: " .. testResults.total .. ", Tests Passed: " .. testResults.passed .. ", Tests Failed: " .. testResults.failed)
print("[UISystemTester] Pass Rate: " .. passRate .. "%")

-- Show notification with test results if UIRegistry available
local uiRegistry = findModule("UIRegistry")
if uiRegistry and uiRegistry.DialogFactory and uiRegistry.DialogFactory.showNotification then
    local notificationType = passRate >= 70 and "success" or (passRate >= 40 and "warning" or "error")
    local message = "Tests Run: " .. testResults.total .. "\nPassed: " .. testResults.passed .. "\nFailed: " .. testResults.failed
    uiRegistry.DialogFactory.showNotification("UI System Test Results", message, notificationType, 10)
end

print("==== UI SYSTEM TESTS COMPLETE ====\n")
