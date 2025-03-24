-- BasketballSystemController.lua
-- Place this in ServerScriptService

local ServerStorage = game:GetService("ServerStorage")
local workspace = game:GetService("Workspace")

print("Initializing Basketball Court Systems...")

-- Create GymParts in ServerStorage if it doesn't exist
local gymPartsStorage = ServerStorage:FindFirstChild("GymParts")
if not gymPartsStorage then
	gymPartsStorage = Instance.new("Folder")
	gymPartsStorage.Name = "GymParts"
	gymPartsStorage.Parent = ServerStorage
	print("Created GymParts folder in ServerStorage")
end

-- Create required structure in ServerStorage if needed
local function ensureFolder(parent, name)
	if not parent:FindFirstChild(name) then
		local newFolder = Instance.new("Folder")
		newFolder.Name = name
		newFolder.Parent = parent
		return newFolder
	end
	return parent:FindFirstChild(name)
end

-- Create storage hierarchy
local secondFloorStorage = ensureFolder(gymPartsStorage, "2nd Floor")
local basketballStorage = ensureFolder(secondFloorStorage, "Basketball")
local roofStorage = ensureFolder(gymPartsStorage, "Roof")
local trackAreaStorage = ensureFolder(roofStorage, "Track Area")
local fullCourtStorage = ensureFolder(trackAreaStorage, "Full Court")

-- Get workspace reference for runtime functionality
local GuiFolder = workspace:WaitForChild("GuiFolder")

-- Paths to court components in storage (will be copied to workspace when needed)
local storageComponents = {
	mainGoalPath = "GymParts.2nd Floor.Basketball.Basketball.Court.Half.NewGoal20",
	roofGoalPath = "GymParts.Roof.Track Area.Full Court.Full Court.Goal.Model",
	scoreboardsPath = "GymParts.2nd Floor.Basketball.Basketball.Gym.Scoreboards"
}

-- Runtime components (actual instances in workspace)
local runtimeComponents = {
	mainGoal = nil,
	roofGoal = nil,
	scoreboards = nil
}

-- Function to get path from storage
local function getFromPath(path, parent)
	parent = parent or ServerStorage
	local parts = string.split(path, ".")
	local current = parent

	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then return nil end
	end

	return current
end

-- Function to copy from storage to workspace when needed
local function setupBasketballCourt()
	print("Setting up basketball court instances in workspace...")

	-- Ensure workspace structure exists
	local workspaceGymParts = ensureFolder(workspace, "GymParts")
	local secondFloor = ensureFolder(workspaceGymParts, "2nd Floor")
	local basketball = ensureFolder(secondFloor, "Basketball")
	local roof = ensureFolder(workspaceGymParts, "Roof")
	local trackArea = ensureFolder(roof, "Track Area")
	local fullCourt = ensureFolder(trackArea, "Full Court")

	-- Copy from storage to workspace (only if needed)
	local function copyIfNeeded(storagePath, workspacePath)
		local storageObj = getFromPath(storagePath)
		if not storageObj then
			warn("Could not find " .. storagePath .. " in ServerStorage")
			return nil
		end

		local parts = string.split(workspacePath or storagePath, ".")
		local parent = workspace

		-- Navigate to parent folder in workspace
		for i = 1, #parts - 1 do
			parent = ensureFolder(parent, parts[i])
		end

		-- Check if already exists
		if parent:FindFirstChild(parts[#parts]) then
			return parent:FindFirstChild(parts[#parts])
		end

		-- Copy from storage
		local copy = storageObj:Clone()
		copy.Parent = parent
		return copy
	end

	-- Copy main components
	runtimeComponents.mainGoal = copyIfNeeded(storageComponents.mainGoalPath)
	runtimeComponents.roofGoal = copyIfNeeded(storageComponents.roofGoalPath)
	runtimeComponents.scoreboards = copyIfNeeded(storageComponents.scoreboardsPath)

	print("Basketball court setup complete")
end

-- Setup time management
local function setupTimeManagement()
	print("Setting up time management...")

	if not runtimeComponents.mainGoal then
		warn("Main goal not found. Skipping time management setup.")
		return
	end

	-- Get minute/second IntValues
	local timeboxes = runtimeComponents.mainGoal:FindFirstChild("HooperMaster Backstop")
	if not timeboxes or not timeboxes:FindFirstChild("Timeboxes") then
		warn("Timeboxes not found. Skipping time management setup.")
		return
	end

	local daktronics = timeboxes.Timeboxes:FindFirstChild("DAKTRONICS TIMEBOX")
	if not daktronics or not daktronics:FindFirstChild("TIME") then
		warn("DAKTRONICS TIMEBOX or TIME not found. Skipping time management setup.")
		return
	end

	local minutesValue = daktronics.TIME:FindFirstChild("Minutes")
	local secondsValue = daktronics.TIME:FindFirstChild("Second")

	if not minutesValue or not secondsValue then
		warn("Minutes or Second values not found. Skipping time management setup.")
		return
	end

	-- Minutes updater
	spawn(function()
		while true do
			task.wait(1)
			if GuiFolder and GuiFolder:FindFirstChild("Time") then
				minutesValue.Value = math.floor(GuiFolder.Time.Value / 60)
			end
		end
	end)

	-- Seconds updater
	spawn(function()
		while true do
			task.wait(1)
			if GuiFolder and GuiFolder:FindFirstChild("Time") then
				secondsValue.Value = GuiFolder.Time.Value % 60
			end
		end
	end)

	print("Time management setup complete")
end

-- Setup buzzer and light effects
local function setupBuzzerAndLights()
	print("Setting up buzzer and lights...")

	if not runtimeComponents.mainGoal then
		warn("Main goal not found. Skipping buzzer and lights setup.")
		return
	end

	-- Find the buzzer - use safer approach by searching for it
	local buzzer
	local buzzerFolder = runtimeComponents.mainGoal:FindFirstChild("Buzzer")

	if buzzerFolder then
		-- Search for the dots directly
		buzzer = buzzerFolder:FindFirstChild("Dots")

		-- If not found directly, search through children
		if not buzzer then
			for _, child in pairs(buzzerFolder:GetChildren()) do
				local dotsInChild = child:FindFirstChild("Dots")
				if dotsInChild then
					buzzer = dotsInChild
					break
				end
			end
		end
	end

	-- Buzzer updater (only if found)
	if buzzer then
		spawn(function()
			while true do
				task.wait(1)
				if GuiFolder and GuiFolder:FindFirstChild("Time") then
					if GuiFolder.Time.Value == 0 then
						buzzer.BrickColor = BrickColor.new("Really red")
						buzzer.Material = Enum.Material.Neon
					else
						buzzer.BrickColor = BrickColor.new("Black")
						buzzer.Material = Enum.Material.SmoothPlastic
					end
				end
			end
		end)
		print("Buzzer functionality set up")
	else
		warn("Could not find buzzer. Skipping buzzer functionality.")
	end

	-- Circle light
	local timeboxes = runtimeComponents.mainGoal:FindFirstChild("HooperMaster Backstop")
	if not timeboxes or not timeboxes:FindFirstChild("Timeboxes") then
		warn("Timeboxes not found. Skipping circle light setup.")
		return
	end

	local daktronics = timeboxes.Timeboxes:FindFirstChild("DAKTRONICS TIMEBOX")
	if not daktronics or not daktronics:FindFirstChild("TIME") then
		warn("DAKTRONICS TIMEBOX or TIME not found. Skipping circle light setup.")
		return
	end

	local circle = daktronics.TIME:FindFirstChild("Circle1")

	-- Circle light updater
	if circle then
		spawn(function()
			while true do
				task.wait(1)
				if GuiFolder and GuiFolder:FindFirstChild("Time") then
					local yellowColor = Color3.fromRGB(255, 255, 0)
					local defaultColor = Color3.fromRGB(70, 67, 69)

					if GuiFolder.Time.Value < 60 then
						circle.Color = yellowColor
						if circle.Parent:FindFirstChild("Circle") then
							circle.Parent.Circle.Color = yellowColor
						end
					else
						circle.Color = yellowColor
						if circle.Parent:FindFirstChild("Circle") then
							circle.Parent.Circle.Color = yellowColor
						end
					end
				end
			end
		end)
		print("Circle light functionality set up")
	else
		warn("Could not find circle light. Skipping circle light functionality.")
	end

	print("Buzzer and lights setup complete")
end

-- Setup goal interactions
local function setupGoalInteractions()
	print("Setting up goal interactions...")

	-- Setup for Main Court Goal
	local function setupGoal(hoop)
		if not hoop or not hoop:FindFirstChild("Glass") or not hoop.Glass:FindFirstChild("Goal") then
			warn("Invalid hoop structure. Skipping goal setup.")
			return
		end

		local brick = hoop.Glass.Goal
		local net = hoop:FindFirstChild("Net")

		if not net then
			warn("Net not found in hoop. Some animations might not work.")
		end

		local moveSpeed = 0.08
		local netSpeed = 0.03
		local debounce1 = 0
		local debounce2 = 0

		-- Handle ball going through hoop
		local function handleGoal(hit)
			local person = hit.Parent
			if not person then return end

			if person:IsA("Hat") and person.Parent == workspace then
				person:Destroy()
			elseif person:FindFirstChild("Humanoid") and person:FindFirstChild("Torso") then
				person.Torso.CFrame = hoop.Here.CFrame
				person.Humanoid.Sit = true
			elseif person:IsA("Tool") and debounce1 == 0 then
				debounce1 = 1

				if hoop:FindFirstChild("Top") and hoop.Top:FindFirstChild("PointLight") then
					hoop.Top.PointLight.Enabled = true

					for i = 1, 10 do
						if hoop.Top then
							hoop.Top.Transparency = math.max(0.1, hoop.Top.Transparency - 0.1)
						end
						task.wait(moveSpeed)
					end

					for i = 1, 10 do
						if hoop.Top then
							hoop.Top.Transparency = math.min(1, hoop.Top.Transparency + 0.1)
						end
						task.wait(moveSpeed)
					end

					if hoop.Top and hoop.Top:FindFirstChild("PointLight") then
						hoop.Top.PointLight.Enabled = false
					end
				end

				task.wait(0.1)
				debounce1 = 0
			end
		end

		-- Handle swish animation
		local function handleSwish(hit)
			local person = hit.Parent
			if not person then return end

			if person:IsA("Tool") and debounce2 == 0 then
				debounce2 = 1

				if net and net:FindFirstChild("Mesh") and hoop:FindFirstChild("swish") then
					if hoop.swish.Value == false then
						local scaleSequence = {2.7, 2.4, 2.1, 1.8, 1.5, 1.9, 2.3, 2.7, 3.2, 2.7}
						for _, scale in ipairs(scaleSequence) do
							net.Mesh.Scale = Vector3.new(2.4, scale, 2.4)
							task.wait(netSpeed)
						end
					elseif hoop.swish.Value == true then
						if person:FindFirstChild("Handle") then
							person.Handle.CFrame = brick.CFrame - Vector3.new(0, 3, 0)
						end

						local scaleSequence = {-3, -2.5, -2.2, -1.9, -1.4, -1, -0.5, 0.4, 0.9, 1.5, 2, 2.4, 2.9, 3.2, 2.7}
						for _, scale in ipairs(scaleSequence) do
							if net and net:FindFirstChild("Mesh") then
								net.Mesh.Scale = Vector3.new(2.4, scale, 2.4)
								task.wait(netSpeed)
							end
						end
					end
				end

				debounce2 = 0
			end
		end

		-- Connect events
		brick.Touched:Connect(handleGoal)
		brick.Touched:Connect(handleSwish)

		-- Setup sound effects
		local function setupSoundTrigger(soundName)
			if brick:FindFirstChild(string.lower(soundName)) then
				local debounce = false

				local function onTouched(hit)
					if not debounce and hit.Parent and hit.Parent.Name == "Basketball" then
						debounce = true
						brick[string.lower(soundName)]:Play()
						task.wait(1)
						debounce = false
					end
				end

				brick.Touched:Connect(onTouched)
				print("Set up " .. soundName .. " sound trigger")
			else
				warn(soundName .. " sound not found in goal")
			end
		end

		-- Setup different sound effects
		setupSoundTrigger("Chaching")
		setupSoundTrigger("Swish")
		setupSoundTrigger("Bounce")

		-- Setup shotclock light
		local shotclockLight = hoop:FindFirstChild("ShotclockLight")
		if shotclockLight then
			local originalColor = shotclockLight.Color

			local function handleShotclockLight(hit)
				local person = hit.Parent
				if person and person:FindFirstChild("Handle") then
					local backboard = hoop:FindFirstChild("Backboard")

					if person:FindFirstChild("dunk") and backboard and 
						backboard:FindFirstChild("here") and
						backboard.here:FindFirstChild("GUI") and
						backboard.here.GUI:FindFirstChild("Label") then
						backboard.here.GUI.Label.Text = "Dunk!"
						task.wait(0.01)
						person.dunk:Destroy()
					end

					shotclockLight.Color = Color3.new(0, 1, 0)
					task.wait(1)
					shotclockLight.Color = originalColor
				end
			end

			brick.Touched:Connect(handleShotclockLight)
			print("Set up shotclock light")
		end

		-- Setup top light
		local topLight = hoop:FindFirstChild("TopLight")
		if topLight then
			local originalColor = topLight.Color

			local function handleTopLight(hit)
				local person = hit.Parent
				if person and person:FindFirstChild("Handle") then
					local backboard = hoop:FindFirstChild("Backboard")

					if person:FindFirstChild("dunk") and backboard and 
						backboard:FindFirstChild("here") and
						backboard.here:FindFirstChild("GUI") and
						backboard.here.GUI:FindFirstChild("Label") then
						backboard.here.GUI.Label.Text = "Dunk!"
						task.wait(0.01)
						person.dunk:Destroy()
					end

					topLight.Color = Color3.new(0, 1, 0)
					task.wait(1)
					topLight.Color = originalColor
				end
			end

			brick.Touched:Connect(handleTopLight)
			print("Set up top light")
		end

		print("Goal setup complete for " .. hoop:GetFullName())
	end

	-- Setup for Glass effects
	local function setupGlassEffects()
		if not runtimeComponents.mainGoal then
			warn("Main goal not found. Skipping glass effects setup.")
			return
		end

		local base = runtimeComponents.mainGoal:FindFirstChild("Glass")

		if base and base:FindFirstChild("Light") and base:FindFirstChild("Decal") then
			spawn(function()
				while true do
					task.wait(0.2)
					local guiFolder = workspace:FindFirstChild("GuiFolder")
					if guiFolder then
						local shotclock = guiFolder:FindFirstChild("Shotclock")
						if shotclock and shotclock.Value == 0 then
							base.Light.Enabled = true
							base.Decal.Transparency = 0
						else
							base.Light.Enabled = false
							base.Decal.Transparency = 1
						end
					end
				end
			end)
			print("Glass effects setup complete")
		else
			warn("Could not find proper glass components. Skipping glass effects.")
		end
	end

	-- Setup for Scoreboard
	local function setupScoreboard()
		if not runtimeComponents.scoreboards then
			warn("Scoreboards not found. Skipping scoreboard setup.")
			return
		end

		if runtimeComponents.scoreboards:FindFirstChild("scoreboard") and
			runtimeComponents.scoreboards.scoreboard:FindFirstChild("HomeBonus") and
			runtimeComponents.scoreboards.scoreboard.HomeBonus:FindFirstChild("Gui") and
			runtimeComponents.scoreboards.scoreboard.HomeBonus.Gui:FindFirstChild("Score") then

			local Panel = runtimeComponents.scoreboards.scoreboard.HomeBonus.Gui.Score

			spawn(function()
				while true do
					task.wait(1)
					if GuiFolder:FindFirstChild("OneBonus") then
						Panel.TextTransparency = GuiFolder.OneBonus.Value and 0 or 0.7
					end
				end
			end)
			print("Scoreboard setup complete")
		else
			warn("Could not find proper scoreboard components. Skipping scoreboard setup.")
		end
	end

	-- Apply setups to main court goal
	if runtimeComponents.mainGoal then
		pcall(function()
			setupGoal(runtimeComponents.mainGoal)
		end)
	else
		warn("Main goal not found. Skipping goal setup.")
	end

	-- Apply setups to roof goal if it exists and has same structure
	if runtimeComponents.roofGoal then
		pcall(function()
			setupGoal(runtimeComponents.roofGoal)
		end)
	end

	-- Setup additional components
	pcall(setupGlassEffects)
	pcall(setupScoreboard)

	print("Goal interactions setup complete")
end

-- Function to initialize all basketball systems when needed
local function initializeBasketballSystems()
	-- First set up the basketball court from storage to workspace
	setupBasketballCourt()

	-- Then run all setup functions with error handling
	pcall(setupTimeManagement)
	pcall(setupBuzzerAndLights)
	pcall(setupGoalInteractions)

	print("Basketball Court Systems initialization finished!")

	return true
end

-- Export function for other scripts to use
return {
	initializeBasketballSystems = initializeBasketballSystems
}