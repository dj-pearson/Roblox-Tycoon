--lua
--[[
    EquipmentMaintenanceSystem.server.luau
    Handles the maintenance of equipment in the gym.
    Part of the Core systems architecture.
]]

local CollectionService = game:GetService("CollectionService")

-- Module dependencies
local CoreRegistry
local EventBridge

-- Configuration

local CONFIG = {
    equipmentDirtinessTimes = {
        ["Treadmill"] = 60,        -- Treadmills get dirty faster
        ["Elliptical"] = 70,       -- Ellipticals get dirty slightly slower than treadmills
        ["StationaryBike"] = 80,   -- Stationary Bikes get dirty slower
        ["RowingMachine"] = 90,    -- Rowing Machines get dirty slower
        ["WeightMachine"] = 120,   -- Weight Machines get dirty even slower
        ["FreeWeights"] = 150,     -- Free Weights get dirty slower
        ["BenchPress"] = 180,      -- Bench Press gets dirty the slowest
        ["default"] = 120,          -- Default time to get dirty
    },
    debug = true
}

-- Module table
local EquipmentMaintenanceSystem = {
    _name = "EquipmentMaintenanceSystem",
    _version = "1.0.0",
    _dependencies = {"CoreRegistry", "EventBridge"},
    _equipmentTimers = {} -- Table to store equipment timers
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[Equipment Maintenance System]", ...)
    end
end

-- Function to add a tag to equipment
function EquipmentMaintenanceSystem:addTagToEquipment(equipment, tag)
    if not CollectionService:HasTag(equipment, tag) then
        CollectionService:AddTag(equipment, tag)
        debugPrint("Added tag", tag, "to equipment", equipment.Name)
    end
end

-- Function to setup equipment with a timer
function EquipmentMaintenanceSystem:setupEquipment(equipment)
    if not self._equipmentTimers[equipment] then
      local equipmentType = equipment.Name
      local timeToGetDirty = CONFIG.equipmentDirtinessTimes[equipmentType] or CONFIG.equipmentDirtinessTimes["default"]
      
      -- Create a new timer for the equipment
      self._equipmentTimers[equipment] = task.delay(timeToGetDirty, function()
          -- Add the "NeedsCleaning" tag
          self:addTagToEquipment(equipment, "NeedsCleaning")
          debugPrint("Equipment", equipment.Name, "needs cleaning")
  
          -- Re-setup the equipment to get dirty again
          self:setupEquipment(equipment)
      end)
      debugPrint("Equipment", equipment.Name, "will get dirty in", timeToGetDirty, "seconds")
    end
end
-- Function to reset the timer of an equipment
function EquipmentMaintenanceSystem:resetTimer(equipment)
    -- Check if the equipment has a timer
    if self._equipmentTimers[equipment] then
        -- Cancel the existing timer
        task.cancel(self._equipmentTimers[equipment])
        self._equipmentTimers[equipment] = nil
        debugPrint("Equipment", equipment.Name, "timer reset")
        -- Setup a new timer for the equipment
        self:setupEquipment(equipment)
    else
        debugPrint("Equipment", equipment.Name, "does not have a timer")
    end
end

--[[ Initialization and Event Handling ]]--

function EquipmentMaintenanceSystem:init()
    debugPrint("Initializing Equipment Maintenance System v" .. self._version)

    -- Get dependencies
    CoreRegistry = self.CoreRegistry
    EventBridge = CoreRegistry:getSystem("EventBridge")
    
    debugPrint("Equipment Maintenance System initialized")
    return true
end

function EquipmentMaintenanceSystem:start()
    debugPrint("Equipment Maintenance System started")
    -- Setup each equipment in the game.
    for _, equipment in ipairs(workspace.Equipment:GetChildren()) do
      if equipment:IsA("Model") and not CollectionService:HasTag(equipment,"NPC") then
        self:setupEquipment(equipment)
      end
      end
    return true
end

function EquipmentMaintenanceSystem:stop()
    debugPrint("Stopping Equipment Maintenance System")
    -- Disconnect all equipment timers
    for equipment, connection in pairs(self._equipmentTimers) do
        if connection then
            connection:Cancel()
        end
    end
    return true
end

--[[ Public API ]]--
