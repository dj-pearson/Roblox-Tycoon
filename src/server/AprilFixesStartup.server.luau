--!strict
--[[
    AprilFixesStartup.server.luau
    Initializes all fixes implemented for April 29 issues
    
    Created: April 29, 2025
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility functions
local function log(message)
    print("[AprilFixesStartup] " .. message)
end

local function requireSafely(moduleScript)
    if not moduleScript then return nil end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        return result
    else
        warn("[AprilFixesStartup] Failed to require module:", moduleScript:GetFullName(), "-", result)
        return nil
    end
end

-- Find script in various paths
local function findScript(scriptName)
    local paths = {
        ServerScriptService:FindFirstChild("Core"),
        ServerScriptService:FindFirstChild("Systems"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("server"),
        ServerScriptService:FindFirstChild("src"):FindFirstChild("server"):FindFirstChild("Core")
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

-- Initialize each fix in the correct order
local function initializeFixes()
    log("Starting initialization of April 29 fixes...")
    
    -- 1. First, initialize the CoreRegistryRestorer to ensure critical systems exist
    local coreRegistryRestorerScript = findScript("CoreRegistryRestorer")
    if coreRegistryRestorerScript then
        log("Executing CoreRegistryRestorer...")
        requireSafely(coreRegistryRestorerScript)
    else
        warn("[AprilFixesStartup] Could not find CoreRegistryRestorer script!")
    end
    
    -- 2. Next, initialize the BuyTilePositionFixer
    local buyTileFixerScript = findScript("BuyTilePositionFixer")
    if buyTileFixerScript then
        log("Executing BuyTilePositionFixer...")
        requireSafely(buyTileFixerScript)
    else
        warn("[AprilFixesStartup] Could not find BuyTilePositionFixer script!")
    end
    
    -- 3. Ensure all players get the UIAccessRestrictor
    local function setupClientScripts()
        -- Create configuration values in ReplicatedStorage for client scripts
        local configFolder = ReplicatedStorage:FindFirstChild("ClientConfig") or Instance.new("Folder")
        configFolder.Name = "ClientConfig"
        configFolder.Parent = ReplicatedStorage
        
        -- Set flag to enable UIAccessRestrictor
        local uiAccessFlag = configFolder:FindFirstChild("EnableUIAccessRestrictor") or Instance.new("BoolValue")
        uiAccessFlag.Name = "EnableUIAccessRestrictor"
        uiAccessFlag.Value = true
        uiAccessFlag.Parent = configFolder
        
        log("Set up client configuration flags")
    end
    
    setupClientScripts()
    
    log("All April 29 fixes initialized successfully!")
end

-- Execute fixes
initializeFixes()

return true
