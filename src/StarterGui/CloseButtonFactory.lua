--[[
    CloseButtonFactory.lua
    Factory for creating close buttons.

    Updated: Today
]]

local function createCloseButton(args)
	local size = args.size
	local position = args.position
	local target = args.target

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Text = "X"
	closeButton.Size = size
	closeButton.Position = position
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 18
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	closeButton.BackgroundTransparency = 0
	closeButton.Parent = target

	closeButton.MouseButton1Click:Connect(function()
		target:Destroy()
	end)

	return closeButton
end

return createCloseButton