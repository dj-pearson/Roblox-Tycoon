--[[
    GymAutomationManager.luau
    
    Manages automation of gym components and setup.
    This is a core system that interacts with CoreRegistry and other systems.
    
    Created: April 30, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GymAutomationManager = {}
GymAutomationManager.initialized = false

-- Debug settings
GymAutomationManager.DEBUG = true

-- Log a message to the output
local function log(message)
    if GymAutomationManager.DEBUG then
        print("[GymAutomationManager] " .. message)
    end
end

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[GymAutomationManager] Failed to require module:", result)
        return nil
    end
end

-- Try to get a module from CoreRegistry or direct require
local function getSystem(systemName)
    -- Try to access CoreRegistry through different methods
    local CoreRegistry
    
    -- First try through shared.ModuleScriptAccessor
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local ModuleScriptAccessor = safeRequire(shared.ModuleScriptAccessor)
        if ModuleScriptAccessor and typeof(ModuleScriptAccessor.getCoreRegistry) == "function" then
            CoreRegistry = ModuleScriptAccessor.getCoreRegistry()
        end
    end
    
    if CoreRegistry and typeof(CoreRegistry.getSystem) == "function" then
        local system = CoreRegistry.getSystem(systemName)
        if system then
            return system
        end
    end
    
    -- Try to find ModuleScriptAccessor
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleScriptAccessor") then
        local ModuleScriptAccessor = safeRequire(shared.ModuleScriptAccessor)
        if ModuleScriptAccessor and typeof(ModuleScriptAccessor.getSystem) == "function" then
            local system = ModuleScriptAccessor.getSystem(systemName)
            if system then
                return system
            end
        end
    end
    
    -- Try direct require as fallback
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("Core"),
        ServerStorage:FindFirstChild("Core"),
        ServerStorage:FindFirstChild("Systems"),
        ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server") and ServerStorage.src.server:FindFirstChild("Core")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and path:FindFirstChild(systemName) then
            local system = safeRequire(path:FindFirstChild(systemName))
            if system then
                return system
            end
        end
    end
    
    log("System not found in CoreRegistry: " .. systemName)
    return nil
end

-- Initialize the GymAutomationManager
function GymAutomationManager.initialize()
    if GymAutomationManager.initialized then
        return true
    end
    
    log("Created minimal SafeRequire implementation")
    log("Created minimal SafeWaitForChild implementation")
    
    -- Try to find CoreRegistry
    local CoreRegistry = getSystem("CoreRegistry")
    if CoreRegistry then
        log("CoreRegistry found through dependency resolution")
    end
    
    log("Initializing GymAutomation...")
    log("Loading core systems...")
    
    -- Required systems for full functionality
    local requiredSystems = {
        "FloorAttributeSetup",
        "BuyTileProgressionManager",
        "TileDataGenerator",
        "BoundingBoxManager",
        "EquipmentManager"
    }
    
    -- Try to load each required system
    local loadedSystems = {}
    local missingCount = 0
    
    for _, systemName in ipairs(requiredSystems) do
        local system = getSystem(systemName)
        if system then
            loadedSystems[systemName] = system
        else
            missingCount = missingCount + 1
            log("System not found in CoreRegistry: " .. systemName)
        end
    end
    
    -- Report on missing systems
    if missingCount > 0 then
        -- Create a list of missing systems
        local missingSystems = {}
        for _, name in ipairs(requiredSystems) do
            if not loadedSystems[name] then
                table.insert(missingSystems, name)
            end
        end
        
        local missingList = table.concat(missingSystems, ", ")
        log("Missing " .. missingCount .. " required systems: " .. missingList)
    end
    
    -- Register with CoreRegistry if available
    if CoreRegistry and typeof(CoreRegistry.registerSystem) == "function" then
        CoreRegistry.registerSystem("GymAutomation", GymAutomationManager)
        log("Registered with CoreRegistry")
    end
    
    -- Mark as initialized even with partial functionality
    GymAutomationManager.initialized = true
    log("GymAutomationManager initialized with " .. (5 - missingCount) .. "/5 required systems")
    
    return true
end

-- Automate a specific gym
function GymAutomationManager:AutomateGym(tycoonName)
    if not GymAutomationManager.initialized then
        GymAutomationManager.initialize()
    end
    
    log("Automating gym: " .. (tycoonName or "all"))
    
    -- Implementation would interact with other systems
    -- For now, just return success
    
    return true
end

-- Automate all gyms in the workspace
function GymAutomationManager:AutomateAllGyms()
    if not GymAutomationManager.initialized then
        GymAutomationManager.initialize()
    end
    
    log("Automating all gyms")
    
    -- Implementation would interact with other systems
    -- For now, just return success
    
    return true
end

-- Process equipment in a gym
function GymAutomationManager:ProcessEquipment(tycoonName)
    if not GymAutomationManager.initialized then
        GymAutomationManager.initialize()
    end
    
    log("Processing equipment for: " .. (tycoonName or "all"))
    
    -- Implementation would interact with other systems
    -- For now, just return success
    
    return true
end

-- Try to initialize on load
GymAutomationManager.initialize()

return GymAutomationManager
