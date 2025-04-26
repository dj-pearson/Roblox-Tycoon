--[[
    ModuleTemplate.luau
    
    Template for creating new modules with correct loading and dependency handling.
    Copy this template when creating new modules to ensure proper integration with ModuleLoader.
    
    Created: April 25, 2025
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Constants
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

--------------------------------------------------------
-- STEP 1: Load ModuleLoaderHelper
--------------------------------------------------------
local ModuleLoaderHelper
do
    local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
    if sharedFolder and sharedFolder:FindFirstChild("ModuleLoaderHelper") then
        local success, result = pcall(function()
            return require(sharedFolder.ModuleLoaderHelper)
        end)
        
        if success then
            ModuleLoaderHelper = result
        else
            warn("[ModuleTemplate] Failed to load ModuleLoaderHelper: " .. tostring(result))
        end
    end
    
    -- Create a minimal helper if the real one isn't available
    if not ModuleLoaderHelper then
        ModuleLoaderHelper = {
            GetModule = function(_, moduleName)
                local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
                if sharedFolder and sharedFolder:FindFirstChild(moduleName) then
                    local success, result = pcall(function()
                        return require(sharedFolder[moduleName])
                    end)
                    
                    if success then
                        return result
                    end
                end
                return nil
            end,
            
            GetCoreRegistry = function(_)
                if IsServer then
                    local ServerScriptService = game:GetService("ServerScriptService")
                    if ServerScriptService:FindFirstChild("Core") and
                       ServerScriptService.Core:FindFirstChild("CoreRegistry") then
                        return require(ServerScriptService.Core.CoreRegistry)
                    end
                end
                return nil
            end,
            
            GetSystem = function(self, systemName)
                local coreRegistry = self:GetCoreRegistry()
                if coreRegistry then
                    return coreRegistry:getSystem(systemName)
                end
                return nil
            end
        }
    end
end

--------------------------------------------------------
-- STEP 2: Load dependencies using ModuleLoaderHelper
--------------------------------------------------------
-- Load essential dependencies
local CoreRegistry = ModuleLoaderHelper:GetCoreRegistry()
local EventBridge = ModuleLoaderHelper:GetSystem("EventBridge")
local DataManager = ModuleLoaderHelper:GetSystem("DataManager")

-- Example of loading an optional dependency
local OptionalSystem = ModuleLoaderHelper:GetSystem("OptionalSystem")

--------------------------------------------------------
-- STEP 3: Module implementation
--------------------------------------------------------
local ModuleTemplate = {
    initialized = false,
    config = {
        debugLogging = true
    }
}

-- Debug logging helper
function ModuleTemplate:Log(message)
    if self.config.debugLogging then
        print("[ModuleTemplate] " .. message)
    end
end

-- Initialize the module
function ModuleTemplate:Initialize()
    if self.initialized then
        self:Log("Already initialized")
        return
    end
    
    self:Log("Initializing...")
    
    -- Check if dependencies are available
    if not CoreRegistry then
        warn("[ModuleTemplate] CoreRegistry not available!")
    end
    
    if not EventBridge then
        warn("[ModuleTemplate] EventBridge not available!")
    end
    
    -- Set up event connections
    if EventBridge then
        EventBridge:connectEvent("SomeEvent", function(...)
            self:HandleSomeEvent(...)
        end)
        
        self:Log("Event connections established")
    else
        -- Fallback for direct event connections
        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
        if eventsFolder and eventsFolder:FindFirstChild("SomeEvent") then
            if IsServer then
                eventsFolder.SomeEvent.OnServerEvent:Connect(function(...)
                    self:HandleSomeEvent(...)
                end)
            else
                eventsFolder.SomeEvent.OnClientEvent:Connect(function(...)
                    self:HandleSomeEvent(...)
                end)
            end
            
            self:Log("Using fallback event connections")
        end
    end
    
    -- Other initialization steps
    -- ...
    
    self.initialized = true
    self:Log("Initialization complete")
    
    return true
end

-- Example event handler
function ModuleTemplate:HandleSomeEvent(...)
    self:Log("SomeEvent received")
    -- Handle event
end

-- Example public API method
function ModuleTemplate:DoSomething(param1, param2)
    self:Log("DoSomething called with " .. tostring(param1) .. " and " .. tostring(param2))
    
    -- Use dependencies
    if DataManager then
        local data = DataManager:GetData()
        -- Do something with data
    end
    
    -- Implement method
    -- ...
    
    return true
end

--------------------------------------------------------
-- STEP 4: Register with CoreRegistry if available
--------------------------------------------------------
if CoreRegistry then
    CoreRegistry:registerSystem("ModuleTemplate", ModuleTemplate, {
        "EventBridge",
        "DataManager"
    })
end

-- Return the module
return ModuleTemplate
