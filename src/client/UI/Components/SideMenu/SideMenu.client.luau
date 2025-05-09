--!strict
--[[
    SideMenu.client.luau
    
    Side menu component.
    Integrates with existing menu systems and provides a consistent side menu interface.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIComponent = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("UI"):WaitForChild("Core"):WaitForChild("UIComponent"))
local Types = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Types"))
local Constants = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Constants"))

-- Get existing menu systems
local MenuButtonCreator = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("MenuButtonCreator"))
local MenuButtonsHandler = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("UI"):WaitForChild("MenuButtonsHandler"))

type UIComponentProps = Types.UIComponentProps
type UIEvent = Types.UIEvent

local SideMenu = setmetatable({}, { __index = UIComponent })
SideMenu.__index = SideMenu

-- Icon asset IDs
local ICONS = {
    ACHIEVEMENTS = "rbxassetid://79337595530955",
    COMMUNITY_GOALS = "rbxassetid://97149848004338",
    SETTINGS = "rbxassetid://72876573893033",
    REBIRTH = "rbxassetid://129409029383961",
    TUTORIAL = "rbxassetid://98150393120956"
}

-- Constructor
function SideMenu.new(): SideMenu
    local props: UIComponentProps = {
        name = Constants.COMPONENTS.SIDE_MENU,
        size = Constants.LAYOUT.SIDE_MENU_SIZE,
        position = Constants.LAYOUT.SIDE_MENU_POSITION,
        backgroundColor3 = Constants.STYLES.BACKGROUND_COLOR,
        backgroundTransparency = 0,
        zIndex = Constants.DEFAULT_Z_INDEX,
    }
    
    local self = setmetatable(UIComponent.new(Constants.COMPONENTS.SIDE_MENU, props), SideMenu)
    
    -- Create menu elements
    self:createMenuElements()
    
    return self
end

-- Create menu elements
function SideMenu:createMenuElements()
    -- Create container for menu buttons
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 1, 0)
    buttonContainer.Position = UDim2.new(0, 0, 0, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = self.instance
    
    -- Add UIListLayout for button spacing
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, Constants.STYLES.PADDING_NORMAL)
    listLayout.Parent = buttonContainer
    
    -- Create menu buttons using existing MenuButtonCreator
    self:createMenuButtons(buttonContainer)
end

-- Create menu buttons
function SideMenu:createMenuButtons(container: Instance)
    -- Define menu items
    local menuItems = {
        {
            name = "Achievements",
            icon = ICONS.ACHIEVEMENTS,
            action = function()
                self:onAchievementsClick()
            end
        },
        {
            name = "Community Goals",
            icon = ICONS.COMMUNITY_GOALS,
            action = function()
                self:onCommunityGoalsClick()
            end
        },
        {
            name = "Settings",
            icon = ICONS.SETTINGS,
            action = function()
                self:onSettingsClick()
            end
        },
        {
            name = "Rebirth",
            icon = ICONS.REBIRTH,
            action = function()
                self:onRebirthClick()
            end
        },
        {
            name = "Tutorial",
            icon = ICONS.TUTORIAL,
            action = function()
                self:onTutorialClick()
            end
        }
    }
    
    -- Create buttons using MenuButtonCreator
    for _, item in menuItems do
        local button = MenuButtonCreator.createMenuButton({
            name = item.name,
            icon = item.icon,
            onClick = item.action,
            parent = container
        })
        
        -- Add hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR:Lerp(Color3.new(1, 1, 1), 0.2)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
        end)
    end
end

-- Button click handlers
function SideMenu:onAchievementsClick()
    self:dispatch({
        type = Constants.EVENTS.CLICK,
        target = self.instance,
        data = {
            action = "achievements"
        }
    })
end

function SideMenu:onCommunityGoalsClick()
    self:dispatch({
        type = Constants.EVENTS.CLICK,
        target = self.instance,
        data = {
            action = "community_goals"
        }
    })
end

function SideMenu:onSettingsClick()
    self:dispatch({
        type = Constants.EVENTS.CLICK,
        target = self.instance,
        data = {
            action = "settings"
        }
    })
end

function SideMenu:onRebirthClick()
    self:dispatch({
        type = Constants.EVENTS.CLICK,
        target = self.instance,
        data = {
            action = "rebirth"
        }
    })
end

function SideMenu:onTutorialClick()
    self:dispatch({
        type = Constants.EVENTS.CLICK,
        target = self.instance,
        data = {
            action = "tutorial"
        }
    })
end

-- Override event handler
function SideMenu:onEvent(event: UIEvent)
    -- Handle component-specific events
    if event.type == Constants.EVENTS.CLICK then
        -- Handle click events
        if event.data.action == "achievements" then
            -- Handle achievements action
        elseif event.data.action == "community_goals" then
            -- Handle community goals action
        elseif event.data.action == "settings" then
            -- Handle settings action
        elseif event.data.action == "rebirth" then
            -- Handle rebirth action
        elseif event.data.action == "tutorial" then
            -- Handle tutorial action
        end
    end
end

-- Override destroy to clean up
function SideMenu:destroy()
    -- Clean up any existing menu buttons
    if self.instance then
        for _, child in self.instance:GetChildren() do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end
    
    -- Call parent destroy
    UIComponent.destroy(self)
end

return SideMenu 