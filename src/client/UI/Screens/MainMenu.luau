--!strict
--[[
    MainMenu.luau
    
    Main menu screen implementation.
    Demonstrates usage of UIComponent base class.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the base UI component
local UIComponent = require(script.Parent.Parent.Core.UIComponent)

-- Create MainMenu class
local MainMenu = setmetatable({}, {__index = UIComponent})
MainMenu.__index = MainMenu

-- Constructor
function MainMenu.new()
    local self = setmetatable(UIComponent.new("MainMenu"), MainMenu)
    return self
end

-- Override create method
function MainMenu:create()
    -- Call base create method
    local success = UIComponent.create(self)
    if not success then
        return nil
    end
    
    -- Create UI elements
    self:createBackground()
    self:createTitle()
    self:createButtons()
    
    return self.instance
end

-- Create background
function MainMenu:createBackground()
    -- Create background frame
    local background = self:createFrame({
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BackgroundTransparency = 0
    })
    
    -- Add gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 35))
    })
    gradient.Rotation = 45
    gradient.Parent = background
end

-- Create title
function MainMenu:createTitle()
    -- Create title container
    local titleContainer = self:createFrame({
        Name = "TitleContainer",
        Size = UDim2.new(1, 0, 0, 120),
        Position = UDim2.new(0, 0, 0.1, 0),
        BackgroundTransparency = 1
    })
    
    -- Create game title
    local gameTitle = self:createLabel({
        Name = "GameTitle",
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "My Awesome Game",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 48
    })
    
    -- Create subtitle
    local subtitle = self:createLabel({
        Name = "Subtitle",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 70),
        Text = "Welcome to the adventure!",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Font = Enum.Font.Gotham,
        TextSize = 24
    })
end

-- Create buttons
function MainMenu:createButtons()
    -- Create button container
    local buttonContainer = self:createFrame({
        Name = "ButtonContainer",
        Size = UDim2.new(0, 300, 0, 300),
        Position = UDim2.new(0.5, -150, 0.5, -150),
        BackgroundTransparency = 1
    })
    
    -- Create play button
    local playButton = self:createButton({
        Name = "PlayButton",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Play",
        BackgroundColor3 = Color3.fromRGB(114, 137, 218),
        TextSize = 24
    })
    
    -- Create settings button
    local settingsButton = self:createButton({
        Name = "SettingsButton",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 70),
        Text = "Settings",
        BackgroundColor3 = Color3.fromRGB(50, 53, 59),
        TextSize = 24
    })
    
    -- Create credits button
    local creditsButton = self:createButton({
        Name = "CreditsButton",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 140),
        Text = "Credits",
        BackgroundColor3 = Color3.fromRGB(50, 53, 59),
        TextSize = 24
    })
    
    -- Create quit button
    local quitButton = self:createButton({
        Name = "QuitButton",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 210),
        Text = "Quit",
        BackgroundColor3 = Color3.fromRGB(231, 76, 60),
        TextSize = 24
    })
    
    -- Add button hover effects
    local function setupButtonHover(button, hoverColor)
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = hoverColor:Lerp(Color3.new(1, 1, 1), 0.2)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = hoverColor
        end)
    end
    
    setupButtonHover(playButton, Color3.fromRGB(114, 137, 218))
    setupButtonHover(settingsButton, Color3.fromRGB(50, 53, 59))
    setupButtonHover(creditsButton, Color3.fromRGB(50, 53, 59))
    setupButtonHover(quitButton, Color3.fromRGB(231, 76, 60))
    
    -- Add button click handlers
    playButton.MouseButton1Click:Connect(function()
        -- TODO: Implement play functionality
        print("Play button clicked")
    end)
    
    settingsButton.MouseButton1Click:Connect(function()
        -- TODO: Implement settings functionality
        print("Settings button clicked")
    end)
    
    creditsButton.MouseButton1Click:Connect(function()
        -- TODO: Implement credits functionality
        print("Credits button clicked")
    end)
    
    quitButton.MouseButton1Click:Connect(function()
        -- TODO: Implement quit functionality
        print("Quit button clicked")
    end)
end

-- Override update method
function MainMenu:update()
    -- Call base update method
    local success = UIComponent.update(self)
    if not success then
        return false
    end
    
    -- Update UI elements based on state
    -- TODO: Implement state-based updates
    
    return true
end

return MainMenu 