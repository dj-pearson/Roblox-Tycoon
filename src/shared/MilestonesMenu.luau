-- MilestonesMenu.luau
-- UI module for tracking gameplay progression goals
-- Part of UI refinements initiative (April 2025)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local UIComponent = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("UIComponent"))
local UIStyle = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("UIStyle"))

-- MilestonesMenu module
local MilestonesMenu = {}
MilestonesMenu.__index = MilestonesMenu
setmetatable(MilestonesMenu, UIComponent)

-- Example milestone categories and data
-- In a real implementation, this would come from server data
local MILESTONE_CATEGORIES = {
    gym = {
        title = "Gym Milestones",
        icon = "rbxassetid://7059249296", -- Building icon
        description = "Complete these milestones by expanding and upgrading your gym",
        milestones = {
            {
                id = "gym_size_1",
                title = "Starting Small",
                description = "Expand your gym to 5 tiles",
                reward = "$1,000",
                progress = 3,
                total = 5,
                completed = false
            },
            {
                id = "gym_size_2",
                title = "Growing Business",
                description = "Expand your gym to 15 tiles",
                reward = "$5,000",
                progress = 5,
                total = 15,
                completed = false
            },
            {
                id = "gym_equipment_1",
                title = "Basic Equipment",
                description = "Purchase 5 pieces of equipment",
                reward = "20% Equipment Efficiency",
                progress = 3,
                total = 5,
                completed = false
            },
            {
                id = "gym_rating_1",
                title = "Quality Establishment",
                description = "Reach a 3-star gym rating",
                reward = "10% More Members",
                progress = 2,
                total = 3,
                completed = false
            },
            {
                id = "gym_staff_1",
                title = "Hiring Spree",
                description = "Hire 3 staff members",
                reward = "Staff Efficiency +10%",
                progress = 1,
                total = 3,
                completed = false
            }
        }
    },
    membership = {
        title = "Membership Milestones",
        icon = "rbxassetid://7072724538", -- Person icon
        description = "Acquire and satisfy gym members to reach these milestones",
        milestones = {
            {
                id = "members_count_1",
                title = "First Members",
                description = "Attract 10 gym members",
                reward = "$2,000",
                progress = 7,
                total = 10,
                completed = false
            },
            {
                id = "members_count_2",
                title = "Popular Gym",
                description = "Attract 50 gym members",
                reward = "$10,000",
                progress = 7,
                total = 50,
                completed = false
            },
            {
                id = "members_satisfaction_1",
                title = "Quality Service",
                description = "Reach 80% average member satisfaction",
                reward = "Member Retention +15%",
                progress = 65,
                total = 80,
                completed = false
            },
            {
                id = "members_vip_1",
                title = "VIP Treatment",
                description = "Attract 5 VIP members",
                reward = "Revenue Per Member +20%",
                progress = 1,
                total = 5,
                completed = false
            }
        }
    },
    revenue = {
        title = "Revenue Milestones",
        icon = "rbxassetid://7072725323", -- Money icon
        description = "Earn revenue and increase your gym's profitability",
        milestones = {
            {
                id = "revenue_total_1",
                title = "First Profits",
                description = "Earn a total of $10,000",
                reward = "Cash Flow +5%",
                progress = 7500,
                total = 10000,
                completed = false
            },
            {
                id = "revenue_total_2",
                title = "Successful Business",
                description = "Earn a total of $100,000",
                reward = "$15,000 Bonus",
                progress = 7500,
                total = 100000,
                completed = false
            },
            {
                id = "revenue_day_1",
                title = "Busy Day",
                description = "Earn $5,000 in a single day",
                reward = "Member Join Rate +10%",
                progress = 2300,
                total = 5000,
                completed = false
            }
        }
    },
    special = {
        title = "Special Milestones",
        icon = "rbxassetid://7072716268", -- Star icon
        description = "Complete unique goals to unlock special rewards",
        milestones = {
            {
                id = "special_compete_1",
                title = "First Competition",
                description = "Host your first gym competition",
                reward = "Competition Prize Pool +20%",
                progress = 0,
                total = 1,
                completed = false
            },
            {
                id = "special_celebrity_1",
                title = "Celebrity Trainer",
                description = "Hire your first celebrity trainer",
                reward = "Member Gain Rate +25%",
                progress = 0,
                total = 1,
                completed = false
            },
            {
                id = "special_perfect_1",
                title = "Perfect Service",
                description = "Achieve 100% satisfaction for a full day",
                reward = "Premium Decoration Pack",
                progress = 0,
                total = 1,
                completed = false
            },
            {
                id = "special_rebirth_1",
                title = "Fresh Start",
                description = "Complete your first rebirth",
                reward = "2x Rebirth Points",
                progress = 0,
                total = 1,
                completed = false
            }
        }
    }
}

-- Create a new MilestonesMenu instance
function MilestonesMenu.new(customConfig)
    local config = {
        size = UDim2.new(0, 700, 0, 500),
        title = "Milestones",
        backgroundColor = UIStyle.colors.background,
        headerColor = UIStyle.colors.headerBackground
    }
    
    -- Merge with custom config if provided
    if customConfig then
        for key, value in pairs(customConfig) do
            config[key] = value
        end
    end
    
    -- Create base UIComponent
    local self = UIComponent.new(config)
    setmetatable(self, MilestonesMenu)
    
    -- Internal state
    self.currentCategory = "gym" -- Default selected category
    self.uiElements = {}
    self.milestoneData = MILESTONE_CATEGORIES
    
    return self
end

-- Build the UI structure
function MilestonesMenu:build()
    -- Main container styling
    self.container.BackgroundColor3 = UIStyle.colors.background
    self.container.BorderSizePixel = 0
    
    -- Create corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    corner.Parent = self.container
    
    -- Create header
    self:createHeader()
    
    -- Create two-panel layout: category selector and milestone content
    self:createCategorySidebar()
    self:createMilestonePanel()
    
    -- Load initial category
    self:showCategory(self.currentCategory)
end

-- Create header for the menu
function MilestonesMenu:createHeader()
    -- Create header container
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = UIStyle.colors.primaryDark
    header.BorderSizePixel = 0
    header.Parent = self.container
    
    -- Header corner rounding
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    headerCorner.Parent = header
    
    -- Only round the top corners
    local headerCornerFix = Instance.new("Frame")
    headerCornerFix.Name = "CornerFix"
    headerCornerFix.Size = UDim2.new(1, 0, 0.5, 0)
    headerCornerFix.Position = UDim2.new(0, 0, 0.5, 0)
    headerCornerFix.BackgroundColor3 = UIStyle.colors.primaryDark
    headerCornerFix.BorderSizePixel = 0
    headerCornerFix.Parent = header
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Font = UIStyle.fonts.titleMedium.Font
    titleText.TextSize = UIStyle.fonts.titleMedium.Size
    titleText.TextColor3 = UIStyle.colors.textPrimary
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Text = "Gym Milestones"
    titleText.Parent = header
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.BackgroundColor3 = UIStyle.colors.error
    closeButton.TextColor3 = UIStyle.colors.textPrimary
    closeButton.Text = "X"
    closeButton.Font = UIStyle.fonts.button.Font
    closeButton.TextSize = UIStyle.fonts.button.Size
    closeButton.BorderSizePixel = 0
    closeButton.Parent = header
    
    -- Close button corner rounding
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        self:hide()
    end)
    
    -- Store references
    self.uiElements.header = header
    self.uiElements.title = titleText
    self.uiElements.closeButton = closeButton
    
    -- Create content area under header
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, 0, 1, -60) -- Minus header height
    contentArea.Position = UDim2.new(0, 0, 0, 60)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = self.container
    
    self.uiElements.contentArea = contentArea
end

-- Create category sidebar
function MilestonesMenu:createCategorySidebar()
    local contentArea = self.uiElements.contentArea
    
    -- Create sidebar container
    local sidebar = Instance.new("Frame")
    sidebar.Name = "CategorySidebar"
    sidebar.Size = UDim2.new(0, 200, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = UIStyle.colors.backgroundDark
    sidebar.BackgroundTransparency = 0.2
    sidebar.BorderSizePixel = 0
    sidebar.Parent = contentArea
    
    -- Add padding and layout
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = sidebar
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = sidebar
    
    -- Create category buttons
    local categoryButtons = {}
    local index = 0
    
    for categoryId, categoryData in pairs(self.milestoneData) do
        local button = self:createCategoryButton(categoryId, categoryData, index)
        button.Parent = sidebar
        categoryButtons[categoryId] = button
        index = index + 1
    end
    
    -- Store references
    self.uiElements.sidebar = sidebar
    self.uiElements.categoryButtons = categoryButtons
end

-- Create a category button
function MilestonesMenu:createCategoryButton(categoryId, categoryData, index)
    local isSelected = categoryId == self.currentCategory
    
    -- Create button container
    local button = Instance.new("TextButton")
    button.Name = categoryId .. "Button"
    button.Size = UDim2.new(1, 0, 0, 50)
    button.BackgroundColor3 = isSelected and UIStyle.colors.primary or UIStyle.colors.buttonDefault
    button.BackgroundTransparency = 0.1
    button.Text = ""
    button.LayoutOrder = index
    button.BorderSizePixel = 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 10, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = categoryData.icon
    icon.ImageColor3 = UIStyle.colors.textPrimary
    icon.Parent = button
    
    -- Add label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -50, 0.6, 0)
    label.Position = UDim2.new(0, 40, 0, 10)
    label.BackgroundTransparency = 1
    label.Font = UIStyle.fonts.bodyLarge.Font
    label.TextSize = UIStyle.fonts.bodyLarge.Size
    label.TextColor3 = UIStyle.colors.textPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = categoryData.title
    label.Parent = button
    
    -- Add progress counter
    local progressCount = self:getCompletedMilestoneCount(categoryId)
    local totalCount = #categoryData.milestones
    
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "Progress"
    progressLabel.Size = UDim2.new(1, -50, 0.4, 0)
    progressLabel.Position = UDim2.new(0, 40, 0.6, 0)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Font = UIStyle.fonts.caption.Font
    progressLabel.TextSize = UIStyle.fonts.caption.Size
    progressLabel.TextColor3 = UIStyle.colors.textSecondary
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Text = progressCount .. " / " .. totalCount .. " completed"
    progressLabel.Parent = button
    
    -- Connect button
    button.MouseEnter:Connect(function()
        if categoryId ~= self.currentCategory then
            TweenService:Create(
                button,
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.buttonHover}
            ):Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        if categoryId ~= self.currentCategory then
            TweenService:Create(
                button,
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.buttonDefault}
            ):Play()
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        self:showCategory(categoryId)
    end)
    
    return button
end

-- Create the milestone content panel
function MilestonesMenu:createMilestonePanel()
    local contentArea = self.uiElements.contentArea
    
    -- Create panel container
    local panel = Instance.new("ScrollingFrame")
    panel.Name = "MilestonesPanel"
    panel.Size = UDim2.new(1, -220, 1, -20)
    panel.Position = UDim2.new(0, 210, 0, 10)
    panel.BackgroundTransparency = 1
    panel.ScrollBarThickness = 6
    panel.ScrollingDirection = Enum.ScrollingDirection.Y
    panel.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
    panel.Parent = contentArea
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = panel
    
    -- Add layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 15)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel
    
    -- Store reference
    self.uiElements.milestonesPanel = panel
end

-- Show milestones for a specific category
function MilestonesMenu:showCategory(categoryId)
    if not self.milestoneData[categoryId] then return end
    
    -- Update selected category
    local oldCategory = self.currentCategory
    self.currentCategory = categoryId
    
    -- Update button visuals
    if self.uiElements.categoryButtons then
        -- Deselect old category button
        if oldCategory and self.uiElements.categoryButtons[oldCategory] then
            TweenService:Create(
                self.uiElements.categoryButtons[oldCategory],
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.buttonDefault}
            ):Play()
        end
        
        -- Select new category button
        if self.uiElements.categoryButtons[categoryId] then
            TweenService:Create(
                self.uiElements.categoryButtons[categoryId],
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.primary}
            ):Play()
        end
    end
    
    -- Update header title
    if self.uiElements.title then
        self.uiElements.title.Text = self.milestoneData[categoryId].title
    end
    
    -- Clear current milestones
    local panel = self.uiElements.milestonesPanel
    if panel then
        for _, child in pairs(panel:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end
    else
        return -- Panel not created yet
    end
    
    -- Create category header and description
    self:createCategoryHeader(categoryId, panel)
    
    -- Create milestone cards
    local categoryData = self.milestoneData[categoryId]
    for i, milestone in ipairs(categoryData.milestones) do
        local card = self:createMilestoneCard(milestone, i)
        card.Parent = panel
    end
    
    -- Update canvas size
    self:updateCanvasSize()
end

-- Create category header and description
function MilestonesMenu:createCategoryHeader(categoryId, parent)
    local categoryData = self.milestoneData[categoryId]
    
    -- Category description container
    local descContainer = Instance.new("Frame")
    descContainer.Name = "CategoryDescription"
    descContainer.Size = UDim2.new(1, 0, 0, 80)
    descContainer.BackgroundColor3 = UIStyle.colors.primaryDark
    descContainer.BackgroundTransparency = 0.7
    descContainer.BorderSizePixel = 0
    descContainer.LayoutOrder = 0
    descContainer.Parent = parent
    
    -- Container corner rounding
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    containerCorner.Parent = descContainer
    
    -- Category icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "CategoryIcon"
    icon.Size = UDim2.new(0, 50, 0, 50)
    icon.Position = UDim2.new(0, 15, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = categoryData.icon
    icon.ImageColor3 = UIStyle.colors.textPrimary
    icon.Parent = descContainer
    
    -- Category description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -80, 1, -20)
    description.Position = UDim2.new(0, 75, 0, 10)
    description.BackgroundTransparency = 1
    description.Font = UIStyle.fonts.body.Font
    description.TextSize = UIStyle.fonts.body.Size
    description.TextColor3 = UIStyle.colors.textPrimary
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextYAlignment = Enum.TextYAlignment.Top
    description.Text = categoryData.description
    description.TextWrapped = true
    description.Parent = descContainer
    
    -- Progress overview
    local progressCount = self:getCompletedMilestoneCount(categoryId)
    local totalCount = #categoryData.milestones
    local progressPercentage = math.floor((progressCount / totalCount) * 100)
    
    local progress = Instance.new("TextLabel")
    progress.Name = "Progress"
    progress.Size = UDim2.new(0, 100, 0, 20)
    progress.Position = UDim2.new(1, -110, 1, -25)
    progress.BackgroundTransparency = 1
    progress.Font = UIStyle.fonts.numeric.Font
    progress.TextSize = UIStyle.fonts.numeric.Size
    progress.TextColor3 = UIStyle.colors.textPrimary
    progress.Text = progressCount .. "/" .. totalCount .. " (" .. progressPercentage .. "%)"
    progress.Parent = descContainer
    
    return descContainer
end

-- Create a milestone card
function MilestonesMenu:createMilestoneCard(milestone, index)
    local isCompleted = milestone.completed or milestone.progress >= milestone.total
    
    -- Card container
    local card = Instance.new("Frame")
    card.Name = "Milestone_" .. milestone.id
    card.Size = UDim2.new(1, 0, 0, 100)
    card.BackgroundColor3 = isCompleted and UIStyle.colors.success:Lerp(UIStyle.colors.background, 0.7) or UIStyle.colors.backgroundLight
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    
    -- Card corner rounding
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    cardCorner.Parent = card
    
    -- Milestone title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -220, 0, 30)
    title.Position = UDim2.new(0, 15, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = UIStyle.fonts.subheader.Font
    title.TextSize = UIStyle.fonts.subheader.Size
    title.TextColor3 = UIStyle.colors.textPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = milestone.title
    title.Parent = card
    
    -- Milestone description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -220, 0, 30)
    description.Position = UDim2.new(0, 15, 0, 40)
    description.BackgroundTransparency = 1
    description.Font = UIStyle.fonts.body.Font
    description.TextSize = UIStyle.fonts.body.Size
    description.TextColor3 = UIStyle.colors.textSecondary
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.Text = milestone.description
    description.TextWrapped = true
    description.Parent = card
    
    -- Reward container
    local rewardContainer = Instance.new("Frame")
    rewardContainer.Name = "RewardContainer"
    rewardContainer.Size = UDim2.new(0, 120, 0, 50)
    rewardContainer.Position = UDim2.new(1, -200, 0, 25)
    rewardContainer.BackgroundColor3 = UIStyle.colors.buttonDefault
    rewardContainer.BackgroundTransparency = 0.5
    rewardContainer.BorderSizePixel = 0
    rewardContainer.Parent = card
    
    -- Reward container corner rounding
    local rewardCorner = Instance.new("UICorner")
    rewardCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    rewardCorner.Parent = rewardContainer
    
    -- Reward label
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Name = "RewardLabel"
    rewardLabel.Size = UDim2.new(1, -10, 0, 20)
    rewardLabel.Position = UDim2.new(0, 5, 0, 5)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Font = UIStyle.fonts.caption.Font
    rewardLabel.TextSize = UIStyle.fonts.caption.Size
    rewardLabel.TextColor3 = UIStyle.colors.textSecondary
    rewardLabel.TextXAlignment = Enum.TextXAlignment.Center
    rewardLabel.Text = "Reward:"
    rewardLabel.Parent = rewardContainer
    
    -- Reward value
    local rewardValue = Instance.new("TextLabel")
    rewardValue.Name = "RewardValue"
    rewardValue.Size = UDim2.new(1, -10, 0, 20)
    rewardValue.Position = UDim2.new(0, 5, 0, 25)
    rewardValue.BackgroundTransparency = 1
    rewardValue.Font = UIStyle.fonts.bodyMedium.Font
    rewardValue.TextSize = UIStyle.fonts.bodyMedium.Size
    rewardValue.TextColor3 = UIStyle.colors.warning
    rewardValue.TextXAlignment = Enum.TextXAlignment.Center
    rewardValue.Text = milestone.reward
    rewardValue.Parent = rewardContainer
    
    -- Progress container
    local progressContainer = Instance.new("Frame")
    progressContainer.Name = "ProgressContainer"
    progressContainer.Size = UDim2.new(1, -240, 0, 14)
    progressContainer.Position = UDim2.new(0, 15, 0, 75)
    progressContainer.BackgroundColor3 = UIStyle.colors.buttonDefault
    progressContainer.BorderSizePixel = 0
    progressContainer.Parent = card
    
    -- Progress container corner rounding
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0.5, 0)
    progressCorner.Parent = progressContainer
    
    -- Progress fill
    local progressPercentage = math.clamp(milestone.progress / milestone.total, 0, 1)
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(progressPercentage, 0, 1, 0)
    progressFill.BackgroundColor3 = isCompleted and UIStyle.colors.success or UIStyle.colors.primary
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressContainer
    
    -- Progress fill corner rounding
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0.5, 0)
    fillCorner.Parent = progressFill
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(0, 100, 0, 20)
    progressText.Position = UDim2.new(1, -110, 0, 72)
    progressText.BackgroundTransparency = 1
    progressText.Font = UIStyle.fonts.numeric.Font
    progressText.TextSize = UIStyle.fonts.numeric.Size
    progressText.TextColor3 = UIStyle.colors.textPrimary
    progressText.Text = milestone.progress .. " / " .. milestone.total
    progressText.Parent = card
    
    -- Status indicator
    local statusIcon = Instance.new("ImageLabel")
    statusIcon.Name = "StatusIcon"
    statusIcon.Size = UDim2.new(0, 24, 0, 24)
    statusIcon.Position = UDim2.new(1, -35, 0, 15)
    statusIcon.BackgroundTransparency = 1
    statusIcon.Image = isCompleted and "rbxassetid://7072706620" or "rbxassetid://7072719338" -- Checkmark or incomplete icon
    statusIcon.ImageColor3 = isCompleted and UIStyle.colors.success or UIStyle.colors.textSecondary
    statusIcon.Parent = card
    
    return card
end

-- Get completed milestone count for a category
function MilestonesMenu:getCompletedMilestoneCount(categoryId)
    local count = 0
    local categoryData = self.milestoneData[categoryId]
    
    if categoryData and categoryData.milestones then
        for _, milestone in ipairs(categoryData.milestones) do
            if milestone.completed or milestone.progress >= milestone.total then
                count = count + 1
            end
        end
    end
    
    return count
end

-- Update milestone data
function MilestonesMenu:updateMilestoneData(data)
    if not data then return end
    
    -- Update milestone data with new values
    for categoryId, categoryData in pairs(data) do
        if self.milestoneData[categoryId] then
            if categoryData.milestones then
                for _, milestone in ipairs(categoryData.milestones) do
                    -- Find matching milestone in current data
                    for _, existingMilestone in ipairs(self.milestoneData[categoryId].milestones) do
                        if existingMilestone.id == milestone.id then
                            -- Update milestone data
                            existingMilestone.progress = milestone.progress
                            existingMilestone.completed = milestone.completed or milestone.progress >= milestone.total
                            break
                        end
                    end
                end
            end
        end
    end
    
    -- Refresh UI if visible
    if self.visible then
        self:showCategory(self.currentCategory)
    end
end

-- Update canvas size based on content
function MilestonesMenu:updateCanvasSize()
    local panel = self.uiElements.milestonesPanel
    if not panel then return end
    
    local totalHeight = 0
    local layout = panel:FindFirstChildOfClass("UIListLayout")
    
    if layout then
        totalHeight = layout.AbsoluteContentSize.Y + 20 -- Add padding
    end
    
    panel.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Module interface
function MilestonesMenu.create(data)
    local instance = MilestonesMenu.new(data)
    instance:build()
    
    -- Set the milestone data if provided
    if data and data.milestoneData then
        instance:updateMilestoneData(data.milestoneData)
    end
    
    return instance.container
end

function MilestonesMenu.open(ui, data)
    if not ui or not ui:IsA("Instance") then return end
    
    local self = ui._UIInstance
    if not self then
        -- Create a new instance if needed
        self = MilestonesMenu.new()
        self:build()
        ui._UIInstance = self
    end
    
    -- Update data if provided
    if data and data.milestoneData then
        self:updateMilestoneData(data.milestoneData)
    end
    
    -- Show the menu
    self:show()
    
    return ui
end

function MilestonesMenu.close(ui)
    if not ui or not ui:IsA("Instance") then return end
    
    local self = ui._UIInstance
    if self then
        self:hide()
    end
end

return MilestonesMenu