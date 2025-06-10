-- DataStore Plugin/init.luau

-- Plugin version information
local PluginVersion = "1.0.0"

-- Check if we're running in plugin context
local runningInPluginContext = typeof(plugin) == "Plugin"

-- Use the shared module resolver
local ModuleResolver = require(script.Parent.shared.ModuleResolver)
local resolveModule = ModuleResolver.resolveModule

-- Function to safely require modules
local function safeRequireModule(moduleName)
    local success, result = pcall(function()
        -- Try to find in server folder first
        local serverModule = script.Parent:FindFirstChild(moduleName .. ".server")
        if serverModule then
            return require(serverModule)
        end
        
        -- Try shared folder
        local sharedModule = script.Parent.shared:FindFirstChild(moduleName)
        if sharedModule then
            return require(sharedModule)
        end
        
        -- Try without extension
        local regularModule = script.Parent:FindFirstChild(moduleName)
        if regularModule then
            return require(regularModule)
        end
        
        error("Module not found: " .. moduleName)
    end)
    
    if success and result then
        return result
    else
        warn("Failed to load module: " .. moduleName .. " - " .. tostring(result))
        -- Return dummy module to prevent crashes
        return {
            initialize = function() 
                print("Dummy " .. moduleName .. " initialized")
                return true 
            end,
            createUI = function() 
                return Instance.new("Frame")
            end
        }
    end
end

-- Setup plugin UI if we're in plugin context
local toolbar, button
if runningInPluginContext then
    toolbar = plugin:CreateToolbar("DataStore Manager Pro")
    button = toolbar:CreateButton("Open DataStore Manager", "Open the DataStore Manager Pro Interface", "rbxassetid://7634658388")
end

-- Use our resolver to require modules (only core ones for now)
local DataStoreManager = safeRequireModule("DataStoreManager")
local DataExplorer = safeRequireModule("DataExplorer")

-- Define the internal state
local widgetInfo
if runningInPluginContext then
    widgetInfo = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Right,
        false, -- Floating
        false, -- Enabled by default
        800,   -- Width
        600,   -- Height
        800,   -- MinWidth
        600    -- MinHeight
    )
end

local widget
if runningInPluginContext then
    widget = plugin:CreateDockWidgetPluginGui("DataStoreManagerWidget", widgetInfo)
    widget.Title = "DataStore Manager Pro"
end

-- Initialize the core plugin components only
if DataStoreManager and DataStoreManager.initialize then
    DataStoreManager.initialize()
end

-- Set up event handlers
if button and widget then 
    button.Click:Connect(function()
        widget.Enabled = not widget.Enabled
        if widget.Enabled and widget:FindFirstChild("DataStoreExplorerFrame") == nil then
            if DataExplorer and DataExplorer.createMainGui then
                local mainFrame = DataExplorer.createMainGui(widget)
                if mainFrame then
                    mainFrame.Parent = widget
                end
            else
                -- Create basic UI if DataExplorer is not available
                local basicFrame = Instance.new("Frame")
                basicFrame.Name = "DataStoreExplorerFrame"
                basicFrame.Size = UDim2.new(1, 0, 1, 0)
                basicFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                basicFrame.Parent = widget
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 0, 50)
                label.Text = "DataStore Manager Pro - Basic Mode"
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.BackgroundTransparency = 1
                label.Parent = basicFrame
            end
        end
    end)
end

-- Expose the API for external usage (minimal for now)
local DataStoreManagerPlugin = {
    DataStoreManager = DataStoreManager,
    
    -- Core functions if available
    getData = DataStoreManager.getData,
    setData = DataStoreManager.setData,
    
    Version = PluginVersion,
    
    -- Initialize function for external calls
    initialize = function()
        print("DataStore Manager Pro initialized")
        if DataStoreManager and DataStoreManager.initialize then
            return DataStoreManager.initialize()
        end
        return true
    end
}

if not runningInPluginContext then
    print("DataStore Manager Pro loaded successfully in non-plugin context")
    print("Plugin Version:", DataStoreManagerPlugin.Version)
end

return DataStoreManagerPlugin
