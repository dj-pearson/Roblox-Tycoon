local Folder = workspace.GuiFolder

while wait() do
script.Parent.Value = (Folder.Time.Value%60)
if Folder.Time.Value%60==0 then
end
end

