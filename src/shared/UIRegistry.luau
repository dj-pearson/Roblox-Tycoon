--!strict
-- UIRegistry.luau
-- Centralized registry for UI components and utilities
-- Created on April 29, 2025 to fix UI system validation failures

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Import dependencies with fallbacks
local function safeRequire(path)
    local success, result = pcall(function()
        return require(path)
    end)
    
    if success then
        return result
    end
    
    return nil
end

-- Try to find AssetValidator
local AssetValidator = nil
local function findAssetValidator()
    -- Try various paths
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("Modules"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local validator = path:FindFirstChild("AssetValidator")
            if validator and validator:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(validator)
                end)
                
                if success and result then
                    print("[UIRegistry] Found AssetValidator at " .. validator:GetFullName())
                    return result
                end
            end
        end
    end
    
    -- Use our own path
    local thisScript = script
    local parentFolder = thisScript.Parent
    
    if parentFolder then
        local validator = parentFolder:FindFirstChild("AssetValidator")
        if validator and validator:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(validator)
            end)
            
            if success and result then
                print("[UIRegistry] Found AssetValidator in same folder as UIRegistry")
                return result
            end
        end
    end
    
    print("[UIRegistry] AssetValidator not found, using fallback")
    
    -- Fallback minimal implementation
    local fallbackValidator = {
        validateAsset = function(assetId, assetType)
            return true, assetId
        end,
        getDefaultAsset = function(assetType)
            return "rbxassetid://8587344193" -- Default blank image
        end
    }
    
    return fallbackValidator
end

-- Try to find UIComponents
local UIComponents = nil
local function findUIComponents()
    -- Try various paths
    local searchPaths = {
        ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("Modules"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local components = path:FindFirstChild("UIComponents")
            if components and components:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(components)
                end)
                
                if success and result then
                    print("[UIRegistry] Found UIComponents at " .. components:GetFullName())
                    return result
                end
            end
        end
    end
    
    print("[UIRegistry] UIComponents not found, using fallback")
    
    -- Fallback minimal implementation
    local fallbackComponents = {
        createButton = function(text, callback)
            local button = Instance.new("TextButton")
            button.Text = text
            button.Size = UDim2.new(0, 200, 0, 50)
            button.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            button.TextColor3 = Color3.new(1, 1, 1)
            button.Font = Enum.Font.GothamSemibold
            button.TextSize = 14
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = button
            
            if callback and typeof(callback) == "function" then
                button.Activated:Connect(callback)
            end
            
            return button
        end,
        
        createLabel = function(text)
            local label = Instance.new("TextLabel")
            label.Text = text
            label.Size = UDim2.new(0, 200, 0, 50)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            
            return label
        end
    }
    
    return fallbackComponents
end

-- Initialize registry
local UIRegistry = {}
local registeredComponents = {}
local registeredStyles = {}
local registeredIcons = {}
local registeredUIs = {}

-- Load dependencies
AssetValidator = findAssetValidator()
UIComponents = findUIComponents()

-- Default styles
local defaultStyles = {
    colors = {
        primary = Color3.fromRGB(52, 152, 219),
        secondary = Color3.fromRGB(46, 204, 113),
        accent = Color3.fromRGB(155, 89, 182),
        background = Color3.fromRGB(44, 62, 80),
        text = Color3.fromRGB(236, 240, 241),
        warning = Color3.fromRGB(230, 126, 34),
        error = Color3.fromRGB(231, 76, 60),
        success = Color3.fromRGB(39, 174, 96)
    },
    
    fonts = {
        title = Enum.Font.GothamBold,
        heading = Enum.Font.GothamSemibold,
        body = Enum.Font.Gotham,
        button = Enum.Font.GothamMedium
    },
    
    sizes = {
        title = 24,
        heading = 18,
        body = 14,
        button = 16,
        small = 12
    },
    
    padding = {
        small = UDim.new(0, 8),
        medium = UDim.new(0, 16),
        large = UDim.new(0, 24)
    },
    
    cornerRadius = {
        small = UDim.new(0, 4),
        medium = UDim.new(0, 8),
        large = UDim.new(0, 12)
    }
}

-- Default icons
local defaultIcons = {
    close = "rbxassetid://3926305904",
    settings = "rbxassetid://3926307971",
    info = "rbxassetid://3926305904",
    warning = "rbxassetid://3926305904",
    error = "rbxassetid://3926305904",
    success = "rbxassetid://3926305904",
    user = "rbxassetid://3926307971",
    add = "rbxassetid://3926307971",
    remove = "rbxassetid://3926305904"
}

-- Register a UI component
function UIRegistry.registerComponent(name, component)
    if not name or typeof(name) ~= "string" then
        warn("[UIRegistry] Invalid component name")
        return false
    end
    
    if not component then
        warn("[UIRegistry] Cannot register nil component: " .. name)
        return false
    end
    
    registeredComponents[name] = component
    print("[UIRegistry] Registered component: " .. name)
    return true
end

-- Get a registered component
function UIRegistry.getComponent(name)
    local component = registeredComponents[name]
    
    if not component then
        warn("[UIRegistry] Component not found: " .. tostring(name))
        
        -- Try to access from UIComponents as fallback
        if UIComponents and typeof(UIComponents) == "table" then
            if UIComponents[name] and typeof(UIComponents[name]) == "function" then
                return UIComponents[name]
            end
        end
        
        return nil
    end
    
    return component
end

-- Register a style
function UIRegistry.registerStyle(name, style)
    if not name or typeof(name) ~= "string" then
        warn("[UIRegistry] Invalid style name")
        return false
    end
    
    registeredStyles[name] = style or {}
    return true
end

-- Get a style
function UIRegistry.getStyle(name)
    -- If requesting default style, return it
    if name == "default" then
        return defaultStyles
    end
    
    -- Try to get registered style
    local style = registeredStyles[name]
    
    if not style then
        warn("[UIRegistry] Style not found: " .. tostring(name) .. ", using default")
        return defaultStyles
    end
    
    return style
end

-- Register an icon
function UIRegistry.registerIcon(name, iconId)
    if not name or typeof(name) ~= "string" then
        warn("[UIRegistry] Invalid icon name")
        return false
    end
    
    -- Validate asset if possible
    if AssetValidator then
        local isValid, validatedId = AssetValidator.validateAsset(iconId, "image")
        if not isValid then
            warn("[UIRegistry] Invalid icon asset: " .. tostring(iconId) .. ", using fallback")
            iconId = validatedId  -- This will be the fallback asset
        end
    end
    
    registeredIcons[name] = iconId
    return true
end

-- Get an icon
function UIRegistry.getIcon(name)
    -- Check registered icons
    local icon = registeredIcons[name]
    
    -- Check default icons if not found
    if not icon then
        icon = defaultIcons[name]
    end
    
    -- Use fallback if still not found
    if not icon and AssetValidator then
        warn("[UIRegistry] Icon not found: " .. tostring(name) .. ", using fallback")
        icon = AssetValidator.getDefaultAsset("image")
    elseif not icon then
        warn("[UIRegistry] Icon not found: " .. tostring(name) .. ", using hardcoded fallback")
        icon = "rbxassetid://8587344193"  -- Default blank image
    end
    
    return icon
end

-- Register a UI
function UIRegistry.registerUI(name, ui)
    if not name or typeof(name) ~= "string" then
        warn("[UIRegistry] Invalid UI name")
        return false
    end
    
    if not ui then
        warn("[UIRegistry] Cannot register nil UI: " .. name)
        return false
    end
    
    registeredUIs[name] = ui
    print("[UIRegistry] Registered UI: " .. name)
    return true
end

-- Get a UI
function UIRegistry.getUI(name)
    local ui = registeredUIs[name]
    
    if not ui then
        warn("[UIRegistry] UI not found: " .. tostring(name))
        return nil
    end
    
    return ui
}

-- Create a new UI frame with consistent styling
function UIRegistry.createFrame(name, parent)
    local frame = Instance.new("Frame")
    frame.Name = name or "UIFrame"
    frame.BackgroundColor3 = defaultStyles.colors.background
    frame.BorderSizePixel = 0
    
    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = defaultStyles.cornerRadius.medium
    corner.Parent = frame
    
    -- Add auto padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = defaultStyles.padding.medium
    padding.PaddingBottom = defaultStyles.padding.medium
    padding.PaddingLeft = defaultStyles.padding.medium
    padding.PaddingRight = defaultStyles.padding.medium
    padding.Parent = frame
    
    if parent then
        frame.Parent = parent
    end
    
    return frame
end

-- Initialize with basic components
local function init()
    -- Register default styles
    UIRegistry.registerStyle("default", defaultStyles)
    
    -- Register default icons
    for name, iconId in pairs(defaultIcons) do
        UIRegistry.registerIcon(name, iconId)
    end
    
    -- Register basic components from UIComponents
    if UIComponents then
        for name, component in pairs(UIComponents) do
            if typeof(component) == "function" then
                UIRegistry.registerComponent(name, component)
            end
        end
    end
    
    print("[UIRegistry] Initialized with default styles and components")
end

-- Delay initialization to give other modules a chance to load
task.spawn(function()
    task.wait(1)
    init()
end)

return UIRegistry
