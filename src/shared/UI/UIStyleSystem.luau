--!strict
--[[
    UIStyleSystem.luau
    
    Enhanced styling system for UI components.
    Provides theme support, style inheritance, and style application.
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import ModuleLoaderHelper
local ModuleLoaderHelper = nil
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
    else
        warn("[UIStyleSystem] Failed to load ModuleLoaderHelper, using direct requires")
    end
end

-- Try to load the base UIStyle
local BaseUIStyle = nil
if ModuleLoaderHelper then
    BaseUIStyle = ModuleLoaderHelper.loadModule("UIStyle")
else
    local uiStyleModule = ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("UIStyle")
    if uiStyleModule then
        BaseUIStyle = require(uiStyleModule)
    end
end

local UIStyleSystem = {
    -- Current active theme
    activeTheme = "default",
    
    -- Available themes
    themes = {},
    
    -- Component-specific styles
    componentStyles = {},
    
    -- Configuration
    debug = true
}

-- Simple logging function
local function log(message, level)
    if not UIStyleSystem.debug and level ~= "Error" then 
        return 
    end
    
    local prefix = "[UIStyleSystem]"
    if level == "Error" then
        warn(prefix .. " " .. message)
    elseif level == "Success" then
        print(prefix .. " ✓ " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Initialize the default theme using the base UIStyle
if BaseUIStyle then
    UIStyleSystem.themes["default"] = {
        colors = BaseUIStyle.colors,
        transparency = BaseUIStyle.transparency,
        typography = BaseUIStyle.typography,
        layouts = BaseUIStyle.layouts,
        animation = BaseUIStyle.animation,
        corners = BaseUIStyle.corners or {
            small = UDim.new(0, 4),
            medium = UDim.new(0, 8),
            large = UDim.new(0, 12),
            round = UDim.new(0.5, 0)
        },
        shadows = BaseUIStyle.shadows or {
            none = {
                blur = 0,
                offset = Vector2.new(0, 0),
                transparency = 1
            },
            small = {
                blur = 4,
                offset = Vector2.new(0, 2),
                transparency = 0.7
            },
            medium = {
                blur = 8,
                offset = Vector2.new(0, 4),
                transparency = 0.6
            },
            large = {
                blur = 16,
                offset = Vector2.new(0, 8),
                transparency = 0.5
            }
        },
        spacing = BaseUIStyle.spacing or {
            none = 0,
            xs = 2,
            small = 4,
            medium = 8,
            large = 16,
            xl = 24,
            xxl = 32
        }
    }
    
    log("Initialized default theme from base UIStyle", "Success")
else
    warn("[UIStyleSystem] Base UIStyle not found, using fallback colors")
    
    -- Fallback default theme
    UIStyleSystem.themes["default"] = {
        colors = {
            -- Background colors
            background = Color3.fromRGB(40, 40, 60),
            backgroundLight = Color3.fromRGB(60, 60, 80),
            backgroundDark = Color3.fromRGB(30, 30, 45),
            backgroundHover = Color3.fromRGB(50, 50, 70),
            
            -- Accent colors
            accent = Color3.fromRGB(80, 150, 255),
            accentLight = Color3.fromRGB(130, 180, 255),
            accentDark = Color3.fromRGB(60, 120, 200),
            accentHover = Color3.fromRGB(90, 160, 255),
            
            -- Text colors
            text = Color3.fromRGB(240, 240, 255),
            textDark = Color3.fromRGB(200, 200, 220),
            textDisabled = Color3.fromRGB(150, 150, 170),
            textAccent = Color3.fromRGB(100, 170, 255),
            
            -- Feedback colors  
            success = Color3.fromRGB(80, 240, 120),
            warning = Color3.fromRGB(255, 200, 80),
            error = Color3.fromRGB(255, 80, 80),
            info = Color3.fromRGB(100, 200, 255),
            
            -- Additional UI colors
            border = Color3.fromRGB(70, 70, 90),
            shadow = Color3.fromRGB(20, 20, 30),
            overlay = Color3.fromRGB(10, 10, 20),
        },
        
        transparency = {
            shadowDefault = 0.6,
            overlayDefault = 0.5,
            disabledElement = 0.4,
            hoverEffect = 0.1,
        },
        
        typography = {
            heading1 = {
                font = Enum.Font.GothamBold,
                size = 32
            },
            heading2 = {
                font = Enum.Font.GothamBold,
                size = 24
            },
            heading3 = {
                font = Enum.Font.GothamBold,
                size = 20
            },
            body = {
                font = Enum.Font.Gotham,
                size = 16
            },
            small = {
                font = Enum.Font.Gotham,
                size = 14
            },
            button = {
                font = Enum.Font.GothamBold,
                size = 16
            }
        },
        
        corners = {
            small = UDim.new(0, 4),
            medium = UDim.new(0, 8),
            large = UDim.new(0, 12),
            round = UDim.new(0.5, 0)
        },
        
        shadows = {
            none = {
                blur = 0,
                offset = Vector2.new(0, 0),
                transparency = 1
            },
            small = {
                blur = 4,
                offset = Vector2.new(0, 2),
                transparency = 0.7
            },
            medium = {
                blur = 8,
                offset = Vector2.new(0, 4),
                transparency = 0.6
            },
            large = {
                blur = 16,
                offset = Vector2.new(0, 8),
                transparency = 0.5
            }
        },
        
        spacing = {
            none = 0,
            xs = 2,
            small = 4,
            medium = 8,
            large = 16,
            xl = 24,
            xxl = 32
        }
    }
end

--[[
    Create a dark theme based on default theme
]]
UIStyleSystem.themes["dark"] = {
    colors = {
        -- Background colors (darker)
        background = Color3.fromRGB(30, 30, 40),
        backgroundLight = Color3.fromRGB(45, 45, 60),
        backgroundDark = Color3.fromRGB(20, 20, 25),
        backgroundHover = Color3.fromRGB(40, 40, 50),
        
        -- Accent colors (same as default)
        accent = UIStyleSystem.themes.default.colors.accent,
        accentLight = UIStyleSystem.themes.default.colors.accentLight,
        accentDark = UIStyleSystem.themes.default.colors.accentDark,
        accentHover = UIStyleSystem.themes.default.colors.accentHover,
        
        -- Text colors (brighter for contrast)
        text = Color3.fromRGB(255, 255, 255),
        textDark = Color3.fromRGB(210, 210, 230),
        textDisabled = Color3.fromRGB(160, 160, 180),
        textAccent = Color3.fromRGB(110, 180, 255),
        
        -- Feedback colors (same as default)
        success = UIStyleSystem.themes.default.colors.success,
        warning = UIStyleSystem.themes.default.colors.warning,
        error = UIStyleSystem.themes.default.colors.error,
        info = UIStyleSystem.themes.default.colors.info,
        
        -- Additional UI colors
        border = Color3.fromRGB(60, 60, 75),
        shadow = Color3.fromRGB(15, 15, 20),
        overlay = Color3.fromRGB(5, 5, 10),
    },
    
    -- Inherit other properties from default theme
    transparency = UIStyleSystem.themes.default.transparency,
    typography = UIStyleSystem.themes.default.typography,
    corners = UIStyleSystem.themes.default.corners,
    shadows = UIStyleSystem.themes.default.shadows,
    spacing = UIStyleSystem.themes.default.spacing
}

--[[
    Create a light theme
]]
UIStyleSystem.themes["light"] = {
    colors = {
        -- Background colors (light)
        background = Color3.fromRGB(240, 240, 245),
        backgroundLight = Color3.fromRGB(255, 255, 255),
        backgroundDark = Color3.fromRGB(220, 220, 230),
        backgroundHover = Color3.fromRGB(230, 230, 240),
        
        -- Accent colors (same as default)
        accent = UIStyleSystem.themes.default.colors.accent,
        accentLight = UIStyleSystem.themes.default.colors.accentLight,
        accentDark = UIStyleSystem.themes.default.colors.accentDark,
        accentHover = UIStyleSystem.themes.default.colors.accentHover,
        
        -- Text colors (dark for contrast)
        text = Color3.fromRGB(40, 40, 60),
        textDark = Color3.fromRGB(60, 60, 80),
        textDisabled = Color3.fromRGB(150, 150, 170),
        textAccent = Color3.fromRGB(60, 120, 220),
        
        -- Feedback colors (same as default)
        success = UIStyleSystem.themes.default.colors.success,
        warning = UIStyleSystem.themes.default.colors.warning,
        error = UIStyleSystem.themes.default.colors.error,
        info = UIStyleSystem.themes.default.colors.info,
        
        -- Additional UI colors
        border = Color3.fromRGB(200, 200, 220),
        shadow = Color3.fromRGB(180, 180, 200),
        overlay = Color3.fromRGB(240, 240, 250),
    },
    
    -- Inherit other properties from default theme
    transparency = UIStyleSystem.themes.default.transparency,
    typography = UIStyleSystem.themes.default.typography,
    corners = UIStyleSystem.themes.default.corners,
    shadows = UIStyleSystem.themes.default.shadows,
    spacing = UIStyleSystem.themes.default.spacing
}

--[[
    Register a new theme
    @param name - Theme name
    @param theme - Theme properties
    @return - Success status
]]
function UIStyleSystem:registerTheme(name, theme)
    if not name or not theme then
        log("Invalid theme name or properties", "Error")
        return false
    end
    
    -- Copy existing theme as base if specified
    if theme.baseTheme and self.themes[theme.baseTheme] then
        local baseTheme = self.themes[theme.baseTheme]
        local newTheme = {}
        
        -- Deep copy base theme
        for key, value in pairs(baseTheme) do
            if typeof(value) == "table" then
                newTheme[key] = table.clone(value)
            else
                newTheme[key] = value
            end
        end
        
        -- Apply overrides
        for key, value in pairs(theme) do
            if key ~= "baseTheme" then
                if typeof(value) == "table" and typeof(newTheme[key]) == "table" then
                    -- Merge tables
                    for subKey, subValue in pairs(value) do
                        newTheme[key][subKey] = subValue
                    end
                else
                    newTheme[key] = value
                end
            end
        end
        
        self.themes[name] = newTheme
    else
        -- Store new theme directly
        self.themes[name] = theme
    end
    
    log("Registered theme: " .. name, "Success")
    return true
end

--[[
    Set the active theme
    @param themeName - Name of the theme to activate
    @return - Success status
]]
function UIStyleSystem:setTheme(themeName)
    if not self.themes[themeName] then
        log("Theme not found: " .. themeName, "Error")
        return false
    end
    
    self.activeTheme = themeName
    log("Set active theme to: " .. themeName, "Success")
    
    -- If needed, trigger theme change event here
    
    return true
end

--[[
    Get the active theme properties
    @return - Active theme properties
]]
function UIStyleSystem:getActiveTheme()
    return self.themes[self.activeTheme]
end

--[[
    Get a value from the active theme
    @param path - Dot-notation path to the value (e.g., "colors.background")
    @param defaultValue - Default value if path not found
    @return - The theme value or defaultValue
]]
function UIStyleSystem:getValue(path, defaultValue)
    local parts = {}
    for part in string.gmatch(path, "[^.]+") do
        table.insert(parts, part)
    end
    
    local theme = self:getActiveTheme()
    if not theme then
        return defaultValue
    end
    
    local current = theme
    for _, part in ipairs(parts) do
        if typeof(current) ~= "table" or current[part] == nil then
            return defaultValue
        end
        current = current[part]
    end
    
    return current
end

--[[
    Register a component-specific style
    @param componentName - Name of the component
    @param style - Style properties for the component
    @return - Success status
]]
function UIStyleSystem:registerComponentStyle(componentName, style)
    if not componentName or not style then
        log("Invalid component name or style", "Error")
        return false
    end
    
    self.componentStyles[componentName] = style
    log("Registered style for component: " .. componentName, "Success")
    return true
end

--[[
    Get a component-specific style
    @param componentName - Name of the component
    @return - Component style or nil if not found
]]
function UIStyleSystem:getComponentStyle(componentName)
    return self.componentStyles[componentName]
end

--[[
    Apply style to a UI instance
    @param instance - UI instance to style
    @param styleProps - Style properties to apply
    @return - The styled instance
]]
function UIStyleSystem:applyStyle(instance, styleProps)
    if not instance then
        return nil
    end
    
    styleProps = styleProps or {}
    
    -- Handle common properties
    if instance:IsA("GuiObject") then
        -- Background color
        if styleProps.backgroundColor then
            instance.BackgroundColor3 = styleProps.backgroundColor
        end
        
        -- Background transparency
        if styleProps.backgroundTransparency ~= nil then
            instance.BackgroundTransparency = styleProps.backgroundTransparency
        end
        
        -- Border
        if styleProps.borderColor then
            instance.BorderColor3 = styleProps.borderColor
        end
        
        if styleProps.borderSizePixel ~= nil then
            instance.BorderSizePixel = styleProps.borderSizePixel
        end
        
        -- Size and position
        if styleProps.size then
            instance.Size = styleProps.size
        end
        
        if styleProps.position then
            instance.Position = styleProps.position
        end
        
        if styleProps.anchorPoint then
            instance.AnchorPoint = styleProps.anchorPoint
        end
        
        -- Corner radius
        if styleProps.cornerRadius and not instance:FindFirstChild("UICorner") then
            local corner = Instance.new("UICorner")
            corner.CornerRadius = typeof(styleProps.cornerRadius) == "UDim" 
                              and styleProps.cornerRadius 
                              or UDim.new(0, styleProps.cornerRadius)
            corner.Parent = instance
        elseif styleProps.cornerRadius and instance:FindFirstChild("UICorner") then
            instance.UICorner.CornerRadius = typeof(styleProps.cornerRadius) == "UDim" 
                                         and styleProps.cornerRadius 
                                         or UDim.new(0, styleProps.cornerRadius)
        end
    end
    
    -- Handle text properties
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        -- Text color
        if styleProps.textColor then
            instance.TextColor3 = styleProps.textColor
        end
        
        -- Text transparency
        if styleProps.textTransparency ~= nil then
            instance.TextTransparency = styleProps.textTransparency
        end
        
        -- Font
        if styleProps.font then
            instance.Font = styleProps.font
        end
        
        -- Text size
        if styleProps.textSize then
            instance.TextSize = styleProps.textSize
        end
        
        -- Text wrapping
        if styleProps.textWrapped ~= nil then
            instance.TextWrapped = styleProps.textWrapped
        end
        
        -- Text XAlignment
        if styleProps.textXAlignment then
            instance.TextXAlignment = styleProps.textXAlignment
        end
        
        -- Text YAlignment
        if styleProps.textYAlignment then
            instance.TextYAlignment = styleProps.textYAlignment
        end
        
        -- Rich text
        if styleProps.richText ~= nil then
            instance.RichText = styleProps.richText
        end
    end
    
    -- Handle image properties
    if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        -- Image
        if styleProps.image then
            instance.Image = styleProps.image
        end
        
        -- Image color
        if styleProps.imageColor then
            instance.ImageColor3 = styleProps.imageColor
        end
        
        -- Image transparency
        if styleProps.imageTransparency ~= nil then
            instance.ImageTransparency = styleProps.imageTransparency
        end
        
        -- Image rect
        if styleProps.imageRectOffset then
            instance.ImageRectOffset = styleProps.imageRectOffset
        end
        
        if styleProps.imageRectSize then
            instance.ImageRectSize = styleProps.imageRectSize
        end
    end
    
    -- Add stroke if requested
    if styleProps.stroke and not instance:FindFirstChild("UIStroke") then
        local stroke = Instance.new("UIStroke")
        stroke.Color = styleProps.stroke.color or Color3.fromRGB(0, 0, 0)
        stroke.Thickness = styleProps.stroke.thickness or 1
        stroke.Transparency = styleProps.stroke.transparency or 0
        stroke.Parent = instance
    elseif styleProps.stroke and instance:FindFirstChild("UIStroke") then
        local stroke = instance.UIStroke
        if styleProps.stroke.color then
            stroke.Color = styleProps.stroke.color
        end
        if styleProps.stroke.thickness then
            stroke.Thickness = styleProps.stroke.thickness
        end
        if styleProps.stroke.transparency ~= nil then
            stroke.Transparency = styleProps.stroke.transparency
        end
    end
    
    -- Add gradient if requested
    if styleProps.gradient and not instance:FindFirstChild("UIGradient") then
        local gradient = Instance.new("UIGradient")
        
        if styleProps.gradient.color then
            gradient.Color = styleProps.gradient.color
        end
        
        if styleProps.gradient.transparency then
            gradient.Transparency = styleProps.gradient.transparency
        end
        
        if styleProps.gradient.rotation then
            gradient.Rotation = styleProps.gradient.rotation
        end
        
        gradient.Parent = instance
    elseif styleProps.gradient and instance:FindFirstChild("UIGradient") then
        local gradient = instance.UIGradient
        
        if styleProps.gradient.color then
            gradient.Color = styleProps.gradient.color
        end
        
        if styleProps.gradient.transparency then
            gradient.Transparency = styleProps.gradient.transparency
        end
        
        if styleProps.gradient.rotation then
            gradient.Rotation = styleProps.gradient.rotation
        end
    end
    
    -- Add padding if requested
    if styleProps.padding and not instance:FindFirstChild("UIPadding") then
        local padding = Instance.new("UIPadding")
        
        if typeof(styleProps.padding) == "number" then
            -- Same padding on all sides
            padding.PaddingTop = UDim.new(0, styleProps.padding)
            padding.PaddingBottom = UDim.new(0, styleProps.padding)
            padding.PaddingLeft = UDim.new(0, styleProps.padding)
            padding.PaddingRight = UDim.new(0, styleProps.padding)
        else
            -- Different padding for each side
            if styleProps.padding.top then
                padding.PaddingTop = typeof(styleProps.padding.top) == "UDim" 
                                 and styleProps.padding.top 
                                 or UDim.new(0, styleProps.padding.top)
            end
            
            if styleProps.padding.bottom then
                padding.PaddingBottom = typeof(styleProps.padding.bottom) == "UDim" 
                                    and styleProps.padding.bottom 
                                    or UDim.new(0, styleProps.padding.bottom)
            end
            
            if styleProps.padding.left then
                padding.PaddingLeft = typeof(styleProps.padding.left) == "UDim" 
                                  and styleProps.padding.left 
                                  or UDim.new(0, styleProps.padding.left)
            end
            
            if styleProps.padding.right then
                padding.PaddingRight = typeof(styleProps.padding.right) == "UDim" 
                                   and styleProps.padding.right 
                                   or UDim.new(0, styleProps.padding.right)
            end
        end
        
        padding.Parent = instance
    elseif styleProps.padding and instance:FindFirstChild("UIPadding") then
        local padding = instance.UIPadding
        
        if typeof(styleProps.padding) == "number" then
            -- Same padding on all sides
            padding.PaddingTop = UDim.new(0, styleProps.padding)
            padding.PaddingBottom = UDim.new(0, styleProps.padding)
            padding.PaddingLeft = UDim.new(0, styleProps.padding)
            padding.PaddingRight = UDim.new(0, styleProps.padding)
        else
            -- Different padding for each side
            if styleProps.padding.top then
                padding.PaddingTop = typeof(styleProps.padding.top) == "UDim" 
                                 and styleProps.padding.top 
                                 or UDim.new(0, styleProps.padding.top)
            end
            
            if styleProps.padding.bottom then
                padding.PaddingBottom = typeof(styleProps.padding.bottom) == "UDim" 
                                    and styleProps.padding.bottom 
                                    or UDim.new(0, styleProps.padding.bottom)
            end
            
            if styleProps.padding.left then
                padding.PaddingLeft = typeof(styleProps.padding.left) == "UDim" 
                                  and styleProps.padding.left 
                                  or UDim.new(0, styleProps.padding.left)
            end
            
            if styleProps.padding.right then
                padding.PaddingRight = typeof(styleProps.padding.right) == "UDim" 
                                   and styleProps.padding.right 
                                   or UDim.new(0, styleProps.padding.right)
            end
        end
    end
    
    return instance
end

--[[
    Apply a typography style to a text object
    @param instance - Text object to style
    @param typographyStyle - Typography style name or properties
    @return - The styled instance
]]
function UIStyleSystem:applyTypography(instance, typographyStyle)
    if not instance or not (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then
        return instance
    end
    
    local styleProps = {}
    
    if typeof(typographyStyle) == "string" then
        -- Get style from theme
        local theme = self:getActiveTheme()
        if theme and theme.typography and theme.typography[typographyStyle] then
            styleProps = theme.typography[typographyStyle]
        else
            log("Typography style not found: " .. typographyStyle, "Error")
            return instance
        end
    else
        -- Use provided style directly
        styleProps = typographyStyle
    end
    
    -- Apply typography style
    if styleProps.font then
        instance.Font = styleProps.font
    end
    
    if styleProps.size then
        instance.TextSize = styleProps.size
    end
    
    if styleProps.color then
        instance.TextColor3 = styleProps.color
    end
    
    if styleProps.bold ~= nil then
        -- Use bold font if available
        if styleProps.bold and instance.Font == Enum.Font.Gotham then
            instance.Font = Enum.Font.GothamBold
        elseif styleProps.bold and instance.Font == Enum.Font.SourceSans then
            instance.Font = Enum.Font.SourceSansBold
        end
    end
    
    if styleProps.italic ~= nil then
        -- Use italic font if available
        if styleProps.italic and instance.Font == Enum.Font.Gotham then
            instance.Font = Enum.Font.GothamItalic
        elseif styleProps.italic and instance.Font == Enum.Font.SourceSans then
            instance.Font = Enum.Font.SourceSansItalic
        end
    end
    
    if styleProps.wrap ~= nil then
        instance.TextWrapped = styleProps.wrap
    end
    
    if styleProps.xAlign then
        instance.TextXAlignment = styleProps.xAlign
    end
    
    if styleProps.yAlign then
        instance.TextYAlignment = styleProps.yAlign
    end
    
    return instance
end

--[[
    Create a style object for a component
    @param componentName - Name of the component
    @param themeOverrides - Theme overrides for this style
    @return - Style object with getters for theme properties
]]
function UIStyleSystem:createStyle(componentName, themeOverrides)
    local componentStyle = self:getComponentStyle(componentName)
    local theme = self:getActiveTheme()
    
    -- Merge theme, component style, and overrides
    local style = {
        _theme = theme,
        _componentStyle = componentStyle,
        _overrides = themeOverrides or {}
    }
    
    -- Create the style object
    local styleObj = {}
    
    -- Helper to get a value from any of the sources
    local function getValue(key, subKey)
        -- Check overrides first
        if style._overrides[key] then
            if subKey and style._overrides[key][subKey] then
                return style._overrides[key][subKey]
            elseif not subKey then
                return style._overrides[key]
            end
        end
        
        -- Check component style next
        if style._componentStyle and style._componentStyle[key] then
            if subKey and style._componentStyle[key][subKey] then
                return style._componentStyle[key][subKey]
            elseif not subKey then
                return style._componentStyle[key]
            end
        end
        
        -- Finally check theme
        if style._theme[key] then
            if subKey and style._theme[key][subKey] then
                return style._theme[key][subKey]
            elseif not subKey then
                return style._theme[key]
            end
        end
        
        return nil
    end
    
    -- Add getters for common properties
    function styleObj:getColor(name)
        return getValue("colors", name)
    end
    
    function styleObj:getTypography(name)
        return getValue("typography", name)
    end
    
    function styleObj:getCorner(name)
        return getValue("corners", name)
    end
    
    function styleObj:getShadow(name)
        return getValue("shadows", name)
    end
    
    function styleObj:getSpacing(name)
        return getValue("spacing", name)
    end
    
    function styleObj:getTransparency(name)
        return getValue("transparency", name)
    end
    
    function styleObj:getValue(path, defaultValue)
        local parts = {}
        for part in string.gmatch(path, "[^.]+") do
            table.insert(parts, part)
        end
        
        if #parts == 1 then
            return getValue(parts[1]) or defaultValue
        elseif #parts == 2 then
            return getValue(parts[1], parts[2]) or defaultValue
        else
            return defaultValue
        end
    end
    
    return styleObj
end

-- Initialize the system by registering default component styles
do
    -- Button styles
    UIStyleSystem:registerComponentStyle("Button", {
        colors = {
            background = UIStyleSystem:getValue("colors.accent"),
            text = UIStyleSystem:getValue("colors.text"),
            backgroundHover = UIStyleSystem:getValue("colors.accentHover"),
            backgroundPressed = UIStyleSystem:getValue("colors.accentDark"),
            backgroundDisabled = UIStyleSystem:getValue("colors.backgroundLight"),
            textDisabled = UIStyleSystem:getValue("colors.textDisabled")
        },
        typography = UIStyleSystem:getValue("typography.button"),
        corners = UIStyleSystem:getValue("corners.medium"),
        padding = {
            left = 16,
            right = 16,
            top = 8,
            bottom = 8
        }
    })
    
    -- Text styles
    UIStyleSystem:registerComponentStyle("Text", {
        colors = {
            text = UIStyleSystem:getValue("colors.text")
        },
        typography = UIStyleSystem:getValue("typography.body")
    })
    
    -- Container styles
    UIStyleSystem:registerComponentStyle("Container", {
        colors = {
            background = UIStyleSystem:getValue("colors.background"),
            border = UIStyleSystem:getValue("colors.border")
        },
        corners = UIStyleSystem:getValue("corners.medium"),
        padding = UIStyleSystem:getValue("spacing.medium")
    })
    
    -- Card styles
    UIStyleSystem:registerComponentStyle("Card", {
        colors = {
            background = UIStyleSystem:getValue("colors.backgroundLight"),
            shadow = UIStyleSystem:getValue("colors.shadow")
        },
        corners = UIStyleSystem:getValue("corners.medium"),
        padding = UIStyleSystem:getValue("spacing.medium"),
        shadow = UIStyleSystem:getValue("shadows.medium")
    })
    
    log("Initialized default component styles", "Success")
end

return UIStyleSystem
