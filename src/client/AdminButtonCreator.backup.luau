-- AdminButtonCreator.client.luau
-- Script to create the admin button that provides access to global commands
-- Created April 2025
-- Updated May 4, 2025

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Only authorized admin ID
local ADMIN_ID = 7768610061

-- Try to load the admin command implementations
local AdminCommandImplementations
pcall(function()
    if ReplicatedStorage:FindFirstChild("src") and 
       ReplicatedStorage.src:FindFirstChild("shared") and
       ReplicatedStorage.src.shared:FindFirstChild("AdminCommandImplementations") then
        AdminCommandImplementations = require(ReplicatedStorage.src.shared:FindFirstChild("AdminCommandImplementations"))
    end
end)

-- Check if player is admin
local function isAdmin()
    return LocalPlayer.UserId == ADMIN_ID
end

-- Log function with timestamp
local function log(message)
    local timestamp = os.date("%H:%M:%S")
    print("[AdminButtonCreator " .. timestamp .. "] " .. message)
end

-- Create the admin button
local function createAdminButton()
    -- Only proceed if player is admin
    if not isAdmin() then
        log("Not an admin, skipping button creation")
        return
    end
    
    -- Create a ScreenGui for the admin button
    local adminGui = Instance.new("ScreenGui")
    adminGui.Name = "AdminButtonGui"
    adminGui.ResetOnSpawn = false
    adminGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    adminGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create the button
    local adminButton = Instance.new("TextButton")
    adminButton.Name = "AdminButton"
    adminButton.Text = "🔧"
    adminButton.TextSize = 20
    adminButton.Size = UDim2.new(0, 40, 0, 40)
    adminButton.Position = UDim2.new(0, 60, 0, 10)
    adminButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60) -- Red to distinguish it
    adminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    adminButton.BorderSizePixel = 0
    adminButton.ZIndex = 10
    adminButton.Parent = adminGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = adminButton
    
    -- Create dropdown menu
    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "AdminMenu"
    menuFrame.Size = UDim2.new(0, 200, 0, 400)
    menuFrame.Position = UDim2.new(0, 60, 0, 60)
    menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    menuFrame.BorderSizePixel = 0
    menuFrame.Visible = false
    menuFrame.ZIndex = 10
    menuFrame.Parent = adminGui
    
    -- Add corner radius
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 10)
    menuCorner.Parent = menuFrame
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    title.BorderSizePixel = 0
    title.Text = "Admin Commands"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    title.TextSize = 16
    title.ZIndex = 10
    title.Parent = menuFrame
    
    -- Add corner radius to title (top corners only)
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
    
    -- Add scrollable container for buttons
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "CommandScroll"
    scrollFrame.Size = UDim2.new(1, -20, 1, -50)
    scrollFrame.Position = UDim2.new(0, 10, 0, 45)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ZIndex = 10
    scrollFrame.Parent = menuFrame
    
    -- Add layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scrollFrame
      -- Command categories and their commands
    local categories = {
        {
            name = "Tycoon Structure",
            commands = {
                {name = "Process Tycoon", func = "ProcessTycoon"},
                {name = "Automate Gym", func = "AutomateGym"},
                {name = "Show Tycoon Info", func = "ShowTycoonInfo"}
            }
        },
        {
            name = "Buy Tile System",
            commands = {
                {name = "Setup BuyTile System", func = "SetupBuyTileSystem"},
                {name = "Auto-Setup Buy Tiles", func = "AutoSetupBuyTiles"},
                {name = "Generate Build Order", func = "GenerateBuildOrder"},
                {name = "Generate BuyTile Config", func = "GenerateBuyTileConfig"}
            }
        },
        {
            name = "Visualization",
            commands = {
                {name = "Show Hitboxes", func = "ShowHitboxes"},
                {name = "Hide Hitboxes", func = "HideHitboxes"},
                {name = "Add Primary Parts", func = "AssignPrimaryParts"}
            }
        },
        {
            name = "Validation",
            commands = {
                {name = "Validate Gym Models", func = "ValidateGymModels"},
                {name = "Add Primary Parts", func = "AssignPrimaryParts"}
            }
        }
    }
    
    local currentY = 0
    
    -- Add command categories and buttons
    for _, category in ipairs(categories) do
        -- Add category label
        local catLabel = Instance.new("TextLabel")
        catLabel.Size = UDim2.new(1, 0, 0, 30)
        catLabel.BackgroundTransparency = 1
        catLabel.Text = category.name
        catLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
        catLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
        catLabel.TextSize = 14
        catLabel.TextXAlignment = Enum.TextXAlignment.Left
        catLabel.ZIndex = 10
        catLabel.Parent = scrollFrame
        
        -- Add commands for this category
        for _, command in ipairs(category.commands) do
            -- Create button
            local cmdButton = Instance.new("TextButton")
            cmdButton.Size = UDim2.new(1, -10, 0, 35)
            cmdButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
            cmdButton.BorderSizePixel = 0
            cmdButton.Text = command.name
            cmdButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            cmdButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
            cmdButton.TextSize = 14
            cmdButton.ZIndex = 10
            cmdButton.Parent = scrollFrame
            
            -- Add corner radius
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = cmdButton
            
            -- Click handler
            cmdButton.MouseButton1Click:Connect(function()
                log("Executing command: " .. command.name)
                
                -- Create a status indicator while command is processing
                local status = Instance.new("TextLabel")
                status.Name = "StatusIndicator"
                status.Size = UDim2.new(1, 0, 0, 30)
                status.Position = UDim2.new(0, 0, 1, -30)
                status.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
                status.Text = "Executing " .. command.name .. "..."
                status.TextColor3 = Color3.fromRGB(255, 255, 255)
                status.BorderSizePixel = 0
                status.ZIndex = 11
                status.Parent = menuFrame
                
                -- Remove any existing feedback
                for _, child in pairs(menuFrame:GetChildren()) do
                    if child.Name == "Feedback" and child ~= status then
                        child:Destroy()
                    end
                end
                
                -- Try to execute command with multiple fallback methods
                local success, commandResult
                
                -- Method 1: Try direct _G function
                if _G[command.func] and typeof(_G[command.func]) == "function" then
                    success, commandResult = pcall(function()
                        return _G[command.func]()
                    end)
                    print("Method 1 result - success:", success, "result:", commandResult)
                end
                
                -- Method 2: Try with loadstring if direct method failed
                if not success then
                    -- For loadstring, we use the safer approach with proper error handling
                    local loadStringSuccess, loadedFunc = pcall(function()
                        return loadstring("return _G." .. command.func .. "();")
                    end)
                    
                    if loadStringSuccess and typeof(loadedFunc) == "function" then
                        success, commandResult = pcall(loadedFunc)
                        print("Method 2 result - success:", success, "result:", commandResult)
                    end
                end
                
                -- Method 3: Try with remote if available
                if not success then
                    local adminRemotes = game:GetService("ReplicatedStorage"):FindFirstChild("AdminRemotes")
                    if adminRemotes then
                        local executeCommand = adminRemotes:FindFirstChild("ExecuteAdminCommand")
                        if executeCommand and executeCommand:IsA("RemoteFunction") then
                            success, commandResult = pcall(function()
                                return executeCommand:InvokeServer({
                                    type = command.func,
                                    params = {}
                                })
                            end)
                            print("Method 3 result - success:", success, "result:", commandResult)
                        end
                    end
                end
                
                -- Method 4: Special handling for specific commands
                if not success then
                    if AdminCommandImplementations then
                        -- Try to use the shared implementation
                        log("Trying AdminCommandImplementations for " .. command.func)
                        local implementationFuncName = string.lower(command.func:sub(1,1)) .. command.func:sub(2)
                        local implementationFunc = AdminCommandImplementations[implementationFuncName]
                        
                        if typeof(implementationFunc) == "function" then
                            success, commandResult = pcall(function()
                                return implementationFunc()
                            end)
                            log("AdminCommandImplementations result - success: " .. tostring(success) .. ", result: " .. tostring(commandResult))
                        end
                    elseif command.func == "ShowHitboxes" then
                        -- Fallback implementation for ShowHitboxes
                        log("Using fallback implementation for ShowHitboxes")
                        success, commandResult = pcall(function()
                            local hitboxesShown = 0
                            
                            for _, descendant in pairs(workspace:GetDescendants()) do
                                if descendant:IsA("BasePart") and 
                                   (string.find(descendant.Name, "Hitbox") or string.find(descendant.Name, "Collision")) and
                                   descendant.Transparency > 0.9 then
                                    
                                    if not descendant:FindFirstChild("OriginalTransparency") then
                                        local originalValue = Instance.new("NumberValue")
                                        originalValue.Name = "OriginalTransparency"
                                        originalValue.Value = descendant.Transparency
                                        originalValue.Parent = descendant
                                    end
                                    
                                    descendant.Transparency = 0.5
                                    descendant.Color = Color3.fromRGB(255, 0, 0)
                                    hitboxesShown = hitboxesShown + 1
                                end
                            end
                            
                            return "Showed " .. hitboxesShown .. " hitboxes"
                        end)
                    elseif command.func == "HideHitboxes" then
                        -- Fallback implementation for HideHitboxes
                        log("Using fallback implementation for HideHitboxes")
                        success, commandResult = pcall(function()
                            local hitboxesHidden = 0
                            
                            for _, descendant in pairs(workspace:GetDescendants()) do
                                if descendant:IsA("BasePart") and 
                                   descendant:FindFirstChild("OriginalTransparency") and
                                   (string.find(descendant.Name, "Hitbox") or string.find(descendant.Name, "Collision")) then
                                    
                                    local originalValue = descendant:FindFirstChild("OriginalTransparency")
                                    if originalValue and originalValue:IsA("NumberValue") then
                                        descendant.Transparency = originalValue.Value
                                        hitboxesHidden = hitboxesHidden + 1
                                    end
                                end
                            end
                            
                            return "Hidden " .. hitboxesHidden .. " hitboxes"
                        end)
                    elseif command.func == "AssignPrimaryParts" then
                        -- Try with the specific remote function
                        local assignPrimaryPartsRemote = game:GetService("ReplicatedStorage"):FindFirstChild("AssignPrimaryPartsRemote")
                        if assignPrimaryPartsRemote and assignPrimaryPartsRemote:IsA("RemoteFunction") then
                            success, commandResult = pcall(function()
                                                            return assignPrimaryPartsRemote:InvokeServer()
                            end)
                            log("AssignPrimaryParts remote call - success: " .. tostring(success) .. ", result: " .. tostring(commandResult))
                        else
                            log("AssignPrimaryPartsRemote not found")
                        end
                    end
                
                    -- Try with the specific remote function
                    local assignPrimaryPartsRemote = game:GetService("ReplicatedStorage"):FindFirstChild("AssignPrimaryPartsRemote")
                    local success, commandResult
                    if assignPrimaryPartsRemote and assignPrimaryPartsRemote:IsA("RemoteFunction") then
                        success, commandResult = pcall(function()
                            return assignPrimaryPartsRemote:InvokeServer()
                        end)
                        print("Method 4 (specific command) result - success:", success, "result:", commandResult)
                    end
                end
                
                -- Process result and provide feedback
                if status then
                    status:Destroy()
                end
                
                local feedback = Instance.new("TextLabel")
                feedback.Name = "Feedback"
                feedback.Size = UDim2.new(1, 0, 0, 30)
                feedback.Position = UDim2.new(0, 0, 1, -30)
                feedback.BorderSizePixel = 0
                feedback.ZIndex = 11
                feedback.Parent = menuFrame
                
                if success then
                    feedback.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
                    feedback.Text = "Success: " .. command.name
                    
                    -- If result is a string or a number, display it
                    if commandResult ~= nil then
                        if type(commandResult) == "string" or type(commandResult) == "number" or type(commandResult) == "boolean" then
                            feedback.Text = "Success: " .. tostring(commandResult)
                        elseif type(commandResult) == "table" and commandResult.message then
                            feedback.Text = "Success: " .. tostring(commandResult.message)
                        end
                    end
                else
                    feedback.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
                    feedback.Text = "Error: Command failed"
                    
                    -- Try to extract error message
                    if commandResult and type(commandResult) == "string" then
                        feedback.Text = "Error: " .. commandResult:gsub("^.+:%d+: ", "")
                    end
                end
                
                feedback.TextColor3 = Color3.fromRGB(255, 255, 255)
                
                -- Auto-remove feedback after 3 seconds
                task.delay(3, function()
                    if feedback and feedback.Parent then
                        feedback:Destroy()
                    end
                end)
            end)
        end
    end
    
    -- Update scroll frame canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    
    -- Toggle menu visibility
    adminButton.MouseButton1Click:Connect(function()
        menuFrame.Visible = not menuFrame.Visible
    end)
    
    -- Close menu when clicking elsewhere
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local menuPos = menuFrame.AbsolutePosition
            local menuSize = menuFrame.AbsoluteSize
            
            local inMenuX = mousePos.X >= menuPos.X and mousePos.X <= menuPos.X + menuSize.X
            local inMenuY = mousePos.Y >= menuPos.Y and mousePos.Y <= menuPos.Y + menuSize.Y
            
            local inButtonX = mousePos.X >= adminButton.AbsolutePosition.X and mousePos.X <= adminButton.AbsolutePosition.X + adminButton.AbsoluteSize.X
            local inButtonY = mousePos.Y >= adminButton.AbsolutePosition.Y and mousePos.Y <= adminButton.AbsolutePosition.Y + adminButton.AbsoluteSize.Y
            
            if menuFrame.Visible and not (inMenuX and inMenuY) and not (inButtonX and inButtonY) then
                menuFrame.Visible = false
            end
        end
    end)
    
    -- Make button and menu draggable
    local isDragging = false
    local dragStart
    local startPos
    
    adminButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = adminButton.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
            local delta = input.Position - dragStart
            adminButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            
            -- Update menu position
            if menuFrame.Visible then
                menuFrame.Position = UDim2.new(0, adminButton.Position.X.Offset, 0, adminButton.Position.Y.Offset + 50)
            end
        end
    end)
    
    log("Admin button created successfully")
end

-- Initialize the admin button
if isAdmin() then
    createAdminButton()
end

return {
    createAdminButton = createAdminButton
}
