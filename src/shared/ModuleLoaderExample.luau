--!strict
--[[
    ModuleLoaderExample.luau
    
    Example demonstrating how to properly load modules using the ModuleLoader system.
    Use this pattern in both client and server scripts to ensure consistent module loading.
    
    Created: April 26, 2025
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Constants
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

--------------------------------------------------------
-- STEP 1: Load ModuleLoaderHelper first
--------------------------------------------------------
local ModuleLoaderHelper
do
    -- Try to load ModuleLoaderHelper from shared folder
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if sharedFolder and sharedFolder:FindFirstChild("ModuleLoaderHelper") then
        local success, result = pcall(function()
            return require(sharedFolder.ModuleLoaderHelper)
        end)
        
        if success then
            ModuleLoaderHelper = result
        else
            warn("[ModuleLoaderExample] Failed to load ModuleLoaderHelper: " .. tostring(result))
        end
    end
    
    -- If ModuleLoaderHelper wasn't found, create a minimal version
    if not ModuleLoaderHelper then
        ModuleLoaderHelper = {
            GetModule = function(_, moduleName)
                if ReplicatedStorage:FindFirstChild("shared") then
                    local module = ReplicatedStorage.shared:FindFirstChild(moduleName)
                    if module then
                        return pcall(function() return require(module) end)
                    end
                end
                return nil
            end,
            
            GetCoreRegistry = function(_)
                if IsServer then
                    local ServerScriptService = game:GetService("ServerScriptService")
                    if ServerScriptService:FindFirstChild("Core") and
                       ServerScriptService.Core:FindFirstChild("CoreRegistry") then
                        local success, result = pcall(function()
                            return require(ServerScriptService.Core.CoreRegistry)
                        end)
                        if success then
                            return result
                        end
                    end
                else
                    -- Client-side version
                    if ReplicatedStorage:FindFirstChild("shared") and
                       ReplicatedStorage.shared:FindFirstChild("ClientRegistry") then
                        local success, result = pcall(function()
                            return require(ReplicatedStorage.shared.ClientRegistry)
                        end)
                        if success then
                            return result
                        end
                    end
                end
                return nil
            end,
            
            GetSystem = function(self, systemName)
                local registry = self:GetCoreRegistry()
                if registry and typeof(registry.getSystem) == "function" then
                    return registry:getSystem(systemName)
                end
                return nil
            end
        }
        warn("[ModuleLoaderExample] Using minimal ModuleLoaderHelper fallback")
    end
end

--------------------------------------------------------
-- STEP 2: Load dependencies using ModuleLoaderHelper
--------------------------------------------------------
-- Get registry first (either CoreRegistry or ClientRegistry)
local Registry = ModuleLoaderHelper:GetCoreRegistry()

-- Load common systems
local EventBridge = ModuleLoaderHelper:GetSystem("EventBridge")
local DataManager = ModuleLoaderHelper:GetSystem("DataManager")
local AssetValidator = ModuleLoaderHelper:GetSystem("AssetValidator")

-- Load optional dependencies - won't error if missing
local OptionalSystem = ModuleLoaderHelper:GetSystem("OptionalSystem")

-- You can also load any module directly
local Constants = ModuleLoaderHelper:GetModule("Constants")

--------------------------------------------------------
-- STEP 3: Define your module
--------------------------------------------------------
local YourModule = {
    initialized = false,
    config = {
        debugLogging = true
    }
}

-- Logging helper
function YourModule:Log(message)
    if self.config.debugLogging then
        print("[YourModule] " .. message)
    end
end

-- Initialize the module
function YourModule:Initialize()
    if self.initialized then
        self:Log("Already initialized")
        return
    end
    
    self:Log("Initializing")
    
    -- Check if dependencies loaded correctly
    if not Registry then
        warn("[YourModule] Registry not found - functionality will be limited")
    end
    
    if not DataManager then
        warn("[YourModule] DataManager not found - data operations will not work")
    end
    
    -- Set up any event connections
    if EventBridge then
        EventBridge:connectEvent("ExampleEvent", function(...)
            self:HandleExampleEvent(...)
        end)
    else
        warn("[YourModule] EventBridge not found - events will not work")
    end
    
    -- Initialize module state
    self.initialized = true
    self:Log("Initialization complete")
end

-- Example event handler
function YourModule:HandleExampleEvent(...)
    self:Log("ExampleEvent received")
    -- Handle event
end

-- Public API method
function YourModule:DoSomething(param1, param2)
    if not self.initialized then
        self:Initialize()
    end
    
    self:Log("DoSomething called with " .. tostring(param1) .. " and " .. tostring(param2))
    
    -- Use dependencies if available
    if AssetValidator then
        local isValid = AssetValidator:validateAsset(param1)
        if not isValid then
            return false
        end
    end
    
    -- Implementation
    return true
end

--------------------------------------------------------
-- STEP 4: Register with Registry if available
--------------------------------------------------------
if Registry then
    if IsServer and typeof(Registry.registerSystem) == "function" then
        Registry:registerSystem("YourModule", YourModule)
    elseif IsClient and typeof(Registry.registerSystem) == "function" then
        Registry:registerSystem("YourModule", YourModule)
    end
end

-- Initialize if needed immediately
if YourModule.config.initializeOnRequire then
    YourModule:Initialize()
end

return YourModule
