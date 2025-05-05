--!strict
--[[
    UIComponentDemo.client.luau
    
    A client script that demonstrates the UI Component System.
    
    Created: May 4, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get local player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Import ModuleLoaderHelper
local ModuleLoaderHelper = nil
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
    else
        warn("[UIComponentDemo] Failed to load ModuleLoaderHelper, using direct requires")
    end
end

-- Load UI components
local function loadModule(name)
    if ModuleLoaderHelper then
        return ModuleLoaderHelper.loadModule(name)
    else
        local path = ReplicatedStorage:FindFirstChild("shared")
        for part in string.gmatch(name, "[^/]+") do
            if path then
                path = path:FindFirstChild(part)
            end
        end
        
        if path then
            return require(path)
        end
    end
    
    return nil
end

-- Load required modules
local UIComponentBase = loadModule("UI/UIComponentBase")
local UIComponentRegistry = loadModule("UI/UIComponentRegistry")
local UIStyleSystem = loadModule("UI/UIStyleSystem")
local ButtonComponent = loadModule("UI/Components/ButtonComponent")
local TextComponent = loadModule("UI/Components/TextComponent")
local ContainerComponent = loadModule("UI/Components/ContainerComponent")
local CardComponent = loadModule("UI/Components/CardComponent")
local TabViewComponent = loadModule("UI/Components/TabViewComponent")
local FormComponent = loadModule("UI/Components/FormComponent")
local DialogSystem = loadModule("UI/DialogSystem")

-- Forward declare functions needed by TabView
local createButtonsDemo
local createCardsDemo
local createFormsDemo
local createDialogsDemo

-- Check if all modules are loaded
if not (UIComponentBase and ButtonComponent and TextComponent and ContainerComponent 
        and CardComponent and TabViewComponent and FormComponent and DialogSystem) then
    error("[UIComponentDemo] Failed to load required modules")
end

-- Initialize the UI system
local function init()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UIComponentDemo"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- Set DialogSystem default parent
    DialogSystem.config.defaultParent = screenGui
    
    -- Create main container
    local mainContainer = ContainerComponent.new({
        name = "MainContainer",
        size = UDim2.new(0.8, 0, 0.8, 0),
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchorPoint = Vector2.new(0.5, 0.5),
        backgroundColor = Color3.fromRGB(40, 40, 60),
        cornerRadius = 8,
        padding = 16
    })
    
    mainContainer:mount(screenGui)
    
    -- Create heading
    local heading = TextComponent.new({
        text = "UI Component System Demo",
        textStyle = "heading1",
        size = UDim2.new(1, 0, 0, 50),
        position = UDim2.new(0, 0, 0, 0),
        textColor = Color3.fromRGB(255, 255, 255)
    })
    
    heading:mount(mainContainer:getInstance())
      -- Create TabView to demonstrate different components
    local tabView = TabViewComponent.new({
        size = UDim2.new(1, 0, 1, -60),
        position = UDim2.new(0, 0, 0, 60),
        tabPosition = "top",
        tabSize = UDim2.new(0, 150, 0, 40),
        tabs = {
            {
                id = "buttons",
                title = "Buttons",
                content = function() return createButtonsDemo() end
            },
            {
                id = "cards",
                title = "Cards",
                content = function() return createCardsDemo() end
            },
            {
                id = "forms",
                title = "Forms",
                content = function() return createFormsDemo() end
            },
            {
                id = "dialogs",
                title = "Dialogs",
                content = function() return createDialogsDemo() end
            }
        }
    })
    
    tabView:mount(mainContainer:getInstance())
end

-- Create buttons demo
createButtonsDemo = function()
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    
    -- Create title
    local title = TextComponent.new({
        text = "Button Component Examples",
        textStyle = "heading2",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 0)
    })
    
    title:mount(container)
    
    -- Create button container
    local buttonContainer = ContainerComponent.new({
        size = UDim2.new(1, 0, 1, -50),
        position = UDim2.new(0, 0, 0, 50),
        padding = 16,
        layoutType = "vertical",
        layoutConfig = {
            padding = 16,
            alignment = "start"
        }
    })
    
    buttonContainer:mount(container)
    
    -- Create standard button
    local standardButton = ButtonComponent.new({
        text = "Standard Button",
        size = UDim2.new(0, 200, 0, 50),
        backgroundColor = Color3.fromRGB(0, 120, 215)
    })
    
    standardButton:onClick(function()
        print("Standard button clicked")
        
        -- Show success message
        DialogSystem.alert("Button Clicked", "You clicked the standard button!", nil, {
            confirmText = "Got it"
        })
    end)
    
    standardButton:mount(buttonContainer:getInstance())
    
    -- Create large button
    local largeButton = ButtonComponent.new({
        text = "Large Button with Icon",
        size = UDim2.new(0, 250, 0, 60),
        backgroundColor = Color3.fromRGB(0, 170, 85),
        icon = "rbxassetid://6031068433", -- Example icon
        cornerRadius = 8
    })
    
    largeButton:onClick(function()
        print("Large button clicked")
    })
    
    largeButton:mount(buttonContainer:getInstance())
    
    -- Create small button
    local smallButton = ButtonComponent.new({
        text = "Small",
        size = UDim2.new(0, 100, 0, 30),
        backgroundColor = Color3.fromRGB(200, 50, 50),
        cornerRadius = 15 -- Fully rounded
    })
    
    smallButton:mount(buttonContainer:getInstance())
    
    -- Create disabled button
    local disabledButton = ButtonComponent.new({
        text = "Disabled Button",
        size = UDim2.new(0, 200, 0, 50),
        backgroundColor = Color3.fromRGB(100, 100, 120),
        enabled = false
    })
    
    disabledButton:mount(buttonContainer:getInstance())
    
    -- Create row of buttons
    local buttonRow = ContainerComponent.new({
        size = UDim2.new(1, 0, 0, 50),
        layoutType = "horizontal",
        layoutConfig = {
            padding = 16,
            alignment = "center"
        }
    })
    
    buttonRow:mount(buttonContainer:getInstance())
    
    -- Add buttons to row
    for i = 1, 3 do
        local button = ButtonComponent.new({
            text = "Button " .. i,
            size = UDim2.new(0, 120, 0, 40),
            backgroundColor = Color3.fromRGB(80, 80, 180)
        })
        
        button:mount(buttonRow:getInstance())
    end
      return container
end

-- Create cards demo
createCardsDemo = function()
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    
    -- Create title
    local title = TextComponent.new({
        text = "Card Component Examples",
        textStyle = "heading2",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 0)
    })
    
    title:mount(container)
    
    -- Create card container
    local cardContainer = ContainerComponent.new({
        size = UDim2.new(1, 0, 1, -50),
        position = UDim2.new(0, 0, 0, 50),
        padding = 16,
        layoutType = "grid",
        layoutConfig = {
            cellSize = UDim2.new(0.45, 0, 0.45, 0),
            cellPadding = UDim2.new(0, 20, 0, 20),
            fillDirection = Enum.FillDirection.Horizontal,
            alignment = "center"
        }
    })
    
    cardContainer:mount(container)
    
    -- Create basic card
    local basicCard = CardComponent.new({
        title = "Basic Card",
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = Color3.fromRGB(50, 50, 70),
        cornerRadius = 8,
        padding = 16,
        elevation = "medium"
    })
    
    -- Add content to card
    local cardContent = TextComponent.new({
        text = "This is a basic card with a title and some content. Cards can be used to group related information and controls.",
        textStyle = "body",
        size = UDim2.new(1, 0, 0, 0),
        autoSize = "height",
        wrap = true
    })
    
    cardContent:mount(basicCard:getInstance():WaitForChild("Content"))
    basicCard:mount(cardContainer:getInstance())
    
    -- Create card with footer
    local footerCard = CardComponent.new({
        title = "Card with Footer",
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = Color3.fromRGB(50, 50, 70),
        cornerRadius = 8,
        padding = 16,
        elevation = "medium",
        footerContent = "Last updated: May 4, 2025"
    })
    
    -- Add content to card
    local footerCardContent = TextComponent.new({
        text = "This card has a footer section for additional information or actions. Footers can contain text or UI components.",
        textStyle = "body",
        size = UDim2.new(1, 0, 0, 0),
        autoSize = "height",
        wrap = true
    })
    
    footerCardContent:mount(footerCard:getInstance():WaitForChild("Content"))
    footerCard:mount(cardContainer:getInstance())
    
    -- Create card with buttons
    local buttonCard = CardComponent.new({
        title = "Interactive Card",
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = Color3.fromRGB(50, 50, 70),
        cornerRadius = 8,
        padding = 16,
        elevation = "high"
    })
    
    -- Add content to card
    local buttonCardContent = TextComponent.new({
        text = "Cards can contain interactive elements like buttons. Click the buttons below to perform actions.",
        textStyle = "body",
        size = UDim2.new(1, 0, 0, 0),
        autoSize = "height",
        wrap = true
    })
    
    buttonCardContent:mount(buttonCard:getInstance():WaitForChild("Content"))
    
    -- Add button container
    local cardButtonContainer = ContainerComponent.new({
        size = UDim2.new(1, 0, 0, 50),
        position = UDim2.new(0, 0, 0, buttonCardContent:getInstance().AbsoluteSize.Y + 16),
        layoutType = "horizontal",
        layoutConfig = {
            padding = 8,
            alignment = "center"
        }
    })
    
    cardButtonContainer:mount(buttonCard:getInstance():WaitForChild("Content"))
    
    -- Add buttons
    local acceptButton = ButtonComponent.new({
        text = "Accept",
        size = UDim2.new(0, 100, 0, 40),
        backgroundColor = Color3.fromRGB(0, 170, 85)
    })
    
    acceptButton:onClick(function()
        print("Accept clicked")
    end)
    
    local declineButton = ButtonComponent.new({
        text = "Decline",
        size = UDim2.new(0, 100, 0, 40),
        backgroundColor = Color3.fromRGB(200, 50, 50)
    })
    
    acceptButton:mount(cardButtonContainer:getInstance())
    declineButton:mount(cardButtonContainer:getInstance())
    buttonCard:mount(cardContainer:getInstance())
    
    -- Create clickable card
    local clickableCard = CardComponent.new({
        title = "Clickable Card",
        size = UDim2.new(1, 0, 1, 0),
        backgroundColor = Color3.fromRGB(50, 50, 70),
        cornerRadius = 8,
        padding = 16,
        elevation = "medium",
        clickable = true
    })
    
    -- Add content to card
    local clickableCardContent = TextComponent.new({
        text = "This entire card is clickable. Try clicking anywhere on the card!",
        textStyle = "body",
        size = UDim2.new(1, 0, 0, 0),
        autoSize = "height",
        wrap = true
    })
    
    clickableCardContent:mount(clickableCard:getInstance():WaitForChild("Content"))
    
    -- Handle card click
    clickableCard:onClick(function()
        print("Clickable card clicked")
        
        -- Show dialog
        DialogSystem.alert("Card Clicked", "You clicked on the clickable card!")
    end)
    
    clickableCard:mount(cardContainer:getInstance())
      return container
end

-- Create forms demo
createFormsDemo = function()
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    
    -- Create title
    local title = TextComponent.new({
        text = "Form Component Examples",
        textStyle = "heading2",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 0)
    })
    
    title:mount(container)
    
    -- Create form container
    local formContainer = ContainerComponent.new({
        size = UDim2.new(0.6, 0, 1, -50),
        position = UDim2.new(0.2, 0, 0, 50),
        padding = 16,
        backgroundColor = Color3.fromRGB(50, 50, 70),
        cornerRadius = 8
    })
    
    formContainer:mount(container)
    
    -- Create form subtitle
    local subtitle = TextComponent.new({
        text = "Registration Form",
        textStyle = "heading3",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0, 0)
    })
    
    subtitle:mount(formContainer:getInstance())
    
    -- Create registration form
    local registrationForm = FormComponent.new({
        size = UDim2.new(1, 0, 1, -40),
        position = UDim2.new(0, 0, 0, 40),
        labelPosition = "top",
        submitButtonText = "Register",
        fields = {
            {
                name = "username",
                label = "Username",
                type = "text",
                placeholder = "Enter username",
                defaultValue = "",
                validators = {
                    FormComponent.Validation.required,
                    FormComponent.Validation.minLength(3),
                    FormComponent.Validation.maxLength(20)
                }
            },
            {
                name = "email",
                label = "Email Address",
                type = "email",
                placeholder = "Enter email address",
                defaultValue = "",
                validators = {
                    FormComponent.Validation.required,
                    FormComponent.Validation.email
                }
            },
            {
                name = "password",
                label = "Password",
                type = "password",
                placeholder = "Enter password",
                defaultValue = "",
                validators = {
                    FormComponent.Validation.required,
                    FormComponent.Validation.minLength(8),
                    FormComponent.Validation.pattern(".*[%d].*", "Must contain at least one number")
                }
            },
            {
                name = "age",
                label = "Age",
                type = "number",
                placeholder = "Enter your age",
                defaultValue = "",
                validators = {
                    FormComponent.Validation.required,
                    FormComponent.Validation.number,
                    FormComponent.Validation.min(13),
                    FormComponent.Validation.max(120)
                }
            },
            {
                name = "category",
                label = "Player Category",
                type = "select",
                options = {
                    { label = "Beginner", value = "beginner" },
                    { label = "Intermediate", value = "intermediate" },
                    { label = "Advanced", value = "advanced" },
                    { label = "Expert", value = "expert" }
                },
                defaultValue = "beginner",
                validators = {
                    FormComponent.Validation.required
                }
            },
            {
                name = "bio",
                label = "About Yourself",
                type = "textarea",
                placeholder = "Tell us a bit about yourself...",
                defaultValue = "",
                validators = {
                    FormComponent.Validation.maxLength(200)
                }
            },
            {
                name = "notifications",
                label = "Notification Preferences",
                type = "checkbox",
                checkboxLabel = "Receive email notifications",
                defaultValue = true
            },
            {
                name = "terms",
                label = "Terms and Conditions",
                type = "checkbox",
                checkboxLabel = "I agree to the terms and conditions",
                defaultValue = false,
                validators = {
                    FormComponent.Validation.custom(function(value)
                        return value == true
                    end, "You must agree to the terms and conditions")
                }
            }
        }
    })
    
    -- Handle form submission
    registrationForm:onSubmit(function(formData)
        print("Form submitted:", formData)
        
        -- Show success dialog
        DialogSystem.alert("Registration Successful", 
            "Thank you for registering, " .. formData.username .. "!\nWe've sent a confirmation email to " .. formData.email,
            function()
                -- Reset form after successful submission
                registrationForm:reset()
            end
        )
    end)
    
    -- Handle validation error
    registrationForm:onValidationError(function(errors)
        print("Validation errors:", errors)
        
        -- Show error dialog
        local errorMessages = "Please fix the following errors:\n"
        local count = 0
        
        for _, errorMsg in pairs(errors) do
            count += 1
            errorMessages ..= "• " .. errorMsg .. "\n"
            
            -- Limit to first 3 errors for readability
            if count >= 3 then
                errorMessages ..= "• ...and other fields have errors"
                break
            end
        end
        
        DialogSystem.alert("Validation Error", errorMessages, nil, {
            confirmText = "OK",
            backgroundColor = Color3.fromRGB(180, 50, 50),
            width = 450
        })
    end)
    
    registrationForm:mount(formContainer:getInstance())
      return container
end

-- Create dialogs demo
createDialogsDemo = function()
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    
    -- Create title
    local title = TextComponent.new({
        text = "Dialog System Examples",
        textStyle = "heading2",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 0)
    })
    
    title:mount(container)
    
    -- Create button container
    local buttonContainer = ContainerComponent.new({
        size = UDim2.new(0.8, 0, 1, -50),
        position = UDim2.new(0.1, 0, 0, 50),
        padding = 16,
        layoutType = "vertical",
        layoutConfig = {
            padding = 24,
            alignment = "start"
        }
    })
    
    buttonContainer:mount(container)
    
    -- Create section for alert dialogs
    local alertSection = CardComponent.new({
        title = "Alert Dialogs",
        size = UDim2.new(1, 0, 0, 150),
        padding = 16
    })
    
    -- Create button to show alert dialog
    local alertButton = ButtonComponent.new({
        text = "Show Alert Dialog",
        size = UDim2.new(0, 200, 0, 50),
        backgroundColor = Color3.fromRGB(0, 120, 215)
    })
    
    alertButton:onClick(function()
        DialogSystem.alert(
            "Information", 
            "This is a simple alert dialog with an OK button.",
            function()
                print("Alert dialog closed")
            end
        )
    end)
    
    alertButton:mount(alertSection:getInstance():WaitForChild("Content"))
    alertSection:mount(buttonContainer:getInstance())
    
    -- Create section for confirmation dialogs
    local confirmSection = CardComponent.new({
        title = "Confirmation Dialogs",
        size = UDim2.new(1, 0, 0, 150),
        padding = 16
    })
    
    -- Create button to show confirmation dialog
    local confirmButton = ButtonComponent.new({
        text = "Show Confirmation Dialog",
        size = UDim2.new(0, 200, 0, 50),
        backgroundColor = Color3.fromRGB(0, 170, 85)
    })
    
    confirmButton:onClick(function()
        DialogSystem.confirm(
            "Confirm Action", 
            "Are you sure you want to proceed with this action?",
            function()
                print("Action confirmed")
                DialogSystem.alert("Success", "Action completed successfully!")
            end,
            function()
                print("Action cancelled")
            end
        )
    end)
    
    confirmButton:mount(confirmSection:getInstance():WaitForChild("Content"))
    confirmSection:mount(buttonContainer:getInstance())
    
    -- Create section for prompt dialogs
    local promptSection = CardComponent.new({
        title = "Prompt Dialogs",
        size = UDim2.new(1, 0, 0, 150),
        padding = 16
    })
    
    -- Create button to show prompt dialog
    local promptButton = ButtonComponent.new({
        text = "Show Prompt Dialog",
        size = UDim2.new(0, 200, 0, 50),
        backgroundColor = Color3.fromRGB(200, 100, 0)
    })
    
    promptButton:onClick(function()
        DialogSystem.prompt(
            "Enter Name", 
            "Please enter your in-game name:",
            function(value)
                print("Prompt value:", value)
                DialogSystem.alert("Welcome", "Hello, " .. value .. "!")
            end,
            {
                defaultValue = "Player",
                placeholderText = "Enter name here..."
            }
        )
    end)
    
    promptButton:mount(promptSection:getInstance():WaitForChild("Content"))
    promptSection:mount(buttonContainer:getInstance())
    
    -- Create section for custom dialogs
    local customSection = CardComponent.new({
        title = "Custom Dialogs",
        size = UDim2.new(1, 0, 0, 150),
        padding = 16
    })
    
    -- Create button to show custom dialog
    local customButton = ButtonComponent.new({
        text = "Show Custom Dialog",
        size = UDim2.new(0, 200, 0, 50),
        backgroundColor = Color3.fromRGB(150, 50, 200)
    })
    
    customButton:onClick(function()
        DialogSystem.createModal({
            title = "Custom Dialog",
            width = 500,
            backgroundColor = Color3.fromRGB(60, 60, 90),
            closeOnBackgroundClick = true,
            animationType = "scale",
            customContent = function(contentFrame)
                -- Add image
                local image = Instance.new("ImageLabel")
                image.Size = UDim2.new(1, 0, 0, 150)
                image.Position = UDim2.new(0, 0, 0, 0)
                image.BackgroundTransparency = 1
                image.Image = "rbxassetid://6031233233" -- Example image
                image.ScaleType = Enum.ScaleType.Crop
                
                -- Add text
                local text = Instance.new("TextLabel")
                text.Size = UDim2.new(1, 0, 0, 60)
                text.Position = UDim2.new(0, 0, 0, 160)
                text.BackgroundTransparency = 1
                text.Text = "This is a custom dialog with an image and text. You can add any UI elements here."
                text.TextColor3 = Color3.fromRGB(255, 255, 255)
                text.Font = Enum.Font.Gotham
                text.TextSize = 16
                text.TextWrapped = true
                
                image.Parent = contentFrame
                text.Parent = contentFrame
            end,
            buttons = {
                {
                    text = "Great!",
                    style = "primary",
                    width = 120,
                    onClick = function(closeDialog)
                        print("Custom dialog closed")
                        closeDialog()
                    end
                },
                {
                    text = "Cancel",
                    style = "secondary",
                    width = 120,
                    onClick = function(closeDialog)
                        closeDialog()
                    end
                }
            }
        })
    end)
      customButton:mount(customSection:getInstance():WaitForChild("Content"))
    customSection:mount(buttonContainer:getInstance())
    
    return container
end

-- Initialize when player is ready
if player.Character or player.CharacterAdded:Wait() then
    init()
    print("UI Component Demo initialized")
end
