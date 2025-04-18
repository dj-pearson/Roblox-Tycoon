brick=script.Parent

function rim(hit)
	script.Disabled=true
	brick.bounce:Play()
	wait(1.2)
	brick.bounce:Stop()
	script.Disabled=false
end

brick.Touched:connect(rim)
