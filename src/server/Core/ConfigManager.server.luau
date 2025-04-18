-- ConfigManager.server.luau
-- Centralized configuration management system
-- Part of the Performance Optimization Framework

local HttpService = game:GetService("HttpService")

-- Get the CoreRegistry and dependencies
local CoreRegistry = require(script.Parent.CoreRegistry)

-- Default configuration
local DEFAULT_CONFIG = {
    -- Core system settings
    core = {
        debug = true,
        announceInitialization = true,
    },
    
    -- Performance settings
    performance = {
        -- Detail levels
        detailLevels = {
            "High",                -- Full detail, all features enabled
            "Medium",              -- Reduced particle effects, fewer ambient sounds
            "Low",                 -- Minimal visual effects, reduced update frequency
            "Minimal"              -- Only essential systems running, bare minimum visuals
        },
        defaultDetailLevel = "High",
        autoAdjustDetailLevel = true,
        
        -- Thresholds
        minAcceptableFrameRate = 30,
        maxMemoryUsageMB = 3000,
        
        -- Updating frequencies (in seconds)
        npcUpdateInterval = 1.0,
        revenueUpdateInterval = 30.0,
        memberUpdateInterval = 5.0,
        satisfactionUpdateInterval = 10.0,
    },
    
    -- Task scheduling settings
    taskScheduler = {
        taskDistributionTicks = 4,
        taskBatchSize = 5,
    },
    
    -- Object pooling settings
    pooling = {
        initialPoolSizes = {
            NPCs = 20,
            Effects = 15,
            Basketballs = 5,
        },
        growSizes = {
            NPCs = 5,
            Effects = 5,
            Basketballs = 2,
        },
        maxPoolSizes = {
            NPCs = 100,
            Effects = 50,
            Basketballs = 10,
        },
    },
    
    -- Distance-based optimization settings
    distanceOptimization = {
        cullingDistances = {
            NPCs = 150,
            Effects = 100,
            DetailProps = 75,
            Sounds = 50,
        },
        updateFrequencies = {
            close = 1,      -- Update every frame
            medium = 2,     -- Update every 2 frames
            far = 4,        -- Update every 4 frames
            veryFar = 8,    -- Update every 8 frames
        },
    },
    
    -- Effect quality settings by detail level
    effectQuality = {
        High = {
            particleDensity = 1.0,
            maxParticles = 2000,
            shadows = true,
            lighting = true,
            ambientSounds = true,
        },
        Medium = {
            particleDensity = 0.7,
            maxParticles = 1000,
            shadows = true,
            lighting = true,
            ambientSounds = true,
        },
        Low = {
            particleDensity = 0.4,
            maxParticles = 500,
            shadows = false,
            lighting = true,
            ambientSounds = false,
        },
        Minimal = {
            particleDensity = 0.2,
            maxParticles = 200,
            shadows = false,
            lighting = false,
            ambientSounds = false,
        },
    },
    
    -- Memory store settings
    memoryStore = {
        enabled = true,
        useFallback = true,
        expirationTimes = {
            player_session = 3600,
            system_state = 7200,
            game_metrics = 86400,
            temp_effects = 300,
            cooldowns = 1800,
        },
    },
    
    -- System-specific settings
    systems = {
        NPCSystem = {
            maxNPCsPerTycoon = 20,
            staggerUpdates = true,
            updateGroupCount = 4,
            usePooling = true,
        },
        
        RevenueSystem = {
            staggerUpdates = true,
            simulateDetailedEconomy = true,
        },
        
        BasketballSystem = {
            maxBalls = 3,
            usePooling = true,
            optimizePhysics = true,
        },
    },
}

-- Module table
local ConfigManager = {
    Name = "ConfigManager",
    Dependencies = {
        "CoreRegistry"
    },
    
    -- Internal state
    _config = {},                    -- Current configuration
    _defaultConfig = DEFAULT_CONFIG, -- Default configuration
    _listeners = {},                 -- Config change listeners
    _initialized = false             -- Whether the system is initialized
}

-- Debug function
local function debugPrint(...)
    if ConfigManager._config.core and ConfigManager._config.core.debug then
        print("[ConfigManager]", ...)
    end
end

--[[ Configuration Management ]]--

-- Get a configuration value
function ConfigManager:getValue(path, default)
    -- Tokenize the path (e.g. "performance.detailLevels")
    local tokens = {}
    for token in string.gmatch(path, "[^.]+") do
        table.insert(tokens, token)
    end
    
    -- Navigate the config table
    local currentTable = self._config
    for i = 1, #tokens - 1 do
        local token = tokens[i]
        if type(currentTable[token]) ~= "table" then
            return default
        end
        currentTable = currentTable[token]
    end
    
    -- Return the value or default
    local value = currentTable[tokens[#tokens]]
    if value == nil then
        return default
    end
    
    return value
end

-- Set a configuration value
function ConfigManager:setValue(path, value)
    -- Tokenize the path (e.g. "performance.detailLevels")
    local tokens = {}
    for token in string.gmatch(path, "[^.]+") do
        table.insert(tokens, token)
    end
    
    -- Navigate the config table
    local currentTable = self._config
    for i = 1, #tokens - 1 do
        local token = tokens[i]
        if type(currentTable[token]) ~= "table" then
            currentTable[token] = {}
        end
        currentTable = currentTable[token]
    end
    
    -- Set the value
    local lastToken = tokens[#tokens]
    local oldValue = currentTable[lastToken]
    currentTable[lastToken] = value
    
    -- Notify listeners if the value changed
    if oldValue ~= value then
        self:notifyListeners(path, value, oldValue)
    end
    
    return true
end

-- Reset a configuration value to default
function ConfigManager:resetValue(path)
    -- Tokenize the path (e.g. "performance.detailLevels")
    local tokens = {}
    for token in string.gmatch(path, "[^.]+") do
        table.insert(tokens, token)
    end
    
    -- Navigate the default config table
    local defaultTable = self._defaultConfig
    for i = 1, #tokens - 1 do
        local token = tokens[i]
        if type(defaultTable[token]) ~= "table" then
            -- No default value
            return false
        end
        defaultTable = defaultTable[token]
    end
    
    -- Get the default value
    local lastToken = tokens[#tokens]
    local defaultValue = defaultTable[lastToken]
    
    -- Set to default value
    return self:setValue(path, defaultValue)
end

-- Get the entire configuration
function ConfigManager:getConfig()
    -- Return a deep copy to prevent modification
    return self:deepCopy(self._config)
end

-- Set the entire configuration
function ConfigManager:setConfig(config)
    -- Create a deep copy to prevent external modification
    local newConfig = self:deepCopy(config)
    
    -- Store old config for change detection
    local oldConfig = self._config
    
    -- Set the new config
    self._config = newConfig
    
    -- Notify listeners about all changes
    self:notifyAllListeners(newConfig, oldConfig)
    
    return true
end

-- Reset entire configuration to defaults
function ConfigManager:resetConfig()
    return self:setConfig(self._defaultConfig)
end

--[[ Configuration Change Listeners ]]--

-- Add a listener for configuration changes
function ConfigManager:addListener(path, callback)
    if not self._listeners[path] then
        self._listeners[path] = {}
    end
    
    local listenerId = HttpService:GenerateGUID(false)
    self._listeners[path][listenerId] = callback
    
    return listenerId
end

-- Remove a configuration change listener
function ConfigManager:removeListener(path, listenerId)
    if self._listeners[path] and self._listeners[path][listenerId] then
        self._listeners[path][listenerId] = nil
        return true
    end
    
    return false
end

-- Notify listeners about a configuration change
function ConfigManager:notifyListeners(path, newValue, oldValue)
    -- Notify exact path listeners
    if self._listeners[path] then
        for _, callback in pairs(self._listeners[path]) do
            task.spawn(function()
                callback(path, newValue, oldValue)
            end)
        end
    end
    
    -- Notify wildcard listeners
    if self._listeners["*"] then
        for _, callback in pairs(self._listeners["*"]) do
            task.spawn(function()
                callback(path, newValue, oldValue)
            end)
        end
    end
end

-- Notify all listeners about all changes
function ConfigManager:notifyAllListeners(newConfig, oldConfig)
    -- Note: This is a simplified implementation that doesn't detect nested changes
    for category, values in pairs(newConfig) do
        if type(values) == "table" then
            for key, value in pairs(values) do
                local path = category .. "." .. key
                local oldValue = oldConfig[category] and oldConfig[category][key]
                
                if value ~= oldValue then
                    self:notifyListeners(path, value, oldValue)
                end
            end
        else
            -- Top-level value
            local oldValue = oldConfig[category]
            if values ~= oldValue then
                self:notifyListeners(category, values, oldValue)
            end
        end
    end
end

--[[ Helper Functions ]]--

-- Deep copy a table
function ConfigManager:deepCopy(original)
    local copy = {}
    
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = self:deepCopy(value)
        else
            copy[key] = value
        end
    end
    
    return copy
end

-- Save the configuration to a file
function ConfigManager:saveToFile(path)
    local success, result = pcall(function()
        local json = HttpService:JSONEncode(self._config)
        
        -- Write to file
        local file = io.open(path, "w")
        if file then
            file:write(json)
            file:close()
            return true
        end
        return false
    end)
    
    if success then
        debugPrint("Configuration saved to file:", path)
        return result
    else
        warn("Failed to save configuration:", result)
        return false
    end
end

-- Load the configuration from a file
function ConfigManager:loadFromFile(path)
    local success, result = pcall(function()
        -- Read from file
        local file = io.open(path, "r")
        if file then
            local content = file:read("*all")
            file:close()
            
            if content and #content > 0 then
                local config = HttpService:JSONDecode(content)
                self:setConfig(config)
                return true
            end
        end
        return false
    end)
    
    if success then
        if result then
            debugPrint("Configuration loaded from file:", path)
        else
            debugPrint("No configuration file found, using defaults")
            -- Reset to defaults if file not found
            self:resetConfig()
        end
        return result
    else
        warn("Failed to load configuration:", result)
        -- Reset to defaults if loading failed
        self:resetConfig()
        return false
    end
end

--[[ Initialization and Core Functions ]]--

-- Initialize the ConfigManager
function ConfigManager:initialize()
    if self._initialized then
        return true
    end
    
    debugPrint("Initializing ConfigManager...")
    
    -- Set default configuration
    self:resetConfig()
    
    -- Try to load from file
    local configPath = "config.json"
    self:loadFromFile(configPath)
    
    self._initialized = true
    debugPrint("ConfigManager initialized")
    return true
end

-- Stop the ConfigManager
function ConfigManager:shutdown()
    -- Save configuration
    local configPath = "config.json"
    self:saveToFile(configPath)
    
    -- Clear listeners
    self._listeners = {}
    
    self._initialized = false
    debugPrint("ConfigManager shut down")
    return true
end

-- Create public API
local PublicAPI = {
    -- Configuration values
    getValue = function(path, default)
        return ConfigManager:getValue(path, default)
    end,
    
    setValue = function(path, value)
        return ConfigManager:setValue(path, value)
    end,
    
    resetValue = function(path)
        return ConfigManager:resetValue(path)
    end,
    
    -- Full configuration
    getConfig = function()
        return ConfigManager:getConfig()
    end,
    
    setConfig = function(config)
        return ConfigManager:setConfig(config)
    end,
    
    resetConfig = function()
        return ConfigManager:resetConfig()
    end,
    
    -- Listeners
    addListener = function(path, callback)
        return ConfigManager:addListener(path, callback)
    end,
    
    removeListener = function(path, listenerId)
        return ConfigManager:removeListener(path, listenerId)
    end,
    
    -- File operations
    saveToFile = function(path)
        return ConfigManager:saveToFile(path)
    end,
    
    loadFromFile = function(path)
        return ConfigManager:loadFromFile(path)
    end,
}

-- Initialize the system
ConfigManager:initialize()

-- Register with CoreRegistry
if CoreRegistry.registerSystem then
    CoreRegistry.registerSystem("ConfigManager", PublicAPI)
end

return PublicAPI