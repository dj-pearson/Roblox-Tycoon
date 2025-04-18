--[[
    BasketballSystem.luau
    Manages basketball courts, game sessions, scoring, and player interactions
    Part of the Core systems architecture
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- System Dependencies
local CoreRegistry
local EventBridge
local DataManager

-- Configuration
local CONFIG = {
    -- Basketball court setup
    basketballCourtTag = "BasketballCourt",
    hoopTag = "BasketballHoop",
    
    -- Game settings
    defaultGameDuration = 120, -- 2 minutes
    shotClockDuration = 24, -- 24 seconds
    pointsForScore = 2, -- Default points for scoring
    pointsForThreePoint = 3, -- Points from beyond three-point line
    
    -- Net animation
    netAnimationSpeed = 0.03, -- How fast the net moves
    netDefaultScale = Vector3.new(2.4, 2.7, 2.4),
    
    -- Sound effects
    soundIds = {
        basketballBounce = "rbxassetid://131010940",
        scoreSound = "rbxassetid://3748776946",
        buzzerSound = "rbxassetid://1548304764",
        cheerSound = "rbxassetid://5853344708"
    },
    
    -- Visual effects
    backboardLightDuration = 1.5, -- How long the backboard light stays on
    
    -- Physics settings
    ballBounciness = 0.8,
    
    -- Achievement thresholds
    achievements = {
        basketsMade = {10, 50, 100, 500},
        gamesPlayed = {5, 20, 50, 100},
        highScore = {20, 50, 100, 200}
    },
    
    -- Debug
    debug = true
}

-- Module table
local BasketballSystem = {
    _name = "BasketballSystem",
    _version = "1.0.0",
    _dependencies = {"CoreRegistry", "EventBridge", "DataManager"},
    
    -- Internal state
    _basketballCourts = {}, -- Stores all basketball courts
    _activeSessions = {}, -- Active game sessions
    _playerStats = {}, -- Player basketball statistics
    _cleanupTasks = {} -- Cleanup tasks for connections
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[Basketball System]", ...)
    end
end

--[[ Core Functions ]]--

-- Find all basketball courts in the workspace
function BasketballSystem:_findBasketballCourts()
    local courts = {}
    
    -- Look for tagged courts
    for _, courtModel in pairs(CollectionService:GetTagged(CONFIG.basketballCourtTag)) do
        local court = {
            model = courtModel,
            name = courtModel.Name,
            hoops = {},
            scoreboards = {},
            players = {},
            balls = {},
            gameInProgress = false,
            gameState = {
                timeRemaining = 0,
                scores = {
                    team1 = 0,
                    team2 = 0
                },
                shotClock = 0,
                period = 1
            }
        }
        
        -- Find hoops in the court
        for _, hoop in pairs(CollectionService:GetTagged(CONFIG.hoopTag)) do
            if hoop:IsDescendantOf(courtModel) then
                table.insert(court.hoops, hoop)
            end
        end
        
        -- Find the scoreboard
        local scoreboard = courtModel:FindFirstChild("Scoreboard")
        if scoreboard then
            court.scoreboard = scoreboard
        end
        
        -- Find any existing basketballs
        for _, child in pairs(courtModel:GetDescendants()) do
            if child.Name == "Basketball" and child:IsA("BasePart") then
                table.insert(court.balls, child)
            end
        end
        
        table.insert(courts, court)
        debugPrint("Found basketball court:", court.name, "with", #court.hoops, "hoops")
    end
    
    return courts
end

-- Set up a basketball court
function BasketballSystem:_setupBasketballCourt(court)
    -- Set up hoops
    for _, hoop in pairs(court.hoops) do
        self:_setupHoop(hoop, court)
    end
    
    -- Set up the scoreboard
    if court.scoreboard then
        self:_setupScoreboard(court.scoreboard, court)
    end
    
    -- Create folder for shared values if needed
    local guiFolder = workspace:FindFirstChild("GuiFolder")
    if not guiFolder then
        guiFolder = Instance.new("Folder")
        guiFolder.Name = "GuiFolder"
        guiFolder.Parent = workspace
        
        -- Create shared values for scoreboard
        local timeValue = Instance.new("NumberValue")
        timeValue.Name = "Time"
        timeValue.Value = CONFIG.defaultGameDuration
        timeValue.Parent = guiFolder
        
        local team1Score = Instance.new("NumberValue")
        team1Score.Name = "Team1Score"
        team1Score.Value = 0
        team1Score.Parent = guiFolder
        
        local team2Score = Instance.new("NumberValue")
        team2Score.Name = "Team2Score"
        team2Score.Value = 0
        team2Score.Parent = guiFolder
        
        local oneBonus = Instance.new("BoolValue")
        oneBonus.Name = "OneBonus"
        oneBonus.Value = false
        oneBonus.Parent = guiFolder
        
        local twoBonus = Instance.new("BoolValue")
        twoBonus.Name = "TwoBonus"
        twoBonus.Value = false
        twoBonus.Parent = guiFolder
        
        local shotClockValue = Instance.new("NumberValue")
        shotClockValue.Name = "ShotClock"
        shotClockValue.Value = CONFIG.shotClockDuration
        shotClockValue.Parent = guiFolder
    end
    
    -- Set up ball spawner
    local ballSpawner = court.model:FindFirstChild("BallSpawner")
    if ballSpawner then
        local clickDetector = ballSpawner:FindFirstChildOfClass("ClickDetector") or Instance.new("ClickDetector")
        clickDetector.Parent = ballSpawner
        
        -- Store connection for cleanup
        local connection = clickDetector.MouseClick:Connect(function(player)
            self:_spawnBasketball(court, player, ballSpawner.CFrame)
        end)
        
        table.insert(self._cleanupTasks, connection)
    end
    
    -- Check for control panel
    local controlPanel = court.model:FindFirstChild("ControlPanel")
    if controlPanel then
        local startButton = controlPanel:FindFirstChild("StartButton")
        if startButton then
            local clickDetector = startButton:FindFirstChildOfClass("ClickDetector") or Instance.new("ClickDetector")
            clickDetector.Parent = startButton
            
            -- Store connection for cleanup
            local connection = clickDetector.MouseClick:Connect(function(player)
                self:_startGame(court, player)
            end)
            
            table.insert(self._cleanupTasks, connection)
        end
        
        local resetButton = controlPanel:FindFirstChild("ResetButton")
        if resetButton then
            local clickDetector = resetButton:FindFirstChildOfClass("ClickDetector") or Instance.new("ClickDetector")
            clickDetector.Parent = resetButton
            
            -- Store connection for cleanup
            local connection = clickDetector.MouseClick:Connect(function(player)
                self:_resetGame(court, player)
            end)
            
            table.insert(self._cleanupTasks, connection)
        end
    end
    
    return court
end

-- Set up a basketball hoop
function BasketballSystem:_setupHoop(hoop, court)
    -- Make sure it has a trigger for scoring
    local scoreTrigger = hoop:FindFirstChild("ScoreTrigger")
    if not scoreTrigger and hoop:IsA("Model") then
        -- Try to find a likely candidate for score detection
        for _, part in pairs(hoop:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name == "Trigger" or part.Name == "Net" or part.Name == "Rim") then
                scoreTrigger = part
                break
            end
        end
    end
    
    if scoreTrigger and scoreTrigger:IsA("BasePart") then
        local teamValue = Instance.new("StringValue")
        teamValue.Name = "Team"
        teamValue.Value = "Team" .. (hoop:GetAttribute("TeamNumber") or 1)
        teamValue.Parent = hoop
        
        -- Add scoreTrigger detector
        local connection = scoreTrigger.Touched:Connect(function(hit)
            self:_handleHoopTouched(hit, hoop, court)
        end)
        
        table.insert(self._cleanupTasks, connection)
    end
    
    -- Create swish flag if it doesn't exist
    if not hoop:FindFirstChild("swish") then
        local swishValue = Instance.new("BoolValue")
        swishValue.Name = "swish"
        swishValue.Value = false
        swishValue.Parent = hoop
    end
    
    return hoop
end

-- Set up a scoreboard
function BasketballSystem:_setupScoreboard(scoreboard, court)
    -- No active setup needed for scoreboard, but we'll make sure it has
    -- the necessary parts for updating later
    court.scoreboard = scoreboard
    
    -- Initialize scoreboard with default values
    if EventBridge then
        EventBridge:fireEvent("ScoreboardUpdated", {
            court = court.name,
            team1Score = 0,
            team2Score = 0,
            timeRemaining = CONFIG.defaultGameDuration,
            shotClock = CONFIG.shotClockDuration,
            period = 1
        })
    end
    
    return scoreboard
end

-- Handle when a basketball touches a hoop
function BasketballSystem:_handleHoopTouched(hit, hoop, court)
    -- Check if it's a basketball
    if not hit or not hit.Parent or hit.Parent.Name ~= "Basketball" then
        return
    end
    
    local basketball = hit.Parent
    
    -- Get ball owner
    local owner = basketball:GetAttribute("Owner")
    local player = Players:GetPlayerByUserId(owner)
    
    -- Check if ball is moving downward
    local velocity = basketball:GetVelocity()
    if velocity.Y < 0 then
        -- Ball is going through the hoop
        hoop.swish.Value = true
        
        -- Play net animation
        local net = hoop:FindFirstChild("Net")
        if net and net:FindFirstChild("Mesh") then
            -- Animate net - more optimized version than original
            task.spawn(function()
                local mesh = net.Mesh
                local defaultScale = mesh.Scale
                local scales = {
                    Vector3.new(2.4, 2.7, 2.4),
                    Vector3.new(2.4, 2.4, 2.4),
                    Vector3.new(2.4, 2.1, 2.4),
                    Vector3.new(2.4, 1.8, 2.4),
                    Vector3.new(2.4, 1.5, 2.4),
                    Vector3.new(2.4, 1.9, 2.4),
                    Vector3.new(2.4, 2.3, 2.4),
                    Vector3.new(2.4, 2.7, 2.4),
                    Vector3.new(2.4, 3.2, 2.4),
                    Vector3.new(2.4, 2.7, 2.4)
                }
                
                for _, scale in ipairs(scales) do
                    mesh.Scale = scale
                    task.wait(CONFIG.netAnimationSpeed)
                end
                
                mesh.Scale = defaultScale
            end)
        end
        
        -- Light up backboard
        local top = hoop:FindFirstChild("Top")
        if top and top:FindFirstChild("PointLight") then
            task.spawn(function()
                local light = top.PointLight
                light.Enabled = true
                
                -- Fade in and out
                for i = 1, 10 do
                    top.Transparency = 1 - (i / 10)
                    task.wait(CONFIG.backboardLightDuration / 20)
                end
                
                for i = 10, 1, -1 do
                    top.Transparency = 1 - (i / 10)
                    task.wait(CONFIG.backboardLightDuration / 20)
                end
                
                light.Enabled = false
            end)
        end
        
        -- Update score
        local teamValue = hoop:FindFirstChild("Team")
        local teamName = teamValue and teamValue.Value or "Team1"
        local points = self:_calculatePoints(basketball, hoop)
        
        if court.gameInProgress then
            if teamName == "Team1" then
                court.gameState.scores.team1 = court.gameState.scores.team1 + points
            else
                court.gameState.scores.team2 = court.gameState.scores.team2 + points
            end
            
            -- Update scoreboard
            if EventBridge then
                EventBridge:fireEvent("ScoreboardUpdated", {
                    court = court.name,
                    team1Score = court.gameState.scores.team1,
                    team2Score = court.gameState.scores.team2,
                    timeRemaining = court.gameState.timeRemaining,
                    shotClock = court.gameState.shotClock,
                    period = court.gameState.period
                })
            end
            
            -- Reset shot clock after score
            court.gameState.shotClock = CONFIG.shotClockDuration
        end
        
        -- Update player stats
        if player then
            self:_updatePlayerStats(player, "score", points)
            
            -- Notify player
            if EventBridge then
                EventBridge:fireClient("BasketScored", player, {
                    points = points,
                    gameStats = self:GetPlayerStats(player)
                })
            end
        end
        
        -- Play sound
        local sound = Instance.new("Sound")
        sound.SoundId = CONFIG.soundIds.scoreSound
        sound.Volume = 1
        sound.Parent = hoop
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
        
        -- Reset swish for next time
        task.delay(1, function()
            if hoop and hoop:FindFirstChild("swish") then
                hoop.swish.Value = false
            end
        end)
        
        -- Fire event for other systems
        if EventBridge then
            EventBridge:fireEvent("BasketballScored", {
                court = court.name,
                player = player,
                points = points,
                position = basketball:GetPivot().Position
            })
        end
    end
end

-- Calculate points based on distance from hoop
function BasketballSystem:_calculatePoints(basketball, hoop)
    -- Get position of ball and hoop
    local ballPos = basketball:GetPivot().Position
    local hoopPos
    
    -- Find hoop position
    if hoop:IsA("BasePart") then
        hoopPos = hoop.Position
    elseif hoop:IsA("Model") and hoop.PrimaryPart then
        hoopPos = hoop.PrimaryPart.Position
    else
        -- Try to find rim part
        local rim = hoop:FindFirstChild("Rim")
        if rim and rim:IsA("BasePart") then
            hoopPos = rim.Position
        else
            -- Default to first part
            for _, part in pairs(hoop:GetDescendants()) do
                if part:IsA("BasePart") then
                    hoopPos = part.Position
                    break
                end
            end
        end
    end
    
    if not hoopPos then
        return CONFIG.pointsForScore -- Default
    end
    
    -- Check horizontal distance (ignore height difference)
    local horizontalPos1 = Vector3.new(ballPos.X, 0, ballPos.Z)
    local horizontalPos2 = Vector3.new(hoopPos.X, 0, hoopPos.Z)
    local distance = (horizontalPos1 - horizontalPos2).Magnitude
    
    -- Check against three-point line (typically around 7.24 meters or ~24 studs)
    if distance > 24 then
        return CONFIG.pointsForThreePoint
    end
    
    return CONFIG.pointsForScore
end

-- Start a new game on a court
function BasketballSystem:_startGame(court, player)
    if court.gameInProgress then
        debugPrint("Game already in progress")
        return false
    end
    
    -- Initialize or reset game state
    court.gameState = {
        timeRemaining = CONFIG.defaultGameDuration,
        scores = {
            team1 = 0,
            team2 = 0
        },
        shotClock = CONFIG.shotClockDuration,
        period = 1
    }
    
    court.gameInProgress = true
    
    -- Update scoreboard
    if EventBridge then
        EventBridge:fireEvent("ScoreboardUpdated", {
            court = court.name,
            team1Score = 0,
            team2Score = 0,
            timeRemaining = CONFIG.defaultGameDuration,
            shotClock = CONFIG.shotClockDuration,
            period = 1
        })
    end
    
    -- Start game clock
    court.gameClockTask = task.spawn(function()
        while court.gameInProgress and court.gameState.timeRemaining > 0 do
            task.wait(1)
            
            -- Update time
            court.gameState.timeRemaining = court.gameState.timeRemaining - 1
            court.gameState.shotClock = math.max(0, court.gameState.shotClock - 1)
            
            -- Update GuiFolder values
            local guiFolder = workspace:FindFirstChild("GuiFolder")
            if guiFolder then
                local timeValue = guiFolder:FindFirstChild("Time")
                if timeValue then
                    timeValue.Value = court.gameState.timeRemaining
                end
                
                local shotClockValue = guiFolder:FindFirstChild("ShotClock")
                if shotClockValue then
                    shotClockValue.Value = court.gameState.shotClock
                end
            end
            
            -- Shot clock violation
            if court.gameState.shotClock == 0 then
                -- Play buzzer sound
                local buzzer = Instance.new("Sound")
                buzzer.SoundId = CONFIG.soundIds.buzzerSound
                buzzer.Volume = 0.8
                buzzer.Parent = court.model
                buzzer:Play()
                buzzer.Ended:Connect(function()
                    buzzer:Destroy()
                end)
                
                -- Reset shot clock
                court.gameState.shotClock = CONFIG.shotClockDuration
            end
            
            -- Update all clients
            if EventBridge then
                EventBridge:fireEvent("GameClockUpdated", {
                    court = court.name,
                    timeRemaining = court.gameState.timeRemaining,
                    shotClock = court.gameState.shotClock
                })
            end
            
            -- Game ended
            if court.gameState.timeRemaining <= 0 then
                self:_endGame(court)
            end
        end
    end)
    
    -- Update player stats if known
    if player then
        self:_updatePlayerStats(player, "gamesStarted")
    end
    
    -- Notify all nearby players that game started
    if EventBridge then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and (plr.Character:GetPivot().Position - court.model:GetPivot().Position).Magnitude < 100 then
                EventBridge:fireClient("BasketballGameStarted", plr, {
                    court = court.name,
                    duration = CONFIG.defaultGameDuration
                })
            end
        end
    end
    
    return true
end

-- End current game
function BasketballSystem:_endGame(court)
    if not court.gameInProgress then
        return false
    end
    
    court.gameInProgress = false
    
    -- Cancel game clock task
    if court.gameClockTask then
        task.cancel(court.gameClockTask)
        court.gameClockTask = nil
    end
    
    -- Play end game buzzer
    local buzzer = Instance.new("Sound")
    buzzer.SoundId = CONFIG.soundIds.buzzerSound
    buzzer.Volume = 1
    buzzer.Parent = court.model
    buzzer:Play()
    buzzer.Ended:Connect(function()
        buzzer:Destroy()
    end)
    
    -- Determine winner
    local winner = "tie"
    if court.gameState.scores.team1 > court.gameState.scores.team2 then
        winner = "team1"
    elseif court.gameState.scores.team2 > court.gameState.scores.team1 then
        winner = "team2"
    end
    
    -- Update active players' stats
    for userId, playerData in pairs(court.players) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            self:_updatePlayerStats(player, "gamesCompleted")
            
            -- Update wins/losses
            if playerData.team == winner or (playerData.team ~= "team1" and playerData.team ~= "team2" and winner == "tie") then
                self:_updatePlayerStats(player, "wins")
            else
                self:_updatePlayerStats(player, "losses")
            end
        end
    end
    
    -- Notify all nearby players
    if EventBridge then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and (player.Character:GetPivot().Position - court.model:GetPivot().Position).Magnitude < 100 then
                EventBridge:fireClient("BasketballGameEnded", player, {
                    court = court.name,
                    team1Score = court.gameState.scores.team1,
                    team2Score = court.gameState.scores.team2,
                    winner = winner
                })
            end
        end
    end
    
    -- Fire event for other systems
    if EventBridge then
        EventBridge:fireEvent("BasketballGameEnded", {
            court = court.name,
            team1Score = court.gameState.scores.team1,
            team2Score = court.gameState.scores.team2,
            winner = winner,
            duration = CONFIG.defaultGameDuration - court.gameState.timeRemaining
        })
    end
    
    -- Reset game state
    court.gameState = {
        timeRemaining = CONFIG.defaultGameDuration,
        scores = { team1 = 0, team2 = 0 },
        shotClock = CONFIG.shotClockDuration,
        period = 1
    }
    
    -- Clear player assignments
    court.players = {}
    
    return true
end

-- Reset game on a court
function BasketballSystem:_resetGame(court, player)
    -- End current game if in progress
    if court.gameInProgress then
        self:_endGame(court)
    end
    
    -- Reset scoreboard
    if EventBridge then
        EventBridge:fireEvent("ScoreboardUpdated", {
            court = court.name,
            team1Score = 0,
            team2Score = 0,
            timeRemaining = CONFIG.defaultGameDuration,
            shotClock = CONFIG.shotClockDuration,
            period = 1
        })
    end
    
    -- Reset GuiFolder values
    local guiFolder = workspace:FindFirstChild("GuiFolder")
    if guiFolder then
        local timeValue = guiFolder:FindFirstChild("Time")
        if timeValue then
            timeValue.Value = CONFIG.defaultGameDuration
        end
        
        local team1Score = guiFolder:FindFirstChild("Team1Score")
        if team1Score then
            team1Score.Value = 0
        end
        
        local team2Score = guiFolder:FindFirstChild("Team2Score")
        if team2Score then
            team2Score.Value = 0
        end
        
        local shotClockValue = guiFolder:FindFirstChild("ShotClock")
        if shotClockValue then
            shotClockValue.Value = CONFIG.shotClockDuration
        end
    end
    
    -- Clean up any basketballs on court
    for _, ball in pairs(court.balls) do
        if ball and ball.Parent then
            ball:Destroy()
        end
    end
    court.balls = {}
    
    -- Notify player who reset the game
    if player and EventBridge then
        EventBridge:fireClient("BasketballGameReset", player, {
            court = court.name
        })
    end
    
    return true
end

-- Spawn a basketball
function BasketballSystem:_spawnBasketball(court, player, spawnCFrame)
    -- Check for existing balls from this player
    local maxBallsPerPlayer = 2
    local ballCount = 0
    
    for _, ball in pairs(court.balls) do
        if ball and ball.Parent and ball:GetAttribute("Owner") == player.UserId then
            ballCount = ballCount + 1
            
            -- Delete oldest ball if at limit
            if ballCount >= maxBallsPerPlayer then
                ball:Destroy()
                
                -- Remove from court.balls
                for i, b in pairs(court.balls) do
                    if b == ball then
                        table.remove(court.balls, i)
                        break
                    end
                end
            end
        end
    end
    
    -- Create new ball
    local ball = Instance.new("Part")
    ball.Name = "Basketball"
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(1.5, 1.5, 1.5)
    ball.Color = Color3.fromRGB(241, 103, 44) -- Basketball orange
    ball.Material = Enum.Material.Plastic
    ball.CanCollide = true
    ball.Anchored = false
    ball.Massless = false
    
    -- Set custom properties
    ball:SetAttribute("Owner", player.UserId)
    ball:SetAttribute("LastTouched", player.UserId)
    
    -- Create mesh for proper basketball look
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.Scale = Vector3.new(1.5, 1.5, 1.5)
    mesh.Parent = ball
    
    -- Add texture
    local texture = Instance.new("Decal")
    texture.Texture = "rbxassetid://221468070"
    texture.Face = Enum.NormalId.Front
    texture.Parent = ball
    
    -- Physics properties
    local bodyForce = Instance.new("BodyForce")
    bodyForce.Force = Vector3.new(0, ball:GetMass() * workspace.Gravity * 0.05, 0)
    bodyForce.Parent = ball
    
    -- Set bounce settings
    ball.CustomPhysicalProperties = PhysicalProperties.new(
        1, -- Density
        CONFIG.ballBounciness, -- Elasticity/Bounciness
        0.5, -- Friction
        1, -- FrictionWeight
        1 -- ElasticityWeight
    )
    
    -- Set position
    ball.CFrame = spawnCFrame or (player.Character and player.Character:GetPivot()) or CFrame.new(0, 10, 0)
    
    -- Create bounce sound
    local bounceSound = Instance.new("Sound")
    bounceSound.SoundId = CONFIG.soundIds.basketballBounce
    bounceSound.Volume = 0.5
    bounceSound.Parent = ball
    
    -- Add touched event to play bounce sound
    ball.Touched:Connect(function(hit)
        if hit:IsA("BasePart") and hit.CanCollide and not hit:IsDescendantOf(player.Character) then
            -- Get collision velocity
            local velocity = ball.Velocity
            local speed = velocity.Magnitude
            
            -- Only play sound for significant impacts
            if speed > 5 and not bounceSound.IsPlaying then
                bounceSound.Volume = math.min(1.0, speed / 30)
                bounceSound:Play()
            end
            
            -- Update last touched player
            if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
                local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
                if hitPlayer then
                    ball:SetAttribute("LastTouched", hitPlayer.UserId)
                end
            end
        end
    end)
    
    -- Allow player to pick up the ball
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Pick Up Ball"
    prompt.ObjectText = "Basketball"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.RequiresLineOfSight = true
    prompt.MaxActivationDistance = 10
    prompt.Parent = ball
    
    -- Pick up functionality
    prompt.Triggered:Connect(function(playerWhoTriggered)
        ball.CanCollide = false
        
        -- Weld ball to player's hand
        local character = playerWhoTriggered.Character
        if character then
            local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
            if rightHand then
                -- Create attachment and weld
                local attachment = Instance.new("Attachment")
                attachment.Parent = rightHand
                
                local weld = Instance.new("Weld")
                weld.Part0 = rightHand
                weld.Part1 = ball
                weld.C0 = CFrame.new(0, 0, -1.5)
                weld.Parent = ball
                
                -- Update owner
                ball:SetAttribute("Owner", playerWhoTriggered.UserId)
                ball:SetAttribute("LastTouched", playerWhoTriggered.UserId)
                
                -- Create throw prompt
                local throwPrompt = Instance.new("ProximityPrompt")
                throwPrompt.ActionText = "Throw Ball"
                throwPrompt.ObjectText = "Basketball"
                throwPrompt.KeyboardKeyCode = Enum.KeyCode.F
                throwPrompt.RequiresLineOfSight = false
                throwPrompt.MaxActivationDistance = 20
                throwPrompt.Parent = ball
                
                throwPrompt.Triggered:Connect(function()
                    -- Destroy weld and throw the ball
                    if weld then weld:Destroy() end
                    if attachment then attachment:Destroy() end
                    
                    ball.CanCollide = true
                    
                    -- Throw in direction player is looking
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        local lookDirection = humanoid.MoveDirection
                        if lookDirection.Magnitude == 0 then
                            -- Use CFrame if not moving
                            lookDirection = character:GetPivot().LookVector
                        end
                        
                        ball.Velocity = lookDirection * 50 + Vector3.new(0, 20, 0)
                        
                        -- Remove throw prompt
                        throwPrompt:Destroy()
                        
                        -- Restore pickup prompt
                        prompt.Enabled = true
                    end
                end)
                
                -- Disable pickup prompt while holding
                prompt.Enabled = false
            end
        end
    end)
    
    -- Parent to workspace
    ball.Parent = workspace
    
    -- Track ball in court
    table.insert(court.balls, ball)
    
    -- Update player stats
    self:_updatePlayerStats(player, "ballsSpawned")
    
    -- Clean up ball after some time of inactivity
    task.delay(300, function()
        if ball and ball.Parent and (workspace:GetServerTimeNow() - (ball:GetAttribute("LastInteraction") or 0) > 180) then
            ball:Destroy()
            
            -- Remove from court balls
            for i, b in pairs(court.balls) do
                if b == ball then
                    table.remove(court.balls, i)
                    break
                end
            end
        end
    end)
    
    return ball
end

-- Update player basketball stats
function BasketballSystem:_updatePlayerStats(player, statType, value)
    if not player then return end
    
    value = value or 1
    
    -- Initialize player stats if not exists
    if not self._playerStats[player.UserId] then
        self._playerStats[player.UserId] = {
            ballsSpawned = 0,
            basketsMade = 0,
            gamesStarted = 0,
            gamesCompleted = 0,
            wins = 0,
            losses = 0,
            totalPoints = 0,
            personalBest = 0,
            lastGameStats = {
                points = 0,
                team = nil
            }
        }
    end
    
    local stats = self._playerStats[player.UserId]
    
    -- Update the specific stat
    if statType == "ballsSpawned" then
        stats.ballsSpawned = stats.ballsSpawned + value
    elseif statType == "score" then
        stats.basketsMade = stats.basketsMade + 1
        stats.totalPoints = stats.totalPoints + value
        
        -- Update personal best
        if not stats.lastGameStats.team then
            -- Not part of a game, this is practice
            -- Count in personal best
            stats.personalBest = math.max(stats.personalBest, stats.totalPoints)
        end
        
        -- Add to last game stats
        stats.lastGameStats.points = stats.lastGameStats.points + value
    elseif statType == "gamesStarted" then
        stats.gamesStarted = stats.gamesStarted + value
        -- Reset last game stats
        stats.lastGameStats = {
            points = 0,
            team = nil
        }
    elseif statType == "gamesCompleted" then
        stats.gamesCompleted = stats.gamesCompleted + value
    elseif statType == "wins" then
        stats.wins = stats.wins + value
    elseif statType == "losses" then
        stats.losses = stats.losses + value
    end
    
    -- Check for achievements
    self:_checkAchievements(player, statType)
    
    -- Save data if available
    if DataManager then
        local playerData = DataManager:getPlayerData(player)
        if playerData then
            playerData.basketballStats = self._playerStats[player.UserId]
            DataManager:updatePlayerData(player, "basketballStats", playerData.basketballStats)
        end
    end
    
    return self._playerStats[player.UserId]
end

-- Check for achievements based on player stats
function BasketballSystem:_checkAchievements(player, statType)
    if not player or not self._playerStats[player.UserId] then return end
    
    local stats = self._playerStats[player.UserId]
    
    -- Check for relevant achievements
    if statType == "score" or statType == "basketsMade" then
        for _, threshold in ipairs(CONFIG.achievements.basketsMade) do
            if stats.basketsMade == threshold then
                if EventBridge then
                    EventBridge:fireEvent("AchievementUnlocked", {
                        player = player,
                        achievementType = "basketball",
                        achievement = "Basket Master Level " .. table.find(CONFIG.achievements.basketsMade, threshold),
                        description = "Made " .. threshold .. " baskets!"
                    })
                end
                break
            end
        end
    elseif statType == "gamesStarted" or statType == "gamesCompleted" then
        for _, threshold in ipairs(CONFIG.achievements.gamesPlayed) do
            if stats.gamesCompleted == threshold then
                if EventBridge then
                    EventBridge:fireEvent("AchievementUnlocked", {
                        player = player,
                        achievementType = "basketball",
                        achievement = "Basketball Enthusiast Level " .. table.find(CONFIG.achievements.gamesPlayed, threshold),
                        description = "Played " .. threshold .. " basketball games!"
                    })
                end
                break
            end
        end
    end
    
    -- High score achievements
    if stats.personalBest > 0 then
        for _, threshold in ipairs(CONFIG.achievements.highScore) do
            if stats.personalBest >= threshold then
                if EventBridge then
                    EventBridge:fireEvent("AchievementUnlocked", {
                        player = player,
                        achievementType = "basketball",
                        achievement = "Scoring Machine Level " .. table.find(CONFIG.achievements.highScore, threshold),
                        description = "Scored " .. threshold .. " points in basketball!"
                    })
                end
                break
            end
        end
    end
end

-- Inside the score calculation logic for the achievement thresholds
function BasketballSystem:checkScoreAchievements(player, scoreValue)
    -- Get player stats
    local stats = self:getPlayerStats(player)
    if not stats then return end
    
    -- Update personal best if needed
    if scoreValue > stats.personalBest then
        local oldBest = stats.personalBest
        stats.personalBest = scoreValue
        self:savePlayerStats(player, stats)
        
        -- Check achievements for crossing thresholds
        for _, threshold in ipairs(self.achievementThresholds) do
            -- Check if this score crossed the threshold (was below, now above)
            if stats.personalBest >= threshold and oldBest < threshold then
                -- Award achievement
                self:awardAchievement(player, "Basketball_Score_" .. threshold)
                EventBridge:fireEvent("PlayerBasketballMilestone", player, threshold)
            end
        end
    end
end

-- Initialize basketball system
function BasketballSystem:_initialize()
    -- Find all basketball courts
    self._basketballCourts = self:_findBasketballCourts()
    
    -- Initialize each court
    for _, court in pairs(self._basketballCourts) do
        self:_setupBasketballCourt(court)
    end
    
    -- Set up player events
    Players.PlayerAdded:Connect(function(player)
        -- Load player stats
        if DataManager then
            local playerData = DataManager:getPlayerData(player)
            if playerData and playerData.basketballStats then
                self._playerStats[player.UserId] = playerData.basketballStats
            end
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        -- Save player data
        if DataManager then
            local playerData = DataManager:getPlayerData(player)
            if playerData and self._playerStats[player.UserId] then
                playerData.basketballStats = self._playerStats[player.UserId]
                DataManager:updatePlayerData(player, "basketballStats", playerData.basketballStats)
            end
        end
    end)
    
    debugPrint("Basketball system initialized with", #self._basketballCourts, "courts")
    return true
end

-- Clean up basketball system
function BasketballSystem:_cleanup()
    -- Stop any active games
    for _, court in pairs(self._basketballCourts) do
        if court.gameInProgress then
            self:_endGame(court)
        end
    end
    
    -- Disconnect all connections
    for _, connection in pairs(self._cleanupTasks) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    
    self._cleanupTasks = {}
    
    -- Clean up basketballs
    for _, court in pairs(self._basketballCourts) do
        for _, ball in pairs(court.balls) do
            if ball and ball.Parent then
                ball:Destroy()
            end
        end
        court.balls = {}
    end
    
    debugPrint("Basketball system cleaned up")
end

--[[ Public API ]]--

-- Get all basketball courts
function BasketballSystem:GetAllCourts()
    local courts = {}
    for _, court in pairs(self._basketballCourts) do
        table.insert(courts, {
            name = court.name,
            gameInProgress = court.gameInProgress,
            playerCount = #court.players
        })
    end
    return courts
end

-- Get specific court information
function BasketballSystem:GetCourtInfo(courtName)
    for _, court in pairs(self._basketballCourts) do
        if court.name == courtName then
            return {
                name = court.name,
                gameInProgress = court.gameInProgress,
                scores = court.gameState.scores,
                timeRemaining = court.gameState.timeRemaining,
                shotClock = court.gameState.shotClock,
                period = court.gameState.period,
                playerCount = #court.players
            }
        end
    end
    return nil
end

-- Get player basketball stats
function BasketballSystem:GetPlayerStats(player)
    if not player then return nil end
    
    if not self._playerStats[player.UserId] then
        -- Initialize default stats
        self._playerStats[player.UserId] = {
            ballsSpawned = 0,
            basketsMade = 0,
            gamesStarted = 0,
            gamesCompleted = 0,
            wins = 0,
            losses = 0,
            totalPoints = 0,
            personalBest = 0,
            lastGameStats = {
                points = 0,
                team = nil
            }
        }
    end
    
    return self._playerStats[player.UserId]
end

-- Start a game on a specific court
function BasketballSystem:StartGame(courtName, player)
    for _, court in pairs(self._basketballCourts) do
        if court.name == courtName then
            return self:_startGame(court, player)
        end
    end
    return false
end

-- End a game on a specific court
function BasketballSystem:EndGame(courtName)
    for _, court in pairs(self._basketballCourts) do
        if court.name == courtName then
            return self:_endGame(court)
        end
    end
    return false
end

-- Assign a player to a team
function BasketballSystem:AssignPlayerToTeam(player, courtName, team)
    if not player then return false end
    
    for _, court in pairs(self._basketballCourts) do
        if court.name == courtName then
            -- Check if team is valid
            if team ~= "team1" and team ~= "team2" then
                return false
            end
            
            -- Add player to court.players
            court.players[player.UserId] = {
                team = team,
                joinTime = os.time()
            }
            
            -- Update player stats
            if self._playerStats[player.UserId] then
                self._playerStats[player.UserId].lastGameStats.team = team
            end
            
            -- Notify player
            if EventBridge then
                EventBridge:fireClient("TeamAssigned", player, {
                    court = courtName,
                    team = team
                })
            end
            
            return true
        end
    end
    
    return false
end

-- Spawn a basketball for a player
function BasketballSystem:SpawnBasketball(player, courtName)
    if not player or not player.Character then
        return nil
    end
    
    for _, court in pairs(self._basketballCourts) do
        if court.name == courtName then
            -- Find spawn position
            local spawnPosition = player.Character:GetPivot()
            local ballSpawner = court.model:FindFirstChild("BallSpawner")
            if ballSpawner then
                spawnPosition = ballSpawner.CFrame
            end
            
            return self:_spawnBasketball(court, player, spawnPosition)
        end
    end
    
    return nil
end

--[[ Initialization and Lifecycle ]]--

function BasketballSystem:init()
    debugPrint("Initializing BasketballSystem v" .. self._version)
    
    -- Get dependencies
    CoreRegistry = self.CoreRegistry
    EventBridge = CoreRegistry:getSystem("EventBridge")
    DataManager = CoreRegistry:getSystem("DataManager")
    
    -- Register events
    if EventBridge then
        -- Handle client requests
        EventBridge:registerClientEvent("RequestCourtInfo", function(player, courtName)
            local courtInfo = self:GetCourtInfo(courtName)
            if courtInfo then
                EventBridge:fireClient("CourtInfoResponse", player, courtInfo)
            end
        end)
        
        EventBridge:registerClientEvent("RequestStartGame", function(player, courtName)
            local success = self:StartGame(courtName, player)
            EventBridge:fireClient("StartGameResponse", player, {
                success = success,
                court = courtName
            })
        end)
        
        EventBridge:registerClientEvent("RequestEndGame", function(player, courtName)
            local success = self:EndGame(courtName)
            EventBridge:fireClient("EndGameResponse", player, {
                success = success,
                court = courtName
            })
        end)
        
        EventBridge:registerClientEvent("RequestJoinTeam", function(player, data)
            local success = self:AssignPlayerToTeam(player, data.court, data.team)
            EventBridge:fireClient("JoinTeamResponse", player, {
                success = success,
                court = data.court,
                team = data.team
            })
        end)
        
        EventBridge:registerClientEvent("RequestSpawnBall", function(player, courtName)
            local ball = self:SpawnBasketball(player, courtName)
            EventBridge:fireClient("SpawnBallResponse", player, {
                success = ball ~= nil,
                court = courtName
            })
        end)
        
        EventBridge:registerClientEvent("RequestPlayerStats", function(player)
            local stats = self:GetPlayerStats(player)
            EventBridge:fireClient("PlayerStatsResponse", player, stats)
        end)
    end
    
    return true
end

function BasketballSystem:start()
    debugPrint("Starting BasketballSystem")
    
    self:_initialize()
    
    debugPrint("BasketballSystem started")
    return true
end

function BasketballSystem:stop()
    debugPrint("Stopping BasketballSystem")
    
    self:_cleanup()
    
    debugPrint("BasketballSystem stopped")
    return true
end

return BasketballSystem
