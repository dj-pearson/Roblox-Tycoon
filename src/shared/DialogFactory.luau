--[[
    DialogFactory.luau
    
    A factory module for creating standardized dialog boxes and popups based on the UI_Module_Design document.
    Implements confirmation dialogs, notifications, popups, and modal windows with consistent styling.
    
    Author: Updated April 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn("Failed to require module: ", module:GetFullName())
        return nil
    end
    
    return result
end

-- Find shared modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
local UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))
local IconSet = requireSafely(sharedFolder and sharedFolder:FindFirstChild("IconSet"))
local ButtonFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("ButtonFactory"))

-- Create fallbacks if modules not found
if not UIStyle then
    warn("UIStyle module not found, using fallback styles")
    UIStyle = {
        Colors = {
            Background = Color3.fromRGB(40, 40, 60),
            BackgroundLight = Color3.fromRGB(60, 60, 80),
            BackgroundDark = Color3.fromRGB(30, 30, 45),
            HeaderBackground = Color3.fromRGB(35, 35, 55),
            Text = Color3.fromRGB(240, 240, 255),
            TextSecondary = Color3.fromRGB(180, 180, 200),
            Danger = Color3.fromRGB(220, 50, 50),
            Success = Color3.fromRGB(40, 180, 100),
            Warning = Color3.fromRGB(255, 190, 0),
            Info = Color3.fromRGB(80, 170, 240)
        },
        Fonts = {
            Regular = Enum.Font.Gotham,
            Bold = Enum.Font.GothamBold,
            SemiBold = Enum.Font.GothamSemibold,
            Title = Enum.Font.GothamBlack
        },
        TextSizes = {
            Small = 12,
            Medium = 16,
            Large = 20,
            Title = 24
        },
        Animations = {
            Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        },
        ZIndex = {
            Background = 1,
            Content = 10,
            Foreground = 50,
            Overlay = 100,
            Topmost = 200
        }
    }
end

if not ButtonFactory then
    warn("ButtonFactory module not found, using fallback implementation")
    ButtonFactory = {
        createButton = function(text, size, position, callback, style)
            local button = Instance.new("TextButton")
            button.Size = size or UDim2.new(0, 120, 0, 40)
            button.Position = position or UDim2.new(0, 0, 0, 0)
            button.Text = text or "Button"
            return button
        end,
        
        createConfirmButton = function(text, size, position, callback)
            local button = Instance.new("TextButton")
            button.Size = size or UDim2.new(0, 120, 0, 40)
            button.Position = position or UDim2.new(0, 0, 0, 0)
            button.Text = text or "Confirm"
            return button
        end,
        
        createCancelButton = function(text, size, position, callback)
            local button = Instance.new("TextButton")
            button.Size = size or UDim2.new(0, 120, 0, 40)
            button.Position = position or UDim2.new(0, 0, 0, 0)
            button.Text = text or "Cancel"
            return button
        end,
        
        createCloseButton = function(parent, position, callback)
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0, 30, 0, 30)
            button.Position = position or UDim2.new(1, -10, 0, 10)
            button.Text = "X"
            return button
        end
    }
end

-- Dialog Factory Module
local DialogFactory = {}

-- Helper function to create corner rounding
local function addCorner(instance, cornerRadius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = cornerRadius or UDim.new(0, 8)
    corner.Parent = instance
    return corner
end

-- Helper function to create a modal background that closes dialog when clicking outside
local function createModalBackground(zIndex, clickCallback)
    local background = Instance.new("Frame")
    background.Name = "ModalBackground"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.BorderSizePixel = 0
    background.ZIndex = zIndex or UIStyle.ZIndex.Overlay
    
    -- Connect click callback
    background.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            if clickCallback and typeof(clickCallback) == "function" then
                clickCallback()
            end
        end
    end)
    
    return background
end

-- Create a simple notification
function DialogFactory.createNotification(message, duration, type)
    -- Set defaults
    duration = duration or 3
    type = type or "info"
    
    -- Get appropriate colors based on type
    local colors = {
        info = UIStyle.Colors.Info,
        success = UIStyle.Colors.Success,
        warning = UIStyle.Colors.Warning,
        error = UIStyle.Colors.Danger
    }
    
    local iconNames = {
        info = "Info",
        success = "Check",
        warning = "Warning",
        error = "Error"
    }
    
    local backgroundColor = colors[type] or UIStyle.Colors.Info
    local iconName = iconNames[type] or "Info"
    
    -- Get player GUI
    local player = Players.LocalPlayer
    if not player then return end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Create notification container if it doesn't exist
    local notificationGui = playerGui:FindFirstChild("NotificationGui")
    if not notificationGui then
        notificationGui = Instance.new("ScreenGui")
        notificationGui.Name = "NotificationGui"
        notificationGui.ResetOnSpawn = false
        notificationGui.Parent = playerGui
        
        -- Create container to hold notifications
        local container = Instance.new("Frame")
        container.Name = "NotificationContainer"
        container.Size = UDim2.new(0, 300, 1, -20)
        container.Position = UDim2.new(1, -320, 0, 10)
        container.BackgroundTransparency = 1
        container.Parent = notificationGui
        
        -- Add list layout to stack notifications
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 10)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = container
    end
    
    local notificationContainer = notificationGui.NotificationContainer
    
    -- Create the notification frame
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "Notification"
    notificationFrame.Size = UDim2.new(1, 0, 0, 60)
    notificationFrame.BackgroundColor3 = backgroundColor
    notificationFrame.BackgroundTransparency = 0.2
    notificationFrame.BorderSizePixel = 0
    notificationFrame.LayoutOrder = -tick() -- Use negative timestamp to sort newest at top
    notificationFrame.Parent = notificationContainer
    
    -- Add corner rounding
    addCorner(notificationFrame, UDim.new(0, 8))
    
    -- Add icon
    local icon = IconSet and IconSet.createIcon(iconName, UDim2.new(0, 24, 0, 24), UDim2.new(0, 12, 0.5, -12)) 
            or Instance.new("ImageLabel")
    
    if not IconSet then
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 12, 0.5, -12)
        icon.BackgroundTransparency = 1
    end
    
    icon.Parent = notificationFrame
    
    -- Message text
    local messageText = Instance.new("TextLabel")
    messageText.Name = "Message"
    messageText.Size = UDim2.new(1, -60, 1, 0)
    messageText.Position = UDim2.new(0, 48, 0, 0)
    messageText.BackgroundTransparency = 1
    messageText.Font = UIStyle.Fonts.Regular
    messageText.TextSize = UIStyle.TextSizes.Medium
    messageText.TextColor3 = UIStyle.Colors.Text
    messageText.Text = message
    messageText.TextWrapped = true
    messageText.TextXAlignment = Enum.TextXAlignment.Left
    messageText.TextYAlignment = Enum.TextYAlignment.Center
    messageText.Parent = notificationFrame
    
    -- Close button
    local closeBtn = ButtonFactory.createCloseButton(notificationFrame, UDim2.new(1, -8, 0, 8), function()
        -- Fade out and destroy
        TweenService:Create(notificationFrame, UIStyle.Animations.Fast, {
            Position = UDim2.new(1, 0, 0, notificationFrame.Position.Y.Offset),
            BackgroundTransparency = 1
        }):Play()
        
        -- Destroy after animation
        task.delay(0.2, function()
            notificationFrame:Destroy()
        end)
    end)
    
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.TextSize = 12
    
    -- Animate in
    notificationFrame.Position = UDim2.new(1, 0, 0, 0)
    notificationFrame.BackgroundTransparency = 1
    
    TweenService:Create(notificationFrame, UIStyle.Animations.Fast, {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.2
    }):Play()
    
    -- Auto-close after duration
    if duration > 0 then
        task.delay(duration, function()
            if notificationFrame and notificationFrame.Parent then
                -- Fade out and destroy
                TweenService:Create(notificationFrame, UIStyle.Animations.Fast, {
                    Position = UDim2.new(1, 0, 0, notificationFrame.Position.Y.Offset),
                    BackgroundTransparency = 1
                }):Play()
                
                -- Destroy after animation
                task.delay(0.2, function()
                    notificationFrame:Destroy()
                end)
            end
        end)
    end
    
    return notificationFrame
end

-- Create a confirmation dialog
function DialogFactory.createConfirmationDialog(title, message, confirmCallback, cancelCallback, options)
    options = options or {}
    
    -- Get player GUI
    local player = Players.LocalPlayer
    if not player then return end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Create a screen GUI for the dialog
    local dialogGui = Instance.new("ScreenGui")
    dialogGui.Name = "ConfirmationDialog"
    dialogGui.ResetOnSpawn = false
    dialogGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    dialogGui.Parent = playerGui
    
    -- Create the modal background
    local modalBackground = createModalBackground(UIStyle.ZIndex.Overlay, function()
        if options.closeOnOutsideClick ~= false then
            if cancelCallback then cancelCallback() end
            dialogGui:Destroy()
        end
    end)
    modalBackground.Parent = dialogGui
    
    -- Create the dialog frame
    local dialogFrame = Instance.new("Frame")
    dialogFrame.Name = "DialogFrame"
    dialogFrame.Size = UDim2.new(0, 400, 0, 200)
    dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    dialogFrame.BackgroundColor3 = UIStyle.Colors.Background
    dialogFrame.BorderSizePixel = 0
    dialogFrame.ZIndex = UIStyle.ZIndex.Foreground
    dialogFrame.Parent = dialogGui
    
    -- Add corner rounding
    addCorner(dialogFrame, UDim.new(0, 10))
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = UIStyle.Colors.HeaderBackground
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = UIStyle.ZIndex.Foreground
    titleBar.Parent = dialogFrame
    
    -- Add corner rounding to title bar (top corners only)
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Fix title bar bottom corners (make them straight)
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Name = "BottomFrame"
    bottomFrame.Size = UDim2.new(1, 0, 0, 10)
    bottomFrame.Position = UDim2.new(0, 0, 1, -10)
    bottomFrame.BackgroundColor3 = UIStyle.Colors.HeaderBackground
    bottomFrame.BorderSizePixel = 0
    bottomFrame.ZIndex = UIStyle.ZIndex.Foreground
    bottomFrame.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -60, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = UIStyle.Fonts.Bold
    titleText.TextSize = UIStyle.TextSizes.Large
    titleText.TextColor3 = UIStyle.Colors.Text
    titleText.Text = title
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = UIStyle.ZIndex.Foreground
    titleText.Parent = titleBar
    
    -- Close button
    local closeBtn = ButtonFactory.createCloseButton(titleBar, UDim2.new(1, -10, 0.5, 0), function()
        if cancelCallback then cancelCallback() end
        dialogGui:Destroy()
    end)
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.ZIndex = UIStyle.ZIndex.Foreground + 1
    
    -- Message text
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -40, 0, 80)
    messageLabel.Position = UDim2.new(0, 20, 0, 50)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = UIStyle.Fonts.Regular
    messageLabel.TextSize = UIStyle.TextSizes.Medium
    messageLabel.TextColor3 = UIStyle.Colors.Text
    messageLabel.Text = message
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Center
    messageLabel.TextYAlignment = Enum.TextYAlignment.Center
    messageLabel.ZIndex = UIStyle.ZIndex.Foreground
    messageLabel.Parent = dialogFrame
    
    -- Button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -40, 0, 50)
    buttonContainer.Position = UDim2.new(0, 20, 1, -60)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.ZIndex = UIStyle.ZIndex.Foreground
    buttonContainer.Parent = dialogFrame
    
    -- Confirm button
    local confirmText = options.confirmText or "Confirm"
    local confirmButton = ButtonFactory.createConfirmButton(confirmText, UDim2.new(0, 150, 0, 40), UDim2.new(0, 0, 0.5, -20), function()
        if confirmCallback then confirmCallback() end
        dialogGui:Destroy()
    end)
    confirmButton.Parent = buttonContainer
    confirmButton.ZIndex = UIStyle.ZIndex.Foreground
    
    -- Cancel button
    local cancelText = options.cancelText or "Cancel"
    local cancelButton = ButtonFactory.createCancelButton(cancelText, UDim2.new(0, 150, 0, 40), UDim2.new(1, -150, 0.5, -20), function()
        if cancelCallback then cancelCallback() end
        dialogGui:Destroy()
    end)
    cancelButton.Parent = buttonContainer
    cancelButton.ZIndex = UIStyle.ZIndex.Foreground
    
    -- Animate the dialog appearing
    dialogFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(dialogFrame, UIStyle.Animations.Standard, {
        Size = UDim2.new(0, 400, 0, 200)
    }):Play()
    
    -- Return interface
    return {
        gui = dialogGui,
        destroy = function()
            dialogGui:Destroy()
        end
    }
end

-- Create a custom modal dialog with flexible content
function DialogFactory.createModalDialog(title, contentCreator, options)
    options = options or {}
    local width = options.width or 500
    local height = options.height or 300
    
    -- Get player GUI
    local player = Players.LocalPlayer
    if not player then return end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Create a screen GUI for the dialog
    local dialogGui = Instance.new("ScreenGui")
    dialogGui.Name = "ModalDialog"
    dialogGui.ResetOnSpawn = false
    dialogGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    dialogGui.Parent = playerGui
    
    -- Create the modal background
    local modalBackground = createModalBackground(UIStyle.ZIndex.Overlay, function()
        if options.closeOnOutsideClick ~= false and options.onClose then
            options.onClose()
        end
        if options.closeOnOutsideClick ~= false then
            dialogGui:Destroy()
        end
    end)
    modalBackground.Parent = dialogGui
    
    -- Create the dialog frame
    local dialogFrame = Instance.new("Frame")
    dialogFrame.Name = "DialogFrame"
    dialogFrame.Size = UDim2.new(0, width, 0, height)
    dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    dialogFrame.BackgroundColor3 = UIStyle.Colors.Background
    dialogFrame.BorderSizePixel = 0
    dialogFrame.ZIndex = UIStyle.ZIndex.Foreground
    dialogFrame.Parent = dialogGui
    
    -- Add corner rounding
    addCorner(dialogFrame, UDim.new(0, 10))
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = UIStyle.Colors.HeaderBackground
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = UIStyle.ZIndex.Foreground
    titleBar.Parent = dialogFrame
    
    -- Add corner rounding to title bar (top corners only)
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Fix title bar bottom corners (make them straight)
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Name = "BottomFrame"
    bottomFrame.Size = UDim2.new(1, 0, 0, 10)
    bottomFrame.Position = UDim2.new(0, 0, 1, -10)
    bottomFrame.BackgroundColor3 = UIStyle.Colors.HeaderBackground
    bottomFrame.BorderSizePixel = 0
    bottomFrame.ZIndex = UIStyle.ZIndex.Foreground
    bottomFrame.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -60, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = UIStyle.Fonts.Bold
    titleText.TextSize = UIStyle.TextSizes.Large
    titleText.TextColor3 = UIStyle.Colors.Text
    titleText.Text = title
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = UIStyle.ZIndex.Foreground
    titleText.Parent = titleBar
    
    -- Close button
    local closeBtn = ButtonFactory.createCloseButton(titleBar, UDim2.new(1, -10, 0.5, 0), function()
        if options.onClose then options.onClose() end
        dialogGui:Destroy()
    end)
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.ZIndex = UIStyle.ZIndex.Foreground + 1
    
    -- Content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, -40)
    contentContainer.Position = UDim2.new(0, 0, 0, 40)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ZIndex = UIStyle.ZIndex.Foreground
    contentContainer.Parent = dialogFrame
    
    -- Create content using the provided function
    if typeof(contentCreator) == "function" then
        contentCreator(contentContainer)
    elseif typeof(contentCreator) == "string" then
        -- If a string is provided, create a simple text label
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -40, 1, -40)
        textLabel.Position = UDim2.new(0, 20, 0, 20)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = UIStyle.Fonts.Regular
        textLabel.TextSize = UIStyle.TextSizes.Medium
        textLabel.TextColor3 = UIStyle.Colors.Text
        textLabel.Text = contentCreator
        textLabel.TextWrapped = true
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextYAlignment = Enum.TextYAlignment.Top
        textLabel.ZIndex = UIStyle.ZIndex.Foreground
        textLabel.Parent = contentContainer
    end
    
    -- Animate the dialog appearing
    dialogFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(dialogFrame, UIStyle.Animations.Standard, {
        Size = UDim2.new(0, width, 0, height)
    }):Play()
    
    -- Make the dialog draggable if specified
    if options.draggable then
        local isDragging = false
        local dragInput
        local dragStart
        local startPos

        local function updateDrag(input)
            local delta = input.Position - dragStart
            dialogFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                                            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end

        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                dragStart = input.Position
                startPos = dialogFrame.Position
            end
        end)

        titleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
            end
        end)

        dialogGui.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        Players.LocalPlayer:GetMouse().Move:Connect(function()
            if isDragging and dragInput then
                updateDrag(dragInput)
            end
        end)
    end
    
    -- Return interface
    return {
        gui = dialogGui,
        frame = dialogFrame,
        contentContainer = contentContainer,
        destroy = function()
            dialogGui:Destroy()
        end
    }
end

-- Create a tooltip that shows on hover
function DialogFactory.createTooltip(targetElement, tooltipText, position, width)
    position = position or "bottom"
    width = width or 200
    
    -- Ensure target element isn't nil
    if not targetElement then
        warn("Target element for tooltip is nil")
        return
    end
    
    -- Create tooltip container
    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, width, 0, 0) -- Height will be set automatically
    tooltip.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tooltip.BackgroundTransparency = 0.2
    tooltip.BorderSizePixel = 0
    tooltip.ZIndex = UIStyle.ZIndex.Topmost
    tooltip.Visible = false
    tooltip.AutomaticSize = Enum.AutomaticSize.Y
    
    -- Add corner rounding
    addCorner(tooltip, UDim.new(0, 6))
    
    -- Add tooltip text
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "TooltipText"
    textLabel.Size = UDim2.new(1, -16, 0, 0)
    textLabel.Position = UDim2.new(0, 8, 0, 8)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = UIStyle.Fonts.Regular
    textLabel.TextSize = UIStyle.TextSizes.Small
    textLabel.TextColor3 = UIStyle.Colors.Text
    textLabel.Text = tooltipText
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.ZIndex = UIStyle.ZIndex.Topmost
    textLabel.AutomaticSize = Enum.AutomaticSize.Y
    textLabel.Parent = tooltip
    
    -- Set parent
    local player = Players.LocalPlayer
    if not player then return end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Create a tooltips container if it doesn't exist
    local tooltipsContainer = playerGui:FindFirstChild("TooltipsContainer")
    if not tooltipsContainer then
        tooltipsContainer = Instance.new("ScreenGui")
        tooltipsContainer.Name = "TooltipsContainer"
        tooltipsContainer.ResetOnSpawn = false
        tooltipsContainer.Parent = playerGui
    end
    
    tooltip.Parent = tooltipsContainer
    
    -- Show tooltip on hover
    targetElement.MouseEnter:Connect(function()
        -- Calculate position 
        local mouse = player:GetMouse()
        local targetPosition = targetElement.AbsolutePosition
        local targetSize = targetElement.AbsoluteSize
        
        if position == "bottom" then
            tooltip.Position = UDim2.new(0, targetPosition.X + targetSize.X/2 - width/2, 0, targetPosition.Y + targetSize.Y + 10)
        elseif position == "top" then
            tooltip.Position = UDim2.new(0, targetPosition.X + targetSize.X/2 - width/2, 0, targetPosition.Y - 10 - tooltip.AbsoluteSize.Y)
        elseif position == "left" then
            tooltip.Position = UDim2.new(0, targetPosition.X - width - 10, 0, targetPosition.Y + targetSize.Y/2 - tooltip.AbsoluteSize.Y/2)
        elseif position == "right" then
            tooltip.Position = UDim2.new(0, targetPosition.X + targetSize.X + 10, 0, targetPosition.Y + targetSize.Y/2 - tooltip.AbsoluteSize.Y/2)
        end
        
        -- Make tooltip visible
        tooltip.Visible = true
    end)
    
    -- Hide tooltip when mouse leaves
    targetElement.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
    
    return tooltip
end

-- Create an input dialog (e.g., for alliance search)
function DialogFactory.createInputDialog(title, prompt, defaultValue, confirmCallback, cancelCallback, options)
    options = options or {}
    
    -- Get player GUI
    local player = Players.LocalPlayer
    if not player then return end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Create the modal dialog
    local dialog = DialogFactory.createModalDialog(title, function(container)
        -- Create prompt text
        local promptLabel = Instance.new("TextLabel")
        promptLabel.Name = "PromptLabel"
        promptLabel.Size = UDim2.new(1, -40, 0, 40)
        promptLabel.Position = UDim2.new(0, 20, 0, 20)
        promptLabel.BackgroundTransparency = 1
        promptLabel.Font = UIStyle.Fonts.Regular
        promptLabel.TextSize = UIStyle.TextSizes.Medium
        promptLabel.TextColor3 = UIStyle.Colors.Text
        promptLabel.Text = prompt
        promptLabel.TextWrapped = true
        promptLabel.TextXAlignment = Enum.TextXAlignment.Left
        promptLabel.Parent = container
        
        -- Create input field
        local inputField = Instance.new("TextBox")
        inputField.Name = "InputField"
        inputField.Size = UDim2.new(1, -40, 0, 40)
        inputField.Position = UDim2.new(0, 20, 0, 70)
        inputField.BackgroundColor3 = UIStyle.Colors.BackgroundDark
        inputField.Font = UIStyle.Fonts.Regular
        inputField.TextSize = UIStyle.TextSizes.Medium
        inputField.TextColor3 = UIStyle.Colors.Text
        inputField.Text = defaultValue or ""
        inputField.PlaceholderText = options.placeholder or "Enter text..."
        inputField.ClearTextOnFocus = options.clearOnFocus ~= false
        inputField.TextXAlignment = Enum.TextXAlignment.Left
        inputField.Parent = container
        
        -- Add rounded corners to input field
        addCorner(inputField, UDim.new(0, 6))
        
        -- Add padding inside input field
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = inputField
        
        -- Button container
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Name = "ButtonContainer"
        buttonContainer.Size = UDim2.new(1, -40, 0, 50)
        buttonContainer.Position = UDim2.new(0, 20, 1, -60)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.Parent = container
        
        -- Confirm button
        local confirmText = options.confirmText or "Confirm"
        local confirmButton = ButtonFactory.createConfirmButton(confirmText, UDim2.new(0, 150, 0, 40), UDim2.new(0, 0, 0.5, -20), function()
            if confirmCallback then confirmCallback(inputField.Text) end
            dialog.destroy()
        end)
        confirmButton.Parent = buttonContainer
        
        -- Cancel button
        local cancelText = options.cancelText or "Cancel"
        local cancelButton = ButtonFactory.createCancelButton(cancelText, UDim2.new(0, 150, 0, 40), UDim2.new(1, -150, 0.5, -20), function()
            if cancelCallback then cancelCallback() end
            dialog.destroy()
        end)
        cancelButton.Parent = buttonContainer
        
        -- Focus the input field after creation
        task.defer(function()
            inputField:CaptureFocus()
        end)
        
        -- Connect enter key to confirm
        inputField.FocusLost:Connect(function(enterPressed)
            if enterPressed and confirmCallback then
                confirmCallback(inputField.Text)
                dialog.destroy()
            end
        end)
    end, {
        width = 400,
        height = 200,
        closeOnOutsideClick = options.closeOnOutsideClick,
        onClose = cancelCallback
    })
    
    return dialog
end

return DialogFactory