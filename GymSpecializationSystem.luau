-- GymSpecializationSystem.lua
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Try to load dependencies
local DataStorage
pcall(function()
	DataStorage = require(ServerScriptService:FindFirstChild("DataStorageSystem"))
end)

local GymRevenue
pcall(function()
	GymRevenue = require(ServerScriptService:FindFirstChild("GymRevenueSystem"))
end)

local SpecializationSystem = {
	specializations = {
		bodybuilding = {
			name = "Bodybuilding",
			description = "Focus on strength training and muscle growth",
			level_requirement = 3,
			benefits = {
				membership_boost = 1.2,  -- 20% more members
				vip_chance = 0.15,       -- Increased VIP chance (15% vs standard 10%)
				equipment_discounts = {  -- Discounts on related equipment
					weights = 0.2,       -- 20% off weight equipment
					machines = 0.1       -- 10% off machines
				}
			},
			equipment_tags = {"weights", "bench", "rack"}
		},
		cardio = {
			name = "Cardio Fitness",
			description = "Focus on cardiovascular health and endurance",
			level_requirement = 3,
			benefits = {
				dues_boost = 1.15,       -- Members pay 15% more
				membership_retention = 1.25, -- 25% better member retention
				equipment_discounts = {
					treadmill = 0.2,     -- 20% off treadmills
					cardio = 0.15        -- 15% off cardio equipment
				}
			},
			equipment_tags = {"treadmill", "bike", "cardio"}
		},
		luxury = {
			name = "Luxury Wellness",
			description = "Premium experience with spa and wellness features",
			level_requirement = 5,
			benefits = {
				vip_multiplier = 2.0,    -- VIPs pay double the standard boost
				vip_chance = 0.2,        -- 20% chance for VIPs
				membership_boost = 0.9,  -- 10% fewer total members
				dues_boost = 1.3         -- 30% higher membership fees
			},
			equipment_tags = {"spa", "sauna", "luxury"}
		},
		crossfit = {
			name = "CrossFit Training",
			description = "High-intensity functional training approach",
			level_requirement = 4,
			benefits = {
				membership_boost = 1.1,  -- 10% more members
				dues_boost = 1.1,        -- 10% higher dues
				competition_boost = 1.3  -- 30% better competition results
			},
			equipment_tags = {"functional", "crossfit", "box"}
		}
	},

	playerSpecializations = {} -- Format: {userId = {primary = name, secondary = name}}
}

-- Get available specializations for a player
function SpecializationSystem.getAvailableSpecializations(player)
	if not player then return {} end

	local available = {}
	local gymLevel = 1

	-- Get gym level
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or 1
	end

	-- Filter specializations by level requirement
	for id, specialization in pairs(SpecializationSystem.specializations) do
		if gymLevel >= specialization.level_requirement then
			table.insert(available, {
				id = id,
				name = specialization.name,
				description = specialization.description,
				level_requirement = specialization.level_requirement
			})
		end
	end

	return available
end

-- Get current specialization(s) for a player
function SpecializationSystem.getPlayerSpecializations(player)
	if not player then return nil end

	local userId = player.UserId

	-- Check cached data
	if SpecializationSystem.playerSpecializations[userId] then
		-- Create a specialized gym decor based on the player's specialization
		function SpecializationSystem.createSpecializationDecor(player)
			if not player then return end

			local tycoon = player:FindFirstChild("Tycoon")
			if not tycoon or not tycoon.Value then return end

			local specs = SpecializationSystem.getPlayerSpecializations(player)
			if not specs.primary then return end -- Only create decor for primary specialization

			local specialization = SpecializationSystem.specializations[specs.primary]
			if not specialization then return end

			-- Check if decor already exists
			local existingDecor = tycoon.Value:FindFirstChild("SpecializationDecor")
			if existingDecor then
				existingDecor:Destroy()
			end

			-- Create decor model
			local decor = Instance.new("Model")
			decor.Name = "SpecializationDecor"

			-- Create different decor based on specialization
			if specs.primary == "bodybuilding" then
				-- Create bodybuilding decor (posters, trophy case)
				local poster = Instance.new("Part")
				poster.Name = "BodybuildingPoster"
				poster.Size = Vector3.new(4, 3, 0.1)
				poster.Anchored = true
				poster.CanCollide = false

				-- Find a wall to place it on
				local position
				for _, part in pairs(tycoon.Value:GetDescendants()) do
					if part:IsA("BasePart") and part.Size.Y > 5 and part.Size.X > 4 then
						position = part.Position + part.CFrame.LookVector * (part.Size.Z/2 + 0.1)
						break
					end
				end

				if position then
					poster.Position = position + Vector3.new(0, 1, 0)

					-- Add surface GUI with image
					local surfaceGui = Instance.new("SurfaceGui")
					surfaceGui.Face = Enum.NormalId.Front
					surfaceGui.Parent = poster

					local posterImage = Instance.new("ImageLabel")
					posterImage.Size = UDim2.new(1, 0, 1, 0)
					posterImage.BackgroundTransparency = 1
					posterImage.Image = "rbxassetid://2637579692" -- Example bodybuilding image
					posterImage.Parent = surfaceGui

					poster.Parent = decor
				end

			elseif specs.primary == "cardio" then
				-- Create cardio decor (running track markers)
				for i = 1, 5 do
					local marker = Instance.new("Part")
					marker.Name = "TrackMarker"..i
					marker.Size = Vector3.new(0.5, 0.1, 0.5)
					marker.BrickColor = BrickColor.new("Bright red")
					marker.Material = Enum.Material.Neon
					marker.Anchored = true
					marker.CanCollide = false

					-- Find floor to place markers on
					local floor
					for _, part in pairs(tycoon.Value:GetDescendants()) do
						if part:IsA("BasePart") and part.Size.X > 10 and part.Size.Z > 10 and 
							math.abs(part.CFrame.UpVector.Y) > 0.9 then
							floor = part
							break
						end
					end

					if floor then
						local angle = (i / 5) * math.pi * 2
						local radius = 5
						local offsetX = math.cos(angle) * radius
						local offsetZ = math.sin(angle) * radius

						marker.Position = floor.Position + Vector3.new(offsetX, floor.Size.Y/2 + 0.1, offsetZ)
						marker.Parent = decor
					end
				end

			elseif specs.primary == "luxury" then
				-- Create luxury decor (fancy reception desk, plant)
				local plant = Instance.new("Part")
				plant.Name = "LuxuryPlant"
				plant.Size = Vector3.new(1, 2, 1)
				plant.BrickColor = BrickColor.new("Forest green")
				plant.Material = Enum.Material.Grass
				plant.Anchored = true

				local pot = Instance.new("Part")
				pot.Name = "PlantPot"
				pot.Size = Vector3.new(1.2, 0.5, 1.2)
				pot.BrickColor = BrickColor.new("Pearl")
				pot.Material = Enum.Material.Marble
				pot.Anchored = true

				-- Find spot near entrance
				local entrance
				for _, part in pairs(tycoon.Value:GetDescendants()) do
					if part:IsA("BasePart") and (part.Name:lower():find("entrance") or part.Name:lower():find("door")) then
						entrance = part
						break
					end
				end

				if entrance then
					pot.Position = entrance.Position + Vector3.new(2, 0, 2)
					plant.Position = pot.Position + Vector3.new(0, 1.25, 0)

					pot.Parent = decor
					plant.Parent = decor
				end

			elseif specs.primary == "crossfit" then
				-- Create crossfit decor (rope, chalk bucket)
				local chalk = Instance.new("Part")
				chalk.Name = "ChalkBucket"
				chalk.Size = Vector3.new(0.8, 0.5, 0.8)
				chalk.BrickColor = BrickColor.new("Institutional white")
				chalk.Material = Enum.Material.SmoothPlastic
				chalk.Anchored = true

				-- Find a spot in the center
				local center
				for _, part in pairs(tycoon.Value:GetDescendants()) do
					if part.Name == "Platform" or (part:IsA("BasePart") and part.Size.X > 10 and part.Size.Z > 10) then
						center = part
						break
					end
				end

				if center then
					chalk.Position = center.Position + Vector3.new(0, center.Size.Y/2 + 0.25, 0)
					chalk.Parent = decor
				end
			end

			-- Parent decor to tycoon
			decor.Parent = tycoon.Value

			return decor
		end

		-- Pack all functions into a module
		return SpecializationSystem.playerSpecializations[userId]
	end

	-- Load from data storage
	if DataStorage and DataStorage.loadedData[userId] then
		local data = DataStorage.loadedData[userId]
		if data.specializations then
			SpecializationSystem.playerSpecializations[userId] = data.specializations
			return data.specializations
		end
	end

	-- Default to no specialization
	return { primary = nil, secondary = nil }
end

-- Set player specialization
function SpecializationSystem.setSpecialization(player, specializationId, isSecondary)
	if not player or not specializationId then return false end

	-- Check if specialization exists
	if not SpecializationSystem.specializations[specializationId] then
		return false, "Invalid specialization"
	end

	local userId = player.UserId
	local gymLevel = 1

	-- Get gym level
	local tycoon = player:FindFirstChild("Tycoon")
	if tycoon then
		gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or 1
	end

	-- Check level requirement
	local specialization = SpecializationSystem.specializations[specializationId]
	if gymLevel < specialization.level_requirement then
		return false, "Gym level too low. Requires level " .. specialization.level_requirement
	end

	-- Get current specializations
	local current = SpecializationSystem.getPlayerSpecializations(player)

	-- Update specialization
	if isSecondary then
		-- Can't have same primary and secondary
		if current.primary == specializationId then
			return false, "Cannot set the same specialization as both primary and secondary"
		end
		current.secondary = specializationId
	else
		-- Can't have same primary and secondary
		if current.secondary == specializationId then
			return false, "Cannot set the same specialization as both primary and secondary"
		end
		current.primary = specializationId
	end

	-- Update cache
	SpecializationSystem.playerSpecializations[userId] = current

	-- Save to data storage
	if DataStorage and DataStorage.loadedData[userId] then
		local data = DataStorage.loadedData[userId]
		data.specializations = current

		-- Save immediately
		if DataStorage.saveData then
			DataStorage.saveData(player)
		end
	end

	-- Apply specialization benefits
	SpecializationSystem.applySpecializationBenefits(player)

	return true, "Specialization set successfully"
end

-- Apply specialization benefits to a player
function SpecializationSystem.applySpecializationBenefits(player)
	if not player then return end

	local userId = player.UserId
	local specs = SpecializationSystem.getPlayerSpecializations(player)

	-- No specializations
	if not specs.primary and not specs.secondary then
		return
	end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then return end

	-- Reset to base values
	tycoon:SetAttribute("SpecMembershipBoost", 1.0)
	tycoon:SetAttribute("SpecDuesBoost", 1.0)
	tycoon:SetAttribute("SpecVIPChance", 0.1) -- Default 10%
	tycoon:SetAttribute("SpecVIPMultiplier", 1.0)
	tycoon:SetAttribute("SpecCompetitionBoost", 1.0)

	-- Apply primary specialization benefits
	if specs.primary then
		local primary = SpecializationSystem.specializations[specs.primary]
		if primary then
			-- Membership boost
			if primary.benefits.membership_boost then
				tycoon:SetAttribute("SpecMembershipBoost", primary.benefits.membership_boost)
			end

			-- Dues boost
			if primary.benefits.dues_boost then
				tycoon:SetAttribute("SpecDuesBoost", primary.benefits.dues_boost)
			end

			-- VIP chance
			if primary.benefits.vip_chance then
				tycoon:SetAttribute("SpecVIPChance", primary.benefits.vip_chance)
			end

			-- VIP multiplier
			if primary.benefits.vip_multiplier then
				tycoon:SetAttribute("SpecVIPMultiplier", primary.benefits.vip_multiplier)
			end

			-- Competition boost
			if primary.benefits.competition_boost then
				tycoon:SetAttribute("SpecCompetitionBoost", primary.benefits.competition_boost)
			end
		end
	end

	-- Apply secondary specialization benefits (at half strength)
	if specs.secondary then
		local secondary = SpecializationSystem.specializations[specs.secondary]
		if secondary then
			-- Membership boost (half effect)
			if secondary.benefits.membership_boost then
				local currentBoost = tycoon:GetAttribute("SpecMembershipBoost")
				local secondaryEffect = (secondary.benefits.membership_boost - 1.0) * 0.5
				tycoon:SetAttribute("SpecMembershipBoost", currentBoost + secondaryEffect)
			end

			-- Dues boost (half effect)
			if secondary.benefits.dues_boost then
				local currentBoost = tycoon:GetAttribute("SpecDuesBoost")
				local secondaryEffect = (secondary.benefits.dues_boost - 1.0) * 0.5
				tycoon:SetAttribute("SpecDuesBoost", currentBoost + secondaryEffect)
			end

			-- VIP chance (half effect)
			if secondary.benefits.vip_chance then
				local currentChance = tycoon:GetAttribute("SpecVIPChance")
				local secondaryEffect = (secondary.benefits.vip_chance - 0.1) * 0.5
				tycoon:SetAttribute("SpecVIPChance", currentChance + secondaryEffect)
			end

			-- VIP multiplier (half effect)
			if secondary.benefits.vip_multiplier then
				local currentMultiplier = tycoon:GetAttribute("SpecVIPMultiplier")
				local secondaryEffect = (secondary.benefits.vip_multiplier - 1.0) * 0.5
				tycoon:SetAttribute("SpecVIPMultiplier", currentMultiplier + secondaryEffect)
			end

			-- Competition boost (half effect)
			if secondary.benefits.competition_boost then
				local currentBoost = tycoon:GetAttribute("SpecCompetitionBoost")
				local secondaryEffect = (secondary.benefits.competition_boost - 1.0) * 0.5
				tycoon:SetAttribute("SpecCompetitionBoost", currentBoost + secondaryEffect)
			end
		end
	end

	-- Apply equipment discounts
	-- (Implementation depends on your BuyTile system)

	-- Update the EconomySystem config if needed
	if GymRevenue then
		GymRevenue.updatePlayerConfig(player)
	end
end

-- Create specialization UI for a player
function SpecializationSystem.createUI(player)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpecializationGui"
	screenGui.ResetOnSpawn = false

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 600, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	-- Add rounded corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Text = "Gym Specialization"
	title.Parent = mainFrame

	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -40, 0, 40)
	description.Position = UDim2.new(0, 20, 0, 40)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.TextColor3 = Color3.fromRGB(200, 200, 200)
	description.TextSize = 16
	description.TextWrapped = true
	description.Text = "Choose a specialization to focus your gym and receive unique bonuses."
	description.Parent = mainFrame

	-- Specialization container
	local container = Instance.new("ScrollingFrame")
	container.Name = "SpecContainer"
	container.Size = UDim2.new(1, -40, 1, -140)
	container.Position = UDim2.new(0, 20, 0, 90)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ScrollBarThickness = 6
	container.ScrollingDirection = Enum.ScrollingDirection.Y
	container.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set dynamically
	container.Parent = mainFrame

	-- Add list layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	-- Current specialization label
	local currentLabel = Instance.new("TextLabel")
	currentLabel.Name = "CurrentSpecLabel"
	currentLabel.Size = UDim2.new(1, -40, 0, 30)
	currentLabel.Position = UDim2.new(0, 20, 1, -40)
	currentLabel.BackgroundTransparency = 1
	currentLabel.Font = Enum.Font.GothamSemibold
	currentLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
	currentLabel.TextSize = 16
	currentLabel.TextWrapped = true
	currentLabel.Text = "Current Primary: None | Secondary: None"
	currentLabel.Parent = mainFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 18
	closeButton.Text = "X"
	closeButton.Parent = mainFrame

	-- Add rounded corners to close button
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 15)
	closeCorner.Parent = closeButton

	-- Connect close button
	closeButton.MouseButton1Click:Connect(function()
		SpecializationSystem.hideUI(player)
	end)

	screenGui.Parent = player.PlayerGui
	return screenGui
end

-- Create a specialization card
function SpecializationSystem.createSpecCard(container, specId, specData, isPrimary, isSecondary, isAvailable)
	local card = Instance.new("Frame")
	card.Name = specId .. "Card"
	card.Size = UDim2.new(1, 0, 0, 120)
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

	-- Change background color based on selection
	if isPrimary then
		card.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
	elseif isSecondary then
		card.BackgroundColor3 = Color3.fromRGB(0, 80, 140)
	end

	card.BorderSizePixel = 0

	-- Add rounded corners
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -130, 0, 30)
	title.Position = UDim2.new(0, 15, 0, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = specData.name
	title.Parent = card

	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -130, 0, 50)
	description.Position = UDim2.new(0, 15, 0, 40)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.TextColor3 = Color3.fromRGB(220, 220, 220)
	description.TextSize = 14
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.Text = specData.description
	description.Parent = card

	-- Level requirement
	local levelReq = Instance.new("TextLabel")
	levelReq.Name = "LevelReq"
	levelReq.Size = UDim2.new(1, -130, 0, 20)
	levelReq.Position = UDim2.new(0, 15, 0, 90)
	levelReq.BackgroundTransparency = 1
	levelReq.Font = Enum.Font.Gotham
	levelReq.TextColor3 = Color3.fromRGB(180, 180, 180)
	levelReq.TextSize = 12
	levelReq.TextXAlignment = Enum.TextXAlignment.Left
	levelReq.Text = "Requires Level " .. specData.level_requirement
	levelReq.Parent = card

	-- Primary button
	local primaryButton = Instance.new("TextButton")
	primaryButton.Name = "PrimaryButton"
	primaryButton.Size = UDim2.new(0, 100, 0, 30)
	primaryButton.Position = UDim2.new(1, -115, 0, 25)
	primaryButton.BackgroundColor3 = isPrimary and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(0, 120, 180)
	primaryButton.Font = Enum.Font.GothamBold
	primaryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	primaryButton.TextSize = 14
	primaryButton.Text = isPrimary and "PRIMARY" or "Set Primary"
	primaryButton.Parent = card

	-- Add rounded corners to button
	local primaryCorner = Instance.new("UICorner")
	primaryCorner.CornerRadius = UDim.new(0, 6)
	primaryCorner.Parent = primaryButton

	-- Secondary button
	local secondaryButton = Instance.new("TextButton")
	secondaryButton.Name = "SecondaryButton"
	secondaryButton.Size = UDim2.new(0, 100, 0, 30)
	secondaryButton.Position = UDim2.new(1, -115, 0, 65)
	secondaryButton.BackgroundColor3 = isSecondary and Color3.fromRGB(0, 160, 0) or Color3.fromRGB(0, 100, 160)
	secondaryButton.Font = Enum.Font.GothamBold
	secondaryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	secondaryButton.TextSize = 14
	secondaryButton.Text = isSecondary and "SECONDARY" or "Set Secondary"
	secondaryButton.Parent = card

	-- Add rounded corners to button
	local secondaryCorner = Instance.new("UICorner")
	secondaryCorner.CornerRadius = UDim.new(0, 6)
	secondaryCorner.Parent = secondaryButton

	-- Disable if not available
	if not isAvailable then
		primaryButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		secondaryButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		primaryButton.Text = "Locked"
		secondaryButton.Text = "Locked"
		primaryButton.Enabled = false
		secondaryButton.Enabled = false
	end

	card.Parent = container
	return card
end

-- Show the specialization UI
function SpecializationSystem.showUI(player)
	-- Find or create the UI
	local gui = player.PlayerGui:FindFirstChild("SpecializationGui")
	if not gui then
		gui = SpecializationSystem.createUI(player)
	end

	local mainFrame = gui.MainFrame
	local container = mainFrame.SpecContainer

	-- Clear container
	for _, child in pairs(container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get current specializations
	local currentSpecs = SpecializationSystem.getPlayerSpecializations(player)
	local primarySpec = currentSpecs.primary
	local secondarySpec = currentSpecs.secondary

	-- Update current spec label
	local currentLabel = mainFrame.CurrentSpecLabel
	local primaryName = primarySpec and SpecializationSystem.specializations[primarySpec].name or "None"
	local secondaryName = secondarySpec and SpecializationSystem.specializations[secondarySpec].name or "None"
	currentLabel.Text = "Current Primary: " .. primaryName .. " | Secondary: " .. secondaryName

	-- Get available specializations
	local available = SpecializationSystem.getAvailableSpecializations(player)
	local availableIds = {}
	for _, spec in ipairs(available) do
		availableIds[spec.id] = true
	end

	-- Create cards for all specializations
	local index = 0
	for id, specialization in pairs(SpecializationSystem.specializations) do
		local isPrimary = id == primarySpec
		local isSecondary = id == secondarySpec
		local isAvailable = availableIds[id] or false

		local card = SpecializationSystem.createSpecCard(
			container, 
			id, 
			specialization, 
			isPrimary, 
			isSecondary, 
			isAvailable
		)

		-- Set layout order
		card.LayoutOrder = index
		index = index + 1

		-- Connect buttons
		if isAvailable then
			local primaryButton = card.PrimaryButton
			local secondaryButton = card.SecondaryButton

			primaryButton.MouseButton1Click:Connect(function()
				if not isPrimary then
					SpecializationSystem.setSpecialization(player, id, false)
					-- Refresh UI
					SpecializationSystem.showUI(player)
				end
			end)

			secondaryButton.MouseButton1Click:Connect(function()
				if not isSecondary then
					SpecializationSystem.setSpecialization(player, id, true)
					-- Refresh UI
					SpecializationSystem.showUI(player)
				end
			end)
		end
	end

	-- Update canvas size
	container.CanvasSize = UDim2.new(0, 0, 0, index * 130)

	-- Show the UI
	mainFrame.Position = UDim2.new(0.5, -300, 0, -400)
	mainFrame.Visible = true

	local showTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -300, 0.5, -200)}
	)
	showTween:Play()
end

-- Hide the specialization UI
function SpecializationSystem.hideUI(player)
	local gui = player.PlayerGui:FindFirstChild("SpecializationGui")
	if not gui then return end

	local mainFrame = gui.MainFrame

	local hideTween = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, -300, 0, -400)}
	)
	hideTween:Play()

	hideTween.Completed:Connect(function()
		mainFrame.Visible = false
	end)
end

-- Initialize the system
function SpecializationSystem.initialize()
	-- Create remote function for client access
	local showSpecializationsRemote = Instance.new("RemoteFunction")
	showSpecializationsRemote.Name = "ShowSpecializationsMenu"
	showSpecializationsRemote.Parent = ReplicatedStorage

	-- Connect remote function
	showSpecializationsRemote.OnServerInvoke = function(player)
		-- Return specialization info for client-side UI
		local playerSpecs = SpecializationSystem.getPlayerSpecializations(player)
		local availableSpecs = SpecializationSystem.getAvailableSpecializations(player)

		return {
			current = playerSpecs,
			available = availableSpecs
		}
	end

	-- Create a command to open the specialization menu
	local openSpecMenuEvent = Instance.new("RemoteEvent")
	openSpecMenuEvent.Name = "OpenSpecializationMenu"
	openSpecMenuEvent.Parent = ReplicatedStorage

	-- Create a command bar for players
	local commandBar = Instance.new("ScreenGui")
	commandBar.Name = "GymCommandBar"
	commandBar.ResetOnSpawn = false

	-- Create a button for specializations
	local specButton = Instance.new("TextButton")
	specButton.Name = "SpecializationButton"
	specButton.Size = UDim2.new(0, 150, 0, 40)
	specButton.Position = UDim2.new(1, -160, 0, 100)
	specButton.AnchorPoint = Vector2.new(0, 0)
	specButton.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
	specButton.Font = Enum.Font.GothamBold
	specButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	specButton.TextSize = 14
	specButton.Text = "Specializations"

	-- Add rounded corners
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = specButton

	specButton.Parent = commandBar

	-- Create client-side script
	local clientScript = Instance.new("LocalScript")
	clientScript.Parent = commandBar
	clientScript.Source = [[
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        
        local openSpecMenuEvent = ReplicatedStorage:WaitForChild("OpenSpecializationMenu")
        local specButton = script.Parent:WaitForChild("SpecializationButton")
        
        specButton.MouseButton1Click:Connect(function()
            openSpecMenuEvent:FireServer()
        end)
    ]]

	-- Add commandBar to StarterGui
	local StarterGui = game:GetService("StarterGui")
	commandBar.Parent = StarterGui

	-- Connect to the remote event
	openSpecMenuEvent.OnServerEvent:Connect(function(player)
		SpecializationSystem.showUI(player)
	end)

	-- Handle existing players
	for _, player in pairs(Players:GetPlayers()) do
		SpecializationSystem.applySpecializationBenefits(player)
	end

	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		-- Wait for player to load
		player.CharacterAdded:Wait()
		wait(3)

		-- Apply specialization benefits
		SpecializationSystem.applySpecializationBenefits(player)
	end)

	-- Update economy configuration when the GymRevenue system is loaded
	if GymRevenue then
		for _, player in pairs(Players:GetPlayers()) do
			GymRevenue.updatePlayerConfig(player)
		end
	end

	print("Specialization System initialized")
end

-- Apply discounts to equipment purchases
function SpecializationSystem.applyEquipmentDiscount(player, equipmentId, basePrice)
	if not player or not equipmentId then return basePrice end

	local specs = SpecializationSystem.getPlayerSpecializations(player)
	local discount = 0

	-- Get equipment type from id or attributes
	local equipmentType = "unknown"

	-- Example: Extract equipment type from ID or name
	-- In a real implementation, you would need to map equipment IDs to types
	-- or set equipment type attributes in your BuyTile system
	if equipmentId:lower():find("treadmill") then
		equipmentType = "treadmill"
	elseif equipmentId:lower():find("bench") or equipmentId:lower():find("weight") then
		equipmentType = "weights"
	elseif equipmentId:lower():find("machine") then
		equipmentType = "machines"
	elseif equipmentId:lower():find("bike") then
		equipmentType = "cardio"
	elseif equipmentId:lower():find("spa") or equipmentId:lower():find("sauna") then
		equipmentType = "spa"
	elseif equipmentId:lower():find("crossfit") or equipmentId:lower():find("functional") then
		equipmentType = "functional"
	end

	-- Check primary specialization for discounts
	if specs.primary then
		local primary = SpecializationSystem.specializations[specs.primary]
		if primary and primary.benefits.equipment_discounts then
			local discounts = primary.benefits.equipment_discounts

			if discounts[equipmentType] then
				discount = discounts[equipmentType]
			end
		end
	end

	-- Check secondary specialization for discounts (half effect)
	if specs.secondary then
		local secondary = SpecializationSystem.specializations[specs.secondary]
		if secondary and secondary.benefits.equipment_discounts then
			local discounts = secondary.benefits.equipment_discounts

			if discounts[equipmentType] then
				-- Add half of the secondary discount
				discount = discount + (discounts[equipmentType] * 0.5)
			end
		end
	end

	-- Apply discount (capped at 50%)
	discount = math.min(discount, 0.5)
	local discountedPrice = math.floor(basePrice * (1 - discount))

	return discountedPrice
end