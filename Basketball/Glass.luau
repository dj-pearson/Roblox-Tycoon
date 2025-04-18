base=script.Parent

while true do
	wait(0.2)
	if workspace:findFirstChild("GuiFolder") then
		if workspace.GuiFolder.Shotclock.Value==0 then
			base.Light.Enabled=true
			base.Decal.Transparency=0
		else
			base.Light.Enabled=false
			base.Decal.Transparency=1
		end
	end
end
