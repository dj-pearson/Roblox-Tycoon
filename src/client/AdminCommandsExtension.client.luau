-- AdminCommandsExtension.client.luau
--
-- Extension module that adds admin commands to the UI
--
-- Created April 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Only the authorized admin ID can access admin features
local ADMIN_ID = 7768610061

-- Log function
local function log(message)
    print("[AdminCommandsExtension] " .. message)
end

-- Check if player is admin
local function isAdmin()
    return LocalPlayer.UserId == ADMIN_ID
end

-- Create a styled button
local function createStyledButton(parent, text, position, size, callback)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Text = text
    button.Position = position
    button.Size = size
    button.Parent = parent
    button.BackgroundColor3 = Color3.fromRGB(65, 105, 225) -- Royal blue
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    button.TextSize = 14
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add click callback
    button.MouseButton1Click:Connect(callback)
    
    return button
end

local AdminCommandsExtension = {}

-- Add the admin button to DataManagementUI
function AdminCommandsExtension:InitializeAdminButton()
    -- Only proceed if player is an admin
    if not isAdmin() then 
        log("Not an admin - skipping admin button")
        return false
    end
    
    -- Find the DataManagementUI
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local dataManagementUI = playerGui:FindFirstChild("DataManagementUI")
    
    if not dataManagementUI then
        log("DataManagementUI not found")
        return false
    end
    
    -- Create a styled admin button
    local adminButton = Instance.new("TextButton")
    adminButton.Name = "AdminButton"
    adminButton.Text = "🔧"
    adminButton.TextSize = 18
    adminButton.Size = UDim2.new(0, 40, 0, 40)
    adminButton.Position = UDim2.new(0, 60, 0, 10) -- Position next to the data button
    adminButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60) -- Red to distinguish it
    adminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    adminButton.BorderSizePixel = 0
    adminButton.Parent = dataManagementUI
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = adminButton
    
    -- Create a commands menu
    local commandsFrame = Instance.new("Frame")
    commandsFrame.Name = "AdminCommandsFrame"
    commandsFrame.Size = UDim2.new(0, 250, 0, 300)
    commandsFrame.Position = UDim2.new(0, 60, 0, 60)
    commandsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    commandsFrame.BorderSizePixel = 0
    commandsFrame.Visible = false
    commandsFrame.Parent = dataManagementUI
    
    -- Add corner radius
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = commandsFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    title.BorderSizePixel = 0
    title.Text = "Admin Commands"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    title.TextSize = 16
    title.Parent = commandsFrame
    
    -- Add corner radius to title (top corners only)
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    -- Fix bottom corners
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Size = UDim2.new(1, 0, 0, 10)
    bottomFrame.Position = UDim2.new(0, 0, 1, -10)
    bottomFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    bottomFrame.BorderSizePixel = 0
    bottomFrame.ZIndex = title.ZIndex
    bottomFrame.Parent = title
    
    -- Command buttons container
    local buttonContainer = Instance.new("ScrollingFrame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -20, 1, -50)
    buttonContainer.Position = UDim2.new(0, 10, 0, 45)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.ScrollBarThickness = 6
    buttonContainer.Parent = commandsFrame
    
    -- Add button layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = buttonContainer
    
    -- Set up admin commands
    local commandButtons = {
        { name = "Process Tycoon", globalFunc = "ProcessTycoon", desc = "Process tycoon structure" },
        { name = "Automate Gym", globalFunc = "AutomateGym", desc = "Set up gym automatically" },
        { name = "Show Tycoon Info", globalFunc = "ShowTycoonInfo", desc = "Display tycoon information" },
        { name = "Setup Buy Tiles", globalFunc = "SetupBuyTileSystem", desc = "Set up buy tile system" },
        { name = "Show Hitboxes", globalFunc = "ShowHitboxes", desc = "Make hitboxes visible" },
        { name = "Hide Hitboxes", globalFunc = "HideHitboxes", desc = "Hide hitboxes" }
    }
    
    -- Create buttons for commands
    for i, cmd in ipairs(commandButtons) do
        local button = Instance.new("TextButton")
        button.Name = cmd.name .. "Button"
        button.Size = UDim2.new(1, -10, 0, 40)
        button.Text = cmd.name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        button.BorderSizePixel = 0
        button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        button.TextSize = 14
        button.Parent = buttonContainer
        
        -- Add corner radius
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = button
        
        -- Add description
        local description = Instance.new("TextLabel")
        description.Name = "Description"
        description.Size = UDim2.new(1, -20, 0, 20)
        description.Position = UDim2.new(0, 10, 0.5, 0)
        description.BackgroundTransparency = 1
        description.Text = cmd.desc
        description.TextColor3 = Color3.fromRGB(200, 200, 200)
        description.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        description.TextSize = 12
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.Parent = button
        
        -- Click handler
        button.MouseButton1Click:Connect(function()
            -- Execute global function
            local globalFunc = _G[cmd.globalFunc]
            
            if typeof(globalFunc) == "function" then
                local success, result = pcall(function()
                    return globalFunc()
                end)
                
                -- Show feedback
                local feedback = Instance.new("TextLabel")
                feedback.Name = "Feedback"
                feedback.Size = UDim2.new(1, 0, 0, 30)
                feedback.Position = UDim2.new(0, 0, 1, -30)
                feedback.BackgroundColor3 = success and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 40, 40)
                feedback.BorderSizePixel = 0
                feedback.Text = success and "Success: " .. cmd.name or "Error: Command failed"
                feedback.TextColor3 = Color3.fromRGB(255, 255, 255)
                feedback.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
                feedback.TextSize = 14
                feedback.Parent = commandsFrame
                
                -- Auto-remove feedback after 3 seconds
                task.delay(3, function()
                    if feedback and feedback.Parent then
                        feedback:Destroy()
                    end
                end)
            else
                -- Function not found
                local feedback = Instance.new("TextLabel")
                feedback.Name = "Feedback"
                feedback.Size = UDim2.new(1, 0, 0, 30)
                feedback.Position = UDim2.new(0, 0, 1, -30)
                feedback.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
                feedback.BorderSizePixel = 0
                feedback.Text = "Error: Command not found"
                feedback.TextColor3 = Color3.fromRGB(255, 255, 255)
                feedback.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
                feedback.TextSize = 14
                feedback.Parent = commandsFrame
                
                -- Auto-remove feedback after 3 seconds
                task.delay(3, function()
                    if feedback and feedback.Parent then
                        feedback:Destroy()
                    end
                end)
            end
        end)
    end
    
    -- Update canvas size
    buttonContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    
    -- Toggle functionality
    adminButton.MouseButton1Click:Connect(function()
        commandsFrame.Visible = not commandsFrame.Visible
    end)
    
    log("Admin button initialized successfully")
    return true
end

-- Initialize the extension with a delay to ensure DataManagementUI is ready
task.spawn(function()
    -- Wait for DataManagementUI to be created
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local dataManagementUI
    
    -- Try for up to 10 seconds
    for i = 1, 10 do
        dataManagementUI = playerGui:FindFirstChild("DataManagementUI")
        if dataManagementUI then
            break
        end
        task.wait(1)
    end
    
    -- Initialize if we found the UI
    if dataManagementUI then
        task.wait(1) -- Give it an extra second to fully load
        AdminCommandsExtension:InitializeAdminButton()
    else
        log("DataManagementUI not found after waiting")
    end
end)

return AdminCommandsExtension
