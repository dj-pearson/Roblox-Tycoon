-- EmergencyAdminButton.client.luau
-- Simplified admin button for when main UI systems are degraded
-- Created May 4, 2025

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Admin configuration
local ADMIN_IDS = {
    7768610061, -- Main admin ID
}

-- Check if player is admin
local function isAdmin()
    for _, id in ipairs(ADMIN_IDS) do
        if LocalPlayer.UserId == id then
            return true
        end
    end
    return false
end

-- Log function with timestamp
local function log(message)
    local timestamp = os.date("%H:%M:%S")
    print("[EmergencyAdminButton " .. timestamp .. "] " .. message)
end

-- Create the UI for admin commands
local function createEmergencyAdminUI()
    log("Creating emergency admin UI")
    
    -- Main ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "EmergencyAdminUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create the admin button
    local adminButton = Instance.new("TextButton")
    adminButton.Name = "AdminButton"
    adminButton.Size = UDim2.new(0, 50, 0, 50)
    adminButton.Position = UDim2.new(1, -60, 0, 10)
    adminButton.AnchorPoint = Vector2.new(0, 0)
    adminButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    adminButton.Text = "A"
    adminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    adminButton.TextSize = 24
    adminButton.BorderSizePixel = 0
    adminButton.ZIndex = 10
    adminButton.Parent = gui
    
    -- Add rounded corners to button
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = adminButton
    
    -- Create menu frame (initially hidden)
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "AdminMenu"
    menuFrame.Size = UDim2.new(0, 300, 0, 400)
    menuFrame.Position = UDim2.new(1, -310, 0, 70)
    menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    menuFrame.BorderSizePixel = 0
    menuFrame.Visible = false
    menuFrame.ZIndex = 9
    menuFrame.Parent = gui
    
    -- Add rounded corners to menu
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 10)
    menuCorner.Parent = menuFrame
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    title.BorderSizePixel = 0
    title.Text = "Emergency Admin Commands"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    title.TextSize = 16
    title.ZIndex = 10
    title.Parent = menuFrame
    
    -- Add rounded corners to title
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Create a scrolling frame for buttons
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "CommandsScroll"
    scrollFrame.Size = UDim2.new(1, -20, 1, -50)
    scrollFrame.Position = UDim2.new(0, 10, 0, 45)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ZIndex = 10
    scrollFrame.Parent = menuFrame
    
    -- Add layout for buttons
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scrollFrame
    
    -- Emergency commands to include (very basic, guaranteed to work functions)
    local emergencyCommands = {
        { name = "Show Hitboxes", func = function()
            local hitboxesShown = 0
            for _, descendant in pairs(workspace:GetDescendants()) do
                if descendant:IsA("BasePart") and 
                  (string.find(descendant.Name, "Hitbox") or string.find(descendant.Name, "Collision")) and
                  descendant.Transparency > 0.9 then
                    
                    -- Store original transparency
                    if not descendant:FindFirstChild("OriginalTransparency") then
                        local originalValue = Instance.new("NumberValue")
                        originalValue.Name = "OriginalTransparency"
                        originalValue.Value = descendant.Transparency
                        originalValue.Parent = descendant
                    end
                    
                    -- Make hitbox visible
                    descendant.Transparency = 0.5
                    descendant.Color = Color3.fromRGB(255, 0, 0) -- Red for visualization
                    hitboxesShown = hitboxesShown + 1
                end
            end
            return "Showed " .. hitboxesShown .. " hitboxes"
        end},
        
        { name = "Hide Hitboxes", func = function()
            local hitboxesHidden = 0
            for _, descendant in pairs(workspace:GetDescendants()) do
                if descendant:IsA("BasePart") and 
                   descendant:FindFirstChild("OriginalTransparency") and
                   (string.find(descendant.Name, "Hitbox") or string.find(descendant.Name, "Collision")) then
                    
                    -- Restore original transparency
                    local originalValue = descendant:FindFirstChild("OriginalTransparency")
                    if originalValue and originalValue:IsA("NumberValue") then
                        descendant.Transparency = originalValue.Value
                        hitboxesHidden = hitboxesHidden + 1
                    end
                end
            end
            return "Hidden " .. hitboxesHidden .. " hitboxes"
        end},
        
        { name = "Add Primary Parts", func = function()
            local targetFolder = workspace:FindFirstChild("GymParts")
            if not targetFolder then
                return "GymParts folder not found in workspace"
            end
            
            local modelsProcessed = 0
            local modelsUpdated = 0
            
            local function addPrimaryPart(model)
                if not model:IsA("Model") then return false end
                modelsProcessed = modelsProcessed + 1
                
                if model.PrimaryPart then return false end
                
                local modelCFrame, modelSize = model:GetBoundingBox()
                local refPart = Instance.new("Part")
                refPart.Name = "PrimaryReference"
                refPart.Size = Vector3.new(1, 1, 1)
                refPart.Transparency = 1
                refPart.CanCollide = false
                refPart.Anchored = true
                refPart.CFrame = modelCFrame
                refPart.Parent = model
                model.PrimaryPart = refPart
                
                modelsUpdated = modelsUpdated + 1
                return true
            end
            
            for _, child in pairs(targetFolder:GetChildren()) do
                if child:IsA("Model") then
                    addPrimaryPart(child)
                end
            end
            
            return "Processed " .. modelsProcessed .. " models, added primary parts to " .. modelsUpdated
        end},
        
        { name = "Reset UI Scale", func = function()
            for _, player in pairs(Players:GetPlayers()) do
                local pGui = player:FindFirstChild("PlayerGui")
                if pGui then
                    for _, gui in pairs(pGui:GetChildren()) do
                        if gui:IsA("ScreenGui") and gui:FindFirstChild("UIScale") then
                            gui.UIScale.Scale = 1
                        end
                    end
                end
            end
            return "Reset UI scales to 1"
        end},
        
        { name = "Destroy Degraded UIs", func = function() 
            local removedUIs = 0
            for _, player in pairs(Players:GetPlayers()) do
                local pGui = player:FindFirstChild("PlayerGui")
                if pGui then
                    for _, gui in pairs(pGui:GetChildren()) do
                        if gui:IsA("ScreenGui") and (
                           gui.Name:find("Degraded") or
                           gui.Name:find("Broken") or
                           gui.Name:find("Old") or
                           gui.Name == "DataManagementUI"
                        ) then
                            gui:Destroy()
                            removedUIs = removedUIs + 1
                        end
                    end
                end
            end
            return "Removed " .. removedUIs .. " potentially broken UIs"
        end},
        
        { name = "Emergency Reload", func = function()
            local success = false
            
            for _, service in pairs({game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")}) do
                for _, child in pairs(service:GetDescendants()) do
                    if child:IsA("ModuleScript") and (
                       child.Name:find("Loader") or
                       child.Name:find("Initializer") or
                       child.Name:find("Bootstrap")
                    ) then
                        pcall(function() require(child) end)
                        success = true
                    end
                end
            end
            
            return success and "Attempted emergency reload of critical systems" or "Failed to find loader scripts"
        end}
    }
    
    -- Create command buttons
    for i, command in ipairs(emergencyCommands) do
        local button = Instance.new("TextButton")
        button.Name = command.name .. "Button"
        button.Size = UDim2.new(1, 0, 0, 40)
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        button.BorderSizePixel = 0
        button.Text = command.name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        button.TextSize = 14
        button.ZIndex = 10
        button.LayoutOrder = i
        button.Parent = scrollFrame
        
        -- Add rounded corners to button
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- Handle button click
        button.MouseButton1Click:Connect(function()
            log("Executing emergency command: " .. command.name)
            
            -- Create status feedback
            local feedback = Instance.new("TextLabel")
            feedback.Name = "Feedback"
            feedback.Size = UDim2.new(1, 0, 0, 30)
            feedback.Position = UDim2.new(0, 0, 1, -30)
            feedback.BorderSizePixel = 0
            feedback.TextColor3 = Color3.fromRGB(255, 255, 255)
            feedback.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
            feedback.TextSize = 14
            feedback.ZIndex = 11
            feedback.Parent = menuFrame
            
            -- Execute command with error handling
            local success, result = pcall(command.func)
            
            if success then
                feedback.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
                feedback.Text = "Success: " .. tostring(result)
            else
                feedback.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
                feedback.Text = "Error: " .. tostring(result)
            end
            
            -- Auto-remove feedback after 3 seconds
            task.delay(3, function()
                if feedback and feedback.Parent then
                    feedback:Destroy()
                end
            end)
        end)
    end
    
    -- Update scroll frame canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    
    -- Toggle menu visibility when button is clicked
    adminButton.MouseButton1Click:Connect(function()
        menuFrame.Visible = not menuFrame.Visible
    end)
    
    -- Close menu when clicking outside
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and menuFrame.Visible then
            local mousePos = UserInputService:GetMouseLocation()
            local inButtonX = mousePos.X >= adminButton.AbsolutePosition.X and mousePos.X <= adminButton.AbsolutePosition.X + adminButton.AbsoluteSize.X
            local inButtonY = mousePos.Y >= adminButton.AbsolutePosition.Y and mousePos.Y <= adminButton.AbsolutePosition.Y + adminButton.AbsoluteSize.Y
            
            local inMenuX = mousePos.X >= menuFrame.AbsolutePosition.X and mousePos.X <= menuFrame.AbsolutePosition.X + menuFrame.AbsoluteSize.X
            local inMenuY = mousePos.Y >= menuFrame.AbsolutePosition.Y and mousePos.Y <= menuFrame.AbsolutePosition.Y + menuFrame.AbsoluteSize.Y
            
            if not (inButtonX and inButtonY) and not (inMenuX and inMenuY) then
                menuFrame.Visible = false
            end
        end
    end)
    
    -- Make button draggable
    local isDragging = false
    local dragStart
    local startPos
    
    adminButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = adminButton.Position
        end
    end)
    
    adminButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            adminButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            
            -- Update menu position to follow button
            menuFrame.Position = UDim2.new(0, adminButton.AbsolutePosition.X - menuFrame.AbsoluteSize.X + adminButton.AbsoluteSize.X, 
                                          0, adminButton.AbsolutePosition.Y + adminButton.AbsoluteSize.Y + 10)
        end
    end)
    
    -- Parent the GUI to PlayerGui
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    log("Emergency admin UI created successfully")
    return gui
end

-- Create the emergency admin button only if player is admin
if isAdmin() then
    log("Admin detected, creating emergency admin button")
    createEmergencyAdminUI()
else
    log("Not an admin, skipping emergency admin button")
end
