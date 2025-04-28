--[[
    TileValidator.lua
    This module validates tile configurations and ensures proper tile setup.
    
    Created to fix "Tile Validation Failures" reported in RobloxIssues.txt
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Determine if we're on server or client
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

-- Find module across different paths
local function findModule(moduleName)
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Safe require helper
local function safeRequire(modulePath, fallback)
    if typeof(modulePath) ~= "Instance" then
        return fallback
    end
    
    local success, result = pcall(function()
        return require(modulePath)
    end)
    
    if not success then
        warn("TileValidator: Failed to require " .. modulePath:GetFullName() .. " - " .. tostring(result))
        return fallback
    end
    
    return result
end

-- Try to load dependencies
local EventBridge = safeRequire(findModule("EventBridge")) or { fireEvent = function() end, registerEvent = function() end }
local TycoonHelper = safeRequire(findModule("TycoonHelper"))

-- Register events with EventBridge
if EventBridge.registerEvent then
    EventBridge.registerEvent("TileValidator_ValidationFailed")
    EventBridge.registerEvent("TileValidator_ValidationFixed")
    EventBridge.registerEvent("TileValidator_ScanComplete")
end

-- Create the module
local TileValidator = {}

-- Version information
TileValidator.VERSION = "1.0.0"
TileValidator.isLoaded = true

-- Constants
local VALIDATION_INTERVAL = 60 -- seconds
local MAX_RETRIES = 3
local VALIDATION_RULES = {
    -- Tile must be anchored
    ["Anchored"] = {
        check = function(tile)
            return tile.Anchored == true
        end,
        fix = function(tile)
            tile.Anchored = true
            return true
        end
    },
    
    -- Tile must have collision enabled
    ["CanCollide"] = {
        check = function(tile)
            return tile.CanCollide == true
        end,
        fix = function(tile)
            tile.CanCollide = true
            return true
        end
    },
    
    -- Tile must be correctly positioned
    ["Position"] = {
        check = function(tile)
            -- Check that Y position isn't below 0
            return tile.Position.Y >= 0
        end,
        fix = function(tile)
            -- Fix Y position if it's below 0
            if tile.Position.Y < 0 then
                tile.Position = Vector3.new(tile.Position.X, 0, tile.Position.Z)
            end
            return true
        end
    },
    
    -- Tile must have the right size
    ["Size"] = {
        check = function(tile)
            -- Check that X and Z are at least 4x4
            return tile.Size.X >= 4 and tile.Size.Z >= 4
        end,
        fix = function(tile)
            -- Fix size if it's too small
            local newSizeX = math.max(tile.Size.X, 4)
            local newSizeZ = math.max(tile.Size.Z, 4)
            tile.Size = Vector3.new(newSizeX, tile.Size.Y, newSizeZ)
            return true
        end
    },
    
    -- Tile must have gym part positioned correctly if it exists
    ["GymPartPosition"] = {
        check = function(tile)
            for _, child in ipairs(tile:GetChildren()) do
                if child:IsA("Model") then
                    -- Check that model is positioned at the tile
                    return true -- This is just a placeholder, actual check would be more complex
                end
            end
            return true -- No gym part, so it passes
        end,
        fix = function(tile)
            for _, child in ipairs(tile:GetChildren()) do
                if child:IsA("Model") then
                    -- Fix model position
                    if child.PrimaryPart then
                        child:SetPrimaryPartCFrame(tile.CFrame)
                    else
                        child:MoveTo(tile.Position)
                    end
                end
            end
            return true
        end
    }
}

-- Initialize the TileValidator
function TileValidator.initialize()
    print("TileValidator: Initializing...")
    
    -- Start validation loop if on server
    if isServer then
        task.spawn(function()
            while true do
                task.wait(VALIDATION_INTERVAL)
                TileValidator.validateAllTiles()
            end
        end)
    end
    
    print("TileValidator: Initialized successfully")
    return true
end

-- Validate all tiles for all players
function TileValidator.validateAllTiles()
    if not isServer then
        warn("TileValidator: Cannot validate tiles on client")
        return false
    end
    
    local validationResults = {
        totalTiles = 0,
        validTiles = 0,
        fixedTiles = 0,
        failedTiles = 0
    }
    
    print("TileValidator: Starting validation of all tiles...")
    
    for _, player in ipairs(Players:GetPlayers()) do
        local playerResults = TileValidator.validatePlayerTiles(player)
        
        validationResults.totalTiles = validationResults.totalTiles + playerResults.totalTiles
        validationResults.validTiles = validationResults.validTiles + playerResults.validTiles
        validationResults.fixedTiles = validationResults.fixedTiles + playerResults.fixedTiles
        validationResults.failedTiles = validationResults.failedTiles + playerResults.failedTiles
    end
    
    print("TileValidator: Validation complete. Total: " .. validationResults.totalTiles .. 
          ", Valid: " .. validationResults.validTiles .. 
          ", Fixed: " .. validationResults.fixedTiles .. 
          ", Failed: " .. validationResults.failedTiles)
    
    if EventBridge.fireEvent then
        EventBridge.fireEvent("TileValidator_ScanComplete", validationResults)
    end
    
    return true
end

-- Validate all tiles for a player
function TileValidator.validatePlayerTiles(player)
    if not isServer then
        warn("TileValidator: Cannot validate tiles on client")
        return { totalTiles = 0, validTiles = 0, fixedTiles = 0, failedTiles = 0 }
    end
    
    if not player or not player:IsA("Player") then
        warn("TileValidator: Invalid player")
        return { totalTiles = 0, validTiles = 0, fixedTiles = 0, failedTiles = 0 }
    end
    
    local validationResults = {
        totalTiles = 0,
        validTiles = 0,
        fixedTiles = 0,
        failedTiles = 0
    }
    
    -- Get player's tycoon
    local tycoon
    
    if TycoonHelper and TycoonHelper.getTycoon then
        tycoon = TycoonHelper.getTycoon(player)
    else
        tycoon = player:FindFirstChild("Tycoon")
    end
    
    if not tycoon then
        return validationResults
    end
    
    -- Find all tiles in the tycoon
    for _, child in ipairs(tycoon:GetChildren()) do
        -- Skip non-part children (like folders)
        if not child:IsA("BasePart") then
            continue
        end
        
        -- Validate the tile
        validationResults.totalTiles = validationResults.totalTiles + 1
        
        local tileResult = TileValidator.validateTile(child)
        
        if tileResult.valid then
            validationResults.validTiles = validationResults.validTiles + 1
        elseif tileResult.fixed then
            validationResults.fixedTiles = validationResults.fixedTiles + 1
        else
            validationResults.failedTiles = validationResults.failedTiles + 1
        end
    end
    
    return validationResults
end

-- Validate a single tile
function TileValidator.validateTile(tile)
    if not tile or not tile:IsA("BasePart") then
        warn("TileValidator: Invalid tile")
        return { valid = false, fixed = false, violations = { "Invalid tile instance" } }
    end
    
    local result = {
        valid = true,
        fixed = false,
        violations = {},
        fixedIssues = {}
    }
    
    -- Check each validation rule
    for ruleName, rule in pairs(VALIDATION_RULES) do
        local isValid = rule.check(tile)
        
        if not isValid then
            result.valid = false
            table.insert(result.violations, ruleName)
            
            -- Try to fix the issue
            local fixed = rule.fix(tile)
            
            if fixed then
                table.insert(result.fixedIssues, ruleName)
                result.fixed = true
                
                if EventBridge.fireEvent then
                    EventBridge.fireEvent("TileValidator_ValidationFixed", {
                        tile = tile,
                        ruleName = ruleName
                    })
                end
            else
                -- If fixing failed, report the issue
                if EventBridge.fireEvent then
                    EventBridge.fireEvent("TileValidator_ValidationFailed", {
                        tile = tile,
                        ruleName = ruleName
                    })
                end
            end
        end
    end
    
    return result
end

-- Check gym part on a tile
function TileValidator.validateGymPart(tile)
    if not tile or not tile:IsA("BasePart") then
        warn("TileValidator: Invalid tile")
        return { valid = false, fixed = false, violations = { "Invalid tile instance" } }
    end
    
    local result = {
        valid = true,
        fixed = false,
        violations = {},
        fixedIssues = {}
    }
    
    -- Find model in tile
    local gymPart
    
    for _, child in ipairs(tile:GetChildren()) do
        if child:IsA("Model") then
            gymPart = child
            break
        end
    end
    
    -- No gym part, nothing to validate
    if not gymPart then
        return result
    end
    
    -- Check if the gym part is correctly positioned
    local isCorrectlyPositioned = false
    
    if gymPart.PrimaryPart then
        -- Get the distance between the primary part and tile center
        local distance = (gymPart.PrimaryPart.Position - tile.Position).Magnitude
        isCorrectlyPositioned = distance < 5 -- If within 5 studs, consider it valid
    else
        -- If no primary part, check the model's position
        local distance = (gymPart:GetModelCFrame().Position - tile.Position).Magnitude
        isCorrectlyPositioned = distance < 5
    end
    
    if not isCorrectlyPositioned then
        result.valid = false
        table.insert(result.violations, "GymPartPosition")
        
        -- Try to fix the position
        local fixed = false
        
        if gymPart.PrimaryPart then
            gymPart:SetPrimaryPartCFrame(tile.CFrame)
            fixed = true
        else
            gymPart:MoveTo(tile.Position)
            fixed = true
        end
        
        if fixed then
            result.fixed = true
            table.insert(result.fixedIssues, "GymPartPosition")
            
            if EventBridge.fireEvent then
                EventBridge.fireEvent("TileValidator_ValidationFixed", {
                    tile = tile,
                    gymPart = gymPart,
                    ruleName = "GymPartPosition"
                })
            end
        else
            -- If fixing failed, report the issue
            if EventBridge.fireEvent then
                EventBridge.fireEvent("TileValidator_ValidationFailed", {
                    tile = tile,
                    gymPart = gymPart,
                    ruleName = "GymPartPosition"
                })
            end
        end
    end
    
    return result
end

-- Initialize the module
TileValidator.initialize()

-- Register with registry system if available
if isServer then
    local CoreRegistry = safeRequire(findModule("CoreRegistry"))
    if CoreRegistry and CoreRegistry.registerSystem then
        CoreRegistry.registerSystem("TileValidator", TileValidator)
        print("TileValidator: Registered with CoreRegistry")
    end
end

return TileValidator
