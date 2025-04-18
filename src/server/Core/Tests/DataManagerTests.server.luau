-- DataManagerTests.luau
-- Unit tests for the DataManager system
-- Place in ServerScriptService/Core/Tests

local TestingFramework = require(game.ServerScriptService.Core.TestingFramework)
local Players = game:GetService("Players")

-- Create a mock PlayerDataManager for testing
local function createMockDataManager()
    local dataManager = {
        data = {},
        defaults = {
            coins = 0,
            exp = 0,
            level = 1,
            upgrades = {}
        },
        playerCache = {}
    }
    
    -- Mock the set data function
    function dataManager:SetData(player, key, value)
        if not self.data[player.UserId] then
            self.data[player.UserId] = {}
        end
        self.data[player.UserId][key] = value
        return true
    end
    
    -- Mock the get data function
    function dataManager:GetData(player, key, defaultValue)
        if not self.data[player.UserId] then
            return defaultValue or self.defaults[key]
        end
        
        if self.data[player.UserId][key] ~= nil then
            return self.data[player.UserId][key]
        end
        
        return defaultValue or self.defaults[key]
    end
    
    -- Mock the increment data function
    function dataManager:IncrementData(player, key, amount)
        amount = amount or 1
        local currentValue = self:GetData(player, key, 0)
        
        if type(currentValue) ~= "number" then
            return false
        end
        
        return self:SetData(player, key, currentValue + amount)
    end
    
    -- Mock the initialize player function
    function dataManager:InitializePlayer(player)
        -- Create default data structure for this player
        self.data[player.UserId] = table.clone(self.defaults)
        self.playerCache[player.UserId] = true
        return true
    end
    
    -- Mock the save player data function
    function dataManager:SavePlayerData(player)
        -- In the mock, we'll just return true since there's no actual saving
        if not self.data[player.UserId] then
            return false
        end
        
        return true
    end
    
    return dataManager
end

-- Create a mock player for testing
local function createMockPlayer(userId, name)
    local player = {
        UserId = userId or 1234567890,
        Name = name or "TestPlayer",
        IsA = function(self, className)
            return className == "Player"
        end
    }
    
    return player
end

-- Create the test suite
local DataManagerTests = TestingFramework.createSuite("DataManager")

-- Set up before each test
DataManagerTests:setBeforeEach(function()
    -- Nothing to set up globally
end)

-- Clean up after each test
DataManagerTests:setAfterEach(function()
    -- Nothing to clean up globally
end)

-- Test initialization
DataManagerTests:addTest("Should initialize player data with defaults", function()
    local dataManager = createMockDataManager()
    local player = createMockPlayer()
    
    local success = dataManager:InitializePlayer(player)
    
    DataManagerTests:expect(success).toBeTrue()
    DataManagerTests:expect(dataManager.data[player.UserId]).notToBeNil()
    DataManagerTests:expect(dataManager.data[player.UserId].coins).toBe(0)
    DataManagerTests:expect(dataManager.data[player.UserId].exp).toBe(0)
    DataManagerTests:expect(dataManager.data[player.UserId].level).toBe(1)
end)

-- Test setting and getting data
DataManagerTests:addTest("Should set and get player data correctly", function()
    local dataManager = createMockDataManager()
    local player = createMockPlayer()
    
    -- Initialize player
    dataManager:InitializePlayer(player)
    
    -- Set some data
    dataManager:SetData(player, "coins", 100)
    dataManager:SetData(player, "customValue", "test")
    
    -- Get the data back
    local coins = dataManager:GetData(player, "coins")
    local customValue = dataManager:GetData(player, "customValue")
    
    DataManagerTests:expect(coins).toBe(100)
    DataManagerTests:expect(customValue).toBe("test")
end)

-- Test default values
DataManagerTests:addTest("Should return default values for missing keys", function()
    local dataManager = createMockDataManager()
    local player = createMockPlayer()
    
    -- Initialize player
    dataManager:InitializePlayer(player)
    
    -- Get data for a key that doesn't exist
    local nonExistentValue = dataManager:GetData(player, "nonExistentKey", "defaultValue")
    
    DataManagerTests:expect(nonExistentValue).toBe("defaultValue")
end)

-- Test incrementing data
DataManagerTests:addTest("Should properly increment numeric data", function()
    local dataManager = createMockDataManager()
    local player = createMockPlayer()
    
    -- Initialize player
    dataManager:InitializePlayer(player)
    
    -- Set initial value
    dataManager:SetData(player, "coins", 50)
    
    -- Increment by default (1)
    dataManager:IncrementData(player, "coins")
    DataManagerTests:expect(dataManager:GetData(player, "coins")).toBe(51)
    
    -- Increment by specific amount
    dataManager:IncrementData(player, "coins", 10)
    DataManagerTests:expect(dataManager:GetData(player, "coins")).toBe(61)
    
    -- Increment by negative amount (decrement)
    dataManager:IncrementData(player, "coins", -20)
    DataManagerTests:expect(dataManager:GetData(player, "coins")).toBe(41)
end)

-- Test multiple players
DataManagerTests:addTest("Should handle multiple players independently", function()
    local dataManager = createMockDataManager()
    local player1 = createMockPlayer(1, "Player1")
    local player2 = createMockPlayer(2, "Player2")
    
    -- Initialize both players
    dataManager:InitializePlayer(player1)
    dataManager:InitializePlayer(player2)
    
    -- Set different values for each player
    dataManager:SetData(player1, "coins", 100)
    dataManager:SetData(player2, "coins", 200)
    
    -- Check that each player's data is separate
    DataManagerTests:expect(dataManager:GetData(player1, "coins")).toBe(100)
    DataManagerTests:expect(dataManager:GetData(player2, "coins")).toBe(200)
    
    -- Modify one player's data
    dataManager:IncrementData(player1, "coins", 50)
    
    -- Ensure it only affected that player
    DataManagerTests:expect(dataManager:GetData(player1, "coins")).toBe(150)
    DataManagerTests:expect(dataManager:GetData(player2, "coins")).toBe(200)
end)

-- Test save functionality
DataManagerTests:addTest("Should successfully save player data", function()
    local dataManager = createMockDataManager()
    local player = createMockPlayer()
    
    -- Initialize player
    dataManager:InitializePlayer(player)
    
    -- Set some data
    dataManager:SetData(player, "coins", 500)
    
    -- Save the data
    local saveSuccess = dataManager:SavePlayerData(player)
    
    DataManagerTests:expect(saveSuccess).toBeTrue()
end)

-- Test handling non-existent player
DataManagerTests:addTest("Should handle non-existent player gracefully", function()
    local dataManager = createMockDataManager()
    local player = createMockPlayer()
    
    -- Try to get data without initializing
    local defaultCoins = dataManager:GetData(player, "coins")
    
    -- Should return the default value
    DataManagerTests:expect(defaultCoins).toBe(0)
    
    -- Try to save data for non-initialized player
    local saveSuccess = dataManager:SavePlayerData(player)
    
    -- Should fail gracefully
    DataManagerTests:expect(saveSuccess).toBeFalse()
end)

return DataManagerTests