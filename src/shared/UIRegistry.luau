-- UIRegistry.luau
-- Centralized registry for UI components and management
-- Created: April 28, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true
local DEFAULT_TIMEOUT = 5 -- seconds
local UPDATE_INTERVAL = 1 -- seconds for periodic tasks

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[UIRegistry][%s] %s", level, message))
end

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

-- Get AssetValidator if available
local function getAssetValidator()
	return getModule("AssetValidator")
end

-- Safe wait for child function with timeout
local function safeWaitForChild(parent, childName, timeout)
	timeout = timeout or DEFAULT_TIMEOUT
	local startTime = os.clock()
	
	while os.clock() - startTime < timeout do
		local child = parent:FindFirstChild(childName)
		if child then
			return child
		end
		wait(0.1)
	end
	
	return nil -- Timed out
end

-- UIRegistry object
local UIRegistry = {
	_version = VERSION,
	_registry = {}, -- Registered UI components
	_instances = {}, -- Active UI instances
	_templates = {}, -- UI templates
	_factories = {}, -- Component factories
	_animations = {}, -- UI animations
	_listeners = {}, -- Input listeners
	_dynamicElements = {}, -- Elements that need periodic updates
	_updateConnection = nil, -- Connection for periodic updates
	_profileEnabled = false, -- Whether UI performance profiling is enabled
	_stats = {
		createdCount = 0,
		destroyedCount = 0,
		activeCount = 0
	},
	_initialized = false
}

-- Initialize the UIRegistry
function UIRegistry:Initialize()
	if self._initialized then
		return true
	end
	
	log("Initializing UIRegistry v" .. VERSION)
	
	-- Start periodic update
	self:StartPeriodicUpdate()
	
	-- Connect player events
	self:ConnectPlayerEvents()
	
	self._initialized = true
	log("UIRegistry initialized")
	
	return true
end

-- Start periodic update
function UIRegistry:StartPeriodicUpdate()
	-- Disconnect existing connection if any
	if self._updateConnection then
		self._updateConnection:Disconnect()
	end
	
	-- Create a new update connection
	spawn(function()
		while true do
			self:PerformPeriodicUpdate()
			wait(UPDATE_INTERVAL)
		end
	end)
	
	log("Started periodic update with interval: " .. UPDATE_INTERVAL .. " seconds")
	return true
end

-- Perform periodic update
function UIRegistry:PerformPeriodicUpdate()
	-- Update dynamic elements
	for id, element in pairs(self._dynamicElements) do
		-- Check if element still exists
		if not element.instance or not element.instance.Parent then
			self._dynamicElements[id] = nil
			continue
		end
		
		-- Call update function if provided
		if element.updateFunc then
			pcall(function()
				element.updateFunc(element.instance)
			end)
		end
	end
	
	-- Profile UI performance if enabled
	if self._profileEnabled then
		self:ProfileUIPerformance()
	end
end

-- Profile UI performance
function UIRegistry:ProfileUIPerformance()
	-- Collect stats on active UI components
	local stats = {
		totalElements = 0,
		visibleElements = 0,
		hiddenElements = 0,
		byType = {}
	}
	
	-- Count active instances
	for id, instance in pairs(self._instances) do
		if instance and instance.Parent then
			stats.totalElements += 1
			
			-- Check visibility
			local visible = true
			if instance:IsA("GuiObject") then
				visible = instance.Visible
			end
			
			if visible then
				stats.visibleElements += 1
			else
				stats.hiddenElements += 1
			end
			
			-- Count by type
			local className = instance.ClassName
			stats.byType[className] = (stats.byType[className] or 0) + 1
		else
			-- Clean up invalid instances
			self._instances[id] = nil
		end
	end
	
	log("UI Performance: " .. stats.totalElements .. " total, " .. 
		stats.visibleElements .. " visible, " .. 
		stats.hiddenElements .. " hidden")
end

-- Connect player events
function UIRegistry:ConnectPlayerEvents()
	-- Handle player joining
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerJoined(player)
	end)
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		spawn(function()
			self:OnPlayerJoined(player)
		end)
	end
	
	log("Connected player events")
	return true
end

-- Handle player joining
function UIRegistry:OnPlayerJoined(player)
	log("Player joined: " .. player.Name)
	
	-- Wait for player GUI
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		playerGui = safeWaitForChild(player, "PlayerGui")
	end
	
	if not playerGui then
		log("Failed to get PlayerGui for player: " .. player.Name, "Error")
		return
	end
	
	-- Preload UI assets for this player
	self:PreloadUIAssetsForPlayer(player)
end

-- Preload UI assets for a player
function UIRegistry:PreloadUIAssetsForPlayer(player)
	local assetValidator = getAssetValidator()
	if not assetValidator then
		log("AssetValidator not available, skipping asset preloading", "Warning")
		return
	end
	
	-- Collect all assets from registered templates
	local assets = {}
	for _, template in pairs(self._templates) do
		self:CollectAssetsFromInstance(template, assets)
	end
	
	-- Start preloading
	if #assets > 0 then
		log("Preloading " .. #assets .. " UI assets for player: " .. player.Name)
		
		assetValidator:ValidateAssets(assets, function(current, total)
			-- Progress update
			local percent = math.floor((current / total) * 100)
			if percent % 25 == 0 then -- Log at 25%, 50%, 75%, 100%
				log("Asset preloading progress: " .. percent .. "% (" .. current .. "/" .. total .. ")")
			end
		end, function(success)
			-- Completion
			if success then
				log("Successfully preloaded all UI assets for player: " .. player.Name)
			else
				log("Failed to preload some UI assets for player: " .. player.Name, "Warning")
			end
		end)
	end
end

-- Collect assets from an Instance
function UIRegistry:CollectAssetsFromInstance(instance, assets)
	assets = assets or {}
	
	-- Check if this instance has an Image property
	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		if instance.Image and instance.Image ~= "" then
			table.insert(assets, instance)
		end
	end
	
	-- Check if this instance has a SoundId property
	if instance:IsA("Sound") then
		if instance.SoundId and instance.SoundId ~= "" then
			table.insert(assets, instance)
		end
	end
	
	-- Check TextLabel for special font or rich text with images
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		if instance.RichText and string.find(instance.Text, "rbxassetid://") then
			-- Extract asset IDs from rich text
			for assetId in string.gmatch(instance.Text, "rbxassetid://(%d+)") do
				table.insert(assets, "rbxassetid://" .. assetId)
			end
		end
	end
	
	-- Check all children recursively
	for _, child in ipairs(instance:GetChildren()) do
		self:CollectAssetsFromInstance(child, assets)
	end
	
	return assets
end

-- Register a UI component
function UIRegistry:Register(componentName, component)
	if not componentName or not component then
		log("Invalid component registration", "Error")
		return false
	end
	
	-- Store in registry
	self._registry[componentName] = component
	log("Registered component: " .. componentName)
	
	return true
end

-- Register a UI template
function UIRegistry:RegisterTemplate(templateName, template)
	if not templateName or not template then
		log("Invalid template registration", "Error")
		return false
	end
	
	-- Store template
	self._templates[templateName] = template
	log("Registered template: " .. templateName)
	
	-- Preload assets for this template
	local assetValidator = getAssetValidator()
	if assetValidator then
		local assets = {}
		self:CollectAssetsFromInstance(template, assets)
		
		if #assets > 0 then
			assetValidator:QueueForPreload(assets)
		end
	end
	
	return true
end

-- Register a component factory
function UIRegistry:RegisterFactory(factoryName, factoryFunc)
	if not factoryName or type(factoryFunc) ~= "function" then
		log("Invalid factory registration", "Error")
		return false
	end
	
	-- Store factory
	self._factories[factoryName] = factoryFunc
	log("Registered factory: " .. factoryName)
	
	return true
end

-- Create a UI component from a registered template
function UIRegistry:Create(templateName, properties)
	local template = self._templates[templateName]
	if not template then
		log("Template not found: " .. templateName, "Error")
		return nil
	end
	
	-- Clone the template
	local clone
	local success, result = pcall(function()
		return template:Clone()
	end)
	
	if success then
		clone = result
	else
		log("Failed to clone template: " .. templateName .. " - " .. tostring(result), "Error")
		return nil
	end
	
	-- Apply properties if provided
	if properties then
		self:ApplyProperties(clone, properties)
	end
	
	-- Generate a unique ID for this instance
	local id = templateName .. "_" .. tostring(self._stats.createdCount)
	
	-- Store in active instances
	self._instances[id] = clone
	self._stats.createdCount += 1
	self._stats.activeCount += 1
	
	return clone, id
end

-- Create a UI component using a factory
function UIRegistry:CreateFromFactory(factoryName, ...)
	local factory = self._factories[factoryName]
	if not factory then
		log("Factory not found: " .. factoryName, "Error")
		return nil
	end
	
	-- Call the factory function
	local success, result = pcall(function()
		return factory(...)
	end)
	
	if success then
		if typeof(result) == "Instance" then
			-- Generate a unique ID for this instance
			local id = factoryName .. "_" .. tostring(self._stats.createdCount)
			
			-- Store in active instances
			self._instances[id] = result
			self._stats.createdCount += 1
			self._stats.activeCount += 1
			
			return result, id
		else
			log("Factory did not return an Instance: " .. factoryName, "Warning")
			return result
		end
	else
		log("Error in factory: " .. factoryName .. " - " .. tostring(result), "Error")
		return nil
	end
end

-- Apply properties to an instance
function UIRegistry:ApplyProperties(instance, properties)
	for property, value in pairs(properties) do
		-- Handle special properties
		if property == "Children" and type(value) == "table" then
			-- Add children
			for _, child in ipairs(value) do
				if typeof(child) == "Instance" then
					child.Parent = instance
				end
			end
		elseif property == "Events" and type(value) == "table" then
			-- Connect events
			for event, callback in pairs(value) do
				if type(callback) == "function" and instance[event] then
					instance[event]:Connect(callback)
				end
			end
		elseif property == "Attributes" and type(value) == "table" then
			-- Set attributes
			for name, attrValue in pairs(value) do
				instance:SetAttribute(name, attrValue)
			end
		else
			-- Set regular property
			pcall(function()
				instance[property] = value
			end)
		end
	end
end

-- Register a UI animation
function UIRegistry:RegisterAnimation(animationName, animationFunc)
	if not animationName or type(animationFunc) ~= "function" then
		log("Invalid animation registration", "Error")
		return false
	end
	
	-- Store animation
	self._animations[animationName] = animationFunc
	log("Registered animation: " .. animationName)
	
	return true
end

-- Play a registered animation
function UIRegistry:PlayAnimation(animationName, instance, ...)
	local animation = self._animations[animationName]
	if not animation then
		log("Animation not found: " .. animationName, "Error")
		return false
	end
	
	-- Call the animation function
	local success, result = pcall(function()
		return animation(instance, ...)
	end)
	
	if not success then
		log("Error in animation: " .. animationName .. " - " .. tostring(result), "Error")
		return false
	end
	
	return result
end

-- Register an input listener
function UIRegistry:RegisterInputListener(listenerName, listenerFunc, inputTypes)
	if not listenerName or type(listenerFunc) ~= "function" then
		log("Invalid listener registration", "Error")
		return false
	end
	
	-- Store listener
	self._listeners[listenerName] = {
		func = listenerFunc,
		inputTypes = inputTypes or {"InputBegan", "InputEnded"}
	}
	
	-- Connect the listener
	for _, inputType in ipairs(self._listeners[listenerName].inputTypes) do
		if UserInputService[inputType] then
			self._listeners[listenerName][inputType] = UserInputService[inputType]:Connect(function(...)
				listenerFunc(...)
			end)
		end
	end
	
	log("Registered input listener: " .. listenerName)
	
	return true
end

-- Remove an input listener
function UIRegistry:RemoveInputListener(listenerName)
	local listener = self._listeners[listenerName]
	if not listener then
		return false
	end
	
	-- Disconnect all connections
	for inputType, connection in pairs(listener) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	
	-- Remove from listeners
	self._listeners[listenerName] = nil
	log("Removed input listener: " .. listenerName)
	
	return true
end

-- Register an element for dynamic updates
function UIRegistry:RegisterDynamicElement(element, updateFunc)
	if not element then
		log("Element is nil", "Error")
		return false
	end
	
	local id
	if typeof(element) == "Instance" then
		id = element:GetFullName()
	else
		id = tostring(element)
	end
	
	-- Store element
	self._dynamicElements[id] = {
		instance = element,
		updateFunc = updateFunc
	}
	
	log("Registered dynamic element: " .. id)
	
	return true
end

-- Destroy a UI component
function UIRegistry:Destroy(instanceOrId)
	local id, instance
	
	if typeof(instanceOrId) == "Instance" then
		-- Find the ID for this instance
		for i, inst in pairs(self._instances) do
			if inst == instanceOrId then
				id = i
				instance = inst
				break
			end
		end
	else
		-- Use the provided ID
		id = instanceOrId
		instance = self._instances[id]
	end
	
	if not id or not instance then
		log("Instance not found", "Warning")
		return false
	end
	
	-- Remove from dynamic elements
	local dynamicId = instance:GetFullName()
	if self._dynamicElements[dynamicId] then
		self._dynamicElements[dynamicId] = nil
	end
	
	-- Destroy the instance
	pcall(function()
		instance:Destroy()
	end)
	
	-- Remove from active instances
	self._instances[id] = nil
	self._stats.destroyedCount += 1
	self._stats.activeCount -= 1
	
	log("Destroyed UI component: " .. id)
	
	return true
end

-- Get a registered component
function UIRegistry:GetComponent(componentName)
	return self._registry[componentName]
end

-- Get a registered template
function UIRegistry:GetTemplate(templateName)
	return self._templates[templateName]
end

-- Get all active instances
function UIRegistry:GetActiveInstances()
	return self._instances
end

-- Toggle UI performance profiling
function UIRegistry:ToggleProfiler(enabled)
	self._profileEnabled = enabled == true
	log("UI Profiler " .. (self._profileEnabled and "enabled" or "disabled"))
	return true
end

-- Get UI statistics
function UIRegistry:GetStats()
	-- Update active count by checking instances
	local activeCount = 0
	for _, instance in pairs(self._instances) do
		if instance and instance.Parent then
			activeCount += 1
		end
	end
	
	self._stats.activeCount = activeCount
	
	return {
		version = self._version,
		componentsCount = 0, -- Calculated below
		templatesCount = 0, -- Calculated below
		factoriesCount = 0, -- Calculated below
		activeCount = self._stats.activeCount,
		createdCount = self._stats.createdCount,
		destroyedCount = self._stats.destroyedCount
	}
end

-- Get the UIRegistry version
function UIRegistry:GetVersion()
	return self._version
end

-- Initialize the UI registry
UIRegistry:Initialize()

-- Register with ModuleLoader if available
local moduleLoader = getModuleLoader()
if moduleLoader then
	moduleLoader:RegisterPath("UIRegistry", "ReplicatedStorage.shared.UIRegistry")
	log("Registered with ModuleLoader")
end

return UIRegistry
