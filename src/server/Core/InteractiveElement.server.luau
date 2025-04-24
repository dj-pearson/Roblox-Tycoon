--[[
    InteractiveElement.server.luau
    This script adds functionality to interactive elements in the gym.
    It should be added to any model that NPCs can interact with.
]]

local InteractiveElement = {}

-- Configuration
local CONFIG = {
    defaultMaxUsers = 1,
    interactionTypes = {
        "Seat",     -- For benches, chairs, etc.
        "Cardio",   -- For treadmills, bikes, etc.
        "Weights",  -- For weight machines, dumbbells, etc.
        "Spa",      -- For saunas, massage tables, etc.
        "Default"   -- For general interactive elements
    }
}

-- Helper function to validate interaction type
local function validateInteractionType(interactionType)
    if not interactionType or interactionType == "" then
        return "Default"
    end
    
    for _, validType in ipairs(CONFIG.interactionTypes) do
        if interactionType:lower() == validType:lower() then
            return validType
        end
    end
    
    return "Default"
end

-- Setup the model as an interactive element
function InteractiveElement.setup(model, options)
    options = options or {}
    
    -- Set the base attributes
    model:SetAttribute("IsInteractive", true)
    
    -- Validate and set interaction type
    local interactionType = validateInteractionType(options.interactionType)
    model:SetAttribute("InteractionType", interactionType)
    
    -- Set the maximum number of users
    local maxUsers = options.maxUsers or CONFIG.defaultMaxUsers
    model:SetAttribute("MaxUsers", maxUsers)
    
    -- Initialize current users
    model:SetAttribute("CurrentUsers", 0)
    
    -- Set specialization type if applicable
    if options.specializationType then
        model:SetAttribute("SpecializationType", options.specializationType)
    end
    
    -- Create an interaction point if not already present
    if not model:FindFirstChild("InteractionPoint") and options.interactionPointOffset then
        local interactionPoint = Instance.new("Attachment")
        interactionPoint.Name = "InteractionPoint"
        
        -- Position the interaction point relative to the model's primary part
        local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            interactionPoint.Parent = primaryPart
            interactionPoint.Position = options.interactionPointOffset
        end
    end
    
    -- Connect events if needed
    if options.onInteractionStarted then
        model:SetAttribute("OnInteractionStarted", true)
        model.Attributes.Changed:Connect(function(attrName)
            if attrName == "CurrentUsers" then
                local currentUsers = model:GetAttribute("CurrentUsers")
                local previousUsers = model:GetAttribute("PreviousUsers") or 0
                
                if currentUsers > previousUsers then
                    options.onInteractionStarted(model)
                end
                
                model:SetAttribute("PreviousUsers", currentUsers)
            end
        end)
    end
    
    if options.onInteractionEnded then
        model:SetAttribute("OnInteractionEnded", true)
        model.Attributes.Changed:Connect(function(attrName)
            if attrName == "CurrentUsers" then
                local currentUsers = model:GetAttribute("CurrentUsers")
                local previousUsers = model:GetAttribute("PreviousUsers") or 0
                
                if currentUsers < previousUsers then
                    options.onInteractionEnded(model)
                end
                
                model:SetAttribute("PreviousUsers", currentUsers)
            end
        end)
    end
    
    return model
end

return InteractiveElement
