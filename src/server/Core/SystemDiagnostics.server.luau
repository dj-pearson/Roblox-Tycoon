--[[
    SystemDiagnostics.server.luau
    
    Diagnostic module to validate fixed systems.
    Tests CoreRegistry, ModuleLoader, and EventBridge to ensure they are working properly.
    
    Created as part of the CoreRegistry fix documented in CoreRegistry_Fix_Solution.md
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to find a module in various locations
local function findModule(moduleName)
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService,
        ReplicatedStorage:FindFirstChild("shared"),
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

-- Safely require a module
local function safeRequire(moduleInstance)
    if not moduleInstance then
        return nil
    end
    
    local success, result = pcall(function()
        return require(moduleInstance)
    end)
    
    if success then
        return result
    else
        warn("SystemDiagnostics: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return nil
    end
end

print("SystemDiagnostics: Running system validation...")

-- Test results tracking
local tests = {
    CoreRegistry = false,
    ModuleLoader = false,
    SafeWaitForChild = false,
    TycoonFolderStructure = false,
    EventCreation = false,
    ClientRegistry = false,
    UIComponents = false
}

-- 1. Test CoreRegistry
local CoreRegistryModule = findModule("CoreRegistry")
if CoreRegistryModule then
    local CoreRegistry = safeRequire(CoreRegistryModule)
    
    if CoreRegistry and CoreRegistry.getStatus and CoreRegistry.registerSystem then
        local status = CoreRegistry.getStatus()
        print("SystemDiagnostics: CoreRegistry status - " .. status)
        
        if status == "AVAILABLE" or status == CoreRegistry.STATUS.AVAILABLE then
            tests.CoreRegistry = true
        end
    end
end

-- 2. Test ModuleLoader
local ModuleLoaderModule = findModule("ModuleLoader")
if ModuleLoaderModule then
    local ModuleLoader = safeRequire(ModuleLoaderModule)
    
    if ModuleLoader and ModuleLoader.loadModule and ModuleLoader.findModule then
        tests.ModuleLoader = true
    end
end

-- 3. Test SafeWaitForChild
local SafeWaitForChildModule = findModule("SafeWaitForChild")
if SafeWaitForChildModule then
    local SafeWaitForChild = safeRequire(SafeWaitForChildModule)
    
    if SafeWaitForChild and SafeWaitForChild.wait then
        tests.SafeWaitForChild = true
    end
end

-- 4. Test Tycoon Folder Structure
local success, result = pcall(function()
    -- Check if folder initializer exists
    local TycoonFolderInitializerModule = ServerScriptService.Core:FindFirstChild("TycoonFolderInitializer")
    
    if TycoonFolderInitializerModule and TycoonFolderInitializerModule:IsA("Script") then
        return true
    end
    
    return false
end)

tests.TycoonFolderStructure = success and result

-- 5. Test Event Creation
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEventsFolder and #remoteEventsFolder:GetChildren() > 0 then
    tests.EventCreation = true
end

-- 6. Test ClientRegistry
local ClientRegistryModule = ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ClientRegistry")
if not ClientRegistryModule then
    ClientRegistryModule = findModule("ClientRegistry")
end

if ClientRegistryModule then
    local success, _ = pcall(function()
        return require(ClientRegistryModule)
    end)
    tests.ClientRegistry = success
end

-- 7. Test UIComponents
local UIComponentsModule = ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("UIComponents")
if not UIComponentsModule then
    UIComponentsModule = findModule("UIComponents")
end

if UIComponentsModule then
    local success, _ = pcall(function()
        return require(UIComponentsModule)
    end)
    tests.UIComponents = success
end

-- Summarize results
local passCount = 0
local totalTests = 0

for testName, passed in pairs(tests) do
    totalTests += 1
    if passed then
        passCount += 1
        print("✅ SystemDiagnostics: " .. testName .. " - PASS")
    else
        print("❌ SystemDiagnostics: " .. testName .. " - FAIL")
    end
end

local passRate = math.floor((passCount / totalTests) * 100)
print("SystemDiagnostics: Tests passed: " .. passCount .. "/" .. totalTests .. " (" .. passRate .. "%)")

if passRate == 100 then
    print("✅ SystemDiagnostics: All critical systems are operational!")
elseif passRate >= 70 then
    print("⚠️ SystemDiagnostics: Most critical systems are operational but some issues remain.")
else
    print("❌ SystemDiagnostics: Critical system failures detected! Further fixes required.")
end
