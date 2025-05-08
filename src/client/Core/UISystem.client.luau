--[[
    UISystem.client.luau
    
    Enhanced UI system for Gym Tycoon.
    Provides robust UI component management, error recovery, and integration with CoreRegistry.
    
    Features:
    - Reliable UI component registration and management
    - Improved error handling and recovery
    - Integration with CoreRegistry
    - Health monitoring and status reporting
    - Fallback mechanisms for missing components
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxRetries = 3,
    retryDelay = 2, -- seconds,
    criticalComponents = {
        "MenuButtonCreator",
        "GymTycoonMenuUI",
        "AdminButtonCreator",
        "UISystemEnhancer"
    }
}

-- Module state
local UISystem = {
    components = {},    -- Registered UI components
    initialized = false,
    errors = {},       -- Error history
    lastCheck = 0      -- Last health check time
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[UISystem]", ...)
    end
end

-- Safe require with retries
local function safeRequire(module, retries)
    retries = retries or CONFIG.maxRetries
    local success, result
    
    for i = 1, retries do
        success, result = pcall(function()
            return require(module)
        end)
        
        if success then
            return result
        end
        
        if i < retries then
            log("Failed to require module, retrying... (" .. i .. "/" .. retries .. ")")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    return nil
end

-- Find module in multiple paths
local function findModule(moduleName, paths)
    paths = paths or {
        LocalPlayer.PlayerScripts,
        LocalPlayer.PlayerScripts:FindFirstChild("src") and LocalPlayer.PlayerScripts.src:FindFirstChild("client"),
        LocalPlayer.PlayerScripts:FindFirstChild("src") and LocalPlayer.PlayerScripts.src:FindFirstChild("client") and LocalPlayer.PlayerScripts.src.client:FindFirstChild("Core"),
        LocalPlayer.PlayerScripts:FindFirstChild("src") and LocalPlayer.PlayerScripts.src:FindFirstChild("client") and LocalPlayer.PlayerScripts.src.client:FindFirstChild("UI"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and ReplicatedStorage.src.client:FindFirstChild("UI")
    }
    
    for _, path in ipairs(paths) do
        if path then
            local module = path:FindFirstChild(moduleName) or path:FindFirstChild(moduleName .. ".client.luau")
            if module then
                return module
            end
        end
    end
    
    return nil
end

-- Create placeholder component
local function createPlaceholderComponent(name)
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
    if name == "MenuButtonCreator" then
        placeholder.createMenuButton = function(self, props)
            log("Placeholder menu button created")
            return {
                visible = true,
                text = props and props.text or "Menu Button",
                onClick = function() log("Placeholder menu button clicked") end
            }
        end
    elseif name == "GymTycoonMenuUI" then
        placeholder.showMainMenu = function(self)
            log("Placeholder main menu shown")
            return true
        end
    elseif name == "AdminButtonCreator" then
        placeholder.createAdminButton = function(self, props)
            log("Placeholder admin button created")
            return {
                visible = true,
                text = props and props.text or "Admin Button",
                onClick = function() log("Placeholder admin button clicked") end
            }
        end
    elseif name == "UISystemEnhancer" then
        placeholder.enhanceUI = function(self, uiName)
            log("Placeholder UI enhancement for: " .. uiName)
            return true
        end
    end
    
    return placeholder
end

-- Initialize UISystem
function UISystem.initialize()
    if UISystem.initialized then return true end
    
    log("Initializing UISystem...")
    
    -- Get CoreRegistry
    local coreRegistry = _G.CoreRegistry
    if not coreRegistry then
        log("CoreRegistry not found, UI system may not function properly", true)
    end
    
    -- Load critical components
    for _, componentName in ipairs(CONFIG.criticalComponents) do
        log("Loading component: " .. componentName)
        
        -- Try to find the module
        local module = findModule(componentName)
        if not module then
            log("Module not found for: " .. componentName .. ", creating placeholder", true)
            UISystem.components[componentName] = createPlaceholderComponent(componentName)
            continue
        end
        
        -- Require the module
        local component = safeRequire(module)
        if not component then
            log("Failed to require module for: " .. componentName .. ", creating placeholder", true)
            UISystem.components[componentName] = createPlaceholderComponent(componentName)
            continue
        end
        
        -- Initialize if needed
        if typeof(component.initialize) == "function" and not component.initialized then
            local success, err = pcall(function()
                component:initialize()
            end)
            
            if not success then
                log("Failed to initialize: " .. componentName .. " - " .. tostring(err), true)
                UISystem.components[componentName] = createPlaceholderComponent(componentName)
                continue
            end
        end
        
        -- Register component
        UISystem.components[componentName] = component
        log("Successfully loaded: " .. componentName)
        
        -- Register with CoreRegistry if available
        if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
            coreRegistry:registerSystem(componentName, component)
            log("Registered " .. componentName .. " with CoreRegistry")
        end
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            UISystem.checkHealth()
        end
    end)
    
    UISystem.initialized = true
    log("UISystem initialized")
    return true
end

-- Check system health
function UISystem.checkHealth()
    local now = os.time()
    UISystem.lastCheck = now
    
    -- Check critical components
    for _, componentName in ipairs(CONFIG.criticalComponents) do
        local component = UISystem.components[componentName]
        
        if not component then
            UISystem.recordError("Component not found: " .. componentName)
            continue
        end
        
        -- Check if component is initialized
        if not component.initialized then
            UISystem.recordError("Component not initialized: " .. componentName)
            continue
        end
        
        -- Check if component is a placeholder
        if component._isPlaceholder then
            UISystem.recordError("Using placeholder for: " .. componentName)
            continue
        end
    end
    
    return true
end

-- Record an error
function UISystem.recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(UISystem.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #UISystem.errors > 10 do
        table.remove(UISystem.errors, 1)
    end
    
    log("Error recorded: " .. message)
end

-- Get component
function UISystem.getComponent(name)
    return UISystem.components[name]
end

-- Get all components
function UISystem.getAllComponents()
    return UISystem.components
end

-- Get error count
function UISystem.getErrorCount()
    return #UISystem.errors
end

-- Get recent errors
function UISystem.getRecentErrors()
    return UISystem.errors
end

-- Force a health check
function UISystem.forceCheck()
    return UISystem.checkHealth()
end

return UISystem 