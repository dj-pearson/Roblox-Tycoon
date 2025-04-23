--[[
    GymTycoonAutomation.server.luau - 
    
    Master automation script that combines all the automation tools into simple commands.
    This script serves as the central hub for all automation features, allowing you to:\n
    1. Run the entire automation process with a single command
    2. Choose between different automation workflows
    3. Configure automation options
    
    Usage: Run _G.AutomateGymTycoon() from the command bar

    Author: Created April 20, 2025
]]

local ServerStorage = game:GetService("ServerStorage")


-- Import automation modules
local AutoBuyTileSetup = require(script.Parent:FindFirstChild("AutoBuyTileSetup"))
local BuyTileConfigGenerator = require(script.Parent:FindFirstChild("BuyTileConfigGenerator"))
local BuyTileHitboxGenerator = require(script.Parent:FindFirstChild("BuyTileHitboxGenerator"))
local CoreRegistry = require(script.Parent.Parent:FindFirstChild("Core"):FindFirstChild("CoreRegistry") or {})
local ModelValidator = require(script.Parent.Parent:FindFirstChild("Core"):FindFirstChild("ModelValidation"):FindFirstChild("ModelValidator"))
local EquipmentManager = require(script.Parent.Parent:FindFirstChild("Core"):FindFirstChild("EquipmentManager"))

-- Get GymStructureIntegration if available
local GymStructureIntegration = CoreRegistry and CoreRegistry:GetSystem("GymStructureIntegration")
if not GymStructureIntegration then
    local gymStructureModule = script.Parent.Parent:FindFirstChild("Core"):FindFirstChild("GymStructureIntegration")
    if gymStructureModule then
        GymStructureIntegration = require(gymStructureModule)
    end
end

-- Default configuration
local AUTOMATION_CONFIG = {
    generateConfig = true,      -- Generate BuyTile config
    setupAttributes = true,     -- Set up attributes on models
    generateHitboxes = true,    -- Generate hitboxes
    analyzeStructure = true,    -- Analyze gym structure
    overrideExisting = false,   -- Override existing work
    showDebug = true,           -- Show debug output
    useProximityDetection = true, -- Use proximity for prerequisites
    adjustEconomy = true,       -- Automatically balance economy
    generateGymStructureJSON = false, -- Generate GymStructureJSON if not found.
    setupEquipment = true,      -- Setup the equipment
}

-- Run the full automation process
local function AutomateGymTycoon(config)
    config = config or {}

    -- Merge provided config with defaults
    local gymModel = workspace:FindFirstChild('GymParts') or workspace:FindFirstChild('Gym') or workspace:FindFirstChild('Tycoon') or workspace:FindFirstChild('GymTycoon')
    if not gymModel then
        warn("Gym Tycoon Model not found in workspace. Please ensure your Gym Tycoon Model is named 'GymParts', 'Gym', 'Tycoon', or 'GymTycoon'.")
        return
    end
    for key, value in pairs(config) do
        AUTOMATION_CONFIG[key] = value
    end

    print("===== GYM TYCOON AUTOMATION =====")
    print("Starting complete automation process...")

    local startTime = os.clock()
    local stats = {
        modelAttributes = 0,
        hitboxes = 0,
        config = 0,
        structure = {},
    }
    -- Step 0: Validate Models
    print("\n== VALIDATING MODELS ==")
    local validationResults = ModelValidator.ValidateAllModels(gymModel)
    if not validationResults.valid then
        ModelValidator.PrintIssues(validationResults)
        warn("Model validation failed. Stopping automation process.")
        return
    else
        print("✓ All models passed validation!")
    end

    --Tag models by category
    ModelValidator.TagModelsByCategory(gymModel)
    
    -- Step 0.5: Try to fix common model issues
    if _G.FixModelIssues then
        print("\n== FIXING MODEL ISSUES ==")
        local fixResults = _G.FixModelIssues(gymModel, true) --Attempt to fix without asking
        print("Fixed: ", fixResults.fixed)
        print("Not fixed: ", fixResults.notFixed)
    end
    
        -- Step 1: Analyze Gym Structure if available and enabled
    if AUTOMATION_CONFIG.analyzeStructure and GymStructureIntegration then
        print("\n== ANALYZING GYM STRUCTURE ==")
        local structureStats = GymStructureIntegration:AnalyzeGymStructure(AUTOMATION_CONFIG.showDebug)
        if _G.GenerateGymStructureJSON and AUTOMATION_CONFIG.generateGymStructureJSON then
            _G.GenerateGymStructureJSON()
        end
        if structureStats and next(structureStats) then
            stats.structure = structureStats
        end
    end

    -- Step 1: Analyze Gym Structure if available and enabled
    if AUTOMATION_CONFIG.analyzeStructure and GymStructureIntegration then
        print("\n== ANALYZING GYM STRUCTURE ==")
        
        if typeof(GymStructureIntegration.SyncGymStructure) == "function" then
            local structureStats = GymStructureIntegration:SyncGymStructure(AUTOMATION_CONFIG.showDebug)
            if structureStats and next(structureStats) then
                local roomCounts = {}
                for roomType, count in pairs(structureStats) do
                    table.insert(roomCounts, string.format("%s: %d", roomType, count))
                end
                stats.structure = structureStats
                local roomsString = table.concat(roomCounts, ", ")
                print("Analyzed gym structure: " .. roomsString)
            end
        else
            print("GymStructureIntegration found but SyncGymStructure method not available")
        end
    end
    
    -- Step 0.7: Set up equipment if enabled
    if AUTOMATION_CONFIG.setupEquipment then
        print("\n== SETTING UP EQUIPMENT ==")
        EquipmentManager.SetupEquipment(gymModel, AUTOMATION_CONFIG)
    end
    
    -- Step 2: Generate BuyTile Config if enabled
    if AUTOMATION_CONFIG.generateConfig then
        print("\n== GENERATING BUYTILE CONFIG ==")
        local config = BuyTileConfigGenerator.GenerateConfig()
        if config then
            stats.config = #config:split("\n")
            print("Generated BuyTile configuration with approximately " .. math.floor(stats.config / 10) .. " tiles")
        end
    end
    
    -- Step 3: Set up attributes on models if enabled
    if AUTOMATION_CONFIG.setupAttributes then
        print("\n== SETTING UP MODEL ATTRIBUTES ==")
        local setupCount = AutoBuyTileSetup.AutoSetupAllTycoons()
        if setupCount then
            stats.modelAttributes = setupCount
            print("Set up attributes for " .. setupCount .. " models")
        end
    end

    -- Step 4: Generate hitboxes if enabled
    if AUTOMATION_CONFIG.generateHitboxes then
        print("\n== GENERATING HITBOXES ==")

        -- Configure hitbox visibility based on debug setting
        BuyTileHitboxGenerator.SetHitboxConfig({
            showDebugBoxes = AUTOMATION_CONFIG.showDebug,
        })
        
        local hitboxStats = BuyTileHitboxGenerator.GenerateAllHitboxes()
        if hitboxStats then
            stats.hitboxes = hitboxStats.hitboxesCreated + hitboxStats.hitboxesUpdated
            print("Generated/updated " .. stats.hitboxes .. " hitboxes")
        end
    end

    -- Report completion
    local elapsedTime = os.clock() - startTime
    print("\n===== AUTOMATION COMPLETE =====")
    print("Process completed in " .. string.format("%.2f", elapsedTime) .. " seconds")
    print("• Structure: " .. (#stats.structure > 0 and table.concat(stats.structure, ", ") or "No rooms") .. " analyzed")
    print("• Config: ~" .. math.floor(stats.config / 10) .. " tile definitions generated")
    print("• Attributes: " .. stats.modelAttributes .. " models set up")
    print("• Hitboxes: " .. stats.hitboxes .. " hitboxes created/updated")
    
    -- Instructions for next steps
    print("\n== NEXT STEPS ==")
    print("1. Check ServerStorage.GeneratedBuyTileConfig for the generated configuration")
    print("2. Verify hitboxes by walking around the gym")
    print("3. Test purchasing tiles to ensure everything works correctly")
    
    return stats
end

-- Run just structure analysis
local function AnalyzeGymStructure(verbose)
    if GymStructureIntegration then
        print("== ANALYZING GYM STRUCTURE ==")
        if typeof(GymStructureIntegration.SyncGymStructure) == "function" then
            return GymStructureIntegration:SyncGymStructure(verbose)
        else
            print("GymStructureIntegration found but SyncGymStructure method not available")
        end
    else
        print("GymStructureIntegration module not found")
    end
end

-- Set configuration options
local function SetAutomationConfig(config)
    for key, value in pairs(config) do
        if AUTOMATION_CONFIG[key] ~= nil then
            AUTOMATION_CONFIG[key] = value
        else
            warn("GymTycoonAutomation: Unknown config option: " .. key)
        end
    end

    print("GymTycoonAutomation: Configuration updated")
    return AUTOMATION_CONFIG
end

-- Register global functions for command bar
_G.AutomateGymTycoon = function(config)
    return AutomateGymTycoon(config)
end

_G.AnalyzeGymStructure = function(verbose)
    return AnalyzeGymStructure(verbose)
end

_G.SetAutomationConfig = function(config)
    return SetAutomationConfig(config)
end

-- Return module
return {
    AutomateGymTycoon = AutomateGymTycoon,
    AnalyzeGymStructure = AnalyzeGymStructure,
    SetAutomationConfig = SetAutomationConfig,
    AUTOMATION_CONFIG = AUTOMATION_CONFIG
}