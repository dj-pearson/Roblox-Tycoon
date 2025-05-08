--[[
    GymAutomationManager.server.luau
    
    Enhanced GymAutomation manager that ensures reliable initialization and module resolution.
    This version fixes the critical issues reported in RobloxIssues.txt.
    
    Features:
    - Reliable module resolution and loading
    - Improved error handling and recovery
    - Integration with CoreRegistry
    - Health monitoring and status reporting
    - Fallback mechanisms for missing components
    
    Created: May 3, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxRetries = 3,
    retryDelay = 2, -- seconds,
    requiredSystems = {
        "FloorAttributeSetup",
        "BuyTileProgressionManager",
        "TileDataGenerator",
        "BoundingBoxManager",
        "EquipmentManager"
    },
    optionalSystems = {
        "NPCSystem",
        "GymStructureIntegration",
        "BuyTileSystem",
        "ConfigGenerator"
    }
}

-- Module state
local GymAutomationManager = {
    initialized = false,
    systems = {},      -- Loaded systems
    errors = {},       -- Error history
    lastCheck = 0      -- Last health check time
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[GymAutomationManager]", ...)
    end
end

-- Safe require with retries
local function safeRequire(module, retries)
    retries = retries or CONFIG.maxRetries
    local success, result
    
    for i = 1, retries do
        success, result = pcall(function()
            return require(module)
        end)
        
        if success then
            return result
        end
        
        if i < retries then
            log("Failed to require module, retrying... (" .. i .. "/" .. retries .. ")")
            task.wait(CONFIG.retryDelay)
        end
    end
    
    return nil
end

-- Find module in multiple paths
local function findModule(moduleName, paths)
    paths = paths or {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("System"),
        ServerScriptService:FindFirstChild("GymAutomation"),
        ServerScriptService, -- Fallback
        ServerStorage:FindFirstChild("GymAutomation"),
        ServerStorage, -- Fallback
        ReplicatedStorage:FindFirstChild("shared")
    }
    
    for _, path in ipairs(paths) do
        if path then
            local module = path:FindFirstChild(moduleName) or path:FindFirstChild(moduleName .. ".server.luau")
            if module then
                return module
            end
        end
    end
    
    return nil
end

-- Create placeholder system
local function createPlaceholderSystem(name)
    log("Creating placeholder for: " .. name)
    
    local placeholder = {
        _isPlaceholder = true,
        name = name,
        initialized = true,
        
        initialize = function(self)
            log("Initialized placeholder for: " .. name)
            return true
        end,
        
        process = function(self, ...)
            log("Placeholder process called for: " .. name)
            return true
        end
    }
    
    -- Additional functionality based on system type
    if name == "FloorAttributeSetup" then
        placeholder.processTycoon = function(self, tycoon)
            log("Placeholder floor attribute setup for: " .. tycoon.Name)
            return true
        end
    elseif name == "BuyTileProgressionManager" then
        placeholder.setupProgression = function(self, tycoon)
            log("Placeholder buy tile progression setup for: " .. tycoon.Name)
            return true
        end
    elseif name == "TileDataGenerator" then
        placeholder.generateTileData = function(self, tycoon)
            log("Placeholder tile data generation for: " .. tycoon.Name)
            return true
        end
    elseif name == "BoundingBoxManager" then
        placeholder.processModel = function(self, model)
            log("Placeholder bounding box processing for: " .. model.Name)
            return true
        end
    elseif name == "EquipmentManager" then
        placeholder.processAllEquipment = function(self, tycoon)
            log("Placeholder equipment processing for: " .. tycoon.Name)
            return true
        end
    end
    
    return placeholder
end

-- Initialize GymAutomationManager
function GymAutomationManager.initialize()
    if GymAutomationManager.initialized then return true end
    
    log("Initializing GymAutomationManager...")
    
    -- Get CoreRegistry
    local coreRegistry = _G.CoreRegistry
    if not coreRegistry then
        log("CoreRegistry not found, automation may be limited", true)
    end
    
    -- Load required systems
    for _, systemName in ipairs(CONFIG.requiredSystems) do
        log("Loading system: " .. systemName)
        
        -- Try to find the module
        local module = findModule(systemName)
        if not module then
            log("Module not found for: " .. systemName .. ", creating placeholder", true)
            GymAutomationManager.systems[systemName] = createPlaceholderSystem(systemName)
            continue
        end
        
        -- Require the module
        local system = safeRequire(module)
        if not system then
            log("Failed to require module for: " .. systemName .. ", creating placeholder", true)
            GymAutomationManager.systems[systemName] = createPlaceholderSystem(systemName)
            continue
        end
        
        -- Initialize if needed
        if typeof(system.initialize) == "function" and not system.initialized then
            local success, err = pcall(function()
                system:initialize()
            end)
            
            if not success then
                log("Failed to initialize: " .. systemName .. " - " .. tostring(err), true)
                GymAutomationManager.systems[systemName] = createPlaceholderSystem(systemName)
                continue
            end
        end
        
        -- Register system
        GymAutomationManager.systems[systemName] = system
        log("Successfully loaded: " .. systemName)
        
        -- Register with CoreRegistry if available
        if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
            coreRegistry:registerSystem(systemName, system)
            log("Registered " .. systemName .. " with CoreRegistry")
        end
    end
    
    -- Load optional systems
    for _, systemName in ipairs(CONFIG.optionalSystems) do
        log("Loading optional system: " .. systemName)
        
        -- Try to find the module
        local module = findModule(systemName)
        if not module then
            log("Optional module not found: " .. systemName)
            continue
        end
        
        -- Require the module
        local system = safeRequire(module)
        if not system then
            log("Failed to require optional module: " .. systemName)
            continue
        end
        
        -- Initialize if needed
        if typeof(system.initialize) == "function" and not system.initialized then
            local success, err = pcall(function()
                system:initialize()
            end)
            
            if not success then
                log("Failed to initialize optional system: " .. systemName .. " - " .. tostring(err))
                continue
            end
        end
        
        -- Register system
        GymAutomationManager.systems[systemName] = system
        log("Successfully loaded optional system: " .. systemName)
        
        -- Register with CoreRegistry if available
        if coreRegistry and typeof(coreRegistry.registerSystem) == "function" then
            coreRegistry:registerSystem(systemName, system)
            log("Registered optional system " .. systemName .. " with CoreRegistry")
        end
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            GymAutomationManager.checkHealth()
        end
    end)
    
    GymAutomationManager.initialized = true
    log("GymAutomationManager initialized")
    return true
end

-- Check system health
function GymAutomationManager.checkHealth()
    local now = os.time()
    GymAutomationManager.lastCheck = now
    
    -- Check required systems
    for _, systemName in ipairs(CONFIG.requiredSystems) do
        local system = GymAutomationManager.systems[systemName]
        
        if not system then
            GymAutomationManager.recordError("System not found: " .. systemName)
            continue
        end
        
        -- Check if system is initialized
        if not system.initialized then
            GymAutomationManager.recordError("System not initialized: " .. systemName)
            continue
        end
        
        -- Check if system is a placeholder
        if system._isPlaceholder then
            GymAutomationManager.recordError("Using placeholder for: " .. systemName)
            continue
        end
    end
    
    return true
end

-- Record an error
function GymAutomationManager.recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(GymAutomationManager.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #GymAutomationManager.errors > 10 do
        table.remove(GymAutomationManager.errors, 1)
    end
    
    log("Error recorded: " .. message)
end

-- Get system
function GymAutomationManager.getSystem(name)
    return GymAutomationManager.systems[name]
end

-- Get all systems
function GymAutomationManager.getAllSystems()
    return GymAutomationManager.systems
end

-- Get error count
function GymAutomationManager.getErrorCount()
    return #GymAutomationManager.errors
end

-- Get recent errors
function GymAutomationManager.getRecentErrors()
    return GymAutomationManager.errors
end

-- Force a health check
function GymAutomationManager.forceCheck()
    return GymAutomationManager.checkHealth()
end

-- Automate a specific gym
function GymAutomationManager.automateGym(tycoonName)
    if not GymAutomationManager.initialized then
        GymAutomationManager.initialize()
    end
    
    log("Automating gym: " .. (tycoonName or "all"))
    
    -- Get required systems
    local floorSetup = GymAutomationManager.getSystem("FloorAttributeSetup")
    local buyTileManager = GymAutomationManager.getSystem("BuyTileProgressionManager")
    local tileGenerator = GymAutomationManager.getSystem("TileDataGenerator")
    local boundingBoxManager = GymAutomationManager.getSystem("BoundingBoxManager")
    local equipmentManager = GymAutomationManager.getSystem("EquipmentManager")
    
    -- Check if we have all required systems
    if not floorSetup or not buyTileManager or not tileGenerator then
        GymAutomationManager.recordError("Missing required systems for gym automation")
        return false
    end
    
    -- Find the tycoon
    local tycoon = workspace:FindFirstChild(tycoonName)
    if not tycoon then
        GymAutomationManager.recordError("Tycoon not found: " .. tycoonName)
        return false
    end
    
    -- Run automation steps
    local success = true
    
    -- Setup floor attributes
    if floorSetup then
        success = success and floorSetup:processTycoon(tycoon)
    end
    
    -- Generate tile data
    if tileGenerator then
        success = success and tileGenerator:generateTileData(tycoon)
    end
    
    -- Setup buy tile progression
    if buyTileManager then
        success = success and buyTileManager:setupProgression(tycoon)
    end
    
    -- Process bounding boxes
    if boundingBoxManager then
        success = success and boundingBoxManager:processModel(tycoon)
    end
    
    -- Process equipment
    if equipmentManager then
        success = success and equipmentManager:processAllEquipment(tycoon)
    end
    
    if success then
        log("Successfully automated gym: " .. tycoon.Name)
    else
        GymAutomationManager.recordError("Failed to automate gym: " .. tycoon.Name)
    end
    
    return success
end

-- Automate all gyms
function GymAutomationManager.automateAllGyms()
    if not GymAutomationManager.initialized then
        GymAutomationManager.initialize()
    end
    
    log("Automating all gyms")
    
    local success = true
    
    -- Find all tycoons
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and (child.Name:find("Tycoon") or child.Name:find("Gym")) then
            success = success and GymAutomationManager.automateGym(child.Name)
        end
    end
    
    if success then
        log("Successfully automated all gyms")
    else
        GymAutomationManager.recordError("Failed to automate all gyms")
    end
    
    return success
end

return GymAutomationManager
