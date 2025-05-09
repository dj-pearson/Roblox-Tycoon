--!strict
--[[
    Tutorial.client.luau
    
    Tutorial UI component.
    Guides new players through the game's features and mechanics.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local UIComponent = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("UI"):WaitForChild("Core"):WaitForChild("UIComponent"))
local Types = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Types"))
local Constants = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UI"):WaitForChild("Constants"))

-- Get client-side systems
local ClientRegistry = require(script.Parent.Parent.Parent.Parent.Core.ClientRegistry)
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")

type UIComponentProps = Types.UIComponentProps
type UIEvent = Types.UIEvent

local Tutorial = setmetatable({}, { __index = UIComponent })
Tutorial.__index = Tutorial

-- Constructor
function Tutorial.new(): Tutorial
    local props: UIComponentProps = {
        name = Constants.COMPONENTS.TUTORIAL,
        size = UDim2.new(0.8, 0, 0.8, 0),
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchorPoint = Vector2.new(0.5, 0.5),
        backgroundColor3 = Constants.STYLES.BACKGROUND_COLOR,
        backgroundTransparency = 0,
        zIndex = Constants.DEFAULT_Z_INDEX,
    }
    
    local self = setmetatable(UIComponent.new(Constants.COMPONENTS.TUTORIAL, props), Tutorial)
    
    -- Create UI elements
    self:createUIElements()
    
    -- Set up event listeners
    self:setupEventListeners()
    
    return self
end

-- Create UI elements
function Tutorial:createUIElements()
    -- Create main container
    local container = Instance.new("Frame")
    container.Name = "MainContainer"
    container.Size = UDim2.new(1, -40, 1, -100)
    container.Position = UDim2.new(0, 20, 0, 80)
    container.BackgroundTransparency = 1
    container.Parent = self.instance
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Tutorial"
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
    
    -- Create content container
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, -100)
    contentContainer.Position = UDim2.new(0, 0, 0, 80)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ScrollBarThickness = 6
    contentContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    contentContainer.Parent = container
    
    -- Create tutorial sections
    local sections = {
        {
            title = "Getting Started",
            icon = "rbxassetid://98149848004338",
            steps = {
                "Welcome to the game! Let's get you started with the basics.",
                "Use WASD to move around and Space to jump.",
                "Click on objects to interact with them.",
                "Press E to open your inventory."
            }
        },
        {
            title = "Achievements",
            icon = "rbxassetid://79337595530955",
            steps = {
                "Complete tasks to earn achievements.",
                "Achievements give you rewards and bonuses.",
                "Check your progress in the Achievements menu.",
                "Some achievements are hidden until you discover them."
            }
        },
        {
            title = "Community Goals",
            icon = "rbxassetid://97149848004338",
            steps = {
                "Work together with other players to complete community goals.",
                "Each goal has unique rewards for all participants.",
                "Check the Community Goals menu to see active goals.",
                "Participate in goals to earn special rewards."
            }
        },
        {
            title = "Rebirth System",
            icon = "rbxassetid://129409029383961",
            steps = {
                "Rebirth to gain permanent bonuses.",
                "Each rebirth increases your power and unlocks new features.",
                "Save up resources for your next rebirth.",
                "Rebirth perks stack and provide long-term benefits."
            }
        }
    }
    
    -- Create section containers
    for i, section in ipairs(sections) do
        local sectionContainer = Instance.new("Frame")
        sectionContainer.Name = section.title .. "Section"
        sectionContainer.Size = UDim2.new(1, -20, 0, 200)
        sectionContainer.Position = UDim2.new(0, 10, 0, (i - 1) * 220)
        sectionContainer.BackgroundColor3 = Constants.STYLES.ACCENT_COLOR
        sectionContainer.BackgroundTransparency = 0.1
        sectionContainer.Parent = contentContainer
        
        -- Create section header
        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, 50)
        header.BackgroundTransparency = 1
        header.Parent = sectionContainer
        
        -- Create section icon
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 10, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = section.icon
        icon.Parent = header
        
        -- Create section title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -60, 1, 0)
        title.Position = UDim2.new(0, 60, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = section.title
        title.TextColor3 = Constants.STYLES.TEXT_COLOR
        title.TextSize = 20
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = header
        
        -- Create steps container
        local stepsContainer = Instance.new("Frame")
        stepsContainer.Name = "StepsContainer"
        stepsContainer.Size = UDim2.new(1, -20, 1, -60)
        stepsContainer.Position = UDim2.new(0, 10, 0, 60)
        stepsContainer.BackgroundTransparency = 1
        stepsContainer.Parent = sectionContainer
        
        -- Create steps
        for j, step in ipairs(section.steps) do
            local stepContainer = Instance.new("Frame")
            stepContainer.Name = "Step" .. j
            stepContainer.Size = UDim2.new(1, 0, 0, 30)
            stepContainer.Position = UDim2.new(0, 0, 0, (j - 1) * 35)
            stepContainer.BackgroundTransparency = 1
            stepContainer.Parent = stepsContainer
            
            -- Create step number
            local number = Instance.new("TextLabel")
            number.Name = "Number"
            number.Size = UDim2.new(0, 30, 1, 0)
            number.BackgroundTransparency = 1
            number.Text = tostring(j)
            number.TextColor3 = Constants.STYLES.TEXT_COLOR
            number.TextSize = 16
            number.Font = Enum.Font.GothamBold
            number.Parent = stepContainer
            
            -- Create step text
            local text = Instance.new("TextLabel")
            text.Name = "Text"
            text.Size = UDim2.new(1, -40, 1, 0)
            text.Position = UDim2.new(0, 40, 0, 0)
            text.BackgroundTransparency = 1
            text.Text = step
            text.TextColor3 = Constants.STYLES.TEXT_COLOR
            text.TextSize = 14
            text.Font = Enum.Font.Gotham
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.TextWrapped = true
            text.Parent = stepContainer
        end
    end
    
    -- Store references
    self.contentContainer = contentContainer
end

-- Set up event listeners
function Tutorial:setupEventListeners()
    -- Listen for tutorial updates
    ClientEventBridge:connectEvent("TutorialUpdated", function(data)
        self:updateTutorial(data)
    end)
end

-- Update tutorial
function Tutorial:updateTutorial(data)
    if not data then return end
    
    -- Update tutorial sections based on player progress
    for _, section in ipairs(data.sections) do
        local sectionContainer = self.instance:FindFirstChild("MainContainer"):FindFirstChild("ContentContainer"):FindFirstChild(section.title .. "Section")
        if sectionContainer then
            -- Update section visibility
            sectionContainer.Visible = section.unlocked
            
            -- Update step completion status
            for i, step in ipairs(section.steps) do
                local stepContainer = sectionContainer:FindFirstChild("StepsContainer"):FindFirstChild("Step" .. i)
                if stepContainer then
                    local number = stepContainer:FindFirstChild("Number")
                    if number then
                        number.TextColor3 = step.completed and Constants.STYLES.ACCENT_COLOR or Constants.STYLES.TEXT_COLOR
                    end
                    
                    local text = stepContainer:FindFirstChild("Text")
                    if text then
                        text.TextColor3 = step.completed and Constants.STYLES.ACCENT_COLOR or Constants.STYLES.TEXT_COLOR
                    end
                end
            end
        end
    end
end

-- Override event handler
function Tutorial:onEvent(event: UIEvent)
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
function Tutorial:destroy()
    -- Clean up event listeners
    if self.contentContainer then
        self.contentContainer:Destroy()
    end
    
    -- Call parent destroy
    UIComponent.destroy(self)
end

return Tutorial 