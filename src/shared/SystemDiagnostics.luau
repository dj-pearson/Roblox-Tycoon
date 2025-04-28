-- SystemDiagnostics.luau
-- Utility module for diagnosing system issues
-- Created: April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" and level ~= "Success" then return end
	
	local prefix = "[SystemDiagnostics]"
	if level == "Success" then
		print(prefix .. " ✓ " .. message)
	elseif level == "Error" then
		print(prefix .. " ✗ " .. message)
	else
		print(prefix .. " " .. message)
	end
end

-- Safe wait for child function with timeout
local function safeWaitForChild(parent, childName, timeout)
	timeout = timeout or 5
	local startTime = os.clock()
	
	while os.clock() - startTime < timeout do
		local child = parent:FindFirstChild(childName)
		if child then
			return child
		end
		wait(0.1)
	end
	
	return nil -- Timed out
end

-- Safe require function that won't throw errors
local function safeRequire(moduleScript)
	if not moduleScript then
		return nil, "Module is nil"
	end
	
	if not moduleScript:IsA("ModuleScript") then
		return nil, "Not a ModuleScript"
	end
	
	local success, result = pcall(function()
		return require(moduleScript)
	end)
	
	if success then
		return result, nil
	else
		return nil, result
	end
end

-- SystemDiagnostics object
local SystemDiagnostics = {
	_version = VERSION,
	_results = {},
	_stats = {
		total = 0,
		passed = 0,
		failed = 0,
		warnings = 0
	}
}

-- Record a test result
function SystemDiagnostics:RecordResult(testName, passed, details, severity)
	severity = severity or (passed and "Info" or "Error")
	
	self._stats.total = self._stats.total + 1
	
	if passed then
		self._stats.passed = self._stats.passed + 1
		log(testName .. ": " .. (details or "Passed"), "Success")
	else
		if severity == "Warning" then
			self._stats.warnings = self._stats.warnings + 1
			log(testName .. ": " .. (details or "Warning"), "Warning")
		else
			self._stats.failed = self._stats.failed + 1
			log(testName .. ": " .. (details or "Failed"), "Error")
		end
	end
	
	table.insert(self._results, {
		testName = testName,
		passed = passed,
		details = details,
		severity = severity,
		timestamp = os.time()
	})
	
	return passed
end

-- Check if a module exists
function SystemDiagnostics:CheckModuleExists(parent, moduleName)
	local module = parent:FindFirstChild(moduleName)
	if not module then
		return false, "Module not found"
	end
	
	if not module:IsA("ModuleScript") then
		return false, "Instance is not a ModuleScript"
	end
	
	return true, "Module found"
end

-- Test if a module can be required
function SystemDiagnostics:TestRequireModule(parent, moduleName)
	local module = parent:FindFirstChild(moduleName)
	if not module then
		return false, "Module not found"
	end
	
	if not module:IsA("ModuleScript") then
		return false, "Instance is not a ModuleScript"
	end
	
	local success, result = safeRequire(module)
	if not success then
		return false, "Failed to require module: " .. tostring(result)
	end
	
	return true, "Module loaded successfully"
end

-- Check if CoreRegistry exists and is working
function SystemDiagnostics:CheckCoreRegistry()
	log("Checking CoreRegistry...")
	
	-- Look for CoreRegistry in ServerScriptService.Core
	local core = ServerScriptService:FindFirstChild("Core")
	if not core then
		return self:RecordResult("CoreRegistry", false, "Core folder not found in ServerScriptService")
	end
	
	local coreRegistry = core:FindFirstChild("CoreRegistry")
	if not coreRegistry then
		return self:RecordResult("CoreRegistry", false, "CoreRegistry not found in ServerScriptService.Core")
	end
	
	-- Try to require it
	local registry, errorMessage = safeRequire(coreRegistry)
	if not registry then
		return self:RecordResult("CoreRegistry", false, "Failed to require CoreRegistry: " .. tostring(errorMessage))
	end
	
	-- Check if it has the expected methods
	if type(registry.Register) ~= "function" then
		return self:RecordResult("CoreRegistry", false, "CoreRegistry lacks Register method")
	end
	
	if type(registry.Get) ~= "function" then
		return self:RecordResult("CoreRegistry", false, "CoreRegistry lacks Get method")
	end
	
	-- Check if it's properly initialized
	if registry._health and registry._health == "OPERATIONAL" then
		return self:RecordResult("CoreRegistry", true, "CoreRegistry is operational")
	else
		return self:RecordResult("CoreRegistry", false, "CoreRegistry health status is not OPERATIONAL")
	end
end

-- Check if GymAutomation modules exist and are working
function SystemDiagnostics:CheckGymAutomation()
	log("Checking GymAutomation...")
	
	-- Search for GymAutomationManager
	local managerLocations = {
		ServerScriptService:FindFirstChild("GymAutomation"),
		ServerStorage:FindFirstChild("GymAutomation"),
		ServerScriptService:FindFirstChild("server") and ServerScriptService.server:FindFirstChild("GymAutomation")
	}
	
	local manager = nil
	for _, location in ipairs(managerLocations) do
		if location and location:FindFirstChild("GymAutomationManager") then
			manager = location:FindFirstChild("GymAutomationManager")
			break
		end
	end
	
	if not manager then
		return self:RecordResult("GymAutomation", false, "GymAutomationManager not found in any expected location")
	end
	
	-- Try to require it
	local gymManager, errorMessage = safeRequire(manager)
	if not gymManager then
		return self:RecordResult("GymAutomation", false, "Failed to require GymAutomationManager: " .. tostring(errorMessage))
	end
	
	-- Check if it's initialized
	if type(gymManager.IsInitialized) == "function" and gymManager:IsInitialized() then
		return self:RecordResult("GymAutomation", true, "GymAutomationManager is initialized")
	else
		return self:RecordResult("GymAutomation", false, "GymAutomationManager exists but is not initialized")
	end
end

-- Check if ClientRegistry exists and is working
function SystemDiagnostics:CheckClientRegistry()
	log("Checking ClientRegistry...")
	
	-- ClientRegistry should be in ReplicatedStorage
	local clientRegistryLocations = {
		ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ClientRegistry"),
		ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and
			ReplicatedStorage.src.client:FindFirstChild("Core") and ReplicatedStorage.src.client.Core:FindFirstChild("ClientRegistry")
	}
	
	local clientRegistryModule = nil
	for _, location in ipairs(clientRegistryLocations) do
		if location then
			clientRegistryModule = location
			break
		end
	end
	
	if not clientRegistryModule then
		return self:RecordResult("ClientRegistry", false, "ClientRegistry not found in any expected location")
	end
	
	-- Try to require it
	local clientRegistry, errorMessage = safeRequire(clientRegistryModule)
	if not clientRegistry then
		return self:RecordResult("ClientRegistry", false, "Failed to require ClientRegistry: " .. tostring(errorMessage))
	end
	
	-- Check if it has the expected methods
	if type(clientRegistry.Register) ~= "function" or type(clientRegistry.Get) ~= "function" then
		return self:RecordResult("ClientRegistry", false, "ClientRegistry is missing essential methods")
	end
	
	return self:RecordResult("ClientRegistry", true, "ClientRegistry is available and loaded correctly")
end

-- Check if ModuleLoader exists and is working
function SystemDiagnostics:CheckModuleLoader()
	log("Checking ModuleLoader...")
	
	-- ModuleLoader should be in ReplicatedStorage.shared
	local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
	if not sharedFolder then
		return self:RecordResult("ModuleLoader", false, "shared folder not found in ReplicatedStorage")
	end
	
	local moduleLoader = sharedFolder:FindFirstChild("ModuleLoader")
	if not moduleLoader then
		-- Try the src folder structure
		local src = ReplicatedStorage:FindFirstChild("src")
		if src and src:FindFirstChild("shared") then
			moduleLoader = src.shared:FindFirstChild("ModuleLoader")
		end
	end
	
	if not moduleLoader then
		return self:RecordResult("ModuleLoader", false, "ModuleLoader not found in expected locations")
	end
	
	-- Try to require it
	local loader, errorMessage = safeRequire(moduleLoader)
	if not loader then
		return self:RecordResult("ModuleLoader", false, "Failed to require ModuleLoader: " .. tostring(errorMessage))
	end
	
	-- Check if it has the expected methods
	if type(loader.LoadModule) ~= "function" or type(loader.GetModule) ~= "function" then
		return self:RecordResult("ModuleLoader", false, "ModuleLoader is missing essential methods")
	end
	
	return self:RecordResult("ModuleLoader", true, "ModuleLoader is available and loaded correctly")
end

-- Check if UIComponents exists and is working
function SystemDiagnostics:CheckUIComponents()
	log("Checking UIComponents...")
	
	-- UIComponents should be in ReplicatedStorage.shared
	local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
	if not sharedFolder then
		return self:RecordResult("UIComponents", false, "shared folder not found in ReplicatedStorage", "Warning")
	end
	
	local uiComponents = sharedFolder:FindFirstChild("UIComponents")
	if not uiComponents then
		-- Try the src folder structure
		local src = ReplicatedStorage:FindFirstChild("src")
		if src and src:FindFirstChild("shared") then
			uiComponents = src.shared:FindFirstChild("UIComponents")
		end
	end
	
	if not uiComponents then
		return self:RecordResult("UIComponents", false, "UIComponents not found in expected locations", "Warning")
	end
	
	-- Try to require it
	local components, errorMessage = safeRequire(uiComponents)
	if not components then
		return self:RecordResult("UIComponents", false, "Failed to require UIComponents: " .. tostring(errorMessage), "Warning")
	end
	
	-- Check if it has the expected methods
	if type(components.CreateButton) ~= "function" then
		return self:RecordResult("UIComponents", false, "UIComponents is missing essential methods", "Warning")
	end
	
	return self:RecordResult("UIComponents", true, "UIComponents is available and loaded correctly")
end

-- Check if AssetValidator exists and is working
function SystemDiagnostics:CheckAssetValidator()
	log("Checking AssetValidator...")
	
	-- AssetValidator should be in ReplicatedStorage.shared
	local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
	if not sharedFolder then
		return self:RecordResult("AssetValidator", false, "shared folder not found in ReplicatedStorage", "Warning")
	end
	
	local assetValidator = sharedFolder:FindFirstChild("AssetValidator")
	if not assetValidator then
		-- Try the src folder structure
		local src = ReplicatedStorage:FindFirstChild("src")
		if src and src:FindFirstChild("shared") then
			assetValidator = src.shared:FindFirstChild("AssetValidator")
		end
	end
	
	if not assetValidator then
		return self:RecordResult("AssetValidator", false, "AssetValidator not found in expected locations", "Warning")
	end
	
	-- Try to require it
	local validator, errorMessage = safeRequire(assetValidator)
	if not validator then
		return self:RecordResult("AssetValidator", false, "Failed to require AssetValidator: " .. tostring(errorMessage), "Warning")
	end
	
	-- Check if it has the expected methods
	if type(validator.ValidateAsset) ~= "function" then
		return self:RecordResult("AssetValidator", false, "AssetValidator is missing essential methods", "Warning")
	end
	
	return self:RecordResult("AssetValidator", true, "AssetValidator is available and loaded correctly")
end

-- Run a comprehensive system diagnostics check
function SystemDiagnostics:RunDiagnostics()
	log("Running system diagnostics v" .. self._version)
	
	-- Reset stats
	self._results = {}
	self._stats = {
		total = 0,
		passed = 0,
		failed = 0,
		warnings = 0
	}
	
	-- Run the checks
	self:CheckCoreRegistry()
	wait(0.1)
	self:CheckGymAutomation()
	wait(0.1)
	self:CheckClientRegistry()
	wait(0.1)
	self:CheckModuleLoader()
	wait(0.1)
	self:CheckUIComponents()
	wait(0.1)
	self:CheckAssetValidator()
	wait(0.1)
	
	-- Print summary
	self:PrintSummary()
	
	return self._results
end

-- Print a summary of the diagnostic results
function SystemDiagnostics:PrintSummary()
	local passRate = self._stats.total > 0 and (self._stats.passed / self._stats.total * 100) or 0
	
	log("Diagnostics complete. Results:")
	log("Tests Run: " .. self._stats.total)
	log("Tests Passed: " .. self._stats.passed)
	log("Tests Failed: " .. self._stats.failed)
	log("Warnings: " .. self._stats.warnings)
	log("Pass Rate: " .. math.floor(passRate) .. "%")
end

-- Get diagnostic results
function SystemDiagnostics:GetResults()
	return self._results
end

-- Get diagnostic statistics
function SystemDiagnostics:GetStats()
	local passRate = self._stats.total > 0 and (self._stats.passed / self._stats.total * 100) or 0
	
	return {
		total = self._stats.total,
		passed = self._stats.passed,
		failed = self._stats.failed,
		warnings = self._stats.warnings,
		passRate = passRate
	}
end

-- Get the diagnostics version
function SystemDiagnostics:GetVersion()
	return self._version
end

-- Initialize the diagnostics module
log("SystemDiagnostics v" .. VERSION .. " initialized")

-- Make globally accessible for debugging
if _G then
	_G.__SystemDiagnostics = SystemDiagnostics
end

return SystemDiagnostics
