--!strict
--[[
    UISystemTester.client.luau
    
    A client-side utility for testing all aspects of the UI loading system.
    
    Created: April 25, 2025
    
    This module:
    1. Tests all UI module loading paths
    2. Validates that fallbacks work correctly
    3. Reports detailed diagnostics about the UI system health
    4. Helps identify any remaining module loading issues
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("[UISystemTester] No LocalPlayer found")
    return
end

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    TEST_ALL_MODULES = true,
    CREATE_TEST_UI = true,
    REPORT_RESULTS = true
}

-- Find shared folder
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    warn("[UISystemTester] Shared folder not found in ReplicatedStorage")
    return
end

-- Test results logging
local testResults = {
    totalTests = 0,
    passedTests = 0,
    failedTests = 0,
    warningTests = 0,
    testDetails = {}
}

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn("[UISystemTester] Failed to require module: ", (typeof(module) == "Instance" and module:GetFullName() or tostring(module)))
        return nil
    end
    
    return result
end

-- Try to get modules
local ModuleLoader = requireSafely(sharedFolder:FindFirstChild("ModuleLoader"))
local ClientRegistry = nil
local UIRegistry = nil
local UIComponents = nil
local AssetValidator = nil

-- Logging function
local function log(message, level)
    level = level or "info"
    
    if level == "info" then
        print("[UISystemTester] " .. message)
    elseif level == "warn" then
        warn("[UISystemTester] " .. message)
    elseif level == "error" then
        error("[UISystemTester] " .. message)
    end
end

-- Record test result
local function recordTestResult(testName, passed, details)
    testResults.totalTests += 1
    
    if passed == true then
        testResults.passedTests += 1
    elseif passed == false then
        testResults.failedTests += 1
    else
        -- Treat as warning
        testResults.warningTests += 1
    end
    
    table.insert(testResults.testDetails, {
        name = testName,
        passed = passed,
        details = details or "",
        timestamp = os.time()
    })
    
    -- Output to console
    if passed == true then
        log("✓ PASS: " .. testName)
    elseif passed == false then
        log("✗ FAIL: " .. testName .. (details and " - " .. details or ""), "warn")
    else
        log("⚠ WARNING: " .. testName .. (details and " - " .. details or ""), "warn")
    end
end

-- Test ModuleLoader
local function testModuleLoader()
    log("Testing ModuleLoader...")
    
    -- Test if ModuleLoader exists
    if not ModuleLoader then
        recordTestResult("ModuleLoader Exists", false, "ModuleLoader module not found")
        return
    end
    
    recordTestResult("ModuleLoader Exists", true)
    
    -- Test core functionality
    local hasRequireMethod = typeof(ModuleLoader.require) == "function"
    recordTestResult("ModuleLoader.require Method", hasRequireMethod)
    
    local hasTryRequireMethod = typeof(ModuleLoader.tryRequire) == "function"
    recordTestResult("ModuleLoader.tryRequire Method", hasTryRequireMethod)
    
    -- Test module resolution
    if hasTryRequireMethod then
        local clientRegistry = ModuleLoader.tryRequire("ClientRegistry")
        recordTestResult("ModuleLoader Can Find ClientRegistry", clientRegistry ~= nil)
        
        local uiComponents = ModuleLoader.tryRequire("UIComponents")
        recordTestResult("ModuleLoader Can Find UIComponents", uiComponents ~= nil)
    end
end

-- Test ClientRegistry
local function testClientRegistry()
    log("Testing ClientRegistry...")
    
    -- Try multiple ways to get ClientRegistry
    if not ClientRegistry then
        -- Try through ModuleLoader first
        if ModuleLoader and typeof(ModuleLoader.tryRequire) == "function" then
            ClientRegistry = ModuleLoader.tryRequire("ClientRegistry")
        end
        
        -- Try direct require from various locations if still not found
        if not ClientRegistry then
            -- Try in ReplicatedStorage
            if sharedFolder:FindFirstChild("ClientRegistry") then
                ClientRegistry = requireSafely(sharedFolder.ClientRegistry)
            end
            
            -- Try in PlayerScripts
            if not ClientRegistry then
                if LocalPlayer.PlayerScripts:FindFirstChild("Client") and 
                   LocalPlayer.PlayerScripts.Client:FindFirstChild("Core") and
                   LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistry") then
                    ClientRegistry = requireSafely(LocalPlayer.PlayerScripts.Client.Core.ClientRegistry)
                end
            end
        end
    end
    
    -- Test if ClientRegistry exists
    if not ClientRegistry then
        recordTestResult("ClientRegistry Exists", false, "ClientRegistry not found through any method")
        return
    end
    
    recordTestResult("ClientRegistry Exists", true)
    
    -- Test core functionality
    local hasRegisterSystemMethod = typeof(ClientRegistry.registerSystem) == "function"
    recordTestResult("ClientRegistry.registerSystem Method", hasRegisterSystemMethod)
    
    local hasGetSystemMethod = typeof(ClientRegistry.getSystem) == "function"
    recordTestResult("ClientRegistry.getSystem Method", hasGetSystemMethod)
    
    -- Test UI components access
    if typeof(ClientRegistry.getUIComponent) == "function" then
        local uiStyle = ClientRegistry:getUIComponent("UIStyle")
        recordTestResult("ClientRegistry Can Access UIStyle", uiStyle ~= nil)
        
        local iconSet = ClientRegistry:getUIComponent("IconSet")
        recordTestResult("ClientRegistry Can Access IconSet", iconSet ~= nil)
    else
        recordTestResult("ClientRegistry.getUIComponent Method", false)
    end
    
    -- Test registration
    if hasRegisterSystemMethod and hasGetSystemMethod then
        local testSystem = { name = "TestSystem", initialized = true }
        local registerSuccess = pcall(function()
            ClientRegistry:registerSystem("TestSystem", testSystem)
        end)
        recordTestResult("ClientRegistry Can Register System", registerSuccess)
        
        if registerSuccess then
            local retrievedSystem = ClientRegistry:getSystem("TestSystem")
            recordTestResult("ClientRegistry Can Retrieve Registered System", 
                retrievedSystem ~= nil and retrievedSystem.name == "TestSystem")
        end
    end
end

-- Test UIRegistry
local function testUIRegistry()
    log("Testing UIRegistry...")
    
    -- Try to find UIRegistry
    if not UIRegistry then
        -- Try through ClientRegistry first
        if ClientRegistry and typeof(ClientRegistry.getSystem) == "function" then
            UIRegistry = ClientRegistry:getSystem("UIRegistry")
        end
        
        -- Try through ModuleLoader if not found
        if not UIRegistry and ModuleLoader and typeof(ModuleLoader.tryRequire) == "function" then
            UIRegistry = ModuleLoader.tryRequire("UIRegistry")
        end
        
        -- Try direct require if still not found
        if not UIRegistry then
            if LocalPlayer.PlayerScripts:FindFirstChild("Client") and 
               LocalPlayer.PlayerScripts.Client:FindFirstChild("UI") and
               LocalPlayer.PlayerScripts.Client.UI:FindFirstChild("UIRegistry") then
                UIRegistry = requireSafely(LocalPlayer.PlayerScripts.Client.UI.UIRegistry)
            end
        end
    end
    
    -- Test if UIRegistry exists
    if not UIRegistry then
        recordTestResult("UIRegistry Exists", false, "UIRegistry not found through any method")
        return
    end
    
    recordTestResult("UIRegistry Exists", true)
    
    -- Test core functionality
    local hasRegisterUIMethod = typeof(UIRegistry.registerUI) == "function"
    recordTestResult("UIRegistry.registerUI Method", hasRegisterUIMethod)
    
    local hasShowUIMethod = typeof(UIRegistry.showUI) == "function"
    recordTestResult("UIRegistry.showUI Method", hasShowUIMethod)
    
    local hasHideUIMethod = typeof(UIRegistry.hideUI) == "function"
    recordTestResult("UIRegistry.hideUI Method", hasHideUIMethod)
    
    -- Test UI component access
    recordTestResult("UIRegistry.UIStyle", UIRegistry.UIStyle ~= nil)
    recordTestResult("UIRegistry.IconSet", UIRegistry.IconSet ~= nil)
    recordTestResult("UIRegistry.ButtonFactory", UIRegistry.ButtonFactory ~= nil)
    recordTestResult("UIRegistry.DialogFactory", UIRegistry.DialogFactory ~= nil)
    
    -- Test notification system
    if typeof(UIRegistry.showNotification) == "function" then
        local notifySuccess = pcall(function()
            UIRegistry:showNotification("UI System Test", "info", 2)
        end)
        recordTestResult("UIRegistry Can Show Notifications", notifySuccess)
    else
        recordTestResult("UIRegistry.showNotification Method", false)
    end
end

-- Test UIComponents
local function testUIComponents()
    log("Testing UIComponents...")
    
    -- Try to find UIComponents
    if not UIComponents then
        -- Try through ModuleLoader first
        if ModuleLoader and typeof(ModuleLoader.tryRequire) == "function" then
            UIComponents = ModuleLoader.tryRequire("UIComponents")
        end
        
        -- Try direct require if not found
        if not UIComponents and sharedFolder:FindFirstChild("UIComponents") then
            UIComponents = requireSafely(sharedFolder.UIComponents)
        end
    end
    
    -- Test if UIComponents exists
    if not UIComponents then
        recordTestResult("UIComponents Exists", false, "UIComponents not found through any method")
        return
    end
    
    recordTestResult("UIComponents Exists", true)
    
    -- Test individual components
    recordTestResult("UIComponents.UIStyle", UIComponents.UIStyle ~= nil)
    recordTestResult("UIComponents.IconSet", UIComponents.IconSet ~= nil)
    recordTestResult("UIComponents.ButtonFactory", UIComponents.ButtonFactory ~= nil)
    recordTestResult("UIComponents.DialogFactory", UIComponents.DialogFactory ~= nil)
    
    -- Test button creation
    if UIComponents.ButtonFactory and typeof(UIComponents.ButtonFactory.createButton) == "function" then
        local buttonSuccess = pcall(function()
            local button = UIComponents.ButtonFactory.createButton("Test Button")
            if button and button:IsA("TextButton") then
                button:Destroy()
            end
        end)
        recordTestResult("UIComponents Can Create Buttons", buttonSuccess)
    else
        recordTestResult("UIComponents Button Creation", false)
    end
    
    -- Test dialog creation
    if UIComponents.DialogFactory and typeof(UIComponents.DialogFactory.createConfirmDialog) == "function" then
        local dialogSuccess = pcall(function()
            local dialog = UIComponents.DialogFactory.createConfirmDialog(
                "Test Dialog", 
                "This is a test dialog",
                function() end,
                function() end
            )
            if dialog then
                task.delay(0.5, function()
                    if dialog.Parent then
                        dialog:Destroy()
                    end
                end)
            end
        end)
        recordTestResult("UIComponents Can Create Dialogs", dialogSuccess)
    else
        recordTestResult("UIComponents Dialog Creation", false)
    end
end

-- Test AssetValidator
local function testAssetValidator()
    log("Testing AssetValidator...")
    
    -- Try to find AssetValidator
    if not AssetValidator then
        -- Try through ModuleLoader first
        if ModuleLoader and typeof(ModuleLoader.tryRequire) == "function" then
            AssetValidator = ModuleLoader.tryRequire("AssetValidator")
        end
        
        -- Try direct require if not found
        if not AssetValidator and sharedFolder:FindFirstChild("AssetValidator") then
            AssetValidator = requireSafely(sharedFolder.AssetValidator)
        end
    end
    
    -- Test if AssetValidator exists
    if not AssetValidator then
        recordTestResult("AssetValidator Exists", false, "AssetValidator not found through any method")
        return
    end
    
    recordTestResult("AssetValidator Exists", true)
    
    -- Test core functionality
    local hasValidateAssetMethod = typeof(AssetValidator.validateAsset) == "function"
    recordTestResult("AssetValidator.validateAsset Method", hasValidateAssetMethod)
    
    local hasGetValidAssetIdMethod = typeof(AssetValidator.getValidAssetId) == "function"
    recordTestResult("AssetValidator.getValidAssetId Method", hasGetValidAssetIdMethod)
    
    -- Test fallback assets
    recordTestResult("AssetValidator Has Fallback Assets", AssetValidator.fallbackAssets ~= nil)
    
    if AssetValidator.fallbackAssets then
        recordTestResult("AssetValidator.fallbackAssets.Image", AssetValidator.fallbackAssets.Image ~= nil)
        recordTestResult("AssetValidator.fallbackAssets.Sound", AssetValidator.fallbackAssets.Sound ~= nil)
    end
    
    -- Test asset validation with known good ID
    if hasValidateAssetMethod then
        local validResult = AssetValidator.validateAsset(AssetValidator.fallbackAssets.Image, "Image")
        recordTestResult("AssetValidator Can Validate Known Good Image", validResult == true)
    end
    
    -- Test asset validation with known bad ID
    if hasValidateAssetMethod then
        local invalidResult = AssetValidator.validateAsset("rbxassetid://999999999999", "Image")
        recordTestResult("AssetValidator Can Detect Invalid Asset", invalidResult == false)
    end
end

-- Create test UI to verify components work
local function createTestUI()
    log("Creating test UI...")
    
    if not UIComponents or not UIComponents.ButtonFactory or not UIComponents.UIStyle then
        recordTestResult("Create Test UI", false, "Required UI components not available")
        return
    end
    
    -- Create a ScreenGui
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UISystemTest"
    screenGui.Parent = playerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "TestFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    mainFrame.BackgroundColor3 = UIComponents.UIStyle.Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Create title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.BackgroundColor3 = UIComponents.UIStyle.Colors.Primary
    titleLabel.BorderSizePixel = 0
    titleLabel.Font = UIComponents.UIStyle.Fonts.Title
    titleLabel.TextSize = UIComponents.UIStyle.FontSizes.Title
    titleLabel.TextColor3 = UIComponents.UIStyle.Colors.TextLight
    titleLabel.Text = "UI System Test"
    titleLabel.Parent = mainFrame
    
    -- Add corner to title
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleLabel
    
    -- Create test results display
    local resultsLabel = Instance.new("TextLabel")
    resultsLabel.Name = "Results"
    resultsLabel.Size = UDim2.new(1, -20, 0, 30)
    resultsLabel.Position = UDim2.new(0, 10, 0, 50)
    resultsLabel.BackgroundTransparency = 1
    resultsLabel.Font = UIComponents.UIStyle.Fonts.Body
    resultsLabel.TextSize = UIComponents.UIStyle.FontSizes.Body
    resultsLabel.TextColor3 = UIComponents.UIStyle.Colors.TextDark
    resultsLabel.Text = "Running UI System Tests..."
    resultsLabel.TextXAlignment = Enum.TextXAlignment.Left
    resultsLabel.Parent = mainFrame
    
    -- Create test buttons
    local testModulesButton = UIComponents.ButtonFactory.createButton("Test All Modules")
    testModulesButton.Position = UDim2.new(0.5, -150, 0, 90)
    testModulesButton.Size = UDim2.new(0, 140, 0, 40)
    testModulesButton.Parent = mainFrame
    
    local testNotifyButton = UIComponents.ButtonFactory.createButton("Test Notification")
    testNotifyButton.Position = UDim2.new(0.5, 10, 0, 90)
    testNotifyButton.Size = UDim2.new(0, 140, 0, 40)
    testNotifyButton.Parent = mainFrame
    
    local testDialogButton = UIComponents.ButtonFactory.createButton("Test Dialog")
    testDialogButton.Position = UDim2.new(0.5, -150, 0, 140)
    testDialogButton.Size = UDim2.new(0, 140, 0, 40)
    testDialogButton.Parent = mainFrame
    
    local testAssetsButton = UIComponents.ButtonFactory.createButton("Test Assets")
    testAssetsButton.Position = UDim2.new(0.5, 10, 0, 140)
    testAssetsButton.Size = UDim2.new(0, 140, 0, 40)
    testAssetsButton.Parent = mainFrame
    
    local closeButton = UIComponents.ButtonFactory.createButton("Close")
    closeButton.Position = UDim2.new(0.5, -70, 1, -60)
    closeButton.Size = UDim2.new(0, 140, 0, 40)
    closeButton.BackgroundColor3 = UIComponents.UIStyle.Colors.Danger
    closeButton.Parent = mainFrame
    
    -- Update results display
    local function updateResults()
        local passRate = math.floor((testResults.passedTests / testResults.totalTests) * 100)
        resultsLabel.Text = string.format(
            "Tests: %d | Passed: %d | Failed: %d | Pass Rate: %d%%",
            testResults.totalTests,
            testResults.passedTests,
            testResults.failedTests,
            passRate
        )
        
        -- Set color based on results
        if testResults.failedTests > 0 then
            resultsLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
        elseif testResults.warningTests > 0 then
            resultsLabel.TextColor3 = Color3.fromRGB(255, 190, 0)
        else
            resultsLabel.TextColor3 = Color3.fromRGB(40, 180, 100)
        end
    end
    
    -- Button handlers
    testModulesButton.MouseButton1Click:Connect(function()
        testModuleLoader()
        testClientRegistry()
        testUIRegistry()
        testUIComponents()
        updateResults()
    end)
    
    testNotifyButton.MouseButton1Click:Connect(function()
        if UIRegistry and typeof(UIRegistry.showNotification) == "function" then
            UIRegistry:showNotification("Test Notification", "info", 2)
            recordTestResult("Notification Display", true)
        elseif UIComponents.DialogFactory and typeof(UIComponents.DialogFactory.createNotification) == "function" then
            UIComponents.DialogFactory.createNotification("Test Notification", 2, "info")
            recordTestResult("Notification Display", true)
        else
            recordTestResult("Notification Display", false, "No notification system available")
        end
        updateResults()
    end)
    
    testDialogButton.MouseButton1Click:Connect(function()
        if UIRegistry and typeof(UIRegistry.showConfirmDialog) == "function" then
            UIRegistry:showConfirmDialog(
                "Test Dialog",
                "This is a test dialog to verify UI components are working correctly.",
                function() recordTestResult("Dialog Confirm Button", true) end,
                function() recordTestResult("Dialog Cancel Button", true) end
            )
            recordTestResult("Dialog Display", true)
        elseif UIComponents.DialogFactory and typeof(UIComponents.DialogFactory.createConfirmDialog) == "function" then
            UIComponents.DialogFactory.createConfirmDialog(
                "Test Dialog",
                "This is a test dialog to verify UI components are working correctly.",
                function() recordTestResult("Dialog Confirm Button", true) end,
                function() recordTestResult("Dialog Cancel Button", true) end
            )
            recordTestResult("Dialog Display", true)
        else
            recordTestResult("Dialog Display", false, "No dialog system available")
        end
        updateResults()
    end)
    
    testAssetsButton.MouseButton1Click:Connect(function()
        testAssetValidator()
        updateResults()
        
        -- Create asset test dialog
        if AssetValidator then
            -- Create a dashboard
            AssetValidator.createAssetHealthDashboard()
        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Run initial tests
    task.spawn(function()
        testModuleLoader()
        testClientRegistry()
        testUIRegistry()
        testUIComponents()
        testAssetValidator()
        updateResults()
    end)
    
    -- Auto-close after 60 seconds if still open
    task.delay(60, function()
        if screenGui.Parent then
            screenGui:Destroy()
        end
    end)
    
    recordTestResult("Test UI Created", true)
    return screenGui
end

-- Generate full report
local function generateReport()
    if testResults.totalTests == 0 then
        log("No tests have been run yet", "warn")
        return
    end
    
    local passRate = math.floor((testResults.passedTests / testResults.totalTests) * 100)
    
    print("\n======= UI SYSTEM TEST REPORT =======")
    print(string.format("Tests Run: %d", testResults.totalTests))
    print(string.format("Tests Passed: %d", testResults.passedTests))
    print(string.format("Tests Failed: %d", testResults.failedTests))
    print(string.format("Warnings: %d", testResults.warningTests))
    print(string.format("Pass Rate: %d%%", passRate))
    print("------------------------------------")
    
    -- Group results by category
    local categories = {}
    for _, test in ipairs(testResults.testDetails) do
        local category = string.match(test.name, "^([^%.]+)")
        if not category then category = "Other" end
        
        if not categories[category] then
            categories[category] = {
                total = 0,
                passed = 0,
                failed = 0,
                warnings = 0
            }
        end
        
        categories[category].total += 1
        
        if test.passed == true then
            categories[category].passed += 1
        elseif test.passed == false then
            categories[category].failed += 1
        else
            categories[category].warnings += 1
        end
    end
    
    -- Print category results
    for category, results in pairs(categories) do
        local categoryPassRate = math.floor((results.passed / results.total) * 100)
        print(string.format("%s: %d/%d tests passed (%d%%)", 
            category, results.passed, results.total, categoryPassRate))
    end
    
    -- Print failed tests
    if testResults.failedTests > 0 then
        print("\nFailed Tests:")
        for _, test in ipairs(testResults.testDetails) do
            if test.passed == false then
                print(string.format("✗ %s: %s", test.name, test.details))
            end
        end
    end
    
    print("===================================\n")
    
    -- Return a summary for other systems
    return {
        timestamp = os.time(),
        summary = {
            totalTests = testResults.totalTests,
            passedTests = testResults.passedTests,
            failedTests = testResults.failedTests,
            warningTests = testResults.warningTests,
            passRate = passRate
        },
        categories = categories,
        details = testResults.testDetails
    }
end

-- Initialize the tester
local function initialize()
    log("Initializing UI System Tester...")
    
    -- Run system tests
    if CONFIG.TEST_ALL_MODULES then
        task.spawn(function()
            -- Wait a moment for all systems to initialize
            task.wait(1)
            
            testModuleLoader()
            testClientRegistry()
            testUIRegistry()
            testUIComponents()
            testAssetValidator()
            
            if CONFIG.REPORT_RESULTS then
                generateReport()
            end
            
            -- Create test UI after tests are complete
            if CONFIG.CREATE_TEST_UI then
                createTestUI()
            end
        end)
    elseif CONFIG.CREATE_TEST_UI then
        -- Just create the test UI
        task.spawn(function()
            task.wait(1)
            createTestUI()
        end)
    end
    
    return true
end

-- Auto-initialize
initialize()

-- Module interface
local UISystemTester = {
    testModuleLoader = testModuleLoader,
    testClientRegistry = testClientRegistry,
    testUIRegistry = testUIRegistry,
    testUIComponents = testUIComponents,
    testAssetValidator = testAssetValidator,
    createTestUI = createTestUI,
    generateReport = generateReport,
    testResults = testResults
}

return UISystemTester
