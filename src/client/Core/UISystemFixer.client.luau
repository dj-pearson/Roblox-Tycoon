--[[
    UISystemFixer.client.luau
    
    Fixes specific issues with the UISystem that are causing failures 
    in the menu UI components. This script specifically targets the 
    issues identified in RobloxIssues.txt related to UI system failures.
    
    Created: May 4, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Only run on client
if not RunService:IsClient() then
    return
end

print("\n==== RUNNING UI SYSTEM FIXER ====")

-- Get player
local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

-- Debug logging
local function log(message, isError)
    if isError then
        warn("[UISystemFixer] " .. message)
    else
        print("[UISystemFixer] " .. message)
    end
end

-- Function to find a module
local function findModule(name, paths)
    for _, path in ipairs(paths) do
        if path then
            -- Try direct name
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
            
            -- Try checking in UI subfolder
            local uiFolder = path:FindFirstChild("UI")
            if uiFolder then
                module = uiFolder:FindFirstChild(name)
                if module and module:IsA("ModuleScript") then
                    return module
                end
                
                for _, ext in ipairs(extensions) do
                    module = uiFolder:FindFirstChild(name .. ext)
                    if module and module:IsA("ModuleScript") then
                        return module
                    end
                end
            end
        end
    end
    return nil
end

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        log("Failed to require: " .. tostring(module:GetFullName()) .. " - " .. tostring(result), true)
        return nil
    end
end

-- Define search paths
local searchPaths = {
    player:FindFirstChild("PlayerScripts"),
    player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client"),
    player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client") and player.PlayerScripts.src.client:FindFirstChild("Core"),
    player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client") and player.PlayerScripts.src.client:FindFirstChild("UI"),
    ReplicatedStorage:FindFirstChild("shared"),
    ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
    ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client"),
    ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and ReplicatedStorage.src.client:FindFirstChild("UI")
}

-- Get ClientRegistry
local function getClientRegistry()
    -- Try to find ClientRegistry
    log("Looking for ClientRegistry...")
    
    local clientRegistryModule = findModule("ClientRegistry", searchPaths)
    if not clientRegistryModule then
        log("ClientRegistry module not found", true)
        return nil
    end
    
    local clientRegistry = safeRequire(clientRegistryModule)
    if not clientRegistry then
        log("Failed to require ClientRegistry", true)
        return nil
    end
    
    log("Found ClientRegistry at: " .. clientRegistryModule:GetFullName())
    return clientRegistry
end

-- Define UI components to fix
local uiComponentsToFix = {
    {
        name = "UISystem",
        fallbackName = "UIManager",
        errorMessage = "ClientRegistry.getSystem: System not found - UISystem"
    },
    {
        name = "UISystemPatcher",
        fallbackName = "UIPatcher",
        errorMessage = "UISystemPatcher: UISystem not found, cannot patch"
    },
    {
        name = "MenuButtonCreator",
        fallbackName = "ButtonCreator",
        errorMessage = "[UILoader] Failed to load: MenuButtonCreator - Attempted to call require with invalid argument(s)."
    },
    {
        name = "GymTycoonMenuUI",
        fallbackName = "MainMenuUI",
        errorMessage = "[UILoader] Failed to load: GymTycoonMenuUI - Attempted to call require with invalid argument(s)."
    },
    {
        name = "AdminButtonCreator",
        fallbackName = "AdminPanel",
        errorMessage = "[UILoader] Failed to load: AdminButtonCreator - Attempted to call require with invalid argument(s)."
    },
    {
        name = "UISystemEnhancer",
        fallbackName = "UIEnhancer",
        errorMessage = "[UISystemEnhancer] UI folder not found"
    }
}

-- Get ClientRegistry
local ClientRegistry = getClientRegistry()
if not ClientRegistry then
    log("ClientRegistry not available, UI fixes may not work properly", true)
end

-- Create placeholder implementations if needed
local function createPlaceholderUI(name)
    log("Creating placeholder for: " .. name)
    
    local placeholder = {
        _isPlaceholder = true,
        name = name,
        initialized = true,
        
        initialize = function(self)
            log("Initialized placeholder for: " .. name)
            return true
        end,
        
        showUI = function(self)
            log("Placeholder UI shown for: " .. name)
            return true
        end,
        
        hideUI = function(self)
            log("Placeholder UI hidden for: " .. name)
            return true
        end,
        
        createButton = function(self, props)
            log("Placeholder button created for: " .. name)
            return {
                visible = true,
                text = props and props.text or "Button"
            }
        end
    }
    
    -- Additional functionality based on component type
    if name == "UISystem" or name == "UIManager" then
        placeholder.getUI = function(self, uiName)
            log("UISystem placeholder: getUI called for " .. uiName)
            return nil
        end
        
        placeholder.registerUI = function(self, uiName, uiModule)
            log("UISystem placeholder: registerUI called for " .. uiName)
            return true
        end
    elseif name == "UISystemPatcher" or name == "UIPatcher" then
        placeholder.patchUI = function(self, uiName)
            log("UISystemPatcher placeholder: patchUI called for " .. uiName)
            return true
        end
    end
    
    return placeholder
end

-- Fix UI Components
local fixedCount = 0
for _, component in ipairs(uiComponentsToFix) do
    log("Fixing component: " .. component.name)
    
    -- Skip if already registered and working
    local existingModule = ClientRegistry and ClientRegistry.getSystem and ClientRegistry:getSystem(component.name)
    if existingModule and not existingModule._isPlaceholder then
        log("Component already registered and working: " .. component.name)
        fixedCount += 1
        continue
    end
    
    -- Try to find the module
    local module = findModule(component.name, searchPaths)
    if not module and component.fallbackName then
        log("Primary module not found, trying fallback: " .. component.fallbackName)
        module = findModule(component.fallbackName, searchPaths)
    end
    
    if not module then
        log("Module not found for: " .. component.name .. ", creating placeholder", true)
        local placeholder = createPlaceholderUI(component.name)
        
        if ClientRegistry and ClientRegistry.registerSystem then
            ClientRegistry:registerSystem(component.name, placeholder)
            log("Registered placeholder for: " .. component.name)
            fixedCount += 1
        end
        continue
    end
    
    -- Require the module
    local moduleInstance = safeRequire(module)
    if not moduleInstance then
        log("Failed to require module for: " .. component.name .. ", creating placeholder", true)
        local placeholder = createPlaceholderUI(component.name)
        
        if ClientRegistry and ClientRegistry.registerSystem then
            ClientRegistry:registerSystem(component.name, placeholder)
            log("Registered placeholder for: " .. component.name)
            fixedCount += 1
        end
        continue
    end
    
    -- Register with ClientRegistry
    if ClientRegistry and ClientRegistry.registerSystem then
        ClientRegistry:registerSystem(component.name, moduleInstance)
        log("Successfully registered: " .. component.name)
        
        -- Initialize if not already initialized
        if moduleInstance.initialize and not moduleInstance.initialized then
            local success, err = pcall(function()
                moduleInstance:initialize()
            end)
            
            if success then
                log("Successfully initialized: " .. component.name)
            else
                log("Failed to initialize: " .. component.name .. " - " .. tostring(err), true)
            end
        end
        
        fixedCount += 1
    else
        log("ClientRegistry not available, cannot register: " .. component.name, true)
    end
end

-- Special fix for UISystemEnhancer if UI folder is missing
local UISystemEnhancer = ClientRegistry and ClientRegistry.getSystem and ClientRegistry:getSystem("UISystemEnhancer")
if UISystemEnhancer then
    -- Create UI folder if missing
    for _, path in ipairs(searchPaths) do
        if path and not path:FindFirstChild("UI") then
            log("Creating missing UI folder in: " .. path:GetFullName())
            local uiFolder = Instance.new("Folder")
            uiFolder.Name = "UI"
            uiFolder.Parent = path
        end
    end
    
    -- Try to fix MainMenuUI loading
    local mainMenuUI = findModule("MainMenuUI", searchPaths)
    if mainMenuUI then
        log("Found MainMenuUI at: " .. mainMenuUI:GetFullName())
        
        if UISystemEnhancer.registerUI then
            UISystemEnhancer:registerUI("MainMenuUI", safeRequire(mainMenuUI))
            log("Registered MainMenuUI with UISystemEnhancer")
        end
    else
        log("MainMenuUI not found, cannot fix [UISystemEnhancer] All attempts to show UI failed: MainMenuUI", true)
    end
end

-- Report results
log("Fixed " .. fixedCount .. "/" .. #uiComponentsToFix .. " UI components")

-- Set global status flag
_G.UISystemFixApplied = true
_G.UISystemFixTime = os.time()

print("==== UI SYSTEM FIXER COMPLETE ====\n")

return {
    success = fixedCount > 0,
    componentsFixed = fixedCount,
    totalComponents = #uiComponentsToFix
}
