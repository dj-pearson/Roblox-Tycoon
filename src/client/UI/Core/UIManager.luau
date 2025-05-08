--!strict
--[[
    UIManager.luau
    
    Manages the lifecycle and display of UI elements.
    Handles showing/hiding UI components and manages their state.
    
    Features:
    - UI component lifecycle management
    - Screen transitions
    - Modal dialog management
    - UI state persistence
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    debugMode = true,
    defaultTransitionTime = 0.3,
    useTransitions = true,
    zIndexIncrement = 10,
    modalZIndex = 1000
}

-- State
local UIManager = {
    initialized = false,
    activeUIs = {},
    modalStack = {},
    nextZIndex = 1
}

-- Logging
local function log(message, level)
    level = level or "Info"
    local prefix = "[UIManager] "
    
    if level == "Info" and CONFIG.debugMode then
        print(prefix .. message)
    elseif level == "Warning" then
        warn(prefix .. message)
    elseif level == "Error" then
        error(prefix .. message)
    end
end

-- Initialize the UI manager
function UIManager:initialize()
    if self.initialized then
        log("UIManager already initialized", "Warning")
        return true
    end
    
    log("Initializing UIManager...")
    
    -- Clear any existing state
    self.activeUIs = {}
    self.modalStack = {}
    self.nextZIndex = 1
    
    self.initialized = true
    log("UIManager initialized")
    return true
end

-- Show a UI component
function UIManager:showUI(name, component, ...)
    if not self.initialized then
        log("Cannot show UI, UIManager not initialized", "Warning")
        return false
    end
    
    if not name or not component then
        log("Invalid UI show request: missing name or component", "Error")
        return false
    end
    
    -- Check if UI is already active
    if self.activeUIs[name] then
        log("UI already active: " .. name, "Warning")
        return false
    end
    
    -- Create UI instance
    local ui = component:create(...)
    if not ui then
        log("Failed to create UI: " .. name, "Error")
        return false
    end
    
    -- Set up UI properties
    ui.Name = name
    ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ui.ResetOnSpawn = false
    
    -- Set z-index
    ui.ZIndex = self.nextZIndex
    self.nextZIndex = self.nextZIndex + CONFIG.zIndexIncrement
    
    -- Add to PlayerGui
    ui.Parent = PlayerGui
    
    -- Store reference
    self.activeUIs[name] = {
        instance = ui,
        component = component
    }
    
    -- Show with transition if enabled
    if CONFIG.useTransitions then
        self:transitionIn(ui)
    else
        ui.Visible = true
    end
    
    log("Showing UI: " .. name)
    return true
end

-- Hide a UI component
function UIManager:hideUI(name)
    if not self.initialized then
        return false
    end
    
    local uiData = self.activeUIs[name]
    if not uiData then
        log("UI not found: " .. name, "Warning")
        return false
    end
    
    local ui = uiData.instance
    
    -- Hide with transition if enabled
    if CONFIG.useTransitions then
        self:transitionOut(ui, function()
            ui:Destroy()
        end)
    else
        ui:Destroy()
    end
    
    -- Remove from active UIs
    self.activeUIs[name] = nil
    
    log("Hiding UI: " .. name)
    return true
end

-- Show a modal dialog
function UIManager:showModal(options)
    if not self.initialized then
        return nil
    end
    
    -- Create modal instance
    local modal = Instance.new("ScreenGui")
    modal.Name = "Modal_" .. options.title
    modal.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    modal.ResetOnSpawn = false
    
    -- Set z-index above other UIs
    modal.ZIndex = self.modalZIndex + #self.modalStack
    
    -- Create background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.Parent = modal
    
    -- Create dialog frame
    local dialog = Instance.new("Frame")
    dialog.Name = "Dialog"
    dialog.Size = UDim2.new(0, 400, 0, 200)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
    dialog.BackgroundColor3 = Color3.new(1, 1, 1)
    dialog.BorderSizePixel = 0
    dialog.Parent = modal
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = options.title
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = dialog
    
    -- Add content
    local content = Instance.new("TextLabel")
    content.Name = "Content"
    content.Size = UDim2.new(1, -40, 1, -100)
    content.Position = UDim2.new(0, 20, 0, 60)
    content.BackgroundTransparency = 1
    content.Text = options.message
    content.TextSize = 18
    content.Font = Enum.Font.Gotham
    content.TextWrapped = true
    content.Parent = dialog
    
    -- Add buttons
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "Buttons"
    buttonContainer.Size = UDim2.new(1, -40, 0, 40)
    buttonContainer.Position = UDim2.new(0, 20, 1, -50)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = dialog
    
    -- Add to PlayerGui
    modal.Parent = PlayerGui
    
    -- Store in modal stack
    table.insert(self.modalStack, modal)
    
    log("Showing modal: " .. options.title)
    return modal
end

-- Hide a modal dialog
function UIManager:hideModal(modal)
    if not self.initialized then
        return false
    end
    
    -- Find modal in stack
    local index = table.find(self.modalStack, modal)
    if not index then
        log("Modal not found in stack", "Warning")
        return false
    end
    
    -- Remove from stack
    table.remove(self.modalStack, index)
    
    -- Destroy modal
    modal:Destroy()
    
    log("Hiding modal")
    return true
end

-- Hide all UIs
function UIManager:hideAllUIs()
    if not self.initialized then
        return false
    end
    
    for name, _ in pairs(self.activeUIs) do
        self:hideUI(name)
    end
    
    log("Hid all UIs")
    return true
end

-- Close all modals
function UIManager:closeAllModals()
    if not self.initialized then
        return false
    end
    
    for _, modal in ipairs(self.modalStack) do
        modal:Destroy()
    end
    
    self.modalStack = {}
    log("Closed all modals")
    return true
end

-- Transition in animation
function UIManager:transitionIn(ui)
    ui.Visible = true
    ui.BackgroundTransparency = 1
    
    local tweenInfo = TweenInfo.new(
        CONFIG.defaultTransitionTime,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(ui, tweenInfo, {
        BackgroundTransparency = 0
    })
    
    tween:Play()
end

-- Transition out animation
function UIManager:transitionOut(ui, callback)
    local tweenInfo = TweenInfo.new(
        CONFIG.defaultTransitionTime,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In
    )
    
    local tween = TweenService:Create(ui, tweenInfo, {
        BackgroundTransparency = 1
    })
    
    tween.Completed:Connect(function()
        if callback then
            callback()
        end
    end)
    
    tween:Play()
end

-- Shutdown the UI manager
function UIManager:shutdown()
    if not self.initialized then
        return true
    end
    
    log("Shutting down UIManager...")
    
    -- Hide all UIs
    self:hideAllUIs()
    
    -- Close all modals
    self:closeAllModals()
    
    self.initialized = false
    log("UIManager shutdown complete")
    return true
end

return UIManager
