--[[
    ChallengesUI.client.luau
    
    UI module for the Challenges system
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
    local gui = playerGui:FindFirstChild("ChallengesGui")
    
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "ChallengesGui"
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
        mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
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
        titleLabel.Text = "Challenges"
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
        
        -- Add content frame
        local contentFrame = Instance.new("Frame")
        contentFrame.Name = "ContentFrame"
        contentFrame.Size = UDim2.new(0.95, 0, 0.85, 0)
        contentFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
        contentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        contentFrame.BackgroundTransparency = 0.9
        contentFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        contentFrame.Parent = mainFrame
        
        -- Add placeholder challenges
        local challengesList = Instance.new("ScrollingFrame")
        challengesList.Name = "ChallengesList"
        challengesList.Size = UDim2.new(0.9, 0, 0.8, 0)
        challengesList.Position = UDim2.new(0.5, 0, 0.5, 0)
        challengesList.AnchorPoint = Vector2.new(0.5, 0.5)
        challengesList.BackgroundTransparency = 0.8
        challengesList.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        challengesList.ScrollBarThickness = 6
        challengesList.Parent = contentFrame
        
        -- Add corner radius to challenges list
        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = UDim.new(0, 6)
        listCorner.Parent = challengesList
        
        -- Add placeholder challenges
        local challenges = {
            {name = "Daily Workout", description = "Complete 3 workouts today", reward = "200 coins", progress = "0/3"},
            {name = "Perfect Form", description = "Achieve perfect form on 5 exercises", reward = "300 coins", progress = "2/5"},
            {name = "Gym Expert", description = "Reach level 10 in your gym", reward = "1000 coins", progress = "Level 4/10"},
            {name = "Equipment Master", description = "Own 20 pieces of equipment", reward = "500 coins", progress = "12/20"}
        }
        
        -- Add padding for list items
        local listPadding = Instance.new("UIPadding")
        listPadding.PaddingLeft = UDim.new(0, 10)
        listPadding.PaddingRight = UDim.new(0, 10)
        listPadding.PaddingTop = UDim.new(0, 10)
        listPadding.PaddingBottom = UDim.new(0, 10)
        listPadding.Parent = challengesList
        
        -- Set up grid layout
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 10)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = challengesList
        
        -- Create challenge items
        for i, challenge in ipairs(challenges) do
            local challengeFrame = Instance.new("Frame")
            challengeFrame.Name = "Challenge_" .. i
            challengeFrame.Size = UDim2.new(1, 0, 0, 80)
            challengeFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            challengeFrame.BackgroundTransparency = 0.2
            challengeFrame.LayoutOrder = i
            challengeFrame.Parent = challengesList
            
            -- Add corner radius to challenge frame
            local frameCorner = Instance.new("UICorner")
            frameCorner.CornerRadius = UDim.new(0, 6)
            frameCorner.Parent = challengeFrame
            
            -- Add challenge name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(0.7, 0, 0, 25)
            nameLabel.Position = UDim2.new(0, 10, 0, 5)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = challenge.name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 18
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = challengeFrame
            
            -- Add challenge description
            local descLabel = Instance.new("TextLabel")
            descLabel.Name = "DescLabel"
            descLabel.Size = UDim2.new(0.7, 0, 0, 20)
            descLabel.Position = UDim2.new(0, 10, 0, 30)
            descLabel.BackgroundTransparency = 1
            descLabel.Text = challenge.description
            descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            descLabel.TextSize = 14
            descLabel.Font = Enum.Font.Gotham
            descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.Parent = challengeFrame
            
            -- Add challenge reward
            local rewardLabel = Instance.new("TextLabel")
            rewardLabel.Name = "RewardLabel"
            rewardLabel.Size = UDim2.new(0.3, 0, 0, 20)
            rewardLabel.Position = UDim2.new(0.7, 0, 0, 10)
            rewardLabel.BackgroundTransparency = 1
            rewardLabel.Text = "Reward: " .. challenge.reward
            rewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            rewardLabel.TextSize = 14
            rewardLabel.Font = Enum.Font.Gotham
            rewardLabel.TextXAlignment = Enum.TextXAlignment.Right
            rewardLabel.Parent = challengeFrame
            
            -- Add challenge progress
            local progressLabel = Instance.new("TextLabel")
            progressLabel.Name = "ProgressLabel"
            progressLabel.Size = UDim2.new(0.5, 0, 0, 20)
            progressLabel.Position = UDim2.new(0, 10, 0, 55)
            progressLabel.BackgroundTransparency = 1
            progressLabel.Text = "Progress: " .. challenge.progress
            progressLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
            progressLabel.TextSize = 14
            progressLabel.Font = Enum.Font.Gotham
            progressLabel.TextXAlignment = Enum.TextXAlignment.Left
            progressLabel.Parent = challengeFrame
        end
        
        -- Update scrolling frame canvas size
        challengesList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
        
        -- Connect close button
        closeButton.MouseButton1Click:Connect(function()
            gui.Enabled = false
        end)
    end
    
    return gui
end

-- Module implementation
local ChallengesUI = {}

-- Toggles the UI visibility
function ChallengesUI:ToggleUI()
    local gui = getOrCreateGui()
    gui.Enabled = not gui.Enabled
    
    -- Log action for debugging
    print("ChallengesUI " .. (gui.Enabled and "shown" or "hidden"))
    
    return gui.Enabled
end

-- Shows the UI
function ChallengesUI:ShowUI()
    local gui = getOrCreateGui()
    gui.Enabled = true
    
    -- Log action for debugging
    print("ChallengesUI shown")
    
    return true
end

-- Hides the UI
function ChallengesUI:HideUI()
    local gui = getOrCreateGui()
    gui.Enabled = false
    
    -- Log action for debugging
    print("ChallengesUI hidden")
    
    return true
end

-- Initialize the UI
getOrCreateGui()

-- Return the module
return ChallengesUI
