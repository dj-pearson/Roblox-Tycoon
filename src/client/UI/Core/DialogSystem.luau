--!strict
--[[
    DialogSystem.luau
    
    Dialog system implementation.
    Handles showing dialogs, confirmations, and notifications.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Get the module loader
local ModuleLoader = require(script.Parent.ModuleLoader)

-- Load required modules
local UIComponent = ModuleLoader.loadCore("UIComponent")
local UITransitions = ModuleLoader.loadCore("UITransitions")
local UIUtils = ModuleLoader.loadCore("UIUtils")

-- Dialog types
local DIALOG_TYPES = {
    INFO = "Info",
    WARNING = "Warning",
    ERROR = "Error",
    CONFIRM = "Confirm"
}

-- Dialog colors
local DIALOG_COLORS = {
    [DIALOG_TYPES.INFO] = UIUtils.Colors.Primary,
    [DIALOG_TYPES.WARNING] = UIUtils.Colors.Warning,
    [DIALOG_TYPES.ERROR] = UIUtils.Colors.Error,
    [DIALOG_TYPES.CONFIRM] = UIUtils.Colors.Primary
}

-- Create DialogSystem class
local DialogSystem = setmetatable({}, {__index = UIComponent})
DialogSystem.__index = DialogSystem

-- Constructor
function DialogSystem.new()
    local self = setmetatable(UIComponent.new("DialogSystem"), DialogSystem)
    self.dialogQueue = {}
    self.activeDialog = nil
    return self
end

-- Override create method
function DialogSystem:create()
    -- Call base create method
    local success = UIComponent.create(self)
    if not success then
        return nil
    end
    
    -- Create background
    self:createBackground()
    
    return self.instance
end

-- Create background
function DialogSystem:createBackground()
    local background = UIUtils.createFrame(self.instance, {
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5
    })
end

-- Create dialog UI
function DialogSystem:createDialogUI()
    local dialog = UIUtils.createFrame(self.instance, {
        Name = "Dialog",
        Size = UDim2.new(0.4, 0, 0, 200),
        Position = UDim2.new(0.3, 0, 0.4, 0),
        BackgroundColor3 = UIUtils.Colors.Background,
        BackgroundTransparency = 0.1,
        CornerRadius = 8,
        Layout = UIUtils.Layouts.Vertical
    })
    
    -- Create title
    local title = UIUtils.createLabel(dialog, {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 40),
        Text = "",
        TextColor3 = UIUtils.Colors.Text,
        Font = UIUtils.Fonts.Title,
        TextSize = UIUtils.TextSizes.Title,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    
    -- Add separator
    UIUtils.createSeparator(dialog, {
        Size = UDim2.new(0.9, 0, 0, 2)
    })
    
    -- Create message
    local message = UIUtils.createLabel(dialog, {
        Name = "Message",
        Size = UDim2.new(0.9, 0, 0, 60),
        Position = UDim2.new(0.05, 0, 0, 0),
        Text = "",
        TextColor3 = UIUtils.Colors.Text,
        Font = UIUtils.Fonts.Body,
        TextSize = UIUtils.TextSizes.Body,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center
    })
    
    -- Create button container
    local buttonContainer = UIUtils.createFrame(dialog, {
        Name = "ButtonContainer",
        Size = UDim2.new(0.9, 0, 0, 50),
        Position = UDim2.new(0.05, 0, 0, 0),
        BackgroundTransparency = 1,
        Layout = UIUtils.Layouts.Horizontal
    })
    
    return dialog, title, message, buttonContainer
end

-- Create button
function DialogSystem:createButton(parent, text, color, callback)
    local button = UIUtils.createButton(parent, {
        Name = text .. "Button",
        Size = UDim2.new(0.45, 0, 0, 40),
        Text = text,
        BackgroundColor3 = color
    })
    
    -- Add hover effect
    UIUtils.setupButtonHover(button, color, color:Lerp(UIUtils.Colors.Hover, 0.3))
    
    -- Add click handler
    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
        self:hideDialog()
    end)
    
    return button
end

-- Show dialog
function DialogSystem:showDialog(options)
    -- Add to queue
    table.insert(self.dialogQueue, options)
    
    -- Process queue
    self:processQueue()
end

-- Process queue
function DialogSystem:processQueue()
    -- Skip if already showing a dialog
    if self.activeDialog then return end
    
    -- Get next dialog
    local options = table.remove(self.dialogQueue, 1)
    if not options then return end
    
    -- Create dialog UI
    local dialog, title, message, buttonContainer = self:createDialogUI()
    
    -- Set dialog properties
    title.Text = options.title or ""
    message.Text = options.message or ""
    
    -- Set dialog color
    local dialogColor = DIALOG_COLORS[options.type] or DIALOG_COLORS[DIALOG_TYPES.INFO]
    title.TextColor3 = dialogColor
    
    -- Create buttons
    if options.type == DIALOG_TYPES.CONFIRM then
        self:createButton(buttonContainer, options.confirmText or "Confirm", dialogColor, options.onConfirm)
        self:createButton(buttonContainer, options.cancelText or "Cancel", UIUtils.Colors.Secondary, options.onCancel)
    else
        self:createButton(buttonContainer, options.buttonText or "OK", dialogColor, options.onButton)
    end
    
    -- Show dialog
    dialog.Visible = true
    UITransitions.fadeAndSlideIn(dialog, UIUtils.Animations.Default.Time)
    
    -- Store reference
    self.activeDialog = dialog
end

-- Hide dialog
function DialogSystem:hideDialog()
    if not self.activeDialog then return end
    
    -- Hide with animation
    UITransitions.fadeAndSlideOut(self.activeDialog, UIUtils.Animations.Default.Time, function()
        self.activeDialog:Destroy()
        self.activeDialog = nil
        
        -- Process next dialog
        self:processQueue()
    end)
end

-- Show info dialog
function DialogSystem:showInfo(title, message, buttonText, callback)
    self:showDialog({
        type = DIALOG_TYPES.INFO,
        title = title,
        message = message,
        buttonText = buttonText,
        onButton = callback
    })
end

-- Show warning dialog
function DialogSystem:showWarning(title, message, buttonText, callback)
    self:showDialog({
        type = DIALOG_TYPES.WARNING,
        title = title,
        message = message,
        buttonText = buttonText,
        onButton = callback
    })
end

-- Show error dialog
function DialogSystem:showError(title, message, buttonText, callback)
    self:showDialog({
        type = DIALOG_TYPES.ERROR,
        title = title,
        message = message,
        buttonText = buttonText,
        onButton = callback
    })
end

-- Show confirm dialog
function DialogSystem:showConfirm(title, message, confirmText, cancelText, onConfirm, onCancel)
    self:showDialog({
        type = DIALOG_TYPES.CONFIRM,
        title = title,
        message = message,
        confirmText = confirmText,
        cancelText = cancelText,
        onConfirm = onConfirm,
        onCancel = onCancel
    })
end

-- Clean up
function DialogSystem:cleanup()
    -- Clear queue
    self.dialogQueue = {}
    
    -- Hide active dialog
    if self.activeDialog then
        self.activeDialog:Destroy()
        self.activeDialog = nil
    end
end

-- Override update method
function DialogSystem:update()
    -- Call base update method
    local success = UIComponent.update(self)
    if not success then
        return false
    end
    
    return true
end

return DialogSystem 