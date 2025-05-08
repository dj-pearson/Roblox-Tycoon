--!strict
--[[
    PauseMenu.luau
    
    Pause menu implementation.
    Handles game pausing and provides access to game options.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Get the module loader
local ModuleLoader = require(script.Parent.Parent.Core.ModuleLoader)

-- Load required modules
local UIComponent = ModuleLoader.loadCore("UIComponent")
local UITransitions = ModuleLoader.loadCore("UITransitions")
local DialogSystem = ModuleLoader.loadCore("DialogSystem")
local ToastSystem = ModuleLoader.loadCore("ToastSystem")
local UIUtils = ModuleLoader.loadCore("UIUtils")

-- Create PauseMenu class
local PauseMenu = setmetatable({}, {__index = UIComponent})
PauseMenu.__index = PauseMenu

-- Constructor
function PauseMenu.new()
    local self = setmetatable(UIComponent.new("PauseMenu"), PauseMenu)
    self.isPaused = false
    self.dialogSystem = DialogSystem.new()
    self.toastSystem = ToastSystem.new()
    return self
end

-- Override create method
function PauseMenu:create()
    -- Call base create method
    local success = UIComponent.create(self)
    if not success then
        return nil
    end
    
    -- Create UI elements
    self:createBackground()
    self:createMenuPanel()
    self:createButtons()
    
    -- Set up input handling
    self:setupInputHandling()
    
    return self.instance
end

-- Create background
function PauseMenu:createBackground()
    local background = UIUtils.createFrame(self.instance, {
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5
    })
    
    -- Add blur effect
    local blur = Instance.new("BlurEffect")
    blur.Size = 20
    blur.Parent = game:GetService("Lighting")
    
    -- Store reference
    self.blur = blur
end

-- Create menu panel
function PauseMenu:createMenuPanel()
    local panel = UIUtils.createFrame(self.instance, {
        Name = "MenuPanel",
        Size = UDim2.new(0.4, 0, 0.6, 0),
        Position = UDim2.new(0.3, 0, 0.2, 0),
        BackgroundColor3 = UIUtils.Colors.Background,
        BackgroundTransparency = 0.1,
        CornerRadius = 8
    })
    
    -- Create title
    local title = UIUtils.createLabel(panel, {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "PAUSED",
        TextColor3 = UIUtils.Colors.Text,
        Font = UIUtils.Fonts.Title,
        TextSize = UIUtils.TextSizes.Title,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    
    -- Add separator
    UIUtils.createSeparator(panel, {
        Position = UDim2.new(0.1, 0, 0, 70)
    })
end

-- Create buttons
function PauseMenu:createButtons()
    local buttonContainer = UIUtils.createButtonContainer(self.instance.MenuPanel)
    
    -- Create resume button
    local resumeButton = UIUtils.createButton(buttonContainer, {
        Name = "ResumeButton",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Resume",
        BackgroundColor3 = UIUtils.Colors.Primary
    })
    
    -- Create settings button
    local settingsButton = UIUtils.createButton(buttonContainer, {
        Name = "SettingsButton",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 70),
        Text = "Settings",
        BackgroundColor3 = UIUtils.Colors.Secondary
    })
    
    -- Create help button
    local helpButton = UIUtils.createButton(buttonContainer, {
        Name = "HelpButton",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 140),
        Text = "Help",
        BackgroundColor3 = UIUtils.Colors.Secondary
    })
    
    -- Create quit button
    local quitButton = UIUtils.createButton(buttonContainer, {
        Name = "QuitButton",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 0, 210),
        Text = "Quit to Menu",
        BackgroundColor3 = UIUtils.Colors.Error
    })
    
    -- Add button hover effects
    UIUtils.setupButtonHover(resumeButton, UIUtils.Colors.Primary)
    UIUtils.setupButtonHover(settingsButton, UIUtils.Colors.Secondary)
    UIUtils.setupButtonHover(helpButton, UIUtils.Colors.Secondary)
    UIUtils.setupButtonHover(quitButton, UIUtils.Colors.Error)
    
    -- Add button click handlers
    resumeButton.MouseButton1Click:Connect(function()
        self:resume()
    end)
    
    settingsButton.MouseButton1Click:Connect(function()
        -- TODO: Show settings screen
        print("Settings button clicked")
    end)
    
    helpButton.MouseButton1Click:Connect(function()
        -- TODO: Show help screen
        print("Help button clicked")
    end)
    
    quitButton.MouseButton1Click:Connect(function()
        self:confirmQuit()
    end)
end

-- Set up input handling
function PauseMenu:setupInputHandling()
    -- Handle escape key
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape then
            if self.isPaused then
                self:resume()
            else
                self:pause()
            end
        end
    end)
end

-- Pause the game
function PauseMenu:pause()
    if self.isPaused then return end
    
    self.isPaused = true
    
    -- Show menu with animation
    self.instance.Visible = true
    UITransitions.fadeAndSlideIn(self.instance, 0.3)
    
    -- Show toast
    self.toastSystem:showInfo("Game paused", 2)
    
    -- Pause game
    RunService:SetRobloxGuiFocused(true)
    -- TODO: Implement game-specific pause logic
end

-- Resume the game
function PauseMenu:resume()
    if not self.isPaused then return end
    
    self.isPaused = false
    
    -- Hide menu with animation
    UITransitions.fadeAndSlideOut(self.instance, 0.3, function()
        self.instance.Visible = false
    end)
    
    -- Show toast
    self.toastSystem:showSuccess("Game resumed", 2)
    
    -- Resume game
    RunService:SetRobloxGuiFocused(false)
    -- TODO: Implement game-specific resume logic
end

-- Confirm quit
function PauseMenu:confirmQuit()
    self.dialogSystem:showConfirm(
        "Quit to Menu",
        "Are you sure you want to quit to the main menu?",
        "Quit",
        "Cancel",
        function()
            -- TODO: Implement quit to menu logic
            self.toastSystem:showInfo("Returning to main menu...", 2)
            print("Quitting to menu...")
        end,
        function()
            self.toastSystem:showInfo("Cancelled quit", 2)
        end
    )
end

-- Clean up
function PauseMenu:cleanup()
    if self.blur then
        self.blur:Destroy()
    end
    
    if self.dialogSystem then
        self.dialogSystem:cleanup()
    end
    
    if self.toastSystem then
        self.toastSystem:cleanup()
    end
end

-- Override update method
function PauseMenu:update()
    -- Call base update method
    local success = UIComponent.update(self)
    if not success then
        return false
    end
    
    return true
end

return PauseMenu 