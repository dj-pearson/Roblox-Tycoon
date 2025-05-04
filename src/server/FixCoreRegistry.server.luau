--[[
    FixCoreRegistry.server.luau
    
    This script provides an easy way to manually trigger the CoreRegistry fix process.
    Place it in ServerScriptService for easy access.
    
    Created: May 4, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Find CoreRegistryFix script
local function findFixScript()
    local paths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService
    }
    
    for _, path in ipairs(paths) do
        if path then
            if path:FindFirstChild("CoreRegistryFix.server") then
                return path["CoreRegistryFix.server"]
            elseif path:FindFirstChild("CoreRegistryFix") then
                return path.CoreRegistryFix
            end
        end
    end
    
    return nil
end

-- Main execution
print("[FixCoreRegistry] Running CoreRegistry fix...")

local fixScript = findFixScript()
if not fixScript then
    warn("[FixCoreRegistry] ERROR: Could not find CoreRegistryFix script")
    return
end

print("[FixCoreRegistry] Found fix script at:", fixScript:GetFullName())

local success, result = pcall(function()
    return require(fixScript)
end)

if success then
    print("[FixCoreRegistry] Successfully executed CoreRegistry fix")
    
    -- Display status summary
    if result and result.finalStatus then
        print("=== CoreRegistry Status Summary ===")
        print("Registry Status:", result.finalStatus.registryStatus)
        
        if #result.finalStatus.missingSystems == 0 then
            print("✅ All critical systems present")
        else
            print("⚠️ Missing systems:", table.concat(result.finalStatus.missingSystems, ", "))
        end
        
        if #result.finalStatus.placeholderSystems > 0 then
            print("ℹ️ Using placeholder implementations for:", table.concat(result.finalStatus.placeholderSystems, ", "))
        end
    end
else
    warn("[FixCoreRegistry] ERROR: Failed to execute CoreRegistryFix:", result)
end
