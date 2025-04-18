-- TycoonClient.luau
-- Client-side system for interacting with player tycoons
-- Place in StarterPlayer/StarterPlayerScripts/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Import client-side systems
local ClientRegistry = require(script.Parent.ClientRegistry)
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
local UIManager = ClientRegistry.getSystem("UIManager")
local NotificationSystem = ClientRegistry.getSystem("NotificationSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    raycastDistance = 100,            -- Max distance for interaction raycasts
    interactionCheckFrequency = 0.1,  -- How often to check for new interactable objects
    interactionKeyCode = Enum.KeyCode.E,  -- Default interaction key
    interactionGamepadButton = Enum.KeyCode.ButtonX,  -- Default gamepad interaction button
    interactionRange = 10,            -- Distance to interact with objects
    highlightColor = Color3.fromRGB(0, 200, 255),  -- Color for highlighting interactable objects
    textColor = Color3.fromRGB(255, 255, 255),     -- Color for interaction prompts
    hitboxExpansion = 0.5,            -- Expand hitboxes by this amount
    mobileButtonSize = UDim2.new(0, 80, 0, 80),     -- Size of mobile interaction button
    mobileButtonPosition = UDim2.new(1, -100, 1, -100)  -- Position of mobile interaction button
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[TycoonClient]", ...)
    end
end

-- The TycoonClient system
local TycoonClient = {
    -- Internal state
    playerTycoon = nil,               -- Reference to player's tycoon
    interactableObjects = {},         -- Interactable objects in the tycoon
    currentInteractable = nil,        -- Currently focused interactable
    interactionPrompt = nil,          -- UI element for showing interaction prompts
    mobileInteractionButton = nil,    -- Mobile interaction button
    interactionConnections = {},      -- Event connections for interactions
    isInteractionEnabled = true,      -- Whether interaction system is enabled
    heartbeatConnection = nil,        -- Connection for heartbeat updates
    raycastParams = nil               -- Parameters for raycasting
}

-- Initialize the client
function TycoonClient:initialize()
    log("Initializing TycoonClient...")
    
    -- Set up raycast parameters
    self.raycastParams = RaycastParams.new()
    self.raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    self.raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    -- Set up event handlers
    self:setupEventHandlers()
    
    -- Create interaction UI
    self:createInteractionUI()
    
    -- Set up input connections
    self:setupInputHandlers()
    
    -- Start interaction checking loop
    self:startInteractionChecking()
    
    -- Handle if the player already has a tycoon
    task.spawn(function()
        -- Wait a bit for connections and data to load
        task.wait(1)
        
        -- Request tycoon information
        ClientEventBridge.fireServerEvent("GetPlayerTycoon")
    end)
    
    log("TycoonClient initialized")
    return true
end

-- Set up event handlers
function TycoonClient:setupEventHandlers()
    -- Handle receiving player tycoon reference
    ClientEventBridge.connectEvent("PlayerTycoonReceived", function(tycoonModel)
        self:setPlayerTycoon(tycoonModel)
    end)
    
    -- Handle equipment added to tycoon
    ClientEventBridge.connectEvent("EquipmentAdded", function(equipmentModel)
        self:refreshInteractables()
    end)
    
    -- Handle tycoon updated
    ClientEventBridge.connectEvent("TycoonUpdated", function()
        self:refreshInteractables()
    end)
    
    -- Handle character respawn
    LocalPlayer.CharacterAdded:Connect(function(character)
        -- Update filter for raycast
        if self.raycastParams then
            self.raycastParams.FilterDescendantsInstances = {character}
        end
        
        -- Wait for character to be fully loaded
        task.wait(1)
        
        -- Re-initialize interaction system
        self:refreshInteractables()
    end)
    
    log("Event handlers set up")
end

-- Create interaction UI elements
function TycoonClient:createInteractionUI()
    -- Create the interaction prompt
    local prompt = Instance.new("BillboardGui")
    prompt.Name = "InteractionPrompt"
    prompt.Size = UDim2.new(0, 200, 0, 50)
    prompt.StudsOffset = Vector3.new(0, 2, 0)
    prompt.AlwaysOnTop = true
    prompt.Enabled = false
    prompt.Adornee = nil
    
    -- Background frame
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    bg.Parent = prompt
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = bg
    
    -- Add text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ActionText"
    textLabel.Size = UDim2.new(1, -20, 1, -10)
    textLabel.Position = UDim2.new(0, 10, 0, 5)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = CONFIG.textColor
    textLabel.TextSize = 16
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.Text = "Press E to Interact"
    textLabel.TextWrapped = true
    textLabel.Parent = prompt
    
    -- Store reference
    self.interactionPrompt = prompt
    
    -- Create mobile interaction button if on mobile/tablet
    if UserInputService.TouchEnabled then
        self:createMobileInteractionButton()
    end
    
    log("Interaction UI created")
end

-- Create mobile interaction button
function TycoonClient:createMobileInteractionButton()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MobileInteractionGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer.PlayerGui
    
    -- Create the button
    local button = Instance.new("ImageButton")
    button.Name = "InteractButton"
    button.Size = CONFIG.mobileButtonSize
    button.Position = CONFIG.mobileButtonPosition
    button.AnchorPoint = Vector2.new(1, 1)
    button.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    button.BackgroundTransparency = 0.2
    button.Image = "rbxassetid://6022668885" -- Hand icon
    button.ImageColor3 = Color3.fromRGB(255, 255, 255)
    button.ImageTransparency = 0
    button.Visible = false -- Only show when there's something to interact with
    button.Parent = screenGui
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) -- Make it circular
    corner.Parent = button
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 1, 5)
    label.AnchorPoint = Vector2.new(0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = CONFIG.textColor
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Text = "Interact"
    label.Parent = button
    
    -- Connect button
    button.MouseButton1Click:Connect(function()
        self:interactWithCurrent()
    end)
    
    -- Store reference
    self.mobileInteractionButton = button
    
    log("Mobile interaction button created")
end

-- Set up input handlers for interaction
function TycoonClient:setupInputHandlers()
    -- Handle keyboard input
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        -- Skip if UI is handling this input
        if gameProcessedEvent then return end
        
        -- Check for interaction key
        if input.KeyCode == CONFIG.interactionKeyCode or 
           input.KeyCode == CONFIG.interactionGamepadButton then
            self:interactWithCurrent()
        end
    end)
    
    log("Input handlers set up")
end

-- Start the interaction checking loop
function TycoonClient:startInteractionChecking()
    -- Clear any existing connection
    if self.heartbeatConnection then
        self.heartbeatConnection:Disconnect()
        self.heartbeatConnection = nil
    end
    
    -- Create timer for checking less frequently
    local lastCheckTime = 0
    
    -- Connect to RunService.Heartbeat
    self.heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        -- Check if it's time to update
        if tick() - lastCheckTime < CONFIG.interactionCheckFrequency then
            return
        end
        
        -- Update timer
        lastCheckTime = tick()
        
        -- Check for interactables if player has a character
        if LocalPlayer.Character and self.isInteractionEnabled then
            self:checkForInteractables()
        end
    end)
    
    log("Interaction checking started")
end

-- Set the player's tycoon
function TycoonClient:setPlayerTycoon(tycoonModel)
    if not tycoonModel then 
        log("No tycoon model provided")
        return 
    end
    
    log("Setting player tycoon: " .. tycoonModel:GetFullName())
    self.playerTycoon = tycoonModel
    
    -- Initial scan for interactables
    self:refreshInteractables()
end

-- Refresh all interactable objects in the tycoon
function TycoonClient:refreshInteractables()
    -- Clear existing interactables
    self.interactableObjects = {}
    
    -- Only proceed if player has a tycoon
    if not self.playerTycoon then 
        log("No player tycoon to refresh interactables")
        return 
    end
    
    log("Refreshing interactable objects")
    
    -- Find all interactable objects in the tycoon
    for _, object in pairs(self.playerTycoon:GetDescendants()) do
        -- Check if the object is interactable
        if self:isObjectInteractable(object) then
            table.insert(self.interactableObjects, object)
        end
    end
    
    log("Found " .. #self.interactableObjects .. " interactable objects")
end

-- Check if an object is interactable
function TycoonClient:isObjectInteractable(object)
    -- Must be a BasePart or Model to be interactable
    if not (object:IsA("BasePart") or object:IsA("Model")) then
        return false
    end
    
    -- Check for interaction attributes
    if object:GetAttribute("Interactable") then
        return true
    end
    
    -- Check for common interactable names
    local name = object.Name:lower()
    if name:find("button") or 
       name:find("lever") or 
       name:find("machine") or 
       name:find("collect") or
       name:find("upgrade") then
        return true
    end
    
    -- Check if object has an interaction script as a child
    for _, child in pairs(object:GetChildren()) do
        if child:IsA("Script") or child:IsA("LocalScript") then
            if child.Name:find("Interaction") or 
               child.Name:find("Click") or 
               child.Name:find("Button") then
                return true
            end
        end
    end
    
    -- Not interactable
    return false
end

-- Check for nearby interactable objects
function TycoonClient:checkForInteractables()
    -- Need character and interactable objects to continue
    if not LocalPlayer.Character or 
       not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or 
       #self.interactableObjects == 0 then
        self:clearCurrentInteractable()
        return
    end
    
    -- Get character position
    local character = LocalPlayer.Character
    local rootPart = character.HumanoidRootPart
    local cameraPosition = workspace.CurrentCamera.CFrame.Position
    local lookDirection = workspace.CurrentCamera.CFrame.LookVector
    
    -- Try camera raycast first to see if player is looking at an interactable
    local raycastResult = workspace:Raycast(
        cameraPosition, 
        lookDirection * CONFIG.raycastDistance, 
        self.raycastParams
    )
    
    -- If we hit something with raycast
    if raycastResult and raycastResult.Instance then
        -- Check if the hit instance or its ancestors are interactable
        local hitInstance = raycastResult.Instance
        local foundInteractable = nil
        
        -- Check hit instance and its ancestors
        while hitInstance and hitInstance ~= workspace and not foundInteractable do
            -- Check if this is one of our interactable objects
            for _, interactable in ipairs(self.interactableObjects) do
                if hitInstance == interactable or (hitInstance:IsDescendantOf(interactable) and interactable:IsA("Model")) then
                    foundInteractable = interactable
                    break
                end
            end
            
            -- Move up to parent
            hitInstance = hitInstance.Parent
        end
        
        -- If we found an interactable, set it as current
        if foundInteractable then
            self:setCurrentInteractable(foundInteractable)
            return
        end
    end
    
    -- If raycast didn't find anything, fall back to proximity check
    local closestInteractable = nil
    local closestDistance = CONFIG.interactionRange
    
    for _, interactable in ipairs(self.interactableObjects) do
        -- Get interactable position
        local interactablePosition
        if interactable:IsA("Model") and interactable.PrimaryPart then
            interactablePosition = interactable.PrimaryPart.Position
        elseif interactable:IsA("BasePart") then
            interactablePosition = interactable.Position
        else
            continue -- Skip if no position can be determined
        end
        
        -- Calculate distance
        local distance = (rootPart.Position - interactablePosition).Magnitude
        
        -- Update closest if this one is closer
        if distance < closestDistance then
            closestInteractable = interactable
            closestDistance = distance
        end
    end
    
    -- Update current interactable
    if closestInteractable then
        self:setCurrentInteractable(closestInteractable)
    else
        self:clearCurrentInteractable()
    end
end

-- Set the current interactable object
function TycoonClient:setCurrentInteractable(interactable)
    -- Skip if it's the same one
    if self.currentInteractable == interactable then
        return
    end
    
    -- Clear any previous interactable
    self:clearCurrentInteractable()
    
    -- Set new interactable
    self.currentInteractable = interactable
    
    -- Get interaction text
    local actionText = interactable:GetAttribute("InteractionText")
    if not actionText then
        -- Default text based on object name
        local objectName = interactable.Name
        
        -- Remove common prefixes/suffixes
        objectName = objectName:gsub("Button", ""):gsub("Interact", ""):gsub("Machine", "")
        objectName = objectName:gsub("_", " "):gsub("%-", " ")
        objectName = objectName:trim()
        
        -- Default interaction text
        if objectName ~= "" then
            actionText = "Interact with " .. objectName
        else
            actionText = "Interact"
        end
    end
    
    -- Set up prompt
    if self.interactionPrompt then
        -- Show the interaction prompt
        self.interactionPrompt.Adornee = interactable:IsA("Model") and interactable.PrimaryPart or interactable
        self.interactionPrompt.Enabled = true
        
        -- Update text
        local textLabel = self.interactionPrompt:FindFirstChild("ActionText")
        if textLabel then
            -- Add key hint to text
            if UserInputService.TouchEnabled then
                textLabel.Text = actionText
            else
                textLabel.Text = "Press E to " .. actionText
            end
        end
        
        -- Set parent
        self.interactionPrompt.Parent = LocalPlayer.PlayerGui
    end
    
    -- Show mobile interaction button if on mobile
    if UserInputService.TouchEnabled and self.mobileInteractionButton then
        self.mobileInteractionButton.Visible = true
    end
end

-- Clear the current interactable
function TycoonClient:clearCurrentInteractable()
    -- Clear reference
    self.currentInteractable = nil
    
    -- Hide prompt
    if self.interactionPrompt then
        self.interactionPrompt.Enabled = false
        self.interactionPrompt.Adornee = nil
    end
    
    -- Hide mobile button
    if self.mobileInteractionButton then
        self.mobileInteractionButton.Visible = false
    end
end

-- Interact with the current interactable
function TycoonClient:interactWithCurrent()
    if not self.currentInteractable then 
        return 
    end
    
    log("Interacting with: " .. self.currentInteractable.Name)
    
    -- Check for different types of interaction handlers
    local handled = false
    
    -- Check for interaction function in attributes
    local interactionHandler = self.currentInteractable:GetAttribute("InteractionHandler")
    if interactionHandler and typeof(interactionHandler) == "string" then
        -- Fire server event with the handler name
        ClientEventBridge.fireServerEvent("TycoonObjectInteraction", self.currentInteractable, interactionHandler)
        handled = true
    end
    
    -- Check for specific interactions based on object name/type
    if not handled then
        local name = self.currentInteractable.Name:lower()
        
        -- Collection of revenue from cash registers, etc.
        if name:find("collect") or name:find("cash") or name:find("register") then
            ClientEventBridge.fireServerEvent("CollectRevenue", self.currentInteractable)
            handled = true
        
        -- Upgrade interactions
        elseif name:find("upgrade") then
            ClientEventBridge.fireServerEvent("UpgradeEquipment", self.currentInteractable)
            handled = true
        end
        
        -- Generic interaction as fallback
        if not handled then
            ClientEventBridge.fireServerEvent("TycoonObjectInteraction", self.currentInteractable)
        end
    end
    
    -- Provide feedback that interaction was triggered
    self:showInteractionFeedback()
end

-- Show feedback that an interaction was triggered
function TycoonClient:showInteractionFeedback()
    -- Create a small animation on the current interactable
    if not self.currentInteractable then return end
    
    -- Create visual feedback (highlight effect)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = CONFIG.highlightColor
    highlight.OutlineColor = CONFIG.highlightColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Adornee = self.currentInteractable
    highlight.Parent = self.currentInteractable
    
    -- Remove after a short delay
    task.delay(0.3, function()
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end)
    
    -- Play sound effect
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://6042583703" -- Generic click sound
    sound.Volume = 0.5
    sound.Parent = LocalPlayer.PlayerGui
    sound:Play()
    
    -- Clean up sound after it finishes
    task.delay(1, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
end

-- Public API
local PublicAPI = {
    initialize = function()
        return TycoonClient:initialize()
    end,
    
    refreshInteractables = function()
        return TycoonClient:refreshInteractables()
    end,
    
    enableInteractions = function(enabled)
        TycoonClient.isInteractionEnabled = enabled == nil and true or enabled
        return TycoonClient.isInteractionEnabled
    end
}

-- Register with ClientRegistry
return ClientRegistry.registerSystem("TycoonClient", PublicAPI, {"ClientEventBridge", "UIManager", "NotificationSystem"})