--[[
    ClientRegistryFixer.client.luau
    
    Ensures all required client UI components are properly registered and available.
    This script runs at client startup to fix any issues with UI components registration.
    
    Created: April 30, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Only run in client
if not RunService:IsClient() then
    return
end

print("\n==== RUNNING CLIENT REGISTRY FIXER ====")

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
        warn("[ClientRegistryFixer] Failed to require: " .. tostring(module:GetFullName()) .. " - " .. tostring(result))
        return nil
    end
end

-- Get ModuleScriptAccessor
local function getModuleScriptAccessor()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        return safeRequire(shared.ModuleScriptAccessor)
    end
    return nil
end

-- Get CoreRegistry
local function getCoreRegistry()
    local ModuleScriptAccessor = getModuleScriptAccessor()
    if ModuleScriptAccessor then
        return ModuleScriptAccessor.getCoreRegistry()
    end
    return nil
end

-- Wait for player to be available
local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

-- Wait for character
if not player.Character then
    player.CharacterAdded:Wait()
end

-- Define search paths for client modules
local clientSearchPaths = {
    ReplicatedStorage:FindFirstChild("shared"),
    player:FindFirstChild("PlayerScripts"),
    player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client") and player.PlayerScripts.src.client:FindFirstChild("Core")
}

-- Define critical UI components to fix
local criticalUIComponents = {
    {
        name = "UIRegistry",
        searchPaths = clientSearchPaths
    },
    {
        name = "UIComponents",
        searchPaths = clientSearchPaths
    },
    {
        name = "AssetValidator",
        searchPaths = {ReplicatedStorage:FindFirstChild("shared")}
    },
    {
        name = "ModuleLoader",
        searchPaths = {ReplicatedStorage:FindFirstChild("shared")}
    },
    {
        name = "ButtonFactory",
        searchPaths = clientSearchPaths
    },
    {
        name = "DialogFactory",
        searchPaths = clientSearchPaths
    },
    {
        name = "NotificationSystem",
        searchPaths = clientSearchPaths
    }
}

-- Try to get CoreRegistry
local CoreRegistry = getCoreRegistry()
if not CoreRegistry then
    warn("[ClientRegistryFixer] CoreRegistry not found, attempting to find it directly")
    
    -- Try to find CoreRegistry directly
    local coreRegistryModule = findModule("CoreRegistry", {
        ReplicatedStorage:FindFirstChild("shared"),
        player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client") and player.PlayerScripts.src.client:FindFirstChild("Core")
    })
    
    if coreRegistryModule then
        CoreRegistry = safeRequire(coreRegistryModule)
        print("[ClientRegistryFixer] Found CoreRegistry directly")
    else
        warn("[ClientRegistryFixer] CoreRegistry not found, UI components may not function correctly")
    end
end

-- Fix UI components
local fixedCount = 0
for _, component in ipairs(criticalUIComponents) do
    -- Check if already registered
    if CoreRegistry and CoreRegistry.hasSystem and CoreRegistry.hasSystem(component.name) then
        print("[ClientRegistryFixer] " .. component.name .. " is already registered with CoreRegistry")
        fixedCount += 1
        continue
    end
    
    -- Try to find the module
    local moduleScript = findModule(component.name, component.searchPaths)
    if not moduleScript then
        warn("[ClientRegistryFixer] Could not find " .. component.name .. " module")
        continue
    end
    
    -- Require the module
    local moduleInstance = safeRequire(moduleScript)
    if not moduleInstance then
        warn("[ClientRegistryFixer] Failed to require " .. component.name)
        continue
    end
    
    -- Register with CoreRegistry if available
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem(component.name, moduleInstance)
        print("[ClientRegistryFixer] Successfully registered " .. component.name .. " with CoreRegistry")
        fixedCount += 1
    else
        warn("[ClientRegistryFixer] CoreRegistry not available, couldn't register " .. component.name)
    end
    
    -- Initialize if needed
    if typeof(moduleInstance.initialize) == "function" and not moduleInstance.initialized then
        local success = moduleInstance.initialize()
        if success then
            print("[ClientRegistryFixer] Successfully initialized " .. component.name)
        else
            warn("[ClientRegistryFixer] Failed to initialize " .. component.name)
        end
    end
end

print("[ClientRegistryFixer] Fixed " .. fixedCount .. "/" .. #criticalUIComponents .. " UI components")

-- Create notification to show success
task.delay(1, function()
    -- Try to use UIRegistry to show notification
    local UIRegistry = CoreRegistry and CoreRegistry.getSystem and CoreRegistry.getSystem("UIRegistry")
    if UIRegistry and UIRegistry.DialogFactory and UIRegistry.DialogFactory.showNotification then
        UIRegistry.DialogFactory.showNotification(
            "UI System Fixed", 
            "Fixed " .. fixedCount .. "/" .. #criticalUIComponents .. " UI components",
            fixedCount == #criticalUIComponents and "success" or "warning",
            5
        )
    end
end)

print("==== CLIENT REGISTRY FIXES COMPLETE ====\n")
