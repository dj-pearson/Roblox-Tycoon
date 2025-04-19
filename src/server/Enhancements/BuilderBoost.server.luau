local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local DataManager = require(game.ServerScriptService.Data.GymTycoonDataManager)

local DeveloperProductId = 3269235187
local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "BuilderBoostPurchase"
RemoteEvent.Parent = ReplicatedStorage

local isPurchasing = false
local buyTileModule -- Will be initialized in init

local function init()
    buyTileModule = require(ServerStorage:WaitForChild("BuyTile")) -- Assuming you have a BuyTile module
end

local function savePlayerData(player, playerData)
    DataManager.savePlayerData(player, playerData)
end

local function loadPlayerData(player)
    local playerData = DataManager.loadPlayerData(player)
    if not playerData then
        playerData = {
            lastPurchasedTileId = 0,
            purchasedTiles = {}
        }
        savePlayerData(player, playerData)
    end
    return playerData
end

local function getNextTilesToBuy(player, playerData, numTiles)
    local nextTileId = playerData.lastPurchasedTileId + 1
    local tilesToBuy = {}
    local tilesFound = 0

    for i = nextTileId, nextTileId + (numTiles * 10) do -- Increased search range
        local tile = workspace:FindFirstChild("BuyTile" .. i)
        if tile and not playerData.purchasedTiles[i] then
            table.insert(tilesToBuy, tile)
            tilesFound += 1
        end
        if tilesFound >= numTiles then
            break
        end
    end

    return tilesToBuy
end


local function purchaseBuilderBoost(player, numTiles)
    if isPurchasing then
        return -- Already processing a purchase
    end

    isPurchasing = true
    local playerData = loadPlayerData(player)

    local tilesToBuy = getNextTilesToBuy(player, playerData, numTiles)

    if #tilesToBuy < numTiles then
        warn("Not enough tiles available to purchase.")
        isPurchasing = false
        return
    end

    local success = true
    local lastPurchasedTileId = playerData.lastPurchasedTileId
    local purchasedTiles = playerData.purchasedTiles
    for _, tile in ipairs(tilesToBuy) do
        local tileNumber = tonumber(string.match(tile.Name, "%d+"))
        if tileNumber then
            local buySuccess, errorMessage = pcall(function()
                buyTileModule.buyTile(player, tile) -- Assuming this function handles the actual purchase
            end)
            if buySuccess then
                purchasedTiles[tileNumber] = true
                lastPurchasedTileId = tileNumber
            else
                warn("Error buying tile:", errorMessage)
                success = false
                break -- Stop purchasing if one fails
            end
        end
    end

    if success then
        playerData.lastPurchasedTileId = lastPurchasedTileId
        playerData.purchasedTiles = purchasedTiles
        savePlayerData(player, playerData)
        print("Builder Boost purchase successful for", player.Name)
    else
        print("Builder Boost purchase partially failed for", player.Name)
    end

    isPurchasing = false
end

local function processReceipt(receiptInfo)
    if receiptInfo.ProductId == DeveloperProductId then
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if player then
            local success, message = pcall(function()
                purchaseBuilderBoost(player, 10)
            end)
            if success then
                return Enum.ProductPurchaseDecision.PurchaseGranted
            else
                warn("Error processing receipt:", message)
                return Enum.ProductPurchaseDecision.NotProcessedYet
            end
        end
    end
    return Enum.ProductPurchaseDecision.NotProcessedYet
end


local function promptProductPurchase(player)
    local success, errorMessage = pcall(function()
        MarketplaceService:PromptProductPurchase(player, DeveloperProductId)
    end)
    if not success then
        warn("Error prompting product purchase:", errorMessage)
    end
end

MarketplaceService.ProcessReceipt = processReceipt

RemoteEvent.OnServerEvent:Connect(promptProductPurchase)

init()