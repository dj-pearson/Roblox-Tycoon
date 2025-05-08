--[[
    ClientBootstrap.client.luau
    
    Handles client-side initialization and loading of critical client systems.
    Creates necessary folder structures and loads UI components.
    
    Created as part of critical fixes on April 28, 2025.
    Updated May 3, 2025 to use the unified ModuleLoader system.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load ModuleLoaderHelper for consistent module loading
local ModuleLoaderHelper = nil

-- Try to load ModuleLoaderHelper
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
        print("[ClientBootstrap] ModuleLoaderHelper loaded successfully")
    else
        warn("[ClientBootstrap] Failed to load ModuleLoaderHelper, falling back to legacy loading")
    end
end

-- Client status tracking
local STATUS = {
    INITIALIZING = "Initializing",
    LOADING_CORE = "LoadingCore", 
    LOADING_UI = "LoadingUI",
    LOADING_SYSTEMS = "LoadingSystems",
    READY = "Ready",
    ERROR = "Error"
}

-- Configuration
local TIMEOUT = 10 -- Seconds to wait before timing out
local MAX_RETRIES = 3 -- Maximum number of retries for critical operations

-- State tracking
local clientStatus = STATUS.INITIALIZING
local initializeAttempts = 0
local initialized = false

-- Output nicely formatted client logs
local function logClient(message, isWarning, isError)
    local prefix = "[ClientBootstrap] "
    if isError then
        error(prefix .. message)
    elseif isWarning then
        warn(prefix .. message)
    else
        print(prefix .. message)
    end
end

-- Function to safely wait for child object
local function safeWaitForChild(parent, childName, timeoutSeconds)
    timeoutSeconds = timeoutSeconds or TIMEOUT
    
    -- Quick check first
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Use timeout to prevent infinite yield
    local startTime = os.clock()
    local endTime = startTime + timeoutSeconds
    
    while os.clock() < endTime do
        child = parent:FindFirstChild(childName)
        if child then
            return child
        end
        task.wait(0.1)
    end
    
    logClient("Timeout waiting for " .. parent:GetFullName() .. ":" .. childName, true)
    return nil
end

-- Function to ensure a folder path exists
local function ensureFolderPath(parent, pathArray)
    if not parent then
        logClient("Cannot ensure folder path - parent is nil", true)
        return nil
    end
    
    local current = parent
    for _, folderName in ipairs(pathArray) do
        local folder = current:FindFirstChild(folderName)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = current
        end
        current = folder
    end
    return current
end

-- Create or get a ModuleScript in the specified location
local function ensureModule(parent, name, source)
    if not parent then
        logClient("Cannot ensure module - parent is nil", true)
        return nil
    end
    
    local module = parent:FindFirstChild(name)
    if not module then
        if source then
            -- Try to create the module (may fail due to security restrictions)
            pcall(function()
                module = Instance.new("ModuleScript")
                module.Name = name
                module.Source = source
                module.Parent = parent
            end)
        end
    end
    return module
end

-- Function to safely require a module
local function safeRequire(module, fallback)
    -- If ModuleLoaderHelper is available, use it
    if ModuleLoaderHelper then
        return ModuleLoaderHelper.safeRequire(module, fallback)
    end
    
    -- Legacy fallback implementation
    if not module then
        return fallback
    end
    
    if not module:IsA("ModuleScript") then
        logClient("Expected ModuleScript but got " .. module.ClassName .. " for " .. module:GetFullName(), true)
        return fallback
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        logClient("Failed to require " .. module:GetFullName() .. " - " .. tostring(result), true)
        return fallback
    end
end

-- Function to find a module in different locations
local function findModule(moduleName)
    -- If ModuleLoaderHelper is available, use it
    if ModuleLoaderHelper then
        return ModuleLoaderHelper.findModule(moduleName)
    end
    
    -- Legacy fallback implementation
    local player = Players.LocalPlayer
    local locations = {
        player.PlayerScripts:FindFirstChild("Core"),
        player.PlayerScripts,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    for _, location in ipairs(locations) do
        if location then
            local module = location:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Create default minimal UI components module if missing
local function createMinimalUIComponents(parent)
    local source = [[
        -- Minimal UI Components Module (Emergency Fallback)
        -- Created by ClientBootstrap system
        
        local UIComponents = {}
        
        -- Basic button creation
        function UIComponents.CreateButton(text, size)
            local button = Instance.new("TextButton")
            button.Size = size or UDim2.new(0, 200, 0, 50)
            button.Text = text or "Button"
            button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            button.BorderSizePixel = 0
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Font = Enum.Font.GothamMedium
            button.TextSize = 14
            return button
        end
        
        -- Basic frame creation
        function UIComponents.CreateFrame(size)
            local frame = Instance.new("Frame")
            frame.Size = size or UDim2.new(0, 300, 0, 200)
            frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            frame.BorderSizePixel = 0
            return frame
        end
        
        -- Basic label creation
        function UIComponents.CreateLabel(text, size)
            local label = Instance.new("TextLabel")
            label.Size = size or UDim2.new(0, 200, 0, 50)
            label.Text = text or "Label"
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.Font = Enum.Font.GothamMedium
            label.TextSize = 14
            return label
        end
        
        UIComponents.isLoaded = true
        UIComponents.VERSION = "1.0.0-fallback"
        
        return UIComponents
    ]]
    
    return ensureModule(parent, "UIComponents", source)
end

-- Create default minimal ClientRegistry module if missing
local function createMinimalClientRegistry(parent)
    local source = [[
        -- Minimal ClientRegistry Module (Emergency Fallback)
        -- Created by ClientBootstrap system
        
        local ClientRegistry = {}
        local components = {}
        local events = {}
        
        -- Register a UI component
        function ClientRegistry.RegisterComponent(name, component)
            if not name or typeof(name) ~= "string" then
                warn("ClientRegistry: Invalid component name")
                return false
            end
            
            components[name] = component
            return true
        end
        
        -- Get a registered UI component
        function ClientRegistry.GetComponent(name)
            return components[name]
        end
        
        -- Register an event
        function ClientRegistry.RegisterEvent(name, callback)
            if not events[name] then
                events[name] = {}
            end
            table.insert(events[name], callback)
            return true
        end
        
        -- Fire an event
        function ClientRegistry.FireEvent(name, ...)
            local handlers = events[name]
            if handlers then
                for _, callback in ipairs(handlers) do
                    task.spawn(function()
                        callback(...)
                    end)
                end
            end
        end
        
        ClientRegistry.isLoaded = true
        ClientRegistry.VERSION = "1.0.0-fallback"
        
        return ClientRegistry
    ]]
    
    return ensureModule(parent, "ClientRegistry", source)
end

-- Create default minimal AssetValidator module if missing
local function createMinimalAssetValidator(parent)
    local source = [[
        -- Minimal AssetValidator Module (Emergency Fallback)
        -- Created by ClientBootstrap system
        
        local AssetValidator = {}
        
        -- Validate an asset ID
        function AssetValidator.ValidateAsset(assetId, assetType)
            -- Basic validation - just ensures its a number in string/number form
            if not assetId then
                return false
            end
            
            -- Convert rbxassetid:// format
            local id = tostring(assetId)
            id = id:gsub("rbxassetid://", "")
            
            -- Check if it's a number
            local numericId = tonumber(id)
            if not numericId then
                return false
            end
            
            return true, numericId
        end
        
        -- Get a validated image
        function AssetValidator.GetValidatedImageAsset(imageId, fallback)
            local isValid, id = AssetValidator.ValidateAsset(imageId)
            if isValid then
                return "rbxassetid://" .. id
            end
            return fallback or "rbxassetid://0"
        end
        
        -- Get a validated sound
        function AssetValidator.GetValidatedSoundAsset(soundId, fallback)
            local isValid, id = AssetValidator.ValidateAsset(soundId)
            if isValid then
                return "rbxassetid://" .. id
            end
            return fallback or "rbxassetid://0"
        end
        
        AssetValidator.isLoaded = true
        AssetValidator.VERSION = "1.0.0-fallback"
        
        return AssetValidator
    ]]
    
    return ensureModule(parent, "AssetValidator", source)
end

-- Initialize necessary client structures
local function initializeClientStructures()
    local player = Players.LocalPlayer
    if not player then
        return false
    end
    
    -- Ensure core folders exist
    local coreFolder = ensureFolderPath(player.PlayerScripts, {"Core"})
    ensureFolderPath(player.PlayerScripts, {"Client"})
    ensureFolderPath(player.PlayerScripts, {"UI"})
    
    -- Create minimal fallback modules if needed
    if not findModule("UIComponents") then
        createMinimalUIComponents(coreFolder)
        logClient("Created fallback UIComponents module", true)
    end
    
    if not findModule("ClientRegistry") then
        createMinimalClientRegistry(coreFolder)
        logClient("Created fallback ClientRegistry module", true)
    end
    
    if not findModule("AssetValidator") then
        createMinimalAssetValidator(coreFolder)
        logClient("Created fallback AssetValidator module", true)
    end
    
    return true
end

-- Main initialization function
local function initializeClient()
    if initialized then
        return
    end
    
    initializeAttempts = initializeAttempts + 1
    logClient("Initializing client (attempt " .. initializeAttempts .. "/" .. MAX_RETRIES .. ")")
    
    clientStatus = STATUS.INITIALIZING
    
    -- Try to load ClientRegistryPreloader first
    local clientRegistryPreloaderModule = findModule("ClientRegistryPreloader")
    if clientRegistryPreloaderModule then
        pcall(function()
            require(clientRegistryPreloaderModule)
            logClient("Loaded ClientRegistryPreloader")
        end)
    end
    
    -- Ensure client structure
    if not initializeClientStructures() then
        logClient("Failed to initialize client structures", true)
        
        if initializeAttempts < MAX_RETRIES then
            task.delay(1, initializeClient)
        end
        return
    end
    
    clientStatus = STATUS.LOADING_CORE
    
    -- Find and load ModuleLoader
    local moduleLoaderModule = findModule("ModuleLoader")
    local ModuleLoader = nil
    
    if moduleLoaderModule then
        ModuleLoader = safeRequire(moduleLoaderModule)
        logClient("Loaded ModuleLoader")
    else
        logClient("ModuleLoader not found", true)
    end
    
    -- Find and load ClientRegistry
    local clientRegistryModule = findModule("ClientRegistry")
    local ClientRegistry = nil
    
    if clientRegistryModule then
        ClientRegistry = safeRequire(clientRegistryModule)
        logClient("Loaded ClientRegistry")
    else
        logClient("ClientRegistry not found", true)
    end
    
    clientStatus = STATUS.LOADING_UI
    
    -- Find and load UIComponents
    local uiComponentsModule = findModule("UIComponents")
    local UIComponents = nil
    
    if uiComponentsModule then
        UIComponents = safeRequire(uiComponentsModule)
        logClient("Loaded UIComponents")
    else
        logClient("UIComponents not found", true)
    end
    
    clientStatus = STATUS.LOADING_SYSTEMS
    
    -- Find and load AssetValidator
    local assetValidatorModule = findModule("AssetValidator")
    local AssetValidator = nil
    
    if assetValidatorModule then
        AssetValidator = safeRequire(assetValidatorModule)
        logClient("Loaded AssetValidator")
    else
        logClient("AssetValidator not found", true)
    end
    
    -- Connect all components with ClientRegistry
    if ClientRegistry and typeof(ClientRegistry.RegisterComponent) == "function" then
        if UIComponents then
            ClientRegistry.RegisterComponent("UIComponents", UIComponents)
        end
        
        if AssetValidator then
            ClientRegistry.RegisterComponent("AssetValidator", AssetValidator)
        end
        
        -- Register this bootstrap
        ClientRegistry.RegisterComponent("ClientBootstrap", {
            getStatus = function() return clientStatus end,
            initialize = initializeClient,
            VERSION = "1.0.0"
        })
    end
    
    -- Check if we have the minimum requirements
    if ClientRegistry and UIComponents then
        clientStatus = STATUS.READY
        initialized = true
        logClient("✅ Client initialization complete!")
    else
        clientStatus = STATUS.ERROR
        logClient("⚠️ Client initialized with errors - missing critical components", true)
        
        if initializeAttempts < MAX_RETRIES then
            logClient("Retrying initialization in 2 seconds...", true)
            task.delay(2, initializeClient)
            return
        end
    end
    
    -- Create a client-ready event
    if ClientRegistry and typeof(ClientRegistry.FireEvent) == "function" then
        ClientRegistry.FireEvent("ClientReady", clientStatus)
    end
    
    -- Load UISystemEnhancer
    loadUISystemEnhancer()
end

-- Load UISystemEnhancer
local function loadUISystemEnhancer()
    logClient("Loading UISystemEnhancer...")
    local UIFolder = ensureFolderPath(Players.LocalPlayer.PlayerScripts, {"UI"})
    
    -- Try to load the fixed version first
    local uiSystemEnhancerModule = findModule("UISystemEnhancer_fixed")
    if not uiSystemEnhancerModule then
        -- Fall back to original version if fixed version not found
        uiSystemEnhancerModule = findModule("UISystemEnhancer")
    end
    
    if not uiSystemEnhancerModule then
        logClient("UISystemEnhancer not found, skipping UI enhancements", true)
        return
    end
    
    -- Try to require UISystemEnhancer
    local success, uiSystemEnhancer = pcall(function()
        return require(uiSystemEnhancerModule)
    end)
    
    if success and uiSystemEnhancer then
        logClient("UISystemEnhancer loaded successfully")
        
        -- Register UISystemEnhancer with ClientRegistry
        if ClientRegistry and typeof(ClientRegistry.RegisterComponent) == "function" then
            ClientRegistry.RegisterComponent("UISystemEnhancer", uiSystemEnhancer)
            logClient("Registered UISystemEnhancer with ClientRegistry")
        end
        
        -- Initialize MainMenuUI
        if uiSystemEnhancer.showUI then
            task.spawn(function()
                logClient("Attempting to show MainMenuUI...")
                local shown = uiSystemEnhancer.showUI("MainMenuUI")
                if shown then
                    logClient("MainMenuUI displayed successfully")
                else
                    logClient("Failed to show MainMenuUI after attempts", true)
                end
            end)
        end
    else
        logClient("Failed to load UISystemEnhancer", true)
    end
end

-- Wait for player to be available and start initialization
if Players.LocalPlayer then
    task.spawn(initializeClient)
else
    Players:GetPropertyChangedSignal("LocalPlayer"):Connect(function()
        if Players.LocalPlayer then
            task.spawn(initializeClient)
        end
    end)
end

-- Expose client bootstrap for debugging
_G.__ClientBootstrap = {
    getStatus = function() return clientStatus end,
    initialize = initializeClient,
    isInitialized = function() return initialized end,
    version = "1.1.0"
}

-- Return a simple API for external scripts
return {
    getStatus = function() return clientStatus end,
    initialize = initializeClient,
    isInitialized = function() return initialized end,
    version = "1.1.0"
}
