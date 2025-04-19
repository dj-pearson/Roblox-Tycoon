--[[
    Server Script: DoubleMemberRevenueHandler
    Handles the doubling of member revenue for 10 minutes upon successful purchase.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local doubleMemberProductId = 3269228815
local doubleMemberDuration = 600 -- 10 minutes in seconds

-- Remote Event to trigger the effect
local doubleRevenueEvent = Instance.new("RemoteEvent")
doubleRevenueEvent.Name = "DoubleRevenueEvent"
doubleRevenueEvent.Parent = ReplicatedStorage

-- Find the DoubleMember model in ServerStorage > GymParts
local gymPartsFolder = ServerStorage:WaitForChild("GymParts")
local doubleMemberModel = gymPartsFolder:FindFirstChild("DoubleMember")

if not doubleMemberModel then
    warn("DoubleMember model not found in ServerStorage > GymParts!")
end

-- Function to calculate the base revenue
local function calculateBaseRevenue()
    local activeMemberCount = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            -- Check if player has an active member character in the gym, you might need to adjust this logic
           -- Example: If they are touching a specific part or region.
            activeMemberCount = activeMemberCount + 1
        end
    end
    return activeMemberCount * 10 -- Example base revenue per active member
end

-- Function to double the revenue
local function doubleRevenue()
    if doubleMemberModel then
        doubleMemberModel:SetAttribute("Active", true)
        print("Double Member Revenue activated!")
    end
    
    local doubledRevenue = calculateBaseRevenue() * 2
    print("Doubled revenue:", doubledRevenue)

    return doubledRevenue
end

-- Function to reset the revenue
local function resetRevenue()
    if doubleMemberModel then
        doubleMemberModel:SetAttribute("Active", false)
        print("Double Member Revenue deactivated.")
    end
end

-- Handle the purchase
MarketplaceService.ProcessReceipt = function(receiptInfo)
    if receiptInfo.ProductId == doubleMemberProductId then
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if player then
            print("Player purchased double revenue:", player.Name)
            
            -- Trigger double revenue effect
            doubleRevenueEvent:FireClient(player)
            
            -- Apply double revenue effect
            doubleRevenue()

            -- Schedule revenue reset after the duration
            task.delay(doubleMemberDuration, resetRevenue)

            return Enum.ProductPurchaseDecision.PurchaseGranted
        else
            warn("Player not found for receipt:", receiptInfo.PlayerId)
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
    end
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Display purchase button to player when they join
Players.PlayerAdded:Connect(function(player)
    if RunService:IsServer() then
        local playerGui = player:WaitForChild("PlayerGui")
        local buttonFrame = Instance.new("ScreenGui")
        buttonFrame.Name = "DoubleRevenueGui"
        buttonFrame.Parent = playerGui
        local purchaseButton = Instance.new("TextButton")
        purchaseButton.Name = "PurchaseDoubleRevenue"
        purchaseButton.Text = "Double Revenue"
        purchaseButton.Size = UDim2.new(0.2,0,0.1,0)
        purchaseButton.Position = UDim2.new(0.4,0,0.4,0)
        purchaseButton.BackgroundColor3 = Color3.fromRGB(0,255,0)
        purchaseButton.TextColor3 = Color3.fromRGB(255,255,255)
        purchaseButton.Parent = buttonFrame

        purchaseButton.MouseButton1Click:Connect(function()
            MarketplaceService:PromptProductPurchase(player, doubleMemberProductId)
        end)
    end
end)

--[[
    Example: Trigger the effect remotely
]]
doubleRevenueEvent.OnServerEvent:Connect(function(player)
   print("Double Revenue effect triggered for player:" ,player.Name)
end)