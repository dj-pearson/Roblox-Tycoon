--luau
-- DataStore Plugin/SessionManager.luau

local SessionManager = {}

local DataStoreService = game:GetService("DataStoreService")
local LockDataStore = DataStoreService:GetDataStore("SessionLocks")

local DEFAULT_LOCK_TIMEOUT = 600 -- 10 minutes in seconds
local LOCK_PREFIX = "Lock_"

function SessionManager.initialize()
    -- Start monitoring locks when the module is initialized
    coroutine.wrap(SessionManager.monitorLocks)()
end

local MAX_RETRIES = 3
local RETRY_DELAY = 1

function SessionManager.acquireLock(dataStoreName, keyName, sessionId)
    local lockKey = LOCK_PREFIX .. dataStoreName .. "_" .. keyName
    local retries = 0
    local success, result

    repeat
        success, result = pcall(function()
            return LockDataStore:UpdateAsync(lockKey, function(oldLockData)
                if oldLockData == nil or oldLockData.sessionId == sessionId then
                    local newLockData = {
                        sessionId = sessionId,
                        timestamp = os.time()
                    }
                    return newLockData
                else
                    return oldLockData, "Locked by another session"
                end
            end)
        end)        if not success then
            retries = retries + 1
            warn("SessionManager: Failed to acquire lock for", keyName, ". Attempt", retries, "of", MAX_RETRIES, ":", result)
            if retries < MAX_RETRIES then
                task.wait(RETRY_DELAY)
            end
        end 
    until success or retries >= MAX_RETRIES

    if success then
        if result == nil then return true
         else
            if typeof(result) == "string" then
                warn("SessionManager: Key", keyName, "is already locked by session", result)
            else
                return true
            end
            return false
        end    else 
        warn("SessionManager: Failed to get lock for", keyName, ":", result)
        return false
    end
end

function SessionManager.releaseLock(dataStoreName, keyName, sessionId)
    local lockKey = LOCK_PREFIX .. dataStoreName .. "_" .. keyName
    local retries = 0
    local success, result

    repeat
        success, result = pcall(function()
            local currentLock = LockDataStore:GetAsync(lockKey)
            if currentLock ~= nil and currentLock.sessionId == sessionId then
                LockDataStore:RemoveAsync(lockKey)
                return true
            elseif currentLock == nil then
                return true
            else
                warn("SessionManager: Cannot release lock for", keyName, ". It is held by session", currentLock.sessionId, "not", sessionId)
                return false
            end
        end)
        if not success then
            retries = retries + 1
            warn("SessionManager: Failed to release lock for", keyName, ". Attempt", retries, "of", MAX_RETRIES, ":", result)
            if retries < MAX_RETRIES then
                task.wait(RETRY_DELAY)
            end
        end
    until success or retries >= MAX_RETRIES

    if success then
        return result
    else
        warn("SessionManager: Failed to release lock for", keyName, "after retries:", result)
        return false
    end
end

function SessionManager.forceReleaseLock(dataStoreName, keyName)
	local lockKey = LOCK_PREFIX .. dataStoreName .. "_" .. keyName
	local removeSuccess, removeError = pcall(LockDataStore.RemoveAsync, LockDataStore, lockKey)

	if removeSuccess then
		print("SessionManager: Force-released lock for", keyName)
		return true
	else
		warn("SessionManager: Failed to force-release lock for", keyName, ":", removeError)
		return false
	end
end

function SessionManager.getActiveLocks()
    local activeLocks = {}
    local lockKeys = {}
    local nextPageToken
    local success, listKeys
    repeat
        success, listKeys = pcall(LockDataStore.ListKeysAsync, LockDataStore, nil, nil, nextPageToken)
        if success then
            for _, keyInfo in ipairs(listKeys.Keys) do
                if string.sub(keyInfo.Key, 1, #LOCK_PREFIX) == LOCK_PREFIX then
                    table.insert(lockKeys, keyInfo.Key)
                end
            end
            nextPageToken = listKeys.NextPageToken
        else
            warn("SessionManager: Failed to list keys:", listKeys)
        end
    until nextPageToken == nil or not success

    for _, lockKey in ipairs(lockKeys) do
        local lockData = SessionManager.getLockStatus(string.sub(lockKey, #LOCK_PREFIX+1):match("^([^_]+)_"), string.sub(lockKey, #LOCK_PREFIX+1):match("_([^_]+)$"))
        if lockData then table.insert(activeLocks, {lockKey = lockKey, data = lockData}) end
    end
    return activeLocks
end
-- Optional: Add a function to check the lock status
function SessionManager.getLockStatus(dataStoreName, keyName)
    local lockKey = LOCK_PREFIX .. dataStoreName .. "_" .. keyName
    local success, lockData = pcall(LockDataStore.GetAsync, LockDataStore, lockKey)

    if success then
        return lockData -- Returns lock data (including sessionId) or nil
    else
        warn("SessionManager: Failed to get lock status for", keyName, ":", lockData)
        return nil
    end
end

function SessionManager.monitorLocks()
    while true do
        local activeLocks = SessionManager.getActiveLocks()
        for _, lockInfo in ipairs(activeLocks) do
            local lockData = lockInfo.data
            local dataStoreName, keyName = string.match(lockInfo.lockKey, "Lock_(.*)_(.*)")
            if lockData and lockData.timestamp then
                local timeElapsed = os.time() - lockData.timestamp
                if timeElapsed > DEFAULT_LOCK_TIMEOUT then
                    SessionManager.releaseLock(dataStoreName, keyName, lockData.sessionId)
                    print("SessionManager: Released expired lock for", keyName, "held by session", lockData.sessionId)
                end
            end
        end
        task.wait(60) -- Check every 60 seconds (you can adjust this interval)
    end
end


return SessionManager