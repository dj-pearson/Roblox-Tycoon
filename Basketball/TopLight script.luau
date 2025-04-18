local hoop = script.Parent.Parent
local brick = script.Parent
local originalColor = hoop.TopLight.Color 

function Goal(hit)
	local person = hit.Parent
	if person and person:FindFirstChild("Handle") then
		script.Disabled = true
		if person:FindFirstChild("dunk") then
			hoop.Backboard.here.GUI.Label.Text = "Dunk!"
			wait(0.01)
			person.dunk:Destroy()
		end
		hoop.TopLight.Color = Color3.new(0, 1, 0) 
		wait(1)
		hoop.TopLight.Color = Color3.fromRGB(27, 42, 53)
		wait(1)
		script.Disabled = false
	end
end

brick.Touched:Connect(Goal)
