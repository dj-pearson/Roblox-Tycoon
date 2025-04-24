--[[
    UIRegistry.client.luau
    
    A central registry for managing all UI elements in the game.
    Handles UI registration, visibility, transitions, and state management.
    
    Author: Updated April 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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
local DialogFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("DialogFactory"))

-- Create fallbacks if modules not found
if not UIStyle then
    warn("UIStyle module not found in UIRegistry, using fallback")
    UIStyle = {
        Animations = {
            Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        }
    }
end

-- UI Registry Module
local UIRegistry = {}

-- Private state
local registeredUIs = {}
local activeUIs = {}
local transitioningUIs = {}
local priorityLevels = {
    Low = 1,
    Normal = 2,
    High = 3,
    Modal = 4,
    System = 5
}
local blockingOverlay = nil
local isInitialized = false
local player = Players.LocalPlayer
local playerGui = player and player:FindFirstChild("PlayerGui")
local debugMode = false

-- Forward declarations
local closeUI, closeAllUIs, showUI, handleUIConflicts
local createBlockingOverlay, removeBlockingOverlay

-- Initialize the registry
function UIRegistry:initialize()
    if isInitialized then
        return self
    end
    
    if not playerGui then
        warn("PlayerGui not found, UIRegistry initialization failed")
        return self
    end
    
    -- Create a folder for system UI elements
    local systemFolder = Instance.new("Folder")
    systemFolder.Name = "UIRegistrySystem"
    systemFolder.Parent = playerGui
    
    -- Create a blocking overlay for modal dialogs
    blockingOverlay = Instance.new("ScreenGui")
    blockingOverlay.Name = "ModalBlocker"
    blockingOverlay.DisplayOrder = 100000 -- Very high to block everything
    blockingOverlay.IgnoreGuiInset = true
    blockingOverlay.ResetOnSpawn = false
    blockingOverlay.Enabled = false
    blockingOverlay.Parent = systemFolder
    
    local blocker = Instance.new("Frame")
    blocker.Name = "BlockerFrame"
    blocker.Size = UDim2.new(1, 0, 1, 0)
    blocker.BackgroundColor3 = Color3.new(0, 0, 0)
    blocker.BackgroundTransparency = 0.5
    blocker.BorderSizePixel = 0
    blocker.Parent = blockingOverlay
    
    blocker.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            -- Ignore clicks on the blocking overlay
            return
        end
    end)
    
    isInitialized = true
    return self
end

-- Register a UI with the registry
function UIRegistry:registerUI(id, ui, options)
    if not isInitialized then
        self:initialize()
    end
    
    if registeredUIs[id] then
        warn("UI with id '" .. id .. "' is already registered")
        return false
    end
    
    -- Set default options if not provided
    options = options or {}
    
    -- Store the UI with its options
    registeredUIs[id] = {
        id = id,
        ui = ui,
        priority = options.priority or priorityLevels.Normal,
        isModal = options.isModal or false,
        isSystem = options.isSystem or false,
        singleInstance = options.singleInstance ~= false, -- Default to true
        closeOthers = options.closeOthers or false,
        groupId = options.groupId,
        allowMultipleInGroup = options.allowMultipleInGroup or false,
        onBeforeShow = options.onBeforeShow,
        onAfterShow = options.onAfterShow,
        onBeforeClose = options.onBeforeClose,
        onAfterClose = options.onAfterClose,
        showTransition = options.showTransition or "fade", -- fade, slide, scale
        closeTransition = options.closeTransition or "fade", -- fade, slide, scale
        transitionDirection = options.transitionDirection or "right", -- right, left, top, bottom
        transitionDuration = options.transitionDuration or 0.3,
        initialPosition = options.initialPosition,
        hiddenPosition = options.hiddenPosition
    }
    
    -- If the UI is already visible, add it to active UIs
    if ui.Visible then
        activeUIs[id] = {
            id = id,
            ui = ui,
            instance = nil, -- No separate instance since this is the base UI
            priority = registeredUIs[id].priority,
            isModal = registeredUIs[id].isModal
        }
        
        -- Enable modal blocker if needed
        if registeredUIs[id].isModal then
            createBlockingOverlay()
        end
    else
        -- Make sure the UI is hidden
        ui.Visible = false
    end
    
    if debugMode then
        print("Registered UI: " .. id)
    end
    
    return true
end

-- Unregister a UI from the registry
function UIRegistry:unregisterUI(id)
    if not registeredUIs[id] then
        return false
    end
    
    -- Close the UI if it's active
    if activeUIs[id] then
        closeUI(id, true)
    end
    
    -- Remove from registry
    registeredUIs[id] = nil
    
    if debugMode then
        print("Unregistered UI: " .. id)
    end
    
    return true
end

-- Show a UI by its ID
function UIRegistry:showUI(id, data, instance)
    if not isInitialized then
        self:initialize()
    end
    
    if not registeredUIs[id] then
        warn("Cannot show UI with id '" .. id .. "', it is not registered")
        return nil
    end
    
    -- Show the UI, passing any data
    return showUI(id, data, instance)
end

-- Close a UI by its ID
function UIRegistry:closeUI(id, skipTransition)
    if not activeUIs[id] then
        return false
    end
    
    return closeUI(id, skipTransition)
end

-- Close all active UIs
function UIRegistry:closeAllUIs(exceptIds, skipTransition)
    exceptIds = exceptIds or {}
    local exceptIdsSet = {}
    
    for _, id in ipairs(exceptIds) do
        exceptIdsSet[id] = true
    end
    
    return closeAllUIs(exceptIdsSet, skipTransition)
end

-- Check if a UI is active
function UIRegistry:isUIActive(id)
    return activeUIs[id] ~= nil
end

-- Get all active UIs
function UIRegistry:getActiveUIs()
    local active = {}
    for id, _ in pairs(activeUIs) do
        table.insert(active, id)
    end
    return active
end

-- Show a notification using DialogFactory if available
function UIRegistry:showNotification(message, notificationType, duration)
    if DialogFactory then
        DialogFactory.createNotification(message, notificationType, duration)
        return true
    else
        -- Fallback notification if DialogFactory is not available
        warn("DialogFactory not available, showing fallback notification")
        print("[" .. (notificationType or "info") .. "] " .. message)
        return false
    end
end

-- Show a confirmation dialog using DialogFactory if available
function UIRegistry:showConfirmation(title, message, confirmCallback, cancelCallback)
    if DialogFactory then
        return DialogFactory.createConfirmDialog(title, message, confirmCallback, cancelCallback)
    else
        -- Fallback confirmation if DialogFactory is not available
        warn("DialogFactory not available, showing fallback confirmation")
        print("[Confirmation] " .. title .. ": " .. message)
        
        -- Ask for confirmation in the output
        print("Type 'Y' to confirm or 'N' to cancel in the command bar")
        
        -- Cannot directly capture input, so we just return a placeholder
        return {
            id = "placeholder_" .. os.time(),
            close = function() end
        }
    end
end

-- Show a message dialog using DialogFactory if available
function UIRegistry:showMessage(title, message, callback)
    if DialogFactory then
        return DialogFactory.createMessageDialog(title, message, callback)
    else
        -- Fallback message if DialogFactory is not available
        warn("DialogFactory not available, showing fallback message")
        print("[Message] " .. title .. ": " .. message)
        
        return {
            id = "placeholder_" .. os.time(),
            close = function() end
        }
    end
end

-- Toggle debug mode
function UIRegistry:setDebugMode(enabled)
    debugMode = enabled
    return self
end

-- Toggle visibility of a UI
function UIRegistry:toggleUI(id, data)
    if activeUIs[id] then
        return self:closeUI(id)
    else
        return self:showUI(id, data)
    end
end

-- Get data from an active UI (if the UI exposes a getData method)
function UIRegistry:getUIData(id)
    if not activeUIs[id] or not activeUIs[id].ui.getData then
        return nil
    end
    
    return activeUIs[id].ui.getData()
end

-- Update a UI with new data (if the UI exposes an updateData method)
function UIRegistry:updateUI(id, data)
    if not activeUIs[id] or not activeUIs[id].ui.updateData then
        return false
    end
    
    activeUIs[id].ui.updateData(data)
    return true
end

-- Get registered UI definition
function UIRegistry:getUIDefinition(id)
    return registeredUIs[id]
end

-- PRIVATE IMPLEMENTATION FUNCTIONS

-- Show a UI with transition
function showUI(id, data, instance)
    local uiDef = registeredUIs[id]
    if not uiDef then return nil end
    
    -- If already transitioning, cancel the request
    if transitioningUIs[id] then
        if debugMode then
            print("UI is currently transitioning: " .. id)
        end
        return nil
    end
    
    -- If this UI is configured to close others, do that first
    if uiDef.closeOthers then
        closeAllUIs({[id] = true}, true)
    end
    
    -- If this UI is part of a group and allows only one instance
    if uiDef.groupId and not uiDef.allowMultipleInGroup then
        -- Close other UIs in the same group
        for activeId, activeUI in pairs(activeUIs) do
            local activeDef = registeredUIs[activeId]
            if activeDef and activeDef.groupId == uiDef.groupId and activeId ~= id then
                closeUI(activeId, true)
            end
        end
    end
    
    -- Check if the UI is already active and this is a single instance UI
    if activeUIs[id] and uiDef.singleInstance then
        -- If we don't want multiple instances, just return the active one
        return activeUIs[id].ui
    end
    
    -- Create a new instance or use the base UI
    local ui
    local instanceId = id
    
    if instance then
        -- Use the provided instance
        ui = instance
        instanceId = id .. "_" .. os.time()
    else
        -- Use the registered UI
        ui = uiDef.ui
    end
    
    -- Execute the before show callback if defined
    if uiDef.onBeforeShow and typeof(uiDef.onBeforeShow) == "function" then
        uiDef.onBeforeShow(ui, data)
    end
    
    -- Handle conflicts with other UIs
    handleUIConflicts(id, uiDef.priority)
    
    -- Enable modal blocker if needed
    if uiDef.isModal then
        createBlockingOverlay()
    end
    
    -- Set UI as transitioning
    transitioningUIs[id] = true
    
    -- Prepare the UI for the transition
    if uiDef.showTransition == "slide" then
        -- Set starting position for slide
        local startPos
        local endPos = uiDef.initialPosition or ui.Position
        
        if uiDef.hiddenPosition then
            startPos = uiDef.hiddenPosition
        else
            if uiDef.transitionDirection == "right" then
                startPos = UDim2.new(1, 0, endPos.Y.Scale, endPos.Y.Offset)
            elseif uiDef.transitionDirection == "left" then
                startPos = UDim2.new(-1, 0, endPos.Y.Scale, endPos.Y.Offset)
            elseif uiDef.transitionDirection == "top" then
                startPos = UDim2.new(endPos.X.Scale, endPos.X.Offset, -1, 0)
            else -- bottom
                startPos = UDim2.new(endPos.X.Scale, endPos.X.Offset, 1, 0)
            end
        end
        
        ui.Position = startPos
        ui.Visible = true
        
        -- Animate to final position
        TweenService:Create(
            ui,
            TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = endPos}
        ):Play()
    elseif uiDef.showTransition == "scale" then
        -- Set starting scale and position
        local originalSize = ui.Size
        local originalPosition = uiDef.initialPosition or ui.Position
        
        ui.AnchorPoint = Vector2.new(0.5, 0.5)
        ui.Position = UDim2.new(
            originalPosition.X.Scale + (originalSize.X.Scale / 2), 
            originalPosition.X.Offset + (originalSize.X.Offset / 2),
            originalPosition.Y.Scale + (originalSize.Y.Scale / 2), 
            originalPosition.Y.Offset + (originalSize.Y.Offset / 2)
        )
        ui.Size = UDim2.new(0, 0, 0, 0)
        ui.Visible = true
        
        -- Animate to normal size
        TweenService:Create(
            ui,
            TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {
                Size = originalSize,
                Position = UDim2.new(
                    originalPosition.X.Scale + (originalSize.X.Scale / 2), 
                    originalPosition.X.Offset + (originalSize.X.Offset / 2),
                    originalPosition.Y.Scale + (originalSize.Y.Scale / 2), 
                    originalPosition.Y.Offset + (originalSize.Y.Offset / 2)
                )
            }
        ):Play()
    else -- fade (default)
        -- Set transparency for fade
        for _, object in pairs(ui:GetDescendants()) do
            if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) and object:GetAttribute("DoNotFade") ~= true then
                object.TextTransparency = 1
            elseif (object:IsA("ImageLabel") or object:IsA("ImageButton")) and object:GetAttribute("DoNotFade") ~= true then
                object.ImageTransparency = 1
            elseif object:IsA("Frame") and object:GetAttribute("DoNotFade") ~= true then
                object.BackgroundTransparency = 1
            end
        end
        
        -- Also set base UI transparent if it's a GuiObject
        if ui:IsA("GuiObject") and ui:GetAttribute("DoNotFade") ~= true then
            if ui:IsA("TextLabel") or ui:IsA("TextButton") or ui:IsA("TextBox") then
                ui.TextTransparency = 1
            end
            if ui:IsA("ImageLabel") or ui:IsA("ImageButton") then
                ui.ImageTransparency = 1
            end
            ui.BackgroundTransparency = 1
        end
        
        ui.Visible = true
        
        -- Animate fade in for all objects
        for _, object in pairs(ui:GetDescendants()) do
            if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) and object:GetAttribute("DoNotFade") ~= true then
                local originalTransparency = object:GetAttribute("OriginalTextTransparency") or 0
                object:SetAttribute("OriginalTextTransparency", originalTransparency)
                TweenService:Create(
                    object,
                    TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {TextTransparency = originalTransparency}
                ):Play()
            elseif (object:IsA("ImageLabel") or object:IsA("ImageButton")) and object:GetAttribute("DoNotFade") ~= true then
                local originalTransparency = object:GetAttribute("OriginalImageTransparency") or 0
                object:SetAttribute("OriginalImageTransparency", originalTransparency)
                TweenService:Create(
                    object,
                    TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {ImageTransparency = originalTransparency}
                ):Play()
            elseif object:IsA("Frame") and object:GetAttribute("DoNotFade") ~= true then
                local originalTransparency = object:GetAttribute("OriginalBackgroundTransparency") or 0
                object:SetAttribute("OriginalBackgroundTransparency", originalTransparency)
                TweenService:Create(
                    object,
                    TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundTransparency = originalTransparency}
                ):Play()
            end
        end
        
        -- Also fade in the base UI if it's a GuiObject
        if ui:IsA("GuiObject") and ui:GetAttribute("DoNotFade") ~= true then
            if ui:IsA("TextLabel") or ui:IsA("TextButton") or ui:IsA("TextBox") then
                local originalTransparency = ui:GetAttribute("OriginalTextTransparency") or 0
                ui:SetAttribute("OriginalTextTransparency", originalTransparency)
                TweenService:Create(
                    ui,
                    TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {TextTransparency = originalTransparency}
                ):Play()
            end
            if ui:IsA("ImageLabel") or ui:IsA("ImageButton") then
                local originalTransparency = ui:GetAttribute("OriginalImageTransparency") or 0
                ui:SetAttribute("OriginalImageTransparency", originalTransparency)
                TweenService:Create(
                    ui,
                    TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {ImageTransparency = originalTransparency}
                ):Play()
            end
            
            local originalTransparency = ui:GetAttribute("OriginalBackgroundTransparency") or 0
            ui:SetAttribute("OriginalBackgroundTransparency", originalTransparency)
            TweenService:Create(
                ui,
                TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = originalTransparency}
            ):Play()
        end
    end
    
    -- Register as active after transition starts
    activeUIs[instanceId] = {
        id = id,
        ui = ui,
        instance = instance,
        priority = uiDef.priority,
        isModal = uiDef.isModal
    }
    
    -- Show without transition for instant display
    if uiDef.transitionDuration <= 0 or uiDef.showTransition == "none" then
        ui.Visible = true
        transitioningUIs[id] = nil
        
        -- Call the after show callback if defined
        if uiDef.onAfterShow and typeof(uiDef.onAfterShow) == "function" then
            uiDef.onAfterShow(ui, data)
        end
    else
        -- Complete transition after duration
        task.delay(uiDef.transitionDuration, function()
            if transitioningUIs[id] then
                transitioningUIs[id] = nil
                
                -- Call the after show callback if defined
                if uiDef.onAfterShow and typeof(uiDef.onAfterShow) == "function" then
                    uiDef.onAfterShow(ui, data)
                end
            end
        end)
    end
    
    if debugMode then
        print("Showed UI: " .. id .. (instance and " (instance)" or ""))
    end
    
    -- Initiate the UI's data if it has an initData method and data was provided
    if data and ui.initData and typeof(ui.initData) == "function" then
        ui.initData(data)
    end
    
    return ui
end

-- Close a UI with transition
function closeUI(id, skipTransition)
    local activeUI = activeUIs[id]
    if not activeUI then return false end
    
    local uiDef = registeredUIs[activeUI.id]
    if not uiDef then return false end
    
    local ui = activeUI.ui
    
    -- If already transitioning, cancel the request
    if transitioningUIs[id] then
        if debugMode then
            print("UI is currently transitioning: " .. id)
        end
        return false
    end
    
    -- Execute the before close callback if defined
    if uiDef.onBeforeClose and typeof(uiDef.onBeforeClose) == "function" then
        uiDef.onBeforeClose(ui)
    end
    
    -- If skipping transition or transition duration is 0, close immediately
    if skipTransition or uiDef.transitionDuration <= 0 or uiDef.closeTransition == "none" then
        ui.Visible = false
        activeUIs[id] = nil
        
        -- Check if we can remove the modal blocker
        if activeUI.isModal then
            local anyModalActive = false
            for _, otherUI in pairs(activeUIs) do
                if otherUI.isModal then
                    anyModalActive = true
                    break
                end
            end
            
            if not anyModalActive then
                removeBlockingOverlay()
            end
        end
        
        -- Call the after close callback if defined
        if uiDef.onAfterClose and typeof(uiDef.onAfterClose) == "function" then
            uiDef.onAfterClose(ui)
        end
        
        if debugMode then
            print("Closed UI: " .. id .. " (no transition)")
        end
        
        return true
    end
    
    -- Set UI as transitioning
    transitioningUIs[id] = true
    
    -- Apply the close transition
    if uiDef.closeTransition == "slide" then
        -- Calculate end position for slide
        local endPos
        if uiDef.hiddenPosition then
            endPos = uiDef.hiddenPosition
        else
            local startPos = ui.Position
            
            if uiDef.transitionDirection == "right" then
                endPos = UDim2.new(1, 0, startPos.Y.Scale, startPos.Y.Offset)
            elseif uiDef.transitionDirection == "left" then
                endPos = UDim2.new(-1, 0, startPos.Y.Scale, startPos.Y.Offset)
            elseif uiDef.transitionDirection == "top" then
                endPos = UDim2.new(startPos.X.Scale, startPos.X.Offset, -1, 0)
            else -- bottom
                endPos = UDim2.new(startPos.X.Scale, startPos.X.Offset, 1, 0)
            end
        end
        
        -- Animate to end position
        TweenService:Create(
            ui,
            TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = endPos}
        ):Play()
    elseif uiDef.closeTransition == "scale" then
        -- Animate to zero size
        TweenService:Create(
            ui,
            TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        ):Play()
    else -- fade (default)
        -- Animate fade out for all objects
        for _, object in pairs(ui:GetDescendants()) do
            if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) and object:GetAttribute("DoNotFade") ~= true then
                TweenService:Create(
                    object,
                    TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {TextTransparency = 1}
                ):Play()
            elseif (object:IsA("ImageLabel") or object:IsA("ImageButton")) and object:GetAttribute("DoNotFade") ~= true then
                TweenService:Create(
                    object,
                    TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {ImageTransparency = 1}
                ):Play()
            elseif object:IsA("Frame") and object:GetAttribute("DoNotFade") ~= true then
                TweenService:Create(
                    object,
                    TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {BackgroundTransparency = 1}
                ):Play()
            end
        end
        
        -- Also fade out the base UI if it's a GuiObject
        if ui:IsA("GuiObject") and ui:GetAttribute("DoNotFade") ~= true then
            if ui:IsA("TextLabel") or ui:IsA("TextButton") or ui:IsA("TextBox") then
                TweenService:Create(
                    ui,
                    TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {TextTransparency = 1}
                ):Play()
            end
            if ui:IsA("ImageLabel") or ui:IsA("ImageButton") then
                TweenService:Create(
                    ui,
                    TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {ImageTransparency = 1}
                ):Play()
            end
            
            TweenService:Create(
                ui,
                TweenInfo.new(uiDef.transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {BackgroundTransparency = 1}
            ):Play()
        end
    end
    
    -- Complete transition after duration
    task.delay(uiDef.transitionDuration, function()
        ui.Visible = false
        
        -- Remove from active UIs
        activeUIs[id] = nil
        transitioningUIs[id] = nil
        
        -- Check if we can remove the modal blocker
        if activeUI.isModal then
            local anyModalActive = false
            for _, otherUI in pairs(activeUIs) do
                if otherUI.isModal then
                    anyModalActive = true
                    break
                end
            end
            
            if not anyModalActive then
                removeBlockingOverlay()
            end
        end
        
        -- Call the after close callback if defined
        if uiDef.onAfterClose and typeof(uiDef.onAfterClose) == "function" then
            uiDef.onAfterClose(ui)
        end
        
        if debugMode then
            print("Closed UI: " .. id)
        end
    end)
    
    return true
end

-- Close all active UIs with specified exceptions
function closeAllUIs(exceptIds, skipTransition)
    local closedCount = 0
    
    for id, _ in pairs(activeUIs) do
        if not exceptIds[id] then
            if closeUI(id, skipTransition) then
                closedCount = closedCount + 1
            end
        end
    end
    
    return closedCount
end

-- Handle conflicts between UIs based on priority
function handleUIConflicts(newUIId, newUIPriority)
    local uiDef = registeredUIs[newUIId]
    if not uiDef then return end
    
    -- System priority UIs don't cause conflicts and aren't affected by conflicts
    if uiDef.isSystem or newUIPriority == priorityLevels.System then
        return
    end
    
    -- Modal UIs should close lower priority UIs
    if uiDef.isModal or newUIPriority == priorityLevels.Modal then
        for activeId, activeUI in pairs(activeUIs) do
            local activeDef = registeredUIs[activeUI.id]
            
            -- Skip system UIs
            if activeDef and not activeDef.isSystem and activeUI.priority < newUIPriority then
                closeUI(activeId, true) -- Skip transition for cleaner UI switching
            end
        end
    end
end

-- Create a blocking overlay for modal dialogs
function createBlockingOverlay()
    if blockingOverlay then
        blockingOverlay.Enabled = true
    end
end

-- Remove the blocking overlay
function removeBlockingOverlay()
    if blockingOverlay then
        blockingOverlay.Enabled = false
    end
end

-- Initialize the module
UIRegistry:initialize()

return UIRegistry