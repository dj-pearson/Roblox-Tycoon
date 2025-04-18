local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Check if "AccruedDues" exists, if not, create it
if not ReplicatedStorage:FindFirstChild("AccruedDues") then
	local accruedDues = Instance.new("Folder")
	accruedDues.Name = "AccruedDues"
	accruedDues.Parent = ReplicatedStorage
	print("Created 'AccruedDues' in ReplicatedStorage.")
end
