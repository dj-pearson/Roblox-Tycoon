--!strict
--[[
    UISystemTester.client.luau
    
    A tool to test the UI system and verify that all UI components are correctly
    loaded and registered. This can be used to diagnose UI issues and check
    if the fix for the UI Module Loading issues has been successful.
    
    Created: April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Constants
local DEBUG_ENABLED = true
local TESTS = {
    "ModuleLoader Exists",
    "UIRegistry Exists",
    "ClientRegistry Exists",
    "UIComponents Exists",
    "AssetValidator Exists",
    "UIRegistry.UIStyle",
    "UIRegistry.IconSet",
    "UIRegistry.ButtonFactory",
    "UIRegistry.DialogFactory",
    "UIRegistry Can Show Notifications"
}

-- Debug logging
local function log(message)
    if DEBUG_ENABLED then
        print("[UISystemTester] " .. message)
    end
end

local function warn_log(message)
    warn("[UISystemTester] " .. message)
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

-- Try to find and require a module from different paths
local function findAndRequireModule(moduleName)
    local searchPaths = {
        function() return ReplicatedStorage.shared:FindFirstChild(moduleName) end,
        function() return LocalPlayer.PlayerScripts.Client:FindFirstChild(moduleName) end,
        function() return LocalPlayer.PlayerScripts.Client.Core:FindFirstChild(moduleName) end,
        function() return ReplicatedStorage:FindFirstChild(moduleName) end
    }
    
    for _, pathFunc in ipairs(searchPaths) do
        local module = pathFunc()
        if module then
            return requireSafely(module)
        end
    end
    
    return nil
end

-- The test results container
local UISystemTester = {
    testResults = {},
    totalTests = 0,
    passedTests = 0,
    failedTests = 0,
    warnings = 0
}

-- Check if ModuleLoader exists
function UISystemTester:testModuleLoader()
    local moduleLoader = findAndRequireModule("ModuleLoader")
    
    local success = moduleLoader ~= nil
    self:recordTestResult("ModuleLoader Exists", success, 
                        success and "ModuleLoader found" or "ModuleLoader module not found")
                        
    return success, moduleLoader
end

-- Check if UIRegistry exists
function UISystemTester:testUIRegistry()
    local success = false
    local uiRegistry = nil
    
    -- Try to find UIRegistry through ClientRegistry
    local clientRegistry = findAndRequireModule("ClientRegistry")
    
    if clientRegistry then
        uiRegistry = clientRegistry.uiComponents
        success = uiRegistry ~= nil
    else
        -- Try to find UIRegistry directly
        uiRegistry = findAndRequireModule("UIRegistry")
        success = uiRegistry ~= nil
    end
    
    self:recordTestResult("UIRegistry Exists", success, 
                        success and "UIRegistry found" or "UIRegistry not found")
                        
    return success, uiRegistry
end

-- Check if ClientRegistry exists
function UISystemTester:testClientRegistry()
    -- Try to find ClientRegistry through multiple methods
    local clientRegistry
    
    local methods = {
        function() return findAndRequireModule("ClientRegistry") end,
        function() 
            if LocalPlayer and LocalPlayer.PlayerScripts:FindFirstChild("Client") and
               LocalPlayer.PlayerScripts.Client:FindFirstChild("Core") and
               LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistry") then
                return requireSafely(LocalPlayer.PlayerScripts.Client.Core.ClientRegistry)
            end
            return nil
        end,
        function()
            local uiSystem = findAndRequireModule("ClientUISystem")
            if uiSystem and uiSystem.modules then
                return uiSystem.modules.ClientRegistry
            end
            return nil
        end
    }
    
    for _, method in ipairs(methods) do
        clientRegistry = method()
        if clientRegistry then
            break
        end
    end
    
    local success = clientRegistry ~= nil
    self:recordTestResult("ClientRegistry Exists", success, 
                        success and "ClientRegistry found" or "ClientRegistry not found through any method")
                        
    return success, clientRegistry
end

-- Check if UIComponents exists
function UISystemTester:testUIComponents()
    local uiComponents = findAndRequireModule("UIComponents")
    
    local success = uiComponents ~= nil
    self:recordTestResult("UIComponents Exists", success, 
                        success and "UIComponents found" or "UIComponents not found through any method")
                        
    return success, uiComponents
end

-- Check if AssetValidator exists
function UISystemTester:testAssetValidator()
    local assetValidator = findAndRequireModule("AssetValidator")
    
    local success = assetValidator ~= nil
    self:recordTestResult("AssetValidator Exists", success, 
                        success and "AssetValidator found" or "AssetValidator not found through any method")
                        
    return success, assetValidator
end

-- Test UI registry components
function UISystemTester:testUIRegistryComponents()
    local _, clientRegistry = self:testClientRegistry()
    
    if not clientRegistry then
        self:recordTestResult("UIRegistry.UIStyle", false, "ClientRegistry not available")
        self:recordTestResult("UIRegistry.IconSet", false, "ClientRegistry not available")
        self:recordTestResult("UIRegistry.ButtonFactory", false, "ClientRegistry not available")
        self:recordTestResult("UIRegistry.DialogFactory", false, "ClientRegistry not available")
        return false
    end
    
    -- Test UIStyle
    local uiStyle
    if typeof(clientRegistry.getUIComponent) == "function" then
        uiStyle = clientRegistry:getUIComponent("UIStyle")
    elseif clientRegistry.uiComponents then
        uiStyle = clientRegistry.uiComponents.UIStyle
    end
    
    self:recordTestResult("UIRegistry.UIStyle", uiStyle ~= nil, "")
    
    -- Test IconSet
    local iconSet
    if typeof(clientRegistry.getUIComponent) == "function" then
        iconSet = clientRegistry:getUIComponent("IconSet")
    elseif clientRegistry.uiComponents then
        iconSet = clientRegistry.uiComponents.IconSet
    end
    
    self:recordTestResult("UIRegistry.IconSet", iconSet ~= nil, "")
    
    -- Test ButtonFactory
    local buttonFactory
    if typeof(clientRegistry.getUIComponent) == "function" then
        buttonFactory = clientRegistry:getUIComponent("ButtonFactory")
    elseif clientRegistry.uiComponents then
        buttonFactory = clientRegistry.uiComponents.ButtonFactory
    end
    
    self:recordTestResult("UIRegistry.ButtonFactory", buttonFactory ~= nil, "")
    
    -- Test DialogFactory
    local dialogFactory
    if typeof(clientRegistry.getUIComponent) == "function" then
        dialogFactory = clientRegistry:getUIComponent("DialogFactory")
    elseif clientRegistry.uiComponents then
        dialogFactory = clientRegistry.uiComponents.DialogFactory
    end
    
    self:recordTestResult("UIRegistry.DialogFactory", dialogFactory ~= nil, "")
    
    return uiStyle ~= nil and iconSet ~= nil and buttonFactory ~= nil and dialogFactory ~= nil
end

-- Test if notification functionality works
function UISystemTester:testNotifications()
    local _, clientRegistry = self:testClientRegistry()
    
    if not clientRegistry then
        self:recordTestResult("UIRegistry Can Show Notifications", false, "ClientRegistry not available")
        return false
    end
    
    local dialogFactory
    if typeof(clientRegistry.getUIComponent) == "function" then
        dialogFactory = clientRegistry:getUIComponent("DialogFactory")
    elseif clientRegistry.uiComponents then
        dialogFactory = clientRegistry.uiComponents.DialogFactory
    end
    
    if not dialogFactory then
        self:recordTestResult("UIRegistry Can Show Notifications", false, "DialogFactory not available")
        return false
    end
    
    -- Try to create a notification
    local success, _ = pcall(function()
        if typeof(dialogFactory) == "table" and typeof(dialogFactory.createNotification) == "function" then
            dialogFactory:createNotification({
                title = "UI Test",
                message = "Testing notification functionality",
                type = "info",
                duration = 3
            })
        else
            error("DialogFactory doesn't have createNotification method")
        end
    end)
    
    self:recordTestResult("UIRegistry Can Show Notifications", success, 
                        success and "Successfully created notification" or "Failed to create notification")
                        
    return success
end

-- Record a test result
function UISystemTester:recordTestResult(testName, passed, message)
    self.testResults[testName] = {
        passed = passed,
        message = message
    }
    
    self.totalTests += 1
    if passed then
        self.passedTests += 1
    else
        self.failedTests += 1
    end
end

-- Run all tests
function UISystemTester:runAllTests()
    log("Starting UI System tests...")
    
    self:testModuleLoader()
    self:testUIRegistry()
    self:testClientRegistry()
    self:testUIComponents()
    self:testAssetValidator()
    self:testUIRegistryComponents()
    self:testNotifications()
    
    -- Generate and show report
    self:generateReport()
end

-- Generate and print a test report
function UISystemTester:generateReport()
    local passRate = self.totalTests > 0 and math.floor((self.passedTests / self.totalTests) * 100) or 0
    
    log("\n======= UI SYSTEM TEST REPORT =======")
    log("Tests Run: " .. self.totalTests)
    log("Tests Passed: " .. self.passedTests)
    log("Tests Failed: " .. self.failedTests)
    log("Warnings: " .. self.warnings)
    log("Pass Rate: " .. passRate .. "%")
    log("------------------------------------")
    
    -- Show test results by category
    local categories = {}
    local categoryResults = {}
    
    for testName, result in pairs(self.testResults) do
        local category = string.split(testName, ".")[1] or testName
        
        if not categories[category] then
            categories[category] = {
                total = 0,
                passed = 0
            }
            table.insert(categoryResults, category)
        end
        
        categories[category].total += 1
        if result.passed then
            categories[category].passed += 1
        end
    end
    
    -- Sort categories
    table.sort(categoryResults)
    
    -- Show category summaries
    for _, category in ipairs(categoryResults) do
        local stats = categories[category]
        local categoryPassRate = stats.total > 0 and math.floor((stats.passed / stats.total) * 100) or 0
        log(category .. ": " .. stats.passed .. "/" .. stats.total .. " tests passed (" .. categoryPassRate .. "%)")
    end
    
    log("\nFailed Tests:")
    local failedTests = {}
    
    for testName, result in pairs(self.testResults) do
        if not result.passed then
            table.insert(failedTests, testName)
        end
    end
    
    -- Sort failed tests
    table.sort(failedTests)
    
    -- Show failed tests
    for _, testName in ipairs(failedTests) do
        log("✗ " .. testName .. ": " .. self.testResults[testName].message)
    end
    
    -- Create on-screen report if in-game
    self:showInGameReport()
    
    return {
        totalTests = self.totalTests,
        passedTests = self.passedTests,
        failedTests = self.failedTests,
        warnings = self.warnings,
        passRate = passRate,
        results = self.testResults
    }
end

-- Show an in-game UI report
function UISystemTester:showInGameReport()
    if not LocalPlayer then return end
    
    -- Try to get DialogFactory from ClientRegistry
    local clientRegistry = findAndRequireModule("ClientRegistry")
    if not clientRegistry then return end
    
    local dialogFactory
    if typeof(clientRegistry.getUIComponent) == "function" then
        dialogFactory = clientRegistry:getUIComponent("DialogFactory")
    elseif clientRegistry.uiComponents then
        dialogFactory = clientRegistry.uiComponents.DialogFactory
    end
    
    if not dialogFactory or typeof(dialogFactory.createModal) ~= "function" then return end
    
    -- Create a report message
    local passRate = self.totalTests > 0 and math.floor((self.passedTests / self.totalTests) * 100) or 0
    local reportMessage = "Tests Run: " .. self.totalTests .. 
                        "\nTests Passed: " .. self.passedTests ..
                        "\nTests Failed: " .. self.failedTests ..
                        "\nPass Rate: " .. passRate .. "%"
                        
    if self.passedTests == self.totalTests then
        reportMessage = "✅ All UI tests passed!\n\n" .. reportMessage
    else
        reportMessage = "⚠️ Some UI tests failed.\n\n" .. reportMessage
    end
    
    -- Create the modal with the report
    dialogFactory:createModal({
        title = "UI System Test Report",
        message = reportMessage,
        size = UDim2.new(0, 400, 0, 300),
        buttons = {
            {
                text = "OK",
                style = "primary"
            }
        }
    })
end

-- Fix common UI system issues
function UISystemTester:fixCommonIssues()
    log("Attempting to fix common UI system issues...")
    
    -- First check if ClientUISystem exists, if not create it
    local clientUISystem = findAndRequireModule("ClientUISystem")
    
    if not clientUISystem then
        log("ClientUISystem not found, creating it...")
        
        -- Get the ClientUISystem from script
        local success, source = pcall(function()
            return script.Source
        end)
        
        if success and source then
            -- Create the module
            local clientFolder = LocalPlayer.PlayerScripts:FindFirstChild("Client") or
                                 Instance.new("Folder")
            
            if clientFolder.Name ~= "Client" then
                clientFolder.Name = "Client"
                clientFolder.Parent = LocalPlayer.PlayerScripts
            end
            
            local uiSystemModule = Instance.new("ModuleScript")
            uiSystemModule.Name = "ClientUISystem"
            uiSystemModule.Source = "-- Auto-created by UISystemTester\n" .. source
            uiSystemModule.Parent = clientFolder
            
            log("Created ClientUISystem module at " .. uiSystemModule:GetFullName())
            
            -- Try to require it
            clientUISystem = requireSafely(uiSystemModule)
        end
    end
    
    -- If we have ClientUISystem now, use it to fix issues
    if clientUISystem and typeof(clientUISystem.initialize) == "function" then
        log("Using ClientUISystem to fix UI issues...")
        clientUISystem:initialize()
    else
        warn_log("Couldn't create or initialize ClientUISystem")
        return false
    end
    
    -- Re-run tests to verify fixes
    self:runAllTests()
    
    return self.passedTests > 0
end

-- Reset state for a new test run
function UISystemTester:reset()
    self.testResults = {}
    self.totalTests = 0
    self.passedTests = 0
    self.failedTests = 0
    self.warnings = 0
end

-- Run tests immediately
UISystemTester:runAllTests()

-- Return the tester module
return UISystemTester
