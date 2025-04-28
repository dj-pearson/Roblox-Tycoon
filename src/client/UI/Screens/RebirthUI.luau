--!strict
--[[
    RebirthUI.luau
    
    UI for the rebirth system that allows players to reset progress for permanent bonuses.
    
    Features:
    - Tabbed interface with Overview, Benefits, History, and Advanced options
    - Visual confirmation and effects for rebirth
    - Progress tracking and history
    
    Author: Updated April 28, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safe require utility
local function requireSafely(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        return result
    else
        warn("Failed to require module: " .. tostring(moduleScript:GetFullName()) .. "\n" .. tostring(result))
        return nil
    end
end

-- Try to find dependencies
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
local ButtonFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("ButtonFactory"))
local UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))
local clientCoreFolder = LocalPlayer.PlayerScripts:FindFirstChild("Client") and
                         LocalPlayer.PlayerScripts.Client:FindFirstChild("Core")
local RebirthRemote = ReplicatedStorage:FindFirstChild("Remotes") and
                     ReplicatedStorage.Remotes:FindFirstChild("RebirthRemote")

-- Module and state variables
local RebirthUI = {}
local uiElements = {
    mainFrame = nil,
    tabs = {},
    activeTab = nil,
    confirmationDialog = nil
}

-- Configuration
local CONFIG = {
    animationDuration = 0.3,
    tabCount = 4, -- Overview, Benefits, History, Advanced
    mainFrameSize = UDim2.new(0, 600, 0, 400),
    tabButtonSize = UDim2.new(0.25, -10, 0, 30),
    tabContentSize = UDim2.new(1, -20, 1, -50),
    rebirthLevels = {}  -- Will be populated from server data
}

-- Format a number with commas 
local function formatNumber(number)
    local formatted = tostring(number)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Create the main UI
local function createMainUI()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RebirthUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10
    screenGui.Parent = PlayerGui
    
    -- Create Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = CONFIG.mainFrameSize
    mainFrame.Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.5, -CONFIG.mainFrameSize.Y.Offset / 2)
    mainFrame.BackgroundColor3 = UIStyle.Colors.Background
    mainFrame.BorderColor3 = UIStyle.Colors.Border
    mainFrame.BorderSizePixel = 2
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = UIStyle.Colors.Primary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Add title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Rebirth System"
    titleText.Font = UIStyle.Fonts.Bold
    titleText.TextSize = 18
    titleText.TextColor3 = UIStyle.Colors.Text
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Add close button
    local closeButton = ButtonFactory.createButton({
        size = UDim2.new(0, 30, 0, 30),
        position = UDim2.new(1, -35, 0, 5),
        backgroundColor = UIStyle.Colors.Danger,
        text = "X",
        textSize = 16,
        parent = titleBar,
        callback = function()
            RebirthUI:hide()
        end
    })
    
    -- Create tab buttons container
    local tabButtonsContainer = Instance.new("Frame")
    tabButtonsContainer.Name = "TabButtons"
    tabButtonsContainer.Size = UDim2.new(1, -20, 0, 40)
    tabButtonsContainer.Position = UDim2.new(0, 10, 0, 50)
    tabButtonsContainer.BackgroundTransparency = 1
    tabButtonsContainer.Parent = mainFrame
    
    -- Create tab content container
    local tabContentContainer = Instance.new("Frame")
    tabContentContainer.Name = "TabContent"
    tabContentContainer.Size = CONFIG.tabContentSize
    tabContentContainer.Position = UDim2.new(0, 10, 0, 100)
    tabContentContainer.BackgroundTransparency = 1
    tabContentContainer.Parent = mainFrame
    
    -- Store references
    uiElements.mainFrame = mainFrame
    uiElements.tabButtonsContainer = tabButtonsContainer
    uiElements.tabContentContainer = tabContentContainer
    uiElements.screenGui = screenGui
    
    return mainFrame
end

-- Create the tabs
local function createTabs()
    local tabNames = {"Overview", "Benefits", "History", "Advanced"}
    local tabButtons = {}
    local tabContents = {}
    
    -- Create tab buttons
    for i, tabName in ipairs(tabNames) do
        local button = ButtonFactory.createButton({
            size = CONFIG.tabButtonSize,
            position = UDim2.new((i - 1) * 0.25, 5, 0, 0),
            backgroundColor = i == 1 and UIStyle.Colors.Primary or UIStyle.Colors.Secondary,
            text = tabName,
            textSize = 14,
            parent = uiElements.tabButtonsContainer,
            callback = function()
                RebirthUI:switchTab(tabName)
            end
        })
        
        tabButtons[tabName] = button
        
        -- Create content frame for this tab
        local contentFrame = Instance.new("Frame")
        contentFrame.Name = tabName .. "Content"
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Visible = i == 1 -- Only first tab visible by default
        contentFrame.Parent = uiElements.tabContentContainer
        
        tabContents[tabName] = contentFrame
    end
    
    -- Store references
    uiElements.tabs = {
        buttons = tabButtons,
        contents = tabContents
    }
    uiElements.activeTab = "Overview"
end

-- Update rebirth info from server data
function RebirthUI:updateRebirthInfo()
    -- Remote call to get updated data
    local success, data = pcall(function()
        return RebirthRemote:InvokeServer("getRebirthInfo")
    end)
    
    if not success or not data then
        warn("Failed to get rebirth info")
        return
    end
    
    -- Update UI elements with new data
    if uiElements.revenueValue then
        uiElements.revenueValue.Text = "$" .. formatNumber(data.revenue or 0)
    end
    
    if uiElements.levelValue then
        uiElements.levelValue.Text = tostring(data.level or 1)
    end
    
    if uiElements.equipmentValue then
        uiElements.equipmentValue.Text = tostring(data.equipment or 0)
    end
    
    if uiElements.rebirthLevelValue then
        uiElements.rebirthLevelValue.Text = tostring(data.rebirthLevel or 0)
    end
    
    -- Update history table
    if uiElements.historyTable and data.history then
        -- Clear existing rows
        for _, child in pairs(uiElements.historyTable:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Add new rows
        for i, entry in ipairs(data.history) do
            -- Create row
            local row = Instance.new("Frame")
            row.Name = "HistoryRow" .. i
            row.Size = UDim2.new(1, 0, 0, 30)
            row.BackgroundColor3 = i % 2 == 0 and UIStyle.Colors.Secondary or Color3.fromRGB(40, 40, 40)
            row.BorderSizePixel = 0
            row.Parent = uiElements.historyTable
            
            -- Add columns
            local columns = {
                { value = tostring(i), width = 0.1 },
                { value = entry.date or "", width = 0.25 },
                { value = tostring(entry.level or ""), width = 0.15 },
                { value = "$" .. formatNumber(entry.revenue or 0), width = 0.25 },
                { value = tostring(entry.equipment or 0), width = 0.25 }
            }
            
            for j, column in ipairs(columns) do
                local cell = Instance.new("TextLabel")
                cell.Size = UDim2.new(column.width, 0, 1, 0)
                cell.Position = UDim2.new(j == 1 and 0 or columns[j-1].width + (columns[j-2] and columns[j-2].width or 0), 0, 0, 0)
                cell.BackgroundTransparency = 1
                cell.Text = column.value
                cell.Font = UIStyle.Fonts.Regular
                cell.TextSize = 14
                cell.TextColor3 = UIStyle.Colors.Text
                cell.Parent = row
            end
        end
        
        -- Update canvas size
        uiElements.historyTable.CanvasSize = UDim2.new(0, 0, 0, #data.history * 32) -- Height per row + padding
    end
end

--[[ Public API Functions ]]--

-- Switch active tab
function RebirthUI:switchTab(tabName)
    if not uiElements.tabs or not uiElements.tabs.buttons[tabName] or not uiElements.tabs.contents[tabName] then
        return
    end
    
    -- Update tab button colors
    for name, button in pairs(uiElements.tabs.buttons) do
        button.BackgroundColor3 = name == tabName and UIStyle.Colors.Primary or UIStyle.Colors.Secondary
    end
    
    -- Show/hide tab contents
    for name, content in pairs(uiElements.tabs.contents) do
        content.Visible = name == tabName
    end
    
    uiElements.activeTab = tabName
end

-- Initialize the UI
function RebirthUI:initialize()
    -- Create base UI if not already created
    if not uiElements.mainFrame then
        createMainUI()
    end
    
    if not uiElements.tabs or not next(uiElements.tabs) then
        createTabs()
    end
    
    -- Register with UIRegistry if available
    if UIRegistry and UIRegistry.registerComponent then
        UIRegistry:registerComponent("RebirthUI", self)
    end
    
    -- Register with UIManager if available
    if UIManager and UIManager.registerUI then
        UIManager:registerUI("RebirthUI", self)
    end
    
    -- Get initial data
    self:updateRebirthInfo()
    
    return self
end

-- Show the UI
function RebirthUI:show()
    if not uiElements.mainFrame then
        self:initialize()
    end
    
    -- Update data before showing
    self:updateRebirthInfo()
    
    -- Show the main frame with animation
    uiElements.mainFrame.Visible = true
    uiElements.mainFrame.BackgroundTransparency = 1
    uiElements.mainFrame.Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.6, -CONFIG.mainFrameSize.Y.Offset / 2)
    
    -- Create and play entrance animation
    local positionTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.5, -CONFIG.mainFrameSize.Y.Offset / 2) }
    )
    
    local transparencyTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0 }
    )
    
    positionTween:Play()
    transparencyTween:Play()
    
    return true
end

-- Hide the UI
function RebirthUI:hide()
    if not uiElements.mainFrame then return end
    
    -- Create and play exit animation
    local positionTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, -CONFIG.mainFrameSize.X.Offset / 2, 0.6, -CONFIG.mainFrameSize.Y.Offset / 2) }
    )
    
    local transparencyTween = TweenService:Create(
        uiElements.mainFrame,
        TweenInfo.new(CONFIG.animationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )
    
    -- Hide after animation completes
    transparencyTween.Completed:Connect(function()
        uiElements.mainFrame.Visible = false
    end)
    
    positionTween:Play()
    transparencyTween:Play()
    
    return true
end

-- Initialize on module load
RebirthUI:initialize()

-- Return the module
return RebirthUI
