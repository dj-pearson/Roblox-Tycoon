--!strict
--[[
    DialogFactory.luau
    
    A factory module for creating various dialog components such as alerts, modals, 
    notifications, and prompts with consistent styling and behavior.
    
    Created: April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")

-- Try to load dependencies
local UIStyle, ButtonFactory

-- Try to load UIStyle
pcall(function()
    UIStyle = require(ReplicatedStorage.shared.UIStyle)
end)

-- Try to load ButtonFactory
pcall(function()
    ButtonFactory = require(ReplicatedStorage.shared.ButtonFactory)
end)

-- Create fallback styles if modules not found
if not UIStyle then
    UIStyle = {
        Colors = {
            Primary = Color3.fromRGB(0, 120, 215),
            Background = Color3.fromRGB(40, 40, 60),
            BackgroundLight = Color3.fromRGB(60, 60, 80),
            Text = Color3.fromRGB(240, 240, 255),
            Success = Color3.fromRGB(40, 180, 100),
            Warning = Color3.fromRGB(255, 190, 0),
            Danger = Color3.fromRGB(220, 50, 50),
            Info = Color3.fromRGB(80, 170, 240)
        },
        Fonts = {
            Regular = Enum.Font.Gotham,
            Bold = Enum.Font.GothamBold,
            SemiBold = Enum.Font.GothamSemibold
        },
        TextSizes = {
            Small = 12,
            Medium = 16,
            Large = 20,
            Header = 22
        },
        Animations = {
            Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        }
    }
end

-- Create utility functions if ButtonFactory not found
local function createDefaultButton(text, callback, parent)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 0, 40)
    button.BackgroundColor3 = UIStyle.Colors.Primary
    button.TextColor3 = UIStyle.Colors.Text
    button.Font = UIStyle.Fonts.SemiBold
    button.TextSize = UIStyle.TextSizes.Medium
    button.Text = text
    button.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    if callback and typeof(callback) == "function" then
        button.MouseButton1Click:Connect(callback)
    end
    
    if parent then
        button.Parent = parent
    end
    
    return button
end

local function createDefaultCloseButton(callback, parent)
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -10, 0, 10)
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.BackgroundColor3 = UIStyle.Colors.Danger
    closeButton.TextColor3 = UIStyle.Colors.Text
    closeButton.Font = UIStyle.Fonts.Bold
    closeButton.TextSize = 18
    closeButton.Text = "X"
    closeButton.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = closeButton
    
    if callback and typeof(callback) == "function" then
        closeButton.MouseButton1Click:Connect(callback)
    end
    
    if parent then
        closeButton.Parent = parent
    end
    
    return closeButton
end

-- Ensure the dialog container exists
local function getDialogContainer()
    if not PlayerGui then
        warn("PlayerGui not found")
        return nil
    end
    
    local dialogContainer = PlayerGui:FindFirstChild("DialogContainer")
    
    if not dialogContainer then
        dialogContainer = Instance.new("ScreenGui")
        dialogContainer.Name = "DialogContainer"
        dialogContainer.ResetOnSpawn = false
        dialogContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        dialogContainer.Parent = PlayerGui
    end
    
    return dialogContainer
end

local DialogFactory = {}

-- Create a notification toast
function DialogFactory:createNotification(config)
    config = config or {}
    
    -- Get or create the notification container
    local dialogContainer = getDialogContainer()
    if not dialogContainer then
        return nil
    end
    
    local notificationContainer = dialogContainer:FindFirstChild("NotificationContainer")
    if not notificationContainer then
        notificationContainer = Instance.new("Frame")
        notificationContainer.Name = "NotificationContainer"
        notificationContainer.Size = UDim2.new(0, 300, 1, 0)
        notificationContainer.Position = UDim2.new(1, -320, 0, 0)
        notificationContainer.BackgroundTransparency = 1
        notificationContainer.Parent = dialogContainer
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 10)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = notificationContainer
        
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 20)
        padding.Parent = notificationContainer
    end
    
    -- Create notification frame
    local notification = Instance.new("Frame")
    notification.Name = "Notification_" .. os.time()
    notification.Size = UDim2.new(1, -40, 0, 0)
    notification.AutomaticSize = Enum.AutomaticSize.Y
    notification.BackgroundColor3 = config.backgroundColor or UIStyle.Colors.BackgroundLight
    notification.BorderSizePixel = 0
    notification.BackgroundTransparency = 0
    notification.Position = UDim2.new(1, 20, 0, 0)
    notification.Parent = notificationContainer
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    -- Add left color indicator based on notification type
    local colorIndicator = Instance.new("Frame")
    colorIndicator.Name = "ColorIndicator"
    colorIndicator.Size = UDim2.new(0, 6, 1, 0)
    colorIndicator.BorderSizePixel = 0
    
    -- Set color based on type
    if config.type == "success" then
        colorIndicator.BackgroundColor3 = UIStyle.Colors.Success
    elseif config.type == "warning" then
        colorIndicator.BackgroundColor3 = UIStyle.Colors.Warning
    elseif config.type == "error" then
        colorIndicator.BackgroundColor3 = UIStyle.Colors.Danger
    else -- info (default)
        colorIndicator.BackgroundColor3 = UIStyle.Colors.Info
    end
    colorIndicator.Parent = notification
    
    -- Add title if provided
    local contentY = 10
    if config.title then
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -20, 0, 24)
        title.Position = UDim2.new(0, 20, 0, 10)
        title.BackgroundTransparency = 1
        title.TextColor3 = UIStyle.Colors.Text
        title.TextSize = UIStyle.TextSizes.Medium
        title.Font = UIStyle.Fonts.Bold
        title.Text = config.title
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextWrapped = true
        title.Parent = notification
        
        contentY = 40
    end
    
    -- Add message content
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -20, 0, 0)
    message.Position = UDim2.new(0, 20, 0, contentY)
    message.BackgroundTransparency = 1
    message.TextColor3 = UIStyle.Colors.Text
    message.TextSize = UIStyle.TextSizes.Medium
    message.Font = UIStyle.Fonts.Regular
    message.Text = config.message or "Notification"
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = true
    message.AutomaticSize = Enum.AutomaticSize.Y
    message.Parent = notification
    
    -- Add padding at bottom
    local paddingFrame = Instance.new("Frame")
    paddingFrame.Name = "Padding"
    paddingFrame.Size = UDim2.new(1, 0, 0, 10)
    paddingFrame.Position = UDim2.new(0, 0, 0, 0)
    paddingFrame.BackgroundTransparency = 1
    paddingFrame.AutomaticSize = Enum.AutomaticSize.Y
    paddingFrame.AnchorPoint = Vector2.new(0, 0)
    paddingFrame.LayoutOrder = 100
    paddingFrame.Parent = notification
    
    -- Connect message to padding
    local function updatePaddingPosition()
        paddingFrame.Position = UDim2.new(0, 0, 0, message.Position.Y.Offset + message.AbsoluteSize.Y)
    end
    
    message:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePaddingPosition)
    updatePaddingPosition()
    
    -- Add close button
    local closeButton
    if ButtonFactory then
        closeButton = ButtonFactory:createCloseButton({
            size = UDim2.new(0, 24, 0, 24),
            position = UDim2.new(1, -10, 0, 10),
            anchorPoint = Vector2.new(1, 0),
            zIndex = 10,
            parent = notification,
        })
    else
        closeButton = createDefaultCloseButton(nil, notification)
        closeButton.Size = UDim2.new(0, 24, 0, 24)
        closeButton.Position = UDim2.new(1, -10, 0, 10)
    end
    
    -- Animation and auto-close
    -- Slide in from right
    notification.Position = UDim2.new(1, 20, 0, 0)
    local finalPosition = UDim2.new(0, 0, 0, 0)
    
    TweenService:Create(notification, UIStyle.Animations.Standard, {
        Position = finalPosition
    }):Play()
    
    -- Set up auto-close
    local duration = config.duration or 5
    local autoClose = config.autoClose ~= false
    local closed = false
    
    -- Create close function
    local function close()
        if closed then return end
        closed = true
        
        -- Slide out to the right
        local closeTween = TweenService:Create(notification, UIStyle.Animations.Standard, {
            Position = UDim2.new(1, 20, 0, 0)
        })
        
        closeTween:Play()
        closeTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(close)
    
    -- Set up auto-close timer
    if autoClose then
        task.delay(duration, close)
    end
    
    -- Add method to programmatically close the notification
    notification.Close = close
    
    return notification
end

-- Create a modal dialog
function DialogFactory:createModal(config)
    config = config or {}
    
    -- Get dialog container
    local dialogContainer = getDialogContainer()
    if not dialogContainer then
        return nil
    end
    
    -- Create the backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Name = "ModalBackdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 1 -- Start transparent for tween
    backdrop.ZIndex = 100
    backdrop.Parent = dialogContainer
    
    -- Create the modal
    local modal = Instance.new("Frame")
    modal.Name = "Modal"
    modal.Size = config.size or UDim2.new(0, 400, 0, 300)
    modal.AnchorPoint = Vector2.new(0.5, 0.5)
    modal.Position = UDim2.new(0.5, 0, 0.5, 0)
    modal.BackgroundColor3 = config.backgroundColor or UIStyle.Colors.Background
    modal.BorderSizePixel = 0
    modal.ZIndex = 101
    modal.BackgroundTransparency = 1 -- Start transparent for tween
    modal.Parent = backdrop
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = modal
    
    -- Create header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = config.headerColor or UIStyle.Colors.Primary
    header.BorderSizePixel = 0
    header.ZIndex = 102
    header.Parent = modal
    
    -- Add corner rounding to header (top only)
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    -- Add a frame to square off the bottom corners
    local headerBottom = Instance.new("Frame")
    headerBottom.Name = "HeaderBottom"
    headerBottom.Size = UDim2.new(1, 0, 0, 10)
    headerBottom.Position = UDim2.new(0, 0, 1, -10)
    headerBottom.BackgroundColor3 = header.BackgroundColor3
    headerBottom.BorderSizePixel = 0
    headerBottom.ZIndex = 102
    headerBottom.Parent = header
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = UIStyle.Colors.Text
    title.TextSize = UIStyle.TextSizes.Header
    title.Font = UIStyle.Fonts.Bold
    title.Text = config.title or "Modal"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 103
    title.Parent = header
    
    -- Add close button
    local closeButton
    if ButtonFactory then
        closeButton = ButtonFactory:createCloseButton({
            position = UDim2.new(1, -15, 0.5, 0),
            anchorPoint = Vector2.new(1, 0.5),
            zIndex = 103,
            parent = header
        })
    else
        closeButton = createDefaultCloseButton(nil, header)
        closeButton.Position = UDim2.new(1, -15, 0.5, 0)
        closeButton.AnchorPoint = Vector2.new(1, 0.5)
        closeButton.ZIndex = 103
    end
    
    -- Create content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -50)
    content.Position = UDim2.new(0, 0, 0, 50)
    content.BackgroundTransparency = 1
    content.ZIndex = 102
    content.Parent = modal
    
    -- Add padding to content
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.PaddingTop = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = content
    
    -- Add message if provided
    if config.message then
        local message = Instance.new("TextLabel")
        message.Name = "Message"
        message.Size = UDim2.new(1, 0, 0, 0)
        message.AutomaticSize = Enum.AutomaticSize.Y
        message.BackgroundTransparency = 1
        message.TextColor3 = UIStyle.Colors.Text
        message.TextSize = UIStyle.TextSizes.Medium
        message.Font = UIStyle.Fonts.Regular
        message.Text = config.message
        message.TextWrapped = true
        message.TextXAlignment = Enum.TextXAlignment.Left
        message.TextYAlignment = Enum.TextYAlignment.Top
        message.ZIndex = 102
        message.Parent = content
    end
    
    -- Add buttons if provided
    if config.buttons and #config.buttons > 0 then
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Name = "ButtonContainer"
        buttonContainer.Size = UDim2.new(1, 0, 0, 50)
        buttonContainer.Position = UDim2.new(0, 0, 1, -70)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.ZIndex = 102
        buttonContainer.Parent = modal
        
        local buttonLayout = Instance.new("UIListLayout")
        buttonLayout.Padding = UDim.new(0, 10)
        buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        buttonLayout.HorizontalAlignment = config.buttonAlignment or Enum.HorizontalAlignment.Right
        buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
        buttonLayout.Parent = buttonContainer
        
        for i, buttonConfig in ipairs(config.buttons) do
            local button
            if ButtonFactory then
                button = ButtonFactory:createTextButton({
                    text = buttonConfig.text,
                    style = buttonConfig.style,
                    callback = buttonConfig.callback,
                    parent = buttonContainer
                })
            else
                button = createDefaultButton(buttonConfig.text, buttonConfig.callback, buttonContainer)
                
                if buttonConfig.style == "primary" then
                    button.BackgroundColor3 = UIStyle.Colors.Primary
                elseif buttonConfig.style == "danger" then
                    button.BackgroundColor3 = UIStyle.Colors.Danger
                elseif buttonConfig.style == "success" then
                    button.BackgroundColor3 = UIStyle.Colors.Success
                end
            end
            
            button.LayoutOrder = i
        end
    end
    
    -- Animation
    -- Fade in backdrop
    TweenService:Create(backdrop, UIStyle.Animations.Standard, {
        BackgroundTransparency = 0.5
    }):Play()
    
    -- Fade in and scale up modal
    modal.Size = UDim2.new(0, modal.Size.X.Offset * 0.8, 0, modal.Size.Y.Offset * 0.8)
    
    local modalTween = TweenService:Create(modal, UIStyle.Animations.Standard, {
        Size = config.size or UDim2.new(0, 400, 0, 300),
        BackgroundTransparency = 0
    })
    
    modalTween:Play()
    
    -- Create close function
    local closed = false
    
    local function close()
        if closed then return end
        closed = true
        
        -- Fade out and scale down
        local closeTweenBackdrop = TweenService:Create(backdrop, UIStyle.Animations.Standard, {
            BackgroundTransparency = 1
        })
        
        local closeTweenModal = TweenService:Create(modal, UIStyle.Animations.Standard, {
            Size = UDim2.new(0, modal.Size.X.Offset * 0.8, 0, modal.Size.Y.Offset * 0.8),
            BackgroundTransparency = 1
        })
        
        closeTweenBackdrop:Play()
        closeTweenModal:Play()
        
        closeTweenModal.Completed:Connect(function()
            backdrop:Destroy()
        end)
        
        -- Call onClose callback if provided
        if config.onClose and typeof(config.onClose) == "function" then
            config.onClose()
        end
    end
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(close)
    
    -- Add method to programmatically close the modal
    backdrop.Close = close
    modal.Close = close
    
    -- Add method to update content
    function backdrop:setMessage(newMessage)
        local messageLabel = content:FindFirstChild("Message")
        
        if messageLabel then
            messageLabel.Text = newMessage
        else
            local newMessageLabel = Instance.new("TextLabel")
            newMessageLabel.Name = "Message"
            newMessageLabel.Size = UDim2.new(1, 0, 0, 0)
            newMessageLabel.AutomaticSize = Enum.AutomaticSize.Y
            newMessageLabel.BackgroundTransparency = 1
            newMessageLabel.TextColor3 = UIStyle.Colors.Text
            newMessageLabel.TextSize = UIStyle.TextSizes.Medium
            newMessageLabel.Font = UIStyle.Fonts.Regular
            newMessageLabel.Text = newMessage
            newMessageLabel.TextWrapped = true
            newMessageLabel.TextXAlignment = Enum.TextXAlignment.Left
            newMessageLabel.TextYAlignment = Enum.TextYAlignment.Top
            newMessageLabel.ZIndex = 102
            newMessageLabel.Parent = content
        end
    end
    
    -- Allow closing by clicking backdrop if configured
    if config.closeOnBackdropClick ~= false then
        local backdropButton = Instance.new("TextButton")
        backdropButton.Text = ""
        backdropButton.Size = UDim2.new(1, 0, 1, 0)
        backdropButton.BackgroundTransparency = 1
        backdropButton.ZIndex = 99
        backdropButton.Parent = backdrop
        
        backdropButton.MouseButton1Click:Connect(function()
            close()
        end)
        
        -- Prevent clicks inside modal from closing
        local modalButton = Instance.new("TextButton")
        modalButton.Text = ""
        modalButton.Size = UDim2.new(1, 0, 1, 0)
        modalButton.BackgroundTransparency = 1
        modalButton.ZIndex = 101
        modalButton.Parent = modal
        
        modalButton.MouseButton1Down:Connect(function()
            -- Capture but ignore clicks inside modal
        end)
    end
    
    return backdrop
end

-- Create a confirmation dialog (Yes/No)
function DialogFactory:createConfirmDialog(config)
    config = config or {}
    
    -- Set up the modal config
    local modalConfig = {
        title = config.title or "Confirmation",
        message = config.message or "Are you sure you want to proceed?",
        size = config.size or UDim2.new(0, 400, 0, 200),
        closeOnBackdropClick = config.closeOnBackdropClick,
        buttonAlignment = Enum.HorizontalAlignment.Center,
        onClose = config.onClose,
        buttons = {
            {
                text = config.noText or "Cancel",
                style = "default",
                callback = function(modal)
                    if config.onNo and typeof(config.onNo) == "function" then
                        config.onNo()
                    end
                    modal.Parent.Close()
                end
            },
            {
                text = config.yesText or "Confirm",
                style = "primary",
                callback = function(modal)
                    if config.onYes and typeof(config.onYes) == "function" then
                        config.onYes()
                    end
                    modal.Parent.Close()
                end
            }
        }
    }
    
    -- Create the modal
    return DialogFactory:createModal(modalConfig)
end

-- Create an alert dialog (OK button only)
function DialogFactory:createAlertDialog(config)
    config = config or {}
    
    -- Set up the modal config
    local modalConfig = {
        title = config.title or "Alert",
        message = config.message or "This is an alert message.",
        size = config.size or UDim2.new(0, 400, 0, 200),
        closeOnBackdropClick = config.closeOnBackdropClick,
        buttonAlignment = Enum.HorizontalAlignment.Center,
        onClose = config.onClose,
        buttons = {
            {
                text = config.okText or "OK",
                style = "primary",
                callback = function(modal)
                    if config.onOk and typeof(config.onOk) == "function" then
                        config.onOk()
                    end
                    modal.Parent.Close()
                end
            }
        }
    }
    
    -- Create the modal
    return DialogFactory:createModal(modalConfig)
end

return DialogFactory
