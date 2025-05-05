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
    UpdateFrequency = 0.5  -- How often to check player distance
}

-- Local variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local soccerField = script.Parent
local fieldPart = soccerField:FindFirstChild("field") or soccerField.PrimaryPart
local scoreboard
local lastCheck = 0

-- Function to get the field part with improved error handling
local function getFieldPart()
    if fieldPart then return fieldPart end
    
    -- Try to find a field part
    if soccerField.PrimaryPart then
        fieldPart = soccerField.PrimaryPart
        print("Using PrimaryPart as field reference")
        return fieldPart
    end
    
    -- Search for a part named "field" or "Field" first
    for _, part in ipairs(soccerField:GetDescendants()) do
        if part:IsA("BasePart") and 
           (part.Name:lower():find("field") or 
            part.Name:lower() == "field" or 
            part.Name:lower() == "soccerfield") then
            
            fieldPart = part
            print("Found field part with name:", part.Name)
            return fieldPart
        end
    end
    
    -- If still not found, use any BasePart (as a last resort)
    for _, part in ipairs(soccerField:GetDescendants()) do
        if part:IsA("BasePart") then
            fieldPart = part
            warn("No field part found, using:", part.Name)
            return fieldPart
        end
    end
    
    warn("Could not find any BasePart to use as field reference")
    return nil
end

-- Function to get the scoreboard reference with retries
local function getScoreboard()
    -- Look for common scoreboard names
    local possibleNames = {"Scoreboard", "ScoreBoard", "Score", "ScoreDisplay"}
    
    for _, name in ipairs(possibleNames) do
        local found = soccerField:FindFirstChild(name)
        if found then
            return found
        end
    end
    
    -- Not found with common names, search more broadly
    for _, child in ipairs(soccerField:GetChildren()) do
        if child:IsA("BillboardGui") or 
           child:IsA("SurfaceGui") or 
           (child:IsA("Model") and 
            (child:FindFirstChildWhichIsA("BillboardGui") or 
             child:FindFirstChildWhichIsA("SurfaceGui"))) then
            
            return child
        end
    end
    
    return nil
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
        warn("No field part reference, can't calculate distance")
        return
    end
    
    -- Calculate distance to the field
    local distance = (humanoidRootPart.Position - field.Position).Magnitude
    
    -- Toggle visibility based on distance
    if distance <= CONFIG.ScoreboardVisibilityDistance then
        if not scoreboard.Enabled then
            scoreboard.Enabled = true
        end
    else
        if scoreboard.Enabled then
            scoreboard.Enabled = false
        end
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
        warn("SoccerFieldClient: Could not find any field part. Will keep trying...")
        
        -- Set up a retry loop
        task.spawn(function()
            local attempts = 0
            while not fieldPart and attempts < 10 do
                task.wait(1)
                attempts = attempts + 1
                fieldPart = getFieldPart()
                if fieldPart then
                    print("SoccerFieldClient: Found field part on attempt", attempts)
                    break
                end
            end
            
            if not fieldPart then
                warn("SoccerFieldClient: Failed to find field part after", attempts, "attempts")
            end
        end)
    end
    
    -- Get current scoreboard
    scoreboard = getScoreboard()
    if not scoreboard then
        warn("SoccerFieldClient: Could not find scoreboard. Will keep trying...")
        
        -- Set up a retry loop
        task.spawn(function()
            local attempts = 0
            while not scoreboard and attempts < 10 do
                task.wait(1)
                attempts = attempts + 1
                scoreboard = getScoreboard()
                if scoreboard then
                    print("SoccerFieldClient: Found scoreboard on attempt", attempts)
                    break
                end
            end
            
            if not scoreboard then
                warn("SoccerFieldClient: Failed to find scoreboard after", attempts, "attempts")
            else
                -- Initially hide the scoreboard until we check distance
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
    
    print("SoccerFieldClient: Setup complete. Scoreboard will only be visible within", 
          CONFIG.ScoreboardVisibilityDistance, "studs of the field.")
end

-- Run setup
setup()
