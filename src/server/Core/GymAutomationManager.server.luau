--[[
    GymAutomationManager.server.luau
    
    Improved GymAutomation manager to ensure global functions are properly registered
    and system dependencies are correctly loaded. This script addresses the issues
    from RobloxIssues.txt regarding _G function access problems.
    
    Created: April 27, 2025
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    ENABLE_GLOBAL_FUNCTIONS = true,
    DEFAULT_TIMEOUT = 5, -- seconds
    AUTO_REGISTER_WITH_REGISTRY = true
}

-- State tracking for registrations and system health
local SYSTEM_STATE = {
    globalFunctionsRegistered = false,
    coreSystems = {},
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
    },
    missingSystems = {}
}

-- Only run in Studio
if not RunService:IsStudio() then
    if CONFIG.DEBUG_LOGGING then
        print("[GymAutomationManager] Running in production environment, automation disabled")
    end
    return
end

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[GymAutomationManager] " .. message)
    end
end

-- Error logging
local function warn_log(message)
    warn("[GymAutomationManager] " .. message)
end

-- Find or load SafeRequire module from our new module loading system
local SafeRequire
do
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("SafeRequire") then
        local success, result = pcall(function()
            return require(shared.SafeRequire)
        end)
        
        if success and result then
            SafeRequire = result
            log("SafeRequire loaded successfully")
        else
            warn_log("Failed to load SafeRequire module: " .. tostring(result))
        end
    end
    
    -- Create minimal implementation if not found
    if not SafeRequire then
        SafeRequire = {
            require = function(module, fallback)
                if not module then return fallback end
                
                local success, result = pcall(function()
                    return require(module)
                end)
                
                if success then
                    return result
                else
                    warn_log("Failed to require module: " .. tostring(result))
                    return fallback
                end
            end
        }
        log("Created minimal SafeRequire implementation")
    end
end

-- Find or load SafeWaitForChild module from our new module loading system
local SafeWaitForChild
do
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("SafeWaitForChild") then
        local success, result = pcall(function()
            return require(shared.SafeWaitForChild)
        end)
        
        if success and result then
            SafeWaitForChild = result
            log("SafeWaitForChild loaded successfully")
        else
            warn_log("Failed to load SafeWaitForChild module: " .. tostring(result))
        end
    end
    
    -- Create minimal implementation if not found
    if not SafeWaitForChild then
        SafeWaitForChild = {
            waitForChild = function(parent, childName, timeout)
                if not parent then return nil end
                timeout = timeout or CONFIG.DEFAULT_TIMEOUT
                
                -- Check if child already exists
                local child = parent:FindFirstChild(childName)
                if child then return child end
                
                -- Try to wait for it
                local startTime = os.clock()
                
                while os.clock() - startTime < timeout do
                    child = parent:FindFirstChild(childName)
                    if child then return child end
                    task.wait(0.1)
                end
                
                warn_log("Timed out waiting for " .. childName .. " in " .. parent:GetFullName())
                return nil
            end,
            
            waitForDescendant = function(parent, path, timeout)
                if not parent or not path then return nil end
                timeout = timeout or CONFIG.DEFAULT_TIMEOUT
                
                -- Split path
                local segments = string.split(path, ".")
                
                -- Navigate through path
                local current = parent
                for i, segment in ipairs(segments) do
                    current = SafeWaitForChild.waitForChild(current, segment, timeout/#segments)
                    if not current then
                        return nil
                    end
                end
                
                return current
            end
        }
        log("Created minimal SafeWaitForChild implementation")
    end
end

-- Find CoreRegistry (with multiple strategies)
local CoreRegistry
do
    -- Strategy 1: Check global scope (_G)
    if _G and _G.CoreRegistry then
        CoreRegistry = _G.CoreRegistry
        log("CoreRegistry found in global scope")
    end
    
    -- Strategy 2: Use ModuleLoaderHelper
    if not CoreRegistry then
        local shared = ReplicatedStorage:FindFirstChild("shared")
        if shared and shared:FindFirstChild("ModuleLoaderHelper") then
            local ModuleLoaderHelper = SafeRequire.require(shared.ModuleLoaderHelper)
            if ModuleLoaderHelper and ModuleLoaderHelper.GetCoreRegistry then
                CoreRegistry = ModuleLoaderHelper.GetCoreRegistry()
                if CoreRegistry then
                    log("CoreRegistry found via ModuleLoaderHelper")
                end
            end
        end
    end
    
    -- Strategy 3: Look for CoreRegistry in Core folder
    if not CoreRegistry then
        local core = ServerScriptService:FindFirstChild("Core")
        if core and core:FindFirstChild("CoreRegistry") then
            CoreRegistry = SafeRequire.require(core.CoreRegistry)
            if CoreRegistry then
                log("CoreRegistry found in ServerScriptService.Core")
            end
        end
    end
    
    -- Strategy 4: Look in src/server/Core
    if not CoreRegistry then
        local srcServerCore = ServerScriptService:FindFirstChild("src") and 
                             ServerScriptService.src:FindFirstChild("server") and 
                             ServerScriptService.src.server:FindFirstChild("Core")
                             
        if srcServerCore and srcServerCore:FindFirstChild("CoreRegistry") then
            CoreRegistry = SafeRequire.require(srcServerCore.CoreRegistry)
            if CoreRegistry then
                log("CoreRegistry found in src/server/Core")
            end
        end
    end
    
    -- Log the result
    if not CoreRegistry then
        warn_log("CoreRegistry not found, some features will be limited")
    end
end

-- Find all the required systems using CoreRegistry or direct requires
local function loadCoreSystems()
    log("Loading core systems...")
    
    local coreSystems = {}
    local missingCount = 0
    
    -- First, try to get systems from CoreRegistry
    if CoreRegistry and CoreRegistry.getSystem then
        for _, systemName in ipairs(SYSTEM_STATE.requiredSystems) do
            local system = CoreRegistry.getSystem(systemName)
            if system then
                coreSystems[systemName] = system
                log("Loaded " .. systemName .. " from CoreRegistry")
            else
                table.insert(SYSTEM_STATE.missingSystems, systemName)
                missingCount = missingCount + 1
                warn_log("System not found in CoreRegistry: " .. systemName)
            end
        end
        
        -- Also load optional systems
        for _, systemName in ipairs(SYSTEM_STATE.optionalSystems) do
            local system = CoreRegistry.getSystem(systemName)
            if system then
                coreSystems[systemName] = system
                log("Loaded optional system: " .. systemName)
            end
        end
    end
    
    -- Next, try direct requires for any missing systems
    if missingCount > 0 then
        log("Attempting to find missing systems via direct require...")
        
        -- Define potential locations to search
        local searchLocations = {
            ServerScriptService:FindFirstChild("Core"),
            ServerScriptService:FindFirstChild("Systems"),
            ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and 
                ServerScriptService.src.server:FindFirstChild("Core")
        }
        
        -- Search each location for missing systems
        for _, missingSystem in ipairs(SYSTEM_STATE.missingSystems) do
            for _, location in ipairs(searchLocations) do
                if location and location:FindFirstChild(missingSystem) then
                    local system = SafeRequire.require(location[missingSystem])
                    if system then
                        coreSystems[missingSystem] = system
                        log("Loaded " .. missingSystem .. " via direct require")
                        
                        -- Remove from missing list
                        for i, name in ipairs(SYSTEM_STATE.missingSystems) do
                            if name == missingSystem then
                                table.remove(SYSTEM_STATE.missingSystems, i)
                                break
                            end
                        end
                        
                        -- Register with CoreRegistry if available
                        if CoreRegistry and CoreRegistry.registerSystem and CONFIG.AUTO_REGISTER_WITH_REGISTRY then
                            CoreRegistry.registerSystem(missingSystem, system, {})
                            log("Auto-registered " .. missingSystem .. " with CoreRegistry")
                        end
                        
                        break
                    end
                end
            end
        end
    end
    
    -- Store loaded systems
    SYSTEM_STATE.coreSystems = coreSystems
    
    -- Report final status
    if #SYSTEM_STATE.missingSystems > 0 then
        warn_log("Missing " .. #SYSTEM_STATE.missingSystems .. " required systems: " .. 
                table.concat(SYSTEM_STATE.missingSystems, ", "))
        return false
    else
        log("Successfully loaded all required systems")
        return true
    end
end

-- Main GymAutomation module
local GymAutomation = {
    -- Track instance state
    instanceState = {
        hitboxesVisible = false
    }
}

-- Core function to find gym parts in the workspace
function GymAutomation:FindGymParts()
    local gymParts = {}
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and (child.Name == "GymParts" or child.Name == "Gym" or 
           child.Name == "Tycoon" or child.Name == "GymTycoon" or 
           child:GetAttribute("IsGym") or child:GetAttribute("IsTycoon")) then
            table.insert(gymParts, child)
        end
    end
    return gymParts
end

-- Get a specific tycoon by name or the first one found
function GymAutomation:GetTycoon(tycoonName)
    if tycoonName then
        return Workspace:FindFirstChild(tycoonName)
    else
        local gymParts = self:FindGymParts()
        if #gymParts > 0 then
            return gymParts[1]
        end
    end
    return nil
end

-- Main automation function
function GymAutomation:AutomateGym(tycoonName, options)
    options = options or {}
    
    log("Starting gym automation...")
    
    -- Get the tycoon model
    local tycoon = self:GetTycoon(tycoonName)
    if not tycoon then
        warn_log("Gym tycoon not found. Please ensure a gym model exists in the workspace.")
        return false
    end
    
    log("Automating gym: " .. tycoon.Name)
    
    -- Check if we have all required systems
    local FloorAttributeSetup = SYSTEM_STATE.coreSystems["FloorAttributeSetup"]
    local BuyTileProgressionManager = SYSTEM_STATE.coreSystems["BuyTileProgressionManager"]
    local TileDataGenerator = SYSTEM_STATE.coreSystems["TileDataGenerator"]
    local BoundingBoxManager = SYSTEM_STATE.coreSystems["BoundingBoxManager"]
    local EquipmentManager = SYSTEM_STATE.coreSystems["EquipmentManager"]
    
    if not FloorAttributeSetup or not BuyTileProgressionManager or not TileDataGenerator then
        warn_log("Missing required systems to automate gym")
        return false
    end
    
    -- Run setup steps in sequence
    if FloorAttributeSetup then
        log("Setting up floor attributes...")
        FloorAttributeSetup:ProcessTycoon(tycoon)
    end
    
    if TileDataGenerator then
        log("Generating tile data...")
        TileDataGenerator:GenerateTileData(tycoon)
    end
    
    if BuyTileProgressionManager then
        log("Setting up buy tile progression...")
        BuyTileProgressionManager:SetupProgression(tycoon)
    end
    
    if BoundingBoxManager then
        log("Setting up bounding boxes...")
        BoundingBoxManager:ProcessModel(tycoon)
    end
    
    if EquipmentManager then
        log("Setting up equipment...")
        EquipmentManager:ProcessAllEquipment(tycoon)
    end
    
    log("Gym automation complete: " .. tycoon.Name)
    return true
end

-- Automate all gyms in the workspace
function GymAutomation:AutomateAllGyms(options)
    local gymParts = self:FindGymParts()
    log("Found " .. #gymParts .. " gyms to automate")
    
    local results = {}
    for i, gym in ipairs(gymParts) do
        log("Automating gym " .. i .. " of " .. #gymParts .. ": " .. gym.Name)
        local success = self:AutomateGym(gym.Name, options)
        table.insert(results, {
            name = gym.Name,
            success = success
        })
    end
    
    log("Completed automation of " .. #gymParts .. " gyms")
    return results
end

-- Show information about a tycoon
function GymAutomation:ShowTycoonInfo(tycoonName)
    local tycoon = self:GetTycoon(tycoonName)
    if not tycoon then
        warn_log("Tycoon not found")
        return nil
    end
    
    local tileCount = 0
    local equipmentCount = 0
    
    for _, desc in ipairs(tycoon:GetDescendants()) do
        if desc:GetAttribute("IsTile") then
            tileCount = tileCount + 1
        end
        if desc:GetAttribute("IsEquipment") then
            equipmentCount = equipmentCount + 1
        end
    end
    
    local info = {
        name = tycoon.Name,
        tileCount = tileCount,
        equipmentCount = equipmentCount
    }
    
    log("--- Tycoon Info: " .. tycoon.Name .. " ---")
    log("Tiles: " .. tileCount)
    log("Equipment: " .. equipmentCount)
    
    return info
end

-- Generate build order for the tycoon
function GymAutomation:GenerateBuildOrder(tycoonName)
    local tycoon = self:GetTycoon(tycoonName)
    if not tycoon then
        warn_log("Tycoon not found")
        return nil
    end
    
    local BuyTileProgressionManager = SYSTEM_STATE.coreSystems["BuyTileProgressionManager"]
    if not BuyTileProgressionManager then
        warn_log("BuyTileProgressionManager not available")
        return nil
    end
    
    local buildOrder = BuyTileProgressionManager:GenerateBuildOrder(tycoon)
    log("Generated build order with " .. #buildOrder .. " steps")
    
    return buildOrder
end

-- Show equipment hitboxes
function GymAutomation:ShowHitboxes(tycoonName)
    local tycoon = self:GetTycoon(tycoonName)
    if not tycoon then
        warn_log("Tycoon not found")
        return false
    end
    
    local BoundingBoxManager = SYSTEM_STATE.coreSystems["BoundingBoxManager"]
    if not BoundingBoxManager then
        warn_log("BoundingBoxManager not available")
        return false
    end
    
    BoundingBoxManager:ShowHitboxes(tycoon)
    self.instanceState.hitboxesVisible = true
    
    log("Showing hitboxes for " .. tycoon.Name)
    return true
end

-- Hide equipment hitboxes
function GymAutomation:HideHitboxes()
    local BoundingBoxManager = SYSTEM_STATE.coreSystems["BoundingBoxManager"]
    if not BoundingBoxManager then
        warn_log("BoundingBoxManager not available")
        return false
    end
    
    BoundingBoxManager:HideAllHitboxes()
    self.instanceState.hitboxesVisible = false
    
    log("Hiding all hitboxes")
    return true
end

-- Process equipment 
function GymAutomation:ProcessEquipment(tycoonName)
    local tycoon = self:GetTycoon(tycoonName)
    if not tycoon then
        warn_log("Tycoon not found")
        return false
    end
    
    local EquipmentManager = SYSTEM_STATE.coreSystems["EquipmentManager"]
    if not EquipmentManager then
        warn_log("EquipmentManager not available")
        return false
    end
    
    log("Processing equipment for " .. tycoon.Name)
    EquipmentManager:ProcessAllEquipment(tycoon)
    
    return true
end

-- Initialize the GymAutomation module
function GymAutomation:Initialize()
    log("Initializing GymAutomation...")
    
    -- Load all required systems
    loadCoreSystems()
    
    -- Register global functions if enabled
    if CONFIG.ENABLE_GLOBAL_FUNCTIONS then
        self:RegisterGlobalFunctions()
    end
    
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.registerSystem and CONFIG.AUTO_REGISTER_WITH_REGISTRY then
        CoreRegistry.registerSystem("GymAutomation", self, {})
        log("Registered with CoreRegistry")
    end
    
    -- Print the banner
    print("\n===========================")
    print("✅ GYM TYCOON AUTOMATION LOADED")
    print("Run _G.AutomateGym() in the Command Bar to automate the gym setup.")
    print("===========================\n")
    
    return true
end

-- Register global functions for Command Bar access
function GymAutomation:RegisterGlobalFunctions()
    -- Avoid duplicate registrations
    if SYSTEM_STATE.globalFunctionsRegistered then
        return
    end
    
    log("Registering global functions...")
    
    -- Main automation functions
    _G.AutomateGym = function(tycoonName, options)
        return GymAutomation:AutomateGym(tycoonName, options)
    end
    
    _G.AutomateAllGyms = function(options)
        return GymAutomation:AutomateAllGyms(options)
    end
    
    _G.ShowTycoonInfo = function(tycoonName)
        return GymAutomation:ShowTycoonInfo(tycoonName)
    end
    
    _G.GenerateBuildOrder = function(tycoonName)
        return GymAutomation:GenerateBuildOrder(tycoonName)
    end
    
    -- Visualization functions
    _G.ShowHitboxes = function(tycoonName)
        return GymAutomation:ShowHitboxes(tycoonName)
    end
    
    _G.HideHitboxes = function()
        return GymAutomation:HideHitboxes()
    end
    
    -- Equipment processing
    _G.ProcessEquipment = function(tycoonName)
        return GymAutomation:ProcessEquipment(tycoonName)
    end
    
    -- Batch processing
    _G.BatchProcessModels = function(options)
        options = options or {}
        log("Starting batch model processing...")
        
        -- Run all the main processing functions in sequence
        local results = {
            automationResults = GymAutomation:AutomateAllGyms(options),
            equipmentProcessed = _G.ProcessEquipment()
        }
        
        log("Batch processing complete")
        return results
    end
    
    -- Log function registrations
    log("Registered global function: _G.AutomateGym(tycoonName, options)")
    log("Registered global function: _G.AutomateAllGyms(options)")
    log("Registered global function: _G.ShowTycoonInfo(tycoonName)")
    log("Registered global function: _G.GenerateBuildOrder(tycoonName)")
    log("Registered global function: _G.ShowHitboxes(tycoonName)")
    log("Registered global function: _G.HideHitboxes()")
    log("Registered global function: _G.ProcessEquipment(tycoonName)")
    log("Registered global function: _G.BatchProcessModels(options)")
    
    SYSTEM_STATE.globalFunctionsRegistered = true
    return true
end

-- Initialize the module
GymAutomation:Initialize()

-- Return the module
return GymAutomation
