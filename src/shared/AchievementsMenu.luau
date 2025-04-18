-- AchievementsMenu.luau
-- UI Module for displaying player achievements
-- Place in ReplicatedStorage/UIModules

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Import client systems
local ClientRegistry = require(LocalPlayer.PlayerScripts.Core.ClientRegistry)
local UIManager = ClientRegistry.getSystem("UIManager")
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")
local NotificationSystem = ClientRegistry.getSystem("NotificationSystem")

-- Configuration
local CONFIG = {
    debugEnabled = true,
    menuTitle = "Achievements",
    maxCardsPerPage = 6,
    cardSize = Vector2.new(480, 100),
    cardSpacing = 10,
    categoryColors = {},  -- Will be populated from server data
    defaultCategory = "all",
    sortOptions = {
        {id = "category", name = "Category"},
        {id = "difficulty", name = "Difficulty"},
        {id = "progress", name = "Progress"},
        {id = "unlocked", name = "Unlocked"}
    },
    defaultSortOption = "category"
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[AchievementsMenu]", ...)
    end
end

-- Module table
local AchievementsMenu = {
    -- State
    achievementData = {
        unlocked = {},
        progress = {},
        definitions = {}
    },
    selectedCategory = CONFIG.defaultCategory,
    selectedSort = CONFIG.defaultSortOption,
    currentPage = 1,
    totalPages = 1
}

-- Helper function to create an achievement card
local function createAchievementCard(achievement, isUnlocked, progress)
    -- Create card frame
    local card = Instance.new("Frame")
    card.Name = "AchievementCard_" .. achievement.id
    card.Size = UDim2.fromOffset(CONFIG.cardSize.X, CONFIG.cardSize.Y)
    card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    
    -- Apply rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    -- Get category color
    local categoryColor = achievement.categoryColor or Color3.fromRGB(200, 200, 200)
    
    -- Add color accent at left
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 5, 1, 0)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BackgroundColor3 = categoryColor
    accent.BorderSizePixel = 0
    accent.ZIndex = 2
    accent.Parent = card
    
    -- Add rounded corners to accent
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 4)
    accentCorner.Parent = accent
    
    -- Add icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 50, 0, 50)
    icon.Position = UDim2.new(0, 15, 0.5, -25)
    icon.BackgroundTransparency = 1
    icon.Image = achievement.icon or "rbxassetid://6031090990" -- Default icon
    icon.Parent = card
    
    -- Add title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -80, 0, 28)
    title.Position = UDim2.new(0, 70, 0, 10)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextWrapped = true
    title.Text = achievement.name
    title.Parent = card
    
    -- Add achievement description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -80, 0, 36)
    description.Position = UDim2.new(0, 70, 0, 38)
    description.BackgroundTransparency = 1
    description.TextColor3 = Color3.fromRGB(200, 200, 200)
    description.TextSize = 14
    description.Font = Enum.Font.Gotham
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Text = achievement.description
    description.Parent = card
    
    -- Add progress section
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = UDim2.new(1, -20, 0, 20)
    progressFrame.Position = UDim2.new(0, 10, 0, 75)
    progressFrame.BackgroundTransparency = 1
    progressFrame.Parent = card
    
    -- Add progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(0.8, 0, 0, 10)
    progressBg.Position = UDim2.new(0, 0, 0.5, -5)
    progressBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = progressFrame
    
    -- Round corners of progress bar bg
    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 4)
    progressBgCorner.Parent = progressBg
    
    -- Calculate progress percentage
    local progressValue = 0
    if achievement.progressMax and achievement.progressMax > 0 then
        progressValue = math.min(1, progress / achievement.progressMax)
    elseif isUnlocked then
        progressValue = 1
    end
    
    -- Add progress bar fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(progressValue, 0, 1, 0)
    progressFill.BackgroundColor3 = categoryColor
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    -- Round corners of progress fill
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 4)
    progressFillCorner.Parent = progressFill
    
    -- Add progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(0.2, -10, 1, 0)
    progressText.Position = UDim2.new(0.8, 10, 0, 0)
    progressText.BackgroundTransparency = 1
    progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressText.TextSize = 14
    progressText.Font = Enum.Font.GothamSemibold
    progressText.TextXAlignment = Enum.TextXAlignment.Right
    
    -- Format progress text
    if isUnlocked then
        progressText.Text = "Completed!"
    elseif achievement.progressMax then
        progressText.Text = progress .. "/" .. achievement.progressMax
    else
        progressText.Text = "0%"
    end
    
    progressText.Parent = progressFrame
    
    -- Dim the card if not unlocked
    if not isUnlocked then
        card.BackgroundTransparency = 0.3
    end
    
    -- Add difficulty indicator (stars)
    if achievement.difficulty then
        local difficultyFrame = Instance.new("Frame")
        difficultyFrame.Name = "DifficultyFrame"
        difficultyFrame.Size = UDim2.new(0, 80, 0, 20)
        difficultyFrame.Position = UDim2.new(1, -100, 0, 10)
        difficultyFrame.BackgroundTransparency = 1
        difficultyFrame.Parent = card
        
        -- Add stars based on difficulty
        for i = 1, 5 do
            local star = Instance.new("ImageLabel")
            star.Name = "Star" .. i
            star.Size = UDim2.new(0, 16, 0, 16)
            star.Position = UDim2.new(0, (i-1) * 18, 0, 0)
            star.BackgroundTransparency = 1
            
            -- Filled or outline star based on difficulty
            if i <= achievement.difficulty then
                star.Image = "rbxassetid://6031068426" -- Filled star
                star.ImageColor3 = Color3.fromRGB(255, 215, 0) -- Gold
            else
                star.Image = "rbxassetid://6031068433" -- Outline star
                star.ImageColor3 = Color3.fromRGB(150, 150, 150) -- Gray
            end
            
            star.Parent = difficultyFrame
        end
    end
    
    -- Add checkmark if unlocked
    if isUnlocked then
        local checkmark = Instance.new("ImageLabel")
        checkmark.Name = "Checkmark"
        checkmark.Size = UDim2.new(0, 24, 0, 24)
        checkmark.Position = UDim2.new(1, -30, 0, 10)
        checkmark.BackgroundTransparency = 1
        checkmark.Image = "rbxassetid://6031094678" -- Checkmark icon
        checkmark.ImageColor3 = Color3.fromRGB(50, 200, 50) -- Green checkmark
        checkmark.Parent = card
    end
    
    return card
end

-- Create the achievements menu UI
function AchievementsMenu.create()
    log("Creating achievements menu")
    
    -- Create the ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AchievementsMenu"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 500)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add rounded corners
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Title bar corners
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Bottom frame to fix corner overlap
    local bottomFix = Instance.new("Frame")
    bottomFix.Name = "BottomFix"
    bottomFix.Size = UDim2.new(1, 0, 0.5, 0)
    bottomFix.Position = UDim2.new(0, 0, 0.5, 0)
    bottomFix.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    bottomFix.BorderSizePixel = 0
    bottomFix.ZIndex = 0
    bottomFix.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 40, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 22
    titleText.Font = Enum.Font.GothamBold
    titleText.Text = CONFIG.menuTitle
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Trophy icon
    local trophyIcon = Instance.new("ImageLabel")
    trophyIcon.Name = "TrophyIcon"
    trophyIcon.Size = UDim2.new(0, 24, 0, 24)
    trophyIcon.Position = UDim2.new(0, 10, 0.5, -12)
    trophyIcon.BackgroundTransparency = 1
    trophyIcon.Image = "rbxassetid://6031090990" -- Trophy icon
    trophyIcon.ImageColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    trophyIcon.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0.5, -15)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar
    
    -- Close button corners
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Category buttons container
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Name = "CategoryFrame"
    categoryFrame.Size = UDim2.new(1, -40, 0, 40)
    categoryFrame.Position = UDim2.new(0, 20, 0, 50)
    categoryFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    categoryFrame.BorderSizePixel = 0
    categoryFrame.Parent = mainFrame
    
    -- Category frame corners
    local categoryCorner = Instance.new("UICorner")
    categoryCorner.CornerRadius = UDim.new(0, 8)
    categoryCorner.Parent = categoryFrame
    
    -- Create category buttons
    local categoryList = {"all"}
    for category, _ in pairs(AchievementsMenu.achievementData.definitions or {}) do
        if not table.find(categoryList, category) then
            table.insert(categoryList, category)
        end
    end
    
    -- Create the category buttons
    local buttonWidth = math.min(120, (categoryFrame.Size.X.Offset - 20) / #categoryList)
    
    for i, categoryId in ipairs(categoryList) do
        local button = Instance.new("TextButton")
        button.Name = "Category_" .. categoryId
        button.Size = UDim2.new(0, buttonWidth, 0, 30)
        button.Position = UDim2.new(0, 10 + (i-1) * (buttonWidth + 5), 0.5, -15)
        button.BackgroundColor3 = categoryId == AchievementsMenu.selectedCategory 
                               and Color3.fromRGB(60, 60, 60) 
                               or Color3.fromRGB(45, 45, 45)
        button.BorderSizePixel = 0
        button.Text = categoryId:sub(1,1):upper() .. categoryId:sub(2)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        button.Font = Enum.Font.GothamSemibold
        button.Parent = categoryFrame
        
        -- Add hover effect
        button.MouseEnter:Connect(function()
            if categoryId ~= AchievementsMenu.selectedCategory then
                button.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
            end
        end)
        
        button.MouseLeave:Connect(function()
            if categoryId ~= AchievementsMenu.selectedCategory then
                button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            end
        end)
        
        -- Add click handler
        button.MouseButton1Click:Connect(function()
            AchievementsMenu:selectCategory(categoryId)
        end)
        
        -- Round corners
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- Store reference to color for category
        if CONFIG.categoryColors[categoryId] then
            button:SetAttribute("CategoryColor", CONFIG.categoryColors[categoryId])
        end
    end
    
    -- Show completion stats
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, -40, 0, 40)
    statsFrame.Position = UDim2.new(0, 20, 0, 100)
    statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statsFrame.BackgroundTransparency = 0.5
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = mainFrame
    
    -- Stats frame corners
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsFrame
    
    -- Calculate completion stats
    local totalAchievements = 0
    local completedAchievements = 0
    
    for _, achievement in pairs(AchievementsMenu.achievementData.definitions) do
        totalAchievements = totalAchievements + 1
        if AchievementsMenu.achievementData.unlocked[achievement.id] then
            completedAchievements = completedAchievements + 1
        end
    end
    
    -- Stats label
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(0.4, 0, 1, 0)
    statsLabel.Position = UDim2.new(0, 15, 0, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsLabel.TextSize = 16
    statsLabel.Font = Enum.Font.GothamMedium
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Text = "Achievement Progress:"
    statsLabel.Parent = statsFrame
    
    -- Stats progress bar background
    local statsBarBg = Instance.new("Frame")
    statsBarBg.Name = "StatsBarBg"
    statsBarBg.Size = UDim2.new(0.5, -30, 0, 16)
    statsBarBg.Position = UDim2.new(0.4, 0, 0.5, -8)
    statsBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    statsBarBg.BorderSizePixel = 0
    statsBarBg.Parent = statsFrame
    
    -- Stats bar corners
    local statsBarCorner = Instance.new("UICorner")
    statsBarCorner.CornerRadius = UDim.new(0, 4)
    statsBarCorner.Parent = statsBarBg
    
    -- Stats progress fill
    local completionRatio = totalAchievements > 0 and completedAchievements / totalAchievements or 0
    
    local statsBarFill = Instance.new("Frame")
    statsBarFill.Name = "StatsBarFill"
    statsBarFill.Size = UDim2.new(completionRatio, 0, 1, 0)
    statsBarFill.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
    statsBarFill.BorderSizePixel = 0
    statsBarFill.Parent = statsBarBg
    
    -- Stats fill corners
    local statsBarFillCorner = Instance.new("UICorner")
    statsBarFillCorner.CornerRadius = UDim.new(0, 4)
    statsBarFillCorner.Parent = statsBarFill
    
    -- Stats text
    local statsText = Instance.new("TextLabel")
    statsText.Name = "StatsText"
    statsText.Size = UDim2.new(0.1, 0, 1, 0)
    statsText.Position = UDim2.new(0.9, 0, 0, 0)
    statsText.BackgroundTransparency = 1
    statsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsText.TextSize = 16
    statsText.Font = Enum.Font.GothamSemibold
    statsText.TextXAlignment = Enum.TextXAlignment.Right
    statsText.Text = completedAchievements .. "/" .. totalAchievements
    statsText.Parent = statsFrame
    
    -- Create content frame for achievement cards
    local contentScrollFrame = Instance.new("ScrollingFrame")
    contentScrollFrame.Name = "Content"
    contentScrollFrame.Size = UDim2.new(1, -40, 1, -160)
    contentScrollFrame.Position = UDim2.new(0, 20, 0, 150)
    contentScrollFrame.BackgroundTransparency = 1
    contentScrollFrame.BorderSizePixel = 0
    contentScrollFrame.ScrollBarThickness = 6
    contentScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated based on content
    contentScrollFrame.Parent = mainFrame
    
    -- Add layout for cards
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = contentScrollFrame
    
    -- Status text for no achievements
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -40, 0, 30)
    statusText.Position = UDim2.new(0.5, 0, 0.5, 0)
    statusText.AnchorPoint = Vector2.new(0.5, 0.5)
    statusText.BackgroundTransparency = 1
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.TextSize = 18
    statusText.Font = Enum.Font.GothamMedium
    statusText.Text = "Loading achievements..."
    statusText.Visible = (totalAchievements == 0)
    statusText.Parent = contentScrollFrame
    
    -- Populate with achievement cards
    AchievementsMenu:populateAchievements()
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        UIManager.closeUI("AchievementsMenu")
    end)
    
    -- Make the UI draggable
    UIManager.makeFrameDraggable(mainFrame, titleBar)
    
    return screenGui
end

-- Handle UI population
function AchievementsMenu:populateAchievements()
    local contentFrame = UIManager.getUI("AchievementsMenu")
    if not contentFrame then return end
    contentFrame = contentFrame.MainFrame.Content
    
    -- Clear existing cards
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("AchievementCard_") then
            child:Destroy()
        end
    end
    
    -- Filter achievements by category
    local filteredAchievements = {}
    local selectedCategory = self.selectedCategory
    
    for id, achievement in pairs(self.achievementData.definitions) do
        if selectedCategory == "all" or achievement.category == selectedCategory then
            -- Store ID in the achievement object
            achievement.id = id
            table.insert(filteredAchievements, achievement)
        end
    end
    
    -- Sort achievements based on selected sort option
    table.sort(filteredAchievements, function(a, b)
        if self.selectedSort == "category" then
            if a.category ~= b.category then
                return a.category < b.category
            end
        elseif self.selectedSort == "difficulty" then
            if a.difficulty ~= b.difficulty then
                return a.difficulty > b.difficulty
            end
        elseif self.selectedSort == "progress" then
            local aProgress = self.achievementData.progress[a.id] or 0
            local bProgress = self.achievementData.progress[b.id] or 0
            local aRatio = a.progressMax and (aProgress / a.progressMax) or 0
            local bRatio = b.progressMax and (bProgress / b.progressMax) or 0
            if aRatio ~= bRatio then
                return aRatio > bRatio
            end
        elseif self.selectedSort == "unlocked" then
            local aUnlocked = self.achievementData.unlocked[a.id] or false
            local bUnlocked = self.achievementData.unlocked[b.id] or false
            if aUnlocked ~= bUnlocked then
                return aUnlocked
            end
        end
        
        -- Secondary sort by name
        return a.name < b.name
    end)
    
    -- Find the status text and make it visible if no achievements
    local statusText = contentFrame:FindFirstChild("StatusText")
    if statusText then
        if #filteredAchievements == 0 then
            if selectedCategory == "all" then
                statusText.Text = "No achievements available"
            else
                statusText.Text = "No " .. selectedCategory .. " achievements available"
            end
            statusText.Visible = true
        else
            statusText.Visible = false
        end
    end
    
    -- Create card for each achievement
    for i, achievement in ipairs(filteredAchievements) do
        local isUnlocked = self.achievementData.unlocked[achievement.id] or false
        local progress = self.achievementData.progress[achievement.id] or 0
        
        local card = createAchievementCard(achievement, isUnlocked, progress)
        card.LayoutOrder = i
        card.Parent = contentFrame
    end
    
    -- Update canvas size
    local totalHeight = #filteredAchievements * (CONFIG.cardSize.Y + CONFIG.cardSpacing) + CONFIG.cardSpacing
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Update a specific achievement's progress
function AchievementsMenu:updateAchievementProgress(id, progress, target, unlocked)
    if not id or not self.achievementData.definitions[id] then return end
    
    -- Update data
    self.achievementData.progress[id] = progress
    if unlocked ~= nil then
        self.achievementData.unlocked[id] = unlocked
    end
    
    -- Update UI if open
    local mainUI = LocalPlayer.PlayerGui:FindFirstChild("AchievementsMenu")
    if not mainUI then return end
    
    local contentFrame = mainUI.MainFrame.Content
    
    -- Find the achievement card
    local card = contentFrame:FindFirstChild("AchievementCard_" .. id)
    if not card then 
        -- Refresh all cards if we can't find this specific one
        -- (it might be filtered out by category)
        self:populateAchievements()
        return 
    end
    
    -- Update progress bar
    local progressFrame = card:FindFirstChild("ProgressFrame")
    if progressFrame then
        local progressBg = progressFrame:FindFirstChild("ProgressBg")
        if progressBg then
            local progressFill = progressBg:FindFirstChild("ProgressFill")
            if progressFill then
                -- Calculate new progress
                local progressRatio = 0
                if target and target > 0 then
                    progressRatio = math.min(1, progress / target)
                elseif unlocked then
                    progressRatio = 1
                end
                
                -- Animate progress bar
                TweenService:Create(
                    progressFill,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(progressRatio, 0, 1, 0)}
                ):Play()
            end
        end
        
        -- Update progress text
        local progressText = progressFrame:FindFirstChild("ProgressText")
        if progressText then
            if unlocked then
                progressText.Text = "Completed!"
            elseif progress and target then
                progressText.Text = progress .. "/" .. target
            end
        end
    end
    
    -- Add checkmark if newly unlocked
    if unlocked and not card:FindFirstChild("Checkmark") then
        local checkmark = Instance.new("ImageLabel")
        checkmark.Name = "Checkmark"
        checkmark.Size = UDim2.new(0, 24, 0, 24)
        checkmark.Position = UDim2.new(1, -30, 0, 10)
        checkmark.BackgroundTransparency = 1
        checkmark.Image = "rbxassetid://6031094678" -- Checkmark icon
        checkmark.ImageColor3 = Color3.fromRGB(50, 200, 50) -- Green checkmark
        checkmark.Parent = card
        
        -- Animate the checkmark appearing
        checkmark.ImageTransparency = 1
        TweenService:Create(
            checkmark,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {ImageTransparency = 0}
        ):Play()
        
        -- Remove dim effect from card
        TweenService:Create(
            card,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.1}
        ):Play()
    end
    
    -- Update stats frame
    local statsFrame = mainUI.MainFrame:FindFirstChild("StatsFrame")
    if statsFrame then
        -- Recalculate stats
        local totalAchievements = 0
        local completedAchievements = 0
        
        for id, _ in pairs(self.achievementData.definitions) do
            totalAchievements = totalAchievements + 1
            if self.achievementData.unlocked[id] then
                completedAchievements = completedAchievements + 1
            end
        end
        
        -- Update progress bar
        local statsBarBg = statsFrame:FindFirstChild("StatsBarBg")
        if statsBarBg then
            local statsBarFill = statsBarBg:FindFirstChild("StatsBarFill")
            if statsBarFill then
                local completionRatio = totalAchievements > 0 and completedAchievements / totalAchievements or 0
                
                TweenService:Create(
                    statsBarFill,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(completionRatio, 0, 1, 0)}
                ):Play()
            end
        end
        
        -- Update stats text
        local statsText = statsFrame:FindFirstChild("StatsText")
        if statsText then
            statsText.Text = completedAchievements .. "/" .. totalAchievements
        end
    end
end

-- Switch to a different category
function AchievementsMenu:selectCategory(categoryId)
    if not categoryId or categoryId == self.selectedCategory then return end
    
    -- Update selected category
    self.selectedCategory = categoryId
    
    -- Update UI if open
    local mainUI = LocalPlayer.PlayerGui:FindFirstChild("AchievementsMenu")
    if not mainUI then return end
    
    -- Update button colors
    local categoryFrame = mainUI.MainFrame:FindFirstChild("CategoryFrame")
    if categoryFrame then
        for _, button in ipairs(categoryFrame:GetChildren()) do
            if button:IsA("TextButton") and button.Name:find("Category_") then
                local buttonCategory = button.Name:gsub("Category_", "")
                
                if buttonCategory == categoryId then
                    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                else
                    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                end
            end
        end
    end
    
    -- Repopulate achievements
    self:populateAchievements()
end

-- Handle when UI opens
function AchievementsMenu.show(data)
    log("Showing achievements menu")
    
    -- Store achievements data if provided
    if data then
        if data.definitions then
            AchievementsMenu.achievementData.definitions = data.definitions
        end
        
        if data.unlocked then
            AchievementsMenu.achievementData.unlocked = data.unlocked
        end
        
        if data.progress then
            AchievementsMenu.achievementData.progress = data.progress
        end
    end
    
    -- Request fresh data if not provided
    if not data or not data.definitions then
        ClientEventBridge.fireServerEvent("GetPlayerAchievements")
    end
    
    -- Connect to server events if not already connected
    if not AchievementsMenu.eventConnected then
        -- Handle receiving achievement data
        ClientEventBridge.connectEvent("AchievementDataReceived", function(achievementData)
            AchievementsMenu.achievementData = achievementData or {
                unlocked = {},
                progress = {},
                definitions = {}
            }
            
            -- Update UI if open
            AchievementsMenu:populateAchievements()
        end)
        
        -- Handle achievement progress updates
        ClientEventBridge.connectEvent("AchievementProgressUpdated", function(id, progress, target)
            AchievementsMenu:updateAchievementProgress(id, progress, target)
        end)
        
        -- Handle achievement unlocked
        ClientEventBridge.connectEvent("AchievementUnlocked", function(id, achievementData)
            if achievementData then
                AchievementsMenu.achievementData.definitions[id] = achievementData
            end
            AchievementsMenu:updateAchievementProgress(id, achievementData.progressMax, achievementData.progressMax, true)
        end)
        
        AchievementsMenu.eventConnected = true
    end
    
    return true
end

-- Handle when the UI closes
function AchievementsMenu.close(ui)
    log("Closing achievements menu")
    
    -- Destroy the UI
    if ui and ui.Parent then
        ui:Destroy()
    end
    
    return true
end

return AchievementsMenu