--!strict
--[[
    MainMenu.client.luau
    
    Main menu component.
    Serves as the primary menu interface for the game.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIComponent = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("UI"):WaitForChild("Core"):WaitForChild("UIComponent"))
local Types = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Types"))
local Constants = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Constants"))

type UIComponentProps = Types.UIComponentProps
type UIEvent = Types.UIEvent

local MainMenu = setmetatable({}, { __index = UIComponent })
MainMenu.__index = MainMenu

-- Constructor
function MainMenu.new(): MainMenu
    local props: UIComponentProps = {
        name = Constants.COMPONENTS.MAIN_MENU,
        size = Constants.LAYOUT.MAIN_MENU_SIZE,
        position = Constants.LAYOUT.MAIN_MENU_POSITION,
        backgroundColor3 = Constants.STYLES.BACKGROUND_COLOR,
        backgroundTransparency = 0,
        zIndex = Constants.DEFAULT_Z_INDEX,
    }
    
    local self = setmetatable(UIComponent.new(Constants.COMPONENTS.MAIN_MENU, props), MainMenu)
    
    -- Create menu elements
    self:createMenuElements()
    
    return self
end

-- Create menu elements
function MainMenu:createMenuElements()
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0.2, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Main Menu"
    title.TextColor3 = Constants.STYLES.TEXT_COLOR
    title.TextSize = Constants.STYLES.TEXT_SIZE_TITLE
    title.Font = Constants.STYLES.FONT_BOLD
    title.Parent = self.instance
    
    -- Menu container
    local menuContainer = Instance.new("Frame")
    menuContainer.Name = "MenuContainer"
    menuContainer.Size = UDim2.new(0.8, 0, 0.6, 0)
    menuContainer.Position = UDim2.new(0.1, 0, 0.25, 0)
    menuContainer.BackgroundTransparency = 1
    menuContainer.Parent = self.instance
    
    -- Create menu buttons
    self:createMenuButtons(menuContainer)
end

-- Create menu buttons
function MainMenu:createMenuButtons(container: Instance)
    local buttons = {
        {
            name = "Play",
            action = function()
                self:onPlayClick()
            end
        },
        {
            name = "Settings",
            action = function()
                self:onSettingsClick()
            end
        },
        {
            name = "Credits",
            action = function()
                self:onCreditsClick()
            end
        },
        {
            name = "Exit",
            action = function()
                self:onExitClick()
            end
        }
    }
    
    local buttonHeight = 0.2
    local spacing = 0.05
    
    for i, buttonData in buttons do
        local button = Instance.new("TextButton")
        button.Name = buttonData.name .. "Button"
        button.Size = UDim2.new(1, 0, buttonHeight, 0)
        button.Position = UDim2.new(0, 0, (i - 1) * (buttonHeight + spacing), 0)
        button.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
        button.BorderSizePixel = 0
        button.Text = buttonData.name
        button.TextColor3 = Constants.STYLES.TEXT_COLOR
        button.TextSize = Constants.STYLES.TEXT_SIZE_LARGE
        button.Font = Constants.STYLES.FONT_SEMI_BOLD
        button.Parent = container
        
        -- Add corner radius
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, Constants.STYLES.CORNER_RADIUS)
        corner.Parent = button
        
        -- Connect click event
        button.MouseButton1Click:Connect(buttonData.action)
        
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
function MainMenu:onPlayClick()
    -- Implement play action
    self:dispatch({
        type = Constants.EVENTS.CLICK,
        target = self.instance,
        data = {
            action = "play"
        }
    })
end

function MainMenu:onSettingsClick()
    -- Implement settings action
    self:dispatch({
        type = Constants.EVENTS.CLICK,
        target = self.instance,
        data = {
            action = "settings"
        }
    })
end

function MainMenu:onCreditsClick()
    -- Implement credits action
    self:dispatch({
        type = Constants.EVENTS.CLICK,
        target = self.instance,
        data = {
            action = "credits"
        }
    })
end

function MainMenu:onExitClick()
    -- Implement exit action
    self:dispatch({
        type = Constants.EVENTS.CLICK,
        target = self.instance,
        data = {
            action = "exit"
        }
    })
end

-- Override event handler
function MainMenu:onEvent(event: UIEvent)
    -- Handle component-specific events
    if event.type == Constants.EVENTS.CLICK then
        -- Handle click events
    end
end

return MainMenu 