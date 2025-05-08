--!strict
--[[
    AdminDashboardUI.client.luau
    
    Client-side UI for the admin dashboard that provides visualization
    and control of system status and health.
    
    Features:
    - System status display
    - Health check visualization
    - System recovery controls
    - Error history viewer
    - Statistics display
    - Real-time updates
    - Command console
    - Detailed error viewer
    
    Created: May 3, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Import required modules
local AdminDashboardSystem = require(ReplicatedStorage:WaitForChild("AdminDashboardSystem"))

-- UI Configuration
local CONFIG = {
    COLORS = {
        HEALTHY = Color3.fromRGB(0, 255, 0),
        DEGRADED = Color3.fromRGB(255, 165, 0),
        FAILED = Color3.fromRGB(255, 0, 0),
        PENDING = Color3.fromRGB(128, 128, 128),
        RECOVERING = Color3.fromRGB(0, 191, 255),
        SUCCESS = Color3.fromRGB(0, 255, 0),
        ERROR = Color3.fromRGB(255, 0, 0)
    },
    ANIMATION = {
        DURATION = 0.3,
        STYLE = Enum.EasingStyle.Quad,
        DIRECTION = Enum.EasingDirection.Out
    },
    TABS = {
        STATUS = "Status",
        CONSOLE = "Console",
        ERRORS = "Errors",
        STATS = "Stats"
    }
}

-- Create UI elements
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AdminDashboardUI"
    screenGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Name = "DashboardFrame"
    frame.Size = UDim2.new(0.3, 0, 0.8, 0)
    frame.Position = UDim2.new(0.7, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0.1, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    title.BorderSizePixel = 0
    title.Text = "Admin Dashboard"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    -- Create tab buttons
    local tabButtons = Instance.new("Frame")
    tabButtons.Name = "TabButtons"
    tabButtons.Size = UDim2.new(1, 0, 0.1, 0)
    tabButtons.Position = UDim2.new(0, 0, 0.1, 0)
    tabButtons.BackgroundTransparency = 1
    tabButtons.Parent = frame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0.02, 0)
    tabLayout.Parent = tabButtons
    
    -- Create tab content
    local tabContent = Instance.new("Frame")
    tabContent.Name = "TabContent"
    tabContent.Size = UDim2.new(1, 0, 0.8, 0)
    tabContent.Position = UDim2.new(0, 0, 0.2, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.Parent = frame
    
    -- Create status tab
    local statusTab = Instance.new("ScrollingFrame")
    statusTab.Name = CONFIG.TABS.STATUS
    statusTab.Size = UDim2.new(1, 0, 1, 0)
    statusTab.Position = UDim2.new(0, 0, 0, 0)
    statusTab.BackgroundTransparency = 1
    statusTab.BorderSizePixel = 0
    statusTab.ScrollBarThickness = 6
    statusTab.Visible = true
    statusTab.Parent = tabContent
    
    local statusLayout = Instance.new("UIListLayout")
    statusLayout.Padding = UDim.new(0, 5)
    statusLayout.Parent = statusTab
    
    -- Create console tab
    local consoleTab = Instance.new("Frame")
    consoleTab.Name = CONFIG.TABS.CONSOLE
    consoleTab.Size = UDim2.new(1, 0, 1, 0)
    consoleTab.Position = UDim2.new(0, 0, 0, 0)
    consoleTab.BackgroundTransparency = 1
    consoleTab.BorderSizePixel = 0
    consoleTab.Visible = false
    consoleTab.Parent = tabContent
    
    local consoleOutput = Instance.new("ScrollingFrame")
    consoleOutput.Name = "Output"
    consoleOutput.Size = UDim2.new(1, 0, 0.9, 0)
    consoleOutput.Position = UDim2.new(0, 0, 0, 0)
    consoleOutput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    consoleOutput.BorderSizePixel = 0
    consoleOutput.ScrollBarThickness = 6
    consoleOutput.Parent = consoleTab
    
    local consoleInput = Instance.new("TextBox")
    consoleInput.Name = "Input"
    consoleInput.Size = UDim2.new(1, 0, 0.1, 0)
    consoleInput.Position = UDim2.new(0, 0, 0.9, 0)
    consoleInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    consoleInput.BorderSizePixel = 0
    consoleInput.Text = ""
    consoleInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    consoleInput.TextSize = 14
    consoleInput.Font = Enum.Font.Gotham
    consoleInput.Parent = consoleTab
    
    -- Create errors tab
    local errorsTab = Instance.new("ScrollingFrame")
    errorsTab.Name = CONFIG.TABS.ERRORS
    errorsTab.Size = UDim2.new(1, 0, 1, 0)
    errorsTab.Position = UDim2.new(0, 0, 0, 0)
    errorsTab.BackgroundTransparency = 1
    errorsTab.BorderSizePixel = 0
    errorsTab.ScrollBarThickness = 6
    errorsTab.Visible = false
    errorsTab.Parent = tabContent
    
    local errorsLayout = Instance.new("UIListLayout")
    errorsLayout.Padding = UDim.new(0, 5)
    errorsLayout.Parent = errorsTab
    
    -- Create stats tab
    local statsTab = Instance.new("ScrollingFrame")
    statsTab.Name = CONFIG.TABS.STATS
    statsTab.Size = UDim2.new(1, 0, 1, 0)
    statsTab.Position = UDim2.new(0, 0, 0, 0)
    statsTab.BackgroundTransparency = 1
    statsTab.BorderSizePixel = 0
    statsTab.ScrollBarThickness = 6
    statsTab.Visible = false
    statsTab.Parent = tabContent
    
    local statsLayout = Instance.new("UIListLayout")
    statsLayout.Padding = UDim.new(0, 5)
    statsLayout.Parent = statsTab
    
    -- Create tab buttons
    for _, tabName in ipairs(CONFIG.TABS) do
        local button = Instance.new("TextButton")
        button.Name = tabName .. "Button"
        button.Size = UDim2.new(0.2, 0, 1, 0)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        button.BorderSizePixel = 0
        button.Text = tabName
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        button.Font = Enum.Font.Gotham
        button.Parent = tabButtons
        
        button.MouseButton1Click:Connect(function()
            -- Hide all tabs
            for _, tab in ipairs(tabContent:GetChildren()) do
                tab.Visible = false
            end
            
            -- Show selected tab
            tabContent:FindFirstChild(tabName).Visible = true
            
            -- Update button colors
            for _, btn in ipairs(tabButtons:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
            button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end)
    end
    
    return screenGui
end

-- Create system status element
local function createSystemStatusElement(systemName, status, health)
    local container = Instance.new("Frame")
    container.Name = systemName .. "Container"
    container.Size = UDim2.new(1, 0, 0, 100)
    container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    container.BorderSizePixel = 0
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = systemName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = container
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.3, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: " .. status
    statusLabel.TextColor3 = CONFIG.COLORS[status] or Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = container
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "Health"
    healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.6, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "Health: " .. (health and health.status or "Unknown")
    healthLabel.TextColor3 = CONFIG.COLORS[health and health.status or "PENDING"] or Color3.fromRGB(255, 255, 255)
    healthLabel.TextSize = 14
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.Parent = container
    
    local recoverButton = Instance.new("TextButton")
    recoverButton.Name = "RecoverButton"
    recoverButton.Size = UDim2.new(0.4, 0, 0.3, 0)
    recoverButton.Position = UDim2.new(0.3, 0, 0.7, 0)
    recoverButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    recoverButton.BorderSizePixel = 0
    recoverButton.Text = "Recover"
    recoverButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    recoverButton.TextSize = 14
    recoverButton.Font = Enum.Font.Gotham
    recoverButton.Parent = container
    
    recoverButton.MouseButton1Click:Connect(function()
        AdminDashboardSystem.recoverSystem(Players.LocalPlayer, systemName)
    end)
    
    return container
end

-- Create error element
local function createErrorElement(error)
    local container = Instance.new("Frame")
    container.Name = "ErrorContainer"
    container.Size = UDim2.new(1, 0, 0, 80)
    container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    container.BorderSizePixel = 0
    
    local timestamp = Instance.new("TextLabel")
    timestamp.Name = "Timestamp"
    timestamp.Size = UDim2.new(1, 0, 0.3, 0)
    timestamp.Position = UDim2.new(0, 0, 0, 0)
    timestamp.BackgroundTransparency = 1
    timestamp.Text = os.date("%Y-%m-%d %H:%M:%S", error.timestamp)
    timestamp.TextColor3 = Color3.fromRGB(200, 200, 200)
    timestamp.TextSize = 12
    timestamp.Font = Enum.Font.Gotham
    timestamp.Parent = container
    
    local errorText = Instance.new("TextLabel")
    errorText.Name = "Error"
    errorText.Size = UDim2.new(1, 0, 0.7, 0)
    errorText.Position = UDim2.new(0, 0, 0.3, 0)
    errorText.BackgroundTransparency = 1
    errorText.Text = error.error
    errorText.TextColor3 = CONFIG.COLORS.ERROR
    errorText.TextSize = 14
    errorText.Font = Enum.Font.Gotham
    errorText.TextWrapped = true
    errorText.Parent = container
    
    return container
end

-- Create stats element
local function createStatsElement(stats)
    local container = Instance.new("Frame")
    container.Name = "StatsContainer"
    container.Size = UDim2.new(1, 0, 0, 120)
    container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    container.BorderSizePixel = 0
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0.2, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "System Statistics"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = container
    
    local statsText = Instance.new("TextLabel")
    statsText.Name = "Stats"
    statsText.Size = UDim2.new(1, 0, 0.8, 0)
    statsText.Position = UDim2.new(0, 0, 0.2, 0)
    statsText.BackgroundTransparency = 1
    statsText.Text = string.format(
        "Total Commands: %d\nSuccessful: %d\nFailed: %d\nSuccess Rate: %.1f%%",
        stats.totalCommands,
        stats.successfulCommands,
        stats.failedCommands,
        stats.totalCommands > 0 and (stats.successfulCommands / stats.totalCommands * 100) or 0
    )
    statsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsText.TextSize = 14
    statsText.Font = Enum.Font.Gotham
    statsText.TextXAlignment = Enum.TextXAlignment.Left
    statsText.TextYAlignment = Enum.TextYAlignment.Top
    statsText.Parent = container
    
    return container
end

-- Update system status
local function updateSystemStatus(ui, status)
    local content = ui.DashboardFrame.TabContent:FindFirstChild(CONFIG.TABS.STATUS)
    content:ClearAllChildren()
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = content
    
    for systemName, systemStatus in pairs(status) do
        local element = createSystemStatusElement(systemName, systemStatus.status, systemStatus.health)
        element.Parent = content
    end
end

-- Update error history
local function updateErrorHistory(ui, errors)
    local content = ui.DashboardFrame.TabContent:FindFirstChild(CONFIG.TABS.ERRORS)
    content:ClearAllChildren()
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = content
    
    for _, error in ipairs(errors) do
        local element = createErrorElement(error)
        element.Parent = content
    end
end

-- Update statistics
local function updateStats(ui, stats)
    local content = ui.DashboardFrame.TabContent:FindFirstChild(CONFIG.TABS.STATS)
    content:ClearAllChildren()
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = content
    
    local element = createStatsElement(stats)
    element.Parent = content
end

-- Add console output
local function addConsoleOutput(ui, message, isError)
    local console = ui.DashboardFrame.TabContent:FindFirstChild(CONFIG.TABS.CONSOLE).Output
    local output = Instance.new("TextLabel")
    output.Size = UDim2.new(1, 0, 0, 20)
    output.BackgroundTransparency = 1
    output.Text = message
    output.TextColor3 = isError and CONFIG.COLORS.ERROR or CONFIG.COLORS.SUCCESS
    output.TextSize = 14
    output.Font = Enum.Font.Gotham
    output.TextXAlignment = Enum.TextXAlignment.Left
    output.Parent = console
    
    console.CanvasPosition = Vector2.new(0, console.CanvasSize.Y.Offset)
end

-- Toggle dashboard visibility
local function toggleDashboard(ui)
    local frame = ui.DashboardFrame
    frame.Visible = not frame.Visible
    
    local tweenInfo = TweenInfo.new(
        CONFIG.ANIMATION.DURATION,
        CONFIG.ANIMATION.STYLE,
        CONFIG.ANIMATION.DIRECTION
    )
    
    local tween = TweenService:Create(frame, tweenInfo, {
        Position = frame.Visible and UDim2.new(0.7, 0, 0.1, 0) or UDim2.new(1, 0, 0.1, 0)
    })
    tween:Play()
end

-- Initialize UI
local function initializeUI()
    local ui = createUI()
    ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Set up toggle key
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F9 then
            toggleDashboard(ui)
        end
    end)
    
    -- Set up console input
    local consoleInput = ui.DashboardFrame.TabContent:FindFirstChild(CONFIG.TABS.CONSOLE).Input
    consoleInput.FocusLost:Connect(function(enterPressed)
        if enterPressed and consoleInput.Text ~= "" then
            local command = consoleInput.Text
            consoleInput.Text = ""
            
            -- Execute command
            local success, result = AdminDashboardSystem.executeCommand(Players.LocalPlayer, command)
            addConsoleOutput(ui, command, false)
            addConsoleOutput(ui, result, not success)
        end
    end)
    
    -- Set up periodic updates
    task.spawn(function()
        while true do
            task.wait(5) -- Update every 5 seconds
            if ui.DashboardFrame.Visible then
                -- Update system status
                local status = AdminDashboardSystem.getSystemStatus(Players.LocalPlayer)
                if status then
                    updateSystemStatus(ui, status)
                end
                
                -- Update error history
                local errors = AdminDashboardSystem.getErrorHistory(Players.LocalPlayer)
                if errors then
                    updateErrorHistory(ui, errors)
                end
                
                -- Update statistics
                local stats = AdminDashboardSystem.getSystemStats(Players.LocalPlayer)
                if stats then
                    updateStats(ui, stats)
                end
            end
        end
    end)
    
    return ui
end

-- Initialize the UI
local ui = initializeUI()

return ui 