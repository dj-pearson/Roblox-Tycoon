lua
-- src/server/Core/StaffSpecializationSystem.server.luau

--[[
    StaffSpecializationSystem.server.luau
    Manages staff roles, skill trees, and specializations.
    Part of the Core systems architecture.
]]

local CoreRegistry = require(script.Parent.CoreRegistry)

-- Define the available staff roles
local STAFF_ROLES = {
    Trainer = "Trainer",
    Manager = "Manager",
    Janitor = "Janitor",
    Receptionist = "Receptionist"
}

-- Define the skill trees for each role
local SKILL_TREES = {
    [STAFF_ROLES.Trainer] = {
        {
            name = "Speed Training",
            description = "Increases the speed at which members train.",
            effects = {
                trainingSpeedBoost = 0.2 -- 20% boost to training speed
            }
        },
        {
            name = "Motivation",
            description = "Increases member satisfaction when training.",
            effects = {
                memberSatisfactionBoost = 0.15 -- 15% boost to satisfaction
            }
        }
    },
    [STAFF_ROLES.Manager] = {
        {
            name = "Motivation",
            description = "Improves the overall satisfaction of members.",
            effects = {
                memberSatisfactionBoost = 0.1 -- 10% boost to member satisfaction
            }
        },
        
    },
        {
            name = "Member Retention",
            description = "Reduces member churn rate.",
            effects = {
                churnReduction = 0.03 -- 3% reduction in churn
            }
        }
    },
    [STAFF_ROLES.Janitor] = {
        {
            name = "Efficiency",
            description = "Increases cleaning speed.",
            effects = {
                cleaningSpeedBoost = 0.25 -- 25% boost to cleaning speed
            }
        },
        {
            name = "Hygiene",
            description = "Improves cleaning quality.",
            effects = {
                cleanlinessBoost = 0.15 -- 15% boost to how clean they keep the areas.
            }
        }
    },
    [STAFF_ROLES.Receptionist] = {
        {
            name = "Customer Service",
            description = "Increases member satisfaction upon entry.",
            effects = {
                entrySatisfactionBoost = 0.08 -- 8% boost to satisfaction on entry
            }
        },
        {
            name = "Sales",
            description = "Increases chances of new member signups.",
            effects = {
                signupBoost = 0.05 -- 5% boost to signups
            }
        }
    }
}

-- Module table
local StaffSpecializationSystem = {}

-- Initialize the system
function StaffSpecializationSystem:initialize()
    print("[StaffSpecializationSystem] Initialized")
    -- Any setup logic can go here
end

-- Get staff roles
function StaffSpecializationSystem:getStaffRoles()
    return STAFF_ROLES
end

-- Get staff skills
function StaffSpecializationSystem:getSkillTrees()
    return SKILL_TREES
end

-- Get the skill tree for a specific role
function StaffSpecializationSystem:getSkillTreeForRole(role)
    return SKILL_TREES[role]
end

-- Public API to register
local PublicAPI = {
    initialize = function()
        return StaffSpecializationSystem:initialize()
    end,
    getStaffRoles = function()
        return StaffSpecializationSystem:getStaffRoles()
    end,
    getSkillTrees = function()
        return StaffSpecializationSystem:getSkillTrees()
    end,
    getSkillTreeForRole = function(role)
        return StaffSpecializationSystem:getSkillTreeForRole(role)
    end
}

-- Register with the CoreRegistry
return CoreRegistry.registerSystem("StaffSpecializationSystem", PublicAPI, {})