--[[
    GymAutomationLoader.server.luau
    This script is responsible for loading and initializing the GymAutomation system.
    It handles path resolution and graceful error handling.
    Created to fix critical "GymAutomationLoader Failures" reported in RobloxIssues.txt
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Create GymAutomation folder if it doesn't exist
local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

-- Create or ensure all needed folders
local gymAutomationFolder = ensureFolder(ServerScriptService, "GymAutomation")

-- Safe wait for child with timeout
local function safeWaitForChild(parent, childName, timeout)
    timeout = timeout or 5
    local startTime = os.clock()
    local child = parent:FindFirstChild(childName)
    
    while not child and (os.clock() - startTime) < timeout do
        task.wait(0.1)
        child = parent:FindFirstChild(childName)
    end
    
    return child
end

-- Define paths to search for the GymAutomation module
local searchPaths = {
    gymAutomationFolder,
    ServerScriptService:FindFirstChild("Core"),
    ServerScriptService:FindFirstChild("System"),
    ServerScriptService, -- Fallback
    ServerStorage:FindFirstChild("GymAutomation"),
    ServerStorage, -- Fallback
    ReplicatedStorage:FindFirstChild("shared")
}

-- Function to search for a module across multiple paths
local function findModule(moduleName)
    for i, path in ipairs(searchPaths) do
        if path then
            -- Check first before attempting WaitForChild to avoid yield
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                print("[GymAutomationLoader] Found " .. moduleName .. " at search path " .. i .. ": " .. path:GetFullName())
                return module
            end
        end
    end
    
    print("[GymAutomationLoader] Could not find " .. moduleName .. " in any search path")
    return nil
end

-- Load the modules with error handling
local function attemptLoad()
    -- First check for manager
    local managerModule = findModule("GymAutomationManager")
    if not managerModule then
        warn("[GymAutomationLoader] Could not find GymAutomationManager in any search path")
        return false
    end
    
    -- Then check for the main module
    local automationModule = findModule("GymAutomation")
    if not automationModule then
        warn("[GymAutomationLoader] Could not find GymAutomation in any search path")
        return false
    end
    
    -- Try to load the modules
    local success, GymAutomation = pcall(function()
        return require(automationModule)
    end)
    
    if not success then
        warn("[GymAutomationLoader] Failed to require GymAutomation: " .. tostring(GymAutomation))
        return false
    end
    
    if not GymAutomation or typeof(GymAutomation) ~= "table" or not GymAutomation.initialize then
        warn("[GymAutomationLoader] GymAutomation module did not return a valid module")
        return false
    end
    
    -- Initialize the module
    local initSuccess = GymAutomation.initialize({
        retryOnFailure = true,
        logLevel = "verbose",
        componentTypes = {
            -- Register default component types
            treadmill = {
                automationLevel = 1,
                requiresStaff = false,
                cleaningInterval = 120
            },
            elliptical = {
                automationLevel = 1,
                requiresStaff = false,
                cleaningInterval = 120
            },
            weights = {
                automationLevel = 2,
                requiresStaff = true,
                cleaningInterval = 180
            }
        }
    })
    
    if not initSuccess then
        warn("[GymAutomationLoader] GymAutomation initialization failed")
        return false
    end
    
    -- Cache the module in _G for other scripts to access easily
    _G.GymAutomation = GymAutomation
    
    print("✅ GYM TYCOON AUTOMATION LOADED")
    return true
end

-- First attempt
local success = attemptLoad()

-- If failed, retry a few times
if not success then
    warn("[GymAutomationLoader] Failed to load GymAutomation, scheduling retry...")
    
    local retryCount = 0
    local maxRetries = 5
    
    local function retryLoad()
        retryCount = retryCount + 1
        warn("[GymAutomationLoader] Retry attempt " .. retryCount .. "/" .. maxRetries)
        
        success = attemptLoad()
        
        if success then
            print("[GymAutomationLoader] Successfully loaded GymAutomation on retry " .. retryCount)
        elseif retryCount < maxRetries then
            warn("[GymAutomationLoader] Failed to load GymAutomation, scheduling retry...")
            task.delay(5, retryLoad) -- Try again in 5 seconds
        else
            warn("[GymAutomationLoader] Failed to load GymAutomation after " .. maxRetries .. " retries")
        end
    end
    
    task.delay(5, retryLoad) -- First retry in 5 seconds
end
