--[[
    MenuButtonSystem.client.luau
    
    Core system for managing menu buttons and their functionality.
    This system ensures proper button initialization, event handling,
    and UI integration.
    
    Features:
    - Menu button management
    - Event handling
    - UI integration
    - Error tracking
    - Integration with CoreRegistry
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxErrors = 50,
    errorRetentionTime = 3600, -- 1 hour
    maxRetries = 3,
    retryDelay = 1, -- seconds
    buttonStates = {
        enabled = "rbxassetid://8093763464", -- Replace with your enabled button asset
        disabled = "rbxassetid://8093763465", -- Replace with your disabled button asset
        hover = "rbxassetid://8093763466" -- Replace with your hover button asset
    }
}

-- Module state
local MenuButtonSystem = {
    initialized = false,
    errors = {},
    lastCheck = 0,
    buttons = {},
    buttonStates = {},
    buttonCallbacks = {}
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[MenuButtonSystem]", ...)
    end
end

-- Get ErrorHandler
local function getErrorHandler()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local handler = coreRegistry:getSystem("ErrorHandler")
        if handler then
            return handler
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("ErrorHandler") then
        local success, result = pcall(function()
            return require(core.ErrorHandler)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Get UISystem
local function getUISystem()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local system = coreRegistry:getSystem("UISystem")
        if system then
            return system
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("UISystem") then
        local success, result = pcall(function()
            return require(core.UISystem)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Create button
local function createButton(name, config)
    if not name or not config then
        return nil, "Invalid button configuration"
    end
    
    -- Check if button already exists
    if MenuButtonSystem.buttons[name] then
        return nil, "Button already exists: " .. name
    end
    
    -- Create button instance
    local button = Instance.new("ImageButton")
    button.Name = name
    button.BackgroundTransparency = 1
    button.Image = CONFIG.buttonStates.enabled
    button.Size = config.size or UDim2.new(0, 200, 0, 50)
    button.Position = config.position or UDim2.new(0.5, -100, 0.5, -25)
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Create label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Text = config.text or name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = config.textSize or 18
    label.Font = config.font or Enum.Font.GothamBold
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Parent = button
    
    -- Store button
    MenuButtonSystem.buttons[name] = button
    MenuButtonSystem.buttonStates[name] = "enabled"
    MenuButtonSystem.buttonCallbacks[name] = config.callback
    
    -- Set up event handlers
    button.MouseEnter:Connect(function()
        if MenuButtonSystem.buttonStates[name] == "enabled" then
            button.Image = CONFIG.buttonStates.hover
        end
    end)
    
    button.MouseLeave:Connect(function()
        if MenuButtonSystem.buttonStates[name] == "enabled" then
            button.Image = CONFIG.buttonStates.enabled
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        if MenuButtonSystem.buttonStates[name] == "enabled" then
            local callback = MenuButtonSystem.buttonCallbacks[name]
            if callback then
                local success, result = pcall(callback)
                if not success then
                    recordError("Button callback failed: " .. name .. " - " .. tostring(result))
                end
            end
        end
    end)
    
    return button
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(MenuButtonSystem.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #MenuButtonSystem.errors > CONFIG.maxErrors do
        table.remove(MenuButtonSystem.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #MenuButtonSystem.errors, 1, -1 do
        if MenuButtonSystem.errors[i].timestamp < cutoff then
            table.remove(MenuButtonSystem.errors, i)
        end
    end
    
    -- Report to ErrorHandler
    local errorHandler = getErrorHandler()
    if errorHandler then
        errorHandler:recordError(message, "menu_button_system", {
            timestamp = timestamp
        })
    end
    
    log("Error recorded: " .. message)
end

-- Check system health
local function checkHealth()
    local now = os.time()
    MenuButtonSystem.lastCheck = now
    
    -- Check button states
    for name, button in pairs(MenuButtonSystem.buttons) do
        if not button.Parent then
            recordError("Button missing parent: " .. name)
        end
    end
    
    return true
end

-- Initialize MenuButtonSystem
function MenuButtonSystem.initialize()
    if MenuButtonSystem.initialized then return true end
    
    log("Initializing MenuButtonSystem...")
    
    -- Get required systems
    local errorHandler = getErrorHandler()
    if not errorHandler then
        log("ErrorHandler not found, error reporting may be limited")
    end
    
    local uiSystem = getUISystem()
    if not uiSystem then
        log("UISystem not found, UI integration may be limited")
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            checkHealth()
        end
    end)
    
    MenuButtonSystem.initialized = true
    log("MenuButtonSystem initialized")
    return true
end

-- Create menu button
function MenuButtonSystem.createButton(name, config)
    local button, error = createButton(name, config)
    if not button then
        recordError(error)
    end
    return button
end

-- Set button state
function MenuButtonSystem.setState(name, state)
    local button = MenuButtonSystem.buttons[name]
    if not button then
        recordError("Button not found: " .. name)
        return false
    end
    
    if state == "enabled" then
        button.Image = CONFIG.buttonStates.enabled
        MenuButtonSystem.buttonStates[name] = "enabled"
    elseif state == "disabled" then
        button.Image = CONFIG.buttonStates.disabled
        MenuButtonSystem.buttonStates[name] = "disabled"
    else
        recordError("Invalid button state: " .. state)
        return false
    end
    
    return true
end

-- Set button callback
function MenuButtonSystem.setCallback(name, callback)
    if not MenuButtonSystem.buttons[name] then
        recordError("Button not found: " .. name)
        return false
    end
    
    MenuButtonSystem.buttonCallbacks[name] = callback
    return true
end

-- Get button
function MenuButtonSystem.getButton(name)
    return MenuButtonSystem.buttons[name]
end

-- Get button state
function MenuButtonSystem.getState(name)
    return MenuButtonSystem.buttonStates[name]
end

-- Get error count
function MenuButtonSystem.getErrorCount()
    return #MenuButtonSystem.errors
end

-- Get recent errors
function MenuButtonSystem.getRecentErrors()
    return MenuButtonSystem.errors
end

-- Force a health check
function MenuButtonSystem.forceCheck()
    return checkHealth()
end

return MenuButtonSystem 