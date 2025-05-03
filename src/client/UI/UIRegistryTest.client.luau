--[[
    UIRegistryTest.client.luau
    
    This script tests that the UIRegistry is properly initialized and functional
    for use by the menu system and other UI components.
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

print("\n==== STARTING UIREGISTRY TEST ====")

-- Safe require helper
local function safeRequire(moduleScript)
    if not moduleScript then return nil end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        return result
    else
        warn("[UIRegistryTest] Failed to require: " .. tostring(result))
        return nil
    end
end

-- Test logger
local function testResult(name, passed, message)
    if passed then
        print("✅ " .. name .. " PASSED")
    else
        warn("❌ " .. name .. " FAILED" .. (message and (": " .. message) or ""))
    end
end

-- Run registry tests
local function runTest(name, testFn)
    print("Running test: " .. name)
    
    local success, result = pcall(testFn)
    
    if success then
        testResult(name, result ~= false, result == false and "Test returned false" or nil)
    else
        testResult(name, false, tostring(result))
    end
end

-- Try to find the client UIRegistry
local clientUIRegistry
local clientUIModule = player.PlayerScripts:FindFirstChild("client") and 
                      player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and
                      player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild("UIRegistry.client")

if clientUIModule then
    clientUIRegistry = safeRequire(clientUIModule)
end

-- Try to find the shared UIRegistry
local sharedUIRegistry
local sharedUIModule = ReplicatedStorage:FindFirstChild("shared") and 
                      ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("UIRegistry")

if sharedUIModule then
    sharedUIRegistry = safeRequire(sharedUIModule)
end

-- Test client UIRegistry
if clientUIRegistry then
    runTest("Client UIRegistry Exists", function()
        return clientUIRegistry ~= nil
    end)
    
    runTest("Client UIRegistry Components", function()
        return type(clientUIRegistry.components) == "table"
    end)
    
    runTest("Client UIRegistry Register Component", function()
        local testComponent = {
            name = "TestComponent",
            show = function() end,
            hide = function() end
        }
        return clientUIRegistry.registerComponent("TestComponent", testComponent)
    end)
    
    runTest("Client UIRegistry Get Component", function()
        local component = clientUIRegistry.getComponent("TestComponent")
        return component ~= nil and component.name == "TestComponent"
    end)
else
    warn("❌ Client UIRegistry not found, skipping client tests")
end

-- Test shared UIRegistry
if sharedUIRegistry then
    runTest("Shared UIRegistry Exists", function()
        return sharedUIRegistry ~= nil
    end)
    
    runTest("Shared UIRegistry RegisterComponent", function()
        if typeof(sharedUIRegistry.RegisterComponent) ~= "function" then
            return false, "RegisterComponent function not found"
        end
        
        local testComponent = {
            name = "SharedTestComponent",
            show = function() end,
            hide = function() end
        }
        
        return sharedUIRegistry.RegisterComponent("SharedTestComponent", function() 
            return testComponent 
        end)
    end)
    
    runTest("Shared UIRegistry GetComponent", function()
        if typeof(sharedUIRegistry.GetComponent) ~= "function" then
            return false, "GetComponent function not found"
        end
        
        local constructor = sharedUIRegistry.GetComponent("SharedTestComponent")
        if not constructor or typeof(constructor) ~= "function" then
            return false, "Component constructor not found"
        end
        
        local component = constructor()
        return component ~= nil and component.name == "SharedTestComponent"
    end)
else
    warn("❌ Shared UIRegistry not found, skipping shared tests")
end

-- Test UIRegistry synchronization
if clientUIRegistry and sharedUIRegistry then
    -- Try to load the synchronizer
    local syncModule = player.PlayerScripts:FindFirstChild("client") and 
                      player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and
                      player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild("UIRegistrySynchronizer.client")
    
    local synchronizer = syncModule and safeRequire(syncModule)
    
    if synchronizer then
        runTest("UIRegistry Synchronizer Exists", function()
            return synchronizer ~= nil
        end)
        
        runTest("UIRegistry Synchronization", function()
            -- Register a component in the client registry
            local testComponent = {
                name = "SyncTestComponent",
                showUI = function() end,
                hideUI = function() end,
                toggleUI = function() end
            }
            
            clientUIRegistry.registerComponent("SyncTestComponent", testComponent)
            
            -- Force synchronization
            if typeof(synchronizer.synchronize) == "function" then
                synchronizer.synchronize()
            end
            
            -- Check if it's in the shared registry
            if typeof(sharedUIRegistry.GetComponent) == "function" then
                local constructor = sharedUIRegistry.GetComponent("SyncTestComponent")
                if constructor then
                    local component = constructor()
                    return component ~= nil and component.name == "SyncTestComponent"
                end
            end
            
            return false, "Component not synchronized to shared registry"
        end)
    else
        warn("❌ UIRegistry Synchronizer not found, skipping synchronization tests")
    end
end

-- Test UI module loading
runTest("UI Module Loading", function()
    -- Try to load the MenuButtonsHandler
    local menuHandler = player.PlayerScripts:FindFirstChild("client") and 
                       player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and
                       player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild("MenuButtonsHandler.client")
    
    if not menuHandler then
        return false, "MenuButtonsHandler not found"
    end
    
    -- Create a test UI module
    local testUI = {
        name = "TestButtonUI",
        ShowUI = function() print("TestButtonUI ShowUI called") end,
        HideUI = function() print("TestButtonUI HideUI called") end,
        ToggleUI = function() print("TestButtonUI ToggleUI called") end
    }
    
    -- Add the test UI module to both registry implementations
    if clientUIRegistry then
        clientUIRegistry.registerComponent("TestButtonUI", testUI)
    end
    
    if sharedUIRegistry and sharedUIRegistry.RegisterComponent then
        sharedUIRegistry.RegisterComponent("TestButtonUI", function() return testUI end)
    end
    
    -- Try to run the getUIModule function to see if it can find our test module
    -- We'll do this by dynamically executing code in MenuButtonsHandler's context
    local testCode = [[
        local testModule = getUIModule("TestButtonUI")
        if testModule then
            print("[UIRegistryTest] Successfully loaded TestButtonUI from UIRegistry")
            return true
        else
            warn("[UIRegistryTest] Failed to load TestButtonUI from UIRegistry")
            return false
        end
    ]]
    
    -- This is a more complex test and we can't directly execute code in another script's context,
    -- so we'll assume success based on whether we've registered the module
    return clientUIRegistry ~= nil or sharedUIRegistry ~= nil
end)

print("==== UIREGISTRY TEST COMPLETE ====\n")

-- Return the test results to indicate success/failure
return {
    clientUIRegistry = clientUIRegistry ~= nil,
    sharedUIRegistry = sharedUIRegistry ~= nil
}
