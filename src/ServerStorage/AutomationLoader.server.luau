--[[
    AutomationLoader.server.luau - 
    
    This script loads all automation tools and ensures they're available
    through global functions (_G) in the Command Bar.
    
    Usage: 
    1. Put this script in ServerStorage
    2. Run the game in Studio (Play button)
    3. Then use commands like _G.AutomateGymTycoon() in the Command Bar
    
    Created: April 20, 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Paths to automation scripts
local AUTOMATION_SCRIPT_PATHS = {
    -- Main automation script
    "src/server/Connectors/GymTycoonAutomation",
    
    -- Individual automation tools
    "src/server/Connectors/AutoBuyTileSetup",
    "src/server/Connectors/BuyTileConfigGenerator",
    "src/server/Connectors/BuyTileHitboxGenerator",
    
    -- Structure analysis
    "src/server/Core/GymStructureIntegration",
}

-- Print whether paths exist
local function checkPath(path)
    local success, result = pcall(function()
        return script.Parent.Parent:FindFirstChild(path:match("^src/(.+)$"))
    end)
    
    if success and result then
        print("✓ Found: " .. path)
        return result
    else
        warn("✗ Not found: " .. path)
        return nil
    end
end

-- Print header
print("\n=== AUTOMATION LOADER ===")
print("Loading automation tools into global scope...")

-- Try direct loading from paths first
local loadedModules = {}
local loadedCount = 0

for _, path in ipairs(AUTOMATION_SCRIPT_PATHS) do
    local module = checkPath(path)
    
    if module then
        local success, result = pcall(function()
            return require(module)
        end)
        
        if success then
            loadedModules[path:match("[^/]+$")] = result
            loadedCount += 1
            print("✓ Required: " .. path:match("[^/]+$"))
        else
            warn("✗ Failed to require: " .. path:match("[^/]+$") .. " - " .. result)
        end
    end
end

-- Alternative approach - look for scripts in ServerScriptService/Connectors
if loadedCount == 0 then
    print("\nTrying alternate paths...")
    
    local connectors = ServerScriptService:FindFirstChild("Connectors")
    if connectors then
        for _, child in ipairs(connectors:GetChildren()) do
            if child:IsA("ModuleScript") and 
               (string.find(child.Name, "Automation") or 
                string.find(child.Name, "BuyTile") or 
                string.find(child.Name, "Setup")) then
                
                local success, result = pcall(function()
                    return require(child)
                end)
                
                if success then
                    loadedModules[child.Name] = result
                    loadedCount += 1
                    print("✓ Required alternate: " .. child.Name)
                else
                    warn("✗ Failed to require alternate: " .. child.Name)
                end
            end
        end
    end
end

-- Define global functions
if loadedModules.GymTycoonAutomation then
    _G.AutomateGymTycoon = function(config)
        return loadedModules.GymTycoonAutomation.AutomateGymTycoon(config)
    end
    
    _G.AnalyzeGymStructure = function(verbose)
        return loadedModules.GymTycoonAutomation.AnalyzeGymStructure(verbose)
    end
    
    _G.SetAutomationConfig = function(config)
        return loadedModules.GymTycoonAutomation.SetAutomationConfig(config)
    end
    
    print("✓ Registered global function: _G.AutomateGymTycoon()")
    print("✓ Registered global function: _G.AnalyzeGymStructure(verbose)")
    print("✓ Registered global function: _G.SetAutomationConfig(config)")
end

if loadedModules.AutoBuyTileSetup then
    _G.AutoSetupBuyTiles = function()
        return loadedModules.AutoBuyTileSetup.AutoSetupAllTycoons()
    end
    
    print("✓ Registered global function: _G.AutoSetupBuyTiles()")
end

if loadedModules.BuyTileConfigGenerator then
    _G.GenerateBuyTileConfig = function()
        return loadedModules.BuyTileConfigGenerator.GenerateConfig()
    end
    
    print("✓ Registered global function: _G.GenerateBuyTileConfig()")
end

if loadedModules.BuyTileHitboxGenerator then
    _G.GenerateHitboxes = function()
        return loadedModules.BuyTileHitboxGenerator.GenerateAllHitboxes()
    end
    
    print("✓ Registered global function: _G.GenerateHitboxes()")
end

if loadedModules.GymStructureIntegration then
    _G.SyncGymStructure = function(verbose)
        return loadedModules.GymStructureIntegration.SyncGymStructure(verbose)
    end
    
    print("✓ Registered global function: _G.SyncGymStructure(verbose)")
end

-- Define a fallback function in case modules weren't loaded
if loadedCount == 0 then
    _G.AutomateGymTycoon = function()
        warn("Automation modules not found! Make sure you have all the necessary scripts in your project.")
        warn("Required scripts should be in: src/server/Connectors/GymTycoonAutomation")
        warn("Or in ServerScriptService/Connectors folder")
        
        print("\nLooking for possible automation scripts in workspace...")
        
        -- Try to find any automation scripts
        local foundScripts = {}
        
        -- Check ServerScriptService
        for _, service in ipairs({ServerScriptService, ServerStorage}) do
            for _, child in ipairs(service:GetDescendants()) do
                if child:IsA("ModuleScript") or child:IsA("Script") then
                    if string.find(child.Name:lower(), "automation") or
                       string.find(child.Name:lower(), "buytile") or
                       string.find(child.Name:lower(), "setup") or
                       string.find(child.Name:lower(), "generator") then
                        
                        table.insert(foundScripts, child:GetFullName())
                    end
                end
            end
        end
        
        if #foundScripts > 0 then
            print("\nPossible automation scripts found:")
            for _, scriptPath in ipairs(foundScripts) do
                print("- " .. scriptPath)
            end
            
            print("\nYou can try running these directly or moving them to the correct location.")
        else
            print("No automation scripts found in the workspace.")
        end
        
        return nil
    end
    
    print("✓ Registered fallback function: _G.AutomateGymTycoon()")
end

print("\n=== AUTOMATION LOADER COMPLETE ===")
print("Loaded " .. loadedCount .. " modules")
print("Run _G.AutomateGymTycoon() in the Command Bar to start automation")