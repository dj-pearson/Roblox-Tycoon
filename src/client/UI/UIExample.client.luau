--[[
    UIExample.client.luau
    
    A practical example demonstrating the usage of our UI system components together.
    Shows how to register, create and manage various UI elements following the UI_Module_Design pattern.
    
    Author: Updated April 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

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
local DialogFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("DialogFactory"))
local MenuContainer = requireSafely(sharedFolder and sharedFolder:FindFirstChild("MenuContainer"))

-- Find client modules
local clientFolder = script.Parent.Parent
local UIRegistry = requireSafely(clientFolder and clientFolder:FindFirstChild("UI") and clientFolder.UI:FindFirstChild("UIRegistry"))

-- Fallbacks and validations
if not UIStyle then
    warn("UIStyle module not found, UIExample will not run correctly")
    return
end

if not IconSet then
    warn("IconSet module not found, UIExample will not run correctly")
    return
end

if not ButtonFactory then
    warn("ButtonFactory module not found, UIExample will not run correctly")
    return
end

if not DialogFactory then
    warn("DialogFactory module not found, UIExample will not run correctly")
    return
end

if not MenuContainer then
    warn("MenuContainer module not found, UIExample will not run correctly")
    return
end

if not UIRegistry then
    warn("UIRegistry module not found, UIExample will not run correctly")
    return
end

-- Enable debug mode for UIRegistry
UIRegistry:setDebugMode(true)

-- Player dependencies
local player = Players.LocalPlayer
if not player then
    warn("LocalPlayer not found, UIExample will not run correctly")
    return
end

local playerGui = player:WaitForChild("PlayerGui")

-- Helper function to create a test icon
local function createIconButton(label, iconName, parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 80, 0, 100)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local button = ButtonFactory.createButton("", UDim2.new(1, 0, 0, 80), UDim2.new(0, 0, 0, 0))
    IconSet.addIconToButton(button, iconName, UDim2.new(0, 40, 0, 40))
    button.Parent = frame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0, 20)
    textLabel.Position = UDim2.new(0, 0, 0, 80)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = UIStyle.Fonts.Regular
    textLabel.TextSize = UIStyle.TextSizes.Medium
    textLabel.Text = label
    textLabel.TextColor3 = UIStyle.Colors.Text
    textLabel.Parent = frame
    
    return button, frame
end

-- Example Module
local UIExample = {}

-- Create example UIs
function UIExample:createExampleUIs()
    -- 1. Create the main menu
    self:createMainMenu()
    
    -- 2. Create an example dialog
    self:createExampleDialog()
    
    -- 3. Create a tabbed settings menu
    self:createSettingsMenu()
    
    -- 4. Create an example notification button
    self:createNotificationButton()
    
    -- Register these with the UI Registry for management
    self:registerUIs()
    
    return self
end

-- Create the main menu
function UIExample:createMainMenu()
    -- Create a screen gui for the main menu
    local mainMenuGui = Instance.new("ScreenGui")
    mainMenuGui.Name = "MainMenuGui"
    mainMenuGui.ResetOnSpawn = false
    mainMenuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainMenuGui.Parent = playerGui
    
    -- Create a standard container for the main menu
    local menuContainer = MenuContainer.createStandardContainer(
        "MainMenu",
        "Gym Tycoon",
        UDim2.new(0, 300, 0, 400),
        UDim2.new(0.5, 0, 0.5, 0),
        mainMenuGui,
        true -- Include close button
    )
    
    -- Add a header image (gym logo)
    local headerImage = Instance.new("ImageLabel")
    headerImage.Size = UDim2.new(1, -40, 0, 100)
    headerImage.Position = UDim2.new(0, 20, 0, 20)
    headerImage.BackgroundColor3 = UIStyle.Colors.BackgroundLight
    headerImage.BackgroundTransparency = 0.5
    headerImage.Image = "" -- Add your logo image ID here
    headerImage.ScaleType = Enum.ScaleType.Fit
    headerImage.Parent = menuContainer.contentArea
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = headerImage
    
    -- Add main menu buttons
    local buttonsContainer = Instance.new("Frame")
    buttonsContainer.Size = UDim2.new(1, -40, 0, 200)
    buttonsContainer.Position = UDim2.new(0, 20, 0, 140)
    buttonsContainer.BackgroundTransparency = 1
    buttonsContainer.Parent = menuContainer.contentArea
    
    -- Create Play button
    local playButton = ButtonFactory.createFeatureButton("Play", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), function()
        -- Hide main menu and show game UI
        UIRegistry:closeUI("MainMenu")
        UIRegistry:showNotification("Starting game...", "info", 2)
        
        -- Example: Show a confirmation before starting
        DialogFactory.createConfirmDialog(
            "Start Game",
            "Are you sure you want to start a new game?",
            function()
                UIRegistry:showNotification("Game started!", "success")
                -- Additional game start logic would go here
            end,
            function()
                UIRegistry:showNotification("Game start cancelled", "info")
            end
        )
    end)
    playButton.Parent = buttonsContainer
    
    -- Create Settings button
    local settingsButton = ButtonFactory.createFeatureButton("Settings", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 60), function()
        -- Show the settings menu
        UIRegistry:showUI("SettingsMenu")
    end)
    settingsButton.Parent = buttonsContainer
    
    -- Create Alliance button
    local allianceButton = ButtonFactory.createFeatureButton("Alliance", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 120), function()
        DialogFactory.createMessageDialog(
            "Alliance Feature",
            "Alliance feature will be available in the next update!",
            function()
                UIRegistry:showNotification("Stay tuned for alliances!", "info")
            end
        )
    end)
    allianceButton.Parent = buttonsContainer
    
    -- Store reference to the main menu
    self.mainMenuGui = mainMenuGui
end

-- Create an example dialog
function UIExample:createExampleDialog() 
    -- Create a screen gui for the dialog
    local dialogGui = Instance.new("ScreenGui")
    dialogGui.Name = "ExampleDialogGui"
    dialogGui.ResetOnSpawn = false
    dialogGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    dialogGui.Enabled = false -- Start disabled
    dialogGui.Parent = playerGui
    
    -- Create a dialog using a custom dialog
    local customDialog = DialogFactory.createCustomDialog(
        "Example Feature",
        function(contentArea)
            -- Create content for the dialog
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 0, 60)
            textLabel.Position = UDim2.new(0, 0, 0, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Font = UIStyle.Fonts.Regular
            textLabel.TextSize = UIStyle.TextSizes.Medium
            textLabel.Text = "This is an example of a custom dialog with content and buttons."
            textLabel.TextWrapped = true
            textLabel.TextColor3 = UIStyle.Colors.Text
            textLabel.Parent = contentArea
            
            -- Add an example input field
            local inputLabel = Instance.new("TextLabel")
            inputLabel.Size = UDim2.new(1, 0, 0, 20)
            inputLabel.Position = UDim2.new(0, 0, 0, 70)
            inputLabel.BackgroundTransparency = 1
            inputLabel.Font = UIStyle.Fonts.SemiBold
            inputLabel.TextSize = UIStyle.TextSizes.Medium
            inputLabel.Text = "Enter your gym name:"
            inputLabel.TextXAlignment = Enum.TextXAlignment.Left
            inputLabel.TextColor3 = UIStyle.Colors.Text
            inputLabel.Parent = contentArea
            
            local inputBox = Instance.new("TextBox")
            inputBox.Size = UDim2.new(1, 0, 0, 40)
            inputBox.Position = UDim2.new(0, 0, 0, 95)
            inputBox.BackgroundColor3 = UIStyle.Colors.BackgroundLight
            inputBox.Font = UIStyle.Fonts.Regular
            inputBox.TextSize = UIStyle.TextSizes.Medium
            inputBox.TextColor3 = UIStyle.Colors.Text
            inputBox.PlaceholderText = "Enter name here..."
            inputBox.ClearTextOnFocus = false
            inputBox.Parent = contentArea
            
            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 6)
            inputCorner.Parent = inputBox
        end,
        {
            {
                text = "Cancel",
                style = "cancel",
                callback = function()
                    UIRegistry:showNotification("Operation cancelled", "info")
                end
            },
            {
                text = "Submit",
                style = "confirm",
                callback = function()
                    UIRegistry:showNotification("Form submitted successfully!", "success")
                end
            }
        },
        UDim2.new(0, 400, 0, 280) -- Custom size
    )
    
    -- Store reference to the dialog
    self.exampleDialogGui = dialogGui
    dialogGui.DialogFrame = customDialog.dialogFrame
    dialogGui.DialogFrame.Parent = dialogGui
end

-- Create settings menu with tabs
function UIExample:createSettingsMenu()
    -- Create a screen gui for settings
    local settingsGui = Instance.new("ScreenGui")
    settingsGui.Name = "SettingsMenuGui"
    settingsGui.ResetOnSpawn = false
    settingsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    settingsGui.Enabled = false -- Start disabled
    settingsGui.Parent = playerGui
    
    -- Define tabs configuration
    local tabs = {
        {
            name = "General",
            label = "General",
            createContent = function(container)
                -- Create general settings content
                local scrollingContainer = MenuContainer.createScrollingContainer("GeneralSettings", container)
                
                -- Create settings cards
                local musicCard = scrollingContainer.createCard(80)
                local soundCard = scrollingContainer.createCard(80)
                local qualityCard = scrollingContainer.createCard(80)
                
                -- Music settings
                local musicLabel = Instance.new("TextLabel")
                musicLabel.Size = UDim2.new(0, 150, 0, 30)
                musicLabel.Position = UDim2.new(0, 15, 0.5, -15)
                musicLabel.BackgroundTransparency = 1
                musicLabel.Font = UIStyle.Fonts.SemiBold
                musicLabel.TextSize = UIStyle.TextSizes.Medium
                musicLabel.Text = "Music"
                musicLabel.TextXAlignment = Enum.TextXAlignment.Left
                musicLabel.TextColor3 = UIStyle.Colors.Text
                musicLabel.Parent = musicCard
                
                local musicToggle = ButtonFactory.createToggleButton("Music", true, UDim2.new(0, 60, 0, 30), UDim2.new(1, -75, 0.5, -15), function(isOn)
                    UIRegistry:showNotification("Music " .. (isOn and "enabled" or "disabled"), "info")
                end) -- Fixed closing parenthesis and ternary operator
                musicToggle.instance.Parent = musicCard
                
                -- Sound settings
                local soundLabel = Instance.new("TextLabel")
                soundLabel.Size = UDim2.new(0, 150, 0, 30)
                soundLabel.Position = UDim2.new(0, 15, 0.5, -15)
                soundLabel.BackgroundTransparency = 1
                soundLabel.Font = UIStyle.Fonts.SemiBold
                soundLabel.TextSize = UIStyle.TextSizes.Medium
                soundLabel.Text = "Sound Effects"
                soundLabel.TextXAlignment = Enum.TextXAlignment.Left
                soundLabel.TextColor3 = UIStyle.Colors.Text
                soundLabel.Parent = soundCard
                
                local soundToggle = ButtonFactory.createToggleButton("Sound", true, UDim2.new(0, 60, 0, 30), UDim2.new(1, -75, 0.5, -15), function(isOn)
                    UIRegistry:showNotification("Sound effects " .. (isOn and "enabled" or "disabled"), "info")
                end) -- Fixed closing parenthesis and ternary operator
                soundToggle.instance.Parent = soundCard
                
                -- Quality settings
                local qualityLabel = Instance.new("TextLabel")
                qualityLabel.Size = UDim2.new(0, 150, 0, 30)
                qualityLabel.Position = UDim2.new(0, 15, 0.5, -15)
                qualityLabel.BackgroundTransparency = 1
                qualityLabel.Font = UIStyle.Fonts.SemiBold
                qualityLabel.TextSize = UIStyle.TextSizes.Medium
                qualityLabel.Text = "Graphics Quality"
                qualityLabel.TextXAlignment = Enum.TextXAlignment.Left
                qualityLabel.TextColor3 = UIStyle.Colors.Text
                qualityLabel.Parent = qualityCard
                
                local qualityButton = ButtonFactory.createButton("Medium", UDim2.new(0, 100, 0, 30), UDim2.new(1, -115, 0.5, -15), function()
                    DialogFactory.createConfirmDialog(
                        "Change Graphics Quality",
                        "Are you sure you want to change the graphics quality? This may affect performance.",
                        function()
                            UIRegistry:showNotification("Graphics quality updated", "success")
                        end
                    )
                end)
                qualityButton.Parent = qualityCard
            end
        },
        {
            name = "Controls",
            label = "Controls",
            createContent = function(container)
                -- Create controls settings content
                local controlsLabel = Instance.new("TextLabel")
                controlsLabel.Size = UDim2.new(1, -40, 0, 40)
                controlsLabel.Position = UDim2.new(0, 20, 0, 20)
                controlsLabel.BackgroundTransparency = 1
                controlsLabel.Font = UIStyle.Fonts.SemiBold
                controlsLabel.TextSize = UIStyle.TextSizes.Medium
                controlsLabel.Text = "Control Settings"
                controlsLabel.TextXAlignment = Enum.TextXAlignment.Left
                controlsLabel.TextColor3 = UIStyle.Colors.Text
                controlsLabel.Parent = container
                
                -- Create a split container for controls
                local splitContainer = MenuContainer.createSplitContainer(
                    "Controls",
                    container,
                    UDim2.new(1, -40, 1, -80),
                    UDim2.new(0, 20, 0, 70)
                )
                
                -- Create left panel content (keys list)
                local keysList = Instance.new("ScrollingFrame")
                keysList.Size = UDim2.new(1, 0, 1, 0)
                keysList.Position = UDim2.new(0, 0, 0, 0)
                keysList.BackgroundTransparency = 1
                keysList.BorderSizePixel = 0
                keysList.ScrollBarThickness = 6
                keysList.ScrollingDirection = Enum.ScrollingDirection.Y
                keysList.CanvasSize = UDim2.new(0, 0, 0, 200)
                keysList.Parent = splitContainer.firstPanel
                
                local keysLayout = Instance.new("UIListLayout")
                keysLayout.Padding = UDim.new(0, 5)
                keysLayout.SortOrder = Enum.SortOrder.LayoutOrder
                keysLayout.Parent = keysList
                
                -- Example key bindings
                local keyBindings = {
                    { name = "Move Forward", key = "W" },
                    { name = "Move Backward", key = "S" },
                    { name = "Move Left", key = "A" },
                    { name = "Move Right", key = "D" },
                    { name = "Jump", key = "Space" },
                    { name = "Interact", key = "E" }
                }
                
                -- Create key binding entries
                for i, binding in ipairs(keyBindings) do
                    local bindingFrame = Instance.new("Frame")
                    bindingFrame.Size = UDim2.new(1, 0, 0, 30)
                    bindingFrame.BackgroundColor3 = i % 2 == 0 and UIStyle.Colors.BackgroundLight or UIStyle.Colors.Background
                    bindingFrame.BackgroundTransparency = 0.5
                    bindingFrame.LayoutOrder = i
                    bindingFrame.Parent = keysList
                    
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(1, -60, 1, 0)
                    nameLabel.Position = UDim2.new(0, 10, 0, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Font = UIStyle.Fonts.Regular
                    nameLabel.TextSize = UIStyle.TextSizes.Medium
                    nameLabel.Text = binding.name
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.TextColor3 = UIStyle.Colors.Text
                    nameLabel.Parent = bindingFrame
                    
                    local keyLabel = Instance.new("TextLabel")
                    keyLabel.Size = UDim2.new(0, 40, 0, 20)
                    keyLabel.Position = UDim2.new(1, -50, 0.5, -10)
                    keyLabel.BackgroundColor3 = UIStyle.Colors.ButtonDefault
                    keyLabel.Font = UIStyle.Fonts.Bold
                    keyLabel.TextSize = UIStyle.TextSizes.Medium
                    keyLabel.Text = binding.key
                    keyLabel.TextColor3 = UIStyle.Colors.Text
                    keyLabel.Parent = bindingFrame
                    
                    local keyCorner = Instance.new("UICorner")
                    keyCorner.CornerRadius = UDim.new(0, 4)
                    keyCorner.Parent = keyLabel
                end
                
                -- Create right panel content (help text)
                local helpText = Instance.new("TextLabel")
                helpText.Size = UDim2.new(1, -20, 1, -20)
                helpText.Position = UDim2.new(0, 10, 0, 10)
                helpText.BackgroundTransparency = 1
                helpText.Font = UIStyle.Fonts.Regular
                helpText.TextSize = UIStyle.TextSizes.Medium
                helpText.Text = "Click on a key binding to change it. Press the new key to set the binding."
                helpText.TextWrapped = true
                helpText.TextXAlignment = Enum.TextXAlignment.Left
                helpText.TextYAlignment = Enum.TextYAlignment.Top
                helpText.TextColor3 = UIStyle.Colors.Text
                helpText.Parent = splitContainer.secondPanel
            end
        },
        {
            name = "About",
            label = "About",
            createContent = function(container)
                -- Create about content
                local scrollingContainer = MenuContainer.createScrollingContainer("AboutContent", container)
                
                local aboutFrame = Instance.new("Frame")
                aboutFrame.Size = UDim2.new(1, -10, 0, 300)
                aboutFrame.BackgroundTransparency = 1
                aboutFrame.Parent = scrollingContainer.scrollFrame
                
                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(1, 0, 0, 40)
                titleLabel.Position = UDim2.new(0, 0, 0, 0)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Font = UIStyle.Fonts.Bold
                titleLabel.TextSize = UIStyle.TextSizes.Title
                titleLabel.Text = "Gym Tycoon"
                titleLabel.TextColor3 = UIStyle.Colors.Text
                titleLabel.Parent = aboutFrame
                
                local versionLabel = Instance.new("TextLabel")
                versionLabel.Size = UDim2.new(1, 0, 0, 20)
                versionLabel.Position = UDim2.new(0, 0, 0, 50)
                versionLabel.BackgroundTransparency = 1
                versionLabel.Font = UIStyle.Fonts.SemiBold
                versionLabel.TextSize = UIStyle.TextSizes.Medium
                versionLabel.Text = "Version 1.0.0"
                versionLabel.TextColor3 = UIStyle.Colors.TextSecondary
                versionLabel.Parent = aboutFrame
                
                local descriptionLabel = Instance.new("TextLabel")
                descriptionLabel.Size = UDim2.new(1, 0, 0, 150)
                descriptionLabel.Position = UDim2.new(0, 0, 0, 80)
                descriptionLabel.BackgroundTransparency = 1
                descriptionLabel.Font = UIStyle.Fonts.Regular
                descriptionLabel.TextSize = UIStyle.TextSizes.Medium
                descriptionLabel.Text = "Gym Tycoon is a game where you build and manage your own gym. Attract members, hire staff, upgrade equipment, and become the most successful gym in town!"
                descriptionLabel.TextWrapped = true
                descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
                descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
                descriptionLabel.TextColor3 = UIStyle.Colors.Text
                descriptionLabel.Parent = aboutFrame
                
                local creditsLabel = Instance.new("TextLabel")
                creditsLabel.Size = UDim2.new(1, 0, 0, 30)
                creditsLabel.Position = UDim2.new(0, 0, 0, 240)
                creditsLabel.BackgroundTransparency = 1
                creditsLabel.Font = UIStyle.Fonts.SemiBold
                creditsLabel.TextSize = UIStyle.TextSizes.Medium
                creditsLabel.Text = "Credits"
                creditsLabel.TextXAlignment = Enum.TextXAlignment.Left
                creditsLabel.TextColor3 = UIStyle.Colors.Text
                creditsLabel.Parent = aboutFrame
                
                local developersLabel = Instance.new("TextLabel")
                developersLabel.Size = UDim2.new(1, 0, 0, 30)
                developersLabel.Position = UDim2.new(0, 0, 0, 270)
                developersLabel.BackgroundTransparency = 1
                developersLabel.Font = UIStyle.Fonts.Regular
                developersLabel.TextSize = UIStyle.TextSizes.Medium
                developersLabel.Text = "Developed by: Gym Tycoon Development Team"
                developersLabel.TextXAlignment = Enum.TextXAlignment.Left
                developersLabel.TextColor3 = UIStyle.Colors.TextSecondary
                developersLabel.Parent = aboutFrame
                
                -- Add a reset button
                local resetButton = ButtonFactory.createButton("Reset Game Data", UDim2.new(0, 200, 0, 40), UDim2.new(0, 0, 0, 320), function()
                    DialogFactory.createConfirmDialog(
                        "Reset Game Data",
                        "Are you sure you want to reset all game data? This action cannot be undone.",
                        function()
                            UIRegistry:showNotification("Game data has been reset", "success")
                            -- Add actual reset logic here
                        end
                    )
                end, "danger")
                resetButton.Parent = aboutFrame
            end
        }
    }
    
    -- Create the tabbed container for settings
    local settingsContainer = MenuContainer.createTabbedContainer(
        "Settings",
        "Settings",
        tabs,
        UDim2.new(0, 600, 0, 400),
        UDim2.new(0.5, 0, 0.5, 0),
        settingsGui,
        true -- Include close button
    )
    
    -- Store reference to the settings menu
    self.settingsGui = settingsGui
end

-- Create notification demonstration button
function UIExample:createNotificationButton()
    -- Create a screen gui for the button
    local buttonGui = Instance.new("ScreenGui")
    buttonGui.Name = "NotificationButtonGui"
    buttonGui.ResetOnSpawn = false
    buttonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    buttonGui.Parent = playerGui
    
    -- Create a button to show the example dialog
    local notifButton = ButtonFactory.createIconButton(
        "Notifications",
        "Bell",
        UDim2.new(0, 150, 0, 50),
        UDim2.new(0, 20, 0, 20),
        function()
            -- Show a sample notification of each type
            UIRegistry:showNotification("This is an information notification", "info", 3)
            
            task.delay(1, function()
                UIRegistry:showNotification("This is a success notification", "success", 3)
            end)
            
            task.delay(2, function()
                UIRegistry:showNotification("This is a warning notification", "warning", 3)
            end)
            
            task.delay(3, function()
                UIRegistry:showNotification("This is an error notification", "error", 3)
            end)
        end
    )
    notifButton.Parent = buttonGui
    
    -- Create a button to show the example dialog
    local dialogButton = ButtonFactory.createIconButton(
        "Dialog",
        "Document",
        UDim2.new(0, 150, 0, 50),
        UDim2.new(0, 20, 0, 80),
        function()
            UIRegistry:showUI("ExampleDialog")
        end
    )
    dialogButton.Parent = buttonGui
    
    -- Store reference to the button gui
    self.notificationButtonGui = buttonGui
end

-- Register UIs with the UIRegistry
function UIExample:registerUIs()
    -- Register main menu
    UIRegistry:registerUI("MainMenu", self.mainMenuGui, {
        priority = UIRegistry.priorityLevels.High,
        isModal = true,
        showTransition = "fade",
        closeTransition = "fade",
        transitionDuration = 0.5
    })
    
    -- Register example dialog
    UIRegistry:registerUI("ExampleDialog", self.exampleDialogGui, {
        priority = UIRegistry.priorityLevels.Modal,
        isModal = true,
        showTransition = "scale",
        closeTransition = "scale",
        transitionDuration = 0.3
    })
    
    -- Register settings menu
    UIRegistry:registerUI("SettingsMenu", self.settingsGui, {
        priority = UIRegistry.priorityLevels.High,
        isModal = true,
        showTransition = "slide",
        closeTransition = "slide",
        transitionDirection = "right",
        transitionDuration = 0.4
    })
end

-- Initialize and show main menu
function UIExample:init()
    self:createExampleUIs()
    
    -- After everything is set up, show the main menu
    task.delay(1, function()
        UIRegistry:showUI("MainMenu")
    end)
    
    return self
end

-- Initialize the example
UIExample:init()

return UIExample