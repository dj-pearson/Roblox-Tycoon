--[[
    GymAutomation.server.luau
    
    Core system for managing automated gym features.
    This system ensures proper automation initialization, monitoring,
    and error recovery.
    
    Features:
    - Automated gym feature management
    - Equipment maintenance scheduling
    - Staff management automation
    - Error tracking and reporting
    - Integration with CoreRegistry
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
    debug = true,
    checkInterval = 30, -- seconds
    maxErrors = 50,
    errorRetentionTime = 3600, -- 1 hour
    maintenanceInterval = 3600, -- 1 hour
    staffRotationInterval = 7200, -- 2 hours
    maxRetries = 3,
    retryDelay = 2 -- seconds
}

-- Module state
local GymAutomation = {
    initialized = false,
    errors = {},
    lastCheck = 0,
    maintenanceSchedule = {},
    staffSchedule = {},
    equipmentStatus = {}
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[GymAutomation]", ...)
    end
end

-- Get ErrorHandler
local function getErrorHandler()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local handler = coreRegistry:getSystem("ErrorHandler")
        if handler then
            return handler
        end
    end
    
    -- Try to find in ReplicatedStorage
    local core = ReplicatedStorage:FindFirstChild("Core")
    if core and core:FindFirstChild("ErrorHandler") then
        local success, result = pcall(function()
            return require(core.ErrorHandler)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Get DataManager
local function getDataManager()
    -- Try to get from CoreRegistry first
    local coreRegistry = _G.CoreRegistry
    if coreRegistry and typeof(coreRegistry.getSystem) == "function" then
        local manager = coreRegistry:getSystem("DataManager")
        if manager then
            return manager
        end
    end
    
    -- Try to find in ServerScriptService
    local dataManager = ServerScriptService:FindFirstChild("GymTycoonDataManager")
    if dataManager then
        local success, result = pcall(function()
            return require(dataManager)
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end

-- Schedule maintenance
local function scheduleMaintenance(equipmentId)
    if not equipmentId then return false end
    
    local dataManager = getDataManager()
    if not dataManager then
        log("DataManager not found, cannot schedule maintenance")
        return false
    end
    
    -- Get equipment data
    local success, equipment = pcall(function()
        return dataManager:getEquipmentData(equipmentId)
    end)
    
    if not success or not equipment then
        log("Failed to get equipment data for: " .. tostring(equipmentId))
        return false
    end
    
    -- Schedule maintenance
    GymAutomation.maintenanceSchedule[equipmentId] = {
        lastMaintenance = os.time(),
        nextMaintenance = os.time() + CONFIG.maintenanceInterval,
        status = "scheduled"
    }
    
    log("Maintenance scheduled for equipment: " .. tostring(equipmentId))
    return true
end

-- Schedule staff rotation
local function scheduleStaffRotation(staffId)
    if not staffId then return false end
    
    local dataManager = getDataManager()
    if not dataManager then
        log("DataManager not found, cannot schedule staff rotation")
        return false
    end
    
    -- Get staff data
    local success, staff = pcall(function()
        return dataManager:getStaffData(staffId)
    end)
    
    if not success or not staff then
        log("Failed to get staff data for: " .. tostring(staffId))
        return false
    end
    
    -- Schedule rotation
    GymAutomation.staffSchedule[staffId] = {
        lastRotation = os.time(),
        nextRotation = os.time() + CONFIG.staffRotationInterval,
        status = "scheduled"
    }
    
    log("Staff rotation scheduled for: " .. tostring(staffId))
    return true
end

-- Check equipment status
local function checkEquipmentStatus()
    local dataManager = getDataManager()
    if not dataManager then
        log("DataManager not found, cannot check equipment status")
        return false
    end
    
    -- Get all equipment
    local success, equipment = pcall(function()
        return dataManager:getAllEquipment()
    end)
    
    if not success or not equipment then
        log("Failed to get equipment data")
        return false
    end
    
    -- Check each equipment
    for id, data in pairs(equipment) do
        local status = GymAutomation.maintenanceSchedule[id]
        if status then
            -- Check if maintenance is due
            if os.time() >= status.nextMaintenance then
                -- Perform maintenance
                local success = pcall(function()
                    dataManager:performMaintenance(id)
                end)
                
                if success then
                    -- Update schedule
                    status.lastMaintenance = os.time()
                    status.nextMaintenance = os.time() + CONFIG.maintenanceInterval
                    status.status = "maintained"
                else
                    status.status = "failed"
                    log("Maintenance failed for equipment: " .. tostring(id))
                end
            end
        else
            -- Schedule maintenance if not scheduled
            scheduleMaintenance(id)
        end
    end
    
    return true
end

-- Check staff status
local function checkStaffStatus()
    local dataManager = getDataManager()
    if not dataManager then
        log("DataManager not found, cannot check staff status")
        return false
    end
    
    -- Get all staff
    local success, staff = pcall(function()
        return dataManager:getAllStaff()
    end)
    
    if not success or not staff then
        log("Failed to get staff data")
        return false
    end
    
    -- Check each staff member
    for id, data in pairs(staff) do
        local status = GymAutomation.staffSchedule[id]
        if status then
            -- Check if rotation is due
            if os.time() >= status.nextRotation then
                -- Perform rotation
                local success = pcall(function()
                    dataManager:rotateStaff(id)
                end)
                
                if success then
                    -- Update schedule
                    status.lastRotation = os.time()
                    status.nextRotation = os.time() + CONFIG.staffRotationInterval
                    status.status = "rotated"
                else
                    status.status = "failed"
                    log("Staff rotation failed for: " .. tostring(id))
                end
            end
        else
            -- Schedule rotation if not scheduled
            scheduleStaffRotation(id)
        end
    end
    
    return true
end

-- Record an error
local function recordError(message)
    local timestamp = os.time()
    
    -- Add new error
    table.insert(GymAutomation.errors, {
        message = message,
        timestamp = timestamp
    })
    
    -- Remove old errors
    while #GymAutomation.errors > CONFIG.maxErrors do
        table.remove(GymAutomation.errors, 1)
    end
    
    -- Remove errors older than retention time
    local cutoff = timestamp - CONFIG.errorRetentionTime
    for i = #GymAutomation.errors, 1, -1 do
        if GymAutomation.errors[i].timestamp < cutoff then
            table.remove(GymAutomation.errors, i)
        end
    end
    
    -- Report to ErrorHandler
    local errorHandler = getErrorHandler()
    if errorHandler then
        errorHandler:recordError(message, "gym_automation", {
            timestamp = timestamp
        })
    end
    
    log("Error recorded: " .. message)
end

-- Check system health
local function checkHealth()
    local now = os.time()
    GymAutomation.lastCheck = now
    
    -- Check equipment status
    local success = checkEquipmentStatus()
    if not success then
        recordError("Failed to check equipment status")
    end
    
    -- Check staff status
    success = checkStaffStatus()
    if not success then
        recordError("Failed to check staff status")
    end
    
    return true
end

-- Initialize GymAutomation
function GymAutomation.initialize()
    if GymAutomation.initialized then return true end
    
    log("Initializing GymAutomation...")
    
    -- Get required systems
    local dataManager = getDataManager()
    if not dataManager then
        log("DataManager not found, initialization may be limited")
    end
    
    local errorHandler = getErrorHandler()
    if not errorHandler then
        log("ErrorHandler not found, error reporting may be limited")
    end
    
    -- Start health monitoring
    task.spawn(function()
        while true do
            task.wait(CONFIG.checkInterval)
            checkHealth()
        end
    end)
    
    GymAutomation.initialized = true
    log("GymAutomation initialized")
    return true
end

-- Get maintenance schedule
function GymAutomation.getMaintenanceSchedule()
    return GymAutomation.maintenanceSchedule
end

-- Get staff schedule
function GymAutomation.getStaffSchedule()
    return GymAutomation.staffSchedule
end

-- Get equipment status
function GymAutomation.getEquipmentStatus()
    return GymAutomation.equipmentStatus
end

-- Get error count
function GymAutomation.getErrorCount()
    return #GymAutomation.errors
end

-- Get recent errors
function GymAutomation.getRecentErrors()
    return GymAutomation.errors
end

-- Force a health check
function GymAutomation.forceCheck()
    return checkHealth()
end

return GymAutomation
