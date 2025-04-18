-- SpecializationSystem.luau
-- Server-side implementation of the gym specialization system
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Import server-side systems
local CoreRegistry = require(script.Parent.CoreRegistry)
local EventBridge = CoreRegistry.getSystem("EventBridge")
local DataManager = CoreRegistry.getSystem("DataManager")

-- Configuration
local CONFIG = {
    debugEnabled = true,
}

-- Debug function
local function log(...)
    if CONFIG.debugEnabled then
        print("[SpecializationSystem]", ...)
    end
end

-- The SpecializationSystem object
local SpecializationSystem = {
    playerSpecializations = {},
    initialized = false,
    
    -- Specialization definitions
    specializations = {
        bodybuilding = {
            name = "Bodybuilding",
            description = "Focus on strength training and muscle growth",
            level_requirement = 3,
            benefits = {
                membership_boost = 1.2,  -- 20% more members
                vip_chance = 0.15,       -- Increased VIP chance (15% vs standard 10%)
                equipment_discounts = {  -- Discounts on related equipment
                    weights = 0.2,       -- 20% off weight equipment
                    machines = 0.1       -- 10% off machines
                }
            },
            equipment_tags = {"weights", "bench", "rack"}
        },
        cardio = {
            name = "Cardio Fitness",
            description = "Focus on cardiovascular health and endurance",
            level_requirement = 3,
            benefits = {
                dues_boost = 1.15,       -- Members pay 15% more
                membership_retention = 1.25, -- 25% better member retention
                equipment_discounts = {
                    treadmill = 0.2,     -- 20% off treadmills
                    cardio = 0.15        -- 15% off cardio equipment
                }
            },
            equipment_tags = {"treadmill", "bike", "cardio"}
        },
        luxury = {
            name = "Luxury Wellness",
            description = "Premium experience with spa and wellness features",
            level_requirement = 5,
            benefits = {
                vip_multiplier = 2.0,    -- VIPs pay double the standard boost
                vip_chance = 0.2,        -- 20% chance for VIPs
                membership_boost = 0.9,  -- 10% fewer total members
                dues_boost = 1.3         -- 30% higher membership fees
            },
            equipment_tags = {"spa", "sauna", "luxury"}
        },
        crossfit = {
            name = "CrossFit Training",
            description = "High-intensity functional training approach",
            level_requirement = 4,
            benefits = {
                membership_boost = 1.1,  -- 10% more members
                dues_boost = 1.1,        -- 10% higher dues
                competition_boost = 1.3  -- 30% better competition results
            },
            equipment_tags = {"functional", "crossfit", "box"}
        }
    }
}

-- Get available specializations for a player
function SpecializationSystem:getAvailableSpecializations(player)
    if not player then return {} end

    local available = {}
    local gymLevel = 1

    -- Get gym level
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon then
        gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or 1
    end

    -- Filter specializations by level requirement
    for id, specialization in pairs(self.specializations) do
        if gymLevel >= specialization.level_requirement then
            table.insert(available, {
                id = id,
                name = specialization.name,
                description = specialization.description,
                level_requirement = specialization.level_requirement
            })
        end
    end

    return available
end

-- Get current specialization(s) for a player
function SpecializationSystem:getPlayerSpecializations(player)
    if not player then return nil end

    local userId = player.UserId

    -- Check cached data
    if self.playerSpecializations[userId] then
        return self.playerSpecializations[userId]
    end

    -- Load from data storage
    if DataManager then
        local data = DataManager.getPlayerData(player)
        if data and data.specializations then
            self.playerSpecializations[userId] = data.specializations
            return data.specializations
        end
    end

    -- Default to no specialization
    return { primary = nil, secondary = nil }
end

-- Set player specialization
function SpecializationSystem:setSpecialization(player, specializationId, isSecondary)
    if not player or not specializationId then return false, "Missing player or specialization ID" end

    -- Check if specialization exists
    if not self.specializations[specializationId] then
        return false, "Invalid specialization"
    end

    local userId = player.UserId
    local gymLevel = 1

    -- Get gym level
    local tycoon = player:FindFirstChild("Tycoon")
    if tycoon then
        gymLevel = tycoon:GetAttribute("GymTier") or tycoon:GetAttribute("GymLevel") or 1
    end

    -- Check level requirement
    local specialization = self.specializations[specializationId]
    if gymLevel < specialization.level_requirement then
        return false, "Gym level too low. Requires level " .. specialization.level_requirement
    end

    -- Get current specializations
    local current = self:getPlayerSpecializations(player)

    -- Update specialization
    if isSecondary then
        -- Can't have same primary and secondary
        if current.primary == specializationId then
            return false, "Cannot set the same specialization as both primary and secondary"
        end
        current.secondary = specializationId
    else
        -- Can't have same primary and secondary
        if current.secondary == specializationId then
            return false, "Cannot set the same specialization as both primary and secondary"
        end
        current.primary = specializationId
    end

    -- Update cache
    self.playerSpecializations[userId] = current

    -- Save to data storage
    if DataManager then
        DataManager.updateData(player, "specializations", current)
    end

    -- Apply specialization benefits
    self:applySpecializationBenefits(player)
    
    -- Create specialization decor
    self:createSpecializationDecor(player)
    
    -- Notify client
    EventBridge.fireClientEvent("SpecializationUpdated", player, current)

    return true, "Specialization set successfully"
end

-- Apply specialization benefits to a player
function SpecializationSystem:applySpecializationBenefits(player)
    if not player then return end

    local specs = self:getPlayerSpecializations(player)

    -- No specializations
    if not specs.primary and not specs.secondary then
        return
    end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon then return end

    -- Reset to base values
    tycoon:SetAttribute("SpecMembershipBoost", 1.0)
    tycoon:SetAttribute("SpecDuesBoost", 1.0)
    tycoon:SetAttribute("SpecVIPChance", 0.1) -- Default 10%
    tycoon:SetAttribute("SpecVIPMultiplier", 1.0)
    tycoon:SetAttribute("SpecCompetitionBoost", 1.0)

    -- Apply primary specialization benefits
    if specs.primary then
        local primary = self.specializations[specs.primary]
        if primary then
            -- Membership boost
            if primary.benefits.membership_boost then
                tycoon:SetAttribute("SpecMembershipBoost", primary.benefits.membership_boost)
            end

            -- Dues boost
            if primary.benefits.dues_boost then
                tycoon:SetAttribute("SpecDuesBoost", primary.benefits.dues_boost)
            end

            -- VIP chance
            if primary.benefits.vip_chance then
                tycoon:SetAttribute("SpecVIPChance", primary.benefits.vip_chance)
            end

            -- VIP multiplier
            if primary.benefits.vip_multiplier then
                tycoon:SetAttribute("SpecVIPMultiplier", primary.benefits.vip_multiplier)
            end

            -- Competition boost
            if primary.benefits.competition_boost then
                tycoon:SetAttribute("SpecCompetitionBoost", primary.benefits.competition_boost)
            end
        end
    end

    -- Apply secondary specialization benefits (at half strength)
    if specs.secondary then
        local secondary = self.specializations[specs.secondary]
        if secondary then
            -- Membership boost (half effect)
            if secondary.benefits.membership_boost then
                local currentBoost = tycoon:GetAttribute("SpecMembershipBoost")
                local secondaryEffect = (secondary.benefits.membership_boost - 1.0) * 0.5
                tycoon:SetAttribute("SpecMembershipBoost", currentBoost + secondaryEffect)
            end

            -- Dues boost (half effect)
            if secondary.benefits.dues_boost then
                local currentBoost = tycoon:GetAttribute("SpecDuesBoost")
                local secondaryEffect = (secondary.benefits.dues_boost - 1.0) * 0.5
                tycoon:SetAttribute("SpecDuesBoost", currentBoost + secondaryEffect)
            end

            -- VIP chance (half effect)
            if secondary.benefits.vip_chance then
                local currentChance = tycoon:GetAttribute("SpecVIPChance")
                local secondaryEffect = (secondary.benefits.vip_chance - 0.1) * 0.5
                tycoon:SetAttribute("SpecVIPChance", currentChance + secondaryEffect)
            end

            -- VIP multiplier (half effect)
            if secondary.benefits.vip_multiplier then
                local currentMultiplier = tycoon:GetAttribute("SpecVIPMultiplier")
                local secondaryEffect = (secondary.benefits.vip_multiplier - 1.0) * 0.5
                tycoon:SetAttribute("SpecVIPMultiplier", currentMultiplier + secondaryEffect)
            end

            -- Competition boost (half effect)
            if secondary.benefits.competition_boost then
                local currentBoost = tycoon:GetAttribute("SpecCompetitionBoost")
                local secondaryEffect = (secondary.benefits.competition_boost - 1.0) * 0.5
                tycoon:SetAttribute("SpecCompetitionBoost", currentBoost + secondaryEffect)
            end
        end
    end

    -- Update revenue system if available
    local GymRevenueSystem = CoreRegistry.getSystem("GymRevenueSystem")
    if GymRevenueSystem then
        GymRevenueSystem.updatePlayerConfig(player)
    end
    
    -- Notify other systems about specialization changes
    EventBridge.fireEvent("PlayerSpecializationChanged", player, specs)
end

-- Create specialization decor based on player's specialization
function SpecializationSystem:createSpecializationDecor(player)
    if not player then return end

    local tycoon = player:FindFirstChild("Tycoon")
    if not tycoon or not tycoon.Value then return end

    local specs = self:getPlayerSpecializations(player)
    if not specs.primary then return end -- Only create decor for primary specialization

    local specialization = self.specializations[specs.primary]
    if not specialization then return end

    -- Check if decor already exists
    local existingDecor = tycoon.Value:FindFirstChild("SpecializationDecor")
    if existingDecor then
        existingDecor:Destroy()
    end

    -- Create decor model
    local decor = Instance.new("Model")
    decor.Name = "SpecializationDecor"

    -- Create different decor based on specialization
    if specs.primary == "bodybuilding" then
        -- Create bodybuilding decor (posters, trophy case)
        local poster = Instance.new("Part")
        poster.Name = "BodybuildingPoster"
        poster.Size = Vector3.new(4, 3, 0.1)
        poster.Anchored = true
        poster.CanCollide = false

        -- Find a wall to place it on
        local position
        for _, part in pairs(tycoon.Value:GetDescendants()) do
            if part:IsA("BasePart") and part.Size.Y > 5 and part.Size.X > 4 then
                position = part.Position + part.CFrame.LookVector * (part.Size.Z/2 + 0.1)
                break
            end
        end

        if position then
            poster.Position = position + Vector3.new(0, 1, 0)

            -- Add surface GUI with image
            local surfaceGui = Instance.new("SurfaceGui")
            surfaceGui.Face = Enum.NormalId.Front
            surfaceGui.Parent = poster

            local posterImage = Instance.new("ImageLabel")
            posterImage.Size = UDim2.new(1, 0, 1, 0)
            posterImage.BackgroundTransparency = 1
            posterImage.Image = "rbxassetid://2637579692" -- Example bodybuilding image
            posterImage.Parent = surfaceGui

            poster.Parent = decor
        end

    elseif specs.primary == "cardio" then
        -- Create cardio decor (running track markers)
        for i = 1, 5 do
            local marker = Instance.new("Part")
            marker.Name = "TrackMarker"..i
            marker.Size = Vector3.new(0.5, 0.1, 0.5)
            marker.BrickColor = BrickColor.new("Bright red")
            marker.Material = Enum.Material.Neon
            marker.Anchored = true
            marker.CanCollide = false

            -- Find floor to place markers on
            local floor
            for _, part in pairs(tycoon.Value:GetDescendants()) do
                if part:IsA("BasePart") and part.Size.X > 10 and part.Size.Z > 10 and 
                    math.abs(part.CFrame.UpVector.Y) > 0.9 then
                    floor = part
                    break
                end
            end

            if floor then
                local angle = (i / 5) * math.pi * 2
                local radius = 5
                local offsetX = math.cos(angle) * radius
                local offsetZ = math.sin(angle) * radius

                marker.Position = floor.Position + Vector3.new(offsetX, floor.Size.Y/2 + 0.1, offsetZ)
                marker.Parent = decor
            end
        end

    elseif specs.primary == "luxury" then
        -- Create luxury decor (fancy reception desk, plant)
        local plant = Instance.new("Part")
        plant.Name = "LuxuryPlant"
        plant.Size = Vector3.new(1, 2, 1)
        plant.BrickColor = BrickColor.new("Forest green")
        plant.Material = Enum.Material.Grass
        plant.Anchored = true

        local pot = Instance.new("Part")
        pot.Name = "PlantPot"
        pot.Size = Vector3.new(1.2, 0.5, 1.2)
        pot.BrickColor = BrickColor.new("Pearl")
        pot.Material = Enum.Material.Marble
        pot.Anchored = true

        -- Find spot near entrance
        local entrance
        for _, part in pairs(tycoon.Value:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name:lower():find("entrance") or part.Name:lower():find("door")) then
                entrance = part
                break
            end
        end

        if entrance then
            pot.Position = entrance.Position + Vector3.new(2, 0, 2)
            plant.Position = pot.Position + Vector3.new(0, 1.25, 0)

            pot.Parent = decor
            plant.Parent = decor
        end

    elseif specs.primary == "crossfit" then
        -- Create crossfit decor (rope, chalk bucket)
        local chalk = Instance.new("Part")
        chalk.Name = "ChalkBucket"
        chalk.Size = Vector3.new(0.8, 0.5, 0.8)
        chalk.BrickColor = BrickColor.new("Institutional white")
        chalk.Material = Enum.Material.SmoothPlastic
        chalk.Anchored = true

        -- Find a spot in the center
        local center
        for _, part in pairs(tycoon.Value:GetDescendants()) do
            if part.Name == "Platform" or (part:IsA("BasePart") and part.Size.X > 10 and part.Size.Z > 10) then
                center = part
                break
            end
        end

        if center then
            chalk.Position = center.Position + Vector3.new(0, center.Size.Y/2 + 0.25, 0)
            chalk.Parent = decor
        end
    end

    -- Parent decor to tycoon
    decor.Parent = tycoon.Value
    
    -- Tag specialization decor
    CollectionService:AddTag(decor, "SpecializationDecor")
    CollectionService:AddTag(decor, "SpecializationType_" .. specs.primary)

    return decor
end

-- Apply discounts to equipment purchases
function SpecializationSystem:applyEquipmentDiscount(player, equipmentId, basePrice)
    if not player or not equipmentId then return basePrice end

    local specs = self:getPlayerSpecializations(player)
    local discount = 0

    -- Get equipment type from id or attributes
    local equipmentType = "unknown"

    -- Extract equipment type from ID or name
    if equipmentId:lower():find("treadmill") then
        equipmentType = "treadmill"
    elseif equipmentId:lower():find("bench") or equipmentId:lower():find("weight") then
        equipmentType = "weights"
    elseif equipmentId:lower():find("machine") then
        equipmentType = "machines"
    elseif equipmentId:lower():find("bike") then
        equipmentType = "cardio"
    elseif equipmentId:lower():find("spa") or equipmentId:lower():find("sauna") then
        equipmentType = "spa"
    elseif equipmentId:lower():find("crossfit") or equipmentId:lower():find("functional") then
        equipmentType = "functional"
    end

    -- Check primary specialization for discounts
    if specs.primary then
        local primary = self.specializations[specs.primary]
        if primary and primary.benefits.equipment_discounts then
            local discounts = primary.benefits.equipment_discounts

            if discounts[equipmentType] then
                discount = discounts[equipmentType]
            end
        end
    end

    -- Check secondary specialization for discounts (half effect)
    if specs.secondary then
        local secondary = self.specializations[specs.secondary]
        if secondary and secondary.benefits.equipment_discounts then
            local discounts = secondary.benefits.equipment_discounts

            if discounts[equipmentType] then
                -- Add half of the secondary discount
                discount = discount + (discounts[equipmentType] * 0.5)
            end
        end
    end

    -- Apply discount (capped at 50%)
    discount = math.min(discount, 0.5)
    local discountedPrice = math.floor(basePrice * (1 - discount))

    return discountedPrice
end

-- Setup server events
function SpecializationSystem:setupServerEvents()
    -- Set specialization event
    EventBridge.registerClientToServerEvent("SetSpecialization", function(player, specializationId, isSecondary)
        local success, message = self:setSpecialization(player, specializationId, isSecondary)
        
        -- Send response to client
        EventBridge.fireClientEvent("SpecializationResponse", player, {
            success = success,
            message = message
        })
        
        return success
    end)
    
    -- Get specializations request
    EventBridge.registerClientToServerEvent("RequestSpecializations", function(player)
        local playerSpecs = self:getPlayerSpecializations(player)
        local availableSpecs = self:getAvailableSpecializations(player)
        
        -- Send data to client
        EventBridge.fireClientEvent("SpecializationsData", player, {
            current = playerSpecs,
            available = availableSpecs,
            allSpecs = self.specializations
        })
        
        return true
    end)
    
    -- Open specialization UI
    EventBridge.registerClientToServerEvent("OpenSpecializationMenu", function(player)
        -- Just a trigger to open UI - actual UI is handled client-side
        EventBridge.fireClientEvent("ShowSpecializationUI", player)
        return true
    end)
    
    -- Handle equipment purchase discounts
    EventBridge.registerEvent("EquipmentPriceRequest", function(player, equipmentId, basePrice)
        local discountedPrice = self:applyEquipmentDiscount(player, equipmentId, basePrice)
        return discountedPrice
    end)
end

-- Initialize the system
function SpecializationSystem:initialize()
    log("Initializing SpecializationSystem...")
    
    -- Set up server events
    self:setupServerEvents()
    
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:applySpecializationBenefits(player)
    end
    
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        -- Wait for character to load
        player.CharacterAdded:Wait()
        task.wait(3)
        
        -- Apply specialization benefits
        self:applySpecializationBenefits(player)
        
        -- Create decor if they have a specialization
        self:createSpecializationDecor(player)
    end)
    
    self.initialized = true
    log("SpecializationSystem initialized")
    
    return true
end

-- Public API
local PublicAPI = {
    initialize = function()
        return SpecializationSystem:initialize()
    end,
    
    getSpecializations = function()
        return SpecializationSystem.specializations
    end,
    
    getPlayerSpecializations = function(player)
        return SpecializationSystem:getPlayerSpecializations(player)
    end,
    
    getAvailableSpecializations = function(player)
        return SpecializationSystem:getAvailableSpecializations(player)
    end,
    
    setSpecialization = function(player, specializationId, isSecondary)
        return SpecializationSystem:setSpecialization(player, specializationId, isSecondary)
    end,
    
    applySpecializationBenefits = function(player)
        return SpecializationSystem:applySpecializationBenefits(player)
    end,
    
    applyEquipmentDiscount = function(player, equipmentId, basePrice)
        return SpecializationSystem:applyEquipmentDiscount(player, equipmentId, basePrice)
    end,
    
    createSpecializationDecor = function(player)
        return SpecializationSystem:createSpecializationDecor(player)
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("SpecializationSystem", PublicAPI, {"EventBridge", "DataManager"})

