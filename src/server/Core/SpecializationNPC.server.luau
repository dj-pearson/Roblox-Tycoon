lua
local SpecializationNPC = {}

local CollectionService = game:GetService("CollectionService")

local CoreRegistry = require(script.Parent.CoreRegistry)
local SpecializationSystem = CoreRegistry:getSystem("SpecializationSystem")


function SpecializationNPC.init()
    -- Initialization logic (if needed)
end

function SpecializationNPC.getSpecializations()
    return SpecializationSystem:getSpecializationsList()
end

function SpecializationNPC.assignSpecialization(npc)
    if not npc then return end
    local specializations = SpecializationNPC.getSpecializations()
    if not specializations or #specializations == 0 then return end

    local chosenSpecialization = specializations[math.random(#specializations)]

    -- Ensure only one specialization tag is applied at a time
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

function SpecializationNPC.removeSpecializationTag(npc)
    if not npc then return end
    local currentTag = npc:GetAttribute("Specialization")
    if currentTag then
        npc:SetAttribute("Specialization", nil)
    end
end

function SpecializationNPC.getNPCsInSpecializationArea(specialization)
    local npcs = {}
    local areaName = specialization .. "Area" -- Assuming the area is named after the specialization + "Area"

    for _, instance in ipairs(CollectionService:GetTagged(areaName)) do
        if instance:IsA("Model") and instance:HasAttribute("IsNPC") then
            table.insert(npcs, instance)
        end
    end

    return npcs
end

function SpecializationNPC.getSpecializationAreaName(specialization)
    return specialization .. "Area"
end

return SpecializationNPC