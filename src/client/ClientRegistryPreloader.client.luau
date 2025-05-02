--[[
    ClientRegistryPreloader.client.luau
    
    Ensures ClientRegistry and critical client modules are loaded very early
    in the initialization process. Creates necessary folder structures and
    loads UI components before other client scripts run.
    
    Similar to CoreRegistryPreloader but for client-side systems.
    
    Created as part of UI System critical fixes on May 1, 2025.
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Only run on the client
if not RunService:IsClient() then
    return
end

print("\n==== STARTING CLIENT REGISTRY PRELOADER ====")

-- Configuration
local CONFIG = {
    DEBUG = true,
    COMPONENT_TIMEOUT = 5,
    MAX_RETRIES = 3
}

-- Debug function
local function log(message, isWarning)
    if CONFIG.DEBUG then
        if isWarning then
            warn("[ClientRegistryPreloader] " .. message)
        else
            print("[ClientRegistryPreloader] " .. message)
        end
    end
end

-- Get the player
local player = Players.LocalPlayer
if not player then
    log("Waiting for LocalPlayer...", false)
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

-- Safe wait for child
local function safeWaitForChild(parent, childName, timeout)
    timeout = timeout or CONFIG.COMPONENT_TIMEOUT
    
    if not parent then
        return nil
    end
    
    -- Quick check
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    
    -- Wait with timeout
    local startTime = os.clock()
    local endTime = startTime + timeout
    
    while os.clock() < endTime do
        child = parent:FindFirstChild(childName)
        if child then
            return child
        end
        task.wait(0.1)
    end
    
    log("Timeout waiting for " .. parent:GetFullName() .. ":" .. childName, true)
    return nil
end

-- Ensure folder path exists
local function ensureFolderPath(parent, pathArray)
    if not parent then
        log("Cannot ensure folder path - parent is nil", true)
        return nil
    end
    
    local current = parent
    for _, folderName in ipairs(pathArray) do
        local folder = current:FindFirstChild(folderName)
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = current
            log("Created folder: " .. folder:GetFullName())
        end
        current = folder
    end
    return current
end

-- Find a module in different locations
local function findModule(moduleName)
    local playerScripts = player:FindFirstChild("PlayerScripts")
    local searchPaths = {
        -- Client paths
        playerScripts and playerScripts:FindFirstChild("Client") and playerScripts.Client:FindFirstChild("Core"),
        playerScripts and playerScripts:FindFirstChild("Core"),
        playerScripts and playerScripts:FindFirstChild("src") and playerScripts.src:FindFirstChild("client") and playerScripts.src.client:FindFirstChild("Core"),
        playerScripts,
        
        -- ReplicatedStorage paths
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Create or get a ModuleScript in the specified location
local function ensureModule(parent, name, source)
    if not parent then
        log("Cannot ensure module - parent is nil", true)
        return nil
    end
    
    local module = parent:FindFirstChild(name)
    if module and module:IsA("ModuleScript") then
        return module
    end
    
    if source then
        -- Try to create the module
        pcall(function()
            module = Instance.new("ModuleScript")
            module.Name = name
            module.Source = source
            module.Parent = parent
        end)
        
        if module then
            log("Created module: " .. module:GetFullName())
        end
    end
    
    return module
end

-- Safe require for modules
local function safeRequire(module, fallback)
    if not module then
        return fallback
    end
    
    if not module:IsA("ModuleScript") then
        log("Expected ModuleScript but got " .. module.ClassName .. " for " .. module:GetFullName(), true)
        return fallback
    end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        log("Failed to require " .. module:GetFullName() .. " - " .. tostring(result), true)
        return fallback
    end
end

-- Create a minimal ClientRegistry module
local function createClientRegistry(parent)
    local source = [[
-- ClientRegistry Module (Created by ClientRegistryPreloader)
-- Manages client-side systems and UI components

local ClientRegistry = {
    Version = "1.0.0",
    Initialized = false,
    Status = "Initializing"
}

-- Storage for registered systems and components
local registry = {
    systems = {},
    uiComponents = {},
    events = {}
}

-- Debug logging
local function log(message, level)
    local prefix = "[ClientRegistry]"
    if level == "Error" then
        warn(prefix .. " " .. message)
    elseif level == "Success" then
        print(prefix .. " ✓ " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Register a system
function ClientRegistry:registerSystem(name, system)
    if not name or type(name) ~= "string" then
        log("Invalid system name", "Error")
        return false
    end
    
    if system == nil then
        log("Cannot register nil system for: " .. name, "Error")
        return false
    end
    
    registry.systems[name] = system
    log("Registered system: " .. name, "Success")
    return true
end

-- Alternative registration methods for compatibility
ClientRegistry.Register = ClientRegistry.registerSystem
ClientRegistry.register = ClientRegistry.registerSystem

-- Register a UI component
function ClientRegistry:registerUIComponent(name, component)
    if not name or type(name) ~= "string" then
        log("Invalid UI component name", "Error")
        return false
    end
    
    if component == nil then
        log("Cannot register nil UI component for: " .. name, "Error")
        return false
    end
    
    registry.uiComponents[name] = component
    log("Registered UI component: " .. name, "Success")
    return true
end

-- Get a registered system
function ClientRegistry:getSystem(name)
    if not name or type(name) ~= "string" then
        log("Invalid name in getSystem", "Error")
        return nil
    end
    
    return registry.systems[name]
end

-- Alternative getters for compatibility
ClientRegistry.GetSystem = ClientRegistry.getSystem
ClientRegistry.Get = ClientRegistry.getSystem

-- Get a registered UI component
function ClientRegistry:getUIComponent(name)
    if not name or type(name) ~= "string" then
        log("Invalid name in getUIComponent", "Error")
        return nil
    end
    
    return registry.uiComponents[name]
}

-- Check if a system exists
function ClientRegistry:hasSystem(name)
    return registry.systems[name] ~= nil
}

-- Register an event handler
function ClientRegistry:registerEvent(name, callback)
    if not registry.events[name] then
        registry.events[name] = {}
    end
    
    table.insert(registry.events[name], callback)
    return true
}

-- Fire an event
function ClientRegistry:fireEvent(name, ...)
    local handlers = registry.events[name]
    if handlers then
        for _, callback in ipairs(handlers) do
            task.spawn(function()
                callback(...)
            end)
        end
    end
}

-- Initialize the registry
function ClientRegistry:initialize()
    if self.Initialized then
        return true
    end
    
    log("Initializing ClientRegistry")
    
    -- Register self in the registry
    self:registerSystem("ClientRegistry", self)
    
    self.Initialized = true
    self.Status = "Ready"
    log("ClientRegistry initialized successfully!", "Success")
    
    -- Fire initialized event
    self:fireEvent("ClientRegistryReady", self)
    
    return true
}

-- Auto-initialize
task.spawn(function()
    ClientRegistry:initialize()
end)

return ClientRegistry
]]
    
    return ensureModule(parent, "ClientRegistry", source)
end

-- Create a minimal UIComponents module
local function createUIComponents(parent)
    local source = [[
-- UIComponents Module (Created by ClientRegistryPreloader)
-- Provides basic UI component creation functions

local UIComponents = {
    Version = "1.0.0",
    Initialized = false
}

-- Storage for registered components
local components = {}

-- Register a component
function UIComponents:registerComponent(name, component)
    components[name] = component
    return component
end

-- Get a registered component
function UIComponents:getComponent(name)
    return components[name]
end

-- Basic button creation
function UIComponents:createButton(text, size)
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
function UIComponents:createFrame(size)
    local frame = Instance.new("Frame")
    frame.Size = size or UDim2.new(0, 300, 0, 200)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    return frame
end

-- Basic label creation
function UIComponents:createLabel(text, size)
    local label = Instance.new("TextLabel")
    label.Size = size or UDim2.new(0, 200, 0, 50)
    label.Text = text or "Label"
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    return label
end

-- Initialize the system
function UIComponents:initialize()
    if self.Initialized then
        return true
    end
    
    print("[UIComponents] Initializing UIComponents")
    
    -- Register basic components
    self:registerComponent("Button", self.createButton)
    self:registerComponent("Frame", self.createFrame)
    self:registerComponent("Label", self.createLabel)
    
    self.Initialized = true
    print("[UIComponents] UIComponents initialized successfully!")
    
    return true
end

-- Auto-initialize
task.spawn(function()
    UIComponents:initialize()
end)

return UIComponents
]]
    
    return ensureModule(parent, "UIComponents", source)
end

-- Create a minimal AssetValidator module
local function createAssetValidator(parent)
    local source = [[
-- AssetValidator Module (Created by ClientRegistryPreloader)
-- Validates and formats asset IDs for images, sounds, etc.

local AssetValidator = {
    Version = "1.0.0",
    Initialized = false
}

-- Validate an asset ID
function AssetValidator:validateAsset(assetId, assetType)
    -- Basic validation - ensures its a number in string/number form
    if not assetId then
        return false
    end
    
    -- Convert rbxassetid:// format if needed
    local id = tostring(assetId)
    id = id:gsub("rbxassetid://", "")
    
    -- Check if it's a number
    local numericId = tonumber(id)
    if not numericId then
        return false
    end
    
    return true, numericId
end

-- Get a validated image asset
function AssetValidator:getValidatedImageAsset(imageId, fallback)
    local isValid, id = self:validateAsset(imageId)
    if isValid then
        return "rbxassetid://" .. id
    end
    return fallback or "rbxassetid://0"
end

-- Get a validated sound asset
function AssetValidator:getValidatedSoundAsset(soundId, fallback)
    local isValid, id = self:validateAsset(soundId)
    if isValid then
        return "rbxassetid://" .. id
    end
    return fallback or "rbxassetid://0"
end

-- Initialize the system
function AssetValidator:initialize()
    if self.Initialized then
        return true
    end
    
    print("[AssetValidator] Initializing AssetValidator")
    
    self.Initialized = true
    print("[AssetValidator] AssetValidator initialized successfully!")
    
    return true
end

-- Compatibility aliases
AssetValidator.ValidateAsset = AssetValidator.validateAsset
AssetValidator.GetValidatedImageAsset = AssetValidator.getValidatedImageAsset
AssetValidator.GetValidatedSoundAsset = AssetValidator.getValidatedSoundAsset

-- Auto-initialize
task.spawn(function()
    AssetValidator:initialize()
end)

return AssetValidator
]]
    
    return ensureModule(parent, "AssetValidator", source)
end

-- Create a minimal UIRegistry module
local function createUIRegistry(parent)
    local source = [[
-- UIRegistry Module (Created by ClientRegistryPreloader)
-- Manages UI components, styles, and factories

local UIRegistry = {
    Version = "1.0.0",
    Initialized = false
}

-- UI component storage
local components = {}

-- Register a component in the registry
function UIRegistry:registerComponent(name, component)
    if not name or type(name) ~= "string" then
        warn("[UIRegistry] Invalid component name")
        return false
    end
    
    components[name] = component
    print("[UIRegistry] Registered component: " .. name)
    return true
end

-- Get a component from the registry
function UIRegistry:getComponent(name)
    return components[name]
end

-- Initialize basic UI components
function UIRegistry:initialize()
    if self.Initialized then
        return true
    end
    
    print("[UIRegistry] Initializing UIRegistry")
    
    -- Basic UI style
    self:registerComponent("UIStyle", {
        colors = {
            background = Color3.fromRGB(40, 40, 60),
            text = Color3.fromRGB(240, 240, 240),
            accent = Color3.fromRGB(80, 160, 240),
            success = Color3.fromRGB(80, 200, 120),
            warning = Color3.fromRGB(240, 200, 80),
            error = Color3.fromRGB(240, 80, 80)
        },
        fonts = {
            header = Enum.Font.GothamBold,
            body = Enum.Font.Gotham
        },
        applyStyle = function(component, style)
            -- Apply styling based on component type
            if component:IsA("TextLabel") or component:IsA("TextButton") then
                component.TextColor3 = style.colors.text
                component.Font = style.fonts.body
            end
            
            if component:IsA("Frame") or component:IsA("TextButton") then
                component.BackgroundColor3 = style.colors.background
            end
        end
    })
    
    -- Basic button factory
    self:registerComponent("ButtonFactory", {
        createBasicButton = function(text, size, callback)
            local button = Instance.new("TextButton")
            button.Size = size or UDim2.new(0, 200, 0, 50)
            button.Text = text or "Button"
            button.BackgroundColor3 = components.UIStyle.colors.accent
            button.BorderSizePixel = 0
            button.TextColor3 = components.UIStyle.colors.text
            button.Font = components.UIStyle.fonts.body
            button.TextSize = 14
            
            if callback then
                button.MouseButton1Click:Connect(callback)
            end
            
            return button
        end
    })
    
    -- Basic dialog factory
    self:registerComponent("DialogFactory", {
        createNotification = function(options)
            options = options or {}
            local title = options.title or "Notification"
            local message = options.message or ""
            local type = options.type or "info" -- info, success, warning, error
            local duration = options.duration or 5
            
            -- Create UI
            local player = game:GetService("Players").LocalPlayer
            local playerGui = player:FindFirstChild("PlayerGui")
            if not playerGui then return nil end
            
            local notification = Instance.new("ScreenGui")
            notification.Name = "Notification_" .. os.time()
            notification.Parent = playerGui
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 300, 0, 100)
            frame.Position = UDim2.new(1, -320, 0, 20)
            frame.BackgroundColor3 = components.UIStyle.colors.background
            frame.BorderSizePixel = 0
            frame.Parent = notification
            
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, 0, 0, 30)
            titleLabel.Position = UDim2.new(0, 0, 0, 0)
            titleLabel.Text = title
            titleLabel.TextColor3 = components.UIStyle.colors.text
            titleLabel.Font = components.UIStyle.fonts.header
            titleLabel.TextSize = 16
            titleLabel.BackgroundTransparency = 1
            titleLabel.Parent = frame
            
            local messageLabel = Instance.new("TextLabel")
            messageLabel.Size = UDim2.new(1, -20, 1, -40)
            messageLabel.Position = UDim2.new(0, 10, 0, 30)
            messageLabel.Text = message
            messageLabel.TextColor3 = components.UIStyle.colors.text
            messageLabel.Font = components.UIStyle.fonts.body
            messageLabel.TextSize = 14
            messageLabel.TextWrapped = true
            messageLabel.BackgroundTransparency = 1
            messageLabel.Parent = frame
            
            -- Color based on type
            local typeColor = components.UIStyle.colors.accent
            if type == "success" then
                typeColor = components.UIStyle.colors.success
            elseif type == "warning" then
                typeColor = components.UIStyle.colors.warning
            elseif type == "error" then
                typeColor = components.UIStyle.colors.error
            end
            
            local colorBar = Instance.new("Frame")
            colorBar.Size = UDim2.new(0, 5, 1, 0)
            colorBar.Position = UDim2.new(0, 0, 0, 0)
            colorBar.BackgroundColor3 = typeColor
            colorBar.BorderSizePixel = 0
            colorBar.Parent = frame
            
            -- Animate in
            frame:TweenPosition(UDim2.new(1, -320, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
            
            -- Auto-remove after duration
            task.delay(duration, function()
                frame:TweenPosition(UDim2.new(1, 20, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true, function()
                    notification:Destroy()
                end)
            end)
            
            return notification
        end,
        
        showNotification = function(title, message, type, duration)
            return UIRegistry.DialogFactory.createNotification({
                title = title,
                message = message,
                type = type,
                duration = duration
            })
        end
    })
    
    -- Icon set
    self:registerComponent("IconSet", {
        icons = {
            settings = "rbxassetid://3926307971",
            close = "rbxassetid://3926305904",
            warning = "rbxassetid://3926305904",
            info = "rbxassetid://3926305904"
        },
        getIcon = function(iconName)
            return UIRegistry.IconSet.icons[iconName] or ""
        end
    })
    
    self.Initialized = true
    print("[UIRegistry] UIRegistry initialized successfully!")
    
    -- Make properties accessible directly
    self.ButtonFactory = components.ButtonFactory
    self.DialogFactory = components.DialogFactory
    self.UIStyle = components.UIStyle
    self.IconSet = components.IconSet
    
    return true
end

-- Auto-initialize
task.spawn(function()
    UIRegistry:initialize()
end)

return UIRegistry
]]
    
    return ensureModule(parent, "UIRegistry", source)
end

-- Create ModuleScriptAccessor
local function createModuleScriptAccessor(parent)
    local source = [[
-- ModuleScriptAccessor Module (Created by ClientRegistryPreloader)
-- Provides centralized access to modules, systems, and registries

local ModuleScriptAccessor = {}

-- Find module in different locations
local function findModule(moduleName)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players.LocalPlayer
    
    if not player then
        warn("[ModuleScriptAccessor] No LocalPlayer found")
        return nil
    end
    
    -- Search paths
    local searchPaths = {
        -- Client paths
        player.PlayerScripts,
        player.PlayerScripts:FindFirstChild("Client") and player.PlayerScripts.Client:FindFirstChild("Core"),
        player.PlayerScripts:FindFirstChild("Core"),
        player.PlayerScripts:FindFirstChild("src") and player.PlayerScripts.src:FindFirstChild("client") and player.PlayerScripts.src.client:FindFirstChild("Core"),
        
        -- ReplicatedStorage paths
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    return nil
end

-- Get a system via ClientRegistry
function ModuleScriptAccessor:getSystem(systemName)
    local clientRegistry = self:getClientRegistry()
    if clientRegistry and typeof(clientRegistry.getSystem) == "function" then
        return clientRegistry:getSystem(systemName)
    end
    
    -- Try direct module require if ClientRegistry failed
    local moduleScript = findModule(systemName)
    if moduleScript then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            return result
        end
    end
    
    return nil
end

-- Get ClientRegistry
function ModuleScriptAccessor:getClientRegistry()
    local clientRegistryModule = findModule("ClientRegistry")
    if clientRegistryModule then
        local success, result = pcall(function()
            return require(clientRegistryModule)
        end)
        
        if success then
            return result
        end
    end
    
    return nil
end

-- Get CoreRegistry
function ModuleScriptAccessor:getCoreRegistry()
    local shared = game:GetService("ReplicatedStorage"):FindFirstChild("shared")
    if shared and shared:FindFirstChild("CoreRegistry") then
        local success, result = pcall(function()
            return require(shared.CoreRegistry)
        end)
        
        if success then
            return result
        end
    end
    
    return nil
end

-- Get a module directly
function ModuleScriptAccessor:getModule(moduleName)
    local moduleScript = findModule(moduleName)
    if moduleScript then
        local success, result = pcall(function()
            return require(moduleScript)
        end)
        
        if success then
            return result
        end
    end
    
    return nil
end

return ModuleScriptAccessor
]]
    
    return ensureModule(parent, "ModuleScriptAccessor", source)
end

-- Main function to ensure client structure
local function ensureClientStructure()
    -- Ensure important folders exist
    local coreFolder = ensureFolderPath(player.PlayerScripts, {"Client", "Core"})
    ensureFolderPath(player.PlayerScripts, {"Client", "UI"})
    
    -- Create ModuleScriptAccessor in shared folder
    local shared = ensureFolderPath(ReplicatedStorage, {"shared"})
    local moduleScriptAccessor = createModuleScriptAccessor(shared)
    
    -- Ensure ClientRegistry exists
    local clientRegistry = findModule("ClientRegistry")
    if not clientRegistry then
        log("ClientRegistry not found, creating it")
        clientRegistry = createClientRegistry(coreFolder)
    end
    
    -- Ensure UIComponents exists
    local uiComponents = findModule("UIComponents")
    if not uiComponents then
        log("UIComponents not found, creating it")
        uiComponents = createUIComponents(coreFolder)
    end
    
    -- Ensure AssetValidator exists
    local assetValidator = findModule("AssetValidator")
    if not assetValidator then
        log("AssetValidator not found, creating it")
        assetValidator = createAssetValidator(coreFolder)
    end
    
    -- Ensure UIRegistry exists
    local uiRegistry = findModule("UIRegistry")
    if not uiRegistry then
        log("UIRegistry not found, creating it")
        uiRegistry = createUIRegistry(coreFolder)
    end
    
    -- Create shared folder references
    for _, moduleInfo in ipairs({
        {name = "ClientRegistry", source = "return require(game:GetService('Players').LocalPlayer.PlayerScripts.Client.Core.ClientRegistry)"},
        {name = "UIComponents", source = "return require(game:GetService('Players').LocalPlayer.PlayerScripts.Client.Core.UIComponents)"},
        {name = "AssetValidator", source = "return require(game:GetService('Players').LocalPlayer.PlayerScripts.Client.Core.AssetValidator)"},
        {name = "UIRegistry", source = "return require(game:GetService('Players').LocalPlayer.PlayerScripts.Client.Core.UIRegistry)"}
    }) do
        if not shared:FindFirstChild(moduleInfo.name) then
            local reference = Instance.new("ModuleScript")
            reference.Name = moduleInfo.name
            reference.Source = moduleInfo.source
            reference.Parent = shared
            log("Created shared reference: " .. reference:GetFullName())
        end
    end
    
    return true
end

-- Function to initialize all modules
local function initializeClientModules()
    local attempts = 0
    local success = false
    
    -- Require ModuleScriptAccessor
    local shared = ReplicatedStorage:FindFirstChild("shared")
    local moduleScriptAccessor = shared and shared:FindFirstChild("ModuleScriptAccessor")
    local ModuleScriptAccessor = nil
    
    if moduleScriptAccessor then
        ModuleScriptAccessor = safeRequire(moduleScriptAccessor)
        if ModuleScriptAccessor then
            log("ModuleScriptAccessor loaded successfully")
        end
    end
    
    -- Try to get ClientRegistry
    local clientRegistry = nil
    
    while attempts < CONFIG.MAX_RETRIES and not success do
        attempts += 1
        log("Initializing client modules (attempt " .. attempts .. "/" .. CONFIG.MAX_RETRIES .. ")")
        
        -- Try to get ClientRegistry
        if ModuleScriptAccessor then
            clientRegistry = ModuleScriptAccessor:getClientRegistry()
        else
            -- Direct require fallback
            local clientRegistryModule = findModule("ClientRegistry")
            if clientRegistryModule then
                clientRegistry = safeRequire(clientRegistryModule)
            end
        end
        
        if clientRegistry then
            log("ClientRegistry found")
            
            -- Initialize ClientRegistry if needed
            if typeof(clientRegistry.initialize) == "function" and not clientRegistry.Initialized then
                log("Initializing ClientRegistry")
                clientRegistry:initialize()
            end
            
            -- Try to get and initialize the modules
            local modules = {
                UIComponents = findModule("UIComponents"),
                AssetValidator = findModule("AssetValidator"),
                UIRegistry = findModule("UIRegistry")
            }
            
            for name, moduleScript in pairs(modules) do
                if moduleScript then
                    local module = safeRequire(moduleScript)
                    if module then
                        log(name .. " loaded successfully")
                        
                        -- Initialize if needed
                        if typeof(module.initialize) == "function" and not module.Initialized then
                            log("Initializing " .. name)
                            module:initialize()
                        end
                        
                        -- Register with ClientRegistry
                        if typeof(clientRegistry.registerSystem) == "function" then
                            clientRegistry:registerSystem(name, module)
                            log("Registered " .. name .. " with ClientRegistry")
                        end
                    end
                end
            end
            
            success = true
        else
            log("ClientRegistry not found, will retry", true)
            task.wait(0.5)
        end
    end
    
    return success
end

-- Integrate with CoreRegistry if available
local function integrateWithCoreRegistry()
    local shared = ReplicatedStorage:FindFirstChild("shared")
    if not shared then
        return false
    end
    
    local coreRegistryModule = shared:FindFirstChild("CoreRegistry")
    if not coreRegistryModule then
        log("CoreRegistry not found in shared folder", true)
        return false
    end
    
    local CoreRegistry = safeRequire(coreRegistryModule)
    if not CoreRegistry then
        log("Failed to require CoreRegistry", true)
        return false
    end
    
    log("Integrating with CoreRegistry")
    
    -- Find client modules
    local clientModules = {
        ClientRegistry = findModule("ClientRegistry"),
        UIComponents = findModule("UIComponents"),
        AssetValidator = findModule("AssetValidator"),
        UIRegistry = findModule("UIRegistry")
    }
    
    -- Register client systems with CoreRegistry
    local registeredCount = 0
    for name, moduleScript in pairs(clientModules) do
        if moduleScript then
            local module = safeRequire(moduleScript)
            if module and typeof(CoreRegistry.registerSystem) == "function" then
                CoreRegistry.registerSystem(name, module)
                log("Registered " .. name .. " with CoreRegistry")
                registeredCount += 1
            end
        end
    end
    
    log("Registered " .. registeredCount .. " client systems with CoreRegistry")
    return registeredCount > 0
end

-- Main execution
local function main()
    -- Ensure client structure
    local structureOk = ensureClientStructure()
    if not structureOk then
        log("Failed to ensure client structure", true)
        return
    end
    
    -- Initialize modules
    local initOk = initializeClientModules()
    if not initOk then
        log("Failed to initialize client modules", true)
    end
    
    -- Try to integrate with CoreRegistry
    local integrationOk = integrateWithCoreRegistry()
    if not integrationOk then
        log("Failed to integrate with CoreRegistry", true)
    end
    
    log("ClientRegistryPreloader completed " .. 
        (structureOk and "✓" or "✗") .. " " ..
        (initOk and "✓" or "✗") .. " " ..
        (integrationOk and "✓" or "✗"))
    
    -- Show notification if possible
    task.delay(2, function()
        local moduleAccessor = safeRequire(findModule("ModuleScriptAccessor"))
        if moduleAccessor then
            local uiRegistry = moduleAccessor:getSystem("UIRegistry")
            if uiRegistry and uiRegistry.DialogFactory and typeof(uiRegistry.DialogFactory.showNotification) == "function" then
                uiRegistry.DialogFactory.showNotification(
                    "Client Registry Fixed",
                    "ClientRegistryPreloader has initialized all client UI systems",
                    "success",
                    5
                )
            end
        end
    end)
end

print("==== CLIENT REGISTRY PRELOADER COMPLETE ====\n")

-- Start after a short delay to allow other scripts to run first
task.spawn(function()
    main()
end)
