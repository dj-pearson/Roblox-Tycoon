-- Interactive Soccer Game Client Script
-- Place this script as a LocalScript in the SoccerField model

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    -- Scoreboard
    ScoreboardVisibilityDistance = 30,  -- Maximum distance to show scoreboard
    Team1Name = "HOME",
    Team2Name = "AWAY",
    UpdateFrequency = 0.5,  -- How often to check player distance
    AutoCreateScoreboard = true, -- Create a scoreboard if none exists
    ScoreboardHeight = 6    -- Height above field
}

-- Local variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local soccerField = script.Parent
local fieldPart = soccerField:FindFirstChild("field") or soccerField.PrimaryPart
local scoreboard
local lastCheck = 0

-- Create debug printing function
local function debugPrint(message, level)
    local prefix = "[SoccerField]"
    if level == "Warning" then
        warn(prefix .. " " .. message)
    elseif level == "Error" then
        error(prefix .. " " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Function to get the field part with improved error handling
local function getFieldPart()
    if fieldPart then return fieldPart end
    
    -- Try to find a field part
    if soccerField.PrimaryPart then
        fieldPart = soccerField.PrimaryPart
        debugPrint("Using PrimaryPart as field reference")
        return fieldPart
    end
    
    -- Search for a part named "field" or "Field" first
    for _, part in ipairs(soccerField:GetDescendants()) do
        if part:IsA("BasePart") and 
           (part.Name:lower():find("field") or 
            part.Name:lower() == "field" or 
            part.Name:lower() == "soccerfield") then
            
            fieldPart = part
            debugPrint("Found field part with name: " .. part.Name)
            return fieldPart
        end
    end
    
    -- If still not found, use any BasePart (as a last resort)
    for _, part in ipairs(soccerField:GetDescendants()) do
        if part:IsA("BasePart") then
            fieldPart = part
            debugPrint("No field part found, using: " .. part.Name, "Warning")
            return fieldPart
        end
    end
    
    debugPrint("Could not find any BasePart to use as field reference", "Warning")
    return nil
end

-- Function to get the scoreboard reference with retries
local function getScoreboard()
    -- Look for common scoreboard names
    local possibleNames = {"Scoreboard", "ScoreBoard", "Score", "ScoreDisplay"}
    
    for _, name in ipairs(possibleNames) do
        local found = soccerField:FindFirstChild(name)
        if found and (found:IsA("BillboardGui") or found:IsA("SurfaceGui")) then
            debugPrint("Found scoreboard with name: " .. name)
            return found
        end
    end
    
    -- Not found with common names, search more broadly
    for _, child in ipairs(soccerField:GetDescendants()) do
        if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
            debugPrint("Found scoreboard UI: " .. child:GetFullName())
            return child
        end
        
        if child:IsA("Model") then
            local uiChild = child:FindFirstChildWhichIsA("BillboardGui") or child:FindFirstChildWhichIsA("SurfaceGui")
            if uiChild then
                debugPrint("Found scoreboard UI in model: " .. uiChild:GetFullName())
                return uiChild
            end
        end
    end
    
    -- If auto-create is enabled and we have a field part, create a scoreboard
    if CONFIG.AutoCreateScoreboard then
        local field = getFieldPart()
        if field then
            return createScoreboard(field)
        end
    end
    
    return nil
end

-- Create a scoreboard if one doesn't exist
local function createScoreboard(fieldPart)
    if not fieldPart then return nil end
    
    debugPrint("Creating new scoreboard")
    
    local board = Instance.new("BillboardGui")
    board.Name = "Scoreboard"
    board.Size = UDim2.new(0, 250, 0, 120)
    board.StudsOffset = Vector3.new(0, CONFIG.ScoreboardHeight, 0)
    board.MaxDistance = 100  -- Maximum render distance
    board.AlwaysOnTop = true
    board.Enabled = false  -- Start hidden until we check distance
    board.Adornee = fieldPart
    board.Parent = soccerField
    
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
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.BackgroundTransparency = 1
    title.Text = "SCOREBOARD"
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Parent = background
    
    -- Create team names
    local team1Label = Instance.new("TextLabel")
    team1Label.Name = "Team1Label"
    team1Label.Size = UDim2.new(0.45, 0, 0.5, 0)
    team1Label.Position = UDim2.new(0.025, 0, 0.4, 0)
    team1Label.BackgroundTransparency = 1
    team1Label.Text = CONFIG.Team1Name
    team1Label.Font = Enum.Font.SourceSans
    team1Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    team1Label.TextScaled = true
    team1Label.Parent = background
    
    local team2Label = Instance.new("TextLabel")
    team2Label.Name = "Team2Label"
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
    score1.Name = "Score1"
    score1.Size = UDim2.new(0.2, 0, 0.5, 0)
    score1.Position = UDim2.new(0.15, 0, 0.7, 0)
    score1.BackgroundTransparency = 1
    score1.Text = "0"
    score1.Font = Enum.Font.SourceSansBold
    score1.TextColor3 = Color3.fromRGB(255, 255, 100)
    score1.TextScaled = true
    score1.Parent = background
    
    local score2 = Instance.new("TextLabel")
    score2.Name = "Score2"
    score2.Size = UDim2.new(0.2, 0, 0.5, 0)
    score2.Position = UDim2.new(0.65, 0, 0.7, 0)
    score2.BackgroundTransparency = 1
    score2.Text = "0"
    score2.Font = Enum.Font.SourceSansBold
    score2.TextColor3 = Color3.fromRGB(255, 255, 100)
    score2.TextScaled = true
    score2.Parent = background
    
    -- Create divider
    local divider = Instance.new("TextLabel")
    divider.Name = "Divider"
    divider.Size = UDim2.new(0.1, 0, 0.5, 0)
    divider.Position = UDim2.new(0.45, 0, 0.7, 0)
    divider.BackgroundTransparency = 1
    divider.Text = "-"
    divider.Font = Enum.Font.SourceSansBold
    divider.TextColor3 = Color3.fromRGB(255, 255, 255)
    divider.TextScaled = true
    divider.Parent = background
    
    debugPrint("Created new scoreboard successfully")
    return board
end

-- Function to toggle scoreboard visibility based on proximity
local function updateScoreboardVisibility()
    local currentTime = tick()
    
    -- Only check every CONFIG.UpdateFrequency seconds to avoid unnecessary calculations
    if currentTime - lastCheck < CONFIG.UpdateFrequency then
        return
    end
    lastCheck = currentTime
    
    -- Get references
    if not scoreboard then
        scoreboard = getScoreboard()
        if not scoreboard then return end
    end
    
    -- Make sure character exists
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        character = player.Character
        if not character then
            if scoreboard and scoreboard.Enabled then
                scoreboard.Enabled = false
            end
            return
        end
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            if scoreboard and scoreboard.Enabled then
                scoreboard.Enabled = false
            end
            return
        end
    end
    
    -- Get the field part reference
    local field = getFieldPart()
    if not field then
        -- Can't determine distance without a field reference
        debugPrint("No field part reference, can't calculate distance", "Warning")
        return
    end
    
    -- Calculate distance to the field
    local distance = (humanoidRootPart.Position - field.Position).Magnitude
    
    -- Toggle visibility based on distance
    if distance <= CONFIG.ScoreboardVisibilityDistance then
        if not scoreboard.Enabled then
            scoreboard.Enabled = true
            debugPrint("Showing scoreboard (distance: " .. math.floor(distance) .. ")")
        end
    else
        if scoreboard.Enabled then
            scoreboard.Enabled = false
            debugPrint("Hiding scoreboard (distance: " .. math.floor(distance) .. ")")
        end
    end
    
    -- Ensure team labels and scores are visible and properly named
    if scoreboard.Enabled then
        -- Look for background frame
        local background = scoreboard:FindFirstChild("Background")
        if background then
            -- Check team labels
            local team1Label = background:FindFirstChild("Team1Label")
            if not team1Label then
                -- Try to find by different names
                team1Label = background:FindFirstChildOfClass("TextLabel")
                if team1Label and (team1Label.Text:lower():find("home") or team1Label.Text == CONFIG.Team1Name) then
                    team1Label.Name = "Team1Label"
                else
                    -- Create if not found
                    team1Label = Instance.new("TextLabel")
                    team1Label.Name = "Team1Label"
                    team1Label.Size = UDim2.new(0.45, 0, 0.5, 0)
                    team1Label.Position = UDim2.new(0.025, 0, 0.4, 0)
                    team1Label.BackgroundTransparency = 1
                    team1Label.Text = CONFIG.Team1Name
                    team1Label.Font = Enum.Font.SourceSans
                    team1Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                    team1Label.TextScaled = true
                    team1Label.Parent = background
                end
            end
            
            -- Check team labels visibility and content
            if team1Label then
                team1Label.Visible = true
                team1Label.Text = CONFIG.Team1Name
            end
            
            local team2Label = background:FindFirstChild("Team2Label")
            if not team2Label then
                -- Try to find by different names
                for _, label in pairs(background:GetChildren()) do
                    if label:IsA("TextLabel") and label ~= team1Label and
                      (label.Text:lower():find("away") or label.Text == CONFIG.Team2Name) then
                        team2Label = label
                        team2Label.Name = "Team2Label"
                        break
                    end
                end
                
                if not team2Label then
                    -- Create if not found
                    team2Label = Instance.new("TextLabel")
                    team2Label.Name = "Team2Label"
                    team2Label.Size = UDim2.new(0.45, 0, 0.5, 0)
                    team2Label.Position = UDim2.new(0.525, 0, 0.4, 0)
                    team2Label.BackgroundTransparency = 1
                    team2Label.Text = CONFIG.Team2Name
                    team2Label.Font = Enum.Font.SourceSans
                    team2Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                    team2Label.TextScaled = true
                    team2Label.Parent = background
                end
            end
            
            -- Set team 2 label visibility
            if team2Label then
                team2Label.Visible = true
                team2Label.Text = CONFIG.Team2Name
            end
            
            -- Check score labels
            local score1 = background:FindFirstChild("Score1")
            if not score1 then
                for _, label in pairs(background:GetChildren()) do
                    if label:IsA("TextLabel") and (tonumber(label.Text) ~= nil or label.Text == "0") then
                        score1 = label
                        score1.Name = "Score1"
                        break
                    end
                end
                
                if not score1 then
                    score1 = Instance.new("TextLabel")
                    score1.Name = "Score1"
                    score1.Size = UDim2.new(0.2, 0, 0.5, 0)
                    score1.Position = UDim2.new(0.15, 0, 0.7, 0)
                    score1.BackgroundTransparency = 1
                    score1.Text = "0"
                    score1.Font = Enum.Font.SourceSansBold
                    score1.TextColor3 = Color3.fromRGB(255, 255, 100)
                    score1.TextScaled = true
                    score1.Parent = background
                end
            end
            
            if score1 then
                score1.Visible = true
            end
            
            local score2 = background:FindFirstChild("Score2")
            if not score2 then
                for _, label in pairs(background:GetChildren()) do
                    if label:IsA("TextLabel") and label ~= score1 and (tonumber(label.Text) ~= nil or label.Text == "0") then
                        score2 = label
                        score2.Name = "Score2"
                        break
                    end
                end
                
                if not score2 then
                    score2 = Instance.new("TextLabel")
                    score2.Name = "Score2"
                    score2.Size = UDim2.new(0.2, 0, 0.5, 0)
                    score2.Position = UDim2.new(0.65, 0, 0.7, 0)
                    score2.BackgroundTransparency = 1
                    score2.Text = "0"
                    score2.Font = Enum.Font.SourceSansBold
                    score2.TextColor3 = Color3.fromRGB(255, 255, 100)
                    score2.TextScaled = true
                    score2.Parent = background
                end
            end
            
            if score2 then
                score2.Visible = true
            end
            
            -- Make sure divider exists
            local divider = background:FindFirstChild("Divider")
            if not divider then
                divider = Instance.new("TextLabel")
                divider.Name = "Divider"
                divider.Size = UDim2.new(0.1, 0, 0.5, 0)
                divider.Position = UDim2.new(0.45, 0, 0.7, 0)
                divider.BackgroundTransparency = 1
                divider.Text = "-"
                divider.Font = Enum.Font.SourceSansBold
                divider.TextColor3 = Color3.fromRGB(255, 255, 255)
                divider.TextScaled = true
                divider.Parent = background
            end
            
            if divider then
                divider.Visible = true
            end
        end
    end
end

-- Function to update scores (can be called by server scripts)
local function updateScores(team1Score, team2Score)
    if not scoreboard then
        scoreboard = getScoreboard()
        if not scoreboard then return end
    end
    
    local background = scoreboard:FindFirstChild("Background")
    if not background then return end
    
    local score1 = background:FindFirstChild("Score1")
    local score2 = background:FindFirstChild("Score2")
    
    if score1 and team1Score ~= nil then
        score1.Text = tostring(team1Score)
    end
    
    if score2 and team2Score ~= nil then
        score2.Text = tostring(team2Score)
    end
end

-- Player character changes
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

-- Setup function
local function setup()
    -- Get or find the field part
    fieldPart = getFieldPart()
    if not fieldPart then
        debugPrint("Could not find any field part. Will keep trying...", "Warning")
        
        -- Set up a retry loop
        task.spawn(function()
            local attempts = 0
            while not fieldPart and attempts < 10 do
                task.wait(1)
                attempts = attempts + 1
                fieldPart = getFieldPart()
                if fieldPart then
                    debugPrint("Found field part on attempt " .. attempts)
                    break
                end
            end
            
            if not fieldPart then
                debugPrint("Failed to find field part after " .. attempts .. " attempts", "Warning")
            end
        end)
    end
    
    -- Get current scoreboard
    scoreboard = getScoreboard()
    if not scoreboard then
        debugPrint("Could not find scoreboard. Will keep trying...", "Warning")
        
        -- Set up a retry loop
        task.spawn(function()
            local attempts = 0
            while not scoreboard and attempts < 10 do
                task.wait(1)
                attempts = attempts + 1
                scoreboard = getScoreboard()
                if scoreboard then
                    debugPrint("Found scoreboard on attempt " .. attempts)
                    break
                end
            end
            
            if not scoreboard then
                debugPrint("Failed to find scoreboard after " .. attempts .. " attempts, creating one", "Warning")
                local field = getFieldPart()
                if field then
                    scoreboard = createScoreboard(field)
                    if scoreboard then
                        debugPrint("Created new scoreboard successfully")
                    end
                end
            end
            
            -- Initially hide the scoreboard until we check distance
            if scoreboard then
                scoreboard.Enabled = false
            end
        end)
    else
        -- Initially hide the scoreboard until we check distance
        scoreboard.Enabled = false
    end
    
    -- Connect update function
    RunService.Heartbeat:Connect(updateScoreboardVisibility)
    
    -- Listen for character changes
    player.CharacterAdded:Connect(onCharacterAdded)
    
    -- Expose update scores function to _G for server scripts to use
    _G.updateSoccerScores = updateScores
    
    debugPrint("Setup complete. Scoreboard will only be visible within " .. 
          CONFIG.ScoreboardVisibilityDistance .. " studs of the field.")
end

-- Run setup
setup()
