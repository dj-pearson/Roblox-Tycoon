--!strict
-- RebirthButton.luau
-- Reusable UI component for the rebirth button
-- Created: May 2, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

-- Core imports
local ClientRegistry = require(script.Parent.Parent.Parent.Parent.Core.ClientRegistry)
local RebirthClient = ClientRegistry.getSystem("RebirthClient")
local ThemeProvider = ClientRegistry.getSystem("ThemeProvider")

-- Types
type RebirthState = {
    level: number,
    multiplier: number,
    cost: number,
    canRebirth: boolean,
    progressInfo: {[string]: any}?,
    lastUpdate: number,
}

-- Component
local RebirthButton = {}
RebirthButton.__index = RebirthButton

-- Create a new RebirthButton
function RebirthButton.new(parent: Instance): table
    local self = setmetatable({}, RebirthButton)
    
    -- Create UI components
    self.instance = self:_createUI(parent)
    
    -- State
    self.enabled = true
    self.canAfford = false
    
    -- Connect events
    self:_connectEvents()
    
    -- Register with RebirthClient for updates
    if RebirthClient then
        RebirthClient:RegisterUIComponent("RebirthButton_" .. self.instance:GetDebugId(), self)
    end
    
    return self
end

-- Create the UI elements
function RebirthButton:_createUI(parent: Instance): Frame
    local frame = Instance.new("Frame")
    frame.Name = "RebirthButton"
    frame.Size = UDim2.new(0, 220, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- Apply theme if available
    if ThemeProvider then
        ThemeProvider:ApplyTheme(frame, "ButtonBackground")
    end
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Add gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 70))
    })
    gradient.Rotation = 45
    gradient.Parent = frame
    
    -- Create main button text
    local buttonText = Instance.new("TextLabel")
    buttonText.Name = "ButtonText"
    buttonText.Size = UDim2.new(1, 0, 0, 28)
    buttonText.Position = UDim2.new(0, 0, 0, 10)
    buttonText.Font = Enum.Font.GothamBold
    buttonText.Text = "REBIRTH"
    buttonText.TextSize = 20
    buttonText.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    buttonText.BackgroundTransparency = 1
    buttonText.Parent = frame
    
    -- Cost text
    local costText = Instance.new("TextLabel")
    costText.Name = "CostText"
    costText.Size = UDim2.new(1, 0, 0, 20)
    costText.Position = UDim2.new(0, 0, 0, 38)
    costText.Font = Enum.Font.Gotham
    costText.Text = "Cost: $100,000"
    costText.TextSize = 14
    costText.TextColor3 = Color3.fromRGB(220, 220, 220)
    costText.BackgroundTransparency = 1
    costText.Parent = frame
    
    -- Level text
    local levelText = Instance.new("TextLabel")
    levelText.Name = "LevelText"
    levelText.Size = UDim2.new(1, 0, 0, 16)
    levelText.Position = UDim2.new(0, 0, 0, 58)
    levelText.Font = Enum.Font.Gotham
    levelText.Text = "Current Level: 0"
    levelText.TextSize = 12
    levelText.TextColor3 = Color3.fromRGB(200, 200, 200)
    levelText.BackgroundTransparency = 1
    levelText.Parent = frame
    
    -- Store references to text elements
    self.buttonText = buttonText
    self.costText = costText
    self.levelText = levelText
    
    -- Add click detector frame
    local clickArea = Instance.new("TextButton")
    clickArea.Name = "ClickArea"
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.Parent = frame
    self.clickArea = clickArea
    
    -- Add glow effect
    local glow = Instance.new("UIStroke")
    glow.Name = "Glow"
    glow.Color = Color3.fromRGB(255, 215, 0) -- Gold
    glow.Thickness = 2
    glow.Transparency = 0.5
    glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    glow.Parent = frame
    self.glow = glow
    
    -- Set initial state
    self:_updateAvailability(false)
    
    frame.Parent = parent
    return frame
end

-- Connect event handlers
function RebirthButton:_connectEvents()
    -- Button click
    self.clickArea.Activated:Connect(function()
        self:_handleClick()
    end)
    
    -- Button hover effects
    self.clickArea.MouseEnter:Connect(function()
        self:_handleHover(true)
    end)
    
    self.clickArea.MouseLeave:Connect(function()
        self:_handleHover(false)
    end)
end

-- Handle button click
function RebirthButton:_handleClick()
    if not self.enabled or not self.canAfford then
        -- Play "cannot afford" feedback
        self:_playCannotAffordEffect()
        return
    end
    
    -- Request rebirth
    if RebirthClient then
        RebirthClient:RequestRebirth()
    end
    
    -- Play click effect
    self:_playClickEffect()
end

-- Handle hover state
function RebirthButton:_handleHover(isHovering: boolean)
    if not self.enabled then
        return
    end
    
    if isHovering then
        -- Scale up slightly
        local scaleTween = TweenService:Create(self.instance, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 230, 0, 84)
        })
        scaleTween:Play()
        
        -- Brighten glow
        local glowTween = TweenService:Create(self.glow, TweenInfo.new(0.2), {
            Transparency = 0.2,
            Thickness = 3
        })
        glowTween:Play()
    else
        -- Scale back to normal
        local scaleTween = TweenService:Create(self.instance, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 220, 0, 80)
        })
        scaleTween:Play()
        
        -- Return glow to normal
        local glowTween = TweenService:Create(self.glow, TweenInfo.new(0.2), {
            Transparency = 0.5,
            Thickness = 2
        })
        glowTween:Play()
    end
end

-- Play click effect
function RebirthButton:_playClickEffect()
    -- Flash the button
    local originalColor = self.buttonText.TextColor3
    self.buttonText.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    -- Create a quick pulse effect
    local scaleTween = TweenService:Create(self.instance, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 210, 0, 75)
    })
    scaleTween:Play()
    
    -- Return to normal after a short delay
    task.delay(0.1, function()
        self.buttonText.TextColor3 = originalColor
        
        local returnTween = TweenService:Create(self.instance, TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 220, 0, 80)
        })
        returnTween:Play()
    end)
}

-- Play "cannot afford" effect
function RebirthButton:_playCannotAffordEffect()
    -- Shake the button slightly
    local originalPosition = self.instance.Position
    
    -- Quick shake sequence
    local shakeSequence = {
        UDim2.fromOffset(5, 0),
        UDim2.fromOffset(-5, 0),
        UDim2.fromOffset(3, 0),
        UDim2.fromOffset(-3, 0),
        UDim2.fromOffset(0, 0)
    }
    
    -- Temporarily turn text red
    local originalColor = self.costText.TextColor3
    self.costText.TextColor3 = Color3.fromRGB(255, 100, 100)
    
    -- Execute shake
    for i, offset in ipairs(shakeSequence) do
        task.delay(i * 0.05, function()
            self.instance.Position = originalPosition + offset
        end)
    end
    
    -- Reset color after shake
    task.delay(0.3, function()
        self.costText.TextColor3 = originalColor
    end)
}

-- Update the button based on affordability
function RebirthButton:_updateAvailability(canAfford: boolean)
    self.canAfford = canAfford
    
    if canAfford then
        -- Enable the button
        self.glow.Color = Color3.fromRGB(255, 215, 0) -- Gold
        self.buttonText.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
        self.costText.TextColor3 = Color3.fromRGB(220, 220, 220)
    else
        -- Disable the button
        self.glow.Color = Color3.fromRGB(150, 150, 150) -- Gray
        self.buttonText.TextColor3 = Color3.fromRGB(180, 180, 180) -- Gray
        self.costText.TextColor3 = Color3.fromRGB(180, 180, 180)
    end
}

-- Format a number with commas (e.g., 1,000,000)
function RebirthButton:_formatNumber(num: number): string
    local formatted = tostring(num)
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    
    return formatted
end

-- Update the button with new rebirth state
function RebirthButton:UpdateRebirthInfo(state: RebirthState)
    -- Update level text
    self.levelText.Text = string.format("Current Level: %d", state.level)
    
    -- Update cost text
    local formattedCost = self:_formatNumber(state.cost)
    self.costText.Text = string.format("Cost: $%s", formattedCost)
    
    -- Update button availability
    self:_updateAvailability(state.canRebirth)
}

-- Set button enabled state
function RebirthButton:SetEnabled(enabled: boolean)
    self.enabled = enabled
    self.instance.Visible = enabled
}

-- Clean up the component
function RebirthButton:Destroy()
    -- Unregister from RebirthClient
    if RebirthClient then
        RebirthClient:UnregisterUIComponent("RebirthButton_" .. self.instance:GetDebugId())
    end
    
    -- Clean up instance
    if self.instance then
        self.instance:Destroy()
        self.instance = nil
    end
}

return RebirthButton
