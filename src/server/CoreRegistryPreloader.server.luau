--[[
    CoreRegistryPreloader.server.luau
    
    This script ensures CoreRegistry is loaded and initialized at the earliest possible moment.
    Place it directly in ServerScriptService for immediate execution.
    
    Created: May 1, 2025
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
        warn("[CoreRegistryPreloader] Failed to require module:", tostring(result))
        return nil
    end
end

-- Check if CoreRegistry is already initialized
local coreRegistryRef = sharedFolder:FindFirstChild("CoreRegistryRef")
local initializedRegistry = coreRegistryRef and safeRequire(coreRegistryRef)

if initializedRegistry then
    print("✅ [CoreRegistryPreloader] CoreRegistry already initialized")
    return
end

print("[CoreRegistryPreloader] Initializing CoreRegistry...")

-- Find CoreRegistryInitializer
local initializerModules = {
    ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistryInitializer"),
    ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistryInitializer.server.luau"),
    ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and 
        ServerScriptService.src.server:FindFirstChild("Core") and 
        ServerScriptService.src.server.Core:FindFirstChild("CoreRegistryInitializer"),
    ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and 
        ServerScriptService.src.server:FindFirstChild("Core") and 
        ServerScriptService.src.server.Core:FindFirstChild("CoreRegistryInitializer.server.luau")
}

local initialized = false

-- Try each initializer module
for _, module in ipairs(initializerModules) do
    if module then
        print("[CoreRegistryPreloader] Found CoreRegistryInitializer at " .. module:GetFullName())
        local result = safeRequire(module)
        if result then
            initialized = true
            print("✅ [CoreRegistryPreloader] CoreRegistry initialized via initializer")
            break
        end
    end
end

-- If initializer couldn't be found, try direct CoreRegistry modules
if not initialized then
    print("[CoreRegistryPreloader] No CoreRegistryInitializer found, trying direct CoreRegistry modules")
    
    local coreRegistryModules = {
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry.server.luau"),
        ServerScriptService:FindFirstChild("Core") and ServerScriptService.Core:FindFirstChild("CoreRegistry.luau"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and 
            ServerScriptService.src.server:FindFirstChild("Core") and 
            ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and 
            ServerScriptService.src.server:FindFirstChild("Core") and 
            ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry.server.luau"),
        ServerScriptService:FindFirstChild("src") and ServerScriptService.src:FindFirstChild("server") and 
            ServerScriptService.src.server:FindFirstChild("Core") and 
            ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry.luau")
    }
    
    for _, module in ipairs(coreRegistryModules) do
        if module then
            print("[CoreRegistryPreloader] Found CoreRegistry at " .. module:GetFullName())
            local CoreRegistry = safeRequire(module)
            if CoreRegistry then
                -- Initialize if possible
                if typeof(CoreRegistry.initialize) == "function" then
                    CoreRegistry.initialize()
                end
                
                -- Store in shared reference
                if not sharedFolder:FindFirstChild("CoreRegistryRef") then
                    local newRef = Instance.new("ModuleScript")
                    newRef.Name = "CoreRegistryRef"
                    newRef.Source = "return require('" .. module:GetFullName() .. "')"
                    newRef.Parent = sharedFolder
                    print("[CoreRegistryPreloader] Created CoreRegistryRef in shared folder")
                end
                
                initialized = true
                print("✅ [CoreRegistryPreloader] CoreRegistry loaded directly")
                break
            end
        end
    end
end

if not initialized then
    warn("❌ [CoreRegistryPreloader] Failed to initialize CoreRegistry")
end
