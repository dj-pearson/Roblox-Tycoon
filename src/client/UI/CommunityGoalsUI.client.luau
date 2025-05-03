--[[
    CommunityGoalsUI.client.luau
    
    UI module for the Community Goals system
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
    local gui = playerGui:FindFirstChild("CommunityGoalsGui")
    
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "CommunityGoalsGui"
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
        mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
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
        titleLabel.Text = "Community Goals"
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
        
        -- Add placeholder content
        local placeholderText = Instance.new("TextLabel")
        placeholderText.Name = "PlaceholderText"
        placeholderText.Size = UDim2.new(0.8, 0, 0.8, 0)
        placeholderText.Position = UDim2.new(0.5, 0, 0.5, 0)
        placeholderText.AnchorPoint = Vector2.new(0.5, 0.5)
        placeholderText.BackgroundTransparency = 1
        placeholderText.Text = "Community Goals content will appear here.\nThis is a placeholder UI."
        placeholderText.TextColor3 = Color3.fromRGB(200, 200, 200)
        placeholderText.TextSize = 18
        placeholderText.TextWrapped = true
        placeholderText.Font = Enum.Font.Gotham
        placeholderText.Parent = contentFrame
        
        -- Connect close button
        closeButton.MouseButton1Click:Connect(function()
            gui.Enabled = false
        end)
    end
    
    return gui
end

-- Module implementation
local CommunityGoalsUI = {}

-- Toggles the UI visibility
function CommunityGoalsUI:ToggleUI()
    local gui = getOrCreateGui()
    gui.Enabled = not gui.Enabled
    
    -- Log action for debugging
    print("CommunityGoalsUI " .. (gui.Enabled and "shown" or "hidden"))
    
    return gui.Enabled
end

-- Shows the UI
function CommunityGoalsUI:ShowUI()
    local gui = getOrCreateGui()
    gui.Enabled = true
    
    -- Log action for debugging
    print("CommunityGoalsUI shown")
    
    return true
end

-- Hides the UI
function CommunityGoalsUI:HideUI()
    local gui = getOrCreateGui()
    gui.Enabled = false
    
    -- Log action for debugging
    print("CommunityGoalsUI hidden")
    
    return true
end

-- Initialize the UI
getOrCreateGui()

-- Return the module
return CommunityGoalsUI
