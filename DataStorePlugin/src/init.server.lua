-- DataStore Manager Pro Plugin
-- Main plugin entry point

print("DataStore Manager Pro Plugin Loading...")

-- Check plugin availability with detailed debugging
print("Plugin type check:", typeof(plugin))
print("Plugin object:", plugin)

local runningInPluginContext = typeof(plugin) == "Plugin"
print("Running in plugin context:", runningInPluginContext)

if runningInPluginContext then
    print("Attempting to create toolbar...")
    
    local success, toolbar = pcall(function()
        return plugin:CreateToolbar("DataStore Manager Pro")
    end)
    
    if not success then
        warn("Failed to create toolbar:", toolbar)
        return
    end
    
    print("Toolbar created successfully:", toolbar)
    
    local buttonSuccess, button = pcall(function()
        return toolbar:CreateButton(
            "DataStore Manager", -- Name
            "Open the DataStore Manager Pro Interface", -- Tooltip
            "" -- Empty icon to avoid asset issues
        )
    end)
    
    if not buttonSuccess then
        warn("Failed to create button:", button)
        return
    end
    
    print("Button created successfully:", button)

    -- Create widget with error handling
    local widgetSuccess, widget = pcall(function()
        local widgetInfo = DockWidgetPluginGuiInfo.new(
            Enum.InitialDockState.Right,
            false, -- Floating
            false, -- Enabled by default
            800,   -- Width
            600,   -- Height
            800,   -- MinWidth
            600    -- MinHeight
        )
        return plugin:CreateDockWidgetPluginGui("DataStoreManagerWidget", widgetInfo)
    end)
    
    if not widgetSuccess then
        warn("Failed to create widget:", widget)
        return
    end
    
    widget.Title = "DataStore Manager Pro"
    print("Widget created successfully:", widget)

    -- Set up button click handler
    local connectionSuccess, connection = pcall(function()
        return button.Click:Connect(function()
            print("Button clicked! Toggling widget...")
            widget.Enabled = not widget.Enabled
            print("Widget enabled:", widget.Enabled)
            
            if widget.Enabled and not widget:FindFirstChild("MainFrame") then
                print("Creating UI...")
                
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
                
                -- Add DataStore functionality section
                local dsSection = Instance.new("Frame")
                dsSection.Position = UDim2.new(0, 10, 0, 100)
                dsSection.Size = UDim2.new(1, -20, 0, 200)
                dsSection.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                dsSection.BorderSizePixel = 1
                dsSection.BorderColor3 = Color3.fromRGB(80, 80, 80)
                dsSection.Parent = mainFrame
                
                local dsTitle = Instance.new("TextLabel")
                dsTitle.Size = UDim2.new(1, 0, 0, 30)
                dsTitle.Text = "DataStore Operations"
                dsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                dsTitle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                dsTitle.BorderSizePixel = 0
                dsTitle.Font = Enum.Font.SourceSansBold
                dsTitle.TextSize = 14
                dsTitle.Parent = dsSection
                
                local testButton = Instance.new("TextButton")
                testButton.Position = UDim2.new(0, 10, 0, 40)
                testButton.Size = UDim2.new(0, 150, 0, 30)
                testButton.Text = "Test DataStore Access"
                testButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                testButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
                testButton.BorderSizePixel = 0
                testButton.Font = Enum.Font.SourceSans
                testButton.TextSize = 12
                testButton.Parent = dsSection
                
                -- Add test functionality
                testButton.MouseButton1Click:Connect(function()
                    print("Testing DataStore access...")
                    local DataStoreService = game:GetService("DataStoreService")
                    local success, error = pcall(function()
                        local testDS = DataStoreService:GetDataStore("TestStore")
                        print("DataStore access successful!")
                    end)
                    
                    if success then
                        testButton.Text = "✓ DataStore OK"
                        testButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                    else
                        testButton.Text = "✗ DataStore Error"
                        testButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
                        warn("DataStore test failed:", error)
                    end
                end)
                
                print("DataStore Manager Pro UI Created")
            end
        end)
    end)
    
    if not connectionSuccess then
        warn("Failed to connect button click:", connection)
        return
    end
    
    print("DataStore Manager Pro Plugin Initialized Successfully")
    print("Look for 'DataStore Manager' button in the toolbar!")
    
else
    print("DataStore Manager Pro loaded in non-plugin context")
    print("This might happen if the script is loaded as a regular script instead of a plugin")
    print("Try installing the plugin in the Plugins folder and restarting Studio")
end
