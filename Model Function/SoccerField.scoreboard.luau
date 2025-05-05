-- Soccer Field Scoreboard Setup
-- This should be added to or replace the existing scoreboard creation code in SoccerField.luau

-- Create the scoreboard
local function createScoreboard()
    if not CONFIG.EnableScoreboard then return end
    
    local board = Instance.new("BillboardGui")
    board.Name = "Scoreboard"
    board.Size = UDim2.new(0, 250, 0, 120)
    board.StudsOffset = Vector3.new(0, 6, 0)
    board.MaxDistance = 100  -- Maximum render distance
    board.AlwaysOnTop = true
    
    -- Initially hidden - will be controlled by client script based on proximity
    board.Enabled = false
    
    -- Attach to the field
    local fieldPart = soccerField:FindFirstChild("field") or soccerField.PrimaryPart
    if fieldPart then
        board.Adornee = fieldPart
    else
        -- Find any part to adorn if field part not found
        for _, part in ipairs(soccerField:GetDescendants()) do
            if part:IsA("BasePart") then
                board.Adornee = part
                break
            end
        end
    end
    
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    background.BackgroundTransparency = 0.3
    background.BorderSizePixel = 0
    background.Parent = board
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = background
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.BackgroundTransparency = 1
    title.Text = "SCOREBOARD"
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Parent = background
    
    -- Create team names
    local team1Label = Instance.new("TextLabel")
    team1Label.Size = UDim2.new(0.45, 0, 0.5, 0)
    team1Label.Position = UDim2.new(0.025, 0, 0.4, 0)
    team1Label.BackgroundTransparency = 1
    team1Label.Text = CONFIG.Team1Name
    team1Label.Font = Enum.Font.SourceSans
    team1Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    team1Label.TextScaled = true
    team1Label.Parent = background
    
    local team2Label = Instance.new("TextLabel")
    team2Label.Size = UDim2.new(0.45, 0, 0.5, 0)
    team2Label.Position = UDim2.new(0.525, 0, 0.4, 0)
    team2Label.BackgroundTransparency = 1
    team2Label.Text = CONFIG.Team2Name
    team2Label.Font = Enum.Font.SourceSans
    team2Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    team2Label.TextScaled = true
    team2Label.Parent = background
    
    -- Create score displays
    local score1 = Instance.new("TextLabel")
    score1.Size = UDim2.new(0.2, 0, 0.5, 0)
    score1.Position = UDim2.new(0.15, 0, 0.7, 0)
    score1.BackgroundTransparency = 1
    score1.Text = "0"
    score1.Font = Enum.Font.SourceSansBold
    score1.TextColor3 = Color3.fromRGB(255, 255, 100)
    score1.TextScaled = true
    score1.Name = "Score1"
    score1.Parent = background
    
    local score2 = Instance.new("TextLabel")
    score2.Size = UDim2.new(0.2, 0, 0.5, 0)
    score2.Position = UDim2.new(0.65, 0, 0.7, 0)
    score2.BackgroundTransparency = 1
    score2.Text = "0"
    score2.Font = Enum.Font.SourceSansBold
    score2.TextColor3 = Color3.fromRGB(255, 255, 100)
    score2.TextScaled = true
    score2.Name = "Score2"
    score2.Parent = background
    
    -- Create divider
    local divider = Instance.new("TextLabel")
    divider.Size = UDim2.new(0.1, 0, 0.5, 0)
    divider.Position = UDim2.new(0.45, 0, 0.7, 0)
    divider.BackgroundTransparency = 1
    divider.Text = "-"
    divider.Font = Enum.Font.SourceSansBold
    divider.TextColor3 = Color3.fromRGB(255, 255, 255)
    divider.TextScaled = true
    divider.Parent = background
    
    board.Parent = soccerField
    scoreboard = board
    
    -- Create a LocalScript to handle proximity-based visibility
    local clientScript = Instance.new("LocalScript")
    clientScript.Name = "ScoreboardProximityHandler"
    clientScript.Source = [[
        -- This will be replaced during deployment with the full client script
        -- For now, we'll use this placeholder to remind us to add the client script
        print("SoccerField: Remember to add the SoccerField.client.luau script!")
    ]]
    clientScript.Parent = soccerField
    
    return board
end
