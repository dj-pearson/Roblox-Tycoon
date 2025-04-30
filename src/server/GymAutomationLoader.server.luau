--[[
    GymAutomationLoader.server.luau
    
    A simple utility script to ensure the GymAutomation system is loaded early
    and global functions are properly registered. This fixes the issues with
    function availability for automation scripts.
    
    Updated: April 30, 2025
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- Configuration
local CONFIG = {
    DEBUG_LOGGING = true,
    AUTO_RESTART_DELAY = 5, -- seconds
    MAX_RETRY_ATTEMPTS = 5
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

-- Try to find GymAutomationManager in different locations
local function findGymAutomationModule(moduleName)
    -- Define all possible search paths for the module
    local searchPaths = {
        -- Server locations
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild(moduleName),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild(moduleName),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("GymAutomation"),
        ServerScriptService:FindFirstChild("GymAutomation"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server"),
        ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("GymAutomation"),
        
        -- Server Storage locations
        ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server"),
        ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server") and ServerStorage.src.server:FindFirstChild("Core"),
        ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server") and ServerStorage.src.server:FindFirstChild(moduleName),
        ServerStorage:FindFirstChild("src") and ServerStorage.src:FindFirstChild("server") and ServerStorage.src.server:FindFirstChild("GymAutomation"),
        ServerStorage:FindFirstChild("GymAutomation"),
        ServerStorage:FindFirstChild("Systems"),
        ServerStorage:FindFirstChild("Core"),
        
        -- New paths for ServerStorage structure
        ServerStorage:FindFirstChild("GymStructure"),
        ServerStorage:FindFirstChild("GymStructure") and ServerStorage.GymStructure:FindFirstChild(moduleName),
        ServerStorage:FindFirstChild("GymStructure") and ServerStorage.GymStructure:FindFirstChild("Core"),
        ServerStorage:FindFirstChild("BuyTiles"),
        ServerStorage:FindFirstChild("BuyTiles") and ServerStorage.BuyTiles:FindFirstChild(moduleName),
        ServerStorage:FindFirstChild("BuyTiles") and ServerStorage.BuyTiles:FindFirstChild("Systems"),
        
        -- ReplicatedStorage locations
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild(moduleName),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared") and ReplicatedStorage.src.shared:FindFirstChild(moduleName),
        
        -- Current script location (script.Parent)
        script.Parent,
        script.Parent and script.Parent.Parent,
        script.Parent and script.Parent:FindFirstChild("Core"),
        script.Parent and script.Parent:FindFirstChild("GymAutomation")
    }
    
    -- Try to find the module in each search path
    for _, path in ipairs(searchPaths) do
        if path then
            -- Check for the module directly in this path
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                log("Found " .. moduleName .. " at: " .. module:GetFullName())
                local success, result = pcall(function()
                    return require(module)
                end)
                if success and result then
                    return result
                end
            end
            
            -- Check for the module with .luau extension
            module = path:FindFirstChild(moduleName .. ".luau")
            if module and module:IsA("ModuleScript") then
                log("Found " .. moduleName .. ".luau at: " .. module:GetFullName())
                local success, result = pcall(function()
                    return require(module)
                end)
                if success and result then
                    return result
                end
            end
            
            -- Check for the module with .server.luau extension
            module = path:FindFirstChild(moduleName .. ".server.luau")
            if module and module:IsA("ModuleScript") then
                log("Found " .. moduleName .. ".server.luau at: " .. module:GetFullName())
                local success, result = pcall(function()
                    return require(module)
                end)
                if success and result then
                    return result
                end
            end
        end
    end
    
    warn("[GymAutomationLoader] Could not find " .. moduleName .. " in any search path")
    return nil
end

-- Load GymAutomation module
local function loadGymAutomation()
    log("Loading GymAutomation system...")
    
    -- First try the new GymAutomationManager
    local gymAutomation = findGymAutomationModule("GymAutomationManager")
    
    -- Fall back to original GymAutomation if needed
    if not gymAutomation then
        log("GymAutomationManager not found, trying GymAutomation")
        gymAutomation = findGymAutomationModule("GymAutomation")
    end
    
    -- Check if we found GymAutomation
    if not gymAutomation then
        warn("[GymAutomationLoader] Failed to find any GymAutomation module")
        return nil
    end
    
    return gymAutomation
end

-- Try to get CoreRegistry through different methods
local function getCoreRegistry()
    -- Try to use ModuleLoader if available
    local moduleLoader = findGymAutomationModule("ModuleLoader")
    if moduleLoader and typeof(moduleLoader.loadModule) == "function" then
        local coreRegistry = moduleLoader.loadModule("CoreRegistry")
        if coreRegistry then
            log("Found CoreRegistry using ModuleLoader")
            return coreRegistry
        end
    end
    
    -- Try to find it in shared scope
    local success, coreRegistry = pcall(function()
        return require(ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("CoreRegistry"))
    end)
    if success and coreRegistry then
        log("Found CoreRegistry in ReplicatedStorage.shared")
        return coreRegistry
    end
    
    -- Try to find it directly in ServerScriptService paths
    local coreRegistryModule = findGymAutomationModule("CoreRegistry")
    if coreRegistryModule then
        log("Found CoreRegistry through direct path search")
        return coreRegistryModule
    end
    
    warn("[GymAutomationLoader] CoreRegistry not found")
    return nil
end

-- Register automation functions in shared context
local function registerAutomationFunctions(gymAutomation)
    if not gymAutomation then
        return false
    end

    local sharedContext = ReplicatedStorage:FindFirstChild("shared")
    if not sharedContext then
        sharedContext = Instance.new("Folder")
        sharedContext.Name = "shared"
        sharedContext.Parent = ReplicatedStorage
    end
    
    -- Find or create AutomationFunctions module
    local automationFunctions = sharedContext:FindFirstChild("AutomationFunctions")
    if not automationFunctions then
        automationFunctions = Instance.new("ModuleScript")
        automationFunctions.Name = "AutomationFunctions"
        automationFunctions.Parent = sharedContext
    end
    
    -- Create function implementations
    local functionSource = [[
local GymAutomation = require(script.Parent.Parent:WaitForChild("server"):WaitForChild("GymAutomation"))

local AutomationFunctions = {}

function AutomationFunctions.AutomateGym(tycoonName)
    if GymAutomation and typeof(GymAutomation.AutomateGym) == "function" then
        return GymAutomation:AutomateGym(tycoonName)
    else
        warn("GymAutomation module not fully initialized. Please try again in a moment.")
        return false
    end
end

function AutomationFunctions.AutomateAllGyms()
    if GymAutomation and typeof(GymAutomation.AutomateAllGyms) == "function" then
        return GymAutomation:AutomateAllGyms()
    else
        warn("GymAutomation module not fully initialized. Please try again in a moment.")
        return false
    end
end

function AutomationFunctions.ProcessEquipment(tycoonName)
    if GymAutomation and typeof(GymAutomation.ProcessEquipment) == "function" then
        return GymAutomation:ProcessEquipment(tycoonName)
    else
        warn("GymAutomation module not fully initialized. Please try again in a moment.")
        return false
    end
end

function AutomationFunctions.BatchProcessModels()
    if GymAutomation and typeof(GymAutomation.AutomateAllGyms) == "function" then
        local results = GymAutomation:AutomateAllGyms()
        if GymAutomation.ProcessEquipment then
            GymAutomation:ProcessEquipment()
        end
        return results
    else
        warn("GymAutomation module not fully initialized. Please try again in a moment.")
        return false
    end
end

return AutomationFunctions
]]
    
    automationFunctions.Source = functionSource
    log("Created AutomationFunctions module in shared context")
    
    -- Create a reference for clients
    if not ReplicatedStorage:FindFirstChild("AutomationEnabled") then
        local flag = Instance.new("BoolValue")
        flag.Name = "AutomationEnabled"
        flag.Value = true
        flag.Parent = ReplicatedStorage
        log("Created AutomationEnabled flag")
    end
    
    return true
end

-- Main loader function with retry mechanism
local retryAttempts = 0

local function main()
    log("Starting GymAutomation loader...")
    
    -- Load GymAutomation
    local gymAutomation = loadGymAutomation()
    if not gymAutomation then
        retryAttempts = retryAttempts + 1
        
        if retryAttempts <= CONFIG.MAX_RETRY_ATTEMPTS then
            warn("[GymAutomationLoader] Failed to load GymAutomation, scheduling retry... (Attempt " .. retryAttempts .. "/" .. CONFIG.MAX_RETRY_ATTEMPTS .. ")")
            task.delay(CONFIG.AUTO_RESTART_DELAY, main)
        else
            warn("[GymAutomationLoader] Failed to load GymAutomation after " .. CONFIG.MAX_RETRY_ATTEMPTS .. " attempts. Giving up.")
        end
        
        return false
    end
      -- Register with CoreRegistry
    local CoreRegistry = getCoreRegistry()
    if CoreRegistry then
        if typeof(CoreRegistry.registerSystem) == "function" then
            -- Check if already registered
            local isRegistered = false
            
            -- Check if hasSystem method exists
            if typeof(CoreRegistry.hasSystem) == "function" then
                isRegistered = CoreRegistry.hasSystem("GymAutomation")
            end
            
            -- If not registered, register it
            if not isRegistered then
                CoreRegistry.registerSystem("GymAutomation", gymAutomation)
                log("Successfully registered GymAutomation with CoreRegistry")
            else
                log("GymAutomation already registered with CoreRegistry")
            end
        else
            warn("[GymAutomationLoader] CoreRegistry missing registerSystem method")
        end
    else
        -- Create a local CoreRegistry-like interface if CoreRegistry is missing
        log("Creating local system registry since CoreRegistry was not found")
        _G.LocalRegistry = _G.LocalRegistry or {}
        _G.LocalRegistry.GymAutomation = gymAutomation
    end
    
    -- Register automation functions
    local functionsRegistered = registerAutomationFunctions(gymAutomation)
    
    if functionsRegistered then
        log("GymAutomation loaded successfully with all required functions")
        print("\n===== GYM TYCOON AUTOMATION READY =====")
        print("Available through AutomationFunctions module:")
        print("  AutomateGym([tycoonName]) - Automate a specific gym")
        print("  AutomateAllGyms() - Automate all gyms in the workspace")
        print("  ProcessEquipment([tycoonName]) - Process equipment in a gym")
        print("  BatchProcessModels() - Run all automation functions")
        print("======================================\n")
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
