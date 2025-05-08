--!strict
--[[
    LoadingScreen.luau
    
    Loading screen implementation.
    Shows loading progress and helpful tips while game assets load.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Get the module loader
local ModuleLoader = require(script.Parent.Parent.Core.ModuleLoader)

-- Load required modules
local UIComponent = ModuleLoader.loadCore("UIComponent")
local UITransitions = ModuleLoader.loadCore("UITransitions")
local UIUtils = ModuleLoader.loadCore("UIUtils")

-- Loading tips
local LOADING_TIPS = {
    "Tip: Explore every corner of the map to find hidden secrets!",
    "Tip: Complete daily challenges for bonus rewards.",
    "Tip: Join a team to tackle difficult challenges together.",
    "Tip: Customize your character in the settings menu.",
    "Tip: Use the minimap to navigate efficiently.",
    "Tip: Save your progress regularly to avoid losing data.",
    "Tip: Check the tutorial for basic controls and mechanics.",
    "Tip: Different weapons have unique abilities and playstyles."
}

-- Create LoadingScreen class
local LoadingScreen = setmetatable({}, {__index = UIComponent})
LoadingScreen.__index = LoadingScreen

-- Constructor
function LoadingScreen.new()
    local self = setmetatable(UIComponent.new("LoadingScreen"), LoadingScreen)
    self.progress = 0
    self.currentTip = 1
    self.tipDuration = 5 -- seconds
    return self
end

-- Override create method
function LoadingScreen:create()
    -- Call base create method
    local success = UIComponent.create(self)
    if not success then
        return nil
    end
    
    -- Create UI elements
    self:createBackground()
    self:createLoadingElements()
    self:createTips()
    
    -- Start tip rotation
    self:startTipRotation()
    
    return self.instance
end

-- Create background
function LoadingScreen:createBackground()
    local background, gradient = UIUtils.createGradient(self.instance, {
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0
    })
    
    -- Add animated gradient
    task.spawn(function()
        while self.instance and self.instance.Parent do
            gradient.Rotation = (gradient.Rotation + 1) % 360
            task.wait(0.1)
        end
    end)
end

-- Create loading elements
function LoadingScreen:createLoadingElements()
    -- Create loading container
    local container = UIUtils.createFrame(self.instance, {
        Name = "LoadingContainer",
        Size = UDim2.new(0.6, 0, 0.2, 0),
        Position = UDim2.new(0.2, 0, 0.4, 0),
        BackgroundTransparency = 1
    })
    
    -- Create loading text
    local loadingText = UIUtils.createLabel(container, {
        Name = "LoadingText",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Loading...",
        TextColor3 = UIUtils.Colors.Text,
        Font = UIUtils.Fonts.Title,
        TextSize = UIUtils.TextSizes.Title,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    
    -- Create progress bar background
    local progressBarBg = UIUtils.createFrame(container, {
        Name = "ProgressBarBg",
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 0, 60),
        BackgroundColor3 = UIUtils.Colors.Secondary,
        BorderSizePixel = 0,
        CornerRadius = 4
    })
    
    -- Create progress bar fill
    local progressBarFill = UIUtils.createFrame(progressBarBg, {
        Name = "ProgressBarFill",
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = UIUtils.Colors.Primary,
        BorderSizePixel = 0,
        CornerRadius = 4
    })
    
    -- Create progress text
    local progressText = UIUtils.createLabel(container, {
        Name = "ProgressText",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 80),
        Text = "0%",
        TextColor3 = UIUtils.Colors.Text,
        Font = UIUtils.Fonts.Body,
        TextSize = UIUtils.TextSizes.Body,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    
    -- Store references
    self.progressBarFill = progressBarFill
    self.progressText = progressText
end

-- Create tips section
function LoadingScreen:createTips()
    -- Create tips container
    local container = UIUtils.createFrame(self.instance, {
        Name = "TipsContainer",
        Size = UDim2.new(0.6, 0, 0, 60),
        Position = UDim2.new(0.2, 0, 0.65, 0),
        BackgroundTransparency = 1
    })
    
    -- Create tips label
    local tipsLabel = UIUtils.createLabel(container, {
        Name = "TipsLabel",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Tip:",
        TextColor3 = UIUtils.Colors.Primary,
        Font = UIUtils.Fonts.Title,
        TextSize = UIUtils.TextSizes.Subtitle,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Create tip text
    local tipText = UIUtils.createLabel(container, {
        Name = "TipText",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 20),
        Text = LOADING_TIPS[1],
        TextColor3 = UIUtils.Colors.Text,
        Font = UIUtils.Fonts.Body,
        TextSize = UIUtils.TextSizes.Body,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Store reference
    self.tipText = tipText
end

-- Start tip rotation
function LoadingScreen:startTipRotation()
    task.spawn(function()
        while self.instance and self.instance.Parent do
            -- Fade out current tip
            UITransitions.fadeOut(self.tipText, 0.5)
            task.wait(0.5)
            
            -- Update tip
            self.currentTip = (self.currentTip % #LOADING_TIPS) + 1
            self.tipText.Text = LOADING_TIPS[self.currentTip]
            
            -- Fade in new tip
            UITransitions.fadeIn(self.tipText, 0.5)
            
            -- Wait before next tip
            task.wait(self.tipDuration)
        end
    end)
end

-- Update progress
function LoadingScreen:updateProgress(progress)
    if not self.progressBarFill or not self.progressText then return end
    
    self.progress = math.clamp(progress, 0, 1)
    
    -- Update progress bar
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(self.progressBarFill, tweenInfo, {
        Size = UDim2.new(self.progress, 0, 1, 0)
    })
    tween:Play()
    
    -- Update progress text
    self.progressText.Text = math.floor(self.progress * 100) .. "%"
end

-- Show loading screen
function LoadingScreen:show()
    if not self.instance then return end
    
    -- Reset progress
    self:updateProgress(0)
    
    -- Show with animation
    UITransitions.fadeAndSlideIn(self.instance, 0.5)
end

-- Hide loading screen
function LoadingScreen:hide()
    if not self.instance then return end
    
    -- Hide with animation
    UITransitions.fadeAndSlideOut(self.instance, 0.5, function()
        self.instance:Destroy()
    end)
end

-- Override update method
function LoadingScreen:update()
    -- Call base update method
    local success = UIComponent.update(self)
    if not success then
        return false
    end
    
    return true
end

return LoadingScreen 