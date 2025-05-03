--[[
    UIComponentFactory.lua
    
    A robust factory module for creating UI elements with built-in validation,
    error handling, and asset management. This module helps ensure UI components
    display properly even when asset IDs are problematic.
    
    Created by: AI Assistant
    Created on: May 3, 2025
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIComponentFactory = {}

-- Constants
local FALLBACK_ASSETS = {
    button = "rbxassetid://8093763464", -- Menu icon
    image = "rbxassetid://8091927367",  -- Default fallback icon
    logo = "rbxassetid://8092007134",   -- Coin icon
    close = "rbxassetid://8093755787",  -- X icon
    settings = "rbxassetid://8093766304", -- Gear icon
}

-- Cache validated assets for performance
local validatedAssets = {}

-- Utility function to validate asset IDs
local function validateAssetId(assetId)
    if not assetId or assetId == "" then 
        return false 
    end
    
    -- Check cache first
    if validatedAssets[assetId] ~= nil then
        return validatedAssets[assetId]
    end
    
    -- Check format
    if not tostring(assetId):match("^rbxassetid://[0-9]+$") then
        warn("[UIComponentFactory] Asset ID format invalid: " .. tostring(assetId))
        validatedAssets[assetId] = false
        return false
    end
    
    -- Basic length validation for asset IDs (they shouldn't be too long)
    local id = assetId:match("^rbxassetid://([0-9]+)$")
    if id and #id > 15 then
        warn("[UIComponentFactory] Asset ID too long, likely invalid: " .. assetId)
        validatedAssets[assetId] = false
        return false
    end
    
    -- Try to preload the asset
    local success = pcall(function()
        ContentProvider:PreloadAsync({assetId})
    end)
    
    validatedAssets[assetId] = success
    
    if not success then
        warn("[UIComponentFactory] Failed to preload asset: " .. assetId)
    end
    
    return success
end

-- Create an image button with error handling
function UIComponentFactory.createImageButton(config)
    config = config or {}
    
    local button = Instance.new("ImageButton")
    button.Name = config.name or "ImageButton"
    button.Size = config.size or UDim2.new(0, 50, 0, 50)
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    button.BackgroundColor3 = config.backgroundColor or Color3.fromRGB(40, 40, 50)
    button.BackgroundTransparency = config.backgroundTransparency or 0.5
    button.BorderSizePixel = 0
    
    -- Validate and set image
    local imageAssetId = config.image
    if not imageAssetId then
        button.Image = ""
    else
        -- Ensure asset ID is valid
        if validateAssetId(imageAssetId) then
            button.Image = imageAssetId
        else
            -- Use fallback if available
            if config.fallbackImage and validateAssetId(config.fallbackImage) then
                button.Image = config.fallbackImage
                warn("[UIComponentFactory] Using fallback image for: " .. button.Name)
            else
                button.Image = FALLBACK_ASSETS.button
                warn("[UIComponentFactory] Using default fallback for: " .. button.Name)
            end
        end
    end
    
    -- Add error handling for image loading
    button.ImageLoaded:Connect(function()
        if button and button.Parent then
            -- Success - image loaded properly
            if config.onImageLoaded and typeof(config.onImageLoaded) == "function" then
                config.onImageLoaded(button)
            end
        end
    end)
    
    -- Create UI corner if requested
    if config.cornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = config.cornerRadius
        corner.Parent = button
    end
    
    -- Add hover effect if requested
    if config.hoverEffect ~= false then
        button.MouseEnter:Connect(function()
            if not button or not button.Parent then return end
            
            -- Store original properties
            local originalSize = button.Size
            local originalPosition = button.Position
            local originalTransparency = button.BackgroundTransparency
            
            -- Apply hover effect
            button.BackgroundTransparency = math.max(0, originalTransparency - 0.2)
            
            -- Apply scale effect if enabled
            if config.hoverScale and config.hoverScale ~= 1 then
                local scale = config.hoverScale or 1.1
                local sizeDiff = button.Size * (scale - 1)
                
                button.Size = button.Size * scale
                if button.AnchorPoint ~= Vector2.new(0.5, 0.5) then
                    button.Position = button.Position - sizeDiff/2
                end
            end
            
            -- Restore original properties on mouse leave
            button.MouseLeave:Connect(function()
                if not button or not button.Parent then return end
                button.Size = originalSize
                button.Position = originalPosition
                button.BackgroundTransparency = originalTransparency
            end)
        end)
    end
    
    -- Connect click callback
    if config.callback and typeof(config.callback) == "function" then
        button.MouseButton1Click:Connect(function()
            config.callback(button)
        end)
    end
    
    -- Set parent if provided
    if config.parent then
        button.Parent = config.parent
    end
    
    return button
end

-- Add diagnostic function to help troubleshoot UI issues
function UIComponentFactory.runImageDiagnostics(imageInstances)
    local results = {
        total = 0,
        successful = 0,
        failed = 0,
        details = {}
    }
    
    local function checkImage(instance)
        if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
            results.total = results.total + 1
            
            local assetId = instance.Image
            local name = instance.Name
            local path = instance:GetFullName()
            
            -- Check if image is set
            if assetId == "" then
                table.insert(results.details, {
                    instance = path,
                    status = "Empty",
                    issue = "No image set"
                })
                results.failed = results.failed + 1
                return
            end
            
            -- Check format
            if not tostring(assetId):match("^rbxassetid://[0-9]+$") then
                table.insert(results.details, {
                    instance = path,
                    status = "Invalid",
                    issue = "Format error: " .. tostring(assetId)
                })
                results.failed = results.failed + 1
                return
            end
            
            -- Check length
            local id = assetId:match("^rbxassetid://([0-9]+)$")
            if id and #id > 15 then
                table.insert(results.details, {
                    instance = path,
                    status = "Invalid",
                    issue = "ID too long: " .. #id .. " digits"
                })
                results.failed = results.failed + 1
                return
            end
            
            -- Attempt to validate the asset
            local success = validateAssetId(assetId)
            
            if success then
                results.successful = results.successful + 1
                table.insert(results.details, {
                    instance = path,
                    status = "Success",
                    issue = nil
                })
            else
                results.failed = results.failed + 1
                table.insert(results.details, {
                    instance = path,
                    status = "Failed",
                    issue = "Asset failed to load"
                })
            end
        end
    end
    
    -- Check all provided instances
    if typeof(imageInstances) == "table" then
        for _, instance in ipairs(imageInstances) do
            checkImage(instance)
        end
    elseif imageInstances then
        checkImage(imageInstances)
        
        -- If it's a container, also check its descendants
        for _, descendant in ipairs(imageInstances:GetDescendants()) do
            if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
                checkImage(descendant)
            end
        end
    end
    
    return results
end

-- Create a standard UI button 
function UIComponentFactory.createButton(config)
    config = config or {}
    
    local button = Instance.new("TextButton")
    button.Name = config.name or "Button"
    button.Size = config.size or UDim2.new(0, 200, 0, 50)
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.AnchorPoint = config.anchorPoint or Vector2.new(0, 0)
    button.Text = config.text or ""
    button.TextColor3 = config.textColor or Color3.fromRGB(255, 255, 255)
    button.TextSize = config.textSize or 14
    button.Font = config.font or Enum.Font.GothamMedium
    button.BackgroundColor3 = config.color or Color3.fromRGB(60, 100, 180)
    button.BorderSizePixel = 0
    
    -- Add corner radius
    if config.cornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = config.cornerRadius
        corner.Parent = button
    end
    
    -- Handle hover effects
    if config.hoverEffect ~= false then
        button.MouseEnter:Connect(function()
            if not button or not button.Parent then return end
            button.BackgroundColor3 = Color3.new(
                math.min(button.BackgroundColor3.R * 1.1, 1),
                math.min(button.BackgroundColor3.G * 1.1, 1),
                math.min(button.BackgroundColor3.B * 1.1, 1)
            )
        end)
        
        button.MouseLeave:Connect(function()
            if not button or not button.Parent then return end
            button.BackgroundColor3 = config.color or Color3.fromRGB(60, 100, 180)
        end)
    end
    
    -- Connect callback
    if config.callback and type(config.callback) == "function" then
        button.MouseButton1Click:Connect(config.callback)
    end
    
    -- Add icon if specified
    if config.icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0, 10, 0.5, -10)
        icon.BackgroundTransparency = 1
        
        -- Validate icon image
        if validateAssetId(config.icon) then
            icon.Image = config.icon
        else
            icon.Image = FALLBACK_ASSETS.image
            warn("[UIComponentFactory] Using fallback for button icon in: " .. button.Name)
        end
        
        icon.Parent = button
        
        -- Adjust text position for icon
        button.TextXAlignment = Enum.TextXAlignment.Center
    end
    
    -- Set parent if specified
    if config.parent then
        button.Parent = config.parent
    end
    
    return button
end

-- Preload common assets to ensure they're available when needed
function UIComponentFactory.preloadCommonAssets()
    local assetsToPreload = {}
    
    -- Add fallback assets to preload list
    for _, assetId in pairs(FALLBACK_ASSETS) do
        table.insert(assetsToPreload, assetId)
    end
    
    -- Preload them all
    local success, errorMsg = pcall(function()
        ContentProvider:PreloadAsync(assetsToPreload)
    end)
    
    if not success then
        warn("[UIComponentFactory] Failed to preload assets: " .. errorMsg)
    end
    
    return success
end

-- Try to preload common assets when the module loads
spawn(function()
    UIComponentFactory.preloadCommonAssets()
end)

return UIComponentFactory
