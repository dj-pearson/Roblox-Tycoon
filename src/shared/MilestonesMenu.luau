-- MilestonesMenu.luau
-- UI Module for displaying player milestones and achievements
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
    milestoneTypes = {
        revenue = {
            name = "Revenue Milestones",
            color = Color3.fromRGB(50, 200, 100), -- Green
            icon = "rbxassetid://6035078892" -- Money icon
        },
        equipment = {
            name = "Equipment Milestones",
            color = Color3.fromRGB(50, 120, 200), -- Blue
            icon = "rbxassetid://6035047391" -- Dumbbell icon
        },
        members = {
            name = "Membership Milestones",
            color = Color3.fromRGB(200, 120, 50), -- Orange
            icon = "rbxassetid://6026657478" -- Person icon
        },
        time = {
            name = "Time Milestones",
            color = Color3.fromRGB(150, 50, 200), -- Purple
            icon = "rbxassetid://6031225816" -- Clock icon
        },
        special = {
            name = "Special Achievements",
            color = Color3.fromRGB(200, 180, 30), -- Gold
            icon = "rbxassetid://6031090999" -- Star icon
        }
    },
    defaultCategory = "all"
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[MilestonesMenu]", ...)
    end
end

-- Module table
local MilestonesMenu = {}

-- Cached data
local allMilestones = {}
local unlockedMilestones = {}
local selectedCategory = CONFIG.defaultCategory

-- Helper function to create a milestone card
local function createMilestoneCard(milestone)
    -- Create card frame
    local card = Instance.new("Frame")
    card.Name = "MilestoneCard_" .. milestone.id
    card.Size = UDim2.new(1, -20, 0, 100)
    card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    
    -- Apply rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    -- Get milestone type color and icon
    local typeInfo = CONFIG.milestoneTypes[milestone.type] or CONFIG.milestoneTypes.special
    local color = typeInfo.color
    local icon = typeInfo.icon
    
    -- Add color accent at left
    local colorBar = Instance.new("Frame")
    colorBar.Name = "ColorBar"
    colorBar.Size = UDim2.new(0, 6, 1, 0)
    colorBar.Position = UDim2.new(0, 0, 0, 0)
    colorBar.BackgroundColor3 = color
    colorBar.BorderSizePixel = 0
    colorBar.Parent = card
    
    -- Round corners of color bar
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 8)
    barCorner.Parent = colorBar
    
    -- Fix right corners
    local rightFix = Instance.new("Frame")
    rightFix.Name = "RightFix"
    rightFix.Size = UDim2.new(0.5, 0, 1, 0)
    rightFix.Position = UDim2.new(0.5, 0, 0, 0)
    rightFix.BackgroundColor3 = colorBar.BackgroundColor3
    rightFix.BorderSizePixel = 0
    rightFix.ZIndex = colorBar.ZIndex - 1
    rightFix.Parent = colorBar
    
    -- Add milestone icon
    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "Icon"
    iconImage.Size = UDim2.new(0, 40, 0, 40)
    iconImage.Position = UDim2.new(0, 20, 0, 10)
    iconImage.BackgroundTransparency = 1
    iconImage.Image = icon
    iconImage.Parent = card
    
    -- Add milestone title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -80, 0, 24)
    title.Position = UDim2.new(0, 70, 0, 10)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextWrapped = true
    title.Text = milestone.name
    title.Parent = card
    
    -- Add milestone description
    local description = Instance.new("TextLabel")
    description.Name = "Description"
    description.Size = UDim2.new(1, -80, 0, 36)
    description.Position = UDim2.new(0, 70, 0, 34)
    description.BackgroundTransparency = 1
    description.TextColor3 = Color3.fromRGB(200, 200, 200)
    description.TextSize = 14
    description.Font = Enum.Font.Gotham
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.TextWrapped = true
    description.Text = milestone.description
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
    local progress = 0
    if milestone.progress and milestone.target and milestone.target > 0 then
        progress = math.min(1, milestone.progress / milestone.target)
    elseif milestone.unlocked then
        progress = 1
    end
    
    -- Add progress bar fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(progress, 0, 1, 0)
    progressFill.BackgroundColor3 = color
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
    if milestone.unlocked then
        progressText.Text = "Completed!"
    elseif milestone.progress and milestone.target then
        progressText.Text = milestone.progress .. "/" .. milestone.target
    else
        progressText.Text = "0%"
    end
    
    progressText.Parent = progressFrame
    
    -- Add reward section if milestone has rewards
    if milestone.rewards and #milestone.rewards > 0 then
        -- Add reward label
        local rewardLabel = Instance.new("TextLabel")
        rewardLabel.Name = "RewardLabel"
        rewardLabel.Size = UDim2.new(0, 60, 0, 16)
        rewardLabel.Position = UDim2.new(1, -140, 0, 10)
        rewardLabel.BackgroundTransparency = 1
        rewardLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
        rewardLabel.TextSize = 12
        rewardLabel.Font = Enum.Font.GothamBold
        rewardLabel.TextXAlignment = Enum.TextXAlignment.Right
        rewardLabel.Text = "REWARD:"
        rewardLabel.Parent = card
        
        -- Add reward value
        local rewardValue = Instance.new("TextLabel")
        rewardValue.Name = "RewardValue"
        rewardValue.Size = UDim2.new(0, 70, 0, 20)
        rewardValue.Position = UDim2.new(1, -75, 0, 8)
        rewardValue.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        rewardValue.BackgroundTransparency = 0.5
        rewardValue.TextColor3 = Color3.fromRGB(255, 220, 100)
        rewardValue.TextSize = 14
        rewardValue.Font = Enum.Font.GothamBold
        rewardValue.TextXAlignment = Enum.TextXAlignment.Center
        
        -- Format rewards text
        local rewardText = ""
        for i, reward in ipairs(milestone.rewards) do
            if reward.type == "money" then
                rewardText = "$" .. reward.amount
            elseif reward.type == "item" then
                rewardText = reward.name
            else
                rewardText = reward.name or "Special"
            end
            break -- Just show first reward for now
        end
        
        rewardValue.Text = rewardText
        rewardValue.Parent = card
        
        -- Round corners of reward value
        local rewardCorner = Instance.new("UICorner")
        rewardCorner.CornerRadius = UDim.new(0, 4)
        rewardCorner.Parent = rewardValue
    end
    
    -- Add highlight if unlocked
    if milestone.unlocked then
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

-- Create the milestones menu UI
function MilestonesMenu.create(data)
    log("Creating milestones menu")
    
    -- Store milestones data if provided
    if data then
        if data.milestones then
            allMilestones = data.milestones
        end
        
        if data.unlocked then
            unlockedMilestones = data.unlocked
        end
    end
    
    -- Update unlocked status in allMilestones
    for id, milestone in pairs(allMilestones) do
        milestone.unlocked = unlockedMilestones[id] == true
    end
    
    -- Create the ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MilestonesMenu"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    -- Create the main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 600)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleBar.BackgroundTransparency = 0.1
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Add rounded corners to title bar
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners of title bar
    local bottomFix = Instance.new("Frame")
    bottomFix.Name = "BottomFix"
    bottomFix.Size = UDim2.new(1, 0, 0.5, 0)
    bottomFix.Position = UDim2.new(0, 0, 0.5, 0)
    bottomFix.BackgroundColor3 = titleBar.BackgroundColor3
    bottomFix.BackgroundTransparency = titleBar.BackgroundTransparency
    bottomFix.BorderSizePixel = 0
    bottomFix.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 24
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Text = "Gym Milestones & Achievements"
    titleText.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 36, 0, 36)
    closeButton.Position = UDim2.new(1, -18, 0.5, 0)
    closeButton.AnchorPoint = Vector2.new(1, 0.5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    -- Add rounded corners to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0.5, 0)
    closeCorner.Parent = closeButton
    
    -- Category filter buttons
    local categoryBar = Instance.new("Frame")
    categoryBar.Name = "CategoryBar"
    categoryBar.Size = UDim2.new(1, -40, 0, 40)
    categoryBar.Position = UDim2.new(0, 20, 0, 60)
    categoryBar.BackgroundTransparency = 1
    categoryBar.Parent = mainFrame
    
    -- Make a list of categories
    local categories = {
        {id = "all", name = "All Milestones"}
    }
    
    -- Add each milestone type as a category
    for typeId, typeInfo in pairs(CONFIG.milestoneTypes) do
        table.insert(categories, {
            id = typeId,
            name = typeInfo.name,
            color = typeInfo.color
        })
    end
    
    -- Create category buttons
    local buttonWidth = 1 / (#categories + 0.5) -- Add some padding
    
    for i, category in ipairs(categories) do
        -- Create button
        local button = Instance.new("TextButton")
        button.Name = category.id .. "Button"
        button.Size = UDim2.new(buttonWidth, -10, 1, -10)
        button.Position = UDim2.new(buttonWidth * (i-1), 5, 0, 5)
        
        -- Selected state
        if category.id == selectedCategory then
            button.BackgroundColor3 = category.color or Color3.fromRGB(80, 80, 180)
        else
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 16
        button.Font = Enum.Font.GothamMedium
        button.Text = category.name
        button.BorderSizePixel = 0
        
        -- Add rounded corners
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- Connect button
        button.MouseButton1Click:Connect(function()
            MilestonesMenu:filterByCategory(category.id)
        end)
        
        button.Parent = categoryBar
        
        -- Store category color for later
        button:SetAttribute("CategoryColor", category.color)
    end
    
    -- Show completion stats
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, -40, 0, 40)
    statsFrame.Position = UDim2.new(0, 20, 0, 110)
    statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statsFrame.BackgroundTransparency = 0.5
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = mainFrame
    
    -- Add rounded corners
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsFrame
    
    -- Calculate completion stats
    local totalMilestones = 0
    local completedMilestones = 0
    
    for _, milestone in pairs(allMilestones) do
        totalMilestones = totalMilestones + 1
        if milestone.unlocked then
            completedMilestones = completedMilestones + 1
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
    statsLabel.Text = "Milestone Progress:"
    statsLabel.Parent = statsFrame
    
    -- Stats progress bar background
    local statsBarBg = Instance.new("Frame")
    statsBarBg.Name = "StatsBarBg"
    statsBarBg.Size = UDim2.new(0.4, 0, 0.4, 0)
    statsBarBg.Position = UDim2.new(0.4, 15, 0.5, 0)
    statsBarBg.AnchorPoint = Vector2.new(0, 0.5)
    statsBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    statsBarBg.BorderSizePixel = 0
    statsBarBg.Parent = statsFrame
    
    -- Add rounded corners
    local statsBarBgCorner = Instance.new("UICorner")
    statsBarBgCorner.CornerRadius = UDim.new(0, 4)
    statsBarBgCorner.Parent = statsBarBg
    
    -- Stats progress bar fill
    local completionRatio = totalMilestones > 0 and (completedMilestones / totalMilestones) or 0
    
    local statsBarFill = Instance.new("Frame")
    statsBarFill.Name = "StatsBarFill"
    statsBarFill.Size = UDim2.new(completionRatio, 0, 1, 0)
    statsBarFill.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    statsBarFill.BorderSizePixel = 0
    statsBarFill.Parent = statsBarBg
    
    -- Add rounded corners
    local statsBarFillCorner = Instance.new("UICorner")
    statsBarFillCorner.CornerRadius = UDim.new(0, 4)
    statsBarFillCorner.Parent = statsBarFill
    
    -- Stats text
    local statsText = Instance.new("TextLabel")
    statsText.Name = "StatsText"
    statsText.Size = UDim2.new(0.2, -30, 1, 0)
    statsText.Position = UDim2.new(0.8, 15, 0, 0)
    statsText.BackgroundTransparency = 1
    statsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsText.TextSize = 16
    statsText.Font = Enum.Font.GothamBold
    statsText.TextXAlignment = Enum.TextXAlignment.Right
    statsText.Text = completedMilestones .. "/" .. totalMilestones
    statsText.Parent = statsFrame
    
    -- Create content frame for milestone cards
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -40, 1, -160)
    contentFrame.Position = UDim2.new(0, 20, 0, 160)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 6
    contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set automatically
    contentFrame.Parent = mainFrame
    
    -- Layout for cards
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = contentFrame
    
    -- Status text for no milestones
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -40, 0, 30)
    statusText.Position = UDim2.new(0.5, 0, 0.5, 0)
    statusText.AnchorPoint = Vector2.new(0.5, 0.5)
    statusText.BackgroundTransparency = 1
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.TextSize = 18
    statusText.Font = Enum.Font.GothamMedium
    statusText.Text = "Loading milestones..."
    statusText.Visible = totalMilestones == 0
    statusText.Parent = contentFrame
    
    -- Populate with milestone cards
    MilestonesMenu:populateMilestones(allMilestones)
    
    -- Connect close button
    closeButton.MouseButton1Click:Connect(function()
        UIManager.closeUI("MilestonesMenu")
    end)
    
    -- Make the UI draggable
    UIManager.makeFrameDraggable(mainFrame, titleBar)
    
    return screenGui
end

-- Populate the UI with milestone cards
function MilestonesMenu:populateMilestones(milestones)
    if not milestones or not next(milestones) then
        log("No milestones to populate")
        return
    end
    
    -- Convert milestones table to array for sorting
    local milestoneArray = {}
    for id, milestone in pairs(milestones) do
        milestone.id = id -- Store ID in the milestone object
        table.insert(milestoneArray, milestone)
    end
    
    -- Sort milestones: completed at the bottom, then by progress percentage
    table.sort(milestoneArray, function(a, b)
        -- If one is unlocked and the other isn't, unlocked goes after
        if a.unlocked ~= b.unlocked then
            return not a.unlocked
        end
        
        -- If both have progress, sort by progress percentage
        if a.progress and a.target and b.progress and b.target then
            local aProgress = a.progress / a.target
            local bProgress = b.progress / b.target
            return aProgress > bProgress
        end
        
        -- Default sort by type then name
        if a.type == b.type then
            return a.name < b.name
        end
        
        return a.type < b.type
    end)
    
    -- Get the content frame
    local mainUI = LocalPlayer.PlayerGui:FindFirstChild("MilestonesMenu")
    if not mainUI then return end
    
    local contentFrame = mainUI.MainFrame.Content
    if not contentFrame then return end
    
    -- Clear existing status text
    local statusText = contentFrame:FindFirstChild("StatusText")
    if statusText then
        statusText.Visible = false
    end
    
    -- Clear existing cards
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("MilestoneCard_") then
            child:Destroy()
        end
    end
    
    -- Create cards for each milestone
    for i, milestone in ipairs(milestoneArray) do
        -- Skip if filtering by category and this isn't the right category
        if selectedCategory ~= "all" and milestone.type ~= selectedCategory then
            continue
        end
        
        local card = createMilestoneCard(milestone)
        card.LayoutOrder = i -- Order by array index
        card.Parent = contentFrame
    end
end

-- Filter milestones by category
function MilestonesMenu:filterByCategory(category)
    -- Update selected category
    selectedCategory = category
    
    local mainUI = LocalPlayer.PlayerGui:FindFirstChild("MilestonesMenu")
    if not mainUI then return end
    
    -- Update category buttons
    local categoryBar = mainUI.MainFrame.CategoryBar
    for _, button in ipairs(categoryBar:GetChildren()) do
        if button:IsA("TextButton") then
            if button.Name == category .. "Button" then
                -- Get category color or use default
                local categoryColor = button:GetAttribute("CategoryColor")
                button.BackgroundColor3 = categoryColor or Color3.fromRGB(80, 80, 180)
            else
                button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end
    end
    
    -- Re-populate with filtered milestones
    self:populateMilestones(allMilestones)
    
    -- Update status text
    local contentFrame = mainUI.MainFrame.Content
    if not contentFrame then return end
    
    local visibleCount = 0
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("MilestoneCard_") then
            visibleCount = visibleCount + 1
        end
    end
    
    local statusText = contentFrame:FindFirstChild("StatusText")
    if statusText then
        if visibleCount == 0 then
            if category == "all" then
                statusText.Text = "No milestones available"
            else
                statusText.Text = "No " .. category .. " milestones available"
            end
            statusText.Visible = true
        else
            statusText.Visible = false
        end
    end
end

-- Update a specific milestone's progress
function MilestonesMenu:updateMilestoneProgress(id, progress, target, unlocked)
    if not id or not allMilestones[id] then return end
    
    -- Update data
    allMilestones[id].progress = progress
    if target then allMilestones[id].target = target end
    if unlocked ~= nil then 
        allMilestones[id].unlocked = unlocked
        unlockedMilestones[id] = unlocked
    end
    
    -- Update UI if open
    local mainUI = LocalPlayer.PlayerGui:FindFirstChild("MilestonesMenu")
    if not mainUI then return end
    
    local contentFrame = mainUI.MainFrame.Content
    if not contentFrame then return end
    
    -- Find the milestone card
    local card = contentFrame:FindFirstChild("MilestoneCard_" .. id)
    if not card then 
        -- Refresh all cards if we can't find this specific one
        -- (it might be filtered out by category)
        self:populateMilestones(allMilestones)
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
    end
    
    -- Update stats frame
    local statsFrame = mainUI.MainFrame:FindFirstChild("StatsFrame")
    if statsFrame then
        -- Recalculate stats
        local totalMilestones = 0
        local completedMilestones = 0
        
        for _, milestone in pairs(allMilestones) do
            totalMilestones = totalMilestones + 1
            if milestone.unlocked then
                completedMilestones = completedMilestones + 1
            end
        end
        
        -- Update stats text
        local statsText = statsFrame:FindFirstChild("StatsText")
        if statsText then
            statsText.Text = completedMilestones .. "/" .. totalMilestones
        end
        
        -- Update progress bar
        local statsBarBg = statsFrame:FindFirstChild("StatsBarBg")
        if statsBarBg then
            local statsBarFill = statsBarBg:FindFirstChild("StatsBarFill")
            if statsBarFill then
                local completionRatio = totalMilestones > 0 and (completedMilestones / totalMilestones) or 0
                
                TweenService:Create(
                    statsBarFill,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = UDim2.new(completionRatio, 0, 1, 0)}
                ):Play()
            end
        end
    end
end

-- Handle when the UI opens
function MilestonesMenu.open(ui, data)
    log("Opening milestones menu")
    
    -- Request fresh data if not provided
    if not data or not data.milestones then
        ClientEventBridge.fireServerEvent("GetPlayerMilestones")
    end
    
    -- Connect to server events if not already connected
    if not MilestonesMenu.eventConnected then
        -- Handle receiving milestone data
        ClientEventBridge.connectEvent("MilestoneDataReceived", function(milestonesData, unlockedData)
            allMilestones = milestonesData or {}
            unlockedMilestones = unlockedData or {}
            
            -- Update UI if open
            MilestonesMenu:populateMilestones(allMilestones)
        end)
        
        -- Handle milestone progress updates
        ClientEventBridge.connectEvent("MilestoneProgressUpdated", function(id, progress, target, unlocked)
            MilestonesMenu:updateMilestoneProgress(id, progress, target, unlocked)
        end)
        
        -- Handle milestone unlocked
        ClientEventBridge.connectEvent("MilestoneUnlocked", function(id, milestoneData)
            if milestoneData then
                allMilestones[id] = milestoneData
            end
            MilestonesMenu:updateMilestoneProgress(id, milestoneData and milestoneData.target or 100, milestoneData and milestoneData.target or 100, true)
        end)
        
        MilestonesMenu.eventConnected = true
    end
    
    return true
end

-- Handle when the UI closes
function MilestonesMenu.close(ui)
    log("Closing milestones menu")
    
    -- Destroy the UI
    if ui and ui.Parent then
        ui:Destroy()
    end
    
    return true
end

return MilestonesMenu