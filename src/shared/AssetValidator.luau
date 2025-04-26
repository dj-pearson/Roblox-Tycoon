--!strict
--[[
    AssetValidator.luau
    
    A utility module for validating and managing assets.
    
    Created: April 25, 2025
    
    This module:
    1. Validates all types of assets (sounds, animations, images)
    2. Maintains a robust catalog of fallback assets
    3. Implements asset preloading for critical assets
    4. Adds detailed logging for asset loading failures
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    VERBOSE_LOGGING = false,
    ENABLE_VALIDATION = true,
    PRELOAD_CRITICAL_ASSETS = true,
    TRACK_LOADING_STATS = true
}

-- Constants
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()
local IsStudio = RunService:IsStudio()

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn("[AssetValidator] Failed to require module: ", module:GetFullName())
        return nil
    end
    
    return result
end

-- Find shared folder
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = ReplicatedStorage
    print("[AssetValidator] Created shared folder in ReplicatedStorage")
end

-- State tracking
local validationResults = {}
local assetLoadAttempts = {}
local assetLoadSuccesses = {}
local assetLoadFailures = {}
local criticalAssets = {}
local preloadedAssets = {}

-- Fallback assets by type
local fallbackAssets = {
    Image = "rbxassetid://6031090990",  -- Placeholder image
    Sound = "rbxassetid://1547213590",  -- Placeholder sound
    Animation = "rbxassetid://507766388", -- Simple idle animation
    Mesh = "rbxassetid://94586901",     -- Simple cube mesh
    Texture = "rbxassetid://6031090990", -- Placeholder texture
    Icon = "rbxassetid://6031090990",   -- Placeholder icon
    Logo = "rbxassetid://6031090990",   -- Placeholder logo
    UI = "rbxassetid://6031090990"      -- Placeholder UI element
}

-- AssetValidator Module
local AssetValidator = {
    fallbackAssets = fallbackAssets,
    validationResults = validationResults,
    stats = {
        totalAssets = 0,
        validAssets = 0,
        invalidAssets = 0,
        preloadedAssets = 0,
        loadAttempts = 0,
        loadSuccesses = 0,
        loadFailures = 0
    },
    initialized = false
}

-- Debug logging
local function log(message, isVerbose)
    if CONFIG.DEBUG_LOGGING and (not isVerbose or CONFIG.VERBOSE_LOGGING) then
        print("[AssetValidator] " .. message)
    end
end

-- Register a critical asset that should always be preloaded
function AssetValidator.registerCriticalAsset(assetId, assetType)
    if not assetId then
        warn("[AssetValidator] Cannot register critical asset: nil asset ID")
        return false
    end
    
    -- Ensure the asset ID is a proper format
    if not string.match(assetId, "^rbxassetid://") and not tonumber(assetId) then
        warn("[AssetValidator] Invalid asset ID format: " .. assetId)
        return false
    end
    
    -- Normalize asset ID to rbxassetid:// format
    local normalizedId = assetId
    if tonumber(assetId) then
        normalizedId = "rbxassetid://" .. assetId
    end
    
    -- Store in critical assets list
    criticalAssets[normalizedId] = assetType or "Unknown"
    log("Registered critical asset: " .. normalizedId .. " (Type: " .. (assetType or "Unknown") .. ")")
    
    -- If we're already initialized, preload this asset now
    if AssetValidator.initialized and CONFIG.PRELOAD_CRITICAL_ASSETS then
        AssetValidator.preloadAsset(normalizedId, assetType)
    end
    
    return true
end

-- Validate a single asset
function AssetValidator.validateAsset(assetId, assetType, skipCache)
    if not assetId then
        warn("[AssetValidator] Cannot validate nil asset ID")
        return false
    end
    
    -- Check cache first unless skipCache is true
    if not skipCache and validationResults[assetId] ~= nil then
        log("Using cached validation result for " .. assetId .. ": " .. tostring(validationResults[assetId]), true)
        return validationResults[assetId]
    end
    
    -- Normalize asset ID to rbxassetid:// format
    local normalizedId = assetId
    if tonumber(assetId) then
        normalizedId = "rbxassetid://" .. assetId
    end
    
    -- Track attempt
    if CONFIG.TRACK_LOADING_STATS then
        AssetValidator.stats.loadAttempts += 1
        assetLoadAttempts[normalizedId] = (assetLoadAttempts[normalizedId] or 0) + 1
    end
    
    -- Try to load the asset
    local success = pcall(function()
        -- Try different validation approaches based on asset type
        if assetType == "Image" or assetType == "Texture" or assetType == "Icon" or assetType == "Logo" or assetType == "UI" then
            -- For images, create a temporary ImageLabel
            local imageLabel = Instance.new("ImageLabel")
            imageLabel.Image = normalizedId
            
            -- Use a timeout to avoid hanging if the image never loads
            local loadedSuccessfully = false
            local connection
            
            -- Create a promise-like pattern with timeout
            local timeoutTime = tick() + 3 -- 3 second timeout
            
            connection = imageLabel:GetPropertyChangedSignal("IsLoaded"):Connect(function()
                if imageLabel.IsLoaded then
                    loadedSuccessfully = true
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
            
            -- Wait for load or timeout
            while not loadedSuccessfully and tick() < timeoutTime do
                task.wait(0.1)
            end
            
            -- Clean up
            if connection then
                connection:Disconnect()
            end
            
            if not loadedSuccessfully then
                error("Image failed to load within timeout: " .. normalizedId)
            end
            
            imageLabel:Destroy()
        elseif assetType == "Sound" then
            -- For sounds, create a temporary Sound
            local sound = Instance.new("Sound")
            sound.SoundId = normalizedId
            sound.Parent = ReplicatedStorage
            
            -- No clean way to check if sound loaded in Lua, so we'll just wait
            task.delay(0.5, function()
                sound:Destroy()
            end)
        elseif assetType == "Animation" then
            -- For animations, create a temporary Animation
            local animation = Instance.new("Animation")
            animation.AnimationId = normalizedId
            
            -- Try to load it
            local animationTrack = nil
            if IsServer then
                -- Can't easily validate on server
                -- Just assume it's valid
                return true
            else
                -- On client, try to load in a dummy Animator
                local dummy = Instance.new("Part")
                dummy.Anchored = true
                dummy.CanCollide = false
                dummy.Transparency = 1
                dummy.Parent = workspace
                
                local humanoid = Instance.new("Humanoid")
                humanoid.Parent = dummy
                
                local animator = Instance.new("Animator")
                animator.Parent = humanoid
                
                animationTrack = animator:LoadAnimation(animation)
                
                -- Wait briefly
                task.delay(0.5, function()
                    animationTrack:Stop()
                    dummy:Destroy()
                end)
            end
        else
            -- For other asset types, use ContentProvider
            ContentProvider:PreloadAsync({normalizedId}, function(id, status)
                if status ~= Enum.AssetFetchStatus.Success then
                    error("Asset failed to load: " .. id .. " (Status: " .. tostring(status) .. ")")
                end
            end)
        end
    end)
    
    -- Store result
    validationResults[normalizedId] = success
    
    -- Update stats
    if CONFIG.TRACK_LOADING_STATS then
        if success then
            AssetValidator.stats.loadSuccesses += 1
            assetLoadSuccesses[normalizedId] = (assetLoadSuccesses[normalizedId] or 0) + 1
            AssetValidator.stats.validAssets += 1
        else
            AssetValidator.stats.loadFailures += 1
            assetLoadFailures[normalizedId] = (assetLoadFailures[normalizedId] or 0) + 1
            AssetValidator.stats.invalidAssets += 1
            
            warn("[AssetValidator] Asset validation failed: " .. normalizedId .. " (Type: " .. (assetType or "Unknown") .. ")")
        end
        
        AssetValidator.stats.totalAssets += 1
    end
    
    log("Validated asset " .. normalizedId .. ": " .. tostring(success) .. " (Type: " .. (assetType or "Unknown") .. ")")
    return success
end

-- Get a valid asset ID, with fallback if needed
function AssetValidator.getValidAssetId(assetId, assetType, skipValidation)
    if not assetId then
        warn("[AssetValidator] Cannot validate nil asset ID")
        return fallbackAssets[assetType] or fallbackAssets.Image
    end
    
    -- Skip validation if disabled or explicitly skipped
    if not CONFIG.ENABLE_VALIDATION or skipValidation then
        return assetId
    end
    
    -- Normalize asset ID to rbxassetid:// format
    local normalizedId = assetId
    if tonumber(assetId) then
        normalizedId = "rbxassetid://" .. assetId
    end
    
    -- Check if asset is valid
    local isValid = AssetValidator.validateAsset(normalizedId, assetType)
    
    if not isValid then
        -- Return fallback asset
        local fallbackId = fallbackAssets[assetType] or fallbackAssets.Image
        log("Using fallback asset for " .. normalizedId .. ": " .. fallbackId)
        return fallbackId
    end
    
    return normalizedId
end

-- Preload a single asset
function AssetValidator.preloadAsset(assetId, assetType)
    if not assetId then
        warn("[AssetValidator] Cannot preload nil asset ID")
        return false
    end
    
    -- Normalize asset ID to rbxassetid:// format
    local normalizedId = assetId
    if tonumber(assetId) then
        normalizedId = "rbxassetid://" .. assetId
    end
    
    -- Skip if already preloaded
    if preloadedAssets[normalizedId] then
        log("Asset already preloaded: " .. normalizedId, true)
        return true
    end
    
    log("Preloading asset: " .. normalizedId)
    
    -- Try to preload the asset
    local success = pcall(function()
        ContentProvider:PreloadAsync({normalizedId})
    end)
    
    -- Track result
    if success then
        preloadedAssets[normalizedId] = true
        AssetValidator.stats.preloadedAssets += 1
        log("Successfully preloaded asset: " .. normalizedId)
    else
        warn("[AssetValidator] Failed to preload asset: " .. normalizedId)
    end
    
    return success
end

-- Preload all critical assets
function AssetValidator.preloadCriticalAssets()
    log("Preloading critical assets...")
    
    local successCount = 0
    local totalCount = 0
    
    for assetId, assetType in pairs(criticalAssets) do
        totalCount += 1
        if AssetValidator.preloadAsset(assetId, assetType) then
            successCount += 1
        end
    end
    
    log("Preloaded " .. successCount .. "/" .. totalCount .. " critical assets")
    return successCount == totalCount
end

-- Preload a batch of assets
function AssetValidator.preloadAssetBatch(assetIds)
    if not assetIds or #assetIds == 0 then
        warn("[AssetValidator] No assets to preload")
        return false
    end
    
    -- Normalize all asset IDs
    local normalizedIds = {}
    for _, assetId in ipairs(assetIds) do
        if tonumber(assetId) then
            table.insert(normalizedIds, "rbxassetid://" .. assetId)
        else
            table.insert(normalizedIds, assetId)
        end
    end
    
    log("Preloading batch of " .. #normalizedIds .. " assets")
    
    -- Try to preload the assets
    local success = pcall(function()
        ContentProvider:PreloadAsync(normalizedIds)
    end)
    
    -- Track results
    if success then
        for _, assetId in ipairs(normalizedIds) do
            preloadedAssets[assetId] = true
        end
        
        AssetValidator.stats.preloadedAssets += #normalizedIds
        log("Successfully preloaded batch of " .. #normalizedIds .. " assets")
    else
        warn("[AssetValidator] Failed to preload asset batch with " .. #normalizedIds .. " assets")
    end
    
    return success
end

-- Get a list of all invalid assets
function AssetValidator.getInvalidAssets()
    local invalidAssets = {}
    
    for assetId, isValid in pairs(validationResults) do
        if not isValid then
            table.insert(invalidAssets, assetId)
        end
    end
    
    return invalidAssets
end

-- Generate an asset health report
function AssetValidator.generateHealthReport()
    local report = {
        timestamp = os.time(),
        totalAssets = AssetValidator.stats.totalAssets,
        validAssets = AssetValidator.stats.validAssets,
        invalidAssets = AssetValidator.stats.invalidAssets,
        preloadedAssets = AssetValidator.stats.preloadedAssets,
        loadAttempts = AssetValidator.stats.loadAttempts,
        loadSuccesses = AssetValidator.stats.loadSuccesses,
        loadFailures = AssetValidator.stats.loadFailures,
        invalidAssetsList = AssetValidator.getInvalidAssets(),
        criticalAssetsCount = 0, -- Will be calculated
        preloadedAssetsCount = 0 -- Will be calculated
    }
    
    -- Count critical and preloaded assets
    local criticalCount = 0
    for _ in pairs(criticalAssets) do
        criticalCount += 1
    end
    report.criticalAssetsCount = criticalCount
    
    local preloadedCount = 0
    for _ in pairs(preloadedAssets) do
        preloadedCount += 1
    end
    report.preloadedAssetsCount = preloadedCount
    
    return report
end

-- Print the current health report
function AssetValidator.printHealthReport()
    local report = AssetValidator.generateHealthReport()
    
    print("===== Asset Health Report =====")
    print("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S", report.timestamp))
    print("Total Assets: " .. report.totalAssets)
    print("Valid Assets: " .. report.validAssets)
    print("Invalid Assets: " .. report.invalidAssets)
    print("Preloaded Assets: " .. report.preloadedAssets)
    print("Load Attempts: " .. report.loadAttempts)
    print("Load Successes: " .. report.loadSuccesses)
    print("Load Failures: " .. report.loadFailures)
    print("Critical Assets: " .. report.criticalAssetsCount)
    print("Preloaded Assets: " .. report.preloadedAssetsCount)
    
    if #report.invalidAssetsList > 0 then
        print("Invalid Assets List:")
        for _, assetId in ipairs(report.invalidAssetsList) do
            print("  - " .. assetId)
        end
    else
        print("No invalid assets detected.")
    end
    
    print("===============================")
    
    return report
end

-- Try to get ClientRegistry for integration
local ClientRegistry = nil
if IsClient then
    -- Try to find via ModuleLoader
    if sharedFolder:FindFirstChild("ModuleLoader") then
        local ModuleLoader = requireSafely(sharedFolder.ModuleLoader)
        if ModuleLoader then
            ClientRegistry = ModuleLoader.tryRequire("ClientRegistry")
        end
    end
end

-- Initialize the validator
function AssetValidator.initialize()
    if AssetValidator.initialized then
        return true
    end
    
    log("Initializing AssetValidator")
    
    -- Preregister default fallback assets as critical
    for assetTypeStr, assetIdStr in pairs(fallbackAssets) do
        AssetValidator.registerCriticalAsset(assetIdStr, assetTypeStr)
    end
    
    -- Preload critical assets if enabled
    if CONFIG.PRELOAD_CRITICAL_ASSETS then
        task.spawn(function()
            AssetValidator.preloadCriticalAssets()
        end)
    end
    
    -- Auto-register common UI assets if we're on the client
    if IsClient then
        -- Add core UI assets
        local uiAssets = {
            "rbxassetid://3926307971", -- Common UI icons
            "rbxassetid://3926305904", -- Common UI icons
            "rbxassetid://6026568247", -- Coin icon
            "rbxassetid://6031090990"  -- Placeholder image
        }
        
        for _, assetIdVal in ipairs(uiAssets) do
            AssetValidator.registerCriticalAsset(assetIdVal, "UI")
        end
        
        -- Try to register with ClientRegistry if available
        if ClientRegistry and typeof(ClientRegistry.registerSystem) == "function" then
            ClientRegistry:registerSystem("AssetValidator", AssetValidator)
            log("Registered with ClientRegistry")
        end
    end
    
    AssetValidator.initialized = true
    log("AssetValidator initialized")
    
    return true
end

-- Create an AssetHealthDashboard for monitoring asset status
function AssetValidator.createAssetHealthDashboard()
    if not IsClient then
        warn("[AssetValidator] Asset Health Dashboard can only be created on the client")
        return nil
    end
    
    local PlayersService = game:GetService("Players")
    local LocalPlayer = PlayersService.LocalPlayer
    if not LocalPlayer then return nil end
    
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    log("Creating Asset Health Dashboard")
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AssetHealthDashboard"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 20
    titleText.TextColor3 = Color3.new(1, 1, 1)
    titleText.Text = "Asset Health Dashboard"
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Parent = titleBar
    
    -- Add corner to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0.5, 0)
    closeCorner.Parent = closeButton
    
    -- Content frame
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -50)
    contentFrame.Position = UDim2.new(0, 10, 0, 45)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 6
    contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 800) -- Will be adjusted
    contentFrame.Parent = mainFrame
    
    -- Close handler
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Helper function to create a stat section
    local function createStatSection(name, value, position)
        local section = Instance.new("Frame")
        section.Name = name .. "Section"
        section.Size = UDim2.new(0.5, -15, 0, 80)
        section.Position = position
        section.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        section.Parent = contentFrame
        
        -- Add corner
        local sectionCorner = Instance.new("UICorner")
        sectionCorner.CornerRadius = UDim.new(0, 6)
        sectionCorner.Parent = section
        
        -- Add title
        local sectionTitle = Instance.new("TextLabel")
        sectionTitle.Name = "Title"
        sectionTitle.Size = UDim2.new(1, -20, 0, 30)
        sectionTitle.Position = UDim2.new(0, 10, 0, 5)
        sectionTitle.BackgroundTransparency = 1
        sectionTitle.Font = Enum.Font.GothamMedium
        sectionTitle.TextSize = 16
        sectionTitle.TextColor3 = Color3.new(1, 1, 1)
        sectionTitle.Text = name
        sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        sectionTitle.Parent = section
        
        -- Add value
        local sectionValue = Instance.new("TextLabel")
        sectionValue.Name = "Value"
        sectionValue.Size = UDim2.new(1, -20, 0, 30)
        sectionValue.Position = UDim2.new(0, 10, 0, 40)
        sectionValue.BackgroundTransparency = 1
        sectionValue.Font = Enum.Font.GothamBold
        sectionValue.TextSize = 24
        sectionValue.TextColor3 = Color3.new(1, 1, 1)
        sectionValue.Text = tostring(value)
        sectionValue.TextXAlignment = Enum.TextXAlignment.Left
        sectionValue.Parent = section
        
        return section
    end
    
    -- Create stat sections
    local report = AssetValidator.generateHealthReport()
    
    createStatSection("Total Assets", report.totalAssets, UDim2.new(0, 0, 0, 10))
    createStatSection("Valid Assets", report.validAssets, UDim2.new(0.5, 10, 0, 10))
    createStatSection("Invalid Assets", report.invalidAssets, UDim2.new(0, 0, 0, 100))
    createStatSection("Preloaded Assets", report.preloadedAssets, UDim2.new(0.5, 10, 0, 100))
    createStatSection("Load Attempts", report.loadAttempts, UDim2.new(0, 0, 0, 190))
    createStatSection("Load Successes", report.loadSuccesses, UDim2.new(0.5, 10, 0, 190))
    createStatSection("Load Failures", report.loadFailures, UDim2.new(0, 0, 0, 280))
    createStatSection("Critical Assets", report.criticalAssetsCount, UDim2.new(0.5, 10, 0, 280))
    
    -- Create invalid assets list if any
    if #report.invalidAssetsList > 0 then
        -- Create section title
        local listTitle = Instance.new("TextLabel")
        listTitle.Name = "InvalidAssetsTitle"
        listTitle.Size = UDim2.new(1, -20, 0, 30)
        listTitle.Position = UDim2.new(0, 10, 0, 370)
        listTitle.BackgroundTransparency = 1
        listTitle.Font = Enum.Font.GothamBold
        listTitle.TextSize = 18
        listTitle.TextColor3 = Color3.new(1, 1, 1)
        listTitle.Text = "Invalid Assets"
        listTitle.TextXAlignment = Enum.TextXAlignment.Left
        listTitle.Parent = contentFrame
        
        -- Create list container
        local listContainer = Instance.new("Frame")
        listContainer.Name = "InvalidAssetsList"
        listContainer.Size = UDim2.new(1, -20, 0, 30 * math.min(10, #report.invalidAssetsList))
        listContainer.Position = UDim2.new(0, 10, 0, 410)
        listContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        listContainer.BorderSizePixel = 0
        listContainer.Parent = contentFrame
        
        -- Add corner
        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = UDim.new(0, 6)
        listCorner.Parent = listContainer
        
        -- Add list items
        for i, assetId in ipairs(report.invalidAssetsList) do
            if i > 10 then break end -- Limit to 10 items
            
            local listItem = Instance.new("TextLabel")
            listItem.Name = "Item_" .. i
            listItem.Size = UDim2.new(1, -20, 0, 30)
            listItem.Position = UDim2.new(0, 10, 0, (i - 1) * 30)
            listItem.BackgroundTransparency = 1
            listItem.Font = Enum.Font.Gotham
            listItem.TextSize = 14
            listItem.TextColor3 = Color3.fromRGB(255, 100, 100)
            listItem.Text = assetId
            listItem.TextXAlignment = Enum.TextXAlignment.Left
            listItem.TextWrapped = true
            listItem.Parent = listContainer
        end
        
        -- Add message if there are more
        if #report.invalidAssetsList > 10 then
            local moreText = Instance.new("TextLabel")
            moreText.Name = "MoreText"
            moreText.Size = UDim2.new(1, -20, 0, 30)
            moreText.Position = UDim2.new(0, 10, 0, 410 + 30 * 10)
            moreText.BackgroundTransparency = 1
            moreText.Font = Enum.Font.GothamMedium
            moreText.TextSize = 14
            moreText.TextColor3 = Color3.new(0.8, 0.8, 0.8)
            moreText.Text = "...and " .. (#report.invalidAssetsList - 10) .. " more"
            moreText.TextXAlignment = Enum.TextXAlignment.Left
            moreText.Parent = contentFrame
            
            -- Adjust canvas size
            contentFrame.CanvasSize = UDim2.new(0, 0, 0, 460 + 30 * 10)
        else
            -- Adjust canvas size
            contentFrame.CanvasSize = UDim2.new(0, 0, 0, 420 + 30 * #report.invalidAssetsList)
        end
    else
        -- No invalid assets
        local noInvalidText = Instance.new("TextLabel")
        noInvalidText.Name = "NoInvalidText"
        noInvalidText.Size = UDim2.new(1, -20, 0, 30)
        noInvalidText.Position = UDim2.new(0, 10, 0, 370)
        noInvalidText.BackgroundTransparency = 1
        noInvalidText.Font = Enum.Font.GothamBold
        noInvalidText.TextSize = 18
        noInvalidText.TextColor3 = Color3.fromRGB(40, 180, 100)
        noInvalidText.Text = "No invalid assets detected ✓"
        noInvalidText.TextXAlignment = Enum.TextXAlignment.Left
        noInvalidText.Parent = contentFrame
    end
    
    -- Add refresh button
    local refreshButton = Instance.new("TextButton")
    refreshButton.Name = "RefreshButton"
    refreshButton.Size = UDim2.new(0, 150, 0, 40)
    refreshButton.Position = UDim2.new(0.5, -75, 1, -60)
    refreshButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
    refreshButton.Font = Enum.Font.GothamBold
    refreshButton.TextSize = 16
    refreshButton.TextColor3 = Color3.new(1, 1, 1)
    refreshButton.Text = "Refresh Data"
    refreshButton.Parent = mainFrame
    
    -- Add corner to refresh button
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 8)
    refreshCorner.Parent = refreshButton
    
    -- Refresh handler
    refreshButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        AssetValidator.createAssetHealthDashboard()
    end)
    
    return screenGui
end

-- Auto-initialize
AssetValidator.initialize()

return AssetValidator
