-- SatisfactionButton.luau
-- Button to open the satisfaction panel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the local player
local player = Players.LocalPlayer

-- Configuration
local CONFIG = {
    buttonSize = UDim2.new(0, 40, 0, 40),
    buttonPosition = UDim2.new(1, -50, 0, 80),
    buttonColor = Color3.fromRGB(40, 40, 70),
    buttonHoverColor = Color3.fromRGB(60, 60, 100),
    iconId = "rbxassetid://3926305904", -- Member icon
    debug = false
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[Satisfaction Button]", ...)
    end
end

-- Wait for PlayerGui
local playerGui = player:WaitForChild("PlayerGui")

-- Create the button
local function createButton()
    -- Create the screen gui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SatisfactionButtonGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create the button
    local button = Instance.new("ImageButton")
    button.Name = "SatisfactionButton"
    button.Size = CONFIG.buttonSize
    button.Position = CONFIG.buttonPosition
    button.AnchorPoint = Vector2.new(1, 0)
    button.BackgroundColor3 = CONFIG.buttonColor
    button.BorderSizePixel = 0
    button.Image = CONFIG.iconId
    button.ImageColor3 = Color3.fromRGB(255, 255, 255)
    button.ImageTransparency = 0
    button.AutoButtonColor = false
    
    -- Add corner radius
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 10)
    cornerRadius.Parent = button
    
    -- Add tooltip
    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 120, 0, 30)
    tooltip.Position = UDim2.new(0, -130, 0, 5)
    tooltip.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    tooltip.BackgroundTransparency = 0.2
    tooltip.BorderSizePixel = 0
    tooltip.Font = Enum.Font.GothamSemibold
    tooltip.TextSize = 14
    tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
    tooltip.Text = "Member Satisfaction"
    tooltip.TextWrapped = true
    tooltip.Visible = false
    tooltip.ZIndex = 10
    tooltip.Parent = button
    
    -- Add corner radius to tooltip
    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 5)
    tooltipCorner.Parent = tooltip
    
    -- Add hover and click effects
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = CONFIG.buttonHoverColor
        tooltip.Visible = true
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = CONFIG.buttonColor
        tooltip.Visible = false
    end)
    
    -- Add parent hierarchy
    button.Parent = screenGui
    screenGui.Parent = playerGui
    
    return button
end

-- Connect the button to satisfaction display
local function connectButton()
    local button = createButton()
    
    -- We'll need to wait for the ClientRegistry to be ready
    task.spawn(function()
        -- Try to find existing ClientRegistry
        local clientModulesFolder = player:FindFirstChild("ClientModules")
        local ClientRegistry
        
        if clientModulesFolder then
            ClientRegistry = clientModulesFolder:FindFirstChild("ClientRegistry")
        end
        
        -- Wait until we have a ClientRegistry
        local attempts = 0
        while not ClientRegistry and attempts < 10 do
            task.wait(0.5)
            attempts = attempts + 1
            
            if clientModulesFolder then
                ClientRegistry = clientModulesFolder:FindFirstChild("ClientRegistry")
            else
                clientModulesFolder = player:FindFirstChild("ClientModules")
            end
        end
        
        -- If we still don't have a ClientRegistry, try alternative approach
        if not ClientRegistry then
            debugPrint("Couldn't find ClientRegistry through ClientModules, trying alternative...")
            
            -- Try to get it through existing client system
            local success, result = pcall(function()
                -- Look for a client-side system that might expose ClientRegistry
                local clientCoreFolder = playerGui:FindFirstChild("ClientCore")
                if clientCoreFolder and clientCoreFolder:FindFirstChild("ClientRegistry") then
                    return clientCoreFolder:FindFirstChild("ClientRegistry")
                end
                
                return nil
            end)
            
            if success and result then
                ClientRegistry = result
            end
        end
        
        -- Final fallback - use EventBridge directly
        if not ClientRegistry then
            debugPrint("Using EventBridge directly")
            
            -- Connect button click to event system
            button.MouseButton1Click:Connect(function()
                local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
                if eventBridge then
                    -- Try to find client event system
                    local clientEvent = eventBridge:FindFirstChild("ToggleSatisfactionPanel")
                    if clientEvent and clientEvent:IsA("BindableEvent") then
                        clientEvent:Fire()
                    else
                        -- Create our own bindable event
                        local newEvent = Instance.new("BindableEvent")
                        newEvent.Name = "ToggleSatisfactionPanel"
                        newEvent.Parent = eventBridge
                        newEvent:Fire()
                    end
                end
            end)
            
            return
        end
        
        -- Get the SatisfactionClient if available
        local SatisfactionClient
        if typeof(ClientRegistry.getSystem) == "function" then
            SatisfactionClient = ClientRegistry:getSystem("SatisfactionClient")
        end
        
        -- Connect button click
        button.MouseButton1Click:Connect(function()
            if SatisfactionClient and typeof(SatisfactionClient.toggleSatisfactionPanel) == "function" then
                SatisfactionClient.toggleSatisfactionPanel()
            else
                -- Fallback to event system
                local ClientEventBridge = ClientRegistry:getSystem("ClientEventBridge")
                if ClientEventBridge and typeof(ClientEventBridge.fireEvent) == "function" then
                    ClientEventBridge:fireEvent("ToggleSatisfactionPanel")
                else
                    debugPrint("Could not find ClientEventBridge")
                end
            end
        end)
    end)
end

-- Initialize
connectButton()