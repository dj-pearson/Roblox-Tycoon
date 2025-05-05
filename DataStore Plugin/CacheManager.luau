--luau
-- DataStore Plugin/CacheManager.luau

local CacheManager = {}

local cacheHits = 0
local cacheMisses = 0

local cache = {} 
local cacheSizeLimit = 100 -- Maximum number of items in the cache
local lastAccessed = {} -- Table to track the last access time for each cache entry
local AVERAGE_ENTRY_SIZE = 1024 -- Average size of a cache entry in bytes (1KB) - Adjust as needed

-- Stores data in the cache with an optional expiration duration (in seconds)
function CacheManager.set(dataStoreName, keyName, data, duration)
    local cacheKey = dataStoreName .. "_" .. keyName
    local expirationTime = duration and (os.time() + duration) or nil
	local entry = {
        data = data,
        expirationTime = expirationTime,
		lastAccessed = os.time()
    }

	cache[cacheKey] = entry
	lastAccessed[cacheKey] = os.time()

	
	if #cache > cacheSizeLimit then
		local oldestKey
		local oldestTime = math.huge
		for key, time in pairs(lastAccessed) do
			if time < oldestTime then
				oldestTime = time
				oldestKey = key
			end
		end
		if oldestKey then
			cache[oldestKey] = nil
			lastAccessed[oldestKey] = nil
		end
	end
end



-- Retrieves data from the cache. Returns data if found and not expired, otherwise returns nil.
function CacheManager.get(dataStoreName, keyName)
    local cacheKey = dataStoreName .. "_" .. keyName
    local cachedEntry = cache[cacheKey]

    if cachedEntry then
        if cachedEntry.expirationTime and os.time() > cachedEntry.expirationTime then
            -- Cache entry expired, remove it
            cache[cacheKey] = nil
            cacheMisses = cacheMisses + 1
            return nil
        else
            -- Cache entry is valid
			lastAccessed[cacheKey] = os.time()
            cacheHits = cacheHits + 1
            return cachedEntry.data
        end
    else
		cacheMisses = cacheMisses + 1

    
        


        -- No cache entry found
        return nil
    end
end

-- Removes a specific entry from the cache.
function CacheManager.invalidate(dataStoreName, keyName)
	local cacheKey = dataStoreName .. "_" .. keyName
	cache[cacheKey] = nil
end

-- Clears the entire cache
function CacheManager.clear()
	cache = {}
	lastAccessed = {}
end

-- Returns the cache hit and miss counts
function CacheManager.getCacheAnalytics()
	return {
		hits = cacheHits,
		misses = cacheMisses
	}
end

-- Returns a table representing the current contents of the cache, excluding expired entries.
function CacheManager.getCacheContents()
	local contents = {}
	for cacheKey, entry in pairs(cache) do
		if not entry.expirationTime or os.time() <= entry.expirationTime then
			local dataStoreName, keyName = cacheKey:match("(.+)_(.+)")
			if dataStoreName and keyName then
				contents[cacheKey] = {
					dataStoreName = dataStoreName,
					keyName = keyName,
					-- You might want to include more info about the data here (e.g., type, summary)
				}
			end
		end
	end
	return contents
end

-- Estimates the total memory usage of the in-memory cache.
function CacheManager.estimateMemoryUsage()
	local totalSize = 0

	-- Iterate through the cache and estimate the size of each entry
	for _, entry in pairs(cache) do
		totalSize = totalSize + AVERAGE_ENTRY_SIZE -- Add the average size for each entry
	end

	return totalSize
end



function CacheManager.setCacheSizeLimit(size)
	if typeof(size) == "number" then
		cacheSizeLimit = size
	end
end


return CacheManager