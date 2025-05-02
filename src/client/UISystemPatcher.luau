--[[
    UISystemPatcher.luau
    
    This module fixes common UI system issues by patching problematic behaviors
    and ensuring UI components load correctly.
    
    Created as part of April 29 fixes: May 2, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    PATCH_UI_COMPONENTS = true,
    PATCH_UI_SCALING = true,
    PATCH_ORDERING = true,
    ADD_FALLBACKS = true
}

-- Debug logging
local function log(message, messageType)
    if CONFIG.DEBUG_MODE or messageType == "error" or messageType == "warn" then
        local prefix = "[UISystemPatcher] "
        if messageType == "error" then
            warn(prefix .. "ERROR: " .. message)
        elseif messageType == "warn" then
            warn(prefix .. "WARNING: " .. message)
        else
            print(prefix .. message)
        end
    end
end

-- The player
local player = Players.LocalPlayer
if not player then
    -- Wait for player to be available
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

-- Get ClientRegistry if available
local ClientRegistry
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then
        local clientRegistryModule = shared:FindFirstChild("ClientRegistry")
        if clientRegistryModule then
            ClientRegistry = require(clientRegistryModule)
        end
    end
    
    if not ClientRegistry then
        -- Try player scripts
        local clientRegistryModule = player.PlayerScripts:FindFirstChild("ClientRegistry") or
                                   (player.PlayerScripts:FindFirstChild("Core") and 
                                    player.PlayerScripts.Core:FindFirstChild("ClientRegistry"))
        
        if clientRegistryModule then
            ClientRegistry = require(clientRegistryModule)
        end
    end
end)

-- Get UIComponents if available
local UIComponents
pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared then
        local uiComponentsModule = shared:FindFirstChild("UIComponents")
        if uiComponentsModule then
            UIComponents = require(uiComponentsModule)
        end
    end
    
    if not UIComponents then
        -- Try player scripts
        local uiComponentsModule = player.PlayerScripts:FindFirstChild("UIComponents") or
                                 (player.PlayerScripts:FindFirstChild("Core") and 
                                  player.PlayerScripts.Core:FindFirstChild("UIComponents"))
        
        if uiComponentsModule then
            UIComponents = require(uiComponentsModule)
        end
    end
end)

-- The UISystemPatcher module
local UISystemPatcher = {
    initialized = false,
    patchesApplied = {
        UIComponentsPatched = false,
        UIScalingPatched = false,
        OrderingPatched = false,
        FallbacksAdded = false
    },
    originalFunctions = {} -- Store original functions for reference
}

-- Initialize the module
function UISystemPatcher:initialize()
    if self.initialized then
        return true
    end
    
    log("Initializing UISystemPatcher...")
    
    -- Apply patches based on configuration
    if CONFIG.PATCH_UI_COMPONENTS and UIComponents then
        self:patchUIComponents()
    end
    
    if CONFIG.PATCH_UI_SCALING then
        self:patchUIScaling()
    end
    
    if CONFIG.PATCH_ORDERING then
        self:patchZIndexOrdering()
    end
    
    if CONFIG.ADD_FALLBACKS then
        self:addUIFallbacks()
    end
    
    -- Register with ClientRegistry if available
    if ClientRegistry and ClientRegistry.RegisterComponent then
        ClientRegistry.RegisterComponent("UISystemPatcher", self)
        log("Registered with ClientRegistry")
    end
    
    -- Handle key UI events
    self:setupUIEvents()
    
    self.initialized = true
    log("UISystemPatcher initialized successfully")
    return true
end

-- Patch UIComponents module
function UISystemPatcher:patchUIComponents()
    if not UIComponents then
        log("UIComponents module not found, cannot patch", "warn")
        return false
    end
    
    log("Patching UIComponents...")
    
    -- Store original functions
    if typeof(UIComponents.createUI) == "function" then
        self.originalFunctions.createUI = UIComponents.createUI
    end
    
    if typeof(UIComponents.showUI) == "function" then
        self.originalFunctions.showUI = UIComponents.showUI
    end
    
    if typeof(UIComponents.hideUI) == "function" then
        self.originalFunctions.hideUI = UIComponents.hideUI
    end
    
    -- Patch createUI to handle missing template errors
    if typeof(UIComponents.createUI) == "function" then
        UIComponents.createUI = function(uiName, parent, ...)
            local success, result = pcall(function()
                return self.originalFunctions.createUI(uiName, parent, ...)
            end)
            
            if success then
                return result
            else
                log("Error creating UI " .. uiName .. ": " .. tostring(result), "warn")
                
                -- Try to create a fallback UI
                return self:createFallbackUI(uiName, parent)
            end
        end
    end
    
    -- Patch showUI to handle errors
    if typeof(UIComponents.showUI) == "function" then
        UIComponents.showUI = function(uiName, ...)
            local success, result = pcall(function()
                return self.originalFunctions.showUI(uiName, ...)
            end)
            
            if success then
                return result
            else
                log("Error showing UI " .. uiName .. ": " .. tostring(result), "warn")
                
                -- Try to create and show fallback UI
                local fallbackUI = self:createFallbackUI(uiName, player:FindFirstChild("PlayerGui"))
                if fallbackUI then
                    fallbackUI.Visible = true
                    return true
                end
                
                return false
            end
        end
    end
    
    self.patchesApplied.UIComponentsPatched = true
    log("UIComponents patched successfully")
    return true
end

-- Patch UI scaling
function UISystemPatcher:patchUIScaling()
    log("Patching UI scaling...")
    
    -- Find existing PlayerGui
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        log("PlayerGui not found, cannot patch scaling", "warn")
        return false
    end
    
    -- Check for ScreenGui instances with scaling issues
    for _, instance in ipairs(playerGui:GetChildren()) do
        if instance:IsA("ScreenGui") then
            -- Fix scaling mode if incorrect
            if instance.IgnoreGuiInset == false then
                instance.IgnoreGuiInset = true
                log("Fixed IgnoreGuiInset for " .. instance.Name)
            end
            
            -- Fix screen orientation
            if instance.ZIndexBehavior ~= Enum.ZIndexBehavior.Sibling then
                instance.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                log("Fixed ZIndexBehavior for " .. instance.Name)
            end
        end
    end
    
    -- Set up automatic fixes for new ScreenGui instances
    playerGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") then
            -- Fix scaling mode
            if child.IgnoreGuiInset == false then
                child.IgnoreGuiInset = true
                log("Fixed IgnoreGuiInset for new UI: " .. child.Name)
            end
            
            -- Fix screen orientation
            if child.ZIndexBehavior ~= Enum.ZIndexBehavior.Sibling then
                child.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                log("Fixed ZIndexBehavior for new UI: " .. child.Name)
            end
        end
    end)
    
    self.patchesApplied.UIScalingPatched = true
    log("UI scaling patched successfully")
    return true
end

-- Patch Z-index ordering
function UISystemPatcher:patchZIndexOrdering()
    log("Patching Z-index ordering...")
    
    -- Find existing PlayerGui
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        log("PlayerGui not found, cannot patch ordering", "warn")
        return false
    end
    
    -- Define the expected display order for common UIs
    local displayOrders = {
        LoadingUI = 100,
        NotificationUI = 90,
        DialogUI = 80,
        MenuUI = 70,
        HUD = 60,
        GameUI = 50,
        BackgroundUI = 10
    }
    
    -- Fix display orders for existing UIs
    for _, instance in ipairs(playerGui:GetChildren()) do
        if instance:IsA("ScreenGui") then
            local expectedOrder = displayOrders[instance.Name]
            if expectedOrder and instance.DisplayOrder ~= expectedOrder then
                instance.DisplayOrder = expectedOrder
                log("Fixed DisplayOrder for " .. instance.Name .. " to " .. expectedOrder)
            end
        end
    end
    
    -- Set up automatic fixes for new UIs
    playerGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") then
            local expectedOrder = displayOrders[child.Name]
            if expectedOrder and child.DisplayOrder ~= expectedOrder then
                child.DisplayOrder = expectedOrder
                log("Fixed DisplayOrder for new UI: " .. child.Name .. " to " .. expectedOrder)
            end
        end
    end)
    
    self.patchesApplied.OrderingPatched = true
    log("Z-index ordering patched successfully")
    return true
end

-- Add UI fallbacks
function UISystemPatcher:addUIFallbacks()
    log("Adding UI fallbacks...")
    
    -- Find existing PlayerGui
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        log("PlayerGui not found, cannot add fallbacks", "warn")
        return false
    end
    
    -- Create fallback notification system
    local notificationSystem = playerGui:FindFirstChild("NotificationSystem")
    if not notificationSystem then
        notificationSystem = Instance.new("ScreenGui")
        notificationSystem.Name = "NotificationSystem"
        notificationSystem.DisplayOrder = 100
        notificationSystem.IgnoreGuiInset = true
        notificationSystem.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        notificationSystem.Parent = playerGui
        
        -- Create notification container
        local container = Instance.new("Frame")
        container.Name = "NotificationContainer"
        container.Size = UDim2.new(0, 300, 0, 400)
        container.Position = UDim2.new(1, -320, 0, 20)
        container.BackgroundTransparency = 1
        container.Parent = notificationSystem
        
        -- Create layout
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Parent = container
        
        log("Created fallback notification system")
        
        -- Create show notification function
        _G.showNotification = function(message, duration)
            duration = duration or 5
            
            -- Create notification frame
            local notification = Instance.new("Frame")
            notification.Name = "Notification"
            notification.Size = UDim2.new(1, 0, 0, 60)
            notification.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            notification.BorderSizePixel = 0
            notification.BackgroundTransparency = 0.2
            
            -- Create corner
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = notification
            
            -- Create message text
            local text = Instance.new("TextLabel")
            text.Name = "Message"
            text.Size = UDim2.new(1, -20, 1, -20)
            text.Position = UDim2.new(0, 10, 0, 10)
            text.BackgroundTransparency = 1
            text.TextColor3 = Color3.fromRGB(255, 255, 255)
            text.TextSize = 16
            text.TextWrapped = true
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.Text = message
            text.Parent = notification
            
            -- Add to container
            notification.Parent = container
            
            -- Animate in
            notification.BackgroundTransparency = 1
            notification.Position = UDim2.new(1, 0, 0, 0)
            
            -- Tween in
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = game:GetService("TweenService"):Create(notification, tweenInfo, {
                BackgroundTransparency = 0.2,
                Position = UDim2.new(0, 0, 0, 0)
            })
            tween:Play()
            
            -- Remove after duration
            task.delay(duration, function()
                -- Tween out
                local outTween = game:GetService("TweenService"):Create(notification, tweenInfo, {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, 0, 0, 0)
                })
                outTween:Play()
                
                outTween.Completed:Connect(function()
                    notification:Destroy()
                end)
            end)
            
            return notification
        end
        
        log("Created global showNotification function")
    end
    
    self.patchesApplied.FallbacksAdded = true
    log("UI fallbacks added successfully")
    return true
end

-- Create a fallback UI
function UISystemPatcher:createFallbackUI(uiName, parent)
    log("Creating fallback UI for " .. uiName)
    
    local fallbackUI = Instance.new("ScreenGui")
    fallbackUI.Name = uiName
    fallbackUI.IgnoreGuiInset = true
    fallbackUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Set display order based on UI name
    if uiName:match("Loading") or uiName:match("Error") then
        fallbackUI.DisplayOrder = 100
    elseif uiName:match("Notification") or uiName:match("Toast") then
        fallbackUI.DisplayOrder = 90
    elseif uiName:match("Dialog") or uiName:match("Modal") then
        fallbackUI.DisplayOrder = 80
    elseif uiName:match("Menu") then
        fallbackUI.DisplayOrder = 70
    else
        fallbackUI.DisplayOrder = 50
    end
    
    -- Create background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    background.BackgroundTransparency = 0.4
    background.Parent = fallbackUI
    
    -- Create content frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(0, 400, 0, 200)
    content.Position = UDim2.new(0.5, 0, 0.5, 0)
    content.AnchorPoint = Vector2.new(0.5, 0.5)
    content.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    content.BorderSizePixel = 0
    content.Parent = fallbackUI
    
    -- Create corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = content
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 40)
    title.Position = UDim2.new(0, 20, 0, 20)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = uiName
    title.Font = Enum.Font.GothamBold
    title.Parent = content
    
    -- Create message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -40, 0, 80)
    message.Position = UDim2.new(0, 20, 0, 70)
    message.BackgroundTransparency = 1
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.TextSize = 16
    message.TextWrapped = true
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.Text = "This is a fallback UI created because the original " .. uiName .. " could not be loaded."
    message.Font = Enum.Font.Gotham
    message.Parent = content
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 120, 0, 40)
    closeButton.Position = UDim2.new(0.5, 0, 1, -60)
    closeButton.AnchorPoint = Vector2.new(0.5, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.Text = "Close"
    closeButton.Font = Enum.Font.Gotham
    closeButton.Parent = content
    
    -- Create button corner
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = closeButton
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        fallbackUI.Visible = false
    end)
    
    fallbackUI.Parent = parent
    fallbackUI.Visible = false
    
    log("Created fallback UI for " .. uiName)
    return fallbackUI
end

-- Set up UI events
function UISystemPatcher:setupUIEvents()
    log("Setting up UI events...")
    
    -- Get PlayerGui
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        log("PlayerGui not found, cannot set up events", "warn")
        return false
    end
    
    -- Monitor for common UI errors
    playerGui.DescendantAdded:Connect(function(descendant)
        task.spawn(function()
            -- Check for common issues that might cause UI problems
            if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                if descendant.Text == "" then return end
                
                if descendant.TextScaled and descendant.Size.Y.Scale < 0.01 then
                    log("Very small text with TextScaled: " .. descendant:GetFullName(), "warn")
                end
                
                -- Check for invalid fonts
                pcall(function() 
                    if descendant.FontFace.Weight < 100 then
                        log("Invalid FontFace weight: " .. descendant:GetFullName(), "warn")
                    end
                end)
            elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
                if descendant.Image ~= "" and not descendant.Image:match("^rbxasset") then
                    -- Check for valid image size
                    if descendant.Size.X.Offset < 5 or descendant.Size.Y.Offset < 5 then
                        log("Very small image: " .. descendant:GetFullName(), "warn")
                    end
                end
            end
        end)
    end)
    
    log("UI events set up successfully")
    return true
end

-- Get patch status
function UISystemPatcher:getPatchStatus()
    return {
        initialized = self.initialized,
        patchesApplied = self.patchesApplied,
        timestamp = os.time()
    }
end

-- Global API for other scripts to use
_G.UIPatcher = {
    showNotification = _G.showNotification,
    getPatchStatus = function() return UISystemPatcher:getPatchStatus() end,
    createFallbackUI = function(uiName, parent) return UISystemPatcher:createFallbackUI(uiName, parent) end
}

-- Automatically initialize
task.spawn(function()
    UISystemPatcher:initialize()
end)

return UISystemPatcher
