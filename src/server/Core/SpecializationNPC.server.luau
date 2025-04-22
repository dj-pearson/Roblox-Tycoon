lua
local SpecializationNPC = {}

local CoreRegistry = require(script.Parent.CoreRegistry)
local SpecializationSystem = CoreRegistry:getSystem("SpecializationSystem")


function SpecializationNPC.init()
    -- Initialization logic (if needed)
end

function SpecializationNPC.getSpecializations()
    return SpecializationSystem:getSpecializationsList()
end

function SpecializationNPC.assignSpecialization(npc)
    local specializations = SpecializationNPC.getSpecializations()
    local chosenSpecialization = specializations[math.random(#specializations)]
    npc:SetAttribute("Specialization", chosenSpecialization)
    return chosenSpecialization
end

function SpecializationNPC.setSpecialization(npc, specialization)
    local validSpecializations = SpecializationNPC.getSpecializations()
    local isValid = false
    for _, validSpec in ipairs(validSpecializations) do
        if validSpec == specialization then
            isValid = true
            break
        end
    end

    if isValid then
        npc:SetAttribute("Specialization", specialization)
        return true
    else
        return false
    end
end

return SpecializationNPC