--[[
    DataAccessLayer.luau
    
    This module provides robust data storage and retrieval with error handling and retries.
    It's designed to be a reliable interface to Roblox's DataStoreService.
    
    Created as part of the data persistence fix to solve "Data Persistence Failures"
]]

local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local DEFAULT_RETRY_COUNT = 3
local DEFAULT_RETRY_DELAY = 2
local DEFAULT_TIMEOUT = 10
local DEFAULT_SCOPE = nil -- Global scope
local DATA_STORE_VERSION = "V2" -- Increment this when data format changes

-- Find safe require module
local function findModule(moduleName)
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Safe require function to handle missing modules
local function safeRequire(modulePath, fallback)
    if typeof(modulePath) ~= "Instance" then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if success then
        return result
    else
        warn("DataAccessLayer: Failed to require " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
end

-- Try to load the EventBridge module for events
local EventBridge = safeRequire(findModule("EventBridge")) or {
    fireEvent = function() end,
    registerEvent = function() end
}

-- Register events
if EventBridge.registerEvent then
    EventBridge.registerEvent("DataAccessLayer_SaveSuccess")
    EventBridge.registerEvent("DataAccessLayer_SaveError")
    EventBridge.registerEvent("DataAccessLayer_LoadSuccess")
    EventBridge.registerEvent("DataAccessLayer_LoadError")
end

-- The module
local DataAccessLayer = {}

-- Internal state tracking
local activeDataStores = {}
local saveQueue = {}
local loadQueue = {}
local isSaving = false
local pendingSaves = 0
local successfulSaves = 0
local failedSaves = 0
local isProcessingQueue = false

-- Create a new DataStore instance
function DataAccessLayer.getDataStore(storeName, scope)
    storeName = storeName or "DefaultStore"
    scope = scope or DEFAULT_SCOPE
    
    local fullStoreName = storeName .. "_" .. DATA_STORE_VERSION
    local cacheKey = scope and (fullStoreName .. "_" .. scope) or fullStoreName
    
    -- Check cache first
    if activeDataStores[cacheKey] then
        return activeDataStores[cacheKey]
    end
    
    -- Try to create new DataStore
    local success, result = pcall(function()
        if scope then
            return DataStoreService:GetDataStore(fullStoreName, scope)
        else
            return DataStoreService:GetDataStore(fullStoreName)
        end
    end)
    
    if success then
        activeDataStores[cacheKey] = result
        print("DataAccessLayer: Successfully created DataStore: " .. fullStoreName)
        return result
    else
        warn("DataAccessLayer: Failed to create DataStore: " .. fullStoreName .. " - " .. tostring(result))
        return nil
    end
end

-- Save data with retry mechanism
function DataAccessLayer.saveData(storeName, key, data, options)
    if not storeName or not key then
        warn("DataAccessLayer: Invalid parameters for saveData")
        return false
    end
    
    options = options or {}
    
    -- Get the DataStore
    local dataStore = DataAccessLayer.getDataStore(storeName, options.scope)
    if not dataStore then
        warn("DataAccessLayer: Could not get DataStore: " .. storeName)
        
        -- Fire error event
        if EventBridge.fireEvent then
            EventBridge.fireEvent("DataAccessLayer_SaveError", {
                storeName = storeName,
                key = key,
                errorType = "DataStoreUnavailable",
                error = "Could not get DataStore"
            })
        end
        
        return false
    end
    
    -- Track pending save
    pendingSaves = pendingSaves + 1
    
    -- Add to queue for sequential processing
    table.insert(saveQueue, {
        dataStore = dataStore,
        key = key,
        data = data,
        options = options,
        retryCount = 0,
        maxRetries = options.retryCount or DEFAULT_RETRY_COUNT
    })
    
    -- Process queue if not already processing
    if not isProcessingQueue then
        task.spawn(DataAccessLayer.processSaveQueue)
    end
    
    return true
end

-- Process save queue sequentially
function DataAccessLayer.processSaveQueue()
    if isProcessingQueue then
        return
    end
    
    isProcessingQueue = true
    
    while #saveQueue > 0 do
        local saveOperation = table.remove(saveQueue, 1)
        
        local success, result = pcall(function()
            return saveOperation.dataStore:SetAsync(
                saveOperation.key, 
                saveOperation.data, 
                saveOperation.options.userIds, 
                saveOperation.options.metadata
            )
        end)
        
        if success then
            -- Successful save
            successfulSaves = successfulSaves + 1
            
            -- Fire success event
            if EventBridge.fireEvent then
                EventBridge.fireEvent("DataAccessLayer_SaveSuccess", {
                    storeName = saveOperation.options.storeName or "Unknown",
                    key = saveOperation.key,
                    dataSize = math.floor((#game:GetService("HttpService"):JSONEncode(saveOperation.data))/1024)
                })
            end
        else
            -- Handle failure
            saveOperation.retryCount = saveOperation.retryCount + 1
            
            if saveOperation.retryCount < saveOperation.maxRetries then
                -- Put back in queue for retry
                table.insert(saveQueue, saveOperation)
                
                -- Sleep before retry (with exponential backoff)
                local retryDelay = (saveOperation.options.retryDelay or DEFAULT_RETRY_DELAY) * (2 ^ (saveOperation.retryCount - 1))
                task.wait(retryDelay)
            else
                -- Max retries reached, mark as failed
                failedSaves = failedSaves + 1
                
                -- Fire error event
                if EventBridge.fireEvent then
                    EventBridge.fireEvent("DataAccessLayer_SaveError", {
                        storeName = saveOperation.options.storeName or "Unknown",
                        key = saveOperation.key,
                        errorType = "MaxRetriesReached",
                        error = tostring(result)
                    })
                end
                
                warn("DataAccessLayer: Failed to save data after " .. saveOperation.maxRetries .. " retries: " .. tostring(result))
            end
        end
        
        -- Small delay between operations to prevent throttling
        task.wait(0.1)
    end
    
    isProcessingQueue = false
end

-- Load data with retry mechanism
function DataAccessLayer.loadData(storeName, key, options)
    if not storeName or not key then
        warn("DataAccessLayer: Invalid parameters for loadData")
        return nil
    end
    
    options = options or {}
    local retryCount = options.retryCount or DEFAULT_RETRY_COUNT
    local retryDelay = options.retryDelay or DEFAULT_RETRY_DELAY
    
    -- Get the DataStore
    local dataStore = DataAccessLayer.getDataStore(storeName, options.scope)
    if not dataStore then
        warn("DataAccessLayer: Could not get DataStore: " .. storeName)
        
        -- Fire error event
        if EventBridge.fireEvent then
            EventBridge.fireEvent("DataAccessLayer_LoadError", {
                storeName = storeName,
                key = key,
                errorType = "DataStoreUnavailable",
                error = "Could not get DataStore"
            })
        end
        
        return nil
    end
    
    -- Try loading with retries
    local data = nil
    local success = false
    local errorMessage
    
    for attempt = 1, retryCount do
        success, data = pcall(function()
            return dataStore:GetAsync(key)
        end)
        
        if success then
            break
        else
            errorMessage = data -- Error message from pcall
            warn("DataAccessLayer: Load attempt " .. attempt .. "/" .. retryCount .. " failed: " .. tostring(errorMessage))
            
            if attempt < retryCount then
                -- Wait before retry (with exponential backoff)
                task.wait(retryDelay * (2 ^ (attempt - 1)))
            end
        end
    end
    
    if success then
        -- Fire success event
        if EventBridge.fireEvent then
            EventBridge.fireEvent("DataAccessLayer_LoadSuccess", {
                storeName = storeName,
                key = key,
                dataPresent = (data ~= nil)
            })
        end
        
        return data
    else
        -- Fire error event
        if EventBridge.fireEvent then
            EventBridge.fireEvent("DataAccessLayer_LoadError", {
                storeName = storeName,
                key = key,
                errorType = "LoadFailure",
                error = tostring(errorMessage)
            })
        end
        
        warn("DataAccessLayer: Failed to load data after " .. retryCount .. " retries: " .. tostring(errorMessage))
        return nil
    end
end

-- Get save stats
function DataAccessLayer.getSaveStats()
    return {
        pending = pendingSaves - (successfulSaves + failedSaves),
        successful = successfulSaves,
        failed = failedSaves,
        total = pendingSaves
    }
end

-- Reset stats
function DataAccessLayer.resetStats()
    pendingSaves = 0
    successfulSaves = 0
    failedSaves = 0
end

-- On server shutdown, flush remaining saves
game:BindToClose(function()
    if #saveQueue > 0 then
        print("DataAccessLayer: Flushing " .. #saveQueue .. " pending saves during shutdown")
        -- Process all saves synchronously
        for _, saveOperation in ipairs(saveQueue) do
            pcall(function()
                saveOperation.dataStore:SetAsync(
                    saveOperation.key, 
                    saveOperation.data, 
                    saveOperation.options.userIds, 
                    saveOperation.options.metadata
                )
            end)
        end
        
        local stats = DataAccessLayer.getSaveStats()
        print("DataAccessLayer: Saved " .. stats.successful .. " player data records during shutdown")
    end
end)

-- Register with CoreRegistry if available
local CoreRegistryModule = findModule("CoreRegistry")
if CoreRegistryModule then
    local CoreRegistry = safeRequire(CoreRegistryModule)
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("DataAccessLayer", DataAccessLayer)
        print("DataAccessLayer: Registered with CoreRegistry")
    end
end

return DataAccessLayer
