-- filepath: c:\Users\dpearson\OneDrive\Documents\RobloxProject\test_module_fixed.lua
local function createModuleLocatorService()
    local sharedFolder = {}  -- Mock for testing
    local function log(...) 
        print("[TEST]", ...)
    end
    
    local moduleLocatorService = Instance.new("ModuleScript")
    moduleLocatorService.Name = "ModuleLocatorService"
    
    -- Simple string without complex syntax
    moduleLocatorService.Source = "return { name = 'ModuleLocatorService', initialized = true }"

    moduleLocatorService.Parent = sharedFolder
    
    log("ModuleLocatorService created")
    
    return moduleLocatorService
end

-- Create the module
local module = createModuleLocatorService()

-- For testing purposes
print("Module created:", module.Name)
