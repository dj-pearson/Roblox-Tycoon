--!strict
--[[
    ToastSystem.luau
    
    Toast notification system for displaying temporary messages.
    Provides a consistent way to show notifications with animations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Get the transitions module
local UITransitions = require(script.Parent.UITransitions)

-- Toast types
local ToastType = {
    INFO = "info",
    SUCCESS = "success",
    WARNING = "warning",
    ERROR = "error"
}

-- Toast colors
local ToastColors = {
    [ToastType.INFO] = Color3.fromRGB(52, 152, 219),
    [ToastType.SUCCESS] = Color3.fromRGB(46, 204, 113),
    [ToastType.WARNING] = Color3.fromRGB(241, 196, 15),
    [ToastType.ERROR] = Color3.fromRGB(231, 76, 60)
}

-- Create ToastSystem
local ToastSystem = {}
ToastSystem.__index = ToastSystem

-- Constructor
function ToastSystem.new()
    local self = setmetatable({}, ToastSystem)
    self.activeToasts = {}
    self.toastQueue = {}
    self.isProcessingQueue = false
    return self
end

-- Create toast UI
function ToastSystem:createToastUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ToastSystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    return screenGui
end

-- Create toast frame
function ToastSystem:createToastFrame()
    local frame = Instance.new("Frame")
    frame.Name = "ToastFrame"
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(1, 20, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame.BackgroundTransparency = 0.1
    frame.Visible = false
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Create icon
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 40, 1, 0)
    icon.Position = UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 24
    icon.Parent = frame
    
    -- Create message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -50, 1, 0)
    message.Position = UDim2.new(0, 50, 0, 0)
    message.BackgroundTransparency = 1
    message.TextColor3 = Color3.fromRGB(255, 255, 255)
    message.Font = Enum.Font.Gotham
    message.TextSize = 16
    message.TextWrapped = true
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.Parent = frame
    
    return frame
end

-- Get toast icon
function ToastSystem:getToastIcon(type)
    local icons = {
        [ToastType.INFO] = "ℹ",
        [ToastType.SUCCESS] = "✓",
        [ToastType.WARNING] = "⚠",
        [ToastType.ERROR] = "✕"
    }
    return icons[type] or icons[ToastType.INFO]
end

-- Show toast
function ToastSystem:showToast(options)
    -- Add to queue
    table.insert(self.toastQueue, options)
    
    -- Process queue if not already processing
    if not self.isProcessingQueue then
        self:processQueue()
    end
end

-- Process toast queue
function ToastSystem:processQueue()
    if #self.toastQueue == 0 then
        self.isProcessingQueue = false
        return
    end
    
    self.isProcessingQueue = true
    
    -- Get next toast options
    local options = table.remove(self.toastQueue, 1)
    
    -- Create toast UI if needed
    if not self.screenGui then
        self.screenGui = self:createToastUI()
    end
    
    -- Create toast frame
    local toast = self:createToastFrame()
    toast.Parent = self.screenGui
    
    -- Set toast properties
    local icon = toast:FindFirstChild("Icon")
    local message = toast:FindFirstChild("Message")
    
    icon.Text = self:getToastIcon(options.type)
    message.Text = options.message or ""
    
    -- Set toast color
    local toastColor = ToastColors[options.type or ToastType.INFO]
    icon.TextColor3 = toastColor
    
    -- Calculate position based on active toasts
    local yOffset = #self.activeToasts * 70
    toast.Position = UDim2.new(1, 20, 0.1, yOffset)
    
    -- Show toast with animation
    toast.Visible = true
    UITransitions.fadeAndSlideIn(toast, 0.3)
    
    -- Add to active toasts
    table.insert(self.activeToasts, toast)
    
    -- Set up auto-hide
    task.delay(options.duration or 3, function()
        self:hideToast(toast)
    end)
end

-- Hide toast
function ToastSystem:hideToast(toast)
    -- Find toast in active toasts
    local index = table.find(self.activeToasts, toast)
    if index then
        table.remove(self.activeToasts, index)
    end
    
    -- Hide with animation
    UITransitions.fadeAndSlideOut(toast, 0.3, function()
        toast:Destroy()
        
        -- Update positions of remaining toasts
        for i, activeToast in ipairs(self.activeToasts) do
            local yOffset = (i - 1) * 70
            local tween = TweenService:Create(
                activeToast,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(1, 20, 0.1, yOffset)}
            )
            tween:Play()
        end
        
        -- Process next toast
        self:processQueue()
    end)
end

-- Show info toast
function ToastSystem:showInfo(message, duration)
    self:showToast({
        type = ToastType.INFO,
        message = message,
        duration = duration
    })
end

-- Show success toast
function ToastSystem:showSuccess(message, duration)
    self:showToast({
        type = ToastType.SUCCESS,
        message = message,
        duration = duration
    })
end

-- Show warning toast
function ToastSystem:showWarning(message, duration)
    self:showToast({
        type = ToastType.WARNING,
        message = message,
        duration = duration
    })
end

-- Show error toast
function ToastSystem:showError(message, duration)
    self:showToast({
        type = ToastType.ERROR,
        message = message,
        duration = duration
    })
end

-- Clean up
function ToastSystem:cleanup()
    -- Clear queue
    self.toastQueue = {}
    
    -- Hide all active toasts
    for _, toast in ipairs(self.activeToasts) do
        toast:Destroy()
    end
    self.activeToasts = {}
    
    -- Destroy screen GUI
    if self.screenGui then
        self.screenGui:Destroy()
        self.screenGui = nil
    end
end

return ToastSystem 