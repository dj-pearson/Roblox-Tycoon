local hoop = script.Parent.Parent
local brick = script.Parent
local originalColor = hoop.ShotclockLight.Color 

function Goal(hit)
	local person = hit.Parent
	if person and person:FindFirstChild("Handle") then
		script.Disabled = true
		if person:FindFirstChild("dunk") then
			hoop.Backboard.here.GUI.Label.Text = "Dunk!"
			wait(0.01)
			person.dunk:Destroy()
		end
		hoop.ShotclockLight.Color = Color3.new(0, 1, 0) 
		wait(1)
		hoop.ShotclockLight.Color = Color3.fromRGB(202, 203, 209)
		wait(1)
		script.Disabled = false
	end
end

brick.Touched:Connect(Goal)
