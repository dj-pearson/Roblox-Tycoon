--!strict
--[[
    RebirthUIComponent.luau
    
    Unified Rebirth UI component for the gym tycoon game.
    
    Author: Updated May 1, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Module and state variables
local RebirthUIComponent = {}
local rebirthGui = nil
local confirmationVisible = false
local pendingRebirth = false
local playerData = nil
local uiInitialized = false
local lastUpdateTime = 0

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if not success then
        warn("Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
        return nil
    end
    
    return result
end

-- Find paths to important folders
local srcFolder = ReplicatedStorage:FindFirstChild("src") 
if not srcFolder then
    error("Source folder not found")
    return
end

local sharedFolder = srcFolder:FindFirstChild("shared")
if not sharedFolder then
    error("Shared folder not found")
    return
end

local clientFolder = srcFolder:FindFirstChild("client")
local clientUIFolder = clientFolder and clientFolder:FindFirstChild("UI")
local uiCoreFolder = clientUIFolder and clientUIFolder:FindFirstChild("Core")

-- Required modules
local ButtonFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("ButtonFactory"))
local UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))
local UIManager = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIManager"))
local UIRegistry = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIRegistry"))

-- Find rebirth remote
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local rebirthEvent = remotesFolder and remotesFolder:FindFirstChild("RebirthRemote")

-- Configuration
local CONFIG = {
    colors = {
        background = Color3.fromRGB(30, 30, 30),
        headerBg = Color3.fromRGB(50, 50, 50),
        text = Color3.fromRGB(255, 255, 255),
        textDim = Color3.fromRGB(200, 200, 200),
        accent = Color3.fromRGB(0, 162, 255),
        positive = Color3.fromRGB(0, 180, 0),
        negative = Color3.fromRGB(255, 50, 50),
        buttonPrimary = Color3.fromRGB(0, 120, 215),
        buttonSecondary = Color3.fromRGB(60, 60, 60),
        buttonNegative = Color3.fromRGB(180, 0, 0)
    },
    minimumRebirthLevel = 10,
    minimumCash = 50000,
    refreshInterval = 5,
    animationDuration = 0.3
}

-- Format currency with $ sign and commas
local function formatCurrency(amount)
    if not amount then return "$0" end
    
    local formatted = tostring(math.floor(amount))
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    
    return "$" .. formatted
end

-- Show rebirth effects
local function showRebirthEffects(callback)
    -- Create full screen effect
    local effectFrame = Instance.new("Frame")
    effectFrame.Name = "RebirthEffect"
    effectFrame.Size = UDim2.new(1, 0, 1, 0)
    effectFrame.BackgroundColor3 = CONFIG.colors.accent
    effectFrame.BackgroundTransparency = 1
    effectFrame.ZIndex = 100
    effectFrame.Parent = PlayerGui
    
    -- Create flash effect
    local flashTween = TweenService:Create(
        effectFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0 }
    )
    flashTween:Play()
    
    -- Add text
    local rebirthText = Instance.new("TextLabel")
    rebirthText.Name = "RebirthText"
    rebirthText.Size = UDim2.new(1, 0, 1, 0)
    rebirthText.BackgroundTransparency = 1
    rebirthText.Text = "REBORN!"
    rebirthText.TextColor3 = Color3.new(1, 1, 1)
    rebirthText.TextTransparency = 1
    rebirthText.Font = Enum.Font.GothamBold
    rebirthText.TextSize = 80
    rebirthText.ZIndex = 101
    rebirthText.Parent = effectFrame
    
    -- Fade in text
    local textInTween = TweenService:Create(
        rebirthText,
        TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, 0.5),
        { TextTransparency = 0 }
    )
    textInTween:Play()
    
    -- Fade out effect after delay
    task.delay(2.5, function()
        local fadeTween = TweenService:Create(
            effectFrame,
            TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 }
        )
        fadeTween:Play()
        
        local textOutTween = TweenService:Create(
            rebirthText,
            TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
            { TextTransparency = 1 }
        )
        textOutTween:Play()
        
        -- Remove effect and call callback
        task.delay(1, function()
            effectFrame:Destroy()
            if callback then
                callback()
            end
        end)
    end)
end

-- Perform rebirth
local function performRebirth()
    if pendingRebirth then
        return
    end
    
    pendingRebirth = true
    
    -- Call server to perform rebirth
    local success, result = pcall(function()
        return rebirthEvent:InvokeServer()
    end)
    
    if success and result then
        -- Show rebirth effects
        showRebirthEffects(function()
            -- Close the UI
            RebirthUIComponent:hide()
            
            -- Reset pending flag
            pendingRebirth = false
        end)
    else
        -- Show error
        local errorLabel = rebirthGui.MainFrame.StatusLabel
        errorLabel.Text = "Rebirth failed: " .. tostring(result or "Unknown error")
        errorLabel.TextColor3 = CONFIG.colors.negative
        
        -- Reset pending flag
        pendingRebirth = false
    end
end

-- Check if player can rebirth
local function canRebirth()
    if not playerData then
        return false, "Player data not available"
    end
    
    local gymLevel = playerData.gymLevel or 0
    local cash = playerData.cash or 0
    
    if gymLevel < CONFIG.minimumRebirthLevel then
        return false, string.format("Gym must be level %d or higher", CONFIG.minimumRebirthLevel)
    end
    
    if cash < CONFIG.minimumCash then
        return false, string.format("You need %s", formatCurrency(CONFIG.minimumCash))
    end
    
    return true, "Ready to rebirth!"
end

-- Create confirmation dialog
local function createConfirmationDialog()
    if confirmationVisible then
        return
    end
    
    confirmationVisible = true
    
    -- Create dialog frame
    local dialogFrame = Instance.new("Frame")
    dialogFrame.Name = "ConfirmationDialog"
    dialogFrame.Size = UDim2.new(0, 400, 0, 250)
    dialogFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
    dialogFrame.BackgroundColor3 = CONFIG.colors.background
    dialogFrame.BorderSizePixel = 0
    dialogFrame.Parent = rebirthGui.MainFrame
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = dialogFrame
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = CONFIG.colors.headerBg
    title.Text = "Confirm Rebirth"
    title.TextColor3 = CONFIG.colors.text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.Parent = dialogFrame
    
    -- Add corner radius to title
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    -- Create confirmation message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Size = UDim2.new(1, -40, 0, 100)
    message.Position = UDim2.new(0, 20, 0, 60)
    message.BackgroundTransparency = 1
    message.Text = "Are you sure you want to rebirth? This will reset your gym and progress, but you will gain permanent bonuses based on your current level."
    message.TextColor3 = CONFIG.colors.text
    message.Font = Enum.Font.Gotham
    message.TextSize = 16
    message.TextWrapped = true
    message.TextXAlignment = Enum.TextXAlignment.Center
    message.TextYAlignment = Enum.TextYAlignment.Center
    message.Parent = dialogFrame
    
    -- Store buttons in dialog's references
    dialogFrame.ConfirmButton = ButtonFactory:createPrimaryButton({
        text = "Confirm",
        backgroundColor = CONFIG.colors.buttonPrimary,
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(0.25, -75, 1, -60),
        parent = dialogFrame,
        callback = function()
            performRebirth()
            confirmationVisible = false
            dialogFrame:Destroy()
        end
    })
    
    dialogFrame.CancelButton = ButtonFactory:createButton({
        text = "Cancel",
        backgroundColor = CONFIG.colors.buttonSecondary,
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(0.75, -75, 1, -60),
        parent = dialogFrame,
        callback = function()
            confirmationVisible = false
            dialogFrame:Destroy()
        end
    })
    
    -- Animate dialog appearance
    dialogFrame.Size = UDim2.new(0, 0, 0, 0)
    dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local targetSize = UDim2.new(0, 400, 0, 250)
    local targetPosition = UDim2.new(0.5, -200, 0.5, -125)
    
    -- Create and play tween
    local sizeTween = TweenService:Create(dialogFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = targetSize,
        Position = targetPosition
    })
    
    sizeTween:Play()
    
    return dialogFrame
end

-- Create the main rebirth UI
local function createRebirthUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RebirthUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.Parent = PlayerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    mainFrame.BackgroundColor3 = CONFIG.colors.background
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- Add corner radius to main frame
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame
    
    -- Create header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = CONFIG.colors.headerBg
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    -- Add corner radius to header
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header
    
    -- Add header title
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Name = "Title"
    headerTitle.Size = UDim2.new(1, 0, 1, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Gym Rebirth"
    headerTitle.TextColor3 = CONFIG.colors.text
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextSize = 28
    headerTitle.Parent = header
    
    -- Add close button using ButtonFactory
    mainFrame.CloseButton = ButtonFactory:createIconButton({
        icon = "✕",
        size = UDim2.new(0, 40, 0, 40),
        position = UDim2.new(1, -50, 0, 10),
        backgroundColor = CONFIG.colors.buttonNegative,
        cornerRadius = 8,
        parent = header,
        callback = function()
            RebirthUIComponent:hide()
        end
    })
    
    -- Create content container
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -40, 1, -120)
    contentFrame.Position = UDim2.new(0, 20, 0, 80)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Create description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, 0, 0, 60)
    description.Position = UDim2.new(0, 0, 0, 0)
    description.BackgroundTransparency = 1
    description.Text = "Rebirthing resets your gym but grants permanent bonuses for your next playthroughs."
    description.TextColor3 = CONFIG.colors.text
    description.Font = Enum.Font.Gotham
    description.TextSize = 16
    description.TextWrapped = true
    description.Parent = contentFrame
    
    -- Add status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 1, -65)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ready to rebirth!"
    statusLabel.TextColor3 = CONFIG.colors.positive
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 18
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.Parent = mainFrame
    
    -- Add rebirth button using ButtonFactory
    mainFrame.RebirthButton = ButtonFactory:createPrimaryButton({
        text = "Rebirth Now",
        backgroundColor = CONFIG.colors.buttonPrimary,
        size = UDim2.new(0, 200, 0, 50),
        position = UDim2.new(0.5, -100, 1, -60),
        parent = mainFrame,
        callback = function()
            local canDoRebirth, reason = canRebirth()
            
            if canDoRebirth then
                createConfirmationDialog()
            else
                statusLabel.Text = reason
                statusLabel.TextColor3 = CONFIG.colors.negative
                
                local originalPosition = mainFrame.RebirthButton.Position
                for i = 1, 5 do
                    mainFrame.RebirthButton.Position = originalPosition + UDim2.new(0, (i % 2 == 0) and 5 or -5, 0, 0)
                    task.wait(0.05)
                end
                mainFrame.RebirthButton.Position = originalPosition
            end
        end
    })
    
    return screenGui
end

-- Update the UI with player data
function RebirthUIComponent:updateUI()
    if not rebirthGui or not rebirthGui.Parent then return end
    
    local success, data = pcall(function()
        return rebirthEvent:InvokeServer("getRebirthData")
    end)
    
    if not success or not data then
        warn("Failed to get rebirth data:", data)
        return
    end
    
    playerData = data
    
    -- Update status
    local canDoRebirth, reason = canRebirth()
    local statusLabel = rebirthGui.MainFrame.StatusLabel
    
    if canDoRebirth then
        statusLabel.Text = "Ready to rebirth!"
        statusLabel.TextColor3 = CONFIG.colors.positive
    else
        statusLabel.Text = reason
        statusLabel.TextColor3 = CONFIG.colors.negative
    end
    
    lastUpdateTime = os.time()
end

-- Initialize the component
function RebirthUIComponent:initialize()
    if uiInitialized then
        return self
    end
    
    rebirthGui = createRebirthUI()
    
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent("RebirthUI", self, "1.0.0")
    end
    
    self.refreshConnection = RunService.Heartbeat:Connect(function()
        if os.time() - lastUpdateTime >= CONFIG.refreshInterval then
            self:updateUI()
        end
    end)
    
    uiInitialized = true
    return self
end

-- Show the UI
function RebirthUIComponent:show()
    if not rebirthGui then
        self:initialize()
    end
    
    self:updateUI()
    
    local mainFrame = rebirthGui.MainFrame
    mainFrame.Size = UDim2.new(0, 500, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -250, 0.4, -175)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Visible = true
    
    local positionTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -250, 0.5, -175) }
    )
    
    local transparencyTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0 }
    )
    
    positionTween:Play()
    transparencyTween:Play()
    
    return true
end

-- Hide the UI
function RebirthUIComponent:hide()
    if not rebirthGui or not rebirthGui.MainFrame then
        return false
    end
    
    local mainFrame = rebirthGui.MainFrame
    
    local positionTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, -250, 0.4, -175) }
    )
    
    local transparencyTween = TweenService:Create(
        mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )
    
    transparencyTween.Completed:Connect(function()
        mainFrame.Visible = false
    end)
    
    positionTween:Play()
    transparencyTween:Play()
    
    return true
end

-- Destroy the component
function RebirthUIComponent:destroy()
    if self.refreshConnection then
        self.refreshConnection:Disconnect()
        self.refreshConnection = nil
    end
    
    if rebirthGui then
        rebirthGui:Destroy()
        rebirthGui = nil
    end
    
    return true
end

-- Initialize on module load
RebirthUIComponent:initialize()

return RebirthUIComponent
