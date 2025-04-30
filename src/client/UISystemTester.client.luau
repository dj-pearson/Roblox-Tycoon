--[[
    UISystemTester.client.luau
    
    Tests the functionality of UI System components on the client.
    This script validates that all critical UI systems are available and functioning.
    
    Created: April 30, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Only run in client
if not RunService:IsClient() then
    return
end

-- Wait for the player to fully load
if not Players.LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

local player = Players.LocalPlayer
while not player:IsDescendantOf(game) or not player.Character do
    task.wait(0.1)
end

print("\n==== RUNNING UI SYSTEM CLIENT TESTER ====")
print("Testing critical UI systems...")

-- Helper functions
local function findModule(name, paths)
    for _, path in ipairs(paths) do
        if path then
            local module = path:FindFirstChild(name)
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Try with extensions
            local extensions = {".luau", ".client.luau", ".lua"}
            for _, ext in ipairs(extensions) do
                module = path:FindFirstChild(name .. ext)
                if module and module:IsA("ModuleScript") then
                    return module
                end
            end
        end
    end
    
    return nil
end

local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[UISystemTester] Failed to require: " .. tostring(module:GetFullName()) .. " - " .. tostring(result))
        return nil
    end
end

-- Try to get ModuleScriptAccessor
local function getModuleScriptAccessor()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        return safeRequire(shared.ModuleScriptAccessor)
    end
    return nil
end

-- Get a system from ModuleScriptAccessor if available
local function getSystem(systemName)
    local ModuleScriptAccessor = getModuleScriptAccessor()
    if ModuleScriptAccessor then
        return ModuleScriptAccessor.getSystem(systemName)
    end
    return nil
end

-- Check if UI registry is available
local UIRegistry = getSystem("UIRegistry")
if not UIRegistry then
    -- Try direct paths
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("shared"),
        player:FindFirstChild("PlayerScripts"),
        player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client") and player.PlayerScripts.src.client:FindFirstChild("Core")
    }
    
    local uiRegistryModule = findModule("UIRegistry", searchPaths)
    if uiRegistryModule then
        UIRegistry = safeRequire(uiRegistryModule)
    end
end

if UIRegistry then
    print("[UISystemTester] ✅ UIRegistry found")
    
    -- Test if UIRegistry can be initialized
    if UIRegistry.initialize then
        local success = UIRegistry.initialize()
        if success then
            print("[UISystemTester] ✅ UIRegistry initialized successfully")
        else
            warn("[UISystemTester] ❌ UIRegistry initialization failed")
        end
    end
    
    -- Test button factory
    if UIRegistry.ButtonFactory then
        print("[UISystemTester] ✅ ButtonFactory available")
        
        -- Create a test button
        local testButton = UIRegistry.ButtonFactory.createStyledButton("primary", {
            Text = "Test Button",
            Position = UDim2.new(0.5, -100, 0.8, -25),
            Size = UDim2.new(0, 200, 0, 50),
            Parent = player:FindFirstChild("PlayerGui"),
            Callback = function()
                print("Test button clicked!")
                UIRegistry.DialogFactory.showNotification("Button Test", "The button was clicked successfully!", "success", 3)
            end
        })
        
        if testButton then
            print("[UISystemTester] ✅ Test button created successfully")
            
            -- Create a container for the button if needed
            if not testButton.Parent then
                local screenGui = Instance.new("ScreenGui")
                screenGui.Name = "UISystemTesterGui"
                screenGui.ResetOnSpawn = false
                screenGui.Parent = player.PlayerGui
                testButton.Parent = screenGui
                
                print("[UISystemTester] Created ScreenGui container for test UI elements")
            end
        else
            warn("[UISystemTester] ❌ Failed to create test button")
        end
    else
        warn("[UISystemTester] ❌ ButtonFactory not available")
    end
    
    -- Test dialog factory
    if UIRegistry.DialogFactory then
        print("[UISystemTester] ✅ DialogFactory available")
        
        -- Show a test notification
        local testNotification = UIRegistry.DialogFactory.showNotification(
            "UI System Test", 
            "UI components are working correctly!",
            "info",
            5
        )
        
        if testNotification then
            print("[UISystemTester] ✅ Test notification created successfully")
        else
            warn("[UISystemTester] ❌ Failed to create test notification")
        end
    else
        warn("[UISystemTester] ❌ DialogFactory not available")
    end
      -- Test UI styling
    if UIRegistry.UIStyle then
        print("[UISystemTester] ✅ UIStyle utilities available")
        
        -- Get color names
        local colorNames = {}
        for name, _ in pairs(UIRegistry.UIStyle.COLORS) do
            table.insert(colorNames, name)
        end
        print("[UISystemTester] Available colors:", table.concat(colorNames, ", "))
    else
        warn("[UISystemTester] ❌ UIStyle utilities not available")
    end
    
    -- Test icon set
    if UIRegistry.IconSet then
        print("[UISystemTester] ✅ IconSet available")
        
        -- Get icon names
        local iconNames = {}
        for name, value in pairs(UIRegistry.IconSet) do
            if type(value) ~= "function" then
                table.insert(iconNames, name)
            end
        end
        print("[UISystemTester] Available icons:", table.concat(iconNames, ", "))
        -- Create a test icon
        local screenGui = player.PlayerGui:FindFirstChild("UISystemTesterGui")
        if not screenGui then
            screenGui = Instance.new("ScreenGui")
            screenGui.Name = "UISystemTesterGui"
            screenGui.ResetOnSpawn = false
            screenGui.Parent = player.PlayerGui
        end
        
        local testIcon = Instance.new("ImageLabel")
        testIcon.Size = UDim2.new(0, 32, 0, 32)
        testIcon.Position = UDim2.new(0.5, -16, 0.7, -16)
        testIcon.BackgroundTransparency = 1
        testIcon.Image = UIRegistry.IconSet.SUCCESS
        testIcon.Name = "TestIcon"
        testIcon.Parent = screenGui
        
        print("[UISystemTester] ✅ Created test icon successfully")
    else
        warn("[UISystemTester] ❌ IconSet not available")
    end
else
    warn("[UISystemTester] ❌ UIRegistry not found!")
end

-- Check for other critical UI components
local criticalUIComponents = {
    "UIComponents",
    "AssetValidator",
    "DialogFactory",
    "NotificationSystem"
}

for _, componentName in ipairs(criticalUIComponents) do
    local component = getSystem(componentName)
    if component then
        print("[UISystemTester] ✅ " .. componentName .. " found")
    else
        warn("[UISystemTester] ❌ " .. componentName .. " not found")
    end
end

-- Create a cleanup button
local screenGui = player.PlayerGui:FindFirstChild("UISystemTesterGui")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UISystemTesterGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player.PlayerGui
end

local cleanupButton = Instance.new("TextButton")
cleanupButton.Size = UDim2.new(0, 120, 0, 30)
cleanupButton.Position = UDim2.new(0.5, -60, 0.9, -15)
cleanupButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
cleanupButton.Font = Enum.Font.SourceSansSemibold
cleanupButton.TextColor3 = Color3.fromRGB(255, 255, 255)
cleanupButton.TextSize = 14
cleanupButton.Text = "Clean Up Test UI"
cleanupButton.Parent = screenGui

-- Add corner radius
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = cleanupButton

-- Cleanup function
cleanupButton.MouseButton1Click:Connect(function()
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
        print("[UISystemTester] Test UI elements cleaned up")
    end
end)

print("[UISystemTester] UI System test completed")
print("[UISystemTester] You can clean up the test UI elements by clicking the red button at the bottom of the screen\n")
