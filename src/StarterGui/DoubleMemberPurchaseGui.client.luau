local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local doubleMemberPurchaseGui = script.Parent

local purchaseButton = doubleMemberPurchaseGui.PurchaseButton -- Assuming the button is named "PurchaseButton"

local doubleMemberBoostEvent = ReplicatedStorage:WaitForChild("DoubleMemberBoostEvent") -- Assuming the RemoteEvent is named "DoubleMemberBoostEvent"

local developerProductId = 3269228815

local function onPurchaseButtonClicked()
	if MarketplaceService:UserOwnsGamePassAsync(player.UserId, developerProductId) then
		doubleMemberBoostEvent:FireServer()
		print("Already owns Double Member Boost")
	elseif UserInputService.TouchEnabled then
		MarketplaceService:PromptProductPurchase(player, developerProductId)
		print("Prompting purchase from touch")
	else
		MarketplaceService:PromptProductPurchase(player, developerProductId)
		print("Prompting purchase")
	end
end

purchaseButton.MouseButton1Click:Connect(onPurchaseButtonClicked)
purchaseButton.TouchTap:Connect(onPurchaseButtonClicked)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	if receiptInfo.ProductId == developerProductId and receiptInfo.PlayerId == player.UserId then
		doubleMemberBoostEvent:FireServer()
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end