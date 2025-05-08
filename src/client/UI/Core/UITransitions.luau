--!strict
--[[
    UITransitions.luau
    
    Handles smooth transitions and animations for UI elements.
    Provides a consistent animation system across all UI components.
]]

local TweenService = game:GetService("TweenService")

-- Configuration
local CONFIG = {
    defaultDuration = 0.3,
    defaultEasingStyle = Enum.EasingStyle.Quad,
    defaultEasingDirection = Enum.EasingDirection.Out,
    fadeInProperties = {
        BackgroundTransparency = 0,
        TextTransparency = 0,
        ImageTransparency = 0
    },
    fadeOutProperties = {
        BackgroundTransparency = 1,
        TextTransparency = 1,
        ImageTransparency = 1
    },
    slideInProperties = {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    },
    slideOutProperties = {
        Position = UDim2.new(0.5, 0, 1.5, 0)
    }
}

-- Create tween info
local function createTweenInfo(duration, easingStyle, easingDirection)
    return TweenInfo.new(
        duration or CONFIG.defaultDuration,
        easingStyle or CONFIG.defaultEasingStyle,
        easingDirection or CONFIG.defaultEasingDirection
    )
end

-- Fade in animation
local function fadeIn(element, duration, callback)
    if not element then return end
    
    local tweenInfo = createTweenInfo(duration)
    local properties = table.clone(CONFIG.fadeInProperties)
    
    -- Set initial state
    element.BackgroundTransparency = 1
    element.TextTransparency = 1
    element.ImageTransparency = 1
    
    -- Create and play tween
    local tween = TweenService:Create(element, tweenInfo, properties)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

-- Fade out animation
local function fadeOut(element, duration, callback)
    if not element then return end
    
    local tweenInfo = createTweenInfo(duration)
    local properties = table.clone(CONFIG.fadeOutProperties)
    
    -- Create and play tween
    local tween = TweenService:Create(element, tweenInfo, properties)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

-- Slide in animation
local function slideIn(element, duration, callback)
    if not element then return end
    
    local tweenInfo = createTweenInfo(duration)
    local properties = table.clone(CONFIG.slideInProperties)
    
    -- Set initial state
    element.Position = UDim2.new(0.5, 0, 1.5, 0)
    
    -- Create and play tween
    local tween = TweenService:Create(element, tweenInfo, properties)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

-- Slide out animation
local function slideOut(element, duration, callback)
    if not element then return end
    
    local tweenInfo = createTweenInfo(duration)
    local properties = table.clone(CONFIG.slideOutProperties)
    
    -- Create and play tween
    local tween = TweenService:Create(element, tweenInfo, properties)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

-- Scale in animation
local function scaleIn(element, duration, callback)
    if not element then return end
    
    local tweenInfo = createTweenInfo(duration)
    local properties = {
        Size = element.Size,
        Position = element.Position
    }
    
    -- Set initial state
    element.Size = UDim2.new(0, 0, 0, 0)
    element.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    -- Create and play tween
    local tween = TweenService:Create(element, tweenInfo, properties)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

-- Scale out animation
local function scaleOut(element, duration, callback)
    if not element then return end
    
    local tweenInfo = createTweenInfo(duration)
    local properties = {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }
    
    -- Create and play tween
    local tween = TweenService:Create(element, tweenInfo, properties)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

-- Combined animations
local function fadeAndSlideIn(element, duration, callback)
    if not element then return end
    
    local fadeTween = fadeIn(element, duration)
    local slideTween = slideIn(element, duration)
    
    if callback then
        slideTween.Completed:Connect(callback)
    end
    
    return fadeTween, slideTween
end

local function fadeAndSlideOut(element, duration, callback)
    if not element then return end
    
    local fadeTween = fadeOut(element, duration)
    local slideTween = slideOut(element, duration)
    
    if callback then
        slideTween.Completed:Connect(callback)
    end
    
    return fadeTween, slideTween
end

-- Module
local UITransitions = {
    fadeIn = fadeIn,
    fadeOut = fadeOut,
    slideIn = slideIn,
    slideOut = slideOut,
    scaleIn = scaleIn,
    scaleOut = scaleOut,
    fadeAndSlideIn = fadeAndSlideIn,
    fadeAndSlideOut = fadeAndSlideOut
}

return UITransitions 