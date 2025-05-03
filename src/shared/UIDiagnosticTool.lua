--[[
    UIDiagnosticTool.lua
    
    A tool that automatically diagnoses and fixes common UI issues in the game.
    This is especially focused on image assets and buttons.
    
    Created by: AI Assistant
    Created on: May 3, 2025
]]

local UIDiagnosticTool = {}

-- Configuration
UIDiagnosticTool.config = {
    autoRunDelay = 5,      -- Seconds after game loads to run auto-diagnosis
    scanUIOnStart = true,  -- Whether to scan UI on startup
    fixProblems = true,    -- Whether to attempt fixes automatically
    validateAssets = true, -- Whether to validate asset IDs
    logLevel = 2           -- 0: None, 1: Errors only, 2: Warnings + Errors, 3: All
}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

-- Try to get UIComponentFactory
local UIComponentFactory
local success, result = pcall(function()
    return require(ReplicatedStorage.shared.UIComponentFactory)
end)

if success then
    UIComponentFactory = result
else
    warn("[UIDiagnosticTool] Could not load UIComponentFactory: " .. tostring(result))
end

-- Basic logging function
local function log(level, message)
    if level <= UIDiagnosticTool.config.logLevel then
        if level == 1 then
            error("[UIDiagnosticTool] " .. message)
        elseif level == 2 then
            warn("[UIDiagnosticTool] " .. message)
        else
            print("[UIDiagnosticTool] " .. message)
        end
    end
end

-- Validate asset ID format
local function validateAssetId(assetId)
    if not assetId or assetId == "" then 
        return false, "Empty asset ID"
    end
    
    -- Check format
    if not tostring(assetId):match("^rbxassetid://[0-9]+$") then
        return false, "Invalid format: " .. tostring(assetId)
    end
    
    -- Basic length validation for asset IDs
    local id = assetId:match("^rbxassetid://([0-9]+)$")
    if id and #id > 15 then
        return false, "ID too long: " .. #id .. " digits"
    end
    
    return true, nil
end

-- Scan all UI elements in a container for issues
function UIDiagnosticTool.scanUIContainer(container)
    if not container then
        log(2, "No container provided for scanUIContainer")
        return {
            total = 0,
            issues = 0,
            fixed = 0,
            details = {}
        }
    end
    
    -- Use UIComponentFactory's diagnostic if available 
    if UIComponentFactory and UIComponentFactory.runImageDiagnostics then
        log(3, "Using UIComponentFactory diagnostics for " .. container:GetFullName())
        return UIComponentFactory.runImageDiagnostics(container)
    end
    
    -- Manual scan if UIComponentFactory is not available
    local results = {
        total = 0,
        issues = 0,
        fixed = 0,
        details = {}
    }
    
    for _, instance in pairs(container:GetDescendants()) do
        if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
            results.total = results.total + 1
            
            local assetId = instance.Image
            local isValid, issue = validateAssetId(assetId)
            
            if not isValid then
                results.issues = results.issues + 1
                
                table.insert(results.details, {
                    instance = instance:GetFullName(),
                    property = "Image",
                    value = assetId,
                    issue = issue,
                    fixed = false
                })
                
                -- Try to fix if configured to do so
                if UIDiagnosticTool.config.fixProblems then
                    -- Simple fix: use a default image if invalid
                    if issue == "Empty asset ID" then
                        instance.Image = "rbxassetid://8093763464" -- Menu icon as default
                        results.fixed = results.fixed + 1
                        
                        -- Update the details entry
                        results.details[#results.details].fixed = true
                        results.details[#results.details].fixedValue = instance.Image
                    elseif issue:match("ID too long") then
                        -- Try to trim the ID to a reasonable length
                        local idPrefix = "rbxassetid://"
                        local rawId = assetId:match("^rbxassetid://([0-9]+)$")
                        
                        if rawId then
                            -- Trim to 10 digits max (reasonable for asset IDs)
                            local trimmedId = rawId:sub(1, 10)
                            instance.Image = idPrefix .. trimmedId
                            results.fixed = results.fixed + 1
                            
                            -- Update the details entry
                            results.details[#results.details].fixed = true
                            results.details[#results.details].fixedValue = instance.Image
                        end
                    end
                end
            end
        end
    end
    
    return results
end

-- Scan all player GUIs
function UIDiagnosticTool.scanPlayerGUIs(player)
    player = player or Players.LocalPlayer
    
    if not player then
        log(2, "No player available for scanPlayerGUIs")
        return
    end
    
    log(3, "Scanning GUIs for player: " .. player.Name)
    
    local results = {
        playerGui = UIDiagnosticTool.scanUIContainer(player:FindFirstChild("PlayerGui")),
        starterGui = UIDiagnosticTool.scanUIContainer(game:GetService("StarterGui"))
    }
    
    -- Log summary
    log(3, string.format("PlayerGui scan results: %d total, %d issues, %d fixed", 
        results.playerGui.total, results.playerGui.issues, results.playerGui.fixed))
    
    log(3, string.format("StarterGui scan results: %d total, %d issues, %d fixed",
        results.starterGui.total, results.starterGui.issues, results.starterGui.fixed))
    
    return results
end

-- Run diagnostics on all UI in the game
function UIDiagnosticTool.runComprehensiveDiagnostics()
    log(3, "Starting comprehensive UI diagnostics")
    
    -- Collect all diagnosed issues
    local results = {
        playerGUIs = {},
        menuButtons = nil,
        coreGUIs = nil,
        total = {
            scanned = 0,
            issues = 0,
            fixed = 0
        }
    }
    
    -- Scan each connected player's GUIs
    for _, player in ipairs(Players:GetPlayers()) do
        results.playerGUIs[player.Name] = UIDiagnosticTool.scanPlayerGUIs(player)
    end
    
    -- Scan menu buttons if the handler is available
    local menuButtonsHandler = ReplicatedStorage:FindFirstChild("MenuButtonsHandler") or 
                               game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("MenuButtonsHandler")
    
    if menuButtonsHandler then
        log(3, "Scanning menu buttons")
        
        local success, menuResults = pcall(function()
            local module = require(menuButtonsHandler)
            
            if module and module.runDiagnostics then
                return module.runDiagnostics()
            end
            return nil
        end)
        
        if success and menuResults then
            results.menuButtons = menuResults
        end
    end
    
    -- Scan core GUIs
    results.coreGUIs = UIDiagnosticTool.scanUIContainer(game:GetService("CoreGui"))
    
    -- Calculate totals
    for playerName, playerResults in pairs(results.playerGUIs) do
        if playerResults.playerGui then
            results.total.scanned = results.total.scanned + playerResults.playerGui.total
            results.total.issues = results.total.issues + playerResults.playerGui.issues
            results.total.fixed = results.total.fixed + playerResults.playerGui.fixed
        end
        
        if playerResults.starterGui then
            results.total.scanned = results.total.scanned + playerResults.starterGui.total
            results.total.issues = results.total.issues + playerResults.starterGui.issues
            results.total.fixed = results.total.fixed + playerResults.starterGui.fixed
        end
    end
    
    if results.menuButtons then
        results.total.scanned = results.total.scanned + results.menuButtons.total
        results.total.issues = results.total.issues + results.menuButtons.failed or 0
    end
    
    if results.coreGUIs then
        results.total.scanned = results.total.scanned + results.coreGUIs.total
        results.total.issues = results.total.issues + results.coreGUIs.issues
        results.total.fixed = results.total.fixed + results.coreGUIs.fixed
    end
    
    -- Log comprehensive results
    log(3, string.format("Comprehensive diagnostics complete: %d elements scanned, %d issues found, %d issues fixed",
        results.total.scanned, results.total.issues, results.total.fixed))
    
    if results.total.issues > 0 then
        log(2, string.format("%d UI issues still need attention", results.total.issues - results.total.fixed))
    else
        log(3, "UI looking good! No outstanding issues found.")
    end
    
    return results
end

-- Auto-run diagnostics after a delay
if UIDiagnosticTool.config.scanUIOnStart then
    spawn(function()
        wait(UIDiagnosticTool.config.autoRunDelay)
        UIDiagnosticTool.runComprehensiveDiagnostics()
    end)
end

return UIDiagnosticTool
