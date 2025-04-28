--[[
    UISystemRegistration.client.luau
    
    Addresses UI System issues by ensuring all UI components are properly registered
    and available. Creates fallbacks when original components cannot be found.
    
    Created: April 27, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    COMPONENT_TIMEOUT = 5, -- seconds
    AUTO_CREATE_FALLBACKS = true
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[UISystemRegistration] " .. message)
    end
end

-- Find ClientRegistry (with multiple strategies)
local ClientRegistry
do
    -- Strategy 1: Use ModuleLoaderHelper
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleLoaderHelper") then
        local success, ModuleLoaderHelper = pcall(function()
            return require(shared.ModuleLoaderHelper)
        end)
        
        if success and ModuleLoaderHelper and ModuleLoaderHelper.GetModule then
            ClientRegistry = ModuleLoaderHelper.GetModule("ClientRegistry")
            if ClientRegistry then
                log("ClientRegistry found via ModuleLoaderHelper")
            end
        end
    end
    
    -- Strategy 2: Direct require from shared folder
    if not ClientRegistry then
        if shared and shared:FindFirstChild("ClientRegistry") then
            local success, result = pcall(function()
                return require(shared.ClientRegistry)
            end)
            
            if success and result then
                ClientRegistry = result
                log("ClientRegistry found in shared folder")
            end
        end
    end
    
    -- Strategy 3: Try ClientBootstrap
    if not ClientRegistry then
        local clientScripts = Player:FindFirstChild("PlayerScripts")
        if clientScripts and clientScripts:FindFirstChild("ClientBootstrap") then
            local success, ClientBootstrap = pcall(function()
                return require(clientScripts.ClientBootstrap)
            end)
            
            if success and ClientBootstrap and ClientBootstrap.getClientRegistry then
                ClientRegistry = ClientBootstrap.getClientRegistry()
                if ClientRegistry then
                    log("ClientRegistry found via ClientBootstrap")
                end
            end
        end
    end
    
    if not ClientRegistry then
        log("ClientRegistry not found, creating minimal implementation")
        
        -- Create minimal ClientRegistry
        ClientRegistry = {
            systems = {},
            initialized = {},
            
            registerSystem = function(name, system, dependencies)
                ClientRegistry.systems[name] = {
                    module = system,
                    dependencies = dependencies or {}
                }
                log("Registered system: " .. name)
                return system
            end,
            
            getSystem = function(name)
                -- Return already initialized system
                if ClientRegistry.initialized[name] then
                    return ClientRegistry.initialized[name]
                end
                
                -- Check if system exists
                if not ClientRegistry.systems[name] then
                    return nil
                end
                
                -- Initialize the system
                local system = ClientRegistry.systems[name].module
                if typeof(system.initialize) == "function" then
                    local success, result = pcall(function()
                        return system:initialize()
                    end)
                    
                    if not success then
                        warn("[UISystemRegistration] Failed to initialize " .. name .. ": " .. tostring(result))
                    end
                end
                
                -- Mark as initialized
                ClientRegistry.initialized[name] = system
                return system
            end,
            
            hasSystem = function(name)
                return ClientRegistry.systems[name] ~= nil or ClientRegistry.initialized[name] ~= nil
            end
        }
    end
end

-- Safe require function
local function safeRequire(module, fallback)
    if not module then
        return fallback
    end
    
    if not module:IsA("ModuleScript") then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[UISystemRegistration] Failed to require module: " .. module:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Safe wait for child with timeout
local function safeWaitForChild(parent, childName, timeout)
    if not parent then return nil end
    timeout = timeout or CONFIG.COMPONENT_TIMEOUT
    
    -- Check if child already exists
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    -- Try using WaitForChild with a timeout
    local startTime = os.clock()
    
    while os.clock() - startTime < timeout do
        child = parent:FindFirstChild(childName)
        if child then return child end
        task.wait(0.1)
    end
    
    return nil
end

-- Check for UI Components and create fallbacks
local function ensureUIComponents()
    log("Checking for UI components...")
    
    -- Check if UIComponents system exists
    local UIComponents = ClientRegistry:getSystem("UIComponents")
    if not UIComponents and CONFIG.AUTO_CREATE_FALLBACKS then
        log("Creating UIComponents fallback")
        
        -- Create minimal UIComponents
        UIComponents = {
            components = {},
            
            registerComponent = function(name, component)
                UIComponents.components[name] = component
                log("Registered UI component: " .. name)
                return component
            end,
            
            getComponent = function(name)
                return UIComponents.components[name]
            end,
            
            initialize = function()
                log("UIComponents initialized")
                return true
            end
        }
        
        -- Register with ClientRegistry
        ClientRegistry:registerSystem("UIComponents", UIComponents, {})
    end
    
    -- Check for UIStyle
    local UIStyle = ClientRegistry:getSystem("UIStyle")
    if not UIStyle and CONFIG.AUTO_CREATE_FALLBACKS then
        log("Creating UIStyle fallback")
        
        -- Create minimal UIStyle
        UIStyle = {
            Colors = {
                Background = Color3.fromRGB(40, 40, 40),
                Primary = Color3.fromRGB(0, 120, 215),
                Secondary = Color3.fromRGB(0, 90, 160),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(180, 180, 180),
                Success = Color3.fromRGB(50, 200, 80),
                Warning = Color3.fromRGB(240, 180, 10),
                Error = Color3.fromRGB(220, 50, 50),
            },
            
            Fonts = {
                Header = Enum.Font.GothamBold,
                Body = Enum.Font.Gotham,
                Button = Enum.Font.GothamMedium
            },
            
            Sizes = {
                Tiny = 10,
                Small = 14,
                Normal = 18,
                Large = 24,
                ExtraLarge = 32
            },
            
            Padding = {
                Small = UDim.new(0, 4),
                Normal = UDim.new(0, 8),
                Large = UDim.new(0, 12)
            },
            
            CornerRadius = {
                Small = UDim.new(0, 4),
                Normal = UDim.new(0, 8),
                Large = UDim.new(0, 12),
                Round = UDim.new(1, 0)
            },
            
            Borders = {
                None = 0,
                Thin = 1,
                Normal = 2,
                Thick = 3
            },
            
            initialize = function()
                log("UIStyle initialized")
                return true
            end
        }
        
        -- Register with ClientRegistry
        ClientRegistry:registerSystem("UIStyle", UIStyle, {})
    end
    
    -- Check for UIUtils
    local UIUtils = ClientRegistry:getSystem("UIUtils")
    if not UIUtils and CONFIG.AUTO_CREATE_FALLBACKS then
        log("Creating UIUtils fallback")
        
        -- Create minimal UIUtils
        UIUtils = {
            createFrame = function(props)
                local frame = Instance.new("Frame")
                
                -- Apply properties
                for prop, value in pairs(props or {}) do
                    if prop ~= "Children" then
                        frame[prop] = value
                    end
                end
                
                -- Add children
                if props and props.Children then
                    for _, child in ipairs(props.Children) do
                        child.Parent = frame
                    end
                end
                
                return frame
            end,
            
            createTextLabel = function(props)
                local label = Instance.new("TextLabel")
                
                -- Apply properties
                for prop, value in pairs(props or {}) do
                    if prop ~= "Children" then
                        label[prop] = value
                    end
                end
                
                -- Add children
                if props and props.Children then
                    for _, child in ipairs(props.Children) do
                        child.Parent = label
                    end
                end
                
                return label
            end,
            
            createButton = function(props)
                local button = Instance.new("TextButton")
                
                -- Apply properties
                for prop, value in pairs(props or {}) do
                    if prop ~= "Children" and prop ~= "OnClick" then
                        button[prop] = value
                    end
                end
                
                -- Set click handler
                if props and props.OnClick then
                    button.MouseButton1Click:Connect(props.OnClick)
                end
                
                -- Add children
                if props and props.Children then
                    for _, child in ipairs(props.Children) do
                        child.Parent = button
                    end
                end
                
                return button
            end,
            
            createIconButton = function(props)
                local button = UIUtils.createButton(props)
                
                -- Add icon if specified
                if props and props.Icon then
                    local icon = Instance.new("ImageLabel")
                    icon.Name = "Icon"
                    icon.Size = UDim2.new(0.8, 0, 0.8, 0)
                    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
                    icon.AnchorPoint = Vector2.new(0.5, 0.5)
                    icon.BackgroundTransparency = 1
                    icon.Image = props.Icon
                    icon.Parent = button
                end
                
                return button
            end,
            
            createProgressBar = function(props)
                props = props or {}
                
                -- Create container
                local container = UIUtils.createFrame({
                    Name = props.Name or "ProgressBar",
                    Size = props.Size or UDim2.new(1, 0, 0, 20),
                    Position = props.Position or UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = UIStyle and UIStyle.Colors.Background or Color3.fromRGB(40, 40, 40),
                    BorderSizePixel = 0
                })
                
                -- Create fill
                local fill = UIUtils.createFrame({
                    Name = "Fill",
                    Size = UDim2.new(props.Progress or 0, 0, 1, 0),
                    BackgroundColor3 = UIStyle and UIStyle.Colors.Primary or Color3.fromRGB(0, 120, 215),
                    BorderSizePixel = 0
                })
                fill.Parent = container
                
                -- Add text if specified
                if props.ShowPercentage then
                    local textLabel = UIUtils.createTextLabel({
                        Name = "PercentageLabel",
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = tostring(math.floor((props.Progress or 0) * 100)) .. "%",
                        TextColor3 = UIStyle and UIStyle.Colors.Text or Color3.fromRGB(255, 255, 255),
                        Font = UIStyle and UIStyle.Fonts.Body or Enum.Font.Gotham,
                        TextSize = 14
                    })
                    textLabel.Parent = container
                end
                
                -- Add update method
                container.UpdateProgress = function(self, progress)
                    fill.Size = UDim2.new(progress, 0, 1, 0)
                    
                    local percentageLabel = container:FindFirstChild("PercentageLabel")
                    if percentageLabel then
                        percentageLabel.Text = tostring(math.floor(progress * 100)) .. "%"
                    end
                end
                
                return container
            end,
            
            initialize = function()
                log("UIUtils initialized")
                return true
            end
        }
        
        -- Register with ClientRegistry
        ClientRegistry:registerSystem("UIUtils", UIUtils, {})
    end
    
    -- Return the components
    return {
        UIComponents = UIComponents,
        UIStyle = UIStyle,
        UIUtils = UIUtils
    }
end

-- Initialize the UI system
local function initialize()
    log("Initializing UI system registration...")
    
    -- Ensure UI components exist
    local components = ensureUIComponents()
    
    -- Register this module with ClientRegistry 
    ClientRegistry:registerSystem("UISystemRegistration", {
        components = components,
        
        initialize = function()
            log("UISystemRegistration initialized")
            return true
        end,
        
        -- Helper method to create UI elements
        createUI = function(uiName, parent)
            log("Creating UI: " .. uiName)
            
            local UIUtils = components.UIUtils
            local UIStyle = components.UIStyle
            
            if not UIUtils then
                warn("[UISystemRegistration] UIUtils not available, cannot create " .. uiName)
                return nil
            end
            
            if uiName == "RebirthMenuUI" then
                -- Create a simple rebirth menu as a fallback
                local menu = UIUtils.createFrame({
                    Name = "RebirthMenuUI",
                    Size = UDim2.new(0, 300, 0, 400),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = UIStyle and UIStyle.Colors.Background or Color3.fromRGB(40, 40, 40),
                    BorderSizePixel = 0
                })
                
                -- Add header
                local header = UIUtils.createTextLabel({
                    Name = "Header",
                    Size = UDim2.new(1, 0, 0, 50),
                    BackgroundColor3 = UIStyle and UIStyle.Colors.Primary or Color3.fromRGB(0, 120, 215),
                    Text = "Rebirth Menu",
                    TextColor3 = UIStyle and UIStyle.Colors.Text or Color3.fromRGB(255, 255, 255),
                    Font = UIStyle and UIStyle.Fonts.Header or Enum.Font.GothamBold,
                    TextSize = UIStyle and UIStyle.Sizes.Large or 24
                })
                header.Parent = menu
                
                -- Add close button
                local closeButton = UIUtils.createIconButton({
                    Name = "CloseButton",
                    Size = UDim2.new(0, 40, 0, 40),
                    Position = UDim2.new(1, -5, 0, 5),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = UIStyle and UIStyle.Colors.Error or Color3.fromRGB(220, 50, 50),
                    Text = "X",
                    TextColor3 = UIStyle and UIStyle.Colors.Text or Color3.fromRGB(255, 255, 255),
                    Font = UIStyle and UIStyle.Fonts.Button or Enum.Font.GothamBold,
                    TextSize = UIStyle and UIStyle.Sizes.Normal or 18,
                    OnClick = function()
                        menu.Visible = false
                    end
                })
                closeButton.Parent = menu
                
                -- Add content
                local content = UIUtils.createFrame({
                    Name = "Content",
                    Size = UDim2.new(1, -20, 1, -70),
                    Position = UDim2.new(0, 10, 0, 60),
                    BackgroundTransparency = 1
                })
                content.Parent = menu
                
                -- Add rebirth button
                local rebirthButton = UIUtils.createButton({
                    Name = "RebirthButton",
                    Size = UDim2.new(1, 0, 0, 50),
                    Position = UDim2.new(0, 0, 1, -70),
                    BackgroundColor3 = UIStyle and UIStyle.Colors.Secondary or Color3.fromRGB(0, 90, 160),
                    Text = "Rebirth Now",
                    TextColor3 = UIStyle and UIStyle.Colors.Text or Color3.fromRGB(255, 255, 255),
                    Font = UIStyle and UIStyle.Fonts.Button or Enum.Font.GothamBold,
                    TextSize = UIStyle and UIStyle.Sizes.Normal or 18
                })
                rebirthButton.Parent = content
                
                -- Add some info text
                local infoText = UIUtils.createTextLabel({
                    Name = "InfoText",
                    Size = UDim2.new(1, 0, 0, 100),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "Rebirthing will reset your progress but give you permanent bonuses!",
                    TextColor3 = UIStyle and UIStyle.Colors.Text or Color3.fromRGB(255, 255, 255),
                    Font = UIStyle and UIStyle.Fonts.Body or Enum.Font.Gotham,
                    TextSize = UIStyle and UIStyle.Sizes.Normal or 18,
                    TextWrapped = true
                })
                infoText.Parent = content
                
                -- Set parent
                menu.Parent = parent or PlayerGui
                
                log("Created fallback RebirthMenuUI")
                return menu
            end
            
            -- Add more UI types as needed
            
            warn("[UISystemRegistration] Unknown UI type: " .. uiName)
            return nil
        end
    }, {})
    
    log("UI system registration complete")
end

-- Run the initialization
local success, result = pcall(initialize)
if not success then
    warn("[UISystemRegistration] Error during initialization: " .. tostring(result))
end

-- Return the module
return {
    ClientRegistry = ClientRegistry,
    ensureUIComponents = ensureUIComponents
}
