-- UIModuleTemplate.luau
-- Template for creating UI modules compatible with UIHub
-- Part of UI refinements initiative (April 2025)
-- Copy this file to create new UI modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local UIStyle = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("UIStyle"))

-- Configuration
local CONFIG = {
    -- UI Placement
    menuSize = UDim2.new(0, 400, 0, 350),
    menuPosition = UDim2.new(0.5, 0, 0.5, 0),
    
    -- Animation
    tweenDuration = 0.3
}

-- Module definition
local UIModuleTemplate = {}

-- Private variables
local uiElements = {}
local callbacks = {}
local isInitialized = false

-- Initialize the UI module
function UIModuleTemplate:Initialize(UIManager)
    if isInitialized then return end
    
    -- Store reference to UIManager for use in callbacks
    self.UIManager = UIManager
    
    isInitialized = true
    return true
end

-- Create the UI components
function UIModuleTemplate:CreateUI()
    -- Create main frame with shadow using UIStyle
    local menu = UIStyle.createShadowFrame({
        name = "ModuleMenu",
        size = CONFIG.menuSize,
        position = CONFIG.menuPosition,
        anchorPoint = Vector2.new(0.5, 0.5),
        color = UIStyle.colors.background,
        cornerRadius = UIStyle.cornerRadius.large
    })
    
    -- Create header with UIStyle
    local header = UIStyle.createHeader({
        name = "Header",
        text = "Module Name", -- Change this to match your module's name
        color = UIStyle.colors.headerBackground,
        fixBottomCorners = true,
        parent = menu
    })
    
    -- Main content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -40, 1, -80)
    content.Position = UDim2.new(0, 20, 0, 60)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ZIndex = UIStyle.zIndex.content
    content.Parent = menu
    
    -- Footer container (optional)
    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, -40, 0, 40)
    footer.Position = UDim2.new(0, 20, 1, -50)
    footer.BackgroundTransparency = 1
    footer.BorderSizePixel = 0
    footer.ZIndex = UIStyle.zIndex.content
    footer.Parent = menu
    
    -- Add footer button (example)
    local actionButton = UIStyle.createButton({
        name = "ActionButton",
        size = UDim2.new(0, 120, 0, 35),
        position = UDim2.new(0.5, 0, 0, 0),
        anchorPoint = Vector2.new(0.5, 0),
        text = "Action",
        color = UIStyle.colors.primary,
        parent = footer
    })
    
    -- Connect close button
    header.CloseButton.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    -- Connect action button
    actionButton.MouseButton1Click:Connect(function()
        if callbacks.onAction then
            callbacks.onAction()
        end
    end)
    
    -- Store UI elements for future reference
    uiElements = {
        menu = menu,
        header = header,
        content = content,
        footer = footer,
        actionButton = actionButton
    }
    
    return menu
end

-- Open the UI
function UIModuleTemplate:Open(data)
    if not uiElements.menu then
        self:CreateUI()
    end
    
    -- Process any data passed to the Open function
    if data then
        self:UpdateUI(data)
    end
    
    -- Fire the onOpen callback if it exists
    if callbacks.onOpen then
        callbacks.onOpen(data)
    end
    
    return uiElements.menu
end

-- Close the UI
function UIModuleTemplate:Close()
    if self.UIManager then
        self.UIManager.closeUI("ModuleName") -- Change this to match your module name
    end
end

-- Update the UI with new data
function UIModuleTemplate:UpdateUI(data)
    -- Implement the logic to update your UI with new data
    -- Example:
    -- local content = uiElements.content
    -- content:ClearAllChildren()
    -- 
    -- for i, item in ipairs(data.items) do
    --     -- Create UI elements for each item
    -- end
end

-- Set callbacks for UI interaction
function UIModuleTemplate:SetCallbacks(callbackTable)
    callbacks = callbackTable or {}
end

-- For module API pattern compatibility
function UIModuleTemplate.create(data)
    if not isInitialized then
        UIModuleTemplate:Initialize()
    end
    
    local menu = UIModuleTemplate:CreateUI()
    
    -- Update if data is provided
    if data then
        UIModuleTemplate:UpdateUI(data)
    end
    
    return menu
end

function UIModuleTemplate.open(ui, data)
    -- Update if data is provided
    if data then
        UIModuleTemplate:UpdateUI(data)
    end
    
    return ui
end

function UIModuleTemplate.close(ui)
    if ui and ui.Parent then
        ui:Destroy()
    end
    
    uiElements = {}
end

return UIModuleTemplate