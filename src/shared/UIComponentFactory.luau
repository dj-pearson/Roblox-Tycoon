--!strict
--[[
    UIComponentFactory.luau
    Factory for creating UI components with consistent styling and behavior.
    
    Created: May 3, 2025
]]

local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local UIComponentFactory = {}

-- Fallback assets
local FALLBACK_ASSETS = {
    button = "rbxassetid://7287657389", -- Settings icon as fallback
    errorIcon = "rbxassetid://7933759553"
}

-- Cache for validated asset IDs
local validatedAssets = {}

-- Function to validate asset ID
local function validateAssetId(assetId)
    -- Return result from cache if available
    if validatedAssets[assetId] ~= nil then
        return validatedAssets[assetId]
    end
    
    -- Check format
    if not assetId:match("^rbxassetid://[0-9]+$") then
        warn("[UIComponentFactory] Asset ID format invalid: " .. assetId)
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
        corner.CornerRadius = typeof(config.cornerRadius) == "UDim" 
            and config.cornerRadius 
            or UDim.new(0, config.cornerRadius)
        corner.Parent = button
    end
    
    -- Create active indicator if requested
    if config.withActiveIndicator then
        local indicator = Instance.new("Frame")
        indicator.Name = "ActiveIndicator"
        indicator.Size = UDim2.new(0, 4, 1, 0)
        indicator.Position = UDim2.new(0, -5, 0, 0)
        indicator.BackgroundColor3 = config.indicatorColor or Color3.fromRGB(0, 170, 255)
        indicator.Visible = false
        indicator.Parent = button
    end
    
    -- Create tooltip if requested
    if config.tooltip then
        local tooltip = Instance.new("TextLabel")
        tooltip.Name = "Tooltip"
        tooltip.Size = UDim2.new(0, 120, 0, 40)
        tooltip.Position = UDim2.new(0, -130, 0, 5)
        tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
        tooltip.Font = Enum.Font.Gotham
        tooltip.TextSize = 14
        tooltip.Text = config.tooltip
        tooltip.TextWrapped = true
        tooltip.TextXAlignment = Enum.TextXAlignment.Center
        tooltip.TextYAlignment = Enum.TextYAlignment.Center
        tooltip.BackgroundTransparency = 0.2
        tooltip.Visible = false
        
        -- Add corner to tooltip
        local tooltipCorner = Instance.new("UICorner")
        tooltipCorner.CornerRadius = UDim.new(0, 6)
        tooltipCorner.Parent = tooltip
        
        tooltip.Parent = button
        
        -- Show/hide tooltip on hover
        button.MouseEnter:Connect(function()
            tooltip.Visible = true
        end)
        
        button.MouseLeave:Connect(function()
            tooltip.Visible = false
        end)
    end
    
    -- Add hover animation if requested
    if config.hoverEffect then
        local originalSize = button.Size
        local hoverSize = UDim2.new(
            originalSize.X.Scale * config.hoverScale or 1.1, 
            originalSize.X.Offset * config.hoverScale or 1.1,
            originalSize.Y.Scale * config.hoverScale or 1.1, 
            originalSize.Y.Offset * config.hoverScale or 1.1
        )
        
        button.MouseEnter:Connect(function()
            local tweenInfo = TweenInfo.new(
                config.hoverDuration or 0.1,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )
            
            local tween = TweenService:Create(button, tweenInfo, {
                Size = hoverSize
            })
            
            tween:Play()
        end)
        
        button.MouseLeave:Connect(function()
            local tweenInfo = TweenInfo.new(
                config.hoverDuration or 0.1,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )
            
            local tween = TweenService:Create(button, tweenInfo, {
                Size = originalSize
            })
            
            tween:Play()
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
            
            -- Check if image ID is valid format
            if not assetId:match("^rbxassetid://[0-9]+$") then
                table.insert(results.details, {
                    instance = path,
                    status = "Invalid Format",
                    issue = "Image ID format invalid: " .. assetId
                })
                results.failed = results.failed + 1
                return
            end
            
            -- If we've already validated this asset, use the cached result
            if validatedAssets[assetId] ~= nil then
                if validatedAssets[assetId] then
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
                        issue = "Asset failed to load (cached result)"
                    })
                end
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

-- Preload assets to ensure they're available when needed
function UIComponentFactory.preloadAssets(assetIds, callback)
    if typeof(assetIds) ~= "table" then
        assetIds = {assetIds}
    end
    
    -- Ensure all asset IDs are in the correct format
    local validAssets = {}
    for _, id in ipairs(assetIds) do
        if id:match("^rbxassetid://[0-9]+$") then
            table.insert(validAssets, id)
        else
            warn("[UIComponentFactory] Skipping invalid asset ID: " .. id)
        end
    end
    
    -- Preload the valid assets
    local success = pcall(function()
        ContentProvider:PreloadAsync(validAssets)
    end)
    
    -- Update cache with results
    for _, id in ipairs(validAssets) do
        validatedAssets[id] = success
    end
    
    if callback and typeof(callback) == "function" then
        callback(success, #validAssets)
    end
    
    return success
end

return UIComponentFactory
