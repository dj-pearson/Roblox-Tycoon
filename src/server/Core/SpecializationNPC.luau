--lua
function NPCSystem:changeStats(npc)
    local specialization = npc:GetAttribute("Specialization")
    local CoreRegistry = require(script.Parent.CoreRegistry)
    local SpecializationSystem = CoreRegistry:getSystem("SpecializationSystem")
    local specializationsData = SpecializationSystem:getSpecializations()

    if specialization and specializationsData[specialization] then
        local statChanges = specializationsData[specialization].stats
        if statChanges then
            npc:SetAttribute("Strength", statChanges.Strength or 100)
            npc:SetAttribute("Agility", statChanges.Agility or 100)
            npc:SetAttribute("Stamina", statChanges.Stamina or 100)
        else
            npc:SetAttribute("Strength", 100)
            npc:SetAttribute("Agility", 100)
            npc:SetAttribute("Stamina", 100)
        end
    else
        npc:SetAttribute("Strength", 100)
        npc:SetAttribute("Agility", 100)
        npc:SetAttribute("Stamina", 100)
    end
end