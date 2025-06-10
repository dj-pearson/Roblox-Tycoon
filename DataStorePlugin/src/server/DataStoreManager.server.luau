--luau
-- DataStore Plugin/DataStoreManager.luau

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- Safe module resolver function
local function safeRequire(moduleName, fromPath)
    local success, result = pcall(function()
        -- Try shared folder first
        if script.Parent.Parent:FindFirstChild("shared") then
            local sharedModule = script.Parent.Parent.shared:FindFirstChild(moduleName)
            if sharedModule then
                return require(sharedModule)
            end
        end
        
        -- Try server folder
        local serverModule = script.Parent:FindFirstChild(moduleName .. ".server")
        if serverModule then
            return require(serverModule)
        end
        
        -- Try without extension
        local regularModule = script.Parent:FindFirstChild(moduleName)
        if regularModule then
            return require(regularModule)
        end
        
        error("Module not found: " .. moduleName)
    end)
    
    if success and result then
        return result
    else
        warn("Failed to load " .. moduleName .. ", using dummy implementation")
        -- Return a dummy module with basic functions
        return {
            initialize = function() return true end,
            get = function() return nil end,
            set = function() return true end,
            invalidate = function() return true end,
            optimize = function() return true end,
            optimizeCacheDurations = function() return true end,
            loadSchema = function() return nil end,
            saveSchema = function() return true end,
            validate = function(data) return true, data end,
            acquireLock = function() return true end,
            releaseLock = function() return true end,
            timeOperation = function(name, func) 
                local success, result = pcall(func)
                return success, result
            end,
            hasPermission = function() return true end,
            notifyDataAccess = function() return true end
        }
    end
end

-- Load dependencies with safe require
local CacheManager = safeRequire('CacheManager')
local SchemaManager = safeRequire('SchemaManager')
local SchemaValidator = safeRequire('SchemaValidator')
local SessionManager = safeRequire('SessionManager')
local PerformanceMonitor = safeRequire('PerformanceMonitor')
local SecurityManager = safeRequire('SecurityManager')

-- Lazy load MultiServerCoordination to avoid circular dependency
local _lazy_MultiServerCoordination = nil
local function _get_MultiServerCoordination()
    if not _lazy_MultiServerCoordination then
        _lazy_MultiServerCoordination = safeRequire("MultiServerCoordination")
    end
    return _lazy_MultiServerCoordination
end

local DataStoreManager = {}
DataStoreManager.sessionId = HttpService:GenerateGUID()

-- Cache DataStore instances to avoid recreating them
local dataStores = {}

-- Get or create a DataStore instance
local function getDataStore(dataStoreName)
    if not dataStores[dataStoreName] then
        dataStores[dataStoreName] = DataStoreService:GetDataStore(dataStoreName)
    end
    return dataStores[dataStoreName]
end

-- Read data from a DataStore with all the plugin features
function DataStoreManager.getData(dataStoreName, keyName, userId)
    -- Check permissions
    if userId and not SecurityManager.hasPermission(userId, "read") then
        return nil, "Insufficient permissions to read data"
    end
    
    -- Try to get data from cache first
    local cachedData = CacheManager.get(dataStoreName, keyName)
    if cachedData then
        return cachedData
    end
    
    -- If not in cache, check if we need to acquire a session lock
    local locked = SessionManager.acquireLock(dataStoreName, keyName, DataStoreManager.sessionId)
    if not locked then
        return nil, "Failed to acquire lock for reading data"
    end
      -- Get data from DataStore
    local success, result = PerformanceMonitor.timeOperation(
        "GetAsync",
        function()
            local dataStore = getDataStore(dataStoreName)
            return dataStore:GetAsync(keyName)
        end,
        dataStoreName,
        keyName
    )
    
    -- Notify multi-server coordination about this data access
    _get_MultiServerCoordination().notifyDataAccess(dataStoreName, keyName, "read")
    
    -- Release the lock if we only acquired it for reading
    SessionManager.releaseLock(dataStoreName, keyName, DataStoreManager.sessionId)
    
    if success then
        -- Validate data against schema if one exists
        local schema = SchemaManager.loadSchema(dataStoreName, keyName)
        if schema then
            local isValid, validatedData = SchemaValidator.validate(result, schema)
            if not isValid then
                warn("DataStoreManager: Data validation failed for", dataStoreName, keyName, validatedData)
                -- validatedData contains the error message in this case
            else
                result = validatedData
            end
        end
        
        -- Store in cache for future use
        CacheManager.set(dataStoreName, keyName, result, 300) -- Cache for 5 minutes
        
        return result
    else
        return nil, result -- Error message
    end
end

-- Write data to a DataStore with all the plugin features
function DataStoreManager.setData(dataStoreName, keyName, data, userId)
    -- Check permissions
    if userId and not SecurityManager.hasPermission(userId, "write") then
        return false, "Insufficient permissions to write data"
    end
    
    -- Validate data against schema if one exists
    local schema = SchemaManager.loadSchema(dataStoreName, keyName)
    if schema then
        local isValid, validatedData = SchemaValidator.validate(data, schema)
        if not isValid then
            return false, "Data validation failed: " .. validatedData
        end
        data = validatedData
    end
    
    -- Acquire a session lock for writing
    local locked = SessionManager.acquireLock(dataStoreName, keyName, DataStoreManager.sessionId)
    if not locked then
        return false, "Failed to acquire lock for writing data"
    end
    
    -- Set data in the DataStore
    local success, result = PerformanceMonitor.timeOperation(
        "SetAsync",
        function()
            local dataStore = getDataStore(dataStoreName)
            return dataStore:SetAsync(keyName, data)
        end,
        dataStoreName,
        keyName
    )
    
    -- Keep the lock active if successful (to be released later) or release it if failed
    if not success then
        SessionManager.releaseLock(dataStoreName, keyName, DataStoreManager.sessionId)
        return false, result
    end
      -- Update cache with the new data
    CacheManager.set(dataStoreName, keyName, data, 300) -- Cache for 5 minutes
    
    -- Notify multi-server coordination about this data access
    _get_MultiServerCoordination().notifyDataAccess(dataStoreName, keyName, "write")
    
    return true
end

-- Update data in a DataStore with all the plugin features
function DataStoreManager.updateData(dataStoreName, keyName, updateFunction, userId)
    -- Check permissions
    if userId and not SecurityManager.hasPermission(userId, "write") then
        return nil, "Insufficient permissions to update data"
    end
    
    -- Acquire a session lock for updating
    local locked = SessionManager.acquireLock(dataStoreName, keyName, DataStoreManager.sessionId)
    if not locked then
        return nil, "Failed to acquire lock for updating data"
    end
    
    -- Get schema if it exists
    local schema = SchemaManager.loadSchema(dataStoreName, keyName)
    
    -- Update data in the DataStore
    local success, result = PerformanceMonitor.timeOperation(
        "UpdateAsync",
        function()
            local dataStore = getDataStore(dataStoreName)
            return dataStore:UpdateAsync(keyName, function(oldData)
                -- Apply the user's update function
                local newData = updateFunction(oldData)
                
                -- Validate new data against schema if one exists
                if schema then
                    local isValid, validatedData = SchemaValidator.validate(newData, schema)
                    if not isValid then
                        warn("DataStoreManager: Data validation failed in UpdateAsync:", validatedData)
                        return nil -- Abort the update
                    end
                    return validatedData
                end
                
                return newData
            end)
        end,
        dataStoreName,
        keyName
    )
    
    -- Release the lock
    SessionManager.releaseLock(dataStoreName, keyName, DataStoreManager.sessionId)
      if success then
        -- Update cache with the new data
        CacheManager.set(dataStoreName, keyName, result, 300) -- Cache for 5 minutes
        
        -- Notify multi-server coordination about this data access
        _get_MultiServerCoordination().notifyDataAccess(dataStoreName, keyName, "write")
        
        return result
    else
        return nil, result -- Error message
    end
end

-- Remove data from a DataStore with all the plugin features
function DataStoreManager.removeData(dataStoreName, keyName, userId)
    -- Check permissions
    if userId and not SecurityManager.hasPermission(userId, "delete") then
        return false, "Insufficient permissions to delete data"
    end
    
    -- Acquire a session lock for deleting
    local locked = SessionManager.acquireLock(dataStoreName, keyName, DataStoreManager.sessionId)
    if not locked then
        return false, "Failed to acquire lock for deleting data"
    end
    
    -- Remove data from the DataStore
    local success, result = PerformanceMonitor.timeOperation(
        "RemoveAsync",
        function()
            local dataStore = getDataStore(dataStoreName)
            return dataStore:RemoveAsync(keyName)
        end,
        dataStoreName,
        keyName
    )
      -- Release the lock
    SessionManager.releaseLock(dataStoreName, keyName, DataStoreManager.sessionId)
    
    -- Invalidate cache
    CacheManager.invalidate(dataStoreName, keyName)
    
    -- Notify multi-server coordination about this data removal
    _get_MultiServerCoordination().notifyDataAccess(dataStoreName, keyName, "delete")
    
    return success, result
end

-- List keys in a DataStore with pagination
function DataStoreManager.listKeys(dataStoreName, pageSize, cursor, userId)
    -- Check permissions
    if userId and not SecurityManager.hasPermission(userId, "read") then
        return nil, "Insufficient permissions to list keys"
    end
    
    -- List keys from the DataStore
    local success, result = PerformanceMonitor.timeOperation(
        "ListKeysAsync",
        function()
            local dataStore = getDataStore(dataStoreName)
            return dataStore:ListKeysAsync(pageSize or 50, cursor)
        end,
        dataStoreName,
        nil
    )
    
    if success then
        return {
            keys = result:GetCurrentPage(),
            nextCursor = result.ExclusiveStartKey
        }
    else
        return nil, result -- Error message
    end
end

-- Initialize the plugin
function DataStoreManager.initialize()
    if SessionManager and SessionManager.initialize then
        SessionManager.initialize()
    end
    
    -- Setup a periodic task to optimize the cache
    task.spawn(function()
        while true do
            task.wait(300) -- Every 5 minutes
            if CacheManager and CacheManager.optimizeCacheDurations then
                CacheManager.optimizeCacheDurations()
            end
        end
    end)
    
    print("DataStoreManager initialized with session ID:", DataStoreManager.sessionId)
end

return DataStoreManager

