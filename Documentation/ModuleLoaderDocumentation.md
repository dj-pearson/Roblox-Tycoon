--[[
    ModuleLoaderDocumentation.md
    
    # Module Loading System Documentation
    
    ## Overview
    
    The Module Loading System is a core utility that provides a standardized way to load modules across the codebase. 
    It includes error handling, dependency management, and caching to improve performance and reliability.
    
    ## Key Components
    
    1. **ModuleLoader** - The main module that handles loading, caching, and dependency tracking
    2. **ModuleLoaderHelper** - A lightweight utility that provides easy access to ModuleLoader
    
    ## Using the Module Loading System
    
    ### Basic Module Loading
    
    ```lua
    -- Load ModuleLoaderHelper
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ModuleLoaderHelper = require(ReplicatedStorage.shared.ModuleLoaderHelper)
    
    -- Load a module by name
    local MyModule = ModuleLoaderHelper.loadModule("MyModule")
    
    -- Load a module with a fallback value if not found
    local OptionalModule = ModuleLoaderHelper.loadModule("OptionalModule", {})
    ```
    
    ### Advanced Features
    
    #### Dependency Injection
    
    ```lua
    -- Get the full ModuleLoader for advanced features
    local ModuleLoader = ModuleLoaderHelper.getModuleLoader()
    
    -- Register a dependency
    ModuleLoader.registerDependency("ConfigManager", ConfigManager)
    
    -- Inject dependencies into a module
    local EnhancedModule = ModuleLoader.injectDependencies(BaseModule, {
        logger = Logger,
        dataService = DataService
    })
    ```
    
    #### Loading Module Chains
    
    ```lua
    -- Load multiple dependencies at once
    local dependencies = ModuleLoader.loadDependencyChain({
        "UIManager",
        "DataManager",
        "EventManager"
    })
    
    -- Access loaded dependencies
    local UIManager = dependencies.UIManager
    ```
    
    ## Best Practices
    
    1. **Always use the ModuleLoader**: Avoid direct `require()` calls to ensure consistent error handling and caching
    2. **Use dependency injection** for complex systems that require multiple components
    3. **Handle missing modules gracefully** by providing fallback values
    4. **Avoid circular dependencies** which can cause loading errors
    
    ## Implementation Details
    
    ### Module Resolution Process
    
    1. Check module cache first
    2. Look for the module in standard search paths
    3. If found, require the module and cache the result
    4. If not found, return fallback value
    
    ### Circular Dependency Detection
    
    The ModuleLoader tracks module loading attempts to detect circular dependencies.
    When detected, it returns a stub or fallback value to break the cycle.
    
    ### Performance Optimizations
    
    - **Caching**: Loaded modules are cached to improve performance
    - **Smart Path Searching**: Only searches relevant paths based on client/server context
    - **Lazy Loading**: Dependencies are loaded on demand
    
    ## Migrating from Legacy Code
    
    If you have code using custom module loading:
    
    1. Replace custom require functions with ModuleLoaderHelper
    2. Update path strings to standardized module names
    3. Add proper error handling with fallbacks
    
    Example migration:
    
    ```lua
    -- Old code
    local function safeRequire(moduleName)
        -- Custom complex loading logic
    end
    
    local MyModule = safeRequire("MyModule")
    
    -- New code
    local ModuleLoaderHelper = require(ReplicatedStorage.shared.ModuleLoaderHelper)
    local MyModule = ModuleLoaderHelper.loadModule("MyModule")
    ```
    
    ## Troubleshooting
    
    If modules fail to load:
    
    1. Check if the module exists in the expected location
    2. Ensure the module name matches exactly (case-sensitive)
    3. Verify the module doesn't have circular dependencies
    4. Check ModuleLoader debug logs if DEBUG is enabled
]]
