--lua
--!strict
--[[
    PlayerStatsDisplay.client.luau

    A client-side script to display player statistics (Members, Level, Cash) in the UI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Assuming access to UI modules through ReplicatedStorage.shared for simplicity
local shared = ReplicatedStorage:WaitForChild("shared")
local UIStyle = require(shared:WaitForChild("UIStyle"))
local UIComponents = require(shared:WaitForChild("UIComponents"))

local PlayerStatsDisplay = {}

function PlayerStatsDisplay:initialize()
    -- Create the main container frame
    local statsFrame = UIComponents.createFrame({
        name = "PlayerStatsFrame",
        size = UDim2.new(0.3, 0, 0.1, 0), -- Example size, adjust as needed
        position = UDim2.new(0.5, -UDim2.new(0.3, 0, 0.1, 0).X.Offset / 2, 0, 0), -- Top Center positioning
        anchorPoint = Vector2.new(0.5, 0),
        backgroundColor = UIStyle.colors.background, -- Use UIStyle background color
        backgroundTransparency = 0.2, -- Slightly transparent
        cornerRadius = UIStyle.cornerRadius.Small,
        layoutOrder = 1 -- Ensure it appears at the top
    })

    statsFrame.Parent = PlayerGui

    -- Add a UILayout to manage the children automatically
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 20) -- Add some spacing between stats
    listLayout.Parent = statsFrame

    -- Create TextLabel for Members
    local membersLabel = UIComponents.createLabel({
        name = "MembersLabel",
        size = UDim2.new(1/3, 0, 1, 0),
        text = "Members: --", -- Placeholder text
        textColor = UIStyle.colors.text,
        font = UIStyle.fonts.body,
        textSize = 18,
        backgroundTransparency = 1,
        textXAlignment = Enum.TextXAlignment.Center,
        layoutOrder = 1
    })
    membersLabel.Parent = statsFrame
    
     -- Function to update members text
    local function updateMembersText()
        if LocalPlayer:FindFirstChild("Members") and LocalPlayer.Members:FindFirstChild("Value") then
          membersLabel.Text = "Members: " .. tostring(LocalPlayer.Members.Value)
        end
    end

    -- Run once to show the members when the UI loads
    updateMembersText()
    -- Update whenever the value is changed
    LocalPlayer.Members.Changed:Connect(updateMembersText)


    -- Create TextLabel for Level
    local levelLabel = UIComponents.createLabel({
        name = "LevelLabel",
        size = UDim2.new(1/3, 0, 1, 0),
        text = "Level: --", -- Placeholder text
        textColor = UIStyle.colors.text,
        font = UIStyle.fonts.body,
        textSize = 18,
        backgroundTransparency = 1,
        textXAlignment = Enum.TextXAlignment.Center,
        layoutOrder = 2
    })
    levelLabel.Parent = statsFrame
    
    -- Function to update level text
    local function updateLevelText()
       if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Level") then
          levelLabel.Text = "Level: " .. tostring(LocalPlayer.leaderstats.Level.Value)
        end
    end
    
    -- Run once to show the level when the UI loads
    updateLevelText()

    -- Update whenever the value is changed
    LocalPlayer.leaderstats.Level.Changed:Connect(updateLevelText)


    -- Create TextLabel for Cash
    local cashLabel = UIComponents.createLabel({
        name = "CashLabel",
        size = UDim2.new(1/3, 0, 1, 0),
        text = "Cash: --", -- Placeholder text
        textColor = UIStyle.colors.text,
        font = UIStyle.fonts.body,
        textSize = 18,
        backgroundTransparency = 1,
        textXAlignment = Enum.TextXAlignment.Center,
        layoutOrder = 3
    })
    cashLabel.Parent = statsFrame
    
      -- Function to update cash text
    local function updateCashText()
        if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Cash") then
          cashLabel.Text = "Cash: " .. tostring(LocalPlayer.leaderstats.Cash.Value)
        end
    end

    -- Run once to show the cash when the UI loads
    updateCashText()

    -- Update whenever the value is changed
    LocalPlayer.leaderstats.Cash.Changed:Connect(updateCashText)


    -- You might want to store references to these labels to update them later
    self.membersLabel = membersLabel
    self.levelLabel = levelLabel
    self.cashLabel = cashLabel

    print("PlayerStatsDisplay initialized and UI created.")
end

return PlayerStatsDisplay