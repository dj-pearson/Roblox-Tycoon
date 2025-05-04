--[[
    UISystemFixVerifier.client.luau
    
    This script verifies that the UISystemFixer successfully fixed the UI system issues.
    It checks for the existence and functionality of all required UI components.
    
    Created: May 4, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Only run on the client
if not RunService:IsClient() then
    return
end

-- Helper function for logging
local function log(message, isError)
    if isError then
        warn("[UISystemFixVerifier] " .. message)
    else
        print("[UISystemFixVerifier] " .. message)
    end
end

-- Wait for the player to be available
local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

-- Create a delay to ensure UISystemFixer has run
task.wait(2)

log("Starting UI System verification...")

-- Find ClientRegistry
local function findClientRegistry()
    -- Search paths
    local searchPaths = {
        player:FindFirstChild("PlayerScripts"),
        player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client"),
        player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client") and player.PlayerScripts.src.client:FindFirstChild("Core"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared")
    }
    
    -- Try direct approach
    for _, path in ipairs(searchPaths) do
        if path then
            local clientRegistryModule = path:FindFirstChild("ClientRegistry")
            if clientRegistryModule and clientRegistryModule:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(clientRegistryModule)
                end)
                
                if success and typeof(result) == "table" and typeof(result.getSystem) == "function" then
                    log("Found ClientRegistry at: " .. clientRegistryModule:GetFullName())
                    return result
                end
            end
            
            -- Try with extensions
            for _, ext in ipairs({".luau", ".client.luau", ".lua"}) do
                local moduleName = "ClientRegistry" .. ext
                local module = path:FindFirstChild(moduleName)
                if module and module:IsA("ModuleScript") then
                    local success, result = pcall(function()
                        return require(module)
                    end)
                    
                    if success and typeof(result) == "table" and typeof(result.getSystem) == "function" then
                        log("Found ClientRegistry at: " .. module:GetFullName())
                        return result
                    end
                end
            end
        end
    end
    
    log("Could not find ClientRegistry", true)
    return nil
end

-- Get ClientRegistry
local ClientRegistry = findClientRegistry()
if not ClientRegistry then
    log("ClientRegistry not found, verification cannot proceed", true)
    return
end

-- List of required UI components to verify
local requiredUIComponents = {
    "UISystem",
    "UISystemPatcher",
    "MenuButtonCreator",
    "GymTycoonMenuUI",
    "AdminButtonCreator",
    "UISystemEnhancer"
}

-- Verify each UI component
local results = {
    pass = 0,
    fail = 0,
    placeholder = 0,
    details = {}
}

for _, componentName in ipairs(requiredUIComponents) do
    log("Verifying component: " .. componentName)
    
    -- Check if component exists in ClientRegistry
    local component = ClientRegistry:getSystem(componentName)
    
    if not component then
        log("Component not found: " .. componentName, true)
        results.fail += 1
        results.details[componentName] = {
            status = "Missing",
            isPlaceholder = false,
            message = "Component not registered with ClientRegistry"
        }
        continue
    end
    
    -- Check if it's a placeholder
    if component._isPlaceholder then
        log("Component is a placeholder: " .. componentName)
        results.placeholder += 1
        results.details[componentName] = {
            status = "Placeholder",
            isPlaceholder = true,
            message = "Using placeholder implementation"
        }
        continue
    end
    
    -- Component exists and is not a placeholder
    log("Component exists and is not a placeholder: " .. componentName)
    results.pass += 1
    results.details[componentName] = {
        status = "Success",
        isPlaceholder = false,
        message = "Component properly registered and loaded"
    }
end

-- Test UI functionality
local function testUIFunctionality()
    log("Testing UI functionality...")
    
    -- Test UISystem showUI functionality if available
    local UISystem = ClientRegistry:getSystem("UISystem")
    if UISystem and typeof(UISystem.showUI) == "function" then
        local success, result = pcall(function()
            return UISystem:showUI("MainMenu")
        end)
        
        if success then
            log("UISystem.showUI('MainMenu') executed successfully")
            
            -- Hide after testing
            task.delay(0.5, function()
                UISystem:hideUI("MainMenu")
            end)
        else
            log("UISystem.showUI('MainMenu') failed: " .. tostring(result), true)
        end
    end
    
    -- Test MenuButtonCreator functionality if available
    local MenuButtonCreator = ClientRegistry:getSystem("MenuButtonCreator")
    if MenuButtonCreator and typeof(MenuButtonCreator.createButton) == "function" then
        local success, result = pcall(function()
            return MenuButtonCreator:createButton({
                text = "Test Button",
                position = UDim2.new(0.5, 0, 0.9, 0)
            })
        end)
        
        if success then
            log("MenuButtonCreator.createButton executed successfully")
            
            -- Remove test button after a delay
            if result and typeof(result.Destroy) == "function" then
                task.delay(1, function()
                    result:Destroy()
                end)
            end
        else
            log("MenuButtonCreator.createButton failed: " .. tostring(result), true)
        end
    end
end

-- Run functionality test if most components passed
if results.pass + results.placeholder > results.fail then
    task.spawn(testUIFunctionality)
end

-- Generate verification summary
log("\n=== UI System Verification Summary ===")
log("Pass: " .. results.pass .. "/" .. #requiredUIComponents)
log("Placeholder: " .. results.placeholder .. "/" .. #requiredUIComponents)
log("Fail: " .. results.fail .. "/" .. #requiredUIComponents)

log("\nComponent Details:")
for component, detail in pairs(results.details) do
    log(component .. ": " .. detail.status .. " - " .. detail.message)
end

-- Create a visible notification for the player about the status
task.delay(1, function()
    -- Try to use UISystem to show notification
    local UISystem = ClientRegistry:getSystem("UISystem")
    if UISystem and typeof(UISystem.showNotification) == "function" then
        UISystem:showNotification(
            "UI System Verification", 
            "Pass: " .. results.pass .. ", Placeholder: " .. results.placeholder .. ", Fail: " .. results.fail,
            results.fail == 0 and "success" or (results.placeholder > 0 and "warning" or "error"),
            5
        )
    else
        -- Try alternative notification method with DialogFactory
        local DialogFactory = ClientRegistry:getSystem("DialogFactory")
        if DialogFactory and typeof(DialogFactory.showNotification) == "function" then
            DialogFactory:showNotification(
                "UI System Verification", 
                "Pass: " .. results.pass .. ", Placeholder: " .. results.placeholder .. ", Fail: " .. results.fail,
                results.fail == 0 and "success" or (results.placeholder > 0 and "warning" or "error"),
                5
            )
        end
    end
end)

-- Set global verification results
_G.UISystemVerificationResults = results

return results
