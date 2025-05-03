--[[
    UpgradesUI.client.luau
    
    UI module for the Upgrades system
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
    local gui = playerGui:FindFirstChild("UpgradesGui")
    
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "UpgradesGui"
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
        mainFrame.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
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
        titleLabel.Text = "Gym Upgrades"
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
        
        -- Add tab buttons
        local tabButtonsFrame = Instance.new("Frame")
        tabButtonsFrame.Name = "TabButtonsFrame"
        tabButtonsFrame.Size = UDim2.new(1, 0, 0.08, 0)
        tabButtonsFrame.Position = UDim2.new(0, 0, 0.1, 0)
        tabButtonsFrame.BackgroundTransparency = 1
        tabButtonsFrame.Parent = mainFrame
        
        -- Add tabs
        local tabs = {"Equipment", "Facilities", "Staff", "Marketing"}
        local tabButtons = {}
        local tabFrames = {}
        
        -- Create tab buttons
        for i, tabName in ipairs(tabs) do
            local button = Instance.new("TextButton")
            button.Name = tabName .. "Button"
            button.Size = UDim2.new(0.25, -10, 1, -10)
            button.Position = UDim2.new(0.25 * (i-1), 5, 0, 5)
            button.BackgroundColor3 = Color3.fromRGB(50, 65, 90)
            button.Text = tabName
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.TextSize = 16
            button.Font = Enum.Font.GothamSemibold
            button.Parent = tabButtonsFrame
            
            -- Add corner radius
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 6)
            buttonCorner.Parent = button
            
            tabButtons[tabName] = button
            
            -- Create content frame for this tab
            local contentFrame = Instance.new("Frame")
            contentFrame.Name = tabName .. "Frame"
            contentFrame.Size = UDim2.new(0.95, 0, 0.78, 0)
            contentFrame.Position = UDim2.new(0.5, 0, 0.59, 0)
            contentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            contentFrame.BackgroundTransparency = 0.9
            contentFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            contentFrame.Visible = (i == 1) -- Only show first tab initially
            contentFrame.Parent = mainFrame
            
            tabFrames[tabName] = contentFrame
            
            -- Create some sample upgrades for this tab
            local upgradesScrollFrame = Instance.new("ScrollingFrame")
            upgradesScrollFrame.Name = "UpgradesScrollFrame"
            upgradesScrollFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
            upgradesScrollFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            upgradesScrollFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            upgradesScrollFrame.BackgroundTransparency = 1
            upgradesScrollFrame.ScrollBarThickness = 6
            upgradesScrollFrame.Parent = contentFrame
            
            -- Set up grid layout
            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 15)
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = upgradesScrollFrame
            
            -- Add some sample upgrades
            local numUpgrades = (i == 1) and 6 or 4 -- More equipment upgrades
            for j = 1, numUpgrades do
                local upgradeFrame = Instance.new("Frame")
                upgradeFrame.Name = "Upgrade_" .. j
                upgradeFrame.Size = UDim2.new(1, -20, 0, 90)
                upgradeFrame.BackgroundColor3 = Color3.fromRGB(40, 55, 80)
                upgradeFrame.BackgroundTransparency = 0.2
                upgradeFrame.LayoutOrder = j
                upgradeFrame.Parent = upgradesScrollFrame
                
                -- Add corner radius
                local upgradeCorner = Instance.new("UICorner")
                upgradeCorner.CornerRadius = UDim.new(0, 6)
                upgradeCorner.Parent = upgradeFrame
                
                -- Add upgrade name
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Name = "NameLabel"
                nameLabel.Size = UDim2.new(0.7, 0, 0, 30)
                nameLabel.Position = UDim2.new(0, 15, 0, 10)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = tabName .. " Upgrade " .. j
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextSize = 18
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = upgradeFrame
                
                -- Add upgrade description
                local descLabel = Instance.new("TextLabel")
                descLabel.Name = "DescLabel"
                descLabel.Size = UDim2.new(0.7, 0, 0, 30)
                descLabel.Position = UDim2.new(0, 15, 0, 40)
                descLabel.BackgroundTransparency = 1
                descLabel.Text = "Improves " .. tabName:lower() .. " efficiency by " .. (j * 5) .. "%"
                descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                descLabel.TextSize = 14
                descLabel.Font = Enum.Font.Gotham
                descLabel.TextXAlignment = Enum.TextXAlignment.Left
                descLabel.Parent = upgradeFrame
                
                -- Add upgrade cost
                local costLabel = Instance.new("TextLabel")
                costLabel.Name = "CostLabel"
                costLabel.Size = UDim2.new(0.25, 0, 0, 20)
                costLabel.Position = UDim2.new(0.73, 0, 0, 15)
                costLabel.BackgroundTransparency = 1
                costLabel.Text = "$" .. (j * 500)
                costLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
                costLabel.TextSize = 16
                costLabel.Font = Enum.Font.GothamSemibold
                costLabel.TextXAlignment = Enum.TextXAlignment.Right
                costLabel.Parent = upgradeFrame
                
                -- Add upgrade button
                local buyButton = Instance.new("TextButton")
                buyButton.Name = "BuyButton"
                buyButton.Size = UDim2.new(0.2, 0, 0, 30)
                buyButton.Position = UDim2.new(0.78, 0, 0, 45)
                buyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                buyButton.Text = "Upgrade"
                buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                buyButton.TextSize = 14
                buyButton.Font = Enum.Font.GothamSemibold
                buyButton.Parent = upgradeFrame
                
                -- Add corner radius to buy button
                local buyCorner = Instance.new("UICorner")
                buyCorner.CornerRadius = UDim.new(0, 6)
                buyCorner.Parent = buyButton
                
                -- Connect buy button (placeholder)
                buyButton.MouseButton1Click:Connect(function()
                    print("Purchasing " .. tabName .. " Upgrade " .. j)
                end)
            end
            
            -- Update scrolling frame canvas size
            upgradesScrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
            
            -- Connect tab button
            button.MouseButton1Click:Connect(function()
                -- Hide all tab frames
                for _, frame in pairs(tabFrames) do
                    frame.Visible = false
                end
                
                -- Show this tab frame
                contentFrame.Visible = true
                
                -- Update tab button styles
                for _, btn in pairs(tabButtons) do
                    btn.BackgroundColor3 = Color3.fromRGB(50, 65, 90)
                end
                button.BackgroundColor3 = Color3.fromRGB(70, 95, 130)
            end)
        end
        
        -- Connect close button
        closeButton.MouseButton1Click:Connect(function()
            gui.Enabled = false
        end)
    end
    
    return gui
end

-- Module implementation
local UpgradesUI = {}

-- Toggles the UI visibility
function UpgradesUI:ToggleUI()
    local gui = getOrCreateGui()
    gui.Enabled = not gui.Enabled
    
    -- Log action for debugging
    print("UpgradesUI " .. (gui.Enabled and "shown" or "hidden"))
    
    return gui.Enabled
end

-- Shows the UI
function UpgradesUI:ShowUI()
    local gui = getOrCreateGui()
    gui.Enabled = true
    
    -- Log action for debugging
    print("UpgradesUI shown")
    
    return true
end

-- Hides the UI
function UpgradesUI:HideUI()
    local gui = getOrCreateGui()
    gui.Enabled = false
    
    -- Log action for debugging
    print("UpgradesUI hidden")
    
    return true
end

-- Initialize the UI
getOrCreateGui()

-- Return the module
return UpgradesUI
