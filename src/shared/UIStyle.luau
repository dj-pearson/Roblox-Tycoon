--!strict
--[[
    UIStyle.luau
    
    Central style definitions for the UI system. Provides consistent colors,
    fonts, animations, and styling guidelines to be used across all UI components.
    
    Features:
    - Core color palette
    - Font definitions
    - Animation presets
    - UI element style guidelines
    - Theme support
    
    Author: Updated April 26, 2025
]]

local TweenService = game:GetService("TweenService")

-- Module table
local UIStyle = {}

-- Theme definitions
UIStyle.Themes = {
    Dark = {
        name = "Dark",
        colors = {
            Primary = Color3.fromRGB(114, 137, 218),       -- Blurple, primary brand color
            Secondary = Color3.fromRGB(50, 53, 59),        -- Dark gray for secondary elements
            Background = Color3.fromRGB(30, 33, 36),       -- Dark background
            BackgroundLight = Color3.fromRGB(40, 43, 46),  -- Slightly lighter background for panels
            Text = Color3.fromRGB(255, 255, 255),          -- White text
            TextDimmed = Color3.fromRGB(185, 187, 190),    -- Dimmed text for less important info
            Success = Color3.fromRGB(46, 204, 113),        -- Green for success states
            Warning = Color3.fromRGB(230, 126, 34),        -- Orange for warnings
            Error = Color3.fromRGB(231, 76, 60),           -- Red for errors
            Disabled = Color3.fromRGB(100, 100, 110),      -- Gray for disabled elements
            Highlight = Color3.fromRGB(130, 150, 230),     -- Highlight color
            Border = Color3.fromRGB(60, 63, 70)            -- Border color
        },
        transparency = {
            Modal = 0.5,                                   -- Transparency for modal backgrounds
            Hover = 0.9,                                   -- Transparency for hover effects
            Disabled = 0.7                                 -- Transparency for disabled elements
        }
    },
    Light = {
        name = "Light",
        colors = {
            Primary = Color3.fromRGB(114, 137, 218),       -- Blurple, primary brand color
            Secondary = Color3.fromRGB(220, 220, 220),     -- Light gray for secondary elements
            Background = Color3.fromRGB(245, 245, 245),    -- Light background
            BackgroundLight = Color3.fromRGB(255, 255, 255), -- White for panels
            Text = Color3.fromRGB(40, 40, 40),             -- Dark text
            TextDimmed = Color3.fromRGB(120, 120, 120),    -- Dimmed text for less important info
            Success = Color3.fromRGB(46, 204, 113),        -- Green for success states
            Warning = Color3.fromRGB(230, 126, 34),        -- Orange for warnings
            Error = Color3.fromRGB(231, 76, 60),           -- Red for errors
            Disabled = Color3.fromRGB(180, 180, 180),      -- Gray for disabled elements
            Highlight = Color3.fromRGB(130, 150, 230),     -- Highlight color
            Border = Color3.fromRGB(220, 220, 220)         -- Border color
        },
        transparency = {
            Modal = 0.3,                                   -- Transparency for modal backgrounds
            Hover = 0.9,                                   -- Transparency for hover effects
            Disabled = 0.5                                 -- Transparency for disabled elements
        }
    },
    Gaming = {
        name = "Gaming",
        colors = {
            Primary = Color3.fromRGB(255, 70, 85),         -- Vibrant red
            Secondary = Color3.fromRGB(45, 45, 55),        -- Dark gray for secondary elements
            Background = Color3.fromRGB(25, 25, 35),       -- Very dark background
            BackgroundLight = Color3.fromRGB(35, 35, 45),  -- Slightly lighter background for panels
            Text = Color3.fromRGB(240, 240, 255),          -- Slightly blue-tinted white text
            TextDimmed = Color3.fromRGB(170, 170, 195),    -- Dimmed text for less important info
            Success = Color3.fromRGB(0, 255, 170),         -- Neon green for success states
            Warning = Color3.fromRGB(255, 200, 60),        -- Bright yellow for warnings
            Error = Color3.fromRGB(255, 70, 85),           -- Bright red for errors
            Disabled = Color3.fromRGB(80, 80, 100),        -- Dark gray for disabled elements
            Highlight = Color3.fromRGB(0, 200, 255),       -- Bright blue highlight
            Border = Color3.fromRGB(70, 70, 90)            -- Border color
        },
        transparency = {
            Modal = 0.6,                                   -- Transparency for modal backgrounds
            Hover = 0.8,                                   -- Transparency for hover effects
            Disabled = 0.6                                 -- Transparency for disabled elements
        }
    }
}

-- Current theme (default to Dark)
UIStyle.CurrentTheme = "Dark"

-- Get active theme
local function getActiveTheme()
    return UIStyle.Themes[UIStyle.CurrentTheme] or UIStyle.Themes.Dark
end

-- Font definitions
UIStyle.Fonts = {
    Header = Enum.Font.GothamBold,
    SubHeader = Enum.Font.GothamMedium,
    Regular = Enum.Font.Gotham,
    Light = Enum.Font.GothamLight,
    Monospace = Enum.Font.Code,
    Logo = Enum.Font.GothamBold
}

-- Font sizes
UIStyle.FontSizes = {
    Tiny = 12,
    Small = 14,
    Regular = 16,
    Medium = 18,
    Large = 24,
    ExtraLarge = 32,
    Huge = 48
}

-- Animation presets
UIStyle.Animations = {
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Standard = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    Elastic = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    SlideIn = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    SlideOut = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
    FadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    FadeOut = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
}

-- Layout constants
UIStyle.Layout = {
    Padding = {
        Tiny = 4,
        Small = 8,
        Regular = 12,
        Medium = 16,
        Large = 24,
        ExtraLarge = 32
    },
    BorderRadius = {
        Small = UDim.new(0, 4),
        Regular = UDim.new(0, 8),
        Medium = UDim.new(0, 12),
        Large = UDim.new(0, 16),
        Round = UDim.new(1, 0)
    },
    BorderSize = {
        None = 0,
        Thin = 1,
        Regular = 2,
        Thick = 3
    },
    Shadow = {
        None = 0,
        Small = 2,
        Regular = 4,
        Large = 8
    }
}

-- Custom style presets for common UI elements
UIStyle.ElementStyles = {
    Button = {
        Primary = {
            BackgroundColor3 = function() return getActiveTheme().colors.Primary end,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            BorderSizePixel = 0,
            Font = UIStyle.Fonts.Regular,
            TextSize = UIStyle.FontSizes.Regular
        },
        Secondary = {
            BackgroundColor3 = function() return getActiveTheme().colors.Secondary end,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            BorderSizePixel = 0,
            Font = UIStyle.Fonts.Regular,
            TextSize = UIStyle.FontSizes.Regular
        },
        Danger = {
            BackgroundColor3 = function() return getActiveTheme().colors.Error end,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            BorderSizePixel = 0,
            Font = UIStyle.Fonts.Regular,
            TextSize = UIStyle.FontSizes.Regular
        },
        Success = {
            BackgroundColor3 = function() return getActiveTheme().colors.Success end,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            BorderSizePixel = 0,
            Font = UIStyle.Fonts.Regular,
            TextSize = UIStyle.FontSizes.Regular
        },
        Text = {
            BackgroundTransparency = 1,
            TextColor3 = function() return getActiveTheme().colors.Primary end,
            BorderSizePixel = 0,
            Font = UIStyle.Fonts.Regular,
            TextSize = UIStyle.FontSizes.Regular
        }
    },
    Input = {
        Default = {
            BackgroundColor3 = function() return getActiveTheme().colors.BackgroundLight end,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            PlaceholderColor3 = function() return getActiveTheme().colors.TextDimmed end,
            BorderSizePixel = 0,
            Font = UIStyle.Fonts.Regular,
            TextSize = UIStyle.FontSizes.Regular
        }
    },
    Label = {
        Header = {
            BackgroundTransparency = 1,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            Font = UIStyle.Fonts.Header,
            TextSize = UIStyle.FontSizes.Large
        },
        SubHeader = {
            BackgroundTransparency = 1,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            Font = UIStyle.Fonts.SubHeader,
            TextSize = UIStyle.FontSizes.Medium
        },
        Default = {
            BackgroundTransparency = 1,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            Font = UIStyle.Fonts.Regular,
            TextSize = UIStyle.FontSizes.Regular
        },
        Caption = {
            BackgroundTransparency = 1,
            TextColor3 = function() return getActiveTheme().colors.TextDimmed end,
            Font = UIStyle.Fonts.Light,
            TextSize = UIStyle.FontSizes.Small
        }
    },
    Frame = {
        Background = {
            BackgroundColor3 = function() return getActiveTheme().colors.Background end,
            BorderSizePixel = 0
        },
        Card = {
            BackgroundColor3 = function() return getActiveTheme().colors.BackgroundLight end,
            BorderSizePixel = 0
        },
        Highlight = {
            BackgroundColor3 = function() return getActiveTheme().colors.Primary:Lerp(getActiveTheme().colors.Background, 0.8) end,
            BorderSizePixel = 0
        }
    },
    ScrollingFrame = {
        Default = {
            BackgroundTransparency = 1,
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = function() return getActiveTheme().colors.Secondary end,
            BorderSizePixel = 0
        }
    },
    Toggle = {
        Default = {
            BackgroundColor3 = function() return getActiveTheme().colors.Secondary end,
            BorderSizePixel = 0
        },
        Active = {
            BackgroundColor3 = function() return getActiveTheme().colors.Primary end,
            BorderSizePixel = 0
        }
    },
    Dropdown = {
        Default = {
            BackgroundColor3 = function() return getActiveTheme().colors.BackgroundLight end,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            BorderSizePixel = 0,
            Font = UIStyle.Fonts.Regular,
            TextSize = UIStyle.FontSizes.Regular
        }
    },
    Modal = {
        Background = {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = function() return getActiveTheme().transparency.Modal end,
            BorderSizePixel = 0
        },
        Content = {
            BackgroundColor3 = function() return getActiveTheme().colors.BackgroundLight end,
            BorderSizePixel = 0
        }
    },
    Notification = {
        Info = {
            BackgroundColor3 = function() return getActiveTheme().colors.Primary end,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            BorderSizePixel = 0
        },
        Success = {
            BackgroundColor3 = function() return getActiveTheme().colors.Success end,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            BorderSizePixel = 0
        },
        Warning = {
            BackgroundColor3 = function() return getActiveTheme().colors.Warning end,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            BorderSizePixel = 0
        },
        Error = {
            BackgroundColor3 = function() return getActiveTheme().colors.Error end,
            TextColor3 = function() return getActiveTheme().colors.Text end,
            BorderSizePixel = 0
        }
    }
}

--[[ Style Application Functions ]]--

-- Apply style to an instance
function UIStyle:applyStyle(instance, styleType, variant)
    local style
    
    if styleType == "Button" then
        style = self.ElementStyles.Button[variant or "Primary"]
    elseif styleType == "Input" then
        style = self.ElementStyles.Input[variant or "Default"]
    elseif styleType == "Label" then
        style = self.ElementStyles.Label[variant or "Default"]
    elseif styleType == "Frame" then
        style = self.ElementStyles.Frame[variant or "Background"]
    elseif styleType == "ScrollingFrame" then
        style = self.ElementStyles.ScrollingFrame[variant or "Default"]
    elseif styleType == "Toggle" then
        style = self.ElementStyles.Toggle[variant or "Default"]
    elseif styleType == "Dropdown" then
        style = self.ElementStyles.Dropdown[variant or "Default"]
    elseif styleType == "Modal" then
        style = self.ElementStyles.Modal[variant or "Content"]
    elseif styleType == "Notification" then
        style = self.ElementStyles.Notification[variant or "Info"]
    else
        warn("Unknown style type: " .. styleType)
        return false
    end
    
    if not style then
        warn("Style variant not found: " .. tostring(variant))
        return false
    end
    
    -- Apply style properties
    for property, value in pairs(style) do
        -- If the value is a function, call it to get the actual value
        if typeof(value) == "function" then
            instance[property] = value()
        else
            instance[property] = value
        end
    end
    
    -- Add corner radius if applicable
    if styleType ~= "Label" and not instance:FindFirstChild("UICorner") and instance:IsA("GuiObject") then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = self.Layout.BorderRadius.Regular
        corner.Parent = instance
    end
    
    return true
end

-- Apply theme colors to an existing instance
function UIStyle:applyTheme(instance)
    -- Check if the instance has a styleType and variant tag
    local styleType = instance:GetAttribute("StyleType")
    local variant = instance:GetAttribute("StyleVariant")
    
    if styleType then
        self:applyStyle(instance, styleType, variant)
    end
    
    -- Recursively apply to children
    for _, child in ipairs(instance:GetChildren()) do
        if child:IsA("GuiObject") then
            self:applyTheme(child)
        end
    end
end

-- Change the current theme
function UIStyle:setTheme(themeName)
    if not self.Themes[themeName] then
        warn("Theme not found: " .. themeName)
        return false
    end
    
    self.CurrentTheme = themeName
    
    -- Find all GUIs with the StyleType attribute and update them
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                self:applyTheme(gui)
            end
        end
    end
    
    return true
end

-- Get the current colors
function UIStyle:getColor(colorName)
    local theme = getActiveTheme()
    return theme.colors[colorName] or Color3.new(1, 0, 1)  -- Magenta is the "missing color" indicator
end

-- Get font size by name
function UIStyle:getFontSize(sizeName)
    return self.FontSizes[sizeName] or self.FontSizes.Regular
end

-- Get font by name
function UIStyle:getFont(fontName)
    return self.Fonts[fontName] or self.Fonts.Regular
end

-- Get animation preset by name
function UIStyle:getAnimation(animationName)
    return self.Animations[animationName] or self.Animations.Standard
end

-- Get padding by name
function UIStyle:getPadding(paddingName)
    return self.Layout.Padding[paddingName] or self.Layout.Padding.Regular
end

-- Get border radius by name
function UIStyle:getBorderRadius(radiusName)
    return self.Layout.BorderRadius[radiusName] or self.Layout.BorderRadius.Regular
end

-- Return the module
return UIStyle
