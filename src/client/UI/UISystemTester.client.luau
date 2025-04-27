--!strict
--[[
    UISystemTester.client.luau
    
    A tool for testing UI systems and components.
    This script tests the availability and functionality of UI-related modules
    and components to ensure they are properly initialized.
    
    Created: April 25, 2025
    Fixed: April 27, 2025 - Removed _G usage and fixed parameter issues
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Constants
local DEBUG_ENABLED = true
local UI_TEST_DELAY = 5 -- Wait a few seconds for systems to initialize

-- Local variables
local LocalPlayer = Players.LocalPlayer
local tests = {}
local testResults = {
    passed = 0,
    failed = 0,
    warnings = 0,
    total = 0,
    details = {}
}

-- ClientBootstrap reference - this will be located without using _G
local ClientBootstrap = nil

-- Debug logging
local function log(message)
    if DEBUG_ENABLED then
        print("[UISystemTester] " .. message)
    end
end

local function warn_log(message)
    warn("[UISystemTester] " .. message)
    testResults.warnings += 1
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
        warn_log("Failed to require " .. tostring(module:GetFullName()) .. ": " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find a module in multiple possible locations
local function findModule(searchPaths)
    if not searchPaths or #searchPaths == 0 then
        return nil
    end
    
    -- Search all paths
    for _, pathFn in ipairs(searchPaths) do
        local modulePath = pathFn()
        if modulePath and typeof(modulePath) == "Instance" and modulePath:IsA("ModuleScript") then
            return modulePath
        end
    end
    
    return nil
end

-- Add a test
local function addTest(name, testFn, group)
    table.insert(tests, {
        name = name,
        fn = testFn,
        group = group or "General"
    })
end

-- Print test report
local function printTestReport()
    log("\n======= UI SYSTEM TEST REPORT =======")
    log("Tests Run: " .. testResults.total)
    log("Tests Passed: " .. testResults.passed)
    log("Tests Failed: " .. testResults.failed)
    log("Warnings: " .. testResults.warnings)
    log("Pass Rate: " .. math.floor(testResults.passed / testResults.total * 100) .. "%")
    log("------------------------------------")
    
    -- Group results by category
    local groupResults = {}
    
    for _, detail in ipairs(testResults.details) do
        if not groupResults[detail.group] then
            groupResults[detail.group] = {
                passed = 0,
                total = 0
            }
        end
        
        groupResults[detail.group].total += 1
        if detail.passed then
            groupResults[detail.group].passed += 1
        end
    end
    
    -- Print group results
    for group, results in pairs(groupResults) do
        local passRate = math.floor(results.passed / results.total * 100)
        log(group .. ": " .. results.passed .. "/" .. results.total .. " tests passed (" .. passRate .. "%)")
    end
    
    log("\nFailed Tests:")
    for _, detail in ipairs(testResults.details) do
        if not detail.passed then
            local errorInfo = detail.error and (": " .. detail.error) or ""
            log("✗ " .. detail.name .. errorInfo)
        end
    end
end

-- Find the ClientBootstrap object (without using _G)
local function findClientBootstrap()
    -- Look in PlayerScripts.Client
    if LocalPlayer and 
        LocalPlayer.PlayerScripts and 
        LocalPlayer.PlayerScripts:FindFirstChild("Client") then
            
        local bootstrapModule = LocalPlayer.PlayerScripts.Client:FindFirstChild("ClientBootstrap")
        
        if bootstrapModule and bootstrapModule:IsA("ModuleScript") then
            local bootstrap = requireSafely(bootstrapModule)
            if bootstrap and typeof(bootstrap) == "table" then
                return bootstrap
            end
        end
    end
    
    -- Look in PlayerScripts
    if LocalPlayer and LocalPlayer.PlayerScripts then
        local bootstrapScript = LocalPlayer.PlayerScripts:FindFirstChild("ClientBootstrap")
        -- This is likely a LocalScript, not a ModuleScript, so we can't require it
        -- But we can check if it exposed its API through a Value object
        if bootstrapScript then
            local apiValue = bootstrapScript:FindFirstChild("BootstrapAPI")
            if apiValue and apiValue:IsA("ObjectValue") and apiValue.Value then
                local api = apiValue.Value
                if api:IsA("ModuleScript") then
                    return requireSafely(api)
                end
            end
        end
    end
    
    -- Look for a shared API singleton
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then
        local bootstrapAPI = shared:FindFirstChild("ClientBootstrapAPI")
        if bootstrapAPI and bootstrapAPI:IsA("ModuleScript") then
            return requireSafely(bootstrapAPI)
        end
    end
    
    return nil
end

-- Run tests
local function runTests()
    log("Running UI system tests...")
    testResults.total = #tests
    
    -- Sort tests by group
    table.sort(tests, function(a, b)
        if a.group == b.group then
            return a.name < b.name
        end
        return a.group < b.group
    end)
    
    -- Run each test
    for _, test in ipairs(tests) do
        log("Running test: " .. test.name)
        
        local success, result = pcall(test.fn)
        
        local testPassed
        if success then
            testPassed = result
        else
            testPassed = false
            warn_log("Test error: " .. tostring(result))
        end
        
        -- Record result
        if testPassed then
            testResults.passed += 1
            log("✓ " .. test.name .. ": PASSED")
        else
            testResults.failed += 1
            warn_log("✗ " .. test.name .. ": FAILED")
        end
        
        -- Store detail
        table.insert(testResults.details, {
            name = test.name,
            passed = testPassed,
            group = test.group,
            error = not success and tostring(result) or nil
        })
    end
    
    -- Show report
    printTestReport()
end

--------------------------------------------------------
-- TEST DEFINITIONS
--------------------------------------------------------

-- First, try to find ClientBootstrap
ClientBootstrap = findClientBootstrap()

-- Test if ModuleLoader exists
addTest("ModuleLoader Exists", function()
    local moduleLoaderModule = findModule({
        function() return ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoader") end
    })
    
    if not moduleLoaderModule then
        return false
    end
    
    local moduleLoader = requireSafely(moduleLoaderModule)
    return moduleLoader ~= nil
end, "ModuleLoader Exists")

-- Test if ClientRegistry exists
addTest("ClientRegistry Exists", function()
    -- Try different methods to find ClientRegistry
    local clientRegistry
    
    -- Method 1: Look in ClientBootstrap
    if ClientBootstrap and ClientBootstrap.ClientRegistry then
        clientRegistry = ClientBootstrap.ClientRegistry
    end
    
    -- Method 2: Look in shared folder
    if not clientRegistry then
        local clientRegistryModule = findModule({
            function() return ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ClientRegistry") end,
            function() return LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistry") end
        })
        
        if clientRegistryModule then
            clientRegistry = requireSafely(clientRegistryModule)
        end
    end
    
    if not clientRegistry then
        return false
    end
    
    return true
end, "ClientRegistry Exists")

-- Test if UIComponents exists
addTest("UIComponents Exists", function()
    -- Try different methods to find UIComponents
    local uiComponents
    
    -- Method 1: Look in ClientBootstrap
    if ClientBootstrap and ClientBootstrap.UIComponents then
        uiComponents = ClientBootstrap.UIComponents
    end
    
    -- Method 2: Look in shared folder
    if not uiComponents then
        local uiComponentsModule = findModule({
            function() return ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("UIComponents") end,
            function() return LocalPlayer.PlayerScripts.Client.UI:FindFirstChild("UIComponents") end
        })
        
        if uiComponentsModule then
            uiComponents = requireSafely(uiComponentsModule)
        end
    end
    
    if not uiComponents then
        return false
    end
    
    return true
end, "UIComponents Exists")

-- Test if AssetValidator exists
addTest("AssetValidator Exists", function()
    -- Try to find AssetValidator
    local assetValidatorModule = findModule({
        function() return ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("AssetValidator") end,
        function() return LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("AssetValidator") end
    })
    
    if not assetValidatorModule then
        return false
    end
    
    local assetValidator = requireSafely(assetValidatorModule)
    return assetValidator ~= nil
end, "AssetValidator Exists")

-- Test UIRegistry functionality
addTest("UIRegistry.UIStyle", function()
    -- Find ClientRegistry
    local clientRegistry
    
    if ClientBootstrap and ClientBootstrap.ClientRegistry then
        clientRegistry = ClientBootstrap.ClientRegistry
    else
        local clientRegistryModule = ReplicatedStorage:FindFirstChild("shared") and 
                                     ReplicatedStorage.shared:FindFirstChild("ClientRegistry")
        if clientRegistryModule then
            clientRegistry = requireSafely(clientRegistryModule)
        end
    end
    
    if not clientRegistry then
        return false
    end
    
    -- Check if getUIComponent exists
    if typeof(clientRegistry.getUIComponent) ~= "function" then
        return false
    end
    
    -- Check for UIStyle
    local uiStyle = clientRegistry:getUIComponent("UIStyle")
    return uiStyle ~= nil
end, "UIRegistry")

-- Test IconSet
addTest("UIRegistry.IconSet", function()
    -- Find ClientRegistry
    local clientRegistry
    
    if ClientBootstrap and ClientBootstrap.ClientRegistry then
        clientRegistry = ClientBootstrap.ClientRegistry
    else
        local clientRegistryModule = ReplicatedStorage:FindFirstChild("shared") and 
                                     ReplicatedStorage.shared:FindFirstChild("ClientRegistry")
        if clientRegistryModule then
            clientRegistry = requireSafely(clientRegistryModule)
        end
    end
    
    if not clientRegistry then
        return false
    end
    
    -- Check if getUIComponent exists
    if typeof(clientRegistry.getUIComponent) ~= "function" then
        return false
    end
    
    -- Check for IconSet
    local iconSet = clientRegistry:getUIComponent("IconSet")
    return iconSet ~= nil
end, "UIRegistry")

-- Test ButtonFactory
addTest("UIRegistry.ButtonFactory", function()
    -- Find ClientRegistry
    local clientRegistry
    
    if ClientBootstrap and ClientBootstrap.ClientRegistry then
        clientRegistry = ClientBootstrap.ClientRegistry
    else
        local clientRegistryModule = ReplicatedStorage:FindFirstChild("shared") and 
                                     ReplicatedStorage.shared:FindFirstChild("ClientRegistry")
        if clientRegistryModule then
            clientRegistry = requireSafely(clientRegistryModule)
        end
    end
    
    if not clientRegistry then
        return false
    end
    
    -- Check if getUIComponent exists
    if typeof(clientRegistry.getUIComponent) ~= "function" then
        return false
    end
    
    -- Check for ButtonFactory
    local buttonFactory = clientRegistry:getUIComponent("ButtonFactory")
    return buttonFactory ~= nil
end, "UIRegistry")

-- Test DialogFactory
addTest("UIRegistry.DialogFactory", function()
    -- Find ClientRegistry
    local clientRegistry
    
    if ClientBootstrap and ClientBootstrap.ClientRegistry then
        clientRegistry = ClientBootstrap.ClientRegistry
    else
        local clientRegistryModule = ReplicatedStorage:FindFirstChild("shared") and 
                                     ReplicatedStorage.shared:FindFirstChild("ClientRegistry")
        if clientRegistryModule then
            clientRegistry = requireSafely(clientRegistryModule)
        end
    end
    
    if not clientRegistry then
        return false
    end
    
    -- Check if getUIComponent exists
    if typeof(clientRegistry.getUIComponent) ~= "function" then
        return false
    end
    
    -- Check for DialogFactory
    local dialogFactory = clientRegistry:getUIComponent("DialogFactory")
    return dialogFactory ~= nil
end, "UIRegistry")

-- Test if UIRegistry exists
addTest("UIRegistry Exists", function()
    -- Find ClientRegistry
    local clientRegistry
    
    if ClientBootstrap and ClientBootstrap.ClientRegistry then
        clientRegistry = ClientBootstrap.ClientRegistry
    else
        local clientRegistryModule = ReplicatedStorage:FindFirstChild("shared") and 
                                     ReplicatedStorage.shared:FindFirstChild("ClientRegistry")
        if clientRegistryModule then
            clientRegistry = requireSafely(clientRegistryModule)
        end
    end
    
    return clientRegistry ~= nil
end, "UIRegistry")

-- Test if UIRegistry can show notifications
addTest("UIRegistry Can Show Notifications", function()
    -- Find ClientRegistry
    local clientRegistry
    
    if ClientBootstrap and ClientBootstrap.ClientRegistry then
        clientRegistry = ClientBootstrap.ClientRegistry
    else
        local clientRegistryModule = ReplicatedStorage:FindFirstChild("shared") and 
                                     ReplicatedStorage.shared:FindFirstChild("ClientRegistry")
        if clientRegistryModule then
            clientRegistry = requireSafely(clientRegistryModule)
        end
    end
    
    if not clientRegistry then
        return false
    end
    
    -- Try to find DialogFactory
    local dialogFactory = clientRegistry:getUIComponent("DialogFactory")
    
    -- If not found, try UIComponents
    if not dialogFactory then
        local uiComponents = clientRegistry:getUIComponent("UIComponents")
        
        if uiComponents and typeof(uiComponents.createNotification) == "function" then
            -- We can create notifications through UIComponents
            return true
        end
    elseif dialogFactory and typeof(dialogFactory.createNotification) == "function" then
        -- We can create notifications through DialogFactory
        return true
    end
    
    -- Try to find UIComponents directly
    local uiComponents
    if ClientBootstrap and ClientBootstrap.UIComponents then
        uiComponents = ClientBootstrap.UIComponents
    end
    
    if uiComponents and typeof(uiComponents.createNotification) == "function" then
        return true
    end
    
    return false
end, "UIRegistry")

-- Set up tests to run after a delay
task.delay(UI_TEST_DELAY, function()
    runTests()
end)
