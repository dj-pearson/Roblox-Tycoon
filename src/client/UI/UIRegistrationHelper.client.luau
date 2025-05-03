--[[
    UIRegistrationHelper.client.luau
    
    Ensures all UI modules are properly registered with the UIRegistry.
    This module scans for UI modules and registers them if they aren't already registered.
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Safe require helper
local function safeRequire(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then return nil end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        return result
    else
        warn("[UIRegistrationHelper] Failed to require: " .. moduleScript:GetFullName() .. " - " .. tostring(result))
        return nil
    end
end

-- Debug logger
local function log(message, level)
    local prefix = "[UIRegistrationHelper]"
    if level == "Error" then
        warn(prefix, message)
    elseif level == "Success" then
        print(prefix, "✓", message)
    else
        print(prefix, message)
    end
end

-- Find UIRegistry module
local function findUIRegistry()
    local searchPaths = {
        -- Client UI folder
        player.PlayerScripts:FindFirstChild("client") and 
        player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and 
        player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild("UIRegistry.client"),
        
        -- Client Core folder
        player.PlayerScripts:FindFirstChild("client") and 
        player.PlayerScripts:FindFirstChild("client"):FindFirstChild("Core") and 
        player.PlayerScripts:FindFirstChild("client"):FindFirstChild("Core"):FindFirstChild("UIRegistry"),
        
        -- Shared folder
        ReplicatedStorage:FindFirstChild("shared") and 
        ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("UIRegistry")
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local registry = safeRequire(path)
            if registry then
                log("Found UIRegistry at: " .. path:GetFullName(), "Success")
                return registry
            end
        end
    end
    
    log("UIRegistry not found in any expected location", "Error")
    return nil
end

-- Check if a module is a valid UI module
local function isValidUIModule(module)
    if not module then return false end
    
    -- Check for standard UI interface
    local hasToggleUI = typeof(module.ToggleUI) == "function"
    local hasShowUI = typeof(module.ShowUI) == "function"
    local hasHideUI = typeof(module.HideUI) == "function"
    
    return hasToggleUI or (hasShowUI and hasHideUI)
end

-- UIRegistrationHelper
local UIRegistrationHelper = {}

-- Scan for UI modules in a given folder
function UIRegistrationHelper.scanForUIModules(folder)
    if not folder then return end
    
    log("Scanning for UI modules in: " .. folder:GetFullName())
    local uiModules = {}
    
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("ModuleScript") then
            -- Check if it has UI in the name
            if child.Name:find("UI") then
                -- Try to require it
                local module = safeRequire(child)
                if module and isValidUIModule(module) then
                    uiModules[child.Name] = module
                    log("Found UI module: " .. child.Name, "Success")
                end
            end
        end
    end
    
    return uiModules
end

-- Register UI modules with UIRegistry
function UIRegistrationHelper.registerUIModules(forceRegister)
    local UIRegistry = findUIRegistry()
    if not UIRegistry then
        log("Cannot register modules, UIRegistry not found", "Error")
        return false
    end
    
    -- Check if UIRegistry has register methods
    if typeof(UIRegistry.registerComponent) ~= "function" and 
       typeof(UIRegistry.RegisterComponent) ~= "function" then
        log("UIRegistry does not have a registration method", "Error")
        return false
    end
    
    -- Use the appropriate registration method
    local registerFn = UIRegistry.registerComponent or UIRegistry.RegisterComponent
    
    -- Find UI folder in client scripts
    local uiFolder = player.PlayerScripts:FindFirstChild("client") and 
                     player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI")
    
    if not uiFolder then
        log("UI folder not found", "Error")
        return false
    end
    
    -- Scan for UI modules
    local uiModules = UIRegistrationHelper.scanForUIModules(uiFolder)
    local registeredCount = 0
    
    -- Register all found UI modules
    for name, module in pairs(uiModules) do
        -- Check if module is already registered
        local alreadyRegistered = false
        if not forceRegister and UIRegistry.getComponent then
            alreadyRegistered = UIRegistry.getComponent(name) ~= nil
        end
        
        if forceRegister or not alreadyRegistered then
            if typeof(registerFn) == "function" then
                local success = pcall(function()
                    registerFn(name, module)
                end)
                
                if success then
                    registeredCount = registeredCount + 1
                    log("Registered UI module: " .. name, "Success")
                else
                    log("Failed to register UI module: " .. name, "Error")
                end
            end
        else
            log("UI module already registered: " .. name)
        end
    end
    
    log("Registered " .. registeredCount .. " UI modules with UIRegistry", "Success")
    return true
end

-- List all menu UI modules
function UIRegistrationHelper.listMenuUIModules()
    log("Listing all menu UI modules")
    
    -- List of menu buttons to check
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
    
    local UIRegistry = findUIRegistry()
    local resultTable = {}
    
    for _, buttonName in ipairs(menuButtons) do
        local uiModuleName = buttonName .. "UI"
        local result = {
            name = uiModuleName,
            registered = false,
            hasModule = false,
            hasInterface = false
        }
        
        -- Check if registered in UIRegistry
        if UIRegistry and UIRegistry.getComponent then
            local registeredModule = UIRegistry.getComponent(uiModuleName)
            result.registered = registeredModule ~= nil
            
            if registeredModule then
                result.hasModule = true
                result.hasInterface = isValidUIModule(registeredModule)
            end
        end
        
        -- If not found in registry, check direct file
        if not result.hasModule then
            local uiFolder = player.PlayerScripts:FindFirstChild("client") and 
                           player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI")
            
            if uiFolder then
                local moduleScript = uiFolder:FindFirstChild(uiModuleName) or uiFolder:FindFirstChild(uiModuleName .. ".client")
                if moduleScript then
                    local module = safeRequire(moduleScript)
                    result.hasModule = module ~= nil
                    if module then
                        result.hasInterface = isValidUIModule(module)
                    end
                end
            end
        end
        
        resultTable[buttonName] = result
        
        -- Log status
        local status = ""
        if result.registered then
            status = "✅ Registered"
        elseif result.hasModule then
            status = "⚠️ Module exists but not registered"
        else
            status = "❌ Module not found"
        end
        
        local interface = result.hasInterface and "✅ Valid interface" or "❌ Invalid interface"
        log(uiModuleName .. ": " .. status .. ", " .. interface)
    end
    
    return resultTable
end

-- Ensure all menu UIs have proper modules
function UIRegistrationHelper.ensureAllMenuUIs()
    log("Ensuring all menu UIs are available")
    
    -- List of menu buttons to check
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
    
    local uiFolder = player.PlayerScripts:FindFirstChild("client") and 
                    player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI")
    
    if not uiFolder then
        log("UI folder not found", "Error")
        return false
    end
    
    -- Create basic UI template function
    local function createBasicUITemplate(name)
        return {
            name = name,
            isOpen = false,
            
            ToggleUI = function(self)
                self.isOpen = not self.isOpen
                if self.isOpen then
                    return self:ShowUI()
                else
                    return self:HideUI()
                end
            end,
            
            ShowUI = function(self)
                print(name .. " would show here!")
                self.isOpen = true
            end,
            
            HideUI = function(self)
                print(name .. " would hide here!")
                self.isOpen = false
            end
        }
    end
    
    local UIRegistry = findUIRegistry()
    local createdCount = 0
    
    for _, buttonName in ipairs(menuButtons) do
        local uiModuleName = buttonName .. "UI"
        local moduleExists = false
        
        -- Check if module exists
        if UIRegistry and UIRegistry.getComponent then
            moduleExists = UIRegistry.getComponent(uiModuleName) ~= nil
        end
        
        if not moduleExists then
            -- Check if file exists
            local moduleScript = uiFolder:FindFirstChild(uiModuleName) or uiFolder:FindFirstChild(uiModuleName .. ".client")
            if moduleScript then
                local module = safeRequire(moduleScript)
                moduleExists = module ~= nil
            end
        end
        
        -- If module doesn't exist, register a basic template
        if not moduleExists and UIRegistry and UIRegistry.registerComponent then
            local template = createBasicUITemplate(uiModuleName)
            UIRegistry.registerComponent(uiModuleName, template)
            createdCount = createdCount + 1
            log("Created and registered template for: " .. uiModuleName, "Success")
        end
    end
    
    log("Created " .. createdCount .. " template UI modules", "Success")
    return true
end

-- Initialize and register all UI modules
log("UIRegistrationHelper initialized")
UIRegistrationHelper.registerUIModules(false)

return UIRegistrationHelper
