--[[
    ModuleLoaderConfigExample.luau
    
    This is an example of how to configure and use the ModuleLoader system in your scripts.
    Use this as a reference when implementing module loading in new scripts.
    
    Created: May 3, 2025
]]

-- First, import the necessary services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- STEP 1: Load the ModuleLoaderHelper
-- The helper automatically handles finding and using the ModuleLoader
local ModuleLoaderHelper = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoaderHelper"))

-- STEP 2: Load your required modules using ModuleLoaderHelper
-- Basic module loading
local UIManager = ModuleLoaderHelper.loadModule("UIManager", {}) -- Second parameter is a fallback if not found
local DataManager = ModuleLoaderHelper.loadModule("DataManager")
local EventManager = ModuleLoaderHelper.loadModule("EventManager")

-- Loading modules with path strings
local Button = ModuleLoaderHelper.loadModule("UI/Components/Button")
local Panel = ModuleLoaderHelper.loadModule("UI/Components/Panel")

-- STEP 3 (Optional): Access the full ModuleLoader for advanced features
local ModuleLoader = ModuleLoaderHelper.getModuleLoader()

if ModuleLoader then
    -- Register your own modules as dependencies for others to use
    ModuleLoader.registerDependency("MyCustomService", script)
    
    -- Load all modules in a folder
    local uiComponents = ModuleLoader.loadModulesInFolder(ReplicatedStorage.UI.Components)
    
    -- Check if there are circular dependencies
    local dependencies = ModuleLoader.getDependencies("MyModule")
    
    -- Get loading statistics (for performance analysis)
    local stats = ModuleLoader.getStats()
    print("Total modules loaded:", stats.totalLoaded)
    print("Cache hits:", stats.cacheHits)
    print("Loading errors:", stats.loadErrors)
    print("Average load time:", stats.loadTime / (stats.totalLoaded + stats.cacheHits))
    
    -- Clear the module cache (useful during development)
    ModuleLoader.clearCache("MyModule") -- Clear specific module
    -- ModuleLoader.clearAllCache() -- Clear all cached modules
    
    -- Using dependency injection
    local myService = {
        name = "MyService",
        start = function(self)
            print("Starting", self.name)
            if self.logger then
                self.logger:Log("Service started")
            end
        end
    }
    
    -- Inject the dependencies
    myService = ModuleLoader.injectDependencies(myService, {
        logger = ModuleLoader.loadModule("Logger"),
        config = ModuleLoader.loadModule("Config")
    })
    
    -- Now myService has the injected dependencies available
    myService:start() -- Will use the logger if it was loaded successfully
end

-- STEP 4: Create a module that works with ModuleLoader
local MyModule = {}

-- Export your initialization function that accepts dependencies
function MyModule.init(dependencies)
    MyModule.dataManager = dependencies.dataManager or ModuleLoaderHelper.loadModule("DataManager")
    MyModule.logger = dependencies.logger or ModuleLoaderHelper.loadModule("Logger", { log = function() end })
    
    MyModule.logger:log("MyModule initialized")
    return MyModule
end

-- Standard module functions
function MyModule.doSomething()
    if MyModule.dataManager then
        return MyModule.dataManager:getData()
    end
    return nil
end

-- Initialize with default dependencies if not explicitly initialized
if not MyModule.initialized then
    MyModule.init({})
    MyModule.initialized = true
end

return MyModule
