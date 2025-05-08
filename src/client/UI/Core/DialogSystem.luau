--!strict
--[[
    DialogSystem.luau
    
    Dialog system for handling confirmations and notifications.
    Provides a consistent way to show dialogs with animations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Get the transitions module
local UITransitions = require(script.Parent.UITransitions)

-- Dialog types
local DialogType = {
    INFO = "info",
    WARNING = "warning",
    ERROR = "error",
    CONFIRM = "confirm"
}

-- Dialog colors
local DialogColors = {
    [DialogType.INFO] = Color3.fromRGB(52, 152, 219),
    [DialogType.WARNING] = Color3.fromRGB(241, 196, 15),
    [DialogType.ERROR] = Color3.fromRGB(231, 76, 60),
    [DialogType.CONFIRM] = Color3.fromRGB(46, 204, 113)
}

-- Create DialogSystem
local DialogSystem = {}
DialogSystem.__index = DialogSystem

-- Constructor
function DialogSystem.new()
    local self = setmetatable({}, DialogSystem)
    self.activeDialogs = {}
    self.dialogQueue = {}
    self.isProcessingQueue = false
    return self
end

-- Create dialog UI
function DialogSystem:createDialogUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DialogSystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    return screenGui
end

-- Create dialog frame
function DialogSystem:createDialogFrame()
    local frame = Instance.new("Frame")
    frame.Name = "DialogFrame"
    frame.Size = UDim2.new(0, 400, 0, 200)
    frame.Position = UDim2.new(0.5, -200, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame.BackgroundTransparency = 0.1
    frame.Visible = false
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.Parent = frame
    
    -- Create message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(0.9, 0, 0, 80)
    message.Position = UDim2.new(0.05, 0, 0.3, 0)
    message.BackgroundTransparency = 1
    message.TextColor3 = Color3.fromRGB(255, 255, 255)
    message.Font = Enum.Font.Gotham
    message.TextSize = 18
    message.TextWrapped = true
    message.Parent = frame
    
    -- Create button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(0.9, 0, 0, 40)
    buttonContainer.Position = UDim2.new(0.05, 0, 0.8, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = frame
    
    return frame
end

-- Create button
function DialogSystem:createButton(text, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.45, 0, 1, 0)
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.Text = text
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    return button
end

-- Show dialog
function DialogSystem:showDialog(options)
    -- Add to queue
    table.insert(self.dialogQueue, options)
    
    -- Process queue if not already processing
    if not self.isProcessingQueue then
        self:processQueue()
    end
end

-- Process dialog queue
function DialogSystem:processQueue()
    if #self.dialogQueue == 0 then
        self.isProcessingQueue = false
        return
    end
    
    self.isProcessingQueue = true
    
    -- Get next dialog options
    local options = table.remove(self.dialogQueue, 1)
    
    -- Create dialog UI if needed
    if not self.screenGui then
        self.screenGui = self:createDialogUI()
    end
    
    -- Create dialog frame
    local dialog = self:createDialogFrame()
    dialog.Parent = self.screenGui
    
    -- Set dialog properties
    local title = dialog:FindFirstChild("Title")
    local message = dialog:FindFirstChild("Message")
    local buttonContainer = dialog:FindFirstChild("ButtonContainer")
    
    title.Text = options.title or "Dialog"
    message.Text = options.message or ""
    
    -- Set dialog color
    local dialogColor = DialogColors[options.type or DialogType.INFO]
    title.TextColor3 = dialogColor
    
    -- Create buttons
    if options.type == DialogType.CONFIRM then
        -- Create confirm and cancel buttons
        local confirmButton = self:createButton(options.confirmText or "Confirm", DialogColors[DialogType.CONFIRM])
        confirmButton.Position = UDim2.new(0, 0, 0, 0)
        confirmButton.Parent = buttonContainer
        
        local cancelButton = self:createButton(options.cancelText or "Cancel", Color3.fromRGB(50, 53, 59))
        cancelButton.Position = UDim2.new(0.55, 0, 0, 0)
        cancelButton.Parent = buttonContainer
        
        -- Connect button events
        confirmButton.MouseButton1Click:Connect(function()
            if options.onConfirm then
                options.onConfirm()
            end
            self:hideDialog(dialog)
        end)
        
        cancelButton.MouseButton1Click:Connect(function()
            if options.onCancel then
                options.onCancel()
            end
            self:hideDialog(dialog)
        end)
    else
        -- Create single button
        local button = self:createButton(options.buttonText or "OK", dialogColor)
        button.Position = UDim2.new(0.275, 0, 0, 0)
        button.Parent = buttonContainer
        
        -- Connect button event
        button.MouseButton1Click:Connect(function()
            if options.onButton then
                options.onButton()
            end
            self:hideDialog(dialog)
        end)
    end
    
    -- Show dialog with animation
    dialog.Visible = true
    UITransitions.fadeAndSlideIn(dialog, 0.3)
    
    -- Add to active dialogs
    table.insert(self.activeDialogs, dialog)
end

-- Hide dialog
function DialogSystem:hideDialog(dialog)
    -- Find dialog in active dialogs
    local index = table.find(self.activeDialogs, dialog)
    if index then
        table.remove(self.activeDialogs, index)
    end
    
    -- Hide with animation
    UITransitions.fadeAndSlideOut(dialog, 0.3, function()
        dialog:Destroy()
        
        -- Process next dialog
        self:processQueue()
    end)
end

-- Show info dialog
function DialogSystem:showInfo(title, message, buttonText, onButton)
    self:showDialog({
        type = DialogType.INFO,
        title = title,
        message = message,
        buttonText = buttonText,
        onButton = onButton
    })
end

-- Show warning dialog
function DialogSystem:showWarning(title, message, buttonText, onButton)
    self:showDialog({
        type = DialogType.WARNING,
        title = title,
        message = message,
        buttonText = buttonText,
        onButton = onButton
    })
end

-- Show error dialog
function DialogSystem:showError(title, message, buttonText, onButton)
    self:showDialog({
        type = DialogType.ERROR,
        title = title,
        message = message,
        buttonText = buttonText,
        onButton = onButton
    })
end

-- Show confirm dialog
function DialogSystem:showConfirm(title, message, confirmText, cancelText, onConfirm, onCancel)
    self:showDialog({
        type = DialogType.CONFIRM,
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
    
    -- Hide all active dialogs
    for _, dialog in ipairs(self.activeDialogs) do
        dialog:Destroy()
    end
    self.activeDialogs = {}
    
    -- Destroy screen GUI
    if self.screenGui then
        self.screenGui:Destroy()
        self.screenGui = nil
    end
end

return DialogSystem 