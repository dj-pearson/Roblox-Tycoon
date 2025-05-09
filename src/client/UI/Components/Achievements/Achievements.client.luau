--!strict
--[[
    Achievements.client.luau
    
    Achievements UI component.
    Displays player achievements and progress.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIComponent = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("UI"):WaitForChild("Core"):WaitForChild("UIComponent"))
local Types = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Types"))
local Constants = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Constants"))

-- Get client-side systems
local ClientRegistry = require(script.Parent.Parent.Parent.Parent.Core.ClientRegistry)
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")

type UIComponentProps = Types.UIComponentProps
type UIEvent = Types.UIEvent

local Achievements = setmetatable({}, { __index = UIComponent })
Achievements.__index = Achievements

-- Constructor
function Achievements.new(): Achievements
    local props: UIComponentProps = {
        name = Constants.COMPONENTS.ACHIEVEMENTS,
        size = UDim2.new(0.8, 0, 0.8, 0),
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchorPoint = Vector2.new(0.5, 0.5),
        backgroundColor3 = Constants.STYLES.BACKGROUND_COLOR,
        backgroundTransparency = 0,
        zIndex = Constants.DEFAULT_Z_INDEX,
    }
    
    local self = setmetatable(UIComponent.new(Constants.COMPONENTS.ACHIEVEMENTS, props), Achievements)
    
    -- Create UI elements
    self:createUIElements()
    
    -- Set up event listeners
    self:setupEventListeners()
    
    return self
end

-- Create UI elements
function Achievements:createUIElements()
    -- Create container for achievements
    local container = Instance.new("ScrollingFrame")
    container.Name = "AchievementsContainer"
    container.Size = UDim2.new(1, -40, 1, -100)
    container.Position = UDim2.new(0, 20, 0, 80)
    container.BackgroundTransparency = 1
    container.ScrollBarThickness = 6
    container.ScrollingDirection = Enum.ScrollingDirection.Y
    container.Parent = self.instance
    
    -- Add UIListLayout for achievement items
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = container
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Achievements"
    title.TextColor3 = Constants.STYLES.TEXT_COLOR
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = self.instance
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 20)
    closeButton.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    closeButton.Text = "X"
    closeButton.TextColor3 = Constants.STYLES.TEXT_COLOR
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = self.instance
    
    -- Add hover effect
    closeButton.MouseEnter:Connect(function()
        closeButton.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR:Lerp(Color3.new(1, 1, 1), 0.2)
    end)
    
    closeButton.MouseLeave:Connect(function()
        closeButton.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    end)
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        self:dispatch({
            type = Constants.EVENTS.CLICK,
            target = self.instance,
            data = {
                action = "close"
            }
        })
    end)
    
    -- Store container reference
    self.container = container
end

-- Set up event listeners
function Achievements:setupEventListeners()
    -- Listen for achievement data updates
    ClientEventBridge:connectEvent("AchievementDataUpdated", function(data)
        self:updateAchievements(data)
    end)
end

-- Update achievements display
function Achievements:updateAchievements(data)
    if not data or not self.container then return end
    
    -- Clear existing achievements
    for _, child in self.container:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create achievement items
    for _, achievement in ipairs(data) do
        local item = self:createAchievementItem(achievement)
        item.Parent = self.container
    end
end

-- Create achievement item
function Achievements:createAchievementItem(achievement)
    local item = Instance.new("Frame")
    item.Name = achievement.id
    item.Size = UDim2.new(1, 0, 0, 80)
    item.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    item.BackgroundTransparency = achievement.completed and 0.1 or 0.3
    
    -- Create icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0, 10, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = achievement.icon
    icon.Parent = item
    
    -- Create name
    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.Size = UDim2.new(1, -90, 0, 24)
    name.Position = UDim2.new(0, 80, 0, 10)
    name.BackgroundTransparency = 1
    name.Text = achievement.name
    name.TextColor3 = Constants.STYLES.TEXT_COLOR
    name.TextSize = 18
    name.Font = Enum.Font.GothamBold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = item
    
    -- Create description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -90, 0, 20)
    description.Position = UDim2.new(0, 80, 0, 34)
    description.BackgroundTransparency = 1
    description.Text = achievement.description
    description.TextColor3 = Constants.STYLES.TEXT_COLOR
    description.TextSize = 14
    description.Font = Enum.Font.Gotham
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Parent = item
    
    -- Create progress bar
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, -20, 0, 4)
    progressBar.Position = UDim2.new(0, 10, 1, -14)
    progressBar.BackgroundColor3 = Constants.STYLES.BACKGROUND_COLOR
    progressBar.Parent = item
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(achievement.progress / achievement.goal, 0, 1, 0)
    progressFill.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    progressFill.Parent = progressBar
    
    -- Create progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, -20, 0, 20)
    progressText.Position = UDim2.new(0, 10, 1, -10)
    progressText.BackgroundTransparency = 1
    progressText.Text = string.format("%d/%d", achievement.progress, achievement.goal)
    progressText.TextColor3 = Constants.STYLES.TEXT_COLOR
    progressText.TextSize = 12
    progressText.Font = Enum.Font.Gotham
    progressText.TextXAlignment = Enum.TextXAlignment.Right
    progressText.Parent = item
    
    return item
end

-- Override event handler
function Achievements:onEvent(event: UIEvent)
    if event.type == Constants.EVENTS.CLICK then
        if event.data.action == "close" then
            self:dispatch({
                type = Constants.EVENTS.CLOSE,
                target = self.instance
            })
        end
    end
end

-- Override destroy to clean up
function Achievements:destroy()
    -- Clean up event listeners
    if self.container then
        self.container:Destroy()
    end
    
    -- Call parent destroy
    UIComponent.destroy(self)
end

return Achievements 