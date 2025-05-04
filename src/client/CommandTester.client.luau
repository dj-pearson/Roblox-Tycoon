-- CommandTester.client.luau
-- A simple UI for testing command functionality
-- Created: May 4, 2025

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local ENABLE_COMMAND_TESTER = false -- Set to false to disable the tester UI
local ADMIN_ID = 7768610061

-- Only run for authorized admin and if enabled
if LocalPlayer.UserId ~= ADMIN_ID or not ENABLE_COMMAND_TESTER then
    print("Command Tester: Not running (disabled or not admin)")
    return
end

-- Create a test UI for commands
local function createTestUI()
    local testGui = Instance.new("ScreenGui")
    testGui.Name = "CommandTesterGui"
    testGui.ResetOnSpawn = false
    testGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    testGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create container frame
    local frame = Instance.new("Frame")
    frame.Name = "TestFrame"
    frame.Size = UDim2.new(0, 200, 0, 300)
    frame.Position = UDim2.new(1, -220, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.BorderSizePixel = 0
    frame.Parent = testGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    title.BorderSizePixel = 0
    title.Text = "Command Tester"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    title.TextSize = 14
    title.Parent = frame
    
    -- Add corner radius to title
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Fix bottom corners
    local bottomFix = Instance.new("Frame")
    bottomFix.Size = UDim2.new(1, 0, 0, 10)
    bottomFix.Position = UDim2.new(0, 0, 1, -10)
    bottomFix.BackgroundColor3 = title.BackgroundColor3
    bottomFix.BorderSizePixel = 0
    bottomFix.ZIndex = title.ZIndex
    bottomFix.Parent = title
    
    -- Command buttons
    local commands = {
        {name = "Show Hitboxes", func = "ShowHitboxes"},
        {name = "Hide Hitboxes", func = "HideHitboxes"},
        {name = "Add Primary Parts", func = "AssignPrimaryParts"}
    }
    
    -- Add buttons
    for i, cmd in ipairs(commands) do
        local button = Instance.new("TextButton")
        button.Name = cmd.name .. "Button"
        button.Size = UDim2.new(1, -20, 0, 30)
        button.Position = UDim2.new(0, 10, 0, 40 + (i-1) * 40)
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        button.BorderSizePixel = 0
        button.Text = cmd.name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        button.TextSize = 14
        button.Parent = frame
        
        -- Add corner radius
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = button
        
        -- Click handler
        button.MouseButton1Click:Connect(function()
            -- Status text
            local statusText = Instance.new("TextLabel")
            statusText.Name = "StatusText"
            statusText.Size = UDim2.new(1, -20, 0, 40)
            statusText.Position = UDim2.new(0, 10, 1, -50)
            statusText.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            statusText.BorderSizePixel = 0
            statusText.Text = "Executing " .. cmd.name .. "..."
            statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
            statusText.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
            statusText.TextSize = 12
            statusText.TextWrapped = true
            statusText.Parent = frame
            
            -- Add corner radius
            local statusCorner = Instance.new("UICorner")
            statusCorner.CornerRadius = UDim.new(0, 6)
            statusCorner.Parent = statusText
            
            -- Try to run the command
            print("Testing command: " .. cmd.func)
            
            local success, result
            
            -- Method 1: Direct _G access
            if _G[cmd.func] and typeof(_G[cmd.func]) == "function" then
                success, result = pcall(function()
                    return _G[cmd.func]()
                end)
                print("Direct _G call - success:", success, "result:", result)
            else
                print("No global function found for: " .. cmd.func)
                success = false
            end
            
            -- Update status text
            task.delay(1, function()
                if success then
                    statusText.Text = "Success: " .. tostring(result or "Command executed")
                    statusText.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
                else
                    statusText.Text = "Failed: " .. tostring(result or "Command failed")
                    statusText.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
                end
                
                -- Auto-remove after 5 seconds
                task.delay(5, function()
                    if statusText and statusText.Parent then
                        statusText:Destroy()
                    end
                end)
            end)
        end)
    end
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    closeButton.TextSize = 14
    closeButton.Parent = frame
    
    -- Add corner radius
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Close functionality
    closeButton.MouseButton1Click:Connect(function()
        testGui:Destroy()
    end)
    
    return testGui
end

-- Wait a bit before creating the UI to make sure other scripts have initialized
task.wait(3)
createTestUI()

print("Command tester interface created")
