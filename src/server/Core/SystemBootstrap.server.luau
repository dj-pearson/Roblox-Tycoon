-- SystemBootstrap.luau
-- Main entry point for initializing all core systems
-- Place in ServerScriptService/Core

local ServerScriptService = game:GetService("ServerScriptService")
local CoreFolder = ServerScriptService:FindFirstChild("Core")
local ConnectorsFolder = ServerScriptService:FindFirstChild("Connectors")

-- Basic configuration
local CONFIG = {
    debugEnabled = true,
    systemInitTimeout = 10, -- Maximum time to wait for a system to initialize (seconds)
    initRetryCount = 3,     -- Number of times to retry initializing a failed system
    startupDelay = 0        -- Optional delay before initializing systems (seconds)
}

-- Get the CoreRegistry to access all systems
local CoreRegistry = require(CoreFolder:FindFirstChild("CoreRegistry"))

-- Systems to initialize in order (dependencies handled by registry)
local systemsToInitialize = {
    "EventBridge",
    "DataManager", 
    "PerformanceManager", -- Added PerformanceManager early in the initialization process
    "NPCSystem",
    "TycoonSystem",
    "BuyTileSystem",
    "SpecializationSystem",
    "MilestoneSystem",
    "AchievementSystem", 
    "SaunaSystem",
    "RevenueSystem" -- Added RevenueSystem to the initialization list
    -- Additional systems can be added here
}

-- Connectors to initialize after core systems
local connectorsToInitialize = {
    "GymTycoonConnector" -- Bridge between new architecture and legacy code
}

-- Utility functions
local function log(...)
    if CONFIG.debugEnabled then
        print("[SystemBootstrap]", ...)
    end
end

local function warn(...)
    if CONFIG.debugEnabled then
        warn("[SystemBootstrap]", ...)
    end
end

-- Create leaderstats for a player
local function setupLeaderstats(player)
    if not player then return end
    
    -- Check if leaderstats already exists
    if player:FindFirstChild("leaderstats") then
        return
    end
    
    -- Create leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    -- Create Cash value
    local cash = Instance.new("IntValue")
    cash.Name = "Cash"
    cash.Value = 500 -- Starting cash
    cash.Parent = leaderstats
    
    -- Additional stats can be added here
    
    log("Created leaderstats for " .. player.Name)
end

-- Handle when a player joins
local function handlePlayerJoin(player)
    if not player then return end
    
    log("Setting up player: " .. player.Name)
    
    -- Create leaderstats first (if needed)
    setupLeaderstats(player)
    
    -- Ensure player has a tycoon
    local TycoonSystem = CoreRegistry.getSystem("TycoonSystem")
    if TycoonSystem and TycoonSystem.ensurePlayerTycoon then
        task.spawn(function()
            local tycoon = TycoonSystem.ensurePlayerTycoon(player)
            
            if tycoon then
                log("Tycoon ready for " .. player.Name)
            else
                warn("Failed to create tycoon for " .. player.Name)
            end
        end)
    end
    
    -- Additional player setup logic can go here
end

-- Initialize connector modules
local function initializeConnectors()
    if not ConnectorsFolder then
        warn("Connectors folder not found in ServerScriptService")
        return
    end
    
    log("Initializing connector modules...")
    
    -- Track successful initializations
    local initializedCount = 0
    local failedConnectors = {}
    
    for _, connectorName in ipairs(connectorsToInitialize) do
        local connectorScript = ConnectorsFolder:FindFirstChild(connectorName)
        if not connectorScript then
            warn("Connector not found: " .. connectorName)
            table.insert(failedConnectors, connectorName)
            continue
        end
        
        log("Loading connector: " .. connectorName)
        
        -- Try to load and initialize the connector
        local success, connector = pcall(function()
            return require(connectorScript)
        end)
        
        if success and connector then
            -- Try to initialize the connector
            if typeof(connector.initialize) == "function" then
                local initSuccess, result = pcall(function()
                    return connector.initialize()
                end)
                
                if initSuccess and result ~= false then
                    log("Successfully initialized connector: " .. connectorName)
                    initializedCount = initializedCount + 1
                    
                    -- Register with CoreRegistry for other systems to access
                    CoreRegistry.registerSystem(connectorName, connector)
                else
                    warn("Failed to initialize connector: " .. connectorName)
                    table.insert(failedConnectors, connectorName)
                end
            else
                log("Connector has no initialize function: " .. connectorName)
                -- Still register it with CoreRegistry
                CoreRegistry.registerSystem(connectorName, connector)
                initializedCount = initializedCount + 1
            end
        else
            warn("Failed to load connector: " .. connectorName)
            table.insert(failedConnectors, connectorName)
        end
    end
    
    -- Final report
    log("Connectors initialization complete: " .. initializedCount .. " of " .. #connectorsToInitialize .. " connectors initialized")
    
    if #failedConnectors > 0 then
        warn("Failed to initialize " .. #failedConnectors .. " connectors: " .. table.concat(failedConnectors, ", "))
    end
end

-- Tasks to run after all systems are initialized
local function postInitialization()
    log("Running post-initialization tasks...")
    
    -- Connect player joined event
    game:GetService("Players").PlayerAdded:Connect(function(player)
        log("Player joined: " .. player.Name)
        handlePlayerJoin(player)
    end)
    
    -- Handle existing players
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        task.spawn(function()
            handlePlayerJoin(player)
        end)
    end
    
    log("Post-initialization complete")
    log("System bootstrap complete - Ready to play!")
end

-- Main initialization function
local function initializeSystems()
    log("Beginning system initialization...")
    
    if CONFIG.startupDelay > 0 then
        log("Waiting " .. CONFIG.startupDelay .. " seconds before initializing systems...")
        task.wait(CONFIG.startupDelay)
    end
    
    -- Track successful initializations
    local initializedCount = 0
    local failedSystems = {}
    
    for _, systemName in ipairs(systemsToInitialize) do
        local success, retryCount = false, 0
        
        -- Attempt to initialize with retries
        while not success and retryCount < CONFIG.initRetryCount do
            log("Initializing " .. systemName .. (retryCount > 0 and " (retry " .. retryCount .. ")" or ""))
            
            local system = CoreRegistry.getSystem(systemName)
            
            if not system then
                warn("System not found: " .. systemName)
                break
            end
            
            -- Check if the system has already been initialized using CoreRegistry's initialized table
            if CoreRegistry.initialized and CoreRegistry.initialized[systemName] then
                log(systemName .. " was already initialized")
                success = true
                break
            end
            
            -- Attempt initialization with timeout protection
            local initializationComplete = false
            local initSuccess = false
            
            -- Create a separate thread for initialization
            task.spawn(function()
                local result = pcall(function()
                    -- Call system's initialize function if it exists
                    if typeof(system.initialize) == "function" then
                        initSuccess = system.initialize() ~= false
                    else
                        -- Try alternative init method (some systems may use init instead)
                        if typeof(system.init) == "function" then
                            initSuccess = system.init() ~= false
                        else
                            initSuccess = true -- No initialize function means success by default
                        end
                    end
                end)
                
                if not result then
                    initSuccess = false
                end
                
                initializationComplete = true
            end)
            
            -- Wait for initialization with timeout
            local startTime = os.clock()
            while not initializationComplete do
                if os.clock() - startTime > CONFIG.systemInitTimeout then
                    warn("System initialization timed out: " .. systemName)
                    break
                end
                task.wait(0.1)
            end
            
            -- Check result
            if initSuccess then
                success = true
                -- The CoreRegistry should already mark it as initialized if successful
                log("Successfully initialized: " .. systemName)
                initializedCount = initializedCount + 1
            else
                retryCount = retryCount + 1
                warn("Failed to initialize: " .. systemName .. (retryCount < CONFIG.initRetryCount and ", will retry" or ""))
                task.wait(1) -- Wait before retry
            end
        end
        
        -- Track failed systems
        if not success then
            table.insert(failedSystems, systemName)
        end
    end
    
    -- Final report
    log("Core systems initialization complete: " .. initializedCount .. " of " .. #systemsToInitialize .. " systems initialized")
    
    if #failedSystems > 0 then
        warn("Failed to initialize " .. #failedSystems .. " systems: " .. table.concat(failedSystems, ", "))
    end
    
    -- Initialize connectors after core systems
    initializeConnectors()
    
    -- Begin post-initialization tasks
    task.spawn(postInitialization)
end

-- Start the initialization process
task.spawn(function()
    initializeSystems()
end)

-- Return the bootstrap module
return {
    reInitialize = initializeSystems
}