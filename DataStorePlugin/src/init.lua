-- DataStore Manager Pro Plugin
-- Main plugin entry point

print("DataStore Manager Pro Plugin Loading...")

-- Check if we're running in plugin context
local runningInPluginContext = typeof(plugin) == "Plugin"

if runningInPluginContext then
    -- Create toolbar and button
    local toolbar = plugin:CreateToolbar("DataStore Manager Pro")
    local button = toolbar:CreateButton(
        "Open DataStore Manager",
        "Open the DataStore Manager Pro Interface",
        "rbxassetid://7634658388"
    )

    -- Create widget
    local widgetInfo = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Right,
        false, -- Floating
        false, -- Enabled by default
        800,   -- Width
        600,   -- Height
        800,   -- MinWidth
        600    -- MinHeight
    )

    local widget = plugin:CreateDockWidgetPluginGui("DataStoreManagerWidget", widgetInfo)
    widget.Title = "DataStore Manager Pro"

    -- Set up button click handler
    button.Click:Connect(function()
        widget.Enabled = not widget.Enabled
        
        if widget.Enabled and not widget:FindFirstChild("MainFrame") then
            -- Create basic UI
            local mainFrame = Instance.new("Frame")
            mainFrame.Name = "MainFrame"
            mainFrame.Size = UDim2.new(1, 0, 1, 0)
            mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            mainFrame.BorderSizePixel = 0
            mainFrame.Parent = widget
            
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 50)
            title.Text = "DataStore Manager Pro v1.0.0"
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            title.BorderSizePixel = 0
            title.Font = Enum.Font.SourceSansBold
            title.TextSize = 18
            title.Parent = mainFrame
            
            local statusLabel = Instance.new("TextLabel")
            statusLabel.Position = UDim2.new(0, 10, 0, 60)
            statusLabel.Size = UDim2.new(1, -20, 0, 30)
            statusLabel.Text = "Plugin successfully loaded! Basic UI active."
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            statusLabel.BackgroundTransparency = 1
            statusLabel.Font = Enum.Font.SourceSans
            statusLabel.TextSize = 14
            statusLabel.TextXAlignment = Enum.TextXAlignment.Left
            statusLabel.Parent = mainFrame
            
            print("DataStore Manager Pro UI Created")
        end
    end)
    
    print("DataStore Manager Pro Plugin Initialized Successfully")
else
    print("DataStore Manager Pro loaded in non-plugin context")
end

-- Return basic plugin info
return {
    Name = "DataStore Manager Pro",
    Version = "1.0.0",
    Status = "Loaded"
}
