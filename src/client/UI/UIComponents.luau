--[[
    UIComponents.luau
    
    Provides UI components for the game's user interface.
    Fixed as part of critical fixes implementation April 2025.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIComponents = {}

-- Try to get AssetValidator
local AssetValidator
local assetValidatorPath = ReplicatedStorage.shared and ReplicatedStorage.shared:FindFirstChild("AssetValidator")
if assetValidatorPath and assetValidatorPath:IsA("ModuleScript") then
    local success, result = pcall(function()
        return require(assetValidatorPath)
    end)
    
    if success then
        AssetValidator = result
    else
        warn("[UIComponents] Failed to require AssetValidator:", result)
    end
end

-- Create a button component
function UIComponents.CreateButton(config)
    config = config or {}
    
    -- Create button
    local button = Instance.new("TextButton")
    button.Name = config.name or "Button"
    button.Size = config.size or UDim2.new(0, 200, 0, 50)
    button.Position = config.position or UDim2.new(0.5, 0, 0.5, 0)
    button.AnchorPoint = config.anchorPoint or Vector2.new(0.5, 0.5)
    button.BackgroundColor3 = config.backgroundColor or Color3.fromRGB(48, 48, 200)
    button.BorderSizePixel = config.borderSizePixel or 0
    button.Font = config.font or Enum.Font.SourceSansBold
    button.Text = config.text or "Button"
    button.TextColor3 = config.textColor or Color3.fromRGB(255, 255, 255)
    button.TextSize = config.textSize or 18
    
    -- Add corner radius if requested
    if config.cornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, config.cornerRadius)
        corner.Parent = button
    end
    
    -- Add hover effects
    if config.useHoverEffect ~= false then
        local defaultColor = button.BackgroundColor3
        local hoverColor = config.hoverColor or Color3.fromRGB(58, 58, 220)
        
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = hoverColor
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = defaultColor
        end)
    end
    
    -- Add click effect
    if config.useClickEffect ~= false then
        button.MouseButton1Down:Connect(function()
            -- Scale down button slightly
            button:TweenSize(
                UDim2.new(button.Size.X.Scale * 0.95, button.Size.X.Offset * 0.95, 
                           button.Size.Y.Scale * 0.95, button.Size.Y.Offset * 0.95),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.1,
                true
            )
        end)
        
        button.MouseButton1Up:Connect(function()
            -- Return to original size
            button:TweenSize(
                UDim2.new(button.Size.X.Scale / 0.95, button.Size.X.Offset / 0.95, 
                           button.Size.Y.Scale / 0.95, button.Size.Y.Offset / 0.95),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.1,
                true
            )
        end)
    end
    
    -- Connect callback
    if config.callback and type(config.callback) == "function" then
        button.MouseButton1Click:Connect(config.callback)
    end
    
    -- Add to parent if specified
    if config.parent then
        button.Parent = config.parent
    end
    
    -- Validate button image if it has one and AssetValidator is available
    if config.image and AssetValidator then
        -- Set image
        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Name = "ButtonImage"
        imageLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
        imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = config.image
        imageLabel.Parent = button
        
        -- Validate image
        if AssetValidator.validateAsset then
            AssetValidator.validateAsset(imageLabel, {
                source = "UIComponents.CreateButton",
                suppressErrors = true
            })
        end
    end
    
    return button
end

-- Create a frame with standard styling
function UIComponents.CreateFrame(config)
    config = config or {}
    
    -- Create frame
    local frame = Instance.new("Frame")
    frame.Name = config.name or "Frame"
    frame.Size = config.size or UDim2.new(0, 400, 0, 300)
    frame.Position = config.position or UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = config.anchorPoint or Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = config.backgroundColor or Color3.fromRGB(36, 36, 36)
    frame.BorderSizePixel = config.borderSizePixel or 0
    
    -- Add corner radius if requested
    if config.cornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, config.cornerRadius)
        corner.Parent = frame
    end
    
    -- Add to parent if specified
    if config.parent then
        frame.Parent = config.parent
    end
    
    return frame
end

-- Create a text label with standard styling
function UIComponents.CreateLabel(config)
    config = config or {}
    
    -- Create label
    local label = Instance.new("TextLabel")
    label.Name = config.name or "Label"
    label.Size = config.size or UDim2.new(0, 200, 0, 50)
    label.Position = config.position or UDim2.new(0.5, 0, 0.5, 0)
    label.AnchorPoint = config.anchorPoint or Vector2.new(0.5, 0.5)
    label.BackgroundTransparency = config.backgroundTransparency or 1
    label.BackgroundColor3 = config.backgroundColor or Color3.fromRGB(36, 36, 36)
    label.BorderSizePixel = config.borderSizePixel or 0
    label.Font = config.font or Enum.Font.SourceSans
    label.Text = config.text or "Label"
    label.TextColor3 = config.textColor or Color3.fromRGB(255, 255, 255)
    label.TextSize = config.textSize or 14
    label.TextWrapped = config.textWrapped or false
    
    -- Add to parent if specified
    if config.parent then
        label.Parent = config.parent
    end
    
    return label
end

-- Create a simple dialog
function UIComponents.CreateDialog(config)
    config = config or {}
    
    -- Create main frame
    local dialog = UIComponents.CreateFrame({
        name = config.name or "Dialog",
        size = config.size or UDim2.new(0, 400, 0, 200),
        backgroundColor = config.backgroundColor or Color3.fromRGB(36, 36, 36),
        cornerRadius = config.cornerRadius or 8,
        parent = config.parent
    })
    
    -- Add title
    local title = UIComponents.CreateLabel({
        name = "Title",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 0),
        anchorPoint = Vector2.new(0, 0),
        text = config.title or "Dialog",
        font = Enum.Font.SourceSansBold,
        textSize = 18,
        parent = dialog
    })
    
    -- Add message
    local message = UIComponents.CreateLabel({
        name = "Message",
        size = UDim2.new(1, -40, 1, -100),
        position = UDim2.new(0.5, 0, 0, 60),
        anchorPoint = Vector2.new(0.5, 0),
        text = config.message or "",
        textWrapped = true,
        parent = dialog
    })
    
    -- Add button(s)
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, 40)
    buttonContainer.Position = UDim2.new(0, 0, 1, -50)
    buttonContainer.AnchorPoint = Vector2.new(0, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = dialog
    
    -- Add OK button by default
    local button = UIComponents.CreateButton({
        name = "OkButton",
        size = UDim2.new(0, 120, 0, 30),
        position = UDim2.new(0.5, 0, 0, 0),
        text = config.buttonText or "OK",
        callback = config.callback,
        parent = buttonContainer
    })
    
    -- Return the dialog and components
    return {
        dialog = dialog,
        title = title,
        message = message,
        button = button
    }
end

-- Initialize the module
local function initialize()
    print("[UIComponents] Initialized successfully")
end

-- Run initialization
initialize()

return UIComponents
