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

-- Handle player interaction with a trainer
function CelebrityTrainerSystem.interactWithTrainer(player, celebrityId)
	if not player or not celebrityId then return end

	local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
	if not celebrity then return end

	-- Create interaction GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TrainerInteraction"
	screenGui.ResetOnSpawn = false

	-- Create main frame
	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0, 400, 0, 300)
	frame.Position = UDim2.new(0.5, -200, 0.5, -150)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	-- Add trainer name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -20, 0, 40)
	nameLabel.Position = UDim2.new(0, 10, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 24
	nameLabel.Text = celebrity.name
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = frame

	-- Add dialogue
	local dialogue = Instance.new("TextLabel")
	dialogue.Name = "Dialogue"
	dialogue.Size = UDim2.new(1, -40, 0, 100)
	dialogue.Position = UDim2.new(0, 20, 0, 60)
	dialogue.BackgroundTransparency = 1
	dialogue.Font = Enum.Font.Gotham
	dialogue.TextColor3 = Color3.fromRGB(255, 255, 255)
	dialogue.TextSize = 16
	dialogue.TextWrapped = true

	-- Choose random daily dialogue
	if celebrity.dialogue.daily and #celebrity.dialogue.daily > 0 then
		dialogue.Text = celebrity.dialogue.daily[math.random(1, #celebrity.dialogue.daily)]
	else
		dialogue.Text = "Hey there! Let's make this gym the best it can be!"
	end

	dialogue.Parent = frame

	-- Add buttons
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(1, -40, 0, 100)
	buttonsContainer.Position = UDim2.new(0, 20, 0, 170)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = frame

	-- Define button functions
	local buttonFunctions = {
		{
			name = "Special Ability",
			action = function()
				CelebrityTrainerSystem.useSpecialAbility(player, celebrityId)
				screenGui:Destroy()
			end
		},
		{
			name = "View Benefits",
			action = function()
				CelebrityTrainerSystem.showTrainerBenefits(player, celebrityId)
				screenGui:Destroy()
			end
		},
		{
			name = "Fire Trainer",
			action = function()
				CelebrityTrainerSystem.confirmFireTrainer(player, celebrityId)
				screenGui:Destroy()
			end
		},
		{
			name = "Close",
			action = function()
				screenGui:Destroy()
			end
		}
	}

	-- Create buttons
	for i, buttonInfo in ipairs(buttonFunctions) do
		local button = Instance.new("TextButton")
		button.Name = buttonInfo.name .. "Button"
		button.Size = UDim2.new(0.48, 0, 0, 40)
		button.Position = UDim2.new(i % 2 == 1 and 0 or 0.52, 0, i <= 2 and 0 or 0.55, 0)
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Font = Enum.Font.GothamSemibold
		button.TextSize = 16
		button.Text = buttonInfo.name

		-- Add rounded corners
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = button

		-- Connect click event
		button.MouseButton1Click:Connect(buttonInfo.action)

		button.Parent = buttonsContainer
	end

	-- Add close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 18
	closeButton.Text = "X"

	-- Add rounded corners
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 15)
	closeCorner.Parent = closeButton

	-- Connect close button
	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	closeButton.Parent = frame

	-- Parent the GUI to the player
	screenGui.Parent = player.PlayerGui
end

-- Show trainer benefits
function CelebrityTrainerSystem.showTrainerBenefits(player, celebrityId)
	if not player or not celebrityId then return end

	local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
	if not celebrity then return end

	-- Create benefits GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TrainerBenefits"
	screenGui.ResetOnSpawn = false

	-- Create main frame
	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0, 400, 0, 350)
	frame.Position = UDim2.new(0.5, -200, 0.5, -175)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	-- Add title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -20, 0, 40)
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 24
	titleLabel.Text = celebrity.name .. " - Benefits"
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Parent = frame

	-- Add benefits container
	local benefitsContainer = Instance.new("ScrollingFrame")
	benefitsContainer.Name = "BenefitsContainer"
	benefitsContainer.Size = UDim2.new(1, -40, 0, 240)
	benefitsContainer.Position = UDim2.new(0, 20, 0, 60)
	benefitsContainer.BackgroundTransparency = 1
	benefitsContainer.BorderSizePixel = 0
	benefitsContainer.ScrollBarThickness = 6
	benefitsContainer.Parent = frame

	-- Add UIListLayout to organize benefits
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = benefitsContainer

	-- Create benefits list
	local benefitsList = {}
	if celebrity.benefits.vip_chance_boost then
		table.insert(benefitsList, {
			name = "VIP Chance",
			value = "+" .. (celebrity.benefits.vip_chance_boost * 100) .. "%",
			description = "Increased chance for VIP members"
		})
	end

	if celebrity.benefits.membership_boost and celebrity.benefits.membership_boost ~= 1.0 then
		local percent = math.floor((celebrity.benefits.membership_boost - 1) * 100)
		table.insert(benefitsList, {
			name = "Membership",
			value = "+" .. percent .. "%",
			description = "More members join your gym"
		})
	end

	if celebrity.benefits.membership_retention and celebrity.benefits.membership_retention ~= 1.0 then
		local percent = math.floor((celebrity.benefits.membership_retention - 1) * 100)
		table.insert(benefitsList, {
			name = "Retention",
			value = "+" .. percent .. "%",
			description = "Better member retention"
		})
	end

	if celebrity.benefits.dues_boost and celebrity.benefits.dues_boost ~= 1.0 then
		local percent = math.floor((celebrity.benefits.dues_boost - 1) * 100)
		table.insert(benefitsList, {
			name = "Membership Fees",
			value = "+" .. percent .. "%",
			description = "Higher membership fees"
		})
	end

	if celebrity.benefits.vip_multiplier and celebrity.benefits.vip_multiplier ~= 1.0 then
		local percent = math.floor((celebrity.benefits.vip_multiplier - 1) * 100)
		table.insert(benefitsList, {
			name = "VIP Payments",
			value = "+" .. percent .. "%",
			description = "VIP members pay more"
		})
	end

	if celebrity.benefits.special_ability then
		table.insert(benefitsList, {
			name = "Special Ability",
			value = celebrity.benefits.special_ability,
			description = "Special promotion or event"
		})
	end

	if celebrity.benefits.exclusive_equipment then
		table.insert(benefitsList, {
			name = "Exclusive Equipment",
			value = celebrity.benefits.exclusive_equipment,
			description = "Unlock special equipment"
		})
	end

	-- Add benefits to container
	for i, benefit in ipairs(benefitsList) do
		local benefitFrame = Instance.new("Frame")
		benefitFrame.Name = "Benefit_" .. i
		benefitFrame.Size = UDim2.new(1, 0, 0, 60)
		benefitFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		benefitFrame.BorderSizePixel = 0
		benefitFrame.LayoutOrder = i

		-- Add rounded corners
		local benefitCorner = Instance.new("UICorner")
		benefitCorner.CornerRadius = UDim.new(0, 6)
		benefitCorner.Parent = benefitFrame

		-- Add benefit name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(0.4, 0, 0, 30)
		nameLabel.Position = UDim2.new(0, 10, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 16
		nameLabel.Text = benefit.name
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = benefitFrame

		-- Add benefit value
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "ValueLabel"
		valueLabel.Size = UDim2.new(0.3, 0, 0, 30)
		valueLabel.Position = UDim2.new(0.4, 10, 0, 5)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
		valueLabel.TextSize = 16
		valueLabel.Text = benefit.value
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.Parent = benefitFrame

		-- Add benefit description
		local descriptionLabel = Instance.new("TextLabel")
		descriptionLabel.Name = "DescriptionLabel"
		descriptionLabel.Size = UDim2.new(1, -20, 0, 20)
		descriptionLabel.Position = UDim2.new(0, 10, 0, 35)
		descriptionLabel.BackgroundTransparency = 1
		descriptionLabel.Font = Enum.Font.Gotham
		descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descriptionLabel.TextSize = 14
		descriptionLabel.Text = benefit.description
		descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
		descriptionLabel.Parent = benefitFrame

		benefitFrame.Parent = benefitsContainer
	end

	-- Update canvas size
	benefitsContainer.CanvasSize = UDim2.new(0, 0, 0, #benefitsList * 70)

	-- Add close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 100, 0, 40)
	closeButton.Position = UDim2.new(0.5, -50, 0, 310)
	closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 16
	closeButton.Text = "Close"

	-- Add rounded corners
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	-- Connect close button
	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	closeButton.Parent = frame

	-- Parent the GUI to the player
	screenGui.Parent = player.PlayerGui
end

-- Use trainer's special ability
function CelebrityTrainerSystem.useSpecialAbility(player, celebrityId)
	if not player or not celebrityId then return false end

	local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
	if not celebrity or not celebrity.benefits.special_ability then return false end

	-- Check if ability is on cooldown
	if CelebrityTrainerSystem.playerTrainers[player.UserId] and
		CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId] and
		CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId].ability_cooldown then

		local cooldownEndTime = CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId].ability_cooldown
		if os.time() < cooldownEndTime then
			-- Create cooldown notification
			local timeLeft = math.ceil((cooldownEndTime - os.time()) / 60) -- Minutes

			local message = Instance.new("Message")
			message.Text = "Special ability on cooldown. Available in " .. timeLeft .. " minutes."
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 5)

			return false
		end
	end

	-- Implement ability effects based on type
	local abilityName = celebrity.benefits.special_ability
	local success = false

	if abilityName == "PowerCompetition" then
		-- Boost gym revenue for a limited time
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			tycoon:SetAttribute("PowerCompetitionBoost", 2.0) -- Double revenue

			-- Create notification
			local message = Instance.new("Message")
			message.Text = celebrity.name .. " is hosting a power competition!\nDoubled revenue for 1 hour!"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 5)

			-- Remove boost after duration
			spawn(function()
				wait(60 * 60) -- 1 hour
				if tycoon then
					tycoon:SetAttribute("PowerCompetitionBoost", nil)

					-- Notify end
					local endMessage = Instance.new("Message")
					endMessage.Text = "Power competition has ended."
					endMessage.Parent = player
					game:GetService("Debris"):AddItem(endMessage, 5)
				end
			end)

			success = true
		end
	elseif abilityName == "CardioMarathon" then
		-- Attract new members
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			-- Get current membership
			local currentMembership = tycoon:GetAttribute("MembershipCount") or 0

			-- Add 20% more members
			local newMembers = math.floor(currentMembership * 0.2)
			tycoon:SetAttribute("CardioMarathonBonus", newMembers)

			-- Create notification
			local message = Instance.new("Message")
			message.Text = celebrity.name .. " organized a cardio marathon!\nAttracted " .. newMembers .. " new members!"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 5)

			success = true
		end
	elseif abilityName == "MindfulnessRetreat" then
		-- Convert regular members to VIPs
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			-- Get current VIP count
			local currentVIPs = tycoon:GetAttribute("VIPMembershipCount") or 0
			local regularMembers = (tycoon:GetAttribute("MembershipCount") or 0) - currentVIPs

			-- Convert 10% of regular members to VIPs
			local newVIPs = math.floor(regularMembers * 0.1)
			tycoon:SetAttribute("MindfulnessRetreatBonus", newVIPs)

			-- Create notification
			local message = Instance.new("Message")
			message.Text = celebrity.name .. " hosted a luxury mindfulness retreat!\nConverted " .. newVIPs .. " members to VIP status!"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 5)

			success = true
		end
	elseif abilityName == "EliteChallenge" then
		-- Boost member retention
		local tycoon = player:FindFirstChild("Tycoon")
		if tycoon then
			tycoon:SetAttribute("EliteChallengeBoost", 1.5) -- 50% better retention

			-- Create notification
			local message = Instance.new("Message")
			message.Text = celebrity.name .. " is running an elite challenge program!\nImproved member retention for 1 week!"
			message.Parent = player
			game:GetService("Debris"):AddItem(message, 5)

			-- Remove boost after duration
			spawn(function()
				wait(60 * 60 * 24 * 7) -- 1 week
				if tycoon then
					tycoon:SetAttribute("EliteChallengeBoost", nil)

					-- Notify end
					local endMessage = Instance.new("Message")
					endMessage.Text = "Elite challenge program has ended."
					endMessage.Parent = player
					game:GetService("Debris"):AddItem(endMessage, 5)
				end
			end)

			success = true
		end
	elseif abilityName == "MealPlanPromotion" then
		-- Boost membership fees
		local tycoon = player-- CelebrityTrainerSystem.lua
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

			local celebrity = CelebrityTrainerSystem
			-- Complete the useSpecialAbility function
			if abilityName == "MealPlanPromotion" then
				-- Boost membership fees
				local tycoon = player:FindFirstChild("Tycoon")
				if tycoon then
					tycoon:SetAttribute("MealPlanBoost", 1.3) -- 30% higher fees

					-- Create notification
					local message = Instance.new("Message")
					message.Text = celebrity.name .. " launched a premium meal plan promotion!\nMembership fees increased by 30% for 3 days!"
					message.Parent = player
					game:GetService("Debris"):AddItem(message, 5)

					-- Remove boost after duration
					spawn(function()
						wait(60 * 60 * 24 * 3) -- 3 days
						if tycoon then
							tycoon:SetAttribute("MealPlanBoost", nil)

							-- Notify end
							local endMessage = Instance.new("Message")
							endMessage.Text = "Meal plan promotion has ended."
							endMessage.Parent = player
							game:GetService("Debris"):AddItem(endMessage, 5)
						end
					end)

					success = true
				end
			end

			-- Set ability cooldown if successful
			if success then
				-- Set 1 week cooldown
				if not CelebrityTrainerSystem.playerTrainers[player.UserId] then
					CelebrityTrainerSystem.playerTrainers[player.UserId] = {}
				end

				if not CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId] then
					CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId] = {}
				end

				CelebrityTrainerSystem.playerTrainers[player.UserId][celebrityId].ability_cooldown = os.time() + (60 * 60 * 24 * 7) -- 1 week
			end

			return success
		end

		-- Handle confirmation dialog for firing a trainer
		function CelebrityTrainerSystem.confirmFireTrainer(player, celebrityId)
			if not player or not celebrityId then return end

			local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
			if not celebrity then return end

			-- Create confirmation GUI
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "FireTrainerConfirmation"
			screenGui.ResetOnSpawn = false

			-- Create main frame
			local frame = Instance.new("Frame")
			frame.Name = "MainFrame"
			frame.Size = UDim2.new(0, 350, 0, 200)
			frame.Position = UDim2.new(0.5, -175, 0.5, -100)
			frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			frame.BackgroundTransparency = 0.1
			frame.BorderSizePixel = 0
			frame.Parent = screenGui

			-- Add rounded corners
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 10)
			corner.Parent = frame

			-- Add title
			local titleLabel = Instance.new("TextLabel")
			titleLabel.Name = "TitleLabel"
			titleLabel.Size = UDim2.new(1, -20, 0, 40)
			titleLabel.Position = UDim2.new(0, 10, 0, 10)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
			titleLabel.TextSize = 22
			titleLabel.Text = "Fire " .. celebrity.name .. "?"
			titleLabel.TextXAlignment = Enum.TextXAlignment.Center
			titleLabel.Parent = frame

			-- Add warning text
			local warningText = Instance.new("TextLabel")
			warningText.Name = "WarningText"
			warningText.Size = UDim2.new(1, -40, 0, 80)
			warningText.Position = UDim2.new(0, 20, 0, 60)
			warningText.BackgroundTransparency = 1
			warningText.Font = Enum.Font.Gotham
			warningText.TextColor3 = Color3.fromRGB(255, 255, 255)
			warningText.TextSize = 16
			warningText.TextWrapped = true
			warningText.Text = "Are you sure you want to fire " .. celebrity.name .. "? You will lose all benefits and will need to pay the full hiring cost to rehire them."
			warningText.Parent = frame

			-- Add buttons container
			local buttonsContainer = Instance.new("Frame")
			buttonsContainer.Name = "ButtonsContainer"
			buttonsContainer.Size = UDim2.new(1, -40, 0, 40)
			buttonsContainer.Position = UDim2.new(0, 20, 0, 150)
			buttonsContainer.BackgroundTransparency = 1
			buttonsContainer.Parent = frame

			-- Add cancel button
			local cancelButton = Instance.new("TextButton")
			cancelButton.Name = "CancelButton"
			cancelButton.Size = UDim2.new(0.48, 0, 1, 0)
			cancelButton.Position = UDim2.new(0, 0, 0, 0)
			cancelButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			cancelButton.Font = Enum.Font.GothamSemibold
			cancelButton.TextSize = 16
			cancelButton.Text = "Cancel"

			-- Add rounded corners
			local cancelCorner = Instance.new("UICorner")
			cancelCorner.CornerRadius = UDim.new(0, 6)
			cancelCorner.Parent = cancelButton

			-- Add confirm button
			local confirmButton = Instance.new("TextButton")
			confirmButton.Name = "ConfirmButton"
			confirmButton.Size = UDim2.new(0.48, 0, 1, 0)
			confirmButton.Position = UDim2.new(0.52, 0, 0, 0)
			confirmButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			confirmButton.Font = Enum.Font.GothamSemibold
			confirmButton.TextSize = 16
			confirmButton.Text = "Fire Trainer"

			-- Add rounded corners
			local confirmCorner = Instance.new("UICorner")
			confirmCorner.CornerRadius = UDim.new(0, 6)
			confirmCorner.Parent = confirmButton

			-- Connect buttons
			cancelButton.MouseButton1Click:Connect(function()
				screenGui:Destroy()
			end)

			confirmButton.MouseButton1Click:Connect(function()
				screenGui:Destroy()
				CelebrityTrainerSystem.fireTrainer(player, celebrityId)
			end)

			-- Parent buttons
			cancelButton.Parent = buttonsContainer
			confirmButton.Parent = buttonsContainer

			-- Parent GUI to player
			screenGui.Parent = player.PlayerGui
		end

		-- Process trainer salaries for all players
		function CelebrityTrainerSystem.processSalaries()
			local currentTime = os.time()

			for userId, trainers in pairs(CelebrityTrainerSystem.playerTrainers) do
				-- Get player from userId
				local player = Players:GetPlayerByUserId(userId)
				if not player then continue end

				-- Get player cash
				local leaderstats = player:FindFirstChild("leaderstats")
				if not leaderstats or not leaderstats:FindFirstChild("Cash") then continue end

				-- Process each trainer
				for celebrityId, trainerData in pairs(trainers) do
					local celebrity = CelebrityTrainerSystem.celebrities[celebrityId]
					if not celebrity then continue end

					-- Check if salary is due (weekly)
					local salaryInterval = 60 * 60 * 24 * 7 -- 1 week in seconds
					if currentTime - trainerData.last_salary_time >= salaryInterval then
						-- Check if player can afford salary
						if leaderstats.Cash.Value >= celebrity.salary then
							-- Deduct salary
							leaderstats.Cash.Value = leaderstats.Cash.Value - celebrity.salary

							-- Update last salary time
							trainerData.last_salary_time = currentTime

							-- Notify player
							local message = Instance.new("Message")
							message.Text = "You paid " .. celebrity.name .. " their weekly salary of $" .. celebrity.salary
							message.Parent = player
							game:GetService("Debris"):AddItem(message, 5)
						else
							-- Not enough money, fire the trainer
							CelebrityTrainerSystem.fireTrainer(player, celebrityId)

							-- Notify player
							local message = Instance.new("Message")
							message.Text = "You couldn't afford to pay " .. celebrity.name .. "'s salary of $" .. celebrity.salary .. ". They've left your gym."
							message.Parent = player
							game:GetService("Debris"):AddItem(message, 5)
						end
					end
				end
			end
		end

		-- Create a GUI to browse and hire trainers
		function CelebrityTrainerSystem.showTrainerBrowser(player)
			if not player then return end

			-- Create trainer browser GUI
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "TrainerBrowser"
			screenGui.ResetOnSpawn = false

			-- Create main frame
			local frame = Instance.new("Frame")
			frame.Name = "MainFrame"
			frame.Size = UDim2.new(0, 800, 0, 500)
			frame.Position = UDim2.new(0.5, -400, 0.5, -250)
			frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			frame.BackgroundTransparency = 0.1
			frame.BorderSizePixel = 0
			frame.Parent = screenGui

			-- Add rounded corners
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 10)
			corner.Parent = frame

			-- Add title
			local titleLabel = Instance.new("TextLabel")
			titleLabel.Name = "TitleLabel"
			titleLabel.Size = UDim2.new(1, -20, 0, 50)
			titleLabel.Position = UDim2.new(0, 10, 0, 10)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			titleLabel.TextSize = 28
			titleLabel.Text = "Celebrity Trainers"
			titleLabel.TextXAlignment = Enum.TextXAlignment.Center
			titleLabel.Parent = frame

			-- Add subtitle
			local subtitleLabel = Instance.new("TextLabel")
			subtitleLabel.Name = "SubtitleLabel"
			subtitleLabel.Size = UDim2.new(1, -20, 0, 30)
			subtitleLabel.Position = UDim2.new(0, 10, 0, 60)
			subtitleLabel.BackgroundTransparency = 1
			subtitleLabel.Font = Enum.Font.Gotham
			subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			subtitleLabel.TextSize = 18
			subtitleLabel.Text = "Hire world-class trainers to boost your gym's performance"
			subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
			subtitleLabel.Parent = frame

			-- Add trainers container
			local trainersContainer = Instance.new("ScrollingFrame")
			trainersContainer.Name = "TrainersContainer"
			trainersContainer.Size = UDim2.new(1, -40, 0, 380)
			trainersContainer.Position = UDim2.new(0, 20, 0, 100)
			trainersContainer.BackgroundTransparency = 1
			trainersContainer.BorderSizePixel = 0
			trainersContainer.ScrollBarThickness = 6
			trainersContainer.Parent = frame

			-- Create trainer cards
			local yOffset = 0
			local availableTrainers = {}

			-- Check which trainers are available
			for id, celebrity in pairs(CelebrityTrainerSystem.celebrities) do
				-- Check if trainer is available
				local isAvailable = true

				-- Check if trainer is already hired by this player
				if CelebrityTrainerSystem.playerTrainers[player.UserId] and 
					CelebrityTrainerSystem.playerTrainers[player.UserId][id] then
					isAvailable = false
				end

				-- Check if trainer is hired by another player
				for _, unavailableId in ipairs(CelebrityTrainerSystem.availableTrainers) do
					if unavailableId == id then
						isAvailable = false
						break
					end
				end

				if isAvailable then
					table.insert(availableTrainers, id)
				end
			end

			-- Add trainer cards
			for i, id in ipairs(availableTrainers) do
				local celebrity = CelebrityTrainerSystem.celebrities[id]

				-- Create trainer card
				local card = Instance.new("Frame")
				card.Name = id .. "Card"
				card.Size = UDim2.new(1, 0, 0, 150)
				card.Position = UDim2.new(0, 0, 0, yOffset)
				card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				card.BorderSizePixel = 0

				-- Add rounded corners
				local cardCorner = Instance.new("UICorner")
				cardCorner.CornerRadius = UDim.new(0, 8)
				cardCorner.Parent = card

				-- Add trainer icon placeholder
				local iconFrame = Instance.new("Frame")
				iconFrame.Name = "IconFrame"
				iconFrame.Size = UDim2.new(0, 100, 0, 100)
				iconFrame.Position = UDim2.new(0, 20, 0, 25)
				iconFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				iconFrame.Parent = card

				-- Add rounded corners to icon
				local iconCorner = Instance.new("UICorner")
				iconCorner.CornerRadius = UDim.new(0, 8)
				iconCorner.Parent = iconFrame

				-- Add trainer icon if available
				if celebrity.appearance.icon then
					local icon = Instance.new("ImageLabel")
					icon.Name = "Icon"
					icon.Size = UDim2.new(1, 0, 1, 0)
					icon.BackgroundTransparency = 1
					icon.Image = celebrity.appearance.icon
					icon.Parent = iconFrame

					-- Add rounded corners to icon
					local imgCorner = Instance.new("UICorner")
					imgCorner.CornerRadius = UDim.new(0, 8)
					imgCorner.Parent = icon
				end

				-- Add trainer name
				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "NameLabel"
				nameLabel.Size = UDim2.new(0, 300, 0, 30)
				nameLabel.Position = UDim2.new(0, 140, 0, 20)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				nameLabel.TextSize = 20
				nameLabel.Text = celebrity.name
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Parent = card

				-- Add specialty label
				local specialtyLabel = Instance.new("TextLabel")
				specialtyLabel.Name = "SpecialtyLabel"
				specialtyLabel.Size = UDim2.new(0, 200, 0, 20)
				specialtyLabel.Position = UDim2.new(0, 140, 0, 50)
				specialtyLabel.BackgroundTransparency = 1
				specialtyLabel.Font = Enum.Font.Gotham
				specialtyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				specialtyLabel.TextSize = 16
				specialtyLabel.Text = "Specialty: " .. celebrity.specialty:sub(1,1):upper() .. celebrity.specialty:sub(2)
				specialtyLabel.TextXAlignment = Enum.TextXAlignment.Left
				specialtyLabel.Parent = card

				-- Add description
				local descriptionLabel = Instance.new("TextLabel")
				descriptionLabel.Name = "DescriptionLabel"
				descriptionLabel.Size = UDim2.new(0, 400, 0, 40)
				descriptionLabel.Position = UDim2.new(0, 140, 0, 75)
				descriptionLabel.BackgroundTransparency = 1
				descriptionLabel.Font = Enum.Font.Gotham
				descriptionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				descriptionLabel.TextSize = 14
				descriptionLabel.Text = celebrity.description
				descriptionLabel.TextWrapped = true
				descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
				descriptionLabel.Parent = card

				-- Add hire button
				local hireButton = Instance.new("TextButton")
				hireButton.Name = "HireButton"
				hireButton.Size = UDim2.new(0, 120, 0, 40)
				hireButton.Position = UDim2.new(1, -140, 0, 55)
				hireButton.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
				hireButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				hireButton.Font = Enum.Font.GothamBold
				hireButton.TextSize = 16
				hireButton.Text = "Hire: $" .. celebrity.hiring_cost

				-- Add rounded corners
				local buttonCorner = Instance.new("UICorner")
				buttonCorner.CornerRadius = UDim.new(0, 6)
				buttonCorner.Parent = hireButton

				-- Check if player meets requirements
				local meetsRequirements, reason = CelebrityTrainerSystem.checkRequirements(player, id)

				if not meetsRequirements then
					-- Disable button
					hireButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					hireButton.Text = "Unavailable"

					-- Add tooltip with reason
					local tooltip = Instance.new("TextLabel")
					tooltip.Name = "Tooltip"
					tooltip.Size = UDim2.new(0, 200, 0, 30)
					tooltip.Position = UDim2.new(1, -200, 0, 95)
					tooltip.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
					tooltip.BackgroundTransparency = 0.5
					tooltip.TextColor3 = Color3.fromRGB(255, 100, 100)
					tooltip.Font = Enum.Font.Gotham
					tooltip.TextSize = 12
					tooltip.Text = reason
					tooltip.TextWrapped = true
					tooltip.Visible = false

					-- Add rounded corners
					local tooltipCorner = Instance.new("UICorner")
					tooltipCorner.CornerRadius = UDim.new(0, 4)
					tooltipCorner.Parent = tooltip

					tooltip.Parent = card

					-- Show tooltip on hover
					hireButton.MouseEnter:Connect(function()
						tooltip.Visible = true
					end)

					hireButton.MouseLeave:Connect(function()
						tooltip.Visible = false
					end)
				else
					-- Connect hire button
					hireButton.MouseButton1Click:Connect(function()
						-- Close browser
						screenGui:Destroy()

						-- Hire trainer
						CelebrityTrainerSystem.hireTrainer(player, id)
					end)
				end

				hireButton.Parent = card

				-- Add salary info
				local salaryLabel = Instance.new("TextLabel")
				salaryLabel.Name = "SalaryLabel"
				salaryLabel.Size = UDim2.new(0, 120, 0, 20)
				salaryLabel.Position = UDim2.new(1, -140, 0, 100)
				salaryLabel.BackgroundTransparency = 1
				salaryLabel.Font = Enum.Font.Gotham
				salaryLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				salaryLabel.TextSize = 12
				salaryLabel.Text = "Salary: $" .. celebrity.salary .. "/week"
				salaryLabel.Parent = card

				-- Parent card to container
				card.Parent = trainersContainer

				-- Update y offset for next card
				yOffset = yOffset + 165
			end

			-- Update container canvas size
			trainersContainer.CanvasSize = UDim2.new(0, 0, 0, yOffset)

			-- Add close button
			local closeButton = Instance.new("TextButton")
			closeButton.Name = "CloseButton"
			closeButton.Size = UDim2.new(0, 30, 0, 30)
			closeButton.Position = UDim2.new(1, -40, 0, 10)
			closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			closeButton.Font = Enum.Font.GothamBold
			closeButton.TextSize = 18
			closeButton.Text = "X"

			-- Add rounded corners
			local closeCorner = Instance.new("UICorner")
			closeCorner.CornerRadius = UDim.new(0, 15)
			closeCorner.Parent = closeButton

			-- Connect close button
			closeButton.MouseButton1Click:Connect(function()
				screenGui:Destroy()
			end)

			closeButton.Parent = frame

			-- Parent GUI to player
			screenGui.Parent = player.PlayerGui
		end

		-- Create remotes for client-server communication
		function CelebrityTrainerSystem.createRemotes()
			-- Create remotes folder if it doesn't exist
			local remotes = ReplicatedStorage:FindFirstChild("TrainerRemotes")
			if not remotes then
				remotes = Instance.new("Folder")
				remotes.Name = "TrainerRemotes"
				remotes.Parent = ReplicatedStorage
			end

			-- Create remotes
			local functions = {
				showTrainerBrowser = Instance.new("RemoteFunction"),
				hireTrainer = Instance.new("RemoteFunction"),
				fireTrainer = Instance.new("RemoteFunction"),
				interactWithTrainer = Instance.new("RemoteFunction")
			}

			-- Parent and set up remotes
			for name, remote in pairs(functions) do
				remote.Name = name
				remote.Parent = remotes
			end

			-- Connect remote functions
			functions.showTrainerBrowser.OnServerInvoke = function(player)
				CelebrityTrainerSystem.showTrainerBrowser(player)
				return true
			end

			functions.hireTrainer.OnServerInvoke = function(player, celebrityId)
				return CelebrityTrainerSystem.hireTrainer(player, celebrityId)
			end

			functions.fireTrainer.OnServerInvoke = function(player, celebrityId)
				return CelebrityTrainerSystem.fireTrainer(player, celebrityId)
			end

			functions.interactWithTrainer.OnServerInvoke = function(player, celebrityId)
				CelebrityTrainerSystem.interactWithTrainer(player, celebrityId)
				return true
			end
		end

		-- Start salary processing loop
		function CelebrityTrainerSystem.startSalaryLoop()
			spawn(function()
				while true do
					wait(60) -- Check every minute
					CelebrityTrainerSystem.processSalaries()
				end
			end)
		end

		-- Initialize the system
		function CelebrityTrainerSystem.initialize()
			print("Initializing Celebrity Trainer System...")

			-- Create remote functions
			CelebrityTrainerSystem.createRemotes()

			-- Start salary processing
			CelebrityTrainerSystem.startSalaryLoop()

			-- Set up player events
			Players.PlayerRemoving:Connect(function(player)
				-- Clean up player data when they leave
				if CelebrityTrainerSystem.playerTrainers[player.UserId] then
					CelebrityTrainerSystem.playerTrainers[player.UserId] = nil
				end
			end)

			print("Celebrity Trainer System initialized!")
		end

		-- Initialize the system
		CelebrityTrainerSystem.initialize()

		-- Return the module
		return CelebrityTrainerSystem
	end
end
