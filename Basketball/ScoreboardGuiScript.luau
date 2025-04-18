
local Folder = game.Workspace:WaitForChild("GuiFolder")
local Panel = script.Parent

while true do
	wait()
	
	if Folder.OneBonus.Value == true then
		Panel.TextTransparency = 0
		
	elseif Folder.OneBonus.Value == false then
		Panel.TextTransparency = 0.7
		
	end
		
end
	
