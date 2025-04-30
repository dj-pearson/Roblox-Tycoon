--!strict
--[[
    April29FixesTester.server.luau
    Tests the fixes implemented for April 29 issues
    
    Created: April 29, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Utility functions
local function log(message, isError)
    if isError then
        warn("[April29FixesTester] " .. message)
    else
        print("[April29FixesTester] " .. message)
    end
end

local function checkmark(condition)
    return condition and "✅" or "❌"
end

-- Find script in various paths
local function findScript(scriptName)
    local paths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("server"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("client"),
        script.Parent
    }
    
    for _, path in ipairs(paths) do
        if path then
            local script = path:FindFirstChild(scriptName)
            if script then
                return script
            end
        end
    end
    
    return nil
end

-- Find CoreRegistry
local function findCoreRegistry()
    local paths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Core"),
        ReplicatedStorage:FindFirstChild("src"):FindFirstChild("shared")
    }
    
    for _, path in ipairs(paths) do
        if path and path:FindFirstChild("CoreRegistry") then
            local success, module = pcall(function()
                return require(path.CoreRegistry)
            end)
            
            if success and typeof(module) == "table" and typeof(module.GetSystem) == "function" then
                return module
            end
        end
    end
    
    return nil
end

-- Test CoreRegistry fixes
local function testCoreRegistryFixes()
    log("Testing CoreRegistry fixes...")
    
    local CoreRegistry = findCoreRegistry()
    if not CoreRegistry then
        log("Could not find CoreRegistry module", true)
        return false
    end
    
    local criticalSystems = {
        "ModuleLoader",
        "DataManager",
        "UIComponents",
        "AssetValidator",
        "BuyTileSystem"
    }
    
    local results = {}
    local allPassed = true
    
    for _, systemName in ipairs(criticalSystems) do
        local system = CoreRegistry:GetSystem(systemName)
        local exists = system ~= nil
        
        results[systemName] = exists
        if not exists then
            allPassed = false
        end
        
        log(checkmark(exists) .. " " .. systemName .. " system present in CoreRegistry")
    end
    
    log(checkmark(allPassed) .. " CoreRegistry critical systems test: " .. 
        (allPassed and "PASSED" or "FAILED"))
    
    return allPassed
end

-- Test BuyTilePositionFixer
local function testBuyTilePositionFixer()
    log("Testing BuyTilePositionFixer...")
    
    local fixerScript = findScript("BuyTilePositionFixer")
    if not fixerScript then
        log("BuyTilePositionFixer script not found", true)
        return false
    end
    
    -- Check if script is in ServerScriptService
    local isInProperLocation = fixerScript:IsDescendantOf(ServerScriptService)
    log(checkmark(isInProperLocation) .. " BuyTilePositionFixer in proper location")
    
    -- Check if script has run (global flag)
    local hasRun = _G.BuyTilePositionFixerInitialized == true
    log(checkmark(hasRun) .. " BuyTilePositionFixer has run")
    
    -- Check if BuyTileSystem has been patched
    local buyTileSystemPatched = false
    local CoreRegistry = findCoreRegistry()
    if CoreRegistry then
        local BuyTileSystem = CoreRegistry:GetSystem("BuyTileSystem")
        if BuyTileSystem and BuyTileSystem._positionFixApplied then
            buyTileSystemPatched = true
        end
    end
    log(checkmark(buyTileSystemPatched) .. " BuyTileSystem has been patched")
    
    local allPassed = isInProperLocation and (hasRun or buyTileSystemPatched)
    log(checkmark(allPassed) .. " BuyTilePositionFixer test: " .. 
        (allPassed and "PASSED" or "FAILED"))
    
    return allPassed
end

-- Test UIAccessRestrictor
local function testUIAccessRestrictor()
    log("Testing UIAccessRestrictor distribution...")
    
    -- Check if source script exists
    local sourceScript = findScript("UIAccessRestrictor")
    local sourceExists = sourceScript ~= nil
    log(checkmark(sourceExists) .. " UIAccessRestrictor source script exists")
    
    -- Check if distributor script exists
    local distributorScript = findScript("ClientFixDistributor")
    local distributorExists = distributorScript ~= nil
    log(checkmark(distributorExists) .. " ClientFixDistributor script exists")
    
    -- Check for client startup script
    local clientStartupScript = findScript("AprilFixesClientStartup")
    local clientStartupExists = clientStartupScript ~= nil
    log(checkmark(clientStartupExists) .. " AprilFixesClientStartup script exists")
    
    -- Check if client config flag is set
    local clientConfig = ReplicatedStorage:FindFirstChild("ClientConfig")
    local flagValue = clientConfig and clientConfig:FindFirstChild("EnableUIAccessRestrictor") and 
                      clientConfig:FindFirstChild("EnableUIAccessRestrictor").Value
    log(checkmark(flagValue) .. " UIAccessRestrictor enabled in client config")
    
    local allPassed = sourceExists and distributorExists and clientStartupExists and flagValue
    log(checkmark(allPassed) .. " UIAccessRestrictor distribution test: " .. 
        (allPassed and "PASSED" or "FAILED"))
    
    return allPassed
}

-- Run all tests
local function runAllTests()
    log("Starting tests for April 29 fixes...")
    
    local results = {
        CoreRegistry = testCoreRegistryFixes(),
        BuyTilePosition = testBuyTilePositionFixer(),
        UIAccessRestrictor = testUIAccessRestrictor()
    }
    
    log("=== TEST SUMMARY ===")
    local totalPassed = 0
    local totalTests = 0
    
    for testName, passed in pairs(results) do
        totalTests = totalTests + 1
        if passed then
            totalPassed = totalPassed + 1
        end
        
        log(checkmark(passed) .. " " .. testName .. ": " .. (passed and "PASSED" or "FAILED"))
    end
    
    local passRate = math.floor((totalPassed / totalTests) * 100)
    log("=== " .. totalPassed .. " of " .. totalTests .. " tests passed (" .. passRate .. "%) ===")
    
    return results
end

-- Wait a bit for everything to initialize
task.delay(5, function()
    runAllTests()
end)

-- Return true to indicate script loaded
return true
