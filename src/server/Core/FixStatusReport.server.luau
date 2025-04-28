--[[
    FixStatusReport.server.luau
    
    This script runs diagnostics on all critical systems to verify that
    fixes have been applied and are working correctly.
    
    It checks for the proper initialization of CoreRegistry, ModuleLoader,
    DataManager, and other critical systems.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Configuration
local WAIT_TIME = 5 -- Wait this many seconds before running diagnostics

-- Find a module safely
local function findModule(moduleName)
    local searchPaths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Server"),
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

-- Safe require function
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
        warn("FixStatusReport: Failed to require " .. moduleInstance:GetFullName() .. " - " .. tostring(result))
        return nil
    end
end

-- Check folder existence
local function checkFolder(parent, folderName, expected)
    local folder = parent:FindFirstChild(folderName)
    local exists = folder ~= nil
    
    if exists == expected then
        print("✅ " .. parent.Name .. "." .. folderName .. " folder " .. (expected and "exists" or "does not exist") .. " as expected")
        return true
    else
        warn("❌ " .. parent.Name .. "." .. folderName .. " folder " .. (exists and "exists" or "does not exist") .. " (expected: " .. tostring(expected) .. ")")
        return false
    end
end

-- Check module existence and loading
local function checkModule(moduleName, expectedToExist)
    local moduleInstance = findModule(moduleName)
    local exists = moduleInstance ~= nil
    
    if exists ~= expectedToExist then
        warn("❌ " .. moduleName .. " module " .. (exists and "exists" or "does not exist") .. " (expected: " .. tostring(expectedToExist) .. ")")
        return false
    end
    
    if not expectedToExist then
        print("✅ " .. moduleName .. " module does not exist as expected")
        return true
    end
    
    local module = safeRequire(moduleInstance)
    if not module then
        warn("❌ " .. moduleName .. " module exists but failed to load")
        return false
    end
    
    print("✅ " .. moduleName .. " module exists and loaded successfully")
    return true, module
end

print("FixStatusReport: Waiting " .. WAIT_TIME .. " seconds for systems to initialize...")
task.wait(WAIT_TIME)

print("\n=== Critical Systems Status Report ===\n")

-- Check critical folders
print("\n--- Folder Structure Checks ---")
local folderChecks = {
    {ServerScriptService, "Core", true},
    {ReplicatedStorage, "shared", true},
    {ReplicatedStorage, "RemoteEvents", true},
    {ReplicatedStorage, "RemoteFunctions", true},
    {ServerStorage, "GymParts", true}
}

local folderResults = {}
for _, check in ipairs(folderChecks) do
    folderResults[check[1].Name .. "." .. check[2]] = checkFolder(check[1], check[2], check[3])
end

-- Check critical modules
print("\n--- Core Module Checks ---")
local moduleChecks = {
    {"CoreRegistry", true},
    {"ModuleLoader", true},
    {"SafeWaitForChild", true},
    {"DataManager", true},
    {"DataAccessLayer", true},
    {"EventCreator", true},
    {"BuyTileSystem", true},
    {"ClientRegistry", true},
    {"UIComponents", true},
    {"SystemBootstrap", true}
}

local moduleResults = {}
local moduleInstances = {}

for _, check in ipairs(moduleChecks) do
    local success, module = checkModule(check[1], check[2])
    moduleResults[check[1]] = success
    if success then
        moduleInstances[check[1]] = module
    end
end

-- Check CoreRegistry status if available
print("\n--- CoreRegistry Status ---")
if moduleInstances["CoreRegistry"] then
    local CoreRegistry = moduleInstances["CoreRegistry"]
    
    if typeof(CoreRegistry.getStatus) == "function" then
        local status = CoreRegistry.getStatus()
        print("CoreRegistry Status: " .. status)
        if status == "AVAILABLE" or status == CoreRegistry.STATUS.AVAILABLE then
            print("✅ CoreRegistry is AVAILABLE")
        else
            warn("❌ CoreRegistry status is " .. status .. " (expected: AVAILABLE)")
        end
    end
    
    if typeof(CoreRegistry.getAllSystems) == "function" then
        local systems = CoreRegistry.getAllSystems()
        local systemCount = 0
        
        for name, _ in pairs(systems) do
            systemCount = systemCount + 1
        end
        
        print("CoreRegistry has " .. systemCount .. " registered systems")
    end
else
    warn("❌ Cannot check CoreRegistry status as it failed to load")
end

-- Check Player Tycoon folders
print("\n--- Player Tycoon Folders ---")
local anyPlayer = Players:GetPlayers()[1]
if anyPlayer then
    local tycoonFolder = anyPlayer:FindFirstChild("Tycoon")
    if tycoonFolder then
        print("✅ Tycoon folder exists for player " .. anyPlayer.Name)
        
        -- Check essential subfolders
        local subfolders = {"Data", "Equipment", "Staff", "Customers", "Stats"}
        for _, subfolder in ipairs(subfolders) do
            if tycoonFolder:FindFirstChild(subfolder) then
                print("✅ " .. subfolder .. " subfolder exists")
            else
                warn("❌ " .. subfolder .. " subfolder missing")
            end
        end
    else
        warn("❌ Tycoon folder missing for player " .. anyPlayer.Name)
    end
else
    print("⚠️ No players connected to check Tycoon folders")
end

-- Check RemoteEvents
print("\n--- Remote Events ---")
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEvents then
    local eventCount = #remoteEvents:GetChildren()
    print("RemoteEvents folder contains " .. eventCount .. " events")
    
    if eventCount > 0 then
        print("✅ RemoteEvents were created successfully")
    else
        warn("❌ RemoteEvents folder exists but contains no events")
    end
else
    warn("❌ RemoteEvents folder does not exist")
end

-- Check if DataAccessLayer is registered
print("\n--- Data System Status ---")
if moduleInstances["DataAccessLayer"] and moduleInstances["CoreRegistry"] then
    local CoreRegistry = moduleInstances["CoreRegistry"]
    
    if typeof(CoreRegistry.hasSystem) == "function" and CoreRegistry.hasSystem("DataAccessLayer") then
        print("✅ DataAccessLayer is registered with CoreRegistry")
    else
        warn("❌ DataAccessLayer is NOT registered with CoreRegistry")
    end
end

-- Check if BuyTileSystem is working
print("\n--- BuyTile System Status ---")
if moduleInstances["BuyTileSystem"] then
    local BuyTileSystem = moduleInstances["BuyTileSystem"]
    
    if typeof(BuyTileSystem.getAllTileData) == "function" then
        local tileData = BuyTileSystem.getAllTileData()
        local tileCount = 0
        
        for _ in pairs(tileData) do
            tileCount = tileCount + 1
        end
        
        print("BuyTileSystem has " .. tileCount .. " configured tiles")
        
        if tileCount > 0 then
            print("✅ BuyTileSystem has tile configuration")
        else
            warn("⚠️ BuyTileSystem has no tiles configured")
        end
    end
else
    warn("❌ Cannot check BuyTileSystem status as it failed to load")
end

-- Summary
print("\n=== Fix Implementation Status Summary ===")

-- Count passes and fails
local passCount = {
    folders = 0,
    modules = 0
}

local totalCount = {
    folders = 0,
    modules = 0
}

for _ in pairs(folderResults) do
    totalCount.folders = totalCount.folders + 1
end

for name, result in pairs(folderResults) do
    if result then
        passCount.folders = passCount.folders + 1
    else
        print("❌ Failed Folder Check: " .. name)
    end
end

for _ in pairs(moduleResults) do
    totalCount.modules = totalCount.modules + 1
end

for name, result in pairs(moduleResults) do
    if result then
        passCount.modules = passCount.modules + 1
    else
        print("❌ Failed Module Check: " .. name)
    end
end

-- Calculate percentages
local folderPassPercent = math.floor((passCount.folders / totalCount.folders) * 100)
local modulePassPercent = math.floor((passCount.modules / totalCount.modules) * 100)
local overallPassPercent = math.floor(((passCount.folders + passCount.modules) / (totalCount.folders + totalCount.modules)) * 100)

print("\nFolder Structure: " .. passCount.folders .. "/" .. totalCount.folders .. " (" .. folderPassPercent .. "%)")
print("Core Modules: " .. passCount.modules .. "/" .. totalCount.modules .. " (" .. modulePassPercent .. "%)")
print("Overall Fix Implementation: " .. (passCount.folders + passCount.modules) .. "/" .. (totalCount.folders + totalCount.modules) .. " (" .. overallPassPercent .. "%)")

if overallPassPercent >= 90 then
    print("\n✅ EXCELLENT: Most critical fixes have been successfully implemented!")
elseif overallPassPercent >= 70 then
    print("\n✅ GOOD: Critical fixes have been implemented, but some issues remain.")
elseif overallPassPercent >= 50 then
    print("\n⚠️ FAIR: Some critical fixes have been implemented, but significant issues remain.")
else
    print("\n❌ POOR: Most critical fixes have not been implemented or are not working correctly.")
end

print("\n=== End of Fix Status Report ===\n")
