-- AchievementsUI.luau
-- UI module for displaying player achievements and badges
-- Part of UI refinements initiative (April 2025)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local UIComponent = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("UIComponent"))
local UIStyle = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("UIStyle"))

-- AchievementsUI module
local AchievementsUI = {}
AchievementsUI.__index = AchievementsUI
setmetatable(AchievementsUI, UIComponent)

-- Example achievement categories and data
-- In a real implementation, this would come from server data
local ACHIEVEMENT_CATEGORIES = {
    beginner = {
        title = "Beginner Achievements",
        icon = "rbxassetid://7072724538", -- Player icon
        description = "Start your gym tycoon journey with these basic accomplishments",
        achievements = {
            {
                id = "beginner_firstTile",
                title = "First Step",
                description = "Purchase your first gym tile",
                icon = "rbxassetid://7059358892", -- Tile icon
                reward = "$500",
                completed = true,
                completionDate = "2025-04-01T15:32:14Z",
            },
            {
                id = "beginner_firstEquipment",
                title = "Basic Equipment",
                description = "Buy your first piece of gym equipment",
                icon = "rbxassetid://7072706976", -- Weight icon
                reward = "5% Member Satisfaction",
                completed = true,
                completionDate = "2025-04-01T16:05:42Z",
            },
            {
                id = "beginner_firstMember",
                title = "First Customer",
                description = "Welcome your first gym member",
                icon = "rbxassetid://7072724538", -- Person icon
                reward = "$1,000",
                completed = true,
                completionDate = "2025-04-01T16:20:19Z",
            },
            {
                id = "beginner_firstStaff",
                title = "First Employee",
                description = "Hire your first staff member",
                icon = "rbxassetid://7072724785", -- Person with clipboard icon
                reward = "5% Staff Efficiency",
                completed = false,
                completionDate = nil,
            },
            {
                id = "beginner_dayOne",
                title = "Day One Complete",
                description = "Successfully operate your gym for one full day",
                icon = "rbxassetid://7072706706", -- Clock icon
                reward = "$2,000",
                completed = false,
                completionDate = nil,
            }
        }
    },
    intermediate = {
        title = "Intermediate Achievements",
        icon = "rbxassetid://7072706268", -- Trophy icon
        description = "Grow your gym business with these intermediate achievements",
        achievements = {
            {
                id = "intermediate_tenMembers",
                title = "Growing Membership",
                description = "Reach 10 active gym members",
                icon = "rbxassetid://7072724538", -- Person icon
                reward = "$5,000",
                completed = false,
                completionDate = nil,
            },
            {
                id = "intermediate_fiveEquipment",
                title = "Well Equipped",
                description = "Have 5 different exercise equipment types",
                icon = "rbxassetid://7072707049", -- Dumbbell icon
                reward = "10% Member Satisfaction",
                completed = false,
                completionDate = nil,
            },
            {
                id = "intermediate_satisfaction",
                title = "Customer Focus",
                description = "Reach 80% member satisfaction",
                icon = "rbxassetid://7072707339", -- Star icon
                reward = "15% Revenue Boost",
                completed = false,
                completionDate = nil,
            }
        }
    },
    expert = {
        title = "Expert Achievements",
        icon = "rbxassetid://7072719338", -- Medal icon
        description = "Master the gym tycoon with these advanced achievements",
        achievements = {
            {
                id = "expert_fiftyMembers",
                title = "Fitness Empire",
                description = "Reach 50 active gym members",
                icon = "rbxassetid://7072724538", -- Person icon
                reward = "$25,000",
                completed = false,
                completionDate = nil,
            },
            {
                id = "expert_allEquipment",
                title = "Fully Equipped",
                description = "Purchase all equipment types",
                icon = "rbxassetid://7072707049", -- Dumbbell icon
                reward = "25% Equipment Efficiency",
                completed = false,
                completionDate = nil,
            },
            {
                id = "expert_maxRating",
                title = "Five-Star Gym",
                description = "Achieve a 5-star gym rating",
                icon = "rbxassetid://7072707339", -- Star icon
                reward = "Celebrity Member Appearances",
                completed = false,
                completionDate = nil,
            },
            {
                id = "expert_threeDay",
                title = "Sustained Success",
                description = "Maintain 95% satisfaction for three consecutive days",
                icon = "rbxassetid://7072706706", -- Clock icon
                reward = "VIP Member Rate +50%",
                completed = false,
                completionDate = nil,
            }
        }
    },
    special = {
        title = "Special Achievements",
        icon = "rbxassetid://7072707368", -- Diamond icon
        description = "Unique accomplishments and special events",
        achievements = {
            {
                id = "special_competition",
                title = "Competition Host",
                description = "Host your first gym competition event",
                icon = "rbxassetid://7072706507", -- Flag icon
                reward = "Exclusive Gym Decoration",
                completed = false,
                completionDate = nil,
            },
            {
                id = "special_expansion",
                title = "Business Expansion",
                description = "Open a second gym location",
                icon = "rbxassetid://7059249296", -- Building icon
                reward = "Cross-Location Member Benefits",
                completed = false,
                completionDate = nil,
            },
            {
                id = "special_celebrity",
                title = "Celebrity Connection",
                description = "Have a celebrity visit your gym",
                icon = "rbxassetid://7072707240", -- Star person icon
                reward = "Massive Popularity Boost",
                completed = false,
                completionDate = nil,
            }
        }
    }
}

-- Stats for the achievement overview
local ACHIEVEMENT_STATS = {
    totalAchievements = 0,
    totalCompleted = 0,
    percentageComplete = 0,
    recentlyCompleted = {},
    categoryProgress = {}
}

-- Initialize achievement stats
local function initAchievementStats()
    local totalCount = 0
    local completedCount = 0
    ACHIEVEMENT_STATS.categoryProgress = {}
    ACHIEVEMENT_STATS.recentlyCompleted = {}
    
    for categoryId, categoryData in pairs(ACHIEVEMENT_CATEGORIES) do
        local categoryTotal = #categoryData.achievements
        local categoryCompleted = 0
        
        for _, achievement in ipairs(categoryData.achievements) do
            totalCount = totalCount + 1
            
            if achievement.completed then
                completedCount = completedCount + 1
                categoryCompleted = categoryCompleted + 1
                
                -- Add to recently completed if within last week (in a real implementation)
                if achievement.completionDate then
                    table.insert(ACHIEVEMENT_STATS.recentlyCompleted, achievement)
                end
            end
        end
        
        ACHIEVEMENT_STATS.categoryProgress[categoryId] = {
            completed = categoryCompleted,
            total = categoryTotal,
            percentage = categoryTotal > 0 and (categoryCompleted / categoryTotal) * 100 or 0
        }
    end
    
    ACHIEVEMENT_STATS.totalAchievements = totalCount
    ACHIEVEMENT_STATS.totalCompleted = completedCount
    ACHIEVEMENT_STATS.percentageComplete = totalCount > 0 and (completedCount / totalCount) * 100 or 0
    
    -- Sort recently completed by date (newest first)
    table.sort(ACHIEVEMENT_STATS.recentlyCompleted, function(a, b)
        return (a.completionDate or "") > (b.completionDate or "")
    end)
    
    -- Limit to 5 most recent
    while #ACHIEVEMENT_STATS.recentlyCompleted > 5 do
        table.remove(ACHIEVEMENT_STATS.recentlyCompleted)
    end
end

-- Initialize stats
initAchievementStats()

-- Create a new AchievementsUI instance
function AchievementsUI.new(customConfig)
    local config = {
        size = UDim2.new(0, 700, 0, 500),
        title = "Achievements",
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
    setmetatable(self, AchievementsUI)
    
    -- Internal state
    self.currentCategory = "overview" -- Default to overview screen
    self.uiElements = {}
    self.achievementData = ACHIEVEMENT_CATEGORIES
    self.achievementStats = ACHIEVEMENT_STATS
    
    return self
end

-- Build the UI structure
function AchievementsUI:build()
    -- Main container styling
    self.container.BackgroundColor3 = UIStyle.colors.background
    self.container.BorderSizePixel = 0
    
    -- Create corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    corner.Parent = self.container
    
    -- Create header
    self:createHeader()
    
    -- Create sidebar and content panel
    self:createSidebar()
    self:createContentPanel()
    
    -- Load initial view
    self:showCategory(self.currentCategory)
end

-- Create header
function AchievementsUI:createHeader()
    -- Header container
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
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = UIStyle.fonts.titleMedium.Font
    title.TextSize = UIStyle.fonts.titleMedium.Size
    title.TextColor3 = UIStyle.colors.textPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Achievements"
    title.Parent = header
    
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
    self.uiElements.title = title
    self.uiElements.closeButton = closeButton
    
    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, 0, 1, -60) -- Minus header height
    contentArea.Position = UDim2.new(0, 0, 0, 60)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = self.container
    
    self.uiElements.contentArea = contentArea
end

-- Create sidebar
function AchievementsUI:createSidebar()
    local contentArea = self.uiElements.contentArea
    
    -- Sidebar container
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
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
    
    -- Create navigation buttons
    local buttons = {}
    
    -- Overview button (always first)
    buttons.overview = self:createSidebarButton("overview", {
        title = "Overview",
        icon = "rbxassetid://7072724908", -- Home/dashboard icon
        layoutOrder = 0
    })
    buttons.overview.Parent = sidebar
    
    -- Create category buttons
    local index = 1
    for categoryId, categoryData in pairs(self.achievementData) do
        buttons[categoryId] = self:createSidebarButton(categoryId, {
            title = categoryData.title,
            icon = categoryData.icon,
            layoutOrder = index,
            progress = self.achievementStats.categoryProgress[categoryId] or {completed = 0, total = 0}
        })
        buttons[categoryId].Parent = sidebar
        index = index + 1
    end
    
    -- Store references
    self.uiElements.sidebar = sidebar
    self.uiElements.navButtons = buttons
end

-- Create a sidebar navigation button
function AchievementsUI:createSidebarButton(id, props)
    local isSelected = id == self.currentCategory
    
    -- Button container
    local button = Instance.new("TextButton")
    button.Name = id .. "Button"
    button.Size = UDim2.new(1, 0, 0, 50)
    button.BackgroundColor3 = isSelected and UIStyle.colors.primary or UIStyle.colors.buttonDefault
    button.BackgroundTransparency = 0.1
    button.Text = ""
    button.LayoutOrder = props.layoutOrder or 0
    button.BorderSizePixel = 0
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 10, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = props.icon or ""
    icon.ImageColor3 = UIStyle.colors.textPrimary
    icon.Parent = button
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -50, 0.6, 0)
    title.Position = UDim2.new(0, 40, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = UIStyle.fonts.bodyLarge.Font
    title.TextSize = UIStyle.fonts.bodyLarge.Size
    title.TextColor3 = UIStyle.colors.textPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = props.title or "Category"
    title.Parent = button
    
    -- Progress indicator (for category buttons)
    if id ~= "overview" and props.progress then
        local progress = props.progress
        local progressText = progress.completed .. "/" .. progress.total
        
        local progressLabel = Instance.new("TextLabel")
        progressLabel.Name = "Progress"
        progressLabel.Size = UDim2.new(1, -50, 0.4, 0)
        progressLabel.Position = UDim2.new(0, 40, 0.6, 0)
        progressLabel.BackgroundTransparency = 1
        progressLabel.Font = UIStyle.fonts.caption.Font
        progressLabel.TextSize = UIStyle.fonts.caption.Size
        progressLabel.TextColor3 = UIStyle.colors.textSecondary
        progressLabel.TextXAlignment = Enum.TextXAlignment.Left
        progressLabel.Text = progressText
        progressLabel.Parent = button
    end
    
    -- Button hover and click effects
    button.MouseEnter:Connect(function()
        if id ~= self.currentCategory then
            TweenService:Create(
                button,
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.buttonHover}
            ):Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        if id ~= self.currentCategory then
            TweenService:Create(
                button,
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.buttonDefault}
            ):Play()
        end
    end)
    
    button.MouseButton1Click:Connect(function()
        self:showCategory(id)
    end)
    
    return button
end

-- Create content panel
function AchievementsUI:createContentPanel()
    local contentArea = self.uiElements.contentArea
    
    -- Content panel container
    local panel = Instance.new("ScrollingFrame")
    panel.Name = "ContentPanel"
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
    self.uiElements.contentPanel = panel
end

-- Show a specific category
function AchievementsUI:showCategory(categoryId)
    if categoryId ~= "overview" and not self.achievementData[categoryId] and categoryId ~= "recently" then 
        return 
    end
    
    -- Update selected category
    local oldCategory = self.currentCategory
    self.currentCategory = categoryId
    
    -- Update button visuals
    if self.uiElements.navButtons then
        -- Deselect old button
        local oldButton = self.uiElements.navButtons[oldCategory]
        if oldButton then
            TweenService:Create(
                oldButton,
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.buttonDefault}
            ):Play()
        end
        
        -- Select new button
        local newButton = self.uiElements.navButtons[categoryId]
        if newButton then
            TweenService:Create(
                newButton,
                UIStyle.animations.fast,
                {BackgroundColor3 = UIStyle.colors.primary}
            ):Play()
        end
    end
    
    -- Update header title
    if self.uiElements.title then
        if categoryId == "overview" then
            self.uiElements.title.Text = "Achievements Overview"
        elseif categoryId == "recently" then
            self.uiElements.title.Text = "Recently Completed"
        else
            self.uiElements.title.Text = self.achievementData[categoryId].title
        end
    end
    
    -- Clear content panel
    local panel = self.uiElements.contentPanel
    if panel then
        for _, child in pairs(panel:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end
    else
        return -- Panel not created yet
    end
    
    -- Show appropriate content
    if categoryId == "overview" then
        self:buildOverviewContent()
    elseif categoryId == "recently" then
        self:buildRecentlyCompletedContent()
    else
        self:buildCategoryContent(categoryId)
    end
    
    -- Update canvas size
    self:updateCanvasSize()
end

-- Build the overview screen content
function AchievementsUI:buildOverviewContent()
    local panel = self.uiElements.contentPanel
    
    -- Progress summary container
    local summaryContainer = Instance.new("Frame")
    summaryContainer.Name = "ProgressSummary"
    summaryContainer.Size = UDim2.new(1, 0, 0, 150)
    summaryContainer.BackgroundColor3 = UIStyle.colors.backgroundLight
    summaryContainer.BackgroundTransparency = 0.1
    summaryContainer.BorderSizePixel = 0
    summaryContainer.LayoutOrder = 0
    summaryContainer.Parent = panel
    
    -- Container corner rounding
    local summaryCorner = Instance.new("UICorner")
    summaryCorner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    summaryCorner.Parent = summaryContainer
    
    -- Progress title
    local progressTitle = UIStyle.createText({
        name = "ProgressTitle",
        text = "Achievement Progress",
        style = "titleSmall",
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 0, 10),
        parent = summaryContainer
    })
    
    -- Progress percentage
    local percentage = math.floor(self.achievementStats.percentageComplete)
    local progressPercentage = UIStyle.createText({
        name = "ProgressPercentage",
        text = percentage .. "%",
        style = "titleLarge",
        size = UDim2.new(0, 100, 0, 40),
        position = UDim2.new(0, 10, 0, 50),
        parent = summaryContainer
    })
    progressPercentage.TextColor3 = UIStyle.colors.primary
    
    -- Progress text
    local progressText = UIStyle.createText({
        name = "ProgressText",
        text = self.achievementStats.totalCompleted .. " of " .. self.achievementStats.totalAchievements .. " achievements completed",
        style = "bodyMedium",
        size = UDim2.new(0, 300, 0, 30),
        position = UDim2.new(0, 10, 0, 90),
        parent = summaryContainer
    })
    
    -- Progress bar container
    local barContainer = Instance.new("Frame")
    barContainer.Name = "BarContainer"
    barContainer.Size = UDim2.new(0.7, 0, 0, 20)
    barContainer.Position = UDim2.new(0.25, 0, 0, 60)
    barContainer.BackgroundColor3 = UIStyle.colors.buttonDefault
    barContainer.BorderSizePixel = 0
    barContainer.Parent = summaryContainer
    
    -- Bar container corners
    local barContainerCorner = Instance.new("UICorner")
    barContainerCorner.CornerRadius = UDim.new(0.5, 0)
    barContainerCorner.Parent = barContainer
    
    -- Progress bar fill
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(percentage / 100, 0, 1, 0)
    barFill.BackgroundColor3 = UIStyle.colors.primary
    barFill.BorderSizePixel = 0
    barFill.Parent = barContainer
    
    -- Bar fill corners
    local barFillCorner = Instance.new("UICorner")
    barFillCorner.CornerRadius = UDim.new(0.5, 0)
    barFillCorner.Parent = barFill
    
    -- Category progress section title
    local categoryTitle = UIStyle.createText({
        name = "CategoryTitle",
        text = "Progress by Category",
        style = "titleSmall",
        size = UDim2.new(1, -20, 0, 30),
        position = UDim2.new(0, 10, 0, 0),
        parent = panel,
        layoutOrder = 1
    })
    categoryTitle.LayoutOrder = 1
    
    -- Create category progress cards
    local index = 2
    for categoryId, categoryData in pairs(self.achievementData) do
        local progress = self.achievementStats.categoryProgress[categoryId]
        local card = self:createCategoryProgressCard(categoryId, categoryData, progress)
        card.LayoutOrder = index
        card.Parent = panel
        index = index + 1
    end
    
    -- Recent completions section
    if #self.achievementStats.recentlyCompleted > 0 then
        -- Section title
        local recentTitle = UIStyle.createText({
            name = "RecentTitle",
            text = "Recently Completed",
            style = "titleSmall",
            size = UDim2.new(1, -20, 0, 30),
            position = UDim2.new(0, 10, 0, 0),
            parent = panel,
            layoutOrder = index
        })
        recentTitle.LayoutOrder = index
        index = index + 1
        
        -- Recent completions container
        local recentContainer = Instance.new("Frame")
        recentContainer.Name = "RecentContainer"
        recentContainer.Size = UDim2.new(1, 0, 0, 120)
        recentContainer.BackgroundColor3 = UIStyle.colors.backgroundLight
        recentContainer.BackgroundTransparency = 0.1
        recentContainer.BorderSizePixel = 0
        recentContainer.LayoutOrder = index
        recentContainer.Parent = panel
        
        -- Container corner rounding
        local recentCorner = Instance.new("UICorner")
        recentCorner.CornerRadius = UIStyle.layout.cornerRadiusMedium
        recentCorner.Parent = recentContainer
        
        -- Add recent achievements (up to 3)
        local recentCount = math.min(#self.achievementStats.recentlyCompleted, 3)
        for i = 1, recentCount do
            local achievement = self.achievementStats.recentlyCompleted[i]
            local item = self:createRecentAchievementItem(achievement, i)
            item.Parent = recentContainer
        end
        
        -- View all button
        local viewAllButton = Instance.new("TextButton")
        viewAllButton.Name = "ViewAllButton"
        viewAllButton.Size = UDim2.new(0, 120, 0, 30)
        viewAllButton.Position = UDim2.new(1, -130, 1, -40)
        viewAllButton.BackgroundColor3 = UIStyle.colors.primary
        viewAllButton.TextColor3 = UIStyle.colors.textPrimary
        viewAllButton.Text = "View All"
        viewAllButton.Font = UIStyle.fonts.button.Font
        viewAllButton.TextSize = UIStyle.fonts.button.Size
        viewAllButton.BorderSizePixel = 0
        viewAllButton.Parent = recentContainer
        
        -- Button corner rounding
        local viewAllCorner = Instance.new("UICorner")
        viewAllCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
        viewAllCorner.Parent = viewAllButton
        
        -- Connect view all button
        viewAllButton.MouseButton1Click:Connect(function()
            self:showCategory("recently")
        end)
        
        index = index + 1
    end
end

-- Create a category progress card for the overview
function AchievementsUI:createCategoryProgressCard(categoryId, categoryData, progress)
    -- Card container
    local card = Instance.new("Frame")
    card.Name = "Category_" .. categoryId
    card.Size = UDim2.new(1, 0, 0, 70)
    card.BackgroundColor3 = UIStyle.colors.backgroundLight
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    
    -- Card corner rounding
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    cardCorner.Parent = card
    
    -- Category icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "CategoryIcon"
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 15, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = categoryData.icon
    icon.ImageColor3 = UIStyle.colors.textPrimary
    icon.Parent = card
    
    -- Category name
    local name = UIStyle.createText({
        name = "CategoryName",
        text = categoryData.title,
        style = "bodyLarge",
        size = UDim2.new(0.4, 0, 0, 25),
        position = UDim2.new(0, 70, 0, 10),
        parent = card
    })
    
    -- Progress text
    local progressText = UIStyle.createText({
        name = "ProgressText",
        text = progress.completed .. "/" .. progress.total,
        style = "bodyMedium",
        size = UDim2.new(0.2, 0, 0, 20),
        position = UDim2.new(0, 70, 0, 35),
        parent = card
    })
    progressText.TextColor3 = UIStyle.colors.textSecondary
    
    -- Progress percentage
    local progressPercentage = UIStyle.createText({
        name = "ProgressPercentage",
        text = math.floor(progress.percentage) .. "%",
        style = "bodyMedium",
        size = UDim2.new(0.1, 0, 0, 20),
        position = UDim2.new(0.9, -50, 0.5, -10),
        parent = card
    })
    progressPercentage.TextColor3 = UIStyle.colors.primary
    
    -- Progress bar container
    local barContainer = Instance.new("Frame")
    barContainer.Name = "BarContainer"
    barContainer.Size = UDim2.new(0.4, 0, 0, 10)
    barContainer.Position = UDim2.new(0.45, 0, 0.5, 0)
    barContainer.AnchorPoint = Vector2.new(0, 0.5)
    barContainer.BackgroundColor3 = UIStyle.colors.buttonDefault
    barContainer.BorderSizePixel = 0
    barContainer.Parent = card
    
    -- Bar container corners
    local barContainerCorner = Instance.new("UICorner")
    barContainerCorner.CornerRadius = UDim.new(0.5, 0)
    barContainerCorner.Parent = barContainer
    
    -- Progress bar fill
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(progress.percentage / 100, 0, 1, 0)
    barFill.BackgroundColor3 = UIStyle.colors.primary
    barFill.BorderSizePixel = 0
    barFill.Parent = barContainer
    
    -- Bar fill corners
    local barFillCorner = Instance.new("UICorner")
    barFillCorner.CornerRadius = UDim.new(0.5, 0)
    barFillCorner.Parent = barFill
    
    -- Make the entire card clickable
    local button = Instance.new("TextButton")
    button.Name = "CardButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = card
    
    -- Connect button
    button.MouseButton1Click:Connect(function()
        self:showCategory(categoryId)
    end)
    
    return card
end

-- Create a recent achievement item
function AchievementsUI:createRecentAchievementItem(achievement, index)
    -- Item container
    local item = Instance.new("Frame")
    item.Name = "RecentItem_" .. achievement.id
    item.Size = UDim2.new(0.33, -10, 1, -20)
    item.Position = UDim2.new((index - 1) * 0.33, 5 + (index - 1) * 5, 0, 10)
    item.BackgroundColor3 = UIStyle.colors.background
    item.BackgroundTransparency = 0.3
    item.BorderSizePixel = 0
    
    -- Item corner rounding
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    itemCorner.Parent = item
    
    -- Achievement icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "AchievementIcon"
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, 10, 0, 10)
    icon.BackgroundTransparency = 1
    icon.Image = achievement.icon
    icon.ImageColor3 = UIStyle.colors.textPrimary
    icon.Parent = item
    
    -- Achievement title
    local title = UIStyle.createText({
        name = "Title",
        text = achievement.title,
        style = "bodyMedium",
        size = UDim2.new(1, -50, 0, 20),
        position = UDim2.new(0, 45, 0, 15),
        parent = item
    })
    
    -- Achievement description
    local description = UIStyle.createText({
        name = "Description",
        text = achievement.description,
        style = "caption",
        size = UDim2.new(1, -20, 0, 40),
        position = UDim2.new(0, 10, 0, 45),
        parent = item
    })
    description.TextWrapped = true
    description.TextColor3 = UIStyle.colors.textSecondary
    
    -- Achievement date
    if achievement.completionDate then
        -- Parse date for display
        local dateString = "Completed recently"
        
        -- In a real implementation, format the date nicely
        if achievement.completionDate then
            -- Remove the time portion and just get the date
            local datePart = string.match(achievement.completionDate, "(%d+-%d+-%d+)")
            if datePart then
                dateString = "Completed " .. datePart
            end
        end
        
        local date = UIStyle.createText({
            name = "Date",
            text = dateString,
            style = "caption",
            size = UDim2.new(1, -20, 0, 15),
            position = UDim2.new(0, 10, 1, -20),
            parent = item
        })
        date.TextColor3 = UIStyle.colors.textSecondary
        date.TextSize = 10
    end
    
    return item
end

-- Build category content
function AchievementsUI:buildCategoryContent(categoryId)
    local panel = self.uiElements.contentPanel
    local categoryData = self.achievementData[categoryId]
    
    -- Header with description
    local headerContainer = Instance.new("Frame")
    headerContainer.Name = "CategoryHeader"
    headerContainer.Size = UDim2.new(1, 0, 0, 80)
    headerContainer.BackgroundColor3 = UIStyle.colors.primaryDark
    headerContainer.BackgroundTransparency = 0.7
    headerContainer.BorderSizePixel = 0
    headerContainer.LayoutOrder = 0
    headerContainer.Parent = panel
    
    -- Header corner rounding
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    headerCorner.Parent = headerContainer
    
    -- Category icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "CategoryIcon"
    icon.Size = UDim2.new(0, 50, 0, 50)
    icon.Position = UDim2.new(0, 15, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = categoryData.icon
    icon.ImageColor3 = UIStyle.colors.textPrimary
    icon.Parent = headerContainer
    
    -- Category description
    local description = UIStyle.createText({
        name = "Description",
        text = categoryData.description,
        style = "body",
        size = UDim2.new(1, -80, 1, -20),
        position = UDim2.new(0, 75, 0, 10),
        parent = headerContainer
    })
    description.TextWrapped = true
    
    -- Progress bar
    local progress = self.achievementStats.categoryProgress[categoryId]
    local categoryProgress = Instance.new("Frame")
    categoryProgress.Name = "ProgressContainer"
    categoryProgress.Size = UDim2.new(1, 0, 0, 50)
    categoryProgress.BackgroundColor3 = UIStyle.colors.backgroundLight
    categoryProgress.BackgroundTransparency = 0.1
    categoryProgress.BorderSizePixel = 0
    categoryProgress.LayoutOrder = 1
    categoryProgress.Parent = panel
    
    -- Progress container corner rounding
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    progressCorner.Parent = categoryProgress
    
    -- Progress text
    local progressText = UIStyle.createText({
        name = "ProgressText",
        text = "Progress: " .. progress.completed .. " of " .. progress.total .. " completed (" .. math.floor(progress.percentage) .. "%)",
        style = "bodyMedium",
        size = UDim2.new(1, -20, 0, 20),
        position = UDim2.new(0, 10, 0, 5),
        parent = categoryProgress
    })
    
    -- Progress bar container
    local barContainer = Instance.new("Frame")
    barContainer.Name = "BarContainer"
    barContainer.Size = UDim2.new(1, -20, 0, 10)
    barContainer.Position = UDim2.new(0, 10, 0, 30)
    barContainer.BackgroundColor3 = UIStyle.colors.buttonDefault
    barContainer.BorderSizePixel = 0
    barContainer.Parent = categoryProgress
    
    -- Bar container corners
    local barContainerCorner = Instance.new("UICorner")
    barContainerCorner.CornerRadius = UDim.new(0.5, 0)
    barContainerCorner.Parent = barContainer
    
    -- Progress bar fill
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(progress.percentage / 100, 0, 1, 0)
    barFill.BackgroundColor3 = UIStyle.colors.primary
    barFill.BorderSizePixel = 0
    barFill.Parent = barContainer
    
    -- Bar fill corners
    local barFillCorner = Instance.new("UICorner")
    barFillCorner.CornerRadius = UDim.new(0.5, 0)
    barFillCorner.Parent = barFill
    
    -- Create achievement cards
    for i, achievement in ipairs(categoryData.achievements) do
        local card = self:createAchievementCard(achievement, i + 1)
        card.Parent = panel
    end
end

-- Create an achievement card
function AchievementsUI:createAchievementCard(achievement, index)
    local isCompleted = achievement.completed
    
    -- Card container
    local card = Instance.new("Frame")
    card.Name = "Achievement_" .. achievement.id
    card.Size = UDim2.new(1, 0, 0, 100)
    card.BackgroundColor3 = isCompleted and UIStyle.colors.success:Lerp(UIStyle.colors.background, 0.8) or UIStyle.colors.backgroundLight
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    
    -- Card corner rounding
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    cardCorner.Parent = card
    
    -- Achievement icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "AchievementIcon"
    icon.Size = UDim2.new(0, 50, 0, 50)
    icon.Position = UDim2.new(0, 15, 0, 15)
    icon.BackgroundTransparency = isCompleted and 1 or 0.5
    icon.BackgroundColor3 = UIStyle.colors.buttonDefault
    icon.Image = achievement.icon
    icon.ImageColor3 = isCompleted and UIStyle.colors.success or UIStyle.colors.textSecondary
    icon.Parent = card
    
    -- Icon corner rounding
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = icon
    
    -- Achievement title
    local title = UIStyle.createText({
        name = "Title",
        text = achievement.title,
        style = "subheader",
        size = UDim2.new(1, -240, 0, 25),
        position = UDim2.new(0, 80, 0, 15),
        parent = card
    })
    
    -- Achievement description
    local description = UIStyle.createText({
        name = "Description",
        text = achievement.description,
        style = "body",
        size = UDim2.new(1, -240, 0, 25),
        position = UDim2.new(0, 80, 0, 45),
        parent = card
    })
    description.TextColor3 = UIStyle.colors.textSecondary
    
    -- Reward container
    local rewardContainer = Instance.new("Frame")
    rewardContainer.Name = "RewardContainer"
    rewardContainer.Size = UDim2.new(0, 130, 0, 60)
    rewardContainer.Position = UDim2.new(1, -140, 0, 20)
    rewardContainer.BackgroundColor3 = UIStyle.colors.buttonDefault
    rewardContainer.BackgroundTransparency = 0.5
    rewardContainer.BorderSizePixel = 0
    rewardContainer.Parent = card
    
    -- Reward container corner rounding
    local rewardCorner = Instance.new("UICorner")
    rewardCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    rewardCorner.Parent = rewardContainer
    
    -- Reward label
    local rewardLabel = UIStyle.createText({
        name = "RewardLabel",
        text = "Reward:",
        style = "caption",
        size = UDim2.new(1, -10, 0, 20),
        position = UDim2.new(0, 5, 0, 5),
        xAlign = Enum.TextXAlignment.Center,
        parent = rewardContainer
    })
    rewardLabel.TextColor3 = UIStyle.colors.textSecondary
    
    -- Reward value
    local rewardValue = UIStyle.createText({
        name = "RewardValue",
        text = achievement.reward,
        style = "bodyMedium",
        size = UDim2.new(1, -10, 0, 30),
        position = UDim2.new(0, 5, 0, 25),
        xAlign = Enum.TextXAlignment.Center,
        parent = rewardContainer
    })
    rewardValue.TextColor3 = isCompleted and UIStyle.colors.success or UIStyle.colors.warning
    
    -- Completion status
    local statusIcon = Instance.new("ImageLabel")
    statusIcon.Name = "StatusIcon"
    statusIcon.Size = UDim2.new(0, 24, 0, 24)
    statusIcon.Position = UDim2.new(1, -35, 0, 15)
    statusIcon.BackgroundTransparency = 1
    statusIcon.Image = isCompleted and "rbxassetid://7072706620" or "rbxassetid://7072719338" -- Checkmark or incomplete icon
    statusIcon.ImageColor3 = isCompleted and UIStyle.colors.success or UIStyle.colors.textSecondary
    statusIcon.Parent = card
    
    -- Add completion date if completed
    if isCompleted and achievement.completionDate then
        -- Parse date for display
        local dateString = "Recently completed"
        
        -- In a real implementation, format the date nicely
        if achievement.completionDate then
            -- Remove the time portion and just get the date
            local datePart = string.match(achievement.completionDate, "(%d+-%d+-%d+)")
            if datePart then
                dateString = "Completed on " .. datePart
            end
        end
        
        local completionDate = UIStyle.createText({
            name = "CompletionDate",
            text = dateString,
            style = "caption",
            size = UDim2.new(0, 200, 0, 15),
            position = UDim2.new(0, 80, 0, 75),
            parent = card
        })
        completionDate.TextColor3 = UIStyle.colors.success
        completionDate.TextSize = 10
    end
    
    return card
end

-- Build recently completed content
function AchievementsUI:buildRecentlyCompletedContent()
    local panel = self.uiElements.contentPanel
    local recentAchievements = self.achievementStats.recentlyCompleted
    
    -- Header
    local headerContainer = Instance.new("Frame")
    headerContainer.Name = "RecentHeader"
    headerContainer.Size = UDim2.new(1, 0, 0, 80)
    headerContainer.BackgroundColor3 = UIStyle.colors.primaryDark
    headerContainer.BackgroundTransparency = 0.7
    headerContainer.BorderSizePixel = 0
    headerContainer.LayoutOrder = 0
    headerContainer.Parent = panel
    
    -- Header corner rounding
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    headerCorner.Parent = headerContainer
    
    -- Header icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "HeaderIcon"
    icon.Size = UDim2.new(0, 50, 0, 50)
    icon.Position = UDim2.new(0, 15, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://7072707339" -- Trophy icon
    icon.ImageColor3 = UIStyle.colors.textPrimary
    icon.Parent = headerContainer
    
    -- Header description
    local description = UIStyle.createText({
        name = "Description",
        text = "Your most recently completed achievements from all categories",
        style = "body",
        size = UDim2.new(1, -80, 1, -20),
        position = UDim2.new(0, 75, 0, 10),
        parent = headerContainer
    })
    description.TextWrapped = true
    
    -- Check if there are any recent achievements
    if #recentAchievements == 0 then
        local noAchievements = UIStyle.createText({
            name = "NoAchievements",
            text = "You haven't completed any achievements yet.\nComplete achievements to see them here!",
            style = "bodyLarge",
            size = UDim2.new(1, -40, 0, 80),
            position = UDim2.new(0, 20, 0, 100),
            xAlign = Enum.TextXAlignment.Center,
            parent = panel,
            layoutOrder = 1
        })
    else
        -- Create achievement cards for recently completed achievements
        for i, achievement in ipairs(recentAchievements) do
            local card = self:createAchievementCard(achievement, i)
            card.Parent = panel
        end
    end
end

-- Update canvas size based on content
function AchievementsUI:updateCanvasSize()
    local panel = self.uiElements.contentPanel
    if not panel then return end
    
    local totalHeight = 0
    local layout = panel:FindFirstChildOfClass("UIListLayout")
    
    if layout then
        totalHeight = layout.AbsoluteContentSize.Y + 20 -- Add padding
    end
    
    panel.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Update achievement data
function AchievementsUI:updateAchievementData(data)
    if not data then return end
    
    -- Update achievement data with provided values
    for categoryId, categoryData in pairs(data) do
        if self.achievementData[categoryId] then
            if categoryData.achievements then
                for _, achievement in ipairs(categoryData.achievements) do
                    -- Find matching achievement in current data
                    for _, existingAchievement in ipairs(self.achievementData[categoryId].achievements) do
                        if existingAchievement.id == achievement.id then
                            -- Update achievement data
                            existingAchievement.completed = achievement.completed
                            existingAchievement.completionDate = achievement.completionDate
                            break
                        end
                    end
                end
            end
        end
    end
    
    -- Recalculate stats
    initAchievementStats()
    
    -- Refresh UI if visible
    if self.visible then
        self:showCategory(self.currentCategory)
    end
end

-- Module interface
function AchievementsUI.create(data)
    local instance = AchievementsUI.new(data)
    instance:build()
    
    -- Set the achievement data if provided
    if data and data.achievementData then
        instance:updateAchievementData(data.achievementData)
    end
    
    return instance.container
end

function AchievementsUI.open(ui, data)
    if not ui or not ui:IsA("Instance") then return end
    
    local self = ui._UIInstance
    if not self then
        -- Create a new instance if needed
        self = AchievementsUI.new()
        self:build()
        ui._UIInstance = self
    end
    
    -- Update data if provided
    if data and data.achievementData then
        self:updateAchievementData(data.achievementData)
    end
    
    -- Show the UI
    self:show()
    
    return ui
end

function AchievementsUI.close(ui)
    if not ui or not ui:IsA("Instance") then return end
    
    local self = ui._UIInstance
    if self then
        self:hide()
    end
end

return AchievementsUI