-- InitializeCore.luau
-- Entry point for the core system initialization
-- Place in ServerScriptService/Core

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Load core systems in the correct order
local CorePath = ServerScriptService:FindFirstChild("Core")

if not CorePath then
    error("Core folder not found in ServerScriptService!")
    return
end

print("=== Initializing Gym Tycoon Core Systems ===")
print("Loading order: CoreRegistry -> EventBridge -> DataManager -> GymTycoonConnector")

-- First, require the CoreRegistry
local CoreRegistry = require(CorePath:FindFirstChild("CoreRegistry"))
print("CoreRegistry loaded")

-- Then, require and initialize EventBridge
local EventBridge = require(CorePath:FindFirstChild("EventBridge"))
print("EventBridge loaded")

-- Then, require DataManager
local DataManager = require(CorePath:FindFirstChild("DataManager"))
print("DataManager loaded")

-- Finally, load the main connector
local GymTycoonConnector = require(CorePath:FindFirstChild("GymTycoonConnector"))
print("GymTycoonConnector loaded")

-- Make global reference for backward compatibility
_G.InitializedSystems = {
    CoreRegistry = CoreRegistry,
    EventBridge = EventBridge,
    DataManager = DataManager,
    GymTycoonConnector = GymTycoonConnector
}

print("=== Core Systems Initialized Successfully ===")
print("Total systems registered:", #CoreRegistry.getSystemNames())

-- Create diagnostic functions
local diagnostics = {}

-- Log environment information
diagnostics.environment = {
    isStudio = RunService:IsStudio(),
    isServer = RunService:IsServer(),
    isRunning = RunService:IsRunning()
}

-- Log system status
diagnostics.systemStatus = {}
for _, name in ipairs(CoreRegistry.getSystemNames()) do
    diagnostics.systemStatus[name] = CoreRegistry.initialized[name] ~= nil
end

-- Print diagnostic information
print("\n=== Diagnostic Information ===")
print("Environment:", "Studio = " .. tostring(diagnostics.environment.isStudio), 
      "| Server = " .. tostring(diagnostics.environment.isServer),
      "| Running = " .. tostring(diagnostics.environment.isRunning))

print("System Status:")
for name, initialized in pairs(diagnostics.systemStatus) do
    print("  - " .. name .. ": " .. (initialized and "Initialized" or "Not Initialized"))
end
print("===============================")