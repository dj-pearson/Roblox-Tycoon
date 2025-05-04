--[[
    CoreRegistryFix.server.luau
    
    This script orchestrates the CoreRegistry fix process by:
    1. Running the diagnostic to check current status
    2. Running the restorer to fix any issues
    3. Running the diagnostic again to verify fixes
    
    Created: May 4, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local CONFIG = {
    debug = true
}

-- Debug logging
local function log(...)
    if CONFIG.debug then
        print("[CoreRegistryFix]", ...)
    end
end

-- Find required modules
local function findModule(name)
    local paths = {
        ServerScriptService.Core,
        ServerScriptService
    }
    
    for _, path in ipairs(paths) do
        if path and path:FindFirstChild(name) then
            local success, module = pcall(function()
                return require(path[name])
            end)
            
            if success then
                return module
            end
        end
    end
    
    return nil
end

-- Main execution
log("Starting CoreRegistry fix process...")

-- Step 1: Run initial diagnostic
log("Step 1: Running initial diagnostic...")
local diagnosticModule = findModule("CoreRegistryDiagnostic.server")
if not diagnosticModule then
    diagnosticModule = findModule("CoreRegistryDiagnostic")
end

local initialStatus = nil
if diagnosticModule then
    initialStatus = diagnosticModule
    
    log("Initial diagnostic results:")
    log("CoreRegistry found:", initialStatus.coreRegistryFound)
    log("Registry status:", initialStatus.registryStatus)
    log("Missing systems:", table.concat(initialStatus.missingSystems, ", "))
    
    if #initialStatus.missingSystems == 0 then
        log("No missing systems detected, CoreRegistry appears healthy")
    end
else
    log("Could not find diagnostic module, proceeding without initial check")
end

-- Step 2: Run restoration process
log("Step 2: Running CoreRegistry restoration...")
local restorerModule = findModule("CoreRegistryRestorer.server")
if not restorerModule then
    restorerModule = findModule("CoreRegistryRestorer")
end

if restorerModule then
    log("Successfully ran CoreRegistry restoration process")
else
    log("ERROR: Could not find or run CoreRegistryRestorer")
end

-- Step 3: Run diagnostic again to verify fixes
log("Step 3: Running final diagnostic to verify fixes...")
local finalStatus = nil

if diagnosticModule then
    -- Reload the diagnostic module to get fresh results
    package.loaded[diagnosticModule] = nil
    diagnosticModule = findModule("CoreRegistryDiagnostic.server")
    if not diagnosticModule then
        diagnosticModule = findModule("CoreRegistryDiagnostic")
    end
    
    finalStatus = diagnosticModule
    
    log("Final diagnostic results:")
    log("CoreRegistry found:", finalStatus.coreRegistryFound)
    log("Registry status:", finalStatus.registryStatus)
    
    if #finalStatus.missingSystems == 0 then
        log("✓ SUCCESS: All systems are now registered properly")
    else
        log("⚠️ WARNING: Some systems still missing:", table.concat(finalStatus.missingSystems, ", "))
    end
    
    if #finalStatus.placeholderSystems > 0 then
        log("ℹ️ NOTE: The following systems are using placeholder implementations:", 
            table.concat(finalStatus.placeholderSystems, ", "))
    end
else
    log("Could not run final diagnostic check")
end

-- Set global flag
_G.CoreRegistryFixCompleted = true
_G.CoreRegistryFixTime = os.time()

log("CoreRegistry fix process complete")

return {
    initialStatus = initialStatus,
    finalStatus = finalStatus,
    fixCompleted = true
}
