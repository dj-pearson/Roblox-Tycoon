--!strict
--[[
    UIStyle.luau
    
    A central storage for UI styling information.
    This module provides consistent styling across all UI components.
    
    Created: April 27, 2025
]]

-- UIStyle specification
local UIStyle = {
    -- Color scheme
    colors = {
        -- Background colors
        background = Color3.fromRGB(40, 40, 60),           -- Main background color
        backgroundLight = Color3.fromRGB(60, 60, 80),      -- Lighter background variant
        backgroundDark = Color3.fromRGB(30, 30, 45),       -- Darker background variant
        backgroundHover = Color3.fromRGB(50, 50, 70),      -- Background hover state
        
        -- Accent colors
        accent = Color3.fromRGB(80, 150, 255),             -- Main accent color
        accentLight = Color3.fromRGB(130, 180, 255),       -- Lighter accent variant 
        accentDark = Color3.fromRGB(60, 120, 200),         -- Darker accent variant
        accentHover = Color3.fromRGB(90, 160, 255),        -- Accent hover state
        
        -- Text colors
        text = Color3.fromRGB(240, 240, 255),              -- Main text color
        textDark = Color3.fromRGB(200, 200, 220),          -- Secondary text color
        textDisabled = Color3.fromRGB(150, 150, 170),      -- Disabled text color
        textAccent = Color3.fromRGB(100, 170, 255),        -- Accent text color
        
        -- Feedback colors  
        success = Color3.fromRGB(80, 240, 120),            -- Success feedback
        warning = Color3.fromRGB(255, 200, 80),            -- Warning feedback
        error = Color3.fromRGB(255, 80, 80),               -- Error feedback
        info = Color3.fromRGB(100, 200, 255),              -- Information feedback
        
        -- Additional UI colors
        border = Color3.fromRGB(70, 70, 90),               -- Border color
        shadow = Color3.fromRGB(20, 20, 30),               -- Shadow color
        overlay = Color3.fromRGB(10, 10, 20),              -- Modal overlay color
    },
    
    -- Transparency values
    transparency = {
        shadowDefault = 0.6,                               -- Default shadow transparency
        overlayDefault = 0.5,                              -- Default overlay transparency
        disabledElement = 0.4,                             -- Transparency for disabled elements
        hoverEffect = 0.1,                                 -- Transparency change on hover
    },
    
    -- Font settings
    fonts = {
        header = Enum.Font.GothamBold,                     -- Header text font
        body = Enum.Font.Gotham,                           -- Body text font
        button = Enum.Font.GothamMedium,                   -- Button text font
        mono = Enum.Font.Code,                             -- Monospace font for code/data
    },
    
    -- Font sizes
    fontSizes = {
        title = 24,                                        -- Title text size
        header = 20,                                       -- Header text size
        subheader = 18,                                    -- Sub-header text size
        body = 16,                                         -- Body text size
        small = 14,                                        -- Small text size
        button = 16,                                       -- Button text size
        caption = 12,                                      -- Caption text size
    },
    
    -- Spacing and margins
    spacing = {
        tiny = 4,                                          -- Tiny spacing (4px)
        small = 8,                                         -- Small spacing (8px)
        medium = 12,                                       -- Medium spacing (12px)
        large = 16,                                        -- Large spacing (16px)
        xlarge = 24,                                       -- Extra large spacing (24px)
        xxlarge = 32,                                      -- Double extra large spacing (32px)
    },
    
    -- Border radius
    borderRadius = {
        none = UDim.new(0, 0),                             -- No corner radius
        small = UDim.new(0, 4),                            -- Small corner radius (4px)
        medium = UDim.new(0, 8),                           -- Medium corner radius (8px)
        large = UDim.new(0, 12),                           -- Large corner radius (12px)
        pill = UDim.new(0, 9999),                          -- Pill/circular radius (very large)
    },
    
    -- Animations
    animation = {
        -- Duration in seconds
        durationShort = 0.2,                               -- Short animation duration
        durationMedium = 0.3,                              -- Medium animation duration
        durationLong = 0.5,                                -- Long animation duration
        
        -- Easing styles
        easeIn = Enum.EasingStyle.Quad,                    -- Ease-in style
        easeOut = Enum.EasingStyle.Quad,                   -- Ease-out style 
        easeInOut = Enum.EasingStyle.Quad,                 -- Ease-in-out style
        
        -- Easing directions
        dirIn = Enum.EasingDirection.In,                   -- In direction
        dirOut = Enum.EasingDirection.Out,                 -- Out direction
        dirInOut = Enum.EasingDirection.InOut,             -- In-out direction
    },
    
    -- Z-index layers
    zIndex = {
        background = 1,                                    -- Background elements
        default = 10,                                      -- Default UI elements
        dropdown = 50,                                     -- Dropdown menus
        tooltip = 100,                                     -- Tooltips
        modal = 500,                                       -- Modal dialogs
        notification = 1000,                               -- Notifications
        maximum = 9999,                                    -- Maximum z-index
    },
}

-- Function to create color variants
function UIStyle:createColorVariant(baseColor, lightenAmount, darkenAmount)
    -- Create a lightened version
    local lightColor = Color3.new(
        math.min(baseColor.R + lightenAmount, 1),
        math.min(baseColor.G + lightenAmount, 1),
        math.min(baseColor.B + lightenAmount, 1)
    )
    
    -- Create a darkened version
    local darkColor = Color3.new(
        math.max(baseColor.R - darkenAmount, 0),
        math.max(baseColor.G - darkenAmount, 0),
        math.max(baseColor.B - darkenAmount, 0)
    )
    
    return {
        base = baseColor,
        light = lightColor,
        dark = darkColor
    }
end

-- Function to apply theme colors to an instance
function UIStyle:applyTheme(instance, colorType, textColorType)
    if typeof(instance) ~= "Instance" then 
        warn("UIStyle:applyTheme - First argument must be an Instance")
        return
    end
    
    -- Set the background color if the instance has this property
    if instance:IsA("GuiObject") and colorType then
        local color = self.colors[colorType]
        if color then
            instance.BackgroundColor3 = color
        end
    end
    
    -- Set the text color if applicable
    if (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) and textColorType then
        local textColor = self.colors[textColorType]
        if textColor then
            instance.TextColor3 = textColor
        end
    end
end

-- Register with ClientRegistry if available
local function registerWithClientRegistry()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then return end
    
    local clientRegistryModule = shared:FindFirstChild("ClientRegistry")
    if not clientRegistryModule then return end
    
    local success, clientRegistry = pcall(function()
        return require(clientRegistryModule)
    end)
    
    if success and clientRegistry and typeof(clientRegistry.registerUIComponent) == "function" then
        clientRegistry:registerUIComponent("UIStyle", UIStyle)
        print("UIStyle registered with ClientRegistry")
    end
end

-- Try to register with ClientRegistry
task.spawn(registerWithClientRegistry)

return UIStyle
