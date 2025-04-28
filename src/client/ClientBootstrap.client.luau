-- ClientBootstrap.client.luau
-- Client-side initialization script
-- Created: April 28, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true
local INITIALIZATION_TIMEOUT = 5 -- seconds per stage

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[ClientBootstrap][%s] %s", level, message))
end

-- Import SafeWaitForChild utility
local function getSafeWaitForChild()
	-- Find SafeWaitForChild module
	local shared = ReplicatedStorage:FindFirstChild("shared") or ReplicatedStorage:FindFirstChild("Shared")
	
	if shared and shared:FindFirstChild("SafeWaitForChild") then
		local success, module = pcall(function()
			return require(shared.SafeWaitForChild)
		end)
		
		if success and module then
			return module
		end
	end
	
	-- Module not found or failed to load, use a minimal implementation
	log("SafeWaitForChild module not found, using minimal implementation", "Warning")
	
	return {
		Wait = function(parent, childName, timeout)
			timeout = timeout or 5
			local startTime = os.clock()
			
			while os.clock() - startTime < timeout do
				local child = parent:FindFirstChild(childName)
				if child then
					return child
				end
				wait(0.1)
			end
			
			log("Timed out waiting for " .. childName .. " in " .. parent:GetFullName(), "Warning")
			return nil
		end,
		
		EnsureChild = function(parent, childName, instanceType)
			local child = parent:FindFirstChild(childName)
			
			if not child then
				child = Instance.new(instanceType or "Folder")
				child.Name = childName
				child.Parent = parent
			end
			
			return child
		end
	}
end

-- Bootstrap object
local ClientBootstrap = {
	_version = VERSION,
	_initialized = false,
	_safeWait = getSafeWaitForChild(),
	_clientRegistry = nil,
	_moduleLoader = nil,
	_initialized = false,
	_initStages = {
		{name = "Core Path Setup", completed = false},
		{name = "ClientRegistry", completed = false},
		{name = "ModuleLoader", completed = false},
		{name = "UI Components", completed = false},
		{name = "Subsystems", completed = false}
	}
}

-- Initialize bootstrap
function ClientBootstrap:Initialize()
	if self._initialized then
		log("ClientBootstrap already initialized")
		return true
	end
	
	log("Initializing ClientBootstrap v" .. self._version)
	
	-- Make the bootstrap accessible globally for debugging
	_G.__ClientBootstrap = self
	
	-- Run initialization stages
	local success = true
	for i, stage in ipairs(self._initStages) do
		log("Starting init stage " .. i .. ": " .. stage.name)
		
		local stageSuccess = self:RunInitStage(i)
		
		if stageSuccess then
			stage.completed = true
			log("Completed init stage " .. i .. ": " .. stage.name)
		else
			stage.completed = false
			log("Failed init stage " .. i .. ": " .. stage.name, "Error")
			success = false
			
			if i <= 2 then
				-- First two stages are critical, abort if they fail
				log("Critical stage failed, aborting initialization", "Error")
				break
			end
		end
	end
	
	self._initialized = success
	log("ClientBootstrap initialization " .. (success and "succeeded" or "failed with errors"))
	
	return success
end

-- Run a specific initialization stage
function ClientBootstrap:RunInitStage(stageIndex)
	local stageName = self._initStages[stageIndex].name
	local startTime = os.clock()
	
	if stageIndex == 1 then
		-- Stage 1: Core Path Setup
		return self:SetupCorePaths()
	elseif stageIndex == 2 then
		-- Stage 2: ClientRegistry
		return self:InitializeClientRegistry()
	elseif stageIndex == 3 then
		-- Stage 3: ModuleLoader
		return self:InitializeModuleLoader()
	elseif stageIndex == 4 then
		-- Stage 4: UI Components
		return self:InitializeUIComponents()
	elseif stageIndex == 5 then
		-- Stage 5: Subsystems
		return self:InitializeSubsystems()
	else
		log("Invalid initialization stage: " .. stageIndex, "Error")
		return false
	end
end

-- Stage 1: Setup core paths
function ClientBootstrap:SetupCorePaths()
	local success = pcall(function()
		-- Ensure core paths exist
		local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
		
		-- Core folder in PlayerScripts
		local Core = playerScripts:FindFirstChild("Core")
		if not Core then
			Core = Instance.new("Folder")
			Core.Name = "Core"
			Core.Parent = playerScripts
			log("Created Core folder in PlayerScripts", "Warning")
		end
		
		-- ClientCore folder in PlayerScripts
		local ClientCore = playerScripts:FindFirstChild("ClientCore")
		if not ClientCore then
			ClientCore = Instance.new("Folder")
			ClientCore.Name = "ClientCore"
			ClientCore.Parent = playerScripts
			log("Created ClientCore folder in PlayerScripts", "Warning")
		end
		
		-- shared folder in ReplicatedStorage
		local shared = ReplicatedStorage:FindFirstChild("shared")
		if not shared then
			shared = Instance.new("Folder")
			shared.Name = "shared"
			shared.Parent = ReplicatedStorage
			log("Created shared folder in ReplicatedStorage", "Warning")
		end
		
		-- UI folder in shared
		local UI = shared:FindFirstChild("UI")
		if not UI then
			UI = Instance.new("Folder")
			UI.Name = "UI"
			UI.Parent = shared
			log("Created UI folder in shared", "Warning")
		end
		
		log("Core paths setup successful")
	end)
	
	return success
end

-- Stage 2: Initialize ClientRegistry
function ClientBootstrap:InitializeClientRegistry()
	-- Search for ClientRegistry in multiple possible locations
	local clientRegistryLocations = {
		ReplicatedStorage.shared and ReplicatedStorage.shared:FindFirstChild("ClientRegistry"),
		LocalPlayer.PlayerScripts.Core and LocalPlayer.PlayerScripts.Core:FindFirstChild("ClientRegistry"),
		LocalPlayer.PlayerScripts:FindFirstChild("ClientRegistry"),
		ReplicatedStorage:FindFirstChild("ClientRegistry"),
		LocalPlayer.PlayerScripts.Client and LocalPlayer.PlayerScripts.Client.Core and LocalPlayer.PlayerScripts.Client.Core:FindFirstChild("ClientRegistry")
	}
	
	-- Add the path we created
	if ReplicatedStorage:FindFirstChild("src") and 
	   ReplicatedStorage.src:FindFirstChild("client") and 
	   ReplicatedStorage.src.client:FindFirstChild("Core") then
		table.insert(clientRegistryLocations, ReplicatedStorage.src.client.Core:FindFirstChild("ClientRegistry"))
	end
	
	-- Find ClientRegistry in any of the locations
	local clientRegistryModule = nil
	for _, location in ipairs(clientRegistryLocations) do
		if location and location:IsA("ModuleScript") then
			clientRegistryModule = location
			log("Found ClientRegistry at: " .. location:GetFullName())
			break
		end
	end
	
	-- If not found, try to load from properly located version
	if not clientRegistryModule then
		-- Look for it in the src folder structure we created
		local clientFolder = ReplicatedStorage:FindFirstChild("src")
		if clientFolder then
			local clientCoreFolder = clientFolder:FindFirstChild("client")
			if clientCoreFolder then
				local coreFolder = clientCoreFolder:FindFirstChild("Core")
				if coreFolder and coreFolder:FindFirstChild("ClientRegistry") then
					clientRegistryModule = coreFolder.ClientRegistry
					log("Found ClientRegistry in src/client/Core folder")
				end
			end
		end
	end
	
	-- If still not found, try to run a fixer
	if not clientRegistryModule then
		-- Try to load ClientRegistryFixer if it exists
		local fixerPath = LocalPlayer.PlayerScripts.Client
		if fixerPath and fixerPath.Core and fixerPath.Core:FindFirstChild("ClientRegistryFixer") then
			log("Attempting to fix ClientRegistry using ClientRegistryFixer")
			
			local success, fixer = pcall(function()
				return require(fixerPath.Core.ClientRegistryFixer)
			end)
			
			if success and fixer and fixer.FindOrCreateClientRegistry then
				clientRegistryModule = fixer:FindOrCreateClientRegistry()
			else
				log("Failed to require ClientRegistryFixer: " .. tostring(fixer), "Error")
			end
		else
			log("Failed to require module: Players." .. LocalPlayer.Name .. ".PlayerScripts.Client.Core.ClientRegistryFixer", "Error")
		end
	end
	
	-- If still not found, create a minimal ClientRegistry module
	if not clientRegistryModule then
		log("ClientRegistry not found, creating a minimal version", "Warning")
		
		local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
		local Core = self._safeWait.EnsureChild(playerScripts, "Core", "Folder")
		
		clientRegistryModule = Core:FindFirstChild("ClientRegistry")
		if not clientRegistryModule then
			clientRegistryModule = Instance.new("ModuleScript")
			clientRegistryModule.Name = "ClientRegistry"
			clientRegistryModule.Parent = Core
			
			-- Minimal ClientRegistry implementation
			clientRegistryModule.Source = [[
				-- ClientRegistry Module (Minimal Fallback Implementation)
				-- Auto-generated by ClientBootstrap
				-- Generated: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[
				
				local ClientRegistry = {
					_registered = {},
					_version = "1.0.0-fallback",
					_isFallback = true,
				}
				
				-- Register a module or system with the ClientRegistry
				function ClientRegistry:Register(name, module)
					self._registered[name] = module
					print("ClientRegistry: Registered " .. name)
					return true
				end
				
				-- Get a registered module or system
				function ClientRegistry:Get(name)
					return self._registered[name]
				end
				
				-- Return the single registry instance
				return ClientRegistry
			]]
			
			log("Created minimal ClientRegistry module in PlayerScripts.Core", "Warning")
		end
	end
	
	-- Try to load the ClientRegistry module
	local success, clientRegistry = pcall(function()
		return require(clientRegistryModule)
	end)
	
	if success and clientRegistry then
		log("Successfully loaded ClientRegistry")
		self._clientRegistry = clientRegistry
		return true
	else
		log("Failed to require module: " .. clientRegistryModule:GetFullName() .. " - Module code did not return exactly one value", "Error")
		log("Failed to get ClientRegistry, cannot proceed with initialization", "Error")
		return false
	end
end

-- Stage 3: Initialize ModuleLoader
function ClientBootstrap:InitializeModuleLoader()
	-- Check if ClientRegistry is available
	if not self._clientRegistry then
		log("ClientRegistry not available, cannot initialize ModuleLoader", "Error")
		return false
	end
	
	-- Search for ModuleLoader in multiple possible locations
	local moduleLoaderLocations = {
		ReplicatedStorage.shared and ReplicatedStorage.shared:FindFirstChild("ModuleLoader"),
		LocalPlayer.PlayerScripts.Core and LocalPlayer.PlayerScripts.Core:FindFirstChild("ModuleLoader"),
		LocalPlayer.PlayerScripts:FindFirstChild("ModuleLoader"),
		ReplicatedStorage:FindFirstChild("ModuleLoader")
	}
	
	-- Find ModuleLoader in any of the locations
	local moduleLoaderModule = nil
	for _, location in ipairs(moduleLoaderLocations) do
		if location and location:IsA("ModuleScript") then
			moduleLoaderModule = location
			log("Found ModuleLoader at: " .. location:GetFullName())
			break
		end
	end
	
	-- If not found, create a minimal ModuleLoader module
	if not moduleLoaderModule then
		log("ModuleLoader not found, creating a minimal version", "Warning")
		
		-- Try to find a shared folder to put it in
		local shared = ReplicatedStorage:FindFirstChild("shared")
		if not shared then
			shared = Instance.new("Folder")
			shared.Name = "shared"
			shared.Parent = ReplicatedStorage
			log("Created shared folder in ReplicatedStorage", "Warning")
		end
		
		moduleLoaderModule = shared:FindFirstChild("ModuleLoader")
		if not moduleLoaderModule then
			moduleLoaderModule = Instance.new("ModuleScript")
			moduleLoaderModule.Name = "ModuleLoader"
			moduleLoaderModule.Parent = shared
			
			-- Minimal ModuleLoader implementation
			moduleLoaderModule.Source = [[
				-- ModuleLoader Module (Minimal Fallback Implementation)
				-- Auto-generated by ClientBootstrap
				-- Generated: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[
				
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				
				local ModuleLoader = {
					_loadedModules = {},
					_version = "1.0.0-fallback",
					_isFallback = true,
				}
				
				-- Load a module by path string
				function ModuleLoader:LoadModule(pathString)
					if self._loadedModules[pathString] then
						return self._loadedModules[pathString]
					end
					
					local pathParts = string.split(pathString, ".")
					local current = game
					
					for i, part in ipairs(pathParts) do
						current = current:FindFirstChild(part)
						
						if not current then
							warn("ModuleLoader: Failed to find path part " .. i .. ": " .. part)
							return nil
						end
					end
					
					if current and current:IsA("ModuleScript") then
						local success, result = pcall(function()
							return require(current)
						end)
						
						if success then
							self._loadedModules[pathString] = result
							return result
						else
							warn("ModuleLoader: Failed to require module: " .. pathString)
							return nil
						end
					else
						warn("ModuleLoader: Path does not point to a ModuleScript: " .. pathString)
						return nil
					end
				end
				
				-- Get a loaded module
				function ModuleLoader:GetModule(pathString)
					return self._loadedModules[pathString]
				end
				
				-- Return the single loader instance
				return ModuleLoader
			]]
			
			log("Created minimal ModuleLoader module in ReplicatedStorage.shared", "Warning")
		end
	end
	
	-- Try to load the ModuleLoader module
	local success, moduleLoader = pcall(function()
		return require(moduleLoaderModule)
	end)
	
	if success and moduleLoader then
		log("Successfully loaded ModuleLoader")
		self._moduleLoader = moduleLoader
		
		-- Register ModuleLoader with ClientRegistry
		self._clientRegistry:Register("ModuleLoader", moduleLoader)
		
		return true
	else
		log("Failed to require ModuleLoader: " .. tostring(moduleLoader), "Error")
		log("ModuleLoader not found, some system initialization may fail", "Warning")
		return false
	end
end

-- Stage 4: Initialize UI Components
function ClientBootstrap:InitializeUIComponents()
	-- Try to find UIComponents module
	local uiComponentsLocations = {
		ReplicatedStorage.shared and ReplicatedStorage.shared:FindFirstChild("UIComponents"),
		ReplicatedStorage.shared and ReplicatedStorage.shared.UI and ReplicatedStorage.shared.UI:FindFirstChild("UIComponents"),
		ReplicatedStorage:FindFirstChild("UIComponents"),
		ReplicatedStorage:FindFirstChild("UIModules") and ReplicatedStorage.UIModules:FindFirstChild("UIComponent")
	}
	
	-- Find UIComponents in any of the locations
	local uiComponentsModule = nil
	for _, location in ipairs(uiComponentsLocations) do
		if location and location:IsA("ModuleScript") then
			uiComponentsModule = location
			log("Found UIComponents at: " .. location:GetFullName())
			break
		end
	end
	
	-- If not found, handle the error gracefully
	if not uiComponentsModule then
		log("Could not find module for system: UIComponents", "Warning")
		return true -- Not critical, so return true anyway
	end
	
	-- Try to load the UIComponents module
	local success, uiComponents = pcall(function()
		return require(uiComponentsModule)
	end)
	
	if success and uiComponents then
		log("Successfully loaded UIComponents")
		
		-- Register UIComponents with ClientRegistry
		self._clientRegistry:Register("UIComponents", uiComponents)
		
		return true
	else
		log("Failed to require UIComponents: " .. tostring(uiComponents), "Warning")
		return true -- Not critical, so return true anyway
	end
end

-- Stage 5: Initialize Subsystems
function ClientBootstrap:InitializeSubsystems()
	-- List of subsystems to initialize
	local subsystems = {
		"NotificationSystem",
		"ClientEventBridge",
		"UIManager"
	}
	
	local initCount = 0
	
	-- Initialize each subsystem
	for _, systemName in ipairs(subsystems) do
		local success = self:InitializeSubsystem(systemName)
		if success then
			initCount = initCount + 1
		end
	end
	
	log("Initialized " .. initCount .. "/" .. #subsystems .. " subsystems")
	return true -- Always return true as this stage is not critical
end

-- Initialize a specific subsystem
function ClientBootstrap:InitializeSubsystem(systemName)
	-- Skip if ModuleLoader is not available
	if not self._moduleLoader then
		log("ModuleLoader not available, cannot initialize subsystem: " .. systemName, "Warning")
		return false
	end
	
	-- Try to load the subsystem module
	local searchPaths = {
		"ReplicatedStorage.shared." .. systemName,
		"ReplicatedStorage." .. systemName,
		"Players." .. LocalPlayer.Name .. ".PlayerScripts.Core." .. systemName,
		"Players." .. LocalPlayer.Name .. ".PlayerScripts." .. systemName
	}
	
	local systemModule = nil
	for _, path in ipairs(searchPaths) do
		systemModule = self._moduleLoader:LoadModule(path)
		if systemModule then
			log("Loaded subsystem: " .. systemName .. " from path: " .. path)
			break
		end
	end
	
	if systemModule then
		-- Register the subsystem with ClientRegistry
		self._clientRegistry:Register(systemName, systemModule)
		
		-- Initialize the subsystem if it has an Initialize method
		if systemModule.Initialize then
			local success, errorMessage = pcall(function()
				return systemModule:Initialize()
			end)
			
			if success then
				log("Initialized subsystem: " .. systemName)
				return true
			else
				log("Failed to initialize subsystem: " .. systemName .. " - " .. tostring(errorMessage), "Warning")
				return false
			end
		else
			log("Subsystem does not have an Initialize method: " .. systemName, "Warning")
			return true -- Consider it successful anyway
		end
	else
		log("Could not find module for system: " .. systemName, "Warning")
		return false
	end
end

-- Get initialization status
function ClientBootstrap:IsInitialized()
	return self._initialized
end

-- Get version information
function ClientBootstrap:GetVersion()
	return self._version
end

-- Get initialization stage information
function ClientBootstrap:GetInitStages()
	return self._initStages
end

-- Get ClientRegistry
function ClientBootstrap:GetClientRegistry()
	return self._clientRegistry
end

-- Get ModuleLoader
function ClientBootstrap:GetModuleLoader()
	return self._moduleLoader
end

-- Initialize the bootstrap
ClientBootstrap:Initialize()

return ClientBootstrap
