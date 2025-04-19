-- src/server/Core/MemoryStoreManager.server.luau

local CoreRegistry = require(script.Parent.CoreRegistry)

local MemoryStoreManager = {
    _data = {}
}

function MemoryStoreManager:initialize()
    print("[MemoryStoreManager] Initialized")
end

function MemoryStoreManager:setData(key, value)
    self._data[key] = value
end

function MemoryStoreManager:getData(key)
    return self._data[key]
end

local PublicAPI = {
    initialize = function()
        return MemoryStoreManager:initialize()
    end,
    setData = function(key, value)
        MemoryStoreManager:setData(key, value)
    end,
    getData = function(key)
        return MemoryStoreManager:getData(key)
    end
}

return CoreRegistry.registerSystem("MemoryStoreManager", PublicAPI, {"CoreRegistry"})