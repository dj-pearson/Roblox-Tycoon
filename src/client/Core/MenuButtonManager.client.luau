--[[
    MenuButtonManager.client.luau
    
    Enhanced menu button management system that ensures reliable button creation
    and functionality across all menus.
    
    Features:
    - Reliable button creation with fallback mechanisms
    - Integration with ModuleResolver for UI components
    - Button state management and validation
    - Integration with CoreRegistry
    - Health monitoring and status reporting
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxRetries = 3,
    retryDelay = 1, -- seconds
    defaultButtonStyle = {
        Size = UDim2.new(0, 200, 0, 50),
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        BorderSizePixel = 0,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14
    }
}

-- Module state
local MenuButtonManager = {
    initialized = false,
    buttons = {},      -- Active buttons
    errors = {},       -- Error history
    lastCheck = 0      -- Last health check time
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[MenuButtonManager]", ...)
    end
end

-- Get ModuleResolver
local function getModuleResolver()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local resolver = coreRegistry:getSystem("ModuleResolver")
        if resolver then
            return resolver
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("ModuleResolver") then
        local success, result = pcall(function()
            return require(core.ModuleResolver)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Create a button
local function createButton(name, options)
    options = options or {}
    
    -- Create button instance
    local button = Instance.new("TextButton")
    button.Name = name
    
    -- Apply default style
    for property, value in pairs(CONFIG.defaultButtonStyle) do
        button[property] = value
    end
    
    -- Apply custom style
    if options.style then
        for property, value in pairs(options.style) do
            button[property] = value
        end
    end
    
    -- Set text
    button.Text = options.text or name
    
    -- Create click handler
    if options.onClick then
        button.MouseButton1Click:Connect(function()
            local success, result = pcall(options.onClick)
            if not success then
                log("Button click handler failed:", result)
                MenuButtonManager.recordError("Button click failed: " .. name .. " - " .. tostring(result))
            end
        end)
    end
    
    return button
end

-- Create a placeholder button
local function createPlaceholderButton(name)
    log("Creating placeholder button for: " .. name)
    
    return createButton(name, {
        text = name .. " (Placeholder)",
        style = {
            BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        },
        onClick = function()
            log("Placeholder button clicked: " .. name)
        end
    })
end

-- Initialize MenuButtonManager
function MenuButtonManager.initialize()
    if MenuButtonManager.initialized then return true end
    
    log("Initializing MenuButtonManager...")
    
    -- Get ModuleResolver
    local resolver = getModuleResolver()
    if not resolver then
        log("ModuleResolver not found, button creation may be limited", true)
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            MenuButtonManager.checkHealth()
        end
    end)
    
    MenuButtonManager.initialized = true
    log("MenuButtonManager initialized")
    return true
end

-- Create a menu button
function MenuButtonManager.createMenuButton(name, options)
    if not MenuButtonManager.initialized then
        MenuButtonManager.initialize()
    end
    
    options = options or {}
    log("Creating menu button: " .. name)
    
    -- Check if button already exists
    if MenuButtonManager.buttons[name] then
        log("Button already exists: " .. name)
        return MenuButtonManager.buttons[name]
    end
    
    -- Try to get UI module
    local resolver = getModuleResolver()
    local uiModule = nil
    
    if resolver then
        uiModule = resolver.resolve(name .. "UI", {
            createPlaceholder = options.createPlaceholder
        })
    end
    
    -- Create button
    local button
    if uiModule and not uiModule._isPlaceholder then
        -- Create button with UI module
        button = createButton(name, {
            text = options.text or name,
            style = options.style,
            onClick = function()
                local success, result = pcall(function()
                    return uiModule.show()
                end)
                if not success then
                    log("Failed to show UI:", result)
                    MenuButtonManager.recordError("UI show failed: " .. name .. " - " .. tostring(result))
                end
            end
        })
    else
        -- Create placeholder button
        button = createPlaceholderButton(name)
        if uiModule and uiModule._isPlaceholder then
            MenuButtonManager.recordError("Using placeholder UI for: " .. name)
        end
    end
    
    -- Store button
    MenuButtonManager.buttons[name] = button
    
    -- Set parent if provided
    if options.parent then
        button.Parent = options.parent
    end
    
    return button
end

-- Get a menu button
function MenuButtonManager.getButton(name)
    return MenuButtonManager.buttons[name]
end

-- Remove a menu button
function MenuButtonManager.removeButton(name)
    local button = MenuButtonManager.buttons[name]
    if button then
        button:Destroy()
        MenuButtonManager.buttons[name] = nil
    end
end

-- Check system health
function MenuButtonManager.checkHealth()
    local now = os.time()
    MenuButtonManager.lastCheck = now
    
    -- Check button count
    local buttonCount = 0
    for _ in pairs(MenuButtonManager.buttons) do
        buttonCount = buttonCount + 1
    end
    
    if buttonCount > 50 then
        MenuButtonManager.recordError("Too many buttons: " .. buttonCount)
    end
    
    -- Check error count
    if #MenuButtonManager.errors > 50 then
        MenuButtonManager.recordError("Too many errors: " .. #MenuButtonManager.errors)
    end
    
    return true
end

-- Record an error
function MenuButtonManager.recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(MenuButtonManager.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #MenuButtonManager.errors > 50 do
        table.remove(MenuButtonManager.errors, 1)
    end
    
    log("Error recorded: " .. message)
end

-- Get error count
function MenuButtonManager.getErrorCount()
    return #MenuButtonManager.errors
end

-- Get recent errors
function MenuButtonManager.getRecentErrors()
    return MenuButtonManager.errors
end

-- Force a health check
function MenuButtonManager.forceCheck()
    return MenuButtonManager.checkHealth()
end

return MenuButtonManager 