--!strict
--[[
    ToastSystem.luau
    
    Toast notification system implementation.
    Handles showing temporary notifications with animations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Get the module loader
local ModuleLoader = require(script.Parent.ModuleLoader)

-- Load required modules
local UIComponent = ModuleLoader.loadCore("UIComponent")
local UITransitions = ModuleLoader.loadCore("UITransitions")
local UIUtils = ModuleLoader.loadCore("UIUtils")

-- Toast types
local TOAST_TYPES = {
    INFO = "Info",
    SUCCESS = "Success",
    WARNING = "Warning",
    ERROR = "Error"
}

-- Toast colors
local TOAST_COLORS = {
    [TOAST_TYPES.INFO] = UIUtils.Colors.Primary,
    [TOAST_TYPES.SUCCESS] = UIUtils.Colors.Success,
    [TOAST_TYPES.WARNING] = UIUtils.Colors.Warning,
    [TOAST_TYPES.ERROR] = UIUtils.Colors.Error
}

-- Create ToastSystem class
local ToastSystem = setmetatable({}, {__index = UIComponent})
ToastSystem.__index = ToastSystem

-- Constructor
function ToastSystem.new()
    local self = setmetatable(UIComponent.new("ToastSystem"), ToastSystem)
    self.toastQueue = {}
    self.activeToasts = {}
    return self
end

-- Override create method
function ToastSystem:create()
    -- Call base create method
    local success = UIComponent.create(self)
    if not success then
        return nil
    end
    
    -- Create toast container
    self:createToastContainer()
    
    return self.instance
end

-- Create toast container
function ToastSystem:createToastContainer()
    local container = UIUtils.createFrame(self.instance, {
        Name = "ToastContainer",
        Size = UDim2.new(0.3, 0, 0.5, 0),
        Position = UDim2.new(0.7, 0, 0.25, 0),
        BackgroundTransparency = 1,
        Layout = UIUtils.Layouts.Vertical
    })
    
    -- Store reference
    self.toastContainer = container
end

-- Create toast UI
function ToastSystem:createToastUI(type, message)
    local toast = UIUtils.createFrame(self.toastContainer, {
        Name = "Toast",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = UIUtils.Colors.Background,
        BackgroundTransparency = 0.1,
        CornerRadius = 8
    })
    
    -- Create icon
    local icon = UIUtils.createLabel(toast, {
        Name = "Icon",
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = self:getToastIcon(type),
        TextColor3 = TOAST_COLORS[type],
        Font = UIUtils.Fonts.Title,
        TextSize = UIUtils.TextSizes.Title,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    
    -- Create message
    local messageLabel = UIUtils.createLabel(toast, {
        Name = "Message",
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        Text = message,
        TextColor3 = UIUtils.Colors.Text,
        Font = UIUtils.Fonts.Body,
        TextSize = UIUtils.TextSizes.Body,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    return toast
end

-- Get toast icon
function ToastSystem:getToastIcon(type)
    if type == TOAST_TYPES.INFO then
        return "ℹ"
    elseif type == TOAST_TYPES.SUCCESS then
        return "✓"
    elseif type == TOAST_TYPES.WARNING then
        return "⚠"
    elseif type == TOAST_TYPES.ERROR then
        return "✕"
    end
    return "ℹ"
end

-- Show toast
function ToastSystem:showToast(options)
    -- Add to queue
    table.insert(self.toastQueue, options)
    
    -- Process queue
    self:processQueue()
end

-- Process queue
function ToastSystem:processQueue()
    -- Get next toast
    local options = table.remove(self.toastQueue, 1)
    if not options then return end
    
    -- Create toast UI
    local toast = self:createToastUI(options.type, options.message)
    
    -- Add to active toasts
    table.insert(self.activeToasts, toast)
    
    -- Show toast
    toast.Visible = true
    UITransitions.fadeAndSlideIn(toast, UIUtils.Animations.Default.Time)
    
    -- Auto-hide after duration
    task.delay(options.duration or 3, function()
        self:hideToast(toast)
    end)
end

-- Hide toast
function ToastSystem:hideToast(toast)
    -- Find toast in active toasts
    local index = table.find(self.activeToasts, toast)
    if not index then return end
    
    -- Remove from active toasts
    table.remove(self.activeToasts, index)
    
    -- Hide with animation
    UITransitions.fadeAndSlideOut(toast, UIUtils.Animations.Default.Time, function()
        toast:Destroy()
        
        -- Process next toast
        self:processQueue()
    end)
end

-- Show info toast
function ToastSystem:showInfo(message, duration)
    self:showToast({
        type = TOAST_TYPES.INFO,
        message = message,
        duration = duration
    })
end

-- Show success toast
function ToastSystem:showSuccess(message, duration)
    self:showToast({
        type = TOAST_TYPES.SUCCESS,
        message = message,
        duration = duration
    })
end

-- Show warning toast
function ToastSystem:showWarning(message, duration)
    self:showToast({
        type = TOAST_TYPES.WARNING,
        message = message,
        duration = duration
    })
end

-- Show error toast
function ToastSystem:showError(message, duration)
    self:showToast({
        type = TOAST_TYPES.ERROR,
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
end

-- Override update method
function ToastSystem:update()
    -- Call base update method
    local success = UIComponent.update(self)
    if not success then
        return false
    end
    
    return true
end

return ToastSystem 