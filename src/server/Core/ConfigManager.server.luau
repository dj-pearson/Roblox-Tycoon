-- src/server/Core/ConfigManager.server.luau

local CoreRegistry = require(script.Parent.CoreRegistry)

local ConfigManager = {
    _config = {}
}

function ConfigManager:initialize()
    print("[ConfigManager] Initialized")
end

function ConfigManager:getConfig(key)
    return self._config[key]
end

function ConfigManager:setConfig(key, value)
     self._config[key] = value
end

local PublicAPI = {
    initialize = function()
        return ConfigManager:initialize()
    end,
     getConfig = function(key)
        return ConfigManager:getConfig(key)
    end,
    setConfig = function(key, value)
        ConfigManager:setConfig(key, value)
    end
}

return CoreRegistry.registerSystem("ConfigManager", PublicAPI, {"EventBridge"})