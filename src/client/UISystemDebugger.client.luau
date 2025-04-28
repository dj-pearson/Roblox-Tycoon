-- UISystemDebugger.client.luau
-- Provides debug information and diagnosis for UI system issues
-- Created on April 28, 2025

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

print("UISystemDebugger: Starting diagnostic...")

-- Helper functions
local function inspectObject(obj, label)
    local objType = typeof(obj)
    local result = label .. " - Type: " .. objType
    
    if objType == "table" then
        local keys = {}
        for k, _ in pairs(obj) do
            table.insert(keys, tostring(k))
        end
        result = result .. ", Keys: [" .. table.concat(keys, ", ") .. "]"
    elseif objType == "Instance" then
        result = result .. ", ClassName: " .. obj.ClassName
    elseif objType == "function" or objType == "userdata" then
        result = result .. " (No additional info available)"
    else
        result = result .. ", Value: " .. tostring(obj)
    end
    
    return result
end

-- Check global variables
local function checkGlobals()
    print("\n=== GLOBAL VARIABLES CHECK ===")
    local expectedGlobals = {"UIRegistry", "UISystem", "ClientRegistry", "ModuleLoader", "UIComponents", "MainMenuUI"}
    
    for _, name in ipairs(expectedGlobals) do
        local value = _G[name]
        if value then
            print("✅ Found global: " .. inspectObject(value, name))
        else
            print("❌ Missing global: " .. name)
        end
    end
end

-- Check registry status
local function checkRegistry()
    print("\n=== REGISTRY STATUS CHECK ===")
    local registry
    
    if _G.UIRegistry then
        registry = _G.UIRegistry
        print("✅ Found UIRegistry in global scope")
    elseif _G.ClientRegistry and _G.ClientRegistry.getSystem then
        registry = _G.ClientRegistry:getSystem("UIRegistry")
        if registry then
            print("✅ Found UIRegistry via ClientRegistry")
        else
            print("❌ UIRegistry not registered with ClientRegistry")
        end
    else
        print("❌ Cannot locate UIRegistry")
        return
    end
    
    -- Check component registration
    if registry.getRegisteredComponents then
        local components = registry:getRegisteredComponents()
        print("Registered components:")
        if #components == 0 then
            print("  ❌ No components registered")
        else
            for _, name in ipairs(components) do
                local component = registry:getComponent(name)
                if component then
                    print("  ✅ " .. name)
                else
                    print("  ⚠️ " .. name .. " (registered but cannot be retrieved)")
                end
            end
        end
    else
        print("⚠️ Registry doesn't have getRegisteredComponents method")
    end
    
    -- Specifically check for MainMenuUI/MainMenu
    local mainMenuUI = registry:getComponent("MainMenuUI")
    local mainMenu = registry:getComponent("MainMenu")
    
    print("MainMenuUI component: " .. (mainMenuUI and "✅ Found" or "❌ Not found"))
    print("MainMenu component: " .. (mainMenu and "✅ Found" or "❌ Not found"))
end

-- Check UI folder structure
local function checkUIFolders()
    print("\n=== UI FOLDER STRUCTURE CHECK ===")
    local src = ReplicatedStorage:FindFirstChild("src")
    if not src then
        print("❌ src folder not found in ReplicatedStorage")
        return
    end
    
    local client = src:FindFirstChild("client")
    if not client then
        print("❌ client folder not found in src")
        return
    end
      local ui = client:FindFirstChild("UI")
    if not ui then
        print("❌ UI folder not found in client")
        return
    end
    
    print("✅ Found UI folder")
    
    -- Check for Screens folder
    local screens = ui:FindFirstChild("Screens")
    if not screens then
        print("❌ Screens folder not found in UI")
    else
        print("✅ Found Screens folder")
        
        -- Check for MainMenuUI module
        local mainMenuModule = screens:FindFirstChild("MainMenuUI")
        if not mainMenuModule then
            print("❌ MainMenuUI module not found in Screens folder")
        else
            print("✅ Found MainMenuUI module")
            
            -- Check if loadable
            local success, result = pcall(function()
                return require(mainMenuModule)
            end)
            
            if success then
                print("✅ MainMenuUI module loads successfully")
                
                -- Check for required methods
                if typeof(result) == "table" then
                    local methods = {"initialize", "show", "hide"}
                    local allMethods = true
                    
                    for _, method in ipairs(methods) do
                        if not result[method] or typeof(result[method]) ~= "function" then
                            print("❌ MainMenuUI missing required method: " .. method)
                            allMethods = false
                        end
                    end
                    
                    if allMethods then
                        print("✅ MainMenuUI has all required methods")
                    end
                else
                    print("❌ MainMenuUI doesn't return a table")
                end
            else
                print("❌ Error loading MainMenuUI module: " .. tostring(result))
            end
        end
    end
      -- Check for Core folder
    local core = ui:FindFirstChild("Core")
    if not core then
        print("❌ Core folder not found in UI")
    else
        print("✅ Found Core folder")
        
        -- Check for essential modules
        local essentialModules = {"UISystem", "UIRegistry", "UIManager"}
        for _, name in ipairs(essentialModules) do
            local module = core:FindFirstChild(name)
            if not module then
                print("❌ " .. name .. " module not found in Core folder")
            else
                print("✅ Found " .. name .. " module")
            end
        end
    end
end

-- Main execution
task.spawn(function()
    task.wait(2) -- Wait for systems to initialize
    
    checkGlobals()
    checkRegistry()
    checkUIFolders()
    
    print("\n=== UI SYSTEM DIAGNOSIS COMPLETE ===")
    print("If you're seeing issues with the MainMenuUI not showing up,")
    print("please check the above logs for missing components or registry issues.")
    print("You can also try running UISystem:showMainMenu() in the command bar.")
end)

print("UISystemDebugger: Diagnostic scheduled")
