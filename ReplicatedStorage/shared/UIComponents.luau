--[[
    UIComponents.luau
    
    Core UI component library for creating user interface elements.
    This module provides a clean way to create and manage UI components.
    
    Created: April 30, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Try to load our dependencies
local SafeRequire = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("SafeRequire"))

-- Make sure we're on the client
if not RunService:IsClient() then
    warn("[UIComponents] UIComponents should only be used on the client")
    return {
        CreateButton = function() return nil end,
        CreateWindow = function() return nil end
    }
end

-- Try to get ClientRegistry
local function getClientRegistry()
    local player = Players.LocalPlayer
    if not player then return nil end
    
    local PlayerScripts = player:FindFirstChild("PlayerScripts")
    if not PlayerScripts then return nil end
    
    -- Try to find ClientRegistry module using SafeRequire
    local clientRegistry = SafeRequire.requireFromPath("ClientRegistry")
    if clientRegistry then
        return clientRegistry
    end
    
    -- Fallback: try to find ClientRegistry module
    local searchPaths = {
        PlayerScripts:FindFirstChild("src") and PlayerScripts.src:FindFirstChild("client"),
        PlayerScripts:FindFirstChild("Core"),
        PlayerScripts,
        ReplicatedStorage:FindFirstChild("shared")
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild("ClientRegistry")
            if module and module:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(module)
                end)
                
                if success and result then
                    return result
                end
            end
        end
    end
    
    return nil
end

local UIComponents = {}

-- Debug logging
local DEBUG_ENABLED = true
local function log(message)
    if not DEBUG_ENABLED then return end
    print("[UIComponents] " .. message)
end

-- Create a button with the given text and callback
function UIComponents.CreateButton(text, callback, parent, props)
    log("Creating button: " .. text)
    
    -- Create the button
    local button = Instance.new("TextButton")
    button.Name = "Button_" .. text:gsub("%s+", "_")
    button.Text = text
    button.Size = UDim2.new(0, 200, 0, 50)
    button.Position = UDim2.new(0.5, -100, 0.5, -25)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 18
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = button
    
    -- Apply custom properties if provided
    if props then
        for propName, propValue in pairs(props) do
            pcall(function() button[propName] = propValue end)
        end
    end
    
    -- Connect the callback
    if callback then
        button.Activated:Connect(callback)
    end
    
    -- Parent the button
    if parent then
        button.Parent = parent
    end
    
    return button
end

-- Create a window with the given title
function UIComponents.CreateWindow(title, size, position)
    log("Creating window: " .. title)
    
    -- Create the main frame
    local window = Instance.new("Frame")
    window.Name = "Window_" .. title:gsub("%s+", "_")
    window.Size = size or UDim2.new(0, 400, 0, 300)
    window.Position = position or UDim2.new(0.5, -200, 0.5, -150)
    window.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    window.BorderSizePixel = 0
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = window
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = window
    
    -- Add rounded corners to title bar (top only)
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    -- Create title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Text = title
    titleText.Size = UDim2.new(1, -20, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.BackgroundTransparency = 1
    titleText.Parent = titleBar
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Text = "X"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    -- Add rounded corners to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = closeButton
    
    -- Connect close button
    closeButton.Activated:Connect(function()
        window:Destroy()
    end)
    
    -- Create content frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -50)
    content.Position = UDim2.new(0, 10, 0, 45)
    content.BackgroundTransparency = 1
    content.Parent = window
    
    -- Make window draggable
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    RunService:BindToRenderStep("DragWindow", 1000, function()
        if dragging and dragInput then
            update(dragInput)
        end
    end)
    
    return window, content
end

-- Register with ClientRegistry if available
local ClientRegistry = getClientRegistry()
if ClientRegistry then
    ClientRegistry:Register("UIComponents", UIComponents)
    log("Registered with ClientRegistry")
else
    warn("[UIComponents] Could not find ClientRegistry")
end

return UIComponents
