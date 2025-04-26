--[[
    ClientBootstrap.client.luau
    
    Main entry point for client-side initialization.
    Handles loading of ModuleLoader, ClientRegistry, and other critical systems.
    Implements a staged bootstrap process with fallbacks for missing components.
    
    Created: April 25, 2025
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Constants
local DEBUG_ENABLED = true
local MAX_RETRIES = 3
local RETRY_DELAY = 0.5
local BOOTSTRAP_STAGES = {
    "initializeSharedFolders",
    "initializeClientRegistry",
    "initializeUIComponents",
    "initializeEventBridge", 
    "initializeDataBridge"
}

-- Local variables
local LocalPlayer = Players.LocalPlayer
local successfulStages = 0
local failedStages = {}
local startTime = os.clock()
local bootstrapComplete = false

-- Debug logging
local function log(message)
    if DEBUG_ENABLED then
        print("[ClientBootstrap] " .. message)
    end
end

local function warn_log(message)
    warn("[ClientBootstrap] " .. message)
end

--------------------------------------------------------
-- CORE UTILITIES
--------------------------------------------------------

-- Safe require utility
local function requireSafely(module)
    if not module then
        return nil
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if not success then
        warn_log("Failed to require " .. tostring(module:GetFullName()) .. ": " .. tostring(result))
        return nil
    end
    
    return result
end

-- Wait for child with timeout
local function safeWaitForChild(parent, childName, timeoutSecs)
    if not parent then
        warn_log("Cannot wait for child in nil parent")
        return nil
    end
    
    timeoutSecs = timeoutSecs or 5
    
    -- Check if it already exists
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Create a thread to watch for the child
    local foundChild = nil
    local threadFinished = false
    
    -- Thread to wait for child
    task.spawn(function()
        foundChild = parent:WaitForChild(childName, timeoutSecs)
        threadFinished = true
    end)
    
    -- Wait for thread to finish with yield protection
    local startWait = os.clock()
    while not threadFinished and os.clock() - startWait < timeoutSecs do
        task.wait(0.1)
    end
    
    return foundChild
end

-- Ensure folder exists in parent
local function ensureFolderExists(parent, name)
    if not parent then
        warn_log("Cannot create folder in nil parent")
        return nil
    end
    
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
        log("Created folder: " .. name .. " in " .. parent:GetFullName())
    end
    
    return folder
end

-- Find a module in multiple possible locations
local function findModule(moduleName, searchPaths)
    if not searchPaths or #searchPaths == 0 then
        warn_log("No search paths provided to findModule")
        return nil
    end
    
    -- Search all paths
    for _, pathFn in ipairs(searchPaths) do
        local modulePath = pathFn()
        if modulePath and typeof(modulePath) == "Instance" and modulePath:IsA("ModuleScript") then
            return modulePath
        end
    end
    
    return nil
end

-- Create required client folders
local function createClientFolders()
    -- Create folder structure in PlayerScripts
    local client = ensureFolderExists(LocalPlayer.PlayerScripts, "Client")
    local core = ensureFolderExists(client, "Core")
    local ui = ensureFolderExists(client, "UI")
    local systems = ensureFolderExists(client, "Systems")
    
    -- Create shared folder in ReplicatedStorage
    local shared = ensureFolderExists(ReplicatedStorage, "shared")
    
    return client, core, ui, systems, shared
end

--------------------------------------------------------
-- BOOTSTRAP STAGES
--------------------------------------------------------

-- Stage 1: Initialize shared folders
local function initializeSharedFolders()
    log("Stage 1: Initializing shared folders...")
    
    -- Create client folders
    local client, core, ui, systems, shared = createClientFolders()
    
    -- Create events folder if it doesn't exist
    local events = ensureFolderExists(ReplicatedStorage, "Events")
    
    -- Ensure ClientScriptService folder exists for client-specific scripts
    local clientScriptService = ensureFolderExists(ReplicatedStorage, "ClientScriptService")
    
    log("Stage 1: Shared folders initialized")
    return true
end

-- Stage 2: Initialize ClientRegistry
local function initializeClientRegistry()
    log("Stage 2: Initializing ClientRegistry...")
    
    -- Try to find ClientRegistryFixer
    local clientRegistryFixerModule
    local attempts = 0
    
    while not clientRegistryFixerModule and attempts < MAX_RETRIES do
        clientRegistryFixerModule = findModule("ClientRegistryFixer", {
            function() return LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistryFixer") end,
            function() return ReplicatedStorage.shared:FindFirstChild("ClientRegistryFixer") end,
        })
        
        if not clientRegistryFixerModule then
            attempts += 1
            log("ClientRegistryFixer not found, attempt " .. attempts .. "/" .. MAX_RETRIES)
            task.wait(RETRY_DELAY)
        end
    end
    
    -- If not found after retries, create the module
    if not clientRegistryFixerModule then
        log("Creating ClientRegistryFixer...")
        
        -- Create the module at appropriate location
        clientRegistryFixerModule = Instance.new("ModuleScript")
        clientRegistryFixerModule.Name = "ClientRegistryFixer"
        clientRegistryFixerModule.Source = [[
-- Minimal ClientRegistryFixer implementation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function log(message)
    print("[ClientRegistryFixer] " .. message)
end

local function createClientRegistry()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        shared = Instance.new("Folder")
        shared.Name = "shared"
        shared.Parent = ReplicatedStorage
    end
    
    -- Check if one already exists
    if shared:FindFirstChild("ClientRegistry") then
        return require(shared.ClientRegistry)
    end
    
    -- Create a new ClientRegistry
    local clientRegistryModule = Instance.new("ModuleScript")
    clientRegistryModule.Name = "ClientRegistry"
    clientRegistryModule.Source = [[
local ClientRegistry = {
    systems = {},
    uiComponents = {},
    initialized = false,
    createdByFixer = true
}

function ClientRegistry:registerSystem(systemName, system)
    self.systems[systemName] = system
    return system
end

function ClientRegistry:registerUIComponent(componentName, component)
    self.uiComponents[componentName] = component
    return component
end

function ClientRegistry:getSystem(systemName)
    return self.systems[systemName]
end

function ClientRegistry:getUIComponent(componentName)
    return self.uiComponents[componentName]
end

function ClientRegistry:initialize()
    if self.initialized then return end
    self.initialized = true
end

function ClientRegistry:testRegistry()
    return true
end

return ClientRegistry
]]
    clientRegistryModule.Parent = shared
    
    log("Created minimal ClientRegistry in shared folder")
    return require(clientRegistryModule)
end

local function fixClientRegistry()
    local registry = createClientRegistry()
    
    -- Ensure it's initialized
    if typeof(registry.initialize) == "function" and not registry.initialized then
        registry:initialize()
    end
    
    return registry
end

return fixClientRegistry()
]]
        clientRegistryFixerModule.Parent = LocalPlayer.PlayerScripts.Client.Core
        log("Created ClientRegistryFixer module")
    end
    
    -- Load the ClientRegistryFixer
    local clientRegistry = requireSafely(clientRegistryFixerModule)
    
    -- If it didn't work, create minimal ClientRegistry directly
    if not clientRegistry then
        warn_log("Failed to load ClientRegistryFixer, creating minimal ClientRegistry")
        
        local shared = ensureFolderExists(ReplicatedStorage, "shared")
        
        -- Check if one already exists
        if shared:FindFirstChild("ClientRegistry") then
            clientRegistry = requireSafely(shared.ClientRegistry)
            if clientRegistry then
                log("Found existing ClientRegistry")
            end
        end
        
        -- Create one if not found
        if not clientRegistry then
            local clientRegistryModule = Instance.new("ModuleScript")
            clientRegistryModule.Name = "ClientRegistry"
            clientRegistryModule.Source = [[
local ClientRegistry = {
    systems = {},
    uiComponents = {},
    initialized = false,
    createdByBootstrap = true
}

function ClientRegistry:registerSystem(systemName, system)
    self.systems[systemName] = system
    print("[ClientRegistry] Registered system: " .. systemName)
    return system
end

function ClientRegistry:registerUIComponent(componentName, component)
    self.uiComponents[componentName] = component
    print("[ClientRegistry] Registered UI component: " .. componentName)
    return component
end

function ClientRegistry:getSystem(systemName)
    return self.systems[systemName]
end

function ClientRegistry:getUIComponent(componentName)
    return self.uiComponents[componentName]
end

function ClientRegistry:initialize()
    if self.initialized then return end
    
    print("[ClientRegistry] Initializing")
    
    self.initialized = true
end

return ClientRegistry
]]
            clientRegistryModule.Parent = shared
            
            clientRegistry = requireSafely(clientRegistryModule)
            log("Created minimal ClientRegistry in ReplicatedStorage.shared")
        end
    end
    
    -- Initialize the ClientRegistry
    if clientRegistry and typeof(clientRegistry.initialize) == "function" and not clientRegistry.initialized then
        local success = pcall(function()
            clientRegistry:initialize()
        end)
        
        if not success then
            warn_log("Failed to initialize ClientRegistry")
        end
    end
    
    -- Make ClientRegistry accessible globally for the module
    _G.__ClientBootstrap = _G.__ClientBootstrap or {}
    _G.__ClientBootstrap.ClientRegistry = clientRegistry
    
    log("Stage 2: ClientRegistry initialized")
    return clientRegistry ~= nil
end

-- Stage 3: Initialize UIComponents
local function initializeUIComponents()
    log("Stage 3: Initializing UIComponents...")
    
    -- Try to get ClientRegistry from previous stage
    local clientRegistry = _G.__ClientBootstrap and _G.__ClientBootstrap.ClientRegistry
    
    -- Try to find UIComponents
    local uiComponentsModule
    local attempts = 0
    
    while not uiComponentsModule and attempts < MAX_RETRIES do
        uiComponentsModule = findModule("UIComponents", {
            function() return ReplicatedStorage.shared:FindFirstChild("UIComponents") end,
            function() return LocalPlayer.PlayerScripts.Client.UI:FindFirstChild("UIComponents") end
        })
        
        if not uiComponentsModule then
            attempts += 1
            log("UIComponents not found, attempt " .. attempts .. "/" .. MAX_RETRIES)
            task.wait(RETRY_DELAY)
        end
    end
    
    local uiComponents
    
    -- If found, try to require it
    if uiComponentsModule then
        uiComponents = requireSafely(uiComponentsModule)
    else
        -- Otherwise, create a minimal version
        log("Creating minimal UIComponents...")
        
        -- Create the module
        uiComponentsModule = Instance.new("ModuleScript")
        uiComponentsModule.Name = "UIComponents"
        uiComponentsModule.Source = [[
local UIComponents = {
    UIStyle = {
        colors = {
            background = Color3.fromRGB(40, 40, 60),
            text = Color3.fromRGB(240, 240, 240),
            accent = Color3.fromRGB(80, 160, 240)
        },
        fonts = {
            header = Enum.Font.GothamBold,
            body = Enum.Font.Gotham
        }
    },
    IconSet = {
        close = "rbxassetid://8093755787",
        settings = "rbxassetid://8093754726",
        info = "rbxassetid://8093754900"
    },
    initialized = false,
    createdByBootstrap = true
}

-- Initialize the module
function UIComponents:initialize()
    if self.initialized then return end
    
    print("[UIComponents] Initializing minimal version")
    
    -- Try to register with ClientRegistry
    local success, result = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local shared = ReplicatedStorage:FindFirstChild("shared")
        if shared and shared:FindFirstChild("ClientRegistry") then
            local clientRegistry = require(shared.ClientRegistry)
            if clientRegistry then
                clientRegistry:registerUIComponent("UIStyle", self.UIStyle)
                clientRegistry:registerUIComponent("IconSet", self.IconSet)
                clientRegistry:registerUIComponent("UIComponents", self)
            end
        end
    end)
    
    self.initialized = true
end

UIComponents:initialize()

return UIComponents
]]
        
        -- Add to shared folder
        local shared = ensureFolderExists(ReplicatedStorage, "shared")
        uiComponentsModule.Parent = shared
        
        uiComponents = requireSafely(uiComponentsModule)
        log("Created minimal UIComponents in ReplicatedStorage.shared")
    end
    
    -- Initialize the UIComponents
    if uiComponents and typeof(uiComponents.initialize) == "function" and not uiComponents.initialized then
        local success = pcall(function()
            uiComponents:initialize()
        end)
        
        if not success then
            warn_log("Failed to initialize UIComponents")
        end
    end
    
    -- Register with ClientRegistry if available
    if clientRegistry and uiComponents then
        -- Check if already registered
        local alreadyRegistered = false
        
        if typeof(clientRegistry.getUIComponent) == "function" then
            alreadyRegistered = clientRegistry:getUIComponent("UIComponents") ~= nil
        end
        
        if not alreadyRegistered and typeof(clientRegistry.registerUIComponent) == "function" then
            clientRegistry:registerUIComponent("UIComponents", uiComponents)
            
            -- Register UIStyle and IconSet
            clientRegistry:registerUIComponent("UIStyle", uiComponents.UIStyle)
            clientRegistry:registerUIComponent("IconSet", uiComponents.IconSet)
            
            log("Registered UIComponents with ClientRegistry")
        end
    end
    
    -- Make UIComponents accessible globally for the module
    _G.__ClientBootstrap = _G.__ClientBootstrap or {}
    _G.__ClientBootstrap.UIComponents = uiComponents
    
    log("Stage 3: UIComponents initialized")
    return uiComponents ~= nil
end

-- Stage 4: Initialize EventBridge
local function initializeEventBridge()
    log("Stage 4: Initializing EventBridge...")
    
    -- Try to get ClientRegistry from previous stage
    local clientRegistry = _G.__ClientBootstrap and _G.__ClientBootstrap.ClientRegistry
    
    -- Try to find EventBridge
    local eventBridgeModule
    local attempts = 0
    
    while not eventBridgeModule and attempts < MAX_RETRIES do
        eventBridgeModule = findModule("EventBridge", {
            function() return ReplicatedStorage.shared:FindFirstChild("EventBridge") end,
            function() return LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("EventBridge") end
        })
        
        if not eventBridgeModule then
            attempts += 1
            log("EventBridge not found, attempt " .. attempts .. "/" .. MAX_RETRIES)
            task.wait(RETRY_DELAY)
        end
    end
    
    local eventBridge
    
    -- If found, try to require it
    if eventBridgeModule then
        eventBridge = requireSafely(eventBridgeModule)
    else
        -- Otherwise, create a minimal version
        log("Creating minimal EventBridge...")
        
        -- Create the module
        eventBridgeModule = Instance.new("ModuleScript")
        eventBridgeModule.Name = "EventBridge"
        eventBridgeModule.Source = [[
local EventBridge = {
    events = {},
    remoteEvents = {},
    initialized = false,
    createdByBootstrap = true
}

function EventBridge:initialize()
    if self.initialized then return end
    
    print("[EventBridge] Initializing minimal version")
    
    -- Register remote events
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    
    if eventsFolder then
        for _, instance in ipairs(eventsFolder:GetChildren()) do
            if instance:IsA("RemoteEvent") then
                self:registerRemoteEvent(instance.Name, instance)
            end
        end
    end
    
    self.initialized = true
end

function EventBridge:registerRemoteEvent(eventName, remoteEvent)
    self.remoteEvents[eventName] = remoteEvent
    
    remoteEvent.OnClientEvent:Connect(function(...)
        self:fireEvent(eventName, ...)
    end)
    
    print("[EventBridge] Registered remote event: " .. eventName)
end

function EventBridge:connectEvent(eventName, callback)
    if not self.events[eventName] then
        self.events[eventName] = {
            callbacks = {}
        }
    end
    
    table.insert(self.events[eventName].callbacks, callback)
    return true
end

function EventBridge:fireEvent(eventName, ...)
    local event = self.events[eventName]
    if event then
        for _, callback in ipairs(event.callbacks) do
            task.spawn(function()
                callback(...)
            end)
        end
    end
    
    return true
end

function EventBridge:fireServer(eventName, ...)
    local remoteEvent = self.remoteEvents[eventName]
    if remoteEvent then
        remoteEvent:FireServer(...)
        return true
    end
    
    print("[EventBridge] Warning: Remote event not found: " .. eventName)
    return false
end

return EventBridge
]]
        
        -- Add to shared folder
        local shared = ensureFolderExists(ReplicatedStorage, "shared")
        eventBridgeModule.Parent = shared
        
        eventBridge = requireSafely(eventBridgeModule)
        log("Created minimal EventBridge in ReplicatedStorage.shared")
    end
    
    -- Initialize the EventBridge
    if eventBridge and typeof(eventBridge.initialize) == "function" and not eventBridge.initialized then
        local success = pcall(function()
            eventBridge:initialize()
        end)
        
        if not success then
            warn_log("Failed to initialize EventBridge")
        end
    end
    
    -- Register with ClientRegistry if available
    if clientRegistry and eventBridge then
        -- Check if already registered
        local alreadyRegistered = false
        
        if typeof(clientRegistry.getSystem) == "function" then
            alreadyRegistered = clientRegistry:getSystem("EventBridge") ~= nil
        end
        
        if not alreadyRegistered and typeof(clientRegistry.registerSystem) == "function" then
            clientRegistry:registerSystem("EventBridge", eventBridge)
            log("Registered EventBridge with ClientRegistry")
        end
    end
    
    -- Make EventBridge accessible globally for the module
    _G.__ClientBootstrap = _G.__ClientBootstrap or {}
    _G.__ClientBootstrap.EventBridge = eventBridge
    
    log("Stage 4: EventBridge initialized")
    return eventBridge ~= nil
end

-- Stage 5: Initialize DataBridge
local function initializeDataBridge()
    log("Stage 5: Initializing DataBridge...")
    
    -- Try to get ClientRegistry from previous stage
    local clientRegistry = _G.__ClientBootstrap and _G.__ClientBootstrap.ClientRegistry
    
    -- Data-related initialization can be optional, consider it successful regardless
    -- but still attempt to set up if possible
    
    -- Try to find DataBridge module
    local dataBridgeModule = findModule("DataBridge", {
        function() return ReplicatedStorage.shared:FindFirstChild("DataBridge") end,
        function() return LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("DataBridge") end
    })
    
    local dataBridge
    
    -- If found, try to require it
    if dataBridgeModule then
        dataBridge = requireSafely(dataBridgeModule)
        
        -- Initialize if it has the method
        if dataBridge and typeof(dataBridge.initialize) == "function" then
            pcall(function()
                dataBridge:initialize()
            end)
        end
        
        -- Register with ClientRegistry if available
        if clientRegistry and dataBridge then
            if typeof(clientRegistry.registerSystem) == "function" then
                clientRegistry:registerSystem("DataBridge", dataBridge)
                log("Registered DataBridge with ClientRegistry")
            end
        end
        
        -- Make DataBridge accessible globally for the module
        _G.__ClientBootstrap = _G.__ClientBootstrap or {}
        _G.__ClientBootstrap.DataBridge = dataBridge
    else
        log("DataBridge module not found, skipping initialization")
    end
    
    log("Stage 5: DataBridge initialization completed")
    return true
end

--------------------------------------------------------
-- BOOTSTRAP PROCESS
--------------------------------------------------------

-- Run a bootstrap stage with error handling
local function runStage(stageIndex, stageFn)
    local stageName = BOOTSTRAP_STAGES[stageIndex]
    log("Running stage " .. stageIndex .. "/" .. #BOOTSTRAP_STAGES .. ": " .. stageName)
    
    local success, result = pcall(stageFn)
    
    if success and result then
        log("Stage " .. stageIndex .. " (" .. stageName .. ") completed successfully")
        successfulStages += 1
        return true
    else
        local errorMessage = not success and result or "Stage returned false"
        warn_log("Stage " .. stageIndex .. " (" .. stageName .. ") failed: " .. tostring(errorMessage))
        table.insert(failedStages, stageName)
        return false
    end
end

-- Log bootstrap summary
local function logBootstrapSummary()
    local duration = os.clock() - startTime
    
    log("Bootstrap complete: " .. successfulStages .. "/" .. #BOOTSTRAP_STAGES .. " stages successful")
    log("Bootstrap took " .. string.format("%.3f", duration) .. " seconds")
    
    if #failedStages > 0 then
        warn_log("Failed stages: " .. table.concat(failedStages, ", "))
    end
    
    -- Return access to important bootstrap objects
    return {
        ClientRegistry = _G.__ClientBootstrap and _G.__ClientBootstrap.ClientRegistry,
        UIComponents = _G.__ClientBootstrap and _G.__ClientBootstrap.UIComponents,
        EventBridge = _G.__ClientBootstrap and _G.__ClientBootstrap.EventBridge,
        DataBridge = _G.__ClientBootstrap and _G.__ClientBootstrap.DataBridge,
        successfulStages = successfulStages,
        totalStages = #BOOTSTRAP_STAGES
    }
end

-- Run all bootstrap stages
local function runBootstrap()
    log("Starting client bootstrap process...")
    
    -- Setup start time
    startTime = os.clock()
    
    -- Stage 1: Initialize shared folders
    local stage1Success = runStage(1, initializeSharedFolders)
    
    -- Stage 2: Initialize ClientRegistry
    local stage2Success = runStage(2, initializeClientRegistry)
    
    if not stage2Success then
        warn_log("Critical stage failed, bootstrap incomplete")
        logBootstrapSummary()
        return
    end
    
    -- Stage 3: Initialize UIComponents
    runStage(3, initializeUIComponents)
    
    -- Stage 4: Initialize EventBridge
    runStage(4, initializeEventBridge)
    
    -- Stage 5: Initialize DataBridge
    runStage(5, initializeDataBridge)
    
    -- Log summary
    bootstrapComplete = true
    logBootstrapSummary()
end

-- Start the bootstrap process
runBootstrap()

-- Return access to important bootstrap objects
return {
    ClientRegistry = _G.__ClientBootstrap and _G.__ClientBootstrap.ClientRegistry,
    UIComponents = _G.__ClientBootstrap and _G.__ClientBootstrap.UIComponents,
    EventBridge = _G.__ClientBootstrap and _G.__ClientBootstrap.EventBridge,
    DataBridge = _G.__ClientBootstrap and _G.__ClientBootstrap.DataBridge,
    successfulStages = successfulStages,
    totalStages = #BOOTSTRAP_STAGES
}
