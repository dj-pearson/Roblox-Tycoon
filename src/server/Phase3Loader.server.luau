--[[
    Phase3Loader.server.luau
    
    Initialization module for Phase 3 fixes addressing:
    1. Data restoration issues
    2. Asset loading failures
    
    This script ensures that all Phase 3 fixes are properly loaded and initialized.
    
    Created: April 27, 2025
]]

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    DEBUG_MODE = true,
    LOAD_DATA_FIX = true,
    LOAD_SOUND_FIX = true,
    LOAD_ASSET_DIAGNOSTICS = true,
    AUTO_RUN = true
}

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_MODE then
        print("[Phase3Loader] " .. message)
    end
end

-- The Phase 3 loader module
local Phase3Loader = {}

-- Check if module exists
local function moduleExists(path)
    if not path then return false end
    
    local success, _ = pcall(function()
        return require(path)
    end)
    
    return success
end

-- Create folder if it doesn't exist
local function ensureFolder(parent, name)
    if not parent:FindFirstChild(name) then
        local folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        return folder
    end
    
    return parent:FindFirstChild(name)
end

-- Initialize data restoration fixes
function Phase3Loader:InitializeDataFix()
    if not CONFIG.LOAD_DATA_FIX then
        log("Skipping data fix initialization (disabled in config)")
        return false
    end
    
    log("Initializing data restoration fixes...")
    
    -- Ensure paths exist
    local corePath = ServerScriptService:FindFirstChild("Core")
    if not corePath then
        corePath = ensureFolder(ServerScriptService, "Core")
    end
    
    local essentialsPath = ServerScriptService:FindFirstChild("Essentials")
    if not essentialsPath then
        essentialsPath = ensureFolder(ServerScriptService, "Essentials")
    end
    
    -- Check for DataManagerFix
    local dataManagerFixPath = corePath:FindFirstChild("DataManagerFix")
    
    if not dataManagerFixPath or not moduleExists(dataManagerFixPath) then
        log("DataManagerFix not found or failed to load")
        return false
    end
    
    -- Check for PlayerProgressRestoration
    local progressRestorationPath = essentialsPath:FindFirstChild("PlayerProgressRestoration")
    
    if not progressRestorationPath or not moduleExists(progressRestorationPath) then
        log("PlayerProgressRestoration not found or failed to load")
        return false
    end
    
    -- Load the modules
    local dataManagerFix = require(dataManagerFixPath)
    local progressRestoration = require(progressRestorationPath)
    
    if not dataManagerFix or not progressRestoration then
        log("Failed to load data restoration modules")
        return false
    end
    
    log("Data restoration fixes initialized successfully")
    return true
end

-- Initialize sound system fixes
function Phase3Loader:InitializeSoundFix()
    if not CONFIG.LOAD_SOUND_FIX then
        log("Skipping sound fix initialization (disabled in config)")
        return false
    end
    
    log("Initializing sound system fixes...")
    
    -- Ensure paths exist
    local sharedPath = ReplicatedStorage:FindFirstChild("shared")
    if not sharedPath then
        sharedPath = ensureFolder(ReplicatedStorage, "shared")
    end
    
    -- Check for SoundSystemManager
    local soundSystemPath = sharedPath:FindFirstChild("SoundSystemManager")
    
    if not soundSystemPath or not moduleExists(soundSystemPath) then
        log("SoundSystemManager not found or failed to load")
        return false
    end
    
    -- Check for SoundAssetValidator
    local soundValidatorPath = sharedPath:FindFirstChild("SoundAssetValidator")
    
    if not soundValidatorPath or not moduleExists(soundValidatorPath) then
        log("SoundAssetValidator not found or failed to load")
        return false
    end
    
    -- Create PlaySoundEvent if it doesn't exist
    if not ReplicatedStorage:FindFirstChild("PlaySoundEvent") then
        local soundEvent = Instance.new("RemoteEvent")
        soundEvent.Name = "PlaySoundEvent"
        soundEvent.Parent = ReplicatedStorage
        log("Created missing PlaySoundEvent")
    end
    
    -- Load modules
    local soundSystem = require(soundSystemPath)
    local soundValidator = require(soundValidatorPath)
    
    if not soundSystem or not soundValidator then
        log("Failed to load sound system modules")
        return false
    end
    
    -- Run sound asset scan if we're the server
    if RunService:IsServer() then
        task.spawn(function()
            log("Starting sound asset scan")
            -- Wait a bit for the game to load more assets
            task.wait(5)
            
            local fixedCount = soundValidator.scanAndFixSoundAssets()
            log("Sound asset scan complete: Fixed " .. fixedCount .. " sound assets")
        end)
    end
    
    log("Sound system fixes initialized successfully")
    return true
end

-- Initialize asset diagnostics system
function Phase3Loader:InitializeAssetDiagnostics()
    if not CONFIG.LOAD_ASSET_DIAGNOSTICS then
        log("Skipping asset diagnostics initialization (disabled in config)")
        return false
    end
    
    if not RunService:IsServer() then
        log("Asset diagnostics initialization skipped (client-only)")
        return false
    end
    
    log("Initializing asset diagnostics system...")
    
    -- Check for AssetFailureLogger
    local essentialsPath = ServerScriptService:FindFirstChild("Essentials")
    if not essentialsPath then
        essentialsPath = ensureFolder(ServerScriptService, "Essentials")
        log("Created missing Essentials folder")
    end
    
    local assetLoggerPath = essentialsPath:FindFirstChild("AssetFailureLogger")
    if not assetLoggerPath or not moduleExists(assetLoggerPath) then
        log("AssetFailureLogger not found or failed to load")
        return false
    end
    
    -- Create the report event if it doesn't exist
    if not ReplicatedStorage:FindFirstChild("AssetLoadFailureReport") then
        local reportEvent = Instance.new("RemoteEvent")
        reportEvent.Name = "AssetLoadFailureReport"
        reportEvent.Parent = ReplicatedStorage
        log("Created AssetLoadFailureReport event")
    end
    
    -- Load the module
    local assetLogger = require(assetLoggerPath)
    
    if not assetLogger then
        log("Failed to load AssetFailureLogger module")
        return false
    end
    
    log("Asset diagnostics system initialized")
    return true
end

-- Initialize all fixes
function Phase3Loader:Initialize()
    log("Initializing Phase 3 fixes...")
    
    local dataFixResult = self:InitializeDataFix()
    local soundFixResult = self:InitializeSoundFix()
    local diagnosticsResult = self:InitializeAssetDiagnostics()
    
    log("Phase 3 initialization complete:")
    log("- Data Fix: " .. (dataFixResult and "SUCCESS" or "FAILED"))
    log("- Sound Fix: " .. (soundFixResult and "SUCCESS" or "FAILED"))
    log("- Asset Diagnostics: " .. (diagnosticsResult and "SUCCESS" or "FAILED"))
    
    return dataFixResult and soundFixResult and diagnosticsResult
end

-- Auto-run if enabled
if CONFIG.AUTO_RUN then
    Phase3Loader:Initialize()
end

return Phase3Loader
