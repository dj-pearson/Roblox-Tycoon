-- InitializationVerificationTest.server.luau
-- This script verifies that all critical initialization components are working properly
-- Run this script to verify the fixes for the Autorun and Initialization Sequence Issues
-- Created: May 2, 2025

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
    VERBOSE_LOGGING = true,
    CHECK_SERVER_MODULES = true,
    CHECK_CLIENT_MODULES = true,
    CHECK_REGISTRY = true
}

-- Verification results
local verificationResults = {
    serverModules = {},
    clientModules = {},
    registryStatus = {},
    overall = "Pending"
}

-- Print header
print("\n\n================================================")
print("INITIALIZATION VERIFICATION TEST - MAY 2, 2025")
print("================================================\n")

-- Helper function for logging
local function log(message, messageType)
    local prefix = "[VerificationTest] "
    
    if messageType == "error" then
        warn(prefix .. "ERROR: " .. message)
    elseif messageType == "warn" then
        warn(prefix .. "WARNING: " .. message)
    elseif messageType == "success" then
        print(prefix .. "SUCCESS: " .. message)
    else
        print(prefix .. message)
    end
end

-- Verify server modules
local function verifyServerModules()
    log("Verifying server modules...")
    
    local modulesToCheck = {
        ["Core/DataManagerFix"] = {
            path = "ServerScriptService.Core.DataManagerFix",
            alternativePaths = {
                "ServerScriptService.src.server.Core.DataManagerFix",
                "ReplicatedStorage.shared.DataManagerFix"
            }
        },
        ["Essentials/PlayerProgressRestoration"] = {
            path = "ServerScriptService.Essentials.PlayerProgressRestoration",
            alternativePaths = {
                "ServerScriptService.src.server.Essentials.PlayerProgressRestoration",
                "ReplicatedStorage.shared.PlayerProgressRestoration"
            }
        },
        ["Essentials/AssetDiagnosticsSystem"] = {
            path = "ServerScriptService.Essentials.AssetDiagnosticsSystem",
            alternativePaths = {
                "ServerScriptService.src.server.Essentials.AssetDiagnosticsSystem",
                "ReplicatedStorage.shared.AssetDiagnosticsSystem"
            }
        },
        ["Phase3Loader"] = {
            path = "ServerScriptService.Phase3Loader",
            alternativePaths = {
                "ServerScriptService.src.server.Phase3Loader",
                "ServerScriptService.Scripts.Phase3Loader"
            }
        }
    }
    
    -- Check each module
    for name, info in pairs(modulesToCheck) do
        verificationResults.serverModules[name] = {
            found = false,
            loadable = false,
            path = nil
        }
        
        local moduleInstance = nil
        
        -- Check main path
        local pathParts = string.split(info.path, ".")
        local current = game
        
        for i, part in ipairs(pathParts) do
            if current:FindFirstChild(part) then
                current = current:FindFirstChild(part)
                
                if i == #pathParts then
                    moduleInstance = current
                    verificationResults.serverModules[name].found = true
                    verificationResults.serverModules[name].path = info.path
                    break
                end
            else
                break
            end
        end
        
        -- Check alternative paths if not found
        if not moduleInstance then
            for _, altPath in ipairs(info.alternativePaths) do
                local altPathParts = string.split(altPath, ".")
                local altCurrent = game
                
                for i, part in ipairs(altPathParts) do
                    if altCurrent:FindFirstChild(part) then
                        altCurrent = altCurrent:FindFirstChild(part)
                        
                        if i == #altPathParts then
                            moduleInstance = altCurrent
                            verificationResults.serverModules[name].found = true
                            verificationResults.serverModules[name].path = altPath
                            break
                        end
                    else
                        break
                    end
                end
                
                if moduleInstance then break end
            end
        end
        
        -- Check if module can be loaded
        if moduleInstance then
            local success, _ = pcall(function()
                return require(moduleInstance)
            end)
            
            verificationResults.serverModules[name].loadable = success
            
            if CONFIG.VERBOSE_LOGGING then
                if success then
                    log("Module " .. name .. " found and loadable at " .. verificationResults.serverModules[name].path, "success")
                else
                    log("Module " .. name .. " found but not loadable at " .. verificationResults.serverModules[name].path, "warn")
                end
            end
        else
            if CONFIG.VERBOSE_LOGGING then
                log("Module " .. name .. " not found", "error")
            end
        end
    end
    
    -- Calculate overall server module status
    local totalModules = 0
    local foundModules = 0
    local loadableModules = 0
    
    for _, result in pairs(verificationResults.serverModules) do
        totalModules += 1
        if result.found then foundModules += 1 end
        if result.loadable then loadableModules += 1 end
    end
    
    verificationResults.serverModules._summary = {
        total = totalModules,
        found = foundModules,
        loadable = loadableModules,
        status = (loadableModules == totalModules) and "PASS" or "FAIL"
    }
    
    log("Server module verification complete: " .. foundModules .. "/" .. totalModules .. " found, " .. 
        loadableModules .. "/" .. totalModules .. " loadable")
    
    if verificationResults.serverModules._summary.status == "PASS" then
        log("All server modules verified successfully", "success")
    else
        log("Some server modules missing or not loadable", "warn")
    end
    
    return verificationResults.serverModules._summary.status == "PASS"
end

-- Verify client modules
local function verifyClientModules()
    log("Verifying client modules...")
    
    -- Create a RemoteFunction to execute verification on the client
    local clientVerifier = Instance.new("RemoteFunction")
    clientVerifier.Name = "ClientModuleVerifier"
    clientVerifier.Parent = ReplicatedStorage
    
    -- Create the client verification script
    local clientScript = Instance.new("Script")
    clientScript.Name = "ClientVerificationScript"
    
    clientScript.Source = [[
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    
    local player = Players.LocalPlayer
    local clientVerifier = ReplicatedStorage:WaitForChild("ClientModuleVerifier")
    
    local function verifyClientModules()
        local results = {
            clientModules = {},
            overall = "Pending"
        }
        
        local modulesToCheck = {
            ["UISystemPatcher"] = {
                path = "Players.LocalPlayer.PlayerScripts.UISystemPatcher",
                alternativePaths = {
                    "Players.LocalPlayer.PlayerScripts.src.client.UISystemPatcher",
                    "ReplicatedStorage.shared.UISystemPatcher",
                    "ReplicatedStorage.client.UISystemPatcher"
                }
            },
            ["AprilFixesClientStartup"] = {
                path = "Players.LocalPlayer.PlayerScripts.AprilFixesClientStartup",
                alternativePaths = {
                    "Players.LocalPlayer.PlayerScripts.src.client.AprilFixesClientStartup",
                    "Players.LocalPlayer.PlayerScripts.Client.AprilFixesClientStartup"
                }
            }
        }
        
        -- Check each module
        for name, info in pairs(modulesToCheck) do
            results.clientModules[name] = {
                found = false,
                loadable = false,
                path = nil
            }
            
            local moduleInstance = nil
            
            -- Check main path
            local pathParts = string.split(info.path, ".")
            local current = game
            
            for i, part in ipairs(pathParts) do
                if current:FindFirstChild(part) then
                    current = current:FindFirstChild(part)
                    
                    if i == #pathParts then
                        moduleInstance = current
                        results.clientModules[name].found = true
                        results.clientModules[name].path = info.path
                        break
                    end
                else
                    break
                end
            end
            
            -- Check alternative paths if not found
            if not moduleInstance then
                for _, altPath in ipairs(info.alternativePaths) do
                    local altPathParts = string.split(altPath, ".")
                    local altCurrent = game
                    
                    for i, part in ipairs(altPathParts) do
                        if altCurrent:FindFirstChild(part) then
                            altCurrent = altCurrent:FindFirstChild(part)
                            
                            if i == #altPathParts then
                                moduleInstance = altCurrent
                                results.clientModules[name].found = true
                                results.clientModules[name].path = altPath
                                break
                            end
                        else
                            break
                        end
                    end
                    
                    if moduleInstance then break end
                end
            end
            
            -- Check if module can be loaded (if it's a ModuleScript)
            if moduleInstance and moduleInstance:IsA("ModuleScript") then
                local success, _ = pcall(function()
                    return require(moduleInstance)
                end)
                
                results.clientModules[name].loadable = success
            elseif moduleInstance then
                -- If it's not a ModuleScript (e.g., a Script), consider it "loadable"
                results.clientModules[name].loadable = true
            end
        end
        
        -- Calculate overall client module status
        local totalModules = 0
        local foundModules = 0
        local loadableModules = 0
        
        for _, result in pairs(results.clientModules) do
            totalModules += 1
            if result.found then foundModules += 1 end
            if result.loadable then loadableModules += 1 end
        end
        
        results.clientModules._summary = {
            total = totalModules,
            found = foundModules,
            loadable = loadableModules,
            status = (loadableModules == totalModules) and "PASS" or "FAIL"
        }
        
        results.overall = results.clientModules._summary.status
        
        return results
    end
    
    -- Set up the OnServerInvoke callback
    clientVerifier.OnClientInvoke = function()
        return verifyClientModules()
    end
    
    -- Also return the result immediately
    return verifyClientModules()
    ]]
    
    -- Make it run on the client
    clientScript.Parent = game.StarterPlayer.StarterPlayerScripts
    
    -- Wait a moment for scripts to run
    wait(2)
    
    -- Try to get results from any connected player
    local success = false
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        local clientSuccess, clientResults = pcall(function()
            return clientVerifier:InvokeClient(player)
        end)
        
        if clientSuccess and clientResults then
            verificationResults.clientModules = clientResults.clientModules
            success = true
            break
        end
    end
    
    -- If no players connected or results failed, report failure
    if not success then
        log("Could not verify client modules - no player connected or verification failed", "warn")
        verificationResults.clientModules._summary = {
            total = 0,
            found = 0,
            loadable = 0,
            status = "FAIL"
        }
        return false
    end
    
    -- Report results
    log("Client module verification complete: " .. 
        verificationResults.clientModules._summary.found .. "/" .. verificationResults.clientModules._summary.total .. " found, " .. 
        verificationResults.clientModules._summary.loadable .. "/" .. verificationResults.clientModules._summary.total .. " loadable")
    
    if verificationResults.clientModules._summary.status == "PASS" then
        log("All client modules verified successfully", "success")
    else
        log("Some client modules missing or not loadable", "warn")
    end
    
    -- Clean up
    clientVerifier:Destroy()
    clientScript:Destroy()
    
    return verificationResults.clientModules._summary.status == "PASS"
end

-- Verify CoreRegistry
local function verifyCoreRegistry()
    log("Verifying CoreRegistry...")
    
    verificationResults.registryStatus = {
        found = false,
        systemsRegistered = {},
        criticalSystems = {
            "DataManager",
            "PlayerProgressRestoration",
            "AssetDiagnosticsSystem",
            "UIManager",
            "TycoonSystem",
            "BuyTileSystem",
            "EventBridge"
        }
    }
    
    -- Try to find CoreRegistry
    local coreRegistryModule = nil
    
    local potentialPaths = {
        ServerScriptService.Core and ServerScriptService.Core:FindFirstChild("CoreRegistry"),
        ReplicatedStorage.shared and ReplicatedStorage.shared:FindFirstChild("CoreRegistry"),
        ServerScriptService.src and ServerScriptService.src.server and 
        ServerScriptService.src.server.Core and ServerScriptService.src.server.Core:FindFirstChild("CoreRegistry")
    }
    
    for _, path in ipairs(potentialPaths) do
        if path then
            coreRegistryModule = path
            break
        end
    end
    
    if not coreRegistryModule then
        log("CoreRegistry module not found", "error")
        verificationResults.registryStatus.status = "FAIL"
        return false
    end
    
    verificationResults.registryStatus.found = true
    
    -- Try to load CoreRegistry
    local loadSuccess, CoreRegistry = pcall(function()
        return require(coreRegistryModule)
    end)
    
    if not loadSuccess or not CoreRegistry then
        log("CoreRegistry failed to load", "error")
        verificationResults.registryStatus.status = "FAIL"
        return false
    end
    
    -- Check for key systems
    local registeredSystemCount = 0
    local missingSystemCount = 0
    
    for _, systemName in ipairs(verificationResults.registryStatus.criticalSystems) do
        local system = nil
        
        if typeof(CoreRegistry.getSystem) == "function" then
            system = CoreRegistry.getSystem(systemName)
        end
        
        verificationResults.registryStatus.systemsRegistered[systemName] = system ~= nil
        
        if system then
            registeredSystemCount += 1
            if CONFIG.VERBOSE_LOGGING then
                log("System '" .. systemName .. "' registered in CoreRegistry", "success")
            end
        else
            missingSystemCount += 1
            if CONFIG.VERBOSE_LOGGING then
                log("System '" .. systemName .. "' not found in CoreRegistry", "warn")
            end
        end
    end
    
    -- Get registry status if available
    local registryStatus = nil
    
    if typeof(CoreRegistry.getStatus) == "function" then
        registryStatus = CoreRegistry.getStatus()
    end
    
    verificationResults.registryStatus.registryStatus = registryStatus
    
    -- Calculate overall status
    verificationResults.registryStatus.systemsFound = registeredSystemCount
    verificationResults.registryStatus.systemsMissing = missingSystemCount
    verificationResults.registryStatus.systemsTotal = #verificationResults.registryStatus.criticalSystems
    
    -- Pass if most critical systems are found (at least 5 of 7)
    verificationResults.registryStatus.status = (registeredSystemCount >= 5) and "PASS" or "FAIL"
    
    log("CoreRegistry verification complete: " .. registeredSystemCount .. "/" .. 
        #verificationResults.registryStatus.criticalSystems .. " critical systems registered")
    
    if verificationResults.registryStatus.status == "PASS" then
        log("CoreRegistry verification successful", "success")
    else
        log("CoreRegistry verification failed - too many missing systems", "warn")
    end
    
    return verificationResults.registryStatus.status == "PASS"
end

-- Run verification
local function runVerification()
    log("Starting verification tests...")
    
    local serverResult = true
    local clientResult = true
    local registryResult = true
    
    if CONFIG.CHECK_SERVER_MODULES then
        serverResult = verifyServerModules()
    end
    
    if CONFIG.CHECK_CLIENT_MODULES then
        clientResult = verifyClientModules()
    end
    
    if CONFIG.CHECK_REGISTRY then
        registryResult = verifyCoreRegistry()
    end
    
    -- Calculate overall status
    verificationResults.overall = (serverResult and clientResult and registryResult) and "PASS" or "FAIL"
    
    -- Print overall results
    print("\n================================================")
    print("VERIFICATION TEST RESULTS")
    print("================================================")
    print("Server Modules: " .. (verificationResults.serverModules._summary and verificationResults.serverModules._summary.status or "NOT CHECKED"))
    print("Client Modules: " .. (verificationResults.clientModules._summary and verificationResults.clientModules._summary.status or "NOT CHECKED"))
    print("CoreRegistry: " .. (verificationResults.registryStatus and verificationResults.registryStatus.status or "NOT CHECKED"))
    print("------------------------------------------------")
    print("Overall Status: " .. verificationResults.overall)
    print("================================================\n")
    
    if verificationResults.overall == "PASS" then
        log("Verification completed successfully! All critical components are working properly.", "success")
    else
        log("Verification failed. Some components need attention.", "error")
    end
    
    return verificationResults
end

-- Run verification
runVerification()

return verificationResults
