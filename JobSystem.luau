-- JobSystem.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")


-- List of available jobs
local jobs = {
	{name = "Trainer", benefits = "Increased NPC satisfaction"},
	{name = "Receptionist", benefits = "Faster membership processing"}
}

-- Function to assign an NPC a job
local function assignJob(npc, jobName)
	for _, job in pairs(jobs) do
		if job.name == jobName then
			npc:SetAttribute("Job", jobName)
			print(npc.Name .. " assigned as " .. jobName)
			return
		end
	end
end

-- Assign jobs to NPCs
for _, npc in pairs(Workspace:GetDescendants()) do
	if npc.Name == "NPC" then
		assignJob(npc, "Trainer")
	end
end
