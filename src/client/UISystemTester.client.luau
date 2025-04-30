--[[
    UISystemTester.client.luau
    
    Tests the client UI Systems to verify they are properly loaded and functioning.
    This script will check if all required UI components and systems are available
    and report any issues.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Test results
local results = {
    testsRun = 0,
    testsPassed = 0,
    testsFailed = 0,
    details = {}
}

-- Test logging
local function log(message)
    print("[UISystemTester] " .. message)
end

local function recordTest(name, passed, message)
    results.testsRun += 1
    
    if passed then
        results.testsPassed += 1
        log("✓ " .. name)
    else
        results.testsFailed += 1
        log("✗ " .. name .. ": " .. (message or "Test failed"))
    end
    
    -- Record detailed result
    table.insert(results.details, {
        name = name,
        passed = passed,
        message = message
    })
    
    return passed
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
        return nil
    end
end

-- Find module in various locations
local function findModule(name)
    -- Try shared folder first
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild(name) then
        return shared:FindFirstChild(name)
    end
    
    -- Try client Core folder
    local clientCore = script.Parent
    if clientCore and clientCore:FindFirstChild(name) then
        return clientCore:FindFirstChild(name)
    end
    
    -- Try other common locations
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and ReplicatedStorage.src.client:FindFirstChild("Core"),
        ReplicatedStorage:FindFirstChild("Core"),
        player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("Core")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and path:FindFirstChild(name) then
            return path:FindFirstChild(name)
        end
    end
    
    return nil
end

-- Get a system through ModuleScriptAccessor if available
local function getSystemViaMSA(systemName)
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local ModuleScriptAccessor = safeRequire(shared.ModuleScriptAccessor)
        if ModuleScriptAccessor and typeof(ModuleScriptAccessor.getSystem) == "function" then
            return ModuleScriptAccessor.getSystem(systemName)
        end
    end
    return nil
end

-- Helper to get a system through any method
local function getSystem(systemName)
    -- Try via ModuleScriptAccessor
    local system = getSystemViaMSA(systemName)
    if system then
        return system
    end
    
    -- Try direct require
    local module = findModule(systemName)
    if module then
        return safeRequire(module)
    end
    
    return nil
end

-- Tests start here
log("\n===== STARTING UI SYSTEM TESTS =====")

-- Test: Check if ModuleScriptAccessor exists
local ModuleScriptAccessor = findModule("ModuleScriptAccessor")
recordTest("ModuleScriptAccessor Exists", ModuleScriptAccessor ~= nil, ModuleScriptAccessor == nil and "ModuleScriptAccessor not found" or nil)

-- Test: Check if ModuleLoader exists
local ModuleLoader = getSystem("ModuleLoader")
recordTest("ModuleLoader Exists", ModuleLoader ~= nil, ModuleLoader == nil and "ModuleLoader module not found" or nil)

-- Test: Check if AssetValidator exists
local AssetValidator = getSystem("AssetValidator")
recordTest("AssetValidator Exists", AssetValidator ~= nil, AssetValidator == nil and "AssetValidator not found through any method" or nil)

-- Test: Check if UIComponents exists
local UIComponents = getSystem("UIComponents")
recordTest("UIComponents Exists", UIComponents ~= nil, UIComponents == nil and "UIComponents not found through any method" or nil)

-- Test: Check if UIRegistry exists
local UIRegistry = getSystem("UIRegistry")
recordTest("UIRegistry Exists", UIRegistry ~= nil, UIRegistry == nil and "UIRegistry not found" or nil)

-- Tests for UIRegistry functionality (if available)
if UIRegistry then
    -- Test ButtonFactory
    recordTest(
        "UIRegistry.ButtonFactory", 
        UIRegistry.ButtonFactory ~= nil and typeof(UIRegistry.ButtonFactory.createBasicButton) == "function",
        UIRegistry.ButtonFactory == nil and "ButtonFactory missing" or 
        typeof(UIRegistry.ButtonFactory.createBasicButton) ~= "function" and "createBasicButton function missing" or nil
    )
    
    -- Test DialogFactory
    recordTest(
        "UIRegistry.DialogFactory", 
        UIRegistry.DialogFactory ~= nil and typeof(UIRegistry.DialogFactory.createNotification) == "function",
        UIRegistry.DialogFactory == nil and "DialogFactory missing" or 
        typeof(UIRegistry.DialogFactory.createNotification) ~= "function" and "createNotification function missing" or nil
    )
    
    -- Test UIStyle
    recordTest(
        "UIRegistry.UIStyle", 
        UIRegistry.UIStyle ~= nil and UIRegistry.UIStyle.COLORS ~= nil,
        UIRegistry.UIStyle == nil and "UIStyle missing" or 
        UIRegistry.UIStyle.COLORS == nil and "UIStyle.COLORS missing" or nil
    )
    
    -- Test IconSet
    recordTest(
        "UIRegistry.IconSet", 
        UIRegistry.IconSet ~= nil and UIRegistry.IconSet.SUCCESS ~= nil,
        UIRegistry.IconSet == nil and "IconSet missing" or 
        UIRegistry.IconSet.SUCCESS == nil and "IconSet.SUCCESS missing" or nil
    )
    
    -- Test notification functionality
    recordTest(
        "UIRegistry Can Show Notifications", 
        UIRegistry.DialogFactory ~= nil and typeof(UIRegistry.DialogFactory.showNotification) == "function",
        UIRegistry.DialogFactory == nil and "DialogFactory missing" or 
        typeof(UIRegistry.DialogFactory.showNotification) ~= "function" and "DialogFactory not available" or nil
    )
    
    -- If test passes, show a notification as demonstration
    if UIRegistry.DialogFactory and typeof(UIRegistry.DialogFactory.showNotification) == "function" then
        UIRegistry.DialogFactory.showNotification(
            "UI System Tests", 
            "UI System Tester completed successfully.", 
            "success", 
            5
        )
    end
end

-- Summary
local passRate = math.floor((results.testsPassed / results.testsRun) * 100)
log("\n===== UI SYSTEM TEST RESULTS =====")
log("Tests Run: " .. results.testsRun .. ", Tests Passed: " .. results.testsPassed .. ", Tests Failed: " .. results.testsFailed)
log("Pass Rate: " .. passRate .. "%")
log("===================================\n")

-- Create a test report GUI
local function createTestReportGUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UISystemTestReport"
    screenGui.ResetOnSpawn = false
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "UI System Test Results"
    title.Parent = mainFrame
    
    -- Summary
    local summary = Instance.new("TextLabel")
    summary.Name = "Summary"
    summary.Size = UDim2.new(1, -20, 0, 30)
    summary.Position = UDim2.new(0, 10, 0, 50)
    summary.BackgroundTransparency = 1
    summary.Font = Enum.Font.SourceSans
    summary.TextColor3 = Color3.fromRGB(200, 200, 200)
    summary.TextSize = 18
    summary.TextXAlignment = Enum.TextXAlignment.Left
    summary.Text = "Tests: " .. results.testsRun .. " | Passed: " .. results.testsPassed .. " | Failed: " .. results.testsFailed .. " | Pass Rate: " .. passRate .. "%"
    summary.Parent = mainFrame
    
    -- Color bar indicating overall status
    local statusBar = Instance.new("Frame")
    statusBar.Name = "StatusBar"
    statusBar.Size = UDim2.new(1, -20, 0, 8)
    statusBar.Position = UDim2.new(0, 10, 0, 85)
    statusBar.BorderSizePixel = 0
    
    -- Set color based on pass rate
    if passRate >= 90 then
        statusBar.BackgroundColor3 = Color3.fromRGB(16, 124, 16) -- Green
    elseif passRate >= 75 then
        statusBar.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Orange
    else
        statusBar.BackgroundColor3 = Color3.fromRGB(232, 17, 35) -- Red
    end
    
    statusBar.Parent = mainFrame
    
    -- Results scroll frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ResultsScroll"
    scrollFrame.Size = UDim2.new(1, -20, 1, -100)
    scrollFrame.Position = UDim2.new(0, 10, 0, 100)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.BorderSizePixel = 0
    scrollFrame.Parent = mainFrame
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.SourceSans
    closeButton.Parent = mainFrame
    
    -- Add corner radius to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Add test results to scroll frame
    local yOffset = 0
    for i, result in ipairs(results.details) do
        local resultFrame = Instance.new("Frame")
        resultFrame.Name = "TestResult_" .. i
        resultFrame.Size = UDim2.new(1, -10, 0, 30)
        resultFrame.Position = UDim2.new(0, 0, 0, yOffset)
        resultFrame.BackgroundTransparency = i % 2 == 0 and 0.9 or 1
        resultFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        resultFrame.BorderSizePixel = 0
        resultFrame.Parent = scrollFrame
        
        local statusIcon = Instance.new("TextLabel")
        statusIcon.Name = "StatusIcon"
        statusIcon.Size = UDim2.new(0, 30, 1, 0)
        statusIcon.Position = UDim2.new(0, 0, 0, 0)
        statusIcon.BackgroundTransparency = 1
        statusIcon.Text = result.passed and "✓" or "✗"
        statusIcon.TextColor3 = result.passed and Color3.fromRGB(16, 124, 16) or Color3.fromRGB(232, 17, 35)
        statusIcon.TextSize = 18
        statusIcon.Font = Enum.Font.SourceSansBold
        statusIcon.Parent = resultFrame
        
        local testName = Instance.new("TextLabel")
        testName.Name = "TestName"
        testName.Size = UDim2.new(1, -40, 1, 0)
        testName.Position = UDim2.new(0, 30, 0, 0)
        testName.BackgroundTransparency = 1
        testName.Text = result.name
        testName.TextColor3 = Color3.fromRGB(255, 255, 255)
        testName.TextSize = 16
        testName.Font = Enum.Font.SourceSans
        testName.TextXAlignment = Enum.TextXAlignment.Left
        testName.Parent = resultFrame
        
        -- If test failed, show error message on hover
        if not result.passed and result.message then
            -- Add hover effect
            resultFrame.MouseEnter:Connect(function()
                local tooltip = Instance.new("Frame")
                tooltip.Name = "ErrorTooltip"
                tooltip.Size = UDim2.new(0, 300, 0, 40)
                tooltip.Position = UDim2.new(0, 0, 0, 30)
                tooltip.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                tooltip.BorderSizePixel = 0
                tooltip.ZIndex = 10
                tooltip.Parent = resultFrame
                
                -- Add corner radius
                local tooltipCorner = Instance.new("UICorner")
                tooltipCorner.CornerRadius = UDim.new(0, 4)
                tooltipCorner.Parent = tooltip
                
                -- Error message
                local errorMsg = Instance.new("TextLabel")
                errorMsg.Name = "ErrorMessage"
                errorMsg.Size = UDim2.new(1, -10, 1, -10)
                errorMsg.Position = UDim2.new(0, 5, 0, 5)
                errorMsg.BackgroundTransparency = 1
                errorMsg.Text = result.message
                errorMsg.TextColor3 = Color3.fromRGB(232, 17, 35)
                errorMsg.TextSize = 14
                errorMsg.Font = Enum.Font.SourceSans
                errorMsg.TextXAlignment = Enum.TextXAlignment.Left
                errorMsg.TextWrapped = true
                errorMsg.ZIndex = 10
                errorMsg.Parent = tooltip
            end)
            
            resultFrame.MouseLeave:Connect(function()
                local tooltip = resultFrame:FindFirstChild("ErrorTooltip")
                if tooltip then
                    tooltip:Destroy()
                end
            end)
        end
        
        yOffset += 30
    end
    
    -- Update scroll frame canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    
    -- Parent the ScreenGui
    screenGui.Parent = player.PlayerGui
end

-- Create the test report GUI
createTestReportGUI()

-- Return test results
return results
