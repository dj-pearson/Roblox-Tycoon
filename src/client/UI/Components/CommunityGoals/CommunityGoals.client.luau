--!strict
--[[
    CommunityGoals.client.luau
    
    Community Goals UI component.
    Displays active community goals and progress.
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

local CommunityGoals = setmetatable({}, { __index = UIComponent })
CommunityGoals.__index = CommunityGoals

-- Constructor
function CommunityGoals.new(): CommunityGoals
    local props: UIComponentProps = {
        name = Constants.COMPONENTS.COMMUNITY_GOALS,
        size = UDim2.new(0.8, 0, 0.8, 0),
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchorPoint = Vector2.new(0.5, 0.5),
        backgroundColor3 = Constants.STYLES.BACKGROUND_COLOR,
        backgroundTransparency = 0,
        zIndex = Constants.DEFAULT_Z_INDEX,
    }
    
    local self = setmetatable(UIComponent.new(Constants.COMPONENTS.COMMUNITY_GOALS, props), CommunityGoals)
    
    -- Create UI elements
    self:createUIElements()
    
    -- Set up event listeners
    self:setupEventListeners()
    
    return self
end

-- Create UI elements
function CommunityGoals:createUIElements()
    -- Create container for goals
    local container = Instance.new("ScrollingFrame")
    container.Name = "GoalsContainer"
    container.Size = UDim2.new(1, -40, 1, -100)
    container.Position = UDim2.new(0, 20, 0, 80)
    container.BackgroundTransparency = 1
    container.ScrollBarThickness = 6
    container.ScrollingDirection = Enum.ScrollingDirection.Y
    container.Parent = self.instance
    
    -- Add UIListLayout for goal items
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = container
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Community Goals"
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
function CommunityGoals:setupEventListeners()
    -- Listen for community goal updates
    ClientEventBridge:connectEvent("CommunityGoalDataUpdated", function(data)
        self:updateGoals(data)
    end)
end

-- Update goals display
function CommunityGoals:updateGoals(data)
    if not data or not self.container then return end
    
    -- Clear existing goals
    for _, child in self.container:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create goal items
    for _, goal in ipairs(data) do
        local item = self:createGoalItem(goal)
        item.Parent = self.container
    end
end

-- Create goal item
function CommunityGoals:createGoalItem(goal)
    local item = Instance.new("Frame")
    item.Name = goal.goalId
    item.Size = UDim2.new(1, 0, 0, 120)
    item.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    item.BackgroundTransparency = 0.3
    
    -- Create icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 80, 0, 80)
    icon.Position = UDim2.new(0, 10, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = goal.icon or "rbxassetid://97149848004338" -- Default community goals icon
    icon.Parent = item
    
    -- Create name
    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.Size = UDim2.new(1, -100, 0, 24)
    name.Position = UDim2.new(0, 100, 0, 10)
    name.BackgroundTransparency = 1
    name.Text = goal.description
    name.TextColor3 = Constants.STYLES.TEXT_COLOR
    name.TextSize = 18
    name.Font = Enum.Font.GothamBold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = item
    
    -- Create progress bar
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, -120, 0, 4)
    progressBar.Position = UDim2.new(0, 100, 0.5, 20)
    progressBar.BackgroundColor3 = Constants.STYLES.BACKGROUND_COLOR
    progressBar.Parent = item
    
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(goal.currentProgress / goal.target, 0, 1, 0)
    progressFill.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    progressFill.Parent = progressBar
    
    -- Create progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, -120, 0, 20)
    progressText.Position = UDim2.new(0, 100, 0.5, 30)
    progressText.BackgroundTransparency = 1
    progressText.Text = string.format("%d/%d", goal.currentProgress, goal.target)
    progressText.TextColor3 = Constants.STYLES.TEXT_COLOR
    progressText.TextSize = 14
    progressText.Font = Enum.Font.Gotham
    progressText.TextXAlignment = Enum.TextXAlignment.Left
    progressText.Parent = item
    
    -- Create time remaining
    local timeRemaining = Instance.new("TextLabel")
    timeRemaining.Name = "TimeRemaining"
    timeRemaining.Size = UDim2.new(1, -120, 0, 20)
    timeRemaining.Position = UDim2.new(0, 100, 0.5, 50)
    timeRemaining.BackgroundTransparency = 1
    timeRemaining.Text = self:formatTimeRemaining(goal.endTime - os.time())
    timeRemaining.TextColor3 = Constants.STYLES.TEXT_COLOR
    timeRemaining.TextSize = 14
    timeRemaining.Font = Enum.Font.Gotham
    timeRemaining.TextXAlignment = Enum.TextXAlignment.Left
    timeRemaining.Parent = item
    
    -- Create participate button
    local participateButton = Instance.new("TextButton")
    participateButton.Name = "ParticipateButton"
    participateButton.Size = UDim2.new(0, 100, 0, 30)
    participateButton.Position = UDim2.new(1, -110, 1, -40)
    participateButton.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    participateButton.Text = "Participate"
    participateButton.TextColor3 = Constants.STYLES.TEXT_COLOR
    participateButton.TextSize = 14
    participateButton.Font = Enum.Font.GothamBold
    participateButton.Parent = item
    
    -- Add hover effect
    participateButton.MouseEnter:Connect(function()
        participateButton.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR:Lerp(Color3.new(1, 1, 1), 0.2)
    end)
    
    participateButton.MouseLeave:Connect(function()
        participateButton.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
    end)
    
    -- Connect participate button
    participateButton.MouseButton1Click:Connect(function()
        ClientEventBridge:fireEvent("ParticipateInCommunityGoal", {
            goalId = goal.goalId
        })
    end)
    
    return item
end

-- Format time remaining
function CommunityGoals:formatTimeRemaining(seconds)
    if seconds <= 0 then
        return "Ended"
    end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if hours > 0 then
        return string.format("%dh %dm remaining", hours, minutes)
    else
        return string.format("%dm remaining", minutes)
    end
end

-- Override event handler
function CommunityGoals:onEvent(event: UIEvent)
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
function CommunityGoals:destroy()
    -- Clean up event listeners
    if self.container then
        self.container:Destroy()
    end
    
    -- Call parent destroy
    UIComponent.destroy(self)
end

return CommunityGoals 