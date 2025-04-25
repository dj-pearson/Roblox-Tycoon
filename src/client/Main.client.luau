--lua
-- src/client/Main.client.luau

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local StaffManagementUI = require(script.Parent.UI.StaffManagementUI)

local Main = {}

local function start()
	StaffManagementUI.init()
	StaffManagementUI.openUI()

	local staffCardFrames = 0 -- Counter for staff cards
	local clearCardsFrames = 0 -- Counter to clear staff cards
	local hireOptionsFrames = 0 -- Counter for hire options
	local clearHireOptionsFrames = 0 -- Counter to clear hire options
	local trainingOptionsFrames = 0 -- Counter for training options
	local clearTrainingOptionsFrames = 0 -- Counter to clear training options
	local assignmentOptionsFrames = 0 -- Counter for assignment options
	local clearAssignmentOptionsFrames = 0 -- Counter to clear assignment options
	
	local names = { "John", "Alice", "Bob", "Eve", "Charlie", "David", "Frank", "Grace" }
	local status = { "Working", "Training", "Idle" }
    local icons = {13337321193, 13337324635, 13337323256}


    local function getRandomName()
        return names[math.random(1, #names)]
    end

	local function getRandomStatus()
        return status[math.random(1, #status)]
    end

	local function getRandomAssignment()
		return "Area "..math.random(1, 10)
	end

    local function getRandomIcon()
        return icons[math.random(1, #icons)]
    end
	
	RunService.Heartbeat:Connect(function()
        -- Staff Cards
		staffCardFrames = staffCardFrames + 1
		if staffCardFrames >= 100 then
			StaffManagementUI.addStaffCard(getRandomName(), math.random(1, 10), getRandomStatus())
			staffCardFrames = 0
		end

		clearCardsFrames = clearCardsFrames + 1
		if clearCardsFrames >= 500 then
			StaffManagementUI.clearStaffCards()
			clearCardsFrames = 0
		end

        -- Hire options
        hireOptionsFrames = hireOptionsFrames + 1
		clearHireOptionsFrames = clearHireOptionsFrames + 1
        if hireOptionsFrames >= 100 then
            StaffManagementUI.addHireStaffOption(getRandomName(), math.random(10, 100), getRandomIcon())
            hireOptionsFrames = 0
		end
		
        if clearHireOptionsFrames >= 500 then
            StaffManagementUI.clearHireStaffOptions()
            clearHireOptionsFrames = 0
		end

		-- Training options
		trainingOptionsFrames = trainingOptionsFrames + 1
		clearTrainingOptionsFrames = clearTrainingOptionsFrames + 1
		if trainingOptionsFrames >= 100 then
			StaffManagementUI.addTrainingOption(getRandomName().." Training", math.random(50, 500), getRandomIcon(), math.random(10, 60))
			trainingOptionsFrames = 0
		end
		
		if clearTrainingOptionsFrames >= 500 then
			StaffManagementUI.clearTrainingOptions()
			clearTrainingOptionsFrames = 0
		end

		-- Assignment options
		assignmentOptionsFrames = assignmentOptionsFrames + 1
		clearAssignmentOptionsFrames = clearAssignmentOptionsFrames + 1
		if assignmentOptionsFrames >= 100 then
			StaffManagementUI.addAssignmentOption(getRandomName(), getRandomAssignment())
			assignmentOptionsFrames = 0
		end
		if clearAssignmentOptionsFrames >= 500 then
			StaffManagementUI.clearAssignmentOptions()
			clearAssignmentOptionsFrames = 0
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	if player == Players.LocalPlayer then
		start()
	end
end)
return Main