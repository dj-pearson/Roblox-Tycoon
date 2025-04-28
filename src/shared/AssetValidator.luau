-- AssetValidator.luau
-- Utility for validating assets to prevent errors from invalid or inaccessible assets
-- Created: April 28, 2025

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true
local DEFAULT_TIMEOUT = 5 -- seconds
local BATCH_SIZE = 10 -- assets per batch
local BATCH_DELAY = 0.1 -- seconds between batches
local PRELOAD_TIMEOUT = 30 -- seconds for preloading

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[AssetValidator][%s] %s", level, message))
end

-- AssetValidator object
local AssetValidator = {
	_version = VERSION,
	_validatedAssets = {}, -- Assets that have been validated
	_failedAssets = {}, -- Assets that failed validation
	_inProgress = {}, -- Assets currently being validated
	_preloadQueue = {}, -- Queue of assets to preload
	_stats = {
		validCount = 0,
		failedCount = 0,
		preloadedCount = 0
	},
	_callbacks = {}, -- Callbacks for completed validations
	_assetTypeHandlers = {} -- Custom handlers for different asset types
}

-- Get ModuleLoader if available
local function getModuleLoader()
	local shared = ReplicatedStorage:FindFirstChild("shared")
	if shared and shared:FindFirstChild("ModuleLoader") then
		local success, result = pcall(function()
			return require(shared.ModuleLoader)
		end)
		
		if success then
			return result
		end
	end
	
	return nil
end

-- Try to get a module using ModuleLoader
local function getModule(moduleName)
	local moduleLoader = getModuleLoader()
	if moduleLoader then
		return moduleLoader:GetModule(moduleName)
	end
	return nil
end

-- Register an asset type handler
function AssetValidator:RegisterAssetTypeHandler(assetType, handler)
	if type(handler) ~= "function" then
		log("Handler must be a function", "Error")
		return false
	end
	
	self._assetTypeHandlers[assetType] = handler
	log("Registered handler for asset type: " .. assetType)
	return true
end

-- Determine asset type
local function getAssetType(asset)
	if typeof(asset) == "Instance" then
		return asset.ClassName
	elseif typeof(asset) == "string" then
		-- Check if it's an asset ID
		if string.match(asset, "^rbxassetid://(%d+)$") then
			return "ContentId"
		end
		
		-- Check if it's an image
		local lowerAsset = string.lower(asset)
		if string.match(lowerAsset, "%.png$") or 
		   string.match(lowerAsset, "%.jpg$") or 
		   string.match(lowerAsset, "%.jpeg$") then
			return "Image"
		end
		
		-- Check if it's a model
		if string.match(lowerAsset, "%.rbxm$") then
			return "Model"
		end
		
		-- Check if it's a sound
		if string.match(lowerAsset, "%.mp3$") or 
		   string.match(lowerAsset, "%.ogg$") then
			return "Sound"
		end
	end
	
	return "Unknown"
end

-- Validate a single asset
function AssetValidator:ValidateAsset(asset, callback)
	if not asset then
		log("Asset is nil", "Error")
		if callback then callback(false, "Asset is nil") end
		return false
	end
	
	local assetId
	if typeof(asset) == "Instance" then
		assetId = asset:GetFullName()
	else
		assetId = tostring(asset)
	end
	
	-- Check if already validated
	if self._validatedAssets[assetId] then
		log("Asset already validated: " .. assetId, "Info")
		if callback then callback(true) end
		return true
	end
	
	-- Check if previously failed
	if self._failedAssets[assetId] then
		log("Asset previously failed validation: " .. assetId, "Warning")
		if callback then callback(false, self._failedAssets[assetId]) end
		return false
	end
	
	-- Check if validation in progress
	if self._inProgress[assetId] then
		log("Validation already in progress for: " .. assetId, "Info")
		-- Add callback to be called when validation completes
		if callback then
			self._callbacks[assetId] = self._callbacks[assetId] or {}
			table.insert(self._callbacks[assetId], callback)
		end
		return true
	end
	
	-- Mark as in progress
	self._inProgress[assetId] = true
	
	-- Determine asset type and use appropriate validation method
	local assetType = getAssetType(asset)
	
	-- Check if we have a custom handler for this asset type
	if self._assetTypeHandlers[assetType] then
		spawn(function()
			local success, errorMessage = self._assetTypeHandlers[assetType](asset)
			self:HandleValidationResult(assetId, success, errorMessage)
			
			-- Call the original callback
			if callback then callback(success, errorMessage) end
			
			-- Call any additional callbacks
			self:CallAssetCallbacks(assetId, success, errorMessage)
		end)
		return true
	end
	
	-- Default validation using ContentProvider
	spawn(function()
		local assets = {asset}
		local success, errorMessage = pcall(function()
			ContentProvider:PreloadAsync(assets)
		end)
		
		self:HandleValidationResult(assetId, success, errorMessage)
		
		-- Call the original callback
		if callback then callback(success, errorMessage) end
		
		-- Call any additional callbacks
		self:CallAssetCallbacks(assetId, success, errorMessage)
	end)
	
	return true
end

-- Handle validation result
function AssetValidator:HandleValidationResult(assetId, success, errorMessage)
	-- Remove from in progress
	self._inProgress[assetId] = nil
	
	if success then
		-- Add to validated assets
		self._validatedAssets[assetId] = true
		self._stats.validCount += 1
		log("Asset validated: " .. assetId)
	else
		-- Add to failed assets
		self._failedAssets[assetId] = errorMessage
		self._stats.failedCount += 1
		log("Asset validation failed: " .. assetId .. " - " .. tostring(errorMessage), "Warning")
	end
end

-- Call all callbacks for an asset
function AssetValidator:CallAssetCallbacks(assetId, success, errorMessage)
	-- Call any waiting callbacks
	if self._callbacks[assetId] then
		for _, cb in ipairs(self._callbacks[assetId]) do
			pcall(function()
				cb(success, errorMessage)
			end)
		end
		self._callbacks[assetId] = nil
	end
end

-- Validate multiple assets
function AssetValidator:ValidateAssets(assets, progressCallback, completedCallback)
	if type(assets) ~= "table" then
		log("Assets must be a table", "Error")
		if completedCallback then completedCallback(false, "Assets must be a table") end
		return false
	end
	
	local assetCount = #assets
	log("Validating " .. assetCount .. " assets")
	
	local validCount = 0
	local failedCount = 0
	local results = {}
	
	-- Process assets in batches
	spawn(function()
		for i = 1, assetCount, BATCH_SIZE do
			local batchEnd = math.min(i + BATCH_SIZE - 1, assetCount)
			local batch = {}
			
			-- Create batch
			for j = i, batchEnd do
				batch[#batch + 1] = assets[j]
			end
			
			-- Process batch
			for _, asset in ipairs(batch) do
				local assetId
				if typeof(asset) == "Instance" then
					assetId = asset:GetFullName()
				else
					assetId = tostring(asset)
				end
				
				self:ValidateAsset(asset, function(success, errorMessage)
					if success then
						validCount += 1
						results[assetId] = {success = true}
					else
						failedCount += 1
						results[assetId] = {success = false, error = errorMessage}
					end
					
					-- Call progress callback if provided
					if progressCallback then
						progressCallback(validCount + failedCount, assetCount, success, asset)
					end
					
					-- Check if all done
					if validCount + failedCount >= assetCount and completedCallback then
						completedCallback(validCount == assetCount, results)
					end
				end)
			end
			
			-- Wait before next batch
			wait(BATCH_DELAY)
		end
	end)
	
	return true
end

-- Add assets to preload queue
function AssetValidator:QueueForPreload(assets)
	if type(assets) ~= "table" then
		assets = {assets}
	end
	
	for _, asset in ipairs(assets) do
		if asset then
			table.insert(self._preloadQueue, asset)
		end
	end
	
	log("Added " .. #assets .. " assets to preload queue, total: " .. #self._preloadQueue)
	return true
end

-- Preload all queued assets
function AssetValidator:PreloadQueuedAssets(progressCallback, completedCallback)
	local queueCount = #self._preloadQueue
	if queueCount == 0 then
		log("No assets in preload queue")
		if completedCallback then completedCallback(true, {}) end
		return true
	end
	
	log("Preloading " .. queueCount .. " assets")
	
	-- Make a copy of the queue
	local assetsToPreload = {}
	for i, asset in ipairs(self._preloadQueue) do
		assetsToPreload[i] = asset
	end
	
	-- Clear the queue
	self._preloadQueue = {}
	
	-- Start preloading
	local startTime = os.clock()
	self:ValidateAssets(assetsToPreload, progressCallback, function(success, results)
		local duration = os.clock() - startTime
		log("Preloaded " .. queueCount .. " assets in " .. string.format("%.2f", duration) .. " seconds")
		
		self._stats.preloadedCount += queueCount
		
		if completedCallback then
			completedCallback(success, results)
		end
	end)
	
	return true
end

-- Check if an asset is valid
function AssetValidator:IsAssetValid(asset)
	if not asset then
		return false
	end
	
	local assetId
	if typeof(asset) == "Instance" then
		assetId = asset:GetFullName()
	else
		assetId = tostring(asset)
	end
	
	return self._validatedAssets[assetId] == true
end

-- Get stats about validated and failed assets
function AssetValidator:GetStats()
	return {
		validCount = self._stats.validCount,
		failedCount = self._stats.failedCount,
		preloadedCount = self._stats.preloadedCount,
		queuedCount = #self._preloadQueue,
		inProgressCount = 0, -- Calculated below
		callbackCount = 0 -- Calculated below
	}
end

-- Get version
function AssetValidator:GetVersion()
	return self._version
end

-- Register default asset type handlers
function AssetValidator:RegisterDefaultHandlers()
	-- Special handler for ImageLabels and ImageButtons
	self:RegisterAssetTypeHandler("ImageLabel", function(asset)
		-- Check if Image is set
		if not asset.Image or asset.Image == "" then
			return true -- Empty image is valid
		end
		
		-- Try to preload
		local success, result = pcall(function()
			ContentProvider:PreloadAsync({asset})
		end)
		
		return success, not success and result or nil
	end)
	
	-- Handler for ImageButton (same as ImageLabel)
	self:RegisterAssetTypeHandler("ImageButton", self._assetTypeHandlers["ImageLabel"])
	
	-- Handler for Sound objects
	self:RegisterAssetTypeHandler("Sound", function(asset)
		-- Check if SoundId is set
		if not asset.SoundId or asset.SoundId == "" then
			return true -- Empty sound is valid
		end
		
		-- Try to preload
		local success, result = pcall(function()
			ContentProvider:PreloadAsync({asset})
		end)
		
		return success, not success and result or nil
	end)
	
	-- Handler for ContentIds
	self:RegisterAssetTypeHandler("ContentId", function(asset)
		-- Try to create a temporary instance to preload
		local success, tempInstance = pcall(function()
			local id = string.match(asset, "^rbxassetid://(%d+)$")
			if not id then
				return nil
			end
			
			-- Create a temporary ImageLabel to test the asset
			local temp = Instance.new("ImageLabel")
			temp.Size = UDim2.new(0, 1, 0, 1)
			temp.Visible = false
			temp.Image = asset
			
			-- Return the temp instance
			return temp
		end)
		
		if not success or not tempInstance then
			return false, "Failed to create test instance for: " .. asset
		end
		
		-- Try to preload the temporary instance
		local loadSuccess, loadResult = pcall(function()
			ContentProvider:PreloadAsync({tempInstance})
		end)
		
		-- Clean up the temp instance
		pcall(function() tempInstance:Destroy() end)
		
		return loadSuccess, not loadSuccess and loadResult or nil
	end)
	
	log("Registered default asset type handlers")
end

-- Initialize
do
	log("Initializing AssetValidator v" .. VERSION)
	AssetValidator:RegisterDefaultHandlers()
	
	-- Register with ModuleLoader if available
	local moduleLoader = getModuleLoader()
	if moduleLoader then
		moduleLoader:RegisterPath("AssetValidator", "ReplicatedStorage.shared.AssetValidator")
		log("Registered with ModuleLoader")
	end
	
	log("AssetValidator initialized")
end

return AssetValidator
