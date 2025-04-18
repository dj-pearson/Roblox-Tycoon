local Folder = workspace.GuiFolder

while wait() do
	script.Parent.Value = (math.floor(Folder.Time.Value/60))
end

-- (Folder.Second.Value%60)