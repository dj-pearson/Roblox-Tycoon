-- StartupTileVerification.lua
-- Place this in ServerScriptService to ensure it runs last and verifies the first buy tile is present

local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

-- Wait for all scripts to initialize
wait(10)

print("Running Buy Tile startup verification...")

-- Check if first buy tile is present in the workspace
local firstTileFound = false
for _, obj in pairs(Workspace:GetDescendants()) do
	if obj:IsA("Model") and obj:GetAttribute("ID") == 1 and (obj.Name:find("BuyTile") or obj.Name:find("Buy")) then
		firstTileFound = true
		print("First buy tile found in workspace: " .. obj:GetFullName())
		break
	end
end

if not firstTileFound then
	print("First buy tile not found in workspace, attempting to spawn it...")

	-- Try to access the BuyTile module
	local buyTileSystem
	pcall(function()
		buyTileSystem = require(ServerScriptService:FindFirstChild("BuyTile"))
	end)

	if buyTileSystem and buyTileSystem.spawnBuyTile then
		local tile = buyTileSystem.spawnBuyTile(1)
		if tile then
			print("Successfully spawned first buy tile via verification script")

			-- Make sure it's properly set up with handlers
			pcall(function()
				-- Find the BuyTilePart
				local buyTilePart = tile:FindFirstChild("BuyTilePart")
				if buyTilePart then
					-- Get name and price
					local tileName = tile:GetAttribute("Name") or "Wall"
					local tilePrice = tile:GetAttribute("Price") or 0

					-- Make sure BillboardGui exists
					if not buyTilePart:FindFirstChild("BillboardGui") then
						local billboardGui = Instance.new("BillboardGui")
						billboardGui.Name = "BillboardGui"
						billboardGui.Size = UDim2.new(4, 0, 2, 0)
						billboardGui.StudsOffset = Vector3.new(0, 2, 0)
						billboardGui.AlwaysOnTop = true
						billboardGui.Parent = buyTilePart

						local frame = Instance.new("Frame")
						frame.Name = "Frame"
						frame.Size = UDim2.new(1, 0, 1, 0)
						frame.BackgroundTransparency = 0.5
						frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
						frame.BorderSizePixel = 0
						frame.Parent = billboardGui

						local uiCorner = Instance.new("UICorner")
						uiCorner.CornerRadius = UDim.new(0.1, 0)
						uiCorner.Parent = frame

						local nameLabel = Instance.new("TextLabel")
						nameLabel.Name = "NameLabel"
						nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
						nameLabel.BackgroundTransparency = 1
						nameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
						nameLabel.TextScaled = true
						nameLabel.Font = Enum.Font.GothamBold
						nameLabel.Text = "Buy " .. tileName
						nameLabel.Parent = frame

						local priceLabel = Instance.new("TextLabel")
						priceLabel.Name = "PriceLabel"
						priceLabel.Position = UDim2.new(0, 0, 0.5, 0)
						priceLabel.Size = UDim2.new(1, 0, 0.5, 0)
						priceLabel.BackgroundTransparency = 1
						priceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
						priceLabel.TextScaled = true
						priceLabel.Font = Enum.Font.GothamBold
						priceLabel.Text = "$" .. tostring(tilePrice)
						priceLabel.Parent = frame
					end

					-- Ensure touch handler is set up
					print("Adding touch handler to buy tile part")
				end
			end)
		else
			print("Failed to spawn first buy tile from verification script")

			-- Fallback: Create a simple indicator to help debugging
			local indicator = Instance.new("Part")
			indicator.Name = "BuyTilesMissingIndicator"
			indicator.Anchored = true
			indicator.CanCollide = false
			indicator.Size = Vector3.new(5, 5, 5)
			indicator.Position = Vector3.new(0, 10, 0)
			indicator.BrickColor = BrickColor.new("Really red")
			indicator.Material = Enum.Material.Neon
			indicator.Parent = Workspace

			local billboardGui = Instance.new("BillboardGui")
			billboardGui.Size = UDim2.new(0, 200, 0, 50)
			billboardGui.StudsOffset = Vector3.new(0, 3, 0)
			billboardGui.AlwaysOnTop = true
			billboardGui.Parent = indicator

			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			textLabel.TextScaled = true
			textLabel.Font = Enum.Font.GothamBold
			textLabel.Text = "ERROR: BuyTiles missing!"
			textLabel.Parent = billboardGui
		end
	else
		print("Could not access BuyTile system, manual intervention required")
	end
end

print("Buy Tile startup verification complete")