--[[
    RebirthUI.client.luau
    
    Enhanced client-side UI for interacting with the rebirth system with unlockable content progression.
    Refactored to use the standardized UI framework with proper close functionality.
    
    Author: Updated April 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Load required modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared") or ReplicatedStorage:FindFirstChild("Shared")
local clientFolder = script.Parent.Parent

-- Safely require a module
local function requireSafely(moduleScript)
    if moduleScript and moduleScript:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            return result
        else
            warn("Failed to load module: " .. moduleScript.Name .. " - " .. tostring(result))
            return nil
        end
    end
    return nil
end

-- Required modules
local UIUtils = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIUtils"))
local UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))
local UIManager = requireSafely(clientFolder and clientFolder:FindFirstChild("UI") and clientFolder.UI:FindFirstChild("UIManager"))
local ClientRegistry = requireSafely(clientFolder and clientFolder:FindFirstChild("Core") and clientFolder.Core:FindFirstChild("ClientRegistry"))

-- Wait for the remote event
local RebirthRemote = ReplicatedStorage:WaitForChild("RebirthRemote")

-- Rebirth UI Module
local RebirthUI = {}
RebirthUI.__index = RebirthUI

-- State tracking
local uiState = {
    initialized = false,
    uiElements = {},
    rebirthData = {
        rebirthCount = 0,
        cost = 100000,
        multiplier = 0,
        progress = 0,
        unlockedFeatures = {},
        activePerks = {},
        achievements = {},
        totalRebirths = 0,
        fastestTime = 0
    },
    currentTab = "Main"
}

-- Initialize the Rebirth UI system
function RebirthUI:Initialize()
    if uiState.initialized then
        return self
    end
    
    -- Register with registry if available
    if ClientRegistry then
        ClientRegistry.registerSystem("RebirthUI", self)
    end
    
    -- Create toggle button if UI Utils is available
    if UIUtils and UIUtils.createToggleButton then
        uiState.uiElements.toggleButton = UIUtils.createToggleButton(
            "Rebirth", 
            "rebirth", 
            UDim2.new(1, -130, 0, 60), -- Positioned below other menu buttons
            function()
                self:ToggleRebirthMenu()
            end
        )
    else
        -- Fallback to simple button if UIUtils not available
        self:CreateFallbackToggleButton()
    end
    
    -- Listen for server messages
    RebirthRemote.OnClientEvent:Connect(function(messageType, data)
        self:HandleRebirthResponse(messageType, data)
    end)
    
    -- Request initial rebirth information after a short delay
    task.delay(2, function()
        RebirthRemote:FireServer("GetInfo")
    end)
    
    uiState.initialized = true
    return self
end

-- Create the main Rebirth UI using UIUtils
function RebirthUI:CreateRebirthMenu()
    -- Skip if UIUtils not available
    if not UIUtils or not UIUtils.createMenuContainer then
        warn("UIUtils not available - cannot create Rebirth menu")
        return nil
    end
    
    -- Tab definitions for our menu
    local tabs = {
        { name = "Main", label = "Main" },
        { name = "Features", label = "Features" },
        { name = "Perks", label = "Perks" },
        { name = "Achievements", label = "Achievements" }
    }
    
    -- Create the menu using UIManager if available, otherwise directly via UIUtils
    local menuElements
    if UIManager and UIManager.CreateTabbedMenu then
        menuElements = UIManager:CreateTabbedMenu(
            "RebirthMenu",
            "Rebirth System",
            tabs,
            UDim2.new(0, 500, 0, 400),
            UDim2.new(0.5, -250, 0.5, -200)
        )
    else
        -- Fallback to direct creation with UIUtils
        local container = UIUtils.createMenuContainer(
            "RebirthMenu",
            "Rebirth System",
            UDim2.new(0, 500, 0, 400),
            UDim2.new(0.5, -250, 0.5, -200)
        )
        
        local tabSystem = UIUtils.createTabSystem(container.mainFrame, tabs)
        
        menuElements = {
            container = container,
            tabSystem = tabSystem
        }
    end
    
    -- Store reference to menu elements
    uiState.uiElements.menuElements = menuElements
    
    -- Create content for each tab
    self:CreateMainTabContent(menuElements.tabSystem.tabContents.Main)
    self:CreateFeaturesTabContent(menuElements.tabSystem.tabContents.Features)
    self:CreatePerksTabContent(menuElements.tabSystem.tabContents.Perks)
    self:CreateAchievementsTabContent(menuElements.tabSystem.tabContents.Achievements)
    
    -- Create rebirth button at bottom
    self:CreateRebirthButton(menuElements.container.mainFrame)
    
    -- Create stats display
    self:CreateStatsDisplay(menuElements.container.mainFrame)
    
    -- Hide menu initially
    menuElements.container.mainFrame.Visible = false
    
    return menuElements
end

-- Create main tab content
function RebirthUI:CreateMainTabContent(parent)
    -- Cost label
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(1, -20, 0, 25)
    costLabel.Position = UDim2.new(0, 10, 0, 20)
    costLabel.BackgroundTransparency = 1
    costLabel.Font = Enum.Font.GothamSemibold
    costLabel.Text = "Cost: $100,000"
    costLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    costLabel.TextSize = 18
    costLabel.Parent = parent
    
    -- Current rebirth count
    local rebirthCountLabel = Instance.new("TextLabel")
    rebirthCountLabel.Name = "RebirthCountLabel"
    rebirthCountLabel.Size = UDim2.new(1, -20, 0, 25)
    rebirthCountLabel.Position = UDim2.new(0, 10, 0, 50)
    rebirthCountLabel.BackgroundTransparency = 1
    rebirthCountLabel.Font = Enum.Font.Gotham
    rebirthCountLabel.Text = "Your Rebirth Level: 0"
    rebirthCountLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    rebirthCountLabel.TextSize = 16
    rebirthCountLabel.Parent = parent
    
    -- Rebirth multiplier
    local multiplierLabel = Instance.new("TextLabel")
    multiplierLabel.Name = "MultiplierLabel"
    multiplierLabel.Size = UDim2.new(1, -20, 0, 25)
    multiplierLabel.Position = UDim2.new(0, 10, 0, 80)
    multiplierLabel.BackgroundTransparency = 1
    multiplierLabel.Font = Enum.Font.Gotham
    multiplierLabel.Text = "Revenue Multiplier: 0%"
    multiplierLabel.TextColor3 = Color3.fromRGB(100, 255, 255)
    multiplierLabel.TextSize = 16
    multiplierLabel.Parent = parent
    
    -- Progress bar using UIUtils
    local progressBar
    if UIUtils and UIUtils.createProgressBar then
        progressBar = UIUtils.createProgressBar(
            parent,
            UDim2.new(1, -20, 0, 20),
            UDim2.new(0, 10, 0, 115),
            Color3.fromRGB(0, 180, 255)
        )
    else
        -- Fallback to manual creation
        local progressBarContainer = Instance.new("Frame")
        progressBarContainer.Name = "ProgressBarContainer"
        progressBarContainer.Size = UDim2.new(1, -20, 0, 20)
        progressBarContainer.Position = UDim2.new(0, 10, 0, 115)
        progressBarContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
        progressBarContainer.BorderSizePixel = 0
        progressBarContainer.Parent = parent
        
        local progressCorner = Instance.new("UICorner")
        progressCorner.CornerRadius = UDim.new(0, 4)
        progressCorner.Parent = progressBarContainer
        
        local progressBarFill = Instance.new("Frame")
        progressBarFill.Name = "ProgressBarFill"
        progressBarFill.Size = UDim2.new(0, 0, 1, 0)
        progressBarFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        progressBarFill.BorderSizePixel = 0
        progressBarFill.Parent = progressBarContainer
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 4)
        fillCorner.Parent = progressBarFill
        
        -- Create update function
        local updateProgress = function(progress)
            progressBarFill.Size = UDim2.new(progress, 0, 1, 0)
            return progress
        end
        
        progressBar = {
            container = progressBarContainer,
            fill = progressBarFill,
            updateProgress = updateProgress
        }
    end
    
    -- Progress label
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressLabel"
    progressLabel.Size = UDim2.new(1, -20, 0, 20)
    progressLabel.Position = UDim2.new(0, 10, 0, 140)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Font = Enum.Font.Gotham
    progressLabel.Text = "Progress: 0%"
    progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressLabel.TextSize = 14
    progressLabel.Parent = parent
    
    -- Next unlock info
    local nextUnlockLabel = Instance.new("TextLabel")
    nextUnlockLabel.Name = "NextUnlockLabel"
    nextUnlockLabel.Size = UDim2.new(1, -20, 0, 40)
    nextUnlockLabel.Position = UDim2.new(0, 10, 0, 165)
    nextUnlockLabel.BackgroundTransparency = 1
    nextUnlockLabel.Font = Enum.Font.Gotham
    nextUnlockLabel.Text = "Next Unlock: None"
    nextUnlockLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    nextUnlockLabel.TextSize = 14
    nextUnlockLabel.TextWrapped = true
    nextUnlockLabel.Parent = parent
    
    -- Store UI elements
    uiState.uiElements.costLabel = costLabel
    uiState.uiElements.rebirthCountLabel = rebirthCountLabel
    uiState.uiElements.multiplierLabel = multiplierLabel
    uiState.uiElements.progressBar = progressBar
    uiState.uiElements.progressLabel = progressLabel
    uiState.uiElements.nextUnlockLabel = nextUnlockLabel
    
    return parent
end

-- Create features tab content
function RebirthUI:CreateFeaturesTabContent(parent)
    -- Create scrolling list using UIUtils
    local featuresScroll
    if UIUtils and UIUtils.createScrollingList then
        featuresScroll = UIUtils.createScrollingList(parent)
    else
        -- Fallback to manual creation
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "FeaturesScrollFrame"
        scrollFrame.Size = UDim2.new(1, -20, 1, -20)
        scrollFrame.Position = UDim2.new(0, 10, 0, 10)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.ScrollBarThickness = 6
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.Parent = parent
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 10)
        listLayout.FillDirection = Enum.FillDirection.Vertical
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = scrollFrame
        
        featuresScroll = {
            scrollFrame = scrollFrame,
            listLayout = listLayout
        }
    end
    
    -- Store UI elements
    uiState.uiElements.featuresScroll = featuresScroll
    
    -- Show initial "no features" message
    self:ShowNoContentMessage(featuresScroll.scrollFrame, "No features unlocked yet. Rebirth to unlock special features!")
    
    return parent
end

-- Create perks tab content
function RebirthUI:CreatePerksTabContent(parent)
    -- Create scrolling list using UIUtils
    local perksScroll
    if UIUtils and UIUtils.createScrollingList then
        perksScroll = UIUtils.createScrollingList(parent)
    else
        -- Fallback to manual creation
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "PerksScrollFrame"
        scrollFrame.Size = UDim2.new(1, -20, 1, -20)
        scrollFrame.Position = UDim2.new(0, 10, 0, 10)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.ScrollBarThickness = 6
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.Parent = parent
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 10)
        listLayout.FillDirection = Enum.FillDirection.Vertical
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = scrollFrame
        
        perksScroll = {
            scrollFrame = scrollFrame,
            listLayout = listLayout
        }
    end
    
    -- Store UI elements
    uiState.uiElements.perksScroll = perksScroll
    
    -- Show initial "no perks" message
    self:ShowNoContentMessage(perksScroll.scrollFrame, "No perks unlocked yet. Reach higher rebirth levels to unlock perks!")
    
    return parent
end

-- Create achievements tab content
function RebirthUI:CreateAchievementsTabContent(parent)
    -- Create scrolling list using UIUtils
    local achievementsScroll
    if UIUtils and UIUtils.createScrollingList then
        achievementsScroll = UIUtils.createScrollingList(parent)
    else
        -- Fallback to manual creation
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "AchievementsScrollFrame"
        scrollFrame.Size = UDim2.new(1, -20, 1, -20)
        scrollFrame.Position = UDim2.new(0, 10, 0, 10)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.ScrollBarThickness = 6
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.Parent = parent
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 10)
        listLayout.FillDirection = Enum.FillDirection.Vertical
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = scrollFrame
        
        achievementsScroll = {
            scrollFrame = scrollFrame,
            listLayout = listLayout
        }
    end
    
    -- Store UI elements
    uiState.uiElements.achievementsScroll = achievementsScroll
    
    -- Show initial "no achievements" message
    self:ShowNoContentMessage(achievementsScroll.scrollFrame, "No achievements yet. Complete rebirths to earn achievements!")
    
    return parent
end

-- Create rebirth button
function RebirthUI:CreateRebirthButton(parent)
    local rebirthButton = Instance.new("TextButton")
    rebirthButton.Name = "RebirthButton"
    rebirthButton.Size = UDim2.new(0, 200, 0, 50)
    rebirthButton.Position = UDim2.new(0.5, -100, 1, -70)
    rebirthButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    rebirthButton.Font = Enum.Font.GothamBold
    rebirthButton.Text = "REBIRTH NOW"
    rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    rebirthButton.TextSize = 18
    rebirthButton.Parent = parent
    
    -- Add corner rounding
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = rebirthButton
    
    -- Handle rebirth button click
    rebirthButton.MouseButton1Click:Connect(function()
        self:ProcessRebirth(rebirthButton)
    end)
    
    -- Store UI element
    uiState.uiElements.rebirthButton = rebirthButton
    
    return rebirthButton
end

-- Create stats display at the bottom
function RebirthUI:CreateStatsDisplay(parent)
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(1, -20, 0, 30)
    statsContainer.Position = UDim2.new(0, 10, 1, -30)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = parent
    
    -- Total rebirths
    local totalRebirthsLabel = Instance.new("TextLabel")
    totalRebirthsLabel.Name = "TotalRebirthsLabel"
    totalRebirthsLabel.Size = UDim2.new(0.5, -10, 1, 0)
    totalRebirthsLabel.Position = UDim2.new(0, 0, 0, 0)
    totalRebirthsLabel.BackgroundTransparency = 1
    totalRebirthsLabel.Font = Enum.Font.Gotham
    totalRebirthsLabel.Text = "Total Rebirths: 0"
    totalRebirthsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    totalRebirthsLabel.TextSize = 12
    totalRebirthsLabel.TextXAlignment = Enum.TextXAlignment.Left
    totalRebirthsLabel.Parent = statsContainer
    
    -- Fastest rebirth
    local fastestRebirthLabel = Instance.new("TextLabel")
    fastestRebirthLabel.Name = "FastestRebirthLabel"
    fastestRebirthLabel.Size = UDim2.new(0.5, -10, 1, 0)
    fastestRebirthLabel.Position = UDim2.new(0.5, 10, 0, 0)
    fastestRebirthLabel.BackgroundTransparency = 1
    fastestRebirthLabel.Font = Enum.Font.Gotham
    fastestRebirthLabel.Text = "Fastest Rebirth: None"
    fastestRebirthLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    fastestRebirthLabel.TextSize = 12
    fastestRebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
    fastestRebirthLabel.Parent = statsContainer
    
    -- Store UI elements
    uiState.uiElements.totalRebirthsLabel = totalRebirthsLabel
    uiState.uiElements.fastestRebirthLabel = fastestRebirthLabel
    
    return statsContainer
end

-- Toggle the rebirth menu
function RebirthUI:ToggleRebirthMenu()
    -- Create menu if it doesn't exist yet
    if not uiState.uiElements.menuElements then
        uiState.uiElements.menuElements = self:CreateRebirthMenu()
    end
    
    if not uiState.uiElements.menuElements then
        warn("Failed to create rebirth menu")
        return
    end
    
    -- Toggle visibility
    local mainFrame = uiState.uiElements.menuElements.container.mainFrame
    mainFrame.Visible = not mainFrame.Visible
    
    -- Apply animation when opening
    if mainFrame.Visible then
        -- Pop-in animation
        mainFrame.Size = UDim2.new(0, 480, 0, 380)
        mainFrame.BackgroundTransparency = 0.5
        
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 500, 0, 400),
            BackgroundTransparency = 0.1
        }):Play()
        
        -- Update with latest data
        self:UpdateUIWithData()
    end
end

-- Create a fallback toggle button if UIUtils is not available
function RebirthUI:CreateFallbackToggleButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RebirthToggle"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create the button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "RebirthToggleButton"
    toggleButton.Size = UDim2.new(0, 120, 0, 40)
    toggleButton.Position = UDim2.new(1, -130, 0, 60) -- Below other potential menu buttons
    toggleButton.AnchorPoint = Vector2.new(1, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
    toggleButton.Font = Enum.Font.GothamSemibold
    toggleButton.Text = "Rebirth"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextSize = 16
    toggleButton.Parent = screenGui
    
    -- Add corner rounding
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleButton
    
    -- Connect click event
    toggleButton.MouseButton1Click:Connect(function()
        self:ToggleRebirthMenu()
    end)
    
    -- Store UI element
    uiState.uiElements.toggleButton = {
        toggleGui = screenGui,
        toggleButton = toggleButton
    }
    
    -- Add to PlayerGui
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    return toggleButton
end

-- Show "no content" message in a tab
function RebirthUI:ShowNoContentMessage(parent, message)
    local noContentLabel = Instance.new("TextLabel")
    noContentLabel.Name = "NoContentLabel"
    noContentLabel.Size = UDim2.new(1, -20, 0, 40)
    noContentLabel.BackgroundTransparency = 1
    noContentLabel.Font = Enum.Font.GothamMedium
    noContentLabel.Text = message
    noContentLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    noContentLabel.TextSize = 14
    noContentLabel.TextWrapped = true
    noContentLabel.Parent = parent
    
    return noContentLabel
end

-- Handle rebirth process
function RebirthUI:ProcessRebirth(rebirthButton)
    -- Disable the button temporarily
    rebirthButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    rebirthButton.Text = "Processing..."
    rebirthButton.Enabled = false
    
    -- Send rebirth request to server
    RebirthRemote:FireServer("Rebirth")
    
    -- Re-enable button after a delay
    task.delay(2, function()
        rebirthButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
        rebirthButton.Text = "REBIRTH NOW"
        rebirthButton.Enabled = true
    end)
end

-- Handle responses from the server
function RebirthUI:HandleRebirthResponse(messageType, data)
    if messageType == "RebirthSuccess" then
        -- Update the rebirth count
        if uiState.uiElements.rebirthCountLabel then
            uiState.uiElements.rebirthCountLabel.Text = "Your Rebirth Level: " .. data.rebirthCount
        end
        
        -- Show success notification
        self:ShowNotification("Rebirth Successful!", "New Multiplier: " .. string.format("%.1f", data.newMultiplier * 100) .. "%", Color3.fromRGB(0, 150, 50))
        
        -- Request updated info
        RebirthRemote:FireServer("GetInfo")
    elseif messageType == "NotEnoughCash" then
        -- Show not enough cash notification
        self:ShowNotification("Not Enough Cash", "You need $" .. self:FormatNumber(data.required), Color3.fromRGB(150, 30, 30))
    elseif messageType == "RebirthInfo" then
        -- Store the data
        uiState.rebirthData = data
        
        -- Update UI with the new data
        self:UpdateUIWithData()
    end
end

-- Show a notification
function RebirthUI:ShowNotification(title, message, bgColor)
    -- Try to use UIManager notification if available
    if UIManager and UIManager.ShowNotification then
        UIManager:ShowNotification(title .. "\n" .. message)
        return
    end
    
    -- Try to use CentralMenuUI if available
    local clientFolder = script.Parent.Parent
    local CentralMenuUI = requireSafely(clientFolder and clientFolder:FindFirstChild("UI") and clientFolder.UI:FindFirstChild("CentralMenuUI"))
    if CentralMenuUI and CentralMenuUI.ShowNotification then
        CentralMenuUI:ShowNotification(title .. "\n" .. message)
        return
    end
    
    -- Fallback to custom notification
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RebirthNotification"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create notification background
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(0, 300, 0, 100)
    notificationFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
    notificationFrame.BackgroundColor3 = bgColor or Color3.fromRGB(50, 50, 100)
    notificationFrame.BackgroundTransparency = 0.2
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = screenGui
    
    -- Add corner rounding
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = notificationFrame
    
    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.TextWrapped = true
    titleLabel.Parent = notificationFrame
    
    -- Message text
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -20, 0, 40)
    messageLabel.Position = UDim2.new(0, 10, 0, 50)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.TextSize = 16
    messageLabel.TextWrapped = true
    messageLabel.Parent = notificationFrame
    
    -- Animate in
    notificationFrame.Position = UDim2.new(0.5, -150, 0.6, -50)
    notificationFrame.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1
    messageLabel.TextTransparency = 1
    
    -- Fade in animation
    TweenService:Create(notificationFrame, TweenInfo.new(0.5), {
        Position = UDim2.new(0.5, -150, 0.5, -50),
        BackgroundTransparency = 0.2
    }):Play()
    
    TweenService:Create(titleLabel, TweenInfo.new(0.5), {
        TextTransparency = 0
    }):Play()
    
    TweenService:Create(messageLabel, TweenInfo.new(0.5), {
        TextTransparency = 0
    }):Play()
    
    -- Remove after delay
    task.delay(3, function()
        -- Fade out animation
        TweenService:Create(notificationFrame, TweenInfo.new(0.5), {
            Position = UDim2.new(0.5, -150, 0.4, -50),
            BackgroundTransparency = 1
        }):Play()
        
        TweenService:Create(titleLabel, TweenInfo.new(0.5), {
            TextTransparency = 1
        }):Play()
        
        TweenService:Create(messageLabel, TweenInfo.new(0.5), {
            TextTransparency = 1
        }):Play()
        
        -- Destroy after animation completes
        task.delay(0.6, function()
            screenGui:Destroy()
        end)
    end)
end

-- Update UI with the latest rebirth data
function RebirthUI:UpdateUIWithData()
    local data = uiState.rebirthData
    if not data then return end
    
    -- Update main tab info
    if uiState.uiElements.costLabel then
        uiState.uiElements.costLabel.Text = "Cost: $" .. self:FormatNumber(data.cost or 100000)
    end
    
    if uiState.uiElements.rebirthCountLabel then
        uiState.uiElements.rebirthCountLabel.Text = "Your Rebirth Level: " .. (data.rebirthCount or 0)
    end
    
    if uiState.uiElements.multiplierLabel then
        uiState.uiElements.multiplierLabel.Text = "Revenue Multiplier: " .. string.format("%.1f", (data.multiplier or 0) * 100) .. "%"
    end
    
    -- Update progress bar
    local progress = data.progress or 0
    if uiState.uiElements.progressBar then
        if uiState.uiElements.progressBar.updateProgress then
            uiState.uiElements.progressBar.updateProgress(progress)
        else
            -- Fallback for manual progress bar
            TweenService:Create(uiState.uiElements.progressBar.fill, TweenInfo.new(0.5), {
                Size = UDim2.new(progress, 0, 1, 0)
            }):Play()
        end
    end
    
    if uiState.uiElements.progressLabel then
        uiState.uiElements.progressLabel.Text = "Progress: " .. string.format("%.1f", progress * 100) .. "%"
    end
    
    -- Update next unlock info
    if uiState.uiElements.nextUnlockLabel then
        if data.nextFeature then
            uiState.uiElements.nextUnlockLabel.Text = "Next Feature: " .. data.nextFeature.name .. " (Level " .. (data.rebirthCount + 1) .. ")"
        elseif data.nextPerk then
            uiState.uiElements.nextUnlockLabel.Text = "Next Perk: " .. data.nextPerk.name .. " (Level " .. (data.rebirthCount + 1) .. ")"
        else
            uiState.uiElements.nextUnlockLabel.Text = "Next Unlock: None"
        end
    end
    
    -- Update stats
    if uiState.uiElements.totalRebirthsLabel then
        uiState.uiElements.totalRebirthsLabel.Text = "Total Rebirths: " .. (data.totalRebirths or 0)
    end
    
    if uiState.uiElements.fastestRebirthLabel then
        uiState.uiElements.fastestRebirthLabel.Text = "Fastest Rebirth: " .. self:FormatTime(data.fastestTime)
    end
    
    -- Update features tab
    self:UpdateFeaturesTab(data.unlockedFeatures)
    
    -- Update perks tab
    self:UpdatePerksTab(data.activePerks)
    
    -- Update achievements tab
    self:UpdateAchievementsTab(data.achievements)
end

-- Update the features tab
function RebirthUI:UpdateFeaturesTab(unlockedFeatures)
    local featuresScroll = uiState.uiElements.featuresScroll
    if not featuresScroll or not featuresScroll.scrollFrame then return end
    
    -- Clear existing cards
    for _, child in ipairs(featuresScroll.scrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^FeatureCard_") then
            child:Destroy()
        end
    end
    
    -- Clear message if it exists
    for _, child in ipairs(featuresScroll.scrollFrame:GetChildren()) do
        if child:IsA("TextLabel") and child.Name == "NoContentLabel" then
            child:Destroy()
        end
    end
    
    -- Add feature cards
    if unlockedFeatures and #unlockedFeatures > 0 then
        for _, feature in ipairs(unlockedFeatures) do
            -- Create feature card (using UIUtils.createCard if available)
            local card
            if UIUtils and UIUtils.createCard then
                card = UIUtils.createCard(featuresScroll.scrollFrame, 80, Color3.fromRGB(60, 60, 90))
            else
                -- Create card manually
                card = Instance.new("Frame")
                card.Size = UDim2.new(1, -20, 0, 80)
                card.BackgroundColor3 = feature.info.model and Color3.fromRGB(80, 50, 100) or Color3.fromRGB(60, 60, 90)
                card.BorderSizePixel = 0
                card.Parent = featuresScroll.scrollFrame
                
                local cardCorner = Instance.new("UICorner")
                cardCorner.CornerRadius = UDim.new(0, 8)
                cardCorner.Parent = card
            end
            
            card.Name = "FeatureCard_" .. feature.level
            card.LayoutOrder = feature.level
            
            -- Feature icon
            if feature.info.icon then
                local icon = Instance.new("ImageLabel")
                icon.Name = "FeatureIcon"
                icon.Size = UDim2.new(0, 50, 0, 50)
                icon.Position = UDim2.new(0, 10, 0, 15)
                icon.BackgroundTransparency = 1
                icon.Image = feature.info.icon
                icon.Parent = card
            end
            
            -- Feature name and description would be added here
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "FeatureName"
            nameLabel.Size = UDim2.new(1, -80, 0, 25)
            nameLabel.Position = UDim2.new(0, 70, 0, 10)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Text = feature.info.name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 16
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = card
            
            -- Feature description
            local descLabel = Instance.new("TextLabel")
            descLabel.Name = "FeatureDesc"
            descLabel.Size = UDim2.new(1, -80, 0, 40)
            descLabel.Position = UDim2.new(0, 70, 0, 35)
            descLabel.BackgroundTransparency = 1
            descLabel.Font = Enum.Font.Gotham
            descLabel.Text = feature.info.description
            descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            descLabel.TextSize = 12
            descLabel.TextWrapped = true
            descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.Parent = card
            
            -- Level indicator
            local levelLabel = Instance.new("TextLabel")
            levelLabel.Name = "LevelLabel"
            levelLabel.Size = UDim2.new(0, 50, 0, 20)
            levelLabel.Position = UDim2.new(1, -60, 0, 10)
            levelLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
            levelLabel.Font = Enum.Font.GothamSemibold
            levelLabel.Text = "Lvl " .. feature.level
            levelLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
            levelLabel.TextSize = 12
            levelLabel.Parent = card
            
            -- Level indicator corner
            local levelCorner = Instance.new("UICorner")
            levelCorner.CornerRadius = UDim.new(0, 4)
            levelCorner.Parent = levelLabel
        end
        
        -- Update canvas size for scrolling
        self:UpdateScrollCanvasSize(featuresScroll.scrollFrame, #unlockedFeatures * 90)
    else
        -- Show no features message
        self:ShowNoContentMessage(featuresScroll.scrollFrame, "No features unlocked yet. Rebirth to unlock special features!")
    end
end

-- Update the perks tab
function RebirthUI:UpdatePerksTab(activePerks)
    local perksScroll = uiState.uiElements.perksScroll
    if not perksScroll or not perksScroll.scrollFrame then return end
    
    -- Clear existing cards
    for _, child in ipairs(perksScroll.scrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^PerkCard_") then
            child:Destroy()
        end
    end
    
    -- Clear message if it exists
    for _, child in ipairs(perksScroll.scrollFrame:GetChildren()) do
        if child:IsA("TextLabel") and child.Name == "NoContentLabel" then
            child:Destroy()
        end
    end
    
    -- Add perk cards
    if activePerks and #activePerks > 0 then
        for _, perk in ipairs(activePerks) do
            -- Create perk card (using UIUtils.createCard if available)
            local card
            if UIUtils and UIUtils.createCard then
                card = UIUtils.createCard(perksScroll.scrollFrame, 80, Color3.fromRGB(40, 80, 60))
            else
                -- Create card manually
                card = Instance.new("Frame")
                card.Size = UDim2.new(1, -20, 0, 80)
                card.BackgroundColor3 = Color3.fromRGB(40, 80, 60)
                card.BorderSizePixel = 0
                card.Parent = perksScroll.scrollFrame
                
                local cardCorner = Instance.new("UICorner")
                cardCorner.CornerRadius = UDim.new(0, 8)
                cardCorner.Parent = card
            end
            
            card.Name = "PerkCard_" .. perk.level
            card.LayoutOrder = perk.level
            
            -- Perk icon
            if perk.info.icon then
                local icon = Instance.new("ImageLabel")
                icon.Name = "PerkIcon"
                icon.Size = UDim2.new(0, 50, 0, 50)
                icon.Position = UDim2.new(0, 10, 0, 15)
                icon.BackgroundTransparency = 1
                icon.Image = perk.info.icon
                icon.Parent = card
            end
            
            -- Perk name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "PerkName"
            nameLabel.Size = UDim2.new(1, -80, 0, 25)
            nameLabel.Position = UDim2.new(0, 70, 0, 10)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Text = perk.info.name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 16
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = card
            
            -- Perk description
            local descLabel = Instance.new("TextLabel")
            descLabel.Name = "PerkDesc"
            descLabel.Size = UDim2.new(1, -80, 0, 40)
            descLabel.Position = UDim2.new(0, 70, 0, 35)
            descLabel.BackgroundTransparency = 1
            descLabel.Font = Enum.Font.Gotham
            descLabel.Text = perk.info.description
            descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            descLabel.TextSize = 12
            descLabel.TextWrapped = true
            descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.Parent = card
            
            -- Level indicator
            local levelLabel = Instance.new("TextLabel")
            levelLabel.Name = "LevelLabel"
            levelLabel.Size = UDim2.new(0, 50, 0, 20)
            levelLabel.Position = UDim2.new(1, -60, 0, 10)
            levelLabel.BackgroundColor3 = Color3.fromRGB(30, 60, 50)
            levelLabel.Font = Enum.Font.GothamSemibold
            levelLabel.Text = "Lvl " .. perk.level
            levelLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
            levelLabel.TextSize = 12
            levelLabel.Parent = card
            
            -- Level indicator corner
            local levelCorner = Instance.new("UICorner")
            levelCorner.CornerRadius = UDim.new(0, 4)
            levelCorner.Parent = levelLabel
        end
        
        -- Update canvas size for scrolling
        self:UpdateScrollCanvasSize(perksScroll.scrollFrame, #activePerks * 90)
    else
        -- Show no perks message
        self:ShowNoContentMessage(perksScroll.scrollFrame, "No perks unlocked yet. Reach higher rebirth levels to unlock perks!")
    end
end

-- Update the achievements tab
function RebirthUI:UpdateAchievementsTab(achievements)
    local achievementsScroll = uiState.uiElements.achievementsScroll
    if not achievementsScroll or not achievementsScroll.scrollFrame then return end
    
    -- Clear existing cards
    for _, child in ipairs(achievementsScroll.scrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^AchievementCard_") then
            child:Destroy()
        end
    end
    
    -- Clear message if it exists
    for _, child in ipairs(achievementsScroll.scrollFrame:GetChildren()) do
        if child:IsA("TextLabel") and child.Name == "NoContentLabel" then
            child:Destroy()
        end
    end
    
    -- Add achievement cards
    if achievements and #achievements > 0 then
        for i, achievement in ipairs(achievements) do
            -- Create achievement card (using UIUtils.createCard if available)
            local card
            if UIUtils and UIUtils.createCard then
                card = UIUtils.createCard(achievementsScroll.scrollFrame, 80, achievement.earned and Color3.fromRGB(60, 80, 40) or Color3.fromRGB(70, 70, 70))
            else
                -- Create card manually
                card = Instance.new("Frame")
                card.Size = UDim2.new(1, -20, 0, 80)
                card.BackgroundColor3 = achievement.earned and Color3.fromRGB(60, 80, 40) or Color3.fromRGB(70, 70, 70)
                card.BorderSizePixel = 0
                card.Parent = achievementsScroll.scrollFrame
                
                local cardCorner = Instance.new("UICorner")
                cardCorner.CornerRadius = UDim.new(0, 8)
                cardCorner.Parent = card
            end
            
            card.Name = "AchievementCard_" .. achievement.id
            card.LayoutOrder = achievement.earned and i or (1000 + i) -- Sort earned achievements first
            
            -- Achievement icon
            if achievement.info.icon then
                local icon = Instance.new("ImageLabel")
                icon.Name = "AchievementIcon"
                icon.Size = UDim2.new(0, 50, 0, 50)
                icon.Position = UDim2.new(0, 10, 0, 15)
                icon.BackgroundTransparency = 1
                icon.Image = achievement.info.icon
                icon.ImageTransparency = achievement.earned and 0 or 0.5
                icon.Parent = card
            end
            
            -- Achievement name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "AchievementName"
            nameLabel.Size = UDim2.new(1, -80, 0, 25)
            nameLabel.Position = UDim2.new(0, 70, 0, 10)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Text = achievement.info.name
            nameLabel.TextColor3 = achievement.earned and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
            nameLabel.TextSize = 16
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = card
            
            -- Achievement description
            local descLabel = Instance.new("TextLabel")
            descLabel.Name = "AchievementDesc"
            descLabel.Size = UDim2.new(1, -80, 0, 40)
            descLabel.Position = UDim2.new(0, 70, 0, 35)
            descLabel.BackgroundTransparency = 1
            descLabel.Font = Enum.Font.Gotham
            descLabel.Text = achievement.info.description
            descLabel.TextColor3 = achievement.earned and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(150, 150, 150)
            descLabel.TextSize = 12
            descLabel.TextWrapped = true
            descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.Parent = card
            
            -- Status indicator
            local statusLabel = Instance.new("TextLabel")
            statusLabel.Name = "StatusLabel"
            statusLabel.Size = UDim2.new(0, 70, 0, 20)
            statusLabel.Position = UDim2.new(1, -80, 0, 10)
            statusLabel.BackgroundColor3 = achievement.earned and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(80, 40, 40)
            statusLabel.Font = Enum.Font.GothamSemibold
            statusLabel.Text = achievement.earned and "Completed" or "Locked"
            statusLabel.TextColor3 = achievement.earned and Color3.fromRGB(200, 255, 200) or Color3.fromRGB(255, 200, 200)
            statusLabel.TextSize = 12
            statusLabel.Parent = card
            
            -- Status indicator corner
            local statusCorner = Instance.new("UICorner")
            statusCorner.CornerRadius = UDim.new(0, 4)
            statusCorner.Parent = statusLabel
            
            -- Reward display if applicable
            if achievement.info.reward and achievement.info.reward > 0 then
                local rewardLabel = Instance.new("TextLabel")
                rewardLabel.Name = "RewardLabel"
                rewardLabel.Size = UDim2.new(0, 70, 0, 20)
                rewardLabel.Position = UDim2.new(1, -80, 0, 35)
                rewardLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 40)
                rewardLabel.Font = Enum.Font.GothamSemibold
                rewardLabel.Text = "$" .. self:FormatNumber(achievement.info.reward)
                rewardLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
                rewardLabel.TextSize = 12
                rewardLabel.Parent = card
                
                -- Reward label corner
                local rewardCorner = Instance.new("UICorner")
                rewardCorner.CornerRadius = UDim.new(0, 4)
                rewardCorner.Parent = rewardLabel
            end
        end
        
        -- Update canvas size for scrolling
        self:UpdateScrollCanvasSize(achievementsScroll.scrollFrame, #achievements * 90)
    else
        -- Show no achievements message
        self:ShowNoContentMessage(achievementsScroll.scrollFrame, "No achievements yet. Complete rebirths to earn achievements!")
    end
end

-- Update scroll frame canvas size
function RebirthUI:UpdateScrollCanvasSize(scrollFrame, contentHeight)
    -- Add padding to ensure scrolling works properly
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 10)
    
    -- If there's a UIListLayout, use its absolute content size
    local listLayout = scrollFrame:FindFirstChildOfClass("UIListLayout")
    if listLayout then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end
end

-- Format numbers with commas for better readability
function RebirthUI:FormatNumber(num)
    local formatted = tostring(math.floor(num))
    local i = #formatted % 3
    if i == 0 then i = 3 end
    local result = formatted:sub(1, i)
    for j = i + 1, #formatted, 3 do
        result = result .. "," .. formatted:sub(j, j + 2)
    end
    return result
end

-- Format time in a readable way
function RebirthUI:FormatTime(seconds)
    if not seconds or seconds == math.huge then
        return "Never"
    end
    
    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = math.floor(seconds % 60)
    
    local result = ""
    if days > 0 then
        result = result .. days .. "d "
    end
    if hours > 0 or days > 0 then
        result = result .. hours .. "h "
    end
    if minutes > 0 or hours > 0 or days > 0 then
        result = result .. minutes .. "m "
    end
    result = result .. seconds .. "s"
    
    return result
end

-- Public API methods
RebirthUI.initialize = RebirthUI.Initialize -- For ClientRegistry compatibility 
RebirthUI.toggleMenu = RebirthUI.ToggleRebirthMenu
RebirthUI.updateData = RebirthUI.UpdateUIWithData
RebirthUI.showNotification = RebirthUI.ShowNotification

-- Initialize the module when required
return RebirthUI:Initialize()