lua
-- This script manages the Member Satisfaction UI

local MemberSatisfactionUI = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

function MemberSatisfactionUI.init()
    local function createIcon(iconId)
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(1, 0, 1, 0)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://" .. iconId
        return icon
    end
    
    function MemberSatisfactionUI.clearKeyFactors()
        for _, child in ipairs(keyFactorsContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end


    local function updateSatisfactionScore(score)
        local scoreLabel = overviewPanel:FindFirstChild("SatisfactionScore")
        if scoreLabel and scoreLabel:IsA("TextLabel") then
            scoreLabel.Text = tostring(score)
        end
    end

    local function updateStatusLabel(status)
        local statusLabel = overviewPanel:FindFirstChild("StatusLabel")
        if statusLabel and statusLabel:IsA("TextLabel") then
            statusLabel.Text = status
        end
    end

    local function updateTrendIndicator(isImproving)
        local trendIndicator = overviewPanel:FindFirstChild("TrendIndicator")
        if trendIndicator and trendIndicator:IsA("ImageLabel") then
            if isImproving then
                trendIndicator.Image = "rbxassetid://13337321193"
            else
                trendIndicator.Image = "rbxassetid://13337324635"
            end
        end
    end

    local function updateMemberRetention(retention)
        local memberRetentionLabel = overviewPanel:FindFirstChild("MemberRetentionLabel")
        if memberRetentionLabel and memberRetentionLabel:IsA("TextLabel") then
            memberRetentionLabel.Text = "Member Retention: " .. tostring(retention) .. "%"
        end
    end

    local function updateRevenueImpact(impact)
        local revenueImpactLabel = overviewPanel:FindFirstChild("RevenueImpactLabel")
        if revenueImpactLabel and revenueImpactLabel:IsA("TextLabel") then
            revenueImpactLabel.Text = "Revenue Impact: " .. tostring(impact) .. "%"
        end
    end

    local function addKeyFactor(iconId, factorName, value)
        local keyFactorFrame = Instance.new("Frame")
        keyFactorFrame.Size = UDim2.new(0, 50, 0, 50)
        keyFactorFrame.BackgroundTransparency = 1
        local icon = createIcon(iconId)
        icon.Parent = keyFactorFrame
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1,0,0.2,0)
        textLabel.Text = factorName .. " : " .. value
        keyFactorFrame.Parent = keyFactorsContainer
    end


	local gui = Instance.new("ScreenGui")
	gui.Name = "MemberSatisfactionGUI"
	gui.Parent = PlayerGui
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.Position = UDim2.new(0, 0, 0, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.ZIndex = 10
	
	mainFrame.Parent = gui
	
	local overviewPanel = Instance.new("Frame")
	overviewPanel.Name = "OverviewPanel"
	overviewPanel.Size = UDim2.new(0.8, 0, 0.4, 0)
	overviewPanel.Position = UDim2.new(0.1, 0, 0.1, 0)
	overviewPanel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

	local overviewCorner = Instance.new("UICorner")
	overviewCorner.CornerRadius = UDim.new(0, 10)
	overviewCorner.Parent = overviewPanel
	
    local keyFactorsContainer = Instance.new("Frame")
    
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1,0,0.2,0)
	title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.Text = "Member Satisfaction"
    title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = overviewPanel
	
	-- Satisfaction Score
	local satisfactionScore = Instance.new("TextLabel")
	satisfactionScore.Name = "SatisfactionScore"
	satisfactionScore.Size = UDim2.new(0.5, 0, 0.3, 0)
	satisfactionScore.Position = UDim2.new(0.25, 0, 0.3, 0)
	satisfactionScore.BackgroundTransparency = 1
	satisfactionScore.TextColor3 = Color3.fromRGB(255, 255, 255)
	satisfactionScore.Font = Enum.Font.GothamBold
	satisfactionScore.TextSize = 48
	satisfactionScore.Text = "100"
	satisfactionScore.Parent = overviewPanel
	
	-- Status Label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
    statusLabel.Position = UDim2.new(0.25, 0, 0.6, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 18
	statusLabel.Text = "Excellent"
	statusLabel.Parent = overviewPanel

    -- Key Factors Container    
    
    keyFactorsContainer.Name = "KeyFactorsContainer"
    keyFactorsContainer.Size = UDim2.fromScale(1, 0.3)
    keyFactorsContainer.Position = UDim2.new(0, 0, 0.8, 0)
    keyFactorsContainer.BackgroundTransparency = 1
    keyFactorsContainer.Parent = overviewPanel

    -- UIListLayout for Key Factors
    local keyFactorsListLayout = Instance.new("UIListLayout")
    keyFactorsListLayout.Name = "KeyFactorsListLayout"
    keyFactorsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    keyFactorsListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    keyFactorsListLayout.FillDirection = Enum.FillDirection.Horizontal
    keyFactorsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    keyFactorsListLayout.Padding = UDim.new(0, 5)
    keyFactorsListLayout.Parent = keyFactorsContainer

    -- Member Retention Label
    local memberRetentionLabel = Instance.new("TextLabel")
    memberRetentionLabel.Name = "MemberRetentionLabel"
    memberRetentionLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
    memberRetentionLabel.Position = UDim2.new(0, 0, 1, 0)
    memberRetentionLabel.BackgroundTransparency = 1
    memberRetentionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    memberRetentionLabel.Text = "Member Retention: 95%"
    memberRetentionLabel.Parent = overviewPanel
	
    -- Revenue Impact Label
    local revenueImpactLabel = Instance.new("TextLabel")
    revenueImpactLabel.Name = "RevenueImpactLabel"
    revenueImpactLabel.Position = UDim2.new(0, 0, 1.2, 0)
    revenueImpactLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
    revenueImpactLabel.BackgroundTransparency = 1
    revenueImpactLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    revenueImpactLabel.Text = "Revenue Impact: +10%"
    revenueImpactLabel.Parent = overviewPanel

	-- Trend Indicator
	local trendIndicator = Instance.new("ImageLabel")
	trendIndicator.Name = "TrendIndicator"
    trendIndicator.Size = UDim2.new(0,30,0,30)
    trendIndicator.Position = UDim2.new(0.75,0,0.4,0)
    trendIndicator.AnchorPoint = Vector2.new(0.5,0)
    trendIndicator.BackgroundTransparency = 1
    

	trendIndicator.Parent = overviewPanel
	
	overviewPanel.Parent = mainFrame
	
	mainFrame.Visible = false

	MemberSatisfactionUI.MainFrame = mainFrame
    
    function MemberSatisfactionUI.clearKeyFactors()
       MemberSatisfactionUI.clearKeyFactors()
    end
    
end

function MemberSatisfactionUI.addKeyFactor(iconId, factorName, value)
    addKeyFactor(iconId,factorName,value)
end
function MemberSatisfactionUI.updateRevenueImpact(value)
    updateRevenueImpact(value)
end
function MemberSatisfactionUI.updateMemberRetention(value)
    updateMemberRetention(value)
end
function MemberSatisfactionUI.updateTrendIndicator(isImproving)
    updateTrendIndicator(isImproving)
end

function MemberSatisfactionUI.openUI()
	if MemberSatisfactionUI.MainFrame then
		MemberSatisfactionUI.MainFrame.Visible = true
	end
end









return {
	init = MemberSatisfactionUI.init,
	openUI = MemberSatisfactionUI.openUI,
}