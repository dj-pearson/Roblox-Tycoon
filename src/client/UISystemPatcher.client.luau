-- UISystemPatcher.client.luau
--[[
    This script enhances the UISystem to help fix issues with UI components not showing up
    by adding additional methods to try multiple naming conventions and fallbacks.
    
    Created: April 28, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("UISystemPatcher: Starting...")

-- Find UISystem
local function getUISystem()
    -- Try different paths to find UISystem
    local paths = {
        -- Global
        {getfenv(0), "UISystem"},
        {getfenv(0), "_G", "UISystem"},
        
        -- Registry paths
        {getfenv(0), "ClientRegistry", "getSystem", "UISystem"},
        {getfenv(0), "_G", "ClientRegistry", "getSystem", "UISystem"},
        
        -- Module paths
        {ReplicatedStorage, "src", "client", "UI", "Core", "UISystem"},
    }
    
    for _, path in ipairs(paths) do
        local current = path[1]
        local success = true
        
        for i = 2, #path do
            local key = path[i]
            
            if type(current) == "table" then
                if type(key) == "string" then
                    current = current[key]
                end
            elseif type(current) == "userdata" and current:IsA("Instance") then
                if type(key) == "string" then
                    current = current:FindFirstChild(key)
                end
            elseif type(current) == "function" then
                if i == #path then
                    -- If last item is a function and parameter
                    current = current(key)
                else
                    -- Call function and continue
                    current = current()
                    -- Get next key
                    key = path[i+1]
                    -- Skip next iteration
                    i = i + 1
                    -- Check if we need to continue
                    if i > #path then
                        break
                    end
                    
                    -- Continue with new value if available
                    if current then
                        current = current[key]
                    else
                        success = false
                        break
                    end
                end
            else
                success = false
                break
            end
            
            if current == nil then
                success = false
                break
            end
        end
        
        if success and current then
            return current
        end
    end
    
    return nil
end

-- Find UIRegistry
local function getUIRegistry()
    -- Try different paths to find UIRegistry
    local paths = {
        -- Global
        {getfenv(0), "UIRegistry"},
        {getfenv(0), "_G", "UIRegistry"},
        
        -- Registry paths
        {getfenv(0), "ClientRegistry", "getSystem", "UIRegistry"},
        {getfenv(0), "_G", "ClientRegistry", "getSystem", "UIRegistry"},
    }
    
    for _, path in ipairs(paths) do
        local current = path[1]
        local success = true
        
        for i = 2, #path do
            local key = path[i]
            
            if type(current) == "table" then
                if type(key) == "string" then
                    current = current[key]
                end
            elseif type(current) == "userdata" and current:IsA("Instance") then
                if type(key) == "string" then
                    current = current:FindFirstChild(key)
                end
            elseif type(current) == "function" then
                if i == #path then
                    -- If last item is a function and parameter
                    current = current(key)
                else
                    -- Call function and continue
                    current = current()
                    -- Get next key
                    key = path[i+1]
                    -- Skip next iteration
                    i = i + 1
                    -- Check if we need to continue
                    if i > #path then
                        break
                    end
                    
                    -- Continue with new value if available
                    if current then
                        current = current[key]
                    else
                        success = false
                        break
                    end
                end
            else
                success = false
                break
            end
            
            if current == nil then
                success = false
                break
            end
        end
        
        if success and current then
            return current
        end
    end
    
    return nil
end

-- Create an enhanced showUI function
local function enhancedShowUI(name, ...)
    print("UISystemPatcher: Enhanced showUI called for: " .. name)
    
    -- Get UISystem and UIRegistry
    local UISystem = getUISystem()
    local UIRegistry = getUIRegistry()
    
    if not UISystem then
        warn("UISystemPatcher: UISystem not found")
        return false
    end
    
    if not UIRegistry then
        warn("UISystemPatcher: UIRegistry not found")
        return false
    end
    
    -- Try standard and alternative naming patterns
    local namesToTry = {
        name, -- Original name
        name .. "UI", -- Add UI suffix
        string.sub(name, 1, -3) -- Remove UI suffix if it exists
    }
    
    -- Filter out invalid names
    local validNames = {}
    for _, tryName in ipairs(namesToTry) do
        if string.sub(tryName, -2) == "UI" or #tryName >= 3 then
            table.insert(validNames, tryName)
        end
    end
    
    print("UISystemPatcher: Trying UI names: " .. table.concat(validNames, ", "))
    
    -- Try original UISystem.showUI first
    local originalShowUI = UISystem.showUI
    if originalShowUI then
        local success = originalShowUI(UISystem, name, ...)
        if success then
            print("UISystemPatcher: Original showUI succeeded for: " .. name)
            return true
        end
    end
    
    -- Try all name variations
    for _, tryName in ipairs(validNames) do
        if tryName ~= name then -- Skip the original name, we already tried it
            print("UISystemPatcher: Trying alternative name: " .. tryName)
            
            -- Try original UISystem.showUI with alternative name
            if originalShowUI then
                local success = originalShowUI(UISystem, tryName, ...)
                if success then
                    print("UISystemPatcher: Original showUI succeeded for alternative name: " .. tryName)
                    return true
                end
            end
            
            -- Direct component approach
            local component = UIRegistry:getComponent(tryName)
            if component and component.show then
                print("UISystemPatcher: Found component with name: " .. tryName)
                local success, result = pcall(function()
                    return component:show(...)
                end)
                
                if success and result ~= false then
                    print("UISystemPatcher: Successfully showed UI via direct component: " .. tryName)
                    return true
                end
            end
            
            -- Try global component
            local globalComponent = _G[tryName]
            if globalComponent and globalComponent.show then
                print("UISystemPatcher: Found global component with name: " .. tryName)
                local success, result = pcall(function()
                    return globalComponent:show(...)
                end)
                
                if success and result ~= false then
                    print("UISystemPatcher: Successfully showed UI via global component: " .. tryName)
                    return true
                end
            end
        end
    end
    
    warn("UISystemPatcher: Failed to show UI: " .. name .. " (tried all paths and naming variations)")
    return false
end

-- Override UISystem:showUI with our enhanced version
local function patchUISystem()
    local UISystem = getUISystem()
    if not UISystem then
        warn("UISystemPatcher: UISystem not found, cannot patch")
        return false
    end
    
    -- Store the original function
    local originalShowUI = UISystem.showUI
    
    -- Replace with our enhanced version
    UISystem.showUI = function(self, name, ...)
        print("UISystemPatcher: Intercepted showUI call for: " .. name)
        
        -- First try the original method
        local success = originalShowUI(self, name, ...)
        if success then
            return true
        end
        
        -- If that fails, use our enhanced version
        return enhancedShowUI(name, ...)
    end
    
    -- Also patch showMainMenu to ensure it works
    local originalShowMainMenu = UISystem.showMainMenu
    UISystem.showMainMenu = function(self)
        print("UISystemPatcher: Intercepted showMainMenu call")
        
        -- First try the original method
        local success = originalShowMainMenu(self)
        if success then
            return true
        end
        
        -- If that fails, try our enhanced version with both naming conventions
        return enhancedShowUI("MainMenuUI") or enhancedShowUI("MainMenu")
    end
    
    print("UISystemPatcher: Successfully patched UISystem")
    return true
end

-- Wait for game to load and patch UISystem
task.wait(1) -- Wait for systems to initialize
local success = patchUISystem()

if success then
    print("UISystemPatcher: UISystem patched successfully")
    
    -- Try to show the main menu after patching
    task.delay(1, function()
        local UISystem = getUISystem()
        if UISystem then
            print("UISystemPatcher: Attempting to show MainMenuUI")
            UISystem:showMainMenu()
        end
    end)
else
    warn("UISystemPatcher: Failed to patch UISystem")
end

-- Expose global helpers for emergency use
_G.ShowUIEnhanced = enhancedShowUI
_G.UISystemPatcher = {
    enhancedShowUI = enhancedShowUI,
    getUISystem = getUISystem,
    getUIRegistry = getUIRegistry
}

print("UISystemPatcher: Setup complete")
