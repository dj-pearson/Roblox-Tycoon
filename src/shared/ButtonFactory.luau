--[[
    ButtonFactory.luau
    
    A factory module for creating consistent buttons based on the UI_Module_Design document.
    Creates specialized buttons with appropriate icons, styling, and backend connections.
    
    Author: Updated April 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn("Failed to require module: ", module:GetFullName())
        return nil
    end
    
    return result
end

-- Find shared modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
local UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))
local IconSet = requireSafely(sharedFolder and sharedFolder:FindFirstChild("IconSet"))

-- Create fallbacks if modules not found
if not UIStyle then
    warn("UIStyle module not found, using fallback styles")
    UIStyle = {
        Colors = {
            Primary = Color3.fromRGB(0, 120, 215),
            Secondary = Color3.fromRGB(80, 150, 255),
            Danger = Color3.fromRGB(220, 50, 50),
            Success = Color3.fromRGB(40, 180, 100),
            ButtonDefault = Color3.fromRGB(60, 60, 80)
        },
        Fonts = {
            Bold = Enum.Font.GothamBold,
            Regular = Enum.Font.Gotham
        },
        TextSizes = {
            Medium = 16
        },
        Animations = {
            Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        }
    }
end

if not IconSet then
    warn("IconSet module not found, using fallback icons")
    IconSet = {
        AssetIds = {},
        createIcon = function() 
            return Instance.new("ImageLabel")
        end,
        addIconToButton = function(button) 
            return button 
        end
    }
end

-- Button Factory Module
local ButtonFactory = {}

-- Create a standard button with hover effects
function ButtonFactory.createButton(text, size, position, callback, style)
    local button = Instance.new("TextButton")
    button.Name = text:gsub(" ", "") .. "Button"
    button.Size = size or UDim2.new(0, 120, 0, 40)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BorderSizePixel = 0
    button.Text = text
    button.Font = UIStyle.Fonts.Bold
    button.TextSize = UIStyle.TextSizes.Medium
    
    -- Set color based on style
    if style == "primary" then
        button.BackgroundColor3 = UIStyle.Colors.Primary
    elseif style == "danger" then
        button.BackgroundColor3 = UIStyle.Colors.Danger
    elseif style == "success" then
        button.BackgroundColor3 = UIStyle.Colors.Success
    else
        button.BackgroundColor3 = UIStyle.Colors.ButtonDefault
    end
    
    button.TextColor3 = Color3.new(1, 1, 1)
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add hover effects
    button.AutoButtonColor = false
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.15)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, UIStyle.Animations.Fast, {
            BackgroundColor3 = style == "primary" and UIStyle.Colors.Primary 
                or style == "danger" and UIStyle.Colors.Danger
                or style == "success" and UIStyle.Colors.Success
                or UIStyle.Colors.ButtonDefault
        }):Play()
    end)
    
    -- Connect callback
    if callback and typeof(callback) == "function" then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

-- Create a button with an icon
function ButtonFactory.createIconButton(iconName, text, size, position, callback, style)
    local button = ButtonFactory.createButton(text, size, position, callback, style)
    
    -- Add padding for icon
    button.TextXAlignment = Enum.TextXAlignment.Left
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 35)
    padding.Parent = button
    
    -- Add icon
    IconSet.addIconToButton(button, iconName)
    
    return button
end

-- Create a close button that follows the standard design
function ButtonFactory.createCloseButton(parent, position, callback)
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = position or UDim2.new(1, -10, 0, 10)
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.BackgroundColor3 = UIStyle.Colors.Danger
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Font = UIStyle.Fonts.Bold
    closeButton.TextSize = 18
    closeButton.Text = "X"
    closeButton.ZIndex = 12
    closeButton.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = closeButton

    -- Default close functionality
    local defaultCallback = function()
        if parent then
            parent.Visible = false
        end
    end
    
    -- Connect callback
    closeButton.MouseButton1Click:Connect(callback or defaultCallback)
    
    return closeButton
end

-- Create a confirm button for dialogs
function ButtonFactory.createConfirmButton(text, size, position, callback)
    return ButtonFactory.createIconButton("Check", text or "Confirm", size, position, callback, "success")
end

-- Create a cancel button for dialogs
function ButtonFactory.createCancelButton(text, size, position, callback)
    return ButtonFactory.createIconButton("Close", text or "Cancel", size, position, callback, "danger")
end

-- Create a button for specific features from the UI design document
function ButtonFactory.createFeatureButton(feature, size, position, callback)
    local buttonConfig = {
        -- Main menu buttons
        Play = {
            icon = "Play",
            text = "Play",
            style = "primary",
            callback = function()
                -- Connect to GameSystem.startGame()
                if game.ReplicatedStorage:FindFirstChild("GameSystem") then
                    local gameSystem = game.ReplicatedStorage.GameSystem
                    if gameSystem:FindFirstChild("StartGame") then
                        gameSystem.StartGame:FireServer()
                    end
                end
                
                if callback then callback() end
            end
        },
        
        Alliance = {
            icon = "Alliance",
            text = "Alliance",
            style = "default"
        },
        
        Specialization = {
            icon = "StaffManagement",
            text = "Specialization",
            style = "default"
        },
        
        SeasonalEvents = {
            icon = "Calendar",
            text = "Seasonal Events",
            style = "default"
        },
        
        Settings = {
            icon = "Settings",
            text = "Settings",
            style = "default"
        },
        
        Minigames = {
            icon = "Challenges",
            text = "Minigames",
            style = "default"
        },
        
        -- General buttons
        Tutorial = {
            icon = "Tutorial",
            text = "Tutorial",
            style = "default",
            callback = function()
                -- Connect to TutorialSystem.showTutorial()
                if game.ReplicatedStorage:FindFirstChild("TutorialSystem") then
                    local tutorialSystem = game.ReplicatedStorage.TutorialSystem
                    if tutorialSystem:FindFirstChild("ShowTutorial") then
                        tutorialSystem.ShowTutorial:FireServer()
                    end
                end
                
                if callback then callback() end
            end
        },
        
        Reset = {
            icon = "Warning",
            text = "Reset Game",
            style = "danger",
            callback = function()
                -- Create confirmation dialog
                local confirmed = false
                
                -- TODO: Add confirmation dialog implementation
                
                -- Only proceed if confirmed
                if confirmed and game.ReplicatedStorage:FindFirstChild("GameSystem") then
                    local gameSystem = game.ReplicatedStorage.GameSystem
                    if gameSystem:FindFirstChild("Reset") then
                        gameSystem.Reset:FireServer()
                    end
                end
                
                if callback then callback() end
            end
        },
        
        -- Alliance buttons
        JoinAlliance = {
            icon = "Alliance",
            text = "Join Alliance",
            style = "primary",
            callback = function()
                -- Connect to AllianceSystem.joinAlliance()
                if game.ReplicatedStorage:FindFirstChild("AllianceSystem") then
                    local allianceSystem = game.ReplicatedStorage.AllianceSystem
                    if allianceSystem:FindFirstChild("JoinAlliance") then
                        allianceSystem.JoinAlliance:FireServer()
                    end
                end
                
                if callback then callback() end
            end
        },
        
        LeaveAlliance = {
            icon = "Remove",
            text = "Leave Alliance",
            style = "danger",
            callback = function()
                -- Create confirmation dialog
                local confirmed = false
                
                -- TODO: Add confirmation dialog implementation
                
                -- Only proceed if confirmed
                if confirmed and game.ReplicatedStorage:FindFirstChild("AllianceSystem") then
                    local allianceSystem = game.ReplicatedStorage.AllianceSystem
                    if allianceSystem:FindFirstChild("LeaveAlliance") then
                        allianceSystem.LeaveAlliance:FireServer()
                    end
                end
                
                if callback then callback() end
            end
        },
        
        ViewAllianceInfo = {
            icon = "Info",
            text = "Alliance Info",
            style = "default",
            callback = function()
                -- Connect to AllianceSystem.getAllianceInfo()
                if game.ReplicatedStorage:FindFirstChild("AllianceSystem") then
                    local allianceSystem = game.ReplicatedStorage.AllianceSystem
                    if allianceSystem:FindFirstChild("GetAllianceInfo") then
                        allianceSystem.GetAllianceInfo:FireServer()
                    end
                end
                
                if callback then callback() end
            end
        },
        
        -- Rebirth button
        Rebirth = {
            icon = "Rebirth",
            text = "Rebirth",
            style = "primary",
            callback = function()
                -- Connect to RebirthSystem.performRebirth()
                if game.ReplicatedStorage:FindFirstChild("RebirthSystem") then
                    local rebirthSystem = game.ReplicatedStorage.RebirthSystem
                    if rebirthSystem:FindFirstChild("PerformRebirth") then
                        rebirthSystem.PerformRebirth:FireServer()
                    end
                end
                
                if callback then callback() end
            end
        },
        
        -- Seasonal event buttons
        JoinEvent = {
            icon = "Calendar",
            text = "Join Event",
            style = "primary",
            callback = function()
                -- Connect to SeasonalSystem.joinEvent()
                if game.ReplicatedStorage:FindFirstChild("SeasonalSystem") then
                    local seasonalSystem = game.ReplicatedStorage.SeasonalSystem
                    if seasonalSystem:FindFirstChild("JoinEvent") then
                        seasonalSystem.JoinEvent:FireServer()
                    end
                end
                
                if callback then callback() end
            end
        },
        
        LeaveEvent = {
            icon = "Remove",
            text = "Leave Event",
            style = "danger",
            callback = function()
                -- Connect to SeasonalSystem.leaveEvent()
                if game.ReplicatedStorage:FindFirstChild("SeasonalSystem") then
                    local seasonalSystem = game.ReplicatedStorage.SeasonalSystem
                    if seasonalSystem:FindFirstChild("LeaveEvent") then
                        seasonalSystem.LeaveEvent:FireServer()
                    end
                end
                
                if callback then callback() end
            end
        },
        
        -- Default configuration if feature not found
        default = {
            icon = "Settings",
            text = feature,
            style = "default"
        }
    }
    
    -- Get configuration or default
    local config = buttonConfig[feature] or buttonConfig.default
    
    -- Create the button
    local button = ButtonFactory.createIconButton(
        config.icon,
        config.text,
        size,
        position,
        function()
            -- Call the feature's callback if it exists
            if config.callback then
                config.callback()
            end
            
            -- Call the provided callback if it exists
            if callback then
                callback()
            end
        end,
        config.style
    )
    
    return button
end

-- Create a specialized button (factory method that routes to appropriate button creation)
function ButtonFactory.createSpecializedButton(buttonType, text, size, position, callback)
    if buttonType == "close" then
        return ButtonFactory.createCloseButton(nil, position, callback)
    elseif buttonType == "confirm" then
        return ButtonFactory.createConfirmButton(text, size, position, callback)
    elseif buttonType == "cancel" then
        return ButtonFactory.createCancelButton(text, size, position, callback)
    elseif buttonType == "feature" then
        return ButtonFactory.createFeatureButton(text, size, position, callback)
    else
        -- Default to standard button
        return ButtonFactory.createButton(text, size, position, callback)
    end
end

-- Create a toggle button (on/off state)
function ButtonFactory.createToggleButton(text, isOn, size, position, callback)
    local button = Instance.new("TextButton")
    button.Name = text:gsub(" ", "") .. "ToggleButton"
    button.Size = size or UDim2.new(0, 60, 0, 30)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BorderSizePixel = 0
    button.Text = isOn and "ON" or "OFF"
    button.Font = UIStyle.Fonts.Bold
    button.TextSize = UIStyle.TextSizes.Medium
    button.TextColor3 = Color3.new(1, 1, 1)
    
    -- Set initial state
    button.BackgroundColor3 = isOn and UIStyle.Colors.Success or Color3.fromRGB(100, 100, 100)
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = button
    
    -- Track toggle state
    local toggleState = isOn
    
    -- Connect click handler
    button.MouseButton1Click:Connect(function()
        toggleState = not toggleState
        
        -- Update visual state
        button.Text = toggleState and "ON" or "OFF"
        button.BackgroundColor3 = toggleState and UIStyle.Colors.Success or Color3.fromRGB(100, 100, 100)
        
        -- Call callback with new state
        if callback then
            callback(toggleState)
        end
    end)
    
    -- Create API for the toggle button
    local api = {
        instance = button,
        getState = function()
            return toggleState
        end,
        setState = function(state)
            toggleState = state
            button.Text = toggleState and "ON" or "OFF"
            button.BackgroundColor3 = toggleState and UIStyle.Colors.Success or Color3.fromRGB(100, 100, 100)
        end
    }
    
    return api
end

return ButtonFactory