--!strict
--[[
    RebirthUIComponent.luau
    
    Unified Rebirth UI component for the gym tycoon game.
    Consolidates functionality from multiple rebirth UI scripts into a single coherent system.
    
    Features:
    - Rebirth progression display
    - Benefits visualization
    - Requirements tracking
    - Confirmation dialog
    - Post-rebirth effects
    
    Author: Updated April 26, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        warn("Invalid module script provided to requireSafely")
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
local UIRegistry = requireSafely(uiCoreFolder and uiCoreFolder:FindFirstChild("UIRegistry"))
local ButtonFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("ButtonFactory"))

-- Module and state variables
local RebirthUIComponent = {}
local rebirthGui = nil
local playerData = nil
local confirmationVisible = false
local pendingRebirth = false
local rebirthLevel = 0

-- Configuration
local CONFIG = {
    minimumRebirthLevel = 10, -- Minimum gym level required to rebirth
    minimumCash = 100000, -- Minimum cash required to rebirth
    baseBonusMultiplier = 0.1, -- 10% bonus per rebirth level
    calculateMultiplier = function(level)
        return 1 + (level * 0.1)
    end,
    colors = {
        background = Color3.fromRGB(30, 30, 35),
        headerBg = Color3.fromRGB(40, 40, 45),
        text = Color3.fromRGB(230, 230, 230),
        textDim = Color3.fromRGB(150, 150, 150),
        accent = Color3.fromRGB(114, 137, 218),
        positive = Color3.fromRGB(46, 204, 113),
        negative = Color3.fromRGB(231, 76, 60),
        warning = Color3.fromRGB(230, 126, 34),
        buttonPrimary = Color3.fromRGB(114, 137, 218),
        buttonSecondary = Color3.fromRGB(50, 53, 59),
        buttonNegative = Color3.fromRGB(231, 76, 60)
    }
}

-- Remote events
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local getPlayerDataEvent = remoteEvents:FindFirstChild("GetPlayerData") or Instance.new("RemoteFunction")
local rebirthEvent = remoteEvents:FindFirstChild("RequestRebirth") or Instance.new("RemoteFunction")

if not getPlayerDataEvent.Parent then
    getPlayerDataEvent.Name = "GetPlayerData"
    getPlayerDataEvent.Parent = remoteEvents
end

if not rebirthEvent.Parent then
    rebirthEvent.Name = "RequestRebirth"
    rebirthEvent.Parent = remoteEvents
end

--[[ Helper Functions ]]--

-- Format currency
local function formatCurrency(amount)
    if amount >= 1000000000 then
        return string.format("$%.1fB", amount / 1000000000)
    elseif amount >= 1000000 then
        return string.format("$%.1fM", amount / 1000000)
    elseif amount >= 1000 then
        return string.format("$%.1fK", amount / 1000)
    else
        return string.format("$%d", amount)
    end
end

-- Format percentage
local function formatPercentage(value)
    return string.format("+%d%%", value * 100)
end

-- Calculate rebirth bonuses
local function calculateRebirthBonuses(level)
    local nextLevel = level + 1
    local currentMultiplier = CONFIG.calculateMultiplier(level)
    local nextMultiplier = CONFIG.calculateMultiplier(nextLevel)
    
    return {
        current = {
            revenueMultiplier = currentMultiplier,
            memberAttraction = currentMultiplier,
            equipmentEfficiency = currentMultiplier
        },
        next = {
            revenueMultiplier = nextMultiplier,
            memberAttraction = nextMultiplier,
            equipmentEfficiency = nextMultiplier
        }
    }
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
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = CONFIG.colors.headerBg
    title.BorderSizePixel = 0
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
    
    -- Create buttons using ButtonFactory
    local confirmButton = ButtonFactory:createPrimaryButton({
        text = "Confirm",
        backgroundColor = CONFIG.colors.buttonPrimary,
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(0.25, -75, 1, -60),
        parent = dialogFrame,
        callback = function()
            -- Handle rebirth confirmation
            performRebirth()
            confirmationVisible = false
            dialogFrame:Destroy()
        end
    })
    
    local cancelButton = ButtonFactory:createButton({
        text = "Cancel",
        backgroundColor = CONFIG.colors.buttonSecondary,
        size = UDim2.new(0, 150, 0, 40),
        position = UDim2.new(0.75, -75, 1, -60),
        parent = dialogFrame,
        callback = function()
            -- Close dialog
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
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local sizeTween = TweenService:Create(dialogFrame, tweenInfo, {
        Size = targetSize,
        Position = targetPosition
    })
    
    sizeTween:Play()
    
    return dialogFrame
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
    TweenService:Create(
        effectFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0 }
    ):Play()
    
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
    TweenService:Create(
        rebirthText,
        TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, 0.5),
        { TextTransparency = 0 }
    ):Play()
    
    -- Fade out effect after delay
    task.delay(2.5, function()
        TweenService:Create(
            effectFrame,
            TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 }
        ):Play()
        
        TweenService:Create(
            rebirthText,
            TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
            { TextTransparency = 1 }
        ):Play()
        
        -- Remove effect and call callback
        task.delay(1, function()
            effectFrame:Destroy()
            
            if callback then
                callback()
            end
        end)
    end)
end

-- Create rebirth UI
local function createRebirthUI()
    -- Check if UI already exists
    if rebirthGui then
        return rebirthGui
    end
    
    -- Create ScreenGui
    rebirthGui = Instance.new("ScreenGui")
    rebirthGui.Name = "RebirthUI"
    rebirthGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    rebirthGui.ResetOnSpawn = false
    rebirthGui.Parent = PlayerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundColor3 = CONFIG.colors.background
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = rebirthGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
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
    local closeButton = ButtonFactory:createIconButton({
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
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.Parent = contentFrame
    
    -- Create current stats section
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(0.5, -10, 0, 150)
    statsFrame.Position = UDim2.new(0, 0, 0, 70)
    statsFrame.BackgroundColor3 = CONFIG.colors.background:Lerp(Color3.new(1, 1, 1), 0.1)
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = contentFrame
    
    -- Add corner radius to stats frame
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsFrame
    
    -- Add stats title
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Name = "Title"
    statsTitle.Size = UDim2.new(1, 0, 0, 30)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "Current Stats"
    statsTitle.TextColor3 = CONFIG.colors.text
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.TextSize = 18
    statsTitle.Parent = statsFrame
    
    -- Add current gym level
    local gymLevelLabel = Instance.new("TextLabel")
    gymLevelLabel.Name = "GymLevelLabel"
    gymLevelLabel.Size = UDim2.new(0.5, 0, 0, 25)
    gymLevelLabel.Position = UDim2.new(0, 10, 0, 40)
    gymLevelLabel.BackgroundTransparency = 1
    gymLevelLabel.Text = "Gym Level:"
    gymLevelLabel.TextColor3 = CONFIG.colors.textDim
    gymLevelLabel.Font = Enum.Font.Gotham
    gymLevelLabel.TextSize = 16
    gymLevelLabel.TextXAlignment = Enum.TextXAlignment.Left
    gymLevelLabel.Parent = statsFrame
    
    local gymLevelValue = Instance.new("TextLabel")
    gymLevelValue.Name = "GymLevelValue"
    gymLevelValue.Size = UDim2.new(0.5, -20, 0, 25)
    gymLevelValue.Position = UDim2.new(0.5, 10, 0, 40)
    gymLevelValue.BackgroundTransparency = 1
    gymLevelValue.Text = "0"
    gymLevelValue.TextColor3 = CONFIG.colors.text
    gymLevelValue.Font = Enum.Font.GothamBold
    gymLevelValue.TextSize = 16
    gymLevelValue.TextXAlignment = Enum.TextXAlignment.Left
    gymLevelValue.Parent = statsFrame
    
    -- Add current cash
    local cashLabel = Instance.new("TextLabel")
    cashLabel.Name = "CashLabel"
    cashLabel.Size = UDim2.new(0.5, 0, 0, 25)
    cashLabel.Position = UDim2.new(0, 10, 0, 70)
    cashLabel.BackgroundTransparency = 1
    cashLabel.Text = "Cash:"
    cashLabel.TextColor3 = CONFIG.colors.textDim
    cashLabel.Font = Enum.Font.Gotham
    cashLabel.TextSize = 16
    cashLabel.TextXAlignment = Enum.TextXAlignment.Left
    cashLabel.Parent = statsFrame
    
    local cashValue = Instance.new("TextLabel")
    cashValue.Name = "CashValue"
    cashValue.Size = UDim2.new(0.5, -20, 0, 25)
    cashValue.Position = UDim2.new(0.5, 10, 0, 70)
    cashValue.BackgroundTransparency = 1
    cashValue.Text = "$0"
    cashValue.TextColor3 = CONFIG.colors.text
    cashValue.Font = Enum.Font.GothamBold
    cashValue.TextSize = 16
    cashValue.TextXAlignment = Enum.TextXAlignment.Left
    cashValue.Parent = statsFrame
    
    -- Add current rebirth level
    local rebirthLabel = Instance.new("TextLabel")
    rebirthLabel.Name = "RebirthLabel"
    rebirthLabel.Size = UDim2.new(0.5, 0, 0, 25)
    rebirthLabel.Position = UDim2.new(0, 10, 0, 100)
    rebirthLabel.BackgroundTransparency = 1
    rebirthLabel.Text = "Rebirth Level:"
    rebirthLabel.TextColor3 = CONFIG.colors.textDim
    rebirthLabel.Font = Enum.Font.Gotham
    rebirthLabel.TextSize = 16
    rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
    rebirthLabel.Parent = statsFrame
    
    local rebirthValue = Instance.new("TextLabel")
    rebirthValue.Name = "RebirthValue"
    rebirthValue.Size = UDim2.new(0.5, -20, 0, 25)
    rebirthValue.Position = UDim2.new(0.5, 10, 0, 100)
    rebirthValue.BackgroundTransparency = 1
    rebirthValue.Text = "0"
    rebirthValue.TextColor3 = CONFIG.colors.text
    rebirthValue.Font = Enum.Font.GothamBold
    rebirthValue.TextSize = 16
    rebirthValue.TextXAlignment = Enum.TextXAlignment.Left
    rebirthValue.Parent = statsFrame
    
    -- Create benefits section
    local benefitsFrame = Instance.new("Frame")
    benefitsFrame.Name = "BenefitsFrame"
    benefitsFrame.Size = UDim2.new(0.5, -10, 0, 150)
    benefitsFrame.Position = UDim2.new(0.5, 10, 0, 70)
    benefitsFrame.BackgroundColor3 = CONFIG.colors.background:Lerp(Color3.new(1, 1, 1), 0.1)
    benefitsFrame.BorderSizePixel = 0
    benefitsFrame.Parent = contentFrame
    
    -- Add corner radius to benefits frame
    local benefitsCorner = Instance.new("UICorner")
    benefitsCorner.CornerRadius = UDim.new(0, 8)
    benefitsCorner.Parent = benefitsFrame
    
    -- Add benefits title
    local benefitsTitle = Instance.new("TextLabel")
    benefitsTitle.Name = "Title"
    benefitsTitle.Size = UDim2.new(1, 0, 0, 30)
    benefitsTitle.BackgroundTransparency = 1
    benefitsTitle.Text = "Next Rebirth Benefits"
    benefitsTitle.TextColor3 = CONFIG.colors.text
    benefitsTitle.Font = Enum.Font.GothamBold
    benefitsTitle.TextSize = 18
    benefitsTitle.Parent = benefitsFrame
    
    -- Add revenue multiplier
    local revenueLabel = Instance.new("TextLabel")
    revenueLabel.Name = "RevenueLabel"
    revenueLabel.Size = UDim2.new(0.5, 0, 0, 25)
    revenueLabel.Position = UDim2.new(0, 10, 0, 40)
    revenueLabel.BackgroundTransparency = 1
    revenueLabel.Text = "Revenue:"
    revenueLabel.TextColor3 = CONFIG.colors.textDim
    revenueLabel.Font = Enum.Font.Gotham
    revenueLabel.TextSize = 16
    revenueLabel.TextXAlignment = Enum.TextXAlignment.Left
    revenueLabel.Parent = benefitsFrame
    
    local revenueValue = Instance.new("TextLabel")
    revenueValue.Name = "RevenueValue"
    revenueValue.Size = UDim2.new(0.5, -20, 0, 25)
    revenueValue.Position = UDim2.new(0.5, 10, 0, 40)
    revenueValue.BackgroundTransparency = 1
    revenueValue.Text = "+10%"
    revenueValue.TextColor3 = CONFIG.colors.positive
    revenueValue.Font = Enum.Font.GothamBold
    revenueValue.TextSize = 16
    revenueValue.TextXAlignment = Enum.TextXAlignment.Left
    revenueValue.Parent = benefitsFrame
    
    -- Add member attraction
    local attractionLabel = Instance.new("TextLabel")
    attractionLabel.Name = "AttractionLabel"
    attractionLabel.Size = UDim2.new(0.5, 0, 0, 25)
    attractionLabel.Position = UDim2.new(0, 10, 0, 70)
    attractionLabel.BackgroundTransparency = 1
    attractionLabel.Text = "Member Attraction:"
    attractionLabel.TextColor3 = CONFIG.colors.textDim
    attractionLabel.Font = Enum.Font.Gotham
    attractionLabel.TextSize = 16
    attractionLabel.TextXAlignment = Enum.TextXAlignment.Left
    attractionLabel.Parent = benefitsFrame
    
    local attractionValue = Instance.new("TextLabel")
    attractionValue.Name = "AttractionValue"
    attractionValue.Size = UDim2.new(0.5, -20, 0, 25)
    attractionValue.Position = UDim2.new(0.5, 10, 0, 70)
    attractionValue.BackgroundTransparency = 1
    attractionValue.Text = "+10%"
    attractionValue.TextColor3 = CONFIG.colors.positive
    attractionValue.Font = Enum.Font.GothamBold
    attractionValue.TextSize = 16
    attractionValue.TextXAlignment = Enum.TextXAlignment.Left
    attractionValue.Parent = benefitsFrame
    
    -- Add equipment efficiency
    local efficiencyLabel = Instance.new("TextLabel")
    efficiencyLabel.Name = "EfficiencyLabel"
    efficiencyLabel.Size = UDim2.new(0.5, 0, 0, 25)
    efficiencyLabel.Position = UDim2.new(0, 10, 0, 100)
    efficiencyLabel.BackgroundTransparency = 1
    efficiencyLabel.Text = "Equipment Efficiency:"
    efficiencyLabel.TextColor3 = CONFIG.colors.textDim
    efficiencyLabel.Font = Enum.Font.Gotham
    efficiencyLabel.TextSize = 16
    efficiencyLabel.TextXAlignment = Enum.TextXAlignment.Left
    efficiencyLabel.Parent = benefitsFrame
    
    local efficiencyValue = Instance.new("TextLabel")
    efficiencyValue.Name = "EfficiencyValue"
    efficiencyValue.Size = UDim2.new(0.5, -20, 0, 25)
    efficiencyValue.Position = UDim2.new(0.5, 10, 0, 100)
    efficiencyValue.BackgroundTransparency = 1
    efficiencyValue.Text = "+10%"
    efficiencyValue.TextColor3 = CONFIG.colors.positive
    efficiencyValue.Font = Enum.Font.GothamBold
    efficiencyValue.TextSize = 16
    efficiencyValue.TextXAlignment = Enum.TextXAlignment.Left
    efficiencyValue.Parent = benefitsFrame
    
    -- Create requirements section
    local requirementsLabel = Instance.new("TextLabel")
    requirementsLabel.Name = "RequirementsLabel"
    requirementsLabel.Size = UDim2.new(1, 0, 0, 30)
    requirementsLabel.Position = UDim2.new(0, 0, 0, 230)
    requirementsLabel.BackgroundTransparency = 1
    requirementsLabel.Text = "Requirements"
    requirementsLabel.TextColor3 = CONFIG.colors.text
    requirementsLabel.Font = Enum.Font.GothamBold
    requirementsLabel.TextSize = 18
    requirementsLabel.TextXAlignment = Enum.TextXAlignment.Left
    requirementsLabel.Parent = contentFrame
    
    -- Add level requirement
    local levelRequirement = Instance.new("TextLabel")
    levelRequirement.Name = "LevelRequirement"
    levelRequirement.Size = UDim2.new(1, 0, 0, 25)
    levelRequirement.Position = UDim2.new(0, 0, 0, 260)
    levelRequirement.BackgroundTransparency = 1
    levelRequirement.Text = "• Gym Level " .. CONFIG.minimumRebirthLevel .. " or higher"
    levelRequirement.TextColor3 = CONFIG.colors.textDim
    levelRequirement.Font = Enum.Font.Gotham
    levelRequirement.TextSize = 16
    levelRequirement.TextXAlignment = Enum.TextXAlignment.Left
    levelRequirement.Parent = contentFrame
    
    -- Add cash requirement
    local cashRequirement = Instance.new("TextLabel")
    cashRequirement.Name = "CashRequirement"
    cashRequirement.Size = UDim2.new(1, 0, 0, 25)
    cashRequirement.Position = UDim2.new(0, 0, 0, 285)
    cashRequirement.BackgroundTransparency = 1
    cashRequirement.Text = "• " .. formatCurrency(CONFIG.minimumCash) .. " cash"
    cashRequirement.TextColor3 = CONFIG.colors.textDim
    cashRequirement.Font = Enum.Font.Gotham
    cashRequirement.TextSize = 16
    cashRequirement.TextXAlignment = Enum.TextXAlignment.Left
    cashRequirement.Parent = contentFrame
    
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
    local rebirthButton = ButtonFactory:createPrimaryButton({
        text = "Rebirth Now",
        backgroundColor = CONFIG.colors.buttonPrimary,
        size = UDim2.new(0, 200, 0, 50),
        position = UDim2.new(0.5, -100, 1, -60),
        parent = mainFrame,
        callback = function()
            local canDoRebirth, reason = canRebirth()
            
            if canDoRebirth then
                -- Show confirmation dialog
                createConfirmationDialog()
            else
                -- Update status label
                statusLabel.Text = reason
                statusLabel.TextColor3 = CONFIG.colors.negative
                
                -- Shake the button to indicate it can't be pressed
                local originalPosition = rebirthButton.Position
                
                for i = 1, 5 do
                    rebirthButton.Position = originalPosition + UDim2.new(0, (i % 2 == 0) and 5 or -5, 0, 0)
                    task.wait(0.05)
                end
                
                rebirthButton.Position = originalPosition
            end
        end
    })
    
    return rebirthGui
end

--[[ Update Functions ]]--

-- Refresh UI with latest data
local function refreshUI()
    if not rebirthGui or not rebirthGui.MainFrame.Visible then
        return
    end
    
    -- Try to get latest player data
    local success, data = pcall(function()
        return getPlayerDataEvent:InvokeServer()
    end)
    
    if success and data then
        playerData = data
    end
    
    if not playerData then
        return
    end
    
    -- Update current stats
    local statsFrame = rebirthGui.MainFrame.Content.StatsFrame
    
    -- Set gym level
    local gymLevel = playerData.gymLevel or 0
    statsFrame.GymLevelValue.Text = tostring(gymLevel)
    
    -- Set cash
    local cash = playerData.cash or 0
    statsFrame.CashValue.Text = formatCurrency(cash)
    
    -- Set rebirth level
    rebirthLevel = playerData.rebirthLevel or 0
    statsFrame.RebirthValue.Text = tostring(rebirthLevel)
    
    -- Calculate bonuses
    local bonuses = calculateRebirthBonuses(rebirthLevel)
    
    -- Update benefit values
    local benefitsFrame = rebirthGui.MainFrame.Content.BenefitsFrame
    benefitsFrame.RevenueValue.Text = formatPercentage(bonuses.next.revenueMultiplier - 1)
    benefitsFrame.AttractionValue.Text = formatPercentage(bonuses.next.memberAttraction - 1)
    benefitsFrame.EfficiencyValue.Text = formatPercentage(bonuses.next.equipmentEfficiency - 1)
    
    -- Update requirements status
    local canDoRebirth, reason = canRebirth()
    
    -- Update level requirement color
    local levelRequirement = rebirthGui.MainFrame.Content.LevelRequirement
    if gymLevel >= CONFIG.minimumRebirthLevel then
        levelRequirement.TextColor3 = CONFIG.colors.positive
    else
        levelRequirement.TextColor3 = CONFIG.colors.negative
    end
    
    -- Update cash requirement color
    local cashRequirement = rebirthGui.MainFrame.Content.CashRequirement
    if cash >= CONFIG.minimumCash then
        cashRequirement.TextColor3 = CONFIG.colors.positive
    else
        cashRequirement.TextColor3 = CONFIG.colors.negative
    end
    
    -- Update status label
    local statusLabel = rebirthGui.MainFrame.StatusLabel
    if canDoRebirth then
        statusLabel.Text = reason
        statusLabel.TextColor3 = CONFIG.colors.positive
    else
        statusLabel.Text = reason
        statusLabel.TextColor3 = CONFIG.colors.warning
    end
    
    -- Enable/disable rebirth button
    local rebirthButton = rebirthGui.MainFrame:FindFirstChild("Rebirth Now")
    if rebirthButton then
        rebirthButton.Selectable = canDoRebirth
        rebirthButton.BackgroundColor3 = canDoRebirth and CONFIG.colors.buttonPrimary or CONFIG.colors.buttonSecondary
    end
end

--[[ Public API Functions ]]--

-- Initialize the component
function RebirthUIComponent:initialize()
    -- Register with UIRegistry if available
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent("RebirthUI", self, "1.0.0")
        
        -- Register dependencies
        UIRegistry:registerDependency("RebirthUI", "ButtonFactory", "1.0.0")
    end
    
    -- Check for existing UI
    local existingUI = PlayerGui:FindFirstChild("RebirthUI")
    if existingUI then
        existingUI:Destroy()
    end
    
    -- Create the UI
    createRebirthUI()
    
    -- Set up refresh interval
    self.refreshConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if os.clock() % 1 < 0.01 then
            refreshUI()
        end
    end)
    
    return true
end

-- Preload function
function RebirthUIComponent:preload()
    -- Try to get initial player data
    local success, data = pcall(function()
        return getPlayerDataEvent:InvokeServer()
    end)
    
    if success and data then
        playerData = data
    end
    
    return true
end

-- Show the UI
function RebirthUIComponent:show()
    if not rebirthGui then
        createRebirthUI()
    end
    
    -- Get latest player data
    local success, data = pcall(function()
        return getPlayerDataEvent:InvokeServer()
    end)
    
    if success and data then
        playerData = data
    end
    
    -- Refresh UI with latest data
    refreshUI()
    
    -- Show the UI
    rebirthGui.MainFrame.Visible = true
    
    -- Store UI instance for access by UIManager
    self.instance = rebirthGui.MainFrame
    
    return true
end

-- Hide the UI
function RebirthUIComponent:hide()
    if rebirthGui then
        rebirthGui.MainFrame.Visible = false
        
        -- Close any confirmation dialog if open
        local dialog = rebirthGui.MainFrame:FindFirstChild("ConfirmationDialog")
        if dialog then
            dialog:Destroy()
            confirmationVisible = false
        end
    end
    
    return true
end

-- Refresh function for external calls
function RebirthUIComponent:refresh()
    refreshUI()
    return true
end

-- Destroy the component
function RebirthUIComponent:destroy()
    -- Clean up refresh connection
    if self.refreshConnection then
        self.refreshConnection:Disconnect()
        self.refreshConnection = nil
    end
    
    -- Remove UI
    if rebirthGui then
        rebirthGui:Destroy()
        rebirthGui = nil
    end
    
    return true
end

-- Return the module
return RebirthUIComponent
