-- StaffManagementUI.luau
-- UI module for managing gym staff
-- Created: April 2025

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIComponent = require(script.Parent.UIComponent)
local UIStyle = require(script.Parent.UIStyle)

local StaffManagementUI = setmetatable({}, {__index = UIComponent})
StaffManagementUI.__index = StaffManagementUI

-- Constants
local STAFF_TYPES = {
    "Trainer",
    "Receptionist",
    "Cleaner",
    "Manager",
    "Maintenance"
}

-- Create a new StaffManagementUI instance
function StaffManagementUI.new(props)
    props = props or {}
    props.name = props.name or "StaffManagementUI"
    
    local self = setmetatable(UIComponent.new(props), StaffManagementUI)
    
    -- Custom properties
    self.staffData = props.staffData or {}
    self.selectedStaffId = nil
    self.filterCategory = "All"
    
    -- State for pagination
    self.currentPage = 1
    self.itemsPerPage = 6
    
    return self
end

-- Build the UI structure
function StaffManagementUI:build()
    -- Main container styling
    self.container.BackgroundColor3 = UIStyle.colors.backgroundLight
    
    -- Create UI corner for the main container
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    corner.Parent = self.container
    
    -- Create title bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, 50)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = UIStyle.colors.primary
    self.titleBar.BorderSizePixel = 0
    self.titleBar.Parent = self.container
    
    -- Title bar corner
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    titleCorner.Parent = self.titleBar
    
    -- Only round the top corners of the title bar
    local titleCornerFix = Instance.new("Frame")
    titleCornerFix.Name = "CornerFix"
    titleCornerFix.Size = UDim2.new(1, 0, 0.5, 0)
    titleCornerFix.Position = UDim2.new(0, 0, 0.5, 0)
    titleCornerFix.BackgroundColor3 = UIStyle.colors.primary
    titleCornerFix.BorderSizePixel = 0
    titleCornerFix.Parent = self.titleBar
    
    -- Title text
    self.titleText = UIStyle.createText({
        name = "TitleText",
        text = "Staff Management",
        style = "titleMedium",
        size = UDim2.new(1, -20, 1, 0),
        position = UDim2.new(0, 15, 0, 0),
        parent = self.titleBar
    })
    
    -- Close button
    self.closeButton = Instance.new("TextButton")
    self.closeButton.Name = "CloseButton"
    self.closeButton.Size = UDim2.new(0, 40, 0, 40)
    self.closeButton.Position = UDim2.new(1, -45, 0, 5)
    self.closeButton.BackgroundColor3 = UIStyle.colors.primaryDark
    self.closeButton.Text = "X"
    self.closeButton.TextColor3 = UIStyle.colors.textPrimary
    self.closeButton.Font = UIStyle.fonts.titleSmall.Font
    self.closeButton.TextSize = UIStyle.fonts.titleSmall.Size
    self.closeButton.BorderSizePixel = 0
    self.closeButton.Parent = self.titleBar
    
    -- Close button corner
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    closeCorner.Parent = self.closeButton
    
    -- Content container
    self.content = Instance.new("Frame")
    self.content.Name = "Content"
    self.content.Size = UDim2.new(1, 0, 1, -50)
    self.content.Position = UDim2.new(0, 0, 0, 50)
    self.content.BackgroundTransparency = 1
    self.content.Parent = self.container
    
    -- Create tab buttons container
    self.tabButtons = Instance.new("Frame")
    self.tabButtons.Name = "TabButtons"
    self.tabButtons.Size = UDim2.new(1, -20, 0, 40)
    self.tabButtons.Position = UDim2.new(0, 10, 0, 10)
    self.tabButtons.BackgroundTransparency = 1
    self.tabButtons.Parent = self.content
    
    -- Create tab layout
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = self.tabButtons
    
    -- Create tabs
    self:createTab("Overview", 1)
    self:createTab("Hire Staff", 2)
    self:createTab("Schedule", 3)
    self:createTab("Training", 4)
    self:createTab("Performance", 5)
    
    -- Tab content container
    self.tabContent = Instance.new("Frame")
    self.tabContent.Name = "TabContent"
    self.tabContent.Size = UDim2.new(1, -20, 1, -60)
    self.tabContent.Position = UDim2.new(0, 10, 0, 60)
    self.tabContent.BackgroundTransparency = 1
    self.tabContent.Parent = self.content
    
    -- Create tab content frames
    self.overviewTab = self:createTabContent("Overview")
    self.hireStaffTab = self:createTabContent("HireStaff")
    self.scheduleTab = self:createTabContent("Schedule")
    self.trainingTab = self:createTabContent("Training")
    self.performanceTab = self:createTabContent("Performance")
    
    -- Build the content for each tab
    self:buildOverviewTab()
    self:buildHireStaffTab()
    self:buildScheduleTab()
    self:buildTrainingTab()
    self:buildPerformanceTab()
    
    -- Show the overview tab by default
    self:showTab("Overview")
    
    -- Setup close button callback
    self.closeButton.MouseButton1Click:Connect(function()
        self:hide(true)
    end)
end

-- Create a tab button
function StaffManagementUI:createTab(name, order)
    local tab = Instance.new("TextButton")
    tab.Name = name.."Tab"
    tab.Text = name
    tab.Size = UDim2.new(0, 100, 1, 0)
    tab.BackgroundColor3 = UIStyle.colors.buttonDefault
    tab.TextColor3 = UIStyle.colors.textPrimary
    tab.Font = UIStyle.fonts.button.Font
    tab.TextSize = UIStyle.fonts.button.Size
    tab.LayoutOrder = order
    tab.BorderSizePixel = 0
    tab.Parent = self.tabButtons
    
    -- Tab corner
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    tabCorner.Parent = tab
    
    -- Tab click handler
    tab.MouseButton1Click:Connect(function()
        self:showTab(name)
    end)
    
    return tab
end

-- Create content container for a tab
function StaffManagementUI:createTabContent(name)
    local content = Instance.new("ScrollingFrame")
    content.Name = name
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.Visible = false
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.CanvasSize = UDim2.new(0, 0, 2, 0) -- Will be updated based on content
    content.Parent = self.tabContent
    
    -- Content padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UIStyle.layout.paddingMedium
    padding.PaddingRight = UIStyle.layout.paddingMedium
    padding.PaddingTop = UIStyle.layout.paddingMedium
    padding.PaddingBottom = UIStyle.layout.paddingMedium
    padding.Parent = content
    
    -- Auto layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = content
    
    return content
end

-- Show a specific tab
function StaffManagementUI:showTab(tabName)
    -- Hide all tabs
    for _, child in pairs(self.tabContent:GetChildren()) do
        if child:IsA("ScrollingFrame") then
            child.Visible = false
        end
    end
    
    -- Reset all tab button styling
    for _, child in pairs(self.tabButtons:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = UIStyle.colors.buttonDefault
            child.TextColor3 = UIStyle.colors.textPrimary
        end
    end
    
    -- Show the selected tab
    local selectedTab = self.tabContent:FindFirstChild(tabName)
    if selectedTab then
        selectedTab.Visible = true
    end
    
    -- Highlight the selected tab button
    local selectedButton = self.tabButtons:FindFirstChild(tabName.."Tab")
    if selectedButton then
        selectedButton.BackgroundColor3 = UIStyle.colors.primary
        selectedButton.TextColor3 = UIStyle.colors.textPrimary
    end
    
    -- Trigger tab changed event
    self:trigger("tabChanged", tabName)
end

-- Build the Overview tab content
function StaffManagementUI:buildOverviewTab()
    local overview = self.overviewTab
    
    -- Stats container
    local statsContainer = Instance.new("Frame")
    statsContainer.Name = "StatsContainer"
    statsContainer.Size = UDim2.new(1, 0, 0, 100)
    statsContainer.BackgroundColor3 = UIStyle.colors.backgroundDark
    statsContainer.BorderSizePixel = 0
    statsContainer.LayoutOrder = 1
    statsContainer.Parent = overview
    
    -- Stats container corner
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    statsCorner.Parent = statsContainer
    
    -- Create stat items
    self:createStatItem(statsContainer, "Total Staff", "0", UDim2.new(0, 10, 0, 10))
    self:createStatItem(statsContainer, "Staff Cost", "$0", UDim2.new(0.25, 10, 0, 10))
    self:createStatItem(statsContainer, "Avg. Performance", "0%", UDim2.new(0.5, 10, 0, 10))
    self:createStatItem(statsContainer, "Staff Happiness", "0%", UDim2.new(0.75, 10, 0, 10))
    
    -- Staff list container
    local staffListTitle = UIStyle.createText({
        name = "StaffListTitle",
        text = "Current Staff",
        style = "titleSmall",
        size = UDim2.new(1, 0, 0, 30),
        position = UDim2.new(0, 0, 0, 0),
        parent = overview,
        layoutOrder = 2
    })
    staffListTitle.LayoutOrder = 2
    
    -- Filter container
    local filterContainer = Instance.new("Frame")
    filterContainer.Name = "FilterContainer"
    filterContainer.Size = UDim2.new(1, 0, 0, 40)
    filterContainer.BackgroundTransparency = 1
    filterContainer.LayoutOrder = 3
    filterContainer.Parent = overview
    
    -- Filter label
    local filterLabel = UIStyle.createText({
        name = "FilterLabel",
        text = "Filter by:",
        style = "label",
        size = UDim2.new(0, 80, 1, 0),
        position = UDim2.new(0, 0, 0, 0),
        parent = filterContainer
    })
    
    -- Create filter dropdown
    local filterDropdown = Instance.new("TextButton")
    filterDropdown.Name = "FilterDropdown"
    filterDropdown.Size = UDim2.new(0, 150, 0, 30)
    filterDropdown.Position = UDim2.new(0, 85, 0, 5)
    filterDropdown.BackgroundColor3 = UIStyle.colors.backgroundDark
    filterDropdown.TextColor3 = UIStyle.colors.textPrimary
    filterDropdown.Text = "All"
    filterDropdown.Font = UIStyle.fonts.bodyMedium.Font
    filterDropdown.TextSize = UIStyle.fonts.bodyMedium.Size
    filterDropdown.BorderSizePixel = 0
    filterDropdown.Parent = filterContainer
    
    -- Dropdown corner
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    dropdownCorner.Parent = filterDropdown
    
    -- Staff list frame
    local staffListFrame = Instance.new("Frame")
    staffListFrame.Name = "StaffListFrame"
    staffListFrame.Size = UDim2.new(1, 0, 0, 400)
    staffListFrame.BackgroundColor3 = UIStyle.colors.backgroundDark
    staffListFrame.BorderSizePixel = 0
    staffListFrame.LayoutOrder = 4
    staffListFrame.Parent = overview
    
    -- Staff list corners
    local staffListCorner = Instance.new("UICorner")
    staffListCorner.CornerRadius = UIStyle.layout.cornerRadiusMedium
    staffListCorner.Parent = staffListFrame
    
    -- Staff list container
    self.staffList = Instance.new("ScrollingFrame")
    self.staffList.Name = "StaffList"
    self.staffList.Size = UDim2.new(1, -20, 1, -20)
    self.staffList.Position = UDim2.new(0, 10, 0, 10)
    self.staffList.BackgroundTransparency = 1
    self.staffList.BorderSizePixel = 0
    self.staffList.ScrollBarThickness = 4
    self.staffList.ScrollingDirection = Enum.ScrollingDirection.Y
    self.staffList.CanvasSize = UDim2.new(0, 0, 0, 0) -- Updated based on content
    self.staffList.Parent = staffListFrame
    
    -- Staff list layout
    local staffListLayout = Instance.new("UIListLayout")
    staffListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    staffListLayout.Padding = UDim.new(0, 10)
    staffListLayout.Parent = self.staffList
    
    -- Create placeholder staff items (to be replaced with real data)
    self:createStaffItem("Manager Mike", "Manager", 95, 1)
    self:createStaffItem("Trainer Tim", "Trainer", 87, 2)
    self:createStaffItem("Cleaner Clara", "Cleaner", 76, 3)
    
    -- Pagination container
    local paginationContainer = Instance.new("Frame")
    paginationContainer.Name = "PaginationContainer"
    paginationContainer.Size = UDim2.new(1, 0, 0, 40)
    paginationContainer.BackgroundTransparency = 1
    paginationContainer.LayoutOrder = 5
    paginationContainer.Parent = overview
    
    -- Previous page button
    local prevButton = Instance.new("TextButton")
    prevButton.Name = "PrevButton"
    prevButton.Size = UDim2.new(0, 100, 0, 30)
    prevButton.Position = UDim2.new(0, 0, 0, 5)
    prevButton.BackgroundColor3 = UIStyle.colors.buttonDefault
    prevButton.TextColor3 = UIStyle.colors.textPrimary
    prevButton.Text = "< Previous"
    prevButton.Font = UIStyle.fonts.button.Font
    prevButton.TextSize = UIStyle.fonts.button.Size
    prevButton.BorderSizePixel = 0
    prevButton.Parent = paginationContainer
    
    -- Previous button corner
    local prevButtonCorner = Instance.new("UICorner")
    prevButtonCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    prevButtonCorner.Parent = prevButton
    
    -- Page info
    local pageInfo = UIStyle.createText({
        name = "PageInfo",
        text = "Page 1 of 1",
        style = "bodyMedium",
        size = UDim2.new(0, 100, 1, 0),
        position = UDim2.new(0.5, -50, 0, 0),
        xAlign = Enum.TextXAlignment.Center,
        parent = paginationContainer
    })
    
    -- Next page button
    local nextButton = Instance.new("TextButton")
    nextButton.Name = "NextButton"
    nextButton.Size = UDim2.new(0, 100, 0, 30)
    nextButton.Position = UDim2.new(1, -100, 0, 5)
    nextButton.BackgroundColor3 = UIStyle.colors.buttonDefault
    nextButton.TextColor3 = UIStyle.colors.textPrimary
    nextButton.Text = "Next >"
    nextButton.Font = UIStyle.fonts.button.Font
    nextButton.TextSize = UIStyle.fonts.button.Size
    nextButton.BorderSizePixel = 0
    nextButton.Parent = paginationContainer
    
    -- Next button corner
    local nextButtonCorner = Instance.new("UICorner")
    nextButtonCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    nextButtonCorner.Parent = nextButton
end

-- Create a stat display item
function StaffManagementUI:createStatItem(parent, label, value, position)
    local statItem = Instance.new("Frame")
    statItem.Name = label:gsub(" ", "")
    statItem.Size = UDim2.new(0.25, -20, 0, 80)
    statItem.Position = position
    statItem.BackgroundTransparency = 1
    statItem.Parent = parent
    
    -- Stat label
    local statLabel = UIStyle.createText({
        name = "Label",
        text = label,
        style = "label",
        size = UDim2.new(1, 0, 0, 20),
        position = UDim2.new(0, 0, 0, 0),
        parent = statItem
    })
    
    -- Stat value
    local statValue = UIStyle.createText({
        name = "Value",
        text = value,
        style = "titleSmall",
        size = UDim2.new(1, 0, 0, 40),
        position = UDim2.new(0, 0, 0, 30),
        parent = statItem
    })
    
    return statItem
end

-- Create a staff item in the list
function StaffManagementUI:createStaffItem(name, role, performance, order)
    local staffItem = Instance.new("Frame")
    staffItem.Name = name:gsub(" ", "")
    staffItem.Size = UDim2.new(1, 0, 0, 70)
    staffItem.BackgroundColor3 = UIStyle.colors.background
    staffItem.BorderSizePixel = 0
    staffItem.LayoutOrder = order
    staffItem.Parent = self.staffList
    
    -- Staff item corner
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    itemCorner.Parent = staffItem
    
    -- Staff avatar (placeholder)
    local avatarFrame = Instance.new("Frame")
    avatarFrame.Name = "AvatarFrame"
    avatarFrame.Size = UDim2.new(0, 50, 0, 50)
    avatarFrame.Position = UDim2.new(0, 10, 0, 10)
    avatarFrame.BackgroundColor3 = UIStyle.colors.primaryLight
    avatarFrame.BorderSizePixel = 0
    avatarFrame.Parent = staffItem
    
    -- Avatar corner
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0) -- Circle
    avatarCorner.Parent = avatarFrame
    
    -- Staff name
    local staffName = UIStyle.createText({
        name = "StaffName",
        text = name,
        style = "bodyLarge",
        size = UDim2.new(0.4, -70, 0, 25),
        position = UDim2.new(0, 70, 0, 10),
        parent = staffItem
    })
    
    -- Staff role
    local staffRole = UIStyle.createText({
        name = "StaffRole",
        text = role,
        style = "label",
        size = UDim2.new(0.4, -70, 0, 20),
        position = UDim2.new(0, 70, 0, 35),
        color = UIStyle.colors.textSecondary,
        parent = staffItem
    })
    
    -- Performance bar background
    local perfBarBg = Instance.new("Frame")
    perfBarBg.Name = "PerfBarBg"
    perfBarBg.Size = UDim2.new(0.2, 0, 0, 20)
    perfBarBg.Position = UDim2.new(0.4, 10, 0, 25)
    perfBarBg.BackgroundColor3 = UIStyle.colors.backgroundLight
    perfBarBg.BorderSizePixel = 0
    perfBarBg.Parent = staffItem
    
    -- Performance bar background corner
    local perfBgCorner = Instance.new("UICorner")
    perfBgCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    perfBgCorner.Parent = perfBarBg
    
    -- Performance bar fill
    local perfBarFill = Instance.new("Frame")
    perfBarFill.Name = "PerfBarFill"
    perfBarFill.Size = UDim2.new(performance/100, 0, 1, 0)
    perfBarFill.BackgroundColor3 = performance >= 80 and UIStyle.colors.success or 
                                  (performance >= 60 and UIStyle.colors.warning or UIStyle.colors.error)
    perfBarFill.BorderSizePixel = 0
    perfBarFill.Parent = perfBarBg
    
    -- Performance bar fill corner
    local perfFillCorner = Instance.new("UICorner")
    perfFillCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    perfFillCorner.Parent = perfBarFill
    
    -- Performance text
    local perfText = UIStyle.createText({
        name = "PerfText",
        text = performance.."%",
        style = "numeric",
        size = UDim2.new(0, 50, 0, 20),
        position = UDim2.new(0.4, 10 + perfBarBg.Size.X.Offset + 10, 0, 25),
        parent = staffItem
    })
    
    -- View details button
    local viewButton = Instance.new("TextButton")
    viewButton.Name = "ViewButton"
    viewButton.Text = "Details"
    viewButton.Size = UDim2.new(0, 80, 0, 30)
    viewButton.Position = UDim2.new(1, -100, 0.5, -15)
    viewButton.BackgroundColor3 = UIStyle.colors.primary
    viewButton.TextColor3 = UIStyle.colors.textPrimary
    viewButton.Font = UIStyle.fonts.button.Font
    viewButton.TextSize = UIStyle.fonts.button.Size
    viewButton.BorderSizePixel = 0
    viewButton.Parent = staffItem
    
    -- View button corner
    local viewButtonCorner = Instance.new("UICorner")
    viewButtonCorner.CornerRadius = UIStyle.layout.cornerRadiusSmall
    viewButtonCorner.Parent = viewButton
    
    return staffItem
end

-- Placeholder functions for other tabs - to be implemented
function StaffManagementUI:buildHireStaffTab()
    local hireTab = self.hireStaffTab
    
    -- Coming Soon message
    local comingSoon = UIStyle.createText({
        name = "ComingSoon",
        text = "Staff Hiring Interface\nComing Soon",
        style = "titleMedium",
        size = UDim2.new(1, 0, 0, 100),
        position = UDim2.new(0, 0, 0.3, 0),
        xAlign = Enum.TextXAlignment.Center,
        parent = hireTab
    })
end

function StaffManagementUI:buildScheduleTab()
    local scheduleTab = self.scheduleTab
    
    -- Coming Soon message
    local comingSoon = UIStyle.createText({
        name = "ComingSoon",
        text = "Staff Scheduling System\nComing Soon",
        style = "titleMedium",
        size = UDim2.new(1, 0, 0, 100),
        position = UDim2.new(0, 0, 0.3, 0),
        xAlign = Enum.TextXAlignment.Center,
        parent = scheduleTab
    })
end

function StaffManagementUI:buildTrainingTab()
    local trainingTab = self.trainingTab
    
    -- Coming Soon message
    local comingSoon = UIStyle.createText({
        name = "ComingSoon",
        text = "Staff Training System\nComing Soon",
        style = "titleMedium",
        size = UDim2.new(1, 0, 0, 100),
        position = UDim2.new(0, 0, 0.3, 0),
        xAlign = Enum.TextXAlignment.Center,
        parent = trainingTab
    })
end

function StaffManagementUI:buildPerformanceTab()
    local performanceTab = self.performanceTab
    
    -- Coming Soon message
    local comingSoon = UIStyle.createText({
        name = "ComingSoon",
        text = "Staff Performance Metrics\nComing Soon",
        style = "titleMedium",
        size = UDim2.new(1, 0, 0, 100),
        position = UDim2.new(0, 0, 0.3, 0),
        xAlign = Enum.TextXAlignment.Center,
        parent = performanceTab
    })
end

-- Update staff list with actual data
function StaffManagementUI:updateStaffList(staffData)
    -- Clear existing staff items
    for _, child in pairs(self.staffList:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Add staff items from data
    local order = 1
    for id, staff in pairs(staffData) do
        self:createStaffItem(staff.name, staff.role, staff.performance, order)
        order = order + 1
    end
    
    -- Update canvas size
    self:updateCanvasSize()
end

-- Update canvas size based on content
function StaffManagementUI:updateCanvasSize()
    local contentHeight = 0
    local layout = self.staffList:FindFirstChildOfClass("UIListLayout")
    
    if layout then
        contentHeight = layout.AbsoluteContentSize.Y
    end
    
    self.staffList.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 10)
end

-- Override onShow to update with latest data
function StaffManagementUI:onShow()
    -- Update with the latest data when shown
    -- This would connect to a DataService in a real implementation
    self:updateStaffList(self.staffData)
    self:showTab("Overview")
end

return StaffManagementUI