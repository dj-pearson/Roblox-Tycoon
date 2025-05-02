--[[
    TileBuyProgressRestorerTest.server.luau
    
    This script tests the functionality of the TileBuyProgressRestorer module
    to ensure it correctly maintains buy tile progression between player sessions.
    
    Created: May 2, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Utility functions for testing
local COLORS = {
    INFO = Color3.fromRGB(114, 193, 255),
    SUCCESS = Color3.fromRGB(85, 255, 127),
    ERROR = Color3.fromRGB(255, 97, 97),
    WARNING = Color3.fromRGB(255, 200, 87)
}

local function colorPrint(color, ...)
    local args = {...}
    local message = "[TileBuyProgressRestorerTest] "
    for i, arg in ipairs(args) do
        message = message .. tostring(arg) .. (i < #args and " " or "")
    end
    print(message, color)
end

-- Try to require the module under test
local TileBuyProgressRestorer
local success = pcall(function()
    TileBuyProgressRestorer = require(ServerScriptService.Core.TileBuyProgressRestorer)
end)

if not success or not TileBuyProgressRestorer then
    colorPrint(COLORS.ERROR, "Failed to load TileBuyProgressRestorer module")
    return
end

-- Find CoreRegistry if available
local CoreRegistry
pcall(function()
    local paths = {
        ServerScriptService.Core.CoreRegistry,
        ServerScriptService.Server.CoreRegistry,
        ServerScriptService.src and ServerScriptService.src.server and ServerScriptService.src.server.Core and ServerScriptService.src.server.Core.CoreRegistry
    }
    
    for _, path in ipairs(paths) do
        if path then
            CoreRegistry = require(path)
            if CoreRegistry then
                break
            end
        end
    end
end)

-- Find DataManager if available
local DataManager
if CoreRegistry then
    DataManager = CoreRegistry:GetSystem("DataManager")
else
    pcall(function()
        local paths = {
            ServerScriptService.Core.DataManager,
            ServerScriptService.Server.DataManager,
            ServerScriptService.Data.GymTycoonDataManager
        }
        
        for _, path in ipairs(paths) do
            if path then
                DataManager = require(path)
                if DataManager then
                    break
                end
            end
        end
    end)
end

-- Create a test command
local CommandService = CoreRegistry and CoreRegistry:GetSystem("CommandService")
if CommandService then
    -- Register test command
    CommandService:RegisterCommand("testBuyTileProgression", {
        description = "Test the TileBuyProgressRestorer module with the given tile ID",
        parameters = {
            { name = "tileId", type = "number", optional = true, default = 30 }
        },
        handler = function(player, tileId)
            tileId = tileId or 30
            
            colorPrint(COLORS.INFO, "Running buy tile progression test with tile ID:", tileId)
            
            -- Test getting highest tile ID
            local highestTileId = TileBuyProgressRestorer.getHighestTileId(player)
            colorPrint(COLORS.INFO, "Current highest tile ID:", highestTileId)
            
            -- Simulate the player having purchased the specified tile
            if DataManager and DataManager.getPlayerData then
                local playerData = DataManager.getPlayerData(player)
                
                if not playerData.tiles then
                    playerData.tiles = {}
                end
                
                -- Set the specified tile as purchased
                playerData.tiles[tostring(tileId)] = {
                    purchased = true,
                    purchaseDate = os.time(),
                    gymPartId = tostring(tileId)
                }
                
                -- Save the updated data
                DataManager.updatePlayerData(player, playerData)
                colorPrint(COLORS.INFO, "Set tile", tileId, "as purchased for", player.Name)
                
                -- Check highest tile ID again
                local newHighestTileId = TileBuyProgressRestorer.getHighestTileId(player)
                colorPrint(COLORS.INFO, "New highest tile ID:", newHighestTileId)
                
                if newHighestTileId >= tileId then
                    colorPrint(COLORS.SUCCESS, "Successfully updated highest tile ID")
                else
                    colorPrint(COLORS.ERROR, "Failed to update highest tile ID")
                end
                
                -- Test spawning next buy tile
                local success = TileBuyProgressRestorer.spawnNextBuyTile(player)
                
                if success then
                    colorPrint(COLORS.SUCCESS, "Successfully spawned next buy tile (", tileId + 1, ")")
                    
                    return "Test completed successfully. Next tile (" .. (tileId + 1) .. ") should now be visible."
                else
                    colorPrint(COLORS.ERROR, "Failed to spawn next buy tile")
                    
                    return "Test failed. Could not spawn next buy tile."
                end
            else
                colorPrint(COLORS.ERROR, "DataManager not available, cannot complete test")
                
                return "Test failed. DataManager not available."
            end
        end
    })
    
    colorPrint(COLORS.SUCCESS, "Registered test command. Use /testBuyTileProgression [tileId] to test.")
else
    -- Alternative: Create testing RemoteFunction
    local testFunction = Instance.new("RemoteFunction")
    testFunction.Name = "TestBuyTileProgression"
    testFunction.Parent = ReplicatedStorage
    
    testFunction.OnServerInvoke = function(player, tileId)
        tileId = tileId or 30
        
        colorPrint(COLORS.INFO, "Running buy tile progression test with tile ID:", tileId)
            
        -- Test getting highest tile ID
        local highestTileId = TileBuyProgressRestorer.getHighestTileId(player)
        colorPrint(COLORS.INFO, "Current highest tile ID:", highestTileId)
        
        -- Simulate the player having purchased the specified tile
        if DataManager and DataManager.getPlayerData then
            local playerData = DataManager.getPlayerData(player)
            
            if not playerData.tiles then
                playerData.tiles = {}
            end
            
            -- Set the specified tile as purchased
            playerData.tiles[tostring(tileId)] = {
                purchased = true,
                purchaseDate = os.time(),
                gymPartId = tostring(tileId)
            }
            
            -- Save the updated data
            DataManager.updatePlayerData(player, playerData)
            colorPrint(COLORS.INFO, "Set tile", tileId, "as purchased for", player.Name)
            
            -- Check highest tile ID again
            local newHighestTileId = TileBuyProgressRestorer.getHighestTileId(player)
            colorPrint(COLORS.INFO, "New highest tile ID:", newHighestTileId)
            
            if newHighestTileId >= tileId then
                colorPrint(COLORS.SUCCESS, "Successfully updated highest tile ID")
            else
                colorPrint(COLORS.ERROR, "Failed to update highest tile ID")
            end
            
            -- Test spawning next buy tile
            local success = TileBuyProgressRestorer.spawnNextBuyTile(player)
            
            if success then
                colorPrint(COLORS.SUCCESS, "Successfully spawned next buy tile (", tileId + 1, ")")
                
                return {
                    success = true,
                    message = "Test completed successfully. Next tile (" .. (tileId + 1) .. ") should now be visible."
                }
            else
                colorPrint(COLORS.ERROR, "Failed to spawn next buy tile")
                
                return {
                    success = false,
                    message = "Test failed. Could not spawn next buy tile."
                }
            end
        else
            colorPrint(COLORS.ERROR, "DataManager not available, cannot complete test")
            
            return {
                success = false,
                message = "Test failed. DataManager not available."
            }
        end
    end
    
    colorPrint(COLORS.SUCCESS, "Created test RemoteFunction. Call TestBuyTileProgression from client.")
end

colorPrint(COLORS.SUCCESS, "TileBuyProgressRestorer test script initialized!")
