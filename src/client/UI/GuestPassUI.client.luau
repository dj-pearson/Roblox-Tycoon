--[[
    GuestPassUI.client.luau
    
    UI module for the Guest Pass system
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
    local gui = playerGui:FindFirstChild("GuestPassGui")
    
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "GuestPassGui"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Enabled = false
        gui.Parent = playerGui
        
        -- Create main frame
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
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
        titleLabel.Text = "Guest Pass"
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
        
        -- Add description text
        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "DescLabel"
        descLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
        descLabel.Position = UDim2.new(0.5, 0, 0.175, 0)
        descLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = "Invite friends to your gym with guest passes! They'll get a free trial and you'll earn a bonus when they join."
        descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        descLabel.TextSize = 16
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextWrapped = true
        descLabel.Parent = mainFrame
        
        -- Add guest pass options frame
        local optionsFrame = Instance.new("Frame")
        optionsFrame.Name = "OptionsFrame"
        optionsFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
        optionsFrame.Position = UDim2.new(0.5, 0, 0.525, 0)
        optionsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        optionsFrame.BackgroundTransparency = 1
        optionsFrame.Parent = mainFrame
        
        -- Guest pass options
        local passOptions = {
            {name = "1-Day Pass", desc = "24 hours of access", price = "Free", bonus = "10 coins"},
            {name = "3-Day Pass", desc = "72 hours of access", price = "20 coins", bonus = "30 coins"},
            {name = "7-Day Pass", desc = "1 week of access", price = "50 coins", bonus = "75 coins"}
        }
        
        -- Create pass option cards
        for i, option in ipairs(passOptions) do
            local passCard = Instance.new("Frame")
            passCard.Name = option.name .. "Card"
            passCard.Size = UDim2.new(0.3, -20, 0.8, 0)
            passCard.Position = UDim2.new(0.333 * (i-1) + 0.167, 0, 0.5, 0)
            passCard.AnchorPoint = Vector2.new(0.5, 0.5)
            passCard.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            passCard.Parent = optionsFrame
            
            -- Add corner radius
            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 8)
            cardCorner.Parent = passCard
            
            -- Add title
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
            nameLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
            nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = option.name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 18
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = passCard
            
            -- Add description
            local descLabel = Instance.new("TextLabel")
            descLabel.Name = "DescLabel"
            descLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
            descLabel.Position = UDim2.new(0.5, 0, 0.25, 0)
            descLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            descLabel.BackgroundTransparency = 1
            descLabel.Text = option.desc
            descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            descLabel.TextSize = 14
            descLabel.Font = Enum.Font.Gotham
            descLabel.Parent = passCard
            
            -- Add price
            local priceLabel = Instance.new("TextLabel")
            priceLabel.Name = "PriceLabel"
            priceLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
            priceLabel.Position = UDim2.new(0.5, 0, 0.45, 0)
            priceLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            priceLabel.BackgroundTransparency = 1
            priceLabel.Text = "Cost: " .. option.price
            priceLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
            priceLabel.TextSize = 16
            priceLabel.Font = Enum.Font.GothamSemibold
            priceLabel.Parent = passCard
            
            -- Add bonus info
            local bonusLabel = Instance.new("TextLabel")
            bonusLabel.Name = "BonusLabel"
            bonusLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
            bonusLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
            bonusLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            bonusLabel.BackgroundTransparency = 1
            bonusLabel.Text = "You earn: " .. option.bonus
            bonusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            bonusLabel.TextSize = 14
            bonusLabel.Font = Enum.Font.Gotham
            bonusLabel.Parent = passCard
            
            -- Add purchase button
            local purchaseButton = Instance.new("TextButton")
            purchaseButton.Name = "PurchaseButton"
            purchaseButton.Size = UDim2.new(0.8, 0, 0.15, 0)
            purchaseButton.Position = UDim2.new(0.5, 0, 0.8, 0)
            purchaseButton.AnchorPoint = Vector2.new(0.5, 0.5)
            purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            purchaseButton.Text = "Create Pass"
            purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            purchaseButton.TextSize = 14
            purchaseButton.Font = Enum.Font.GothamSemibold
            purchaseButton.Parent = passCard
            
            -- Add corner radius to button
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 6)
            buttonCorner.Parent = purchaseButton
            
            -- Connect purchase button (placeholder)
            purchaseButton.MouseButton1Click:Connect(function()
                print("Creating " .. option.name)
            end)
        end
        
        -- Add help text
        local helpLabel = Instance.new("TextLabel")
        helpLabel.Name = "HelpLabel"
        helpLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
        helpLabel.Position = UDim2.new(0.5, 0, 0.9, 0)
        helpLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        helpLabel.BackgroundTransparency = 1
        helpLabel.Text = "Guest passes can be shared with friends. You'll earn a bonus when they visit your gym!"
        helpLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        helpLabel.TextSize = 14
        helpLabel.Font = Enum.Font.Gotham
        helpLabel.TextWrapped = true
        helpLabel.Parent = mainFrame
        
        -- Connect close button
        closeButton.MouseButton1Click:Connect(function()
            gui.Enabled = false
        end)
    end
    
    return gui
end

-- Module implementation
local GuestPassUI = {}

-- Toggles the UI visibility
function GuestPassUI:ToggleUI()
    local gui = getOrCreateGui()
    gui.Enabled = not gui.Enabled
    
    -- Log action for debugging
    print("GuestPassUI " .. (gui.Enabled and "shown" or "hidden"))
    
    return gui.Enabled
end

-- Shows the UI
function GuestPassUI:ShowUI()
    local gui = getOrCreateGui()
    gui.Enabled = true
    
    -- Log action for debugging
    print("GuestPassUI shown")
    
    return true
end

-- Hides the UI
function GuestPassUI:HideUI()
    local gui = getOrCreateGui()
    gui.Enabled = false
    
    -- Log action for debugging
    print("GuestPassUI hidden")
    
    return true
end

-- Initialize the UI
getOrCreateGui()

-- Return the module
return GuestPassUI
