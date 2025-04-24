--[[
    EquipmentUpgradeSystem.server.luau
    
    System for handling equipment upgrades in the gym tycoon.
    Preserves the exact position and orientation of original equipment
    when upgrading, making it ideal for pre-placed gym equipment.
    
    Author: Created April 2025
    Updated: April 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Fixed reference to BoundingBoxManager instead of EquipmentBoundingBox
local EquipmentBoundingBox = require(script.Parent.BoundingBoxManager)

local EquipmentUpgradeSystem = {}
EquipmentUpgradeSystem.__index = EquipmentUpgradeSystem

-- Constants
local UPGRADE_MODELS_FOLDER = "Upgrades"
local DEFAULT_UPGRADE_COST = 5000
local DEFAULT_REVENUE_MULTIPLIER = 1.5

-- Upgrade data structure
local UPGRADE_DATA = {
    Treadmill = {
        upgradePath = {"Basic Treadmill", "Standard Treadmill", "Premium Treadmill"},
        costs = {DEFAULT_UPGRADE_COST, DEFAULT_UPGRADE_COST * 2},
        revenueMultipliers = {1.0, DEFAULT_REVENUE_MULTIPLIER, DEFAULT_REVENUE_MULTIPLIER * 1.5},
    },
    Elliptical = {
        upgradePath = {"Basic Elliptical", "Standard Elliptical", "Premium Elliptical"},
        costs = {DEFAULT_UPGRADE_COST, DEFAULT_UPGRADE_COST * 2},
        revenueMultipliers = {1.0, DEFAULT_REVENUE_MULTIPLIER, DEFAULT_REVENUE_MULTIPLIER * 1.5},
    },
    -- Add more equipment types as needed
}

-- Constructor
function EquipmentUpgradeSystem.new(tycoonInstance, playerData)
    local self = setmetatable({}, EquipmentUpgradeSystem)
    
    self.tycoon = tycoonInstance
    self.playerData = playerData
    self.equipmentFolder = tycoonInstance:FindFirstChild("Equipment")
    self.remoteEvents = {}
    
    -- Create equipment folder if it doesn't exist
    if not self.equipmentFolder then
        self.equipmentFolder = Instance.new("Folder")
        self.equipmentFolder.Name = "Equipment"
        self.equipmentFolder.Parent = self.tycoon
    end
    
    -- Setup remote events for client communication
    self:SetupRemoteEvents()
    
    return self
end

-- Create and set up remote events
function EquipmentUpgradeSystem:SetupRemoteEvents()
    local events = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder")
    events.Name = "Events"
    events.Parent = ReplicatedStorage
    
    -- Create upgrade event if it doesn't exist
    local upgradeEvent = events:FindFirstChild("RequestEquipmentUpgrade") or Instance.new("RemoteEvent")
    upgradeEvent.Name = "RequestEquipmentUpgrade"
    upgradeEvent.Parent = events
    
    -- Connect event handler
    upgradeEvent.OnServerEvent:Connect(function(player, equipmentId)
        self:HandleUpgradeRequest(player, equipmentId)
    end)
    
    self.remoteEvents.RequestEquipmentUpgrade = upgradeEvent
end

-- Initialize upgrade models in the tycoon
function EquipmentUpgradeSystem:InitializeUpgrades()
    -- This function is now more focused on ensuring equipment has correct attributes
    -- rather than relying on bounding boxes
    
    -- First, verify all equipment has required attributes
    for _, equipment in ipairs(self.equipmentFolder:GetChildren()) do
        -- Skip non-models
        if not equipment:IsA("Model") and not equipment:IsA("BasePart") then
            continue
        end
        
        -- Make sure equipment has an ID (using existing ID attribute naming)
        if not equipment:GetAttribute("ID") then
            equipment:SetAttribute("ID", math.random(1000, 9999))
        end
        
        -- If equipment has no type, try to determine it from name
        if not equipment:GetAttribute("equipmentType") then
            -- Try to guess type from name
            for equipType, _ in pairs(UPGRADE_DATA) do
                if string.find(string.lower(equipment.Name), string.lower(equipType)) then
                    equipment:SetAttribute("equipmentType", equipType)
                    break
                end
            end
        end
        
        -- Set default upgrade level if not present
        if not equipment:GetAttribute("upgradeLevel") then
            equipment:SetAttribute("upgradeLevel", 0)
        end
    end
    
    -- Load equipment upgrade data from player data
    self:LoadEquipmentUpgradeData()
end

-- Load equipment upgrade data from player save
function EquipmentUpgradeSystem:LoadEquipmentUpgradeData()
    -- Skip if no player data
    if not self.playerData then return end
    
    -- Get equipment upgrade data from player data
    local upgradeData = self.playerData:GetData("equipmentUpgrades") or {}
    
    -- Apply upgrades based on saved data
    for equipmentId, upgradeLevel in pairs(upgradeData) do
        local equipment = self.equipmentFolder:FindFirstChild(equipmentId)
        if equipment then
            -- Apply the appropriate upgrade level
            self:ApplyUpgradeToEquipment(equipment, upgradeLevel)
        end
    end
end

-- Handle upgrade request from client
function EquipmentUpgradeSystem:HandleUpgradeRequest(player, equipmentId)
    -- Validate request
    if not player or not equipmentId then return end
    
    -- Find the equipment
    local equipment = self.equipmentFolder:FindFirstChild(equipmentId)
    if not equipment then
        warn("EquipmentUpgradeSystem: Equipment not found:", equipmentId)
        return
    end
    
    -- Get equipment type
    local equipmentType = equipment:GetAttribute("equipmentType")
    if not equipmentType or not UPGRADE_DATA[equipmentType] then
        warn("EquipmentUpgradeSystem: Invalid equipment type:", equipmentType)
        return
    end
    
    -- Get current upgrade level
    local currentLevel = equipment:GetAttribute("upgradeLevel") or 0
    
    -- Check if max level reached
    local upgradePath = UPGRADE_DATA[equipmentType].upgradePath
    if currentLevel >= #upgradePath - 1 then
        warn("EquipmentUpgradeSystem: Max upgrade level reached for", equipmentId)
        return
    end
    
    -- Get upgrade cost
    local upgradeCost = UPGRADE_DATA[equipmentType].costs[currentLevel + 1] or DEFAULT_UPGRADE_COST
    
    -- Check if player can afford upgrade
    if not self.playerData:CanAfford(upgradeCost) then
        warn("EquipmentUpgradeSystem: Player cannot afford upgrade")
        return
    end
    
    -- Charge player for upgrade
    self.playerData:SpendMoney(upgradeCost)
    
    -- Apply upgrade
    self:ApplyUpgradeToEquipment(equipment, currentLevel + 1)
    
    -- Save upgrade data
    self:SaveEquipmentUpgradeData(equipmentId, currentLevel + 1)
end

-- Apply upgrade level to equipment
function EquipmentUpgradeSystem:ApplyUpgradeToEquipment(equipment, upgradeLevel)
    -- Get equipment type
    local equipmentType = equipment:GetAttribute("equipmentType")
    if not equipmentType or not UPGRADE_DATA[equipmentType] then return end
    
    -- Store original position and orientation BEFORE doing anything else
    local originalCFrame
    
    if equipment:IsA("Model") and equipment.PrimaryPart then
        originalCFrame = equipment:GetPivot()
    elseif equipment:IsA("BasePart") then
        originalCFrame = equipment.CFrame
    else
        -- Find a part to use for positioning if no primary part
        for _, part in ipairs(equipment:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCFrame = part.CFrame
                break
            end
        end
    end
    
    -- Exit if we couldn't determine position
    if not originalCFrame then
        warn("EquipmentUpgradeSystem: Could not determine position for equipment:", equipment.Name)
        return
    end
    
    -- Get upgrade model name
    local upgradePath = UPGRADE_DATA[equipmentType].upgradePath
    if upgradeLevel <= 0 or upgradeLevel >= #upgradePath then return end
    
    -- Look for upgrade models in ServerStorage
    local upgradeModel
    
    -- First check in type-specific folders (e.g., "Treadmill_Upgrade")
    local typeFolder = ServerStorage:FindFirstChild(equipmentType .. "_Upgrade")
    if typeFolder then
        upgradeModel = typeFolder:FindFirstChild(equipmentType .. "_Level" .. (upgradeLevel + 1))
    end
    
    -- If not found, check general upgrades folder
    if not upgradeModel then
        local upgradeModelsFolder = ServerStorage:FindFirstChild(UPGRADE_MODELS_FOLDER)
        if upgradeModelsFolder then
            upgradeModel = upgradeModelsFolder:FindFirstChild(upgradePath[upgradeLevel + 1])
        end
    end
    
    if not upgradeModel then
        warn("EquipmentUpgradeSystem: Upgrade model not found for", equipmentType, "level", upgradeLevel + 1)
        return
    end
    
    -- Clone the upgrade model
    local newModel = upgradeModel:Clone()
    
    -- Set attributes - copy ALL attributes from original model
    newModel.Name = equipment.Name
    
    -- Copy all attributes from the original model
    for name, value in pairs(equipment:GetAttributes()) do
        newModel:SetAttribute(name, value)
    end
    
    -- Update specific attributes for the upgrade
    newModel:SetAttribute("equipmentType", equipmentType)
    newModel:SetAttribute("upgradeLevel", upgradeLevel)
    newModel:SetAttribute("originalEquipmentID", equipment:GetAttribute("ID") or equipment.Name)  -- Using ID instead of EquipmentId
    
    -- Get revenue multiplier
    local revenueMultiplier = UPGRADE_DATA[equipmentType].revenueMultipliers[upgradeLevel + 1] or DEFAULT_REVENUE_MULTIPLIER
    newModel:SetAttribute("revenueMultiplier", revenueMultiplier)
    
    -- Apply the original position and orientation
    if newModel:IsA("Model") then
        -- If new model doesn't have a PrimaryPart, find one
        if not newModel.PrimaryPart then
            for _, part in ipairs(newModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    newModel.PrimaryPart = part
                    break
                end
            end
        end
        
        if newModel.PrimaryPart then
            newModel:PivotTo(originalCFrame)
        else
            warn("EquipmentUpgradeSystem: Upgrade model has no PrimaryPart:", newModel.Name)
            -- Try to set position of individual parts
            for _, part in ipairs(newModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CFrame = originalCFrame
                    break -- Only position the first part
                end
            end
        end
    elseif newModel:IsA("BasePart") then
        newModel.CFrame = originalCFrame
    end
    
    -- Replace old model with new model
    newModel.Parent = self.equipmentFolder
    equipment:Destroy()
    
    -- Fire event to notify clients about the upgrade
    self:NotifyClientsOfUpgrade(newModel.Name, upgradeLevel)
end

-- Save equipment upgrade data
function EquipmentUpgradeSystem:SaveEquipmentUpgradeData(equipmentId, upgradeLevel)
    -- Skip if no player data
    if not self.playerData then return end
    
    -- Get current equipment upgrade data
    local upgradeData = self.playerData:GetData("equipmentUpgrades") or {}
    
    -- Update equipment upgrade level
    upgradeData[equipmentId] = upgradeLevel
    
    -- Save data
    self.playerData:SetData("equipmentUpgrades", upgradeData)
end

-- Notify clients of equipment upgrade
function EquipmentUpgradeSystem:NotifyClientsOfUpgrade(equipmentId, upgradeLevel)
    -- Create a remote event for this if needed
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return end
    
    local upgradeNotification = events:FindFirstChild("EquipmentUpgradeNotification") or Instance.new("RemoteEvent")
    upgradeNotification.Name = "EquipmentUpgradeNotification"
    upgradeNotification.Parent = events
    
    -- Fire the event to all clients
    upgradeNotification:FireAllClients(equipmentId, upgradeLevel)
end

-- Get available upgrades for equipment
function EquipmentUpgradeSystem:GetAvailableUpgrades(equipmentId)
    -- Find the equipment
    local equipment = self.equipmentFolder:FindFirstChild(equipmentId)
    if not equipment then return nil end
    
    -- Get equipment type
    local equipmentType = equipment:GetAttribute("equipmentType")
    if not equipmentType or not UPGRADE_DATA[equipmentType] then return nil end
    
    -- Get current upgrade level
    local currentLevel = equipment:GetAttribute("upgradeLevel") or 0
    
    -- Get upgrade path
    local upgradePath = UPGRADE_DATA[equipmentType].upgradePath
    if currentLevel >= #upgradePath - 1 then return nil end
    
    -- Return available upgrade info
    return {
        nextLevel = currentLevel + 1,
        nextModelName = upgradePath[currentLevel + 2],
        cost = UPGRADE_DATA[equipmentType].costs[currentLevel + 1] or DEFAULT_UPGRADE_COST,
        revenueMultiplier = UPGRADE_DATA[equipmentType].revenueMultipliers[currentLevel + 2] or DEFAULT_REVENUE_MULTIPLIER
    }
end

-- Check if model fits in its designated space (optional check)
function EquipmentUpgradeSystem:CheckModelFit(equipmentType, model)
    -- This function is now optional since we're using direct positioning
    -- It can still be useful during development to verify that upgraded models
    -- aren't too different in size compared to originals
    
    -- Check if the model has a PrimaryPart (required for proper positioning)
    if model:IsA("Model") and not model.PrimaryPart then
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                model.PrimaryPart = part
                break
            end
        end
        
        if not model.PrimaryPart then
            warn("EquipmentUpgradeSystem: Model has no PrimaryPart, may not position correctly:", model.Name)
            return false
        end
    end
    
    -- Check size (optional)
    if self.verifyUpgradeSizes then
        -- Find bounding box for this equipment type (if exists)
        local boundingBox
        
        local boundingBoxFolder = self.tycoon:FindFirstChild("EquipmentBoundingBoxes")
        if boundingBoxFolder then
            boundingBox = boundingBoxFolder:FindFirstChild("BoundingBox_" .. equipmentType)
        end
        
        if boundingBox and boundingBox:IsA("BasePart") then
            -- Check if model fits in bounding box
            return EquipmentBoundingBox.ModelFitsInBoundingBox(model, boundingBox)
        end
    end
    
    -- If no bounding box or verification disabled, assume it fits
    return true
end

return EquipmentUpgradeSystem