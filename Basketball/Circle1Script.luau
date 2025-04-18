label=script.Parent
local GuiFolder = game.Workspace:WaitForChild("GuiFolder")
local Color = Color3.fromRGB(255, 255, 0)
local Color2 = Color3.fromRGB(70, 67, 69)


while true do
	wait()
		
	
	if GuiFolder.Time.Value <60 then
		label.Color = Color
		label.Parent.Circle.Color = Color
		elseif GuiFolder.Time.Value >59 then
			label.Color = Color
			label.Parent.Circle.Color = Color
		

	         end
		end



