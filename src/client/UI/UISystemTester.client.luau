-- UISystemTester.client.luau
-- Tests the UI system components to ensure they're available and working
-- Created: April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true
local TEST_DELAY = 0.2 -- Seconds between tests

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" and level ~= "Success" then return end
	
	local prefix = "[UISystemTester]"
	if level == "Success" then
		print(prefix .. " ✓ " .. message)
	elseif level == "Error" then
		print(prefix .. " ✗ " .. message)
	else
		print(prefix .. " " .. message)
	end
end

-- UI System Tester object
local UISystemTester = {
	_version = VERSION,
	_testResults = {},
	_testCount = 0,
	_passCount = 0,
	_failCount = 0,
}

-- Function to find a module in multiple locations
local function findModule(moduleName)
	-- Check in ReplicatedStorage.shared
	local shared = ReplicatedStorage:FindFirstChild("shared")
	if shared and shared:FindFirstChild(moduleName) then
		return shared:FindFirstChild(moduleName)
	end
	
	-- Check in ReplicatedStorage.src.shared
	local src = ReplicatedStorage:FindFirstChild("src")
	if src and src:FindFirstChild("shared") and src.shared:FindFirstChild(moduleName) then
		return src.shared:FindFirstChild(moduleName)
	end
	
	-- Check in ReplicatedStorage root
	if ReplicatedStorage:FindFirstChild(moduleName) then
		return ReplicatedStorage:FindFirstChild(moduleName)
	end
	
	-- Check in LocalPlayer.PlayerScripts
	if LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts") and 
	   LocalPlayer.PlayerScripts:FindFirstChild(moduleName) then
		return LocalPlayer.PlayerScripts:FindFirstChild(moduleName)
	end
	
	-- Check in ReplicatedStorage.UIModules
	local uiModules = ReplicatedStorage:FindFirstChild("UIModules")
	if uiModules and uiModules:FindFirstChild(moduleName) then
		return uiModules:FindFirstChild(moduleName)
	end
	
	return nil
end

-- Function to safely require a module
local function safeRequire(module)
	if not module then
		return nil, "Module is nil"
	end
	
	if not module:IsA("ModuleScript") then
		return nil, "Not a ModuleScript"
	end
	
	local success, result = pcall(function()
		return require(module)
	end)
	
	if success then
		return result, nil
	else
		return nil, result
	end
end

-- Function to record test result
function UISystemTester:RecordResult(testName, passed, errorMessage)
	self._testCount = self._testCount + 1
	
	if passed then
		self._passCount = self._passCount + 1
		log(testName .. ": Test passed", "Success")
	else
		self._failCount = self._failCount + 1
		log(testName .. ": " .. (errorMessage or "Test failed"), "Error")
	end
	
	table.insert(self._testResults, {
		testName = testName,
		passed = passed,
		errorMessage = errorMessage,
		timestamp = os.time()
	})
	
	return passed
end

-- Test if a module exists
function UISystemTester:TestModuleExists(moduleName)
	log("Testing if " .. moduleName .. " exists")
	
	-- Look for the module
	local moduleScript = findModule(moduleName)
	if not moduleScript then
		return self:RecordResult(moduleName .. " Exists", false, moduleName .. " not found through any method")
	end
	
	-- Try to require it
	local module, errorMessage = safeRequire(moduleScript)
	if not module then
		return self:RecordResult(moduleName .. " Exists", false, moduleName .. " module not found")
	end
	
	return self:RecordResult(moduleName .. " Exists", true)
end

-- Test if a module function exists
function UISystemTester:TestModuleFunction(moduleName, functionName)
	log("Testing if " .. moduleName .. "." .. functionName .. " exists")
	
	-- Look for the module
	local moduleScript = findModule(moduleName)
	if not moduleScript then
		return self:RecordResult(moduleName .. "." .. functionName, false, moduleName .. " not found")
	end
	
	-- Try to require it
	local module, errorMessage = safeRequire(moduleScript)
	if not module then
		return self:RecordResult(moduleName .. "." .. functionName, false, "Failed to require " .. moduleName .. ": " .. tostring(errorMessage))
	end
	
	-- Check if the function exists
	if type(module[functionName]) ~= "function" then
		return self:RecordResult(moduleName .. "." .. functionName, false, functionName .. " is not a function in " .. moduleName)
	end
	
	return self:RecordResult(moduleName .. "." .. functionName, true)
end

-- Test if a ClientRegistry exists and is properly initialized
function UISystemTester:TestClientRegistry()
	log("Testing ClientRegistry")
	
	-- Look for the ClientRegistry module
	local clientRegistryModule = findModule("ClientRegistry")
	if not clientRegistryModule then
		return self:RecordResult("ClientRegistry Exists", false, "ClientRegistry not found through any method")
	end
	
	-- Try to require it
	local clientRegistry, errorMessage = safeRequire(clientRegistryModule)
	if not clientRegistry then
		return self:RecordResult("ClientRegistry Exists", false, "Failed to require ClientRegistry: " .. tostring(errorMessage))
	end
	
	-- Check if it has the expected methods
	if type(clientRegistry.Register) ~= "function" then
		return self:RecordResult("ClientRegistry Exists", false, "ClientRegistry lacks Register method")
	end
	
	if type(clientRegistry.Get) ~= "function" then
		return self:RecordResult("ClientRegistry Exists", false, "ClientRegistry lacks Get method")
	end
	
	return self:RecordResult("ClientRegistry Exists", true)
end

-- Test if UIComponents exists and is properly initialized
function UISystemTester:TestUIComponents()
	log("Testing UIComponents")
	
	-- Look for the UIComponents module
	local uiComponentsModule = findModule("UIComponents")
	if not uiComponentsModule then
		return self:RecordResult("UIComponents Exists", false, "UIComponents not found through any method")
	end
	
	-- Try to require it
	local uiComponents, errorMessage = safeRequire(uiComponentsModule)
	if not uiComponents then
		return self:RecordResult("UIComponents Exists", false, "Failed to require UIComponents: " .. tostring(errorMessage))
	end
	
	-- Check if it has the expected methods
	if type(uiComponents.CreateButton) ~= "function" then
		return self:RecordResult("UIComponents Exists", false, "UIComponents lacks CreateButton method")
	end
	
	return self:RecordResult("UIComponents Exists", true)
end

-- Test if AssetValidator exists and is properly initialized
function UISystemTester:TestAssetValidator()
	log("Testing AssetValidator")
	
	-- Look for the AssetValidator module
	local assetValidatorModule = findModule("AssetValidator")
	if not assetValidatorModule then
		return self:RecordResult("AssetValidator Exists", false, "AssetValidator not found through any method")
	end
	
	-- Try to require it
	local assetValidator, errorMessage = safeRequire(assetValidatorModule)
	if not assetValidator then
		return self:RecordResult("AssetValidator Exists", false, "Failed to require AssetValidator: " .. tostring(errorMessage))
	end
	
	-- Check if it has the expected methods
	if type(assetValidator.ValidateAsset) ~= "function" then
		return self:RecordResult("AssetValidator Exists", false, "AssetValidator lacks ValidateAsset method")
	end
	
	return self:RecordResult("AssetValidator Exists", true)
end

-- Test if UIRegistry exists and is properly initialized
function UISystemTester:TestUIRegistry()
	log("Testing UIRegistry")
	
	-- Look for the UIRegistry module
	local uiRegistryModule = findModule("UIRegistry")
	if not uiRegistryModule then
		return self:RecordResult("UIRegistry Exists", false, "UIRegistry not found")
	end
	
	-- Try to require it
	local uiRegistry, errorMessage = safeRequire(uiRegistryModule)
	if not uiRegistry then
		return self:RecordResult("UIRegistry Exists", false, "Failed to require UIRegistry: " .. tostring(errorMessage))
	end
	
	-- Check if it has the expected methods
	if type(uiRegistry.RegisterComponent) ~= "function" then
		return self:RecordResult("UIRegistry Exists", false, "UIRegistry lacks RegisterComponent method")
	end
	
	return self:RecordResult("UIRegistry Exists", true)
end

-- Test if ModuleLoader exists and is properly initialized
function UISystemTester:TestModuleLoader()
	log("Testing ModuleLoader")
	
	-- Look for the ModuleLoader module
	local moduleLoaderModule = findModule("ModuleLoader")
	if not moduleLoaderModule then
		return self:RecordResult("ModuleLoader Exists", false, "ModuleLoader module not found")
	end
	
	-- Try to require it
	local moduleLoader, errorMessage = safeRequire(moduleLoaderModule)
	if not moduleLoader then
		return self:RecordResult("ModuleLoader Exists", false, "Failed to require ModuleLoader: " .. tostring(errorMessage))
	end
	
	-- Check if it has the expected methods
	if type(moduleLoader.LoadModule) ~= "function" then
		return self:RecordResult("ModuleLoader Exists", false, "ModuleLoader lacks LoadModule method")
	end
	
	return self:RecordResult("ModuleLoader Exists", true)
end

-- Test if ClientBootstrap exists and is properly initialized
function UISystemTester:TestClientBootstrap()
	log("Testing ClientBootstrap")
	
	local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	if not playerScripts then
		return self:RecordResult("ClientBootstrap Exists", false, "PlayerScripts not found")
	end
	
	-- Look for the ClientBootstrap module
	local clientBootstrapModule = playerScripts:FindFirstChild("ClientBootstrap")
	if not clientBootstrapModule then
		return self:RecordResult("ClientBootstrap Exists", false, "ClientBootstrap not found in PlayerScripts")
	end
	
	-- Check if it's been initialized
	if _G.__ClientBootstrap then
		return self:RecordResult("ClientBootstrap Exists", true)
	else
		return self:RecordResult("ClientBootstrap Exists", false, "ClientBootstrap exists but is not initialized")
	end
end

-- Run a basic UI rendering test
function UISystemTester:TestUIRendering()
	log("Testing UI rendering capability")
	
	local success = pcall(function()
		-- Create a temporary ScreenGui
		local gui = Instance.new("ScreenGui")
		gui.Name = "UITestGui"
		gui.ResetOnSpawn = false
		
		-- Add a basic UI element
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, 100, 0, 100)
		frame.Position = UDim2.new(0.5, -50, 0.5, -50)
		frame.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
		frame.Parent = gui
		
		-- Add a label
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 30)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.Gotham
		label.TextSize = 14
		label.Text = "UI Test"
		label.Parent = frame
		
		-- Parent to PlayerGui
		gui.Parent = LocalPlayer:FindFirstChild("PlayerGui")
		
		-- Destroy after a brief moment
		spawn(function()
			wait(1)
			gui:Destroy()
		end)
	end)
	
	return self:RecordResult("UI Rendering", success, success and nil or "Failed to create test UI")
end

-- Test a basic UIComponents function if available
function UISystemTester:TestUIComponentsFunction()
	log("Testing UIComponents functionality")
	
	-- Look for the UIComponents module
	local uiComponentsModule = findModule("UIComponents")
	if not uiComponentsModule then
		return self:RecordResult("UIComponents Function", false, "UIComponents not found")
	end
	
	-- Try to require it
	local uiComponents, errorMessage = safeRequire(uiComponentsModule)
	if not uiComponents then
		return self:RecordResult("UIComponents Function", false, "Failed to require UIComponents")
	end
	
	-- Try to create a button
	local success = pcall(function()
		local button = uiComponents:CreateButton("Test Button")
		if button then
			-- Success!
			spawn(function()
				wait(1)
				button:Destroy()
			end)
		else
			error("Button creation returned nil")
		end
	end)
	
	return self:RecordResult("UIComponents Function", success, success and nil or "Failed to create button with UIComponents")
end

-- Run a comprehensive UI system test
function UISystemTester:TestUISystem()
	self._testResults = {}
	self._testCount = 0
	self._passCount = 0
	self._failCount = 0
	
	log("Starting UI system tests")
	
	-- Schedule the tests to run in sequence
	spawn(function()
		-- Core modules
		self:TestModuleLoader()
		wait(TEST_DELAY)
		self:TestClientRegistry()
		wait(TEST_DELAY)
		self:TestClientBootstrap()
		wait(TEST_DELAY)
		
		-- UI modules
		self:TestUIComponents()
		wait(TEST_DELAY)
		self:TestAssetValidator()
		wait(TEST_DELAY)
		self:TestUIRegistry()
		wait(TEST_DELAY)
		
		-- Module functions
		self:TestModuleFunction("UIComponents", "CreateButton")
		wait(TEST_DELAY)
		self:TestModuleFunction("AssetValidator", "ValidateAsset")
		wait(TEST_DELAY)
		self:TestModuleFunction("UIRegistry", "RegisterComponent")
		wait(TEST_DELAY)
		
		-- Functional tests
		self:TestUIRendering()
		wait(TEST_DELAY)
		self:TestUIComponentsFunction()
		wait(TEST_DELAY)
		
		-- Output a summary
		self:PrintSummary()
	end)
end

-- Get test results
function UISystemTester:GetResults()
	return self._testResults
end

-- Get test statistics
function UISystemTester:GetStats()
	return {
		total = self._testCount,
		passed = self._passCount,
		failed = self._failCount,
		passRate = self._testCount > 0 and (self._passCount / self._testCount * 100) or 0
	}
end

-- Print a summary of the test results
function UISystemTester:PrintSummary()
	local stats = self:GetStats()
	log("Tests Run: " .. stats.total .. ", Tests Passed: " .. stats.passed .. ", Tests Failed: " .. stats.failed)
	log("Pass Rate: " .. math.floor(stats.passRate) .. "%")
end

-- Update ClientRegistry with test results if available
function UISystemTester:UpdateClientRegistry()
	-- Look for the ClientRegistry module
	local clientRegistryModule = findModule("ClientRegistry")
	if not clientRegistryModule then
		return false
	end
	
	-- Try to require it
	local clientRegistry, errorMessage = safeRequire(clientRegistryModule)
	if not clientRegistry then
		return false
	end
	
	-- Register the test results
	if type(clientRegistry.Register) == "function" then
		clientRegistry:Register("UISystemTester", self)
		clientRegistry:Register("UITestResults", self:GetResults())
		clientRegistry:Register("UITestStats", self:GetStats())
		return true
	end
	
	return false
end

-- Run the tests automatically when the module is first required
do
	log("UISystemTester v" .. VERSION .. " initialized")
	
	-- Make the tester accessible globally for debugging
	if _G then
		_G.__UISystemTester = UISystemTester
	end
	
	-- Run the tests after a short delay to ensure everything else has loaded
	spawn(function()
		wait(3) -- Wait a few seconds for other systems to initialize
		UISystemTester:TestUISystem()
		UISystemTester:UpdateClientRegistry()
	end)
end

return UISystemTester
