local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import SafeWait utility
local SafeWait
pcall(function()
    SafeWait = require(ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared"):FindFirstChild("SafeWait"))
end)

-- If SafeWait isn't available, create a simple version
if not SafeWait then
    SafeWait = {
        waitForChild = function(parent, name, timeout)
            return parent:WaitForChild(name, timeout or 5)
        end
    }
end

local LocalPlayer = Players.LocalPlayer
-- Safely wait for GUI elements with timeouts
local PlayerGui = SafeWait.waitForChild(LocalPlayer, "PlayerGui", 10)
local ScreenGui = PlayerGui and SafeWait.waitForChild(PlayerGui, "BuilderBoostPurchaseGui", 5)
local PurchaseButton = ScreenGui and SafeWait.waitForChild(ScreenGui, "PurchaseButton", 5)
local BuilderBoostEvent = SafeWait.waitForChild(ReplicatedStorage, "BuilderBoostEvent", 5)

-- Check if required elements were found
if not PurchaseButton then
    warn("BuilderBoostPurchaseGui: Failed to find PurchaseButton")
    return -- Exit script if button is missing to prevent errors
end

if not BuilderBoostEvent then
    warn("BuilderBoostPurchaseGui: Failed to find BuilderBoostEvent")
    -- Continue execution since we may still want the purchase functionality to work
end
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