-- Celebrity Trainer System (Server)
-- Place in ServerScriptService

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Try to load dependencies
local SpecializationSystem
pcall(function()
    SpecializationSystem = require(ServerScriptService:FindFirstChild("GymSpecializationSystem"))
end)

local GymRevenue
pcall(function()
    GymRevenue = require(ServerScriptService:FindFirstChild("GymRevenueSystem"))
end)

local CelebrityTrainerSystem = {
    -- Currently available celebrity trainers
    availableTrainers = {},

    -- Players' hired trainers
    playerTrainers = {},

    -- Celebrity trainer definitions
    celebrities = {
        powerMax = {
            name = "Max Power",
            description = "World-famous bodybuilding champion and 5-time Mr. Universe",
            specialty = "bodybuilding",
            hiring_cost = 50000,
            salary = 5000, -- Weekly salary
            appearance = {
                model_id = "rbxassetid://12345683", -- Replace with actual model ID
                icon = "rbxassetid://12345684" -- Replace with actual icon ID
            },
            benefits = {
                vip_chance_boost = 0.1, -- +10% VIP chance
                membership_boost = 1.15, -- 15% more members
                special_ability = "PowerCompetition", -- Can host special competitions
                exclusive_equipment = "PowerRack" -- Unlocks special equipment
            },
            dialogue = {
                greeting = "Let's pump up your gym's revenue like I pump iron! ARE YOU READY?",
                hired = "YEEAAH! Time to make this the best gym in town!",
                fired = "Your loss, bro. I'll take my gains elsewhere.",
                daily = {"Feel the burn!", "No pain, no gain!", "One more rep!"}
            },
            requirements = {
                gym_level = 5,
                specialization = "bodybuilding" -- Required specialization
            }
        },

        cardioQueen = {
            name = "Cardio Queen",
            description = "Marathon champion and fitness influencer with over 10 million followers",
            specialty = "cardio",
            hiring_cost = 45000,
            salary = 4500,
            appearance = {
                model_id = "rbxassetid://12345685",
                icon = "rbxassetid://12345686"
            },
            benefits = {
                membership_retention = 1.3, -- 30% better retention
                dues_boost = 1.1, -- 10% higher dues
                special_ability = "CardioMarathon",
                exclusive_equipment = "PremiumTreadmill"
            },
            dialogue = {
                greeting = "Hi there! Ready to take your cardio program to the next level?",
                hired = "Fantastic! Let's get those hearts pumping!",
                fired = "Oh, that's too bad. Call me if you change your mind!",
                daily = {"Keep moving!", "Feel that endurance building!", "You're doing great!"}
            },
            requirements = {
                gym_level = 4,
                specialization = "cardio"
            }
        },

        zenMaster = {
            name = "Zen Master",
            description = "Celebrity yoga instructor and wellness coach to the stars",
            specialty = "luxury",
            hiring_cost = 60000,
            salary = 6000,
            appearance = {
                model_id = "rbxassetid://12345687",
                icon = "rbxassetid://12345688"
            },
            benefits = {
                vip_multiplier = 1.3, -- VIPs pay 30% more
                vip_chance_boost = 0.15,
                special_ability = "MindfulnessRetreat",
                exclusive_equipment = "LuxurySpa"
            },
            dialogue = {
                greeting = "Peace and prosperity to your establishment. Shall we elevate your members' experience?",
                hired = "A wise choice. Together we will create harmony and balance.",
                fired = "I understand. Our paths may cross again when the time is right.",
                daily = {"Find your center.", "Breathe in prosperity.", "Align your business chakras."}
            },
            requirements = {
                gym_level = 6,
                specialization = "luxury"
            }
        },

        crossfitChamp = {
            name = "CrossFit Champ",
            description = "CrossFit Games champion known for high-intensity functional training",
            specialty = "crossfit",
            hiring_cost = 55000,
            salary = 5500,
            appearance = {
                model_id = "rbxassetid://12345689",
                icon = "rbxassetid://12345690"
            },
            benefits = {
                membership_boost = 1.2,
                dues_boost = 1.15,
                special_ability = "EliteChallenge",
                exclusive_equipment = "FunctionalRig"
            },
            dialogue = {
                greeting = "Hey! Want to transform your gym into a high-performance training ground?",
                hired = "Let's do this! Time to push your gym to its limits!",
                fired = "No worries, catch you on the next WOD!",
                daily = {"Three, two, one, GO!", "Beat your yesterday!", "As many rounds as possible!"}
            },
            requirements = {
                gym_level = 5,
                specialization = "crossfit"
            }
        },

        nutritionGuru = {
            name = "Nutrition Guru",
            description = "Celebrity nutritionist and author of bestselling fitness cookbooks",
            specialty = "general", -- Works with any specialization
            hiring_cost = 40000,
            salary = 4000,
            appearance = {
                model_id = "rbxassetid://12345691",
                icon = "rbxassetid://12345692"
            },
            benefits = {
                membership_retention = 1.2,
                vip_chance_boost = 0.05,
                special_ability = "MealPlanPromotion",
                exclusive_equipment = "JuiceBar"
            },
            dialogue = {
                greeting = "Hello! Want to supercharge your gym's results with proper nutrition?",
                hired = "Excellent! Nutrition is the foundation of fitness success!",
                fired = "I understand. Nutrition is often overlooked, but always important!",
                daily = {"Fuel your body right!", "Protein is key!", "Hydration leads to success!"}
            },
            requirements = {
                gym_level = 3 -- Lower requirement, works with any specialization
            }
        }
    }
}

-- Check if a player meets requirements for a celebrity trainer
function CelebrityTrainerSystem.checkRequirements(player, celebrityId)
    if not player or not celebrityId then return false end

    local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
    if not celebrity then return false end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then return false end

    -- Check gym level
    local gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or 1
    if gymLevel < celebrity.requirements.gym_level then
        return false, "Your gym needs to be level " .. celebrity.requirements.gym_level
    end

    -- Check specialization if required
    if celebrity.requirements.specialization and celebrity.requirements.specialization ~= "general" then
        local hasRequiredSpec = false

        -- Check if player has the specialization system
        if SpecializationSystem then
            local specs = SpecializationSystem.getPlayerSpecializations(player)
            if specs and (specs.primary == celebrity.requirements.specialization or 
                specs.secondary == celebrity.requirements.specialization) then
                hasRequiredSpec = true
            end
        end

        if not hasRequiredSpec then
            return false, "You need the " .. celebrity.requirements.specialization .. " specialization"
        end
    end

    -- Check if player has enough money
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats or not leaderstats:FindFirstChild("Cash") then
        return false, "Cannot verify funds"
    end

    if leaderstats.Cash.Value < celebrity.hiring_cost then
        return false, "You need $" .. celebrity.hiring_cost .. " to hire this trainer"
    end

    return true
end

-- Hire a celebrity trainer
function CelebrityTrainerSystem.hireTrainer(player, celebrityId)
    if not player or not celebrityId then return false end

    local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
    if not celebrity then return false, "Invalid celebrity trainer" end

    -- Check requirements
    local meetsRequirements, reason = CelebrityTrainerSystem.checkRequirements(player, celebrityId)
    if not meetsRequirements then
        return false, reason
    end

    -- Check if player already has this trainer
    if CelebrityTrainerSystem.playerTrainers[player.UserId] and 
        CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId] then
        return false, "You already hired this trainer"
    end

    -- Deduct hiring cost
    local leaderstats = player:FindFirstChild("leaderstats")
    leaderstats.Cash.Value = leaderstats.Cash.Value - celebrity.hiring_cost

    -- Initialize player's trainers table if needed
    if not CelebrityTrainerSystem.playerTrainers[player.UserId] then
        CelebrityTrainerSystem.playerTrainers[player.UserId] = {}
    end

    -- Record hiring
    CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId] = {
        hired_time = os.time(),
        last_salary_time = os.time(),
        benefits_applied = false
    }

    -- Apply benefits
    CelebrityTrainerSystem.applyTrainerBenefits(player, celebrityId)

    -- Create trainer in player's gym
    CelebrityTrainerSystem.createTrainerInGym(player, celebrityId)

    -- Create notification
    local message = Instance.new("Message")
    message.Text = celebrity.name .. " has joined your team!\n" .. celebrity.dialogue.hired
    message.Parent = player
    game:GetService("Debris"):AddItem(message, 5)

    -- Mark trainer as unavailable for other players
    table.insert(CelebrityTrainerSystem.availableTrainers, celebrityId)

    return true, "Trainer hired successfully"
end

-- Fire a celebrity trainer
function CelebrityTrainerSystem.fireTrainer(player, celebrityId)
    if not player or not celebrityId then return false end

    -- Check if player has this trainer
    if not CelebrityTrainerSystem.playerTrainers[player.UserId] or
        not CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId] then
        return false, "You haven't hired this trainer"
    end

    local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
    if not celebrity then return false, "Invalid celebrity trainer" end

    -- Remove benefits
    CelebrityTrainerSystem.removeTrainerBenefits(player, celebrityId)

    -- Remove trainer from player's gym
    CelebrityTrainerSystem.removeTrainerFromGym(player, celebrityId)

    -- Remove from player's trainers
    CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId] = nil

    -- Create notification
    local message = Instance.new("Message")
    message.Text = celebrity.name .. " has left your team.\n" .. celebrity.dialogue.fired
    message.Parent = player
    game:GetService("Debris"):AddItem(message, 5)

    -- Make trainer available again after a cooldown
    spawn(function()
        wait(60 * 60) -- 1 hour cooldown

        -- Remove from unavailable list
        for i, id in ipairs(CelebrityTrainerSystem.availableTrainers) do
            if id == celebrityId then
                table.remove(CelebrityTrainerSystem.availableTrainers, i)
                break
            end
        end
    end)

    return true, "Trainer fired successfully"
end

-- Apply trainer benefits to a player
function CelebrityTrainerSystem.applyTrainerBenefits(player, celebrityId)
    if not player or not celebrityId then return false end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then return false end

    local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
    if not celebrity then return false end

    -- Apply benefits to tycoon attributes
    if celebrity.benefits.vip_chance_boost then
        local currentBoost = tycoon:GetAttribute("TrainerVIPChanceBoost") or 0
        tycoon:SetAttribute("TrainerVIPChanceBoost", currentBoost + celebrity.benefits.vip_chance_boost)
    end

    if celebrity.benefits.membership_boost then
        local currentBoost = tycoon:GetAttribute("TrainerMembershipBoost") or 1.0
        tycoon:SetAttribute("TrainerMembershipBoost", currentBoost * celebrity.benefits.membership_boost)
    end

    if celebrity.benefits.membership_retention then
        local currentRetention = tycoon:GetAttribute("TrainerRetentionBoost") or 1.0
        tycoon:SetAttribute("TrainerRetentionBoost", currentRetention * celebrity.benefits.membership_retention)
    end

    if celebrity.benefits.dues_boost then
        local currentDuesBoost = tycoon:GetAttribute("TrainerDuesBoost") or 1.0
        tycoon:SetAttribute("TrainerDuesBoost", currentDuesBoost * celebrity.benefits.dues_boost)
    end

    if celebrity.benefits.vip_multiplier then
        local currentVIPMultiplier = tycoon:GetAttribute("TrainerVIPMultiplier") or 1.0
        tycoon:SetAttribute("TrainerVIPMultiplier", currentVIPMultiplier * celebrity.benefits.vip_multiplier)
    end

    -- Unlock exclusive equipment if available
    if celebrity.benefits.exclusive_equipment then
        tycoon:SetAttribute("Unlocked_" .. celebrity.benefits.exclusive_equipment, true)

        -- Notification about unlocked equipment
        local message = Instance.new("Message")
        message.Text = "New equipment unlocked: " .. celebrity.benefits.exclusive_equipment
        message.Parent = player
        game:GetService("Debris"):AddItem(message, 5)
    end

    -- Mark benefits as applied
    if CelebrityTrainerSystem.playerTrainers[player.UserId] and
        CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId] then
        CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId].benefits_applied = true
    end

    -- Update revenue system
    if GymRevenue and GymRevenue.updatePlayerConfig then
        GymRevenue.updatePlayerConfig(player)
    end

    return true
end

-- Remove trainer benefits from a player
function CelebrityTrainerSystem.removeTrainerBenefits(player, celebrityId)
    if not player or not celebrityId then return false end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then return false end

    local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
    if not celebrity then return false end

    -- Reset attributes - a more complex implementation would track individual 
    -- contributions from each trainer rather than resetting everything
    tycoon:SetAttribute("TrainerVIPChanceBoost", 0)
    tycoon:SetAttribute("TrainerMembershipBoost", 1.0)
    tycoon:SetAttribute("TrainerRetentionBoost", 1.0)
    tycoon:SetAttribute("TrainerDuesBoost", 1.0)
    tycoon:SetAttribute("TrainerVIPMultiplier", 1.0)

    -- Re-apply benefits from any remaining trainers
    if CelebrityTrainerSystem.playerTrainers[player.UserId] then
        for id, data in pairs(CelebrityTrainerSystem.playerTrainers[player.UserId]) do
            if id ~= celebrityId then
                CelebrityTrainerSystem.applyTrainerBenefits(player, id)
            end
        end
    end

    -- Update revenue system
    if GymRevenue and GymRevenue.updatePlayerConfig then
        GymRevenue.updatePlayerConfig(player)
    end

    return true
end

-- Create a trainer model in the player's gym
function CelebrityTrainerSystem.createTrainerInGym(player, celebrityId)
    if not player or not celebrityId then return nil end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then return nil end

    local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
    if not celebrity then return nil end

    -- Check if trainer model already exists
    local existingTrainer = tycoon.Value:FindFirstChild("Trainer_" .. celebrityId)
    if existingTrainer then
        return existingTrainer
    end

    -- Create trainer model
    local trainerModel = Instance.new("Model")
    trainerModel.Name = "Trainer_" .. celebrityId

    -- Try to load a custom model if available
    local customModel = nil
    pcall(function()
        if celebrity.appearance.model_id then
            customModel = game:GetObjects(celebrity.appearance.model_id)[1]
        end
    end)

    if customModel then
        -- Use the custom model
        customModel.Parent = trainerModel
    else
        -- Create a simple placeholder model
        local torso = Instance.new("Part")
        torso.Name = "Torso"
        torso.Size = Vector3.new(2, 2, 1)
        torso.BrickColor = BrickColor.new("Bright blue")
        torso.Anchored = true
        torso.CanCollide = false
        torso.Parent = trainerModel

        local head = Instance.new("Part")
        head.Name = "Head"
        head.Shape = Enum.PartType.Ball
        head.Size = Vector3.new(1.25, 1.25, 1.25)
        head.BrickColor = BrickColor.new("Light yellow")
        head.Anchored = true
        head.CanCollide = false
        head.Position = torso.Position + Vector3.new(0, 1.625, 0)
        head.Parent = trainerModel

        -- Add name label
        local nameGui = Instance.new("BillboardGui")
        nameGui.Name = "NameLabel"
        nameGui.Size = UDim2.new(0, 100, 0, 40)
        nameGui.StudsOffset = Vector3.new(0, 2, 0)
        nameGui.AlwaysOnTop = true
        nameGui.Parent = head

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.Text = celebrity.name
        nameLabel.Parent = nameGui
    end

    -- Find a good position in the gym
    local position

    -- Try to find front desk first
    local frontDesk = tycoon.Value:FindFirstChild("Front Desk")
    if frontDesk then
        position = frontDesk:GetPivot().Position + Vector3.new(3, 0, 0)
    else
        -- If no front desk, find any suitable floor
        for _, part in pairs(tycoon.Value:GetDescendants()) do
            if part:IsA("BasePart") and part.Size.X > 5 and part.Size.Z > 5 and
                math.abs(part.CFrame.UpVector.Y) > 0.9 then
                position = part.Position + Vector3.new(0, part.Size.Y/2 + 1, 0)
                break
            end
        end

        -- If still no position, use the tycoon origin
        if not position then
            position = tycoon.Value:GetPivot().Position
        end
    end

    -- Position the trainer
    if customModel then
        -- Position custom model
        if customModel.PrimaryPart then
            customModel:SetPrimaryPartCFrame(CFrame.new(position))
        else
            -- Find a part to use as reference
            for _, part in pairs(customModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Position = part.Position - customModel:GetPivot().Position + position
                end
            end
        end
    else
        -- Position basic model
        local torso = trainerModel:FindFirstChild("Torso")
        if torso then
            torso.Position = position

            -- Reposition head relative to torso
            local head = trainerModel:FindFirstChild("Head")
            if head then
                head.Position = torso.Position + Vector3.new(0, 1.625, 0)
            end
        end
    end

    -- Add proximity prompt for interaction
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "TrainerPrompt"
    prompt.ObjectText = celebrity.name
    prompt.ActionText = "Talk to Trainer"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false

    -- Find a part to parent the prompt to
    local promptPart
    if customModel and customModel.PrimaryPart then
        promptPart = customModel.PrimaryPart
    elseif trainerModel:FindFirstChild("Torso") then
        promptPart = trainerModel.Torso
    else
        for _, part in pairs(trainerModel:GetDescendants()) do
            if part:IsA("BasePart") then
                promptPart = part
                break
            end
        end
    end

    if promptPart then
        prompt.Parent = promptPart

        -- Connect prompt to interaction handler
        prompt.Triggered:Connect(function(otherPlayer)
            if otherPlayer == player then
                -- Handle interaction
                CelebrityTrainerSystem.interactWithTrainer(player, celebrityId)
            else
                -- Show message for other players
                local message = Instance.new("Message")
                message.Text = celebrity.name .. " is working exclusively with " .. player.Name .. "'s gym."
                message.Parent = otherPlayer
                game:GetService("Debris"):AddItem(message, 3)
            end
        end)
    end

    -- Parent the trainer to the gym
    trainerModel.Parent = tycoon.Value

    -- Animate trainer appearance
    for _, part in pairs(trainerModel:GetDescendants()) do
        if part:IsA("BasePart") then
            local originalTransparency = part.Transparency
            part.Transparency = 1

            -- Create transparency tween
            local tween = TweenService:Create(
                part,
                TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {Transparency = originalTransparency}
            )

            tween:Play()
        end
    end

    return trainerModel
end

-- Remove a trainer from a player's gym
function CelebrityTrainerSystem.removeTrainerFromGym(player, celebrityId)
    if not player or not celebrityId then return false end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then return false end

    -- Find trainer model
    local trainerModel = tycoon.Value:FindFirstChild("Trainer_" .. celebrityId)
    if not trainerModel then return false end

    -- Animate trainer disappearance
    for _, part in pairs(trainerModel:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Create transparency tween
            local tween = TweenService:Create(
                part,
                TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                {Transparency = 1}
            )

            tween:Play()
        end
    end

    -- Remove after animation
    spawn(function()
        wait(1)
        trainerModel:Destroy()
    end)

    return true
end

-- Return the module
return CelebrityTrainerSystem
