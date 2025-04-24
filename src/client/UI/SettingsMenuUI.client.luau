--[[
    SettingsMenuUI.client.luau
    
    Settings Menu UI implementation that provides an interface for customizing game settings.
    Uses modern UI modules for consistent appearance and behavior.
    
    Created: April 24, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Load required modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared") or ReplicatedStorage:FindFirstChild("Shared")

-- Safe require helper
local function requireSafely(moduleScript)
    if moduleScript and moduleScript:IsA("ModuleScript") then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            return result
        else
            warn("Failed to load module: " .. moduleScript.Name)
            return nil
        end
    end
    return nil
end

-- Import UI modules
local UIStyle = requireSafely(sharedFolder:FindFirstChild("UIStyle"))
local IconSet = requireSafely(sharedFolder:FindFirstChild("IconSet"))
local ButtonFactory = requireSafely(sharedFolder:FindFirstChild("ButtonFactory"))
local DialogFactory = requireSafely(sharedFolder:FindFirstChild("DialogFactory"))
local SettingsMenu = requireSafely(sharedFolder:FindFirstChild("SettingsMenu"))

-- Check if modules loaded correctly
if not UIStyle then
    warn("UIStyle module not found, SettingsMenuUI will have limited functionality")
end

if not IconSet then
    warn("IconSet module not found, SettingsMenuUI will have limited functionality")
end

if not ButtonFactory then
    warn("ButtonFactory module not found, SettingsMenuUI will have limited functionality")
end

if not DialogFactory then
    warn("DialogFactory module not found, SettingsMenuUI will have limited functionality")
end

if not SettingsMenu then
    warn("SettingsMenu module not found, SettingsMenuUI will not function")
    return
end

-- Settings Menu UI Module
local SettingsMenuUI = {}
SettingsMenuUI.__index = SettingsMenuUI

-- State tracking
local uiState = {
    isInitialized = false,
    menuVisible = false,
    settingsInstance = nil,
    menuElements = {}
}

-- Define the available settings categories and options for the UI
-- This extends the default settings defined in SettingsMenu.luau
local SETTINGS_CONFIG = {
    size = UDim2.new(0, 800, 0, 550),
    title = "Settings",
    backgroundColor = UIStyle.Colors.Background,
    headerColor = UIStyle.Colors.HeaderBackground,
    
    -- Define any additional categories or options
    additionalCategories = {
        accessibility = {
            title = "Accessibility",
            icon = IconSet.getAssetId("Settings"),
            options = {
                highContrast = {
                    type = "toggle",
                    title = "High Contrast Mode",
                    description = "Increases contrast for better visibility",
                    default = false
                },
                largeText = {
                    type = "toggle",
                    title = "Large Text",
                    description = "Makes text bigger throughout the game",
                    default = false
                },
                colorBlindMode = {
                    type = "dropdown",
                    title = "Color Blind Mode",
                    description = "Adjusts colors for different types of color blindness",
                    options = {"Off", "Protanopia", "Deuteranopia", "Tritanopia"},
                    default = "Off"
                },
                motionReduction = {
                    type = "toggle",
                    title = "Reduce Motion",
                    description = "Reduces animations and motion effects",
                    default = false
                }
            }
        },
        interface = {
            title = "Interface",
            icon = IconSet.getAssetId("Settings"),
            options = {
                notificationsEnabled = {
                    type = "toggle",
                    title = "Show Notifications",
                    description = "Enable or disable game notifications",
                    default = true
                },
                chatBubbles = {
                    type = "toggle",
                    title = "Show Chat Bubbles",
                    description = "Display chat messages above players' heads",
                    default = true
                },
                uiTransparency = {
                    type = "slider",
                    title = "UI Transparency",
                    description = "Adjust the transparency of UI elements",
                    min = 0,
                    max = 50,
                    default = 0
                },
                useUIHub = {
                    type = "toggle",
                    title = "Use UI Hub",
                    description = "Use the compact UI hub for quick access",
                    default = true
                }
            }
        }
    }
}

-- Initialize the settings menu
function SettingsMenuUI:Initialize()
    if uiState.isInitialized then
        return self
    end
    
    -- Create the settings instance
    self:CreateSettingsMenu()
    
    uiState.isInitialized = true
    return self
end

-- Create the settings menu
function SettingsMenuUI:CreateSettingsMenu()
    -- Create the settings instance with our configuration
    uiState.settingsInstance = SettingsMenu.new(SETTINGS_CONFIG)
    
    -- Register callbacks
    uiState.settingsInstance.callbacks = {
        onSettingsSaved = function(settings)
            -- Apply settings immediately
            self:ApplySettings(settings)
            
            -- Show confirmation notification
            DialogFactory.createNotification("Settings saved successfully", 3, "success")
        end,
        
        onSettingsApplied = function(settings)
            -- Handle settings application
            self:ApplySettings(settings)
        end,
        
        onClose = function()
            self:HideSettingsMenu()
        end
    }
    
    -- Create the container GUI
    local screenGui = player:FindFirstChild("SettingsMenuGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SettingsMenuGui"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = player:FindFirstChild("PlayerGui")
    end
    
    -- Store for later reference
    uiState.menuElements.screenGui = screenGui
end

-- Create the toggle button for settings
function SettingsMenuUI:CreateSettingsToggle(position)
    position = position or UDim2.new(1, -50, 0, 50)
    
    local settingsToggle = ButtonFactory.createIconButton(
        "Settings", 
        "", 
        UDim2.new(0, 40, 0, 40), 
        position,
        function()
            self:ToggleSettingsMenu()
        end
    )
    
    -- Add to player's GUI
    settingsToggle.Parent = player:FindFirstChild("PlayerGui") or Instance.new("ScreenGui", player)
    
    -- Apply tooltip
    DialogFactory.createTooltip(settingsToggle, "Open Settings", "bottom", 100)
    
    -- Store for later reference
    uiState.menuElements.settingsToggle = settingsToggle
    return settingsToggle
end

-- Show the settings menu
function SettingsMenuUI:ShowSettingsMenu()
    if not uiState.settingsInstance then
        warn("Settings instance not initialized")
        return
    end
    
    -- If already visible, do nothing
    if uiState.menuVisible then
        return
    end
    
    -- Create UI if it doesn't exist yet
    if not uiState.menuElements.settingsContainer then
        local settingsUI = uiState.settingsInstance:createUI()
        settingsUI.Parent = uiState.menuElements.screenGui
        uiState.menuElements.settingsContainer = settingsUI
    end
    
    -- Show the settings menu with animation
    local container = uiState.menuElements.settingsContainer
    if container then
        container.Visible = true
        container.BackgroundTransparency = 1
        container.Position = UDim2.new(0.5, -container.Size.X.Offset/2, 0.6, -container.Size.Y.Offset/2)
        
        -- Animate in
        TweenService:Create(
            container,
            UIStyle.Animations.Standard,
            {
                Position = UDim2.new(0.5, -container.Size.X.Offset/2, 0.5, -container.Size.Y.Offset/2),
                BackgroundTransparency = 0
            }
        ):Play()
        
        -- Create a modal background
        if not uiState.menuElements.modalBackground then
            local background = Instance.new("Frame")
            background.Name = "ModalBackground"
            background.Size = UDim2.new(1, 0, 1, 0)
            background.Position = UDim2.new(0, 0, 0, 0)
            background.BackgroundColor3 = Color3.new(0, 0, 0)
            background.BackgroundTransparency = 1
            background.BorderSizePixel = 0
            background.ZIndex = UIStyle.ZIndex.Overlay - 1
            background.Parent = uiState.menuElements.screenGui
            
            -- Connect click to close
            background.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    -- Don't close when clicking on settings
                    local mousePos = UserInputService:GetMouseLocation()
                    local absPos = container.AbsolutePosition
                    local absSize = container.AbsoluteSize
                    
                    if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or
                       mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
                        self:HideSettingsMenu()
                    end
                end
            end)
            
            uiState.menuElements.modalBackground = background
        end
        
        -- Animate in modal background
        TweenService:Create(
            uiState.menuElements.modalBackground, 
            UIStyle.Animations.Standard, 
            { BackgroundTransparency = 0.5 }
        ):Play()
    end
    
    -- Update state
    uiState.menuVisible = true
end

-- Hide the settings menu
function SettingsMenuUI:HideSettingsMenu()
    -- If not visible, do nothing
    if not uiState.menuVisible then
        return
    end
    
    local container = uiState.menuElements.settingsContainer
    if container then
        -- Animate out
        TweenService:Create(
            container,
            UIStyle.Animations.Standard,
            {
                Position = UDim2.new(0.5, -container.Size.X.Offset/2, 0.6, -container.Size.Y.Offset/2),
                BackgroundTransparency = 1
            }
        ):Play()
        
        -- Animate out modal background
        if uiState.menuElements.modalBackground then
            TweenService:Create(
                uiState.menuElements.modalBackground, 
                UIStyle.Animations.Standard, 
                { BackgroundTransparency = 1 }
            ):Play()
        end
        
        -- Hide after animation
        task.delay(UIStyle.Animations.Standard.Time, function()
            if not uiState.menuVisible then
                container.Visible = false
            end
        end)
    end
    
    -- Update state
    uiState.menuVisible = false
end

-- Toggle the settings menu
function SettingsMenuUI:ToggleSettingsMenu()
    if uiState.menuVisible then
        self:HideSettingsMenu()
    else
        self:ShowSettingsMenu()
    end
end

-- Apply settings to the game
function SettingsMenuUI:ApplySettings(settings)
    -- Apply settings to game systems
    
    -- Audio settings
    if settings.audio then
        -- Master volume
        if settings.audio.masterVolume then
            -- Would connect to audio system to set volume
        end
        
        -- Music volume
        if settings.audio.musicVolume then
            -- Would connect to audio system to set music volume
        end
        
        -- SFX volume
        if settings.audio.sfxVolume then
            -- Would connect to audio system to set sound effects volume
        end
        
        -- Mute music toggle
        if settings.audio.muteMusic ~= nil then
            -- Would connect to audio system to mute/unmute music
        end
    end
    
    -- Visual settings
    if settings.visual then
        -- Graphics quality
        if settings.visual.quality then
            local qualityLevel = {
                Low = Enum.RenderingQuality.Automatic,
                Medium = Enum.RenderingQuality.Automatic,
                High = Enum.RenderingQuality.Automatic
            }
            
            local quality = qualityLevel[settings.visual.quality] or Enum.RenderingQuality.Automatic
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = quality
        end
        
        -- Show FPS toggle
        if settings.visual.showFPS ~= nil then
            -- Would toggle FPS counter
        end
    end
    
    -- Gameplay settings
    if settings.gameplay then
        -- Auto-collect revenue
        if settings.gameplay.autoCollect ~= nil then
            -- Would connect to revenue system
        end
        
        -- Confirm purchases
        if settings.gameplay.confirmPurchases ~= nil then
            -- Would set purchase confirmation flag
        end
    end
    
    -- Accessibility settings
    if settings.accessibility then
        -- High contrast mode
        if settings.accessibility.highContrast ~= nil then
            -- Would apply high contrast theme
        end
        
        -- Large text
        if settings.accessibility.largeText ~= nil then
            -- Would scale UI text
        end
        
        -- Color blind mode
        if settings.accessibility.colorBlindMode then
            -- Would apply color correction
        end
    end
    
    -- Interface settings
    if settings.interface then
        -- Notifications toggle
        if settings.interface.notificationsEnabled ~= nil then
            -- Would enable/disable notifications
        end
        
        -- UI transparency
        if settings.interface.uiTransparency then
            -- Would set UI transparency
        end
    end
    
    -- Save settings to player data
    if uiState.settingsInstance then
        -- SettingsMenu module handles saving settings to player data
    end
end

-- Open the settings menu with the specified category
function SettingsMenuUI:OpenSettingsCategory(categoryId)
    -- Show the settings menu
    self:ShowSettingsMenu()
    
    -- Switch to the specified category
    if categoryId and uiState.settingsInstance then
        uiState.settingsInstance:showCategory(categoryId)
    end
end

-- Initialize the module when required
return SettingsMenuUI:Initialize()