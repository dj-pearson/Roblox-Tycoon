--[[
    MenuButtonsTest.client.luau
    
    A comprehensive test script to verify that all menu buttons correctly open their UIs.
    This script will test each menu button to ensure it properly finds and displays its UI interface.
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

print("\n==== STARTING MENU BUTTONS TEST ====")

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[MenuButtonsTest] Failed to require module:", tostring(result))
        return nil
    end
end

-- Test logger
local function logTestResult(name, passed, message)
    if passed then
        print("✅ " .. name .. " PASSED")
    else
        warn("❌ " .. name .. " FAILED" .. (message and (": " .. message) or ""))
    end
end

-- Run a test and log the result
local function runTest(name, testFn)
    print("Running test: " .. name)
    
    local success, result = pcall(testFn)
    
    if success then
        logTestResult(name, result ~= false, result == false and "Test returned false" or nil)
        return result ~= false
    else
        logTestResult(name, false, tostring(result))
        return false
    end
end

-- Get required module paths
local menuButtonsHandler = nil
local searchPaths = {
    player.PlayerScripts:FindFirstChild("client") and 
    player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and 
    player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild("MenuButtonsHandler.client"),
    
    player.PlayerGui:FindFirstChild("UI") and 
    player.PlayerGui:FindFirstChild("UI"):FindFirstChild("MenuButtonsHandler.client")
}

-- Find MenuButtonsHandler
for _, path in pairs(searchPaths) do
    if path then
        menuButtonsHandler = path
        print("[MenuButtonsTest] Found MenuButtonsHandler at: " .. path:GetFullName())
        break
    end
end

if not menuButtonsHandler then
    warn("❌ MenuButtonsHandler not found, cannot run tests")
    return
end

-- Get MenuButtonsHandler module
local MenuButtonsHandler = safeRequire(menuButtonsHandler)
if not MenuButtonsHandler then
    warn("❌ Failed to load MenuButtonsHandler module")
    return
end

-- Get UIRegistry
local UIRegistry = nil
local uiRegistryPaths = {
    player.PlayerScripts:FindFirstChild("client") and 
    player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and 
    player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild("UIRegistry.client"),
    
    player.PlayerScripts:FindFirstChild("client") and 
    player.PlayerScripts:FindFirstChild("client"):FindFirstChild("Core") and 
    player.PlayerScripts:FindFirstChild("client"):FindFirstChild("Core"):FindFirstChild("UIRegistry"),
    
    ReplicatedStorage:FindFirstChild("shared") and 
    ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("UIRegistry")
}

for _, path in pairs(uiRegistryPaths) do
    if path then
        local tempRegistry = safeRequire(path)
        if tempRegistry then
            UIRegistry = tempRegistry
            print("[MenuButtonsTest] Found UIRegistry at: " .. path:GetFullName())
            break
        end
    end
end

if not UIRegistry then
    warn("⚠️ UIRegistry not found, some tests may fail")
end

-- Define the menu buttons to test
local menuButtons = {
    "Settings",
    "CommunityGoals",
    "Alliance",
    "Challenges",
    "StaffManagement",
    "Upgrades",
    "Achievements",
    "Tutorial",
    "GuestPass"
}

-- Test functions
local function testUIModuleLoading()
    local allModulesFound = true
    local modulesFound = 0
    local totalModules = #menuButtons
    
    for _, buttonName in ipairs(menuButtons) do
        -- Test if we can get the UI module for this button
        local uiModuleName = buttonName .. "UI"
        
        -- First check UIRegistry
        local registryModule = nil
        if UIRegistry and UIRegistry.getComponent then
            registryModule = UIRegistry.getComponent(uiModuleName)
        end
        
        -- Try to find the module directly
        local directModule = nil
        local moduleScript = player.PlayerScripts:FindFirstChild("client") and 
                            player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and 
                            player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild(uiModuleName)
        
        if moduleScript and moduleScript:IsA("ModuleScript") then
            directModule = safeRequire(moduleScript)
        end
        
        -- Check if either method found the module
        local moduleFound = registryModule ~= nil or directModule ~= nil
        
        if moduleFound then
            modulesFound = modulesFound + 1
            print("✅ Found UI module: " .. uiModuleName)
        else
            warn("❌ Could not find UI module: " .. uiModuleName)
            allModulesFound = false
        end
    end
    
    print("[MenuButtonsTest] Found " .. modulesFound .. " of " .. totalModules .. " UI modules")
    return allModulesFound
end

local function testUIModuleInterfaces()
    local allInterfacesValid = true
    local validInterfaces = 0
    local totalModules = #menuButtons
    
    for _, buttonName in ipairs(menuButtons) do
        local uiModuleName = buttonName .. "UI"
        local uiModule = nil
        
        -- Try UIRegistry first
        if UIRegistry and UIRegistry.getComponent then
            uiModule = UIRegistry.getComponent(uiModuleName)
        end
        
        -- If not found in registry, try direct module
        if not uiModule then
            local moduleScript = player.PlayerScripts:FindFirstChild("client") and 
                                player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and 
                                player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild(uiModuleName)
            
            if moduleScript and moduleScript:IsA("ModuleScript") then
                uiModule = safeRequire(moduleScript)
            end
        end
        
        -- Check if module has required interface
        if uiModule then
            local hasToggleUI = typeof(uiModule.ToggleUI) == "function"
            local hasShowUI = typeof(uiModule.ShowUI) == "function"
            local hasHideUI = typeof(uiModule.HideUI) == "function"
            
            -- Module needs at least one of these interfaces
            local validInterface = hasToggleUI or (hasShowUI and hasHideUI)
            
            if validInterface then
                validInterfaces = validInterfaces + 1
                print("✅ Valid interface for: " .. uiModuleName .. " (ToggleUI: " .. tostring(hasToggleUI) .. 
                      ", ShowUI: " .. tostring(hasShowUI) .. ", HideUI: " .. tostring(hasHideUI) .. ")")
            else
                warn("❌ Invalid interface for: " .. uiModuleName .. " (ToggleUI: " .. tostring(hasToggleUI) .. 
                     ", ShowUI: " .. tostring(hasShowUI) .. ", HideUI: " .. tostring(hasHideUI) .. ")")
                allInterfacesValid = false
            end
        else
            warn("❌ Could not test interface for: " .. uiModuleName .. " (module not found)")
            allInterfacesValid = false
        end
    end
    
    print("[MenuButtonsTest] Found " .. validInterfaces .. " of " .. totalModules .. " valid UI interfaces")
    return allInterfacesValid
end

local function testUIModuleRegistration()
    -- Skip if UIRegistry not found
    if not UIRegistry or not UIRegistry.getComponent then
        warn("⚠️ UIRegistry not found or missing getComponent method, skipping registration test")
        return false
    end
    
    local allModulesRegistered = true
    local modulesRegistered = 0
    local totalModules = #menuButtons
    
    for _, buttonName in ipairs(menuButtons) do
        local uiModuleName = buttonName .. "UI"
        local registeredModule = UIRegistry.getComponent(uiModuleName)
        
        if registeredModule then
            modulesRegistered = modulesRegistered + 1
            print("✅ Module registered with UIRegistry: " .. uiModuleName)
        else
            warn("❌ Module not registered with UIRegistry: " .. uiModuleName)
            allModulesRegistered = false
        end
    end
    
    print("[MenuButtonsTest] Found " .. modulesRegistered .. " of " .. totalModules .. " modules registered with UIRegistry")
    return allModulesRegistered
end

local function testButtonUIToggle()
    -- This test can't directly click the buttons, but we can check if the toggle functions work
    local allToggleTests = true
    local successfulToggles = 0
    local totalButtons = #menuButtons
    
    for _, buttonName in ipairs(menuButtons) do
        local uiModuleName = buttonName .. "UI"
        local uiModule = nil
        
        -- Try UIRegistry first
        if UIRegistry and UIRegistry.getComponent then
            uiModule = UIRegistry.getComponent(uiModuleName)
        end
        
        -- If not found in registry, try direct module
        if not uiModule then
            local moduleScript = player.PlayerScripts:FindFirstChild("client") and 
                                player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and 
                                player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild(uiModuleName)
            
            if moduleScript and moduleScript:IsA("ModuleScript") then
                uiModule = safeRequire(moduleScript)
            end
        end
        
        if uiModule then
            -- See if we can toggle the UI
            local toggleSuccess = false
            
            if typeof(uiModule.ToggleUI) == "function" then
                local success = pcall(function()
                    uiModule.ToggleUI()
                    -- Give it a moment to toggle on
                    task.wait(0.1)
                    -- Toggle it back off
                    uiModule.ToggleUI()
                end)
                toggleSuccess = success
            elseif typeof(uiModule.ShowUI) == "function" and typeof(uiModule.HideUI) == "function" then
                local success = pcall(function()
                    uiModule.ShowUI()
                    -- Give it a moment to show
                    task.wait(0.1)
                    -- Hide it
                    uiModule.HideUI()
                end)
                toggleSuccess = success
            end
            
            if toggleSuccess then
                successfulToggles = successfulToggles + 1
                print("✅ Successfully toggled UI for: " .. uiModuleName)
            else
                warn("❌ Failed to toggle UI for: " .. uiModuleName)
                allToggleTests = false
            end
        else
            warn("❌ Could not test toggle for: " .. uiModuleName .. " (module not found)")
            allToggleTests = false
        end
    end
    
    print("[MenuButtonsTest] Successfully toggled " .. successfulToggles .. " of " .. totalButtons .. " UIs")
    return allToggleTests
end

-- Run all tests
local testResults = {}

testResults.UIModuleLoading = runTest("UI Module Loading", testUIModuleLoading)
testResults.UIModuleInterfaces = runTest("UI Module Interfaces", testUIModuleInterfaces)
testResults.UIModuleRegistration = runTest("UI Module Registration", testUIModuleRegistration)
testResults.ButtonUIToggle = runTest("Button UI Toggle", testButtonUIToggle)

-- Calculate overall results
local totalTests = 0
local passedTests = 0
for _, passed in pairs(testResults) do
    totalTests = totalTests + 1
    if passed then
        passedTests = passedTests + 1
    end
end

local passRate = math.floor((passedTests / totalTests) * 100)
print("\n==== MENU BUTTONS TEST SUMMARY ====")
print("Tests Run: " .. totalTests)
print("Tests Passed: " .. passedTests)
print("Tests Failed: " .. (totalTests - passedTests))
print("Pass Rate: " .. passRate .. "%")

if passRate == 100 then
    print("🎉 All menu button tests PASSED! 🎉")
elseif passRate >= 75 then
    print("👍 Most menu button tests PASSED with some issues to resolve")
else
    print("⚠️ Several menu button tests FAILED, need more work")
end

print("==== MENU BUTTONS TEST COMPLETE ====\n")

return {
    results = testResults,
    passRate = passRate
}
