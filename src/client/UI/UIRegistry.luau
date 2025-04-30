-- UIRegistry.luau
-- A registry for UI components and screens
-- Created: April 30, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player and player:FindFirstChild("PlayerGui")

local UIRegistry = {
    initialized = false,
    DEBUG = true,
    
    -- Storage for registered UI components
    components = {},
    screens = {},
    templates = {}
}

-- Simple logging function
local function log(message, level)
    if not UIRegistry.DEBUG and level ~= "Error" then return end
    
    local prefix = "[UIRegistry]"
    if level == "Error" then
        warn(prefix .. " " .. message)
    elseif level == "Success" then
        print(prefix .. " ✓ " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Register a UI component
function UIRegistry:RegisterComponent(name, component)
    if not name or typeof(name) ~= "string" then
        log("Invalid component name", "Error")
        return false
    end
    
    if not component then
        log("Invalid component provided for: " .. name, "Error")
        return false
    end
    
    self.components[name] = component
    log("Registered component: " .. name, "Success")
    return true
end

-- Get a registered component
function UIRegistry:GetComponent(name)
    if not name or typeof(name) ~= "string" then
        log("Invalid component name", "Error")
        return nil
    end
    
    if not self.components[name] then
        log("Component not found: " .. name, "Error")
        return nil
    end
    
    return self.components[name]
end

-- Register a screen (top-level UI)
function UIRegistry:RegisterScreen(name, screen)
    if not name or typeof(name) ~= "string" then
        log("Invalid screen name", "Error")
        return false
    end
    
    if not screen then
        log("Invalid screen provided for: " .. name, "Error")
        return false
    end
    
    self.screens[name] = screen
    log("Registered screen: " .. name, "Success")
    return true
end

-- Get a registered screen
function UIRegistry:GetScreen(name)
    if not name or typeof(name) ~= "string" then
        log("Invalid screen name", "Error")
        return nil
    end
    
    if not self.screens[name] then
        log("Screen not found: " .. name, "Error")
        return nil
    end
    
    return self.screens[name]
end

-- Register a UI template
function UIRegistry:RegisterTemplate(name, template)
    if not name or typeof(name) ~= "string" then
        log("Invalid template name", "Error")
        return false
    end
    
    if not template then
        log("Invalid template provided for: " .. name, "Error")
        return false
    end
    
    self.templates[name] = template
    log("Registered template: " .. name, "Success")
    return true
end

-- Get a registered template
function UIRegistry:GetTemplate(name)
    if not name or typeof(name) ~= "string" then
        log("Invalid template name", "Error")
        return nil
    end
    
    if not self.templates[name] then
        log("Template not found: " .. name, "Error")
        return nil
    end
    
    return self.templates[name]
end

-- Initialize module
function UIRegistry:initialize()
    if self.initialized then
        return
    end
    
    log("Initializing UIRegistry")
    
    -- Register with ClientRegistry if available
    local ClientRegistry = nil
    
    -- First try direct requiring
    local success, result = pcall(function()
        return require(script.Parent.Parent:FindFirstChild("ClientRegistry"))
    end)
    
    if success and result then
        ClientRegistry = result
    else
        -- Try to find in player scripts
        local player = Players.LocalPlayer
        local PlayerScripts = player and player:FindFirstChild("PlayerScripts")
        
        if PlayerScripts and PlayerScripts:FindFirstChild("ClientRegistry") then
            ClientRegistry = require(PlayerScripts.ClientRegistry)
        elseif ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ClientRegistry") then
            ClientRegistry = require(ReplicatedStorage.shared.ClientRegistry)
        end
    end
    
    if ClientRegistry and typeof(ClientRegistry.Register) == "function" then
        ClientRegistry:Register("UIRegistry", self)
        log("Registered with ClientRegistry", "Success")
    else
        log("ClientRegistry not found, could not register", "Error")
    end
    
    self.initialized = true
    log("UIRegistry initialized", "Success")
    return true
end

-- Initialize on require
task.spawn(function()
    UIRegistry:initialize()
end)

return UIRegistry
