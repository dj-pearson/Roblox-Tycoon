--!strict
--[[
    AssetHealthDashboard.client.luau
    
    A client-side dashboard for monitoring asset health
    
    Created: April 25, 2025
    
    This module:
    1. Provides a UI dashboard for viewing asset loading failures
    2. Offers tools to validate and fix problematic assets
    3. Monitors asset loading performance
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[AssetHealthDashboard] No LocalPlayer found, waiting...")
    repeat
        task.wait(0.1)
        LocalPlayer = Players.LocalPlayer
    until LocalPlayer or not RunService:IsRunning()
    
    if not LocalPlayer then
        warn("[AssetHealthDashboard] Failed to find LocalPlayer")
        return
    end
end

-- Find shared folder
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    warn("[AssetHealthDashboard] Shared folder not found")
    return
end

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn("[AssetHealthDashboard] Failed to require module: ", module:GetFullName())
        return nil
    end
    
    return result
end

-- Try to get AssetValidator
local AssetValidator = requireSafely(sharedFolder:FindFirstChild("AssetValidator"))
if not AssetValidator then
    warn("[AssetHealthDashboard] AssetValidator module not found")
    return
end

-- Try to get ClientRegistry
local ClientRegistry = nil
local clientRegistryModule = nil

-- Try to find in PlayerScripts
if LocalPlayer and LocalPlayer.PlayerScripts then
    if LocalPlayer.PlayerScripts:FindFirstChild("Client") and 
       LocalPlayer.PlayerScripts.Client:FindFirstChild("Core") and
       LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistry") then
        clientRegistryModule = LocalPlayer.PlayerScripts.Client.Core.ClientRegistry
    end
end

-- Try to find in shared folder
if not clientRegistryModule and sharedFolder:FindFirstChild("ClientRegistry") then
    clientRegistryModule = sharedFolder.ClientRegistry
end

-- Try to require if found
if clientRegistryModule then
    ClientRegistry = requireSafely(clientRegistryModule)
end

-- Asset Health Dashboard Module
local AssetHealthDashboard = {
    isOpen = false,
    gui = nil,
    refreshInterval = 10,
    autoRefresh = false,
    monitoringEnabled = false,
    problemAssets = {},
    assetFixers = {},
    initialized = false
}

-- Asset Type Detection
local assetTypeDetectors = {
    -- Check if asset is an image
    isImage = function(assetId)
        local success = pcall(function()
            local tempImage = Instance.new("ImageLabel")
            tempImage.Image = assetId
            tempImage:GetPropertyChangedSignal("IsLoaded"):Wait()
            tempImage:Destroy()
        end)
        return success
    end,
    
    -- Check if asset is a sound
    isSound = function(assetId)
        local success = pcall(function()
            local tempSound = Instance.new("Sound")
            tempSound.SoundId = assetId
            -- No good way to check if loaded, just assume it is
        end)
        return success
    end,
    
    -- Check if asset is an animation
    isAnimation = function(assetId)
        local success = pcall(function()
            local tempAnim = Instance.new("Animation")
            tempAnim.AnimationId = assetId
            -- No good way to check if loaded, just assume it is
        end)
        return success
    end,
    
    -- Detect likely type from asset ID
    detectAssetType = function(assetId)
        local id = assetId
        if string.match(id, "rbxassetid://") then
            id = string.match(id, "rbxassetid://(%d+)")
        end
        id = tonumber(id) or 0
        
        -- Check common ID ranges (approximate)
        if id >= 3000000000 and id <= 7000000000 then
            return "Image" -- Common range for images
        elseif id >= 1000000 and id <= 2000000 then
            return "Sound" -- Common range for sounds
        elseif id >= 500000 and id <= 999999 then
            return "Animation" -- Common range for animations
        else
            return "Unknown"
        end
    end
}

-- Get asset type either from cache or by detection
local function getAssetType(assetId)
    -- Try to determine from problematic assets list first
    for _, problemAsset in pairs(AssetHealthDashboard.problemAssets) do
        if problemAsset.id == assetId then
            return problemAsset.assetType
        end
    end
    
    -- Otherwise try to detect
    return assetTypeDetectors.detectAssetType(assetId)
end

-- Register an asset fixer function
function AssetHealthDashboard.registerAssetFixer(assetType, fixerFunction)
    AssetHealthDashboard.assetFixers[assetType] = fixerFunction
end

-- Add default asset fixers
do
    -- Generic image fixer (returns a placeholder)
    AssetHealthDashboard.registerAssetFixer("Image", function(assetId)
        return AssetValidator.fallbackAssets.Image
    end)
    
    -- Generic sound fixer
    AssetHealthDashboard.registerAssetFixer("Sound", function(assetId)
        return AssetValidator.fallbackAssets.Sound
    end)
    
    -- Generic animation fixer
    AssetHealthDashboard.registerAssetFixer("Animation", function(assetId)
        return AssetValidator.fallbackAssets.Animation
    end)
end

-- Create the dashboard UI
function AssetHealthDashboard.createDashboardGUI()
    if AssetHealthDashboard.gui then
        AssetHealthDashboard.gui:Destroy()
    end
    
    -- Create a new dashboard using AssetValidator's health dashboard
    AssetHealthDashboard.gui = AssetValidator.createAssetHealthDashboard()
    AssetHealthDashboard.isOpen = true
    
    -- Add the asset fixer section
    AssetHealthDashboard.addAssetFixerSection()
    
    return AssetHealthDashboard.gui
end

-- Open the dashboard
function AssetHealthDashboard.open()
    if not AssetHealthDashboard.gui or not AssetHealthDashboard.gui.Parent then
        AssetHealthDashboard.createDashboardGUI()
    else
        AssetHealthDashboard.gui.Enabled = true
        AssetHealthDashboard.isOpen = true
    end
end

-- Close the dashboard
function AssetHealthDashboard.close()
    if AssetHealthDashboard.gui then
        AssetHealthDashboard.gui.Enabled = false
    end
    AssetHealthDashboard.isOpen = false
end

-- Toggle the dashboard
function AssetHealthDashboard.toggle()
    if AssetHealthDashboard.isOpen then
        AssetHealthDashboard.close()
    else
        AssetHealthDashboard.open()
    end
end

-- Add asset fixer section to dashboard
function AssetHealthDashboard.addAssetFixerSection()
    if not AssetHealthDashboard.gui then return end
    
    local mainGui = AssetHealthDashboard.gui
    local mainFrame = mainGui:FindFirstChild("MainFrame")
    if not mainFrame then return end
    
    -- Create the fixer tab
    local fixerTab = Instance.new("Frame")
    fixerTab.Name = "FixerTab"
    fixerTab.Size = UDim2.new(1, 0, 1, 0)
    fixerTab.BackgroundTransparency = 1
    fixerTab.Visible = false
    fixerTab.Parent = mainFrame
    
    -- Create fixer header
    local fixerHeader = Instance.new("TextLabel")
    fixerHeader.Name = "FixerHeader"
    fixerHeader.Size = UDim2.new(1, -20, 0, 40)
    fixerHeader.Position = UDim2.new(0, 10, 0, 10)
    fixerHeader.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    fixerHeader.Font = Enum.Font.GothamBold
    fixerHeader.TextSize = 18
    fixerHeader.TextColor3 = Color3.new(1, 1, 1)
    fixerHeader.Text = "Asset Fixer"
    fixerHeader.TextXAlignment = Enum.TextXAlignment.Left
    fixerHeader.BorderSizePixel = 0
    fixerHeader.Parent = fixerTab
    
    -- Add padding
    local headerPadding = Instance.new("UIPadding")
    headerPadding.PaddingLeft = UDim.new(0, 10)
    headerPadding.Parent = fixerHeader
    
    -- Add corner to header
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 6)
    headerCorner.Parent = fixerHeader
    
    -- Create asset ID input
    local assetIdLabel = Instance.new("TextLabel")
    assetIdLabel.Name = "AssetIdLabel"
    assetIdLabel.Size = UDim2.new(0, 100, 0, 30)
    assetIdLabel.Position = UDim2.new(0, 10, 0, 60)
    assetIdLabel.BackgroundTransparency = 1
    assetIdLabel.Font = Enum.Font.GothamMedium
    assetIdLabel.TextSize = 14
    assetIdLabel.TextColor3 = Color3.new(1, 1, 1)
    assetIdLabel.Text = "Asset ID:"
    assetIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    assetIdLabel.Parent = fixerTab
    
    local assetIdInput = Instance.new("TextBox")
    assetIdInput.Name = "AssetIdInput"
    assetIdInput.Size = UDim2.new(0.7, -120, 0, 30)
    assetIdInput.Position = UDim2.new(0, 110, 0, 60)
    assetIdInput.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    assetIdInput.Font = Enum.Font.Gotham
    assetIdInput.TextSize = 14
    assetIdInput.TextColor3 = Color3.new(1, 1, 1)
    assetIdInput.PlaceholderText = "Enter asset ID (e.g., rbxassetid://123456789)"
    assetIdInput.Text = ""
    assetIdInput.ClearTextOnFocus = false
    assetIdInput.Parent = fixerTab
    
    -- Add corner to input
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = assetIdInput
    
    -- Create asset type dropdown
    local assetTypeLabel = Instance.new("TextLabel")
    assetTypeLabel.Name = "AssetTypeLabel"
    assetTypeLabel.Size = UDim2.new(0, 100, 0, 30)
    assetTypeLabel.Position = UDim2.new(0, 10, 0, 100)
    assetTypeLabel.BackgroundTransparency = 1
    assetTypeLabel.Font = Enum.Font.GothamMedium
    assetTypeLabel.TextSize = 14
    assetTypeLabel.TextColor3 = Color3.new(1, 1, 1)
    assetTypeLabel.Text = "Asset Type:"
    assetTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
    assetTypeLabel.Parent = fixerTab
    
    local assetTypeDropdown = Instance.new("TextButton")
    assetTypeDropdown.Name = "AssetTypeDropdown"
    assetTypeDropdown.Size = UDim2.new(0, 150, 0, 30)
    assetTypeDropdown.Position = UDim2.new(0, 110, 0, 100)
    assetTypeDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    assetTypeDropdown.Font = Enum.Font.Gotham
    assetTypeDropdown.TextSize = 14
    assetTypeDropdown.TextColor3 = Color3.new(1, 1, 1)
    assetTypeDropdown.Text = "Image"
    assetTypeDropdown.Parent = fixerTab
    
    -- Add corner to dropdown
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 6)
    dropdownCorner.Parent = assetTypeDropdown
    
    -- Create dropdown menu
    local dropdownMenu = Instance.new("Frame")
    dropdownMenu.Name = "DropdownMenu"
    dropdownMenu.Size = UDim2.new(0, 150, 0, 120)
    dropdownMenu.Position = UDim2.new(0, 110, 0, 130)
    dropdownMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    dropdownMenu.BorderSizePixel = 0
    dropdownMenu.Visible = false
    dropdownMenu.ZIndex = 10
    dropdownMenu.Parent = fixerTab
    
    -- Add corner to menu
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 6)
    menuCorner.Parent = dropdownMenu
    
    -- Create dropdown options
    local assetTypes = {"Image", "Sound", "Animation", "Mesh", "Texture", "Icon", "Logo", "UI"}
    local optionHeight = 30
    
    for i, assetType in ipairs(assetTypes) do
        local option = Instance.new("TextButton")
        option.Name = assetType .. "Option"
        option.Size = UDim2.new(1, 0, 0, optionHeight)
        option.Position = UDim2.new(0, 0, 0, (i-1) * optionHeight)
        option.BackgroundTransparency = 0.9
        option.Font = Enum.Font.Gotham
        option.TextSize = 14
        option.TextColor3 = Color3.new(1, 1, 1)
        option.Text = assetType
        option.ZIndex = 11
        option.Parent = dropdownMenu
        
        -- Option selection
        option.MouseButton1Click:Connect(function()
            assetTypeDropdown.Text = assetType
            dropdownMenu.Visible = false
        end)
        
        -- Hover effect
        option.MouseEnter:Connect(function()
            option.BackgroundTransparency = 0.7
        end)
        
        option.MouseLeave:Connect(function()
            option.BackgroundTransparency = 0.9
        end)
    end
    
    -- Toggle dropdown menu
    assetTypeDropdown.MouseButton1Click:Connect(function()
        dropdownMenu.Visible = not dropdownMenu.Visible
    end)
    
    -- Create validate and fix buttons
    local validateButton = Instance.new("TextButton")
    validateButton.Name = "ValidateButton"
    validateButton.Size = UDim2.new(0, 120, 0, 40)
    validateButton.Position = UDim2.new(0, 110, 0, 150)
    validateButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
    validateButton.Font = Enum.Font.GothamMedium
    validateButton.TextSize = 14
    validateButton.TextColor3 = Color3.new(1, 1, 1)
    validateButton.Text = "Validate Asset"
    validateButton.Parent = fixerTab
    
    -- Add corner to validate button
    local validateCorner = Instance.new("UICorner")
    validateCorner.CornerRadius = UDim.new(0, 6)
    validateCorner.Parent = validateButton
    
    local fixButton = Instance.new("TextButton")
    fixButton.Name = "FixButton"
    fixButton.Size = UDim2.new(0, 120, 0, 40)
    fixButton.Position = UDim2.new(0, 240, 0, 150)
    fixButton.BackgroundColor3 = Color3.fromRGB(40, 180, 100)
    fixButton.Font = Enum.Font.GothamMedium
    fixButton.TextSize = 14
    fixButton.TextColor3 = Color3.new(1, 1, 1)
    fixButton.Text = "Fix Asset"
    fixButton.Parent = fixerTab
    
    -- Add corner to fix button
    local fixCorner = Instance.new("UICorner")
    fixCorner.CornerRadius = UDim.new(0, 6)
    fixCorner.Parent = fixButton
    
    -- Create result display
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(1, -20, 0, 120)
    resultFrame.Position = UDim2.new(0, 10, 0, 200)
    resultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    resultFrame.Parent = fixerTab
    
    -- Add corner to result frame
    local resultCorner = Instance.new("UICorner")
    resultCorner.CornerRadius = UDim.new(0, 6)
    resultCorner.Parent = resultFrame
    
    local resultTitle = Instance.new("TextLabel")
    resultTitle.Name = "ResultTitle"
    resultTitle.Size = UDim2.new(1, 0, 0, 30)
    resultTitle.BackgroundTransparency = 1
    resultTitle.Font = Enum.Font.GothamBold
    resultTitle.TextSize = 16
    resultTitle.TextColor3 = Color3.new(1, 1, 1)
    resultTitle.Text = "Validation Result"
    resultTitle.Parent = resultFrame
    
    local resultText = Instance.new("TextLabel")
    resultText.Name = "ResultText"
    resultText.Size = UDim2.new(1, -20, 0, 80)
    resultText.Position = UDim2.new(0, 10, 0, 30)
    resultText.BackgroundTransparency = 1
    resultText.Font = Enum.Font.Gotham
    resultText.TextSize = 14
    resultText.TextColor3 = Color3.fromRGB(200, 200, 200)
    resultText.Text = "Enter an asset ID and click Validate to check its status."
    resultText.TextWrapped = true
    resultText.TextXAlignment = Enum.TextXAlignment.Left
    resultText.TextYAlignment = Enum.TextYAlignment.Top
    resultText.Parent = resultFrame
    
    -- Create preview panel
    local previewLabel = Instance.new("TextLabel")
    previewLabel.Name = "PreviewLabel"
    previewLabel.Size = UDim2.new(0, 100, 0, 30)
    previewLabel.Position = UDim2.new(0, 10, 0, 330)
    previewLabel.BackgroundTransparency = 1
    previewLabel.Font = Enum.Font.GothamMedium
    previewLabel.TextSize = 14
    previewLabel.TextColor3 = Color3.new(1, 1, 1)
    previewLabel.Text = "Preview:"
    previewLabel.TextXAlignment = Enum.TextXAlignment.Left
    previewLabel.Parent = fixerTab
    
    local previewFrame = Instance.new("Frame")
    previewFrame.Name = "PreviewFrame"
    previewFrame.Size = UDim2.new(1, -20, 0, 150)
    previewFrame.Position = UDim2.new(0, 10, 0, 360)
    previewFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    previewFrame.Parent = fixerTab
    
    -- Add corner to preview frame
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 6)
    previewCorner.Parent = previewFrame
    
    -- Create image preview (default)
    local imagePreview = Instance.new("ImageLabel")
    imagePreview.Name = "ImagePreview"
    imagePreview.Size = UDim2.new(0, 128, 0, 128)
    imagePreview.Position = UDim2.new(0.5, -64, 0.5, -64)
    imagePreview.BackgroundTransparency = 1
    imagePreview.Image = ""
    imagePreview.Parent = previewFrame
    
    -- Create sound preview (initially hidden)
    local soundPreview = Instance.new("Frame")
    soundPreview.Name = "SoundPreview"
    soundPreview.Size = UDim2.new(1, -20, 0, 40)
    soundPreview.Position = UDim2.new(0, 10, 0.5, -20)
    soundPreview.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    soundPreview.Visible = false
    soundPreview.Parent = previewFrame
    
    -- Add corner to sound preview
    local soundPreviewCorner = Instance.new("UICorner")
    soundPreviewCorner.CornerRadius = UDim.new(0, 6)
    soundPreviewCorner.Parent = soundPreview
    
    local soundLabel = Instance.new("TextLabel")
    soundLabel.Name = "SoundLabel"
    soundLabel.Size = UDim2.new(0.7, 0, 1, 0)
    soundLabel.BackgroundTransparency = 1
    soundLabel.Font = Enum.Font.Gotham
    soundLabel.TextSize = 14
    soundLabel.TextColor3 = Color3.new(1, 1, 1)
    soundLabel.Text = "Sound Asset Preview"
    soundLabel.Parent = soundPreview
    
    local playButton = Instance.new("TextButton")
    playButton.Name = "PlayButton"
    playButton.Size = UDim2.new(0, 80, 0, 30)
    playButton.Position = UDim2.new(1, -90, 0.5, -15)
    playButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
    playButton.Font = Enum.Font.GothamMedium
    playButton.TextSize = 14
    playButton.TextColor3 = Color3.new(1, 1, 1)
    playButton.Text = "Play"
    playButton.Parent = soundPreview
    
    -- Add corner to play button
    local playButtonCorner = Instance.new("UICorner")
    playButtonCorner.CornerRadius = UDim.new(0, 4)
    playButtonCorner.Parent = playButton
    
    -- Create sound instance for previewing
    local previewSound = Instance.new("Sound")
    previewSound.Name = "PreviewSound"
    previewSound.Volume = 0.5
    previewSound.Parent = soundPreview
    
    -- Handle play button
    playButton.MouseButton1Click:Connect(function()
        if previewSound.IsPlaying then
            previewSound:Stop()
            playButton.Text = "Play"
        else
            previewSound:Play()
            playButton.Text = "Stop"
            
            -- Reset button when sound finishes
            previewSound.Ended:Connect(function()
                playButton.Text = "Play"
            end)
        end
    end)
    
    -- Handle validate button click
    validateButton.MouseButton1Click:Connect(function()
        local assetId = assetIdInput.Text
        local assetType = assetTypeDropdown.Text
        
        -- Normalize asset ID
        if not string.match(assetId, "^rbxassetid://") and tonumber(assetId) then
            assetId = "rbxassetid://" .. assetId
        end
        
        -- Validate the asset
        local isValid = AssetValidator.validateAsset(assetId, assetType, true)
        
        -- Update result text
        if isValid then
            resultText.Text = "✅ Asset is valid and loads correctly."
            resultTitle.TextColor3 = Color3.fromRGB(40, 180, 100)
        else
            resultText.Text = "❌ Asset failed validation. This asset may not load correctly in-game."
            resultTitle.TextColor3 = Color3.fromRGB(220, 50, 50)
            
            -- Add to problemAssets if it's not already there
            local found = false
            for _, problemAsset in pairs(AssetHealthDashboard.problemAssets) do
                if problemAsset.id == assetId then
                    found = true
                    break
                end
            end
            
            if not found then
                table.insert(AssetHealthDashboard.problemAssets, {
                    id = assetId,
                    assetType = assetType,
                    timestamp = os.time(),
                    fixAttempts = 0,
                    fixed = false,
                    replacementId = nil
                })
            end
        end
        
        -- Update preview
        AssetHealthDashboard.updatePreview(assetId, assetType)
    end)
    
    -- Handle fix button click
    fixButton.MouseButton1Click:Connect(function()
        local assetId = assetIdInput.Text
        local assetType = assetTypeDropdown.Text
        
        -- Normalize asset ID
        if not string.match(assetId, "^rbxassetid://") and tonumber(assetId) then
            assetId = "rbxassetid://" .. assetId
        end
        
        -- Find an asset fixer
        local fixer = AssetHealthDashboard.assetFixers[assetType]
        if not fixer then
            resultText.Text = "❌ No fixer available for asset type: " .. assetType
            resultTitle.TextColor3 = Color3.fromRGB(220, 50, 50)
            return
        end
        
        -- Apply the fixer
        local replacementId = fixer(assetId)
        
        -- Update result text
        if replacementId then
            resultText.Text = "✅ Asset fixed. Replacement ID: " .. replacementId
            resultTitle.TextColor3 = Color3.fromRGB(40, 180, 100)
            
            -- Update in problemAssets list
            for _, problemAsset in pairs(AssetHealthDashboard.problemAssets) do
                if problemAsset.id == assetId then
                    problemAsset.fixed = true
                    problemAsset.replacementId = replacementId
                    problemAsset.fixAttempts += 1
                    break
                end
            end
            
            -- Update preview to show the replacement
            AssetHealthDashboard.updatePreview(replacementId, assetType)
        else
            resultText.Text = "❌ Failed to fix asset. No replacement available."
            resultTitle.TextColor3 = Color3.fromRGB(220, 50, 50)
        end
    end)
    
    -- Add tab buttons
    local dashboardTabButton = Instance.new("TextButton")
    dashboardTabButton.Name = "DashboardTabButton"
    dashboardTabButton.Size = UDim2.new(0, 100, 0, 30)
    dashboardTabButton.Position = UDim2.new(0, 10, 0, 5)
    dashboardTabButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
    dashboardTabButton.Font = Enum.Font.GothamMedium
    dashboardTabButton.TextSize = 14
    dashboardTabButton.TextColor3 = Color3.new(1, 1, 1)
    dashboardTabButton.Text = "Dashboard"
    dashboardTabButton.Parent = mainGui
    
    -- Add corner to dashboard button
    local dashboardButtonCorner = Instance.new("UICorner")
    dashboardButtonCorner.CornerRadius = UDim.new(0, 4)
    dashboardButtonCorner.Parent = dashboardTabButton
    
    local fixerTabButton = Instance.new("TextButton")
    fixerTabButton.Name = "FixerTabButton"
    fixerTabButton.Size = UDim2.new(0, 100, 0, 30)
    fixerTabButton.Position = UDim2.new(0, 120, 0, 5)
    fixerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    fixerTabButton.Font = Enum.Font.GothamMedium
    fixerTabButton.TextSize = 14
    fixerTabButton.TextColor3 = Color3.new(1, 1, 1)
    fixerTabButton.Text = "Asset Fixer"
    fixerTabButton.Parent = mainGui
    
    -- Add corner to fixer button
    local fixerButtonCorner = Instance.new("UICorner")
    fixerButtonCorner.CornerRadius = UDim.new(0, 4)
    fixerButtonCorner.Parent = fixerTabButton
    
    -- Get the content frame
    local contentFrame = mainFrame:FindFirstChild("ContentFrame")
    
    -- Tab switching logic
    dashboardTabButton.MouseButton1Click:Connect(function()
        dashboardTabButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
        fixerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        
        if contentFrame then
            contentFrame.Visible = true
        end
        fixerTab.Visible = false
    end)
    
    fixerTabButton.MouseButton1Click:Connect(function()
        dashboardTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        fixerTabButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
        
        if contentFrame then
            contentFrame.Visible = false
        end
        fixerTab.Visible = true
    end)
    
    -- Adjust main frame size to fit tabs
    if contentFrame then
        contentFrame.Size = UDim2.new(1, -20, 1, -80)
        contentFrame.Position = UDim2.new(0, 10, 0, 45)
    end
end

-- Update preview display for an asset
function AssetHealthDashboard.updatePreview(assetId, assetType)
    local mainGui = AssetHealthDashboard.gui
    if not mainGui then return end
    
    local fixerTab = mainGui.MainFrame:FindFirstChild("FixerTab")
    if not fixerTab then return end
    
    local previewFrame = fixerTab:FindFirstChild("PreviewFrame")
    if not previewFrame then return end
    
    local imagePreview = previewFrame:FindFirstChild("ImagePreview")
    local soundPreview = previewFrame:FindFirstChild("SoundPreview")
    
    if assetType == "Image" or assetType == "Texture" or assetType == "Icon" or assetType == "Logo" or assetType == "UI" then
        -- Show image preview
        imagePreview.Visible = true
        soundPreview.Visible = false
        imagePreview.Image = assetId
    elseif assetType == "Sound" then
        -- Show sound preview
        imagePreview.Visible = false
        soundPreview.Visible = true
        
        -- Set sound ID
        local previewSound = soundPreview:FindFirstChild("PreviewSound")
        if previewSound then
            previewSound.SoundId = assetId
            soundPreview.SoundLabel.Text = "Sound: " .. assetId
        end
    else
        -- Generic preview
        imagePreview.Visible = true
        soundPreview.Visible = false
        imagePreview.Image = ""
        
        -- Display type as text
        local textLabel = previewFrame:FindFirstChild("TypeLabel")
        if not textLabel then
            textLabel = Instance.new("TextLabel")
            textLabel.Name = "TypeLabel"
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Font = Enum.Font.GothamMedium
            textLabel.TextSize = 16
            textLabel.TextColor3 = Color3.new(1, 1, 1)
            textLabel.Parent = previewFrame
        end
        
        textLabel.Text = assetType .. ": " .. assetId
    end
end

-- Start monitoring for asset loading failures
function AssetHealthDashboard.startMonitoring()
    if AssetHealthDashboard.monitoringEnabled then
        return
    end
    
    AssetHealthDashboard.monitoringEnabled = true
    
    -- Set up a ContentProvider listener
    ContentProvider.AssetFetchFailed:Connect(function(assetId, errorMsg)
        -- Log the failure
        warn("[AssetHealthDashboard] Asset fetch failed: " .. assetId .. " - " .. errorMsg)
        
        -- Add to problem assets if not already there
        local found = false
        for _, problemAsset in pairs(AssetHealthDashboard.problemAssets) do
            if problemAsset.id == assetId then
                found = true
                break
            end
        end
        
        if not found then
            local assetType = getAssetType(assetId)
            table.insert(AssetHealthDashboard.problemAssets, {
                id = assetId,
                assetType = assetType,
                timestamp = os.time(),
                fixAttempts = 0,
                fixed = false,
                replacementId = nil,
                error = errorMsg
            })
        end
    end)
end

-- Initialize the dashboard
function AssetHealthDashboard.initialize()
    if AssetHealthDashboard.initialized then
        return
    end
    
    -- Start monitoring asset loading failures
    AssetHealthDashboard.startMonitoring()
    
    -- Register with ClientRegistry if available
    if ClientRegistry and typeof(ClientRegistry.registerSystem) == "function" then
        ClientRegistry:registerSystem("AssetHealthDashboard", AssetHealthDashboard)
    end
    
    -- Set up shortcut key (Ctrl+Shift+A)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.A and 
           UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 
           UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            AssetHealthDashboard.toggle()
        end
    end)
    
    AssetHealthDashboard.initialized = true
end

-- Auto-initialize after a short delay
task.delay(1, function()
    AssetHealthDashboard.initialize()
end)

return AssetHealthDashboard
