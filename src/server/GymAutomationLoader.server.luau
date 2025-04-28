--[[
    GymAutomationLoader.server.luau
    
    A simple utility script to ensure the GymAutomation system is loaded early
    and global functions are properly registered. This fixes the issues with
    _G function availability for automation scripts.
    
    Created: April 27, 2025
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    CORE_REGISTRY_TIMEOUT = 10, -- seconds
    AUTO_RESTART_DELAY = 5 -- seconds
}

-- Only run in Studio
if not RunService:IsStudio() then
    return
end

-- Debug logging
local function log(message)
    if CONFIG.DEBUG_LOGGING then
        print("[GymAutomationLoader] " .. message)
    end
end

-- Find or load a module
local function findAndRequireModule(moduleName, paths)
    for _, path in ipairs(paths) do
        if path and path:FindFirstChild(moduleName) then
            local moduleScript = path[moduleName]
            if moduleScript:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(moduleScript)
                end)
                
                if success and result then
                    log("Successfully loaded " .. moduleName .. " from " .. path:GetFullName())
                    return result
                else
                    warn("[GymAutomationLoader] Failed to load " .. moduleName .. ": " .. tostring(result))
                end
            end
        end
    end
    
    warn("[GymAutomationLoader] Could not find " .. moduleName .. " in any search path")
    return nil
end

-- Safe wait for CoreRegistry with timeout
local function waitForCoreRegistry()
    log("Waiting for CoreRegistry...")
    
    -- First check if it's already in global scope
    if _G.CoreRegistry then
        log("CoreRegistry already available in global scope")
        return _G.CoreRegistry
    end
    
    -- Try the new ModuleLoaderHelper first
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if shared and shared:FindFirstChild("ModuleLoaderHelper") then
        local success, ModuleLoaderHelper = pcall(function()
            return require(shared.ModuleLoaderHelper)
        end)
        
        if success and ModuleLoaderHelper and ModuleLoaderHelper.GetCoreRegistry then
            local registry = ModuleLoaderHelper.GetCoreRegistry()
            if registry then
                log("CoreRegistry found via ModuleLoaderHelper")
                return registry
            end
        end
    end
    
    -- Try direct lookup in core folder
    local core = ServerScriptService:FindFirstChild("Core")
    if core and core:FindFirstChild("CoreRegistry") then
        local success, registry = pcall(function()
            return require(core.CoreRegistry)
        end)
        
        if success and registry then
            log("CoreRegistry found in Core folder")
            return registry
        end
    end
    
    -- Wait with timeout
    local startTime = os.clock()
    while os.clock() - startTime < CONFIG.CORE_REGISTRY_TIMEOUT do
        -- Check global scope again
        if _G.CoreRegistry then
            log("CoreRegistry appeared in global scope after " .. (os.clock() - startTime) .. " seconds")
            return _G.CoreRegistry
        end
        
        task.wait(0.5)
    end
    
    warn("[GymAutomationLoader] Timed out waiting for CoreRegistry")
    return nil
end

-- Load GymAutomationManager
local function loadGymAutomation()
    log("Loading GymAutomation system...")
    
    -- Define paths to search for the module
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and 
            ServerScriptService.src.server:FindFirstChild("Core"),
        ServerScriptService
    }
    
    -- First try the new GymAutomationManager
    local gymAutomation = findAndRequireModule("GymAutomationManager", searchPaths)
    
    -- Fall back to original GymAutomation if needed
    if not gymAutomation then
        log("GymAutomationManager not found, trying GymAutomation")
        gymAutomation = findAndRequireModule("GymAutomation", searchPaths)
    end
    
    -- Check if we found GymAutomation
    if not gymAutomation then
        warn("[GymAutomationLoader] Failed to find any GymAutomation module")
        return nil
    end
    
    return gymAutomation
end

-- Check if global functions are registered
local function checkGlobalFunctions()
    local requiredFunctions = {
        "AutomateGym",
        "AutomateAllGyms",
        "ProcessEquipment",
        "BatchProcessModels"
    }
    
    local missing = {}
    for _, funcName in ipairs(requiredFunctions) do
        if not _G[funcName] then
            table.insert(missing, funcName)
        end
    end
    
    if #missing > 0 then
        warn("[GymAutomationLoader] Missing global functions: " .. table.concat(missing, ", "))
        return false
    end
    
    log("All required global functions are registered")
    return true
end

-- Register GymAutomation with CoreRegistry
local function registerWithCoreRegistry(gymAutomation)
    if not gymAutomation then 
        warn("[GymAutomationLoader] Cannot register nil GymAutomation")
        return false
    end
    
    local CoreRegistry = waitForCoreRegistry()
    if not CoreRegistry then 
        warn("[GymAutomationLoader] Cannot register - CoreRegistry not found")
        return false
    end
    
    if typeof(CoreRegistry.registerSystem) ~= "function" then
        warn("[GymAutomationLoader] CoreRegistry missing registerSystem method")
        return false
    end
    
    -- Check if already registered
    if CoreRegistry.hasSystem and CoreRegistry.hasSystem("GymAutomation") then
        log("GymAutomation already registered with CoreRegistry")
        return true
    end
    
    -- Register the system
    CoreRegistry.registerSystem("GymAutomation", gymAutomation, {})
    log("Successfully registered GymAutomation with CoreRegistry")
    
    return true
end

-- Main loader function
local function main()
    log("Starting GymAutomation loader...")
    
    -- Load GymAutomation
    local gymAutomation = loadGymAutomation()
    if not gymAutomation then
        warn("[GymAutomationLoader] Failed to load GymAutomation, scheduling retry...")
        task.delay(CONFIG.AUTO_RESTART_DELAY, main)
        return false
    end
    
    -- Register with CoreRegistry
    registerWithCoreRegistry(gymAutomation)
    
    -- Check global functions
    local functionsOK = checkGlobalFunctions()
    if not functionsOK then
        -- Try to initialize GymAutomation if it has an Initialize method
        if typeof(gymAutomation.Initialize) == "function" then
            log("Re-initializing GymAutomation...")
            gymAutomation:Initialize()
            
            -- Check again
            functionsOK = checkGlobalFunctions()
        end
    end
    
    if functionsOK then
        log("GymAutomation loaded successfully with all required global functions")
        print("\n===== GYM TYCOON AUTOMATION READY =====")
        print("Available commands:")
        print("  _G.AutomateGym([tycoonName]) - Automate a specific gym")
        print("  _G.AutomateAllGyms() - Automate all gyms in the workspace")
        print("  _G.ProcessEquipment([tycoonName]) - Process equipment in a gym")
        print("  _G.BatchProcessModels() - Run all automation functions")
        print("======================================\n")
    else
        -- Create fallbacks for most critical functions
        log("Creating fallback global functions...")
        
        if not _G.AutomateGym then
            _G.AutomateGym = function(tycoonName)
                if gymAutomation and typeof(gymAutomation.AutomateGym) == "function" then
                    return gymAutomation:AutomateGym(tycoonName)
                else
                    warn("GymAutomation module not fully initialized. Please try again in a moment.")
                    return false
                end
            end
            log("Created fallback for _G.AutomateGym")
        end
        
        if not _G.AutomateAllGyms then
            _G.AutomateAllGyms = function()
                if gymAutomation and typeof(gymAutomation.AutomateAllGyms) == "function" then
                    return gymAutomation:AutomateAllGyms()
                else
                    warn("GymAutomation module not fully initialized. Please try again in a moment.")
                    return false
                end
            end
            log("Created fallback for _G.AutomateAllGyms")
        end
        
        if not _G.ProcessEquipment then
            _G.ProcessEquipment = function(tycoonName)
                if gymAutomation and typeof(gymAutomation.ProcessEquipment) == "function" then
                    return gymAutomation:ProcessEquipment(tycoonName)
                else
                    warn("GymAutomation module not fully initialized. Please try again in a moment.")
                    return false
                end
            end
            log("Created fallback for _G.ProcessEquipment")
        end
        
        if not _G.BatchProcessModels then
            _G.BatchProcessModels = function()
                if gymAutomation and typeof(gymAutomation.AutomateAllGyms) == "function" then
                    local results = gymAutomation:AutomateAllGyms()
                    if gymAutomation.ProcessEquipment then
                        gymAutomation:ProcessEquipment()
                    end
                    return results
                else
                    warn("GymAutomation module not fully initialized. Please try again in a moment.")
                    return false
                end
            end
            log("Created fallback for _G.BatchProcessModels")
        end
    end
    
    return true
end

-- Run the main loader
local success, result = pcall(main)
if not success then
    warn("[GymAutomationLoader] Error during loading: " .. tostring(result))
    task.delay(CONFIG.AUTO_RESTART_DELAY, function()
        log("Retrying after error...")
        main()
    end)
end
