-- BuilderBoostPurchaseGui.client.luau
-- Client script for handling premium Builder Boost product purchases
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
local BuilderBoostEvent = ReplicatedStorage:FindFirstChild("BuilderBoostEvent")

-- Create or get the ScreenGui if it doesn't exist
if not ScreenGui then
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BuilderBoostPurchaseGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui
    print("BuilderBoostPurchaseGui: Created missing ScreenGui")
end

-- Get or create the purchase button
local PurchaseButton = ScreenGui:FindFirstChild("PurchaseButton")
if not PurchaseButton then
    PurchaseButton = Instance.new("TextButton")
    PurchaseButton.Name = "PurchaseButton"
    PurchaseButton.Size = UDim2.new(0, 200, 0, 50)
    PurchaseButton.Position = UDim2.new(0.5, -100, 0.5, 0)
    PurchaseButton.Text = "Purchase Builder Boost"
    PurchaseButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    PurchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    PurchaseButton.BorderSizePixel = 0
    PurchaseButton.Font = Enum.Font.GothamMedium
    PurchaseButton.TextSize = 18
    PurchaseButton.Parent = ScreenGui
    print("BuilderBoostPurchaseGui: Created missing PurchaseButton")
end

-- Create builder boost event if it doesn't exist (for testing purposes in Studio)
if not BuilderBoostEvent then
    BuilderBoostEvent = Instance.new("RemoteEvent")
    BuilderBoostEvent.Name = "BuilderBoostEvent"
    BuilderBoostEvent.Parent = ReplicatedStorage
    print("BuilderBoostPurchaseGui: Created missing BuilderBoostEvent for testing")
end

local DEVELOPER_PRODUCT_ID = 3269235187

PurchaseButton.MouseButton1Click:Connect(function()
    local success, errorMessage = pcall(function()
        MarketplaceService:PromptProductPurchase(LocalPlayer, DEVELOPER_PRODUCT_ID)
    end)
    
    if not success then
        warn("BuilderBoostPurchaseGui: Failed to prompt purchase - ", errorMessage)
    end
end)

-- Listen for purchase processing
MarketplaceService.ProcessReceipt = function(receiptInfo)
    if receiptInfo.ProductId == DEVELOPER_PRODUCT_ID then
        -- Fire remote event to server to process the purchase
        if BuilderBoostEvent then
            BuilderBoostEvent:FireServer(receiptInfo)
        end
        
        -- Display success message
        local message = Instance.new("TextLabel")
        message.Size = UDim2.new(1, 0, 0, 30)
        message.Position = UDim2.new(0, 0, 0, -40)
        message.Text = "Builder Boost Activated!"
        message.TextColor3 = Color3.fromRGB(0, 255, 0)
        message.BackgroundTransparency = 0.7
        message.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        message.Font = Enum.Font.GothamMedium
        message.TextSize = 16
        message.Parent = PurchaseButton
        
        -- Remove message after 3 seconds
        task.delay(3, function()
            message:Destroy()
        end)
        
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

print("BuilderBoostPurchaseGui initialized successfully")
