-- GymTycoonMenuUI.client.luau
-- Specialized UI module for Gym Tycoon game systems
-- Created April 2025

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Log function
local function log(message)
    print("[GymTycoonMenuUI] " .. message)
end

-- Icons for gym-related systems
local GYM_ICONS = {
    Equipment = "rbxassetid://6031094678",   -- Equipment icon
    Membership = "rbxassetid://6031302920",  -- Membership card icon
    Staff = "rbxassetid://6031094670",       -- Staff icon
    Expansion = "rbxassetid://6026568247",   -- Construction/expansion icon
    Challenge = "rbxassetid://6031280882",   -- Challenge/competition icon
    Marketing = "rbxassetid://6031094661"    -- Marketing/business icon
}

-- Main Gym Tycoon UI module
local GymTycoonMenuUI = {}

-- Track all UI elements
GymTycoonMenuUI.activeMenus = {}

-- Initialize the UI system
function GymTycoonMenuUI:Initialize()
    log("Initializing GymTycoonMenuUI...")
    
    -- Create the management menu (hidden initially)
    self:CreateManagementMenu()
    
    -- Make sure our ToggleManagementMenu function is properly defined
    -- It's already defined below, so we don't need to redefine it here
    
    log("GymTycoonMenuUI initialized successfully")
    return true
end

-- Create the main management menu
function GymTycoonMenuUI:CreateManagementMenu()
    -- Create a ScreenGui for the management menu
    local menuGui = Instance.new("ScreenGui")
    menuGui.Name = "GymManagementMenu"
    menuGui.ResetOnSpawn = false
    menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    menuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create the main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = menuGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Add corner radius to title bar (top corners only)
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners
    local bottomFix = Instance.new("Frame")
    bottomFix.Size = UDim2.new(1, 0, 0, 10)
    bottomFix.Position = UDim2.new(0, 0, 1, -10)
    bottomFix.BackgroundColor3 = titleBar.BackgroundColor3
    bottomFix.BorderSizePixel = 0
    bottomFix.Parent = titleBar
    
    -- Add title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 50, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Gym Management"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Add icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 14, 0, 8)
    icon.BackgroundTransparency = 1
    icon.Image = GYM_ICONS.Equipment
    icon.Parent = titleBar
    
    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    closeButton.TextSize = 18
    closeButton.Parent = titleBar
    
    -- Close button click event
    closeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)
    
    -- Create tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 120, 1, -50)
    tabContainer.Position = UDim2.new(0, 10, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    -- Create content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -140, 1, -50)
    contentFrame.Position = UDim2.new(0, 130, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Track tab buttons and content
    local tabButtons = {}
    local tabContents = {}
    
    -- Function to create a tab
    local function createTab(name)
        -- Count existing tabs to determine position
        local tabCount = 0
        for _, child in pairs(tabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                tabCount = tabCount + 1
            end
        end
        
        local yPos = tabCount * 40
        
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = name .. "Tab"
        tabButton.Text = name
        tabButton.Size = UDim2.new(1, -10, 0, 35)
        tabButton.Position = UDim2.new(0, 5, 0, yPos + 5)
        tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        tabButton.TextSize = 14
        tabButton.BorderSizePixel = 0
        tabButton.Parent = tabContainer
          -- Add corner radius
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 8)
        tabCorner.Parent = tabButton
        
        -- Create content container for this tab
        local tabContent = Instance.new("Frame")
        tabContent.Name = name .. "Content"
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = #tabButtons == 0 -- First tab is visible by default
        tabContent.Parent = contentFrame
        
        -- Tab button click event
        tabButton.MouseButton1Click:Connect(function()
            -- Show this tab, hide others
            for _, content in pairs(tabContents) do
                content.Visible = (content == tabContent)
            end
            
            -- Update button styles
            for _, button in ipairs(tabButtons) do
                button.BackgroundColor3 = (button == tabButton) 
                    and Color3.fromRGB(65, 105, 225) 
                    or Color3.fromRGB(50, 50, 60)
            end
        end)
        
        -- Set initial colors
        if #tabButtons == 0 then
            tabButton.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
        else
            tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        end
        
        table.insert(tabButtons, tabButton)
        tabContents[name] = tabContent
        
        return tabContent
    end
    
    -- Create the tabs for gym management
    local equipmentTab = createTab("Equipment")
    local staffTab = createTab("Staff")
    local expansionTab = createTab("Expansion")
    local marketingTab = createTab("Marketing")
    local financesTab = createTab("Finances")
    
    -- Equipment Tab Content
    self:SetupEquipmentTab(equipmentTab)
    
    -- Staff Tab Content
    self:SetupStaffTab(staffTab)
    
    -- Expansion Tab Content
    self:SetupExpansionTab(expansionTab)
    
    -- Marketing Tab Content
    self:SetupMarketingTab(marketingTab)
    
    -- Finances Tab Content
    self:SetupFinancesTab(financesTab)
    
    -- Make the frame draggable
    local dragging = false
    local dragInput, dragStart, startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    Players.LocalPlayer:GetMouse().Move:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Store the menu in active menus
    self.activeMenus["Management"] = {
        gui = menuGui,
        mainFrame = mainFrame
    }
    
    log("Created gym management menu")
end

-- Create styled button function
function GymTycoonMenuUI:CreateStyledButton(parent, text, position, size, callback)
    local button = Instance.new("TextButton")
    button.Name = text:gsub("%s+", "") .. "Button"
    button.Text = text
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = Color3.fromRGB(65, 105, 225) -- Royal blue
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    button.TextSize = 14
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Add hover effects
    local hoverColor = Color3.fromRGB(100, 140, 250)
    local defaultColor = button.BackgroundColor3
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = defaultColor
    end)
    
    -- Add click callback
    if callback then
        button.MouseButton1Click:Connect(function()
            callback(button)
        end)
    end
    
    return button
end

-- Create styled label function
function GymTycoonMenuUI:CreateStyledLabel(parent, text, position, size, bold)
    local label = Instance.new("TextLabel")
    label.Name = text:gsub("%s+", "") .. "Label"
    label.Text = text
    label.Position = position
    label.Size = size
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    if bold then
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    else
        label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
    end
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = parent
    
    return label
end

-- Set up Equipment Tab
function GymTycoonMenuUI:SetupEquipmentTab(parent)
    -- Title
    self:CreateStyledLabel(parent, "Gym Equipment Management", UDim2.new(0, 10, 0, 10), UDim2.new(0, 240, 0, 30), true)
    
    -- Equipment list container
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Name = "EquipmentList"
    listFrame.Size = UDim2.new(1, -20, 0, 200)
    listFrame.Position = UDim2.new(0, 10, 0, 50)
    listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 6
    listFrame.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = listFrame
    
    -- Add layout for equipment items
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = listFrame
    
    -- Sample equipment items (these would normally come from the server)
    local sampleEquipment = {
        { name = "Treadmill", level = 1, cost = 500 },
        { name = "Bench Press", level = 2, cost = 1200 },
        { name = "Squat Rack", level = 3, cost = 2000 },
        { name = "Rowing Machine", level = 1, cost = 800 }
    }
      -- Add equipment items to the list
    for _, equipment in ipairs(sampleEquipment) do
        local item = Instance.new("Frame")
        item.Name = equipment.name .. "Item"
        item.Size = UDim2.new(1, -10, 0, 60)
        item.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        item.BorderSizePixel = 0
        item.Parent = listFrame
        
        -- Add corner radius
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 6)
        itemCorner.Parent = item
        
        -- Equipment name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(0.5, -10, 0, 20)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = equipment.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = item
        
        -- Equipment level
        local levelLabel = Instance.new("TextLabel")
        levelLabel.Name = "LevelLabel"
        levelLabel.Size = UDim2.new(0.5, -10, 0, 20)
        levelLabel.Position = UDim2.new(0, 10, 0, 25)
        levelLabel.BackgroundTransparency = 1
        levelLabel.Text = "Level: " .. equipment.level
        levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        levelLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
        levelLabel.TextSize = 12
        levelLabel.TextXAlignment = Enum.TextXAlignment.Left
        levelLabel.Parent = item
        
        -- Create upgrade button
        self:CreateStyledButton(
            item, 
            "Upgrade", 
            UDim2.new(0.75, 0, 0, 10), 
            UDim2.new(0.22, 0, 0, 30),
            function()
                log("Upgrade equipment: " .. equipment.name)
                
                -- This would call a server event in a real scenario
                local success = true -- Simulated success
                
                if success then
                    equipment.level = equipment.level + 1
                    levelLabel.Text = "Level: " .. equipment.level
                end
            end
        )
        
        -- Cost label
        local costLabel = Instance.new("TextLabel")
        costLabel.Name = "CostLabel"
        costLabel.Size = UDim2.new(0.25, -10, 0, 20)
        costLabel.Position = UDim2.new(0.5, 0, 0, 15)
        costLabel.BackgroundTransparency = 1
        costLabel.Text = "$" .. equipment.cost
        costLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
        costLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
        costLabel.TextSize = 14
        costLabel.TextXAlignment = Enum.TextXAlignment.Left
        costLabel.Parent = item
    end
    
    -- Update layout size
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Action buttons
    self:CreateStyledButton(
        parent, 
        "Buy New Equipment", 
        UDim2.new(0, 10, 0, 260), 
        UDim2.new(0, 150, 0, 35),
        function()
            log("Open buy new equipment menu")
            -- This would open a catalog of available equipment
        end
    )
    
    self:CreateStyledButton(
        parent, 
        "Rearrange Layout", 
        UDim2.new(0, 170, 0, 260), 
        UDim2.new(0, 150, 0, 35),
        function()
            log("Open layout editor")
            -- This would open a layout editor for the gym
        end
    )
end

-- Set up Staff Tab
function GymTycoonMenuUI:SetupStaffTab(parent)
    -- Title
    self:CreateStyledLabel(parent, "Staff Management", UDim2.new(0, 10, 0, 10), UDim2.new(0, 240, 0, 30), true)
    
    -- Staff functionality would go here
    self:CreateStyledLabel(parent, "Hire and manage your gym staff", UDim2.new(0, 10, 0, 50), UDim2.new(0, 240, 0, 30))
    
    -- Staff stats
    self:CreateStyledLabel(parent, "Current Staff: 3", UDim2.new(0, 10, 0, 90), UDim2.new(0, 240, 0, 20))
    self:CreateStyledLabel(parent, "Monthly Expenses: $1,500", UDim2.new(0, 10, 0, 120), UDim2.new(0, 240, 0, 20))
    self:CreateStyledLabel(parent, "Staff Efficiency: 85%", UDim2.new(0, 10, 0, 150), UDim2.new(0, 240, 0, 20))
    
    -- Action buttons
    self:CreateStyledButton(
        parent, 
        "Hire New Staff", 
        UDim2.new(0, 10, 0, 190), 
        UDim2.new(0, 150, 0, 35),
        function()
            log("Open staff hiring menu")
        end
    )
    
    self:CreateStyledButton(
        parent, 
        "Train Staff", 
        UDim2.new(0, 10, 0, 235), 
        UDim2.new(0, 150, 0, 35),
        function()
            log("Open staff training menu")
        end
    )
    
    self:CreateStyledButton(
        parent, 
        "Manage Schedule", 
        UDim2.new(0, 10, 0, 280), 
        UDim2.new(0, 150, 0, 35),
        function()
            log("Open staff schedule menu")
        end
    )
end

-- Set up other tabs (simplified implementation for brevity)
function GymTycoonMenuUI:SetupExpansionTab(parent)
    self:CreateStyledLabel(parent, "Gym Expansion", UDim2.new(0, 10, 0, 10), UDim2.new(0, 240, 0, 30), true)
    self:CreateStyledLabel(parent, "Expand your gym to attract more members", UDim2.new(0, 10, 0, 50), UDim2.new(0, 240, 0, 30))
    
    -- Additional expansion UI would go here
end

function GymTycoonMenuUI:SetupMarketingTab(parent)
    self:CreateStyledLabel(parent, "Marketing Campaigns", UDim2.new(0, 10, 0, 10), UDim2.new(0, 240, 0, 30), true)
    self:CreateStyledLabel(parent, "Promote your gym to attract new members", UDim2.new(0, 10, 0, 50), UDim2.new(0, 240, 0, 30))
    
    -- Additional marketing UI would go here
end

function GymTycoonMenuUI:SetupFinancesTab(parent)
    self:CreateStyledLabel(parent, "Financial Management", UDim2.new(0, 10, 0, 10), UDim2.new(0, 240, 0, 30), true)
    self:CreateStyledLabel(parent, "Track income and expenses", UDim2.new(0, 10, 0, 50), UDim2.new(0, 240, 0, 30))
    
    -- Additional finances UI would go here
end

-- Toggle visibility of the management menu
function GymTycoonMenuUI:ToggleManagementMenu()
    if self.activeMenus and self.activeMenus["Management"] then
        local menu = self.activeMenus["Management"]
        menu.mainFrame.Visible = not menu.mainFrame.Visible
        
        log("Toggled management menu visibility: " .. tostring(menu.mainFrame.Visible))
    else
        log("Management menu not found")
    end
end

-- Initialize when the player is loaded
local function onPlayerLoaded()
    -- Wait a short time to ensure other systems are ready
    task.wait(2)
    GymTycoonMenuUI:Initialize()
end

-- If the player is already loaded
if LocalPlayer:IsDescendantOf(game) then
    onPlayerLoaded()
else
    -- Otherwise wait for the player to load
    LocalPlayer.CharacterAdded:Connect(function()
        onPlayerLoaded()
    end)
end

return GymTycoonMenuUI
