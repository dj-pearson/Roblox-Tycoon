--[[
    AchievementsUI.client.luau
    
    UI module for the Achievements system
    Implements standard UI interface with toggle, show, and hide functions
    
    Created: May 3, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load required modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared") or ReplicatedStorage:FindFirstChild("Shared")

-- Safe require helper
local function requireSafely(moduleScript)
    if moduleScript and moduleScript:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            return result
        else
            warn("Failed to load module: " .. moduleScript.Name)
            return nil
        end
    end
    return nil
end

-- Import UI modules
local UIStyle = requireSafely(sharedFolder and sharedFolder:FindFirstChild("UIStyle"))
local IconSet = requireSafely(sharedFolder and sharedFolder:FindFirstChild("IconSet"))
local ButtonFactory = requireSafely(sharedFolder and sharedFolder:FindFirstChild("ButtonFactory"))

-- Create or get the ScreenGui for this UI
local function getOrCreateGui()
    local gui = playerGui:FindFirstChild("AchievementsGui")
    
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "AchievementsGui"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Enabled = false
        gui.Parent = playerGui
        
        -- Create main frame
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
        mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        mainFrame.BackgroundColor3 = Color3.fromRGB(45, 35, 60)
        mainFrame.BackgroundTransparency = 0.1
        mainFrame.Parent = gui
        
        -- Add corner radius
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = mainFrame
        
        -- Add title
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "TitleLabel"
        titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Achievements"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 24
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Parent = mainFrame
        
        -- Add close button
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Size = UDim2.new(0, 40, 0, 40)
        closeButton.Position = UDim2.new(1, -50, 0, 10)
        closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        closeButton.Text = "X"
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.TextSize = 18
        closeButton.Font = Enum.Font.GothamBold
        closeButton.Parent = mainFrame
        
        -- Add corner radius to close button
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = closeButton
        
        -- Add stats summary
        local statsFrame = Instance.new("Frame")
        statsFrame.Name = "StatsFrame"
        statsFrame.Size = UDim2.new(0.95, 0, 0.15, 0)
        statsFrame.Position = UDim2.new(0.5, 0, 0.175, 0)
        statsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        statsFrame.BackgroundColor3 = Color3.fromRGB(55, 45, 70)
        statsFrame.BackgroundTransparency = 0.3
        statsFrame.Parent = mainFrame
        
        -- Add corner radius to stats frame
        local statsCorner = Instance.new("UICorner")
        statsCorner.CornerRadius = UDim.new(0, 6)
        statsCorner.Parent = statsFrame
        
        -- Add achievement stats
        local statsLabels = {
            {name = "Total Achievements", value = "21/50", color = Color3.fromRGB(255, 255, 255)},
            {name = "Points Earned", value = "1,250", color = Color3.fromRGB(255, 215, 0)},
            {name = "Completion", value = "42%", color = Color3.fromRGB(100, 200, 255)}
        }
        
        for i, stat in ipairs(statsLabels) do
            local statFrame = Instance.new("Frame")
            statFrame.Name = "Stat_" .. i
            statFrame.Size = UDim2.new(0.333, -10, 1, -20)
            statFrame.Position = UDim2.new(0.333 * (i-1), 5, 0, 10)
            statFrame.BackgroundTransparency = 1
            statFrame.Parent = statsFrame
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
            nameLabel.Position = UDim2.new(0, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = stat.name
            nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            nameLabel.TextSize = 14
            nameLabel.Font = Enum.Font.GothamSemibold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Center
            nameLabel.Parent = statFrame
            
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Name = "ValueLabel"
            valueLabel.Size = UDim2.new(1, 0, 0.6, 0)
            valueLabel.Position = UDim2.new(0, 0, 0.4, 0)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = stat.value
            valueLabel.TextColor3 = stat.color
            valueLabel.TextSize = 22
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.TextXAlignment = Enum.TextXAlignment.Center
            valueLabel.Parent = statFrame
        end
        
        -- Add achievements grid
        local achievementsFrame = Instance.new("ScrollingFrame")
        achievementsFrame.Name = "AchievementsFrame"
        achievementsFrame.Size = UDim2.new(0.95, 0, 0.625, 0)
        achievementsFrame.Position = UDim2.new(0.5, 0, 0.575, 0)
        achievementsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        achievementsFrame.BackgroundTransparency = 0.9
        achievementsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        achievementsFrame.ScrollBarThickness = 6
        achievementsFrame.Parent = mainFrame
        
        -- Add grid layout
        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.new(0.33, -10, 0, 120)
        gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = achievementsFrame
        
        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 5)
        padding.PaddingRight = UDim.new(0, 5)
        padding.PaddingTop = UDim.new(0, 5)
        padding.PaddingBottom = UDim.new(0, 5)
        padding.Parent = achievementsFrame
        
        -- Sample achievements data
        local achievements = {
            {name = "Gym Starter", desc = "Start your first gym", completed = true},
            {name = "First Purchase", desc = "Buy your first equipment", completed = true},
            {name = "Level 5", desc = "Reach gym level 5", completed = true},
            {name = "First Staff", desc = "Hire your first staff member", completed = true},
            {name = "10 Members", desc = "Have 10 gym members", completed = true},
            {name = "Equipment Collector", desc = "Own 10 pieces of equipment", completed = true},
            {name = "Popular Gym", desc = "Reach 50 members", completed = false},
            {name = "Level 10", desc = "Reach gym level 10", completed = false},
            {name = "Premium Equipment", desc = "Buy a premium equipment", completed = false},
            {name = "Full Staff", desc = "Hire all types of staff", completed = false},
            {name = "Money Maker", desc = "Earn $10,000", completed = false},
            {name = "Expansion Expert", desc = "Unlock all gym tiles", completed = false}
        }
        
        -- Create achievement tiles
        for i, achievement in ipairs(achievements) do
            local tile = Instance.new("Frame")
            tile.Name = "Achievement_" .. i
            tile.BackgroundColor3 = achievement.completed 
                and Color3.fromRGB(60, 50, 100) 
                or Color3.fromRGB(40, 40, 50)
            tile.BackgroundTransparency = 0.2
            tile.LayoutOrder = i
            tile.Parent = achievementsFrame
            
            -- Add corner radius
            local tileCorner = Instance.new("UICorner")
            tileCorner.CornerRadius = UDim.new(0, 6)
            tileCorner.Parent = tile
            
            -- Add completion indicator
            local indicator = Instance.new("Frame")
            indicator.Name = "Indicator"
            indicator.Size = UDim2.new(0, 10, 0, 10)
            indicator.Position = UDim2.new(0.05, 0, 0.05, 0)
            indicator.BackgroundColor3 = achievement.completed 
                and Color3.fromRGB(100, 255, 100) 
                or Color3.fromRGB(100, 100, 100)
            indicator.Parent = tile
            
            -- Make indicator round
            local indicatorCorner = Instance.new("UICorner")
            indicatorCorner.CornerRadius = UDim.new(1, 0)
            indicatorCorner.Parent = indicator
            
            -- Add name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(0.9, 0, 0, 25)
            nameLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = achievement.name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 16
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = tile
            
            -- Add description
            local descLabel = Instance.new("TextLabel")
            descLabel.Name = "DescLabel"
            descLabel.Size = UDim2.new(0.9, 0, 0, 40)
            descLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
            descLabel.BackgroundTransparency = 1
            descLabel.Text = achievement.desc
            descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            descLabel.TextSize = 14
            descLabel.Font = Enum.Font.Gotham
            descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.TextWrapped = true
            descLabel.Parent = tile
            
            -- Add reward text
            local rewardLabel = Instance.new("TextLabel")
            rewardLabel.Name = "RewardLabel"
            rewardLabel.Size = UDim2.new(0.9, 0, 0, 20)
            rewardLabel.Position = UDim2.new(0.05, 0, 0.7, 0)
            rewardLabel.BackgroundTransparency = 1
            rewardLabel.Text = "Reward: 100 Points"
            rewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            rewardLabel.TextSize = 12
            rewardLabel.Font = Enum.Font.GothamSemibold
            rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
            rewardLabel.Parent = tile
        end
        
        -- Update canvas size based on content
        achievementsFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)
        
        -- Connect close button
        closeButton.MouseButton1Click:Connect(function()
            gui.Enabled = false
        end)
    end
    
    return gui
end

-- Module implementation
local AchievementsUI = {}

-- Toggles the UI visibility
function AchievementsUI:ToggleUI()
    local gui = getOrCreateGui()
    gui.Enabled = not gui.Enabled
    
    -- Log action for debugging
    print("AchievementsUI " .. (gui.Enabled and "shown" or "hidden"))
    
    return gui.Enabled
end

-- Shows the UI
function AchievementsUI:ShowUI()
    local gui = getOrCreateGui()
    gui.Enabled = true
    
    -- Log action for debugging
    print("AchievementsUI shown")
    
    return true
end

-- Hides the UI
function AchievementsUI:HideUI()
    local gui = getOrCreateGui()
    gui.Enabled = false
    
    -- Log action for debugging
    print("AchievementsUI hidden")
    
    return true
end

-- Initialize the UI
getOrCreateGui()

-- Return the module
return AchievementsUI
