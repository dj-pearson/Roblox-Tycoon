--[[
    GymAutomation.luau
    Core automation module for gym facilities and equipment
    
    This module handles automatic operations of gym facilities, equipment servicing,
    and member interactions throughout the gym.
    
    Created: April 28, 2025
]]

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Module
local GymAutomation = {}

-- Constants
GymAutomation.VERSION = "1.0.0"
GymAutomation.DEBUG = true

-- Private variables
local initialized = false
local autoCleanInterval = 300 -- 5 minutes
local equipmentCheckInterval = 600 -- 10 minutes
local registeredEquipment = {}
local activeCleaningTasks = {}
local activeMaintenanceTasks = {}

-- Private functions
local function log(message, level)
    level = level or "Info"
    if not GymAutomation.DEBUG and level == "Debug" then return end
    
    print("[GymAutomation] " .. message)
end

local function findCoreRegistry()
    -- Try global access first
    if _G.CoreRegistry then
        return _G.CoreRegistry
    end
    
    -- Try common paths
    local serverScriptService = game:GetService("ServerScriptService")
    local coreFolder = serverScriptService:FindFirstChild("Core") or serverScriptService:FindFirstChild("Server")
    local registryModule = coreFolder and coreFolder:FindFirstChild("CoreRegistry")
    
    if registryModule and registryModule:IsA("ModuleScript") then
        local success, registry = pcall(function() 
            return require(registryModule)
        end)
        
        if success then
            return registry
        end
    end
    
    return nil
end

-- Initialization
function GymAutomation:initialize()
    if initialized then
        log("GymAutomation already initialized")
        return self
    end
    
    log("Initializing GymAutomation system...")
    
    -- Try to register with CoreRegistry if available
    local coreRegistry = findCoreRegistry()
    if coreRegistry then
        log("Registering with CoreRegistry...")
        if coreRegistry.registerSystem then
            coreRegistry.registerSystem("GymAutomation", self)
            log("Successfully registered with CoreRegistry")
        else
            log("CoreRegistry missing registerSystem method", "Warning")
        end
    else
        log("CoreRegistry not found", "Warning")
    end
    
    -- Set up equipment auto-cleaning
    self:setupAutoClean()
    
    -- Set up equipment maintenance checks
    self:setupMaintenanceChecks()
    
    initialized = true
    log("GymAutomation initialized successfully")
    
    return self
end

-- Equipment registration
function GymAutomation:registerEquipment(equipment, equipmentType, options)
    if not equipment or not equipmentType then
        log("Failed to register equipment: missing parameters", "Warning")
        return false
    end
    
    -- Generate unique ID
    local equipmentId = equipment:GetFullName()
    
    -- Set default options
    options = options or {}
    options.maintenanceInterval = options.maintenanceInterval or equipmentCheckInterval
    options.cleaningNeeded = options.cleaningNeeded or false
    
    -- Store equipment data
    registeredEquipment[equipmentId] = {
        instance = equipment,
        type = equipmentType,
        options = options,
        lastMaintenance = os.time(),
        lastCleaning = os.time(),
        condition = 100, -- percent
    }
    
    log("Registered equipment: " .. equipmentId)
    return true
end

-- Perform cleaning on equipment
function GymAutomation:cleanEquipment(equipmentId)
    local equipment = registeredEquipment[equipmentId]
    if not equipment then
        log("Equipment not found for cleaning: " .. tostring(equipmentId), "Warning")
        return false
    end
    
    log("Cleaning equipment: " .. equipmentId)
    
    -- Mark as in cleaning process
    activeCleaningTasks[equipmentId] = true
    
    -- Update equipment state
    equipment.lastCleaning = os.time()
    equipment.options.cleaningNeeded = false
    
    -- Update visual appearance if applicable
    if equipment.instance:FindFirstChild("Appearance") then
        -- Implement visual cleaning effect
    end
    
    -- Complete cleaning
    activeCleaningTasks[equipmentId] = nil
    
    return true
end

-- Perform maintenance on equipment
function GymAutomation:performMaintenance(equipmentId)
    local equipment = registeredEquipment[equipmentId]
    if not equipment then
        log("Equipment not found for maintenance: " .. tostring(equipmentId), "Warning")
        return false
    end
    
    log("Performing maintenance on equipment: " .. equipmentId)
    
    -- Mark as in maintenance
    activeMaintenanceTasks[equipmentId] = true
    
    -- Update equipment state
    equipment.lastMaintenance = os.time()
    equipment.condition = 100
    
    -- Update attributes on the instance
    if equipment.instance:IsA("Model") or equipment.instance:IsA("BasePart") then
        equipment.instance:SetAttribute("Condition", 100)
        equipment.instance:SetAttribute("LastMaintenance", os.time())
    end
    
    -- Complete maintenance
    activeMaintenanceTasks[equipmentId] = nil
    
    return true
end

-- Setup auto-cleaning system
function GymAutomation:setupAutoClean()
    log("Setting up auto-cleaning system...")
    
    -- Start periodic cleaning check
    task.spawn(function()
        while true do
            task.wait(autoCleanInterval)
            
            log("Running auto-cleaning check...", "Debug")
            
            -- Check all equipment for cleaning needs
            for id, equipment in pairs(registeredEquipment) do
                if equipment.options.cleaningNeeded and not activeCleaningTasks[id] then
                    task.spawn(function()
                        self:cleanEquipment(id)
                    end)
                end
            end
        end
    end)
end

-- Setup maintenance check system
function GymAutomation:setupMaintenanceChecks()
    log("Setting up maintenance check system...")
    
    -- Start periodic maintenance check
    task.spawn(function()
        while true do
            task.wait(equipmentCheckInterval)
            
            log("Running maintenance check...", "Debug")
            
            -- Check all equipment for maintenance needs
            for id, equipment in pairs(registeredEquipment) do
                local timeSinceLastMaintenance = os.time() - equipment.lastMaintenance
                
                -- Check if maintenance is needed
                if timeSinceLastMaintenance > equipment.options.maintenanceInterval and not activeMaintenanceTasks[id] then
                    task.spawn(function()
                        self:performMaintenance(id)
                    end)
                end
            end
        end
    end)
end

-- Get equipment statistics
function GymAutomation:getEquipmentStats()
    local stats = {
        totalEquipment = 0,
        needsMaintenance = 0,
        needsCleaning = 0,
        inMaintenance = 0,
        inCleaning = 0,
        byType = {}
    }
    
    -- Count equipment
    for id, equipment in pairs(registeredEquipment) do
        stats.totalEquipment = stats.totalEquipment + 1
        
        -- Track by type
        stats.byType[equipment.type] = (stats.byType[equipment.type] or 0) + 1
        
        -- Check maintenance status
        local timeSinceLastMaintenance = os.time() - equipment.lastMaintenance
        if timeSinceLastMaintenance > equipment.options.maintenanceInterval then
            stats.needsMaintenance = stats.needsMaintenance + 1
        end
        
        -- Check cleaning status
        if equipment.options.cleaningNeeded then
            stats.needsCleaning = stats.needsCleaning + 1
        end
        
        -- Check active tasks
        if activeMaintenanceTasks[id] then
            stats.inMaintenance = stats.inMaintenance + 1
        end
        
        if activeCleaningTasks[id] then
            stats.inCleaning = stats.inCleaning + 1
        end
    end
    
    return stats
end

-- Return the module
return GymAutomation
