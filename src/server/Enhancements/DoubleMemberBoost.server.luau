--[[
    Server Script: DoubleMemberRevenueHandler
    Handles the doubling of member revenue for 10 minutes upon successful purchase.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local doubleMemberProductId = 3269228815
local doubleMemberDuration = 600 -- 10 minutes in seconds

-- Remote Events for system communication
local doubleRevenueEvent = Instance.new("RemoteEvent")
doubleRevenueEvent.Name = "DoubleRevenueEvent"
doubleRevenueEvent.Parent = ReplicatedStorage

-- Create a remote event to trigger UI from touching the model
local showDoubleMemberUIEvent = Instance.new("RemoteEvent")
showDoubleMemberUIEvent.Name = "ShowDoubleMemberUIEvent"
showDoubleMemberUIEvent.Parent = ReplicatedStorage

-- Find the DoubleMember model in ServerStorage > GymParts
local gymPartsFolder = ServerStorage:WaitForChild("GymParts")
local doubleMemberModel = gymPartsFolder:FindFirstChild("DoubleMember")

-- Also check for DoubleMember model in the workspace
if not doubleMemberModel then
    doubleMemberModel = Workspace:FindFirstChild("DoubleMember")
end

if not doubleMemberModel then
    warn("DoubleMember model not found in ServerStorage > GymParts or Workspace!")
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

-- Setup the DoubleMember model's Touched event if it exists
if doubleMemberModel then
    -- Find the primary part or use the first part
    local primaryPart = doubleMemberModel.PrimaryPart
    
    if not primaryPart and doubleMemberModel:IsA("Model") then
        -- Try to find any part in the model
        for _, part in pairs(doubleMemberModel:GetDescendants()) do
            if part:IsA("BasePart") then
                primaryPart = part
                break
            end
        end
    end
    
    if primaryPart then
        -- Set up the Touched event
        primaryPart.Touched:Connect(function(hit)
            local character = hit.Parent
            local player = Players:GetPlayerFromCharacter(character)
            
            if player then
                -- Fire client event to show the UI
                showDoubleMemberUIEvent:FireClient(player)
                print("Fired showDoubleMemberUIEvent for player:", player.Name)
            end
        end)
        
        print("DoubleMember touch event set up successfully")
    else
        warn("No primary part found in DoubleMember model")
    end
else
    warn("DoubleMember model not found, touch event not set up")
end

-- Add a chat command for testing (can be removed in production)
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message:lower() == "/doublerevenue" then
            showDoubleMemberUIEvent:FireClient(player)
            print("Fired showDoubleMemberUIEvent from chat command for player:", player.Name)
        end
    end)
end)

--[[
    Example: Trigger the effect remotely
]]
doubleRevenueEvent.OnServerEvent:Connect(function(player)
   print("Double Revenue effect triggered for player:" ,player.Name)
end)