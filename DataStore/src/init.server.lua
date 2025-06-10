-- DataStore Manager Pro - Main Entry Point
-- Modular initialization with granular error handling for easy debugging

local PLUGIN_INFO = {
    name = "DataStore Manager Pro",
    version = "1.0.0",
    id = "DataStoreManagerPro",
    author = "YourStudioName",
    description = "Professional DataStore management for Roblox Studio"
}

-- Debug logging system
local function debugLog(component, message, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    print(string.format("[%s] [%s] %s: %s", timestamp, level, component, message))
end

debugLog("MAIN", "Starting " .. PLUGIN_INFO.name .. " v" .. PLUGIN_INFO.version)

-- Wait for plugin context to be available
local function waitForPlugin()
    local attempts = 0
    while not plugin and attempts < 50 do -- Wait up to 5 seconds
        wait(0.1)
        attempts = attempts + 1
    end
    
    if not plugin then
        error("Plugin context not available after 5 seconds - ensure this is running as a plugin")
    end
    
    -- Check if plugin has the required methods (more reliable than typeof check)
    local requiredMethods = {"CreateToolbar", "CreateDockWidgetPluginGui"}
    for _, method in ipairs(requiredMethods) do
        if not plugin[method] or type(plugin[method]) ~= "function" then
            error("Invalid plugin context - missing required method: " .. method)
        end
    end
    
    debugLog("MAIN", "Plugin context validated successfully (type: " .. typeof(plugin) .. ")")
    return plugin
end

-- Validate plugin context
local pluginObject = waitForPlugin()

-- Service loader with detailed error reporting
local Services = {}
local serviceLoadOrder = {
    "shared.Constants",
    "shared.Utils", 
    "shared.Types",
    "core.config.PluginConfig",
    "core.error.ErrorHandler",
    "core.logging.Logger",
    "core.licensing.LicenseManager",
    "core.data.DataStoreManager",
    "core.performance.PerformanceMonitor",
    "features.explorer.DataExplorer",
    "features.validation.SchemaValidator",
    "features.analytics.PerformanceAnalyzer",
    "features.operations.BulkOperations",
    "ui.core.UIManager"
}

-- Helper function to split path
local function splitPath(path, delimiter)
    delimiter = delimiter or "."
    local result = {}
    for match in path:gmatch("([^" .. delimiter .. "]+)") do
        table.insert(result, match)
    end
    return result
end

-- Initialize services in order
for _, servicePath in ipairs(serviceLoadOrder) do
    local success, serviceModule = pcall(function()
        local pathParts = splitPath(servicePath, ".")
        local currentScript = script
        
        for _, part in ipairs(pathParts) do
            currentScript = currentScript:FindFirstChild(part)
            if not currentScript then
                error("Module not found: " .. servicePath)
            end
        end
        
        return require(currentScript)
    end)
    
    if success and serviceModule then
        -- Try to initialize if the service has an init function
        local initSuccess, serviceInstance = pcall(function()
            if serviceModule.initialize then
                return serviceModule.initialize()
            end
            return serviceModule
        end)
        
        if initSuccess then
            Services[servicePath] = serviceInstance
            debugLog("INIT", "✓ " .. servicePath .. " loaded successfully")
        else
            debugLog("INIT", "✗ " .. servicePath .. " initialization failed: " .. tostring(serviceInstance), "ERROR")
        end
    else
        debugLog("INIT", "✗ " .. servicePath .. " module load failed: " .. tostring(serviceModule), "ERROR")
    end
end

-- Set up service references after all services are loaded
if Services["features.explorer.DataExplorer"] and Services["core.data.DataStoreManager"] then
    Services["features.explorer.DataExplorer"]:setDataStoreManager(Services["core.data.DataStoreManager"])
    debugLog("INIT", "✓ DataExplorer connected to DataStoreManager")
end

-- Create plugin UI
local success, uiError = pcall(function()
    debugLog("MAIN", "Creating plugin toolbar and button...")
    local toolbar = pluginObject:CreateToolbar("DataStore Manager Pro")
    debugLog("MAIN", "Toolbar created: " .. tostring(toolbar))
    
    local button = toolbar:CreateButton(
        "DataStore Manager",
        "Open DataStore Manager Pro",
        ""
    )
    debugLog("MAIN", "Button created: " .. tostring(button))

    local widgetInfo = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Float,
        false,  -- Initially hidden
        false,  -- Don't override saved state
        1200,   -- Default width
        800,    -- Default height
        600,    -- Min width
        400     -- Min height
    )

    local widget = pluginObject:CreateDockWidgetPluginGui(PLUGIN_INFO.id, widgetInfo)
    widget.Title = PLUGIN_INFO.name
    widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Initialize main interface if UI manager loaded
    if Services["ui.core.UIManager"] then
        debugLog("MAIN", "Creating UI Manager instance...")
        local interface = Services["ui.core.UIManager"].new(widget, Services, PLUGIN_INFO)
        
        if not interface then
            debugLog("MAIN", "Failed to create UI Manager instance", "ERROR")
            return
        end
        
        button.Click:Connect(function()
            debugLog("MAIN", "Plugin button clicked! Toggling widget...")
            widget.Enabled = not widget.Enabled
            debugLog("MAIN", "Widget enabled: " .. tostring(widget.Enabled))
            if widget.Enabled and interface.refresh then
                interface:refresh()
            end
        end)
        
        debugLog("MAIN", "Button click handler connected successfully")
        
        -- Store references for cleanup
        Services._ui = {
            toolbar = toolbar,
            button = button,
            widget = widget,
            interface = interface
        }
    else
        debugLog("MAIN", "UI Manager not loaded - plugin will not function", "ERROR")
    end
end)

if not success then
    debugLog("MAIN", "UI creation failed: " .. tostring(uiError), "ERROR")
end

-- Plugin cleanup handler
pluginObject.Unloading:Connect(function()
    debugLog("MAIN", "Plugin unloading - cleaning up services")
    
    for servicePath, service in pairs(Services) do
        if service and service.cleanup then
            local cleanupSuccess, cleanupError = pcall(service.cleanup)
            if cleanupSuccess then
                debugLog("CLEANUP", "✓ " .. servicePath .. " cleaned up")
            else
                debugLog("CLEANUP", "✗ " .. servicePath .. " cleanup failed: " .. tostring(cleanupError), "ERROR")
            end
        end
    end
    
    debugLog("MAIN", "Plugin cleanup completed")
end)

debugLog("MAIN", "🎉 " .. PLUGIN_INFO.name .. " initialization completed!") 