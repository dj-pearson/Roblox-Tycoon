while wait() do
	if workspace.GuiFolder.Time.Value == 0 then
		script.Parent.BrickColor = BrickColor.new("Really red")
		script.Parent.Material = Enum.Material.Neon
	else
		script.Parent.BrickColor = BrickColor.new("Black")
		script.Parent.Material = Enum.Material.SmoothPlastic
	end
end
