--[[
    RevenueDisplay.client.luau
    Client-side UI module for displaying gym revenue information
    Part of the UI modules architecture
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Client references
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Module dependencies
local ClientRegistry
local ClientEventBridge
local UIManager

-- Configuration
local CONFIG = {
    -- UI appearance
    mainColor = Color3.fromRGB(39, 174, 96),     -- Green
    accentColor = Color3.fromRGB(241, 196, 15),  -- Yellow/Gold
    warningColor = Color3.fromRGB(231, 76, 60),  -- Red
    
    -- Animation settings
    tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    countingTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    
    -- Display settings
    formatCurrency = true,  -- Add $ symbol and commas
    updateInterval = 5,     -- Update display every 5 seconds
    
    -- Sound effects
    sounds = {
        collect = "rbxassetid://5297553953",  -- Cash register sound
        tier = "rbxassetid://6895079853"      -- Level up sound
    },
    
    -- Debug
    debug = false
}

-- Module table
local RevenueDisplay = {
    _name = "RevenueDisplay",
    _version = "1.0.0",
    _dependencies = {"ClientRegistry", "ClientEventBridge", "UIManager"},
    _isSetup = false,
    _gui = nil,
    _membershipInfo = {
        memberCount = 0,
        vipCount = 0,
        hourlyRevenue = 0,
        currentTier = 0,
        nextThreshold = nil
    }
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[Revenue Display]", ...)
    end
end

--[[ Helper Functions ]]--

-- Format numbers with commas and optional currency symbol
local function formatNumber(number, addCurrency)
    local formatted = tostring(number)
    local k
    
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    
    if addCurrency then
        formatted = "$" .. formatted
    end
    
    return formatted
end

-- Animate number counting up
local function animateCount(label, startValue, endValue, duration, prefix)
    prefix = prefix or ""
    
    -- Create a value object to tween
    local countValue = Instance.new("NumberValue")
    countValue.Value = startValue
    
    -- Create a tween for smooth counting animation
    local tween = TweenService:Create(
        countValue,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Value = endValue}
    )
    
    -- Update the label during the tween
    local connection
    connection = countValue.Changed:Connect(function()
        local currentValue = math.floor(countValue.Value)
        
        if CONFIG.formatCurrency and prefix == "$" then
            label.Text = prefix .. formatNumber(currentValue, false)
        else
            label.Text = prefix .. currentValue
        end
    end)
    
    -- Clean up when the tween completes
    tween.Completed:Connect(function()
        connection:Disconnect()
        countValue:Destroy()
    end)
    
    -- Start the animation
    tween:Play()
    
    return tween
end

-- Create and play a sound effect
local function playSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = PlayerGui
    
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    return sound
end

--[[ Core Functions ]]--

-- Create the main revenue display UI
function RevenueDisplay:createGui()
    -- Check if UI already exists
    if self._gui then return self._gui end
    
    -- Create main UI frame
    local gui = Instance.new("ScreenGui")
    gui.Name = "RevenueDisplayGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main container frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(1, -320, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(52, 73, 94) -- Dark blue
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = gui
    
    -- Apply corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "Gym Revenue"
    titleLabel.TextSize = 24
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Parent = mainFrame
    
    -- Add membership count display
    local membershipFrame = Instance.new("Frame")
    membershipFrame.Name = "MembershipFrame"
    membershipFrame.Size = UDim2.new(1, -20, 0, 30)
    membershipFrame.Position = UDim2.new(0, 10, 0, 50)
    membershipFrame.BackgroundTransparency = 0.8
    membershipFrame.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
    membershipFrame.BorderSizePixel = 0
    membershipFrame.Parent = mainFrame
    
    local membershipLabel = Instance.new("TextLabel")
    membershipLabel.Name = "Label"
    membershipLabel.Size = UDim2.new(0.5, 0, 1, 0)
    membershipLabel.BackgroundTransparency = 1
    membershipLabel.Font = Enum.Font.Gotham
    membershipLabel.Text = "Members:"
    membershipLabel.TextSize = 16
    membershipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    membershipLabel.TextXAlignment = Enum.TextXAlignment.Left
    membershipLabel.Parent = membershipFrame
    
    local membershipValue = Instance.new("TextLabel")
    membershipValue.Name = "Value"
    membershipValue.Size = UDim2.new(0.5, 0, 1, 0)
    membershipValue.Position = UDim2.new(0.5, 0, 0, 0)
    membershipValue.BackgroundTransparency = 1
    membershipValue.Font = Enum.Font.GothamSemibold
    membershipValue.Text = "0"
    membershipValue.TextSize = 16
    membershipValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    membershipValue.TextXAlignment = Enum.TextXAlignment.Right
    membershipValue.Parent = membershipFrame
    
    -- Add VIP members display
    local vipFrame = Instance.new("Frame")
    vipFrame.Name = "VIPFrame"
    vipFrame.Size = UDim2.new(1, -20, 0, 30)
    vipFrame.Position = UDim2.new(0, 10, 0, 85)
    vipFrame.BackgroundTransparency = 0.8
    vipFrame.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
    vipFrame.BorderSizePixel = 0
    vipFrame.Parent = mainFrame
    
    local vipLabel = Instance.new("TextLabel")
    vipLabel.Name = "Label"
    vipLabel.Size = UDim2.new(0.5, 0, 1, 0)
    vipLabel.BackgroundTransparency = 1
    vipLabel.Font = Enum.Font.Gotham
    vipLabel.Text = "VIP Members:"
    vipLabel.TextSize = 16
    vipLabel.TextColor3 = Color3.fromRGB(255, 223, 0) -- Gold for VIP
    vipLabel.TextXAlignment = Enum.TextXAlignment.Left
    vipLabel.Parent = vipFrame
    
    local vipValue = Instance.new("TextLabel")
    vipValue.Name = "Value"
    vipValue.Size = UDim2.new(0.5, 0, 1, 0)
    vipValue.Position = UDim2.new(0.5, 0, 0, 0)
    vipValue.BackgroundTransparency = 1
    vipValue.Font = Enum.Font.GothamSemibold
    vipValue.Text = "0"
    vipValue.TextSize = 16
    vipValue.TextColor3 = Color3.fromRGB(255, 223, 0) -- Gold for VIP
    vipValue.TextXAlignment = Enum.TextXAlignment.Right
    vipValue.Parent = vipFrame
    
    -- Add hourly revenue display
    local revenueFrame = Instance.new("Frame")
    revenueFrame.Name = "RevenueFrame"
    revenueFrame.Size = UDim2.new(1, -20, 0, 30)
    revenueFrame.Position = UDim2.new(0, 10, 0, 120)
    revenueFrame.BackgroundTransparency = 0.8
    revenueFrame.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
    revenueFrame.BorderSizePixel = 0
    revenueFrame.Parent = mainFrame
    
    local revenueLabel = Instance.new("TextLabel")
    revenueLabel.Name = "Label"
    revenueLabel.Size = UDim2.new(0.5, 0, 1, 0)
    revenueLabel.BackgroundTransparency = 1
    revenueLabel.Font = Enum.Font.Gotham
    revenueLabel.Text = "Hourly Revenue:"
    revenueLabel.TextSize = 16
    revenueLabel.TextColor3 = CONFIG.mainColor
    revenueLabel.TextXAlignment = Enum.TextXAlignment.Left
    revenueLabel.Parent = revenueFrame
    
    local revenueValue = Instance.new("TextLabel")
    revenueValue.Name = "Value"
    revenueValue.Size = UDim2.new(0.5, 0, 1, 0)
    revenueValue.Position = UDim2.new(0.5, 0, 0, 0)
    revenueValue.BackgroundTransparency = 1
    revenueValue.Font = Enum.Font.GothamSemibold
    revenueValue.Text = "$0"
    revenueValue.TextSize = 16
    revenueValue.TextColor3 = CONFIG.mainColor
    revenueValue.TextXAlignment = Enum.TextXAlignment.Right
    revenueValue.Parent = revenueFrame
    
    -- Add tier display
    local tierFrame = Instance.new("Frame")
    tierFrame.Name = "TierFrame"
    tierFrame.Size = UDim2.new(1, -20, 0, 30)
    tierFrame.Position = UDim2.new(0, 10, 0, 155)
    tierFrame.BackgroundTransparency = 0.8
    tierFrame.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
    tierFrame.BorderSizePixel = 0
    tierFrame.Parent = mainFrame
    
    local tierLabel = Instance.new("TextLabel")
    tierLabel.Name = "Label"
    tierLabel.Size = UDim2.new(0.5, 0, 1, 0)
    tierLabel.BackgroundTransparency = 1
    tierLabel.Font = Enum.Font.Gotham
    tierLabel.Text = "Membership Tier:"
    tierLabel.TextSize = 16
    tierLabel.TextColor3 = CONFIG.accentColor
    tierLabel.TextXAlignment = Enum.TextXAlignment.Left
    tierLabel.Parent = tierFrame
    
    local tierValue = Instance.new("TextLabel")
    tierValue.Name = "Value"
    tierValue.Size = UDim2.new(0.5, 0, 1, 0)
    tierValue.Position = UDim2.new(0.5, 0, 0, 0)
    tierValue.BackgroundTransparency = 1
    tierValue.Font = Enum.Font.GothamSemibold
    tierValue.Text = "0"
    tierValue.TextSize = 16
    tierValue.TextColor3 = CONFIG.accentColor
    tierValue.TextXAlignment = Enum.TextXAlignment.Right
    tierValue.Parent = tierFrame
    
    -- Store references
    self._gui = gui
    self._frames = {
        membership = membershipValue,
        vip = vipValue,
        revenue = revenueValue,
        tier = tierValue
    }
    
    -- Parent to PlayerGui
    gui.Parent = PlayerGui
    
    return gui
end

-- Show special event notification
function RevenueDisplay:showSpecialEventNotification(eventData)
    -- Create notification frame
    local notification = Instance.new("Frame")
    notification.Name = "SpecialEventNotification"
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(0.5, -150, 0, -100) -- Start above screen
    notification.BackgroundColor3 = CONFIG.accentColor
    notification.BorderSizePixel = 0
    notification.Parent = self._gui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notification
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "SPECIAL EVENT!"
    titleLabel.TextSize = 20
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Parent = notification
    
    -- Add description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -20, 0, 40)
    descLabel.Position = UDim2.new(0, 10, 0, 35)
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Enum.Font.Gotham
    descLabel.Text = (eventData.eventType or "Membership Drive") .. " - Income Boosted by " .. 
                     math.floor(((eventData.boostMultiplier or 1.5) - 1) * 100) .. "%!"
    descLabel.TextSize = 14
    descLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    descLabel.TextWrapped = true
    descLabel.Parent = notification
    
    -- Animate entry
    local entryTween = TweenService:Create(
        notification,
        CONFIG.tweenInfo,
        {Position = UDim2.new(0.5, -150, 0, 20)}
    )
    entryTween:Play()
    
    -- Schedule removal after 5 seconds
    task.delay(5, function()
        local exitTween = TweenService:Create(
            notification,
            CONFIG.tweenInfo,
            {Position = UDim2.new(0.5, -150, 0, -100)}
        )
        exitTween:Play()
        
        exitTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
    
    -- Play notification sound
    playSound("rbxassetid://6026984224")
end

-- Update the display with new revenue information
function RevenueDisplay:updateDisplay(data, animate)
    if not self._gui then
        self:createGui()
    end
    
    -- Store previous values for animation if needed
    local prev = {
        memberCount = self._membershipInfo.memberCount,
        vipCount = self._membershipInfo.vipCount,
        hourlyRevenue = self._membershipInfo.hourlyRevenue,
        currentTier = self._membershipInfo.currentTier
    }
    
    -- Update stored information
    for k, v in pairs(data) do
        self._membershipInfo[k] = v
    end
    
    -- Update display values
    if animate then
        -- Animate count transitions
        animateCount(self._frames.membership, prev.memberCount, data.memberCount, 1)
        animateCount(self._frames.vip, prev.vipCount, data.vipCount, 1)
        animateCount(self._frames.revenue, prev.hourlyRevenue, data.hourlyRevenue, 1, "$")
        
        -- Handle tier change separately with effects
        if data.currentTier > prev.currentTier then
            -- Flash tier value with gold color
            animateCount(self._frames.tier, prev.currentTier, data.currentTier, 0.5)
            
            local flashSequence = function()
                for i = 1, 3 do
                    self._frames.tier.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
                    task.wait(0.2)
                    self._frames.tier.TextColor3 = CONFIG.accentColor
                    task.wait(0.2)
                end
            end
            
            task.spawn(flashSequence)
            playSound(CONFIG.sounds.tier)
        else
            self._frames.tier.Text = data.currentTier
        end
    else
        -- Update immediately without animation
        self._frames.membership.Text = data.memberCount
        self._frames.vip.Text = data.vipCount
        self._frames.revenue.Text = "$" .. formatNumber(data.hourlyRevenue, false)
        self._frames.tier.Text = data.currentTier
    end
end

-- Show the dues collection animation and notification
function RevenueDisplay:showDuesCollected(amount)
    -- Create a floating notification
    local notification = Instance.new("Frame")
    notification.Name = "DuesCollectedNotification"
    notification.Size = UDim2.new(0, 200, 0, 60)
    notification.Position = UDim2.new(0.5, -100, 0.4, 0)
    notification.BackgroundColor3 = CONFIG.mainColor
    notification.BackgroundTransparency = 0.2
    notification.BorderSizePixel = 0
    notification.Parent = self._gui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notification
    
    -- Add text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "DUES COLLECTED"
    titleLabel.TextSize = 18
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Parent = notification
    
    local amountLabel = Instance.new("TextLabel")
    amountLabel.Name = "Amount"
    amountLabel.Size = UDim2.new(1, 0, 0, 30)
    amountLabel.Position = UDim2.new(0, 0, 0.5, 0)
    amountLabel.BackgroundTransparency = 1
    amountLabel.Font = Enum.Font.GothamSemibold
    amountLabel.Text = "$" .. formatNumber(amount, false)
    amountLabel.TextSize = 22
    amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    amountLabel.Parent = notification
    
    -- Play collection sound
    playSound(CONFIG.sounds.collect)
    
    -- Animate the notification
    TweenService:Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 220, 0, 70)}
    ):Play()
    
    -- Fade out and remove after 2 seconds
    task.delay(2, function()
        local fadeTween = TweenService:Create(
            notification,
            CONFIG.tweenInfo,
            {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, -100, 0.35, 0)
            }
        )
        fadeTween:Play()
        
        -- Also fade out the text
        TweenService:Create(titleLabel, CONFIG.tweenInfo, {TextTransparency = 1}):Play()
        TweenService:Create(amountLabel, CONFIG.tweenInfo, {TextTransparency = 1}):Play()
        
        fadeTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
end

--[[ Event Handlers ]]--

-- Handle membership data updates
function RevenueDisplay:handleMembershipUpdated(data)
    self:updateDisplay(data, true)
end

-- Handle membership tier changes
function RevenueDisplay:handleMembershipTierUp(data)
    local tierInfo = {
        [1] = "Bronze Tier",
        [2] = "Silver Tier",
        [3] = "Gold Tier",
        [4] = "Platinum Tier",
        [5] = "Diamond Tier"
    }
    
    local notification = UIManager:showNotification({
        title = "MEMBERSHIP TIER UP!",
        message = "Your gym is now " .. (tierInfo[data.newTier] or "Tier " .. data.newTier),
        icon = "rbxassetid://6031280882", -- Trophy icon
        duration = 5,
        color = CONFIG.accentColor
    })
    
    playSound(CONFIG.sounds.tier)
end

-- Handle special events
function RevenueDisplay:handleSpecialEventStarted(data)
    self:showSpecialEventNotification(data)
end

-- Handle dues collection
function RevenueDisplay:handleDuesCollected(amount)
    self:showDuesCollected(amount)
end

--[[ Initialization and Cleanup ]]--

-- Set up the revenue display system
function RevenueDisplay:setup()
    if self._isSetup then return end
    
    -- Get dependencies
    ClientRegistry = self.ClientRegistry
    ClientEventBridge = ClientRegistry:getSystem("ClientEventBridge")
    UIManager = ClientRegistry:getSystem("UIManager")
    
    -- Register event handlers
    if ClientEventBridge then
        ClientEventBridge:registerEvent("MembershipUpdated", function(data)
            self:handleMembershipUpdated(data)
        end)
        
        ClientEventBridge:registerEvent("MembershipTierUp", function(data)
            self:handleMembershipTierUp(data)
        end)
        
        ClientEventBridge:registerEvent("SpecialEventStarted", function(data)
            self:handleSpecialEventStarted(data)
        end)
        
        ClientEventBridge:registerEvent("SpecialEventEnded", function()
            UIManager:showNotification({
                title = "Event Ended",
                message = "The special event has ended. Regular income rates resumed.",
                duration = 3
            })
        end)
        
        ClientEventBridge:registerEvent("DuesCollected", function(amount)
            self:handleDuesCollected(amount)
        end)
    end
    
    -- Create the UI
    self:createGui()
    
    -- Request initial data
    if ClientEventBridge then
        ClientEventBridge:fireServer("RequestMembershipData")
    end
    
    -- Setup auto-refresh loop
    self._refreshInterval = task.spawn(function()
        while true do
            task.wait(CONFIG.updateInterval)
            if ClientEventBridge then
                ClientEventBridge:fireServer("RequestMembershipData")
            end
        end
    end)
    
    self._isSetup = true
    debugPrint("RevenueDisplay setup complete")
end

-- Clean up resources
function RevenueDisplay:cleanup()
    if self._refreshInterval then
        task.cancel(self._refreshInterval)
        self._refreshInterval = nil
    end
    
    if self._gui then
        self._gui:Destroy()
        self._gui = nil
    end
    
    self._isSetup = false
end

--[[ Public API ]]--

-- Initialize the module
function RevenueDisplay:init()
    debugPrint("Initializing RevenueDisplay v" .. self._version)
    return true
end

-- Start the module
function RevenueDisplay:start()
    self:setup()
    debugPrint("RevenueDisplay started")
    return true
end

-- Stop the module
function RevenueDisplay:stop()
    self:cleanup()
    debugPrint("RevenueDisplay stopped")
    return true
end

return RevenueDisplay