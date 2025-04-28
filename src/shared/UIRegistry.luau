-- UIRegistry.luau
-- Central registry for UI components and systems
-- Created: April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[UIRegistry][%s] %s", level, message))
end

-- Safe require function that won't throw errors
local function safeRequire(moduleScript)
	if not moduleScript then
		return nil
	end
	
	if not moduleScript:IsA("ModuleScript") then
		return nil
	end
	
	local success, result = pcall(function()
		return require(moduleScript)
	end)
	
	if success then
		return result
	else
		return nil
	end
end

-- Try to find ModuleLoader
local function getModuleLoader()
	local shared = ReplicatedStorage:FindFirstChild("shared")
	if shared and shared:FindFirstChild("ModuleLoader") then
		return safeRequire(shared.ModuleLoader)
	end
	
	local src = ReplicatedStorage:FindFirstChild("src")
	if src and src:FindFirstChild("shared") and src.shared:FindFirstChild("ModuleLoader") then
		return safeRequire(src.shared.ModuleLoader)
	end
	
	return nil
end

-- UIRegistry object
local UIRegistry = {
	_version = VERSION,
	_uiComponents = {}, -- UI components by name
	_uiModules = {}, -- UI module references
	_templates = {}, -- UI templates
	_uiStyles = {}, -- UI styles
	_uiEvents = {}, -- Event connections for UI
	_initialized = false
}

-- Initialize the UI Registry
function UIRegistry:Initialize()
	if self._initialized then
		return true
	end
	
	log("Initializing UIRegistry v" .. self._version)
	
	-- Register with ClientRegistry if available
	local moduleLoader = getModuleLoader()
	if moduleLoader then
		local clientRegistry = moduleLoader:GetModule("ClientRegistry")
		if clientRegistry then
			clientRegistry:Register("UIRegistry", self)
			log("Registered with ClientRegistry")
		else
			log("ClientRegistry not found, skipping registration", "Warning")
		end
	else
		log("ModuleLoader not found, skipping registration", "Warning")
	end
	
	-- Load UIComponents if available
	if moduleLoader then
		local uiComponents = moduleLoader:GetModule("UIComponents")
		if uiComponents then
			self:RegisterComponent("UIComponents", uiComponents)
			log("Loaded UIComponents module")
		else
			log("UIComponents module not found", "Warning")
		end
		
		-- Load AssetValidator if available
		local assetValidator = moduleLoader:GetModule("AssetValidator")
		if assetValidator then
			self:RegisterComponent("AssetValidator", assetValidator)
			log("Loaded AssetValidator module")
		else
			log("AssetValidator module not found", "Warning")
		end
	end
	
	-- Load UI modules from ReplicatedStorage.UIModules if available
	local uiModules = ReplicatedStorage:FindFirstChild("UIModules")
	if uiModules then
		for _, module in ipairs(uiModules:GetChildren()) do
			if module:IsA("ModuleScript") then
				self:LoadUIModule(module)
			end
		end
		log("Loaded UI modules from ReplicatedStorage.UIModules")
	else
		log("UIModules folder not found", "Warning")
	end
	
	self._initialized = true
	return true
end

-- Register a UI component
function UIRegistry:RegisterComponent(name, component)
	if not name or not component then
		return false
	end
	
	self._uiComponents[name] = component
	log("Registered component: " .. name)
	return true
end

-- Get a registered UI component
function UIRegistry:GetComponent(name)
	return self._uiComponents[name]
end

-- Check if a component is registered
function UIRegistry:HasComponent(name)
	return self._uiComponents[name] ~= nil
end

-- Get all registered component names
function UIRegistry:GetComponentNames()
	local names = {}
	for name, _ in pairs(self._uiComponents) do
		table.insert(names, name)
	end
	return names
end

-- Load a UI module and register it
function UIRegistry:LoadUIModule(moduleScript)
	if not moduleScript or not moduleScript:IsA("ModuleScript") then
		return false
	end
	
	local moduleName = moduleScript.Name
	
	-- Check if we've already loaded this module
	if self._uiModules[moduleName] then
		return true
	end
	
	-- Require the module
	local module = safeRequire(moduleScript)
	if not module then
		log("Failed to require UI module: " .. moduleName, "Warning")
		return false
	end
	
	-- Register the module
	self._uiModules[moduleName] = module
	log("Loaded UI module: " .. moduleName)
	
	-- If the module has a Component property, register it as a component too
	if module.Component then
		self:RegisterComponent(moduleName, module.Component)
	end
	
	return true
end

-- Get a loaded UI module
function UIRegistry:GetModule(moduleName)
	return self._uiModules[moduleName]
end

-- Check if a module is loaded
function UIRegistry:HasModule(moduleName)
	return self._uiModules[moduleName] ~= nil
end

-- Create a UI template
function UIRegistry:CreateTemplate(templateName, createFunc)
	if not templateName or not createFunc or type(createFunc) ~= "function" then
		return false
	end
	
	self._templates[templateName] = createFunc
	log("Created template: " .. templateName)
	return true
end

-- Get a UI template
function UIRegistry:GetTemplate(templateName, ...)
	local template = self._templates[templateName]
	if not template then
		log("Template not found: " .. templateName, "Warning")
		return nil
	end
	
	-- Create an instance of the template
	return template(...)
end

-- Set a UI style property
function UIRegistry:SetStyle(styleName, value)
	self._uiStyles[styleName] = value
	log("Set style: " .. styleName)
	return true
end

-- Get a UI style property
function UIRegistry:GetStyle(styleName, defaultValue)
	local value = self._uiStyles[styleName]
	if value == nil then
		return defaultValue
	end
	return value
end

-- Create an event for UI interactions
function UIRegistry:CreateEvent(eventName)
	local event = self._uiEvents[eventName]
	if not event then
		event = Instance.new("BindableEvent")
		self._uiEvents[eventName] = event
		log("Created UI event: " .. eventName)
	end
	return event
end

-- Connect a handler to a UI event
function UIRegistry:ConnectEvent(eventName, handler)
	local event = self:CreateEvent(eventName)
	local connection = event.Event:Connect(handler)
	return connection
end

-- Fire a UI event
function UIRegistry:FireEvent(eventName, ...)
	local event = self._uiEvents[eventName]
	if event then
		event:Fire(...)
	else
		log("Event not found: " .. eventName, "Warning")
	end
end

-- Get the UIRegistry version
function UIRegistry:GetVersion()
	return self._version
end

-- Create a notification
function UIRegistry:CreateNotification(title, message, notificationType)
	local uiComponents = self:GetComponent("UIComponents")
	if uiComponents and uiComponents.CreateNotification then
		return uiComponents:CreateNotification(title, message, notificationType)
	else
		log("UIComponents not available, cannot create notification", "Warning")
		
		-- Fallback notification
		local player = Players.LocalPlayer
		if player then
			local notification = Instance.new("ScreenGui")
			notification.Name = "SimpleNotification"
			
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 300, 0, 100)
			frame.Position = UDim2.new(1, -320, 1, -120)
			frame.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
			frame.Parent = notification
			
			local titleLabel = Instance.new("TextLabel")
			titleLabel.Size = UDim2.new(1, -20, 0, 30)
			titleLabel.Position = UDim2.new(0, 10, 0, 10)
			titleLabel.BackgroundTransparency = 1
			titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			titleLabel.Font = Enum.Font.GothamBold
			titleLabel.TextSize = 18
			titleLabel.Text = title or "Notification"
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.Parent = frame
			
			local messageLabel = Instance.new("TextLabel")
			messageLabel.Size = UDim2.new(1, -20, 0, 40)
			messageLabel.Position = UDim2.new(0, 10, 0, 50)
			messageLabel.BackgroundTransparency = 1
			messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			messageLabel.Font = Enum.Font.Gotham
			messageLabel.TextSize = 14
			messageLabel.Text = message or ""
			messageLabel.TextXAlignment = Enum.TextXAlignment.Left
			messageLabel.TextWrapped = true
			messageLabel.Parent = frame
			
			notification.Parent = player.PlayerGui
			
			-- Auto-remove after a delay
			spawn(function()
				wait(5)
				notification:Destroy()
			end)
			
			return notification
		end
	end
end

-- Create a dialog
function UIRegistry:CreateDialog(title, content, buttons)
	local uiComponents = self:GetComponent("UIComponents")
	if uiComponents and uiComponents.CreateDialog then
		return uiComponents:CreateDialog(title, content, buttons)
	else
		log("UIComponents not available, cannot create dialog", "Warning")
		return nil
	end
end

-- Get UI diagnostic information
function UIRegistry:GetDiagnostics()
	local componentCount = 0
	for _ in pairs(self._uiComponents) do
		componentCount = componentCount + 1
	end
	
	local moduleCount = 0
	for _ in pairs(self._uiModules) do
		moduleCount = moduleCount + 1
	end
	
	local templateCount = 0
	for _ in pairs(self._templates) do
		templateCount = templateCount + 1
	end
	
	return {
		version = self._version,
		initialized = self._initialized,
		componentCount = componentCount,
		moduleCount = moduleCount,
		templateCount = templateCount
	}
end

-- Initialize the registry
UIRegistry:Initialize()

-- Make globally accessible for debugging
if _G then
	_G.__UIRegistry = UIRegistry
end

return UIRegistry
