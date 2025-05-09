--!strict
--[[
    UIConstants.luau
    
    Common UI constants and configurations.
    Centralizes UI-related values for consistency.
]]

local UIConstants = {}

-- Colors
UIConstants.Colors = {
    Primary = Color3.fromRGB(0, 120, 215),
    Secondary = Color3.fromRGB(45, 45, 45),
    Background = Color3.fromRGB(30, 30, 30),
    Text = Color3.new(1, 1, 1),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    Success = Color3.fromRGB(46, 204, 113),
    Warning = Color3.fromRGB(241, 196, 15),
    Error = Color3.fromRGB(231, 76, 60),
    Disabled = Color3.fromRGB(100, 100, 100)
}

-- Fonts
UIConstants.Fonts = {
    Title = Enum.Font.GothamBold,
    Subtitle = Enum.Font.GothamSemibold,
    Body = Enum.Font.Gotham,
    Button = Enum.Font.GothamSemibold
}

-- Text Sizes
UIConstants.TextSizes = {
    Title = 24,
    Subtitle = 20,
    Body = 14,
    Button = 14,
    Small = 12
}

-- Spacing
UIConstants.Spacing = {
    Small = 5,
    Medium = 10,
    Large = 20,
    ExtraLarge = 30
}

-- Corner Radius
UIConstants.CornerRadius = {
    Small = 4,
    Medium = 8,
    Large = 12
}

-- Animation Durations
UIConstants.AnimationDurations = {
    Fast = 0.2,
    Normal = 0.3,
    Slow = 0.5
}

-- Layout Configurations
UIConstants.Layouts = {
    Vertical = {
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder
    },
    Horizontal = {
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder
    }
}

-- UI Component Sizes
UIConstants.Sizes = {
    Button = {
        Small = UDim2.new(0, 100, 0, 30),
        Medium = UDim2.new(0, 150, 0, 40),
        Large = UDim2.new(0, 200, 0, 50)
    },
    Input = {
        Small = UDim2.new(0, 100, 0, 30),
        Medium = UDim2.new(0, 150, 0, 40),
        Large = UDim2.new(0, 200, 0, 50)
    },
    Panel = {
        Small = UDim2.new(0, 300, 0, 200),
        Medium = UDim2.new(0, 400, 0, 300),
        Large = UDim2.new(0, 500, 0, 400)
    }
}

-- Z-Index Values
UIConstants.ZIndex = {
    Base = 1,
    Modal = 1000,
    Tooltip = 2000,
    Notification = 3000
}

-- UI Component Names
UIConstants.ComponentNames = {
    MainMenu = "MainMenu",
    SideMenu = "SideMenu",
    Achievements = "Achievements",
    CommunityGoals = "CommunityGoals",
    Settings = "Settings",
    Tutorial = "Tutorial"
}

-- UI Event Names
UIConstants.EventNames = {
    ShowUI = "ShowUI",
    HideUI = "HideUI",
    UpdateUI = "UpdateUI",
    UIInteraction = "UIInteraction",
    UIError = "UIError"
}

-- UI Animation Names
UIConstants.AnimationNames = {
    FadeIn = "FADE_IN",
    FadeOut = "FADE_OUT",
    SlideInLeft = "SLIDE_IN_LEFT",
    SlideOutLeft = "SLIDE_OUT_LEFT",
    ScaleIn = "SCALE_IN",
    ScaleOut = "SCALE_OUT"
}

return UIConstants 