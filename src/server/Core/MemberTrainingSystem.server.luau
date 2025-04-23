lua
--[[
    MemberTrainingSystem.server.luau
    Handles the training logic for gym members.
    Part of the Core systems architecture.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- System Dependencies
local CoreRegistry
local EventBridge
local DataManager
local StaffManagementSystem
local CollectionService = game:GetService("CollectionService")

-- Configuration
local CONFIG = {
    xpPerTrainingCycle = 10, -- Base XP gained per training cycle
    trainingCycleDuration = 5, -- Duration of a training cycle in seconds
    maxLevel = 100, -- Maximum level a member can reach
    debug = true
}

-- Module table
local MemberTrainingSystem = {
    _name = "MemberTrainingSystem",
    _version = "1.0.0",
    _dependencies = {"CoreRegistry", "EventBridge", "DataManager","StaffManagementSystem", "EquipmentMaintenanceSystem"},
    _trainingData = {}, -- Table to store training data for each member
    _equipmentData = {}, -- Table to store data for each equipment
    _loops = {} -- Table to store loops
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[Member Training System]", ...)
    end
end

-- Function to get the dirtiness of an equipment
function MemberTrainingSystem:getEquipmentDirtiness(equipment)
    if not self._equipmentData[equipment] then
        self._equipmentData[equipment] = {
            dirtiness = 100 -- Default dirtiness when an equipment is created
        }
    end
    return self._equipmentData[equipment].dirtiness
end


--[[ Core Functions ]]--

-- Function to handle the training process
function MemberTrainingSystem:handleTraining(member, equipment)
    local memberId = member.Name
    --Check if the member is being trained
    if not self._trainingData[memberId].isTraining then return end
    -- Check if there is a trainer nearby
    local trainer = nil
    local trainerEfficiency = 1
    local minDistance = 10
    local memberPosition = member.HumanoidRootPart.Position
    local isCleaningStaff = false
    
    for _, staff in ipairs(workspace.Staff:GetChildren()) do
        if staff:IsA("Model") and staff.HumanoidRootPart then
            local staffPosition = staff.HumanoidRootPart.Position
            local distance = (memberPosition - staffPosition).Magnitude
            
            if distance < minDistance then
                minDistance = distance
                trainer = staff
                 if StaffManagementSystem then
                    trainerEfficiency = StaffManagementSystem:getStaffEfficiency(trainer.Name) or 1
                    isCleaningStaff = StaffManagementSystem:getStaffRole(trainer.Name) == "janitor"
                end
                
            end
        end
    end
    
    if trainer then
        -- Apply training effect
        if trainerEfficiency > 1 and not isCleaningStaff then
            self:applyTrainingEffect(member, trainerEfficiency)
        end
        -- Check if equipment needs cleaning
        if isCleaningStaff and CollectionService:HasTag(equipment, "NeedsCleaning") then
            self:cleanEquipment(equipment, trainerEfficiency)
        end
    end
    
end

-- Apply training effect to a member
function MemberTrainingSystem:applyTrainingEffect(member, efficiency)
    -- Get member's current XP and level
    local memberId = member.Name
    local xp = self._trainingData[memberId].xp or 0
    local level = self._trainingData[memberId].level or 1

    -- Calculate XP gain based on efficiency
    local xpGain = CONFIG.xpPerTrainingCycle * efficiency
    xp = xp + xpGain
    debugPrint("Member", memberId, "gained", xpGain, "XP. Total XP:", xp)

    -- Check for level up
    local xpToNextLevel = self:getXPForNextLevel(level)
    while xp >= xpToNextLevel and level < CONFIG.maxLevel do
        xp = xp - xpToNextLevel
        level = level + 1
        xpToNextLevel = self:getXPForNextLevel(level)
        debugPrint("Member", memberId, "leveled up to", level)
    end

    -- Update member's data
    self._trainingData[memberId].xp = xp
    self._trainingData[memberId].level = level

    -- Notify the client about the member's updated XP and level
    if EventBridge then
        EventBridge:fireEvent("MemberTrainingUpdated", member, {
            xp = xp,
            level = level
        })
    end
end

-- Function to clean equipment
function MemberTrainingSystem:cleanEquipment(equipment, efficiency)
    -- Get current equipment dirtiness
    local currentDirtiness = self:getEquipmentDirtiness(equipment)
    
    -- Calculate the amount to clean based on efficiency
    local cleanAmount = 10 * efficiency

    -- Reduce dirtiness
    currentDirtiness = currentDirtiness - cleanAmount

    -- Ensure dirtiness does not go below 0
    currentDirtiness = math.max(currentDirtiness, 0)

    -- Update equipment data
    self._equipmentData[equipment].dirtiness = currentDirtiness
    debugPrint("Equipment", equipment.Name, "cleaned. Dirtiness:", currentDirtiness)
    -- Check if equipment is clean
    if currentDirtiness <= 0 then
        CollectionService:RemoveTag(equipment, "NeedsCleaning")
        })
        -- Reset the timer of the equipment
        EquipmentMaintenanceSystem:resetTimer(equipment)
    end
end

-- Function to start the training of a member
function MemberTrainingSystem:startTraining(member, equipment)
    if member and member.Parent then
        local memberId = member.Name
        if not self._trainingData[memberId] then
            self._trainingData[memberId] = {
                xp = 0,
                level = 1,
                isTraining = true
            }
            debugPrint("Started training for member", memberId)
        end
        -- Start training loop for the member
        self._loops[memberId] = task.spawn(function()
            while self._trainingData[memberId] and self._trainingData[memberId].isTraining do
                task.wait(1) -- Run every second
                self:handleTraining(member, equipment)
            end
        end)
    end
end

-- Function to stop the training of a member
function MemberTrainingSystem:stopTraining(member)
    local memberId = member.Name
    if self._trainingData[memberId] then
        self._trainingData[memberId].isTraining = false
        debugPrint("Stopped training for member", memberId)
    end
end

-- Helper function to calculate XP needed for the next level
function MemberTrainingSystem:getXPForNextLevel(level)
    -- Example: Linear increase in XP requirement per level
    return 100 + (level - 1) * 50
end

--[[ Initialization and Event Handling ]]--

function MemberTrainingSystem:init()
    debugPrint("Initializing Member Training System v" .. self._version)

    -- Get dependencies
    CoreRegistry = self.CoreRegistry
    EventBridge = CoreRegistry:getSystem("EventBridge")
    DataManager = CoreRegistry:getSystem("DataManager")
    StaffManagementSystem = CoreRegistry:getSystem("StaffManagementSystem")
    EquipmentMaintenanceSystem = CoreRegistry:getSystem("EquipmentMaintenanceSystem")

    debugPrint("Member Training System initialized")
    return true
end

function MemberTrainingSystem:start()
    debugPrint("Member Training System started")
    return true
end

function MemberTrainingSystem:stop()
    debugPrint("Stopping Member Training System")
    return true
end

--[[ Public API ]]--

return CoreRegistry.registerSystem("MemberTrainingSystem", MemberTrainingSystem, {"CoreRegistry", "EventBridge", "DataManager","StaffManagementSystem", "EquipmentMaintenanceSystem"})