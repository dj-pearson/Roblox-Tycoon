-- UIComponentsFallback.luau
-- A fallback implementation of the UIComponents module
-- Created: April 30, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player and player:FindFirstChild("PlayerGui")

local UIComponentsFallback = {
    initialized = false,
    DEBUG = true
}

-- Simple logging function
local function log(message, level)
    if not UIComponentsFallback.DEBUG and level ~= "Error" then return end
    
    local prefix = "[UIComponentsFallback]"
    if level == "Error" then
        warn(prefix .. " " .. message)
    elseif level == "Success" then
        print(prefix .. " ✓ " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Fallback implementation of CreateButton
function UIComponentsFallback:CreateButton(properties)
    properties = properties or {}
    
    local button = Instance.new("TextButton")
    button.Size = properties.Size or UDim2.new(0, 200, 0, 50)
    button.Position = properties.Position or UDim2.new(0.5, -100, 0.5, -25)
    button.Text = properties.Text or "Button"
    button.BackgroundColor3 = properties.BackgroundColor3 or Color3.fromRGB(0, 120, 215)
    button.TextColor3 = properties.TextColor3 or Color3.fromRGB(255, 255, 255)
    button.Font = properties.Font or Enum.Font.SourceSansBold
    button.TextSize = properties.TextSize or 18
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.AnchorPoint = properties.AnchorPoint or Vector2.new(0.5, 0.5)
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add a hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.new(
            button.BackgroundColor3.R * 0.9,
            button.BackgroundColor3.G * 0.9,
            button.BackgroundColor3.B * 0.9
        )
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = properties.BackgroundColor3 or Color3.fromRGB(0, 120, 215)
    end)
    
    -- Handle parent
    if properties.Parent then
        button.Parent = properties.Parent
    end
    
    -- Handle click callback
    if typeof(properties.OnClick) == "function" then
        button.MouseButton1Click:Connect(properties.OnClick)
    end
    
    log("Created fallback button")
    return button
end

-- Fallback implementation of CreateText
function UIComponentsFallback:CreateText(properties)
    properties = properties or {}
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = properties.Size or UDim2.new(0, 200, 0, 50)
    textLabel.Position = properties.Position or UDim2.new(0.5, -100, 0.5, -25)
    textLabel.Text = properties.Text or "Text"
    textLabel.BackgroundTransparency = properties.BackgroundTransparency or 1
    textLabel.TextColor3 = properties.TextColor3 or Color3.fromRGB(255, 255, 255)
    textLabel.Font = properties.Font or Enum.Font.SourceSans
    textLabel.TextSize = properties.TextSize or 18
    textLabel.AnchorPoint = properties.AnchorPoint or Vector2.new(0.5, 0.5)
    textLabel.TextXAlignment = properties.TextXAlignment or Enum.TextXAlignment.Center
    textLabel.TextYAlignment = properties.TextYAlignment or Enum.TextYAlignment.Center
    
    -- Handle parent
    if properties.Parent then
        textLabel.Parent = properties.Parent
    end
    
    log("Created fallback text")
    return textLabel
end

-- Fallback implementation of CreateFrame
function UIComponentsFallback:CreateFrame(properties)
    properties = properties or {}
    
    local frame = Instance.new("Frame")
    frame.Size = properties.Size or UDim2.new(0, 300, 0, 200)
    frame.Position = properties.Position or UDim2.new(0.5, -150, 0.5, -100)
    frame.BackgroundColor3 = properties.BackgroundColor3 or Color3.fromRGB(45, 45, 45)
    frame.BorderSizePixel = 0
    frame.AnchorPoint = properties.AnchorPoint or Vector2.new(0.5, 0.5)
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Handle parent
    if properties.Parent then
        frame.Parent = properties.Parent
    end
    
    log("Created fallback frame")
    return frame
end

-- Fallback implementation of CreateScreenGui
function UIComponentsFallback:CreateScreenGui(properties)
    if not playerGui then
        log("PlayerGui not found, cannot create ScreenGui", "Error")
        return nil
    end
    
    properties = properties or {}
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = properties.Name or "FallbackUI"
    screenGui.ResetOnSpawn = properties.ResetOnSpawn or false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = properties.IgnoreGuiInset or false
    
    -- Handle parent
    screenGui.Parent = properties.Parent or playerGui
    
    log("Created fallback ScreenGui")
    return screenGui
end

-- Fallback implementation of CreateImage
function UIComponentsFallback:CreateImage(properties)
    properties = properties or {}
    
    local image = Instance.new("ImageLabel")
    image.Size = properties.Size or UDim2.new(0, 100, 0, 100)
    image.Position = properties.Position or UDim2.new(0.5, -50, 0.5, -50)
    image.BackgroundTransparency = 1
    image.Image = properties.Image or "rbxassetid://0"
    image.ScaleType = properties.ScaleType or Enum.ScaleType.Stretch
    image.AnchorPoint = properties.AnchorPoint or Vector2.new(0.5, 0.5)
    
    -- Handle parent
    if properties.Parent then
        image.Parent = properties.Parent
    end
    
    log("Created fallback image")
    return image
end

-- Initialize module
function UIComponentsFallback:initialize()
    if self.initialized then
        return
    end
    
    log("Initializing UIComponentsFallback")
    
    -- Register with ClientRegistry if available
    local ClientRegistry = nil
    
    -- First try direct requiring
    local success, result = pcall(function()
        return require(script.Parent.Parent:FindFirstChild("ClientRegistry"))
    end)
    
    if success and result then
        ClientRegistry = result
    else
        -- Try to find in other places
        local player = Players.LocalPlayer
        local PlayerScripts = player and player:FindFirstChild("PlayerScripts")
        
        if PlayerScripts and PlayerScripts:FindFirstChild("ClientRegistry") then
            ClientRegistry = require(PlayerScripts.ClientRegistry)
        elseif ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ClientRegistry") then
            ClientRegistry = require(ReplicatedStorage.shared.ClientRegistry)
        end
    end
    
    if ClientRegistry and typeof(ClientRegistry.Register) == "function" then
        ClientRegistry:Register("UIComponents", self)
        log("Registered with ClientRegistry", "Success")
    else
        log("ClientRegistry not found, could not register", "Error")
    end
    
    self.initialized = true
    log("UIComponentsFallback initialized", "Success")
    return true
end

-- Get a specific interface for the client
function UIComponentsFallback:getClientInterface()
    return self
end

-- Initialize on require
task.spawn(function()
    UIComponentsFallback:initialize()
end)

return UIComponentsFallback
