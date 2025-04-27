--[[
    ConfigurationExample.server.luau
    Shows how to use the new configuration system (Phase 6: Task 1)
]]

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Only run this in Studio
if not RunService:IsStudio() then
    return
end

-- Get reference to our modules through CoreRegistry or direct require
local CoreRegistry = nil
local systemFolder = ServerScriptService:FindFirstChild("Systems") or ServerScriptService:FindFirstChild("Core") or ServerScriptService

for _, folder in ipairs(systemFolder:GetDescendants()) do
    if folder:IsA("ModuleScript") and folder.Name == "CoreRegistry" then
        CoreRegistry = require(folder)
        break
    end
end

-- Get our modules
local TycoonConfigurationManager = CoreRegistry and CoreRegistry:GetSystem("TycoonConfigurationManager")
local ConfigurationIntegration = CoreRegistry and CoreRegistry:GetSystem("ConfigurationIntegration")
local GymAutomation = CoreRegistry and CoreRegistry:GetSystem("GymAutomation")

-- If not available through registry, try to load directly
if not TycoonConfigurationManager then
    local success, result = pcall(function()
        return require(script.Parent.Core.TycoonConfigurationManager)
    end)
    
    if success then
        TycoonConfigurationManager = result
        -- Initialize the module
        TycoonConfigurationManager.init()
        print("TycoonConfigurationManager loaded directly")
    else
        warn("Failed to load TycoonConfigurationManager:", result)
    end
end

if not ConfigurationIntegration then
    local success, result = pcall(function()
        return require(script.Parent.Core.ConfigurationIntegration) 
    end)
    
    if success then
        ConfigurationIntegration = result
        print("ConfigurationIntegration loaded directly")
    else
        warn("Failed to load ConfigurationIntegration:", result)
    end
end

if not GymAutomation then
    local success, result = pcall(function()
        return require(script.Parent.Core.GymAutomation)
    end)
    
    if success then
        GymAutomation = result
        print("GymAutomation loaded directly")
    else
        warn("Failed to load GymAutomation:", result)
    end
end

-- Make sure we have the required modules
if not (TycoonConfigurationManager and ConfigurationIntegration) then
    warn("Required modules not available. Example cannot run.")
    return
end

-- Example function to create a custom configuration
local function CreateCustomConfig()
    print("\n=== Creating Custom Configuration ===")
    
    -- Create a new configuration manager
    local configManager = TycoonConfigurationManager.new("LuxuryGymConfig")
    
    -- Set economy parameters
    configManager:SetSetting("tycoonType", "Gym")
    configManager:SetSetting("settings.economyMultiplier", 1.5)
    configManager:SetSetting("settings.progressionSpeed", 1.2)
    configManager:SetSetting("settings.maxFloors", 4)
    
    -- Define room types for luxury gym
    configManager:SetSetting("roomTypes", {
        {name = "Cardio", color = Color3.fromRGB(255, 200, 200)},
        {name = "Weights", color = Color3.fromRGB(200, 200, 255)},
        {name = "Specialized", color = Color3.fromRGB(200, 255, 200)},
        {name = "Luxury", color = Color3.fromRGB(255, 215, 0)},
        {name = "Spa", color = Color3.fromRGB(173, 216, 230)}
    })
    
    -- Define equipment categories
    configManager:SetSetting("equipmentCategories", {
        {name = "Cardio", upgradePathPrefix = "Cardio_"},
        {name = "Strength", upgradePathPrefix = "Strength_"},
        {name = "Functional", upgradePathPrefix = "Func_"},
        {name = "Premium", upgradePathPrefix = "Premium_"}
    })
    
    -- Define advanced prerequisites
    configManager:SetSetting("prerequisites", {
        floor2 = {"receptionArea", "basicCardio", "basicStrength"},
        floor3 = {"floor2", "advancedCardio", "advancedStrength"},
        luxuryArea = {"floor3", "premiumMembership"},
        spaArea = {"floor2", "luxuryMembership"}
    })
    
    -- Save the configuration
    local success = configManager:SaveConfig()
    print("Configuration saved:", success)
    
    -- Export to JSON string for demonstration
    local jsonString = configManager:ExportConfig()
    print("Configuration exported to JSON:", jsonString ~= nil)
    
    return configManager
end

-- Example function to apply configuration to a tycoon
local function ApplyConfigurationToTycoon(tycoonName, configName)
    print("\n=== Applying Configuration to Tycoon ===")
    
    -- Find the tycoon
    local tycoon = workspace:FindFirstChild(tycoonName)
    if not tycoon then
        print("Tycoon not found:", tycoonName)
        return
    end
    
    -- Apply configuration
    print("Applying configuration '" .. configName .. "' to tycoon '" .. tycoonName .. "'")
    local success = ConfigurationIntegration.applyConfiguration(tycoon, configName)
    
    if success then
        print("Configuration applied successfully")
        
        -- Get the configuration to inspect values
        local config = ConfigurationIntegration.getConfiguration(tycoon)
        if config then
            print("- Economy multiplier:", config:GetSetting("settings.economyMultiplier"))
            print("- Max floors:", config:GetSetting("settings.maxFloors"))
            print("- Room types:", #config:GetSetting("roomTypes"))
            
            -- Check if a specific feature is enabled
            local customizationEnabled = config:IsFeatureEnabled("settings.customizationEnabled")
            print("- Customization enabled:", customizationEnabled)
        end
    else
        print("Failed to apply configuration")
    end
end

-- Example function to automate tycoon with configuration
local function AutomateTycoonWithConfig(tycoonName, configName)
    print("\n=== Automating Tycoon With Configuration ===")
    
    if not GymAutomation then
        print("GymAutomation module not available")
        return
    end
    
    -- Find the tycoon
    local tycoon = workspace:FindFirstChild(tycoonName)
    if not tycoon then
        print("Tycoon not found:", tycoonName)
        return
    end
    
    -- Automate the tycoon with the specified configuration
    print("Automating tycoon '" .. tycoonName .. "' with configuration '" .. configName .. "'")
    local results = GymAutomation:AutomateGym(tycoon, configName)
    
    -- Print results
    if results then
        print("Automation completed successfully:")
        print("- Floor count:", results.floorCount)
        print("- Equipment count:", results.equipmentCount)
        print("- Hitbox count:", results.hitboxCount)
    end
end

-- Register commands in Studio for testing
local function RegisterStudioCommands()
    print("\n=== Registering Studio Commands ===")
    
    -- Command to create a custom configuration
    shared.CreateCustomConfig = CreateCustomConfig
    
    -- Command to apply configuration to a tycoon
    shared.ApplyConfigToTycoon = function(tycoonName, configName)
        ApplyConfigurationToTycoon(tycoonName or "GymTycoon", configName or "LuxuryGymConfig")
    end
    
    -- Command to automate a tycoon with configuration
    shared.AutomateTycoonWithConfig = function(tycoonName, configName)
        AutomateTycoonWithConfig(tycoonName or "GymTycoon", configName or "LuxuryGymConfig")
    end
    
    print("Registered commands:")
    print("- shared.CreateCustomConfig()")
    print("- shared.ApplyConfigToTycoon(tycoonName, configName)")
    print("- shared.AutomateTycoonWithConfig(tycoonName, configName)")
end

-- Run the example
print("Configuration System Example")

-- Initialize ConfigurationIntegration if not already initialized
if ConfigurationIntegration and not ConfigurationIntegration._initialized then
    ConfigurationIntegration.init()
end

-- Register studio commands
RegisterStudioCommands()

-- Create the custom configuration
local customConfig = CreateCustomConfig()

-- Output welcome message
print("\nConfiguration system is ready to use!")
print("Run 'shared.ApplyConfigToTycoon()' to apply the configuration to a tycoon.")
print("Run 'shared.AutomateTycoonWithConfig()' to automate a tycoon with the configuration.")
