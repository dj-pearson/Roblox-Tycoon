--!strict
--[[
    Constants.luau
    
    Shared constants for the UI system.
    These constants are used across both client and server scripts.
]]

local Constants = {
    -- UI System
    DEFAULT_Z_INDEX = 1,
    MAX_Z_INDEX = 100,
    DEFAULT_ANIMATION_DURATION = 0.3,
    
    -- Component Names
    COMPONENTS = {
        MAIN_MENU = "MainMenu",
        SIDE_MENU = "SideMenu",
        ADMIN_PANEL = "AdminPanel",
        LOADING_SCREEN = "LoadingScreen",
        ERROR_POPUP = "ErrorPopup",
        CONFIRMATION_DIALOG = "ConfirmationDialog",
    },
    
    -- Animation Types
    ANIMATIONS = {
        FADE = "fade",
        SLIDE = "slide",
        SCALE = "scale",
        ROTATE = "rotate",
    },
    
    -- Event Types
    EVENTS = {
        CLICK = "click",
        HOVER = "hover",
        PRESS = "press",
        RELEASE = "release",
        FOCUS = "focus",
        BLUR = "blur",
        CHANGE = "change",
    },
    
    -- Default Styles
    STYLES = {
        BACKGROUND_COLOR = Color3.fromRGB(40, 40, 40),
        TEXT_COLOR = Color3.fromRGB(255, 255, 255),
        ACCENT_COLOR = Color3.fromRGB(0, 120, 215),
        ERROR_COLOR = Color3.fromRGB(255, 50, 50),
        SUCCESS_COLOR = Color3.fromRGB(50, 255, 50),
        WARNING_COLOR = Color3.fromRGB(255, 200, 50),
        
        FONT = Enum.Font.Gotham,
        FONT_BOLD = Enum.Font.GothamBold,
        FONT_SEMI_BOLD = Enum.Font.GothamSemibold,
        
        TEXT_SIZE_SMALL = 12,
        TEXT_SIZE_NORMAL = 14,
        TEXT_SIZE_LARGE = 18,
        TEXT_SIZE_TITLE = 24,
        
        PADDING_SMALL = 8,
        PADDING_NORMAL = 12,
        PADDING_LARGE = 16,
        
        CORNER_RADIUS = 4,
        BORDER_SIZE = 1,
    },
    
    -- Layout
    LAYOUT = {
        MAIN_MENU_SIZE = UDim2.new(0.8, 0, 0.8, 0),
        MAIN_MENU_POSITION = UDim2.new(0.1, 0, 0.1, 0),
        
        SIDE_MENU_SIZE = UDim2.new(0.2, 0, 1, 0),
        SIDE_MENU_POSITION = UDim2.new(0, 0, 0, 0),
        
        ADMIN_PANEL_SIZE = UDim2.new(0.4, 0, 0.6, 0),
        ADMIN_PANEL_POSITION = UDim2.new(0.3, 0, 0.2, 0),
    },
}

return Constants 