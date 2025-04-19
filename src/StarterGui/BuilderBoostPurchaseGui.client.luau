local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:WaitForChild("BuilderBoostPurchaseGui")
local PurchaseButton = ScreenGui:WaitForChild("PurchaseButton") 
local BuilderBoostEvent = ReplicatedStorage:WaitForChild("BuilderBoostEvent")
local DEVELOPER_PRODUCT_ID = 3269235187

PurchaseButton.MouseButton1Click:Connect(function()
	local success, errorMessage = pcall(function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, DEVELOPER_PRODUCT_ID)
	end)
	if not success then
		warn("Error prompting purchase:", errorMessage)
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(player, productId, wasPurchased)
	if player == LocalPlayer and productId == DEVELOPER_PRODUCT_ID and wasPurchased then
		BuilderBoostEvent:FireServer()
	end
end)