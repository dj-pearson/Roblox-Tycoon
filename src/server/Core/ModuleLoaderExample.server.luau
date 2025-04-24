--!strict
--[[
    ModuleLoaderExample.server.luau
    Example of how to properly load modules using the new ModuleLoader system
    
    Copy this pattern into your other scripts to fix module loading errors
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--------------------------------------------------------
-- STEP 1: Try to load the ModuleLoader utility
--------------------------------------------------------
local ModuleLoader
do
    local success, result = pcall(function()
        return require(ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("ModuleLoader"))
    end)
    
    if success and result then
        ModuleLoader = result
        print("[ModuleLoaderExample] ModuleLoader loaded successfully")
    else
        print("[ModuleLoaderExample] ModuleLoader not found, using legacy loading")
    end
end

--------------------------------------------------------
-- STEP 2: Load your dependencies using ModuleLoader or fallback
--------------------------------------------------------
-- Core dependencies
local CoreRegistry
local DataManager
local EventBridge

-- Load CoreRegistry (essential)
if ModuleLoader then
    -- Preferred method: Use ModuleLoader
    CoreRegistry = ModuleLoader:LoadServerModule("Core", "CoreRegistry")
else
    -- Legacy method (fallback)
    local success, result = pcall(function()
        -- Try different paths that might exist in your codebase
        if ServerScriptService:FindFirstChild("src") and 
           ServerScriptService.src:FindFirstChild("server") and 
           ServerScriptService.src.server:FindFirstChild("Core") then
            return require(ServerScriptService.src.server.Core.CoreRegistry)
        elseif ServerScriptService:FindFirstChild("Core") then
            return require(ServerScriptService.Core.CoreRegistry)
        elseif ServerScriptService:FindFirstChild("Server") and 
               ServerScriptService.Server:FindFirstChild("Core") then
            return require(ServerScriptService.Server.Core.CoreRegistry)
        end
        return nil
    end)
    
    if success and result then
        CoreRegistry = result
    else
        warn("[ModuleLoaderExample] Failed to load CoreRegistry: " .. tostring(result))
    end
end

-- If CoreRegistry is available, we can use it to get other systems more easily
if CoreRegistry then
    DataManager = CoreRegistry.getSystem("DataManager")
    EventBridge = CoreRegistry.getSystem("EventBridge")
    
    -- Register this module with CoreRegistry if needed
    -- CoreRegistry.registerSystem("ModuleLoaderExample", YourModule, {"DataManager", "EventBridge"})
else
    -- If CoreRegistry isn't available, load dependencies directly
    if ModuleLoader then
        DataManager = ModuleLoader:LoadServerModule("Core", "DataManager")
        EventBridge = ModuleLoader:LoadServerModule("Core", "EventBridge")
    else
        -- Fallback to direct requires (tread carefully - this is what caused the original errors)
        local success, result = pcall(function()
            if ServerScriptService.src and ServerScriptService.src.server and ServerScriptService.src.server.Core then
                return require(ServerScriptService.src.server.Core.DataManager)
            elseif ServerScriptService.Core then
                return require(ServerScriptService.Core.DataManager)
            end
            return nil
        end)
        
        if success and result then
            DataManager = result
        end
        
        -- Repeat the same pattern for other dependencies
    end
end

--------------------------------------------------------
-- STEP 3: Your module's functionality
--------------------------------------------------------
local YourModule = {}

function YourModule:Initialize()
    print("[ModuleLoaderExample] Initializing")
    
    -- Check if dependencies loaded correctly
    if not CoreRegistry then
        warn("[ModuleLoaderExample] CoreRegistry not found - functionality will be limited")
    end
    
    if not DataManager then
        warn("[ModuleLoaderExample] DataManager not found - data persistence will not work")
    end
    
    if not EventBridge then
        warn("[ModuleLoaderExample] EventBridge not found - events will not work")
    end
    
    -- Your initialization code here
end

--------------------------------------------------------
-- STEP 4: Return your module
--------------------------------------------------------
return YourModule
