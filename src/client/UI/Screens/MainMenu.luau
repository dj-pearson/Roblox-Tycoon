--!strict
--[[
    MainMenu.luau
    
    Main menu screen implementation.
    Demonstrates usage of UIComponent base class and UIUtils.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the module loader
local ModuleLoader = require(script.Parent.Parent.Core.ModuleLoader)

-- Load required modules
local UIComponent = ModuleLoader.loadCore("UIComponent")
local UITransitions = ModuleLoader.loadCore("UITransitions")
local UIUtils = ModuleLoader.loadCore("UIUtils")

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
    -- Create background frame with gradient
    local background = UIUtils.createFrame(self.instance, {
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = UIUtils.Colors.Background,
        BackgroundTransparency = 0
    })
    
    -- Add gradient
    local gradient = UIUtils.createGradient(background, {
        Colors = {
            ColorSequenceKeypoint.new(0, UIUtils.Colors.Background:Lerp(UIUtils.Colors.Primary, 0.1)),
            ColorSequenceKeypoint.new(1, UIUtils.Colors.Background)
        },
        Rotation = 45
    })
end

-- Create title
function MainMenu:createTitle()
    local title = UIUtils.createLabel(self.instance, {
        Name = "Title",
        Size = UDim2.new(0, 400, 0, 80),
        Position = UDim2.new(0.5, 0, 0.2, 0),
        Text = "Main Menu",
        TextColor3 = UIUtils.Colors.Text,
        Font = UIUtils.Fonts.Title,
        TextSize = UIUtils.TextSizes.Title,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    
    -- Add hover effect
    UIUtils.setupButtonHover(title, UIUtils.Colors.Text, UIUtils.Colors.Primary)
end

-- Create buttons
function MainMenu:createButtons()
    -- Create button container with vertical layout
    local buttonContainer = UIUtils.createFrame(self.instance, {
        Name = "ButtonContainer",
        Size = UDim2.new(0, 300, 0, 300),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Layout = UIUtils.Layouts.Vertical
    })
    
    -- Create play button
    local playButton = UIUtils.createButton(buttonContainer, {
        Name = "PlayButton",
        Size = UDim2.new(0.8, 0, 0, 50),
        Text = "Play",
        BackgroundColor3 = UIUtils.Colors.Primary
    })
    
    -- Add hover effect
    UIUtils.setupButtonHover(playButton, UIUtils.Colors.Primary, UIUtils.Colors.Primary:Lerp(UIUtils.Colors.Hover, 0.3))
    
    -- Add click handler
    playButton.MouseButton1Click:Connect(function()
        -- TODO: Start game
    end)
    
    -- Create settings button
    local settingsButton = UIUtils.createButton(buttonContainer, {
        Name = "SettingsButton",
        Size = UDim2.new(0.8, 0, 0, 50),
        Text = "Settings",
        BackgroundColor3 = UIUtils.Colors.Secondary
    })
    
    -- Add hover effect
    UIUtils.setupButtonHover(settingsButton, UIUtils.Colors.Secondary, UIUtils.Colors.Secondary:Lerp(UIUtils.Colors.Hover, 0.3))
    
    -- Add click handler
    settingsButton.MouseButton1Click:Connect(function()
        -- TODO: Show settings
    end)
    
    -- Create quit button
    local quitButton = UIUtils.createButton(buttonContainer, {
        Name = "QuitButton",
        Size = UDim2.new(0.8, 0, 0, 50),
        Text = "Quit",
        BackgroundColor3 = UIUtils.Colors.Error
    })
    
    -- Add hover effect
    UIUtils.setupButtonHover(quitButton, UIUtils.Colors.Error, UIUtils.Colors.Error:Lerp(UIUtils.Colors.Hover, 0.3))
    
    -- Add click handler
    quitButton.MouseButton1Click:Connect(function()
        -- TODO: Quit game
    end)
end

-- Override show method
function MainMenu:show()
    -- Call base show method
    local success = UIComponent.show(self)
    if not success then
        return false
    end
    
    -- Show with animation
    UITransitions.fadeAndSlideIn(self.instance, UIUtils.Animations.Default.Time)
    
    return true
end

-- Override hide method
function MainMenu:hide()
    -- Hide with animation
    UITransitions.fadeAndSlideOut(self.instance, UIUtils.Animations.Default.Time, function()
        -- Call base hide method
        UIComponent.hide(self)
    end)
    
    return true
end

-- Override update method
function MainMenu:update()
    -- Call base update method
    local success = UIComponent.update(self)
    if not success then
        return false
    end
    
    return true
end

return MainMenu 