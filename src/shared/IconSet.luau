--[[
    IconSet.luau
    
    A centralized module for accessing game icons consistently throughout the UI.
    Contains references to all standardized icon asset IDs and helper functions.
    
    Author: Updated April 2025
]]

local IconSet = {}

-- Core icon asset IDs from design document
IconSet.AssetIds = {
    Alliance = "rbxassetid://128203268160479",
    CommunityGoals = "rbxassetid://97149848004338",
    Challenges = "rbxassetid://120333480860384",
    GuestPass = "rbxassetid://110319251186892",
    Tutorial = "rbxassetid://98150393120956",
    Settings = "rbxassetid://72876573893033",
    Rebirth = "rbxassetid://129409029383961",
    StaffManagement = "rbxassetid://89834599810886",
    Upgrades = "rbxassetid://132635366103906",
    Achievements = "rbxassetid://79337595530955",
    AdminFunctions = "rbxassetid://105112405426846",
    
    -- Additional common icons
    Close = "rbxassetid://9307168228", -- X icon
    Coin = "rbxassetid://9288186583", -- Money/currency icon
    Star = "rbxassetid://9288554951", -- Star for ratings/achievements
    Heart = "rbxassetid://9288185223", -- Health/satisfaction
    User = "rbxassetid://9288196653", -- User/profile
    Clock = "rbxassetid://9288187455", -- Time/duration
    Calendar = "rbxassetid://9288192475", -- Events/schedule
    Leaderboard = "rbxassetid://9288190136", -- Rankings
    Trophy = "rbxassetid://9288198124", -- Victories/competitions
    Gear = "rbxassetid://9288189061", -- Settings alternative
    Info = "rbxassetid://9288189848", -- Information
    Warning = "rbxassetid://9288198975", -- Warning icon
    Error = "rbxassetid://9288187809", -- Error icon
    Check = "rbxassetid://9288193052", -- Checkmark/success
    ArrowUp = "rbxassetid://9288189346", -- Arrow pointing up
    ArrowDown = "rbxassetid://9288188451", -- Arrow pointing down
    Play = "rbxassetid://9288193830", -- Play button
    Pause = "rbxassetid://9288192900", -- Pause button
    Question = "rbxassetid://9288194701", -- Question mark / help
    Lock = "rbxassetid://9288191212", -- Lock icon for permissions
    Unlock = "rbxassetid://9288198345", -- Unlock icon
    Add = "rbxassetid://9288184486", -- Plus icon
    Remove = "rbxassetid://9288194902", -- Minus icon
    Edit = "rbxassetid://9288187043", -- Pencil/edit icon
}

-- Button icon mapping for UI features from design document
IconSet.ButtonIcons = {
    -- Main menu section
    Play = IconSet.AssetIds.Play,
    Alliance = IconSet.AssetIds.Alliance,
    Specialization = IconSet.AssetIds.StaffManagement,
    SeasonalEvents = IconSet.AssetIds.Calendar,
    Settings = IconSet.AssetIds.Settings,
    Minigames = IconSet.AssetIds.Challenges,
    
    -- Rebirth section
    Rebirth = IconSet.AssetIds.Rebirth,
    
    -- General buttons
    Tutorial = IconSet.AssetIds.Tutorial,
    Reset = IconSet.AssetIds.Warning,
    Confirm = IconSet.AssetIds.Check,
    Cancel = IconSet.AssetIds.Close,
    Close = IconSet.AssetIds.Close,
    
    -- Alliance buttons
    JoinAlliance = IconSet.AssetIds.Alliance,
    LeaveAlliance = IconSet.AssetIds.Remove,
    ViewAllianceInfo = IconSet.AssetIds.Info,
    
    -- Seasonal event buttons
    JoinEvent = IconSet.AssetIds.Calendar,
    LeaveEvent = IconSet.AssetIds.Remove,
}

-- Creates an ImageLabel with the specified icon
function IconSet.createIcon(iconName, size, position)
    -- Default to settings icon if the requested icon doesn't exist
    local iconAssetId = IconSet.AssetIds[iconName] or IconSet.AssetIds.Settings

    local icon = Instance.new("ImageLabel")
    icon.Name = iconName .. "Icon"
    icon.Size = size or UDim2.new(0, 24, 0, 24)
    icon.Position = position or UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Image = iconAssetId
    icon.ScaleType = Enum.ScaleType.Fit
    
    return icon
end

-- Creates a button with an icon
function IconSet.createIconButton(iconName, text, size, position, callback)
    local button = Instance.new("TextButton")
    button.Name = iconName .. "Button"
    button.Size = size or UDim2.new(0, 120, 0, 40)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    button.BorderSizePixel = 0
    button.Text = text or ""
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    -- Add padding if text is provided
    if text and text ~= "" then
        button.Text = "    " .. text
        button.TextXAlignment = Enum.TextXAlignment.Left
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 35)
        padding.Parent = button
    end
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add the icon
    local iconAssetId = IconSet.AssetIds[iconName] or IconSet.AssetIds.Settings
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 10, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = iconAssetId
    icon.Parent = button
    
    -- Connect callback if provided
    if callback and typeof(callback) == "function" then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

-- Add an icon to an existing button
function IconSet.addIconToButton(button, iconName)
    if not button then return end
    
    local iconAssetId = IconSet.AssetIds[iconName] or IconSet.AssetIds.Settings
    
    -- Add padding to text for icon
    if button:IsA("TextButton") or button:IsA("TextLabel") then
        button.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Add padding if not already present
        if not button:FindFirstChild("UIPadding") then
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 35)
            padding.Parent = button
        end
        
        -- Create icon
        local icon = button:FindFirstChild("Icon") or Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0, 10, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = iconAssetId
        icon.Parent = button
    end
    
    return button
end

-- Creates a standardized icon display with label
function IconSet.createIconWithLabel(iconName, labelText, size, position, isHorizontal)
    local container = Instance.new("Frame")
    container.Name = iconName .. "Container"
    container.Size = size or UDim2.new(0, 200, 0, 40)
    container.Position = position or UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    
    local iconAssetId = IconSet.AssetIds[iconName] or IconSet.AssetIds.Settings
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.BackgroundTransparency = 1
    icon.Image = iconAssetId
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = labelText or ""
    
    -- Arrange elements based on orientation
    if isHorizontal then
        icon.Size = UDim2.new(0, 24, 0, 24)
        icon.Position = UDim2.new(0, 0, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        
        label.Size = UDim2.new(1, -32, 1, 0) 
        label.Position = UDim2.new(0, 32, 0, 0)
        label.TextXAlignment = Enum.TextXAlignment.Left
    else
        icon.Size = UDim2.new(0, 32, 0, 32)
        icon.Position = UDim2.new(0.5, 0, 0, 0)
        icon.AnchorPoint = Vector2.new(0.5, 0)
        
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, 36)
        label.TextXAlignment = Enum.TextXAlignment.Center
    end
    
    icon.Parent = container
    label.Parent = container
    
    return container
end

-- Get the asset ID for a specific icon
function IconSet.getAssetId(iconName)
    return IconSet.AssetIds[iconName] or IconSet.AssetIds.Settings
end

return IconSet