--[[
    ClientUI_FixTest.client.luau
    
    Tests the Client UI System to verify that all fixes have been properly applied.
    Runs a suite of tests to check that all components are available, accessible,
    and functioning correctly.
    
    Created: May 1, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

if not player then
    warn("[ClientUI_FixTest] No LocalPlayer found, waiting...")
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

print("\n==== RUNNING CLIENT UI FIX VERIFICATION TESTS ====")

-- Define test suite
local tests = {
    total = 0,
    passed = 0,
    failed = 0
}

-- Run a test
local function runTest(name, testFunc)
    tests.total += 1
    print("Running test: " .. name)
    
    local success, result = pcall(testFunc)
    
    if success and result then
        tests.passed += 1
        print("✅ " .. name .. " PASSED")
        return true
    else
        tests.failed += 1
        local errorMsg = (type(result) == "string" and result ~= "") and (": " .. result) or ""
        warn("❌ " .. name .. " FAILED" .. errorMsg)
        return false
    end
end

-- Helper function to find a module
local function findModule(name)
    -- Try ModuleScriptAccessor first
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local success, moduleAccessor = pcall(function()
            return require(shared.ModuleScriptAccessor)
        end)
        
        if success and moduleAccessor and typeof(moduleAccessor.getModule) == "function" then
            local module = moduleAccessor.getModule(name)
            if module then
                return module
            end
        end
    end
    
    -- Try direct paths
    local searchPaths = {
        player.PlayerScripts:FindFirstChild("Client") and player.PlayerScripts.Client:FindFirstChild("Core"),
        player.PlayerScripts:FindFirstChild("Core"),
        shared,
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared")
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(name)
            if module and module:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(module)
                end)
                
                if success then
                    return result
                end
            end
        end
    end
    
    return nil
end

-- T1: ClientRegistryPreloader exists
runTest("ClientRegistryPreloader Exists", function()
    local clientScripts = player.PlayerScripts
    if not clientScripts:FindFirstChild("ClientRegistryPreloader") and
       not clientScripts:FindFirstChild("ClientRegistryPreloader.client.luau") then
        return false, "ClientRegistryPreloader not found in PlayerScripts"
    end
    return true
end)

-- T2: ClientRegistry exists and is initialized
runTest("ClientRegistry Initialized", function()
    local clientRegistry = findModule("ClientRegistry")
    if not clientRegistry then
        return false, "ClientRegistry module not found"
    end
    
    if not clientRegistry.Initialized and not clientRegistry.initialized then
        return false, "ClientRegistry is not initialized"
    end
    
    return true
end)

-- T3: UIComponents exists and is initialized
runTest("UIComponents Initialized", function()
    local uiComponents = findModule("UIComponents")
    if not uiComponents then
        return false, "UIComponents module not found"
    end
    
    if not uiComponents.Initialized and not uiComponents.initialized then
        return false, "UIComponents is not initialized"
    end
    
    -- Check if it has critical methods
    if typeof(uiComponents.createButton) ~= "function" and
       typeof(uiComponents.CreateButton) ~= "function" and
       typeof(uiComponents.createFrame) ~= "function" and
       typeof(uiComponents.CreateFrame) ~= "function" then
        return false, "UIComponents missing critical UI creation methods"
    end
    
    return true
end)

-- T4: AssetValidator exists and is initialized
runTest("AssetValidator Initialized", function()
    local assetValidator = findModule("AssetValidator")
    if not assetValidator then
        return false, "AssetValidator module not found"
    end
    
    if not assetValidator.Initialized and not assetValidator.initialized then
        return false, "AssetValidator is not initialized"
    end
    
    -- Check if it has critical methods
    if typeof(assetValidator.validateAsset) ~= "function" and
       typeof(assetValidator.ValidateAsset) ~= "function" then
        return false, "AssetValidator missing critical validation methods"
    end
    
    return true
end)

-- T5: UIRegistry exists and is initialized
runTest("UIRegistry Initialized", function()
    local uiRegistry = findModule("UIRegistry")
    if not uiRegistry then
        return false, "UIRegistry module not found"
    end
    
    if not uiRegistry.Initialized and not uiRegistry.initialized then
        return false, "UIRegistry is not initialized"
    end
    
    -- Check if it has critical factories
    if not uiRegistry.ButtonFactory and not uiRegistry.buttonFactory then
        return false, "UIRegistry missing ButtonFactory"
    end
    
    if not uiRegistry.DialogFactory and not uiRegistry.dialogFactory then
        return false, "UIRegistry missing DialogFactory"
    end
    
    return true
end)

-- T6: ModuleScriptAccessor exists and works
runTest("ModuleScriptAccessor Works", function()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared or not shared:FindFirstChild("ModuleScriptAccessor") then
        return false, "ModuleScriptAccessor not found in shared folder"
    end
    
    local success, moduleAccessor = pcall(function()
        return require(shared.ModuleScriptAccessor)
    end)
    
    if not success or not moduleAccessor then
        return false, "Failed to require ModuleScriptAccessor: " .. tostring(moduleAccessor)
    end
    
    -- Check if it has critical methods
    if typeof(moduleAccessor.getModule) ~= "function" or 
       typeof(moduleAccessor.getSystem) ~= "function" or
       typeof(moduleAccessor.getClientRegistry) ~= "function" then
        return false, "ModuleScriptAccessor missing critical methods"
    end
    
    -- Test if it can actually find a module
    local clientRegistry = moduleAccessor.getClientRegistry()
    if not clientRegistry then
        return false, "ModuleScriptAccessor could not find ClientRegistry"
    end
    
    return true
end)

-- T7: ClientBootstrap integration
runTest("ClientBootstrap Integration", function()
    local clientBootstrap = findModule("ClientBootstrap")
    if not clientBootstrap then
        return false, "ClientBootstrap module not found"
    end
    
    -- Check if it's reporting initialized state
    if typeof(clientBootstrap.isInitialized) == "function" and not clientBootstrap.isInitialized() then
        return false, "ClientBootstrap reports it is not initialized"
    end
    
    -- Check status if available
    if typeof(clientBootstrap.getStatus) == "function" then
        local status = clientBootstrap.getStatus()
        if status == "Error" then
            return false, "ClientBootstrap reporting Error status"
        end
    end
    
    return true
end)

-- T8: ClientUISystem integration
runTest("ClientUISystem Integration", function()
    local clientUISystem = findModule("ClientUISystem")
    if not clientUISystem then
        return false, "ClientUISystem module not found"
    end
    
    -- Check if it's initialized
    if not clientUISystem.initialized then
        return false, "ClientUISystem is not initialized"
    end
    
    -- Check if it has registered modules
    if not clientUISystem.modules or not clientUISystem.modules.ClientRegistry then
        return false, "ClientUISystem has not registered ClientRegistry"
    end
    
    return true
end)

-- T9: UI Component Creation Test
runTest("UI Component Creation", function()
    local uiComponents = findModule("UIComponents")
    if not uiComponents then
        return false, "UIComponents module not found"
    end
    
    -- Try to create a button
    local createButtonFunc = uiComponents.createButton or uiComponents.CreateButton
    if typeof(createButtonFunc) ~= "function" then
        return false, "UIComponents missing button creation function"
    end
    
    local success, button = pcall(function()
        return createButtonFunc(uiComponents, "Test Button")
    end)
    
    if not success or not button or not button:IsA("GuiObject") then
        return false, "Failed to create button: " .. tostring(button)
    end
    
    -- Try to create a frame
    local createFrameFunc = uiComponents.createFrame or uiComponents.CreateFrame
    if typeof(createFrameFunc) ~= "function" then
        return false, "UIComponents missing frame creation function"
    end
    
    local success, frame = pcall(function()
        return createFrameFunc(uiComponents)
    end)
    
    if not success or not frame or not frame:IsA("GuiObject") then
        return false, "Failed to create frame: " .. tostring(frame)
    end
    
    return true
end)

-- T10: UI Registry Integration
runTest("UIRegistry Component Registration", function()
    local moduleAccessor = findModule("ModuleScriptAccessor")
    if not moduleAccessor then
        return false, "ModuleScriptAccessor not found"
    end
    
    local clientRegistry = moduleAccessor.getClientRegistry()
    if not clientRegistry then
        return false, "ClientRegistry not found via ModuleScriptAccessor"
    end
    
    -- Check for UIRegistry in ClientRegistry
    local uiRegistry = nil
    if typeof(clientRegistry.getUIComponent) == "function" then
        uiRegistry = clientRegistry:getUIComponent("UIRegistry")
    elseif typeof(clientRegistry.getSystem) == "function" then
        uiRegistry = clientRegistry:getSystem("UIRegistry")
    end
    
    if not uiRegistry then
        return false, "UIRegistry not registered with ClientRegistry"
    end
    
    -- Check if UI Registry has required methods
    if typeof(uiRegistry.registerComponent) ~= "function" then
        return false, "UIRegistry missing registerComponent method"
    end
    
    -- Register a test component
    local success = pcall(function()
        uiRegistry:registerComponent("TestComponent", {
            name = "TestComponent",
            version = "1.0.0"
        })
    end)
    
    if not success then
        return false, "Failed to register component with UIRegistry"
    end
    
    -- Verify component was registered
    local component = nil
    if typeof(uiRegistry.getComponent) == "function" then
        component = uiRegistry:getComponent("TestComponent")
    end
    
    if not component or component.name ~= "TestComponent" then
        return false, "Failed to retrieve registered component from UIRegistry"
    end
    
    return true
end)

-- T11: Integration with CoreRegistry
runTest("CoreRegistry Integration", function()
    local moduleAccessor = findModule("ModuleScriptAccessor")
    if not moduleAccessor then
        return false, "ModuleScriptAccessor not found"
    end
    
    local coreRegistry = moduleAccessor.getCoreRegistry()
    if not coreRegistry then
        return false, "CoreRegistry not found via ModuleScriptAccessor"
    end
    
    -- Check if ClientRegistry is registered with CoreRegistry
    local hasClientRegistry = false
    if typeof(coreRegistry.hasSystem) == "function" then
        hasClientRegistry = coreRegistry.hasSystem("ClientRegistry")
    else
        -- Check if systems table is accessible
        if coreRegistry.systems and coreRegistry.systems.ClientRegistry then
            hasClientRegistry = true
        end
    end
    
    if not hasClientRegistry then
        return false, "ClientRegistry not registered with CoreRegistry"
    end
    
    return true
end)

-- Print test results
local passRate = math.floor((tests.passed / tests.total) * 100)
print("\n[ClientUI_FixTest] Test Results:")
print("Tests Run: " .. tests.total)
print("Tests Passed: " .. tests.passed)
print("Tests Failed: " .. tests.failed)
print("Pass Rate: " .. passRate .. "%")

-- Show notification with test results if possible
local moduleAccessor = findModule("ModuleScriptAccessor")
if moduleAccessor then
    local uiRegistry = moduleAccessor.getSystem("UIRegistry")
    if uiRegistry and uiRegistry.DialogFactory and typeof(uiRegistry.DialogFactory.showNotification) == "function" then
        uiRegistry.DialogFactory.showNotification(
            "Client UI Fix Verification",
            "Tests: " .. tests.passed .. "/" .. tests.total .. " (" .. passRate .. "%)",
            passRate >= 90 and "success" or (passRate >= 50 and "warning" or "error"),
            10
        )
    end
end

print("==== CLIENT UI FIX VERIFICATION TESTS COMPLETE ====\n")
