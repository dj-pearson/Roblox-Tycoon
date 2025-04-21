--[[
    EquipmentUpgradeSystem.luau
    
    ===== DEPRECATION NOTICE =====
    This script has been deprecated and is scheduled for removal.
    It has been consolidated into the new EquipmentManager.server.luau module.
    Please use EquipmentManager:UpgradeEquipment() instead of functionality from this script.
    See ConsolidationPlan.md for details on the module consolidation project.
    ===== END NOTICE =====
    
    Original script documentation follows:
    
    A system that handles equipment upgrades in the gym tycoon.
    This system allows players to upgrade their equipment to higher levels,
    replacing models while maintaining their position in the gym.
    
    Author: Created April 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Attempt to get modules
local CoreRegistry = require(script.Parent:FindFirstChild("CoreRegistry") or {})

local EquipmentUpgradeSystem = {}
EquipmentUpgradeSystem.__index = EquipmentUpgradeSystem

-- Constants
local MAX_UPGRADE_LEVEL = 4
local UPGRADE_PRICE_MULTIPLIER = 1.75 -- Each level costs 1.75x the previous level

-- Initialize the system
function EquipmentUpgradeSystem:Initialize()
    -- Register with CoreRegistry if available
    if CoreRegistry and CoreRegistry.RegisterSystem then
        CoreRegistry:RegisterSystem("EquipmentUpgradeSystem", self)
    end
    
    self.tycoonSystem = CoreRegistry and CoreRegistry:GetSystem("TycoonSystem")
    self.economySystem = CoreRegistry and CoreRegistry:GetSystem("EconomySystem")
    
    -- Create upgrade events
    self.upgradeEvents = {
        upgradeRequested = Instance.new("BindableEvent"),
        upgradeCompleted = Instance.new("BindableEvent")
    }
    
    -- Public events
    self.UpgradeRequested = self.upgradeEvents.upgradeRequested.Event
    self.UpgradeCompleted = self.upgradeEvents.upgradeCompleted.Event
    
    -- Setup event handlers
    self:SetupEventHandlers()
    
    return self
end

-- Setup event handlers for the system
function EquipmentUpgradeSystem:SetupEventHandlers()
    -- Listen for RemoteEvents if available
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if remoteEvents then
        local upgradeRequestEvent = remoteEvents:FindFirstChild("RequestEquipmentUpgrade")
        
        if upgradeRequestEvent then
            upgradeRequestEvent.OnServerEvent:Connect(function(player, equipmentId, equipmentType, targetLevel)
                -- Find the equipment in player's tycoon
                local equipment
                if self.tycoonSystem then
                    local tycoon = self.tycoonSystem:GetPlayerTycoon(player)
                    if tycoon then
                        local equipmentFolder = tycoon:FindFirstChild("Equipment")
                        if equipmentFolder then
                            -- Find by ID first
                            for _, item in ipairs(equipmentFolder:GetChildren()) do
                                if item:GetAttribute("EquipmentId") == equipmentId then
                                    equipment = item
                                    break
                                end
                            end
                            
                            -- If not found by ID, try by type and position
                            if not equipment then
                                for _, item in ipairs(equipmentFolder:GetChildren()) do
                                    if item:GetAttribute("equipmentType") == equipmentType then
                                        equipment = item
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                
                if equipment then
                    self:HandleUpgradeRequest(player, equipment, equipmentType, targetLevel)
                end
            end)
        end
    end
end

-- Handle an upgrade request from a player
function EquipmentUpgradeSystem:HandleUpgradeRequest(player, equipment, equipmentType, targetLevel)
    if not player or not equipment then return false end
    
    -- Get current level
    local currentLevel = equipment:GetAttribute("upgradeLevel") or 1
    
    -- Validate target level
    targetLevel = targetLevel or (currentLevel + 1)
    if targetLevel <= currentLevel or targetLevel > MAX_UPGRADE_LEVEL then
        return false, "Invalid upgrade level"
    end
    
    -- Calculate upgrade cost
    local basePrice = equipment:GetAttribute("basePrice") or 100
    local upgradeCost = self:CalculateUpgradeCost(basePrice, currentLevel, targetLevel)
    
    -- Check if player can afford upgrade
    if self.economySystem then
        if not self.economySystem:CanAfford(player, upgradeCost) then
            return false, "Cannot afford upgrade"
        end
    else
        -- Fallback economy check if no economy system
        local playerMoney = player:FindFirstChild("leaderstats") and 
                            player.leaderstats:FindFirstChild("Money") and 
                            player.leaderstats.Money.Value or 0
                            
        if playerMoney < upgradeCost then
            return false, "Cannot afford upgrade"
        end
    end
    
    -- Fire upgrade requested event
    self.upgradeEvents.upgradeRequested:Fire(player, equipment, equipmentType, targetLevel, upgradeCost)
    
    -- Charge the player
    if self.economySystem then
        self.economySystem:SpendMoney(player, upgradeCost, "Equipment Upgrade")
    else
        -- Fallback economy update if no economy system
        local playerMoney = player:FindFirstChild("leaderstats") and 
                            player.leaderstats:FindFirstChild("Money")
        if playerMoney then
            playerMoney.Value = playerMoney.Value - upgradeCost
        end
    end
    
    -- Perform the actual upgrade
    local success, result = self:UpgradeEquipment(player, equipment, equipmentType, targetLevel)
    
    -- Fire completion event
    if success then
        self.upgradeEvents.upgradeCompleted:Fire(player, result, equipmentType, targetLevel)
    end
    
    return success, result
end

-- Calculate the cost to upgrade from current level to target level
function EquipmentUpgradeSystem:CalculateUpgradeCost(basePrice, currentLevel, targetLevel)
    local totalCost = 0
    
    for level = currentLevel + 1, targetLevel do
        totalCost = totalCost + (basePrice * (UPGRADE_PRICE_MULTIPLIER ^ (level - 1)))
    end
    
    return math.floor(totalCost)
end

-- Actually upgrade the equipment
function EquipmentUpgradeSystem:UpgradeEquipment(player, equipment, equipmentType, targetLevel)
    if not equipmentType then
        equipmentType = equipment:GetAttribute("equipmentType") or equipment.Name
    end
    
    -- Find the upgrade model in ServerStorage
    local upgradeFolder = ServerStorage:FindFirstChild(equipmentType .. "_Upgrade")
    if not upgradeFolder then
        return false, "No upgrade models found"
    end
    
    -- Find the specific upgrade level model
    local upgradedModel = upgradeFolder:FindFirstChild(equipmentType .. "_Level" .. targetLevel)
    if not upgradedModel then
        return false, "No upgrade model found for level " .. targetLevel
    end
    
    -- Clone the upgraded model
    local newEquipment = upgradedModel:Clone()
    
    -- Transfer attributes from old equipment
    for _, attrName in ipairs(equipment:GetAttributes()) do
        if attrName ~= "upgradeLevel" then -- Don't copy over the old level
            newEquipment:SetAttribute(attrName, equipment:GetAttribute(attrName))
        end
    end
    
    -- Set the new upgrade level
    newEquipment:SetAttribute("upgradeLevel", targetLevel)
    
    -- Calculate new income bonus based on level
    local baseBonus = equipment:GetAttribute("incomeBonus") or 10
    local newIncomeBonus = baseBonus * (1 + (targetLevel - 1) * 0.5) -- 50% increase per level
    newEquipment:SetAttribute("incomeBonus", newIncomeBonus)
    
    -- Add satisfaction bonus for higher tier equipment
    newEquipment:SetAttribute("satisfactionBonus", (targetLevel - 1) * 5) -- +5 per level above 1
    
    -- Handle positioning
    -- This will be handled by the EquipmentSetup module through monkey patching

    -- Get reference to parent before replacing
    local parent = equipment.Parent
    
    -- Remove the old equipment
    equipment:Destroy()
    
    -- Add the new equipment
    newEquipment.Parent = parent
    
    return true, newEquipment
end

-- Check if equipment can be upgraded
function EquipmentUpgradeSystem:CanUpgrade(equipment)
    if not equipment then return false end
    
    local currentLevel = equipment:GetAttribute("upgradeLevel") or 1
    return currentLevel < MAX_UPGRADE_LEVEL
end

-- Get details about the next upgrade level
function EquipmentUpgradeSystem:GetUpgradeDetails(equipment)
    if not equipment then return nil end
    
    local currentLevel = equipment:GetAttribute("upgradeLevel") or 1
    if currentLevel >= MAX_UPGRADE_LEVEL then
        return nil -- Already at max level
    end
    
    local nextLevel = currentLevel + 1
    local basePrice = equipment:GetAttribute("basePrice") or 100
    local upgradeCost = self:CalculateUpgradeCost(basePrice, currentLevel, nextLevel)
    
    local baseBonus = equipment:GetAttribute("incomeBonus") or 10
    local newIncomeBonus = baseBonus * (1 + (nextLevel - 1) * 0.5)
    
    return {
        currentLevel = currentLevel,
        nextLevel = nextLevel,
        maxLevel = MAX_UPGRADE_LEVEL,
        upgradeCost = upgradeCost,
        currentIncomeBonus = equipment:GetAttribute("incomeBonus") or baseBonus,
        newIncomeBonus = newIncomeBonus,
        currentSatisfactionBonus = equipment:GetAttribute("satisfactionBonus") or 0,
        newSatisfactionBonus = (nextLevel - 1) * 5
    }
end

-- Get available upgrade levels
function EquipmentUpgradeSystem:GetAvailableUpgradeLevels(equipment)
    if not equipment then return {} end
    
    local currentLevel = equipment:GetAttribute("upgradeLevel") or 1
    local equipmentType = equipment:GetAttribute("equipmentType") or equipment.Name
    
    local upgradeFolder = ServerStorage:FindFirstChild(equipmentType .. "_Upgrade")
    if not upgradeFolder then
        return {}
    end
    
    local availableLevels = {}
    
    -- Check each level from current+1 to MAX_UPGRADE_LEVEL
    for level = currentLevel + 1, MAX_UPGRADE_LEVEL do
        local levelModel = upgradeFolder:FindFirstChild(equipmentType .. "_Level" .. level)
        
        if levelModel then
            local basePrice = equipment:GetAttribute("basePrice") or 100
            local upgradeCost = self:CalculateUpgradeCost(basePrice, currentLevel, level)
            
            local baseBonus = equipment:GetAttribute("incomeBonus") or 10
            local newIncomeBonus = baseBonus * (1 + (level - 1) * 0.5)
            
            table.insert(availableLevels, {
                level = level,
                cost = upgradeCost,
                incomeBonus = newIncomeBonus,
                satisfactionBonus = (level - 1) * 5
            })
        end
    end
    
    return availableLevels
end

return EquipmentUpgradeSystem:Initialize()