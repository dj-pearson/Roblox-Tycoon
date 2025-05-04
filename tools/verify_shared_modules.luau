--[[
    verify_shared_modules.luau
    
    This script verifies that all modules from ReplicatedStorage\shared have corresponding
    counterparts in src\shared, and they provide the same functionality.
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- List of modules in ReplicatedStorage\shared to check
local modulesToVerify = {
    "AssetValidator",
    "ModuleLoader",
    "SafeRequire",
    "SafeWaitForChild",
    "UIComponents",
    "UIRegistry"
}

-- Initialize results table
local results = {
    missing = {},
    incompatible = {}
}

-- Helper function to print colored text
local function printColored(text, color)
    local colors = {
        red = "\27[31m",
        green = "\27[32m",
        yellow = "\27[33m",
        blue = "\27[34m",
        reset = "\27[0m"
    }
    
    print(colors[color] .. text .. colors.reset)
end

-- Verify each module
printColored("Checking modules in ReplicatedStorage\\shared vs src\\shared:", "blue")
print("=====================================================")

for _, moduleName in ipairs(modulesToVerify) do
    printColored("Checking " .. moduleName .. "...", "yellow")
      -- Attempt to require from src\shared (via Shared with capital S)
    local srcModuleSuccess, srcModule = pcall(function()
        local moduleScript = ReplicatedStorage.Shared:FindFirstChild(moduleName)
        if not moduleScript then
            error("Module not found: " .. moduleName)
        end
        return require(moduleScript)
    end)
    
    -- Attempt to require from ReplicatedStorage\shared
    local replModuleSuccess, replModule = pcall(function()
        -- Modules in ReplicatedStorage\shared have .luau extension in their names
        local module = ReplicatedStorage:FindFirstChild("shared"):FindFirstChild(moduleName .. ".luau")
        if not module then
            error("Module not found: " .. moduleName .. ".luau")
        end
        return require(module)
    end)
    
    if not srcModuleSuccess then
        table.insert(results.missing, moduleName)
        printColored("  ERROR: Module not found in src\\shared", "red")
    elseif not replModuleSuccess then
        printColored("  WARNING: Module not found in ReplicatedStorage\\shared", "yellow")
    else
        -- Compare basic functionality: check if they're both tables and have the same functions
        local isCompatible = true
        local missingFunctions = {}
        
        if type(srcModule) == "table" and type(replModule) == "table" then
            for key, _ in pairs(replModule) do
                if srcModule[key] == nil then
                    table.insert(missingFunctions, key)
                    isCompatible = false
                end
            end
            
            if not isCompatible then
                table.insert(results.incompatible, {
                    name = moduleName,
                    missingFunctions = missingFunctions
                })
                printColored("  WARNING: Not fully compatible. Missing functions in src\\shared: " .. table.concat(missingFunctions, ", "), "yellow")
            else
                printColored("  OK: Module appears compatible", "green")
            end
        else
            table.insert(results.incompatible, {
                name = moduleName,
                reason = "Different types"
            })
            printColored("  WARNING: Different return types", "yellow")
        end
    end
end

-- Print summary
print("\nSummary of Results:")
print("=====================================================")

if #results.missing > 0 then
    printColored("Missing modules in src\\shared:", "red")
    for _, moduleName in ipairs(results.missing) do
        print("  - " .. moduleName)
    end
else
    printColored("All modules exist in src\\shared", "green")
end

if #results.incompatible > 0 then
    printColored("\nPotentially incompatible modules:", "yellow")
    for _, moduleInfo in ipairs(results.incompatible) do
        print("  - " .. moduleInfo.name)
        if moduleInfo.missingFunctions then
            print("    Missing functions: " .. table.concat(moduleInfo.missingFunctions, ", "))
        elseif moduleInfo.reason then
            print("    Reason: " .. moduleInfo.reason)
        end
    end
else
    printColored("\nAll modules appear compatible", "green")
end

print("\nRecommendation:")
if #results.missing > 0 or #results.incompatible > 0 then
    printColored("Address the issues above before removing ReplicatedStorage\\shared", "yellow")
else
    printColored("Safe to remove ReplicatedStorage\\shared folder, as all modules are properly represented in src\\shared", "green")
end
