-- src/server/Core/ConfigManager.server.luau

local CoreRegistry = require(script.Parent.CoreRegistry)

local CONFIG = {
    difficulty = "Normal", -- Can be "Easy", "Normal", "Hard", etc.
    DIFFICULTY_SETTINGS = {
        ["Chill"] = {
            startingMoney = 50000,
            memberSatisfactionDecay = 0.01, -- Very slow decay
            failureConditions = {}
        },

        ["Easy"] = {
            startingMoney = 20000,
            memberSatisfactionDecay = 0.05, -- Slow decay
            failureConditions = {}
        },
        ["Normal"] = {
            startingMoney = 10000,
            memberSatisfactionDecay = 0.1, -- Normal decay
            failureConditions = { "NegativeBalance", "LowSatisfaction" }
        },
        ["Hard"] = {
            startingMoney = 5000,
            memberSatisfactionDecay = 0.2, -- Fast decay
            failureConditions = { "NegativeBalance", "VeryLowSatisfaction", "LowMemberCount" }
        }
    }
}

local ConfigManager = {
    _config = CONFIG
}

function ConfigManager:initialize()
    print("[ConfigManager] Initialized")
end

function ConfigManager:getConfig(key, difficulty)
    return self._config[key] or self._config.DIFFICULTY_SETTINGS[difficulty or self._config.difficulty][key]
end

function ConfigManager:setConfig(key, value)
     self._config[key] = value
end

function ConfigManager:setDifficulty(difficulty)
    self._config.difficulty = difficulty
end

local PublicAPI = {
    initialize = function()
        return ConfigManager:initialize()
    end,   
    getConfig = function(key, difficulty)
        return ConfigManager:getConfig(key, difficulty)
    end,
    setConfig = function(key, value)
        ConfigManager:setConfig(key, value)
    end,
    setDifficulty = function(difficulty)
        ConfigManager:setDifficulty(difficulty)
    end
}

return CoreRegistry.registerSystem("ConfigManager", PublicAPI, {"EventBridge"})