--!strict
--[[
    UIComponentRegistry.luau
    
    A registry for UI components in the enhanced UI system.
    Manages component discovery, registration, and instantiation.
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Import ModuleLoaderHelper
local ModuleLoaderHelper = nil
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
    else
        warn("[UIComponentRegistry] Failed to load ModuleLoaderHelper, using direct requires")
    end
end

-- Try to load UIComponentBase
local UIComponentBase
if ModuleLoaderHelper then
    UIComponentBase = ModuleLoaderHelper.loadModule("UI/UIComponentBase")
else
    local componentBasePath = ReplicatedStorage:FindFirstChild("shared") and 
                              ReplicatedStorage.shared:FindFirstChild("UI") and 
                              ReplicatedStorage.shared.UI:FindFirstChild("UIComponentBase")
    
    if componentBasePath then
        UIComponentBase = require(componentBasePath)
    else
        warn("[UIComponentRegistry] Failed to find UIComponentBase module")
    end
end

local UIComponentRegistry = {
    -- Core registry properties
    initialized = false,
    components = {}, -- Component classes by name
    instances = {}, -- Component instances by ID
    
    -- Configuration
    autoDiscovery = true,
    debug = true
}

-- Simple logging function
local function log(message, level)
    if not UIComponentRegistry.debug and level ~= "Error" then 
        return 
    end
    
    local prefix = "[UIComponentRegistry]"
    if level == "Error" then
        warn(prefix .. " " .. message)
    elseif level == "Success" then
        print(prefix .. " ✓ " .. message)
    else
        print(prefix .. " " .. message)
    end
end

--[[
    Initialize the component registry
    @param config - Configuration options
    @return - Success status
]]
function UIComponentRegistry:initialize(config)
    if self.initialized then
        return true
    end
    
    config = config or {}
    
    -- Apply configuration
    for key, value in pairs(config) do
        if self[key] ~= nil then
            self[key] = value
        end
    end
    
    -- Perform auto-discovery if enabled
    if self.autoDiscovery then
        self:discoverComponents()
    end
    
    self.initialized = true
    log("UIComponentRegistry initialized", "Success")
    
    return true
end

--[[
    Register a component class
    @param name - Name of the component
    @param componentClass - The component class (should inherit from UIComponentBase)
    @return - Success status
]]
function UIComponentRegistry:registerComponent(name, componentClass)
    if not name or typeof(name) ~= "string" then
        log("Invalid component name", "Error")
        return false
    end
    
    if not componentClass then
        log("Invalid component class for: " .. name, "Error")
        return false
    end
    
    -- Check if it's a valid component (has new function)
    if typeof(componentClass) ~= "table" or typeof(componentClass.new) ~= "function" then
        log("Component class missing .new() constructor: " .. name, "Error")
        return false
    end
    
    -- Store in registry
    self.components[name] = componentClass
    log("Registered component: " .. name, "Success")
    
    return true
end

--[[
    Get a component class by name
    @param name - Name of the component
    @return - Component class or nil if not found
]]
function UIComponentRegistry:getComponent(name)
    return self.components[name]
end

--[[
    Create a component instance
    @param name - Name of the component class
    @param props - Properties to pass to the component constructor
    @return - Component instance or nil if failed
]]
function UIComponentRegistry:createComponent(name, props)
    if not self.initialized then
        self:initialize()
    end
    
    local componentClass = self:getComponent(name)
    if not componentClass then
        log("Component not found: " .. name, "Error")
        return nil
    end
    
    -- Create the component instance
    local instance
    local success, result = pcall(function()
        return componentClass.new(props)
    end)
    
    if success then
        instance = result
        -- Register the instance if it has an ID
        if instance._id then
            self.instances[instance._id] = instance
        end
    else
        log("Failed to create component: " .. name .. " - " .. tostring(result), "Error")
        return nil
    end
    
    return instance
end

--[[
    Get a component instance by ID
    @param id - ID of the component instance
    @return - Component instance or nil if not found
]]
function UIComponentRegistry:getInstance(id)
    return self.instances[id]
end

--[[
    Unregister a component instance
    @param instance - Component instance or ID
    @return - Success status
]]
function UIComponentRegistry:unregisterInstance(instance)
    local id = instance
    if typeof(instance) == "table" and instance._id then
        id = instance._id
    end
    
    if self.instances[id] then
        self.instances[id] = nil
        return true
    end
    
    return false
end

--[[
    Discover components in the common UI folders
    @return - Number of components discovered
]]
function UIComponentRegistry:discoverComponents()
    if not ModuleLoaderHelper then
        log("ModuleLoaderHelper not available, skipping auto-discovery", "Error")
        return 0
    end
    
    local discoveryPaths = {
        "UI/Components",
        "shared/UI/Components",
        "client/UI/Components"
    }
    
    local discovered = 0
    for _, path in ipairs(discoveryPaths) do
        local folderContents = ModuleLoaderHelper.findModulesInPath(path)
        if folderContents then
            for _, moduleScript in ipairs(folderContents) do
                if moduleScript:IsA("ModuleScript") then
                    local success, component = pcall(function()
                        return require(moduleScript)
                    end)
                    
                    if success and typeof(component) == "table" and typeof(component.new) == "function" then
                        local name = moduleScript.Name:gsub("Component$", "")
                        self:registerComponent(name, component)
                        discovered += 1
                    end
                end
            end
        end
    end
    
    if discovered > 0 then
        log("Auto-discovered " .. discovered .. " components", "Success")
    end
    
    return discovered
end

--[[
    Check if a component inherits from UIComponentBase
    @param component - Component class to check
    @return - True if it inherits from UIComponentBase
]]
function UIComponentRegistry:isValidComponentClass(component)
    if not UIComponentBase or typeof(component) ~= "table" then
        return false
    end
    
    -- Check if this component has the basic UIComponentBase methods
    if typeof(component.new) ~= "function" or 
       typeof(component.render) ~= "function" or
       typeof(component.mount) ~= "function" then
        return false
    end
    
    -- Check metatable inheritance
    local mt = getmetatable(component)
    while mt do
        if mt == UIComponentBase then
            return true
        end
        mt = getmetatable(mt)
    end
    
    return false
end

--[[
    Create a compatible component from a legacy module
    @param module - Legacy UI module
    @param compatibilityLayer - Function to adapt the legacy module
    @return - Component class compatible with UIComponentBase
]]
function UIComponentRegistry:createCompatibleComponent(module, compatibilityLayer)
    if not module or not compatibilityLayer then
        return nil
    end
    
    -- Create a new component class that wraps the legacy module
    local CompatibleComponent = {}
    CompatibleComponent.__index = CompatibleComponent
    
    -- Set up inheritance from UIComponentBase
    if UIComponentBase then
        setmetatable(CompatibleComponent, UIComponentBase)
    end
    
    -- Constructor
    function CompatibleComponent.new(props)
        local self
        if UIComponentBase then
            self = UIComponentBase.new(props)
            setmetatable(self, CompatibleComponent)
        else
            self = setmetatable({
                _props = props or {},
                _id = math.random(1, 1000000),
                _name = props.name or "CompatibleComponent",
                _instance = nil
            }, CompatibleComponent)
        end
        
        -- Store the legacy module
        self._legacyModule = module
        
        return self
    end
    
    -- Override render
    function CompatibleComponent:render()
        if self._instance then
            return self._instance
        end
        
        -- Call the compatibility layer to adapt the legacy module
        self._instance = compatibilityLayer(self._legacyModule, self._props)
        
        return self._instance
    end
    
    return CompatibleComponent
end

--[[
    Clean up resources when the player leaves
]]
local function onPlayerRemoving(player)
    if player == Players.LocalPlayer then
        -- Clean up all instances
        for id, instance in pairs(UIComponentRegistry.instances) do
            if typeof(instance.destroy) == "function" then
                instance:destroy()
            end
        end
        
        UIComponentRegistry.instances = {}
    end
end

-- Connect player removing event if we're on the client
if RunService:IsClient() then
    Players.PlayerRemoving:Connect(onPlayerRemoving)
end

-- Add method to find modules in paths for compatibility with ModuleLoaderHelper
function UIComponentRegistry:findModulesInPath(path)
    if ModuleLoaderHelper and typeof(ModuleLoaderHelper.findModulesInPath) == "function" then
        return ModuleLoaderHelper.findModulesInPath(path)
    end
    
    -- Simple fallback implementation
    local searchPaths = {
        Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerScripts"),
        ReplicatedStorage,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage:FindFirstChild("client")
    }
    
    local results = {}
    for _, searchPath in ipairs(searchPaths) do
        if searchPath then
            local success, modules = pcall(function()
                local parts = string.split(path, "/")
                local current = searchPath
                
                for i, part in ipairs(parts) do
                    if current:FindFirstChild(part) then
                        current = current[part]
                    else
                        return nil
                    end
                end
                
                return current:GetChildren()
            end)
            
            if success and modules then
                for _, module in ipairs(modules) do
                    table.insert(results, module)
                end
            end
        end
    end
    
    return results
end

return UIComponentRegistry
