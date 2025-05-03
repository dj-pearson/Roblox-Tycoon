--[[
    UIRegistrySynchronizer.client.luau
    
    This script ensures that both implementations of UIRegistry (client and shared)
    work together correctly by synchronizing their data and functionality.
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        warn("[UIRegistrySynchronizer] Failed to require module:", tostring(result))
        return nil
    end
end

-- Debug logger
local function log(message, level)
    local prefix = "[UIRegistrySynchronizer]"
    if level == "Error" then
        warn(prefix, message)
    elseif level == "Success" then
        print(prefix, "✓", message)
    else
        print(prefix, message)
    end
end

log("Starting UIRegistry synchronization...")

-- Load the shared UIRegistry
local sharedUIRegistry = nil
local sharedModule = ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("UIRegistry")
if sharedModule then
    sharedUIRegistry = safeRequire(sharedModule)
    if sharedUIRegistry then
        log("Loaded shared UIRegistry", "Success")
    else
        log("Failed to load shared UIRegistry", "Error")
    end
else
    log("Shared UIRegistry module not found", "Error")
end

-- Load the client UIRegistry
local clientUIRegistry = nil
local searchLocations = {
    player.PlayerScripts:FindFirstChild("client") and player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and
    player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild("UIRegistry.client"),
    
    player.PlayerScripts:FindFirstChild("client") and player.PlayerScripts:FindFirstChild("client"):FindFirstChild("Core") and
    player.PlayerScripts:FindFirstChild("client"):FindFirstChild("Core"):FindFirstChild("UIRegistry"),
    
    player.PlayerScripts:FindFirstChild("client") and player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI") and
    player.PlayerScripts:FindFirstChild("client"):FindFirstChild("UI"):FindFirstChild("UIRegistry"),
}

for _, location in pairs(searchLocations) do
    if location then
        clientUIRegistry = safeRequire(location)
        if clientUIRegistry then
            log("Loaded client UIRegistry from " .. location:GetFullName(), "Success")
            break
        end
    end
end

if not clientUIRegistry then
    log("Client UIRegistry not found", "Error")
end

-- Skip synchronization if either module is missing
if not sharedUIRegistry or not clientUIRegistry then
    log("Can't synchronize because one of the UIRegistry modules is missing", "Error")
    return
end

-- Synchronization function
local function synchronizeRegistries()
    log("Starting registry synchronization...")
    
    -- Sync from shared to client (registeredComponents -> components)
    if sharedUIRegistry.registeredComponents then
        for id, componentData in pairs(sharedUIRegistry.registeredComponents) do
            -- Only sync if the client doesn't already have this component
            if not clientUIRegistry.components[id] then
                log("Syncing component from shared to client: " .. id)
                
                -- Handle different data structures between the two implementations
                if typeof(componentData) == "table" and componentData.constructor then
                    -- If shared uses constructor pattern
                    clientUIRegistry.registerComponent(id, componentData.constructor)
                else
                    -- Otherwise just register the component directly
                    clientUIRegistry.registerComponent(id, componentData)
                end
            end
        end
    end
    
    -- Sync from client to shared (components -> registeredComponents)
    if clientUIRegistry.components then
        for id, componentData in pairs(clientUIRegistry.components) do
            -- Check if the client component exists in the shared registry
            local sharedHasComponent = false
            if sharedUIRegistry.registeredComponents and sharedUIRegistry.registeredComponents[id] then
                sharedHasComponent = true
            end
            
            if not sharedHasComponent and sharedUIRegistry.RegisterComponent then
                log("Syncing component from client to shared: " .. id)
                
                -- Extract the component instance if needed
                local component = componentData
                if typeof(componentData) == "table" and componentData.instance then
                    component = componentData.instance
                end
                
                -- Register with the shared registry
                sharedUIRegistry.RegisterComponent(id, function() return component end, {
                    isScreen = true,
                    metadata = { source = "client_sync" }
                })
            end
        end
    end
    
    log("Registry synchronization complete", "Success")
    
    -- Make sure both registries are initialized
    if clientUIRegistry.initialize and not clientUIRegistry._initialized then
        clientUIRegistry.initialize()
    end
    
    if sharedUIRegistry.Initialize and not sharedUIRegistry._initialized then
        sharedUIRegistry.Initialize()
    end
end

-- Perform initial synchronization
synchronizeRegistries()

-- Set up periodic synchronization to ensure new components are shared
local function periodicSync()
    while true do
        task.wait(10) -- Check every 10 seconds
        synchronizeRegistries()
    end
end

task.spawn(periodicSync)

-- Export the synchronizer
local UIRegistrySynchronizer = {
    sharedUIRegistry = sharedUIRegistry,
    clientUIRegistry = clientUIRegistry,
    synchronize = synchronizeRegistries
}

return UIRegistrySynchronizer
