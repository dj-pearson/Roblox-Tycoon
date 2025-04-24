--lua
-- src/server/Core/StaffManagementSystem.server.luau

--[[
    StaffManagementSystem.server.luau
    Manages staff members, their roles, and other staff-related data.
    Part of the Core systems architecture.
]]

local CoreRegistry = require(script.Parent.CoreRegistry)

local StaffManagementSystem = {}
-- Will be initialized in the initialize function
local StaffSpecializationSystem = nil

--[[
    _staffData:
    A table to store data for each staff member.
    The key is the staffId, and the value is a table with the staff's data.
]]
StaffManagementSystem._staffData = {}

--[[
    assignRole(staffId, role)
    Assigns a role to a staff member.
    staffId: The unique identifier for the staff member.
    role: The role to assign (e.g., "Trainer", "Manager").
]]
function StaffManagementSystem:assignRole(staffId, role)
    -- Check if the staff member already exists, if not, create an entry
    if not self._staffData[staffId] then
        self._staffData[staffId] = {}
        self._staffData[staffId].skills = {}
    end
    -- Assign the role
    self._staffData[staffId].role = role
    -- Set the staff efficiency to 1 by default
    self._staffData[staffId].efficiency = 1

    if StaffSpecializationSystem then
        local skillTree = StaffSpecializationSystem:getSkillTreeForRole(role)
        if skillTree then
            for _, skill in ipairs(skillTree) do
                self._staffData[staffId].skills[skill.name] = skill.effects
            end
        end
    end

    -- Apply the skill effects
    self:applySkillEffects(staffId)

    print("[StaffManagementSystem] Assigned role " .. role .. " to staff member " .. tostring(staffId))
end

--[[
    getStaffRole(staffId)
    Gets the role of a staff member.
    staffId: The unique identifier for the staff member.
    Returns: The staff member's role, or nil if the staff member doesn't exist or doesn't have a role.
]]
function StaffManagementSystem:getStaffRole(staffId)
    if self._staffData[staffId] and self._staffData[staffId].role then
        return self._staffData[staffId].role
    else
        return nil
    end
end

--[[
    setStaffEfficiency(staffId, efficiency)
    Sets the efficiency of a staff member.
    staffId: The unique identifier for the staff member.
    efficiency: The new efficiency value (e.g., 1.0, 1.2).
]]
function StaffManagementSystem:setStaffEfficiency(staffId, efficiency)
    if self._staffData[staffId] then
        self._staffData[staffId].efficiency = efficiency
        print("[StaffManagementSystem] Set efficiency of staff member " .. tostring(staffId) .. " to " .. tostring(efficiency))
    else
        print("[StaffManagementSystem] Warning: Staff member " .. tostring(staffId) .. " not found.")
    end
end

--[[
    getStaffEfficiency(staffId)
    Gets the efficiency of a staff member.
    staffId: The unique identifier for the staff member.
    Returns: The staff member's efficiency, or nil if the staff member doesn't exist or doesn't have an efficiency set.
]]
function StaffManagementSystem:getStaffEfficiency(staffId)
    if self._staffData[staffId] and self._staffData[staffId].efficiency then
        return self._staffData[staffId].efficiency
    else
        return nil
    end
end

--[[
    getStaffSkills(staffId)
    Gets the skills of a staff member.
    staffId: The unique identifier for the staff member.
    Returns: The staff member's skills, or nil if the staff member doesn't exist.
]]
function StaffManagementSystem:getStaffSkills(staffId)
    if self._staffData[staffId] then
        return self._staffData[staffId].skills
    else
        return nil
    end
end

--[[
    applySkillEffects(staffId)
    Applies the effects of the staff member's skills to their attributes.
    staffId: The unique identifier for the staff member.
]]
function StaffManagementSystem:applySkillEffects(staffId)
    local skills = self:getStaffSkills(staffId)
    if skills then
        for skillName, effects in pairs(skills) do
            if skillName == "Efficiency" then
                self._staffData[staffId].efficiency = self._staffData[staffId].efficiency * effects.cleaningSpeedBoost
            elseif skillName == "Speed Training" then
                self._staffData[staffId].efficiency = self._staffData[staffId].efficiency * effects.trainingSpeedBoost
            end
        end
    end
end

--[[
    initialize()
    Initializes the system.
]]
function StaffManagementSystem:initialize()
    print("[StaffManagementSystem] Initialized")
    -- Get StaffSpecializationSystem from CoreRegistry
    StaffSpecializationSystem = CoreRegistry:getSystem("StaffSpecializationSystem")
end

--[[ 
Public API to register
]]
local PublicAPI = {
    initialize = function()
        return StaffManagementSystem:initialize()
    end,
    assignRole = function(staffId, role)
        StaffManagementSystem:assignRole(staffId, role)
    end,
    getStaffRole = function(staffId)
        return StaffManagementSystem:getStaffRole(staffId)
    end,
    setStaffEfficiency = function(staffId, efficiency)
        StaffManagementSystem:setStaffEfficiency(staffId, efficiency)
    end,
    getStaffEfficiency = function(staffId)
        return StaffManagementSystem:getStaffEfficiency(staffId)
    end,
    getStaffSkills = function(staffId)
        return StaffManagementSystem:getStaffSkills(staffId)
    end,
    applySkillEffects = function(staffId)
        StaffManagementSystem:applySkillEffects(staffId)
    end,

}

-- Register with the CoreRegistry
return CoreRegistry.registerSystem("StaffManagementSystem", PublicAPI, {"CoreRegistry","StaffSpecializationSystem"})