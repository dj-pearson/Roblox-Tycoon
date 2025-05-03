--!strict
--[[
    DialogSystem.luau
    
    A centralized system for creating and managing dialogs, modals, and popups.
    
    Created: May 4, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Import ModuleLoaderHelper
local ModuleLoaderHelper = nil
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
    else
        warn("[DialogSystem] Failed to load ModuleLoaderHelper, using direct requires")
    end
end

-- Load UIComponentBase
local UIComponentBase
if ModuleLoaderHelper then
    UIComponentBase = ModuleLoaderHelper.loadModule("UI/UIComponentBase")
else
    local componentBasePath = ReplicatedStorage:FindFirstChild("shared") and 
                             ReplicatedStorage.shared:FindFirstChild("UI") and 
                             ReplicatedStorage.shared.UI:FindFirstChild("UIComponentBase")
    
    if componentBasePath then
        UIComponentBase = require(componentBasePath)
    end
end

if not UIComponentBase then
    error("[DialogSystem] Required dependency UIComponentBase not found")
end

-- Load CardComponent
local CardComponent
if ModuleLoaderHelper then
    CardComponent = ModuleLoaderHelper.loadModule("UI/Components/CardComponent")
else
    local cardComponentPath = ReplicatedStorage:FindFirstChild("shared") and 
                              ReplicatedStorage.shared:FindFirstChild("UI") and 
                              ReplicatedStorage.shared.UI:FindFirstChild("Components") and
                              ReplicatedStorage.shared.UI.Components:FindFirstChild("CardComponent")
    
    if cardComponentPath then
        CardComponent = require(cardComponentPath)
    end
end

-- Load ButtonComponent
local ButtonComponent
if ModuleLoaderHelper then
    ButtonComponent = ModuleLoaderHelper.loadModule("UI/Components/ButtonComponent")
else
    local buttonComponentPath = ReplicatedStorage:FindFirstChild("shared") and 
                               ReplicatedStorage.shared:FindFirstChild("UI") and 
                               ReplicatedStorage.shared.UI:FindFirstChild("Components") and
                               ReplicatedStorage.shared.UI.Components:FindFirstChild("ButtonComponent")
    
    if buttonComponentPath then
        ButtonComponent = require(buttonComponentPath)
    end
end

-- Load TextComponent
local TextComponent
if ModuleLoaderHelper then
    TextComponent = ModuleLoaderHelper.loadModule("UI/Components/TextComponent")
else
    local textComponentPath = ReplicatedStorage:FindFirstChild("shared") and 
                             ReplicatedStorage.shared:FindFirstChild("UI") and 
                             ReplicatedStorage.shared.UI:FindFirstChild("Components") and
                             ReplicatedStorage.shared.UI.Components:FindFirstChild("TextComponent")
    
    if textComponentPath then
        TextComponent = require(textComponentPath)
    end
end

-- Load UIStyleSystem
local UIStyleSystem
if ModuleLoaderHelper then
    UIStyleSystem = ModuleLoaderHelper.loadModule("UI/UIStyleSystem")
else
    local styleSystemPath = ReplicatedStorage:FindFirstChild("shared") and 
                           ReplicatedStorage.shared:FindFirstChild("UI") and 
                           ReplicatedStorage.shared.UI:FindFirstChild("UIStyleSystem")
    
    if styleSystemPath then
        UIStyleSystem = require(styleSystemPath)
    end
end

-- Default animation settings
local DEFAULT_ANIMATIONS = {
    fadeIn = {
        duration = 0.2,
        easing = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out
    },
    fadeOut = {
        duration = 0.2,
        easing = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.In
    },
    scaleIn = {
        duration = 0.3,
        easing = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out
    },
    scaleOut = {
        duration = 0.2,
        easing = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.In
    }
}

--[[
    DialogSystem - A centralized system for creating and managing dialogs
]]
local DialogSystem = {
    -- Active dialogs
    _activeDialogs = {},
    _dialogCounter = 0,
    
    -- Configuration
    config = {
        animations = DEFAULT_ANIMATIONS,
        defaultParent = nil, -- Will be set to PlayerGui when available
        defaultZIndex = 10,
        modalBackgroundColor = Color3.fromRGB(0, 0, 0),
        modalBackgroundTransparency = 0.5,
        defaultWidth = 400,
        defaultButtonHeight = 40,
        spacing = 16,
        padding = 24
    }
}

--[[
    Initialize the dialog system
    @return - Success status
]]
function DialogSystem.initialize()
    -- Check if system is already initialized
    if DialogSystem._initialized then
        return true
    end
    
    -- Try to find the PlayerGui to use as default parent
    if Players.LocalPlayer then
        DialogSystem.config.defaultParent = Players.LocalPlayer:FindFirstChild("PlayerGui")
    end
    
    DialogSystem._initialized = true
    return true
end

--[[
    Create a modal dialog
    @param options - Dialog options
    @return - Dialog ID and close function
]]
function DialogSystem.createModal(options)
    options = options or {}
    
    -- Increment dialog counter
    DialogSystem._dialogCounter += 1
    local dialogId = DialogSystem._dialogCounter
    
    -- Set default parent if not specified
    local parent = options.parent or DialogSystem.config.defaultParent
    if not parent then
        warn("[DialogSystem] No parent specified for dialog and no default parent available")
        return nil
    end
    
    -- Create components for the dialog
    local modal = DialogSystem._createModalContainer(parent, options)
    local dialogCard = DialogSystem._createDialogCard(modal, options)
    
    -- Animate entrance
    DialogSystem._animateEntrance(modal, dialogCard, options)
    
    -- Store active dialog
    DialogSystem._activeDialogs[dialogId] = {
        modal = modal,
        dialogCard = dialogCard,
        options = options
    }
    
    -- Create close function
    local closeFunction = function()
        return DialogSystem.closeDialog(dialogId)
    end
    
    return dialogId, closeFunction
end

--[[
    Create a simple alert dialog
    @param title - Dialog title
    @param message - Dialog message
    @param onConfirm - Confirm button callback (optional)
    @param options - Additional options (optional)
    @return - Dialog ID and close function
]]
function DialogSystem.alert(title, message, onConfirm, options)
    options = options or {}
    options.title = title
    options.message = message
    options.buttons = {
        {
            text = options.confirmText or "OK",
            style = "primary",
            onClick = function(closeDialog)
                if onConfirm then
                    onConfirm()
                end
                closeDialog()
            end
        }
    }
    
    return DialogSystem.createModal(options)
end

--[[
    Create a confirmation dialog
    @param title - Dialog title
    @param message - Dialog message
    @param onConfirm - Confirm button callback
    @param onCancel - Cancel button callback (optional)
    @param options - Additional options (optional)
    @return - Dialog ID and close function
]]
function DialogSystem.confirm(title, message, onConfirm, onCancel, options)
    options = options or {}
    options.title = title
    options.message = message
    options.buttons = {
        {
            text = options.confirmText or "Confirm",
            style = "primary",
            onClick = function(closeDialog)
                if onConfirm then
                    onConfirm()
                end
                closeDialog()
            end
        },
        {
            text = options.cancelText or "Cancel",
            style = "secondary",
            onClick = function(closeDialog)
                if onCancel then
                    onCancel()
                end
                closeDialog()
            end
        }
    }
    
    return DialogSystem.createModal(options)
end

--[[
    Create a prompt dialog with input
    @param title - Dialog title
    @param message - Dialog message (optional)
    @param onSubmit - Submit callback that receives the input value
    @param options - Additional options (optional)
    @return - Dialog ID and close function
]]
function DialogSystem.prompt(title, message, onSubmit, options)
    options = options or {}
    options.title = title
    options.message = message
    options.inputType = options.inputType or "text"
    options.defaultValue = options.defaultValue or ""
    options.placeholderText = options.placeholderText or "Enter value..."
    
    local inputValue = options.defaultValue
    options.customContent = function(contentFrame)
        -- Create text input
        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(1, 0, 0, 40)
        textBox.Position = UDim2.new(0, 0, 0, 0)
        textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        textBox.PlaceholderText = options.placeholderText
        textBox.Text = options.defaultValue
        textBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 200)
        textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        textBox.Font = Enum.Font.Gotham
        textBox.TextSize = 16
        textBox.BorderSizePixel = 0
        textBox.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = textBox
        
        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = textBox
        
        -- Update value when changed
        textBox.Changed:Connect(function(property)
            if property == "Text" then
                inputValue = textBox.Text
            end
        end)
        
        textBox.Parent = contentFrame
    end
    
    options.buttons = {
        {
            text = options.submitText or "Submit",
            style = "primary",
            onClick = function(closeDialog)
                if onSubmit then
                    onSubmit(inputValue)
                end
                closeDialog()
            end
        },
        {
            text = options.cancelText or "Cancel",
            style = "secondary",
            onClick = function(closeDialog)
                closeDialog()
            end
        }
    }
    
    return DialogSystem.createModal(options)
end

--[[
    Close a dialog by its ID
    @param dialogId - The ID of the dialog to close
    @return - Success status
]]
function DialogSystem.closeDialog(dialogId)
    local dialog = DialogSystem._activeDialogs[dialogId]
    if not dialog then
        return false
    end
    
    -- Animate dialog exit
    local success = DialogSystem._animateExit(dialog.modal, dialog.dialogCard, dialog.options, function()
        -- Cleanup
        dialog.modal:Destroy()
        DialogSystem._activeDialogs[dialogId] = nil
    end)
    
    return success
end

--[[
    Close all active dialogs
    @return - Success status
]]
function DialogSystem.closeAllDialogs()
    for dialogId, _ in pairs(DialogSystem._activeDialogs) do
        DialogSystem.closeDialog(dialogId)
    end
    
    return true
end

--[[
    Create the modal container (background)
    @param parent - Parent instance
    @param options - Dialog options
    @return - Modal container
]]
function DialogSystem._createModalContainer(parent, options)
    -- Create modal background
    local modal = Instance.new("Frame")
    modal.Name = "DialogModal_" .. DialogSystem._dialogCounter
    modal.Size = UDim2.new(1, 0, 1, 0)
    modal.Position = UDim2.new(0, 0, 0, 0)
    modal.BackgroundColor3 = options.modalBackgroundColor or DialogSystem.config.modalBackgroundColor
    modal.BackgroundTransparency = 1 -- Start transparent for animation
    modal.BorderSizePixel = 0
    modal.ZIndex = options.zIndex or DialogSystem.config.defaultZIndex
    
    -- Close on background click if allowed
    if options.closeOnBackgroundClick ~= false then
        local modalButton = Instance.new("TextButton")
        modalButton.Text = ""
        modalButton.Size = UDim2.new(1, 0, 1, 0)
        modalButton.BackgroundTransparency = 1
        modalButton.ZIndex = modal.ZIndex
        modalButton.AutoButtonColor = false
        
        modalButton.MouseButton1Click:Connect(function()
            -- Close if specifically enabled, or default behavior
            if options.closeOnBackgroundClick then
                DialogSystem.closeDialog(DialogSystem._dialogCounter)
            end
        end)
        
        modalButton.Parent = modal
    end
    
    modal.Parent = parent
    
    return modal
end

--[[
    Create the dialog card
    @param modal - Modal container
    @param options - Dialog options
    @return - Dialog card component
]]
function DialogSystem._createDialogCard(modal, options)
    local width = options.width or DialogSystem.config.defaultWidth
    local minHeight = options.minHeight or 150
    
    -- Create dialog card
    local dialogCard = CardComponent.new({
        name = "DialogCard",
        title = options.title,
        titlePosition = "top",
        titleStyle = "heading2",
        size = UDim2.new(0, width, 0, minHeight),
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchorPoint = Vector2.new(0.5, 0.5),
        backgroundColor = options.backgroundColor or Color3.fromRGB(50, 50, 70),
        cornerRadius = options.cornerRadius or 8,
        elevation = "high",
        shadow = true,
        padding = options.padding or DialogSystem.config.padding,
        zIndex = (options.zIndex or DialogSystem.config.defaultZIndex) + 1
    })
    
    -- Create content
    local contentContainer = dialogCard:getInstance():WaitForChild("Content")
    
    -- Add message text if provided
    if options.message then
        local messageComponent = TextComponent.new({
            text = options.message,
            textStyle = "body",
            size = UDim2.new(1, 0, 0, 0),
            autoSize = "height",
            wrap = true
        })
        
        messageComponent:mount(contentContainer)
    end
    
    -- Add custom content if provided
    if options.customContent and typeof(options.customContent) == "function" then
        options.customContent(contentContainer)
    end
    
    -- Add buttons if provided
    if options.buttons and #options.buttons > 0 then
        DialogSystem._createButtons(contentContainer, options, dialogCard:getInstance())
    end
    
    -- Mount the dialog card to the modal
    dialogCard:mount(modal)
    
    return dialogCard
end

--[[
    Create dialog buttons
    @param contentContainer - Content container
    @param options - Dialog options
    @param dialogInstance - Dialog card instance
]]
function DialogSystem._createButtons(contentContainer, options, dialogInstance)
    local buttonCount = #options.buttons
    local spacing = options.buttonSpacing or DialogSystem.config.spacing
    local buttonHeight = options.buttonHeight or DialogSystem.config.defaultButtonHeight
    
    -- Create button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, buttonHeight)
    buttonContainer.Position = UDim2.new(0, 0, 1, -buttonHeight - spacing)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.ZIndex = dialogInstance.ZIndex + 1
    
    -- Create button layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, spacing)
    layout.Parent = buttonContainer
    
    -- Create buttons
    for i, buttonInfo in ipairs(options.buttons) do
        -- Create button
        local button = ButtonComponent.new({
            text = buttonInfo.text,
            size = UDim2.new(0, buttonInfo.width or 100, 0, buttonHeight),
            backgroundColor = DialogSystem._getButtonColor(buttonInfo.style),
            cornerRadius = 4,
            layoutOrder = buttonCount - i + 1, -- Reverse order for right alignment
            textColor = Color3.fromRGB(255, 255, 255)
        })
        
        -- Set up click handler
        button:onClick(function()
            if buttonInfo.onClick then
                -- Pass close function
                local closeFunc = function()
                    DialogSystem.closeDialog(DialogSystem._dialogCounter)
                end
                
                buttonInfo.onClick(closeFunc)
            end
        end)
        
        button:mount(buttonContainer)
    end
    
    buttonContainer.Parent = contentContainer
end

--[[
    Get button color based on style
    @param style - Button style
    @return - Color3
]]
function DialogSystem._getButtonColor(style)
    if UIStyleSystem then
        if style == "primary" then
            return UIStyleSystem:getValue("colors.accent") or Color3.fromRGB(0, 120, 215)
        elseif style == "secondary" then
            return UIStyleSystem:getValue("colors.secondary") or Color3.fromRGB(80, 80, 100)
        elseif style == "success" then
            return UIStyleSystem:getValue("colors.success") or Color3.fromRGB(0, 170, 85)
        elseif style == "danger" then
            return UIStyleSystem:getValue("colors.danger") or Color3.fromRGB(200, 50, 50)
        elseif style == "warning" then
            return UIStyleSystem:getValue("colors.warning") or Color3.fromRGB(230, 150, 0)
        end
    end
    
    -- Fallback colors
    if style == "primary" then
        return Color3.fromRGB(0, 120, 215)
    elseif style == "secondary" then
        return Color3.fromRGB(80, 80, 100)
    elseif style == "success" then
        return Color3.fromRGB(0, 170, 85)
    elseif style == "danger" then
        return Color3.fromRGB(200, 50, 50)
    elseif style == "warning" then
        return Color3.fromRGB(230, 150, 0)
    end
    
    return Color3.fromRGB(100, 100, 120)
end

--[[
    Animate dialog entrance
    @param modal - Modal container
    @param dialogCard - Dialog card component
    @param options - Dialog options
    @return - Success status
]]
function DialogSystem._animateEntrance(modal, dialogCard, options)
    local animationType = options.animationType or "fade"
    
    -- Animate modal background
    local backgroundTween = TweenService:Create(
        modal,
        TweenInfo.new(
            DialogSystem.config.animations.fadeIn.duration,
            DialogSystem.config.animations.fadeIn.easing,
            DialogSystem.config.animations.fadeIn.direction
        ),
        {BackgroundTransparency = options.modalBackgroundTransparency or DialogSystem.config.modalBackgroundTransparency}
    )
    backgroundTween:Play()
    
    -- Get dialog instance
    local dialogInstance = dialogCard:getInstance()
    
    -- Different entrance animations
    if animationType == "scale" then
        -- Store original size
        local originalSize = dialogInstance.Size
        
        -- Start small
        dialogInstance.Size = UDim2.new(0, 0, 0, 0)
        
        -- Scale in
        local scaleTween = TweenService:Create(
            dialogInstance,
            TweenInfo.new(
                DialogSystem.config.animations.scaleIn.duration,
                DialogSystem.config.animations.scaleIn.easing,
                DialogSystem.config.animations.scaleIn.direction
            ),
            {Size = originalSize}
        )
        scaleTween:Play()
    elseif animationType == "fade" then
        -- Start transparent
        dialogInstance.BackgroundTransparency = 1
        
        local children = dialogInstance:GetDescendants()
        for _, child in ipairs(children) do
            if child:IsA("GuiObject") then
                if child.ClassName ~= "UICorner" and child.ClassName ~= "UIListLayout" then
                    child.BackgroundTransparency = 1
                end
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    child.TextTransparency = 1
                end
                if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                    child.ImageTransparency = 1
                end
            end
        end
        
        -- Fade in
        local dialogTween = TweenService:Create(
            dialogInstance,
            TweenInfo.new(
                DialogSystem.config.animations.fadeIn.duration,
                DialogSystem.config.animations.fadeIn.easing,
                DialogSystem.config.animations.fadeIn.direction
            ),
            {BackgroundTransparency = 0}
        )
        dialogTween:Play()
        
        -- Fade in all children
        for _, child in ipairs(children) do
            if child:IsA("GuiObject") then
                if child.ClassName ~= "UICorner" and child.ClassName ~= "UIListLayout" then
                    local targetTransparency = 0
                    if child.Name == "Shadow" then
                        targetTransparency = 0.7
                    end
                    
                    local childTween = TweenService:Create(
                        child,
                        TweenInfo.new(
                            DialogSystem.config.animations.fadeIn.duration,
                            DialogSystem.config.animations.fadeIn.easing,
                            DialogSystem.config.animations.fadeIn.direction
                        ),
                        {BackgroundTransparency = targetTransparency}
                    )
                    childTween:Play()
                end
                
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    local textTween = TweenService:Create(
                        child,
                        TweenInfo.new(
                            DialogSystem.config.animations.fadeIn.duration,
                            DialogSystem.config.animations.fadeIn.easing,
                            DialogSystem.config.animations.fadeIn.direction
                        ),
                        {TextTransparency = 0}
                    )
                    textTween:Play()
                end
                
                if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                    local imageTween = TweenService:Create(
                        child,
                        TweenInfo.new(
                            DialogSystem.config.animations.fadeIn.duration,
                            DialogSystem.config.animations.fadeIn.easing,
                            DialogSystem.config.animations.fadeIn.direction
                        ),
                        {ImageTransparency = 0}
                    )
                    imageTween:Play()
                end
            end
        end
    end
    
    return true
end

--[[
    Animate dialog exit
    @param modal - Modal container
    @param dialogCard - Dialog card component
    @param options - Dialog options
    @param onComplete - Function to call when animation completes
    @return - Success status
]]
function DialogSystem._animateExit(modal, dialogCard, options, onComplete)
    local animationType = options.animationType or "fade"
    
    -- Animate modal background
    local backgroundTween = TweenService:Create(
        modal,
        TweenInfo.new(
            DialogSystem.config.animations.fadeOut.duration,
            DialogSystem.config.animations.fadeOut.easing,
            DialogSystem.config.animations.fadeOut.direction
        ),
        {BackgroundTransparency = 1}
    )
    backgroundTween:Play()
    
    -- Get dialog instance
    local dialogInstance = dialogCard:getInstance()
    
    -- Different exit animations
    local animTween
    if animationType == "scale" then
        -- Scale out
        animTween = TweenService:Create(
            dialogInstance,
            TweenInfo.new(
                DialogSystem.config.animations.scaleOut.duration,
                DialogSystem.config.animations.scaleOut.easing,
                DialogSystem.config.animations.scaleOut.direction
            ),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
    elseif animationType == "fade" then
        -- Fade out
        animTween = TweenService:Create(
            dialogInstance,
            TweenInfo.new(
                DialogSystem.config.animations.fadeOut.duration,
                DialogSystem.config.animations.fadeOut.easing,
                DialogSystem.config.animations.fadeOut.direction
            ),
            {BackgroundTransparency = 1}
        )
        
        -- Fade out all children
        local children = dialogInstance:GetDescendants()
        for _, child in ipairs(children) do
            if child:IsA("GuiObject") then
                if child.ClassName ~= "UICorner" and child.ClassName ~= "UIListLayout" then
                    local childTween = TweenService:Create(
                        child,
                        TweenInfo.new(
                            DialogSystem.config.animations.fadeOut.duration,
                            DialogSystem.config.animations.fadeOut.easing,
                            DialogSystem.config.animations.fadeOut.direction
                        ),
                        {BackgroundTransparency = 1}
                    )
                    childTween:Play()
                end
                
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    local textTween = TweenService:Create(
                        child,
                        TweenInfo.new(
                            DialogSystem.config.animations.fadeOut.duration,
                            DialogSystem.config.animations.fadeOut.easing,
                            DialogSystem.config.animations.fadeOut.direction
                        ),
                        {TextTransparency = 1}
                    )
                    textTween:Play()
                end
                
                if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                    local imageTween = TweenService:Create(
                        child,
                        TweenInfo.new(
                            DialogSystem.config.animations.fadeOut.duration,
                            DialogSystem.config.animations.fadeOut.easing,
                            DialogSystem.config.animations.fadeOut.direction
                        ),
                        {ImageTransparency = 1}
                    )
                    imageTween:Play()
                end
            end
        end
    end
    
    -- Handle completion
    if animTween then
        animTween:Play()
        task.delay(DialogSystem.config.animations.fadeOut.duration + 0.05, function()
            if onComplete then
                onComplete()
            end
        end)
    else
        if onComplete then
            onComplete()
        end
    end
    
    return true
end

-- Initialize the system
DialogSystem.initialize()

return DialogSystem
