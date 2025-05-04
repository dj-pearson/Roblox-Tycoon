--[[
    CoreRegistryEarlyLoader.server.luau
    
    This script ensures CoreRegistry is loaded and initialized at the earliest possible moment.
    Place it directly in ServerScriptService for immediate execution.
    
    Created: May 1, 2025
    Updated: May 4, 2025 - Enhanced to fix degraded state issues
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Only run in Studio for safety
if not RunService:IsStudio() then
    return
end

-- Create shared folder if it doesn't exist
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if not sharedFolder then
    sharedFolder = Instance.new("Folder")
    sharedFolder.Name = "shared"
    sharedFolder.Parent = ReplicatedStorage
end

local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[CoreRegistryEarlyLoader] Failed to require module:", tostring(result))
        return nil
    end
end

-- Check if CoreRegistry is already initialized
local coreRegistryRef = sharedFolder:FindFirstChild("CoreRegistryRef")
local initializedRegistry = coreRegistryRef and safeRequire(coreRegistryRef)

if initializedRegistry then
    print("✅ [CoreRegistryEarlyLoader] CoreRegistry already initialized")
    return
end

-- Find CoreRegistryInitializer
local initializerModules = {
    ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistryInitializer"),
    ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistryInitializer.server.luau"),
    ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistryInitializer"),
    ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistryInitializer.server.luau")
}

local initialized = false

-- Try each module
for _, module in ipairs(initializerModules) do
    if module then
        print("[CoreRegistryEarlyLoader] Found CoreRegistryInitializer at " .. module:GetFullName())
        local result = safeRequire(module)
        if result then
            initialized = true
            print("✅ [CoreRegistryEarlyLoader] CoreRegistry initialized")
            break
        end
    end
end

-- If initializer couldn't be found, try direct CoreRegistry modules
if not initialized then
    print("[CoreRegistryEarlyLoader] No CoreRegistryInitializer found, trying direct CoreRegistry modules")
    
    local coreRegistryModules = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry.server.luau"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry.luau"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry.server.luau"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and ServerScriptService.src.server:FindFirstChild("Core") and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry.luau")
    }
    
    for _, module in ipairs(coreRegistryModules) do
        if module then
            print("[CoreRegistryEarlyLoader] Found CoreRegistry at " .. module:GetFullName())
            local CoreRegistry = safeRequire(module)
            if CoreRegistry then
                -- Initialize if possible
                if typeof(CoreRegistry.initialize) == "function" then
                    CoreRegistry.initialize()
                end
                  -- Store in shared folder for access by other scripts
                local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
                if not sharedFolder then
                    sharedFolder = Instance.new("Folder")
                    sharedFolder.Name = "shared"
                    sharedFolder.Parent = ReplicatedStorage
                end
                
                -- Create a ModuleScript that returns CoreRegistry
                local coreRegistryRef = sharedFolder:FindFirstChild("CoreRegistryRef")
                if not coreRegistryRef then
                    coreRegistryRef = Instance.new("ModuleScript")
                    coreRegistryRef.Name = "CoreRegistryRef"
                    coreRegistryRef.Source = "return require('" .. module:GetFullName() .. "')"
                    coreRegistryRef.Parent = sharedFolder
                end
                
                initialized = true
                print("✅ [CoreRegistryEarlyLoader] CoreRegistry loaded and stored in shared reference")
                break
            end
        end
    end
end

-- =============== MAY 4, 2025 ENHANCEMENT - FIX DEGRADED STATE ===============
-- Check CoreRegistry health and fix if needed
local function runCoreRegistryFix()
    print("[CoreRegistryEarlyLoader] Checking CoreRegistry health and fixing any issues...")
    
    -- Find CoreRegistryFix script
    local fixScript = nil
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            if path:FindFirstChild("CoreRegistryFix.server") then
                fixScript = path["CoreRegistryFix.server"]
                break
            elseif path:FindFirstChild("CoreRegistryFix") then
                fixScript = path.CoreRegistryFix
                break
            end
        end
    end
    
    if not fixScript then
        warn("[CoreRegistryEarlyLoader] CoreRegistryFix script not found")
        return false
    end
    
    -- Run the fix script
    local success, result = pcall(function()
        return require(fixScript)
    end)
    
    if success then
        print("✅ [CoreRegistryEarlyLoader] Successfully ran CoreRegistry fix")
        return true
    else
        warn("❌ [CoreRegistryEarlyLoader] Failed to run CoreRegistry fix:", result)
        return false
    end
end

-- Run fix process after initialization
if initialized then
    -- Wait a brief moment to allow the registry to fully initialize
    task.wait(0.5)
    runCoreRegistryFix()
else
    warn("[CoreRegistryEarlyLoader] Skipping fix process since initialization failed")
end

-- Set global flag
_G.CoreRegistryEarlyLoaderRun = true
_G.CoreRegistryEarlyLoaderTime = os.time()

if not initialized then
    warn("❌ [CoreRegistryEarlyLoader] Failed to initialize CoreRegistry")
end
